---
description: Full end-to-end SpecKit workflow (12 steps) - supports :auto and :confirm modes
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
│   ├─ ASK user: "What feature would you like to build?"
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

## 🔒 GATE 1: SPEC FOLDER SELECTION

**STATUS: ☐ BLOCKED**

```
EXECUTE AFTER GATE 0 PASSES:

1. Search for related spec folders:
   $ ls -d specs/*/ 2>/dev/null | tail -10

2. ASK user with these EXACT options:
   ┌────────────────────────────────────────────────────────────┐
   │ "Where should this feature be documented?"                 │
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
└─ IF NO mode suffix detected (plain /spec_kit:complete):
  │
  ├─ ASK user:
  │   ┌────────────────────────────────────────────────────────────┐
  │   │ "How would you like to execute this workflow?"              │
  │   │                                                            │
  │   │ A) Autonomous - Execute all 12 steps without approval      │
  │   │    gates. Best for well-defined tasks with clear            │
  │   │    requirements.                                           │
  │   │                                                            │
  │   │ B) Interactive - Pause at each step for approval. Best     │
  │   │    for complex features where you want control over        │
  │   │    decisions.                                              │
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
│   ├─ YES → Proceed to "# SpecKit Complete" section below
│   └─ NO  → STOP and complete the blocked gate
```

---

## ⚠️ VIOLATION SELF-DETECTION (BLOCKING)

**YOU ARE IN VIOLATION IF YOU:**

**Gate Violations:**
- Started reading the workflow section before all gates passed
- Proceeded without asking user for feature description (Gate 0)
- Auto-created or assumed a spec folder without A/B/C/D choice (Gate 1)
- Skipped memory prompt when using existing folder with memory files (Gate 2)
- **Started workflow execution without asking user for A/B mode choice (Gate 3) when no :auto/:confirm suffix was present**
- Inferred feature from context instead of explicit user input
- **Auto-selected autonomous or interactive mode without explicit user choice or command suffix**

**Workflow Violations (Steps 1-12):**
- **Skipped Phase Gate and jumped directly to implementation code**
- **Started writing code before completing Steps 1-7 (Planning Phase)**
- **Did not mark tasks [x] in tasks.md during Step 10**
- **Did not create implementation-summary.md in Step 11**
- **Claimed "complete" or "done" without verifying all 12 steps executed**

**VIOLATION RECOVERY PROTOCOL:**
```
FOR GATE VIOLATIONS:
1. STOP immediately - do not continue current action
2. STATE: "I violated GATE [X] by [specific action]. Correcting now."
3. RETURN to the violated gate
4. COMPLETE the gate properly (ask user, wait for response)
5. RESUME only after all gates pass verification

FOR WORKFLOW VIOLATIONS:
1. STOP immediately
2. STATE: "I skipped STEP [X] by [specific action]. Correcting now."
3. RETURN to the skipped step
4. COMPLETE all activities for that step
5. VERIFY outputs exist
6. MARK step ✅ in tracking table
7. CONTINUE to next step in sequence
```

---

# 📊 WORKFLOW EXECUTION (12 STEPS) - MANDATORY TRACKING

**⛔ ENFORCEMENT RULE:** Execute steps IN ORDER (1→12). Mark each step ✅ ONLY after completing ALL its activities and verifying outputs. DO NOT SKIP STEPS.

---

## PHASE A: PLANNING (Steps 1-7)

| STEP | NAME              | STATUS | REQUIRED OUTPUT           | VERIFICATION                          |
| ---- | ----------------- | ------ | ------------------------- | ------------------------------------- |
| 1    | Request Analysis  | ☐      | requirement_summary       | Scope defined                         |
| 2    | Pre-Work Review   | ☐      | coding_standards_summary  | AGENTS.md reviewed                    |
| 3    | Specification     | ☐      | `spec.md` created         | File exists, no [NEEDS CLARIFICATION] |
| 4    | Clarification     | ☐      | updated `spec.md`         | Ambiguities resolved                  |
| 5    | Quality Checklist | ☐      | `checklist.md` (Level 2+) | Checklist items defined               |
| 6    | Planning          | ☐      | `plan.md` created         | Technical approach documented         |
| 7    | Task Breakdown    | ☐      | `tasks.md` created        | All tasks listed with IDs             |

---

## 🔒 PHASE GATE: PLANNING → IMPLEMENTATION

**STATUS: ☐ BLOCKED**

```
BEFORE proceeding to Implementation Phase (Steps 8-12):

VERIFY all planning artifacts exist and are complete:
├─ [ ] spec.md exists in spec_path
├─ [ ] spec.md has NO [NEEDS CLARIFICATION] markers remaining
├─ [ ] plan.md exists in spec_path
├─ [ ] plan.md has technical approach defined
├─ [ ] tasks.md exists in spec_path
├─ [ ] tasks.md has all implementation tasks listed with T### IDs

IF any artifact missing or incomplete:
└─ STOP → Return to appropriate step (3, 6, or 7) → Complete it → Return here

WHEN all artifacts verified:
└─ SET PHASE GATE STATUS: ✅ PASSED → Proceed to Step 8

⛔ HARD STOP: DO NOT start Step 8 until Phase Gate shows ✅ PASSED
⛔ NEVER skip directly to writing implementation code
⛔ NEVER assume "I know what to build" - follow the process
```

---

## PHASE B: IMPLEMENTATION (Steps 8-12)

| STEP | NAME                 | STATUS | REQUIRED OUTPUT                   | VERIFICATION                              |
| ---- | -------------------- | ------ | --------------------------------- | ----------------------------------------- |
| 8    | Analysis             | ☐      | consistency_report                | Artifacts cross-checked                   |
| 9    | Implementation Check | ☐      | prerequisites_verified            | Ready to implement                        |
| 10   | Development          | ☐      | code changes + tasks marked `[x]` | **ALL tasks in tasks.md marked complete** |
| 11   | Completion           | ☐      | `implementation-summary.md`       | **Summary file created**                  |
| 12   | Save Context         | ☐      | `memory/*.md`                     | Context preserved                         |

---

## ⛔ CRITICAL ENFORCEMENT RULES

```
STEP 10 (Development) REQUIREMENTS:
├─ MUST load tasks.md and execute tasks in order
├─ MUST mark each task [x] in tasks.md when completed
├─ MUST NOT claim "development complete" until ALL tasks marked [x]
└─ MUST test code changes before marking complete

STEP 11 (Completion) REQUIREMENTS:
├─ MUST verify all tasks in tasks.md show [x]
├─ MUST create implementation-summary.md with:
│   ├─ Files modified/created
│   ├─ Verification steps taken
│   ├─ Deviations from plan (if any)
│   └─ Browser testing results
└─ MUST NOT skip this step

STEP 12 (Save Context) REQUIREMENTS:
├─ MUST save session context to memory/ folder
└─ MUST include decisions made and implementation details
```

---

## ⚠️ WORKFLOW VIOLATION DETECTION

**YOU ARE IN VIOLATION IF YOU:**
- Started writing implementation code before Step 8
- Skipped Steps 8-9 and jumped directly to coding
- Did not mark tasks `[x]` in tasks.md during Step 10
- Did not create implementation-summary.md in Step 11
- Claimed "complete" without all 12 steps showing ✅

**WORKFLOW VIOLATION RECOVERY:**
```
1. STOP current action
2. STATE: "I skipped Step [X]. Correcting now."
3. Return to the skipped step
4. Complete ALL activities for that step
5. Mark step ✅ in tracking table
6. Continue to next step
```

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

## 1. 📋 PURPOSE

Run the full 12-step SpecKit workflow: specification, clarification, planning, task breakdown, implementation, and context saving. This is the comprehensive workflow for feature development with full documentation trail.

---

## 2. 📝 CONTRACT

**Inputs:** `$ARGUMENTS` — Feature description with optional parameters (branch, scope, context)
**Outputs:** Complete spec folder with all artifacts + `STATUS=<OK|FAIL|CANCELLED>`

### User Input

```text
$ARGUMENTS
```

## 3. 📊 WORKFLOW-OVERVIEW

| Step | Name                 | Purpose                                                                      | Outputs                    |
| ---- | -------------------- | ---------------------------------------------------------------------------- | -------------------------- |
| 1    | Request Analysis     | Analyze inputs, define scope                                                 | requirement_summary        |
| 2    | Pre-Work Review      | Review AGENTS.md, standards                                                  | coding_standards_summary   |
| 3    | Specification        | Create spec.md                                                               | spec.md, feature branch    |
| 4    | Clarification        | Resolve ambiguities                                                          | updated spec.md            |
| 5    | Quality Checklist    | Generate validation checklist (ACTIVELY USED for verification at completion) | checklist.md |
| 6    | Planning             | Create technical plan                                                        | plan.md, research.md       |
| 7    | Task Breakdown       | Break into tasks                                                             | tasks.md                   |
| 8    | Analysis             | Verify consistency                                                           | consistency_report         |
| 9    | Implementation Check | Verify prerequisites                                                         | greenlight                 |
| 10   | Development          | Execute implementation                                                       | code changes               |
| 11   | Completion           | Generate summary                                                             | implementation-summary.md  |
| 12   | Save Context         | Preserve conversation                                                        | memory/*.md                |

---

## 4. ⚡ INSTRUCTIONS

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
| `scope`       | File paths, glob patterns like `src/**/*.js`, "files:"          | Default to specs/**                                |

**IMPORTANT:** The `spec_folder` field MUST come from the user's explicit choice in GATE 1.
Do NOT auto-create or infer - the user MUST have selected Option A, B, C, or D.

**Transformation Process**:

1. **Extract explicit fields**: Scan for labeled patterns ("branch:", "files:", etc.)
2. **Infer implicit fields**: Extract context clues from natural language
3. **Apply defaults**: Fill remaining fields with intelligent defaults (EXCEPT spec_folder - use Step 1.3 value)
4. **Validate required**: Ensure `request` field has substantive content

**Example Transformation**:

Raw input:
```
Add user authentication with OAuth2 to the dashboard.
Use Passport.js for the backend. Staging: https://staging.example.com
Files in src/auth/ and src/middleware/
```

Transformed (after user selected Option B in GATE 1):
```yaml
user_inputs:
  git_branch: ""  # Auto-create
  spec_folder: "specs/045-oauth-auth/"  # FROM USER CHOICE IN GATE 1
  context: "Technical stack: Passport.js for OAuth2 implementation"
  issues: ""  # Discover during workflow
  request: "Add user authentication with OAuth2 to the dashboard"
  environment: "https://staging.example.com"
  scope: |
    src/auth/**
    src/middleware/**
```

#### Step 1.3: Load & Execute Workflow Prompt

Based on `execution_mode` from GATE 3:

- **AUTONOMOUS**: Load and execute `.opencode/command/spec_kit/assets/spec_kit_complete_auto.yaml`
- **INTERACTIVE**: Load and execute `.opencode/command/spec_kit/assets/spec_kit_complete_confirm.yaml`

**Note:** The mode was already determined in GATE 3. Do NOT re-ask the user here.

### Phase 2: Workflow Execution

Execute the 12 steps defined in Workflow Overview. Each step produces artifacts that feed into subsequent steps. See prompt files for detailed step-by-step instructions.

---

## 5. 📁 CONTEXT-LOADING

When resuming work in an existing spec folder, the system will prompt to load prior session memory:
- **A)** Load most recent memory file (quick context refresh)
- **B)** Load all recent files (up to 3) (comprehensive context)
- **C)** List all files and select specific (historical search)
- **D)** Skip (start fresh, no context)

See AGENTS.md Section 2 for full memory file handling details.

## 6. 🔧 FAILURE-RECOVERY

| Failure Type                     | Recovery Action                                      |
| -------------------------------- | ---------------------------------------------------- |
| Step validation fails            | Review requirements, ask clarifying questions, retry |
| User rejects approach            | Present alternatives, modify plan, document decision |
| Tests fail during implementation | Debug, fix, re-run before marking complete           |
| Prerequisites insufficient       | Return to prior workflow phase (planning)            |
| Environment unavailable          | Skip browser testing, document limitation            |

## 7. ⚠️ ERROR-HANDLING

| Condition              | Action                                                     |
| ---------------------- | ---------------------------------------------------------- |
| Empty `$ARGUMENTS`     | Prompt user: "Please describe what you want to accomplish" |
| Missing required field | Apply intelligent default or ask user                      |
| Prerequisites missing  | Guide user to prerequisite commands                        |
| Validation failure     | Log issue and attempt resolution or escalate               |

## 8. 📊 DOCUMENTATION-LEVELS

| Level                      | Required Files               | LOC Guidance | Use Case                               |
| -------------------------- | ---------------------------- | ------------ | -------------------------------------- |
| **Level 1 (Baseline)**     | spec.md + plan.md + tasks.md | <100 LOC     | Simple changes, bug fixes              |
| **Level 2 (Verification)** | Level 1 + checklist.md       | 100-499 LOC  | Medium features, refactoring           |
| **Level 3 (Full)**         | Level 2 + decision-record.md | >=500 LOC    | Complex features, architecture changes |

**Note:** LOC thresholds are soft guidance. Choose level based on complexity and risk.

**Important:** For Level 2+, `checklist.md` is MANDATORY for verification before any completion claims. The AI must actively use it to verify work.

## 9. 📁 TEMPLATES-USED

**Core Templates:**
- `.opencode/speckit/templates/spec.md` (Level 1+)
- `.opencode/speckit/templates/plan.md` (Level 1+)
- `.opencode/speckit/templates/tasks.md` (Level 1+)
- `.opencode/speckit/templates/checklist.md` (Level 2+)
- `.opencode/speckit/templates/decision-record.md` (Level 3)

**Research Templates (optional):**
- `.opencode/speckit/templates/research.md` (any level)
- `.opencode/speckit/templates/research-spike.md` (any level)

**Utility Templates:**
- `.opencode/speckit/templates/handover.md` (any level)
- `.opencode/speckit/templates/debug-delegation.md` (any level)

## 10. 📊 COMPLETION-REPORT

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
- memory/[DD-MM-YY_HH-MM]__session.md (context saved)

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

## 11. 🔍 EXAMPLES

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

## 12. 📌 NOTES

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

- **Parallel Sub-Agent Dispatch (AGENTS.md Compliant):**
  - Eligible phases (Specification, Analysis, Development) can dispatch parallel sub-agents for faster execution
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
  - Plans can feed into `/spec_kit:implement` workflow
  - Context saved via workflows-memory skill
