---
name: workflows-memory
description: Saves expanded conversation context with full dialogue, decision rationale, visual flowcharts, and file changes. Auto-triggers on keywords. Includes semantic vector search.
allowed-tools: [Read, Write, Bash]
version: 1.0.0
---

<!-- Keywords: memory, context-preservation, memory, session-documentation, auto-save, semantic-search, anchor-retrieval -->

# Memory - Expanded Conversation Documentation

> **Related Documentation:**
> - [README.md](./README.md) - Semantic Memory setup, MCP integration, API reference
> - [/memory/save](../../commands/memory/save.md) - Save context command
> - [/memory/search](../../commands/memory/search.md) - Search, manage index, view recent

> **TL;DR**: Use `/memory/save` to save context or let keyword triggers auto-save. Use `/memory/search` for semantic search and index management. Creates `specs/###-feature/memory/{timestamp}.md` with full conversation, decisions, and diagrams.

---

## ⚠️ Platform Differences

| Feature | Claude Code | Opencode |
|---------|-------------|----------|
| Auto-save on keywords | ✅ Automatic (hook) | ❌ Manual only |
| Context surfacing | ✅ Automatic prompt | ❌ Manual `/memory/search` |
| Session preferences | ✅ Detected by hook | ❌ Not available |
| Commands | ✅ Full support | ✅ Full support |
| MCP Tools | ✅ Full support | ✅ Full support |
| Scripts | ✅ Full support | ✅ Full support |

**Feature Parity: ~60%** — Core functionality (commands, MCP, scripts) works identically. Automation features require manual invocation in Opencode.

### Opencode Users: Manual Workflows

Since Opencode lacks hooks, these features require manual action:

1. **Saving Context**: Run `/memory/save` explicitly (no auto-triggers)
2. **Finding Context**: Run `/memory/search` at session start
3. **Session Preferences**: Not available - use commands directly

---

## 1. 🎯 WHEN TO USE

### Trigger Phrases

| Phrase          | Also Works             |
| --------------- | ---------------------- |
| "save context"  | "save conversation"    |
| "document this" | "preserve context"     |
| "save session"  | "save this discussion" |

### Auto-Save (Claude Code Only)

When trigger phrases are detected (e.g., "save context", "document this"), the system automatically saves. In Opencode, run `/memory/save` manually.

### When to Save

| Scenario           | Example                                  |
| ------------------ | ---------------------------------------- |
| Feature complete   | "Just finished the payment integration"  |
| Complex discussion | "We made 5 architecture decisions today" |
| Team sharing       | "Need to document this for the team"     |
| Session ending     | "Wrapping up for the day"                |

### When NOT to Use

- Simple typo fixes or trivial changes
- Context already documented in spec/plan files
- Conversations without spec folders (create one first)

### Context Recovery (CRITICAL)

**Before implementing ANY changes** in a spec folder with memory files, search for relevant context:

```bash
# Keyword search
grep -r "anchor:.*keyword" specs/###-current-spec/memory/*.md

# Semantic search (use MCP tool or command)
# /memory/search "your search query"
```

If found, load and acknowledge context before proceeding.

### Proactive Context Surfacing (Hook-Powered)

The `memory-surfacing.sh` hook automatically surfaces relevant context when:
1. User references a spec folder (e.g., "working on 006-semantic-memory")
2. User mentions spec folder content (e.g., "continue the memory surfacing work")
3. Trigger phrases are detected in the prompt

**What the Hook Does:**

When you reference a spec folder, the hook automatically displays:

```
---

**Found relevant context from your previous session(s):**

  **[1]** OAuth implementation decisions (2 days ago)
  **[2]** JWT token flow discussion (3 days ago)
  **[3]** Session management notes (5 days ago)

**Load context?** Reply with: [1] [2] [3] [all] [skip]

---
```

**User Response Options:**
- `[1]`, `[2]`, `[3]` - Load specific memory
- `[all]` - Load all listed memories
- `[skip]` - Continue without loading (instant, never blocks)

**Detection Patterns:**
- `specs/NNN-name` or `spec/NNN-name` in prompt
- "spec folder NNN", "spec NNN" phrases
- "working on", "continue", "resume" + spec folder reference
- Spec folder name keywords in prompt

**Performance:**
- Trigger phrase matching: <50ms
- Context surfacing: <1s
- Skip is always instant

**Hook Location:** `.claude/hooks/UserPromptSubmit/memory-surfacing.sh`

> **Opencode Users:** Hooks are not supported in Opencode. Instead, manually run `/memory/search` before starting work in a spec folder, or the AI should proactively offer to search for relevant context when you mention a spec folder.

---

## 2. 🧭 SMART ROUTING & REFERENCES

### Command Entry Points
```
/memory/save
    │
    └─► SAVE ACTION: Generate context documentation
        └─► Interactive folder detection if multiple specs active

/memory/search [args]
    │
    ├─► No args
    │   └─► UNIFIED BROWSER: Search prompt screen
    │
    ├─► "query text" (2+ words)
    │   └─► SEARCH RESULTS: Semantic search with related navigation
    │
    ├─► "recent"
    │   └─► VIEW ACTION: Show recent memory files
    │
    ├─► "rebuild" | "reindex"
    │   └─► INDEX ACTION: Rebuild vector embeddings
    │
    ├─► "verify" | "health"
    │   └─► VERIFY ACTION: Check index integrity
    │
    ├─► "retry"
    │   └─► RETRY ACTION: Retry failed embeddings
    │
    └─► "resume"
        └─► RESUME ACTION: Continue previous search session

/memory/cleanup
    │
    └─► CLEANUP ACTION: Interactive removal of old/unused memories
        ├─► Shows preview of candidates (NO FLAGS needed)
        ├─► [a]ll, [r]eview each, [n]one, [c]ancel
        └─► Smart defaults: 90 days, <3 accesses, <0.4 confidence

/memory/triggers
    │
    └─► TRIGGER ACTION: View/manage learned trigger phrases
        ├─► Shows what system learned from your searches
        ├─► Add/remove trigger phrases manually
        └─► Search by trigger, clear all (with confirm)

/memory/status
    │
    └─► STATUS ACTION: Quick health check
        ├─► Memory count, health indicator
        ├─► Last save, storage size, vector availability
        └─► Quick action shortcuts: [s]earch [c]leanup [r]ebuild
```

### Resource Router
```python
def route_save_context_resources(task):
    # ──────────────────────────────────────────────────────────────────
    # Main Context Generation
    # Purpose: 4 execution paths, anchor retrieval
    # Key Insight: Running save-context
    # ──────────────────────────────────────────────────────────────────
    if task.generating_context:
        return execute("scripts/generate-context.js")

    # ──────────────────────────────────────────────────────────────────
    # Flowchart Patterns (Linear)
    # Purpose: Sequential diagrams (<=4 phases)
    # Key Insight: Creating flowcharts
    # ──────────────────────────────────────────────────────────────────
    if task.needs_flowchart:
        if task.phase_count <= 4:
            return load("references/workflow_linear_pattern.md")
        # ──────────────────────────────────────────────────────────────────
        # Flowchart Patterns (Parallel)
        # Purpose: Concurrent diagrams (>4 phases)
        # Key Insight: Complex flows
        # ──────────────────────────────────────────────────────────────────
        else:
            return load("references/workflow_parallel_pattern.md")

    # ──────────────────────────────────────────────────────────────────
    # Semantic Memory
    # Purpose: Vector search, MCP tools
    # Key Insight: Semantic features
    # ──────────────────────────────────────────────────────────────────
    if task.semantic_search:
        return load("references/semantic_memory.md")

    # ──────────────────────────────────────────────────────────────────
    # Execution Methods
    # Purpose: 4 execution paths, anchor retrieval
    # Key Insight: Running save-context
    # ──────────────────────────────────────────────────────────────────
    if task.needs_execution_details:
        return load("references/execution_methods.md")

    # ──────────────────────────────────────────────────────────────────
    # Spec Folder Detection
    # Purpose: Folder routing, markers
    # Key Insight: Understanding routing
    # ──────────────────────────────────────────────────────────────────
    if task.folder_detection:
        return load("references/spec_folder_detection.md")

    # ──────────────────────────────────────────────────────────────────
    # Troubleshooting
    # Purpose: Issue resolution
    # Key Insight: Debugging problems
    # ──────────────────────────────────────────────────────────────────
    if task.has_issues:
        return load("references/troubleshooting.md")

    # ──────────────────────────────────────────────────────────────────
    # Output Format
    # Purpose: Timestamps, file naming
    # Key Insight: Understanding output
    # ──────────────────────────────────────────────────────────────────
    if task.needs_output_format:
        return load("references/output_format.md")

    # ──────────────────────────────────────────────────────────────────
    # Trigger Configuration
    # Purpose: Keywords, auto-save interval
    # Key Insight: Customizing triggers
    # ──────────────────────────────────────────────────────────────────
    if task.configuring:
        return load("references/trigger_config.md")

# ══════════════════════════════════════════════════════════════════════
# STATIC RESOURCES (always available, not conditionally loaded)
# ══════════════════════════════════════════════════════════════════════
# references/alignment_scoring.md → Topic matching weights (score questions)
# templates/context_template.md → Output format template
# config.jsonc → Runtime configuration
# filters.jsonc → Content filtering rules

# Output: specs/###-feature/memory/{timestamp}__{topic}.md
# Alignment threshold: 70%
```

---

## 3. 🛠️ HOW TO USE

### Quick Overview

| Action          | Method                             | When to Use                |
| --------------- | ---------------------------------- | -------------------------- |
| Auto-save       | Say trigger phrase or wait 20 msgs | Normal workflow            |
| Manual save     | `/memory/save` command             | Explicit control           |
| Search/manage   | `/memory/search` command           | Find context, manage index |
| Script          | `node generate-context.js`         | Testing/debugging          |
| Semantic search | `/memory/search "query"`           | Find prior context         |

### Execution Methods

| Method              | Hooks | AI  | Effort | Use Case            |
| ------------------- | ----- | --- | ------ | ------------------- |
| **Keyword trigger** | No    | No  | Zero   | Type "save context" |
| **Save command**    | No    | Yes | Low    | `/memory/save`      |
| **Search command**  | No    | Yes | Low    | `/memory/search`    |
| **Direct script**   | No    | No  | Medium | Testing             |
| **Helper script**   | No    | No  | Low    | Standalone          |

For detailed examples, see [execution_methods.md](./references/execution_methods.md).

### Basic Script Usage

Run with spec folder: `node scripts/generate-context.js /tmp/data.json "122-feature"` or use the helper script for auto-detection. See [execution_methods.md](./references/execution_methods.md) for detailed examples.

### Output Files

| File                        | Content                    |
| --------------------------- | -------------------------- |
| `{date}_{time}__{topic}.md` | Full session documentation |
| `metadata.json`             | Session statistics         |

**Naming**: `DD-MM-YY_HH-MM__topic.md` (e.g., `07-12-25_14-30__oauth.md`)

---

## 4. 🔗 ANCHOR-BASED RETRIEVAL

Memory files include searchable HTML anchors for targeted loading.

### Token Efficiency

| Approach          | Tokens  | Savings |
| ----------------- | ------- | ------- |
| Full file read    | ~12,000 | -       |
| Anchor extraction | ~800    | 93%     |

### Anchor Format

`<!-- anchor: category-keywords-spec# -->`

**Categories**: `implementation`, `decision`, `guide`, `architecture`, `files`, `discovery`, `integration`

### Quick Commands

```bash
# Find anchors by keyword
grep -l "anchor:.*decision.*auth" specs/*/memory/*.md

# Extract specific section
sed -n '/<!-- anchor: decision-jwt-049 -->/,/<!-- \/anchor: decision-jwt-049 -->/p' file.md
```

### Context Recovery Protocol

**MANDATORY before implementing in folders with memory**: Search anchors (`grep -r "anchor:.*keyword"`) or semantic (`/memory/search "query"`), load relevant sections, acknowledge context. See [execution_methods.md](./references/execution_methods.md) for full protocol.

---

## 5. 🧠 SEMANTIC SEARCH

Semantic vector search enables intelligent memory retrieval.

### Key Commands

| Command            | Purpose                        | Example                             |
| ------------------ | ------------------------------ | ----------------------------------- |
| `search <query>`   | Interactive semantic search    | `/memory/search "OAuth"`            |
| `multi <concepts>` | AND search across concepts     | `/memory/search "oauth" "security"` |
| `recent`           | View recent memory files       | `/memory/search recent`             |
| `rebuild`          | Rebuild vector index           | `/memory/search rebuild`            |
| `verify`           | Check index integrity          | `/memory/search verify`             |
| `retry`            | Retry last failed operation    | `/memory/search retry`              |
| `resume`           | Resume previous search session | `/memory/search resume`             |

### Interactive Actions

| Action          | Purpose                   | Example                          |
| --------------- | ------------------------- | -------------------------------- |
| `v#` / `l#`     | Preview / Load memory     | `v1`, `l1`                       |
| `f <filter>`    | Filter results            | `f folder:auth date:>2025-12-01` |
| `c` / `n` / `p` | Cluster / Next / Previous | `c`, `n`                         |
| `e <anchor>`    | Extract section           | `e decisions`                    |

Sessions persist 1 hour (resume with `/memory/search resume`).

### MCP Tools (for AI agents)

| Tool                    | Purpose                      | specFolder |
| ----------------------- | ---------------------------- | ---------- |
| `memory_search`         | Semantic vector search       | REQUIRED |
| `memory_load`           | Load memory by spec folder   | REQUIRED |
| `memory_match_triggers` | Fast trigger phrase matching | REQUIRED |
| `memory_inject`         | Get recent context for spec  | REQUIRED |

> **Important:** `specFolder` is a **REQUIRED** parameter for all MCP tools. MCP tools are stateless and cannot auto-detect the active spec folder. The AI must determine the spec folder from conversation context and pass it explicitly.

See [semantic_memory.md](./references/semantic_memory.md) for complete documentation.

---

## 6. 📋 IMPLEMENTATION

### JSON Data Structure

```javascript
{
  "SPEC_FOLDER": "049-feature-name",
  "recent_context": [{
    "request": "What user asked for",
    "completed": "What was accomplished",
    "learning": "Key insights",
    "duration": "45m",
    "date": "2025-12-07T14:30:00Z"
  }],
  "observations": [{
    "type": "feature|bugfix|decision|discovery|change",
    "title": "Brief title",
    "narrative": "Detailed description",
    "timestamp": "2025-12-07T14:30:00Z",
    "files": ["path/to/file.js"],
    "facts": ["Key point 1", "Key point 2"]
  }],
  "user_prompts": [{
    "prompt": "The actual user message",
    "timestamp": "2025-12-07T14:30:00Z"
  }]
}
```

### Spec Folder Detection

| Step | Action                                     |
| ---- | ------------------------------------------ |
| 1    | Check if in `/specs/###-*/` directory      |
| 2    | If not, find most recent spec folder       |
| 3    | Calculate alignment score (threshold: 70%) |
| 4    | If < 70%, prompt user to select folder     |
| 5    | If no spec folder exists, fail with error  |

See [spec_folder_detection.md](./references/spec_folder_detection.md) for sub-folder routing.

---

## 7. 📖 RULES

### ALWAYS

- Detect spec folder before creating documentation
- Use single `memory/` folder with timestamped files
- Include `metadata.json` with session stats
- Search anchors/semantic before implementing in folders with memory
- Generate vector embeddings for new memory files

### NEVER

- Fabricate decisions that weren't made
- Include sensitive data (passwords, API keys)
- Skip template validation before writing
- Proceed if spec folder detection fails
- Save context without spec folder

### ESCALATE IF

- Cannot create conversation summary
- Script execution fails with errors
- File write permissions denied
- Vector embedding generation fails repeatedly
- No spec folder exists

---

## 8. 🎓 SUCCESS CRITERIA

### Task Complete When

- [x] Auto-detects current spec folder
- [x] Creates 2 files: `{timestamp}.md` + `metadata.json`
- [x] Generates readable, well-formatted documentation
- [x] Includes accurate timestamps and metadata
- [x] Vector embeddings generated
- [x] Trigger phrases extracted

### Performance Targets

| Operation        | Target | Actual |
| ---------------- | ------ | ------ |
| Manual save      | 2-3s   | ~2.5s  |
| Auto-save        | 3-5s   | ~4s    |
| Vector search    | <500ms | ~450ms |
| Trigger matching | <50ms  | ~35ms  |

---

## 9. 🔗 INTEGRATION POINTS

### Data Flow

```
Conversation → AI Analysis → JSON → Script → Markdown + Embeddings
```

### Pairs With

| Skill                  | Integration               |
| ---------------------- | ------------------------- |
| `git-commit`           | Enhances with commit SHAs |
| `create-documentation` | Flowchart generation      |
| `workflows-spec-kit`   | Spec folder workflows     |

### Script Location

```
.claude/skills/workflows-memory/scripts/generate-context.js
```

### Semantic Components

| Component       | Location                         |
| --------------- | -------------------------------- |
| Embeddings      | `scripts/lib/embeddings.js`      |
| Vector Index    | `scripts/lib/vector-index.js`    |
| Trigger Matcher | `scripts/lib/trigger-matcher.js` |
| Memory Database | `.opencode/memory/memory-index.sqlite` |

---

## 10. 💡 EXAMPLES

### Example 1: Feature Implementation

**Context**: Completed OAuth implementation

**Output**:
```
specs/015-auth-system/memory/
├── 07-12-25_14-23__auth-system.md
└── metadata.json
```

**Contains**: Session summary, JWT decision rationale, auth flow diagram, 45-message dialogue, vector embeddings

### Example 2: Finding Prior Context

```bash
# Search for authentication decisions
/memory/search "how did we implement OAuth"

# Result:
# [92%] specs/049-auth/memory/28-11-25_14-30__oauth.md
#       → OAuth callback flow with JWT tokens
```

---

## 11. ⚠️ COMMON MISTAKES

> **Quick Fixes**
> 1. **Missing spec folder**: `mkdir -p specs/###-feature/`
> 2. **Wrong script path**: Use `.claude/skills/workflows-memory/scripts/generate-context.js`
> 3. **Arg 2 format**: Full folder name like `122-skill-standardization`, not just `122`
> 4. **Vector search empty**: Run `/memory/search rebuild` to generate embeddings

See [troubleshooting.md](./references/troubleshooting.md) for alignment scoring details and issue resolution.

---

## 12. 📊 QUICK REFERENCE

**Commands (5 total)**:

| Command            | Purpose             | Interaction                           |
| ------------------ | ------------------- | ------------------------------------- |
| `/memory/save`     | Save context        | Existing - works great                |
| `/memory/search`   | **UNIFIED BROWSER** | Search, Select, Related navigation    |
| `/memory/cleanup`  | **NEW**             | Interactive cleanup (no flags needed) |
| `/memory/triggers` | **NEW**             | View/manage learned phrases           |
| `/memory/status`   | **NEW**             | Health check + quick actions          |

**Enhanced Search** (`/memory/search`):
- No args: Interactive browser
- `"query"`: Direct semantic search
- Single-letter navigation: `[1-9]` select, `[a-c]` related, `[n]ew`, `[b]ack`, `[l]oad`, `[q]uit`

**Cleanup** (`/memory/cleanup`):
- NO FLAGS needed - uses smart defaults
- Preview before delete
- Review each OR bulk actions
- `[v]iew` content before deciding

**Trigger Management** (`/memory/triggers`):
- Shows what system learned
- Add/remove phrases
- Educational - builds trust

**System Status** (`/memory/status`):
- One-glance health overview
- Performance indicators
- Quick action shortcuts

**Auto Features (Invisible)**:
- Smart ranking (recency + usage boost)
- MMR diversity (varied results)
- Trigger learning (from search patterns)
- LRU caching (instant repeat searches)
- Related memory linking (on save)

**Performance Targets**:

| Operation         | Target |
| ----------------- | ------ |
| Save              | <3s    |
| Search            | <200ms |
| Cached search     | <10ms  |
| Trigger match     | <50ms  |
| Context surfacing | <1s    |

**Output**: `specs/###-feature/memory/{date}_{time}__{topic}.md`

**Anchor Format**: `<!-- anchor: category-keywords-spec# -->`

**Script**: `.claude/skills/workflows-memory/scripts/generate-context.js`

---

*This skill operates as a context preservation engine with semantic search, capturing dialogue, decisions, and visual flows while enabling intelligent retrieval across sessions.*