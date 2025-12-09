# Markdown Optimizer - Quick Reference

One-page cheat sheet for experienced users who need quick command access, quality gates, transformation patterns, and integration points.

---

## 1. 💻 COMMANDS

**Full Pipeline**:
```bash
markdown-c7-optimizer --full document.md
# Runs: Enforcement → Optimization → Validation
```

**Enforcement Only**:
```bash
markdown-c7-optimizer --enforce document.md
# Auto-fixes structure, blocks on critical violations
```

**Optimization Only**:
```bash
markdown-c7-optimizer --optimize document.md
# Improves c7score, generates llms.txt
```

**Validation Only**:
```bash
markdown-c7-optimizer --validate document.md
# Triple scoring report
```

---

## 2. 🔒 QUALITY GATES

| Document Type | Min Overall | Min Structure | Min C7Score | Min Style |
|---------------|-------------|---------------|-------------|-----------|
| SKILL.md      | 85+         | 100           | 75+         | 85+       |
| Command       | 85+         | 100           | 75+         | 85+       |
| Knowledge     | 85+         | 100           | 70+         | 85+       |
| README        | 80+         | 95+           | 70+         | 80+       |
| Spec          | 70+         | 90+           | 60+         | 70+       |

**Quality Badges**:
- ⭐⭐⭐⭐⭐ Excellent (90-100)
- ⭐⭐⭐⭐ Very Good (80-89)
- ⭐⭐⭐ Good (70-79)

---

## 3. 🎨 TRANSFORMATION PATTERNS (TOP 8)

| # | Pattern | Impact | Effort |
|---|---------|--------|--------|
| 1 | API → Usage | +15-20 pts | Medium |
| 2 | Import → Complete | +10-15 pts | Low |
| 3 | Consolidate | +8-12 pts | Medium |
| 4 | Remove Metadata | +5-8 pts | Low |
| 5 | Theory → Practical | +12-18 pts | High |
| 6 | Error → Handling | +8-12 pts | Medium |
| 7 | Complete Examples | +10-15 pts | Medium |
| 8 | Deduplicate | +8-12 pts | Low |

---

## 4. 📚 DOCUMENT TYPES & ENFORCEMENT

**SKILL.md** (Strict):
- YAML frontmatter required
- H1 with subtitle
- No H3+ headings
- Blocks on violations

**Knowledge** (Moderate):
- NO frontmatter
- H1 with subtitle
- Numbered H2 sections
- Blocks on structural issues

**Spec** (Loose):
- Suggestions only
- Never blocks
- Flexible structure

**README** (Flexible):
- Frontmatter optional
- Safe auto-fixes only
- No blocking

**Command** (Strict):
- YAML frontmatter required (description, argument-hint, allowed-tools)
- H1 without subtitle
- Required sections: Purpose, Contract, Instructions, Example Usage
- Template: `assets/command_template.md`

---

## 5. 🛠️ COMMON ISSUES - QUICK FIXES

**Issue**: Hook blocks with "critical violations"
**Fix**: Check `.claude/hooks/logs/quality-checks.log`

**Issue**: Low c7score despite examples
**Fix**: Answer "How do I..." questions, not just API docs

**Issue**: Style score low
**Fix**: All H2 must be ALL CAPS with --- separators

**Issue**: llms.txt fails
**Fix**: Use full URLs (`https://`), H1/H2 only

---

## 6. 📁 FILE STRUCTURE

```
.claude/skills/markdown-c7-optimizer/
├── SKILL.md (overview + quick guidance)
├── references/
│   ├── core_standards.md (filename conventions, document types, violations)
│   ├── optimization.md (c7score metrics, transformation patterns)
│   ├── validation.md (quality scoring, gates, interpretation)
│   ├── workflows.md (execution modes, hooks, troubleshooting)
│   └── quick_reference.md (this file)
├── assets/
│   ├── frontmatter_templates.md (YAML frontmatter examples)
│   ├── command_template.md (slash command templates)
│   ├── llmstxt_templates.md (llms.txt generation examples)
│   └── skill_md_template.md (SKILL.md file templates)
└── scripts/
    └── analyze_docs.py (c7score analyzer)
```

---

## 7. 📊 C7SCORE QUICK GUIDE

**Weights**:
- Question-Snippet: 80% (most important)
- LLM Evaluation: 10%
- Formatting: 5%
- Metadata: 2.5%
- Initialization: 2.5%

**Quick Wins** (+15-20 pts):
1. Transform API refs → complete examples
2. Combine imports with usage
3. Answer top 5 developer questions

---

## 8. 🔗 INTEGRATION POINTS

**Hooks**:
- `PostToolUse/enforce-markdown-post.sh` - Filename fixes
- `UserPromptSubmit/enforce-markdown-strict.sh` - Structure validation

**Skills**:
- Pairs with: `git-commit`, `save-context`, `create-skill`

**External**:
- llms.txt: https://llmstxt.org/
- c7score: Context7 quality benchmark

---

**For complete documentation**: See [SKILL.md](../SKILL.md)