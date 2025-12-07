#!/bin/bash

# ───────────────────────────────────────────────────────────────
# CHECK PENDING QUESTIONS - PreToolUse Hook
# ───────────────────────────────────────────────────────────────
# STRICT MODE: Blocks ALL tool execution if a mandatory question
# is pending. Only AskUserQuestion is allowed (that's how user responds).
#
# Version: 1.0.0
# Created: 2025-11-25
#
# BEHAVIOR:
#   - When pending_question state exists:
#     - AskUserQuestion → ALLOW (clears pending state)
#     - All other tools → BLOCK with exit 1
#   - When no pending_question state:
#     - All tools → ALLOW
#
# STATE FILE: /tmp/claude_hooks_state/pending_question.json
# EXPIRY: 5 minutes (300 seconds)
#
# PERFORMANCE TARGET: <50ms
# COMPATIBILITY: Bash 3.2+ (macOS and Linux)
#
# EXIT CODE CONVENTION:
#   0 = Allow (tool execution proceeds)
#   1 = Block (tool execution stopped with user warning)
# ───────────────────────────────────────────────────────────────

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" 2>/dev/null && pwd)"
HOOKS_DIR="$(cd "$SCRIPT_DIR/.." 2>/dev/null && pwd)"
LOG_DIR="$HOOKS_DIR/logs"
LOG_FILE="$LOG_DIR/check-pending-questions.log"

mkdir -p "$LOG_DIR" 2>/dev/null

# Source required libraries
source "$HOOKS_DIR/lib/shared-state.sh" 2>/dev/null || {
  # If shared-state.sh is missing, allow all tools (graceful degradation)
  exit 0
}

source "$HOOKS_DIR/lib/exit-codes.sh" 2>/dev/null || {
  # Fallback exit codes if library missing
  EXIT_ALLOW=0
  EXIT_BLOCK=1
}

source "$HOOKS_DIR/lib/output-helpers.sh" 2>/dev/null || {
  # Fallback output function if library missing
  print_error_box() {
    echo "❌ $1" >&2
    shift
    for line in "$@"; do
      echo "   $line" >&2
    done
  }
}

source "$HOOKS_DIR/lib/perf-timing.sh" 2>/dev/null || true

# Performance tracking (using centralized _get_nano_time from perf-timing.sh)
START_TIME=$(_get_nano_time)

# ───────────────────────────────────────────────────────────────
# READ INPUT
# ───────────────────────────────────────────────────────────────
INPUT=$(cat)

# Extract tool name from JSON input
TOOL_NAME=$(echo "$INPUT" | jq -r '.name // empty' 2>/dev/null)

# Early exit if no tool name (shouldn't happen, but be safe)
if [ -z "$TOOL_NAME" ]; then
  exit $EXIT_ALLOW
fi

# ───────────────────────────────────────────────────────────────
# ASKUSERQUESTION - ALWAYS ALLOWED
# ───────────────────────────────────────────────────────────────
# This is how the user responds to pending questions.
# When AskUserQuestion is used, clear the pending question state.
if [ "$TOOL_NAME" = "AskUserQuestion" ]; then
  # Log successful response
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] AskUserQuestion used - question answered" >> "$LOG_FILE" 2>/dev/null

  # Clear pending question AND violations (user responded correctly)
  clear_hook_state "pending_question" 2>/dev/null || true
  clear_hook_state "question_violations" 2>/dev/null || true

  exit $EXIT_ALLOW
fi

# ───────────────────────────────────────────────────────────────
# ATOMIC CHECK FOR PENDING QUESTION
# ───────────────────────────────────────────────────────────────
# Check if a mandatory question is pending (with 5-minute expiry)
# CRITICAL: This must be atomic to prevent TOCTOU race conditions
QUESTION_EXPIRY=300  # 5 minutes in seconds

# Atomically read pending question state (single operation)
PENDING=$(read_hook_state "pending_question" "$QUESTION_EXPIRY" 2>/dev/null)

# If no pending question OR state is empty, allow all tools
if [ -z "$PENDING" ]; then
  exit $EXIT_ALLOW
fi

# Validate JSON integrity (corrupted state should be cleared)
if ! echo "$PENDING" | jq empty 2>/dev/null; then
  # Invalid JSON, clear and allow
  clear_hook_state "pending_question" 2>/dev/null || true
  exit $EXIT_ALLOW
fi

# Extract timestamp and re-validate freshness (double-check pattern)
QUESTION_TIMESTAMP=$(echo "$PENDING" | jq -r '.timestamp // 0' 2>/dev/null)
CURRENT_TIME=$(date +%s 2>/dev/null || echo "0")
QUESTION_AGE=$((CURRENT_TIME - QUESTION_TIMESTAMP))

# If question is expired, clear and allow
if [ "$QUESTION_AGE" -gt "$QUESTION_EXPIRY" ] 2>/dev/null; then
  # Expired, clear and allow
  clear_hook_state "pending_question" 2>/dev/null || true
  exit $EXIT_ALLOW
fi

# ───────────────────────────────────────────────────────────────
# QUESTION IS VALID AND FRESH - PROCEED WITH BLOCKING
# ───────────────────────────────────────────────────────────────

# Extract question details for the error message
QUESTION_TYPE=$(echo "$PENDING" | jq -r '.type // "UNKNOWN"' 2>/dev/null)
QUESTION_TEXT=$(echo "$PENDING" | jq -r '.question // "Pending question"' 2>/dev/null)
ASKED_AT=$(echo "$PENDING" | jq -r '.asked_at // "unknown"' 2>/dev/null)

# ─────────────────────────────────────────────────────────────
# ATOMIC VIOLATION TRACKING
# ─────────────────────────────────────────────────────────────
# Track how many times the AI has attempted to use tools without responding
# Read current violations atomically
VIOLATION_COUNT=0
if has_hook_state "question_violations" 600 2>/dev/null; then
  VIOLATIONS_STATE=$(read_hook_state "question_violations" 600 2>/dev/null)
  VIOLATION_COUNT=$(echo "$VIOLATIONS_STATE" | jq -r '.count // 0' 2>/dev/null || echo "0")
fi

# Increment violation counter
VIOLATION_COUNT=$((VIOLATION_COUNT + 1))

# Write back with timestamp (use jq for JSON construction to avoid escaping issues)
VIOLATION_JSON=$(jq -n \
  --arg count "$VIOLATION_COUNT" \
  --arg tool "$TOOL_NAME" \
  '{count: ($count | tonumber), last_tool: $tool, timestamp: now}' 2>/dev/null)

write_hook_state "question_violations" "$VIOLATION_JSON" 2>/dev/null || true

# Log the block with violation count
echo "[$(date '+%Y-%m-%d %H:%M:%S')] BLOCKED: $TOOL_NAME (pending: $QUESTION_TYPE, violation #$VIOLATION_COUNT)" >> "$LOG_FILE" 2>/dev/null

# ─────────────────────────────────────────────────────────────
# IMPROVED BLOCKING MESSAGE
# ─────────────────────────────────────────────────────────────
# Emit systemMessage for Claude Code visibility
echo "{\"systemMessage\": \"🔴 BLOCKED: Answer pending question first using AskUserQuestion - Type: $QUESTION_TYPE\"}"
echo "" >&2
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" >&2
echo "🔴 MANDATORY USER QUESTION PENDING" >&2
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" >&2
echo "" >&2
echo "Type: $QUESTION_TYPE" >&2
echo "Question: $QUESTION_TEXT" >&2
echo "" >&2
echo "You MUST use the AskUserQuestion tool to respond." >&2
echo "All other tools are blocked until you answer." >&2
echo "" >&2
if [ "$VIOLATION_COUNT" -gt 0 ] 2>/dev/null; then
  echo "⚠️  Violation count: $VIOLATION_COUNT (tool bypass attempts)" >&2
  echo "" >&2
fi
echo "The pending question signal was already displayed above." >&2
echo "Please scroll up to see the question and options." >&2
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" >&2

# Record performance
END_TIME=$(_get_nano_time)
if [[ "$START_TIME" =~ ^[0-9]+$ ]] && [[ "$END_TIME" =~ ^[0-9]+$ ]]; then
  DURATION=$(((END_TIME - START_TIME) / 1000000))
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] check-pending-questions.sh ${DURATION}ms (blocked: $TOOL_NAME, violation #$VIOLATION_COUNT)" >> "$HOOKS_DIR/logs/performance.log" 2>/dev/null
fi

exit $EXIT_BLOCK  # HARD BLOCK tool execution
