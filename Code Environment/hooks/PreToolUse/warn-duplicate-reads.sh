#!/bin/bash

# ───────────────────────────────────────────────────────────────
# INTELLIGENT DUPLICATE READ DETECTOR (Machine-Readable Intelligence)
# ───────────────────────────────────────────────────────────────
# PreToolUse hook that provides actionable duplicate detection intelligence
# for read-only tool calls (Read, Grep, Glob).
#
# Version: 2.0.0 (Enhanced Intelligence)
# Created: 2025-11-27
# Enhanced: 2025-11-29
# Spec: specs/001-skills-and-hooks/046-context-pruning-hook/
#
# PERFORMANCE TARGET: <50ms (reduced from <100ms)
# COMPATIBILITY: Bash 3.2+ (macOS and Linux compatible)
#
# EXECUTION ORDER: PreToolUse hook (runs BEFORE tool execution)
#   Fires when: Any tool is about to execute
#   Non-blocking: Always exits 0 (advisory only)
#   Purpose: Provide actionable intelligence about duplicate tool calls
#
# ENHANCEMENTS v2.0:
#   - Smart deduplication (distinguishes legitimate re-reads)
#   - Machine-readable JSON signals (not just human warnings)
#   - Token waste quantification (estimated savings)
#   - Context-aware detection (verification reads, time-based TTL)
#   - Reduced false positives (understands legitimate patterns)
#
# EXIT CODE CONVENTION:
#   0 = Always (advisory intelligence never blocks execution)
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
TOOL_NAME=$(echo "$INPUT" | jq -r '.name // empty' 2>/dev/null)

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

# Extract key parameters for context-aware analysis
FILE_PATH=""
PATTERN=""
case "$TOOL_NAME" in
  "Read")
    FILE_PATH=$(echo "$TOOL_INPUT" | jq -r '.file_path // ""' 2>/dev/null)
    ;;
  "Grep")
    PATTERN=$(echo "$TOOL_INPUT" | jq -r '.pattern // ""' 2>/dev/null)
    FILE_PATH=$(echo "$TOOL_INPUT" | jq -r '.path // ""' 2>/dev/null)
    ;;
  "Glob")
    PATTERN=$(echo "$TOOL_INPUT" | jq -r '.pattern // ""' 2>/dev/null)
    FILE_PATH=$(echo "$TOOL_INPUT" | jq -r '.path // ""' 2>/dev/null)
    ;;
esac

# ───────────────────────────────────────────────────────────────
# CHECK FOR DUPLICATES (WITH CONTEXT-AWARE INTELLIGENCE)
# ───────────────────────────────────────────────────────────────

# Read tool call history from shared state (5min window)
HISTORY=$(read_hook_state "tool_call_history" 300 2>/dev/null)

# Initialize empty history if not found
if [ -z "$HISTORY" ] || [ "$HISTORY" = "null" ]; then
  HISTORY='{"signatures":{},"message_count":0,"session_token_waste":0}'
fi

# Read modified files state (to detect verification reads)
MODIFIED_FILES=$(read_hook_state "modified_files" 300 2>/dev/null)
if [ -z "$MODIFIED_FILES" ] || [ "$MODIFIED_FILES" = "null" ]; then
  MODIFIED_FILES='{"files":[]}'
fi

# Check if signature exists
if echo "$HISTORY" | jq -e ".signatures.\"$SIGNATURE\"" >/dev/null 2>&1; then
  # Potential duplicate detected!
  PREV_MSG=$(echo "$HISTORY" | jq -r ".signatures.\"$SIGNATURE\".message_number" 2>/dev/null)
  PREV_TIME=$(echo "$HISTORY" | jq -r ".signatures.\"$SIGNATURE\".timestamp" 2>/dev/null)

  # Calculate time elapsed since previous call
  TIME_ELAPSED=$(calculate_time_elapsed_seconds "$PREV_TIME")
  TIME_AGO=$(seconds_to_human_readable "$TIME_ELAPSED")

  # ─────────────────────────────────────────────────────────────
  # SMART DETECTION: Determine if this is a LEGITIMATE re-read
  # ─────────────────────────────────────────────────────────────

  IS_LEGITIMATE=false
  LEGITIMATE_REASON=""

  # Case 1: Verification read after file modification
  if [ -n "$FILE_PATH" ] && [ "$TOOL_NAME" = "Read" ]; then
    # Check if file was recently modified
    LAST_MODIFIED=$(echo "$MODIFIED_FILES" | jq -r --arg path "$FILE_PATH" \
      '.files[] | select(.path == $path) | .timestamp' 2>/dev/null | tail -n 1)

    if [ -n "$LAST_MODIFIED" ]; then
      MODIFIED_AGE=$(calculate_time_elapsed_seconds "$LAST_MODIFIED")
      # If file was modified after the last read, this is a verification read
      if [ "$MODIFIED_AGE" -lt "$TIME_ELAPSED" ]; then
        IS_LEGITIMATE=true
        LEGITIMATE_REASON="verification_after_modification"
      fi
    fi
  fi

  # Case 2: Different Grep patterns on same file (not a true duplicate)
  if [ "$TOOL_NAME" = "Grep" ] && [ -n "$PATTERN" ]; then
    # This is already unique by signature, so won't trigger
    # But we track it for clarity
    IS_LEGITIMATE=true
    LEGITIMATE_REASON="different_grep_pattern"
  fi

  # Case 3: Time-based TTL (reads >2min apart are considered fresh context)
  if [ "$TIME_ELAPSED" -gt 120 ]; then
    IS_LEGITIMATE=true
    LEGITIMATE_REASON="stale_context_refresh"
  fi

  # ─────────────────────────────────────────────────────────────
  # ESTIMATE TOKEN WASTE (if true duplicate)
  # ─────────────────────────────────────────────────────────────

  ESTIMATED_TOKENS=0
  TOKEN_WASTE_THIS_CALL=0

  if [ "$IS_LEGITIMATE" = false ]; then
    # Estimate token count based on tool type
    case "$TOOL_NAME" in
      "Read")
        # Average file read: ~500-2000 tokens (conservative: 1000)
        ESTIMATED_TOKENS=1000
        ;;
      "Grep")
        # Average grep output: ~200-800 tokens (conservative: 400)
        ESTIMATED_TOKENS=400
        ;;
      "Glob")
        # Average glob output: ~100-300 tokens (conservative: 150)
        ESTIMATED_TOKENS=150
        ;;
    esac

    TOKEN_WASTE_THIS_CALL=$ESTIMATED_TOKENS
  fi

  # ─────────────────────────────────────────────────────────────
  # MACHINE-READABLE INTELLIGENCE OUTPUT (JSON Signal)
  # ─────────────────────────────────────────────────────────────

  if [ "$IS_LEGITIMATE" = false ]; then
    # Retrieve session token waste total
    SESSION_WASTE=$(echo "$HISTORY" | jq -r '.session_token_waste // 0' 2>/dev/null)
    NEW_SESSION_WASTE=$((SESSION_WASTE + TOKEN_WASTE_THIS_CALL))

    # Emit machine-readable JSON intelligence
    cat <<EOF

╔══════════════════════════════════════════════════════════════╗
║  DUPLICATE DETECTION INTELLIGENCE (Machine-Readable Signal)  ║
╚══════════════════════════════════════════════════════════════╝

{
  "duplicate_detected": true,
  "tool_name": "$TOOL_NAME",
  "file_path": "$FILE_PATH",
  "pattern": "$PATTERN",
  "previous_call": {
    "message_number": $PREV_MSG,
    "time_ago_seconds": $TIME_ELAPSED,
    "time_ago_human": "$TIME_AGO"
  },
  "analysis": {
    "is_legitimate": false,
    "false_positive": false,
    "reason_ignored": null
  },
  "token_impact": {
    "estimated_waste_this_call": $TOKEN_WASTE_THIS_CALL,
    "session_total_waste": $NEW_SESSION_WASTE,
    "potential_savings": "Consider reusing previous output"
  },
  "actionable_suggestion": "REUSE_PREVIOUS_OUTPUT",
  "signature": "$(echo "$SIGNATURE" | head -c 60)..."
}

╔══════════════════════════════════════════════════════════════╗
║  RECOMMENDATION: Reference previous output from message #$PREV_MSG  ║
║  ESTIMATED TOKENS WASTED: $TOKEN_WASTE_THIS_CALL                              ║
║  SESSION TOTAL WASTE: $NEW_SESSION_WASTE tokens                    ║
╚══════════════════════════════════════════════════════════════╝

EOF

    # Update session waste counter in history
    HISTORY=$(echo "$HISTORY" | jq --arg waste "$NEW_SESSION_WASTE" \
      '.session_token_waste = ($waste | tonumber)' 2>/dev/null)

  else
    # Legitimate re-read: Emit informational signal (low priority)
    cat <<EOF

{
  "duplicate_detected": true,
  "tool_name": "$TOOL_NAME",
  "file_path": "$FILE_PATH",
  "analysis": {
    "is_legitimate": true,
    "false_positive": false,
    "reason_ignored": "$LEGITIMATE_REASON"
  },
  "token_impact": {
    "estimated_waste_this_call": 0,
    "reason": "Legitimate re-read pattern detected"
  },
  "actionable_suggestion": "PROCEED_AS_PLANNED"
}

EOF
  fi
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

# Calculate time elapsed in seconds since timestamp
calculate_time_elapsed_seconds() {
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

  echo $((now_epoch - prev_epoch))
}

# Convert seconds to human-readable format
seconds_to_human_readable() {
  local diff=$1

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
