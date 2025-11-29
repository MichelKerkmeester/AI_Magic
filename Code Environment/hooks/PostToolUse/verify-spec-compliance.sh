#!/bin/bash

# ───────────────────────────────────────────────────────────────
# VERIFY-SPEC-COMPLIANCE.SH - Spec Folder Compliance Check
# ───────────────────────────────────────────────────────────────
# PostToolUse hook that warns when files are modified without
# an active spec folder. Advisory only (not blocking).
#
# Version: 1.0.0
# Created: 2025-11-26
# Spec: specs/009-spec-enforcement/
#
# TRIGGERS: After Write, Edit tool completions
# OUTPUT: Warning when no active spec folder
# BLOCKING: No - advisory only
#
# RATIONALE:
#   Per CLAUDE.md Section 2: Every conversation that modifies
#   files MUST have a spec folder. This hook provides visibility
#   into compliance violations without blocking workflow.
# ───────────────────────────────────────────────────────────────

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HOOKS_DIR="$(dirname "$SCRIPT_DIR")"
PROJECT_ROOT="$(dirname "$HOOKS_DIR")"
PROJECT_ROOT="${PROJECT_ROOT%/.claude}"
LOG_DIR="$HOOKS_DIR/logs"
LOG_FILE="$LOG_DIR/compliance.log"

mkdir -p "$LOG_DIR" 2>/dev/null

# Read tool input from stdin
INPUT=$(cat)

# Extract tool name
TOOL_NAME=$(echo "$INPUT" | jq -r '.tool_name // ""' 2>/dev/null)

# Only check file modification tools
case "$TOOL_NAME" in
  Write|Edit) ;;
  *) exit 0 ;;
esac

# Source shared state library
if [ -f "$HOOKS_DIR/lib/shared-state.sh" ]; then
  source "$HOOKS_DIR/lib/shared-state.sh"
fi

# V9: Source spec-context for session-aware marker paths
if [ -f "$HOOKS_DIR/lib/spec-context.sh" ]; then
  source "$HOOKS_DIR/lib/spec-context.sh"
fi

# V9: Extract SESSION_ID for session-isolated markers
SESSION_ID=$(echo "$INPUT" | jq -r '.session_id // empty' 2>/dev/null)
if [ -n "$SESSION_ID" ]; then
  SESSION_ID=$(echo "$SESSION_ID" | tr -cd 'a-zA-Z0-9_-')
fi

# Check if spec folder is active (V9: session-aware)
SPEC_MARKER=$(get_spec_marker_path "$SESSION_ID")
SKIP_MARKER=".claude/.spec-skip"

# If user explicitly skipped documentation, respect that choice
if [ -f "$SKIP_MARKER" ]; then
  exit 0
fi

# If spec folder marker exists, all good
if [ -f "$SPEC_MARKER" ]; then
  exit 0
fi

# Extract file path for logging
FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // .tool_input.filePath // .tool_input.path // .tool_input.notebook_path // .parameters.file_path // .parameters.filePath // .parameters.path // .parameters.notebook_path // "unknown"' 2>/dev/null)

# VIOLATION: File modification without spec folder
echo "[$(date '+%Y-%m-%d %H:%M:%S')] COMPLIANCE: $TOOL_NAME on $FILE_PATH without spec folder" >> "$LOG_FILE" 2>/dev/null

# Output warning (advisory, not blocking)
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "⚠️  COMPLIANCE WARNING: File Modified Without Spec Folder"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "Tool: $TOOL_NAME"
echo "File: $FILE_PATH"
echo ""
echo "Per CLAUDE.md Section 2:"
echo "Every conversation that modifies files MUST have a spec folder."
echo ""
echo "Next steps:"
echo "  1. Create spec folder: specs/###-short-name/"
echo "  2. Add spec.md from template"
echo "  3. Continue work in documented context"
echo ""
echo "Or use option D (Skip) if this is truly trivial exploration."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

exit 0  # Advisory only - don't block
