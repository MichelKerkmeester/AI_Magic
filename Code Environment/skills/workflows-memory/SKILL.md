---
name: workflows-memory
description: Context preservation with semantic memory v11.1: six-tier importance system (constitutional/critical/important/normal/temporary/deprecated), hybrid search (FTS5 + vector), 90-day half-life decay for recency boosting, checkpoint save/restore for context safety, constitutional memories (always surfaced), confidence-based promotion (90% threshold), session validation logging, context type filtering (research/implementation/decision/discovery/general). Auto-triggers on keywords or every 20 messages.
allowed-tools: [Read, Write, Bash, Glob, Grep]
version: 11.1.0
---

<!-- Keywords: memory, context-preservation, session-documentation, auto-save, semantic-search, anchor-retrieval, constitutional, importance-tier, decay, checkpoint -->

# 🧠 Workflows Memory - Context Preservation & Semantic Search

Saves expanded conversation context with full dialogue, decision rationale, visual flowcharts, and file changes. Uses semantic vector search for intelligent retrieval across sessions. Creates `specs/###-feature/memory/{timestamp}.md` with comprehensive session documentation.

---

## 1. 🎯 WHEN TO USE

### 📚 Navigation Guide

**This file (SKILL.md)**: Core workflow, MCP tools reference, rules, and quick commands

**Reference Files** (detailed documentation):
- [semantic_memory.md](./references/semantic_memory.md) – Complete semantic search documentation and MCP tool usage
- [execution_methods.md](./references/execution_methods.md) – 4 execution paths, script usage, anchor retrieval
- [spec_folder_detection.md](./references/spec_folder_detection.md) – Folder routing, markers, alignment scoring
- [output_format.md](./references/output_format.md) – Timestamps, file naming conventions
- [trigger_config.md](./references/trigger_config.md) – Keywords, auto-save interval configuration
- [troubleshooting.md](./references/troubleshooting.md) – Issue resolution guide
- [workflow_linear_pattern.md](./references/workflow_linear_pattern.md) – Sequential diagrams (≤4 phases)
- [workflow_parallel_pattern.md](./references/workflow_parallel_pattern.md) – Concurrent diagrams (>4 phases)

**Templates** (output resources):
- [context_template.md](./templates/context_template.md) – Output format template

**Scripts** (automation):
- [generate-context.js](./scripts/generate-context.js) – Main context generation script

### Primary Use Cases

**Use when:**
- Feature complete: "Just finished the payment integration"
- Complex discussion: "We made 5 architecture decisions today"
- Team sharing: "Need to document this for the team"
- Session ending: "Wrapping up for the day"
- Research complete: After investigation with findings to preserve
- Before context compaction: Save before Claude's context limit

**Trigger Phrases:**

| Phrase          | Also Works             |
| --------------- | ---------------------- |
| "save context"  | "save conversation"    |
| "document this" | "preserve context"     |
| "save session"  | "save this discussion" |

### Context Recovery (CRITICAL)

**Before implementing ANY changes** in a spec folder with memory files:

```bash
# Semantic search (use MCP tool directly - MANDATORY)
mcp__semantic_memory__memory_search({ query: "your search query", specFolder: "###-name" })

# Or use command
/memory/search "your search query"
```

**User Response Options:**
- `[1]`, `[2]`, `[3]` - Load specific memory
- `[all]` - Load all listed memories
- `[skip]` - Continue without loading (instant, never blocks)

### When NOT to Use

- Simple typo fixes or trivial changes
- Context already documented in spec/plan files
- Conversations without spec folders (create one first)

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
    │   └─► HOME SCREEN (Dashboard)
    │       ├─► Quick stats [via: memory_stats]
    │       ├─► Recent memories [via: memory_list]
    │       ├─► Suggested [via: memory_match_triggers]
    │       └─► Actions: [1-5] [a-b] [s]earch [f]ilter [c]leanup [q]uit
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
        └─► [a]ll, [r]eview each, [n]one, [c]ancel

/memory/triggers
    │
    └─► TRIGGER ACTION: View/manage learned trigger phrases

/memory/status
    │
    └─► STATUS ACTION: Quick health check + shortcuts [via: memory_stats]
```

### Resource Router

```python
def route_memory_resources(task):
    """
    Resource Router for workflows-memory skill
    Load references based on task context
    """

    # ──────────────────────────────────────────────────────────────────
    # Context Generation
    # Purpose: 4 execution paths, anchor retrieval, main save workflow
    # Key Insight: Primary entry point for saving conversation context
    # ──────────────────────────────────────────────────────────────────
    if task.generating_context:
        return execute("scripts/generate-context.js")

    # ──────────────────────────────────────────────────────────────────
    # Semantic Memory (MCP Tools)
    # Purpose: Vector search, hybrid search, importance tiers, decay
    # Key Insight: Native MCP calls - NEVER through Code Mode
    # ──────────────────────────────────────────────────────────────────
    if task.semantic_search or task.mcp_tools:
        return load("references/semantic_memory.md")

    # ──────────────────────────────────────────────────────────────────
    # Flowchart Patterns
    # Purpose: Visual diagrams for linear (≤4 phases) or parallel flows
    # Key Insight: Use linear for simple, parallel for complex workflows
    # ──────────────────────────────────────────────────────────────────
    if task.needs_flowchart:
        if task.phase_count <= 4:
            return load("references/workflow_linear_pattern.md")
        else:
            return load("references/workflow_parallel_pattern.md")

    # ──────────────────────────────────────────────────────────────────
    # Execution Methods
    # Purpose: Script invocation, command usage, anchor retrieval
    # Key Insight: Multiple paths - keyword trigger, command, script
    # ──────────────────────────────────────────────────────────────────
    if task.needs_execution_details:
        return load("references/execution_methods.md")

    # ──────────────────────────────────────────────────────────────────
    # Spec Folder Detection
    # Purpose: Folder routing, markers, alignment scoring
    # Key Insight: 70% alignment threshold for auto-detection
    # ──────────────────────────────────────────────────────────────────
    if task.folder_detection:
        return load("references/spec_folder_detection.md")

    # ──────────────────────────────────────────────────────────────────
    # Troubleshooting
    # Purpose: Issue resolution, common problems, debugging
    # Key Insight: Check alignment scoring and vector index health
    # ──────────────────────────────────────────────────────────────────
    if task.has_issues:
        return load("references/troubleshooting.md")

    # ──────────────────────────────────────────────────────────────────
    # Output Format
    # Purpose: Timestamps, file naming conventions, metadata
    # Key Insight: Format is DD-MM-YY_HH-MM__topic.md
    # ──────────────────────────────────────────────────────────────────
    if task.needs_output_format:
        return load("references/output_format.md")

    # ──────────────────────────────────────────────────────────────────
    # Trigger Configuration
    # Purpose: Keywords, auto-save interval, customization
    # Key Insight: Auto-save every 20 messages when enabled
    # ──────────────────────────────────────────────────────────────────
    if task.configuring:
        return load("references/trigger_config.md")

    # Default: SKILL.md covers basic cases

# ──────────────────────────────────────────────────────────────────────
# STATIC RESOURCES (always available, not conditionally loaded)
# ──────────────────────────────────────────────────────────────────────
# templates/context_template.md    → Output format template
# config.jsonc                     → Runtime configuration
# filters.jsonc                    → Content filtering rules
# references/alignment_scoring.md  → Topic matching weights

# Output: specs/###-feature/memory/{timestamp}__{topic}.md
# Alignment threshold: 70%
```

---

## 3. 🛠️ HOW IT WORKS

### Quick Overview

| Action          | Method                     | When to Use                |
| --------------- | -------------------------- | -------------------------- |
| Manual save     | `/memory/save`             | Explicit control           |
| Search/manage   | `/memory/search`           | Find context, manage index |
| MCP tool        | `memory_search()`          | AI agent integration       |
| Semantic search | `/memory/search "query"`   | Find prior context         |

### Save Workflow

```
USER triggers save (keyword or command)
        ↓
DETECT spec folder (70% alignment threshold)
        ↓
GENERATE context document
    ├─ Conversation summary
    ├─ Decisions made
    ├─ Files changed
    └─ Anchors for retrieval
        ↓
WRITE to specs/###/memory/{timestamp}__{topic}.md
        ↓
CREATE vector embeddings for semantic search
        ↓
EXTRACT trigger phrases for fast matching
```

### Output Files

| File                        | Content                    |
| --------------------------- | -------------------------- |
| `{date}_{time}__{topic}.md` | Full session documentation |
| `metadata.json`             | Session statistics         |

**Naming**: `DD-MM-YY_HH-MM__topic.md` (e.g., `07-12-25_14-30__oauth.md`)

See [execution_methods.md](./references/execution_methods.md) for detailed script usage.

### Anchor-Based Retrieval

Memory files include searchable HTML anchors for targeted loading (93% token savings vs full file).

**Anchor Format**: `<!-- anchor: category-keywords-spec# -->`

**Categories**: `implementation`, `decision`, `guide`, `architecture`, `files`, `discovery`, `integration`

```bash
# Find anchors by keyword
grep -l "anchor:.*decision.*auth" specs/*/memory/*.md
```

### MCP Tools (for AI Agents)

**CRITICAL**: Call MCP tools directly - NEVER through Code Mode.

| Tool                    | Purpose                           | specFolder |
| ----------------------- | --------------------------------- | ---------- |
| `memory_search`         | Semantic vector search            | REQUIRED   |
| `memory_load`           | Load memory by spec folder        | REQUIRED   |
| `memory_match_triggers` | Fast trigger phrase matching (<50ms) | REQUIRED   |
| `memory_list`           | Browse memories with pagination   | optional   |
| `memory_update`         | Update importance/metadata        | optional   |
| `memory_delete`         | Delete by ID or spec folder       | optional   |
| `memory_stats`          | System statistics                 | -          |
| `memory_validate`       | Record validation feedback        | REQUIRED   |

**Key `memory_search` Parameters:**

| Parameter      | Type    | Default | Description |
| -------------- | ------- | ------- | ----------- |
| `tier`         | string  | null    | Filter: `constitutional`, `critical`, `important`, `normal`, `temporary`, `deprecated` |
| `context_type` | string  | null    | Filter: `decision`, `implementation`, `research`, `debug` |
| `use_decay`    | boolean | true    | Apply 90-day half-life decay to scores |

### Six-Tier Importance System

| Tier           | Weight | Decay  | Use Case |
| -------------- | ------ | ------ | -------- |
| `constitutional` | 2.0x | None   | Always surfaced (max 500 tokens/session) |
| `critical`     | 1.5x   | None   | Architecture decisions, breaking changes |
| `important`    | 1.2x   | Slow   | Key implementations, major features |
| `normal`       | 1.0x   | Normal | Standard development context |
| `temporary`    | 0.7x   | Fast   | Debug sessions, experiments |
| `deprecated`   | 0.3x   | Fast   | Outdated, superseded information |

### Memory Decay System

**Formula**: `decay_factor = 0.5 ^ (days_since_access / 90)`

| Days | Decay Factor | 
| ---- | ------------ |
| 0    | 1.00         |
| 30   | 0.79         |
| 90   | 0.50         |
| 180  | 0.25         |

**Bypass decay**: critical tier, historical keywords ("original", "initial"), or `use_decay: false`

### Hybrid Search Pipeline

```
Query → [Vector Search] → Top 20
      → [FTS5 Search]   → Top 20
      → [RRF Fusion]    → Combined ranking
      → [Decay Applied] → Final results
```

### Confidence-Based Promotion

Memories with 90%+ accuracy after 5+ validations are promoted to `important` tier.

```typescript
// Validate memory accuracy
memory_validate({ id: 123, wasUseful: true })
```

### Checkpoint System

Save/restore database state for safe experimentation:

| Command | Purpose |
| ------- | ------- |
| `checkpoint create "name"` | Save current state |
| `checkpoint restore "name"` | Restore to checkpoint |
| `checkpoint list` | View all checkpoints |

See [semantic_memory.md](./references/semantic_memory.md) for complete documentation.

---

## 4. 📋 RULES

### ✅ ALWAYS

1. **ALWAYS detect spec folder before creating documentation**
   - Use 70% alignment threshold
   - Prompt user if uncertain

2. **ALWAYS use single `memory/` folder with timestamped files**
   - Format: `DD-MM-YY_HH-MM__topic.md`
   - Include `metadata.json` with session stats

3. **ALWAYS search context before implementing in folders with memory**
   - Run `memory_search()` or `/memory/search` first
   - Load and acknowledge relevant context

4. **ALWAYS generate vector embeddings for new memory files**
   - Enables semantic search
   - Extract trigger phrases for fast matching

5. **ALWAYS call MCP tools directly (NEVER through Code Mode)**
   - `mcp__semantic_memory__memory_search()` - correct
   - `call_tool_chain(semantic_memory...)` - WRONG

### ❌ NEVER

1. **NEVER fabricate decisions that weren't made**
   - Document only actual conversation content
   - Mark uncertainties explicitly

2. **NEVER include sensitive data**
   - No passwords, API keys, tokens
   - Filter before saving

3. **NEVER proceed if spec folder detection fails**
   - Prompt user to create/select folder
   - No orphaned memory files

4. **NEVER skip context recovery in folders with existing memory**
   - Search before implementing
   - Acknowledge prior context

### ⚠️ ESCALATE IF

1. **ESCALATE IF spec folder detection fails**
   - Ask user to create or select folder
   - Cannot proceed without valid target

2. **ESCALATE IF vector embedding generation fails repeatedly**
   - Check MCP server status
   - May need index rebuild

3. **ESCALATE IF alignment score < 70%**
   - Present folder options to user
   - Let user select correct target

---

## 5. ✅ SUCCESS CRITERIA

### Save Complete When

- [ ] Spec folder auto-detected (70%+ alignment)
- [ ] Memory file created: `{timestamp}__{topic}.md`
- [ ] Metadata file created: `metadata.json`
- [ ] Vector embeddings generated
- [ ] Trigger phrases extracted

### Search Complete When

- [ ] Results returned with similarity scores
- [ ] Tier filtering applied (if specified)
- [ ] Decay calculation applied (unless disabled)
- [ ] Context loaded and acknowledged

### Performance Targets

| Operation         | Target  |
| ----------------- | ------- |
| Save              | <3s     |
| Search            | <200ms  |
| Cached search     | <10ms   |
| Trigger match     | <50ms   |
| Context surfacing | <1s     |

---

## 6. 🔗 INTEGRATION POINTS

### Related Skills

| Skill                  | Integration                        |
| ---------------------- | ---------------------------------- |
| `workflows-spec-kit`   | Spec folder creation and routing   |
| `workflows-git`        | Enhances commits with context SHAs |
| `create-documentation` | Flowchart generation patterns      |

### Data Flow

```
Conversation → AI Analysis → JSON → Script → Markdown + Embeddings
```

### Script Locations

| Component       | Location                                       |
| --------------- | ---------------------------------------------- |
| Main script     | `.opencode/memory/scripts/generate-context.js` |
| Memory Database | `.opencode/memory/database/memory-index.sqlite`|

### Quick Reference

**Commands:**

| Command            | Purpose                |
| ------------------ | ---------------------- |
| `/memory/save`     | Save context           |
| `/memory/search`   | Search, Select, Load   |
| `/memory/cleanup`  | Interactive cleanup    |
| `/memory/triggers` | View/manage phrases    |
| `/memory/status`   | Health check           |

**Output**: `specs/###-feature/memory/{date}_{time}__{topic}.md`

**Anchor Format**: `<!-- anchor: category-keywords-spec# -->`

---

**Common Fixes:**
1. **Missing spec folder**: `mkdir -p specs/###-feature/memory/`
2. **Vector search empty**: Run `/memory/search rebuild`
3. **Decay hiding old results**: Use `use_decay: false`

See [troubleshooting.md](./references/troubleshooting.md) for detailed issue resolution.
