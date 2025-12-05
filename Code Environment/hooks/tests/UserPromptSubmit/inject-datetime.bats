#!/usr/bin/env bats
# ───────────────────────────────────────────────────────────────
# Tests for: inject-datetime.sh
# Type: UserPromptSubmit
# ───────────────────────────────────────────────────────────────
# Spec: 010-comprehensive-hook-testing
# Created: 2025-12-03
# ───────────────────────────────────────────────────────────────

load ../test_helper

# ───────────────────────────────────────────────────────────────
# CONSTANTS
# ───────────────────────────────────────────────────────────────

# Use real hooks directory
REAL_HOOKS_DIR="$(cd "$BATS_TEST_DIRNAME/../.." && pwd)"
HOOK_SCRIPT="$REAL_HOOKS_DIR/UserPromptSubmit/inject-datetime.sh"

# ───────────────────────────────────────────────────────────────
# SETUP / TEARDOWN
# ───────────────────────────────────────────────────────────────

setup() {
  TEST_TMP_DIR=$(mktemp -d "${TMPDIR:-/tmp}/bats_test.XXXXXX")
  mkdir -p "$TEST_TMP_DIR/logs"
  export HOOKS_DIR="$REAL_HOOKS_DIR"
}

teardown() {
  [ -n "$TEST_TMP_DIR" ] && [ -d "$TEST_TMP_DIR" ] && rm -rf "$TEST_TMP_DIR"
}

# ───────────────────────────────────────────────────────────────
# BASIC FUNCTIONALITY
# ───────────────────────────────────────────────────────────────

@test "inject-datetime outputs current date" {
  run bash -c "echo '{}' | bash '$HOOK_SCRIPT'"

  # Should contain a day of week
  [[ "$output" == *"Monday"* ]] || \
  [[ "$output" == *"Tuesday"* ]] || \
  [[ "$output" == *"Wednesday"* ]] || \
  [[ "$output" == *"Thursday"* ]] || \
  [[ "$output" == *"Friday"* ]] || \
  [[ "$output" == *"Saturday"* ]] || \
  [[ "$output" == *"Sunday"* ]]
}

@test "inject-datetime outputs current time" {
  run bash -c "echo '{}' | bash '$HOOK_SCRIPT'"

  # Should contain time in HH:MM format
  [[ "$output" =~ [0-2][0-9]:[0-5][0-9] ]]
}

@test "inject-datetime format matches expected pattern" {
  run bash -c "echo '{}' | bash '$HOOK_SCRIPT'"

  # Expected: "Current date and time is DayOfWeek DayNum Month HH:MM Year"
  [[ "$output" == *"Current date and time is"* ]]
}

@test "inject-datetime includes month name" {
  run bash -c "echo '{}' | bash '$HOOK_SCRIPT'"

  # Should contain a month name
  [[ "$output" == *"January"* ]] || \
  [[ "$output" == *"February"* ]] || \
  [[ "$output" == *"March"* ]] || \
  [[ "$output" == *"April"* ]] || \
  [[ "$output" == *"May"* ]] || \
  [[ "$output" == *"June"* ]] || \
  [[ "$output" == *"July"* ]] || \
  [[ "$output" == *"August"* ]] || \
  [[ "$output" == *"September"* ]] || \
  [[ "$output" == *"October"* ]] || \
  [[ "$output" == *"November"* ]] || \
  [[ "$output" == *"December"* ]]
}

@test "inject-datetime includes current year" {
  local current_year
  current_year=$(date +%Y)

  run bash -c "echo '{}' | bash '$HOOK_SCRIPT'"

  [[ "$output" == *"$current_year"* ]]
}

# ───────────────────────────────────────────────────────────────
# EXIT CODES
# ───────────────────────────────────────────────────────────────

@test "inject-datetime exits with 0" {
  run bash -c "echo '{}' | bash '$HOOK_SCRIPT'"

  [ "$status" -eq 0 ]
}

@test "inject-datetime exits with 0 even with empty input" {
  run bash -c "echo '' | bash '$HOOK_SCRIPT'"

  [ "$status" -eq 0 ]
}

# ───────────────────────────────────────────────────────────────
# JSON OUTPUT FORMAT
# ───────────────────────────────────────────────────────────────

@test "inject-datetime outputs valid JSON" {
  run bash -c "echo '{}' | bash '$HOOK_SCRIPT'"

  echo "$output" | jq empty 2>/dev/null
}

@test "inject-datetime includes systemMessage field" {
  run bash -c "echo '{}' | bash '$HOOK_SCRIPT'"

  local has_system_message
  has_system_message=$(echo "$output" | jq -r '.systemMessage // empty')
  [ -n "$has_system_message" ]
}

# ───────────────────────────────────────────────────────────────
# PERFORMANCE
# ───────────────────────────────────────────────────────────────

@test "inject-datetime completes within 100ms" {
  # Note: Shell startup time makes <5ms unrealistic in testing
  # Using 100ms as practical threshold
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
