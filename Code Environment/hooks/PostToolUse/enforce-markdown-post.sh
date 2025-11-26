#!/bin/bash
# enforce-markdown-post.sh
# PostToolUse hook to automatically enforce markdown filename conventions
#
# Detects and auto-corrects:
# - ALL CAPS filenames (except README.md, AGENTS.md, CLAUDE.md, GEMINI.md, SKILL.md)
# - Hyphen-separated names
# - camelCase/PascalCase names
#
# Enforces: lowercase snake_case only (e.g., document_name.md)
# Exceptions: README.md, AGENTS.md, CLAUDE.md, GEMINI.md, SKILL.md (in .claude/skills/*/ only)
#             Files in ~/.claude/plans/ (Claude Code system files with hyphenated names)
#
# PERFORMANCE TARGET: <200ms (file operations, git commands)
# COMPATIBILITY: Bash 3.2+ (macOS and Linux compatible)
#
# RESPONSIBILITY: Filename enforcement for markdown files
# - Renames uppercase violations (README.md → readme.md)
# - Handles case-only changes (two-step rename on case-insensitive FS)
# - Does NOT validate content structure (see enforce-markdown-strict.sh)
#
# EXECUTION ORDER: PostToolUse hook (runs AFTER tool completion)
#   1. UserPromptSubmit hooks run FIRST (before processing user input)
#   2. PreToolUse hooks run SECOND (before tool execution, validation)
#   3. PostToolUse hooks run LAST (after tool completion, verification)
#   This hook: Auto-renames markdown files to lowercase snake_case
#
# EXIT CODE CONVENTION:
#   0 = Allow (hook passed, continue execution)
#   1 = Block (hook failed, stop execution with warning)
#   2 = Error (reserved for critical failures)
# ───────────────────────────────────────────────────────────────

# Source output helpers
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" 2>/dev/null && pwd)"
HOOKS_DIR="$(cd "$SCRIPT_DIR/.." 2>/dev/null && pwd)"
LIB_DIR="$HOOKS_DIR/lib"

if [[ -f "$LIB_DIR/output-helpers.sh" ]]; then
    source "$LIB_DIR/output-helpers.sh"
fi

# Configuration
LOG_DIR="$HOOKS_DIR/logs"
LOG_FILE="$LOG_DIR/$(basename "$0" .sh).log"

# Get git repository root (portable across all environments)
GIT_ROOT=$(git rev-parse --show-toplevel 2>/dev/null || pwd)
STYLE_GUIDE=".claude/skills/create-documentation/references/core_standards.md (Filename Conventions)"

# Ensure log directory exists
mkdir -p "$LOG_DIR"

# Function to log corrections
log_correction() {
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo "[$timestamp] $1" >> "$LOG_FILE"
}

# Function to convert filename to lowercase snake_case
to_snake_case() {
    local filename="$1"
    local extension="${filename##*.}"
    local basename="${filename%.*}"

    # Insert underscores between lowercase/number and uppercase letters (camelCase / PascalCase)
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

# Function to check if filename violates naming rules
is_violation() {
    local filename="$1"
    local filepath="$2"

    # Exception: README.md is always allowed
    if [[ "$filename" == "README.md" ]]; then
        return 1  # Not a violation
    fi

    # Exception: AGENTS.md, CLAUDE.md, GEMINI.md at project root
    if [[ "$filename" == "AGENTS.md" || "$filename" == "CLAUDE.md" || "$filename" == "GEMINI.md" ]]; then
        return 1  # Not a violation
    fi

    # Exception: SKILL.md is allowed in .claude/skills/*/ directories
    if [[ "$filename" == "SKILL.md" && "$filepath" =~ \.claude/skills/ ]]; then
        return 1  # Not a violation
    fi

    # Exception: ~/.claude/plans/ directory (Claude Code system files with hyphenated names)
    if [[ "$filepath" =~ \.claude/plans/ || "$filepath" =~ /Users/[^/]+/\.claude/plans/ ]]; then
        return 1  # Not a violation
    fi

    # Check if .md file
    if [[ "$filename" != *.md ]]; then
        return 1  # Not a markdown file
    fi

    local basename="${filename%.*}"

    # Check for uppercase letters
    if [[ "$basename" =~ [A-Z] ]]; then
        return 0  # Violation
    fi

    # Check for hyphens
    if [[ "$basename" =~ - ]]; then
        return 0  # Violation
    fi

    return 1  # Not a violation
}

# Main enforcement logic
main() {
    # Read tool input from stdin
    local input=$(cat)

    # Extract tool name (support multiple payload shapes)
    local tool_name=$(echo "$input" | jq -r '.tool_name // .toolName // .tool // .name // empty' 2>/dev/null)

    # Only process Write, Edit, NotebookEdit tools
    case "$tool_name" in
        "Write"|"Edit"|"NotebookEdit"|"create_file"|"edit_notebook_file"|"replace_string_in_file")
            ;;
        *)
            # Not a file editing tool, exit silently
            exit 0
            ;;
    esac

    # Extract file_path from tool input (support multiple payload shapes)
    local file_path=$(echo "$input" | jq -r '.tool_input.filePath // .tool_input.file_path // .tool_input.path // .tool_input.notebook_path // .parameters.file_path // .parameters.filePath // .parameters.path // .parameters.notebook_path // empty' 2>/dev/null)

    # Skip if no file path found
    if [[ -z "$file_path" || "$file_path" == "null" ]]; then
        exit 0
    fi

    # Get just the filename
    local filename=$(basename "$file_path")
    local dirname=$(dirname "$file_path")

    # Check if violation exists
    if ! is_violation "$filename" "$file_path"; then
        exit 0
    fi

    # Generate corrected filename
    local corrected_filename=$(to_snake_case "$filename")

    # If already correct, skip
    if [[ "$filename" == "$corrected_filename" ]]; then
        exit 0
    fi

    local corrected_path="${dirname}/${corrected_filename}"

    # Perform the rename (two-step process for case-insensitive filesystems)
    if [[ -f "$file_path" ]]; then
        # Check if this is a case-only change
        local filename_lower=$(echo "$filename" | tr '[:upper:]' '[:lower:]')
        local corrected_lower=$(echo "$corrected_filename" | tr '[:upper:]' '[:lower:]')

        if [[ "$filename_lower" == "$corrected_lower" ]]; then
            # Case-only change - use two-step rename for case-insensitive filesystems
            # Note: Two-step rename works on ALL filesystems (APFS, HFS+, ext4, etc.)
            # Performance: ~2ms overhead vs direct rename, negligible for hook execution
            # Security: Use unique temp name and verify all operations
            local temp_path="${file_path}.tmp_rename_${$}_${RANDOM}"

            # Step 1: Move to temp location
            if mv "$file_path" "$temp_path" 2>/dev/null; then
                # Step 2: Move from temp to final name
                if mv "$temp_path" "$corrected_path" 2>/dev/null; then
                    # Success - temp file is gone, nothing to clean up
                    :
                else
                    # Step 2 failed - attempt rollback
                    log_correction "RENAME ERROR: Failed to rename temp to $corrected_path, attempting rollback"
                    if mv "$temp_path" "$file_path" 2>/dev/null; then
                        log_correction "ROLLBACK SUCCESS: Restored $file_path"
                    else
                        # Rollback failed - file may be orphaned as temp
                        log_correction "ROLLBACK FAILED: File may be orphaned at $temp_path"
                        # Try to at least leave it findable
                        if [[ -f "$temp_path" ]]; then
                            mv "$temp_path" "${file_path}.ORPHANED_${$}" 2>/dev/null || true
                        fi
                    fi
                fi
            else
                log_correction "RENAME ERROR: Failed to move $file_path to temp location"
            fi
        else
            # Different name - direct rename
            mv "$file_path" "$corrected_path" 2>/dev/null
        fi

        # Check if rename succeeded by verifying actual filename case
        # On case-insensitive filesystems, use ls to check actual filename
        if [[ -f "$corrected_path" ]]; then
            local actual_filename=$(ls -1 "$dirname" 2>/dev/null | grep -x "$corrected_filename" 2>/dev/null)

            if [[ "$actual_filename" == "$corrected_filename" ]]; then
                # Log the correction
                log_correction "FILENAME AUTO-FIXED: $file_path → $corrected_path (naming convention violation)"

                # Show condensed correction notice
                print_correction_condensed "$file_path" "$corrected_filename" "$STYLE_GUIDE"
            fi
        fi
    fi
}

# Performance timing START
START_TIME=$(date +%s%N)

# Execute main function
main

# Performance timing END
END_TIME=$(date +%s%N)
DURATION=$(( (END_TIME - START_TIME) / 1000000 ))
HOOKS_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
echo "[$(date '+%Y-%m-%d %H:%M:%S')] enforce-markdown-post.sh ${DURATION}ms" >> "$HOOKS_DIR/logs/performance.log"

# Always exit 0 (never block)
exit 0
