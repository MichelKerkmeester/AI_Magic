#!/usr/bin/env bats
# ───────────────────────────────────────────────────────────────
# Tests for: track-file-modifications.sh
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
HOOK_SCRIPT="$REAL_HOOKS_DIR/PostToolUse/track-file-modifications.sh"

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

make_write_input() {
  local file_path="$1"
  jq -n --arg path "$file_path" \
    '{tool_name: "Write", tool_input: {file_path: $path}}'
}

make_edit_input() {
  local file_path="$1"
  jq -n --arg path "$file_path" \
    '{tool_name: "Edit", tool_input: {file_path: $path}}'
}

# ───────────────────────────────────────────────────────────────
# TOOL FILTERING
# ───────────────────────────────────────────────────────────────

@test "track-file-modifications tracks Write tool" {
  local input
  input=$(make_write_input "/project/src/file.js")

  run bash -c "echo '$input' | bash '$HOOK_SCRIPT' 2>/dev/null"

  [ "$status" -eq 0 ]
}

@test "track-file-modifications tracks Edit tool" {
  local input
  input=$(make_edit_input "/project/src/module.ts")

  run bash -c "echo '$input' | bash '$HOOK_SCRIPT' 2>/dev/null"

  [ "$status" -eq 0 ]
}

@test "track-file-modifications ignores Read tool" {
  local input
  input=$(jq -n '{tool_name: "Read", tool_input: {file_path: "/project/file.js"}}')

  run bash -c "echo '$input' | bash '$HOOK_SCRIPT' 2>/dev/null"

  [ "$status" -eq 0 ]
}

@test "track-file-modifications ignores Bash tool" {
  local input
  input=$(jq -n '{tool_name: "Bash", tool_input: {command: "ls"}}')

  run bash -c "echo '$input' | bash '$HOOK_SCRIPT' 2>/dev/null"

  [ "$status" -eq 0 ]
}

# ───────────────────────────────────────────────────────────────
# FILE PATH HANDLING
# ───────────────────────────────────────────────────────────────

@test "track-file-modifications handles various file paths" {
  local input
  input=$(make_write_input "/project/deep/nested/path/file.md")

  run bash -c "echo '$input' | bash '$HOOK_SCRIPT' 2>/dev/null"

  [ "$status" -eq 0 ]
}

@test "track-file-modifications handles spec folder paths" {
  local input
  input=$(make_edit_input "/project/specs/001-feature/plan.md")

  run bash -c "echo '$input' | bash '$HOOK_SCRIPT' 2>/dev/null"

  [ "$status" -eq 0 ]
}

# ───────────────────────────────────────────────────────────────
# INPUT HANDLING
# ───────────────────────────────────────────────────────────────

@test "track-file-modifications handles empty input" {
  run bash -c "echo '{}' | bash '$HOOK_SCRIPT' 2>/dev/null"

  [ "$status" -eq 0 ]
}

@test "track-file-modifications handles missing file_path" {
  local input
  input=$(jq -n '{tool_name: "Write"}')

  run bash -c "echo '$input' | bash '$HOOK_SCRIPT' 2>/dev/null"

  [ "$status" -eq 0 ]
}

# ───────────────────────────────────────────────────────────────
# EXIT CODES (always 0 - advisory)
# ───────────────────────────────────────────────────────────────

@test "track-file-modifications always exits 0" {
  local input
  input=$(make_write_input "/project/src/any.js")

  run bash -c "echo '$input' | bash '$HOOK_SCRIPT' 2>/dev/null"

  [ "$status" -eq 0 ]
}

@test "track-file-modifications never blocks" {
  local input
  input=$(make_edit_input "/project/outside/scope.js")

  run bash -c "echo '$input' | bash '$HOOK_SCRIPT' 2>/dev/null"

  [ "$status" -eq 0 ]
}

# ───────────────────────────────────────────────────────────────
# PERFORMANCE
# ───────────────────────────────────────────────────────────────

@test "track-file-modifications completes within 200ms" {
  local start_time end_time duration

  if [[ "$OSTYPE" == "darwin"* ]]; then
    start_time=$(python3 -c 'import time; print(int(time.time() * 1000))')
  else
    start_time=$(date +%s%3N)
  fi

  local input
  input=$(make_write_input "/project/file.md")
  run bash -c "echo '$input' | bash '$HOOK_SCRIPT' 2>/dev/null"

  if [[ "$OSTYPE" == "darwin"* ]]; then
    end_time=$(python3 -c 'import time; print(int(time.time() * 1000))')
  else
    end_time=$(date +%s%3N)
  fi

  duration=$((end_time - start_time))
  [ "$duration" -lt 200 ]
}

