#!/bin/bash

# ───────────────────────────────────────────────────────────────
# TRACK-TEST-FAILURES.SH - Test Specialist Suggestion Hook
# ───────────────────────────────────────────────────────────────
# PostToolUse hook that tracks test command failures and suggests
# dispatching a test specialist after consecutive failures.
#
# Version: 1.0.0
# Created: 2025-12-06
# Tasks: T127 (US-014)
# Spec: specs/013-speckit-enhancements-from-repo-reference/
#
# TEST PATTERNS DETECTED:
#   - npm test / npm run test
#   - pytest / py.test
#   - jest
#   - bats
#   - mocha
#   - vitest
#   - go test
#   - cargo test
#
# THRESHOLD: 2 consecutive failures
# BEHAVIOR: Suggests (does NOT auto-dispatch) test specialist
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
LOG_FILE="$LOG_DIR/track-test-failures.log"
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

# Source adhoc-dispatch library
if [[ ! -f "$HOOKS_DIR/lib/adhoc-dispatch.sh" ]]; then
    exit 0
fi

source "$HOOKS_DIR/lib/adhoc-dispatch.sh" 2>/dev/null || exit 0

# Check if this is a test command
FRAMEWORK=$(is_test_command "$COMMAND" 2>/dev/null) || true

if [[ -z "$FRAMEWORK" ]]; then
    # Not a test command, skip
    exit 0
fi

# Check exit code
if [[ "$EXIT_CODE" == "0" || -z "$EXIT_CODE" ]]; then
    # Test passed - clear consecutive failure count
    clear_test_failures 2>/dev/null || true
    
    {
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] Test passed: $FRAMEWORK - counter cleared"
    } >> "$LOG_FILE" 2>/dev/null
    
    exit 0
fi

# Test failed - track it
track_test_failure "$COMMAND" "$FRAMEWORK" "$OUTPUT_SNIPPET"

# Check if threshold reached
if should_suggest_test_specialist; then
    FAILURE_COUNT=$(get_test_failure_count)
    
    # Emit test specialist suggestion
    emit_test_specialist_suggestion "$FRAMEWORK"
    
    # Output detailed context for Claude
    cat << EOCONTEXT

TEST SPECIALIST SUGGESTION
==========================
Consecutive Failures: ${FAILURE_COUNT} (threshold: ${TEST_FAILURE_THRESHOLD:-2})
Framework: ${FRAMEWORK}
Command: ${COMMAND:0:80}
Error Preview: ${OUTPUT_SNIPPET:0:150}

RECOMMENDED ACTION:
Use the Task tool to dispatch a test specialist:
  - Description: "Test specialist: Fix failing ${FRAMEWORK} tests"
  - Include test output and relevant source files
  - Agent capabilities: write_tests, run_tests, analyze_coverage, read_files, edit_files

After tests pass, failure counter will be cleared.
==========================

EOCONTEXT
    
    # Log suggestion event
    {
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] TEST SPECIALIST SUGGESTED"
        echo "  Failure Count: $FAILURE_COUNT"
        echo "  Framework: $FRAMEWORK"
        echo "  Command: $COMMAND"
        echo "───────────────────────────────────────────────────────────────"
    } >> "$LOG_FILE" 2>/dev/null
else
    CURRENT_COUNT=$(get_test_failure_count)
    THRESHOLD="${TEST_FAILURE_THRESHOLD:-2}"
    
    {
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] Test failure tracked: $CURRENT_COUNT/$THRESHOLD ($FRAMEWORK)"
    } >> "$LOG_FILE" 2>/dev/null
fi

# Performance timing
END_TIME=$(_get_time_ms)
DURATION=$((END_TIME - START_TIME))
echo "[$(date '+%Y-%m-%d %H:%M:%S')] track-test-failures.sh ${DURATION}ms" >> "$HOOKS_DIR/logs/performance.log" 2>/dev/null

exit 0
