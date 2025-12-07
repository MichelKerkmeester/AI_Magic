---
description: Planning workflow (7 steps) - spec through plan only, no implementation. Supports :auto and :confirm modes
argument-hint: "[feature-description] [:auto|:confirm]"
allowed-tools: Read, Write, Edit, Bash, Grep, Glob, Task, AskUserQuestion
---

# 🚨 MANDATORY GATES - BLOCKING ENFORCEMENT

**These gates MUST be passed sequentially. Each gate BLOCKS until complete. You CANNOT proceed to the workflow until ALL gates show ✅ PASSED or ⏭️ N/A.**

---

## 🔒 GATE 0: Input Validation

**STATUS: ☐ BLOCKED**

```
EXECUTE THIS CHECK FIRST:

├─ IF $ARGUMENTS is empty, undefined, or whitespace-only (ignoring :auto/:confirm flags):
│   │
│   ├─ ASK user: "What feature would you like to plan?"
│   ├─ WAIT for user response (DO NOT PROCEED)
│   ├─ Store response as: feature_description
│   └─ SET STATUS: ✅ PASSED
│
└─ IF $ARGUMENTS contains content:
    ├─ Store as: feature_description
    └─ SET STATUS: ✅ PASSED

⛔ HARD STOP: DO NOT read past this gate until STATUS = ✅ PASSED
⛔ NEVER infer features from context, screenshots, or conversation history
```

**Gate 0 Output:** `feature_description = ________________`

---

## 🔒 GATE 1: Spec Folder Selection

**STATUS: ☐ BLOCKED**

```
EXECUTE AFTER GATE 0 PASSES:

1. Search for related spec folders:
   $ ls -d specs/*/ 2>/dev/null | tail -10

2. ASK user with these EXACT options:
   ┌────────────────────────────────────────────────────────────┐
   │ "Where should this plan be documented?"                    │
   │                                                            │
   │ A) Use existing spec folder: [suggest if related found]    │
   │ B) Create new spec folder: specs/[NNN]-[feature-slug]/     │
   │ C) Update related spec: [if partial match found]           │
   │ D) Skip documentation (no persistent artifacts)            │
   └────────────────────────────────────────────────────────────┘

3. WAIT for explicit user choice (A, B, C, or D)

4. Store results:
   - spec_choice = [A/B/C/D]
   - spec_path = [path or null if D]

5. SET STATUS: ✅ PASSED

⛔ HARD STOP: DO NOT proceed until user explicitly selects A, B, C, or D
⛔ NEVER auto-create spec folders without user confirmation
⛔ NEVER assume or infer the user's choice
```

**Gate 1 Output:** `spec_choice = ___` | `spec_path = ________________`

---

## 🔒 GATE 2: Memory Context Loading

**STATUS: ☐ BLOCKED / ☐ N/A**

```
EXECUTE AFTER GATE 1 PASSES:

CHECK spec_choice value:

├─ IF spec_choice == D (Skip):
│   └─ SET STATUS: ⏭️ N/A (no spec folder, no memory)
│
├─ IF spec_choice == B (Create new):
│   └─ SET STATUS: ⏭️ N/A (new folder has no memory)
│
└─ IF spec_choice == A or C (Use existing):
    │
    ├─ Check: Does spec_path/memory/ exist AND contain files?
    │
    ├─ IF memory/ is empty or missing:
    │   └─ SET STATUS: ⏭️ N/A (no memory to load)
    │
    └─ IF memory/ has files:
        │
        ├─ ASK user:
        │   ┌────────────────────────────────────────────────────┐
        │   │ "Load previous context from this spec folder?"     │
        │   │                                                    │
        │   │ A) Load most recent memory file (quick refresh)    │
        │   │ B) Load all recent files, up to 3 (comprehensive)  │
        │   │ C) List all files and select specific              │
        │   │ D) Skip (start fresh, no context)                  │
        │   └────────────────────────────────────────────────────┘
        │
        ├─ WAIT for user response
        ├─ Execute loading based on choice (use Read tool)
        ├─ Acknowledge loaded context briefly
        └─ SET STATUS: ✅ PASSED

⛔ HARD STOP: DO NOT proceed until STATUS = ✅ PASSED or ⏭️ N/A
```

**Gate 2 Output:** `memory_loaded = [yes/no]` | `context_summary = ________________`

---

## ✅ GATE STATUS VERIFICATION

**Before continuing to the workflow, verify ALL gates:**

| Gate | Required Status | Your Status | Output Value |
|------|-----------------|-------------|--------------|
| GATE 0: Input | ✅ PASSED | ______ | feature_description: ______ |
| GATE 1: Spec Folder | ✅ PASSED | ______ | spec_choice: ___ / spec_path: ______ |
| GATE 2: Memory | ✅ PASSED or ⏭️ N/A | ______ | memory_loaded: ______ |

```
VERIFICATION CHECK:
├─ ALL gates show ✅ PASSED or ⏭️ N/A?
│   ├─ YES → Proceed to "# SpecKit Plan" section below
│   └─ NO  → STOP and complete the blocked gate
```

---

## ⚠️ VIOLATION SELF-DETECTION

**You are IN VIOLATION if you:**
- Started reading the workflow section before all gates passed
- Proceeded without asking user for feature description (Gate 0)
- Auto-created or assumed a spec folder without A/B/C/D choice (Gate 1)
- Skipped memory prompt when using existing folder with memory files (Gate 2)
- Inferred feature from context instead of explicit user input

**VIOLATION RECOVERY PROTOCOL:**
```
1. STOP immediately - do not continue current action
2. STATE: "I violated GATE [X] by [specific action]. Correcting now."
3. RETURN to the violated gate
4. COMPLETE the gate properly (ask user, wait for response)
5. RESUME only after all gates pass verification
```

---
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

#### Step 1.3: Verify Gates Passed

**Confirm all mandatory gates from the header were completed:**

| Gate | Status |
|------|--------|
| GATE 0: Input Validation | ✅ feature_description captured |
| GATE 1: Spec Folder Selection | ✅ spec_choice + spec_path set |
| GATE 2: Memory Context | ✅ PASSED or ⏭️ N/A |

**If any gate is incomplete, STOP and return to complete it before continuing.**

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
