---
description: Full end-to-end SpecKit workflow (12 steps) - supports :auto and :confirm modes
---

## Smart Command: /speckit.complete

**Purpose**: Execute the complete SpecKit lifecycle from specification through implementation with save context. Supports two execution modes.

## User Input

```text
$ARGUMENTS
```

## Mode Detection & Routing

### Step 1: Parse Mode Suffix

Detect execution mode from command invocation:

| Pattern | Mode | Behavior |
|---------|------|----------|
| `/speckit.complete:auto` | AUTONOMOUS | Execute all steps without user approval gates |
| `/speckit.complete:confirm` | INTERACTIVE | Pause at each step for user approval |
| `/speckit.complete` (no suffix) | PROMPT | Ask user to choose mode |

### Step 2: Mode Selection (when no suffix detected)

If no `:auto` or `:confirm` suffix is present, use AskUserQuestion:

**Question**: "How would you like to execute this workflow?"

| Option | Mode | Description |
|--------|------|-------------|
| **A** | Autonomous | Execute all 12 steps without approval gates. Best for well-defined tasks with clear requirements. |
| **B** | Interactive | Pause at each step for approval. Best for complex features where you want control over decisions. |

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
| `scope` | File paths, glob patterns like `src/**/*.js`, "files:" | Default to specs/** |

**Transformation Process**:

1. **Extract explicit fields**: Scan for labeled patterns ("branch:", "files:", etc.)
2. **Infer implicit fields**: Extract context clues from natural language
3. **Apply defaults**: Fill remaining fields with intelligent defaults
4. **Validate required**: Ensure `request` field has substantive content

**Example Transformation**:

Raw input:
```
Add user authentication with OAuth2 to the dashboard.
Use Passport.js for the backend. Staging: https://staging.example.com
Files in src/auth/ and src/middleware/
```

Transformed:
```yaml
user_inputs:
  git_branch: ""  # Auto-create
  spec_folder: ""  # Auto-create
  context: "Technical stack: Passport.js for OAuth2 implementation"
  issues: ""  # Discover during workflow
  request: "Add user authentication with OAuth2 to the dashboard"
  environment: "https://staging.example.com"
  scope: |
    src/auth/**
    src/middleware/**
```

### Step 4: Load & Execute Workflow Prompt

Based on detected/selected mode:

- **AUTONOMOUS**: Load and execute `.claude/prompts/spec_kit/spec_kit_complete_auto.yaml`
- **INTERACTIVE**: Load and execute `.claude/prompts/spec_kit/spec_kit_complete_confirm.yaml`

## Workflow Overview (12 Steps)

| Step | Name | Purpose | Outputs |
|------|------|---------|---------|
| 1 | Request Analysis | Analyze inputs, define scope | requirement_summary |
| 2 | Pre-Work Review | Review AGENTS.md, standards | coding_standards_summary |
| 3 | Specification | Create spec.md | spec.md, feature branch |
| 4 | Clarification | Resolve ambiguities | updated spec.md |
| 5 | Quality Checklist | Generate validation checklist | checklists/requirements.md |
| 6 | Planning | Create technical plan | plan.md, research.md |
| 7 | Task Breakdown | Break into tasks | tasks.md |
| 8 | Analysis | Verify consistency | consistency_report |
| 9 | Implementation Check | Verify prerequisites | greenlight |
| 10 | Development | Execute implementation | code changes |
| 11 | Completion | Generate summary | implementation-summary.md |
| 12 | Save Context | Preserve conversation | memory/*.md |

## Key Behaviors

### Autonomous Mode (`:auto`)
- Executes all steps without user approval gates
- Self-validates at each checkpoint
- Makes informed decisions based on best judgment
- Documents all significant decisions
- Logs deviations from expected patterns

### Interactive Mode (`:confirm`)
- Pauses after each step for user approval
- Presents options: Approve, Review Details, Modify, Skip, Abort
- Documents user decisions at each checkpoint
- Allows course correction throughout workflow

## Error Handling

| Condition | Action |
|-----------|--------|
| Empty `$ARGUMENTS` | Prompt user: "Please describe what you want to accomplish" |
| Missing required field | Apply intelligent default or ask user |
| Prerequisites missing | Guide user to prerequisite commands |
| Validation failure | Log issue and attempt resolution or escalate |

## Templates Used

- `.opencode/speckit/templates/spec_template.md`
- `.opencode/speckit/templates/plan_template.md`
- `.opencode/speckit/templates/tasks_template.md`
- `.opencode/speckit/templates/checklist_template.md`
- `.opencode/speckit/templates/research_spike_template.md` (optional)
- `.opencode/speckit/templates/decision_record_template.md` (optional)

## Completion Report

After workflow completion, report:

```
✅ SpecKit Complete Workflow Finished

Mode: [AUTONOMOUS/INTERACTIVE]
Branch: feature-NNN-short-name
Spec Folder: specs/NNN-short-name/

Artifacts Created:
- spec.md (specification with acceptance criteria)
- plan.md (technical approach and architecture)
- tasks.md (implementation breakdown)
- checklists/requirements.md (validation checklist)
- implementation-summary.md (completion report)
- memory/[timestamp]__session.md (context saved)

Implementation:
- Files modified: [count]
- Tests: [PASS/FAIL]
- Browser validation: [COMPLETE/SKIPPED]

Next Steps:
- Review implementation summary
- Prepare for code review and PR
```
