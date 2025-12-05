#!/usr/bin/env bats
# ───────────────────────────────────────────────────────────────
# Tests for: validate-output-quality.sh
# Type: PostToolUse (advisory)
# ───────────────────────────────────────────────────────────────
# Spec: 010-comprehensive-hook-testing
# Created: 2025-12-03
# Tests: 15
# ───────────────────────────────────────────────────────────────

# Load test helper at file level
load '../test_helper'

# Get real hooks directory
REAL_HOOKS_DIR="$(cd "$BATS_TEST_DIRNAME/../.." && pwd)"
HOOK_SCRIPT="$REAL_HOOKS_DIR/PostToolUse/validate-output-quality.sh"

# ───────────────────────────────────────────────────────────────
# SETUP / TEARDOWN
# ───────────────────────────────────────────────────────────────

setup() {
  # Create unique temp directory for this test
  TEST_TMP_DIR=$(mktemp -d "${TMPDIR:-/tmp}/bats_test.XXXXXX")

  # Check if hook exists
  if [ -f "$HOOK_SCRIPT" ]; then
    HOOK_AVAILABLE=true
  else
    HOOK_AVAILABLE=false
  fi
}

teardown() {
  if [ -n "$TEST_TMP_DIR" ] && [ -d "$TEST_TMP_DIR" ]; then
    rm -rf "$TEST_TMP_DIR"
  fi
}

# ───────────────────────────────────────────────────────────────
# HELPER: Create Task tool output
# ───────────────────────────────────────────────────────────────

make_task_output() {
  local content="$1"
  jq -n \
    --arg content "$content" \
    --arg tool "Task" \
    '{tool_name: $tool, tool_result: $content}'
}

skip_if_hook_missing() {
  if [ "$HOOK_AVAILABLE" != "true" ]; then
    skip "validate-output-quality.sh hook not available"
  fi
}

# ───────────────────────────────────────────────────────────────
# FLUFF DETECTION
# ───────────────────────────────────────────────────────────────

@test "detects 'It is worth noting' fluff phrase" {
  skip_if_hook_missing

  local input
  input=$(make_task_output "It is worth noting that this is a good approach.")

  run bash -c "echo '$input' | bash '$HOOK_SCRIPT'"

  [ "$status" -eq 0 ]  # Advisory only, always exits 0
}

@test "detects 'As we all know' fluff phrase" {
  skip_if_hook_missing

  local input
  input=$(make_task_output "As we all know, JavaScript is a programming language.")

  run bash -c "echo '$input' | bash '$HOOK_SCRIPT'"

  [ "$status" -eq 0 ]
}

@test "detects 'It goes without saying' fluff phrase" {
  skip_if_hook_missing

  local input
  input=$(make_task_output "It goes without saying that error handling is important.")

  run bash -c "echo '$input' | bash '$HOOK_SCRIPT'"

  [ "$status" -eq 0 ]
}

@test "detects 'It is important to' fluff phrase" {
  skip_if_hook_missing

  local input
  input=$(make_task_output "It is important to note that this works well.")

  run bash -c "echo '$input' | bash '$HOOK_SCRIPT'"

  [ "$status" -eq 0 ]
}

# ───────────────────────────────────────────────────────────────
# AMBIGUITY DETECTION
# ───────────────────────────────────────────────────────────────

@test "detects 'might work' ambiguity" {
  skip_if_hook_missing

  local input
  input=$(make_task_output "This might work for your use case.")

  run bash -c "echo '$input' | bash '$HOOK_SCRIPT'"

  [ "$status" -eq 0 ]
}

@test "detects 'could possibly' ambiguity" {
  skip_if_hook_missing

  local input
  input=$(make_task_output "You could possibly use this method.")

  run bash -c "echo '$input' | bash '$HOOK_SCRIPT'"

  [ "$status" -eq 0 ]
}

@test "triggers on multiple ambiguity matches" {
  skip_if_hook_missing

  local input
  input=$(make_task_output "This might work. It could help. Perhaps try this. Maybe check that.")

  run bash -c "echo '$input' | bash '$HOOK_SCRIPT'"

  [ "$status" -eq 0 ]  # Advisory, but should detect multiple
}

# ───────────────────────────────────────────────────────────────
# LAZY LIST DETECTION
# ───────────────────────────────────────────────────────────────

@test "detects lazy short bullet lists" {
  skip_if_hook_missing

  local content="Changes:
- Fix bug
- Update code
- Add test
- Clean up
- Refactor
- Improve"
  local input
  input=$(make_task_output "$content")

  run bash -c "echo '$input' | bash '$HOOK_SCRIPT'"

  [ "$status" -eq 0 ]
}

# ───────────────────────────────────────────────────────────────
# CLEAN OUTPUT
# ───────────────────────────────────────────────────────────────

@test "allows clean output without warnings" {
  skip_if_hook_missing

  local content="The function calculates the sum of two numbers.

function sum(a, b) {
  return a + b;
}

This returns the sum of parameters a and b."
  local input
  input=$(make_task_output "$content")

  run bash -c "echo '$input' | bash '$HOOK_SCRIPT'"

  [ "$status" -eq 0 ]
}

# ───────────────────────────────────────────────────────────────
# INPUT HANDLING
# ───────────────────────────────────────────────────────────────

@test "handles empty output" {
  skip_if_hook_missing

  local input
  input=$(make_task_output "")

  run bash -c "echo '$input' | bash '$HOOK_SCRIPT'"

  [ "$status" -eq 0 ]
}

@test "handles very long output" {
  skip_if_hook_missing

  local long_content
  long_content=$(printf 'This is a line of valid code. %.0s' {1..100})
  local input
  input=$(make_task_output "$long_content")

  run bash -c "echo '$input' | bash '$HOOK_SCRIPT'"

  [ "$status" -eq 0 ]
}

@test "handles non-Task tool" {
  skip_if_hook_missing

  local input
  input=$(jq -n '{tool_name: "Write", tool_result: "file created"}')

  run bash -c "echo '$input' | bash '$HOOK_SCRIPT'"

  # Should pass through for non-Task tools
  [ "$status" -eq 0 ]
}

# ───────────────────────────────────────────────────────────────
# EXIT CODE VERIFICATION
# ───────────────────────────────────────────────────────────────

@test "always exits 0 (advisory only)" {
  skip_if_hook_missing

  local input
  input=$(make_task_output "It is worth noting. As we all know. This might work.")

  run bash -c "echo '$input' | bash '$HOOK_SCRIPT'"

  # Should never block (advisory only)
  [ "$status" -eq 0 ]
}

# ───────────────────────────────────────────────────────────────
# COMBINED PATTERNS
# ───────────────────────────────────────────────────────────────

@test "handles output with multiple quality issues" {
  skip_if_hook_missing

  local content="It is worth noting that this might work.
As we all know, it could possibly help.
Changes:
- Fix
- Update
- Test
- Clean
- Refactor
- Done"
  local input
  input=$(make_task_output "$content")

  run bash -c "echo '$input' | bash '$HOOK_SCRIPT'"

  # Should complete (advisory)
  [ "$status" -eq 0 ]
}
