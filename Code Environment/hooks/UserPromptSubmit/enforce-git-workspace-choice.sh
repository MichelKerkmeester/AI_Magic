#!/bin/bash

# ───────────────────────────────────────────────────────────────
# ENFORCE GIT WORKSPACE CHOICE - UserPromptSubmit Hook
# ───────────────────────────────────────────────────────────────
# Ensures AI ALWAYS asks user to choose git workspace strategy
# (branch, worktree, or current branch) before any git workspace
# operation. The AI should NEVER decide autonomously.
#
# Version: 1.0.0
# Created: 2025-11-30
# Spec: specs/056-git-workspace-enforcement/
#
# BEHAVIOR:
#   - Detects git workspace triggers in user prompts
#   - Emits mandatory question with options A/B/C
#   - Blocks all tools until user responds
#   - Stores session preference (1-hour expiry)
#   - Supports override phrases for power users
#
# TRIGGER PATTERNS (contextual - require action verb + git context):
#   "new feature", "start feature", "implement feature"
#   "create branch", "new branch", "feature branch"
#   "worktree", "isolated workspace", "parallel development"
#   "start working on", "begin work on"
#   "fix bug", "hotfix", "bugfix"
#   "git flow"
#
# OVERRIDE PHRASES:
#   "use branch", "create branch" → bypasses with branch selected
#   "use worktree", "in a worktree" → bypasses with worktree selected
#   "current branch", "on this branch" → bypasses with current selected
#
# PERFORMANCE TARGET: <100ms
# COMPATIBILITY: Bash 3.2+ (macOS and Linux)
#
# EXIT CODE CONVENTION:
#   0 = Allow (continue with prompt processing)
#   1 = Block (NOT used - blocking via check-pending-questions.sh)
# ───────────────────────────────────────────────────────────────

# Get script directory and hooks root
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" 2>/dev/null && pwd)"
HOOKS_DIR="$(cd "$SCRIPT_DIR/.." 2>/dev/null && pwd)"
LOG_DIR="$HOOKS_DIR/logs"
LOG_FILE="$LOG_DIR/enforce-git-workspace-choice.log"

# Ensure log directory exists
mkdir -p "$LOG_DIR" 2>/dev/null

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

# Source required libraries (graceful degradation if missing)
source "$HOOKS_DIR/lib/shared-state.sh" 2>/dev/null || {
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] WARNING: shared-state.sh not found - allowing" >> "$LOG_FILE"
  exit 0
}

source "$HOOKS_DIR/lib/signal-output.sh" 2>/dev/null || {
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] WARNING: signal-output.sh not found - allowing" >> "$LOG_FILE"
  exit 0
}

source "$HOOKS_DIR/lib/output-helpers.sh" 2>/dev/null || {
  # Fallback if output-helpers not available
  check_dependency() { command -v "$1" >/dev/null 2>&1; }
}

# Check for jq dependency
if ! command -v jq >/dev/null 2>&1; then
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] WARNING: jq not found - allowing" >> "$LOG_FILE"
  exit 0
fi

# ───────────────────────────────────────────────────────────────
# CONFIGURATION
# ───────────────────────────────────────────────────────────────

# State keys and expiry
GIT_WORKSPACE_STATE_KEY="git_workspace_choice"
GIT_WORKSPACE_STATE_EXPIRY=3600  # 1 hour session preference
GIT_WORKSPACE_FLOW_STAGE="git_workspace_choice"

# ───────────────────────────────────────────────────────────────
# READ INPUT
# ───────────────────────────────────────────────────────────────

INPUT=$(cat)
PROMPT=$(echo "$INPUT" | jq -r '.prompt // empty' 2>/dev/null)

# If no prompt, allow
if [ -z "$PROMPT" ]; then
  exit 0
fi

# Normalize prompt for pattern matching
PROMPT_LOWER=$(echo "$PROMPT" | tr '[:upper:]' '[:lower:]')

# ───────────────────────────────────────────────────────────────
# OVERRIDE PHRASE DETECTION
# ───────────────────────────────────────────────────────────────
# Allow users to bypass the question with explicit workspace choice

# Branch overrides
if echo "$PROMPT_LOWER" | grep -qE "(use branch|use a branch|create.*branch|on a branch|in a branch)"; then
  write_hook_state "$GIT_WORKSPACE_STATE_KEY" \
    '{"choice":"branch","timestamp":"'$(date -u +%Y-%m-%dT%H:%M:%SZ)'","source":"override"}'

  {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] OVERRIDE: Branch selected via phrase"
    echo "  Prompt: ${PROMPT:0:100}..."
  } >> "$LOG_FILE"

  echo ""
  echo "Git workspace: Branch (selected via override phrase)"
  echo ""
  exit 0
fi

# Worktree overrides
if echo "$PROMPT_LOWER" | grep -qE "(use worktree|use a worktree|in a worktree|isolated workspace|create.*worktree)"; then
  write_hook_state "$GIT_WORKSPACE_STATE_KEY" \
    '{"choice":"worktree","timestamp":"'$(date -u +%Y-%m-%dT%H:%M:%SZ)'","source":"override"}'

  {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] OVERRIDE: Worktree selected via phrase"
    echo "  Prompt: ${PROMPT:0:100}..."
  } >> "$LOG_FILE"

  echo ""
  echo "Git workspace: Worktree (selected via override phrase)"
  echo ""
  exit 0
fi

# Current branch overrides
if echo "$PROMPT_LOWER" | grep -qE "(current branch|on this branch|stay on.*branch|no new branch|without.*branch)"; then
  write_hook_state "$GIT_WORKSPACE_STATE_KEY" \
    '{"choice":"current","timestamp":"'$(date -u +%Y-%m-%dT%H:%M:%SZ)'","source":"override"}'

  {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] OVERRIDE: Current branch selected via phrase"
    echo "  Prompt: ${PROMPT:0:100}..."
  } >> "$LOG_FILE"

  echo ""
  echo "Git workspace: Current branch (selected via override phrase)"
  echo ""
  exit 0
fi

# ───────────────────────────────────────────────────────────────
# CHECK FOR EXISTING SESSION PREFERENCE
# ───────────────────────────────────────────────────────────────
# If user has already chosen this session, don't ask again

if has_hook_state "$GIT_WORKSPACE_STATE_KEY" "$GIT_WORKSPACE_STATE_EXPIRY" 2>/dev/null; then
  EXISTING_STATE=$(read_hook_state "$GIT_WORKSPACE_STATE_KEY" "$GIT_WORKSPACE_STATE_EXPIRY" 2>/dev/null)

  if [ -n "$EXISTING_STATE" ] && echo "$EXISTING_STATE" | jq empty 2>/dev/null; then
    EXISTING_CHOICE=$(echo "$EXISTING_STATE" | jq -r '.choice // ""' 2>/dev/null)

    if [ -n "$EXISTING_CHOICE" ]; then
      {
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] Using existing session preference: $EXISTING_CHOICE"
      } >> "$LOG_FILE"
      exit 0
    fi
  fi
fi

# ───────────────────────────────────────────────────────────────
# HANDLE USER RESPONSE TO PENDING QUESTION
# ───────────────────────────────────────────────────────────────
# Check if user is responding to the git workspace question

handle_git_workspace_flow() {
  local current_stage=$(get_question_stage 2>/dev/null)

  if [ "$current_stage" != "$GIT_WORKSPACE_FLOW_STAGE" ]; then
    return 1
  fi

  # Detect user choice from prompt
  local user_choice=""

  # Check for explicit A/B/C response (multiple patterns for natural language)
  if echo "$PROMPT_LOWER" | grep -qE "^[[:space:]]*[abc][[:space:]]*$"; then
    # Bare letter response: "a", "b", "c"
    user_choice=$(echo "$PROMPT" | tr -d '[:space:]' | tr '[:lower:]' '[:upper:]')
  elif echo "$PROMPT_LOWER" | grep -qiE "(option|choice|select|pick|choose|go with|use|let'?s)[[:space:]]*(option)?[[:space:]]*[abc]"; then
    # Natural language: "go with A", "let's use B", "I choose option C"
    user_choice=$(echo "$PROMPT_LOWER" | grep -oiE "[abc]" | tail -1 | tr '[:lower:]' '[:upper:]')
  elif echo "$PROMPT_LOWER" | grep -qiE "^[[:space:]]*(a\)|b\)|c\)|option[[:space:]]*[abc])"; then
    # Formatted: "A)", "option A"
    user_choice=$(echo "$PROMPT_LOWER" | grep -oiE "[abc]" | head -1 | tr '[:lower:]' '[:upper:]')
  elif echo "$PROMPT_LOWER" | grep -qiE "^[[:space:]]*[abc][[:space:]]*(please|thanks|ok|$|\.|\,)"; then
    # Letter at start with trailing words: "A please", "b, thanks"
    user_choice=$(echo "$PROMPT_LOWER" | grep -oiE "^[[:space:]]*[abc]" | tr -d '[:space:]' | tr '[:lower:]' '[:upper:]')
  fi

  {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] GIT_WORKSPACE_FLOW: Stage=$current_stage, Choice=${user_choice:-none}"
  } >> "$LOG_FILE"

  if [ -z "$user_choice" ]; then
    return 1
  fi

  # Process the choice
  case "$user_choice" in
    A)
      echo ""
      echo "Git workspace: Branch selected"
      echo "   Creating a new branch for this work"
      echo ""

      write_hook_state "$GIT_WORKSPACE_STATE_KEY" \
        '{"choice":"branch","timestamp":"'$(date -u +%Y-%m-%dT%H:%M:%SZ)'","source":"question"}'

      clear_question_flow
      exit 0
      ;;
    B)
      echo ""
      echo "Git workspace: Worktree selected"
      echo "   Creating an isolated worktree for this work"
      echo ""

      write_hook_state "$GIT_WORKSPACE_STATE_KEY" \
        '{"choice":"worktree","timestamp":"'$(date -u +%Y-%m-%dT%H:%M:%SZ)'","source":"question"}'

      clear_question_flow
      exit 0
      ;;
    C)
      echo ""
      echo "Git workspace: Current branch selected"
      echo "   Working on the current branch without creating a new one"
      echo ""

      write_hook_state "$GIT_WORKSPACE_STATE_KEY" \
        '{"choice":"current","timestamp":"'$(date -u +%Y-%m-%dT%H:%M:%SZ)'","source":"question"}'

      clear_question_flow
      exit 0
      ;;
  esac

  return 1
}

# Check if user is responding to the question
if handle_git_workspace_flow; then
  exit 0
fi

# ───────────────────────────────────────────────────────────────
# GIT WORKSPACE TRIGGER DETECTION
# ───────────────────────────────────────────────────────────────
# Contextual patterns that require action verb + git workspace context

detect_git_workspace_trigger() {
  local prompt_lower="$1"
  local detected_trigger=""

  # Feature-related triggers (action verb + "feature" anywhere after)
  if echo "$prompt_lower" | grep -qE "(new|start|create|implement|begin|add).*feature"; then
    detected_trigger="new feature"

  # Branch-related triggers
  elif echo "$prompt_lower" | grep -qE "(create|new|make|start).*branch"; then
    detected_trigger="create branch"

  # Worktree-related triggers
  elif echo "$prompt_lower" | grep -qE "worktree|git worktree|isolated workspace|parallel development"; then
    detected_trigger="worktree"

  # Work initiation triggers
  elif echo "$prompt_lower" | grep -qE "(start|begin) (working|coding|implementing) on"; then
    detected_trigger="start working on"

  # Bug fix triggers (may need branch or worktree)
  elif echo "$prompt_lower" | grep -qE "(fix|resolve|address|debug|patch).*(bug|issue|problem|error)"; then
    detected_trigger="fix bug"

  # Hotfix triggers
  elif echo "$prompt_lower" | grep -qE "hotfix|hot fix"; then
    detected_trigger="hotfix"

  # Git flow triggers
  elif echo "$prompt_lower" | grep -qE "git flow|gitflow"; then
    detected_trigger="git flow"

  # Implementation triggers with git context
  elif echo "$prompt_lower" | grep -qE "(implement|build|develop).*(feature|module|component|system|service|api|endpoint)"; then
    detected_trigger="implement feature"
  fi

  echo "$detected_trigger"
}

DETECTED_TRIGGER=$(detect_git_workspace_trigger "$PROMPT_LOWER")

# If no trigger detected, allow the prompt to proceed
if [ -z "$DETECTED_TRIGGER" ]; then
  {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] No git workspace trigger detected"
    echo "  Prompt: ${PROMPT:0:100}..."
  } >> "$LOG_FILE"
  exit 0
fi

# ───────────────────────────────────────────────────────────────
# EMIT MANDATORY QUESTION
# ───────────────────────────────────────────────────────────────
# Git workspace trigger detected - ask user to choose

{
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] GIT WORKSPACE TRIGGER DETECTED"
  echo "  Trigger: $DETECTED_TRIGGER"
  echo "  Prompt: ${PROMPT:0:100}..."
  echo "  Emitting mandatory question..."
} >> "$LOG_FILE"

# Build options JSON
OPTIONS=$(cat <<'EOF'
[
  {"id": "A", "label": "Create a new branch", "description": "Standard branch on current repo - good for quick fixes and small changes"},
  {"id": "B", "label": "Create a git worktree", "description": "Isolated workspace in separate directory - ideal for parallel work and complex features"},
  {"id": "C", "label": "Work on current branch", "description": "No new branch - for trivial changes or exploration on existing branch"}
]
EOF
)

# Build context JSON with detected trigger (compact for argument passing)
CONTEXT=$(jq -c -n \
  --arg trigger "$DETECTED_TRIGGER" \
  '{"detected_trigger": $trigger}')

# Emit the mandatory question
emit_mandatory_question "GIT_WORKSPACE_CHOICE" \
  "How would you like to organize your git workspace for this work?" \
  "$OPTIONS" \
  "$CONTEXT"

# Set question flow stage
set_question_flow "$GIT_WORKSPACE_FLOW_STAGE" "" "" ""

# Performance timing END
END_TIME=$(_get_nano_time)
DURATION=$(((END_TIME - START_TIME) / 1000000))
echo "[$(date '+%Y-%m-%d %H:%M:%S')] enforce-git-workspace-choice.sh ${DURATION}ms" >> "$HOOKS_DIR/logs/performance.log"

{
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] Mandatory question emitted"
  echo "───────────────────────────────────────────────────────────────"
} >> "$LOG_FILE"

# Allow the hook to complete - blocking is handled by check-pending-questions.sh
exit 0
