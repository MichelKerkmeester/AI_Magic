---
name: workflows-planning
description: 4-agent parallel exploration for comprehensive planning. Spawns Architecture/Feature/Dependency/Test Sonnet explorers, synthesizes findings, and generates verified plan.md. Auto-triggered by spec_kit step_6 or manually via planning keywords. (project)
allowed-tools: [Read, Write, Task, Glob, Grep, AskUserQuestion]
version: 1.0.0
---

# Workflows Plan Claude - Parallel Exploration Planning

Comprehensive planning through 4-agent parallel codebase exploration, hypothesis verification, and structured plan generation. Creates plan.md using verified findings rather than assumptions.

**Integration**: Invoked by spec_kit workflows (step_6_planning) or manually with planning keywords.

---

## 1. 🎯 WHEN TO USE

### Navigation Guide

**This file (SKILL.md)**: Core workflow and activation configuration

**Reference Files** (workflow patterns):
- [exploration_workflow.md](./references/exploration_workflow.md) – 4-agent exploration process and verification

**Assets** (templates):
- [agent_prompts.md](./assets/agent_prompts.md) – Sonnet agent prompt templates

### Activation Triggers

**Auto-Invoked By**:
- spec_kit:plan workflows (step_6_planning)
- spec_kit:complete workflows (step_6_planning)
- Keywords: "plan with exploration", "parallel planning", "comprehensive plan"

**Manual Invocation**:
- Complex features requiring codebase understanding
- Tasks needing verified architecture knowledge
- When planning confidence is low without exploration

**This skill should NOT be used for**:
- Simple typo fixes or trivial changes
- Tasks where codebase structure is already well understood
- Time-sensitive changes where exploration overhead is too high

**Key Characteristics**:
- **Triggering**: Via spec_kit step_6 or manual invocation
- **Agents**: 4 parallel Sonnet Explore agents (Architecture/Feature/Dependency/Test)
- **Verification**: Opus-level reasoning for hypothesis validation
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

## 3. 🗂️ REFERENCES

### Core Framework & Workflows
| Document | Purpose | Key Insight |
|----------|---------|-------------|
| **4-Agent Exploration** | Parallel codebase discovery | **Architecture/Feature/Dependency/Test agents** |
| **Hypothesis Verification** | Cross-check agent findings | **Evidence over assumptions** |
| **Plan Creation** | Structured plan generation | **Template-based with verified findings** |

### Bundled Resources
| Document | Purpose | Key Insight |
|----------|---------|-------------|
| **references/exploration_workflow.md** | Full exploration process | Phase-by-phase agent coordination |
| **assets/agent_prompts.md** | Sonnet agent templates | Copy-ready prompt templates |

---

## 4. 🛠️ HOW TO USE

### Automatic Invocation (via spec_kit)

**Most Common Usage**: spec_kit workflows automatically invoke this skill in step_6_planning.

**What Happens**:
1. spec_kit reaches step_6_planning phase
2. Skill tool invokes `workflows-planning`
3. 4 Sonnet Explore agents spawn in parallel
4. Agents return findings (files, patterns, hypotheses)
5. Main agent verifies hypotheses by reading identified files
6. plan.md created using plan_template.md + verified findings
7. Control returns to spec_kit workflow

**Fallback**: If agent spawning fails, spec_kit uses inline planning logic.

### Manual Invocation

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

3. **Wait for Exploration**:
   - 4 agents explore codebase in parallel
   - ~15-30 seconds for exploration phase
   - Main agent verifies findings

4. **Review Output**:
   - plan.md created at spec_folder_path
   - Contains verified architectural findings
   - Integration points documented
   - Test patterns identified

### Inputs & Outputs

**Inputs**:
```yaml
task_description: string  # What needs to be accomplished
spec_folder_path: string  # From .spec-active marker or user input
```

**Outputs**:
```yaml
plan.md: file             # Technical implementation plan at spec_folder_path
exploration_summary:      # Digest of agent findings (embedded in plan)
```

---

## 5. ⚙️ IMPLEMENTATION STEPS

### Phase 1: Agent Spawning (Parallel)

Spawn 4 Sonnet Explore agents simultaneously using Task tool:

```yaml
agents:
  architecture_explorer:
    model: "sonnet"
    subagent_type: "Explore"
    focus: "Project structure, file organization, patterns"
    purpose: "Understand overall architecture"

  feature_explorer:
    model: "sonnet"
    subagent_type: "Explore"
    focus: "Similar features, related patterns"
    purpose: "Find reusable patterns"

  dependency_explorer:
    model: "sonnet"
    subagent_type: "Explore"
    focus: "Imports, modules, affected areas"
    purpose: "Identify integration points"

  test_explorer:
    model: "sonnet"
    subagent_type: "Explore"
    focus: "Test patterns, testing infrastructure"
    purpose: "Understand verification approach"
```

**Agent Spawn Pattern**:
```javascript
Task({
  subagent_type: "Explore",
  model: "sonnet",  // REQUIRED: Fast, cost-effective exploration
  description: "Architecture exploration",
  prompt: "[exploration prompt from agent_prompts.md]"
})
```

**Parallel Execution**: All 4 agents spawn in single message with multiple Task tool calls.

### Phase 2: Hypothesis Verification

After agents return, verify their findings:

1. **Read Identified Files**: Use file paths from agent findings
2. **Cross-Check Hypotheses**: Verify or refute each hypothesis
3. **Resolve Conflicts**: If agents disagree, read more files to clarify
4. **Build Mental Model**: Document verified understanding

**Verification Checklist**:
- [ ] All agent hypotheses verified or refuted
- [ ] Conflicting hypotheses resolved or documented
- [ ] At least 80% of identified files read
- [ ] Mental model includes architecture, affected components, integration points, risks

### Phase 3: Plan Creation

Generate plan.md using verified findings:

1. **Load Template**: Read `.claude/commands/spec_kit/assets/templates/plan_template.md`
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

**Quick Reference**:

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

---

## 7. 🔄 GRACEFUL DEGRADATION

### Fallback Scenarios

| Scenario | Fallback Action |
|----------|-----------------|
| Task tool unavailable | Return control to spec_kit inline planning |
| Agent spawning fails | Attempt single-agent exploration, then inline |
| Agent timeout (>60s) | Use partial results + inline planning |
| No relevant files found | Document limitation, proceed with available info |

### Fallback Logic

```yaml
on_skill_invocation:
  try:
    spawn_4_agents_parallel()
    verify_findings()
    create_plan_md()
  catch:
    agent_spawn_failed:
      action: "Return control to caller with fallback flag"
      message: "Agent spawning unavailable, use inline planning"
    partial_results:
      action: "Use available findings, note incomplete exploration"
```

---

## 8. 📖 RULES

### ✅ ALWAYS
- Spawn agents in parallel (single message, multiple Task calls)
- Specify `model: "sonnet"` for all Explore agents
- Verify agent hypotheses before including in plan
- Use plan_template.md structure for output
- Include file paths with line numbers (format: `path:lineNumber`)
- Document unverified hypotheses as uncertainties

### ❌ NEVER
- Include unverified hypotheses as facts
- Skip verification phase even if agents agree
- Create plan without reading identified files
- Leave placeholder text in final plan.md
- Block for more than 90 seconds total (planning phase limit)

### ⚠️ ESCALATE IF
- All 4 agents fail to spawn
- Verification reveals contradictory architecture
- Task scope is unclear after exploration
- No relevant files identified by any agent

---

## 9. 🎓 SUCCESS CRITERIA

**Task complete when**:
- [ ] 4 Sonnet agents spawned and returned findings
- [ ] Agent hypotheses verified by reading identified files
- [ ] plan.md created at spec_folder_path
- [ ] All template sections filled with verified content
- [ ] No placeholder text remaining
- [ ] File paths include line numbers

**Performance**:
- [ ] Exploration phase: ≤60 seconds
- [ ] Total planning phase: ≤90 seconds
- [ ] At least 10-30 files identified across agents

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
    fallback:
      on_failure: "Use inline planning logic"
```

**Output Compatibility**:
- plan.md uses same template as spec_kit inline planning
- Memory files compatible between workflows
- spec_kit:implement reads plan.md successfully

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
  "description": "4-agent parallel exploration for comprehensive planning",
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
1. **4 Agents**: Architecture, Feature, Dependency, Test (all Sonnet)
2. **Verification**: Read files to verify hypotheses
3. **Plan Generation**: Template-based with verified findings

**Timing**:
- Exploration: ~15-30 seconds
- Verification: ~15-30 seconds
- Plan creation: ~15-30 seconds
- **Total**: ≤90 seconds

**Data Flow**:
```
Task Description → 4 Parallel Agents → Findings → Verification → plan.md
```

---

**Remember**: This skill enhances planning quality through evidence-based exploration. When in doubt about codebase structure, invoke this skill for verified architectural understanding.
