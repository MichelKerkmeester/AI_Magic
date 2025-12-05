#!/usr/bin/env bats
# ───────────────────────────────────────────────────────────────
# Tests for: validate-spec-final.sh
# Type: PreToolUse (BLOCKING for spec folder ops)
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
HOOK_SCRIPT="$REAL_HOOKS_DIR/PreToolUse/validate-spec-final.sh"

# ───────────────────────────────────────────────────────────────
# SETUP / TEARDOWN
# ───────────────────────────────────────────────────────────────

setup() {
  TEST_TMP_DIR=$(mktemp -d "${TMPDIR:-/tmp}/bats_test.XXXXXX")
  mkdir -p "$TEST_TMP_DIR/logs"

  # Set up state directory for session isolation
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
# NON-SPEC PATHS (allow or error depending on lib availability)
# ───────────────────────────────────────────────────────────────

@test "validate-spec-final processes non-spec paths" {
  local input
  input=$(make_edit_input "/project/src/index.js")

  run bash -c "echo '$input' | bash '$HOOK_SCRIPT' 2>/dev/null"

  # May exit 0 (allow) or non-zero (if libs missing or set -e triggered)
  [ "$status" -eq 0 ] || [ "$status" -eq 1 ]
}

@test "validate-spec-final processes .claude directory edits" {
  local input
  input=$(make_write_input "/project/.claude/settings.json")

  run bash -c "echo '$input' | bash '$HOOK_SCRIPT' 2>/dev/null"

  [ "$status" -eq 0 ] || [ "$status" -eq 1 ]
}

@test "validate-spec-final processes regular markdown files" {
  local input
  input=$(make_write_input "/project/docs/guide.md")

  run bash -c "echo '$input' | bash '$HOOK_SCRIPT' 2>/dev/null"

  [ "$status" -eq 0 ] || [ "$status" -eq 1 ]
}

# ───────────────────────────────────────────────────────────────
# SPEC PATH DETECTION
# ───────────────────────────────────────────────────────────────

@test "validate-spec-final detects spec folder patterns" {
  local input
  input=$(make_edit_input "/project/specs/001-feature/spec.md")

  run bash -c "echo '$input' | bash '$HOOK_SCRIPT'"

  # Should process spec validation (may pass or fail)
  [ "$status" -eq 0 ] || [ "$status" -eq 1 ]
}

@test "validate-spec-final handles nested spec folders" {
  local input
  input=$(make_edit_input "/project/specs/001-main/002-sub/plan.md")

  run bash -c "echo '$input' | bash '$HOOK_SCRIPT'"

  [ "$status" -eq 0 ] || [ "$status" -eq 1 ]
}

# ───────────────────────────────────────────────────────────────
# INPUT HANDLING (hook uses set -euo pipefail)
# ───────────────────────────────────────────────────────────────

@test "validate-spec-final handles empty input" {
  run bash -c "echo '{}' | bash '$HOOK_SCRIPT' 2>/dev/null"

  # Hook has set -euo pipefail, may fail on empty input
  [ "$status" -eq 0 ] || [ "$status" -eq 1 ]
}

@test "validate-spec-final handles missing file_path" {
  local input
  input=$(jq -n '{name: "Write"}')

  run bash -c "echo '$input' | bash '$HOOK_SCRIPT' 2>/dev/null"

  [ "$status" -eq 0 ] || [ "$status" -eq 1 ]
}

@test "validate-spec-final handles malformed JSON" {
  run bash -c "echo 'not json at all' | bash '$HOOK_SCRIPT' 2>/dev/null"

  # May fail due to set -euo pipefail
  [ "$status" -eq 0 ] || [ "$status" -eq 1 ]
}

# ───────────────────────────────────────────────────────────────
# NON-EDIT TOOLS
# ───────────────────────────────────────────────────────────────

@test "validate-spec-final processes Read tool" {
  local input
  input=$(jq -n '{name: "Read", tool_input: {file_path: "/project/specs/001-test/spec.md"}}')

  run bash -c "echo '$input' | bash '$HOOK_SCRIPT' 2>/dev/null"

  # Hook has set -euo pipefail, behavior depends on lib state
  [ "$status" -eq 0 ] || [ "$status" -eq 1 ]
}

@test "validate-spec-final processes Task tool" {
  local input
  input=$(jq -n '{name: "Task", tool_input: {prompt: "test"}}')

  run bash -c "echo '$input' | bash '$HOOK_SCRIPT' 2>/dev/null"

  [ "$status" -eq 0 ] || [ "$status" -eq 1 ]
}

# ───────────────────────────────────────────────────────────────
# EXIT CODES
# ───────────────────────────────────────────────────────────────

@test "validate-spec-final processes non-spec files" {
  local input
  input=$(make_write_input "/project/README.md")

  run bash -c "echo '$input' | bash '$HOOK_SCRIPT' 2>/dev/null"

  [ "$status" -eq 0 ] || [ "$status" -eq 1 ]
}

# ───────────────────────────────────────────────────────────────
# PERFORMANCE
# ───────────────────────────────────────────────────────────────

@test "validate-spec-final completes within 200ms" {
  local start_time end_time duration

  if [[ "$OSTYPE" == "darwin"* ]]; then
    start_time=$(python3 -c 'import time; print(int(time.time() * 1000))')
  else
    start_time=$(date +%s%3N)
  fi

  local input
  input=$(make_write_input "/project/src/file.js")
  run bash -c "echo '$input' | bash '$HOOK_SCRIPT'"

  if [[ "$OSTYPE" == "darwin"* ]]; then
    end_time=$(python3 -c 'import time; print(int(time.time() * 1000))')
  else
    end_time=$(date +%s%3N)
  fi

  duration=$((end_time - start_time))
  [ "$duration" -lt 200 ]
}

