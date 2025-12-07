#!/bin/bash

# ───────────────────────────────────────────────────────────────
# DETECT PARALLEL CONFLICTS HOOK
# ───────────────────────────────────────────────────────────────
# SubagentStop hook that detects file modification conflicts between
# parallel sub-agents when they complete their work.
#
# TRIGGERS: When any sub-agent completes (SubagentStop event)
# PURPOSE: Detect conflicts with other agents' work
# BLOCKING: Only for CRITICAL conflicts (same lines modified)
#
# Version: 1.0.0
# Created: 2025-12-06
# Spec: specs/013-speckit-enhancements-from-repo-reference/
# Tasks: T158 (US-022)
#
# BEHAVIOR:
#   - Runs conflict detection after agent completes
#   - Logs conflicts to conflict report
#   - CRITICAL conflicts: Flag as BLOCKER with systemMessage
#   - HIGH/MEDIUM conflicts: Emit warning
#
# PERFORMANCE TARGET: <50ms
# EXIT CODE: 0 (decision returned via stdout JSON)
# ───────────────────────────────────────────────────────────────

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" 2>/dev/null && pwd)"
HOOKS_DIR="$(cd "$SCRIPT_DIR/.." 2>/dev/null && pwd)"

# Logging
LOG_DIR="$HOOKS_DIR/logs"
LOG_FILE="$LOG_DIR/conflict-detection.log"
mkdir -p "$LOG_DIR" 2>/dev/null

# Cross-platform timing
_get_time_ms() {
  if [[ "$OSTYPE" == "darwin"* ]]; then
    echo $(($(date +%s) * 1000))
  else
    date +%s%3N 2>/dev/null || echo $(($(date +%s) * 1000))
  fi
}

START_TIME=$(_get_time_ms)

# ═══════════════════════════════════════════════════════════════
# READ INPUT
# ═══════════════════════════════════════════════════════════════

INPUT=$(cat)

# Extract SubagentStop payload fields
SESSION_ID=$(echo "$INPUT" | jq -r '.session_id // empty' 2>/dev/null)
HOOK_EVENT=$(echo "$INPUT" | jq -r '.hook_event_name // empty' 2>/dev/null)
STOP_HOOK_ACTIVE=$(echo "$INPUT" | jq -r '.stop_hook_active // false' 2>/dev/null)

# Verify this is a SubagentStop event
if [ "$HOOK_EVENT" != "SubagentStop" ]; then
  exit 0
fi

# Prevent infinite loops if stop hook is already active
if [ "$STOP_HOOK_ACTIVE" = "true" ]; then
  {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] SKIP: stop_hook_active=true (preventing loop)"
  } >> "$LOG_FILE" 2>/dev/null
  exit 0
fi

# ═══════════════════════════════════════════════════════════════
# LOAD CONFLICT DETECTION LIBRARY
# ═══════════════════════════════════════════════════════════════

if [ ! -f "$HOOKS_DIR/lib/conflict-detection.sh" ]; then
  # Library not available - skip silently
  {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] SKIP: conflict-detection.sh not found"
  } >> "$LOG_FILE" 2>/dev/null
  exit 0
fi

source "$HOOKS_DIR/lib/conflict-detection.sh" 2>/dev/null || {
  echo '{"systemMessage": "⚠️ Conflict detection library not available"}'
  exit 0
}

# ═══════════════════════════════════════════════════════════════
# DETECT CONFLICTS
# ═══════════════════════════════════════════════════════════════

{
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] Checking for conflicts after agent completion"
  echo "  session=$SESSION_ID"
} >> "$LOG_FILE" 2>/dev/null

# Run conflict detection
CONFLICTS=$(detect_conflicts 2>/dev/null) || CONFLICTS="[]"

CONFLICT_COUNT=$(echo "$CONFLICTS" | jq 'length' 2>/dev/null) || CONFLICT_COUNT=0

if [ "$CONFLICT_COUNT" -eq 0 ]; then
  # No conflicts - silent success
  {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] No conflicts detected"
  } >> "$LOG_FILE" 2>/dev/null
  exit 0
fi

# ═══════════════════════════════════════════════════════════════
# ANALYZE CONFLICT SEVERITY
# ═══════════════════════════════════════════════════════════════

CRITICAL_COUNT=$(echo "$CONFLICTS" | jq '[.[] | select(.severity == "CRITICAL")] | length' 2>/dev/null) || CRITICAL_COUNT=0
HIGH_COUNT=$(echo "$CONFLICTS" | jq '[.[] | select(.severity == "HIGH")] | length' 2>/dev/null) || HIGH_COUNT=0
MEDIUM_COUNT=$(echo "$CONFLICTS" | jq '[.[] | select(.severity == "MEDIUM")] | length' 2>/dev/null) || MEDIUM_COUNT=0

# Get list of conflicting files for display
CONFLICTING_FILES=$(list_conflicting_files 2>/dev/null | head -5 | tr '\n' ', ' | sed 's/,$//')

# Log findings
{
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] CONFLICTS DETECTED"
  echo "  total=$CONFLICT_COUNT"
  echo "  critical=$CRITICAL_COUNT"
  echo "  high=$HIGH_COUNT"
  echo "  medium=$MEDIUM_COUNT"
  echo "  files=$CONFLICTING_FILES"
} >> "$LOG_FILE" 2>/dev/null

# ═══════════════════════════════════════════════════════════════
# OUTPUT DECISION
# ═══════════════════════════════════════════════════════════════

END_TIME=$(_get_time_ms)
DURATION=$((END_TIME - START_TIME))

{
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] Duration: ${DURATION}ms"
} >> "$LOG_FILE" 2>/dev/null

if [ "$CRITICAL_COUNT" -gt 0 ]; then
  # ─────────────────────────────────────────────────────────────
  # CRITICAL CONFLICTS: Flag as BLOCKER
  # ─────────────────────────────────────────────────────────────
  
  # Get critical conflict details
  CRITICAL_DETAILS=$(echo "$CONFLICTS" | jq -r '
    [.[] | select(.severity == "CRITICAL")] | 
    .[0] |
    "File: \(.files[0]), Agents: \(.agents | join(", "))"' 2>/dev/null)
  
  BLOCK_MSG="CRITICAL CONFLICT: Same lines modified by multiple agents. $CRITICAL_DETAILS. Manual resolution required before merging."
  
  # Truncate if too long
  [ ${#BLOCK_MSG} -gt 500 ] && BLOCK_MSG="${BLOCK_MSG:0:497}..."
  
  jq -n \
    --arg reason "$BLOCK_MSG" \
    --arg files "$CONFLICTING_FILES" \
    --argjson critical "$CRITICAL_COUNT" \
    '{
      decision: "block",
      reason: $reason,
      systemMessage: ("🚨 BLOCKER: " + $reason),
      conflictData: {
        severity: "CRITICAL",
        count: $critical,
        files: $files
      }
    }'
  
  {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] BLOCKED: Critical conflict detected"
  } >> "$LOG_FILE" 2>/dev/null
  
elif [ "$HIGH_COUNT" -gt 0 ]; then
  # ─────────────────────────────────────────────────────────────
  # HIGH CONFLICTS: Emit warning but allow
  # ─────────────────────────────────────────────────────────────
  
  WARNING_MSG="⚠️ HIGH CONFLICT: Same files modified by multiple agents ($CONFLICTING_FILES). Review before merging."
  
  jq -n --arg msg "$WARNING_MSG" '{systemMessage: $msg}'
  
  {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] WARNING: High conflict - same files modified"
  } >> "$LOG_FILE" 2>/dev/null
  
elif [ "$MEDIUM_COUNT" -gt 0 ]; then
  # ─────────────────────────────────────────────────────────────
  # MEDIUM CONFLICTS: Emit info but allow
  # ─────────────────────────────────────────────────────────────
  
  INFO_MSG="ℹ️ Related files modified by multiple agents ($CONFLICTING_FILES). Consider coordinating changes."
  
  jq -n --arg msg "$INFO_MSG" '{systemMessage: $msg}'
  
  {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] INFO: Medium conflict - related files modified"
  } >> "$LOG_FILE" 2>/dev/null
  
fi

exit 0
