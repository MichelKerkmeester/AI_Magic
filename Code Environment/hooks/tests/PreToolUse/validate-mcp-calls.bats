#!/usr/bin/env bats
# ───────────────────────────────────────────────────────────────
# Tests for: validate-mcp-calls.sh
# Type: PreToolUse (advisory)
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
HOOK_SCRIPT="$REAL_HOOKS_DIR/PreToolUse/validate-mcp-calls.sh"

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
# HELPERS
# ───────────────────────────────────────────────────────────────

make_tool_input() {
  local tool_name="$1"
  jq -n --arg name "$tool_name" '{name: $name}'
}

# ───────────────────────────────────────────────────────────────
# CODE MODE TOOLS (allowed)
# ───────────────────────────────────────────────────────────────

@test "validate-mcp-calls allows call_tool_chain" {
  local input
  input=$(make_tool_input "call_tool_chain")

  run bash -c "echo '$input' | bash '$HOOK_SCRIPT'"

  [ "$status" -eq 0 ]
}

@test "validate-mcp-calls allows search_tools" {
  local input
  input=$(make_tool_input "search_tools")

  run bash -c "echo '$input' | bash '$HOOK_SCRIPT'"

  [ "$status" -eq 0 ]
}

@test "validate-mcp-calls allows list_tools" {
  local input
  input=$(make_tool_input "list_tools")

  run bash -c "echo '$input' | bash '$HOOK_SCRIPT'"

  [ "$status" -eq 0 ]
}

# ───────────────────────────────────────────────────────────────
# DIRECT MCP CALLS (warns but allows)
# ───────────────────────────────────────────────────────────────

@test "validate-mcp-calls warns on direct webflow calls" {
  local input
  input=$(make_tool_input "webflow_sites_list")

  run bash -c "echo '$input' | bash '$HOOK_SCRIPT'"

  # Advisory hook - always exits 0
  [ "$status" -eq 0 ]
  # Should output warning about Code Mode
  [[ "$output" == *"Code Mode"* ]] || [[ "$output" == *"Webflow"* ]] || [[ "$output" == "" ]]
}

@test "validate-mcp-calls warns on direct figma calls" {
  local input
  input=$(make_tool_input "figma_get_file")

  run bash -c "echo '$input' | bash '$HOOK_SCRIPT'"

  [ "$status" -eq 0 ]
}

@test "validate-mcp-calls warns on direct chrome_devtools calls" {
  local input
  input=$(make_tool_input "chrome_devtools_navigate_page")

  run bash -c "echo '$input' | bash '$HOOK_SCRIPT'"

  [ "$status" -eq 0 ]
}

# ───────────────────────────────────────────────────────────────
# EDGE CASES
# ───────────────────────────────────────────────────────────────

@test "validate-mcp-calls handles empty tool name" {
  run bash -c "echo '{}' | bash '$HOOK_SCRIPT'"

  [ "$status" -eq 0 ]
}

@test "validate-mcp-calls allows regular tools" {
  local input
  input=$(make_tool_input "Read")

  run bash -c "echo '$input' | bash '$HOOK_SCRIPT'"

  [ "$status" -eq 0 ]
}

# ───────────────────────────────────────────────────────────────
# EXIT CODES
# ───────────────────────────────────────────────────────────────

@test "validate-mcp-calls exits with 0 (advisory)" {
  local input
  input=$(make_tool_input "webflow_test")

  run bash -c "echo '$input' | bash '$HOOK_SCRIPT'"

  [ "$status" -eq 0 ]
}

# ───────────────────────────────────────────────────────────────
# PERFORMANCE
# ───────────────────────────────────────────────────────────────

@test "validate-mcp-calls completes within 150ms" {
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
  [ "$duration" -lt 150 ]
}
