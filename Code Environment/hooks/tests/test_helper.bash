#!/bin/bash
# ───────────────────────────────────────────────────────────────
# BATS TEST HELPER - Shared Test Utilities
# ───────────────────────────────────────────────────────────────
# Provides setup/teardown functions, mocks, and assertion helpers
# for testing Claude hooks.
#
# Usage in .bats files:
#   load test_helper
#
# Version: 1.0.0
# Created: 2025-12-03
# ───────────────────────────────────────────────────────────────

# Determine test root directory
TEST_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HOOKS_DIR="$(cd "$TEST_DIR/.." && pwd)"
PROJECT_ROOT="$(cd "$HOOKS_DIR/../.." && pwd)"

# Test temp directory (cleaned up after each test)
TEST_TMP_DIR=""

# ───────────────────────────────────────────────────────────────
# SETUP/TEARDOWN FUNCTIONS
# ───────────────────────────────────────────────────────────────

# Called before each test
setup() {
  # Create unique temp directory for this test
  TEST_TMP_DIR=$(mktemp -d "${TMPDIR:-/tmp}/bats_test.XXXXXX")

  # Create mock project structure
  mkdir -p "$TEST_TMP_DIR/project/.claude/hooks/lib"
  mkdir -p "$TEST_TMP_DIR/project/.claude/hooks/logs"
  mkdir -p "$TEST_TMP_DIR/project/.claude/hooks/UserPromptSubmit"
  mkdir -p "$TEST_TMP_DIR/project/.claude/configs"
  mkdir -p "$TEST_TMP_DIR/project/specs"

  # Initialize mock git repo
  (cd "$TEST_TMP_DIR/project" && git init -q 2>/dev/null || true)

  # Set up state directory for hook state isolation
  export CLAUDE_SESSION_ID="test-$$-$(date +%s)"
  export HOOK_STATE_DIR="$TEST_TMP_DIR/state"
  mkdir -p "$HOOK_STATE_DIR"

  # Export paths for hooks under test
  export PROJECT_ROOT="$TEST_TMP_DIR/project"
  export HOOKS_DIR="$TEST_TMP_DIR/project/.claude/hooks"

  # Create minimal output-helpers.sh mock
  create_output_helpers_mock

  # Create minimal shared-state.sh copy (uses real implementation)
  cp "$HOOKS_DIR/../lib/shared-state.sh" "$TEST_TMP_DIR/project/.claude/hooks/lib/shared-state.sh" 2>/dev/null || \
    create_shared_state_mock
}

# Called after each test
teardown() {
  # Clean up temp directory
  if [ -n "$TEST_TMP_DIR" ] && [ -d "$TEST_TMP_DIR" ]; then
    rm -rf "$TEST_TMP_DIR"
  fi

  # Clean up any test state
  unset CLAUDE_SESSION_ID
  unset HOOK_STATE_DIR
  unset PROJECT_ROOT
  unset HOOKS_DIR
}

# ───────────────────────────────────────────────────────────────
# MOCK CREATION FUNCTIONS
# ───────────────────────────────────────────────────────────────

# Create minimal output-helpers.sh mock
create_output_helpers_mock() {
  cat > "$TEST_TMP_DIR/project/.claude/hooks/lib/output-helpers.sh" << 'MOCK_EOF'
#!/bin/bash
# Mock output-helpers.sh for testing

check_dependency() {
  command -v "$1" &>/dev/null
}

validate_json() {
  [ -f "$1" ] && jq empty "$1" 2>/dev/null
}

emit_json() {
  echo "$1"
}

log_message() {
  echo "[LOG] $*" >&2
}
MOCK_EOF
}

# Create minimal shared-state.sh mock
create_shared_state_mock() {
  cat > "$TEST_TMP_DIR/project/.claude/hooks/lib/shared-state.sh" << 'MOCK_EOF'
#!/bin/bash
# Mock shared-state.sh for testing

get_state_dir() {
  local session_id="${CLAUDE_SESSION_ID:-global}"
  session_id=$(echo "$session_id" | tr -cd 'a-zA-Z0-9_-')
  session_id="${session_id:-global}"
  local session_dir="${HOOK_STATE_DIR:-/tmp/claude_hooks_state}/$session_id"
  mkdir -p "$session_dir" 2>/dev/null
  echo "$session_dir"
}

write_hook_state() {
  local key="$1"
  local value="$2"
  local state_dir=$(get_state_dir)
  echo "$value" > "$state_dir/${key}.json"
}

read_hook_state() {
  local key="$1"
  local state_dir=$(get_state_dir)
  local file="$state_dir/${key}.json"
  [ -f "$file" ] && cat "$file"
}

clear_hook_state() {
  local key="$1"
  local state_dir=$(get_state_dir)
  if [ -n "$key" ]; then
    rm -f "$state_dir/${key}.json"
  else
    rm -f "$state_dir"/*.json
  fi
}

has_hook_state() {
  local key="$1"
  local state_dir=$(get_state_dir)
  [ -f "$state_dir/${key}.json" ]
}

export -f get_state_dir write_hook_state read_hook_state clear_hook_state has_hook_state 2>/dev/null || true
MOCK_EOF
}

# Create exit-codes.sh mock
create_exit_codes_mock() {
  cat > "$TEST_TMP_DIR/project/.claude/hooks/lib/exit-codes.sh" << 'MOCK_EOF'
#!/bin/bash
# Mock exit-codes.sh for testing
EXIT_ALLOW=0
EXIT_BLOCK=1
EXIT_ERROR=2
MOCK_EOF
}

# Create signal-output.sh mock
create_signal_output_mock() {
  cat > "$TEST_TMP_DIR/project/.claude/hooks/lib/signal-output.sh" << 'MOCK_EOF'
#!/bin/bash
# Mock signal-output.sh for testing
emit_question() { echo "[QUESTION] $*"; }
emit_memory_load_question() { echo "[MEMORY_QUESTION] $*"; }
set_question_flow() { :; }
get_question_stage() { echo "initial"; }
clear_question_flow() { :; }
get_flow_spec_folder() { echo ""; }
get_flow_memory_files() { echo "[]"; }
MOCK_EOF
}

# Create spec-context.sh mock
create_spec_context_mock() {
  cat > "$TEST_TMP_DIR/project/.claude/hooks/lib/spec-context.sh" << 'MOCK_EOF'
#!/bin/bash
# Mock spec-context.sh for testing
get_spec_marker_path() { echo "$PROJECT_ROOT/.claude/.spec-active"; }
create_spec_marker() { echo "$1" > "$PROJECT_ROOT/.claude/.spec-active"; }
cleanup_spec_marker() { rm -f "$PROJECT_ROOT/.claude/.spec-active"; }
has_root_level_content() { return 1; }
MOCK_EOF
}

# ───────────────────────────────────────────────────────────────
# ASSERTION HELPERS
# ───────────────────────────────────────────────────────────────

# Assert that output contains a string
# Usage: assert_output_contains "expected substring"
assert_output_contains() {
  local expected="$1"
  if [[ "$output" != *"$expected"* ]]; then
    echo "Expected output to contain: $expected"
    echo "Actual output: $output"
    return 1
  fi
}

# Assert that output does NOT contain a string
# Usage: assert_output_not_contains "unexpected substring"
assert_output_not_contains() {
  local unexpected="$1"
  if [[ "$output" == *"$unexpected"* ]]; then
    echo "Expected output NOT to contain: $unexpected"
    echo "Actual output: $output"
    return 1
  fi
}

# Assert exit status equals expected value
# Usage: assert_status 0
assert_status() {
  local expected="$1"
  if [ "$status" -ne "$expected" ]; then
    echo "Expected status: $expected"
    echo "Actual status: $status"
    return 1
  fi
}

# Assert file exists
# Usage: assert_file_exists "/path/to/file"
assert_file_exists() {
  local file="$1"
  if [ ! -f "$file" ]; then
    echo "Expected file to exist: $file"
    return 1
  fi
}

# Assert file does not exist
# Usage: assert_file_not_exists "/path/to/file"
assert_file_not_exists() {
  local file="$1"
  if [ -f "$file" ]; then
    echo "Expected file NOT to exist: $file"
    return 1
  fi
}

# Assert directory exists
# Usage: assert_dir_exists "/path/to/dir"
assert_dir_exists() {
  local dir="$1"
  if [ ! -d "$dir" ]; then
    echo "Expected directory to exist: $dir"
    return 1
  fi
}

# Assert that a variable equals expected value
# Usage: assert_equals "expected" "$actual"
assert_equals() {
  local expected="$1"
  local actual="$2"
  if [ "$expected" != "$actual" ]; then
    echo "Expected: $expected"
    echo "Actual: $actual"
    return 1
  fi
}

# Assert that a variable matches a regex pattern
# Usage: assert_matches "pattern" "$value"
assert_matches() {
  local pattern="$1"
  local value="$2"
  if ! [[ "$value" =~ $pattern ]]; then
    echo "Expected pattern: $pattern"
    echo "Actual value: $value"
    return 1
  fi
}

# ───────────────────────────────────────────────────────────────
# HOOK EXECUTION HELPERS
# ───────────────────────────────────────────────────────────────

# Run a hook with JSON input
# Usage: run_hook_with_input "/path/to/hook.sh" '{"prompt": "test"}'
run_hook_with_input() {
  local hook="$1"
  local json_input="$2"

  echo "$json_input" | bash "$hook"
}

# Create mock JSON input for UserPromptSubmit hooks
# Usage: make_prompt_input "analyze the bug"
make_prompt_input() {
  local prompt="$1"
  local session_id="${2:-test-session}"

  jq -n \
    --arg prompt "$prompt" \
    --arg session_id "$session_id" \
    '{prompt: $prompt, session_id: $session_id}'
}

# ───────────────────────────────────────────────────────────────
# UTILITY FUNCTIONS
# ───────────────────────────────────────────────────────────────

# Create a minimal spec folder structure
# Usage: create_spec_folder "001-feature-name"
create_spec_folder() {
  local spec_name="$1"
  local spec_dir="$TEST_TMP_DIR/project/specs/$spec_name"

  mkdir -p "$spec_dir/memory"

  cat > "$spec_dir/spec.md" << EOF
# Specification: $spec_name

## Overview
Test specification for $spec_name
EOF

  echo "$spec_dir"
}

# Create a memory file in a spec folder
# Usage: create_memory_file "001-feature" "25-12-03_10-00__session.md"
create_memory_file() {
  local spec_name="$1"
  local filename="$2"
  local content="${3:-# Memory file content}"

  local memory_dir="$TEST_TMP_DIR/project/specs/$spec_name/memory"
  mkdir -p "$memory_dir"

  echo "$content" > "$memory_dir/$filename"
}

# Wait for file to exist (with timeout)
# Usage: wait_for_file "/path/to/file" 5
wait_for_file() {
  local file="$1"
  local timeout="${2:-5}"
  local count=0

  while [ ! -f "$file" ] && [ $count -lt $timeout ]; do
    sleep 1
    count=$((count + 1))
  done

  [ -f "$file" ]
}

# Get line count of a file
# Usage: line_count "/path/to/file"
line_count() {
  local file="$1"
  wc -l < "$file" | tr -d ' '
}

# Print debug info (useful during test development)
debug_output() {
  echo "=== DEBUG OUTPUT ===" >&3
  echo "Status: $status" >&3
  echo "Output:" >&3
  echo "$output" >&3
  echo "===================" >&3
}
