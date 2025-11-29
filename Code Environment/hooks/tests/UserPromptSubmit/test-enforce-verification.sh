#!/bin/bash

# ───────────────────────────────────────────────────────────────
# TEST SUITE: Verification Enforcement Hook
# ───────────────────────────────────────────────────────────────
# Tests for false positive elimination in enforce-verification.sh
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
    echo -e "   Prompt: $prompt"
    ((TESTS_FAILED++))
  fi
}

echo "═══════════════════════════════════════════════════════════════"
echo "VERIFICATION ENFORCEMENT HOOK - TEST SUITE v3.0.0"
echo "═══════════════════════════════════════════════════════════════"
echo ""

# ───────────────────────────────────────────────────────────────
# TEST GROUP 1: Should ALLOW (False Positive Prevention)
# ───────────────────────────────────────────────────────────────
echo "Test Group 1: False Positive Prevention (Should Allow)"
echo "───────────────────────────────────────────────────────────────"

run_test "FP1: Imperative instruction with 'works'" \
  "Analyze all skill.md files and convert diagrams to python or yaml pseudo code (whatever works best)" \
  "allow"

run_test "FP2: Make sure instruction" \
  "Test all speckit hooks, scripts, etc to make sure it still works (ultrathink)" \
  "allow"

run_test "FP3: Temporal marker with compound instruction" \
  "Double check for bugs and things you might have missed. When done. Update Hooks README, Skills README and save context in spec sub-folder." \
  "allow"

run_test "FP4: Ensure/verify instruction" \
  "Analyze all skills and make sure the README is completely up to date" \
  "allow"

run_test "FP5: Future intent with 'working'" \
  "Double check if all speckit scripts and related hooks are properly working" \
  "allow"

run_test "FP6: Create instruction" \
  "Create a testing suite to properly test the parallel agent functionality" \
  "allow"

run_test "FP7: Investigate with 'working'" \
  "Investigate why the hook that should show parallel agent descriptions + tasks wasn't working" \
  "allow"

run_test "FP8: Modal verb - should work" \
  "After this fix, the animation should work perfectly" \
  "allow"

run_test "FP9: Conditional - if it works" \
  "Check if the feature works and report back" \
  "allow"

run_test "FP10: Infinitive phrase" \
  "Update the code to make sure everything is working correctly" \
  "allow"

echo ""

# ───────────────────────────────────────────────────────────────
# TEST GROUP 2: Should BLOCK (True Positives)
# ───────────────────────────────────────────────────────────────
echo "Test Group 2: True Positive Detection (Should Block)"
echo "───────────────────────────────────────────────────────────────"

run_test "TP1: Explicit completion claim" \
  "The animation is complete" \
  "block"

run_test "TP2: Single word completion" \
  "Done." \
  "block"

run_test "TP3: Component state claim" \
  "The animation works perfectly now" \
  "block"

run_test "TP4: Everything works claim" \
  "Everything is working now" \
  "block"

run_test "TP5: Past tense completion" \
  "I have completed the implementation" \
  "block"

run_test "TP6: Present tense with article" \
  "This is done and ready for review" \
  "block"

run_test "TP7: Feature ready claim" \
  "The feature is ready for production" \
  "block"

run_test "TP8: All fixed claim" \
  "All issues fixed" \
  "block"

run_test "TP9: Component working claim" \
  "The video player is working now" \
  "block"

run_test "TP10: Finished claim" \
  "I just finished implementing the animation" \
  "block"

echo ""

# ───────────────────────────────────────────────────────────────
# TEST GROUP 3: Should ALLOW (Valid Evidence Present)
# ───────────────────────────────────────────────────────────────
echo "Test Group 3: Completion with Valid Evidence (Should Allow)"
echo "───────────────────────────────────────────────────────────────"

run_test "VE1: Complete with 2+ evidence" \
  "The animation is complete. Tested in Chrome at 1920px and 375px, DevTools console clear, no errors." \
  "allow"

run_test "VE2: Done with browser + console" \
  "Done. Tested in Firefox, opened browser and saw smooth animation, console shows no errors." \
  "allow"

run_test "VE3: Working with viewport + observation" \
  "Everything is working. Tested at desktop and mobile viewports, watched the animation play smoothly." \
  "allow"

echo ""

# ───────────────────────────────────────────────────────────────
# TEST GROUP 4: Should BLOCK (Insufficient Evidence)
# ───────────────────────────────────────────────────────────────
echo "Test Group 4: Completion with Insufficient Evidence (Should Block)"
echo "───────────────────────────────────────────────────────────────"

run_test "IE1: Only browser mentioned" \
  "Done. Tested in Chrome." \
  "block"

run_test "IE2: Only console mentioned" \
  "The animation is complete. Console is clear." \
  "block"

run_test "IE3: Only viewport mentioned" \
  "Everything works. Tested at 1920px." \
  "block"

echo ""

# ───────────────────────────────────────────────────────────────
# TEST GROUP 5: Edge Cases
# ───────────────────────────────────────────────────────────────
echo "Test Group 5: Edge Cases"
echo "───────────────────────────────────────────────────────────────"

run_test "EC1: Negation - not working" \
  "The feature is not working as expected" \
  "allow"

run_test "EC2: Question - is it working" \
  "Is the animation working correctly?" \
  "allow"

run_test "EC3: Will be done (future)" \
  "This will be done by tomorrow" \
  "allow"

run_test "EC4: Whatever works (option)" \
  "Use whatever works best for the implementation" \
  "allow"

run_test "EC5: Mid-sentence 'done'" \
  "After we're done with testing, deploy to production" \
  "allow"

echo ""

# ───────────────────────────────────────────────────────────────
# RESULTS SUMMARY
# ───────────────────────────────────────────────────────────────
echo "═══════════════════════════════════════════════════════════════"
echo "TEST RESULTS SUMMARY"
echo "═══════════════════════════════════════════════════════════════"
echo "Total Tests:   $TESTS_RUN"
echo -e "Passed:        ${GREEN}$TESTS_PASSED${NC}"
echo -e "Failed:        ${RED}$TESTS_FAILED${NC}"

if [ $TESTS_FAILED -eq 0 ]; then
  echo ""
  echo -e "${GREEN}✓ ALL TESTS PASSED${NC}"
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
