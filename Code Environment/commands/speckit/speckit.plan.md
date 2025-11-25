---
description: Planning workflow (7 steps) - spec through plan only, no implementation. Supports :auto and :confirm modes
---

## Smart Command: /speckit.plan

**Purpose**: Execute the SpecKit planning lifecycle from specification through planning. Terminates after creating plan.md - use `/speckit.implement` for implementation phase.

## User Input

```text
$ARGUMENTS
```

## Mode Detection & Routing

### Step 1: Parse Mode Suffix

Detect execution mode from command invocation:

| Pattern | Mode | Behavior |
|---------|------|----------|
| `/speckit.plan:auto` | AUTONOMOUS | Execute all steps without user approval gates |
| `/speckit.plan:confirm` | INTERACTIVE | Pause at each step for user approval |
| `/speckit.plan` (no suffix) | PROMPT | Ask user to choose mode |

### Step 2: Mode Selection (when no suffix detected)

If no `:auto` or `:confirm` suffix is present, use AskUserQuestion:

**Question**: "How would you like to execute this planning workflow?"

| Option | Mode | Description |
|--------|------|-------------|
| **A** | Autonomous | Execute all 7 steps without approval gates. Best for straightforward planning. |
| **B** | Interactive | Pause at each step for approval. Best for complex features needing discussion. |

**Wait for user response before proceeding.**

### Step 3: Transform Raw Input

Parse the raw text from `$ARGUMENTS` and transform into structured user_inputs fields.

**Field Extraction Rules**:

| Field | Pattern Detection | Default If Empty |
|-------|-------------------|------------------|
| `git_branch` | "branch: X", "on branch X", "feature/X" | Auto-create feature-{NNN} |
| `spec_folder` | "specs/NNN", "spec folder X", "in specs/X" | Auto-create next available |
| `context` | "using X", "with Y", "tech stack:", "constraints:" | Infer from request |
| `issues` | "issue:", "bug:", "problem:", "error:" | Discover during workflow |
| `request` | Primary task description (REQUIRED) | ERROR if completely empty |
| `environment` | URLs starting with http(s)://, "staging:", "production:" | Skip browser testing |
| `scope` | File paths, glob patterns, "files:" | Default to specs/** |

### Step 4: Load & Execute Workflow Prompt

Based on detected/selected mode:

- **AUTONOMOUS**: Load and execute `.claude/prompts/spec_kit/spec_kit_plan_auto.yaml`
- **INTERACTIVE**: Load and execute `.claude/prompts/spec_kit/spec_kit_plan_confirm.yaml`

## Workflow Overview (7 Steps)

| Step | Name | Purpose | Outputs |
|------|------|---------|---------|
| 1 | Request Analysis | Analyze inputs, define scope | requirement_summary |
| 2 | Pre-Work Review | Review AGENTS.md, standards | coding_standards_summary |
| 3 | Specification | Create spec.md | spec.md, feature branch |
| 4 | Clarification | Resolve ambiguities | updated spec.md |
| 5 | Quality Checklist | Generate validation checklist | checklists/requirements.md |
| 6 | Planning | Create technical plan | plan.md, planning-summary.md |
| 7 | Save Context | Preserve conversation | memory/*.md |

## Key Differences from /speckit.complete

- **Terminates after planning** - Does not include task breakdown, analysis, or implementation
- **Outputs planning-summary.md** instead of implementation-summary.md
- **Next step guidance** - Recommends `/speckit.implement` when ready to build
- **Use case** - Planning phase separation, stakeholder review, feasibility analysis

## Key Behaviors

### Autonomous Mode (`:auto`)
- Executes all steps without user approval gates
- Self-validates at each checkpoint
- Makes informed decisions based on best judgment
- Documents all significant decisions

### Interactive Mode (`:confirm`)
- Pauses after each step for user approval
- Presents options: Approve, Review Details, Modify, Skip
- Allows course correction throughout planning

## Error Handling

| Condition | Action |
|-----------|--------|
| Empty `$ARGUMENTS` | Prompt user: "Please describe what you want to plan" |
| Missing required field | Apply intelligent default or ask user |
| Validation failure | Log issue and attempt resolution |

## Templates Used

- `.opencode/speckit/templates/spec_template.md`
- `.opencode/speckit/templates/plan_template.md`
- `.opencode/speckit/templates/checklist_template.md`
- `.opencode/speckit/templates/research_spike_template.md` (optional)
- `.opencode/speckit/templates/decision_record_template.md` (optional)

## Completion Report

After workflow completion, report:

```
✅ SpecKit Plan Workflow Finished

Mode: [AUTONOMOUS/INTERACTIVE]
Branch: feature-NNN-short-name
Spec Folder: specs/NNN-short-name/

Artifacts Created:
- spec.md (specification with acceptance criteria)
- plan.md (technical approach and architecture)
- planning-summary.md (planning overview)
- checklists/requirements.md (validation checklist)
- memory/[timestamp]__planning_session.md (context saved)

Next Steps:
- Review planning documentation
- Validate technical approach with stakeholders
- Run /speckit.implement:auto or /speckit.implement:confirm to begin implementation
```
