---
description: Create implementation plan with 4 parallel Opus 4.5 exploration agents (thorough, deep reasoning)
argument-hint: <task description> [mode:simple|mode:complex]
allowed-tools: Read, Write, Edit, Glob, Grep, Task, AskUserQuestion
agent: plan
model: opus
---

# Plan with Opus Agents

## ⛔ MANDATORY GATES - BLOCKING ENFORCEMENT

**YOU MUST COMPLETE ALL GATES BEFORE READING ANYTHING ELSE IN THIS FILE.**

These gates are BLOCKING - you cannot proceed past any gate until its condition is satisfied.

---

## 1. 🔒 GATE 0: INPUT VALIDATION - HARD STOP

**Check `$ARGUMENTS` for task description:**

```
IF $ARGUMENTS is empty, undefined, or contains only whitespace:
    ⛔ BLOCKED - Cannot proceed
    
    ACTION REQUIRED:
    1. Use AskUserQuestion tool with this exact question:
       question: "What would you like to plan?"
       options:
         - label: "Describe my task"
           description: "I'll provide a task description for planning"
    2. WAIT for user response
    3. Capture response as: task_description = ______
    4. Only THEN proceed to GATE 1

IF $ARGUMENTS contains a task description:
    ✅ Capture: task_description = $ARGUMENTS
    → Proceed to GATE 1
```

**GATE 0 Output:**
- `task_description = ______` (REQUIRED - must be filled before continuing)

---

## 2. 🔒 GATE 1: SPEC FOLDER SELECTION - HARD STOP

**You MUST ask user to select a spec folder option. DO NOT SKIP THIS QUESTION.**

```
⛔ BLOCKED until user explicitly selects A, B, C, or D

ACTION REQUIRED:
1. Use AskUserQuestion tool with these exact options:
   question: "Where should I create the planning documentation?"
   options:
     A) Use existing spec folder - [suggest relevant existing folder if found]
     B) Create new spec folder - specs/[###-suggested-name]/
     C) Update related spec - [suggest if related spec exists]
     D) Skip documentation - (not recommended for plan commands)

2. WAIT for user response
3. Capture: spec_folder_choice = ______ (A, B, C, or D)
4. Capture: spec_folder_path = ______
5. Only THEN proceed to GATE 2 (if applicable) or continue workflow
```

**GATE 1 Output:**
- `spec_folder_choice = ______` (REQUIRED - A, B, C, or D)
- `spec_folder_path = ______` (REQUIRED - actual path)

---

## 3. 🔒 GATE 2: MEMORY CONTEXT LOADING (CONDITIONAL)

**This gate only applies if user selected Option A or C in GATE 1.**

```
IF spec_folder_choice is A or C AND memory/ folder exists with files:
    → Auto-load the most recent memory file (DEFAULT)
    → Briefly confirm: "Loaded context from [filename]"
    → User can say "skip memory" or "fresh start" to bypass
    
IF spec_folder_choice is B or D:
    → Skip this gate (no memory to load)
    ✅ Proceed to workflow
```

---

## 4. ✅ GATE STATUS VERIFICATION

Before proceeding, verify all gates are passed:

| Gate   | Status | Required Output                                            |
| ------ | ------ | ---------------------------------------------------------- |
| GATE 0 | ⬜      | `task_description = ______`                                |
| GATE 1 | ⬜      | `spec_folder_choice = ______`, `spec_folder_path = ______` |
| GATE 2 | ⬜      | Memory loaded OR skipped (conditional)                     |

**All gates must show ✅ before continuing to the workflow below.**

---

## 5. ⚠️ VIOLATION SELF-DETECTION

If you notice yourself:
- Reading workflow steps before completing gates → ⛔ STOP, return to incomplete gate
- Assuming task description without explicit input → ⛔ STOP, return to GATE 0
- Skipping spec folder question → ⛔ STOP, return to GATE 1
- Proceeding without user's explicit choice → ⛔ STOP, ask the required question

**Recovery Protocol:** State "I need to complete the mandatory gates first" and return to the first incomplete gate.

---

## Implementation Plan (Claude Code + Opus 4.5 Agents)

**About this command:** This command creates SpecKit documentation using 4 parallel Opus 4.5 agents for thorough, deep-reasoning codebase exploration before any code changes. It requires a task description as input.

**Platform**: Claude Code only (uses Task tool with Claude agents)
**Agent Model**: Opus 4.5 (claude-opus-4-5-20251101) - Deep parallel analysis
**Orchestrator**: Opus 4.5 (claude-opus-4-5-20251101) - Task understanding, verification, synthesis
**SpecKit Aligned**: Creates Level 2+ documentation per AGENTS.md Section 2

---

## 6. 🔀 WHEN TO USE CC_OPUS VS CC_SONNET

| Variant            | Agent Model | Best For                                | Trade-off                      |
| ------------------ | ----------- | --------------------------------------- | ------------------------------ |
| cc_sonnet          | Sonnet      | Most planning tasks, quick exploration  | Fast & cheap, Opus verifies    |
| **cc_opus** (this) | Opus 4.5    | Complex architecture, critical features | Thorough but slower & costlier |

**When to use cc_opus (this command):**
- Complex architectural decisions where deep reasoning matters
- Large-scale refactors affecting many interconnected systems
- Critical features where thoroughness > speed (auth, payments, security)
- When exploration agents need to understand nuanced patterns
- Major system redesigns requiring comprehensive analysis

**When to use cc_sonnet instead:**
- Standard feature development
- Quick planning iterations
- Cost-sensitive projects
- When Opus verification (Phase 5) is sufficient

---

## 7. 📋 PURPOSE

Enter PLANNING MODE to create detailed, verified SpecKit documentation. This command:
1. Determines SpecKit documentation level (2 or 3) based on task complexity
2. Creates spec.md (requirements and user stories) + plan.md (technical approach)
3. Spawns **4 Opus 4.5 agents in parallel** for thorough codebase analysis
4. Opus orchestrator synthesizes and verifies findings
5. Optionally creates tasks.md for complex features (Level 3)
6. Requires user approval before implementation begins

**Documentation Levels (Progressive Enhancement):**
- **Level 1** (Baseline): spec.md + plan.md + tasks.md - All tasks get this minimum
- **Level 2** (Verification): Level 1 + checklist.md - Tasks needing verification
- **Level 3** (Full): Level 2 + decision-record.md + optional research-spike.md - Complex/architectural tasks

**LOC Thresholds (Soft Guidance):**
- <100 LOC suggests Level 1
- 100-499 LOC suggests Level 2
- >=500 LOC suggests Level 3

**Note**: All plan commands create AT LEAST Level 1 documentation (spec.md + plan.md + tasks.md) because running a plan command implies structured planning.

---

## 8. 📝 CONTRACT

**Inputs:** `$ARGUMENTS` — Task description (REQUIRED) + optional mode override
**Outputs:** SpecKit documentation at `specs/###-name/`:
  - `spec.md` - Feature specification and requirements (ALL levels)
  - `plan.md` - Technical implementation plan (ALL levels)
  - `tasks.md` - Task breakdown (ALL levels - part of baseline)
  - `checklist.md` - Verification checklist (Level 2+)
  - `decision-record.md` - Decision documentation (Level 3)
  - `research-spike.md` - Research documentation (Level 3, optional)
  - `STATUS=<OK|FAIL|CANCELLED>`

---

## 9. ⚡ INSTRUCTIONS

Execute the following workflow:

### Step 1: Parse Input & Validate Arguments

1. **CRITICAL: Check if $ARGUMENTS is empty or missing**
   - If `$ARGUMENTS` is empty, undefined, or contains only whitespace:
     - **STOP immediately** - do NOT continue
     - Use AskUserQuestion to prompt: "Please describe the task you want to plan"
     - Wait for user response before continuing
   - If `$ARGUMENTS` contains a task description: continue to item 2

2. **Extract task description from $ARGUMENTS**
3. **Check for explicit mode override:**
   - Pattern: `mode:simple` or `mode:complex` in arguments
   - If found: Use specified mode, skip auto-detection
   - If not found: Continue to Step 2 for auto-detection

### Step 1.5: Verify Gates Passed

Before continuing, confirm all gates are complete:

```
□ GATE 0: task_description captured from $ARGUMENTS or user response
□ GATE 1: spec_folder_choice explicitly selected (A/B/C/D)
□ GATE 2: Memory loaded (if applicable) or skipped

If ANY gate incomplete → STOP and return to that gate
```

### Step 2: Auto-Detect Planning Mode

If no mode override specified, analyze task complexity:

4. **Estimate LOC from task description:**
   - Keywords: "small" = 100, "feature" = 200, "refactor" = 300, "system" = 500, "redesign" = 800
   - File count indicators: "all", "multiple", "across" = +200 LOC
   - Default: 300 LOC if unclear

5. **Calculate complexity score (0-100%):**
   - Domain count (35%): code, docs, git, testing, devops
   - File count (25%): estimated files modified
   - LOC estimate (15%): normalized 0-1
   - Parallel opportunity (20%): can tasks run in parallel?
   - Task type (5%): implementation complexity

6. **Select mode:**
   ```
   IF loc_estimate < 500:
     mode = "simple"
   ELSE IF loc_estimate >= 500 OR iterations >= 4:
     mode = "complex"  # Falls back to simple until Phase 5 implemented
   ELSE:
     mode = "simple"
   ```

### Step 3: Load & Execute YAML Workflow

7. **Set agent model and read the appropriate YAML workflow:**

   **CRITICAL: Set AGENT_MODEL=opus before loading simple_mode.yaml**

   This command uses Opus 4.5 agents for thorough, deep-reasoning exploration.
   The simple_mode.yaml file is parameterized and will use whatever model is specified.

   Asset path: `.claude/commands/plan/assets/`

   Based on the mode selected in Step 2:

   - **SIMPLE mode** (<500 LOC):
     1. Set `AGENT_MODEL=opus`
     2. Use the Read tool to load `.claude/commands/plan/assets/simple_mode.yaml`
     3. Execute all instructions with model="opus" for exploration agents

   - **COMPLEX mode** (≥500 LOC): Use the Read tool to load `.claude/commands/plan/assets/complex_mode.yaml`. Note: Complex mode is a stub as of Phase 1.5 and will notify user to fall back to simple mode (using AGENT_MODEL=opus).

8. **YAML workflow executes automatically:**

   The loaded YAML prompt contains the complete 9-phase workflow (SpecKit aligned):
   - **Phase 0**: Documentation Level Detection (SpecKit Level 1, 2, or 3)
   - **Phases 1-3**: Task Understanding, Spec Folder Setup, Context Loading
   - **Phases 4-5**: Parallel Exploration (4 Opus 4.5 agents), Hypothesis Verification (Opus)
   - **Phase 6**: Document Creation (level-appropriate files)
   - **Phases 7-8**: User Review & Confirmation, Context Persistence

   All phases execute sequentially: 0 → 1 → 2 → 3 → 4 → 5 → 6 → 7 → 8

   **Expected outputs:**
   - Level 1: `specs/###-name/spec.md` + `plan.md` + `tasks.md`
   - Level 2: Level 1 + `checklist.md`
   - Level 3: Level 2 + `decision-record.md` (+ optional `research-spike.md`)


### Step 4: Monitor Progress

9. **Display phase progress to user:**
   ```
   Planning Mode Activated (Full Opus 4.5 Stack)

   Task: {task_description}
   Mode: {SIMPLE/COMPLEX} ({loc_estimate} LOC estimated)
   Documentation Level: {1, 2, or 3}
   Agent Model: Opus 4.5 (thorough exploration)

   Phase 0: Documentation Level Detection...
   Phase 1: Task Understanding & Session Initialization...
   Phase 2: Spec Folder Setup...
   Phase 3: Context Loading...
   Phase 4: Parallel Exploration (4 Opus 4.5 agents)...
   Phase 5: Hypothesis Verification (Opus cross-check)...
   Phase 6: Document Creation (level-appropriate files)...
   Phase 7: User Review & Confirmation...
   Phase 8: Context Persistence...
   ```

---

## 10. 🔧 FAILURE RECOVERY

| Failure Type                | Recovery Action                                          |
| --------------------------- | -------------------------------------------------------- |
| Task unclear                | Use AskUserQuestion to clarify (handled in YAML Phase 1) |
| Explore agents find nothing | Expand search scope (handled in YAML Phase 4)            |
| Conflicting findings        | Document both perspectives, ask user (YAML Phase 5)      |
| User rejects plan           | Revise based on feedback, resubmit (YAML Phase 7)        |
| Cannot create plan file     | Check permissions, use alternative path (YAML Phase 6)   |
| YAML prompt not found       | Return error with installation suggestion                |

---

## 11. ⚠️ ERROR HANDLING

| Condition              | Action                                                                                 |
| ---------------------- | -------------------------------------------------------------------------------------- |
| Empty `$ARGUMENTS`     | Prompt: "Please describe the task you want to plan"                                    |
| Invalid mode override  | Ignore, proceed with auto-detection                                                    |
| YAML file missing      | Return error: "Workflow file missing at .claude/commands/plan/assets/simple_mode.yaml" |
| Explore agents timeout | Continue with available results (handled in YAML)                                      |
| Plan file exists       | Ask to overwrite or create new version (handled in YAML Phase 6)                       |

---

## 12. 🔍 EXAMPLE USAGE

### Complex Architecture Planning
```bash
/plan:cc_opus Redesign the authentication system with multi-tenant support
```
> Uses 4 Opus 4.5 agents for deep architectural analysis

### Critical Feature Planning
```bash
/plan:cc_opus Implement payment processing with Stripe integration
```
> Thorough exploration of security, error handling, webhook patterns

### Large-Scale Refactor
```bash
/plan:cc_opus Migrate from REST to GraphQL across all services
```
> Deep reasoning about API surface, breaking changes, migration paths

### For Quick Planning (Use cc_sonnet Instead)
```bash
/plan:cc_sonnet Add user profile page
```
> Faster exploration with Sonnet agents (recommended for standard features)

---

## 13. 📊 EXAMPLE OUTPUT

```
Planning Mode Activated (Full Opus 4.5 Stack)

Task: Redesign authentication system with multi-tenant support
Mode: SIMPLE (500 LOC estimated)
Agent Model: Opus 4.5 (thorough exploration)

Phase 0: Documentation Level Detection
  LOC estimate: 500 (suggests Level 3)
  Documentation Level: 3 (Full)
  Required files: spec.md, plan.md, tasks.md, checklist.md, decision-record.md

Phase 1: Task Understanding & Session Initialization
  Task parsed: Multi-tenant authentication redesign
  SESSION_ID extracted: def456
  Complexity: HIGH (architecture change + security implications)

Phase 2: Spec Folder Setup
  Creating new spec folder: specs/043-auth-redesign/
  Marker set: .spec-active.def456

Phase 3: Context Loading
  No previous memory files found - starting fresh

Phase 4: Parallel Exploration (4 Opus 4.5 agents)
  Architecture Explorer (Opus): deep analysis of auth patterns...
    - Identified 12 auth-related modules
    - Found tenant isolation concerns in 3 areas
    - Discovered legacy session handling needing migration
  Feature Explorer (Opus): comprehensive auth feature mapping...
    - Mapped all auth flows (login, register, reset, 2FA)
    - Found cross-tenant data leakage risk in user lookup
    - Identified 8 features requiring tenant context
  Dependency Explorer (Opus): thorough dependency analysis...
    - Traced auth dependencies across 15 services
    - Found circular dependency in user/tenant modules
    - Identified 5 breaking change points
  Test Explorer (Opus): deep test infrastructure review...
    - Found gaps in tenant isolation tests
    - Identified 23 auth tests needing updates
    - Discovered missing integration test coverage
  Exploration Complete (47 files identified) [~45-60 seconds]

Phase 5: Hypothesis Verification (Opus cross-check)
  Cross-validating agent findings...
  Resolving 2 conflicting hypotheses...
  Building comprehensive mental model...
  Verification Complete (high confidence)

Phase 6: Document Creation (SpecKit Level 3)
  spec.md created: specs/043-auth-redesign/spec.md
  plan.md created: specs/043-auth-redesign/plan.md
  tasks.md created: specs/043-auth-redesign/tasks.md
  checklist.md created: specs/043-auth-redesign/checklist.md
  decision-record.md created: specs/043-auth-redesign/decision-record.md

Phase 7: User Review & Confirmation
  SpecKit Documentation Created (Level 3 - Full):
  - spec.md - Feature specification and requirements
  - plan.md - Technical implementation plan
  - tasks.md - Task breakdown
  - checklist.md - Verification checklist
  - decision-record.md - Architecture decisions documented

  Please review the documentation and confirm to proceed.
  [User confirms]
  Documents re-read (no edits)

Phase 8: Context Persistence
  Context saved: specs/043-auth-redesign/memory/28-11-25_15-00__auth-redesign.md

STATUS=OK ACTION=documentation_created FILES=spec.md,plan.md,tasks.md,checklist.md,decision-record.md PATH=specs/043-auth-redesign/
```

---

## 14. 📌 NOTES

- **Model Hierarchy (Opus 4.5 Variant):**
  - **Orchestrator**: Opus 4.5 (claude-opus-4-5-20251101) - Task understanding, verification, synthesis
  - **Explore Agents**: Opus 4.5 (claude-opus-4-5-20251101) - Deep parallel analysis
  - Claude Code Task tool uses `model: "opus"` parameter for full Opus stack
  - **Why Opus agents?** Deeper reasoning, better pattern recognition, more thorough analysis
  - **Trade-off**: Slower (~45-60s total vs ~15-20s with Sonnet) and higher cost
  - **Best for**: Critical features, complex architecture, security-sensitive changes

- **Opus Agent Advantages:**
  - Better at understanding nuanced code patterns
  - More thorough dependency analysis
  - Deeper reasoning about edge cases and risks
  - Higher quality hypotheses requiring less verification correction
  - Better at identifying non-obvious connections

- **SpecKit Alignment:**
  - MANDATORY compliance with AGENTS.md Section 2 requirements
  - Creates Level 1+ documentation (spec.md + plan.md + tasks.md baseline)
  - Level 2 adds checklist.md for verification tasks
  - Level 3 adds decision-record.md (required) + research-spike.md (optional)
  - All templates from `.opencode/speckit/templates/`
  - Documentation level detection in Phase 0
  - LOC thresholds are SOFT guidance; hooks enforce HARD requirements

- **YAML Architecture:**
  - Command file (~150 lines): Mode detection + agent model selection
  - YAML prompt (~1150 lines): Parameterized 9-phase workflow + SpecKit integration
  - Uses `simple_mode.yaml` with `AGENT_MODEL=opus` parameter
  - Single workflow file serves both cc_sonnet and cc_opus (DRY principle)
  - Modular, maintainable, version-friendly

- **Integration:**
  - Works with spec folder system (Phase 2)
  - Memory context enables session continuity (Phases 3 & 8)
  - SpecKit documents feed into `/spec_kit:implement` workflow
  - Enforced by workflows-spec-kit hooks

- **Memory System (Phase 8):**
  - Invokes `workflows-memory` skill for memory file creation
  - Auto-generates HTML anchor tags for grep-able sections
  - Anchor format: `<!-- anchor: category-topic-spec -->`
  - Search: `grep -r "anchor:.*keyword" specs/*/memory/`
  - Compatible with anchor-based context retrieval (spec 049)
  - Fallback to legacy template if skill unavailable

- **Alternative: cc_sonnet**
  - Use `/plan:cc_sonnet` for standard planning tasks
  - 4 Sonnet agents instead of Opus
  - Faster and more cost-effective
  - Opus orchestrator still verifies all findings
  - Recommended for most use cases