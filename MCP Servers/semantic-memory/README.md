# Semantic Memory MCP Server

A Model Context Protocol server providing semantic search, memory loading, and fast trigger phrase matching for conversation context retrieval.

---

## 📋 TABLE OF CONTENTS

1. [📖 OVERVIEW](#1--overview)
2. [⚡ QUICK REFERENCE](#2--quick-reference)
3. [🏗️ ARCHITECTURE](#3-️-architecture)
4. [🔧 TOOLS](#4--tools)
5. [⚙️ CONFIGURATION](#5-️-configuration)
6. [🚀 USAGE PATTERNS](#6--usage-patterns)
7. [📊 PERFORMANCE](#7--performance)
8. [🛠️ TROUBLESHOOTING](#8-️-troubleshooting)
9. [📚 RESOURCES](#9--resources)

---

## 1. 📖 OVERVIEW

### What It Does

The Semantic Memory MCP Server exposes conversation memory operations as standard MCP tools. It enables AI assistants to:

- **Search memories semantically** using vector embeddings
- **Load memory content** by spec folder or anchor ID
- **Match trigger phrases** for fast keyword-based retrieval

### Key Features

- **Local Embeddings**: Uses `all-MiniLM-L6-v2` model (384 dimensions) - no external API calls
- **Fast Trigger Matching**: Sub-50ms phrase matching for proactive surfacing
- **Multi-Concept Search**: Find memories matching ALL specified concepts
- **Graceful Degradation**: Falls back to anchor-only mode if sqlite-vec unavailable
- **Cross-Platform**: Works with Claude Code, OpenCode, and other MCP clients

### Version Information

| Property     | Value                 |
| ------------ | --------------------- |
| **Version**  | 10.0.0                |
| **Protocol** | MCP (stdio transport) |
| **License**  | MIT                   |

---

## 2. ⚡ QUICK REFERENCE

### Tools at a Glance

| Tool                    | Purpose                | Speed  | Use When                     |
| ----------------------- | ---------------------- | ------ | ---------------------------- |
| `memory_search`         | Semantic vector search | ~500ms | Need meaning-based retrieval |
| `memory_load`           | Load memory content    | <10ms  | Know exact spec folder/ID    |
| `memory_match_triggers` | Fast phrase matching   | <50ms  | Quick keyword lookup first   |

### Tool Selection Flowchart

```
User Request
     │
     ▼
┌─────────────────────────────────────────┐
│ Does request contain specific keywords?  │
└────────────────┬────────────────────────┘
                 │
         ┌───────┴───────┐
         │               │
        YES              NO
         │               │
         ▼               ▼
┌─────────────────┐  ┌────────────────────┐
│ memory_match_   │  │ Need semantic      │
│ triggers        │  │ understanding?     │
│ (<50ms)         │  └─────────┬──────────┘
└────────┬────────┘            │
         │              ┌──────┴──────┐
         │             YES            NO
         │              │              │
         ▼              ▼              ▼
┌─────────────────┐  ┌──────────────┐  ┌────────────────┐
│ Found matches?  │  │ memory_search│  │ memory_load    │
│                 │  │ (~500ms)     │  │ (direct access)│
└────────┬────────┘  └──────────────┘  └────────────────┘
         │
    ┌────┴────┐
   YES        NO
    │          │
    ▼          ▼
┌────────┐  ┌──────────────┐
│ Done!  │  │ memory_search│
│        │  │ (fallback)   │
└────────┘  └──────────────┘
```

---

## 3. 🏗️ ARCHITECTURE

### System Overview

```
┌─────────────────────────────────────────────────────────────┐
│                    MCP Client (Claude/OpenCode)             │
└─────────────────────────────┬───────────────────────────────┘
                              │ stdio
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                    memory-server.js                         │
│  ┌─────────────────────────────────────────────────────┐    │
│  │ MCP Protocol Handler (@modelcontextprotocol/sdk)    │    │
│  │ - ListTools / CallTool handlers                     │    │
│  └─────────────────────────────────────────────────────┘    │
│                              │                              │
│  ┌───────────┬───────────────┼───────────────┬───────────┐  │
│  │           │               │               │           │  │
│  ▼           ▼               ▼               ▼           │  │
│ ┌─────┐   ┌─────────┐   ┌─────────┐   ┌──────────────┐   │  │
│ │embed│   │vector-  │   │trigger- │   │trigger-      │   │  │
│ │dings│   │index.js │   │matcher  │   │extractor.js  │   │  │
│ │.js  │   │         │   │.js      │   │(save only)   │   │  │
│ └──┬──┘   └────┬────┘   └────┬────┘   └──────────────┘   │  │
│    │           │              │                          │  │
│    │     ┌─────┴─────┐        │                          │  │
│    │     │           │        │                          │  │
│    ▼     ▼           ▼        ▼                          │  │
│ ┌────────────┐  ┌────────────────┐                       │  │
│ │ HuggingFace│  │ SQLite + vec   │                       │  │
│ │ MiniLM-L6  │  │ memory-index   │                       │  │
│ │ (local)    │  │ .sqlite        │                       │  │
│ └────────────┘  └────────────────┘                       │  │
└─────────────────────────────────────────────────────────────┘
```

### Database Schema

```sql
-- Metadata table
CREATE TABLE memory_index (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  spec_folder TEXT NOT NULL,
  file_path TEXT NOT NULL,
  anchor_id TEXT,
  title TEXT,
  trigger_phrases TEXT,      -- JSON array
  importance_weight REAL DEFAULT 0.5,
  embedding_status TEXT DEFAULT 'pending',
  retry_count INTEGER DEFAULT 0,
  created_at TEXT,
  updated_at TEXT
);

-- Vector table (sqlite-vec)
CREATE VIRTUAL TABLE vec_memories USING vec0(
  embedding FLOAT[384]
);
-- Note: rowids synchronized between tables
```

---

## 4. 🔧 TOOLS

### 4.1 memory_search

**Purpose**: Search conversation memories semantically using vector similarity.

**Parameters**:

| Parameter    | Type   | Required | Default | Description                   |
| ------------ | ------ | -------- | ------- | ----------------------------- |
| `query`      | string | Yes      | -       | Natural language search query |
| `concepts`   | array  | No       | -       | 2-5 concepts for AND search   |
| `specFolder` | string | No       | -       | Limit to specific spec folder |
| `limit`      | number | No       | 10      | Maximum results               |

**Example Request**:
```json
{
  "query": "authentication implementation decisions",
  "specFolder": "049-auth-system",
  "limit": 5
}
```

**Example Response**:
```json
{
  "searchType": "vector",
  "count": 2,
  "results": [
    {
      "id": 42,
      "specFolder": "049-auth-system",
      "filePath": "specs/049-auth-system/memory/28-11-25_14-30__oauth.md",
      "title": "OAuth Implementation Session",
      "similarity": 0.89,
      "triggerPhrases": ["oauth", "jwt", "authentication"],
      "createdAt": "2025-11-28T14:30:00Z"
    }
  ]
}
```

---

### 4.2 memory_load

**Purpose**: Load memory content by spec folder, anchor ID, or memory ID.

**Parameters**:

| Parameter    | Type   | Required | Default | Description             |
| ------------ | ------ | -------- | ------- | ----------------------- |
| `specFolder` | string | Yes*     | -       | Spec folder identifier  |
| `anchorId`   | string | No       | -       | Load specific section   |
| `memoryId`   | number | No       | -       | Direct memory ID access |

*Either `specFolder` or `memoryId` required

**Example Request**:
```json
{
  "specFolder": "011-semantic-memory-upgrade",
  "anchorId": "decisions"
}
```

**Example Response**:
```json
{
  "id": 15,
  "specFolder": "011-semantic-memory-upgrade",
  "filePath": "specs/011-semantic-memory-upgrade/memory/06-12-25_18-46.md",
  "title": "Semantic Memory Implementation",
  "anchor": "decisions",
  "content": "## Key Decisions\n\n1. Use MiniLM-L6-v2 for local embeddings..."
}
```

---

### 4.3 memory_match_triggers

**Purpose**: Fast trigger phrase matching without embeddings. Use for quick keyword-based lookups.

**Parameters**:

| Parameter | Type   | Required | Default | Description                    |
| --------- | ------ | -------- | ------- | ------------------------------ |
| `prompt`  | string | Yes      | -       | Text to match against triggers |
| `limit`   | number | No       | 3       | Maximum results                |

**Example Request**:
```json
{
  "prompt": "How did we implement OAuth with JWT tokens?",
  "limit": 3
}
```

**Example Response**:
```json
{
  "matchType": "trigger-phrase",
  "count": 2,
  "results": [
    {
      "memoryId": 42,
      "specFolder": "049-auth-system",
      "filePath": "specs/049-auth-system/memory/28-11-25_14-30__oauth.md",
      "title": "OAuth Implementation",
      "matchedPhrases": ["oauth", "jwt"],
      "importanceWeight": 0.8
    }
  ]
}
```

---

## 5. ⚙️ CONFIGURATION

### Claude Code (.mcp.json)

```json
{
  "mcpServers": {
    "memory_server": {
      "command": "node",
      "args": [
        "/path/to/semantic-memory/memory-server.js"
      ],
      "env": {},
      "disabled": false
    }
  }
}
```

**Enable in settings.local.json**:
```json
{
  "enabledMcpjsonServers": [
    "memory_server"
  ]
}
```

### OpenCode (opencode.json)

```json
{
  "mcp": {
    "memory_server": {
      "type": "local",
      "command": [
        "node",
        "/path/to/semantic-memory/memory-server.js"
      ],
      "environment": {},
      "enabled": true
    }
  }
}
```

---

## 6. 🚀 USAGE PATTERNS

### Pattern 1: Quick Topic Check (OpenCode/No Hooks)

When starting work on a topic, check for existing context:

```
1. Call memory_match_triggers with topic keywords
   → Fast check for relevant memories (<50ms)

2. If matches found, call memory_load for details
   → Load full content of matched memories

3. If no matches, call memory_search for semantic lookup
   → Broader search using meaning (slower but thorough)
```

### Pattern 2: Deep Research

When researching a complex topic:

```
1. Call memory_search with natural language query
   → Find semantically related memories

2. Call memory_search with concepts array
   → Find memories matching ALL concepts (AND search)
   → Example: ["authentication", "error handling", "retry"]

3. Call memory_load for promising results
   → Load full content to review
```

### Pattern 3: Direct Access

When you know exactly what you need:

```
1. Call memory_load with specFolder
   → Get most recent memory for that spec

2. Optionally add anchorId
   → Get specific section only
```

### Smart Routing Logic

```python
def select_memory_tool(user_request):
    # Fast path: specific keywords present
    if has_specific_keywords(user_request):
        result = memory_match_triggers(user_request, limit=3)
        if result.count > 0:
            return memory_load(result.results[0])

    # Semantic path: understanding needed
    if needs_semantic_understanding(user_request):
        return memory_search(user_request)

    # Multi-concept: multiple topics
    if has_multiple_concepts(user_request):
        concepts = extract_concepts(user_request)
        return memory_search(query=user_request, concepts=concepts)

    # Direct path: known location
    if has_spec_folder(user_request):
        return memory_load(specFolder=extract_spec_folder(user_request))
```

---

## 7. 📊 PERFORMANCE

### Targets

| Operation            | Target | Actual |
| -------------------- | ------ | ------ |
| Trigger matching     | <50ms  | ~35ms  |
| Vector search        | <500ms | ~450ms |
| Memory load          | <10ms  | ~5ms   |
| Embedding generation | <500ms | ~400ms |

### Performance Monitoring

Slow operations are logged automatically:

```
[trigger-matcher] matchTriggerPhrases: 45ms (target <50ms)
[embeddings] generateEmbedding: 520ms (target <500ms) - SLOW
```

### Cache Behavior

| Cache               | TTL     | Purpose                           |
| ------------------- | ------- | --------------------------------- |
| Trigger phrases     | 60s     | In-memory cache for fast matching |
| Embedding model     | Session | Singleton pattern, loaded once    |
| Database connection | Session | WAL mode for concurrent access    |

---

## 8. 🛠️ TROUBLESHOOTING

### Server Won't Start

**Problem**: `Error: Cannot find module`

**Solutions**:
1. Check symlink:
   ```bash
   ls -la node_modules
   # Should point to workflows-save-context/node_modules
   ```

2. Reinstall if broken:
   ```bash
   rm node_modules
   ln -s /path/to/.claude/skills/workflows-save-context/node_modules .
   ```

### sqlite-vec Not Loading

**Problem**: `Warning: sqlite-vec unavailable, falling back to anchor-only mode`

**Solutions**:
1. Check platform binary:
   ```bash
   ls node_modules/sqlite-vec-darwin-arm64/  # macOS ARM
   ls node_modules/sqlite-vec-linux-x64/     # Linux x64
   ```

2. Install manually (macOS):
   ```bash
   brew install sqlite-vec
   ```

### No Search Results

**Problem**: `memory_search` returns empty results

**Solutions**:
1. Check database exists:
   ```bash
   ls ~/.claude/memory-index.sqlite
   ```

2. Verify embeddings exist:
   ```bash
   sqlite3 ~/.claude/memory-index.sqlite "SELECT COUNT(*) FROM vec_memories"
   ```

3. Check embedding status:
   ```bash
   sqlite3 ~/.claude/memory-index.sqlite \
     "SELECT embedding_status, COUNT(*) FROM memory_index GROUP BY embedding_status"
   ```

### Slow Performance

**Problem**: Operations exceeding targets

**Solutions**:
1. Check for large prompt (truncated at 2000 chars)
2. Verify WAL mode:
   ```bash
   sqlite3 ~/.claude/memory-index.sqlite "PRAGMA journal_mode"
   # Should return: wal
   ```

---

## 9. 📚 RESOURCES

### File Structure

```
semantic-memory/
├── memory-server.js      # Main MCP server (executable)
├── package.json          # Dependencies manifest
├── README.md             # This file
├── node_modules/         # Symlink to shared dependencies
└── lib/
    ├── embeddings.js     # HuggingFace embedding generation
    ├── vector-index.js   # SQLite-vec database operations
    ├── trigger-matcher.js # Fast phrase matching
    ├── trigger-extractor.js # TF-IDF phrase extraction
    └── retry-manager.js  # Failed embedding retry logic
```

### Related Documentation

| Document        | Location                                         | Purpose                   |
| --------------- | ------------------------------------------------ | ------------------------- |
| Install Guide   | `Install Guides/MCP - Semantic Memory.md`        | Step-by-step installation |
| Spec 011        | `specs/011-semantic-memory-upgrade/`             | Full specification        |
| Skills SKILL.md | `.claude/skills/workflows-save-context/SKILL.md` | Save context workflow     |

### Verification Commands

```bash
# Check server version
node memory-server.js --version 2>&1 | head -1

# Test startup (Ctrl+C to exit)
node memory-server.js

# Check database
sqlite3 ~/.claude/memory-index.sqlite ".tables"

# Count indexed memories
sqlite3 ~/.claude/memory-index.sqlite "SELECT COUNT(*) FROM memory_index"
```

---

**Version**: 10.0.0
**Status**: Production Ready
**Protocol**: MCP (Model Context Protocol)
