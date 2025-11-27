---
name: workflows-conversation
description: Mandatory spec folder workflow orchestrating documentation level selection (0-3), template selection, and folder creation for all file modifications through hook-assisted enforcement and context auto-save.
allowed-tools: ["*"]
version: 1.0.0
---

# 🗂️ Conversation Documentation Workflow - Mandatory Spec Folder System & Template Enforcement

Orchestrates mandatory spec folder creation for all conversations involving file modifications. This skill ensures proper documentation level selection (0-3), template usage, and context preservation through automated workflows and hook-assisted enforcement.

---

## 1. 🎯 WHEN TO USE

### Navigation Guide

**This file (SKILL.md)**: Overview of conversation documentation workflow and orchestration

**Reference Files** (detailed documentation):
- [level_specifications.md](./references/level_specifications.md) - Complete specifications for documentation levels 0-3
- [template_guide.md](./references/template_guide.md) - Template selection, copying, and adaptation rules
- [automation_workflows.md](./references/automation_workflows.md) - Hook behavior, enforcement, and context auto-save
- [quick_reference.md](./references/quick_reference.md) - Commands, checklists, and troubleshooting

**Assets** (decision tools and mappings):
- [level_decision_matrix.md](./assets/level_decision_matrix.md) - LOC thresholds and complexity factors for level selection
- [template_mapping.md](./assets/template_mapping.md) - Template-to-level mapping with copy commands

### Activation Triggers

**MANDATORY activation for ALL file modifications:**
- Code files (JS, TS, Python, CSS, HTML)
- Documentation files (Markdown, README, guides)
- Configuration files (JSON, YAML, TOML, env templates)
- Knowledge base files (`.claude/knowledge/*.md`)
- Template files (`.opencode/speckit/templates/*.md`)
- Build/tooling files (package.json, requirements.txt, Dockerfile)

**User request patterns:**
- "Add/implement/create [feature]"
- "Fix/update/refactor [code]"
- "Modify/change [configuration]"
- Hook detection: modification keywords (add, implement, fix, update, etc.)

### When NOT to Use

- ❌ Pure exploration/reading (no file modifications)
- ❌ Single typo fixes (<5 characters in one file)
- ❌ Whitespace-only changes
- ❌ Auto-generated file updates (package-lock.json)
- ❌ User explicitly selects Option D (skip documentation) - creates technical debt

**Rule of thumb:** If you're modifying ANY file content → Activate this skill.

---

## 2. 🧭 SMART ROUTING

```python
def route_conversation_resources(task):
    # level 1: simple changes (< 100 LOC)
    if task.estimated_loc < 100:
        return load("templates/spec_template.md")  # spec.md only
    
    # level 2: moderate changes (100-499 LOC)
    if task.estimated_loc < 500:
        load("templates/spec_template.md")  # spec.md
        return load("templates/plan_template.md")  # + plan.md
    
    # level 3: complex changes (>= 500 LOC)
    if task.estimated_loc >= 500:
        return execute("/speckit.specify")  # auto-generates all core files
    
    # supporting templates (optional, load as needed)
    if task.needs_task_breakdown:
        return load("templates/tasks_template.md")
    if task.needs_validation_checklist:
        return load("templates/checklist_template.md")
    if task.documenting_decision:
        return load("templates/decision_record_template.md")
    if task.doing_research:
        return load("templates/research_spike_template.md")

# levels: 1 (< 100 LOC), 2 (100-499 LOC), 3 (>= 500 LOC)
# high risk/complexity bumps to at least level 2
# templates in: .opencode/speckit/templates/
```

---

## 3. 🗂️ REFERENCES

### Core Framework & Workflows

| Document | Purpose | Key Insight |
|----------|---------|-------------|
| **Conversation Documentation - Main Workflow** | Orchestrates spec folder creation for all file modifications | **Hook-assisted enforcement with 4-level decision framework** |

### Bundled Resources

| Document | Purpose | Key Insight |
|----------|---------|-------------|
| **assets/level_decision_matrix.md** | LOC thresholds and decision factors | **LOC is primary**; complexity/risk can override |
| **assets/template_mapping.md** | Template-to-level mapping with copy commands | Always copy from `.opencode/speckit/templates/` - **never freehand** |
| **references/level_specifications.md** | Complete Level 1-3 specifications | **When in doubt, choose higher level** |
| **references/template_guide.md** | Template selection and adaptation rules | Fill **ALL placeholders**, remove sample content |
| **references/automation_workflows.md** | Hook enforcement and context auto-save | Hook prompts **at conversation start**, not mid-work |
| **references/quick_reference.md** | Commands, checklists, troubleshooting | Pre-implementation checklist is **mandatory** |

---

## 4. ⚙️ HOW IT WORKS

### 4-Level Decision Framework

The conversation documentation system uses a graduated approach based on Lines of Code (LOC) and complexity:

**Level 1: Simple (<100 LOC)**
- Localized to one component or trivial changes
- Clear, well-defined requirements
- Low to moderate complexity
- **Documentation**: `spec.md` (from `spec_template.md`)
- **Optional**: `checklist.md` for validation
- **Example**: Add email validation, fix bug, loading spinner, typo fix

**Level 2: Moderate (100-499 LOC)**
- Multiple files or components
- Moderate complexity
- Requires planning and coordination
- **Documentation**: `spec.md` + `plan.md` (from standard templates)
- **Optional**: `tasks.md`, `checklist.md`, `research-spike-*.md`, `decision-record-*.md`
- **Example**: Modal component, auth flow, library migration

**Level 3: Complex (≥500 LOC)**
- High complexity
- Multiple systems
- Significant architectural impact
- **Process**: Use `/speckit.specify` command (auto-generates all core files)
- **Auto-generated**: `spec.md`, `plan.md`, `tasks.md`, `research.md`, `data-model.md`, `quickstart.md`, `contracts/`
- **Optional**: `checklist.md` (manual copy)
- **Example**: Major feature, system redesign, multi-team projects


### Secondary Factors (Can Override LOC)

- **Complexity**: Architectural changes vs simple refactors
- **Risk**: Config cascades, authentication, security implications
- **Dependencies**: Multiple systems affected
- **Testing needs**: Integration vs unit test requirements

**Decision rule**: When in doubt, choose the **higher level**.


### Template System

**All templates located in**: `.opencode/speckit/templates/`

**Core templates by level:**
- Level 1: `spec_template.md` → `spec.md`
- Level 2: `spec_template.md` + `plan_template.md` → `spec.md` + `plan.md`
- Level 3: `/speckit.specify` command (auto-generates)

**Supporting templates (optional):**
- `tasks_template.md` → `tasks.md` (after plan, before coding)
- `checklist_template.md` → `checklist.md` (validation needs)
- `decision_record_template.md` → `decision-record-[name].md` (major decisions)
- `research_spike_template.md` → `research-spike-[name].md` (research/POC)


### Folder Naming Convention

**Format**: `specs/###-short-name/`

**Rules**:
- 2-3 words (shorter is better)
- Lowercase
- Hyphen-separated
- Action-noun structure
- 3-digit padding: `001`, `042`, `099` (no padding past 999)

**Good examples**: `fix-typo`, `add-auth`, `mcp-code-mode`, `cli-codex`

**Find next number**:
```bash
ls -d specs/[0-9]*/ | sed 's/.*\/\([0-9]*\)-.*/\1/' | sort -n | tail -1
```

### Hook-Assisted Enforcement

**`enforce-spec-folder.sh` hook behavior:**

**Start of conversation** (empty/minimal spec folder):
- Detects modification keywords (add, implement, fix, etc.)
- Searches for related existing specs
- Presents options: A) Use existing, B) Create new, C) Update related, D) Skip (technical debt)
- Does NOT block - allows conversation to continue
- AI agent asks user for choice (A/B/C/D)

**Mid-conversation** (substantial content exists):
- Detects real work started (>2 files OR files >1000 bytes)
- **Prompts for spec folder confirmation** (two-stage flow):
  1. Stage 1: "Continue in this spec folder?" (A/B/D)
  2. Stage 2: "Load memory files?" (A/B/C/D) - only if A chosen in Stage 1
- See "Two-Stage Question Flow" section for details

**Option D (Skip):**
- Creates `.claude/.spec-skip` marker file
- Subsequent prompts skip validation
- Logs skip events to audit trail
- **WARNING**: Creates technical debt - use sparingly


### Context Auto-Save

**`save-context-trigger.sh` hook behavior:**
- Saves conversation context every 20 messages (20, 40, 60, 80...)
- Parallel execution when available (non-blocking)
- Target: `specs/###-folder/memory/` or sub-folder memory/ if active
- Manual trigger: Keywords "save context", "save conversation"


### Sub-Folder Versioning Pattern

When reusing existing spec folders for iterative work, the system automatically creates sub-folders to separate iterations while maintaining independent memory contexts.

**Pattern Structure:**
```
specs/###-name/
├── 001-original-topic/   # Auto-archived first iteration
│   ├── spec.md
│   ├── plan.md
│   └── memory/
│       └── {timestamp}__.md
├── 002-new-iteration/    # Second iteration
│   ├── spec.md
│   ├── plan.md
│   └── memory/
│       └── {timestamp}__.md
└── 003-another-task/     # Third iteration (current, active)
    ├── spec.md
    ├── plan.md
    └── memory/           # Independent context
        └── {timestamp}__.md
```

**When This Triggers:**
- User selects **Option A** (use existing folder)
- Spec folder has root-level content (spec.md, plan.md, etc.)
- Hook detects need for iteration separation

**What Happens Automatically:**
1. System detects root-level files in existing spec folder
2. Hook prompts AI to ask user for new sub-folder name
3. AI calls `migrate_to_subfolders()` function via Bash tool
4. System archives existing files to `001-{topic}/` (numbered)
5. System creates new sub-folder with user-provided name
6. System copies fresh templates to new sub-folder
7. `.spec-active` marker updated to point to new sub-folder
8. Each sub-folder maintains independent `memory/` directory

**Naming Convention:**
- **Sub-folder format**: `{###}-{descriptive-name}` (automatic numbering)
  - Numbers: 001, 002, 003, etc. (3-digit padded, sequential)
  - Archive: `001-{original-topic}` (automatic, based on spec folder name)
  - New: `002-{user-provided-name}` (user provides descriptive name)
  - Name rules: lowercase, hyphens, 2-3 words (shorter is better)
  - Examples: `001-mcp-code-mode`, `002-api-refactor`, `003-bug-fixes`

**AI Workflow When Migration Needed:**
```
1. Hook displays: "📦 SUB-FOLDER VERSIONING WILL BE APPLIED"
2. User selects Option A
3. AI asks: "Please provide a name for the new sub-folder (e.g., 'api-refactor')"
4. User provides: "spec-folder-versioning"
5. AI executes:
   node -e "
   const { execSync } = require('child_process');
   const result = execSync(
     'bash -c \"source .claude/hooks/UserPromptSubmit/enforce-spec-folder.sh && migrate_to_subfolders \\\"specs/122-skill-standardization\\\" \\\"spec-folder-versioning\\\"\"',
     { encoding: 'utf-8', stdio: 'pipe' }
   );
   console.log(result);
   "
6. System creates:
   ├── 001-skill-standardization/  (archive)
   └── 002-spec-folder-versioning/ (new, active)
7. AI copies fresh templates to new sub-folder
8. Work proceeds in new sub-folder
```

**Memory Context Routing:**
- `save-context` reads `.spec-active` marker
- Writes to active sub-folder's `memory/` directory
- Each iteration has isolated conversation history
- Root `memory/` preserved for legacy saves (backward compatibility)

**Example Use Case:**
```
Scenario: Working on skill standardization across multiple skills

Initial work: specs/122-skill-standardization/
  └── (root files: spec.md, plan.md, etc.)

User: "Work on cli-codex alignment"
System: Creates → 001-cli-codex-alignment/ sub-folder

User: "Now work on workflows-conversation alignment"
System: Archives to 002-cli-codex-alignment/
System: Creates → 003-workflows-conversation-alignment/ sub-folder

Result: Clean separation of work, independent memory contexts
```

**Benefits:**
- ✅ Clean separation of iterative work
- ✅ Preserves all historical work (no data loss)
- ✅ Independent memory/ contexts per iteration
- ✅ Automatic archival with timestamps
- ✅ Backward compatible (works with non-versioned folders)


### Two-Stage Question Flow (Returning to Spec Folder)

When returning to an active spec folder, the hook now asks **two separate questions in sequence**:

**Stage 1: Spec Folder Confirmation** (MANDATORY)
```
🔴 MANDATORY_USER_QUESTION
"You have an active spec folder. Continue in '006-commands' or start fresh?"
  A) Continue in 006-commands (has previous session context)
  B) Create new spec folder (specs/007-new-feature/)
  D) Skip documentation (creates .spec-skip marker)
```

**Stage 2: Memory File Selection** (only if A chosen in Stage 1)
```
📁 Spec folder confirmed: 006-commands

🧠 MEMORY FILES AVAILABLE
Found 3 previous session file(s):
  • 26-11-25_08-42__commands.md
  • 25-11-25_15-30__planning.md

🔴 MANDATORY_USER_QUESTION
"Would you like to load previous session context?"
  A) Load most recent
  B) Load all recent (files 1-3)
  C) List all memory files and select specific
  D) Skip (start fresh without loading context)
```

**Key Insight:** "D" means different things at each stage:
- Stage 1 "D" = Skip documentation entirely (no spec folder)
- Stage 2 "D" = Skip memory loading (but stay in spec folder)

**AI Workflow (MANDATORY):**
1. Hook displays Stage 1 (spec folder confirmation)
2. **AI MUST ask user**: "Continue in this spec folder? (A/B/D)"
3. Wait for explicit choice
4. If A chosen AND memory files exist:
   - Hook displays Stage 2 (memory file selection)
   - **AI MUST ask user**: "Load memory files? (A/B/C/D)"
   - Wait for explicit choice
5. Based on Stage 2 selection:
   - **A**: Read most recent file using Read tool
   - **B**: Read 3 most recent files using Read tool (parallel calls)
   - **C**: List up to 10 files, wait for user number selection, then read
   - **D**: Proceed without loading context (stays in spec folder)
6. Acknowledge loaded context and continue conversation

**Memory File Format:**
- Filename: `DD-MM-YY_HH-MM__topic-name.md`
- Example: `23-11-25_10-10__mcp-code-mode-alignment.md`
- Location: Active sub-folder `memory/` or root `memory/` (fallback)

**Integration with Sub-Folder Versioning:**
```
specs/122-skill-standardization/
├── 001-original-work/
│   └── memory/
│       └── 23-11-25_10-10__original.md  (archived)
└── 002-api-refactor/       (.spec-active points here)
    └── memory/
        └── 23-11-25_11-30__api-refactor.md  ← This is shown
```

**Benefits:**
- ✅ Seamless context restoration across sessions
- ✅ Prevents re-asking questions already answered
- ✅ Maintains conversation continuity
- ✅ User control over context loading (A/B/C/D options)
- ✅ Sub-folder aware (respects active iteration)

---

## 5. 📋 RULES

### ✅ ALWAYS 

1. **ALWAYS determine documentation level (1/2/3) before ANY file changes**
   - Count LOC estimate
   - Assess complexity and risk
   - Choose higher level when uncertain

2. **ALWAYS copy templates from `.opencode/speckit/templates/` - NEVER create from scratch**
   - Use exact template files for level
   - Rename correctly after copying
   - Preserve template structure

3. **ALWAYS fill ALL placeholders in templates**
   - Replace `[PLACEHOLDER]` with actual content
   - Remove `<!-- SAMPLE CONTENT -->` blocks
   - Remove instructional comments

4. **ALWAYS respond to hook confirmation prompts by asking user for choice (A/B/C/D)**
   - Present all 4 options clearly
   - Explain implications of each choice
   - Wait for explicit user selection

5. **ALWAYS check for related specs before creating new folders**
   - Search by keywords in folder names and titles
   - Review status field (draft/active/paused/complete/archived)
   - Recommend updates to existing specs when appropriate

6. **ALWAYS get explicit user approval before file changes**
   - Present documentation level chosen
   - Show spec folder path
   - List templates used
   - Explain implementation approach
   - Wait for "yes/go ahead/proceed"

7. **ALWAYS use consistent folder naming**
   - Format: `specs/###-short-name/`
   - 2-3 words, lowercase, hyphen-separated
   - Find next number with command

### ❌ NEVER 

1. **NEVER create documentation files from scratch** - Always copy from `.opencode/speckit/templates/`

2. **NEVER skip spec folder creation** (unless user explicitly selects Option D)
   - All file modifications require spec folders
   - Applies to code, docs, config, templates, knowledge base files

3. **NEVER make file changes before spec folder creation and user approval**
   - Spec folder is prerequisite for ALL modifications
   - No exceptions without explicit user choice (Option D)

4. **NEVER leave placeholder text in final documentation**
   - All `[PLACEHOLDER]` must be replaced
   - All sample content must be removed
   - Templates must be fully adapted

5. **NEVER decide autonomously between update vs create**
   - Always ask user when related specs exist
   - Present status and let user choose
   - Respect user's explicit choice

6. **NEVER proceed without hook confirmation response**
   - If hook presents options → Ask user to choose
   - Wait for explicit A/B/C/D selection
   - Document choice in spec folder

### ⚠️ ESCALATE IF

1. **Scope grows during implementation**
   - LOC estimate increases significantly
   - Complexity increases substantially
   - Add higher-level templates to same folder
   - Document level change in changelog

2. **Uncertainty about level selection (confidence <80%)**
   - Present level options to user
   - Explain trade-offs
   - Default to higher level if user unsure

3. **Template doesn't fit feature requirements**
   - Use closest template as starting point
   - Adapt structure to fit
   - Document modifications
   - Consider creating custom template for future use

4. **User requests to skip documentation (Option D)**
   - Warn about technical debt implications
   - Explain future debugging challenges
   - Confirm explicit consent
   - Log skip event for audit trail

---

## 6. ✅ SUCCESS CRITERIA

### Documentation Created

- [ ] Spec folder exists at `specs/###-short-name/`
- [ ] Folder name follows convention (2-3 words, lowercase, hyphen-separated)
- [ ] Number is sequential (no gaps or duplicates)
- [ ] Correct level templates copied and renamed
- [ ] All placeholders replaced with actual content
- [ ] Sample content removed
- [ ] Supporting templates added if needed

### Template Quality

- [ ] Templates copied from `.opencode/speckit/templates/` (not created from scratch)
- [ ] Template structure preserved (numbered H2 sections with emojis)
- [ ] Metadata block filled correctly
- [ ] All sections relevant (N/A stated if not applicable)
- [ ] Cross-references to sibling documents (spec.md ↔ plan.md ↔ tasks.md)

### User Approval

- [ ] Documentation level presented to user
- [ ] Spec folder path shown
- [ ] Templates used listed
- [ ] Implementation approach explained
- [ ] Explicit "yes/go ahead/proceed" received before file changes

### Hook Compliance

- [ ] Responded to hook confirmation prompt (if displayed)
- [ ] Asked user for A/B/C/D choice
- [ ] Documented user's choice
- [ ] Created skip marker if Option D selected

### Context Preservation

- [ ] Context auto-saved to `specs/###/memory/` (every 20 messages)
- [ ] Manual saves triggered when appropriate ("save context")
- [ ] Conversation history preserved for debugging
- [ ] Implementation decisions documented

---

## 7. 🔗 INTEGRATION POINTS

### Related Skills

**Upstream (feeds into this skill):**
- None - This is the foundational workflow for all implementation conversations

**Downstream (uses this skill's outputs):**
- **workflows-code** → Uses spec folders for implementation tracking
- **workflows-git** → References spec folders in commit messages and PRs
- **create-documentation** → Validates spec folder documentation quality
- **save-context** → Saves conversation context to spec folder memory/

### Cross-Skill Workflows

**Spec Folder → Implementation Workflow:**
1. `workflows-conversation` creates spec folder
2. `workflows-code` implements from spec + plan
3. `workflows-git` commits with spec reference
4. `save-context` preserves conversation to spec/memory/

**Documentation Quality Workflow:**
1. `workflows-conversation` creates spec documentation
2. `create-documentation` validates structure and quality scores
3. Feedback loop: Iterate on documentation if scores <90

### External Dependencies

- `.opencode/speckit/templates/` - All template files
- `.claude/hooks/UserPromptSubmit/enforce-spec-folder.sh` - Hook enforcement
- `.claude/hooks/UserPromptSubmit/save-context-trigger.sh` - Context auto-save
- `/speckit.specify` - Level 3 auto-generation command

### Skill Maintenance

**Version**: 1.0.0
**Last Updated**: 2025-11-23
**Maintainer**: Engineering Team
**Update Frequency**: As needed when template system changes

**Change Log:**
- 2025-11-23: Initial skill creation from conversation_documentation.md knowledge base
- Converted from knowledge base to skill for better integration and discoverability
- Added standardized structure: navigation guide, references section, routing diagram
- Organized content into bundled resources (assets/ and references/)

---

**Remember**: This skill operates as the foundational documentation orchestrator. It enforces structure, template usage, and context preservation for all file modifications.