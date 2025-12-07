# SpecKit Framework

> Complete documentation for the SpecKit documentation framework - a spec-driven development system that ensures proper conversation documentation, template usage, and workflow enforcement for all file modifications.

---

## TABLE OF CONTENTS

- [1. 📖 OVERVIEW](#1--overview)
- [2. 🚀 QUICK START](#2--quick-start)
- [3. 📁 DIRECTORY STRUCTURE](#3--directory-structure)
- [4. 📊 DOCUMENTATION LEVELS (1-3)](#4--documentation-levels-1-3)
- [5. 📝 TEMPLATES (9 TOTAL)](#5--templates-9-total)
- [6. ⚙️ SCRIPTS](#6--scripts)
- [7. 🎯 COMMANDS (7 TOTAL)](#7--commands-7-total)
- [8. 🔄 HOW IT WORKS](#8--how-it-works)
- [9. 🔀 CLAUDE VS OPENCODE DIFFERENCES](#9--claude-vs-opencode-differences)
- [10. 🔌 INTEGRATION POINTS](#10--integration-points)
- [11. 💡 USAGE EXAMPLES](#11--usage-examples)
- [12. 🔧 TROUBLESHOOTING](#12--troubleshooting)
- [13. ❓ FAQ](#13--faq)

---

## 1. 📖 OVERVIEW

### What is SpecKit?

**SpecKit** is a comprehensive spec-driven development framework that provides structured templates, automation scripts, and workflow commands to manage feature specifications from planning through implementation. It enforces mandatory documentation for all conversations involving file modifications.

### Key Statistics

| Category   | Count  | Details                                                            |
| ---------- | ------ | ------------------------------------------------------------------ |
| Templates  | 9      | Markdown templates for specs, plans, research, decisions, handover |
| Scripts    | 5      | Shell scripts for automation and validation                        |
| Commands   | 7      | Slash commands for workflow execution (4 core + 3 utility)         |
| Assets     | 2      | Decision support tools (level matrix, template mapping)            |
| References | 4      | Detailed workflow documentation                                    |
| **Total**  | **27** | Complete bundled resource set                                      |

### Key Features

**Template Management**:
- 9 structured templates for documentation levels 1-3
- Placeholder system with validation enforcement
- Template source markers for traceability

**Workflow Automation**:
- Auto-create feature branches and spec folders
- Prerequisite checking and validation
- Completeness scoring for spec folders

**Quality Enforcement**:
- Integration with `validate-spec-final.sh` hook
- Template adaptation validation
- Cross-reference checking

### Activation Triggers

**MANDATORY activation for ALL file modifications:**
- Code files (JS, TS, Python, CSS, HTML)
- Documentation files (Markdown, README, guides)
- Configuration files (JSON, YAML, TOML, env templates)
- Template files (`.opencode/speckit/templates/*.md`)
- Build/tooling files (package.json, requirements.txt, Dockerfile)

**Exceptions (No Spec Required):**
- Pure exploration/reading (no file modifications)
- Single typo fixes (<5 characters in one file)
- Whitespace-only changes
- Auto-generated file updates (package-lock.json)

---

## 2. 🚀 QUICK START

### 30-Second Setup

```bash
# 1. Navigate to your project root
cd /path/to/project

# 2. Find the next spec folder number
ls -d specs/[0-9]*/ | sed 's/.*\/\([0-9]*\)-.*/\1/' | sort -n | tail -1

# 3. Create your spec folder (replace ### with next number)
mkdir -p specs/###-your-feature-name/

# 4. Copy required templates
cp .opencode/speckit/templates/spec.md specs/###-your-feature-name/
cp .opencode/speckit/templates/plan.md specs/###-your-feature-name/
cp .opencode/speckit/templates/tasks.md specs/###-your-feature-name/
```

### Using Commands

```bash
# Full workflow (spec → plan → implement)
/spec_kit:complete add user authentication

# Planning only
/spec_kit:plan refactor database layer

# Implementation (requires existing spec+plan)
/spec_kit:implement

# Technical investigation
/spec_kit:research evaluate auth libraries
```

### Level Selection Quick Guide

| LOC Estimate | Level | Templates to Copy            |
| ------------ | ----- | ---------------------------- |
| <100         | 1     | spec.md + plan.md + tasks.md |
| 100-499      | 2     | Level 1 + checklist.md       |
| ≥500         | 3     | Level 2 + decision-record.md |

---

## 3. 📁 DIRECTORY STRUCTURE

### Core SpecKit Structure

```
.opencode/speckit/
├── README.md               # This file (comprehensive documentation)
├── templates/              # 9 markdown templates
│   ├── spec.md             # Feature specification (Level 1+)
│   ├── plan.md             # Implementation plan (Level 1+)
│   ├── tasks.md            # Task breakdown (Level 1+)
│   ├── checklist.md        # QA validation (Level 2+)
│   ├── decision-record.md  # Architecture decisions (Level 3)
│   ├── research.md         # Comprehensive research (Level 3 optional)
│   ├── research-spike.md   # Time-boxed PoC (Level 3 optional)
│   ├── handover.md         # Session continuity (utility)
│   └── debug-delegation.md # Sub-agent debugging (utility)
└── scripts/                # 5 shell scripts
    ├── common.sh           # Shared utility functions
    ├── create-new-feature.sh    # Create feature branch & spec folder
    ├── check-prerequisites.sh   # Validate spec folder structure
    ├── calculate-completeness.sh # Calculate completeness percentage
    └── setup-plan.sh            # Copy plan template
```

### Skill Resources (workflows-spec-kit)

```
.opencode/skills/workflows-spec-kit/
├── SKILL.md                              # Complete workflow documentation
├── README.md                             # Skill overview
├── assets/
│   ├── level_decision_matrix.md          # LOC thresholds, complexity factors
│   └── template_mapping.md               # Template-to-level mapping
└── references/
    ├── automation_workflows.md           # Hook enforcement, context auto-save
    ├── level_specifications.md           # Complete Level 1-3 specifications
    ├── quick_reference.md                # Commands, checklists, troubleshooting
    └── template_guide.md                 # Template selection & adaptation rules
```

### Spec Folder Structure (Example)

```
specs/042-user-authentication/
├── spec.md                 # Required (Level 1+)
├── plan.md                 # Required (Level 1+)
├── tasks.md                # Required (Level 1+)
├── checklist.md            # Required (Level 2+)
├── decision-record-auth-provider.md  # Required (Level 3)
├── research.md             # Optional (Level 3)
└── memory/                 # Context preservation
    ├── 07-12-25_14-30__initial-spec.md
    └── 07-12-25_16-45__implementation-progress.md
```

---

## 4. 📊 DOCUMENTATION LEVELS (1-3)

The SpecKit documentation system uses a **progressive enhancement** approach where each level BUILDS on the previous.

### Progressive Enhancement Model

```
Level 1 (Baseline):     spec.md + plan.md + tasks.md
                              │
                              ▼
Level 2 (Verification): Level 1 + checklist.md
                              │
                              ▼
Level 3 (Full):         Level 2 + decision-record.md + optional research

Utility (any level):    handover.md, debug-delegation.md
```

### Level Specifications

| Level | Name         | Required Files               | LOC Guidance | Enforcement                              |
| ----- | ------------ | ---------------------------- | ------------ | ---------------------------------------- |
| **1** | Baseline     | spec.md + plan.md + tasks.md | <100         | Hard block if any missing                |
| **2** | Verification | Level 1 + checklist.md       | 100-499      | Hard block if checklist.md missing       |
| **3** | Full         | Level 2 + decision-record.md | ≥500         | Hard block if decision-record.md missing |

### Level 1: Baseline Documentation

- **Required Files**: `spec.md` + `plan.md` + `tasks.md`
- **Optional Files**: None (baseline is complete)
- **Use When**: All features - this is the minimum documentation for any work
- **Examples**: Email validation, bug fix, loading spinner, typo fix

### Level 2: Verification Added

- **Required Files**: Level 1 + `checklist.md`
- **Optional Files**: None
- **Use When**: Features needing systematic QA validation
- **Examples**: Modal component, auth flow, library migration

> **Note**: The `checklist.md` is an **ACTIVE VERIFICATION TOOL** that the AI MUST use before claiming completion. P0/P1 items must be marked with evidence.

### Level 3: Full Documentation

- **Required Files**: Level 2 + `decision-record.md`
- **Optional Files**: `research.md`, `research-spike.md`
- **Use When**: Complex features, architecture changes, major decisions
- **Examples**: Major feature, system redesign, multi-team projects

### Utility Templates (Any Level)

| Template              | Purpose             | When to Use                                  |
| --------------------- | ------------------- | -------------------------------------------- |
| `handover.md`         | Session continuity  | Multi-session work, team handoffs            |
| `debug-delegation.md` | Sub-agent debugging | Delegating debug tasks to specialized agents |

### LOC Thresholds Are SOFT GUIDANCE

These factors can override LOC and push to a higher level:

- **Complexity**: Architectural changes vs simple refactors
- **Risk**: Config cascades, authentication, security implications
- **Dependencies**: Multiple systems affected (>5 files suggests higher level)
- **Testing needs**: Integration vs unit test requirements

**Decision Rules:**
- When in doubt → choose higher level (better to over-document)
- Risk/complexity can override LOC (e.g., 50 LOC security change = Level 2+)
- Multi-file changes often need higher level than LOC alone suggests

---

## 5. 📝 TEMPLATES (9 TOTAL)

All templates are located in `.opencode/speckit/templates/`. **NEVER create documentation from scratch** - always copy from templates and fill placeholders.

### Template Summary Table

| Template              | Level | Type     | Lines | Description                             |
| --------------------- | ----- | -------- | ----- | --------------------------------------- |
| `spec.md`             | 1+    | Required | ~150  | Feature specification with user stories |
| `plan.md`             | 1+    | Required | ~120  | Implementation plan with architecture   |
| `tasks.md`            | 1+    | Required | ~80   | Task breakdown by user story            |
| `checklist.md`        | 2+    | Required | ~100  | Validation/QA checklists (P0/P1/P2)     |
| `decision-record.md`  | 3     | Required | ~90   | Architecture Decision Records (ADR)     |
| `research.md`         | 3     | Optional | ~878  | Comprehensive multi-domain research     |
| `research-spike.md`   | 3     | Optional | ~100  | Time-boxed research/PoC                 |
| `handover.md`         | Any   | Utility  | ~63   | Session continuity and agent handover   |
| `debug-delegation.md` | Any   | Utility  | ~64   | Sub-agent debugging delegation          |

### Level 1: Baseline Templates

#### `spec.md` - Feature Specification

**Purpose**: Complete feature specification with user stories, acceptance criteria, and technical requirements

**Key Sections**:
- Objective & metadata (category, priority, status)
- Scope (in/out of scope)
- User stories with acceptance scenarios
- Functional & non-functional requirements
- Edge cases, success criteria, dependencies

**Copy Command**:
```bash
cp .opencode/speckit/templates/spec.md specs/###-name/spec.md
```

#### `plan.md` - Implementation Plan

**Purpose**: Implementation plan with architecture decisions, technical approach, and execution phases

**Key Sections**:
- Technical approach & architecture
- Implementation phases with milestones
- Testing strategy & quality gates
- Risk assessment & rollback plan
- Resource requirements

**Copy Command**:
```bash
cp .opencode/speckit/templates/plan.md specs/###-name/plan.md
```

#### `tasks.md` - Task Breakdown

**Purpose**: Break implementation plan into actionable, trackable tasks

**Key Sections**:
- Task list with priorities and estimates
- Dependencies between tasks
- Assignment and status tracking
- Completion criteria per task

**Copy Command**:
```bash
cp .opencode/speckit/templates/tasks.md specs/###-name/tasks.md
```

### Level 2: Verification Template

#### `checklist.md` - QA Validation

**Purpose**: Systematic validation and QA procedures with priority levels

**Key Sections**:
- Pre-implementation checklist
- Implementation verification
- Testing checklist
- Documentation completeness
- Deployment readiness

**Priority System**:
- **P0 (Blocker)**: MUST pass - work is incomplete without this
- **P1 (Required)**: MUST pass for production readiness
- **P2 (Optional)**: Can defer with documented reason

**Copy Command**:
```bash
cp .opencode/speckit/templates/checklist.md specs/###-name/checklist.md
```

### Level 3: Full Documentation Templates

#### `decision-record.md` - Architecture Decisions

**Purpose**: Architecture Decision Records (ADRs) for documenting major technical decisions

**Key Sections**:
- Decision title and status
- Context and problem statement
- Options considered with pros/cons
- Decision outcome and rationale
- Consequences and follow-up actions

**Copy Command**:
```bash
cp .opencode/speckit/templates/decision-record.md specs/###-name/decision-record-[topic].md
```

#### `research.md` - Comprehensive Research

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

**Copy Command**:
```bash
cp .opencode/speckit/templates/research.md specs/###-name/research.md
```

#### `research-spike.md` - Time-Boxed Research

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

**Copy Command**:
```bash
cp .opencode/speckit/templates/research-spike.md specs/###-name/research-spike-[topic].md
```

### Utility Templates

#### `handover.md` - Session Continuity

**Purpose**: Document context for agent handoffs between sessions or team members

**Key Sections**:
- Context summary (task ID, status, progress)
- Completed work (files modified, decisions made, tests run)
- Remaining work (next steps, known issues, blockers)
- Artifacts (key files, related memory files)
- Handover checklist

**When to Use**:
- Multi-session work requiring context transfer
- Team handoffs or agent transitions
- Session completion with pending work

**Copy Command**:
```bash
cp .opencode/speckit/templates/handover.md specs/###-name/handover.md
```

#### `debug-delegation.md` - Sub-Agent Debugging

**Purpose**: Document debugging context when delegating to specialized agents

**Key Sections**:
- Problem summary (error category, message, affected files)
- Attempted fixes (approach, result, diff for each attempt)
- Context for specialist (code section, documentation, hypothesis)
- Recommended next steps
- Handoff checklist

**When to Use**:
- Complex debugging requiring specialized knowledge
- After 3+ failed fix attempts
- Escalating to domain-specific agents

**Copy Command**:
```bash
cp .opencode/speckit/templates/debug-delegation.md specs/###-name/debug-delegation.md
```

### Template Rules

1. **ALWAYS copy from `.opencode/speckit/templates/`** - never create from scratch
2. **Fill ALL placeholders** - replace `[PLACEHOLDER]` and `[YOUR_VALUE_HERE]` with actual content
3. **Remove sample content** - delete `<!-- SAMPLE CONTENT -->` blocks
4. **Preserve structure** - keep numbered H2 sections with consistent formatting
5. **Use descriptive filenames** - prefix decision records and research spikes with topic

---

## 6. ⚙️ SCRIPTS

Five automation scripts in `.opencode/speckit/scripts/` provide workflow automation.

### Script Overview

| Script                      | Purpose                             | Performance   |
| --------------------------- | ----------------------------------- | ------------- |
| `common.sh`                 | Shared utility functions            | N/A (sourced) |
| `create-new-feature.sh`     | Create feature branch & spec folder | ~100ms        |
| `check-prerequisites.sh`    | Validate spec folder structure      | ~50ms         |
| `calculate-completeness.sh` | Calculate completeness percentage   | ~200ms        |
| `setup-plan.sh`             | Copy plan template                  | ~30ms         |

### `common.sh` - Shared Utilities

**Purpose**: Shared utility functions used by all other SpecKit scripts

**Functions**:
| Function                 | Description                               |
| ------------------------ | ----------------------------------------- |
| `get_repo_root()`        | Find git repository root directory        |
| `get_current_branch()`   | Get current git branch name               |
| `get_feature_paths()`    | Resolve all feature-related paths         |
| `check_feature_branch()` | Validate branch follows naming convention |

**Usage**: Sourced by other scripts, not called directly

### `create-new-feature.sh` - Feature Creation

**Purpose**: Create new feature branch and spec folder with proper numbering

**Options**:
| Flag                  | Description                     | Default        |
| --------------------- | ------------------------------- | -------------- |
| `--json`              | Output in JSON format           | false          |
| `--short-name <name>` | Custom feature name (2-4 words) | auto-generated |
| `--number N`          | Specify feature number          | auto-increment |

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

### `check-prerequisites.sh` - Structure Validation

**Purpose**: Validate spec folder structure and list available documentation

**Options**:
| Flag              | Description                     | Default |
| ----------------- | ------------------------------- | ------- |
| `--json`          | Output in JSON format           | false   |
| `--require-tasks` | Require tasks.md exists         | false   |
| `--include-tasks` | Include tasks.md in output      | false   |
| `--paths-only`    | Output paths without validation | false   |

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

### `calculate-completeness.sh` - Quality Assessment

**Purpose**: Calculate spec folder completeness percentage for quality assessment

**What It Checks**:
| Check            | Weight | Description                      |
| ---------------- | ------ | -------------------------------- |
| Required files   | 30%    | spec.md, plan.md exist           |
| Placeholders     | 25%    | All `[YOUR_VALUE_HERE]` replaced |
| Content quality  | 20%    | Minimum word counts met          |
| Cross-references | 15%    | Files reference each other       |
| Metadata         | 10%    | Status, priority, dates filled   |

**Example**:
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

### `setup-plan.sh` - Plan Template Setup

**Purpose**: Copy plan template to current feature folder

**Options**:
| Flag     | Description           | Default |
| -------- | --------------------- | ------- |
| `--json` | Output in JSON format | false   |

**Example**:
```bash
$ .opencode/speckit/scripts/setup-plan.sh

✅ Plan template copied to: specs/042-user-auth/plan.md
```

**Exit Codes**: `0` = Success | `1` = No feature folder | `2` = Template not found

---

## 7. 🎯 COMMANDS (7 TOTAL)

Seven SpecKit commands available in both Claude Code and OpenCode.

### Command Overview

| Command               | Steps | Purpose                           | Key Templates                             |
| --------------------- | ----- | --------------------------------- | ----------------------------------------- |
| `/spec_kit:help`      | -     | List all commands                 | -                                         |
| `/spec_kit:complete`  | 12    | Full end-to-end workflow          | All templates                             |
| `/spec_kit:plan`      | 7     | Planning only (no implementation) | spec, plan, checklist                     |
| `/spec_kit:implement` | 8     | Execute pre-planned work          | tasks, checklist                          |
| `/spec_kit:research`  | 9     | Technical investigation           | research, research-spike, decision-record |
| `/spec_kit:resume`    | -     | Resume previous session           | Loads memory/                             |
| `/spec_kit:status`    | -     | Show progress at a glance         | -                                         |

### Core Commands (4)

#### `/spec_kit:complete` - Full Workflow

End-to-end workflow from specification through implementation.

**Steps (12)**:
1. Create/select spec folder
2. Write spec.md
3. Review spec
4. Write plan.md
5. Review plan
6. Create tasks.md
7. Implement tasks
8. Run tests
9. Create checklist.md
10. Verify checklist
11. Commit changes
12. Complete workflow

#### `/spec_kit:plan` - Planning Only

Planning workflow without implementation (for later execution).

**Steps (7)**:
1. Create/select spec folder
2. Write spec.md
3. Review spec
4. Write plan.md
5. Review plan
6. Create tasks.md
7. Save for later implementation

#### `/spec_kit:implement` - Implementation Only

Execute pre-planned work (requires existing spec+plan).

**Steps (8)**:
1. Load existing spec folder
2. Review spec.md and plan.md
3. Load/create tasks.md
4. Implement tasks
5. Run tests
6. Create/verify checklist.md
7. Commit changes
8. Complete workflow

#### `/spec_kit:research` - Technical Investigation

Comprehensive technical research workflow.

**Steps (9)**:
1. Define research scope
2. Create research.md or research-spike.md
3. Conduct investigation
4. Document findings
5. Evaluate options
6. Create decision-record.md
7. Recommend approach
8. Review with stakeholders
9. Prepare for planning

### Utility Commands (3)

| Command            | Purpose                                    |
| ------------------ | ------------------------------------------ |
| `/spec_kit:help`   | List all commands with brief descriptions  |
| `/spec_kit:resume` | Resume previous session, load memory files |
| `/spec_kit:status` | Show current spec folder progress          |

### Mode Suffixes

Each core command supports two execution modes:

| Suffix     | Mode        | Behavior                        |
| ---------- | ----------- | ------------------------------- |
| `:auto`    | Autonomous  | Execute without approval gates  |
| `:confirm` | Interactive | Pause at each step for approval |

**Examples**:
```bash
/spec_kit:complete add user authentication :auto
/spec_kit:plan refactor database layer :confirm
```

### Workflow Decision Guide

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
    │ Do you need to plan   │  │ /spec_kit:research    │
    │ implementation later? │  │ (investigate first)    │
    └───────────┬───────────┘  └───────────┬───────────┘
          ┌─────┴─────┐                    │
          ▼           ▼                    ▼
        YES          NO             Then choose path:
          │           │             :plan or :complete
          ▼           ▼
  ┌─────────────┐  ┌─────────────┐
  │/spec_kit:   │  │/spec_kit:   │
  │ plan        │  │ complete    │
  │ (7 steps)   │  │ (12 steps)  │
  └──────┬──────┘  └─────────────┘
         │
         ▼
  ┌─────────────────┐
  │/spec_kit:       │
  │ implement       │
  │ (8 steps)       │
  └─────────────────┘
```

### Valid Workflow Paths

1. `/spec_kit:complete` - Full end-to-end (spec → plan → implement)
2. `/spec_kit:plan` → `/spec_kit:implement` - Split execution
3. `/spec_kit:research` → `/spec_kit:plan` → `/spec_kit:implement` - With research phase
4. `/spec_kit:research` → `/spec_kit:complete` - Research then full workflow

### Command Locations

```
.claude/commands/spec_kit/           # Claude Code
.opencode/command/spec_kit/          # OpenCode (identical)
```

---

## 8. 🔄 HOW IT WORKS

### 8.1 Spec Folder Question Flow (A/B/C/D Options)

When file modification intent is detected, the system presents four options:

| Option | Action                   | Description                                      |
| ------ | ------------------------ | ------------------------------------------------ |
| **A**  | Use existing spec folder | Continue work in detected folder                 |
| **B**  | Create new spec folder   | Auto-increment number, create fresh folder       |
| **C**  | Update related spec      | Modify existing related spec                     |
| **D**  | Skip documentation       | Create `.spec-skip` marker, proceed without spec |

**AI Agent Protocol**: Present options, wait for explicit user selection, never decide autonomously.

### 8.2 Memory File Loading (Auto-Load with Opt-Out)

When selecting Option A or C with existing memory files:

**Default Behavior**: Automatically load the most recent memory file

**On-Demand Options**:
| Command                            | Action                             |
| ---------------------------------- | ---------------------------------- |
| `"load all memory"`                | Load up to 3 recent files          |
| `"list memory"`                    | Show available files for selection |
| `"skip memory"` or `"fresh start"` | No context loading                 |

**Memory File Naming Format**: `DD-MM-YY_HH-MM__short-description.md`

### 8.3 Sub-Folder Versioning (001, 002, 003 Pattern)

When reusing a spec folder with existing root-level content:

1. **Trigger**: Selecting Option A with existing files at root
2. **Archive**: Existing files moved to `001-{topic}/`
3. **New Work**: Create sub-folder `002-{user-name}/`, `003-{user-name}/`, etc.
4. **Memory**: Each sub-folder has independent `memory/` context

**Example**:
```
specs/122-skill-standardization/
├── 001-original-work/        (archived)
├── 002-api-refactor/         (completed)
└── 003-bug-fixes/            (active)
    ├── spec.md
    ├── plan.md
    ├── tasks.md
    └── memory/
        └── 07-12-25_14-30__context.md
```

### 8.4 Hook-Assisted Enforcement (Claude Code Only)

The `validate-spec-final.sh` hook provides automatic prompts and validation.

**Enforcement Rules**:
- Level 1 blocks if missing: `spec.md` OR `plan.md` OR `tasks.md`
- Level 2 blocks if missing: `checklist.md`
- Level 3 blocks if missing: `decision-record.md`

> **Note**: Hooks are NOT available in OpenCode. OpenCode users rely on AGENTS.md discipline.

### 8.5 Context Auto-Save

| Platform    | Mechanism                                      | Frequency         |
| ----------- | ---------------------------------------------- | ----------------- |
| Claude Code | Automatic via `skill-scaffold-trigger.sh` hook | Every 20 messages |
| OpenCode    | Manual - use "save context" or `/save_context` | On-demand         |

### 8.6 Folder Naming Convention

**Format**: `/specs/###-short-name/`

**Finding Next Number**:
```bash
ls -d specs/[0-9]*/ | sed 's/.*\/\([0-9]*\)-.*/\1/' | sort -n | tail -1
```

**Naming Rules**:
- 2-3 words maximum
- Lowercase, hyphen-separated
- Action-noun structure preferred (e.g., `add-auth`, `fix-validation`)

### 8.7 Architecture (2-Tier System)

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

---

## 9. 🔀 CLAUDE VS OPENCODE DIFFERENCES

### Feature Comparison Matrix

| Feature                     | Claude Code              | OpenCode                 |
| --------------------------- | ------------------------ | ------------------------ |
| **Hooks System**            | ✅ Full auto-enforcement  | ❌ Not available          |
| **Spec Folder Enforcement** | ✅ Hard block (hooks)     | ⚠️ AGENTS.md discipline   |
| **Context Auto-Save**       | ✅ Every 20 messages      | ⚠️ Manual `/save_context` |
| **Memory Surfacing**        | ✅ Auto-suggested         | ⚠️ Manual file reading    |
| **Checklist Verification**  | ✅ P0/P1/P2 auto-enforced | ⚠️ Manual verification    |
| **Sequential Thinking MCP** | ⚠️ Use ultrathink instead | ✅ Recommended            |
| **Templates**               | ✅ Same location          | ✅ Same location          |
| **Commands**                | ✅ Identical (7)          | ✅ Identical (7)          |
| **Skills**                  | ✅ Identical              | ✅ Identical              |

### Claude-Specific Folders

#### `.claude/hooks/` - Hook Enforcement

Key SpecKit hooks:
| Hook                                | Purpose                        |
| ----------------------------------- | ------------------------------ |
| `enforce-spec-folder.sh`            | Blocks without spec folder     |
| `workflows-save-context-trigger.sh` | Auto-saves every 20 messages   |
| `memory-surfacing.sh`               | Suggests relevant memory files |
| `validate-new-task.sh`              | Detects task changes           |

#### `.claude/checklist-evidence/`

Stores P0/P1/P2 verification evidence as JSON files:
- `evidence.json` - Item-level verification with timestamps
- `general-evidence.json` - Cross-phase evidence storage

#### `.claude/checklists/`

Phase-specific validation checklists:
- `research-phase.md`
- `planning-phase.md`
- `implementation-phase.md`
- `review-phase.md`

### OpenCode Implications

**Without hooks, OpenCode users must:**

1. **Rely on AGENTS.md Section 2** - No automatic blocking
2. **Manual context saving** - Use `/save_context` explicitly
3. **Manual checklist verification** - Read and verify items yourself
4. **Manual memory management** - Explicitly read memory files

### OpenCode Workaround Checklist

```markdown
Before EVERY file modification:
□ Check if spec folder exists
□ If not, create: mkdir -p specs/###-feature-name/
□ Copy required templates based on level

Every 20 messages (approximately):
□ Run /save_context or ask AI to save context

Before claiming "done":
□ Load and verify checklist.md if Level 2+
□ Mark each item [x] with evidence
```

---

## 10. 🔌 INTEGRATION POINTS

### CAPS Integration (Claude-Specific)

The Context-Aware Permission System provides intelligent rule evaluation:

| Library                | Purpose                       |
| ---------------------- | ----------------------------- |
| `context-inference.sh` | CAPS core engine              |
| `caps-adapter.sh`      | Bridge to registry operations |
| `rule-evaluation.sh`   | 68 AGENTS.md-derived rules    |
| `speckit-state.sh`     | Session state management      |

### Related Skills

**Upstream:** None (foundational workflow)

**Downstream:**
| Skill                    | Integration                          |
| ------------------------ | ------------------------------------ |
| `workflows-code`         | Uses spec folders for implementation |
| `workflows-git`          | References specs in commits/PRs      |
| `create-documentation`   | Validates documentation quality      |
| `workflows-save-context` | Saves to spec folder memory/         |

### External Dependencies

**Shared (Both Platforms):**
- `.opencode/speckit/templates/*.md` - All 9 templates
- `.opencode/skills/workflows-spec-kit/SKILL.md` - Main skill
- `AGENTS.md` - Section 2 defines requirements
- `specs/` - Directory for all spec folders

**Claude-Only:**
- `.claude/hooks/PreToolUse/validate-spec-final.sh`
- `.claude/hooks/PreToolUse/validate-completion-checklist.sh`
- `.claude/hooks/PostToolUse/verify-spec-compliance.sh`
- `.claude/hooks/PostToolUse/skill-scaffold-trigger.sh`
- `.claude/.spec-active` - Active spec marker
- `.claude/.spec-skip` - Skip marker

### SpecKit vs Commands vs Hooks

| Component    | Purpose                        | Execution                      | Location             |
| ------------ | ------------------------------ | ------------------------------ | -------------------- |
| **SpecKit**  | Template & workflow management | User-invoked or AI-triggered   | `.opencode/speckit/` |
| **Commands** | SpecKit workflow execution     | Slash commands (`/spec_kit:*`) | `.claude/commands/`  |
| **Hooks**    | Automated enforcement          | System-triggered on events     | `.claude/hooks/`     |

---

## 11. 💡 USAGE EXAMPLES

### Creating a New Feature

```bash
# Generate feature branch and spec folder
.opencode/speckit/scripts/create-new-feature.sh "Add user authentication system"

# Result:
# - Branch: 042-user-authentication-system
# - Folder: specs/042-user-authentication-system/
# - File: specs/042-user-authentication-system/spec.md
```

### Manual Template Setup

```bash
# Level 1: Baseline (all features)
cp .opencode/speckit/templates/spec.md specs/042-feature/spec.md
cp .opencode/speckit/templates/plan.md specs/042-feature/plan.md
cp .opencode/speckit/templates/tasks.md specs/042-feature/tasks.md

# Level 2: Add verification
cp .opencode/speckit/templates/checklist.md specs/042-feature/checklist.md

# Level 3: Add decision documentation
cp .opencode/speckit/templates/decision-record.md specs/042-feature/decision-record-database.md

# Optional research
cp .opencode/speckit/templates/research.md specs/042-feature/research.md
cp .opencode/speckit/templates/research-spike.md specs/042-feature/research-spike-auth-library.md

# Utility templates
cp .opencode/speckit/templates/handover.md specs/042-feature/handover.md
cp .opencode/speckit/templates/debug-delegation.md specs/042-feature/debug-delegation.md
```

### Checking Prerequisites

```bash
# Validate spec folder has required files
.opencode/speckit/scripts/check-prerequisites.sh

# Output example:
# FEATURE_DIR: specs/042-user-auth
# AVAILABLE_DOCS:
#   ✓ spec.md
#   ✓ plan.md
#   ✗ tasks.md
#   ✗ research.md
```

### Checking Completeness

```bash
# Calculate spec folder completeness
.opencode/speckit/scripts/calculate-completeness.sh specs/042-user-auth

# Output example:
# Completeness Score: 75%
# Missing:
#   - tasks.md not created
#   - Placeholders in spec.md (2 found)
#   - Cross-references incomplete
```

### Using Commands

```bash
# Full workflow for new feature
/spec_kit:complete add payment processing :confirm

# Planning for later implementation
/spec_kit:plan refactor user service :auto

# Research before planning
/spec_kit:research evaluate GraphQL vs REST

# Resume previous work
/spec_kit:resume

# Check current status
/spec_kit:status
```

### Sub-Folder Versioning

```bash
# When reusing spec folder with existing content
# System auto-creates versioned sub-folders:

specs/042-user-auth/
├── 001-initial-implementation/    # Original work (archived)
│   ├── spec.md
│   └── plan.md
├── 002-password-reset-feature/    # Second iteration
│   ├── spec.md
│   ├── plan.md
│   └── memory/
└── 003-oauth-integration/         # Active work
    ├── spec.md
    ├── plan.md
    ├── tasks.md
    └── memory/
```

---

## 12. 🔧 TROUBLESHOOTING

### Spec Folder Not Found

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

# Check .spec-active marker (Claude only)
cat .claude/.spec-active

# Verify folder matches branch pattern
# Branch: feature-042-user-auth → Folder: specs/042-user-auth/
```

### Template Placeholders Not Replaced

**Symptom**: Hook blocks with "Placeholders found in spec.md" error

**Causes**:
1. `[YOUR_VALUE_HERE]` or `[PLACEHOLDER]` text still in file
2. Template markers not adapted to actual content

**Solutions**:
```bash
# Find all placeholders in spec folder
grep -r "\[PLACEHOLDER\]" specs/042-feature/
grep -r "\[YOUR_VALUE_HERE\]" specs/042-feature/

# Common placeholders to replace:
# - [FEATURE_NAME] → Actual feature name
# - [PRIORITY] → P0/P1/P2/P3
# - [STATUS] → Draft/In Progress/Complete
```

### Completeness Score Below Threshold

**Symptom**: `calculate-completeness.sh` returns score below 80%

**Causes**:
1. Missing required files (spec.md, plan.md)
2. Incomplete sections in templates
3. Missing cross-references between files

**Solutions**:
```bash
# Run completeness check with details
.opencode/speckit/scripts/calculate-completeness.sh specs/042-feature/

# Address missing items in order of weight:
# 1. Required files (30%)
# 2. Placeholders (25%)
# 3. Content quality (20%)
# 4. Cross-references (15%)
# 5. Metadata (10%)
```

### Hook Enforcement Conflicts (Claude Only)

**Symptom**: Hooks block operations or create unexpected prompts

**Causes**:
1. Multiple hooks triggering on same operation
2. Conflicting skip markers
3. Outdated hook cache

**Solutions**:
```bash
# Check hook logs
tail -20 .claude/hooks/logs/enforce-spec-folder.log

# Clear spec-active marker
rm .claude/.spec-active

# Remove skip marker
rm .claude/.spec-skip

# Verify hook configuration
cat .claude/settings.json | jq '.hooks'
```

### Memory Loading Issues

**Symptom**: Previous context not loaded

**Solutions**:
```bash
# Verify memory folder exists
ls -la specs/###-folder/memory/

# Check file naming pattern
ls specs/###-folder/memory/*__*.md

# Manually load memory file
cat specs/###-folder/memory/DD-MM-YY_HH-MM__description.md
```

### Command Mode Confusion

**Symptom**: Unsure whether to use `:auto` or `:confirm` mode

**Decision Guide**:
| Situation                 | Recommended Mode |
| ------------------------- | ---------------- |
| First time using SpecKit  | `:confirm`       |
| Learning new workflow     | `:confirm`       |
| Routine feature work      | `:auto`          |
| Complex/risky changes     | `:confirm`       |
| Debugging workflow issues | `:confirm`       |

### Performance Issues

**Symptom**: SpecKit scripts take >1 second to execute

**Solutions**:
1. Check file system performance (network drives can be slow)
2. Reduce spec folder count (archive old folders)
3. Ensure scripts have execute permission: `chmod +x .opencode/speckit/scripts/*.sh`

**Expected Performance**:
| Script                      | Expected Time |
| --------------------------- | ------------- |
| `create-new-feature.sh`     | <100ms        |
| `check-prerequisites.sh`    | <50ms         |
| `calculate-completeness.sh` | <200ms        |
| `setup-plan.sh`             | <30ms         |

---

## 13. ❓ FAQ

### General Questions

**Q: Do I need a spec folder for every change?**

A: Yes, if the change modifies files (code, docs, config). The `enforce-spec-folder.sh` hook enforces this. For truly trivial changes, select option D (Skip) when prompted - this creates a `.spec-skip` marker valid for the current session.

---

**Q: What's the difference between `research.md` and `research-spike.md`?**

A:
- **`research.md`**: Comprehensive multi-domain research (architecture, security, performance). Use for deep investigations before major features. (~878 lines, 17 sections)
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

**Q: What happens if I run `/spec_kit:implement` without spec.md?**

A: The command will fail at the prerequisites check step. It requires both `spec.md` and `plan.md` to exist in the spec folder before proceeding.

---

**Q: Can I reuse a spec folder for related work?**

A: Yes. When the hook detects existing content, it offers sub-folder versioning:
- Existing content archives to `001-original-work/`
- New work goes in `002-your-description/`
- Each sub-folder has independent `memory/` context

---

**Q: What are the 9 templates?**

A:
1. `spec.md` - Feature specification (Level 1+)
2. `plan.md` - Implementation plan (Level 1+)
3. `tasks.md` - Task breakdown (Level 1+)
4. `checklist.md` - QA validation (Level 2+)
5. `decision-record.md` - Architecture decisions (Level 3)
6. `research.md` - Comprehensive research (Level 3 optional)
7. `research-spike.md` - Time-boxed PoC (Level 3 optional)
8. `handover.md` - Session continuity (utility)
9. `debug-delegation.md` - Sub-agent debugging (utility)

---

**Q: What are P0, P1, P2 priority levels in checklists?**

A:
- **P0 (Blocker)**: MUST pass - work is incomplete without this
- **P1 (Required)**: MUST pass for production readiness
- **P2 (Optional)**: Can defer with documented reason

---

**Q: Are commands the same in Claude and OpenCode?**

A: Yes, identical 7 commands exist in both platforms with the same behavior.

---

**Q: How often is context auto-saved?**

A: Every 20 messages in Claude Code (automatic). Manual in OpenCode (use `/save_context`).

---

**Q: Where are templates located?**

A: Single source of truth: `.opencode/speckit/templates/`