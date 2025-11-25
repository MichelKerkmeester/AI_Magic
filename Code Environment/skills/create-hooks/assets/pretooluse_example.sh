#!/bin/bash

# ───────────────────────────────────────────────────────────────
# BASH COMMAND VALIDATION HOOK EXAMPLE
# ───────────────────────────────────────────────────────────────
# PreToolUse hook that validates bash commands before execution
# to prevent dangerous operations and security risks.
#
# Version: 1.0.0
# Created: 2025-11-24
#
# PERFORMANCE TARGET: <50ms (blocks tool execution - must be fast)
# COMPATIBILITY: Bash 3.2+ (macOS and Linux compatible)
#
# EXECUTION ORDER: PreToolUse hook
#   Fires when: Before any tool executes
#   Can block: YES (prevents tool from running)
#   Purpose: Safety checks and command validation
#
# EXIT CODE CONVENTION:
#   0 = Allow (command is safe, proceed with execution)
#   1 = Block (command is dangerous, prevent execution with warning)
#   2 = Error (critical validation failure)
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
  exit 0  # Skip validation if jq not available
fi

# ───────────────────────────────────────────────────────────────
# PARSE JSON PAYLOAD
# ───────────────────────────────────────────────────────────────

INPUT=$(cat)

# Extract tool name and command
TOOL_NAME=$(echo "$INPUT" | jq -r '.tool_name // empty' 2>/dev/null)
COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // empty' 2>/dev/null)

# Only validate Bash tool
if [ "$TOOL_NAME" != "Bash" ]; then
  exit 0  # Allow other tools without validation
fi

# If no command found, allow it
if [ -z "$COMMAND" ]; then
  exit 0
fi

# ───────────────────────────────────────────────────────────────
# VALIDATION: Dangerous Command Patterns
# ───────────────────────────────────────────────────────────────

# Define dangerous patterns to block
DANGEROUS_PATTERNS=(
  # Destructive commands
  "rm -rf /"
  "rm -rf /*"
  "rm -rf \$HOME"

  # System damage
  "dd if=/dev/zero"
  "mkfs\."
  "> /dev/sda"

  # Fork bomb
  ":(){:|:&};:"

  # Dangerous permissions
  "chmod 777 /"
  "chmod -R 777 /"

  # Pipe to shell (potential security risk)
  "curl.*|.*sh"
  "wget.*|.*sh"

  # Eval with potential injection
  "eval \$"

  # System file modification
  "> /etc/"
  ">> /etc/"
)

# Check for dangerous patterns
for pattern in "${DANGEROUS_PATTERNS[@]}"; do
  if echo "$COMMAND" | grep -qE "$pattern"; then
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" >&2
    echo "🚫 COMMAND BLOCKED - Security" >&2
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" >&2
    echo "" >&2
    echo "Pattern matched: $pattern" >&2
    echo "" >&2
    echo "Reason: Dangerous command that could:" >&2
    echo "  • Delete important files or directories" >&2
    echo "  • Damage system integrity" >&2
    echo "  • Compromise system security" >&2
    echo "" >&2
    echo "Command: $COMMAND" >&2
    echo "" >&2
    echo "Please use safer alternatives." >&2
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" >&2

    # Log the blocked command
    LOG_DIR="$HOOKS_DIR/logs"
    mkdir -p "$LOG_DIR"
    TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')
    echo "[$TIMESTAMP] BLOCKED: $pattern - $COMMAND" >> "$LOG_DIR/blocked-commands.log"

    exit $EXIT_BLOCK  # Block execution
  fi
done

# ───────────────────────────────────────────────────────────────
# VALIDATION: Syntax Check (Optional)
# ───────────────────────────────────────────────────────────────

# Optionally validate bash syntax
if ! echo "$COMMAND" | bash -n 2>/dev/null; then
  echo "⚠️  WARNING: Bash syntax error detected" >&2
  echo "   Command may fail: ${COMMAND:0:80}..." >&2
  # Don't block - just warn (syntax errors will be caught during execution)
fi

# ───────────────────────────────────────────────────────────────
# PERFORMANCE LOGGING
# ───────────────────────────────────────────────────────────────

END_TIME=$(date +%s%N)
DURATION=$(( (END_TIME - START_TIME) / 1000000 ))
log_performance "bash-validation" "$DURATION"

# ───────────────────────────────────────────────────────────────
# EXIT
# ───────────────────────────────────────────────────────────────

# Command is safe, allow execution
exit $EXIT_ALLOW
