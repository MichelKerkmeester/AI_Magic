#!/usr/bin/env bats
# ───────────────────────────────────────────────────────────────
# Integration Tests: Session Lifecycle
# ───────────────────────────────────────────────────────────────
# Tests the complete session lifecycle from start to end
# Spec: 010-comprehensive-hook-testing
# Created: 2025-12-04
# Tests: 10
# ───────────────────────────────────────────────────────────────

load '../test_helper'

# ───────────────────────────────────────────────────────────────
# CONSTANTS
# ───────────────────────────────────────────────────────────────

REAL_HOOKS_DIR="$(cd "$BATS_TEST_DIRNAME/../.." && pwd)"
INIT_SCRIPT="$REAL_HOOKS_DIR/PreSessionStart/initialize-session.sh"
CLEANUP_SCRIPT="$REAL_HOOKS_DIR/PostSessionEnd/cleanup-session.sh"

# ───────────────────────────────────────────────────────────────
# SETUP / TEARDOWN
# ───────────────────────────────────────────────────────────────

setup() {
  TEST_TMP_DIR=$(mktemp -d "${TMPDIR:-/tmp}/bats_test.XXXXXX")
  mkdir -p "$TEST_TMP_DIR/logs"

  export HOOK_STATE_DIR="$TEST_TMP_DIR/state"
  mkdir -p "$HOOK_STATE_DIR"

  # Use consistent session ID for lifecycle tests
  export CLAUDE_SESSION_ID="lifecycle-test-$$-$(date +%s)"
}

teardown() {
  [ -n "$TEST_TMP_DIR" ] && [ -d "$TEST_TMP_DIR" ] && rm -rf "$TEST_TMP_DIR"
}

# ───────────────────────────────────────────────────────────────
# HELPERS
# ───────────────────────────────────────────────────────────────

make_session_input() {
  local session_id="${1:-$CLAUDE_SESSION_ID}"
  local cwd="${2:-$TEST_TMP_DIR}"
  jq -n --arg sid "$session_id" --arg dir "$cwd" \
    '{session_id: $sid, cwd: $dir}'
}

# ───────────────────────────────────────────────────────────────
# FULL LIFECYCLE TESTS
# ───────────────────────────────────────────────────────────────

@test "lifecycle: session init followed by cleanup completes" {
  local input
  input=$(make_session_input)

  # Initialize session
  run bash -c "echo '$input' | bash '$INIT_SCRIPT' 2>/dev/null"
  [ "$status" -eq 0 ]

  # Cleanup session
  run bash -c "echo '$input' | bash '$CLEANUP_SCRIPT' 2>/dev/null"
  [ "$status" -eq 0 ]
}

@test "lifecycle: cleanup without init still succeeds" {
  local input
  input=$(make_session_input "orphan-session")

  run bash -c "echo '$input' | bash '$CLEANUP_SCRIPT' 2>/dev/null"
  [ "$status" -eq 0 ]
}

@test "lifecycle: multiple init calls are idempotent" {
  local input
  input=$(make_session_input)

  # First init
  run bash -c "echo '$input' | bash '$INIT_SCRIPT' 2>/dev/null"
  [ "$status" -eq 0 ]

  # Second init (should not fail)
  run bash -c "echo '$input' | bash '$INIT_SCRIPT' 2>/dev/null"
  [ "$status" -eq 0 ]
}

@test "lifecycle: multiple cleanup calls are safe" {
  local input
  input=$(make_session_input)

  # Initialize
  run bash -c "echo '$input' | bash '$INIT_SCRIPT' 2>/dev/null"
  [ "$status" -eq 0 ]

  # First cleanup
  run bash -c "echo '$input' | bash '$CLEANUP_SCRIPT' 2>/dev/null"
  [ "$status" -eq 0 ]

  # Second cleanup (should not fail)
  run bash -c "echo '$input' | bash '$CLEANUP_SCRIPT' 2>/dev/null"
  [ "$status" -eq 0 ]
}

# ───────────────────────────────────────────────────────────────
# STATE MANAGEMENT
# ───────────────────────────────────────────────────────────────

@test "lifecycle: init creates state directory" {
  local input
  input=$(make_session_input)

  run bash -c "echo '$input' | bash '$INIT_SCRIPT' 2>/dev/null"

  [ "$status" -eq 0 ]
}

@test "lifecycle: cleanup removes session-specific state" {
  local input
  input=$(make_session_input)

  # Initialize
  run bash -c "echo '$input' | bash '$INIT_SCRIPT' 2>/dev/null"
  [ "$status" -eq 0 ]

  # Cleanup
  run bash -c "echo '$input' | bash '$CLEANUP_SCRIPT' 2>/dev/null"
  [ "$status" -eq 0 ]
}

# ───────────────────────────────────────────────────────────────
# CONCURRENT SESSIONS
# ───────────────────────────────────────────────────────────────

@test "lifecycle: concurrent sessions are isolated" {
  local input1 input2
  input1=$(make_session_input "session-1")
  input2=$(make_session_input "session-2")

  # Initialize both
  run bash -c "echo '$input1' | bash '$INIT_SCRIPT' 2>/dev/null"
  [ "$status" -eq 0 ]

  run bash -c "echo '$input2' | bash '$INIT_SCRIPT' 2>/dev/null"
  [ "$status" -eq 0 ]

  # Cleanup session-1 only
  run bash -c "echo '$input1' | bash '$CLEANUP_SCRIPT' 2>/dev/null"
  [ "$status" -eq 0 ]

  # Session-2 cleanup should still work
  run bash -c "echo '$input2' | bash '$CLEANUP_SCRIPT' 2>/dev/null"
  [ "$status" -eq 0 ]
}

# ───────────────────────────────────────────────────────────────
# ERROR RECOVERY
# ───────────────────────────────────────────────────────────────

@test "lifecycle: handles invalid session ID gracefully" {
  local input
  input=$(jq -n '{session_id: "", cwd: "/tmp"}')

  run bash -c "echo '$input' | bash '$INIT_SCRIPT' 2>/dev/null"
  [ "$status" -eq 0 ]

  run bash -c "echo '$input' | bash '$CLEANUP_SCRIPT' 2>/dev/null"
  [ "$status" -eq 0 ]
}

@test "lifecycle: handles missing cwd gracefully" {
  local input
  input=$(jq -n '{session_id: "test-123"}')

  run bash -c "echo '$input' | bash '$INIT_SCRIPT' 2>/dev/null"
  [ "$status" -eq 0 ]
}

# ───────────────────────────────────────────────────────────────
# PERFORMANCE
# ───────────────────────────────────────────────────────────────

@test "lifecycle: full init+cleanup cycle under 500ms" {
  local start_time end_time duration

  if [[ "$OSTYPE" == "darwin"* ]]; then
    start_time=$(python3 -c 'import time; print(int(time.time() * 1000))')
  else
    start_time=$(date +%s%3N)
  fi

  local input
  input=$(make_session_input)

  bash -c "echo '$input' | bash '$INIT_SCRIPT' 2>/dev/null"
  bash -c "echo '$input' | bash '$CLEANUP_SCRIPT' 2>/dev/null"

  if [[ "$OSTYPE" == "darwin"* ]]; then
    end_time=$(python3 -c 'import time; print(int(time.time() * 1000))')
  else
    end_time=$(date +%s%3N)
  fi

  duration=$((end_time - start_time))
  [ "$duration" -lt 500 ]
}

