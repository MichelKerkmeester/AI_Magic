#!/bin/bash

# ───────────────────────────────────────────────────────────────
# INTELLIGENT SEMANTIC SEARCH SUGGESTION HOOK
# ───────────────────────────────────────────────────────────────
# Pre-UserPromptSubmit hook that suggests semantic search MCP tools
# for intelligent code exploration based on contextual prompt analysis
#
# ENHANCEMENTS (v2.0.0):
# - Contextual pattern matching (exploration vs implementation)
# - Integration with validate-skill-activation.sh (avoid duplication)
# - Query template suggestions (actionable guidance)
# - Architecture/relationship awareness
# - Deduplication to prevent spam
#
# PERFORMANCE TARGET: <50ms (lightweight pattern matching)
# COMPATIBILITY: Bash 3.2+ (macOS and Linux compatible)
#
# EXECUTION ORDER: UserPromptSubmit hook (runs BEFORE user prompt processing)
#   1. UserPromptSubmit hooks run FIRST (before processing user input)
#   2. PreToolUse hooks run SECOND (before tool execution, validation)
#   3. PostToolUse hooks run LAST (after tool completion, verification)
#   This hook: Suggests semantic search for intelligent code exploration
#
# EXIT CODE CONVENTION:
#   0 = Allow (hook passed, continue execution)
#   1 = Block (hook failed, stop execution with warning)
#   2 = Error (reserved for critical failures)
# ───────────────────────────────────────────────────────────────

# Source output helpers (completely silent on success)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" 2>/dev/null && pwd)"
HOOKS_DIR="$(cd "$SCRIPT_DIR/.." 2>/dev/null && pwd)"
source "$HOOKS_DIR/lib/output-helpers.sh" || exit 0

# Logging configuration
LOG_DIR="$HOOKS_DIR/logs"
LOG_FILE="$LOG_DIR/$(basename "$0" .sh).log"

# Performance timing START
START_TIME=$(date +%s%N)

# Read JSON input from stdin
INPUT=$(cat)

# Extract the prompt from JSON (silent on error)
PROMPT=$(echo "$INPUT" | jq -r '.prompt // empty' 2>/dev/null)

# If no prompt found, allow it
if [ -z "$PROMPT" ]; then
  exit 0
fi

# Convert prompt to lowercase for case-insensitive matching
PROMPT_LOWER=$(echo "$PROMPT" | tr '[:upper:]' '[:lower:]')

# ───────────────────────────────────────────────────────────────
# INTELLIGENT TRIGGER PATTERNS
# ───────────────────────────────────────────────────────────────
# Context-aware triggers for different exploration scenarios
# Note: validate-skill-activation.sh now has mcp-semantic-search in
# skill-rules.json, so both hooks provide complementary suggestions:
# - validate-skill-activation.sh: Skill descriptions and documentation
# - This hook: Contextual query templates and exploration guidance

SHOULD_SUGGEST=false
SUGGESTION_TYPE=""
QUERY_TEMPLATE=""

# Pattern 1: EXPLORATORY QUESTIONS (Where/How/What implemented?)
if echo "$PROMPT_LOWER" | grep -qiE '\b(where (is|are|does|do)|how (is|are|does|do)|what (handles|implements|manages))\b.*\b(implemented|handled|defined|located|stored|managed)\b'; then
  SHOULD_SUGGEST=true
  SUGGESTION_TYPE="exploratory"

  # Extract feature/functionality from prompt
  FEATURE=$(echo "$PROMPT_LOWER" | sed -E 's/.*\b(where|how|what)\b.*\b(is|are|does|do)\b[[:space:]]*//; s/\b(implemented|handled|defined|located|stored|managed)\b.*//')
  QUERY_TEMPLATE="Find code that handles $FEATURE"
fi

# Pattern 2: ARCHITECTURE UNDERSTANDING (How does X work?)
if [ "$SHOULD_SUGGEST" = false ]; then
  if echo "$PROMPT_LOWER" | grep -qiE '\b(how does|how do|explain how|understand how|show me how)\b.*(work|function|operate|integrate)'; then
    SHOULD_SUGGEST=true
    SUGGESTION_TYPE="architecture"

    COMPONENT=$(echo "$PROMPT_LOWER" | sed -E 's/.*\b(how does|how do|explain how|understand how|show me how)\b[[:space:]]*//; s/\b(work|function|operate|integrate)\b.*//')
    QUERY_TEMPLATE="How does $COMPONENT work?"
  fi
fi

# Pattern 3: CODE NAVIGATION (Find all uses/patterns/similar)
if [ "$SHOULD_SUGGEST" = false ]; then
  if echo "$PROMPT_LOWER" | grep -qiE '\b(find all|show all|list all|locate all)\b.*(uses|usage|patterns|implementations|instances|occurrences)'; then
    SHOULD_SUGGEST=true
    SUGGESTION_TYPE="navigation"

    PATTERN=$(echo "$PROMPT_LOWER" | sed -E 's/.*\b(find all|show all|list all|locate all)\b[[:space:]]*//; s/\b(uses|usage|patterns|implementations|instances|occurrences)\b.*//')
    QUERY_TEMPLATE="Find all $PATTERN usage patterns"
  fi
fi

# Pattern 4: RELATIONSHIP DISCOVERY (What depends on/interacts with X?)
if [ "$SHOULD_SUGGEST" = false ]; then
  if echo "$PROMPT_LOWER" | grep -qiE '\b(what (depends on|uses|calls|interacts with|is related to)|which (components|modules|files) (use|depend on|interact with))\b'; then
    SHOULD_SUGGEST=true
    SUGGESTION_TYPE="relationships"

    ENTITY=$(echo "$PROMPT_LOWER" | sed -E 's/.*\b(depends on|uses|calls|interacts with|is related to|use|depend on|interact with)\b[[:space:]]*//; s/[[:space:]]*\?.*//')
    QUERY_TEMPLATE="What code depends on $ENTITY?"
  fi
fi

# Pattern 5: FEATURE DISCOVERY (Show me error handling/auth/etc patterns)
if [ "$SHOULD_SUGGEST" = false ]; then
  if echo "$PROMPT_LOWER" | grep -qiE '\b(show me|find|locate|where).*(error handling|authentication|authorization|validation|logging|caching|state management|data flow)\b'; then
    SHOULD_SUGGEST=true
    SUGGESTION_TYPE="feature_discovery"

    FEATURE=$(echo "$PROMPT_LOWER" | grep -oiE '(error handling|authentication|authorization|validation|logging|caching|state management|data flow)' | head -1)
    QUERY_TEMPLATE="Find $FEATURE implementation patterns"
  fi
fi

# Pattern 6: REFACTORING CONTEXT (Find similar components to refactor)
if [ "$SHOULD_SUGGEST" = false ]; then
  if echo "$PROMPT_LOWER" | grep -qiE '\b(find similar|show similar|locate similar|identify similar)\b.*(components?|modules?|functions?|patterns?|code)'; then
    SHOULD_SUGGEST=true
    SUGGESTION_TYPE="refactoring"

    TARGET=$(echo "$PROMPT_LOWER" | sed -E 's/.*\b(find similar|show similar|locate similar|identify similar)\b[[:space:]]*//; s/\b(components?|modules?|functions?|patterns?|code)\b.*//')
    QUERY_TEMPLATE="Find components similar to $TARGET"
  fi
fi

# ───────────────────────────────────────────────────────────────
# OUTPUT CONTEXTUAL SUGGESTION
# ───────────────────────────────────────────────────────────────

if [ "$SHOULD_SUGGEST" = true ]; then
  echo ""
  echo "💡 Code Exploration Detected - Semantic Search Recommended"
  echo "───────────────────────────────────────────────────────────────"

  case "$SUGGESTION_TYPE" in
    exploratory)
      echo "Context: You're exploring where/how functionality is implemented"
      echo "Tool: Use search_codebase() via mcp-code-mode for intent-based discovery"
      ;;
    architecture)
      echo "Context: You're understanding how components work together"
      echo "Tool: Use search_codebase() to find related code and dependencies"
      ;;
    navigation)
      echo "Context: You're navigating usage patterns across the codebase"
      echo "Tool: Use search_codebase() for comprehensive pattern discovery"
      ;;
    relationships)
      echo "Context: You're discovering code relationships and dependencies"
      echo "Tool: Use search_codebase() with relationship queries"
      ;;
    feature_discovery)
      echo "Context: You're finding implementation patterns for features"
      echo "Tool: Use search_codebase() to discover feature implementations"
      ;;
    refactoring)
      echo "Context: You're identifying similar code for refactoring"
      echo "Tool: Use search_codebase() to find similar patterns"
      ;;
  esac

  echo ""
  echo "Suggested Query Template:"
  echo "  \"$QUERY_TEMPLATE\""
  echo ""
  echo "Why Semantic Search?"
  echo "  ✓ Finds code by what it does (not just what it's called)"
  echo "  ✓ Understands intent and relationships"
  echo "  ✓ Returns ranked results with context"
  echo ""
  echo "How to Use:"
  echo "  1. Activate: Use Skill tool to load 'mcp-semantic-search' skill"
  echo "  2. Execute: Use mcp-code-mode to run search_codebase(\"your query\")"
  echo "  3. Follow-up: Read specific files for full context"
  echo ""
  echo "Documentation:"
  echo "  📖 Semantic Search: .claude/skills/mcp-semantic-search/SKILL.md"
  echo "  📖 Code Mode: .claude/skills/mcp-code-mode/SKILL.md"
  echo "  📖 Query Examples: .claude/skills/mcp-semantic-search/assets/query_examples.md"
  echo "───────────────────────────────────────────────────────────────"
  echo ""

  # Log suggestion
  mkdir -p "$LOG_DIR"
  {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] SEMANTIC SEARCH SUGGESTION"
    echo "Type: $SUGGESTION_TYPE"
    echo "Prompt: ${PROMPT:0:100}..."
    echo "Template: $QUERY_TEMPLATE"
    echo "───────────────────────────────────────────────────────────────"
  } >> "$LOG_FILE"
fi

# Performance timing END
END_TIME=$(date +%s%N)
DURATION=$(( (END_TIME - START_TIME) / 1000000 ))
echo "[$(date '+%Y-%m-%d %H:%M:%S')] suggest-semantic-search.sh ${DURATION}ms" >> "$HOOKS_DIR/logs/performance.log"

# Always allow the prompt to proceed
exit 0
