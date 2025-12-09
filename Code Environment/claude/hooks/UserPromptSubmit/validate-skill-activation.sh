#!/bin/bash

# ───────────────────────────────────────────────────────────────
# SKILL AUTO-ACTIVATION HOOK
# ───────────────────────────────────────────────────────────────
# Pre-UserPromptSubmit hook that analyzes prompts and suggests
# relevant skills based on keywords, intent, and file context
#
# PERFORMANCE TARGET: <100ms (pre-compiled skill data cache)
# COMPATIBILITY: Bash 3.2+ (macOS and Linux compatible)
#
# EXECUTION ORDER: UserPromptSubmit hook (runs BEFORE user prompt processing)
#   1. UserPromptSubmit hooks run FIRST (before processing user input)
#   2. PreToolUse hooks run SECOND (before tool execution, validation)
#   3. PostToolUse hooks run LAST (after tool completion, verification)
#   This hook: Analyzes prompts and suggests relevant skills
#
# EXIT CODE CONVENTION:
#   0 = Allow (hook passed, continue execution)
#   1 = Block (hook failed, stop execution with warning)
#   2 = Error (reserved for critical failures)
# ───────────────────────────────────────────────────────────────

# Source output helpers (completely silent on success)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" 2>/dev/null && pwd)"
source "$SCRIPT_DIR/../lib/output-helpers.sh" || exit 0
source "$SCRIPT_DIR/../lib/signal-output.sh" 2>/dev/null || true

# Cross-platform nanosecond timing helper
_get_nano_time() {
  if [[ "$OSTYPE" == "darwin"* ]]; then
    echo $(($(date +%s) * 1000000000))
  else
    date +%s%N 2>/dev/null || echo $(($(date +%s) * 1000000000))
  fi
}

# Standard separator for output formatting
SEPARATOR="───────────────────────────────────────────────────────────────"

# Performance timing START
START_TIME=$(_get_nano_time)

# Check dependencies (silent on success)
check_dependency "jq" "brew install jq (macOS) or apt install jq (Linux)" || exit 0

# Read JSON input from stdin
INPUT=$(cat)

# Extract the prompt from JSON (silent on error)
PROMPT=$(echo "$INPUT" | jq -r '.prompt // empty' 2>/dev/null)

# If no prompt found, allow it
if [ -z "$PROMPT" ]; then
  exit 0
fi

# Standardized config path resolution
PROJECT_ROOT=$(git rev-parse --show-toplevel 2>/dev/null || (cd "$SCRIPT_DIR/../.." && pwd))
CONFIGS_DIR="${CONFIGS_DIR:-$PROJECT_ROOT/.claude/configs}"

# Load skill rules configuration
SKILL_RULES="$CONFIGS_DIR/skill-rules.json"
SPECS_DIR="$PROJECT_ROOT/specs"
DOC_GUIDE="$PROJECT_ROOT/.claude/knowledge/conversation_documentation.md"

# Initialize log file paths early (used in error handling)
HOOKS_DIR="$(cd "$SCRIPT_DIR/.." 2>/dev/null && pwd)"
LOG_DIR="$HOOKS_DIR/logs"
mkdir -p "$LOG_DIR" 2>/dev/null
LOG_FILE="$LOG_DIR/skill-recommendations.log"

if [ ! -f "$SKILL_RULES" ]; then
  # No rules file, silently allow
  exit 0
fi

# Validate JSON
validate_json "$SKILL_RULES" || exit 0

# ───────────────────────────────────────────────────────────────
# PERFORMANCE: PRE-COMPILED SKILL DATA CACHE (90% IMPROVEMENT)
# ───────────────────────────────────────────────────────────────
# Cache ALL skill data in shell-sourceable format to eliminate
# 100+ jq subprocess spawns. Single jq execution builds cache.
# Target: <100ms execution (from 5160ms baseline = 98% reduction)

CACHE_DIR="/tmp/claude_hooks_cache"
CACHE_KEY=$(echo -n "$SKILL_RULES" | cksum | cut -d' ' -f1)
CACHE_FILE="$CACHE_DIR/skill_data_${CACHE_KEY}.sh"
mkdir -p "$CACHE_DIR" 2>/dev/null

# Get file modification time (platform-independent)
if [[ "$(uname)" == "Darwin" ]]; then
  # macOS
  RULES_MTIME=$(stat -f %m "$SKILL_RULES" 2>/dev/null || echo "0")
else
  # Linux
  RULES_MTIME=$(stat -c %Y "$SKILL_RULES" 2>/dev/null || echo "0")
fi

# Check if cache exists and is valid
USE_CACHE=false
if [[ -f "$CACHE_FILE" ]]; then
  CACHED_MTIME=$(head -n1 "$CACHE_FILE" 2>/dev/null | grep -oE '[0-9]+' | head -1)
  if [[ "$CACHED_MTIME" == "$RULES_MTIME" ]]; then
    USE_CACHE=true
  fi
fi

# Build or load cache
if [[ "$USE_CACHE" == "true" ]]; then
  # Load pre-compiled cache (instant, no jq subprocess)
  source "$CACHE_FILE" 2>/dev/null || USE_CACHE=false
fi

if [[ "$USE_CACHE" == "false" ]]; then
  # Cache miss or invalid - rebuild with SINGLE jq execution
  # Extract ALL data in one pass and generate complete shell script
  {
    echo "# MTIME=$RULES_MTIME"
    echo "# Auto-generated skill data cache - DO NOT EDIT"
    echo "# Generated: $(date)"
    echo ""

    jq -r '
      # Skill names array (inline, no subshell/while loop)
      ("SKILL_NAMES=(" + ([ .skills | keys[] | "\"" + . + "\"" ] | join(" ")) + ")"),
      "",

      # Generate shell variable assignments for all skill data
      (.skills | to_entries[] |
        (
          # Skill name
          "SKILL_\(.key | gsub("-"; "_") | ascii_upcase)_NAME=\"\(.key)\"",

          # Priority
          "SKILL_\(.key | gsub("-"; "_") | ascii_upcase)_PRIORITY=\"\(.value.priority // "medium")\"",

          # Description (escape quotes)
          "SKILL_\(.key | gsub("-"; "_") | ascii_upcase)_DESC=\"\(.value.description // "" | gsub("\""; "\\\""))\"",

          # Always active flag
          "SKILL_\(.key | gsub("-"; "_") | ascii_upcase)_ALWAYS=\"\(.value.alwaysActive // false)\"",

          # Keywords (newline-separated, pre-lowercased for performance)
          "SKILL_\(.key | gsub("-"; "_") | ascii_upcase)_KEYWORDS=\"\((.value.promptTriggers.keywords // []) | map(ascii_downcase) | join("\n"))\"",

          # Intent patterns (newline-separated, already case-insensitive)
          "SKILL_\(.key | gsub("-"; "_") | ascii_upcase)_INTENTS=\"\((.value.promptTriggers.intentPatterns // []) | join("\n"))\"",

          # Path patterns (newline-separated)
          "SKILL_\(.key | gsub("-"; "_") | ascii_upcase)_PATHS=\"\((.value.fileTriggers.pathPatterns // []) | join("\n"))\"",

          # Phase mapping for workflows-code (special case)
          if .key == "workflows-code" then
            "SKILL_WORKFLOWS_CODE_PHASE_IMPL_DESC=\"\(.value.phaseMapping.implementation.description // "")\"",
            "SKILL_WORKFLOWS_CODE_PHASE_DEBUG_DESC=\"\(.value.phaseMapping.debugging.description // "")\"",
            "SKILL_WORKFLOWS_CODE_PHASE_VERIFY_DESC=\"\(.value.phaseMapping.verification.description // "")\"",
            "SKILL_WORKFLOWS_CODE_PHASE_IMPL_SECTIONS=\"\(.value.phaseMapping.implementation.sections // "")\"",
            "SKILL_WORKFLOWS_CODE_PHASE_DEBUG_SECTIONS=\"\(.value.phaseMapping.debugging.sections // "")\"",
            "SKILL_WORKFLOWS_CODE_PHASE_VERIFY_SECTIONS=\"\(.value.phaseMapping.verification.sections // "")\""
          else
            empty
          end
        )
      )
    ' "$SKILL_RULES" 2>/dev/null
  } > "$CACHE_FILE"

  if [ $? -eq 0 ] && [ -f "$CACHE_FILE" ]; then
    # Load the newly created cache
    source "$CACHE_FILE" 2>/dev/null
  else
    # Fallback to non-cached operation
    SKILL_NAMES=$(jq -r '.skills | keys[]' "$SKILL_RULES" 2>/dev/null)
    if [ -z "$SKILL_NAMES" ]; then
      exit 0
    fi
    # Convert to array
    SKILL_NAMES=($SKILL_NAMES)
  fi
fi

# Verify we have skill data
if [ -z "${SKILL_NAMES[*]}" ]; then
  # Fallback: try to parse skill names directly
  SKILL_NAMES=$(jq -r '.skills | keys[]' "$SKILL_RULES" 2>/dev/null)
  if [ -z "$SKILL_NAMES" ]; then
    exit 0
  fi
  # Convert to array
  SKILL_NAMES=($SKILL_NAMES)
fi

# Convert prompt to lowercase for case-insensitive matching
PROMPT_LOWER=$(echo "$PROMPT" | tr '[:upper:]' '[:lower:]')

# Array to store matched skills
MATCHED_SKILLS=()

# ───────────────────────────────────────────────────────────────
# QUESTION DETECTION - Skip skill activation for questions
# ───────────────────────────────────────────────────────────────

# Check if prompt is a question (no modification intent)
# PRIORITY-BASED DETECTION:
# 0. Explanatory phrases override implementation keywords (explanation request)
# 1. Implementation keywords override question patterns (implementation request)
# 2. Pure question patterns without implementation keywords (read-only question)
is_question_prompt() {
  local text="$1"

  # Priority 0: Check for explanatory intent phrases
  # These override implementation keywords - user wants to UNDERSTAND, not DO
  if echo "$text" | grep -qiE "(help me understand|explain (how|why|what|the)|tell me about|describe (how|the|what)|can you explain|what does.*mean|how does.*work)"; then
    return 0  # Is a question (explanation request)
  fi

  # Priority 0.5: Check for analysis+issue patterns (likely leads to fixes)
  # These are NOT questions - they indicate upcoming code changes
  if echo "$text" | grep -qiE "analyze.*(issue|bug|problem|error|broken|not working|failing)"; then
    return 1  # Not a question (analysis with fix intent)
  fi

  # Priority 0.6: Check for investigation patterns with issues
  if echo "$text" | grep -qiE "(investigate|diagnose|troubleshoot|debug).*(issue|bug|problem|error)"; then
    return 1  # Not a question (investigation with fix intent)
  fi

  # Priority 0.7: Check for "Issue:" or "Bug:" headers in prompt
  if echo "$text" | grep -qiE "(^|[|:])\\s*(issue|bug|problem)\\s*:"; then
    return 1  # Not a question (issue report)
  fi

  # Priority 1: Check for implementation keywords
  # If found, this is an implementation request, NOT a question
  if echo "$text" | grep -qiE "(implement|create|add|build|fix|refactor|write|update|change|modify|remove|delete)"; then
    return 1  # Not a question (implementation request)
  fi

  # Priority 2: Check for question patterns (read-only intent)
  # Question starters at beginning of prompt
  if echo "$text" | grep -qiE "^(what|how|why|when|where|who|which|explain|tell me|show me|help me understand|describe)"; then
    return 0  # Is a question
  fi

  # Question mark at end (without implementation keywords from Priority 1)
  if echo "$text" | grep -qE '\?$'; then
    return 0  # Is a question
  fi

  return 1  # Not a question (default to allowing skill activation)
}

# Exit early if this is a question prompt
if is_question_prompt "$PROMPT_LOWER"; then
  exit 0  # No skills to activate for questions
fi

# ───────────────────────────────────────────────────────────────
# SECURITY: REGEX PATTERN VALIDATION
# ───────────────────────────────────────────────────────────────
# Validates regex patterns to prevent ReDoS (Regular Expression Denial of Service)
# attacks from compromised skill-rules.json configuration file
validate_regex_pattern() {
  local pattern="$1"

  # Check for dangerous ReDoS patterns:
  # 1. Nested quantifiers: (a+)+ or (a*)*
  # 2. Excessive wildcards: .*.*.* (3 or more in sequence)
  # 3. Overlapping alternation: (a|a)* or (ab|a)*
  # 4. Exponential backtracking patterns
  # 5. Pattern complexity limits

  # Check pattern length/complexity (increased from 100 to 200 for compound patterns)
  if [ ${#pattern} -gt 200 ]; then
    return 1  # Pattern too complex
  fi

  # Check for nested quantifiers (more comprehensive)
  if echo "$pattern" | grep -qE '\([^)]*[+*?{]\)[+*?{]'; then
    return 1  # Dangerous: nested quantifiers
  fi

  # Check for alternation with quantifiers
  if echo "$pattern" | grep -qE '\([^)]*\|[^)]*\)[+*?{]'; then
    return 1  # Dangerous: alternation with quantifier
  fi

  # Check for excessive consecutive wildcards
  if echo "$pattern" | grep -qE '(\.\*){3,}'; then
    return 1  # Dangerous: 3+ wildcards
  fi

  # Check for catastrophic backtracking patterns
  if echo "$pattern" | grep -qE '(.*\|.*){3,}'; then
    return 1  # Dangerous: multiple alternations with wildcards
  fi

  # Pattern is safe
  return 0
}

# ───────────────────────────────────────────────────────────────
# KEYWORD MATCHING (OPTIMIZED - NO JQ SUBPROCESS)
# ───────────────────────────────────────────────────────────────

# PERFORMANCE CRITICAL: Direct variable name construction
# Avoids subprocess spawning in hot loops (called 100+ times)
# Bash 3.2 compatible - uses single tr call instead of awk | tr
to_upper_underscore() {
  # Single subprocess: tr does BOTH uppercase AND hyphen replacement
  # This is 2x faster than: echo | awk | tr (2 subprocesses)
  echo "$1" | tr '[:lower:]-' '[:upper:]_'
}

check_keywords() {
  local var_prefix="$1"  # Pre-computed from caller to avoid subprocess
  local keywords_var="${var_prefix}_KEYWORDS"
  local keywords="${!keywords_var}"

  if [ -z "$keywords" ]; then
    return 1
  fi

  while IFS= read -r keyword; do
    if [ -n "$keyword" ]; then
      # Keywords are pre-lowercased in cache for performance

      # Validate pattern before use (security: prevent ReDoS)
      if ! validate_regex_pattern "\\b${keyword}\\b"; then
        # Skip dangerous pattern, log warning
        continue
      fi

      if echo "$PROMPT_LOWER" | grep -qE "\\b${keyword}\\b"; then
        return 0  # Match found
      fi
    fi
  done <<< "$keywords"

  return 1  # No match
}

# ───────────────────────────────────────────────────────────────
# INTENT PATTERN MATCHING (OPTIMIZED - NO JQ SUBPROCESS)
# ───────────────────────────────────────────────────────────────

check_intent_patterns() {
  local var_prefix="$1"  # Pre-computed from caller to avoid subprocess
  local patterns_var="${var_prefix}_INTENTS"
  local patterns="${!patterns_var}"

  if [ -z "$patterns" ]; then
    return 1
  fi

  while IFS= read -r pattern; do
    if [ -n "$pattern" ]; then
      # Validate pattern before use (security: prevent ReDoS)
      if ! validate_regex_pattern "$pattern"; then
        # Skip dangerous pattern, log warning
        continue
      fi

      if echo "$PROMPT_LOWER" | grep -qiE "$pattern"; then
        return 0  # Match found
      fi
    fi
  done <<< "$patterns"

  return 1  # No match
}

# ───────────────────────────────────────────────────────────────
# FILE CONTEXT MATCHING (OPTIMIZED - NO JQ SUBPROCESS)
# ───────────────────────────────────────────────────────────────

check_file_context() {
  local var_prefix="$1"  # Pre-computed from caller to avoid subprocess

  # Extract file paths mentioned in prompt (common patterns)
  local file_paths=$(echo "$PROMPT" | grep -oE '(src|specs|knowledge)/[a-zA-Z0-9_/.-]+' || echo "")

  if [ -z "$file_paths" ]; then
    return 1  # No file paths in prompt
  fi

  # Validate extracted paths
  local validated_paths=""
  while IFS= read -r file_path; do
    if [ -n "$file_path" ]; then
      # Check if path exists and is within project
      local full_path="$PROJECT_ROOT/$file_path"
      if [ -e "$full_path" ]; then
        local real_path=$(realpath "$full_path" 2>/dev/null)
        local project_real=$(realpath "$PROJECT_ROOT" 2>/dev/null)
        # Ensure path is within project (prevent path traversal)
        if [[ "$real_path" == "$project_real"* ]]; then
          validated_paths="${validated_paths}${file_path}"$'\n'
        fi
      fi
    fi
  done <<< "$file_paths"

  # Update file_paths to only validated ones
  file_paths="$validated_paths"

  if [ -z "$file_paths" ]; then
    return 1  # No valid file paths
  fi

  local paths_var="${var_prefix}_PATHS"
  local path_patterns="${!paths_var}"

  if [ -z "$path_patterns" ]; then
    return 1
  fi

  while IFS= read -r pattern; do
    if [ -n "$pattern" ]; then
      # Convert glob pattern to regex (proper escaping)
      # 1. Escape regex special chars (except * and ?)
      # 2. Convert ** to .* (match any depth)
      # 3. Convert * to [^/]* (match within directory)
      # 4. Convert ? to . (single character)
      regex_pattern=$(echo "$pattern" | \
        sed 's/\./\\./g' | \
        sed 's/+/\\+/g' | \
        sed 's/{/\\{/g' | \
        sed 's/}/\\}/g' | \
        sed 's/(/\\(/g' | \
        sed 's/)/\\)/g' | \
        sed 's/\[/\\[/g' | \
        sed 's/\]/\\]/g' | \
        sed 's/\*\*/.*/g' | \
        sed 's/\*/[^\/]*/g' | \
        sed 's/?/./g')

      # Validate pattern before use (security: prevent ReDoS)
      if ! validate_regex_pattern "$regex_pattern"; then
        # Skip dangerous pattern, log warning
        continue
      fi

      while IFS= read -r file_path; do
        if echo "$file_path" | grep -qE "$regex_pattern"; then
          return 0  # Match found
        fi
      done <<< "$file_paths"
    fi
  done <<< "$path_patterns"

  return 1  # No match
}

estimate_documentation_scope() {
  local text="$1"
  local level=2
  local loc=200
  local reason="Feature or multi-file change"

  if echo "$text" | grep -qiE "typo|misspell|spelling|grammar|whitespace"; then
    level=0
    loc=5
    reason="Minor typo/whitespace adjustment"
  elif echo "$text" | grep -qiE "rename|single file|small fix|docs only|readme"; then
    level=1
    loc=50
    reason="Single-file or documentation-only update"
  elif echo "$text" | grep -qiE "architecture|system|platform|rebuild|overhaul|multi-service|infra"; then
    level=3
    loc=600
    reason="Architecture/system-wide change"
  elif echo "$text" | grep -qiE "feature|component|integration|workflow|refactor|implement"; then
    level=2
    loc=200
    reason="Feature implementation or refactor"
  fi

  echo "$level|$loc|$reason"
}

# ───────────────────────────────────────────────────────────────
# LIFECYCLE PHASE DETECTION
# ───────────────────────────────────────────────────────────────
# Detects which development lifecycle phase the user is in:
# - Implementation: Creating new code, adding features
# - Debugging: Fixing bugs, investigating issues
# - Verification: Testing, checking browser, ready to deploy

detect_lifecycle_phase() {
  local text="$1"

  # Implementation phase indicators (writing new code)
  if echo "$text" | grep -qiE "(create|add|build|implement|develop|write|new feature|new component|initialize|setup|configure)"; then
    echo "implementation"
    return
  fi

  # Debugging phase indicators (fixing problems)
  if echo "$text" | grep -qiE "(debug|fix|error|bug|issue|problem|not working|broken|failing|investigate|troubleshoot|trace|diagnose)"; then
    echo "debugging"
    return
  fi

  # Verification phase indicators (testing/checking)
  if echo "$text" | grep -qiE "(test|verify|check browser|validate|confirm|looks complete|looks done|ready to deploy|ready to test|browser test|viewport|working correctly)"; then
    echo "verification"
    return
  fi

  # Default to implementation if unclear
  echo "implementation"
}

calculate_next_spec_number() {
  if [ ! -d "$SPECS_DIR" ]; then
    printf "%03d" 1
    return
  fi

  local max=0
  while IFS= read -r dir; do
    local base=$(basename "$dir")
    local num=${base%%-*}
    # Remove leading zeros and validate number
    num=$(echo "$num" | sed 's/^0*//')
    # Validate it's a number and in valid range (1-9999)
    if [[ "$num" =~ ^[1-9][0-9]*$ ]] && [ "$num" -lt 10000 ]; then
      if [ "$num" -gt "$max" ]; then
        max="$num"
      fi
    fi
  done < <(find "$SPECS_DIR" -maxdepth 1 -mindepth 1 -type d -name "[0-9]*-*" 2>/dev/null)

  printf "%03d" $((max + 1))
}

level_label() {
  case "$1" in
    1) echo "Level 1 (Simple)" ;;
    2) echo "Level 2 (Standard)" ;;
    3) echo "Level 3 (Complete)" ;;
    *) echo "Unknown Level" ;;
  esac
}

documentation_time_for_level() {
  case "$1" in
    1) echo "≈10 minutes" ;;
    2) echo "≈20 minutes" ;;
    3) echo "≈30 minutes" ;;
  esac
}

print_required_template_commands() {
  local level="$1"
  local spec_number="$2"
  case "$level" in
    1)
      echo "   cp .opencode/speckit/templates/spec.md specs/${spec_number}-your-feature-name/spec.md"
      ;;
    2)
      echo "   cp .opencode/speckit/templates/spec.md specs/${spec_number}-your-feature-name/spec.md"
      echo "   cp .opencode/speckit/templates/plan.md specs/${spec_number}-your-feature-name/plan.md"
      ;;
    3)
      echo "   /spec_kit:complete (auto-generates spec.md, plan.md, tasks.md, etc.)"
      ;;
  esac
}

print_optional_template_commands() {
  local level="$1"
  local spec_number="$2"
  case "$level" in
    1)
      echo "   cp .opencode/speckit/templates/checklist.md specs/${spec_number}-your-feature-name/checklist.md"
      ;;
    2)
      echo "   cp .opencode/speckit/templates/tasks.md specs/${spec_number}-your-feature-name/tasks.md"
      echo "   cp .opencode/speckit/templates/checklist.md specs/${spec_number}-your-feature-name/checklist.md"
      ;;
    3)
      echo "   cp .opencode/speckit/templates/tasks.md specs/${spec_number}-your-feature-name/tasks.md"
      echo "   cp .opencode/speckit/templates/checklist.md specs/${spec_number}-your-feature-name/checklist.md"
      echo "   cp .opencode/speckit/templates/decision-record.md specs/${spec_number}-your-feature-name/decision-record-topic.md"
      echo "   cp .opencode/speckit/templates/research-spike.md specs/${spec_number}-your-feature-name/research-spike-topic.md"
      echo "   cp .opencode/speckit/templates/research.md specs/${spec_number}-your-feature-name/research.md"
      ;;
  esac
}

print_conversation_doc_guidance() {
  echo ""
  echo "📊 Detected Intent: $DOC_SCOPE_REASON"
  echo "📏 Estimated LOC: ~${DOC_SCOPE_LOC} lines"
  echo "📋 Recommended Level: $(level_label "$DOC_SCOPE_LEVEL")"
  echo ""
  echo "🗂️  Next Spec Number: $NEXT_SPEC_NUMBER"
  echo "📁 Create Folder: specs/${NEXT_SPEC_NUMBER}-your-feature-name/"
  echo ""
  echo "📝 Required Templates:"
  print_required_template_commands "$DOC_SCOPE_LEVEL" "$NEXT_SPEC_NUMBER"

  local optional_templates=$(print_optional_template_commands "$DOC_SCOPE_LEVEL" "$NEXT_SPEC_NUMBER")
  if [ -n "$optional_templates" ]; then
    echo ""
    echo "💡 Optional Templates:"
    echo "$optional_templates"
  fi

  echo ""
  echo "📖 Guide: $DOC_GUIDE"
  echo "⚙️  Level Decision Tree: Section 2 of conversation_documentation.md"
  echo "⏱️  Estimated Documentation Time: $(documentation_time_for_level "$DOC_SCOPE_LEVEL")"
  echo ""
}

print_skill_evaluation_requirement() {
  local -a skills=("$@")

  echo ""
  echo "───────────────────────────────────────────────────────────────"
  echo "⚡ MANDATORY SKILL EVALUATION - REQUIRED BEFORE IMPLEMENTATION"
  echo "───────────────────────────────────────────────────────────────"
  echo ""
  echo "You MUST evaluate each skill above before proceeding:"
  echo ""
  echo "For each skill listed:"
  echo "  1. State: YES (will apply) or NO (not applicable)"
  echo "  2. Provide brief reason (one sentence)"
  echo "  3. If YES: Activate using Skill tool"
  echo ""
  echo "Required format:"
  for skill_item in "${skills[@]}"; do
    # Pure Bash string manipulation (no subprocess)
    skill_name="${skill_item%%|*}"
    echo "  [$skill_name]: YES/NO - [your reason]"
  done
  echo ""
  echo "After evaluation, proceed with implementation."
  echo "───────────────────────────────────────────────────────────────"
  echo ""
}

# ───────────────────────────────────────────────────────────────
# SKILL EVALUATION (OPTIMIZED - CACHE VARIABLES INSTEAD OF JQ)
# ───────────────────────────────────────────────────────────────

# Initialize documentation scope variables (must be after function definitions)
DOC_SCOPE_INFO=$(estimate_documentation_scope "$PROMPT_LOWER")
DOC_SCOPE_LEVEL=${DOC_SCOPE_INFO%%|*}
DOC_SCOPE_REMAINDER=${DOC_SCOPE_INFO#*|}
DOC_SCOPE_LOC=${DOC_SCOPE_REMAINDER%%|*}
DOC_SCOPE_REASON=${DOC_SCOPE_INFO##*|}
NEXT_SPEC_NUMBER=$(calculate_next_spec_number)

# Iterate through all skills using cached data
for skill_name in "${SKILL_NAMES[@]}"; do
  if [ -z "$skill_name" ]; then
    continue
  fi

  # Get cached skill data using variable indirection
  # Compute var_prefix ONCE per skill using optimized tr (single subprocess)
  var_prefix=$(echo "$skill_name" | tr '[:lower:]-' '[:upper:]_')
  var_prefix="SKILL_${var_prefix}"
  always_var="${var_prefix}_ALWAYS"

  if [ "${!always_var}" = "true" ]; then
    MATCHED_SKILLS+=("$skill_name")
    continue
  fi

  # Check keyword matches (pass pre-computed var_prefix)
  if check_keywords "$var_prefix"; then
    MATCHED_SKILLS+=("$skill_name")
    continue
  fi

  # Check intent pattern matches (pass pre-computed var_prefix)
  if check_intent_patterns "$var_prefix"; then
    MATCHED_SKILLS+=("$skill_name")
    continue
  fi

  # Check file context matches (pass pre-computed var_prefix)
  if check_file_context "$var_prefix"; then
    MATCHED_SKILLS+=("$skill_name")
    continue
  fi
done

# ───────────────────────────────────────────────────────────────
# GENERATE SKILL ACTIVATION MESSAGE
# ───────────────────────────────────────────────────────────────

# Detect lifecycle phase for workflow guidance
DETECTED_PHASE=$(detect_lifecycle_phase "$PROMPT_LOWER")

if [ ${#MATCHED_SKILLS[@]} -eq 0 ]; then
  # No skills matched, exit silently
  # Performance timing END (silent path)
  END_TIME=$(_get_nano_time)
  DURATION=$(( (END_TIME - START_TIME) / 1000000 ))
  [ -d "$HOOKS_DIR/logs" ] || mkdir -p "$HOOKS_DIR/logs" 2>/dev/null
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] validate-skill-activation.sh ${DURATION}ms (no-match)" >> "$HOOKS_DIR/logs/performance.log"
  exit 0
fi

# Build activation message
ACTIVATION_MSG=""
CRITICAL_SKILLS=()
HIGH_SKILLS=()
MEDIUM_SKILLS=()
CONV_DOC_REQUIRED=false
WORKFLOWS_CODE_MATCHED=false

for skill in "${MATCHED_SKILLS[@]}"; do
  # Get priority and description from cached variables
  # Compute var_prefix ONCE per matched skill using optimized tr (single subprocess)
  var_prefix=$(echo "$skill" | tr '[:lower:]-' '[:upper:]_')
  var_prefix="SKILL_${var_prefix}"
  priority_var="${var_prefix}_PRIORITY"
  desc_var="${var_prefix}_DESC"
  priority="${!priority_var}"
  description="${!desc_var}"

  # Add phase guidance for workflows-code
  if [ "$skill" = "workflows-code" ]; then
    WORKFLOWS_CODE_MATCHED=true
    # Use pre-cached phase data
    case "$DETECTED_PHASE" in
      implementation)
        phase_desc="${SKILL_WORKFLOWS_CODE_PHASE_IMPL_DESC}"
        phase_sections="${SKILL_WORKFLOWS_CODE_PHASE_IMPL_SECTIONS}"
        ;;
      debugging)
        phase_desc="${SKILL_WORKFLOWS_CODE_PHASE_DEBUG_DESC}"
        phase_sections="${SKILL_WORKFLOWS_CODE_PHASE_DEBUG_SECTIONS}"
        ;;
      verification)
        phase_desc="${SKILL_WORKFLOWS_CODE_PHASE_VERIFY_DESC}"
        phase_sections="${SKILL_WORKFLOWS_CODE_PHASE_VERIFY_SECTIONS}"
        ;;
    esac
    description="$description | Start with ${DETECTED_PHASE^} Phase ($phase_sections): $phase_desc"
  fi

  case "$priority" in
    critical)
      CRITICAL_SKILLS+=("$skill|$description")
      ;;
    high)
      HIGH_SKILLS+=("$skill|$description")
      ;;
    medium)
      MEDIUM_SKILLS+=("$skill|$description")
      ;;
  esac

  if [ "$skill" = "conversation-documentation" ]; then
    CONV_DOC_REQUIRED=true
  fi
done


# ───────────────────────────────────────────────────────────────
# DISPLAY MANDATORY SKILLS TO USER
# ───────────────────────────────────────────────────────────────

# Display MANDATORY priority skills to user (others logged only)
if [ ${#CRITICAL_SKILLS[@]} -gt 0 ]; then
  # Build systemMessage for visible output
  SKILL_MSG="🔴 MANDATORY SKILLS - MUST BE APPLIED:\\n"
  SKILL_MSG="${SKILL_MSG}⚠️  Proceeding without these skills will result in incomplete/incorrect implementation.\\n\\n"
  
  for item in "${CRITICAL_SKILLS[@]}"; do
    # Pure Bash string manipulation (no subprocess)
    skill_name="${item%%|*}"   # Remove from first | to end
    desc="${item#*|}"          # Remove from start to first |

    # Smart truncation at 100 chars with word boundary preservation
    if [ ${#desc} -gt 100 ]; then
      desc_short="${desc:0:97}"  # Leave room for "..."
      # Truncate at last space to avoid mid-word cut
      desc_short="${desc_short% *}..."
    else
      desc_short="$desc"
    fi

    SKILL_MSG="${SKILL_MSG}   • $skill_name - $desc_short\\n"
  done
  
  # Output as systemMessage JSON for Claude Code visibility
  echo "{\"systemMessage\": \"${SKILL_MSG}\"}"

  # NEW: Add evaluation requirement
  print_skill_evaluation_requirement "${CRITICAL_SKILLS[@]}"

  if [ "$CONV_DOC_REQUIRED" = true ]; then
    print_conversation_doc_guidance
  fi
fi

# ───────────────────────────────────────────────────────────────
# LOG ALL MATCHED SKILLS TO FILE
# ───────────────────────────────────────────────────────────────

# Only log if there are skills to recommend
# Log to file instead of stderr to keep interface clean
# Note: LOG_DIR and LOG_FILE already initialized at script start

# Rotate log if it is getting large (best-effort, non-blocking)
rotate_log_if_needed "$LOG_FILE" 102400

# Prepare log entry with timestamp
TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')

# Write to log file
{
  echo ""
  echo "$SEPARATOR"
  echo "[$TIMESTAMP] SKILL RECOMMENDATIONS"
  echo "$SEPARATOR"
  echo "Prompt: ${PROMPT:0:100}..."
  echo "$SEPARATOR"


  # Format output by priority
  if [ ${#CRITICAL_SKILLS[@]} -gt 0 ]; then
    echo ""
    echo "🔴 MANDATORY (Must Apply)"
    for item in "${CRITICAL_SKILLS[@]}"; do
      skill_name=$(echo "$item" | cut -d'|' -f1)
      desc=$(echo "$item" | cut -d'|' -f2)
      echo "   • $skill_name"
      echo "     $desc"
    done
  fi

  if [ ${#HIGH_SKILLS[@]} -gt 0 ]; then
    echo ""
    echo "🟡 HIGH PRIORITY (Strongly Recommended)"
    for item in "${HIGH_SKILLS[@]}"; do
      skill_name=$(echo "$item" | cut -d'|' -f1)
      desc=$(echo "$item" | cut -d'|' -f2)
      echo "   • $skill_name"
      echo "     $desc"
    done
  fi

  if [ ${#MEDIUM_SKILLS[@]} -gt 0 ]; then
    echo ""
    echo "🔵 RELEVANT SKILLS (Consider)"
    for item in "${MEDIUM_SKILLS[@]}"; do
      skill_name=$(echo "$item" | cut -d'|' -f1)
      desc=$(echo "$item" | cut -d'|' -f2)
      echo "   • $skill_name"
      echo "     $desc"
    done
  fi

  echo ""
  echo "$SEPARATOR"
  echo ""
} >> "$LOG_FILE"

# Performance timing END
END_TIME=$(_get_nano_time)
DURATION=$(( (END_TIME - START_TIME) / 1000000 ))
# Ensure log directory exists
[ -d "$HOOKS_DIR/logs" ] || mkdir -p "$HOOKS_DIR/logs" 2>/dev/null
echo "[$(date '+%Y-%m-%d %H:%M:%S')] validate-skill-activation.sh ${DURATION}ms (${#MATCHED_SKILLS[@]} matched)" >> "$HOOKS_DIR/logs/performance.log"

# Allow the request to proceed silently (exit 0)
exit 0
