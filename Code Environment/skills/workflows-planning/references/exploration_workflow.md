# Exploration Workflow Reference

Detailed documentation of the 4-agent parallel exploration process, hypothesis verification, and plan generation phases.

---

## 1. 📖 OVERVIEW

The workflows-planning skill uses a 3-phase approach:

```
Phase 1: Parallel Exploration (4 Sonnet agents)
    ↓
Phase 2: Hypothesis Verification (main agent)
    ↓
Phase 3: Plan Creation (template-based)
```

**Purpose**: Create evidence-based implementation plans by exploring the codebase before writing plans, rather than making assumptions.

---

## 2. 🚀 PHASE 1: PARALLEL EXPLORATION

### Agent Configuration

Four specialized Sonnet agents explore the codebase simultaneously:

| Agent | Focus | Purpose | Output |
|-------|-------|---------|--------|
| **Architecture Explorer** | Project structure, file organization | Understand overall architecture | File paths, structural patterns |
| **Feature Explorer** | Similar features, related patterns | Find reusable patterns | Similar implementations, patterns |
| **Dependency Explorer** | Imports, modules, affected areas | Identify integration points | Dependency chains, coupling points |
| **Test Explorer** | Test patterns, testing infrastructure | Understand verification approach | Test frameworks, coverage patterns |

### Spawning Pattern

**CRITICAL**: All 4 agents MUST be spawned in a single message with multiple Task tool calls for true parallel execution.

**❌ WRONG - Sequential Spawning** (4x slower, ~60-100 seconds total):
```javascript
// Message 1 - spawn first agent
Task({ subagent_type: "Explore", model: "sonnet", description: "Architecture exploration", prompt: architecture_explorer_prompt })
// Wait for response...

// Message 2 - spawn second agent
Task({ subagent_type: "Explore", model: "sonnet", description: "Feature exploration", prompt: feature_explorer_prompt })
// Wait for response...

// ... 2 more sequential spawns
// TOTAL TIME: 4 × 15-25 seconds = 60-100 seconds
```

**✅ CORRECT - Parallel Spawning** (single message, ~15-30 seconds total):
```javascript
// Single message with 4 Task calls
Task({
  subagent_type: "Explore",
  model: "sonnet",
  description: "Architecture exploration",
  prompt: architecture_explorer_prompt
})

Task({
  subagent_type: "Explore",
  model: "sonnet",
  description: "Feature exploration",
  prompt: feature_explorer_prompt
})

Task({
  subagent_type: "Explore",
  model: "sonnet",
  description: "Dependency exploration",
  prompt: dependency_explorer_prompt
})

Task({
  subagent_type: "Explore",
  model: "sonnet",
  description: "Test exploration",
  prompt: test_explorer_prompt
})

// TOTAL TIME: max(agent times) = 15-30 seconds
```

### Model Selection Rationale

**Why Sonnet for Exploration?**
- Fast execution (~5-15 seconds per agent)
- Cost-effective for exploratory work
- Sufficient capability for pattern recognition
- Parallel execution keeps total time low

**Why Not Opus for Exploration?**
- Higher latency per agent
- Overkill for hypothesis generation
- Better reserved for verification phase

### Expected Agent Output

Each agent returns:
1. **Hypothesis**: Their understanding of the codebase aspect
2. **File Paths**: Full paths to relevant files (format: `/path/to/file.ts:lineNumber`)
3. **Patterns**: Observations about conventions, naming, structure

**Example Architecture Explorer Output**:
```
HYPOTHESIS: The project uses a feature-based folder structure with
shared utilities in src/common/ and page-specific code in src/pages/.

RELEVANT FILES:
- src/pages/index.ts:1-50 (main entry point)
- src/common/utils.ts:15-80 (shared utilities)
- src/components/Layout.tsx:1-120 (layout wrapper)

PATTERNS:
- Feature folders contain index.ts exports
- Components follow PascalCase naming
- Utilities use snake_case
```

---

## 3. ✅ PHASE 2: HYPOTHESIS VERIFICATION

### Purpose

Agents generate **hypotheses** based on their exploration. These are unverified assumptions that must be cross-checked against actual code.

### Verification Process

1. **Read Identified Files**
   - Use Read tool on each file path from agent findings
   - Include line numbers for targeted reading
   - Verify file contents match agent descriptions

2. **Cross-Check Hypotheses**
   - Compare agent findings against actual code
   - Identify contradictions or gaps
   - Validate architectural assumptions
   - Confirm integration points

3. **Resolve Conflicts**
   - If agents disagree, read additional files
   - Prioritize evidence over assumptions
   - Document unresolved ambiguities

4. **Build Mental Model**
   - Document verified understanding of:
     - Current architecture (confirmed patterns)
     - Affected components (scope of changes)
     - Integration points (where new code connects)
     - Potential risks (identified during verification)

### Verification Checklist

```markdown
□ All agent hypotheses verified or refuted
□ At least 80% of identified files actually read
□ Conflicting hypotheses resolved or documented
□ Mental model includes all 4 components:
  - Current architecture
  - Affected components
  - Integration points
  - Potential risks
```

### Common Verification Scenarios

| Scenario | Action |
|----------|--------|
| Agent hypothesis confirmed | Include as verified finding in plan |
| Agent hypothesis refuted | Note discrepancy, use actual code structure |
| Agents disagree | Read more files, determine ground truth |
| Gap in agent coverage | Manual exploration to fill gaps |
| Agent found non-existent file | Ignore, rely on other agents |

---

## 4. 📝 PHASE 3: PLAN CREATION

### Template Usage

Plans use `.claude/commands/spec_kit/assets/templates/plan_template.md` structure:

```yaml
read_template:
  path: ".claude/commands/spec_kit/assets/templates/plan_template.md"
  purpose: "Base structure for plan"
  requirement: "Preserve all section headings"
```

### Section-by-Section Population

| Section | Source | Content Focus |
|---------|--------|---------------|
| **1. OBJECTIVE** | Task description + Phase 2 | What we're building, why, for whom |
| **2. QUALITY GATES** | Test Explorer | Completion criteria, DoR/DoD |
| **3. PROJECT STRUCTURE** | Architecture Explorer | Affected files, directory structure |
| **4. IMPLEMENTATION PHASES** | All agents | Phased breakdown with file references |
| **5. TESTING STRATEGY** | Test Explorer | Test pyramid, coverage targets |
| **6. SUCCESS METRICS** | Derived | Measurable outcomes |
| **7. RISKS & MITIGATIONS** | Phase 2 risks | Risk matrix, rollback plan |
| **8. DEPENDENCIES** | Dependency Explorer | Internal/external dependencies |
| **9. COMMUNICATION** | Standard | Review checkpoints |
| **10. REFERENCES** | All phases | Spec files, agent findings |

### Content Requirements

**MUST Include**:
- File paths with line numbers (format: `src/file.ts:123`)
- Verified findings (not raw agent hypotheses)
- Clear phase breakdown with deliverables
- Identified risks and mitigations

**MUST Remove**:
- All `[PLACEHOLDER]` markers
- All `[YOUR_VALUE_HERE: ...]` text
- Unverified speculation
- Agent hypotheses that were refuted

### Validation Checklist

```markdown
□ No placeholder text remaining
□ All file paths include line numbers
□ Each phase has clear verification steps
□ Risks identified during exploration are documented
□ All template sections present and filled
□ Final line includes user review prompt
```

---

## 5. ⏱️ TIMING EXPECTATIONS

### Phase Timing

| Phase | Expected Duration | Maximum |
|-------|-------------------|---------|
| Agent Spawning | 1-2 seconds | 5 seconds |
| Agent Exploration | 10-25 seconds | 45 seconds |
| Hypothesis Verification | 15-30 seconds | 35 seconds |
| Plan Creation | 10-20 seconds | 25 seconds |
| **Total** | **35-75 seconds** | **90 seconds** |

### Timeout Handling

If total time exceeds 90 seconds:
1. Use partial agent results
2. Document incomplete exploration
3. Note gaps in plan.md
4. Recommend manual verification of undiscovered areas

---

## 6. ⚠️ ERROR HANDLING

### Graceful Degradation Matrix

| Error | Impact | Recovery |
|-------|--------|----------|
| Task tool unavailable | Cannot spawn agents | Fall back to inline planning |
| 1-2 agents fail | Partial findings | Use successful agents + manual exploration |
| All agents fail | No exploration | Return control to caller with fallback flag |
| Agent timeout | Incomplete findings | Use partial results, note gaps |
| No files found | Limited context | Document limitation, proceed with task description only |

### Fallback Signal

When skill cannot complete:
```yaml
fallback:
  status: "incomplete"
  reason: "Agent spawning unavailable"
  action: "Use inline planning logic"
  partial_findings: [any results obtained]
```

---

## 7. ⭐ BEST PRACTICES

### ✅ For Effective Exploration

1. **Clear Task Description**: Provide specific, detailed task description
2. **Context Awareness**: Load spec folder context before exploration
3. **Parallel Spawning**: Always spawn all 4 agents in single message
4. **Verification First**: Never skip verification phase

### ✅ For Quality Plans

1. **Verify Everything**: Don't trust agent hypotheses without reading code
2. **Include Line Numbers**: File references must include line numbers
3. **Document Uncertainties**: Note areas that couldn't be fully explored
4. **Risk Awareness**: Surface risks discovered during exploration

### ❌ Common Mistakes to Avoid

| Mistake | Consequence | Prevention |
|---------|-------------|------------|
| Sequential agent spawning | 4x slower exploration | Use single message with 4 Task calls |
| Skipping verification | Plan based on wrong assumptions | Always read identified files |
| Unverified hypotheses in plan | Incorrect implementation guidance | Verify before including |
| Missing line numbers | Harder to navigate plan | Format: `file.ts:123` |

---

## 8. 🔄 INTEGRATION CHECKLIST

When integrating this workflow into spec_kit:

```markdown
□ Skill invocation added to step_6_planning
□ Task tool properly configured for agent spawning
□ Fallback logic preserves existing inline planning
□ plan.md output compatible with spec_kit:implement
□ Timing within 90-second planning phase limit
□ skill-rules.json entry added for auto-suggestion
```

---

**Remember**: The goal is evidence-based planning. Every claim in the plan should be backed by code that was actually read and verified.
