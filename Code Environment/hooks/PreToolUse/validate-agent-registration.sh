#!/usr/bin/env bash
# ==============================================================================
# validate-agent-registration.sh - PreToolUse hook for agent registration
# ==============================================================================
# Validates incoming agent registration data before allowing registration.
# Blocks invalid registrations with clear, actionable error messages.
#
# Trigger: Agent registration attempts (Task tool with registration data)
# Sources: registration-validation.sh for validation functions
#
# Exit Codes:
#   0 - Registration data valid, allow to proceed
#   1 - Invalid registration data, block with error
#   2 - Not a registration attempt, skip validation
# ==============================================================================

set -euo pipefail

# ------------------------------------------------------------------------------
# Setup
# ------------------------------------------------------------------------------
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HOOKS_DIR="$(dirname "$SCRIPT_DIR")"
LIB_DIR="${HOOKS_DIR}/lib"

# Source validation library
if [[ -f "${LIB_DIR}/registration-validation.sh" ]]; then
    # shellcheck source=../lib/registration-validation.sh
    source "${LIB_DIR}/registration-validation.sh"
else
    echo "ERROR: registration-validation.sh not found at ${LIB_DIR}" >&2
    exit 1
fi

# Source output helpers if available
if [[ -f "${LIB_DIR}/output-helpers.sh" ]]; then
    # shellcheck source=../lib/output-helpers.sh
    source "${LIB_DIR}/output-helpers.sh"
fi

# ------------------------------------------------------------------------------
# Parse hook input
# ------------------------------------------------------------------------------
# Read input from stdin (Claude hook format)
INPUT=""
if [[ -p /dev/stdin ]]; then
    INPUT=$(cat)
fi

# Also check for command line argument
TOOL_NAME="${1:-}"
TOOL_INPUT="${2:-$INPUT}"

# ------------------------------------------------------------------------------
# Check if this is a registration attempt
# ------------------------------------------------------------------------------
is_registration_attempt() {
    local input="${1:-}"
    
    # Check for registration-related patterns in Task tool calls
    if [[ "$TOOL_NAME" == "Task" || "$TOOL_NAME" == "task" ]]; then
        # Look for agent registration patterns
        if echo "$input" | grep -qiE "(register.*agent|agent.*registration|---.*agent_id|yaml.*frontmatter.*agent)"; then
            return 0
        fi
    fi
    
    # Check for direct registration function calls
    if echo "$input" | grep -qE "(register_agent|validate_registration)"; then
        return 0
    fi
    
    # Check for YAML frontmatter with agent fields
    if echo "$input" | grep -qE "^---" && echo "$input" | grep -qE "(agent_id:|role:|capabilities:)"; then
        return 0
    fi
    
    return 1
}

# ------------------------------------------------------------------------------
# Extract registration data from input
# ------------------------------------------------------------------------------
extract_registration_data() {
    local input="${1:-}"
    
    # Try to extract key=value pairs
    echo "$input" | grep -E "^[a-zA-Z_][a-zA-Z0-9_]*=" 2>/dev/null || true
    
    # Try to extract from YAML frontmatter format
    if echo "$input" | grep -qE "^---"; then
        # Parse simple YAML-like structure
        echo "$input" | grep -E "^[a-zA-Z_][a-zA-Z0-9_]*:" | while read -r line; do
            key=$(echo "$line" | cut -d: -f1)
            value=$(echo "$line" | cut -d: -f2- | sed 's/^[[:space:]]*//')
            echo "${key}=${value}"
        done
    fi
}

# ------------------------------------------------------------------------------
# Main validation logic
# ------------------------------------------------------------------------------
main() {
    # Skip if not a registration attempt
    if ! is_registration_attempt "$TOOL_INPUT"; then
        exit 0  # Not our concern, allow to proceed
    fi
    
    # Extract registration data
    local reg_data
    reg_data=$(extract_registration_data "$TOOL_INPUT")
    
    if [[ -z "$reg_data" ]]; then
        # Could be a registration attempt but no parseable data
        # Let it through - the actual registration function will handle it
        exit 0
    fi
    
    # Run full validation
    local validation_result
    local error_code
    
    # Capture validation result
    set +e
    run_full_validation "$reg_data" 2>/dev/null
    error_code=$?
    set -e
    
    if [[ $error_code -ne 0 ]]; then
        # Get human-readable error message
        local error_msg
        error_msg=$(get_validation_error_message "$error_code")
        
        # Output structured error for Claude hooks
        cat << EOF
{
    "action": "block",
    "reason": "Agent registration validation failed",
    "error_code": $error_code,
    "error_message": "$error_msg",
    "suggestion": "Please correct the registration data and try again."
}
EOF
        
        # Also output to stderr for visibility
        echo "BLOCKED: Agent registration validation failed" >&2
        echo "Error Code: $error_code" >&2
        echo "Error: $error_msg" >&2
        
        exit 1
    fi
    
    # Validation passed
    exit 0
}

# ------------------------------------------------------------------------------
# Run main function
# ------------------------------------------------------------------------------
main "$@"
