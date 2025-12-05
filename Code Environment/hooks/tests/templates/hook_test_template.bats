#!/usr/bin/env bats
# ───────────────────────────────────────────────────────────────
# Tests for: [HOOK_NAME]
# Type: [UserPromptSubmit|PreToolUse|PostToolUse|SubagentStop|PreCompact|Lifecycle]
# ───────────────────────────────────────────────────────────────
# Spec: 010-comprehensive-hook-testing
# Created: YYYY-MM-DD
# ───────────────────────────────────────────────────────────────

# Adjust path based on test file location
# From tests/UserPromptSubmit/ use: ../test_helper
# From tests/lib/ use: ../test_helper
# From tests/integration/ use: ../test_helper
load ../test_helper

# ───────────────────────────────────────────────────────────────
# CONSTANTS
# ───────────────────────────────────────────────────────────────

HOOK_SCRIPT="[HookType]/[hook-name].sh"

# ───────────────────────────────────────────────────────────────
# SETUP / TEARDOWN
# ───────────────────────────────────────────────────────────────

setup() {
  # Load test helper (creates temp dir, mocks, etc.)
  load ../test_helper

  # Copy actual hook to test environment
  cp "$HOOKS_DIR/../$HOOK_SCRIPT" "$TEST_TMP_DIR/project/.claude/hooks/$HOOK_SCRIPT" 2>/dev/null || true

  # Additional setup specific to this hook
  # Example: Create required config files
  # cat > "$TEST_TMP_DIR/project/.claude/configs/some-config.json" << 'EOF'
  # {"key": "value"}
  # EOF
}

teardown() {
  # Cleanup handled by test_helper teardown
  :
}

# ───────────────────────────────────────────────────────────────
# BASIC FUNCTIONALITY
# ───────────────────────────────────────────────────────────────

@test "[hook-name] processes valid input" {
  local input
  input=$(make_prompt_input "test prompt")

  run echo "$input" | bash "$HOOKS_DIR/$HOOK_SCRIPT"

  assert_status 0
}

@test "[hook-name] outputs expected format" {
  local input
  input=$(make_prompt_input "test prompt")

  run echo "$input" | bash "$HOOKS_DIR/$HOOK_SCRIPT"

  assert_status 0
  # assert_output_contains "expected"
}

@test "[hook-name] handles trigger pattern" {
  local input
  input=$(make_prompt_input "trigger keyword here")

  run echo "$input" | bash "$HOOKS_DIR/$HOOK_SCRIPT"

  assert_status 0
  # assert_output_contains "triggered"
}

# ───────────────────────────────────────────────────────────────
# INPUT VALIDATION
# ───────────────────────────────────────────────────────────────

@test "[hook-name] handles empty input" {
  run echo '{}' | bash "$HOOKS_DIR/$HOOK_SCRIPT"

  assert_status 0
}

@test "[hook-name] handles missing prompt field" {
  run echo '{"session_id": "test"}' | bash "$HOOKS_DIR/$HOOK_SCRIPT"

  assert_status 0
}

@test "[hook-name] handles special characters in input" {
  local input
  input=$(make_prompt_input 'test with "quotes" and $pecial chars')

  run echo "$input" | bash "$HOOKS_DIR/$HOOK_SCRIPT"

  assert_status 0
}

# ───────────────────────────────────────────────────────────────
# EXIT CODES
# ───────────────────────────────────────────────────────────────

@test "[hook-name] returns 0 for valid input" {
  local input
  input=$(make_prompt_input "valid input")

  run echo "$input" | bash "$HOOKS_DIR/$HOOK_SCRIPT"

  assert_status 0
}

# For blocking hooks, add:
# @test "[hook-name] returns 1 when blocking" {
#   local input
#   input=$(make_prompt_input "blocking trigger")
#
#   run echo "$input" | bash "$HOOKS_DIR/$HOOK_SCRIPT"
#
#   assert_status 1
# }

# ───────────────────────────────────────────────────────────────
# JSON OUTPUT (for hooks that emit JSON)
# ───────────────────────────────────────────────────────────────

@test "[hook-name] outputs valid JSON" {
  local input
  input=$(make_prompt_input "json trigger")

  run echo "$input" | bash "$HOOKS_DIR/$HOOK_SCRIPT"

  # Verify output is valid JSON (if hook outputs JSON)
  if [ -n "$output" ]; then
    echo "$output" | jq empty 2>/dev/null || {
      echo "Output is not valid JSON: $output"
      return 1
    }
  fi
}

# @test "[hook-name] includes systemMessage field" {
#   local input
#   input=$(make_prompt_input "trigger")
#
#   run echo "$input" | bash "$HOOKS_DIR/$HOOK_SCRIPT"
#
#   local has_system_message
#   has_system_message=$(echo "$output" | jq -r '.systemMessage // empty')
#   [ -n "$has_system_message" ]
# }

# ───────────────────────────────────────────────────────────────
# EDGE CASES
# ───────────────────────────────────────────────────────────────

@test "[hook-name] handles very long input" {
  local long_text
  long_text=$(printf 'a%.0s' {1..5000})
  local input
  input=$(make_prompt_input "$long_text")

  run echo "$input" | bash "$HOOKS_DIR/$HOOK_SCRIPT"

  assert_status 0
}

@test "[hook-name] handles unicode characters" {
  local input
  input=$(make_prompt_input "test with émojis 🚀 and ünîcödé")

  run echo "$input" | bash "$HOOKS_DIR/$HOOK_SCRIPT"

  assert_status 0
}

@test "[hook-name] handles newlines in input" {
  local input
  input=$(jq -n --arg p $'line1\nline2\nline3' '{prompt: $p}')

  run echo "$input" | bash "$HOOKS_DIR/$HOOK_SCRIPT"

  assert_status 0
}

# ───────────────────────────────────────────────────────────────
# ERROR HANDLING
# ───────────────────────────────────────────────────────────────

@test "[hook-name] handles malformed JSON gracefully" {
  run echo 'not json' | bash "$HOOKS_DIR/$HOOK_SCRIPT"

  # Hook should not crash
  [ "$status" -eq 0 ] || [ "$status" -eq 1 ]
}

@test "[hook-name] handles missing dependencies" {
  # Temporarily remove a dependency
  local orig_path="$PATH"
  export PATH="/usr/bin"

  local input
  input=$(make_prompt_input "test")

  run echo "$input" | bash "$HOOKS_DIR/$HOOK_SCRIPT"

  export PATH="$orig_path"

  # Should handle gracefully
  [ "$status" -eq 0 ] || [ "$status" -eq 1 ]
}

# ───────────────────────────────────────────────────────────────
# PERFORMANCE
# ───────────────────────────────────────────────────────────────

@test "[hook-name] completes within performance target" {
  local input
  input=$(make_prompt_input "test")

  local start_time end_time duration
  start_time=$(date +%s%N)

  run echo "$input" | bash "$HOOKS_DIR/$HOOK_SCRIPT"

  end_time=$(date +%s%N)
  duration=$(( (end_time - start_time) / 1000000 ))

  # Adjust target based on hook type
  # UserPromptSubmit: <200ms
  # PreToolUse: <100ms
  # PostToolUse: <200ms
  [ "$duration" -lt 200 ]
}

# ───────────────────────────────────────────────────────────────
# STATE MANAGEMENT (for hooks that use shared state)
# ───────────────────────────────────────────────────────────────

# @test "[hook-name] writes state correctly" {
#   source "$HOOKS_DIR/lib/shared-state.sh"
#
#   local input
#   input=$(make_prompt_input "state trigger")
#
#   run echo "$input" | bash "$HOOKS_DIR/$HOOK_SCRIPT"
#
#   # Verify state was written
#   local state
#   state=$(read_hook_state "expected_key")
#   [ -n "$state" ]
# }

# @test "[hook-name] reads existing state" {
#   source "$HOOKS_DIR/lib/shared-state.sh"
#   write_hook_state "existing_key" "existing_value"
#
#   local input
#   input=$(make_prompt_input "test")
#
#   run echo "$input" | bash "$HOOKS_DIR/$HOOK_SCRIPT"
#
#   # Hook should have used the existing state
#   assert_status 0
# }

# ───────────────────────────────────────────────────────────────
# LOGGING (verify logging behavior)
# ───────────────────────────────────────────────────────────────

# @test "[hook-name] logs to correct file" {
#   local log_file="$HOOKS_DIR/logs/[hook-name].log"
#
#   local input
#   input=$(make_prompt_input "test")
#
#   run echo "$input" | bash "$HOOKS_DIR/$HOOK_SCRIPT"
#
#   # Check log file was created/updated
#   assert_file_exists "$log_file"
# }
