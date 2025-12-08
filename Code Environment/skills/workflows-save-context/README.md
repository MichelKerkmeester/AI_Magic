# Save Context - Semantic Memory System

A semantic intelligence layer for the save-context memory system, enabling natural language search, multi-concept queries, and proactive memory surfacing with full backward compatibility with anchor-based retrieval.

---

### TABLE OF CONTENTS

- [1. 📖 OVERVIEW](#1--overview)
- [2. 🚀 QUICK START](#2--quick-start)
- [3. 🎯 TRIGGER PHRASES](#3--trigger-phrases)
- [4. ⚙️ EXECUTION METHODS](#4--execution-methods)
- [5. 🔍 SEMANTIC SEARCH](#5--semantic-search)
- [6. 🔌 MCP TOOLS](#6--mcp-tools)
- [7. 🏗️ ARCHITECTURE](#7--architecture)
- [8. 📊 DATABASE SCHEMA](#8--database-schema)
- [9. ⚡ PERFORMANCE](#9--performance)
- [10. 🛠️ CONFIGURATION](#10--configuration)
- [11. 🧪 TESTING](#11--testing)
- [12. 🔧 TROUBLESHOOTING](#12--troubleshooting)
- [13. ❓ FAQ](#13--faq)
- [14. 📚 RELATED DOCUMENTS](#14--related-documents)
- [15. 🔄 PLATFORM COMPATIBILITY](#15--platform-compatibility)

---

## 1. 📖 OVERVIEW

### What Is Semantic Memory?

The semantic memory system transforms save-context from text/anchor-based retrieval into a semantically-intelligent system. Instead of relying solely on keyword matching and anchors, it uses **vector embeddings** to understand the meaning of your conversations.

### Core Value Proposition

**Find relevant past discussions even when exact keywords don't match.**

Search for "authentication implementation" and find conversations about "login flow" or "user auth" that share semantic meaning.

### Privacy-First Design

**All processing happens locally:**
- Embedding model runs on your machine
- Vector database stored locally
- No data sent to external APIs
- No cloud dependencies

### Key Features

| Feature                  | Description                                                |
| ------------------------ | ---------------------------------------------------------- |
| **Semantic Search**      | Natural language queries ranked by meaning similarity      |
| **Multi-Concept AND**    | Find memories matching ALL specified concepts              |
| **Proactive Surfacing**  | Relevant memories auto-surface based on trigger phrases    |
| **Cross-Folder Search**  | Search across all spec folders in one query                |
| **Graceful Degradation** | Falls back to anchor-only mode if dependencies unavailable |
| **Anchor Compatibility** | All anchor-based commands continue to work                 |

---

## 2. 🚀 QUICK START

```bash
# 1. Install sqlite-vec (macOS)
brew install sqlite-vec

# 2. Install Node.js dependencies
cd .claude/skills/workflows-save-context && npm install

# 3. Save context - interactive folder detection
/memory/save

# 4. Search your memories semantically
/memory/search "how did we implement authentication"

# 5. Rebuild index for existing memories
/memory/search rebuild
```

That's it! The system works automatically after installation.

### System Requirements

| Component      | Minimum    | Recommended |
| -------------- | ---------- | ----------- |
| **Node.js**    | 18.0.0     | 20.x LTS    |
| **npm**        | 8.x        | 10.x        |
| **Disk Space** | 200MB      | 500MB       |
| **RAM**        | 512MB free | 2GB free    |

### Dependencies

| Dependency                  | Version | Purpose                  |
| --------------------------- | ------- | ------------------------ |
| `@huggingface/transformers` | ^3.0.0  | Embedding generation     |
| `better-sqlite3`            | ^9.0.0  | SQLite database          |
| `sqlite-vec`                | Latest  | Vector similarity search |

---

## 3. 🎯 TRIGGER PHRASES

### Save Context Triggers

| Phrase          | Also Works             |
| --------------- | ---------------------- |
| "save context"  | "save conversation"    |
| "document this" | "preserve context"     |
| "save session"  | "save this discussion" |

### Auto-Save

**Every 20 messages** the system automatically saves context. No action required.

### When to Save

| Scenario           | Example                                  |
| ------------------ | ---------------------------------------- |
| Feature complete   | "Just finished the payment integration"  |
| Complex discussion | "We made 5 architecture decisions today" |
| Team sharing       | "Need to document this for the team"     |
| Session ending     | "Wrapping up for the day"                |

---

## 4. ⚙️ EXECUTION METHODS

### Commands (Split Architecture)

The memory system uses two separate commands for clarity:

| Command          | Purpose                                           |
| ---------------- | ------------------------------------------------- |
| `/memory/save`   | Save current context with interactive folder detection |
| `/memory/search` | Search, manage index, view recent, rebuild, verify, retry |

#### /memory/save

Simple save with interactive spec folder detection:
- Detects active spec folder from `.spec-active` or recent activity
- Prompts for confirmation or manual selection
- Generates memory file with embeddings

#### /memory/search

All search and index management operations:

| Subcommand                              | Purpose                           |
| --------------------------------------- | --------------------------------- |
| `/memory/search "query"`                | Semantic search                   |
| `/memory/search multi "term1" "term2"`  | Multi-concept AND search          |
| `/memory/search recent`                 | View recent memories              |
| `/memory/search verify`                 | Check index health                |
| `/memory/search rebuild`                | Regenerate all embeddings         |
| `/memory/search retry`                  | Retry failed embeddings           |
| `/memory/search list-failed`            | List failed embeddings            |

#### /memory/cleanup

Interactive cleanup of old, unused, or low-relevance memories:

| Feature                  | Description                                              |
| ------------------------ | -------------------------------------------------------- |
| **Zero flags required**  | Works without parameters - uses smart defaults           |
| **Interactive preview**  | Shows candidates before any deletion                     |
| **Review mode**          | Step through each memory with [y/n/v]iew options         |
| **Smart defaults**       | 90 days old, <3 accesses, <0.4 confidence                |

**Usage:**
```
/memory/cleanup

# Shows: "Found 5 memories that may be outdated"
# Actions: [a]ll, [r]eview each, [n]one, [c]ancel
```

#### /memory/triggers

View and manage learned trigger phrases:

| Feature               | Description                                               |
| --------------------- | --------------------------------------------------------- |
| **Transparency**      | See what phrases the system learned from your searches    |
| **Add/Remove**        | Manually associate or disassociate phrases with memories  |
| **Search by trigger** | Find memories matching a specific trigger phrase          |
| **Clear all**         | Reset all learned triggers (with confirmation)            |

**Usage:**
```
/memory/triggers              # Interactive menu
/memory/triggers search oauth # Find memories with "oauth" trigger
/memory/triggers clear        # Reset all triggers
```

#### /memory/status

Quick health check and system statistics:

| Metric              | Description                         |
| ------------------- | ----------------------------------- |
| **Memories**        | Total indexed count                 |
| **Health**          | System status (OK/Degraded/Error)   |
| **Last save**       | When context was last saved         |
| **Storage**         | Database size in MB                 |
| **Performance**     | Vector search availability          |

**Usage:**
```
/memory/status

# Output:
# Memories:     47 indexed
# Health:       All systems operational
# Storage:      12.5 MB used
# Quick actions: [s]earch [c]leanup [r]ebuild index
```

### Execution Options

| Method              | Hooks | AI  | Effort | Use Case            |
| ------------------- | ----- | --- | ------ | ------------------- |
| **Keyword trigger** | No    | No  | Zero   | Type "save context" |
| **Slash command**   | No    | Yes | Low    | `/memory/save` or `/memory/search` |
| **Direct script**   | No    | No  | Medium | Testing             |
| **Helper script**   | No    | No  | Low    | Standalone          |

### Script Usage

```bash
# With spec folder argument
node .claude/skills/workflows-save-context/scripts/generate-context.js \
  /tmp/context-data.json "122-feature-name"

# Helper script (auto-detects folder)
bash .claude/skills/workflows-save-context/scripts/save-context-manual.sh
```

---

## 5. 🔍 SEMANTIC SEARCH

### Basic Search

```bash
/memory/search "how did we implement OAuth authentication"
/memory/search "database schema design decisions"
/memory/search "error handling patterns"
```

**Output:**
```
Semantic Search: "OAuth authentication"

Found 3 relevant memories

  [92%] 049-auth-system/memory/28-11-25_14-30__oauth-implementation.md
        "OAuth callback flow implementation with JWT tokens"
        Triggers: oauth, jwt authentication, callback flow

  [78%] 049-auth-system/memory/25-11-25_10-15__auth-decisions.md
        "Authentication strategy decisions and trade-offs"
```

### Multi-Concept AND Search

```bash
/memory/search multi "oauth" "error handling"
/memory/search multi "database" "performance" "queries"
```

Returns only memories matching **ALL** concepts (2-5 concepts supported).

### Interactive Search Mode (Spec 015)

Rich interactive search with preview, filtering, and session persistence:

```
/memory/search "oauth implementation"

Memory Search Results                              Page 1/3
============================================================

Query: "oauth implementation"
Found: 25 memories across 5 spec folders

#1 [92%] OAuth callback flow implementation
   Folder: 049-auth-system  |  Date: Dec 5  |  Tags: oauth, jwt
   "Authorization Code flow with PKCE, httpOnly refresh..."

#2 [85%] JWT token refresh strategy
   Folder: 049-auth-system  |  Date: Dec 4  |  Tags: jwt, refresh
   "Sliding window refresh with httpOnly cookies..."

---------------------------------------------------------------------
Actions: [v]iew #n | [l]oad #n | [f]ilter | [c]luster | [n]ext | [q]uit
```

#### Interactive Actions

| Action           | Purpose                       | Example                          |
| ---------------- | ----------------------------- | -------------------------------- |
| `v#` or `view #` | Preview memory before loading | `v1`                             |
| `l#` or `load #` | Load memory into context      | `l1`                             |
| `f <filter>`     | Filter results                | `f folder:auth date:>2025-12-01` |
| `c`              | Cluster by spec folder        | `c`                              |
| `n` / `p`        | Next/previous page            | `n`                              |
| `e <anchor>`     | Extract specific section      | `e decisions`                    |
| `b`              | Back to previous view         | `b`                              |
| `?`              | Show help                     | `?`                              |

#### Filter Syntax

```bash
f folder:049-auth      # Filter by spec folder (partial match)
f date:>2025-12-01     # Filter by date (after)
f date:<2025-12-01     # Filter by date (before)
f tag:oauth            # Filter by tag
f folder:auth tag:jwt  # Multiple filters (AND)
```

#### Session Persistence

Search sessions persist for 1 hour:
- Resume with `/memory/search resume`
- Auto-saves on every action
- Preserves filters, pagination, and state

### Relevance Scoring

| Factor          | Weight | Description                                      |
| --------------- | ------ | ------------------------------------------------ |
| Category Match  | 35%    | decision > implementation > guide > architecture |
| Keyword Overlap | 30%    | Number of query keywords in anchor ID            |
| Recency Factor  | 20%    | Newer files rank higher                          |
| Spec Proximity  | 15%    | Same spec=1.0, parent=0.8, other=0.3             |

---

## 6. 🔌 MCP TOOLS

### Available Tools

| Tool                    | Purpose                      |
| ----------------------- | ---------------------------- |
| `memory_search`         | Semantic vector search       |
| `memory_load`           | Load memory by spec folder   |
| `memory_match_triggers` | Fast trigger phrase matching |

### memory_search

```json
{
  "query": "authentication implementation",
  "specFolder": "049-auth-system",
  "limit": 5
}
```

**Response:**
```json
{
  "results": [
    {
      "memoryId": 42,
      "title": "OAuth Implementation",
      "filePath": "specs/049-auth-system/memory/28-11-25__oauth.md",
      "similarity": 0.92,
      "triggerPhrases": ["oauth", "jwt", "authentication"]
    }
  ]
}
```

### memory_load

```json
{
  "specFolder": "049-auth-system",
  "anchorId": "decision-oauth-flow"
}
```

---

## 7. 🏗️ ARCHITECTURE

### System Diagram

```
┌────────────────────────────────────────────────────────────────────┐
│                     SEMANTIC MEMORY SYSTEM                         │
├────────────────────────────────────────────────────────────────────┤
│                                                                    │
│  USER INPUT                                                        │
│      │                                                             │
│      ▼                                                             │
│  ┌──────────────────┐                                              │
│  │ /memory/save     │                                              │
│  │ /memory/search   │                                              │
│  └────────┬─────────┘                                              │
│           │                                                        │
│           ▼                                                        │
│  ┌──────────────────┐    ┌───────────────────┐    ┌──────────────┐ │
│  │ generate-context │───▶│ embeddings.js     │───▶│ vector-index │ │
│  │       .js        │    │ (MiniLM-L6-v2)    │    │ (sqlite-vec) │ │
│  └────────┬─────────┘    └───────────────────┘    └──────┬───────┘ │
│           │                                              │         │
│           ▼                                              ▼         │
│  ┌──────────────────┐    ┌───────────────────┐    ┌──────────────┐ │
│  │ trigger-extractor│───▶│ Memory File       │    │ memory-index │ │
│  │ (TF-IDF+N-gram)  │    │ (specs/*/memory/) │    │ .sqlite      │ │
│  └──────────────────┘    └───────────────────┘    └──────────────┘ │
│                                                          │         │
│  ┌──────────────────┐                          ┌──────────────────┐│
│  │ UserPromptSubmit │◀─────────────────────────│ MCP Server       ││
│  │ Hook             │                          │ (memory_search)  ││
│  │ (trigger-matcher)│                          └──────────────────┘│
│  └────────┬─────────┘                                              │
│           │                                                        │
│           ▼                                                        │
│  ┌──────────────────┐                                              │
│  │ Proactive Memory │                                              │
│  │ Surfacing        │                                              │
│  └──────────────────┘                                              │
│                                                                    │
└────────────────────────────────────────────────────────────────────┘
```

### Data Flow

```
Save Flow:
  Conversation → generate-context.js → [Write .md, Generate Embedding, Extract Triggers]
                                                ↓
                                     Index in sqlite-vec + Store metadata
                                                ↓
                                        Context Saved (async)

Search Flow:
  Query → Generate Embedding (300-500ms) → sqlite-vec Similarity (<100ms) → Ranked Results

Trigger Flow:
  Prompt → Load Cache (<20ms) → String Match (<10ms) → Rank → Inject Top 3 (<50ms total)
```

### Storage Architecture

| Data Type         | Location                        | Purpose                            |
| ----------------- | ------------------------------- | ---------------------------------- |
| Memory content    | `specs/*/memory/*.md`           | Human-readable, version controlled |
| Metadata          | `specs/*/memory/metadata.json`  | Session info, embedding status     |
| Vector embeddings | `.opencode/memory/memory-index.sqlite` | Fast semantic search (project-local) |
| Trigger cache     | In-memory                       | <50ms hook execution               |

---

## 8. 📊 DATABASE SCHEMA

### memory_index Table

```sql
CREATE TABLE memory_index (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    spec_folder TEXT NOT NULL,
    file_path TEXT NOT NULL UNIQUE,
    anchor_id TEXT,
    title TEXT,
    summary TEXT,
    trigger_phrases TEXT,          -- JSON array
    importance_weight REAL,        -- 0.0 to 1.0
    embedding_status TEXT,         -- pending | success | failed | retry
    retry_count INTEGER DEFAULT 0,
    last_retry_at TEXT,
    failure_reason TEXT,
    created_at TEXT DEFAULT (datetime('now')),
    updated_at TEXT DEFAULT (datetime('now'))
);

CREATE INDEX idx_memory_spec_folder ON memory_index(spec_folder);
CREATE INDEX idx_memory_status ON memory_index(embedding_status);
```

### vec_memories Virtual Table

```sql
CREATE VIRTUAL TABLE vec_memories USING vec0(
    embedding FLOAT[384]
);

-- rowid corresponds to memory_index.id
SELECT m.*, v.distance
FROM memory_index m
JOIN vec_memories v ON m.id = v.rowid
WHERE v.embedding MATCH ?
ORDER BY v.distance
LIMIT 10;
```

### Embedding Status Values

| Status    | Description                           |
| --------- | ------------------------------------- |
| `pending` | Embedding generation scheduled        |
| `success` | Embedding generated and indexed       |
| `retry`   | Failed, will retry (retry_count < 3)  |
| `failed`  | Permanently failed (retry_count >= 3) |

---

## 9. ⚡ PERFORMANCE

### Target Metrics

| Operation            | Target | Typical |
| -------------------- | ------ | ------- |
| Manual save          | 2-3s   | ~2.5s   |
| Auto-save            | 3-5s   | ~4s     |
| Embedding generation | <500ms | ~400ms  |
| Semantic search      | <100ms | ~80ms   |
| Multi-concept search | <200ms | ~150ms  |
| Trigger matching     | <50ms  | ~35ms   |
| Vector search        | <500ms | ~450ms  |

### Memory Usage

| Component                     | Memory |
| ----------------------------- | ------ |
| Embedding model               | ~200MB |
| Trigger cache (1000 memories) | ~50KB  |
| SQLite connection             | ~10MB  |
| Per embedding                 | ~1.5KB |

### Optimization Tips

1. **Model Warmup**: Pre-load model before heavy usage
2. **Limit Search Scope**: Use `--spec` flag to search specific folder
3. **Adjust Similarity**: Higher threshold = fewer, more relevant results
4. **Cache TTL**: Increase `cacheTimeMs` for less frequent refreshes

---

## 10. 🛠️ CONFIGURATION

### Environment Variables

| Variable                   | Default                         | Description                      |
| -------------------------- | ------------------------------- | -------------------------------- |
| `CLAUDE_MEMORY_INDEX_PATH` | `.opencode/memory/memory-index.sqlite` | Vector index location (project-local) |
| `HUGGINGFACE_CACHE`        | `~/.cache/huggingface/`         | Model cache directory            |
| `DEBUG_TRIGGER_MATCHER`    | `false`                         | Enable verbose trigger logs      |
| `MEMORY_SURFACING_LIMIT`   | `3`                             | Max memories surfaced per prompt |

### config.jsonc

```jsonc
{
  "embedding": {
    "model": "Xenova/all-MiniLM-L6-v2",
    "dimensions": 384,
    "maxTextLength": 2000
  },
  "surfacing": {
    "enabled": true,
    "maxMemories": 3,
    "minImportanceWeight": 0.3,
    "cacheTimeMs": 60000
  },
  "search": {
    "defaultLimit": 10,
    "minSimilarity": 0.5,
    "multiConceptMinSimilarity": 0.4
  },
  "retry": {
    "maxAttempts": 3,
    "backoffMinutes": [1, 5, 15]
  }
}
```

### File Locations

| File           | Location                        | Purpose                 |
| -------------- | ------------------------------- | ----------------------- |
| Vector Index   | `.opencode/memory/memory-index.sqlite` | Embeddings + metadata (project-local) |
| Memory Content | `specs/*/memory/*.md`           | Human-readable markdown |
| Metadata       | `specs/*/memory/metadata.json`  | Session metadata        |

---

## 11. 🧪 TESTING

### Run Tests

```bash
cd .claude/skills/workflows-save-context

# Unit tests
node scripts/tests/embeddings.test.js
node scripts/tests/trigger-extractor.test.js
node scripts/tests/trigger-matcher.test.js
node scripts/tests/vector-index.test.js

# Integration tests
node scripts/tests/integration/mcp-server.integration.test.js
node scripts/tests/integration/hook-surfacing.integration.test.js

# E2E tests
node scripts/tests/e2e/full-workflow.e2e.test.js

# Performance tests
node scripts/tests/performance/latency.perf.test.js
```

### Test Coverage

| Module               | Tests              | Coverage                           |
| -------------------- | ------------------ | ---------------------------------- |
| embeddings.js        | Unit               | Generation, normalization, Unicode |
| vector-index.js      | Unit + Integration | CRUD, search, multi-concept        |
| trigger-extractor.js | Unit               | Extraction, stop words, dedup      |
| trigger-matcher.js   | Unit + Integration | Matching, cache, performance       |
| MCP Server           | Integration        | Tools, error handling              |

### Manual Testing

```bash
# 1. Save a test context
/memory/save

# 2. Verify it was indexed
/memory/search verify

# 3. Search for it
/memory/search "your test topic"
```

---

## 12. 🔧 TROUBLESHOOTING

### Common Issues

#### sqlite-vec extension not found

```bash
# macOS
brew install sqlite-vec

# Verify
sqlite3 -cmd ".load sqlite-vec" -cmd "SELECT vec_version()"
```

**Fallback:** System operates in anchor-only mode

#### Model download failed

```bash
# Manual model download
npx @huggingface/transformers download Xenova/all-MiniLM-L6-v2

# Or set custom cache directory
export HUGGINGFACE_HUB_CACHE=/path/to/cache
```

#### Embedding generation failed

```bash
# Check status
/memory/search list-failed

# Retry
/memory/search retry

# If persistent, rebuild
/memory/search rebuild
```

#### Search returns no results

1. Verify index exists: `/memory/search verify`
2. Rebuild index: `/memory/search rebuild`
3. Check query is meaningful (avoid single words)
4. Lower similarity threshold in config

### Batch Indexing

When you need to rebuild the index or index many memory files at once:

```bash
cd .claude/skills/workflows-save-context/scripts

# Auto-scan all memory files (recursive - supports nested specs)
node index-all.js --scan /path/to/project

# Or use a manifest file (one path per line)
find specs -name "*.md" -path "*/memory/*" > /tmp/manifest.txt
node index-all.js /tmp/manifest.txt
```

**Scan Coverage:**
- `specs/001-foo/memory/` ✓
- `specs/001-foo/002-bar/memory/` ✓ (nested)
- `specs/001-foo/002-bar/003-baz/memory/` ✓ (deeply nested)

### Diagnostic Commands

```bash
# System status
/memory/search verify

# Index statistics
sqlite3 .opencode/memory/memory-index.sqlite \
  "SELECT embedding_status, COUNT(*) FROM memory_index GROUP BY embedding_status"

# Test embedding
node -e "
require('.claude/skills/workflows-save-context/scripts/lib/embeddings')
  .generateEmbedding('test')
  .then(e => console.log('OK:', e.length, 'dimensions'))
  .catch(e => console.error('ERROR:', e.message))
"

# Batch reindex all memories
node .claude/skills/workflows-save-context/scripts/index-all.js --scan .
```

### Log Locations

| Log              | Location                                                |
| ---------------- | ------------------------------------------------------- |
| Hook performance | `.claude/hooks/logs/performance.log`                    |
| Trigger matching | `.claude/hooks/logs/suggest-semantic-search.log`        |
| Save context     | `.claude/hooks/logs/workflows-save-context-trigger.log` |

---

## 13. ❓ FAQ

### General

**Q: Does this send my data to external servers?**
A: No. All processing is local. The embedding model runs on your machine.

**Q: How much disk space does it use?**
A: ~100MB for the model (first download), ~1.5KB per memory embedding.

**Q: Will this slow down my workflow?**
A: No. Embedding generation is async and doesn't block saves. Trigger matching is <50ms.

### Search

**Q: Why doesn't keyword search find exact matches?**
A: Semantic search matches meaning, not keywords. Use grep for exact keyword matches.

**Q: How do I search only one spec folder?**
A: Use `--spec` flag: `/memory/search "query" --spec 049-auth-system`

### Compatibility

**Q: Do my existing memory files still work?**
A: Yes, 100% backward compatible. All anchor-based commands work identically.

**Q: What if sqlite-vec isn't available?**
A: System falls back to anchor-only mode with a warning. Core functionality preserved.

---

## 14. 📚 RELATED DOCUMENTS

### Skill Documentation

- **SKILL.md**: [SKILL.md](./SKILL.md) - Main skill reference
- **Slash Commands**: `/memory/save` and `/memory/search`

### Reference Files

| Document                                                                  | Purpose                             |
| ------------------------------------------------------------------------- | ----------------------------------- |
| [execution_methods.md](./references/execution_methods.md)                 | 4 execution paths, anchor retrieval |
| [semantic_memory.md](./references/semantic_memory.md)                     | Vector search, MCP tools            |
| [spec_folder_detection.md](./references/spec_folder_detection.md)         | Folder routing, markers             |
| [workflow_linear_pattern.md](./references/workflow_linear_pattern.md)     | Sequential diagrams                 |
| [workflow_parallel_pattern.md](./references/workflow_parallel_pattern.md) | Concurrent diagrams                 |
| [trigger_config.md](./references/trigger_config.md)                       | Keywords, auto-save interval        |
| [troubleshooting.md](./references/troubleshooting.md)                     | Issue resolution                    |

### Templates & Config

| File                                                   | Purpose                 |
| ------------------------------------------------------ | ----------------------- |
| [context_template.md](./templates/context_template.md) | Output format template  |
| [config.jsonc](./config.jsonc)                         | Runtime configuration   |
| [filters.jsonc](./filters.jsonc)                       | Content filtering rules |

---

## 15. PLATFORM COMPATIBILITY

### Claude Code vs Opencode

This skill works identically on both Claude Code and Opencode with one difference:

| Feature | Claude Code | Opencode |
|---------|-------------|----------|
| Commands | All 5 available | All 5 available |
| Scripts | `.claude/skills/...` | Uses shared `.claude/` implementation |
| Hooks | Full support | Not supported |
| Context surfacing | Automatic (hook) | Manual (`/memory/search`) |

### Opencode Users

Opencode doesn't support hooks, so proactive context surfacing is manual:

1. **Before starting work** in a spec folder, run:
   ```
   /memory/search "your topic"
   ```

2. **The AI should proactively offer** to search for relevant context when you mention a spec folder

3. **All commands work identically**:
   - `/memory/save` - Save context
   - `/memory/search` - Search memories
   - `/memory/cleanup` - Clean up old memories
   - `/memory/triggers` - View learned phrases
   - `/memory/status` - Check system health

### Shared Implementation

Both platforms use the same backend implementation in `.claude/skills/workflows-save-context/`. The `.opencode/` folder contains synced copies for Opencode's skill discovery, but the actual scripts run from `.claude/`.

To sync changes from Claude Code to Opencode:
```bash
bash .claude/scripts/sync-to-opencode.sh
```

---

*This skill operates as a context preservation engine with semantic search, capturing dialogue, decisions, and visual flows while enabling intelligent retrieval across sessions.*
