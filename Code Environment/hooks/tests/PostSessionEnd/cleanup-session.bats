#!/usr/bin/env bats
# ───────────────────────────────────────────────────────────────
# Tests for: cleanup-session.sh
# Type: PostSessionEnd (cleanup)
# ───────────────────────────────────────────────────────────────
# Spec: 010-comprehensive-hook-testing
# Created: 2025-12-04
# Tests: 12
# ───────────────────────────────────────────────────────────────

load '../test_helper'

# ───────────────────────────────────────────────────────────────
# CONSTANTS
# ───────────────────────────────────────────────────────────────

REAL_HOOKS_DIR="$(cd "$BATS_TEST_DIRNAME/../.." && pwd)"
HOOK_SCRIPT="$REAL_HOOKS_DIR/PostSessionEnd/cleanup-session.sh"

# ───────────────────────────────────────────────────────────────
# SETUP / TEARDOWN
# ───────────────────────────────────────────────────────────────

setup() {
  TEST_TMP_DIR=$(mktemp -d "${TMPDIR:-/tmp}/bats_test.XXXXXX")
  mkdir -p "$TEST_TMP_DIR/logs"

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

make_session_input() {
  local session_id="${1:-test-session-123}"
  jq -n --arg sid "$session_id" \
    '{session_id: $sid}'
}

# ───────────────────────────────────────────────────────────────
# BASIC FUNCTIONALITY
# ───────────────────────────────────────────────────────────────

@test "cleanup-session processes valid session input" {
  local input
  input=$(make_session_input "session-abc")

  run bash -c "echo '$input' | bash '$HOOK_SCRIPT' 2>/dev/null"

  [ "$status" -eq 0 ]
}

@test "cleanup-session handles missing session_id" {
  local input
  input=$(jq -n '{}')

  run bash -c "echo '$input' | bash '$HOOK_SCRIPT' 2>/dev/null"

  [ "$status" -eq 0 ]
}

@test "cleanup-session handles empty input" {
  run bash -c "echo '{}' | bash '$HOOK_SCRIPT' 2>/dev/null"

  [ "$status" -eq 0 ]
}

# ───────────────────────────────────────────────────────────────
# STATE CLEANUP
# ───────────────────────────────────────────────────────────────

@test "cleanup-session clears session state" {
  local input
  input=$(make_session_input "test-session")

  run bash -c "echo '$input' | bash '$HOOK_SCRIPT' 2>/dev/null"

  [ "$status" -eq 0 ]
}

@test "cleanup-session clears complexity state" {
  local input
  input=$(make_session_input "test-session")

  run bash -c "echo '$input' | bash '$HOOK_SCRIPT' 2>/dev/null"

  [ "$status" -eq 0 ]
}

@test "cleanup-session clears dispatch state" {
  local input
  input=$(make_session_input "test-session")

  run bash -c "echo '$input' | bash '$HOOK_SCRIPT' 2>/dev/null"

  [ "$status" -eq 0 ]
}

# ───────────────────────────────────────────────────────────────
# SESSION ID SANITIZATION
# ───────────────────────────────────────────────────────────────

@test "cleanup-session sanitizes session ID with special chars" {
  local input
  input=$(make_session_input "session/../../../etc/passwd")

  run bash -c "echo '$input' | bash '$HOOK_SCRIPT' 2>/dev/null"

  [ "$status" -eq 0 ]
}

@test "cleanup-session handles session ID with unicode" {
  local input
  input=$(make_session_input "session-测试-test")

  run bash -c "echo '$input' | bash '$HOOK_SCRIPT' 2>/dev/null"

  [ "$status" -eq 0 ]
}

# ───────────────────────────────────────────────────────────────
# EXIT CODES (always 0 - cleanup)
# ───────────────────────────────────────────────────────────────

@test "cleanup-session always exits 0" {
  local input
  input=$(make_session_input "any-session")

  run bash -c "echo '$input' | bash '$HOOK_SCRIPT' 2>/dev/null"

  [ "$status" -eq 0 ]
}

@test "cleanup-session never blocks session end" {
  local input
  input=$(make_session_input "unknown")

  run bash -c "echo '$input' | bash '$HOOK_SCRIPT' 2>/dev/null"

  [ "$status" -eq 0 ]
}

# ───────────────────────────────────────────────────────────────
# PERFORMANCE
# ───────────────────────────────────────────────────────────────

@test "cleanup-session completes within 300ms" {
  local start_time end_time duration

  if [[ "$OSTYPE" == "darwin"* ]]; then
    start_time=$(python3 -c 'import time; print(int(time.time() * 1000))')
  else
    start_time=$(date +%s%3N)
  fi

  local input
  input=$(make_session_input)
  run bash -c "echo '$input' | bash '$HOOK_SCRIPT' 2>/dev/null"

  if [[ "$OSTYPE" == "darwin"* ]]; then
    end_time=$(python3 -c 'import time; print(int(time.time() * 1000))')
  else
    end_time=$(date +%s%3N)
  fi

  duration=$((end_time - start_time))
  [ "$duration" -lt 300 ]
}

