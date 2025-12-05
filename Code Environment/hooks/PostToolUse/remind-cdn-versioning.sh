#!/bin/bash

# ───────────────────────────────────────────────────────────────
# CDN VERSION REMINDER HOOK - ENHANCED PRODUCTION DETECTION
# ───────────────────────────────────────────────────────────────
# Post-ToolUse hook that reminds to run CDN version updater
# after JavaScript file modifications in production/staging contexts
#
# Author: Enhanced from spec 090-code-workflows-orchestrator-restructure
# Date: 2025-11-29
# Version: 2.0.0
#
# ENHANCEMENTS (v2.0.0):
# - Multi-tier production detection (production/staging/development)
# - Branch-based environment detection (main/master = production)
# - Environment variable checks (NODE_ENV, RAILS_ENV, etc.)
# - Smart caching to prevent spam on same file
# - Deployment context awareness (build scripts, output directories)
#
# PERFORMANCE TARGET: <200ms (file path checks, pattern matching, cache)
# COMPATIBILITY: Bash 3.2+ (macOS and Linux compatible)
#
# EXECUTION ORDER: PostToolUse hook (runs AFTER tool completion)
#   1. UserPromptSubmit hooks run FIRST (before processing user input)
#   2. PreToolUse hooks run SECOND (before tool execution, validation)
#   3. PostToolUse hooks run LAST (after tool completion, verification)
#   This hook: Reminds to update CDN version parameters after JS changes
#
# EXIT CODE CONVENTION:
#   0 = Allow (hook passed, continue execution)
#   1 = Block (hook failed, stop execution with warning)
#   2 = Error (reserved for critical failures)
# ───────────────────────────────────────────────────────────────

# Source output helpers
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" 2>/dev/null && pwd)"
HOOKS_DIR="$(cd "$SCRIPT_DIR/.." 2>/dev/null && pwd)"
source "$HOOKS_DIR/lib/output-helpers.sh" || exit 0

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

# Read JSON input from stdin
INPUT=$(cat)

# Extract tool information from JSON (support multiple payload shapes)
TOOL_NAME=$(echo "$INPUT" | jq -r '.tool_name // .toolName // .tool // .name // empty' 2>/dev/null)
FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.filePath // .tool_input.file_path // .tool_input.path // .tool_input.notebook_path // .parameters.file_path // .parameters.filePath // .parameters.path // .parameters.notebook_path // empty' 2>/dev/null)

# If no tool or file path, allow it
if [ -z "$TOOL_NAME" ] || [ -z "$FILE_PATH" ]; then
  exit 0
fi

# ───────────────────────────────────────────────────────────────
# JAVASCRIPT FILE MODIFICATION DETECTION
# ───────────────────────────────────────────────────────────────

# Check if tool was Edit or Write
if [ "$TOOL_NAME" != "Edit" ] && [ "$TOOL_NAME" != "Write" ]; then
  exit 0
fi

# Check if file is a JavaScript file
if ! echo "$FILE_PATH" | grep -qE '\.(js|jsx|ts|tsx|mjs|cjs)$'; then
  exit 0
fi

# ───────────────────────────────────────────────────────────────
# MULTI-TIER PRODUCTION DETECTION
# ───────────────────────────────────────────────────────────────
# Tier 1: Critical production files (versioning MANDATORY)
# Tier 2: Staging files (versioning RECOMMENDED)
# Tier 3: Development files (no reminder needed)

PROJECT_ROOT=$(git rev-parse --show-toplevel 2>/dev/null || (cd "$SCRIPT_DIR/../.." && pwd))
REL_FILE_PATH=${FILE_PATH#$PROJECT_ROOT/}

# Initialize tier and environment
ENVIRONMENT_TIER="development"
ENVIRONMENT_NAME="Development"
REMINDER_PRIORITY="INFO"
CURRENT_BRANCH=""  # Initialize to avoid undefined variable issues

# ───────────────────────────────────────────────────────────────
# TIER 1: PRODUCTION DETECTION
# ───────────────────────────────────────────────────────────────

# Check 1: Production output directories
if echo "$REL_FILE_PATH" | grep -qE '^(public|dist|build|out|.next/static|_site|deploy|release)/'; then
  ENVIRONMENT_TIER="production"
  ENVIRONMENT_NAME="Production Output"
  REMINDER_PRIORITY="CRITICAL"
fi

# Check 2: Git branch detection (main/master = production)
if [ "$ENVIRONMENT_TIER" = "development" ]; then
  CURRENT_BRANCH=$(git branch --show-current 2>/dev/null)
  if echo "$CURRENT_BRANCH" | grep -qE '^(main|master|production|prod|release)$'; then
    # Check if in source directory (not test files)
    if echo "$REL_FILE_PATH" | grep -qE '^(src|lib|app|assets|static)/'; then
      ENVIRONMENT_TIER="production"
      ENVIRONMENT_NAME="Production Branch ($CURRENT_BRANCH)"
      REMINDER_PRIORITY="CRITICAL"
    fi
  fi
fi

# Check 3: Environment variables
if [ "$ENVIRONMENT_TIER" = "development" ]; then
  if [ "${NODE_ENV:-}" = "production" ] || \
     [ "${RAILS_ENV:-}" = "production" ] || \
     [ "${DJANGO_ENV:-}" = "production" ] || \
     [ "${FLASK_ENV:-}" = "production" ] || \
     [ "${APP_ENV:-}" = "production" ]; then
    ENVIRONMENT_TIER="production"
    ENVIRONMENT_NAME="Production Environment"
    REMINDER_PRIORITY="CRITICAL"
  fi
fi

# Check 4: Project-specific production paths
if [ "$ENVIRONMENT_TIER" = "development" ]; then
  # src/2_javascript/ is production-ready code for this project
  if echo "$REL_FILE_PATH" | grep -qE '^src/2_javascript/'; then
    ENVIRONMENT_TIER="production"
    ENVIRONMENT_NAME="Production JavaScript"
    REMINDER_PRIORITY="CRITICAL"
  fi
fi

# ───────────────────────────────────────────────────────────────
# TIER 2: STAGING DETECTION
# ───────────────────────────────────────────────────────────────

if [ "$ENVIRONMENT_TIER" = "development" ]; then
  # Check 1: Staging output directories
  if echo "$REL_FILE_PATH" | grep -qE '^(staging|stage|preview|.next/preview)/'; then
    ENVIRONMENT_TIER="staging"
    ENVIRONMENT_NAME="Staging"
    REMINDER_PRIORITY="WARN"
  fi

  # Check 2: Staging branch
  if [ "$ENVIRONMENT_TIER" = "development" ]; then
    if echo "$CURRENT_BRANCH" | grep -qE '^(staging|stage|develop|dev|preview)$'; then
      if echo "$REL_FILE_PATH" | grep -qE '^(src|lib|app|assets|static)/'; then
        ENVIRONMENT_TIER="staging"
        ENVIRONMENT_NAME="Staging Branch ($CURRENT_BRANCH)"
        REMINDER_PRIORITY="WARN"
      fi
    fi
  fi

  # Check 3: Project-specific staging paths
  if [ "$ENVIRONMENT_TIER" = "development" ]; then
    if echo "$REL_FILE_PATH" | grep -qE '^src/3_staging/'; then
      ENVIRONMENT_TIER="staging"
      ENVIRONMENT_NAME="Staging Directory"
      REMINDER_PRIORITY="WARN"
    fi
  fi
fi

# ───────────────────────────────────────────────────────────────
# TIER 3: DEVELOPMENT (Skip Reminder)
# ───────────────────────────────────────────────────────────────

if [ "$ENVIRONMENT_TIER" = "development" ]; then
  # No reminder needed for development files
  exit 0
fi

# ───────────────────────────────────────────────────────────────
# SMART CACHING - PREVENT SPAM
# ───────────────────────────────────────────────────────────────
# Track which files have already been reminded in this session
# Cache expires after 1 hour or on hook restart

CACHE_DIR="/tmp/cdn_versioning_cache"
mkdir -p "$CACHE_DIR" 2>/dev/null

# Generate cache key from file path
CACHE_KEY=$(echo -n "$REL_FILE_PATH" | cksum | cut -d' ' -f1)
CACHE_FILE="$CACHE_DIR/${CACHE_KEY}.reminded"

# Check if reminder was already shown recently (within 1 hour)
if [ -f "$CACHE_FILE" ]; then
  CACHE_AGE=$(( $(date +%s) - $(stat -f %m "$CACHE_FILE" 2>/dev/null || stat -c %Y "$CACHE_FILE" 2>/dev/null || echo 0) ))
  if [ "$CACHE_AGE" -lt 3600 ]; then
    # Already reminded recently, skip
    exit 0
  fi
fi

# Mark this file as reminded
touch "$CACHE_FILE" 2>/dev/null

# ───────────────────────────────────────────────────────────────
# TIERED REMINDER OUTPUT
# ───────────────────────────────────────────────────────────────

# Log reminder
LOG_DIR="$HOOKS_DIR/logs"
mkdir -p "$LOG_DIR"
LOG_FILE="$LOG_DIR/$(basename "$0" .sh).log"

# Rotate log if needed
rotate_log_if_needed "$LOG_FILE" 102400

# Build reminder message based on tier
case "$ENVIRONMENT_TIER" in
  production)
    echo ""
    echo "🔴 CRITICAL: Production JavaScript Modified"
    echo "───────────────────────────────────────────────────────────────"
    echo "File: $REL_FILE_PATH"
    echo "Context: $ENVIRONMENT_NAME"
    echo ""
    echo "⚡ REQUIRED ACTION: Update CDN version parameters"
    echo ""
    echo "  python3 .claude/hooks/scripts/update_html_versions.py"
    echo ""
    echo "Why: Production files require cache-busting to ensure browsers"
    echo "     download fresh JavaScript instead of serving stale cached versions."
    echo ""
    echo "Impact: Users may experience bugs if cached old code conflicts with"
    echo "        new server-side changes or updated HTML."
    echo ""
    echo "Reference: .claude/skills/workflows-code/references/implementation_workflows.md"
    echo "───────────────────────────────────────────────────────────────"
    echo ""
    
    # Emit systemMessage for Claude Code visibility
    visible_msg=$(jq -n --arg msg "🔴 CRITICAL: Production JS modified ($REL_FILE_PATH). Run: python3 .claude/hooks/scripts/update_html_versions.py" '{systemMessage: $msg}')
    echo "$visible_msg"

    {
      echo "[$(date '+%Y-%m-%d %H:%M:%S')] PRODUCTION CDN VERSION REMINDER"
      echo "Tool: $TOOL_NAME"
      echo "File: $REL_FILE_PATH"
      echo "Context: $ENVIRONMENT_NAME"
      echo "Priority: CRITICAL - Versioning REQUIRED"
      echo "Action: Modified production JavaScript"
      echo "Reminder: Run update_html_versions.py script BEFORE deployment"
      echo "───────────────────────────────────────────────────────────────"
    } >> "$LOG_FILE"
    ;;

  staging)
    echo ""
    echo "🟡 RECOMMENDED: Staging JavaScript Modified"
    echo "───────────────────────────────────────────────────────────────"
    echo "File: $REL_FILE_PATH"
    echo "Context: $ENVIRONMENT_NAME"
    echo ""
    echo "💡 RECOMMENDED: Update CDN version parameters"
    echo ""
    echo "  python3 .claude/hooks/scripts/update_html_versions.py"
    echo ""
    echo "Why: Staging environments benefit from cache-busting to ensure"
    echo "     accurate testing of JavaScript changes."
    echo ""
    echo "Note: While not critical, versioning helps prevent false negatives"
    echo "      in testing due to cached code."
    echo ""
    echo "Reference: .claude/skills/workflows-code/references/implementation_workflows.md"
    echo "───────────────────────────────────────────────────────────────"
    echo ""
    
    # Emit systemMessage for Claude Code visibility
    visible_msg=$(jq -n --arg msg "🟡 RECOMMENDED: Staging JS modified ($REL_FILE_PATH). Consider: python3 .claude/hooks/scripts/update_html_versions.py" '{systemMessage: $msg}')
    echo "$visible_msg"

    {
      echo "[$(date '+%Y-%m-%d %H:%M:%S')] STAGING CDN VERSION REMINDER"
      echo "Tool: $TOOL_NAME"
      echo "File: $REL_FILE_PATH"
      echo "Context: $ENVIRONMENT_NAME"
      echo "Priority: RECOMMENDED - Versioning helpful for testing"
      echo "Action: Modified staging JavaScript"
      echo "Reminder: Consider running update_html_versions.py script"
      echo "───────────────────────────────────────────────────────────────"
    } >> "$LOG_FILE"
    ;;
esac

# Performance timing END (using helper defined at top)
END_TIME=$(_get_nano_time)
DURATION=$(( (END_TIME - START_TIME) / 1000000 ))
echo "[$(date '+%Y-%m-%d %H:%M:%S')] remind-cdn-versioning.sh ${DURATION}ms (tier=$ENVIRONMENT_TIER)" >> "$SCRIPT_DIR/../logs/performance.log"

# Allow request to proceed
exit 0
