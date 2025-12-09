#!/bin/bash

# ───────────────────────────────────────────────────────────────
# ENHANCED TASK DISPATCH ANNOUNCEMENT HOOK
# ───────────────────────────────────────────────────────────────
# PreToolUse hook that displays rich agent launch information with
# metadata integration before Task tool executes.
#
# ENHANCEMENTS (v2.0):
#   - Rich metadata capture (complexity, domains, skills, batch)
#   - Double-line box formatting for high visibility (╔══╗)
#   - Integration with orchestrate-skill-validation.sh
#   - Structured JSON state for PostToolUse correlation
#   - Batch dispatch context and position tracking
#
# DISPLAY LOGIC:
#   - 1-2 agents: Enhanced compact format with full metadata
#   - 3+ agents: Batch format with position and context
#
# PERFORMANCE TARGET: <20ms
# COMPATIBILITY: Bash 3.2+ (macOS and Linux compatible)
#
# EXIT CODE: Always 0 (informational only, never blocks Task tool)
# ───────────────────────────────────────────────────────────────

# Script setup
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" 2>/dev/null && pwd)"
HOOKS_DIR="$(cd "$SCRIPT_DIR/.." 2>/dev/null && pwd)"

# Source libraries (silent failures - hook should not block on missing libs)
source "$HOOKS_DIR/lib/output-helpers.sh" 2>/dev/null || true
source "$HOOKS_DIR/lib/agent-tracking.sh" 2>/dev/null || true
source "$HOOKS_DIR/lib/shared-state.sh" 2>/dev/null || true
source "$HOOKS_DIR/lib/perf-timing.sh" 2>/dev/null || true

# Logging
LOG_FILE="$HOOKS_DIR/logs/task-dispatch.log"
mkdir -p "$(dirname "$LOG_FILE")" 2>/dev/null

# Performance timing (using centralized _get_nano_time from perf-timing.sh)
START_TIME=$(_get_nano_time)

# Read JSON input from stdin
INPUT=$(cat)

# Extract tool name
TOOL_NAME=$(echo "$INPUT" | jq -r '.name // empty' 2>/dev/null)

# Only process Task tool calls
if [ "$TOOL_NAME" != "Task" ]; then
  exit 0
fi

# ───────────────────────────────────────────────────────────────
# EXTRACT TASK PARAMETERS
# ───────────────────────────────────────────────────────────────

DESCRIPTION=$(echo "$INPUT" | jq -r '.tool_input.description // "Sub-agent"' 2>/dev/null)
MODEL=$(echo "$INPUT" | jq -r '.tool_input.model // "inherit"' 2>/dev/null)
TIMEOUT=$(echo "$INPUT" | jq -r '.tool_input.timeout // 300000' 2>/dev/null)
SUBAGENT_TYPE=$(echo "$INPUT" | jq -r '.tool_input.subagent_type // "general-purpose"' 2>/dev/null)
PROMPT=$(echo "$INPUT" | jq -r '.tool_input.prompt // ""' 2>/dev/null)

# ───────────────────────────────────────────────────────────────
# FETCH COMPLEXITY METADATA (from orchestrate-skill-validation)
# ───────────────────────────────────────────────────────────────

COMPLEXITY_STATE=$(read_hook_state "complexity" 2>/dev/null || echo "{}")
COMPLEXITY_SCORE=$(echo "$COMPLEXITY_STATE" | jq -r '.complexity_score // 0' 2>/dev/null)
DOMAIN_COUNT=$(echo "$COMPLEXITY_STATE" | jq -r '.domain_count // 0' 2>/dev/null)

# ───────────────────────────────────────────────────────────────
# EXTRACT DOMAINS AND SKILLS FROM PROMPT
# ───────────────────────────────────────────────────────────────

extract_domains_from_prompt() {
  local prompt="$1"
  local prompt_lower=$(echo "$prompt" | tr '[:upper:]' '[:lower:]')
  local detected_domains=""

  # Detect domains (synced with orchestrate logic)
  if echo "$prompt_lower" | grep -qE "(implement|code|refactor|function|class|component|backend|frontend|fix|bug|debug|error|issue|problem|resolve|patch|hotfix|optimize|improve|enhance|script|module|service|handler|controller|model|util|helper|endpoint|route)"; then
    detected_domains="${detected_domains}code,"
  fi

  if echo "$prompt_lower" | grep -qE "(analyze|investigate|explore|examine|audit|inspect|trace|profile|benchmark|diagnose|troubleshoot|discover|locate|scan)"; then
    detected_domains="${detected_domains}analysis,"
  fi

  if echo "$prompt_lower" | grep -qE "(document|readme|guide|tutorial|api.*doc|comment|explain|release.*notes|specification|spec.*doc|jsdoc|typedoc|markdown|wiki)"; then
    detected_domains="${detected_domains}docs,"
  fi

  if echo "$prompt_lower" | grep -qE "(git|commit|branch|merge|pull.*request|migration|version|pr\b|tag|release|changelog|rebase|cherry.*pick)"; then
    detected_domains="${detected_domains}git,"
  fi

  if echo "$prompt_lower" | grep -qE "(test|unittest|integration.*test|e2e|coverage|spec\b|assert|mock|stub|fixture|snapshot|playwright|jest|vitest|bats|pytest)"; then
    detected_domains="${detected_domains}testing,"
  fi

  if echo "$prompt_lower" | grep -qE "(deploy|ci|cd|docker|build|pipeline|infrastructure|kubernetes|k8s|helm|terraform|ansible|aws|gcp|azure|nginx|ssl|certificate|monitoring|logging|metrics)"; then
    detected_domains="${detected_domains}devops,"
  fi

  # Remove trailing comma
  detected_domains="${detected_domains%,}"

  # Default to code if nothing detected
  if [[ -z "$detected_domains" ]]; then
    detected_domains="code"
  fi

  echo "$detected_domains"
}

get_skills_for_domain() {
  local domain="$1"
  case "$domain" in
    "code")
      echo "workflows-code,mcp-semantic-search"
      ;;
    "analysis")
      echo "mcp-semantic-search,workflows-code"
      ;;
    "docs")
      echo "create-documentation,workflows-spec-kit"
      ;;
    "git")
      echo "workflows-git,workflows-memory"
      ;;
    "testing")
      echo "workflows-code,mcp-semantic-search"
      ;;
    "devops")
      echo "mcp-code-mode,cli-gemini"
      ;;
    *)
      echo "workflows-code"
      ;;
  esac
}

# Extract domain from prompt
DETECTED_DOMAINS=$(extract_domains_from_prompt "$PROMPT")
PRIMARY_DOMAIN=$(echo "$DETECTED_DOMAINS" | cut -d',' -f1)
SKILLS=$(get_skills_for_domain "$PRIMARY_DOMAIN")

# ───────────────────────────────────────────────────────────────
# GENERATE AGENT ID AND TRACK
# ───────────────────────────────────────────────────────────────

AGENT_ID=$(generate_agent_id 2>/dev/null || echo "agent_$(date +%s)")

# Get current session agent count for display logic
AGENT_COUNT=$(get_agent_count 2>/dev/null)
# Ensure AGENT_COUNT is a valid number (default to 1)
if ! [[ "$AGENT_COUNT" =~ ^[0-9]+$ ]]; then
  AGENT_COUNT=1
fi

# Check for existing batch context
PENDING_DISPATCH=$(read_hook_state "pending_dispatch" 2>/dev/null || echo "{}")
EXPECTED_AGENTS=$(echo "$PENDING_DISPATCH" | jq -r '.agents // 0' 2>/dev/null)

BATCH_ID=""
BATCH_POSITION=""

# If this is part of a parallel dispatch (expected_agents > 1), manage batch
if [ "$EXPECTED_AGENTS" -gt 1 ]; then
  # Check for existing batch
  ACTIVE_BATCH=$(read_hook_state "active_batch" 2>/dev/null || echo "{}")
  BATCH_ID=$(echo "$ACTIVE_BATCH" | jq -r '.batch_id // empty' 2>/dev/null)

  if [ -z "$BATCH_ID" ]; then
    # Create new batch
    BATCH_ID=$(create_batch_dispatch 2>/dev/null)
    BATCH_STATE=$(cat <<EOF
{"batch_id":"$BATCH_ID","expected_count":$EXPECTED_AGENTS,"created_at":"$(date -u +%Y-%m-%dT%H:%M:%SZ)"}
EOF
)
    write_hook_state "active_batch" "$BATCH_STATE" 2>/dev/null || true
  fi

  # Add agent to batch
  add_agent_to_batch "$BATCH_ID" "$AGENT_ID" 2>/dev/null || true

  # Calculate batch position
  BATCH_POSITION="${AGENT_COUNT}/${EXPECTED_AGENTS}"
fi

# Start agent tracking with enhanced metadata
start_agent_tracking "$AGENT_ID" "$DESCRIPTION" "$MODEL" "$TIMEOUT" 2>/dev/null || true

# Create timestamp file for enforce-markdown-post-task.sh to find recently created files
# This file is checked by the post-task hook to only process files created during this Task
touch "/tmp/.claude_task_start_$$" 2>/dev/null || true
# Cleanup trap to prevent temp file resource leak
trap "rm -f /tmp/.claude_task_start_$$" EXIT

# Store enhanced metadata in agent state
# Use get_state_dir() if available, fallback to hardcoded path for compatibility
if command -v get_state_dir >/dev/null 2>&1; then
  STATE_FILE="$(get_state_dir)/agent_tracking.json"
else
  STATE_FILE="/tmp/claude_hooks_state/agent_tracking.json"
fi
if [ -f "$STATE_FILE" ]; then
  # Enrich agent record with metadata
  TEMP_STATE=$(jq --arg id "$AGENT_ID" \
    --arg complexity "$COMPLEXITY_SCORE" \
    --arg domains "$DETECTED_DOMAINS" \
    --arg skills "$SKILLS" \
    --arg batch "$BATCH_ID" '
    if .active_agents[$id] then
      .active_agents[$id].complexity_score = ($complexity | tonumber) |
      .active_agents[$id].domains = ($domains | split(",")) |
      .active_agents[$id].skills = ($skills | split(",")) |
      .active_agents[$id].batch_id = (if $batch == "" then null else $batch end)
    else . end
  ' "$STATE_FILE" 2>/dev/null)

  if [ -n "$TEMP_STATE" ]; then
    echo "$TEMP_STATE" > "$STATE_FILE" 2>/dev/null
  fi
fi

# ───────────────────────────────────────────────────────────────
# FORMATTING UTILITIES
# ───────────────────────────────────────────────────────────────

format_timeout() {
  local ms="$1"
  local seconds=$((ms / 1000))
  if [ "$seconds" -ge 60 ]; then
    echo "$((seconds / 60))min"
  else
    echo "${seconds}s"
  fi
}

TIMEOUT_HUMAN=$(format_timeout "$TIMEOUT")

truncate_text() {
  local text="$1"
  local max="$2"
  if [ ${#text} -gt $max ]; then
    echo "${text:0:$((max-3))}..."
  else
    echo "$text"
  fi
}

DESC_SHORT=$(truncate_text "$DESCRIPTION" 46)
SKILLS_SHORT=$(truncate_text "$SKILLS" 46)

# Estimate duration from complexity score
estimate_duration() {
  local complexity="$1"
  # Formula: duration ≈ (complexity / 100) * 10 minutes
  # Returns range like "2-4min"
  if [ "$complexity" -gt 0 ]; then
    local base=$(awk "BEGIN {printf \"%.0f\", $complexity * 0.1}" 2>/dev/null || echo "3")
    local low=$((base - 1))
    local high=$((base + 1))

    # Ensure minimum of 1 min
    if [ "$low" -lt 1 ]; then
      low=1
    fi

    echo "${low}-${high}min"
  else
    echo "3-5min"
  fi
}

DURATION_EST=$(estimate_duration "$COMPLEXITY_SCORE")

# Complexity label
get_complexity_label() {
  local score="$1"
  if awk "BEGIN {exit !($score >= 50)}" 2>/dev/null; then
    echo "High"
  elif awk "BEGIN {exit !($score >= 35)}" 2>/dev/null; then
    echo "Medium"
  elif awk "BEGIN {exit !($score >= 25)}" 2>/dev/null; then
    echo "Low"
  else
    echo "Minimal"
  fi
}

COMPLEXITY_LABEL=$(get_complexity_label "$COMPLEXITY_SCORE")

# ───────────────────────────────────────────────────────────────
# ENHANCED DISPLAY OUTPUT
# ───────────────────────────────────────────────────────────────

# Helper: Escape JSON string (handles quotes, backslashes, newlines)
json_escape() {
  local str="$1"
  # Use jq if available for proper escaping
  if command -v jq >/dev/null 2>&1; then
    printf '%s' "$str" | jq -Rs '.' | sed 's/^"//;s/"$//'
  else
    # Fallback: basic escaping for common characters
    printf '%s' "$str" | sed 's/\\/\\\\/g; s/"/\\"/g; s/\t/\\t/g' | tr -d '\n'
  fi
}

# Display logic: Enhanced format for all agents with rich metadata
if [ -z "$BATCH_ID" ]; then
  # ─────────────────────────────────────────────────────────────
  # SINGLE AGENT FORMAT (enhanced with metadata)
  # ─────────────────────────────────────────────────────────────

  # JSON systemMessage for terminal visibility (REQUIRED for Claude Code)
  ESCAPED_DESC=$(json_escape "$DESC_SHORT")
  ESCAPED_TYPE=$(json_escape "$SUBAGENT_TYPE")
  ESCAPED_MODEL=$(json_escape "$MODEL")
  echo "{\"systemMessage\": \"Agent #${AGENT_COUNT} DISPATCHED: ${ESCAPED_TYPE} | Model: ${ESCAPED_MODEL} | Domain: ${PRIMARY_DOMAIN} | Task: ${ESCAPED_DESC}\"}"

  # Detailed box format for logs/verbose mode
  {
    echo ""
    echo "╔══════════════════════════════════════════════════════════╗"
    printf "║ 🤖 AGENT #%-3d DISPATCHED: %-29s║\n" "$AGENT_COUNT" "${SUBAGENT_TYPE}"
    echo "╠══════════════════════════════════════════════════════════╣"
    printf "║ Task: %-50s ║\n" "$DESC_SHORT"
    printf "║ Model: %-6s | Timeout: %-4s | Complexity: %-3.0f%% (%-7s) ║\n" "$MODEL" "$TIMEOUT_HUMAN" "$COMPLEXITY_SCORE" "$COMPLEXITY_LABEL"
    printf "║ Skills: %-48s ║\n" "$SKILLS_SHORT"
    printf "║ Domain: %-15s | Estimated: %-19s║\n" "$PRIMARY_DOMAIN" "$DURATION_EST"
    echo "╚══════════════════════════════════════════════════════════╝"
    echo ""
  } >&2

else
  # ─────────────────────────────────────────────────────────────
  # BATCH FORMAT (parallel dispatch with position)
  # ─────────────────────────────────────────────────────────────

  # JSON systemMessage for terminal visibility (REQUIRED for Claude Code)
  ESCAPED_DESC=$(json_escape "$DESC_SHORT")
  ESCAPED_TYPE=$(json_escape "$SUBAGENT_TYPE")
  ESCAPED_MODEL=$(json_escape "$MODEL")
  echo "{\"systemMessage\": \"PARALLEL BATCH [${BATCH_POSITION}]: ${ESCAPED_TYPE} | Model: ${ESCAPED_MODEL} | Domain: ${PRIMARY_DOMAIN} | Task: ${ESCAPED_DESC}\"}"

  # Detailed box format for logs/verbose mode
  {
    echo ""
    echo "╔══════════════════════════════════════════════════════════╗"
    printf "║ 🚀 PARALLEL BATCH DISPATCH (Agent %-21s) ║\n" "$BATCH_POSITION"
    echo "╠══════════════════════════════════════════════════════════╣"
    printf "║ Batch: %-15s | Complexity: %-3.0f%% (%-11s) ║\n" "${BATCH_ID:0:15}" "$COMPLEXITY_SCORE" "$COMPLEXITY_LABEL"
    printf "║ Domain: %-15s | Agent: %-24s║\n" "$PRIMARY_DOMAIN" "${SUBAGENT_TYPE:0:24}"
    printf "║ Skills: %-48s ║\n" "$SKILLS_SHORT"
    printf "║ Estimated: %-9s | Model: %-26s║\n" "$DURATION_EST" "$MODEL"
    echo "╚══════════════════════════════════════════════════════════╝"
    echo ""
  } >&2
fi

# ───────────────────────────────────────────────────────────────
# STRUCTURED LOGGING
# ───────────────────────────────────────────────────────────────

{
  END_TIME=$(_get_nano_time)
  DURATION=$(( (END_TIME - START_TIME) / 1000000 ))

  echo "[$(date '+%Y-%m-%d %H:%M:%S')] DISPATCH"
  echo "  agent_id=$AGENT_ID"
  echo "  type=$SUBAGENT_TYPE"
  echo "  model=$MODEL"
  echo "  complexity=${COMPLEXITY_SCORE}%"
  echo "  domains=$DETECTED_DOMAINS"
  echo "  skills=$SKILLS"
  echo "  batch=$BATCH_ID"
  echo "  position=$BATCH_POSITION"
  echo "  count=$AGENT_COUNT"
  echo "  duration=${DURATION}ms"
  echo ""
} >> "$LOG_FILE" 2>/dev/null

# Always allow Task tool to proceed
exit 0
