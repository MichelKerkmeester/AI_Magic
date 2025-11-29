#!/bin/bash

# ───────────────────────────────────────────────────────────────
# REAL-WORLD TEST CASES: Verification Enforcement Hook
# ───────────────────────────────────────────────────────────────
# Tests using actual prompts from enforce-verification.log
# Version: 3.0.0
# Updated: 2025-11-29
# ───────────────────────────────────────────────────────────────

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HOOK_SCRIPT="$SCRIPT_DIR/enforce-verification.sh"

# Test counter
TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0

# Color codes
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Test helper
run_test() {
  local test_name="$1"
  local prompt="$2"
  local expected_result="$3"  # "allow" or "block"

  ((TESTS_RUN++))

  # Create JSON input
  local json_input=$(jq -n --arg prompt "$prompt" '{prompt: $prompt}')

  # Run hook
  echo "$json_input" | "$HOOK_SCRIPT" > /dev/null 2>&1
  local exit_code=$?

  # Determine actual result
  local actual_result="allow"
  if [ $exit_code -eq 1 ]; then
    actual_result="block"
  fi

  # Check result
  if [ "$actual_result" == "$expected_result" ]; then
    echo -e "${GREEN}✓${NC} PASS: $test_name"
    ((TESTS_PASSED++))
  else
    echo -e "${RED}✗${NC} FAIL: $test_name"
    echo -e "   Expected: $expected_result, Got: $actual_result"
    echo -e "   Prompt: ${prompt:0:100}..."
    ((TESTS_FAILED++))
  fi
}

echo "═══════════════════════════════════════════════════════════════"
echo "REAL-WORLD FALSE POSITIVE TESTS"
echo "═══════════════════════════════════════════════════════════════"
echo "Testing actual prompts from enforce-verification.log"
echo ""

# ───────────────────────────────────────────────────────────────
# FALSE POSITIVES FROM LOG (Should now ALLOW)
# ───────────────────────────────────────────────────────────────

run_test "Log FP #1: Reduce examples" \
  "Reduce amount of examples in /path/to/your/project/.claude/skills/create-documentation/assets/skill_md_template.md to reduce line count We only need 1 really good example" \
  "allow"

run_test "Log FP #2: Consolidate spec" \
  "Consolidate spec 123 124 125 (mcp and knowledge) into spec folder 122, but 122 is the main most recently updated one so make sure to fix logic / allignment issues from 123 / 124 when merging into 122" \
  "allow"

run_test "Log FP #3: Update logic with subfolder" \
  "Update the logic a bit. So that each subfolder also has a number, example: 122/ ---001/sub-folder --- 002/sub-folder, etc. After updating that logic, Double check for bugs and things you might have missed" \
  "allow"

run_test "Log FP #4: When done instruction" \
  "Double check for bugs and things you might have missed. When done. Update Hooks README, Skills README and save context in spec sub-folder. Afterwards Check if AGENTS.md & CLAUDE.md are aligned with recent skills and changes" \
  "allow"

run_test "Log FP #5: Double check properly working" \
  "double check if all speckit scripts and related hooks are properly working" \
  "allow"

run_test "Log FP #6: Make sure it still works" \
  "Test all speckit hooks, scripts, etc to make sure it still works (ultrathink)" \
  "allow"

run_test "Log FP #7: Combine phases" \
  "in Workflows-code combine the phases here. so phase 1 capabilities and then use case, after that phase 2, etc." \
  "allow"

run_test "Log FP #8: Convert diagrams whatever works" \
  "Analyze all skill.md files in this folder and Convert all smart routing diagrams to python or yaml pseudo code (whatever works best)" \
  "allow"

run_test "Log FP #9: Make sure README is up to date" \
  "Analyze all skills and make sure the README is completely up to date (Think really hard about this... Use ultrathink)" \
  "allow"

run_test "Log FP #10: Make sure hooks README is up to date" \
  "Analyze all hooks and make sure the README is completely up to date (Think really hard about this... Use ultrathink)" \
  "allow"

run_test "Log FP #11: Apply fixes missing from README" \
  "Apply fixes to: 1. Missing Skill Discovered - create-hooks (v1.0.0) was completely missing from the README - Full skill with 15 files (5 references, 8 assets, 2 scripts) - Comprehensive hook creation documentation" \
  "allow"

run_test "Log FP #12: Create testing suite" \
  "Analyze this skill for bugs also the related hooks. And create a testing suite to properly test this skill" \
  "allow"

run_test "Log FP #13: Investigate why wasn't working" \
  "investigate why the hook that should show parallel agent descriptions + tasks wasn't working Think really hard about this... Use ultrathink" \
  "allow"

run_test "Log FP #14: Improve adherences" \
  "Improve adherences to automatic spec folder creation, asking of user which spec folder to use. And proper detection for when an ai is working on something where there is no spec folder for or the one" \
  "allow"

run_test "Log FP #15: Create template" \
  "Analyze and Create a template for commands" \
  "allow"

run_test "Log FP #16: Remove diagram" \
  "Remove the smart routing diagram from plan skill" \
  "allow"

echo ""

# ───────────────────────────────────────────────────────────────
# TRUE POSITIVES FROM LOG (Should still BLOCK)
# ───────────────────────────────────────────────────────────────
echo "Real-World True Positives (Should Block)"
echo "───────────────────────────────────────────────────────────────"

run_test "Log TP #1: Animation is complete" \
  "The animation is complete" \
  "block"

run_test "Log TP #2: Done, tested in Chrome (1 evidence)" \
  "Done, tested in Chrome" \
  "block"

run_test "Log TP #3: Done, DevTools console clear (1 evidence)" \
  "Done, DevTools console is clear" \
  "block"

run_test "Log TP #4: Done, tested at 1920px (1 evidence)" \
  "Done, tested at 1920px" \
  "block"

run_test "Log TP #5: Animation is working now" \
  "Animation is working now" \
  "block"

echo ""

# ───────────────────────────────────────────────────────────────
# RESULTS SUMMARY
# ───────────────────────────────────────────────────────────────
echo "═══════════════════════════════════════════════════════════════"
echo "REAL-WORLD TEST RESULTS"
echo "═══════════════════════════════════════════════════════════════"
echo "Total Tests:   $TESTS_RUN"
echo -e "Passed:        ${GREEN}$TESTS_PASSED${NC}"
echo -e "Failed:        ${RED}$TESTS_FAILED${NC}"

if [ $TESTS_FAILED -eq 0 ]; then
  echo ""
  echo -e "${GREEN}✓ ALL REAL-WORLD TESTS PASSED${NC}"
  echo "False Positive Rate: 0% (was ~40% in v2.0.0)"
  echo ""
  exit 0
else
  PASS_RATE=$(awk "BEGIN {printf \"%.1f\", ($TESTS_PASSED / $TESTS_RUN) * 100}")
  echo ""
  echo -e "${RED}✗ SOME TESTS FAILED${NC}"
  echo "Pass Rate: $PASS_RATE%"
  echo ""
  exit 1
fi
