#!/usr/bin/env bash
# ==============================================================================
# enforce-phase-checkpoints.sh - PreToolUse Hook for Phase-Based Enforcement
# ==============================================================================
# Enforces workflow phase checkpoints by checking if the current tool operation
# is appropriate for the current workflow phase. Blocks operations that would
# skip required phases.
#
# Version: 1.0.0
# Task: T058
# Agent: Agent 6 (Blocking-Hook)
#
# Phase-Tool Mapping:
#   Read/Grep/Glob    → research or any (always allowed)
#   Write to specs/   → planning (requires init/research complete)
#   Write to src/     → implement (requires planning complete)
#   Bash with test    → review (requires implement complete)
#   Git commit        → review (requires all checks passed)
#
# Exit codes:
#   0 - Allow tool execution
#   1 - Block tool execution (phase conditions not met)
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
LOG_FILE="${LOG_DIR}/phase-checkpoints.log"

# ==============================================================================
# Source Guard and Library Loading
# ==============================================================================

[[ -n "${_ENFORCE_PHASE_CHECKPOINTS_LOADED:-}" ]] && exit 0
readonly _ENFORCE_PHASE_CHECKPOINTS_LOADED=1

# Ensure log directory exists
mkdir -p "${LOG_DIR}" 2>/dev/null || true

# Source workflow-statemachine.sh for get_current_state()
if [[ -f "${LIB_DIR}/workflow-statemachine.sh" ]]; then
    # shellcheck source=/dev/null
    source "${LIB_DIR}/workflow-statemachine.sh"
else
    # Cannot enforce without state machine - allow all
    echo "[phase-checkpoints] WARN: workflow-statemachine.sh not found, skipping checks" >&2
    exit 0
fi

# Source phase-transitions.sh for check_phase_prerequisites()
if [[ -f "${LIB_DIR}/phase-transitions.sh" ]]; then
    # shellcheck source=/dev/null
    source "${LIB_DIR}/phase-transitions.sh"
fi

# ==============================================================================
# Logging Function
# ==============================================================================

_log() {
    local level="${1:-INFO}"
    local message="${2:-}"
    local timestamp
    timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
    echo "[${timestamp}] [${level}] [phase-checkpoints] ${message}" >> "${LOG_FILE}" 2>/dev/null || true
}

# ==============================================================================
# Phase Implication Logic
# ==============================================================================

# Determine what phase a tool operation implies based on tool name and input
# Returns: phase name or "any" if tool doesn't imply a specific phase
get_implied_phase() {
    local tool_name="${1:-}"
    local tool_input="${2:-}"
    
    case "${tool_name}" in
        Read|Grep|Glob|List)
            # Read operations are always allowed (research or any phase)
            echo "any"
            ;;
        Write|Edit)
            # Check what's being written
            if [[ "${tool_input}" =~ specs/ ]]; then
                # Writing to specs implies planning phase
                echo "planning"
            elif [[ "${tool_input}" =~ (src/|\.claude/hooks/|\.sh$|\.js$|\.ts$|\.css$|\.html$) ]]; then
                # Writing to source code implies implement phase
                echo "implement"
            else
                # Other writes could be any phase
                echo "any"
            fi
            ;;
        Bash)
            # Check command content
            if [[ "${tool_input}" =~ (npm\ test|bats|jest|pytest|test\.sh|run.*test) ]]; then
                # Running tests implies review phase
                echo "review"
            elif [[ "${tool_input}" =~ (git\ commit|git\ push) ]]; then
                # Git operations require review phase
                echo "review"
            else
                # General bash commands allowed in any phase
                echo "any"
            fi
            ;;
        Task)
            # Task tool (sub-agents) - check for commit-related tasks
            if [[ "${tool_input}" =~ (commit|push|deploy) ]]; then
                echo "review"
            else
                echo "any"
            fi
            ;;
        *)
            # Unknown tools - allow by default
            echo "any"
            ;;
    esac
}

# Check if transition from current phase to implied phase is valid
# Returns: 0 if allowed, 1 if blocked
check_phase_transition_allowed() {
    local current_phase="${1:-}"
    local implied_phase="${2:-}"
    
    # "any" is always allowed
    [[ "${implied_phase}" == "any" ]] && return 0
    
    # Same phase is always allowed
    [[ "${current_phase}" == "${implied_phase}" ]] && return 0
    
    # Check the phase order
    local -A phase_order=(
        ["init"]=0
        ["research"]=1
        ["planning"]=2
        ["implement"]=3
        ["review"]=4
        ["complete"]=5
    )
    
    local current_order="${phase_order[${current_phase}]:-0}"
    local implied_order="${phase_order[${implied_phase}]:-0}"
    
    # Going backwards is generally allowed (refinement loops)
    # But jumping forward requires proper transitions
    
    if [[ ${implied_order} -gt ${current_order} ]]; then
        # Trying to skip ahead - check if transition is valid
        case "${current_phase}:${implied_phase}" in
            init:research|research:planning|planning:implement|implement:review|review:complete)
                # Valid adjacent transitions
                return 0
                ;;
            research:implement)
                # Skipping planning - not allowed
                return 1
                ;;
            planning:review)
                # Skipping implement - not allowed
                return 1
                ;;
            init:implement|init:review)
                # Major skips from init - not allowed
                return 1
                ;;
            *)
                # Other forward transitions need validation
                if command -v validate_transition &>/dev/null; then
                    validate_transition "${current_phase}" "${implied_phase}" 2>/dev/null
                    return $?
                fi
                # Default: allow if no validation function
                return 0
                ;;
        esac
    fi
    
    # Backwards or same-level - allowed
    return 0
}

# Get blocking summary for a phase transition
get_blocking_summary() {
    local current_phase="${1:-}"
    local implied_phase="${2:-}"
    local summary=""
    
    case "${current_phase}:${implied_phase}" in
        init:planning)
            summary="Cannot start planning without research phase. Gather context first."
            ;;
        init:implement)
            summary="Cannot implement without research and planning phases. Create spec first."
            ;;
        research:implement)
            summary="Cannot implement without planning phase. Create spec.md, plan.md, tasks.md first."
            ;;
        planning:review)
            summary="Cannot review without implementation phase. Write code first."
            ;;
        init:review)
            summary="Cannot review without preceding phases. Complete research, planning, and implementation first."
            ;;
        *)
            summary="Phase transition from '${current_phase}' to '${implied_phase}' is not allowed."
            ;;
    esac
    
    echo "${summary}"
}

# Get next steps suggestion
get_next_steps() {
    local current_phase="${1:-}"
    
    case "${current_phase}" in
        init)
            echo "Start by reading code and gathering context (research phase)."
            ;;
        research)
            echo "Create spec.md, plan.md, and tasks.md to enter planning phase."
            ;;
        planning)
            echo "Finish planning documents, then start implementation."
            ;;
        implement)
            echo "Complete code changes, then run tests to enter review phase."
            ;;
        review)
            echo "Address any failing tests or checklist items, then complete workflow."
            ;;
        complete)
            echo "Workflow complete. Start a new workflow with 'init' if needed."
            ;;
        *)
            echo "Check current phase with get_current_state()."
            ;;
    esac
}

# ==============================================================================
# Main Hook Logic
# ==============================================================================

main() {
    local tool_name="${CLAUDE_TOOL_NAME:-}"
    local tool_input="${CLAUDE_TOOL_INPUT:-}"
    
    # Skip if no tool name (shouldn't happen but be defensive)
    if [[ -z "${tool_name}" ]]; then
        _log "WARN" "No tool name provided, allowing execution"
        exit 0
    fi
    
    _log "INFO" "Checking tool: ${tool_name}"
    
    # Get current workflow phase
    local current_phase
    current_phase=$(get_current_state 2>/dev/null || echo "init")
    _log "INFO" "Current phase: ${current_phase}"
    
    # Determine what phase this tool implies
    local implied_phase
    implied_phase=$(get_implied_phase "${tool_name}" "${tool_input}")
    _log "INFO" "Implied phase for ${tool_name}: ${implied_phase}"
    
    # If tool implies "any" phase, always allow
    if [[ "${implied_phase}" == "any" ]]; then
        _log "INFO" "Tool ${tool_name} allowed in any phase"
        exit 0
    fi
    
    # Check if the transition is allowed
    if check_phase_transition_allowed "${current_phase}" "${implied_phase}"; then
        _log "INFO" "Phase transition allowed: ${current_phase} -> ${implied_phase}"
        exit 0
    else
        # Block the operation
        _log "WARN" "BLOCKED: ${current_phase} -> ${implied_phase} for ${tool_name}"
        
        local summary
        summary=$(get_blocking_summary "${current_phase}" "${implied_phase}")
        
        local next_steps
        next_steps=$(get_next_steps "${current_phase}")
        
        # Output blocking message
        cat >&2 <<EOF

╔══════════════════════════════════════════════════════════════════════════════╗
║                      PHASE CHECKPOINT BLOCKED                                 ║
╠══════════════════════════════════════════════════════════════════════════════╣
║ Cannot proceed: phase transition blocked                                      ║
╠══════════════════════════════════════════════════════════════════════════════╣
║ Current phase:  ${current_phase}
║ Required phase: ${implied_phase}
║ Tool:           ${tool_name}
╠══════════════════════════════════════════════════════════════════════════════╣
║ Reason:                                                                       ║
║   ${summary}
╠══════════════════════════════════════════════════════════════════════════════╣
║ Next steps:                                                                   ║
║   ${next_steps}
╠══════════════════════════════════════════════════════════════════════════════╣
║ To bypass (emergency): export FORCE_TRANSITION=1                              ║
╚══════════════════════════════════════════════════════════════════════════════╝

EOF
        
        # Check for bypass flag
        if [[ "${FORCE_TRANSITION:-}" == "1" ]]; then
            _log "WARN" "BYPASS: Force transition enabled, allowing blocked operation"
            echo "[phase-checkpoints] WARNING: Bypassing phase checkpoint (FORCE_TRANSITION=1)" >&2
            exit 0
        fi
        
        exit 1
    fi
}

# ==============================================================================
# Execute Main
# ==============================================================================

main "$@"
