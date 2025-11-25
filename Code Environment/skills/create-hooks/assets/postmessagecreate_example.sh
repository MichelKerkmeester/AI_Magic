#!/bin/bash

# ───────────────────────────────────────────────────────────────
# RESPONSE METRICS LOGGING HOOK
# ───────────────────────────────────────────────────────────────
# PostMessageCreate hook that logs metrics after AI response
# generation completes.
#
# PRIMARY PURPOSE: Response metrics collection (not blocking)
# - Logs response length (character count)
# - Tracks response patterns for quality analysis
# - Records timing information
#
# PERFORMANCE TARGET: <30ms (lightweight logging)
# COMPATIBILITY: Bash 3.2+ (macOS and Linux compatible)
#
# EXECUTION ORDER: PostMessageCreate hook (runs AFTER AI response)
#   1. UserPromptSubmit hooks run FIRST (before processing user input)
#   2. PreToolUse hooks run SECOND (before tool execution)
#   3. PreMessageCreate hooks run (before AI response generation)
#   4. PostToolUse hooks run (after tool completion)
#   5. PostMessageCreate hooks run LAST (after AI response)
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

# Logging configuration
LOG_DIR="$HOOKS_DIR/logs"
LOG_FILE="$LOG_DIR/postmessagecreate.log"
METRICS_FILE="$LOG_DIR/response-metrics.log"
PERF_LOG="$LOG_DIR/performance.log"

# Ensure log directory exists
mkdir -p "$LOG_DIR" 2>/dev/null

# Performance timing START
START_TIME=$(date +%s%N 2>/dev/null) || START_TIME=0

# Read JSON input from stdin
INPUT=$(cat)

# Extract metrics from payload (if available)
SESSION_ID=$(echo "$INPUT" | jq -r '.session_id // "unknown"' 2>/dev/null) || SESSION_ID="unknown"
RESPONSE=$(echo "$INPUT" | jq -r '.response // ""' 2>/dev/null) || RESPONSE=""

# Sanitize session ID
SESSION_ID=$(echo "$SESSION_ID" | tr -cd 'a-zA-Z0-9_-')
SESSION_ID="${SESSION_ID:-unknown}"

# Calculate metrics
RESPONSE_LENGTH=${#RESPONSE}
TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')

# Log to metrics file (structured format for analysis)
{
  echo "[$TIMESTAMP] session=$SESSION_ID length=$RESPONSE_LENGTH"
} >> "$METRICS_FILE" 2>/dev/null

# Log detailed entry
{
  echo "[$TIMESTAMP] PostMessageCreate"
  echo "  session_id: $SESSION_ID"
  echo "  response_length: $RESPONSE_LENGTH characters"
} >> "$LOG_FILE" 2>/dev/null

# Performance timing END
END_TIME=$(date +%s%N 2>/dev/null) || END_TIME=0
if [ "$START_TIME" -gt 0 ] && [ "$END_TIME" -gt 0 ]; then
  DURATION_MS=$(( (END_TIME - START_TIME) / 1000000 ))
  echo "[$TIMESTAMP] log-response-metrics.sh ${DURATION_MS}ms" >> "$PERF_LOG" 2>/dev/null
fi

# Always allow (non-blocking, logging only)
exit 0
