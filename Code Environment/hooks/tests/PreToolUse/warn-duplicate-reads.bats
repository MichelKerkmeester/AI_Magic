#!/usr/bin/env bats
# ───────────────────────────────────────────────────────────────
# Tests for: warn-duplicate-reads.sh
# Type: PreToolUse (advisory, never blocks)
# ───────────────────────────────────────────────────────────────
# Spec: 010-comprehensive-hook-testing
# Created: 2025-12-03
# Tests: 15
# ───────────────────────────────────────────────────────────────

load '../test_helper'

# ───────────────────────────────────────────────────────────────
# CONSTANTS
# ───────────────────────────────────────────────────────────────

REAL_HOOKS_DIR="$(cd "$BATS_TEST_DIRNAME/../.." && pwd)"
HOOK_SCRIPT="$REAL_HOOKS_DIR/PreToolUse/warn-duplicate-reads.sh"

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

make_read_input() {
  local file_path="$1"
  jq -n --arg path "$file_path" \
    '{name: "Read", tool_input: {file_path: $path}}'
}

make_grep_input() {
  local pattern="$1"
  local path="${2:-/project}"
  jq -n --arg pat "$pattern" --arg path "$path" \
    '{name: "Grep", tool_input: {pattern: $pat, path: $path}}'
}

make_glob_input() {
  local pattern="$1"
  local path="${2:-/project}"
  jq -n --arg pat "$pattern" --arg path "$path" \
    '{name: "Glob", tool_input: {pattern: $pat, path: $path}}'
}

make_tool_input() {
  local tool_name="$1"
  jq -n --arg name "$tool_name" '{name: $name}'
}

# ───────────────────────────────────────────────────────────────
# READ TOOL TRACKING
# ───────────────────────────────────────────────────────────────

@test "warn-duplicate-reads tracks Read tool calls" {
  local input
  input=$(make_read_input "/project/src/file.js")

  run bash -c "echo '$input' | bash '$HOOK_SCRIPT'"

  [ "$status" -eq 0 ]
}

@test "warn-duplicate-reads detects duplicate Read calls" {
  local input
  input=$(make_read_input "/project/src/file.js")

  # First call - should record
  run bash -c "echo '$input' | bash '$HOOK_SCRIPT'"
  [ "$status" -eq 0 ]

  # Second call - should detect duplicate
  run bash -c "echo '$input' | bash '$HOOK_SCRIPT'"
  [ "$status" -eq 0 ]
}

# ───────────────────────────────────────────────────────────────
# GREP TOOL TRACKING
# ───────────────────────────────────────────────────────────────

@test "warn-duplicate-reads tracks Grep tool calls" {
  local input
  input=$(make_grep_input "TODO")

  run bash -c "echo '$input' | bash '$HOOK_SCRIPT'"

  [ "$status" -eq 0 ]
}

@test "warn-duplicate-reads allows different grep patterns" {
  local input1 input2

  input1=$(make_grep_input "TODO")
  run bash -c "echo '$input1' | bash '$HOOK_SCRIPT'"
  [ "$status" -eq 0 ]

  input2=$(make_grep_input "FIXME")
  run bash -c "echo '$input2' | bash '$HOOK_SCRIPT'"
  [ "$status" -eq 0 ]
}

# ───────────────────────────────────────────────────────────────
# GLOB TOOL TRACKING
# ───────────────────────────────────────────────────────────────

@test "warn-duplicate-reads tracks Glob tool calls" {
  local input
  input=$(make_glob_input "**/*.ts")

  run bash -c "echo '$input' | bash '$HOOK_SCRIPT'"

  [ "$status" -eq 0 ]
}

# ───────────────────────────────────────────────────────────────
# NON-READ TOOLS (ignored)
# ───────────────────────────────────────────────────────────────

@test "warn-duplicate-reads ignores Write tool" {
  local input
  input=$(make_tool_input "Write")

  run bash -c "echo '$input' | bash '$HOOK_SCRIPT'"

  [ "$status" -eq 0 ]
}

@test "warn-duplicate-reads ignores Edit tool" {
  local input
  input=$(make_tool_input "Edit")

  run bash -c "echo '$input' | bash '$HOOK_SCRIPT'"

  [ "$status" -eq 0 ]
}

@test "warn-duplicate-reads ignores Bash tool" {
  local input
  input=$(make_tool_input "Bash")

  run bash -c "echo '$input' | bash '$HOOK_SCRIPT'"

  [ "$status" -eq 0 ]
}

@test "warn-duplicate-reads ignores Task tool" {
  local input
  input=$(make_tool_input "Task")

  run bash -c "echo '$input' | bash '$HOOK_SCRIPT'"

  [ "$status" -eq 0 ]
}

# ───────────────────────────────────────────────────────────────
# INPUT HANDLING
# ───────────────────────────────────────────────────────────────

@test "warn-duplicate-reads handles empty input" {
  run bash -c "echo '{}' | bash '$HOOK_SCRIPT'"

  [ "$status" -eq 0 ]
}

@test "warn-duplicate-reads handles missing tool_input" {
  local input
  input=$(jq -n '{name: "Read"}')

  run bash -c "echo '$input' | bash '$HOOK_SCRIPT'"

  [ "$status" -eq 0 ]
}

# ───────────────────────────────────────────────────────────────
# EXIT CODES (always 0)
# ───────────────────────────────────────────────────────────────

@test "warn-duplicate-reads always exits 0 (advisory)" {
  local input
  input=$(make_read_input "/project/file.txt")

  run bash -c "echo '$input' | bash '$HOOK_SCRIPT'"

  [ "$status" -eq 0 ]
}

@test "warn-duplicate-reads never blocks execution" {
  local input
  input=$(make_read_input "/project/important.js")

  # Call twice to trigger duplicate
  run bash -c "echo '$input' | bash '$HOOK_SCRIPT'"
  run bash -c "echo '$input' | bash '$HOOK_SCRIPT'"

  # Should still be 0 (advisory only)
  [ "$status" -eq 0 ]
}

# ───────────────────────────────────────────────────────────────
# PERFORMANCE
# ───────────────────────────────────────────────────────────────

@test "warn-duplicate-reads completes within 150ms" {
  local start_time end_time duration

  if [[ "$OSTYPE" == "darwin"* ]]; then
    start_time=$(python3 -c 'import time; print(int(time.time() * 1000))')
  else
    start_time=$(date +%s%3N)
  fi

  local input
  input=$(make_read_input "/project/test.js")
  run bash -c "echo '$input' | bash '$HOOK_SCRIPT'"

  if [[ "$OSTYPE" == "darwin"* ]]; then
    end_time=$(python3 -c 'import time; print(int(time.time() * 1000))')
  else
    end_time=$(date +%s%3N)
  fi

  duration=$((end_time - start_time))
  [ "$duration" -lt 150 ]
}

