#!/usr/bin/env bats
# ───────────────────────────────────────────────────────────────
# Tests for: suggest-semantic-search.sh
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
HOOK_SCRIPT="$REAL_HOOKS_DIR/UserPromptSubmit/suggest-semantic-search.sh"

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
# PATTERN 1: EXPLORATORY QUESTIONS
# ───────────────────────────────────────────────────────────────

@test "suggest-semantic-search suggests for where is X implemented" {
  local input
  input=$(jq -n '{prompt: "where is the authentication implemented"}')

  run bash -c "echo '$input' | bash '$HOOK_SCRIPT'"

  [ "$status" -eq 0 ]
  [[ "$output" == *"Semantic search"* ]] || [[ "$output" == *"search_codebase"* ]]
}

@test "suggest-semantic-search suggests for how does X work" {
  local input
  input=$(jq -n '{prompt: "how does the caching system work"}')

  run bash -c "echo '$input' | bash '$HOOK_SCRIPT'"

  [ "$status" -eq 0 ]
  [[ "$output" == *"Semantic search"* ]] || [[ "$output" == *"search_codebase"* ]]
}

# ───────────────────────────────────────────────────────────────
# PATTERN 2: CODE NAVIGATION
# ───────────────────────────────────────────────────────────────

@test "suggest-semantic-search suggests for find all usage" {
  local input
  input=$(jq -n '{prompt: "find all uses of the user service"}')

  run bash -c "echo '$input' | bash '$HOOK_SCRIPT'"

  [ "$status" -eq 0 ]
  [[ "$output" == *"Semantic search"* ]] || [[ "$output" == *"search_codebase"* ]]
}

# ───────────────────────────────────────────────────────────────
# PATTERN 3: RELATIONSHIP DISCOVERY
# ───────────────────────────────────────────────────────────────

@test "suggest-semantic-search suggests for what depends on X" {
  local input
  input=$(jq -n '{prompt: "what depends on the database module"}')

  run bash -c "echo '$input' | bash '$HOOK_SCRIPT'"

  [ "$status" -eq 0 ]
  [[ "$output" == *"Semantic search"* ]] || [[ "$output" == *"search_codebase"* ]]
}

# ───────────────────────────────────────────────────────────────
# PATTERN 4: FEATURE DISCOVERY
# ───────────────────────────────────────────────────────────────

@test "suggest-semantic-search suggests for error handling patterns" {
  local input
  input=$(jq -n '{prompt: "show me the error handling patterns"}')

  run bash -c "echo '$input' | bash '$HOOK_SCRIPT'"

  [ "$status" -eq 0 ]
  [[ "$output" == *"Semantic search"* ]] || [[ "$output" == *"search_codebase"* ]]
}

# ───────────────────────────────────────────────────────────────
# NON-TRIGGER CASES
# ───────────────────────────────────────────────────────────────

@test "suggest-semantic-search skips implementation prompts" {
  local input
  input=$(jq -n '{prompt: "implement a new button component"}')

  run bash -c "echo '$input' | bash '$HOOK_SCRIPT'"

  [ "$status" -eq 0 ]
  # Should not suggest for implementation tasks
  [[ "$output" != *"SEMANTIC SEARCH RECOMMENDATION"* ]]
}

@test "suggest-semantic-search handles empty prompt" {
  run bash -c "echo '{}' | bash '$HOOK_SCRIPT'"

  [ "$status" -eq 0 ]
}

@test "suggest-semantic-search handles no pattern match" {
  local input
  input=$(jq -n '{prompt: "fix the typo in README"}')

  run bash -c "echo '$input' | bash '$HOOK_SCRIPT'"

  [ "$status" -eq 0 ]
  # No exploration pattern, so no recommendation output
  [[ "$output" != *"SEMANTIC SEARCH RECOMMENDATION"* ]]
}

# ───────────────────────────────────────────────────────────────
# JSON OUTPUT
# ───────────────────────────────────────────────────────────────

@test "suggest-semantic-search outputs JSON systemMessage" {
  local input
  input=$(jq -n '{prompt: "where is authentication handled"}')

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

@test "suggest-semantic-search exits with 0" {
  local input
  input=$(jq -n '{prompt: "where is the API defined"}')

  run bash -c "echo '$input' | bash '$HOOK_SCRIPT'"

  [ "$status" -eq 0 ]
}

# ───────────────────────────────────────────────────────────────
# PERFORMANCE
# ───────────────────────────────────────────────────────────────

@test "suggest-semantic-search completes within 100ms" {
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

# ───────────────────────────────────────────────────────────────
# QUERY TEMPLATE
# ───────────────────────────────────────────────────────────────

@test "suggest-semantic-search includes query template" {
  local input
  input=$(jq -n '{prompt: "how does the routing work"}')

  run bash -c "echo '$input' | bash '$HOOK_SCRIPT'"

  [ "$status" -eq 0 ]
  [[ "$output" == *"Suggested Query"* ]] || [[ "$output" == *"search_codebase"* ]]
}
