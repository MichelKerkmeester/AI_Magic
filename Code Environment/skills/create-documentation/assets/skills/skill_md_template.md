# 📄 SKILL.md File Templates - Creation Guide

Comprehensive templates and guidelines for creating effective SKILL.md files for Claude skills. These templates provide complete scaffolds for skills of varying complexity levels with detailed section guidance.

---

## 1. 📖 Introduction & Template Selection

### Purpose of SKILL.md Files

SKILL.md files define Claude skills - reusable capabilities that extend Claude's functionality for specific domains or workflows. A well-crafted SKILL.md:

- **Triggers automatically** when relevant patterns detected
- **Guides Claude** through specialized workflows
- **Maintains consistency** across conversations
- **Encodes expertise** in specific domains

### Template Overview

This guide provides **one comprehensive SKILL template** (Section 3) that covers all skill types from simple single-purpose tools to complex multi-mode orchestrators.

**The template is flexible:**
- **Simple skills**: Use core sections only (WHEN TO USE, HOW IT WORKS, RULES)
- **Skills with bundled resources**: Add Navigation Guide, references folder, assets folder, scripts folder
- **Multi-mode skills**: Expand WHEN TO USE and HOW IT WORKS sections by mode
- **All skills**: MUST include Section 2 (SMART ROUTING) and Section 3 (REFERENCES)

**Target size**: 800-2000 lines for SKILL.md (<5k words total)

**Examples**:
- Simple: Unit test generator, documentation formatter (no bundled resources)
- Moderate: API client, specialized code reviewer (with references and assets)
- Complex: Workflow orchestrator, document quality pipeline (multi-mode with extensive resources)

### Progressive Disclosure Principle

SKILL.md architecture follows progressive disclosure:

1. **Metadata** (YAML frontmatter) - Always in context (~100 words)
2. **SKILL.md body** - When skill activates (<5k words)
3. **Bundled resources** - Loaded as needed (unlimited size)

**Critical**: Keep SKILL.md <5k words. Move detailed content to `references/`, `scripts/`, or `assets/`.

### Document Type Requirements

**Enforcement Level**: STRICT (SKILL.md files require perfect structure)

**Required Elements**:
- ✅ YAML frontmatter with required fields
- ✅ H1 title with subtitle
- ✅ Numbered H2 sections with emojis
- ✅ Section separators (`---`)
- ✅ No table of contents (forbidden in SKILL.md)

**Quality Targets**:
- Structure: 100/100
- C7Score: 85+/100
- Overall: 90+/100

---

## 2. 🎯 Frontmatter Template & Field Guidelines

### Complete YAML Frontmatter Template

```yaml
---
name: [skill-name]
description: [One-sentence description using third-person. Be specific about capabilities and use cases. Mention key workflows or unique features.]
allowed-tools: [Tool1, Tool2, Tool3]
version: 1.0.0
---
```

### Field-by-Field Requirements

**`name`** (REQUIRED):
- Format: `hyphen-case` (lowercase with hyphens)
- Length: 2-4 words typically
- Must match directory name exactly
- Examples: `cli-gemini`, `workflows-git`, `create-documentation`
- ❌ Avoid: snake_case, camelCase, spaces

**`description`** (REQUIRED):
- Length: 1-3 sentences, ~150-300 characters
- Voice: Third-person form ("This skill...", "Use when...", "Provides...")
- Content: Specific capabilities, primary use cases, key differentiators
- Must answer: "What does this skill do?" and "When should it be used?"
- ✅ Good: "Wield Google's Gemini CLI as a powerful auxiliary tool for code generation, review, analysis, and web research. Use when tasks benefit from a second AI perspective or current web information via Google Search."
- ❌ Bad: "Helps with Gemini" (too vague), "You can use this to..." (wrong voice)

**`allowed-tools`** (REQUIRED):
- Format: YAML inline array `[Tool1, Tool2]` (brackets required) or YAML list
- Common tools: `Read`, `Write`, `Edit`, `Bash`, `Glob`, `Grep`, `AskUserQuestion`, `TodoWrite`
- Include ALL tools skill instructions reference
- Order: List most-used tools first
- Validation: Skill will fail if it attempts to use tools not listed
- ❌ **Invalid**: `allowed-tools: Read, Write, Bash` (comma-separated string)
- ✅ **Valid**: `allowed-tools: [Read, Write, Bash]` (inline array with brackets)

**`version`** (OPTIONAL but RECOMMENDED):
- Format: Semantic versioning `major.minor.patch`
- Start at: `1.0.0` for production-ready, `0.1.0` for beta
- Increment: Major for breaking changes, minor for new features, patch for fixes
- Purpose: Track skill evolution, manage deprecation

### YAML Formatting Rules

**Array format options**:
```yaml
# Inline (preferred for short lists)
allowed-tools: [Read, Write, Edit, Bash]

# Multi-line (use for 6+ tools)
allowed-tools:
  - Read
  - Write
  - Edit
  - Bash
  - Glob
  - Grep
```

**Common Mistakes**:
- ❌ Using angle brackets: `description: <placeholder text>` (breaks validation)
- ❌ Missing quotes for special characters: `name: skill:name` (use `name: "skill:name"`)
- ❌ Incorrect indentation in multi-line arrays (must be 2 spaces)
- ❌ Using second-person: "You should use this when..." (use third-person)
- ❌ Comma-separated string for tools: `allowed-tools: Read, Write, Bash` (must use brackets: `[Read, Write, Bash]`)

---

## 3. 🔧 SKILL Template (With Bundled Resources)

**Use for**: Skills with bundled resources (references, scripts, or assets)

**Target**: 800-2000 lines (SKILL.md <1000 lines, rest in resources)

### Template

---
name: [skill-name]
description: [Specific description including what this skill does, when to use it, and what bundled resources it provides. Third-person voice.]
allowed-tools: [Read, Write, Edit, Bash, Glob, Grep, AskUserQuestion]
version: 1.0.0
---

# [Skill Title - Comprehensive Name]

[One-sentence tagline followed by key capabilities overview]

---

## 1. 🎯 WHEN TO USE

### 📚 Navigation Guide

**This file (SKILL.md)**: [What's in this file - 1 sentence]

**Reference Files** (detailed documentation):
- [reference-name.md](./references/reference-name.md) – What it contains
- [guide-name.md](./references/guide-name.md) – What it contains

**Assets** (templates and output resources):
- [template-name.md](./assets/template-name.md) – What it provides

**Scripts** (automation):
- [script-name.py](./scripts/script-name.py) – What it does

### [Primary Use Case Category]

**Use when**:
- [Scenario 1 with context]
- [Scenario 2 with context]
- [Scenario 3 with context]

**Automatic Triggers** (if applicable):
- [Pattern 1 that auto-triggers skill]
- [Pattern 2 that auto-triggers skill]

### [Secondary Use Case Category]

[Content for secondary use cases]

### When NOT to Use

**Do not use for**:
- [Anti-pattern with rationale]
- [Anti-pattern with rationale]
- [Anti-pattern with rationale]

---

## 2. 🧭 SMART ROUTING

```python
def route_[skill_name]_resources(task):
    # [category 1]
    if task.[condition_1]:
        return load("references/[filename].md")  # [what it provides]
    
    # [category 2]
    if task.[condition_2]:
        load("references/[filename].md")  # [what it provides]
        return load("assets/[template].md")  # [what it provides]
    
    # [category 3]
    if task.[condition_3]:
        return execute("scripts/[script].py")  # [what it does]
    
    # quick lookup
    if task.needs_quick_reference:
        return load("references/quick_reference.md")  # one-page cheat sheet

# [summary comment: key thresholds, patterns, or decision rules]
```

---

## 3. 🗂️ REFERENCES

### Core Framework & Workflows
| Document                         | Purpose                        | Key Insight                             |
| -------------------------------- | ------------------------------ | --------------------------------------- |
| **[Skill Name] - Main Workflow** | [Core capability and workflow] | **[Key differentiator or methodology]** |

### Bundled Resources
| Document                      | Purpose                        | Key Insight                      |
| ----------------------------- | ------------------------------ | -------------------------------- |
| **references/[filename].md**  | [Detailed documentation topic] | [How it enhances skill]          |
| **assets/[template-name].md** | [Template or example provided] | [When to use it]                 |
| **scripts/[script-name].py**  | [Automation capability]        | [Performance or execution notes] |

---

## 4. 🛠️ HOW IT WORKS

### [Primary Workflow] Overview

[2-3 sentence explanation of the workflow]

**Process Flow**:
```
STEP 1: [Action Name]
       ├─ [Sub-action with detail]
       ├─ [Sub-action with detail]
       └─ [Output description]
       ↓
STEP 2: [Action Name]
       ├─ [Sub-action with detail]
       └─ [Output description]
       ↓
STEP 3: [Action Name]
       └─ [Final output]
```

See [workflow-details.md](./references/workflow-details.md) for complete step-by-step guidance.

### [Key Component or Pattern]

[Explanation of important architectural pattern or component]

**Structure**:
```[language]
# Show structure or pattern
# With explanatory comments
```

### [Resource Usage Pattern]

**How to use bundled resources**:

**Scripts**: [When and how to invoke scripts]
```bash
# Example script invocation
[command-line-example]
```

**References**: [When to load reference files]

**Assets**: [When to use template/asset files]

### [Configuration or Setup]

[Setup requirements, if any]

---

<!-- NOTE: RULES section is a special case - semantic emojis (✅ ❌ ⚠️) are REQUIRED on H3 subsections.
     Do NOT remove these emojis. Do NOT add horizontal dividers (---) between H3 subsections. -->

## 5. 📖 RULES

### ✅ ALWAYS Rules

**ALWAYS do these without asking:**

1. **ALWAYS [critical rule with resource tie-in]**
   - [Implementation detail]
   - [Reference to bundled resource if applicable]

2. **ALWAYS [critical rule 2]**
   - [Detail]

3. **ALWAYS [critical rule 3]**
   - [Detail]

4. **ALWAYS [critical rule 4]**
   - [Detail]

5. **ALWAYS [critical rule 5]**
   - [Detail]

### ❌ NEVER Rules

**NEVER do these:**

1. **NEVER [anti-pattern]**
   - [Why problematic]
   - [Alternative approach]

2. **NEVER [anti-pattern]**
   - [Why problematic]

3. **NEVER [anti-pattern]**
   - [Why problematic]

### ⚠️ ESCALATE IF

**Ask user when:**

1. **ESCALATE IF [ambiguous case]**
   - [What's unclear]
   - [What to ask]

2. **ESCALATE IF [blocking issue]**
   - [What's blocked]
   - [Resolution path]

---

## 6. 🎓 SUCCESS CRITERIA

### [Primary Workflow] Completion Checklist

**[Workflow name] complete when**:
- ✅ [Criterion 1]
- ✅ [Criterion 2]
- ✅ [Criterion 3]
- ✅ [Criterion 4]
- ✅ [Criterion 5]

### Quality Targets

**Target metrics** (if applicable):
- **[Metric 1]**: [Target value/threshold]
- **[Metric 2]**: [Target value/threshold]
- **[Metric 3]**: [Target value/threshold]

### Validation Success

**Validation passes when**:
- ✅ [Validation check 1]
- ✅ [Validation check 2]
- ✅ [Validation check 3]

---

## 7. 🔗 INTEGRATION POINTS

### [Integration System 1 - e.g., Hook System]

**[Hook Name]** (if applicable):
- Triggers: [When it runs]
- Purpose: [What it does]
- Execution: [Performance characteristics]

### [Integration System 2 - e.g., Related Skills]

**[skill-name]**: [How they integrate]

### Tool Usage Guidelines

**[Tool Name]**: [Specific usage pattern]

**[Tool Name]**: [Specific usage pattern]

**[Tool Name]**: [Specific usage pattern]

### Knowledge Base Dependencies

**Required**:
- `file-path` – Purpose, what happens if missing

**Optional**:
- `file-path` – Enhancement provided

### External Tools

**[Tool Name]** (if needed):
- Installation: [How to install]
- Purpose: [Why needed]
- Fallback: [What happens if unavailable]

**Word Count Targets**:
- Section 1 (WHEN TO USE): 150-200 lines
- Section 2 (SMART ROUTING): 30-80 lines (NEW - Python routing logic)
- Section 3 (REFERENCES): 80-120 lines (bundled resources tables)
- Section 4 (HOW IT WORKS): 200-300 lines
- Section 5 (RULES): 150-200 lines
- Section 6 (SUCCESS CRITERIA): 80-120 lines
- Section 7 (INTEGRATION POINTS): 100-150 lines

**Bundled Resources Structure**:
```
skill-name/
├── SKILL.md (800-1000 lines)
└── Bundled Resources
    ├── scripts/          - Executable automation
    ├── references/       - Detailed documentation
    └── assets/           - Templates and examples
```

---

## 4. 📝 Section-by-Section Content Guidance

### Section 1: WHEN TO USE

**Purpose**: Help Claude and users understand when to activate this skill

**Essential Content**:
- Navigation Guide subsection (NEW - mandatory for skills with bundled resources)
- Primary use case categories (2-4 categories)
- Specific scenarios (3-5 per category)
- Anti-patterns ("When NOT to Use")
- Automatic trigger patterns (if applicable)

**Structure**:

### 📚 Navigation Guide

**This file (SKILL.md)**: [What's in this file - 1 sentence]

**Reference Files** (detailed documentation):
- [reference-name.md](./references/reference-name.md) – What it contains
- [guide-name.md](./references/guide-name.md) – What it contains

**Assets** (templates and output resources):
- [template-name.md](./assets/template-name.md) – What it provides

**Scripts** (automation):
- [script-name.py](./scripts/script-name.py) – What it does

### [Use Case Category]

**Use when**:
- [Specific scenario with context]
- [Specific scenario with context]

### When NOT to Use

**Skip this skill when:**
- [Anti-pattern with rationale]

**Writing Tips**:
- **Navigation Guide**: List ALL bundled resources with 1-line descriptions (place at TOP of section)
- Be specific: "Generate JSDoc for functions" not "document code"
- Include context: Why each scenario benefits from this skill
- Clear boundaries: Explicitly state what's out of scope
- Trigger patterns: What keywords/patterns auto-activate skill

**Word Budget**: 100-200 lines

---

### Section 2: SMART ROUTING (NEW - Required for All Skills)

**Purpose**: Provide Python-like pseudo code that routes Claude to the correct reference, asset, or script based on context

**Placement**: After Section 1 (WHEN TO USE), before Section 3 (REFERENCES)

**Essential Content**:
- Python-style routing functions using `load()` and `execute()` patterns
- Condition-based logic for selecting appropriate resources
- Inline comments explaining routing decisions

**Structure**:

## 2. 🧠 SMART ROUTING

```python
def route_request(context):
    # Main routing logic for this skill
    
    if context.needs_detailed_guide:
        # Load comprehensive reference for complex scenarios
        load("references/detailed_guide.md")
    
    elif context.needs_template:
        # Provide structured template for output generation
        load("assets/output_template.md")
    
    elif context.needs_automation:
        # Execute script for automated processing
        execute("scripts/automation.py")
    
    else:
        # Default: Use skill's core methodology
        load("references/core_methodology.md")
```

**Writing Tips**:
- **Function names**: Use descriptive names like `route_request()`, `select_resource()`, `determine_mode()`
- **Conditions**: Match skill's actual use cases and decision points
- **Comments**: Add inline comments explaining *why* each resource is loaded
- **Resource paths**: Use actual file paths from the skill's bundled resources
- **Fallback**: Always include a default/else case
- **Keep it simple**: 10-30 lines of routing logic is ideal

**Word Budget**: 30-80 lines

---

### Section 3: REFERENCES

**Purpose**: Provide structured overview of skill architecture and bundled resources

**Placement**: After Section 2 (SMART ROUTING), before Section 4 (HOW IT WORKS)

**Essential Content**:
- 3-column categorized tables listing bundled resources
- Clear categorization (Core Framework, Bundled Resources, Templates, etc.)
- Note: Smart Routing Python code moved to Section 2

**Structure - 3-Column Categorized Tables**:

## 3. 🗂️ REFERENCES

### Core Framework & Workflows
| Document                                   | Purpose                       | Key Insight                                   |
| ------------------------------------------ | ----------------------------- | --------------------------------------------- |
| **[Conceptual Name - Main Workflow]**      | [What this workflow provides] | **[Key differentiator or integration point]** |
| **[Conceptual Name - Secondary Workflow]** | [What this provides]          | **[Key insight]**                             |

### Bundled Resources
| Document                     | Purpose                        | Key Insight                      |
| ---------------------------- | ------------------------------ | -------------------------------- |
| **references/[filename.md]** | [Detailed documentation topic] | [How it enhances the skill]      |
| **assets/[filename.md]**     | [Template or example content]  | [When to use it]                 |
| **scripts/[filename.py]**    | [Automation provided]          | [Performance or capability note] |

**Writing Tips**:
- **Table Organization**:
  - Use category headers (### Core Framework, ### Bundled Resources, etc.)
  - Document names in **bold** (conceptual names, not always file paths)
  - Purpose column: What it does (1 sentence)
  - Key Insight column: Why it matters, integration points, performance notes
  - For bundled resources: Use actual file paths (references/name.md, assets/name.md, scripts/name.py)

- **Categorization Guidelines**:
  - **Core Framework**: Main workflows, methodologies, thinking frameworks
  - **Bundled Resources**: Files in references/, assets/, scripts/
  - **Templates**: Output templates if skill generates structured content
  - **External Documentation**: Links to external resources (separate subsection)
  - **Quick Reference**: Task-based navigation (separate subsection)

**Word Budget**: 80-150 lines

**Examples**:
- See `.claude/skills/z_example/Product Owner - v0.924.md` Section 3 (3-column categorized tables)

---

### Section 4: HOW IT WORKS

**Purpose**: Explain the skill's workflow, architecture, and key patterns

**Essential Content**:
- Process flow (visual diagram using ASCII)
- Key capabilities or components
- Configuration or setup requirements
- Examples of primary workflows
- Flowchart supplements for complex logic (NEW - when logic blocks present)

**Structure**:

### [Primary Workflow Name]

[Brief explanation]

**Process Flow**:
\`\`\`
STEP 1: [Action]
   ├─ [Sub-task]
   └─ [Output]
   ↓
STEP 2: [Action]
   └─ [Output]
\`\`\`

**Example**:
\`\`\`[language]
# Realistic example
\`\`\`

**Writing Tips**:
- Visual flows help comprehension (use ASCII diagrams)
- Show, don't just tell (include code examples)
- Progressive detail: Overview → specifics → edge cases
- Link to references for deep dives
- **Flowchart Supplements**: Add visual flowcharts before/after complex Python/YAML logic (see Section 6.5)

**Word Budget**: 150-300 lines

---

### Section 4.5: FLOWCHART SUPPLEMENTS (NEW - For Complex Logic)

**Purpose**: Add visual clarity to complex Python/YAML logic blocks without removing structured code

**When to Use**:
- Complex conditional logic (nested if/else, multiple branches)
- Mode detection algorithms
- Multi-step decision trees
- Workflow routing logic
- State machine transitions

**Approach**:
- **Supplement, don't replace**: Keep existing Python/YAML code intact
- **Add flowcharts**: Place ASCII flowchart before or after code block
- **Visual aid purpose**: Help quick understanding of logic flow

**Structure**:

### [Logic Section Name]

**[Brief explanation of what this logic does]**

**Logic Flow**:
\`\`\`
START
  ↓
[Check Condition A]
  ↓
A True? ─── NO ──→ [Path B]
  │                    ↓
  │              [Process B]
  │                    ↓
  YES              [Continue]
  ↓
[Process A]
  ↓
RESULT
\`\`\`

**Implementation**:
\`\`\`python
def example_logic(input):
    """Original Python logic preserved"""
    if condition_a:
        return process_a(input)
    else:
        return process_b(input)
\`\`\`

**OR for configuration:**

\`\`\`yaml
mode_detection:
  trigger_patterns:
    ticket: ["$ticket", "create ticket"]
    story: ["$story", "user story"]
  defaults:
    mode: interactive
    depth: 10
\`\`\`

**Writing Tips**:
- **Keep code**: Don't remove Python/YAML - it's precise and complete
- **Add diagrams**: Flowcharts provide at-a-glance understanding
- **Placement**:
  - Flowchart FIRST if it aids comprehension before reading code
  - Flowchart AFTER if it summarizes complex code
  - Both before AND after for very complex logic
- **Consistency**: Use same ASCII flowchart style as Smart Routing Diagram
- **When to skip**: Simple 2-3 line logic doesn't need flowcharts

**Example Use Cases**:
- Mode detection with 5+ conditions → Flowchart + Python code
- YAML configuration with complex triggers → Keep YAML, add decision tree diagram
- Multi-step workflow routing → Flowchart showing paths, keep implementation code

**Word Budget**: Variable (adds 10-30 lines per complex logic block)

---

### Section 5: RULES

**Purpose**: Define mandatory behaviors, prohibited actions, and escalation triggers

**Essential Content**:
- ALWAYS rules (4-7 critical requirements)
- NEVER rules (3-5 anti-patterns to avoid)
- ESCALATE IF (3-5 situations requiring user input)

**Structure**:

### ALWAYS

**ALWAYS do these without asking:**

1. **ALWAYS [requirement]**
   - [Why this matters]
   - [Implementation detail]

### NEVER

**NEVER do these:**

1. **NEVER [anti-pattern]**
   - [Why problematic]
   - [Alternative approach]

### ESCALATE IF

**Ask user when:**

1. **ESCALATE IF [ambiguous situation]**
   - [What's unclear]
   - [What clarification needed]

**Writing Tips**:
- Use ALL CAPS for section headers (ALWAYS, NEVER, ESCALATE IF)
- Be specific and actionable
- Explain *why* for each rule (rationale matters)
- Include implementation guidance
- Use AskUserQuestion tool for ESCALATE IF cases

**Word Budget**: 100-200 lines

---

### Section 6: SUCCESS CRITERIA

**Purpose**: Define completion conditions and quality standards

**Essential Content**:
- Completion checklist (5-10 items)
- Quality gates or thresholds
- Validation requirements

**Structure**:

### Task Completion Checklist

**[Workflow name] Complete When:**

- [ ] [Success criterion 1]
- [ ] [Success criterion 2]
- [ ] [Success criterion 3]

### Quality Gates

**Before marking complete:**

- **[Dimension]**: [Specific requirement]
- **[Dimension]**: [Specific requirement]

**Writing Tips**:
- Use checkbox format `- [ ]` for checklists
- Specific and measurable criteria
- Include both completion and quality checks
- Define thresholds numerically where possible

**Word Budget**: 50-120 lines

---

### Section 7: INTEGRATION POINTS

**Purpose**: Document how skill integrates with systems, tools, and other skills

**Essential Content**:
- Hook system integration (if applicable)
- Related skills and complementary workflows
- Tool usage patterns
- Knowledge base dependencies
- External tool requirements

**Structure**:

### Hook System Integration

**[Hook Name]**:
- Triggers: [When]
- Purpose: [What]

### Related Skills

**[skill-name]**: [How they integrate]

### Tool Usage Guidelines

**[Tool]**: [Usage pattern]

### Knowledge Base Dependencies

**Required**: [Files needed]
**Optional**: [Enhancing files]

### External Tools

**[Tool Name]**:
- Installation: [How]
- Purpose: [Why]

**Writing Tips**:
- Distinguish required vs. optional dependencies
- Provide installation/setup instructions for external tools
- Explain fallback behavior if optional resources missing
- Link related skills by name

**Word Budget**: 50-150 lines

---

## 5. ✅ Best Practices & Common Pitfalls

### Writing Style Best Practices

**DO**:
- ✅ Use third-person voice in frontmatter description
- ✅ Use imperative/infinitive form in instructions ("Validate the file")
- ✅ Be specific and actionable
- ✅ Include concrete examples
- ✅ Explain rationale for rules
- ✅ Use consistent emoji for similar concepts
- ✅ Keep SKILL.md <5k words (move details to references/)

**DON'T**:
- ❌ Use second-person ("You should validate...")
- ❌ Be vague or generic ("Helps with stuff")
- ❌ Duplicate content between SKILL.md and references/
- ❌ Include excessive detail in main file
- ❌ Use angle brackets in frontmatter `<placeholder>`
- ❌ Create skills without concrete examples

### Content Organization Best Practices

**Progressive Disclosure**:
1. Metadata → Always in context
2. SKILL.md → Core workflow and rules
3. references/ → Deep dives and detailed guides
4. assets/ → Templates and examples
5. scripts/ → Executable automation

**Section Order**:
1. WHEN TO USE (triggers and scope)
2. SMART ROUTING (Python routing logic for resource loading)
3. REFERENCES (navigation and bundled resources)
4. HOW IT WORKS (workflow and architecture)
5. RULES (behavior constraints)
6. SUCCESS CRITERIA (completion definition)
7. INTEGRATION POINTS (external connections)

### Common Pitfalls

**Pitfall 1: Generic or Vague Descriptions**
- ❌ Bad: "Helps with Git operations"
- ✅ Good: "Git workflow orchestrator guiding developers through workspace setup, clean commits, and work completion across git-worktrees, git-commit, and git-finish skills"

**Pitfall 2: Using Second-Person Voice**
- ❌ Bad: "You should use this when you need to validate files"
- ✅ Good: "Use this skill when file validation is required"

**Pitfall 3: Bloated SKILL.md Files**
- ❌ Bad: 10,000-line SKILL.md with all details inlined
- ✅ Good: <3,000-line SKILL.md that references bundled resources

**Pitfall 4: Missing Rationale for Rules**
- ❌ Bad: "NEVER skip validation"
- ✅ Good: "NEVER skip validation - Testing prevents bugs from reaching production and is more efficient than debugging later"

**Pitfall 5: Unclear Success Criteria**
- ❌ Bad: "Task complete when done"
- ✅ Good: "Task complete when: code passes tests, security scan shows no vulnerabilities, and documentation is updated"

**Pitfall 6: No Anti-Patterns in WHEN TO USE**
- ❌ Bad: Only listing when to use
- ✅ Good: Including "When NOT to Use" section with rationale

### Quality Optimization Tips

**For Higher C7Score** (AI-friendliness):
- Use question-answering format where appropriate
- Include concrete examples
- Break complex topics into digestible sections
- Use clear headers and structure
- Add context and rationale
- Link related concepts

**For Better Structure**:
- Use consistent heading hierarchy
- Include section separators (`---`)
- Number H2 headings
- Add emoji to all H2 headings (title case)
- No table of contents in SKILL.md (forbidden)

**For Style Compliance**:
- Follow third-person voice in descriptions
- Use imperative form in instructions
- Be concise but complete
- Avoid jargon without definitions
- Use consistent terminology

---

## 6. 🔍 Quality Checklist & Quick Reference

### Pre-Packaging Checklist

**Before running package_skill.py:**

Frontmatter:
□ YAML frontmatter present and valid
□ Required fields: name, description, allowed-tools
□ Name is hyphen-case (matches directory)
□ Description uses third-person voice
□ Description is specific (not generic)
□ No angle brackets in description
□ allowed-tools lists all tools used

Structure:
□ H1 title with descriptive subtitle
□ Numbered H2 sections (1. 🎯 WHEN TO USE, 2. 🗂️ REFERENCES, etc.)
□ H2 headings use title case + emoji
□ Section separators (---) between major sections
□ No table of contents (forbidden in SKILL.md)
□ Proper heading hierarchy (H1 → H2 → H3)
□ REFERENCES section placed after WHEN TO USE, before HOW IT WORKS

Content - Standard Sections:
□ WHEN TO USE section includes use cases + anti-patterns
□ HOW IT WORKS section explains workflow clearly
□ RULES section has ALWAYS, NEVER, ESCALATE IF
□ SUCCESS CRITERIA section defines completion
□ INTEGRATION POINTS section documents dependencies
□ All bundled resources referenced from SKILL.md
□ No duplication between SKILL.md and references/

Content - NEW Standardization (2025):
□ Navigation Guide present in Section 1 (if bundled resources exist)
□ SMART ROUTING section exists (Section 2 - REQUIRED for all skills)
□ REFERENCES section exists (Section 3 - REQUIRED for all skills)
□ REFERENCES has 3-column categorized tables (Document | Purpose | Key Insight)
□ Flowchart supplements added to complex logic blocks in Section 4 (where applicable)
□ Python/YAML code preserved (supplements, not replacements)
□ All ASCII diagrams use consistent style (↓, →, ───, │, [boxes])

Quality:
□ SKILL.md under 5k words (<3k preferred)
□ Concrete examples included
□ Rationale provided for rules
□ Language is third-person (descriptions) or imperative (instructions)
□ Consistent emoji usage
□ All code blocks specify language
□ Links work correctly
□ 3-column tables properly formatted (aligned columns)
□ SMART ROUTING Python pseudo-code is accurate and helpful
□ Navigation Guide lists ALL bundled resources


### Quick Reference Table

| Element               | Requirement                 | Example                                                                            |
| --------------------- | --------------------------- | ---------------------------------------------------------------------------------- |
| **Filename**          | `SKILL.md` (exact case)     | ✅ `SKILL.md`  ❌ `skill.md`                                                         |
| **Frontmatter**       | Required YAML with fields   | `name`, `description`, `allowed-tools`                                             |
| **Name Format**       | `hyphen-case`               | ✅ `cli-gemini`  ❌ `gemini_cli`                                                     |
| **Description Voice** | Third-person                | ✅ "Use when..."  ❌ "You should..."                                                 |
| **H2 Format**         | Number + Emoji + Title Case | ✅ `## 1. 🎯 WHEN TO USE`                                                            |
| **TOC**               | Forbidden in SKILL.md       | ❌ No table of contents                                                             |
| **Sections**          | 6 required sections         | WHEN TO USE, HOW IT WORKS, RULES, SUCCESS CRITERIA, INTEGRATION POINTS, REFERENCES |
| **File Size**         | <5k words (<3k preferred)   | Move details to references/                                                        |
| **Rules Format**      | ALWAYS, NEVER, ESCALATE IF  | All caps headers, specific rules                                                   |
| **Examples**          | Concrete and realistic      | Show actual use cases                                                              |

### Template Selection Matrix

| Characteristic        | Simple                       | Moderate                     | Complex                             |
| --------------------- | ---------------------------- | ---------------------------- | ----------------------------------- |
| **Workflows**         | Single                       | Single                       | Multiple modes                      |
| **Bundled Resources** | None                         | Some (refs/scripts/assets)   | Extensive                           |
| **Total Lines**       | 400-800                      | 800-2000                     | 2000-5000                           |
| **SKILL.md Lines**    | 400-800                      | 800-1000                     | <3000                               |
| **Sections**          | 6 core                       | 6 core + navigation          | 6 core per mode + overview          |
| **Example Skills**    | cli-gemini, cli-codex | save-context, workflows-code | create-documentation, workflows-git |

### Validation Command Reference

```bash
# Minimal validation (package_skill.py)
python3 scripts/package_skill.py .claude/skills/[skill-name]

# Comprehensive validation (create-documentation)
# Target: Structure 100/100, C7Score 85+, Overall 90+
# (Use after packaging for quality assurance)
```

---

**Related Files**:
- See [frontmatter_templates.md](./frontmatter_templates.md) for YAML frontmatter patterns
- See [skill_asset_template.md](./skill_asset_template.md) for creating bundled asset files
- See `../references/skill_creation.md` for complete skill creation workflow