#!/bin/bash

# ───────────────────────────────────────────────────────────────
# RESPONSE CONTEXT VALIDATION HOOK
# ───────────────────────────────────────────────────────────────
# PreMessageCreate hook that validates context before AI response
# generation begins. Logs context state for monitoring.
#
# PRIMARY PURPOSE: Context state monitoring (not blocking)
# - Checks if spec folder context is loaded
# - Validates conversation state marker
# - Logs response generation events for auditing
#
# PERFORMANCE TARGET: <50ms (lightweight logging)
# COMPATIBILITY: Bash 3.2+ (macOS and Linux compatible)
#
# EXECUTION ORDER: PreMessageCreate hook (runs BEFORE AI response)
#   1. UserPromptSubmit hooks run FIRST (before processing user input)
#   2. PreToolUse hooks run SECOND (before tool execution)
#   3. PreMessageCreate hooks run THIRD (before AI response generation)
#   4. PostToolUse hooks run (after tool completion)
#   5. PostMessageCreate hooks run (after AI response)
#
# EXIT CODE CONVENTION:
#   0 = Allow (hook passed, continue execution)
#   1 = Block (hook failed, stop execution with warning)
#   2 = Error (reserved for critical failures)
#
# NOTE: This hook always returns 0 (non-blocking, logging only)
# ───────────────────────────────────────────────────────────────

# Source output helpers (completely silent on success)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" 2>/dev/null && pwd)"
HOOKS_DIR="$(cd "$SCRIPT_DIR/.." 2>/dev/null && pwd)"
PROJECT_ROOT=$(git rev-parse --show-toplevel 2>/dev/null || (cd "$SCRIPT_DIR/../.." && pwd))

# Source libraries silently
source "$HOOKS_DIR/lib/output-helpers.sh" 2>/dev/null || true
source "$HOOKS_DIR/lib/shared-state.sh" 2>/dev/null || true

# Logging configuration
LOG_DIR="$HOOKS_DIR/logs"
LOG_FILE="$LOG_DIR/premessagecreate.log"
PERF_LOG="$LOG_DIR/performance.log"

# Ensure log directory exists
mkdir -p "$LOG_DIR" 2>/dev/null

# Performance timing START
START_TIME=$(date +%s%N 2>/dev/null) || START_TIME=0

# Read JSON input from stdin
INPUT=$(cat)

# Extract session info from payload (if available)
SESSION_ID=$(echo "$INPUT" | jq -r '.session_id // "unknown"' 2>/dev/null) || SESSION_ID="unknown"
MESSAGE_COUNT=$(echo "$INPUT" | jq -r '.message_count // 0' 2>/dev/null) || MESSAGE_COUNT=0

# Sanitize session ID (alphanumeric, underscore, hyphen only)
SESSION_ID=$(echo "$SESSION_ID" | tr -cd 'a-zA-Z0-9_-')
SESSION_ID="${SESSION_ID:-unknown}"

# Check if spec folder context is active
SPEC_ACTIVE_FILE="$PROJECT_ROOT/.claude/.spec-active"
SPEC_CONTEXT=""
if [ -f "$SPEC_ACTIVE_FILE" ]; then
  SPEC_CONTEXT=$(cat "$SPEC_ACTIVE_FILE" 2>/dev/null | head -1)
fi

# Check for complexity data from orchestrator
COMPLEXITY_DATA=$(read_hook_state "complexity" 120 2>/dev/null) || COMPLEXITY_DATA=""
COMPLEXITY_SCORE="N/A"
if [ -n "$COMPLEXITY_DATA" ]; then
  COMPLEXITY_SCORE=$(echo "$COMPLEXITY_DATA" | jq -r '.complexity_score // "N/A"' 2>/dev/null) || COMPLEXITY_SCORE="N/A"
fi

# Log the response context state
TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')
{
  echo "[$TIMESTAMP] PreMessageCreate"
  echo "  session_id: $SESSION_ID"
  echo "  message_count: $MESSAGE_COUNT"
  echo "  spec_context: ${SPEC_CONTEXT:-none}"
  echo "  complexity: $COMPLEXITY_SCORE"
} >> "$LOG_FILE" 2>/dev/null

# Performance timing END
END_TIME=$(date +%s%N 2>/dev/null) || END_TIME=0
if [ "$START_TIME" -gt 0 ] && [ "$END_TIME" -gt 0 ]; then
  DURATION_MS=$(( (END_TIME - START_TIME) / 1000000 ))
  echo "[$TIMESTAMP] validate-response-context.sh ${DURATION_MS}ms" >> "$PERF_LOG" 2>/dev/null
fi

# Always allow (non-blocking, logging only)
exit 0
