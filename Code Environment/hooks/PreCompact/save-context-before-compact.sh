#!/bin/bash

# ───────────────────────────────────────────────────────────────
# SAVE CONTEXT BEFORE COMPACTION
# ───────────────────────────────────────────────────────────────
# PreCompact hook that automatically saves conversation context
# before compaction operations (manual or automatic).
#
# Version: 1.0.1
# Created: 2025-11-24
#
# PERFORMANCE TARGET: <5s (Node.js script execution)
# COMPATIBILITY: Bash 3.2+ (macOS and Linux compatible)
#
# EXECUTION ORDER: PreCompact hook (runs BEFORE compaction)
#   Fires when: User manually compacts OR auto-compact threshold reached
#   Cannot block: Compaction proceeds regardless of exit code
#   Purpose: Backup transcript before context loss
#
# EXIT CODE CONVENTION:
#   0 = Success (transcript saved)
#   1 = Warning (partial success or skipped)
#   2 = Error (reserved for critical failures, does not block)
# ───────────────────────────────────────────────────────────────

# Source output helpers and exit codes
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" 2>/dev/null && pwd)"
HOOKS_DIR="$(cd "$SCRIPT_DIR/.." 2>/dev/null && pwd)"

source "$HOOKS_DIR/lib/output-helpers.sh" || exit 0
source "$HOOKS_DIR/lib/exit-codes.sh" || exit 0

# Cross-platform nanosecond timing helper (Bash 3.2 compatible)
_get_nano_time() {
  if [[ "$OSTYPE" == "darwin"* ]]; then
    # macOS: no nanoseconds, use seconds * 1 billion
    echo $(($(date +%s) * 1000000000))
  else
    # Linux: use nanoseconds with fallback
    date +%s%N 2>/dev/null || echo $(($(date +%s) * 1000000000))
  fi
}

# Performance timing START
START_TIME=$(_get_nano_time)

# ───────────────────────────────────────────────────────────────
# DEPENDENCY CHECKS
# ───────────────────────────────────────────────────────────────

# Check dependencies (silent on success, graceful degradation on failure)
if ! check_dependency "jq" "brew install jq (macOS) or apt install jq (Linux)"; then
  echo "   ⚠️  PreCompact save skipped: jq not available" >&2
  exit $EXIT_ALLOW  # Allow compaction to proceed
fi

if ! check_dependency "node" "Install from https://nodejs.org/"; then
  echo "   ⚠️  PreCompact save skipped: Node.js not available" >&2
  exit $EXIT_ALLOW  # Allow compaction to proceed
fi

# ───────────────────────────────────────────────────────────────
# PARSE JSON PAYLOAD
# ───────────────────────────────────────────────────────────────

# Read JSON input from stdin
INPUT=$(cat)

# Extract payload fields (silent on error)
TRIGGER=$(echo "$INPUT" | jq -r '.trigger // "auto"' 2>/dev/null)
CUSTOM_INSTRUCTIONS=$(echo "$INPUT" | jq -r '.custom_instructions // empty' 2>/dev/null)
SESSION_ID=$(echo "$INPUT" | jq -r '.session_id // empty' 2>/dev/null)
CWD=$(echo "$INPUT" | jq -r '.cwd // empty' 2>/dev/null)

# Security: Sanitize SESSION_ID (allow only alphanumeric, dash, underscore)
if [ -n "$SESSION_ID" ]; then
  SESSION_ID=$(echo "$SESSION_ID" | tr -cd 'a-zA-Z0-9_-')
fi

# Validate required fields
if [ -z "$SESSION_ID" ]; then
  echo "   ⚠️  PreCompact save skipped: Session ID not available" >&2
  exit $EXIT_ALLOW
fi

if [ -z "$CWD" ] || [ ! -d "$CWD" ]; then
  echo "   ⚠️  PreCompact save skipped: Invalid working directory" >&2
  exit $EXIT_ALLOW
fi

# ───────────────────────────────────────────────────────────────
# DISPLAY TRIGGER NOTIFICATION
# ───────────────────────────────────────────────────────────────

if [ "$TRIGGER" = "manual" ]; then
  echo "💾 Saving context before compaction (manual trigger)..."
  if [ -n "$CUSTOM_INSTRUCTIONS" ]; then
    echo "   📝 Custom instructions: ${CUSTOM_INSTRUCTIONS:0:80}..."
  fi
else
  echo "💾 Saving context before compaction (auto-compact threshold reached)..."
fi

# ───────────────────────────────────────────────────────────────
# LOCATE TRANSCRIPT FILE
# ───────────────────────────────────────────────────────────────

# Validate CWD path (security: prevent path traversal)
SAFE_CWD=$(realpath "$CWD" 2>/dev/null || echo "$CWD")
if [ ! -d "$SAFE_CWD" ]; then
  echo "   ⚠️  Cannot save: Invalid working directory" >&2
  exit $EXIT_ALLOW
fi

# Convert path to Claude project slug format
# Format: /Users/name/project → -Users-name-project
# Security: Only allow alphanumeric, dash, underscore in slug
PROJECT_SLUG=$(echo "$SAFE_CWD" | sed 's|^/|-|' | sed 's|/|-|g' | sed 's|\.|-|g' | sed 's|[^a-zA-Z0-9_-]||g')
TRANSCRIPT_DIR="$HOME/.claude/projects/$PROJECT_SLUG"

# Find transcript file
TRANSCRIPT_PATH=$(find "$TRANSCRIPT_DIR" -name "${SESSION_ID}.jsonl" 2>/dev/null | head -1)

if [ -z "$TRANSCRIPT_PATH" ] || [ ! -f "$TRANSCRIPT_PATH" ]; then
  echo "   ⚠️  Cannot save: Transcript file not found" >&2
  echo "   Expected: $TRANSCRIPT_DIR/${SESSION_ID}.jsonl" >&2
  exit $EXIT_ALLOW
fi

echo "   📂 Found transcript: $(basename "$TRANSCRIPT_PATH")"

# ───────────────────────────────────────────────────────────────
# LOCATE SPEC FOLDER
# ───────────────────────────────────────────────────────────────

# Check if project has specs/ folder
if [ ! -d "$CWD/specs" ]; then
  echo "   ⚠️  Auto-save skipped: No spec folder found" >&2
  echo "   Create spec folder: mkdir -p specs/###-name/" >&2
  exit $EXIT_ALLOW
fi

# Find most recent spec folder (exclude archives)
SPEC_FOLDER=$(find "$CWD/specs" -maxdepth 1 -type d -name "[0-9][0-9][0-9]-*" 2>/dev/null | \
  grep -viE '/(z_|.*archive.*|.*old.*|.*\.archived.*)$' | \
  sort -r | head -1)

if [ -z "$SPEC_FOLDER" ]; then
  echo "   ⚠️  Auto-save skipped: No spec folder found" >&2
  echo "   Create spec folder: mkdir -p specs/###-name/" >&2
  exit $EXIT_ALLOW
fi

SPEC_NAME=$(basename "$SPEC_FOLDER")
echo "   📁 Target spec: $SPEC_NAME"

# ───────────────────────────────────────────────────────────────
# SUB-FOLDER VERSIONING SUPPORT
# ───────────────────────────────────────────────────────────────
# Check for .spec-active marker for sub-folder routing

CONTEXT_DIR="$SPEC_FOLDER/memory"
SPEC_TARGET="$SPEC_NAME"

# Check for active sub-folder marker (V9: session-aware markers)
# Try session-specific marker first, then fall back to global marker
SPEC_ACTIVE_MARKER=""
if [ -n "$SESSION_ID" ] && [ -f "$CWD/.claude/.spec-active.${SESSION_ID}" ]; then
  SPEC_ACTIVE_MARKER="$CWD/.claude/.spec-active.${SESSION_ID}"
elif [ -f "$CWD/.claude/.spec-active" ]; then
  SPEC_ACTIVE_MARKER="$CWD/.claude/.spec-active"
fi

if [ -n "$SPEC_ACTIVE_MARKER" ] && [ -f "$SPEC_ACTIVE_MARKER" ]; then
  ACTIVE_PATH=$(cat "$SPEC_ACTIVE_MARKER" 2>/dev/null | tr -d '\n\r')
  
  # Handle JSON format markers (V9 fingerprint format)
  if echo "$ACTIVE_PATH" | grep -q '^{'; then
    ACTIVE_PATH=$(echo "$ACTIVE_PATH" | jq -r '.path // empty' 2>/dev/null)
  fi

  # Normalize paths for comparison (marker may be relative, SPEC_FOLDER is absolute)
  if [ -n "$ACTIVE_PATH" ]; then
    # If ACTIVE_PATH is relative, make it absolute
    if [[ "$ACTIVE_PATH" != /* ]]; then
      ACTIVE_PATH="$CWD/$ACTIVE_PATH"
    fi
    
    # Verify active path exists and is within current spec folder
    if [ -d "$ACTIVE_PATH" ]; then
      # Use realpath for reliable comparison
      ACTIVE_REAL=$(realpath "$ACTIVE_PATH" 2>/dev/null || echo "$ACTIVE_PATH")
      SPEC_REAL=$(realpath "$SPEC_FOLDER" 2>/dev/null || echo "$SPEC_FOLDER")
      
      if [[ "$ACTIVE_REAL" == "$SPEC_REAL"/* ]]; then
        CONTEXT_DIR="$ACTIVE_PATH/memory"
        ACTIVE_SUBFOLDER=$(basename "$ACTIVE_PATH")
        SPEC_TARGET="$SPEC_NAME/$ACTIVE_SUBFOLDER"
        echo "   📂 Using active sub-folder: $ACTIVE_SUBFOLDER"
      fi
    else
      # Stale marker - cleanup
      echo "   🧹 Cleaning up stale marker: $(basename "$SPEC_ACTIVE_MARKER")"
      rm -f "$SPEC_ACTIVE_MARKER"
    fi
  fi
fi

# Create memory directory
mkdir -p "$CONTEXT_DIR"

# ───────────────────────────────────────────────────────────────
# TRANSFORM TRANSCRIPT
# ───────────────────────────────────────────────────────────────

# Create temporary file for transformed JSON
TEMP_JSON="/tmp/precompact-context-${SESSION_ID}.json"

# Get path to transformer script
TRANSFORMER="$HOOKS_DIR/lib/transform-transcript.js"

if [ ! -f "$TRANSFORMER" ]; then
  echo "   ⚠️  Cannot save: Transform script not found" >&2
  echo "   Expected: $TRANSFORMER" >&2
  exit $EXIT_ALLOW
fi

# Transform transcript JSONL → JSON (capture errors)
NODE_OUTPUT=$(node "$TRANSFORMER" "$TRANSCRIPT_PATH" "$TEMP_JSON" 2>&1)
NODE_EXIT=$?

if [ $NODE_EXIT -ne 0 ] || [ ! -f "$TEMP_JSON" ]; then
  echo "   ⚠️  Transform failed: ${NODE_OUTPUT:0:100}" >&2
  rm -f "$TEMP_JSON"
  exit $EXIT_ALLOW
fi

echo "   ✅ Transcript transformed to JSON"

# ───────────────────────────────────────────────────────────────
# GENERATE CONTEXT FILE
# ───────────────────────────────────────────────────────────────

# Change to project directory
cd "$CWD" || {
  rm -f "$TEMP_JSON"
  echo "   ⚠️  Cannot save: Failed to change directory" >&2
  exit $EXIT_ALLOW
}

# Locate save-context script
SAVE_CONTEXT_SCRIPT="$HOOKS_DIR/../skills/workflows-save-context/scripts/generate-context.js"

if [ ! -f "$SAVE_CONTEXT_SCRIPT" ]; then
  echo "   ⚠️  Cannot save: workflows-save-context script not found" >&2
  echo "   Expected: $SAVE_CONTEXT_SCRIPT" >&2
  rm -f "$TEMP_JSON"
  exit $EXIT_ALLOW
fi

# Execute save-context script with timeout
# Pass SPEC_TARGET (either "###-name" or "###-name/###-subfolder")
# Run in AUTO_SAVE_MODE to bypass alignment prompts
# NOTE: ENV_VAR must precede command, not follow timeout
if command -v timeout >/dev/null 2>&1; then
  NODE_OUTPUT=$(AUTO_SAVE_MODE=true timeout 30 node "$SAVE_CONTEXT_SCRIPT" "$TEMP_JSON" "$SPEC_TARGET" 2>&1)
else
  NODE_OUTPUT=$(AUTO_SAVE_MODE=true node "$SAVE_CONTEXT_SCRIPT" "$TEMP_JSON" "$SPEC_TARGET" 2>&1)
fi
EXIT_CODE=$?

# Clean up temporary file
rm -f "$TEMP_JSON"

# ───────────────────────────────────────────────────────────────
# DISPLAY RESULT
# ───────────────────────────────────────────────────────────────

if [ $EXIT_CODE -eq 0 ]; then
  # Show relative path from CWD for clarity
  REL_PATH=$(echo "$CONTEXT_DIR" | sed "s|^$CWD/||")
  echo "   ✅ Context saved to: $REL_PATH/"
  echo "   🎯 Compaction can proceed"
else
  echo "   ⚠️  Save failed (exit code: $EXIT_CODE)" >&2
  if [ -n "$NODE_OUTPUT" ]; then
    echo "   Error: ${NODE_OUTPUT:0:200}" >&2
  fi
fi

# ───────────────────────────────────────────────────────────────
# LOGGING
# ───────────────────────────────────────────────────────────────

LOG_DIR="$HOOKS_DIR/logs"
mkdir -p "$LOG_DIR"
LOG_FILE="$LOG_DIR/precompact.log"

# Rotate log if needed (100KB limit)
rotate_log_if_needed "$LOG_FILE" 102400

TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')

{
  echo ""
  echo "───────────────────────────────────────────────────────────────"
  echo "[$TIMESTAMP] PRECOMPACT SAVE TRIGGERED"
  echo "───────────────────────────────────────────────────────────────"
  echo "Trigger: $TRIGGER"
  if [ "$TRIGGER" = "manual" ] && [ -n "$CUSTOM_INSTRUCTIONS" ]; then
    echo "Custom Instructions: ${CUSTOM_INSTRUCTIONS:0:200}"
  fi
  echo "Session: $SESSION_ID"
  echo "Spec Target: $SPEC_TARGET"
  echo "Context Dir: $CONTEXT_DIR"
  echo "Exit Code: $EXIT_CODE"
  if [ $EXIT_CODE -eq 0 ]; then
    echo "Status: ✅ Success"
  else
    echo "Status: ⚠️  Failed"
  fi
  echo "───────────────────────────────────────────────────────────────"
  echo ""
} >> "$LOG_FILE"

# Performance timing END
END_TIME=$(_get_nano_time)
DURATION=$(( (END_TIME - START_TIME) / 1000000 ))
echo "[$(date '+%Y-%m-%d %H:%M:%S')] save-context-before-compact.sh ${DURATION}ms" >> "$LOG_DIR/performance.log"

# Always allow compaction to proceed (PreCompact cannot block)
exit $EXIT_ALLOW
