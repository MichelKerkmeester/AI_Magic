#!/bin/bash

# ───────────────────────────────────────────────────────────────
# TRACK-FILE-MODIFICATIONS.SH - File Drift Detection
# ───────────────────────────────────────────────────────────────
# PostToolUse hook that tracks Write/Edit operations for drift
# detection from the active spec folder scope.
#
# Version: 1.0.0
# Created: 2025-11-26
# Spec: specs/009-spec-enforcement/
#
# TRIGGERS: After Write, Edit tool completions (NOT Bash per user preference)
# OUTPUT: Advisory warning when task drift detected
# BLOCKING: No - advisory only (blocking is via pending questions)
#
# HYBRID APPROACH:
#   - Tracks Write/Edit file paths only
#   - Does NOT track Bash commands (per user preference)
#   - Complements keyword-based divergence detection
# ───────────────────────────────────────────────────────────────

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HOOKS_DIR="$(dirname "$SCRIPT_DIR")"
PROJECT_ROOT="$(dirname "$HOOKS_DIR")"
PROJECT_ROOT="${PROJECT_ROOT%/.claude}"
LOG_DIR="$HOOKS_DIR/logs"
LOG_FILE="$LOG_DIR/file-tracking.log"

mkdir -p "$LOG_DIR" 2>/dev/null

# Read tool input from stdin
INPUT=$(cat)

# Extract tool name
TOOL_NAME=$(echo "$INPUT" | jq -r '.tool_name // ""' 2>/dev/null)

# Only track Write/Edit (hybrid approach - not Bash per user preference)
case "$TOOL_NAME" in
  Write|Edit) ;;
  *) exit 0 ;;
esac

# Source required libraries
if [ -f "$HOOKS_DIR/lib/shared-state.sh" ]; then
  source "$HOOKS_DIR/lib/shared-state.sh"
else
  exit 0  # Can't track without state library
fi

if [ -f "$HOOKS_DIR/lib/file-scope-tracking.sh" ]; then
  source "$HOOKS_DIR/lib/file-scope-tracking.sh"
else
  exit 0  # Can't track without file-scope library
fi

# Extract file path from tool input
FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // .tool_input.filePath // ""' 2>/dev/null)

if [ -z "$FILE_PATH" ]; then
  exit 0  # No file path to track
fi

# Log the tracking
echo "[$(date '+%Y-%m-%d %H:%M:%S')] Tracking: $TOOL_NAME on $FILE_PATH" >> "$LOG_FILE" 2>/dev/null

# Track the modification and check for drift
drift_result=$(track_file_modification "$FILE_PATH" "$TOOL_NAME" 2>/dev/null) || drift_result=""

# Check if we should emit drift warning
if should_emit_drift_question 2>/dev/null; then
  # Get context for warning
  scope_def=$(read_hook_state "scope_definition" 3600 2>/dev/null) || scope_def='{}'
  spec_folder=$(echo "$scope_def" | jq -r '.spec_folder // "unknown"' 2>/dev/null)
  drift_score=$(calculate_file_drift_score 2>/dev/null) || drift_score=0

  # Log the drift detection
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] DRIFT DETECTED: score=$drift_score, folder=$spec_folder" >> "$LOG_FILE" 2>/dev/null

  # Emit advisory warning (non-blocking)
  echo ""
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "⚠️  TASK DRIFT DETECTED (Score: $drift_score)"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo ""
  echo "You're modifying files outside the active spec folder scope."
  echo "  Active spec: $spec_folder"
  echo "  Last file: $FILE_PATH"
  echo ""
  echo "If this is intentional cross-scope work, consider:"
  echo "  A) Creating a new spec folder for this work"
  echo "  B) Confirming with user this is expected"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  
  # Emit systemMessage for Claude Code visibility
  visible_msg=$(jq -n --arg msg "⚠️ TASK DRIFT (Score: $drift_score): Modifying files outside spec scope ($spec_folder). Create new spec or confirm intent." '{systemMessage: $msg}')
  echo "$visible_msg"

  # Mark that we warned (prevent spam)
  mark_drift_question_asked 2>/dev/null || true
fi

exit 0
