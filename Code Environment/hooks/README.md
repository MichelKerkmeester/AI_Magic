# Claude Code Hooks

Automated workflows and quality checks for Claude Code interactions. Hooks trigger during operations to provide auto-save, skill suggestions, security validation, and quality reminders.

#### 📋 TABLE OF CONTENTS

1. [📖 OVERVIEW](#1--overview)
2. [🔄 HOOK LIFECYCLE](#2--hook-lifecycle)
3. [🎯 INSTALLED HOOKS](#3--installed-hooks)
4. [🔑 EXIT CODE CONVENTION](#4--exit-code-convention)
5. [⚡ PERFORMANCE EXPECTATIONS](#5--performance-expectations)
6. [🔗 HOW HOOKS CONNECT](#6--how-hooks-connect)
7. [📚 SHARED LIBRARIES](#7--shared-libraries)
8. [📊 LOGS DIRECTORY](#8--logs-directory)
9. [⚙️ CONFIGURATION](#9-️-configuration)
10. [🛠️ HELPER SCRIPTS](#10-️-helper-scripts)
11. [💡 KEY BEHAVIORAL FEATURES](#11--key-behavioral-features)
12. [📖 ADDITIONAL RESOURCES](#12--additional-resources)

---

## 1. 📖 OVERVIEW

This directory contains hooks that automatically trigger during Claude Code operations.

### Hook Types

**Input/Tool Processing:**
- **UserPromptSubmit**: Triggers before user prompts are processed
- **PreToolUse**: Triggers before Bash tool execution
- **PostToolUse**: Triggers after Write/Edit/NotebookEdit operations
- **PreCompact**: Triggers before context compaction (manual or automatic)

**Session Lifecycle:**
- **PreSessionStart**: Triggers when a new session begins (initialization)
- **PostSessionEnd**: Triggers when a session ends (cleanup)

### Key Features

**Context & Documentation**
- Auto-save conversation context (keywords + context threshold)
- Auto-load previous memory files when continuing work (user selectable A/B/C/D options)
- Smart spec folder enforcement: Only prompts at conversation start (detects substantial content to avoid repeated prompts mid-conversation)
- Task change detection: Hybrid explicit triggers + automatic divergence detection to prompt for new spec folder when switching tasks mid-conversation

**AI Assistance & Discovery**
- Suggest relevant skills based on prompt content
- Semantic search MCP tool reminders for code exploration
- Debug trace output for semantic search hook (visible execution with timing)

**Markdown & Quality**
- Auto-fix markdown filenames to lowercase snake_case with condensed output
- C7score quality analysis for modified markdown files
- Auto-scaffold skill directories: Creates references/ and assets/ when SKILL.md written

**Security & Validation**
- Block wasteful Bash commands (prevents context bloat from large file reads)
- Security risk pattern detection (eval, innerHTML, etc.)
- Quality check reminders for edited code files

**Performance & UX**
- Condensed hook output for reduced verbosity
- Success indicators for validation passes
- Performance monitoring (all hooks log execution timing)
- JSON caching: 30-40% faster hook execution via skill-rules.json caching

---

## 2. 🔄 HOOK LIFECYCLE

```text
Session Start
     │
     ▼
┌─────────────────────────────────────────┐
│  PreSessionStart Hooks 🆕               │
│  - initialize-session.sh (0)            │
│  Note: (0) = initialization, non-block  │
│        🆕  = Session lifecycle          │
└────────┬────────────────────────────────┘
         │
         ▼
User Action
     │
     ▼
┌─────────────────────────────────────────┐
│  UserPromptSubmit Hooks                 │
│  - workflows-save-context-trigger.sh (0)│
│  - validate-skill-activation.sh (0)     │
│  - orchestrate-skill-validation.sh (0) 🆕│
│  - suggest-semantic-search.sh (0) 🆕    │
│  - suggest-code-mode.sh (0) 🆕          │
│  - detect-mcp-workflow.sh (0) 🆕        │
│  - enforce-spec-folder.sh (0*)          │
│  - enforce-verification.sh (1)          │
│  - enforce-markdown-strict.sh (1)       │
│  Note: (0*) = prompts but allows        │
│        (1)  = blocking                  │
│        (0)  = non-blocking              │
│        🆕   = Parallel agents / Code Mode │
└────────┬────────────────────────────────┘
         │
         ▼
┌─────────────────────────────────────────┐
│  Claude Processes Prompt                │
└────────┬────────────────────────────────┘
         │
         ▼
┌─────────────────────────────────────────┐
│  PreToolUse Hooks                       │
│  - validate-bash.sh (1)                 │
│  - validate-mcp-calls.sh (0) 🆕         │
│  - validate-spec-final.sh (1) 🆕        │
│  - announce-task-dispatch.sh (0) 🎯     │
│  Note: (1) = blocks execution           │
│        (0) = educational warning        │
│        🆕  = Code Mode / SpecKit        │
│        🎯  = Agent lifecycle visibility │
└────────┬────────────────────────────────┘
         │
         ▼
┌─────────────────────────────────────────┐
│  Tool Executes                          │
│  (Write/Edit/Bash/call_tool_chain/etc.) │
└────────┬────────────────────────────────┘
         │
         ▼
┌─────────────────────────────────────────┐
│  PostToolUse Hooks                      │
│  - enforce-markdown-post.sh (0)         │
│  - validate-post-response.sh (0)        │
│  - remind-cdn-versioning.sh (0)         │
│  - skill-scaffold-trigger.sh (0)        │
│  - summarize-task-completion.sh (0) 🎯  │
│  - detect-scope-growth.sh (0) 📊        │
│  Note: (0) = non-blocking auto-fix      │
│        🎯  = Agent lifecycle visibility │
│        📊  = Scope monitoring           │
└────────┬────────────────────────────────┘
         │
         ▼
┌─────────────────────────────────────────┐
│  Claude Generates Response              │
└────────┬────────────────────────────────┘
         │
         ▼
┌─────────────────────────────────────────┐
│  PreCompact Hooks                       │
│  - save-context-before-compact.sh (0)   │
│  Note: (0) = always allows (non-block)  │
└────────┬────────────────────────────────┘
         │
         ▼
┌─────────────────────────────────────────┐
│  Result Returned to User                │
└────────┬────────────────────────────────┘
         │
         ▼ (on session end)
┌─────────────────────────────────────────┐
│  PostSessionEnd Hooks 🆕                │
│  - cleanup-session.sh (0)               │
│  Note: (0) = cleanup, non-blocking      │
│        🆕  = Session lifecycle          │
└─────────────────────────────────────────┘
```

---

## 3. 🎯 INSTALLED HOOKS

### 3.1 UserPromptSubmit Hooks

#### `workflows-save-context-trigger.sh`

**Purpose**: Auto-saves conversations to preserve context and decisions

**Triggers**:
- 🔑 Keywords: `save context`, `save conversation`, `export conversation`, `document this`, `preserve context`
- 🔄 Automatic: Every 20 messages (20, 40, 60, 80...)

**Integrations**:
- `workflows-save-context` skill → Uses `generate-context.js`
- `lib/transform-transcript.js` → Transforms JSONL to JSON
- Output: `specs/###-folder/memory/` (or sub-folder `memory/` when versioning active)
- Logging: `.claude/hooks/logs/performance.log`

**Sub-Folder Routing** (Spec Folder Versioning):
- Detects `.spec-active` marker → Routes to sub-folder memory/
- Passes full path to Node script (e.g., `"122-skill-standardization/016-bugfix"`)
- Backward compatible: Parent folder routing when no marker exists
- See: `.claude/hooks/lib/migrate-spec-folder.sh` for sub-folder creation

**Execution**:
- ⚡ Parallel (non-blocking) when supported
- ⏸️  Fallback to synchronous if parallel unavailable
- ✅ Conversation continues immediately with parallel mode

**Example Output**:
```bash
💾 Auto-saving context (keyword: 'save context' detected)...
💾 Auto-saving context (message 20 - saving every 20 messages)...
   ✅ Context saved to: specs/070-feature/memory/
   🔄 Saving to: specs/070-feature/memory/ (background process)
```

---

#### `validate-skill-activation.sh`

**Purpose**: Matches prompts to relevant skills and enforces mandatory skill evaluation

**Triggers**: Before every user prompt

**Integrations**:
- Config: `.claude/configs/skill-rules.json` (skill definitions, keywords, patterns)
- Keyword matching: `animation`, `commit`, `debug`, `documentation`, etc.
- Pattern matching: `create feature`, `fix bug`, `implement X`

**Priority Levels**:
- 🔴 **MANDATORY**: Must apply (shown to user) - `code-standards`, `conversation-documentation`
- 🟡 **HIGH**: Strongly recommended (logged) - `git-commit`, `workflows-save-context`
- 🔵 **MEDIUM**: Consider using (logged) - `debugging`, `workflows-code`

**Features**:
- 📊 Estimates documentation level + complexity from prompt
- 🔢 Calculates next spec folder number
- 📋 Prints copy commands for required/optional templates
- ⏱️  Shows documentation time estimate
- 🔗 Links to `.claude/knowledge/conversation_documentation.md`

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

For each skill listed:
  1. State: YES (will apply) or NO (not applicable)
  2. Provide brief reason (one sentence)
  3. If YES: Activate using Skill tool

Required format:
  [code-standards]: YES/NO - [your reason]
  [conversation-documentation]: YES/NO - [your reason]

After evaluation, proceed with implementation.
───────────────────────────────────────────────────────────────

📊 Detected Intent: Feature implementation or refactor
📏 Estimated LOC: ~200 lines
📋 Recommended Level: Level 2 (Standard)

🗂️  Next Spec Number: 049
📁 Create Folder: specs/049-feature-name/

📝 Required Templates:
   cp .opencode/speckit/templates/spec_template.md specs/049-feature-name/spec.md
   cp .opencode/speckit/templates/plan_template.md specs/049-feature-name/plan.md

💡 Optional Templates:
   cp .opencode/speckit/templates/tasks_template.md specs/049-feature-name/tasks.md
   cp .opencode/speckit/templates/checklist_template.md specs/049-feature-name/checklist.md

📖 Guide: .claude/knowledge/conversation_documentation.md
⚙️  Level Decision Tree: Section 2 of conversation_documentation.md
⏱️  Estimated Documentation Time: ≈20 minutes
```

**Question Detection**:
- Automatically detects read-only prompts (questions, reviews, explanations)
- Patterns: `what|how|why|explain|show me|describe|tell me`
- Exits early to prevent false positives on non-modification requests
- Special handling: polite questions that clearly ask to *implement/add/fix/build/refactor/update/change/create/modify* something (e.g., "Can you implement X?") are treated as **modification** prompts, not read-only questions

**Commitment Structure** (Phase 2 - Nov 2025):
- Requires explicit YES/NO evaluation for mandatory skills
- Forces written decision before implementation
- Based on research showing 4x improvement (20% → 84% activation success)
- Format templates reduce ambiguity and create psychological commitment


**Performance Optimization** (Nov 2025):
- JSON caching for skill-rules.json parsing
- Cache location: `/tmp/claude_hooks_cache/`
- Cache key: MD5 hash of skill-rules.json path
- Automatic invalidation on file modification
- Performance improvement: 30-40% faster (200-300ms → 120-180ms)
- Platform-independent (macOS + Linux)

**Logs to**: `.claude/hooks/logs/skill-recommendations.log` (all matches)

---

#### `orchestrate-skill-validation.sh`

**Purpose**: Auto-dispatches parallel agents based on task complexity (5-factor scoring: domains 35%, files 25%, LOC 15%, parallelism 20%, type 5%)

**Dispatch Logic**:
- <25%: Sequential validation
- 25-34%: User preference prompt
- ≥35% + ≥2 domains: Auto-dispatch 4 agents (workflow, knowledge, tool, mcp)

**Performance**: 48ms parallel vs 120ms sequential (2.5x speedup, +15% tokens)

**Output Example**:
```bash
📊 Complexity: 77.75% (4 domains, 8 files, ~350 LOC)
🚀 Dispatching 4 parallel agents...
✅ Complete (48ms) → workflows-code, create-documentation, workflows-git
```

**Integration**: `create-parallel-sub-agents` skill | Config: `skill-rules.json` | Logs: `orchestrator.log`

---

#### `suggest-semantic-search.sh`

**Purpose**: Reminds AI to use Code Mode with semantic search MCP tools for code exploration

**Triggers**:
- 🔑 Keywords: `find code`, `where is implementation`, `locate function`, `search codebase`
- 🔍 Patterns: `explore code`, `analyze implementation`, `show how X works`

**Integrations**:
- Guide: `.claude/knowledge/mcp_code_mode.md` - Code Mode usage
- Guide: `.claude/knowledge/mcp_semantic_search.md` - Semantic search details
- Tools: MCP semantic search (intent-based code discovery)

**Example Output**:
```bash
💡 Code exploration detected: Use semantic search MCP via Code Mode for intent-based discovery
   📖 Docs: .claude/knowledge/mcp_semantic_search.md & mcp_code_mode.md
```

**Performance**: ~13ms
**Note**: Output kept minimal (2 lines) to prevent API policy violations from excessive technical content
**Logging**: `.claude/hooks/logs/performance.log`

---

#### `suggest-code-mode.sh`

**Purpose**: Detects MCP tool operations and suggests Code Mode for optimal performance

**Triggers**:

**CMS Operations (Webflow):**
- Keywords: `webflow`, `cms collection`, `publish site`, `update content`, `webflow item`

**Design Tools (Figma):**
- Keywords: `figma`, `design file`, `get component`, `design system`, `figma export`

**Browser Automation (Chrome DevTools MCP via Code Mode):**
- Keywords: `chrome devtools`, `screenshot`, `navigate page`, `browser automation`, `test page`
- Note: For terminal-based debugging, see cli-chrome-devtools skill (bdg CLI tool)

**Multi-Tool Workflows:**
- Keywords: `workflow`, `pipeline`, `integrate`, `from X to Y`, `then update`, `automate`

**Integrations**:
- Guide: `.claude/knowledge/mcp_code_mode.md`
- Dynamic examples based on detected category

**Example Output**:
```bash
🤖 CODE MODE REMINDER:

Pattern Detected: CMS Operations (Webflow)

⚡ Benefits:
• 68% fewer tokens consumed
• 98.7% reduction in context overhead
• 60% faster execution

📖 Usage Pattern:
call_tool_chain({
  code: `
    const sites = await webflow.webflow_sites_list({});
    const collections = await webflow.webflow_collections_list({
      site_id: sites.sites[0].id
    });
    return { sites, collections };
  `
});

🔧 Tool Naming: {manual_name}.{manual_name}_{tool_name}
⚠️  IMPORTANT: ALL MCP tools MUST be called via Code Mode
```

**Performance**: 25-41ms (4 pattern categories)
**Logging**: Category detection logged to `.claude/hooks/logs/performance.log`

---

#### `detect-mcp-workflow.sh`

**Purpose**: Detects multi-step MCP workflows and highlights Code Mode workflow benefits

**Triggers**:

**Multi-Platform Workflows:**
- Detection: 2+ platforms mentioned (Webflow, Figma, Chrome DevTools, Semantic Search)
- Example: "Get Figma design then update Webflow collection"

**Sequential Operations:**
- Keywords: `first then`, `then update`, `after create`, `next publish`, `and then`
- Example: "First get Webflow collections, then update each collection"

**Cross-Platform Integration:**
- Keywords: `from X to Y`, `integrate with`, `sync with`, `pipeline`, `workflow`
- Example: "Create workflow from Figma to Webflow"

**Integrations**:
- Guide: `.claude/knowledge/mcp_code_mode.md` (Section 4: Usage Examples)
- Dynamic workflow examples based on detected platforms

**Example Output**:
```bash
🔄 MULTI-STEP WORKFLOW DETECTED:

Platforms Detected: [Webflow, Figma]
Workflow Type: Multi-Platform Workflow

⚡ Code Mode Advantages for Workflows:
• State persistence across ALL operations
• Single execution (no context switching)
• 5× faster than separate tool calls
• Automatic error handling and rollback

📖 Example: Design-to-CMS Workflow
call_tool_chain({
  code: `
    const design = await figma.figma_get_file({ fileId: 'abc123' });
    const sites = await webflow.webflow_sites_list({});
    const item = await webflow.webflow_items_create_item({
      collectionId: '...',
      fields: { name: design.name }
    });
    return { design, item };
  `,
  timeout: 60000
});

⚠️  Multi-step workflows benefit MOST from Code Mode
```

**Performance**: 39-46ms
**Logging**: Workflow type and platform count logged

---

#### `enforce-markdown-strict.sh`

**Purpose**: Validates markdown structure and blocks critical violations

**Triggers**: Before user prompts (checks recently modified `.md` files)

**Validation Rules**:
- 📘 **SKILL.md**: YAML frontmatter, H1 subtitle, required sections
- 📋 **Commands**: Frontmatter (`description`, `argument-hint`)
- 📖 **Knowledge**: H1 subtitle format, no frontmatter

**C7Score Analysis**:
- Runs `create-documentation` CLI on modified markdown
- Shows condensed analysis (issue rate, recommendations)
- Non-blocking informational feedback
- Optimizes documentation for AI consumption

**Integrations**:
- `.claude/skills/create-documentation` → Document style standards and validation
- `.claude/skills/create-documentation/create-documentation` → CLI wrapper for validation & optimization
- `.claude/skills/create-documentation/scripts/analyze_docs.py` → Python analyzer
- Git status → Finds modified .md files
- `lib/output-helpers.sh` → Condensed output formatting

**Behavior**:
- ✅ Safe fixes: Auto-applied by other tools (separators, caps, spacing)
- 🚫 Critical violations: BLOCKS execution (missing frontmatter, wrong structure)
- ℹ️ C7score analysis: Informational only, shows quality metrics
- ✅ Success indicator: Shows "✅ Markdown validation passed: N file(s) checked, 0 violations"

**Output Example** (blocking - condensed):
```
❌ MARKDOWN ENFORCEMENT BLOCKED: .claude/skills/my-skill/SKILL.md
   Type: skill (strict enforcement)

   Critical Issues:
     CRITICAL: Missing YAML frontmatter
     CRITICAL: H1 missing subtitle

   Fix: Review .claude/skills/create-documentation (Document Standards)
   Then: create-documentation validate --file SKILL.md --fix
```

**Output Example** (C7score analysis):
```
ℹ️  C7SCORE ANALYSIS:
   Issue rate: 20.0%
   ✅ Recommendations

   Tip: Run 'create-documentation validate --file /path/to/file.md' for full analysis
```

**Output Example** (success):
```text
✅ Markdown validation passed: 3 file(s) checked, 0 violations
```

**Responsibility Boundary**:
- **Content validation ONLY** - Checks structure, frontmatter, headings, c7score
- **Does NOT rename files** - See `enforce-markdown-post.sh` for filename corrections
- This separation ensures validation runs before user input, filename fixes run after file operations

---

#### `enforce-spec-folder.sh`
**What it does**: Prompts for spec folder selection with related spec discovery. Supports sub-folder versioning, memory loading, task change detection, and session-isolated markers.

**Triggers**:
- Runs before each prompt
- Fires only when the prompt implies file modifications (verbs like add/update/implement)

**Validates**:
- Latest `specs/###-short-name/` folder exists
- `spec.md` or `README.md` > 200 bytes with numbered sections
- Optional placeholder checks (configurable)
- Configurable enforcement modes via `skill-rules.json`:
  - **warning**: Logs but allows (exit 0)
  - **soft-block**: Warns but allows (exit 0 with verbose message)
  - **hard-block**: Blocks execution (exit 1) **[DEFAULT]**
  - Configuration: `.claude/configs/skill-rules.json` → `skills.conversation-documentation.enforcementConfig.mode`

**Behavior Change (Nov 2025)**:
- **Before**: Hard-blocked with exit 1 when no spec folder
- **Now**: Asks user to confirm folder choice (A/B/C options), exits with 0 to allow conversation to continue
- AI receives confirmation prompt and responds with user's choice

**Mid-Conversation Detection (Nov 2025)**:
- **Detects substantial content** in spec folder to determine conversation state
- **Criteria**: >2 files OR any file >1000 bytes = mid-conversation
- **Behavior**: Exits early without prompting when substantial content detected
- **Performance**: File system check only, no git/timestamps, ~5-10ms overhead
- **Goal**: Only prompt at start of conversation, not repeatedly during work

**Related Spec Discovery**:
- Extracts keywords from user prompt
- Searches existing spec folders by keyword matching
- Checks spec.md frontmatter for status field (active/draft/paused/complete/archived)
- Ranks by status priority (active > draft > paused > complete)
- Surfaces top 3 related specs before asking for confirmation

**Connects to**:
- `.claude/configs/skill-rules.json` → `conversation-documentation.enforcementConfig`
- `.claude/knowledge/conversation_documentation.md` → Section 7 (Spec Reuse Guidelines)
- `.claude/hooks/scripts/find-related-spec.sh` → Manual search tool
- `.claude/hooks/logs/spec-enforcement.log` + `performance.log`

**Sub-Folder Versioning (Nov 2025)**:
- **Automatic numbered sub-folders** when reusing spec folders with existing content
- **Numbering**: Sequential 001, 002, 003, etc. (3-digit padded)
- **Archive**: Existing root-level files moved to `001-{topic}/`
- **New work**: Created in `002-{user-provided-name}/`
- **Memory isolation**: Each sub-folder has independent `memory/` directory
- **Marker**: `.spec-active` tracks active sub-folder path
- **Migration script**: `.claude/hooks/lib/migrate-spec-folder.sh <spec-folder> <new-subfolder-name>`
- **Example structure**:
  ```
  specs/122-skill-standardization/
  ├── 001-cli-codex-alignment/
  │   ├── spec.md
  │   └── memory/
  ├── 002-workflows-conversation/
  │   ├── spec.md
  │   └── memory/
  └── 003-spec-folder-versioning/  ← Active
      ├── spec.md
      └── memory/
  ```
- **Triggers when**: User selects Option A and spec folder has root-level `.md` files
- **AI prompted for**: New sub-folder name (system adds number prefix automatically)
- **Migration process**:
  1. AI asks user for sub-folder name (lowercase, hyphens, 2-4 words)
  2. AI executes: `.claude/hooks/lib/migrate-spec-folder.sh <spec-folder> <new-name>`
  3. Script archives existing files to `001-{original-topic}/`
  4. Script creates new work folder `002-{new-name}/`
  5. Script updates `.spec-active` marker
  6. AI creates fresh spec.md and plan.md in new sub-folder
- **Benefits**: Clean iteration separation, preserved history, backward compatible

**Marker Sync System (Nov 2025)**:
- **Automatic local marker creation** from global `.claude/.spec-active` marker
- **Purpose**: Enables parent folder detection by bridging global → local marker gap
- **Function**: `sync_marker_to_parent()` (runs before folder detection)
- **Behavior**:
  - Reads global marker path (e.g., `specs/002-hook-refinement/009-fix/`)
  - Extracts parent folder via `get_parent_folder()` helper
  - Creates local marker at `{parent}/.spec-active` with child folder name
  - Uses atomic file writes (tmp + mv) to prevent corruption
  - Gracefully handles errors (missing paths, permission issues)
- **Performance**: <5ms overhead per execution
- **Example**:
  ```
  Global: .claude/.spec-active → "specs/002-hook-refinement/009-fix/"
  Sync creates: specs/002-hook-refinement/.spec-active → "009-fix"
  Result: Parent folder now detectable as PARENT_ACTIVE
  ```

**Enhanced Memory Search (Nov 2025)**:
- **Hierarchical traversal** for finding memory files across related spec folders
- **Function**: `find_memory_directory()` with 3 fallback options
- **Search priority**:
  1. **Direct match**: Marker points to child of current spec
  2. **Same parent**: Marker and spec are siblings (e.g., `002-*/008-*` and `002-*/009-*`)
  3. **Related family**: Both in same spec family by root number (e.g., `003-speckit-refinement` family)
- **Fixes issue**: Memory prompts now work when continuing work across related specs
- **Example scenario**:
  ```
  Marker: specs/002-hook-refinement/008-readme-update
  User works in: specs/002-hook-refinement/009-hook-detection-fix
  Result: Memory from 008-readme-update is found and offered (same parent)
  ```

**Marker Staleness Detection (Nov 2025)**:
- **Keyword-based staleness checking** to warn about unrelated work
- **Function**: `check_marker_staleness()` (runs during mid-conversation check)
- **Behavior**:
  - Extracts keywords from current prompt (3+ letter words)
  - Compares against marker path (parent and child folder names)
  - Issues non-blocking warning if no keyword matches found
  - Logs stale marker events for auditing
- **Example**:
  ```
  Marker: specs/002-hook-refinement/009-hook-detection-fix
  Prompt: "Implement animation timing fix"
  Keywords: implement, animation, timing
  Result: ⚠️ Warning shown (no "hook" or "refinement" in prompt)
  ```

**Task Change Detection (Nov 2025)**:
- **Hybrid detection system** combining explicit triggers + automatic divergence detection
- **Purpose**: Detects mid-conversation task changes and prompts for new spec folder
- **Libraries**: `lib/spec-context.sh` (fingerprinting) + `lib/signal-output.sh` (question emission)

**Explicit Trigger Detection (Priority 1)**:
- **Triggers**: `new task`, `different task`, `switch to`, `change topic`, `start fresh`, `clear context`, `work on something else`, `different feature`, `new feature`, `new bug`, `reset spec`
- **Question exclusion**: Phrases ending in `?` or starting with `how/what/when/why/can/could/should` are NOT treated as triggers
- **Behavior**: Clears `.spec-active` marker and prompts for new spec folder
- **Example**: "new task: implement auth" → Clears marker → Fresh spec folder prompt

**Automatic Divergence Detection (Priority 2)**:
- **Topic fingerprinting**: Stores keywords in enhanced JSON marker format
- **Enhanced marker format**:
  ```json
  {
    "path": "specs/122-skill-standardization",
    "topic_keywords": ["skill", "standardization", "alignment"],
    "created_at": "2025-11-26T10:00:00Z"
  }
  ```
- **Backward compatible**: `read_spec_marker()` handles both legacy (path-only) and JSON formats
- **Functions**:
  - `extract_prompt_keywords()` - Extract and filter keywords (stop words removed, 3+ chars)
  - `create_spec_marker_with_fingerprint()` - JSON marker with keywords
  - `calculate_divergence_score()` - Keyword overlap calculation (0-100%)
  - `emit_task_change_question()` - Blocking question for task change

**Divergence Thresholds**:
- **≤40%**: Continue silently (same topic)
- **41-60%**: Log only (borderline)
- **>60%**: Emit **BLOCKING** question asking user if switching tasks

**Question Type**: `TASK_CHANGE_DETECTED`
- **Options**:
  - **A) Continue current**: Stay in current spec folder (this is related work)
  - **B) New spec folder**: Create a fresh spec folder for new task
  - **C) Switch to existing**: Choose a different existing spec folder
- **Question Flow Stage**: `task_change` (added to `handle_question_flow()`)

**Example Output**:
```bash
🔴 MANDATORY_USER_QUESTION
{"signal": "MANDATORY_QUESTION",
  "type": "TASK_CHANGE_DETECTED",
  "question": "Your request seems different from current work (85% divergence from 122-skill-standardization). Are you switching tasks?",
  "options": [
    {"id": "A", "label": "Continue current", "description": "Stay in 122-skill-standardization - this is related work"},
    {"id": "B", "label": "New spec folder", "description": "Create a fresh spec folder for this new task"},
    {"id": "C", "label": "Switch to existing", "description": "Choose a different existing spec folder"}
  ],
  "blocking": true
}
```

**Performance**: <100ms total for fingerprinting + divergence calculation

**Edge Cases**:
- Empty/short prompts: Default to 50% divergence (neutral)
- Legacy markers: Converted to JSON format automatically
- Questions about switching: Excluded from explicit triggers via `\?$` pattern

**Session-Isolated Spec Markers (V9 - Nov 2025)**:
- **Problem solved**: Multiple concurrent Claude Code sessions would overwrite each other's `.spec-active` markers
  - Terminal 1 sets marker to `specs/043-save-context/`, Terminal 2 overwrites with `specs/007-auth/`
  - save-context would route to wrong folder, context would be lost
- **Solution**: Session-suffixed marker files using SESSION_ID
- **Marker naming**:
  ```
  Before (shared):  .claude/.spec-active
  After (isolated): .claude/.spec-active.{SESSION_ID}
  ```
- **Backward compatibility**: Falls back to legacy `.spec-active` when SESSION_ID unavailable
- **Files updated**:
  - `lib/spec-context.sh` - Added `get_spec_marker_path(session_id)` helper
  - `enforce-spec-folder.sh` - Extracts SESSION_ID, uses session-aware marker
  - `workflows-save-context-trigger.sh` - Reads session-aware marker
  - `verify-spec-compliance.sh` - Uses session-aware marker
  - `lib/migrate-spec-folder.sh` - Writes both legacy and session markers
  - `PostSessionEnd/cleanup-session.sh` - Removes session marker on session end
  - `PreSessionStart/initialize-session.sh` - Cleans stale markers (>24h) on session start
- **Lifecycle**:
  1. Session starts → Stale markers (>24h old) cleaned up
  2. User selects spec folder → Creates `.spec-active.{SESSION_ID}`
  3. save-context triggers → Reads session-specific marker, routes correctly
  4. Session ends → Session marker removed automatically
- **Session ID extraction**: `jq -r '.session_id' + tr -cd 'a-zA-Z0-9_-'` (sanitized for security)
- **Example**: Two concurrent sessions working independently:
  ```
  .claude/.spec-active.abc123   → specs/043-save-context/
  .claude/.spec-active.def456   → specs/007-auth/
  .claude/.spec-active          → Legacy fallback (optional)
  ```

**Two-Stage Question Flow (Nov 2025)** - BUG FIX:
- **Problem solved**: Previously, spec folder confirmation and memory loading were conflated
  - User selecting "D" (skip) for memory was interpreted as "continue in current spec folder"
  - This was wrong - "skip memory" and "skip spec folder" are different decisions
- **Fix**: Two separate decisions, asked sequentially:
  1. **Stage 1 (spec_folder_confirm)**: "Continue in this spec folder or create new?"
     - **A)** Continue in existing folder (proceed to stage 2 if memory exists)
     - **B)** Create new spec folder
     - **D)** Skip documentation entirely
  2. **Stage 2 (memory_load)**: "Load previous context?" (only if A chosen in stage 1)
     - **A)** Load most recent
     - **B)** Load all recent
     - **C)** Select specific
     - **D)** Skip (start fresh without loading context)
- **Flow diagram**:
  ```
  Mid-conversation detected
          ↓
  Ask: "Continue in 006-commands?"  ← Stage 1 (spec_folder_confirm)
          ↓
  User picks A (continue) → Check for memory files
          ↓                         ↓
  Memory exists?           No memory → Proceed
          ↓
  Ask: "Load context?"  ← Stage 2 (memory_load)
          ↓
  User picks D (skip) → Proceed WITHOUT loading (but stays in folder)
  ```
- **Key insight**: "D" in stage 1 = skip documentation; "D" in stage 2 = skip memory only
- **Functions**:
  - `emit_spec_folder_confirm_question()` - Stage 1 question (lib/signal-output.sh)
  - `emit_memory_load_question()` - Stage 2 question (lib/signal-output.sh)
  - Handler: `spec_folder_confirm` stage in `handle_question_flow()` (enforce-spec-folder.sh)

**Memory File Selection & Context Loading (Nov 2025)**:
- **Automatic context restoration** when continuing work in existing spec folders
- **IMPORTANT**: Memory selection is **Stage 2** - only triggers AFTER user confirms spec folder (Option A in Stage 1)
- **Triggers when**:
  - User selected A (continue) in spec folder confirmation
  - Memory directory exists (respects `.spec-active` marker for sub-folders)
  - At least one memory file exists (format: `DD-MM-YY_HH-MM__topic.md`)
- **User presented with 4 options**:
  - **A)** Load most recent memory file (quick context refresh)
  - **B)** Load all recent files (1-3 files, comprehensive context)
  - **C)** List all memory files and select specific (up to 10 files shown)
  - **D)** Skip (start fresh, no context loading - but stays in spec folder)
- **AI workflow**:
  1. User confirms spec folder in Stage 1
  2. Hook detects memory files and emits Stage 2 question
  3. AI asks user: "Which memory files should I load? (A/B/C/D)"
  4. AI waits for user's explicit choice
  5. AI uses Read tool to load selected files (unless D chosen)
  6. AI summarizes loaded context and continues conversation
- **Display format**:
  ```
  📁 Spec folder confirmed: 006-commands

  🧠 MEMORY FILES AVAILABLE
  Found 3 previous session file(s):
    • 26-11-25_08-42__commands.md
    • 25-11-25_15-30__planning.md
    • 24-11-25_10-00__initial.md

  🔴 MANDATORY_USER_QUESTION
  {"signal": "MANDATORY_QUESTION", "type": "MEMORY_LOAD", ...}
  ```
- **Sub-folder aware**: Automatically finds memory files in active sub-folder via `.spec-active` marker
- **Cross-platform**: Works on both macOS (`date -j`) and Linux (`date -d`) with automatic platform detection
- **Performance**: <100ms overhead for memory file discovery and display
- **Benefits**: Seamless session continuity, prevents re-asking questions, maintains conversation context
- **Graceful degradation**: Silently skips Stage 2 if no memory directory or files exist

**Exceptions**:
- Configurable patterns (`typo fix`, `whitespace only`, etc.) with LOC + single-file constraints

**Output Example (No Spec Folder)**:
```
⚠️  SPEC FOLDER CONFIRMATION NEEDED

Detected modification intent: implement
Estimated documentation level: Level 2 (Standard)
Status: No spec folder detected

No spec folder detected.

Choose one:
  A) Create new spec folder: specs/070-short-name/
  B) Create spec with different number
  D) Skip spec folder creation (PROCEED WITHOUT DOCUMENTATION)
     ⚠️  WARNING: Skipping documentation creates technical debt
     ⚠️  Future debugging will be harder without context
     ⚠️  Use only for truly trivial explorations

📝 Next steps after choosing:
   cp .opencode/speckit/templates/spec_template.md specs/070-short-name/spec.md
   cp .opencode/speckit/templates/plan_template.md specs/070-short-name/plan.md

📖 Reference: /path/to/conversation_documentation.md

Reply with A, B, C, or D to proceed with your choice.
```

**Output Example (With Related Specs)**:
```
───────────────────────────────────────────────
RELATED SPECS FOUND
───────────────────────────────────────────────
Found existing specs that may be related to your request:

  • 083-create-documentation
    Status: ✓ ACTIVE - recommended for updates
    Path: /path/to/specs/083-create-documentation
──────────────────────────────────────────────────────────

RECOMMENDATION
Consider updating one of the related specs above instead of creating a new one.

AI should ask user:
  A) Update existing spec (if work is related)
  B) Create new spec (if work is distinct)
──────────────────────────────────────────────────────────

⚠️  SPEC FOLDER CONFIRMATION NEEDED
[...confirmation prompt follows...]
```

**Helper Script**: `.claude/hooks/scripts/find-related-spec.sh`
- Standalone tool for manual spec search
- Usage: `find-related-spec.sh "keyword1 keyword2"`
- Returns top 5 matches with status and description
- Three-tier ranking: folder name (10) > title (5) > content (1)

**Skip Option (Option D)** - Added in spec 121:

Available to allow users to explicitly skip spec folder creation for truly trivial explorations.

**When User Selects Skip**:
1. Hook creates `.claude/.spec-skip` marker file
2. Subsequent prompts in same session skip validation automatically
3. Skip event logged to `spec-enforcement.log`
4. Conversation proceeds without spec folder requirement

**Skip Marker File**: `.claude/.spec-skip`
- Single marker file per workspace (not per-conversation)
- Persists across conversation until manually removed
- Gitignored (not tracked in repository)
- Cleanup: `rm .claude/.spec-skip` to re-enable prompts

**Use Cases**:
- ✅ Quick code exploration (read-only)
- ✅ Testing concepts without implementation
- ✅ Analyzing existing code
- ❌ **NOT for**: Actual implementation or bug fixes

**Warnings Displayed**:
- "Skipping documentation creates technical debt"
- "Future debugging will be harder without context"
- "Use only for truly trivial explorations"

**See**: `.claude/knowledge/conversation_documentation.md` Section 7 for complete skip option documentation

---

### 3.2 PreToolUse Hooks

#### `validate-bash.sh`

**Purpose**: Prevents context bloat from reading large/irrelevant files

**Triggers**: Before executing any Bash command

**Blocks**:
- ❌ **Context bloat**: `node_modules/`, `build/`, `dist/`, `venv/`, `.next/`
- ❌ **Sensitive files**: `.ssh/`, `.env`, `.pem`, credentials
- ❌ **Dangerous ops**: `rm -rf /`, `sudo`, `chmod 777`, `curl ... | sh`

**Whitelisted**:
- ✅ `.claude/logs/`, `.claude/hooks/logs/`, `.claude/configs/`

**Behavior**:
- Returns **exit code 2** when blocking a command (matches PreToolUse lifecycle diagram)
- Returns **exit code 0** for allowed or non-matching commands

**Example Output**:
```bash
ERROR: Access to 'node_modules' is blocked by security policy
Alternative: Use targeted file reads or grep/glob patterns
```

---

#### `validate-mcp-calls.sh`

**Purpose**: Detects direct MCP tool calls and suggests Code Mode usage (anti-pattern prevention)

**Triggers**: Before executing any tool

**Detection Logic**:

**Code Mode Tools (Correct Pattern):**
- ✅ `call_tool_chain`, `search_tools`, `list_tools`, `tool_info`
- Silent pass-through (exit 0, no output)

**Direct MCP Calls (Anti-Pattern):**
- ❌ Tools starting with: `webflow_`, `figma_`, `chrome_devtools_`, `semantic_search_`
- Non-blocking warning (exit 0 with educational output)

**Regular Tools:**
- ✅ All other tools (Read, Write, Edit, Bash, etc.)
- Silent pass-through (exit 0, no output)

**Integrations**:
- Guide: `.claude/knowledge/mcp_code_mode.md`
- Detects 4 active MCP platforms (Webflow, Figma, Chrome DevTools, Semantic Search)

**Behavior**:
- **Non-blocking** - Allows operation to proceed (exit 0)
- **Educational** - Shows benefits and correct Code Mode pattern
- **Dynamic** - Platform-specific suggestions based on detected tool

**Example Output** (Direct MCP Call Detected):
```bash
⚠️  DIRECT MCP CALL DETECTED (ANTI-PATTERN):

  Platform: Webflow
  Tool: webflow_sites_list

  ❌ Direct MCP calls use excessive context and slow execution
  ✅ Use Code Mode instead for 98.7% overhead reduction

  ✅ Recommended Pattern (Code Mode):
  search_tools({ task_description: "Webflow operations", limit: 10 });

  call_tool_chain({
    code: `
      const result = await webflow.webflow_sites_list({});
      return result;
    `
  });

  ⚡ Benefits of Code Mode:
  • 68% fewer tokens consumed
  • 98.7% reduction in context overhead
  • 60% faster execution
  • State persistence across multiple operations

  🔧 Tool Naming: {manual_name}.{manual_name}_{tool_name}
  Examples:
  • webflow.webflow_sites_list()
  • figma.figma_get_file()
  • chrome_devtools_1.chrome_devtools_navigate_page()
  • semantic_search.semantic_search_search_codebase()

📖 See: .claude/knowledge/mcp_code_mode.md

⚠️  Allowing this operation to proceed for compatibility,
    but STRONGLY recommend using Code Mode for all future MCP calls.
```

**Performance**: 21-23ms
**Logging**: Platform and tool name logged to `.claude/hooks/logs/performance.log`

---

#### `validate-spec-final.sh`

**Purpose**: SpecKit pre-commit quality gate - validates spec folder documentation before file modifications

**Triggers**: Before Edit/Write/NotebookEdit tools modify spec folder files

**Validation Checks**:
- **Template Sources**: Verifies SPECKIT_TEMPLATE_SOURCE markers present
- **Section Completeness**: Ensures all required sections exist for template type
- **Content Adaptation**: Confirms placeholders replaced, sample content removed
- **Metadata Validation**: Checks metadata block completeness
- **Traceability**: Validates cross-references between spec/plan/tasks files

**Exit Codes**:
- `0` = Allow (validation passed, continue tool execution)
- `1` = Block (validation failed, stop tool execution with warning)
- `2` = Error (reserved for critical failures)

**Validation Modes**:
- **standard**: Block on critical errors, allow on warnings (default)
- **strict**: Block on any errors or warnings (`STRICT_MODE=true`)

**Integrations**:
- `lib/template-validation.sh` → 5 validation functions
- `.claude/configs/template-validation.json` → Optional configuration
- `.opencode/speckit/templates/` → Template structure requirements

**Behavior**:
- **Blocking** - Can prevent tool execution on validation failures
- **Fast** - Target <150ms validation time
- **Smart Detection** - Only runs when in spec folder context
- **Graceful** - Allows execution if validation library unavailable

**Example Output**:
```bash
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
SPECKIT PRE-COMMIT QUALITY GATE
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

✅ Template source validation passed
✅ Section completeness verified
✅ Content adaptation complete
✅ Metadata validation passed
✅ Traceability checks passed

🎯 Validation complete - Tool execution allowed
```

**Connects to**:
- `.claude/hooks/lib/template-validation.sh` → Validation function library
- `.claude/hooks/lib/output-helpers.sh` → Formatting functions
- spec folders: `specs/###-name/` → Validation target

**Performance**: <150ms target (quality gate must be fast)
**Logging**: Validation results logged to `.claude/hooks/logs/validate-spec-final.log`

**Created**: 2025-11-24 (spec 003-speckit-rework/003-template-enforcement/)

---

#### `check-pending-questions.sh`

**Purpose**: STRICT MODE hook that blocks ALL tool execution when a mandatory question is pending, ensuring users respond to required questions before AI proceeds

**Triggers**: Before any tool execution (PreToolUse)

**Behavior**:
- **AskUserQuestion** → ALWAYS ALLOWED (clears pending state when used)
- **All other tools** → BLOCKED with exit 1 when question pending
- **No pending question** → All tools allowed (exit 0)

**State Management**:
- State file: `/tmp/claude_hooks_state/pending_question.json`
- Expiry: 5 minutes (300 seconds) - stale questions auto-expire
- Cleared automatically when `AskUserQuestion` tool is used

**Integrations**:
- `lib/shared-state.sh` → Read/write/clear pending question state
- `lib/signal-output.sh` → Sets pending_question state when emitting questions
- `lib/exit-codes.sh` → Standard exit code constants
- `lib/output-helpers.sh` → Error box formatting

**Question Types Supported**:
- `SPEC_FOLDER_CHOICE` - Spec folder selection (from enforce-spec-folder.sh)
- `MEMORY_LOAD` - Previous session context loading
- `SKILL_EVAL` - Mandatory skill evaluation
- `CUSTOM` - Any other mandatory question

**Exit Codes**:
- `0` = Allow (no pending question OR tool is AskUserQuestion)
- `1` = Block (pending question exists AND tool is not AskUserQuestion)

**Example Output** (when blocking):
```bash
❌ 🔴 TOOL BLOCKED - Mandatory Question Pending

   Blocked Tool: Read
   Question Type: SPEC_FOLDER_CHOICE
   Asked At: 2025-11-25T10:30:00Z

   Question: Which spec folder should we use for this work?

   ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
   YOU MUST answer the pending question before using any tools.

   Use the AskUserQuestion tool to present options to the user.
   All tools are BLOCKED until the user responds.
   ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

**Graceful Degradation**:
- If `shared-state.sh` is missing → allows all tools (exit 0)
- If `exit-codes.sh` is missing → uses fallback constants
- If `output-helpers.sh` is missing → uses fallback error function

**Performance**: <50ms target
**Logs to**: `.claude/hooks/logs/check-pending-questions.log`

**Created**: 2025-11-25 (spec 003-mandatory-question-enforcement)

---

#### `announce-task-dispatch.sh`

**Purpose**: Displays agent launch announcement before Task tool executes, providing visibility into sub-agent dispatch

**Triggers**: Before any Task tool call

**Display Logic (Expandable Default)**:
- **1-2 agents**: Compact single-line format
- **3+ agents**: Full verbose box with details

**Integrations**:
- `lib/agent-tracking.sh` → State management for agent lifecycle
- `lib/output-helpers.sh` → Formatting functions
- State file: `/tmp/claude_hooks_state/agent_tracking.json`

**Behavior**:
- **Non-blocking** - Always allows Task tool to proceed (exit 0)
- **Informational** - Shows agent details before execution
- **Batch-aware** - Tracks multiple parallel agents in session

**Example Output (Compact - 1-2 agents)**:
```bash
🚀 Launching: Explore (sonnet) → "Find auth implementations"
```

**Example Output (Verbose - 3+ agents)**:
```bash
┌─────────────────────────────────────────────────────────────┐
│ 🚀 PARALLEL DISPATCH (Agent #3)                            │
├─────────────────────────────────────────────────────────────┤
│ 3. Explore (sonnet, 5 min)                                  │
│    └─ "Find auth implementations"                           │
│                                                             │
│ Task Preview:                                               │
│ > You are a specialized agent focused on exploring...       │
│                                                             │
│ ⏳ Executing...                                             │
└─────────────────────────────────────────────────────────────┘
```

**Performance**: <30ms target
**Logs to**: `.claude/hooks/logs/task-dispatch.log`

**Created**: 2025-11-25 (parallel agent display enhancement)

---

### 3.3 PostToolUse Hooks

#### `enforce-markdown-post.sh`

**Purpose**: Auto-renames markdown files to lowercase snake_case

**Triggers**: After Write/Edit/NotebookEdit on `.md` files

**Conversions**:
- `TEST_FILE.md` → `test_file.md`
- `My-File.md` → `my_file.md`
- `myFile.md` → `my_file.md`

**Exceptions**:
- ✅ `README.md`, `AGENTS.md`, `CLAUDE.md`, `GEMINI.md`
- ✅ `.claude/skills/*/SKILL.md`
- ✅ `~/.claude/plans/*` (Claude Code system files with hyphenated names)

**Integrations**:
- `.claude/skills/create-documentation` (naming standards)
- `lib/output-helpers.sh` → `print_correction_condensed()` function

**Output Example**:
```text
✓ AUTO-CORRECTED: TEST_FILE.md → test_file.md (See create-documentation: Naming Conventions)
```

**Logs to**: `.claude/hooks/logs/quality-checks.log`

**Responsibility Boundary**:
- **Filename corrections ONLY** - Renames to lowercase snake_case
- **Does NOT validate content** - See `enforce-markdown-strict.sh` for structure validation
- This separation ensures validation happens pre-submit, renaming happens post-write

---

#### `validate-post-response.sh`
**What it does**: Detects code patterns and logs quality check reminders

**Triggers**: After file edit operations (Edit, Write)

**Detects Patterns**:
- Animation code → Reminds about performance, mobile timing
- Async operations → Reminds about error handling, timeouts
- Form handling → Reminds about validation, accessibility
- Initialization → Reminds about CDN-safe patterns
- Security risks → Reminds about XSS, input validation
- Code changes → Reminds about spec folder requirement

**Connects to**:
- `.claude/configs/skill-rules.json` → Reads `riskPatterns` definitions

**Behavior**: Non-blocking, silently logs reminders only

**Logs to**: `.claude/hooks/logs/quality-checks.log`

---

#### `remind-cdn-versioning.sh`
**What it does**: Reminds to update CDN version parameters after JS changes in `src/2_javascript/` (cache-busting)

**Output Example**:
```
⚡ REMINDER: JavaScript file modified
File: src/2_javascript/hero/hero_video.js
Run: python3 .claude/hooks/scripts/update_html_versions.py
Purpose: Increments version (e.g., page_loader.js?v=1.0.2 → v=1.0.3)
```

**Update Script**: `update_html_versions.py` scans `src/0_html/`, finds version params, increments patch version

**Behavior**: Non-blocking | Logs: `remind-cdn-versioning.log` | Performance: ~20-50ms

---

#### `suggest-cli-verification.sh`
**What it does**: Suggests CLI verification workflow after frontend code changes (`.js`, `.css` in `src/`)

**Output Example**:
```
💡 Frontend code modified. Consider running CLI verification:
   bdg https://anobel.com 2>&1
   bdg screenshot verification.png 2>&1
   bdg console logs 2>&1 | jq '.[] | select(.level=="error")'
   bdg stop 2>&1
📖 Full workflows: verification_workflows.md, debugging_workflows.md, performance_patterns.md
```

**Resources**:
- Skill: `.claude/skills/cli-chrome-devtools/`
- Examples: `performance-baseline.sh`, `animation-testing.sh`, `multi-viewport-test.sh`
- Workflows: `verification_workflows.md`, `debugging_workflows.md`, `performance_patterns.md`

**Behavior**: Non-blocking | Logs: `quality-checks.log` | Performance: <100ms

---

#### `skill-scaffold-trigger.sh`
**What it does**: Auto-scaffolds skill directory structure when SKILL.md is created

**Triggers**: After Write operations on `.claude/skills/*/SKILL.md` (file creation only, not edits)

**Creates**:
- `references/` directory with comprehensive README.md
- `assets/` directory with guidelines README.md
- Placeholder documentation with best practices

**Displays**:
- Success message listing created directories
- Next steps guidance (frontmatter, reference files, templates)
- Example reference to create-documentation

**Benefits**:
- Instant skill structure setup
- Consistent directory organization
- Helpful guidance included automatically
- Focus on content, not boilerplate

**Output Example**:
```
───────────────────────────────────────────────────────────────
✅ SKILL STRUCTURE SCAFFOLDED
───────────────────────────────────────────────────────────────
   Auto-created directories for: my-new-skill

   📁 Created: .claude/skills/my-new-skill/references/
   📁 Created: .claude/skills/my-new-skill/assets/

───────────────────────────────────────────────────────────────
📝 NEXT STEPS
───────────────────────────────────────────────────────────────
   1. Complete SKILL.md frontmatter (name, description, allowed-tools)
   2. Add reference files to references/ as needed
   3. Add templates/examples to assets/ if applicable
   4. Consider creating executable wrapper for CLI access

   💡 Tip: See .claude/skills/create-documentation/ for
      a complete example of a well-structured skill

───────────────────────────────────────────────────────────────
```

**Connects to**:
- `.claude/skills/create-documentation/assets/skill_asset_template.md` → Referenced in README
- `.claude/skills/create-documentation/references/skill_creation.md` → Best practices

**Behavior**: Non-blocking, silent if directories already exist

**No logs** (outputs directly to user for visibility)

---

#### `summarize-task-completion.sh`

**Purpose**: Displays agent completion summary after Task tool finishes, showing duration, status, and result preview

**Triggers**: After any Task tool completes

**Display Logic (Expandable Default)**:
- **1-2 agents (success)**: Compact single-line format
- **3+ agents**: Full verbose box with batch summary
- **Errors/timeouts**: Always verbose box

**Integrations**:
- `lib/agent-tracking.sh` → Duration calculation, batch aggregation
- `lib/output-helpers.sh` → Formatting functions
- State file: `/tmp/claude_hooks_state/agent_tracking.json`

**Behavior**:
- **Non-blocking** - Always allows (exit 0)
- **Informational** - Shows completion details
- **Batch aggregation** - Shows summary when all agents complete

**Example Output (Compact - success)**:
```bash
✅ Explore completed (45.2s) → Found auth implementations in src/auth/
```

**Example Output (Verbose - 3+ agents batch complete)**:
```bash
┌─────────────────────────────────────────────────────────────┐
│ ✅ PARALLEL DISPATCH COMPLETE (3/3)                        │
├─────────────────────────────────────────────────────────────┤
│ ├─ ✅ Explore (45.2s) - Found auth in src/                 │
│ ├─ ✅ Explore (28.1s) - Updated API docs                   │
│ └─ ✅ Explore (52.8s) - Created 15 tests                   │
│                                                             │
│ 📊 Total: 52.8s (vs ~126s sequential) = 2.4x speedup       │
└─────────────────────────────────────────────────────────────┘
```

**Example Output (Error - always verbose)**:
```bash
┌─────────────────────────────────────────────────────────────┐
│ ❌ SUB-AGENT ERROR                                          │
├─────────────────────────────────────────────────────────────┤
│ Agent: Code refactoring agent                               │
│ Duration: 45.2s                                             │
│                                                             │
│ Output:                                                     │
│ > Error: Connection timeout to external service...          │
└─────────────────────────────────────────────────────────────┘
```

**Performance**: <50ms target
**Logs to**: `.claude/hooks/logs/task-dispatch.log`

**Created**: 2025-11-25 (parallel agent display enhancement)

---

#### `detect-scope-growth.sh`

**Purpose**: Monitors for scope expansion during implementation and provides advisory warnings when scope grows significantly beyond initial estimate

**Triggers**: After Edit/Write operations (via `*` matcher)

**Detection Logic**:
- Reads initial scope from shared state (set by `enforce-spec-folder.sh`)
- Compares current file count in spec folder vs initial estimate
- Warns when growth exceeds 50% (growth_ratio > 150%)

**Integrations**:
- `lib/shared-state.sh` → State management for initial scope tracking
- `enforce-spec-folder.sh` → Sets initial scope state at conversation start
- State key: `initial_scope` (TTL: 7200s / 2 hours)

**Behavior**:
- **Non-blocking** - Advisory only (exit 0)
- **Silent** - No output unless scope growth detected
- **Helpful** - Suggests level upgrades based on growth

**Example Output**:
```bash
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
⚠️  SCOPE GROWTH DETECTED (Advisory)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Initial files: 2
Current files: 5
Growth: +150%

Consider:
  • Upgrading to Level 2 (add plan.md)
  • Adding tasks.md for tracking
  • Adding checklist.md for validation

This is advisory only - continue if scope growth is expected.
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

**Performance**: <10ms (early exit for non-relevant tools)
**Logs**: None (advisory output only)

**Created**: 2025-11-25 (spec 002-speckit/008-validation-enforcement)

---

### 3.4 PreCompact Hooks

#### `save-context-before-compact.sh`

**Purpose**: Automatically saves conversation context before compaction operations (manual `/compact` or automatic threshold)

**Triggers**:
- 🔑 Manual: User runs `/compact` command
- 🔄 Automatic: Context reaches ~75% threshold (auto-compaction)

**Payload Fields**:
- `trigger`: `"manual"` or `"auto"`
- `custom_instructions`: Optional user text (manual compaction only)
- `session_id`: Session identifier
- `cwd`: Current working directory

**Integrations**:
- `workflows-save-context` skill → Uses `generate-context.js`
- `lib/transform-transcript.js` → Transforms JSONL to JSON
- Transcript location: `~/.claude/projects/{project-slug}/{session-id}.jsonl`
- Output: `specs/###-folder/memory/` (or sub-folder when versioning active)
- Logging: `.claude/hooks/logs/precompact.log`, `performance.log`

**Sub-Folder Routing** (Spec Folder Versioning):
- Detects `.spec-active` marker → Routes to sub-folder memory/
- Passes full path: `"###-name/###-subfolder"` or `"###-name"`
- Auto-cleanup of stale markers
- Backward compatible with root-level folders

**Execution**:
- ⚡ **Synchronous** (2-5s delay acceptable)
- 🎯 **Cannot Block**: Compaction proceeds regardless of exit code
- 🔒 **Graceful Degradation**: Missing dependencies → warn and skip
- 📊 **Performance Target**: <5s (95th percentile)

**Features**:
- Project slug conversion: `/Users/name/project` → `-Users-name-project`
- Spec folder auto-detection (most recent `###-name` folder)
- Sub-folder support via `.spec-active` marker
- AUTO_SAVE_MODE environment variable (bypasses prompts)
- Comprehensive error handling with logging

**Example Output**:
```bash
💾 Saving context before compaction (manual trigger)...
   📝 Custom instructions: Save before long research session...
   📂 Found transcript: abc123def456.jsonl
   📁 Target spec: 004-precompact-hooks
   📂 Using active sub-folder: 002-testing
   ✅ Transcript transformed to JSON
   ✅ Context saved to: specs/004-precompact-hooks/002-testing/memory/
   🎯 Compaction can proceed
```

**Security**:
- Session ID sanitization (alphanumeric + dash/underscore only)
- Path validation with `realpath`
- No eval usage
- Input validation before processing

**Behavior**:
- **Always exits 0** (PreCompact cannot block by design)
- Saves before context loss (critical for long sessions)
- Logs all operations for debugging
- Timeout protection (30s max with fallback)

**Connects to**:
- `.claude/skills/workflows-save-context/scripts/generate-context.js` → Context generation
- `.claude/hooks/lib/transform-transcript.js` → JSONL→JSON conversion
- `.claude/hooks/lib/output-helpers.sh` → Logging functions
- `.claude/hooks/lib/exit-codes.sh` → Exit code constants

**Performance**:
- Typical: 2-3s (includes transcript transformation + Node.js execution)
- Target: <5s (95th percentile)
- Logged to: `.claude/hooks/logs/performance.log`

**No User Interaction**: Fully automated, runs silently unless errors occur

---

## 4. 🔑 EXIT CODE CONVENTION

**Standardized across all 18 hooks** (updated Nov 2025):

```
0 = Allow (hook passed, continue execution)
1 = Block (hook failed, stop execution with warning)
2 = Error (reserved for critical failures - currently unused)
```

### Blocking Hooks (use exit 1)
- `check-pending-questions.sh` - Blocks ALL tools when mandatory question pending (except AskUserQuestion)
- `enforce-markdown-strict.sh` - Blocks on critical markdown violations
- `enforce-verification.sh` - Blocks completion claims without evidence
- `validate-bash.sh` - Blocks wasteful commands (context bloat prevention)
- `validate-spec-final.sh` - Blocks on spec folder validation failures (SpecKit quality gate)

### Advisory Hooks (exit 0 only)
- `workflows-save-context-trigger.sh` - Auto-save context (non-blocking)
- `validate-skill-activation.sh` - Skill suggestions (non-blocking)
- `orchestrate-skill-validation.sh` - Skill orchestration (non-blocking)
- `suggest-semantic-search.sh` - Search reminders (non-blocking)
- `suggest-code-mode.sh` - Code Mode suggestions (non-blocking)
- `detect-mcp-workflow.sh` - MCP workflow detection (non-blocking)
- `enforce-spec-folder.sh` - Spec folder prompts (non-blocking)
- `validate-mcp-calls.sh` - MCP call pattern education (non-blocking)
- `enforce-markdown-post.sh` - Auto-fix filenames (non-blocking)
- `validate-post-response.sh` - Quality reminders (non-blocking)
- `skill-scaffold-trigger.sh` - Directory scaffolding (non-blocking)
- `remind-cdn-versioning.sh` - CDN update reminder (non-blocking)
- `save-context-before-compact.sh` - PreCompact context backup (always allows, cannot block)

### Exit Code Usage

**Exit 0**: Hook passed OR advisory-only hook
**Exit 1**: Blocking error - stops execution with user-visible message
**Exit 2**: Reserved for future use (critical system failures)

---

## 5. ⚡ PERFORMANCE EXPECTATIONS

All hooks include a `PERFORMANCE TARGET` comment in their header specifying expected execution time.

**Target execution times** (95th percentile):

### Lightweight Hooks (<50ms)
Simple pattern matching, no file I/O:
- `suggest-semantic-search.sh` - Pattern matching in prompt: ~15-30ms
- `enforce-verification.sh` - Completion claim detection: ~20-40ms

### Validation Hooks (<100ms)
Pattern matching, validation logic, minimal I/O:
- `validate-bash.sh` - Command validation, security checks: ~30-60ms
- `enforce-spec-folder.sh` - State marker checks, folder validation: ~50-100ms
- `validate-skill-activation.sh` - JSON parsing (cached), skill matching: ~80-120ms

### Analysis Hooks (<200ms)
File reading, content analysis, git operations:
- `enforce-markdown-post.sh` - File renaming, git operations: ~60-120ms
- `enforce-markdown-strict.sh` - Markdown validation, multiple rules: ~100-180ms
- `validate-post-response.sh` - File scanning, security analysis: ~80-150ms
- `remind-cdn-versioning.sh` - File path checks, pattern matching: ~20-50ms
- `skill-scaffold-trigger.sh` - Directory creation, file operations: ~40-80ms
- `validate-spec-final.sh` - SpecKit validation library (5 checks): **<150ms** (quality gate must be fast)

### Heavy Processing (2-5s)
External tool execution, blocking by design:
- `workflows-save-context-trigger.sh` - Node.js script execution: **2-5 seconds**
  - Manual save: 2-3 seconds
  - Auto-save (with analysis): 3-5 seconds
  - **Intentionally synchronous** for guaranteed completion
- `save-context-before-compact.sh` - PreCompact transcript backup: **<5 seconds**
  - JSONL→JSON transformation: 1-2 seconds
  - Node.js execution (generate-context.js): 1-3 seconds
  - **Non-blocking** (compaction proceeds regardless)

### Performance Monitoring

All hooks log execution time to `.claude/hooks/logs/performance.log`:

```bash
# View recent performance
tail -20 .claude/hooks/logs/performance.log

# Check specific hook
grep "validate-bash" .claude/hooks/logs/performance.log

# Find slow executions (>100ms)
awk '$3 > 100 {print}' .claude/hooks/logs/performance.log
```

### Optimization Features
- **JSON caching**: skill-rules.json cached in `/tmp/` (30-40% faster)
- **State marker**: `.spec-active` file avoids repeated folder checks
- **Lazy loading**: Only process files when patterns match

---

## 6. 🔗 HOW HOOKS CONNECT

### Connection Flow

```text
User Prompt
    ↓
┌─────────────────────────────────────────────────────────────┐
│ UserPromptSubmit Hooks (8)                                  │
├─────────────────────────────────────────────────────────────┤
│ 1. workflows-save-context-trigger    → transform-transcript.js        │
│                             → workflows-save-context skill            │
│                             → specs/###/memory/ OR memory/  │
│                                                             │
│ 2. validate-skill-activation → skill-rules.json (skills)    │
│                              → Displays CRITICAL priority   │
│                              → Logs HIGH/MEDIUM priority    │
│                              → Prints doc guidance if needed│
│                                                             │
│ 3. suggest-semantic-search  → mcp_semantic_search.md        │
│                             → MCP tools reminder            │
│                                                             │
│ 4. suggest-code-mode        → mcp_code_mode.md              │
│                             → Code Mode benefits reminder   │
│                             → MCP tool efficiency guidance  │
│                                                             │
│ 5. detect-mcp-workflow      → Multi-tool workflow detection │
│                             → Code Mode pattern suggestion  │
│                                                             │
│ 6. enforce-spec-folder     → specs/** + skill-rules.json    │
│                             → conversation_documentation.md │
│                             → Discovers related specs       │
│                             → Hard-blocks missing docs      │
│                             → Logs to spec-enforcement.log  │
│                                                             │
│ 7. enforce-verification     → Blocks unverified completions │
│                             → Requires browser evidence     │
│                             → Iron Law enforcement          │
│                                                             │
│ 8. enforce-markdown-strict  → create-documentation skill    │
│                             → C7score quality analysis      │
│                             → Git status (modified .md)     │
│                             → BLOCKS if critical violations │
│                             → Condensed blocking output     │
│                             → Success indicators            │
├─────────────────────────────────────────────────────────────┤
│ PreToolUse Hooks (4)                                        │
├─────────────────────────────────────────────────────────────┤
│ 1. check-pending-questions  → BLOCKS ALL tools if question  │
│                               pending (except AskUserQuestion)│
│                             → Enforces mandatory questions  │
│                             → lib/signal-output.sh          │
│                                                             │
│ 2. validate-bash            → Validates command patterns    │
│                             → BLOCKS wasteful file reads    │
│                             → Whitelists .claude/ paths     │
│                                                             │
│ 3. validate-mcp-calls       → Detects direct MCP calls      │
│                             → Educational Code Mode warning │
│                                                             │
│ 4. validate-spec-final      → SpecKit pre-commit gate       │
│                             → lib/template-validation.sh    │
│                             → 5 validation functions        │
│                             → BLOCKS on validation fails    │
└─────────────────────────────────────────────────────────────┘
    ↓
Tool Executes (Bash, Write, Edit, etc.)
    ↓
┌─────────────────────────────────────────────────────────────┐
│ PostToolUse Hooks (6)                                       │
├─────────────────────────────────────────────────────────────┤
│ 1. enforce-markdown-post    → Auto-renames .md files        │
│                             → lowercase_snake_case.md       │
│                             → Condensed output (1 line)     │
│                             → Logs to quality-checks.log    │
│                                                             │
│ 2. validate-post-response   → skill-rules.json (patterns)   │
│                             → Detects risk patterns         │
│                             → Logs to quality-checks.log    │
│                                                             │
│ 3. remind-cdn-versioning    → Detects JS file changes       │
│                             → Reminds version parameter bump│
│                             → update_html_versions.py       │
│                             → CDN cache-busting workflow    │
│                                                             │
│ 4. suggest-cli-verification → Detects frontend code changes │
│                             → Suggests CLI verification     │
│                             → browser-debugger-cli (bdg)    │
│                             → Logs to quality-checks.log    │
│                                                             │
│ 5. skill-scaffold-trigger   → Auto-creates skill structure  │
│                             → references/ and assets/ dirs  │
│                             → Helpful README placeholders   │
│                             → Next steps guidance           │
│                                                             │
│ 6. summarize-task-completion→ Logs task completion metrics  │
│                             → Tracks files modified         │
│                             → Duration and tool usage       │
│                             → Logs to task-dispatch.log     │
└─────────────────────────────────────────────────────────────┘
    ↓
┌─────────────────────────────────────────────────────────────┐
│ PreCompact Hooks (1) 🆕                                     │
├─────────────────────────────────────────────────────────────┤
│ 1. save-context-before-compact → Backs up transcript        │
│                                → lib/transform-transcript.js│
│                                → workflows-save-context skill│
│                                → specs/###/memory/ OR        │
│                                   ###-name/###-sub/memory/  │
│                                → Always exits 0 (non-block) │
└─────────────────────────────────────────────────────────────┘
    ↓
Result Returned to User
```

### Central Hub: `skill-rules.json`

The configuration file `.claude/configs/skill-rules.json` is the **central connection point**:

**Used by 2 hooks**:
1. `validate-skill-activation.sh` → Reads `.skills{}` definitions
2. `validate-post-response.sh` → Reads `.riskPatterns{}` definitions

**Defines**:
- 22 skills with keywords, patterns, priorities, file triggers
- 7 risk pattern categories with detection patterns and reminders

### Shared Library: `output-helpers.sh`

**Used by all hooks** for consistent formatting:
- Functions: `print_message()`, `print_section()`, `print_bullet()`
- Emoji standards: ℹ️ INFO, ✅ SUCCESS, ⚠️ WARN, ❌ ERROR
- Priority indicators: 🔴 CRITICAL, 🟡 HIGH, 🔵 MEDIUM

### Log Files Connection

Most hooks write to `.claude/hooks/logs/`:
- `workflows-save-context-trigger.sh` → `auto-workflows-save-context.log`
- `validate-skill-activation.sh` → `skill-recommendations.log`
- `enforce-markdown-post.sh` → `quality-checks.log`
- `enforce-markdown-strict.sh` → `quality-checks.log`
- `validate-post-response.sh` → `quality-checks.log`
- `enforce-spec-folder.sh` → `spec-enforcement.log`
- `skill-scaffold-trigger.sh` → No logs (outputs directly to user for visibility)
- All 8 hooks → `performance.log` (execution timing)

---

## 7. 📚 SHARED LIBRARIES

### Compatibility

**Bash Version**: All hooks require **Bash 3.2 or later**

**Platform Support**:
- ✅ macOS 10.15+ (default bash 3.2.57)
- ✅ Linux with bash 3.2+ or 4.x+

**Compatibility Techniques**:
- Case conversion via `tr '[:upper:]' '[:lower:]'` (not `${var,,}`)
- Standard redirection `2>/dev/null` (not `&>>`)
- Indexed arrays only (no associative arrays)
- Portable command substitution `$()`

All hooks include `# COMPATIBILITY: Bash 3.2+ (macOS and Linux compatible)` in their headers.

### `lib/output-helpers.sh`
**Purpose**: Standardized visual output formatting for all hooks

**Provides**:
- Consistent color-coded messages (INFO, SUCCESS, WARN, ERROR)
- Emoji indicators: ℹ️ ✅ ⚠️ ❌ | 🔴 🟡 🔵
- Visual separators and section headers
- Dependency checking and JSON validation
- Condensed output helpers for reduced terminal verbosity

**Key Functions**:
- `print_message()` - Status messages with color/emoji
- `print_section()` - Boxed section headers
- `print_bullet()` - Bullet points
- `check_dependency()` - Silently verify commands
- `validate_json()` - Validate JSON files
- `print_correction_condensed()` - Single-line auto-correction notices
- `print_blocking_error_condensed()` - Condensed blocking errors (8-10 lines)

**Used by**: All 11 hooks

### `lib/exit-codes.sh`

**Purpose**: Standard exit code constants for consistent hook behavior

**Location**: `.claude/hooks/lib/exit-codes.sh`

**Provides**:
- `EXIT_ALLOW=0` - Hook passed, continue execution
- `EXIT_BLOCK=1` - Hook blocked, stop with warning
- `EXIT_ERROR=2` - Internal hook error (not for blocking)

**Why it exists**: Ensures all hooks use consistent exit codes (see Section 4)

**Usage**:
```bash
source "$HOOKS_DIR/lib/exit-codes.sh"

if [ some_validation_failed ]; then
  print_error_box "Validation Failed" "Details here"
  exit $EXIT_BLOCK  # Consistent exit code
fi

exit $EXIT_ALLOW  # Allow execution
```

**Used by**: All hooks that need exit code constants

### `lib/transform-transcript.js`
**Purpose**: Convert Claude Code transcript (JSONL) to workflows-save-context format (JSON)

**Used by**: `workflows-save-context-trigger.sh` hook

**Transforms**:
- Extracts user prompts and assistant responses
- Filters system messages and tool calls
- Structures conversation flow for documentation
- Prepares data for `workflows-save-context` skill's generate-context.js

### `lib/shared-state.sh`
**Purpose**: Inter-hook communication library providing atomic read/write operations for sharing state between hooks in the same session

**Used by**: `check-pending-questions.sh`, `signal-output.sh`, `enforce-spec-folder.sh`

**State Directory**: `/tmp/claude_hooks_state/`

**Provides**:
- Atomic file writes (temp + mv pattern)
- Staleness checking with configurable max age
- Cross-platform support (macOS + Linux)
- Session-scoped state (temp directory)

**Key Functions**:
- `write_hook_state(key, value)` - Atomically write JSON state for a key
- `read_hook_state(key, max_age)` - Read state with staleness check (default: 60s)
- `clear_hook_state(key)` - Clear specific key or all state (if key omitted)
- `has_hook_state(key, max_age)` - Check if state exists and is fresh
- `cleanup_stale_state(max_age_minutes)` - Remove files older than threshold

**Example**:
```bash
source "$HOOKS_DIR/lib/shared-state.sh"

# Write state
write_hook_state "complexity" '{"score":75,"domains":3}'

# Read with 60s staleness check
DATA=$(read_hook_state "complexity" 60)
if [ $? -eq 0 ]; then
  SCORE=$(echo "$DATA" | jq -r '.score')
fi

# Clear state
clear_hook_state "complexity"
```

**Security**:
- Key sanitization (alphanumeric + underscore/hyphen only)
- Atomic writes prevent partial reads
- No eval usage

---

### `lib/agent-tracking.sh`
**Purpose**: Agent lifecycle tracking library for Task tool dispatch visibility

**Used by**: `announce-task-dispatch.sh`, `summarize-task-completion.sh`

**State File**: `/tmp/claude_hooks_state/agent_tracking.json`

**Provides**:
- Agent start/completion tracking
- Duration calculation
- Batch aggregation for parallel dispatches
- Session agent counting

**Key Functions**:
- `generate_agent_id()` - Generate unique agent ID
- `start_agent_tracking(id, description, model, timeout)` - Record agent launch
- `complete_agent_tracking(id, status, duration_ms, preview)` - Record completion
- `create_batch_dispatch()` - Create new batch for parallel agents
- `add_agent_to_batch(batch_id, agent_id)` - Link agent to batch
- `is_batch_complete(batch_id)` - Check if all agents done
- `get_agent_count()` - Get session agent count for display logic
- `get_batch_summary(batch_id)` - Get aggregated batch data

**Example**:
```bash
source "$HOOKS_DIR/lib/agent-tracking.sh"

# Track agent launch
AGENT_ID=$(generate_agent_id)
start_agent_tracking "$AGENT_ID" "Code agent" "sonnet" 300000

# Track completion
complete_agent_tracking "$AGENT_ID" "success" 45200 "Refactored auth..."

# Check display logic
if [ $(get_agent_count) -lt 3 ]; then
  # Compact display
else
  # Verbose display
fi
```

**Created**: 2025-11-25 (parallel agent display enhancement)

---

### `lib/signal-output.sh`
**Purpose**: Standardized signals for hooks to emit mandatory questions that the AI MUST respond to using AskUserQuestion

**Used by**: `enforce-spec-folder.sh` (and any hook needing mandatory questions)

**Signal Format**:
```
🔴 MANDATORY_USER_QUESTION
{"signal": "MANDATORY_QUESTION", "type": "...", "options": [...]}
```

**Provides**:
- Multi-stage question flow management
- Pending question state tracking
- Pre-built question emitters for common scenarios

**Key Functions**:
- `emit_mandatory_question(type, question, options, context)` - Emit question signal and set pending state
- `clear_pending_question()` - Clear pending question state
- `has_pending_question(max_age)` - Check if question is pending
- `get_question_stage()` - Get current stage in multi-stage flow
- `set_question_flow(stage, spec_folder, memory_files, user_response)` - Set flow state
- `clear_question_flow()` - Clear all flow state
- `is_in_question_flow()` - Check if in active multi-stage flow

**Convenience Functions**:
- `emit_spec_folder_question(folder, next_num, related)` - Spec folder selection
- `emit_memory_load_question(memory_files)` - Memory file loading
- `emit_skill_eval_question(skills)` - Mandatory skill evaluation
- `emit_task_change_question(current_spec, divergence)` - Task change detection (Nov 2025)

**Question Types**:
- `SPEC_FOLDER_CHOICE` - Select spec folder for documentation
- `MEMORY_LOAD` - Load previous session context
- `SKILL_EVAL` - Evaluate mandatory skills
- `TASK_CHANGE_DETECTED` - Task change detected mid-conversation (Nov 2025)
- `CUSTOM` - Any other mandatory question

**Flow Stages**:
- `initial` - No question pending, detect intent
- `spec_folder` - Spec folder question asked, awaiting answer
- `memory_load` - Memory load question asked, awaiting answer
- `task_change` - Task change question asked, awaiting answer (Nov 2025)
- `complete` - All questions answered, proceed

**Integration**:
- Sets `pending_question` state for `check-pending-questions.sh` blocking
- AI detects `🔴 MANDATORY_USER_QUESTION` signal and responds with `AskUserQuestion`

---

### `lib/spec-context.sh`
**Purpose**: Spec folder state marker management and mid-conversation task change detection (Nov 2025)

**Used by**: `enforce-spec-folder.sh`, `workflows-save-context-trigger.sh`

**Provides**:
- Spec folder marker management (create, read, cleanup)
- Substantial content detection for mid-conversation state
- Sub-folder versioning support (parent/child folder detection)
- Topic fingerprinting for task change detection (Nov 2025)

**Session-Isolated Marker Functions (V9 - Nov 2025)**:
- `get_spec_marker_path(session_id)` - Get session-aware marker path
  - With SESSION_ID: Returns `.claude/.spec-active.{SESSION_ID}` (isolated per session)
  - Without SESSION_ID: Returns `.claude/.spec-active` (legacy fallback)
  - Enables multiple concurrent Claude Code sessions with independent spec contexts

**Marker Management Functions**:
- `has_substantial_content(spec_folder)` - Check if mid-conversation (marker exists + folder valid)
- `create_spec_marker(spec_path)` - Create legacy path-only marker
- `cleanup_spec_marker()` - Remove marker file
- `check_marker_staleness()` - Verify marker points to valid folder
- `has_skip_marker()` / `create_skip_marker()` / `cleanup_skip_marker()` - Skip marker handling

**Sub-Folder Versioning Functions**:
- `has_root_level_content(spec_folder)` - Check for root-level MD files
- `get_next_subfolder_number(spec_folder)` - Get next sequential number (001, 002, etc.)
- `get_parent_folder(spec_folder)` - Extract parent from sub-folder path
- `is_parent_folder(spec_folder)` - Check if folder has numbered sub-folders
- `get_active_child(spec_folder)` - Get currently active sub-folder from marker

**Topic Fingerprinting Functions (Nov 2025)**:
- `extract_prompt_keywords(text)` - Extract significant keywords (filters stop words, 3+ chars, returns top 10)
- `create_spec_marker_with_fingerprint(path, prompt)` - Create JSON marker with keywords
- `read_spec_marker()` - Read marker (handles legacy path-only AND JSON formats)
- `get_marker_path()` - Get spec path from marker (either format)
- `get_marker_keywords()` - Get stored keywords from JSON marker
- `calculate_divergence_score(prompt)` - Calculate keyword overlap (0-100%, higher = more different)
- `is_task_change_likely(prompt, threshold)` - Check if divergence exceeds threshold (default: 60%)

**Enhanced Marker Format** (JSON):
```json
{
  "path": "specs/122-skill-standardization",
  "topic_keywords": ["skill", "standardization", "alignment"],
  "created_at": "2025-11-26T10:00:00Z"
}
```

**Backward Compatibility**: `read_spec_marker()` auto-converts legacy path-only markers to JSON structure

---

### `lib/template-validation.sh`
**Purpose**: SpecKit template validation library providing quality checks and content validation functions

**Used by**: `validate-spec-final.sh` (PreToolUse hook)

**Provides**:
- 5 core validation functions for spec folder quality gates
- Template structure enforcement
- Content adaptation verification
- Metadata completeness checking
- Cross-reference traceability validation

**Key Functions**:
1. `validate_template_source()` - Checks for SPECKIT_TEMPLATE_SOURCE marker in files
   - Verifies template provenance and prevents template bypass
   - Returns: 0 on pass, 1 on missing marker

2. `validate_section_completeness()` - Ensures all required sections present for template type
   - Validates H2 section headers match template requirements
   - Template-specific section lists (spec/plan/tasks/research/spike/etc.)
   - Returns: 0 if all sections present, 1 if sections missing

3. `validate_content_adaptation()` - Confirms placeholders replaced and sample content removed
   - Detects `[PLACEHOLDER]`, `[YOUR_VALUE_HERE]`, `[NEEDS CLARIFICATION]`
   - Identifies `<!-- SAMPLE CONTENT -->` markers
   - Returns: 0 if content adapted, 1 if placeholders remain

4. `validate_metadata()` - Validates metadata block completeness
   - Checks required fields present (Category, Tags, Priority, etc.)
   - Template-specific metadata requirements
   - Returns: 0 if metadata complete, 1 if fields missing

5. `validate_traceability()` - Checks cross-references between spec/plan/tasks files
   - Verifies "See spec.md" / "See plan.md" references exist
   - Ensures documentation coherence across files
   - Returns: 0 if traceability maintained, 1 if references broken

**Configuration**:
- Optional config: `.claude/configs/template-validation.json`
- Template directory: `.opencode/speckit/templates/`
- Performance budget: 150ms total validation time

**Validation Categories**:
- **P0 (Critical)**: Template bypass, section completeness, structure
- **P1 (High)**: Metadata, traceability, user story independence
- **P2 (Medium)**: Content adaptation, pre-commit validation
- **P3 (Low)**: Emoji, hierarchy, hash verification

**Dependencies**:
- `grep` - Pattern matching
- `awk` - Text processing
- `sed` - Stream editing
- `jq` (optional) - JSON config parsing

**Error Handling**:
- Logs validation errors to stderr
- Returns specific exit codes for each validation type
- Graceful degradation if dependencies unavailable

**Created**: 2025-11-24 (spec 003-speckit-rework/003-template-enforcement/)

---

## 8. 📊 LOGS DIRECTORY

All hooks write to `.claude/hooks/logs/` for debugging and audit trail.

### Logging Strategy

**Convention**: One log file per hook, named `<hook-name>.log`

**Pattern**: `LOG_FILE="$LOG_DIR/$(basename "$0" .sh).log"`

**Benefits**:
- Simplified debugging (one log per hook)
- No log file sharing conflicts
- Consistent naming across all hooks
- Easy to locate hook-specific logs

### Log Files

**PostToolUse Hooks**:
- `enforce-markdown-post.log` - Markdown filename corrections
- `remind-cdn-versioning.log` - CDN version update reminders
- `skill-scaffold-trigger.log` - Skill directory scaffolding events
- `validate-post-response.log` - Quality check reminders, security pattern detection

**PreToolUse Hooks**:
- `validate-bash.log` - Bash command validation, security blocks

**UserPromptSubmit Hooks**:
- `workflows-save-context-trigger.log` - Auto-save trigger events (keyword/threshold)
- `validate-skill-activation.log` - Skill recommendations, matched patterns
- `enforce-spec-folder.log` - Spec folder enforcement, block/allow outcomes
- `enforce-verification.log` - Verification enforcement triggers
- `enforce-markdown-strict.log` - Markdown validation enforcement
- `suggest-semantic-search.log` - Semantic search suggestions

**Shared**:
- `performance.log` - Execution timing for all hooks (format: `[YYYY-MM-DD HH:MM:SS] hook_name Xms`)

### Usage Examples

```bash
# View recent entries from specific hooks
tail -n 50 .claude/hooks/logs/validate-skill-activation.log
tail -n 50 .claude/hooks/logs/workflows-save-context-trigger.log

# Search for specific patterns
grep "git-commit" .claude/hooks/logs/validate-skill-activation.log
grep "SECURITY CHECK" .claude/hooks/logs/validate-post-response.log

# View markdown enforcement logs
cat .claude/hooks/logs/enforce-markdown-post.log
cat .claude/hooks/logs/enforce-markdown-strict.log

# Check hook performance
tail -20 .claude/hooks/logs/performance.log
grep "validate-bash" .claude/hooks/logs/performance.log

# View all logs for a specific hook type
ls -lh .claude/hooks/logs/*.log
```

### Maintenance Scripts

**Automated log rotation**: Use `rotate-logs.sh` to manage log file size. See [Section 8 - Helper Scripts](#8-️-helper-scripts) for complete usage details.

**Recommended**: Run weekly or when logs exceed threshold (10,000 lines)

**Maintenance**: Log files grow over time. Archives are compressed, timestamped, and stored in `.claude/hooks/logs/archive/` (not tracked in git).

---

## 9. ⚙️ CONFIGURATION

### `.claude/configs/skill-rules.json`

**Central hub** connecting hooks to skills and patterns.

**Structure**:
```json
{
  "skills": {
    "skill-name": {
      "type": "knowledge|workflow|tool",
      "enforcement": "strict|suggest",
      "priority": "critical|high|medium",
      "description": "Brief description",
      "promptTriggers": {
        "keywords": ["word1", "word2"],
        "intentPatterns": ["regex1", "regex2"]
      },
      "fileTriggers": {
        "pathPatterns": ["src/**/*.js"],
        "contentPatterns": ["pattern1"]
      },
      "alwaysActive": true|false
    }
  },
  "riskPatterns": {
    "category-name": {
      "patterns": ["regex1", "regex2"],
      "reminder": "Quality check reminder text"
    }
  }
}
```

**Used by**:
- `validate-skill-activation.sh` → Reads `skills{}` for prompt matching
- `validate-post-response.sh` → Reads `riskPatterns{}` for code pattern detection

**Current Skills** (13 total):

**Skills with directories** (6):
- cli-gemini, cli-codex, create-documentation, create-flowchart, workflows-save-context, workflows-code, workflows-git

**Knowledge-based skills** (7):
- animation-strategy, code-standards ⭐ (alwaysActive), conversation-documentation ⭐ (alwaysActive)
- debugging, document-style-guide, initialization-pattern, webflow-platform-constraints

Note: Skill directories are in `.claude/skills/`. Knowledge-based skills reference files in `.claude/knowledge/`.

**Current Risk Patterns** (7 categories):
- animation, asyncOperations, commitOperations, formHandling
- initialization, securityRisks, specFolderRequired

### `.claude/configs/skill-rules.schema.json`

**Purpose**: JSON Schema (Draft 7) for validating skill-rules.json structure

**Validates**:
- Skill types: `knowledge|workflow|tool`
- Enforcement modes: `strict|suggest`
- Priority levels: `critical|high|medium|low`
- Required fields and structure
- Pattern syntax

**Validation Script**:
```bash
bash .claude/hooks/scripts/validate-config.sh
```

**Recommended**: Run before editing skill-rules.json to prevent configuration errors

### `.claude/configs/template-validation.json`

**Purpose**: SpecKit template validation configuration (optional)

**Location**: `.claude/configs/template-validation.json`

**Status**: Optional - if file doesn't exist, validation uses built-in defaults

**Used by**:
- `validate-spec-final.sh` (PreToolUse hook)
- `lib/template-validation.sh` (shared library)

**Contains**:
- Template-specific validation rules
- Required section definitions per template type
- Placeholder detection patterns
- Metadata requirement rules
- Cross-reference validation settings

**Example structure**:
```json
{
  "templates": {
    "spec_template": {
      "required_sections": ["OBJECTIVE", "SCOPE", "SUCCESS CRITERIA"],
      "optional_sections": ["RISKS", "DEPENDENCIES"],
      "metadata_required": true
    }
  },
  "validation": {
    "strict_mode": false,
    "block_on_warnings": false
  }
}
```

**Default behavior**: If file missing, validation uses built-in section definitions from `template-validation.sh`

---

## 10. 🛠️ HELPER SCRIPTS

### `.claude/hooks/scripts/find-related-spec.sh`

**Purpose**: Standalone tool to search for related spec folders by keywords

**Usage**:
```bash
.claude/hooks/scripts/find-related-spec.sh "keyword1 keyword2"
```

**Examples**:
```bash
# Search for markdown-related specs
.claude/hooks/scripts/find-related-spec.sh "markdown optimizer"

# Search for hero animation specs
.claude/hooks/scripts/find-related-spec.sh "hero animation"

# Search for authentication specs
.claude/hooks/scripts/find-related-spec.sh "auth"
```

**How it Works**:
1. Searches spec folder names (highest priority - score 10)
2. Searches spec.md titles (medium priority - score 5)
3. Searches spec.md content first 50 lines (low priority - score 1)
4. Extracts status from YAML frontmatter
5. Returns top 5 matches ranked by score

**Output Format**:
```
Related specs found for: markdown optimizer
──────────────────────────────────────────────────────────────

083-create-documentation
  Status: ✓ ACTIVE
  Path: /path/to/specs/083-create-documentation
  Description: Unified markdown and skill management specialist...

──────────────────────────────────────────────────────────────
Found 2 related spec(s)

Guidelines: .claude/knowledge/conversation_documentation.md Section 7
```

**Exit Codes**:
- `0` - Matches found
- `1` - No matches or error

**Used by**:
- `enforce-spec-folder.sh` hook (automatic discovery)
- AI agents (manual search before creating new specs)
- Users (command-line spec discovery)

**Status Field Support**:
- `active` - Currently being worked on (highest priority)
- `draft` - Planning phase
- `paused` - Temporarily on hold
- `complete` - Implementation finished
- `archived` - Historical record
- Default: `active` (if status field missing)

**Performance**: <50ms for typical spec directory (~50 folders)

---

### `.claude/hooks/scripts/update_html_versions.py`

**Purpose**: Increment CDN version parameters in HTML files for cache-busting

**Usage**:
```bash
python3 .claude/hooks/scripts/update_html_versions.py
```

**What it does**:
1. Scans all HTML files in `src/0_html/` (recursive)
2. Finds CDN URLs with version parameters (e.g., `hero_video.js?v=1.1.27`)
3. Increments the patch version by 1 (e.g., `1.1.27` → `1.1.28`)
4. Updates files in-place
5. Provides comprehensive summary of all changes

**Pattern Matching**:
- CDN URL: `https://pub-85443b585f1e4411ab5cc976c4fb08ca.r2.dev/`
- File types: `.js` and `.css`
- Version format: `?v=MAJOR.MINOR.PATCH` (e.g., `?v=1.1.27`)

**Output Example**:
```
⚡ CDN VERSION UPDATER
───────────────────────────────────────────────────────────────
Found 18 HTML file(s)

✓ src/0_html/home.html
  └─ hero_video.js: v1.1.27 → v1.1.28
  └─ marquee_brands.js: v1.1.27 → v1.1.28

✓ Updated 18 file(s) with 82 version change(s)

Summary of version changes:
  • hero_video.js: v1.1.27 → v1.1.28
  • marquee_brands.js: v1.1.27 → v1.1.28
  ...

Next steps:
  1. Review changes: git diff src/0_html/
  2. Test locally before deploying
  3. Deploy updated HTML to Webflow
───────────────────────────────────────────────────────────────
```

**When to use**:
- After modifying JavaScript files in `src/2_javascript/`
- After modifying CSS files
- Before deploying to production/staging
- When browsers are loading stale cached versions

**Triggered by**: `remind-cdn-versioning.sh` hook (reminder only, not automatic execution)

**Exit Codes**:
- `0` - Success (version updates completed)
- `1` - Error (HTML directory not found or processing failed)

**Performance**: ~100-200ms for typical workspace (18 HTML files)

**Documentation**: See `.claude/skills/workflows-code/references/implementation_workflows.md` Section 3

---

### `.claude/hooks/scripts/rotate-logs.sh`

**Purpose**: Rotate and compress hook log files

**Usage**:
```bash
bash .claude/hooks/scripts/rotate-logs.sh
```

**Behavior**:
- Rotates logs exceeding 10,000 lines
- Keeps last 1,000 lines in active log
- Archives remainder to `.claude/hooks/logs/archive/`
- Compresses archives with gzip
- Adds timestamp to archive filename

**Recommended Schedule**: Weekly or when logs exceed threshold

---

### `.claude/hooks/lib/migrate-spec-folder.sh`

**Purpose**: Sub-folder versioning for spec folders (enables reusing spec folders across multiple work sessions)

**Location**: `.claude/hooks/lib/migrate-spec-folder.sh`

**Trigger**: Manual execution when reusing existing spec folders

**What it does**:
1. Archives existing root-level spec content → `001-{original-topic}/`
2. Creates new numbered sub-folder → `00X-{new-name}/` (auto-increments)
3. Updates `.spec-active` marker to route context saves to new sub-folder
4. Creates fresh memory/ directory in new sub-folder
5. Preserves all original spec folder content in archive

**Usage**:
```bash
bash .claude/hooks/lib/migrate-spec-folder.sh \
  /full/path/to/specs/122-skill-standardization \
  new-subfolder-name
```

**Example**:
```
Input:
  specs/122-skill-standardization/
    ├── spec.md
    ├── plan.md
    └── memory/

Output:
  specs/122-skill-standardization/
    ├── 001-skill-standardization/  (archived original)
    │   ├── spec.md
    │   ├── plan.md
    │   └── memory/
    └── 002-new-subfolder-name/     (active workspace)
        ├── spec.md (fresh)
        ├── plan.md (fresh)
        └── memory/
```

**Integration**:
- Referenced in CLAUDE.md Section 2 (Sub-Folder Versioning)
- Used by `enforce-spec-folder.sh` when reusing spec folders
- Marker file: `.claude/.spec-active` tracks active sub-folder

**Exit Codes**:
- `0` - Migration successful
- `1` - Error (invalid path, permissions, etc.)

**Performance**: <100ms (file system operations)

---

### `.claude/hooks/scripts/validate-config.sh`

**Purpose**: Validate skill-rules.json against JSON schema

**Usage**:
```bash
bash .claude/hooks/scripts/validate-config.sh
```

**Validates**:
- JSON syntax correctness
- Required fields present
- Valid enum values
- Proper structure

**Recommended**: Run before committing changes to skill-rules.json
---

## 11. 💡 KEY BEHAVIORAL FEATURES

### Smart Spec Folder Enforcement

The `enforce-spec-folder.sh` hook now uses **mid-conversation detection** to avoid repeated prompts:

**How it works:**
- **Start of conversation**: Prompts for spec folder confirmation when folder is empty or has minimal content (≤2 files AND all <1000 bytes)
- **Mid-conversation**: Automatically skips validation when substantial content exists (>2 files OR any file >1000 bytes)
- **Detection method**: File system inspection only - no git, no timestamps, no external dependencies

**Benefits:**
- ✅ Only prompts once at the start
- ✅ No interruptions during active work
- ✅ Fast (<10ms overhead)
- ✅ Reliable content-based detection

**Example:**
```
First message with empty folder:
→ Shows confirmation prompt (A/B/C options)

Subsequent messages after spec.md created:
→ "✅ Mid-conversation: 076-feature-name (validation skipped)"
```

### Auto-Save Context

The `workflows-save-context-trigger.sh` hook automatically saves conversations:
- Triggered by keywords ("save context", "save conversation")
- Auto-triggers every 20 messages
- Saves to `specs/[###-name]/memory/`

### Skill Suggestions

The `validate-skill-activation.sh` hook suggests relevant skills based on prompt keywords, helping discover available automation and best practices.

---

## 12. 📖 ADDITIONAL RESOURCES

### Skills Documentation

**Skills README**: `.claude/skills/README.md`
- Comprehensive overview of all available skills
- Skill types and categorization (Workflow Orchestrators, Documentation Specialists, CLI Tool Wrappers)
- Installation and usage examples
- Creating new skills guide
- Integration with hooks system

**Key Skills**:
- `workflows-code` - Development workflow orchestration (implementation, debugging, verification)
- `workflows-git` - Git workflow orchestration (worktrees, commits, PRs)
- `workflows-save-context` - Conversation context preservation
- `create-documentation` - Markdown optimization and validation
- `create-flowchart` - ASCII flowchart generation
- `cli-codex` - OpenAI Codex CLI integration
- `cli-gemini` - Google Gemini CLI integration

### Knowledge Base

**Core Standards**:
- `.claude/knowledge/code_standards.md` - Naming conventions, file organization, commenting
- `.claude/knowledge/conversation_documentation.md` - Spec folder system and documentation levels
- `.claude/knowledge/mcp_code_mode.md` - Code Mode usage patterns for MCP tools
- `.claude/knowledge/mcp_semantic_search.md` - Intent-based code discovery

**Domain-Specific**:
- `.claude/knowledge/initialization_pattern.md` - CDN-safe initialization patterns
- `.claude/skills/workflows-code/references/animation_workflows.md` - Motion.dev and CSS animation patterns (integrated into workflows-code)
- `.claude/skills/workflows-code/references/webflow_patterns.md` - Webflow-specific constraints (integrated into workflows-code)

### Configuration

**skill-rules.json**: `.claude/configs/skill-rules.json`
- Central configuration for all skills
- 24 skill definitions (7 active + 17 knowledge-based)
- Trigger patterns (keywords + intent patterns)
- Priority levels (critical, high, medium)
- File trigger patterns

**skill-rules.schema.json**: `.claude/configs/skill-rules.schema.json`
- JSON Schema validation for skill-rules.json
- Ensures configuration correctness

### Cross-System Integration

**Hooks → Skills**:
- `validate-skill-activation.sh` → Reads skill-rules.json for recommendations
- `workflows-save-context-trigger.sh` → Uses workflows-save-context skill's generate-context.js
- `enforce-markdown-strict.sh` → Uses create-documentation for validation
- `skill-scaffold-trigger.sh` → Creates structure following create-documentation standards

**Hooks → Knowledge Base**:
- `suggest-code-mode.sh` → References mcp_code_mode.md
- `suggest-semantic-search.sh` → References mcp_semantic_search.md
- Multiple hooks → Reference code_standards.md for enforcement

**Skills → Knowledge Base**:
- `workflows-code` → initialization_pattern.md (also includes integrated animation_workflows.md and webflow_patterns.md)
- `code-standards` (skill) → code_standards.md
- `conversation-documentation` (skill) → conversation_documentation.md

### External Resources

**MCP Servers**:
- Semantic Search MCP - Intent-based code discovery
- Chrome DevTools MCP - Browser automation and testing
- Webflow MCP - CMS operations and site management
- Figma MCP - Design file integration

**CLI Tools**:
- **browser-debugger-cli (bdg)** - Direct CDP access via terminal for browser debugging, automation, and testing
  - Installation: `npm install -g browser-debugger-cli@alpha`
  - Skill: `.claude/skills/cli-chrome-devtools/SKILL.md` (complete documentation)
  - Use Cases: Screenshots, console logs, HAR files, performance metrics, DOM inspection
  - Workflows Integration:
    - `.claude/skills/workflows-code/references/debugging_workflows.md` (automated performance metrics)
    - `.claude/skills/workflows-code/references/animation_workflows.md` (visual regression testing)
    - `.claude/skills/workflows-code/references/performance_patterns.md` (performance budgets)
    - `.claude/skills/workflows-code/references/quick_reference.md` (quick examples)
- **OpenAI Codex CLI** - Alternative code generation perspective (skill: cli-codex)
- **Google Gemini CLI** - Web research and current information (skill: cli-gemini)
- **GitHub CLI (gh)** - PR creation and repository operations

### Support

**Questions or Issues**:
- Check hook logs: `.claude/hooks/logs/*.log`
- Review skill documentation: `.claude/skills/*/SKILL.md`
- Consult knowledge base: `.claude/knowledge/*.md`
- Validate configuration: `bash .claude/hooks/scripts/validate-config.sh`

**Contributing**:
- Follow code_standards.md for all modifications
- Use conversation_documentation.md spec folder system
- Test hooks with sample inputs before committing
- Update README when adding new hooks or features