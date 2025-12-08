# Command Template - Claude Code Slash Commands

Templates and best practices for creating production-quality slash commands in Claude Code.

> **STYLE STANDARD:** Commands use numbered ALL-CAPS section headers with emoji prefix. Format: `## N. [EMOJI] SECTION-NAME`. See Section 8 Validation Checklist for details.

---

## 1. 📋 QUICK REFERENCE

### Frontmatter Requirements

| Field | Required | Purpose | Format |
|-------|----------|---------|--------|
| `description` | Yes | Human-readable purpose | One sentence, action-verb start |
| `argument-hint` | Recommended | Show expected arguments | `<required> [optional] [--flag]` |
| `allowed-tools` | Recommended | Tools command can use | Comma-separated list |
| `name` | No | Override command name | kebab-case (inferred from filename) |
| `model` | No | Override default model (use sparingly) | `opus` for complex reasoning only |

> **Note on `model` field**: Only use for commands requiring complex reasoning (e.g., `plan/with_claude` uses `opus` for parallel exploration). Most commands should NOT specify a model and use the default.

### Command Types

| Type | Complexity | Template |
|------|------------|----------|
| **Simple** | Single action, few args | Section 3 |
| **Workflow** | Multi-step process | Section 4 |
| **Mode-Based** | `:auto`/`:confirm` variants | Section 5 |
| **Argument Dispatch** | Multiple entry points/actions | Section 6 |
| **Destructive** | Requires confirmation | Section 7 |
| **Namespace** | Grouped commands (`/group:action`) | Section 8 |

---

## 2. 🚨 MANDATORY GATE PATTERN (CRITICAL)

**For commands with REQUIRED arguments**, add a mandatory gate immediately after frontmatter to prevent context inference.

### Why This Pattern Exists

Without this gate, AI agents may:
- Infer tasks from conversation history or open files
- Assume what the user wants based on screenshots or context
- Proceed with incorrect assumptions instead of asking

### The Pattern

Add this block **immediately after frontmatter, before any other content**:

```markdown
# 🚨 MANDATORY FIRST ACTION - DO NOT SKIP

**BEFORE READING ANYTHING ELSE IN THIS FILE, CHECK `$ARGUMENTS`:**

\`\`\`
IF $ARGUMENTS is empty, undefined, or contains only whitespace (ignoring mode flags):
    → STOP IMMEDIATELY
    → Use AskUserQuestion tool with this exact question:
        question: "[Context-appropriate question]"
        options:
          - label: "[Action label]"
            description: "[What user will provide]"
    → WAIT for user response
    → Use their response as the [input type]
    → Only THEN continue with this workflow

IF $ARGUMENTS contains [expected input]:
    → Continue reading this file
\`\`\`

**CRITICAL RULES:**
- **DO NOT** infer [input type] from context, screenshots, or existing files
- **DO NOT** assume what the user wants based on conversation history
- **DO NOT** proceed past this point without an explicit [input] from the user
- The [input] MUST come from `$ARGUMENTS` or user's answer to the question above
```

### When to Use

| Argument Type | Use Mandatory Gate? | Example |
|---------------|---------------------|---------|
| `<required>` (angle brackets) | **YES** | `<task>`, `<query>`, `<spec-folder>` |
| `[optional]` (square brackets) | No (has default) | `[count]`, `[--flag]` |
| `[:auto\|:confirm]` mode flags | No (mode selection) | Mode suffixes only |

### Example Questions by Command Type

| Command Purpose | Question |
|-----------------|----------|
| Planning | "What would you like to plan?" |
| Research | "What topic would you like to research?" |
| Implementation | "Which spec folder would you like to implement?" |
| File improvement | "What would you like to improve and which files?" |
| Prompt enhancement | "What prompt would you like to improve?" |
| Generic routing | "What request would you like to route?" |

---

## 3. 📄 SIMPLE COMMAND TEMPLATE

Use for: Single-action commands with straightforward execution.

```markdown
---
description: [Action verb] [what it does] [context/scope]
argument-hint: "<required-arg> [optional-arg]"
allowed-tools: Tool1, Tool2
---

# 🚨 MANDATORY FIRST ACTION - DO NOT SKIP

**BEFORE READING ANYTHING ELSE IN THIS FILE, CHECK `$ARGUMENTS`:**

\`\`\`
IF $ARGUMENTS is empty, undefined, or contains only whitespace:
    → STOP IMMEDIATELY
    → Use AskUserQuestion tool
    → WAIT for user response
    → Only THEN continue

IF $ARGUMENTS contains required input:
    → Continue reading this file
\`\`\`

**CRITICAL RULES:**
- **DO NOT** infer from context, screenshots, or conversation history
- **DO NOT** assume what the user wants
- **DO NOT** proceed without explicit input from the user

---

# [Command Title]

[One sentence describing what this command does and when to use it.]

---

## 1. 📋 PURPOSE

[2-3 sentences explaining the command's purpose and primary use case.]

---

## 2. 📝 CONTRACT

**Inputs:** `$ARGUMENTS` — [Description of expected arguments]
**Outputs:** `STATUS=<OK|FAIL> [ADDITIONAL_DATA=<value>]`

---

## 3. ⚡ INSTRUCTIONS

Execute the following steps:

### Step 1: [Step Name]

- [Sub-step or detail]
- [Sub-step or detail]

### Step 2: [Step Name]

- [Sub-step or detail]

### Step 3: Return Status

- If successful: `STATUS=OK [DATA=<value>]`
- If failed: `STATUS=FAIL ERROR="<message>"`

---

## 4. 🔍 EXAMPLE USAGE

### Basic Usage

\`\`\`bash
/command-name "argument"
\`\`\`

### With Optional Args

\`\`\`bash
/command-name "argument" --flag
\`\`\`

---

## 5. 📊 EXAMPLE OUTPUT

\`\`\`
[Formatted output example]

STATUS=OK DATA=<value>
\`\`\`

---

## 6. 📌 NOTES

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

## 4. 📊 WORKFLOW COMMAND TEMPLATE

Use for: Multi-step processes with defined phases and outputs.

```markdown
---
description: [Workflow name] ([N] steps) - [brief purpose]
argument-hint: "<topic> [context]"
allowed-tools: Read, Write, Edit, Bash, Task, AskUserQuestion
---

# 🚨 MANDATORY FIRST ACTION - DO NOT SKIP

[Include mandatory gate pattern from Section 2]

---

# [Workflow Title]

**Purpose**: [One sentence describing the workflow's goal and primary output.]

---

## 1. 📋 USER INPUT

\`\`\`text
$ARGUMENTS
\`\`\`

---

## 2. 🔍 WORKFLOW OVERVIEW ([N] STEPS)

| Step | Name | Purpose | Outputs |
|------|------|---------|---------|
| 1 | [Step Name] | [What it does] | [Artifacts created] |
| 2 | [Step Name] | [What it does] | [Artifacts created] |
| 3 | [Step Name] | [What it does] | [Artifacts created] |
| N | Save Context | Preserve conversation | memory/*.md |

---

## 3. ⚡ INSTRUCTIONS

### Step 1: [Step Name]

[Detailed instructions for this step]

**Validation checkpoint:**
- [ ] [Condition that must be true]
- [ ] [Another condition]

### Step 2: [Step Name]

[Detailed instructions for this step]

---

## 4. 🔧 FAILURE RECOVERY

| Failure Type | Recovery Action |
|--------------|-----------------|
| [Failure condition] | [How to recover] |
| [Another condition] | [Recovery steps] |

---

## 5. ⚠️ ERROR HANDLING

| Condition | Action |
|-----------|--------|
| Empty `$ARGUMENTS` | Prompt user: "Please describe..." |
| [Other condition] | [Action to take] |

---

## 6. 📁 TEMPLATES USED

- `.opencode/speckit/templates/[template].md`
- [Other template references]

---

## 7. 📊 COMPLETION REPORT

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

## 8. 🎯 EXAMPLES

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

## 5. 🔀 MODE-BASED COMMAND TEMPLATE

Use for: Commands supporting `:auto` and `:confirm` execution modes.

```markdown
---
description: [Workflow name] ([N] steps) - [purpose]. Supports :auto and :confirm modes
argument-hint: "<request> [:auto|:confirm]"
allowed-tools: Read, Write, Edit, Bash, Task, AskUserQuestion
---

# 🚨 MANDATORY FIRST ACTION - DO NOT SKIP

[Include mandatory gate pattern from Section 2]

---

# [Command Title]

**Purpose**: [Description of what this command accomplishes.]

---

## 1. 📋 USER INPUT

\`\`\`text
$ARGUMENTS
\`\`\`

---

## 2. 🔍 MODE DETECTION & ROUTING

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

---

## 3. ⚡ KEY BEHAVIORS

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

## 4. 📁 CONTEXT LOADING

When resuming work in an existing spec folder, prompt to load prior session memory:
- **A)** Load most recent memory file (quick context refresh)
- **B)** Load all recent files (up to 3) (comprehensive context)
- **C)** List all files and select specific (historical search)
- **D)** Skip (start fresh, no context)

---

## 5. 🎯 EXAMPLES

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

## 6. 🧭 ARGUMENT DISPATCH PATTERN

Use for: Commands that accept multiple argument types and need to route to different actions.

### Pattern Overview

When a single command handles multiple argument patterns (like `/semantic_search` accepting queries, actions, and flags), use an ASCII decision tree to document the routing logic clearly.

### The Pattern

```markdown
---
description: [Command] with multiple entry points
argument-hint: "[action|query] [options]"
allowed-tools: [Tools]
---

# [Command Title]

---

## 1. 📋 ARGUMENT DISPATCH

```
$ARGUMENTS
    │
    ├─► Empty (no args)
    │   └─► DEFAULT ACTION: [What happens with no args]
    │
    ├─► First word matches ACTION KEYWORD (case-insensitive)
    │   ├─► "start" | "on" | "init"       → START ACTION
    │   ├─► "stop" | "off" | "kill"       → STOP ACTION
    │   ├─► "status" | "info"             → STATUS ACTION
    │   ├─► "search" | "find" | "query"   → SEARCH ACTION (remaining args = query)
    │   └─► "reset" | "clear"             → RESET ACTION
    │
    ├─► Looks like NATURAL LANGUAGE QUERY
    │   Detection: 2+ words, question words, code terms, quotes
    │   └─► SEARCH ACTION (full args = query)
    │
    └─► Single ambiguous word
        └─► [DEFAULT ACTION] (assume most common intent)
```

---

## 2. ⚡ ACTION HANDLERS

### START ACTION
[Instructions for start]

### STOP ACTION
[Instructions for stop]

### SEARCH ACTION
[Instructions for search]

---

## 3. 📊 EXAMPLE ROUTING

| Input | Detected As | Action |
|-------|-------------|--------|
| (empty) | No args | Show menu/help |
| `start` | Keyword | START ACTION |
| `how does auth work` | Natural language | SEARCH ACTION |
| `oauth` | Single word | SEARCH ACTION (default) |
```

### When to Use Argument Dispatch

| Scenario | Use Pattern? |
|----------|--------------|
| Command has multiple action keywords | **Yes** |
| Command accepts both keywords AND queries | **Yes** |
| Command has only one action | No (use simple template) |
| Command uses `:auto`/`:confirm` modes only | No (use mode-based template) |

### Real Example: `/semantic_search`

```
/semantic_search [args]
    │
    ├─► No args
    │   └─► Show usage help
    │
    ├─► "index" | "reindex" | "rebuild"
    │   └─► INDEX ACTION: Rebuild vector index
    │
    ├─► "status" | "health"
    │   └─► STATUS ACTION: Show index health
    │
    ├─► Natural language query (2+ words)
    │   └─► SEARCH ACTION: Execute semantic search
    │
    └─► Single ambiguous word
        └─► SEARCH ACTION (assume search intent)
```

### Combining with Mode-Based Pattern

For commands that need BOTH argument dispatch AND mode support:

```
$ARGUMENTS
    │
    ├─► Parse mode suffix (:auto | :confirm)
    │
    └─► After mode extraction, dispatch remaining args:
        ├─► "action1" → ACTION 1
        ├─► "action2" → ACTION 2
        └─► Natural language → DEFAULT ACTION
```

---

## 8. ⚠️ DESTRUCTIVE COMMAND TEMPLATE

Use for: Commands that delete data or make irreversible changes.

```markdown
---
description: [Action] (DESTRUCTIVE)
argument-hint: "[--confirm]"
allowed-tools: Bash, AskUserQuestion
---

# [Command Title]

**DESTRUCTIVE OPERATION** - [Brief warning about what will be affected.]

---

## 1. 📋 PURPOSE

[Explain the destructive action and why it might be needed.]

---

## 2. 📝 CONTRACT

**Inputs:** `$ARGUMENTS` — Must include `--confirm` flag to skip prompt
**Outputs:** `STATUS=<OK|FAIL|CANCELLED> ACTION=<action|cancelled>`

---

## 3. ⚡ INSTRUCTIONS

### Step 1: Safety Check - Require Confirmation

- Check if `--confirm` flag is present in `$ARGUMENTS`
- If NOT present:
  - Use AskUserQuestion: "[Warning message]. Are you sure?"
  - Options: "Yes, proceed" / "No, cancel"
  - If user cancels: `STATUS=CANCELLED ACTION=cancelled`

### Step 2: Show What Will Be Affected

- Display current state
- List items that will be deleted/changed
- Show size/count of affected data

### Step 3: Execute Destructive Action

- [Step-by-step execution]
- Log each action taken

### Step 4: Verify Completion

- Confirm action completed
- Show new state

### Step 5: Provide Recovery Guidance

- Explain how to rebuild/restore if needed
- Link to relevant commands

### Step 6: Return Status

- If completed: `STATUS=OK ACTION=[action]`
- If cancelled: `STATUS=CANCELLED ACTION=cancelled`
- If failed: `STATUS=FAIL ERROR="<message>"`

---

## 4. 🔍 EXAMPLE USAGE

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

## 5. 📌 NOTES

- **When to Use:**
  - [Valid use case 1]
  - [Valid use case 2]

- **Impact:**
  - [What will be lost]
  - [Other consequences]
  - [What is preserved]
  - [Recovery options]

- **Alternatives to Consider:**
  - [Less destructive alternative]
  - [Another option]

---

## 6. 🛡️ SAFETY FEATURES

- Requires explicit confirmation by default
- Shows what will be affected before proceeding
- Provides clear recovery steps
- Cannot accidentally affect [protected items]
```

---

## 9. 📁 NAMESPACE COMMAND PATTERN

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

## 10. 📝 FRONTMATTER FIELD REFERENCE

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

allowed-tools: Tool1, Tool2, Tool3
# Common tools: Read, Write, Edit, Bash, Grep, Glob, Task, AskUserQuestion
# MCP tools: mcp__[server-name]__[tool_function]
---
```

### Optional Fields

```yaml
---
name: command-name
# Override inferred name from filename

model: opus
# Override default model (USE SPARINGLY)

version: 1.0.0
# Track command version

disable-model-invocation: true
# Prevent Claude from invoking this command
---
```

---

## 11. ✅ VALIDATION CHECKLIST

Before publishing a command, verify:

### Frontmatter
- [ ] `description` is present and action-oriented
- [ ] `argument-hint` shows expected format (if args expected)
- [ ] `allowed-tools` lists all tools used (if any)
- [ ] No angle brackets `< >` in description (reserved for hints)

### Mandatory Gate (CRITICAL for required arguments)
- [ ] If `argument-hint` contains `<required>` args → **MANDATORY GATE present**
- [ ] Gate is **immediately after frontmatter**, before any other content
- [ ] Gate uses `AskUserQuestion` tool with appropriate question
- [ ] Gate includes all 4 CRITICAL RULES (DO NOT infer, assume, proceed)
- [ ] Skip gate only if ALL arguments are `[optional]` with defaults

### Structure
- [ ] H1 title matches command purpose (no emoji, no number)
- [ ] H2 sections use format: `## N. [EMOJI] SECTION-NAME`
- [ ] H3 subsections: `### Step N: Description` (no emoji)
- [ ] Dividers (`---`) between major sections
- [ ] Instructions are numbered and actionable
- [ ] Example usage shows 2-3 scenarios

### Header Format (NEW STANDARD)
- [ ] H1: Plain title only (`# Command Title`)
- [ ] H2: Numbered + emoji + ALL-CAPS (`## 1. 📋 PURPOSE`)
- [ ] H3/H4: Title case, no emoji (`### Step 1: Description`)
- [ ] Consistent numbering (1, 2, 3...)
- [ ] Appropriate emoji for section type

### Emoji Selection Guide

| Section Type | Emoji | Example |
|--------------|-------|---------|
| Purpose/Overview | 📋 | `## 1. 📋 PURPOSE` |
| Contract/Interface | 📝 | `## 2. 📝 CONTRACT` |
| Instructions/Steps | ⚡ | `## 3. ⚡ INSTRUCTIONS` |
| Usage/Examples | 🔍 | `## 4. 🔍 EXAMPLE USAGE` |
| Output/Results | 📊 | `## 5. 📊 OUTPUT FORMAT` |
| Notes/Info | 📌 | `## 6. 📌 NOTES` |
| Success/Goals | 🎯 | `## 5. 🎯 SUCCESS CRITERIA` |
| Related/Links | 🔗 | `## 6. 🔗 RELATED COMMANDS` |
| Troubleshooting | 🔧 | `## 7. 🔧 TROUBLESHOOTING` |
| Warning/Caution | ⚠️ | `## 4. ⚠️ ERROR HANDLING` |
| Files/Templates | 📁 | `## 6. 📁 TEMPLATES USED` |
| Safety/Security | 🛡️ | `## 6. 🛡️ SAFETY FEATURES` |
| Quick Reference | 📋 | `## 1. 📋 QUICK REFERENCE` |
| Mode/Routing | 🔀 | `## 2. 🔀 MODE DETECTION` |

### Status Output Patterns

| Pattern | Use Case | Example |
|---------|----------|---------|
| `STATUS=OK` | Simple success | Basic commands |
| `STATUS=OK RESULTS_COUNT=N` | Search/query | `/index:search` |
| `STATUS=OK ACTION=<action>` | State change | `/index:start` |
| `STATUS=OK ACTION=<action> PATH=<path>` | File creation | `/spec_kit:complete` |
| `STATUS=FAIL ERROR="<message>"` | All failures | Error handling |
| `STATUS=CANCELLED ACTION=cancelled` | User abort | Interactive commands |

---

## 12. 🧠 ORCHESTRATOR + WORKERS PATTERN

Use for: Commands that spawn parallel sub-agents for exploration/analysis.

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
              ├──────────────────┬──────────────────┐
              ▼                  ▼                  ▼
┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐
│ SONNET WORKER 1 │  │ SONNET WORKER 2 │  │ SONNET WORKER N │
│ Fast exploration│  │ Fast exploration│  │ Fast exploration│
└─────────────────┘  └─────────────────┘  └─────────────────┘
```

### Model Hierarchy

| Role | Model | Responsibility |
|------|-------|----------------|
| **Orchestrator** | `opus` | Task understanding, dispatch, verification, synthesis |
| **Workers** | `sonnet` | Fast parallel exploration, discovery, hypothesis generation |

### When to Use

| Scenario | Use Orchestrator Pattern? |
|----------|--------------------------|
| Parallel codebase exploration | Yes |
| Multi-aspect analysis | Yes |
| Complex planning with verification | Yes |
| Simple single-action command | No |
| Sequential workflow | No |

---

## 13. 🔗 RELATED RESOURCES

### Templates
- [frontmatter_templates.md](./frontmatter_templates.md) - Frontmatter by document type
- [skill_md_template.md](./skill_md_template.md) - If converting to skill

### Standards
- [core_standards.md](../references/core_standards.md) - Document type rules
- [validation.md](../references/validation.md) - Quality scoring

### Examples (Following New Standard)
- `.claude/commands/spec_kit/resume.md` - Reference file for formatting
- `.claude/commands/spec_kit/help.md` - Reference file for formatting
- `.claude/commands/spec_kit/status.md` - Reference file for formatting
