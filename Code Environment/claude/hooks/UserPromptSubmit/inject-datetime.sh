#!/bin/bash

# ───────────────────────────────────────────────────────────────
# DATE/TIME INJECTION HOOK
# ───────────────────────────────────────────────────────────────
# UserPromptSubmit hook that injects the current date and time
# into every message visible to the AI.
#
# OUTPUT FORMAT: "Current date and time is Tuesday 2 December 09:07 2025"
#
# PERFORMANCE TARGET: <5ms (simple date formatting)
# COMPATIBILITY: Bash 3.2+ (macOS and Linux compatible)
#
# EXIT CODE: Always 0 (informational only, never blocks)
# ───────────────────────────────────────────────────────────────

# Performance timing START
START_TIME=$(($(date +%s) * 1000))

# Resolve script directory for library sourcing
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" 2>/dev/null && pwd)"
HOOKS_DIR="$(cd "$SCRIPT_DIR/.." 2>/dev/null && pwd)"

# Read stdin (required to prevent blocking, even if unused)
cat > /dev/null

# ───────────────────────────────────────────────────────────────
# DATE FORMATTING
# ───────────────────────────────────────────────────────────────

# Get all date components in a single call for efficiency
# Format: "DayOfWeek DayNum Month Time Year" e.g., "Tuesday 2 December 09:07 2025"
# Using %-d for day without leading zero (works on macOS 10.9+ and GNU date)
DATETIME_STR="Current date and time is $(date '+%A %-d %B %H:%M %Y' 2>/dev/null)"

# Fallback if %-d not supported (very old systems)
if [[ "$DATETIME_STR" == *"%-d"* ]] || [[ -z "$DATETIME_STR" ]]; then
  DAY_OF_WEEK=$(date +%A)
  DAY_NUM=$(date +%d | sed 's/^0//')
  MONTH=$(date +%B)
  TIME=$(date +%H:%M)
  YEAR=$(date +%Y)
  DATETIME_STR="Current date and time is ${DAY_OF_WEEK} ${DAY_NUM} ${MONTH} ${TIME} ${YEAR}"
fi

# ───────────────────────────────────────────────────────────────
# OUTPUT
# ───────────────────────────────────────────────────────────────

# Output as systemMessage JSON for Claude Code visibility
printf '{"systemMessage": "%s"}\n' "$DATETIME_STR"

# Performance timing END
END_TIME=$(($(date +%s) * 1000))
DURATION=$((END_TIME - START_TIME))
echo "[$(date '+%Y-%m-%d %H:%M:%S')] inject-datetime.sh ${DURATION}ms" >> "$HOOKS_DIR/logs/performance.log" 2>/dev/null

# Always allow - this is purely informational
exit 0
