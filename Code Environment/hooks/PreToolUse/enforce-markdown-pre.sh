#!/bin/bash
# enforce-markdown-pre.sh
# PreToolUse hook to PREVENT creation of markdown files with invalid naming
#
# BLOCKS Write/Edit/NotebookEdit operations if filename violates conventions:
# - ALL CAPS filenames (except README.md, AGENTS.md, CLAUDE.md, GEMINI.md, SKILL.md)
# - Hyphen-separated names (should be snake_case)
# - camelCase/PascalCase names (should be snake_case)
#
# Enforces: lowercase snake_case only (e.g., document_name.md)
# Exceptions: README.md, AGENTS.md, CLAUDE.md, GEMINI.md, SKILL.md (in appropriate locations)
#             Files in ~/.claude/plans/ (Claude Code system files)
#
# PERFORMANCE TARGET: <50ms (validation only, no file operations)
# COMPATIBILITY: Bash 3.2+ (macOS and Linux compatible)
#
# RESPONSIBILITY: Filename validation BEFORE file creation/modification
# - BLOCKS invalid filenames (uppercase, hyphens, camelCase)
# - Provides clear error message with correct filename suggestion
# - Complements enforce-markdown-post.sh (which auto-corrects after creation)
#
# WHY THIS EXISTS:
# - PostToolUse hooks may not execute due to Claude Code system bugs
# - PreToolUse validation provides a safety net to PREVENT violations
# - Blocking before creation is better than fixing after creation
#
# EXECUTION ORDER: PreToolUse hook (runs BEFORE tool execution)
#   1. UserPromptSubmit hooks run FIRST (before processing user input)
#   2. PreToolUse hooks run SECOND (before tool execution, validation) ← THIS HOOK
#   3. PostToolUse hooks run LAST (after tool completion, auto-fix)
#
# EXIT CODE CONVENTION:
#   0 = Allow (filename is valid, continue execution)
#   1 = Block (filename is invalid, stop execution with error message)
# ───────────────────────────────────────────────────────────────

# Source libraries
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" 2>/dev/null && pwd)"
HOOKS_DIR="$(cd "$SCRIPT_DIR/.." 2>/dev/null && pwd)"
LIB_DIR="$HOOKS_DIR/lib"

if [[ -f "$LIB_DIR/exit-codes.sh" ]]; then
    source "$LIB_DIR/exit-codes.sh"
else
    # Fallback exit codes
    EXIT_ALLOW=0
    EXIT_BLOCK=1
fi

# Configuration
LOG_DIR="$HOOKS_DIR/logs"
LOG_FILE="$LOG_DIR/$(basename "$0" .sh).log"

mkdir -p "$LOG_DIR"

# Cross-platform nanosecond timing helper
_get_nano_time() {
  if [[ "$OSTYPE" == "darwin"* ]]; then
    echo $(($(date +%s) * 1000000000))
  else
    date +%s%N 2>/dev/null || echo $(($(date +%s) * 1000000000))
  fi
}

# Performance tracking
START_TIME=$(_get_nano_time)

# Function to log blocks
log_block() {
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo "[$timestamp] BLOCKED: $1" >> "$LOG_FILE" 2>/dev/null
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

    # Exception: Standard uppercase documentation files
    if [[ "$filename" == "CHANGELOG.md" || "$filename" == "LICENSE.md" || "$filename" == "CONTRIBUTING.md" ]]; then
        return 1  # Not a violation
    fi

    # Exception: SKILL.md is allowed in .claude/skills/*/ directories
    if [[ "$filename" == "SKILL.md" && "$filepath" =~ \.claude/skills/ ]]; then
        return 1  # Not a violation
    fi

    # Exception: ~/.claude/plans/ directory (Claude Code system files)
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

# Main validation logic
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
            # Not a file editing tool, allow
            exit $EXIT_ALLOW
            ;;
    esac

    # Extract file_path from tool input (support multiple payload shapes)
    local file_path=$(echo "$input" | jq -r '.tool_input.filePath // .tool_input.file_path // .tool_input.path // .tool_input.notebook_path // .parameters.file_path // .parameters.filePath // .parameters.path // .parameters.notebook_path // empty' 2>/dev/null)

    # Allow if no file path found
    if [[ -z "$file_path" ]]; then
        exit $EXIT_ALLOW
    fi

    # Extract filename from path
    local filename=$(basename "$file_path")

    # Check if filename violates naming rules
    if is_violation "$filename" "$file_path"; then
        # Calculate suggested filename
        local suggested=$(to_snake_case "$filename")

        # Log the block
        log_block "$filename → suggested: $suggested (path: $file_path)"

        # Emit systemMessage for Claude Code visibility
        echo "{\"systemMessage\": \"❌ BLOCKED: Invalid markdown filename '$filename' - use lowercase snake_case: '$suggested'\"}"

        # Display blocking error message
        echo "" >&2
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" >&2
        echo "❌ INVALID MARKDOWN FILENAME" >&2
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" >&2
        echo "" >&2
        echo "File: $filename" >&2
        echo "Path: $file_path" >&2
        echo "" >&2
        echo "❌ VIOLATION: Filename contains uppercase letters or hyphens" >&2
        echo "" >&2
        echo "✅ REQUIRED FORMAT: lowercase_snake_case.md" >&2
        echo "✅ SUGGESTED NAME: $suggested" >&2
        echo "" >&2
        echo "Exceptions (allowed):" >&2
        echo "  • README.md (always allowed)" >&2
        echo "  • AGENTS.md, CLAUDE.md, GEMINI.md (project root only)" >&2
        echo "  • CHANGELOG.md, LICENSE.md, CONTRIBUTING.md (standard docs)" >&2
        echo "  • SKILL.md (.claude/skills/*/ only)" >&2
        echo "" >&2
        echo "Reference: .claude/skills/create-documentation/references/core_standards.md" >&2
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" >&2

        # Record performance
        END_TIME=$(_get_nano_time)
        if [[ "$START_TIME" =~ ^[0-9]+$ ]] && [[ "$END_TIME" =~ ^[0-9]+$ ]]; then
            DURATION=$(((END_TIME - START_TIME) / 1000000))
            echo "[$(date '+%Y-%m-%d %H:%M:%S')] enforce-markdown-pre.sh ${DURATION}ms (blocked: $filename)" >> "$HOOKS_DIR/logs/performance.log" 2>/dev/null
        fi

        exit $EXIT_BLOCK
    fi

    # Filename is valid, allow operation
    # Record performance
    END_TIME=$(_get_nano_time)
    if [[ "$START_TIME" =~ ^[0-9]+$ ]] && [[ "$END_TIME" =~ ^[0-9]+$ ]]; then
        DURATION=$(((END_TIME - START_TIME) / 1000000))
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] enforce-markdown-pre.sh ${DURATION}ms (allowed: $filename)" >> "$HOOKS_DIR/logs/performance.log" 2>/dev/null
    fi

    exit $EXIT_ALLOW
}

# Execute main function
main
