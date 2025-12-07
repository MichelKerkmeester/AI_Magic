---
description: Planning workflow (7 steps) - spec through plan only, no implementation. Supports :auto and :confirm modes
argument-hint: "[feature-description] [:auto|:confirm]"
allowed-tools: Read, Write, Edit, Bash, Grep, Glob, Task, AskUserQuestion
---

# 🚨 MANDATORY FIRST ACTION - DO NOT SKIP

**BEFORE READING ANYTHING ELSE IN THIS FILE, CHECK `$ARGUMENTS`:**

```
IF $ARGUMENTS is empty, undefined, or contains only whitespace (ignoring mode flags):
    → STOP IMMEDIATELY
    → Use AskUserQuestion tool with this exact question:
        question: "What feature would you like to plan?"
        options:
          - label: "Describe my feature"
            description: "I'll provide a feature description for planning"
    → WAIT for user response
    → Use their response as the feature description
    → Only THEN continue with this workflow

IF $ARGUMENTS contains a feature description:
    → Continue reading this file
```

**CRITICAL RULES:**
- **DO NOT** infer features from context, screenshots, or existing spec folders
- **DO NOT** assume what the user wants based on conversation history
- **DO NOT** proceed past this point without an explicit feature description from the user
- The feature MUST come from `$ARGUMENTS` or user's answer to the question above

---

# SpecKit Plan

Execute the SpecKit planning lifecycle from specification through planning. Terminates after creating plan.md - use `/spec_kit:implement` for implementation phase.

---

```yaml
role: Expert Developer using Smart SpecKit for Planning Phase
purpose: Spec-driven planning with mandatory compliance and stakeholder review support
action: Run 7-step planning workflow from specification through technical plan creation

operating_mode:
  workflow: sequential_7_step
  workflow_compliance: MANDATORY
  workflow_execution: autonomous_or_interactive
  approvals: step_by_step_for_confirm_mode
  tracking: progressive_artifact_creation
  validation: consistency_check_before_handoff
```

---

## Purpose

Run the 7-step planning workflow: specification, clarification, quality checklist, and technical planning. Creates spec.md, plan.md, and checklists without proceeding to implementation. Use when planning needs review before coding.

---

## Contract

**Inputs:** `$ARGUMENTS` — Feature description with optional parameters (branch, scope, context)
**Outputs:** Spec folder with planning artifacts (spec.md, plan.md, checklists/) + `STATUS=<OK|FAIL|CANCELLED>`

## User Input

```text
$ARGUMENTS
```

## Workflow Overview (7 Steps)

| Step | Name | Purpose | Outputs |
|------|------|---------|---------|
| 1 | Request Analysis | Analyze inputs, define scope | requirement_summary |
| 2 | Pre-Work Review | Review AGENTS.md, standards | coding_standards_summary |
| 3 | Specification | Create spec.md | spec.md, feature branch |
| 4 | Clarification | Resolve ambiguities | updated spec.md |
| 5 | Quality Checklist | Generate validation checklist (will be ACTIVELY USED for verification during implementation) | checklists/requirements.md |
| 6 | Planning | Create technical plan | plan.md, planning-summary.md |
| 7 | Save Context | Preserve conversation | memory/*.md |

---

## Instructions

### Phase 1: Mode Detection & Input Parsing

#### Step 1.1: Parse Mode Suffix

Detect execution mode from command invocation:

| Pattern | Mode | Behavior |
|---------|------|----------|
| `/spec_kit:plan:auto` | AUTONOMOUS | Execute all steps without user approval gates |
| `/spec_kit:plan:confirm` | INTERACTIVE | Pause at each step for user approval |
| `/spec_kit:plan` (no suffix) | PROMPT | Ask user to choose mode |

#### Step 1.2: Mode Selection (when no suffix detected)

If no `:auto` or `:confirm` suffix is present, use AskUserQuestion:

**Question**: "How would you like to execute this planning workflow?"

| Option | Mode | Description |
|--------|------|-------------|
| **A** | Autonomous | Execute all 7 steps without approval gates. Best for straightforward planning. |
| **B** | Interactive | Pause at each step for approval. Best for complex features needing discussion. |

**Wait for user response before proceeding.**

#### Step 1.3: Spec Folder Confirmation (MANDATORY - DO NOT SKIP)

🚨 **This step is REQUIRED by AGENTS.md Section 1 - "Collaboration First"**

**BEFORE any file creation or workflow execution, you MUST:**

1. **Search for related spec folders:**
   ```bash
   ls -d specs/*/ 2>/dev/null | head -10
   ```
   Also search for keyword matches in existing spec folders related to the planning topic.

2. **Present A/B/C/D options using AskUserQuestion:**
   ```
   question: "Where should this plan be documented?"
   options:
     - A) Use existing spec folder: [suggest if related spec found]
     - B) Create new spec folder: specs/[NNN]-[feature-slug]/
     - C) Update related spec: [if partial match found]
     - D) Skip documentation (planning only, no persistent artifacts)
   ```

3. **WAIT for explicit user response** - Do NOT proceed until user selects an option.

4. **If user selects Option A or C AND memory files exist:**
   - Trigger memory file selection (MANDATORY per AGENTS.md Section 1):
   ```
   question: "Load previous context from this spec folder?"
   options:
     - A) Load most recent memory file (quick context refresh)
     - B) Load all recent files (up to 3) (comprehensive context)
     - C) List all files and select specific (historical search)
     - D) Skip (start fresh, no context)
   ```
   - Use Read tool to load selected memory files
   - Acknowledge loaded context before proceeding

5. **Create/use spec folder based on user's explicit choice:**
   - Option A: Use specified existing folder
   - Option B: Create new folder with next sequential number
   - Option C: Update specified related folder
   - Option D: Skip folder creation (plan output will not be persisted)

**CRITICAL:**
- NEVER auto-create spec folders without user confirmation
- NEVER skip this step even if `$ARGUMENTS` contains a spec folder reference
- NEVER proceed to Step 1.4 until user has explicitly chosen

#### Step 1.4: Transform Raw Input

Parse the raw text from `$ARGUMENTS` and transform into structured user_inputs fields.

**Field Extraction Rules**:

| Field | Pattern Detection | Default If Empty |
|-------|-------------------|------------------|
| `git_branch` | "branch: X", "on branch X", "feature/X" | Auto-create feature-{NNN} |
| `spec_folder` | "specs/NNN", "spec folder X", "in specs/X" | **USE VALUE FROM STEP 1.3** (user's explicit choice) |
| `context` | "using X", "with Y", "tech stack:", "constraints:" | Infer from request |
| `issues` | "issue:", "bug:", "problem:", "error:", "question:", "unknown:" | Discover during workflow |
| `request` | Primary task description (REQUIRED) | ERROR if completely empty |
| `environment` | URLs starting with http(s)://, "staging:", "production:" | Skip browser testing |
| `scope` | File paths, glob patterns, "files:" | Default to specs/** |

**IMPORTANT:** The `spec_folder` field MUST come from the user's explicit choice in Step 1.3.
Do NOT auto-create or infer - the user MUST have selected Option A, B, C, or D.

#### Step 1.5: Load & Execute Workflow Prompt

Based on detected/selected mode:

- **AUTONOMOUS**: Load and execute `.claude/commands/spec_kit/assets/spec_kit_plan_auto.yaml`
- **INTERACTIVE**: Load and execute `.claude/commands/spec_kit/assets/spec_kit_plan_confirm.yaml`

### Phase 2: Workflow Execution

Execute the 7 steps defined in Workflow Overview. Each step produces artifacts that feed into subsequent steps. See prompt files for detailed step-by-step instructions.

---

## Key Differences from /spec_kit:complete

- **Terminates after planning** - Does not include task breakdown, analysis, or implementation
- **Outputs planning-summary.md** instead of implementation-summary.md
- **Next step guidance** - Recommends `/spec_kit:implement` when ready to build
- **Use case** - Planning phase separation, stakeholder review, feasibility analysis

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
| Spec ambiguity persists | Document as assumption, add to risk matrix |
| Environment unavailable | Skip browser testing, document limitation |

## Error Handling

| Condition | Action |
|-----------|--------|
| Empty `$ARGUMENTS` | Prompt user: "Please describe what you want to plan" |
| Missing required field | Apply intelligent default or ask user |
| Validation failure | Log issue and attempt resolution |

## Documentation Levels (Progressive Enhancement)

| Level | Required Files | LOC Guidance | Use Case |
|-------|---------------|--------------|----------|
| **Level 1 (Baseline)** | spec.md + plan.md + tasks.md | <100 LOC | Simple changes, bug fixes |
| **Level 2 (Verification)** | Level 1 + checklist.md | 100-499 LOC | Medium features, refactoring |
| **Level 3 (Full)** | Level 2 + decision-record.md | >=500 LOC | Complex features, architecture changes |

**Note:** LOC thresholds are soft guidance. Choose level based on complexity and risk.

**Important:** For Level 2+, `checklist.md` will be created during planning and is MANDATORY for verification during the subsequent `/spec_kit:implement` phase. The AI must actively use it to verify all work before claiming completion.

## Templates Used

**Core Templates:**
- `.opencode/speckit/templates/spec.md` (Level 1+)
- `.opencode/speckit/templates/plan.md` (Level 1+)
- `.opencode/speckit/templates/tasks.md` (Level 1+ - created during implementation)
- `.opencode/speckit/templates/checklist.md` (Level 2+)
- `.opencode/speckit/templates/decision-record.md` (Level 3)

**Research Templates (optional):**
- `.opencode/speckit/templates/research.md` (any level)
- `.opencode/speckit/templates/research-spike.md` (any level)

**Utility Templates:**
- `.opencode/speckit/templates/handover.md` (any level)
- `.opencode/speckit/templates/debug-delegation.md` (any level)

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
- Run /spec_kit:implement:auto or /spec_kit:implement:confirm to begin implementation

STATUS=OK PATH=specs/NNN-short-name/
```

## Examples

**Example 1: Simple Planning (autonomous)**
```
/spec_kit:plan:auto Add dark mode toggle to the settings page
```

**Example 2: Complex Planning (interactive)**
```
/spec_kit:plan:confirm Redesign the checkout flow with multi-step form and payment integration
```

**Example 3: With Context**
```
/spec_kit:plan "Build analytics dashboard" tech stack: React, Chart.js, existing API
```

---

## Notes

### Checklist Creation for Implementation Verification (Level 2+)

When creating `checklist.md` for Level 2+ projects, structure items for mandatory verification during implementation:

1. **Priority Levels** - Assign P0/P1/P2 to each item:
   - P0 (Critical): BLOCKERS - implementation cannot complete without these
   - P1 (High): Required - must complete or get explicit user deferral approval
   - P2 (Medium): Optional - can defer with documentation
2. **Verification Format** - Use checkbox format with evidence fields:
   ```
   - [ ] CHK001 [P0] Description | Evidence: [to be filled during implementation]
   ```
3. **Implementation Contract** - The `/spec_kit:implement` workflow MUST:
   - Load and verify each checklist item before claiming completion
   - Mark items `[x]` with evidence (links, test output, file references)
   - Block completion until all P0/P1 items are verified

- **Mode Behaviors:**
  - **Autonomous (`:auto`)**: Executes all steps without user approval gates. Self-validates at each checkpoint. Makes informed decisions based on best judgment. Documents all significant decisions.
  - **Interactive (`:confirm`)**: Pauses after each step for user approval. Presents options: Approve, Review Details, Modify, Skip, Abort. Allows course correction throughout planning.

- **Parallel Sub-Agent Dispatch (AGENTS.md Compliant):**
  - Eligible phases (Specification) can dispatch parallel sub-agents for faster execution
  - Complexity scoring evaluates: domain count (35%), file count (25%), LOC estimate (15%), parallel opportunity (20%), task type (5%)
  - **Dispatch Behavior:**
    - <20% complexity → Execute directly (no parallel agents)
    - ≥20% + 2 domains → ALWAYS ask user via AskUserQuestion
    - No auto-dispatch: Per AGENTS.md Section 1, always ask before parallel dispatch
  - **Exception:** Step 6 (Planning) uses 4-agent parallel exploration automatically
    - This is the core planning feature - user chose a planning workflow
  - **Session Preference:** User's choice persists for 1 hour
  - **Override Phrases:** "proceed directly", "use parallel agents", "auto-decide"

- **Integration:**
  - Works with spec folder system for documentation
  - Pairs with `/spec_kit:implement` for execution phase
  - Context saved via workflows-save-context skill
