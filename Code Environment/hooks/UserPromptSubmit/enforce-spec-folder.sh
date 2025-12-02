#!/bin/bash

# ───────────────────────────────────────────────────────────────
# SPEC FOLDER ENFORCEMENT HOOK
# ───────────────────────────────────────────────────────────────
# UserPromptSubmit hook that blocks (or warns) when a conversation
# attempts to modify files without the required spec documentation.
#
# Features
#   • Detects implementation intent based on the prompt
#   • Supports configurable enforcement modes (warning, soft, hard)
#   • Validates spec folder existence and template structure
#   • Honors configurable exception patterns for trivial edits
#   • Logs every decision to spec-enforcement.log for auditing
#   • Records execution time in performance.log (<100ms target)
#   • Uses .claude/.spec-active marker for mid-conversation detection
#
# State Marker Usage
#   • Marker file: .claude/.spec-active (contains active spec path)
#   • Create marker: When starting work in a spec folder
#     Example: echo "specs/095-feature-name" > .claude/.spec-active
#   • Cleanup marker: When conversation ends or switching specs
#     Example: rm -f .claude/.spec-active
#   • Auto-cleanup: Stale markers (pointing to non-existent folders) are removed automatically
#
# PERFORMANCE TARGET: <100ms (state checks, file validation)
# COMPATIBILITY: Bash 3.2+ (macOS and Linux compatible)
#
# EXECUTION ORDER: UserPromptSubmit hook (runs BEFORE user prompt processing)
#   1. UserPromptSubmit hooks run FIRST (before processing user input)
#   2. PreToolUse hooks run SECOND (before tool execution, validation)
#   3. PostToolUse hooks run LAST (after tool completion, verification)
#   This hook: Ensures spec folder exists for file modification intents
#
# EXIT CODE CONVENTION:
#   0 = Allow (hook passed, continue execution)
#   1 = Block (hook failed, stop execution with warning)
#   2 = Error (reserved for critical failures)
# ───────────────────────────────────────────────────────────────

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" 2>/dev/null && pwd)"
HOOKS_DIR="$(cd "$SCRIPT_DIR/.." 2>/dev/null && pwd)"
PROJECT_ROOT=$(git rev-parse --show-toplevel 2>/dev/null || (cd "$SCRIPT_DIR/../.." && pwd))
CONFIG_FILE="$PROJECT_ROOT/.claude/configs/skill-rules.json"
LOG_DIR="$HOOKS_DIR/logs"
LOG_FILE="$LOG_DIR/$(basename "$0" .sh).log"
PERF_LOG="$LOG_DIR/performance.log"
SPECS_DIR="$PROJECT_ROOT/specs"
DOC_GUIDE="$PROJECT_ROOT/.claude/skills/workflows-spec-kit/SKILL.md"

mkdir -p "$LOG_DIR"

source "$SCRIPT_DIR/../lib/output-helpers.sh" || exit 0
source "$SCRIPT_DIR/../lib/shared-state.sh" 2>/dev/null || true
source "$SCRIPT_DIR/../lib/signal-output.sh" 2>/dev/null || true
source "$SCRIPT_DIR/../lib/spec-context.sh" 2>/dev/null || true
source "$SCRIPT_DIR/../lib/file-scope-tracking.sh" 2>/dev/null || true
source "$SCRIPT_DIR/../lib/migrate-spec-folder.sh" 2>/dev/null || true

# Load exit codes for standardized exit handling
if [ -f "$SCRIPT_DIR/../lib/exit-codes.sh" ]; then
  source "$SCRIPT_DIR/../lib/exit-codes.sh"
else
  # Fallback: define constants if library missing
  EXIT_ALLOW=0
  EXIT_BLOCK=1
fi

# Source template validation library (if available)
# Note: template-validation.sh expects REPO_ROOT to be set
if [ -f "$SCRIPT_DIR/../lib/template-validation.sh" ]; then
  export REPO_ROOT="$PROJECT_ROOT"
  source "$SCRIPT_DIR/../lib/template-validation.sh" 2>/dev/null || true
  VALIDATION_LIB_LOADED=true
else
  VALIDATION_LIB_LOADED=false
fi

# Cross-platform nanosecond timing helper
_get_nano_time() {
  if [[ "$OSTYPE" == "darwin"* ]]; then
    echo $(($(date +%s) * 1000000000))
  else
    date +%s%N 2>/dev/null || echo $(($(date +%s) * 1000000000))
  fi
}

START_TIME=$(_get_nano_time)

check_dependency "jq" "brew install jq (macOS) or apt install jq (Linux)" || exit 0

INPUT=$(cat)
PROMPT=$(echo "$INPUT" | jq -r '.prompt // empty' 2>/dev/null)
if [ -z "$PROMPT" ]; then
  exit 0
fi
PROMPT_LOWER=$(echo "$PROMPT" | tr '[:upper:]' '[:lower:]')
PROMPT_SNIPPET="${PROMPT:0:200}"

# V9: Extract SESSION_ID for session-isolated markers
SESSION_ID=$(echo "$INPUT" | jq -r '.session_id // empty' 2>/dev/null)
if [ -n "$SESSION_ID" ]; then
  SESSION_ID=$(echo "$SESSION_ID" | tr -cd 'a-zA-Z0-9_-')
fi
# Ensure SESSION_ID is never empty - defaults to "current" for safety
SESSION_ID="${SESSION_ID:-current}"

# Early definition needed for multi-stage flow handler (V9: session-aware)
SPEC_MARKER=$(get_spec_marker_path "$SESSION_ID")

# ───────────────────────────────────────────────────────────────
# MULTI-STAGE QUESTION FLOW HANDLING
# ───────────────────────────────────────────────────────────────
# Check if we're in an ongoing question flow and handle stage transitions
#
# Stage 1a (spec_folder): User answered spec folder CHOICE (new conversation)
#   → If A chosen and folder has memory files, emit MEMORY_LOAD question
#   → If no memory files, complete flow and proceed
#
# Stage 1b (spec_folder_confirm): User answered spec folder CONFIRM (mid-conversation)
#   → If A chosen and folder has memory files, emit MEMORY_LOAD question
#   → If B/D chosen, complete flow (no memory question needed)
#
# Stage 2 (memory_load): User answered memory load question
#   → Complete flow and proceed
#
# Stage 3 (task_change): User answered task change question
#   → A: Continue in current, B: New folder, C: Switch to existing
#
# CRITICAL FIX: spec_folder/spec_folder_confirm and memory_load are
# TWO SEPARATE decisions. Memory is ONLY asked AFTER spec confirmed.
# ───────────────────────────────────────────────────────────────

# ───────────────────────────────────────────────────────────────
# detect_user_choice - Parse user's A/B/C/D response from prompt
# ───────────────────────────────────────────────────────────────
# Returns: Sets USER_CHOICE variable (empty if no clear choice)
# ───────────────────────────────────────────────────────────────
detect_user_choice() {
  USER_CHOICE=""
  if echo "$PROMPT_LOWER" | grep -qE "^[[:space:]]*[abcd][[:space:]]*$"; then
    USER_CHOICE=$(echo "$PROMPT" | tr -d '[:space:]' | tr '[:lower:]' '[:upper:]')
  elif echo "$PROMPT_LOWER" | grep -qiE "(option|choice|select|pick|choose)[[:space:]]*(a|b|c|d)"; then
    USER_CHOICE=$(echo "$PROMPT_LOWER" | grep -oiE "(option|choice|select|pick|choose)[[:space:]]*(a|b|c|d)" | grep -oiE "[abcd]" | tail -1 | tr '[:lower:]' '[:upper:]')
  elif echo "$PROMPT_LOWER" | grep -qiE "^[[:space:]]*(a\)|b\)|c\)|d\))"; then
    USER_CHOICE=$(echo "$PROMPT_LOWER" | grep -oE "^[[:space:]]*[abcd]" | tr -d '[:space:]' | tr '[:lower:]' '[:upper:]')
  fi
}

# ───────────────────────────────────────────────────────────────
# NOTE: find_memory_directory() is defined later in this file (line ~1740)
# with enhanced support for parent hierarchy traversal and stale marker handling
# ───────────────────────────────────────────────────────────────

# ───────────────────────────────────────────────────────────────
# build_memory_files_json - Build JSON array of memory files
# ───────────────────────────────────────────────────────────────
# Arguments: $1 - memory directory path
# Returns: Sets MEMORY_FILES_JSON and MEMORY_COUNT variables
# ───────────────────────────────────────────────────────────────
build_memory_files_json() {
  local memory_dir="$1"
  MEMORY_FILES_JSON="[]"
  MEMORY_COUNT=0

  if [ -z "$memory_dir" ] || [ ! -d "$memory_dir" ]; then
    return 1
  fi

  MEMORY_COUNT=$(find "$memory_dir" -maxdepth 1 -type f -name "*__*.md" 2>/dev/null | wc -l | tr -d ' ')

  if [ "$MEMORY_COUNT" -gt 0 ]; then
    local files_json="["
    local first=true
    while IFS= read -r file; do
      [ -z "$file" ] && continue
      local file_name=$(basename "$file")
      if [ "$first" = true ]; then
        files_json="$files_json\"$file_name\""
        first=false
      else
        files_json="$files_json,\"$file_name\""
      fi
    done < <(find "$memory_dir" -maxdepth 1 -type f -name "*__*.md" -exec basename {} \; 2>/dev/null | sort -r | head -5)
    files_json="$files_json]"
    MEMORY_FILES_JSON="$files_json"
  fi
}

# ───────────────────────────────────────────────────────────────
# create_validated_spec_marker - Create marker with subfolder validation
# ───────────────────────────────────────────────────────────────
# Arguments: $1 - spec folder path
# ───────────────────────────────────────────────────────────────
create_validated_spec_marker() {
  local spec_folder="$1"
  local target_folder="$spec_folder"

  if has_root_level_content "$spec_folder" && [ -f "$SPEC_MARKER" ]; then
    target_folder=$(cat "$SPEC_MARKER" 2>/dev/null | tr -d '\n')
  fi

  create_spec_marker "$target_folder"
}

# ───────────────────────────────────────────────────────────────
# handle_skip_choice - Handle user choosing to skip documentation
# ───────────────────────────────────────────────────────────────
# Arguments: $1 - log message prefix
# ───────────────────────────────────────────────────────────────
handle_skip_choice() {
  local prefix="${1:-}"
  echo "[FLOW_COMPLETE] ${prefix}User skipped documentation (choice D)" >> "$LOG_FILE" 2>/dev/null || true
  clear_question_flow
  mkdir -p "$PROJECT_ROOT/.claude" 2>/dev/null
  echo "skip" > "$PROJECT_ROOT/.claude/.spec-skip"
  exit 0
}

# ───────────────────────────────────────────────────────────────
# handle_new_folder_choice - Handle user choosing to create new folder
# ───────────────────────────────────────────────────────────────
# Arguments: $1 - log message prefix
# ───────────────────────────────────────────────────────────────
handle_new_folder_choice() {
  local prefix="${1:-}"
  echo "[FLOW_TRANSITION] ${prefix}User wants new spec folder (choice B)" >> "$LOG_FILE" 2>/dev/null || true
  cleanup_spec_marker 2>/dev/null || rm -f "$SPEC_MARKER" 2>/dev/null
  clear_question_flow
  echo ""
  echo "🆕 Creating new spec folder..."
  echo ""
  return 1
}

# ───────────────────────────────────────────────────────────────
# transition_to_memory_stage - Transition to memory loading stage
# ───────────────────────────────────────────────────────────────
# Arguments: $1 - stored folder, $2 - user choice, $3 - display message
# ───────────────────────────────────────────────────────────────
transition_to_memory_stage() {
  local stored_folder="$1"
  local user_choice="$2"
  local display_msg="${3:-Spec folder selected}"

  echo "[FLOW_TRANSITION] Moving to memory_load stage ($MEMORY_COUNT memory files found)" >> "$LOG_FILE" 2>/dev/null || true

  set_question_flow "memory_load" "$stored_folder" "$MEMORY_FILES_JSON" "$user_choice"

  # Terminal-visible notification via systemMessage
  echo "{\"systemMessage\": \"🧠 Memory files detected ($MEMORY_COUNT) - select A/B/C/D to load context\"}"

  echo ""
  echo "📁 $display_msg: $(basename "$stored_folder")"
  echo ""
  echo "🧠 MEMORY FILES DETECTED"
  echo "Found $MEMORY_COUNT previous session file(s) in memory/:"
  find "$MEMORY_DIR" -maxdepth 1 -type f -name "*__*.md" -exec basename {} \; 2>/dev/null | sort -r | head -3 | while read -r f; do
    echo "   • $f"
  done
  echo ""

  emit_memory_load_question "$MEMORY_FILES_JSON"
  exit $EXIT_BLOCK
}

# ───────────────────────────────────────────────────────────────
# handle_stage_spec_folder - Handle spec_folder stage response
# ───────────────────────────────────────────────────────────────
handle_stage_spec_folder() {
  if [ -z "$USER_CHOICE" ]; then
    return 1
  fi

  local stored_folder=$(get_flow_spec_folder)

  if [ "$USER_CHOICE" = "D" ]; then
    handle_skip_choice ""
  fi

  if [ "$USER_CHOICE" != "A" ]; then
    echo "[FLOW_COMPLETE] User chose $USER_CHOICE (not reuse), skipping memory check" >> "$LOG_FILE" 2>/dev/null || true
    clear_question_flow
    return 1
  fi

  # User chose A - check for memory files
  MEMORY_DIR=$(find_memory_directory "$stored_folder" 2>/dev/null) || MEMORY_DIR=""
  build_memory_files_json "$MEMORY_DIR"

  if [ "$MEMORY_COUNT" -gt 0 ]; then
    transition_to_memory_stage "$stored_folder" "$USER_CHOICE" "Spec folder selected"
  else
    echo "[FLOW_COMPLETE] Spec folder selected, no memory files" >> "$LOG_FILE" 2>/dev/null || true
    create_validated_spec_marker "$stored_folder"
    clear_question_flow
    return 1
  fi
}

# ───────────────────────────────────────────────────────────────
# handle_stage_spec_folder_confirm - Handle spec_folder_confirm stage
# ───────────────────────────────────────────────────────────────
handle_stage_spec_folder_confirm() {
  if [ -z "$USER_CHOICE" ]; then
    return 1
  fi

  local stored_folder=$(get_flow_spec_folder)
  local spec_name=$(basename "$stored_folder" 2>/dev/null || echo "unknown")

  if [ "$USER_CHOICE" = "D" ]; then
    echo "[FLOW_COMPLETE] Mid-conv: User skipped documentation (choice D)" >> "$LOG_FILE" 2>/dev/null || true
    clear_question_flow
    create_skip_marker 2>/dev/null || {
      mkdir -p "$PROJECT_ROOT/.claude" 2>/dev/null
      echo "skip" > "$PROJECT_ROOT/$SKIP_MARKER"
    }
    exit 0
  fi

  if [ "$USER_CHOICE" = "B" ]; then
    handle_new_folder_choice "Mid-conv: "
    return $?
  fi

  # User chose A - continue in existing folder
  echo "[FLOW_TRANSITION] Mid-conv: User confirmed spec folder $spec_name (choice A)" >> "$LOG_FILE" 2>/dev/null || true

  MEMORY_DIR=$(find_memory_directory "$stored_folder" 2>/dev/null) || MEMORY_DIR=""
  build_memory_files_json "$MEMORY_DIR"

  if [ "$MEMORY_COUNT" -gt 0 ]; then
    transition_to_memory_stage "$stored_folder" "$USER_CHOICE" "Spec folder confirmed"
  else
    echo "[FLOW_COMPLETE] Spec folder confirmed, no memory files" >> "$LOG_FILE" 2>/dev/null || true
    create_validated_spec_marker "$stored_folder"
    clear_question_flow
    echo ""
    echo "✅ Continuing in spec folder: $spec_name"
    echo ""
    exit 0
  fi
}

# ───────────────────────────────────────────────────────────────
# handle_stage_memory_load - Handle memory_load stage response
# ───────────────────────────────────────────────────────────────
handle_stage_memory_load() {
  if [ -z "$USER_CHOICE" ]; then
    if echo "$PROMPT_LOWER" | grep -qiE "(load|skip|fresh|recent|all|specific)"; then
      echo "[FLOW_COMPLETE] Memory question answered (inferred from content)" >> "$LOG_FILE" 2>/dev/null || true
      clear_question_flow
      exit 0
    fi
    return 1
  fi

  echo "[FLOW_COMPLETE] Memory question answered: $USER_CHOICE" >> "$LOG_FILE" 2>/dev/null || true

  local stored_folder=$(get_flow_spec_folder)
  local memory_files=$(get_flow_memory_files)

  echo ""
  echo "✅ QUESTION FLOW COMPLETE"
  echo "   Spec folder: $(basename "$stored_folder")"
  echo "   Memory choice: $USER_CHOICE"
  echo ""

  # V9.0: Load context using anchor-based retrieval script
  if [ "$USER_CHOICE" != "D" ]; then
    local spec_folder_name=$(basename "$stored_folder")
    local load_script="$SCRIPT_DIR/../lib/load-related-context.sh"

    if [ -x "$load_script" ]; then
      case "$USER_CHOICE" in
        A)
          echo "📚 Loading context from most recent session..."
          echo ""
          "$load_script" "$spec_folder_name" summary 2>&1 || true
          echo ""
          ;;
        B)
          echo "📚 Loading summaries from recent sessions..."
          echo ""
          "$load_script" "$spec_folder_name" recent 3 2>&1 || true
          echo ""
          echo "💡 Use 'extract <anchor-id>' to load specific sections"
          echo ""
          ;;
        C)
          echo "📚 Available sessions:"
          echo ""
          "$load_script" "$spec_folder_name" list 2>&1 || true
          echo ""
          echo "💡 Commands available:"
          echo "   - Read tool to load complete files"
          echo "   - 'extract <anchor-id>' to load specific sections"
          echo "   - 'search <keyword>' to find anchors"
          echo ""
          ;;
      esac
    else
      echo "📖 AI: Load the selected memory file(s) using the Read tool before proceeding."
      echo ""
    fi
  fi

  create_validated_spec_marker "$stored_folder"
  clear_question_flow
  exit 0
}

# ───────────────────────────────────────────────────────────────
# handle_stage_task_change - Handle task_change stage response
# ───────────────────────────────────────────────────────────────
handle_stage_task_change() {
  local choice="$USER_CHOICE"

  # Infer choice from keywords if not explicit
  if [ -z "$choice" ]; then
    if echo "$PROMPT_LOWER" | grep -qiE "(continue|stay|current|same|related)"; then
      choice="A"
    elif echo "$PROMPT_LOWER" | grep -qiE "(new|create|fresh|different|separate)"; then
      choice="B"
    elif echo "$PROMPT_LOWER" | grep -qiE "(switch|existing|other|choose)"; then
      choice="C"
    fi
  fi

  if [ -z "$choice" ]; then
    return 1
  fi

  local stored_folder=$(get_flow_spec_folder)

  case "$choice" in
    A)
      echo "[FLOW_COMPLETE] User confirmed current spec folder (choice A)" >> "$LOG_FILE" 2>/dev/null || true
      echo ""
      echo "✅ Continuing in $(basename "$stored_folder")"
      echo ""
      create_validated_spec_marker "$stored_folder"
      clear_question_flow
      exit 0
      ;;
    B)
      echo "[FLOW_TRANSITION] User wants new spec folder (choice B)" >> "$LOG_FILE" 2>/dev/null || true
      cleanup_spec_marker 2>/dev/null || rm -f "$SPEC_MARKER" 2>/dev/null
      clear_question_flow
      echo ""
      echo "🆕 Creating new spec folder for this task..."
      echo ""
      return 1
      ;;
    C)
      echo "[FLOW_TRANSITION] User wants to switch to existing spec (choice C)" >> "$LOG_FILE" 2>/dev/null || true
      cleanup_spec_marker 2>/dev/null || rm -f "$SPEC_MARKER" 2>/dev/null
      clear_question_flow
      echo ""
      echo "🔄 Select from existing spec folders..."
      echo ""
      return 1
      ;;
  esac

  clear_question_flow
  return 1
}

# ───────────────────────────────────────────────────────────────
# handle_question_flow - Main question flow dispatcher
# ───────────────────────────────────────────────────────────────
handle_question_flow() {
  local current_stage=$(get_question_stage)

  # Not in a flow - return 1 to continue normal processing
  if [ "$current_stage" = "initial" ] || [ "$current_stage" = "complete" ]; then
    return 1
  fi

  # Detect user's response pattern (A/B/C/D or explicit choice)
  detect_user_choice
  echo "[FLOW_CHECK] Stage: $current_stage, Detected choice: ${USER_CHOICE:-none}" >> "$LOG_FILE" 2>/dev/null || true

  # Dispatch to stage-specific handler
  case "$current_stage" in
    "spec_folder")
      handle_stage_spec_folder
      return $?
      ;;
    "spec_folder_confirm")
      handle_stage_spec_folder_confirm
      return $?
      ;;
    "memory_load")
      handle_stage_memory_load
      return $?
      ;;
    "task_change")
      handle_stage_task_change
      return $?
      ;;
    *)
      # Unknown stage - clear and continue
      clear_question_flow
      return 1
      ;;
  esac
}

# Check for ongoing question flow FIRST
if handle_question_flow; then
  # Flow was handled and exited - this line won't be reached
  exit 0
fi

# ───────────────────────────────────────────────────────────────
# EXPLICIT NEW TASK TRIGGER DETECTION
# ───────────────────────────────────────────────────────────────
# User can explicitly signal task change with trigger phrases.
# This clears the marker and forces re-prompt for new spec folder.
# Checked BEFORE modification intent detection.
# ───────────────────────────────────────────────────────────────

EXPLICIT_NEW_TASK_TRIGGERS="new task|different task|switch to|change topic|start fresh|clear context|work on something else|different feature|new feature|new bug|reset spec"

check_explicit_new_task_trigger() {
  # Check for trigger patterns
  if echo "$PROMPT_LOWER" | grep -qiE "$EXPLICIT_NEW_TASK_TRIGGERS"; then
    # Exclude questions about task switching (e.g., "how do I switch tasks?")
    if echo "$PROMPT_LOWER" | grep -qE '\?$'; then
      return 1  # Question - not a trigger
    fi
    if echo "$PROMPT_LOWER" | grep -qiE "^(how|what|when|where|why|can|could|should).*(switch|change|task)"; then
      return 1  # Question about switching - not a trigger
    fi
    return 0  # Explicit trigger found
  fi
  return 1  # No trigger
}

if [ -f "$SPEC_MARKER" ] && check_explicit_new_task_trigger; then
  # User explicitly signaled task change - clear marker and allow normal flow
  old_marker_path=$(cat "$SPEC_MARKER" 2>/dev/null | tr -d '\n')
  old_marker_name=$(basename "$old_marker_path" 2>/dev/null || echo "unknown")

  echo "" >&2
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" >&2
  echo "🔄 TASK CHANGE DETECTED" >&2
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" >&2
  echo "" >&2
  echo "Previous spec folder cleared: $old_marker_name" >&2
  echo "" >&2
  echo "You're starting a new task. The spec folder prompt will appear." >&2
  echo "" >&2
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" >&2
  echo "" >&2

  # Log and clear marker
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] EXPLICIT_NEW_TASK: Cleared marker from $old_marker_path" >> "$LOG_FILE" 2>/dev/null || true
  cleanup_spec_marker 2>/dev/null || rm -f "$SPEC_MARKER" 2>/dev/null
  cleanup_skip_marker 2>/dev/null || rm -f "$SKIP_MARKER" 2>/dev/null
  clear_question_flow 2>/dev/null || true

  # Continue to normal flow - will now prompt for spec folder
fi

log_event() {
  local status="$1"
  local detail="$2"
  local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
  {
    echo "$SEPARATOR"
    echo "[$timestamp] STATUS: $status"
    echo "Prompt: $PROMPT_SNIPPET"
    [ -n "$detail" ] && echo "Detail: $detail"
  } >> "$LOG_FILE"
}

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
  # Question patterns at start of prompt
  if echo "$PROMPT_LOWER" | grep -qE "^(what|how|why|when|where|who|which|can you|could you|would you|should|do you|does|is|are|show me|explain|tell me|help me understand)"; then
    return 1  # No modification intent
  fi

  # Check for question words + review/explain (read-only intent)
  if echo "$PROMPT_LOWER" | grep -qE "(explain|review|show|describe|tell).*(what|how|why|code|flow|work)"; then
    return 1  # No modification intent
  fi

  # Detect session continuation patterns (runs work from previous session)
  # These patterns indicate the user wants to execute pending implementation work
  if echo "$PROMPT_LOWER" | grep -qiE "(continue|resume|proceed|pick up|carry on).*(conversation|session|task|work|where.*left|from where|last task|from last)"; then
    DETECTED_INTENT="session-continuation"
    return 0  # This IS modification intent - previous work will be executed
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

ALLOWED_EXCEPTION_PATTERNS=()
ALLOWED_EXCEPTION_REASON=""
MAX_EXCEPTION_LOC=0
SINGLE_FILE_ONLY=false
ENFORCEMENT_MODE="hard-block"
VALIDATION_LEVEL="moderate"
CHECK_SPEC_FOLDER=true
CHECK_TEMPLATES=true
CHECK_PLACEHOLDERS=true
CHECK_METADATA=true
CHECK_TEMPLATE_SOURCE=true
CHECK_H2_EMOJIS=true
CHECK_CROSS_REFERENCES=false

load_enforcement_config() {
  if [ ! -f "$CONFIG_FILE" ]; then
    return
  fi

  if ! validate_json "$CONFIG_FILE" >/dev/null 2>&1; then
    return
  fi

  local base_path='.skills["conversation-documentation"].enforcementConfig'

  ENFORCEMENT_MODE=$(jq -r "$base_path.mode // \"hard-block\"" "$CONFIG_FILE" 2>/dev/null)
  VALIDATION_LEVEL=$(jq -r "$base_path.validationLevel // \"moderate\"" "$CONFIG_FILE" 2>/dev/null)
  CHECK_SPEC_FOLDER=$(jq -r "$base_path.checkSpecFolder // true" "$CONFIG_FILE" 2>/dev/null)
  CHECK_TEMPLATES=$(jq -r "$base_path.checkTemplates // true" "$CONFIG_FILE" 2>/dev/null)
  CHECK_PLACEHOLDERS=$(jq -r "$base_path.checkPlaceholders // false" "$CONFIG_FILE" 2>/dev/null)
  CHECK_METADATA=$(jq -r "$base_path.checkMetadata // true" "$CONFIG_FILE" 2>/dev/null)
  CHECK_TEMPLATE_SOURCE=$(jq -r "$base_path.checkTemplateSource // true" "$CONFIG_FILE" 2>/dev/null)
  CHECK_H2_EMOJIS=$(jq -r "$base_path.checkH2Emojis // true" "$CONFIG_FILE" 2>/dev/null)
  CHECK_CROSS_REFERENCES=$(jq -r "$base_path.checkCrossReferences // false" "$CONFIG_FILE" 2>/dev/null)
  MAX_EXCEPTION_LOC=$(jq -r "$base_path.allowedExceptions.maxLOC // 5" "$CONFIG_FILE" 2>/dev/null)
  SINGLE_FILE_ONLY=$(jq -r "$base_path.allowedExceptions.singleFileOnly // true" "$CONFIG_FILE" 2>/dev/null)

  # Bash 3.2 compatible: read patterns into array
  ALLOWED_EXCEPTION_PATTERNS=()
  while IFS= read -r pattern; do
    [ -n "$pattern" ] && ALLOWED_EXCEPTION_PATTERNS+=("$pattern")
  done < <(jq -r "$base_path.allowedExceptions.patterns[]?" "$CONFIG_FILE" 2>/dev/null)
}

exception_matches_prompt() {
  ALLOWED_EXCEPTION_REASON=""
  if [ ${#ALLOWED_EXCEPTION_PATTERNS[@]} -eq 0 ]; then
    return 1
  fi

  for pattern in "${ALLOWED_EXCEPTION_PATTERNS[@]}"; do
    local clean_pattern=$(echo "$pattern" | tr '[:upper:]' '[:lower:]')
    if [ -n "$clean_pattern" ] && [[ "$PROMPT_LOWER" == *"$clean_pattern"* ]]; then
      ALLOWED_EXCEPTION_REASON="$pattern"
      return 0
    fi
  done

  return 1
}

file_has_structure() {
  local file_path="$1"
  local size=$(wc -c < "$file_path" 2>/dev/null | tr -d ' ')
  if [ -z "$size" ] || [ "$size" -lt 200 ]; then
    return 1
  fi

  if ! grep -qE '^## [0-9]+\. ' "$file_path" 2>/dev/null; then
    return 1
  fi

  if [ "$CHECK_PLACEHOLDERS" = true ] && grep -qE '\[PLACEHOLDER|\[NEEDS CLARIFICATION|\[YOUR_VALUE_HERE' "$file_path" 2>/dev/null; then
    return 1
  fi

  return 0
}

# ───────────────────────────────────────────────────────────────
# NEW VALIDATION FUNCTIONS - Template Structure Enforcement
# ───────────────────────────────────────────────────────────────

# Helper: Detect spec folder level based on file presence
# NEW LEVEL STRUCTURE (Progressive Enhancement):
#   Level 1 (Baseline):     spec.md + plan.md + tasks.md
#   Level 2 (Verification): Level 1 + checklist.md
#   Level 3 (Full):         Level 2 + decision-record.md + optional research-spike.md
detect_spec_level() {
  local spec_folder="$1"

  # Level 3: Has decision-record (Full documentation)
  if [ -f "$spec_folder/decision-record.md" ] || ls "$spec_folder"/decision-record-*.md 1>/dev/null 2>&1; then
    echo "3"
    return
  fi

  # Level 2: Has checklist (Verification level)
  if [ -f "$spec_folder/checklist.md" ]; then
    echo "2"
    return
  fi

  # Level 1: Baseline (spec + plan + tasks)
  # This is the default/minimum level
  echo "1"
}

# Helper: Get required files for documentation level
# NEW LEVEL STRUCTURE (Progressive Enhancement):
#   Level 1 (Baseline):     spec.md + plan.md + tasks.md
#   Level 2 (Verification): Level 1 + checklist.md
#   Level 3 (Full):         Level 2 + decision-record.md + optional research-spike.md
get_required_files_for_level() {
  local level="$1"
  case "$level" in
    1) echo "spec.md plan.md tasks.md" ;;
    2) echo "spec.md plan.md tasks.md checklist.md" ;;
    3) echo "spec.md plan.md tasks.md checklist.md decision-record.md" ;;
    *) echo "spec.md plan.md tasks.md" ;;  # Default to L1
  esac
}

# Helper: Validate required files exist for given level
# Returns 0 if all required files exist, 1 if missing files
# Outputs: List of missing files on stdout
validate_required_files() {
  local spec_folder="$1"
  local level="$2"
  local required_files
  local missing_files=""

  required_files=$(get_required_files_for_level "$level")

  for file in $required_files; do
    # Handle decision-record specially (can have suffixes)
    if [ "$file" = "decision-record.md" ]; then
      if [ ! -f "$spec_folder/decision-record.md" ] && ! ls "$spec_folder"/decision-record-*.md 1>/dev/null 2>&1; then
        missing_files="${missing_files}${file} "
      fi
    elif [ ! -f "$spec_folder/$file" ]; then
      missing_files="${missing_files}${file} "
    fi
  done

  if [ -n "$missing_files" ]; then
    echo "$missing_files"
    return 1
  fi

  return 0
}

# Helper: Extract metadata block from file (YAML frontmatter or ### Metadata section)
extract_metadata() {
  local file_path="$1"

  if [ ! -f "$file_path" ]; then
    echo ""
    return
  fi

  # Try YAML frontmatter (between --- markers)
  if head -n 1 "$file_path" 2>/dev/null | grep -q '^---$'; then
    sed -n '/^---$/,/^---$/p' "$file_path" 2>/dev/null | tail -n +2 | head -n -1
    return
  fi

  # Try Metadata section (### Metadata)
  if grep -q '^### Metadata' "$file_path" 2>/dev/null; then
    sed -n '/^### Metadata/,/^###/p' "$file_path" 2>/dev/null | tail -n +2 | head -n -1
    return
  fi

  echo ""
}

# Helper: Check if status value is valid
is_valid_status() {
  local status="$1"
  case "$status" in
    Draft|"In Review"|Approved|"In Progress"|Paused|Complete|Archived) return 0 ;;
    *) return 1 ;;
  esac
}

# Helper: Get required metadata fields for level
# Note: Level 0 was eliminated - typos are Level 1 (or exempt if single typo <5 chars)
get_required_fields() {
  local level="$1"
  case "$level" in
    1) echo "created status level estimated_loc complexity" ;;
    2|3) echo "category tags priority status created level estimated_loc" ;;
    *) echo "" ;;
  esac
}

# Helper: Map file name to template name
map_file_to_template() {
  case "$1" in
    "spec.md") echo "spec.md" ;;
    "plan.md") echo "plan.md" ;;
    "tasks.md") echo "tasks.md" ;;
    "checklist.md") echo "checklist.md" ;;
    *) echo "unknown" ;;
  esac
}

# Helper: Suggest emoji for H2 heading based on content
suggest_emoji_for_heading() {
  local heading="$1"

  case "$heading" in
    *OBJECTIVE*) echo "🎯" ;;
    *SCOPE*) echo "📋" ;;
    *USER*|*STORIES*) echo "👥" ;;
    *REQUIREMENT*) echo "📝" ;;
    *SUCCESS*) echo "✅" ;;
    *RISK*|*MITIGATION*) echo "⚠️" ;;
    *DEPEND*) echo "🔗" ;;
    *REFER*) echo "📚" ;;
    *TEST*) echo "🧪" ;;
    *IMPLEMENT*) echo "🛠️" ;;
    *PHASE*) echo "📍" ;;
    *QUALITY*) echo "💎" ;;
    *) echo "📌" ;;  # Default
  esac
}

# Validation: Check for placeholder text (HARD BLOCK)
validate_placeholders() {
  local spec_folder="$1"
  local issues=()

  # Skip if check disabled
  if [ "$CHECK_PLACEHOLDERS" != "true" ]; then
    return 0
  fi

  # Scan all .md files in spec folder (excluding memory/)
  while IFS= read -r file; do
    if [ -f "$file" ]; then
      # Check for [PLACEHOLDER], [NEEDS CLARIFICATION:, or [YOUR_VALUE_HERE:
      if grep -qE '\[PLACEHOLDER\]|\[NEEDS CLARIFICATION|\[YOUR_VALUE_HERE' "$file" 2>/dev/null; then
        local lines=$(grep -nE '\[PLACEHOLDER\]|\[NEEDS CLARIFICATION|\[YOUR_VALUE_HERE' "$file" 2>/dev/null | head -5 | cut -d: -f1 | tr '\n' ',' | sed 's/,$//')
        issues+=("$(basename "$file"):$lines - Contains placeholder text")
      fi

      # Check for sample content blocks
      if grep -qE '<!-- SAMPLE CONTENT -->|REPLACE SAMPLE CONTENT' "$file" 2>/dev/null; then
        local lines=$(grep -nE '<!-- SAMPLE CONTENT -->|REPLACE SAMPLE CONTENT' "$file" 2>/dev/null | head -5 | cut -d: -f1 | tr '\n' ',' | sed 's/,$//')
        issues+=("$(basename "$file"):$lines - Contains sample content blocks")
      fi

      # Check for ACTION REQUIRED markers
      if grep -qE 'ACTION REQUIRED:' "$file" 2>/dev/null; then
        local lines=$(grep -n 'ACTION REQUIRED:' "$file" 2>/dev/null | head -5 | cut -d: -f1 | tr '\n' ',' | sed 's/,$//')
        issues+=("$(basename "$file"):$lines - Contains action required markers")
      fi
    fi
  done < <(find "$spec_folder" -maxdepth 1 -name "*.md" -not -path "*/memory/*" 2>/dev/null)

  if [ ${#issues[@]} -gt 0 ]; then
    echo "════════════════════════════════════════"
    echo "❌ HARD BLOCK: Placeholder text detected"
    echo "════════════════════════════════════════"
    echo ""
    printf '%s\n' "${issues[@]}"
    echo ""
    echo "You must replace all placeholder text before making file changes."
    echo "See: .claude/skills/workflows-spec-kit/references/template_guide.md"
    echo ""
    return 1  # Hard block
  fi

  return 0  # No issues
}

# Validation: Check for template source markers (BLOCKING if config severity=error)
validate_template_source() {
  local spec_folder="$1"
  local warnings=()

  # Skip if check disabled
  if [ "$CHECK_TEMPLATE_SOURCE" != "true" ]; then
    return 0
  fi

  # Read severity from config (defaults to warning)
  local severity="warning"
  if [ -f "$CONFIG_FILE" ]; then
    severity=$(jq -r '.validation.template_bypass.severity // "warning"' "$CONFIG_FILE" 2>/dev/null || echo "warning")
  fi

  # Check core spec files for template markers
  local core_files=("spec.md" "plan.md")

  for file_name in "${core_files[@]}"; do
    local file_path="$spec_folder/$file_name"

    if [ -f "$file_path" ]; then
      # Check first 10 lines for marker
      if ! head -n 10 "$file_path" 2>/dev/null | grep -q 'SPECKIT_TEMPLATE_SOURCE:'; then
        local suggested_template=$(map_file_to_template "$file_name")
        if [ "$suggested_template" != "unknown" ]; then
          warnings+=("$file_name - Missing template source marker")
          warnings+=("  → Suggested: cp .opencode/speckit/templates/$suggested_template $file_path")
        fi
      fi
    fi
  done

  if [ ${#warnings[@]} -gt 0 ]; then
    if [ "$severity" = "error" ]; then
      echo "════════════════════════════════════════"
      echo "❌ HARD BLOCK: Template source validation"
      echo "════════════════════════════════════════"
      echo ""
      printf '%s\n' "${warnings[@]}"
      echo ""
      echo "Files MUST be copied from .opencode/speckit/templates/ - manual creation is blocked."
      echo ""
      return 2  # Hard block (severity=error)
    else
      echo "────────────────────────────────────────"
      echo "⚠️  WARNING: Template source validation"
      echo "────────────────────────────────────────"
      echo ""
      printf '%s\n' "${warnings[@]}"
      echo ""
      echo "Files should be copied from .opencode/speckit/templates/ for consistency."
      echo ""
      return 1  # Soft warning (not blocking)
    fi
  fi

  return 0  # No issues
}

# Validation: Check metadata block completeness (SOFT WARNING)
validate_metadata_block() {
  local spec_folder="$1"
  local warnings=()

  # Skip if check disabled
  if [ "$CHECK_METADATA" != "true" ]; then
    return 0
  fi

  local level=$(detect_spec_level "$spec_folder")

  # Check spec.md for metadata
  local spec_file="$spec_folder/spec.md"

  if [ ! -f "$spec_file" ]; then
    return 0  # No spec file to validate
  fi

  # Extract metadata block
  local metadata=$(extract_metadata "$spec_file")

  if [ -z "$metadata" ]; then
    warnings+=("No metadata block found in $(basename "$spec_file")")
    warnings+=("  → Consider adding metadata section for better organization")
  else
    # Get required fields for level
    local required_fields=$(get_required_fields "$level")

    if [ -n "$required_fields" ]; then
      # Check each required field
      for field in $required_fields; do
        if ! echo "$metadata" | grep -qiE "^[- ]*$field:" 2>/dev/null; then
          warnings+=("Missing metadata field for Level $level: $field")
        fi
      done
    fi

    # Validate status field if present
    if echo "$metadata" | grep -qiE "^[- ]*status:" 2>/dev/null; then
      local status=$(echo "$metadata" | grep -iE "^[- ]*status:" | sed 's/.*status:\s*//' | sed 's/[[:space:]]*$//' | tr -d '[]"' | head -1)
      if ! is_valid_status "$status"; then
        warnings+=("Invalid status value: '$status'")
        warnings+=("  → Valid: Draft | In Review | Approved | In Progress | Paused | Complete | Archived")
      fi
    fi
  fi

  if [ ${#warnings[@]} -gt 0 ]; then
    echo "────────────────────────────────────────"
    echo "⚠️  WARNING: Metadata validation (Level $level)"
    echo "────────────────────────────────────────"
    echo ""
    printf '%s\n' "${warnings[@]}"
    echo ""
    return 1  # Soft warning (not blocking)
  fi

  return 0  # No issues
}

# Validation: Check H2 emoji usage (SUGGESTION)
validate_h2_emojis() {
  local spec_folder="$1"
  local suggestions=()

  # Skip if check disabled
  if [ "$CHECK_H2_EMOJIS" != "true" ]; then
    return 0
  fi

  while IFS= read -r file; do
    if [ -f "$file" ]; then
      local filename=$(basename "$file")

      # Check H2 headings without emojis (## N. TEXT without emoji)
      while IFS= read -r line; do
        if [ -n "$line" ]; then
          local line_num=$(echo "$line" | cut -d: -f1)
          local heading=$(echo "$line" | cut -d: -f2- | sed 's/^## [0-9]*\. //')

          # Skip if heading already starts with common emoji patterns (simple character check)
          # Check for emoji-like characters at start (most emojis are multi-byte UTF-8)
          local first_chars=$(echo "$heading" | cut -c1-3)
          if echo "$first_chars" | LC_ALL=C grep -q '[^ -~]' 2>/dev/null; then
            # Contains non-ASCII character at start, likely emoji
            continue
          fi

          local suggested_emoji=$(suggest_emoji_for_heading "$heading")
          suggestions+=("$filename:$line_num - H2 without emoji, suggest: $suggested_emoji $heading")
        fi
      done < <(grep -nE '^## [0-9]+\. [A-Z]' "$file" 2>/dev/null || true)
    fi
  done < <(find "$spec_folder" -maxdepth 1 -name "*.md" -not -path "*/memory/*" 2>/dev/null)

  if [ ${#suggestions[@]} -gt 0 ]; then
    # Limit suggestions to first 5 to avoid overwhelming output
    local limited_suggestions=("${suggestions[@]:0:5}")

    echo "────────────────────────────────────────"
    echo "💡 SUGGESTION: H2 emoji validation"
    echo "────────────────────────────────────────"
    echo ""
    printf '%s\n' "${limited_suggestions[@]}"
    if [ ${#suggestions[@]} -gt 5 ]; then
      echo "  ... and $((${#suggestions[@]} - 5)) more"
    fi
    echo ""
    echo "H2 sections should include emojis for visual scanning."
    echo ""
    return 1  # Suggestion (not blocking)
  fi

  return 0  # No issues
}

# Validation: Check cross-references (SOFT WARNING)
validate_cross_references() {
  local spec_folder="$1"
  local warnings=()

  # Skip if check disabled
  if [ "$CHECK_CROSS_REFERENCES" != "true" ]; then
    return 0
  fi

  while IFS= read -r file; do
    if [ -f "$file" ]; then
      local filename=$(basename "$file")

      # Extract markdown links to .md files
      while IFS= read -r link; do
        if [ -n "$link" ]; then
          # Resolve relative path
          local target_path
          if [[ "$link" == ./* ]]; then
            target_path="$(dirname "$file")/${link#./}"
          else
            target_path="$(dirname "$file")/$link"
          fi

          # Check if target exists
          if [ ! -f "$target_path" ]; then
            warnings+=("$filename - Broken link: $link (target not found)")
          fi
        fi
      done < <(grep -oE '\[.*\]\([^)]+\.md\)' "$file" 2>/dev/null | grep -oE '\([^)]+\.md\)' | tr -d '()' || true)
    fi
  done < <(find "$spec_folder" -maxdepth 1 -name "*.md" -not -path "*/memory/*" 2>/dev/null)

  if [ ${#warnings[@]} -gt 0 ]; then
    echo "────────────────────────────────────────"
    echo "⚠️  WARNING: Cross-reference validation"
    echo "────────────────────────────────────────"
    echo ""
    printf '%s\n' "${warnings[@]}"
    echo ""
    echo "Fix broken links or create missing target files."
    echo ""
    return 1  # Soft warning (not blocking)
  fi

  return 0  # No issues
}

# Suggestion: Sub-folder README
suggest_subfolder_readme() {
  local spec_folder="$1"
  local current_path="$PWD"

  # Check if we're in a sub-folder of the spec folder
  if [[ "$current_path" == "$spec_folder"/* ]] && [[ "$current_path" != "$spec_folder" ]]; then
    # We're in a sub-folder
    local subfolder_name=$(basename "$current_path")

    # Skip memory/ sub-folder
    if [ "$subfolder_name" = "memory" ]; then
      return 0
    fi

    # Check if README.md exists
    if [ ! -f "$current_path/README.md" ]; then
      echo "────────────────────────────────────────"
      echo "💡 SUGGESTION: Sub-folder organization"
      echo "────────────────────────────────────────"
      echo ""
      echo "You're working in sub-folder: $subfolder_name"
      echo ""
      echo "Consider creating a README.md to document this sub-folder's purpose."
      echo ""
      echo "See: .claude/skills/workflows-spec-kit/references/template_guide.md"
      echo "     (Section: 'Using Sub-Folders for Organization')"
      echo ""
      return 1  # Suggestion (not blocking)
    fi
  fi

  return 0  # No suggestion needed
}

# ───────────────────────────────────────────────────────────────

VALIDATION_ERRORS=()

validate_templates() {
  local folder="$1"
  VALIDATION_ERRORS=()

  if [ ! -d "$folder" ]; then
    VALIDATION_ERRORS+=("Spec folder not found at $folder")
    return 1
  fi

  local spec_file="$folder/spec.md"
  local plan_file="$folder/plan.md"

  local has_valid_spec=false

  if [ -f "$spec_file" ] && file_has_structure "$spec_file"; then
    has_valid_spec=true
  fi

  if [ "$has_valid_spec" = false ]; then
    VALIDATION_ERRORS+=("spec.md missing/too small (<200 bytes) or missing numbered sections")
  fi

  if [ "$VALIDATION_LEVEL" = "strict" ] && [ -f "$spec_file" ] && ! file_has_structure "$plan_file"; then
    VALIDATION_ERRORS+=("plan.md missing or incomplete for strict validation")
  fi

  if [ ${#VALIDATION_ERRORS[@]} -gt 0 ]; then
    return 1
  fi

  # ───────────────────────────────────────────────────────────────
  # NEW VALIDATION CHECKS - Template Structure Enforcement
  # ───────────────────────────────────────────────────────────────

  local has_hard_block=false
  local has_warnings=false
  local has_suggestions=false

  # Run placeholder validation (HARD BLOCK)
  if ! validate_placeholders "$folder" 2>&1; then
    has_hard_block=true
  fi

  # If hard block detected, stop here and return failure
  if [ "$has_hard_block" = true ]; then
    return 1
  fi

  # Run template source validation (HARD BLOCK if severity=error, else warning)
  validate_template_source "$folder" 2>&1
  local template_source_result=$?
  if [ "$template_source_result" -eq 2 ]; then
    has_hard_block=true
  elif [ "$template_source_result" -eq 1 ]; then
    has_warnings=true
  fi

  # If hard block detected from template source, stop here
  if [ "$has_hard_block" = true ]; then
    return 1
  fi

  if ! validate_metadata_block "$folder" 2>&1; then
    has_warnings=true
  fi

  if ! validate_h2_emojis "$folder" 2>&1; then
    has_suggestions=true
  fi

  if ! validate_cross_references "$folder" 2>&1; then
    has_warnings=true
  fi

  if ! suggest_subfolder_readme "$folder" 2>&1; then
    has_suggestions=true
  fi

  # Warnings and suggestions don't block, just inform
  return 0
}

find_latest_spec_folder() {
  if [ ! -d "$SPECS_DIR" ]; then
    return
  fi

  local latest=$(find "$SPECS_DIR" -maxdepth 1 -mindepth 1 -type d -name "[0-9]*-*" 2>/dev/null | sort | tail -1)
  echo "$latest"
}

calculate_next_spec_number() {
  if [ ! -d "$SPECS_DIR" ]; then
    printf "%03d" 1
    return
  fi

  local max=0
  while IFS= read -r dir; do
    local base=$(basename "$dir")
    local num=${base%%-*}
    if [[ "$num" =~ ^[0-9]+$ ]]; then
      if ((10#$num > max)); then
        max=$((10#$num))
      fi
    fi
  done < <(find "$SPECS_DIR" -maxdepth 1 -mindepth 1 -type d -name "[0-9]*-*" 2>/dev/null)

  printf "%03d" $((max + 1))
}

NEXT_SPEC_NUMBER=$(calculate_next_spec_number)

# ───────────────────────────────────────────────────────────────
# DETECT MID-CONVERSATION STATE USING STATE MARKER
# ───────────────────────────────────────────────────────────────
# Check if there's an active spec folder using explicit state tracking.
# Uses .claude/.spec-active marker file instead of fragile heuristics.
#
# Marker file contains the path to the currently active spec folder.
# Create marker: create_spec_marker "specs/095-feature-name"
# Cleanup marker: cleanup_spec_marker
#
# Returns:
#   0 - Mid-conversation (marker exists, skip validation)
#   1 - Start of conversation (no marker, run validation)

# V9: Use session-aware marker path (SESSION_ID already extracted above)
SPEC_MARKER=$(get_spec_marker_path "$SESSION_ID")
SKIP_MARKER=".claude/.spec-skip"

has_substantial_content() {
  local spec_folder="$1"

  # Check if state marker file exists
  if [ -f "$SPEC_MARKER" ]; then
    # Marker exists - we're mid-conversation
    local active_spec=$(cat "$SPEC_MARKER" 2>/dev/null)

    # Verify the marked spec folder actually exists
    if [ -d "$active_spec" ]; then
      return 0  # Mid-conversation
    else
      # Stale marker - cleanup and treat as start of conversation
      cleanup_spec_marker
      return 1
    fi
  fi

  # No marker - check for actual content in folder (including sub-folders)
  # This handles cases where work exists but marker was cleared
  if [ -n "$spec_folder" ] && [ -d "$spec_folder" ]; then
    # Count MD files recursively (root + sub-folders)
    local md_count
    md_count=$(find "$spec_folder" -name "*.md" -type f 2>/dev/null | wc -l | tr -d ' ')

    # Consider substantial if 2+ MD files exist (spec.md + at least one other)
    if [ "$md_count" -ge 2 ]; then
      return 0  # Has substantial content
    fi
  fi

  # No marker and no substantial content - start of conversation
  return 1
}

# Create state marker when spec folder is created
# If initial_prompt is provided, stores topic keywords for divergence detection
create_spec_marker() {
  local spec_path="$1"
  local initial_prompt="${2:-$PROMPT}"  # Default to current prompt if not provided

  if [ -z "$spec_path" ]; then
    return 1
  fi

  # Ensure .claude directory exists
  mkdir -p .claude 2>/dev/null

  # Try to use fingerprinted version if available (from spec-context.sh)
  if type create_spec_marker_with_fingerprint &>/dev/null && [ -n "$initial_prompt" ]; then
    create_spec_marker_with_fingerprint "$spec_path" "$initial_prompt"
  else
    # Fallback to simple path-only format
    echo "$spec_path" > "$SPEC_MARKER"
  fi

  # ─────────────────────────────────────────────────────────────
  # SCOPE TRACKING INITIALIZATION
  # ─────────────────────────────────────────────────────────────
  # Initialize file-based scope tracking for drift detection
  # Uses hybrid approach: keywords + file path monitoring
  if type initialize_scope_definition &>/dev/null; then
    initialize_scope_definition "$spec_path" "$initial_prompt"
    # Clear any previous modification tracking from prior spec folders
    if type clear_file_tracking &>/dev/null; then
      clear_file_tracking
    fi
  fi
}

# Cleanup state marker (call when conversation ends or manually)
cleanup_spec_marker() {
  rm -f "$SPEC_MARKER"
}

# ───────────────────────────────────────────────────────────────
# SKIP MARKER FUNCTIONS
# ───────────────────────────────────────────────────────────────
# Allow users to explicitly skip spec folder creation for trivial
# explorations. Creates .claude/.spec-skip marker to remember decision.

# Check if skip marker exists
has_skip_marker() {
  [ -f "$SKIP_MARKER" ]
}

# Create skip marker when user selects skip option
create_skip_marker() {
  # Ensure .claude directory exists
  mkdir -p .claude

  # Write skip marker (content not used, just existence check)
  echo "skip" > "$SKIP_MARKER"
}

# Cleanup skip marker (call manually to re-enable spec folder prompts)
cleanup_skip_marker() {
  rm -f "$SKIP_MARKER"
}

# ───────────────────────────────────────────────────────────────
# SUB-FOLDER VERSIONING FUNCTIONS
# ───────────────────────────────────────────────────────────────
# Support for iterative work patterns within single spec folders.
# When reusing existing spec folders, automatically create sub-folders
# to separate iterations while maintaining independent memory contexts.

# Check if spec folder has root-level content (needs migration to sub-folders)
has_root_level_content() {
  local spec_folder="$1"

  if [ -z "$spec_folder" ] || [ ! -d "$spec_folder" ]; then
    return 1
  fi

  # Check for any markdown files at root level (excluding directories)
  local root_md_count=$(find "$spec_folder" -maxdepth 1 -type f -name "*.md" 2>/dev/null | wc -l | tr -d ' ')

  if [ "$root_md_count" -gt 0 ]; then
    return 0  # Has root content
  fi

  return 1  # No root content
}

# get_next_subfolder_number() - MOVED TO LIBRARY
# Function is now sourced from: lib/migrate-spec-folder.sh
# See comment at migrate_to_subfolders() location for details.

# Get parent folder from a path (handles both ###-parent and ###-parent/###-child)
# Returns parent folder path, or empty if path is not in numbered folder
get_parent_folder() {
  local path="$1"

  if [ -z "$path" ]; then
    return 1
  fi

  # Get absolute path
  if [[ "$path" != /* ]]; then
    path="$PROJECT_ROOT/$path"
  fi

  # Check if path itself is a numbered folder at specs level
  # Pattern: /path/to/specs/###-name (no trailing slash or subdirectory)
  if [[ "$path" =~ /specs/[0-9][0-9][0-9]-[^/]+$ ]]; then
    # Path is already a parent folder (###-name)
    echo "$path"
    return 0
  fi

  # Check if path is a child folder (###-parent/###-child)
  # Pattern: /path/to/specs/###-parent/###-child
  if [[ "$path" =~ (/specs/[0-9][0-9][0-9]-[^/]+)/[0-9][0-9][0-9]- ]]; then
    # Extract parent folder from match (full path up to parent)
    local parent_suffix="${BASH_REMATCH[1]}"
    # Get the full path by taking everything before /specs/ and appending the match
    local base_path="${path%%/specs/*}"
    echo "${base_path}${parent_suffix}"
    return 0
  fi

  # Not a numbered folder
  return 1
}

# Check if marker is stale (points to unrelated work based on keywords)
# Returns 0 if stale, 1 if fresh (keyword match found)
check_marker_staleness() {
  local prompt_keywords="$1"
  local marker_path="$2"

  if [ -z "$prompt_keywords" ] || [ -z "$marker_path" ]; then
    return 1  # Cannot determine, assume fresh
  fi

  # Extract folder names from marker path (both parent and child)
  local parent_folder=$(basename "$(dirname "$marker_path")")
  local child_folder=$(basename "$marker_path")

  # Check if any keyword matches parent or child folder
  while IFS= read -r keyword; do
    [ -z "$keyword" ] && continue

    # Check parent folder
    if echo "$parent_folder" | grep -qiE "$keyword"; then
      return 1  # Fresh (keyword match in parent)
    fi

    # Check child folder
    if echo "$child_folder" | grep -qiE "$keyword"; then
      return 1  # Fresh (keyword match in child)
    fi
  done <<< "$prompt_keywords"

  return 0  # Stale (no keyword match)
}

# Sync global marker to local marker in parent folder
# Creates/updates local .spec-active marker from global marker state
# Returns 0 on success, 1 on failure or if sync not needed
sync_marker_to_parent() {
  local global_marker="$SPEC_MARKER"

  # Check if global marker exists
  if [ ! -f "$global_marker" ]; then
    return 1
  fi

  # Read global marker
  local active_path=$(cat "$global_marker" 2>/dev/null | tr -d '\n')

  # Validate path exists
  if [ -z "$active_path" ] || [ ! -d "$active_path" ]; then
    # Clean up stale marker
    rm -f "$global_marker" 2>/dev/null
    log_event "MARKER_SYNC" "Cleaned up stale global marker (path: $active_path)"
    return 1
  fi

  # Determine parent folder
  local parent_folder=$(get_parent_folder "$active_path")

  if [ -z "$parent_folder" ]; then
    # Not a spec folder path, no sync needed
    return 1
  fi

  # Create local marker path
  local local_marker="$parent_folder/.spec-active"
  local child_name=$(basename "$active_path")

  # Check if local marker already has correct value
  if [ -f "$local_marker" ]; then
    local existing_value=$(cat "$local_marker" 2>/dev/null | tr -d '\n')
    if [ "$existing_value" = "$child_name" ]; then
      # Already synced, no action needed
      return 0
    fi
  fi

  # Write atomically (tmp file with PID + mv to prevent race conditions)
  local tmp_file="${local_marker}.tmp.$$"
  if echo "$child_name" > "$tmp_file" 2>/dev/null && mv "$tmp_file" "$local_marker" 2>/dev/null; then
    log_event "MARKER_SYNC" "Synced local marker: $parent_folder/.spec-active → $child_name"
    return 0
  else
    # Cleanup failed tmp file
    rm -f "$tmp_file" 2>/dev/null
    log_event "MARKER_SYNC" "Failed to sync local marker (permission denied or disk full?)"
    return 1
  fi
}

# Check if folder is a parent folder (contains numbered sub-folders ###-*)
# Returns 0 (true) if folder has numbered sub-folders, 1 (false) otherwise
# Used to differentiate organizational parent folders from working spec folders
is_parent_folder() {
  local folder="$1"

  if [ ! -d "$folder" ]; then
    return 1
  fi

  # Check for numbered sub-folders (###-*)
  local child_count=$(find "$folder" -maxdepth 1 -mindepth 1 -type d -name "[0-9][0-9][0-9]-*" 2>/dev/null | wc -l | tr -d ' ')

  if [ "$child_count" -gt 0 ]; then
    return 0  # Is parent
  fi

  return 1  # Not parent
}

# Get active child folder from parent via .spec-active marker
# Returns active child path if marker exists and child is valid, empty otherwise
# Used to determine which child folder is currently active in parent
get_active_child() {
  local parent_folder="$1"

  if [ ! -d "$parent_folder" ]; then
    return 1
  fi

  # Check for .spec-active marker
  local marker_file="$parent_folder/.spec-active"
  if [ ! -f "$marker_file" ]; then
    return 1
  fi

  # Read active child path from marker
  local active_path=$(cat "$marker_file" 2>/dev/null | tr -d '\n')

  # Validate active child exists
  if [ -n "$active_path" ] && [ -d "$active_path" ]; then
    echo "$active_path"
    return 0
  fi

  return 1
}

# migrate_to_subfolders() - MOVED TO LIBRARY
# Function is now sourced from: lib/migrate-spec-folder.sh
# This eliminates code duplication and centralizes maintenance.
# The library provides: migrate_to_subfolders(), get_next_subfolder_number()

# ───────────────────────────────────────────────────────────────
# MEMORY FILE SELECTION FUNCTIONS
# ───────────────────────────────────────────────────────────────
# Support for loading previous session context from memory files.
# Presents user with options to load recent memory files when continuing work.

# Find memory directory (sub-folder aware via .spec-active marker)
# Enhanced to traverse parent hierarchy and check related folders
find_memory_directory() {
  local spec_folder="$1"

  if [ -z "$spec_folder" ] || [ ! -d "$spec_folder" ]; then
    return 1
  fi

  # Check if .spec-active marker points to a sub-folder
  if [ -f "$SPEC_MARKER" ]; then
    local active_path=$(cat "$SPEC_MARKER" 2>/dev/null | tr -d '\n')

    # Validate marker points to existing directory
    if [ -n "$active_path" ] && [ -d "$active_path" ]; then

      # OPTION 1: Direct match - marker points to child of this spec
      if [[ "$active_path" == "$spec_folder"/* ]] && [ -d "$active_path/memory" ]; then
        echo "$active_path/memory"
        return 0
      fi

      # OPTION 2: Same parent - check if marker parent matches spec parent
      local marker_parent=$(get_parent_folder "$active_path")
      local spec_parent=$(get_parent_folder "$spec_folder")

      if [ -n "$marker_parent" ] && [ -n "$spec_parent" ] && [ "$marker_parent" = "$spec_parent" ]; then
        # Marker and spec are in same parent folder (siblings or same)
        if [ -d "$active_path/memory" ]; then
          echo "$active_path/memory"
          return 0
        fi
      fi

      # OPTION 3: Related parent - check if both are in same spec family
      # (same root number - e.g., 003-speckit-refinement and 003-speckit-rework)
      if [ -n "$marker_parent" ] && [ -n "$spec_parent" ]; then
        local marker_root=$(basename "$marker_parent" | sed 's/^\([0-9][0-9][0-9]\)-.*/\1/')
        local spec_root=$(basename "$spec_parent" | sed 's/^\([0-9][0-9][0-9]\)-.*/\1/')

        if [ -n "$marker_root" ] && [ -n "$spec_root" ] && [ "$marker_root" = "$spec_root" ]; then
          # Same spec family - use marker's memory directory
          if [ -d "$active_path/memory" ]; then
            echo "$active_path/memory"
            return 0
          fi
        fi
      fi

    else
      # Stale marker pointing to deleted folder - clean up and warn
      if [ -n "$active_path" ]; then
        rm -f "$SPEC_MARKER" 2>/dev/null
        log_event "MARKER_CLEANUP" "Removed stale .spec-active marker (path: $active_path)" 2>/dev/null || true
        # Return error - don't silently fallback to wrong directory
        echo "⚠️  Warning: Stale marker pointed to deleted folder: $active_path" >&2
        # Continue to fallback below, but log the warning
      fi
    fi
  fi

  # Fallback: use root memory/ if it exists (only if no stale marker was found)
  if [ -d "$spec_folder/memory" ]; then
    echo "$spec_folder/memory"
    return 0
  fi

  return 1
}

# List recent memory files (sorted by timestamp, most recent first)
# Returns:
#   0 - Success (files found and listed)
#   1 - Empty (directory exists but no memory files)
#   2 - Error (directory doesn't exist)
list_recent_memory_files() {
  local memory_dir="$1"
  local limit="${2:-3}"

  # Error: Directory doesn't exist
  if [ ! -d "$memory_dir" ]; then
    return 2
  fi

  # Find all memory files matching pattern: DD-MM-YY_HH-MM__topic.md
  local files
  files=$(find "$memory_dir" -maxdepth 1 -type f -name "*__*.md" 2>/dev/null | sort -r | head -n "$limit")

  # Empty: Directory exists but no files found
  if [ -z "$files" ]; then
    return 1
  fi

  # Success: Files found
  echo "$files"
  return 0
}

# Extract metadata from memory file's metadata.json
extract_memory_metadata() {
  local memory_dir="$1"
  local metadata_file="$memory_dir/metadata.json"

  # Default values if metadata doesn't exist
  local message_count="?"
  local decision_count="?"
  local timestamp="?"

  # Validate metadata file exists and is readable
  if [ ! -f "$metadata_file" ]; then
    echo "${message_count},${decision_count},${timestamp}"
    return 1
  fi

  if [ ! -r "$metadata_file" ]; then
    echo "${message_count},${decision_count},${timestamp}"
    return 1
  fi

  # Validate JSON format before parsing
  if ! validate_json "$metadata_file" >/dev/null 2>&1; then
    echo "${message_count},${decision_count},${timestamp}"
    return 1
  fi

  # Extract fields with error handling
  message_count=$(jq -r '.messageCount // "?"' "$metadata_file" 2>/dev/null || echo "?")
  decision_count=$(jq -r '.decisionCount // "?"' "$metadata_file" 2>/dev/null || echo "?")
  timestamp=$(jq -r '.timestamp // "?"' "$metadata_file" 2>/dev/null || echo "?")

  echo "${message_count},${decision_count},${timestamp}"
  return 0
}

# Calculate relative time from timestamp (DD-MM-YY_HH-MM format)
calculate_relative_time() {
  local filename="$1"

  # Validate input
  if [ -z "$filename" ]; then
    echo "unknown"
    return 1
  fi

  # Extract timestamp from filename (DD-MM-YY_HH-MM__topic.md)
  local timestamp=$(echo "$filename" | grep -oE '[0-9]{2}-[0-9]{2}-[0-9]{2}_[0-9]{2}-[0-9]{2}' | head -1)

  if [ -z "$timestamp" ]; then
    echo "unknown"
    return 1
  fi

  # Parse timestamp: DD-MM-YY_HH-MM
  local day=$(echo "$timestamp" | cut -d'-' -f1)
  local month=$(echo "$timestamp" | cut -d'-' -f2)
  local year=$(echo "$timestamp" | cut -d'-' -f3 | cut -d'_' -f1)
  local hour=$(echo "$timestamp" | cut -d'_' -f2 | cut -d'-' -f1)
  local minute=$(echo "$timestamp" | cut -d'-' -f4)

  # Validate extracted components
  if [ -z "$day" ] || [ -z "$month" ] || [ -z "$year" ] || [ -z "$hour" ] || [ -z "$minute" ]; then
    echo "unknown"
    return 1
  fi

  # Validate numeric ranges
  if [ "$day" -lt 1 ] || [ "$day" -gt 31 ] || \
     [ "$month" -lt 1 ] || [ "$month" -gt 12 ] || \
     [ "$hour" -lt 0 ] || [ "$hour" -gt 23 ] || \
     [ "$minute" -lt 0 ] || [ "$minute" -gt 59 ]; then
    echo "unknown"
    return 1
  fi

  # Convert to full year (20XX format)
  local full_year="20${year}"

  # Get current time in seconds since epoch
  local now=$(date +%s 2>/dev/null)
  if [ -z "$now" ]; then
    echo "unknown"
    return 1
  fi

  # Convert file timestamp to seconds since epoch (format: YYYY-MM-DD HH:MM:SS)
  # Platform-specific date command syntax
  local file_time=""
  if [[ "$OSTYPE" == "darwin"* ]]; then
    # macOS: use -j flag
    file_time=$(date -j -f "%Y-%m-%d %H:%M:%S" "${full_year}-${month}-${day} ${hour}:${minute}:00" +%s 2>/dev/null)
  else
    # Linux: use -d flag
    file_time=$(date -d "${full_year}-${month}-${day} ${hour}:${minute}:00" +%s 2>/dev/null)
  fi

  if [ -z "$file_time" ] || [ "$file_time" = "" ]; then
    echo "unknown"
    return 1
  fi

  # Calculate difference in seconds
  local diff=$((now - file_time))

  # Handle negative differences (file in future - clock skew)
  if [ $diff -lt 0 ]; then
    echo "recent"
    return 0
  fi

  # Convert to human-readable format
  if [ $diff -lt 3600 ]; then
    # Less than 1 hour
    local minutes=$((diff / 60))
    if [ $minutes -lt 1 ]; then
      echo "just now"
    else
      echo "${minutes} min ago"
    fi
  elif [ $diff -lt 86400 ]; then
    # Less than 1 day
    local hours=$((diff / 3600))
    echo "${hours}h ago"
  else
    # Days
    local days=$((diff / 86400))
    if [ $days -eq 1 ]; then
      echo "1d ago"
    else
      echo "${days}d ago"
    fi
  fi

  return 0
}

# Load spec.md summary (objective, status, key info)
load_spec_summary() {
  local spec_folder="$1"
  local spec_file="$spec_folder/spec.md"

  if [ ! -f "$spec_file" ]; then
    return 1
  fi

  # Extract metadata from spec.md
  local metadata=$(extract_metadata "$spec_file")
  local status="?"
  local level="?"
  local estimated_loc="?"

  if [ -n "$metadata" ]; then
    status=$(echo "$metadata" | grep -iE "^[- ]*status:" | sed 's/.*status:\s*//' | sed 's/[[:space:]]*$//' | tr -d '[]"' | head -1)
    level=$(echo "$metadata" | grep -iE "^[- ]*level:" | sed 's/.*level:\s*//' | sed 's/[[:space:]]*$//' | tr -d '[]"' | head -1)
    estimated_loc=$(echo "$metadata" | grep -iE "^[- ]*estimated_loc:" | sed 's/.*estimated_loc:\s*//' | sed 's/[[:space:]]*$//' | tr -d '[]"' | head -1)
  fi

  # Extract objective (first paragraph after ## 1. Objective)
  local objective=""
  if grep -q '^## 1\. .*Objective' "$spec_file" 2>/dev/null; then
    objective=$(sed -n '/^## 1\. .*Objective/,/^##/p' "$spec_file" \
      | tail -n +2 \
      | head -n -1 \
      | grep -v '^$' \
      | head -3 \
      | tr '\n' ' ' \
      | sed 's/  */ /g')
  fi

  # Return formatted summary
  echo "STATUS:${status}|LEVEL:${level}|LOC:${estimated_loc}|OBJECTIVE:${objective}"
}

# Present memory selection prompt to user
present_memory_selection_prompt() {
  local spec_folder="$1"
  local memory_dir=$(find_memory_directory "$spec_folder")

  if [ -z "$memory_dir" ]; then
    # No memory directory found
    return 1
  fi

  # List recent memory files
  local recent_files=$(list_recent_memory_files "$memory_dir" 3)

  if [ -z "$recent_files" ]; then
    # No memory files found
    return 1
  fi

  # Load spec summary
  local spec_summary=$(load_spec_summary "$spec_folder")
  local status=$(echo "$spec_summary" | grep -oE 'STATUS:[^|]*' | cut -d':' -f2)
  local level=$(echo "$spec_summary" | grep -oE 'LEVEL:[^|]*' | cut -d':' -f2)
  local estimated_loc=$(echo "$spec_summary" | grep -oE 'LOC:[^|]*' | cut -d':' -f2)
  local objective=$(echo "$spec_summary" | grep -oE 'OBJECTIVE:.*' | cut -d':' -f2-)

  # Display spec context header
  echo ""
  echo "───────────────────────────────────────────────────────────────"
  echo "📋 SPEC CONTEXT AVAILABLE"
  echo "───────────────────────────────────────────────────────────────"
  echo ""
  echo "Active Spec: $(basename "$spec_folder")/"

  if [ -n "$status" ] && [ "$status" != "?" ]; then
    echo "Status: $status | Level: $level | Est. LOC: ~${estimated_loc}"
  fi

  if [ -n "$objective" ] && [ "$objective" != "" ]; then
    echo ""
    echo "Current Objective:"
    echo "  ${objective:0:200}"
    if [ ${#objective} -gt 200 ]; then
      echo "  ..."
    fi
  fi

  # Display memory files section
  echo ""
  echo "🧠 PREVIOUS SESSION CONTEXT"
  echo ""
  echo "Recent Memory Files:"

  local index=1
  while IFS= read -r file; do
    if [ -n "$file" ]; then
      local basename=$(basename "$file")
      local date_time=$(echo "$basename" | cut -d'_' -f1-2)
      local topic=$(echo "$basename" | cut -d'_' -f3- | sed 's/.md$//' | tr '_' ' ')
      local relative_time=$(calculate_relative_time "$basename")

      echo "  $index. $date_time - $topic ($relative_time)"
      index=$((index + 1))
    fi
  done <<< "$recent_files"

  # Display memory selection options (user-facing)
  echo ""
  echo "📂 Memory files from previous session(s):"
  echo "  A) Load most recent (file 1)"
  echo "  B) Load all recent (files 1-3)"
  echo "  C) List all memory files and select specific"
  echo "  D) Skip (start fresh)"
  echo ""
  echo "🔴 AI: Ask user to select A/B/C/D"
  echo ""
  # AI instructions block (parseable, separate from user display)
  echo "<!-- AI_INSTRUCTIONS"
  echo "After user selects option, execute:"
  echo "  A: Read file 1 using Read tool"
  echo "  B: Read files 1-3 using Read tool (parallel calls)"
  echo "  C: List up to 10 files, wait for user selection, then read"
  echo "  D: Proceed without loading memory files"
  echo "AI_INSTRUCTIONS -->"
  echo ""
  echo "───────────────────────────────────────────────────────────────"
  echo ""

  return 0
}

# ───────────────────────────────────────────────────────────────

estimate_documentation_level() {
  local text="$1"
  # Note: Level 0 eliminated. Typos are Level 1 (or exempt if single typo <5 chars)

  # Level 1: Simple, trivial changes
  if echo "$text" | grep -qiE "typo|misspell|spelling|grammar|whitespace|rename|single file|small fix|docs only|comment|readme|formatting"; then
    echo 1
    return
  fi

  # Level 3: Complex, architectural changes
  if echo "$text" | grep -qiE "architecture|system|platform|multiple services|rebuild|major refactor|redesign|overhaul|migration|database schema"; then
    echo 3
    return
  fi

  # Level 2+: Sensitive areas that need proper documentation
  if echo "$text" | grep -qiE "auth|security|api|database|deploy|config|environment|secrets|permissions|roles"; then
    echo 2
    return
  fi

  # Level 2: Scope expansion indicators
  if echo "$text" | grep -qiE "and also|plus|additionally|multiple|several|complete|full|entire|all of"; then
    echo 2
    return
  fi

  # Level 2: Standard feature work
  if echo "$text" | grep -qiE "feature|component|integration|workflow|refactor|implement|create|build|develop"; then
    echo 2
    return
  fi

  echo 2  # Default to Level 2 (moderate is safer than under-documenting)
}

DOC_LEVEL=$(estimate_documentation_level "$PROMPT_LOWER")

get_level_label() {
  case "$DOC_LEVEL" in
    1) echo "1 (Baseline: spec + plan + tasks)" ;;
    2) echo "2 (Verification: L1 + checklist)" ;;
    3) echo "3 (Full: L2 + decision-record)" ;;
    *) echo "1 (Baseline: spec + plan + tasks)" ;;  # Default to L1
  esac
}

# ───────────────────────────────────────────────────────────────
# RELATED SPEC DISCOVERY FUNCTIONS
# ───────────────────────────────────────────────────────────────

extract_keywords() {
  local text="$1"
  # Remove common stop words and extract significant terms
  # Also split compound words on hyphens for broader matching
  local keywords=$(echo "$text" | \
    tr '[:upper:]' '[:lower:]' | \
    tr '-' ' ' | \
    sed -E 's/\b(the|is|a|an|and|or|but|in|on|at|to|for|of|with|from)\b//g' | \
    tr -s ' ' '\n' | \
    grep -E '^[a-z]{2,}$' | \
    sort -u | \
    head -15)
  echo "$keywords"
}

get_spec_status() {
  local spec_folder="$1"
  local spec_file="$spec_folder/spec.md"

  if [ ! -f "$spec_file" ]; then
    echo "active"  # Default if spec.md missing
    return
  fi

  # Extract from YAML frontmatter (between --- markers)
  local status=$(awk '/^---$/,/^---$/ {if (/^status:/) {print $2; exit}}' "$spec_file" 2>/dev/null)

  # Default to "active" if missing
  echo "${status:-active}"
}

status_priority() {
  local status="$1"
  case "$status" in
    active) echo "1" ;;
    draft) echo "2" ;;
    paused) echo "3" ;;
    complete) echo "4" ;;
    archived) echo "5" ;;
    *) echo "1" ;; # Treat unknown as active
  esac
}

find_related_specs() {
  # Temporarily disable nounset to handle empty arrays safely
  # (template-validation.sh sets -u which breaks ${array[@]} on empty arrays)
  local _prev_set=$(set +o | grep nounset)
  set +u

  local prompt="$1"
  local keywords=$(extract_keywords "$prompt")

  if [ -z "$keywords" ] || [ ! -d "$SPECS_DIR" ]; then
    eval "$_prev_set"  # Restore original setting
    return
  fi

  # Separate parent matches from child matches (bash 3.2 compatible)
  # Initialize as empty arrays to avoid unbound variable errors with set -u
  declare -a parent_active=()
  declare -a parent_inactive=()
  declare -a child_matches=()

  # Array size limit to prevent memory exhaustion on large codebases
  local MAX_MATCHES=50

  # Helper to check if folder already in array
  folder_in_array() {
    local check="$1"
    shift
    local arr=("$@")
    for item in "${arr[@]}"; do
      # Extract folder path (before first colon)
      local folder="${item%%:*}"
      [[ "$folder" == "$check" ]] && return 0
    done
    return 1
  }

  # Search spec folder names for keyword matches
  while IFS= read -r keyword; do
    [ -z "$keyword" ] && continue

    while IFS= read -r folder; do
      [ -z "$folder" ] && continue
      local name=$(basename "$folder")

      # Skip if folder name is just numbers
      [[ "$name" =~ ^[0-9]+$ ]] && continue

      # Check if keyword matches folder name
      if echo "$name" | grep -qiE "$keyword"; then

        # Determine if parent or child folder
        if is_parent_folder "$folder"; then
          # Check for .spec-active marker
          local active_child=$(get_active_child "$folder")

          if [ -n "$active_child" ]; then
            # Active parent (has .spec-active marker)
            if ! folder_in_array "$folder" "${parent_active[@]}" && [[ ${#parent_active[@]} -lt $MAX_MATCHES ]]; then
              parent_active+=("$folder:$(basename "$active_child"):PARENT_ACTIVE")
            fi
          else
            # Inactive parent (no .spec-active marker)
            if ! folder_in_array "$folder" "${parent_inactive[@]}" && [[ ${#parent_inactive[@]} -lt $MAX_MATCHES ]]; then
              parent_inactive+=("$folder::PARENT_INACTIVE")
            fi
          fi
        else
          # Regular child/working folder
          if ! folder_in_array "$folder" "${child_matches[@]}" && [[ ${#child_matches[@]} -lt $MAX_MATCHES ]]; then
            local status=$(get_spec_status "$folder")
            local priority=$(status_priority "$status")
            child_matches+=("$priority:$folder:$status:CHILD")
          fi
        fi
      fi
    done < <(find "$SPECS_DIR" -maxdepth 1 -mindepth 1 -type d -name "[0-9]*-*" 2>/dev/null)
  done <<< "$keywords"

  # Prioritize: Active parents > Inactive parents > Child matches
  # For child matches, sort by status priority first
  {
    printf '%s\n' "${parent_active[@]}"
    printf '%s\n' "${parent_inactive[@]}"
    printf '%s\n' "${child_matches[@]}" | sort -t: -k1 -n
  } | head -3

  # Restore original nounset setting
  eval "$_prev_set"
}

print_template_guidance() {
  case "$DOC_LEVEL" in
    1)
      print_detail "cp .opencode/speckit/templates/spec.md specs/${NEXT_SPEC_NUMBER}-short-name/spec.md"
      ;;
    2)
      print_detail "cp .opencode/speckit/templates/spec.md specs/${NEXT_SPEC_NUMBER}-short-name/spec.md"
      print_detail "cp .opencode/speckit/templates/plan.md specs/${NEXT_SPEC_NUMBER}-short-name/plan.md"
      ;;
    3)
      print_detail "/spec_kit:complete (auto-generates Level 3 bundle)"
      ;;
  esac

  # ───────────────────────────────────────────────────────────────
  # COMPLEXITY-BASED TEMPLATE RECOMMENDATIONS (Phase 2: US4-7)
  # ───────────────────────────────────────────────────────────────

  if [ "$VALIDATION_LIB_LOADED" = true ]; then
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "💡 ADDITIONAL TEMPLATE RECOMMENDATIONS:"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

    local recommendations_made=false
    local user_input="$PROMPT"

    # Read complexity data from shared state (written by orchestrate-skill-validation.sh)
    # Falls back to defaults if state is stale (>60s) or unavailable
    local complexity_data
    complexity_data=$(read_hook_state "complexity" 60 2>/dev/null) || complexity_data=""
    local complexity_score=0
    local domain_count=1
    if [ -n "$complexity_data" ]; then
      complexity_score=$(echo "$complexity_data" | jq -r '.complexity_score // 0' 2>/dev/null) || complexity_score=0
      domain_count=$(echo "$complexity_data" | jq -r '.domain_count // 1' 2>/dev/null) || domain_count=1
    fi

    # Check for research-spike template need (investigation/POC work)
    local spike_result
    spike_result=$(detect_spike_needed "$user_input" "$complexity_score" 2>/dev/null) || spike_result=""

    if [ -n "$spike_result" ]; then
      recommendations_made=true
      echo "🔬 Research-Spike Template: [$spike_result]"
      echo "   Your task involves investigation/POC work"
      echo "   Command: cp .opencode/speckit/templates/research-spike.md specs/${NEXT_SPEC_NUMBER}-short-name/research-spike-[topic].md"
      echo ""
    fi

    # Check for research template need (exploration/comparison)
    local research_result
    research_result=$(detect_research_needed "$user_input" "$complexity_score" "$domain_count" 2>/dev/null) || research_result=""

    if [ -n "$research_result" ]; then
      recommendations_made=true
      echo "📚 Research Template: [$research_result]"
      echo "   Your task involves comprehensive research/exploration"
      echo "   Command: cp .opencode/speckit/templates/research.md specs/${NEXT_SPEC_NUMBER}-short-name/research.md"
      echo ""
    fi

    # Check for decision record need (architecture decisions)
    local decision_result
    decision_result=$(detect_decision_record_needed "$user_input" "$complexity_score" 2>/dev/null) || decision_result=""

    if [ -n "$decision_result" ]; then
      recommendations_made=true
      echo "📋 Decision Record Template: [$decision_result]"
      echo "   Your task involves architectural/technical decisions"
      echo "   Command: cp .opencode/speckit/templates/decision-record.md specs/${NEXT_SPEC_NUMBER}-short-name/decision-[topic].md"
      echo ""
    fi

    if [ "$recommendations_made" = false ]; then
      echo "No additional templates recommended for this task complexity"
    fi

    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  fi
}

show_confirmation_prompt() {
  local reason="$1"
  local folder="$2"

  # Build options JSON based on context
  local options=""
  local option_a_label=""
  local option_a_desc=""
  local option_b_label=""
  local option_b_desc=""

  if [ -n "$folder" ]; then
    # Folder detected: A=use, B=new
    option_a_label="Use detected folder"
    option_a_desc="$(basename "$folder")"
    option_b_label="Create new folder"
    option_b_desc="specs/${NEXT_SPEC_NUMBER}-feature-name/"
  else
    # No folder: A=new, B=different-number
    option_a_label="Create new folder"
    option_a_desc="specs/${NEXT_SPEC_NUMBER}-feature-name/"
    option_b_label="Different number"
    option_b_desc="Specify a different spec folder number"
  fi

  # Build options array - always include A, B, D; include C if related specs exist
  if [ -n "$RELATED_SPECS" ]; then
    options='[
      {"id": "A", "label": "'"$option_a_label"'", "description": "'"$option_a_desc"'"},
      {"id": "B", "label": "'"$option_b_label"'", "description": "'"$option_b_desc"'"},
      {"id": "C", "label": "Update related spec", "description": "Choose from related specs shown above"},
      {"id": "D", "label": "Skip documentation", "description": "Proceed without spec folder (creates technical debt)"}
    ]'
  else
    options='[
      {"id": "A", "label": "'"$option_a_label"'", "description": "'"$option_a_desc"'"},
      {"id": "B", "label": "'"$option_b_label"'", "description": "'"$option_b_desc"'"},
      {"id": "D", "label": "Skip documentation", "description": "Proceed without spec folder (creates technical debt)"}
    ]'
  fi

  # Build context JSON
  local context
  context=$(cat <<EOF
{
  "detected_intent": "${DETECTED_INTENT:-unknown}",
  "estimated_level": "$(get_level_label)",
  "next_spec_number": "${NEXT_SPEC_NUMBER}",
  "detected_folder": "${folder:-null}",
  "has_related_specs": $([ -n "$RELATED_SPECS" ] && echo "true" || echo "false"),
  "reason": "${reason}"
}
EOF
)

  # Pre-compute memory files for multi-stage flow
  local memory_files_json="[]"
  if [ -n "$folder" ]; then
    local memory_dir=$(find_memory_directory "$folder")
    if [ -n "$memory_dir" ] && [ -d "$memory_dir" ]; then
      # Build JSON array of memory files
      local files_array=""
      while IFS= read -r file; do
        if [ -n "$file" ]; then
          local filename=$(basename "$file")
          local rel_path="${memory_dir#$PROJECT_ROOT/}/$filename"
          if [ -n "$files_array" ]; then
            files_array="$files_array,"
          fi
          files_array="$files_array\"$rel_path\""
        fi
      done < <(find "$memory_dir" -maxdepth 1 -type f -name "*__*.md" 2>/dev/null | sort -r | head -5)

      if [ -n "$files_array" ]; then
        memory_files_json="[$files_array]"
      fi
    fi
  fi

  # EMIT THE MANDATORY QUESTION SIGNAL
  # This is the key integration point - uses signal-output.sh library
  # Terminal-visible notification via systemMessage
  echo "{\"systemMessage\": \"📁 Spec folder required - please select option A/B/C/D\"}"
  emit_mandatory_question "SPEC_FOLDER_CHOICE" \
    "Which spec folder should we use for this work?" \
    "$options" \
    "$context"

  # Set question flow state for multi-stage tracking
  # This enables stage 2 (memory load) question after user answers stage 1
  set_question_flow "spec_folder" "$folder" "$memory_files_json" ""

  # Also output human-readable context (for logs and fallback)
  echo ""
  echo "📊 Context Information:"
  echo "   Detected Intent: ${DETECTED_INTENT:-unknown}"
  echo "   Documentation Level: $(get_level_label)"
  echo "   Status: $reason"
  echo ""
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "📋 DOCUMENTATION LEVEL GUIDANCE"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo ""
  case "$DOC_LEVEL" in
    1)
      echo "📌 Suggested: Level 1 (Baseline)"
      echo "   Templates: spec.md + plan.md + tasks.md (all required)"
      echo "   Typical LOC: <100 lines (soft guidance)"
      echo ""
      echo "   Why: Baseline documentation for all work"
      echo "   (every feature gets spec + plan + tasks)"
      ;;
    2)
      echo "📌 Suggested: Level 2 (Verification)"
      echo "   Templates: Level 1 + checklist.md (required)"
      echo "   All files: spec.md, plan.md, tasks.md, checklist.md"
      echo "   Typical LOC: 100-500 lines (soft guidance)"
      echo ""
      echo "   Why: Detected feature work or sensitive areas"
      echo "   (auth, api, database, config, integration, etc.)"
      ;;
    3)
      echo "📌 Suggested: Level 3 (Complex)"
      echo "   Templates: Full SpecKit"
      echo "   Required: spec.md + plan.md + tasks.md"
      echo "   Optional: research.md, decision-record-*.md"
      echo "   Typical LOC: 500+ lines"
      echo ""
      echo "   Why: Detected architectural/platform-level work"
      echo "   (architecture, rebuild, migration, redesign, etc.)"
      ;;
  esac
  echo ""
  echo "💡 If you disagree, tell the AI which level to use."
  echo "   Rule: When in doubt, choose higher level."
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

  # OPTIONAL TEMPLATE RECOMMENDATIONS (shown BEFORE user makes choice)
  if [ "$VALIDATION_LIB_LOADED" = true ]; then
    local user_input="$PROMPT"
    local complexity_data
    complexity_data=$(read_hook_state "complexity" 60 2>/dev/null) || complexity_data=""
    local complexity_score=0
    local domain_count=1
    if [ -n "$complexity_data" ]; then
      complexity_score=$(echo "$complexity_data" | jq -r '.complexity_score // 0' 2>/dev/null) || complexity_score=0
      domain_count=$(echo "$complexity_data" | jq -r '.domain_count // 1' 2>/dev/null) || domain_count=1
    fi

    local spike_result=""
    local research_result=""
    local decision_result=""

    spike_result=$(detect_spike_needed "$user_input" "$complexity_score" 2>/dev/null) || spike_result=""
    research_result=$(detect_research_needed "$user_input" "$complexity_score" "$domain_count" 2>/dev/null) || research_result=""
    decision_result=$(detect_decision_record_needed "$user_input" "$complexity_score" 2>/dev/null) || decision_result=""

    if [ -n "$spike_result" ] || [ -n "$research_result" ] || [ -n "$decision_result" ]; then
      echo ""
      echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
      echo "🎯 OPTIONAL TEMPLATES RECOMMENDED"
      echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
      [ -n "$spike_result" ] && echo "  🔬 Research-Spike: [$spike_result] - for investigation/POC"
      [ -n "$research_result" ] && echo "  📚 Research: [$research_result] - for comprehensive exploration"
      [ -n "$decision_result" ] && echo "  📋 Decision Record: [$decision_result] - for architecture decisions"
      echo ""
      echo "  Include these in your spec folder for better documentation."
      echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    fi
  fi

  if [ -n "$folder" ]; then
    echo "   Detected Folder: $folder"

    # Check if folder has root-level content requiring migration
    if has_root_level_content "$folder"; then
      echo ""
      echo "📦 SUB-FOLDER VERSIONING INFO:"
      echo "   If Option A selected, existing files will be archived to 001-{topic}/"
      echo "   New work will go in 002-{new-name}/"
      echo "   AI must ask for sub-folder name after user selects Option A"
    fi
  fi

  # Check if folder has memory files and add guidance
  if [ -n "$folder" ]; then
    local memory_dir=$(find_memory_directory "$folder")
    if [ -n "$memory_dir" ] && [ -d "$memory_dir" ]; then
      local memory_file_count=$(find "$memory_dir" -maxdepth 1 -type f -name "*__*.md" 2>/dev/null | wc -l | tr -d ' ')
      if [ "$memory_file_count" -gt 0 ]; then
        echo ""
        echo "🧠 MEMORY FILES DETECTED"
        echo "The detected spec folder contains $memory_file_count previous session file(s) in memory/."
        echo ""
        echo "⚠️  AI: If user selects Option A, you should ALSO:"
        echo "  1. Load spec summary from spec.md (objective, status, progress)"
        echo "  2. List recent memory files (3 most recent)"
        echo "  3. Ask user: 'Would you like to load previous session context?'"
        echo "     A) Load most recent memory file"
        echo "     B) Load all recent memory files (1-3)"
        echo "     C) List all and select specific"
        echo "     D) Skip (start fresh)"
        echo "  4. Read selected memory file(s) using Read tool"
        echo "  5. Summarize loaded context before continuing"
        echo ""
        echo "Memory files provide conversation history, decisions, and progress from previous sessions."
      fi
    fi
  fi

  echo ""
  echo "📝 Required format for your response:"
  echo "  Choice: [A/B/C/D]"
  echo "  Reason: [your explanation]"
  echo ""
  echo "📝 Next steps after choosing:"
  echo ""
  echo "If user selects D (Skip):"
  echo "  mkdir -p .claude && echo 'skip' > .claude/.spec-skip"
  echo "  (This creates skip marker to prevent future prompts)"
  echo ""
  echo "If user selects A/B/C (Create spec folder):"
  print_template_guidance
  echo ""
  echo "📖 Reference: $DOC_GUIDE"
  echo ""
  echo "⚠️  Do not start implementation until you've made your selection."
  echo "⚠️  This is an INTERACTIVE prompt - wait for user's explicit choice."
  echo ""
}

handle_confirmation() {
  local reason="$1"
  local folder="$2"
  log_event "CONFIRMATION_NEEDED" "$reason"

  # Emit mandatory question signal for proper blocking
  # This uses the signal-output.sh library for consistent AI interaction
  if type emit_mandatory_question &>/dev/null; then
    local options_json='[
      {"id":"A","label":"Use existing spec folder","description":"Continue work in existing folder"},
      {"id":"B","label":"Create new spec folder","description":"Create fresh spec folder for new work"},
      {"id":"C","label":"Update related spec","description":"Add to related existing spec"},
      {"id":"D","label":"Skip documentation","description":"Skip and create .spec-skip marker"}
    ]'
    local context_json="{\"folder\": \"${folder:-none}\", \"reason\": \"${reason}\"}"

    emit_mandatory_question "SPEC_FOLDER_CHOICE" \
      "Which spec folder would you like to use for this work?" \
      "$options_json" \
      "$context_json"
  fi

  # Also show human-readable confirmation prompt
  show_confirmation_prompt "$reason" "$folder"

  # Always exit 0 to allow prompt to proceed to AI
  # AI will see confirmation request and respond accordingly
  return 0
}

handle_warning() {
  local reason="$1"
  log_event "WARNING" "$reason"
  print_warn_box "Documentation Warning" "$reason" "Mode: warning-only (execution allowed)"
}

if ! detect_modification_intent; then
  echo "✓ [enforce-spec-folder] No modification detected, skipping validation" >&2
  END_TIME=$(_get_nano_time)
  DURATION=$(((END_TIME - START_TIME)/1000000))
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] enforce-spec-folder.sh ${DURATION}ms" >> "$PERF_LOG"
  exit 0
fi

echo "⚡ [enforce-spec-folder] Modification intent detected, validating spec folder..." >&2

load_enforcement_config

if exception_matches_prompt; then
  log_event "ALLOWED" "Exception matched: $ALLOWED_EXCEPTION_REASON"
  END_TIME=$(_get_nano_time)
  DURATION=$(((END_TIME - START_TIME)/1000000))
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] enforce-spec-folder.sh ${DURATION}ms" >> "$PERF_LOG"
  exit 0
fi

# ───────────────────────────────────────────────────────────────
# CHECK FOR SKIP MARKER
# ───────────────────────────────────────────────────────────────
# If user previously selected skip option, allow conversation to proceed
# without spec folder validation

if has_skip_marker; then
  log_event "SKIPPED" "Skip marker detected - user previously selected skip option"
  echo "⚡ [enforce-spec-folder] Skip marker detected - proceeding without spec folder" >&2
  END_TIME=$(_get_nano_time)
  DURATION=$(((END_TIME - START_TIME)/1000000))
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] enforce-spec-folder.sh ${DURATION}ms (skipped)" >> "$PERF_LOG"
  exit 0
fi

# ───────────────────────────────────────────────────────────────
# SEARCH FOR RELATED SPECS
# ───────────────────────────────────────────────────────────────

RELATED_SPECS=$(find_related_specs "$PROMPT")

if [ -n "$RELATED_SPECS" ]; then
  echo "📋 [enforce-spec-folder] Found related specs, suggesting reuse..." >&2
  print_section "RELATED SPECS FOUND"
  print_detail "Found existing specs that may be related to your request:"
  print_line

  while IFS=':' read -r field1 field2 field3 field4; do
    # Parse format based on type (4th field)
    # Parent format: path:active_child:PARENT_ACTIVE or path::PARENT_INACTIVE
    # Child format: priority:path:status:CHILD

    # Note: Can't use 'local' here as this is in main script body, not a function
    _path=""
    _type="${field4:-$field3}"  # Type is 4th field for children, 3rd for parents

    # Determine path based on format
    if [[ "$_type" == PARENT_* ]]; then
      # Parent format: field1=path, field2=active_child, field3=type
      _path="$field1"
      _active_child="$field2"
      _name=$(basename "$_path")

      if [[ "$_type" == "PARENT_ACTIVE" ]]; then
        print_detail "  🏢 $_name (PARENT FOLDER - active work ongoing)"
        print_detail "    → Active child: $_active_child"
        print_detail "    → Suggested: Continue in new sub-folder"
        print_detail "    → Path: $_path"
      else
        print_detail "  🏢 $_name (PARENT FOLDER - inactive)"
        print_detail "    → No active work currently"
        print_detail "    → Suggested: Resume or create new sub-folder"
        print_detail "    → Path: $_path"
      fi
      print_line
    elif [[ "$_type" == "CHILD" ]]; then
      # Child format: field1=priority, field2=path, field3=status, field4=CHILD
      _path="$field2"
      _status="$field3"
      _name=$(basename "$_path")
      _status_label=""

      case "$_status" in
        active) _status_label="✓ ACTIVE - recommended for updates" ;;
        draft) _status_label="◐ DRAFT - can be started" ;;
        paused) _status_label="⏸  PAUSED - can be resumed" ;;
        complete) _status_label="✓ COMPLETE - reopening discouraged" ;;
        archived) _status_label="📦 ARCHIVED - do not reuse" ;;
        *) _status_label="status: $_status" ;;
      esac

      print_detail "  • $_name"
      print_detail "    Status: $_status_label"
      print_detail "    Path: $_path"
      print_line
    fi
  done <<< "$RELATED_SPECS"

  print_section "RECOMMENDATION"
  print_detail "Consider updating one of the related specs above instead of creating a new one."
  print_detail "For parent folders, system will create new numbered sub-folder automatically."
  print_detail "Guidelines: .claude/skills/workflows-spec-kit/SKILL.md"
  print_detail ""
  print_detail "AI should ask user:"
  print_detail "  A) Update existing spec (if work is related)"
  print_detail "  B) Create new spec (if work is distinct)"
  print_line
fi

# ───────────────────────────────────────────────────────────────

SPEC_FOLDER=""
SPEC_FOLDER_NAME=""
NEEDS_CONFIRMATION=false

if [ "$CHECK_SPEC_FOLDER" != "false" ]; then
  # Sync global marker to local markers before folder detection
  sync_marker_to_parent 2>/dev/null || true

  SPEC_FOLDER=$(find_latest_spec_folder)

  # ───────────────────────────────────────────────────────────────
  # SKIP VALIDATION IF MID-CONVERSATION (SUBSTANTIAL CONTENT EXISTS)
  # ───────────────────────────────────────────────────────────────
  # Only prompt at start when spec folder is empty or has minimal content.
  # Once real work has started (files added or substantial edits made),
  # skip validation to avoid repeated prompts during conversation.

  if [ -n "$SPEC_FOLDER" ] && has_substantial_content "$SPEC_FOLDER"; then
    SPEC_FOLDER_NAME=$(basename "$SPEC_FOLDER")
    log_event "ALLOWED" "Mid-conversation detected in $SPEC_FOLDER_NAME (substantial content exists, checking for memory files)"
    echo "✅ [enforce-spec-folder] Mid-conversation: ${SPEC_FOLDER_NAME} (checking memory files)" >&2

    # Initialize scope tracking for mid-conversation detection (Phase 5)
    # Only write if not already set (first detection in this session)
    if ! has_hook_state "initial_scope" 7200 2>/dev/null; then
      _files_count=$(find "$SPEC_FOLDER" -maxdepth 2 -name "*.md" 2>/dev/null | wc -l | tr -d ' ')
      write_hook_state "initial_scope" "{
        \"spec_folder\": \"$SPEC_FOLDER\",
        \"files_count\": $_files_count,
        \"level\": $DOC_LEVEL,
        \"timestamp\": \"$(date -u +%Y-%m-%dT%H:%M:%SZ)\"
      }" 2>/dev/null || true
    fi

    # Initialize scope definition for file-scope-tracking.sh integration
    # This supports the detect-scope-growth.sh hook
    if ! has_hook_state "scope_definition" 7200 2>/dev/null; then
      if type initialize_scope_definition &>/dev/null; then
        initialize_scope_definition "$SPEC_FOLDER" "$PROMPT" 2>/dev/null || true
      fi
    fi

    # ─────────────────────────────────────────────────────────────
    # TOPIC DIVERGENCE DETECTION - Check if prompt matches current task
    # ─────────────────────────────────────────────────────────────
    # Calculate keyword divergence to detect task changes mid-conversation.
    # If divergence exceeds threshold, emit mandatory question asking if
    # user is switching tasks. This replaces the old warning-only check.
    # ─────────────────────────────────────────────────────────────

    if [ -f "$SPEC_MARKER" ]; then
      active_marker_path=$(cat "$SPEC_MARKER" 2>/dev/null | tr -d '\n')
      if [ -n "$active_marker_path" ]; then
        # Verify marker points to existing folder, cleanup if stale
        if [ ! -d "$active_marker_path" ]; then
          log_event "MARKER_CLEANUP" "Removing stale marker pointing to deleted folder: $active_marker_path"
          echo "🧹 [enforce-spec-folder] Cleaned up stale marker (folder no longer exists): $(basename "$active_marker_path")" >&2
          cleanup_spec_marker 2>/dev/null || rm -f "$SPEC_MARKER" 2>/dev/null
          active_marker_path=""
        else
          # Calculate topic divergence using keyword fingerprinting
          DIVERGENCE_SCORE=$(calculate_divergence_score "$PROMPT" 2>/dev/null || echo "50")

          log_event "DIVERGENCE_CHECK" "Score: ${DIVERGENCE_SCORE}% for $SPEC_FOLDER_NAME"

          if [ "$DIVERGENCE_SCORE" -gt 60 ] 2>/dev/null; then
            # High divergence - emit blocking question asking if switching tasks
            log_event "TASK_CHANGE_DETECTED" "High divergence (${DIVERGENCE_SCORE}%), asking user"
            echo "" >&2
            echo "⚠️  [enforce-spec-folder] Topic divergence detected (${DIVERGENCE_SCORE}%)" >&2
            echo "   Current spec: $SPEC_FOLDER_NAME" >&2
            echo "   Your request may be for a different task." >&2
            echo "" >&2

            # Emit the mandatory task change question
            echo "{\"systemMessage\": \"📁 Task change detected (${DIVERGENCE_SCORE}% divergence) - please confirm spec folder\"}"
            emit_task_change_question "$SPEC_FOLDER" "$DIVERGENCE_SCORE"

            # Set question flow state for handling response
            set_question_flow "task_change" "$SPEC_FOLDER" "[]" ""

            END_TIME=$(_get_nano_time)
            DURATION=$(((END_TIME - START_TIME)/1000000))
            echo "[$(date '+%Y-%m-%d %H:%M:%S')] enforce-spec-folder.sh ${DURATION}ms (task change question)" >> "$PERF_LOG"
            exit $EXIT_BLOCK  # BLOCK until user responds
          elif [ "$DIVERGENCE_SCORE" -gt 40 ] 2>/dev/null; then
            # Medium divergence - just log, don't block
            echo "💡 [enforce-spec-folder] Some topic drift detected (${DIVERGENCE_SCORE}%) - continuing in $SPEC_FOLDER_NAME" >&2
            log_event "TOPIC_DRIFT" "Medium divergence (${DIVERGENCE_SCORE}%) in $SPEC_FOLDER_NAME"
          fi
        fi
      fi
    fi

    # ─────────────────────────────────────────────────────────────
    # BUG FIX: Ask about spec folder BEFORE asking about memory
    # ─────────────────────────────────────────────────────────────
    # Previously, the hook would directly present memory options,
    # which conflated two separate decisions:
    #   1. Which spec folder to use? (A=existing, B=new, D=skip)
    #   2. Load previous context? (A=recent, B=all, C=select, D=skip)
    #
    # The fix: ALWAYS ask about spec folder first. Only ask about
    # memory loading AFTER user confirms they want to continue in
    # the existing spec folder (option A).
    # ─────────────────────────────────────────────────────────────

    # Check if memory files exist (to inform user in confirmation prompt)
    # Note: Using underscore-prefixed vars as we're in main script body, not a function
    _has_memory_files="false"
    _memory_dir=$(find_memory_directory "$SPEC_FOLDER" 2>/dev/null)
    if [ -n "$_memory_dir" ] && [ -d "$_memory_dir" ]; then
      _memory_count=$(find "$_memory_dir" -maxdepth 1 -type f -name "*__*.md" 2>/dev/null | wc -l | tr -d ' ')
      if [ "$_memory_count" -gt 0 ]; then
        _has_memory_files="true"
      fi
    fi

    # Find next spec number for option B
    if [ -d "$SPECS_DIR" ]; then
      _max_num=$(find "$SPECS_DIR" -maxdepth 1 -mindepth 1 -type d -name "[0-9][0-9][0-9]-*" 2>/dev/null | \
        sed 's/.*\/\([0-9][0-9][0-9]\)-.*/\1/' | sort -n | tail -1 || echo "000")
      _next_spec_number=$(printf "%03d" $((10#${_max_num:-0} + 1)))
    else
      _next_spec_number="001"
    fi

    # Emit spec folder CONFIRM question (NOT memory question)
    log_event "SPEC_CONFIRM_PROMPT" "Asking user to confirm spec folder: $SPEC_FOLDER_NAME"
    echo "" >&2
    echo "📂 [enforce-spec-folder] Detected active spec folder: $SPEC_FOLDER_NAME" >&2
    echo "   Asking for confirmation before proceeding..." >&2
    echo "" >&2

    # Build memory files JSON for flow state
    _memory_files_json="[]"
    if [ "$_has_memory_files" = "true" ] && [ -n "$_memory_dir" ]; then
      _files_array=""
      while IFS= read -r file; do
        if [ -n "$file" ]; then
          _filename=$(basename "$file")
          if [ -n "$_files_array" ]; then
            _files_array="$_files_array,"
          fi
          _files_array="$_files_array\"$_filename\""
        fi
      done < <(find "$_memory_dir" -maxdepth 1 -type f -name "*__*.md" 2>/dev/null | sort -r | head -5)
      if [ -n "$_files_array" ]; then
        _memory_files_json="[$_files_array]"
      fi
    fi

    # Emit the SPEC FOLDER CONFIRM question (stage 1b)
    echo "{\"systemMessage\": \"📁 Spec folder confirmation required - select A/B/D for: $SPEC_FOLDER_NAME\"}"
    emit_spec_folder_confirm_question "$SPEC_FOLDER" "$_next_spec_number" "$_has_memory_files"

    # Set flow state to spec_folder_confirm stage
    set_question_flow "spec_folder_confirm" "$SPEC_FOLDER" "$_memory_files_json" ""

    END_TIME=$(_get_nano_time)
    DURATION=$(((END_TIME - START_TIME)/1000000))
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] enforce-spec-folder.sh ${DURATION}ms (spec folder confirm question)" >> "$PERF_LOG"
    exit $EXIT_BLOCK  # BLOCK until user confirms spec folder (then ask about memory if applicable)
  fi

  # Empty or minimal content → Start of conversation, run validation
  if [ -z "$SPEC_FOLDER" ]; then
    if [ "$ENFORCEMENT_MODE" = "warning-only" ]; then
      handle_warning "No spec folders detected in specs/."
    else
      handle_confirmation "No spec folder detected" ""
      NEEDS_CONFIRMATION=true
    fi
  else
    SPEC_FOLDER_NAME=$(basename "$SPEC_FOLDER")
  fi
fi

if [ "$NEEDS_CONFIRMATION" = false ] && [ -n "$SPEC_FOLDER" ] && [ "$CHECK_TEMPLATES" != "false" ]; then
  if ! validate_templates "$SPEC_FOLDER"; then
    # Note: Can't use 'local' here as this is in main script body
    _joined_errors=""
    if [ ${#VALIDATION_ERRORS[@]} -gt 0 ] 2>/dev/null; then
      _joined_errors="$(printf '%s; ' "${VALIDATION_ERRORS[@]}")"
    fi
    if [ "$ENFORCEMENT_MODE" = "warning-only" ]; then
      handle_warning "$_joined_errors"
    else
      handle_confirmation "$_joined_errors" "$SPEC_FOLDER_NAME"
      NEEDS_CONFIRMATION=true
    fi
  fi
fi

# If confirmation was needed, BLOCK execution until user responds
# The PreToolUse/check-pending-questions.sh hook will also block tool usage
# until the pending_question state is cleared by AskUserQuestion
if [ "$NEEDS_CONFIRMATION" = true ]; then
  END_TIME=$(_get_nano_time)
  DURATION=$(((END_TIME - START_TIME)/1000000))
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] enforce-spec-folder.sh ${DURATION}ms (BLOCKING - confirmation needed)" >> "$PERF_LOG"
  log_event "BLOCKING" "Mandatory spec folder question pending - EXIT_BLOCK"
  exit $EXIT_BLOCK  # CRITICAL: Block until user responds to mandatory question
fi

log_event "ALLOWED" "Spec folder validated: ${SPEC_FOLDER_NAME:-n/a}"
echo "✅ [enforce-spec-folder] Spec folder validated: ${SPEC_FOLDER_NAME:-n/a}" >&2
END_TIME=$(_get_nano_time)
DURATION=$(((END_TIME - START_TIME)/1000000))
echo "[$(date '+%Y-%m-%d %H:%M:%S')] enforce-spec-folder.sh ${DURATION}ms (${SPEC_FOLDER_NAME:-no-spec})" >> "$PERF_LOG"
exit 0
