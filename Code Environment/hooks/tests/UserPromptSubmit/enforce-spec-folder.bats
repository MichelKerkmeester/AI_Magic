#!/usr/bin/env bats
# ───────────────────────────────────────────────────────────────
# TESTS: enforce-spec-folder.sh
# ───────────────────────────────────────────────────────────────
# Tests for the spec folder enforcement hook that detects
# implementation intent and requires spec documentation.
#
# Run with: bats UserPromptSubmit/enforce-spec-folder.bats
# ───────────────────────────────────────────────────────────────

# Load test helper
load '../test_helper'

# ───────────────────────────────────────────────────────────────
# HELPER: Extract and test detect_modification_intent function
# ───────────────────────────────────────────────────────────────
# Since the full hook has many dependencies, we extract just the
# detection logic for unit testing.

# Create a minimal test script that sources only what we need
create_intent_tester() {
  cat > "$TEST_TMP_DIR/intent_tester.sh" << 'INTENT_SCRIPT'
#!/bin/bash
# Minimal intent detection test harness

# Mirror the real hook's behavior: lowercase the input first
PROMPT_LOWER=$(echo "$1" | tr '[:upper:]' '[:lower:]')

MODIFICATION_KEYWORDS=(
  "add" "adjust" "apply" "build" "change" "continue" "create" "delete" "edit" "enhance" "fix"
  "implement" "improve" "modify" "optimize" "patch" "proceed" "refactor" "remove" "replace"
  "resume" "revamp" "rewrite" "ship" "update" "write"
)

DETECTED_INTENT=""

detect_modification_intent() {
  # Treat "can you/could you/would you" requests that clearly ask to
  # implement or change something as modification intent, not pure questions
  if echo "$PROMPT_LOWER" | grep -qiE "^(can you|could you|would you).*(implement|add|fix|build|refactor|update|change|create|modify)"; then
    DETECTED_INTENT="question-implement"
    return 0
  fi

  # First check if this is a question (no modification intent)
  if echo "$PROMPT_LOWER" | grep -qE "^(what|how|why|when|where|who|which|can you|could you|would you|should|do you|does|is|are|show me|explain|tell me|help me understand)"; then
    return 1  # No modification intent
  fi

  # Check for question words + review/explain (read-only intent)
  if echo "$PROMPT_LOWER" | grep -qE "(explain|review|show|describe|tell).*(what|how|why|code|flow|work)"; then
    return 1  # No modification intent
  fi

  # Detect session continuation patterns
  if echo "$PROMPT_LOWER" | grep -qiE "(continue|resume|proceed|pick up|carry on).*(conversation|session|task|work|where.*left|from where|last task|from last)"; then
    DETECTED_INTENT="session-continuation"
    return 0
  fi

  # Detect "continue with" followed by implementation verbs
  if echo "$PROMPT_LOWER" | grep -qiE "continue.*(with|on|the|implementing|building|fixing|working)"; then
    DETECTED_INTENT="continuation-implementation"
    return 0
  fi

  # Detect "proceed with" implementation patterns
  if echo "$PROMPT_LOWER" | grep -qiE "proceed.*(with|to|on).*(implementation|plan|task|work|coding|building)"; then
    DETECTED_INTENT="proceed-implementation"
    return 0
  fi

  # Detect analysis with issue/bug intent
  if echo "$PROMPT_LOWER" | grep -qiE "analyze.*(issue|bug|problem|error|broken|not working|failing|wrong|incorrect)"; then
    DETECTED_INTENT="analysis-with-fix-intent"
    return 0
  fi

  # Detect investigation patterns that imply upcoming fixes
  if echo "$PROMPT_LOWER" | grep -qiE "(investigate|diagnose|troubleshoot|debug).*(issue|bug|problem|error|why.*(not|broken|failing))"; then
    DETECTED_INTENT="investigation-with-fix-intent"
    return 0
  fi

  # Detect "Issue:" or "Bug:" or "Problem:" headers
  if echo "$PROMPT_LOWER" | grep -qiE "(^|[|:])\s*(issue|bug|problem)\s*:"; then
    DETECTED_INTENT="issue-report"
    return 0
  fi

  for keyword in "${MODIFICATION_KEYWORDS[@]}"; do
    if [[ "$PROMPT_LOWER" == *"$keyword"* ]] || [[ "$PROMPT_LOWER" == *"$keyword "* ]]; then
      DETECTED_INTENT="$keyword"
      return 0
    fi
  done

  if echo "$PROMPT_LOWER" | grep -qE "let['']?s (code|start|implement|build)"; then
    DETECTED_INTENT="collaborative-build"
    return 0
  fi

  return 1
}

# Run detection
if detect_modification_intent; then
  echo "INTENT_DETECTED:$DETECTED_INTENT"
  exit 0
else
  echo "NO_INTENT"
  exit 1
fi
INTENT_SCRIPT
  chmod +x "$TEST_TMP_DIR/intent_tester.sh"
}

# Setup for each test
setup() {
  TEST_TMP_DIR=$(mktemp -d "${TMPDIR:-/tmp}/bats_test.XXXXXX")
  create_intent_tester
}

teardown() {
  if [ -n "$TEST_TMP_DIR" ] && [ -d "$TEST_TMP_DIR" ]; then
    rm -rf "$TEST_TMP_DIR"
  fi
}

# ───────────────────────────────────────────────────────────────
# TESTS: Implementation Intent Detection - SHOULD TRIGGER
# ───────────────────────────────────────────────────────────────

@test "detect intent: 'analyze the bug' triggers spec folder" {
  run "$TEST_TMP_DIR/intent_tester.sh" "analyze the bug in the login form"

  [ "$status" -eq 0 ]
  [[ "$output" == *"INTENT_DETECTED"* ]]
  [[ "$output" == *"analysis-with-fix-intent"* ]]
}

@test "detect intent: 'Issue: broken' (known issue - falsely matches question pattern)" {
  # KNOWN BUG: "issue:" falsely matches ^is in question pattern
  # The regex ^(is|are|...) matches "issue:" because "issue" starts with "is"
  # This test documents the current (buggy) behavior - should be fixed in the hook
  run "$TEST_TMP_DIR/intent_tester.sh" "issue: the authentication is broken"

  # Currently returns NO_INTENT due to false question pattern match
  [ "$status" -eq 1 ]
  [[ "$output" == "NO_INTENT" ]]
}

@test "detect intent: 'Found | issue:' with pipe triggers spec folder" {
  # The regex matches issue: after ^ or | or :
  # Using pipe separator to trigger the pattern
  run "$TEST_TMP_DIR/intent_tester.sh" "Found | issue: auth is broken"

  [ "$status" -eq 0 ]
  [[ "$output" == *"INTENT_DETECTED"* ]]
  [[ "$output" == *"issue-report"* ]]
}

@test "detect intent: 'Bug: not working' triggers spec folder" {
  run "$TEST_TMP_DIR/intent_tester.sh" "bug: login not working properly"

  [ "$status" -eq 0 ]
  [[ "$output" == *"INTENT_DETECTED"* ]]
  [[ "$output" == *"issue-report"* ]]
}

@test "detect intent: 'implement user auth' triggers spec folder" {
  run "$TEST_TMP_DIR/intent_tester.sh" "implement user authentication"

  [ "$status" -eq 0 ]
  [[ "$output" == *"INTENT_DETECTED"* ]]
  [[ "$output" == *"implement"* ]]
}

@test "detect intent: 'fix the broken button' triggers spec folder" {
  run "$TEST_TMP_DIR/intent_tester.sh" "fix the broken button on the homepage"

  [ "$status" -eq 0 ]
  [[ "$output" == *"INTENT_DETECTED"* ]]
  [[ "$output" == *"fix"* ]]
}

@test "detect intent: 'add dark mode' triggers spec folder" {
  run "$TEST_TMP_DIR/intent_tester.sh" "add dark mode toggle to settings"

  [ "$status" -eq 0 ]
  [[ "$output" == *"INTENT_DETECTED"* ]]
  [[ "$output" == *"add"* ]]
}

@test "detect intent: 'refactor the service' triggers spec folder" {
  run "$TEST_TMP_DIR/intent_tester.sh" "refactor the user service class"

  [ "$status" -eq 0 ]
  [[ "$output" == *"INTENT_DETECTED"* ]]
  [[ "$output" == *"refactor"* ]]
}

@test "detect intent: 'update the config' triggers spec folder" {
  run "$TEST_TMP_DIR/intent_tester.sh" "update the configuration file"

  [ "$status" -eq 0 ]
  [[ "$output" == *"INTENT_DETECTED"* ]]
  [[ "$output" == *"update"* ]]
}

@test "detect intent: 'delete old files' triggers spec folder" {
  run "$TEST_TMP_DIR/intent_tester.sh" "delete the old migration files"

  [ "$status" -eq 0 ]
  [[ "$output" == *"INTENT_DETECTED"* ]]
  [[ "$output" == *"delete"* ]]
}

@test "detect intent: 'continue from last session' triggers spec folder" {
  run "$TEST_TMP_DIR/intent_tester.sh" "continue from where we left off last session"

  [ "$status" -eq 0 ]
  [[ "$output" == *"INTENT_DETECTED"* ]]
  [[ "$output" == *"session-continuation"* ]]
}

@test "detect intent: 'proceed with implementation' triggers spec folder" {
  run "$TEST_TMP_DIR/intent_tester.sh" "proceed with the implementation plan"

  [ "$status" -eq 0 ]
  [[ "$output" == *"INTENT_DETECTED"* ]]
  [[ "$output" == *"proceed-implementation"* ]]
}

@test "detect intent: 'lets code now' triggers spec folder" {
  # Note: The regex uses let['']?s which matches curly quotes or no apostrophe
  # Testing with "lets code" (no apostrophe, uses "code" not "implement")
  # to test the collaborative-build pattern without hitting keyword match first
  run "$TEST_TMP_DIR/intent_tester.sh" "lets code now"

  [ "$status" -eq 0 ]
  [[ "$output" == *"INTENT_DETECTED"* ]]
  [[ "$output" == *"collaborative-build"* ]]
}

@test "detect intent: 'debug why it fails' triggers spec folder" {
  run "$TEST_TMP_DIR/intent_tester.sh" "debug why the test is failing"

  [ "$status" -eq 0 ]
  [[ "$output" == *"INTENT_DETECTED"* ]]
  [[ "$output" == *"investigation-with-fix-intent"* ]]
}

@test "detect intent: 'can you implement auth' triggers spec folder" {
  run "$TEST_TMP_DIR/intent_tester.sh" "can you implement the auth module"

  [ "$status" -eq 0 ]
  [[ "$output" == *"INTENT_DETECTED"* ]]
  [[ "$output" == *"question-implement"* ]]
}

@test "detect intent: 'could you fix this bug' triggers spec folder" {
  run "$TEST_TMP_DIR/intent_tester.sh" "could you fix this bug in the parser"

  [ "$status" -eq 0 ]
  [[ "$output" == *"INTENT_DETECTED"* ]]
  [[ "$output" == *"question-implement"* ]]
}

# ───────────────────────────────────────────────────────────────
# TESTS: No Implementation Intent - SHOULD NOT TRIGGER
# ───────────────────────────────────────────────────────────────

@test "no intent: 'read the file' does NOT trigger spec folder" {
  run "$TEST_TMP_DIR/intent_tester.sh" "read the configuration file"

  [ "$status" -eq 1 ]
  [[ "$output" == "NO_INTENT" ]]
}

@test "no intent: 'what does this function do' does NOT trigger" {
  run "$TEST_TMP_DIR/intent_tester.sh" "what does the handleSubmit function do"

  [ "$status" -eq 1 ]
  [[ "$output" == "NO_INTENT" ]]
}

@test "no intent: 'how does auth work' does NOT trigger" {
  run "$TEST_TMP_DIR/intent_tester.sh" "how does the authentication work"

  [ "$status" -eq 1 ]
  [[ "$output" == "NO_INTENT" ]]
}

@test "no intent: 'explain the code flow' does NOT trigger" {
  run "$TEST_TMP_DIR/intent_tester.sh" "explain the code flow in this module"

  [ "$status" -eq 1 ]
  [[ "$output" == "NO_INTENT" ]]
}

@test "no intent: 'show me the config' does NOT trigger" {
  run "$TEST_TMP_DIR/intent_tester.sh" "show me the database configuration"

  [ "$status" -eq 1 ]
  [[ "$output" == "NO_INTENT" ]]
}

@test "no intent: 'why is this test failing' (question) does NOT trigger" {
  run "$TEST_TMP_DIR/intent_tester.sh" "why is this test failing"

  [ "$status" -eq 1 ]
  [[ "$output" == "NO_INTENT" ]]
}

@test "no intent: 'tell me how this works' does NOT trigger" {
  run "$TEST_TMP_DIR/intent_tester.sh" "tell me how the caching works"

  [ "$status" -eq 1 ]
  [[ "$output" == "NO_INTENT" ]]
}

@test "no intent: 'describe the architecture' does NOT trigger" {
  run "$TEST_TMP_DIR/intent_tester.sh" "describe how the architecture works"

  [ "$status" -eq 1 ]
  [[ "$output" == "NO_INTENT" ]]
}

@test "no intent: 'can you explain this' does NOT trigger" {
  run "$TEST_TMP_DIR/intent_tester.sh" "can you explain this code to me"

  [ "$status" -eq 1 ]
  [[ "$output" == "NO_INTENT" ]]
}

@test "no intent: 'is this correct' does NOT trigger" {
  run "$TEST_TMP_DIR/intent_tester.sh" "is this the correct approach"

  [ "$status" -eq 1 ]
  [[ "$output" == "NO_INTENT" ]]
}

@test "no intent: 'review the code' does NOT trigger" {
  run "$TEST_TMP_DIR/intent_tester.sh" "review what the code does here"

  [ "$status" -eq 1 ]
  [[ "$output" == "NO_INTENT" ]]
}

# ───────────────────────────────────────────────────────────────
# TESTS: Edge Cases
# ───────────────────────────────────────────────────────────────

@test "edge case: empty prompt does NOT trigger" {
  run "$TEST_TMP_DIR/intent_tester.sh" ""

  [ "$status" -eq 1 ]
  [[ "$output" == "NO_INTENT" ]]
}

@test "edge case: single word 'fix' triggers" {
  run "$TEST_TMP_DIR/intent_tester.sh" "fix"

  [ "$status" -eq 0 ]
  [[ "$output" == *"INTENT_DETECTED"* ]]
}

@test "edge case: 'Problem:' with colon triggers" {
  run "$TEST_TMP_DIR/intent_tester.sh" "problem: the api is slow"

  [ "$status" -eq 0 ]
  [[ "$output" == *"INTENT_DETECTED"* ]]
  [[ "$output" == *"issue-report"* ]]
}

@test "edge case: mixed case 'IMPLEMENT' triggers" {
  run "$TEST_TMP_DIR/intent_tester.sh" "IMPLEMENT the new feature"

  # The function uses grep -i for case-insensitive matching on patterns
  # but keyword matching is case-sensitive, so this tests lowercase conversion
  [ "$status" -eq 0 ]
  [[ "$output" == *"INTENT_DETECTED"* ]]
}

@test "edge case: keyword in middle of sentence triggers" {
  run "$TEST_TMP_DIR/intent_tester.sh" "please add a new button to the form"

  [ "$status" -eq 0 ]
  [[ "$output" == *"INTENT_DETECTED"* ]]
  [[ "$output" == *"add"* ]]
}

@test "edge case: 'write tests' triggers" {
  run "$TEST_TMP_DIR/intent_tester.sh" "write unit tests for the service"

  [ "$status" -eq 0 ]
  [[ "$output" == *"INTENT_DETECTED"* ]]
  [[ "$output" == *"write"* ]]
}

@test "edge case: 'build the component' triggers" {
  run "$TEST_TMP_DIR/intent_tester.sh" "build the new dashboard component"

  [ "$status" -eq 0 ]
  [[ "$output" == *"INTENT_DETECTED"* ]]
  [[ "$output" == *"build"* ]]
}
