#!/usr/bin/env bats
# ───────────────────────────────────────────────────────────────
# Tests for: enforce-markdown-pre.sh
# Type: PreToolUse (BLOCKING)
# ───────────────────────────────────────────────────────────────
# Spec: 010-comprehensive-hook-testing
# Created: 2025-12-03
# Tests: 14
# ───────────────────────────────────────────────────────────────

load '../test_helper'

# ───────────────────────────────────────────────────────────────
# CONSTANTS
# ───────────────────────────────────────────────────────────────

REAL_HOOKS_DIR="$(cd "$BATS_TEST_DIRNAME/../.." && pwd)"
HOOK_SCRIPT="$REAL_HOOKS_DIR/PreToolUse/enforce-markdown-pre.sh"

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

# ───────────────────────────────────────────────────────────────
# BLOCKING: Invalid Filenames
# ───────────────────────────────────────────────────────────────

@test "enforce-markdown-pre blocks ALL CAPS filenames" {
  local input
  input=$(make_write_input "/project/DOCUMENT.md")

  run bash -c "echo '$input' | bash '$HOOK_SCRIPT'"

  [ "$status" -eq 1 ]
}

@test "enforce-markdown-pre blocks hyphenated filenames" {
  local input
  input=$(make_write_input "/project/my-document.md")

  run bash -c "echo '$input' | bash '$HOOK_SCRIPT'"

  [ "$status" -eq 1 ]
}

@test "enforce-markdown-pre blocks camelCase filenames" {
  local input
  input=$(make_write_input "/project/myDocument.md")

  run bash -c "echo '$input' | bash '$HOOK_SCRIPT'"

  [ "$status" -eq 1 ]
}

@test "enforce-markdown-pre blocks PascalCase filenames" {
  local input
  input=$(make_write_input "/project/MyDocument.md")

  run bash -c "echo '$input' | bash '$HOOK_SCRIPT'"

  [ "$status" -eq 1 ]
}

# ───────────────────────────────────────────────────────────────
# ALLOWING: Valid Filenames
# ───────────────────────────────────────────────────────────────

@test "enforce-markdown-pre allows lowercase_snake_case" {
  local input
  input=$(make_write_input "/project/my_document.md")

  run bash -c "echo '$input' | bash '$HOOK_SCRIPT'"

  [ "$status" -eq 0 ]
}

@test "enforce-markdown-pre allows simple lowercase" {
  local input
  input=$(make_write_input "/project/document.md")

  run bash -c "echo '$input' | bash '$HOOK_SCRIPT'"

  [ "$status" -eq 0 ]
}

# ───────────────────────────────────────────────────────────────
# EXCEPTIONS
# ───────────────────────────────────────────────────────────────

@test "enforce-markdown-pre allows README.md" {
  local input
  input=$(make_write_input "/project/README.md")

  run bash -c "echo '$input' | bash '$HOOK_SCRIPT'"

  [ "$status" -eq 0 ]
}

@test "enforce-markdown-pre allows SKILL.md" {
  local input
  input=$(make_write_input "/project/.claude/skills/test/SKILL.md")

  run bash -c "echo '$input' | bash '$HOOK_SCRIPT'"

  [ "$status" -eq 0 ]
}

@test "enforce-markdown-pre allows AGENTS.md" {
  local input
  input=$(make_write_input "/project/AGENTS.md")

  run bash -c "echo '$input' | bash '$HOOK_SCRIPT'"

  [ "$status" -eq 0 ]
}

@test "enforce-markdown-pre allows CLAUDE.md" {
  local input
  input=$(make_write_input "/project/CLAUDE.md")

  run bash -c "echo '$input' | bash '$HOOK_SCRIPT'"

  [ "$status" -eq 0 ]
}

# ───────────────────────────────────────────────────────────────
# EDGE CASES
# ───────────────────────────────────────────────────────────────

@test "enforce-markdown-pre handles non-markdown files" {
  local input
  input=$(make_write_input "/project/script.js")

  run bash -c "echo '$input' | bash '$HOOK_SCRIPT'"

  [ "$status" -eq 0 ]
}

@test "enforce-markdown-pre handles nested paths" {
  local input
  input=$(make_write_input "/project/deep/nested/path/doc.md")

  run bash -c "echo '$input' | bash '$HOOK_SCRIPT'"

  [ "$status" -eq 0 ]
}

@test "enforce-markdown-pre handles empty input" {
  run bash -c "echo '{}' | bash '$HOOK_SCRIPT'"

  [ "$status" -eq 0 ]
}

# ───────────────────────────────────────────────────────────────
# PERFORMANCE
# ───────────────────────────────────────────────────────────────

@test "enforce-markdown-pre completes within 150ms" {
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
  [ "$duration" -lt 150 ]
}
