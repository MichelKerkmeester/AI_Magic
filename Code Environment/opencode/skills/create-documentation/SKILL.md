---
name: create-documentation
description: Unified markdown and skill management specialist providing document quality enforcement (structure, c7score, style), content optimization for AI assistants, complete skill creation workflow (scaffolding, validation, packaging), and ASCII flowchart creation for visualizing complex workflows, user journeys, and decision trees.
allowed-tools: [Read, Write, Edit, Bash, Glob, Grep, AskUserQuestion]
version: 4.0.0
---

<!-- Keywords: create-documentation, markdown-quality, skill-creation, c7score, document-validation, ascii-flowchart, llms-txt, content-optimization -->

# Documentation Creation Specialist - Unified Markdown & Skill Management

Unified specialist providing: (1) Complete document quality pipeline with structure enforcement, content optimization (c7score), and style guide compliance, (2) Complete skill creation workflow with scaffolding, validation, and packaging, and (3) ASCII flowchart creation for visualizing complex workflows, user journeys, system architectures, and decision trees.

**Core principle**: Structure first, then content, then quality = documentation that is valid, AI-friendly, and maintainable.

---

## 1. 🎯 CAPABILITIES OVERVIEW

This skill operates in three primary modes:

### Mode 1: Document Quality Management

Enforce markdown structure, optimize content for AI assistants, and validate quality compliance through a unified 3-phase pipeline: Enforcement → Optimization → Validation.

**Use when**:
- Writing or optimizing markdown documentation
- Enforcing structural standards through validation
- Improving AI-friendliness of documentation (c7score optimization)
- Validating document quality before release

**See**: Sections 2-5 below

### Mode 2: Skill Creation & Management

Guide the creation of effective Claude skills through a structured 6-step workflow: Understanding → Planning → Initialization → Editing → Packaging → Iteration.

**Use when**:
- Creating new Claude skills
- Scaffolding skill directory structure
- Validating skill quality (SKILL.md validation)
- Packaging skills for distribution
- Updating or maintaining existing skills

**See**: Sections 2-5 below and [skill_creation.md](./references/skill_creation.md)

### Mode 3: Flowchart Creation

Create comprehensive ASCII flowcharts in markdown for visualizing complex workflows, user journeys, system architectures, and decision trees with clear visual hierarchy.

**Use when**:
- Documenting complex multi-step workflows
- User journey mapping with step-by-step flows
- System architecture and data flow diagrams
- Decision trees with multiple branches
- Showing parallel execution paths and dependencies
- Creating quick reference guides for processes

**See**: Sections 2-5 below and [assets/flowcharts/](./assets/flowcharts/)

---

## 2. 🧭 SMART ROUTING & REFERENCES

### Mode Selection
```
TASK CONTEXT
    │
    ├─► Improving existing markdown / documentation quality
    │   └─► MODE 1: Document Optimization
    │       └─► Load: core_standards.md, optimization.md, validation.md
    │
    ├─► Creating new skill / skill maintenance
    │   └─► MODE 2: Skill Creation
    │       └─► Load: skill_creation.md, skill_md_template.md
    │       └─► Execute: init_skill.py, package_skill.py
    │
    ├─► Creating ASCII flowcharts / diagrams
    │   └─► MODE 3: ASCII Flowcharts
    │       └─► Load: flowchart assets (decision_tree.txt, etc.)
    │
    └─► Quick reference / standards lookup
        └─► Load: quick_reference.md
```

### Resource Router
```python
def route_documentation_resources(task):
    # ══════════════════════════════════════════════════════════════════════
    # MODE 1: Document Quality
    # ══════════════════════════════════════════════════════════════════════
    if task.mode == "document_quality":
        # ──────────────────────────────────────────────────────────────────
        # Core Standards
        # Purpose: Filename conventions, document types, structural violations
        # Key Insight: Load for Phase 1 enforcement and violation detection
        # ──────────────────────────────────────────────────────────────────
        if task.checking_structure:
            return load("references/core_standards.md")

        # ──────────────────────────────────────────────────────────────────
        # Optimization
        # Purpose: C7score metrics and 16 transformation patterns
        # Key Insight: Load for Phase 2 optimization and improvement suggestions
        # ──────────────────────────────────────────────────────────────────
        if task.optimizing_content:
            return load("references/optimization.md")

        # ──────────────────────────────────────────────────────────────────
        # Validation
        # Purpose: Quality scoring, gates, and improvement recommendations
        # Key Insight: Load for Phase 3 validation and quality gates
        # ──────────────────────────────────────────────────────────────────
        if task.validating_quality:
            return load("references/validation.md")

        # ──────────────────────────────────────────────────────────────────
        # Workflows
        # Purpose: Four execution modes, hook integration, enforcement patterns
        # Key Insight: Load for mode selection and workflow guidance
        # ──────────────────────────────────────────────────────────────────
        if task.needs_workflow_guidance:
            return load("references/workflows.md")

    # ══════════════════════════════════════════════════════════════════════
    # MODE 2: Skill Creation
    # ══════════════════════════════════════════════════════════════════════
    if task.mode == "skill_creation":
        # ──────────────────────────────────────────────────────────────────
        # Skill Creation Workflow
        # Purpose: Complete 6-step skill creation workflow with examples
        # Key Insight: Load for MODE 2 skill creation/updates
        # ──────────────────────────────────────────────────────────────────
        if task.creating_skill:
            load("references/skill_creation.md")
            return execute("scripts/init_skill.py")

        # ──────────────────────────────────────────────────────────────────
        # SKILL.md Template
        # Purpose: Complete SKILL.md file templates
        # Key Insight: Load for MODE 2 skill initialization
        # ──────────────────────────────────────────────────────────────────
        if task.needs_skill_template:
            return load("assets/skill_md_template.md")

        # ──────────────────────────────────────────────────────────────────
        # Asset Template
        # Purpose: Asset file creation templates
        # Key Insight: Load for MODE 2 bundled asset files
        # ──────────────────────────────────────────────────────────────────
        if task.needs_asset_template:
            return load("assets/skill_asset_template.md")

        # ──────────────────────────────────────────────────────────────────
        # Reference Template
        # Purpose: Reference doc templates
        # Key Insight: Load for MODE 2 bundled reference files
        # ──────────────────────────────────────────────────────────────────
        if task.needs_reference_template:
            return load("assets/skill_reference_template.md")

        # ──────────────────────────────────────────────────────────────────
        # Command Template
        # Purpose: Claude Code slash command templates (simple, workflow, mode-based, destructive)
        # Key Insight: Load for command creation/alignment
        # ──────────────────────────────────────────────────────────────────
        if task.creating_command:
            return load("assets/command_template.md")

        # ──────────────────────────────────────────────────────────────────
        # Skill Packaging
        # Purpose: Skill validation and packaging
        # Key Insight: Execute for MODE 2 Step 5 packaging
        # ──────────────────────────────────────────────────────────────────
        if task.packaging_skill:
            return execute("scripts/package_skill.py")

        # ──────────────────────────────────────────────────────────────────
        # Quick Validation
        # Purpose: Minimal skill validation
        # Key Insight: Execute for fast validation checks
        # ──────────────────────────────────────────────────────────────────
        if task.quick_validation:
            return execute("scripts/quick_validate.py")

    # ══════════════════════════════════════════════════════════════════════
    # MODE 3: Flowchart Creation
    # ══════════════════════════════════════════════════════════════════════
    if task.mode == "flowchart":
        # ──────────────────────────────────────────────────────────────────
        # Simple Workflow
        # Purpose: Linear sequential flow example
        # Key Insight: Load for basic top-to-bottom flows
        # ──────────────────────────────────────────────────────────────────
        if task.is_linear_sequence:
            return load("assets/flowcharts/simple_workflow.md")

        # ──────────────────────────────────────────────────────────────────
        # Decision Tree Flow
        # Purpose: Multi-branch decision example
        # Key Insight: Load for complex decision trees
        # ──────────────────────────────────────────────────────────────────
        if task.has_decision_branches:
            return load("assets/flowcharts/decision_tree_flow.md")

        # ──────────────────────────────────────────────────────────────────
        # Parallel Execution
        # Purpose: Concurrent tasks example
        # Key Insight: Load for sync points and parallel blocks
        # ──────────────────────────────────────────────────────────────────
        if task.has_parallel_tasks:
            return load("assets/flowcharts/parallel_execution.md")

        # ──────────────────────────────────────────────────────────────────
        # User Onboarding (Nested)
        # Purpose: Nested sub-process example
        # Key Insight: Load for hierarchical workflows
        # ──────────────────────────────────────────────────────────────────
        if task.has_nested_process:
            return load("assets/flowcharts/user_onboarding.md")

        # ──────────────────────────────────────────────────────────────────
        # Approval Workflow Loops
        # Purpose: Revision cycles example
        # Key Insight: Load for approval gates and loops
        # ──────────────────────────────────────────────────────────────────
        if task.has_approval_gate or task.has_loop_iteration:
            return load("assets/flowcharts/approval_workflow_loops.md")

        # ──────────────────────────────────────────────────────────────────
        # System Architecture Swimlane
        # Purpose: Swimlane pattern example
        # Key Insight: Load for layer separation diagrams
        # ──────────────────────────────────────────────────────────────────
        if task.has_multi_stage or task.needs_swimlanes:
            return load("assets/flowcharts/system_architecture_swimlane.md")

        # ──────────────────────────────────────────────────────────────────
        # Flowchart Validation
        # Purpose: Flowchart validation automation
        # Key Insight: Execute for size, depth, and alignment checks
        # ──────────────────────────────────────────────────────────────────
        if task.validating_flowchart:
            return execute("scripts/validate_flowchart.sh")

    # ══════════════════════════════════════════════════════════════════════
    # GENERAL UTILITIES (cross-mode)
    # ══════════════════════════════════════════════════════════════════════

    # ──────────────────────────────────────────────────────────────────
    # Frontmatter Templates
    # Purpose: YAML frontmatter templates by document type
    # Key Insight: Load when creating/validating frontmatter
    # ──────────────────────────────────────────────────────────────────
    if task.needs_frontmatter:
        return load("assets/frontmatter_templates.md")

    # ──────────────────────────────────────────────────────────────────
    # llms.txt Templates
    # Purpose: Example llms.txt files
    # Key Insight: Load when generating llms.txt
    # ──────────────────────────────────────────────────────────────────
    if task.generating_llmstxt:
        return load("assets/llmstxt_templates.md")

    # ──────────────────────────────────────────────────────────────────
    # Document Analysis
    # Purpose: Document quality analysis automation
    # Key Insight: Execute for batch quality analysis
    # ──────────────────────────────────────────────────────────────────
    if task.analyzing_docs:
        return execute("scripts/analyze_docs.py")

    # ──────────────────────────────────────────────────────────────────
    # Quick Reference
    # Purpose: One-page cheat sheet for fast lookup
    # Key Insight: Load for quick navigation and decision support
    # ──────────────────────────────────────────────────────────────────
    if task.needs_quick_reference:
        return load("references/quick_reference.md")

# ══════════════════════════════════════════════════════════════════════
# STATIC RESOURCES (always available, not conditionally loaded)
# ══════════════════════════════════════════════════════════════════════
# references/core_standards.md → Filename conventions, document types, structural violations
# references/workflows.md → Four execution modes, hook integration, enforcement patterns
# references/optimization.md → C7score metrics and 16 transformation patterns
# references/validation.md → Quality scoring, gates, and improvement recommendations
# references/skill_creation.md → Complete 6-step skill creation workflow with examples
# references/quick_reference.md → One-page cheat sheet for fast lookup
# assets/frontmatter_templates.md → YAML frontmatter templates by document type
# assets/llmstxt_templates.md → Example llms.txt files
# assets/command_template.md → Claude Code slash command templates
# assets/skill_md_template.md → Complete SKILL.md file templates
# assets/skill_asset_template.md → Asset file creation templates
# assets/skill_reference_template.md → Reference doc templates
# assets/flowcharts/simple_workflow.md → Linear sequential flow example
# assets/flowcharts/decision_tree_flow.md → Multi-branch decision example
# assets/flowcharts/parallel_execution.md → Concurrent tasks example
# assets/flowcharts/user_onboarding.md → Nested sub-process example
# assets/flowcharts/approval_workflow_loops.md → Revision cycles example
# assets/flowcharts/system_architecture_swimlane.md → Swimlane pattern example
# scripts/analyze_docs.py → Document quality analysis automation
# scripts/init_skill.py → Skill scaffolding and template generation
# scripts/package_skill.py → Skill validation and packaging
# scripts/quick_validate.py → Minimal skill validation
# scripts/validate_flowchart.sh → Flowchart validation automation
```

---

## 3. 🎯 WHEN TO USE

### Mode 1: Document Quality Management

#### Validation Workflow

> **Note:** In Claude Code, enforcement runs automatically via hooks. In Opencode, apply these standards manually.

**Filename Standards** - Apply after Write/Edit operations:
- Auto-correct filename violations (ALL CAPS → lowercase, hyphens → underscores)
- Preserve exceptions (README.md, SKILL.md)

**Structure Validation** - Apply before finalizing:
- Fix safe violations (separators, H2 case, emoji per "Emoji Usage Rules")
- Check for critical violations (missing frontmatter, wrong section order)
- Provide specific fix suggestions with line numbers

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


### Mode 3: Flowchart Creation

#### Flowchart Mode Triggers

**Use when**:
- User requests workflow visualization ("create a flowchart", "diagram this process")
- Documenting multi-step processes with branching logic
- Showing parallel execution with synchronization points
- Creating decision trees with multiple outcomes
- Visualizing approval gates and revision cycles
- Mapping user journeys or system architectures

**Automatic Triggers**:
- User mentions "flowchart", "workflow diagram", "process visualization"
- User asks about visualizing decisions, branches, or parallel tasks
- User needs ASCII diagrams for documentation

#### 7 Core Patterns

| Pattern | Use Case | Example |
|---------|----------|---------|
| 1: Linear Sequential | Step-by-step without branching | User registration flow |
| 2: Decision Branch | Binary or multi-way decisions | Validation with success/failure |
| 3: Parallel Execution | Multiple tasks run together | CI/CD test runners |
| 4: Nested Sub-Process | Embedded workflows | Onboarding with sub-steps |
| 5: Approval Gate | Review/approval required | PR review workflow |
| 6: Loop/Iteration | Until condition met | Retry with backoff |
| 7: Pipeline | Sequential stages with gates | Deploy pipeline |

#### When NOT to Use

**Do not use for**:
- Simple linear lists (use bullet points instead)
- Code architecture (use mermaid diagrams instead)
- Data models (use ER diagrams instead)
- Interactive/exportable diagrams required
- Very simple 2-3 step processes

---

## 4. ⚙️ HOW TO USE

### Mode 1: Document Quality

**Three-Phase Pipeline**: Enforcement (structure validation) → Optimization (content enhancement) → Validation (quality scoring). Each phase runs independently or chains sequentially.

| Mode              | Purpose         | Result                                    |
| ----------------- | --------------- | ----------------------------------------- |
| Full Pipeline     | Critical docs   | 85+ overall (structure + c7score + style) |
| Enforcement Only  | Structure checks | Structurally valid markdown               |
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


### Mode 2: Skill Creation

**6-Step Process**: Understanding (examples) → Planning (resources) → Initialization (init_skill.py) → Editing (populate) → Packaging (package_skill.py) → Iteration (test/improve).

**Progressive Disclosure Design**:
1. Metadata (name + description) - Always in context (~100 words)
2. SKILL.md body - When skill triggers (<5k words)
3. Bundled resources - As needed (unlimited)

**Integration with Document Quality**: After packaging, validate SKILL.md with full pipeline (target: 90+ overall score).

**Platform Compatibility (CRITICAL)**: Skills sync to both `.claude/` and `.opencode/`. Opencode does NOT support hooks. When documenting hook-dependent features, add notes like "In Claude Code, this runs automatically via hooks. In Opencode, follow manually." See Pitfall 6 in skill_creation.md.

See [skill_creation.md](./references/skill_creation.md) for detailed workflow and [skill_md_template.md](./assets/skill_md_template.md) for templates.


### Mode 3: Flowchart Creation

**Workflow**: Select pattern → Build with components → Validate → Document

**Building Blocks**:
```
Process Box:        Decision Diamond:     Terminal:
┌─────────────┐         ╱──────╲           ╭─────────╮
│   Action    │        ╱ Test?  ╲          │  Start  │
└─────────────┘        ╲        ╱          ╰─────────╯
                        ╲──────╱
```

**Flow Control**:
```
Standard Flow:      Branch:           Parallel:
     │              │   │   │         ┌────┬────┐
     ▼              ▼   ▼   ▼         │    │    │
```

**Pattern Selection**:

| Need | Pattern | Reference |
|------|---------|-----------|
| Simple sequence | 1: Linear | simple_workflow.md |
| Yes/No choice | 2: Decision | decision_tree_flow.md |
| Simultaneous work | 3: Parallel | parallel_execution.md |
| Complex subprocess | 4: Nested | user_onboarding.md |
| Manual checkpoint | 5: Approval | approval_workflow_loops.md |
| Repeated action | 6: Loop | approval_workflow_loops.md |
| Multi-phase project | 7: Pipeline | system_architecture_swimlane.md |

**Validation**: Run `scripts/validate_flowchart.sh` for size, depth, and alignment checks.

---

## 5. 📋 RULES

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


### Mode 3: Flowchart Creation

#### ✅ ALWAYS

1. **ALWAYS use consistent box styles** (single-line for process, rounded for terminals, diamond for decisions)
2. **ALWAYS label all decision branches** (Yes/No, Approve/Reject, or specific outcomes)
3. **ALWAYS align elements vertically or horizontally** (no diagonal lines, consistent spacing)
4. **ALWAYS show complete paths** (every box has entry/exit, all parallel blocks converge)
5. **ALWAYS validate readability** (verify arrows connect correctly, paths are traceable)

#### ❌ NEVER

1. **NEVER create ambiguous arrow connections** (show explicit merge points)
2. **NEVER leave decision outcomes unlabeled** (all branches must show outcomes)
3. **NEVER exceed 40 boxes in single diagram** (break into sub-workflows)
4. **NEVER mix box styles inconsistently** (use standard boxes for processes throughout)
5. **NEVER skip spacing and alignment** (use single blank line between steps)

#### ⚠️ ESCALATE IF

1. **Process exceeds ~30-40 boxes** (diagram too complex for single view)
2. **Interactive/exportable format needed** (suggest mermaid or design tools)
3. **Collaborative editing required** (ASCII limitations for team edits)
4. **Pattern unclear** (ask user about workflow type to select pattern)


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

## 6. 🏆 SUCCESS CRITERIA

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


### Mode 3: Flowchart Creation

#### Flowchart Complete When

**Quality checklist**:
- ✅ All paths from start to end are clear
- ✅ Decisions have labeled outcomes
- ✅ Parallel processes clearly marked with sync points
- ✅ Approval gates visually distinct
- ✅ Spacing and alignment consistent throughout
- ✅ Can be understood without verbal explanation
- ✅ Matches actual process accurately
- ✅ Visual hierarchy supports comprehension

#### Validation Questions

**Can answer YES to all?**
- Can a new person follow any path?
- Are all decision points exhaustive?
- Do parallel blocks resolve properly?
- Is timing/context provided where needed?
- Does visual hierarchy aid understanding?

#### Size Limits

- **Max boxes**: 40 per diagram (break into sub-workflows if larger)
- **Max depth**: 8 levels (use swimlanes for deeper hierarchies)
- **Max lines**: 200 (split into multiple diagrams for readability)

---

## 7. 🔌 INTEGRATION POINTS

### Mode 1: Document Quality

#### Quality Integration

> **Note:** In Claude Code, validation runs automatically via hooks. In Opencode, apply these checks manually.

**Filename Validation** (after Write/Edit operations):
- Purpose: Filename enforcement (corrections as needed)
- Apply: After creating or editing markdown files
- Check: ALL CAPS → lowercase, hyphens → underscores

**Structure Validation** (before finalizing):
- Purpose: Structure validation and corrections
- Apply: Before completing documentation tasks
- Check: Frontmatter, section order, formatting

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

**workflows-memory**: Context files saved by workflows-memory skill can be optimized
- Document type: memory (flexible enforcement)
- Optional optimization for clarity and future reference
- No blocking violations on memory files


### Mode 3: Flowchart Creation

#### Flowchart Validation Script

**validate_flowchart.sh**:
- Purpose: Check flowchart for common issues
- Usage: `scripts/validate_flowchart.sh <flowchart.md>`
- Checks: Box alignment, arrow connections, decision labels, nesting depth, file size

#### Tool Usage

**Read**: Load reference examples for pattern guidance

**Write**: Create new flowchart markdown files

**Edit**: Modify existing flowcharts

#### Reference Examples

| File | Pattern | Complexity |
|------|---------|------------|
| simple_workflow.md | Linear | Low |
| decision_tree_flow.md | Decision Branch | High |
| parallel_execution.md | Parallel | Medium-High |
| user_onboarding.md | Nested | High |
| approval_workflow_loops.md | Loop + Approval | High |
| system_architecture_swimlane.md | Swimlane | High |

---

## 8. 📚 EXTERNAL RESOURCES

- **llms.txt specification**: https://llmstxt.org/
- **c7score benchmarking**: https://context7.ai/ (AI documentation quality)
- **Anthropic documentation**: https://docs.anthropic.com/
- **CommonMark specification**: https://spec.commonmark.org/

---

## 9. 🚀 QUICK START

### For Document Quality

1. **Read**: This SKILL.md Section 3 (When to Use), Section 4 (How to Use), Section 5 (Rules), Section 6 (Success Criteria)
2. **Navigate**: [workflows.md](./references/workflows.md) for execution modes
3. **Use**: Run enforcement, optimization, or validation as needed

### For Skill Creation

1. **Read**: This SKILL.md Section 3 (When to Use), Section 4 (How to Use), Section 5 (Rules), Section 6 (Success Criteria)
2. **Navigate**: [skill_creation.md](./references/skill_creation.md) for complete workflow
3. **Use Scripts**: init_skill.py → edit → package_skill.py
4. **Validate**: Run Document Quality mode on SKILL.md (target 90+)

### Quick Reference

Need fast navigation? See [quick_reference.md](./references/quick_reference.md)

---

**Remember**: This skill operates in two modes - Document Quality and Skill Creation. Both modes integrate seamlessly for creating and validating high-quality skills.