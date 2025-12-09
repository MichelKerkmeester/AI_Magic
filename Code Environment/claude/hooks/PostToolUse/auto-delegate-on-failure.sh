#!/bin/bash

# ───────────────────────────────────────────────────────────────
# AUTO-DELEGATE-ON-FAILURE.SH - Debug Specialist Auto-Dispatch
# ───────────────────────────────────────────────────────────────
# PostToolUse hook that triggers after Bash tool with non-zero exit.
# Tracks debug attempts and dispatches debug specialist when
# threshold is reached (default: 3 failures).
#
# Version: 1.0.0
# Created: 2025-12-06
# Tasks: T124-T125 (US-014)
# Spec: specs/013-speckit-enhancements-from-repo-reference/
#
# TRIGGERS: After Bash tool with exit_code != 0
# OUTPUT: Debug dispatch suggestion when threshold reached
# BLOCKING: No - advisory only
#
# PERFORMANCE TARGET: <50ms
# COMPATIBILITY: Bash 3.2+ (macOS and Linux)
# ───────────────────────────────────────────────────────────────

set -euo pipefail

# Script setup
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" 2>/dev/null && pwd)"
HOOKS_DIR="$(cd "$SCRIPT_DIR/.." 2>/dev/null && pwd)"

# Logging
LOG_DIR="$HOOKS_DIR/logs"
LOG_FILE="$LOG_DIR/auto-delegate-on-failure.log"
mkdir -p "$LOG_DIR" 2>/dev/null || true

# Cross-platform timing
_get_time_ms() {
    if [[ "$OSTYPE" == "darwin"* ]]; then
        echo $(($(date +%s) * 1000))
    else
        date +%s%3N 2>/dev/null || echo $(($(date +%s) * 1000))
    fi
}

START_TIME=$(_get_time_ms)

# Read JSON input from stdin
INPUT=$(cat)

# Extract tool information
TOOL_NAME=$(echo "$INPUT" | jq -r '.tool_name // .toolName // .name // ""' 2>/dev/null)
EXIT_CODE=$(echo "$INPUT" | jq -r '.tool_output.exit_code // .output.exit_code // .exit_code // 0' 2>/dev/null)
COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // .input.command // ""' 2>/dev/null)
OUTPUT_SNIPPET=$(echo "$INPUT" | jq -r '.tool_output.output // .output.stdout // .output // ""' 2>/dev/null | head -c 200)

# Only process Bash tool calls
if [[ "$TOOL_NAME" != "Bash" && "$TOOL_NAME" != "bash" ]]; then
    exit 0
fi

# Only process failures (non-zero exit)
if [[ "$EXIT_CODE" == "0" || -z "$EXIT_CODE" ]]; then
    # Success - clear failure count
    if [[ -f "$HOOKS_DIR/lib/adhoc-dispatch.sh" ]]; then
        source "$HOOKS_DIR/lib/adhoc-dispatch.sh" 2>/dev/null || true
        clear_debug_failures 2>/dev/null || true
    fi
    exit 0
fi

# Source adhoc-dispatch library
if [[ ! -f "$HOOKS_DIR/lib/adhoc-dispatch.sh" ]]; then
    {
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] ERROR: adhoc-dispatch.sh not found"
    } >> "$LOG_FILE" 2>/dev/null
    exit 0
fi

source "$HOOKS_DIR/lib/adhoc-dispatch.sh" 2>/dev/null || {
    echo '{"systemMessage": "⚠️ Ad-hoc dispatch library not found - skipping failure tracking"}'
    exit 0
}

# Track this failure
track_debug_failure "$COMMAND" "$EXIT_CODE" "$OUTPUT_SNIPPET"

# Check if threshold reached
if should_dispatch_debug_specialist; then
    # Get failure count for context
    FAILURE_COUNT=$(get_debug_failure_count)
    
    # Emit dispatch suggestion
    emit_debug_dispatch_suggestion "Command failed: ${COMMAND:0:50}"
    
    # Log delegation event
    {
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] DEBUG DELEGATION TRIGGERED"
        echo "  Failure Count: $FAILURE_COUNT"
        echo "  Command: $COMMAND"
        echo "  Exit Code: $EXIT_CODE"
        echo "  Snippet: ${OUTPUT_SNIPPET:0:100}"
        echo "───────────────────────────────────────────────────────────────"
    } >> "$LOG_FILE" 2>/dev/null
else
    CURRENT_COUNT=$(get_debug_failure_count)
    THRESHOLD="${DEBUG_THRESHOLD:-3}"
    
    {
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] Failure tracked: $CURRENT_COUNT/$THRESHOLD"
        echo "  Command: ${COMMAND:0:50}"
    } >> "$LOG_FILE" 2>/dev/null
fi

# Performance timing
END_TIME=$(_get_time_ms)
DURATION=$((END_TIME - START_TIME))
echo "[$(date '+%Y-%m-%d %H:%M:%S')] auto-delegate-on-failure.sh ${DURATION}ms" >> "$HOOKS_DIR/logs/performance.log" 2>/dev/null

exit 0
