---
description: Full end-to-end SpecKit workflow (12 steps) - supports :auto and :confirm modes
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

## 🔒 GATE 1: Spec Folder Selection

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
   │ B) Create new spec folder: specs/[NNN]-[feature-slug]/     │
   │ C) Update related spec: [if partial match found]           │
   │ D) Skip documentation (WARNING: complete workflow produces │
   │    many artifacts - not recommended)                       │
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

| Gate                | Required Status   | Your Status | Output Value                         |
| ------------------- | ----------------- | ----------- | ------------------------------------ |
| GATE 0: Input       | ✅ PASSED          | ______      | feature_description: ______          |
| GATE 1: Spec Folder | ✅ PASSED          | ______      | spec_choice: ___ / spec_path: ______ |
| GATE 2: Memory      | ✅ PASSED or ⏭️ N/A | ______      | memory_loaded: ______                |

```
VERIFICATION CHECK:
├─ ALL gates show ✅ PASSED or ⏭️ N/A?
│   ├─ YES → Proceed to "# SpecKit Complete" section below
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

| Step | Name                 | Purpose                                                                      | Outputs                    |
| ---- | -------------------- | ---------------------------------------------------------------------------- | -------------------------- |
| 1    | Request Analysis     | Analyze inputs, define scope                                                 | requirement_summary        |
| 2    | Pre-Work Review      | Review AGENTS.md, standards                                                  | coding_standards_summary   |
| 3    | Specification        | Create spec.md                                                               | spec.md, feature branch    |
| 4    | Clarification        | Resolve ambiguities                                                          | updated spec.md            |
| 5    | Quality Checklist    | Generate validation checklist (ACTIVELY USED for verification at completion) | checklists/requirements.md |
| 6    | Planning             | Create technical plan                                                        | plan.md, research.md       |
| 7    | Task Breakdown       | Break into tasks                                                             | tasks.md                   |
| 8    | Analysis             | Verify consistency                                                           | consistency_report         |
| 9    | Implementation Check | Verify prerequisites                                                         | greenlight                 |
| 10   | Development          | Execute implementation                                                       | code changes               |
| 11   | Completion           | Generate summary                                                             | implementation-summary.md  |
| 12   | Save Context         | Preserve conversation                                                        | memory/*.md                |

---

## Instructions

### Phase 1: Mode Detection & Input Parsing

#### Step 1.1: Parse Mode Suffix

Detect execution mode from command invocation:

| Pattern                          | Mode        | Behavior                                      |
| -------------------------------- | ----------- | --------------------------------------------- |
| `/spec_kit:complete:auto`        | AUTONOMOUS  | Execute all steps without user approval gates |
| `/spec_kit:complete:confirm`     | INTERACTIVE | Pause at each step for user approval          |
| `/spec_kit:complete` (no suffix) | PROMPT      | Ask user to choose mode                       |

#### Step 1.2: Mode Selection (when no suffix detected)

If no `:auto` or `:confirm` suffix is present, use AskUserQuestion:

**Question**: "How would you like to execute this workflow?"

| Option | Mode        | Description                                                                                       |
| ------ | ----------- | ------------------------------------------------------------------------------------------------- |
| **A**  | Autonomous  | Execute all 12 steps without approval gates. Best for well-defined tasks with clear requirements. |
| **B**  | Interactive | Pause at each step for approval. Best for complex features where you want control over decisions. |

**Wait for user response before proceeding.**

#### Step 1.3: Verify Gates Passed

**⚠️ CHECKPOINT: Confirm all gates from the enforcement section above are complete.**

Before proceeding, verify you have these values from the gates:
- `feature_description` from GATE 0
- `spec_choice` and `spec_path` from GATE 1  
- `memory_loaded` status from GATE 2

**If ANY gate is incomplete, STOP and return to the MANDATORY GATES section.**

#### Step 1.4: Transform Raw Input

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

**IMPORTANT:** The `spec_folder` field MUST come from the user's explicit choice in Step 1.3.
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

Transformed (after user selected Option B in Step 1.3):
```yaml
user_inputs:
  git_branch: ""  # Auto-create
  spec_folder: "specs/045-oauth-auth/"  # FROM USER CHOICE IN STEP 1.3
  context: "Technical stack: Passport.js for OAuth2 implementation"
  issues: ""  # Discover during workflow
  request: "Add user authentication with OAuth2 to the dashboard"
  environment: "https://staging.example.com"
  scope: |
    src/auth/**
    src/middleware/**
```

#### Step 1.5: Load & Execute Workflow Prompt

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

| Failure Type                     | Recovery Action                                      |
| -------------------------------- | ---------------------------------------------------- |
| Step validation fails            | Review requirements, ask clarifying questions, retry |
| User rejects approach            | Present alternatives, modify plan, document decision |
| Tests fail during implementation | Debug, fix, re-run before marking complete           |
| Prerequisites insufficient       | Return to prior workflow phase (planning)            |
| Environment unavailable          | Skip browser testing, document limitation            |

## Error Handling

| Condition              | Action                                                     |
| ---------------------- | ---------------------------------------------------------- |
| Empty `$ARGUMENTS`     | Prompt user: "Please describe what you want to accomplish" |
| Missing required field | Apply intelligent default or ask user                      |
| Prerequisites missing  | Guide user to prerequisite commands                        |
| Validation failure     | Log issue and attempt resolution or escalate               |

## Documentation Levels (Progressive Enhancement)

| Level                      | Required Files               | LOC Guidance | Use Case                               |
| -------------------------- | ---------------------------- | ------------ | -------------------------------------- |
| **Level 1 (Baseline)**     | spec.md + plan.md + tasks.md | <100 LOC     | Simple changes, bug fixes              |
| **Level 2 (Verification)** | Level 1 + checklist.md       | 100-499 LOC  | Medium features, refactoring           |
| **Level 3 (Full)**         | Level 2 + decision-record.md | >=500 LOC    | Complex features, architecture changes |

**Note:** LOC thresholds are soft guidance. Choose level based on complexity and risk.

**Important:** For Level 2+, `checklist.md` is MANDATORY for verification before any completion claims. The AI must actively use it to verify work.

## Templates Used

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

- **Parallel Sub-Agent Dispatch (AGENTS.md Compliant):**
  - Eligible phases (Specification, Analysis, Development) can dispatch parallel sub-agents for faster execution
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
  - Plans can feed into `/spec_kit:implement` workflow
  - Context saved via workflows-save-context skill
