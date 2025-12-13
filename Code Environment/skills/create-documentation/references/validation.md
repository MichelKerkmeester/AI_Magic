# Validation - Quality Scoring and Gates

Comprehensive reference for triple dimension scoring, quality gates, score interpretation, and improvement recommendations for markdown documentation.

---

## 1. 📖 INTRODUCTION & PURPOSE

### What Is Validation?

Validation provides a comprehensive quality assessment framework for markdown documentation using three independent scoring dimensions: Structure, C7Score (AI-friendliness), and Style compliance.

**Core Purpose**:
- **Quality measurement** - Objective scoring across structure, content, and style
- **Quality gates** - Document-specific thresholds for production readiness
- **Improvement guidance** - Actionable recommendations based on score analysis
- **CI/CD integration** - Automated quality checks with exit codes

**Progressive Disclosure Context**:
```
Level 1: SKILL.md metadata (name + description)
         └─ Always in context (~100 words)
            ↓
Level 2: SKILL.md body
         └─ When skill triggers (<5k words)
            ↓
Level 3: Reference files (this document)
         └─ Loaded as needed for scoring details
```

This reference file provides Level 3 deep-dive technical guidance on quality scoring, gates, and interpretation patterns.

### Core Principle

**"Measure what matters, gate what guarantees quality"** - Structure ensures validity, C7Score ensures AI-friendliness, Style ensures consistency. All three dimensions must meet thresholds for production readiness.

---

## 2. 📊 TRIPLE DIMENSION SCORING

**Phase 3 validates across three independent dimensions:**

```
INPUT: Optimized Markdown
    ↓
DIMENSION 1: Structure (0-100)
    - Frontmatter validity
    - Heading hierarchy
    - Section order
    - Format compliance
    ↓
DIMENSION 2: C7Score (0-100)
    - Question-snippet matching (80%)
    - LLM evaluation (10%)
    - Formatting (5%)
    - Metadata removal (2.5%)
    - Initialization (2.5%)
    ↓
DIMENSION 3: Style (0-100)
    - core_standards.md compliance
    - H2 formatting
    - Code example standards
    - Tone and voice
    ↓
OUTPUT: Overall Score (weighted average)
```

---

## 3. 🔢 SCORING BREAKDOWN

### Dimension 1: Structure (0-100)

**Checks**:
- ✅ YAML frontmatter valid (if required)
- ✅ Single H1, no duplicates
- ✅ Proper heading hierarchy (no skipped levels)
- ✅ Required sections present and ordered
- ✅ Section separators (`---`) correct
- ✅ Code blocks properly fenced
- ✅ No unclosed markdown elements
- ✅ Emoji usage correct (H2 numbered have emoji, H3 semantic only in RULES sections, H1/H4+/H5/H6 no emoji)
- ✅ RULES section H3 subsections have required semantic emojis (✅ ❌ ⚠️)
- ✅ Horizontal dividers (`---`) only between major H2 sections (not between H3 subsections)

**Scoring**:
- 100 = Perfect structure, no violations
- 95-99 = Minor formatting issues (auto-fixable)
- 90-94 = Missing optional sections
- <90 = Critical violations present

**Emoji violations** (deduct points):
- -1 point: H1 has emoji
- -1 point: H2 numbered missing emoji
- -0.5 point: H3 has decorative emoji outside RULES section (🔧 💡 📦)
- -1 point: RULES section H3 missing semantic emoji (✅ ❌ ⚠️)
- -1 point: H4/H5/H6 has emoji

**Divider violations** (deduct points):
- -0.5 point: Missing `---` between major H2 sections
- -1 point: Horizontal divider (`---`) between H3 subsections within same H2
- -0.5 point: Excessive blank lines around dividers

**Target**: 100 for SKILL/Knowledge, 95+ for README/Spec

### Dimension 2: C7Score (0-100)

**Components** (see [optimization.md](./optimization.md) for details):
- Question-snippet matching: 0-80 points
- LLM evaluation: 0-10 points
- Formatting: 0-5 points
- Metadata removal: 0-2.5 points
- Initialization: 0-2.5 points

**Scoring**:
- 90-100 = Excellent, comprehensive question coverage
- 80-89 = Good, minor gaps
- 70-79 = Acceptable, needs more examples
- 60-69 = Fair, significant gaps
- <60 = Poor, major restructuring needed

**Target**: 85+ for critical docs, 80+ for others

### Dimension 3: Style (0-100)

**Checks** (from `references/core_standards.md`):
- ✅ Frontmatter format matches guide
- ✅ H2 numbered headings: ALL CAPS + emoji (e.g., `## 1. 🎯 WHEN TO USE`)
- ✅ H3 headings: Only semantic emojis (✅ ❌ ⚠️), no decorative emojis
- ✅ Code examples include comments
- ✅ Bullet lists under 7 items
- ✅ Consistent terminology
- ✅ Active voice preferred
- ✅ No emojis in body text (unless guide allows)

**Emoji style compliance**:
- ✅ Semantic emojis on H3: `### ✅ ALWAYS Rules` (functional signal)
- ❌ Decorative emojis on H3: `### 🔧 Pattern 1` (visual noise)
- See [core_standards.md](./core_standards.md#6--emoji-usage-rules) for criteria

**Scoring**:
- 95-100 = Exemplary compliance
- 90-94 = Good compliance, minor issues
- 85-89 = Acceptable, some violations
- <85 = Non-compliant, needs revision

**Target**: 90+ for shared docs, 85+ for internal

**Note**: Style rules are defined in `references/core_standards.md`

---

## 4. 🧮 OVERALL SCORE CALCULATION

**Formula**:
```
Overall = (Structure × 0.40) + (C7Score × 0.40) + (Style × 0.20)
```

**Weights rationale**:
- Structure (40%): Validity is foundational
- C7Score (40%): AI-friendliness is primary goal
- Style (20%): Consistency matters but less critical

**Example**:
```
Structure: 100
C7Score: 85
Style: 90

Overall = (100 × 0.4) + (85 × 0.4) + (90 × 0.2)
        = 40 + 34 + 18
        = 92 (Excellent)
```

---

## 5. 🔒 QUALITY GATES

### Rating Scale

| Score | Rating | Status | Action |
|-------|--------|--------|--------|
| **90-100** | Excellent | ✅ Production ready | None needed |
| **80-89** | Good | ✅ Shareable | Optional improvements |
| **70-79** | Acceptable | ⚠️ Functional | Optimization recommended |
| **60-69** | Fair | ⚠️ Needs work | Optimization required |
| **<60** | Poor | ❌ Unacceptable | Major restructuring |

### Document-Specific Thresholds

**SKILL.md**:
```
Structure: 100 (strict, no exceptions)
C7Score: 85+ (highly AI-friendly)
Style: 90+ (exemplary)
Overall: 90+ required
```

**Knowledge**:
```
Structure: 100 (strict frontmatter rules)
C7Score: 80+ (good AI-friendliness)
Style: 85+ (consistent)
Overall: 85+ required
```

**README**:
```
Structure: 95+ (flexible enforcement)
C7Score: 85+ (highly AI-friendly)
Style: 85+ (good compliance)
Overall: 85+ required
```

**Command**:
```
Structure: 100 (strict)
C7Score: 75+ (functional)
Style: 85+ (consistent)
Overall: 85+ required
```

**Spec**:
```
Structure: 90+ (loose, working doc)
C7Score: N/A (not enforced)
Style: 80+ (basic compliance)
Overall: 80+ suggested
```

---

## 6. 📈 SCORE INTERPRETATION

### High Structure, Low C7Score

**Example**: Structure 100, C7Score 65, Style 90 → Overall 85

**Diagnosis**: Valid markdown but poor question coverage

**Fix**: Apply transformation patterns (see [optimization.md](./optimization.md))
- Add question-answering snippets
- Combine import-only with usage
- Provide complete workflow examples

### High C7Score, Low Style

**Example**: Structure 100, C7Score 90, Style 70 → Overall 86

**Diagnosis**: AI-friendly but inconsistent formatting

**Fix**: Apply style guide compliance
- Fix H2 heading format (title case + emoji)
- Add code comments
- Break long bullet lists
- Use consistent terminology

### High C7Score + Style, Low Structure

**Example**: Structure 85, C7Score 90, Style 90 → Overall 88

**Diagnosis**: Good content but structural violations

**Fix**: Run enforcement phase
- Add missing frontmatter
- Fix heading hierarchy
- Reorder sections
- Close unclosed elements

### ️ Balanced Low Scores

**Example**: Structure 75, C7Score 70, Style 75 → Overall 73

**Diagnosis**: Multiple quality issues

**Fix**: Run full pipeline (Enforcement → Optimization → Validation)

---

## 7. 💡 IMPROVEMENT RECOMMENDATIONS

**When Overall < 80**:

1. **Run enforcement** - Fix structural issues first
2. **Identify lowest dimension** - Focus improvement efforts
3. **Apply targeted patterns** - Use optimization patterns for c7score
4. **Re-validate** - Check improvement
5. **Iterate** - Repeat until threshold met

**Priority order**:
1. Structure (if < 90) - Must be valid before optimizing
2. C7Score (if < 80) - Primary optimization target
3. Style (if < 85) - Polish for consistency

**Quick fixes** (high impact, low effort):
- Structure: Add frontmatter, fix heading levels
- C7Score: Combine installation + usage, remove metadata
- Style: Fix H2 case, add emoji, break long lists

---

## 8. 📋 VALIDATION OUTPUT FORMAT

**Example report**:
```
=== Quality Report: specs/042/spec.md ===

Document Type: spec (loose enforcement)

DIMENSION 1: Structure (100/100) ✅
✓ Valid YAML frontmatter
✓ Single H1 with subtitle
✓ Proper heading hierarchy
✓ Required sections present
✓ Section separators correct

DIMENSION 2: C7Score (78/100) ⚠️
Question-answering: 62/80
  Missing answers for:
  - "How does this integrate with existing systems?"
  - "What are performance implications?"
Concrete examples: 7/10
LLM evaluation: 9/10
Formatting: 5/5
Metadata removal: 2.5/2.5

DIMENSION 3: Style (88/100) ✓
✓ Frontmatter format matches guide
✓ H2 headings use title case + emoji
✓ Code examples include comments
⚠ Some bullet lists exceed 7 items

OVERALL SCORE: 89/100 (Good Quality)

RECOMMENDATIONS:
1. Add integration architecture section (c7score +5)
2. Add performance benchmarks (c7score +3)
3. Break long bullet lists (style +5)

Estimated improvement: 89 → 97
```

---

## 9. 💻 VALIDATION COMMANDS

**Validate single file**:
```bash
markdown-c7-optimizer --validate document.md
```

**Validate with threshold**:
```bash
markdown-c7-optimizer --validate --threshold=85 document.md
# Exit code 1 if score < 85
```

**Batch validation**:
```bash
find specs/ -name "*.md" | while read file; do
  markdown-c7-optimizer --validate "$file"
done
```

**CI/CD integration**:
```bash
# Fail build if documentation quality < 80
markdown-c7-optimizer --validate --threshold=80 README.md || exit 1
```

---

## REFERENCES

- Structure rules: [core_standards.md](./core_standards.md)
- Execution modes: [workflows.md](./workflows.md)
- Optimization patterns: [optimization.md](./optimization.md)
- Quick commands: [quick_reference.md](./quick_reference.md)