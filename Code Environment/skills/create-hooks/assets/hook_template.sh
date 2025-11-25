#!/bin/bash

# ───────────────────────────────────────────────────────────────
# [HOOK NAME]
# ───────────────────────────────────────────────────────────────
# [Brief description of what this hook does - 1-2 sentences explaining
#  the purpose and what actions it performs]
#
# Version: 1.0.0
# Created: YYYY-MM-DD
#
# PERFORMANCE TARGET: <Xms/s (e.g., <50ms, <200ms, <5s)>
# COMPATIBILITY: Bash 3.2+ (macOS and Linux compatible)
#
# EXECUTION ORDER: [HookType] hook (e.g., PreCompact, UserPromptSubmit)
#   Fires when: [specific trigger condition]
#   Can block: YES/NO
#   Purpose: [primary purpose - e.g., validation, auto-fix, logging]
#
# EXIT CODE CONVENTION:
#   0 = [meaning - e.g., Allow execution / Success]
#   1 = [meaning - e.g., Block execution / Warning]
#   2 = [meaning - e.g., Critical error / Block]
# ───────────────────────────────────────────────────────────────

# ───────────────────────────────────────────────────────────────
# SETUP: Source shared libraries
# ───────────────────────────────────────────────────────────────

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" 2>/dev/null && pwd)"
HOOKS_DIR="$(cd "$SCRIPT_DIR/.." 2>/dev/null && pwd)"

# Source helper functions (output formatting, logging)
source "$HOOKS_DIR/lib/output-helpers.sh" || exit 0
source "$HOOKS_DIR/lib/exit-codes.sh" || exit 0

# ───────────────────────────────────────────────────────────────
# PERFORMANCE TIMING
# ───────────────────────────────────────────────────────────────

START_TIME=$(date +%s%N)

# ───────────────────────────────────────────────────────────────
# DEPENDENCY CHECKS
# ───────────────────────────────────────────────────────────────
# Check for required external tools and gracefully degrade if missing

# Example: Check for jq (JSON processor)
# if ! check_dependency "jq" "brew install jq (macOS) or apt install jq (Linux)"; then
#   echo "   ⚠️  Hook skipped: jq not available" >&2
#   exit $EXIT_ALLOW  # Graceful degradation
# fi

# Example: Check for optional dependencies
# if ! command -v node &>/dev/null; then
#   echo "   💡 node not found (optional feature disabled)" >&2
# fi

# ───────────────────────────────────────────────────────────────
# PARSE JSON PAYLOAD
# ───────────────────────────────────────────────────────────────
# Read JSON from stdin and extract required fields

INPUT=$(cat)

# Extract common fields (customize based on hook type)
# SESSION_ID=$(echo "$INPUT" | jq -r '.session_id // empty' 2>/dev/null)
# CWD=$(echo "$INPUT" | jq -r '.cwd // empty' 2>/dev/null)

# Hook-specific fields
# FIELD1=$(echo "$INPUT" | jq -r '.field1 // "default_value"' 2>/dev/null)
# FIELD2=$(echo "$INPUT" | jq -r '.field2 // empty' 2>/dev/null)

# ───────────────────────────────────────────────────────────────
# INPUT SANITIZATION (SECURITY)
# ───────────────────────────────────────────────────────────────
# Always sanitize user-controlled inputs to prevent security issues

# Example: Sanitize session ID (alphanumeric + dash/underscore only)
# if [ -n "$SESSION_ID" ]; then
#   SESSION_ID=$(echo "$SESSION_ID" | tr -cd 'a-zA-Z0-9_-')
# fi

# Example: Validate and sanitize file paths
# if [ -n "$CWD" ]; then
#   SAFE_CWD=$(realpath "$CWD" 2>/dev/null || echo "$CWD")
#   if [ ! -d "$SAFE_CWD" ]; then
#     echo "   ⚠️  Invalid working directory: $CWD" >&2
#     exit $EXIT_ALLOW  # or EXIT_BLOCK depending on severity
#   fi
#   CWD="$SAFE_CWD"
# fi

# Example: Sanitize user text (remove shell metacharacters)
# SAFE_TEXT=$(echo "$USER_TEXT" | tr -cd '[:alnum:][:space:]._-')

# ───────────────────────────────────────────────────────────────
# VALIDATION
# ───────────────────────────────────────────────────────────────
# Validate required fields and business logic

# Example: Check required fields
# if [ -z "$REQUIRED_FIELD" ]; then
#   echo "   ❌ Error: Required field missing" >&2
#   exit $EXIT_BLOCK  # or EXIT_ALLOW for non-critical
# fi

# Example: Validate business rules
# if ! validate_business_logic; then
#   echo "   ⚠️  Validation failed: $REASON" >&2
#   exit $EXIT_BLOCK
# fi

# ───────────────────────────────────────────────────────────────
# CORE LOGIC
# ───────────────────────────────────────────────────────────────
# Implement your hook's main functionality here

# Display notification to user (optional)
# echo "🔧 Hook: [Your message here]"

# Example Pattern 1: Keyword Detection
# PROMPT_LOWER=$(echo "$PROMPT" | tr '[:upper:]' '[:lower:]')
# KEYWORDS=("keyword1" "keyword2" "keyword3")
# for keyword in "${KEYWORDS[@]}"; do
#   if echo "$PROMPT_LOWER" | grep -qF "$keyword"; then
#     echo "🎯 Detected keyword: '$keyword'"
#     # Perform action
#     break
#   fi
# done

# Example Pattern 2: File Processing
# if [ -f "$FILE_PATH" ]; then
#   # Process file
#   process_file "$FILE_PATH"
# fi

# Example Pattern 3: Command Validation
# if ! validate_command "$COMMAND"; then
#   echo "🚫 BLOCKED: Invalid command" >&2
#   exit $EXIT_BLOCK
# fi

# Example Pattern 4: External Script Execution
# TEMP_FILE=$(mktemp)
# echo "$INPUT" > "$TEMP_FILE"
# if ! node "$HOOKS_DIR/scripts/process.js" "$TEMP_FILE"; then
#   echo "   ⚠️  External script failed" >&2
#   rm -f "$TEMP_FILE"
#   exit $EXIT_ALLOW  # Graceful degradation
# fi
# rm -f "$TEMP_FILE"

# [YOUR HOOK LOGIC HERE]

# ───────────────────────────────────────────────────────────────
# LOGGING (OPTIONAL)
# ───────────────────────────────────────────────────────────────
# Log operations for debugging and auditing

# LOG_DIR="$HOOKS_DIR/logs"
# mkdir -p "$LOG_DIR"
# LOG_FILE="$LOG_DIR/[hook-name].log"
#
# TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')
# echo "[$TIMESTAMP] Hook executed: [details]" >> "$LOG_FILE"

# ───────────────────────────────────────────────────────────────
# PERFORMANCE LOGGING
# ───────────────────────────────────────────────────────────────

END_TIME=$(date +%s%N)
DURATION=$(( (END_TIME - START_TIME) / 1000000 ))

# Log performance using helper function
log_performance "[hook-name]" "$DURATION"

# Optional: Log to dedicated performance file
# echo "[$(date '+%Y-%m-%d %H:%M:%S')] [hook-name] ${DURATION}ms" >> "$HOOKS_DIR/logs/performance.log"

# ───────────────────────────────────────────────────────────────
# EXIT
# ───────────────────────────────────────────────────────────────
# Exit with appropriate code based on hook type and outcome

# For hooks that should always allow (PreCompact, PostToolUse, etc.):
exit $EXIT_ALLOW  # 0

# For hooks that may block (PreToolUse, UserPromptSubmit, etc.):
# exit $EXIT_ALLOW   # 0: Allow execution
# exit $EXIT_BLOCK   # 1: Block with warning
# exit $EXIT_ERROR   # 2: Critical error, block
