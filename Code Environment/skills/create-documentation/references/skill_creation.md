# Skill Creation Workflow

Comprehensive reference for creating effective skills that extend AI agent capabilities with specialized knowledge, workflows, tool integrations, and bundled resources.

---

## 1. 📖 INTRODUCTION & PURPOSE

### What Is This Reference?

This reference provides complete guidance for creating, validating, and distributing AI agent skills. It covers the full lifecycle from initial concept through packaging and maintenance.

**Core Purpose**:
- **Skill architecture** - Progressive disclosure design with 3-level loading
- **Creation workflow** - Step-by-step process from concept to packaged skill
- **Validation standards** - Quality requirements and automated checks
- **Best practices** - Writing style, resource organization, common pitfalls

**Progressive Disclosure Context**:
```
Level 1: SKILL.md metadata (name + description)
         └─ Always in context (~100 words)
            ↓
Level 2: SKILL.md body
         └─ When skill triggers (<5k words)
            ↓
Level 3: Reference files (this document)
         └─ Loaded as needed for creation details
```

This reference file provides Level 3 deep-dive technical guidance on skill creation, validation, and distribution.

### Core Principle

**"Progressive disclosure maximizes value, minimizes cost"** - Keep metadata always-loaded, SKILL.md concise (<5k words), move details to references, extract logic to scripts, store output assets separately.

---

## 2. 🧠 UNDERSTANDING SKILLS

### What Skills Provide

Skills are modular, self-contained packages that transform an AI agent from a general-purpose assistant into a specialized agent equipped with procedural knowledge.

**Core Value Propositions**:
1. **Specialized workflows** - Multi-step procedures for specific domains
2. **Tool integrations** - Instructions for working with specific file formats or APIs
3. **Domain expertise** - Company-specific knowledge, schemas, business logic
4. **Bundled resources** - Scripts, references, and assets for complex tasks

### ️ Skill Architecture Philosophy

**Progressive Disclosure Design**: Skills use a three-level loading system for context efficiency:

1. **Metadata (name + description)** - Always in context (~100 words)
2. **SKILL.md body** - When skill triggers (<5k words)
3. **Bundled resources** - As needed by the agent (Unlimited*)

*Unlimited because scripts can be executed without reading into context window.

---

## 3. 📦 SKILL ANATOMY

Every skill consists of a required SKILL.md file and optional bundled resources:

```
skill-name/
├── SKILL.md (required)
│   ├── YAML frontmatter metadata (required)
│   │   ├── name: (required)
│   │   └── description: (required)
│   └── Markdown instructions (required)
└── Bundled Resources (optional)
    ├── scripts/          - Executable code (Python/Bash/etc.)
    ├── references/       - Documentation loaded into context as needed
    └── assets/           - Files used in output (templates, icons, fonts)
```

### SKILL.md Requirements

**Metadata Quality**: The `name` and `description` in YAML frontmatter determine when the AI agent will use the skill. Be specific about what the skill does and when to use it.

**Writing Style Guidelines**:
- Use **third-person** in descriptions (e.g., "This skill should be used when..." instead of "Use this skill when...")
- Write using **imperative/infinitive form** (verb-first instructions), not second person
- Use objective, instructional language (e.g., "To accomplish X, do Y" rather than "You should do X")
- Keep SKILL.md body under **5k words**

**Required Sections** (enforced by markdown-document-specialist validation):
1. WHEN TO USE
2. SMART ROUTING (Python routing logic for resource loading)
3. REFERENCES (bundled resources tables)
4. HOW IT WORKS
5. RULES (ALWAYS/NEVER/ESCALATE IF)

**Recommended Sections**:
6. SUCCESS CRITERIA
7. INTEGRATION POINTS

### Bundled Resources (Optional)

#### Scripts Directory (`scripts/`)

Executable code for tasks requiring deterministic reliability or repeatedly rewritten.

**When to include scripts**:
- Same code being rewritten repeatedly by the agent
- Deterministic reliability needed
- Performance optimization required
- Complex logic better handled by programming language

**Examples**:
- `scripts/rotate_pdf.py` - PDF rotation tasks
- `scripts/analyze_docs.py` - Document quality analysis
- `scripts/init_skill.py` - Skill scaffolding

**Benefits**:
- Token efficient (may execute without loading into context)
- Deterministic behavior
- Reusable across skill invocations

**Note**: Scripts may still need to be read for patching or environment adjustments.

#### References Directory (`references/`)

Documentation loaded as needed to inform the agent's process and thinking.

**When to include references**:
- Documentation the agent should reference while working
- Detailed domain knowledge
- API specifications
- Database schemas
- Company policies

**Examples**:
- `references/schema.md` - Database schema documentation
- `references/api_docs.md` - API endpoint specifications
- `references/policies.md` - Company policies and guidelines
- `references/workflows.md` - Detailed workflow documentation

**Use cases**:
- Database schemas
- API docs
- Domain knowledge
- Company policies
- Technical specifications

**Benefits**:
- Keeps SKILL.md lean
- Loaded only when needed
- Supports deep, detailed documentation

**Best practice**:
- If files are large (>10k words), include grep search patterns in SKILL.md
- Avoid duplication between SKILL.md and references
- Keep only essential instructions in SKILL.md
- Move detailed reference material to references files

#### Assets Directory (`assets/`)

Files used within the output the agent produces (not loaded into context).

**When to include assets**:
- Skill needs files for final output
- Templates for document generation
- Boilerplate code
- Images, icons, logos

**Examples**:
- `assets/logo.png` - Brand logo
- `assets/template.html` - HTML template
- `assets/font.ttf` - Custom font
- `assets/frontmatter_templates.md` - YAML frontmatter examples

**Use cases**:
- Templates
- Images
- Icons
- Boilerplate code
- Fonts
- Configuration files

**Benefits**:
- Separates output resources from documentation
- Keeps context window clean
- Provides consistent output resources

---

## 4. 🚀 SKILL CREATION PROCESS

Follow these steps in order, skipping only if there is a clear reason they are not applicable.

### Step 1: Understanding the Skill with Concrete Examples

**Objective**: Gain clear understanding of skill's purpose through concrete examples.

**Skip only when**: Skill's usage patterns are already clearly understood.

**Process**:
1. Understand concrete examples of how skill will be used
2. Examples can come from direct user input or generated and validated
3. Ask focused questions about functionality and use cases

**Example Questions** (for image-editor skill):
- "What functionality should the image-editor skill support?"
- "Can you give examples of how this would be used?"
- "What would a user say that should trigger this skill?"

**Best Practice**: Avoid overwhelming users—ask most important questions first, follow up as needed.

**Conclude when**: Clear sense of functionality the skill should support.

**Example Dialogue**:
```
AI: What functionality should the markdown-editor skill support?
User: I want to enforce markdown structure and optimize content for AI.

AI: Can you give specific examples of what you want enforced?
User: Filename conventions, frontmatter format, heading hierarchy.

AI: What optimization do you want for AI readability?
User: Convert documentation to question-answering format, remove metadata.
```


### Step 2: Planning Reusable Skill Contents

**Objective**: Identify scripts, references, and assets that will be reused across skill invocations.

**Process**:
1. Consider how to execute each example from scratch
2. Identify scripts, references, and assets helpful for repeated execution
3. Categorize resources by type (scripts/references/assets)

**Example 1: PDF Editor Skill**
- **Query**: "Help me rotate this PDF"
- **Analysis**: Rotating PDF requires re-writing same code each time
- **Solution**: Create `scripts/rotate_pdf.py`
- **Rationale**: Deterministic operation, same code repeatedly needed

**Example 2: Frontend Webapp Builder**
- **Query**: "Build me a todo app"
- **Analysis**: Requires same boilerplate HTML/React each time
- **Solution**: Create `assets/hello-world/` template
- **Rationale**: Starting point for every app, consistent structure

**Example 3: BigQuery Skill**
- **Query**: "How many users logged in today?"
- **Analysis**: Re-discovering table schemas each time
- **Solution**: Create `references/schema.md`
- **Rationale**: Schema documentation needed for query construction

**Example 4: Markdown Optimizer Skill**
- **Query**: "Optimize this documentation for AI"
- **Analysis**: Need to apply multiple transformation patterns consistently
- **Solution**: Create `scripts/analyze_docs.py` and `references/optimization.md`
- **Rationale**: Complex analysis better in Python, patterns documented for reference

**Output**: List of reusable resources (scripts, references, assets) with rationale.


### ️ Step 3: Initializing the Skill

**Objective**: Create skill directory structure with template files.

**Skip only when**: Skill already exists and iteration is needed.

**Command**:
```bash
scripts/init_skill.py <skill-name> --path <output-directory>
```

**Default path**: If `--path` not specified, creates in current directory.

**Script Actions**:
1. Creates skill directory at specified path
2. Generates SKILL.md template with proper frontmatter and TODO placeholders
3. Creates example resource directories: `scripts/`, `references/`, `assets/`
4. Adds example files that can be customized or deleted

**Generated SKILL.md Template**:
```yaml
---
name: skill-name
description: [TODO: Complete description]
---

# Skill Name

## 1. WHEN TO USE
[TODO: Describe when to use this skill]

## 2. SMART ROUTING
```python
def route_request(context):
    # [TODO: Add routing logic for resource selection]
    if context.needs_detailed_guide:
        load("references/guide.md")
    else:
        load("references/default.md")
```

## 3. REFERENCES
[TODO: Add 3-column tables listing bundled resources]

## 4. HOW IT WORKS
[TODO: Explain how the skill works]

## 5. RULES
[TODO: Add ALWAYS/NEVER/ESCALATE IF rules]

## 6. SUCCESS CRITERIA
[TODO: Define success criteria]

## 7. INTEGRATION POINTS
[TODO: Describe integration points]

## BUNDLED RESOURCES
[TODO: List bundled resources]
```

**After initialization**: Customize or remove generated files as needed.

**Example Usage**:
```bash
# Create skill in .opencode/skills/ directory
scripts/init_skill.py markdown-optimizer --path .opencode/skills

# Creates:
# .opencode/skills/markdown-optimizer/
# ├── SKILL.md (with TODO placeholders)
# ├── scripts/example_script.py
# ├── references/example_reference.md
# └── assets/example_asset.txt
```


### ️ Step 4: Edit the Skill

**Objective**: Populate skill with instructions and bundled resources.

**Remember**: Creating this skill for another AI agent instance to use. Focus on information that would be beneficial and non-obvious.

#### 4.1: Start with Reusable Skill Contents

Begin with resources identified in Step 2: `scripts/`, `references/`, and `assets/` files.

**Process**:
1. Create scripts identified in planning phase
2. Add reference documentation
3. Include asset files
4. Delete example files generated during initialization

**Note**: May require user input (e.g., brand assets, documentation templates).

**Important**: Delete example files and directories not needed for the skill.

**Example - Markdown Optimizer Skill**:
```bash
# Keep needed directories
scripts/
  ├── analyze_docs.py         # Created
  └── example_script.py       # DELETE

references/
  ├── core_standards.md       # Created
  ├── workflows.md            # Created
  ├── optimization.md         # Created
  ├── validation.md           # Created
  └── example_reference.md    # DELETE

assets/
  ├── frontmatter_templates.md  # Created
  └── example_asset.txt         # DELETE
```

#### 4.2: Update SKILL.md

Answer these questions in SKILL.md:

1. **What is the purpose of the skill, in a few sentences?**
   - Write clear, concise summary
   - Include in subtitle under H1

2. **When should the skill be used?**
   - Section 1: WHEN TO USE
   - Be specific about triggers and use cases
   - Include "When NOT to Use" subsection

3. **How should the agent route to the right resources?**
   - Section 2: SMART ROUTING
   - Python routing logic using load() and execute()
   - Route based on context to appropriate references/assets/scripts

4. **What resources are bundled with this skill?**
   - Section 3: REFERENCES
   - 3-column categorized tables (Document | Purpose | Key Insight)
   - Group by Core Framework, Bundled Resources, etc.

5. **How should the agent use the skill in practice?**
   - Section 4: HOW IT WORKS
   - Reference all bundled resources
   - Explain workflow and decision points

6. **What rules govern skill usage?**
   - Section 5: RULES
   - ALWAYS rules (required actions)
   - NEVER rules (forbidden actions)
   - ESCALATE IF (when to ask user)

**Writing Style Reminders**:
- Use imperative/infinitive form (verb-first: "Run validation", "Check structure")
- Third-person descriptions ("This skill should be used when...")
- Objective, instructional language
- Keep total under 5k words

**Frontmatter Completion**:
```yaml
---
name: markdown-optimizer
description: Complete document quality pipeline with structure enforcement, content optimization (c7score), and style guide compliance. Unified skill replacing markdown-enforcer and llm-docs-optimizer.
allowed-tools: Read, Write, Edit, Bash, Glob, Grep
version: 1.0.0
---
```

**Description Quality Guidelines**:
- Be specific about what the skill does
- Mention key capabilities or workflows
- Use third-person form
- Avoid generic descriptions
- Include context about when to use
- No angle brackets (e.g., `<skill-name>`)


### Step 5: Packaging a Skill

**Objective**: Validate skill and package into distributable zip file.

**Command**:
```bash
scripts/package_skill.py <path/to/skill-folder>
```

**Optional output directory**:
```bash
scripts/package_skill.py <path/to/skill-folder> ./dist
```

**Packaging Process**:

**Phase 1: Validation** (automatic):
- YAML frontmatter format and required fields
- Skill naming conventions (hyphen-case)
- Description completeness and quality (no angle brackets, no generic text)
- Directory structure validation
- File organization check

**Validation Checks**:
1. SKILL.md exists
2. Frontmatter starts with `---`
3. Frontmatter has closing `---`
4. Required fields present: `name`, `description`
5. Name is hyphen-case (lowercase, hyphens, no underscores)
6. Name doesn't start/end with hyphen
7. No consecutive hyphens
8. No angle brackets in description (e.g., `<skill-name>`)
9. Description is complete (not just TODO placeholder)

**Phase 2: Packaging** (if validation passes):
- Creates zip file named after skill (e.g., `markdown-optimizer.zip`)
- Includes all files with proper directory structure
- Preserves executable permissions for scripts
- Creates in output directory or skill parent directory

**If validation fails**:
- Error messages printed to console
- Specific issues highlighted
- Fix errors and run packaging command again

**Success Output**:
```
✅ Validation passed
📦 Packaging skill: markdown-optimizer
✅ Successfully packaged skill to: ./dist/markdown-optimizer.zip

💡 Recommended next step:
   Run quality validation to ensure production readiness:
   markdown-document-specialist --validate-skill markdown-optimizer/SKILL.md
   Target: 90+ overall score
```


### Step 6: Iterate

**Objective**: Test and improve based on real usage.

**Iteration Workflow**:
1. Use skill on real tasks
2. Notice struggles or inefficiencies
3. Identify SKILL.md or bundled resource updates needed
4. Implement changes
5. Repackage and test again

**Best Time to Iterate**: Right after using skill, with fresh context of performance.

**Common Iteration Patterns**:

**Pattern 1: Unclear Instructions**
- Symptom: The agent misinterprets skill guidance
- Fix: Add examples to SKILL.md, clarify wording
- Location: Typically in HOW IT WORKS or RULES sections

**Pattern 2: Missing Resources**
- Symptom: The agent recreates same code/content repeatedly
- Fix: Add script or reference file
- Location: New file in scripts/ or references/

**Pattern 3: Overly Detailed SKILL.md**
- Symptom: SKILL.md exceeds 5k words, context window strain
- Fix: Move detailed content to references/ files
- Location: Extract sections to references/, add pointers in SKILL.md

**Pattern 4: Skill Not Triggering**
- Symptom: The agent doesn't use skill when appropriate
- Fix: Improve description in frontmatter, be more specific about triggers
- Location: YAML frontmatter `description` field

**Iteration Example - Markdown Optimizer**:
```
Initial Version:
- SKILL.md: 800 words
- description: "Optimizes markdown files"
- Problem: Too generic, skill didn't trigger

Iteration 1:
- Updated description: "Complete document quality pipeline with structure enforcement, content optimization (c7score), and style guide compliance"
- Result: Better triggering, but users confused about modes

Iteration 2:
- Added workflows.md reference with detailed mode explanations
- Added examples section with before/after
- Result: Clear usage, high adoption

Iteration 3:
- Added analyze_docs.py script to automate c7score calculation
- Result: Faster execution, more reliable scoring
```

---

## 5. ✅ VALIDATION REQUIREMENTS

### Minimal Validation (quick_validate.py)

**Purpose**: Pre-packaging sanity check for essential frontmatter requirements.

**Checks**:
1. SKILL.md file exists
2. YAML frontmatter present
3. Required fields: name, description
4. Name format: hyphen-case
5. No angle brackets in description
6. **Platform compatibility** - Features work across different AI agent environments

**Output**: Pass/fail with error messages

**When to use**: Automatically during packaging


### Comprehensive Validation (markdown-document-specialist)

**Purpose**: Full quality assurance for production-ready skills.

**Three-Dimensional Scoring**:

**Structure Dimension (0-100)**:
- YAML frontmatter valid
- Single H1, no duplicates
- Proper heading hierarchy
- Required sections present and ordered (WHEN TO USE, HOW IT WORKS, RULES)
- H2 format (title case + emoji)
- Code blocks properly fenced
- No unclosed markdown elements

**C7Score Dimension (0-100)**:
- Question-answering coverage
- Complete workflow examples
- Integration examples
- Error handling examples
- Testing examples
- Code formatting quality

**Style Dimension (0-100)**:
- Document style guide compliance
- Frontmatter format
- Bullet list length (<7 items recommended)
- Terminology consistency
- Active voice preference
- Emoji usage rules

**Overall Score**: Weighted average
- Structure: 40%
- C7Score: 40%
- Style: 20%

**Quality Gates**:
- 90-100: Excellent (production ready)
- 80-89: Good (shareable)
- 70-79: Acceptable (functional)
- <70: Needs improvement

**Target for SKILL.md**: 90+ overall score

**When to use**: After packaging, before distribution

**Command**:
```bash
markdown-document-specialist --validate .opencode/skills/my-skill/SKILL.md
```

---

## 6. 📖 SKILL WRITING BEST PRACTICES

### ️ Writing Style Guidelines

**Voice and Tone**:
- Third-person in descriptions
- Imperative/infinitive form in instructions
- Objective, instructional language
- Professional but approachable

**Structure**:
- Keep SKILL.md under 5k words
- Use progressive disclosure (SKILL.md → references → scripts)
- Clear section hierarchy with numbered H2 headers
- Consistent formatting

**Clarity**:
- Be specific, not generic
- Provide concrete examples
- Reference bundled resources explicitly
- Explain why, not just what

### Description Quality

**Good Descriptions** (specific, action-oriented):
- "Complete document quality pipeline with structure enforcement, content optimization (c7score), and style guide compliance"
- "Browser automation, debugging, and performance analysis using Puppeteer CLI scripts"
- "Professional Git commit workflow - analyze changes, determine commit strategy, and write high-quality commit messages"

**Bad Descriptions** (generic, vague):
- "Helps with markdown files"
- "This skill optimizes documents"
- "Use this for commits"

**Description Checklist**:
- ✅ Specific about what skill does
- ✅ Mentions key capabilities
- ✅ Uses third-person form
- ✅ Includes when to use context
- ✅ No angle brackets or placeholders
- ❌ Avoids generic phrases
- ❌ Not just TODO placeholder

### Resource Organization

**SKILL.md Content** (always loaded):
- High-level workflow
- When to use / when not to use
- Quick reference
- Pointers to references

**references/ Content** (loaded as needed):
- Detailed documentation
- API specifications
- Schema definitions
- Extended examples
- Policy documentation

**scripts/ Content** (executed, not loaded):
- Deterministic operations
- Repeatedly needed code
- Performance-critical logic
- Complex algorithms

**assets/ Content** (used in output):
- Templates
- Images
- Boilerplate code
- Configuration files

**Anti-Pattern**: Duplicating information between SKILL.md and references/

**Best Practice**: Mention in SKILL.md, detail in references/

**Example**:
```markdown
<!-- In SKILL.md -->
## 4. HOW IT WORKS

See [workflows.md](./references/workflows.md) for detailed execution modes.

<!-- In references/workflows.md -->
## EXECUTION MODES

### Mode 1: Full Pipeline
[Detailed explanation with examples...]

### Mode 2: Enforcement Only
[Detailed explanation with examples...]
```

---

## 7. ⚠️ COMMON PITFALLS

### Pitfall 1: Generic Descriptions

**Problem**: Skill doesn't trigger because description is too vague.

**Example**:
```yaml
# Bad
description: Helps with markdown files

# Good
description: Complete document quality pipeline with structure enforcement, content optimization (c7score), and style guide compliance
```

**Fix**: Be specific about capabilities and use cases.


### Pitfall 2: Bloated SKILL.md

**Problem**: SKILL.md exceeds 5k words, straining context window.

**Example**:
```markdown
# Bad - Everything in SKILL.md
## 4. HOW IT WORKS
[2000 words of detailed documentation]
[500 lines of examples]
[1000 words of API specs]

# Good - Progressive disclosure
## 4. HOW IT WORKS
See [workflows.md](./references/workflows.md) for execution modes.
See [optimization.md](./references/optimization.md) for transformation patterns.
```

**Fix**: Move detailed content to references/, keep SKILL.md lean.


### Pitfall 3: Missing Bundled Resources

**Problem**: The agent recreates same code repeatedly instead of using scripts.

**Example**:
```markdown
# Bad - No script provided
## HOW IT WORKS
Rotate PDF by writing Python code using PyPDF2...

# Good - Script provided
## HOW IT WORKS
Use scripts/rotate_pdf.py to rotate PDF files.
```

**Fix**: Identify repeatedly needed code, create scripts.


### Pitfall 4: Unclear Triggers

**Problem**: Skill exists but never triggers because conditions are unclear.

**Example**:
```markdown
# Bad
## 1. WHEN TO USE
Use this skill for documents.

# Good
## 1. WHEN TO USE
Use this skill when validating markdown files after Write/Edit operations.
Manual optimization when:
- README needs c7score 85+
- Creating critical documentation
- Quality assurance before sharing
```

**Fix**: Be specific about automatic vs manual triggers, clear use cases.


### Pitfall 5: Second-Person Language

**Problem**: Skill uses "you" instead of imperative form.

**Example**:
```markdown
# Bad
You should validate the file before processing.

# Good
Validate the file before processing.
```

**Fix**: Use imperative/infinitive form throughout.


### Pitfall 6: Platform Compatibility

**Problem**: Skill references automatic triggers or platform-specific features that don't work in OpenCode.

**Context**: Skills should be platform-agnostic. OpenCode uses AGENTS.md discipline for enforcement, not automatic triggers.

**Example**:
```markdown
# Bad - Claims automatic behavior
#### Automatic Enforcement
Enforcement runs automatically via triggers:
- After Write/Edit operations
- Before AI processes prompts

# Good - Manual workflow documentation
#### Validation Workflow
**Filename Validation** (after Write/Edit operations):
- Purpose: Filename enforcement
- Apply: After creating or editing files
- Verify: Before claiming completion
```

**Fix**: When documenting enforcement features:
1. Replace "runs automatically" with "verify manually"
2. Replace "blocks commits" with "verify before commits"
3. Replace "Automatic activation" with "Use this skill when"
4. Focus on AGENTS.md discipline, not automatic triggers

**Validation Check**: Search for outdated patterns before packaging:
```bash
grep -E "runs automatically|blocks commits|Automatic.*via|auto-enforced" SKILL.md
```

---

## 8. 💡 EXAMPLE SKILLS

### Example 1: PDF Editor Skill

**Purpose**: Rotate, crop, and edit PDF files

**Directory Structure**:
```
pdf-editor/
├── SKILL.md
├── scripts/
│   ├── rotate_pdf.py
│   ├── crop_pdf.py
│   └── merge_pdfs.py
└── references/
    └── pdf_operations.md
```

**SKILL.md Highlights**:
- When to use: PDF manipulation tasks
- How it works: References scripts for operations
- Rules: Always validate PDF before processing
- Success criteria: Operation completes without corruption

**Bundled Resources**:
- `scripts/rotate_pdf.py` - Rotate PDF pages
- `scripts/crop_pdf.py` - Crop PDF regions
- `scripts/merge_pdfs.py` - Merge multiple PDFs
- `references/pdf_operations.md` - PyPDF2 documentation


### Example 2: Brand Guidelines Skill

**Purpose**: Apply company branding to documents

**Directory Structure**:
```
brand-guidelines/
├── SKILL.md
├── assets/
│   ├── logo.png
│   ├── logo-dark.png
│   └── color_palette.json
└── references/
    └── brand_guidelines.md
```

**SKILL.md Highlights**:
- When to use: Creating customer-facing documents
- How it works: Apply branding from assets/
- Rules: Always use official logo, follow color palette
- Success criteria: Document matches brand guidelines

**Bundled Resources**:
- `assets/logo.png` - Primary logo
- `assets/logo-dark.png` - Dark mode logo
- `assets/color_palette.json` - Official colors
- `references/brand_guidelines.md` - Detailed brand rules


### ️ Example 3: Database Query Skill

**Purpose**: Query company database with proper schemas

**Directory Structure**:
```
database-query/
├── SKILL.md
└── references/
    ├── schema.md
    └── common_queries.md
```

**SKILL.md Highlights**:
- When to use: Querying company database
- How it works: Reference schema, construct queries
- Rules: Always use prepared statements, check permissions
- Success criteria: Query executes successfully, returns expected data

**Bundled Resources**:
- `references/schema.md` - Database schema documentation
- `references/common_queries.md` - Query pattern examples

---

## 9. 🔧 SKILL MAINTENANCE

### When to Update Skills

**Update triggers**:
1. Skill struggles with common use cases
2. User feedback indicates confusion
3. New features needed
4. Bundled resources become outdated
5. Writing style inconsistencies discovered

### ️ Update Workflow

1. **Identify Issue**: Use skill, notice problem
2. **Diagnose**: SKILL.md unclear? Missing resource? Outdated info?
3. **Fix**: Update relevant files
4. **Validate**: Run quality validation
5. **Repackage**: Create new zip file
6. **Test**: Try skill on real task
7. **Document**: Note changes in version history

### Versioning

**Semantic Versioning** (recommended):
- Major (1.0.0 → 2.0.0): Breaking changes, complete restructure
- Minor (1.0.0 → 1.1.0): New features, new bundled resources
- Patch (1.0.0 → 1.0.1): Bug fixes, typo corrections

**Update frontmatter version field**:
```yaml
---
name: markdown-optimizer
description: Complete document quality pipeline...
version: 2.0.0
---
```

---

## 10. 📤 DISTRIBUTION

### Packaging for Distribution

**Command**:
```bash
scripts/package_skill.py <path/to/skill> <output-directory>
```

**Output**: Zip file ready for distribution

**Distribution Checklist**:
- ✅ Validation passed
- ✅ Quality score 90+
- ✅ All bundled resources included
- ✅ README or documentation provided
- ✅ Version number in frontmatter
- ✅ License information (if applicable)

### Installation

**User installation**:
1. Download skill zip file
2. Extract to `.opencode/skills/` directory
3. Skill automatically available to the agent

**Verification**:
- Check skill appears in the agent's skill list
- Test skill with example use case
- Verify bundled resources accessible

---

## 11. 🎯 QUICK REFERENCE

### File Structure

```
skill-name/
├── SKILL.md (required)
│   ├── YAML frontmatter (name, description, allowed-tools, version)
│   └── Markdown content (<5k words)
├── scripts/ (optional)
│   └── *.py, *.sh
├── references/ (optional)
│   └── *.md
└── assets/ (optional)
    └── *.*
```

### ️ Writing Style

- **Third-person**: "This skill should be used when..."
- **Imperative form**: "Validate file before processing"
- **Objective tone**: Instructional, not conversational
- **Concise**: SKILL.md < 5k words

### Required Sections

1. WHEN TO USE
2. HOW IT WORKS
3. RULES

### Recommended Sections

4. SUCCESS CRITERIA
5. EXAMPLES
6. INTEGRATION POINTS
7. QUICK REFERENCE

### Commands

**Initialize**:
```bash
scripts/init_skill.py <skill-name> --path <output-dir>
```

**Package**:
```bash
scripts/package_skill.py <skill-path> <output-dir>
```

**Validate**:
```bash
markdown-document-specialist --validate <skill-path>/SKILL.md
```

### Quality Targets

- Structure: 100/100
- C7Score: 85+/100
- Style: 90+/100
- Overall: 90+/100

---

## 12. 🛠️ SCRIPT USAGE

### init_skill.py

**Purpose**: Generate skill directory structure with templates.

**Usage**:
```bash
python scripts/init_skill.py <skill-name> [--path <output-directory>]
```

**Arguments**:
- `skill-name` (required): Name in hyphen-case (e.g., `markdown-optimizer`)
- `--path` (optional): Output directory (default: current directory)

**Output**:
- Creates `<output-directory>/<skill-name>/` folder
- Generates SKILL.md with TODO placeholders
- Creates example `scripts/`, `references/`, `assets/` directories

**Example**:
```bash
python scripts/init_skill.py pdf-editor --path .opencode/skills

# Creates:
# .opencode/skills/pdf-editor/
# ├── SKILL.md
# ├── scripts/example_script.py
# ├── references/example_reference.md
# └── assets/example_asset.txt
```


### package_skill.py

**Purpose**: Validate and package skill into distributable zip file.

**Usage**:
```bash
python scripts/package_skill.py <skill-path> [output-directory]
```

**Arguments**:
- `skill-path` (required): Path to skill folder
- `output-directory` (optional): Where to create zip file (default: skill parent directory)

**Validation** (automatic):
- Frontmatter format and required fields
- Naming conventions
- Description quality
- File structure

**Output**:
- `<skill-name>.zip` file
- Validation report

**Example**:
```bash
python scripts/package_skill.py .opencode/skills/pdf-editor ./dist

# Creates: ./dist/pdf-editor.zip
```


### quick_validate.py

**Purpose**: Minimal validation for essential requirements.

**Usage**:
```bash
python scripts/quick_validate.py <skill-path>
```

**Checks**:
- SKILL.md exists
- Frontmatter valid
- Required fields present
- Name format correct
- No angle brackets in description

**Output**: Pass/fail with specific error messages

**Example**:
```bash
python scripts/quick_validate.py .opencode/skills/pdf-editor

# Output:
# Validation passed
# OR
# Validation failed: Missing required field 'description'
```

## END OF SKILL CREATION WORKFLOW