---
description: Create a detailed implementation plan using Gemini orchestrator with Sonnet explorers and web research capabilities (OpenCode)
argument-hint: <task description> [mode:simple|mode:complex]
allowed-tools: Read, Write, Edit, Glob, Grep, Task, AskUserQuestion
agent: plan
model: gemini-3.0-pro
---

# Implementation Plan with Gemini Orchestrator (OpenCode)

Create comprehensive implementation plans using **Gemini as orchestrator** with Sonnet agents for parallel codebase exploration and potential web research.

**Platform**: OpenCode with Copilot integration
**Orchestrator**: Gemini 3.0 pro via Copilot (task understanding, verification, synthesis, web research)
**Explorers**: Sonnet agents × 4 (parallel exploration) - with intelligent fallback

---

## Purpose

Enter PLANNING MODE to create detailed, verified implementation plans. This command:
1. **Gemini orchestrates** the entire planning workflow (task understanding, agent coordination, verification)
2. **Spawns 4 Sonnet agents** in parallel for fast, cost-effective codebase exploration
3. **Leverages Gemini's web research** capabilities for current best practices (if enabled in Copilot)
4. **Falls back gracefully** if Sonnet unavailable (tries other models, then self-exploration)
5. **Gemini verifies** all findings by reading actual code before creating plan
6. Requires user approval before implementation begins

**Key Architecture**:
- **Gemini Orchestrator**: Provides Gemini's perspective on planning, synthesis, and multimodal understanding
- **Sonnet Explorers**: Fast parallel agents for efficient codebase discovery
- **Web Research**: Potential Google Search integration for current best practices and documentation
- **Hybrid Strength**: Combines Gemini's research capabilities with Sonnet's exploration speed
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

7. **YAML workflow executes with Gemini orchestration + Sonnet exploration:**

   The loaded YAML prompt contains the complete 8-phase workflow:
   - **Phases 1-3**: Task Understanding (Gemini + optional web research), Spec Folder Setup, Context Loading
   - **Phases 4-5**: Parallel Exploration (4 Sonnet agents), Hypothesis Verification (Gemini)
   - **Phase 6**: Plan Creation (Gemini synthesis + web insights)
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
      # Fallback Option 1: Try Gemini agents
      Task({
        subagent_type: "Explore",
        model: "gemini-3.0-pro",  # Same as orchestrator
        description: "Architecture exploration",
        prompt: "[exploration prompt from YAML]"
      })
      ```

   2. **Self-exploration with web research** (if no agents available):
      - Gemini orchestrator performs exploration inline using Glob/Grep/Read tools
      - Optionally augment with web research for current best practices
      - Sequential but thorough codebase analysis with external knowledge
      - Document that parallel agents were unavailable
      - Slower but may include valuable web insights

   **Model Priority:**
   1. Sonnet (preferred - fast, cost-effective)
   2. Gemini 3.0 pro (fallback - same as orchestrator, may include web research)
   3. Other available models (Haiku, etc.)
   4. Self-exploration (no agents - inline analysis + optional web research)

   All phases execute sequentially: 1 → 2 → 3 → 4 (Sonnet/fallback) → 5 (Gemini verifies) → 6 → 7 → 8

   **Expected outputs:**
   - Simple mode: `specs/###-name/plan.md` (500-2000 lines)
   - Complex mode (future): `specs/###-name/plan/` directory with manifest

### Step 4: Monitor Progress

8. **Display phase progress to user:**
   ```
   🔍 Planning Mode Activated (Gemini Orchestrator + Sonnet Explorers)

   Task: {task_description}
   Mode: {SIMPLE/COMPLEX} ({loc_estimate} LOC estimated)
   Orchestrator: Gemini 3.0 pro via Copilot
   Explorers: Sonnet agents (with fallback)
   Web Research: {Enabled/Disabled}

   📋 Phase 1: Task Understanding & Session Initialization (Gemini)...
   📁 Phase 2: Spec Folder Setup...
   🧠 Phase 3: Context Loading...
   📊 Phase 4: Parallel Exploration (4 Sonnet agents)...
   🔬 Phase 5: Hypothesis Verification (Gemini review)...
   📝 Phase 6: Plan Creation (Gemini synthesis)...
   👤 Phase 7: User Review & Confirmation...
   💾 Phase 8: Context Persistence...
   ```

---

## Failure Recovery

| Failure Type                | Recovery Action                                                |
| --------------------------- | -------------------------------------------------------------- |
| Copilot unavailable         | Fall back to with_claude command                               |
| Gemini model not accessible | Fall back to with_claude or with_gpt command                   |
| Sonnet agents unavailable   | Try Gemini agents → other models → self-exploration + research |
| Task unclear                | Use AskUserQuestion to clarify (handled in YAML Phase 1)       |
| Explore agents find nothing | Expand search scope, use web research (handled in YAML Phase 4)|
| Conflicting findings        | Document both perspectives, ask user (YAML Phase 5)            |
| User rejects plan           | Revise based on feedback, resubmit (YAML Phase 7)              |
| Cannot create plan file     | Check permissions, use alternative path (YAML Phase 6)         |
| YAML prompt not found       | Return error with installation suggestion                      |

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
| Sonnet spawn fails     | Auto-fallback to Gemini agents → other models → self-exploration + web research         |

---

## Example Usage

### Basic Planning (Auto-Detect Mode)
```bash
/plan:with_gemini Add user authentication with OAuth2
# Gemini orchestrator spawns 4 Sonnet agents for exploration
```

### Explicit Simple Mode
```bash
/plan:with_gemini "Refactor authentication (800 LOC)" mode:simple
# Forces SIMPLE mode despite LOC estimate
```

### Leveraging Web Research
```bash
/plan:with_gemini Implement WebAssembly module loader
# Gemini may research current WASM best practices if web search enabled
```

---

## Example Output

```
🔍 Planning Mode Activated (Gemini Orchestrator + Sonnet Explorers)

Task: Add user authentication with OAuth2
Mode: SIMPLE (300 LOC estimated)
Orchestrator: Gemini 3.0 pro via Copilot
Explorers: Sonnet agents
Web Research: Enabled

📋 Phase 1: Task Understanding & Session Initialization (Gemini)
  ✓ Task parsed: Implement OAuth2 authentication flow
  ✓ SESSION_ID extracted: abc123
  🌐 Web research: Current OAuth2 best practices reviewed

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

🔬 Phase 5: Hypothesis Verification (Gemini review)
  ├─ Verifying Sonnet hypotheses (Gemini reading files)...
  ├─ Cross-referencing agent findings with web research...
  └─ Building complete mental model with Gemini perspective...
  ✅ Verification Complete

📝 Phase 6: Plan Creation (Gemini synthesis)
  ✓ Plan file created: specs/042-oauth2-auth/plan.md
  ✓ Gemini perspective applied with current best practices
  🌐 Incorporated OAuth2 security recommendations from web research

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

- **Gemini Orchestration:**
  - Gemini 3.0 pro handles task understanding, agent coordination, verification, synthesis
  - Uses OpenCode's Copilot integration for Gemini model access
  - Provides Gemini's unique perspective on planning and code patterns
  - Multimodal capabilities for enhanced understanding
  - Different strengths than Claude or GPT for certain types of analysis

- **Sonnet Exploration:**
  - Spawns 4 Sonnet agents via Task tool for parallel discovery
  - Fast, cost-effective exploration phase
  - Sonnet excels at quick codebase pattern recognition
  - Parallel execution keeps total time low (15-35 seconds)

- **Web Research Capabilities:**
  - Gemini may have access to Google Search (if enabled in Copilot)
  - Can research current best practices, documentation, security advisories
  - Augments codebase exploration with external knowledge
  - Especially valuable for newer technologies or evolving standards
  - Note: Web research availability depends on Copilot configuration

- **Hybrid Architecture Benefits:**
  - **Gemini Planning**: Strategic thinking, synthesis, multimodal understanding, web research
  - **Sonnet Exploration**: Fast parallel discovery, pattern recognition
  - **Best of Both**: Combines strengths of different models
  - **Cost Efficient**: Expensive Gemini for high-value tasks, cheaper Sonnet for exploration
  - **Knowledge Augmentation**: External web research complements code analysis

- **Intelligent Fallback:**
  - Primary: 4 Sonnet agents in parallel
  - Fallback 1: 4 Gemini agents in parallel (if Sonnet unavailable)
  - Fallback 2: Other available models (GPT, Haiku, etc.)
  - Fallback 3: Gemini self-exploration (inline, no agents, + web research)
  - Automatically selects best available option

- **Performance:**
  - Exploration: ~15-35 seconds (4 Sonnet agents)
  - Verification: ~15-30 seconds (Gemini + optional web research)
  - Plan creation: ~10-20 seconds (Gemini)
  - **Total**: ~40-85 seconds (may be longer with extensive web research)

- **When to Use:**
  - Want Gemini's perspective on planning and synthesis
  - Implementing newer technologies (benefit from web research)
  - Need current best practices and security recommendations
  - Multimodal understanding might help
  - Need fast parallel exploration (Sonnet)
  - Cost-effective hybrid approach
  - Comparing different AI perspectives
  - Have OpenCode with Copilot configured for Gemini

- **Integration:**
  - Works with spec folder system (Phase 2)
  - Memory context enables session continuity (Phases 3 & 8)
  - Plans feed into `/spec_kit:implement` workflow
  - Can be used alongside `/plan:with_claude` or `/plan:with_gpt` for comparison

- **Copilot Requirements:**
  - OpenCode with Copilot integration enabled
  - Copilot subscription with Gemini model access
  - Proper model routing configuration in OpenCode
  - Ideally, access to both Gemini and Claude models for full functionality
  - Optional: Google Search integration for web research

---

**Remember**: This command uses **Gemini as the orchestrator** (planning, verification, synthesis, web research) with **Sonnet as parallel explorers** (fast codebase discovery). The hybrid approach combines Gemini's research and multimodal capabilities with Sonnet's exploration speed and cost-effectiveness.
