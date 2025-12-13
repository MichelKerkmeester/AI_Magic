# Semantic Memory Reference - MCP Tools & Intelligent Retrieval

Vector search, hybrid FTS5+vector retrieval, and intelligent memory management for context preservation.

---

## 1. 📖 OVERVIEW

Semantic search provides intelligent memory retrieval through vector embeddings, enabling natural language queries across all saved context. Version 11.1 introduces hybrid search (FTS5 + vector), six-tier importance system, memory decay, checkpoint management, and constitutional memories.

**Core Principle:** Memory should surface relevant context automatically based on semantic meaning, not just keyword matches. The system balances recency, importance, and relevance to prioritize what matters most.

### Key Capabilities

| Feature | Description |
|---------|-------------|
| Hybrid Search | FTS5 keyword + vector semantic fusion via RRF |
| Six Importance Tiers | constitutional → deprecated with boost multipliers |
| Time-Based Decay | 90-day half-life with tier-specific rates |
| Checkpoints | Save/restore memory state for safety |
| Constitutional Tier | Always-surfaced memories (~500 tokens) |
| Confidence Promotion | Auto-promote validated memories to critical |

---

## 2. 🛠️ MCP TOOLS

### Quick Reference

| Tool | Purpose |
|------|---------|
| `memory_search` | Semantic vector search with hybrid FTS5 fusion |
| `memory_load` | Load memory by spec folder and optional anchor |
| `memory_match_triggers` | Fast trigger phrase matching (<50ms) |
| `memory_list` | Browse memories with pagination |
| `memory_update` | Update memory metadata and importance |
| `memory_delete` | Remove memories by ID or spec folder |
| `memory_validate` | Record validation feedback, build confidence |
| `memory_stats` | Get memory system statistics |
| `checkpoint_create` | Save current memory state |
| `checkpoint_list` | List available checkpoints |
| `checkpoint_restore` | Restore from checkpoint |

### memory_search Parameters

```typescript
memory_search({
  query: string,           // Natural language query
  concepts?: string[],     // 2-5 concepts for AND search
  limit?: number,          // Max results (default: 10)
  specFolder?: string,     // Filter by spec folder
  tier?: string,           // Filter by importance tier
  contextType?: string,    // Filter by context type
  useDecay?: boolean,      // Apply time-based decay (default: true)
  includeConstitutional?: boolean  // Include constitutional tier (default: true)
})
```

### memory_update Parameters

```typescript
memory_update({
  id: number,                    // Memory ID to update
  title?: string,                // New title
  triggerPhrases?: string[],     // Updated trigger phrases
  importanceWeight?: number,     // Weight 0-1
  importanceTier?: string        // 'constitutional'|'critical'|'important'|'normal'|'temporary'|'deprecated'
})
```

### memory_validate Parameters

```typescript
memory_validate({
  id: number,         // Memory ID to validate
  wasUseful: boolean  // Whether the memory was useful
})
// After 5+ validations at 90%+ confidence → promotion to critical tier offered
```

---

## 3. 🔍 HYBRID SEARCH

### How It Works

Hybrid search combines FTS5 keyword matching with sqlite-vec vector similarity for optimal results:

1. **FTS5 Search**: Fast keyword-based ranking using BM25
2. **Vector Search**: Semantic similarity using embeddings
3. **Score Fusion**: Reciprocal Rank Fusion (RRF) combines both

### RRF Score Fusion Formula

```
RRF_score(d) = sum( 1 / (k + rank_i(d)) ) for each ranking system i

Where:
- d = document
- k = smoothing constant (default: 60)
- rank_i(d) = rank of document d in system i
```

### Implementation Example

```typescript
async function hybridSearch(query: string, limit: number = 10) {
  // 1. FTS5 keyword search
  const ftsResults = await db.all(`
    SELECT id, bm25(memory_fts) as fts_score
    FROM memory_fts WHERE memory_fts MATCH ?
    ORDER BY fts_score LIMIT ?
  `, [query, limit * 2]);

  // 2. Vector similarity search
  const embedding = await generateEmbedding(query);
  const vecResults = await db.all(`
    SELECT id, vec_distance_cosine(embedding, ?) as vec_score
    FROM memory_index WHERE embedding IS NOT NULL
    ORDER BY vec_score ASC LIMIT ?
  `, [embedding, limit * 2]);

  // 3. RRF fusion
  const k = 60;
  const scores = new Map();
  ftsResults.forEach((r, rank) => {
    scores.set(r.id, (scores.get(r.id) || 0) + 1 / (k + rank + 1));
  });
  vecResults.forEach((r, rank) => {
    scores.set(r.id, (scores.get(r.id) || 0) + 1 / (k + rank + 1));
  });

  return [...scores.entries()].sort((a, b) => b[1] - a[1]).slice(0, limit);
}
```

### Relevance Scoring

| Factor | Weight | Description |
|--------|--------|-------------|
| Hybrid RRF Score | 40% | Combined FTS5 + vector similarity |
| Importance Tier | 25% | Tier boost multiplier |
| Recency/Decay | 20% | Time-based decay factor |
| Keyword Overlap | 15% | Query keywords in anchor ID |

**Formula**: `score = (rrf*0.40 + tier_boost*0.25 + decay*0.20 + keywords*0.15) * 100`

### Fallback Behavior

| Scenario | Behavior |
|----------|----------|
| No FTS matches | Use vector-only results |
| No vector matches | Use FTS-only results |
| Both empty | Return empty with suggestion |
| Embedding unavailable | Fall back to FTS-only |

---

## 4. 📊 IMPORTANCE TIERS & DECAY

### Six-Tier System (v11.1)

| Tier | Description | Boost | Auto-Expire | Always Surface |
|------|-------------|-------|-------------|----------------|
| `constitutional` | Universal rules, core constraints (~500 tokens) | 3.0x | Never | Yes |
| `critical` | Core decisions, architecture choices | 2.0x | Never | No |
| `important` | Key implementations, major features | 1.5x | Never | No |
| `normal` | Standard context, typical work | 1.0x | 90 days | No |
| `temporary` | Debugging sessions, experiments | 0.5x | 7 days | No |
| `deprecated` | Outdated info, superseded decisions | 0.25x | Immediate | No |

### Constitutional Tier

Constitutional memories are **always surfaced** at session start without needing a search query. Limited to ~500 tokens total.

**Use for:**
- Project-wide rules that should never be forgotten
- Critical constraints that apply to all work
- Lessons learned that prevent repeated mistakes

### Memory Decay Formula

```
decayed_score = base_score * decay_factor
decay_factor = max(min_decay, 1 - (days_since_access * decay_rate))
```

### Tier Decay Rates

| Tier | Decay Rate | Half-Life | Min Floor |
|------|------------|-----------|-----------|
| `constitutional` | 0 | Never | 1.0 |
| `critical` | 0.001/day | ~693 days | 0.5 |
| `important` | 0.005/day | ~139 days | 0.3 |
| `normal` | 0.01/day | ~69 days | 0.1 |
| `temporary` | 0.05/day | ~14 days | 0.1 |
| `deprecated` | 0.1/day | ~7 days | 0.05 |

### Disabling Decay

```typescript
// Per-search: disable decay
const results = await memory_search({
  query: "old authentication",
  useDecay: false  // Show all results without decay
});

// Per-memory: set high importance
await memory_update({
  id: 123,
  importanceWeight: 1.0  // Effective decay immunity
});
```

---

## 5. 🗄️ DATABASE SCHEMA

### Core Table: memory_index

```sql
CREATE TABLE memory_index (
  id INTEGER PRIMARY KEY,
  spec_folder TEXT NOT NULL,
  file_path TEXT NOT NULL UNIQUE,
  title TEXT,
  anchor_id TEXT,
  content TEXT,
  embedding BLOB,

  -- Metadata
  created_at TEXT DEFAULT (datetime('now')),
  created_at_epoch INTEGER,
  updated_at TEXT,

  -- Importance system
  importance_weight REAL DEFAULT 0.5,
  importance_tier TEXT CHECK(importance_tier IN (
    'constitutional', 'critical', 'important', 'normal', 'temporary', 'deprecated'
  )) DEFAULT 'normal',

  -- Context classification
  context_type TEXT CHECK(context_type IN (
    'research', 'implementation', 'decision', 'discovery', 'general'
  )) DEFAULT 'general',

  -- Session tracking
  channel TEXT,
  session_id TEXT,

  -- Access tracking (for decay)
  access_count INTEGER DEFAULT 0,
  last_accessed TEXT,

  -- Validation tracking
  validation_count INTEGER DEFAULT 0,
  confidence_score REAL DEFAULT 0.5,

  -- Trigger phrases (JSON array)
  trigger_phrases TEXT DEFAULT '[]'
);

CREATE INDEX idx_memory_spec ON memory_index(spec_folder);
CREATE INDEX idx_memory_tier ON memory_index(importance_tier);
CREATE INDEX idx_memory_context ON memory_index(context_type);
CREATE INDEX idx_memory_created ON memory_index(created_at_epoch);
```

### Supporting Tables

```sql
-- Memory history for audit trail
CREATE TABLE memory_history (
  id INTEGER PRIMARY KEY,
  memory_id INTEGER NOT NULL,
  field_changed TEXT NOT NULL,
  old_value TEXT,
  new_value TEXT,
  changed_at TEXT DEFAULT (datetime('now')),
  FOREIGN KEY (memory_id) REFERENCES memory_index(id) ON DELETE CASCADE
);

-- Checkpoints for state management
CREATE TABLE checkpoints (
  id INTEGER PRIMARY KEY,
  name TEXT NOT NULL,
  description TEXT,
  created_at TEXT DEFAULT (datetime('now')),
  memory_count INTEGER,
  snapshot_path TEXT,
  metadata TEXT  -- JSON blob
);

-- FTS5 for keyword search
CREATE VIRTUAL TABLE memory_fts USING fts5(
  title, content, anchor_id, spec_folder,
  content='memory_index', content_rowid='id',
  tokenize='porter unicode61'
);
```

### Context Types

| Type | Description | Use Case |
|------|-------------|----------|
| `research` | Investigation, analysis | Technical spikes, library evaluations |
| `implementation` | Code changes, feature builds | Active development work |
| `decision` | Architectural choices | ADRs, design decisions |
| `discovery` | Bugs found, unexpected behavior | Debugging sessions |
| `general` | Default catch-all | Unclassified context |

---

## 6. 🔧 CONFIGURATION

### config.jsonc

```jsonc
{
  "semantic": {
    "enabled": true,
    "model": "local",  // "local" | "openai"
    "dimensions": 384,
    "indexPath": ".opencode/memory/database/memory-index.sqlite"
  },
  "triggers": {
    "autoSaveInterval": 20,
    "phrases": ["save context", "document this"]
  },
  "memory": {
    "decay": {
      "enabled": true,
      "rates": {
        "constitutional": 0,
        "critical": 0.001,
        "important": 0.005,
        "normal": 0.01,
        "temporary": 0.05,
        "deprecated": 0.1
      },
      "minFloor": 0.1,
      "exemptTiers": ["constitutional", "critical"]
    },
    "defaultTier": "normal",
    "defaultContextType": "general"
  }
}
```

### Embedding Models

```javascript
// Default: Local embedding model via sqlite-vec
const embedder = new SqliteVecEmbedder({
  model: 'nomic-embed-text-v1.5',
  dimensions: 384
});

// Optional: OpenAI embeddings
const embedder = new OpenAIEmbedder({
  model: 'text-embedding-3-small',
  dimensions: 1536
});
```

---

## 7. ⏱️ PERFORMANCE

### Performance Targets

| Operation | Target | Typical |
|-----------|--------|---------|
| Hybrid search | <500ms | ~300ms |
| Vector-only search | <300ms | ~200ms |
| FTS-only search | <100ms | ~50ms |
| Trigger matching | <50ms | ~35ms |
| Embedding generation | <2s/file | ~1.5s |
| Index rebuild (50 files) | <60s | ~45s |

### Architecture

```
Memory Save → Content Extraction → Embedding Generation
                                          ↓
                              ┌───────────┴───────────┐
                              ↓                       ↓
                         Vector Index            FTS5 Index
                              ↓                       ↓
                              └───────────┬───────────┘
                                          ↓
Query → Query Embedding → Hybrid Search (RRF Fusion) → Ranked Results
                                          ↓
                                    Decay Applied → Final Scores
```

### Index Locations

| Component | Location |
|-----------|----------|
| MCP Server | `semantic-memory-mcp/` |
| SQLite Database | `.opencode/memory/database/memory-index.sqlite` |
| Embeddings | sqlite-vec extension |
| FTS Index | SQLite FTS5 virtual table |

---

## 8. ⚠️ TROUBLESHOOTING

### Empty Search Results

```bash
# Check if index exists
ls -la .opencode/memory/database/memory-index.sqlite

# Rebuild: restart MCP server (auto-rebuilds on startup)
# Or use checkpoint restore if available
```

### Slow Search Performance

```bash
# Check index size
sqlite3 .opencode/memory/database/memory-index.sqlite "SELECT COUNT(*) FROM memory_index"

# Optimize via SQLite VACUUM
sqlite3 .opencode/memory/database/memory-index.sqlite "VACUUM"
```

### Embedding Failures

```bash
# Check via MCP stats tool
# memory_stats() returns embedding model info

# Fall back to keyword search
grep -r "keyword" specs/*/memory/*.md
```

### FTS5 Out of Sync

```bash
# Rebuild FTS index
sqlite3 .opencode/memory/database/memory-index.sqlite "INSERT INTO memory_fts(memory_fts) VALUES('rebuild')"
```

### Migration from v10 to v11

Migration is automatic on first access. New columns have sensible defaults:

| Column | Default |
|--------|---------|
| `importance_tier` | `'normal'` |
| `context_type` | `'general'` |
| `access_count` | `0` |
| `created_at_epoch` | Calculated from `created_at` |

---

## 9. ✅ USAGE EXAMPLES

### Basic Search

```typescript
// Natural language query via MCP
const results = await memory_search({
  query: "how did we implement authentication",
  limit: 5
});

// Output:
// [92%] specs/049-auth/memory/28-11-25_14-30__oauth.md
//       → OAuth callback flow with JWT tokens
```

### Multi-Concept AND Search

```typescript
// Finds documents matching ALL concepts
const results = await memory_search({
  concepts: ["oauth", "errors", "callback"]
});

// Output:
// [89%] specs/049-auth/memory/28-11-25_14-30__oauth.md
//       → Contains: oauth (5), errors (3), callback (7)
```

### Filter by Tier and Context

```typescript
// Find critical decisions about authentication
const results = await memory_search({
  query: "authentication",
  tier: "critical",
  contextType: "decision"
});
```

### Checkpoint Operations

```typescript
// Create checkpoint before major changes
await checkpoint_create({
  name: "pre-refactor-v2",
  description: "Before major auth system refactor"
});

// List available checkpoints
const checkpoints = await checkpoint_list();

// Restore if needed
await checkpoint_restore({ name: "pre-refactor-v2" });
```

### Validate and Promote

```typescript
// Validate memory accuracy (builds confidence)
await memory_validate({ id: 123, wasUseful: true });

// After 5+ validations at 90%+ confidence
// → Promotion to critical tier may be offered
```

### Trigger Phrase Matching

```typescript
// Fast trigger detection (<50ms)
const trigger = await memory_match_triggers({
  prompt: "save context for the auth work"
});
// Returns: { matched: true, trigger: 'save context', confidence: 0.95 }
```

---

*Related: [SKILL.md](../SKILL.md) | [execution_methods.md](./execution_methods.md)*
