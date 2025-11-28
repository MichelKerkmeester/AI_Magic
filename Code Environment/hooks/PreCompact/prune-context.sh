#!/bin/bash

# ───────────────────────────────────────────────────────────────
# PRUNE CONTEXT BEFORE COMPACTION
# ───────────────────────────────────────────────────────────────
# PreCompact hook that intelligently reduces token usage by
# deduplicating repeated tool call outputs before compaction.
#
# Version: 1.0.0
# Created: 2025-11-27
# Spec: specs/001-skills-and-hooks/046-context-pruning-hook/
#
# PERFORMANCE TARGET: <5s (Node.js script execution)
# COMPATIBILITY: Bash 3.2+ (macOS and Linux compatible)
#
# EXECUTION ORDER: PreCompact hook (runs BEFORE compaction)
#   Fires when: User manually compacts OR auto-compact threshold reached
#   Cannot block: Compaction proceeds regardless of exit code
#   Purpose: Reduce context size by removing duplicate tool outputs
#
# EXIT CODE CONVENTION:
#   0 = Success (pruning completed or skipped gracefully)
#   1 = Warning (partial success or configuration disabled)
#   2 = Error (reserved for critical failures, does not block)
# ───────────────────────────────────────────────────────────────

# Source output helpers and exit codes
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" 2>/dev/null && pwd)"
HOOKS_DIR="$(cd "$SCRIPT_DIR/.." 2>/dev/null && pwd)"

source "$HOOKS_DIR/lib/output-helpers.sh" || exit 0
source "$HOOKS_DIR/lib/exit-codes.sh" || exit 0

# Performance timing START
START_TIME=$(date +%s%N)

# ───────────────────────────────────────────────────────────────
# DEPENDENCY CHECKS
# ───────────────────────────────────────────────────────────────

if ! check_dependency "jq" "brew install jq (macOS) or apt install jq (Linux)"; then
  echo "   ⚠️  Context pruning skipped: jq not available" >&2
  exit $EXIT_ALLOW
fi

if ! check_dependency "node" "Install from https://nodejs.org/"; then
  echo "   ⚠️  Context pruning skipped: Node.js not available" >&2
  exit $EXIT_ALLOW
fi

# ───────────────────────────────────────────────────────────────
# PARSE JSON PAYLOAD
# ───────────────────────────────────────────────────────────────

INPUT=$(cat)

TRIGGER=$(echo "$INPUT" | jq -r '.trigger // "auto"' 2>/dev/null)
CUSTOM_INSTRUCTIONS=$(echo "$INPUT" | jq -r '.custom_instructions // empty' 2>/dev/null)
SESSION_ID=$(echo "$INPUT" | jq -r '.session_id // empty' 2>/dev/null)
CWD=$(echo "$INPUT" | jq -r '.cwd // empty' 2>/dev/null)

# Security: Sanitize SESSION_ID
if [ -n "$SESSION_ID" ]; then
  SESSION_ID=$(echo "$SESSION_ID" | tr -cd 'a-zA-Z0-9_-')
fi

# Validate required fields
if [ -z "$SESSION_ID" ]; then
  echo "   ⚠️  Context pruning skipped: Session ID not available" >&2
  exit $EXIT_ALLOW
fi

if [ -z "$CWD" ] || [ ! -d "$CWD" ]; then
  echo "   ⚠️  Context pruning skipped: Invalid working directory" >&2
  exit $EXIT_ALLOW
fi

# ───────────────────────────────────────────────────────────────
# LOAD CONFIGURATION
# ───────────────────────────────────────────────────────────────

# Check project config first
CONFIG_PATH="$CWD/.claude/configs/context-pruning.json"

# Fallback to default if not found
if [ ! -f "$CONFIG_PATH" ]; then
  CONFIG_PATH="$HOOKS_DIR/../configs/context-pruning.json"
fi

# Validate JSON
if [ -f "$CONFIG_PATH" ] && ! jq empty "$CONFIG_PATH" 2>/dev/null; then
  echo "   ⚠️  Invalid config JSON, using defaults" >&2
  CONFIG_PATH=""  # Let Node.js use hardcoded defaults
fi

# Check if pruning is enabled
if [ -n "$CONFIG_PATH" ]; then
  ENABLED=$(jq -r '.enabled // true' "$CONFIG_PATH" 2>/dev/null)
  if [ "$ENABLED" = "false" ]; then
    echo "   📋 Context pruning disabled in config" >&2
    exit $EXIT_ALLOW
  fi
fi

# ───────────────────────────────────────────────────────────────
# DISPLAY TRIGGER NOTIFICATION
# ───────────────────────────────────────────────────────────────

if [ "$TRIGGER" = "manual" ]; then
  echo "🧹 Pruning context before compaction (manual trigger)..."
  if [ -n "$CUSTOM_INSTRUCTIONS" ]; then
    echo "   📝 Custom instructions: ${CUSTOM_INSTRUCTIONS:0:80}..."
  fi
else
  echo "🧹 Pruning context before compaction (auto-compact threshold reached)..."
fi

# ───────────────────────────────────────────────────────────────
# LOCATE TRANSCRIPT FILE
# ───────────────────────────────────────────────────────────────

# Validate CWD path (security: prevent path traversal)
SAFE_CWD=$(realpath "$CWD" 2>/dev/null || echo "$CWD")
if [ ! -d "$SAFE_CWD" ]; then
  echo "   ⚠️  Cannot prune: Invalid working directory" >&2
  exit $EXIT_ALLOW
fi

# Convert path to Claude project slug format
PROJECT_SLUG=$(echo "$SAFE_CWD" | sed 's|^/|-|' | sed 's|/|-|g' | sed 's|\.|-|g' | sed 's|[^a-zA-Z0-9_-]||g')
TRANSCRIPT_DIR="$HOME/.claude/projects/$PROJECT_SLUG"

# Find transcript file
TRANSCRIPT_PATH=$(find "$TRANSCRIPT_DIR" -name "${SESSION_ID}.jsonl" 2>/dev/null | head -1)

if [ -z "$TRANSCRIPT_PATH" ] || [ ! -f "$TRANSCRIPT_PATH" ]; then
  echo "   ⚠️  Cannot prune: Transcript file not found" >&2
  echo "   Expected: $TRANSCRIPT_DIR/${SESSION_ID}.jsonl" >&2
  exit $EXIT_ALLOW
fi

echo "   📂 Found transcript: $(basename "$TRANSCRIPT_PATH")"

# ───────────────────────────────────────────────────────────────
# EXECUTE PRUNING ENGINE
# ───────────────────────────────────────────────────────────────

PRUNER="$HOOKS_DIR/lib/context-pruner.js"

if [ ! -f "$PRUNER" ]; then
  echo "   ⚠️  Cannot prune: Pruning engine not found" >&2
  echo "   Expected: $PRUNER" >&2
  exit $EXIT_ALLOW
fi

# Execute pruning with timeout
if command -v timeout >/dev/null 2>&1; then
  NODE_OUTPUT=$(timeout 5 node "$PRUNER" "$TRANSCRIPT_PATH" "$CONFIG_PATH" 2>&1)
else
  NODE_OUTPUT=$(node "$PRUNER" "$TRANSCRIPT_PATH" "$CONFIG_PATH" 2>&1)
fi
EXIT_CODE=$?

# ───────────────────────────────────────────────────────────────
# DISPLAY RESULT
# ───────────────────────────────────────────────────────────────

if [ $EXIT_CODE -eq 0 ]; then
  echo "$NODE_OUTPUT"
  echo "   🎯 Compaction can proceed with pruned context"
else
  echo "   ⚠️  Pruning failed (exit code: $EXIT_CODE)" >&2
  if [ -n "$NODE_OUTPUT" ]; then
    echo "   Error: ${NODE_OUTPUT:0:200}" >&2
  fi
  echo "   ⚠️  Compaction will proceed with original context" >&2
fi

# ───────────────────────────────────────────────────────────────
# LOGGING
# ───────────────────────────────────────────────────────────────

LOG_DIR="$HOOKS_DIR/logs"
mkdir -p "$LOG_DIR"
LOG_FILE="$LOG_DIR/context-pruning.log"

# Rotate log if needed (100KB limit)
rotate_log_if_needed "$LOG_FILE" 102400

TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')

{
  echo ""
  echo "───────────────────────────────────────────────────────────────"
  echo "[$TIMESTAMP] CONTEXT PRUNING TRIGGERED"
  echo "───────────────────────────────────────────────────────────────"
  echo "Trigger: $TRIGGER"
  if [ "$TRIGGER" = "manual" ] && [ -n "$CUSTOM_INSTRUCTIONS" ]; then
    echo "Custom Instructions: ${CUSTOM_INSTRUCTIONS:0:200}"
  fi
  echo "Session: $SESSION_ID"
  echo "Config: $CONFIG_PATH"
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
END_TIME=$(date +%s%N)
DURATION=$(( (END_TIME - START_TIME) / 1000000 ))
echo "[$(date '+%Y-%m-%d %H:%M:%S')] prune-context.sh ${DURATION}ms" >> "$LOG_DIR/performance.log"

# Always allow compaction to proceed (PreCompact cannot block)
exit $EXIT_ALLOW
