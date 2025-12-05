#!/usr/bin/env bats
# ───────────────────────────────────────────────────────────────
# Tests for: suggest-prompt-improvement.sh
# Type: UserPromptSubmit
# ───────────────────────────────────────────────────────────────
# Spec: 010-comprehensive-hook-testing
# Created: 2025-12-03
# Tests: 8
# ───────────────────────────────────────────────────────────────

load ../test_helper

# ───────────────────────────────────────────────────────────────
# CONSTANTS
# ───────────────────────────────────────────────────────────────

REAL_HOOKS_DIR="$(cd "$BATS_TEST_DIRNAME/../.." && pwd)"
HOOK_SCRIPT="$REAL_HOOKS_DIR/UserPromptSubmit/suggest-prompt-improvement.sh"

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

# Generate a long prompt with word count > 100
make_long_prompt() {
  local pattern="$1"
  # Generate 50 filler words + pattern + 60 more filler words = 110+ words
  local filler="word word word word word word word word word word "
  local filler_50="${filler}${filler}${filler}${filler}${filler}"
  echo "You are an assistant with context for this task. ${filler_50}${pattern} ${filler_50}Please provide format examples for the output deliverable."
}

make_short_prompt() {
  echo "Fix the bug in the code."
}

# ───────────────────────────────────────────────────────────────
# TRIGGER DETECTION
# ───────────────────────────────────────────────────────────────

@test "suggest-prompt-improvement suggests for long prompts with patterns" {
  local prompt
  prompt=$(make_long_prompt "analyze this context and provide output")
  local input
  input=$(jq -n --arg p "$prompt" '{prompt: $p}')

  run bash -c "echo '$input' | bash '$HOOK_SCRIPT'"

  [ "$status" -eq 0 ]
  [[ "$output" == *"prompt_improver"* ]] || [[ "$output" == *"Complex prompt detected"* ]]
}

@test "suggest-prompt-improvement skips short prompts" {
  local prompt
  prompt=$(make_short_prompt)
  local input
  input=$(jq -n --arg p "$prompt" '{prompt: $p}')

  run bash -c "echo '$input' | bash '$HOOK_SCRIPT'"

  [ "$status" -eq 0 ]
  # Should NOT contain suggestion for short prompts
  [[ "$output" != *"prompt_improver"* ]]
}

@test "suggest-prompt-improvement skips prompts without patterns" {
  # Long prompt but without trigger patterns
  local filler="word word word word word word word word word word "
  local filler_120="${filler}${filler}${filler}${filler}${filler}${filler}${filler}${filler}${filler}${filler}${filler}${filler}"
  local prompt="Please help me with this task. ${filler_120}"
  local input
  input=$(jq -n --arg p "$prompt" '{prompt: $p}')

  run bash -c "echo '$input' | bash '$HOOK_SCRIPT'"

  [ "$status" -eq 0 ]
  # No pattern match means no suggestion
  [[ "$output" != *"prompt_improver"* ]]
}

# ───────────────────────────────────────────────────────────────
# JSON OUTPUT
# ───────────────────────────────────────────────────────────────

@test "suggest-prompt-improvement outputs valid JSON when triggered" {
  local prompt
  prompt=$(make_long_prompt "generate this with context")
  local input
  input=$(jq -n --arg p "$prompt" '{prompt: $p}')

  run bash -c "echo '$input' | bash '$HOOK_SCRIPT'"

  [ "$status" -eq 0 ]
  # If output exists, should be valid JSON
  if [ -n "$output" ]; then
    echo "$output" | head -1 | jq empty 2>/dev/null
  fi
}

# ───────────────────────────────────────────────────────────────
# EDGE CASES
# ───────────────────────────────────────────────────────────────

@test "suggest-prompt-improvement handles empty prompt" {
  run bash -c "echo '{}' | bash '$HOOK_SCRIPT'"

  [ "$status" -eq 0 ]
}

@test "suggest-prompt-improvement handles missing prompt field" {
  run bash -c "echo '{\"session_id\": \"test\"}' | bash '$HOOK_SCRIPT'"

  [ "$status" -eq 0 ]
}

# ───────────────────────────────────────────────────────────────
# EXIT CODES
# ───────────────────────────────────────────────────────────────

@test "suggest-prompt-improvement exits with 0" {
  local prompt
  prompt=$(make_long_prompt "create output format")
  local input
  input=$(jq -n --arg p "$prompt" '{prompt: $p}')

  run bash -c "echo '$input' | bash '$HOOK_SCRIPT'"

  [ "$status" -eq 0 ]
}

# ───────────────────────────────────────────────────────────────
# PERFORMANCE
# ───────────────────────────────────────────────────────────────

@test "suggest-prompt-improvement completes within 100ms" {
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
