---
description: Create a detailed implementation plan using GPT orchestrator with Sonnet explorers (OpenCode)
argument-hint: <task description> [mode:simple|mode:complex]
allowed-tools: Read, Write, Edit, Glob, Grep, Task, AskUserQuestion
agent: plan
model: gpt
---

# ⛔ MANDATORY GATES - BLOCKING ENFORCEMENT

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

# Implementation Plan with GPT Orchestrator (OpenCode)

**About this command:** This command creates SpecKit documentation using GPT as orchestrator with Sonnet agents for parallel codebase exploration. It requires a task description as input.

**Platform**: OpenCode with Copilot integration
**Orchestrator**: GPT via Copilot (task understanding, verification, synthesis)
**Explorers**: Sonnet agents × 4 (parallel exploration) - with intelligent fallback
**SpecKit Aligned**: Creates Level 2+ documentation per AGENTS.md Section 2

---

## 6. 🔀 WHEN TO USE WITH_GPT VS WITH_CLAUDE VS WITH_GEMINI

| Command             | Orchestrator | Best For               | Unique Strength           |
| ------------------- | ------------ | ---------------------- | ------------------------- |
| with_claude         | Claude       | Most planning tasks    | Claude's coding expertise |
| **with_gpt** (this) | GPT          | GPT perspective needed | Alternative AI viewpoint  |
| with_gemini         | Gemini       | Web research helpful   | Google Search integration |

**Recommendation**: Use `with_gpt` when you want GPT's perspective on planning. Use `with_claude` for Claude's coding expertise, or `with_gemini` for web research capabilities.

---

## 7. 📋 PURPOSE

Enter PLANNING MODE to create detailed, verified SpecKit documentation. This command:
1. Determines SpecKit documentation level (2 or 3) based on task complexity
2. **GPT orchestrates** the entire planning workflow (task understanding, agent coordination, verification)
3. **Spawns 4 Sonnet agents** in parallel for fast, cost-effective codebase exploration
4. **Falls back gracefully** if Sonnet unavailable (tries other models, then self-exploration)
5. **GPT verifies** all findings by reading actual code before creating SpecKit documents
6. Creates spec.md (requirements and user stories) + plan.md (technical approach)
7. Optionally creates tasks.md for complex features (Level 3)
8. Requires user approval before implementation begins

**Key Architecture**:
- **GPT Orchestrator**: Provides GPT's perspective on planning, synthesis, and code understanding
- **Sonnet Explorers**: Fast parallel agents for efficient codebase discovery
- **Hybrid Strength**: Combines GPT's planning expertise with Sonnet's exploration speed
- **Intelligent Fallback**: Automatically adapts if Sonnet agents unavailable
- **SpecKit Integration**: Creates complete Level 2+ documentation per AGENTS.md requirements

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

7. **Set model parameters and read the appropriate YAML workflow:**

   **CRITICAL: Set parameters before loading simple_mode.yaml**

   ```
   ORCHESTRATOR_MODEL=gpt
   AGENT_MODEL=sonnet
   ```

   This command uses GPT as orchestrator with Sonnet exploration agents.
   The simple_mode.yaml file is parameterized and will use whatever models are specified.

   Asset path: `.opencode/command/plan/assets/`

   Based on the mode selected in Step 2:

   - **SIMPLE mode** (<500 LOC):
     1. Set `ORCHESTRATOR_MODEL=gpt` and `AGENT_MODEL=sonnet`
     2. Use the Read tool to load `.opencode/command/plan/assets/simple_mode.yaml`
     3. Execute all instructions with gpt orchestrating and sonnet exploring

   - **COMPLEX mode** (≥500 LOC): Use the Read tool to load `.opencode/command/plan/assets/complex_mode.yaml`. Note: Complex mode is a stub as of Phase 1.5 and will notify user to fall back to simple mode.

8. **YAML workflow executes with GPT orchestration + Sonnet exploration:**

   The loaded YAML prompt contains the complete 9-phase workflow (SpecKit aligned):
   - **Phase 0**: Documentation Level Detection (SpecKit Level 1, 2, or 3)
   - **Phases 1-3**: Task Understanding (GPT), Spec Folder Setup, Context Loading
   - **Phases 4-5**: Parallel Exploration (4 Sonnet agents), Hypothesis Verification (GPT)
   - **Phase 6**: Document Creation (level-appropriate files) (GPT synthesis)
   - **Phases 7-8**: User Review & Confirmation, Context Persistence

   **Parameterized Workflow:**

   The simple_mode.yaml workflow uses `ORCHESTRATOR_MODEL=gpt` and `AGENT_MODEL=sonnet` to:
   - Spawn 4 Sonnet agents for fast parallel exploration
   - Use GPT for verification and synthesis

   **Spawn all 4 agents in parallel** (single message with 4 Task calls):
   - Architecture Explorer (Sonnet)
   - Feature Explorer (Sonnet)
   - Dependency Explorer (Sonnet)
   - Test Explorer (Sonnet)

   **Fallback Strategy (if Sonnet spawn fails):**

   If Sonnet agents are unavailable or spawn fails:

   1. **Try GPT agents** (same as orchestrator)
   2. **Self-exploration** - GPT performs inline analysis using Glob/Grep/Read
   3. Document that parallel agents were unavailable

   All phases execute sequentially: 0 → 1 → 2 → 3 → 4 (Sonnet/fallback) → 5 (GPT verifies) → 6 → 7 → 8

   **Expected outputs:**
   - Level 1: `specs/###-name/spec.md` + `plan.md` + `tasks.md`
   - Level 2: Level 1 + `checklist.md`
   - Level 3: Level 2 + `decision-record.md` (+ optional `research-spike.md`)


### Step 4: Monitor Progress

9. **Display phase progress to user:**
   ```
   Planning Mode Activated (GPT Orchestrator + Sonnet Explorers)

   Task: {task_description}
   Mode: {SIMPLE/COMPLEX} ({loc_estimate} LOC estimated)
   Documentation Level: {1, 2, or 3}
   Orchestrator: GPT via Copilot
   Explorers: Sonnet agents (with fallback)

   Phase 0: Documentation Level Detection...
   Phase 1: Task Understanding & Session Initialization (GPT)...
   Phase 2: Spec Folder Setup...
   Phase 3: Context Loading...
   Phase 4: Parallel Exploration (4 Sonnet agents)...
   Phase 5: Hypothesis Verification (GPT review)...
   Phase 6: Document Creation (level-appropriate files) (GPT synthesis)...
   Phase 7: User Review & Confirmation...
   Phase 8: Context Persistence...
   ```

---

## 10. 🔧 FAILURE RECOVERY

| Failure Type                | Recovery Action                                          |
| --------------------------- | -------------------------------------------------------- |
| Copilot unavailable         | Fall back to with_claude command                         |
| GPT model not accessible    | Fall back to with_claude command                         |
| Sonnet agents unavailable   | Try GPT agents → other models → self-exploration         |
| Task unclear                | Use AskUserQuestion to clarify (handled in YAML Phase 1) |
| Explore agents find nothing | Expand search scope (handled in YAML Phase 4)            |
| Conflicting findings        | Document both perspectives, ask user (YAML Phase 5)      |
| User rejects plan           | Revise based on feedback, resubmit (YAML Phase 7)        |
| Cannot create plan file     | Check permissions, use alternative path (YAML Phase 6)   |
| YAML prompt not found       | Return error with installation suggestion                |

---

## 11. ⚠️ ERROR HANDLING

| Condition              | Action                                                                                  |
| ---------------------- | --------------------------------------------------------------------------------------- |
| Empty `$ARGUMENTS`     | Prompt: "Please describe the task you want to plan"                                     |
| Invalid mode override  | Ignore, proceed with auto-detection                                                     |
| YAML file missing      | Return error: "Workflow file missing at .opencode/command/plan/assets/{mode}_mode.yaml" |
| Explore agents timeout | Continue with available results (handled in YAML)                                       |
| Plan file exists       | Ask to overwrite or create new version (handled in YAML Phase 6)                        |
| Copilot not configured | Error: "OpenCode Copilot not configured. Run setup or use /plan:with_claude"            |
| Sonnet spawn fails     | Auto-fallback to GPT agents → other models → self-exploration                           |

---

## 12. 🔍 EXAMPLE USAGE

### Basic Planning (Auto-Detect Mode)
```bash
/plan:with_gpt Add user authentication with OAuth2
# GPT orchestrator spawns 4 Sonnet agents for exploration
```

### Explicit Simple Mode
```bash
/plan:with_gpt "Refactor authentication (800 LOC)" mode:simple
# Forces SIMPLE mode despite LOC estimate
```

---

## 13. 📊 EXAMPLE OUTPUT

```
Planning Mode Activated (GPT Orchestrator + Sonnet Explorers + SpecKit)

Task: Add user authentication with OAuth2
Mode: SIMPLE (300 LOC estimated)
Orchestrator: GPT via Copilot
Explorers: Sonnet agents

Phase 0: Documentation Level Detection
  LOC estimate: 300 (suggests Level 2)
  Documentation Level: 2 (Verification)
  Required files: spec.md, plan.md, tasks.md, checklist.md

Phase 1: Task Understanding & Session Initialization (GPT)
  Task parsed: Implement OAuth2 authentication flow
  SESSION_ID extracted: abc123

Phase 2: Spec Folder Setup
  Creating new spec folder: specs/042-oauth2-auth/
  Marker set: .spec-active.abc123

Phase 3: Context Loading
  No previous memory files found - starting fresh

Phase 4: Parallel Exploration (4 Sonnet agents)
  Architecture Explorer (Sonnet): analyzing project structure...
  Feature Explorer (Sonnet): finding auth patterns...
  Dependency Explorer (Sonnet): mapping imports...
  Test Explorer (Sonnet): reviewing test infrastructure...
  Exploration Complete (28 files identified)

Phase 5: Hypothesis Verification (GPT review)
  Verifying Sonnet hypotheses (GPT reading files)...
  Cross-referencing agent findings...
  Building complete mental model with GPT perspective...
  Verification Complete

Phase 6: Document Creation (SpecKit Level 2 - GPT synthesis)
  spec.md created: specs/042-oauth2-auth/spec.md
  plan.md created: specs/042-oauth2-auth/plan.md
  tasks.md created: specs/042-oauth2-auth/tasks.md
  checklist.md created: specs/042-oauth2-auth/checklist.md
  GPT perspective applied to SpecKit documents

Phase 7: User Review & Confirmation
  SpecKit Documentation Created (Level 2):
  - spec.md - Feature specification and requirements
  - plan.md - Technical implementation plan
  - tasks.md - Task breakdown
  - checklist.md - Verification checklist

  Please review and confirm to proceed.
  [User confirms]
  Documents re-read (no edits)

Phase 8: Context Persistence
  Context saved: specs/042-oauth2-auth/memory/29-11-25_14-30__oauth2-auth.md

STATUS=OK ACTION=documentation_created FILES=spec.md,plan.md,tasks.md,checklist.md PATH=specs/042-oauth2-auth/
```

---

## 14. 📌 NOTES

- **SpecKit Alignment:**
  - MANDATORY compliance with AGENTS.md Section 2 requirements
  - Creates Level 1+ documentation (spec.md + plan.md + tasks.md baseline)
  - Level 2 adds checklist.md for verification tasks
  - Level 3 adds decision-record.md (required) + research-spike.md (optional)
  - All templates from `.opencode/speckit/templates/`
  - Documentation level detection in Phase 0
  - LOC thresholds are SOFT guidance; manual discipline enforces requirements

- **GPT Orchestration:**
  - GPT handles task understanding, agent coordination, verification, synthesis
  - Uses OpenCode's Copilot integration for GPT model access
  - Provides GPT's unique perspective on planning and code patterns
  - Different strengths than Claude for certain types of analysis
  - Applies GPT perspective to SpecKit document creation

- **Sonnet Exploration:**
  - Spawns 4 Sonnet agents via Task tool for parallel discovery
  - Fast, cost-effective exploration phase
  - Sonnet excels at quick codebase pattern recognition
  - Parallel execution keeps total time low (15-35 seconds)

- **Hybrid Architecture Benefits:**
  - **GPT Planning**: Strategic thinking, synthesis, code understanding
  - **Sonnet Exploration**: Fast parallel discovery, pattern recognition
  - **Best of Both**: Combines strengths of different models
  - **Cost Efficient**: Expensive GPT for high-value tasks, cheaper Sonnet for exploration

- **Intelligent Fallback:**
  - Primary: 4 Sonnet agents in parallel
  - Fallback 1: 4 GPT agents in parallel (if Sonnet unavailable)
  - Fallback 2: Other available models
  - Fallback 3: GPT self-exploration (inline, no agents)
  - Automatically selects best available option

- **Performance:**
  - Exploration: ~15-35 seconds (4 Sonnet agents)
  - Verification: ~15-30 seconds (GPT)
  - Plan creation: ~10-20 seconds (GPT)
  - **Total**: ~40-85 seconds

- **When to Use:**
  - Want GPT's perspective on planning and synthesis
  - Need fast parallel exploration (Sonnet)
  - Cost-effective hybrid approach
  - Comparing different AI perspectives
  - Have OpenCode with Copilot configured

- **Integration:**
  - Works with spec folder system (Phase 2)
  - Memory context enables session continuity (Phases 3 & 8)
  - Plans feed into `/spec_kit:implement` workflow
  - Can be used alongside `/plan:with_claude` or `/plan:with_gemini` for comparison

- **Copilot Requirements:**
  - OpenCode with Copilot integration enabled
  - GitHub Copilot subscription (for GPT model access)
  - Proper model routing configuration in OpenCode
  - Ideally, access to both GPT and Claude models for full functionality

---

**Remember**: This command uses **GPT as the orchestrator** (planning, verification, synthesis) with **Sonnet as parallel explorers** (fast codebase discovery). The hybrid approach combines GPT's planning strengths with Sonnet's exploration speed and cost-effectiveness.
