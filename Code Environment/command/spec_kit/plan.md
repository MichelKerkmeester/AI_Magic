---
description: Planning workflow (7 steps) - spec through plan only, no implementation. Supports :auto and :confirm modes
argument-hint: "[feature-description] [:auto|:confirm]"
allowed-tools: Read, Write, Edit, Bash, Grep, Glob, Task
---

# 🚨 MANDATORY GATES - BLOCKING ENFORCEMENT

**These gates MUST be passed sequentially. Each gate BLOCKS until complete. You CANNOT proceed to the workflow until ALL gates show ✅ PASSED or ⏭️ N/A.**

---

## 🔒 GATE 0: INPUT VALIDATION

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

## 🔒 GATE 1: SPEC FOLDER VALIDATION

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
   │ B) Create new spec folder (Level 1+)                       │
   │ C) Update related spec: [if partial match found]           │
   │ D) Skip documentation (creates .spec-skip marker)          │
   └────────────────────────────────────────────────────────────┘

3. WAIT for explicit user choice (A, B, C, or D)

4. Store results:
   - spec_choice = [A/B/C/D]
   - spec_path = [path or null if D]

5. SET STATUS: ✅ PASSED

6. UPDATE SPEC MARKER (after status passes):
   ├─ IF spec_choice IN [A, B, C]:
   │   ├─ Write spec_path to project root marker file
   │   │   Command: echo "$spec_path" > .spec-active
   │   └─ This enables /spec_kit:resume to detect the active session
   │
   └─ IF spec_choice == D (Skip):
       └─ Clean up any existing marker: rm -f .spec-active

⛔ HARD STOP: DO NOT proceed until user explicitly selects A, B, C, or D
⛔ NEVER auto-create spec folders without user confirmation
⛔ NEVER assume or infer the user's choice
```

**Gate 1 Output:** `spec_choice = ___` | `spec_path = ________________` | `.spec-active = [updated/cleared]`

---

## 🔒 GATE 2: MEMORY CONTEXT LOADING

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
        │   │ A) Load most recent memory file (quick refresh)     │
        │   │ B) Load all recent files, up to 3 (comprehensive)   │
        │   │ C) List all files and select specific                │
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

## 🔒 GATE 3: EXECUTION MODE SELECTION

**STATUS: ☐ BLOCKED**

```
EXECUTE AFTER GATE 2 PASSES (or N/A):

1. CHECK command invocation for mode suffix:

├─ IF command contains ":auto" suffix:
│   ├─ execution_mode = "AUTONOMOUS"
│   └─ SET STATUS: ✅ PASSED
│
├─ IF command contains ":confirm" suffix:
│   ├─ execution_mode = "INTERACTIVE"
│   └─ SET STATUS: ✅ PASSED
│
└─ IF NO mode suffix detected (plain /spec_kit:plan):
    │
    ├─ ASK user:
    │   ┌────────────────────────────────────────────────────────────┐
    │   │ "How would you like to execute this planning workflow?"    │
    │   │                                                            │
    │   │ A) Autonomous - Execute all 7 steps without approval       │
    │   │    gates. Best for straightforward planning.               │
    │   │                                                            │
    │   │ B) Interactive - Pause at each step for approval. Best     │
    │   │    for complex features needing discussion.                │
    │   └────────────────────────────────────────────────────────────┘
    │
    ├─ WAIT for explicit user choice (A or B)
    │
    ├─ IF user selects A:
    │   └─ execution_mode = "AUTONOMOUS"
    │
    ├─ IF user selects B:
    │   └─ execution_mode = "INTERACTIVE"
    │
    └─ SET STATUS: ✅ PASSED

⛔ HARD STOP: DO NOT proceed to workflow execution until user explicitly selects A or B
⛔ NEVER auto-select a mode without explicit suffix or user choice
⛔ NEVER assume user preference from context or previous sessions
```

**Gate 3 Output:** `execution_mode = [AUTONOMOUS/INTERACTIVE]`

---

## ✅ GATE STATUS VERIFICATION (BLOCKING)

**Before continuing to the workflow, verify ALL gates:**

| GATE                   | REQUIRED STATUS   | YOUR STATUS | OUTPUT VALUE                         |
| ---------------------- | ----------------- | ----------- | ------------------------------------ |
| GATE 0: INPUT          | ✅ PASSED          | ______      | feature_description: ______          |
| GATE 1: SPEC FOLDER    | ✅ PASSED          | ______      | spec_choice: ___ / spec_path: ______ |
| GATE 2: MEMORY         | ✅ PASSED or ⏭️ N/A | ______      | memory_loaded: ______                |
| GATE 3: EXECUTION MODE | ✅ PASSED          | ______      | execution_mode: ______               |

```
VERIFICATION CHECK:
├─ ALL gates show ✅ PASSED or ⏭️ N/A?
│   ├─ YES → Proceed to "# SpecKit Plan" section below
│   └─ NO  → STOP and complete the blocked gate
```

---

## ⚠️ VIOLATION SELF-DETECTION (BLOCKING)

**YOU ARE IN VIOLATION IF YOU:**
- Started reading the workflow section before all gates passed
- Proceeded without asking user for feature description (Gate 0)
- Auto-created or assumed a spec folder without A/B/C/D choice (Gate 1)
- Skipped memory prompt when using existing folder with memory files (Gate 2)
- **Started workflow execution without asking user for A/B mode choice (Gate 3) when no :auto/:confirm suffix was present**
- Inferred feature from context instead of explicit user input
- **Auto-selected autonomous or interactive mode without explicit user choice or command suffix**

**VIOLATION RECOVERY PROTOCOL:**
```
1. STOP immediately - do not continue current action
2. STATE: "I violated GATE [X] by [specific action]. Correcting now."
3. RETURN to the violated gate
4. COMPLETE the gate properly (ask user, wait for response)
5. RESUME only after all gates pass verification
```

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

## 1. 📋 PURPOSE

Run the 7-step planning workflow: specification, clarification, quality checklist, and technical planning. Creates spec.md, plan.md, and checklists without proceeding to implementation. Use when planning needs review before coding.

---

## 2. 📝 CONTRACT

**Inputs:** `$ARGUMENTS` — Feature description with optional parameters (branch, scope, context)
**Outputs:** Spec folder with planning artifacts (spec.md, plan.md, checklists/) + `STATUS=<OK|FAIL|CANCELLED>`

---

## 3. 🔍 USER INPUT

```text
$ARGUMENTS
```

---

## 4. 📊 WORKFLOW OVERVIEW (7 STEPS)

| Step | Name              | Purpose                                                                                      | Outputs                      |
| ---- | ----------------- | -------------------------------------------------------------------------------------------- | ---------------------------- |
| 1    | Request Analysis  | Analyze inputs, define scope                                                                 | requirement_summary          |
| 2    | Pre-Work Review   | Review AGENTS.md, standards                                                                  | coding_standards_summary     |
| 3    | Specification     | Create spec.md                                                                               | spec.md, feature branch      |
| 4    | Clarification     | Resolve ambiguities                                                                          | updated spec.md              |
| 5    | Quality Checklist | Generate validation checklist (will be ACTIVELY USED for verification during implementation) | checklist.md                 |
| 6    | Planning          | Create technical plan                                                                        | plan.md, planning-summary.md |
| 7    | Save Context      | Preserve conversation                                                                        | memory/*.md                  |

---

## 5. ⚡ INSTRUCTIONS

### Phase 1: Gate Verification & Input Parsing

#### Step 1.1: Verify All Gates Passed

**⚠️ CRITICAL CHECKPOINT: ALL mandatory gates must be complete before this phase.**

Confirm you have these values from the gates:
- `feature_description` from GATE 0
- `spec_choice` and `spec_path` from GATE 1
- `memory_loaded` status from GATE 2
- `execution_mode` from GATE 3 ← **THIS IS REQUIRED**

**If ANY gate is incomplete, STOP and return to the MANDATORY GATES section.**

```
Gate Reference (from MANDATORY GATES section):
├─ GATE 3 determines execution_mode via:
│   ├─ :auto suffix → AUTONOMOUS
│   ├─ :confirm suffix → INTERACTIVE
│   └─ No suffix → User must choose A or B
│
└─ execution_mode MUST be set before proceeding
```

#### Step 1.2: Transform Raw Input

Parse the feature_description (from GATE 0) and transform into structured user_inputs fields.

**Field Extraction Rules**:

| Field         | Pattern Detection                                               | Default If Empty                                   |
| ------------- | --------------------------------------------------------------- | -------------------------------------------------- |
| `git_branch`  | "branch: X", "on branch X", "feature/X"                         | Auto-create feature-{NNN}                          |
| `spec_folder` | "specs/NNN", "spec folder X", "in specs/X"                      | **USE VALUE FROM GATE 1** (user's explicit choice) |
| `context`     | "using X", "with Y", "tech stack:", "constraints:"              | Infer from request                                 |
| `issues`      | "issue:", "bug:", "problem:", "error:", "question:", "unknown:" | Discover during workflow                           |
| `request`     | Primary task description (REQUIRED)                             | ERROR if completely empty                          |
| `environment` | URLs starting with http(s)://, "staging:", "production:"        | Skip browser testing                               |
| `scope`       | File paths, glob patterns, "files:"                             | Default to specs/**                                |

**IMPORTANT:** The `spec_folder` field MUST come from the user's explicit choice in GATE 1.
Do NOT auto-create or infer - the user MUST have selected Option A, B, C, or D.

#### Step 1.3: Load & Execute Workflow Prompt

Based on `execution_mode` from GATE 3:

- **AUTONOMOUS**: Load and execute `.opencode/command/spec_kit/assets/spec_kit_plan_auto.yaml`
- **INTERACTIVE**: Load and execute `.opencode/command/spec_kit/assets/spec_kit_plan_confirm.yaml`

**Note:** The mode was already determined in GATE 3. Do NOT re-ask the user here.

### Phase 2: Workflow Execution

Execute the 7 steps defined in Workflow Overview. Each step produces artifacts that feed into subsequent steps. See prompt files for detailed step-by-step instructions.

---

## 6. 🔀 KEY DIFFERENCES FROM /SPEC_KIT:COMPLETE

- **Terminates after planning** - Does not include task breakdown, analysis, or implementation
- **Outputs planning-summary.md** instead of implementation-summary.md
- **Next step guidance** - Recommends `/spec_kit:implement` when ready to build
- **Use case** - Planning phase separation, stakeholder review, feasibility analysis

---

## 7. 🔗 CONTEXT LOADING

When resuming work in an existing spec folder, the system will prompt to load prior session memory:
- **A)** Load most recent memory file (quick context refresh)
- **B)** Load all recent files (up to 3) (comprehensive context)
- **C)** List all files and select specific (historical search)
- **D)** Skip (start fresh, no context)

See AGENTS.md Section 2 for full memory file handling details.

---

## 8. 🔧 FAILURE RECOVERY

| Failure Type            | Recovery Action                                      |
| ----------------------- | ---------------------------------------------------- |
| Step validation fails   | Review requirements, ask clarifying questions, retry |
| User rejects approach   | Present alternatives, modify plan, document decision |
| Spec ambiguity persists | Document as assumption, add to risk matrix           |
| Environment unavailable | Skip browser testing, document limitation            |

---

## 9. ⚠️ ERROR HANDLING

| Condition              | Action                                               |
| ---------------------- | ---------------------------------------------------- |
| Empty `$ARGUMENTS`     | Prompt user: "Please describe what you want to plan" |
| Missing required field | Apply intelligent default or ask user                |
| Validation failure     | Log issue and attempt resolution                     |

---

## 10. 📁 DOCUMENTATION LEVELS (PROGRESSIVE ENHANCEMENT)

| Level                      | Required Files                           | LOC Guidance | Use Case                               |
| -------------------------- | ---------------------------------------- | ------------ | -------------------------------------- |
| **Level 1 (Baseline)**     | spec.md + plan.md (tasks.md in implement)| <100 LOC     | Simple changes, bug fixes              |
| **Level 2 (Verification)** | Level 1 + checklist.md                   | 100-499 LOC  | Medium features, refactoring           |
| **Level 3 (Full)**         | Level 2 + decision-record.md             | >=500 LOC    | Complex features, architecture changes |

**Note:** LOC thresholds are soft guidance. Choose level based on complexity and risk.

**Important:** This workflow creates `spec.md`, `plan.md`, and `checklist.md` (Level 2+). The `tasks.md` file is created during the subsequent `/spec_kit:implement` phase. Use `/spec_kit:complete` if you need all artifacts in one workflow.

**Important:** For Level 2+, `checklist.md` will be created during planning and is MANDATORY for verification during the subsequent `/spec_kit:implement` phase. The AI must actively use it to verify all work before claiming completion.

---

## 11. 📁 TEMPLATES USED

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

---

## 12. 📊 COMPLETION REPORT

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
- checklist.md (validation checklist)
- memory/[DD-MM-YY_HH-MM]__planning_session.md (context saved)

Next Steps:
- Review planning documentation
- Validate technical approach with stakeholders
- Run /spec_kit:implement:auto or /spec_kit:implement:confirm to begin implementation

STATUS=OK PATH=specs/NNN-short-name/
```

---

## 13. 🔍 EXAMPLES

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

## 14. 📌 NOTES

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
    - ≥20% + 2 domains → ALWAYS ask user
    - No auto-dispatch: Per AGENTS.md Section 1, always ask before parallel dispatch
  - **Exception:** Step 6 (Planning) uses 4-agent parallel exploration automatically
    - This is the core planning feature - user chose a planning workflow
  - **Session Preference:** User's choice persists for 1 hour
  - **Override Phrases:** "proceed directly", "use parallel agents", "auto-decide"

- **Integration:**
  - Works with spec folder system for documentation
  - Pairs with `/spec_kit:implement` for execution phase
  - Context saved via workflows-memory skill
