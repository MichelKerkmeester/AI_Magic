---
name: workflows-planning
description: Hybrid orchestrator + 4-agent parallel exploration for comprehensive planning. Supports single-model (Claude) and hybrid architectures (GPT/Gemini orchestrators with Sonnet explorers). Used by plan commands (/plan:with_claude_code in Claude Code; /plan:with_claude, /plan:with_gpt, /plan:with_gemini in OpenCode). (project)
allowed-tools: [Read, Write, Task, Glob, Grep, AskUserQuestion]
version: 3.0.0
---

# Workflows Planning - Multi-Model Parallel Exploration

Platform-agnostic planning workflow supporting 4-agent parallel codebase exploration with multiple AI models. Core workflow used by all `/plan:*` commands across Claude Code and OpenCode platforms.

**Integration**: Invoked by spec_kit workflows (step_6_planning), slash commands, or manually via planning keywords.

---

## 1. 🎯 WHEN TO USE

### Navigation Guide

**This file (SKILL.md)**: Core workflow and activation configuration

**Reference Files** (workflow patterns):
- [exploration_workflow.md](./references/exploration_workflow.md) – 4-agent exploration process and verification

**Assets** (templates):
- [agent_prompts.md](./assets/agent_prompts.md) – Agent prompt templates (model-agnostic)

### Activation Triggers

**Auto-Invoked By**:
- spec_kit:plan workflows (step_6_planning)
- spec_kit:complete workflows (step_6_planning)
- Keywords: "plan with exploration", "parallel planning", "comprehensive plan"

**Slash Commands Using This Workflow**:
- **Claude Code**: `/plan:with_claude_code` (Opus orchestrator, Sonnet explorers)
- **OpenCode**: `/plan:with_claude` (Claude orchestrator, Claude explorers)
- **OpenCode**: `/plan:with_gpt` (GPT orchestrator, Sonnet explorers via Copilot)
- **OpenCode**: `/plan:with_gemini` (Gemini 3.0 pro orchestrator, Sonnet explorers via Copilot)

**Manual Invocation**:
- Complex features requiring codebase understanding
- Tasks needing verified architecture knowledge
- When planning confidence is low without exploration

**This skill should NOT be used for**:
- Simple typo fixes or trivial changes
- Tasks where codebase structure is already well understood
- Time-sensitive changes where exploration overhead is too high

**Key Characteristics**:
- **Triggering**: Via spec_kit step_6, slash commands, or manual invocation
- **Agents**: 4 parallel Explore agents (model varies by command/platform)
- **Verification**: Claude-based hypothesis validation (consistent across all variants)
- **Output**: plan.md using plan_template.md structure
- **Fallback**: Graceful degradation if agent spawning fails

---

## 2. 🧭 SMART ROUTING

```python
def route_planning_approach(task):
    # Determine if parallel exploration is beneficial
    if task.complexity >= "medium":
        if task.requires_architecture_understanding:
            return spawn_exploration_agents()  # Full 4-agent exploration
        elif task.requires_pattern_discovery:
            return spawn_feature_agent_only()  # Targeted exploration

    # Fallback to inline planning
    return inline_planning()

# Exploration triggers:
# - "plan with exploration", "parallel planning", "comprehensive plan"
# - "explore and plan", "deep analysis plan"
# - Multi-file changes affecting architecture

# Output: specs/###-feature/plan.md (using plan_template.md)
```

---

## 3. 🗂️ PLATFORM & MODEL SUPPORT

### Supported Platforms & Models

| Platform | Command | Orchestrator | Explorers | Architecture Type |
|----------|---------|--------------|-----------|-------------------|
| **Claude Code** | /plan:with_claude_code | Opus | Sonnet | Hybrid (Opus planning + Sonnet exploration) |
| **OpenCode** | /plan:with_claude | Claude | Claude | Single-model (Claude throughout) |
| **OpenCode** | /plan:with_gpt | **GPT** | **Sonnet** | **Hybrid (GPT planning + Sonnet exploration)** |
| **OpenCode** | /plan:with_gemini | **Gemini 3.0 pro** | **Sonnet** | **Hybrid (Gemini planning + Sonnet exploration)** |

### Hybrid Architecture Philosophy (v3.0)

**Hybrid Commands** (with_claude_code, with_gpt, with_gemini):
- **Orchestrator**: Expensive, sophisticated model handles high-value tasks
  - Task understanding and parsing
  - Hypothesis verification by reading code
  - Plan synthesis and generation
  - Final quality control
- **Explorers**: Fast, cost-effective Sonnet agents for parallel discovery
  - Quick codebase pattern recognition
  - Parallel execution (4 agents simultaneously)
  - Returns hypotheses for orchestrator to verify
- **Benefit**: Best of both worlds - sophisticated planning + fast exploration

**Single-Model Command** (with_claude):
- **Orchestrator**: Claude handles all tasks
- **Explorers**: Claude agents (consistent model throughout)
- **Benefit**: Single-model consistency, proven quality

### Intelligent Fallback (Hybrid Commands)

If Sonnet explorers unavailable, hybrid commands gracefully degrade:
1. **Primary**: Spawn 4 Sonnet agents (fast, cheap)
2. **Fallback 1**: Spawn 4 orchestrator model agents (GPT or Gemini)
3. **Fallback 2**: Try other available models
4. **Fallback 3**: Orchestrator performs self-exploration (inline Glob/Grep/Read)

Result: Always produces a plan, adapts to available resources.

### Why Hybrid Architecture?

1. **Cost Optimization**: Expensive models for planning, cheap Sonnet for exploration
2. **Speed**: Sonnet's fast parallel discovery keeps total time low
3. **Alternative Perspectives**: GPT/Gemini planning provides different insights
4. **Web Research**: Gemini can augment with Google Search (if enabled)
5. **Reliability**: Multi-tier fallback ensures plans always generated
6. **Model Strengths**: Match model capabilities to task requirements

---

## 4. 🛠️ HOW TO USE

### Automatic Invocation (via spec_kit)

**Most Common Usage**: spec_kit workflows automatically invoke this skill in step_6_planning.

**What Happens**:
1. spec_kit reaches step_6_planning phase
2. Skill tool invokes `workflows-planning`
3. 4 Explore agents spawn in parallel (model depends on command/platform)
4. Agents return findings (files, patterns, hypotheses)
5. Orchestrator (Claude) verifies hypotheses by reading identified files
6. plan.md created using plan_template.md + verified findings
7. Control returns to spec_kit workflow

**Fallback**: If agent spawning fails, spec_kit uses inline planning logic.

### Via Slash Commands

**Most Direct Usage**: Use platform-specific slash commands that invoke this workflow.

**Claude Code**:
```bash
/plan:with_claude_code Add user authentication
# Uses Opus orchestrator + Sonnet explorers
```

**OpenCode**:
```bash
# Default (Claude explorers)
/plan:with_claude Add user authentication

# Alternative: GPT explorers via Copilot
/plan:with_gpt Add user authentication

# Alternative: Gemini explorers via Copilot (+ potential web research)
/plan:with_gemini Add user authentication
```

### Manual Invocation (Advanced)

**When to Use**:
- Need comprehensive planning outside spec_kit workflow
- Want parallel exploration before spec creation
- Complex task requiring verified architecture understanding

**Process**:

1. **Invoke Skill**:
   ```
   Skill tool: skill="workflows-planning"
   ```

2. **Provide Context**:
   - Task description (what needs to be accomplished)
   - Spec folder path (where plan.md will be created)
   - Model preference (optional, defaults to Claude)

3. **Wait for Exploration**:
   - 4 agents explore codebase in parallel
   - ~15-40 seconds for exploration phase (varies by model)
   - Orchestrator verifies findings

4. **Review Output**:
   - plan.md created at spec_folder_path
   - Contains verified architectural findings
   - Integration points documented
   - Test patterns identified

### Inputs & Outputs

**Inputs**:
```yaml
task_description: string       # What needs to be accomplished
spec_folder_path: string       # From .spec-active marker or user input
model_preference: string       # Optional: "sonnet" | "gpt" | "gemini-3.0-pro"
```

**Outputs**:
```yaml
plan.md: file                  # Technical implementation plan at spec_folder_path
exploration_summary:           # Digest of agent findings (embedded in plan)
model_used: string             # Which model was used for exploration
```

---

## 5. ⚙️ IMPLEMENTATION STEPS

### Phase 1: Agent Spawning (Parallel)

Spawn 4 Explore agents simultaneously using Task tool:

```yaml
agents:
  architecture_explorer:
    model: <varies>  # "sonnet" | "gpt" | "gemini-3.0-pro"
    subagent_type: "Explore"
    focus: "Project structure, file organization, patterns"
    purpose: "Understand overall architecture"

  feature_explorer:
    model: <varies>
    subagent_type: "Explore"
    focus: "Similar features, related patterns"
    purpose: "Find reusable patterns"

  dependency_explorer:
    model: <varies>
    subagent_type: "Explore"
    focus: "Imports, modules, affected areas"
    purpose: "Identify integration points"

  test_explorer:
    model: <varies>
    subagent_type: "Explore"
    focus: "Test patterns, testing infrastructure"
    purpose: "Understand verification approach"
```

**Agent Spawn Pattern (Platform-Specific)**:

**Claude Code**:
```javascript
Task({
  subagent_type: "Explore",
  model: "sonnet",  // Fast, cost-effective Claude exploration
  description: "Architecture exploration",
  prompt: "[exploration prompt from agent_prompts.md]"
})
```

**OpenCode with Claude**:
```javascript
Task({
  subagent_type: "Explore",
  // No model parameter - uses default Claude
  description: "Architecture exploration",
  prompt: "[exploration prompt from agent_prompts.md]"
})
```

**OpenCode with GPT (via Copilot)**:
```javascript
Task({
  subagent_type: "Explore",
  model: "gpt-4o",  // GPT via Copilot integration
  description: "Architecture exploration",
  prompt: "[exploration prompt from agent_prompts.md]"
})
```

**OpenCode with Gemini (via Copilot)**:
```javascript
Task({
  subagent_type: "Explore",
  model: "gemini-3.0-pro",  // Gemini via Copilot integration
  description: "Architecture exploration",
  prompt: "[exploration prompt from agent_prompts.md]"
})
```

**Parallel Execution**: All 4 agents spawn in single message with multiple Task tool calls.

### Phase 2: Hypothesis Verification

After agents return, orchestrator (always Claude) verifies their findings:

1. **Read Identified Files**: Use file paths from agent findings
2. **Cross-Check Hypotheses**: Verify or refute each hypothesis
3. **Resolve Conflicts**: If agents disagree, read more files to clarify
4. **Build Mental Model**: Document verified understanding

**Verification Checklist**:
- [ ] All agent hypotheses verified or refuted
- [ ] Conflicting hypotheses resolved or documented
- [ ] At least 80% of identified files read
- [ ] Mental model includes architecture, affected components, integration points, risks

**Why Claude Always Verifies**:
- Consistent verification quality across all model variants
- Deep reasoning capabilities for hypothesis validation
- Already has full context as orchestrator
- Ensures no unverified speculation in plans

### Phase 3: Plan Creation

Generate plan.md using verified findings:

1. **Load Template**: Read plan_template.md (platform-specific path)
2. **Fill Sections**: Populate each section with verified findings
3. **Remove Placeholders**: Replace all `[PLACEHOLDER]` and `[YOUR_VALUE_HERE:]` text
4. **Add File References**: Include paths with line numbers (format: `path/to/file.ts:123`)
5. **Write Plan**: Save to `{spec_folder_path}/plan.md`

**Section Sources**:
| Section | Primary Source |
|---------|---------------|
| 1. OBJECTIVE | Task description + verified findings |
| 2. QUALITY GATES | Test Explorer findings |
| 3. PROJECT STRUCTURE | Architecture Explorer findings |
| 4. IMPLEMENTATION PHASES | All agent findings + integration points |
| 5. TESTING STRATEGY | Test Explorer findings |
| 6. SUCCESS METRICS | Derived from objectives |
| 7. RISKS & MITIGATIONS | Risk assessment from verification |
| 8. DEPENDENCIES | Dependency Explorer findings |
| 9. COMMUNICATION | Standard review checkpoints |
| 10. REFERENCES | Spec files + agent findings |

---

## 6. 📝 AGENT PROMPT TEMPLATES

See [assets/agent_prompts.md](./assets/agent_prompts.md) for full prompt templates.

**Quick Reference (Model-Agnostic)**:

```yaml
architecture_explorer: |
  Explore the codebase to find architectural patterns relevant to: {task_description}

  Return:
  1. Your hypothesis about how the project is organized
  2. Full paths to all relevant files (e.g., /path/to/file.ts:lineNumber)
  3. Any patterns you noticed (file organization, module structure, etc.)

  Do NOT draw conclusions - just report findings.

feature_explorer: |
  Explore the codebase to find similar features or related patterns for: {task_description}
  [... returns hypothesis, file paths, patterns ...]

dependency_explorer: |
  Explore the codebase to find dependencies and integration points for: {task_description}
  [... returns hypothesis, file paths, patterns ...]

test_explorer: |
  Explore the codebase to find test patterns and testing infrastructure.
  [... returns hypothesis, file paths, patterns ...]
```

**Note**: Prompts are identical across all models. Different models may find different patterns or have different strengths, but use the same exploration instructions.

---

## 7. 🔄 GRACEFUL DEGRADATION

### Fallback Scenarios

| Scenario | Fallback Action |
|----------|-----------------|
| Task tool unavailable | Return control to caller, use inline planning |
| Agent spawning fails | Attempt single-agent exploration, then inline |
| Agent timeout (>60s) | Use partial results + inline planning |
| No relevant files found | Document limitation, proceed with available info |
| Copilot unavailable (OpenCode) | Fall back to Claude explorers |
| Model not accessible | Use default Claude explorers |

### Fallback Logic

```yaml
on_skill_invocation:
  try:
    spawn_4_agents_parallel(model: preferred_model)
    verify_findings()
    create_plan_md()
  catch:
    agent_spawn_failed:
      action: "Return control to caller with fallback flag"
      message: "Agent spawning unavailable, use inline planning"
    model_not_available:
      action: "Fall back to default Claude explorers"
      message: "Requested model not accessible, using Claude"
    partial_results:
      action: "Use available findings, note incomplete exploration"
```

---

## 8. 📖 RULES

### ✅ ALWAYS
- Spawn agents in parallel (single message, multiple Task calls)
- Specify model parameter when using GPT/Gemini (OpenCode + Copilot)
- Verify agent hypotheses before including in plan
- Use plan_template.md structure for output
- Include file paths with line numbers (format: `path:lineNumber`)
- Document unverified hypotheses as uncertainties
- Use Claude for verification (consistent quality)

### ❌ NEVER
- Include unverified hypotheses as facts
- Skip verification phase even if agents agree
- Create plan without reading identified files
- Leave placeholder text in final plan.md
- Block for more than 90 seconds total (planning phase limit)
- Mix models within same exploration phase (all 4 agents use same model)

### ⚠️ ESCALATE IF
- All 4 agents fail to spawn
- Verification reveals contradictory architecture
- Task scope is unclear after exploration
- No relevant files identified by any agent

---

## 9. 🎓 SUCCESS CRITERIA

**Task complete when**:
- [ ] 4 Explore agents spawned and returned findings (any supported model)
- [ ] Agent hypotheses verified by reading identified files
- [ ] plan.md created at spec_folder_path
- [ ] All template sections filled with verified content
- [ ] No placeholder text remaining
- [ ] File paths include line numbers

**Performance**:
- [ ] Exploration phase: ≤60 seconds (varies by model)
- [ ] Total planning phase: ≤90 seconds
- [ ] At least 10-30 files identified across agents

**Model-Specific Notes**:
- Claude (Sonnet): Typically 15-30 seconds exploration
- GPT (via Copilot): Typically 20-35 seconds exploration
- Gemini (via Copilot): Typically 20-40 seconds (may include web research)

---

## 10. 🔗 INTEGRATION POINTS

### spec_kit Integration

**Invocation Point**: step_6_planning in all spec_kit YAML workflows

**Integration Pattern**:
```yaml
step_6_planning:
  skill_invocation:
    condition: "Always invoke for enhanced planning"
    tool: Skill
    parameter: skill="workflows-planning"
    inputs:
      task_description: "$user_inputs.request"
      spec_folder_path: "$spec_folder"
      model_preference: "$DEFAULT"  # Or user-specified
    fallback:
      on_failure: "Use inline planning logic"
```

**Output Compatibility**:
- plan.md uses same template as spec_kit inline planning
- Memory files compatible between workflows
- spec_kit:implement reads plan.md successfully

### Slash Command Integration

**Command Files**:
- `.claude/commands/plan/with_claude_code.md` (Claude Code, Sonnet explorers)
- `.opencode/command/plan/with_claude.md` (OpenCode, Claude explorers)
- `.opencode/command/plan/with_gpt.md` (OpenCode, GPT explorers via Copilot)
- `.opencode/command/plan/with_gemini.md` (OpenCode, Gemini explorers via Copilot)

All commands use this workflow with different model parameters.

### Skill Tool Pattern

**Invocation**:
```
Skill tool: skill="workflows-planning"
```

**skill-rules.json Entry**:
```json
"workflows-planning": {
  "type": "workflow",
  "enforcement": "suggest",
  "priority": "high",
  "description": "4-agent parallel exploration for comprehensive planning (multi-model support)",
  "promptTriggers": {
    "keywords": ["plan with exploration", "parallel planning", "comprehensive plan"]
  }
}
```

---

## 11. 📚 QUICK REFERENCE

**Invocation**: `Skill(skill: "workflows-planning")`

**Output Location**: `specs/###-feature/plan.md`

**Key Components**:
1. **4 Agents**: Architecture, Feature, Dependency, Test (model varies)
2. **Verification**: Claude reads files to verify hypotheses (consistent)
3. **Plan Generation**: Template-based with verified findings

**Timing (by model)**:
- **Claude (Sonnet)**: ~15-30s exploration, ~40-75s total
- **GPT (via Copilot)**: ~20-35s exploration, ~45-85s total
- **Gemini (via Copilot)**: ~20-40s exploration, ~45-90s total

**Data Flow**:
```
Task Description → 4 Parallel Agents (model varies) → Findings →
Claude Verification → plan.md
```

**Platform Compatibility**:
- ✅ Claude Code (Opus orchestrator, Sonnet explorers)
- ✅ OpenCode (Claude orchestrator, Claude/GPT/Gemini explorers)

---

## 12. 🌐 PLATFORM-SPECIFIC NOTES

### Claude Code

**Characteristics**:
- Opus orchestrator for task understanding and verification
- Sonnet explorers for fast, cost-effective exploration
- Direct model access (no Copilot routing)
- Model parameter: `model: "sonnet"`

**Commands**: `/plan:with_claude_code`

### OpenCode

**Characteristics**:
- Hybrid architecture with different orchestrators per command
- Multiple explorer options via Copilot routing
- Model parameter varies: none (Claude), `"gpt"`, `"gemini-3.0-pro"`

**Commands**:
- `/plan:with_claude` - Claude orchestrator, Claude explorers
- `/plan:with_gpt` - GPT orchestrator, Sonnet explorers via Copilot
- `/plan:with_gemini` - Gemini 3.0 pro orchestrator, Sonnet explorers via Copilot

**Copilot Integration**:
- Requires OpenCode Copilot integration enabled
- GitHub Copilot subscription for GPT access
- Extended Copilot config for Gemini access
- Routing handled automatically by OpenCode

---

**Remember**: This skill is platform-agnostic and model-flexible. It enhances planning quality through evidence-based exploration regardless of which AI model performs the exploration. Claude always verifies findings for consistent quality across all variants.

**Version 2.0 Changes**: Added multi-model support (Claude, GPT, Gemini), platform awareness (Claude Code vs OpenCode), and integration with all 4 slash command variants.
