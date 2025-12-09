#!/bin/bash
# ───────────────────────────────────────────────────────────────
# VALIDATE DISPATCH REQUIREMENT HOOK
# ───────────────────────────────────────────────────────────────
# PreToolUse hook that blocks non-Task tools when parallel dispatch
# is required but not yet executed.
#
# PERFORMANCE TARGET: <10ms
#
# EXECUTION ORDER: PreToolUse hook (runs BEFORE tool execution)
#
# EXIT CODE CONVENTION:
#   0 = Allow (tool can proceed)
#   1 = Block (tool blocked, require dispatch first)
# ───────────────────────────────────────────────────────────────

# Source shared state library
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" 2>/dev/null && pwd)"
source "$SCRIPT_DIR/../lib/shared-state.sh" 2>/dev/null || exit 0

# Logging
LOG_FILE="$SCRIPT_DIR/../logs/validate-dispatch.log"
mkdir -p "$(dirname "$LOG_FILE")" 2>/dev/null

# Read input
INPUT=$(cat)

# Extract tool name from JSON
TOOL_NAME=$(echo "$INPUT" | jq -r '.name // empty' 2>/dev/null)

# If no tool name, allow
if [ -z "$TOOL_NAME" ]; then
  exit 0
fi

# Tools that are always allowed (even during pending dispatch)
ALLOWED_TOOLS="Task|AskUserQuestion|Read|Glob|Grep|WebSearch|WebFetch|TodoWrite"

# Check if this is an allowed tool
if echo "$TOOL_NAME" | grep -qE "^($ALLOWED_TOOLS)$"; then
  # Task tool clears the pending dispatch requirement
  if [[ "$TOOL_NAME" == "Task" ]]; then
    # Clear pending dispatch state when Task tool is used
    clear_hook_state "pending_dispatch" 2>/dev/null || true
  fi
  exit 0
fi

# Check for pending dispatch requirement
DISPATCH_STATE=$(read_hook_state "pending_dispatch" 2>/dev/null)

# Log state check
{
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] CHECK tool=$TOOL_NAME state='$DISPATCH_STATE'"
} >> "$LOG_FILE" 2>/dev/null

# If no pending dispatch, allow the tool
if [ -z "$DISPATCH_STATE" ] || [ "$DISPATCH_STATE" == "{}" ] || [ "$DISPATCH_STATE" == "" ]; then
  {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] ALLOW tool=$TOOL_NAME reason=no_pending_dispatch"
  } >> "$LOG_FILE" 2>/dev/null
  exit 0
fi

# Parse dispatch state
REQUIRED=$(echo "$DISPATCH_STATE" | jq -r '.required // false' 2>/dev/null)

if [[ "$REQUIRED" == "true" ]]; then
  # Extract details for error message
  COMPLEXITY=$(echo "$DISPATCH_STATE" | jq -r '.complexity // "unknown"' 2>/dev/null)
  AGENTS=$(echo "$DISPATCH_STATE" | jq -r '.agents // "unknown"' 2>/dev/null)
  DOMAINS=$(echo "$DISPATCH_STATE" | jq -r '.domains // "unknown"' 2>/dev/null)

  # Log blocking decision
  {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] BLOCK tool=$TOOL_NAME complexity=$COMPLEXITY agents=$AGENTS domains=$DOMAINS"
  } >> "$LOG_FILE" 2>/dev/null

  # Block the tool and show error
  {
    echo ""
    echo "┌─────────────────────────────────────────────────────────────┐"
    echo "│ 🔴 BLOCKED: Parallel Dispatch Required                     │"
    echo "├─────────────────────────────────────────────────────────────┤"
    echo "│ The '${TOOL_NAME}' tool is blocked because parallel dispatch │"
    echo "│ is required for this high-complexity task.                 │"
    echo "│                                                             │"
    echo "│ Task Analysis:                                             │"
    echo "│   • Complexity: ${COMPLEXITY}%                              │"
    echo "│   • Domains detected: ${DOMAINS}                            │"
    echo "│   • Recommended agents: ${AGENTS}                           │"
    echo "│                                                             │"
    echo "│ How to proceed:                                            │"
    echo "│ ✓ Use Task tool to create ${AGENTS} sub-agents              │"
    echo "│   (one per domain for parallel execution)                  │"
    echo "│                                                             │"
    echo "│ Override options:                                          │"
    echo "│ • Say 'proceed directly' to handle sequentially            │"
    echo "│ • Say 'skip parallel' to bypass this check                 │"
    echo "└─────────────────────────────────────────────────────────────┘"
    echo ""
  } >&2

  exit ${EXIT_BLOCK:-1}
fi

# Default: allow
exit ${EXIT_ALLOW:-0}
