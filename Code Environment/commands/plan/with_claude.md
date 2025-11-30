---
description: Create a detailed implementation plan with parallel exploration before any code changes (OpenCode)
argument-hint: <task description> [mode:simple|mode:complex]
allowed-tools: Read, Write, Edit, Glob, Grep, Task, AskUserQuestion
agent: plan
---

# Implementation Plan (OpenCode)

Create comprehensive SpecKit documentation using parallel exploration agents to thoroughly analyze the codebase before any code changes.

**Platform**: OpenCode only (uses Task tool with Claude agents)
**SpecKit Aligned**: Creates Level 2+ documentation per AGENTS.md Section 2

---

## Purpose

Enter PLANNING MODE to create detailed, verified SpecKit documentation. This command:
1. Determines SpecKit documentation level (2 or 3) based on task complexity
2. Creates spec.md (requirements and user stories) + plan.md (technical approach)
3. Spawns multiple Explore agents in parallel to discover codebase patterns
4. Synthesizes findings into structured SpecKit documents using YAML workflow
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

## Contract

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

## Instructions

Execute the following workflow:

### Step 1: Parse Input & Detect Mode Override

1. **Extract task description from $ARGUMENTS**
2. **Check for explicit mode override:**
   - Pattern: `mode:simple` or `mode:complex` in arguments
   - If found: Use specified mode, skip auto-detection
   - If not found: Proceed to Step 2 for auto-detection

### Step 2: Auto-Detect Planning Mode

If no mode override specified, analyze task complexity:

3. **Estimate LOC from task description:**
   - Keywords: "small" = 100, "feature" = 200, "refactor" = 300, "system" = 500, "redesign" = 800
   - File count indicators: "all", "multiple", "across" = +200 LOC
   - Default: 300 LOC if unclear

4. **Calculate complexity score (0-100%):**
   - Domain count (35%): code, docs, git, testing, devops
   - File count (25%): estimated files modified
   - LOC estimate (15%): normalized 0-1
   - Parallel opportunity (20%): can tasks run in parallel?
   - Task type (5%): implementation complexity

5. **Select mode:**
   ```
   IF loc_estimate < 500:
     mode = "simple"
   ELSE IF loc_estimate >= 500 OR iterations >= 4:
     mode = "complex"  # Falls back to simple until Phase 5 implemented
   ELSE:
     mode = "simple"
   ```

### Step 3: Load & Execute YAML Workflow

6. **Read the appropriate YAML workflow prompt from OpenCode assets:**

   Asset path: `.opencode/command/plan/assets/`

   Based on the mode selected in Step 2:

   - **SIMPLE mode** (<500 LOC): Use the Read tool to load `.opencode/command/plan/assets/simple_mode.yaml` and execute all instructions in that file.

   - **COMPLEX mode** (≥500 LOC): Use the Read tool to load `.opencode/command/plan/assets/complex_mode.yaml`. Note: Complex mode is a stub as of Phase 1.5 and will notify user to fall back to simple mode.

7. **YAML workflow executes automatically:**

   The loaded YAML prompt contains the complete 9-phase workflow (SpecKit aligned):
   - **Phase 0**: Documentation Level Detection (SpecKit Level 1, 2, or 3)
   - **Phases 1-3**: Task Understanding, Spec Folder Setup, Context Loading
   - **Phases 4-5**: Parallel Exploration (4 Sonnet agents), Hypothesis Verification (Opus)
   - **Phase 6**: Document Creation (level-appropriate files)
   - **Phases 7-8**: User Review & Confirmation, Context Persistence

   All phases execute sequentially: 0 → 1 → 2 → 3 → 4 → 5 → 6 → 7 → 8

   **Expected outputs:**
   - Level 1: `specs/###-name/spec.md` + `plan.md` + `tasks.md`
   - Level 2: Level 1 + `checklist.md`
   - Level 3: Level 2 + `decision-record.md` (+ optional `research-spike.md`)

### Step 4: Monitor Progress

8. **Display phase progress to user:**
   ```
   Planning Mode Activated (Opus Orchestrator + SpecKit)

   Task: {task_description}
   Mode: {SIMPLE/COMPLEX} ({loc_estimate} LOC estimated)
   Documentation Level: {1, 2, or 3}

   Phase 0: Documentation Level Detection...
   Phase 1: Task Understanding & Session Initialization...
   Phase 2: Spec Folder Setup...
   Phase 3: Context Loading...
   Phase 4: Parallel Exploration (4 Sonnet agents)...
   Phase 5: Hypothesis Verification (Opus review)...
   Phase 6: Document Creation (level-appropriate files)...
   Phase 7: User Review & Confirmation...
   Phase 8: Context Persistence...
   ```

---

## Failure Recovery

| Failure Type                | Recovery Action                                          |
| --------------------------- | -------------------------------------------------------- |
| Task unclear                | Use AskUserQuestion to clarify (handled in YAML Phase 1) |
| Explore agents find nothing | Expand search scope (handled in YAML Phase 4)            |
| Conflicting findings        | Document both perspectives, ask user (YAML Phase 5)      |
| User rejects plan           | Revise based on feedback, resubmit (YAML Phase 7)        |
| Cannot create plan file     | Check permissions, use alternative path (YAML Phase 6)   |
| YAML prompt not found       | Return error with installation suggestion                |

---

## Error Handling

| Condition              | Action                                                                                  |
| ---------------------- | --------------------------------------------------------------------------------------- |
| Empty `$ARGUMENTS`     | Prompt: "Please describe the task you want to plan"                                     |
| Invalid mode override  | Ignore, proceed with auto-detection                                                     |
| YAML file missing      | Return error: "Workflow file missing at .opencode/command/plan/assets/{mode}_mode.yaml" |
| Explore agents timeout | Continue with available results (handled in YAML)                                       |
| Plan file exists       | Ask to overwrite or create new version (handled in YAML Phase 6)                        |

---

## Example Usage

### Basic Planning (Auto-Detect Mode)
```bash
/plan:with_claude Add user authentication with OAuth2
# Auto-detects: ~300 LOC → SIMPLE mode → simple_mode.yaml
```

### Explicit Simple Mode
```bash
/plan:with_claude "Refactor authentication (800 LOC)" mode:simple
# Forces SIMPLE mode despite LOC estimate
```

### Future: Complex Mode
```bash
/plan:with_claude Implement real-time collaboration with conflict resolution
# Auto-detects: ~800 LOC → COMPLEX mode → Falls back to SIMPLE (stub)
```

---

## Example Output

```
Planning Mode Activated (Opus Orchestrator + SpecKit)

Task: Add user authentication with OAuth2
Mode: SIMPLE (300 LOC estimated)

Phase 0: Documentation Level Detection
  LOC estimate: 300 (suggests Level 2)
  Documentation Level: 2 (Verification)
  Required files: spec.md, plan.md, tasks.md, checklist.md

Phase 1: Task Understanding & Session Initialization
  Task parsed: Implement OAuth2 authentication flow
  SESSION_ID extracted: abc123

Phase 2: Spec Folder Setup
  Creating new spec folder: specs/042-oauth2-auth/
  Marker set: .spec-active.abc123

Phase 3: Context Loading
  No previous memory files found - starting fresh

Phase 4: Parallel Exploration (4 Sonnet agents)
  Architecture Explorer: analyzing project structure...
  Feature Explorer: finding auth patterns...
  Dependency Explorer: mapping imports...
  Test Explorer: reviewing test infrastructure...
  Exploration Complete (23 files identified)

Phase 5: Hypothesis Verification (Opus review)
  Verifying architecture hypotheses...
  Cross-referencing agent findings...
  Building complete mental model...
  Verification Complete

Phase 6: Document Creation (SpecKit Level 2)
  spec.md created: specs/042-oauth2-auth/spec.md
  plan.md created: specs/042-oauth2-auth/plan.md
  tasks.md created: specs/042-oauth2-auth/tasks.md
  checklist.md created: specs/042-oauth2-auth/checklist.md

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
  Context saved: specs/042-oauth2-auth/memory/28-11-25_14-30__oauth2-auth.md

STATUS=OK ACTION=documentation_created FILES=spec.md,plan.md,tasks.md,checklist.md PATH=specs/042-oauth2-auth/
```

---

## Notes

- **SpecKit Alignment:**
  - MANDATORY compliance with AGENTS.md Section 2 requirements
  - Creates Level 1+ documentation (spec.md + plan.md + tasks.md baseline)
  - Level 2 adds checklist.md for verification tasks
  - Level 3 adds decision-record.md (required) + research-spike.md (optional)
  - All templates from `.opencode/speckit/templates/`
  - Documentation level detection in Phase 0
  - LOC thresholds are SOFT guidance; hooks enforce HARD requirements

- **YAML Architecture:**
  - Command file (~150 lines): Mode detection + prompt loading
  - YAML prompts (~1150 lines): All 9-phase logic + SpecKit integration
  - Modular, maintainable, version-friendly

- **Model Hierarchy:**
  - Orchestrator: Default agent (task understanding, verification, synthesis)
  - Explore Agents: Faster model (fast parallel discovery)
  - OpenCode Task tool supports parallel agent spawning

- **Integration:**
  - Works with spec folder system (Phase 2)
  - Memory context enables session continuity (Phases 3 & 8)
  - SpecKit documents feed into `/spec_kit:implement` workflow
  - Enforced by workflows-spec-kit hooks

- **Memory System (Phase 8):**
  - Invokes `workflows-save-context` skill for memory file creation
  - Auto-generates HTML anchor tags for grep-able sections
  - Anchor format: `<!-- anchor: category-topic-spec -->`
  - Search: `grep -r "anchor:.*keyword" specs/*/memory/`
  - Compatible with anchor-based context retrieval (spec 049)
  - Fallback to legacy template if skill unavailable

- **Future Enhancements:**
  - Complex mode with multi-file plan/ directory (Phase 5 upgrade)
  - Mode selection refinement based on usage patterns
  - Enhanced Level 3 support with guided research-spike creation
