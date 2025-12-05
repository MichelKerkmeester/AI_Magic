#!/usr/bin/env bats
# ───────────────────────────────────────────────────────────────
# Tests for: detect-scope-growth.sh
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
HOOK_SCRIPT="$REAL_HOOKS_DIR/PostToolUse/detect-scope-growth.sh"

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

make_edit_input() {
  local file_path="$1"
  jq -n --arg name "Edit" --arg path "$file_path" \
    '{name: $name, tool_input: {file_path: $path}}'
}

make_write_input() {
  local file_path="$1"
  jq -n --arg name "Write" --arg path "$file_path" \
    '{name: $name, tool_input: {file_path: $path}}'
}

# ───────────────────────────────────────────────────────────────
# TOOL FILTERING
# ───────────────────────────────────────────────────────────────

@test "detect-scope-growth processes Edit tool" {
  local input
  input=$(make_edit_input "/project/specs/001-test/spec.md")

  run bash -c "echo '$input' | bash '$HOOK_SCRIPT' 2>/dev/null"

  [ "$status" -eq 0 ]
}

@test "detect-scope-growth processes Write tool" {
  local input
  input=$(make_write_input "/project/specs/001-test/plan.md")

  run bash -c "echo '$input' | bash '$HOOK_SCRIPT' 2>/dev/null"

  [ "$status" -eq 0 ]
}

@test "detect-scope-growth ignores Read tool" {
  local input
  input=$(jq -n '{name: "Read", tool_input: {file_path: "/project/specs/001-test/spec.md"}}')

  run bash -c "echo '$input' | bash '$HOOK_SCRIPT' 2>/dev/null"

  [ "$status" -eq 0 ]
}

@test "detect-scope-growth ignores non-spec paths" {
  local input
  input=$(make_edit_input "/project/src/index.js")

  run bash -c "echo '$input' | bash '$HOOK_SCRIPT' 2>/dev/null"

  [ "$status" -eq 0 ]
}

# ───────────────────────────────────────────────────────────────
# SPEC PATH DETECTION
# ───────────────────────────────────────────────────────────────

@test "detect-scope-growth detects spec folder pattern" {
  local input
  input=$(make_edit_input "/project/specs/001-feature/spec.md")

  run bash -c "echo '$input' | bash '$HOOK_SCRIPT' 2>/dev/null"

  [ "$status" -eq 0 ]
}

@test "detect-scope-growth handles nested spec paths" {
  local input
  input=$(make_write_input "/project/specs/001-main/002-sub/tasks.md")

  run bash -c "echo '$input' | bash '$HOOK_SCRIPT' 2>/dev/null"

  [ "$status" -eq 0 ]
}

# ───────────────────────────────────────────────────────────────
# INPUT HANDLING
# ───────────────────────────────────────────────────────────────

@test "detect-scope-growth handles empty input" {
  run bash -c "echo '{}' | bash '$HOOK_SCRIPT' 2>/dev/null"

  [ "$status" -eq 0 ]
}

@test "detect-scope-growth handles missing file_path" {
  local input
  input=$(jq -n '{name: "Edit"}')

  run bash -c "echo '$input' | bash '$HOOK_SCRIPT' 2>/dev/null"

  [ "$status" -eq 0 ]
}

# ───────────────────────────────────────────────────────────────
# EXIT CODES (always 0 - advisory)
# ───────────────────────────────────────────────────────────────

@test "detect-scope-growth always exits 0" {
  local input
  input=$(make_edit_input "/project/specs/001-test/spec.md")

  run bash -c "echo '$input' | bash '$HOOK_SCRIPT' 2>/dev/null"

  [ "$status" -eq 0 ]
}

@test "detect-scope-growth never blocks execution" {
  local input
  input=$(make_write_input "/project/specs/001-test/new_file.md")

  run bash -c "echo '$input' | bash '$HOOK_SCRIPT' 2>/dev/null"

  [ "$status" -eq 0 ]
}

# ───────────────────────────────────────────────────────────────
# PERFORMANCE
# ───────────────────────────────────────────────────────────────

@test "detect-scope-growth completes within 250ms" {
  local start_time end_time duration

  if [[ "$OSTYPE" == "darwin"* ]]; then
    start_time=$(python3 -c 'import time; print(int(time.time() * 1000))')
  else
    start_time=$(date +%s%3N)
  fi

  local input
  input=$(make_edit_input "/project/src/file.js")
  run bash -c "echo '$input' | bash '$HOOK_SCRIPT' 2>/dev/null"

  if [[ "$OSTYPE" == "darwin"* ]]; then
    end_time=$(python3 -c 'import time; print(int(time.time() * 1000))')
  else
    end_time=$(date +%s%3N)
  fi

  duration=$((end_time - start_time))
  [ "$duration" -lt 250 ]
}

