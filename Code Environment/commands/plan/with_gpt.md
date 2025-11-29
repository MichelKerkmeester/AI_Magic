---
description: Create a detailed implementation plan using GPT orchestrator with Sonnet explorers (OpenCode)
argument-hint: <task description> [mode:simple|mode:complex]
allowed-tools: Read, Write, Edit, Glob, Grep, Task, AskUserQuestion
agent: plan
model: gpt
---

# Implementation Plan with GPT Orchestrator (OpenCode)

Create comprehensive implementation plans using **GPT as orchestrator** with Sonnet agents for parallel codebase exploration.

**Platform**: OpenCode with Copilot integration
**Orchestrator**: GPT via Copilot (task understanding, verification, synthesis)
**Explorers**: Sonnet agents × 4 (parallel exploration) - with intelligent fallback

---

## Purpose

Enter PLANNING MODE to create detailed, verified implementation plans. This command:
1. **GPT orchestrates** the entire planning workflow (task understanding, agent coordination, verification)
2. **Spawns 4 Sonnet agents** in parallel for fast, cost-effective codebase exploration
3. **Falls back gracefully** if Sonnet unavailable (tries other models, then self-exploration)
4. **GPT verifies** all findings by reading actual code before creating plan
5. Requires user approval before implementation begins

**Key Architecture**:
- **GPT Orchestrator**: Provides GPT's perspective on planning, synthesis, and code understanding
- **Sonnet Explorers**: Fast parallel agents for efficient codebase discovery
- **Hybrid Strength**: Combines GPT's planning expertise with Sonnet's exploration speed
- **Intelligent Fallback**: Automatically adapts if Sonnet agents unavailable

**Modes:**
- **Simple Mode** (<500 LOC): Single plan.md file using `simple_mode.yaml`
- **Complex Mode** (≥500 LOC): Multi-file plan/ directory (future - currently falls back to simple mode)

---

## Contract

**Inputs:** `$ARGUMENTS` — Task description (REQUIRED) + optional mode override
**Outputs:** Plan file at `specs/###-name/plan.md` + `STATUS=<OK|FAIL|CANCELLED>`

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

7. **YAML workflow executes with GPT orchestration + Sonnet exploration:**

   The loaded YAML prompt contains the complete 8-phase workflow:
   - **Phases 1-3**: Task Understanding (GPT), Spec Folder Setup, Context Loading
   - **Phases 4-5**: Parallel Exploration (4 Sonnet agents), Hypothesis Verification (GPT)
   - **Phase 6**: Plan Creation (GPT synthesis)
   - **Phases 7-8**: User Review & Confirmation, Context Persistence

   **CRITICAL OVERRIDE for Phase 4 (Parallel Exploration):**

   When spawning the 4 Explore agents, use **Sonnet agents** for fast parallel exploration:

   ```yaml
   # Primary strategy: Spawn 4 Sonnet agents
   Task({
     subagent_type: "Explore",
     model: "sonnet",  # Claude Sonnet for fast exploration
     description: "Architecture exploration",
     prompt: "[exploration prompt from YAML]"
   })
   ```

   **Spawn all 4 agents in parallel** (single message with 4 Task calls):
   - Architecture Explorer (Sonnet)
   - Feature Explorer (Sonnet)
   - Dependency Explorer (Sonnet)
   - Test Explorer (Sonnet)

   **Fallback Strategy (if Sonnet spawn fails):**

   If Sonnet agents are unavailable or spawn fails:

   1. **Try alternative models** available via Copilot:
      ```yaml
      # Fallback Option 1: Try GPT agents
      Task({
        subagent_type: "Explore",
        model: "gpt",  # Same as orchestrator
        description: "Architecture exploration",
        prompt: "[exploration prompt from YAML]"
      })
      ```

   2. **Self-exploration** (if no agents available):
      - GPT orchestrator performs exploration inline using Glob/Grep/Read tools
      - Sequential but thorough codebase analysis
      - Document that parallel agents were unavailable
      - Slower but still produces quality plan

   **Model Priority:**
   1. Sonnet (preferred - fast, cost-effective)
   2. GPT (fallback - same as orchestrator)
   3. Other available models (Haiku, etc.)
   4. Self-exploration (no agents - inline analysis)

   All phases execute sequentially: 1 → 2 → 3 → 4 (Sonnet/fallback) → 5 (GPT verifies) → 6 → 7 → 8

   **Expected outputs:**
   - Simple mode: `specs/###-name/plan.md` (500-2000 lines)
   - Complex mode (future): `specs/###-name/plan/` directory with manifest

### Step 4: Monitor Progress

8. **Display phase progress to user:**
   ```
   🔍 Planning Mode Activated (GPT Orchestrator + Sonnet Explorers)

   Task: {task_description}
   Mode: {SIMPLE/COMPLEX} ({loc_estimate} LOC estimated)
   Orchestrator: GPT via Copilot
   Explorers: Sonnet agents (with fallback)

   📋 Phase 1: Task Understanding & Session Initialization (GPT)...
   📁 Phase 2: Spec Folder Setup...
   🧠 Phase 3: Context Loading...
   📊 Phase 4: Parallel Exploration (4 Sonnet agents)...
   🔬 Phase 5: Hypothesis Verification (GPT review)...
   📝 Phase 6: Plan Creation (GPT synthesis)...
   👤 Phase 7: User Review & Confirmation...
   💾 Phase 8: Context Persistence...
   ```

---

## Failure Recovery

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

## Error Handling

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

## Example Usage

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

## Example Output

```
🔍 Planning Mode Activated (GPT Orchestrator + Sonnet Explorers)

Task: Add user authentication with OAuth2
Mode: SIMPLE (300 LOC estimated)
Orchestrator: GPT via Copilot
Explorers: Sonnet agents

📋 Phase 1: Task Understanding & Session Initialization (GPT)
  ✓ Task parsed: Implement OAuth2 authentication flow
  ✓ SESSION_ID extracted: abc123

📁 Phase 2: Spec Folder Setup
  ✓ Creating new spec folder: specs/042-oauth2-auth/
  ✓ Marker set: .spec-active.abc123

🧠 Phase 3: Context Loading
  ℹ No previous memory files found - starting fresh

📊 Phase 4: Parallel Exploration (4 Sonnet agents)
  ├─ Architecture Explorer (Sonnet): analyzing project structure...
  ├─ Feature Explorer (Sonnet): finding auth patterns...
  ├─ Dependency Explorer (Sonnet): mapping imports...
  └─ Test Explorer (Sonnet): reviewing test infrastructure...
  ✅ Exploration Complete (28 files identified)

🔬 Phase 5: Hypothesis Verification (GPT review)
  ├─ Verifying Sonnet hypotheses (GPT reading files)...
  ├─ Cross-referencing agent findings...
  └─ Building complete mental model with GPT perspective...
  ✅ Verification Complete

📝 Phase 6: Plan Creation (GPT synthesis)
  ✓ Plan file created: specs/042-oauth2-auth/plan.md
  ✓ GPT perspective applied to plan structure

👤 Phase 7: User Review & Confirmation
  Please review and confirm to proceed.
  [User confirms]
  ✓ Plan re-read (no edits)

💾 Phase 8: Context Persistence
  ✓ Context saved: specs/042-oauth2-auth/memory/29-11-25_14-30__oauth2-auth.md

STATUS=OK ACTION=plan_created PATH=specs/042-oauth2-auth/plan.md
```

---

## Notes

- **GPT Orchestration:**
  - GPT handles task understanding, agent coordination, verification, synthesis
  - Uses OpenCode's Copilot integration for GPT model access
  - Provides GPT's unique perspective on planning and code patterns
  - Different strengths than Claude for certain types of analysis

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
