#!/bin/bash

# ───────────────────────────────────────────────────────────────
# VERIFICATION ENFORCEMENT HOOK - "The Iron Law"
# ───────────────────────────────────────────────────────────────
# UserPromptSubmit hook that BLOCKS completion claims without verification
# NO COMPLETION CLAIMS WITHOUT FRESH BROWSER VERIFICATION EVIDENCE
#
# Behavior: exit 1 (BLOCKS) when completion claim detected without evidence
# Updated: 2025-11-29 (false positive elimination)
# Version: 3.0.0
#
# PERFORMANCE TARGET: <50ms (lightweight pattern matching)
# COMPATIBILITY: Bash 3.2+ (macOS and Linux compatible)
#
# EXECUTION ORDER: UserPromptSubmit hook (runs BEFORE user prompt processing)
#   1. UserPromptSubmit hooks run FIRST (before processing user input)
#   2. PreToolUse hooks run SECOND (before tool execution, validation)
#   3. PostToolUse hooks run LAST (after tool completion, verification)
#   This hook: Blocks completion claims without browser verification evidence
#
# EXIT CODE CONVENTION:
#   0 = Allow (hook passed, continue execution)
#   1 = Block (hook failed, stop execution with warning)
#   2 = Error (reserved for critical failures)
# ───────────────────────────────────────────────────────────────

# Source output helpers
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" 2>/dev/null && pwd)"
source "$SCRIPT_DIR/../lib/output-helpers.sh" || exit 0

# Cross-platform nanosecond timing helper
_get_nano_time() {
  if [[ "$OSTYPE" == "darwin"* ]]; then
    echo $(($(date +%s) * 1000000000))
  else
    date +%s%N 2>/dev/null || echo $(($(date +%s) * 1000000000))
  fi
}

# Performance timing START
START_TIME=$(_get_nano_time)

# Read JSON input from stdin
INPUT=$(cat)

# Extract the prompt from JSON
PROMPT=$(echo "$INPUT" | jq -r '.prompt // empty' 2>/dev/null)

# If no prompt found, allow it
if [ -z "$PROMPT" ]; then
  exit 0
fi

# Convert to lowercase for matching
PROMPT_LOWER=$(echo "$PROMPT" | tr '[:upper:]' '[:lower:]')

# ───────────────────────────────────────────────────────────────
# COMPLETION CLAIM DETECTION (v3.0.0 - False Positive Elimination)
# ───────────────────────────────────────────────────────────────

# Detect completion claims with high precision
detect_completion_claim() {
  local text="$1"

  # PATTERN 1: Explicit past tense completion statements
  # Matches: "I have completed", "I've fixed", "I finished"
  # Avoids: "to complete", "will complete", "should complete"
  if echo "$text" | grep -qiE "(I have|I've|I just|I already|I successfully) (completed|finished|fixed|implemented|verified|tested)"; then
    return 0
  fi

  # PATTERN 2: Present tense completion with definitive language
  # Matches: "This is complete", "Everything is done", "The fix is ready"
  # Avoids: "should be done", "will be ready", "to be complete"
  # Key: Requires definitive article/pronoun + "is/are" + completion word at sentence boundary
  if echo "$text" | grep -qiE "^(this|that|it|everything|the [a-z]+) (is|are) (now )?(complete|done|fixed|working|ready|finished)"; then
    return 0
  fi

  # PATTERN 3: Single-word completion claims at start of prompt
  # Matches: "Done.", "Complete.", "Fixed.", "Ready."
  # Avoids: "done with X" in middle of sentence, "when done"
  # Key: Must be at start (^) or after period, followed by punctuation or end
  if echo "$text" | grep -qiE "^(done|complete|fixed|ready|finished)[\.,!\?]"; then
    return 0
  fi

  # PATTERN 4: Feature/component state claims (specific artifacts)
  # Matches: "The animation works perfectly", "Video player is working now"
  # Avoids: "to make the animation work", "ensure video works"
  # Key: Requires "the" + artifact + present tense verb (no modals)
  if echo "$text" | grep -qiE "the (animation|layout|video|video player|form|feature|component|page|button|modal) (works|is working|has been fixed|is now (working|ready|complete))"; then
    return 0
  fi

  # PATTERN 4b: Artifact without "the" but with "is working/fixed"
  # Matches: "Video player is working now", "Animation is fixed"
  if echo "$text" | grep -qiE "(animation|layout|video player|form|feature|component|page|button|modal) is (now )?(working|fixed|complete|ready)"; then
    return 0
  fi

  # PATTERN 5: Verification completion statements
  # Matches: "Verified in browser", "Tested and working", "Confirmed working"
  # Avoids: "to verify", "please test", "needs verification"
  # Key: Past participle at start + completion descriptor
  if echo "$text" | grep -qiE "^(verified|tested|confirmed|checked) (in|and|that).*(working|complete|successful|passes|no errors)"; then
    return 0
  fi

  # PATTERN 6: Status update completion
  # Matches: "All issues fixed", "Everything works now", "All tests pass"
  # Avoids: "to fix all issues", "make everything work"
  # Key: "all/everything" + present tense (no modal verbs)
  if echo "$text" | grep -qiE "^(all|everything) (is )?(now )?(working|works|fixed|complete|done|passing)"; then
    return 0
  fi

  # PATTERN 7: Short completion statements without prefix
  # Matches: "All issues fixed", "All tests passing"
  # Must be at sentence start or standalone
  if echo "$text" | grep -qiE "^all [a-z]+ (fixed|done|complete|passing|working)"; then
    return 0
  fi

  return 1
}

# Detect exclusion patterns (future intent, instructions, conditionals)
detect_exclusion_patterns() {
  local text="$1"

  # EXCLUSION 1: Imperative/instruction verbs at start
  # These indicate requests/instructions, not completion claims
  # "Analyze...", "Create...", "Update...", "Fix...", "Check..."
  if echo "$text" | grep -qiE "^(analyze|create|update|fix|check|verify|test|ensure|make sure|double check|improve|remove|add|implement|investigate)"; then
    return 0
  fi

  # EXCLUSION 2: Modal verbs indicating future/conditional
  # "should work", "will be done", "would be ready", "might work"
  if echo "$text" | grep -qiE "(should|will|would|could|might|can|must).*(work|be (done|ready|complete|fixed))"; then
    return 0
  fi

  # EXCLUSION 3: Infinitive phrases (future intent)
  # "to make sure it works", "to be completed", "to verify it's working"
  if echo "$text" | grep -qiE "to (make sure|ensure|verify|check|test).*(work|done|ready|complete|fixed)"; then
    return 0
  fi

  # EXCLUSION 4: Temporal markers with compound instructions
  # "When done, do X", "After it's working, check Y"
  # Key: Completion word followed by comma and another verb
  if echo "$text" | grep -qiE "(when|after|once|if) (it('s| is)|everything('s| is)).*(done|complete|working|ready)[,\.].*[a-z]"; then
    return 0
  fi

  # EXCLUSION 5: Conditional/interrogative phrases
  # "if it works", "is it working", "whether it's complete"
  if echo "$text" | grep -qiE "(if|is|whether|does|can|will).*(it|this|that).*(work|working|done|complete|ready)"; then
    return 0
  fi

  # EXCLUSION 6: Desire/expectation statements
  # "make sure it is working", "ensure the feature works", "verify it's complete"
  # Key: Command verb + "it/the" + state verb (not claiming current state)
  if echo "$text" | grep -qiE "(make sure|ensure|verify|confirm).*(is|are).*(working|complete|ready|done)"; then
    return 0
  fi

  # EXCLUSION 7: Option/alternative phrasing
  # "whatever works best", "whichever is complete"
  if echo "$text" | grep -qiE "(whatever|whichever|however).*(work|complete|done)"; then
    return 0
  fi

  # EXCLUSION 8: Negation patterns
  # "not working", "isn't complete", "doesn't work"
  if echo "$text" | grep -qiE "(not|isn't|doesn't|aren't|haven't).*(work|working|complete|done|ready|fixed)"; then
    return 0
  fi

  return 1
}

# Detect verification evidence
check_verification_evidence() {
  local text="$1"

  # Evidence patterns that indicate actual browser verification
  local evidence_count=0

  # Browser testing mentioned
  if echo "$text" | grep -qiE "tested in (chrome|firefox|safari|browser)"; then
    evidence_count=$((evidence_count + 1))
  fi

  # DevTools console mentioned
  if echo "$text" | grep -qiE "(devtools|console).*(clear|no errors)"; then
    evidence_count=$((evidence_count + 1))
  fi

  # Viewport sizes mentioned
  if echo "$text" | grep -qiE "(1920px|375px|768px).*test"; then
    evidence_count=$((evidence_count + 1))
  fi

  # Viewport types mentioned with testing
  if echo "$text" | grep -qiE "tested at (desktop|mobile|tablet|phone).*(and|,).*(desktop|mobile|tablet|viewport)"; then
    evidence_count=$((evidence_count + 1))
  fi

  # Actual observation described
  if echo "$text" | grep -qiE "(saw|watched|observed|opened browser|refreshed page)"; then
    evidence_count=$((evidence_count + 1))
  fi

  # Need at least 2 evidence patterns for valid verification
  if [ $evidence_count -ge 2 ]; then
    return 0
  fi

  return 1
}

# ───────────────────────────────────────────────────────────────
# ENFORCEMENT LOGIC
# ───────────────────────────────────────────────────────────────

# STEP 1: Check exclusion patterns FIRST (highest priority)
# If this is an instruction/request, allow it regardless of completion words
if detect_exclusion_patterns "$PROMPT_LOWER"; then
  # This is future intent/instruction, not a completion claim
  exit 0
fi

# STEP 2: Check if completion claim is present
if ! detect_completion_claim "$PROMPT_LOWER"; then
  # No completion claim, allow request
  exit 0
fi

# STEP 3: Completion claim detected - check for verification evidence
if check_verification_evidence "$PROMPT_LOWER"; then
  # Valid verification evidence found, allow request
  exit 0
fi

# VIOLATION: Completion claim WITHOUT verification evidence
# Terminal-visible notification via systemMessage
echo "{\"systemMessage\": \"⚠️ BLOCKED: Verification required before claiming completion (The Iron Law)\"}"

echo ""
echo "🔴 BLOCKED - VERIFICATION REQUIRED (The Iron Law)"
echo "───────────────────────────────────────────────────────────────"
echo "Detected completion claim without browser verification evidence."
echo ""
echo "NO COMPLETION CLAIMS WITHOUT FRESH BROWSER VERIFICATION EVIDENCE"
echo ""
echo "Before claiming work is complete, you MUST:"
echo "  □ Open actual browser (Chrome minimum)"
echo "  □ Test at desktop viewport (1920px)"
echo "  □ Test at mobile viewport (375px)"
echo "  □ Check DevTools console (no errors)"
echo "  □ Describe what you saw in browser"
echo ""
echo "Claims like 'done', 'fixed', 'working', 'complete' require evidence:"
echo "  ✅ 'Tested in Chrome at 1920px and 375px, console clear, animation smooth'"
echo "  ❌ 'Animation code looks correct' (no browser test)"
echo "  ❌ 'Should work now' (no verification)"
echo ""
echo "→ ACTION REQUIRED: Verify in browser first, then resubmit with evidence"
echo ""
echo "See: workflows-code skill, Verification Phase (Sections 1-3, 5, 8)"
echo "Reference: .claude/skills/workflows-code/references/verification_workflows.md"
echo "───────────────────────────────────────────────────────────────"
echo ""

# Log enforcement
HOOKS_DIR="$(cd "$SCRIPT_DIR/.." 2>/dev/null && pwd)"
LOG_DIR="$HOOKS_DIR/logs"
mkdir -p "$LOG_DIR"
LOG_FILE="$LOG_DIR/$(basename "$0" .sh).log"

{
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] VERIFICATION ENFORCEMENT TRIGGERED"
  echo "Prompt (first 200 chars): ${PROMPT:0:200}..."
  echo "Reason: Completion claim without verification evidence"
  echo "───────────────────────────────────────────────────────────────"
} >> "$LOG_FILE"

# Performance timing END
END_TIME=$(_get_nano_time)
DURATION=$(( (END_TIME - START_TIME) / 1000000 ))
echo "[$(date '+%Y-%m-%d %H:%M:%S')] enforce-verification.sh ${DURATION}ms BLOCKED" >> "$SCRIPT_DIR/../logs/performance.log"

# Block request - Iron Law enforcement
exit ${EXIT_BLOCK:-1}
