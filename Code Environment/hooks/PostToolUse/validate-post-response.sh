#!/bin/bash

# ───────────────────────────────────────────────────────────────
# POST-TOOL-USE QUALITY CHECK HOOK
# ───────────────────────────────────────────────────────────────
# Runs after tools are used and provides gentle self-check
# Reminders based on file edits and code patterns
#
# PERFORMANCE TARGET: <200ms (file scanning, security analysis)
# PERFORMANCE NOTE: Executes synchronously after EVERY file edit
#   - Typical execution time: 20-40ms for pattern matching
#   - Checks for: API keys, credentials, animation patterns, async code
#   - Trade-off: Slight latency vs immediate security/quality validation
# COMPATIBILITY: Bash 3.2+ (macOS and Linux compatible)
#
# EXECUTION ORDER: PostToolUse hook (runs AFTER tool completion)
#   1. UserPromptSubmit hooks run FIRST (before processing user input)
#   2. PreToolUse hooks run SECOND (before tool execution, validation)
#   3. PostToolUse hooks run LAST (after tool completion, verification)
#   This hook: Detects security risks and quality patterns in edited code
#
# EXIT CODE CONVENTION:
#   0 = Allow (hook passed, continue execution)
#   1 = Block (hook failed, stop execution with warning)
#   2 = Error (reserved for critical failures)
# ───────────────────────────────────────────────────────────────

# Source output helpers (completely silent on success)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" 2>/dev/null && pwd)"
source "$SCRIPT_DIR/../lib/output-helpers.sh" || exit 0

# Cross-platform nanosecond timing helper
_get_nano_time() {
  if [[ "$OSTYPE" == "darwin"* ]]; then
    echo $(($(date +%s) * 1000000000))
  else
    date +%s%N 2>/dev/null || echo $(($(date +%s) * 1000000000))
  fi
}

# Performance timing START
START_TIME=$(_get_nano_time)

# Check dependencies (silent on success)
check_dependency "jq" "brew install jq (macOS) or apt install jq (Linux)" || exit 0

# Read JSON input from stdin
INPUT=$(cat)

# Extract tool information from the input (silent on error)
TOOL_NAME=$(echo "$INPUT" | jq -r '.tool_name // .toolName // empty' 2>/dev/null)

# Only process file editing tools
case "$TOOL_NAME" in
  "Edit"|"Write"|"NotebookEdit"|"replace_string_in_file"|"create_file"|"edit_notebook_file")
    # Extract file path from tool input (support multiple payload shapes)
    FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.filePath // .tool_input.file_path // .tool_input.path // .tool_input.notebook_path // .parameters.file_path // .parameters.filePath // .parameters.path // .parameters.notebook_path // empty' 2>/dev/null)

    if [ -z "$FILE_PATH" ]; then
      exit 0
    fi
    ;;
  *)
    # Not a file editing tool, exit silently
    exit 0
    ;;
esac

# Load risk patterns configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILL_RULES="$(cd "$SCRIPT_DIR/../.." && pwd)/configs/skill-rules.json"

if [ ! -f "$SKILL_RULES" ]; then
  # No rules file, silently exit
  exit 0
fi

# Array to store triggered reminders
TRIGGERED_REMINDERS=()

# ───────────────────────────────────────────────────────────────
# SECURITY: REGEX PATTERN VALIDATION
# ───────────────────────────────────────────────────────────────
# Validates regex patterns to prevent ReDoS (Regular Expression Denial of Service)
# attacks from compromised skill-rules.json configuration file
validate_regex_pattern() {
  local pattern="$1"

  # Check for dangerous ReDoS patterns:
  # 1. Nested quantifiers: (a+)+ or (a*)*
  # 2. Excessive wildcards: .*.*.* (3 or more in sequence)
  # 3. Overlapping alternation: (a|a)* or (ab|a)*
  # 4. Exponential backtracking patterns
  # 5. Pattern complexity limits

  # Check pattern length/complexity
  if [ ${#pattern} -gt 100 ]; then
    return 1  # Pattern too complex
  fi

  # Check for nested quantifiers (more comprehensive)
  if echo "$pattern" | grep -qE '\([^)]*[+*?{]\)[+*?{]'; then
    return 1  # Dangerous: nested quantifiers
  fi

  # Check for alternation with quantifiers
  if echo "$pattern" | grep -qE '\([^)]*\|[^)]*\)[+*?{]'; then
    return 1  # Dangerous: alternation with quantifier
  fi

  # Check for excessive consecutive wildcards
  if echo "$pattern" | grep -qE '(\.\*){3,}'; then
    return 1  # Dangerous: 3+ wildcards
  fi

  # Check for catastrophic backtracking patterns
  if echo "$pattern" | grep -qE '(.*\|.*){3,}'; then
    return 1  # Dangerous: multiple alternations with wildcards
  fi

  # Pattern is safe
  return 0
}

# ───────────────────────────────────────────────────────────────
# CHECK FILE FOR RISK PATTERNS
# ───────────────────────────────────────────────────────────────

check_file_for_patterns() {
  local file_path="$1"
  
  # Skip if file doesn't exist or isn't readable
  if [ ! -f "$file_path" ] || [ ! -r "$file_path" ]; then
    return
  fi
  
  # Get file content
  local content=$(cat "$file_path" 2>/dev/null)
  
  if [ -z "$content" ]; then
    return
  fi
  
  # Check each risk pattern category
  local risk_categories=$(jq -r '.riskPatterns // {} | keys[]' "$SKILL_RULES" 2>/dev/null)
  
  while IFS= read -r category; do
    if [ -z "$category" ]; then
      continue
    fi
    
    # Get patterns for this category
    local patterns=$(jq -r ".riskPatterns[\"$category\"].patterns // [] | .[]" "$SKILL_RULES" 2>/dev/null)
    
    # Check if any pattern matches
    local matched=false
    while IFS= read -r pattern; do
      if [ -n "$pattern" ]; then
        # Validate pattern before use (security: prevent ReDoS)
        if ! validate_regex_pattern "$pattern"; then
          # Skip dangerous pattern, continue checking others
          continue
        fi

        if echo "$content" | grep -qE "$pattern"; then
          matched=true
          break
        fi
      fi
    done <<< "$patterns"
    
    # If matched, add reminder (avoid duplicates)
    if [ "$matched" = true ]; then
      local reminder=$(jq -r ".riskPatterns[\"$category\"].reminder // empty" "$SKILL_RULES" 2>/dev/null)
      
      # Check if reminder already added
      local already_added=false
      for existing in "${TRIGGERED_REMINDERS[@]}"; do
        if [ "$existing" = "$reminder" ]; then
          already_added=true
          break
        fi
      done
      
      if [ "$already_added" = false ]; then
        TRIGGERED_REMINDERS+=("$reminder")
      fi
    fi
  done <<< "$risk_categories"
}

# Check the edited file
check_file_for_patterns "$FILE_PATH"

# ───────────────────────────────────────────────────────────────
# OUTPUT REMINDERS
# ───────────────────────────────────────────────────────────────

if [ ${#TRIGGERED_REMINDERS[@]} -gt 0 ]; then
  # Prepare log directory
  HOOKS_DIR="$(cd "$SCRIPT_DIR/.." 2>/dev/null && pwd)"
  LOG_DIR="$HOOKS_DIR/logs"
  mkdir -p "$LOG_DIR"
  LOG_FILE="$LOG_DIR/quality-checks.log"

  # Rotate log if it is getting large (best-effort, non-blocking)
  rotate_log_if_needed "$LOG_FILE" 102400

  # Prepare log entry with timestamp and file path
  TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')
  LOG_ENTRY="[$TIMESTAMP] File: $FILE_PATH"

  # Write to log file (no stderr output)
  {
    echo ""
    echo "$SEPARATOR"
    echo "$LOG_ENTRY"
    echo "$SEPARATOR"
    for reminder in "${TRIGGERED_REMINDERS[@]}"; do
      echo "$reminder"
      echo ""
    done
    echo "$SEPARATOR"
    echo ""
  } >> "$LOG_FILE"

  # Emit concise summary so reminders are visible without opening logs
  echo "QUALITY CHECK: Reminders logged for $FILE_PATH (see $LOG_FILE)"
  
  # Emit systemMessage for Claude Code visibility
  REMINDER_COUNT=${#TRIGGERED_REMINDERS[@]}
  visible_msg=$(jq -n --arg msg "⚠️ QUALITY CHECK: $REMINDER_COUNT reminder(s) triggered for $(basename "$FILE_PATH"). Review $LOG_FILE for details." '{systemMessage: $msg}')
  echo "$visible_msg"
fi

# Performance timing END
END_TIME=$(_get_nano_time)
DURATION=$(( (END_TIME - START_TIME) / 1000000 ))
HOOKS_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
# Ensure log directory exists
[ -d "$HOOKS_DIR/logs" ] || mkdir -p "$HOOKS_DIR/logs" 2>/dev/null
echo "[$(date '+%Y-%m-%d %H:%M:%S')] validate-post-response.sh ${DURATION}ms" >> "$HOOKS_DIR/logs/performance.log"

# Always allow silently (non-blocking)
exit 0


