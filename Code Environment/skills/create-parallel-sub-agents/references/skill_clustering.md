# Skill Clustering - Domain-Based Skill Grouping

Each sub-agent receives ONLY skills relevant to its domain - reducing context overhead while maintaining effectiveness through focused specialization.

**Prerequisites:** Follow [Agent Orchestrator Workflow](../SKILL.md) for complete context:
- **Complexity Scoring**: See [complexity_scoring.md](./complexity_scoring.md) for task analysis
- **Hook Integration**: Reads from `.claude/hooks/logs/skill-recommendations.log`

---

## 1. 🗂️ DOMAIN DEFINITIONS

You MUST assign skills to appropriate domains before creating sub-agents.

### Domain 1: Code
**Purpose**: Programming, refactoring, bug fixes, implementation

**Core Skills**:
- `workflows-code` - Development workflow with code quality standards (MANDATORY)
- `mcp-semantic-search` - Intent-based code discovery for finding implementations
- `cli-codex` - Alternative AI for code generation/review (optional)

**Allowed Tools**: Read, Write, Edit, Grep, Glob, Bash

**Validation**: `code_skills_assigned`


### Domain 2: Documentation
**Purpose**: Creating and updating documentation

**Core Skills**:
- `create-documentation` - Documentation creation and structure (MANDATORY)
- `workflows-spec-kit` - Spec folder system for conversation documentation (MANDATORY)
- `create-flowchart` - Visual documentation with flowcharts (optional)

**Allowed Tools**: Read, Write, Edit, Grep, WebSearch

**Validation**: `docs_skills_assigned`


### Domain 3: Git
**Purpose**: Version control operations

**Core Skills**:
- `workflows-git` - Git workflow orchestration including commits and branches (MANDATORY)
- `workflows-save-context` - Save conversation context before major changes (optional)

**Allowed Tools**: Bash, Read, Grep

**Validation**: `git_skills_assigned`


### Domain 4: Testing
**Purpose**: Test creation and execution

**Core Skills**:
- `workflows-code` - Includes testing patterns in code quality standards (MANDATORY)
- `mcp-semantic-search` - Find existing test patterns in codebase (optional)

**Allowed Tools**: Read, Write, Edit, Bash, BrowserTool (if available)

**Validation**: `test_skills_assigned`


### Domain 5: DevOps / MCP Integration
**Purpose**: Build, deployment, external tool integration

**Core Skills**:
- `mcp-code-mode` - MCP tool orchestration via TypeScript execution (MANDATORY)
- `cli-gemini` - Alternative AI with web research capabilities (optional)

**Allowed Tools**: Bash, Read, Edit, WebFetch

**Validation**: `devops_skills_assigned`

---

## 2. 🔄 THE 3 CLUSTERING PHASES

You MUST complete each phase before proceeding to the next.

### Phase 1: Domain Identification

**Purpose**: Extract functional domains from user request

**Actions**:
1. Parse request for domain keywords
2. Identify primary domain (main focus)
3. Identify secondary domains (supporting work)
4. Filter out trivial mentions (e.g., "add comment" != documentation domain)

**Decision Logic**:
```markdown
IF request contains domain keywords:
  → Add domain to list
IF domain work is trivial (<5 min):
  → Exclude from domain list
IF domains overlap significantly:
  → Merge into primary domain
```

❌ **WRONG - Over-identifying domains**:
```
Request: "Fix auth bug and add explanatory comment"
Domains: code, documentation (2)
→ Incorrect: Comment is trivial, not separate domain
```

✅ **RIGHT - Accurate domain filtering**:
```
Request: "Fix auth bug and add explanatory comment"
Domains: code (1)
→ Correct: Comment is part of code fix, not separate work
```

**Validation**: `domains_identified`


### Phase 2: Skill Assignment

**Purpose**: Map skills from hook recommendations to identified domains

**Actions**:
1. Read `.claude/hooks/logs/skill-recommendations.log`
2. Extract MANDATORY skills (always include)
3. Filter HIGH priority skills by domain relevance
4. Add MEDIUM priority skills if space permits
5. Deduplicate across agents

**Priority Filtering Logic**:
```markdown
FOR each domain:
  1. Start with MANDATORY skills (🔴)
  2. Add HIGH priority skills (🟡) if domain-relevant
  3. Add MEDIUM priority skills (🟠) if space allows (<5 skills total)
  4. Skip LOW priority skills
```

❌ **WRONG - Missing mandatory skills**:
```
Code Agent Skills:
- mcp-semantic-search
- cli-codex
→ Missing: workflows-code (MANDATORY)
```

✅ **RIGHT - Including mandatory skills**:
```
Code Agent Skills:
- workflows-code (MANDATORY)
- mcp-semantic-search
- cli-codex
→ Correct: All mandatory skills included
```

**Validation**: `skills_assigned`


### Phase 3: Cross-Domain Resolution

**Purpose**: Handle shared skills and dependencies

**Actions**:
1. Identify skills needed by multiple domains
2. Assign shared skills to primary domain
3. Ensure no critical skill gaps
4. Optimize for minimal overlap

**Shared Skill Patterns**:

| Skill | Domains | Assignment Strategy |
|-------|---------|-------------------|
| `workflows-code` | Code, Test | Include in both (code quality + testing patterns) |
| `workflows-spec-kit` | All | Include in all (spec folder required) |
| `mcp-semantic-search` | Code, Test | Include in both (find implementations and tests) |

**Validation**: `dependencies_resolved`

---

## 3. 📋 CLUSTERING EXAMPLES

### Example 1: Multi-Domain Feature

**Request**: "Implement dark mode toggle with tests and documentation"

**Phase 1 - Domain Identification**:
- Domains: code (toggle implementation), test (testing), docs (documentation)

**Phase 2 - Skill Assignment**:
```yaml
code_agent:
  - workflows-code (MANDATORY)
  - workflows-spec-kit (MANDATORY)
  - mcp-semantic-search (HIGH)

test_agent:
  - workflows-code (MANDATORY)
  - workflows-spec-kit (MANDATORY)
  - mcp-semantic-search (HIGH)

docs_agent:
  - create-documentation (MANDATORY)
  - workflows-spec-kit (MANDATORY)
  - create-flowchart (MEDIUM)
```

**Phase 3 - Cross-Domain Resolution**:
- Shared: `workflows-code`, `workflows-spec-kit` (included where needed)
- No conflicts: Each agent has focused skill set


### Example 2: Parallel Debugging

**Request**: "Fix failing tests in auth, payment, and user modules"

**Phase 1 - Domain Identification**:
- Domains: code (3 independent bugs)
- Pattern: Parallel debugging opportunity

**Phase 2 - Skill Assignment**:
```yaml
auth_agent:
  - workflows-code (MANDATORY)
  - mcp-semantic-search (HIGH)

payment_agent:
  - workflows-code (MANDATORY)
  - mcp-semantic-search (HIGH)

user_agent:
  - workflows-code (MANDATORY)
  - mcp-semantic-search (HIGH)
```

**Phase 3 - Cross-Domain Resolution**:
- Identical skill sets (same domain, same task type)
- No overlap issues (fully independent)

---

## 4. ⚠️ COMMON CLUSTERING ERRORS

**Error Pattern 1: Skill Overload**
```javascript
// Code Agent with 10+ skills assigned
// ❌ WRONG: Too many skills, context bloat
// ✅ RIGHT: Maximum 5 skills per agent, focused set
```

**Error Pattern 2: Missing Mandatory Skills**
```javascript
// Agent created without code-standards
// ❌ WRONG: All agents need MANDATORY skills
// ✅ RIGHT: Always include 🔴 MANDATORY skills first
```

**Error Pattern 3: Incorrect Domain Assignment**
```javascript
// Request: "Add comment to function"
// ❌ WRONG: Created documentation agent
// ✅ RIGHT: Trivial comment, part of code agent
```

**Error Pattern 4: Excessive Skill Duplication**
```javascript
// 3 agents all have same 8 skills
// ❌ WRONG: No specialization benefit
// ✅ RIGHT: Each agent has focused skill subset
```

---

## 5. 🔧 OPTIMIZATION STRATEGIES

### Minimize Context Overhead

**Goal**: Keep each agent under 5 skills total

**Strategy**:
1. MANDATORY skills first (non-negotiable)
2. Add 2-3 HIGH priority domain-specific skills
3. Add 0-1 MEDIUM priority if critical
4. Skip LOW priority entirely

### Balance Workload

**Goal**: Distribute work evenly across agents

**Strategy**:
```markdown
IF one agent has 80% of work:
  → Consider splitting into sub-tasks
IF agents have 90%+ skill overlap:
  → Merge into single agent (no benefit from splitting)
```

### Respect Tool Constraints

**Goal**: Match tools to domain needs

| Domain | Essential Tools | Optional Tools |
|--------|----------------|----------------|
| Code | Read, Write, Edit, Bash | Grep, Glob |
| Docs | Read, Write | Edit, WebSearch |
| Git | Bash | Read, Grep |
| Test | Bash, Read, Edit | BrowserTool |

---

## 6. 🎯 QUICK REFERENCE

**Clustering Decision Matrix**:

| Request Type | Domains | Agents | Skills Per Agent |
|-------------|---------|--------|------------------|
| Typo fix | 1 (code) | 0 | N/A (direct) |
| Feature + tests | 2 (code, test) | 2 | 4-5 each |
| Feature + tests + docs | 3 (code, test, docs) | 3 | 4-5 each |
| 5 independent bugs | 1 (code) | 5 | 3-4 each |

**Skill Priority Filter**:
```
🔴 MANDATORY → Always include
🟡 HIGH → Include if domain-relevant
🟠 MEDIUM → Include if space permits (<5 total)
⚪ LOW → Skip for sub-agents
```

---

**See also:**
- [complexity_scoring.md](./complexity_scoring.md) for domain count scoring
- [dispatch_decision.md](./dispatch_decision.md) for when to create agents
- [sub_agent_lifecycle.md](./sub_agent_lifecycle.md) for agent creation details