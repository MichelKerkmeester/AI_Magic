#!/usr/bin/env bats
# ───────────────────────────────────────────────────────────────
# Tests for: suggest-mcp-tools.sh
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
HOOK_SCRIPT="$REAL_HOOKS_DIR/UserPromptSubmit/suggest-mcp-tools.sh"

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
# PLATFORM DETECTION
# ───────────────────────────────────────────────────────────────

@test "suggest-mcp-tools detects Webflow mentions" {
  local input
  input=$(jq -n '{prompt: "Update the Webflow CMS collection"}')

  run bash -c "echo '$input' | bash '$HOOK_SCRIPT'"

  [ "$status" -eq 0 ]
  [[ "$output" == *"Webflow"* ]]
}

@test "suggest-mcp-tools detects Figma mentions" {
  local input
  input=$(jq -n '{prompt: "Get the design from Figma file"}')

  run bash -c "echo '$input' | bash '$HOOK_SCRIPT'"

  [ "$status" -eq 0 ]
  [[ "$output" == *"Figma"* ]]
}

@test "suggest-mcp-tools detects Notion mentions" {
  local input
  input=$(jq -n '{prompt: "Create a page in Notion database"}')

  run bash -c "echo '$input' | bash '$HOOK_SCRIPT'"

  [ "$status" -eq 0 ]
  [[ "$output" == *"Notion"* ]]
}

@test "suggest-mcp-tools detects GitHub mentions" {
  local input
  input=$(jq -n '{prompt: "Check the GitHub issues for this repo"}')

  run bash -c "echo '$input' | bash '$HOOK_SCRIPT'"

  [ "$status" -eq 0 ]
  [[ "$output" == *"GitHub"* ]]
}

@test "suggest-mcp-tools detects ClickUp mentions" {
  local input
  input=$(jq -n '{prompt: "Get tasks from ClickUp list"}')

  run bash -c "echo '$input' | bash '$HOOK_SCRIPT'"

  [ "$status" -eq 0 ]
  [[ "$output" == *"ClickUp"* ]]
}

@test "suggest-mcp-tools detects Chrome DevTools mentions" {
  local input
  input=$(jq -n '{prompt: "Take a screenshot using Chrome DevTools"}')

  run bash -c "echo '$input' | bash '$HOOK_SCRIPT'"

  [ "$status" -eq 0 ]
  [[ "$output" == *"Chrome"* ]]
}

# ───────────────────────────────────────────────────────────────
# MULTI-PLATFORM DETECTION
# ───────────────────────────────────────────────────────────────

@test "suggest-mcp-tools handles multiple tool mentions" {
  local input
  input=$(jq -n '{prompt: "Get data from Figma and create items in Webflow CMS"}')

  run bash -c "echo '$input' | bash '$HOOK_SCRIPT'"

  [ "$status" -eq 0 ]
  [[ "$output" == *"Figma"* ]]
  [[ "$output" == *"Webflow"* ]]
}

# ───────────────────────────────────────────────────────────────
# NON-TRIGGER CASES
# ───────────────────────────────────────────────────────────────

@test "suggest-mcp-tools handles no tool mentions" {
  local input
  input=$(jq -n '{prompt: "Fix the bug in the code"}')

  run bash -c "echo '$input' | bash '$HOOK_SCRIPT'"

  [ "$status" -eq 0 ]
  # No platform suggestions when no MCP tools mentioned
  [[ "$output" != *"MCP TOOL USAGE DETECTED"* ]]
}

@test "suggest-mcp-tools handles empty prompt" {
  run bash -c "echo '{}' | bash '$HOOK_SCRIPT'"

  [ "$status" -eq 0 ]
}

# ───────────────────────────────────────────────────────────────
# JSON OUTPUT
# ───────────────────────────────────────────────────────────────

@test "suggest-mcp-tools outputs JSON systemMessage" {
  local input
  input=$(jq -n '{prompt: "Update the Webflow site"}')

  run bash -c "echo '$input' | bash '$HOOK_SCRIPT'"

  [ "$status" -eq 0 ]
  # First line should be valid JSON with systemMessage
  local first_line
  first_line=$(echo "$output" | head -1)
  echo "$first_line" | jq -e '.systemMessage' >/dev/null 2>&1
}

# ───────────────────────────────────────────────────────────────
# EXIT CODES
# ───────────────────────────────────────────────────────────────

@test "suggest-mcp-tools exits with 0" {
  local input
  input=$(jq -n '{prompt: "Work with Webflow CMS"}')

  run bash -c "echo '$input' | bash '$HOOK_SCRIPT'"

  [ "$status" -eq 0 ]
}

# ───────────────────────────────────────────────────────────────
# PERFORMANCE
# ───────────────────────────────────────────────────────────────

@test "suggest-mcp-tools completes within 100ms" {
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
