---
description: Implementation workflow (8 steps) - execute pre-planned work. Requires existing plan.md. Supports :auto and :confirm modes
argument-hint: "<spec-folder> [:auto|:confirm]"
allowed-tools: Read, Write, Edit, Bash, Grep, Glob, Task, AskUserQuestion
---

# SpecKit Implement

Execute implementation of a pre-planned feature. Requires existing spec.md and plan.md from a prior `/spec_kit:plan` workflow.

> **Note**: This is a standalone workflow (8 steps) that assumes spec.md and plan.md already exist.
> Run `/spec_kit:plan` first if you need to create planning artifacts.

---

## Purpose

Run the 8-step implementation workflow: plan review, task breakdown, quality validation, development, and completion summary. Picks up where `/spec_kit:plan` left off to execute the actual code changes.

---

## Contract

**Inputs:** `$ARGUMENTS` — Spec folder path (REQUIRED) with optional parameters (environment, constraints)
**Outputs:** Completed implementation + implementation-summary.md + `STATUS=<OK|FAIL|CANCELLED>`

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

If prerequisites are missing, guide user to run `/spec_kit:plan` first.

## Workflow Overview (8 Steps)

| Step | Name | Purpose | Outputs |
|------|------|---------|---------|
| 1 | Review Plan & Spec | Understand requirements | requirements_summary |
| 2 | Task Breakdown | Create/validate tasks.md | tasks.md |
| 3 | Analysis | Verify consistency | consistency_report |
| 4 | Quality Checklist | Validate checklists | checklist_status |
| 5 | Implementation Check | Verify prerequisites | greenlight |
| 6 | Development | Execute implementation | code changes |
| 7 | Completion | Generate summary | implementation-summary.md |
| 8 | Save Context | Preserve conversation | memory/*.md |

---

## Instructions

### Phase 1: Mode Detection & Input Parsing

#### Step 1.1: Parse Mode Suffix

Detect execution mode from command invocation:

| Pattern | Mode | Behavior |
|---------|------|----------|
| `/spec_kit:implement:auto` | AUTONOMOUS | Execute all steps without user approval gates |
| `/spec_kit:implement:confirm` | INTERACTIVE | Pause at each step for user approval |
| `/spec_kit:implement` (no suffix) | PROMPT | Ask user to choose mode |

#### Step 1.2: Mode Selection (when no suffix detected)

If no `:auto` or `:confirm` suffix is present, use AskUserQuestion:

**Question**: "How would you like to execute this implementation workflow?"

| Option | Mode | Description |
|--------|------|-------------|
| **A** | Autonomous | Execute all 8 steps without approval gates. Best for straightforward implementation. |
| **B** | Interactive | Pause at each step for approval. Best for complex code changes needing review. |

**Wait for user response before proceeding.**

#### Step 1.3: Transform Raw Input

Parse the raw text from `$ARGUMENTS` and transform into structured user_inputs fields.

**Field Extraction Rules**:

| Field | Pattern Detection | Default If Empty |
|-------|-------------------|------------------|
| `git_branch` | "branch: X", "on branch X", "feature/X" | Use existing branch from spec folder |
| `spec_folder` | "specs/NNN", "spec folder X", "in specs/X" | REQUIRED - must specify or detect |
| `context` | "using X", "with Y", "constraints:" | Infer from spec folder |
| `issues` | "issue:", "bug:", "problem:", "error:", "question:", "unknown:" | Discover during workflow |
| `request` | Additional instructions | "Conduct comprehensive review and implement" |
| `environment` | URLs, "staging:", "production:" | Skip browser testing |
| `scope` | File paths, glob patterns | Default to specs/** |

#### Step 1.4: Load & Execute Workflow Prompt

Based on detected/selected mode:

- **AUTONOMOUS**: Load and execute `.claude/commands/spec_kit/assets/spec_kit_implement_auto.yaml`
- **INTERACTIVE**: Load and execute `.claude/commands/spec_kit/assets/spec_kit_implement_confirm.yaml`

### Phase 2: Workflow Execution

Execute the 8 steps defined in Workflow Overview. Each step produces artifacts that feed into subsequent steps. See prompt files for detailed step-by-step instructions.

---

## Key Differences from /spec_kit:complete

- **Requires existing plan** - Won't create spec.md or plan.md
- **Starts at implementation** - Skips specification and planning phases
- **Use case** - Separated planning/implementation, team handoffs, phased delivery

---

## Context Loading

When resuming work in an existing spec folder, the system will prompt to load prior session memory:
- **A)** Load most recent memory file (quick context refresh)
- **B)** Load all recent files (up to 3) (comprehensive context)
- **C)** List all files and select specific (historical search)
- **D)** Skip (start fresh, no context)

See CLAUDE.md Section 2 for full memory file handling details.

## Failure Recovery

| Failure Type | Recovery Action |
|--------------|-----------------|
| Step validation fails | Review requirements, ask clarifying questions, retry |
| User rejects approach | Present alternatives, modify code, document decision |
| Tests fail during implementation | Debug, fix, re-run before marking complete |
| Prerequisites insufficient | Return to `/spec_kit:plan` workflow |
| Environment unavailable | Skip browser testing, document limitation |

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

Please run /spec_kit:plan first to create planning artifacts.
```

## Error Handling

| Condition | Action |
|-----------|--------|
| Missing spec.md | ERROR: Guide to /spec_kit:plan |
| Missing plan.md | ERROR: Guide to /spec_kit:plan |
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

STATUS=OK PATH=specs/NNN-short-name/
```

## Examples

**Example 1: Execute Existing Plan (autonomous)**
```
/spec_kit:implement:auto specs/042-user-auth/
```

**Example 2: With Review (interactive)**
```
/spec_kit:implement:confirm specs/042-user-auth/
```

**Example 3: With Staging Environment**
```
/spec_kit:implement "specs/042-user-auth/" staging: https://staging.example.com
```

---

## Notes

- **Mode Behaviors:**
  - **Autonomous (`:auto`)**: Executes all steps without user approval gates. Self-validates at each checkpoint. Marks tasks complete as they're finished. Documents all implementation decisions.
  - **Interactive (`:confirm`)**: Pauses after each step for user approval. Presents options: Approve, Review Details, Modify, Skip, Abort. Allows code review at each checkpoint.

- **Prerequisites:**
  - Requires spec.md and plan.md from prior `/spec_kit:plan` workflow
  - Will create tasks.md if missing

- **Integration:**
  - Works with spec folder system for documentation
  - Pairs with `/spec_kit:plan` for planning phase
  - Context saved via workflows-save-context skill
