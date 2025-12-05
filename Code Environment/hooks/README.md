# Claude Code Hooks

Automated workflows and quality checks for Claude Code interactions. Hooks trigger during operations to provide auto-save, skill suggestions, security validation, and quality reminders.

#### 📋 TABLE OF CONTENTS

1. [📖 OVERVIEW](#1--overview)
2. [🔄 HOOK LIFECYCLE](#2--hook-lifecycle)
3. [🎯 INSTALLED HOOKS](#3--installed-hooks)
4. [📤 HOOK OUTPUT VISIBILITY](#4--hook-output-visibility)
5. [🔑 EXIT CODE CONVENTION](#5--exit-code-convention)
6. [⚡ PERFORMANCE EXPECTATIONS](#6--performance-expectations)
7. [🔗 HOW HOOKS CONNECT](#7--how-hooks-connect)
8. [📚 SHARED LIBRARIES](#8--shared-libraries)
9. [📊 LOGS DIRECTORY](#9--logs-directory)
10. [⚙️ CONFIGURATION](#10-️-configuration)
11. [🛠️ HELPER SCRIPTS](#11-️-helper-scripts)
12. [💡 KEY BEHAVIORAL FEATURES](#12--key-behavioral-features)
13. [📖 ADDITIONAL RESOURCES](#13--additional-resources)
14. [🧪 TESTING](#14--testing)

---

## 1. 📖 OVERVIEW

This directory contains hooks that automatically trigger during Claude Code operations.

### Hook Types

**Input/Tool Processing:**
- **UserPromptSubmit**: Triggers before user prompts are processed
- **PreToolUse**: Triggers before Bash tool execution
- **PostToolUse**: Triggers after Write/Edit/NotebookEdit operations
- **PreCompact**: Triggers before context compaction (manual or automatic)

**Sub-Agent Lifecycle:**
- **SubagentStop**: Triggers when a sub-agent (Task tool) completes - can BLOCK bad output

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
│  - inject-datetime.sh (0) 🕐            │
│  - workflows-save-context-trigger.sh (0)│
│  - validate-skill-activation.sh (0)     │
│  - orchestrate-skill-validation.sh (0) 🆕│
│  - suggest-semantic-search.sh (0) 🆕    │
│  - suggest-mcp-tools.sh (0) 🆕          │
│  - enforce-spec-folder.sh (0*)          │
│  - enforce-git-workspace-choice.sh (0*) │
│  - enforce-verification.sh (1)          │
│  - enforce-markdown-strict.sh (1)       │
│  Note: (0*) = prompts but allows        │
│        (1)  = blocking                  │
│        (0)  = non-blocking              │
│        🕐   = Datetime context injection │
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
│  - enforce-markdown-pre.sh (1) 🛡️       │
│  - validate-spec-final.sh (1) 🆕        │
│  - announce-task-dispatch.sh (0) 🎯     │
│  - warn-duplicate-reads.sh (0) 🔄       │
│  - enforce-semantic-search.sh (0) 🔍    │
│  Note: (1) = blocks execution           │
│        (0) = educational warning        │
│        🆕  = Code Mode / SpecKit        │
│        🎯  = Agent lifecycle visibility │
│        🔄  = Context optimization       │
│        🛡️  = Filename enforcement       │
│        🔍  = Semantic search suggestion │
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
│  - enforce-markdown-naming.sh (0) 🔀    │
│  - validate-post-response.sh (0)        │
│  - remind-cdn-versioning.sh (0)         │
│  - skill-scaffold-trigger.sh (0)        │
│  - summarize-task-completion.sh (0) 🎯  │
│  - detect-scope-growth.sh (0) 📊        │
│  Note: (0) = non-blocking auto-fix      │
│        🎯  = Agent lifecycle visibility │
│        📊  = Scope monitoring           │
│        🔀  = Merged (v2.0.0)            │
└────────┬────────────────────────────────┘
         │
         ▼ (if Task tool used)
┌─────────────────────────────────────────┐
│  SubagentStop Hooks 🛡️                  │
│  - validate-subagent-output.sh (block)  │
│  Note: (block) = CAN block bad output   │
│        🛡️  = Quality gate for agents    │
│  Validates: errors, completeness,       │
│             alignment, security         │
│  Score < 40: BLOCKS with reason         │
│  Score 40-69: Warns but allows          │
│  Score 70+: Allows (good output)        │
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
│  - prune-context.sh (0) 🔄              │
│  - save-context-before-compact.sh (0)   │
│  Note: (0) = always allows (non-block)  │
│        🔄  = Context optimization       │
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

### Quick Reference Table

| Hook | Type | Purpose | Key Triggers | Exit | Perf |
|------|------|---------|--------------|------|------|
| inject-datetime | UserPromptSubmit | Inject current date/time into AI context | Every prompt | 0 | <5ms |
| workflows-save-context-trigger | UserPromptSubmit | Auto-save conversation context | `save context`, Every 20 msgs | 0 | <100ms |
| validate-skill-activation | UserPromptSubmit | Match prompts to skills (v2.0.0 - pre-compiled cache) | Every prompt | 0 | 97-1200ms |
| orchestrate-skill-validation | UserPromptSubmit | Calculate complexity, emit mandatory dispatch questions | Complexity ≥20% + 2+ domains | 0 | <100ms |
| suggest-semantic-search | UserPromptSubmit | Semantic search MCP (v2.0.0 - contextual patterns) | `find code`, `locate` | 0 | ~13ms |
| suggest-mcp-tools | UserPromptSubmit | MCP tools + Code Mode (merged v2.0.0) | `webflow`, `figma`, `notion` | 0 | ~20ms |
| suggest-prompt-improvement | UserPromptSubmit | Prompt quality reminders | All prompts | 0 | ~15ms |
| enforce-spec-folder | UserPromptSubmit | Spec folder validation | File modifications | 0* | <200ms |
| enforce-git-workspace-choice | UserPromptSubmit | Git workspace mandatory question | `new feature`, `create branch` | 0* | <100ms |
| enforce-verification | UserPromptSubmit | Require verification (v3.0.0 - 0% false positives) | Implementation tasks | 1 | ~50ms |
| enforce-markdown-strict | UserPromptSubmit | Markdown structure validation | Markdown edits | 1 | <200ms |
| validate-bash | PreToolUse | Block wasteful commands | Bash tool | 1 | <50ms |
| validate-mcp-calls | PreToolUse | Enforce Code Mode routing | MCP tools | 0 | ~30ms |
| check-pending-questions | PreToolUse | Mandatory question enforcement | Any tool | 1 | <10ms |
| validate-dispatch-requirement | PreToolUse | Require parallel dispatch | Task tool | 1 | ~25ms |
| enforce-markdown-pre | PreToolUse | Block invalid markdown filenames | Write/Edit/NotebookEdit | 1 | <50ms |
| validate-spec-final | PreToolUse | Final spec validation | Write/Edit/NotebookEdit | 1 | ~40ms |
| announce-task-dispatch | PreToolUse | Agent dispatch (v2.0.0 - rich metadata) | Task tool | 0 | <20ms |
| warn-duplicate-reads | PreToolUse | Duplicate detection (v2.0.0 - JSON intelligence) | Read/Grep/Glob | 0 | 25-55ms |
| enforce-markdown-naming | PostToolUse | Filename enforcement (merged v2.0.0) | Write/Edit/Task | 0 | <200ms |
| remind-cdn-versioning | PostToolUse | CDN reminders (v2.0.0 - multi-tier detection) | Edit CSS/JS | 0 | <20ms |
| skill-scaffold-trigger | PostToolUse | Auto-scaffold skill directories | Write SKILL.md | 0 | ~30ms |
| suggest-cli-verification | PostToolUse | CLI testing (fixed: 0%→100% detection) | Edit implementation | 0 | ~25ms |
| track-file-modifications | PostToolUse | File change tracking | Write/Edit | 0 | <15ms |
| validate-post-response | PostToolUse | Quality check reminders | Write/Edit code | 0 | ~20ms |
| verify-spec-compliance | PostToolUse | Spec folder compliance check | Write/Edit | 0 | ~30ms |
| detect-scope-growth | PostToolUse | Scope growth (v2.0.0 - NOW FUNCTIONAL) | Write/Edit .md | 0 | <50ms |
| summarize-task-completion | PostToolUse | Task summaries (fixed: duration calculation) | Task tool | 0 | ~20ms |
| validate-output-quality | PostToolUse | Fluff/ambiguity detection (v1.0.0) | Task tool | 0 | <100ms |
| validate-subagent-output | SubagentStop | Block bad sub-agent output (v1.0.0 - quality gate) | Task completion | 0/block | <50ms |
| prune-context | PreCompact | Context pruning (v2.0.0 - DCP-style output) | Before compaction | 0 | <5s |
| save-context-before-compact | PreCompact | Auto-save before compact | Before compaction | 0 | <10s |
| initialize-session | PreSessionStart | Session initialization | Session start | 0 | <50ms |
| cleanup-session | PostSessionEnd | Session cleanup | Session end | 0 | <100ms |

**Exit Codes**: `0` = Non-blocking | `0*` = Prompts user | `1` = Blocking

**Common Integrations**: All hooks log to `.claude/hooks/logs/` | Config: `skill-rules.json`, `template-validation.json` | Libraries: `lib/output-helpers.sh`, `lib/spec-context.sh`, `lib/signal-output.sh`

---

## 4. 📤 HOOK OUTPUT VISIBILITY

**CRITICAL**: Understanding how Claude Code displays hook output is essential for effective hook development.

### Output Visibility Rules

| Goal | Method | Exit Code | Stream | When Visible |
|------|--------|-----------|--------|--------------|
| **Always visible to user** | `echo '{"systemMessage": "..."}'` | 0 | stdout | Terminal (always) |
| Block + show message to user | `{"decision": "block", "reason": "..."}` | 0 | stdout (JSON) | Terminal |
| Claude context only | Plain text (UserPromptSubmit hooks) | 0 | stdout | Not visible to user |
| Verbose mode only | Plain stdout (other hook types) | 0 | stdout | Ctrl+O to see |
| Block with error to Claude | stderr message | 2 | stderr | Fed to Claude |

### JSON systemMessage Format

For messages that should **ALWAYS** appear in the user's terminal (regardless of verbose mode):

```bash
# Single-line JSON with systemMessage field
echo '{"systemMessage": "Your visible message here"}'
```

**Example - Agent dispatch notification:**
```bash
echo '{"systemMessage": "Agent #1 DISPATCHED: code-specialist | Model: opus | Task: Fix authentication bug"}'
```

**Example - Context pruning notification:**
```bash
echo '{"systemMessage": "Context pruned successfully - optimized for compaction"}'
```

### Common Mistakes

1. **Using plain echo expecting visibility** - Plain stdout only shows in verbose mode (Ctrl+O)
2. **Wrong exit code** - Exit 2 feeds stderr to Claude, exit 1 shows in verbose mode only
3. **Not enabling verbose mode during development** - Press Ctrl+O to see hook output
4. **UserPromptSubmit stdout confusion** - For this hook type, stdout becomes Claude context, not user-visible

### Safe JSON Construction

Use `jq` for proper JSON escaping:

```bash
# Safe JSON construction with dynamic values
local msg
msg=$(jq -n --arg text "$DYNAMIC_VALUE" '{systemMessage: $text}')
echo "$msg"
```

**Fallback for when jq unavailable:**
```bash
# Manual escaping helper
json_escape() {
  printf '%s' "$1" | jq -Rs '.' 2>/dev/null | sed 's/^"//;s/"$//' || \
  printf '%s' "$1" | sed 's/\\/\\\\/g; s/"/\\"/g'
}
```

### Hooks Using systemMessage

| Hook | Message Type |
|------|--------------|
| `signal-output.sh` | Mandatory question notifications |
| `announce-task-dispatch.sh` | Agent dispatch notifications |
| `prune-context.sh` | Context pruning status |
| `suggest-semantic-search.sh` | Semantic search recommendations |

---

### 3.1 Context Injection Hooks

#### inject-datetime.sh (UserPromptSubmit)
**Purpose**: Injects current date and time into every AI message for temporal awareness
**Output Format**: `Current date and time is Tuesday 2 December 09:07 2025`
**Features**:
  - Runs on EVERY user prompt (no filtering)
  - Single `date` call for efficiency (optimized from 5 separate calls)
  - Cross-platform: macOS and Linux compatible
  - Fallback for systems without `%-d` support
  - Performance logging to `performance.log`
**Performance**: <5ms (minimal overhead)
**Exit**: Always 0 (purely informational, never blocks)
**Use Case**: Ensures AI always knows current date/time for scheduling, deadlines, time-sensitive tasks

### 3.2 Critical Hooks (Detailed)

#### validate-skill-activation.sh (UserPromptSubmit) - v2.0.0
**Priority system**: 🔴 MANDATORY (shown), 🟡 HIGH (logged), 🔵 MEDIUM (logged)
**Features**: Documentation level estimation, spec folder number calculation, template commands, commitment structure (YES/NO evaluation)
**Performance**: Pre-compiled cache system (97-111ms for questions, 1000-1200ms for complex prompts)
  - Cache location: `/tmp/claude_hooks_cache/skill_data_*.cache`
  - Single jq execution for cache generation (was 140+ jq subprocess calls)
  - mtime-based invalidation, <5ms cache hit overhead
  - 76-97% faster than previous version
**Output**: See example in Section 11

#### enforce-spec-folder.sh (UserPromptSubmit)
**Smart detection**: Only prompts at conversation start, checks for substantial content
**Features**: Option D (load related context), task change detection, sub-folder routing
**Marker**: `.spec-active.{SESSION_ID}` (V9 session isolation)

#### orchestrate-skill-validation.sh (UserPromptSubmit)

**Purpose:** Calculate task complexity and emit mandatory questions for parallel agent dispatch decisions

**Execution:** Runs on every user prompt as UserPromptSubmit hook

**Decision Flow:**
1. Check for existing parallel dispatch preference (1-hour expiry)
2. Calculate complexity score (5-dimension weighted algorithm)
3. Decision logic:
   - If complexity ≥20% + ≥2 domains AND no preference:
     - Emit mandatory question via `emit_parallel_dispatch_question()`
     - Block all tools until user responds
   - If preference exists (auto/direct/parallel):
     - Apply preference automatically
     - Log decision to orchestrator.log
   - If ≥50% + 3+ domains:
     - Auto-dispatch with notification only

**User Response Options:**
- **A) Handle directly** - Sequential execution, no parallel agents
- **B) Create parallel agents** - Dispatch specialized sub-agents
- **C) Auto-decide** - Enable session auto-mode (use parallel when ≥35% + ≥2 domains)

**Override Phrases:**
- `"proceed directly"` - Force direct handling
- `"use parallel agents"` - Force parallel dispatch
- `"auto-decide"` - Enable auto-mode

**State Files:**
- `parallel_dispatch_completed.json` - User's choice (1-hour expiry)
- `parallel_dispatch_asked_ever.json` - First-time detection (24-hour expiry)

**Logs:**
- `.claude/hooks/logs/orchestrator.log` - Full complexity analysis + decision
- `/tmp/delegation-guidance.json` - Agent specifications for parallel dispatch

**Performance Target:** <100ms execution time

**Integration:**
- Works with `PreToolUse/check-pending-questions.sh` for blocking
- Uses `emit_parallel_dispatch_question()` from `lib/signal-output.sh`
- Reads from `lib/shared-state.sh` for preference persistence

#### enforce-markdown-pre.sh (PreToolUse)
**Blocks**: ALL CAPS filenames, hyphens, camelCase (except README.md, AGENTS.md, CLAUDE.md, GEMINI.md, SKILL.md)
**Enforces**: lowercase_snake_case.md naming convention
**Suggests**: Correct filename in error message
**Purpose**: PREVENT creation of markdown files with invalid naming (safety net for PostToolUse hook failures)

#### validate-bash.sh (PreToolUse)
**Blocks**: `cat` large files, `find` without limits, grep on binary, context-heavy operations
**Suggests**: Read/Grep/Glob tools as alternatives
**Purpose**: Prevent token bloat from wasteful commands

#### validate-mcp-calls.sh (PreToolUse)
**Enforces**: All MCP tools → Code Mode (`call_tool_chain`)
**Exception**: Sequential Thinking MCP (direct calls allowed)
**References**: `mcp_code_mode.md`

#### check-pending-questions.sh (PreToolUse)
**Blocks**: ALL tools except AskUserQuestion when `MANDATORY_USER_QUESTION` signal detected
**Purpose**: Enforce mandatory question responses
**Performance**: <10ms

### 3.3 Quality & Documentation Hooks

#### enforce-markdown-naming.sh (PostToolUse) - v2.0.0 Merged
**Purpose**: Unified markdown filename enforcement (merged from enforce-markdown-post.sh + enforce-markdown-post-task.sh)
**Auto-fixes**: ALL CAPS → lowercase, hyphens → underscores
**Preserves**: README.md, SKILL.md, AGENTS.md, CLAUDE.md, GEMINI.md exceptions
**Output**: Condensed (one-line per fix)
**Features**:
  - Handles both direct Write/Edit operations AND Task tool sub-agent modifications
  - Scans directories for violations after Task completion
  - Atomic rename support for case-insensitive filesystems

#### enforce-markdown-strict.sh (UserPromptSubmit)
**Validates**: Frontmatter, section order, heading hierarchy
**Auto-fixes**: Safe violations (H2 case, separators, emoji rules)
**Blocks**: Critical violations (missing frontmatter, wrong structure)

#### skill-scaffold-trigger.sh (PostToolUse)
**Triggers**: When SKILL.md written
**Creates**: `references/` and `assets/` directories
**Purpose**: Auto-scaffold skill structure

#### remind-cdn-versioning.sh (PostToolUse) - v2.0.0 Multi-Tier Detection
**Fixed**: 100% false negative rate (only triggered in test environments, now works in production)
**Multi-Tier Detection**: Production (critical), Staging (recommended), Development (silent)
  - Production: main/master branch + output dirs (public/dist/build), ENV vars (NODE_ENV=production)
  - Staging: staging/develop branch, staging dirs
  - Development: Silent (no spam)
**Smart Caching**: 1-hour per-file deduplication (prevents repetitive warnings)
**Purpose**: CDN cache-busting reminders for JavaScript/CSS changes
**References**: `update_html_versions.py` script

#### suggest-cli-verification.sh (PostToolUse) - Detection Fixed
**Fixed**: JSON parsing bug (0% → 100% detection rate)
  - Was using `.tool` (wrong), now uses `.tool_name` (correct)
  - Added camelCase support (`.filePath` alongside `.file_path`)
**Detects**: Frontend file changes (HTML/CSS/JS)
**Suggests**: CLI verification via browser-debugger-cli (bdg)
**Purpose**: Remind about browser-based testing for visual changes
**References**: `cli-chrome-devtools` skill

### 3.4 Context & Performance Hooks

#### workflows-save-context-trigger.sh (UserPromptSubmit)
**Triggers**: Keywords (`save context`), Every 20 messages
**V9 features**: Session-aware markers, anchor-based retrieval, sub-folder routing
**Execution**: Parallel (non-blocking) when supported
**Output**: Saves to `specs/###-folder/memory/` (or sub-folder when versioning active)

#### prune-context.sh (PreCompact) - v2.0.0 DCP-Style Output
**Purpose**: Prune conversation context before compaction using intelligent deduplication
**Output Format**: Inspired by OpenCode Dynamic Context Pruning (DCP) plugin
**Features**:
  - `[DCP]` prefix for all output messages (consistent with OpenCode plugin)
  - Per-tool breakdown table showing duplicates removed per tool type
  - Actual token estimates (e.g., `~6.3k tokens`) not just percentages
  - Handles both Claude Code format (`entry.content`) and Anthropic API format (`entry.message.content`)
  - Timeout handling (exit codes 124/137) with clear error messages
**Config**: `.claude/configs/context-pruning.json`
**Deduplication Targets**: Read, Grep, Glob tools (exact parameter matching)
**Protected Tools**: Task, TodoWrite, TodoRead, AskUserQuestion, Skill, SlashCommand, EnterPlanMode, ExitPlanMode
**Performance**: <5s
**Example Output**:
```
[DCP] Context pruning triggered (auto-compact)
[DCP] Scanning: abc123-session.jsonl
[DCP] ─────────────────────────────────────────
[DCP] Deduplication: found 15 duplicates
[DCP] ─────────────────────────────────────────
[DCP] Duplicates by tool:
[DCP] ┌────────────┬───────────┬─────────────┐
[DCP] │ Tool       │ Removed   │ Tokens      │
[DCP] ├────────────┼───────────┼─────────────┤
[DCP] │ Read       │        8  │        4.2k │
[DCP] │ Grep       │        5  │        1.8k │
[DCP] │ Glob       │        2  │         350 │
[DCP] └────────────┴───────────┴─────────────┘
[DCP] Token savings: ~6.3k tokens (42% reduction)
[DCP] ─────────────────────────────────────────
[DCP] Compaction ready (context optimized)
```

#### warn-duplicate-reads.sh (PreToolUse) - v2.0.0 Intelligence System
**Transformation**: Low-value warnings → High-value actionable intelligence
**Smart Deduplication**: Detects legitimate patterns (70% false positive reduction)
  - Verification reads after Edit/Write operations
  - Stale context refresh (>2min TTL)
  - Different query parameters
**Token Quantification**: Conservative estimates with session totals
  - Read: 1000 tokens | Grep: 400 tokens | Glob: 150 tokens
  - Tracks cumulative waste per session
**Machine-Readable Output**: JSON signals for AI optimization (not text warnings)
  - `{"duplicate_detected": true, "is_legitimate": false, "estimated_waste_this_call": 1000, "session_total_waste": 2400}`
  - Actionable suggestions: REUSE_PREVIOUS_OUTPUT, USE_AGENT_VARIABLE
**Performance**: 25-55ms (40% faster than v1.0.0, was 30-130ms)
**ROI**: 2-3x token savings potential

### 3.5 Agent & MCP Hooks

#### suggest-semantic-search.sh (UserPromptSubmit) - v2.0.0 Contextual Patterns
**Triggers**: 6 contextual patterns with query templates (was 25+ generic patterns)
  - Exploratory questions: "where is X implemented" → "Find code that handles X"
  - Architecture understanding: "how does X work" → "How does X work?"
  - Code navigation: "find all X usage" → "Find all X usage patterns"
**Deduplication**: Prevents overlap with validate-skill-activation.sh (skips implementation prompts)
**Output**: JSON systemMessage for terminal visibility + Claude context for AI guidance
**References**: `mcp_semantic_search.md`, `mcp_code_mode.md`

#### suggest-mcp-tools.sh (UserPromptSubmit) - v2.0.0 Merged
**Purpose**: Unified MCP tools + Code Mode suggestions (merged from suggest-code-mode.sh + detect-mcp-workflow.sh)
**Detects**: Webflow, Figma, Notion, GitHub API, ClickUp, multi-tool workflow patterns
**Features**:
  - Domain detection via lib/domain-detection.sh library
  - Complexity scoring for parallel dispatch decisions
  - Code Mode efficiency reminders (68% fewer tokens)
**Performance**: ~20ms

#### announce-task-dispatch.sh (PreToolUse) - v2.0.0 Rich Metadata
**Purpose**: Announce agent dispatch with rich lifecycle tracking before Task tool execution
**Features**: Double-line box formatting (╔══╗) for visual distinction
  - Complexity scores and domains from orchestrate-skill-validation.sh
  - Batch context tracking with position indicators (Agent 2/4)
  - Enriched agent_tracking.json with metadata for correlation
**Visibility**: Complete visibility into why agents dispatched, what they're assigned, batch context
**Integration**: orchestrate-skill-validation.sh state, agent-tracking.sh library

#### summarize-task-completion.sh (PostToolUse) - Fixed Duration Calculation
**Purpose**: Summarize Task tool results with accurate metrics
**Fixed**: Duration calculation (was showing "?s", now shows actual time like "12.3s")
**Features**: 5 failure mode diagnostics for troubleshooting
  - JSON validation via agent-tracking.sh library
  - Auto-recovery from corruption
**Output**: Success/failure status, accurate execution time, files modified count

#### enforce-semantic-search.sh (PreToolUse) - v1.0.0
**Purpose**: Suggest semantic search before Glob/Grep operations for exploratory queries
**Triggers**: Glob and Grep tool calls matching exploratory patterns
**Output**: JSON systemMessage for terminal visibility
**Features**:
  - Pattern matching for code discovery queries
  - Integration with mcp-semantic-search skill
**Performance**: <30ms

#### enforce-git-workspace-choice.sh (UserPromptSubmit) - v1.0.0
**Purpose**: Mandatory question for git workspace strategy before feature work
**Triggers**: "new feature", "create branch", "worktree", "fix bug", "hotfix"
**Options**:
  - A) Create a new branch (standard workflow)
  - B) Create a git worktree (isolated workspace)
  - C) Work on current branch (quick fixes)
**Features**:
  - 1-hour session preference caching
  - Override phrases: "use branch", "use worktree", "current branch"
  - Integration with lib/signal-output.sh for mandatory questions
**Performance**: <100ms

### 3.6 Verification & Compliance Hooks

#### enforce-verification.sh (UserPromptSubmit) - v3.0.0 False Positive Elimination
**Blocks**: Implementation without verification plan (with 0% false positives)
**Architecture**: Exclusion-first pattern matching (checks exclusions BEFORE completion detection)
**8 Exclusion Patterns**: Imperative verbs, modal verbs, infinitive phrases, temporal markers, conditionals, desire statements, option phrasing, negations
**Performance**: 100% reduction in false positives (was ~40%), 100% true positive rate maintained
**Testing**: 52 comprehensive tests (31 synthetic + 21 real-world), 100% pass rate
**Reminds**: Browser testing, edge cases, CLI verification
**Exit**: Blocking (1)

#### validate-spec-final.sh (PreToolUse)
**Purpose**: Final spec folder validation before file modification
**Checks**: Active spec marker exists, file change aligns with spec topic

#### verify-spec-compliance.sh (PostToolUse)
**Purpose**: Verify modifications match active spec folder
**Output**: Warning if mismatch detected

#### detect-scope-growth.sh (PostToolUse) - v2.0.0 NOW FUNCTIONAL
**Status**: Previously never executed (0 log entries all-time), now 100% functional
**Self-Initializing**: Auto-detects spec folder from file path, establishes baseline on first .md edit
**Features**:
  - 50% growth threshold triggers advisory warning
  - 10-minute spam prevention cooldown
  - Integration with file-scope-tracking.sh library
  - Comprehensive logging for debugging
**Tracks**: File modifications across spec folder
**Detects**: Scope creep (warns at 150% of baseline file count)
**Integration**: Updated enforce-spec-folder.sh to initialize scope_definition state
**Performance**: <50ms

### 3.7 SubagentStop Hooks (Quality Gate)

#### validate-subagent-output.sh (SubagentStop) - v1.0.0

**Purpose**: Validate sub-agent (Task tool) output quality and BLOCK bad output before acceptance

**Unique Capability**: SubagentStop is the ONLY hook type that can block a sub-agent's output after execution. Other hooks can only warn.

**Validation Checks** (5 categories):
1. **Failure Detection**: Errors, exceptions, crashes, timeouts
2. **Completeness Check**: TODOs, placeholders, unfinished work markers
3. **Quality Assessment**: Output length, depth, relevance to task
4. **Security Scan**: Basic vulnerability patterns (eval, innerHTML, secrets)
5. **Task Alignment**: Does output address the original task request?

**Scoring System** (0-100):
| Score Range | Action | Behavior |
|-------------|--------|----------|
| 0-39 | **BLOCK** | Returns `{"decision": "block", "reason": "..."}` |
| 40-69 | Warn | Allows with `{"systemMessage": "⚠️ ..."}` |
| 70-89 | Allow | Silent pass |
| 90-100 | Excellent | Success message `{"systemMessage": "✅ ..."}` |

**Retry Logic**:
- Max 2 retries per agent before giving up
- Retry count tracked in `/tmp/claude_hooks_state/subagent_retries.json`
- Retries reset after 1 hour (cleanup on stale state)

**Blocking Patterns** (will BLOCK output):
- Critical failures: `fatal error`, `stack trace`, `segmentation fault`
- Multiple errors: >5 error patterns detected
- Incomplete work: >3 TODO/FIXME markers
- Empty/very short output: <50 characters for complex tasks
- Quality score below threshold: <40/100

**Warning Patterns** (allow with warning):
- Some errors: 1-5 error patterns
- Few incomplete markers: 1-3 TODOs
- Security concerns: `eval()`, `innerHTML`, exposed secrets
- Poor task alignment: Output doesn't mention task keywords

**Agent-Type Specific Rules**:
- **Explore agents**: Must report findings (files, paths, components)
- **Plan agents**: Must produce structured plan (steps, phases)
- **Code reviewers**: Must provide feedback (suggestions, issues)
- **General-purpose**: Minimal type-specific requirements

**Configuration**: `.claude/configs/subagent-validation.json`
- Customizable patterns and thresholds
- Per-agent-type validation rules
- Retry guidance messages

**Library**: `.claude/hooks/lib/subagent-validation.sh`
- Core validation functions
- Pattern matching utilities
- Retry state management
- Transcript output extraction

**Logs**: `.claude/hooks/logs/subagent-validation.log`
- Validation results with scores
- Block/allow decisions
- Retry counts and reasons

**Performance**: <50ms (reads transcript, applies validation, returns decision)

**Example Output (Block)**:
```json
{
  "decision": "block",
  "reason": "Quality score: 25/100 (Poor) - Too many errors in output (8) | Issues: Multiple errors detected (8 occurrences)",
  "systemMessage": "❌ Sub-agent output blocked: Quality score: 25/100 (Poor) - Too many errors in output (8)"
}
```

**Example Output (Warn)**:
```json
{
  "systemMessage": "⚠️ Sub-agent output quality: 55/100 (Marginal) - Contains TODO/FIXME markers (2)"
}
```

---

### 3.8 Session Lifecycle Hooks

#### initialize-session.sh (PreSessionStart)
**Purpose**: Session initialization
**Creates**: Temporary files, session markers
**Performance**: <50ms

#### cleanup-session.sh (PostSessionEnd)
**Purpose**: Session cleanup
**Removes**: Temporary files, stale markers
**Performance**: <100ms

---

## 5. 🔑 EXIT CODE CONVENTION

**Standardized across all hooks** (updated Nov 2025):

```
0 = Allow (hook passed, continue execution)
1 = Block (hook failed, stop execution with warning)
2 = Error (reserved for blocking with stderr fed to Claude)
3 = Warning (advisory, non-blocking - from lib/exit-codes.sh)
4 = Skip (skip remaining hooks in chain - from lib/exit-codes.sh)
```

### Blocking Hooks (use exit 1)
- `check-pending-questions.sh` - Blocks ALL tools when mandatory question pending (except AskUserQuestion)
- `enforce-markdown-pre.sh` - Blocks invalid markdown filenames (ALL CAPS, hyphens, camelCase)
- `enforce-markdown-strict.sh` - Blocks on critical markdown violations
- `enforce-verification.sh` - Blocks completion claims without evidence
- `validate-bash.sh` - Blocks wasteful commands (context bloat prevention)
- `validate-spec-final.sh` - Blocks on spec folder validation failures (SpecKit quality gate)

### Advisory Hooks (exit 0 only)
- `workflows-save-context-trigger.sh` - Auto-save context (non-blocking)
- `validate-skill-activation.sh` - Skill suggestions (non-blocking)
- `orchestrate-skill-validation.sh` - Skill orchestration (non-blocking)
- `suggest-semantic-search.sh` - Search reminders (non-blocking)
- `suggest-mcp-tools.sh` - MCP tools + Code Mode suggestions (merged v2.0.0)
- `enforce-spec-folder.sh` - Spec folder prompts (non-blocking)
- `enforce-git-workspace-choice.sh` - Git workspace selection (non-blocking)
- `validate-mcp-calls.sh` - MCP call pattern education (non-blocking)
- `enforce-markdown-naming.sh` - Auto-fix filenames (merged v2.0.0)
- `enforce-semantic-search.sh` - Semantic search suggestions for Glob/Grep (non-blocking)
- `validate-post-response.sh` - Quality reminders (non-blocking)
- `skill-scaffold-trigger.sh` - Directory scaffolding (non-blocking)
- `remind-cdn-versioning.sh` - CDN update reminder (non-blocking)
- `warn-duplicate-reads.sh` - Real-time duplicate detection advisory (non-blocking)
- `save-context-before-compact.sh` - PreCompact context backup (always allows, cannot block)
- `prune-context.sh` - Context pruning at compaction (always allows, cannot block)

### Exit Code Usage

**Exit 0**: Hook passed OR advisory-only hook
**Exit 1**: Blocking error - stops execution with user-visible message
**Exit 2**: Reserved for future use (critical system failures)

---

## 6. ⚡ PERFORMANCE EXPECTATIONS

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
- `enforce-markdown-naming.sh` - File renaming, git operations: ~60-120ms
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

## 7. 🔗 HOW HOOKS CONNECT

### Connection Flow

```text
User Prompt
    ↓
┌─────────────────────────────────────────────────────────────┐
│ UserPromptSubmit Hooks (10)                                 │
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
│ 4. suggest-mcp-tools        → mcp_code_mode.md              │
│                             → Code Mode benefits reminder   │
│                             → MCP tool efficiency guidance  │
│                             → Multi-tool workflow detection │
│                             → (merged: suggest-code-mode +  │
│                             │  detect-mcp-workflow)         │
│                                                             │
│ 5. enforce-spec-folder     → specs/** + skill-rules.json    │
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
│                                                             │
│ 9. suggest-prompt-improvement  → Prompt quality analysis    │
│                                 → DEPTH framework hints     │
│                                                             │
│ 10. orchestrate-skill-validation → Complexity scoring       │
│                                 → Parallel dispatch logic    │
├─────────────────────────────────────────────────────────────┤
│ PreToolUse Hooks (9)                                        │
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
│                                                             │
│ 5. validate-dispatch-requirement → Parallel dispatch gate   │
│                             → Requires user dispatch choice │
│                                                             │
│ 6. announce-task-dispatch   → Agent lifecycle visibility    │
│                             → Rich metadata tracking        │
│                                                             │
│ 7. warn-duplicate-reads     → Duplicate detection           │
│                             → Token waste quantification    │
│                                                             │
│ 8. enforce-semantic-search  → Semantic search suggestions   │
│                             → For Glob/Grep operations      │
│                                                             │
│ 9. enforce-markdown-pre     → Filename validation           │
│                             → BLOCKS invalid markdown names │
└─────────────────────────────────────────────────────────────┘
    ↓
Tool Executes (Bash, Write, Edit, etc.)
    ↓
┌─────────────────────────────────────────────────────────────┐
│ PostToolUse Hooks (9)                                       │
├─────────────────────────────────────────────────────────────┤
│ 1. enforce-markdown-naming  → Auto-renames .md files        │
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
│                                                             │
│ 7. track-file-modifications → File change tracking          │
│                             → Scope creep detection input   │
│                                                             │
│ 8. verify-spec-compliance   → Spec folder compliance        │
│                             → Warns on mismatch             │
│                                                             │
│ 9. detect-scope-growth      → Scope growth detection        │
│                             → Advisory warnings             │
└─────────────────────────────────────────────────────────────┘
    ↓
┌─────────────────────────────────────────────────────────────┐
│ PreCompact Hooks (2)                                        │
├─────────────────────────────────────────────────────────────┤
│ 1. save-context-before-compact → Backs up transcript        │
│                                → lib/transform-transcript.js│
│                                → workflows-save-context skill│
│                                → specs/###/memory/ OR        │
│                                   ###-name/###-sub/memory/  │
│                                → Always exits 0 (non-block) │
│                                                             │
│ 2. prune-context            → Context pruning engine        │
│                             → DCP-style deduplication       │
│                             → Token savings calculation     │
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
- `enforce-markdown-naming.sh` → `quality-checks.log`
- `enforce-markdown-strict.sh` → `quality-checks.log`
- `validate-post-response.sh` → `quality-checks.log`
- `enforce-spec-folder.sh` → `spec-enforcement.log`
- `skill-scaffold-trigger.sh` → No logs (outputs directly to user for visibility)
- All 8 hooks → `performance.log` (execution timing)

---

## 8. 📚 SHARED LIBRARIES

### Library Reference Table

| Library | Purpose | Key Functions | Used By | Performance |
|---------|---------|---------------|---------|-------------|
| **output-helpers.sh** | Standardized hook output formatting | `log_info()`, `log_warn()`, `log_error()`, `log_success()` | All hooks | N/A (output only) |
| **exit-codes.sh** | Exit code constants | `EXIT_SUCCESS=0`, `EXIT_BLOCK=1`, `EXIT_WARNING=3`, `EXIT_SKIP=4` | All hooks | N/A (constants) |
| **transform-transcript.js** | JSONL → JSON conversion | `transformTranscript()`, content filtering | workflows-save-context-trigger.sh | ~500ms |
| **shared-state.sh** | Cross-hook state management (BSD-compatible v1.0.0) | `write_hook_state()`, `read_hook_state()`, `clear_hook_state()`, `get_state_dir()` | Multiple hooks | <5ms |
| **agent-tracking.sh** | Agent lifecycle tracking | `track_dispatch()`, `track_completion()` | orchestrate-skill-validation.sh, announce-task-dispatch.sh | ~10ms |
| **signal-output.sh** | JSON signal generation (v2.0.0 - systemMessage) | `emit_signal()`, `emit_mandatory_question()` | enforce-spec-folder.sh, check-pending-questions.sh, enforce-git-workspace-choice.sh | <5ms |
| **spec-context.sh** | Spec folder state management | `get_spec_marker_path()`, `has_substantial_content()`, `create_spec_marker()` | enforce-spec-folder.sh, workflows-save-context | ~10ms |
| **template-validation.sh** | Template placeholder detection | `validate_template()`, `check_placeholders()` | validate-post-response.sh | ~20ms |
| **anchor-generator.js** | HTML anchor generation for memory files | `generateAnchorId()`, `categorizeSection()` | workflows-save-context (generate-context.js) | <50ms |
| **load-related-context.sh** | Anchor-based context retrieval | `list`, `summary`, `search`, `extract`, `recent`, `smart`, `search_all` | enforce-spec-folder.sh (Option D) | <200ms core, <500ms smart |
| **relevance-scorer.sh** | 4-dimension relevance scoring | `calculate_relevance()` (category, keywords, recency, proximity) | load-related-context.sh (smart/search_all) | ~10ms per anchor |
| **file-scope-tracking.sh** | File modification tracking | `track_file()`, `get_modified_files()` | detect-scope-growth.sh, track-file-modifications.sh | <10ms |
| **context-pruner.js** | Context pruning engine (v2.0.0 - DCP-style) | `extractToolCalls()`, `deduplicateToolCalls()`, `displaySummary()` | prune-context.sh | <5s |
| **platform-utils.sh** | Cross-platform utilities (v1.0.0) | `get_file_size()`, `get_file_mtime()`, `sanitize_session_id()`, `relpath()` | Multiple hooks | <5ms |
| **subagent-validation.sh** | Sub-agent output validation (v1.0.0) | `validate_subagent_output()`, `quick_validate()`, `extract_subagent_output_from_transcript()` | validate-subagent-output.sh | <50ms |
| **tool-input-parser.sh** | JSON input parsing (v1.0.0) | `read_tool_input()`, `parse_file_path()`, `is_file_editing_tool()` | PreToolUse/PostToolUse hooks | <5ms |
| **perf-timing.sh** | Performance timing (v1.0.0) | `start_timing()`, `end_timing()`, `log_performance()` | All hooks | <1ms |
| **hook-init.sh** | Common initialization boilerplate (v1.0.0) | Sources common libraries, sets up logging | All hooks | <5ms |
| **domain-detection.sh** | Complexity domain detection (v1.0.0) | `detect_domains()`, `count_domains()`, `get_domain_keywords()` | suggest-mcp-tools.sh, orchestrate-skill-validation.sh | <10ms |
| **markdown-naming.sh** | Markdown naming conventions (v1.0.0) | `to_snake_case()`, `is_naming_violation()`, `atomic_rename()` | enforce-markdown-naming.sh | <10ms |
| **spec-memory.sh** | Spec memory file management (v1.0.0) | `get_memory_files()`, `get_latest_memory()`, `create_memory_file()` | workflows-save-context, enforce-spec-folder | <10ms |
| **migrate-spec-folder.sh** | Spec folder versioning (v1.0.0) | `migrate_to_subfolder()`, `archive_root_content()` | enforce-spec-folder.sh | <100ms |
| **mcp-auth-cache.sh** | MCP auth token caching (v1.0.0) | `mcp_auth_cached()`, `mcp_auth_store()`, `mcp_auth_clear()`, `mcp_auth_get()` | MCP tool integrations | <5ms |
| **agent-state-handoff.sh** | Parallel agent state management (v1.0.0) | `agent_state_init()`, `agent_state_update()`, `agent_state_wait()`, `agent_state_read()` | Parallel dispatch orchestration | <10ms |

### 8.1 Core Libraries

#### output-helpers.sh
**Functions**: `log_info`, `log_warn`, `log_error`, `log_success`, `log_block`
**Format**: Emoji prefix + message + timing
**Usage**: Source in all hooks for consistent output

#### exit-codes.sh
**Constants**: `EXIT_SUCCESS=0`, `EXIT_BLOCK=1`, `EXIT_CONTINUE=0`, `EXIT_WARNING=3`, `EXIT_SKIP=4`
**Purpose**: Standardized exit codes across all hooks
**New in v2.0.0**: `EXIT_WARNING` for advisory messages, `EXIT_SKIP` for skipping remaining hooks

### 8.2 Context & State Management

#### spec-context.sh
**V9 Features**: Session-aware markers (`.spec-active.{SESSION_ID}`), sub-folder routing
**Functions**: 
- `get_spec_marker_path(session_id)` - Get session-specific marker path
- `has_substantial_content(spec_folder)` - Check for mid-conversation state
- `create_spec_marker(spec_folder)` - Create session marker

#### shared-state.sh (v1.0.0 - BSD-Compatible Locking)
**Storage**: `/tmp/claude_hooks_state/`
**Functions**: `write_hook_state(key, value)`, `read_hook_state(key, max_age)`, `clear_hook_state(key)`, `has_hook_state(key)`
**Locking**: BSD-compatible `mkdir`-based atomic locking (works on macOS and Linux)
**Features**:
- Atomic write operations with 1-second timeout
- Automatic lock cleanup via trap handlers (EXIT, INT, TERM)
- Lock directories instead of files (easier to identify)
- Staleness checking with configurable max_age
**Performance**: <5ms per operation, <1000ms lock acquisition timeout
**Purpose**: Cross-hook communication with guaranteed atomicity
**Migration**: Replaced Linux-specific `flock` with universal `mkdir` locking (2025-11-29)
**Documentation**: See `specs/001-skills-and-hooks/046-context-pruning-hook/001-bsd-locking-fix/` for complete technical details (`bsd_locking_migration.md` and `bsd_fix_summary.md`)

#### file-scope-tracking.sh
**Tracks**: File modifications across tool uses
**Storage**: In-memory arrays
**Purpose**: Detect scope creep, duplicate operations

### 8.3 Memory & Retrieval

#### anchor-generator.js (V9.0)
**8-Category Taxonomy**: decision (1.0), implementation (0.9), guide (0.85), architecture (0.8), discovery (0.7), integration (0.65), files (0.5), summary (0.4)
**Output**: HTML anchors (`<!-- anchor: category-keywords-spec -->`)
**Performance**: <50ms per file, 5-15 anchors generated

#### load-related-context.sh (V9.0)
**7 Commands**: list, summary, search, extract, recent, smart, search_all
**Token Reduction**: 93-97% (400-800 tokens vs 12,000 for full file)
**Usage**: `bash lib/load-related-context.sh <command> [args]`

#### relevance-scorer.sh (V9.0)
**Algorithm**: Weighted scoring - category (35%) + keywords (30%) + recency (20%) + proximity (15%)
**Output**: Relevance score 0-100
**Usage**: Called by load-related-context.sh for smart/search_all commands

### 8.4 Transformation & Processing

#### transform-transcript.js
**Input**: JSONL transcript from Claude Code
**Output**: JSON with conversation, decisions, diagrams
**Filtering**: Content filtering via `lib/content-filter.js`
**Performance**: ~500ms for typical session

#### context-pruner.js (v2.0.0 - DCP-Style)
**Purpose**: Intelligent context pruning before compaction using deduplication
**Output**: DCP-style format with `[DCP]` prefix, token estimates, per-tool breakdown tables
**Config**: `.claude/configs/context-pruning.json`
**Key Functions**:
  - `getContentArray()` - Handles both Claude Code (`entry.content`) and API (`entry.message.content`) formats
  - `extractToolCalls()` - Extracts tool calls with results for token estimation
  - `deduplicateToolCalls()` - Safe deduplication with exact parameter matching
  - `displaySummary()` - DCP-style formatted output with tables
  - `formatTokenCount()` - Human-readable token counts (e.g., `4.2k`)
**Protected Tools**: Task, TodoWrite, TodoRead, AskUserQuestion, Skill, SlashCommand, EnterPlanMode, ExitPlanMode
**Deduplication Targets**: Read, Grep, Glob (configurable via `allowedTools`)
**Performance**: <5s

#### template-validation.sh
**Detects**: `[PLACEHOLDER]`, `[NEEDS CLARIFICATION: ...]`, template markers
**Config**: `.claude/configs/template-validation.json`
**Purpose**: Ensure complete template population

### 8.5 Agent & Workflow

#### agent-tracking.sh - JSON Validation & Corruption Recovery
**Tracks**: Agent dispatch, completion, duration
**Enhanced**: JSON validation on write, auto-recovery from corruption
**Fixed**: Duration calculation bug (was showing "?s" in summarize-task-completion.sh)
**Features**:
  - Validates JSON before writing to prevent corruption
  - Auto-detects and recovers from corrupted agent_tracking.json
  - 5 failure mode diagnostics for troubleshooting
**Storage**: Shared state (`/tmp/claude_hooks_state/agent_tracking.json`)
**Output**: Agent lifecycle visibility in hooks
**Used by**: announce-task-dispatch.sh, summarize-task-completion.sh

#### signal-output.sh (v2.0.0 - systemMessage)
**Generates**: JSON signals for mandatory questions, blocking conditions
**Format**: `{"signal": "MANDATORY_QUESTION", "blocking": true, "question": {...}}`
**New in v2.0.0**: JSON systemMessage output for always-visible terminal notifications
**Purpose**: Standardized AI communication protocol with user visibility
**jq Dependency**: Now includes jq availability check with warning

### 8.6 New Utility Libraries (v2.0.0)

#### platform-utils.sh
**Purpose**: Cross-platform utilities for macOS/Linux compatibility
**Functions**:
  - `get_file_size(file)` - Get file size in bytes
  - `get_file_mtime(file)` - Get file modification time
  - `parse_timestamp(ts)` - Parse ISO timestamp
  - `generate_unique_id()` - Generate unique identifier
  - `sanitize_session_id(id)` - Clean session IDs for safe filenames
  - `relpath(path, base)` - Get relative path
**Compatibility**: BSD (macOS) and GNU (Linux) compatible

#### tool-input-parser.sh
**Purpose**: JSON input parsing for PreToolUse/PostToolUse hooks
**Functions**:
  - `read_tool_input()` - Read and cache stdin JSON
  - `parse_file_path()` - Extract file_path from tool input
  - `is_file_editing_tool()` - Check if tool modifies files
  - `is_file_reading_tool()` - Check if tool reads files
  - `get_prompt()` - Get user prompt from input
  - `get_session_id()` - Get session ID from input

#### perf-timing.sh
**Purpose**: Performance timing utilities
**Functions**:
  - `start_timing()` - Record start time
  - `end_timing()` - Calculate elapsed time
  - `log_performance(hook, duration)` - Log to performance.log
  - `auto_start_timing()` - Automatic timing on source
**Usage**: Source at start of hook, calls auto_start_timing()

#### hook-init.sh
**Purpose**: Common initialization boilerplate
**Sources**: output-helpers.sh, exit-codes.sh, perf-timing.sh
**Sets Up**: LOG_DIR, LOG_FILE, HOOKS_DIR variables
**Usage**: `source "$HOOKS_DIR/lib/hook-init.sh"` at start of hook

#### domain-detection.sh
**Purpose**: Complexity domain detection for parallel dispatch
**Functions**:
  - `detect_domains(prompt)` - Detect domains in prompt
  - `count_domains(domains)` - Count unique domains
  - `get_domain_keywords(domain)` - Get keywords for domain
**Domains**: code, docs, testing, config, research, design

#### markdown-naming.sh
**Purpose**: Markdown filename conventions
**Functions**:
  - `to_snake_case(name)` - Convert to snake_case
  - `is_naming_violation(name)` - Check for violations
  - `atomic_rename(src, dst)` - Case-safe rename
**Exceptions**: README.md, SKILL.md, AGENTS.md, CLAUDE.md, GEMINI.md

### 8.7 Usage Pattern

```bash
# Source libraries in hooks
source "$HOOKS_DIR/lib/output-helpers.sh"
source "$HOOKS_DIR/lib/exit-codes.sh"
source "$HOOKS_DIR/lib/spec-context.sh"

# Use functions
log_info "Processing hook..."
SPEC_MARKER=$(get_spec_marker_path "$SESSION_ID")
log_success "Complete" "150ms"
exit $EXIT_SUCCESS
```

---

## 9. 📊 LOGS DIRECTORY

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
- `inject-datetime.log` - (None - outputs only to performance.log)
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

## 10. ⚙️ CONFIGURATION

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

**Current Skills** (10 total):

**Skills with directories** (6):
- cli-gemini, cli-codex, create-documentation, workflows-save-context, workflows-code, workflows-git

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
    "spec": {
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

## 11. 🛠️ HELPER SCRIPTS

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

## 12. 💡 KEY BEHAVIORAL FEATURES

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

## 13. 📖 ADDITIONAL RESOURCES

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
- `create-documentation` - Markdown optimization, validation, and ASCII flowchart creation
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
- `suggest-mcp-tools.sh` → References mcp_code_mode.md
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

---

## 14. 🧪 TESTING

### Overview

The hooks system includes a comprehensive BATS (Bash Automated Testing System) test suite for validating hook behavior, library functions, and integration points.

**Test Statistics**: 54 tests across 2 test files
- `lib/shared-state.bats` - 20 tests
- `UserPromptSubmit/enforce-spec-folder.bats` - 34 tests

### Quick Start

```bash
# Run all tests
./tests/run-tests.sh

# Run specific test directory
./tests/run-tests.sh lib/

# Run with verbose output and timing
./tests/run-tests.sh -v --timing

# Run in parallel (faster)
./tests/run-tests.sh --jobs 4
```

### Test Structure

```
.claude/hooks/tests/
├── run-tests.sh           # Test runner with BATS detection
├── test_helper.bash       # Shared utilities, mocks, assertions
├── lib/
│   └── shared-state.bats  # Tests for lib/shared-state.sh
└── UserPromptSubmit/
    └── enforce-spec-folder.bats  # Intent detection tests
```

### Key Features

**Test Isolation**:
- Each test runs in an isolated temp directory
- Mock project structures created automatically
- State files cleaned up after each test

**Assertion Helpers** (from `test_helper.bash`):
| Function | Purpose |
|----------|---------|
| `assert_output_contains "str"` | Check output contains substring |
| `assert_output_not_contains "str"` | Check output does NOT contain |
| `assert_status 0` | Verify exit code |
| `assert_file_exists "/path"` | Verify file exists |
| `assert_equals "expected" "$actual"` | Compare values |
| `assert_matches "pattern" "$value"` | Regex pattern matching |

**Mock Functions**:
- `create_output_helpers_mock` - Mock output formatting
- `create_shared_state_mock` - Mock state management
- `create_signal_output_mock` - Mock question signals
- `create_spec_context_mock` - Mock spec folder utilities

**Utility Functions**:
- `create_spec_folder "001-feature"` - Create test spec folder
- `create_memory_file "001-feature" "filename.md"` - Create memory file
- `make_prompt_input "prompt text"` - Generate JSON hook input
- `run_hook_with_input "/path/hook.sh" '{"json":"input"}'` - Execute hook

### Dependencies

**Required**:
- BATS Core 1.0+ (`brew install bats-core` or `apt install bats`)
- jq (`brew install jq` or `apt install jq`)

**Optional** (for extended assertions):
- bats-support (`brew install bats-support`)
- bats-assert (`brew install bats-assert`)

### Writing New Tests

1. Create `.bats` file in appropriate directory
2. Load test helper: `load ../test_helper` (adjust path)
3. Write tests using BATS syntax:

```bash
#!/usr/bin/env bats

load ../test_helper

@test "description of what is being tested" {
  # Setup
  local input='{"prompt": "test input"}'

  # Execute
  run echo "$input" | bash "$HOOKS_DIR/lib/some-lib.sh"

  # Assert
  assert_status 0
  assert_output_contains "expected"
}
```

### CI Integration

For CI/CD pipelines, use TAP output format:

```bash
./tests/run-tests.sh --tap > test-results.tap
```

### Documentation

Full testing documentation: `.claude/hooks/tests/README.md`
