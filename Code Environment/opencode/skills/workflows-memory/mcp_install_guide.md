# Semantic Memory MCP Server Installation Guide

A comprehensive guide to installing, configuring, and using the Semantic Memory MCP server for conversation context retrieval and vector search.

---

## 🤖 AI-FIRST INSTALL GUIDE

### Verify Success (30 seconds)

After installation, test immediately:
1. Open Claude Code in a configured project
2. Type: "Search my memories for recent decisions"
3. See tool invocation = SUCCESS

Not working? Jump to [Troubleshooting](#troubleshooting).

---

> **Related Documentation:**
> - [MCP Server README](../semantic-memory/README.md) - Technical reference
> - workflows-memory SKILL.md - Workflow details (in your project's `.claude/skills/` or `.opencode/skills/`)
> - `/save_context` command - Command reference

---

**Copy and paste this prompt to your AI assistant to get installation help:**

```
I want to install the Semantic Memory MCP server for conversation memory retrieval.

Please help me:
1. Check if I have Node.js 18+ installed
2. Verify better-sqlite3 and sqlite-vec are available
3. Copy the server files to my MCP Servers directory
4. Create the required symlinks for node_modules
5. Configure for my AI environment (I'm using: [Claude Code / OpenCode])
6. Initialize the database
7. Test the installation with a basic memory search

My project path is: [your-project-path]
My MCP Servers directory is: [your-mcp-servers-path]

Guide me through each step with the exact commands and configuration needed.
```

**What the AI will do:**
- Verify Node.js 18+ and npm are available
- Check for or install native dependencies (better-sqlite3, sqlite-vec)
- Copy server files to your designated location
- Create symlink to shared node_modules
- Configure MCP settings for your platform
- Initialize the SQLite database with vector extension
- Test all three tools: `memory_search`, `memory_load`, `memory_match_triggers`

**Expected setup time:** 5-10 minutes

---

#### 📋 TABLE OF CONTENTS

1. [📖 OVERVIEW](#1--overview)
2. [📋 PREREQUISITES](#2--prerequisites)
3. [📥 INSTALLATION](#3--installation)
4. [⚙️ CONFIGURATION](#4-️-configuration)
5. [✅ VERIFICATION](#5--verification)
6. [🚀 USAGE](#6--usage)
7. [🎯 FEATURES](#7--features)
8. [🔧 TROUBLESHOOTING](#8--troubleshooting)
9. [📚 RESOURCES](#9--resources)

---

## 1. 📖 OVERVIEW

The Semantic Memory MCP Server provides AI assistants with conversation memory retrieval capabilities. It enables semantic search using local vector embeddings, fast trigger phrase matching, and direct memory content loading.

### Key Features

- **Local Embeddings**: Uses `nomic-embed-text-v1.5` model (768 dimensions) - no external API calls
- **Fast Trigger Matching**: Sub-50ms phrase matching for proactive surfacing
- **Multi-Concept Search**: Find memories matching ALL specified concepts
- **Graceful Degradation**: Falls back to anchor-only mode if sqlite-vec unavailable
- **Cross-Platform**: Works with Claude Code, OpenCode, and other MCP clients

### Embedding Model

> **Model**: `nomic-ai/nomic-embed-text-v1.5` (768 dimensions)

| Specification      | Value                              |
| ------------------ | ---------------------------------- |
| **Model Name**     | `nomic-ai/nomic-embed-text-v1.5`   |
| **Dimensions**     | 768                                |
| **Context Window** | 8,192 tokens                       |
| **Inference**      | Local (HuggingFace Transformers)   |
| **Storage**        | sqlite-vec (`FLOAT[768]`)          |

**Why nomic-embed-text-v1.5?**
- 2x larger context window than alternatives (8K vs 512 tokens)
- Better semantic understanding for technical documentation
- Fully local inference - no API calls, complete privacy

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

### Architecture Overview

```
┌─────────────────────────────────────────────────────────────┐
│                    MCP Client (Claude/OpenCode)             │
└─────────────────────────────┬───────────────────────────────┘
                              │ stdio
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                    semantic-memory.js                         │
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
│ │ nomic-v1.5 │  │ memory-index   │                       │  │
│ │ (local)    │  │ .sqlite        │                       │  │
│ └────────────┘  └────────────────┘                       │  │
└─────────────────────────────────────────────────────────────┘
```

### Performance Targets

| Operation            | Target | Typical |
| -------------------- | ------ | ------- |
| Trigger matching     | <50ms  | ~35ms   |
| Vector search        | <500ms | ~450ms  |
| Memory load          | <10ms  | ~5ms    |
| Embedding generation | <500ms | ~400ms  |

---

## 2. 📋 PREREQUISITES

Before installing the Semantic Memory MCP server, ensure you have:

### Required

- **Node.js 18 or higher**
  ```bash
  node --version
  # Should show v18.x or higher
  ```

- **npm** (comes with Node.js)
  ```bash
  npm --version
  ```

- **MCP-Compatible Client** (one of the following):
  - Claude Code CLI
  - OpenCode CLI

### Dependencies (Auto-installed)

These dependencies are required and typically available via shared node_modules:

| Dependency                  | Purpose                     |
| --------------------------- | --------------------------- |
| `@modelcontextprotocol/sdk` | MCP protocol implementation |
| `better-sqlite3`            | SQLite database driver      |
| `sqlite-vec`                | Vector similarity extension |
| `@huggingface/transformers` | Local embedding model       |

### Database Location

The memory database is stored at:
```
.opencode/memory/memory-index.sqlite
```

This location is shared between Claude Code and OpenCode.

### Common Setup Gotchas

**Two config files needed (Claude Code):**
- `.mcp.json` - defines the server
- `settings.local.json` - enables via `enabledMcpjsonServers: ["semantic_memory"]`

**Platform-specific sqlite-vec:**
- macOS ARM: `sqlite-vec-darwin-arm64`
- macOS Intel: `sqlite-vec-darwin-x64`
- Linux: `sqlite-vec-linux-x64`

**Graceful fallback:** If sqlite-vec fails, system uses keyword search automatically.

---

## 3. 📥 INSTALLATION

### Step 1: Create Server Directory

```bash
# Create directory for the MCP server
mkdir -p "/Users/developer/projects/mcp-servers/semantic-memory"
cd "/Users/developer/projects/mcp-servers/semantic-memory"
```

### Step 2: Copy Server Files

Copy from your Claude Code skills directory:

```bash
# Copy main server file
cp /path/to/.claude/skills/workflows-memory/scripts/semantic-memory.js .

# Copy lib directory
mkdir -p lib
cp /path/to/.claude/skills/workflows-memory/scripts/lib/embeddings.js lib/
cp /path/to/.claude/skills/workflows-memory/scripts/lib/vector-index.js lib/
cp /path/to/.claude/skills/workflows-memory/scripts/lib/trigger-matcher.js lib/
cp /path/to/.claude/skills/workflows-memory/scripts/lib/trigger-extractor.js lib/
cp /path/to/.claude/skills/workflows-memory/scripts/lib/retry-manager.js lib/
```

### Step 3: Create node_modules Symlink

```bash
# Create symlink to shared dependencies
ln -s /path/to/.claude/skills/workflows-memory/node_modules .
```

**Note:** This avoids duplicating 527MB of dependencies.

### Step 4: Create package.json

```bash
cat > package.json << 'EOF'
{
  "name": "semantic-memory-mcp",
  "version": "10.0.0",
  "description": "MCP server for semantic memory search and retrieval",
  "main": "semantic-memory.js",
  "type": "commonjs",
  "scripts": {
    "start": "node semantic-memory.js"
  },
  "dependencies": {
    "@huggingface/transformers": "^3.5.1",
    "@modelcontextprotocol/sdk": "^1.0.0",
    "better-sqlite3": "^11.5.0",
    "sqlite-vec": "^0.1.6-alpha.4"
  }
}
EOF
```

### Step 5: Test Server Startup

```bash
# Test that server starts correctly
node semantic-memory.js
# Press Ctrl+C after seeing successful startup message
```

---

## 4. ⚙️ CONFIGURATION

### Option A: Configure for Claude Code CLI

Add to `.mcp.json` in your project root:

```json
{
  "mcpServers": {
    "semantic_memory": {
      "command": "node",
      "args": [
        "/Users/developer/projects/mcp-servers/semantic-memory/semantic-memory.js"
      ],
      "env": {},
      "disabled": false
    }
  }
}
```

Enable in `settings.local.json`:

```json
{
  "enabledMcpjsonServers": [
    "semantic_memory"
  ]
}
```

### Option B: Configure for OpenCode

Add to `opencode.json` in your project root:

```json
{
  "mcp": {
    "semantic_memory": {
      "type": "local",
      "command": [
        "node",
        "/Users/developer/projects/mcp-servers/semantic-memory/semantic-memory.js"
      ],
      "environment": {},
      "enabled": true
    }
  }
}
```

### Database Path Configuration

The default database path is `.opencode/memory/memory-index.sqlite`. This can be overridden via environment variable:

```json
{
  "env": {
    "MEMORY_DB_PATH": "/custom/path/memory-index.sqlite"
  }
}
```

---

## 5. ✅ VERIFICATION

### One-Command Health Check

```bash
sqlite3 .opencode/memory/memory-index.sqlite "SELECT 'OK: ' || COUNT(*) || ' memories' FROM memory_index" 2>/dev/null || echo "Database not created yet (will be created on first save)"
```

### Check 1: Verify Server Files

```bash
# Check all required files exist
ls -la /path/to/semantic-memory/
# Should show: semantic-memory.js, lib/, node_modules, package.json

ls -la /path/to/semantic-memory/lib/
# Should show: embeddings.js, vector-index.js, trigger-matcher.js,
#              trigger-extractor.js, retry-manager.js
```

### Check 2: Verify node_modules Symlink

```bash
# Check symlink is valid
ls -la /path/to/semantic-memory/node_modules/better-sqlite3
# Should resolve to actual directory, not show broken symlink
```

### Check 3: Test Server Startup

```bash
# Start server manually (will wait for MCP protocol input)
node /path/to/semantic-memory/semantic-memory.js

# Expected: No errors, server waits for input
# Press Ctrl+C to exit
```

### Check 4: Verify in Your AI Client

**In Claude Code:**
```bash
# Start Claude Code session
claude

# Ask about available tools
> What memory tools are available?

# Expected: Should list memory_search, memory_load, memory_match_triggers
```

**In OpenCode:**
```bash
opencode

> List available MCP tools

# Expected: Memory tools should appear
```

### Check 5: Test Database Connection

```bash
# Check database exists and has tables
sqlite3 .opencode/memory/memory-index.sqlite ".tables"
# Expected: memory_index vec_memories

# Count indexed memories
sqlite3 .opencode/memory/memory-index.sqlite "SELECT COUNT(*) FROM memory_index"
```

---

## 6. 🚀 USAGE

### Pattern 1: Quick Topic Check

When starting work on a topic, check for existing context:

```
1. Call memory_match_triggers with topic keywords
   → Fast check for relevant memories (<50ms)

2. If matches found, call memory_load for details
   → Load full content of matched memories

3. If no matches, call memory_search for semantic lookup
   → Broader search using meaning (slower but thorough)
```

**Example conversation:**
```
User: Let's work on the authentication system

AI uses memory_match_triggers("authentication system")
→ Returns matches with specFolders and file paths

AI uses memory_load(specFolder: "049-auth-system")
→ Loads full context from previous sessions
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

**Example:**
```json
{
  "specFolder": "011-semantic-memory-upgrade",
  "anchorId": "decisions"
}
```

### Tool Selection Guide

| Scenario               | Tool                            | Why                  |
| ---------------------- | ------------------------------- | -------------------- |
| Quick keyword lookup   | `memory_match_triggers`         | <50ms, no embeddings |
| Semantic understanding | `memory_search`                 | Vector similarity    |
| Known spec folder      | `memory_load`                   | Direct access        |
| Multi-concept search   | `memory_search` with `concepts` | AND search           |

---

## 7. 🎯 FEATURES

### 7.1 memory_search

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

### 7.2 memory_load

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
  "content": "## Key Decisions\n\n1. Use nomic-embed-text-v1.5 for local embeddings..."
}
```

### 7.3 memory_match_triggers

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

## 8. 🔧 TROUBLESHOOTING

### Server Won't Start

**Problem**: `Error: Cannot find module`

**What it means**: The server can't find its dependencies. The symlink to node_modules is missing or broken.

**Fix**:
```bash
ls -la node_modules
# Should point to workflows-memory/node_modules
```

**If that doesn't work**:
```bash
rm node_modules
ln -s /path/to/.claude/skills/workflows-memory/node_modules .
```

### sqlite-vec Not Loading

**Problem**: `Warning: sqlite-vec unavailable, falling back to anchor-only mode`

**What it means**: The vector search extension isn't loading. The system will still work using keyword search, but semantic similarity won't be available.

**Fix**:
```bash
# Check if the right platform binary exists
ls node_modules/sqlite-vec-darwin-arm64/  # macOS ARM
ls node_modules/sqlite-vec-darwin-x64/    # macOS Intel
ls node_modules/sqlite-vec-linux-x64/     # Linux x64
```

**If that doesn't work**:
```bash
# Install manually (macOS)
brew install sqlite-vec
```

### No Search Results

**Problem**: `memory_search` returns empty results

**What it means**: Either no memories have been saved yet, or the embeddings haven't been generated for existing memories.

**Fix**:
```bash
# Check database exists
ls .opencode/memory/memory-index.sqlite

# Verify embeddings exist
sqlite3 .opencode/memory/memory-index.sqlite "SELECT COUNT(*) FROM vec_memories"
```

**If that doesn't work**:
```bash
# Check embedding status - most should show 'completed'
sqlite3 .opencode/memory/memory-index.sqlite \
  "SELECT embedding_status, COUNT(*) FROM memory_index GROUP BY embedding_status"
```

**Rebuild index with batch indexer** (indexes all memory files recursively):
```bash
cd .claude/skills/workflows-memory/scripts
node index-all.js --scan /path/to/project
```

The `--scan` option recursively finds all memory files in nested specs structures like `specs/001-foo/002-bar/memory/`.

### Slow Performance

**Problem**: Operations exceeding targets (triggers >50ms, search >500ms)

**What it means**: The database may not be optimized, or queries are hitting large datasets.

**Fix**:
```bash
# Verify WAL mode is enabled for better concurrency
sqlite3 .opencode/memory/memory-index.sqlite "PRAGMA journal_mode"
# Should return: wal
```

**If that doesn't work**: Large prompts are truncated at 2000 characters. If you're sending very long queries, try shorter, more specific ones.

### Tool Not Appearing in Client

**Problem**: Memory tools not listed in AI client

**What it means**: The MCP configuration isn't being read, or there's a syntax error in the config file.

**Fix**:
```bash
# Check for JSON syntax errors
python3 -m json.tool < .mcp.json
```

**If that doesn't work**:
1. Verify the server path is absolute, not relative
2. For Claude Code: ensure both `.mcp.json` AND `settings.local.json` are configured
3. Restart the AI client after configuration changes

---

## 9. 📚 RESOURCES

### File Structure

```
semantic-memory/
├── semantic-memory.js      # Main MCP server (executable)
├── package.json          # Dependencies manifest
├── README.md             # Documentation
├── node_modules/         # Symlink to shared dependencies
└── lib/
    ├── embeddings.js     # HuggingFace embedding generation
    ├── vector-index.js   # SQLite-vec database operations
    ├── trigger-matcher.js # Fast phrase matching
    ├── trigger-extractor.js # TF-IDF phrase extraction
    └── retry-manager.js  # Failed embedding retry logic
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
  embedding FLOAT[768]
);
-- Note: rowids synchronized between tables
```

### Configuration Paths

| Client          | Configuration File                  | Server Key      |
| --------------- | ----------------------------------- | --------------- |
| **Claude Code** | `.mcp.json` + `settings.local.json` | `semantic_memory` |
| **OpenCode**    | `opencode.json`                     | `semantic_memory` |

### Verification Commands

```bash
# Check server version
node semantic-memory.js --version 2>&1 | head -1

# Test startup (Ctrl+C to exit)
node semantic-memory.js

# Check database tables
sqlite3 .opencode/memory/memory-index.sqlite ".tables"

# Count indexed memories
sqlite3 .opencode/memory/memory-index.sqlite "SELECT COUNT(*) FROM memory_index"

# Check embedding statistics
sqlite3 .opencode/memory/memory-index.sqlite \
  "SELECT embedding_status, COUNT(*) as count FROM memory_index GROUP BY embedding_status"
```

### Performance Monitoring

Slow operations are logged automatically:
```
[trigger-matcher] matchTriggerPhrases: 45ms (target <50ms)
[embeddings] generateEmbedding: 520ms (target <500ms) - SLOW
```

### Related Documentation

| Document        | Location                                         | Purpose                   |
| --------------- | ------------------------------------------------ | ------------------------- |
| Server README   | `semantic-memory/README.md`                      | Full server documentation |
| Skills SKILL.md | Your project's `.claude/skills/` or `.opencode/skills/` | Memory workflow     |

---

## ⚡ Quick Reference

### Tool Summary

| Tool                    | Purpose                | Speed  | Use When                     |
| ----------------------- | ---------------------- | ------ | ---------------------------- |
| `memory_search`         | Semantic vector search | ~500ms | Need meaning-based retrieval |
| `memory_load`           | Load memory content    | <10ms  | Know exact spec folder/ID    |
| `memory_match_triggers` | Fast phrase matching   | <50ms  | Quick keyword lookup first   |

### Essential Commands

```bash
# Verify installation
ls -la /path/to/semantic-memory/lib/
sqlite3 .opencode/memory/memory-index.sqlite ".tables"

# Test server
node /path/to/semantic-memory/semantic-memory.js

# Check database stats
sqlite3 .opencode/memory/memory-index.sqlite "SELECT COUNT(*) FROM memory_index"
```

### Configuration Quick Copy

**Claude Code (.mcp.json):**
```json
{
  "mcpServers": {
    "semantic_memory": {
      "command": "node",
      "args": ["/path/to/semantic-memory/semantic-memory.js"],
      "env": {},
      "disabled": false
    }
  }
}
```

**OpenCode (opencode.json):**
```json
{
  "mcp": {
    "semantic_memory": {
      "type": "local",
      "command": ["node", "/path/to/semantic-memory/semantic-memory.js"],
      "environment": {},
      "enabled": true
    }
  }
}
```

---

**Installation Complete!**

You now have the Semantic Memory MCP server installed and configured. Use it to retrieve conversation context, search memories semantically, and quickly match trigger phrases.

Start using Semantic Memory by asking your AI assistant:
```
Search my memories for information about [topic]
```

---

## Next Steps

- **Test the system**: Run `/save_context check` in Claude Code
- **Save your first context**: Type "save context" after a meaningful conversation
- **Search memories**: Try `/save_context how did we...`

**Need help?** See [Troubleshooting](#troubleshooting) or check Claude Code terminal for server logs.

---

**Version**: 10.0.0
**Protocol**: MCP (Model Context Protocol)
**Status**: Production Ready
