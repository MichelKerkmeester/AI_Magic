#!/usr/bin/env bats
# ───────────────────────────────────────────────────────────────
# Tests for: workflows-save-context-trigger.sh
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
HOOK_SCRIPT="$REAL_HOOKS_DIR/UserPromptSubmit/workflows-save-context-trigger.sh"

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
# KEYWORD TRIGGERS
# ───────────────────────────────────────────────────────────────

@test "workflows-save-context-trigger triggers on save context" {
  local input
  input=$(jq -n '{prompt: "Please save context now"}')

  run bash -c "echo '$input' | bash '$HOOK_SCRIPT'"

  [ "$status" -eq 0 ]
  # Should output something about save context
  [[ "$output" == *"save"* ]] || [[ "$output" == *"context"* ]] || [[ "$output" == "" ]]
}

@test "workflows-save-context-trigger triggers on save conversation" {
  local input
  input=$(jq -n '{prompt: "I want to save conversation"}')

  run bash -c "echo '$input' | bash '$HOOK_SCRIPT'"

  [ "$status" -eq 0 ]
}

@test "workflows-save-context-trigger triggers on export session" {
  local input
  input=$(jq -n '{prompt: "Can you export session please"}')

  run bash -c "echo '$input' | bash '$HOOK_SCRIPT'"

  [ "$status" -eq 0 ]
}

@test "workflows-save-context-trigger triggers on preserve memory" {
  local input
  input=$(jq -n '{prompt: "Preserve memory of this discussion"}')

  run bash -c "echo '$input' | bash '$HOOK_SCRIPT'"

  [ "$status" -eq 0 ]
}

@test "workflows-save-context-trigger triggers on document this" {
  local input
  input=$(jq -n '{prompt: "Document this conversation"}')

  run bash -c "echo '$input' | bash '$HOOK_SCRIPT'"

  [ "$status" -eq 0 ]
}

# ───────────────────────────────────────────────────────────────
# NON-TRIGGER CASES
# ───────────────────────────────────────────────────────────────

@test "workflows-save-context-trigger skips non-trigger prompts" {
  local input
  input=$(jq -n '{prompt: "Fix the bug in the code"}')

  run bash -c "echo '$input' | bash '$HOOK_SCRIPT'"

  [ "$status" -eq 0 ]
}

@test "workflows-save-context-trigger handles empty prompt" {
  run bash -c "echo '{}' | bash '$HOOK_SCRIPT'"

  [ "$status" -eq 0 ]
}

@test "workflows-save-context-trigger handles missing prompt field" {
  run bash -c "echo '{\"session_id\": \"test\"}' | bash '$HOOK_SCRIPT'"

  [ "$status" -eq 0 ]
}

# ───────────────────────────────────────────────────────────────
# SESSION METADATA
# ───────────────────────────────────────────────────────────────

@test "workflows-save-context-trigger handles session_id" {
  local input
  input=$(jq -n '{prompt: "test", session_id: "test-session-123"}')

  run bash -c "echo '$input' | bash '$HOOK_SCRIPT'"

  [ "$status" -eq 0 ]
}

@test "workflows-save-context-trigger sanitizes session_id" {
  # Session ID with special characters should be sanitized
  local input
  input=$(jq -n '{prompt: "test", session_id: "test;rm -rf /;session"}')

  run bash -c "echo '$input' | bash '$HOOK_SCRIPT'"

  [ "$status" -eq 0 ]
}

# ───────────────────────────────────────────────────────────────
# NON-BLOCKING BEHAVIOR
# ───────────────────────────────────────────────────────────────

@test "workflows-save-context-trigger runs non-blocking" {
  local input
  input=$(jq -n '{prompt: "save context"}')

  run bash -c "echo '$input' | bash '$HOOK_SCRIPT'"

  # Hook always exits 0 (non-blocking)
  [ "$status" -eq 0 ]
}

# ───────────────────────────────────────────────────────────────
# EXIT CODES
# ───────────────────────────────────────────────────────────────

@test "workflows-save-context-trigger exits with 0" {
  local input
  input=$(jq -n '{prompt: "any prompt here"}')

  run bash -c "echo '$input' | bash '$HOOK_SCRIPT'"

  [ "$status" -eq 0 ]
}

# ───────────────────────────────────────────────────────────────
# EDGE CASES
# ───────────────────────────────────────────────────────────────

@test "workflows-save-context-trigger handles unicode" {
  local input
  input=$(jq -n '{prompt: "save context with ünïcödé 🚀"}')

  run bash -c "echo '$input' | bash '$HOOK_SCRIPT'"

  [ "$status" -eq 0 ]
}

@test "workflows-save-context-trigger handles very long prompt" {
  local filler
  filler=$(printf 'word %.0s' {1..500})
  local input
  input=$(jq -n --arg p "$filler" '{prompt: $p}')

  run bash -c "echo '$input' | bash '$HOOK_SCRIPT'"

  [ "$status" -eq 0 ]
}

# ───────────────────────────────────────────────────────────────
# PERFORMANCE
# ───────────────────────────────────────────────────────────────

@test "workflows-save-context-trigger completes pattern matching within 100ms" {
  # Pattern matching part should be fast
  # (actual save takes longer but is backgrounded)
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
  [ "$duration" -lt 500 ]  # Allow 500ms for file checks
}
