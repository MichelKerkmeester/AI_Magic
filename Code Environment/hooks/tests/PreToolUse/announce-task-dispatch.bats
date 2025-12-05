#!/usr/bin/env bats
# ───────────────────────────────────────────────────────────────
# Tests for: announce-task-dispatch.sh
# Type: PreToolUse (informational, never blocks)
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
HOOK_SCRIPT="$REAL_HOOKS_DIR/PreToolUse/announce-task-dispatch.sh"

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
  local model="${2:-sonnet}"
  local subagent_type="${3:-general-purpose}"
  jq -n --arg desc "$description" --arg model "$model" --arg type "$subagent_type" \
    '{name: "Task", tool_input: {description: $desc, model: $model, subagent_type: $type, prompt: "Test prompt"}}'
}

make_tool_input() {
  local tool_name="$1"
  jq -n --arg name "$tool_name" '{name: $name}'
}

# ───────────────────────────────────────────────────────────────
# TASK TOOL PROCESSING
# ───────────────────────────────────────────────────────────────

@test "announce-task-dispatch processes Task tool" {
  local input
  input=$(make_task_input "Explore codebase")

  run bash -c "echo '$input' | bash '$HOOK_SCRIPT'"

  # Always exits 0 (informational)
  [ "$status" -eq 0 ]
}

@test "announce-task-dispatch outputs systemMessage for Task" {
  local input
  input=$(make_task_input "Code review" "opus" "general-purpose")

  run bash -c "echo '$input' | bash '$HOOK_SCRIPT'"

  [ "$status" -eq 0 ]
  # Should output systemMessage JSON
  [[ "$output" == *"systemMessage"* ]] || [[ "$output" == *"DISPATCHED"* ]]
}

@test "announce-task-dispatch handles different models" {
  local input
  input=$(make_task_input "Quick task" "haiku")

  run bash -c "echo '$input' | bash '$HOOK_SCRIPT'"

  [ "$status" -eq 0 ]
}

@test "announce-task-dispatch handles Explore subagent" {
  local input
  input=$(make_task_input "Find files" "sonnet" "Explore")

  run bash -c "echo '$input' | bash '$HOOK_SCRIPT'"

  [ "$status" -eq 0 ]
}

# ───────────────────────────────────────────────────────────────
# NON-TASK TOOLS (ignored)
# ───────────────────────────────────────────────────────────────

@test "announce-task-dispatch ignores Read tool" {
  local input
  input=$(make_tool_input "Read")

  run bash -c "echo '$input' | bash '$HOOK_SCRIPT'"

  [ "$status" -eq 0 ]
  # Should exit silently without output
  [ -z "$output" ] || [[ "$output" != *"DISPATCHED"* ]]
}

@test "announce-task-dispatch ignores Write tool" {
  local input
  input=$(make_tool_input "Write")

  run bash -c "echo '$input' | bash '$HOOK_SCRIPT'"

  [ "$status" -eq 0 ]
}

@test "announce-task-dispatch ignores Bash tool" {
  local input
  input=$(make_tool_input "Bash")

  run bash -c "echo '$input' | bash '$HOOK_SCRIPT'"

  [ "$status" -eq 0 ]
}

# ───────────────────────────────────────────────────────────────
# INPUT HANDLING
# ───────────────────────────────────────────────────────────────

@test "announce-task-dispatch handles empty input" {
  run bash -c "echo '{}' | bash '$HOOK_SCRIPT'"

  [ "$status" -eq 0 ]
}

@test "announce-task-dispatch handles missing description" {
  local input
  input=$(jq -n '{name: "Task", tool_input: {prompt: "test"}}')

  run bash -c "echo '$input' | bash '$HOOK_SCRIPT'"

  [ "$status" -eq 0 ]
}

# ───────────────────────────────────────────────────────────────
# EXIT CODES (always 0)
# ───────────────────────────────────────────────────────────────

@test "announce-task-dispatch always exits 0" {
  local input
  input=$(make_task_input "Any task")

  run bash -c "echo '$input' | bash '$HOOK_SCRIPT'"

  [ "$status" -eq 0 ]
}

@test "announce-task-dispatch never blocks Task execution" {
  local input
  input=$(make_task_input "Complex task with many words in description")

  run bash -c "echo '$input' | bash '$HOOK_SCRIPT'"

  [ "$status" -eq 0 ]
}

# ───────────────────────────────────────────────────────────────
# PERFORMANCE
# ───────────────────────────────────────────────────────────────

@test "announce-task-dispatch completes within 250ms" {
  local start_time end_time duration

  if [[ "$OSTYPE" == "darwin"* ]]; then
    start_time=$(python3 -c 'import time; print(int(time.time() * 1000))')
  else
    start_time=$(date +%s%3N)
  fi

  local input
  input=$(make_task_input "Performance test")
  run bash -c "echo '$input' | bash '$HOOK_SCRIPT'"

  if [[ "$OSTYPE" == "darwin"* ]]; then
    end_time=$(python3 -c 'import time; print(int(time.time() * 1000))')
  else
    end_time=$(date +%s%3N)
  fi

  duration=$((end_time - start_time))
  [ "$duration" -lt 250 ]
}

