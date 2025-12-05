#!/bin/bash
# ───────────────────────────────────────────────────────────────
# BATS TEST RUNNER
# ───────────────────────────────────────────────────────────────
# Runs all BATS tests for Claude hooks.
#
# Usage:
#   ./run-tests.sh           # Run all tests
#   ./run-tests.sh lib/      # Run tests in lib/ directory only
#   ./run-tests.sh -v        # Verbose output
#   ./run-tests.sh --tap     # TAP output format
#
# Version: 1.0.0
# Created: 2025-12-03
# ───────────────────────────────────────────────────────────────

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HOOKS_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Print colored output
print_header() {
  echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
  echo -e "${BLUE}  BATS Test Runner for Claude Hooks${NC}"
  echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
  echo ""
}

print_success() {
  echo -e "${GREEN}[PASS]${NC} $1"
}

print_failure() {
  echo -e "${RED}[FAIL]${NC} $1"
}

print_warning() {
  echo -e "${YELLOW}[WARN]${NC} $1"
}

print_info() {
  echo -e "${BLUE}[INFO]${NC} $1"
}

# Check if BATS is installed
check_bats() {
  if ! command -v bats &> /dev/null; then
    echo ""
    print_failure "BATS (Bash Automated Testing System) is not installed"
    echo ""
    echo "Install BATS using one of these methods:"
    echo ""
    echo "  macOS (Homebrew):"
    echo "    brew install bats-core"
    echo ""
    echo "  Linux (apt):"
    echo "    sudo apt install bats"
    echo ""
    echo "  From source:"
    echo "    git clone https://github.com/bats-core/bats-core.git"
    echo "    cd bats-core && sudo ./install.sh /usr/local"
    echo ""
    echo "For assertion helpers (recommended):"
    echo "    brew install bats-support bats-assert"
    echo "    # or"
    echo "    git clone https://github.com/bats-core/bats-support.git /usr/local/lib/bats-support"
    echo "    git clone https://github.com/bats-core/bats-assert.git /usr/local/lib/bats-assert"
    echo ""
    exit 1
  fi
}

# Check for jq (required by many hooks)
check_jq() {
  if ! command -v jq &> /dev/null; then
    print_warning "jq is not installed - some tests may fail"
    echo "  Install with: brew install jq (macOS) or apt install jq (Linux)"
    echo ""
  fi
}

# Find all .bats test files
find_tests() {
  local target="${1:-.}"

  if [ -d "$SCRIPT_DIR/$target" ]; then
    find "$SCRIPT_DIR/$target" -name "*.bats" -type f ! -path "*/templates/*" | sort
  elif [ -f "$SCRIPT_DIR/$target" ]; then
    echo "$SCRIPT_DIR/$target"
  else
    echo ""
  fi
}

# Run tests and capture results
run_tests() {
  local target="${1:-.}"
  local bats_args=()
  local verbose=false
  local tap_output=false

  # Parse arguments
  while [[ $# -gt 0 ]]; do
    case "$1" in
      -v|--verbose)
        verbose=true
        bats_args+=("--verbose-run")
        shift
        ;;
      --tap)
        tap_output=true
        bats_args+=("--formatter" "tap")
        shift
        ;;
      --timing)
        bats_args+=("--timing")
        shift
        ;;
      --jobs)
        bats_args+=("--jobs" "$2")
        shift 2
        ;;
      *)
        target="$1"
        shift
        ;;
    esac
  done

  # Find test files
  local test_files
  test_files=$(find_tests "$target")

  if [ -z "$test_files" ]; then
    print_warning "No .bats test files found in: $target"
    exit 0
  fi

  # Count test files
  local file_count
  file_count=$(echo "$test_files" | wc -l | tr -d ' ')

  print_info "Found $file_count test file(s)"
  echo ""

  # Show test files to be run
  if [ "$verbose" = true ]; then
    echo "Test files:"
    echo "$test_files" | while read -r f; do
      echo "  - $(basename "$f")"
    done
    echo ""
  fi

  # Run BATS
  print_info "Running tests..."
  echo ""

  # Export paths for tests
  export HOOKS_DIR="$HOOKS_DIR"
  export PROJECT_ROOT="$(cd "$HOOKS_DIR/../.." && pwd)"

  # Run BATS with collected arguments
  if bats "${bats_args[@]}" $test_files; then
    echo ""
    print_success "All tests passed!"
    return 0
  else
    echo ""
    print_failure "Some tests failed"
    return 1
  fi
}

# Print usage
usage() {
  echo "Usage: $(basename "$0") [OPTIONS] [TARGET]"
  echo ""
  echo "Options:"
  echo "  -v, --verbose    Verbose output (show test details)"
  echo "  --tap            Output in TAP format"
  echo "  --timing         Show timing for each test"
  echo "  --jobs N         Run N tests in parallel"
  echo "  -h, --help       Show this help message"
  echo ""
  echo "Target:"
  echo "  Directory or file to run tests from (default: all tests)"
  echo ""
  echo "Examples:"
  echo "  $(basename "$0")                    # Run all tests"
  echo "  $(basename "$0") lib/               # Run tests in lib/ directory"
  echo "  $(basename "$0") UserPromptSubmit/  # Run UserPromptSubmit tests"
  echo "  $(basename "$0") -v --timing        # Verbose with timing"
  echo ""
}

# Main entry point
main() {
  # Handle help
  if [[ "$1" == "-h" ]] || [[ "$1" == "--help" ]]; then
    usage
    exit 0
  fi

  print_header

  # Check dependencies
  check_bats
  check_jq

  # Run tests
  run_tests "$@"
}

main "$@"
