# Workflows - Execution Modes and Enforcement Patterns

Comprehensive reference for execution modes, hook integration patterns, enforcement workflows, and phase interactions for the markdown documentation quality pipeline.

---

## 1. 📖 INTRODUCTION & PURPOSE

### What Are Workflows?

Workflows define the execution patterns and operational modes for the markdown documentation quality pipeline. These workflows orchestrate enforcement, optimization, and validation phases with hook-based automation.

**Core Purpose**:
- **Mode selection** - Four execution modes for different use cases
- **Hook automation** - Non-blocking post-save and blocking pre-submit validation
- **Phase orchestration** - Sequential or independent phase execution
- **Error handling** - Graceful degradation with clear error messages

**Progressive Disclosure Context**:
```
Level 1: SKILL.md metadata (name + description)
         └─ Always in context (~100 words)
            ↓
Level 2: SKILL.md body
         └─ When skill triggers (<5k words)
            ↓
Level 3: Reference files (this document)
         └─ Loaded as needed for workflow details
```

This reference file provides Level 3 deep-dive technical guidance on execution modes, hook patterns, and workflow orchestration.

### Core Principle

**"Structure first, optimize second, validate always"** - Enforce valid markdown structure before content optimization, then verify quality at every stage.

---

## 2. ⚙️ FOUR EXECUTION MODES

| Mode | Phases | Command | Use When | Output |
|------|--------|---------|----------|--------|
| **Full Pipeline** | 1+2+3 | `--full-pipeline` | Critical docs (specs, skills, READMEs) | 85+ overall score |
| **Enforcement Only** | 1 | Automatic (hooks) | File save, structure validation | Valid markdown |
| **Optimization Only** | 2 | `--optimize` | Improve existing docs for AI | 80+ c7score |
| **Validation Only** | 3 | `--validate` | Quality audit, no changes | Score report |

**Mode selection**:
- Creating new SKILL/Knowledge → Full Pipeline
- Saving files → Enforcement (automatic)
- Improving README → Optimization Only
- Pre-release check → Validation Only

---

## 3. 🔗 HOOK INTEGRATION

**PostToolUse Hook** (`enforce-markdown-post.sh`):
- **Trigger**: After Write/Edit/NotebookEdit on `.md` files
- **Action**: Filename corrections (ALL CAPS → lowercase, hyphens → underscores)
- **Blocking**: No (logs only)
- **Speed**: <50ms per file
- **Log**: `.claude/hooks/logs/quality-checks.log`

**UserPromptSubmit Hook** (`enforce-markdown-strict.sh`):
- **Trigger**: Before AI processes prompts
- **Action**: Structure validation + safe auto-fixes
- **Blocking**: Yes (on critical violations)
- **Speed**: <200ms per file
- **Log**: `.claude/hooks/logs/quality-checks.log`

**Hook workflow**:
```
User saves file
    ↓
PostToolUse: Fix filename (non-blocking)
    ↓
User submits prompt
    ↓
UserPromptSubmit: Validate structure
    ├─ Safe violations → Auto-fix → Continue
    └─ Critical violations → Block → Show fixes
```

---

## 4. 🛠️ ENFORCEMENT WORKFLOWS

### ️ Workflow 1: Add Missing Frontmatter

**Detection**: SKILL/Command file, no `---` at line 1

**Fix approach**:
1. Determine document type (SKILL vs Command)
2. Use AskUserQuestion to get metadata
3. Insert frontmatter template at line 1

**Approval prompt template**:
```
Missing required frontmatter. Add the following to line 1?

---
name: [skill-name]
description: [Brief description]
allowed-tools: Read, Write, Edit, Bash
---

Options:
A) Add frontmatter as shown
B) Let me edit manually
C) Skip this file
```

### Workflow 2: Fix Section Order

**Detection**: Required sections out of sequence

**Fix approach**:
1. Identify current section order
2. Map to required order for document type
3. Show proposed reordering

**Approval prompt template**:
```
Section order incorrect. Reorder to match standard?

Current: [current order]
Required: [required order]

Options:
A) Reorder automatically
B) Let me reorder manually
C) Skip validation
```

### Workflow 3: Add Missing Sections

**Detection**: Required section absent (e.g., RULES in SKILL)

**Fix approach**:
1. Identify missing sections
2. Generate section template
3. Insert at appropriate position

**Approval prompt template**:
```
Missing required section: [SECTION NAME]

Add template section at line [N]?

## N.  [SECTION NAME]
[Template content]

Options:
A) Add template section
B) Let me add manually
C) Skip this section
```

---

## 5. 🔄 PHASE INTERACTIONS

**Independent execution**:
- Phase 1 (Enforcement) → Standalone structure validation
- Phase 2 (Optimization) → Standalone content improvement
- Phase 3 (Validation) → Standalone quality audit

**Sequential chaining** (Full Pipeline):
```
Phase 1: Enforce structure
    ├─ Critical violations? → STOP
    └─ Valid → Continue
        ↓
Phase 2: Optimize content
    ├─ Low c7score (<60)? → WARNING
    └─ Continue
        ↓
Phase 3: Validate quality
    ├─ Low overall (<80)? → REPORT
    └─ Complete
```

**Error handling**:
- Phase 1 critical → Block execution, manual fix required
- Phase 2 low score → Warning + suggestions, continues
- Phase 3 low score → Report + improvement plan

---

## 6. 📝 COMMON WORKFLOW EXAMPLES

**Example 1: New SKILL Creation**
```bash
# 1. Create file
mkdir .claude/skills/my-skill
cd .claude/skills/my-skill

# 2. Write initial SKILL.md
# (PostToolUse hook auto-fixes filename)

# 3. Run full pipeline
markdown-c7-optimizer --full-pipeline SKILL.md

# Expected: Structure 100, C7Score 85+, Style 90+, Overall 90+
```

**Example 2: README Optimization**
```bash
# Current README c7score: 52/100
markdown-c7-optimizer --optimize README.md

# Output:
# Before: c7score 52/100
# Applied: 6 patterns
# After: c7score 84/100
```

**Example 3: Pre-Commit Validation**
```bash
# Validate spec before commit
markdown-c7-optimizer --validate specs/042/spec.md

# Output:
# Structure: 100/100
# C7Score: 78/100
# Style: 88/100
# Overall: 89/100 (good)
```

---

## 7. 📦 BATCH PROCESSING

**Multi-file enforcement**:
```bash
find specs/ -name "spec.md" | while read file; do
  markdown-c7-optimizer --full-pipeline "$file"
done
```

**Selective optimization**:
```bash
# Only optimize files with c7score < 70
for file in $(find docs/ -name "*.md"); do
  score=$(markdown-c7-optimizer --validate "$file" | grep "C7Score" | awk '{print $2}' | cut -d'/' -f1)
  if [ "$score" -lt 70 ]; then
    markdown-c7-optimizer --optimize "$file"
  fi
done
```

---

## 8. 🔧 QUICK TROUBLESHOOTING

| Issue | Cause | Solution |
|-------|-------|----------|
| "Execution blocked" | Critical violation | Read error message, apply suggested fix |
| "c7score unavailable" | Tool not installed | `pip install c7score` or set `MARKDOWN_SKIP_C7SCORE=true` |
| "Style dimension N/A" | No style guide | Create `.claude/knowledge/document_style_guide.md` |
| Hook not running | Hook disabled | Check `.claude/hooks/README.md` |
| Wrong type detected | File location mismatch | Use `--type=X` override |
| Safe fix not applied | Permission issue | Check file permissions |

---

## REFERENCES

- Structure rules: [core_standards.md](./core_standards.md)
- Optimization patterns: [optimization.md](./optimization.md)
- Quality scoring: [validation.md](./validation.md)
- Quick commands: [quick_reference.md](./quick_reference.md)