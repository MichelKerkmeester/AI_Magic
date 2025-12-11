#!/bin/bash

# ───────────────────────────────────────────────────────────────
# AGENTS.MD INJECTION HOOK (HARD BLOCKER)
# ───────────────────────────────────────────────────────────────
# UserPromptSubmit hook that injects the full AGENTS.md content
# into Claude's context as a system message on FIRST message only.
#
# PURPOSE: Force Claude to read AGENTS.md (AI governance framework)
# at session start without relying on CLAUDE.md redirect.
#
# HARD BLOCKER: If AGENTS.md is missing, session is BLOCKED.
# This is a P0 critical gate - the entire governance system depends on this.
#
# PERFORMANCE TARGET: <100ms
# COMPATIBILITY: Bash 3.2+ (macOS and Linux compatible)
#
# EXIT CODE:
#   0 = Success (content injected or already injected)
#   0 = Blocked via JSON output ({"result": "block"})
# ───────────────────────────────────────────────────────────────

# Performance timing START
START_TIME=$(($(date +%s) * 1000))

# Resolve paths
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" 2>/dev/null && pwd)"
HOOKS_DIR="$(cd "$SCRIPT_DIR/.." 2>/dev/null && pwd)"
PROJECT_ROOT=$(git rev-parse --show-toplevel 2>/dev/null || (cd "$SCRIPT_DIR/../../.." && pwd))

# Read stdin (required to prevent blocking)
cat > /dev/null

# ───────────────────────────────────────────────────────────────
# SESSION FLAG - PREVENT RE-INJECTION
# ───────────────────────────────────────────────────────────────
# Use Claude Code's session ID if available, otherwise use PPID
# CLAUDE_SESSION_ID is set by Claude Code; PPID is the parent process ID

SESSION_ID="${CLAUDE_SESSION_ID:-$PPID}"
SESSION_FLAG="/tmp/claude-agents-md-injected-${SESSION_ID}"

# Check if already injected this session
if [[ -f "$SESSION_FLAG" ]]; then
  # Already injected, skip silently
  # Log for debugging
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] inject-agents-md.sh SKIPPED (already injected)" >> "$HOOKS_DIR/logs/performance.log" 2>/dev/null
  exit 0
fi

# ───────────────────────────────────────────────────────────────
# HARD BLOCKER - CHECK AGENTS.MD EXISTS
# ───────────────────────────────────────────────────────────────

AGENTS_FILE="$PROJECT_ROOT/AGENTS.md"

if [[ ! -f "$AGENTS_FILE" ]]; then
  # HARD BLOCK - Cannot proceed without governance framework
  printf '{"result": "block", "reason": "CRITICAL: AGENTS.md not found at project root (%s). The AI governance framework cannot be loaded. All gates, protocols, and behavioral guardrails are UNAVAILABLE. Please ensure AGENTS.md exists before proceeding."}\n' "$PROJECT_ROOT"

  # Log the critical error
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] inject-agents-md.sh HARD BLOCK - AGENTS.md not found" >> "$HOOKS_DIR/logs/performance.log" 2>/dev/null
  exit 0
fi

# ───────────────────────────────────────────────────────────────
# READ AND ESCAPE AGENTS.MD
# ───────────────────────────────────────────────────────────────

# Read AGENTS.md and escape for JSON using jq (most reliable method)
if command -v jq &> /dev/null; then
  # Use jq for proper JSON escaping - outputs ready-to-use escaped string without quotes
  ESCAPED_CONTENT=$(cat "$AGENTS_FILE" | jq -Rs '.' | sed 's/^"//;s/"$//')
else
  # Fallback: basic escaping (less reliable for complex content)
  ESCAPED_CONTENT=$(cat "$AGENTS_FILE" | \
    sed 's/\\/\\\\/g' | \
    sed 's/"/\\"/g' | \
    sed ':a;N;$!ba;s/\n/\\n/g' | \
    sed 's/\t/\\t/g')
fi

# ───────────────────────────────────────────────────────────────
# OUTPUT
# ───────────────────────────────────────────────────────────────

# Output as systemMessage JSON
printf '{"systemMessage": "%s"}\n' "$ESCAPED_CONTENT"

# Set flag to prevent re-injection on subsequent messages
touch "$SESSION_FLAG"

# Performance timing END
END_TIME=$(($(date +%s) * 1000))
DURATION=$((END_TIME - START_TIME))
echo "[$(date '+%Y-%m-%d %H:%M:%S')] inject-agents-md.sh ${DURATION}ms INJECTED" >> "$HOOKS_DIR/logs/performance.log" 2>/dev/null

# Success
exit 0
