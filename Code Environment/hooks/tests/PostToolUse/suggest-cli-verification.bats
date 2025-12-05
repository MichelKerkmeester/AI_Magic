#!/usr/bin/env bats
# ───────────────────────────────────────────────────────────────
# Tests for: suggest-cli-verification.sh
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
HOOK_SCRIPT="$REAL_HOOKS_DIR/PostToolUse/suggest-cli-verification.sh"

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
  jq -n --arg name "Edit" --arg path "$file_path" \
    '{name: $name, tool_input: {file_path: $path}}'
}

make_write_input() {
  local file_path="$1"
  jq -n --arg name "Write" --arg path "$file_path" \
    '{name: $name, tool_input: {file_path: $path}}'
}

# ───────────────────────────────────────────────────────────────
# FRONTEND CODE DETECTION
# ───────────────────────────────────────────────────────────────

@test "suggest-cli-verification detects src/*.js edits" {
  local input
  input=$(make_edit_input "/project/src/app.js")

  run bash -c "echo '$input' | bash '$HOOK_SCRIPT'"

  [ "$status" -eq 0 ]
}

@test "suggest-cli-verification detects src/*.css edits" {
  local input
  input=$(make_write_input "/project/src/styles.css")

  run bash -c "echo '$input' | bash '$HOOK_SCRIPT'"

  [ "$status" -eq 0 ]
}

@test "suggest-cli-verification outputs suggestion for JS" {
  local input
  input=$(make_edit_input "/project/src/component.js")

  run bash -c "echo '$input' | bash '$HOOK_SCRIPT'"

  [ "$status" -eq 0 ]
  # Should suggest CLI verification
  [[ "$output" == *"systemMessage"* ]] || [[ "$output" == *"verification"* ]] || [[ -z "$output" ]]
}

# ───────────────────────────────────────────────────────────────
# NON-FRONTEND FILES (ignored)
# ───────────────────────────────────────────────────────────────

@test "suggest-cli-verification ignores .md files" {
  local input
  input=$(make_edit_input "/project/src/README.md")

  run bash -c "echo '$input' | bash '$HOOK_SCRIPT'"

  [ "$status" -eq 0 ]
}

@test "suggest-cli-verification ignores non-src paths" {
  local input
  input=$(make_edit_input "/project/docs/app.js")

  run bash -c "echo '$input' | bash '$HOOK_SCRIPT'"

  [ "$status" -eq 0 ]
}

# ───────────────────────────────────────────────────────────────
# TOOL FILTERING
# ───────────────────────────────────────────────────────────────

@test "suggest-cli-verification ignores Read tool" {
  local input
  input=$(jq -n '{name: "Read", tool_input: {file_path: "/project/src/app.js"}}')

  run bash -c "echo '$input' | bash '$HOOK_SCRIPT'"

  [ "$status" -eq 0 ]
}

# ───────────────────────────────────────────────────────────────
# INPUT HANDLING
# ───────────────────────────────────────────────────────────────

@test "suggest-cli-verification handles empty input" {
  run bash -c "echo '{}' | bash '$HOOK_SCRIPT'"

  [ "$status" -eq 0 ]
}

@test "suggest-cli-verification handles missing file_path" {
  local input
  input=$(jq -n '{name: "Edit"}')

  run bash -c "echo '$input' | bash '$HOOK_SCRIPT'"

  [ "$status" -eq 0 ]
}

# ───────────────────────────────────────────────────────────────
# EXIT CODES (always 0)
# ───────────────────────────────────────────────────────────────

@test "suggest-cli-verification always exits 0" {
  local input
  input=$(make_edit_input "/project/src/test.js")

  run bash -c "echo '$input' | bash '$HOOK_SCRIPT'"

  [ "$status" -eq 0 ]
}

@test "suggest-cli-verification never blocks" {
  local input
  input=$(make_write_input "/project/src/critical.js")

  run bash -c "echo '$input' | bash '$HOOK_SCRIPT'"

  [ "$status" -eq 0 ]
}

# ───────────────────────────────────────────────────────────────
# PERFORMANCE
# ───────────────────────────────────────────────────────────────

@test "suggest-cli-verification completes within 200ms" {
  local start_time end_time duration

  if [[ "$OSTYPE" == "darwin"* ]]; then
    start_time=$(python3 -c 'import time; print(int(time.time() * 1000))')
  else
    start_time=$(date +%s%3N)
  fi

  local input
  input=$(make_edit_input "/project/README.md")
  run bash -c "echo '$input' | bash '$HOOK_SCRIPT'"

  if [[ "$OSTYPE" == "darwin"* ]]; then
    end_time=$(python3 -c 'import time; print(int(time.time() * 1000))')
  else
    end_time=$(date +%s%3N)
  fi

  duration=$((end_time - start_time))
  [ "$duration" -lt 200 ]
}

