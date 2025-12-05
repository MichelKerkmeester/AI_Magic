#!/usr/bin/env bats
# ───────────────────────────────────────────────────────────────
# Tests for: validate-dispatch-requirement.sh
# Type: PreToolUse (BLOCKING when dispatch required)
# ───────────────────────────────────────────────────────────────
# Spec: 010-comprehensive-hook-testing
# Created: 2025-12-03
# Tests: 10
# ───────────────────────────────────────────────────────────────

load '../test_helper'

# ───────────────────────────────────────────────────────────────
# CONSTANTS
# ───────────────────────────────────────────────────────────────

REAL_HOOKS_DIR="$(cd "$BATS_TEST_DIRNAME/../.." && pwd)"
HOOK_SCRIPT="$REAL_HOOKS_DIR/PreToolUse/validate-dispatch-requirement.sh"

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

make_tool_input() {
  local tool_name="$1"
  jq -n --arg name "$tool_name" '{name: $name}'
}

set_pending_dispatch() {
  source "$REAL_HOOKS_DIR/lib/shared-state.sh" 2>/dev/null || return 1
  local dispatch_json=$(jq -n '{required: true, complexity: 75, agents: 3, domains: "code,docs,testing"}')
  write_hook_state "pending_dispatch" "$dispatch_json"
}

# ───────────────────────────────────────────────────────────────
# NO PENDING DISPATCH (always allow)
# ───────────────────────────────────────────────────────────────

@test "validate-dispatch-requirement allows all tools when no dispatch pending" {
  local input
  input=$(make_tool_input "Write")

  run bash -c "echo '$input' | bash '$HOOK_SCRIPT'"

  [ "$status" -eq 0 ]
}

@test "validate-dispatch-requirement allows Edit when no dispatch pending" {
  local input
  input=$(make_tool_input "Edit")

  run bash -c "echo '$input' | bash '$HOOK_SCRIPT'"

  [ "$status" -eq 0 ]
}

# ───────────────────────────────────────────────────────────────
# ALWAYS ALLOWED TOOLS
# ───────────────────────────────────────────────────────────────

@test "validate-dispatch-requirement always allows Task tool" {
  set_pending_dispatch

  local input
  input=$(make_tool_input "Task")

  run bash -c "echo '$input' | bash '$HOOK_SCRIPT'"

  [ "$status" -eq 0 ]
}

@test "validate-dispatch-requirement always allows Read tool" {
  set_pending_dispatch

  local input
  input=$(make_tool_input "Read")

  run bash -c "echo '$input' | bash '$HOOK_SCRIPT'"

  [ "$status" -eq 0 ]
}

@test "validate-dispatch-requirement always allows AskUserQuestion" {
  set_pending_dispatch

  local input
  input=$(make_tool_input "AskUserQuestion")

  run bash -c "echo '$input' | bash '$HOOK_SCRIPT'"

  [ "$status" -eq 0 ]
}

@test "validate-dispatch-requirement always allows TodoWrite" {
  set_pending_dispatch

  local input
  input=$(make_tool_input "TodoWrite")

  run bash -c "echo '$input' | bash '$HOOK_SCRIPT'"

  [ "$status" -eq 0 ]
}

# ───────────────────────────────────────────────────────────────
# BLOCKING BEHAVIOR
# ───────────────────────────────────────────────────────────────

@test "validate-dispatch-requirement blocks Write when dispatch pending" {
  set_pending_dispatch

  local input
  input=$(make_tool_input "Write")

  run bash -c "echo '$input' | bash '$HOOK_SCRIPT'"

  [ "$status" -eq 1 ]
}

@test "validate-dispatch-requirement blocks Edit when dispatch pending" {
  set_pending_dispatch

  local input
  input=$(make_tool_input "Edit")

  run bash -c "echo '$input' | bash '$HOOK_SCRIPT'"

  [ "$status" -eq 1 ]
}

# ───────────────────────────────────────────────────────────────
# INPUT HANDLING
# ───────────────────────────────────────────────────────────────

@test "validate-dispatch-requirement handles empty input" {
  run bash -c "echo '{}' | bash '$HOOK_SCRIPT'"

  [ "$status" -eq 0 ]
}

# ───────────────────────────────────────────────────────────────
# PERFORMANCE
# ───────────────────────────────────────────────────────────────

@test "validate-dispatch-requirement completes within 100ms" {
  local start_time end_time duration

  if [[ "$OSTYPE" == "darwin"* ]]; then
    start_time=$(python3 -c 'import time; print(int(time.time() * 1000))')
  else
    start_time=$(date +%s%3N)
  fi

  local input
  input=$(make_tool_input "Read")
  run bash -c "echo '$input' | bash '$HOOK_SCRIPT'"

  if [[ "$OSTYPE" == "darwin"* ]]; then
    end_time=$(python3 -c 'import time; print(int(time.time() * 1000))')
  else
    end_time=$(date +%s%3N)
  fi

  duration=$((end_time - start_time))
  [ "$duration" -lt 100 ]
}

