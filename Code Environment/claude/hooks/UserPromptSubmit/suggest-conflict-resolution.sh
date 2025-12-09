#!/bin/bash

# ───────────────────────────────────────────────────────────────
# SUGGEST CONFLICT RESOLUTION HOOK
# ───────────────────────────────────────────────────────────────
# UserPromptSubmit hook that checks for pending conflicts and
# suggests resolution options to the user.
#
# Version: 1.0.0
# Created: 2025-12-06
# Spec: specs/013-speckit-enhancements-from-repo-reference/
# Tasks: T163 (US-023)
#
# BEHAVIOR:
#   1. Check for pending conflicts at prompt submission
#   2. If conflicts exist, display summary and options
#   3. Suggest resolution strategy based on severity
#   4. Provide A/B/C/D options for user choice
#
# PERFORMANCE TARGET: <50ms
# COMPATIBILITY: Bash 3.2+ (macOS and Linux)
#
# EXIT CODE CONVENTION:
#   0 = Allow (always allow prompt to proceed)
# ───────────────────────────────────────────────────────────────

# Source initialization (sets up HOOKS_DIR, LIB_DIR, etc.)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" 2>/dev/null && pwd)"
HOOKS_DIR="$(cd "$SCRIPT_DIR/.." 2>/dev/null && pwd)"
LIB_DIR="$HOOKS_DIR/lib"

# Source required libraries
source "$LIB_DIR/output-helpers.sh" 2>/dev/null || true
source "$LIB_DIR/exit-codes.sh" 2>/dev/null || {
  readonly EXIT_ALLOW=0
  readonly EXIT_BLOCK=1
}

# Logging configuration
LOG_DIR="$HOOKS_DIR/logs"
LOG_FILE="$LOG_DIR/suggest-conflict-resolution.log"
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

# ───────────────────────────────────────────────────────────────
# DEPENDENCY CHECK
# ───────────────────────────────────────────────────────────────

# Check if merge-engine.sh exists
if [[ ! -f "$LIB_DIR/merge-engine.sh" ]]; then
  # No merge engine available - silently exit
  exit $EXIT_ALLOW
fi

# Source merge-engine.sh
source "$LIB_DIR/merge-engine.sh" 2>/dev/null || {
  # Could not source - silently exit
  exit $EXIT_ALLOW
}

# Source shared-state.sh for reading state
source "$LIB_DIR/shared-state.sh" 2>/dev/null || {
  exit $EXIT_ALLOW
}

# ───────────────────────────────────────────────────────────────
# READ INPUT
# ───────────────────────────────────────────────────────────────

# Read JSON input from stdin
INPUT=$(cat)

# Extract the prompt from JSON (silent on error)
PROMPT=$(echo "$INPUT" | jq -r '.prompt // empty' 2>/dev/null)

# If no prompt found, allow it
if [[ -z "$PROMPT" ]]; then
  exit $EXIT_ALLOW
fi

# Convert prompt to lowercase for pattern matching
PROMPT_LOWER=$(echo "$PROMPT" | tr '[:upper:]' '[:lower:]')

# ───────────────────────────────────────────────────────────────
# CHECK FOR RESOLUTION COMMANDS IN PROMPT
# ───────────────────────────────────────────────────────────────

# If user is actively resolving a conflict, don't interrupt
if echo "$PROMPT_LOWER" | grep -qE "resolve.*conflict|get_resolution|mark_resolution|apply_resolution|conflict.*resolved"; then
  exit $EXIT_ALLOW
fi

# ───────────────────────────────────────────────────────────────
# CHECK FOR PENDING CONFLICTS
# ───────────────────────────────────────────────────────────────

# Get pending resolutions
PENDING_CONFLICTS=$(get_pending_resolutions 2>/dev/null)

# If no pending conflicts, exit silently
if [[ -z "$PENDING_CONFLICTS" ]]; then
  exit $EXIT_ALLOW
fi

# Count pending conflicts
CONFLICT_COUNT=$(echo "$PENDING_CONFLICTS" | grep -c '.' | tr -d ' ')

# If no conflicts (empty result), exit
if [[ "$CONFLICT_COUNT" -eq 0 ]]; then
  exit $EXIT_ALLOW
fi

# ───────────────────────────────────────────────────────────────
# ANALYZE CONFLICTS
# ───────────────────────────────────────────────────────────────

# Count by severity
CRITICAL_COUNT=0
HIGH_COUNT=0
MEDIUM_COUNT=0
LOW_COUNT=0

while IFS= read -r conflict_line; do
  [[ -z "$conflict_line" ]] && continue
  
  severity=$(echo "$conflict_line" | grep -o 'SEVERITY:[^ ]*' | sed 's/SEVERITY://')
  
  case "$severity" in
    "critical") CRITICAL_COUNT=$((CRITICAL_COUNT + 1)) ;;
    "high")     HIGH_COUNT=$((HIGH_COUNT + 1)) ;;
    "medium")   MEDIUM_COUNT=$((MEDIUM_COUNT + 1)) ;;
    "low"|*)    LOW_COUNT=$((LOW_COUNT + 1)) ;;
  esac
done <<< "$PENDING_CONFLICTS"

# ───────────────────────────────────────────────────────────────
# DETERMINE URGENCY
# ───────────────────────────────────────────────────────────────

URGENCY="low"
URGENCY_EMOJI="ℹ️"

if [[ "$CRITICAL_COUNT" -gt 0 ]]; then
  URGENCY="critical"
  URGENCY_EMOJI="🔴"
elif [[ "$HIGH_COUNT" -gt 0 ]]; then
  URGENCY="high"
  URGENCY_EMOJI="🟡"
elif [[ "$MEDIUM_COUNT" -gt 0 ]]; then
  URGENCY="medium"
  URGENCY_EMOJI="🔵"
fi

# ───────────────────────────────────────────────────────────────
# BUILD NOTIFICATION MESSAGE
# ───────────────────────────────────────────────────────────────

# Only show notification for critical/high urgency
# Medium/Low can be handled later
if [[ "$URGENCY" == "critical" ]] || [[ "$URGENCY" == "high" ]]; then
  
  # Get first conflict for detailed display
  FIRST_CONFLICT_LINE=$(echo "$PENDING_CONFLICTS" | head -1)
  FIRST_CONFLICT_ID=$(echo "$FIRST_CONFLICT_LINE" | awk '{print $1}')
  FIRST_CONFLICT_FILE=$(echo "$FIRST_CONFLICT_LINE" | grep -o 'FILE:[^ ]*' | sed 's/FILE://')
  
  # Build systemMessage for visibility
  MSG="$URGENCY_EMOJI PENDING CONFLICT$([ "$CONFLICT_COUNT" -gt 1 ] && echo "S") DETECTED\\n\\n"
  MSG="${MSG}Total: $CONFLICT_COUNT conflict(s) requiring resolution\\n"
  
  if [[ "$CRITICAL_COUNT" -gt 0 ]]; then
    MSG="${MSG}  🔴 Critical: $CRITICAL_COUNT\\n"
  fi
  if [[ "$HIGH_COUNT" -gt 0 ]]; then
    MSG="${MSG}  🟡 High: $HIGH_COUNT\\n"
  fi
  if [[ "$MEDIUM_COUNT" -gt 0 ]]; then
    MSG="${MSG}  🔵 Medium: $MEDIUM_COUNT\\n"
  fi
  if [[ "$LOW_COUNT" -gt 0 ]]; then
    MSG="${MSG}  ⚪ Low: $LOW_COUNT\\n"
  fi
  
  MSG="${MSG}\\nMost urgent: $FIRST_CONFLICT_ID\\n"
  MSG="${MSG}File: $FIRST_CONFLICT_FILE\\n"
  
  # Get recommended strategy for first conflict
  if type get_resolution_strategy &>/dev/null; then
    RECOMMENDATION=$(get_resolution_strategy "$FIRST_CONFLICT_ID" 2>/dev/null | grep "RECOMMENDED_STRATEGY:" | sed 's/RECOMMENDED_STRATEGY: //')
    if [[ -n "$RECOMMENDATION" ]]; then
      MSG="${MSG}Recommended: $RECOMMENDATION\\n"
    fi
  fi
  
  MSG="${MSG}\\nResolution Options:\\n"
  MSG="${MSG}  A) Auto-resolve all (where safe)\\n"
  MSG="${MSG}  B) View conflict details\\n"
  MSG="${MSG}  C) Resolve manually\\n"
  MSG="${MSG}  D) Defer (continue with current work)\\n"
  MSG="${MSG}\\nSay 'A', 'B', 'C', or 'D' to choose"
  
  # Output as systemMessage JSON for Claude Code visibility
  echo "{\"systemMessage\": \"${MSG}\"}"
  
  echo ""
  echo "───────────────────────────────────────────────────────────────"
  echo "CONFLICT RESOLUTION REQUIRED"
  echo "───────────────────────────────────────────────────────────────"
  echo ""
  echo "Pending conflicts: $CONFLICT_COUNT"
  echo ""
  
  # List first 3 conflicts
  SHOWN=0
  while IFS= read -r conflict_line; do
    [[ -z "$conflict_line" ]] && continue
    [[ "$SHOWN" -ge 3 ]] && break
    
    conflict_id=$(echo "$conflict_line" | awk '{print $1}')
    severity=$(echo "$conflict_line" | grep -o 'SEVERITY:[^ ]*' | sed 's/SEVERITY://')
    file=$(echo "$conflict_line" | grep -o 'FILE:[^ ]*' | sed 's/FILE://')
    
    case "$severity" in
      "critical") sev_emoji="🔴" ;;
      "high")     sev_emoji="🟡" ;;
      "medium")   sev_emoji="🔵" ;;
      *)          sev_emoji="⚪" ;;
    esac
    
    echo "  $sev_emoji $conflict_id - $file"
    
    SHOWN=$((SHOWN + 1))
  done <<< "$PENDING_CONFLICTS"
  
  if [[ "$CONFLICT_COUNT" -gt 3 ]]; then
    echo "  ... and $((CONFLICT_COUNT - 3)) more"
  fi
  
  echo ""
  echo "Resolution Options:"
  echo "  A) Auto-resolve all safe conflicts"
  echo "     Run: resolve_all_safe_conflicts()"
  echo ""
  echo "  B) View conflict details"
  echo "     Run: get_merge_preview('$FIRST_CONFLICT_ID')"
  echo ""
  echo "  C) Resolve manually"
  echo "     Run: get_resolution_instructions('$FIRST_CONFLICT_ID')"
  echo ""
  echo "  D) Defer resolution (continue with current work)"
  echo ""
  echo "───────────────────────────────────────────────────────────────"
  echo ""
  
  # Log the notification
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] Showed $CONFLICT_COUNT conflict(s) notification (urgency: $URGENCY)" >> "$LOG_FILE" 2>/dev/null

elif [[ "$URGENCY" == "medium" ]] && [[ "$CONFLICT_COUNT" -gt 0 ]]; then
  # Medium urgency - brief reminder only
  echo ""
  echo "ℹ️  Note: $CONFLICT_COUNT conflict(s) pending resolution"
  echo "   Run get_pending_resolutions() to view details"
  echo ""
  
  # Log
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] Brief reminder: $CONFLICT_COUNT conflict(s) (urgency: $URGENCY)" >> "$LOG_FILE" 2>/dev/null
fi

# ───────────────────────────────────────────────────────────────
# PERFORMANCE LOGGING
# ───────────────────────────────────────────────────────────────

END_TIME=$(_get_nano_time)
DURATION=$(( (END_TIME - START_TIME) / 1000000 ))

echo "[$(date '+%Y-%m-%d %H:%M:%S')] suggest-conflict-resolution.sh ${DURATION}ms - Found $CONFLICT_COUNT conflicts" >> "$HOOKS_DIR/logs/performance.log" 2>/dev/null

# Always allow the prompt to proceed
exit $EXIT_ALLOW
