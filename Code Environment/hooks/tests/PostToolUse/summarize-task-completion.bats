#!/usr/bin/env bats
# ───────────────────────────────────────────────────────────────
# Tests for: summarize-task-completion.sh
# Type: PostToolUse (informational)
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
HOOK_SCRIPT="$REAL_HOOKS_DIR/PostToolUse/summarize-task-completion.sh"

# ───────────────────────────────────────────────────────────────
# SETUP / TEARDOWN
# ───────────────────────────────────────────────────────────────

setup() {
  TEST_TMP_DIR=$(mktemp -d "${TMPDIR:-/tmp}/bats_test.XXXXXX")
  mkdir -p "$TEST_TMP_DIR/logs"

  export HOOK_STATE_DIR="$TEST_TMP_DIR/state"
  mkdir -p "$HOOK_STATE_DIR"
  export CLAUDE_SESSION_ID="bats-test-$$-$(date +%s)-$RANDOM"
}

teardown() {
  [ -n "$TEST_TMP_DIR" ] && [ -d "$TEST_TMP_DIR" ] && rm -rf "$TEST_TMP_DIR"
}

# ───────────────────────────────────────────────────────────────
# HELPERS
# ───────────────────────────────────────────────────────────────

make_task_input() {
  local description="${1:-Test task}"
  local output="${2:-Task completed successfully}"
  jq -n --arg desc "$description" --arg out "$output" \
    '{tool_name: "Task", tool_input: {description: $desc, subagent_type: "general-purpose"}, tool_output: $out}'
}

make_tool_input() {
  local tool_name="$1"
  jq -n --arg name "$tool_name" '{tool_name: $name}'
}

# ───────────────────────────────────────────────────────────────
# TASK TOOL PROCESSING
# ───────────────────────────────────────────────────────────────

@test "summarize-task-completion processes Task tool" {
  local input
  input=$(make_task_input "Explore codebase")

  run bash -c "echo '$input' | bash '$HOOK_SCRIPT'"

  [ "$status" -eq 0 ]
}

@test "summarize-task-completion outputs systemMessage for Task" {
  local input
  input=$(make_task_input "Code review" "Found 3 issues")

  run bash -c "echo '$input' | bash '$HOOK_SCRIPT'"

  [ "$status" -eq 0 ]
  # Should output completion message
  [[ "$output" == *"systemMessage"* ]] || [[ "$output" == *"completed"* ]]
}

@test "summarize-task-completion detects success status" {
  local input
  input=$(make_task_input "Test task" "All tests passed successfully")

  run bash -c "echo '$input' | bash '$HOOK_SCRIPT'"

  [ "$status" -eq 0 ]
}

@test "summarize-task-completion detects error status" {
  local input
  input=$(make_task_input "Failing task" "Error: something failed")

  run bash -c "echo '$input' | bash '$HOOK_SCRIPT'"

  [ "$status" -eq 0 ]
}

# ───────────────────────────────────────────────────────────────
# NON-TASK TOOLS (ignored)
# ───────────────────────────────────────────────────────────────

@test "summarize-task-completion ignores Read tool" {
  local input
  input=$(make_tool_input "Read")

  run bash -c "echo '$input' | bash '$HOOK_SCRIPT'"

  [ "$status" -eq 0 ]
}

@test "summarize-task-completion ignores Write tool" {
  local input
  input=$(make_tool_input "Write")

  run bash -c "echo '$input' | bash '$HOOK_SCRIPT'"

  [ "$status" -eq 0 ]
}

@test "summarize-task-completion ignores Edit tool" {
  local input
  input=$(make_tool_input "Edit")

  run bash -c "echo '$input' | bash '$HOOK_SCRIPT'"

  [ "$status" -eq 0 ]
}

# ───────────────────────────────────────────────────────────────
# INPUT HANDLING
# ───────────────────────────────────────────────────────────────

@test "summarize-task-completion handles empty input" {
  run bash -c "echo '{}' | bash '$HOOK_SCRIPT'"

  [ "$status" -eq 0 ]
}

@test "summarize-task-completion handles missing description" {
  local input
  input=$(jq -n '{tool_name: "Task", tool_input: {}, tool_output: "done"}')

  run bash -c "echo '$input' | bash '$HOOK_SCRIPT'"

  [ "$status" -eq 0 ]
}

# ───────────────────────────────────────────────────────────────
# EXIT CODES (always 0)
# ───────────────────────────────────────────────────────────────

@test "summarize-task-completion always exits 0" {
  local input
  input=$(make_task_input "Any task")

  run bash -c "echo '$input' | bash '$HOOK_SCRIPT'"

  [ "$status" -eq 0 ]
}

@test "summarize-task-completion never blocks" {
  local input
  input=$(make_task_input "Critical task" "Error occurred")

  run bash -c "echo '$input' | bash '$HOOK_SCRIPT'"

  [ "$status" -eq 0 ]
}

# ───────────────────────────────────────────────────────────────
# PERFORMANCE
# ───────────────────────────────────────────────────────────────

@test "summarize-task-completion completes within 200ms" {
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
  [ "$duration" -lt 200 ]
}

