#!/usr/bin/env bats
# ───────────────────────────────────────────────────────────────
# Tests for: skill-scaffold-trigger.sh
# Type: PostToolUse (advisory, auto-scaffolds)
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
HOOK_SCRIPT="$REAL_HOOKS_DIR/PostToolUse/skill-scaffold-trigger.sh"

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
# SKILL.MD DETECTION
# ───────────────────────────────────────────────────────────────

@test "skill-scaffold-trigger detects SKILL.md creation" {
  local input
  input=$(make_write_input "/project/.claude/skills/new-skill/SKILL.md")

  run bash -c "echo '$input' | bash '$HOOK_SCRIPT'"

  [ "$status" -eq 0 ]
}

@test "skill-scaffold-trigger ignores non-SKILL.md files" {
  local input
  input=$(make_write_input "/project/.claude/skills/test/README.md")

  run bash -c "echo '$input' | bash '$HOOK_SCRIPT'"

  [ "$status" -eq 0 ]
}

@test "skill-scaffold-trigger ignores SKILL.md outside skills dir" {
  local input
  input=$(make_write_input "/project/docs/SKILL.md")

  run bash -c "echo '$input' | bash '$HOOK_SCRIPT'"

  [ "$status" -eq 0 ]
}

# ───────────────────────────────────────────────────────────────
# TOOL FILTERING
# ───────────────────────────────────────────────────────────────

@test "skill-scaffold-trigger only triggers on Write tool" {
  local input
  input=$(make_write_input "/project/.claude/skills/test/SKILL.md")

  run bash -c "echo '$input' | bash '$HOOK_SCRIPT'"

  [ "$status" -eq 0 ]
}

@test "skill-scaffold-trigger ignores Edit tool" {
  local input
  input=$(jq -n '{name: "Edit", tool_input: {file_path: "/project/.claude/skills/test/SKILL.md"}}')

  run bash -c "echo '$input' | bash '$HOOK_SCRIPT'"

  [ "$status" -eq 0 ]
}

@test "skill-scaffold-trigger ignores Read tool" {
  local input
  input=$(jq -n '{name: "Read", tool_input: {file_path: "/project/.claude/skills/test/SKILL.md"}}')

  run bash -c "echo '$input' | bash '$HOOK_SCRIPT'"

  [ "$status" -eq 0 ]
}

# ───────────────────────────────────────────────────────────────
# INPUT HANDLING
# ───────────────────────────────────────────────────────────────

@test "skill-scaffold-trigger handles empty input" {
  run bash -c "echo '{}' | bash '$HOOK_SCRIPT'"

  [ "$status" -eq 0 ]
}

@test "skill-scaffold-trigger handles missing file_path" {
  local input
  input=$(jq -n '{name: "Write"}')

  run bash -c "echo '$input' | bash '$HOOK_SCRIPT'"

  [ "$status" -eq 0 ]
}

# ───────────────────────────────────────────────────────────────
# EXIT CODES (always 0)
# ───────────────────────────────────────────────────────────────

@test "skill-scaffold-trigger always exits 0" {
  local input
  input=$(make_write_input "/project/.claude/skills/new/SKILL.md")

  run bash -c "echo '$input' | bash '$HOOK_SCRIPT'"

  [ "$status" -eq 0 ]
}

@test "skill-scaffold-trigger never blocks execution" {
  local input
  input=$(make_write_input "/project/any/path.md")

  run bash -c "echo '$input' | bash '$HOOK_SCRIPT'"

  [ "$status" -eq 0 ]
}

# ───────────────────────────────────────────────────────────────
# PERFORMANCE
# ───────────────────────────────────────────────────────────────

@test "skill-scaffold-trigger completes within 300ms" {
  local start_time end_time duration

  if [[ "$OSTYPE" == "darwin"* ]]; then
    start_time=$(python3 -c 'import time; print(int(time.time() * 1000))')
  else
    start_time=$(date +%s%3N)
  fi

  local input
  input=$(make_write_input "/project/src/file.md")
  run bash -c "echo '$input' | bash '$HOOK_SCRIPT'"

  if [[ "$OSTYPE" == "darwin"* ]]; then
    end_time=$(python3 -c 'import time; print(int(time.time() * 1000))')
  else
    end_time=$(date +%s%3N)
  fi

  duration=$((end_time - start_time))
  [ "$duration" -lt 300 ]
}

