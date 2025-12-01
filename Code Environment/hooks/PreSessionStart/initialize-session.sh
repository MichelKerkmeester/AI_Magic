#!/bin/bash

# ───────────────────────────────────────────────────────────────
# SESSION INITIALIZATION HOOK
# ───────────────────────────────────────────────────────────────
# PreSessionStart hook that initializes session state when a new
# Claude Code session begins.
#
# PRIMARY PURPOSE: Session setup and initialization (not blocking)
# - Creates session state directory
# - Initializes performance logging for the session
# - Cleans up stale state from previous sessions
# - Checks for pending spec folders
#
# PERFORMANCE TARGET: <100ms (initialization)
# COMPATIBILITY: Bash 3.2+ (macOS and Linux compatible)
#
# EXECUTION ORDER: PreSessionStart hook (runs when session begins)
#   This is the FIRST hook to run at the start of a session
#
# EXIT CODE CONVENTION:
#   0 = Allow (hook passed, continue execution)
#   1 = Block (hook failed, stop execution with warning)
#   2 = Error (reserved for critical failures)
#
# NOTE: This hook always returns 0 (non-blocking, initialization)
# ───────────────────────────────────────────────────────────────

# Source output helpers (completely silent on success)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" 2>/dev/null && pwd)"
HOOKS_DIR="$(cd "$SCRIPT_DIR/.." 2>/dev/null && pwd)"
PROJECT_ROOT=$(git rev-parse --show-toplevel 2>/dev/null || (cd "$SCRIPT_DIR/../.." && pwd))

# Source libraries silently
source "$HOOKS_DIR/lib/output-helpers.sh" 2>/dev/null || true
source "$HOOKS_DIR/lib/shared-state.sh" 2>/dev/null || true
source "$HOOKS_DIR/lib/exit-codes.sh" 2>/dev/null || true

# Directories
LOG_DIR="$HOOKS_DIR/logs"
STATE_DIR="/tmp/claude_hooks_state"
PERF_LOG="$LOG_DIR/performance.log"
SESSION_LOG="$LOG_DIR/session.log"

# Ensure directories exist
mkdir -p "$LOG_DIR" 2>/dev/null
mkdir -p "$STATE_DIR" 2>/dev/null

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

TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')

# Clean up stale state files (older than 60 minutes)
cleanup_stale_state 60 > /dev/null 2>&1 || true

# V9: Clean up stale session-specific spec markers (older than 24 hours)
# These are orphaned markers from crashed/force-quit sessions
# Pattern: .claude/.spec-active.{SESSION_ID}
if [ -d "$PROJECT_ROOT/.claude" ]; then
  find "$PROJECT_ROOT/.claude" -maxdepth 1 -name ".spec-active.*" -mtime +1 -delete 2>/dev/null || true
fi

# Initialize session state
SESSION_STATE=$(cat <<EOF
{"session_id":"$SESSION_ID","started_at":"$(date -u +%Y-%m-%dT%H:%M:%SZ)","cwd":"$CWD"}
EOF
)
write_hook_state "session" "$SESSION_STATE" 2>/dev/null || true

# Check for active spec folder
SPEC_ACTIVE_FILE="$PROJECT_ROOT/.claude/.spec-active"
SPEC_CONTEXT="none"
if [ -f "$SPEC_ACTIVE_FILE" ]; then
  SPEC_CONTEXT=$(cat "$SPEC_ACTIVE_FILE" 2>/dev/null | head -1)
  SPEC_CONTEXT="${SPEC_CONTEXT:-none}"
fi

# Log session start
{
  echo "═══════════════════════════════════════════════════════════════"
  echo "SESSION START: $TIMESTAMP"
  echo "═══════════════════════════════════════════════════════════════"
  echo "  session_id: $SESSION_ID"
  echo "  cwd: $CWD"
  echo "  spec_active: $SPEC_CONTEXT"
  echo "═══════════════════════════════════════════════════════════════"
} >> "$SESSION_LOG" 2>/dev/null

# Performance timing END
END_TIME=$(_get_nano_time)
DURATION_MS=$(( (END_TIME - START_TIME) / 1000000 ))
echo "[$TIMESTAMP] initialize-session.sh ${DURATION_MS}ms" >> "$PERF_LOG" 2>/dev/null

# Always allow (non-blocking, initialization)
exit ${EXIT_ALLOW:-0}
