# Claude Code Skills

Specialized automation workflows and AI orchestrators for development tasks. Skills provide reusable patterns, comprehensive guidance, and proven workflows for complex multi-step operations.

#### 📋 TABLE OF CONTENTS

1. [📖 OVERVIEW](#1--overview)
2. [🧩 SKILL TYPES](#2--skill-types)
3. [🎯 INSTALLED SKILLS](#3--installed-skills)
   - 3.1 [Workflow Orchestrators](#31-workflow-orchestrators-4-skills) (4 skills)
   - 3.2 [Documentation Specialists](#32-documentation-specialists-2-skills) (2 skills)
   - 3.3 [CLI Tool Wrappers](#33-cli-tool-wrappers-3-skills) (3 skills)
   - 3.4 [MCP Integration](#34-mcp-integration-2-skills) (2 skills)
   - 3.5 [Hook Creation & Management](#35-hook-creation--management-1-skill) (1 skill)
   - 3.6 [Skill Maturity Matrix](#36-skill-maturity-matrix)
4. [📁 SKILL STRUCTURE](#4--skill-structure)
5. [🔄 SKILL ACTIVATION](#5--skill-activation)
6. [🔑 PRIORITY LEVELS](#6--priority-levels)
7. [🔗 HOW SKILLS CONNECT](#7--how-skills-connect)
8. [📚 KNOWLEDGE BASE](#8--knowledge-base)
9. [⚙️ CONFIGURATION](#9-️-configuration)
10. [🛠️ CREATING NEW SKILLS](#10-️-creating-new-skills)
11. [💡 KEY BEHAVIORAL FEATURES](#11--key-behavioral-features)

---

## 1. 📖 OVERVIEW

This directory contains skills that provide structured guidance for complex development tasks.

### What are Skills?

**Skills** are specialized AI workflows that orchestrate multi-step processes:
- Provide step-by-step implementation guidance
- Enforce quality standards and best practices
- Integrate tools and external services
- Maintain consistency across implementations

### Skill vs Hook vs Knowledge

| Type | Purpose | Execution | Examples |
|------|---------|-----------|----------|
| **Skill** | Multi-step workflow orchestration | AI-invoked via Skill tool | workflows-code, workflows-save-context, create-documentation |
| **Hook** | Automated quality checks/triggers | System-invoked (before/after operations) | validate-bash, enforce-spec-folder |
| **Knowledge** | Reference documentation | AI-referenced during responses | code_standards.md, mcp_code_mode.md |

### Key Features

**Workflow Orchestration**
- Multi-phase implementations (Planning → Implementation → Verification)
- Context-aware step-by-step guidance
- Integration of multiple tools and services

**Quality & Standards**
- Enforce project-specific conventions
- Provide proven patterns and anti-patterns
- Comprehensive documentation and references

**AI Assistance**
- Context-specific skill recommendations via hooks
- Automatic skill scaffolding for new skills
- Integrated with conversation documentation system

**External Tool Integration**
- CLI wrappers for external AI tools (Codex, Gemini)
- MCP server integrations (Chrome DevTools, Semantic Search)
- Code Mode optimization for MCP operations

---

## 2. 🧩 SKILL TYPES

### 2.1 Workflow Orchestrators

**Purpose**: Guide multi-phase implementations with systematic patterns

**Characteristics**:
- Multiple reference documents (implementation, debugging, verification)
- Phase-based execution (Phase 1 → 2 → 3)
- Integration points with hooks and other skills

**Examples**:
- `workflows-code` - Development workflow orchestration (implementation, debugging, verification)
- `workflows-git` - Git workflow orchestration (worktrees, commits, completion)
- `create-parallel-sub-agents` - Dynamic sub-agent orchestration for complex multi-domain tasks

### 2.2 Documentation Specialists

**Purpose**: Create, validate, and optimize documentation

**Characteristics**:
- Document structure enforcement
- Quality analysis (C7Score)
- Auto-formatting and validation

**Examples**:
- `create-documentation` - Markdown optimization, skill creation, document validation
- `create-flowchart` - ASCII flowchart generation for workflows and decision trees
- `workflows-save-context` - Conversation context preservation and documentation

### 2.3 CLI Tool Wrappers

**Purpose**: Integrate external AI assistants as auxiliary tools

**Characteristics**:
- Parallel execution for alternative perspectives
- Specialized use cases (code review, research, analysis)
- Proper attribution and result handling

**Examples**:
- `cli-codex` - OpenAI Codex CLI integration for code generation/review
- `cli-gemini` - Google Gemini CLI integration with web search capabilities

---

## 3. 🎯 INSTALLED SKILLS

**Total**: 13 skills across 6 categories | **Latest Update**: 2025-11-27

### 3.1 Workflow Orchestrators (4 skills)

#### `create-parallel-sub-agents` (v1.0.0)

**Purpose**: Dynamic agent orchestration system that autonomously creates and dispatches specialized sub-agents for complex multi-step tasks

**Maturity**: Medium | **References**: 5 files | **Assets**: 2 files

**Key Capabilities**:
- **Task Complexity Analysis**: Calculates complexity score (0-100%) based on domains, parallelization, and dependencies
- **Hook Integration**: Reads skill recommendations from `.claude/hooks/logs/skill-recommendations.log`
- **Intelligent Sub-Agent Creation**: Creates ephemeral agents with targeted skill subsets
- **Flexible Dispatch**: Parallel, sequential, or hybrid execution strategies

**Decision Thresholds**:
- **<25% complexity**: Direct handling (no orchestration overhead)
- **25-34%**: Asks user preference (collaborative decision)
- **≥35%**: Auto-dispatch sub-agents (maximum efficiency)

**Key References**:
- `complexity_scoring.md` - Task complexity heuristics and scoring algorithm
- `skill_clustering.md` - Domain-based skill grouping strategies
- `dispatch_decision.md` - When to dispatch vs direct handling
- `sub_agent_lifecycle.md` - Agent creation, dispatch, integration, cleanup
- `quick_reference.md` - One-page orchestrator cheat sheet

**When to Use**:
- Complex multi-domain tasks (code + docs + git + testing)
- Tasks spanning 3+ functional domains
- Opportunities for parallel execution
- Multiple independent failures to investigate

**Example**:
```
Implementing authentication with tests and docs:
→ Complexity: 85% (3 domains: code, testing, documentation)
→ Auto-dispatch: 3 parallel agents
  - Agent 1: Code domain (code-standards, workflows-code)
  - Agent 2: Test domain (test patterns, verification)
  - Agent 3: Docs domain (create-documentation)
→ Result: 60% faster than sequential, integrated results
```

**Integration Points**:
- Reads from: `.claude/hooks/logs/skill-recommendations.log`
- Coordinates: Other workflow skills (workflows-code, workflows-git, create-documentation)
- Logs to: `.claude/hooks/logs/orchestrator.log`


#### `workflows-code` (v2.0.0)

**Purpose**: Development workflow orchestration across implementation, debugging, and verification phases

**Maturity**: Very High | **References**: 11 files | **Assets**: 4 files

**Phases**:
- **Phase 1 (Implementation)**: Condition-based waiting, defense-in-depth validation, CDN versioning, performance patterns, security patterns
- **Phase 2 (Debugging)**: Systematic debugging, root cause tracing, performance debugging
- **Phase 3 (Verification)**: MANDATORY browser verification before completion claims

**Key References**:
- `implementation_workflows.md` - Async handling, validation, cache-busting
- `performance_patterns.md` - Animation optimization, asset optimization, request optimization
- `security_patterns.md` - OWASP Top 10 security checklist
- `debugging_workflows.md` - DevTools-based debugging, performance profiling
- `verification_workflows.md` - Browser testing requirements
- `quick_reference.md` - One-page cheat sheet

**When to Use**:
- Implementing frontend features
- Debugging console errors or performance issues
- Before claiming "works", "fixed", or "complete"

**Example**:
```
Implementing async form submission with validation:
→ Phase 1: Use condition-based waiting + defense-in-depth patterns
→ Phase 2: Debug any race conditions with systematic debugging
→ Phase 3: Verify in browser (desktop + mobile) before claiming complete
```


#### `workflows-git` (v1.0.0)

**Purpose**: Git workflow orchestration for worktrees, clean commits, and work completion

**Maturity**: Medium | **References**: 5 files | **Assets**: 3 files

**Phases**:
- **Worktrees**: Safe parallel work on multiple features
- **Commits**: Clean, conventional commits with AI assistance
- **Completion**: PR creation, branch cleanup, verification

**Key Features**:
- Prevents direct commits to main/master
- Enforces conventional commit format
- Guides PR creation with gh CLI
- Automated cleanup workflows

**When to Use**:
- Starting new feature work
- Creating clean commits
- Completing and merging work

**Example**:
```
Starting new feature:
→ Create worktree for feature branch
→ Make changes + create conventional commits
→ Create PR with descriptive summary
→ Clean up worktree after merge
```


#### `workflows-conversation` (v1.0.0)

**Purpose**: Mandatory spec folder workflow orchestrating documentation level selection (0-3) and folder creation for all file modifications

**Maturity**: Medium-High (Mandatory) | **References**: 4 files | **Assets**: 2 files

**Key Features**:
- **Hook-Assisted Enforcement**: Automatically prompts for spec folder before file modifications
- **4-Level Decision Framework**: Level 0 (Minimal) → Level 3 (Complete SpecKit)
- **Template Integration**: Automated template selection based on documentation level
- **Skip Option**: Option D for trivial explorations (creates technical debt warning)

**Decision Levels**:
- **Level 0 (<10 LOC)**: README.md only - Trivial fixes
- **Level 1 (<100 LOC)**: spec.md + optional checklist.md - Simple isolated changes
- **Level 2 (<500 LOC)**: spec.md + plan.md + optional tasks.md - Moderate features
- **Level 3 (≥500 LOC)**: Full SpecKit - Complex features with ADRs, spikes

**When to Use**:
- Before ANY file modifications (code, docs, config, templates)
- Automatically triggered by hooks on file change intent
- Mandatory for all conversations involving file modifications

**Sub-Folder Versioning** (New in v1.1.0):
- **Automatic numbered sub-folders** when reusing spec folders
- **Format**: `001-{name}/`, `002-{name}/`, `003-{name}/` etc.
- **Archive**: Existing content moved to `001-{topic}/` automatically
- **Memory isolation**: Each sub-folder has independent `memory/` directory
- **Use case**: Iterative work on same specification (multiple alignment tasks, bug fixes, enhancements)
- **Example**:
  ```
  specs/122-skill-standardization/
  ├── 001-cli-codex-alignment/
  ├── 002-workflows-conversation/
  └── 003-spec-folder-versioning/  ← Active
  ```

**Example**:
```
Implementing new form validation:
→ Hook detects file modification intent
→ Prompts for spec folder selection
→ User chooses Level 2 (moderate complexity)
→ Creates specs/123-form-validation/ with spec.md + plan.md
→ Proceeds with implementation

Reusing existing spec folder:
→ User selects Option A (use existing specs/122-skill-standardization/)
→ Hook detects root-level files (migration needed)
→ AI prompts for new sub-folder name: "versioning-enhancement"
→ AI executes: .claude/hooks/lib/migrate-spec-folder.sh specs/122-skill-standardization versioning-enhancement
→ Script creates 001-skill-standardization/ (archive) + 002-versioning-enhancement/ (active)
→ Script updates .spec-active marker to point to new sub-folder
→ Each has independent memory/ folder for context saves
```


#### `workflows-save-context` (v1.2.0)

**Purpose**: Automatic conversation context preservation triggered by keywords or every 20 messages

**Maturity**: High | **References**: 2 files | **Scripts**: 1 file (generate-context.js)

**Key Features**:
- **Auto-Trigger System**: Activates on keywords ("save context", "save conversation") OR every 20 messages
- **Timestamped Memory Files**: `DD-MM-YY_HH-MM__topic.md` in `specs/###-feature/memory/` or sub-folder memory/
- **Sub-Folder Awareness**: Routes to active sub-folder's memory/ using `.spec-active` marker
- **Visual Documentation**: Auto-generated flowcharts and decision trees
- **Spec Folder Alignment**: 70% threshold alignment detection, interactive prompt if low
- **Parallel Processing**: Promise.all() for 40-60% faster execution

**Output Files**:
- Timestamped markdown: `{date}_{time}__{topic}.md` with full conversation flow
- Metadata JSON: `metadata.json` with session stats (message/decision/diagram counts)

**When to Use**:
- Completing significant implementation sessions
- Documenting architectural discussions
- Preserving complex debugging sessions
- Auto-triggered every 20 messages (context budget management)

**Example**:
```
After implementing authentication system:
→ Automatically triggered at 20 messages
→ Creates memory/22-11-25_14-23__auth-system.md
→ Includes JWT decision rationale, auth flow diagram, full conversation
→ Updates metadata.json with session stats
```

---

### 3.2 Documentation Specialists (2 skills)

#### `create-documentation` (v3.2.0)

**Purpose**: Unified markdown and skill management with quality enforcement

**Maturity**: Very High | **References**: 6 files | **Assets**: 5 files | **Scripts**: 4 files

**Capabilities**:
- **Document Optimization**: C7Score analysis, structure validation, AI consumption optimization
- **Skill Creation**: Scaffolding, validation, best practices enforcement
- **Quality Analysis**: Structure checking, frontmatter validation, style enforcement

**Commands**:
```bash
# Validate document structure
create-documentation validate --file path/to/doc.md

# Analyze and fix issues
create-documentation validate --file path/to/doc.md --fix

# Create new skill structure
create-documentation create-skill --name my-skill
```

**When to Use**:
- Creating or updating markdown documentation
- Building new skills
- Validating documentation quality
- Optimizing docs for AI consumption

**Example**:
```
Creating new skill:
→ create-documentation create-skill --name my-workflow
→ Auto-scaffolds SKILL.md, references/, assets/
→ Provides structure templates and validation
```


#### `create-flowchart` (v1.1.0)

**Purpose**: Generate comprehensive ASCII flowcharts for visualizing workflows

**Maturity**: Medium-High | **References**: 6 files | **Scripts**: 1 file (validate.sh)

**Supports**:
- Sequential workflows (linear pattern)
- Parallel execution (concurrent blocks)
- Decision trees with branching
- Multi-path flows with approval gates
- Nested processes with hierarchy

**When to Use**:
- Documenting complex workflows
- Visualizing user journeys
- Mapping system architectures
- Creating decision tree documentation

**Example**:
```
Documenting approval workflow:
→ Skill(skill: "create-flowchart")
→ Generates ASCII diagram with:
  - Multiple approval gates
  - Parallel execution paths
  - Clear visual hierarchy
```

---

### 3.3 CLI Tool Wrappers (3 skills)

#### `cli-codex` (v1.0.0)

**Purpose**: Integrate OpenAI Codex CLI for code generation and review

**Maturity**: Medium | **References**: 5 files | **Model**: GPT-5.1 Codex

**Use Cases**:
- Alternative code generation perspective
- Code review from different AI model
- Parallel implementation approaches
- Specialized code analysis tasks

**When to Use**:
- Task benefits from second AI perspective
- Need alternative implementation approach
- Code review requirements
- User explicitly requests Codex

**Example**:
```
Reviewing complex algorithm:
→ Skill(skill: "cli-codex")
→ Sends code to Codex for review
→ Returns alternative perspectives and improvements
```


#### `cli-gemini` (v1.1.0)

**Purpose**: Integrate Google Gemini CLI with web search capabilities

**Maturity**: High | **References**: 4 files | **Model**: Gemini 3 Pro

**Use Cases**:
- Current web information via Google Search
- Codebase architecture analysis
- Research tasks requiring latest docs
- Alternative AI perspective

**Key Features**:
- Access to current web information (beyond knowledge cutoff)
- Google Search integration for recent documentation
- Parallel code generation capabilities
- Multi-modal analysis

**When to Use**:
- Need current web information
- Research latest framework versions
- Compare multiple AI perspectives
- User explicitly requests Gemini

**Example**:
```
Researching latest API changes:
→ Skill(skill: "cli-gemini")
→ Searches web for latest documentation
→ Returns current best practices (post knowledge cutoff)
```

#### `cli-chrome-devtools` (v1.0.0)

**Purpose**: Direct Chrome DevTools Protocol access via browser-debugger-cli (bdg) terminal commands

**Maturity**: Medium | **References**: 3 files | **Tool**: browser-debugger-cli (bdg)

**Use Cases**:
- Lightweight browser debugging via terminal
- Quick screenshots, HAR files, console logs
- DOM inspection and JavaScript execution
- Alternative to Puppeteer/Playwright for simple tasks
- Token-efficient browser automation

**Key Features**:
- Self-documenting tool discovery (--list, --describe, --search)
- Direct CDP access to all 644 methods
- Unix pipe composability for workflows
- Session-based state management
- Minimal setup (npm install -g browser-debugger-cli@alpha)

**When to Use**:
- Quick debugging/inspection tasks
- Terminal-first workflow preferred
- Token efficiency is priority
- Alternative to MCP Chrome DevTools for simple browser tasks

**Example**:
```bash
# Screenshot capture
bdg --url https://example.com Page.captureScreenshot

# Console log monitoring
bdg --url https://example.com Runtime.enable | bdg Runtime.consoleAPICalled
```

**Tool Comparison**:
- **bdg (CLI)**: Lowest token cost, self-documenting, terminal-native
- **Chrome DevTools MCP**: Multi-tool integration, type-safe, IDE-based
- **Puppeteer/Playwright**: Complex UI testing, heavy automation

---

### 3.4 MCP Integration (2 skills)

#### `mcp-code-mode` (v1.0.0)

**Purpose**: MCP orchestration via TypeScript execution for efficient multi-tool workflows

**Maturity**: Medium-High (Mandatory for all MCP calls) | **References**: 5 files | **Assets**: 2 files | **Scripts**: 1 file

**Key Features**:
- **Progressive Tool Loading**: Tools discovered on-demand, zero upfront cost
- **Context Reduction**: 98.7% reduction (1.6k tokens vs 141k for 47 tools)
- **Execution Speed**: 60% faster than traditional tool calling (single execution vs 15+ API round trips)
- **Type Safety**: Full TypeScript support with autocomplete
- **Tool Coverage**: 200+ MCP tools (ClickUp, Notion, Figma, Webflow, Chrome DevTools, etc.)

**Critical Pattern**:
```typescript
// REQUIRED naming pattern for all MCP tool calls
{manual_name}.{manual_name}_{tool_name}

// Examples:
await webflow.webflow_sites_list({});
await clickup.clickup_create_task({...});
await figma.figma_get_file({...});
```

**When to Use**:
- **MANDATORY for ALL MCP tool calls**
- Calling ClickUp, Notion, Figma, Webflow, Chrome DevTools, or any MCP tools
- Managing tasks in project management tools
- Browser automation and web interactions
- Multi-tool workflows requiring state persistence

**Configuration Requirements**:
- `.utcp_config.json` - MCP server definitions
- `.env` - API keys and environment variables
- Validation script: `scripts/validate_config.py`

**Example**:
```
Multi-tool workflow (Figma → ClickUp → Webflow):
→ Step 1: Search tools via progressive discovery
→ Step 2: Execute via call_tool_chain with TypeScript
→ Step 3: State persists across tool calls (atomic execution)
→ Result: 5× faster than sequential individual tool calls
```

**Common Mistake**:
```typescript
❌ await webflow.sites_list({});        // Missing manual prefix
✅ await webflow.webflow_sites_list({}); // Correct naming pattern
```


#### `mcp-semantic-search` (v1.0.0)

**Purpose**: Intent-based code discovery using natural language queries for CLI AI agents

**Maturity**: Medium (CLI AI agents only - NOT IDE integrations) | **References**: 3 files | **Assets**: 1 file

**Key Features**:
- **Intent-Based Discovery**: Search by what code does, not what it's called
- **Natural Language Queries**: "Find code that handles authentication" vs `grep -r "auth"`
- **Semantic Understanding**: Uses voyage-3 judge model for relevance ranking
- **Codebase Coverage**: 249 files indexed with automatic background indexing
- **Availability**: CLI AI agents only (Claude Code AI, GitHub Copilot CLI) - NOT IDE extensions

**When to Use**:
- **REQUIRED when exploring code functionality** (CLI AI agents)
- Finding code by behavior vs keywords
- Understanding feature implementations
- Locating patterns across multiple files
- Exploring unfamiliar codebase areas

**Priority Over Native Tools**:
- Use semantic search FIRST before grep/read when exploring code
- Grep for literal text matching, semantic search for intent-based discovery

**Example**:
```
Finding authentication logic:
→ search_codebase("authentication implementation")
→ Returns: src/auth/authenticate.ts, src/middleware/auth.ts, src/utils/jwt.ts
→ Ranked by semantic relevance, not keyword matching
```

**Availability Note**:
```
✅ Claude Code AI (CLI)
✅ GitHub Copilot CLI
❌ VS Code extensions
❌ IDE integrations
```

---

### 3.5 Hook Creation & Management (1 skill)

#### `create-hooks` (v1.0.0)

**Purpose**: Comprehensive hook creation documentation for Claude Code's 8 hook types providing templates, payload structures, best practices, and testing strategies

**Maturity**: Medium | **References**: 5 files | **Assets**: 8 files | **Scripts**: 2 files

**Key Capabilities**:
- **8 Hook Types Coverage**: PreCompact, UserPromptSubmit, PreToolUse, PostToolUse, PreRead, PostRead, PreResponse, PostResponse
- **Template Provision**: Ready-to-use templates for each hook type with payload structures
- **Testing Strategies**: Comprehensive testing guide with validation workflows
- **Production Examples**: Real-world hook implementations and best practices

**Hook Lifecycle Phases**:
- **Pre-Execution**: PreCompact (context optimization)
- **User Prompt Processing**: UserPromptSubmit (validation, suggestions)
- **Tool Execution**: PreToolUse, PostToolUse (tool validation, result processing)
- **File Operations**: PreRead, PostRead (file access control)
- **Response Generation**: PreResponse, PostResponse (quality checks, formatting)

**When to Use**:
- Creating custom automation workflows
- Building project-specific quality checks
- Implementing automated triggers
- Understanding hook system architecture
- Extending Claude Code with custom tooling

**Example**:
```bash
Creating custom quality check hook:
→ Skill(skill: "create-hooks")
→ Select hook type: PostToolUse (after tool execution)
→ Use template from assets/hook_template_PostToolUse.sh
→ Implement validation logic
→ Test with validation script
→ Deploy to .claude/hooks/PostToolUse/
```

**Integration Points**:
- Works with: create-documentation (documenting hooks), workflows-code (testing hooks)
- Triggered by: workflows-conversation (hooks enforce spec folder creation)
- Foundation for: All hook-assisted workflows in the system

---

### 3.6 Skill Maturity Matrix

**Overview**: All 13 skills across 6 categories with version, maturity, and documentation metrics

| Skill | Version | Maturity | Category | References | Assets | Scripts |
|-------|---------|----------|----------|------------|--------|---------|
| create-documentation | v3.2.0 | ★★★★★ Very High | Documentation | 6 | 6 | 4 |
| workflows-code | v2.0.0 | ★★★★★ Very High | Orchestrator | 11 | 4 | 0 |
| workflows-save-context | v1.2.0 | ★★★★ High | Orchestrator | 2 | 0 | 1 |
| cli-gemini | v1.1.0 | ★★★★ High | CLI Wrapper | 4 | 0 | 0 |
| cli-chrome-devtools | v1.0.0 | ★★★ Medium | CLI Wrapper | 3 | 0 | 0 |
| create-flowchart | v1.1.0 | ★★★★ High | Documentation | 6 | 0 | 1 |
| workflows-conversation | v1.0.0 | ★★★★ Medium-High | Orchestrator | 4 | 2 | 0 |
| mcp-code-mode | v1.0.0 | ★★★★ Medium-High | MCP Integration | 5 | 2 | 1 |
| workflows-git | v1.0.0 | ★★★ Medium | Orchestrator | 5 | 3 | 0 |
| mcp-semantic-search | v1.0.0 | ★★★ Medium | MCP Integration | 3 | 1 | 0 |
| create-parallel-sub-agents | v1.0.0 | ★★★ Medium | Orchestration | 5 | 2 | 0 |
| create-hooks | v1.0.0 | ★★★ Medium | Hook Creation | 5 | 8 | 2 |
| cli-codex | v1.0.0 | ★★★ Medium | CLI Wrapper | 4 | 0 | 0 |

**Maturity Levels**:
- ★★★★★ **Very High** (v2.0+): Battle-tested, comprehensive documentation, actively maintained
- ★★★★ **High** (v1.2+): Stable, well-documented, feature-complete
- ★★★ **Medium** (v1.0.0): Stable foundation, complete documentation, ready for production
- ★★ **Low** (v0.x): Experimental, incomplete documentation, use with caution
- ★ **Experimental** (v0.1): Alpha stage, documentation in progress, not recommended for production

**Version Distribution**:
- v3.x: 1 skill (8%) - Most mature
- v2.x: 1 skill (8%) - Major update
- v1.2+: 1 skill (8%) - Minor updates
- v1.1.x: 2 skills (15%) - Minor updates
- v1.0.0: 8 skills (62%) - Stable releases

**Documentation Metrics**:
- **Average References**: 5.4 files per skill
- **Average Assets**: 2.3 files per skill
- **Average Scripts**: 0.8 files per skill
- **Total Documentation**: 102 files across all skills

**Mandatory Skills** (Required for specific operations):
- 🔴 **workflows-conversation**: ALL file modifications
- 🔴 **mcp-code-mode**: ALL MCP tool calls
- 🟡 **workflows-save-context**: Context preservation (auto-triggered)
- 🟡 **mcp-semantic-search**: Code exploration (CLI AI agents only)

---

## 4. 📁 SKILL STRUCTURE

### Standard Directory Layout

```
.claude/skills/
└── skill-name/
    ├── SKILL.md              # Main skill documentation (REQUIRED)
    ├── references/           # Detailed reference docs (OPTIONAL)
    │   ├── pattern_name.md
    │   └── workflow_details.md
    ├── assets/               # Code templates, examples (OPTIONAL)
    │   ├── template.js
    │   └── checklist.md
    ├── scripts/              # Helper scripts (OPTIONAL)
    │   └── process.js
    └── config.jsonc          # Skill configuration (OPTIONAL)
```

### SKILL.md Structure

**Required frontmatter**:
```yaml
---
name: skill-name
description: Brief description (used by hooks for recommendations)
allowed-tools: [Read, Write, Bash, Grep, etc.]
version: 1.0.0
---
```

**Required sections**:
1. **Title + Subtitle** - `# Skill Name - Brief Description`
2. **When to Use** - Triggering conditions and use cases
3. **How to Use** - Step-by-step implementation guide
4. **Rules** - ALWAYS, NEVER, ESCALATE IF guidelines
5. **Success Criteria** - What defines completion
6. **Examples** - Practical usage scenarios

**Optional sections**:
- Quick Reference - One-page summary
- Troubleshooting - Common issues and solutions
- Integration Points - Connections to other skills/hooks
- References - Links to related documentation

### Auto-Scaffolding

When creating `SKILL.md`, the `skill-scaffold-trigger` hook automatically creates:
- `references/` directory with placeholder README
- `assets/` directory with guidelines README
- Next steps documentation

---

## 5. 🔄 SKILL ACTIVATION

### How Skills Are Invoked

**1. Explicit Invocation** (Manual)
```javascript
// Claude activates skill directly
Skill({ skill: "skill-name" })
```

**2. Hook Suggestion** (Automatic)
```
User: "I need to create a PR for this feature"
Hook: 🟡 RECOMMENDED SKILL: workflows-git
AI: [Evaluates and activates if appropriate]
```

**3. Mandatory Activation** (Enforced)
```
Hook: 🔴 MANDATORY SKILL: code-standards
AI: [MUST evaluate and apply before proceeding]
```

### Activation Decision Process

```mermaid
User Prompt
    ↓
Hook Suggests Skills (validate-skill-activation.sh)
    ↓
AI Evaluates Each Skill:
  - MANDATORY skills → Must apply
  - HIGH priority → Strongly recommended
  - MEDIUM priority → Consider using
    ↓
AI Makes Decision:
  YES → Activates skill
  NO  → Explains why not applicable
    ↓
Skill Executes → Provides Guidance
```

### Mandatory Skill Evaluation Format

When hooks suggest MANDATORY skills, AI must provide explicit evaluation:

```
[code-standards]: YES/NO - [brief reason]
[conversation-documentation]: YES/NO - [brief reason]
```

**Example**:
```
[code-standards]: YES - Making code changes requiring naming convention compliance
[conversation-documentation]: NO - Read-only analysis, no file modifications
```

---

## 6. 🔑 PRIORITY LEVELS

Skills are configured in `.claude/configs/skill-rules.json` with priority levels:

### CRITICAL Priority

**Enforcement**: MANDATORY - AI must evaluate before proceeding

**Skills**:
- `code-standards` - Naming conventions, file headers, commenting rules
- `conversation-documentation` - Spec folder system for all file modifications

**When Applied**:
- Always active for code/file modifications
- Blocks implementation without explicit YES/NO evaluation

**Example Output**:
```
🔴 MANDATORY SKILLS - MUST BE APPLIED:
⚠️  Proceeding without these skills will result in incomplete/incorrect implementation.

   • code-standards - Naming conventions, file headers, commenting rules
   • conversation-documentation - Mandatory spec folder system

───────────────────────────────────────────────────────────────
⚡ MANDATORY SKILL EVALUATION - REQUIRED BEFORE IMPLEMENTATION
───────────────────────────────────────────────────────────────

You MUST evaluate each skill above before proceeding:
[skill-name]: YES/NO - [your reason]
```

### HIGH Priority

**Enforcement**: STRONGLY RECOMMENDED - AI should use unless clear reason not to

**Skills**:
- `workflows-code` - Implementation, debugging, verification workflows
- `workflows-git` - Git operations, commits, PR creation
- `create-parallel-sub-agents` - Dynamic sub-agent orchestration for complex multi-domain tasks
- `workflows-save-context` - Context preservation at conversation milestones

**When Applied**:
- Feature implementations → workflows-code
- Git operations → workflows-git
- Complex multi-domain tasks → create-parallel-sub-agents
- Long conversations → workflows-save-context

### MEDIUM Priority

**Enforcement**: SUGGESTED - AI considers based on context

**Skills**:
- `create-documentation` - Documentation creation/validation
- `create-flowchart` - Complex workflow visualization
- `cli-codex` - Alternative AI perspectives
- `cli-gemini` - Web research and current information

**When Applied**:
- Creating documentation → create-documentation
- Need flowchart → create-flowchart
- Need web search → cli-gemini

---

## 7. 🔗 HOW SKILLS CONNECT

### Connection Flow

```text
User Request
    ↓
┌─────────────────────────────────────────────────────────────┐
│ Hook: validate-skill-activation.sh                          │
│ - Reads skill-rules.json                                    │
│ - Matches keywords + patterns in prompt                     │
│ - Returns CRITICAL/HIGH/MEDIUM priority suggestions         │
│ - Provides documentation guidance                           │
└────────┬────────────────────────────────────────────────────┘
         │
         ▼
┌─────────────────────────────────────────────────────────────┐
│ AI Evaluation                                               │
│ - Reviews mandatory skills (CRITICAL priority)              │
│ - Provides explicit YES/NO with reason                      │
│ - Activates applicable skills                               │
└────────┬────────────────────────────────────────────────────┘
         │
         ▼
┌─────────────────────────────────────────────────────────────┐
│ Skill Execution                                             │
├─────────────────────────────────────────────────────────────┤
│ workflows-code:                                             │
│ → references/implementation_workflows.md                    │
│ → references/performance_patterns.md                        │
│ → references/security_patterns.md                           │
│ → references/debugging_workflows.md                         │
│                                                             │
│ workflows-save-context:                                     │
│ → scripts/generate-context.js                               │
│ → Writes to specs/###-folder/memory/                        │
│ → Creates metadata.json with session stats                  │
│                                                             │
│ create-documentation:                                       │
│ → scripts/analyze_docs.py (C7Score)                         │
│ → Validates structure, frontmatter                          │
│ → Auto-fixes style issues                                   │
└─────────────────────────────────────────────────────────────┘
```

### Skill Dependencies & Pairing Patterns

#### Foundational Skills (Required by Others)

**workflows-conversation** (Mandatory)
- **Required by**: ALL workflow skills when modifying files
- **Purpose**: Spec folder creation before file modifications
- **Enforcement**: Hook-based, blocks file modifications without spec folder
- **Usage**: Auto-triggered by file change detection

**mcp-code-mode** (Mandatory for MCP)
- **Required by**: ALL skills calling MCP tools (ClickUp, Notion, Figma, Webflow, Chrome DevTools, etc.)
- **Purpose**: Efficient MCP tool orchestration with context reduction
- **Enforcement**: Mandatory for all external tool integration
- **Usage**: Explicitly invoked via `call_tool_chain` with TypeScript

**create-documentation** (Foundational)
- **Required for**: New skill creation, documentation validation
- **Purpose**: Skill scaffolding and quality enforcement
- **Enforcement**: Recommended for all documentation work
- **Usage**: Manual invocation or hook-triggered

#### Common Pairing Patterns

**Pattern 1: Complete Development Cycle**
```
workflows-conversation (spec folder)
  → workflows-code (implementation + debugging + verification)
    → workflows-git (commit + PR)
      → workflows-save-context (documentation)
```
**Use when**: Implementing features from start to finish

**Pattern 2: MCP-Powered Workflows**
```
mcp-semantic-search (code discovery)
  → mcp-code-mode (tool orchestration)
    → workflows-code (verification)
```
**Use when**: External tool integration with code exploration

**Pattern 3: Auxiliary AI Verification**
```
workflows-code (implementation)
  → cli-gemini or cli-codex (review)
    → workflows-code (fixes)
      → workflows-git (commit)
```
**Use when**: Need second opinion before committing

**Pattern 4: Dynamic Agent Orchestration**
```
create-parallel-sub-agents (complexity analysis)
  → Dispatches: workflows-code + create-documentation + workflows-git (parallel)
    → Integrates results
      → workflows-save-context (documentation)
```
**Use when**: Complex multi-domain tasks (code + docs + git + testing)

**Pattern 5: Documentation Workflow**
```
create-documentation (validation)
  → create-flowchart (visualization)
    → workflows-save-context (preservation)
```
**Use when**: Creating comprehensive documentation with diagrams

#### Dependency Graph

**Upstream Dependencies** (foundational, used by many):
- `workflows-conversation` ← Required by all workflow skills
- `create-documentation` ← Required for skill creation/validation
- `mcp-code-mode` ← Required for all MCP tool calls

**Downstream Usage** (skills that consume others):
- `workflows-code` → Can use `cli-gemini`, `cli-codex` (Phase 2 verification)
- `workflows-git` → Referenced by `workflows-code` (Phase 3 completion)
- `workflows-save-context` → Triggered by `workflows-conversation` (auto-save)
- `create-parallel-sub-agents` → Can dispatch ALL skills as sub-agents

**Integration Pairing**:
- `mcp-code-mode` + `mcp-semantic-search` - MCP orchestration with code discovery
- `workflows-code` + `workflows-git` - Complete implementation to commit cycle
- `create-documentation` + `create-flowchart` - Documentation suite
- `cli-codex` + `cli-gemini` - Multi-AI perspective comparison

### Cross-Skill Integration (Legacy)

**workflows-code ↔ workflows-git**
- workflows-code Phase 3 (Verification) → triggers workflows-git for commit/PR
- workflows-git completion → may trigger workflows-save-context for documentation

**workflows-save-context ↔ workflows-conversation**
- workflows-conversation enforces spec folder existence
- workflows-save-context writes to spec folder's memory/ subdirectory
- Both use same spec folder numbering convention

**create-documentation ↔ hooks**
- enforce-markdown-strict.sh → Uses create-documentation for validation
- skill-scaffold-trigger.sh → Creates structure following create-documentation standards
- enforce-markdown-post.sh → Follows create-documentation naming conventions

**cli-codex / cli-gemini ↔ workflows-code**
- Can be used in workflows-code Phase 2 (Debugging) for alternative perspectives
- Proper attribution required (Co-Authored-By in commits)
- Results integrated into main workflow

---

## 8. 📚 KNOWLEDGE BASE

Skills reference knowledge base files in `.claude/knowledge/`:

### Core Standards

**`code_standards.md`**
- Naming conventions (kebab-case, camelCase, PascalCase rules)
- File organization and structure
- Commenting and documentation standards
- Git commit message format
- Used by: code-standards skill (alwaysActive)

**`conversation_documentation.md`**
- Spec folder system (4 levels: Minimal, Concise, Standard, Complete)
- Documentation requirements for file modifications
- Template usage and structure
- Used by: conversation-documentation skill (alwaysActive)

### Domain-Specific Patterns

**`initialization_pattern.md`**
- CDN-safe initialization patterns
- Library loading and dependency management
- Async script handling
- Used by: workflows-code skill (code_quality_standards.md)

**Note:** Animation and Webflow patterns have been integrated into the workflows-code skill:
- Animation patterns: See `.claude/skills/workflows-code/references/animation_workflows.md`
- Webflow patterns: See `.claude/skills/workflows-code/references/webflow_patterns.md`

### MCP Integration

**`mcp_code_mode.md`**
- Code Mode usage for MCP tools (68% fewer tokens, 98.7% overhead reduction)
- Tool naming conventions ({manual_name}.{manual_name}_{tool_name})
- Progressive tool discovery patterns
- Used by: hooks (suggest-code-mode.sh, validate-mcp-calls.sh)

**`mcp_semantic_search.md`**
- Intent-based code discovery (vs keyword matching)
- search_codebase and search_commits usage
- Integration with Code Mode
- Used by: hooks (suggest-semantic-search.sh)

---

## 9. ⚙️ CONFIGURATION

### `.claude/configs/skill-rules.json`

**Purpose**: Central configuration for skill definitions and triggers

**Structure**:
```json
{
  "skills": {
    "skill-name": {
      "type": "workflow|documentation|cli-tool|knowledge",
      "enforcement": "strict|suggest",
      "priority": "critical|high|medium",
      "description": "Brief description",
      "promptTriggers": {
        "keywords": ["word1", "word2"],
        "intentPatterns": ["pattern1", "pattern2"]
      },
      "fileTriggers": {
        "pathPatterns": ["src/**/*.js"],
        "contentPatterns": ["pattern"]
      },
      "alwaysActive": true|false
    }
  }
}
```

**Used By**:
- `validate-skill-activation.sh` hook → Reads skill definitions for prompt matching
- `validate-post-response.sh` hook → Reads riskPatterns for quality checks

**Example Entry**:
```json
{
  "workflows-code": {
    "type": "workflow",
    "enforcement": "strict",
    "priority": "high",
    "description": "Development workflow orchestration (implementation, debugging, verification)",
    "promptTriggers": {
      "keywords": ["implement", "debug", "fix", "verify", "animation", "async"],
      "intentPatterns": [
        "implement.*feature",
        "fix.*bug",
        "debug.*issue",
        "verify.*works"
      ]
    },
    "fileTriggers": {
      "pathPatterns": ["src/**/*.js", "src/**/*.css"],
      "contentPatterns": ["addEventListener", "async", "fetch"]
    }
  }
}
```

### Skill Types

| Type | Purpose | Examples | Characteristics |
|------|---------|----------|-----------------|
| **workflow** | Multi-phase orchestration | workflows-code, workflows-git, create-parallel-sub-agents | Phase-based, comprehensive references |
| **documentation** | Doc creation/validation | workflows-save-context, create-documentation | Structure enforcement, quality analysis |
| **cli-tool** | External tool integration | cli-codex, cli-gemini | Parallel execution, attribution required |
| **knowledge** | Reference documentation | code-standards, animation-strategy | Always-active, no execution logic |

---

## 10. 🛠️ CREATING NEW SKILLS

### Quick Start

```bash
# Option 1: Use create-documentation skill
create-documentation create-skill --name my-workflow

# Option 2: Manual creation (auto-scaffolds on SKILL.md write)
mkdir -p .claude/skills/my-workflow
# Create SKILL.md with required frontmatter
# Hook auto-creates references/ and assets/ directories
```

### Required Frontmatter

```yaml
---
name: my-workflow
description: Brief one-line description (shows in hook suggestions)
allowed-tools: [Read, Write, Bash, Grep, Glob]
version: 1.0.0
---
```

### Frontmatter Fields

**Required**:
- `name` - Skill identifier (kebab-case, matches directory name)
- `description` - One-line description (used by hooks for recommendations)
- `allowed-tools` - Array of Claude Code tools this skill can use
- `version` - Semantic version (MAJOR.MINOR.PATCH)

**Optional**:
- `author` - Skill creator
- `created` - Creation date (YYYY-MM-DD)
- `updated` - Last update date (YYYY-MM-DD)
- `tags` - Array of searchable tags

### Content Structure

**Section 1: When to Use**
- Clear triggering conditions
- Use cases and examples
- When NOT to use (prevent false positives)

**Section 2: How to Use**
- Step-by-step implementation guide
- Tool invocations with examples
- Expected inputs and outputs

**Section 3: Rules**
- ALWAYS - Required behaviors
- NEVER - Prohibited actions
- ESCALATE IF - When to ask for help

**Section 4: Success Criteria**
- What defines successful completion
- Verification steps
- Performance expectations

**Section 5: Examples**
- Real-world usage scenarios
- Before/after comparisons
- Common patterns

### Creating References

```bash
# Auto-created by skill-scaffold-trigger.sh hook
.claude/skills/my-workflow/
├── references/
│   ├── README.md                    # Auto-generated placeholder
│   ├── implementation_guide.md      # Add your detailed docs
│   └── troubleshooting.md
```

**Best Practices**:
- Keep SKILL.md concise (navigation + overview)
- Move detailed content to references/
- Use descriptive filenames (workflow_details.md, api_reference.md)
- Link from SKILL.md to references for deep dives

### Creating Assets

```bash
.claude/skills/my-workflow/
├── assets/
│   ├── README.md              # Auto-generated guidelines
│   ├── template.js            # Code templates
│   ├── checklist.md           # Validation checklists
│   └── example_config.json    # Configuration examples
```

**Asset Types**:
- **Templates** - Reusable code patterns
- **Checklists** - Step-by-step validation lists
- **Examples** - Reference implementations
- **Schemas** - Configuration validation schemas

### Adding to skill-rules.json

```json
{
  "skills": {
    "my-workflow": {
      "type": "workflow",
      "enforcement": "suggest",
      "priority": "medium",
      "description": "My custom workflow for X",
      "promptTriggers": {
        "keywords": ["keyword1", "keyword2"],
        "intentPatterns": ["implement.*X", "create.*Y"]
      },
      "fileTriggers": {
        "pathPatterns": ["src/**/*.ext"],
        "contentPatterns": ["pattern"]
      }
    }
  }
}
```

**Validation**:
```bash
# Validate skill-rules.json after changes
bash .claude/hooks/scripts/validate-config.sh
```

### Testing New Skills

**Manual Testing**:
```javascript
// Test skill invocation
Skill({ skill: "my-workflow" })
```

**Hook Integration Testing**:
```bash
# Verify skill appears in suggestions
# Use keywords from promptTriggers in prompt
# Check .claude/hooks/logs/skill-recommendations.log
```

**Documentation Testing**:
```bash
# Validate SKILL.md structure
create-documentation validate --file .claude/skills/my-workflow/SKILL.md

# Check C7Score
create-documentation validate --file .claude/skills/my-workflow/SKILL.md --analyze
```

---

## 11. 💡 KEY BEHAVIORAL FEATURES

### Auto-Scaffolding

When you create a new `SKILL.md` file, the `skill-scaffold-trigger.sh` hook automatically:
- Creates `references/` directory with README placeholder
- Creates `assets/` directory with guidelines
- Provides next steps guidance
- Shows example skill structure

**Benefit**: Instant setup with best practices baked in

### Skill Recommendations

The `validate-skill-activation.sh` hook suggests skills based on:
- **Keywords** - Matches words in prompt against skill definitions
- **Intent patterns** - Matches regex patterns for common tasks
- **File triggers** - Activates when specific files are modified

**Example**:
```
User: "I need to implement async form validation"
Hook: 🟡 RECOMMENDED SKILL: workflows-code
      Keywords matched: implement, async, validation
```

### Mandatory Skill Evaluation

For CRITICAL priority skills, AI must explicitly evaluate:
```
[code-standards]: YES - Making code changes to JavaScript files
[conversation-documentation]: YES - Creating new feature documentation
```

**Enforcement**: Implementation cannot proceed without explicit YES/NO evaluation

### Context Budget Management

The `workflows-save-context` skill includes automatic triggering:
- Every 20 messages (configurable via MESSAGE_COUNT_TRIGGER)
- Preserves conversation context before hitting limits
- Creates timestamped snapshots in spec folder's memory/

**Example**:
```
Message 20 reached:
📊 Context Budget: 20 messages reached. Auto-saving context...
✅ Context saved to: specs/113-feature/memory/22-11-25_14-30__feature.md
```

### Cross-Skill Workflows

Skills can orchestrate multi-tool workflows:

**Example: Full Development Workflow**
```
1. workflows-code (Phase 1: Implementation)
   → Implements feature with proper patterns

2. workflows-code (Phase 2: Debugging)
   → Debugs any issues systematically

3. workflows-code (Phase 3: Verification)
   → Verifies in browser (MANDATORY)

4. workflows-git (Completion)
   → Creates clean commit + PR

5. workflows-save-context (Documentation)
   → Preserves full conversation context
```

### Integration with Hooks

Skills and hooks work together:

**Pre-Implementation** (UserPromptSubmit hooks):
- `validate-skill-activation.sh` → Suggests relevant skills
- `enforce-spec-folder.sh` → Ensures documentation folder exists
- `enforce-markdown-strict.sh` → Validates SKILL.md structure

**During Implementation** (PreToolUse hooks):
- `validate-bash.sh` → Prevents context bloat from skill scripts
- `validate-mcp-calls.sh` → Ensures Code Mode usage for MCP tools

**Post-Implementation** (PostToolUse hooks):
- `skill-scaffold-trigger.sh` → Auto-creates skill structure
- `enforce-markdown-post.sh` → Ensures naming conventions
- `validate-post-response.sh` → Quality check reminders

---

## 12. 📖 ADDITIONAL RESOURCES

### Documentation

**Skill Creation**:
- `.claude/skills/create-documentation/references/skill_creation.md` - Complete skill creation guide
- `.claude/skills/create-documentation/assets/skill_asset_template.md` - Template examples

**Hook Integration**:
- `.claude/hooks/README.md` - Complete hook system documentation
- `.claude/configs/skill-rules.json` - Skill configuration reference

**Knowledge Base**:
- `.claude/knowledge/code_standards.md` - Project coding standards
- `.claude/knowledge/conversation_documentation.md` - Spec folder system
- `.claude/knowledge/mcp_code_mode.md` - Code Mode usage patterns

### Helper Scripts

**Validation**:
```bash
# Validate skill-rules.json
bash .claude/hooks/scripts/validate-config.sh

# Validate SKILL.md structure
create-documentation validate --file .claude/skills/my-skill/SKILL.md
```

**Analysis**:
```bash
# Check skill recommendations log
tail -50 .claude/hooks/logs/skill-recommendations.log

# View performance metrics
grep "validate-skill-activation" .claude/hooks/logs/performance.log
```