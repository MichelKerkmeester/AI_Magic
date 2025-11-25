# SpecKit - Spec-Driven Development Framework

**Location**: `.opencode/speckit/` (single source of truth - no duplicates)

#### 📋 TABLE OF CONTENTS

1. [📖 OVERVIEW](#1--overview)
2. [🗂️ DIRECTORY STRUCTURE](#2-️-directory-structure)
3. [📝 TEMPLATES](#3--templates)
4. [🔧 SCRIPTS](#4--scripts)
5. [💡 USAGE EXAMPLES](#5--usage-examples)
6. [🔗 INTEGRATION](#6--integration)
7. [🛠️ MAINTENANCE](#7-️-maintenance)
8. [📖 DOCUMENTATION](#8--documentation)
9. [🔄 RECENT UPDATES](#9--recent-updates)

---

## 1. 📖 OVERVIEW

SpecKit is a comprehensive framework for spec-driven development, providing:
- **Templates**: Structured markdown templates for specs, plans, tasks, research, and more
- **Scripts**: Shell scripts for feature creation, prerequisite checking, and workflow automation
- **Commands**: Slash commands for SpecKit workflow integration

---

## 2. 🗂️ DIRECTORY STRUCTURE

```
.opencode/speckit/
├── templates/              # 10 markdown templates
│   ├── spec_template.md
│   ├── plan_template.md
│   ├── tasks_template.md
│   ├── checklist_template.md
│   ├── research_template.md         # Comprehensive feature research
│   ├── research_spike_template.md   # Time-boxed technical research
│   ├── decision_record_template.md
│   ├── readme_template.md
│   └── subfolder_readme_template.md
└── scripts/                # 4 shell scripts
    ├── common.sh                     # Shared utility functions
    ├── create-new-feature.sh         # Create feature branch & spec folder
    ├── check-prerequisites.sh        # Validate spec folder structure
    ├── calculate-completeness.sh     # Calculate spec folder completeness percentage
    └── setup-plan.sh                 # Copy plan template
```

---

## 3. 📝 TEMPLATES

### Core Templates (Required for most features)

#### `spec_template.md`
- Complete feature specification
- User stories, acceptance criteria
- Use for: Level 2/3 features

#### `plan_template.md`
- Implementation plan and architecture
- Technical approach, phases, testing strategy
- Use for: Level 2/3 features

### Optional Templates

#### `research_template.md` ⭐ NEW
- Comprehensive technical research documentation
- 17 sections covering architecture, specs, integration, security, etc.
- Use for: Deep technical investigation before implementation
- When: Complex features spanning multiple technical areas

#### `tasks_template.md`
- Break plan into actionable tasks
- Use for: After plan.md, before coding

#### `checklist_template.md`
- Validation and QA checklists
- Use for: Systematic validation needs

#### `research_spike_template.md`
- Time-boxed research/experimentation
- Use for: Proof-of-concept, feasibility validation

#### `decision_record_template.md`
- Architecture Decision Records (ADRs)
- Use for: Major technical decisions

### Simplified Templates

#### `readme_template.md`
- Standard README documentation
- Use for: Project documentation, package READMEs

#### `subfolder_readme_template.md`
- Sub-folder organization documentation
- Use for: Organizing related work within spec folders

---

## 4. 🔧 SCRIPTS

### `common.sh`
Shared utility functions used by other scripts:
- `get_repo_root()` - Find repository root
- `get_current_branch()` - Get current git branch or feature
- `get_feature_paths()` - Resolve all feature paths
- `check_feature_branch()` - Validate branch naming

### `create-new-feature.sh`
Create new feature branch and spec folder:
```bash
.opencode/speckit/scripts/create-new-feature.sh "Feature description"
.opencode/speckit/scripts/create-new-feature.sh --short-name "feature-name" "Description"
.opencode/speckit/scripts/create-new-feature.sh --number 42 "Description"
```

**Options**:
- `--json` - Output in JSON format
- `--short-name <name>` - Custom branch name (2-4 words)
- `--number N` - Specify branch number manually

### `check-prerequisites.sh`
Validate spec folder structure and list available docs:
```bash
.opencode/speckit/scripts/check-prerequisites.sh --json
.opencode/speckit/scripts/check-prerequisites.sh --require-tasks
.opencode/speckit/scripts/check-prerequisites.sh --paths-only
```

**Options**:
- `--json` - Output in JSON format
- `--require-tasks` - Require tasks.md (for implementation)
- `--include-tasks` - Include tasks.md in output
- `--paths-only` - Output paths without validation

### `calculate-completeness.sh`
Calculate spec folder completeness percentage:
```bash
.opencode/speckit/scripts/calculate-completeness.sh /path/to/spec/folder
```

**What it checks**:
- Required documentation exists (spec.md, plan.md, tasks.md)
- Template adaptation (placeholders replaced)
- Content quality (minimum word counts)
- Cross-references between files
- Metadata completeness

**Output**:
- Percentage score (0-100%)
- Missing elements list
- Recommendations for improvement

### `setup-plan.sh`
Copy plan template to feature folder:
```bash
.opencode/speckit/scripts/setup-plan.sh
.opencode/speckit/scripts/setup-plan.sh --json
```

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
cp .opencode/speckit/templates/research_template.md specs/042-feature/research.md

# Copy research-spike template for time-boxed experiment
cp .opencode/speckit/templates/research_spike_template.md specs/042-feature/research-spike-auth-library.md

# Copy decision record for technical decisions
cp .opencode/speckit/templates/decision_record_template.md specs/042-feature/decision-record-database.md
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

SpecKit commands (`.opencode/command/speckit/*.md`) reference these templates and scripts:

**Core Workflow Commands**:
- `/speckit.specify` - Uses `spec_template.md` - Create feature specification
- `/speckit.clarify` - No template - Resolve spec ambiguities interactively
- `/speckit.plan` - Uses `plan_template.md` - Generate technical implementation plan
- `/speckit.tasks` - Uses `tasks_template.md` + `check-prerequisites.sh` - Break plan into executable tasks
- `/speckit.implement` - Uses task list - Execute implementation systematically

**Quality & Validation Commands**:
- `/speckit.checklist` - Uses `checklist_template.md` - Generate requirements quality checklists
- `/speckit.analyze` - Uses `check-prerequisites.sh` - Pre-implementation quality analysis

**Research & Decision Commands**:
- `/speckit.research` - Uses `research_template.md` - Comprehensive multi-domain research
- `/speckit.research-spike` - Uses `research_spike_template.md` - Time-boxed technical research
- `/speckit.decision` - Uses `decision_record_template.md` - Architecture Decision Records (ADRs)

**Governance Commands**:
- `/speckit.constitution` - Uses project principles - Define project governance and principles

### With Hooks

Hooks (`.claude/hooks/`) reference templates directly:

- `enforce-spec-folder.sh` - Suggests templates from `.opencode/speckit/templates/`
- All paths reference `.opencode/speckit/` directly (no symlinks)

### With Skills

**workflows-conversation** skill:
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
2. Test via both `.opencode/` and `.claude/` paths (symlink)
3. Update documentation

### Version Control

- `.opencode/speckit/` is the only tracked location
- No duplicate files in `.claude/`
- Cleaner git history without symlinks

---

## 8. 📖 DOCUMENTATION

### Quick Navigation

**Getting Started**:
- Read this README for overview
- See `.claude/knowledge/conversation_documentation.md` for complete workflow
- Check `.claude/skills/workflows-conversation/` for automation details

**Template Selection**:
- Level decision tree: See `.claude/knowledge/conversation_documentation.md` Section 2
- Template mapping: See `.claude/skills/workflows-conversation/assets/template_mapping.md`

**Scripts Usage**:
- Script documentation: See Section 4 above
- Integration examples: See Section 5 above

### Full Documentation

**Full Documentation**: See `.claude/knowledge/conversation_documentation.md` for:
- Level decision tree
- Template adaptation guide
- Workflow integration
- Quality standards

**Compatibility Analysis**: See `specs/124-feature-research-template/SPECKIT_COMPATIBILITY_ANALYSIS.md` for:
- Symlink implementation details
- Path resolution explanation
- Testing checklist

### Template Selection Guide

| LOC | Level | Templates | When |
|-----|-------|-----------|------|
| <10 | 0 | readme_template.md | Trivial fix, single file |
| <100 | 1 | spec_template.md | Simple, isolated change |
| <500 | 2 | spec_template.md + plan_template.md | Moderate feature, multiple files |
| ≥500 | 3 | Full SpecKit (spec + plan + tasks + research) | Complex feature, architectural changes |

**Optional additions**:
- Add `research_template.md` for deep technical investigation (use before research-spike for larger efforts)
- Add `research_spike_template.md` for time-boxed experiments
- Add `decision_record_template.md` for major technical decisions
- Add `tasks_template.md` to break plan into actionable items
- Add `checklist_template.md` for systematic validation

---

## 9. 🔄 RECENT UPDATES

**2025-11-25**:
- ✅ Added `/speckit.research` command - Uses `research_template.md` for comprehensive multi-domain research
- ✅ Now both research templates have corresponding commands (research + research-spike)

**2025-11-24**:
- ✅ Aligned README with create-documentation skill standards
- ✅ Added comprehensive TABLE OF CONTENTS
- ✅ Numbered all H2 sections with emojis
- ✅ Improved navigation and cross-references
- ✅ Added completeness script documentation

**2025-11-23**:
- ✅ Added `research_template.md` - Comprehensive feature research template (878 lines, 17 sections)
- ✅ Moved all files from `.claude/speckit/` to `.opencode/speckit/` (single location)
- ✅ Removed symlink - Claude can access `.opencode/` directly
- ✅ Removed duplicate `.claude/commands/speckit/` folder
- ✅ Updated ALL ~113 path references from `.claude/speckit` to `.opencode/speckit`
- ✅ Updated documentation references in `CLAUDE.md`, `AGENTS.md`, hooks, scripts, commands, and skills
- ✅ No duplicates - `.opencode/speckit/` is the single source of truth

---

**Maintained By**: Development Team
**Version**: 1.2
**Last Updated**: 2025-11-25
