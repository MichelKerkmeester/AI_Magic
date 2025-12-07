#!/usr/bin/env bash
# ==============================================================================
# validate-completion-checklist.sh - PreToolUse Hook for Checklist Validation
# ==============================================================================
# Validates that phase checklist requirements are met before marking tasks
# as complete. Blocks completion claims when P0 items are incomplete and
# warns when P1 items are incomplete.
#
# Version: 1.0.0
# Task: T153 (US-021)
# Agent: Checklist Verification Hook
#
# Trigger conditions:
#   - Tool is Task with completion-related patterns
#   - Tool is Bash with git commit patterns
#   - Tool is Write with memory/context files
#
# Exit codes:
#   0 - Allow tool execution
#   1 - Block tool execution (P0 items incomplete)
# ==============================================================================

set -euo pipefail

# ==============================================================================
# Configuration
# ==============================================================================

HOOK_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIB_DIR="$(cd "${HOOK_DIR}/../lib" && pwd)"
WORKSPACE_ROOT="${WORKSPACE_ROOT:-$(cd "${HOOK_DIR}/../../.." && pwd)}"

# Export for library functions
export WORKSPACE_ROOT

# Log file
LOG_DIR="${HOOK_DIR}/../logs"
LOG_FILE="${LOG_DIR}/validate-completion-checklist.log"

# ==============================================================================
# Source Guard
# ==============================================================================

if [ -n "${_VALIDATE_COMPLETION_CHECKLIST_LOADED:-}" ]; then
    exit 0
fi
_VALIDATE_COMPLETION_CHECKLIST_LOADED=1

# Ensure log directory exists
mkdir -p "${LOG_DIR}" 2>/dev/null || true

# ==============================================================================
# Library Loading
# ==============================================================================

# Source checklist-verification.sh
if [ -f "${LIB_DIR}/checklist-verification.sh" ]; then
    # shellcheck source=/dev/null
    . "${LIB_DIR}/checklist-verification.sh"
else
    # Cannot enforce without library - allow all
    echo "[validate-completion-checklist] WARN: checklist-verification.sh not found, skipping checks" >&2
    exit 0
fi

# Source workflow-statemachine.sh for get_current_state()
if [ -f "${LIB_DIR}/workflow-statemachine.sh" ]; then
    # shellcheck source=/dev/null
    . "${LIB_DIR}/workflow-statemachine.sh" 2>/dev/null || true
fi

# ==============================================================================
# Logging Function
# ==============================================================================

_log() {
    local level="${1:-INFO}"
    local message="${2:-}"
    local timestamp
    timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
    echo "[${timestamp}] [${level}] [validate-completion-checklist] ${message}" >> "${LOG_FILE}" 2>/dev/null || true
}

# ==============================================================================
# Detection Functions
# ==============================================================================

# Detect if tool operation suggests task completion
is_completion_operation() {
    local tool_name="${1:-}"
    local tool_input="${2:-}"
    
    # Check for completion keywords in tool input
    case "$tool_input" in
        *"complete"*|*"done"*|*"finish"*|*"COMPLETE"*|*"DONE"*|*"FINISH"*)
            return 0
            ;;
    esac
    
    # Check for specific tool patterns
    case "$tool_name" in
        Bash)
            # Git commit suggests phase completion
            case "$tool_input" in
                *"git commit"*|*"git push"*)
                    return 0
                    ;;
            esac
            ;;
        Task)
            # Task tool with completion messaging
            case "$tool_input" in
                *"mark"*"complete"*|*"task"*"done"*|*"finish"*"task"*)
                    return 0
                    ;;
            esac
            ;;
        Write)
            # Writing to memory context (completion artifact)
            case "$tool_input" in
                *"/memory/"*|*"context"*".md"*|*"handover"*".md"*)
                    return 0
                    ;;
            esac
            ;;
    esac
    
    return 1
}

# Determine current phase from tool context or state
detect_current_phase() {
    local tool_input="${1:-}"
    local phase=""
    
    # Try to get phase from workflow state machine
    if command -v get_current_state >/dev/null 2>&1; then
        local state
        state=$(get_current_state 2>/dev/null || echo "")
        if [ -n "$state" ]; then
            # Map state to checklist phase name
            case "$state" in
                research) phase="research" ;;
                planning) phase="planning" ;;
                implement) phase="implementation" ;;
                review) phase="review" ;;
            esac
        fi
    fi
    
    # If no phase from state machine, fallback to tool input detection
    if [ -z "$phase" ]; then
        case "$tool_input" in
            *"research"*) phase="research" ;;
            *"planning"*|*"plan"*) phase="planning" ;;
            *"implement"*|*"code"*|*"develop"*) phase="implementation" ;;
            *"review"*|*"test"*|*"commit"*) phase="review" ;;
        esac
    fi
    
    echo "$phase"
}

# ==============================================================================
# Display Functions
# ==============================================================================

display_blocking_message() {
    local phase="${1:-}"
    local incomplete_items="${2:-}"
    
    cat >&2 <<EOF

╔══════════════════════════════════════════════════════════════════════════════╗
║                    COMPLETION BLOCKED - CHECKLIST INCOMPLETE                  ║
╠══════════════════════════════════════════════════════════════════════════════╣
║ Cannot mark task complete: P0 checklist items are not verified                ║
╠══════════════════════════════════════════════════════════════════════════════╣
║ Phase: ${phase}
║ 
║ Incomplete P0/P1 items:
EOF
    
    # Display each incomplete item
    echo "$incomplete_items" | while IFS= read -r item; do
        if [ -n "$item" ]; then
            echo "║   $item" >&2
        fi
    done
    
    cat >&2 <<EOF
╠══════════════════════════════════════════════════════════════════════════════╣
║ Action required:                                                              ║
║   1. Complete all P0 (Critical) items before marking done                     ║
║   2. Address P1 items or get explicit deferral approval                       ║
║   3. Use verify_checklist_item() to mark items with evidence                  ║
╠══════════════════════════════════════════════════════════════════════════════╣
║ To bypass (emergency): export SKIP_CHECKLIST_VALIDATION=1                     ║
╚══════════════════════════════════════════════════════════════════════════════╝

EOF
}

display_warning_message() {
    local phase="${1:-}"
    local incomplete_items="${2:-}"
    
    cat >&2 <<EOF

╔══════════════════════════════════════════════════════════════════════════════╗
║                    WARNING: P1 CHECKLIST ITEMS INCOMPLETE                     ║
╠══════════════════════════════════════════════════════════════════════════════╣
║ Phase: ${phase}
║ 
║ Incomplete P1 items:
EOF
    
    echo "$incomplete_items" | while IFS= read -r item; do
        if [ -n "$item" ]; then
            echo "║   $item" >&2
        fi
    done
    
    cat >&2 <<EOF
╠══════════════════════════════════════════════════════════════════════════════╣
║ Recommendation: Address these items or document deferral reason              ║
╚══════════════════════════════════════════════════════════════════════════════╝

EOF
}

# ==============================================================================
# Main Hook Logic
# ==============================================================================

main() {
    local tool_name="${CLAUDE_TOOL_NAME:-}"
    local tool_input="${CLAUDE_TOOL_INPUT:-}"
    
    # Skip if no tool name
    if [ -z "$tool_name" ]; then
        _log "WARN" "No tool name provided, skipping checks"
        exit 0
    fi
    
    _log "INFO" "Checking tool: $tool_name"
    
    # Check for bypass flag
    if [ "${SKIP_CHECKLIST_VALIDATION:-}" = "1" ]; then
        _log "WARN" "BYPASS: Checklist validation skipped (SKIP_CHECKLIST_VALIDATION=1)"
        echo "[validate-completion-checklist] WARNING: Bypassing checklist validation" >&2
        exit 0
    fi
    
    # Check if this is a completion operation
    if ! is_completion_operation "$tool_name" "$tool_input"; then
        _log "INFO" "Not a completion operation, allowing"
        exit 0
    fi
    
    _log "INFO" "Detected completion operation"
    
    # Detect current phase
    local phase
    phase=$(detect_current_phase "$tool_input")
    
    if [ -z "$phase" ]; then
        _log "INFO" "Could not detect phase, skipping checklist check"
        exit 0
    fi
    
    _log "INFO" "Current phase: $phase"
    
    # Check if phase is complete
    if is_phase_complete "$phase"; then
        _log "INFO" "Phase $phase checklist is complete"
        exit 0
    fi
    
    # Get incomplete items
    local incomplete_items
    incomplete_items=$(get_incomplete_items "$phase" 2>/dev/null || echo "")
    
    # Check for P0 incomplete items (blocking)
    local has_p0_incomplete=0
    if echo "$incomplete_items" | grep -q "^\[P0\]"; then
        has_p0_incomplete=1
    fi
    
    if [ "$has_p0_incomplete" -eq 1 ]; then
        _log "WARN" "BLOCKED: P0 items incomplete for phase $phase"
        display_blocking_message "$phase" "$incomplete_items"
        exit 1
    fi
    
    # Check for P1 incomplete items (warning only)
    if echo "$incomplete_items" | grep -q "^\[P1\]"; then
        _log "WARN" "WARNING: P1 items incomplete for phase $phase"
        display_warning_message "$phase" "$incomplete_items"
        # Allow but warn
    fi
    
    _log "INFO" "Checklist validation passed for phase: $phase"
    exit 0
}

# ==============================================================================
# Execute Main
# ==============================================================================

main "$@"
