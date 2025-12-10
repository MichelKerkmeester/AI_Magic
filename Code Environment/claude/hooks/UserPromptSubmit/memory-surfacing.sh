#!/usr/bin/env bash

# ═══════════════════════════════════════════════════════════════════════════════
# Memory Surfacing Hook - Proactive Memory Surfacing
# ═══════════════════════════════════════════════════════════════════════════════
#
# Version: 12.0.0
# Hook Event: UserPromptSubmit
# Performance Target: <50ms for trigger matching, <1s for context surfacing (NFR-P03)
#
# This hook surfaces relevant memories in three ways:
# 1. SESSION PREFERENCES: Detect "auto-load memories", "fresh start", "skip memory" phrases
# 2. SPEC FOLDER DETECTION: When user works in/references a spec folder
# 3. TRIGGER MATCHING: When trigger phrases are detected in the prompt
#
# Session preferences (Gate 3 implementation):
#   - "auto-load memories" → Skip prompt, load most recent automatically (1 hour)
#   - "fresh start" / "skip memory" → Skip all memory surfacing (1 hour)
#   - "ask about memories" → Revert to interactive selection (default)
#
# The #1 pain point is users losing context between sessions. This hook
# proactively surfaces recent memories when working in spec folders.
#
# Usage: memory-surfacing.sh <stdin: hook_data_json>
# Input: JSON with "prompt" field
# Output: JSON with "result" and optionally "continue" fields
#
# ═══════════════════════════════════════════════════════════════════════════════
# OPENCODE ALTERNATIVE
# ═══════════════════════════════════════════════════════════════════════════════
# Opencode doesn't support hooks. Instead, the SKILL.md file
# instructs the AI to:
# 1. Check if working in a spec folder
# 2. Query recent memories via /memory/search
# 3. Offer to load relevant context
#
# This is documented in:
# .opencode/skills/workflows-memory/SKILL.md
# ═══════════════════════════════════════════════════════════════════════════════

set -euo pipefail

# ───────────────────────────────────────────────────────────────
# CONFIGURATION
# ───────────────────────────────────────────────────────────────

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILL_DIR="${SCRIPT_DIR}/../../skills/workflows-memory"
MATCHER_SCRIPT="${SKILL_DIR}/scripts/lib/trigger-matcher.js"
VECTOR_INDEX_SCRIPT="${SKILL_DIR}/scripts/lib/vector-index.js"
LOG_FILE="${SCRIPT_DIR}/../logs/memory-surfacing.log"

# Performance budgets
TRIGGER_MATCH_BUDGET_MS=50
CONTEXT_SURFACE_BUDGET_MS=1000

# Memory surfacing configuration
RECENT_DAYS=7
MAX_MEMORIES=3

# Session preferences (Gate 3 implementation)
SESSION_PREF_DIR="/tmp/claude-memory-prefs"
SESSION_PREF_TTL=3600  # 1 hour in seconds

# ───────────────────────────────────────────────────────────────
# LOGGING
# ───────────────────────────────────────────────────────────────

log_debug() {
  if [[ "${DEBUG_MEMORY_SURFACING:-}" == "1" ]]; then
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] [memory-surfacing] $*" >> "$LOG_FILE" 2>/dev/null || true
  fi
}

log_perf() {
  local operation="$1"
  local elapsed="$2"
  local budget="$3"
  if [[ $elapsed -gt $budget ]]; then
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] [memory-surfacing] SLOW: ${operation} took ${elapsed}ms (budget: ${budget}ms)" >> "$LOG_FILE" 2>/dev/null || true
  fi
}

# ───────────────────────────────────────────────────────────────
# HELPERS
# ───────────────────────────────────────────────────────────────

# Fast JSON output
output_json() {
  local result="$1"
  local continue_flag="${2:-true}"
  echo "{\"result\": \"${result}\", \"continue\": ${continue_flag}}"
}

# Error output (silent failure - don't block user)
output_error() {
  output_json "" true
  exit 0
}

# Get current time in milliseconds (macOS compatible)
get_time_ms() {
  if command -v gdate &>/dev/null; then
    gdate +%s%3N
  elif [[ "$OSTYPE" == "darwin"* ]]; then
    # macOS: use python for milliseconds
    python3 -c "import time; print(int(time.time() * 1000))" 2>/dev/null || echo 0
  else
    date +%s%3N 2>/dev/null || echo 0
  fi
}

# Get elapsed time in milliseconds
get_elapsed_ms() {
  local start="$1"
  local end
  end=$(get_time_ms)
  if [[ "$start" -gt 0 && "$end" -gt 0 ]]; then
    echo $((end - start))
  else
    echo 0
  fi
}

# ───────────────────────────────────────────────────────────────
# SESSION PREFERENCES (Gate 3 - Memory File Loading)
# ───────────────────────────────────────────────────────────────
# Preferences: "interactive" (default), "auto-load", "skip"
# Phrases detected:
#   - "auto-load memories" → auto-load
#   - "fresh start", "skip memory" → skip
#   - "ask about memories" → interactive (reset to default)

# Get session preference file path
get_session_pref_file() {
  # Use PPID or a hash of the session to create unique file
  local session_id="${CLAUDE_SESSION_ID:-$$}"
  echo "${SESSION_PREF_DIR}/session-${session_id}.pref"
}

# Initialize session pref directory
init_session_prefs() {
  mkdir -p "$SESSION_PREF_DIR" 2>/dev/null || true
}

# Get current session preference (default: interactive)
get_session_preference() {
  local pref_file
  pref_file=$(get_session_pref_file)

  if [[ -f "$pref_file" ]]; then
    # Check TTL - file should not be older than SESSION_PREF_TTL
    local file_age
    if [[ "$OSTYPE" == "darwin"* ]]; then
      file_age=$(( $(date +%s) - $(stat -f %m "$pref_file" 2>/dev/null || echo 0) ))
    else
      file_age=$(( $(date +%s) - $(stat -c %Y "$pref_file" 2>/dev/null || echo 0) ))
    fi

    if [[ $file_age -lt $SESSION_PREF_TTL ]]; then
      cat "$pref_file" 2>/dev/null || echo "interactive"
      return
    else
      # Expired - remove and return default
      rm -f "$pref_file" 2>/dev/null || true
    fi
  fi

  echo "interactive"
}

# Set session preference
set_session_preference() {
  local pref="$1"
  local pref_file
  pref_file=$(get_session_pref_file)

  init_session_prefs
  echo "$pref" > "$pref_file" 2>/dev/null || true
  log_debug "Session preference set to: $pref"
}

# Detect preference phrase in prompt and update session state
# Returns: "auto-load", "skip", "interactive", or "" (no change)
detect_preference_phrase() {
  local prompt="$1"
  local prompt_lower
  prompt_lower=$(echo "$prompt" | tr '[:upper:]' '[:lower:]')

  # Check for "auto-load memories" or "auto load memories"
  if [[ "$prompt_lower" == *"auto-load memor"* ]] || [[ "$prompt_lower" == *"auto load memor"* ]] || [[ "$prompt_lower" == *"autoload memor"* ]]; then
    set_session_preference "auto-load"
    echo "auto-load"
    return 0
  fi

  # Check for "fresh start" or "skip memory" or "skip memories"
  if [[ "$prompt_lower" == *"fresh start"* ]] || [[ "$prompt_lower" == *"skip memor"* ]]; then
    set_session_preference "skip"
    echo "skip"
    return 0
  fi

  # Check for "ask about memories" (reset to default)
  if [[ "$prompt_lower" == *"ask about memor"* ]] || [[ "$prompt_lower" == *"ask me about memor"* ]]; then
    set_session_preference "interactive"
    echo "interactive"
    return 0
  fi

  echo ""
  return 1
}

# ───────────────────────────────────────────────────────────────
# SPEC FOLDER DETECTION
# ───────────────────────────────────────────────────────────────

# Detect spec folder from user prompt
# Patterns matched:
#   - specs/NNN-name, spec/NNN-name
#   - "spec folder NNN", "spec NNN"
#   - "working on NNN-name"
#   - Explicit spec folder mentions
detect_spec_folder() {
  local prompt="$1"
  local detected=""

  # Pattern 1: Direct path reference (specs/NNN-name or spec/NNN-name)
  if [[ "$prompt" =~ specs?/([0-9]{2,3}-[a-zA-Z0-9_-]+) ]]; then
    detected="${BASH_REMATCH[1]}"
    log_debug "Detected spec folder from path: $detected"
    echo "$detected"
    return 0
  fi

  # Pattern 2: "spec folder NNN" or "spec NNN"
  if [[ "$prompt" =~ spec[[:space:]]+(folder[[:space:]]+)?([0-9]{2,3})-?([a-zA-Z0-9_-]*) ]]; then
    local num="${BASH_REMATCH[2]}"
    local name="${BASH_REMATCH[3]}"
    if [[ -n "$name" ]]; then
      detected="${num}-${name}"
    else
      # Try to find matching spec folder by number
      detected=$(find_spec_by_number "$num")
    fi
    if [[ -n "$detected" ]]; then
      log_debug "Detected spec folder from phrase: $detected"
      echo "$detected"
      return 0
    fi
  fi

  # Pattern 3: "working on NNN-name" or "continue NNN-name"
  if [[ "$prompt" =~ (working[[:space:]]+on|continue|resume)[[:space:]]+([0-9]{2,3}-[a-zA-Z0-9_-]+) ]]; then
    detected="${BASH_REMATCH[2]}"
    log_debug "Detected spec folder from action: $detected"
    echo "$detected"
    return 0
  fi

  # Pattern 4: Check for common spec folder names mentioned
  # Look for patterns like "memory surfacing", "hook enhancement", etc.
  local specs_dir="${SCRIPT_DIR}/../../../specs"
  if [[ -d "$specs_dir" ]]; then
    # Get list of spec folder names
    local spec_folders
    spec_folders=$(ls -1 "$specs_dir" 2>/dev/null | grep -E '^[0-9]{2,3}-' || true)

    local prompt_lower
    prompt_lower=$(echo "$prompt" | tr '[:upper:]' '[:lower:]')

    for folder in $spec_folders; do
      # Extract the name part (without number prefix)
      local folder_name
      folder_name=$(echo "$folder" | sed 's/^[0-9]*-//' | tr '-' ' ')

      # Check if folder name keywords appear in prompt
      if [[ "$prompt_lower" == *"$folder_name"* ]]; then
        detected="$folder"
        log_debug "Detected spec folder from name match: $detected"
        echo "$detected"
        return 0
      fi
    done
  fi

  echo ""
  return 1
}

# Find spec folder by number prefix
find_spec_by_number() {
  local num="$1"
  local specs_dir="${SCRIPT_DIR}/../../../specs"

  if [[ -d "$specs_dir" ]]; then
    local match
    match=$(ls -1 "$specs_dir" 2>/dev/null | grep -E "^0*${num}-" | head -1 || true)
    echo "$match"
  fi
}

# ───────────────────────────────────────────────────────────────
# RECENT MEMORY QUERY
# ───────────────────────────────────────────────────────────────

# Query recent memories for a spec folder (last 7 days)
# Returns JSON array of recent memories
query_recent_memories() {
  local spec_folder="$1"

  # Check if vector-index script exists
  if [[ ! -f "$VECTOR_INDEX_SCRIPT" ]]; then
    log_debug "Vector index script not found: $VECTOR_INDEX_SCRIPT"
    echo "[]"
    return
  fi

  local memories
  memories=$(node -e "
    'use strict';

    try {
      const vectorIndex = require('${VECTOR_INDEX_SCRIPT}');
      const fs = require('fs');
      const path = require('path');

      // Initialize database
      vectorIndex.initializeDb();

      // Get memories for this spec folder
      const memories = vectorIndex.getMemoriesByFolder('${spec_folder}');

      if (!memories || memories.length === 0) {
        console.log('[]');
        process.exit(0);
      }

      // Calculate date threshold (last ${RECENT_DAYS} days)
      const threshold = new Date();
      threshold.setDate(threshold.getDate() - ${RECENT_DAYS});

      // Filter to recent memories and enrich with age
      const recent = memories
        .filter(m => {
          const created = new Date(m.created_at);
          return created >= threshold;
        })
        .map(m => {
          const created = new Date(m.created_at);
          const now = new Date();
          const diffDays = Math.floor((now - created) / (1000 * 60 * 60 * 24));

          // Format age string
          let age;
          if (diffDays === 0) {
            age = 'today';
          } else if (diffDays === 1) {
            age = 'yesterday';
          } else {
            age = diffDays + ' days ago';
          }

          return {
            id: m.id,
            title: m.title || path.basename(m.file_path, '.md'),
            filePath: m.file_path,
            specFolder: m.spec_folder,
            age: age,
            daysAgo: diffDays,
            importance: m.importance_weight || 0.5
          };
        })
        .sort((a, b) => {
          // Sort by recency first, then importance
          if (a.daysAgo !== b.daysAgo) {
            return a.daysAgo - b.daysAgo;
          }
          return b.importance - a.importance;
        })
        .slice(0, ${MAX_MEMORIES});

      console.log(JSON.stringify(recent));
    } catch (e) {
      // Silent failure - return empty array
      console.log('[]');
    }
  " 2>/dev/null || echo "[]")

  echo "$memories"
}

# ───────────────────────────────────────────────────────────────
# INTERACTIVE PROMPT FORMATTING
# ───────────────────────────────────────────────────────────────

# Format interactive context prompt
# Shows numbered memory selections with age
format_context_prompt() {
  local memories_json="$1"
  local spec_folder="$2"

  local formatted
  formatted=$(node -e "
    'use strict';

    try {
      const memories = JSON.parse(process.argv[1]);
      const specFolder = process.argv[2];

      if (!memories || memories.length === 0) {
        console.log('');
        process.exit(0);
      }

      const lines = [];

      // Header box
      lines.push('');
      lines.push('<!-- PROACTIVE_CONTEXT_SURFACING -->');
      lines.push('');
      lines.push('---');
      lines.push('');
      lines.push('**Found relevant context from your previous session(s):**');
      lines.push('');

      // Numbered memory list
      for (let i = 0; i < memories.length; i++) {
        const m = memories[i];
        const num = i + 1;
        lines.push('  **[' + num + ']** ' + m.title + ' (' + m.age + ')');
      }

      lines.push('');
      lines.push('**Load context?** Reply with: [1] [2] [3] [all] [skip]');
      lines.push('');
      lines.push('---');
      lines.push('');
      lines.push('<!-- END_PROACTIVE_CONTEXT_SURFACING -->');

      console.log(lines.join('\\n'));
    } catch (e) {
      console.log('');
    }
  " "$memories_json" "$spec_folder" 2>/dev/null || echo "")

  echo "$formatted"
}

# ───────────────────────────────────────────────────────────────
# TRIGGER PHRASE MATCHING (Original Functionality)
# ───────────────────────────────────────────────────────────────

# Match trigger phrases in prompt
match_trigger_phrases() {
  local sanitized_prompt="$1"

  if [[ ! -f "$MATCHER_SCRIPT" ]]; then
    echo ""
    return
  fi

  local matches
  matches=$(node -e "
    const matcher = require('${MATCHER_SCRIPT}');
    const prompt = process.argv[1];
    try {
      const results = matcher.matchTriggerPhrases(prompt, 3);
      if (results.length > 0) {
        console.log(JSON.stringify(results));
      }
    } catch (e) {
      // Silent failure
    }
  " "$sanitized_prompt" 2>/dev/null || true)

  echo "$matches"
}

# Format trigger match results
format_trigger_matches() {
  local matches="$1"

  local formatted
  formatted=$(node -e "
    const matches = JSON.parse(process.argv[1]);
    const lines = ['<!-- SURFACED_MEMORIES -->', ''];
    lines.push('**Related memories found:**');
    lines.push('');
    for (const match of matches) {
      const phrases = match.matchedPhrases.slice(0, 3).join(', ');
      lines.push('- **' + match.specFolder + '**: ' + (match.title || 'Memory') + ' (matched: ' + phrases + ')');
      lines.push('  File: \\\`' + match.filePath + '\\\`');
    }
    lines.push('');
    lines.push('<!-- END_SURFACED_MEMORIES -->');
    console.log(lines.join('\\\\n'));
  " "$matches" 2>/dev/null || true)

  echo "$formatted"
}

# ───────────────────────────────────────────────────────────────
# MAIN LOGIC
# ───────────────────────────────────────────────────────────────

main() {
  local start_time
  start_time=$(get_time_ms)

  # Read hook data from stdin
  local hook_data
  if ! hook_data=$(cat 2>/dev/null); then
    output_error
    return
  fi

  # Extract prompt from JSON
  local prompt
  prompt=$(echo "$hook_data" | jq -r '.prompt // empty' 2>/dev/null || true)

  # Skip if no prompt
  if [[ -z "$prompt" ]]; then
    output_json "" true
    return
  fi

  # Skip very short prompts
  if [[ ${#prompt} -lt 10 ]]; then
    output_json "" true
    return
  fi

  # Sanitize prompt - remove dangerous characters for security
  local sanitized_prompt
  sanitized_prompt=$(echo "$prompt" | tr -d '`$(){}[]\\' | head -c 5000)

  log_debug "Processing prompt: ${sanitized_prompt:0:100}..."

  # ─────────────────────────────────────────────────────────────
  # PHASE 0: SESSION PREFERENCE DETECTION (Gate 3)
  # ─────────────────────────────────────────────────────────────

  # Check if prompt contains preference phrase and update state
  local pref_change
  pref_change=$(detect_preference_phrase "$sanitized_prompt" || true)

  if [[ -n "$pref_change" ]]; then
    log_debug "Preference phrase detected, setting to: $pref_change"
    # If user just set preference, acknowledge but continue processing
    # (preference will apply to subsequent prompts)
  fi

  # Get current session preference
  local session_pref
  session_pref=$(get_session_preference)
  log_debug "Current session preference: $session_pref"

  # If preference is "skip", bypass all memory surfacing
  if [[ "$session_pref" == "skip" ]]; then
    log_debug "Session preference is 'skip' - bypassing memory surfacing"
    output_json "" true
    return
  fi

  # ─────────────────────────────────────────────────────────────
  # PHASE 1: SPEC FOLDER DETECTION (Proactive Context Surfacing)
  # ─────────────────────────────────────────────────────────────

  local spec_folder
  spec_folder=$(detect_spec_folder "$sanitized_prompt" || true)

  if [[ -n "$spec_folder" ]]; then
    log_debug "Spec folder detected: $spec_folder"

    # Query recent memories for this spec folder
    local memories_json
    memories_json=$(query_recent_memories "$spec_folder")

    log_debug "Recent memories: $memories_json"

    # Check if we have memories to surface
    local memory_count
    memory_count=$(echo "$memories_json" | jq -r 'length' 2>/dev/null || echo 0)

    if [[ "$memory_count" -gt 0 ]]; then
      # Apply session preference behavior
      if [[ "$session_pref" == "auto-load" ]]; then
        # Auto-load: Load most recent memory automatically without asking
        log_debug "Auto-loading most recent memory (session preference)"
        local most_recent_path
        most_recent_path=$(echo "$memories_json" | jq -r '.[0].filePath // empty' 2>/dev/null)

        if [[ -n "$most_recent_path" ]]; then
          local auto_context
          auto_context="<!-- AUTO_LOADED_CONTEXT (session preference: auto-load) -->\n\n**Auto-loading context:** $(echo "$memories_json" | jq -r '.[0].title // "Recent session"' 2>/dev/null)\n\nUse \`Read\` tool to load: \`$most_recent_path\`\n\n<!-- END_AUTO_LOADED_CONTEXT -->"

          local escaped
          escaped=$(echo -e "$auto_context" | jq -Rs '.' 2>/dev/null | sed 's/^"//;s/"$//')
          output_json "$escaped" true
          return
        fi
      else
        # Interactive (default): Show numbered prompt
        local context_prompt
        context_prompt=$(format_context_prompt "$memories_json" "$spec_folder")

        if [[ -n "$context_prompt" ]]; then
          # Performance check for context surfacing
          local elapsed
          elapsed=$(get_elapsed_ms "$start_time")
          log_perf "context_surfacing" "$elapsed" "$CONTEXT_SURFACE_BUDGET_MS"

          # Escape for JSON
          local escaped
          escaped=$(echo "$context_prompt" | jq -Rs '.' 2>/dev/null | sed 's/^"//;s/"$//')
          output_json "$escaped" true
          return
        fi
      fi
    fi
  fi

  # ─────────────────────────────────────────────────────────────
  # PHASE 2: TRIGGER PHRASE MATCHING (Original Functionality)
  # ─────────────────────────────────────────────────────────────

  local trigger_start
  trigger_start=$(get_time_ms)

  local matches
  matches=$(match_trigger_phrases "$sanitized_prompt")

  # Performance check for trigger matching
  local trigger_elapsed
  trigger_elapsed=$(get_elapsed_ms "$trigger_start")
  log_perf "trigger_matching" "$trigger_elapsed" "$TRIGGER_MATCH_BUDGET_MS"

  # Skip if no matches
  if [[ -z "$matches" || "$matches" == "[]" ]]; then
    output_json "" true
    return
  fi

  # Format surfaced memories as context injection
  local formatted
  formatted=$(format_trigger_matches "$matches")

  # Total performance check
  local total_elapsed
  total_elapsed=$(get_elapsed_ms "$start_time")
  log_perf "total_execution" "$total_elapsed" "$CONTEXT_SURFACE_BUDGET_MS"

  # Output formatted context
  if [[ -n "$formatted" ]]; then
    local escaped
    escaped=$(echo "$formatted" | jq -Rs '.' 2>/dev/null | sed 's/^"//;s/"$//')
    output_json "$escaped" true
  else
    output_json "" true
  fi
}

# ───────────────────────────────────────────────────────────────
# ENTRY POINT
# ───────────────────────────────────────────────────────────────

main "$@"
