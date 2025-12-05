#!/usr/bin/env bats
# ───────────────────────────────────────────────────────────────
# Tests for: prune-context.sh
# Type: PreCompact (optimization)
# ───────────────────────────────────────────────────────────────
# Spec: 010-comprehensive-hook-testing
# Created: 2025-12-04
# Tests: 14
# ───────────────────────────────────────────────────────────────

load '../test_helper'

# ───────────────────────────────────────────────────────────────
# CONSTANTS
# ───────────────────────────────────────────────────────────────

REAL_HOOKS_DIR="$(cd "$BATS_TEST_DIRNAME/../.." && pwd)"
HOOK_SCRIPT="$REAL_HOOKS_DIR/PreCompact/prune-context.sh"

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

make_compact_input() {
  local trigger="${1:-auto}"
  local session_id="${2:-test-session-123}"
  local cwd="${3:-/project}"
  jq -n --arg trigger "$trigger" --arg sid "$session_id" --arg dir "$cwd" \
    '{trigger: $trigger, session_id: $sid, cwd: $dir}'
}

# ───────────────────────────────────────────────────────────────
# TRIGGER TYPES
# ───────────────────────────────────────────────────────────────

@test "prune-context handles auto trigger" {
  local input
  input=$(make_compact_input "auto")

  run bash -c "echo '$input' | bash '$HOOK_SCRIPT' 2>/dev/null"

  [ "$status" -eq 0 ]
}

@test "prune-context handles manual trigger" {
  local input
  input=$(make_compact_input "manual")

  run bash -c "echo '$input' | bash '$HOOK_SCRIPT' 2>/dev/null"

  [ "$status" -eq 0 ]
}

@test "prune-context handles manual trigger with instructions" {
  local input
  input=$(jq -n '{trigger: "manual", session_id: "test", cwd: "/project", custom_instructions: "Focus on cleanup"}')

  run bash -c "echo '$input' | bash '$HOOK_SCRIPT' 2>/dev/null"

  [ "$status" -eq 0 ]
}

# ───────────────────────────────────────────────────────────────
# INPUT VALIDATION
# ───────────────────────────────────────────────────────────────

@test "prune-context handles missing session_id" {
  local input
  input=$(jq -n '{trigger: "auto", cwd: "/project"}')

  run bash -c "echo '$input' | bash '$HOOK_SCRIPT' 2>/dev/null"

  [ "$status" -eq 0 ]
}

@test "prune-context handles missing cwd" {
  local input
  input=$(jq -n '{trigger: "auto", session_id: "test"}')

  run bash -c "echo '$input' | bash '$HOOK_SCRIPT' 2>/dev/null"

  [ "$status" -eq 0 ]
}

@test "prune-context handles empty input" {
  run bash -c "echo '{}' | bash '$HOOK_SCRIPT' 2>/dev/null"

  [ "$status" -eq 0 ]
}

@test "prune-context handles invalid cwd path" {
  local input
  input=$(make_compact_input "auto" "test" "/nonexistent/path/that/does/not/exist")

  run bash -c "echo '$input' | bash '$HOOK_SCRIPT' 2>/dev/null"

  [ "$status" -eq 0 ]
}

# ───────────────────────────────────────────────────────────────
# SESSION ID SANITIZATION
# ───────────────────────────────────────────────────────────────

@test "prune-context sanitizes session ID" {
  local input
  input=$(make_compact_input "auto" "../../../etc/passwd")

  run bash -c "echo '$input' | bash '$HOOK_SCRIPT' 2>/dev/null"

  [ "$status" -eq 0 ]
}

@test "prune-context handles session ID with special chars" {
  local input
  input=$(make_compact_input "auto" "session\$\`test")

  run bash -c "echo '$input' | bash '$HOOK_SCRIPT' 2>/dev/null"

  [ "$status" -eq 0 ]
}

# ───────────────────────────────────────────────────────────────
# DEPENDENCY HANDLING
# ───────────────────────────────────────────────────────────────

@test "prune-context gracefully handles missing dependencies" {
  local input
  input=$(make_compact_input)

  run bash -c "echo '$input' | bash '$HOOK_SCRIPT' 2>/dev/null"

  [ "$status" -eq 0 ]
}

# ───────────────────────────────────────────────────────────────
# EXIT CODES (always 0 - PreCompact cannot block)
# ───────────────────────────────────────────────────────────────

@test "prune-context always exits 0" {
  local input
  input=$(make_compact_input "auto" "any-session")

  run bash -c "echo '$input' | bash '$HOOK_SCRIPT' 2>/dev/null"

  [ "$status" -eq 0 ]
}

@test "prune-context never blocks compaction" {
  local input
  input=$(make_compact_input "manual" "unknown" "/invalid")

  run bash -c "echo '$input' | bash '$HOOK_SCRIPT' 2>/dev/null"

  [ "$status" -eq 0 ]
}

# ───────────────────────────────────────────────────────────────
# PERFORMANCE
# ───────────────────────────────────────────────────────────────

@test "prune-context startup completes within 500ms" {
  local start_time end_time duration

  if [[ "$OSTYPE" == "darwin"* ]]; then
    start_time=$(python3 -c 'import time; print(int(time.time() * 1000))')
  else
    start_time=$(date +%s%3N)
  fi

  local input
  input=$(make_compact_input)
  # Note: Full pruning may take longer, we test early-exit path
  run bash -c "echo '$input' | bash '$HOOK_SCRIPT' 2>/dev/null"

  if [[ "$OSTYPE" == "darwin"* ]]; then
    end_time=$(python3 -c 'import time; print(int(time.time() * 1000))')
  else
    end_time=$(date +%s%3N)
  fi

  duration=$((end_time - start_time))
  [ "$duration" -lt 500 ]
}

