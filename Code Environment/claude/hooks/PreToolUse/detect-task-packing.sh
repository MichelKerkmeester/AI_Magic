#!/bin/bash

# ───────────────────────────────────────────────────────────────
# DETECT TASK PACKING HOOK
# ───────────────────────────────────────────────────────────────
# PreToolUse hook that monitors for task packing anti-patterns.
# Tracks files modified in the current session and warns when
# thresholds are exceeded (>5 files or >3 domains).
#
# This is a WARNING-ONLY hook - it does not block operations.
#
# Version: 1.0.0
# Created: 2025-12-06
# Spec: specs/013-speckit-enhancements-from-repo-reference/ (T102-T103)
#
# EXECUTION ORDER: PreToolUse hook (runs BEFORE tool execution)
#   1. UserPromptSubmit hooks (FIRST - before user prompt processing)
#   2. PreToolUse hooks (SECOND - before tool execution, validation) ← THIS HOOK
#   3. PostToolUse hooks (LAST - after tool completion, verification)
#
# EXIT CODE CONVENTION:
#   0 = Allow (always - this hook only warns, never blocks)
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
LOG_FILE="$LOG_DIR/detect-task-packing.log"

mkdir -p "$LOG_DIR" 2>/dev/null || true

# Thresholds for warning
readonly WARN_FILE_THRESHOLD=5
readonly WARN_DOMAIN_THRESHOLD=3

# Cooldown: Only warn once per 10 minutes
readonly WARN_COOLDOWN_SECONDS=600

# ============================================================================
# LOAD DEPENDENCIES
# ============================================================================

# Load exit codes
if [ -f "$HOOKS_DIR/lib/exit-codes.sh" ]; then
  source "$HOOKS_DIR/lib/exit-codes.sh"
else
  EXIT_ALLOW=0
fi

# Load task validation library
if [ -f "$HOOKS_DIR/lib/task-validation.sh" ]; then
  source "$HOOKS_DIR/lib/task-validation.sh"
  TASK_VAL_LOADED=true
else
  # Library not available - exit silently
  exit 0
fi

# Load shared state for cooldown tracking
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

# Check if warning cooldown has passed
should_show_warning() {
  # Check for recent warning
  if type has_hook_state &>/dev/null; then
    if has_hook_state "task_packing_warned" "$WARN_COOLDOWN_SECONDS" 2>/dev/null; then
      return 1  # Still in cooldown
    fi
  fi
  
  return 0  # OK to show warning
}

# Mark that warning was shown
mark_warning_shown() {
  if type write_hook_state &>/dev/null; then
    local timestamp
    timestamp=$(date -u +%Y-%m-%dT%H:%M:%SZ 2>/dev/null || date +%Y-%m-%dT%H:%M:%SZ)
    write_hook_state "task_packing_warned" "{\"warned\":true,\"timestamp\":\"$timestamp\"}" 2>/dev/null || true
  fi
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

# ============================================================================
# MAIN DETECTION LOGIC
# ============================================================================

main() {
  # Read JSON input from stdin
  local input
  input=$(cat)
  
  if [ -z "$input" ]; then
    exit $EXIT_ALLOW
  fi
  
  # Parse tool name
  local tool_name
  if command -v jq &>/dev/null; then
    tool_name=$(echo "$input" | jq -r '.tool_name // .name // .tool // empty' 2>/dev/null)
  else
    tool_name=$(parse_json_field "$input" ".tool_name")
    [ -z "$tool_name" ] && tool_name=$(parse_json_field "$input" ".name")
  fi
  
  # Only check on file-modifying tools
  if [[ ! "$tool_name" =~ ^(Write|Edit|NotebookEdit)$ ]]; then
    exit $EXIT_ALLOW
  fi
  
  # Get current session stats
  local file_count
  local domain_count
  
  file_count=$(get_session_file_count 2>/dev/null) || file_count=0
  domain_count=$(get_session_domains 2>/dev/null) || domain_count=0
  
  # Check thresholds
  local should_warn=false
  local warnings=""
  
  if [ "$file_count" -ge "$WARN_FILE_THRESHOLD" ]; then
    should_warn=true
    warnings="$warnings  • $file_count files modified (threshold: $WARN_FILE_THRESHOLD)\n"
  fi
  
  if [ "$domain_count" -ge "$WARN_DOMAIN_THRESHOLD" ]; then
    should_warn=true
    warnings="$warnings  • $domain_count domains touched (threshold: $WARN_DOMAIN_THRESHOLD)\n"
  fi
  
  # Show warning if thresholds exceeded and not in cooldown
  if [ "$should_warn" = true ] && should_show_warning; then
    log_event "PACKING_DETECTED" "Files: $file_count, Domains: $domain_count"
    
    # Get task splitting suggestions
    local suggestions
    suggestions=$(get_task_split_suggestions 2>/dev/null) || suggestions=""
    
    echo ""
    echo "────────────────────────────────────────────────────────────────"
    echo "⚠️  TASK PACKING WARNING"
    echo "────────────────────────────────────────────────────────────────"
    echo ""
    echo "This task may be too large. Consider splitting it."
    echo ""
    echo "Current session metrics:"
    echo -e "$warnings"
    echo ""
    if [ -n "$suggestions" ]; then
      echo "$suggestions"
      echo ""
    fi
    echo "Benefits of smaller tasks:"
    echo "  • Easier to review and verify"
    echo "  • Cleaner commit history"
    echo "  • Better error isolation"
    echo "  • Improved progress tracking"
    echo ""
    echo "────────────────────────────────────────────────────────────────"
    echo ""
    
    # Mark that we warned (cooldown)
    mark_warning_shown
  fi
  
  # Always allow - this is warning only
  exit $EXIT_ALLOW
}

# ============================================================================
# EXECUTION
# ============================================================================

main "$@"
