# Claude Hooks Test Suite

Comprehensive BATS (Bash Automated Testing System) test suite for validating hook behavior, library functions, and integration points.

---

## Quick Reference

```bash
# Run all tests
./run-tests.sh

# Run specific directory
./run-tests.sh lib/
./run-tests.sh UserPromptSubmit/

# With options
./run-tests.sh -v              # Verbose
./run-tests.sh --timing        # Show timing
./run-tests.sh --tap           # TAP output
./run-tests.sh --jobs 4        # Parallel
```

---

## Table of Contents

1. [Overview](#overview)
2. [Installation](#installation)
3. [Test Structure](#test-structure)
4. [Running Tests](#running-tests)
5. [Writing Tests](#writing-tests)
6. [Test Helper API](#test-helper-api)
7. [Mock System](#mock-system)
8. [Best Practices](#best-practices)
9. [CI/CD Integration](#cicd-integration)
10. [Troubleshooting](#troubleshooting)

---

## Overview

### Current Test Coverage

| Test File | Tests | Coverage Area |
|-----------|-------|---------------|
| `lib/shared-state.bats` | 20 | State management, locking, expiry |
| `UserPromptSubmit/enforce-spec-folder.bats` | 34 | Intent detection, spec enforcement |
| **Total** | **54** | |

### Test Philosophy

1. **Isolation**: Each test runs in a fresh temp directory
2. **Mocking**: Library dependencies are mocked for unit testing
3. **Determinism**: Tests produce consistent results
4. **Speed**: Individual tests complete in <100ms

---

## Installation

### Required Dependencies

**BATS Core** (Bash Automated Testing System):

```bash
# macOS (Homebrew)
brew install bats-core

# Linux (apt)
sudo apt install bats

# From source
git clone https://github.com/bats-core/bats-core.git
cd bats-core && sudo ./install.sh /usr/local
```

**jq** (JSON processor - required by many hooks):

```bash
# macOS
brew install jq

# Linux
sudo apt install jq
```

### Optional Dependencies

For enhanced assertions:

```bash
# macOS
brew install bats-support bats-assert

# Manual installation
git clone https://github.com/bats-core/bats-support.git /usr/local/lib/bats-support
git clone https://github.com/bats-core/bats-assert.git /usr/local/lib/bats-assert
```

### Verify Installation

```bash
bats --version
# Expected: Bats 1.x.x

jq --version
# Expected: jq-1.x
```

---

## Test Structure

```
.claude/hooks/tests/
├── README.md              # This documentation
├── run-tests.sh           # Test runner script
├── test_helper.bash       # Shared utilities & mocks
├── lib/
│   └── shared-state.bats  # Library function tests
├── UserPromptSubmit/
│   └── enforce-spec-folder.bats  # Hook behavior tests
├── PreToolUse/            # (planned)
├── PostToolUse/           # (planned)
└── SubagentStop/          # (planned)
```

### Directory Convention

Tests are organized to mirror the hooks structure:
- `lib/*.bats` - Tests for library files in `../lib/`
- `UserPromptSubmit/*.bats` - Tests for UserPromptSubmit hooks
- `PreToolUse/*.bats` - Tests for PreToolUse hooks
- etc.

---

## Running Tests

### Basic Usage

```bash
# From hooks directory
cd .claude/hooks

# Run all tests
./tests/run-tests.sh

# Run specific directory
./tests/run-tests.sh lib/
./tests/run-tests.sh UserPromptSubmit/

# Run single test file
./tests/run-tests.sh lib/shared-state.bats
```

### Options

| Option | Description |
|--------|-------------|
| `-v, --verbose` | Show detailed test output |
| `--tap` | Output in TAP format (for CI) |
| `--timing` | Show execution time per test |
| `--jobs N` | Run N tests in parallel |
| `-h, --help` | Show usage information |

### Examples

```bash
# Verbose with timing
./tests/run-tests.sh -v --timing

# Parallel execution (faster)
./tests/run-tests.sh --jobs 4

# CI-friendly output
./tests/run-tests.sh --tap > results.tap

# Combine options
./tests/run-tests.sh -v --timing --jobs 2 lib/
```

### Direct BATS Usage

You can also run BATS directly:

```bash
# Single file
bats tests/lib/shared-state.bats

# With options
bats --verbose-run --timing tests/lib/shared-state.bats

# All tests
bats tests/**/*.bats
```

---

## Writing Tests

### Basic Test Structure

```bash
#!/usr/bin/env bats

# Load test helper (adjust path based on location)
load ../test_helper

@test "description of what is being tested" {
  # Setup - prepare test conditions
  local input='{"prompt": "test input"}'

  # Execute - run the code under test
  run some_function "$input"

  # Assert - verify results
  assert_status 0
  assert_output_contains "expected output"
}
```

### Test Lifecycle

1. **`setup()`** - Runs before EACH test
   - Creates temp directory
   - Initializes mock project structure
   - Sets up environment variables

2. **`@test`** - Individual test case
   - Self-contained test logic
   - Uses `run` to capture output/status

3. **`teardown()`** - Runs after EACH test
   - Cleans up temp directory
   - Unsets environment variables

### Using `run`

The `run` command captures output and exit status:

```bash
@test "example using run" {
  run echo "hello world"

  # $status contains exit code
  [ "$status" -eq 0 ]

  # $output contains stdout
  [[ "$output" == "hello world" ]]

  # $lines is an array of output lines
  [ "${lines[0]}" == "hello world" ]
}
```

### Testing Hook Input

For hooks that read JSON from stdin:

```bash
@test "hook processes input correctly" {
  local input
  input=$(make_prompt_input "analyze this code")

  run echo "$input" | bash "$HOOKS_DIR/UserPromptSubmit/some-hook.sh"

  assert_status 0
  assert_output_contains "expected"
}
```

### Testing Library Functions

```bash
@test "library function returns correct value" {
  # Source the library
  source "$HOOKS_DIR/lib/shared-state.sh"

  # Call function
  run write_hook_state "test_key" "test_value"
  assert_status 0

  # Verify result
  run read_hook_state "test_key"
  assert_output_contains "test_value"
}
```

---

## Test Helper API

### Setup/Teardown Functions

| Function | Purpose |
|----------|---------|
| `setup()` | Called before each test - creates temp dir, mocks |
| `teardown()` | Called after each test - cleanup |

### Assertion Functions

| Function | Usage | Description |
|----------|-------|-------------|
| `assert_status N` | `assert_status 0` | Exit code equals N |
| `assert_output_contains "str"` | `assert_output_contains "success"` | Output includes string |
| `assert_output_not_contains "str"` | `assert_output_not_contains "error"` | Output excludes string |
| `assert_file_exists "path"` | `assert_file_exists "/tmp/file.txt"` | File exists |
| `assert_file_not_exists "path"` | `assert_file_not_exists "/tmp/old.txt"` | File doesn't exist |
| `assert_dir_exists "path"` | `assert_dir_exists "/tmp/dir"` | Directory exists |
| `assert_equals "exp" "$act"` | `assert_equals "foo" "$var"` | Values match exactly |
| `assert_matches "regex" "$val"` | `assert_matches "^[0-9]+$" "$num"` | Regex pattern matches |

### Utility Functions

| Function | Usage | Description |
|----------|-------|-------------|
| `create_spec_folder "name"` | `create_spec_folder "001-feature"` | Create mock spec folder |
| `create_memory_file "spec" "file"` | `create_memory_file "001-feature" "memory.md"` | Create memory file |
| `make_prompt_input "text"` | `make_prompt_input "analyze bug"` | Generate JSON input |
| `run_hook_with_input "path" "json"` | `run_hook_with_input "$hook" "$input"` | Execute hook with input |
| `wait_for_file "path" N` | `wait_for_file "/tmp/f" 5` | Wait up to N seconds |
| `line_count "file"` | `line_count "/tmp/out.txt"` | Count lines in file |
| `debug_output` | `debug_output` | Print debug info (fd 3) |

### Environment Variables

Set automatically by `setup()`:

| Variable | Description |
|----------|-------------|
| `TEST_TMP_DIR` | Unique temp directory for test |
| `PROJECT_ROOT` | Mock project root |
| `HOOKS_DIR` | Mock hooks directory |
| `HOOK_STATE_DIR` | Isolated state directory |
| `CLAUDE_SESSION_ID` | Test session identifier |

---

## Mock System

### Available Mocks

The test helper creates minimal mocks of library dependencies:

| Mock | Function | Location |
|------|----------|----------|
| `output-helpers.sh` | Logging functions | Auto-created |
| `shared-state.sh` | State management | Copied from real or mocked |
| `exit-codes.sh` | Exit code constants | `create_exit_codes_mock` |
| `signal-output.sh` | Question signals | `create_signal_output_mock` |
| `spec-context.sh` | Spec folder utils | `create_spec_context_mock` |

### Creating Custom Mocks

```bash
@test "test with custom mock" {
  # Create custom mock
  cat > "$HOOKS_DIR/lib/custom-lib.sh" << 'EOF'
#!/bin/bash
my_function() {
  echo "mocked response"
}
EOF

  # Source and use
  source "$HOOKS_DIR/lib/custom-lib.sh"
  run my_function
  assert_output_contains "mocked response"
}
```

### Mock Project Structure

Created automatically by `setup()`:

```
$TEST_TMP_DIR/
├── project/
│   ├── .claude/
│   │   ├── hooks/
│   │   │   ├── lib/
│   │   │   ├── logs/
│   │   │   └── UserPromptSubmit/
│   │   └── configs/
│   └── specs/
└── state/           # Isolated hook state
```

---

## Best Practices

### 1. One Assertion Per Test (When Practical)

```bash
# Good - focused test
@test "returns 0 on valid input" {
  run validate_input "valid"
  assert_status 0
}

@test "returns error message on invalid input" {
  run validate_input "invalid"
  assert_output_contains "error"
}

# Acceptable - related assertions
@test "creates spec folder with correct structure" {
  run create_spec_folder "001-test"
  assert_status 0
  assert_dir_exists "$TEST_TMP_DIR/project/specs/001-test"
  assert_dir_exists "$TEST_TMP_DIR/project/specs/001-test/memory"
}
```

### 2. Use Descriptive Test Names

```bash
# Good
@test "write_hook_state creates file with correct content"
@test "enforce-spec-folder blocks when no spec folder selected"

# Bad
@test "test1"
@test "it works"
```

### 3. Keep Tests Independent

Each test should be able to run in isolation:

```bash
# Good - self-contained
@test "function handles empty state" {
  # Setup happens in setup()
  run read_hook_state "nonexistent"
  assert_status 0
  assert_output ""
}

# Bad - depends on other tests
@test "function reads previously written value" {
  # Assumes another test wrote the value!
  run read_hook_state "shared_key"
  assert_output "value"
}
```

### 4. Test Edge Cases

```bash
@test "handles empty input" { ... }
@test "handles special characters in input" { ... }
@test "handles very long input" { ... }
@test "handles concurrent access" { ... }
```

### 5. Use Debug Output During Development

```bash
@test "debugging a failing test" {
  run some_function

  # Print debug info to fd 3 (shown with -v)
  debug_output

  assert_status 0
}
```

---

## CI/CD Integration

### GitHub Actions Example

```yaml
name: Hook Tests

on: [push, pull_request]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Install BATS
        run: |
          sudo apt-get update
          sudo apt-get install -y bats jq

      - name: Run tests
        run: |
          cd .claude/hooks
          ./tests/run-tests.sh --tap > test-results.tap

      - name: Upload results
        uses: actions/upload-artifact@v3
        with:
          name: test-results
          path: .claude/hooks/test-results.tap
```

### TAP Output Format

```bash
# Generate TAP (Test Anything Protocol) output
./tests/run-tests.sh --tap > results.tap
```

TAP output example:
```
TAP version 13
1..54
ok 1 write_hook_state creates state file
ok 2 read_hook_state returns correct value
...
```

### Exit Codes

| Code | Meaning |
|------|---------|
| 0 | All tests passed |
| 1 | One or more tests failed |
| 127 | BATS not installed |

---

## Troubleshooting

### Common Issues

**1. "BATS not installed"**
```bash
# Install BATS
brew install bats-core  # macOS
sudo apt install bats   # Linux
```

**2. "jq: command not found"**
```bash
brew install jq  # macOS
sudo apt install jq  # Linux
```

**3. Tests pass locally but fail in CI**
- Check for hardcoded paths
- Ensure all dependencies are installed
- Verify environment variables

**4. "Permission denied" errors**
```bash
chmod +x tests/run-tests.sh
chmod +x tests/*.bats
```

**5. Debugging failing tests**

```bash
# Run with verbose output
bats --verbose-run tests/lib/shared-state.bats

# Add debug output in test
@test "failing test" {
  run some_function
  debug_output  # Prints to fd 3
  assert_status 0
}
```

### Debug Mode

Run BATS with maximum verbosity:

```bash
bats --verbose-run --trace tests/lib/shared-state.bats
```

### Inspecting Test Environment

```bash
@test "inspect environment" {
  echo "TEST_TMP_DIR: $TEST_TMP_DIR" >&3
  echo "HOOKS_DIR: $HOOKS_DIR" >&3
  echo "PROJECT_ROOT: $PROJECT_ROOT" >&3
  ls -la "$HOOKS_DIR/lib/" >&3

  # Actual test
  run true
  assert_status 0
}
```

---

## Adding New Test Files

### Step-by-Step

1. **Create test file** in appropriate directory:
   ```bash
   touch tests/PostToolUse/my-hook.bats
   chmod +x tests/PostToolUse/my-hook.bats
   ```

2. **Add boilerplate**:
   ```bash
   #!/usr/bin/env bats

   # Adjust path based on directory depth
   load ../test_helper

   # Tests go here
   @test "first test" {
     run true
     assert_status 0
   }
   ```

3. **Run to verify**:
   ```bash
   bats tests/PostToolUse/my-hook.bats
   ```

### Template

```bash
#!/usr/bin/env bats
# ───────────────────────────────────────────────────────────────
# Tests for: [hook/library name]
# ───────────────────────────────────────────────────────────────

load ../test_helper

# ─────────────────────────────────────────
# Setup
# ─────────────────────────────────────────

setup() {
  # Call parent setup
  load ../test_helper

  # Additional setup if needed
}

# ─────────────────────────────────────────
# Basic Functionality
# ─────────────────────────────────────────

@test "basic case works" {
  run true
  assert_status 0
}

# ─────────────────────────────────────────
# Edge Cases
# ─────────────────────────────────────────

@test "handles empty input" {
  run echo ""
  assert_status 0
}

# ─────────────────────────────────────────
# Error Conditions
# ─────────────────────────────────────────

@test "fails gracefully on invalid input" {
  run false
  assert_status 1
}
```

---

## Related Documentation

- **Hooks README**: `../.claude/hooks/README.md` (Section 14)
- **BATS Core**: https://github.com/bats-core/bats-core
- **BATS Assertion Libraries**: https://github.com/bats-core/bats-assert
- **TAP Protocol**: https://testanything.org/

---

**Version**: 1.0.0
**Created**: 2025-12-03
**Maintainer**: Claude Code Hooks System
