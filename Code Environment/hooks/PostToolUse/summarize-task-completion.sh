#!/bin/bash

# ───────────────────────────────────────────────────────────────
# TASK COMPLETION SUMMARY HOOK
# ───────────────────────────────────────────────────────────────
# PostToolUse hook that displays agent completion summary after
# Task tool finishes. Provides visibility into sub-agent results.
#
# DISPLAY LOGIC (Expandable Default):
#   - 1-2 agents: Compact single-line format
#   - 3+ agents: Full verbose box with batch summary
#   - Errors: Always verbose box
#
# PERFORMANCE TARGET: <50ms
# COMPATIBILITY: Bash 3.2+ (macOS and Linux compatible)
#
# EXIT CODE: Always 0 (informational only)
# ───────────────────────────────────────────────────────────────

# Script setup
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" 2>/dev/null && pwd)"
HOOKS_DIR="$(cd "$SCRIPT_DIR/.." 2>/dev/null && pwd)"

# Source libraries (silent failures)
source "$HOOKS_DIR/lib/output-helpers.sh" 2>/dev/null || true
source "$HOOKS_DIR/lib/agent-tracking.sh" 2>/dev/null || true

# Logging
LOG_FILE="$HOOKS_DIR/logs/task-dispatch.log"

# Cross-platform nanosecond timing helper
_get_nano_time() {
  if [[ "$OSTYPE" == "darwin"* ]]; then
    echo $(($(date +%s) * 1000000000))
  else
    date +%s%N 2>/dev/null || echo $(($(date +%s) * 1000000000))
  fi
}

# Performance timing
START_TIME=$(_get_nano_time)

# Read JSON input from stdin
INPUT=$(cat)

# Extract tool name
TOOL_NAME=$(echo "$INPUT" | jq -r '.tool_name // empty' 2>/dev/null)

# Only process Task tool calls
if [ "$TOOL_NAME" != "Task" ]; then
  exit 0
fi

# Extract Task tool parameters and output
DESCRIPTION=$(echo "$INPUT" | jq -r '.tool_input.description // "Sub-agent"' 2>/dev/null)
SUBAGENT_TYPE=$(echo "$INPUT" | jq -r '.tool_input.subagent_type // "general-purpose"' 2>/dev/null)
MODEL=$(echo "$INPUT" | jq -r '.tool_input.model // "inherit"' 2>/dev/null)
TOOL_OUTPUT=$(echo "$INPUT" | jq -r '.tool_output // ""' 2>/dev/null)

# Determine status from output
detect_status() {
  local output="$1"
  if echo "$output" | grep -qiE "error|failed|exception|crashed"; then
    echo "error"
  elif echo "$output" | grep -qiE "timeout|timed out"; then
    echo "timeout"
  else
    echo "success"
  fi
}

STATUS=$(detect_status "$TOOL_OUTPUT")

# Find agent from tracking state using description mapping
AGENT_ID=""
MAPPING_FILE="/tmp/claude_hooks_state/agent_description_map.txt"
if [ -f "$MAPPING_FILE" ]; then
  # Use fixed string matching (grep -F) to avoid regex issues with description
  AGENT_ID=$(grep -F "${DESCRIPTION}|" "$MAPPING_FILE" 2>/dev/null | tail -1 | cut -d'|' -f2 | tr -d '[:space:]')
fi

# Fallback: try to find agent by description using library function
if [ -z "$AGENT_ID" ]; then
  AGENT_ID=$(find_agent_by_description "$DESCRIPTION" 2>/dev/null)
fi

# Log agent resolution for debugging
{
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] RESOLVE desc='$DESCRIPTION' agent_id='$AGENT_ID'"
} >> "$LOG_FILE" 2>/dev/null

# Calculate duration with robust fallbacks
DURATION_SEC="?"
DURATION_MS=0

if [ -n "$AGENT_ID" ]; then
  # Try to get agent info from tracking
  AGENT_INFO=$(get_agent_info "$AGENT_ID" 2>/dev/null)

  # Log agent info for debugging
  {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] AGENT_INFO agent_id='$AGENT_ID' info='$AGENT_INFO'"
  } >> "$LOG_FILE" 2>/dev/null

  if [ -n "$AGENT_INFO" ] && [ "$AGENT_INFO" != "null" ] && [ "$AGENT_INFO" != "{}" ]; then
    START_MS=$(echo "$AGENT_INFO" | jq -r '.start_ms // empty' 2>/dev/null)

    # Validate START_MS is a number
    if [ -n "$START_MS" ] && [ "$START_MS" != "null" ] && [[ "$START_MS" =~ ^[0-9]+$ ]]; then
      # Get current time in ms (cross-platform - macOS doesn't support %3N)
      if [[ "$OSTYPE" == "darwin"* ]]; then
        # macOS: use seconds * 1000
        END_MS=$(($(date +%s) * 1000))
      elif [[ $(date +%s%3N 2>/dev/null) =~ ^[0-9]+$ ]]; then
        END_MS=$(date +%s%3N)
      else
        END_MS=$(($(date +%s) * 1000))
      fi

      # Validate END_MS and calculate
      if [[ "$END_MS" =~ ^[0-9]+$ ]] && [ "$END_MS" -gt "$START_MS" ]; then
        DURATION_MS=$((END_MS - START_MS))

        # Sanity check: duration should be positive and reasonable (<10 min = 600000ms)
        if [ "$DURATION_MS" -gt 0 ] && [ "$DURATION_MS" -lt 600000 ]; then
          DURATION_SEC=$(awk "BEGIN {printf \"%.1f\", $DURATION_MS / 1000}" 2>/dev/null)
          # Fallback if awk fails
          if [ -z "$DURATION_SEC" ] || [ "$DURATION_SEC" = "0.0" ] && [ "$DURATION_MS" -gt 500 ]; then
            DURATION_SEC="$((DURATION_MS / 1000)).$((DURATION_MS % 1000 / 100))"
          fi
        else
          {
            echo "[$(date '+%Y-%m-%d %H:%M:%S')] DURATION_FAIL reason=out_of_range duration_ms=$DURATION_MS"
          } >> "$LOG_FILE" 2>/dev/null
        fi
      else
        {
          echo "[$(date '+%Y-%m-%d %H:%M:%S')] DURATION_FAIL reason=invalid_times start=$START_MS end=$END_MS"
        } >> "$LOG_FILE" 2>/dev/null
      fi
    else
      {
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] DURATION_FAIL reason=no_start_ms start='$START_MS'"
      } >> "$LOG_FILE" 2>/dev/null
    fi
  else
    {
      echo "[$(date '+%Y-%m-%d %H:%M:%S')] DURATION_FAIL reason=no_agent_info"
    } >> "$LOG_FILE" 2>/dev/null
  fi
else
  {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] DURATION_FAIL reason=no_agent_id"
  } >> "$LOG_FILE" 2>/dev/null
fi

# Extract result preview (first 100 chars of meaningful content)
extract_preview() {
  local output="$1"
  # Skip common prefixes and get first meaningful line
  local preview
  preview=$(echo "$output" | grep -v "^$" | head -3 | tr '\n' ' ' | head -c 100)
  if [ ${#output} -gt 100 ]; then
    echo "${preview}..."
  else
    echo "$preview"
  fi
}

RESULT_PREVIEW=$(extract_preview "$TOOL_OUTPUT")

# Record completion in tracking
if [ -n "$AGENT_ID" ]; then
  complete_agent_tracking "$AGENT_ID" "$STATUS" "${DURATION_MS:-0}" "$RESULT_PREVIEW" 2>/dev/null || true
fi

# Get current session agent count
AGENT_COUNT=$(get_agent_count 2>/dev/null)
# Ensure AGENT_COUNT is a valid number (default to 1)
if ! [[ "$AGENT_COUNT" =~ ^[0-9]+$ ]]; then
  AGENT_COUNT=1
fi

# Truncate description if too long
truncate_text() {
  local text="$1"
  local max="$2"
  if [ ${#text} -gt $max ]; then
    echo "${text:0:$((max-3))}..."
  else
    echo "$text"
  fi
}

DESC_SHORT=$(truncate_text "$DESCRIPTION" 45)

# Status emoji
get_status_emoji() {
  case "$1" in
    "success") echo "✅" ;;
    "error") echo "❌" ;;
    "timeout") echo "⏱️" ;;
    *) echo "✅" ;;
  esac
}

STATUS_EMOJI=$(get_status_emoji "$STATUS")

# ───────────────────────────────────────────────────────────────
# DISPLAY OUTPUT
# ───────────────────────────────────────────────────────────────

# Check if part of a batch
BATCH_ID=""
if [ -n "$AGENT_ID" ]; then
  BATCH_ID=$(get_agent_batch "$AGENT_ID" 2>/dev/null)
fi

# Error always gets verbose treatment
if [ "$STATUS" = "error" ] || [ "$STATUS" = "timeout" ]; then
  # ─────────────────────────────────────────────────────────────
  # ERROR FORMAT (always verbose)
  # ─────────────────────────────────────────────────────────────
  {
    echo ""
    echo "┌─────────────────────────────────────────────────────────────┐"
    if [ "$STATUS" = "error" ]; then
      echo "│ ❌ SUB-AGENT ERROR                                          │"
    else
      echo "│ ⏱️ SUB-AGENT TIMEOUT                                        │"
    fi
    echo "├─────────────────────────────────────────────────────────────┤"
    printf "│ Agent: %-52s │\n" "$DESC_SHORT"
    printf "│ Duration: %-49s │\n" "${DURATION_SEC}s"
    echo "│                                                             │"
    if [ -n "$RESULT_PREVIEW" ]; then
      echo "│ Output:                                                     │"
      printf "│ > %-57s │\n" "$RESULT_PREVIEW"
    fi
    echo "└─────────────────────────────────────────────────────────────┘"
    echo ""
  } >&2

elif [ "$AGENT_COUNT" -lt 3 ]; then
  # ─────────────────────────────────────────────────────────────
  # COMPACT FORMAT (1-2 agents, success)
  # ─────────────────────────────────────────────────────────────
  {
    echo ""
    echo "${STATUS_EMOJI} ${SUBAGENT_TYPE} completed (${DURATION_SEC}s) → ${DESC_SHORT}"
    echo ""
  } >&2

else
  # ─────────────────────────────────────────────────────────────
  # BATCH FORMAT (3+ agents)
  # ─────────────────────────────────────────────────────────────

  # Check if this is the last agent in batch
  IS_BATCH_COMPLETE=false
  if [ -n "$BATCH_ID" ] && [ "$BATCH_ID" != "null" ]; then
    if is_batch_complete "$BATCH_ID" 2>/dev/null; then
      IS_BATCH_COMPLETE=true
    fi
  fi

  if [ "$IS_BATCH_COMPLETE" = true ]; then
    # All agents done - show batch summary
    BATCH_SUMMARY=$(get_batch_summary "$BATCH_ID" 2>/dev/null)

    COMPLETED_COUNT=$(echo "$BATCH_SUMMARY" | jq -r '.batch.completed_count // 0' 2>/dev/null)
    EXPECTED_COUNT=$(echo "$BATCH_SUMMARY" | jq -r '.batch.expected_count // 0' 2>/dev/null)

    # Calculate total time (slowest agent)
    MAX_DURATION=0
    TOTAL_DURATION=0

    # Get all agent durations from batch summary
    while IFS= read -r agent_data; do
      if [ -n "$agent_data" ]; then
        dur=$(echo "$agent_data" | jq -r '.duration_ms // 0' 2>/dev/null)
        if [ "$dur" -gt "$MAX_DURATION" ]; then
          MAX_DURATION=$dur
        fi
        TOTAL_DURATION=$((TOTAL_DURATION + dur))
      fi
    done < <(echo "$BATCH_SUMMARY" | jq -c '.agents[]' 2>/dev/null)

    # Calculate speedup
    if [ "$MAX_DURATION" -gt 0 ] && [ "$TOTAL_DURATION" -gt 0 ]; then
      SPEEDUP=$(awk "BEGIN {printf \"%.1f\", $TOTAL_DURATION / $MAX_DURATION}" 2>/dev/null || echo "?")
      MAX_SEC=$(awk "BEGIN {printf \"%.1f\", $MAX_DURATION / 1000}" 2>/dev/null || echo "?")
      TOTAL_SEC=$(awk "BEGIN {printf \"%.1f\", $TOTAL_DURATION / 1000}" 2>/dev/null || echo "?")
    else
      SPEEDUP="?"
      MAX_SEC="?"
      TOTAL_SEC="?"
    fi

    {
      echo ""
      echo "┌─────────────────────────────────────────────────────────────┐"
      printf "│ ✅ PARALLEL DISPATCH COMPLETE (%d/%d)                       │\n" "$COMPLETED_COUNT" "$EXPECTED_COUNT"
      echo "├─────────────────────────────────────────────────────────────┤"

      # List each agent result
      agent_num=1
      while IFS= read -r agent_data; do
        if [ -n "$agent_data" ]; then
          a_status=$(echo "$agent_data" | jq -r '.status // "success"' 2>/dev/null)
          a_desc=$(echo "$agent_data" | jq -r '.description // "Agent"' 2>/dev/null | head -c 35)
          a_dur=$(echo "$agent_data" | jq -r '.duration_ms // 0' 2>/dev/null)
          a_dur_sec=$(awk "BEGIN {printf \"%.1f\", $a_dur / 1000}" 2>/dev/null || echo "?")
          a_emoji=$(get_status_emoji "$a_status")

          if [ "$agent_num" -lt "$COMPLETED_COUNT" ]; then
            printf "│ ├─ %s %-35s (%ss) │\n" "$a_emoji" "$a_desc" "$a_dur_sec"
          else
            printf "│ └─ %s %-35s (%ss) │\n" "$a_emoji" "$a_desc" "$a_dur_sec"
          fi
          agent_num=$((agent_num + 1))
        fi
      done < <(echo "$BATCH_SUMMARY" | jq -c '.agents[]' 2>/dev/null)

      echo "│                                                             │"
      printf "│ 📊 Total: %ss (vs ~%ss sequential) = %sx speedup       │\n" "$MAX_SEC" "$TOTAL_SEC" "$SPEEDUP"
      echo "└─────────────────────────────────────────────────────────────┘"
      echo ""
    } >&2

  else
    # More agents pending - show quiet individual completion
    {
      echo "   ${STATUS_EMOJI} ${DESC_SHORT} completed (${DURATION_SEC}s)"
    } >&2
  fi
fi

# Log for debugging
mkdir -p "$(dirname "$LOG_FILE")" 2>/dev/null
{
  END_TIME=$(_get_nano_time)
  HOOK_DURATION=$(( (END_TIME - START_TIME) / 1000000 ))
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] COMPLETE agent=$AGENT_ID status=$STATUS duration=${DURATION_SEC}s hook=${HOOK_DURATION}ms"
} >> "$LOG_FILE" 2>/dev/null

exit 0
