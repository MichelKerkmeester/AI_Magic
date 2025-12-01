#!/bin/bash

# ───────────────────────────────────────────────────────────────
# MCP TOOLS SUGGESTION HOOK (UNIFIED)
# ───────────────────────────────────────────────────────────────
# UserPromptSubmit hook that detects MCP platform usage and workflows,
# then suggests Code Mode for optimal efficiency.
#
# MERGED FROM:
# - suggest-code-mode.sh (pattern detection for CMS, design, browser)
# - detect-mcp-workflow.sh (multi-platform workflow detection)
#
# PERFORMANCE TARGET: <50ms (single-pass pattern matching)
# COMPATIBILITY: Bash 3.2+ (macOS and Linux compatible)
#
# DETECTS:
# - MCP platforms: webflow, figma, notion, github, clickup, chrome
# - Semantic search opportunities
# - Multi-step workflows and cross-platform integrations
#
# EXIT CODE CONVENTION:
#   0 = Allow (hook passed, continue execution)
#   1 = Block (hook failed, stop execution with warning)
#   2 = Error (reserved for critical failures)
# ───────────────────────────────────────────────────────────────

# Source output helpers (completely silent on success)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" 2>/dev/null && pwd)"
HOOKS_DIR="$(cd "$SCRIPT_DIR/.." 2>/dev/null && pwd)"
source "$HOOKS_DIR/lib/output-helpers.sh" 2>/dev/null || true

# Logging configuration
LOG_DIR="$HOOKS_DIR/logs"
LOG_FILE="$LOG_DIR/$(basename "$0" .sh).log"
mkdir -p "$LOG_DIR" 2>/dev/null

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
# SINGLE-PASS PATTERN DETECTION
# ───────────────────────────────────────────────────────────────

# Platform detection (count mentions)
WEBFLOW_COUNT=$(echo "$PROMPT_LOWER" | grep -o "webflow" | wc -l | tr -d ' ')
FIGMA_COUNT=$(echo "$PROMPT_LOWER" | grep -o "figma" | wc -l | tr -d ' ')
NOTION_COUNT=$(echo "$PROMPT_LOWER" | grep -o "notion" | wc -l | tr -d ' ')
GITHUB_COUNT=$(echo "$PROMPT_LOWER" | grep -o "github" | wc -l | tr -d ' ')
CLICKUP_COUNT=$(echo "$PROMPT_LOWER" | grep -o "clickup" | wc -l | tr -d ' ')
CHROME_COUNT=$(echo "$PROMPT_LOWER" | grep -o -E "chrome|devtools|screenshot|browser automation" | wc -l | tr -d ' ')
SEMANTIC_COUNT=$(echo "$PROMPT_LOWER" | grep -o -E "semantic search|code search|find.*implementation|search.*codebase" | wc -l | tr -d ' ')

# Calculate total platforms (Bash 3.2 compatible - avoid ((var++)) edge case)
TOTAL_PLATFORMS=0
[ "$WEBFLOW_COUNT" -gt 0 ] && TOTAL_PLATFORMS=$((TOTAL_PLATFORMS + 1))
[ "$FIGMA_COUNT" -gt 0 ] && TOTAL_PLATFORMS=$((TOTAL_PLATFORMS + 1))
[ "$NOTION_COUNT" -gt 0 ] && TOTAL_PLATFORMS=$((TOTAL_PLATFORMS + 1))
[ "$GITHUB_COUNT" -gt 0 ] && TOTAL_PLATFORMS=$((TOTAL_PLATFORMS + 1))
[ "$CLICKUP_COUNT" -gt 0 ] && TOTAL_PLATFORMS=$((TOTAL_PLATFORMS + 1))
[ "$CHROME_COUNT" -gt 0 ] && TOTAL_PLATFORMS=$((TOTAL_PLATFORMS + 1))
[ "$SEMANTIC_COUNT" -gt 0 ] && TOTAL_PLATFORMS=$((TOTAL_PLATFORMS + 1))

# Build detected platforms list
DETECTED_PLATFORMS=""
[ "$WEBFLOW_COUNT" -gt 0 ] && DETECTED_PLATFORMS="${DETECTED_PLATFORMS}Webflow, "
[ "$FIGMA_COUNT" -gt 0 ] && DETECTED_PLATFORMS="${DETECTED_PLATFORMS}Figma, "
[ "$NOTION_COUNT" -gt 0 ] && DETECTED_PLATFORMS="${DETECTED_PLATFORMS}Notion, "
[ "$GITHUB_COUNT" -gt 0 ] && DETECTED_PLATFORMS="${DETECTED_PLATFORMS}GitHub, "
[ "$CLICKUP_COUNT" -gt 0 ] && DETECTED_PLATFORMS="${DETECTED_PLATFORMS}ClickUp, "
[ "$CHROME_COUNT" -gt 0 ] && DETECTED_PLATFORMS="${DETECTED_PLATFORMS}Chrome DevTools, "
[ "$SEMANTIC_COUNT" -gt 0 ] && DETECTED_PLATFORMS="${DETECTED_PLATFORMS}Semantic Search, "
DETECTED_PLATFORMS=$(echo "$DETECTED_PLATFORMS" | sed 's/, $//')

# ───────────────────────────────────────────────────────────────
# WORKFLOW PATTERN DETECTION (single pass)
# ───────────────────────────────────────────────────────────────

# Combined workflow patterns regex
WORKFLOW_REGEX="first.*then|then.*update|then.*create|after.*create|after.*update|next.*publish|and then|from.*to|into.*and|between.*and|integrate.*with|sync.*with|pipeline|workflow|automate|automation"

HAS_WORKFLOW=false
if echo "$PROMPT_LOWER" | grep -qE "$WORKFLOW_REGEX"; then
    HAS_WORKFLOW=true
fi

# CMS-specific patterns
CMS_REGEX="cms collection|publish site|update content|cms item|collection field"
HAS_CMS=false
if echo "$PROMPT_LOWER" | grep -qE "$CMS_REGEX"; then
    HAS_CMS=true
fi

# Design-specific patterns
DESIGN_REGEX="design file|get component|design system|design token|team component"
HAS_DESIGN=false
if echo "$PROMPT_LOWER" | grep -qE "$DESIGN_REGEX"; then
    HAS_DESIGN=true
fi

# ───────────────────────────────────────────────────────────────
# DECISION LOGIC
# ───────────────────────────────────────────────────────────────

SHOULD_SUGGEST=false
SUGGESTION_TYPE=""
DETECTED_CATEGORY=""

# Multi-platform workflow (highest priority)
if [ "$TOTAL_PLATFORMS" -ge 2 ]; then
    SHOULD_SUGGEST=true
    SUGGESTION_TYPE="multi_platform"
    DETECTED_CATEGORY="Multi-Platform Workflow"

# Sequential workflow with platform
elif [ "$HAS_WORKFLOW" = true ] && [ "$TOTAL_PLATFORMS" -ge 1 ]; then
    SHOULD_SUGGEST=true
    SUGGESTION_TYPE="sequential"
    DETECTED_CATEGORY="Sequential Multi-Step Operations"

# Single platform detected
elif [ "$TOTAL_PLATFORMS" -ge 1 ]; then
    SHOULD_SUGGEST=true

    if [ "$WEBFLOW_COUNT" -gt 0 ]; then
        if [ "$HAS_CMS" = true ]; then
            SUGGESTION_TYPE="webflow_cms"
            DETECTED_CATEGORY="CMS Operations (Webflow)"
        else
            SUGGESTION_TYPE="webflow"
            DETECTED_CATEGORY="Webflow Operations"
        fi
    elif [ "$FIGMA_COUNT" -gt 0 ]; then
        if [ "$HAS_DESIGN" = true ]; then
            SUGGESTION_TYPE="figma_design"
            DETECTED_CATEGORY="Design Tools (Figma)"
        else
            SUGGESTION_TYPE="figma"
            DETECTED_CATEGORY="Figma Operations"
        fi
    elif [ "$NOTION_COUNT" -gt 0 ]; then
        SUGGESTION_TYPE="notion"
        DETECTED_CATEGORY="Notion Operations"
    elif [ "$GITHUB_COUNT" -gt 0 ]; then
        SUGGESTION_TYPE="github"
        DETECTED_CATEGORY="GitHub Operations"
    elif [ "$CLICKUP_COUNT" -gt 0 ]; then
        SUGGESTION_TYPE="clickup"
        DETECTED_CATEGORY="ClickUp Operations"
    elif [ "$CHROME_COUNT" -gt 0 ]; then
        SUGGESTION_TYPE="chrome"
        DETECTED_CATEGORY="Browser Automation (Chrome DevTools)"
    elif [ "$SEMANTIC_COUNT" -gt 0 ]; then
        SUGGESTION_TYPE="semantic"
        DETECTED_CATEGORY="Semantic Code Search"
    fi
fi

# ───────────────────────────────────────────────────────────────
# OUTPUT UNIFIED SUGGESTION
# ───────────────────────────────────────────────────────────────

if [ "$SHOULD_SUGGEST" = true ]; then
    echo ""

    # Header based on type
    if [ "$SUGGESTION_TYPE" = "multi_platform" ] || [ "$SUGGESTION_TYPE" = "sequential" ]; then
        echo "MCP WORKFLOW DETECTED:"
    else
        echo "MCP TOOL USAGE DETECTED:"
    fi
    echo ""

    # Show detected platforms
    if [ -n "$DETECTED_PLATFORMS" ]; then
        echo "  Platforms: [$DETECTED_PLATFORMS]"
    fi
    echo "  Category: $DETECTED_CATEGORY"
    echo ""

    # Benefits section
    echo "  Code Mode Benefits:"
    echo "  - 68% fewer tokens consumed"
    echo "  - 98.7% reduction in context overhead"
    echo "  - 60% faster execution"
    if [ "$SUGGESTION_TYPE" = "multi_platform" ] || [ "$SUGGESTION_TYPE" = "sequential" ]; then
        echo "  - State persistence across ALL operations"
        echo "  - Single execution (no context switching)"
        echo "  - Automatic error handling and rollback"
    fi
    echo ""

    # Context-specific examples
    case "$SUGGESTION_TYPE" in
        "multi_platform")
            if [ "$FIGMA_COUNT" -gt 0 ] && [ "$WEBFLOW_COUNT" -gt 0 ]; then
                echo "  Example: Design-to-CMS Workflow"
                echo "  call_tool_chain({"
                echo "    code: \`"
                echo "      const design = await figma.figma_get_file({ fileId: '...' });"
                echo "      const item = await webflow.webflow_items_create_item({"
                echo "        collectionId: '...',"
                echo "        fields: { name: design.name }"
                echo "      });"
                echo "      return { design, item };"
                echo "    \`,"
                echo "    timeout: 60000"
                echo "  });"
            else
                echo "  Example: Multi-Platform Workflow"
                echo "  call_tool_chain({"
                echo "    code: \`"
                echo "      const data1 = await platform1.platform1_get_data({...});"
                echo "      const data2 = await platform2.platform2_create_item({"
                echo "        field: data1.value"
                echo "      });"
                echo "      return { data1, data2 };"
                echo "    \`,"
                echo "    timeout: 60000"
                echo "  });"
            fi
            ;;

        "webflow"|"webflow_cms")
            echo "  Example: Webflow CMS Operations"
            echo "  call_tool_chain({"
            echo "    code: \`"
            echo "      const sites = await webflow.webflow_sites_list({});"
            echo "      const collections = await webflow.webflow_collections_list({"
            echo "        site_id: sites.sites[0].id"
            echo "      });"
            echo "      return { sites, collections };"
            echo "    \`"
            echo "  });"
            ;;

        "figma"|"figma_design")
            echo "  Example: Figma Design Operations"
            echo "  call_tool_chain({"
            echo "    code: \`"
            echo "      const file = await figma.figma_get_file({ fileId: '...' });"
            echo "      return file;"
            echo "    \`"
            echo "  });"
            ;;

        "chrome")
            echo "  Example: Browser Automation"
            echo "  call_tool_chain({"
            echo "    code: \`"
            echo "      await chrome_devtools_1.chrome_devtools_navigate_page({ url: '...' });"
            echo "      const screenshot = await chrome_devtools_1.chrome_devtools_take_screenshot({});"
            echo "      return screenshot;"
            echo "    \`"
            echo "  });"
            ;;

        "notion")
            echo "  Example: Notion Operations"
            echo "  call_tool_chain({"
            echo "    code: \`"
            echo "      const page = await notion.notion_get_page({ page_id: '...' });"
            echo "      return page;"
            echo "    \`"
            echo "  });"
            ;;

        "clickup")
            echo "  Example: ClickUp Operations"
            echo "  call_tool_chain({"
            echo "    code: \`"
            echo "      const tasks = await clickup.clickup_get_tasks({ list_id: '...' });"
            echo "      return tasks;"
            echo "    \`"
            echo "  });"
            ;;

        "semantic")
            echo "  Example: Semantic Code Search"
            echo "  search_tools({ task_description: 'find authentication logic', limit: 10 });"
            echo ""
            echo "  call_tool_chain({"
            echo "    code: \`"
            echo "      const results = await semantic.semantic_search({ query: '...' });"
            echo "      return results;"
            echo "    \`"
            echo "  });"
            ;;

        "sequential")
            echo "  Example: Sequential Operations"
            echo "  call_tool_chain({"
            echo "    code: \`"
            echo "      const step1 = await platform.operation_1({...});"
            echo "      const step2 = await platform.operation_2({ ref: step1.id });"
            echo "      return { step1, step2 };"
            echo "    \`,"
            echo "    timeout: 60000"
            echo "  });"
            ;;
    esac

    echo ""
    echo "  Tool Naming: {manual_name}.{manual_name}_{tool_name}"
    echo ""
    echo "Reference: .claude/skills/mcp-code-mode/SKILL.md"
    echo ""
    echo "IMPORTANT: ALL MCP tools MUST be called via Code Mode"
    echo ""
fi

# ───────────────────────────────────────────────────────────────
# PERFORMANCE LOGGING
# ───────────────────────────────────────────────────────────────

END_TIME=$(_get_nano_time)
DURATION=$(( (END_TIME - START_TIME) / 1000000 ))

LOG_ENTRY="[$(date '+%Y-%m-%d %H:%M:%S')] suggest-mcp-tools.sh ${DURATION}ms"
if [ "$SHOULD_SUGGEST" = true ]; then
    LOG_ENTRY="$LOG_ENTRY - Detected: $DETECTED_CATEGORY (Platforms: $TOTAL_PLATFORMS)"
else
    LOG_ENTRY="$LOG_ENTRY - No MCP patterns detected"
fi
echo "$LOG_ENTRY" >> "$HOOKS_DIR/logs/performance.log" 2>/dev/null

# Always allow the prompt to proceed
exit 0
