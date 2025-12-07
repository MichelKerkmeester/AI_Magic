#!/bin/bash

# ───────────────────────────────────────────────────────────────
# DETECT-RESEARCH-NEED.SH - Research Agent Suggestion Hook
# ───────────────────────────────────────────────────────────────
# UserPromptSubmit hook that parses user prompt for research
# indicators and suggests dispatching a research agent.
#
# Version: 1.0.0
# Created: 2025-12-06
# Tasks: T126 (US-014)
# Spec: specs/013-speckit-enhancements-from-repo-reference/
#
# KEYWORDS DETECTED:
#   - "research"
#   - "find examples"
#   - "look up" / "lookup"
#   - "investigate"
#
# BEHAVIOR: Suggests (does NOT auto-dispatch) research agent
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
LOG_FILE="$LOG_DIR/detect-research-need.log"
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

# Extract prompt from JSON
PROMPT=$(echo "$INPUT" | jq -r '.prompt // empty' 2>/dev/null)

# Exit if no prompt
if [[ -z "$PROMPT" ]]; then
    exit 0
fi

# Source adhoc-dispatch library
if [[ ! -f "$HOOKS_DIR/lib/adhoc-dispatch.sh" ]]; then
    exit 0
fi

source "$HOOKS_DIR/lib/adhoc-dispatch.sh" 2>/dev/null || exit 0

# Detect research keywords
KEYWORDS=$(detect_research_keywords "$PROMPT" 2>/dev/null) || true

if [[ -n "$KEYWORDS" ]]; then
    # Extract first 100 chars of prompt for context
    PROMPT_EXCERPT="${PROMPT:0:100}"
    
    # Emit research suggestion (non-blocking)
    emit_research_suggestion "$KEYWORDS" "$PROMPT_EXCERPT"
    
    # Also output detailed context for Claude
    cat << EOCONTEXT

RESEARCH AGENT SUGGESTION (Advisory)
====================================
Detected Keywords: ${KEYWORDS}
Prompt Preview: ${PROMPT_EXCERPT}...

If this requires in-depth research, consider:
  - Use Task tool to dispatch a research agent
  - Description: "Research agent: ${PROMPT_EXCERPT}"
  - Benefits: Parallel execution, focused investigation

This is a suggestion only - proceed with direct handling if preferred.
====================================

EOCONTEXT
    
    # Log detection
    {
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] RESEARCH KEYWORDS DETECTED"
        echo "  Keywords: $KEYWORDS"
        echo "  Prompt: ${PROMPT_EXCERPT}..."
        echo "───────────────────────────────────────────────────────────────"
    } >> "$LOG_FILE" 2>/dev/null
fi

# Performance timing
END_TIME=$(_get_time_ms)
DURATION=$((END_TIME - START_TIME))
echo "[$(date '+%Y-%m-%d %H:%M:%S')] detect-research-need.sh ${DURATION}ms" >> "$HOOKS_DIR/logs/performance.log" 2>/dev/null

# Always allow prompt to proceed
exit 0
