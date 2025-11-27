---
name: create-documentation
description: Unified markdown and skill management specialist providing document quality enforcement (structure, c7score, style), content optimization for AI assistants, and complete skill creation workflow (scaffolding, validation, packaging).
allowed-tools: [Read, Write, Edit, Bash, Glob, Grep, AskUserQuestion]
version: 3.2.0
---

# Documentation Creation Specialist

Unified specialist providing: (1) Complete document quality pipeline with structure enforcement, content optimization (c7score), and style guide compliance, and (2) Complete skill creation workflow with scaffolding, validation, and packaging.

**Core principle**: Structure first, then content, then quality = documentation that is valid, AI-friendly, and maintainable.

---

## 1. 🎯 CAPABILITIES OVERVIEW

This skill operates in two primary modes:

### Mode 1: Document Quality Management

Enforce markdown structure, optimize content for AI assistants, and validate quality compliance through a unified 3-phase pipeline: Enforcement → Optimization → Validation.

**Use when**:
- Writing or optimizing markdown documentation
- Enforcing structural standards automatically (via hooks)
- Improving AI-friendliness of documentation (c7score optimization)
- Validating document quality before release

**See**: Sections 2-6 below

### Mode 2: Skill Creation & Management

Guide the creation of effective Claude skills through a structured 6-step workflow: Understanding → Planning → Initialization → Editing → Packaging → Iteration.

**Use when**:
- Creating new Claude skills
- Scaffolding skill directory structure
- Validating skill quality (SKILL.md validation)
- Packaging skills for distribution
- Updating or maintaining existing skills

**See**: Sections 2-6 below and [skill_creation.md](./references/skill_creation.md)

---

## 2. 🧭 SMART ROUTING

```python
def route_documentation_resources(task):
    # MODE 1: Document Quality
    if task.mode == "document_quality":
        if task.checking_structure:
            return load("references/core_standards.md")  # filename, types, violations
        if task.optimizing_content:
            return load("references/optimization.md")  # c7score, 16 transformations
        if task.validating_quality:
            return load("references/validation.md")  # scoring, gates, recommendations
        if task.needs_workflow_guidance:
            return load("references/workflows.md")  # 4 execution modes
    
    # MODE 2: Skill Creation
    if task.mode == "skill_creation":
        if task.creating_skill:
            load("references/skill_creation.md")  # 6-step workflow
            return execute("scripts/init_skill.py")  # scaffolding
        if task.needs_skill_template:
            return load("assets/skill_md_template.md")  # SKILL.md template
        if task.creating_command:
            return load("assets/command_template.md")  # slash command templates
        if task.packaging_skill:
            return execute("scripts/package_skill.py")  # validation + packaging
        if task.quick_validation:
            return execute("scripts/quick_validate.py")  # fast validation
    
    # frontmatter help
    if task.needs_frontmatter:
        return load("assets/frontmatter_templates.md")  # YAML by doc type
    
    # batch analysis
    if task.analyzing_docs:
        return execute("scripts/analyze_docs.py")  # quality automation
    
    # quick lookup
    if task.needs_quick_reference:
        return load("references/quick_reference.md")  # one-page cheat sheet
```

---

## 3. 🗂️ REFERENCES

### Core Framework
| Document                                 | Purpose                               | Key Insight                                |
| ---------------------------------------- | ------------------------------------- | ------------------------------------------ |
| **Create Documentation - Main Workflow** | Core capability and execution pattern | **Specialized auxiliary tool integration** |

### References
| Document | Purpose | Key Insight |
|----------|---------|-------------|
| **references/core_standards.md** | Filename conventions, document types, structural violations | Load for Phase 1 enforcement and violation detection |
| **references/workflows.md** | Four execution modes, hook integration, enforcement patterns | Load for mode selection and workflow guidance |
| **references/optimization.md** | C7score metrics and 16 transformation patterns | Load for Phase 2 optimization and improvement suggestions |
| **references/validation.md** | Quality scoring, gates, and improvement recommendations | Load for Phase 3 validation and quality gates |
| **references/skill_creation.md** | Complete 6-step skill creation workflow with examples | Load for MODE 2 skill creation/updates |
| **references/quick_reference.md** | One-page cheat sheet for fast lookup | Load for quick navigation and decision support |

### Assets
| Document | Purpose | Key Insight |
|----------|---------|-------------|
| **assets/frontmatter_templates.md** | YAML frontmatter templates by document type | Load when creating/validating frontmatter |
| **assets/skill_md_template.md** | Complete SKILL.md file templates | Load for MODE 2 skill initialization |
| **assets/command_template.md** | Claude Code slash command templates (simple, workflow, mode-based, destructive) | Load for command creation/alignment |
| **assets/llmstxt_templates.md** | Example llms.txt files | Load when generating llms.txt |

### Scripts
| Document | Purpose | Key Insight |
|----------|---------|-------------|
| **scripts/analyze_docs.py** | Document quality analysis automation | Execute for batch quality analysis |
| **scripts/init_skill.py** | Skill scaffolding and template generation | Execute for MODE 2 Step 3 initialization |
| **scripts/package_skill.py** | Skill validation and packaging | Execute for MODE 2 Step 5 packaging |
| **scripts/quick_validate.py** | Minimal skill validation | Execute for fast validation checks |

---

## 4. 🎯 WHEN TO USE

### Navigation Guide

**This file (SKILL.md)**: Essential overview and rules for using this skill

**Reference Files** (detailed documentation):
- [core_standards.md](./references/core_standards.md) - Filename conventions, document types, structural violations
- [workflows.md](./references/workflows.md) - Four execution modes, hook integration, enforcement patterns
- [optimization.md](./references/optimization.md) - C7score metrics and 16 transformation patterns
- [validation.md](./references/validation.md) - Quality scoring, gates, and improvement recommendations
- [skill_creation.md](./references/skill_creation.md) - Complete skill creation workflow (6 steps, examples, best practices)
- [quick_reference.md](./references/quick_reference.md) - One-page cheat sheet

**Assets** (templates and output resources):
- [frontmatter_templates.md](./assets/frontmatter_templates.md) - YAML frontmatter templates
- [knowledge_base_template.md](./assets/knowledge_base_template.md) - Knowledge file creation guide
- [skill_md_template.md](./assets/skill_md_template.md) - Complete SKILL.md file templates
- [command_template.md](./assets/command_template.md) - Claude Code slash command templates
- [llmstxt_templates.md](./assets/llmstxt_templates.md) - Example llms.txt files

**Scripts** (automation):
- [analyze_docs.py](./scripts/analyze_docs.py) - Document quality analysis
- [init_skill.py](./scripts/init_skill.py) - Skill scaffolding and template generation
- [package_skill.py](./scripts/package_skill.py) - Skill validation and packaging
- [quick_validate.py](./scripts/quick_validate.py) - Minimal skill validation


### Mode 1: Document Quality Management

#### Automatic Enforcement

Enforcement runs automatically via hooks:

**PostToolUse Hook** - After Write/Edit/NotebookEdit operations:
- Auto-corrects filename violations (ALL CAPS → lowercase, hyphens → underscores)
- Logs corrections, never blocks execution
- Preserves exceptions (README.md, SKILL.md)

**UserPromptSubmit Hook** - Before AI processes prompts:
- Auto-fixes safe violations (separators, H2 case, emoji per "Emoji Usage Rules")
- Blocks execution on critical violations (missing frontmatter, wrong section order)
- Provides specific fix suggestions with line numbers

See [workflows.md](./references/workflows.md) for complete hook integration details.

#### Manual Optimization

Run manual optimization when:

**Content Quality Improvement**:
- README needs optimization for AI assistants (target: c7score 85+)
- Creating critical documentation (specs, knowledge, skills)
- Generating llms.txt for LLM navigation
- Quality assurance before sharing

**Quality Validation**:
- Pre-release quality checks
- Compliance audits across structure, content, and style
- Documentation review (target: 85+ overall score)

See [workflows.md](./references/workflows.md) for workflow examples.

#### When NOT to Use

**Do not use for**:
- Non-markdown files (only `.md` supported)
- Simple typo fixes (use Edit tool directly)
- Internal notes or drafts
- Auto-generated API docs
- Spec files during active development (loose enforcement by design)


### Mode 2: Skill Creation & Management

### Skill Creation Mode Triggers

**Use when**:
- User explicitly requests skill creation ("create a skill", "make a new skill")
- User wants to scaffold skill directory structure
- User needs to validate SKILL.md quality
- User wants to package skill for distribution
- User needs guidance on skill architecture or best practices

**Automatic Triggers**:
- User mentions "create-skill" or "skill creation"
- User asks about skill scaffolding, templates, or structure
- User requests skill validation or packaging
- User asks "how do I create a skill?"

### Skill Creation Workflow Overview

**6-Step Process** (detailed in [skill_creation.md](./references/skill_creation.md)):
1. **Understanding** - Gather concrete examples and use cases
2. **Planning** - Identify reusable resources (scripts, references, assets)
3. **Initialization** - Scaffold skill structure with templates
4. **Editing** - Populate SKILL.md and bundled resources
5. **Packaging** - Validate and create distributable zip file
6. **Iteration** - Test, improve, and maintain

### When NOT to Use

**Do not use for**:
- Creating non-skill documentation (use Document Quality mode)
- Optimizing existing SKILL.md files without user request (use Document Quality mode)
- General markdown editing unrelated to skills

---

## 5. ⚙️ HOW TO USE

### Mode 1: Document Quality

**Three-Phase Pipeline**: Enforcement (structure validation) → Optimization (content enhancement) → Validation (quality scoring). Each phase runs independently or chains sequentially.

**Execution Modes**: See [workflows.md](./references/workflows.md) for mode selection guidance.

| Mode              | Purpose         | Result                                    |
| ----------------- | --------------- | ----------------------------------------- |
| Full Pipeline     | Critical docs   | 85+ overall (structure + c7score + style) |
| Enforcement Only  | Auto via hooks  | Structurally valid markdown               |
| Optimization Only | Content quality | 80+ c7score (AI-friendly)                 |
| Validation Only   | Quality audit   | Triple scoring report                     |

**Document Type Detection** (auto-applies enforcement level):

| Type      | Enforcement | Frontmatter | C7Score Target |
| --------- | ----------- | ----------- | -------------- |
| README    | Flexible    | None        | 85+            |
| SKILL     | Strict      | Required    | 85+            |
| Knowledge | Moderate    | Forbidden   | 80+            |
| Command   | Strict      | Required    | 75+            |
| Spec      | Loose       | Optional    | N/A            |
| Generic   | Flexible    | Optional    | N/A            |

See [core_standards.md](./references/core_standards.md) for complete type system and [optimization.md](./references/optimization.md) for 16 transformation patterns.


### Mode 2: Skill Creation

**6-Step Process**: Understanding (examples) → Planning (resources) → Initialization (init_skill.py) → Editing (populate) → Packaging (package_skill.py) → Iteration (test/improve).

**Progressive Disclosure Design**:
1. Metadata (name + description) - Always in context (~100 words)
2. SKILL.md body - When skill triggers (<5k words)
3. Bundled resources - As needed (unlimited)

**Integration with Document Quality**: After packaging, validate SKILL.md with full pipeline (target: 90+ overall score).

See [skill_creation.md](./references/skill_creation.md) for detailed workflow and [skill_md_template.md](./assets/skill_md_template.md) for templates.

---

## 6. 📋 RULES

### Mode 1: Document Quality

#### ✅ ALWAYS 

1. **ALWAYS validate filename conventions** (snake_case, preserve README.md/SKILL.md)
2. **ALWAYS detect document type first** (applies correct enforcement: strict/moderate/flexible/loose)
3. **ALWAYS verify frontmatter** for SKILL.md and Command types
4. **NEVER add TOC** (TOCs only allowed in README files; never in SKILL, Knowledge, Command, Spec, llms.txt)
5. **ALWAYS ask about llms.txt generation** (use AskUserQuestion, never auto-generate)
6. **ALWAYS apply safe auto-fixes** (H2 case, separators, filenames - log all changes)
7. **ALWAYS validate before completion** (structure + c7score + style scores)
8. **ALWAYS provide metrics** (before/after scores, improvement deltas)

See [core_standards.md](./references/core_standards.md) for detailed rationale and enforcement patterns.

#### ❌ NEVER

1. **NEVER modify spec files during active development** (loose enforcement only)
2. **NEVER delete original content without approval** (preserve until validated)
3. **NEVER block for safe violations** (only block: missing frontmatter, wrong order, invalid structure)
4. **NEVER generate llms.txt without asking** (explicit user consent required)
5. **NEVER apply wrong enforcement level** (README/Generic: flexible, SKILL/Command: strict, Knowledge: moderate, Spec: loose)

**Note**: For emoji usage rules, see "Emoji Usage Rules" subsection below.

#### ⚠️ ESCALATE IF

1. **Document type ambiguous** (clarify with AskUserQuestion)
2. **Critical violations detected** (missing frontmatter, wrong order - user must fix)
3. **Major restructuring needed** (c7score <40, get approval)
4. **Style guide missing** (ask if user wants to create)
5. **Conflicts with user intent** (get confirmation before changes)


### Mode 2: Skill Creation

#### ✅ ALWAYS

1. **ALWAYS start with concrete examples** (validate understanding first)
2. **ALWAYS run init_skill.py** (proper scaffolding with templates)
3. **ALWAYS identify bundled resources** (scripts/references/assets with rationale)
4. **ALWAYS use third-person** ("Use when..." not "You should use...")
5. **ALWAYS keep SKILL.md <5k words** (move details to references/)
6. **ALWAYS delete unused examples** (keep lean after initialization)
7. **ALWAYS validate before packaging** (package_skill.py checks)
8. **ALWAYS recommend quality validation** (target 90+ overall score)

See [skill_creation.md](./references/skill_creation.md) for workflow details and best practices.

#### ❌ NEVER

1. **NEVER use second-person** (imperative/infinitive form only)
2. **NEVER duplicate SKILL.md/references/** (progressive disclosure)
3. **NEVER create without examples** (examples validate understanding)
4. **NEVER skip validation** (prevents broken skill distribution)
5. **NEVER include excessive detail** (SKILL.md is orchestrator)
6. **NEVER use vague descriptions** (specific capabilities and workflows)

#### ⚠️ ESCALATE IF

1. **Skill purpose unclear** (multiple interpretations or contradictory examples)
2. **No concrete examples** (cannot proceed without understanding)
3. **Validation fails repeatedly** (architectural issues)
4. **Unsupported features** (discuss workarounds/alternatives)
5. **User input required** (brand assets, API docs, schemas)

### Emoji Usage Rules

**Heading Emoji Requirements**:

| Heading Level    | Emoji Rule               | Example                        |
| ---------------- | ------------------------ | ------------------------------ |
| **H1** (`#`)     | ❌ NEVER use emoji        | `# Documentation Specialist`   |
| **H2** (`##`)    | ✅ ALWAYS include emoji   | `## 1. 🎯 CAPABILITIES`         |
| **H3** (`###`)   | ⚠️ SEMANTIC ONLY         | `### ✅ ALWAYS` (RULES only)   |
| **H4+** (`####`) | ❌ NEVER use emoji        | `#### Success Metrics`         |

**Body Text Emoji Usage**:
- ✅ Status indicators in lists: ✅ ❌ ⚠️
- ✅ Priority markers: 🔴 🟡 🔵
- ✅ Visual indicators: 📊 🔍 ⚡
- ⚠️ Only use when explicitly requested by user or when enhancing clarity

**H3 Semantic Emoji Exception - RULES Sections**:

Semantic emojis (✅ ❌ ⚠️) are REQUIRED on H3 subsections within RULES sections for functional signaling:

```markdown
## N. 📖 RULES

### ✅ ALWAYS

[content]

### ❌ NEVER

[content]

### ⚠️ ESCALATE IF

[content]
```

**Key distinctions**:
- **Semantic emojis** (✅ ❌ ⚠️): Functional signaling, required in RULES sections
- **Decorative emojis** (🔧 💡 📦): Category markers, prohibited on H3 headings
- **No dividers**: Never use `---` between H3 subsections (use blank lines only)

**Rationale**:
- H2 emoji provides visual hierarchy and scanning structure
- H1 emoji-free maintains document title clarity
- H3 semantic-only prevents visual clutter while preserving functional signals in RULES sections
- Semantic emojis (✅ ❌ ⚠️) provide instant cognitive mapping in rules/guidelines
- No dividers between H3 subsections prevents fragmentation and maintains section cohesion
- Body emoji enhances readability when used purposefully

---

## 7. 🏆 SUCCESS CRITERIA

### Mode 1: Document Quality

#### Quality Score Thresholds

**Excellent (90-100)**:
- Structure: 100/100 (perfect validity)
- C7Score: 85+/100 (highly AI-friendly)
- Style: 90+/100 (exemplary compliance)
- Overall: 90+/100
- Status: Ready for production, no improvements needed

**Good (80-89)**:
- Structure: 95+/100
- C7Score: 75+/100
- Style: 85+/100
- Overall: 85+/100
- Status: Ready for sharing, minor improvements optional

**Acceptable (70-79)**:
- Structure: 90+/100
- C7Score: 65+/100
- Style: 75+/100
- Overall: 75+/100
- Status: Functional, optimization recommended

**Needs Improvement (<70)**:
- Any dimension <70
- Overall <75
- Status: Significant improvements required

### Completion Checklist

**Phase 1 Complete:**
- ✅ No critical violations detected
- ✅ All safe violations auto-fixed
- ✅ Structure score: 100/100
- ✅ Document type correctly detected

**Phase 2 Complete:**
- ✅ c7score improvement shown (before → after)
- ✅ Transformation patterns applied (list provided)
- ✅ Content optimized for AI assistants
- ✅ llms.txt generated (if user requested)

**Phase 3 Complete:**
- ✅ Triple scoring completed (structure, c7score, style)
- ✅ Overall score calculated
- ✅ Quality gate evaluation shown
- ✅ Improvement recommendations provided (if needed)

### Document-Type Specific Gates

**SKILL.md**:
- Structure: 100/100 (strict, no exceptions)
- C7Score: 85+/100
- Overall: 90+/100
- Required: Frontmatter, WHEN TO USE, HOW TO USE, RULES sections

**README.md**:
- Structure: 95+/100 (flexible enforcement)
- C7Score: 85+/100
- Overall: 85+/100
- Focus: Quick Start, usage examples, question-answering format

**Knowledge**:
- Structure: 100/100 (no frontmatter allowed)
- C7Score: 80+/100
- Overall: 85+/100
- Required: Numbered H2 sections, concept → implementation → examples

See [validation.md](./references/validation.md) for complete scoring details.


### Mode 2: Skill Creation

#### Skill Completion Checklist

**Skill is complete when**:
- ✅ YAML frontmatter includes name and description
- ✅ Description uses third-person form
- ✅ Description is specific (not generic)
- ✅ SKILL.md under 5k words
- ✅ All bundled resources properly organized
- ✅ Unused example files deleted
- ✅ Passes validation checks (package_skill.py)
- ✅ Successfully packages into zip file
- ✅ SKILL.md quality validated (90+ overall score)
- ✅ Tested on real examples

### Quality Targets for SKILL.md

When validating SKILL.md with Document Quality mode:
- **Structure**: 100/100 (strict enforcement)
- **C7Score**: 85+/100 (AI-friendly)
- **Style**: 90+/100 (exemplary)
- **Overall**: 90+/100 (production ready)

### Validation Success

**Minimal validation** (package_skill.py):
- ✅ SKILL.md exists
- ✅ YAML frontmatter present and valid
- ✅ Required fields: name, description
- ✅ Name is hyphen-case
- ✅ No angle brackets in description

**Comprehensive validation** (Document Quality mode):
- ✅ All minimal validation checks
- ✅ Proper section structure (WHEN TO USE, HOW TO USE, RULES)
- ✅ Heading hierarchy correct
- ✅ Emoji usage follows "Emoji Usage Rules" (H2 required, H1/H3/H4+ never)
- ✅ Code blocks properly fenced
- ✅ High c7score (AI-friendly)
- ✅ Style guide compliance

---

## 8. 🔌 INTEGRATION POINTS

### Mode 1: Document Quality

#### Hook System Integration

**PostToolUse Hook** (`enforce-markdown-post.sh`):
- Triggers after Write/Edit/NotebookEdit operations
- Purpose: Filename enforcement (automatic corrections)
- Execution: <50ms per file (non-blocking)
- Logging: `.claude/hooks/logs/quality-checks.log`

**UserPromptSubmit Hook** (`enforce-markdown-strict.sh`):
- Triggers before AI processes user prompts
- Purpose: Structure validation and safe auto-fixes
- Execution: <200ms per file
- Blocking: Only on critical violations
- Logging: `.claude/hooks/logs/quality-checks.log`

See [workflows.md](./references/workflows.md) for hook integration details.

#### Tool Usage Guidelines

**Read tool**: Examine files before optimization, check existing structure

**Write tool**: Create optimized versions or llms.txt files

**Edit tool**: Apply specific transformations for safe auto-fixes

**Bash tool**: Execute c7score command-line tool for scoring, run init/package scripts

**Glob tool**: Find multiple markdown files for batch processing

**Grep tool**: Search for patterns or violations across files

**AskUserQuestion tool**: Required for llms.txt generation consent, document type clarification, major restructuring approval

#### Knowledge Base Dependencies

**Required:**
- Style standards enforced via bundled `references/core_standards.md`
  - No external dependencies required
  - Self-contained style enforcement

**Optional:**
- `.claude/knowledge/code_standards.md` - Code example validation
  - If missing: Skip code validation
  - Used by: Code example formatting checks

**Recommended:**
- `.claude/knowledge/conversation_documentation.md` - Spec folder system
  - Integration: Validates spec folder documentation
  - Used by: Spec type detection and enforcement level selection

#### External Tools

**c7score** (Python package):
- Installation: `pip install c7score`
- Purpose: AI-friendliness scoring
- Fallback: `export MARKDOWN_SKIP_C7SCORE=true` to disable


### Mode 2: Skill Creation

#### Skill Creation Scripts

**init_skill.py**:
- Purpose: Generate skill directory structure with templates
- Usage: `scripts/init_skill.py <skill-name> --path <output-dir>`
- Creates: SKILL.md template, example resources

**package_skill.py**:
- Purpose: Validate and package skill into zip file
- Usage: `scripts/package_skill.py <skill-path> [output-dir]`
- Validates: Frontmatter, naming conventions, structure
- Output: `<skill-name>.zip`

**quick_validate.py**:
- Purpose: Minimal validation for essential requirements
- Usage: `scripts/quick_validate.py <skill-path>`
- Checks: Frontmatter presence, required fields, format

#### Workflow Integration

**Skill Creation → Document Quality**:
1. Initialize skill (init_skill.py)
2. Edit SKILL.md and resources
3. Package skill (package_skill.py - minimal validation)
4. Quality validation (Document Quality mode - comprehensive)
5. Iterate if score <90

**Example Command Sequence**:
```bash
# Create skill
scripts/init_skill.py my-skill --path .claude/skills

# [User edits SKILL.md and bundled resources]

# Package with validation
scripts/package_skill.py .claude/skills/my-skill

# Quality assurance (comprehensive)
markdown-document-specialist --full-pipeline .claude/skills/my-skill/SKILL.md
```

#### Related Skills

**workflows-save-context**: Context files saved by workflows-save-context skill can be optimized
- Document type: memory (flexible enforcement)
- Optional optimization for clarity and future reference
- No blocking violations on memory files

---

## 9. 📚 ADDITIONAL RESOURCES

### Skill Resources

**Reference Documentation** (detailed guides):
- `references/core_standards.md` - Filename conventions, document types, structural violations
- `references/workflows.md` - Four execution modes, hook integration, enforcement patterns
- `references/optimization.md` - C7score metrics and 16 transformation patterns
- `references/validation.md` - Quality scoring, gates, and improvement recommendations
- `references/quick_reference.md` - One-page cheat sheet for document quality
- `references/skill_creation.md` - Complete skill creation workflow (6 steps, examples, best practices)

**Assets** (templates and examples):
- `assets/frontmatter_templates.md` - YAML frontmatter by document type
- `assets/knowledge_base_template.md` - Knowledge file creation guide
- `assets/skill_md_template.md` - Complete SKILL.md file templates
- `assets/command_template.md` - Claude Code slash command templates (simple, workflow, mode-based, destructive)
- `assets/llmstxt_templates.md` - Example llms.txt files

**Scripts** (automation):
- `scripts/analyze_docs.py` - Document quality analysis
- `scripts/init_skill.py` - Skill scaffolding and template generation
- `scripts/package_skill.py` - Skill validation and packaging
- `scripts/quick_validate.py` - Minimal skill validation

### External Documentation

- **llms.txt specification**: https://llmstxt.org/
- **c7score benchmarking**: https://context7.ai/ (AI documentation quality)
- **Code standards**: `.claude/knowledge/code_standards.md`

### Related Standards

- **Structural rules**: [core_standards.md](./references/core_standards.md)
- **Execution workflows**: [workflows.md](./references/workflows.md)
- **Content optimization**: [optimization.md](./references/optimization.md)
- **Quality validation**: [validation.md](./references/validation.md)
- **Skill creation workflow**: [skill_creation.md](./references/skill_creation.md)
- **Knowledge file guide**: [knowledge_base_template.md](./assets/knowledge_base_template.md)
- **SKILL.md templates**: [skill_md_template.md](./assets/skill_md_template.md)
- **Frontmatter formats**: [frontmatter_templates.md](./assets/frontmatter_templates.md)

### Quick Navigation

**Document Quality**:
- Getting started: Read this SKILL.md, then [quick_reference.md](./references/quick_reference.md)
- Execution modes and workflows: [workflows.md](./references/workflows.md)
- Document types and rules: [core_standards.md](./references/core_standards.md)
- Optimization patterns: [optimization.md](./references/optimization.md)

**Skill Creation**:
- Getting started: Read this SKILL.md Sections 2, 3, 4, 5, 6
- Complete workflow: [skill_creation.md](./references/skill_creation.md)
- Script usage: [skill_creation.md](./references/skill_creation.md) Section 11

---

## 10. 🚀 QUICK START

### For Document Quality

1. **Read**: This SKILL.md Section 4 (When to Use), Section 5 (How to Use), Section 6 (Rules), Section 7 (Success Criteria)
2. **Navigate**: [workflows.md](./references/workflows.md) for execution modes
3. **Use**: Run enforcement, optimization, or validation as needed

### For Skill Creation

1. **Read**: This SKILL.md Section 4 (When to Use), Section 5 (How to Use), Section 6 (Rules), Section 7 (Success Criteria)
2. **Navigate**: [skill_creation.md](./references/skill_creation.md) for complete workflow
3. **Use Scripts**: init_skill.py → edit → package_skill.py
4. **Validate**: Run Document Quality mode on SKILL.md (target 90+)

### Quick Reference

Need fast navigation? See [quick_reference.md](./references/quick_reference.md)

---

**Remember**: This skill operates in two modes - Document Quality and Skill Creation. Both modes integrate seamlessly for creating and validating high-quality skills.