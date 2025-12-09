#!/bin/bash

# ───────────────────────────────────────────────────────────────
# SESSION CLEANUP HOOK
# ───────────────────────────────────────────────────────────────
# PostSessionEnd hook that cleans up after a Claude Code session
# ends.
#
# PRIMARY PURPOSE: Session cleanup and archival (not blocking)
# - Archives session logs if configured
# - Cleans up temporary state files
# - Saves session summary
# - Preserves context for future reference
#
# PERFORMANCE TARGET: <100ms (cleanup)
# COMPATIBILITY: Bash 3.2+ (macOS and Linux compatible)
#
# EXECUTION ORDER: PostSessionEnd hook (runs when session ends)
#   This is the LAST hook to run at the end of a session
#
# EXIT CODE CONVENTION:
#   0 = Allow (hook passed, continue execution)
#   1 = Block (hook failed, stop execution with warning)
#   2 = Error (reserved for critical failures)
#
# NOTE: This hook always returns 0 (non-blocking, cleanup)
# ───────────────────────────────────────────────────────────────

# Source output helpers (completely silent on success)
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
STATE_DIR="/tmp/claude_hooks_state"
PERF_LOG="$LOG_DIR/performance.log"
SESSION_LOG="$LOG_DIR/session.log"
ARCHIVE_DIR="$LOG_DIR/archive"

# Ensure directories exist
mkdir -p "$LOG_DIR" 2>/dev/null
mkdir -p "$ARCHIVE_DIR" 2>/dev/null

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

# Sanitize session ID
SESSION_ID=$(echo "$SESSION_ID" | tr -cd 'a-zA-Z0-9_-')
SESSION_ID="${SESSION_ID:-unknown}"

TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')

# Read session state (if exists)
SESSION_DATA=$(read_hook_state "session" 0 2>/dev/null) || SESSION_DATA=""
SESSION_START="unknown"
if [ -n "$SESSION_DATA" ]; then
  SESSION_START=$(echo "$SESSION_DATA" | jq -r '.started_at // "unknown"' 2>/dev/null) || SESSION_START="unknown"
fi

# Clean up session-specific state files
clear_hook_state "session" 2>/dev/null || true
clear_hook_state "complexity" 2>/dev/null || true
clear_hook_state "parallel_dispatch_completed" 2>/dev/null || true
clear_hook_state "parallel_dispatch_asked_ever" 2>/dev/null || true

# Clean up agent tracking if function exists
if type cleanup_agent_state >/dev/null 2>&1; then
  cleanup_agent_state 0 2>/dev/null || true
fi

# Clean up old temporary files (older than 60 minutes)
if [ -d "$STATE_DIR" ]; then
  find "$STATE_DIR" -type f -mmin +60 -delete 2>/dev/null || true
fi

# Clean up session-specific state directory
SESSION_STATE_DIR="$STATE_DIR/${SESSION_ID:-}"
if [[ -n "$SESSION_ID" ]] && [[ "$SESSION_ID" != "unknown" ]] && [[ -d "$SESSION_STATE_DIR" ]]; then
  rm -rf "$SESSION_STATE_DIR" 2>/dev/null || true
fi

# Trigger log rotation if any log exceeds 500KB
for log in "$LOG_DIR"/*.log; do
  if [[ -f "$log" ]] && [[ $(wc -c < "$log" 2>/dev/null | tr -d ' ') -gt 512000 ]]; then
    bash "$HOOKS_DIR/scripts/rotate-logs.sh" --quiet 2>/dev/null || true
    break
  fi
done

# ─── T186: Save session state before cleanup ───
# Auto-save session state to spec memory folder for cross-session continuity
if type save_state_artifact &>/dev/null; then
  STATE_SAVED=""
  STATE_SAVED=$(save_state_artifact 2>/dev/null) || true
  if [ -n "$STATE_SAVED" ]; then
    echo "  state_saved: $STATE_SAVED" >> "$SESSION_LOG" 2>/dev/null
  fi
fi

# V9: Clean up session-specific spec marker
# Each session has its own marker file (.claude/.spec-active.{SESSION_ID})
# Remove it when session ends to prevent orphaned markers
if [ -n "$SESSION_ID" ] && [ "$SESSION_ID" != "unknown" ]; then
  SESSION_MARKER="$PROJECT_ROOT/.claude/.spec-active.$SESSION_ID"
  if [ -f "$SESSION_MARKER" ]; then
    rm -f "$SESSION_MARKER" 2>/dev/null || true
  fi
fi

# Log session end
{
  echo "═══════════════════════════════════════════════════════════════"
  echo "SESSION END: $TIMESTAMP"
  echo "═══════════════════════════════════════════════════════════════"
  echo "  session_id: $SESSION_ID"
  echo "  started_at: $SESSION_START"
  echo "  ended_at: $(date -u +%Y-%m-%dT%H:%M:%SZ)"
  echo "═══════════════════════════════════════════════════════════════"
  echo ""
} >> "$SESSION_LOG" 2>/dev/null

# Performance timing END
END_TIME=$(_get_nano_time)
DURATION_MS=$(( (END_TIME - START_TIME) / 1000000 ))
echo "[$TIMESTAMP] cleanup-session.sh ${DURATION_MS}ms" >> "$PERF_LOG" 2>/dev/null

# Always allow (non-blocking, cleanup)
exit ${EXIT_ALLOW:-0}
