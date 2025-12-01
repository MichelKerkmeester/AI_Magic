#!/bin/bash

# ───────────────────────────────────────────────────────────────
# MARKDOWN NAMING ENFORCEMENT HOOK (UNIFIED)
# ───────────────────────────────────────────────────────────────
# PostToolUse hook to enforce markdown filename conventions for
# both direct file operations (Write/Edit) AND Task tool completion.
#
# MERGED FROM:
# - enforce-markdown-post.sh (Write/Edit tool enforcement)
# - enforce-markdown-post-task.sh (Task tool post-scan)
#
# DETECTS AND AUTO-CORRECTS:
# - ALL CAPS filenames (except exceptions)
# - Hyphen-separated names
# - camelCase/PascalCase names
#
# ENFORCES: lowercase snake_case only (e.g., document_name.md)
#
# PERFORMANCE TARGET: <200ms (direct), <500ms (Task scan)
# COMPATIBILITY: Bash 3.2+ (macOS and Linux compatible)
#
# EXIT CODE CONVENTION:
#   0 = Allow (hook passed, continue execution)
#   1 = Block (hook failed, stop execution with warning)
#   2 = Error (reserved for critical failures)
# ───────────────────────────────────────────────────────────────

# Source libraries
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" 2>/dev/null && pwd)"
HOOKS_DIR="$(cd "$SCRIPT_DIR/.." 2>/dev/null && pwd)"
LIB_DIR="$HOOKS_DIR/lib"

# Source output helpers
if [[ -f "$LIB_DIR/output-helpers.sh" ]]; then
    source "$LIB_DIR/output-helpers.sh"
fi

# Source markdown naming library (if available)
if [[ -f "$LIB_DIR/markdown-naming.sh" ]]; then
    source "$LIB_DIR/markdown-naming.sh"
    USE_LIB=true
else
    USE_LIB=false
fi

# Configuration
LOG_DIR="$HOOKS_DIR/logs"
LOG_FILE="$LOG_DIR/$(basename "$0" .sh).log"
GIT_ROOT=$(git rev-parse --show-toplevel 2>/dev/null || pwd)
STYLE_GUIDE=".claude/skills/create-documentation/references/core_standards.md (Filename Conventions)"

# Ensure log directory exists
mkdir -p "$LOG_DIR" 2>/dev/null

# ───────────────────────────────────────────────────────────────
# INLINE FUNCTIONS (fallback if library not available)
# ───────────────────────────────────────────────────────────────

# Allowed exceptions (single source of truth)
if [[ "$USE_LIB" != "true" ]]; then
    MARKDOWN_EXCEPTIONS=(
        "README.md"
        "AGENTS.md"
        "CLAUDE.md"
        "GEMINI.md"
        "SKILL.md"
        "CHANGELOG.md"
        "LICENSE.md"
        "CONTRIBUTING.md"
    )
fi

# Function to log corrections
log_correction() {
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo "[$timestamp] $1" >> "$LOG_FILE"
}

# Convert filename to lowercase snake_case (fallback)
if [[ "$USE_LIB" != "true" ]]; then
    to_snake_case() {
        local filename="$1"
        local extension="${filename##*.}"
        local basename="${filename%.*}"

        # Insert underscores between lowercase/number and uppercase letters
        basename=$(echo "$basename" | sed 's/\([a-z0-9]\)\([A-Z]\)/\1_\2/g')
        # Replace hyphens with underscores
        basename=$(echo "$basename" | tr '-' '_')
        # Convert to lowercase
        basename=$(echo "$basename" | tr '[:upper:]' '[:lower:]')
        # Replace multiple underscores with single underscore
        basename=$(echo "$basename" | sed 's/__*/_/g')
        # Remove leading/trailing underscores
        basename=$(echo "$basename" | sed 's/^_//;s/_$//')

        echo "${basename}.${extension}"
    }
fi

# Check if filename violates naming rules (fallback)
if [[ "$USE_LIB" != "true" ]]; then
    is_naming_violation() {
        local filepath="$1"
        local filename=$(basename "$filepath")

        # Check exceptions
        for exception in "${MARKDOWN_EXCEPTIONS[@]}"; do
            [[ "$filename" == "$exception" ]] && return 1
        done

        # Exception: SKILL.md in .claude/skills/
        [[ "$filename" == "SKILL.md" && "$filepath" =~ \.claude/skills/ ]] && return 1

        # Exception: ~/.claude/plans/ directory
        [[ "$filepath" =~ \.claude/plans/ || "$filepath" =~ /Users/[^/]+/\.claude/plans/ ]] && return 1

        # Check if .md file
        [[ "$filename" != *.md ]] && return 1

        local name="${filename%.*}"
        # Check for uppercase letters or hyphens
        [[ "$name" =~ [A-Z] || "$name" =~ - ]] && return 0

        return 1
    }
fi

# Atomic rename (handles case-insensitive filesystems) - fallback
if [[ "$USE_LIB" != "true" ]]; then
    # Global for cleanup trap
    _ATOMIC_RENAME_TEMP=""

    _atomic_rename_cleanup() {
        [[ -n "$_ATOMIC_RENAME_TEMP" && -f "$_ATOMIC_RENAME_TEMP" ]] && rm -f "$_ATOMIC_RENAME_TEMP" 2>/dev/null
    }

    atomic_rename() {
        local source="$1"
        local target="$2"

        if [[ ! -f "$source" ]]; then
            return 1
        fi

        # If only case differs, use intermediate file
        local source_lower=$(echo "$source" | tr '[:upper:]' '[:lower:]')
        local target_lower=$(echo "$target" | tr '[:upper:]' '[:lower:]')

        if [[ "$source_lower" == "$target_lower" ]] && [[ "$source" != "$target" ]]; then
            _ATOMIC_RENAME_TEMP="${source}.tmp.$$"
            trap '_atomic_rename_cleanup' EXIT INT TERM
            if mv "$source" "$_ATOMIC_RENAME_TEMP" 2>/dev/null && mv "$_ATOMIC_RENAME_TEMP" "$target" 2>/dev/null; then
                _ATOMIC_RENAME_TEMP=""
                trap - EXIT INT TERM
                return 0
            else
                # Rollback if possible
                [[ -f "$_ATOMIC_RENAME_TEMP" ]] && mv "$_ATOMIC_RENAME_TEMP" "$source" 2>/dev/null
                _ATOMIC_RENAME_TEMP=""
                trap - EXIT INT TERM
                return 1
            fi
        else
            mv "$source" "$target" 2>/dev/null
            return $?
        fi
    }
fi

# ───────────────────────────────────────────────────────────────
# ENFORCEMENT FUNCTIONS
# ───────────────────────────────────────────────────────────────

# Process a single file for naming violations
process_file() {
    local file_path="$1"
    local source_context="$2"  # "direct" or "task-scan"

    local filename=$(basename "$file_path")
    local dirname=$(dirname "$file_path")

    # Check if violation exists
    if ! is_naming_violation "$file_path"; then
        return 0
    fi

    # Generate corrected filename
    local corrected_filename=$(to_snake_case "$filename")

    # If already correct, skip
    if [[ "$filename" == "$corrected_filename" ]]; then
        return 0
    fi

    local corrected_path="${dirname}/${corrected_filename}"

    # Perform the rename
    if atomic_rename "$file_path" "$corrected_path"; then
        # Verify rename succeeded (check actual filename on filesystem)
        if [[ -f "$corrected_path" ]]; then
            local actual_filename=$(ls -1 "$dirname" 2>/dev/null | grep -x "$corrected_filename" 2>/dev/null)

            if [[ "$actual_filename" == "$corrected_filename" ]]; then
                log_correction "FILENAME AUTO-FIXED ($source_context): $file_path -> $corrected_path"

                # Show condensed correction notice
                if declare -f print_correction_condensed >/dev/null 2>&1; then
                    print_correction_condensed "$file_path" "$corrected_filename" "$STYLE_GUIDE"
                else
                    echo "[Filename Auto-Fixed] $filename -> $corrected_filename"
                fi
                return 0
            fi
        fi
    fi

    log_correction "RENAME ERROR ($source_context): Failed to rename $file_path"
    return 1
}

# Handle direct file operations (Write/Edit)
handle_direct_operation() {
    local input="$1"

    # Extract file_path from tool input (support multiple payload shapes)
    local file_path=$(echo "$input" | jq -r '.tool_input.filePath // .tool_input.file_path // .tool_input.path // .tool_input.notebook_path // .parameters.file_path // .parameters.filePath // .parameters.path // .parameters.notebook_path // empty' 2>/dev/null)

    # Skip if no file path found
    if [[ -z "$file_path" || "$file_path" == "null" ]]; then
        return 0
    fi

    process_file "$file_path" "direct"
}

# Handle Task tool completion (scan for violations)
handle_task_completion() {
    log_correction "POST-TASK SCAN: Starting markdown naming enforcement scan"

    local violations_found=0
    local violations_fixed=0

    # Scan key directories for markdown files with violations
    local scan_dirs=(
        "$GIT_ROOT"
        "$GIT_ROOT/.claude/hooks"
        "$GIT_ROOT/specs"
    )

    for scan_dir in "${scan_dirs[@]}"; do
        [[ ! -d "$scan_dir" ]] && continue

        # Find markdown files (limited depth for performance)
        # Look for recently modified files (within last 5 minutes)
        while IFS= read -r -d '' file_path; do
            local filename=$(basename "$file_path")

            if is_naming_violation "$file_path"; then
                ((violations_found++))

                if process_file "$file_path" "task-scan"; then
                    ((violations_fixed++))
                fi
            fi
        done < <(find "$scan_dir" -maxdepth 3 -type f -name "*.md" -mmin -5 2>/dev/null -print0)
    done

    if [[ $violations_found -gt 0 ]]; then
        log_correction "POST-TASK COMPLETE: Found $violations_found violations, fixed $violations_fixed"
    fi
}

# ───────────────────────────────────────────────────────────────
# MAIN LOGIC
# ───────────────────────────────────────────────────────────────

main() {
    # Read tool input from stdin
    local input=$(cat)

    # Extract tool name (support multiple payload shapes)
    local tool_name=$(echo "$input" | jq -r '.tool_name // .toolName // .tool // .name // empty' 2>/dev/null)

    case "$tool_name" in
        # Direct file operations
        "Write"|"Edit"|"NotebookEdit"|"create_file"|"edit_notebook_file"|"replace_string_in_file")
            handle_direct_operation "$input"
            ;;

        # Task tool completion - scan for violations
        "Task")
            handle_task_completion
            ;;

        # Not a relevant tool, exit silently
        *)
            exit 0
            ;;
    esac
}

# ───────────────────────────────────────────────────────────────
# EXECUTION
# ───────────────────────────────────────────────────────────────

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

# Execute main function
main

# Performance timing END
END_TIME=$(_get_nano_time)
DURATION=$(( (END_TIME - START_TIME) / 1000000 ))
echo "[$(date '+%Y-%m-%d %H:%M:%S')] enforce-markdown-naming.sh ${DURATION}ms" >> "$HOOKS_DIR/logs/performance.log" 2>/dev/null

# Always exit 0 (never block)
exit 0
