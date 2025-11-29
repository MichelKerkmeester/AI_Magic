# 🗂️ Template Mapping - Template-to-Level Guide with Copy Commands

Complete mapping of documentation levels to templates with copy commands and file structure examples. Use this guide to identify which templates to copy for each documentation level and see exact folder structure patterns.

---

## 1. 📍 TEMPLATE LOCATION

**All templates located in:** `.claude/commands/spec_kit/assets/templates/`

**Critical Rule:** ALWAYS copy templates from this directory - NEVER create documentation files from scratch.

---

## 2. 📋 CORE TEMPLATES BY LEVEL

| Level | Template File | Copy As | Copy Command |
|-------|--------------|---------|--------------|
| **1: Simple** | `spec_template.md` | `spec.md` | `cp .claude/commands/spec_kit/assets/templates/spec_template.md specs/###-name/spec.md` |
| **2: Moderate** | `spec_template.md`<br>`plan_template.md` | `spec.md`<br>`plan.md` | `cp .claude/commands/spec_kit/assets/templates/spec_template.md specs/###-name/spec.md`<br>`cp .claude/commands/spec_kit/assets/templates/plan_template.md specs/###-name/plan.md` |
| **3: Complex** | SpecKit auto-generates | Multiple files | `/spec_kit:complete` command |

---

## 3. 📦 SUPPORTING TEMPLATES (OPTIONAL)

Additional templates for specific needs - use descriptive names:

| Template File | Copy As | When to Use | Copy Command |
|--------------|---------|-------------|--------------|
| `tasks_template.md` | `tasks.md` | After plan.md, before coding - breaks plan into actionable tasks | `cp .claude/commands/spec_kit/assets/templates/tasks_template.md specs/###-name/tasks.md` |
| `checklist_template.md` | `checklist.md` | When systematic validation needed (QA, security, deployment) | `cp .claude/commands/spec_kit/assets/templates/checklist_template.md specs/###-name/checklist.md` |
| `decision_record_template.md` | `decision-record-[topic].md` | Major technical decisions (database choice, architecture) | `cp .claude/commands/spec_kit/assets/templates/decision_record_template.md specs/###-name/decision-record-database.md` |
| `research_spike_template.md` | `research-spike-[topic].md` | Before uncertain work - research, POC, feasibility | `cp .claude/commands/spec_kit/assets/templates/research_spike_template.md specs/###-name/research-spike-performance.md` |

**Notes:**
- Use descriptive names for decision records and research-spikes (not generic "final" or "new")
- Multiple decision records/research-spikes can exist per spec folder
- Only copy when explicitly needed (not mandatory)

---

## 4. 🗂️ FOLDER STRUCTURE BY LEVEL

### Level 1: Simple Changes

```
specs/043-add-email-validation/
├── spec.md                      (from spec_template.md)
└── checklist.md                 (optional, from checklist_template.md)
```

**Content expectations:**
- Problem statement or feature description
- Proposed solution
- Files to change
- Testing approach
- Success criteria

---

### Level 2: Moderate Features

```
specs/044-modal-component/
├── spec.md                      (from spec_template.md)
├── plan.md                      (from plan_template.md)
├── tasks.md                     (optional, from tasks_template.md)
├── checklist.md                 (optional, from checklist_template.md)
├── research-spike-animation-perf.md (optional, from research_spike_template.md)
└── decision-record-library.md   (optional, from decision_record_template.md)
```

**spec.md expectations:**
- Detailed requirements
- Technical approach
- Alternatives considered
- Success criteria
- Risks and mitigations

**plan.md expectations:**
- Implementation steps (ordered)
- File changes breakdown
- Testing strategy
- Rollout plan
- Dependencies

---

### Level 3: Complex Features

```
specs/045-user-dashboard/
├── spec.md                      (SpecKit auto-generated)
├── plan.md                      (SpecKit auto-generated)
├── tasks.md                     (SpecKit auto-generated)
├── research.md                  (SpecKit auto-generated)
├── data-model.md                (SpecKit auto-generated)
├── quickstart.md                (SpecKit auto-generated)
├── contracts/                   (SpecKit auto-generated)
└── checklist.md                 (optional, manual copy)
```

**Process:** Use `/spec_kit:complete` command - it auto-generates all core files.

**Optional files:** Copy manually from templates if needed.

---

## 5. 📐 TEMPLATE STRUCTURE REQUIREMENTS

All templates follow consistent structure:

### 1. Numbered H2 Sections

**Format:** `## N. EMOJI TITLE`

**Example:** `## 3. 🛠️ IMPLEMENTATION`

**Rules:**
- Keep numbering sequential
- Never remove emojis (visual scanning pattern)
- Maintain consistent formatting

### 2. Metadata Block

First section sets expectations:

**Level 1:** Metadata + Complexity + Success Criteria

**Level 2/3:** Category, Tags, Priority, Status

### 3. Placeholder Conventions

- `[PLACEHOLDER]` - Must be replaced with actual content
- `[NEEDS CLARIFICATION: ...]` - Unknown requirement (flag for user)
- `<!-- SAMPLE CONTENT -->` - Remove before delivery

### 4. Template Footer

Accountability reminder (remove after filling):

```html
<!--
  REPLACE SAMPLE CONTENT IN FINAL OUTPUT
  - This template contains placeholders and examples
  - Replace them with actual content
-->
```

---

## 6. ✅ TEMPLATE ADHERENCE RULES

**Non-negotiable rules:**

1. **Always copy from `.claude/commands/spec_kit/assets/templates/`** - Never freehand documentation
2. **Preserve numbering and emojis** - Maintain visual scanning pattern
3. **Fill every placeholder** - Replace `[PLACEHOLDER]` with actual content
4. **Remove instructional comments** - Delete `<!-- SAMPLE -->` blocks
5. **Use descriptive filenames** - `decision-record-[topic].md`, not `decision-record-final.md`
6. **Keep sections relevant** - State "N/A" instead of deleting sections
7. **Link sibling documents** - Cross-reference spec.md ↔ plan.md ↔ tasks.md
8. **Document level changes** - Note upgrades/downgrades in changelog
9. **Keep history immutable** - Append to history, don't rewrite
10. **Validate before coding** - Complete pre-implementation checklist first

---

## 7. 🎯 STEP-BY-STEP TEMPLATE USAGE

### Step 1: Determine Level
Use decision matrix (LOC + complexity factors)

### Step 2: Find Next Number
```bash
ls -d specs/[0-9]*/ | sed 's/.*\/\([0-9]*\)-.*/\1/' | sort -n | tail -1
```
Add 1 to get next number.

### Step 3: Create Folder
```bash
mkdir -p specs/###-short-name/
```

### Step 4: Copy Core Templates

**Level 1:**
```bash
cp .claude/commands/spec_kit/assets/templates/spec_template.md specs/###-name/spec.md
```

**Level 2:**
```bash
cp .claude/commands/spec_kit/assets/templates/spec_template.md specs/###-name/spec.md
cp .claude/commands/spec_kit/assets/templates/plan_template.md specs/###-name/plan.md
```

**Level 3:**
```bash
/spec_kit:complete
```

### Step 5: Copy Supporting Templates (If Needed)

```bash
# Tasks (after plan, before coding)
cp .claude/commands/spec_kit/assets/templates/tasks_template.md specs/###-name/tasks.md

# Checklist (validation needs)
cp .claude/commands/spec_kit/assets/templates/checklist_template.md specs/###-name/checklist.md

# Decision Record (use descriptive name)
cp .claude/commands/spec_kit/assets/templates/decision_record_template.md specs/###-name/decision-record-database.md

# Research-Spike (use descriptive name)
cp .claude/commands/spec_kit/assets/templates/research_spike_template.md specs/###-name/research-spike-performance.md
```

### Step 6: Fill Templates
- Replace ALL `[PLACEHOLDER]` text
- Remove sample/example sections
- Adapt to specific feature
- Remove instructional comments

### Step 7: Present to User
- Show level chosen
- Show folder path
- Show which templates used
- Explain approach

### Step 8: Wait for Approval
Get explicit "yes/go ahead/proceed" before ANY file changes.
