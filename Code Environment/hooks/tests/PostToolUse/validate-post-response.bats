#!/usr/bin/env bats
# ───────────────────────────────────────────────────────────────
# Tests for: validate-post-response.sh
# Type: PostToolUse (advisory)
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
HOOK_SCRIPT="$REAL_HOOKS_DIR/PostToolUse/validate-post-response.sh"

# ───────────────────────────────────────────────────────────────
# SETUP / TEARDOWN
# ───────────────────────────────────────────────────────────────

setup() {
  TEST_TMP_DIR=$(mktemp -d "${TMPDIR:-/tmp}/bats_test.XXXXXX")
  mkdir -p "$TEST_TMP_DIR/logs"
}

teardown() {
  [ -n "$TEST_TMP_DIR" ] && [ -d "$TEST_TMP_DIR" ] && rm -rf "$TEST_TMP_DIR"
}

# ───────────────────────────────────────────────────────────────
# HELPERS
# ───────────────────────────────────────────────────────────────

make_edit_input() {
  local file_path="$1"
  jq -n --arg path "$file_path" \
    '{tool_name: "Edit", tool_input: {file_path: $path}}'
}

make_write_input() {
  local file_path="$1"
  jq -n --arg path "$file_path" \
    '{tool_name: "Write", tool_input: {file_path: $path}}'
}

# ───────────────────────────────────────────────────────────────
# FILE EDITING TOOLS
# ───────────────────────────────────────────────────────────────

@test "validate-post-response processes Edit tool" {
  local input
  input=$(make_edit_input "/project/src/file.js")

  run bash -c "echo '$input' | bash '$HOOK_SCRIPT'"

  [ "$status" -eq 0 ]
}

@test "validate-post-response processes Write tool" {
  local input
  input=$(make_write_input "/project/src/module.ts")

  run bash -c "echo '$input' | bash '$HOOK_SCRIPT'"

  [ "$status" -eq 0 ]
}

@test "validate-post-response processes NotebookEdit tool" {
  local input
  input=$(jq -n '{tool_name: "NotebookEdit", tool_input: {notebook_path: "/project/notebook.ipynb"}}')

  run bash -c "echo '$input' | bash '$HOOK_SCRIPT'"

  [ "$status" -eq 0 ]
}

# ───────────────────────────────────────────────────────────────
# NON-EDITING TOOLS (ignored)
# ───────────────────────────────────────────────────────────────

@test "validate-post-response ignores Read tool" {
  local input
  input=$(jq -n '{tool_name: "Read", tool_input: {file_path: "/project/file.js"}}')

  run bash -c "echo '$input' | bash '$HOOK_SCRIPT'"

  [ "$status" -eq 0 ]
}

@test "validate-post-response ignores Bash tool" {
  local input
  input=$(jq -n '{tool_name: "Bash", tool_input: {command: "ls"}}')

  run bash -c "echo '$input' | bash '$HOOK_SCRIPT'"

  [ "$status" -eq 0 ]
}

@test "validate-post-response ignores Task tool" {
  local input
  input=$(jq -n '{tool_name: "Task", tool_input: {prompt: "test"}}')

  run bash -c "echo '$input' | bash '$HOOK_SCRIPT'"

  [ "$status" -eq 0 ]
}

# ───────────────────────────────────────────────────────────────
# INPUT HANDLING
# ───────────────────────────────────────────────────────────────

@test "validate-post-response handles empty input" {
  run bash -c "echo '{}' | bash '$HOOK_SCRIPT'"

  [ "$status" -eq 0 ]
}

@test "validate-post-response handles missing file_path" {
  local input
  input=$(jq -n '{tool_name: "Edit"}')

  run bash -c "echo '$input' | bash '$HOOK_SCRIPT'"

  [ "$status" -eq 0 ]
}

# ───────────────────────────────────────────────────────────────
# EXIT CODES (always 0 - advisory)
# ───────────────────────────────────────────────────────────────

@test "validate-post-response always exits 0" {
  local input
  input=$(make_edit_input "/project/src/any.js")

  run bash -c "echo '$input' | bash '$HOOK_SCRIPT'"

  [ "$status" -eq 0 ]
}

@test "validate-post-response never blocks" {
  local input
  input=$(make_write_input "/project/critical.js")

  run bash -c "echo '$input' | bash '$HOOK_SCRIPT'"

  [ "$status" -eq 0 ]
}

# ───────────────────────────────────────────────────────────────
# PERFORMANCE
# ───────────────────────────────────────────────────────────────

@test "validate-post-response completes within 300ms" {
  local start_time end_time duration

  if [[ "$OSTYPE" == "darwin"* ]]; then
    start_time=$(python3 -c 'import time; print(int(time.time() * 1000))')
  else
    start_time=$(date +%s%3N)
  fi

  local input
  input=$(make_edit_input "/project/file.md")
  run bash -c "echo '$input' | bash '$HOOK_SCRIPT'"

  if [[ "$OSTYPE" == "darwin"* ]]; then
    end_time=$(python3 -c 'import time; print(int(time.time() * 1000))')
  else
    end_time=$(date +%s%3N)
  fi

  duration=$((end_time - start_time))
  [ "$duration" -lt 300 ]
}

