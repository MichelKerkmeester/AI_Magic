#!/bin/bash

# ───────────────────────────────────────────────────────────────
# SKILL SCAFFOLDING AUTOMATION HOOK
# ───────────────────────────────────────────────────────────────
# Post-ToolUse hook that auto-scaffolds skill directory structure
# when SKILL.md is created in .claude/skills/*/
#
# Triggers:
# - Tool: Write or Edit
# - Path: .claude/skills/*/SKILL.md
# - Condition: File is newly created (not edited)
#
# Actions:
# - Creates references/ directory
# - Creates assets/ directory
# - Creates scripts/ directory (optional)
# - Adds placeholder README files with guidance
# - Displays helpful next steps to user
#
# PERFORMANCE TARGET: <200ms (directory creation, file operations)
# COMPATIBILITY: Bash 3.2+ (macOS and Linux compatible)
#
# EXECUTION ORDER: PostToolUse hook (runs AFTER tool completion)
#   1. UserPromptSubmit hooks run FIRST (before processing user input)
#   2. PreToolUse hooks run SECOND (before tool execution, validation)
#   3. PostToolUse hooks run LAST (after tool completion, verification)
#   This hook: Auto-scaffolds skill directory structure when SKILL.md created
#
# EXIT CODE CONVENTION:
#   0 = Allow (hook passed, continue execution)
#   1 = Block (hook failed, stop execution with warning)
#   2 = Error (reserved for critical failures)
# ───────────────────────────────────────────────────────────────

# Source output helpers
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" 2>/dev/null && pwd)"
HOOKS_DIR="$(cd "$SCRIPT_DIR/.." 2>/dev/null && pwd)"
source "$HOOKS_DIR/lib/output-helpers.sh" || exit 0

# Logging configuration
LOG_DIR="$HOOKS_DIR/logs"
LOG_FILE="$LOG_DIR/$(basename "$0" .sh).log"

# Read JSON input from stdin
INPUT=$(cat)

# Extract tool use information (support multiple payload shapes)
TOOL_NAME=$(echo "$INPUT" | jq -r '.tool_name // .toolName // .tool // .name // empty' 2>/dev/null)
FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.filePath // .tool_input.file_path // .tool_input.path // .tool_input.notebook_path // .parameters.file_path // .parameters.filePath // .parameters.path // .parameters.notebook_path // empty' 2>/dev/null)

# Exit early if not relevant
if [[ -z "$TOOL_NAME" || -z "$FILE_PATH" ]]; then
  exit 0
fi

# Only trigger on Write tool (file creation)
if [[ "$TOOL_NAME" != "Write" ]]; then
  exit 0
fi

# Check if file is SKILL.md in a skill directory
if [[ ! "$FILE_PATH" =~ \.claude/skills/[^/]+/SKILL\.md$ ]]; then
  exit 0
fi

# Extract skill directory and name
SKILL_DIR=$(dirname "$FILE_PATH")
SKILL_NAME=$(basename "$SKILL_DIR")

# Get project root
PROJECT_ROOT=$(git rev-parse --show-toplevel 2>/dev/null || (cd "$SCRIPT_DIR/../.." && pwd))

# Full path to skill directory (handle absolute and relative paths)
if [[ "$SKILL_DIR" = /* ]]; then
  FULL_SKILL_DIR="$SKILL_DIR"
else
  FULL_SKILL_DIR="$PROJECT_ROOT/$SKILL_DIR"
fi

# ───────────────────────────────────────────────────────────────
# DIRECTORY SCAFFOLDING
# ───────────────────────────────────────────────────────────────

# Track what was created
CREATED_ITEMS=()

# Create references directory
if [[ ! -d "$FULL_SKILL_DIR/references" ]]; then
  mkdir -p "$FULL_SKILL_DIR/references" 2>/dev/null
  if [[ $? -eq 0 ]]; then
    CREATED_ITEMS+=("references/")

    # Create placeholder README
    cat > "$FULL_SKILL_DIR/references/README.md" 2>/dev/null <<'EOF'
# References Directory

This directory contains detailed reference documentation that supports the main SKILL.md file.

## Purpose

References provide in-depth information that would make SKILL.md too long if included directly. They enable **progressive disclosure** - users can dig deeper when needed without cluttering the main skill file.

## Common Reference Files

- **core_standards.md**: Fundamental standards, rules, and conventions
- **workflows.md**: Detailed step-by-step workflow documentation
- **optimization.md**: Performance and quality optimization guides
- **validation.md**: Validation rules and quality criteria
- **quick_reference.md**: One-page cheat sheet for common tasks

## Guidelines

- Keep each reference focused on a single topic
- Use clear, descriptive filenames with underscores
- Cross-reference from SKILL.md where relevant
- Use examples liberally

## Template

See `.claude/skills/create-documentation/references/` for examples of well-structured reference files.
EOF
  fi
fi

# Create assets directory
if [[ ! -d "$FULL_SKILL_DIR/assets" ]]; then
  mkdir -p "$FULL_SKILL_DIR/assets" 2>/dev/null
  if [[ $? -eq 0 ]]; then
    CREATED_ITEMS+=("assets/")

    # Create placeholder README
    cat > "$FULL_SKILL_DIR/assets/README.md" 2>/dev/null <<'EOF'
# Assets Directory

This directory contains reference data, templates, examples, and lookup tables that support the skill's functionality.

## Purpose

Assets provide copy-paste templates, code examples, and reference data that users can apply directly without needing to construct from scratch.

## Common Asset Types

### 📝 Templates (`*_templates.md`)
- Copy-paste starting points for common tasks
- Configuration files, code snippets, document structures
- Include field descriptions and complete examples

### 📊 References (`*_reference.md`)
- Lookup tables, decision matrices, classification systems
- Quick reference data (emoji mappings, naming conventions)
- Standards and specifications

### 💡 Examples (`*_examples.md`)
- Working examples of skill outputs
- Before/after comparisons
- Common patterns and anti-patterns

### 🎓 Guides (`*_guide.md`)
- Step-by-step guides for complex processes
- Troubleshooting documentation
- Integration instructions

## Naming Conventions

- Format: `[topic]_[type].md`
- Use underscores (not hyphens)
- Lowercase only
- Examples: `frontmatter_templates.md`, `validation_reference.md`

## Template

See `.claude/skills/create-documentation/assets/skill_asset_template.md` for comprehensive guidance on creating asset files.
EOF
  fi
fi

# Create scripts directory (only if skill will need automation)
# Note: Not created by default - user can add manually if needed
# if [[ ! -d "$FULL_SKILL_DIR/scripts" ]]; then
#   mkdir -p "$FULL_SKILL_DIR/scripts" 2>/dev/null
#   CREATED_ITEMS+=("scripts/")
# fi

# ───────────────────────────────────────────────────────────────
# USER FEEDBACK
# ───────────────────────────────────────────────────────────────

# Only show message if we created something
if [[ ${#CREATED_ITEMS[@]} -gt 0 ]]; then

  cat >&2 << EOF

───────────────────────────────────────────────────────────────
✅ SKILL STRUCTURE SCAFFOLDED
───────────────────────────────────────────────────────────────
   Auto-created directories for: $SKILL_NAME

EOF

  # List created items
  for item in "${CREATED_ITEMS[@]}"; do
    echo "   📁 Created: $SKILL_DIR/$item" >&2
  done

  cat >&2 << EOF

───────────────────────────────────────────────────────────────
📝 NEXT STEPS
───────────────────────────────────────────────────────────────
   1. Complete SKILL.md frontmatter (name, description, allowed-tools)
   2. Add reference files to references/ as needed
   3. Add templates/examples to assets/ if applicable
   4. Consider creating executable wrapper for CLI access

   💡 Tip: See .claude/skills/create-documentation/ for
      a complete example of a well-structured skill

───────────────────────────────────────────────────────────────

EOF

  # Emit systemMessage for Claude Code visibility
  created_list=$(IFS=', '; echo "${CREATED_ITEMS[*]}")
  visible_msg=$(jq -n --arg msg "✅ SKILL SCAFFOLDED: Created $created_list for $SKILL_NAME. Complete SKILL.md frontmatter next." '{systemMessage: $msg}')
  echo "$visible_msg"

fi

exit 0
