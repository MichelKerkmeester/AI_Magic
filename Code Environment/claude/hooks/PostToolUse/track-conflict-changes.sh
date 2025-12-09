#!/bin/bash

# ───────────────────────────────────────────────────────────────
# TRACK FILE CHANGES FOR CONFLICT DETECTION
# ───────────────────────────────────────────────────────────────
# PostToolUse hook that tracks Write/Edit tool completions for
# parallel agent conflict detection.
#
# TRIGGERS: After Write, Edit tool completions
# PURPOSE: Track modifications with agent context for conflict detection
# BLOCKING: No - tracking only
#
# Version: 1.0.0
# Created: 2025-12-06
# Spec: specs/013-speckit-enhancements-from-repo-reference/
# Tasks: T156-T157 (US-022)
#
# BEHAVIOR:
#   - Tracks file modifications by agent
#   - Stores in file_modifications.json
#   - Checks for immediate conflicts
#   - Emits warning for same-file conflicts
#
# PERFORMANCE TARGET: <20ms
# ───────────────────────────────────────────────────────────────

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" 2>/dev/null && pwd)"
HOOKS_DIR="$(cd "$SCRIPT_DIR/.." 2>/dev/null && pwd)"

# Logging
LOG_DIR="$HOOKS_DIR/logs"
LOG_FILE="$LOG_DIR/conflict-tracking.log"
mkdir -p "$LOG_DIR" 2>/dev/null

# ═══════════════════════════════════════════════════════════════
# READ INPUT
# ═══════════════════════════════════════════════════════════════

INPUT=$(cat)

# Extract tool name
TOOL_NAME=$(echo "$INPUT" | jq -r '.tool_name // ""' 2>/dev/null)

# Only track Write/Edit operations
case "$TOOL_NAME" in
  Write|Edit) ;;
  *) exit 0 ;;
esac

# ═══════════════════════════════════════════════════════════════
# LOAD CONFLICT DETECTION LIBRARY
# ═══════════════════════════════════════════════════════════════

if [ ! -f "$HOOKS_DIR/lib/conflict-detection.sh" ]; then
  # Library not available - skip silently
  exit 0
fi

source "$HOOKS_DIR/lib/conflict-detection.sh" 2>/dev/null || exit 0

# ═══════════════════════════════════════════════════════════════
# EXTRACT FILE MODIFICATION DETAILS
# ═══════════════════════════════════════════════════════════════

# Extract file path from tool input
FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // .tool_input.filePath // ""' 2>/dev/null)

if [ -z "$FILE_PATH" ]; then
  exit 0  # No file path to track
fi

# Extract agent context (if available from session)
AGENT_ID=$(echo "$INPUT" | jq -r '.agent_id // .session_id // "main"' 2>/dev/null)
SESSION_ID=$(echo "$INPUT" | jq -r '.session_id // ""' 2>/dev/null)

# If agent_id not explicit, derive from session or use main
if [ -z "$AGENT_ID" ] || [ "$AGENT_ID" = "null" ]; then
  if [ -n "$SESSION_ID" ]; then
    AGENT_ID="agent_${SESSION_ID:0:8}"
  else
    AGENT_ID="main"
  fi
fi

# Determine modification type based on tool
MODIFICATION_TYPE="edit"
if [ "$TOOL_NAME" = "Write" ]; then
  MODIFICATION_TYPE="write"
fi

# Try to extract line range for Edit operations
LINE_START=""
LINE_END=""
if [ "$TOOL_NAME" = "Edit" ]; then
  # Estimate line range from oldString/newString if available
  OLD_STRING=$(echo "$INPUT" | jq -r '.tool_input.oldString // ""' 2>/dev/null)
  if [ -n "$OLD_STRING" ]; then
    # Count lines in old string as an estimate
    LINE_COUNT=$(echo -n "$OLD_STRING" | wc -l | tr -d ' ')
    LINE_COUNT=$((LINE_COUNT + 1))
    # We don't know exact start line without reading file, leave empty
  fi
fi

# ═══════════════════════════════════════════════════════════════
# TRACK THE MODIFICATION
# ═══════════════════════════════════════════════════════════════

{
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] Tracking: $TOOL_NAME on $FILE_PATH by $AGENT_ID"
} >> "$LOG_FILE" 2>/dev/null

# Track the modification
if ! track_file_modification "$AGENT_ID" "$FILE_PATH" "$MODIFICATION_TYPE" "$LINE_START" "$LINE_END"; then
  {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] WARN: Failed to track modification"
  } >> "$LOG_FILE" 2>/dev/null
  exit 0
fi

# ═══════════════════════════════════════════════════════════════
# CHECK FOR IMMEDIATE CONFLICTS
# ═══════════════════════════════════════════════════════════════

# Get other agents that have modified this file
OTHER_MODIFIERS=$(get_file_modifiers "$FILE_PATH" 2>/dev/null | grep -v "^${AGENT_ID}$" || true)

if [ -n "$OTHER_MODIFIERS" ]; then
  # Other agents have modified this file - emit warning
  OTHER_COUNT=$(echo "$OTHER_MODIFIERS" | wc -l | tr -d ' ')
  OTHER_LIST=$(echo "$OTHER_MODIFIERS" | tr '\n' ',' | sed 's/,$//')
  
  {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] CONFLICT POTENTIAL: $FILE_PATH also modified by: $OTHER_LIST"
  } >> "$LOG_FILE" 2>/dev/null
  
  # Check for overlapping modifications
  OVERLAP=$(get_modification_overlap "$FILE_PATH" 2>/dev/null) || OVERLAP='{"has_overlap":false}'
  HAS_OVERLAP=$(echo "$OVERLAP" | jq -r '.has_overlap' 2>/dev/null) || HAS_OVERLAP="false"
  
  if [ "$HAS_OVERLAP" = "true" ]; then
    # Critical: overlapping line ranges
    WARNING_MSG="🚨 CRITICAL: Overlapping modifications detected in $FILE_PATH by agents: $OTHER_LIST, $AGENT_ID"
    jq -n --arg msg "$WARNING_MSG" '{systemMessage: $msg}'
    
    {
      echo "[$(date '+%Y-%m-%d %H:%M:%S')] CRITICAL: Overlapping lines in $FILE_PATH"
    } >> "$LOG_FILE" 2>/dev/null
  else
    # Warning: same file modified
    WARNING_MSG="⚠️ Same file ($FILE_PATH) modified by multiple agents: $OTHER_LIST, $AGENT_ID"
    jq -n --arg msg "$WARNING_MSG" '{systemMessage: $msg}'
  fi
fi

exit 0
