#!/bin/bash
# enforce-markdown-post-task.sh
# PostToolUse hook to enforce markdown filename conventions AFTER Task tool completion
#
# PURPOSE: Sub-agents spawned by Task tool run in separate contexts and don't
# trigger the main session's PostToolUse hooks. This hook scans for and fixes
# any markdown files with naming violations created during Task execution.
#
# DETECTS AND FIXES:
# - ALL CAPS filenames (except README.md, AGENTS.md, CLAUDE.md, GEMINI.md, SKILL.md)
# - Hyphen-separated names
# - camelCase/PascalCase names
#
# ENFORCES: lowercase snake_case only (e.g., document_name.md)
#
# PERFORMANCE TARGET: <500ms (quick file scan, limited depth)
# COMPATIBILITY: Bash 3.2+ (macOS and Linux compatible)
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
GIT_ROOT=$(git rev-parse --show-toplevel 2>/dev/null || pwd)

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

# Function to check if filename violates naming rules
is_violation() {
    local filename="$1"
    local filepath="$2"

    # Exception: README.md is always allowed
    [[ "$filename" == "README.md" ]] && return 1
    # Exception: AGENTS.md, CLAUDE.md, GEMINI.md at project root
    [[ "$filename" == "AGENTS.md" || "$filename" == "CLAUDE.md" || "$filename" == "GEMINI.md" ]] && return 1
    # Exception: SKILL.md in .claude/skills/
    [[ "$filename" == "SKILL.md" && "$filepath" =~ \.claude/skills/ ]] && return 1
    # Exception: ~/.claude/plans/ directory
    [[ "$filepath" =~ \.claude/plans/ ]] && return 1
    # Check if .md file
    [[ "$filename" != *.md ]] && return 1

    local basename="${filename%.*}"
    # Check for uppercase letters or hyphens
    [[ "$basename" =~ [A-Z] || "$basename" =~ - ]] && return 0

    return 1
}

# Function to perform atomic rename (handles case-insensitive filesystems)
atomic_rename() {
    local file_path="$1"
    local corrected_filename="$2"
    local dirname=$(dirname "$file_path")
    local corrected_path="${dirname}/${corrected_filename}"

    if [[ ! -f "$file_path" ]]; then
        return 1
    fi

    # Check if this is a case-only change
    local filename=$(basename "$file_path")
    local filename_lower=$(echo "$filename" | tr '[:upper:]' '[:lower:]')
    local corrected_lower=$(echo "$corrected_filename" | tr '[:upper:]' '[:lower:]')

    if [[ "$filename_lower" == "$corrected_lower" ]]; then
        # Case-only change - use two-step rename
        local temp_path="${file_path}.tmp_rename_${$}_${RANDOM}"
        if mv "$file_path" "$temp_path" 2>/dev/null && mv "$temp_path" "$corrected_path" 2>/dev/null; then
            return 0
        else
            # Rollback if possible
            [[ -f "$temp_path" ]] && mv "$temp_path" "$file_path" 2>/dev/null
            return 1
        fi
    else
        # Different name - direct rename
        mv "$file_path" "$corrected_path" 2>/dev/null
        return $?
    fi
}

# Main enforcement logic
main() {
    # Read tool input from stdin
    local input=$(cat)

    # Only process Task tool
    local tool_name=$(echo "$input" | jq -r '.tool_name // .toolName // .tool // .name // empty' 2>/dev/null)
    if [[ "$tool_name" != "Task" ]]; then
        exit 0
    fi

    log_correction "POST-TASK SCAN: Starting markdown naming enforcement scan"

    local violations_found=0
    local violations_fixed=0

    # Scan key directories for markdown files with violations
    # Focus on areas where sub-agents typically create files
    local scan_dirs=(
        "$GIT_ROOT"
        "$GIT_ROOT/.claude/hooks"
        "$GIT_ROOT/specs"
    )

    for scan_dir in "${scan_dirs[@]}"; do
        [[ ! -d "$scan_dir" ]] && continue

        # Find markdown files (limited depth for performance)
        while IFS= read -r -d '' file_path; do
            local filename=$(basename "$file_path")

            if is_violation "$filename" "$file_path"; then
                local corrected_filename=$(to_snake_case "$filename")

                if [[ "$filename" != "$corrected_filename" ]]; then
                    ((violations_found++))

                    if atomic_rename "$file_path" "$corrected_filename"; then
                        ((violations_fixed++))
                        local corrected_path="$(dirname "$file_path")/${corrected_filename}"
                        log_correction "POST-TASK FIX: $file_path → $corrected_path"

                        # Output correction notice
                        if declare -f print_correction_condensed >/dev/null 2>&1; then
                            print_correction_condensed "$file_path" "$corrected_filename" "Post-Task naming enforcement"
                        else
                            echo "[Filename Auto-Fixed] $(basename "$file_path") → $corrected_filename"
                        fi
                    else
                        log_correction "POST-TASK ERROR: Failed to rename $file_path"
                    fi
                fi
            fi
        done < <(find "$scan_dir" -maxdepth 3 -type f -name "*.md" -newer /tmp/.claude_task_start_${PPID} 2>/dev/null -print0 || find "$scan_dir" -maxdepth 3 -type f -name "*.md" -mmin -5 2>/dev/null -print0)
    done

    if [[ $violations_found -gt 0 ]]; then
        log_correction "POST-TASK COMPLETE: Found $violations_found violations, fixed $violations_fixed"
    fi
}

# Performance timing START
START_TIME=$(date +%s%N 2>/dev/null || date +%s)

# Execute main function
main

# Performance timing END
END_TIME=$(date +%s%N 2>/dev/null || date +%s)
if [[ "$START_TIME" =~ ^[0-9]+$ && "$END_TIME" =~ ^[0-9]+$ && ${#START_TIME} -gt 10 ]]; then
    DURATION=$(( (END_TIME - START_TIME) / 1000000 ))
else
    DURATION=0
fi
echo "[$(date '+%Y-%m-%d %H:%M:%S')] enforce-markdown-post-task.sh ${DURATION}ms" >> "$HOOKS_DIR/logs/performance.log"

# Always exit 0 (never block)
exit 0
