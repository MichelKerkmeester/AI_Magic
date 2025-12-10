---
name: workflows-spec-kit
description: Mandatory spec folder workflow orchestrating documentation level selection (1-3), template selection, and folder creation for all file modifications through hook-assisted enforcement and context auto-save.
allowed-tools: ["*"]
version: 1.0.1
---

<!-- Keywords: spec-kit, speckit, documentation-workflow, spec-folder, template-enforcement, context-preservation, hook-automation, progressive-documentation -->

# 🗂️ Conversation Documentation Workflow - Mandatory Spec Folder System & Template Enforcement

Orchestrates mandatory spec folder creation for all conversations involving file modifications. This skill ensures proper documentation level selection (1-3), template usage, and context preservation through automated workflows and hook-assisted enforcement.

---

## 1. 🎯 WHEN TO USE

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

## 2. 🧭 SMART ROUTING & REFERENCES

### Command Entry Points
```
/spec_kit:[command] [args]
    │
    ├─► :plan [feature] [:auto|:confirm]
    │   └─► PLAN WORKFLOW: Spec through plan only (7 steps)
    │
    ├─► :research [topic] [:auto|:confirm]
    │   └─► RESEARCH WORKFLOW: Technical investigation (9 steps)
    │
    ├─► :implement <spec-folder> [:auto|:confirm]
    │   └─► IMPLEMENT WORKFLOW: Execute pre-planned work (8 steps)
    │
    ├─► :complete [feature] [:auto|:confirm]
    │   └─► COMPLETE WORKFLOW: Full end-to-end (12 steps)
    │
    └─► :resume [spec-folder]
        └─► RESUME: Continue existing spec work
```

### Level Selection (Auto-detected)
```
ESTIMATED LOC
    │
    ├─► <100 LOC (simple change)
    │   └─► Level 1: spec.md + plan.md + tasks.md
    │
    ├─► 100-499 LOC (standard feature)
    │   └─► Level 2: + research.md + checklist.md
    │
    └─► ≥500 LOC (complex system)
        └─► Level 3: + decision-record.md + architecture diagrams
```

### Resource Router
```python
def route_conversation_resources(task):
    """
    Progressive Enhancement Model:
    - Level 1 (Baseline):     spec.md + plan.md + tasks.md
    - Level 2 (Verification): Level 1 + checklist.md
    - Level 3 (Full):         Level 2 + decision-record.md + optional research.md/research-spike.md

    Utility Templates (any level):
    - handover.md        → Session continuity for multi-session work
    - debug-delegation.md → Sub-agent debugging task delegation

    LOC thresholds are SOFT GUIDANCE (not enforcement):
    - <100 LOC suggests Level 1
    - 100-499 LOC suggests Level 2
    - ≥500 LOC suggests Level 3

    Enforcement is HARD - hooks block commits with missing required templates.
    """

    # ══════════════════════════════════════════════════════════════════════
    # TEMPLATES (9 files in .opencode/speckit/templates/)
    # ══════════════════════════════════════════════════════════════════════

    # ──────────────────────────────────────────────────────────────────
    # Level 1: Baseline (all tasks start here)
    # Purpose: Required: spec.md + plan.md + tasks.md
    # Key Insight: All features start here - minimum documentation for any work
    # ──────────────────────────────────────────────────────────────────
    load("templates/spec.md")
    load("templates/plan.md")
    load("templates/tasks.md")

    # ──────────────────────────────────────────────────────────────────
    # Level 2: Add verification (QA validation needed)
    # Purpose: Required: Level 1 + checklist.md
    # Key Insight: Features needing systematic QA validation
    # ──────────────────────────────────────────────────────────────────
    if task.needs_qa_validation or task.estimated_loc >= 100:
        load("templates/checklist.md")

    # ──────────────────────────────────────────────────────────────────
    # Level 3: Full documentation (complex/architectural)
    # Purpose: Required: Level 2 + decision-record.md; Optional: research.md, research-spike.md
    # Key Insight: Complex features, architecture changes, major decisions
    # ──────────────────────────────────────────────────────────────────
    if task.is_complex or task.has_arch_impact or task.estimated_loc >= 500:
        load("templates/decision-record.md")
        if task.needs_research:
            load("templates/research.md")          # Comprehensive research
            load("templates/research-spike.md")    # Time-boxed PoC

    # ──────────────────────────────────────────────────────────────────
    # Utility Templates (any level)
    # Purpose: Session continuity and sub-agent debugging
    # Key Insight: Available at ANY level for multi-session or debugging needs
    # ──────────────────────────────────────────────────────────────────
    if task.is_multi_session:
        load("templates/handover.md")              # Session continuity
    if task.needs_debug_delegation:
        load("templates/debug-delegation.md")      # Sub-agent debugging

    # ══════════════════════════════════════════════════════════════════════
    # ASSETS (2 files in ./assets/) - Decision support tools
    # ══════════════════════════════════════════════════════════════════════

    # ──────────────────────────────────────────────────────────────────
    # Level Decision Matrix
    # Purpose: LOC thresholds and decision factors
    # Key Insight: LOC is soft guidance; progressive enhancement model
    # ──────────────────────────────────────────────────────────────────
    load("assets/level_decision_matrix.md")

    # ──────────────────────────────────────────────────────────────────
    # Template Mapping
    # Purpose: Template-to-level mapping with copy commands
    # Key Insight: Always copy from .opencode/speckit/templates/ - never freehand
    # ──────────────────────────────────────────────────────────────────
    load("assets/template_mapping.md")

    # ══════════════════════════════════════════════════════════════════════
    # REFERENCES (4 files in ./references/) - Detailed documentation
    # ══════════════════════════════════════════════════════════════════════

    # ──────────────────────────────────────────────────────────────────
    # Level Specifications
    # Purpose: Complete Level 1-3 specifications
    # Key Insight: Progressive enhancement: each level builds on previous
    # ──────────────────────────────────────────────────────────────────
    load("references/level_specifications.md")

    # ──────────────────────────────────────────────────────────────────
    # Template Guide
    # Purpose: Template selection and adaptation rules
    # Key Insight: Fill ALL placeholders, remove sample content
    # ──────────────────────────────────────────────────────────────────
    load("references/template_guide.md")

    # ──────────────────────────────────────────────────────────────────
    # Automation Workflows
    # Purpose: Hook enforcement and context auto-save
    # Key Insight: Hard enforcement - hooks block commits with missing files
    # ──────────────────────────────────────────────────────────────────
    load("references/automation_workflows.md")

    # ──────────────────────────────────────────────────────────────────
    # Quick Reference
    # Purpose: Commands, checklists, troubleshooting
    # Key Insight: Pre-implementation checklist is mandatory
    # ──────────────────────────────────────────────────────────────────
    load("references/quick_reference.md")

    # Overrides: High risk OR arch impact OR >5 files → bump to higher level
    # Enforcement: Hard block - hooks prevent commits with missing files
    # Rule: When in doubt → choose higher level

# ══════════════════════════════════════════════════════════════════════
# STATIC RESOURCES (always available, not conditionally loaded)
# ══════════════════════════════════════════════════════════════════════
# .opencode/speckit/templates/ → 9 template files (source of truth)

# SUMMARY: 15 total documents
# - 9 templates in: .opencode/speckit/templates/
# - 2 assets in:    ./assets/
# - 4 references in: ./references/
```

---

## 3. ⚙️ HOW IT WORKS

### 3-Level Progressive Enhancement Framework

The documentation system uses progressive enhancement where each level builds on the previous. See Smart Router (Section 2) for complete template routing and LOC thresholds.

**Level 1: Baseline Documentation** (LOC guidance: <100)
- **Required Files**: `spec.md` + `plan.md` + `tasks.md`
- **Optional Files**: None (baseline is complete)
- **Use When**: All features - this is the minimum documentation for any work
- **Enforcement**: Hard block if any required file missing
- **Example**: Add email validation, fix bug, loading spinner, typo fix

**Level 2: Verification Added** (LOC guidance: 100-499)
- **Required Files**: Level 1 + `checklist.md`
- **Optional Files**: None
- **Use When**: Features needing systematic QA validation
- **Enforcement**: Hard block if `checklist.md` missing
- **Example**: Modal component, auth flow, library migration

> **CRITICAL: Checklist as Active Verification Tool**
>
> The `checklist.md` is NOT just documentation - it is an **ACTIVE VERIFICATION TOOL** that the AI MUST use to verify its own work before claiming completion. The checklist serves as:
> - A systematic verification protocol (not a passive record)
> - An evidence-based completion gate (must mark items with proof)
> - A priority-driven blocker (P0/P1 items MUST pass before done)
>
> See Section 5 (RULES) for mandatory checklist verification requirements.

**Level 3: Full Documentation** (LOC guidance: ≥500)
- **Required Files**: Level 2 + `decision-record.md`
- **Optional Files**: `research-spike.md`, `research.md`
- **Use When**: Complex features, architecture changes, major decisions
- **Enforcement**: Hard block if `decision-record.md` missing
- **Example**: Major feature, system redesign, multi-team projects


### Secondary Factors (Can Override LOC)

LOC thresholds are **SOFT GUIDANCE** - these factors can push to higher level:

- **Complexity**: Architectural changes vs simple refactors
- **Risk**: Config cascades, authentication, security implications
- **Dependencies**: Multiple systems affected (>5 files suggests higher level)
- **Testing needs**: Integration vs unit test requirements

**Decision rules**:
- **When in doubt → choose higher level** (better to over-document than under-document)
- **Risk/complexity can override LOC** (e.g., 50 LOC security change = Level 2+)
- **Multi-file changes often need higher level** than LOC alone suggests
- **Enforcement is HARD** - hooks block commits with missing required templates


### Folder Naming Convention

**Format**: `specs/###-short-name/`

**Rules**:
- 2-3 words (shorter is better)
- Lowercase
- Hyphen-separated
- Action-noun structure
- 3-digit padding: `001`, `042`, `099` (no padding past 999)

**Good examples**: `fix-typo`, `add-auth`, `mcp-code-mode`

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

**`workflows-memory-trigger.sh` hook behavior:**
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
- `workflows-memory` reads `.spec-active` marker
- Writes to active sub-folder's `memory/` directory
- Each iteration has isolated conversation history
- Root `memory/` preserved for legacy saves (backward compatibility)

**Example Use Case:**
```
Scenario: Working on skill standardization across multiple skills

Initial work: specs/122-skill-standardization/
  └── (root files: spec.md, plan.md, etc.)

User: "Work on devtools alignment"
System: Creates → 001-devtools-alignment/ sub-folder

User: "Now work on workflows-spec-kit alignment"
System: Archives to 002-devtools-alignment/
System: Creates → 003-workflows-spec-kit-alignment/ sub-folder

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

## 4. 📋 RULES

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

8. **ALWAYS use checklist.md to verify work before completion (Level 2+)**
   - Load checklist.md at completion phase
   - Verify each item systematically (P0 first, then P1, then P2)
   - Cannot claim "done" until checklist verification complete

9. **ALWAYS mark checklist items [x] with evidence when verified**
   - Include links to files, test outputs, or screenshots
   - Document how each item was verified
   - Update checklist.md with verification timestamps

10. **ALWAYS complete all P0 and P1 items before claiming done**
    - P0 = Blocker: MUST pass or work is incomplete
    - P1 = Required: MUST pass for production readiness
    - P2 = Optional: Can defer with documented reason

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

6. **NEVER claim completion without verifying checklist.md items (Level 2+)**
   - Must load and review checklist.md before stating work is done
   - Must mark all P0/P1 items as verified with evidence
   - Incomplete checklist = incomplete work

7. **NEVER proceed without hook confirmation response**
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

## 5. ✅ SUCCESS CRITERIA

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

### Checklist Verification (Level 2+)

- [ ] Loaded `checklist.md` before claiming completion
- [ ] Verified items in priority order (P0 → P1 → P2)
- [ ] All P0 items marked [x] with evidence
- [ ] All P1 items marked [x] with evidence
- [ ] P2 items either verified or deferred with documented reason
- [ ] Updated `checklist.md` with verification timestamps
- [ ] No unchecked P0/P1 items remain

---

## 6. 🔗 INTEGRATION POINTS

### CAPS Integration (Context-Aware Permission System)

SpecKit integrates with CAPS for validation and enforcement through hook-assisted rules.

**CAPS Components Used:**
| Component              | Purpose                                   | Location             |
| ---------------------- | ----------------------------------------- | -------------------- |
| `context-inference.sh` | Core CAPS engine (v1.0.0)                 | `.claude/hooks/lib/` |
| `caps-adapter.sh`      | Adapter bridging operations to CAPS rules | `.claude/hooks/lib/` |
| `rule-evaluation.sh`   | Rule priority evaluation (P0/P1/P2)       | `.claude/hooks/lib/` |
| `speckit-state.sh`     | SpecKit state management with CAPS        | `.claude/hooks/lib/` |

**Enforcement Levels (CAPS Priority System):**
- **P0 (Blocker)**: Hard block - cannot proceed without resolution
  - Missing required templates for level (e.g., no `checklist.md` for Level 2)
  - Unresolved placeholders in templates (`[PLACEHOLDER]`)
- **P1 (Warning)**: Must address or explicitly defer with user approval
  - Incomplete checklist items before completion claims
  - Missing optional templates for level
- **P2 (Optional)**: Can defer without approval
  - Documentation enhancements
  - Additional context preservation

**CAPS Functions Available:**
```bash
# Validate operations via CAPS rules
result=$(validate_agent_via_caps "$context_json")

# Context inference for permission decisions
context=$(infer_context "$prompt_text")

# Rule evaluation with priority
rules=$(evaluate_rules "$context_json")
```

**SpecKit-Specific CAPS Triggers:**
- `enforce-spec-folder.sh` → Validates spec folder existence and template completeness
- `workflows-memory-trigger.sh` → Triggers context preservation at 20-message intervals
- Template validation → Checks placeholder removal and required field completion

### Related Skills

**Upstream (feeds into this skill):**
- None - This is the foundational workflow for all implementation conversations

**Downstream (uses this skill's outputs):**
- **workflows-code** → Uses spec folders for implementation tracking
- **workflows-git** → References spec folders in commit messages and PRs
- **create-documentation** → Validates spec folder documentation quality
- **workflows-memory** → Saves conversation context to spec folder memory/

### Cross-Skill Workflows

**Spec Folder → Implementation Workflow:**
1. `workflows-spec-kit` creates spec folder
2. `workflows-code` implements from spec + plan
3. `workflows-git` commits with spec reference
4. `workflows-memory` preserves conversation to spec/memory/

**Documentation Quality Workflow:**
1. `workflows-spec-kit` creates spec documentation
2. `create-documentation` validates structure and quality scores
3. Feedback loop: Iterate on documentation if scores <90

### External Dependencies

- `.opencode/speckit/templates/` - All template files
- `.claude/hooks/UserPromptSubmit/enforce-spec-folder.sh` - Hook enforcement
- `.claude/hooks/UserPromptSubmit/workflows-memory-trigger.sh` - Context auto-save
- `/spec_kit:complete` - Level 3 auto-generation command

---

**Remember**: This skill operates as the foundational documentation orchestrator. It enforces structure, template usage, and context preservation for all file modifications.