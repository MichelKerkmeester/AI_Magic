# Semantic Memory Reference

> Vector search, MCP tools, and intelligent memory retrieval for save-context.

---

## 1. 📖 OVERVIEW

Semantic search provides intelligent memory retrieval through vector embeddings, enabling natural language queries across all saved context.

---

## 2. 🎯 KEY COMMANDS

| Command | Purpose | Example |
|---------|---------|---------|
| `vector <query>` | Natural language search | `claude-mem vector "OAuth implementation"` |
| `multi <concepts>` | AND search across concepts | `claude-mem multi oauth errors` |
| `rebuild` | Rebuild vector index | `claude-mem rebuild` |
| `verify` | Check index integrity | `claude-mem verify` |

---

## 3. 🔌 MCP TOOLS

For AI agents, the following MCP tools are available:

| Tool | Purpose |
|------|---------|
| `memory_search` | Semantic vector search |
| `memory_load` | Load memory by spec folder |
| `memory_match_triggers` | Fast trigger phrase matching |

---

## 4. 🏗️ ARCHITECTURE

### Components

| Component | Location |
|-----------|----------|
| Embeddings | `scripts/lib/embeddings.js` |
| Vector Index | `scripts/lib/vector-index.js` |
| Trigger Matcher | `scripts/lib/trigger-matcher.js` |
| Memory Database | `~/.claude/memory-index.sqlite` |

### Data Flow

```
Memory File → Text Extraction → Embedding Generation → Vector Index
                                                            ↓
Query → Query Embedding → Similarity Search → Ranked Results
```

---

## 5. 🧮 EMBEDDING GENERATION

### When Generated

- Automatically on each context save
- During `claude-mem rebuild` command
- When index verification detects missing embeddings

### Model Configuration

```javascript
// Default: Local embedding model
const embedder = new LocalEmbedder({
  model: 'all-MiniLM-L6-v2',
  dimensions: 384
});

// Optional: OpenAI embeddings
const embedder = new OpenAIEmbedder({
  model: 'text-embedding-3-small',
  dimensions: 1536
});
```

---

## 6. 🔍 VECTOR SEARCH

### Basic Search

```bash
# Natural language query
claude-mem vector "how did we implement authentication"

# Output:
# [92%] specs/049-auth/memory/28-11-25_14-30__oauth.md
#       → OAuth callback flow with JWT tokens
# [78%] specs/015-login/memory/15-11-25_10-00__login.md
#       → Session-based login implementation
```

### Multi-Concept Search

```bash
# AND search - finds documents matching ALL concepts
claude-mem multi oauth errors callback

# Output:
# [89%] specs/049-auth/memory/28-11-25_14-30__oauth.md
#       → Contains: oauth (5), errors (3), callback (7)
```

### Relevance Scoring

Smart search uses weighted multi-dimensional scoring:

| Factor | Weight | Description |
|--------|--------|-------------|
| Category Match | 35% | decision > implementation > guide > architecture |
| Keyword Overlap | 30% | Number of query keywords in anchor ID |
| Recency Factor | 20% | Newer files rank higher (1 / days+1) |
| Spec Proximity | 15% | Same spec=1.0, parent=0.8, other=0.3 |

**Formula**: `score = (category*0.35 + keywords*0.30 + recency*0.20 + proximity*0.15) * 100`

---

## 7. 🗄️ INDEX MANAGEMENT

### Rebuild Index

```bash
# Full rebuild (clears and regenerates)
claude-mem rebuild

# Incremental update (new files only)
claude-mem update
```

### Verify Index

```bash
# Check for missing or stale embeddings
claude-mem verify

# Output:
# Index Status: OK
# Total documents: 47
# Missing embeddings: 0
# Stale embeddings: 2
```

### Index Location

- **Database**: `~/.claude/memory-index.sqlite`
- **Backup**: `~/.claude/memory-index.sqlite.bak`

---

## 8. ⚡ TRIGGER PHRASE MATCHING

Fast trigger detection for auto-save:

```javascript
// Registered triggers
const TRIGGERS = [
  'save context',
  'save conversation',
  'document this',
  'preserve context',
  'save session'
];

// Matching (< 50ms)
const matched = triggerMatcher.match(userMessage);
// Returns: { matched: true, trigger: 'save context', confidence: 0.95 }
```

---

## 9. 🔗 MCP SERVER INTEGRATION

### Starting the Server

```bash
# Start MCP server for memory tools
node .opencode/skills/workflows-save-context/scripts/mcp-server.js
```

### Using MCP Tools

```typescript
// Search memory semantically
const results = await mcp.memory_search({
  query: "authentication decisions",
  limit: 5
});

// Load specific memory file
const memory = await mcp.memory_load({
  specFolder: "049-auth",
  sessionId: "latest"
});

// Check for triggers
const trigger = await mcp.memory_match_triggers({
  message: "save context for the auth work"
});
```

---

## 10. 📈 PERFORMANCE TARGETS

| Operation | Target | Actual |
|-----------|--------|--------|
| Vector search | <500ms | ~450ms |
| Trigger matching | <50ms | ~35ms |
| Embedding generation | <2s/file | ~1.5s |
| Index rebuild (50 files) | <60s | ~45s |

---

## 11. ⚙️ CONFIGURATION

### config.jsonc

```jsonc
{
  "semantic": {
    "enabled": true,
    "model": "local",  // "local" | "openai"
    "dimensions": 384,
    "indexPath": "~/.claude/memory-index.sqlite"
  },
  "triggers": {
    "autoSaveInterval": 20,
    "phrases": ["save context", "document this"]
  }
}
```

---

## 12. 🐛 TROUBLESHOOTING

### Empty Search Results

```bash
# Check if index exists
ls -la ~/.claude/memory-index.sqlite

# Rebuild if missing
claude-mem rebuild
```

### Slow Search Performance

```bash
# Check index size
sqlite3 ~/.claude/memory-index.sqlite "SELECT COUNT(*) FROM embeddings"

# Optimize if >1000 documents
claude-mem optimize
```

### Embedding Failures

```bash
# Check model availability
claude-mem verify --verbose

# Fall back to keyword search
grep -r "keyword" specs/*/memory/*.md
```

---

## 13. 🔄 MIGRATION

Semantic features are fully backward compatible:

- Existing anchor-based retrieval still works
- New semantic search is additive
- Memory files unchanged
- Embeddings generated on-demand

**To enable semantic features**:
1. Run `claude-mem rebuild` to generate embeddings
2. Start using `claude-mem vector` for searches

---

*Related: [SKILL.md](../SKILL.md) | [execution_methods.md](./execution_methods.md)*
