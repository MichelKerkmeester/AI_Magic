#!/usr/bin/env bash

# ═══════════════════════════════════════════════════════════════════════════════
# Memory Surfacing Hook - Proactive Memory Surfacing via Trigger Phrases
# ═══════════════════════════════════════════════════════════════════════════════
#
# Version: 10.0.0
# Hook Event: UserPromptSubmit
# Performance Target: <50ms (NFR-P03)
#
# This hook surfaces relevant memories when trigger phrases are detected
# in the user's prompt. Uses exact string matching (NOT semantic/embedding).
#
# Usage: memory-surfacing.sh <stdin: hook_data_json>
# Input: JSON with "prompt" field
# Output: JSON with "result" and optionally "continue" fields
#
# ═══════════════════════════════════════════════════════════════════════════════

set -euo pipefail

# ───────────────────────────────────────────────────────────────
# CONFIGURATION
# ───────────────────────────────────────────────────────────────

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILL_DIR="${SCRIPT_DIR}/../../skills/workflows-save-context"
MATCHER_SCRIPT="${SKILL_DIR}/scripts/lib/trigger-matcher.js"

# Performance budget
MAX_EXECUTION_MS=50

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

# ───────────────────────────────────────────────────────────────
# MAIN LOGIC
# ───────────────────────────────────────────────────────────────

main() {
  local start_time=$(date +%s%3N 2>/dev/null || echo 0)

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

  # Skip very short prompts (unlikely to contain trigger phrases)
  if [[ ${#prompt} -lt 10 ]]; then
    output_json "" true
    return
  fi

  # Check if matcher script exists
  if [[ ! -f "$MATCHER_SCRIPT" ]]; then
    output_json "" true
    return
  fi

  # Sanitize prompt before use - remove dangerous characters to prevent command injection
  # Limit length to prevent DoS and remove backticks, dollar signs, parens, braces, brackets, backslashes
  local sanitized_prompt
  sanitized_prompt=$(echo "$prompt" | tr -d '`$(){}[]\\' | head -c 5000)

  # Run trigger matching via Node.js
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

  # Skip if no matches
  if [[ -z "$matches" || "$matches" == "[]" ]]; then
    output_json "" true
    return
  fi

  # Format surfaced memories as context injection
  local formatted
  formatted=$(node -e "
    const matches = JSON.parse(process.argv[1]);
    const lines = ['<!-- SURFACED_MEMORIES -->', ''];
    lines.push('**Related memories found:**');
    lines.push('');
    for (const match of matches) {
      const phrases = match.matchedPhrases.slice(0, 3).join(', ');
      lines.push('- **' + match.specFolder + '**: ' + (match.title || 'Memory') + ' (matched: ' + phrases + ')');
      lines.push('  File: \`' + match.filePath + '\`');
    }
    lines.push('');
    lines.push('<!-- END_SURFACED_MEMORIES -->');
    console.log(lines.join('\\n'));
  " "$matches" 2>/dev/null || true)

  # Performance check
  local end_time=$(date +%s%3N 2>/dev/null || echo 0)
  local elapsed=$((end_time - start_time))

  if [[ $elapsed -gt $MAX_EXECUTION_MS ]]; then
    # Log warning but don't fail
    echo "[memory-surfacing] WARNING: Execution took ${elapsed}ms (target: <${MAX_EXECUTION_MS}ms)" >&2
  fi

  # Output formatted context
  if [[ -n "$formatted" ]]; then
    # Escape for JSON
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
