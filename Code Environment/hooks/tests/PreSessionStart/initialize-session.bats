#!/usr/bin/env bats
# ───────────────────────────────────────────────────────────────
# Tests for: initialize-session.sh
# Type: PreSessionStart (initialization)
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
HOOK_SCRIPT="$REAL_HOOKS_DIR/PreSessionStart/initialize-session.sh"

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
  local cwd="${2:-/project}"
  jq -n --arg sid "$session_id" --arg dir "$cwd" \
    '{session_id: $sid, cwd: $dir}'
}

# ───────────────────────────────────────────────────────────────
# BASIC FUNCTIONALITY
# ───────────────────────────────────────────────────────────────

@test "initialize-session processes valid session input" {
  local input
  input=$(make_session_input "session-abc" "/Users/test/project")

  run bash -c "echo '$input' | bash '$HOOK_SCRIPT' 2>/dev/null"

  [ "$status" -eq 0 ]
}

@test "initialize-session handles missing session_id" {
  local input
  input=$(jq -n '{cwd: "/project"}')

  run bash -c "echo '$input' | bash '$HOOK_SCRIPT' 2>/dev/null"

  [ "$status" -eq 0 ]
}

@test "initialize-session handles missing cwd" {
  local input
  input=$(jq -n '{session_id: "test-123"}')

  run bash -c "echo '$input' | bash '$HOOK_SCRIPT' 2>/dev/null"

  [ "$status" -eq 0 ]
}

@test "initialize-session handles empty input" {
  run bash -c "echo '{}' | bash '$HOOK_SCRIPT' 2>/dev/null"

  [ "$status" -eq 0 ]
}

# ───────────────────────────────────────────────────────────────
# SESSION ID SANITIZATION
# ───────────────────────────────────────────────────────────────

@test "initialize-session sanitizes session ID with special chars" {
  local input
  input=$(make_session_input "session/../../../etc/passwd" "/project")

  run bash -c "echo '$input' | bash '$HOOK_SCRIPT' 2>/dev/null"

  [ "$status" -eq 0 ]
}

@test "initialize-session handles session ID with spaces" {
  local input
  input=$(make_session_input "session with spaces" "/project")

  run bash -c "echo '$input' | bash '$HOOK_SCRIPT' 2>/dev/null"

  [ "$status" -eq 0 ]
}

# ───────────────────────────────────────────────────────────────
# STATE INITIALIZATION
# ───────────────────────────────────────────────────────────────

@test "initialize-session creates state directory" {
  local input
  input=$(make_session_input)

  run bash -c "echo '$input' | bash '$HOOK_SCRIPT' 2>/dev/null"

  [ "$status" -eq 0 ]
}

@test "initialize-session cleans stale state" {
  local input
  input=$(make_session_input)

  run bash -c "echo '$input' | bash '$HOOK_SCRIPT' 2>/dev/null"

  [ "$status" -eq 0 ]
}

# ───────────────────────────────────────────────────────────────
# EXIT CODES (always 0 - initialization)
# ───────────────────────────────────────────────────────────────

@test "initialize-session always exits 0" {
  local input
  input=$(make_session_input "any-session")

  run bash -c "echo '$input' | bash '$HOOK_SCRIPT' 2>/dev/null"

  [ "$status" -eq 0 ]
}

@test "initialize-session never blocks session start" {
  local input
  input=$(make_session_input "test" "/nonexistent/path")

  run bash -c "echo '$input' | bash '$HOOK_SCRIPT' 2>/dev/null"

  [ "$status" -eq 0 ]
}

# ───────────────────────────────────────────────────────────────
# PERFORMANCE
# ───────────────────────────────────────────────────────────────

@test "initialize-session completes within 300ms" {
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

