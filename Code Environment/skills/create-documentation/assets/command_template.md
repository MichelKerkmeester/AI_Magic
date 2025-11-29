# Command Template - Claude Code Slash Commands

Templates and best practices for creating production-quality slash commands in Claude Code.

> **⚠️ CRITICAL: Commands NEVER use emojis.** No emoji on H1, H2, H3, H4, or in body text. Plain section headers only (e.g., `## Purpose`, not `## 🎯 Purpose`). See Section 8 Validation Checklist for details.

---

## 1. 📋 QUICK REFERENCE

### Frontmatter Requirements

| Field | Required | Purpose | Format |
|-------|----------|---------|--------|
| `description` | ✅ Yes | Human-readable purpose | One sentence, action-verb start |
| `argument-hint` | ⚠️ Recommended | Show expected arguments | `<required> [optional] [--flag]` |
| `allowed-tools` | ⚠️ Recommended | Tools command can use | Comma-separated list |
| `name` | ❌ No | Override command name | kebab-case (inferred from filename) |
| `model` | ❌ No | Override default model (use sparingly) | `opus` for complex reasoning only |

> **Note on `model` field**: Only use for commands requiring complex reasoning (e.g., `plan/with_claude` uses `opus` for parallel exploration). Most commands should NOT specify a model and use the default.

### Command Types

| Type | Complexity | Template |
|------|------------|----------|
| **Simple** | Single action, few args | Section 2 |
| **Workflow** | Multi-step process | Section 3 |
| **Mode-Based** | `:auto`/`:confirm` variants | Section 4 |
| **Destructive** | Requires confirmation | Section 5 |
| **Namespace** | Grouped commands (`/group:action`) | Section 6 |

---

## 2. 📄 SIMPLE COMMAND TEMPLATE

Use for: Single-action commands with straightforward execution.

```markdown
---
description: [Action verb] [what it does] [context/scope]
argument-hint: "<required-arg> [optional-arg]"
allowed-tools: Tool1, Tool2
---

# [Command Title]

[One sentence describing what this command does and when to use it.]

---

## Purpose

[2-3 sentences explaining the command's purpose and primary use case.]

---

## Contract

**Inputs:** `$ARGUMENTS` — [Description of expected arguments]
**Outputs:** `STATUS=<OK|FAIL> [ADDITIONAL_DATA=<value>]`

---

## Instructions

Execute the following steps:

1. **[Step name]:**
   - [Sub-step or detail]
   - [Sub-step or detail]

2. **[Step name]:**
   - [Sub-step or detail]

3. **Return status:**
   - If successful: `STATUS=OK [DATA=<value>]`
   - If failed: `STATUS=FAIL ERROR="<message>"`

---

## Example Usage

### Basic Usage
\`\`\`bash
/command-name "argument"
\`\`\`

### With Optional Args
\`\`\`bash
/command-name "argument" --flag
\`\`\`

---

## Example Output

\`\`\`
[Formatted output example]

STATUS=OK DATA=<value>
\`\`\`

---

## Notes

- **[Category]:** [Important note about usage]
- **[Category]:** [Performance or limitation note]
- **Requirements:** [Prerequisites or dependencies]
```

### Simple Command Example

```yaml
---
description: Search codebase semantically using natural language queries
argument-hint: "<query> [--refined]"
allowed-tools: mcp__semantic-search__semantic_search
---
```

---

## 3. 📊 WORKFLOW COMMAND TEMPLATE

Use for: Multi-step processes with defined phases and outputs.

```markdown
---
description: [Workflow name] ([N] steps) - [brief purpose]
argument-hint: "[topic] [context]"
allowed-tools: Read, Write, Edit, Bash, Task, AskUserQuestion
---

# [Workflow Title]

**Purpose**: [One sentence describing the workflow's goal and primary output.]

## User Input

\`\`\`text
$ARGUMENTS
\`\`\`

## Workflow Overview ([N] Steps)

| Step | Name | Purpose | Outputs |
|------|------|---------|---------|
| 1 | [Step Name] | [What it does] | [Artifacts created] |
| 2 | [Step Name] | [What it does] | [Artifacts created] |
| 3 | [Step Name] | [What it does] | [Artifacts created] |
| N | Save Context | Preserve conversation | memory/*.md |

## Instructions

### Step 1: [Step Name]

[Detailed instructions for this step]

**Validation checkpoint:**
- [ ] [Condition that must be true]
- [ ] [Another condition]

### Step 2: [Step Name]

[Detailed instructions for this step]

---

## Failure Recovery

| Failure Type | Recovery Action |
|--------------|-----------------|
| [Failure condition] | [How to recover] |
| [Another condition] | [Recovery steps] |

---

## Error Handling

| Condition | Action |
|-----------|--------|
| Empty `$ARGUMENTS` | Prompt user: "Please describe..." |
| [Other condition] | [Action to take] |

---

## Templates Used

- `.claude/commands/spec_kit/assets/templates/[template].md`
- [Other template references]

---

## Completion Report

After workflow completion, report:

\`\`\`
✅ [Workflow Name] Complete

[Summary of what was accomplished]

Artifacts Created:
- [artifact 1]
- [artifact 2]

Next Steps:
- [Recommended follow-up action]
\`\`\`

---

## Examples

**Example 1: [Use case]**
\`\`\`
/workflow-name [arguments]
\`\`\`

**Example 2: [Another use case]**
\`\`\`
/workflow-name [different arguments]
\`\`\`
```

---

## 4. 🔀 MODE-BASED COMMAND TEMPLATE

Use for: Commands supporting `:auto` and `:confirm` execution modes.

```markdown
---
description: [Workflow name] ([N] steps) - [purpose]. Supports :auto and :confirm modes
---

## Smart Command: /[command-name]

**Purpose**: [Description of what this command accomplishes.]

## User Input

\`\`\`text
$ARGUMENTS
\`\`\`

## Mode Detection & Routing

### Step 1: Parse Mode Suffix

Detect execution mode from command invocation:

| Pattern | Mode | Behavior |
|---------|------|----------|
| `/command:auto` | AUTONOMOUS | Execute all steps without user approval gates |
| `/command:confirm` | INTERACTIVE | Pause at each step for user approval |
| `/command` (no suffix) | PROMPT | Ask user to choose mode |

### Step 2: Mode Selection (when no suffix detected)

If no `:auto` or `:confirm` suffix is present, use AskUserQuestion:

**Question**: "How would you like to execute this workflow?"

| Option | Mode | Description |
|--------|------|-------------|
| **A** | Autonomous | Execute all steps without approval gates. Best for [use case]. |
| **B** | Interactive | Pause at each step for approval. Best for [use case]. |

**Wait for user response before proceeding.**

### Step 3: Transform Raw Input

Parse the raw text from `$ARGUMENTS` and transform into structured fields.

**Field Extraction Rules**:

| Field | Pattern Detection | Default If Empty |
|-------|-------------------|------------------|
| `[field_name]` | "[pattern]", "[pattern]" | [Default value] |
| `request` | Primary description (REQUIRED) | ERROR if empty |

---

## Key Behaviors

### Autonomous Mode (`:auto`)
- Executes all steps without user approval gates
- Self-validates at each checkpoint
- Makes informed decisions based on best judgment
- Documents all significant decisions

### Interactive Mode (`:confirm`)
- Pauses after each step for user approval
- Presents options: Approve, Review Details, Modify, Skip, Abort
- Documents user decisions at each checkpoint
- Allows course correction throughout workflow

---

## Context Loading

When resuming work in an existing spec folder, prompt to load prior session memory:
- **A)** Load most recent memory file (quick context refresh)
- **B)** Load all recent files (up to 3) (comprehensive context)
- **C)** List all files and select specific (historical search)
- **D)** Skip (start fresh, no context)

---

## Examples

**Example 1: Autonomous execution**
\`\`\`
/command:auto [arguments]
\`\`\`

**Example 2: Interactive execution**
\`\`\`
/command:confirm [arguments]
\`\`\`

**Example 3: Prompt for mode selection**
\`\`\`
/command [arguments]
\`\`\`
```

---

## 5. ⚠️ DESTRUCTIVE COMMAND TEMPLATE

Use for: Commands that delete data or make irreversible changes.

```markdown
---
description: [Action] (DESTRUCTIVE)
argument-hint: "[--confirm]"
allowed-tools: Bash, AskUserQuestion
---

# [Command Title]

⚠️ **DESTRUCTIVE OPERATION** - [Brief warning about what will be affected.]

---

## Purpose

[Explain the destructive action and why it might be needed.]

---

## Contract

**Inputs:** `$ARGUMENTS` — Must include `--confirm` flag to skip prompt
**Outputs:** `STATUS=<OK|FAIL|CANCELLED> ACTION=<action|cancelled>`

---

## Instructions

Execute the following steps:

1. **Safety check - Require confirmation:**
   - Check if `--confirm` flag is present in `$ARGUMENTS`
   - If NOT present:
     - Use AskUserQuestion: "⚠️ [Warning message]. Are you sure?"
     - Options: "Yes, proceed" / "No, cancel"
     - If user cancels: `STATUS=CANCELLED ACTION=cancelled`

2. **Show what will be affected:**
   - Display current state
   - List items that will be deleted/changed
   - Show size/count of affected data

3. **Execute destructive action:**
   - [Step-by-step execution]
   - Log each action taken

4. **Verify completion:**
   - Confirm action completed
   - Show new state

5. **Provide recovery guidance:**
   - Explain how to rebuild/restore if needed
   - Link to relevant commands

6. **Return status:**
   - If completed: `STATUS=OK ACTION=[action]`
   - If cancelled: `STATUS=CANCELLED ACTION=cancelled`
   - If failed: `STATUS=FAIL ERROR="<message>"`

---

## Example Usage

### Without Confirmation (Safe Default)
\`\`\`bash
/command-name
\`\`\`
→ Will prompt for confirmation before proceeding

### With Confirmation Flag (Skip Prompt)
\`\`\`bash
/command-name --confirm
\`\`\`
→ Proceeds immediately (use with caution)

---

## Notes

- **When to Use:**
  - [Valid use case 1]
  - [Valid use case 2]

- **Impact:**
  - ❌ [What will be lost]
  - ❌ [Other consequences]
  - ✅ [What is preserved]
  - ✅ [Recovery options]

- **Alternatives to Consider:**
  - [Less destructive alternative]
  - [Another option]

---

## Safety Features

- Requires explicit confirmation by default
- Shows what will be affected before proceeding
- Provides clear recovery steps
- Cannot accidentally affect [protected items]
```

---

## 6. 📁 NAMESPACE COMMAND PATTERN

Use for: Grouping related commands under a common prefix.

### Directory Structure

```
.claude/commands/
└── [namespace]/           # Directory name = namespace
    ├── [action1].md       # → /namespace:action1
    ├── [action2].md       # → /namespace:action2
    └── [action3].md       # → /namespace:action3
```

### Example: Index Namespace

```
.claude/commands/
└── index/
    ├── start.md     → /index:start
    ├── stop.md      → /index:stop
    ├── search.md    → /index:search
    ├── stats.md     → /index:stats
    ├── history.md   → /index:history
    └── reset.md     → /index:reset
```

### Naming Conventions

| Element | Convention | Example |
|---------|------------|---------|
| Namespace directory | lowercase, hyphen-case | `index/`, `git-workflow/` |
| Action files | lowercase, hyphen-case | `search.md`, `full-reset.md` |
| Resulting command | namespace:action | `/index:search` |

---

## 7. 📝 FRONTMATTER FIELD REFERENCE

### Required Fields

```yaml
---
description: |
  Clear, action-oriented description.
  Start with action verb (Create, Search, Delete, Start, Stop).
  One to two sentences maximum.
  Shown in /help output.
---
```

### Recommended Fields

```yaml
---
argument-hint: "<required> [optional] [--flag]"
# Format conventions:
#   <angle-brackets> = required argument
#   [square-brackets] = optional argument
#   --flag = boolean flag
#   [default: value] = argument with default
# Examples:
#   "<query>"
#   "<query> [--refined]"
#   "[spec-folder] [:auto|:confirm]"
#   "[--confirm]"

allowed-tools: Tool1, Tool2, Tool3
# Common tools:
#   Read, Write, Edit - File operations
#   Bash - Shell commands
#   Grep, Glob - Search operations
#   Task - Sub-agent dispatch
#   AskUserQuestion - User interaction
#
# Tool filtering syntax:
#   Bash(git:*) - Allow only git commands
#   Bash(codesql:*) - Allow only codesql commands
#   Bash(npm:*) - Allow only npm commands
#
# MCP tool naming convention:
#   mcp__[server-name]__[tool_function]
#   Example: mcp__semantic-search__semantic_search
#   Example: mcp__chrome-devtools__take_snapshot
---
```

### Optional Fields

```yaml
---
name: command-name
# Override inferred name from filename
# Usually not needed

model: opus
# Override default model (USE SPARINGLY)
# Only for commands requiring complex reasoning
# Example: plan/with_claude uses opus for parallel exploration
# Most commands should NOT specify model

version: 1.0.0
# Track command version
# Useful for deprecation management

disable-model-invocation: true
# Prevent Claude from invoking this command
# Use for user-only commands
---
```

---

## 8. ✅ VALIDATION CHECKLIST

Before publishing a command, verify:

### Frontmatter
- [ ] `description` is present and action-oriented
- [ ] `argument-hint` shows expected format (if args expected)
- [ ] `allowed-tools` lists all tools used (if any)
- [ ] No angle brackets `< >` in description (reserved for hints)

### Structure
- [ ] H1 title matches command purpose (no subtitle)
- [ ] Purpose section explains "why"
- [ ] Contract section defines inputs/outputs
- [ ] Instructions are numbered and actionable
- [ ] Example usage shows 2-3 scenarios
- [ ] Example output shows expected format

### Emoji Policy (CRITICAL)
- [ ] **NO emoji on H1** (title)
- [ ] **NO emoji on H2** (section headers)
- [ ] **NO emoji on H3/H4** (subsections)
- [ ] **NO emoji in body text** (unless displaying user data)
- [ ] **NO numbered H2 sections** (use plain `## Section Name`)

> **Rationale**: Commands are machine-invoked operational documents. Plain text headers improve parsing reliability and maintain professional clarity. Emojis are reserved for human-facing documentation (SKILL, Knowledge, README).

### Content Quality
- [ ] Status output follows standard format (see patterns below)
- [ ] Error cases are handled
- [ ] Empty arguments have sensible default or error
- [ ] Destructive operations require confirmation

### Status Output Patterns

Use the appropriate pattern based on command type:

| Pattern | Use Case | Example |
|---------|----------|---------|
| `STATUS=OK` | Simple success | Basic commands |
| `STATUS=OK RESULTS_COUNT=N` | Search/query | `/index:search` |
| `STATUS=OK ACTION=<action>` | State change | `/index:start`, `/index:stop` |
| `STATUS=OK ACTION=<action> PATH=<path>` | File creation | `/plan:with_claude`, `/spec_kit:complete` |
| `STATUS=FAIL ERROR="<message>"` | All failures | Error handling |
| `STATUS=CANCELLED ACTION=cancelled` | User abort | Interactive commands |

### Integration
- [ ] Filename uses snake_case or kebab-case
- [ ] Namespace directory exists (for namespaced commands)
- [ ] Referenced tools are available
- [ ] Referenced templates exist

---

## 9. 🧠 ORCHESTRATOR + WORKERS PATTERN

Use for: Commands that spawn parallel sub-agents for exploration/analysis, with a primary model for synthesis and verification.

### Pattern Overview

```
┌─────────────────────────────────────────────────────────────┐
│  OPUS ORCHESTRATOR                                          │
│  - Understands task                                         │
│  - Dispatches Sonnet workers                                │
│  - Verifies hypotheses                                      │
│  - Synthesizes findings                                     │
│  - Creates final output                                     │
└─────────────────────────────────────────────────────────────┘
              │
              ├──────────────────┬──────────────────┬──────────────────┐
              ▼                  ▼                  ▼                  ▼
┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐
│ SONNET WORKER 1 │  │ SONNET WORKER 2 │  │ SONNET WORKER 3 │  │ SONNET WORKER N │
│ Fast exploration│  │ Fast exploration│  │ Fast exploration│  │ Fast exploration│
│ File discovery  │  │ Pattern finding │  │ Dependency map  │  │ Test analysis   │
└─────────────────┘  └─────────────────┘  └─────────────────┘  └─────────────────┘
```

### Implementation

**1. Command Frontmatter**

```yaml
---
description: [Command purpose]
model: opus  # Orchestrator uses Opus for complex reasoning
argument-hint: "<task description>"
allowed-tools: Read, Write, Edit, Glob, Grep, Task, AskUserQuestion
---
```

**2. Worker Dispatch (Task tool calls)**

```typescript
// All workers MUST specify model: "sonnet"
{
  "subagent_type": "Explore",
  "model": "sonnet",  // REQUIRED
  "description": "Worker description",
  "prompt": "..."
}
```

**3. Model Hierarchy Table**

Include this table in the command's Notes section:

| Role | Model | Responsibility |
|------|-------|----------------|
| **Orchestrator** | `opus` | Task understanding, dispatch, verification, synthesis, final output |
| **Workers** | `sonnet` | Fast parallel exploration, discovery, hypothesis generation |

### When to Use This Pattern

| Scenario | Use Orchestrator Pattern? |
|----------|--------------------------|
| Parallel codebase exploration | ✅ Yes |
| Multi-aspect analysis | ✅ Yes |
| Complex planning with verification | ✅ Yes |
| Simple single-action command | ❌ No |
| Sequential workflow | ❌ No |

### Example: plan/with_claude Command

```markdown
### Phase 2: Parallel Exploration (Sonnet Agents)

| Agent | Focus | Model |
|-------|-------|-------|
| Architecture Explorer | Project structure | sonnet |
| Feature Explorer | Similar patterns | sonnet |
| Dependency Explorer | Import mapping | sonnet |
| Test Explorer | Test infrastructure | sonnet |

### Phase 3: Hypothesis Verification (Opus Review)

Opus synthesizes and validates:
- Cross-reference findings across agents
- Verify or refute each hypothesis
- Resolve conflicting findings
- Build complete mental model
```

### Benefits

- **Quality**: Opus provides deep reasoning for verification and synthesis
- **Speed**: Sonnet workers explore in parallel (4x faster than sequential)
- **Cost-effective**: Sonnet exploration is cheaper than Opus for discovery tasks
- **Accuracy**: Cross-referencing multiple workers reduces blind spots

---

## 10. 🔗 RELATED RESOURCES

### Templates
- [frontmatter_templates.md](./frontmatter_templates.md) - Frontmatter by document type
- [skill_md_template.md](./skill_md_template.md) - If converting to skill

### Standards
- [core_standards.md](../references/core_standards.md) - Document type rules
- [validation.md](../references/validation.md) - Quality scoring

### Examples
- `.claude/commands/index/search.md` - Simple command with flags
- `.claude/commands/index/reset.md` - Destructive operation pattern
- `.claude/commands/speckit_complete.md` - Mode-based workflow
- `.claude/commands/save_context.md` - Context-aware targeting
- `.claude/commands/plan/with_claude.md` - File path (command: `/plan:with_claude`) - Orchestrator + Workers pattern (Opus + Sonnet)