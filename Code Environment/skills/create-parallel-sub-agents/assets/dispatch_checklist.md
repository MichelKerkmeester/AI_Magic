# Pre-Dispatch Validation Checklist

Systematic validation before dispatching sub-agents to ensure success.

---

## 1. 🔍 PRE-FLIGHT CHECKLIST

### 1. Resource Availability
```markdown
□ Token budget checked (>20% remaining)
□ Concurrent agent slots available (<5 active)
□ Task tool accessible and responsive
□ Sufficient time remaining in conversation
```

### 2. Task Analysis Complete
```markdown
□ Complexity score calculated (0-100%)
□ Domains clearly identified
□ Dependencies mapped (parallel vs sequential)
□ Success criteria defined
□ Time estimates calculated
```

### 3. Skills & Hooks Verified
```markdown
□ Hook recommendations read from logs
□ Skills filtered by priority (mandatory → high → medium)
□ Skills clustered by domain
□ No critical skills missing
□ Skill conflicts resolved
```

### 4. Agent Specifications Ready
```markdown
□ Clear task description for each agent
□ Appropriate model selected (haiku/sonnet/inherit)
□ Detailed prompts constructed
□ Tools minimized to essentials
□ Timeouts set appropriately
```

### 5. Integration Plan Clear
```markdown
□ Result format defined
□ Integration strategy chosen (merge/validate/sequential)
□ Conflict resolution approach defined
□ Partial result handling planned
□ Fallback strategy prepared
```

---

## 2. 🚦 GO/NO-GO DECISION MATRIX

| Check | Go | No-Go | Action if No-Go |
|-------|-----|-------|-----------------|
| Token budget >20% | ✅ | ❌ | Handle directly |
| Complexity ≥50% | ✅ | ❌ | Consider direct or ask user |
| Domains ≥2 | ✅ | ❌ | Handle directly |
| Parallel possible | ✅ | ❌ | Consider sequential |
| Skills available | ✅ | ❌ | Use basic skill set |
| Clear success criteria | ✅ | ❌ | Clarify with user |

**Decision**: If ANY no-go → Reconsider dispatch strategy

---

## 3. 📋 DISPATCH EXECUTION CHECKLIST

### Phase 1: Preparation
```markdown
□ Log dispatch decision with rationale
□ Inform user of dispatch plan
□ Set up monitoring for agents
□ Prepare timeout handlers
□ Initialize result collection
```

### Phase 2: Launch
```markdown
□ Create agent specifications
□ Validate specifications
□ Dispatch agents (parallel or sequential)
□ Log successful dispatches
□ Handle any launch failures
```

### Phase 3: Monitoring
```markdown
□ Track agent progress
□ Monitor for timeouts
□ Check for early completion
□ Watch token consumption
□ Prepare for partial results
```

### Phase 4: Collection
```markdown
□ Gather all agent results
□ Validate result completeness
□ Check for conflicts
□ Merge results appropriately
□ Handle any failures
```

### Phase 5: Integration
```markdown
□ Integrate into main context
□ Validate integrated state
□ Report to user
□ Log metrics
□ Clean up resources
```

---

## 4. ⚠️ ABORT CONDITIONS

**STOP dispatch if any of these occur:**

1. **Critical Resource Shortage**
   - Token budget drops below 15%
   - Memory pressure warnings
   - Task tool becomes unresponsive

2. **Task Clarification Needed**
   - Ambiguous requirements discovered
   - Conflicting success criteria
   - Missing critical information

3. **High Failure Risk**
   - >2 recent agent failures
   - Unstable system state
   - Critical dependencies unavailable

4. **User Intervention**
   - User requests cancellation
   - User provides new information
   - User changes requirements

---

## 5. 📊 QUALITY GATES

### Pre-Dispatch Quality
```markdown
Minimum Requirements:
✓ Complexity score confidence >80%
✓ Domain identification accuracy >90%
✓ Skill coverage >75% of needed capabilities
✓ Clear success criteria for >80% of tasks
✓ Integration strategy defined
```

### Post-Dispatch Quality
```markdown
Success Metrics:
✓ >90% agents launched successfully
✓ <5% timeout rate
✓ >80% task completion
✓ <10% integration conflicts
✓ User satisfaction with results
```

---

## 6. 🔧 COMMON ISSUES & FIXES

| Issue | Detection | Fix |
|-------|-----------|-----|
| Skills missing | Agent fails early | Add to skill cluster |
| Timeout too short | Agent times out at 90%+ | Increase by 50% |
| Wrong model | Simple task slow | Switch to haiku |
| Tools insufficient | Agent blocked | Expand tool access |
| Prompt unclear | Agent confused | Clarify instructions |
| Integration fails | Conflicts detected | Adjust merge strategy |

---

## 7. 📝 DISPATCH LOG TEMPLATE

```markdown
[timestamp] DISPATCH_VALIDATION
─────────────────────────────
Task: [user request summary]
Complexity: [score]% (confidence: [N]%)
Domains: [list]
Parallel Opportunity: [YES/NO/PARTIAL]

Resource Check:
- Token Budget: [N]% remaining
- Active Agents: [N]/5
- Task Tool: [AVAILABLE/UNAVAILABLE]

Skills Selected:
- [domain]: [skill1, skill2, ...]

Agents to Create: [N]
1. [domain] agent: [description]
2. [domain] agent: [description]

Decision: [DISPATCH/ABORT/MODIFY]
Reason: [explanation]
─────────────────────────────
```

---

## 8. ✅ FINAL VALIDATION

**Before pressing "dispatch":**

1. **Have I checked all resource constraints?**
2. **Is the complexity analysis accurate?**
3. **Are the agent specifications complete?**
4. **Do I have a clear integration plan?**
5. **Have I prepared for failure scenarios?**

**If all YES → DISPATCH**
**If any NO → REVIEW AND REVISE**

---

## 9. 🚀 QUICK DISPATCH COMMANDS

```javascript
// Quick validation
validateDispatch(agents) && dispatch(agents);

// Safe dispatch with fallback
try {
  await dispatchWithValidation(agents);
} catch (error) {
  handleDirectly(task);
}

// Conditional dispatch
if (passesAllChecks()) {
  dispatchParallel(agents);
} else {
  askUserPreference();
}
```

---

## 10. 📖 REFERENCES

- [Complexity Scoring](../references/complexity_scoring.md)
- [Dispatch Decision](../references/dispatch_decision.md)
- [Sub-Agent Lifecycle](../references/sub_agent_lifecycle.md)
- [Error Recovery](../references/quick_reference.md#10--error-recovery)