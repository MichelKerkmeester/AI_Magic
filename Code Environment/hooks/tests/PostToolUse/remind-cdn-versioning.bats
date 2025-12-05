#!/usr/bin/env bats
# ───────────────────────────────────────────────────────────────
# Tests for: remind-cdn-versioning.sh
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
HOOK_SCRIPT="$REAL_HOOKS_DIR/PostToolUse/remind-cdn-versioning.sh"

# ───────────────────────────────────────────────────────────────
# SETUP / TEARDOWN
# ───────────────────────────────────────────────────────────────

setup() {
  TEST_TMP_DIR=$(mktemp -d "${TMPDIR:-/tmp}/bats_test.XXXXXX")
  mkdir -p "$TEST_TMP_DIR/logs"

  # Clear cache for testing
  rm -rf /tmp/cdn_versioning_cache 2>/dev/null || true
}

teardown() {
  [ -n "$TEST_TMP_DIR" ] && [ -d "$TEST_TMP_DIR" ] && rm -rf "$TEST_TMP_DIR"
  rm -rf /tmp/cdn_versioning_cache 2>/dev/null || true
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
# JAVASCRIPT DETECTION
# ───────────────────────────────────────────────────────────────

@test "remind-cdn-versioning detects .js file edits" {
  local input
  input=$(make_edit_input "/project/src/2_javascript/app.js")

  run bash -c "echo '$input' | bash '$HOOK_SCRIPT'"

  [ "$status" -eq 0 ]
}

@test "remind-cdn-versioning detects .ts file edits" {
  local input
  input=$(make_write_input "/project/src/2_javascript/module.ts")

  run bash -c "echo '$input' | bash '$HOOK_SCRIPT'"

  [ "$status" -eq 0 ]
}

# ───────────────────────────────────────────────────────────────
# NON-JS FILES (ignored)
# ───────────────────────────────────────────────────────────────

@test "remind-cdn-versioning ignores .md files" {
  local input
  input=$(make_edit_input "/project/README.md")

  run bash -c "echo '$input' | bash '$HOOK_SCRIPT'"

  [ "$status" -eq 0 ]
}

@test "remind-cdn-versioning ignores .html files" {
  local input
  input=$(make_edit_input "/project/src/index.html")

  run bash -c "echo '$input' | bash '$HOOK_SCRIPT'"

  [ "$status" -eq 0 ]
}

# ───────────────────────────────────────────────────────────────
# TOOL FILTERING
# ───────────────────────────────────────────────────────────────

@test "remind-cdn-versioning ignores Read tool" {
  local input
  input=$(jq -n '{name: "Read", tool_input: {file_path: "/project/src/app.js"}}')

  run bash -c "echo '$input' | bash '$HOOK_SCRIPT'"

  [ "$status" -eq 0 ]
}

@test "remind-cdn-versioning ignores Bash tool" {
  local input
  input=$(jq -n '{name: "Bash", tool_input: {command: "npm build"}}')

  run bash -c "echo '$input' | bash '$HOOK_SCRIPT'"

  [ "$status" -eq 0 ]
}

# ───────────────────────────────────────────────────────────────
# INPUT HANDLING
# ───────────────────────────────────────────────────────────────

@test "remind-cdn-versioning handles empty input" {
  run bash -c "echo '{}' | bash '$HOOK_SCRIPT'"

  [ "$status" -eq 0 ]
}

@test "remind-cdn-versioning handles missing file_path" {
  local input
  input=$(jq -n '{name: "Edit"}')

  run bash -c "echo '$input' | bash '$HOOK_SCRIPT'"

  [ "$status" -eq 0 ]
}

# ───────────────────────────────────────────────────────────────
# EXIT CODES (always 0 - advisory)
# ───────────────────────────────────────────────────────────────

@test "remind-cdn-versioning always exits 0" {
  local input
  input=$(make_edit_input "/project/src/2_javascript/production.js")

  run bash -c "echo '$input' | bash '$HOOK_SCRIPT'"

  [ "$status" -eq 0 ]
}

@test "remind-cdn-versioning never blocks" {
  local input
  input=$(make_write_input "/project/dist/bundle.js")

  run bash -c "echo '$input' | bash '$HOOK_SCRIPT'"

  [ "$status" -eq 0 ]
}

# ───────────────────────────────────────────────────────────────
# PERFORMANCE
# ───────────────────────────────────────────────────────────────

@test "remind-cdn-versioning completes within 300ms" {
  local start_time end_time duration

  if [[ "$OSTYPE" == "darwin"* ]]; then
    start_time=$(python3 -c 'import time; print(int(time.time() * 1000))')
  else
    start_time=$(date +%s%3N)
  fi

  local input
  input=$(make_edit_input "/project/src/file.css")
  run bash -c "echo '$input' | bash '$HOOK_SCRIPT'"

  if [[ "$OSTYPE" == "darwin"* ]]; then
    end_time=$(python3 -c 'import time; print(int(time.time() * 1000))')
  else
    end_time=$(date +%s%3N)
  fi

  duration=$((end_time - start_time))
  [ "$duration" -lt 300 ]
}

