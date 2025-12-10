# Mnemo MCP Server Installation Guide

A comprehensive guide to installing and configuring the Mnemo MCP server for extended AI memory via Gemini context caching. Load and query GitHub repositories, documentation sites, PDFs, and JSON APIs.

---

## 🤖 AI-FIRST INSTALL GUIDE

### Verify Success (60 seconds)

After installation, test immediately:
1. Open Claude Code in a configured project
2. Run: `mcp__mnemo__context_list({})`
3. See empty array or cache list = SUCCESS

Not working? Jump to [Troubleshooting](#8--troubleshooting).

---

> **Related Documentation:**
> - [SKILL.md](./SKILL.md) - Complete skill documentation and workflows
> - [query_examples.md](./assets/query_examples.md) - Categorized usage examples
> - [Mnemo Repository](https://github.com/Logos-Flux/mnemo) - Official source

---

**Copy and paste this prompt to your AI assistant to get installation help:**

```
I want to install the Mnemo MCP server for extended AI memory via Gemini context caching.

Please help me:
1. Check if I have Bun runtime installed
2. Clone the Mnemo repository
3. Install dependencies with bun install
4. Configure GEMINI_API_KEY environment variable
5. Configure for my AI environment (I'm using: [Claude Code / OpenCode])
6. Test the installation with context_list

My project path is: [your-project-path]
My MCP Servers directory is: [your-mcp-servers-path]

Guide me through each step with the exact commands and configuration needed.
```

**What the AI will do:**
- Verify Bun runtime is installed (1.0+)
- Clone Mnemo repository to your MCP Servers directory
- Install dependencies with bun install
- Help you obtain and configure Gemini API key
- Configure MCP settings for your platform
- Test all tools: `context_load`, `context_query`, `context_list`

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

Mnemo (Greek: memory) extends AI memory through Gemini context caching, enabling natural language queries across large codebases, documentation, PDFs, and external sources without complex RAG pipelines.

### Key Features

- **Perfect Recall**: No chunking or retrieval means no lost context
- **Lower Latency**: Cached context served quickly from Gemini
- **Cost Savings**: Cached tokens cost 75-90% less than regular input
- **Simplicity**: No vector databases, embeddings, or complex retrieval logic
- **Multi-Source**: GitHub repos, URLs, PDFs, JSON APIs, local directories

### What Can Mnemo Load?

| Source Type | Supported | Notes |
|-------------|-----------|-------|
| GitHub repos (public) | ✅ | Full codebase loading |
| GitHub repos (private) | ✅ | Requires `githubToken` |
| Any URL (docs, articles) | ✅ | HTML, text, JSON |
| PDF documents | ✅ | Local or remote |
| JSON APIs | ✅ | Direct URL loading |
| Local files/directories | ✅ | Full path required |

### Tool Selection Flowchart

```
User Request
     │
     ▼
┌─────────────────────────────────────────┐
│ Is content EXTERNAL (GitHub, URL, PDF)? │
└────────────────┬────────────────────────┘
                 │
         ┌───────┴───────┐
         │               │
        YES              NO
         │               │
         ▼               ▼
┌─────────────────┐  ┌────────────────────┐
│ Use Mnemo       │  │ Is it LOCAL code   │
│ context_load    │  │ discovery?         │
│ context_query   │  └─────────┬──────────┘
└─────────────────┘            │
                       ┌───────┴───────┐
                      YES              NO
                       │               │
                       ▼               ▼
               ┌──────────────┐  ┌────────────────┐
               │ Use Semantic │  │ Know exact     │
               │ Search MCP   │  │ file path?     │
               │              │  └─────────┬──────┘
               └──────────────┘            │
                                   ┌───────┴───────┐
                                  YES              NO
                                   │               │
                                   ▼               ▼
                           ┌────────────┐  ┌────────────┐
                           │ Use Read   │  │ Use Grep   │
                           │ tool       │  │ or Glob    │
                           └────────────┘  └────────────┘
```

### Architecture Overview

```
┌─────────────────────────────────────────────────────────────┐
│                    AI Client (Claude/OpenCode)              │
└─────────────────────────────┬───────────────────────────────┘
                              │ stdio
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                    Mnemo MCP Server                          │
│                    (Bun + TypeScript)                        │
├─────────────────────────────────────────────────────────────┤
│  MCP Tools                                                   │
│  • context_load    - Load sources into Gemini cache         │
│  • context_query   - Query cached content                   │
│  • context_list    - Show active caches                     │
│  • context_evict   - Remove cache                           │
│  • context_stats   - Token usage, costs                     │
│  • context_refresh - Reload cache with fresh content        │
├─────────────────────────────────────────────────────────────┤
│  Adapters                                                    │
│  • GitHub repos (via API)                                   │
│  • URL loading (HTML, PDF, JSON, text)                      │
│  • Token-targeted crawling                                  │
│  • robots.txt compliance                                    │
└─────────────────────────────┬───────────────────────────────┘
                              │ HTTPS
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                    Gemini API                                │
│                    (Context Caching)                         │
│  • 1M token context window                                  │
│  • 75-90% discount on cached tokens                         │
│  • TTL-based cache management                               │
└─────────────────────────────────────────────────────────────┘
```

### Performance Targets

| Operation | Target | Typical |
|-----------|--------|---------|
| Cache creation | <30s | ~10-20s (depends on source size) |
| Query response | <5s | ~2-4s |
| Context list | <100ms | ~50ms |
| Cache eviction | <100ms | ~50ms |

### Cost Structure

| Resource | Cost |
|----------|------|
| Cache storage | ~$4.50 per 1M tokens per hour |
| Cached input | 75-90% discount vs regular input |
| Regular input | ~$0.075 per 1M tokens (Flash) |

**Example:** 100K token codebase cached for 1 hour with 10 queries ≈ $0.47

---

## 2. 📋 PREREQUISITES

Before installing Mnemo, ensure you have:

### Required

- **Bun 1.0 or higher** (TypeScript runtime)
  ```bash
  bun --version
  # Should show 1.0.x or higher

  # Install if needed (macOS/Linux):
  curl -fsSL https://bun.sh/install | bash
  ```

- **Gemini API Key**
  1. Go to [Google AI Studio](https://aistudio.google.com/apikey)
  2. Create or sign in to your Google account
  3. Generate an API key
  4. Keep it secure - you'll need it for configuration

- **MCP-Compatible Client** (one of the following):
  - Claude Code CLI
  - OpenCode CLI

### Platform Support

| Platform | Status | Notes |
|----------|--------|-------|
| **macOS** | Native support | Recommended |
| **Linux** | Native support | Tested on Ubuntu, Debian |
| **Windows** | WSL recommended | Native support may work |

### Common Setup Gotchas

**Bun not found:**
- Restart terminal after installation
- Check `~/.bun/bin` is in PATH
- Try: `source ~/.bashrc` or `source ~/.zshrc`

**Gemini API key issues:**
- Ensure key has Gemini API access enabled
- Check for billing/quota limits
- Verify key is correctly copied (no extra spaces)

**Permission errors:**
- Run `chmod +x` on scripts if needed
- Ensure directory has write permissions

---

## 3. 📥 INSTALLATION

### Step 1: Create MCP Servers Directory

```bash
# Create directory for MCP servers (if not exists)
mkdir -p "/Users/USERNAME/path/to/mcp-servers"
cd "/Users/USERNAME/path/to/mcp-servers"
```

### Step 2: Clone Mnemo Repository

```bash
# Clone the official repository
git clone https://github.com/Logos-Flux/mnemo
cd mnemo
```

### Step 3: Install Dependencies

```bash
# Install with Bun
bun install
```

### Step 4: Set Gemini API Key

```bash
# Set environment variable (temporary for testing)
export GEMINI_API_KEY="your-gemini-api-key-here"

# Add to shell profile for persistence
echo 'export GEMINI_API_KEY="your-gemini-api-key-here"' >> ~/.zshrc
source ~/.zshrc
```

### Step 5: Verify Installation

```bash
# Test server startup (stdio mode for MCP)
bun run packages/local/src/stdio.ts

# Expected: No errors, server waits for MCP protocol input
# Press Ctrl+C to exit
```

### Step 6: Test HTTP Mode (Optional)

```bash
# Start HTTP server for direct testing
bun run dev

# In another terminal, test health endpoint
curl http://localhost:8080/health
# Expected: {"status":"ok"}
```

---

## 4. ⚙️ CONFIGURATION

### Option A: Configure for Claude Code CLI

Add to `.mcp.json` in your project root:

```json
{
  "mcpServers": {
    "mnemo": {
      "command": "/Users/YOUR_NAME/.bun/bin/bun",
      "args": [
        "run",
        "/Users/YOUR_NAME/MEGA/MCP Servers/mnemo/packages/local/src/stdio.ts"
      ],
      "env": {
        "GEMINI_API_KEY": "your-gemini-api-key-here",
        "MNEMO_PORT": "8080",
        "MNEMO_DIR": "~/.mnemo"
      },
      "disabled": false
    }
  }
}
```

**Important:** Replace paths with your actual paths:
- Find Bun path: `which bun`
- Find Mnemo path: `ls /path/to/MCP\ Servers/mnemo`

### Option B: Configure for OpenCode

Add to `opencode.json` in your project root:

```json
{
  "mcp": {
    "mnemo": {
      "type": "local",
      "command": [
        "/Users/YOUR_NAME/.bun/bin/bun",
        "run",
        "/Users/YOUR_NAME/MEGA/MCP Servers/mnemo/packages/local/src/stdio.ts"
      ],
      "environment": {
        "GEMINI_API_KEY": "your-gemini-api-key-here",
        "MNEMO_PORT": "8080",
        "MNEMO_DIR": "~/.mnemo"
      },
      "enabled": true
    }
  }
}
```

### Environment Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `GEMINI_API_KEY` | Your Gemini API key | **Required** |
| `MNEMO_PORT` | HTTP server port (local only) | 8080 |
| `MNEMO_DIR` | Data directory (local only) | ~/.mnemo |
| `MNEMO_AUTH_TOKEN` | Auth token for protected endpoints | None |

---

## 5. ✅ VERIFICATION

### One-Command Health Check

```bash
# Verify Bun installation
bun --version && echo "Bun: OK"

# Verify Gemini API key is set
[ -n "$GEMINI_API_KEY" ] && echo "GEMINI_API_KEY: SET" || echo "GEMINI_API_KEY: NOT SET"

# Test server startup
timeout 5 bun run /path/to/mnemo/packages/local/src/stdio.ts 2>&1 || echo "Server: OK (timeout expected)"
```

### Check 1: Verify Installation Files

```bash
# Check mnemo directory structure
ls -la /path/to/mnemo/
# Should show: packages/, bun.lock, package.json, README.md

ls -la /path/to/mnemo/packages/local/src/
# Should show: index.ts, stdio.ts
```

### Check 2: Verify Bun and Dependencies

```bash
# Check Bun version
bun --version
# Should show: 1.x.x

# Check dependencies installed
ls /path/to/mnemo/node_modules/
# Should show: @google, etc.
```

### Check 3: Test Server Startup

```bash
# Start server manually (will wait for MCP protocol input)
cd /path/to/mnemo
bun run packages/local/src/stdio.ts

# Expected: No errors, server waits for input
# Press Ctrl+C to exit
```

### Check 4: Verify in Your AI Client

**In Claude Code:**
```bash
# Start Claude Code session
claude

# List active caches
> List my mnemo caches

# Expected: AI calls context_list, returns empty array or cache list
```

**In OpenCode:**
```bash
opencode

> List available mnemo tools

# Expected: Tools should appear: context_load, context_query, etc.
```

### Check 5: Test Load and Query

```bash
# In Claude Code or OpenCode, ask:
> Load the Hono framework repository and tell me about its routing system

# Expected:
# 1. AI calls context_load with github.com/honojs/hono
# 2. AI calls context_query with routing question
# 3. Returns detailed response about Hono routing
```

---

## 6. 🚀 USAGE

### Pattern 1: GitHub Repository Analysis

**Goal:** Understand an unfamiliar open-source library

```javascript
// Load the repository
context_load({
  source: "https://github.com/honojs/hono",
  alias: "hono",
  ttl: 7200,
  systemInstruction: "You are an expert on this web framework"
})

// Query architecture
context_query({
  alias: "hono",
  query: "What's the routing architecture? How do middleware work?"
})

// Evict when done
context_evict({ alias: "hono" })
```

### Pattern 2: Documentation Cross-Reference

**Goal:** Learn a new framework from official docs

```javascript
// Load multiple doc sections
context_load({
  sources: [
    "https://react.dev/learn",
    "https://react.dev/reference"
  ],
  alias: "react-docs",
  ttl: 86400
})

// Query for specific guidance
context_query({
  alias: "react-docs",
  query: "When should I use useCallback vs useMemo? Give examples."
})
```

### Pattern 3: PDF Analysis

**Goal:** Extract insights from technical papers

```javascript
// Load PDF (local or remote)
context_load({
  source: "https://example.com/research-paper.pdf",
  alias: "paper",
  ttl: 3600
})

// Query content
context_query({
  alias: "paper",
  query: "What methodology did they use? What were the key findings?"
})
```

### Pattern 4: Private Repository Analysis

**Goal:** Analyze internal company codebase

```javascript
// Load private repo with token
context_load({
  source: "https://github.com/company/private-repo",
  alias: "internal",
  ttl: 3600,
  githubToken: "ghp_your_github_token"
})

// Query implementation
context_query({
  alias: "internal",
  query: "How is authentication implemented?"
})
```

### Pattern 5: Multi-Framework Comparison

**Goal:** Compare how different frameworks solve the same problem

```javascript
// Load multiple frameworks
context_load({
  sources: [
    "https://github.com/expressjs/express",
    "https://github.com/honojs/hono",
    "https://github.com/fastify/fastify"
  ],
  alias: "node-frameworks",
  ttl: 14400
})

// Comparative query
context_query({
  alias: "node-frameworks",
  query: "Compare how each framework handles middleware composition"
})
```

### Tool Selection Guide

| Scenario | Tool | Why |
|----------|------|-----|
| Analyze GitHub repo | Mnemo `context_load` | Full codebase context |
| Query loaded content | Mnemo `context_query` | Natural language Q&A |
| Local project search | Semantic Search MCP | Real-time, no API cost |
| Known file path | `Read` tool | Direct, fastest |
| Pattern search | `Grep` tool | Exact matching |
| File discovery | `Glob` tool | Pattern-based |

---

## 7. 🎯 FEATURES

### 7.1 context_load

**Purpose**: Load sources into Gemini context cache for querying.

**Parameters**:

| Parameter | Type | Required | Default | Description |
|-----------|------|----------|---------|-------------|
| `source` | string | Yes* | - | Single source URL or path |
| `sources` | string[] | Yes* | - | Multiple sources (array) |
| `alias` | string | Yes | - | Cache identifier (1-64 chars) |
| `ttl` | number | No | 3600 | Time to live in seconds (60-86400) |
| `systemInstruction` | string | No | - | System prompt for queries |
| `githubToken` | string | No | - | Token for private repos |

*Either `source` or `sources` required, not both.

**Example Request**:
```json
{
  "source": "https://github.com/honojs/hono",
  "alias": "hono",
  "ttl": 7200,
  "systemInstruction": "You are an expert on this framework"
}
```

### 7.2 context_query

**Purpose**: Query cached content with natural language.

**Parameters**:

| Parameter | Type | Required | Default | Description |
|-----------|------|----------|---------|-------------|
| `alias` | string | Yes | - | Cache alias to query |
| `query` | string | Yes | - | Natural language question |
| `maxTokens` | number | No | - | Max response tokens |
| `temperature` | number | No | - | Response randomness (0-2) |

**Example Request**:
```json
{
  "alias": "hono",
  "query": "How do I add middleware for authentication?",
  "maxTokens": 2048
}
```

### 7.3 context_list

**Purpose**: List all active context caches with metadata.

**Parameters**: None required.

**Example Response**:
```json
[
  {
    "alias": "hono",
    "tokens": 150000,
    "expires": "2024-01-15T14:00:00Z"
  },
  {
    "alias": "react-docs",
    "tokens": 500000,
    "expires": "2024-01-16T12:00:00Z"
  }
]
```

### 7.4 context_stats

**Purpose**: Get usage statistics with cost tracking.

**Parameters**:

| Parameter | Type | Required | Default | Description |
|-----------|------|----------|---------|-------------|
| `alias` | string | No | - | Specific cache (omit for global) |

**Example Response**:
```json
{
  "alias": "hono",
  "tokens": 150000,
  "queries": 15,
  "estimatedCost": "$0.23",
  "cacheHitRate": 0.95
}
```

### 7.5 context_refresh

**Purpose**: Refresh cache with fresh content (e.g., after repo updates).

**Parameters**:

| Parameter | Type | Required | Default | Description |
|-----------|------|----------|---------|-------------|
| `alias` | string | Yes | - | Cache alias to refresh |
| `ttl` | number | No | - | New TTL (optional) |
| `systemInstruction` | string | No | - | New system instruction |
| `githubToken` | string | No | - | Token for private repos |

**Example Request**:
```json
{
  "alias": "docs",
  "ttl": 7200
}
```

### 7.6 context_evict

**Purpose**: Remove a cache to stop billing and free resources.

**Parameters**:

| Parameter | Type | Required | Default | Description |
|-----------|------|----------|---------|-------------|
| `alias` | string | Yes | - | Cache alias to evict |

**Example Request**:
```json
{
  "alias": "old-project"
}
```

---

## 8. 🔧 TROUBLESHOOTING

### Server Won't Start

**Problem**: `Error: Cannot find module` or Bun not found

**What it means**: Bun runtime not installed or not in PATH.

**Fix**:
```bash
# Check Bun installation
bun --version

# If not found, install Bun
curl -fsSL https://bun.sh/install | bash

# Reload shell
source ~/.zshrc  # or ~/.bashrc

# Verify
which bun
```

### GEMINI_API_KEY Not Set

**Problem**: `Error: GEMINI_API_KEY environment variable is required`

**What it means**: The Gemini API key is not configured.

**Fix**:
```bash
# Check if set
echo $GEMINI_API_KEY

# Set temporarily
export GEMINI_API_KEY="your-key-here"

# Set permanently
echo 'export GEMINI_API_KEY="your-key-here"' >> ~/.zshrc
source ~/.zshrc
```

### Cache Creation Fails

**Problem**: `Error: Failed to create cache`

**What it means**: Source URL inaccessible or token count too low.

**Fix**:
```bash
# Verify source URL is accessible
curl -I https://github.com/owner/repo

# For private repos, verify token
curl -H "Authorization: token YOUR_TOKEN" https://api.github.com/repos/owner/repo

# Check minimum tokens (1,024 for Flash, 4,096 for Pro)
# Smaller sources may fail - combine with other sources
```

### Query Returns Poor Results

**Problem**: Vague or incorrect responses from `context_query`

**What it means**: Query too broad or cache content not relevant.

**Fix**:
1. Use more specific queries with context:
   ```
   ❌ "How does routing work?"
   ✅ "How does the middleware routing pipeline work in the Router class?"
   ```

2. Add systemInstruction during context_load:
   ```javascript
   context_load({
     source: "...",
     alias: "project",
     systemInstruction: "You are an expert on this authentication library"
   })
   ```

3. Verify cache loaded successfully with `context_list`

### Tool Not Appearing in Client

**Problem**: Mnemo tools not listed in AI client

**What it means**: MCP configuration not being read or syntax error.

**Fix**:
```bash
# Check for JSON syntax errors in .mcp.json
python3 -m json.tool < .mcp.json

# Verify paths are absolute (not relative)
# Check Bun path: which bun
# Check Mnemo path exists

# For Claude Code: restart session
# For OpenCode: restart application
```

### High Costs

**Problem**: Unexpected Gemini API charges

**What it means**: Forgotten caches still incurring storage costs.

**Fix**:
```bash
# In AI client, list all caches
> List all my mnemo caches

# Evict unused caches
> Evict the old-project cache

# Set shorter TTLs for temporary analysis
context_load({ source: "...", alias: "temp", ttl: 600 })  # 10 minutes
```

### Rate Limiting

**Problem**: `Error: Rate limit exceeded`

**What it means**: Too many requests to Gemini API.

**Fix**:
- Wait a few minutes and retry
- Reduce query frequency
- Use longer TTLs to reduce cache recreations
- Check Gemini API quota in Google Cloud Console

---

## 9. 📚 RESOURCES

### File Structure

```
mnemo/
├── packages/
│   ├── local/
│   │   └── src/
│   │       ├── index.ts      # HTTP server entry point
│   │       └── stdio.ts      # MCP stdio entry point
│   ├── core/                 # Gemini client, loaders, adapters
│   ├── mcp-server/           # MCP protocol handling
│   └── cf-worker/            # Cloudflare Workers deployment
├── docs/                     # Additional documentation
├── node_modules/             # Dependencies
├── package.json              # Package manifest
├── bun.lock                  # Bun lockfile
└── README.md                 # Official documentation
```

### Configuration Paths

| Client | Configuration File | Server Key |
|--------|-------------------|------------|
| **Claude Code** | `.mcp.json` | `mnemo` |
| **OpenCode** | `opencode.json` | `mnemo` |

### Verification Commands

```bash
# Check Bun version
bun --version

# Check Gemini API key
echo $GEMINI_API_KEY | head -c 10
# Should show first 10 chars of key

# Test server (HTTP mode)
cd /path/to/mnemo && bun run dev &
curl http://localhost:8080/health
# Expected: {"status":"ok"}

# List available tools
curl http://localhost:8080/tools
```

### Source Type Formats

| Source Type | Format | Example |
|-------------|--------|---------|
| GitHub repo | `https://github.com/owner/repo` | `github.com/facebook/react` |
| GitHub branch | `https://github.com/owner/repo@branch` | `github.com/vercel/next.js@canary` |
| GitHub tag | `https://github.com/owner/repo@v1.0.0` | `github.com/honojs/hono@v4.0.0` |
| URL | `https://example.com/page` | `https://react.dev/learn` |
| PDF (local) | `/path/to/file.pdf` | `/docs/spec.pdf` |
| PDF (remote) | `https://example.com/doc.pdf` | `https://arxiv.org/pdf/...` |
| Local dir | `/path/to/directory` | `/projects/my-app` |
| JSON API | `https://api.example.com/endpoint` | `https://api.github.com/...` |

### Related Documentation

| Document | Location | Purpose |
|----------|----------|---------|
| SKILL.md | `./SKILL.md` | Complete workflow documentation |
| Query Examples | `./assets/query_examples.md` | Categorized usage patterns |
| Mnemo README | Repository root | Official documentation |
| Gemini Caching | [Google AI Docs](https://ai.google.dev/gemini-api/docs/caching) | Context caching guide |

---

## ⚡ Quick Reference

### Tool Summary

| Tool | Purpose | Speed | Use When |
|------|---------|-------|----------|
| `context_load` | Load sources | ~10-20s | Need external content |
| `context_query` | Query cache | ~2-4s | Natural language Q&A |
| `context_list` | List caches | <100ms | Check active caches |
| `context_stats` | Usage stats | <100ms | Monitor costs |
| `context_refresh` | Refresh cache | ~10-20s | Content updated |
| `context_evict` | Remove cache | <100ms | Done with analysis |

### Essential Commands

```javascript
// Load GitHub repo
context_load({
  source: "https://github.com/owner/repo",
  alias: "project",
  ttl: 3600
})

// Query loaded content
context_query({
  alias: "project",
  query: "How does authentication work?"
})

// List all caches
context_list({})

// Check usage
context_stats({ alias: "project" })

// Refresh stale cache
context_refresh({ alias: "project", ttl: 7200 })

// Clean up
context_evict({ alias: "project" })
```

### Configuration Quick Copy

**Claude Code (.mcp.json):**
```json
{
  "mcpServers": {
    "mnemo": {
      "command": "/Users/YOUR_NAME/.bun/bin/bun",
      "args": [
        "run",
        "/Users/YOUR_NAME/MEGA/MCP Servers/mnemo/packages/local/src/stdio.ts"
      ],
      "env": {
        "GEMINI_API_KEY": "your-gemini-api-key-here",
        "MNEMO_PORT": "8080",
        "MNEMO_DIR": "~/.mnemo"
      },
      "disabled": false
    }
  }
}
```

**OpenCode (opencode.json):**
```json
{
  "mcp": {
    "mnemo": {
      "type": "local",
      "command": [
        "/Users/YOUR_NAME/.bun/bin/bun",
        "run",
        "/Users/YOUR_NAME/MEGA/MCP Servers/mnemo/packages/local/src/stdio.ts"
      ],
      "environment": {
        "GEMINI_API_KEY": "your-gemini-api-key-here"
      },
      "enabled": true
    }
  }
}
```

---

**Installation Complete!**

You now have Mnemo MCP installed and configured. Use it to load and query GitHub repositories, documentation sites, PDFs, and other external content.

Start using Mnemo by asking your AI assistant:
```
Load the React repository and explain how hooks work
```

---

## Next Steps

- **Test the system**: Run `context_list` to verify connection
- **Load your first repo**: Try `context_load` with a small public repository
- **Read SKILL.md**: For complete workflow patterns
- **Monitor costs**: Use `context_stats` to track usage

**Need help?** See [Troubleshooting](#8--troubleshooting) or check the [Mnemo Repository](https://github.com/Logos-Flux/mnemo) for issues.

---

**Version**: 1.0.0
**Protocol**: MCP (Model Context Protocol)
**Backend**: Gemini Context Caching
**Status**: Production Ready
