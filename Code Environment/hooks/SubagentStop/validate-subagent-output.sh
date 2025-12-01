#!/bin/bash

# ───────────────────────────────────────────────────────────────
# SUB-AGENT OUTPUT VALIDATION HOOK
# ───────────────────────────────────────────────────────────────
# SubagentStop hook that validates sub-agent output quality and
# blocks bad output before it's accepted into the conversation.
#
# VALIDATION CHECKS:
#   1. Failure Detection    - Errors, exceptions, crashes
#   2. Completeness Check   - TODOs, placeholders, unfinished work
#   3. Quality Assessment   - Length, depth, relevance
#   4. Security Scan        - Basic vulnerability patterns
#   5. Task Alignment       - Did agent address the request?
#
# BLOCKING BEHAVIOR:
#   - Score < 40: Block with reason (requires retry or manual review)
#   - Score 40-69: Allow with warnings
#   - Score 70+: Allow (good output)
#
# RETRY LOGIC:
#   - Max 2 retries per agent before giving up
#   - Retry state tracked in /tmp/claude_hooks_state/subagent_retries.json
#   - Retries reset after 1 hour
#
# PERFORMANCE TARGET: <50ms
# EXIT CODE: 0 (decision returned via stdout JSON)
#
# Created: 2025-12-01
# Version: 1.1.0 - Fixed SCORE validation, VALIDATION_MAX_RETRIES fallback, jq JSON escaping
# ───────────────────────────────────────────────────────────────

# Strict mode for reliability
set -euo pipefail

# Script setup
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" 2>/dev/null && pwd)"
HOOKS_DIR="$(cd "$SCRIPT_DIR/.." 2>/dev/null && pwd)"

# Source libraries
source "$HOOKS_DIR/lib/subagent-validation.sh" 2>/dev/null || {
    # If library not found, allow through with warning
    echo '{"systemMessage": "⚠️ Subagent validation library not found - skipping validation"}'
    exit 0
}
source "$HOOKS_DIR/lib/output-helpers.sh" 2>/dev/null || true
source "$HOOKS_DIR/lib/agent-tracking.sh" 2>/dev/null || true

# Logging
LOG_DIR="$HOOKS_DIR/logs"
LOG_FILE="$LOG_DIR/subagent-validation.log"
mkdir -p "$LOG_DIR" 2>/dev/null

# Cross-platform timing
_get_time_ms() {
    if [[ "$OSTYPE" == "darwin"* ]]; then
        echo $(($(date +%s) * 1000))
    else
        date +%s%3N 2>/dev/null || echo $(($(date +%s) * 1000))
    fi
}

START_TIME=$(_get_time_ms)

# ═══════════════════════════════════════════════════════════════
# READ INPUT
# ═══════════════════════════════════════════════════════════════

INPUT=$(cat)

# Extract SubagentStop payload fields
SESSION_ID=$(echo "$INPUT" | jq -r '.session_id // empty' 2>/dev/null)
TRANSCRIPT_PATH=$(echo "$INPUT" | jq -r '.transcript_path // empty' 2>/dev/null)
HOOK_EVENT=$(echo "$INPUT" | jq -r '.hook_event_name // empty' 2>/dev/null)
STOP_HOOK_ACTIVE=$(echo "$INPUT" | jq -r '.stop_hook_active // false' 2>/dev/null)

# Verify this is a SubagentStop event
if [ "$HOOK_EVENT" != "SubagentStop" ]; then
    # Not our event, allow through
    exit 0
fi

# Prevent infinite loops if stop hook is already active
if [ "$STOP_HOOK_ACTIVE" = "true" ]; then
    {
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] SKIP: stop_hook_active=true (preventing loop)"
    } >> "$LOG_FILE" 2>/dev/null
    exit 0
fi

# ═══════════════════════════════════════════════════════════════
# EXTRACT AGENT OUTPUT FROM TRANSCRIPT
# ═══════════════════════════════════════════════════════════════

# Clean up old retry state periodically
cleanup_old_retries 2>/dev/null || true

# Extract the sub-agent's output from transcript
AGENT_OUTPUT=$(extract_subagent_output_from_transcript "$TRANSCRIPT_PATH" 2>/dev/null)

if [ -z "$AGENT_OUTPUT" ]; then
    # Couldn't extract output - allow through with warning
    echo '{"systemMessage": "⚠️ Could not extract subagent output for validation"}'
    {
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] WARN: Could not extract output from $TRANSCRIPT_PATH"
    } >> "$LOG_FILE" 2>/dev/null
    exit 0
fi

# Extract task description for alignment check
TASK_DESCRIPTION=$(extract_task_description_from_transcript "$TRANSCRIPT_PATH" 2>/dev/null)

# Generate agent ID from session for tracking
AGENT_ID="agent_${SESSION_ID:0:8}"

# Detect agent type from output patterns
detect_agent_type() {
    local output="$1"

    if echo "$output" | grep -qiE "files found|search results|codebase exploration"; then
        echo "Explore"
    elif echo "$output" | grep -qiE "implementation plan|step 1|phase 1|approach"; then
        echo "Plan"
    elif echo "$output" | grep -qiE "code review|suggestion|recommend|issue found"; then
        echo "code-reviewer"
    else
        echo "general-purpose"
    fi
}

AGENT_TYPE=$(detect_agent_type "$AGENT_OUTPUT")

# ═══════════════════════════════════════════════════════════════
# VALIDATE OUTPUT
# ═══════════════════════════════════════════════════════════════

# Run full validation
VALIDATION_RESULT=$(validate_subagent_output "$AGENT_OUTPUT" "$TASK_DESCRIPTION" "$AGENT_TYPE" "$AGENT_ID")

# Extract validation fields with safe defaults
SCORE=$(echo "$VALIDATION_RESULT" | jq -r '.score // 100')
# Validate SCORE is a valid integer (default to 100 if not)
[[ "$SCORE" =~ ^[0-9]+$ ]] || SCORE=100
SHOULD_BLOCK=$(echo "$VALIDATION_RESULT" | jq -r '.should_block // false')
BLOCK_REASON=$(echo "$VALIDATION_RESULT" | jq -r '.block_reason // ""')
CAN_RETRY=$(echo "$VALIDATION_RESULT" | jq -r '.can_retry // false')
RETRY_COUNT=$(echo "$VALIDATION_RESULT" | jq -r '.retry_count // 0')
ISSUES=$(echo "$VALIDATION_RESULT" | jq -r '.issues | join(", ") // ""')
WARNINGS=$(echo "$VALIDATION_RESULT" | jq -r '.warnings | join(", ") // ""')

# Get quality label
QUALITY_LABEL=$(get_quality_label "$SCORE")

# ═══════════════════════════════════════════════════════════════
# DECISION LOGIC
# ═══════════════════════════════════════════════════════════════

# Calculate timing
END_TIME=$(_get_time_ms)
DURATION=$((END_TIME - START_TIME))

# Log validation result
{
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] VALIDATION"
    echo "  session=$SESSION_ID"
    echo "  agent_id=$AGENT_ID"
    echo "  agent_type=$AGENT_TYPE"
    echo "  score=$SCORE ($QUALITY_LABEL)"
    echo "  should_block=$SHOULD_BLOCK"
    echo "  block_reason=$BLOCK_REASON"
    echo "  retry_count=$RETRY_COUNT"
    echo "  can_retry=$CAN_RETRY"
    echo "  issues=$ISSUES"
    echo "  warnings=$WARNINGS"
    echo "  output_length=${#AGENT_OUTPUT}"
    echo "  duration=${DURATION}ms"
    echo ""
} >> "$LOG_FILE" 2>/dev/null

# ═══════════════════════════════════════════════════════════════
# OUTPUT DECISION
# ═══════════════════════════════════════════════════════════════

if [ "$SHOULD_BLOCK" = "true" ]; then
    # ─────────────────────────────────────────────────────────
    # BLOCK: Output failed validation
    # ─────────────────────────────────────────────────────────

    # Increment retry count
    NEW_RETRY_COUNT=$(increment_retry_count "$AGENT_ID" 2>/dev/null || echo "$((RETRY_COUNT + 1))")

    # Build detailed block reason
    FULL_REASON="Quality score: $SCORE/100 ($QUALITY_LABEL)"
    [ -n "$BLOCK_REASON" ] && FULL_REASON="$FULL_REASON - $BLOCK_REASON"
    [ -n "$ISSUES" ] && FULL_REASON="$FULL_REASON | Issues: $ISSUES"

    # Add retry guidance (VALIDATION_MAX_RETRIES may come from library, fallback to 2)
    MAX_RETRIES="${VALIDATION_MAX_RETRIES:-2}"
    if [ "$CAN_RETRY" = "true" ]; then
        FULL_REASON="$FULL_REASON | Retry $NEW_RETRY_COUNT/$MAX_RETRIES allowed"
    else
        FULL_REASON="$FULL_REASON | Max retries reached - manual review required"
    fi

    # Truncate reason if too long
    [ ${#FULL_REASON} -gt 500 ] && FULL_REASON="${FULL_REASON:0:497}..."

    # Output blocking decision
    # Note: Using jq to properly escape the reason string
    jq -n \
        --arg reason "$FULL_REASON" \
        '{
            decision: "block",
            reason: $reason,
            systemMessage: ("❌ Sub-agent output blocked: " + $reason)
        }'

    # Log block action
    {
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] BLOCKED agent=$AGENT_ID retry=$NEW_RETRY_COUNT reason=$BLOCK_REASON"
    } >> "$LOG_FILE" 2>/dev/null

elif [ "$SCORE" -lt 70 ]; then
    # ─────────────────────────────────────────────────────────
    # WARN: Output is marginal but allowed
    # ─────────────────────────────────────────────────────────

    WARNING_MSG="⚠️ Sub-agent output quality: $SCORE/100 ($QUALITY_LABEL)"
    [ -n "$WARNINGS" ] && WARNING_MSG="$WARNING_MSG - $WARNINGS"

    # Clear retry count since we're accepting
    clear_retry_count "$AGENT_ID" 2>/dev/null || true

    # Output warning but allow
    jq -n --arg msg "$WARNING_MSG" '{systemMessage: $msg}'

else
    # ─────────────────────────────────────────────────────────
    # ALLOW: Output passed validation
    # ─────────────────────────────────────────────────────────

    # Clear retry count
    clear_retry_count "$AGENT_ID" 2>/dev/null || true

    # Silent success (no output needed)
    # Optionally emit success message for verbose mode
    if [ "$SCORE" -ge 90 ]; then
        jq -n --arg score "$SCORE" --arg label "$QUALITY_LABEL" \
            '{systemMessage: ("✅ Sub-agent output validated: " + $score + "/100 (" + $label + ")")}'
    fi
fi

exit 0
