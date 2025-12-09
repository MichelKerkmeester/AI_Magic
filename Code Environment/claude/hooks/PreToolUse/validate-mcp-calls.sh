#!/bin/bash

# ───────────────────────────────────────────────────────────────
# MCP CALL VALIDATION HOOK
# ───────────────────────────────────────────────────────────────
# PreToolUse hook that detects direct MCP tool calls and suggests
# Code Mode usage for optimal performance
#
# PERFORMANCE TARGET: <50ms (lightweight pattern matching)
# COMPATIBILITY: Bash 3.2+ (macOS and Linux compatible)
#
# EXECUTION ORDER: PreToolUse hook (runs BEFORE tool execution)
#   1. UserPromptSubmit hooks run FIRST (before processing user input)
#   2. PreToolUse hooks run SECOND (before tool execution, validation)
#   3. PostToolUse hooks run LAST (after tool completion, verification)
#   This hook: Validates MCP tool call patterns before execution
#
# EXIT CODE CONVENTION:
#   0 = Allow (hook passed, continue execution)
#   1 = Block (hook failed, stop execution with warning)
#   2 = Error (reserved for critical failures)
#
# BEHAVIOR:
#   - Exit 0 (allow) if Code Mode tools detected (correct usage)
#   - Exit 0 (allow) but warn if direct MCP calls detected (anti-pattern)
#   - Non-blocking to avoid disrupting workflow
# ───────────────────────────────────────────────────────────────

# Source output helpers (completely silent on success)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" 2>/dev/null && pwd)"
HOOKS_DIR="$(cd "$SCRIPT_DIR/.." 2>/dev/null && pwd)"
source "$HOOKS_DIR/lib/output-helpers.sh" || exit 0
source "$HOOKS_DIR/lib/perf-timing.sh" 2>/dev/null || true

# Logging configuration
LOG_DIR="$HOOKS_DIR/logs"
LOG_FILE="$LOG_DIR/$(basename "$0" .sh).log"

# Performance timing START (using centralized _get_nano_time from perf-timing.sh)
START_TIME=$(_get_nano_time)

# Read JSON input from stdin
INPUT=$(cat)

# Extract tool name and parameters from JSON (silent on error)
TOOL_NAME=$(echo "$INPUT" | jq -r '.name // empty' 2>/dev/null)
TOOL_PARAMS=$(echo "$INPUT" | jq -r '.params // empty' 2>/dev/null)

# If no tool name found, allow it
if [ -z "$TOOL_NAME" ]; then
  exit 0
fi

# Convert tool name to lowercase for case-insensitive matching
TOOL_NAME_LOWER=$(echo "$TOOL_NAME" | tr '[:upper:]' '[:lower:]')

# ───────────────────────────────────────────────────────────────
# DETECTION LOGIC
# ───────────────────────────────────────────────────────────────

IS_CODE_MODE_TOOL=false
IS_DIRECT_MCP_CALL=false
MCP_PLATFORM=""
SUGGESTED_CODE_MODE_CALL=""

# Check if this is a Code Mode tool (correct usage)
if echo "$TOOL_NAME_LOWER" | grep -qE "^(call_tool_chain|search_tools|list_tools|tool_info|get_required_keys_for_tool)"; then
  IS_CODE_MODE_TOOL=true
fi

# Check if this is a direct MCP tool call (anti-pattern for external tools)
# Pattern: tool names starting with external MCP server prefixes
# NOTE: semantic_search_ is NOT included - it's a NATIVE MCP tool, call directly
if echo "$TOOL_NAME_LOWER" | grep -qE "^(webflow_|figma_|chrome_devtools_)"; then
  IS_DIRECT_MCP_CALL=true

  # Determine which platform (use TOOL_NAME_LOWER consistently for suffix removal)
  if echo "$TOOL_NAME_LOWER" | grep -q "^webflow_"; then
    MCP_PLATFORM="Webflow"
    SUGGESTED_CODE_MODE_CALL="webflow.webflow_${TOOL_NAME_LOWER#webflow_}"
  elif echo "$TOOL_NAME_LOWER" | grep -q "^figma_"; then
    MCP_PLATFORM="Figma"
    SUGGESTED_CODE_MODE_CALL="figma.figma_${TOOL_NAME_LOWER#figma_}"
  elif echo "$TOOL_NAME_LOWER" | grep -q "^chrome_devtools_"; then
    MCP_PLATFORM="Chrome DevTools"
    SUGGESTED_CODE_MODE_CALL="chrome_devtools_1.chrome_devtools_${TOOL_NAME_LOWER#chrome_devtools_}"
  fi
  # NOTE: semantic_search_ removed - it's NATIVE MCP, not external
fi

# ───────────────────────────────────────────────────────────────
# OUTPUT HANDLING
# ───────────────────────────────────────────────────────────────

# Use _get_nano_time defined earlier for END_TIME
get_nano_time() { _get_nano_time; }

# Case 1: Code Mode tool detected (correct usage)
if [ "$IS_CODE_MODE_TOOL" = true ]; then
  # Silent success - this is the correct pattern
  END_TIME=$(get_nano_time)
  DURATION=$(( (END_TIME - START_TIME) / 1000000 ))
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] validate-mcp-calls.sh ${DURATION}ms - Code Mode detected (correct)" >> "$HOOKS_DIR/logs/performance.log"
  exit 0
fi

# Case 2: Direct MCP call detected (anti-pattern)
if [ "$IS_DIRECT_MCP_CALL" = true ]; then
  # Emit systemMessage for Claude Code visibility
  echo "{\"systemMessage\": \"💡 Use Code Mode (call_tool_chain) for $MCP_PLATFORM - 98.7% overhead reduction, 60% faster\"}"
  echo ""
  echo "⚠️  DIRECT MCP CALL DETECTED - Use Code Mode instead"
  echo "   Tool: $TOOL_NAME → $SUGGESTED_CODE_MODE_CALL"
  echo ""
  echo "   ✅ call_tool_chain({ code: \`await $SUGGESTED_CODE_MODE_CALL({...})\` })"
  echo ""
  echo "   Benefits: 98.7% overhead reduction, 60% faster, state persistence"
  echo "   📖 Guide: .claude/skills/mcp-code-mode/SKILL.md"
  echo ""

  # Log the anti-pattern detection
  END_TIME=$(get_nano_time)
  DURATION=$(( (END_TIME - START_TIME) / 1000000 ))
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] validate-mcp-calls.sh ${DURATION}ms - Direct MCP call: $TOOL_NAME ($MCP_PLATFORM)" >> "$HOOKS_DIR/logs/performance.log"

  # Exit 0 (allow) but with educational warning
  exit 0
fi

# Case 3: Neither Code Mode nor direct MCP call (probably a regular tool)
# Silent success - don't interfere with non-MCP tools
END_TIME=$(get_nano_time)
DURATION=$(( (END_TIME - START_TIME) / 1000000 ))
echo "[$(date '+%Y-%m-%d %H:%M:%S')] validate-mcp-calls.sh ${DURATION}ms - Regular tool: $TOOL_NAME" >> "$HOOKS_DIR/logs/performance.log"
exit 0
