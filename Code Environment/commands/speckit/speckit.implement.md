---
description: Implementation workflow (8 steps) - execute pre-planned work. Requires existing plan.md. Supports :auto and :confirm modes
---

## Smart Command: /speckit.implement

**Purpose**: Execute implementation of a pre-planned feature. Requires existing spec.md and plan.md from a prior `/speckit.plan` or `/speckit.complete` workflow that was terminated early.

## User Input

```text
$ARGUMENTS
```

## Prerequisites

**REQUIRED**: This command requires existing planning artifacts:
- `spec.md` - Feature specification
- `plan.md` - Technical plan

**OPTIONAL** (will be created if missing):
- `tasks.md` - Task breakdown

If prerequisites are missing, guide user to run `/speckit.plan` first.

## Mode Detection & Routing

### Step 1: Parse Mode Suffix

Detect execution mode from command invocation:

| Pattern | Mode | Behavior |
|---------|------|----------|
| `/speckit.implement:auto` | AUTONOMOUS | Execute all steps without user approval gates |
| `/speckit.implement:confirm` | INTERACTIVE | Pause at each step for user approval |
| `/speckit.implement` (no suffix) | PROMPT | Ask user to choose mode |

### Step 2: Mode Selection (when no suffix detected)

If no `:auto` or `:confirm` suffix is present, use AskUserQuestion:

**Question**: "How would you like to execute this implementation workflow?"

| Option | Mode | Description |
|--------|------|-------------|
| **A** | Autonomous | Execute all 8 steps without approval gates. Best for straightforward implementation. |
| **B** | Interactive | Pause at each step for approval. Best for complex code changes needing review. |

**Wait for user response before proceeding.**

### Step 3: Transform Raw Input

Parse the raw text from `$ARGUMENTS` and transform into structured user_inputs fields.

**Field Extraction Rules**:

| Field | Pattern Detection | Default If Empty |
|-------|-------------------|------------------|
| `git_branch` | "branch: X", "on branch X", "feature/X" | Use existing branch from spec folder |
| `spec_folder` | "specs/NNN", "spec folder X", "in specs/X" | REQUIRED - must specify or detect |
| `context` | "using X", "with Y", "constraints:" | Infer from spec folder |
| `issues` | "issue:", "bug:", "problem:" | Discover during workflow |
| `request` | Additional instructions | "Conduct comprehensive review and implement" |
| `environment` | URLs, "staging:", "production:" | Skip browser testing |
| `scope` | File paths, glob patterns | Default to specs/** |

### Step 4: Load & Execute Workflow Prompt

Based on detected/selected mode:

- **AUTONOMOUS**: Load and execute `.claude/prompts/spec_kit/spec_kit_implement_auto.yaml`
- **INTERACTIVE**: Load and execute `.claude/prompts/spec_kit/spec_kit_implement_confirm.yaml`

## Workflow Overview (8 Steps)

| Step | Name | Purpose | Outputs |
|------|------|---------|---------|
| 10 | Review Plan & Spec | Understand requirements | requirements_summary |
| 11 | Task Breakdown | Create/validate tasks.md | tasks.md |
| 12 | Analysis | Verify consistency | consistency_report |
| 13 | Quality Checklist | Validate checklists | checklist_status |
| 14 | Implementation Check | Verify prerequisites | greenlight |
| 15 | Development | Execute implementation | code changes |
| 16 | Completion | Generate summary | implementation-summary.md |
| 17 | Save Context | Preserve conversation | memory/*.md |

**Note**: Step numbers continue from planning workflow (10-17) to indicate this is a continuation.

## Key Differences from /speckit.complete

- **Requires existing plan** - Won't create spec.md or plan.md
- **Starts at implementation** - Skips specification and planning phases
- **Use case** - Separated planning/implementation, team handoffs, phased delivery

## Key Behaviors

### Autonomous Mode (`:auto`)
- Executes all steps without user approval gates
- Self-validates at each checkpoint
- Marks tasks complete as they're finished
- Documents all implementation decisions

### Interactive Mode (`:confirm`)
- Pauses after each step for user approval
- Presents options: Approve, Review Code, Modify, Continue
- Allows code review at each checkpoint

## Prerequisite Check

Before starting workflow, run:
```bash
.opencode/speckit/scripts/check-prerequisites.sh --json --require-tasks --include-tasks
```

Parse output for:
- `FEATURE_DIR` - Spec folder path
- `FEATURE_SPEC` - Path to spec.md
- `IMPL_PLAN` - Path to plan.md
- `TASKS` - Path to tasks.md (if exists)
- `AVAILABLE_DOCS` - List of available artifacts

If prerequisites missing, display:
```
⚠️ Prerequisites Missing

Required artifacts not found:
- spec.md: [FOUND/MISSING]
- plan.md: [FOUND/MISSING]

Please run /speckit.plan first to create planning artifacts.
```

## Error Handling

| Condition | Action |
|-----------|--------|
| Missing spec.md | ERROR: Guide to /speckit.plan |
| Missing plan.md | ERROR: Guide to /speckit.plan |
| Missing tasks.md | Create tasks.md from plan.md |
| Checklist failures | Prompt user to proceed or fix |
| Test failures | Log and report, allow user decision |

## Templates Used

- `.opencode/speckit/templates/tasks_template.md`
- `.opencode/speckit/templates/checklist_template.md`

## Completion Report

After workflow completion, report:

```
✅ SpecKit Implementation Workflow Finished

Mode: [AUTONOMOUS/INTERACTIVE]
Branch: feature-NNN-short-name
Spec Folder: specs/NNN-short-name/

Implementation Summary:
- Tasks completed: [X/Y]
- Files modified: [count]
- Files created: [count]
- Tests: [PASS/FAIL]
- Browser validation: [COMPLETE/SKIPPED]

Artifacts Updated/Created:
- tasks.md (all tasks marked complete)
- implementation-summary.md (completion report)
- memory/[timestamp]__implementation_session.md (context saved)

Next Steps:
- Review implementation summary
- Run final tests
- Prepare for code review and PR submission
```
