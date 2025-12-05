#!/usr/bin/env bats
# ───────────────────────────────────────────────────────────────
# Tests for: check-pending-questions.sh
# Type: PreToolUse (BLOCKING)
# ───────────────────────────────────────────────────────────────
# Spec: 010-comprehensive-hook-testing
# Created: 2025-12-03
# Tests: 12
# ───────────────────────────────────────────────────────────────

load '../test_helper'

# ───────────────────────────────────────────────────────────────
# CONSTANTS
# ───────────────────────────────────────────────────────────────

REAL_HOOKS_DIR="$(cd "$BATS_TEST_DIRNAME/../.." && pwd)"
HOOK_SCRIPT="$REAL_HOOKS_DIR/PreToolUse/check-pending-questions.sh"

# ───────────────────────────────────────────────────────────────
# SETUP / TEARDOWN
# ───────────────────────────────────────────────────────────────

setup() {
  TEST_TMP_DIR=$(mktemp -d "${TMPDIR:-/tmp}/bats_test.XXXXXX")
  mkdir -p "$TEST_TMP_DIR/state"

  # Set up state directory for session isolation
  export HOOK_STATE_DIR="$TEST_TMP_DIR/state"
  export CLAUDE_SESSION_ID="bats-test-$$-$(date +%s)-$RANDOM"
}

teardown() {
  [ -n "$TEST_TMP_DIR" ] && [ -d "$TEST_TMP_DIR" ] && rm -rf "$TEST_TMP_DIR"
}

# ───────────────────────────────────────────────────────────────
# HELPERS
# ───────────────────────────────────────────────────────────────

make_tool_input() {
  local tool_name="$1"
  jq -n --arg name "$tool_name" '{name: $name}'
}

set_pending_question() {
  # Source shared-state library to use the proper state API
  source "$REAL_HOOKS_DIR/lib/shared-state.sh" 2>/dev/null || return 1

  # Create proper state JSON with timestamp (required for expiry checks)
  local timestamp=$(date +%s)
  local state_json=$(jq -n \
    --arg ts "$timestamp" \
    --arg type "mandatory" \
    --arg question "Test question" \
    --arg asked_at "$(date '+%Y-%m-%d %H:%M:%S')" \
    '{timestamp: ($ts | tonumber), type: $type, question: $question, asked_at: $asked_at}')

  write_hook_state "pending_question" "$state_json"
}

# ───────────────────────────────────────────────────────────────
# BLOCKING BEHAVIOR
# ───────────────────────────────────────────────────────────────

@test "check-pending-questions blocks all tools when question pending" {
  set_pending_question

  local input
  input=$(make_tool_input "Read")

  run bash -c "echo '$input' | bash '$HOOK_SCRIPT'"

  [ "$status" -eq 1 ]
}

@test "check-pending-questions blocks Bash when question pending" {
  set_pending_question

  local input
  input=$(make_tool_input "Bash")

  run bash -c "echo '$input' | bash '$HOOK_SCRIPT'"

  [ "$status" -eq 1 ]
}

@test "check-pending-questions blocks Write when question pending" {
  set_pending_question

  local input
  input=$(make_tool_input "Write")

  run bash -c "echo '$input' | bash '$HOOK_SCRIPT'"

  [ "$status" -eq 1 ]
}

# ───────────────────────────────────────────────────────────────
# ASKUSERQUESTION EXCEPTION
# ───────────────────────────────────────────────────────────────

@test "check-pending-questions allows AskUserQuestion" {
  set_pending_question

  local input
  input=$(make_tool_input "AskUserQuestion")

  run bash -c "echo '$input' | bash '$HOOK_SCRIPT'"

  [ "$status" -eq 0 ]
}

# ───────────────────────────────────────────────────────────────
# NO PENDING QUESTION
# ───────────────────────────────────────────────────────────────

@test "check-pending-questions exits with 0 when no question" {
  # No pending question set
  local input
  input=$(make_tool_input "Read")

  run bash -c "echo '$input' | bash '$HOOK_SCRIPT'"

  [ "$status" -eq 0 ]
}

@test "check-pending-questions allows Bash when no question" {
  local input
  input=$(make_tool_input "Bash")

  run bash -c "echo '$input' | bash '$HOOK_SCRIPT'"

  [ "$status" -eq 0 ]
}

# ───────────────────────────────────────────────────────────────
# EDGE CASES
# ───────────────────────────────────────────────────────────────

@test "check-pending-questions handles missing signal state" {
  # Ensure no state exists
  rm -rf "$HOOK_STATE_DIR"/*

  local input
  input=$(make_tool_input "Read")

  run bash -c "echo '$input' | bash '$HOOK_SCRIPT'"

  [ "$status" -eq 0 ]
}

@test "check-pending-questions handles empty input" {
  run bash -c "echo '{}' | bash '$HOOK_SCRIPT'"

  [ "$status" -eq 0 ]
}

@test "check-pending-questions handles missing tool name" {
  run bash -c "echo '{\"input\": {}}' | bash '$HOOK_SCRIPT'"

  [ "$status" -eq 0 ]
}

# ───────────────────────────────────────────────────────────────
# EXIT CODES
# ───────────────────────────────────────────────────────────────

@test "check-pending-questions exits with 1 when blocking" {
  set_pending_question

  local input
  input=$(make_tool_input "Task")

  run bash -c "echo '$input' | bash '$HOOK_SCRIPT'"

  [ "$status" -eq 1 ]
}

# ───────────────────────────────────────────────────────────────
# PERFORMANCE
# ───────────────────────────────────────────────────────────────

@test "check-pending-questions completes within 150ms" {
  local start_time end_time duration

  if [[ "$OSTYPE" == "darwin"* ]]; then
    start_time=$(python3 -c 'import time; print(int(time.time() * 1000))')
  else
    start_time=$(date +%s%3N)
  fi

  local input
  input=$(make_tool_input "Read")
  run bash -c "echo '$input' | bash '$HOOK_SCRIPT'"

  if [[ "$OSTYPE" == "darwin"* ]]; then
    end_time=$(python3 -c 'import time; print(int(time.time() * 1000))')
  else
    end_time=$(date +%s%3N)
  fi

  duration=$((end_time - start_time))
  [ "$duration" -lt 150 ]
}
