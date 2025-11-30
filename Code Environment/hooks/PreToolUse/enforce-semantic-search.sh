#!/bin/bash

# ───────────────────────────────────────────────────────────────
# SEMANTIC SEARCH EDUCATIONAL ENFORCEMENT HOOK
# ───────────────────────────────────────────────────────────────
# PreToolUse hook that educates AI about semantic search vs grep
# usage patterns for code exploration tasks
#
# VERSION: 1.0.0 (educational warnings only, exit 0)
# PERFORMANCE TARGET: <50ms (simple pattern matching)
# COMPATIBILITY: Bash 3.2+ (macOS and Linux compatible)
#
# EXECUTION ORDER: PreToolUse hook (runs BEFORE tool execution)
#   1. UserPromptSubmit hooks run FIRST
#   2. PreToolUse hooks run SECOND (this hook)
#   3. Tool executes THIRD
#   4. PostToolUse hooks run LAST
#
# EXIT CODE CONVENTION:
#   0 = Allow (always, educational only)
#   1 = Block (not used in v1.0.0)
#
# FUTURE: Upgrade to exit 1 (blocking) after monitoring validates
#         false positive rate <20% over 1 week period
# ───────────────────────────────────────────────────────────────

# Source output helpers
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" 2>/dev/null && pwd)"
HOOKS_DIR="$(cd "$SCRIPT_DIR/.." 2>/dev/null && pwd)"
source "$HOOKS_DIR/lib/output-helpers.sh" || exit 0
source "$HOOKS_DIR/lib/exit-codes.sh" || exit 0

# Logging configuration
LOG_DIR="$HOOKS_DIR/logs"
mkdir -p "$LOG_DIR" 2>/dev/null
LOG_FILE="$LOG_DIR/$(basename "$0" .sh).log"

# Performance timing START
START_TIME=$(date +%s%N)

# Read JSON input from stdin
INPUT=$(cat)

# Check dependencies
check_dependency "jq" "brew install jq (macOS) or apt install jq (Linux)" || exit 0

# Extract tool name and parameters
TOOL=$(echo "$INPUT" | jq -r '.tool // empty' 2>/dev/null)
PARAMS=$(echo "$INPUT" | jq -r '.parameters // {}' 2>/dev/null)

# Only check Grep tool (not Read/Glob - those have legitimate uses)
if [ "$TOOL" != "Grep" ]; then
  exit 0
fi

# Extract grep pattern
PATTERN=$(echo "$PARAMS" | jq -r '.pattern // ""' 2>/dev/null)

# Check if pattern looks like behavioral search (not literal symbol search)
# Behavioral patterns: implement, handle, manage, process, validate, initialize
# These suggest code intent, not specific symbols
if echo "$PATTERN" | grep -qiE '\b(implement|handle|manage|process|validate|initialize|execute|perform|trigger|calculate|compute|determine)\b'; then

  # Log detection
  {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] BEHAVIORAL SEARCH DETECTED"
    echo "Tool: Grep"
    echo "Pattern: $PATTERN"
    echo "Suggestion: Use semantic search instead"
    echo "───────────────────────────────────────────────────────────────"
  } >> "$LOG_FILE"

  # Educational output to AI
  echo ""
  echo "💡 Educational Guidance - Semantic Search Recommended"
  echo "═══════════════════════════════════════════════════════════════"
  echo ""
  echo "Pattern Detected: Behavioral search using Grep"
  echo "Your pattern: \"$PATTERN\""
  echo ""
  echo "⚠️  This looks like you're searching for code BEHAVIOR, not literal text."
  echo ""
  echo "Why Semantic Search is Better:"
  echo "  ✓ Finds code by WHAT IT DOES (not what it's called)"
  echo "  ✓ Understands relationships and dependencies"
  echo "  ✓ Returns ranked results with context"
  echo "  ✓ Works across different naming conventions"
  echo ""
  echo "Example Comparison:"
  echo "  ❌ Grep: pattern='validate.*email' → only finds literal matches"
  echo "  ✅ Semantic: query='Find code that validates email addresses'"
  echo "             → finds isEmailValid(), checkEmail(), validateEmailFormat(), etc."
  echo ""
  echo "How to Use Semantic Search:"
  echo "  1. Load skill: Use Skill tool with 'mcp-semantic-search'"
  echo "  2. Execute: Use mcp-code-mode with search_codebase(\"your natural language query\")"
  echo "  3. Follow-up: Read specific files for full context"
  echo ""
  echo "Example Query for Your Search:"
  # Try to convert pattern to natural language query
  BEHAVIOR=$(echo "$PATTERN" | grep -oiE '\b(implement|handle|manage|process|validate|initialize|execute|perform|trigger|calculate|compute|determine)\b' | head -1)
  echo "  search_codebase(\"Find code that ${BEHAVIOR}s the functionality\")"
  echo ""
  echo "Documentation:"
  echo "  📖 .claude/skills/mcp-semantic-search/SKILL.md"
  echo "  📖 .claude/skills/mcp-code-mode/SKILL.md"
  echo "  📖 AGENTS.md (line 716 - Tool Routing)"
  echo ""
  echo "═══════════════════════════════════════════════════════════════"
  echo ""
  echo "Note: This is educational guidance only. Grep will still execute."
  echo "      Future versions may block behavioral searches."
  echo ""
fi

# Performance timing END
END_TIME=$(date +%s%N)
DURATION=$(( (END_TIME - START_TIME) / 1000000 ))
echo "[$(date '+%Y-%m-%d %H:%M:%S')] enforce-semantic-search.sh ${DURATION}ms" >> "$HOOKS_DIR/logs/performance.log"

# Always allow (educational only in v1.0.0)
exit $EXIT_SUCCESS
