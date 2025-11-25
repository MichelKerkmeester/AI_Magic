#!/bin/bash

# ───────────────────────────────────────────────────────────────
# KEYWORD DETECTION HOOK EXAMPLE
# ───────────────────────────────────────────────────────────────
# UserPromptSubmit hook that detects keywords in user messages
# and triggers actions automatically.
#
# Version: 1.0.0
# Created: 2025-11-24
#
# PERFORMANCE TARGET: <200ms (keyword matching is fast)
# COMPATIBILITY: Bash 3.2+ (macOS and Linux compatible)
#
# EXECUTION ORDER: UserPromptSubmit hook
#   Fires when: User submits a message
#   Can block: YES (but this example doesn't block)
#   Purpose: Auto-trigger workflows based on keywords
#
# EXIT CODE CONVENTION:
#   0 = Allow (message processing continues)
#   1 = Block (would prevent message processing - not used here)
#   2 = Error (critical failure - not used here)
# ───────────────────────────────────────────────────────────────

# Source shared libraries
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" 2>/dev/null && pwd)"
HOOKS_DIR="$(cd "$SCRIPT_DIR/.." 2>/dev/null && pwd)"

source "$HOOKS_DIR/lib/output-helpers.sh" || exit 0
source "$HOOKS_DIR/lib/exit-codes.sh" || exit 0

# Performance timing START
START_TIME=$(date +%s%N)

# ───────────────────────────────────────────────────────────────
# DEPENDENCY CHECKS
# ───────────────────────────────────────────────────────────────

if ! check_dependency "jq" "brew install jq (macOS) or apt install jq (Linux)"; then
  exit 0  # Silently skip if jq not available
fi

# ───────────────────────────────────────────────────────────────
# PARSE JSON PAYLOAD
# ───────────────────────────────────────────────────────────────

INPUT=$(cat)

# Extract prompt text from payload
PROMPT=$(echo "$INPUT" | jq -r '.prompt // empty' 2>/dev/null)

# If no prompt found, allow silently
if [ -z "$PROMPT" ]; then
  exit 0
fi

# ───────────────────────────────────────────────────────────────
# KEYWORD DETECTION
# ───────────────────────────────────────────────────────────────

# Convert to lowercase for case-insensitive matching
PROMPT_LOWER=$(echo "$PROMPT" | tr '[:upper:]' '[:lower:]')

# Define trigger keywords
# Add your own keywords here
KEYWORDS=(
  "save context"
  "save conversation"
  "document this"
  "export conversation"
  "preserve context"
)

# Check for keyword matches
KEYWORD_FOUND=false
MATCHED_KEYWORD=""

for keyword in "${KEYWORDS[@]}"; do
  # Use grep with word boundaries to avoid partial matches
  if echo "$PROMPT_LOWER" | grep -qE "\\b${keyword}\\b"; then
    KEYWORD_FOUND=true
    MATCHED_KEYWORD="$keyword"
    break
  fi
done

# If keyword detected, trigger action
if [ "$KEYWORD_FOUND" = true ]; then
  echo "🎯 Detected keyword: \"$MATCHED_KEYWORD\""
  echo "   Triggering workflows-save-context skill..."

  # The skill activation happens automatically when we output a message
  # Claude Code will see this and trigger the appropriate workflow

  # You could also:
  # - Log the detection event
  # - Call an external script
  # - Perform any other automated action

  # Example: Log to file
  LOG_DIR="$HOOKS_DIR/logs"
  mkdir -p "$LOG_DIR"
  TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')
  echo "[$TIMESTAMP] Keyword detected: '$MATCHED_KEYWORD'" >> "$LOG_DIR/keyword-detections.log"
fi

# ───────────────────────────────────────────────────────────────
# PERFORMANCE LOGGING
# ───────────────────────────────────────────────────────────────

END_TIME=$(date +%s%N)
DURATION=$(( (END_TIME - START_TIME) / 1000000 ))
log_performance "keyword-detection" "$DURATION"

# ───────────────────────────────────────────────────────────────
# EXIT
# ───────────────────────────────────────────────────────────────

# Always allow message processing to continue
exit $EXIT_ALLOW
