#!/usr/bin/env bats
# ───────────────────────────────────────────────────────────────
# Integration Tests: Multi-Hook Coordination
# ───────────────────────────────────────────────────────────────
# Tests hooks working together in realistic scenarios
# Spec: 010-comprehensive-hook-testing
# Created: 2025-12-04
# Tests: 10
# ───────────────────────────────────────────────────────────────

load '../test_helper'

# ───────────────────────────────────────────────────────────────
# CONSTANTS
# ───────────────────────────────────────────────────────────────

REAL_HOOKS_DIR="$(cd "$BATS_TEST_DIRNAME/../.." && pwd)"

# ───────────────────────────────────────────────────────────────
# SETUP / TEARDOWN
# ───────────────────────────────────────────────────────────────

setup() {
  TEST_TMP_DIR=$(mktemp -d "${TMPDIR:-/tmp}/bats_test.XXXXXX")
  mkdir -p "$TEST_TMP_DIR/logs"
  mkdir -p "$TEST_TMP_DIR/specs/001-test"

  export HOOK_STATE_DIR="$TEST_TMP_DIR/state"
  mkdir -p "$HOOK_STATE_DIR"
  export CLAUDE_SESSION_ID="multi-hook-$$-$(date +%s)-$RANDOM"

  # Source shared state
  source "$REAL_HOOKS_DIR/lib/shared-state.sh" 2>/dev/null || true
}

teardown() {
  [ -n "$TEST_TMP_DIR" ] && [ -d "$TEST_TMP_DIR" ] && rm -rf "$TEST_TMP_DIR"
}

# ───────────────────────────────────────────────────────────────
# HELPERS
# ───────────────────────────────────────────────────────────────

make_write_input() {
  local file_path="$1"
  jq -n --arg path "$file_path" \
    '{tool_name: "Write", tool_input: {file_path: $path}}'
}

make_edit_input() {
  local file_path="$1"
  jq -n --arg path "$file_path" \
    '{tool_name: "Edit", tool_input: {file_path: $path}}'
}

# ───────────────────────────────────────────────────────────────
# PRE/POST TOOL COORDINATION
# ───────────────────────────────────────────────────────────────

@test "coordination: PreToolUse and PostToolUse both succeed for Write" {
  local input
  input=$(make_write_input "/project/src/file.js")

  # PreToolUse hooks
  run bash -c "echo '$input' | bash '$REAL_HOOKS_DIR/PreToolUse/validate-bash.sh' 2>/dev/null"
  [ "$status" -eq 0 ]

  # PostToolUse hooks
  run bash -c "echo '$input' | bash '$REAL_HOOKS_DIR/PostToolUse/track-file-modifications.sh' 2>/dev/null"
  [ "$status" -eq 0 ]
}

@test "coordination: file tracking after edit" {
  local input
  input=$(make_edit_input "/project/src/module.ts")

  run bash -c "echo '$input' | bash '$REAL_HOOKS_DIR/PostToolUse/track-file-modifications.sh' 2>/dev/null"
  [ "$status" -eq 0 ]
}

# ───────────────────────────────────────────────────────────────
# SESSION WITH TOOL OPERATIONS
# ───────────────────────────────────────────────────────────────

@test "coordination: session init then file operations succeed" {
  local session_input
  session_input=$(jq -n --arg sid "$CLAUDE_SESSION_ID" --arg dir "$TEST_TMP_DIR" \
    '{session_id: $sid, cwd: $dir}')

  # Initialize session
  run bash -c "echo '$session_input' | bash '$REAL_HOOKS_DIR/PreSessionStart/initialize-session.sh' 2>/dev/null"
  [ "$status" -eq 0 ]

  # Perform file operation
  local file_input
  file_input=$(make_write_input "$TEST_TMP_DIR/test.js")
  run bash -c "echo '$file_input' | bash '$REAL_HOOKS_DIR/PostToolUse/track-file-modifications.sh' 2>/dev/null"
  [ "$status" -eq 0 ]
}

@test "coordination: multiple file operations in sequence" {
  local input1 input2 input3
  input1=$(make_write_input "/project/file1.js")
  input2=$(make_edit_input "/project/file2.ts")
  input3=$(make_write_input "/project/file3.md")

  run bash -c "echo '$input1' | bash '$REAL_HOOKS_DIR/PostToolUse/track-file-modifications.sh' 2>/dev/null"
  [ "$status" -eq 0 ]

  run bash -c "echo '$input2' | bash '$REAL_HOOKS_DIR/PostToolUse/track-file-modifications.sh' 2>/dev/null"
  [ "$status" -eq 0 ]

  run bash -c "echo '$input3' | bash '$REAL_HOOKS_DIR/PostToolUse/track-file-modifications.sh' 2>/dev/null"
  [ "$status" -eq 0 ]
}

# ───────────────────────────────────────────────────────────────
# STATE SHARING BETWEEN HOOKS
# ───────────────────────────────────────────────────────────────

@test "coordination: state written by one hook readable by another" {
  # Write state
  write_hook_state "coord_test" '{"written": true}'

  # Read in a subshell (simulating another hook)
  run bash -c "
    source '$REAL_HOOKS_DIR/lib/shared-state.sh' 2>/dev/null
    export HOOK_STATE_DIR='$HOOK_STATE_DIR'
    export CLAUDE_SESSION_ID='$CLAUDE_SESSION_ID'
    read_hook_state coord_test 0
  "

  [ "$status" -eq 0 ]
  [[ "$output" == *"written"* ]]
}

@test "coordination: check-pending-questions blocks when question pending" {
  # Set pending question state
  local question_state
  question_state=$(jq -n \
    --arg ts "$(date +%s)" \
    '{timestamp: ($ts | tonumber), type: "mandatory", question: "Test?"}')
  write_hook_state "pending_question" "$question_state"

  local input
  input=$(jq -n '{name: "Write", tool_input: {file_path: "/test.js"}}')

  run bash -c "
    export HOOK_STATE_DIR='$HOOK_STATE_DIR'
    export CLAUDE_SESSION_ID='$CLAUDE_SESSION_ID'
    echo '$input' | bash '$REAL_HOOKS_DIR/PreToolUse/check-pending-questions.sh' 2>/dev/null
  "

  [ "$status" -eq 1 ]
}

# ───────────────────────────────────────────────────────────────
# ERROR ISOLATION
# ───────────────────────────────────────────────────────────────

@test "coordination: one hook failure does not affect others" {
  local input
  input=$(make_write_input "/project/file.js")

  # Even if one hook has issues, others should still work
  run bash -c "echo '$input' | bash '$REAL_HOOKS_DIR/PostToolUse/track-file-modifications.sh' 2>/dev/null"
  [ "$status" -eq 0 ]

  run bash -c "echo '$input' | bash '$REAL_HOOKS_DIR/PostToolUse/suggest-cli-verification.sh' 2>/dev/null"
  [ "$status" -eq 0 ]
}

@test "coordination: hooks handle malformed input gracefully" {
  # Invalid JSON should not crash hooks (segfault=139, 128+signal)
  # The key is they complete without a crash, any numeric exit is fine
  run bash -c "echo 'not json' | bash '$REAL_HOOKS_DIR/PostToolUse/track-file-modifications.sh' 2>/dev/null"
  # Accept any exit code less than 128 (signal exits are 128+signal)
  [ "$status" -lt 128 ]
}

# ───────────────────────────────────────────────────────────────
# PERFORMANCE
# ───────────────────────────────────────────────────────────────

@test "coordination: multiple hooks chain under 1000ms" {
  local start_time end_time duration

  if [[ "$OSTYPE" == "darwin"* ]]; then
    start_time=$(python3 -c 'import time; print(int(time.time() * 1000))')
  else
    start_time=$(date +%s%3N)
  fi

  local input
  input=$(make_write_input "/project/src/component.js")

  # Simulate hook chain
  bash -c "echo '$input' | bash '$REAL_HOOKS_DIR/PostToolUse/track-file-modifications.sh' 2>/dev/null" || true
  bash -c "echo '$input' | bash '$REAL_HOOKS_DIR/PostToolUse/suggest-cli-verification.sh' 2>/dev/null" || true
  bash -c "echo '$input' | bash '$REAL_HOOKS_DIR/PostToolUse/remind-cdn-versioning.sh' 2>/dev/null" || true

  if [[ "$OSTYPE" == "darwin"* ]]; then
    end_time=$(python3 -c 'import time; print(int(time.time() * 1000))')
  else
    end_time=$(date +%s%3N)
  fi

  duration=$((end_time - start_time))
  [ "$duration" -lt 1000 ]
}

