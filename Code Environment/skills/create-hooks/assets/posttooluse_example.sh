#!/bin/bash

# ───────────────────────────────────────────────────────────────
# AUTO-FORMAT HOOK EXAMPLE
# ───────────────────────────────────────────────────────────────
# PostToolUse hook that automatically formats markdown files
# after Write or Edit operations.
#
# Version: 1.0.0
# Created: 2025-11-24
#
# PERFORMANCE TARGET: <200ms (file formatting operations)
# COMPATIBILITY: Bash 3.2+ (macOS and Linux compatible)
#
# EXECUTION ORDER: PostToolUse hook
#   Fires when: After any tool completes execution
#   Can block: NO (tool already executed, cannot prevent)
#   Purpose: Auto-fix, formatting, post-processing
#
# EXIT CODE CONVENTION:
#   0 = Success (auto-fix applied or not needed)
#   1 = Warning (not used - cannot block anyway)
#   2 = Error (not used - cannot block anyway)
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

if ! check_dependency "jq" "brew install jq"; then
  exit 0  # Skip if jq not available
fi

# Check for prettier (optional formatter)
HAS_PRETTIER=false
if command -v prettier &>/dev/null; then
  HAS_PRETTIER=true
fi

# ───────────────────────────────────────────────────────────────
# PARSE JSON PAYLOAD
# ───────────────────────────────────────────────────────────────

INPUT=$(cat)

# Extract tool information
TOOL_NAME=$(echo "$INPUT" | jq -r '.tool_name // empty' 2>/dev/null)
EXIT_CODE=$(echo "$INPUT" | jq -r '.exit_code // 1' 2>/dev/null)
FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty' 2>/dev/null)

# ───────────────────────────────────────────────────────────────
# FILTERING: Only Process Relevant Operations
# ───────────────────────────────────────────────────────────────

# Only process successful Write/Edit operations
if [ "$EXIT_CODE" -ne 0 ]; then
  exit 0  # Tool failed, skip post-processing
fi

if [ "$TOOL_NAME" != "Write" ] && [ "$TOOL_NAME" != "Edit" ]; then
  exit 0  # Not a file modification tool
fi

if [ -z "$FILE_PATH" ] || [ ! -f "$FILE_PATH" ]; then
  exit 0  # No file path or file doesn't exist
fi

# Only format markdown files
if [[ "$FILE_PATH" != *.md ]]; then
  exit 0  # Not a markdown file
fi

# ───────────────────────────────────────────────────────────────
# AUTO-FORMATTING
# ───────────────────────────────────────────────────────────────

# Attempt to format with prettier if available
if [ "$HAS_PRETTIER" = true ]; then
  # Format the file (prettier modifies in-place with --write)
  if prettier --write "$FILE_PATH" 2>/dev/null; then
    echo "✨ Auto-formatted: $(basename "$FILE_PATH")"

    # Log the formatting action
    LOG_DIR="$HOOKS_DIR/logs"
    mkdir -p "$LOG_DIR"
    TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')
    echo "[$TIMESTAMP] Formatted: $FILE_PATH" >> "$LOG_DIR/auto-format.log"
  else
    echo "⚠️  Warning: Prettier formatting failed for $(basename "$FILE_PATH")" >&2
  fi
else
  # Prettier not available - could implement basic formatting here
  # For example: fix line endings, trim trailing whitespace, etc.

  # Basic fix: Remove trailing whitespace
  if command -v sed &>/dev/null; then
    # Create backup
    cp "$FILE_PATH" "$FILE_PATH.bak"

    # Remove trailing whitespace (bash 3.2 compatible)
    sed 's/[[:space:]]*$//' "$FILE_PATH.bak" > "$FILE_PATH"

    # Check if changes were made
    if ! cmp -s "$FILE_PATH" "$FILE_PATH.bak"; then
      echo "✨ Removed trailing whitespace: $(basename "$FILE_PATH")"
    fi

    # Remove backup
    rm -f "$FILE_PATH.bak"
  fi
fi

# ───────────────────────────────────────────────────────────────
# PERFORMANCE LOGGING
# ───────────────────────────────────────────────────────────────

END_TIME=$(date +%s%N)
DURATION=$(( (END_TIME - START_TIME) / 1000000 ))
log_performance "auto-format" "$DURATION"

# ───────────────────────────────────────────────────────────────
# EXIT
# ───────────────────────────────────────────────────────────────

# Always allow (PostToolUse cannot block)
exit $EXIT_ALLOW
