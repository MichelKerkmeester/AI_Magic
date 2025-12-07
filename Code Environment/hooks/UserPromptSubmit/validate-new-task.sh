#!/bin/bash

# ───────────────────────────────────────────────────────────────
# VALIDATE NEW TASK HOOK
# ───────────────────────────────────────────────────────────────
# UserPromptSubmit hook that detects when a user starts a new task
# while another task is in_progress. Prompts user to complete or
# abandon the current task before starting a new one.
#
# Version: 1.0.0
# Created: 2025-12-06
# Spec: specs/013-speckit-enhancements-from-repo-reference/ (T104)
#
# EXECUTION ORDER: UserPromptSubmit hook (runs BEFORE user prompt processing)
#   1. UserPromptSubmit hooks (FIRST - before user prompt processing) ← THIS HOOK
#   2. PreToolUse hooks (SECOND - before tool execution, validation)
#   3. PostToolUse hooks (LAST - after tool completion, verification)
#
# EXIT CODE CONVENTION:
#   0 = Allow (continue processing)
#   2 = Block (show message and wait for user response)
#
# PERFORMANCE TARGET: <50ms validation time
# COMPATIBILITY: Bash 3.2+ (macOS and Linux compatible)
# ───────────────────────────────────────────────────────────────

# Strict mode for reliability
set -euo pipefail

# ============================================================================
# CONFIGURATION
# ============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" 2>/dev/null && pwd)"
HOOKS_DIR="$(cd "$SCRIPT_DIR/.." 2>/dev/null && pwd)"
PROJECT_ROOT=$(git rev-parse --show-toplevel 2>/dev/null || (cd "$SCRIPT_DIR/../.." && pwd))
LOG_DIR="$HOOKS_DIR/logs"
LOG_FILE="$LOG_DIR/validate-new-task.log"

mkdir -p "$LOG_DIR" 2>/dev/null || true

# ============================================================================
# LOAD DEPENDENCIES
# ============================================================================

# Load exit codes
if [ -f "$HOOKS_DIR/lib/exit-codes.sh" ]; then
  source "$HOOKS_DIR/lib/exit-codes.sh"
else
  EXIT_ALLOW=0
  EXIT_BLOCK=2
fi

# Load task validation library
if [ -f "$HOOKS_DIR/lib/task-validation.sh" ]; then
  source "$HOOKS_DIR/lib/task-validation.sh"
  TASK_VAL_LOADED=true
else
  # Library not available - allow all
  exit 0
fi

# Load shared state for question flow
if [ -f "$HOOKS_DIR/lib/shared-state.sh" ]; then
  source "$HOOKS_DIR/lib/shared-state.sh"
fi

# ============================================================================
# HELPER FUNCTIONS
# ============================================================================

# Log event with timestamp
log_event() {
  local status="$1"
  local detail="${2:-}"
  local timestamp
  timestamp=$(date '+%Y-%m-%d %H:%M:%S' 2>/dev/null || date)
  
  {
    echo "[$timestamp] STATUS: $status"
    [ -n "$detail" ] && echo "  Detail: $detail"
  } >> "$LOG_FILE" 2>/dev/null || true
}

# Parse JSON with jq or fallback
parse_json_field() {
  local json="$1"
  local field="$2"
  
  if command -v jq &>/dev/null; then
    echo "$json" | jq -r "$field // empty" 2>/dev/null
  else
    echo "$json" | grep -o "\"${field#.}\"[[:space:]]*:[[:space:]]*\"[^\"]*\"" | \
      sed 's/.*: *"//;s/"$//' | head -1
  fi
}

# Check if we're in a pending question flow
is_pending_task_question() {
  if type has_hook_state &>/dev/null; then
    if has_hook_state "new_task_question_pending" 600 2>/dev/null; then
      return 0
    fi
  fi
  return 1
}

# Mark question as pending
mark_question_pending() {
  if type write_hook_state &>/dev/null; then
    local timestamp
    timestamp=$(date -u +%Y-%m-%dT%H:%M:%SZ 2>/dev/null || date +%Y-%m-%dT%H:%M:%SZ)
    write_hook_state "new_task_question_pending" "{\"pending\":true,\"timestamp\":\"$timestamp\"}" 2>/dev/null || true
  fi
}

# Clear pending question
clear_question_pending() {
  if type clear_hook_state &>/dev/null; then
    clear_hook_state "new_task_question_pending" 2>/dev/null || true
  fi
}

# Detect user's choice from response
detect_user_choice() {
  local prompt="$1"
  local prompt_lower
  prompt_lower=$(echo "$prompt" | tr '[:upper:]' '[:lower:]')
  
  # Check for explicit A/B/C choice
  if echo "$prompt_lower" | grep -qE "^[[:space:]]*[abc][[:space:]]*$"; then
    echo "$prompt" | tr -d '[:space:]' | tr '[:lower:]' '[:upper:]'
    return 0
  fi
  
  # Check for option keywords
  if echo "$prompt_lower" | grep -qE "(option|choice|select)[[:space:]]*(a|b|c)"; then
    echo "$prompt_lower" | grep -oE "(option|choice|select)[[:space:]]*(a|b|c)" | grep -oE "[abc]" | tail -1 | tr '[:lower:]' '[:upper:]'
    return 0
  fi
  
  # Check for action keywords
  if echo "$prompt_lower" | grep -qiE "(complete|finish|done|mark.*(complete|done))"; then
    echo "A"
    return 0
  fi
  
  if echo "$prompt_lower" | grep -qiE "(abandon|cancel|stop|discard)"; then
    echo "B"
    return 0
  fi
  
  if echo "$prompt_lower" | grep -qiE "(continue|proceed|go ahead|keep going|override)"; then
    echo "C"
    return 0
  fi
  
  return 1
}

# ============================================================================
# MAIN VALIDATION LOGIC
# ============================================================================

main() {
  # Read JSON input from stdin
  local input
  input=$(cat)
  
  if [ -z "$input" ]; then
    exit $EXIT_ALLOW
  fi
  
  # Parse prompt from input
  local prompt
  if command -v jq &>/dev/null; then
    prompt=$(echo "$input" | jq -r '.prompt // empty' 2>/dev/null)
  else
    prompt=$(parse_json_field "$input" ".prompt")
  fi
  
  if [ -z "$prompt" ]; then
    exit $EXIT_ALLOW
  fi
  
  local prompt_lower
  prompt_lower=$(echo "$prompt" | tr '[:upper:]' '[:lower:]')
  local prompt_snippet="${prompt:0:100}"
  
  # ========================================================================
  # CHECK FOR PENDING QUESTION RESPONSE
  # ========================================================================
  
  if is_pending_task_question; then
    local choice
    choice=$(detect_user_choice "$prompt") || choice=""
    
    if [ -n "$choice" ]; then
      log_event "QUESTION_ANSWERED" "Choice: $choice"
      clear_question_pending
      
      case "$choice" in
        A)
          # Complete current task
          echo ""
          echo "✅ Marking current task as complete."
          echo ""
          clear_current_task
          exit $EXIT_ALLOW
          ;;
        B)
          # Abandon current task
          echo ""
          echo "🗑️  Abandoning current task. Starting fresh."
          echo ""
          clear_current_task
          exit $EXIT_ALLOW
          ;;
        C)
          # Continue anyway
          echo ""
          echo "⚡ Proceeding with new task alongside existing work."
          echo ""
          exit $EXIT_ALLOW
          ;;
      esac
    fi
    
    # Not a clear choice - continue to check if still a new task prompt
    clear_question_pending
  fi
  
  # ========================================================================
  # CHECK FOR NEW TASK INDICATORS
  # ========================================================================
  
  # Check if prompt contains task indicators
  if ! has_task_indicators "$prompt"; then
    # Not a task-starting prompt - allow
    exit $EXIT_ALLOW
  fi
  
  # Check if there's an active in_progress task
  if ! has_active_task; then
    # No active task - allow new task to start
    log_event "NEW_TASK" "Starting new task (no active task)"
    exit $EXIT_ALLOW
  fi
  
  # ========================================================================
  # ACTIVE TASK EXISTS - PROMPT USER
  # ========================================================================
  
  local active_task_info
  active_task_info=$(get_active_task_info 2>/dev/null) || active_task_info="Unknown task"
  
  local file_count
  file_count=$(get_session_file_count 2>/dev/null) || file_count=0
  
  log_event "TASK_CONFLICT" "New task detected while task in progress"
  mark_question_pending
  
  echo ""
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "⚠️  ACTIVE TASK IN PROGRESS"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo ""
  echo "You're starting a new task, but there's work in progress:"
  echo ""
  echo "  $active_task_info"
  echo "  Files modified: $file_count"
  echo ""
  echo "New request: \"$prompt_snippet...\""
  echo ""
  echo "Choose how to proceed:"
  echo ""
  echo "  A) Complete current task first (mark as done)"
  echo "  B) Abandon current task (discard progress)"
  echo "  C) Continue anyway (work on both)"
  echo ""
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo ""
  
  exit $EXIT_BLOCK
}

# ============================================================================
# EXECUTION
# ============================================================================

main "$@"
