#!/bin/bash

# ───────────────────────────────────────────────────────────────
# OFFER STATE RESTORE HOOK
# ───────────────────────────────────────────────────────────────
# PreSessionStart hook that checks for saved session state and
# offers to restore it for cross-session continuity.
#
# PRIMARY PURPOSE: State restoration offer (not blocking)
# - Checks for saved state artifacts
# - Offers restore options to user
# - Shows summary of what would be restored
#
# PERFORMANCE TARGET: <100ms
# COMPATIBILITY: Bash 3.2+ (macOS and Linux compatible)
#
# EXECUTION ORDER: PreSessionStart (after initialize-session.sh)
#
# EXIT CODE CONVENTION:
#   0 = Allow (hook passed, continue execution)
#   1 = Block (hook failed, stop execution with warning)
#   2 = Error (reserved for critical failures)
#
# Spec: 013-speckit-enhancements-from-repo-reference (US-025)
# Task: T186 - Integration with session hooks
#
# NOTE: This hook always returns 0 (non-blocking, informational)
# ───────────────────────────────────────────────────────────────

# Source output helpers
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" 2>/dev/null && pwd)"
HOOKS_DIR="$(cd "$SCRIPT_DIR/.." 2>/dev/null && pwd)"
PROJECT_ROOT=$(git rev-parse --show-toplevel 2>/dev/null || (cd "$SCRIPT_DIR/../.." && pwd))

# Source libraries silently
source "$HOOKS_DIR/lib/output-helpers.sh" 2>/dev/null || true
source "$HOOKS_DIR/lib/shared-state.sh" 2>/dev/null || true
source "$HOOKS_DIR/lib/exit-codes.sh" 2>/dev/null || true
source "$HOOKS_DIR/lib/speckit-state.sh" 2>/dev/null || true

# Directories
LOG_DIR="$HOOKS_DIR/logs"
PERF_LOG="$LOG_DIR/performance.log"
SESSION_LOG="$LOG_DIR/session.log"

# Ensure directories exist
mkdir -p "$LOG_DIR" 2>/dev/null

# Cross-platform nanosecond timing helper
_get_nano_time() {
  if [[ "$OSTYPE" == "darwin"* ]]; then
    echo $(($(date +%s) * 1000000000))
  else
    date +%s%N 2>/dev/null || echo $(($(date +%s) * 1000000000))
  fi
}

# Performance timing START
START_TIME=$(_get_nano_time)

# Read JSON input from stdin
INPUT=$(cat)

# Extract session info from payload (if available)
SESSION_ID=$(echo "$INPUT" | jq -r '.session_id // "unknown"' 2>/dev/null) || SESSION_ID="unknown"
CWD=$(echo "$INPUT" | jq -r '.cwd // "."' 2>/dev/null) || CWD="."

# Sanitize session ID
SESSION_ID=$(echo "$SESSION_ID" | tr -cd 'a-zA-Z0-9_-')
SESSION_ID="${SESSION_ID:-unknown}"

export CLAUDE_SESSION_ID="$SESSION_ID"

TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')

# ─── Check for saved state ───
STATE_OFFER=""
STATE_FILE=""

# Only check if speckit-state functions are available
if type get_latest_state &>/dev/null; then
  STATE_FILE=$(get_latest_state 2>/dev/null)
  
  if [ -n "$STATE_FILE" ] && [ -f "$STATE_FILE" ]; then
    # Generate restore offer
    if type restore_on_session_start &>/dev/null; then
      STATE_OFFER=$(restore_on_session_start 2>/dev/null)
    fi
  fi
fi

# ─── Output to Claude ───
# If we found saved state, emit a notification
if [ -n "$STATE_OFFER" ]; then
  # Read saved state for summary
  SAVED_STATE=$(cat "$STATE_FILE" 2>/dev/null)
  
  # Extract key info
  SPEC_NAME=""
  TASK_COUNT=""
  SAVED_AT=""
  
  if command -v jq &>/dev/null && [ -n "$SAVED_STATE" ]; then
    SPEC_NAME=$(echo "$SAVED_STATE" | jq -r '.spec_context.active_spec // "unknown"' 2>/dev/null | xargs basename 2>/dev/null)
    TASK_COUNT=$(echo "$SAVED_STATE" | jq -r '.task_state.pending_tasks | length' 2>/dev/null)
    SAVED_AT=$(echo "$SAVED_STATE" | jq -r '.generated_at // "unknown"' 2>/dev/null)
  fi
  
  # Log the offer
  {
    echo "  state_restore_offered: true"
    echo "  state_file: $STATE_FILE"
    echo "  spec_name: $SPEC_NAME"
    echo "  pending_tasks: ${TASK_COUNT:-0}"
    echo "  saved_at: $SAVED_AT"
  } >> "$SESSION_LOG" 2>/dev/null
  
  # Emit the offer as output (will be shown to Claude)
  # Using YAML-style for structured output that hooks can parse
  cat << EOF

<system-reminder>
PREVIOUS SESSION STATE FOUND

A saved session state was found from a previous session.

Spec: ${SPEC_NAME:-unknown}
Saved: ${SAVED_AT:-unknown}
Pending Tasks: ${TASK_COUNT:-0}

Would you like to:
  A) Restore this state and continue where you left off
  B) Start fresh (ignore saved state)
  C) View full state details before deciding

Reply with A, B, or C to proceed.

State file: $STATE_FILE
</system-reminder>

EOF

fi

# Performance timing END
END_TIME=$(_get_nano_time)
DURATION_MS=$(( (END_TIME - START_TIME) / 1000000 ))
echo "[$TIMESTAMP] offer-state-restore.sh ${DURATION_MS}ms" >> "$PERF_LOG" 2>/dev/null

# Always allow (non-blocking, informational)
exit ${EXIT_ALLOW:-0}
