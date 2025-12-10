#!/bin/bash
# PostToolUse Hook: suggest-cli-verification.sh
# Detects frontend code changes (JS, CSS) and suggests CLI verification workflow
# Performance target: <100ms
# Exit codes: 0 (allow, non-blocking suggestion), 1 (block - not used), 2 (error)

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Configuration
LOG_FILE="$SCRIPT_DIR/../logs/quality-checks.log"
START_TIME=$(date +%s)
SITE_URL="${SITE_URL:-https://example.com}"

# Parse tool input from stdin
TOOL_INPUT=$(cat)

# Extract tool name (use .tool_name which is the actual JSON field)
TOOL_NAME=$(echo "$TOOL_INPUT" | jq -r '.tool_name // .toolName // .tool // empty')

# Only process Write, Edit, NotebookEdit tools
if [[ ! "$TOOL_NAME" =~ ^(Write|Edit|NotebookEdit)$ ]]; then
  exit 0
fi

# Extract file path from tool_input (support both snake_case and camelCase)
FILE_PATH=$(echo "$TOOL_INPUT" | jq -r '
  .tool_input.file_path //
  .tool_input.filePath //
  .tool_input.path //
  .tool_input.notebook_path //
  .parameters.file_path //
  .parameters.filePath //
  .parameters.path //
  .parameters.notebook_path //
  empty
')

# Exit if no file path found
if [[ -z "$FILE_PATH" ]]; then
  exit 0
fi

# Detect frontend code changes (JS or CSS files)
# Pattern: Match .js or .css files in src/ directory
if [[ "$FILE_PATH" =~ src/.*\.(js|css)$ ]]; then
  # Log detection
  echo "[$(date +'%Y-%m-%d %H:%M:%S')] Frontend code modified: $FILE_PATH" >> "$LOG_FILE"

  # Print suggestion (non-blocking)
  echo ""
  echo "💡 SUGGESTION: Frontend code modified"
  echo "───────────────────────────────────────────────────────────────"
  echo "File: $FILE_PATH"
  echo ""
  echo "Consider running CLI verification:"
  echo ""
  echo "   # Quick browser verification"
  echo "   bdg $SITE_URL 2>&1"
  echo "   bdg screenshot verification.png 2>&1"
  echo "   bdg console logs 2>&1 | jq '.[] | select(.level==\"error\")'"
  echo "   bdg stop 2>&1"
  echo ""
  echo "📖 Full workflows:"
  echo "   - Verification: .claude/skills/workflows-code/references/verification_workflows.md (Section 2.5 Option 2)"
  echo "   - Debugging: .claude/skills/workflows-code/references/debugging_workflows.md (Section 7)"
  echo "   - Performance: .claude/skills/workflows-code/references/performance_patterns.md (Section 3)"
  echo "───────────────────────────────────────────────────────────────"
  echo ""
  
  # Emit systemMessage for Claude Code visibility
  visible_msg=$(jq -n --arg msg "💡 Frontend modified: $(basename "$FILE_PATH"). Consider CLI verification with bdg commands." '{systemMessage: $msg}')
  echo "$visible_msg"
fi

# Performance tracking (log only, no threshold check)
END_TIME=$(date +%s)
DURATION=$((END_TIME - START_TIME))
echo "[$(date +'%Y-%m-%d %H:%M:%S')] suggest-cli-verification.sh completed in ${DURATION}s (tool: $TOOL_NAME, matched: $([ -n "$FILE_PATH" ] && [[ "$FILE_PATH" =~ src/.*\.(js|css)$ ]] && echo 'yes' || echo 'no'))" >> "$LOG_FILE"

# Exit 0 (allow, non-blocking suggestion)
exit 0
