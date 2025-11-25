# Claude Code Commands - Semantic Codebase Indexing

Semantic code indexing and search commands for managing your codebase index. Search code by what it does, not just what it's called.

#### 📋 TABLE OF CONTENTS

1. [📖 OVERVIEW](#1--overview)
2. [⚡ AVAILABLE COMMANDS](#2--available-commands)
3. [🚀 QUICK START GUIDE](#3--quick-start-guide)
4. [🏗️ ARCHITECTURE](#4-️-architecture)
5. [💡 TIPS & BEST PRACTICES](#5--tips--best-practices)
6. [🔧 TROUBLESHOOTING](#6--troubleshooting)
7. [🔗 INTEGRATION](#7--integration)
8. [📊 COMMAND REFERENCE SUMMARY](#8--command-reference-summary)
9. [🆘 SUPPORT](#9--support)

---

## 1. 📖 OVERVIEW

This directory contains commands that provide a CLI interface to the semantic code indexing system.

### Capabilities
- ✅ Start/stop the indexing watcher process
- ✅ Search code using natural language queries
- ✅ View indexing statistics and status
- ✅ Index git commit history for temporal search
- ✅ Reset the index when needed

### Command Support Status

| Command | Status | Safety | Description |
|---------|--------|--------|-------------|
| `/index:stats` | ✅ WORKING | Read-only | Show indexing statistics |
| `/index:search` | ✅ WORKING | Read-only | Semantic code search |
| `/index:start` | ✅ WORKING | Non-destructive | Start file watcher |
| `/index:stop` | ✅ WORKING | Non-destructive | Stop file watcher |
| `/index:history` | ✅ WORKING | Adds data | Index git commits |
| `/index:reset` | ⚠️ DESTRUCTIVE | Requires confirmation | Delete all indexed data |

---

## 2. ⚡ AVAILABLE COMMANDS

### `/index:stats` - Show Statistics
Display current indexing statistics including tracked files, indexed commits, and watcher status.

```bash
/index:stats
```

**Use cases:**
- Check if indexer is running
- Verify how many files are indexed
- See collection ID
- Monitor indexing progress

**Safety:** ✅ Read-only, safe to run anytime

---

### `/index:search <query>` - Semantic Search
Search your codebase using natural language queries. Finds code based on what it does, not just keywords.

```bash
/index:search "authentication middleware"
/index:search "form validation logic" --refined
```

**Arguments:**
- `<query>` - Natural language description of what you're looking for
- `--refined` - (Optional) Enable LLM-based analysis for better insights

**Query tips:**
- Be specific: "how do we validate email inputs" > "validation"
- Use exact names if known: "HeroVideo component"
- Ask about functionality, not file names
- Combine concepts: "form submission and error handling"

**Safety:** ✅ Read-only, requires index to be populated

---

### `/index:start` - Start Indexer
Start the background file watcher process to index your codebase.

```bash
/index:start
```

**What it does:**
- Creates `.codebase/` directory if needed
- Initializes vector database
- Starts watching for file changes
- Performs initial indexing scan

**First run:** May take a few minutes depending on codebase size
**Subsequent runs:** Fast, only indexes changes

**Safety:** ✅ Non-destructive, safe to run

---

### `/index:stop` - Stop Indexer
Stop the background file watcher process cleanly.

```bash
/index:stop
```

**What it does:**
- Stops the file watcher process
- Preserves all indexed data
- Searches still work with existing index

**When to use:**
- Reduce system resource usage
- Before performing bulk file operations
- Switching to different workspace

**Safety:** ✅ Non-destructive, preserves indexed data

---

### `/index:history [count]` - Index Git History
Index recent git commits to enable temporal code understanding.

```bash
/index:history          # Index last 10 commits (default)
/index:history 50       # Index last 50 commits
/index:history 100      # Index last 100 commits
```

**What it does:**
- Processes recent git commits
- Indexes code changes over time
- Enables temporal search queries

**Use cases:**
- Understand code evolution
- Find when features were added
- Search for bug fixes and refactoring
- Historical context for current code

**Example temporal queries:**
- "when was authentication added"
- "how has the navigation menu changed"
- "evolution of form validation"

**Performance:**
- 10-20 commits: < 1 minute
- 50-100 commits: 2-5 minutes
- 500+ commits: 10+ minutes

**Safety:** ⚠️ Adds data to index, but non-destructive

---

### `/index:reset` - Full Reset (DESTRUCTIVE)
Delete all indexed data and start fresh.

```bash
/index:reset            # Prompts for confirmation
/index:reset --confirm  # Skip confirmation (use with caution)
```

**⚠️ WARNING: This is a DESTRUCTIVE operation!**

**What it deletes:**
- ❌ All semantic search vectors
- ❌ All indexed commit history
- ❌ All cached file metadata
- ✅ Source code files NOT affected

**When to use:**
- Index is corrupted
- Major codebase restructure
- Troubleshooting search quality
- Testing/development only

**After reset:**
1. Run `/index:start` to rebuild (may take time)
2. Use `/index:stats` to monitor progress
3. Run `/index:history` if temporal search needed
4. Test with `/index:search`

**Safety:** ⚠️ DESTRUCTIVE - Requires explicit confirmation

---

## 3. 🚀 QUICK START GUIDE

### Environment Setup (Required)

The `codesql` CLI requires embedder configuration. Ensure `.codebase/.env` exists with:

```bash
EMBED_BASE_URL=https://api.voyageai.com/v1
EMBED_API_KEY=<your-voyage-ai-api-key>
EMBED_MODEL=voyage-code-3
EMBED_DIMENSION=1024
```

**Important:** The slash commands automatically source this file. If running `codesql` manually:
```bash
set -a && source .codebase/.env && set +a && codesql -start
```

### First Time Setup

1. **Start the indexer:**
   ```bash
   /index:start
   ```
   Wait for initial scan to complete (check with `/index:stats`)

2. **(Optional) Index git history:**
   ```bash
   /index:history 50
   ```

3. **Test search:**
   ```bash
   /index:search "form validation"
   ```

### Daily Workflow

The indexer runs in the background and automatically updates as you code. You typically only need:

```bash
/index:search "<your query>"
```

Use `/index:stats` occasionally to verify status.

---

## 4. 🏗️ ARCHITECTURE

### Storage Structure
```
.codebase/
├── vectors.db       # SQLite vector database (~7MB)
├── cache.json       # File hash cache
├── state.json       # Workspace metadata
└── watcher.pid      # Process ID for watcher
```

### Technologies Used
- **Indexer:** `codesql` CLI tool (Node.js based)
- **Storage:** SQLite with sqlite-vec extension
- **Embeddings:** voyage-code-3 model via OpenAI-compatible API
- **MCP Server:** semantic-search for search functionality

### What Gets Indexed
- ✅ All code files in workspace
- ✅ Git commit history (optional)
- ❌ `node_modules/`, `.git/`, build artifacts
- ❌ Binary files
- Respects `.gitignore` patterns

---

## 5. 💡 TIPS & BEST PRACTICES

### Writing Good Queries
- ✅ **Good:** "how do we handle form submission errors"
- ❌ **Poor:** "errors"
- ✅ **Good:** "authentication middleware for protected routes"
- ❌ **Poor:** "auth"

### When to Use Refined Mode
Use `--refined` flag when:
- You need analysis of relevance
- Identifying key files vs boilerplate
- Finding missing references or imports
- More expensive but more insightful

### Managing Index Size
- Start with recent commits (10-50)
- Index more history as needed
- Monitor `.codebase/vectors.db` size
- Consider periodic resets for very active projects

### Performance Optimization
- Let indexer run in background
- Only stop when necessary
- Index history in batches
- Use specific queries to reduce result sets

---

## 6. 🔧 TROUBLESHOOTING

### "Unable to infer embedder provider" Error
- **Cause:** Environment variables not loaded
- **Fix:** Ensure `.codebase/.env` exists with valid `EMBED_*` variables
- The slash commands source this automatically, but manual `codesql` calls need:
  ```bash
  set -a && source .codebase/.env && set +a
  ```

### "Invalid API key" (401) Error
- **Cause:** API key in `.codebase/.env` is expired or invalid
- **Fix:** Get a new API key from Voyage AI dashboard and update `EMBED_API_KEY`
- Verify the key matches what's in `.utcp_config.json` (semantic_search MCP server)

### Indexer won't start
- Check `codesql` is in PATH
- Verify write permissions for `.codebase/`
- Check disk space

### Search returns no results
- Run `/index:stats` to verify files are indexed
- Wait for initial indexing to complete
- Try more specific queries
- Consider re-indexing with `/index:start`

### Slow indexing
- Large codebases take time on first run
- Subsequent runs are incremental and fast
- Use `/index:stats` to monitor progress

### Index corrupted
- Use `/index:reset` to start fresh (last resort)
- Backup important data first
- Re-index will take time

---

## 7. 🔗 INTEGRATION

### With MCP Server
These commands integrate with the semantic-search MCP server:
- Configuration: `.mcp.json`
- Server location: `/Users/michelkerkmeester/MEGA/MCP Servers/semantic-search/`
- Embedding provider: OpenAI-compatible (voyage-code-3)

**Note:** While `.vscode/mcp.json` exists for Code Mode integration, semantic search MCP tools are only available to CLI AI agents (Claude Code AI, GitHub Copilot CLI). IDE integrations like VS Code GitHub Copilot use different systems and cannot access these tools.

### With Git
- Automatically respects `.gitignore`
- Can index commit history
- Works with current branch
- No impact on git operations

---

## 8. 📊 COMMAND REFERENCE SUMMARY

| Command | Purpose | Safety | Time |
|---------|---------|--------|------|
| `/index:stats` | Show statistics | ✅ Safe | Instant |
| `/index:search` | Semantic search | ✅ Safe | Fast |
| `/index:start` | Start indexer | ✅ Safe | 1-5 min first run |
| `/index:stop` | Stop indexer | ✅ Safe | Instant |
| `/index:history` | Index commits | ⚠️ Adds data | 1-10 min |
| `/index:reset` | Delete index | ⚠️ Destructive | Instant |

---

## 9. 🆘 SUPPORT

For issues or questions:
- Check `/index:stats` for current status
- Review `.codebase/` directory
- Verify MCP server configuration in `.mcp.json`
- Check Claude Code logs for errors

---

## 10. 📜 VERSION HISTORY

**Current Version**: 1.0.0
**Last Updated**: 2025-11-11

### v1.0.0 (2025-11-11) - Initial Release
- ✅ Created semantic code indexing command suite
- ✅ Implemented `/index:start` for watcher initialization
- ✅ Implemented `/index:stop` for clean shutdown
- ✅ Implemented `/index:stats` for statistics display
- ✅ Implemented `/index:search` for semantic queries
- ✅ Implemented `/index:history` for git commit indexing
- ✅ Implemented `/index:reset` for destructive reset
- ✅ Aligned documentation with hooks/skills README format
- ✅ Added comprehensive troubleshooting guides
- ✅ Added integration documentation

---

## 11. 🔗 RELATED DOCUMENTATION

- [Semantic Search MCP Server](https://github.com/yourorg/semantic-search-mcp)
- [codesql CLI Documentation](https://github.com/yourorg/codesql)
- [Claude Code Documentation](https://code.claude.com/docs/)
- [SQLite Vec Extension](https://github.com/asg017/sqlite-vec)

---

**Created:** November 11, 2025
**Location:** `.claude/commands/code-indexing/`
**Total Commands:** 6
