#!/bin/bash

# ───────────────────────────────────────────────────────────────
# ENFORCE TASK SCOPE HOOK
# ───────────────────────────────────────────────────────────────
# PreToolUse hook that validates file operations stay within task scope.
# Blocks Write/Edit operations on files outside the current task's
# allowed directories, and checks Bash commands for boundary violations.
#
# Version: 1.0.0
# Created: 2025-12-06
# Spec: specs/013-speckit-enhancements-from-repo-reference/ (T100-T101)
#
# EXECUTION ORDER: PreToolUse hook (runs BEFORE tool execution)
#   1. UserPromptSubmit hooks (FIRST - before user prompt processing)
#   2. PreToolUse hooks (SECOND - before tool execution, validation) ← THIS HOOK
#   3. PostToolUse hooks (LAST - after tool completion, verification)
#
# EXIT CODE CONVENTION:
#   0 = Allow (validation passed, continue execution)
#   2 = Block (validation failed, stop execution with message)
#
# PERFORMANCE TARGET: <50ms validation time
# COMPATIBILITY: Bash 3.2+ (macOS and Linux compatible)
# ───────────────────────────────────────────────────────────────

# Strict mode for reliability
set -euo pipefail

# ============================================================================
# CONFIGURATION
# ============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" 2>/dev/null && pwd)"
HOOKS_DIR="$(cd "$SCRIPT_DIR/.." 2>/dev/null && pwd)"
PROJECT_ROOT=$(git rev-parse --show-toplevel 2>/dev/null || (cd "$SCRIPT_DIR/../.." && pwd))
LOG_DIR="$HOOKS_DIR/logs"
LOG_FILE="$LOG_DIR/enforce-task-scope.log"

mkdir -p "$LOG_DIR" 2>/dev/null || true

# ============================================================================
# LOAD DEPENDENCIES
# ============================================================================

# Load exit codes
if [ -f "$HOOKS_DIR/lib/exit-codes.sh" ]; then
  source "$HOOKS_DIR/lib/exit-codes.sh"
else
  EXIT_ALLOW=0
  EXIT_BLOCK=2
fi

# Load task validation library
if [ -f "$HOOKS_DIR/lib/task-validation.sh" ]; then
  source "$HOOKS_DIR/lib/task-validation.sh"
  TASK_VAL_LOADED=true
else
  # Library not available - allow all operations
  exit 0
fi

# Load tool input parser
if [ -f "$HOOKS_DIR/lib/tool-input-parser.sh" ]; then
  source "$HOOKS_DIR/lib/tool-input-parser.sh"
fi

# ============================================================================
# HELPER FUNCTIONS
# ============================================================================

# Log event with timestamp
log_event() {
  local status="$1"
  local detail="${2:-}"
  local timestamp
  timestamp=$(date '+%Y-%m-%d %H:%M:%S' 2>/dev/null || date)
  
  {
    echo "[$timestamp] STATUS: $status"
    [ -n "$detail" ] && echo "  Detail: $detail"
  } >> "$LOG_FILE" 2>/dev/null || true
}

# Parse JSON with jq or fallback to grep/sed
parse_json_field() {
  local json="$1"
  local field="$2"
  
  if command -v jq &>/dev/null; then
    echo "$json" | jq -r "$field // empty" 2>/dev/null
  else
    # Fallback: simple extraction for common fields
    echo "$json" | grep -o "\"${field#.}\"[[:space:]]*:[[:space:]]*\"[^\"]*\"" | \
      sed 's/.*: *"//;s/"$//' | head -1
  fi
}

# ============================================================================
# MAIN VALIDATION LOGIC
# ============================================================================

main() {
  # Read JSON input from stdin
  local input
  input=$(cat)
  
  if [ -z "$input" ]; then
    exit $EXIT_ALLOW
  fi
  
  # Parse tool name and input
  local tool_name
  local tool_input
  
  if command -v jq &>/dev/null; then
    tool_name=$(echo "$input" | jq -r '.tool_name // .name // .tool // empty' 2>/dev/null)
    tool_input=$(echo "$input" | jq -c '.tool_input // .parameters // {}' 2>/dev/null)
  else
    tool_name=$(parse_json_field "$input" ".tool_name")
    [ -z "$tool_name" ] && tool_name=$(parse_json_field "$input" ".name")
    tool_input="$input"
  fi
  
  # Skip if no tool name detected
  if [ -z "$tool_name" ]; then
    exit $EXIT_ALLOW
  fi
  
  # ========================================================================
  # WRITE/EDIT TOOL VALIDATION
  # ========================================================================
  
  if [[ "$tool_name" =~ ^(Write|Edit|NotebookEdit)$ ]]; then
    # Extract file path
    local file_path
    if command -v jq &>/dev/null; then
      file_path=$(echo "$tool_input" | jq -r '.file_path // .path // .filePath // empty' 2>/dev/null)
    else
      file_path=$(parse_json_field "$tool_input" ".file_path")
      [ -z "$file_path" ] && file_path=$(parse_json_field "$tool_input" ".path")
      [ -z "$file_path" ] && file_path=$(parse_json_field "$tool_input" ".filePath")
    fi
    
    if [ -n "$file_path" ]; then
      # Check if file is within task scope
      if ! is_file_in_task_scope "$file_path"; then
        local reason
        reason=$(get_scope_violation_reason "$file_path")
        
        log_event "BLOCKED" "$tool_name on $file_path - $reason"
        
        echo ""
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo "⚠️  TASK SCOPE VIOLATION"
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo ""
        echo "Tool: $tool_name"
        echo "File: $file_path"
        echo ""
        echo "Reason: $reason"
        echo ""
        echo "Options:"
        echo "  A) Expand task scope to include this file"
        echo "  B) Complete current task first, then start new task"
        echo "  C) Override and proceed (acknowledge scope expansion)"
        echo ""
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo ""
        
        exit $EXIT_BLOCK
      fi
      
      # Track file modification for packing detection
      track_session_file "$file_path" "$tool_name"
      log_event "ALLOWED" "$tool_name on $file_path (in scope)"
    fi
    
    exit $EXIT_ALLOW
  fi
  
  # ========================================================================
  # BASH COMMAND VALIDATION
  # ========================================================================
  
  if [[ "$tool_name" == "Bash" ]]; then
    # Extract command
    local command
    if command -v jq &>/dev/null; then
      command=$(echo "$tool_input" | jq -r '.command // empty' 2>/dev/null)
    else
      command=$(parse_json_field "$tool_input" ".command")
    fi
    
    if [ -n "$command" ]; then
      # Check if command is within scope
      if ! is_command_in_scope "$command"; then
        local reason
        reason=$(get_command_violation_reason "$command")
        
        log_event "BLOCKED" "Bash command - $reason"
        
        echo ""
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo "⚠️  COMMAND BOUNDARY VIOLATION"
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo ""
        echo "Command: ${command:0:100}..."
        echo ""
        echo "Reason: $reason"
        echo ""
        echo "This command exceeds the current task boundaries."
        echo "Consider breaking it into smaller, focused operations."
        echo ""
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo ""
        
        exit $EXIT_BLOCK
      fi
      
      log_event "ALLOWED" "Bash command (in scope)"
    fi
  fi
  
  # All other tools - allow
  exit $EXIT_ALLOW
}

# ============================================================================
# EXECUTION
# ============================================================================

main "$@"
