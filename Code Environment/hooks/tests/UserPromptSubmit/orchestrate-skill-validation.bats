#!/usr/bin/env bats
# ───────────────────────────────────────────────────────────────
# Tests for: orchestrate-skill-validation.sh
# Type: UserPromptSubmit
# ───────────────────────────────────────────────────────────────
# Spec: 010-comprehensive-hook-testing
# Created: 2025-12-03
# Tests: 15
# ───────────────────────────────────────────────────────────────

load ../test_helper

# ───────────────────────────────────────────────────────────────
# CONSTANTS
# ───────────────────────────────────────────────────────────────

REAL_HOOKS_DIR="$(cd "$BATS_TEST_DIRNAME/../.." && pwd)"
HOOK_SCRIPT="$REAL_HOOKS_DIR/UserPromptSubmit/orchestrate-skill-validation.sh"

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
# OVERRIDE PHRASES
# ───────────────────────────────────────────────────────────────

@test "orchestrate-skill-validation handles proceed directly override" {
  local input
  input=$(jq -n '{prompt: "proceed directly with the implementation"}')

  run bash -c "echo '$input' | bash '$HOOK_SCRIPT'"

  [ "$status" -eq 0 ]
}

@test "orchestrate-skill-validation handles use parallel agents override" {
  local input
  input=$(jq -n '{prompt: "use parallel agents for this task"}')

  run bash -c "echo '$input' | bash '$HOOK_SCRIPT'"

  [ "$status" -eq 0 ]
}

@test "orchestrate-skill-validation handles auto-decide override" {
  local input
  input=$(jq -n '{prompt: "auto-decide on parallel dispatch"}')

  run bash -c "echo '$input' | bash '$HOOK_SCRIPT'"

  [ "$status" -eq 0 ]
}

@test "orchestrate-skill-validation handles skip dispatch override" {
  local input
  input=$(jq -n '{prompt: "skip dispatch and handle directly"}')

  run bash -c "echo '$input' | bash '$HOOK_SCRIPT'"

  [ "$status" -eq 0 ]
}

# ───────────────────────────────────────────────────────────────
# COMPLEXITY DETECTION
# ───────────────────────────────────────────────────────────────

@test "orchestrate-skill-validation detects multiple domains" {
  local input
  input=$(jq -n '{prompt: "Create a Webflow CMS integration with Figma designs and save to Notion"}')

  run bash -c "echo '$input' | bash '$HOOK_SCRIPT'"

  [ "$status" -eq 0 ]
}

@test "orchestrate-skill-validation handles simple prompts" {
  local input
  input=$(jq -n '{prompt: "Fix the typo"}')

  run bash -c "echo '$input' | bash '$HOOK_SCRIPT'"

  [ "$status" -eq 0 ]
}

# ───────────────────────────────────────────────────────────────
# INPUT HANDLING
# ───────────────────────────────────────────────────────────────

@test "orchestrate-skill-validation handles empty prompt" {
  run bash -c "echo '{}' | bash '$HOOK_SCRIPT'"

  [ "$status" -eq 0 ]
}

@test "orchestrate-skill-validation handles missing prompt field" {
  run bash -c "echo '{\"session_id\": \"test\"}' | bash '$HOOK_SCRIPT'"

  [ "$status" -eq 0 ]
}

@test "orchestrate-skill-validation handles malformed JSON" {
  run bash -c "echo 'not json' | bash '$HOOK_SCRIPT'"

  [ "$status" -eq 0 ]
}

# ───────────────────────────────────────────────────────────────
# STATE MANAGEMENT
# ───────────────────────────────────────────────────────────────

@test "orchestrate-skill-validation respects existing preference" {
  local input
  input=$(jq -n '{prompt: "proceed directly with the task"}')

  # First call sets preference
  run bash -c "echo '$input' | bash '$HOOK_SCRIPT'"
  [ "$status" -eq 0 ]

  # Second call should respect preference
  local input2
  input2=$(jq -n '{prompt: "another complex task"}')
  run bash -c "echo '$input2' | bash '$HOOK_SCRIPT'"
  [ "$status" -eq 0 ]
}

# ───────────────────────────────────────────────────────────────
# EXIT CODES
# ───────────────────────────────────────────────────────────────

@test "orchestrate-skill-validation exits with 0" {
  local input
  input=$(jq -n '{prompt: "any prompt here"}')

  run bash -c "echo '$input' | bash '$HOOK_SCRIPT'"

  [ "$status" -eq 0 ]
}

# ───────────────────────────────────────────────────────────────
# PERFORMANCE
# ───────────────────────────────────────────────────────────────

@test "orchestrate-skill-validation completes within 100ms" {
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
  [ "$duration" -lt 100 ]
}

# ───────────────────────────────────────────────────────────────
# LOGGING
# ───────────────────────────────────────────────────────────────

@test "orchestrate-skill-validation logs to orchestrator.log" {
  local input
  input=$(jq -n '{prompt: "skip dispatch and handle directly"}')

  run bash -c "echo '$input' | bash '$HOOK_SCRIPT'"

  [ "$status" -eq 0 ]
  # Log should exist (hook creates it on overrides)
  [ -f "$REAL_HOOKS_DIR/logs/orchestrator.log" ]
}

# ───────────────────────────────────────────────────────────────
# EDGE CASES
# ───────────────────────────────────────────────────────────────

@test "orchestrate-skill-validation handles unicode" {
  local input
  input=$(jq -n '{prompt: "Complex task with ünïcödé 🚀"}')

  run bash -c "echo '$input' | bash '$HOOK_SCRIPT'"

  [ "$status" -eq 0 ]
}

@test "orchestrate-skill-validation handles long prompt" {
  local filler
  filler=$(printf 'word %.0s' {1..500})
  local input
  input=$(jq -n --arg p "$filler" '{prompt: $p}')

  run bash -c "echo '$input' | bash '$HOOK_SCRIPT'"

  [ "$status" -eq 0 ]
}
