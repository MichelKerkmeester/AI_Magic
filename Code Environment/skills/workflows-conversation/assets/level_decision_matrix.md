# 📊 Level Decision Matrix - Quick Reference for Documentation Level Selection

Quick reference for selecting the appropriate documentation level based on Lines of Code (LOC) and complexity factors. Use this matrix to quickly determine whether your change requires Level 1, 2, or 3 documentation.

---

## 1. 📊 DECISION MATRIX TABLE

| Level | LOC Range | Core Files | Use When | Example Scenarios |
|-------|-----------|------------|----------|------------------|
| **1: Simple** | <100 | `spec.md` | Localized change, clear requirements | Typo fix, bug fix, small enhancement |
| **2: Moderate** | 100-499 | `spec.md` + `plan.md` | Multiple files, moderate complexity | New feature, refactoring |
| **3: Complex** | ≥500 | Full SpecKit | High complexity, multiple systems | Major features, system redesign |

---

## 2. 🎯 PRIMARY DECISION FACTOR: LINES OF CODE (LOC)

**How to count:**
- Count all files being modified
- Include new files being created
- Estimate conservatively (round up when uncertain)

**LOC thresholds:**
- **<100 LOC** → Level 1 (Simple)
- **100-499 LOC** → Level 2 (Moderate)
- **≥500 LOC** → Level 3 (Complex)

**Note:** Single typo/whitespace fixes (<5 characters in one file) are exempt from spec requirements.

---

## 3. ⚖️ SECONDARY FACTORS (CAN OVERRIDE LOC)

These factors can push you to a higher level even if LOC suggests lower:

### 1. Complexity
- **Simple refactor** (no new logic) → May stay at lower level
- **Architectural change** (new patterns) → Escalate to higher level
- **Example**: 200 LOC refactor might stay Level 2, but 200 LOC architectural change could be Level 3

### 2. Risk
- **Config cascades** → Higher level (documentation protects against mistakes)
- **Authentication/security changes** → Higher level (security implications)
- **Example**: 50 LOC config change affecting multiple systems → Level 2 (risk trumps LOC)

### 3. Dependencies
- **Single component** → Lower level acceptable
- **Multiple systems affected** → Higher level needed
- **Example**: 80 LOC touching 5 different modules → Level 2 (coordination needed)

### 4. Testing Needs
- **Unit tests only** → Lower level acceptable
- **Integration/E2E tests required** → Higher level needed
- **Example**: 95 LOC requiring complex integration testing → Level 2 (testing strategy needed)

---

## 4. ⚠️ EDGE CASE GUIDANCE

| Scenario | LOC | Suggested Level | Rationale |
|----------|-----|----------------|-----------|
| Typo in one file | 1 | Exempt | Truly trivial (<5 chars, single file) |
| Typo across 5 files | 5 | Level 1 | Multi-file coordination |
| 95 LOC feature | 95 | Level 1 | Under threshold |
| 105 LOC feature | 105 | Level 2 | Just over, safer with plan |
| Refactor (no new logic) | 200 | Level 2 | Complexity matters more than LOC |
| Config cascade | 50 | Level 2 | Risk trumps LOC |
| Authentication change | 80 | Level 2 | Security implications require planning |
| System redesign | 300 | Level 3 | Architectural impact trumps LOC |

---

## 5. 🤔 WHEN IN DOUBT

**Choose the higher level.**

**Reasoning:**
- Better to over-document than under-document
- Higher level provides more structure and guidance
- Easier to skip optional sections than add missing documentation later
- Future you will thank present you for the extra context

---

## 5.1 📚 RESEARCH VS SPIKE TEMPLATES

**When to use which:**

| Template | Use When | Time Investment | Output |
|----------|----------|-----------------|--------|
| **research_template.md** | Deep technical investigation spanning multiple areas BEFORE implementation | 1-2 days | Comprehensive findings document |
| **research_spike_template.md** | Time-boxed experimentation to answer specific technical questions | 1-3 hours | Go/no-go decision with rationale |

**Decision logic:**
- **Need to explore multiple approaches?** → Use spike (compare options quickly)
- **Need deep understanding of unfamiliar area?** → Use research (thorough investigation)
- **Feasibility unknown?** → Use spike (quick validation)
- **Complex feature requiring architecture decisions?** → Use research first, then spike for unknowns

---

## 6. 🔄 LEVEL MIGRATION DURING IMPLEMENTATION

If scope grows during implementation, you can escalate to a higher level:

| From Level | To Level | Action | Document Change |
|-----------|----------|--------|----------------|
| 1 → 2 | Add `plan.md` to same folder | Update level field, add changelog |
| 2 → 3 | Use `/spec_kit:plan` in same folder | Update level field, add changelog |

**Changelog example:**
```markdown
## Change Log
- 2025-11-15: Created as Level 1 (simple bug fix)
- 2025-11-16: Escalated to Level 2 (discovered architectural changes needed)
```

**Note:** Going down levels is rare (keep higher-level docs even if not all used).

---

## 7. 🚀 QUICK DECISION FLOWCHART

```
Estimate LOC
    ↓
Single typo? ──YES──→ Exempt (no spec needed)
(<5 chars, 1 file)
    │
    NO
    ↓
<100 LOC? ──YES──→ Level 1 (unless complexity/risk high)
    │
    NO
    ↓
<500 LOC? ──YES──→ Level 2
    │
    NO
    ↓
≥500 LOC ────────→ Level 3
```

**Check secondary factors:**
- High complexity? → +1 level
- High risk? → +1 level
- Multiple dependencies? → +1 level
- Complex testing needs? → +1 level

**Final check:** If confidence < 80% on level choice → Ask user or choose higher level.
