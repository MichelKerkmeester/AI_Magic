#!/usr/bin/env bats
# ───────────────────────────────────────────────────────────────
# Tests for: enforce-verification.sh
# Type: UserPromptSubmit (BLOCKING)
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
HOOK_SCRIPT="$REAL_HOOKS_DIR/UserPromptSubmit/enforce-verification.sh"

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
# BLOCKING: Completion Claims Without Evidence
# ───────────────────────────────────────────────────────────────

@test "enforce-verification blocks I have completed" {
  local input
  input=$(jq -n '{prompt: "I have completed the animation fix"}')

  run bash -c "echo '$input' | bash '$HOOK_SCRIPT'"

  [ "$status" -eq 1 ]
  [[ "$output" == *"BLOCKED"* ]] || [[ "$output" == *"Verification"* ]]
}

@test "enforce-verification blocks the feature is done" {
  local input
  input=$(jq -n '{prompt: "The feature is done now"}')

  run bash -c "echo '$input' | bash '$HOOK_SCRIPT'"

  [ "$status" -eq 1 ]
}

@test "enforce-verification blocks Done standalone" {
  local input
  input=$(jq -n '{prompt: "Done."}')

  run bash -c "echo '$input' | bash '$HOOK_SCRIPT'"

  [ "$status" -eq 1 ]
}

@test "enforce-verification blocks implementation complete" {
  local input
  # Pattern requires "I have completed" or "I successfully implemented" (no words in between)
  input=$(jq -n '{prompt: "I successfully implemented the changes"}')

  run bash -c "echo '$input' | bash '$HOOK_SCRIPT'"

  [ "$status" -eq 1 ]
}

# ───────────────────────────────────────────────────────────────
# ALLOWING: Future Tense / Instructions
# ───────────────────────────────────────────────────────────────

@test "enforce-verification allows I will complete" {
  local input
  input=$(jq -n '{prompt: "I will complete the animation fix"}')

  run bash -c "echo '$input' | bash '$HOOK_SCRIPT'"

  [ "$status" -eq 0 ]
}

@test "enforce-verification allows should I complete" {
  local input
  input=$(jq -n '{prompt: "Should I complete the feature now?"}')

  run bash -c "echo '$input' | bash '$HOOK_SCRIPT'"

  [ "$status" -eq 0 ]
}

@test "enforce-verification allows to complete this" {
  local input
  input=$(jq -n '{prompt: "I need to complete this task first"}')

  run bash -c "echo '$input' | bash '$HOOK_SCRIPT'"

  [ "$status" -eq 0 ]
}

@test "enforce-verification allows might be complete" {
  local input
  input=$(jq -n '{prompt: "It might be complete after the fix"}')

  run bash -c "echo '$input' | bash '$HOOK_SCRIPT'"

  [ "$status" -eq 0 ]
}

@test "enforce-verification allows analyze instruction" {
  local input
  input=$(jq -n '{prompt: "Analyze the code and fix any issues"}')

  run bash -c "echo '$input' | bash '$HOOK_SCRIPT'"

  [ "$status" -eq 0 ]
}

# ───────────────────────────────────────────────────────────────
# ALLOWING: With Verification Evidence
# ───────────────────────────────────────────────────────────────

@test "enforce-verification allows completion with browser testing evidence" {
  local input
  input=$(jq -n '{prompt: "I have completed the fix. Tested in Chrome at 1920px and 375px, DevTools console is clear, saw the animation smooth"}')

  run bash -c "echo '$input' | bash '$HOOK_SCRIPT'"

  [ "$status" -eq 0 ]
}

# ───────────────────────────────────────────────────────────────
# EDGE CASES
# ───────────────────────────────────────────────────────────────

@test "enforce-verification handles empty prompt" {
  run bash -c "echo '{}' | bash '$HOOK_SCRIPT'"

  [ "$status" -eq 0 ]
}

@test "enforce-verification handles missing prompt field" {
  run bash -c "echo '{\"session_id\": \"test\"}' | bash '$HOOK_SCRIPT'"

  [ "$status" -eq 0 ]
}

@test "enforce-verification allows negation patterns" {
  local input
  input=$(jq -n '{prompt: "It is not working correctly yet"}')

  run bash -c "echo '$input' | bash '$HOOK_SCRIPT'"

  [ "$status" -eq 0 ]
}

# ───────────────────────────────────────────────────────────────
# EXIT CODES
# ───────────────────────────────────────────────────────────────

@test "enforce-verification exits with 1 when blocking" {
  local input
  input=$(jq -n '{prompt: "Everything is done"}')

  run bash -c "echo '$input' | bash '$HOOK_SCRIPT'"

  [ "$status" -eq 1 ]
}

@test "enforce-verification exits with 0 when allowing" {
  local input
  input=$(jq -n '{prompt: "Please fix the bug in the code"}')

  run bash -c "echo '$input' | bash '$HOOK_SCRIPT'"

  [ "$status" -eq 0 ]
}
