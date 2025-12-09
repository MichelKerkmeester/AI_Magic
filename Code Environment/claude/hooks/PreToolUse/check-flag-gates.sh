#!/bin/bash

# ───────────────────────────────────────────────────────────────
# CHECK FLAG GATES HOOK
# ───────────────────────────────────────────────────────────────
# PreToolUse hook that checks flag gates before Write/Edit operations.
# Blocks if BLOCKER flags exist, warns if WARNING threshold exceeded.
#
# Version: 1.0.0
# Created: 2025-12-06
# Hook Type: PreToolUse
# Tasks: T125-T135 (US-017/US-018)
#
# BLOCKING BEHAVIOR:
#   - BLOCKER flags: Hard block on Write, Edit, Bash
#   - WARNING threshold exceeded: Soft warning, allow proceed
#
# ENVIRONMENT:
#   TOOL_NAME - Name of the tool being invoked
#   TOOL_INPUT - JSON input for the tool
# ───────────────────────────────────────────────────────────────

set -euo pipefail

# Get hook directory
HOOKS_DIR="${HOOKS_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"

# Source dependencies
source "$HOOKS_DIR/lib/exit-codes.sh" 2>/dev/null || {
  readonly EXIT_ALLOW=0
  readonly EXIT_BLOCK=1
  readonly EXIT_WARNING=3
  readonly EXIT_SKIP=4
}

# Source flag system
if [[ -f "$HOOKS_DIR/lib/flag-system.sh" ]]; then
  source "$HOOKS_DIR/lib/flag-system.sh"
else
  # Flag system not available - skip check
  exit "${EXIT_SKIP:-4}"
fi

# Parse input from Claude hook system
TOOL_NAME="${TOOL_NAME:-}"
TOOL_INPUT="${TOOL_INPUT:-}"

# Read from stdin if environment variables not set
if [[ -z "$TOOL_NAME" ]]; then
  if [[ -t 0 ]]; then
    # No stdin and no env var - skip
    exit "${EXIT_SKIP:-4}"
  fi
  
  # Read JSON from stdin
  INPUT_JSON=$(cat)
  
  if command -v jq &>/dev/null; then
    TOOL_NAME=$(echo "$INPUT_JSON" | jq -r '.tool_name // empty' 2>/dev/null)
  else
    TOOL_NAME=$(echo "$INPUT_JSON" | grep -o '"tool_name":"[^"]*"' | sed 's/"tool_name":"//;s/"$//' 2>/dev/null)
  fi
fi

# ───────────────────────────────────────────────────────────────
# TOOL FILTERING
# ───────────────────────────────────────────────────────────────

# Tools that should be checked against flag gates
BLOCKED_TOOLS="Write Edit Bash"

# Check if current tool should be blocked
should_check_tool() {
  local tool="$1"
  
  for blocked_tool in $BLOCKED_TOOLS; do
    if [[ "$tool" == "$blocked_tool" ]]; then
      return 0
    fi
  done
  
  return 1
}

# Skip if not a blocking tool
if ! should_check_tool "$TOOL_NAME"; then
  exit "${EXIT_ALLOW:-0}"
fi

# ───────────────────────────────────────────────────────────────
# BLOCKER GATE CHECK
# ───────────────────────────────────────────────────────────────

# Check for BLOCKER flags first (hard block)
if has_blockers; then
  blocker_count=$(get_flag_count "BLOCKER" "active")
  
  echo "═══════════════════════════════════════════════════════════════"
  echo "BLOCKED: $blocker_count active BLOCKER flag(s)"
  echo "═══════════════════════════════════════════════════════════════"
  echo ""
  echo "Cannot proceed with $TOOL_NAME - resolve blockers first:"
  echo ""
  
  # List blockers
  if command -v jq &>/dev/null; then
    flags_json=$(read_hook_state "flags" 86400 2>/dev/null) || flags_json='{"flags":[]}'
    echo "$flags_json" | jq -r '.flags[] | select(.type == "BLOCKER" and .status == "active") | "  [!] [\(.task_id)] \(.message)"' 2>/dev/null
  fi
  
  echo ""
  echo "To resolve a blocker, use: resolve_flag <flag_id> <resolution_notes>"
  echo "═══════════════════════════════════════════════════════════════"
  
  exit "${EXIT_BLOCK:-1}"
fi

# ───────────────────────────────────────────────────────────────
# REVIEW GATE CHECK
# ───────────────────────────────────────────────────────────────

# Check WARNING threshold (soft warning, doesn't block)
warning_count=$(get_flag_count "WARNING" "active")

# Get threshold from config
if [[ -f "$PROJECT_ROOT/.claude/configs/flag-thresholds.json" ]] && command -v jq &>/dev/null; then
  max_warnings=$(jq -r '.thresholds.WARNING.max_active // 3' "$PROJECT_ROOT/.claude/configs/flag-thresholds.json" 2>/dev/null)
else
  max_warnings=3
fi

if [[ "$warning_count" -gt "$max_warnings" ]]; then
  echo "───────────────────────────────────────────────────────────────"
  echo "WARNING: $warning_count active WARNING flag(s) (threshold: $max_warnings)"
  echo "───────────────────────────────────────────────────────────────"
  echo ""
  echo "Consider resolving warnings before completing the task:"
  echo ""
  
  # List warnings
  if command -v jq &>/dev/null; then
    flags_json=$(read_hook_state "flags" 86400 2>/dev/null) || flags_json='{"flags":[]}'
    echo "$flags_json" | jq -r '.flags[] | select(.type == "WARNING" and .status == "active") | "  [~] [\(.task_id)] \(.message)"' 2>/dev/null
  fi
  
  echo ""
  echo "───────────────────────────────────────────────────────────────"
  
  # Return warning but allow to proceed
  exit "${EXIT_WARNING:-3}"
fi

# ───────────────────────────────────────────────────────────────
# INFO CHECK (non-blocking, just log)
# ───────────────────────────────────────────────────────────────

info_count=$(get_flag_count "INFO" "active")

if [[ "$info_count" -gt 0 ]]; then
  # Silently track info flags - no output to avoid noise
  :
fi

# All checks passed
exit "${EXIT_ALLOW:-0}"
