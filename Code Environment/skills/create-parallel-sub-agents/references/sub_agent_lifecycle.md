# Sub-Agent Lifecycle - Creation to Cleanup

Sub-agents are ephemeral - they exist only for task duration with no persistent state, created on-demand and destroyed immediately after result integration.

**Prerequisites:** Follow [Agent Orchestrator Workflow](../SKILL.md) for complete context:
- **Dispatch Decision**: See [dispatch_decision.md](./dispatch_decision.md) for when to create agents
- **Skill Clustering**: See [skill_clustering.md](./skill_clustering.md) for skill assignment

---

## 1. 🔄 THE 5 LIFECYCLE PHASES

You MUST complete each phase before proceeding to the next.

### Phase 1: Creation

**Purpose**: Build agent specification with domain, skills, and constraints

**Actions**:
1. Generate unique agent ID (`${domain}_${timestamp}`)
2. Select model based on domain and complexity
3. Build detailed prompt with skills and task context
4. Set timeout (default: 5 minutes)
5. Create agent specification

**Agent Specification Structure**:
```typescript
{
  description: "Brief task (3-10 words)",
  subagent_type: "general-purpose",
  model: "haiku" | "sonnet" | undefined,  // undefined = inherit
  prompt: "Detailed instructions...",
  timeout: 300000  // milliseconds
}
```

**Model Selection Logic**:
```markdown
IF complexity < 30%:
  → model: "haiku" (fast, cost-effective)
IF domain == "documentation":
  → model: "haiku" (text generation)
IF domain == "code" OR domain == "debugging":
  → model: "sonnet" (complex reasoning)
ELSE:
  → model: undefined (inherit from parent)
```

**Validation**: `agent_spec_created`


### Phase 2: Dispatch

**Purpose**: Invoke Task tool to launch sub-agent

**Actions**:
1. Log dispatch attempt
2. Invoke Task tool with agent spec
3. Log successful dispatch or handle error
4. Return agent handle for monitoring

**Dispatch Patterns**:

**Parallel Dispatch** (independent agents):
```javascript
const agents = [codeAgent, docsAgent, testAgent];
const results = await Promise.allSettled(
  agents.map(agent => Task.invoke(agent.spec))
);
```

**Sequential Dispatch** (dependent agents):
```javascript
const codeResult = await Task.invoke(codeAgent.spec);
const testResult = await Task.invoke(testAgent.spec); // depends on code
const gitResult = await Task.invoke(gitAgent.spec);   // depends on both
```

**Validation**: `agents_dispatched`


### Phase 3: Execution

**Purpose**: Monitor autonomous agent execution

**Actions**:
1. Set timeout watchdog
2. Check for early completion signals (every 5 seconds)
3. Handle timeout or errors
4. Prepare for result collection

**Monitoring Logic**:
```markdown
WHILE agent running AND time < timeout:
  Check completion status every 5s
  IF completed:
    → Proceed to Phase 4 (Integration)
  IF timeout reached:
    → Attempt partial result recovery
    → Mark as timeout failure
```

**Resource Limits**:
- Max concurrent: 5 agents
- Default timeout: 5 minutes (300000ms)
- Max timeout: 10 minutes (600000ms)
- Token budget per agent: 10% of remaining

**Validation**: `execution_monitored`


### Phase 4: Integration

**Purpose**: Collect and merge results from all agents

**Actions**:
1. Collect results from completed agents
2. Identify partial/failed results
3. Validate consistency across agents
4. Merge into unified output
5. Generate summary for user

**Integration Patterns**:

**Pattern 1: Merge Results**
```javascript
{
  code_changes: codeAgent.result.changes,
  documentation: docsAgent.result.updates,
  tests: testAgent.result.suites,
  combined_summary: generateSummary(allResults)
}
```

**Pattern 2: Validate Consistency**
```javascript
// Check for conflicts between agents
if (codeAgent.api !== docsAgent.api) {
  issues.push("API mismatch between code and docs");
}
```

**Pattern 3: Handle Partial Results**
```javascript
if (agent.status === 'partial') {
  use_completed = agent.result.completed;
  mark_incomplete = agent.result.incomplete;
  fallback_plan = handleIncomplete(mark_incomplete);
}
```

**Validation**: `results_integrated`


### Phase 5: Cleanup

**Purpose**: Release resources and destroy agent context

**Actions**:
1. Clear temporary files
2. Release token allocation
3. Log cleanup completion
4. Remove from active agents list

**Cleanup Strategies**:

**Immediate Cleanup** (as each completes):
```javascript
agent.promise.finally(() => cleanupAgent(agent));
```

**Batch Cleanup** (after all complete):
```javascript
await Promise.allSettled(agents.map(a => a.promise));
agents.forEach(agent => cleanupAgent(agent));
```

**Validation**: `resources_released`

---

## 2. ⚠️ ERROR HANDLING

### Timeout Handling

**Decision Logic**:
```markdown
IF agent times out:
  → Attempt partial result recovery
  → Log timeout with agent ID and duration
  → Mark tasks incomplete for main agent
  → Continue with other agents (don't block)
```

**Partial Recovery**:
```javascript
{
  status: 'timeout',
  completed: extractCompleted(agent),  // What finished
  incomplete: extractIncomplete(agent), // What didn't
  usable: completed.length > 0
}
```

### Failure Recovery

**Decision Logic**:
```markdown
IF agent fails with error:
  → Log error details
  IF retryable_error AND retries < 2:
    → Retry with same spec
  ELSE:
    → Fall back to direct handling
    → Log fallback decision
```

**Retry Strategy**:
- Max retries: 1
- Retry delay: 2 seconds
- Retry conditions: Network errors, timeout, transient failures
- No retry: Specification errors, validation failures


### Cascading Failures

**Decision Logic**:
```markdown
IF failure_rate > 30%:
  → Abort remaining dispatches
  → Switch to direct handling
  → Log cascade prevention

Example: 2 of 5 agents failed → Continue
         2 of 3 agents failed → Abort (66% failure)
```

---

## 3. 📊 LIFECYCLE METRICS

### Event Stream Format

```
[timestamp] AGENT_CREATED {id: code_1234, domain: code}
[timestamp] AGENT_DISPATCHED {id: code_1234, timeout: 300000}
[timestamp] AGENT_EXECUTING {id: code_1234}
[timestamp] AGENT_COMPLETED {id: code_1234, duration: 145000ms}
[timestamp] RESULTS_INTEGRATED {id: code_1234, success: true}
[timestamp] AGENT_CLEANED {id: code_1234}
```

### Performance Metrics

```javascript
{
  totalAgents: 3,
  successRate: 100%,         // 3/3 completed
  avgDuration: 2m 25s,       // Average execution time
  parallelSpeedup: 2.4x,     // Sequential: 7min → Parallel: 2m 55s
  tokenEfficiency: 85%       // Tokens used / budgeted
}
```

---

## 4. 🐛 COMMON LIFECYCLE ERRORS

**Error Pattern 1: Wrong Model Selection**
```javascript
// Simple documentation task
// ❌ WRONG: model: "sonnet" (slow, expensive)
// ✅ RIGHT: model: "haiku" (fast, appropriate)
```

**Error Pattern 2: Missing Timeout**
```javascript
// Complex refactoring task
// ❌ WRONG: timeout: 300000 (5min, insufficient)
// ✅ RIGHT: timeout: 600000 (10min, adequate buffer)
```

**Error Pattern 3: Skipping Cleanup**
```javascript
// Agent completed
// ❌ WRONG: Left in active list (resource leak)
// ✅ RIGHT: Immediate cleanup (resources released)
```

**Error Pattern 4: Ignoring Partial Results**
```javascript
// Agent timeout with 80% complete
// ❌ WRONG: Discarded all work (wasteful)
// ✅ RIGHT: Used completed portion (efficient)
```

---

## 5. 🎯 QUICK REFERENCE

### Lifecycle Timeline

```
Creation (500ms)
    ↓
Dispatch (1s)
    ↓
Execution (30s - 5min)
    ↓
Integration (500ms)
    ↓
Cleanup (100ms)
────────────────────
Total Overhead: ~2s per agent
```

### Model Selection Guide

| Domain | Complexity | Model | Rationale |
|--------|-----------|-------|-----------|
| Docs | Any | haiku | Text generation |
| Code | <30% | haiku | Simple changes |
| Code | ≥30% | sonnet | Complex logic |
| Debug | Any | sonnet | Reasoning needed |
| Test | Any | inherit | Use parent model |

### Timeout Guidelines

| Task Complexity | Timeout | Model |
|----------------|---------|-------|
| Trivial | 1 min | haiku |
| Simple | 3 min | haiku |
| Moderate | 5 min | sonnet |
| Complex | 10 min | sonnet |

---

**See also:**
- [dispatch_decision.md](./dispatch_decision.md) for when to create agents
- [skill_clustering.md](./skill_clustering.md) for skill assignment
- [sub_agent_template.md](../assets/sub_agent_template.md) for specification templates