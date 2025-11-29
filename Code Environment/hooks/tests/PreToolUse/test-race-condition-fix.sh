#!/bin/bash

# ───────────────────────────────────────────────────────────────
# TEST: Race Condition Fix for check-pending-questions.sh
# ───────────────────────────────────────────────────────────────
# This script tests the atomic check-and-block logic to ensure
# the TOCTOU race condition is fixed.
#
# Created: 2025-11-29
# ───────────────────────────────────────────────────────────────

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" 2>/dev/null && pwd)"
HOOKS_DIR="$(cd "$SCRIPT_DIR/../.." 2>/dev/null && pwd)"
TEST_SCRIPT="$HOOKS_DIR/PreToolUse/check-pending-questions.sh"

# Source required libraries
source "$HOOKS_DIR/lib/shared-state.sh" 2>/dev/null || {
  echo "❌ FAILED: Cannot load shared-state.sh"
  exit 1
}

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🧪 TESTING: Race Condition Fix for check-pending-questions.sh"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Clean up any existing state
clear_hook_state "pending_question" 2>/dev/null || true
clear_hook_state "question_violations" 2>/dev/null || true

# ───────────────────────────────────────────────────────────────
# TEST 1: Normal Flow - No Pending Question
# ───────────────────────────────────────────────────────────────
echo "Test 1: Normal Flow - No Pending Question"
echo "─────────────────────────────────────────"

INPUT='{"name":"Read","parameters":{"file_path":"/tmp/test.txt"}}'
RESULT=$(echo "$INPUT" | bash "$TEST_SCRIPT" 2>&1)
EXIT_CODE=$?

if [ "$EXIT_CODE" -eq 0 ]; then
  echo -e "${GREEN}✓ PASS${NC} - Read tool allowed (no pending question)"
else
  echo -e "${RED}✗ FAIL${NC} - Read tool blocked (exit code: $EXIT_CODE)"
  echo "Output: $RESULT"
fi
echo ""

# ───────────────────────────────────────────────────────────────
# TEST 2: Pending Question - Block Other Tools
# ───────────────────────────────────────────────────────────────
echo "Test 2: Pending Question - Block Other Tools"
echo "─────────────────────────────────────────────"

# Create a pending question
TIMESTAMP=$(date +%s)
QUESTION_JSON=$(jq -n \
  --arg type "MANDATORY" \
  --arg question "Which library should we use?" \
  --arg timestamp "$TIMESTAMP" \
  '{type: $type, question: $question, timestamp: ($timestamp | tonumber), asked_at: now}')

write_hook_state "pending_question" "$QUESTION_JSON" 2>/dev/null

# Try to use Read tool (should be blocked)
INPUT='{"name":"Read","parameters":{"file_path":"/tmp/test.txt"}}'
RESULT=$(echo "$INPUT" | bash "$TEST_SCRIPT" 2>&1)
EXIT_CODE=$?

if [ "$EXIT_CODE" -eq 1 ]; then
  echo -e "${GREEN}✓ PASS${NC} - Read tool blocked (pending question exists)"
else
  echo -e "${RED}✗ FAIL${NC} - Read tool allowed (exit code: $EXIT_CODE)"
  echo "Output: $RESULT"
fi

# Check if blocking message is shown
if echo "$RESULT" | grep -q "MANDATORY USER QUESTION PENDING"; then
  echo -e "${GREEN}✓ PASS${NC} - Blocking message displayed"
else
  echo -e "${RED}✗ FAIL${NC} - Blocking message not displayed"
fi

# Check violation count
if echo "$RESULT" | grep -q "Violation count: 1"; then
  echo -e "${GREEN}✓ PASS${NC} - Violation count tracked correctly"
else
  echo -e "${RED}✗ FAIL${NC} - Violation count not tracked"
fi
echo ""

# ───────────────────────────────────────────────────────────────
# TEST 3: AskUserQuestion - Always Allowed
# ───────────────────────────────────────────────────────────────
echo "Test 3: AskUserQuestion - Always Allowed"
echo "─────────────────────────────────────────"

# Try to use AskUserQuestion (should be allowed and clear state)
INPUT='{"name":"AskUserQuestion","parameters":{"questions":[]}}'
RESULT=$(echo "$INPUT" | bash "$TEST_SCRIPT" 2>&1)
EXIT_CODE=$?

if [ "$EXIT_CODE" -eq 0 ]; then
  echo -e "${GREEN}✓ PASS${NC} - AskUserQuestion allowed"
else
  echo -e "${RED}✗ FAIL${NC} - AskUserQuestion blocked (exit code: $EXIT_CODE)"
  echo "Output: $RESULT"
fi

# Check if pending question was cleared
if ! has_hook_state "pending_question" 300 2>/dev/null; then
  echo -e "${GREEN}✓ PASS${NC} - Pending question cleared"
else
  echo -e "${RED}✗ FAIL${NC} - Pending question not cleared"
fi

# Check if violations were cleared
if ! has_hook_state "question_violations" 600 2>/dev/null; then
  echo -e "${GREEN}✓ PASS${NC} - Violations cleared"
else
  echo -e "${RED}✗ FAIL${NC} - Violations not cleared"
fi
echo ""

# ───────────────────────────────────────────────────────────────
# TEST 4: After Answer - Tools Allowed Again
# ───────────────────────────────────────────────────────────────
echo "Test 4: After Answer - Tools Allowed Again"
echo "───────────────────────────────────────────"

# Try to use Read tool again (should be allowed now)
INPUT='{"name":"Read","parameters":{"file_path":"/tmp/test.txt"}}'
RESULT=$(echo "$INPUT" | bash "$TEST_SCRIPT" 2>&1)
EXIT_CODE=$?

if [ "$EXIT_CODE" -eq 0 ]; then
  echo -e "${GREEN}✓ PASS${NC} - Read tool allowed (question answered)"
else
  echo -e "${RED}✗ FAIL${NC} - Read tool blocked (exit code: $EXIT_CODE)"
  echo "Output: $RESULT"
fi
echo ""

# ───────────────────────────────────────────────────────────────
# TEST 5: Expired Question - Auto-Clear
# ───────────────────────────────────────────────────────────────
echo "Test 5: Expired Question - Auto-Clear"
echo "──────────────────────────────────────"

# Create an expired question (timestamp 400 seconds ago, expiry is 300)
EXPIRED_TIMESTAMP=$(($(date +%s) - 400))
QUESTION_JSON=$(jq -n \
  --arg type "MANDATORY" \
  --arg question "Expired question" \
  --arg timestamp "$EXPIRED_TIMESTAMP" \
  '{type: $type, question: $question, timestamp: ($timestamp | tonumber), asked_at: now}')

write_hook_state "pending_question" "$QUESTION_JSON" 2>/dev/null

# Try to use Read tool (should be allowed, expired question cleared)
INPUT='{"name":"Read","parameters":{"file_path":"/tmp/test.txt"}}'
RESULT=$(echo "$INPUT" | bash "$TEST_SCRIPT" 2>&1)
EXIT_CODE=$?

if [ "$EXIT_CODE" -eq 0 ]; then
  echo -e "${GREEN}✓ PASS${NC} - Read tool allowed (expired question)"
else
  echo -e "${RED}✗ FAIL${NC} - Read tool blocked (exit code: $EXIT_CODE)"
  echo "Output: $RESULT"
fi

# Check if expired question was cleared
if ! has_hook_state "pending_question" 300 2>/dev/null; then
  echo -e "${GREEN}✓ PASS${NC} - Expired question auto-cleared"
else
  echo -e "${RED}✗ FAIL${NC} - Expired question not cleared"
fi
echo ""

# ───────────────────────────────────────────────────────────────
# TEST 6: Invalid JSON - Auto-Clear
# ───────────────────────────────────────────────────────────────
echo "Test 6: Invalid JSON - Auto-Clear"
echo "──────────────────────────────────"

# Create invalid JSON state
echo "invalid json {{{" > "/tmp/claude_hooks_state/pending_question.json" 2>/dev/null

# Try to use Read tool (should be allowed, invalid JSON cleared)
INPUT='{"name":"Read","parameters":{"file_path":"/tmp/test.txt"}}'
RESULT=$(echo "$INPUT" | bash "$TEST_SCRIPT" 2>&1)
EXIT_CODE=$?

if [ "$EXIT_CODE" -eq 0 ]; then
  echo -e "${GREEN}✓ PASS${NC} - Read tool allowed (invalid JSON)"
else
  echo -e "${RED}✗ FAIL${NC} - Read tool blocked (exit code: $EXIT_CODE)"
  echo "Output: $RESULT"
fi
echo ""

# Clean up
clear_hook_state "pending_question" 2>/dev/null || true
clear_hook_state "question_violations" 2>/dev/null || true

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✅ Test Suite Complete"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
