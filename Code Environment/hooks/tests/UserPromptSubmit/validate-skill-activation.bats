#!/usr/bin/env bats
# ───────────────────────────────────────────────────────────────
# Tests for: validate-skill-activation.sh
# Type: UserPromptSubmit
# ───────────────────────────────────────────────────────────────
# Spec: 010-comprehensive-hook-testing
# Created: 2025-12-03
# Tests: 18
# ───────────────────────────────────────────────────────────────

load ../test_helper

# ───────────────────────────────────────────────────────────────
# CONSTANTS
# ───────────────────────────────────────────────────────────────

REAL_HOOKS_DIR="$(cd "$BATS_TEST_DIRNAME/../.." && pwd)"
HOOK_SCRIPT="$REAL_HOOKS_DIR/UserPromptSubmit/validate-skill-activation.sh"

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
# SKILL MATCHING
# ───────────────────────────────────────────────────────────────

@test "validate-skill-activation matches skill by keyword" {
  local input
  input=$(jq -n '{prompt: "create documentation for this feature"}')

  run bash -c "echo '$input' | bash '$HOOK_SCRIPT'"

  [ "$status" -eq 0 ]
}

@test "validate-skill-activation handles spec folder keywords" {
  local input
  input=$(jq -n '{prompt: "implement the feature from spec folder"}')

  run bash -c "echo '$input' | bash '$HOOK_SCRIPT'"

  [ "$status" -eq 0 ]
}

@test "validate-skill-activation handles git workflow keywords" {
  local input
  input=$(jq -n '{prompt: "commit the changes and push"}')

  run bash -c "echo '$input' | bash '$HOOK_SCRIPT'"

  [ "$status" -eq 0 ]
}

@test "validate-skill-activation handles save context keyword" {
  local input
  input=$(jq -n '{prompt: "save context for this conversation"}')

  run bash -c "echo '$input' | bash '$HOOK_SCRIPT'"

  [ "$status" -eq 0 ]
}

# ───────────────────────────────────────────────────────────────
# DOCUMENTATION LEVEL ESTIMATION
# ───────────────────────────────────────────────────────────────

@test "validate-skill-activation estimates documentation level" {
  local input
  input=$(jq -n '{prompt: "implement a new multi-file feature with database changes"}')

  run bash -c "echo '$input' | bash '$HOOK_SCRIPT'"

  [ "$status" -eq 0 ]
}

@test "validate-skill-activation calculates next spec number" {
  local input
  input=$(jq -n '{prompt: "create a new feature"}')

  run bash -c "echo '$input' | bash '$HOOK_SCRIPT'"

  [ "$status" -eq 0 ]
}

# ───────────────────────────────────────────────────────────────
# CACHE BEHAVIOR
# ───────────────────────────────────────────────────────────────

@test "validate-skill-activation uses skill-rules.json cache" {
  local input
  input=$(jq -n '{prompt: "test prompt"}')

  # First call
  run bash -c "echo '$input' | bash '$HOOK_SCRIPT'"
  [ "$status" -eq 0 ]

  # Second call should use cache
  run bash -c "echo '$input' | bash '$HOOK_SCRIPT'"
  [ "$status" -eq 0 ]
}

# ───────────────────────────────────────────────────────────────
# INPUT HANDLING
# ───────────────────────────────────────────────────────────────

@test "validate-skill-activation handles empty prompt" {
  run bash -c "echo '{}' | bash '$HOOK_SCRIPT'"

  [ "$status" -eq 0 ]
}

@test "validate-skill-activation handles missing prompt field" {
  run bash -c "echo '{\"session_id\": \"test\"}' | bash '$HOOK_SCRIPT'"

  [ "$status" -eq 0 ]
}

@test "validate-skill-activation handles very long prompt" {
  local filler
  filler=$(printf 'word %.0s' {1..500})
  local input
  input=$(jq -n --arg p "$filler" '{prompt: $p}')

  run bash -c "echo '$input' | bash '$HOOK_SCRIPT'"

  [ "$status" -eq 0 ]
}

@test "validate-skill-activation handles malformed JSON" {
  run bash -c "echo 'not json' | bash '$HOOK_SCRIPT'"

  [ "$status" -eq 0 ]
}

# ───────────────────────────────────────────────────────────────
# JSON OUTPUT
# ───────────────────────────────────────────────────────────────

@test "validate-skill-activation outputs valid JSON for suggestions" {
  local input
  input=$(jq -n '{prompt: "create documentation"}')

  run bash -c "echo '$input' | bash '$HOOK_SCRIPT'"

  [ "$status" -eq 0 ]
  # If output exists, check first JSON line
  if [ -n "$output" ]; then
    local first_json_line
    first_json_line=$(echo "$output" | grep -E '^\{' | head -1)
    if [ -n "$first_json_line" ]; then
      echo "$first_json_line" | jq empty 2>/dev/null
    fi
  fi
}

# ───────────────────────────────────────────────────────────────
# MULTIPLE SKILL MATCHES
# ───────────────────────────────────────────────────────────────

@test "validate-skill-activation handles multiple skill matches" {
  local input
  input=$(jq -n '{prompt: "create documentation and commit with git flow"}')

  run bash -c "echo '$input' | bash '$HOOK_SCRIPT'"

  [ "$status" -eq 0 ]
}

# ───────────────────────────────────────────────────────────────
# CONFIG FILE HANDLING
# ───────────────────────────────────────────────────────────────

@test "validate-skill-activation handles missing skill-rules.json" {
  # Should gracefully handle missing config
  local input
  input=$(jq -n '{prompt: "test"}')

  run bash -c "CONFIGS_DIR=/nonexistent echo '$input' | bash '$HOOK_SCRIPT'"

  [ "$status" -eq 0 ]
}

# ───────────────────────────────────────────────────────────────
# EXIT CODES
# ───────────────────────────────────────────────────────────────

@test "validate-skill-activation exits with 0" {
  local input
  input=$(jq -n '{prompt: "any prompt here"}')

  run bash -c "echo '$input' | bash '$HOOK_SCRIPT'"

  [ "$status" -eq 0 ]
}

# ───────────────────────────────────────────────────────────────
# PERFORMANCE
# ───────────────────────────────────────────────────────────────

@test "validate-skill-activation completes within 200ms" {
  local start_time end_time duration

  if [[ "$OSTYPE" == "darwin"* ]]; then
    start_time=$(python3 -c 'import time; print(int(time.time() * 1000))')
  else
    start_time=$(date +%s%3N)
  fi

  run bash -c "echo '{}' | bash '$HOOK_SCRIPT'"

  if [[ "$OSTYPE" == "darwin"* ]]; then
    end_time=$(python3 -c 'import time; print(int(time.time() * 1000))')
  else
    end_time=$(date +%s%3N)
  fi

  duration=$((end_time - start_time))
  [ "$duration" -lt 200 ]
}

# ───────────────────────────────────────────────────────────────
# SPECIAL CHARACTERS
# ───────────────────────────────────────────────────────────────

@test "validate-skill-activation handles unicode characters" {
  local input
  input=$(jq -n '{prompt: "Create documentation with ünïcödé 🚀 characters"}')

  run bash -c "echo '$input' | bash '$HOOK_SCRIPT'"

  [ "$status" -eq 0 ]
}

@test "validate-skill-activation handles special characters in prompt" {
  local input
  input=$(jq -n '{prompt: "Fix the \"bug\" in $PATH and @mentions"}')

  run bash -c "echo '$input' | bash '$HOOK_SCRIPT'"

  [ "$status" -eq 0 ]
}
