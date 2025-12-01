#!/usr/bin/env bash
#
# validate-spec-final.sh
# SpecKit Pre-Commit Quality Gate
#
# PURPOSE:
#   Final validation checkpoint before allowing spec folder commits.
#   Runs comprehensive quality checks and blocks commits with critical issues.
#
# VERSION: 1.0.0
# CREATED: 2025-11-24
# SPEC: specs/003-speckit-rework/003-template-enforcement/
#
# EXECUTION ORDER: PreToolUse hook (runs BEFORE tool execution)
#   1. UserPromptSubmit hooks (FIRST - before user prompt processing)
#   2. PreToolUse hooks (SECOND - before tool execution, validation) ← THIS HOOK
#   3. PostToolUse hooks (LAST - after tool completion, verification)
#
# EXIT CODE CONVENTION:
#   0 = Allow (validation passed, continue execution)
#   1 = Block (validation failed, stop execution with warning)
#   2 = Error (reserved for critical failures)
#
# VALIDATION MODES:
#   - standard: Block on critical errors, allow on warnings
#   - strict: Block on any errors or warnings (set STRICT_MODE=true)
#
# PERFORMANCE TARGET: <150ms total validation time
#

set -euo pipefail

# ============================================================================
# CONFIGURATION
# ============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" 2>/dev/null && pwd)"
HOOKS_DIR="$(cd "$SCRIPT_DIR/.." 2>/dev/null && pwd)"
REPO_ROOT=$(git rev-parse --show-toplevel 2>/dev/null || (cd "$SCRIPT_DIR/../.." && pwd))

# Load validation library
if [ -f "${REPO_ROOT}/.claude/hooks/lib/template-validation.sh" ]; then
  source "${REPO_ROOT}/.claude/hooks/lib/template-validation.sh"
  VALIDATION_LIB_LOADED=true
else
  # Validation library not available, allow commit
  exit 0
fi

# Load output helpers (optional)
if [ -f "${HOOKS_DIR}/lib/output-helpers.sh" ]; then
  source "${HOOKS_DIR}/lib/output-helpers.sh"
fi

# Configuration
STRICT_MODE="${STRICT_MODE:-false}"
VALIDATION_LEVEL="${VALIDATION_LEVEL:-standard}"

# ============================================================================
# HELPER FUNCTIONS
# ============================================================================

# print_section()
# PURPOSE: Print formatted section header
# ARGS: $1 - section title
print_section() {
  local title="$1"
  echo ""
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "$title"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
}

# detect_spec_folder()
# PURPOSE: Detect if current directory is a spec folder
# RETURNS: 0 if in spec folder, 1 if not
# OUTPUTS: Spec folder path to stdout
detect_spec_folder() {
  local current_dir="$(pwd)"

  # Check if current directory matches specs/###-name pattern
  if [[ "$current_dir" =~ specs/[0-9]{3}-[a-z-]+ ]]; then
    echo "$current_dir"
    return 0
  fi

  # Check if current directory is a subdirectory of a spec folder
  if [[ "$current_dir" =~ (specs/[0-9]{3}-[a-z-]+) ]]; then
    echo "${BASH_REMATCH[1]}"
    return 0
  fi

  return 1
}

# validate_all_template_sources()
# PURPOSE: Run template source validation on all spec files
# ARGS: $1 - spec folder path
# RETURNS: 0 if all valid, 1 if warnings found
validate_all_template_sources() {
  local spec_folder="$1"
  local has_warnings=false

  # Validate spec.md (if exists)
  if [ -f "${spec_folder}/spec.md" ]; then
    if ! validate_template_source "${spec_folder}/spec.md" "spec" 2>&1; then
      has_warnings=true
    fi
  fi

  # Validate plan.md (if exists)
  if [ -f "${spec_folder}/plan.md" ]; then
    if ! validate_template_source "${spec_folder}/plan.md" "plan" 2>&1; then
      has_warnings=true
    fi
  fi

  # Validate tasks.md (if exists)
  if [ -f "${spec_folder}/tasks.md" ]; then
    if ! validate_template_source "${spec_folder}/tasks.md" "tasks" 2>&1; then
      has_warnings=true
    fi
  fi

  # Validate README.md (if exists)
  if [ -f "${spec_folder}/README.md" ]; then
    if ! validate_template_source "${spec_folder}/README.md" "README" 2>&1; then
      has_warnings=true
    fi
  fi

  if [ "$has_warnings" = true ]; then
    return 1
  fi

  return 0
}

# validate_all_section_completeness()
# PURPOSE: Run section completeness validation on all spec files
# ARGS: $1 - spec folder path
# RETURNS: 0 if all complete, 1 if missing sections
validate_all_section_completeness() {
  local spec_folder="$1"
  local has_errors=false

  # Validate spec.md (if exists)
  if [ -f "${spec_folder}/spec.md" ]; then
    if ! validate_section_completeness "${spec_folder}/spec.md" "spec" 2>&1; then
      has_errors=true
    fi
  fi

  # Validate plan.md (if exists)
  if [ -f "${spec_folder}/plan.md" ]; then
    if ! validate_section_completeness "${spec_folder}/plan.md" "plan" 2>&1; then
      has_errors=true
    fi
  fi

  # Validate tasks.md (if exists)
  if [ -f "${spec_folder}/tasks.md" ]; then
    if ! validate_section_completeness "${spec_folder}/tasks.md" "tasks" 2>&1; then
      has_errors=true
    fi
  fi

  if [ "$has_errors" = true ]; then
    return 1
  fi

  return 0
}

# validate_all_content_adaptation()
# PURPOSE: Run content adaptation validation on all spec files
# ARGS: $1 - spec folder path
# RETURNS: 0 if adapted, 1 if placeholders remain
validate_all_content_adaptation() {
  local spec_folder="$1"
  local has_errors=false

  # Validate all markdown files in spec folder
  for file in "${spec_folder}"/*.md; do
    [ -f "$file" ] || continue

    if ! validate_content_adaptation "$file" 2>&1; then
      has_errors=true
    fi
  done

  if [ "$has_errors" = true ]; then
    return 1
  fi

  return 0
}

# validate_all_metadata()
# PURPOSE: Run metadata validation on all spec files with metadata
# ARGS: $1 - spec folder path
# RETURNS: 0 if valid, 1 if issues found
validate_all_metadata() {
  local spec_folder="$1"
  local has_warnings=false

  # Validate spec.md metadata (if exists)
  if [ -f "${spec_folder}/spec.md" ]; then
    if ! validate_metadata "${spec_folder}/spec.md" 2>&1; then
      has_warnings=true
    fi
  fi

  if [ "$has_warnings" = true ]; then
    return 1
  fi

  return 0
}

# ============================================================================
# MAIN VALIDATION LOGIC
# ============================================================================

main() {
  # Read JSON input from stdin (PreToolUse hooks receive tool input as JSON)
  INPUT=$(cat)

  # Extract file path from tool input (supports Edit, Write, Read tools)
  local file_path
  file_path=$(echo "$INPUT" | jq -r '.tool_input.file_path // .tool_input.path // .parameters.file_path // empty' 2>/dev/null)

  # Detect spec folder from file path or current directory
  local spec_folder
  if [ -n "$file_path" ] && [[ "$file_path" =~ specs/[0-9]{3}-[a-z-]+ ]]; then
    # Extract spec folder from file path
    spec_folder=$(echo "$file_path" | grep -oE 'specs/[0-9]{3}-[a-z-]+(/[0-9]{3}-[a-z-]+)?' | head -1)
    spec_folder="${REPO_ROOT}/${spec_folder}"
  else
    # Fallback to pwd-based detection
    spec_folder=$(detect_spec_folder 2>/dev/null) || spec_folder=""
  fi

  if [ -z "$spec_folder" ]; then
    # Not in spec folder, allow commit
    exit 0
  fi

  print_section "🔍 PRE-COMMIT VALIDATION: $(basename $spec_folder)"

  local error_count=0
  local warning_count=0

  # ========================================================================
  # P0 VALIDATION: Template Sources (WARNINGS)
  # ========================================================================

  echo "Checking template sources..."
  if ! validate_all_template_sources "$spec_folder"; then
    warning_count=$((warning_count + 1))
  fi

  # ========================================================================
  # P0 VALIDATION: Section Completeness (ERRORS)
  # ========================================================================

  echo "Checking section completeness..."
  if ! validate_all_section_completeness "$spec_folder"; then
    error_count=$((error_count + 1))
  fi

  # ========================================================================
  # P2 VALIDATION: Content Adaptation (ERRORS)
  # ========================================================================

  echo "Checking content adaptation..."
  if ! validate_all_content_adaptation "$spec_folder"; then
    error_count=$((error_count + 1))
  fi

  # ========================================================================
  # P1 VALIDATION: Metadata (WARNINGS)
  # ========================================================================

  echo "Checking metadata..."
  if ! validate_all_metadata "$spec_folder"; then
    warning_count=$((warning_count + 1))
  fi

  # ========================================================================
  # P1 VALIDATION: Traceability (WARNINGS)
  # ========================================================================

  echo "Checking traceability..."
  if ! validate_traceability "$spec_folder"; then
    warning_count=$((warning_count + 1))
  fi

  # ========================================================================
  # RESULTS REPORTING
  # ========================================================================

  echo ""
  print_section "VALIDATION RESULTS"

  if [ "$error_count" -eq 0 ] && [ "$warning_count" -eq 0 ]; then
    echo "✅ All validation checks passed!"
    echo ""
    echo "Spec folder quality: EXCELLENT"
    echo "  - All required sections present"
    echo "  - All placeholders replaced"
    echo "  - Metadata validated"
    echo "  - Traceability verified"
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    exit 0

  elif [ "$error_count" -eq 0 ]; then
    echo "⚠️  Validation passed with ${warning_count} warning(s)"
    echo ""
    echo "Spec folder quality: GOOD (with warnings)"
    echo "  - Required sections present"
    echo "  - Content adapted"
    echo "  - ${warning_count} warnings (see above)"
    echo ""

    if [ "$STRICT_MODE" = "true" ]; then
      echo "❌ BLOCKED: Strict mode treats warnings as errors"
      echo ""
      echo "To allow commit with warnings, set STRICT_MODE=false"
      echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
      exit 1
    else
      echo "Commit allowed (set STRICT_MODE=true to block on warnings)"
      echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
      exit 0
    fi

  else
    echo "❌ Validation failed with ${error_count} error(s) and ${warning_count} warning(s)"
    echo ""
    echo "Spec folder quality: NEEDS IMPROVEMENT"
    echo "  - ${error_count} critical error(s) found"
    echo "  - ${warning_count} warning(s) found"
    echo ""
    echo "Please fix the issues above before committing."
    echo ""
    echo "Common fixes:"
    echo "  - Missing sections: Add required sections to spec.md/plan.md"
    echo "  - Placeholders: Replace [YOUR_VALUE_HERE:...] with actual content"
    echo "  - Missing [NEEDS CLARIFICATION:...]: Resolve open questions"
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    exit 1
  fi
}

# ============================================================================
# EXECUTION
# ============================================================================

# Run main validation
main "$@"
