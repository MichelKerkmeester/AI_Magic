---
description: Full end-to-end SpecKit workflow (12 steps) - supports :auto and :confirm modes
argument-hint: "[feature-description] [:auto|:confirm]"
allowed-tools: Read, Write, Edit, Bash, Grep, Glob, Task, AskUserQuestion
---

# SpecKit Complete

Execute the complete SpecKit lifecycle from specification through implementation with context preservation. Supports autonomous (`:auto`) and interactive (`:confirm`) execution modes.

---

```yaml
role: Expert Developer using Smart SpecKit with Full Lifecycle Management
purpose: Spec-driven development with mandatory compliance and comprehensive documentation
action: Run full 12-step SpecKit from specification to implementation with context preservation

operating_mode:
  workflow: sequential_12_step
  workflow_compliance: MANDATORY
  workflow_execution: autonomous_or_interactive
  approvals: step_by_step_for_confirm_mode
  tracking: progressive_task_checklists
  validation: checkpoint_based_with_checklist_verification
```

---

## Purpose

Run the full 12-step SpecKit workflow: specification, clarification, planning, task breakdown, implementation, and context saving. This is the comprehensive workflow for feature development with full documentation trail.

---

## Contract

**Inputs:** `$ARGUMENTS` — Feature description with optional parameters (branch, scope, context)
**Outputs:** Complete spec folder with all artifacts + `STATUS=<OK|FAIL|CANCELLED>`

## User Input

```text
$ARGUMENTS
```

## Workflow Overview (12 Steps)

| Step | Name | Purpose | Outputs |
|------|------|---------|---------|
| 1 | Request Analysis | Analyze inputs, define scope | requirement_summary |
| 2 | Pre-Work Review | Review AGENTS.md, standards | coding_standards_summary |
| 3 | Specification | Create spec.md | spec.md, feature branch |
| 4 | Clarification | Resolve ambiguities | updated spec.md |
| 5 | Quality Checklist | Generate validation checklist (ACTIVELY USED for verification at completion) | checklists/requirements.md |
| 6 | Planning | Create technical plan | plan.md, research.md |
| 7 | Task Breakdown | Break into tasks | tasks.md |
| 8 | Analysis | Verify consistency | consistency_report |
| 9 | Implementation Check | Verify prerequisites | greenlight |
| 10 | Development | Execute implementation | code changes |
| 11 | Completion | Generate summary | implementation-summary.md |
| 12 | Save Context | Preserve conversation | memory/*.md |

---

## Instructions

### Phase 1: Mode Detection & Input Parsing

#### Step 1.1: Parse Mode Suffix

Detect execution mode from command invocation:

| Pattern | Mode | Behavior |
|---------|------|----------|
| `/spec_kit:complete:auto` | AUTONOMOUS | Execute all steps without user approval gates |
| `/spec_kit:complete:confirm` | INTERACTIVE | Pause at each step for user approval |
| `/spec_kit:complete` (no suffix) | PROMPT | Ask user to choose mode |

#### Step 1.2: Mode Selection (when no suffix detected)

If no `:auto` or `:confirm` suffix is present, use AskUserQuestion:

**Question**: "How would you like to execute this workflow?"

| Option | Mode | Description |
|--------|------|-------------|
| **A** | Autonomous | Execute all 12 steps without approval gates. Best for well-defined tasks with clear requirements. |
| **B** | Interactive | Pause at each step for approval. Best for complex features where you want control over decisions. |

**Wait for user response before proceeding.**

#### Step 1.3: Transform Raw Input

Parse the raw text from `$ARGUMENTS` and transform into structured user_inputs fields.

**Field Extraction Rules**:

| Field | Pattern Detection | Default If Empty |
|-------|-------------------|------------------|
| `git_branch` | "branch: X", "on branch X", "feature/X" | Auto-create feature-{NNN} |
| `spec_folder` | "specs/NNN", "spec folder X", "in specs/X" | Auto-create next available |
| `context` | "using X", "with Y", "tech stack:", "constraints:" | Infer from request |
| `issues` | "issue:", "bug:", "problem:", "error:", "question:", "unknown:" | Discover during workflow |
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

#### Step 1.4: Load & Execute Workflow Prompt

Based on detected/selected mode:

- **AUTONOMOUS**: Load and execute `.claude/commands/spec_kit/assets/spec_kit_complete_auto.yaml`
- **INTERACTIVE**: Load and execute `.claude/commands/spec_kit/assets/spec_kit_complete_confirm.yaml`

### Phase 2: Workflow Execution

Execute the 12 steps defined in Workflow Overview. Each step produces artifacts that feed into subsequent steps. See prompt files for detailed step-by-step instructions.

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
| User rejects approach | Present alternatives, modify plan, document decision |
| Tests fail during implementation | Debug, fix, re-run before marking complete |
| Prerequisites insufficient | Return to prior workflow phase (planning) |
| Environment unavailable | Skip browser testing, document limitation |

## Error Handling

| Condition | Action |
|-----------|--------|
| Empty `$ARGUMENTS` | Prompt user: "Please describe what you want to accomplish" |
| Missing required field | Apply intelligent default or ask user |
| Prerequisites missing | Guide user to prerequisite commands |
| Validation failure | Log issue and attempt resolution or escalate |

## Documentation Levels (Progressive Enhancement)

| Level | Required Files | LOC Guidance | Use Case |
|-------|---------------|--------------|----------|
| **Level 1 (Baseline)** | spec.md + plan.md + tasks.md | <100 LOC | Simple changes, bug fixes |
| **Level 2 (Verification)** | Level 1 + checklist.md | 100-499 LOC | Medium features, refactoring |
| **Level 3 (Full)** | Level 2 + decision-record.md | >=500 LOC | Complex features, architecture changes |

**Note:** LOC thresholds are soft guidance. Choose level based on complexity and risk.

**Important:** For Level 2+, `checklist.md` is MANDATORY for verification before any completion claims. The AI must actively use it to verify work.

## Templates Used

- `.opencode/speckit/templates/spec.md` (Level 1+)
- `.opencode/speckit/templates/plan.md` (Level 1+)
- `.opencode/speckit/templates/tasks.md` (Level 1+)
- `.opencode/speckit/templates/checklist.md` (Level 2+)
- `.opencode/speckit/templates/decision-record.md` (Level 3)
- `.opencode/speckit/templates/research-spike.md` (optional, any level)

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
- checklist.md (validation checklist - Level 2+)
- implementation-summary.md (completion report)
- memory/[timestamp]__session.md (context saved)

Implementation:
- Files modified: [count]
- Tests: [PASS/FAIL]
- Browser validation: [COMPLETE/SKIPPED]

Checklist Verification (Level 2+):
- Status: [VERIFIED/PARTIAL/N/A]
- Items verified: [X/Y] (e.g., "15/15 items verified")
- P0 (Critical): [X/Y] - All must pass
- P1 (High): [X/Y] - Required items
- P2 (Medium): [X/Y] - Optional items
- Deferred items: [list with reasons, if any]

Next Steps:
- Review implementation summary
- Prepare for code review and PR

STATUS=OK PATH=specs/NNN-short-name/
```

## Examples

**Example 1: Simple Feature (autonomous)**
```
/spec_kit:complete:auto Add a newsletter signup form to the footer
```

**Example 2: Complex Feature (interactive)**
```
/spec_kit:complete:confirm Add user authentication with OAuth2 to the dashboard. Use Passport.js. Staging: https://staging.example.com
```

**Example 3: With Specific Files**
```
/spec_kit:complete "Refactor the payment processing module" files: src/payments/** src/checkout/**
```

---

## Notes

### Checklist Verification Protocol (Level 2+ Mandatory)

When `checklist.md` exists, the AI MUST complete verification before any completion claims:

1. **Load** checklist.md at completion phase
2. **Verify** each item systematically:
   - P0 (Critical): BLOCKERS - must complete
   - P1 (High): Required - complete or get user deferral approval
   - P2 (Medium): Optional - can defer with documentation
3. **Mark** items `[x]` with evidence (links, test output, etc.)
4. **Block** completion until all P0/P1 items verified
5. **Document** any deferred items in completion summary

**Example Verification:**
```
- [x] CHK001 [P0] Requirements documented | Evidence: spec.md sections 1-3
- [x] CHK006 [P0] Code passes lint | Evidence: `npm run lint` - 0 errors
- [ ] CHK016 [P2] Performance targets | Deferred: Will benchmark post-MVP
```

- **Mode Behaviors:**
  - **Autonomous (`:auto`)**: Executes all steps without user approval gates. Self-validates at each checkpoint. Makes informed decisions based on best judgment. Documents all significant decisions. Logs deviations from expected patterns.
  - **Interactive (`:confirm`)**: Pauses after each step for user approval. Presents options: Approve, Review Details, Modify, Skip, Abort. Documents user decisions at each checkpoint. Allows course correction throughout workflow.

- **Parallel Sub-Agent Dispatch:**
  - Eligible phases (Specification, Analysis, Development) can dispatch parallel sub-agents for faster execution
  - Complexity scoring evaluates: domain count (35%), file count (25%), LOC estimate (15%), parallel opportunity (20%), task type (5%)
  - **Dispatch Thresholds:**
    - <20% complexity → Execute directly (silent)
    - ≥20% + 2 domains → Ask user via AskUserQuestion
    - ≥50% + 3 domains → Auto-dispatch with notification
  - **Session Preference:** User's choice persists for 1 hour
  - **Override Phrases:** "proceed directly", "use parallel agents", "auto-decide"
  - Step 6 (Planning) automatically uses 4-agent parallel exploration (inline via Task tool)

- **Integration:**
  - Works with spec folder system for documentation
  - Plans can feed into `/spec_kit:implement` workflow
  - Context saved via workflows-save-context skill
