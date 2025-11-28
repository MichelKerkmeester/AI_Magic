#!/bin/bash

# ───────────────────────────────────────────────────────────────
# AUTO SAVE-CONTEXT TRIGGER
# ───────────────────────────────────────────────────────────────
# UserPromptSubmit hook that automatically saves conversation
# context via TWO triggering methods:
#   1. Keyword detection (e.g., "save context", "save conversation")
#   2. Context window threshold (75% used, 25% remaining = 200 messages)
#
# Version: 1.3.0
# Last Updated: 2025-11-09
#
# PERFORMANCE TARGET: 2-5s (external Node.js script execution)
# COMPATIBILITY: Bash 3.2+ (macOS and Linux compatible)
#
# EXECUTION ORDER: UserPromptSubmit hook (runs BEFORE user prompt processing)
#   1. UserPromptSubmit hooks run FIRST (before processing user input)
#   2. PreToolUse hooks run SECOND (before tool execution, validation)
#   3. PostToolUse hooks run LAST (after tool completion, verification)
#   This hook: Auto-saves conversation context via keywords or threshold
#
# EXIT CODE CONVENTION:
#   0 = Allow (hook passed, continue execution)
#   1 = Block (hook failed, stop execution with warning)
#   2 = Error (reserved for critical failures)
# ───────────────────────────────────────────────────────────────

# Source output helpers (completely silent on success)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" 2>/dev/null && pwd)"
HOOKS_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
source "$SCRIPT_DIR/../lib/output-helpers.sh" || exit 0

# V9: Source spec-context for session-aware marker paths
source "$HOOKS_DIR/lib/spec-context.sh" 2>/dev/null || true

# Performance timing START
START_TIME=$(date +%s%N)

# Check dependencies (silent on success)
check_dependency "jq" "brew install jq (macOS) or apt install jq (Linux)" || exit 0
check_dependency "node" "Install from https://nodejs.org/" || exit 0

# Read JSON input from stdin
INPUT=$(cat)

# Extract the prompt from JSON (silent on error)
PROMPT=$(echo "$INPUT" | jq -r '.prompt // empty' 2>/dev/null)

# Extract session metadata (silent on error)
SESSION_ID=$(echo "$INPUT" | jq -r '.session_id // empty' 2>/dev/null)
CWD=$(echo "$INPUT" | jq -r '.cwd // empty' 2>/dev/null)

# ───────────────────────────────────────────────────────────────
# SECURITY: Sanitize SESSION_ID to prevent shell injection
# ───────────────────────────────────────────────────────────────
# SESSION_ID is used in find commands later. Sanitize to allow only
# alphanumeric characters, dash, and underscore (safe for shell)
if [ -n "$SESSION_ID" ]; then
  SESSION_ID=$(echo "$SESSION_ID" | tr -cd 'a-zA-Z0-9_-')
fi

# If no prompt found, allow it silently
if [ -z "$PROMPT" ]; then
  exit 0
fi

# Convert prompt to lowercase for case-insensitive matching
PROMPT_LOWER=$(echo "$PROMPT" | tr '[:upper:]' '[:lower:]')

# ───────────────────────────────────────────────────────────────
# KEYWORD DETECTION
# ───────────────────────────────────────────────────────────────

# Define keywords that trigger auto-save
TRIGGER_KEYWORDS=(
  "save context"
  "save conversation"
  "save session"
  "export conversation"
  "preserve context"
  "capture context"
  "export context"
  "save memory"
  "preserve memory"
  "document conversation"
  "document session"
  "save chat"
  "export session"
  "document this"
  "record this"
  "write this down"
  "store this"
  "backup conversation"
)

# Check if any keyword matches
TRIGGERED=false
MATCHED_KEYWORD=""
TRIGGER_REASON=""

for keyword in "${TRIGGER_KEYWORDS[@]}"; do
  if echo "$PROMPT_LOWER" | grep -qE "\\b${keyword}\\b"; then
    TRIGGERED=true
    MATCHED_KEYWORD="$keyword"
    TRIGGER_REASON="keyword"
    break
  fi
done

# ───────────────────────────────────────────────────────────────
# CONTEXT WINDOW DETECTION (Every 20 messages)
# ───────────────────────────────────────────────────────────────
# NOTE: This is the PRIMARY auto-save mechanism, triggered
# automatically every 20 messages for frequent context preservation.
# ───────────────────────────────────────────────────────────────

if [ "$TRIGGERED" = false ] && [ -n "$SESSION_ID" ]; then
  # Try to find transcript in standard location using same slug logic as below
  SAFE_CWD_THRESHOLD=$(realpath "$CWD" 2>/dev/null || echo "$CWD")
  PROJECT_SLUG=$(echo "$SAFE_CWD_THRESHOLD" | sed 's|^/|-|' | sed 's|/|-|g' | sed 's|\.|-|g' | sed 's|[^a-zA-Z0-9_-]||g')
  TRANSCRIPT_DIR="$HOME/.claude/projects/$PROJECT_SLUG"
  TRANSCRIPT_PATH=$(find "$TRANSCRIPT_DIR" -name "${SESSION_ID}.jsonl" 2>/dev/null | head -1)

  if [ -f "$TRANSCRIPT_PATH" ]; then
    # Count messages in transcript (each line is a message)
    MESSAGE_COUNT=$(wc -l < "$TRANSCRIPT_PATH" 2>/dev/null | tr -d ' ')

    # Context window thresholds
    # Auto-save every 20 messages for frequent preservation
    CONTEXT_THRESHOLD=20

    # Check if we're at a 20-message interval (20, 40, 60, 80...)
    if [ "$MESSAGE_COUNT" -ge "$CONTEXT_THRESHOLD" ]; then
      REMAINDER=$((MESSAGE_COUNT % CONTEXT_THRESHOLD))
      if [ "$REMAINDER" -eq 0 ]; then
        TRIGGERED=true
        TRIGGER_REASON="context-window"
        MATCHED_KEYWORD="automatic (20-message interval)"
      fi
    fi
  fi
fi

# If not triggered, allow prompt to proceed
if [ "$TRIGGERED" = false ]; then
  exit 0
fi

# Display trigger notification immediately (before validation that might fail)
if [ "$TRIGGER_REASON" = "keyword" ]; then
  echo "💾 Auto-saving context (keyword: '$MATCHED_KEYWORD' detected)..."
else
  echo "💾 Auto-saving context (message $MESSAGE_COUNT - saving every 20 messages)..."
fi

# ───────────────────────────────────────────────────────────────
# FIND TRANSCRIPT AND VALIDATE ENVIRONMENT
# ───────────────────────────────────────────────────────────────

# Construct transcript path from session ID
if [ -z "$SESSION_ID" ]; then
  echo "   ⚠️  Cannot save: Session ID not available"
  exit 0
fi

# Validate CWD path (security: prevent path traversal)
SAFE_CWD=$(realpath "$CWD" 2>/dev/null || echo "$CWD")
if [ ! -d "$SAFE_CWD" ]; then
  echo "   ⚠️  Cannot save: Invalid working directory"
  exit 0
fi

# Try to find transcript in standard location
# Convert path to Claude project slug format: add leading dash, replace / and . with -
# Security: Only allow alphanumeric, dash, underscore in slug
PROJECT_SLUG=$(echo "$SAFE_CWD" | sed 's|^/|-|' | sed 's|/|-|g' | sed 's|\.|-|g' | sed 's|[^a-zA-Z0-9_-]||g')
TRANSCRIPT_DIR="$HOME/.claude/projects/$PROJECT_SLUG"

# Find most recent transcript (in case of reconnection)
TRANSCRIPT_PATH=$(find "$TRANSCRIPT_DIR" -name "${SESSION_ID}.jsonl" 2>/dev/null | head -1)

if [ -z "$TRANSCRIPT_PATH" ] || [ ! -f "$TRANSCRIPT_PATH" ]; then
  echo "   ⚠️  Cannot save: Transcript file not found"
  exit 0
fi

# ───────────────────────────────────────────────────────────────
# FIND TARGET SPEC FOLDER (MANDATORY)
# ───────────────────────────────────────────────────────────────
# BUG FIX: Check .spec-active marker FIRST before top-level detection
# This supports nested spec folder structures like:
#   specs/001-skills-and-hooks/043-save-context-filtering/

# Check if project has specs/ folder
if [ ! -d "$CWD/specs" ]; then
  echo "   ⚠️  Auto-save skipped: No spec folder found"
  echo "   Create spec folder to enable auto-save: mkdir -p specs/###-name/"
  exit 0
fi

# Initialize variables
SPEC_FOLDER=""
CONTEXT_DIR=""
SPEC_TARGET=""
ACTIVE_SUBFOLDER=""

# ───────────────────────────────────────────────────────────────
# STEP 1: Check .spec-active marker FIRST (supports nested folders)
# V9: Use session-aware marker path for multi-session isolation
# ───────────────────────────────────────────────────────────────
SPEC_ACTIVE_MARKER="$CWD/$(get_spec_marker_path "$SESSION_ID")"

if [ -f "$SPEC_ACTIVE_MARKER" ]; then
  ACTIVE_PATH=$(cat "$SPEC_ACTIVE_MARKER" 2>/dev/null | tr -d '\n\r')

  # Handle both relative (specs/...) and absolute paths
  if [[ "$ACTIVE_PATH" != /* ]]; then
    # Relative path - prepend CWD
    ACTIVE_PATH="$CWD/$ACTIVE_PATH"
  fi

  if [ -n "$ACTIVE_PATH" ] && [ -d "$ACTIVE_PATH" ]; then
    # Verify it's within specs/ folder (security check)
    CANON_SPECS=$(realpath "$CWD/specs" 2>/dev/null || echo "$CWD/specs")
    CANON_ACTIVE=$(realpath "$ACTIVE_PATH" 2>/dev/null || echo "$ACTIVE_PATH")

    if [[ "$CANON_ACTIVE" == "$CANON_SPECS"/* ]]; then
      SPEC_FOLDER="$ACTIVE_PATH"
      CONTEXT_DIR="$ACTIVE_PATH/memory"
      # Extract relative path from specs/ for SPEC_TARGET
      SPEC_TARGET="${CANON_ACTIVE#$CANON_SPECS/}"
      echo "   📂 Using active spec folder: $SPEC_TARGET"
    else
      echo "   ⚠️  .spec-active points outside specs/ - ignoring"
    fi
  else
    # Stale marker - cleanup
    echo "   🧹 Cleaning up stale .spec-active marker"
    rm -f "$SPEC_ACTIVE_MARKER"
  fi
fi

# ───────────────────────────────────────────────────────────────
# STEP 2: Fall back to top-level detection if no marker
# ───────────────────────────────────────────────────────────────
if [ -z "$SPEC_FOLDER" ]; then
  # Find most recent top-level spec folder (exclude archive folders)
  SPEC_FOLDER=$(find "$CWD/specs" -maxdepth 1 -type d -name "[0-9][0-9][0-9]-*" 2>/dev/null | \
    grep -viE '/(z_|.*archive.*|.*old.*|.*\.archived.*)$' | \
    sort -r | head -1)

  if [ -z "$SPEC_FOLDER" ]; then
    echo "   ⚠️  Auto-save skipped: No spec folder found"
    echo "   Create spec folder to enable auto-save: mkdir -p specs/###-name/"
    exit 0
  fi

  CONTEXT_DIR="$SPEC_FOLDER/memory"
  SPEC_TARGET="$(basename "$SPEC_FOLDER")"
fi

# Create memory directory
mkdir -p "$CONTEXT_DIR"

# ───────────────────────────────────────────────────────────────
# PARALLEL EXECUTION DETECTION
# ───────────────────────────────────────────────────────────────

# Check if parallel execution is available
# NOTE: Parallel execution via Task tool is environment-specific
# We attempt to detect it, but default to synchronous save
PARALLEL_AVAILABLE=false

# Try to detect if we're in an OpenCode environment with Task tool support
# This is done by checking for specific environment markers
# For now, we default to synchronous (future enhancement)
# PARALLEL_AVAILABLE=true  # Uncomment when Task tool integration ready

# ───────────────────────────────────────────────────────────────
# TRANSFORM AND SAVE
# ───────────────────────────────────────────────────────────────

# Create secure temporary file with proper cleanup
TEMP_JSON=$(mktemp "/tmp/save-context-XXXXXX.json" 2>/dev/null || echo "/tmp/save-context-keyword-${SESSION_ID}.json")
trap 'rm -f "$TEMP_JSON"' EXIT

# Get path to transformer script
HOOK_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TRANSFORMER="$HOOK_DIR/../lib/transform-transcript.js"

if [ ! -f "$TRANSFORMER" ]; then
  echo "   ⚠️  Cannot save: Transform script not found"
  exit 0
fi

# Transform transcript (capture errors)
NODE_OUTPUT=$(node "$TRANSFORMER" "$TRANSCRIPT_PATH" "$TEMP_JSON" 2>&1)
NODE_EXIT=$?

if [ $NODE_EXIT -ne 0 ] || [ ! -f "$TEMP_JSON" ]; then
  echo "   ⚠️  Transform failed: ${NODE_OUTPUT:0:100}"
  rm -f "$TEMP_JSON"
  exit 0
fi

# Change to project directory
cd "$CWD" || {
  rm -f "$TEMP_JSON"
  exit 0  # Silently exit
}

# Check if workflows-save-context skill exists
# Calculate path relative to hooks directory for portability
SAVE_CONTEXT_SCRIPT="${HOOKS_DIR}/../skills/workflows-save-context/scripts/generate-context.js"

if [ ! -f "$SAVE_CONTEXT_SCRIPT" ]; then
  echo "   ⚠️  Cannot save: workflows-save-context script not found at: $SAVE_CONTEXT_SCRIPT"
  echo "   Expected location: .claude/skills/workflows-save-context/scripts/generate-context.js"
  rm -f "$TEMP_JSON"
  exit 0  # Graceful degradation
fi

# ───────────────────────────────────────────────────────────────
# EXECUTE SAVE (SYNCHRONOUS ONLY)
# ───────────────────────────────────────────────────────────────
# PERFORMANCE NOTE: Auto-save executes synchronously (2-5 seconds)
# This blocks conversation flow but ensures context is saved before continuing
# Future enhancement: Move to background Task tool execution

EXIT_CODE=0

# Execute synchronously with timeout (blocking)
# Run in auto-save mode (bypasses alignment prompts)
# Pass spec target as second argument (parent or parent/subfolder)
# This routes context to correct memory/ directory (sub-folder aware)
# BUG FIX: ENV_VAR=value must come BEFORE command, not after timeout
if command -v timeout >/dev/null 2>&1; then
  NODE_OUTPUT=$(AUTO_SAVE_MODE=true timeout 30 node "$SAVE_CONTEXT_SCRIPT" "$TEMP_JSON" "$SPEC_TARGET" 2>&1)
else
  NODE_OUTPUT=$(AUTO_SAVE_MODE=true node "$SAVE_CONTEXT_SCRIPT" "$TEMP_JSON" "$SPEC_TARGET" 2>&1)
fi
EXIT_CODE=$?

# Clean up
rm -f "$TEMP_JSON"

# ───────────────────────────────────────────────────────────────
# DISPLAY CONFIRMATION TO USER
# ───────────────────────────────────────────────────────────────

# Display completion status to user
# Synchronous execution - show result immediately
if [ $EXIT_CODE -eq 0 ]; then
    # Show relative path from CWD for clarity
    REL_PATH=$(echo "$CONTEXT_DIR" | sed "s|^$CWD/||")
    echo "   ✅ Context saved to: $REL_PATH/"
else
  echo "   ⚠️  Save failed (exit code: $EXIT_CODE)"
  # Show actual error from generate-context.js (first 200 chars)
  if [ -n "$NODE_OUTPUT" ]; then
    echo "   Error: ${NODE_OUTPUT:0:200}"
  fi
fi

# ───────────────────────────────────────────────────────────────
# LOG DETAILED INFO TO FILE
# ───────────────────────────────────────────────────────────────

# Log result to file
HOOKS_DIR="$(cd "$SCRIPT_DIR/.." 2>/dev/null && pwd)"
LOG_DIR="$HOOKS_DIR/logs"
mkdir -p "$LOG_DIR"
LOG_FILE="$LOG_DIR/$(basename "$0" .sh).log"

TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')

{
  echo ""
  echo "───────────────────────────────────────────────────────────────"
  echo "[$TIMESTAMP] AUTO-SAVE TRIGGERED"
  echo "───────────────────────────────────────────────────────────────"
  echo "Trigger: $TRIGGER_REASON"
  if [ "$TRIGGER_REASON" = "keyword" ]; then
    echo "Keyword: '$MATCHED_KEYWORD'"
  elif [ "$TRIGGER_REASON" = "context-window" ]; then
    echo "Reason: 20-message interval reached ($MESSAGE_COUNT messages)"
    echo "Threshold: $CONTEXT_THRESHOLD messages"
  fi
  echo "Execution: $([ "$PARALLEL_AVAILABLE" = true ] && echo "Parallel (non-blocking)" || echo "Synchronous")"
  echo "Session: $SESSION_ID"
  echo "Target: $SPEC_TARGET/memory/"
  echo "Exit Code: $EXIT_CODE"
  if [ $EXIT_CODE -eq 0 ]; then
    echo "Status: ✅ Success"
  else
    echo "Status: ⚠️  Completed with warnings"
    if [ -n "$NODE_OUTPUT" ]; then
      echo "Error Output:"
      echo "$NODE_OUTPUT"
    fi
  fi
  echo "───────────────────────────────────────────────────────────────"
  echo ""
} >> "$LOG_FILE"

# Performance timing END
END_TIME=$(date +%s%N)
DURATION=$(( (END_TIME - START_TIME) / 1000000 ))
# Ensure log directory exists
[ -d "$HOOKS_DIR/logs" ] || mkdir -p "$HOOKS_DIR/logs" 2>/dev/null
echo "[$(date '+%Y-%m-%d %H:%M:%S')] save-context-trigger.sh ${DURATION}ms" >> "$HOOKS_DIR/logs/performance.log"

# Allow prompt to proceed to Claude (silently)
exit 0
