# SpecKit - Spec-Driven Development Framework

**Location**: `.opencode/speckit/` (single source of truth - no duplicates)

#### 📋 TABLE OF CONTENTS

1. [📖 OVERVIEW](#1--overview) - What SpecKit provides and key concepts
2. [🗂️ DIRECTORY STRUCTURE](#2-️-directory-structure) - File organization and layout
3. [📝 TEMPLATES](#3--templates) - 7 templates with usage guides
4. [🔧 SCRIPTS](#4--scripts) - 5 automation scripts
5. [💡 USAGE EXAMPLES](#5--usage-examples) - Common workflows and patterns
6. [🔗 INTEGRATION](#6--integration) - How SpecKit connects to commands/hooks/skills
7. [🛠️ MAINTENANCE](#7-️-maintenance) - Adding and modifying components
8. [📖 QUICK REFERENCE](#8--quick-reference) - Consolidated navigation and guides
9. [❓ TROUBLESHOOTING](#9--troubleshooting) - Common issues and solutions
10. [💬 FAQ](#10--faq) - Frequently asked questions
11. [🔄 RECENT UPDATES](#11--recent-updates) - Changelog and version history

---

## 1. 📖 OVERVIEW

### What is SpecKit?

**SpecKit** is a comprehensive spec-driven development framework that provides structured templates, automation scripts, and workflow commands to manage feature specifications from planning through implementation.

| Stat | Count | Description |
|------|-------|-------------|
| Templates | 7 | Markdown templates for specs, plans, research, decisions |
| Scripts | 5 | Shell scripts for automation and validation |
| Commands | 4 | Slash commands for workflow execution |

### SpecKit vs Commands vs Hooks

| Component | Purpose | Execution | Location |
|-----------|---------|-----------|----------|
| **SpecKit** | Template & workflow management | User-invoked or AI-triggered | `.opencode/speckit/` |
| **Commands** | SpecKit workflow execution | Slash commands (`/spec_kit:*`) | `.claude/commands/` |
| **Hooks** | Automated enforcement | System-triggered on events | `.claude/hooks/` |

### Key Features

**Template Management**:
- 7 structured templates for documentation levels 1-3
- Placeholder system with validation enforcement
- Template source markers for traceability

**Workflow Automation**:
- Auto-create feature branches and spec folders
- Prerequisite checking and validation
- Completeness scoring for spec folders

**Quality Enforcement**:
- Integration with `enforce-spec-folder.sh` hook
- Template adaptation validation
- Cross-reference checking

**Integration Points**:
- Commands: `/spec_kit:complete`, `/spec_kit:plan`, `/spec_kit:implement`, `/spec_kit:research`
- Skills: `workflows-spec-kit`, `create-documentation`
- Hooks: `enforce-spec-folder.sh`

---

## 2. 🗂️ DIRECTORY STRUCTURE

```
.opencode/speckit/
├── templates/              # 7 markdown templates
│   ├── spec.md
│   ├── plan.md
│   ├── tasks.md
│   ├── checklist.md
│   ├── research.md         # Comprehensive feature research
│   ├── research-spike.md   # Time-boxed technical research
│   └── decision-record.md
└── scripts/                # 4 shell scripts
    ├── common.sh                     # Shared utility functions
    ├── create-new-feature.sh         # Create feature branch & spec folder
    ├── check-prerequisites.sh        # Validate spec folder structure
    ├── calculate-completeness.sh     # Calculate spec folder completeness percentage
    └── setup-plan.sh                 # Copy plan template
```

---

## 3. 📝 TEMPLATES

### 3.1 Core Templates

#### `spec.md`

**Purpose**: Complete feature specification with user stories, acceptance criteria, and technical requirements

**Key Sections**:
- Objective & metadata (category, priority, status)
- Scope (in/out of scope)
- User stories with acceptance scenarios
- Functional & non-functional requirements
- Edge cases, success criteria, dependencies

**When to Use**:
- Level 1-3 features (any significant change)
- New feature specifications
- Substantial bug fix documentation

**When NOT to Use**:
- Research-only work (use `research.md`)

**Integration**: Commands `/spec_kit:complete`, `/spec_kit:plan` | Hook `enforce-spec-folder.sh`

---

#### `plan.md`

**Purpose**: Implementation plan with architecture decisions, technical approach, and execution phases

**Key Sections**:
- Technical approach & architecture
- Implementation phases with milestones
- Testing strategy & quality gates
- Risk assessment & rollback plan
- Resource requirements

**When to Use**:
- Level 2-3 features requiring architectural planning
- After spec.md is approved
- Complex implementations with multiple phases

**When NOT to Use**:
- Never skip - plan.md is REQUIRED for all levels (Level 1+)
- Before requirements are clear (do spec first)

**Integration**: Commands `/spec_kit:complete`, `/spec_kit:plan` | Skill `workflows-spec-kit`

---

### 3.2 Research Templates

#### `research.md`

**Purpose**: Comprehensive technical research spanning multiple domains (architecture, integration, security, performance)

**Key Sections** (17 total):
- Project context & research scope
- Technical foundations & architecture analysis
- Integration patterns & data flow
- API/SDK documentation review
- Security & performance considerations
- Implementation recommendations

**When to Use**:
- Deep technical investigation before implementation
- Complex features spanning multiple technical areas
- Evaluating multiple solution approaches

**When NOT to Use**:
- Quick feasibility checks (use `research-spike.md`)
- Already know the technical approach

**Integration**: Command `/spec_kit:research` | Workflow path: research → plan → implement

---

#### `research-spike.md`

**Purpose**: Time-boxed technical investigation to answer specific questions or validate approaches

**Key Sections**:
- Research question & hypothesis
- Time box (recommended: 2-4 hours)
- Experiment design & success criteria
- Findings & recommendations
- Decision: proceed, pivot, or abandon

**When to Use**:
- Proof-of-concept validation
- Evaluating specific library or API
- Answering targeted technical questions

**When NOT to Use**:
- Comprehensive multi-domain research (use `research.md`)
- Already validated approaches

**Integration**: Command `/spec_kit:research` | Often followed by decision record

---

### 3.3 Supporting Templates

#### `tasks.md`

**Purpose**: Break implementation plan into actionable, trackable tasks

**Key Sections**:
- Task list with priorities and estimates
- Dependencies between tasks
- Assignment and status tracking
- Completion criteria per task

**When to Use**:
- After plan.md is complete, before coding
- Level 2-3 features with multiple implementation steps
- Team coordination on complex features

**Integration**: Command `/spec_kit:implement` | Skill `workflows-spec-kit`

---

#### `checklist.md`

**Purpose**: Systematic validation and QA procedures

**Key Sections**:
- Pre-implementation checklist
- Implementation verification
- Testing checklist
- Documentation completeness
- Deployment readiness

**When to Use**:
- Systematic validation is needed
- Complex features with many verification steps
- Team handoffs or reviews

**Integration**: All SpecKit commands (validation phase)

---

#### `decision-record.md`

**Purpose**: Architecture Decision Records (ADRs) for documenting major technical decisions

**Key Sections**:
- Decision title and status
- Context and problem statement
- Options considered with pros/cons
- Decision outcome and rationale
- Consequences and follow-up actions

**When to Use**:
- Major architectural decisions
- Technology or library selection
- Significant design trade-offs

**Integration**: Command `/spec_kit:research` | Often follows research spike

---


## 4. 🔧 SCRIPTS

### 4.1 `common.sh`

**Purpose**: Shared utility functions used by all other SpecKit scripts

**Functions**:
| Function | Description |
|----------|-------------|
| `get_repo_root()` | Find git repository root directory |
| `get_current_branch()` | Get current git branch name |
| `get_feature_paths()` | Resolve all feature-related paths |
| `check_feature_branch()` | Validate branch follows naming convention |

**Usage**: Sourced by other scripts, not called directly

---

### 4.2 `create-new-feature.sh`

**Purpose**: Create new feature branch and spec folder with proper numbering

**Triggers**:
- Manual: User runs from terminal
- Commands: `/spec_kit:complete` (auto-create mode)

**Options**:
| Flag | Description | Default |
|------|-------------|---------|
| `--json` | Output in JSON format | false |
| `--short-name <name>` | Custom feature name (2-4 words) | auto-generated |
| `--number N` | Specify feature number | auto-increment |

**Example**:
```bash
$ .opencode/speckit/scripts/create-new-feature.sh "Add user authentication"

✅ Feature created:
   Branch: 042-user-authentication
   Folder: specs/042-user-authentication/
   File:   specs/042-user-authentication/spec.md
```

**Auto-Create Logic**:
1. Find next number: `ls -d specs/[0-9]*/ | sort -n | tail -1` + 1
2. Create folder: `specs/{NNN}-{feature-name}/`
3. Handle collisions: Increment until unique
4. Create branch: `feature-{NNN}-{short-name}`

**Exit Codes**: `0` = Success | `1` = Invalid arguments | `2` = Git error

**Performance**: ~100ms typical

---

### 4.3 `check-prerequisites.sh`

**Purpose**: Validate spec folder structure and list available documentation

**Triggers**:
- Manual: Pre-implementation verification
- Commands: `/spec_kit:implement` (prerequisite check)

**Options**:
| Flag | Description | Default |
|------|-------------|---------|
| `--json` | Output in JSON format | false |
| `--require-tasks` | Require tasks.md exists | false |
| `--include-tasks` | Include tasks.md in output | false |
| `--paths-only` | Output paths without validation | false |

**Example**:
```bash
$ .opencode/speckit/scripts/check-prerequisites.sh

FEATURE_DIR: specs/042-user-auth
AVAILABLE_DOCS:
  ✓ spec.md
  ✓ plan.md
  ✗ tasks.md
  ✗ research.md
```

**Exit Codes**: `0` = All prerequisites met | `1` = Missing required files | `2` = No spec folder found

**Performance**: ~50ms typical

---

### 4.4 `calculate-completeness.sh`

**Purpose**: Calculate spec folder completeness percentage for quality assessment

**Triggers**:
- Manual: Quality check before implementation
- Hooks: Quality validation

**Usage**:
```bash
.opencode/speckit/scripts/calculate-completeness.sh /path/to/spec/folder
```

**What It Checks**:
| Check | Weight | Description |
|-------|--------|-------------|
| Required files | 30% | spec.md, plan.md exist |
| Placeholders | 25% | All `[YOUR_VALUE_HERE]` replaced |
| Content quality | 20% | Minimum word counts met |
| Cross-references | 15% | Files reference each other |
| Metadata | 10% | Status, priority, dates filled |

**Example Output**:
```bash
$ .opencode/speckit/scripts/calculate-completeness.sh specs/042-user-auth

Completeness Score: 75%

Missing:
  - tasks.md not created
  - 2 placeholders in spec.md
  - Cross-references incomplete

Recommendations:
  - Create tasks.md from plan
  - Fill remaining placeholders
```

**Exit Codes**: `0` = 80%+ complete | `1` = Below 80% | `2` = Spec folder not found

**Performance**: ~200ms (file parsing)

---

### 4.5 `setup-plan.sh`

**Purpose**: Copy plan template to current feature folder

**Triggers**:
- Manual: After spec.md is created
- Commands: `/spec_kit:plan`

**Options**:
| Flag | Description | Default |
|------|-------------|---------|
| `--json` | Output in JSON format | false |

**Example**:
```bash
$ .opencode/speckit/scripts/setup-plan.sh

✅ Plan template copied to: specs/042-user-auth/plan.md
```

**Exit Codes**: `0` = Success | `1` = No feature folder | `2` = Template not found

**Performance**: ~30ms

---

## 5. 💡 USAGE EXAMPLES

### Creating a New Feature

```bash
# Generate feature branch and spec folder
./speckit/scripts/create-new-feature.sh "Add user authentication system"

# Result:
# - Branch: 042-user-authentication-system
# - Folder: specs/042-user-authentication-system/
# - File: specs/042-user-authentication-system/spec.md
```

### Using Templates

```bash
# Copy research template for comprehensive investigation
cp .opencode/speckit/templates/research.md specs/042-feature/research.md

# Copy research-spike template for time-boxed experiment
cp .opencode/speckit/templates/research-spike.md specs/042-feature/research-spike-auth-library.md

# Copy decision record for technical decisions
cp .opencode/speckit/templates/decision-record.md specs/042-feature/decision-record-database.md
```

### Checking Prerequisites

```bash
# Validate spec folder has required files
./speckit/scripts/check-prerequisites.sh

# Output example:
# FEATURE_DIR: specs/042-user-auth
# AVAILABLE_DOCS:
#   ✓ research.md
#   ✗ data-model.md
#   ✗ contracts/
```

### Checking Completeness

```bash
# Calculate spec folder completeness
./speckit/scripts/calculate-completeness.sh specs/042-user-auth

# Output example:
# Completeness Score: 75%
# Missing:
#   - tasks.md not created
#   - Placeholders in spec.md (2 found)
#   - Cross-references incomplete
```

---

## 6. 🔗 INTEGRATION

### With SpecKit Commands

SpecKit commands (`.opencode/command/speckit_*.md`) provide 4 core workflows:

| Command | Steps | Purpose | Key Templates |
|---------|-------|---------|---------------|
| `/spec_kit:complete` | 12 | End-to-end workflow (spec → plan → implement) | All templates |
| `/spec_kit:plan` | 7 | Planning only (spec → plan, no implementation) | spec, plan, checklist |
| `/spec_kit:implement` | 8 (10-17) | Implementation only (requires existing spec+plan) | tasks, checklist |
| `/spec_kit:research` | 9 | Comprehensive technical research | research, research_spike, decision_record |

**Workflow Paths** (Valid command sequences):
1. `/spec_kit:complete` - Full end-to-end (spec → plan → implement)
2. `/spec_kit:plan` → `/spec_kit:implement` - Split execution (plan first, implement later)
3. `/spec_kit:research` → `/spec_kit:plan` → `/spec_kit:implement` - With research phase
4. `/spec_kit:research` → `/spec_kit:complete` - Research then full workflow

**Decision Guide**:
- **Know what to build?** → `/spec_kit:complete` or `/spec_kit:plan`
- **Need investigation first?** → `/spec_kit:research`
- **Have spec+plan already?** → `/spec_kit:implement`

**Workflow Decision Diagram**:
```
┌─────────────────────────────────────────────────────────────┐
│                    START: New Task                          │
└─────────────────────────────┬───────────────────────────────┘
                              ▼
              ┌───────────────────────────────┐
              │ Do you understand the         │
              │ requirements clearly?         │
              └───────────────┬───────────────┘
                    ┌─────────┴─────────┐
                    ▼                   ▼
                  YES                   NO
                    │                   │
                    ▼                   ▼
    ┌───────────────────────┐  ┌───────────────────────┐
    │ Do you need to plan   │  │ /spec_kit:research     │
    │ implementation later? │  │ (investigate first)   │
    └───────────┬───────────┘  └───────────┬───────────┘
          ┌─────┴─────┐                    │
          ▼           ▼                    ▼
        YES          NO            Then choose path:
          │           │            .plan or .complete
          ▼           ▼
  ┌─────────────┐  ┌─────────────┐
  │/spec_kit:plan│  │/spec_kit:    │
  │ (7 steps)   │  │ complete    │
  │             │  │ (12 steps)  │
  └──────┬──────┘  └─────────────┘
         │
         ▼
  ┌─────────────────┐
  │/spec_kit:implement│
  │ (8 steps)        │
  │ Requires spec.md │
  │ and plan.md      │
  └─────────────────┘
```

**Execution Modes**:
Each command supports two modes via suffix:
- `:auto` - Autonomous execution (no user approval between steps)
- `:confirm` - Interactive execution (user approval at each step)

Example: `/spec_kit:complete:auto` or `/spec_kit:plan:confirm`

### Architecture (2-Tier System)

SpecKit uses a 2-tier architecture:

**Tier 1: Command Definitions** (what to do)
- Location: `.opencode/command/speckit_*.md` (and `.claude/commands/speckit_*.md` mirror)
- Purpose: Define workflow purpose, steps, user-facing documentation
- Contains: Workflow overview, mode detection, error handling

**Tier 2: Workflow Prompts** (how to do it)
- Location: `.opencode/prompts/spec_kit/*.yaml`
- Purpose: Detailed AI instructions per mode (auto/confirm)
- Contains: Step-by-step activities, template references, tool invocations

**Flow**: User invokes command → Command definition routes to prompt → Prompt executes workflow

### With Hooks

Hooks (`.claude/hooks/`) reference templates directly:

- `enforce-spec-folder.sh` - Suggests templates from `.opencode/speckit/templates/`
- All paths reference `.opencode/speckit/` directly (no symlinks)

### With Skills

**workflows-spec-kit** skill:
- Orchestrates spec folder creation for all file modifications
- Uses template mapping for documentation level selection (0-3)
- References `.opencode/speckit/templates/` for all template operations

**create-documentation** skill:
- Validates template structure and quality
- Enforces placeholder removal and content adaptation
- Uses `.opencode/speckit/templates/` as reference for validation

---

## 7. 🛠️ MAINTENANCE

### Adding New Templates

1. Create template in `.opencode/speckit/templates/`
2. Include `<!-- SPECKIT_TEMPLATE_SOURCE: template-name | v1.0 -->` marker
3. Add to this README
4. Update relevant commands/hooks

### Modifying Scripts

1. Edit scripts in `.opencode/speckit/scripts/`
2. Test scripts work correctly from project root
3. Update documentation

### Version Control

- `.opencode/speckit/` is the only tracked location
- No duplicate files in `.claude/`
- Cleaner git history without symlinks

---

## 8. 📖 QUICK REFERENCE

### Template Selection Guide

| LOC | Level | Required Templates | Optional Additions |
|-----|-------|-------------------|-------------------|
| <100 | 1 | `spec.md` | `checklist.md` |
| <500 | 2 | `spec.md` + `plan.md` | `tasks.md`, `checklist.md` |
| ≥500 | 3 | Full SpecKit (spec + plan + tasks) | `research.md`, `decision-record.md` |

### Command Quick Reference

| Command | Steps | Use When |
|---------|-------|----------|
| `/spec_kit:complete` | 12 | Know requirements, want full workflow |
| `/spec_kit:plan` | 7 | Planning only, implement later |
| `/spec_kit:implement` | 8 | Have spec+plan, ready to code |
| `/spec_kit:research` | 9 | Need investigation first |

### Script Quick Reference

| Script | Purpose | Common Usage |
|--------|---------|--------------|
| `create-new-feature.sh` | Create branch + folder | `./scripts/create-new-feature.sh "description"` |
| `check-prerequisites.sh` | Validate structure | `./scripts/check-prerequisites.sh --json` |
| `calculate-completeness.sh` | Quality score | `./scripts/calculate-completeness.sh specs/###-name/` |
| `setup-plan.sh` | Copy plan template | `./scripts/setup-plan.sh` |

### Documentation Links

**Getting Started**:
- This README → Overview and quick reference
- `.claude/skills/workflows-spec-kit/SKILL.md` → Complete workflow documentation

**Detailed References**:
- `workflows-spec-kit/references/level_specifications.md` → Level decision tree
- `workflows-spec-kit/references/template_guide.md` → Template adaptation guide
- `workflows-spec-kit/assets/template_mapping.md` → Template-to-level mapping

---

## 9. ❓ TROUBLESHOOTING

### Common Issues and Solutions

#### Spec Folder Not Found

**Symptom**: Commands fail with "No spec folder found" or hook prompts for new folder on existing work

**Causes**:
1. Not on a feature branch (`feature-*` or `feat/*` pattern)
2. Spec folder name doesn't match branch pattern
3. Working in wrong directory

**Solutions**:
```bash
# Check current branch
git branch --show-current

# List existing spec folders
ls -d specs/[0-9]*/

# Verify folder matches branch pattern
# Branch: feature-042-user-auth → Folder: specs/042-user-auth/
```

---

#### Template Placeholders Not Replaced

**Symptom**: Hook blocks with "Placeholders found in spec.md" error

**Causes**:
1. `[YOUR_VALUE_HERE]` or `[PLACEHOLDER]` text still in file
2. Template markers not adapted to actual content

**Solutions**:
```bash
# Find all placeholders in spec folder
grep -r "\[.*\]" specs/042-feature/

# Common placeholders to replace:
# - [FEATURE_NAME] → Actual feature name
# - [PRIORITY] → P0/P1/P2/P3
# - [STATUS] → Draft/In Progress/Complete
# - [YOUR_VALUE_HERE] → Actual content
```

---

#### Completeness Score Below Threshold

**Symptom**: `calculate-completeness.sh` returns score below 80%

**Causes**:
1. Missing required files (spec.md, plan.md)
2. Incomplete sections in templates
3. Missing cross-references between files

**Solutions**:
```bash
# Run completeness check with details
./speckit/scripts/calculate-completeness.sh specs/042-feature/

# Check what's missing:
# - Required files: spec.md, plan.md
# - Optional files: tasks.md, checklist.md
# - Content: Minimum word counts per section
# - References: Files should link to each other
```

---

#### Hook Enforcement Conflicts

**Symptom**: Hooks block operations or create unexpected prompts

**Causes**:
1. Multiple hooks triggering on same operation
2. Conflicting skip markers
3. Outdated hook cache

**Solutions**:
```bash
# Check hook logs
tail -20 .claude/hooks/logs/enforce-spec-folder.log

# Clear skip marker if needed
rm .claude/.spec-skip

# Verify hook configuration
cat .claude/settings.json | jq '.hooks'
```

---

#### Command Mode Confusion

**Symptom**: Unsure whether to use `:auto` or `:confirm` mode

**Decision Guide**:
| Situation | Recommended Mode |
|-----------|-----------------|
| First time using SpecKit | `:confirm` |
| Learning new workflow | `:confirm` |
| Routine feature work | `:auto` |
| Complex/risky changes | `:confirm` |
| Debugging workflow issues | `:confirm` |

---

### Performance Issues

#### Scripts Running Slowly

**Symptom**: SpecKit scripts take >1 second to execute

**Solutions**:
1. Check file system performance (network drives can be slow)
2. Reduce spec folder count (archive old folders)
3. Ensure scripts have execute permission: `chmod +x scripts/*.sh`

**Expected Performance**:
| Script | Expected Time |
|--------|--------------|
| `create-new-feature.sh` | <100ms |
| `check-prerequisites.sh` | <50ms |
| `calculate-completeness.sh` | <200ms |
| `setup-plan.sh` | <30ms |

---

## 10. 💬 FAQ

### General Questions

**Q: Do I need a spec folder for every change?**

A: Yes, if the change modifies files (code, docs, config). The `enforce-spec-folder.sh` hook enforces this. For truly trivial changes, select option D (Skip) when prompted - this creates a `.spec-skip` marker valid for the current session.

---

**Q: What's the difference between `research.md` and `research-spike.md`?**

A:
- **`research.md`**: Comprehensive multi-domain research (architecture, security, performance). Use for deep investigations before major features.
- **`research-spike.md`**: Time-boxed experiments (2-4 hours). Use for quick proof-of-concept validation or answering specific technical questions.

---

**Q: Which command should I start with?**

A: Use this decision tree:
1. **Know what to build?** → `/spec_kit:complete` or `/spec_kit:plan`
2. **Need to investigate first?** → `/spec_kit:research`
3. **Have existing spec + plan?** → `/spec_kit:implement`

---

**Q: Can I use SpecKit without the slash commands?**

A: Yes. Templates and scripts work independently. You can:
- Copy templates manually: `cp templates/spec.md specs/042-feature/spec.md`
- Run scripts directly: `./scripts/create-new-feature.sh "feature name"`
- Commands just orchestrate these components

---

### Workflow Questions

**Q: What happens if I run `/spec_kit:implement` without spec.md?**

A: The command will fail at the prerequisites check step. It requires both `spec.md` and `plan.md` to exist in the spec folder before proceeding.

---

**Q: How do I skip a step in a workflow?**

A: In `:confirm` mode, when prompted for approval, choose "Skip" to bypass the current step. In `:auto` mode, workflows don't pause for confirmation.

---

**Q: Can I reuse a spec folder for related work?**

A: Yes. When the hook detects existing content, it offers sub-folder versioning:
- Existing content archives to `001-original-work/`
- New work goes in `002-your-description/`
- Each sub-folder has independent `memory/` context

---

### Integration Questions

**Q: Why does the hook keep prompting me even with a spec folder?**

A: The hook prompts on new conversations or significant changes. To persist the selection:
1. Ensure `.spec-active` marker points to correct sub-folder
2. Check that memory files exist in `spec-folder/memory/`
3. Verify branch name matches spec folder pattern

---

**Q: How do templates integrate with the create-documentation skill?**

A: The `create-documentation` skill validates template usage:
- Checks placeholder removal
- Validates structure matches template
- Enforces quality standards (C7Score)
- Templates in `.opencode/speckit/templates/` are the source of truth

---

## 11. 🔄 RECENT UPDATES

**2025-11-25** (Latest):
- ✅ Fixed broken `.claude/knowledge/` references in all 8 YAML prompts (now uses generic knowledge base reference)
- ✅ Updated command list to show only 4 actual commands (complete, plan, implement, research)
- ✅ Added workflow paths and decision guide documentation
- ✅ Standardized user approval options across all commands (Approve, Review Details, Modify, Skip, Abort)
- ✅ Added step continuation documentation to implement.md
- ✅ Added 2-tier architecture documentation (commands vs prompts)
- ✅ Added context loading and failure recovery sections to all commands
- ✅ Added auto-create behavior documentation
- ✅ Added `/spec_kit:research` command - Uses `research.md` for comprehensive multi-domain research
- ✅ Now both research templates have corresponding commands (research + research-spike)

**2025-11-24**:
- ✅ Aligned README with create-documentation skill standards
- ✅ Added comprehensive TABLE OF CONTENTS
- ✅ Numbered all H2 sections with emojis
- ✅ Improved navigation and cross-references
- ✅ Added completeness script documentation

**2025-11-23**:
- ✅ Added `research.md` - Comprehensive feature research template (878 lines, 17 sections)
- ✅ Moved all files from `.claude/speckit/` to `.opencode/speckit/` (single location)
- ✅ Removed symlink - Claude can access `.opencode/` directly
- ✅ Removed duplicate `.claude/commands/speckit/` folder
- ✅ Updated ALL ~113 path references from `.claude/speckit` to `.opencode/speckit`
- ✅ Updated documentation references in `CLAUDE.md`, `AGENTS.md`, hooks, scripts, commands, and skills
- ✅ No duplicates - `.opencode/speckit/` is the single source of truth

---

**Maintained By**: Development Team
**Version**: 2.0
**Last Updated**: 2025-11-26
