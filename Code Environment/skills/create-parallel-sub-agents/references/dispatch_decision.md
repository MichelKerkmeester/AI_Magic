# Dispatch Decision - When to Dispatch vs Direct Handling

Dispatch only when parallel execution or specialization benefits exceed orchestration overhead - measure benefit in time saved, not tasks completed.

> **Implementation Note**: The `orchestrate-skill-validation.sh` hook operates in **informational mode** (always exits 0). It calculates complexity scores and writes recommendations to `.claude/hooks/logs/orchestrator.log`, but the AI agent makes the final dispatch decision.

**Prerequisites:** Follow [Agent Orchestrator Workflow](../SKILL.md) for complete context:
- **Complexity Scoring**: See [complexity_scoring.md](./complexity_scoring.md) for threshold calculation
- **Skill Clustering**: See [skill_clustering.md](./skill_clustering.md) for agent creation

---

## 1. 🌲 THE DECISION TREE

You MUST evaluate ALL checkpoints in order before dispatching.

```
START
  │
  ├─ [Checkpoint 1: Token Budget]
  │   │
  │   ├─ Budget < 20% → DIRECT (insufficient resources)
  │   └─ Budget ≥ 20% → Continue
  │
  ├─ [Checkpoint 2: Complexity Score]
  │   │
  │   ├─ Score < 40% → DIRECT (too simple)
  │   ├─ Score 40-49% → COLLABORATIVE (ask user)
  │   └─ Score ≥ 50% → Continue
  │
  ├─ [Checkpoint 3: Domain Count]
  │   │
  │   ├─ Domains = 1 → DIRECT (no specialization benefit)
  │   └─ Domains ≥ 2 → Continue
  │
  ├─ [Checkpoint 4: Dependencies]
  │   │
  │   ├─ Sequential only → DIRECT (no parallel benefit)
  │   └─ Parallel possible → Continue
  │
  ├─ [Checkpoint 5: Overhead Analysis]
  │   │
  │   ├─ Overhead > 30% → DIRECT (overhead too high)
  │   └─ Overhead < 30% → DISPATCH
  │
  └─ DISPATCH SUB-AGENTS
```

**Validation**: `dispatch_decision_made`

---

## 2. ✅ DISPATCH BENEFICIAL SCENARIOS

### Scenario 1: Multi-Domain Tasks
**Pattern**: Task spans 3+ distinct functional areas

❌ **WRONG - Single domain misidentified**:
```
Request: "Fix bug and add comment explaining the fix"
Analysis: 2 domains (code + documentation)
Decision: DISPATCH
→ Incorrect: Comment is trivial, not separate domain
```

✅ **RIGHT - True multi-domain**:
```
Request: "Refactor auth, update API docs, add tests, prepare PR"
Analysis: 4 domains (code, documentation, testing, git)
Decision: DISPATCH
Benefit: Parallel execution of independent domains
Expected speedup: 50-60% faster than sequential
```

**Validation**: `multi_domain_identified`


### Scenario 2: Parallel Debugging
**Pattern**: Multiple independent failures in unrelated modules

❌ **WRONG - Missing sequential dependency**:
```
Request: "Fix bug that breaks tests, then fix the tests"
Analysis: 2 bugs, parallel opportunity
Decision: DISPATCH
→ Incorrect: Tests depend on bug fix, must be sequential
```

✅ **RIGHT - True parallel opportunity**:
```
Request: "Fix failing tests in auth, payment, and shipping"
Analysis: 3 independent test suites, no dependencies
Decision: DISPATCH
Benefit: 3x faster via parallel investigation
Expected agents: 3 (one per module)
```

**Validation**: `parallel_opportunity_confirmed`


### Scenario 3: Complex Feature Implementation
**Pattern**: Large feature with separable concerns

✅ **RIGHT - Separable concerns**:
```
Request: "Implement dark mode with theme switcher, preferences, docs"
Components: UI logic, state management, persistence, documentation
Decision: DISPATCH
Benefit: Specialized agents for each component
Expected agents: 3-4
```

**Validation**: `complex_feature_identified`


### Scenario 4: Broad Codebase Analysis
**Pattern**: System-wide search and documentation

✅ **RIGHT - Wide-ranging analysis**:
```
Request: "Find all API endpoints and document their usage"
Scope: Full codebase search + documentation generation
Decision: DISPATCH
Benefit: Parallel search and documentation creation
Expected agents: 2 (search + docs)
```

**Validation**: `broad_analysis_identified`

---

## 3. ❌ DIRECT HANDLING SCENARIOS

### Scenario 1: Single File Changes
**Pattern**: Localized modifications

✅ **RIGHT - Direct for simple changes**:
```
Request: "Fix typo in README"
Scope: 1 file, 1 line
Complexity: 5%
Overhead: 2-3 seconds (>100% of task time)
Decision: DIRECT
Rationale: Overhead exceeds task duration
```

**Validation**: `single_file_identified`


### Scenario 2: Sequential Dependencies
**Pattern**: Step B requires step A completion

❌ **WRONG - Ignoring dependencies**:
```
Request: "Install dependencies, build project, run tests"
Decision: DISPATCH (3 agents in parallel)
→ Incorrect: Each step depends on previous completion
```

✅ **RIGHT - Recognizing sequence**:
```
Request: "Install dependencies, build project, run tests"
Dependencies: build needs install, tests need build
Decision: DIRECT
Rationale: No parallelization possible, overhead not justified
```

**Validation**: `sequential_dependency_identified`


### Scenario 3: Quick Fixes
**Pattern**: Trivial changes < 5 minutes

✅ **RIGHT - Direct for quick tasks**:
```
Request: "Add missing semicolon in auth.js"
Time estimate: 30 seconds
Overhead: 2-3 seconds dispatch
Decision: DIRECT
Rationale: Task too trivial for orchestration
```

**Validation**: `quick_fix_identified`


### Scenario 4: Exploratory Tasks
**Pattern**: Unclear scope requiring iteration

✅ **RIGHT - Direct for exploration**:
```
Request: "Figure out why this is broken"
Scope: Unknown, requires investigation
Approach: Iterative discovery
Decision: DIRECT
Rationale: Cannot pre-plan agents for unknown problem
```

**Validation**: `exploratory_task_identified`

---

## 4. 🤝 COLLABORATIVE DECISION (MEDIUM COMPLEXITY)

### When to Ask User

Complexity score 40-49% triggers user preference:

```markdown
Complexity Score: 45%

This task has medium complexity (45%). I can either:

A) **Handle directly** (simpler, sequential execution)
   - Pros: Less overhead, easier to track
   - Cons: May take longer, sequential processing
   - Estimated time: 15 minutes

B) **Create specialized sub-agents** (parallel execution)
   - Pros: Potentially faster (est. 10 min), specialized focus
   - Cons: More complex, 2-3s overhead per agent
   - Estimated agents: 2-3

Which would you prefer?
```

**User Override Patterns**:
- User may prefer dispatch for learning/testing
- User may prefer direct for simplicity
- Track preferences to learn user patterns

**Validation**: `user_preference_collected`

---

## 5. 📊 OVERHEAD CALCULATION

### Fixed Overhead Per Agent

```
Sub-agent creation: ~500ms
Task tool invocation: ~1s
Result integration: ~500ms
────────────────────────────
Total fixed: ~2s per agent
```

### Variable Overhead

```
Context preparation: 100-500ms
Skill filtering: 50-100ms
Domain clustering: 100-200ms
Error handling: 0-1000ms (if needed)
────────────────────────────
Total variable: 250-1800ms
```

### Break-Even Analysis

**Decision Logic**:
```markdown
parallel_time = estimated_task_time / num_agents
overhead = num_agents * 2.5s
total_time = parallel_time + overhead

IF total_time < (sequential_time * 0.7):
  → DISPATCH (30%+ time savings justifies overhead)
ELSE:
  → DIRECT (overhead not justified)
```

❌ **WRONG - Ignoring overhead**:
```
Task: 5-minute fix, 3 agents
Overhead ignored
Decision: DISPATCH
→ Actual: 2min parallel + 7.5s overhead vs 5min direct
```

✅ **RIGHT - Including overhead**:
```
Task: 15-minute implementation, 3 agents
parallel_time = 15min / 3 = 5min
overhead = 3 * 2.5s = 7.5s
total = 5min 7.5s vs 15min sequential
savings = 66% → DISPATCH justified
```

**Validation**: `overhead_calculated`

---

## 6. ⚙️ SPECIAL CONSIDERATIONS

### Token Budget Constraints

**Decision Logic**:
```markdown
IF token_budget < 20%:
  → Override: DIRECT (force direct regardless of complexity)

IF token_budget >= 20% AND token_budget < 40%:
  → Override: LIMIT_2 (maximum 2 sub-agents only)

IF token_budget >= 40%:
  → Normal operation (up to 5 agents allowed)
```

**Validation**: `token_budget_checked`


### Error Recovery Cost

Consider failure probability:

```markdown
IF task_failure_probability > 30%:
  → Prefer DIRECT (easier debugging and recovery)

IF task_failure_probability < 10%:
  → DISPATCH acceptable (low risk)
```

**Validation**: `failure_risk_assessed`


### User Preference Learning

Track and learn from user choices:

```
[timestamp] USER_PREFERENCE
Task type: refactoring
Complexity: 55%
Offered: COLLABORATIVE
User chose: DISPATCH
Note: User prefers parallel for refactoring tasks
```

**After 10+ decisions**: Adjust default behavior based on patterns

**Validation**: `user_patterns_logged`

---

## 7. 🐛 COMMON DECISION ERRORS

**Error Pattern 1: Over-Dispatching Simple Tasks**
```javascript
// Request: "Update variable name"
// ❌ WRONG: Created agent (overhead > task time)
// ✅ RIGHT: Handle directly (30-second task)
```

**Error Pattern 2: Missing Sequential Dependencies**
```javascript
// Request: "Build then test"
// ❌ WRONG: Parallel agents (tests need build)
// ✅ RIGHT: Sequential handling (dependency chain)
```

**Error Pattern 3: Ignoring Token Budget**
```javascript
// Complexity: 80%, Token Budget: 15%
// ❌ WRONG: Dispatched anyway (failed mid-execution)
// ✅ RIGHT: Override to DIRECT (insufficient budget)
```

**Error Pattern 4: Underestimating Overhead**
```javascript
// Task: 3 minutes, 4 agents
// ❌ WRONG: Ignored 10s overhead (assumed negligible)
// ✅ RIGHT: 45s parallel + 10s overhead = still beneficial
```

---

## 8. 📈 TUNING PARAMETERS

### Adjustable Thresholds

```javascript
const THRESHOLDS = {
  complexity: {
    direct: 40,          // Below: always direct
    collaborative: 50,   // Below: ask user
    dispatch: 50         // At/above: auto-dispatch
  },
  overhead: {
    max_percent: 30      // Max acceptable overhead
  },
  domains: {
    min_for_dispatch: 2  // Minimum domains for dispatch
  },
  tokens: {
    critical: 20,        // Force direct below this
    limited: 40          // Limit agents below this
  }
};
```

### Metrics for Tuning

Track actual outcomes:

```markdown
[timestamp] DECISION_OUTCOME
Decision: DISPATCH
Predicted benefit: 40% faster
Actual benefit: 35% faster
Accuracy: 87.5%
Adjustment needed: NO (within 10% tolerance)
```

**Iteration Process**:
1. Track 20+ decisions
2. Calculate accuracy rate (predicted vs actual)
3. Adjust thresholds by ±5% if accuracy <80%
4. Repeat until 80%+ accuracy sustained

---

## 9. 🎯 QUICK REFERENCE MATRIX

| Complexity | Domains | Parallel | Token Budget | Decision |
|------------|---------|----------|--------------|----------|
| <40% | Any | Any | Any | DIRECT |
| Any | 1 | Any | Any | DIRECT |
| Any | Any | None | Any | DIRECT |
| Any | Any | Any | <20% | DIRECT |
| 40-49% | 2+ | Some | >20% | COLLABORATIVE |
| ≥50% | 2+ | Yes | >40% | DISPATCH |
| ≥50% | 2+ | Yes | 20-40% | LIMIT_DISPATCH (max 2) |

---

**See also:**
- [complexity_scoring.md](./complexity_scoring.md) for threshold calculation
- [skill_clustering.md](./skill_clustering.md) for agent creation after dispatch decision
- [sub_agent_lifecycle.md](./sub_agent_lifecycle.md) for execution details