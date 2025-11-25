---
name: create-parallel-sub-agents
description: Dynamic agent orchestration system that autonomously creates and dispatches specialized sub-agents with pre-selected skill subsets for complex multi-step tasks
allowed-tools: [Task, Read, Grep, Glob]
version: 1.0.0
---

# Agent Orchestrator - Dynamic Sub-Agent Creation & Dispatch

Autonomous agent orchestration system that analyzes task complexity, receives skill recommendations from hooks, and intelligently dispatches ephemeral sub-agents for efficient parallel or specialized execution.

**Core principle**: Analyze → Determine dispatch value → Create sub-agents → Dispatch → Integrate results = efficient complex task execution.

> **Implementation Note**: The `orchestrate-skill-validation.sh` hook operates in **informational mode** (always exits 0). It calculates complexity scores and writes recommendations to logs, but does not block operations. The AI agent reads these recommendations and makes dispatch decisions.

---

## 1. 🎯 WHEN TO USE

### Navigation Guide

**This file (SKILL.md)**: Essential overview and orchestration guidance

**Reference Files** (detailed documentation):
- [complexity_scoring.md](./references/complexity_scoring.md) - Task complexity analysis algorithm
- [skill_clustering.md](./references/skill_clustering.md) - Domain-based skill grouping logic
- [dispatch_decision.md](./references/dispatch_decision.md) - When to dispatch vs direct handling
- [sub_agent_lifecycle.md](./references/sub_agent_lifecycle.md) - Agent creation, dispatch, integration, cleanup
- [quick_reference.md](./references/quick_reference.md) - One-page decision tree

**Assets** (templates and checklists):
- [sub_agent_template.md](./assets/sub_agent_template.md) - Sub-agent specification template
- [dispatch_checklist.md](./assets/dispatch_checklist.md) - Pre-dispatch validation checklist

### Automatic Activation Triggers

**High-Value Dispatch Scenarios**:

1. **Multi-Domain Refactoring**
   - Request: "Refactor authentication system and update documentation"
   - Domains: Code (refactoring) + Docs (updating)
   - Action: Create 2 sub-agents with domain-specific skills

2. **Parallel Debugging**
   - Request: "Fix 3 independent test failures in different modules"
   - Pattern: Independent failures, parallel opportunity
   - Action: Create 3 sub-agents for parallel investigation

3. **Feature Implementation + Documentation**
   - Request: "Implement dark mode toggle and document the API"
   - Domains: Code (feature) + Docs (API documentation)
   - Action: Create 2 sub-agents with appropriate skills

4. **Complex Multi-Step Tasks**
   - Request: "Update all components to new design system, update docs, and commit"
   - Domains: Code + Docs + Git
   - Action: Create 3 sub-agents or sequence based on dependencies

### When NOT to Use

**Low-Value Dispatch (Handle Directly)**:

1. **Single File Changes**
   - Request: "Fix typo in README"
   - Complexity: < 40%
   - Action: Handle directly, no dispatch

2. **Sequential Dependencies**
   - Request: "Build project then run tests"
   - Pattern: Step B requires step A
   - Action: Handle sequentially, no parallel benefit

3. **Quick Fixes**
   - Request: "Add missing semicolon"
   - Complexity: Trivial
   - Action: Direct fix, no orchestration needed

---

## 2. 🗂️ REFERENCES

### Core Framework
| Document | Purpose | Key Insight |
|----------|---------|-------------|
| **Agent Orchestrator - Main Workflow** | Core capability and execution pattern | **Specialized auxiliary tool integration** |

### Bundled Resources
| Document | Purpose | Key Insight |
|----------|---------|-------------|
| **references/complexity_scoring.md** | Task complexity analysis algorithm (5-factor weighted scoring) | Load for complexity score calculation |
| **references/skill_clustering.md** | Domain-based skill grouping logic (code/docs/git/testing clusters) | Load for skill subset selection |
| **references/dispatch_decision.md** | When to dispatch vs direct handling (threshold-based decision tree) | Load for dispatch value determination |
| **references/sub_agent_lifecycle.md** | Agent creation, dispatch, integration, cleanup (ephemeral agent pattern) | Load for sub-agent management workflow |
| **references/quick_reference.md** | One-page decision tree for fast lookup | Load for quick navigation and decision support |
| **assets/sub_agent_template.md** | Sub-agent specification template | Load when creating sub-agent specs |
| **assets/dispatch_checklist.md** | Pre-dispatch validation checklist | Load before launching sub-agents |

### Smart Routing Logic

**Note**: The following is conceptual pseudo-code illustrating the orchestration flow. Actual implementation uses shell hooks and Claude's Task tool.

```python
# CONCEPTUAL PSEUDO-CODE - Not runnable code
def orchestrate_task(request):
    analysis = analyze_task(request)
    score = calculate_complexity(analysis)

    if score < 40:
        return execute_directly(request)
    elif score < 50:
        if ask_user_preference() == "direct":
            return execute_directly(request)

    if check_token_budget() < 0.20:
        return execute_directly(request)

    skill_groups = group_skills_by_domain(
        read_skill_recommendations(),
        analysis.domains
    )

    agents = [
        create_sub_agent(domain, skill_groups[domain])
        for domain in analysis.domains
    ]

    results = dispatch_agents(agents)

    if failure_rate(results) > 0.30:
        return execute_directly(request)

    if has_failures(results):
        results = retry_failed(results)

    return integrate_results(results)


def calculate_complexity(analysis):
    weights = {
        'domains': 30 * (0 if len(analysis.domains) == 1 else 0.5 if len(analysis.domains) == 2 else 1.0),
        'files': 25 * (0 if analysis.files <= 2 else 0.5 if analysis.files <= 5 else 1.0),
        'loc': 20 * (0 if analysis.loc < 50 else 0.5 if analysis.loc <= 200 else 1.0),
        'parallel': 15 * (0 if analysis.parallel == "none" else 0.5 if analysis.parallel == "some" else 1.0),
        'type': 10 * (0 if analysis.type == "trivial" else 0.5 if analysis.type == "moderate" else 1.0)
    }
    return round(sum(weights.values()))
```

---

## 3. 🛠️ HOW IT WORKS

### Operational Modes

This orchestrator operates in three primary modes:

**Mode 1: Task Analysis & Scoring**
- Evaluates task complexity and determines dispatch value
- Use when: Receiving multi-domain requests, task spans code + docs + git + testing, multiple independent failures to investigate, parallel execution opportunities exist
- See: [complexity_scoring.md](./references/complexity_scoring.md)

**Mode 2: Intelligent Sub-Agent Creation**
- Creates ephemeral agents with targeted skill subsets
- Use when: Complexity score >= 50% (high complexity), 2+ distinct domains identified, hook recommendations available, parallel execution beneficial
- See: [skill_clustering.md](./references/skill_clustering.md), [sub_agent_lifecycle.md](./references/sub_agent_lifecycle.md)

**Mode 3: Direct Task Handling**
- Handles tasks directly without sub-agent overhead
- Use when: Complexity score < 40% (low complexity), single domain task, sequential dependencies exist, quick fixes or trivial updates
- See: [dispatch_decision.md](./references/dispatch_decision.md)

### Step 1: Task Analysis

```markdown
1. Parse user request
2. Identify domains (code, docs, git, testing, etc.)
3. Count affected files/components
4. Check for parallel execution opportunities
5. Calculate complexity score (0-100%)
```

### Step 2: Hook Integration

The `orchestrate-skill-validation.sh` hook **WRITES** complexity analysis and recommendations to logs:

```markdown
Hook Output Locations:
1. `.claude/hooks/logs/orchestrator.log` - Complexity scores and dispatch decisions
2. `.claude/hooks/logs/skill-recommendations.log` - Skill recommendations by priority

AI Agent Reads:
1. Parse skill-recommendations.log for prioritized skills:
   - 🔴 MANDATORY (critical priority)
   - 🟡 HIGH PRIORITY (high priority)
   - 🟠 MEDIUM (medium priority)
2. Filter skills relevant to identified domains
3. Group skills by domain clustering
```

### Step 3: Dispatch Decision

```markdown
IF complexity_score >= 50% AND domains >= 2:
  → DISPATCH sub-agents
ELSE IF complexity_score < 40% OR domains == 1:
  → HANDLE directly
ELSE (40-49%):
  → COLLABORATIVE decision (ask user preference)
```

### Step 4: Sub-Agent Creation

```markdown
For each domain:
  1. Select relevant skills from hook recommendations
  2. Define allowed tools (minimal subset needed)
  3. Create agent specification:
     - description: Clear task description
     - subagent_type: "general-purpose" or specific type
     - model: "haiku" for simple tasks, inherit for complex
     - prompt: Detailed task with context
     - skills: Domain-specific skill subset
     - timeout: Default 5 minutes
```

Use the provided assets to keep specs consistent:
- Fill out [`sub_agent_template.md`](./assets/sub_agent_template.md) for each dispatched role so every field above is captured.
- Run the [`dispatch_checklist.md`](./assets/dispatch_checklist.md) before launch to confirm skills/tools/timeouts match the task scope.

### Step 5: Dispatch & Integration

```markdown
1. Dispatch sub-agents via Task tool (parallel when possible)
2. Monitor progress (check for timeout/errors)
3. Collect results from each sub-agent
4. Integrate results into main context
5. Report combined outcome to user
6. Clean up (agents are ephemeral, no persistence)
```

### Step 6: Mandatory Dispatch Announcement

> **ENFORCEMENT**: When complexity ≥50% + ≥2 domains, the hook BLOCKS (exit 1) until dispatch or override.

When dispatching parallel sub-agents via Task tool, you **MUST** announce visibly:

**Before Dispatch (REQUIRED)**:
```
🚀 LAUNCHING PARALLEL SUB-AGENTS

Task Complexity: [score]% | Domains: [count]
Estimated Speedup: [X]x faster than sequential

Dispatching [N] agents:
1. [domain]_agent
   - Task: [3-10 word description]
   - Skills: [skill1, skill2]
   - Model: [haiku/sonnet]

2. [domain]_agent
   - Task: [3-10 word description]
   - Skills: [skill1, skill2]
   - Model: [haiku/sonnet]

Monitoring progress...
```

**After Completion (REQUIRED)**:
```
✅ PARALLEL DISPATCH COMPLETE

Results:
- [domain]_agent: [status] ([duration])
- [domain]_agent: [status] ([duration])

Total Time: [X] min (vs ~[Y] min sequential)
Speedup Achieved: [Z]x
```

**Override Options**:
If you want to handle directly instead of dispatching, say one of:
- "proceed anyway"
- "skip dispatch"
- "handle directly"
- "override dispatch"

### Error Handling Patterns

> **Note**: These are recommended patterns for the AI agent to follow when dispatching sub-agents. The hook enforces dispatch requirements (exit 1) but error recovery is agent-managed.

**Sub-Agent Failures** *(AI Agent Guidelines)*:
```markdown
IF sub-agent times out:
  → Log timeout, return partial results
  → Mark tasks incomplete for main agent
  → Continue with other agents

IF sub-agent errors:
  → Log error details
  → Attempt retry once (if time allows)
  → Fall back to direct handling if critical

IF multiple failures (>30%):
  → Abort remaining dispatches
  → Switch to direct handling
  → Log failure pattern for analysis
```

**Hook System Failures**:
```markdown
IF skill-recommendations.log missing:
  → Fall back to basic skill detection
  → Use minimal skill set
  → Log warning

IF log parsing fails:
  → Use cached skill list if available
  → Default to common skills
  → Continue with degraded recommendations
```

**Resource Constraints** *(Future Enhancement)*:
```markdown
IF token budget low (<20%):
  → Cancel dispatch
  → Handle directly
  → Inform user of constraint

IF concurrent limit reached:
  → Queue agents for sequential execution
  → Or fall back to direct handling
  → Log resource constraint

Note: Token budget and concurrent limit checks are not yet
implemented in hooks. AI agents should estimate these constraints.
```

### Example Workflows

**Example 1: Multi-Domain Task (High Complexity)**

Request: "Refactor the form validation system, update the documentation, and commit the changes"

Analysis:
```
Domains: 3 (code, docs, git)
Files: ~8-10 estimated
Complexity Score: 85%
Decision: DISPATCH
```

Sub-Agents Created:
1. Code Agent: refactoring, validation patterns
2. Docs Agent: documentation updates
3. Git Agent: commit preparation

Result: Parallel execution, 60% faster than sequential

**Example 2: Simple Fix (Low Complexity)**

Request: "Fix the typo in the header comment"

Analysis:
```
Domains: 1 (code)
Files: 1
Complexity Score: 10%
Decision: DIRECT
```

Result: Handled directly, no dispatch overhead

**Example 3: Borderline Case (Medium Complexity)**

Request: "Update the API endpoints and add basic tests"

Analysis:
```
Domains: 2 (code, testing)
Files: 3-4
Complexity Score: 55%
Decision: COLLABORATIVE
```

User Prompt: "Would you like me to handle this directly or split into parallel agents for code and testing?"

---

## 4. 📖 RULES

### ✅ ALWAYS 

**ALWAYS calculate complexity score before deciding**:
- Analyze domains, file count, LOC estimate, parallel opportunities, and task type
- Use weighted formula: Domain (30%) + Files (25%) + LOC (20%) + Parallel (15%) + Type (10%)
- Reference [complexity_scoring.md](./references/complexity_scoring.md) for calculation details

**ALWAYS check token budget before dispatch** *(Future Enhancement)*:
- If budget < 20%: Fall back to direct handling
- If budget < 40%: Limit to 2 sub-agents maximum
- If budget > 40%: Normal operation (3-5 agents)
- *Note: Token budget checking is not yet implemented in hooks; this is a recommended best practice for AI agents to follow manually*

**ALWAYS use hook recommendations for skill selection**:
- Read `.claude/hooks/logs/skill-recommendations.log`
- Prioritize: MANDATORY (🔴) > HIGH PRIORITY (🟡) > MEDIUM (🟠)
- Filter by domain relevance

**ALWAYS validate sub-agent specs before dispatch**:
- Use [dispatch_checklist.md](./assets/dispatch_checklist.md)
- Verify: description, skills, tools, timeout, prompt clarity

### ❌ NEVER 

**NEVER dispatch for trivial tasks (complexity < 40%)**:
- Dispatch overhead exceeds benefit
- Handle directly for single-file changes, typos, quick fixes

**NEVER skip complexity scoring**:
- Guessing dispatch value leads to inefficient resource usage
- Always calculate score objectively

**NEVER dispatch when sequential dependencies exist**:
- "Build then test then deploy" requires sequential execution
- No parallel benefit from sub-agents

### ⚠️ ESCALATE IF

**ESCALATE IF complexity score is borderline (40-49%)**:
- Ask user preference: "Handle directly or dispatch sub-agents?"
- Explain trade-offs: simplicity vs potential speed
- Note: 50%+ with ≥2 domains auto-dispatches

**ESCALATE IF resource constraints detected mid-dispatch**:
- Token budget drops below 20%
- Inform user and fall back to direct handling

**ESCALATE IF multiple sub-agent failures occur**:
- >30% failure rate indicates systemic issue
- Switch to direct handling and report pattern

### Complexity Scoring Weights

```
Domain Count:        30% (1 domain=0, 2=0.5, 3+=1.0)
File Count:          25% (1-2=0, 3-5=0.5, 6+=1.0)
LOC Estimate:        20% (<50=0, 50-200=0.5, 200+=1.0)
Parallel Opportunity: 15% (none=0, some=0.5, high=1.0)
Task Type:           10% (trivial=0, moderate=0.5, complex=1.0)
─────────────────────────────────────────────────────
Total Score:         0-100%
```

Multiply each weight by the bucket multiplier (0 / 0.5 / 1.0) and sum, then round to the nearest whole percent.

*Example*: 3 domains (30×1.0=30) + 4 files (25×0.5=12.5) + 120 LOC (20×0.5=10) + some parallelism (15×0.5=7.5) + moderate task (10×0.5=5) → **65%**, so treat as a collaborative decision.

### Dispatch Thresholds

| Score Range | Action | Rationale |
|-------------|--------|-----------|
| 0-39% | Direct handling | Overhead exceeds benefit |
| 40-49% | Collaborative | Borderline, user preference |
| 50-100% | Auto-dispatch | Clear efficiency gain |

### Skill Priority Filtering

```
1. Start with MANDATORY (🔴) skills - always include
2. Add HIGH PRIORITY (🟡) skills - include if relevant
3. Consider MEDIUM (🟠) skills - include if space allows
4. Skip LOW priority skills - rarely needed for sub-agents
```

### Token Budget Rules *(Future Enhancement)*

```
- Check remaining context before dispatch
- If budget < 20%: Fall back to direct handling
- If budget < 40%: Limit to 2 sub-agents max
- If budget > 40%: Normal operation (3-5 agents)

Note: Token budget checking is not implemented in hooks.
These are recommended guidelines for AI agents.
```

---

## 5. 🎓 SUCCESS CRITERIA

### Dispatch Decision Quality

```markdown
✓ Complexity score calculated accurately
✓ Domains identified correctly
✓ Parallel opportunities recognized
✓ Appropriate dispatch decision made
✓ User informed of decision rationale
```

### Sub-Agent Effectiveness

```markdown
✓ Skills selected match domain needs
✓ Tools minimized to essentials
✓ Clear task description provided
✓ Appropriate timeout set
✓ Results integrated successfully
```

### Performance Metrics

```markdown
✓ Analysis time < 500ms
✓ Dispatch overhead < 2 seconds
✓ Total overhead < 10% of task time
✓ Sub-agent success rate > 90%
✓ Timeout rate < 5%
```

**Monitoring These Metrics**:
- Source raw data from `.claude/hooks/logs/orchestrator.log`; each entry already records timestamp, complexity, domains, decision, and sub-agent counts
- Use `rg "ORCHESTRATION" .claude/hooks/logs/orchestrator.log` or tailing scripts to sample runtimes, then aggregate in a spreadsheet or notebook to confirm thresholds
- Log annotations (e.g., `Timeout:` or `Sub-agent result:`) should be captured during Step 5 so trend analysis reflects actual dispatch outcomes

---

## 6. 🔗 INTEGRATION POINTS

### Hook System Integration

The orchestrator reads skill recommendations from:
```
.claude/hooks/logs/skill-recommendations.log
```

Format expected:
```
🔴 MANDATORY (Must Apply)
   • skill-name
     Description text

🟡 HIGH PRIORITY (Strongly Recommended)
   • skill-name
     Description text
```

### Task Tool Integration

Dispatches sub-agents using Task tool with:
```typescript
{
  description: "Brief task description",
  subagent_type: "general-purpose",
  model: "haiku", // or inherit
  prompt: "Detailed task instructions...",
  // Optional: resume: "agent-id" for continuation
}
```

### Logging

Orchestration decisions logged to:
```
.claude/hooks/logs/orchestrator.log
```

Format:
```
[timestamp] ORCHESTRATION DECISION
Task: [user request summary]
Complexity: [score]%
Domains: [list]
Decision: [DISPATCH|DIRECT|COLLABORATIVE]
Sub-agents: [count] ([list of types])
```

### Related Skills

**Existing Orchestrators**: `workflows-code`, `workflows-git`
**Hook System**: `.claude/hooks/UserPromptSubmit/validate-skill-activation.sh`
**Skill Rules**: `.claude/configs/skill-rules.json`

---

**Remember**: This skill operates as a dynamic orchestration system. It analyzes complexity and dispatches specialized sub-agents for efficient parallel execution.