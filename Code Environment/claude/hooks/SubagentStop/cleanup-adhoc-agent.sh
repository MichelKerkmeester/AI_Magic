#!/bin/bash

# ───────────────────────────────────────────────────────────────
# CLEANUP-ADHOC-AGENT.SH - Ad-Hoc Agent Cleanup Hook
# ───────────────────────────────────────────────────────────────
# SubagentStop hook that cleans up when an ad-hoc agent completes.
# Archives output to memory folder and updates task status.
#
# Version: 1.0.0
# Created: 2025-12-06
# Tasks: T128 (US-014)
# Spec: specs/013-speckit-enhancements-from-repo-reference/
#
# TRIGGERS: When any sub-agent stops (filters for ad-hoc agents)
# ACTIONS:
#   1. Detect if stopped agent is an ad-hoc agent
#   2. Archive agent output to spec memory folder
#   3. Clear relevant failure counters on success
#   4. Update task status if applicable
#
# PERFORMANCE TARGET: <100ms
# COMPATIBILITY: Bash 3.2+ (macOS and Linux)
# ───────────────────────────────────────────────────────────────

set -euo pipefail

# Script setup
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" 2>/dev/null && pwd)"
HOOKS_DIR="$(cd "$SCRIPT_DIR/.." 2>/dev/null && pwd)"

# Logging
LOG_DIR="$HOOKS_DIR/logs"
LOG_FILE="$LOG_DIR/cleanup-adhoc-agent.log"
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

# Extract SubagentStop payload fields
SESSION_ID=$(echo "$INPUT" | jq -r '.session_id // empty' 2>/dev/null)
TRANSCRIPT_PATH=$(echo "$INPUT" | jq -r '.transcript_path // empty' 2>/dev/null)
HOOK_EVENT=$(echo "$INPUT" | jq -r '.hook_event_name // empty' 2>/dev/null)

# Verify this is a SubagentStop event
if [[ "$HOOK_EVENT" != "SubagentStop" ]]; then
    exit 0
fi

# Source adhoc-dispatch library
if [[ ! -f "$HOOKS_DIR/lib/adhoc-dispatch.sh" ]]; then
    exit 0
fi

source "$HOOKS_DIR/lib/adhoc-dispatch.sh" 2>/dev/null || exit 0

# Source shared-state for spec folder detection
if [[ -f "$HOOKS_DIR/lib/shared-state.sh" ]]; then
    source "$HOOKS_DIR/lib/shared-state.sh" 2>/dev/null || true
fi

# ═══════════════════════════════════════════════════════════════
# DETECT AD-HOC AGENT
# ═══════════════════════════════════════════════════════════════

# Check if this is an ad-hoc agent (ID starts with "adhoc-")
AGENT_ID=""

# Try to get agent ID from active agents list
ACTIVE_AGENTS=$(list_active_adhoc_agents "simple" 2>/dev/null) || true

# Check if session_id matches any active ad-hoc agent
if [[ -n "$SESSION_ID" && "$SESSION_ID" == adhoc-* ]]; then
    AGENT_ID="$SESSION_ID"
elif [[ -n "$ACTIVE_AGENTS" ]]; then
    # Check each active agent
    while IFS= read -r agent; do
        if [[ -n "$agent" && "$agent" == adhoc-* ]]; then
            # This is an ad-hoc agent
            AGENT_ID="$agent"
            break
        fi
    done <<< "$ACTIVE_AGENTS"
fi

# If not an ad-hoc agent, exit silently
if [[ -z "$AGENT_ID" ]]; then
    exit 0
fi

# ═══════════════════════════════════════════════════════════════
# EXTRACT AGENT OUTPUT
# ═══════════════════════════════════════════════════════════════

OUTPUT_CONTENT=""

# Try to extract output from transcript if available
if [[ -n "$TRANSCRIPT_PATH" && -f "$TRANSCRIPT_PATH" ]]; then
    # Extract last assistant message as output summary
    OUTPUT_CONTENT=$(jq -r '
        .messages | 
        map(select(.role == "assistant")) | 
        last | 
        .content // "No content"
    ' "$TRANSCRIPT_PATH" 2>/dev/null | head -c 2000) || true
fi

# Fallback if no output extracted
if [[ -z "$OUTPUT_CONTENT" ]]; then
    OUTPUT_CONTENT="Agent completed. Transcript: ${TRANSCRIPT_PATH:-unavailable}"
fi

# ═══════════════════════════════════════════════════════════════
# DETERMINE SPEC FOLDER FOR ARCHIVING
# ═══════════════════════════════════════════════════════════════

SPEC_FOLDER=""

# Try to get active spec folder from phase bindings
if type phase_get &>/dev/null; then
    SPEC_FOLDER=$(phase_get "spec_folder" 2>/dev/null) || true
fi

# Fallback: Check for .spec-active file
if [[ -z "$SPEC_FOLDER" ]]; then
    PROJECT_ROOT="$(cd "$HOOKS_DIR/../.." 2>/dev/null && pwd)"
    if [[ -f "$PROJECT_ROOT/.spec-active" ]]; then
        SPEC_FOLDER=$(cat "$PROJECT_ROOT/.spec-active" 2>/dev/null | head -1)
        # Make path absolute if relative
        if [[ "$SPEC_FOLDER" != /* ]]; then
            SPEC_FOLDER="$PROJECT_ROOT/$SPEC_FOLDER"
        fi
    fi
fi

# ═══════════════════════════════════════════════════════════════
# ARCHIVE OUTPUT & CLEANUP
# ═══════════════════════════════════════════════════════════════

# Get agent info before termination
AGENT_INFO=$(get_adhoc_agent_info "$AGENT_ID" 2>/dev/null) || true
AGENT_TYPE=""
if [[ -n "$AGENT_INFO" ]]; then
    AGENT_TYPE=$(echo "$AGENT_INFO" | grep "^Type:" | cut -d':' -f2 | tr -d ' ')
fi

# Archive output
ARCHIVE_PATH=$(archive_adhoc_output "$AGENT_ID" "$OUTPUT_CONTENT" "$SPEC_FOLDER" 2>/dev/null) || true

# Terminate the ad-hoc agent
terminate_adhoc_agent "$AGENT_ID" "complete" 2>/dev/null || true

# Clear relevant failure counters based on agent type
case "$AGENT_TYPE" in
    debug)
        clear_debug_failures 2>/dev/null || true
        {
            echo "[$(date '+%Y-%m-%d %H:%M:%S')] Debug agent completed - failure counter cleared"
        } >> "$LOG_FILE" 2>/dev/null
        ;;
    test)
        clear_test_failures 2>/dev/null || true
        {
            echo "[$(date '+%Y-%m-%d %H:%M:%S')] Test agent completed - failure counter cleared"
        } >> "$LOG_FILE" 2>/dev/null
        ;;
esac

# Output confirmation
echo "{\"systemMessage\": \"✅ Ad-hoc agent ${AGENT_ID} completed and archived\"}"

# Log cleanup event
{
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] AD-HOC AGENT CLEANUP"
    echo "  Agent ID: $AGENT_ID"
    echo "  Type: ${AGENT_TYPE:-unknown}"
    echo "  Archive: ${ARCHIVE_PATH:-not archived}"
    echo "  Spec Folder: ${SPEC_FOLDER:-not set}"
    echo "───────────────────────────────────────────────────────────────"
} >> "$LOG_FILE" 2>/dev/null

# Performance timing
END_TIME=$(_get_time_ms)
DURATION=$((END_TIME - START_TIME))
echo "[$(date '+%Y-%m-%d %H:%M:%S')] cleanup-adhoc-agent.sh ${DURATION}ms" >> "$HOOKS_DIR/logs/performance.log" 2>/dev/null

exit 0
