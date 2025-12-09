#!/bin/bash

# ───────────────────────────────────────────────────────────────
# BASH COMMAND CONTEXT BLOAT PREVENTION HOOK
# ───────────────────────────────────────────────────────────────
# PreToolUse hook that prevents wasted tokens by blocking reads of
# large, irrelevant files before they consume your context window
#
# PRIMARY PURPOSE: Context window optimization (not security)
# - Blocks reads of node_modules/, build/, dist/, .env files
# - Prevents accidental context bloat from large directories
# - Secondary benefit: Also blocks truly dangerous commands (rm -rf /, etc.)
#
# PERFORMANCE TARGET: <100ms (command validation, pattern matching)
# COMPATIBILITY: Bash 3.2+ (macOS and Linux compatible)
#
# EXECUTION ORDER: PreToolUse hook (runs BEFORE tool execution)
#   1. UserPromptSubmit hooks run FIRST (before processing user input)
#   2. PreToolUse hooks run SECOND (before tool execution, validation)
#   3. PostToolUse hooks run LAST (after tool completion, verification)
#   This hook: Validates bash commands before execution to prevent dangerous operations
#
# EXIT CODE CONVENTION:
#   0 = Allow (hook passed, continue execution)
#   1 = Block (hook failed, stop execution with warning)
#   2 = Error (reserved for critical failures)
# ───────────────────────────────────────────────────────────────

# Source output helpers and exit codes (completely silent on success)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" 2>/dev/null && pwd)"
HOOKS_DIR="$(cd "$SCRIPT_DIR/.." 2>/dev/null && pwd)"
source "$HOOKS_DIR/lib/output-helpers.sh" || exit 0
source "$HOOKS_DIR/lib/exit-codes.sh" || exit 0
source "$HOOKS_DIR/lib/perf-timing.sh" 2>/dev/null || true

# Logging configuration
LOG_DIR="$HOOKS_DIR/logs"
LOG_FILE="$LOG_DIR/$(basename "$0" .sh).log"

# Performance timing START (using centralized _get_nano_time from perf-timing.sh)
START_TIME=$(_get_nano_time)

# Read JSON input from stdin
INPUT=$(cat)

# Extract the command from JSON - correct path (silent on error)
COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // empty' 2>/dev/null)

# If no command found, allow it
if [ -z "$COMMAND" ]; then
  exit 0
fi

# Define whitelisted patterns (always allow these specific paths)
# L1 Fix: Added more log directories for legitimate debugging workflows
WHITELISTED_PATTERNS=(
  "\.claude/logs/"         # Allow reading skill logs
  "\.claude/hooks/logs/"   # Allow reading hook logs
  "\.claude/configs/"      # Allow reading configuration files
  "logs/.*\.log$"          # Allow reading project logs/ directory
  "tmp/.*\.log$"           # Allow reading temp logs
  "specs/.*\.log$"         # Allow reading spec folder logs
  "tests/.*\.log$"         # Allow reading test output logs
)

# Check if command matches any whitelisted patterns
for pattern in "${WHITELISTED_PATTERNS[@]}"; do
  if echo "$COMMAND" | grep -qE "$pattern"; then
    exit 0  # Whitelisted, allow immediately
  fi
done

# Define forbidden patterns (security + performance)
FORBIDDEN_PATTERNS=(
  # Large directories (performance)
  "node_modules"
  "frontend/node_modules"
  "__pycache__"
  "build/"
  "dist/"
  "venv/"

  # Binary/data files (performance)
  "\.pyc$"
  "\.csv$"
  "\.log$"

  # Sensitive files (security)
  "\.env"
  "\.git/config"
  "\.git/objects"
  "\.ssh/"
  "\.aws/"
  "\.pem$"
  "\.key$"
  "id_rsa"
  "credentials\.json"
  "secrets\."
  "password"

  # Dangerous commands (security)
  # Note: | must be escaped as \\| in bash array for grep -E to see it as literal
  "rm -rf /"
  "rm -rf \*"
  ":(){:\\|:&};:"
  "chmod 777"
  "chmod -R 777"
  "sudo rm"
  "curl.*\\|.*sh"
  "wget.*\\|.*sh"
  "eval "
  "> /etc/"
  "dd if=/dev/zero"
  "mkfs\\."
)

# ───────────────────────────────────────────────────────────────
# HEREDOC CONTENT EXCLUSION
# ───────────────────────────────────────────────────────────────
# Strip heredoc content from validation to prevent false positives.
# Heredocs are used for writing content (cat > file << 'EOF'), and their
# content should NOT be validated against file patterns.
#
# Examples that should NOT be blocked:
#   cat > report.txt << 'EOF'
#   This report discusses logging systems...  ← Contains ".log" but OK
#   EOF
#
# Only validate the command structure (before <<), not the content.
COMMAND_TO_CHECK="$COMMAND"
if echo "$COMMAND" | grep -qE '<<'; then
  # Remove heredoc and all content after it
  # Extract just the command before << (handles multi-line commands properly)
  # For "cat << 'EOF'\nstuff\nEOF", we want just "cat "
  COMMAND_TO_CHECK=$(echo "$COMMAND" | sed -n '1{s/<<.*//p}')
  # If the first line has content before <<, use it
  # Otherwise, the << is the whole command which is safe
  if [ -z "$COMMAND_TO_CHECK" ]; then
    COMMAND_TO_CHECK="heredoc_only"  # Safe placeholder
  fi
fi

# ───────────────────────────────────────────────────────────────
# OPTIMIZED PATTERN MATCHING (O(1) detection, O(n) only on match)
# ───────────────────────────────────────────────────────────────
# Combine all patterns into single regex with alternation for fast detection
# Only loop to find specific match if initial check passes
COMBINED_PATTERN=$(IFS='|'; echo "${FORBIDDEN_PATTERNS[*]}")

if echo "$COMMAND_TO_CHECK" | grep -qE "$COMBINED_PATTERN"; then
  # Match found - now identify which pattern matched for error message
  MATCHED_PATTERN=""
  for pattern in "${FORBIDDEN_PATTERNS[@]}"; do
    if echo "$COMMAND_TO_CHECK" | grep -qE "$pattern"; then
      MATCHED_PATTERN="$pattern"
      break
    fi
  done

  # Determine the category and provide helpful message
  case "$MATCHED_PATTERN" in
    "node_modules"|"build/"|"dist/"|"venv/"|"__pycache__"|"frontend/node_modules")
      # Emit systemMessage for Claude Code visibility
      echo "{\"systemMessage\": \"❌ BLOCKED: Command accesses large directory ($MATCHED_PATTERN) - use targeted file reads instead\"}"
      print_error_box "COMMAND BLOCKED - Performance" \
        "Pattern: $MATCHED_PATTERN" \
        "Reason: Large directory wastes tokens and slows execution" \
        "" \
        "Alternative: Use targeted file reads:" \
        "  • Read specific files directly" \
        "  • Use grep/glob patterns to find files" \
        "  • Search with code-specific tools"
      ;;
    "\.env"|"\.ssh/"|"\.aws/"|"\.pem$"|"\.key$"|"id_rsa"|"credentials\.json"|"secrets\."|"password"|"\.git/config"|"\.git/objects")
      # Emit systemMessage for Claude Code visibility
      echo "{\"systemMessage\": \"❌ BLOCKED: Command accesses sensitive file ($MATCHED_PATTERN) - security policy violation\"}"
      print_error_box "COMMAND BLOCKED - Security" \
        "Pattern: $MATCHED_PATTERN" \
        "Reason: Sensitive files may contain credentials" \
        "" \
        "Security Risk: This could expose:" \
        "  • API keys and tokens" \
        "  • Passwords and secrets" \
        "  • Private SSH keys" \
        "" \
        "Do not access sensitive files in conversations."
      ;;
    *)
      # Emit systemMessage for Claude Code visibility
      echo "{\"systemMessage\": \"❌ BLOCKED: Dangerous command detected ($MATCHED_PATTERN) - security policy violation\"}"
      print_error_box "COMMAND BLOCKED - Security" \
        "Pattern: $MATCHED_PATTERN" \
        "Reason: Dangerous command blocked by security policy" \
        "" \
        "This command could:" \
        "  • Delete important files" \
        "  • Modify system settings" \
        "  • Compromise system security" \
        "" \
        "Please use safer alternatives."
      ;;
  esac
  exit $EXIT_BLOCK  # Block execution with user warning
fi

# Performance timing END
END_TIME=$(_get_nano_time)
DURATION=$(( (END_TIME - START_TIME) / 1000000 ))
HOOKS_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
# Ensure log directory exists
[ -d "$HOOKS_DIR/logs" ] || mkdir -p "$HOOKS_DIR/logs" 2>/dev/null
echo "[$(date '+%Y-%m-%d %H:%M:%S')] validate-bash.sh ${DURATION}ms" >> "$HOOKS_DIR/logs/performance.log"

# Command is clean, allow it
exit 0