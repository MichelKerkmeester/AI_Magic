# Complexity Scoring - Task Analysis Algorithm

Calculate complexity objectively across multiple dimensions to determine whether sub-agent dispatch provides value - dispatch only when orchestration overhead is justified by parallel execution gains or specialization benefits.

**Prerequisites:** Follow [Agent Orchestrator Workflow](../SKILL.md) for complete context:
- **Dispatch Decision**: See [dispatch_decision.md](./dispatch_decision.md) for threshold application
- **Sub-Agent Lifecycle**: See [sub_agent_lifecycle.md](./sub_agent_lifecycle.md) for agent creation

---

## 1. 📊 THE 5 SCORING DIMENSIONS

You MUST evaluate ALL five dimensions before making a dispatch decision.

### Dimension 1: Domain Count (30% weight)

**Purpose**: Identifies distinct functional domains that could benefit from specialized agents

**Domain Classification**:
- **Code**: Programming, refactoring, bug fixes
- **Documentation**: README, API docs, comments
- **Git**: Commits, branches, merges
- **Testing**: Unit tests, integration tests
- **DevOps**: CI/CD, deployment, configuration
- **Database**: Schema, queries, migrations
- **UI/UX**: Styling, layouts, animations

**Scoring Logic**:
```markdown
IF domains == 1:
  → Score: 0 points (single focus, no benefit from splitting)
IF domains == 2:
  → Score: 0.5 points (borderline, may benefit from parallel)
IF domains >= 3:
  → Score: 1.0 points (high benefit from specialized agents)
```

❌ **WRONG - Over-counting**:
```
Request: "Fix auth bug and add comment"
Domains counted: code, documentation (2)
→ Incorrect: Comment is trivial, not a separate domain
```

✅ **RIGHT - Accurate classification**:
```
Request: "Fix auth bug and add comment"
Domains: code only (1)
→ Correct: Comment is part of code change, not separate work
```

**Validation**: `domains_identified`


### Dimension 2: File Count (25% weight)

**Purpose**: Estimates scope of changes to determine coordination complexity

**Scoring Logic**:
```markdown
IF files <= 2:
  → Score: 0 points (localized change)
IF files == 3-5:
  → Score: 0.5 points (moderate scope)
IF files >= 6:
  → Score: 1.0 points (wide-ranging changes)
```

**Estimation Heuristics**:

| Request Pattern | Estimated Files | Rationale |
|----------------|-----------------|-----------|
| "all components" | 10+ files | System-wide change |
| "authentication system" | 5-8 files | Multi-file module |
| "update footer" | 1-2 files | Component + test |
| "typo in README" | 1 file | Single file edit |

❌ **WRONG - Under-estimating**:
```
Request: "Refactor authentication system"
Estimate: 2-3 files
→ Auth systems typically span 5-8 files minimum
```

✅ **RIGHT - Realistic estimation**:
```
Request: "Refactor authentication system"
Estimate: 6-8 files (routes, controllers, models, tests, docs)
→ Score: 1.0 × 25% = 25%
```

**Validation**: `file_scope_estimated`


### Dimension 3: Lines of Code (20% weight)

**Purpose**: Rough estimate of implementation volume

**Scoring Logic**:
```markdown
IF LOC < 50:
  → Score: 0 points (minor change)
IF LOC == 50-200:
  → Score: 0.5 points (moderate implementation)
IF LOC >= 200:
  → Score: 1.0 points (significant implementation)
```

**Estimation Patterns**:

| Task Type | Typical LOC | Examples |
|-----------|------------|----------|
| Typo fix | <10 | Comment changes, variable renames |
| Add validation | 20-50 | Input checks, error handling |
| Refactor module | 100-300 | Restructuring, pattern changes |
| New feature | 200+ | Complete implementations |

**Validation**: `loc_estimated`


### Dimension 4: Parallel Opportunity (15% weight)

**Purpose**: Identifies independent tasks that can execute concurrently

**Scoring Logic**:
```markdown
IF no parallel opportunity:
  → Score: 0 points (sequential dependencies)
IF some parallel tasks:
  → Score: 0.5 points (partial parallelization possible)
IF high parallelization:
  → Score: 1.0 points (fully independent tasks)
```

**Pattern Recognition**:

**Sequential Dependency Keywords** (force parallel_opportunity = 0):
```
then, after, before, first...then, once...done,
when...complete, followed by
```

> **Implementation Note**: The `orchestrate-skill-validation.sh` hook detects these keywords and sets parallel_opportunity to 0 when found.

❌ **WRONG - Missing dependencies**:
```
Request: "Build project then run tests"
Parallel score: 1.0
→ Incorrect: Tests depend on build completion
```

✅ **RIGHT - Recognizing dependencies**:
```
Request: "Build project then run tests"
Parallel score: 0.0 (sequential dependency)
→ Correct: "then" keyword detected, cannot parallelize
```

❌ **WRONG - Missing parallel opportunity**:
```
Request: "Fix bug in auth, payment, and shipping modules"
Parallel score: 0.0
→ Incorrect: Three independent modules can run parallel
```

✅ **RIGHT - Identifying parallelization**:
```
Request: "Fix bug in auth, payment, and shipping modules"
Parallel score: 1.0 (three independent fixes)
→ Correct: All three are unrelated, full parallelization
```

**Validation**: `parallel_opportunity_assessed`


### Dimension 5: Task Type (10% weight)

**Purpose**: Categorizes inherent task complexity

**Categories**:

| Type | Examples | Score | Rationale |
|------|----------|-------|-----------|
| **Trivial** | Typos, comments, formatting | 0.0 | No meaningful complexity |
| **Moderate** | Bug fixes, small features | 0.5 | Standard development work |
| **Complex** | Refactoring, new systems, architecture | 1.0 | High cognitive load |

**Validation**: `task_type_classified`

---

## 2. 🧮 CALCULATION WORKFLOW

You MUST complete these phases in order.

### Phase 1: Analyze Request

**Purpose**: Extract scoring signals from user request

**Actions**:
1. Identify mentioned domains (code, docs, git, test, etc.)
2. Estimate file count from scope indicators
3. Estimate LOC from task type
4. Check for parallel execution keywords
5. Classify overall task complexity

**Validation**: `request_analyzed`


### Phase 2: Score Each Dimension

**Purpose**: Calculate weighted scores for all dimensions

**Actions**:
```javascript
// Dimension scoring
const domainScore = scoreDomains(request);      // 0, 0.5, or 1.0
const fileScore = scoreFiles(request);          // 0, 0.5, or 1.0
const locScore = scoreLOC(request);             // 0, 0.5, or 1.0
const parallelScore = scoreParallel(request);   // 0, 0.5, or 1.0
const typeScore = scoreType(request);           // 0, 0.5, or 1.0

// Apply weights
const weightedScores = {
  domain: domainScore * 0.30,
  file: fileScore * 0.25,
  loc: locScore * 0.20,
  parallel: parallelScore * 0.15,
  type: typeScore * 0.10
};

// Total score (0-1.0, convert to percentage)
const complexityScore = Object.values(weightedScores).reduce((a, b) => a + b) * 100;
```

**Validation**: `dimensions_scored`


### Phase 3: Apply Decision Thresholds

**Purpose**: Convert score to dispatch decision

**Decision Logic**:
```markdown
IF complexityScore < 40:
  → Decision: DIRECT (low complexity)
  → Rationale: Overhead exceeds benefit

IF complexityScore >= 40 AND complexityScore < 50:
  → Decision: COLLABORATIVE (medium complexity)
  → Rationale: Borderline case, user preference

IF complexityScore >= 50:
  → Decision: DISPATCH (high complexity)
  → Rationale: Clear efficiency gain from sub-agents
```

**Validation**: `decision_determined`

---

## 3. 📝 COMPLETE SCORING EXAMPLE

**Request**: "Implement user authentication, add tests, update API documentation, and prepare commit message"

### Dimension Analysis:

**1. Domain Count (30%)**:
- Domains identified: code, testing, documentation, git (4 domains)
- Score: 1.0 (≥3 domains)
- Weighted: 1.0 × 30% = **30%**

**2. File Count (25%)**:
- Estimated: 8-12 files (auth module + tests + docs + commit)
- Score: 1.0 (≥6 files)
- Weighted: 1.0 × 25% = **25%**

**3. LOC Estimate (20%)**:
- New authentication feature: ~300-500 LOC
- Score: 1.0 (≥200 LOC)
- Weighted: 1.0 × 20% = **20%**

**4. Parallel Opportunity (15%)**:
- Docs can be parallel, tests depend on code
- Score: 0.5 (some parallelization)
- Weighted: 0.5 × 15% = **7.5%**

**5. Task Type (10%)**:
- Complex (new authentication system)
- Score: 1.0 (complex task)
- Weighted: 1.0 × 10% = **10%**

### Final Calculation:
```
Total Score = 30% + 25% + 20% + 7.5% + 10% = 92.5%
```

### Decision:
```
Score: 92.5% → AUTO-DISPATCH
Rationale: High complexity across all dimensions, clear parallelization opportunities
Expected agents: 3-4 (code, test, docs, git)
```

---

## 4. ⚠️ EDGE CASES & OVERRIDES

### Sequential Dependencies Override

Even high complexity may not benefit from dispatch:

```markdown
Request: "Install dependencies, build project, run tests, deploy"
Complexity Score: May be 55-65% (multiple steps)
Parallel Opportunity: 0.0 (strict sequential)
Override: DIRECT despite score
Rationale: No parallel benefit, sequential execution required
```

### Resource Constraints Override

Token budget overrides complexity score:

```markdown
IF token_budget < 20%:
  → Override: DIRECT (regardless of complexity)
  → Rationale: Insufficient resources for sub-agent dispatch

IF token_budget >= 20% AND token_budget < 40%:
  → Override: LIMIT_2 (maximum 2 sub-agents)
  → Rationale: Limited resources, reduce agent count
```

### User Preference (Collaborative Zone)

Medium complexity (40-49%) always asks (50%+ auto-dispatches):

```markdown
Complexity: 45%
Prompt: "This task has medium complexity (45%).
Would you prefer:
A) Handle directly (simpler, sequential)
B) Dispatch sub-agents (parallel, potentially faster)"
```

---

## 5. 🐛 COMMON SCORING ERRORS

**Error Pattern 1: Domain Over-Counting**
```javascript
// Request: "Fix bug and add comment to explain fix"
// ❌ WRONG: Counted as 2 domains (code + documentation)
// ✅ RIGHT: 1 domain (code) - comment is trivial part of fix
```

**Error Pattern 2: Under-Estimating File Count**
```javascript
// Request: "Refactor authentication"
// ❌ WRONG: Estimated 2-3 files
// ✅ RIGHT: 5-8 files (routes, middleware, controllers, tests, docs)
```

**Error Pattern 3: Missing Sequential Dependencies**
```javascript
// Request: "Build then test then deploy"
// ❌ WRONG: High parallel score (3 steps = 3 agents)
// ✅ RIGHT: Zero parallel (strict sequential dependency)
```

**Error Pattern 4: Ignoring Resource Constraints**
```javascript
// Complexity: 85%, Token Budget: 15%
// ❌ WRONG: Dispatched anyway (hit resource limit)
// ✅ RIGHT: Override to DIRECT (insufficient budget)
```

---

## 6. 📊 TUNING & CALIBRATION

### Adjusting Weights

If dispatch decisions prove incorrect:

| Problem | Adjustment | Rationale |
|---------|-----------|-----------|
| Too many dispatches | Increase domain weight | Require more domains to dispatch |
| Missing opportunities | Increase parallel weight | Prioritize parallelization |
| Wrong on small tasks | Increase file count weight | Better filter trivial changes |

**Maximum adjustment**: ±5% per iteration

### Gathering Validation Data

```markdown
[timestamp] SCORE_VALIDATION
Request: "[request text]"
Predicted Score: 75%
Predicted Decision: DISPATCH
Actual Benefit: HIGH | MEDIUM | LOW | NEGATIVE
Actual Time Saved: +60% | +30% | 0% | -20%
Adjustment Needed: YES | NO
```

### Iteration Process

1. Run for 1 week with current weights
2. Analyze logs for prediction accuracy
3. Calculate error rate (wrong decisions / total decisions)
4. Adjust weights by maximum ±5%
5. Repeat until >80% accuracy achieved

---

## 7. 🎯 QUICK REFERENCE

| Request Pattern | Typical Score | Decision | Agents |
|----------------|---------------|----------|---------|
| "Fix typo" | 5-10% | Direct | 0 |
| "Add button" | 20-30% | Direct | 0 |
| "Update component + tests" | 45-55% | Collaborative | Ask user |
| "Refactor module + docs" | 70-80% | Dispatch | 2 |
| "Implement feature + tests + docs" | 85-95% | Dispatch | 3 |
| "Fix 5 unrelated bugs" | 80-90% | Dispatch | 5 |

---

**See also:**
- [dispatch_decision.md](./dispatch_decision.md) for threshold application and decision tree
- [skill_clustering.md](./skill_clustering.md) for domain-based agent creation
- [quick_reference.md](./quick_reference.md) for one-page decision guide