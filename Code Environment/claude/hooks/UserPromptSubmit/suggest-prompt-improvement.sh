#!/bin/bash

# ───────────────────────────────────────────────────────────────
# PROMPT IMPROVEMENT SUGGESTION HOOK
# ───────────────────────────────────────────────────────────────
# UserPromptSubmit hook that detects complex prompts and suggests
# /prompt_improver:workflow command for enhancement with proven frameworks
#
# PERFORMANCE TARGET: <50ms (lightweight pattern matching)
# COMPATIBILITY: Bash 3.2+ (macOS and Linux compatible)
#
# EXECUTION ORDER: UserPromptSubmit hook (runs BEFORE user prompt processing)
#   1. UserPromptSubmit hooks run FIRST (before processing user input)
#   2. PreToolUse hooks run SECOND (before tool execution, validation)
#   3. PostToolUse hooks run LAST (after tool completion, verification)
#   This hook: Suggests /prompt_improver:workflow for complex prompts
#
# EXIT CODE CONVENTION:
#   0 = Allow (hook passed, continue execution)
#   1 = Block (hook failed, stop execution with warning)
#   2 = Error (reserved for critical failures)
# ───────────────────────────────────────────────────────────────

# Source output helpers (completely silent on success)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" 2>/dev/null && pwd)"
HOOKS_DIR="$(cd "$SCRIPT_DIR/.." 2>/dev/null && pwd)"
source "$HOOKS_DIR/lib/output-helpers.sh" || exit 0

# Logging configuration
LOG_DIR="$HOOKS_DIR/logs"
LOG_FILE="$LOG_DIR/$(basename "$0" .sh).log"

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

# Extract the prompt from JSON (silent on error)
PROMPT=$(echo "$INPUT" | jq -r '.prompt // empty' 2>/dev/null)

# If no prompt found, allow it
if [ -z "$PROMPT" ]; then
  exit 0
fi

# Convert prompt to lowercase for case-insensitive matching
PROMPT_LOWER=$(echo "$PROMPT" | tr '[:upper:]' '[:lower:]')

# ───────────────────────────────────────────────────────────────
# TRIGGER DETECTION
# ───────────────────────────────────────────────────────────────

# Count words in the prompt
WORD_COUNT=$(echo "$PROMPT" | wc -w | tr -d ' ')

# Only proceed if word count > 100
if [ "$WORD_COUNT" -le 100 ]; then
  exit 0
fi

# ───────────────────────────────────────────────────────────────
# PROMPT-LIKE PATTERN DETECTION
# ───────────────────────────────────────────────────────────────

# Patterns that indicate a structured prompt (not just a conversation)
PROMPT_PATTERNS=(
  "you are.*context"
  "you are.*format"
  "you are.*example"
  "you are.*constraint"
  "you are.*output"
  "you are.*deliverable"
  "act as.*context"
  "act as.*format"
  "act as.*example"
  "act as.*constraint"
  "act as.*output"
  "act as.*deliverable"
  "your role.*context"
  "your role.*format"
  "your role.*example"
  "your role.*constraint"
  "your role.*output"
  "your role.*deliverable"
  "analyze.*context"
  "analyze.*format"
  "analyze.*example"
  "analyze.*constraint"
  "analyze.*output"
  "analyze.*deliverable"
  "generate.*context"
  "generate.*format"
  "generate.*example"
  "generate.*constraint"
  "generate.*output"
  "generate.*deliverable"
  "create.*context"
  "create.*format"
  "create.*example"
  "create.*constraint"
  "create.*output"
  "create.*deliverable"
)

# Check if prompt matches any prompt-like pattern
SHOULD_SUGGEST=false

for pattern in "${PROMPT_PATTERNS[@]}"; do
  if echo "$PROMPT_LOWER" | grep -qE "$pattern"; then
    SHOULD_SUGGEST=true
    break
  fi
done

# ───────────────────────────────────────────────────────────────
# OUTPUT SUGGESTION
# ───────────────────────────────────────────────────────────────

if [ "$SHOULD_SUGGEST" = true ]; then
  # Output as systemMessage JSON for Claude Code visibility
  PROMPT_MSG="💡 Complex prompt detected. Use /prompt_improver:workflow for enhancement with proven frameworks (RCAF, COSTAR). Quick: :quick, Polish: :refine"
  echo "{\"systemMessage\": \"${PROMPT_MSG}\"}"
fi

# Performance timing END
END_TIME=$(_get_nano_time)
DURATION=$(( (END_TIME - START_TIME) / 1000000 ))
echo "[$(date '+%Y-%m-%d %H:%M:%S')] suggest-prompt-improvement.sh ${DURATION}ms" >> "$HOOKS_DIR/logs/performance.log"

# Always allow the prompt to proceed (informational only)
exit 0
