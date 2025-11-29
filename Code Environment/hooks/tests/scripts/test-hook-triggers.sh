#!/bin/bash

# ───────────────────────────────────────────────────────────────
# HOOK TRIGGER TESTING SCRIPT
# ───────────────────────────────────────────────────────────────
# Tests validate-dispatch-requirement.sh and summarize-task-completion.sh
# to verify they trigger correctly after fixes.
#
# Usage:
#   ./test-hook-triggers.sh
#
# Exit codes:
#   0 = All tests passed
#   1 = One or more tests failed
# ───────────────────────────────────────────────────────────────

# Don't exit on error - we test for both success and failure cases
set +e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HOOKS_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "HOOK TRIGGER TEST SUITE"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Clean state
echo "🧹 Cleaning state..."
rm -rf /tmp/claude_hooks_state 2>/dev/null || true
mkdir -p /tmp/claude_hooks_state
rm -f "$HOOKS_DIR/logs/validate-dispatch.log" 2>/dev/null || true
rm -f "$HOOKS_DIR/logs/task-dispatch.log" 2>/dev/null || true

# ───────────────────────────────────────────────────────────────
# TEST 1: validate-dispatch-requirement.sh - No State (Should Allow)
# ───────────────────────────────────────────────────────────────
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "TEST 1: validate-dispatch-requirement.sh (No State)"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

TEST_INPUT='{"tool_name":"Read","tool_input":{"file_path":"/test/file.txt"}}'
RESULT=$(echo "$TEST_INPUT" | "$HOOKS_DIR/PreToolUse/validate-dispatch-requirement.sh" 2>&1)
EXIT_CODE=$?

if [ $EXIT_CODE -eq 0 ]; then
  echo "✅ PASS: Hook allows tool when no pending dispatch"
else
  echo "❌ FAIL: Hook blocked tool when it should allow (exit $EXIT_CODE)"
  exit 1
fi

# Check log
if grep -q "ALLOW.*reason=no_pending_dispatch" "$HOOKS_DIR/logs/validate-dispatch.log" 2>/dev/null; then
  echo "✅ PASS: Log entry created"
else
  echo "⚠️  WARN: No log entry found (may be expected)"
fi
echo ""

# ───────────────────────────────────────────────────────────────
# TEST 2: validate-dispatch-requirement.sh - With State (Should Block)
# ───────────────────────────────────────────────────────────────
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "TEST 2: validate-dispatch-requirement.sh (With State)"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Set pending dispatch state
echo '{"required":true,"complexity":45.5,"domains":3,"agents":3,"timestamp":"2025-11-29T10:00:00Z"}' \
  > /tmp/claude_hooks_state/pending_dispatch.json

TEST_INPUT='{"tool_name":"Edit","tool_input":{"file_path":"/test/file.txt"}}'
RESULT=$(echo "$TEST_INPUT" | "$HOOKS_DIR/PreToolUse/validate-dispatch-requirement.sh" 2>&1)
EXIT_CODE=$?

if [ $EXIT_CODE -eq 1 ]; then
  echo "✅ PASS: Hook blocks non-Task tool when dispatch pending"
else
  echo "❌ FAIL: Hook should block but allowed tool (exit $EXIT_CODE)"
  exit 1
fi

# Check for blocking message
if echo "$RESULT" | grep -q "BLOCKED: Parallel Dispatch Required"; then
  echo "✅ PASS: Blocking message displayed"
else
  echo "❌ FAIL: No blocking message shown"
  exit 1
fi

# Check log
if grep -q "BLOCK.*complexity=45.5.*agents=3" "$HOOKS_DIR/logs/validate-dispatch.log" 2>/dev/null; then
  echo "✅ PASS: Block logged correctly"
else
  echo "⚠️  WARN: Block not logged"
fi
echo ""

# ───────────────────────────────────────────────────────────────
# TEST 3: validate-dispatch-requirement.sh - Task Tool Clears State
# ───────────────────────────────────────────────────────────────
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "TEST 3: validate-dispatch-requirement.sh (Task Tool)"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Ensure state exists
echo '{"required":true,"complexity":45.5,"domains":3,"agents":3,"timestamp":"2025-11-29T10:00:00Z"}' \
  > /tmp/claude_hooks_state/pending_dispatch.json

TEST_INPUT='{"tool_name":"Task","tool_input":{"description":"Test agent"}}'
RESULT=$(echo "$TEST_INPUT" | "$HOOKS_DIR/PreToolUse/validate-dispatch-requirement.sh" 2>&1)
EXIT_CODE=$?

if [ $EXIT_CODE -eq 0 ]; then
  echo "✅ PASS: Task tool allowed through"
else
  echo "❌ FAIL: Task tool should be allowed (exit $EXIT_CODE)"
  exit 1
fi

# Verify state cleared
STATE_AFTER=$(cat /tmp/claude_hooks_state/pending_dispatch.json 2>/dev/null || echo "")
if [ -z "$STATE_AFTER" ]; then
  echo "✅ PASS: pending_dispatch state cleared by Task tool"
else
  echo "⚠️  WARN: State not cleared: $STATE_AFTER"
fi
echo ""

# ───────────────────────────────────────────────────────────────
# TEST 4: announce-task-dispatch.sh + summarize-task-completion.sh
# ───────────────────────────────────────────────────────────────
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "TEST 4: Task Lifecycle (Dispatch + Completion)"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Clean tracking state
rm -f /tmp/claude_hooks_state/agent_tracking.json 2>/dev/null || true
rm -f /tmp/claude_hooks_state/agent_description_map.txt 2>/dev/null || true

# Test dispatch announcement
DISPATCH_INPUT='{"tool_name":"Task","tool_input":{"description":"Test integration hook","model":"sonnet","timeout":300000,"subagent_type":"general-purpose","prompt":"Test task"}}'

DISPATCH_OUTPUT=$(echo "$DISPATCH_INPUT" | "$HOOKS_DIR/PreToolUse/announce-task-dispatch.sh" 2>&1)
DISPATCH_EXIT=$?

if [ $DISPATCH_EXIT -eq 0 ]; then
  echo "✅ PASS: announce-task-dispatch.sh executed"
else
  echo "❌ FAIL: announce-task-dispatch.sh failed (exit $DISPATCH_EXIT)"
  exit 1
fi

# Check dispatch log
if grep -q "DISPATCH.*type=general-purpose" "$HOOKS_DIR/logs/task-dispatch.log" 2>/dev/null; then
  echo "✅ PASS: Dispatch logged"
else
  echo "❌ FAIL: Dispatch not logged"
  exit 1
fi

# Check agent tracking state created
if [ -f /tmp/claude_hooks_state/agent_tracking.json ]; then
  AGENT_COUNT=$(jq -r '.session_count // 0' /tmp/claude_hooks_state/agent_tracking.json 2>/dev/null)
  if [ "$AGENT_COUNT" -gt 0 ]; then
    echo "✅ PASS: Agent tracking state created (count=$AGENT_COUNT)"
  else
    echo "⚠️  WARN: Agent tracking state exists but count is 0"
  fi
else
  echo "❌ FAIL: Agent tracking state not created"
  exit 1
fi

# Sleep briefly to simulate agent execution
sleep 0.2

# Test completion summary
COMPLETION_INPUT='{"tool_name":"Task","tool_input":{"description":"Test integration hook","model":"sonnet"},"tool_output":"Task completed successfully with integration test results."}'

COMPLETION_OUTPUT=$(echo "$COMPLETION_INPUT" | "$HOOKS_DIR/PostToolUse/summarize-task-completion.sh" 2>&1)
COMPLETION_EXIT=$?

if [ $COMPLETION_EXIT -eq 0 ]; then
  echo "✅ PASS: summarize-task-completion.sh executed"
else
  echo "❌ FAIL: summarize-task-completion.sh failed (exit $COMPLETION_EXIT)"
  exit 1
fi

# Check completion log
if grep -q "COMPLETE.*status=success" "$HOOKS_DIR/logs/task-dispatch.log" 2>/dev/null; then
  echo "✅ PASS: Completion logged"
else
  echo "❌ FAIL: Completion not logged"
  exit 1
fi

# Check if duration was calculated (look for non-? duration)
LAST_COMPLETE=$(grep "COMPLETE" "$HOOKS_DIR/logs/task-dispatch.log" 2>/dev/null | tail -1)
if echo "$LAST_COMPLETE" | grep -qE "duration=[0-9]+\.[0-9]+s"; then
  echo "✅ PASS: Duration calculated successfully"
  DURATION=$(echo "$LAST_COMPLETE" | grep -oE "duration=[0-9]+\.[0-9]+s" | cut -d= -f2)
  echo "   Duration: $DURATION"
elif echo "$LAST_COMPLETE" | grep -q "duration=?s"; then
  echo "⚠️  WARN: Duration calculation failed (shows ?s)"
  echo "   This may indicate agent_tracking.json corruption"
  # Check error log
  if [ -f /tmp/claude_hooks_state/agent_tracking_errors.log ]; then
    echo "   Errors found:"
    tail -3 /tmp/claude_hooks_state/agent_tracking_errors.log
  fi
else
  echo "⚠️  WARN: Could not parse duration from log"
fi
echo ""

# ───────────────────────────────────────────────────────────────
# SUMMARY
# ───────────────────────────────────────────────────────────────
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "TEST SUMMARY"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

echo ""
echo "Log files created:"
echo "  - $HOOKS_DIR/logs/validate-dispatch.log"
echo "  - $HOOKS_DIR/logs/task-dispatch.log"
echo ""
echo "State files:"
ls -lh /tmp/claude_hooks_state/*.json 2>/dev/null || echo "  (none)"
echo ""
echo "✅ ALL TESTS PASSED"
echo ""
