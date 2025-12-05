#!/usr/bin/env bats
# ───────────────────────────────────────────────────────────────
# Tests for: validate-bash.sh
# Type: PreToolUse (blocking)
# ───────────────────────────────────────────────────────────────
# Spec: 010-comprehensive-hook-testing
# Created: 2025-12-03
# Tests: 15
# ───────────────────────────────────────────────────────────────

# Load test helper at file level
load '../test_helper'

# Get real hooks directory
REAL_HOOKS_DIR="$(cd "$BATS_TEST_DIRNAME/../.." && pwd)"
HOOK_SCRIPT="$REAL_HOOKS_DIR/PreToolUse/validate-bash.sh"

# ───────────────────────────────────────────────────────────────
# SETUP / TEARDOWN
# ───────────────────────────────────────────────────────────────

setup() {
  # Create unique temp directory for this test
  TEST_TMP_DIR=$(mktemp -d "${TMPDIR:-/tmp}/bats_test.XXXXXX")

  # Check if hook exists
  if [ -f "$HOOK_SCRIPT" ]; then
    HOOK_AVAILABLE=true
  else
    HOOK_AVAILABLE=false
  fi
}

teardown() {
  if [ -n "$TEST_TMP_DIR" ] && [ -d "$TEST_TMP_DIR" ]; then
    rm -rf "$TEST_TMP_DIR"
  fi
}

# ───────────────────────────────────────────────────────────────
# HELPER: Create bash tool input
# ───────────────────────────────────────────────────────────────

make_bash_input() {
  local command="$1"
  jq -n \
    --arg cmd "$command" \
    --arg tool "Bash" \
    '{tool_name: $tool, tool_input: {command: $cmd}}'
}

skip_if_hook_missing() {
  if [ "$HOOK_AVAILABLE" != "true" ]; then
    skip "validate-bash.sh hook not available"
  fi
}

# ───────────────────────────────────────────────────────────────
# BLOCKING: Large Directories (Performance)
# ───────────────────────────────────────────────────────────────

@test "blocks node_modules access" {
  skip_if_hook_missing

  local input
  input=$(make_bash_input "cat node_modules/package.json")

  run bash -c "echo '$input' | bash '$HOOK_SCRIPT'"

  [ "$status" -eq 1 ]
  [[ "$output" == *"node_modules"* ]]
}

@test "blocks build/ directory access" {
  skip_if_hook_missing

  local input
  input=$(make_bash_input "ls build/assets")

  run bash -c "echo '$input' | bash '$HOOK_SCRIPT'"

  [ "$status" -eq 1 ]
}

@test "blocks dist/ directory access" {
  skip_if_hook_missing

  local input
  input=$(make_bash_input "cat dist/bundle.js")

  run bash -c "echo '$input' | bash '$HOOK_SCRIPT'"

  [ "$status" -eq 1 ]
}

# ───────────────────────────────────────────────────────────────
# BLOCKING: Sensitive Files (Security)
# ───────────────────────────────────────────────────────────────

@test "blocks .env file access" {
  skip_if_hook_missing

  local input
  input=$(make_bash_input "cat .env")

  run bash -c "echo '$input' | bash '$HOOK_SCRIPT'"

  [ "$status" -eq 1 ]
  [[ "$output" == *"BLOCKED"* ]]
}

@test "blocks .ssh/ directory access" {
  skip_if_hook_missing

  local input
  input=$(make_bash_input "cat .ssh/id_rsa")

  run bash -c "echo '$input' | bash '$HOOK_SCRIPT'"

  [ "$status" -eq 1 ]
}

# ───────────────────────────────────────────────────────────────
# BLOCKING: Dangerous Commands (Security)
# ───────────────────────────────────────────────────────────────

@test "blocks rm -rf /" {
  skip_if_hook_missing

  local input
  input=$(make_bash_input "rm -rf /")

  run bash -c "echo '$input' | bash '$HOOK_SCRIPT'"

  [ "$status" -eq 1 ]
}

@test "blocks chmod 777" {
  skip_if_hook_missing

  local input
  input=$(make_bash_input "chmod 777 /etc/passwd")

  run bash -c "echo '$input' | bash '$HOOK_SCRIPT'"

  [ "$status" -eq 1 ]
}

# ───────────────────────────────────────────────────────────────
# ALLOWING: Safe Commands
# ───────────────────────────────────────────────────────────────

@test "allows git commands" {
  skip_if_hook_missing

  local input
  input=$(make_bash_input "git status")

  run bash -c "echo '$input' | bash '$HOOK_SCRIPT'"

  [ "$status" -eq 0 ]
}

@test "allows npm commands" {
  skip_if_hook_missing

  local input
  input=$(make_bash_input "npm install lodash")

  run bash -c "echo '$input' | bash '$HOOK_SCRIPT'"

  [ "$status" -eq 0 ]
}

@test "allows ls in safe directories" {
  skip_if_hook_missing

  local input
  input=$(make_bash_input "ls -la src/")

  run bash -c "echo '$input' | bash '$HOOK_SCRIPT'"

  [ "$status" -eq 0 ]
}

# ───────────────────────────────────────────────────────────────
# ALLOWING: Whitelisted Paths
# ───────────────────────────────────────────────────────────────

@test "allows .claude/hooks/logs/ access" {
  skip_if_hook_missing

  local input
  input=$(make_bash_input "cat .claude/hooks/logs/performance.log")

  run bash -c "echo '$input' | bash '$HOOK_SCRIPT'"

  [ "$status" -eq 0 ]
}

@test "allows .claude/configs/ access" {
  skip_if_hook_missing

  local input
  input=$(make_bash_input "cat .claude/configs/skill-rules.json")

  run bash -c "echo '$input' | bash '$HOOK_SCRIPT'"

  [ "$status" -eq 0 ]
}

# ───────────────────────────────────────────────────────────────
# INPUT HANDLING
# ───────────────────────────────────────────────────────────────

@test "handles empty command" {
  skip_if_hook_missing

  local input
  input=$(make_bash_input "")

  run bash -c "echo '$input' | bash '$HOOK_SCRIPT'"

  # Empty command should be allowed
  [ "$status" -eq 0 ]
}

@test "handles non-Bash tool gracefully" {
  skip_if_hook_missing

  local input
  input=$(jq -n '{tool_name: "Read", tool_input: {file_path: "/some/file"}}')

  run bash -c "echo '$input' | bash '$HOOK_SCRIPT'"

  # Non-bash tools should pass through
  [ "$status" -eq 0 ]
}

# ───────────────────────────────────────────────────────────────
# HEREDOC EXCLUSION
# ───────────────────────────────────────────────────────────────

@test "allows heredoc content containing blocked patterns" {
  skip_if_hook_missing

  # Heredoc content should not trigger blocks
  local input
  input=$(make_bash_input "cat > file.txt << 'EOF'
This discusses .env files
EOF")

  run bash -c "echo '$input' | bash '$HOOK_SCRIPT'"

  # Should allow - heredoc content is excluded from validation
  [ "$status" -eq 0 ]
}
