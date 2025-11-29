# Agent Orchestrator - Quick Reference

One-page decision guide for dynamic sub-agent dispatch.

---

## 1. 🎯 DECISION FLOW

```
Request → Analyze Complexity → Check Thresholds → Dispatch or Direct
```

### Complexity Score Thresholds
- **<20%**: Direct handling (silent, no question)
- **20-49% + ≥2 domains**: **MANDATORY QUESTION** - User chooses A/B/C
- **≥50% + 3+ domains**: Auto-dispatch (notification only, no question)

### Quick Complexity Calculator
```
Domain Count × 35%     (1=0, 2=0.5, 3+=1.0)
File Count × 25%       (1-2=0, 3-5=0.5, 6+=1.0)
LOC Estimate × 15%     (<50=0, 50-200=0.5, 200+=1.0)
Parallel Opp × 20%     (none=0, some=0.5, high=1.0)
Task Type × 5%         (trivial=0, moderate=0.5, complex=1.0)
───────────────────────────────────────────────────
Total Score = Sum of weighted components (0-100%)
```

---

## 2. ✅ WHEN TO DISPATCH

### AUTO-DISPATCH (Score ≥35%)
✓ Multi-domain tasks (code + docs + git)
✓ 3+ independent failures to debug
✓ Parallel execution opportunities
✓ Complex feature implementation
✓ Broad codebase analysis

### Example Requests
- "Refactor auth system, update docs, and commit"
- "Fix failing tests in auth, payment, and shipping"
- "Find all API endpoints and document them"

---

## 3. ❌ WHEN NOT TO DISPATCH

### ALWAYS DIRECT
✗ Token budget <20%
✗ Single domain only
✗ Sequential dependencies only
✗ Trivial changes (<5 min)
✗ Single file modifications

### Example Requests
- "Fix typo in README"
- "Add missing semicolon"
- "Build then test"
- "Change variable name"

---

## 4. 🤝 MANDATORY QUESTION ZONE (20-49% + ≥2 domains)

### User Must Choose (via AskUserQuestion):
```markdown
**How should I approach this task?**

A) Sequential (~X min) - Traditional approach, simpler to debug
B) Parallel agents (~Y min) - Create N specialized agents, 40% faster
C) Auto-decide for me - Enable automatic mode for this session

(Override anytime with: "proceed directly", "use parallel", "auto-decide")
```

**Exception:** If sequential dependencies detected (e.g., "first X then Y"), question is **SKIPPED** and task handled directly (no parallelization benefit).

---

## 5. 🎛️ OVERRIDE PHRASES

### Bypass Mandatory Question with Explicit Phrases:

**Force Direct Handling:**
- `"proceed directly"` - Skip question, handle sequentially
- `"handle directly"` - Skip question, handle sequentially
- `"skip parallel"` - Skip question, handle sequentially

**Force Parallel Dispatch:**
- `"use parallel agents"` - Skip question, dispatch immediately
- `"dispatch agents"` - Skip question, dispatch immediately
- `"parallelize"` - Skip question, dispatch immediately

**Enable Auto-Decide Mode:**
- `"auto-decide"` - Skip question, enable session auto-mode
- `"auto decide"` - Skip question, enable session auto-mode
- `"automatic mode"` - Skip question, enable session auto-mode

**Session Persistence:** User preference stored for 1 hour, applies to all subsequent prompts in session.

**Detection Patterns:** Sequential dependencies (e.g., "first X then Y", "after X complete", "once X done", "when X finishes", "X followed by Y", "X, then Y") automatically set parallel_opportunity=0 and skip the question regardless of complexity score.

---

## 6. 📊 DOMAIN CLUSTERING

| Domain | Core Skills | Tools |
|--------|------------|-------|
| **Code** | workflows-code, mcp-semantic-search | Read, Write, Edit, Bash |
| **Analysis** | mcp-semantic-search, workflows-code | Read, Grep, Glob, WebSearch |
| **Docs** | create-documentation, workflows-spec-kit | Read, Write, WebSearch |
| **Git** | workflows-git, workflows-save-context | Bash, Read |
| **Test** | workflows-code, mcp-semantic-search | Read, Write, Bash |
| **DevOps** | mcp-code-mode, cli-gemini | Bash, Read, Edit |

> **6 domains total**: code, analysis, docs, git, test, devops

> ⚠️ **Excluded Keywords**: Generic verbs (`add`, `update`, `create`, `check`, `review`, `find`) are excluded to prevent over-matching. The word `api` alone is excluded from code domain—use `endpoint` or `route` instead.

---

## 7. 🚀 SUB-AGENT SPEC TEMPLATE

```typescript
{
  description: "${domain} task in <10 words",
  subagent_type: "general-purpose",
  model: "haiku", // or "sonnet" for complex
  prompt: "Detailed instructions with skills...",
  timeout: 300000  // 5 minutes default
}
```

### Model Selection
- **haiku**: Simple tasks, docs, quick fixes
- **sonnet**: Complex code, debugging
- **inherit**: Use parent model

---

## 8. 📈 PERFORMANCE TARGETS

- Analysis: <500ms
- Dispatch: <2s overhead
- Total overhead: <10% of task time
- Success rate: >90%
- Timeout rate: <5%

---

## 9. 🔧 RESOURCE LIMITS

- Max concurrent agents: 5
- Default timeout: 5 minutes
- Token budget per agent: 10%
- Min token budget for dispatch: 20%

---

## 10. 🎬 LIFECYCLE PHASES

```
1. CREATE → Build spec (500ms)
2. DISPATCH → Task tool (1s)
3. EXECUTE → Autonomous (30s-5min)
4. INTEGRATE → Merge results (500ms)
5. CLEANUP → Release resources (100ms)
```

---

## 11. 🚨 ERROR RECOVERY

| Error Type | Recovery Strategy |
|------------|------------------|
| Timeout | Use partial results, handle remainder directly |
| Failure | Retry once, then fallback to direct |
| Token limit | Abort dispatch, handle directly |
| Parse error | Use basic skill set, continue degraded |

---

## 12. 📝 LOGGING

```bash
# Check decisions
tail -50 .claude/hooks/logs/orchestrator.log

# View skill recommendations
cat .claude/hooks/logs/skill-recommendations.log
```

---

## 13. 🎯 COMMON PATTERNS

### Pattern: Multi-Domain Feature
```
"Implement X with tests and docs"
→ 3 agents: code, test, docs
→ Parallel execution
→ 60% time savings
```

### Pattern: Parallel Debugging
```
"Fix 3 independent failures"
→ 3 agents: one per failure
→ Concurrent investigation
→ 3x faster resolution
```

### Pattern: Sequential Task
```
"Build, test, then deploy"
→ No agents (sequential)
→ Direct handling
→ Dependencies prevent parallel
```

---

## 14. 💡 PRO TIPS

1. **Trust the scores** - Tuned from real usage
2. **When in doubt, ask** - Collaborative mode for borderline cases
3. **Monitor tokens** - Dispatch disabled <20% budget
4. **Log everything** - Helps tune thresholds
5. **Partial > nothing** - Failed agents may still provide value

---

## 15. 🔗 QUICK LINKS

- Full documentation: [SKILL.md](../SKILL.md)
- Complexity scoring: [complexity_scoring.md](./complexity_scoring.md)
- Skill clustering: [skill_clustering.md](./skill_clustering.md)
- Dispatch decisions: [dispatch_decision.md](./dispatch_decision.md)
- Agent lifecycle: [sub_agent_lifecycle.md](./sub_agent_lifecycle.md)