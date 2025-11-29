---
description: Create a detailed implementation plan with parallel exploration before any code changes
argument-hint: <task description> [mode:simple|mode:complex]
allowed-tools: Read, Write, Edit, Glob, Grep, Task, AskUserQuestion
model: opus
---

# Implementation Plan

Create comprehensive implementation plans using parallel exploration agents to thoroughly analyze the codebase before any code changes.

---

## Purpose

Enter PLANNING MODE to create detailed, verified implementation plans. This command:
1. Analyzes task complexity and selects appropriate mode (simple or complex)
2. Spawns multiple Explore agents in parallel to discover codebase patterns
3. Synthesizes findings into a structured plan using YAML workflow
4. Requires user approval before implementation begins

**Modes:**
- **Simple Mode** (<500 LOC): Single plan.md file using `simple_mode.yaml`
- **Complex Mode** (≥500 LOC): Multi-file plan/ directory (future - currently falls back to simple mode)

---

## Contract

**Inputs:** `$ARGUMENTS` — Task description (REQUIRED) + optional mode override
**Outputs:** Plan file at `specs/###-name/plan.md` (or `plan/` for complex mode) + `STATUS=<OK|FAIL|CANCELLED>`

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

6. **Read and execute the appropriate YAML workflow prompt:**

   Based on the mode selected in Step 2:

   - **SIMPLE mode** (<500 LOC): Use the Read tool to load `.claude/commands/plan/assets/simple_mode.yaml` and execute all instructions in that file.

   - **COMPLEX mode** (≥500 LOC): Use the Read tool to load `.claude/commands/plan/assets/complex_mode.yaml`. Note: Complex mode is a stub as of Phase 1.5 and will notify user to fall back to simple mode.

7. **YAML workflow executes automatically:**

   The loaded YAML prompt contains the complete 8-phase workflow:
   - **Phases 1-3** (from base_phases.yaml): Task Understanding, Spec Folder Setup, Context Loading
   - **Phases 4-5** (from exploration.yaml): Parallel Exploration (4 Sonnet agents), Hypothesis Verification (Opus)
   - **Phase 6** (mode-specific): Plan Creation (simple_mode or complex_mode)
   - **Phases 7-8** (from base_phases.yaml): User Review & Confirmation, Context Persistence

   All phases execute sequentially: 1 → 2 → 3 → 4 → 5 → 6 → 7 → 8

   **Expected outputs:**
   - Simple mode: `specs/###-name/plan.md` (500-2000 lines)
   - Complex mode (future): `specs/###-name/plan/` directory with manifest

### Step 4: Monitor Progress

8. **Display phase progress to user:**
   ```
   🔍 Planning Mode Activated (Opus Orchestrator)

   Task: {task_description}
   Mode: {SIMPLE/COMPLEX} ({loc_estimate} LOC estimated)

   📋 Phase 1: Task Understanding & Session Initialization...
   📁 Phase 2: Spec Folder Setup...
   🧠 Phase 3: Context Loading...
   📊 Phase 4: Parallel Exploration (4 Sonnet agents)...
   🔬 Phase 5: Hypothesis Verification (Opus review)...
   📝 Phase 6: Plan Creation...
   👤 Phase 7: User Review & Confirmation...
   💾 Phase 8: Context Persistence...
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
| YAML file missing      | Return error: "Workflow file missing at .claude/commands/plan/assets/{mode}_mode.yaml" |
| Explore agents timeout | Continue with available results (handled in YAML)                                       |
| Plan file exists       | Ask to overwrite or create new version (handled in YAML Phase 6)                        |

---

## Example Usage

### Basic Planning (Auto-Detect Mode)
```bash
/plan:with_claudeAdd user authentication with OAuth2
# Auto-detects: ~300 LOC → SIMPLE mode → simple_mode.yaml
```

### Explicit Simple Mode
```bash
/plan:with_claude"Refactor authentication (800 LOC)" mode:simple
# Forces SIMPLE mode despite LOC estimate
```

### Future: Complex Mode
```bash
/plan:with_claudeImplement real-time collaboration with conflict resolution
# Auto-detects: ~800 LOC → COMPLEX mode → Falls back to SIMPLE (stub)
```

---

## Example Output

```
🔍 Planning Mode Activated (Opus Orchestrator)

Task: Add user authentication with OAuth2
Mode: SIMPLE (300 LOC estimated)

📋 Phase 1: Task Understanding & Session Initialization
  ✓ Task parsed: Implement OAuth2 authentication flow
  ✓ SESSION_ID extracted: abc123

📁 Phase 2: Spec Folder Setup
  ✓ Creating new spec folder: specs/042-oauth2-auth/
  ✓ Marker set: .spec-active.abc123

🧠 Phase 3: Context Loading
  ℹ No previous memory files found - starting fresh

📊 Phase 4: Parallel Exploration (4 Sonnet agents)
  ├─ Architecture Explorer: analyzing project structure...
  ├─ Feature Explorer: finding auth patterns...
  ├─ Dependency Explorer: mapping imports...
  └─ Test Explorer: reviewing test infrastructure...
  ✅ Exploration Complete (23 files identified)

🔬 Phase 5: Hypothesis Verification (Opus review)
  ├─ Verifying architecture hypotheses...
  ├─ Cross-referencing agent findings...
  └─ Building complete mental model...
  ✅ Verification Complete

📝 Phase 6: Plan Creation
  ✓ Plan file created: specs/042-oauth2-auth/plan.md

👤 Phase 7: User Review & Confirmation
  Please review and confirm to proceed.
  [User confirms]
  ✓ Plan re-read (no edits)

💾 Phase 8: Context Persistence
  ✓ Context saved: specs/042-oauth2-auth/memory/28-11-25_14-30__oauth2-auth.md

STATUS=OK ACTION=plan_created PATH=specs/042-oauth2-auth/plan.md
```

---

## Notes

- **YAML Architecture:**
  - Command file (~150 lines): Mode detection + prompt loading
  - YAML prompts (~1050 lines): All phase logic
  - Modular, maintainable, version-friendly

- **Model Hierarchy:**
  - Orchestrator: `opus` (task understanding, verification, synthesis)
  - Explore Agents: `sonnet` (fast parallel discovery)
  - All Task tool calls for Explore agents MUST include `model: "sonnet"`

- **Integration:**
  - Works with spec folder system (Phase 2)
  - Memory context enables session continuity (Phases 3 & 8)
  - Plans feed into `/spec_kit:implement` workflow

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
