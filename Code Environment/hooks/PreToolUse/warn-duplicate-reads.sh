#!/bin/bash

# ───────────────────────────────────────────────────────────────
# WARN DUPLICATE READS (Advisory Hook)
# ───────────────────────────────────────────────────────────────
# PreToolUse hook that provides real-time duplicate detection warnings
# for read-only tool calls (Read, Grep, Glob).
#
# Version: 1.0.0
# Created: 2025-11-27
# Spec: specs/001-skills-and-hooks/046-context-pruning-hook/
#
# PERFORMANCE TARGET: <100ms
# COMPATIBILITY: Bash 3.2+ (macOS and Linux compatible)
#
# EXECUTION ORDER: PreToolUse hook (runs BEFORE tool execution)
#   Fires when: Any tool is about to execute
#   Non-blocking: Always exits 0 (advisory only)
#   Purpose: Alert Claude to duplicate tool calls for awareness
#
# EXIT CODE CONVENTION:
#   0 = Always (advisory warnings never block execution)
# ───────────────────────────────────────────────────────────────

# Source libraries
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" 2>/dev/null && pwd)"
HOOKS_DIR="$(cd "$SCRIPT_DIR/.." 2>/dev/null && pwd)"

source "$HOOKS_DIR/lib/output-helpers.sh" 2>/dev/null || exit 0
source "$HOOKS_DIR/lib/exit-codes.sh" 2>/dev/null || exit 0
source "$HOOKS_DIR/lib/shared-state.sh" 2>/dev/null || exit 0

# Performance timing
START_TIME=$(date +%s%N)

# ───────────────────────────────────────────────────────────────
# DEPENDENCY CHECKS
# ───────────────────────────────────────────────────────────────

# Check for jq (silent fail if not available)
if ! command -v jq >/dev/null 2>&1; then
  exit 0  # Skip silently
fi

# ───────────────────────────────────────────────────────────────
# PARSE JSON INPUT
# ───────────────────────────────────────────────────────────────

INPUT=$(cat)
TOOL_NAME=$(echo "$INPUT" | jq -r '.tool_name // empty' 2>/dev/null)

# Only track read-only tools (safe to deduplicate)
case "$TOOL_NAME" in
  "Read"|"Grep"|"Glob")
    # Continue with duplicate detection
    ;;
  *)
    # Other tools: no tracking, exit silently
    exit 0
    ;;
esac

# ───────────────────────────────────────────────────────────────
# GENERATE SIGNATURE
# ───────────────────────────────────────────────────────────────

# Extract tool input as compact JSON
TOOL_INPUT=$(echo "$INPUT" | jq -c '.tool_input' 2>/dev/null)

# Generate signature (tool_name:input)
SIGNATURE="${TOOL_NAME}:${TOOL_INPUT}"

# ───────────────────────────────────────────────────────────────
# CHECK FOR DUPLICATES
# ───────────────────────────────────────────────────────────────

# Read tool call history from shared state (5min window)
HISTORY=$(read_hook_state "tool_call_history" 300 2>/dev/null)

# Initialize empty history if not found
if [ -z "$HISTORY" ] || [ "$HISTORY" = "null" ]; then
  HISTORY='{"signatures":{},"message_count":0}'
fi

# Check if signature exists
if echo "$HISTORY" | jq -e ".signatures.\"$SIGNATURE\"" >/dev/null 2>&1; then
  # Duplicate detected!
  PREV_MSG=$(echo "$HISTORY" | jq -r ".signatures.\"$SIGNATURE\".message_number" 2>/dev/null)
  PREV_TIME=$(echo "$HISTORY" | jq -r ".signatures.\"$SIGNATURE\".timestamp" 2>/dev/null)

  # Calculate time ago
  TIME_AGO=$(calculate_time_ago "$PREV_TIME")

  # Display advisory warning (non-blocking)
  echo ""
  echo "   📋 Advisory: This ${TOOL_NAME} call appears to duplicate a previous call"
  echo "   ├─ Previous: Message #${PREV_MSG} (${TIME_AGO} ago)"
  echo "   └─ Suggestion: Consider reusing previous output to save tokens"
  echo ""
fi

# ───────────────────────────────────────────────────────────────
# UPDATE HISTORY
# ───────────────────────────────────────────────────────────────

# Increment message counter
MESSAGE_NUM=$(echo "$HISTORY" | jq -r '.message_count // 0' 2>/dev/null | awk '{print $1+1}')

# Update history with current call
UPDATED_HISTORY=$(echo "$HISTORY" | jq \
  --arg sig "$SIGNATURE" \
  --arg msg "$MESSAGE_NUM" \
  --arg ts "$(date -u +%Y-%m-%dT%H:%M:%SZ 2>/dev/null || date +%Y-%m-%dT%H:%M:%SZ)" \
  '.signatures[$sig] = {message_number: ($msg | tonumber), timestamp: $ts} | .message_count = ($msg | tonumber)' 2>/dev/null)

# Write updated history to shared state
if [ -n "$UPDATED_HISTORY" ]; then
  write_hook_state "tool_call_history" "$UPDATED_HISTORY" 2>/dev/null
fi

# ───────────────────────────────────────────────────────────────
# PERFORMANCE LOGGING
# ───────────────────────────────────────────────────────────────

LOG_DIR="$HOOKS_DIR/logs"
mkdir -p "$LOG_DIR" 2>/dev/null

END_TIME=$(date +%s%N)
DURATION=$(( (END_TIME - START_TIME) / 1000000 ))

echo "[$(date '+%Y-%m-%d %H:%M:%S')] warn-duplicate-reads.sh ${DURATION}ms" >> "$LOG_DIR/performance.log" 2>/dev/null

# Always allow execution (non-blocking advisory)
exit 0

# ───────────────────────────────────────────────────────────────
# HELPER FUNCTIONS
# ───────────────────────────────────────────────────────────────

# Calculate human-readable time difference
calculate_time_ago() {
  local prev_time="$1"

  # Get current time in seconds since epoch
  local now_epoch
  if [[ "$OSTYPE" == "darwin"* ]]; then
    now_epoch=$(date +%s)
  else
    now_epoch=$(date +%s)
  fi

  # Parse previous time (ISO 8601 format)
  local prev_epoch
  if [[ "$OSTYPE" == "darwin"* ]]; then
    # macOS: use -j for parsing
    prev_epoch=$(date -j -f "%Y-%m-%dT%H:%M:%SZ" "$prev_time" +%s 2>/dev/null || echo "$now_epoch")
  else
    # Linux: use -d for parsing
    prev_epoch=$(date -d "$prev_time" +%s 2>/dev/null || echo "$now_epoch")
  fi

  local diff=$((now_epoch - prev_epoch))

  # Format as human-readable
  if [ $diff -lt 60 ]; then
    echo "${diff}s"
  elif [ $diff -lt 3600 ]; then
    echo "$((diff / 60))m"
  elif [ $diff -lt 86400 ]; then
    echo "$((diff / 3600))h"
  else
    echo "$((diff / 86400))d"
  fi
}
