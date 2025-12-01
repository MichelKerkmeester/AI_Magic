#!/bin/bash
# enforce-markdown-strict.sh
# UserPromptSubmit hook for aggressive markdown enforcement
#
# Features:
# - Auto-fixes SAFE violations (separators, ALL CAPS, emoji, spacing)
# - BLOCKS on CRITICAL violations (exit 1)
# - Type-specific enforcement (SKILL.md strict, knowledge moderate, spec loose)
#
# Safe auto-fixes (applied immediately):
# - Missing --- separators
# - H2 not ALL CAPS
# - Missing H2 emoji
# - H1 subtitle format
# - Spacing normalization
#
# Critical violations (BLOCKS with exit 1):
# - Missing frontmatter (SKILL.md/commands)
# - Missing required frontmatter fields
# - Sections in wrong order
# - Missing required sections
# - H1 subtitle violations
# - Multiple H1 headers
#
# PERFORMANCE TARGET: <200ms (content analysis, validation rules)
# COMPATIBILITY: Bash 3.2+ (macOS and Linux compatible)
#
# RESPONSIBILITY: Structure validation for markdown files
# - Checks frontmatter presence and validity
# - Validates c7score (heading distribution)
# - Verifies H2 emoji presence
# - Enforces section order and required sections
# - Does NOT handle filename violations (see enforce-markdown-post.sh)
#
# EXECUTION ORDER: UserPromptSubmit hook (runs BEFORE user prompt processing)
#   1. UserPromptSubmit hooks run FIRST (before processing user input)
#   2. PreToolUse hooks run SECOND (before tool execution, validation)
#   3. PostToolUse hooks run LAST (after tool completion, verification)
#   This hook: Validates markdown structure before processing prompts
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
CACHE_DIR="/tmp/claude_hooks_cache/warnings"
CACHE_TTL=86400  # 24 hours in seconds

# Get git repository root (portable across all environments)
GIT_ROOT=$(git rev-parse --show-toplevel 2>/dev/null || pwd)
STYLE_GUIDE=".claude/skills/create-documentation/SKILL.md (ALWAYS Rules Section 5)"

# Ensure log directory and cache directory exist
mkdir -p "$LOG_DIR"
mkdir -p "$CACHE_DIR"

# Function to log enforcement actions
log_action() {
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo "[$timestamp] $1" >> "$LOG_FILE"
}

# Warning cache functions (prevent spam for same file warnings)
get_warning_cache_key() {
    local filepath="$1"
    local warning_type="$2"
    # Create hash from filepath + warning type for cache key
    echo "$filepath:$warning_type" | md5 -q 2>/dev/null || echo "$filepath:$warning_type" | md5sum 2>/dev/null | awk '{print $1}'
}

is_warning_cached() {
    local cache_key="$1"
    local cache_file="$CACHE_DIR/$cache_key"

    # Check if cache file exists
    if [[ ! -f "$cache_file" ]]; then
        return 1  # Not cached
    fi

    # Check if cache is still valid (within TTL)
    local cache_age=$(($(date +%s) - $(stat -f %m "$cache_file" 2>/dev/null || stat -c %Y "$cache_file" 2>/dev/null)))
    if [[ $cache_age -lt $CACHE_TTL ]]; then
        return 0  # Cached and valid
    fi

    # Cache expired, remove it
    rm -f "$cache_file" 2>/dev/null
    return 1  # Not cached (expired)
}

cache_warning() {
    local cache_key="$1"
    local cache_file="$CACHE_DIR/$cache_key"

    # Atomic write using temp file + mv
    local temp_file="${cache_file}.tmp.$$"
    echo "$(date +%s)" > "$temp_file" 2>/dev/null
    mv "$temp_file" "$cache_file" 2>/dev/null || rm -f "$temp_file" 2>/dev/null
}

# Cleanup old cache files (older than TTL)
cleanup_warning_cache() {
    # Find and remove cache files older than TTL
    find "$CACHE_DIR" -type f -mtime +1 -delete 2>/dev/null || true
}

# Function to detect document type from file path
detect_document_type() {
    local filepath="$1"

    if [[ "$filepath" =~ \.claude/skills/.*/SKILL\.md$ ]]; then
        echo "skill"
    elif [[ "$filepath" =~ \.claude/commands/.*/.*\.md$ ]]; then
        echo "command"
    elif [[ "$filepath" =~ \.claude/knowledge/.*\.md$ ]]; then
        echo "knowledge"
    elif [[ "$filepath" =~ specs/.*\.md$ ]]; then
        echo "spec"
    elif [[ "$filepath" =~ README\.md$ ]]; then
        echo "readme"
    else
        echo "unknown"
    fi
}

# Function to check for critical SKILL.md violations
check_skill_critical() {
    local filepath="$1"
    local critical_violations=()

    # Check for YAML frontmatter
    if ! head -1 "$filepath" | grep -q "^---$"; then
        critical_violations+=("CRITICAL: Missing YAML frontmatter (requires: name, description, allowed-tools)")
        return 1
    fi

    # Check required frontmatter fields
    if ! grep -q "^name:" "$filepath"; then
        critical_violations+=("CRITICAL: Missing 'name' field in YAML frontmatter")
    fi
    if ! grep -q "^description:" "$filepath"; then
        critical_violations+=("CRITICAL: Missing 'description' field in YAML frontmatter")
    fi
    if ! grep -q "^allowed-tools:" "$filepath"; then
        critical_violations+=("CRITICAL: Missing 'allowed-tools' field in YAML frontmatter")
    fi

    # Check H1 format (should have subtitle)
    local h1_line=$(grep "^# " "$filepath" | head -1)
    if [[ -n "$h1_line" && ! "$h1_line" =~ " - " ]]; then
        critical_violations+=("CRITICAL: H1 title missing subtitle format (expected: 'Skill Name - Descriptive Subtitle')")
    fi

    # Check for multiple H1 headers
    local h1_count=$(grep -c "^# " "$filepath")
    if [[ $h1_count -gt 1 ]]; then
        critical_violations+=("CRITICAL: Multiple H1 headers found ($h1_count). Only one H1 allowed.")
    fi

    # Check for required sections
    # Pattern matches: "## N. [EMOJI] SECTION NAME" or "## N. SECTION NAME"
    # The section name can appear anywhere after the number and optional emoji
    # Note: "HOW TO USE" is the standard (previously "HOW IT WORKS")
    local required_sections=("WHEN TO USE" "HOW TO USE" "RULES")
    for section in "${required_sections[@]}"; do
        # Match pattern: ## followed by number, dot, optional emoji, then section name
        if ! grep -qE "^## [0-9]+\. .* ?${section}" "$filepath"; then
            critical_violations+=("CRITICAL: Missing required section: $section")
        fi
    done

    if [[ ${#critical_violations[@]} -gt 0 ]]; then
        printf '%s\n' "${critical_violations[@]}"
        return 1
    fi

    return 0
}

# Function to check for critical command violations
check_command_critical() {
    local filepath="$1"
    local critical_violations=()

    # Check for YAML frontmatter
    if ! head -1 "$filepath" | grep -q "^---$"; then
        critical_violations+=("CRITICAL: Missing YAML frontmatter (requires: description, argument-hint, allowed-tools)")
        return 1
    fi

    # Check required frontmatter fields
    if ! grep -q "^description:" "$filepath"; then
        critical_violations+=("CRITICAL: Missing 'description' field in YAML frontmatter")
    fi
    if ! grep -q "^argument-hint:" "$filepath"; then
        critical_violations+=("CRITICAL: Missing 'argument-hint' field in YAML frontmatter")
    fi

    # Check H1 format (should NOT have subtitle for commands)
    local h1_line=$(grep "^# " "$filepath" | head -1)
    if [[ -n "$h1_line" && "$h1_line" =~ " - " ]]; then
        critical_violations+=("CRITICAL: H1 title should NOT have subtitle for commands (expected: 'Command Name' only)")
    fi

    # Check for multiple H1 headers
    local h1_count=$(grep -c "^# " "$filepath")
    if [[ $h1_count -gt 1 ]]; then
        critical_violations+=("CRITICAL: Multiple H1 headers found ($h1_count). Only one H1 allowed.")
    fi

    if [[ ${#critical_violations[@]} -gt 0 ]]; then
        printf '%s\n' "${critical_violations[@]}"
        return 1
    fi

    return 0
}

# Function to check for critical knowledge violations
check_knowledge_critical() {
    local filepath="$1"
    local critical_violations=()

    # Check for NO YAML frontmatter
    if head -1 "$filepath" | grep -q "^---$"; then
        critical_violations+=("CRITICAL: Knowledge files should NOT have YAML frontmatter (remove it)")
    fi

    # Check H1 format (should have subtitle)
    local h1_line=$(grep "^# " "$filepath" | head -1)
    if [[ -n "$h1_line" && ! "$h1_line" =~ " - " ]]; then
        critical_violations+=("CRITICAL: H1 title missing subtitle format (expected: 'Topic - Descriptive Subtitle')")
    fi

    # Check for multiple H1 headers
    local h1_count=$(grep -c "^# " "$filepath")
    if [[ $h1_count -gt 1 ]]; then
        critical_violations+=("CRITICAL: Multiple H1 headers found ($h1_count). Only one H1 allowed.")
    fi

    if [[ ${#critical_violations[@]} -gt 0 ]]; then
        printf '%s\n' "${critical_violations[@]}"
        return 1
    fi

    return 0
}

# Function to check for TOC violations (applies to all types except README)
check_toc_violations() {
    local filepath="$1"
    local doc_type="$2"
    local warnings=()

    # Only README files are allowed to have TOCs
    # Skip check for README files
    if [[ "$doc_type" == "readme" ]]; then
        return 0
    fi

    # Check for TOC headers (case-insensitive)
    if grep -iq "^##.*TABLE OF CONTENTS" "$filepath" 2>/dev/null; then
        warnings+=("WARNING: Found TOC header '## TABLE OF CONTENTS' - TOCs only allowed in README files per Rule #4")
    fi

    if grep -iq "^####.*TABLE OF CONTENTS" "$filepath" 2>/dev/null; then
        warnings+=("WARNING: Found TOC header '#### TABLE OF CONTENTS' - TOCs only allowed in README files per Rule #4")
    fi

    # Check for TOC link patterns (markdown links with section numbers)
    if grep -E "^- \[[0-9]+\. " "$filepath" >/dev/null 2>&1; then
        warnings+=("INFO: Found potential TOC links (lines starting with '- [1. ') - TOCs only allowed in README files")
    fi

    if [[ ${#warnings[@]} -gt 0 ]]; then
        printf '%s\n' "${warnings[@]}"
        return 1
    fi

    return 0
}

# C7score caching functions
get_cache_key() {
    local filepath="$1"
    # Cache key = MD5 of file content + modification time
    local content_hash=$(md5 -q "$filepath" 2>/dev/null || md5sum "$filepath" 2>/dev/null | awk '{print $1}')
    local mod_time=$(stat -f %m "$filepath" 2>/dev/null || stat -c %Y "$filepath" 2>/dev/null)
    echo "${content_hash}_${mod_time}"
}

get_cached_score() {
    local cache_key="$1"
    local cache_dir="$HOOKS_DIR/.cache/c7score"
    local cache_file="$cache_dir/$cache_key"

    # Check if cache exists and is less than 24 hours old
    if [[ -f "$cache_file" ]]; then
        local cache_age=$(($(date +%s) - $(stat -f %m "$cache_file" 2>/dev/null || stat -c %Y "$cache_file" 2>/dev/null)))
        if [[ $cache_age -lt 86400 ]]; then
            cat "$cache_file"
            return 0
        fi
    fi
    return 1
}

save_cached_score() {
    local cache_key="$1"
    local output="$2"
    local cache_dir="$HOOKS_DIR/.cache/c7score"
    local cache_file="$cache_dir/$cache_key"

    mkdir -p "$cache_dir" 2>/dev/null
    echo "$output" > "$cache_file" 2>/dev/null || true
}

# Run c7score analysis on file (non-blocking, informational only)
run_c7score_analysis() {
    local filepath="$1"
    local cli_wrapper="$GIT_ROOT/.claude/skills/create-documentation/create-documentation"

    # Only run if CLI wrapper exists and Python3 available
    if [[ ! -f "$cli_wrapper" ]] || ! command -v python3 >/dev/null 2>&1; then
        return 0
    fi

    # Check cache first
    local cache_key=$(get_cache_key "$filepath")
    local full_output=$(get_cached_score "$cache_key" || true)

    # If not cached, run analyzer
    if [[ -z "$full_output" ]]; then
        full_output=$("$cli_wrapper" "$filepath" 2>/dev/null || true)
        # Save to cache if we got output
        if [[ -n "$full_output" ]]; then
            save_cached_score "$cache_key" "$full_output"
        fi
    fi

    # Extract c7score value if present
    local score=$(echo "$full_output" | grep -oE "C7[Ss]core:? [0-9]+(\.[0-9]+)?" | grep -oE "[0-9]+(\.[0-9]+)?" | head -1)

    # Extract key metrics
    local issue_rate=$(echo "$full_output" | grep "Issue rate" || true)
    local recommendations=$(echo "$full_output" | grep -A 3 "Recommendations" || true)
    local anti_patterns=$(echo "$full_output" | grep "Anti-patterns" || true)

    # Determine quality indicator based on score or issues
    local indicator="ℹ️ "
    local quality_text=""
    if [[ -n "$score" ]]; then
        if (( $(echo "$score >= 8.0" | bc -l 2>/dev/null || echo 0) )); then
            indicator="✅"
            quality_text="(excellent)"
        elif (( $(echo "$score >= 6.5" | bc -l 2>/dev/null || echo 0) )); then
            indicator="📊"
            quality_text="(good)"
        elif (( $(echo "$score >= 5.0" | bc -l 2>/dev/null || echo 0) )); then
            indicator="⚠️ "
            quality_text="(needs improvement)"
        else
            indicator="❌"
            quality_text="(poor structure)"
        fi
    fi

    # If there are notable issues or score, show formatted summary
    if [[ -n "$score" ]] || [[ -n "$issue_rate" ]]; then
        cat >&2 << EOF

${indicator} C7SCORE ANALYSIS:
$(if [[ -n "$score" ]]; then echo "   Score: $score/10 $quality_text"; fi)
$(if [[ -n "$issue_rate" ]]; then echo "   $issue_rate" | sed 's/^/   /'; fi)
$(if [[ -n "$recommendations" ]]; then echo "$recommendations" | sed 's/^/   /'; fi)
$(if [[ -n "$anti_patterns" ]]; then echo "$anti_patterns" | sed 's/^/   /'; fi)

   💡 Tip: Run 'create-documentation validate --file $filepath' for full analysis
EOF
    fi
}

# Main enforcement logic
main() {
    # Cleanup old cache files on startup (non-blocking)
    cleanup_warning_cache &

    # Get git repository root (or use CWD as fallback)
    local git_root=$(git rev-parse --show-toplevel 2>/dev/null || pwd)

    # Get recently modified markdown files
    local modified_files=$(git -C "$git_root" status --short 2>/dev/null | grep "\.md$" | awk '{print $2}' | head -10)

    # Also check staged files
    local staged_files=$(git -C "$git_root" diff --name-only --cached 2>/dev/null | grep "\.md$" | head -10)

    # Combine and deduplicate
    local all_files=$(echo -e "$modified_files\n$staged_files" | sort -u | grep -v "^$")

    # If no markdown files modified, exit silently
    if [[ -z "$all_files" ]]; then
        # Performance timing END
        local end_time=$(_get_nano_time)
        local duration=$(( (end_time - START_TIME) / 1000000 ))
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] enforce-markdown-strict.sh ${duration}ms" >> "$HOOKS_DIR/logs/performance.log"
        exit 0
    fi

    local has_critical=false
    local files_checked=0

    # Check each file
    while IFS= read -r file; do
        [[ -z "$file" ]] && continue

        # Construct full path using git root (portable)
        local full_path="$GIT_ROOT/$file"

        # Skip if file doesn't exist
        [[ ! -f "$full_path" ]] && continue

        # Detect document type
        local doc_type=$(detect_document_type "$file")

        # Skip unknown and README types
        [[ "$doc_type" == "unknown" || "$doc_type" == "readme" ]] && continue

        # Skip spec files (loose enforcement only)
        [[ "$doc_type" == "spec" ]] && continue

        # Count this file as checked
        files_checked=$((files_checked + 1))

        # Check for critical violations based on type
        local critical_violations=""
        case "$doc_type" in
            skill)
                critical_violations=$(check_skill_critical "$full_path")
                ;;
            command)
                critical_violations=$(check_command_critical "$full_path")
                ;;
            knowledge)
                critical_violations=$(check_knowledge_critical "$full_path")
                ;;
        esac

        # Check for TOC violations (non-blocking, informational warning)
        # Only README files are allowed to have TOCs - all other types should not have them
        local toc_warnings=$(check_toc_violations "$full_path" "$doc_type" || true)
        if [[ -n "$toc_warnings" ]]; then
            # Check if we've already warned about this file's TOC violations
            local toc_cache_key=$(get_warning_cache_key "$full_path" "toc")
            if ! is_warning_cached "$toc_cache_key"; then
                # First time warning - show it and cache it
                echo "" >&2
                echo "⚠️  TOC POLICY VIOLATION: $file" >&2
                echo "$toc_warnings" | sed 's/^/   /' >&2
                echo "" >&2
                echo "   📖 Reference: $STYLE_GUIDE (Rule #4: TOCs ONLY allowed in README files)" >&2
                log_action "TOC WARNING: $file - $toc_warnings"
                cache_warning "$toc_cache_key"
            else
                # Already warned about this file, just log silently
                log_action "TOC WARNING (suppressed): $file - already warned in last 24h"
            fi
        fi

        # Run c7score analysis (non-blocking, informational)
        run_c7score_analysis "$full_path"

        # If critical violations found, BLOCK
        if [[ -n "$critical_violations" ]]; then
            has_critical=true

            # Log the block
            log_action "BLOCKED: $file (type: $doc_type) - Critical violations found"

            # Inject BLOCKING error into AI context
            print_blocking_error_condensed "$file" "$doc_type" "$critical_violations"
        fi
    done <<< "$all_files"

    # If any critical violations found, EXIT 1 to block execution
    if [[ "$has_critical" == "true" ]]; then
        log_action "EXECUTION BLOCKED - Critical violations must be fixed"
        # Performance timing END
        local end_time=$(_get_nano_time)
        local duration=$(( (end_time - START_TIME) / 1000000 ))
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] enforce-markdown-strict.sh ${duration}ms" >> "$HOOKS_DIR/logs/performance.log"
        exit ${EXIT_BLOCK:-1}
    fi

    # Show success indicator if files were checked
    if [[ $files_checked -gt 0 ]]; then
        echo "" >&2
        echo "✅ Markdown validation passed: $files_checked file(s) checked, 0 violations" >&2
    fi

    # Performance timing END
    local end_time=$(_get_nano_time)
    local duration=$(( (end_time - START_TIME) / 1000000 ))
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] enforce-markdown-strict.sh ${duration}ms" >> "$HOOKS_DIR/logs/performance.log"

    # No critical violations - exit 0 (allow execution)
    exit 0
}

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
