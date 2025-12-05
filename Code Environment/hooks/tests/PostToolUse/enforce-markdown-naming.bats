#!/usr/bin/env bats
# ───────────────────────────────────────────────────────────────
# Tests for: enforce-markdown-naming.sh
# Type: PostToolUse (auto-corrects filenames)
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
HOOK_SCRIPT="$REAL_HOOKS_DIR/PostToolUse/enforce-markdown-naming.sh"

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

make_write_input() {
  local file_path="$1"
  jq -n --arg name "Write" --arg path "$file_path" \
    '{name: $name, tool_input: {file_path: $path}}'
}

make_edit_input() {
  local file_path="$1"
  jq -n --arg name "Edit" --arg path "$file_path" \
    '{name: $name, tool_input: {file_path: $path}}'
}

make_task_input() {
  jq -n '{name: "Task", tool_input: {prompt: "test"}}'
}

# ───────────────────────────────────────────────────────────────
# TOOL PROCESSING
# ───────────────────────────────────────────────────────────────

@test "enforce-markdown-naming processes Write tool" {
  local input
  input=$(make_write_input "/project/docs/my_document.md")

  run bash -c "echo '$input' | bash '$HOOK_SCRIPT'"

  [ "$status" -eq 0 ]
}

@test "enforce-markdown-naming processes Edit tool" {
  local input
  input=$(make_edit_input "/project/docs/readme.md")

  run bash -c "echo '$input' | bash '$HOOK_SCRIPT'"

  [ "$status" -eq 0 ]
}

@test "enforce-markdown-naming processes Task tool" {
  local input
  input=$(make_task_input)

  run bash -c "echo '$input' | bash '$HOOK_SCRIPT'"

  [ "$status" -eq 0 ]
}

# ───────────────────────────────────────────────────────────────
# EXCEPTIONS (allowed filenames)
# ───────────────────────────────────────────────────────────────

@test "enforce-markdown-naming allows README.md" {
  local input
  input=$(make_write_input "/project/README.md")

  run bash -c "echo '$input' | bash '$HOOK_SCRIPT'"

  [ "$status" -eq 0 ]
}

@test "enforce-markdown-naming allows SKILL.md in skills dir" {
  local input
  input=$(make_write_input "/project/.claude/skills/test/SKILL.md")

  run bash -c "echo '$input' | bash '$HOOK_SCRIPT'"

  [ "$status" -eq 0 ]
}

@test "enforce-markdown-naming allows AGENTS.md" {
  local input
  input=$(make_write_input "/project/AGENTS.md")

  run bash -c "echo '$input' | bash '$HOOK_SCRIPT'"

  [ "$status" -eq 0 ]
}

@test "enforce-markdown-naming allows CHANGELOG.md" {
  local input
  input=$(make_write_input "/project/CHANGELOG.md")

  run bash -c "echo '$input' | bash '$HOOK_SCRIPT'"

  [ "$status" -eq 0 ]
}

# ───────────────────────────────────────────────────────────────
# NON-MARKDOWN FILES (ignored)
# ───────────────────────────────────────────────────────────────

@test "enforce-markdown-naming ignores .js files" {
  local input
  input=$(make_write_input "/project/src/MyComponent.js")

  run bash -c "echo '$input' | bash '$HOOK_SCRIPT'"

  [ "$status" -eq 0 ]
}

@test "enforce-markdown-naming ignores .ts files" {
  local input
  input=$(make_edit_input "/project/src/module.ts")

  run bash -c "echo '$input' | bash '$HOOK_SCRIPT'"

  [ "$status" -eq 0 ]
}

# ───────────────────────────────────────────────────────────────
# INPUT HANDLING
# ───────────────────────────────────────────────────────────────

@test "enforce-markdown-naming handles empty input" {
  run bash -c "echo '{}' | bash '$HOOK_SCRIPT'"

  [ "$status" -eq 0 ]
}

@test "enforce-markdown-naming handles missing file_path" {
  local input
  input=$(jq -n '{name: "Write"}')

  run bash -c "echo '$input' | bash '$HOOK_SCRIPT'"

  [ "$status" -eq 0 ]
}

# ───────────────────────────────────────────────────────────────
# EXIT CODES (always 0)
# ───────────────────────────────────────────────────────────────

@test "enforce-markdown-naming always exits 0" {
  local input
  input=$(make_write_input "/project/docs/any-document.md")

  run bash -c "echo '$input' | bash '$HOOK_SCRIPT'"

  [ "$status" -eq 0 ]
}

@test "enforce-markdown-naming never blocks execution" {
  local input
  input=$(make_edit_input "/project/MyDocument.md")

  run bash -c "echo '$input' | bash '$HOOK_SCRIPT'"

  [ "$status" -eq 0 ]
}

# ───────────────────────────────────────────────────────────────
# PERFORMANCE
# ───────────────────────────────────────────────────────────────

@test "enforce-markdown-naming completes within 300ms" {
  local start_time end_time duration

  if [[ "$OSTYPE" == "darwin"* ]]; then
    start_time=$(python3 -c 'import time; print(int(time.time() * 1000))')
  else
    start_time=$(date +%s%3N)
  fi

  local input
  input=$(make_write_input "/project/doc.md")
  run bash -c "echo '$input' | bash '$HOOK_SCRIPT'"

  if [[ "$OSTYPE" == "darwin"* ]]; then
    end_time=$(python3 -c 'import time; print(int(time.time() * 1000))')
  else
    end_time=$(date +%s%3N)
  fi

  duration=$((end_time - start_time))
  [ "$duration" -lt 300 ]
}

