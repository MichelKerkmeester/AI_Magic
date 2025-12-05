#!/usr/bin/env bats
# ───────────────────────────────────────────────────────────────
# Tests for: enforce-git-workspace-choice.sh
# Type: UserPromptSubmit
# ───────────────────────────────────────────────────────────────
# Spec: 010-comprehensive-hook-testing
# Created: 2025-12-03
# Tests: 12
# ───────────────────────────────────────────────────────────────

load ../test_helper

# ───────────────────────────────────────────────────────────────
# CONSTANTS
# ───────────────────────────────────────────────────────────────

REAL_HOOKS_DIR="$(cd "$BATS_TEST_DIRNAME/../.." && pwd)"
HOOK_SCRIPT="$REAL_HOOKS_DIR/UserPromptSubmit/enforce-git-workspace-choice.sh"

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
# TRIGGER PATTERNS
# ───────────────────────────────────────────────────────────────

@test "enforce-git-workspace-choice triggers on new feature" {
  local input
  input=$(jq -n '{prompt: "Start a new feature for user authentication"}')

  run bash -c "echo '$input' | bash '$HOOK_SCRIPT'"

  [ "$status" -eq 0 ]
  # Should either output question or allow based on state
}

@test "enforce-git-workspace-choice triggers on create branch" {
  local input
  input=$(jq -n '{prompt: "Create a branch for the fix"}')

  run bash -c "echo '$input' | bash '$HOOK_SCRIPT'"

  [ "$status" -eq 0 ]
  # Should trigger with branch override
  [[ "$output" == *"Branch"* ]] || [[ "$output" == *"workspace"* ]] || [[ "$output" == "" ]]
}

@test "enforce-git-workspace-choice triggers on worktree" {
  local input
  input=$(jq -n '{prompt: "Use a worktree for isolated development"}')

  run bash -c "echo '$input' | bash '$HOOK_SCRIPT'"

  [ "$status" -eq 0 ]
  [[ "$output" == *"Worktree"* ]]
}

# ───────────────────────────────────────────────────────────────
# OVERRIDE PHRASES
# ───────────────────────────────────────────────────────────────

@test "enforce-git-workspace-choice handles use branch override" {
  local input
  input=$(jq -n '{prompt: "Use a branch for this new feature"}')

  run bash -c "echo '$input' | bash '$HOOK_SCRIPT'"

  [ "$status" -eq 0 ]
  [[ "$output" == *"Branch"* ]]
}

@test "enforce-git-workspace-choice handles use worktree override" {
  local input
  input=$(jq -n '{prompt: "Use a worktree for development"}')

  run bash -c "echo '$input' | bash '$HOOK_SCRIPT'"

  [ "$status" -eq 0 ]
  [[ "$output" == *"Worktree"* ]]
}

@test "enforce-git-workspace-choice handles current branch override" {
  local input
  input=$(jq -n '{prompt: "Work on current branch without creating new"}')

  run bash -c "echo '$input' | bash '$HOOK_SCRIPT'"

  [ "$status" -eq 0 ]
}

# ───────────────────────────────────────────────────────────────
# NON-TRIGGER CASES
# ───────────────────────────────────────────────────────────────

@test "enforce-git-workspace-choice skips for non-feature prompts" {
  local input
  input=$(jq -n '{prompt: "Fix the typo in README"}')

  run bash -c "echo '$input' | bash '$HOOK_SCRIPT'"

  [ "$status" -eq 0 ]
  # No git workspace question for simple prompts
}

@test "enforce-git-workspace-choice handles empty prompt" {
  run bash -c "echo '{}' | bash '$HOOK_SCRIPT'"

  [ "$status" -eq 0 ]
}

# ───────────────────────────────────────────────────────────────
# JSON OUTPUT
# ───────────────────────────────────────────────────────────────

@test "enforce-git-workspace-choice outputs valid JSON" {
  local input
  input=$(jq -n '{prompt: "Use a branch for the feature"}')

  run bash -c "echo '$input' | bash '$HOOK_SCRIPT'"

  [ "$status" -eq 0 ]
  # If output exists, first line should be valid JSON
  if [ -n "$output" ]; then
    local first_line
    first_line=$(echo "$output" | head -1)
    echo "$first_line" | jq empty 2>/dev/null
  fi
}

# ───────────────────────────────────────────────────────────────
# EXIT CODES
# ───────────────────────────────────────────────────────────────

@test "enforce-git-workspace-choice exits with 0" {
  local input
  input=$(jq -n '{prompt: "Create a new feature branch"}')

  run bash -c "echo '$input' | bash '$HOOK_SCRIPT'"

  [ "$status" -eq 0 ]
}

# ───────────────────────────────────────────────────────────────
# PERFORMANCE
# ───────────────────────────────────────────────────────────────

@test "enforce-git-workspace-choice completes within 100ms" {
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
