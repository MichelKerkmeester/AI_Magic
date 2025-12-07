#!/usr/bin/env bash
# ==============================================================================
# enforce-capabilities.sh - PreToolUse hook for capability boundary enforcement
# ==============================================================================
# Enforces that agents only use tools they have capabilities for.
# Maps tool names to capabilities and validates against agent's registered caps.
#
# Environment:
#   CLAUDE_TOOL_NAME  - The tool being called (Read, Write, Bash, etc.)
#   CLAUDE_TOOL_INPUT - JSON of tool parameters
#   AGENT_ID          - Current agent identifier (optional)
#
# Exit Codes:
#   0  - Tool allowed (passes check or orchestrator mode)
#   1  - Tool blocked (capability violation)
#
# Usage:
#   Called automatically by Claude Code as PreToolUse hook
# ==============================================================================

# Source guard - prevent multiple loading in same shell
[[ -n "${_ENFORCE_CAPABILITIES_LOADED:-}" ]] && exit 0

set -euo pipefail

# ==============================================================================
# Configuration
# ==============================================================================
HOOKS_DIR="${HOOKS_DIR:-.claude/hooks}"
LIB_DIR="${HOOKS_DIR}/lib"
LOG_DIR="${HOOKS_DIR}/logs"
LOG_FILE="${LOG_DIR}/capability-enforcement.log"

# Debug mode - set CAPABILITY_DEBUG=1 to enable verbose logging
DEBUG="${CAPABILITY_DEBUG:-0}"

# ==============================================================================
# Logging Functions
# ==============================================================================
log_debug() {
    [[ "$DEBUG" == "1" ]] || return 0
    local msg="$1"
    local timestamp
    timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
    mkdir -p "$LOG_DIR" 2>/dev/null || true
    echo "[$timestamp] [DEBUG] $msg" >> "$LOG_FILE" 2>/dev/null || true
}

log_info() {
    local msg="$1"
    local timestamp
    timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
    mkdir -p "$LOG_DIR" 2>/dev/null || true
    echo "[$timestamp] [INFO] $msg" >> "$LOG_FILE" 2>/dev/null || true
}

log_error() {
    local msg="$1"
    local timestamp
    timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
    mkdir -p "$LOG_DIR" 2>/dev/null || true
    echo "[$timestamp] [ERROR] $msg" >> "$LOG_FILE" 2>/dev/null || true
    echo "ERROR: $msg" >&2
}

# ==============================================================================
# Tool-to-Capability Mapping
# ==============================================================================
# Maps Claude Code tools to capability identifiers from the master list.
# See capability-utils.sh for the complete ALLOWED_CAPABILITIES list.
#
# Mapping Table:
# ┌─────────────────────┬───────────────────┬─────────────────────────────────┐
# │ Tool Name           │ Capability        │ Notes                           │
# ├─────────────────────┼───────────────────┼─────────────────────────────────┤
# │ Read                │ file_read         │ Reading file contents           │
# │ Glob                │ file_read         │ File pattern matching           │
# │ Grep                │ file_read         │ Content search                  │
# │ List                │ file_read         │ Directory listing               │
# │ Write               │ file_write        │ Creating/overwriting files      │
# │ Edit                │ file_edit         │ Modifying file contents         │
# │ Bash                │ bash_execute*     │ *Or bash_readonly based on cmd  │
# │ WebFetch            │ web_fetch         │ HTTP requests                   │
# │ Task                │ create_agent      │ Spawning sub-agents             │
# │ TodoRead            │ file_read         │ Reading todo state              │
# │ TodoWrite           │ file_write        │ Writing todo state              │
# │ semantic_search_*   │ search_semantic   │ Semantic code search            │
# │ code_mode_*         │ search_code       │ Code mode operations            │
# │ sequential_thinking │ search_code       │ Reasoning tool                  │
# └─────────────────────┴───────────────────┴─────────────────────────────────┘
# ==============================================================================

map_tool_to_capability() {
    local tool_name="${1:-}"
    local tool_input="${2:-}"
    
    case "$tool_name" in
        # File reading operations
        Read|Glob|Grep|List|TodoRead)
            echo "file_read"
            ;;
        
        # File writing operations
        Write|TodoWrite)
            echo "file_write"
            ;;
        
        # File editing operations
        Edit)
            echo "file_edit"
            ;;
        
        # Bash execution - check if readonly or full execute
        Bash)
            # Determine if command is readonly or modifying
            local capability
            capability=$(classify_bash_command "$tool_input")
            echo "$capability"
            ;;
        
        # Web operations
        WebFetch)
            echo "web_fetch"
            ;;
        
        # Agent creation
        Task)
            echo "create_agent"
            ;;
        
        # Semantic search tools (MCP)
        semantic_search_*|mcp_semantic_*)
            echo "search_semantic"
            ;;
        
        # Code mode tools
        code_mode_*)
            echo "search_code"
            ;;
        
        # Sequential thinking
        sequential_thinking_*)
            echo "search_code"
            ;;
        
        # Git operations - check command type
        git_*)
            # Most git operations are read, but push/commit/merge are write
            if [[ "$tool_name" =~ (push|commit|merge|rebase|reset|checkout) ]]; then
                echo "git_write"
            else
                echo "git_read"
            fi
            ;;
        
        # Checkpoint operations
        checkpoint_create|create_checkpoint)
            echo "create_checkpoint"
            ;;
        
        checkpoint_load|load_checkpoint)
            echo "load_checkpoint"
            ;;
        
        # Prune tool - no special capability needed, allow
        prune)
            echo "ALLOW_ALL"
            ;;
        
        # Unknown tools - log warning and allow by default
        *)
            log_debug "Unknown tool '$tool_name' - defaulting to ALLOW_ALL"
            echo "ALLOW_ALL"
            ;;
    esac
}

# ==============================================================================
# Bash Command Classification
# ==============================================================================
# Classifies bash commands as readonly or modifying to map to appropriate capability

classify_bash_command() {
    local tool_input="${1:-}"
    
    # Extract command from JSON input
    local command=""
    if [[ -n "$tool_input" ]]; then
        command=$(echo "$tool_input" | jq -r '.command // empty' 2>/dev/null || echo "")
    fi
    
    # If we can't parse the command, default to bash_execute (safer)
    if [[ -z "$command" ]]; then
        echo "bash_execute"
        return
    fi
    
    # List of readonly commands (safe operations)
    local readonly_patterns=(
        "^ls"
        "^cat"
        "^head"
        "^tail"
        "^less"
        "^more"
        "^grep"
        "^rg"
        "^find"
        "^which"
        "^whereis"
        "^type"
        "^file"
        "^stat"
        "^wc"
        "^du"
        "^df"
        "^pwd"
        "^echo"
        "^printf"
        "^date"
        "^whoami"
        "^id"
        "^env"
        "^printenv"
        "^git status"
        "^git log"
        "^git diff"
        "^git show"
        "^git branch"
        "^git remote"
        "^npm list"
        "^npm ls"
        "^yarn list"
        "^node --version"
        "^npm --version"
        "^python --version"
        "^pip list"
    )
    
    # Check if command matches any readonly pattern
    local pattern
    for pattern in "${readonly_patterns[@]}"; do
        if [[ "$command" =~ $pattern ]]; then
            echo "bash_readonly"
            return
        fi
    done
    
    # Default to bash_execute for modifying commands
    echo "bash_execute"
}

# ==============================================================================
# Agent Detection
# ==============================================================================
# Attempts to detect the current agent ID from various sources

get_current_agent_id() {
    # 1. Check environment variable (most reliable when set)
    if [[ -n "${AGENT_ID:-}" ]]; then
        echo "$AGENT_ID"
        return 0
    fi
    
    # 2. Check Claude-specific environment
    if [[ -n "${CLAUDE_AGENT_ID:-}" ]]; then
        echo "$CLAUDE_AGENT_ID"
        return 0
    fi
    
    # 3. Check for task context file
    local task_context="${CLAUDE_STATE_DIR:-${TMPDIR:-/tmp}/claude_hooks_state}/current_agent"
    if [[ -f "$task_context" ]]; then
        local agent_id
        agent_id=$(cat "$task_context" 2>/dev/null)
        if [[ -n "$agent_id" ]]; then
            echo "$agent_id"
            return 0
        fi
    fi
    
    # 4. No agent context found - this is orchestrator mode
    return 1
}

# ==============================================================================
# Main Hook Logic
# ==============================================================================
main() {
    local tool_name="${CLAUDE_TOOL_NAME:-}"
    local tool_input="${CLAUDE_TOOL_INPUT:-}"
    
    log_debug "Hook invoked: tool='$tool_name'"
    
    # Early exit if no tool name
    if [[ -z "$tool_name" ]]; then
        log_debug "No tool name provided, allowing"
        exit 0
    fi
    
    # Source capability-utils.sh
    if [[ -f "${LIB_DIR}/capability-utils.sh" ]]; then
        # shellcheck source=lib/capability-utils.sh
        source "${LIB_DIR}/capability-utils.sh"
        log_debug "Sourced capability-utils.sh"
    else
        # Graceful degradation - if library missing, warn and allow
        log_info "capability-utils.sh not found at ${LIB_DIR}/capability-utils.sh - allowing tool"
        echo "WARN: capability-utils.sh not found, skipping capability check" >&2
        exit 0
    fi
    
    # Get current agent ID
    local agent_id
    if ! agent_id=$(get_current_agent_id); then
        # No agent context - orchestrator mode, allow all
        log_debug "No agent context (orchestrator mode) - allowing tool"
        exit 0
    fi
    
    log_debug "Agent ID: $agent_id"
    
    # Map tool to capability
    local required_capability
    required_capability=$(map_tool_to_capability "$tool_name" "$tool_input")
    
    log_debug "Tool '$tool_name' requires capability: $required_capability"
    
    # Special case: ALLOW_ALL means no restriction
    if [[ "$required_capability" == "ALLOW_ALL" ]]; then
        log_debug "Tool '$tool_name' has ALLOW_ALL - no capability check needed"
        exit 0
    fi
    
    # Check capability boundary
    local check_result
    if check_result=$(check_capability_boundary "$agent_id" "$required_capability" 2>&1); then
        # Capability allowed
        log_info "ALLOWED: Agent '$agent_id' used tool '$tool_name' (capability: $required_capability)"
        exit 0
    else
        local exit_code=$?
        
        # Handle different error codes
        case $exit_code in
            12)
                # Capability violation - block the tool
                log_error "BLOCKED: Agent '$agent_id' attempted '$tool_name' without '$required_capability' capability"
                echo "" >&2
                echo "╔══════════════════════════════════════════════════════════════════╗" >&2
                echo "║  🚫 CAPABILITY VIOLATION - TOOL BLOCKED                          ║" >&2
                echo "╠══════════════════════════════════════════════════════════════════╣" >&2
                echo "║  Agent:      $agent_id" >&2
                echo "║  Tool:       $tool_name" >&2
                echo "║  Required:   $required_capability" >&2
                echo "║                                                                  ║" >&2
                echo "║  This agent does not have permission to use this tool.           ║" >&2
                echo "║  Contact the orchestrator to escalate this operation.           ║" >&2
                echo "╚══════════════════════════════════════════════════════════════════╝" >&2
                exit 1
                ;;
            
            11)
                # Invalid capability - this is a config error, log but allow
                log_error "CONFIG ERROR: '$required_capability' is not a valid capability"
                echo "WARN: Invalid capability mapping for tool '$tool_name'" >&2
                exit 0
                ;;
            
            1)
                # Agent not found in registry - might be new agent, allow with warning
                log_info "Agent '$agent_id' not in registry - allowing tool (new agent grace period)"
                exit 0
                ;;
            
            *)
                # Unknown error - allow with warning
                log_error "Unknown error ($exit_code) checking capabilities: $check_result"
                exit 0
                ;;
        esac
    fi
}

# Run main function
main "$@"
