---
description: Extended AI memory via Gemini context caching - load and query external content (GitHub repos, docs, PDFs)
argument-hint: "[action|query] [source/alias] [options]"
allowed-tools: Read, Bash, AskUserQuestion, mcp__mnemo__context_load, mcp__mnemo__context_query, mcp__mnemo__context_list, mcp__mnemo__context_stats, mcp__mnemo__context_evict, mcp__mnemo__context_refresh
---

# Offload Context

Offload large external content to Gemini context caching. Query GitHub repos, documentation, PDFs without consuming conversation context.

---

## 1. 📋 ARGUMENT DISPATCH

```
$ARGUMENTS
    │
    ├─► Empty (no args)
    │   └─► INTERACTIVE MODE: Run context_list(), then AskUserQuestion
    │
    ├─► First word matches ACTION KEYWORD (case-insensitive)
    │   ├─► "load" | "add" | "cache"       → LOAD ACTION (remaining args = source + alias)
    │   ├─► "query" | "ask" | "search"     → QUERY ACTION (remaining args = alias + query)
    │   ├─► "list" | "ls" | "show"         → LIST ACTION (show all caches)
    │   ├─► "stats" | "usage" | "cost"     → STATS ACTION (remaining args = alias)
    │   ├─► "refresh" | "update"           → REFRESH ACTION (remaining args = alias)
    │   ├─► "evict" | "remove" | "delete"  → EVICT ACTION (remaining args = alias)
    │   └─► "help" | "examples"            → HELP ACTION (show examples)
    │
    └─► No keyword match
        └─► INTERACTIVE MODE (assume user wants guided flow)
```

---

## 2. 📝 CONTRACT

**Inputs:** `$ARGUMENTS` — Optional action keyword with source/alias/query

**Outputs:**
- Success: `STATUS=OK ACTION=<action> [ALIAS=<alias>] [DATA=<value>]`
- Failure: `STATUS=FAIL ERROR="<message>"`
- Cancelled: `STATUS=CANCELLED ACTION=cancelled`

---

## 3. 🔀 INTERACTIVE MODE

When `$ARGUMENTS` is empty or no keyword match, execute this guided flow:

### Step 1: Check Current State

Run `mcp__mnemo__context_list()` silently to check for existing caches.

### Step 2: Present Options

**If NO caches exist**, use AskUserQuestion:

```
question: "What would you like to do with Offload Context?"
header: "Action"
options:
  - label: "Load external content"
    description: "Cache a GitHub repo, documentation URL, or PDF for querying"
  - label: "Show examples"
    description: "See example workflows and use cases"
```

**If caches EXIST**, use AskUserQuestion:

```
question: "You have [N] active cache(s). What would you like to do?"
header: "Action"
options:
  - label: "Query a cache"
    description: "Ask questions about cached content"
  - label: "Load new content"
    description: "Add another source to cache"
  - label: "Manage caches"
    description: "View stats, refresh, or remove caches"
```

### Step 3: Follow-up Questions

**For LOAD selection:**

```
question: "What type of content?"
header: "Source"
options:
  - label: "GitHub repository"
    description: "Full repo or specific branch/tag"
  - label: "Documentation URL"
    description: "Web pages, API docs, guides"
  - label: "PDF document"
    description: "Local or remote PDF files"
  - label: "Local directory"
    description: "A folder on your machine"
```

Then prompt for URL/path (via "Other" free text), then prompt for alias.

**For QUERY selection:**

If multiple caches, ask which one first. Then ask for the query text.

**For MANAGE selection:**

```
question: "What management action?"
header: "Manage"
options:
  - label: "View usage stats"
    description: "See token counts and costs"
  - label: "Refresh cache"
    description: "Re-fetch source content"
  - label: "Remove cache"
    description: "Delete and stop billing"
```

---

## 4. ⚡ ACTION HANDLERS

### LOAD ACTION

Execute:
```javascript
mcp__mnemo__context_load({
  source: "<source-url-or-path>",
  alias: "<alias>",
  ttl: 3600
})
```

Return: `STATUS=OK ACTION=load ALIAS=<alias>`

### QUERY ACTION

Execute:
```javascript
mcp__mnemo__context_query({
  alias: "<alias>",
  query: "<query-text>"
})
```

Return: `STATUS=OK ACTION=query ALIAS=<alias>`

### LIST ACTION

Execute:
```javascript
mcp__mnemo__context_list()
```

Return: `STATUS=OK ACTION=list DATA=<cache-list>`

### STATS ACTION

Execute:
```javascript
mcp__mnemo__context_stats({ alias: "<alias>" })
```

Return: `STATUS=OK ACTION=stats ALIAS=<alias>`

### REFRESH ACTION

Execute:
```javascript
mcp__mnemo__context_refresh({ alias: "<alias>" })
```

Return: `STATUS=OK ACTION=refresh ALIAS=<alias>`

### EVICT ACTION

Execute:
```javascript
mcp__mnemo__context_evict({ alias: "<alias>" })
```

Return: `STATUS=OK ACTION=evict ALIAS=<alias>`

---

## 5. 📊 EXAMPLE ROUTING

| Input | Detected As | Action |
|-------|-------------|--------|
| (empty) | No args | INTERACTIVE MODE |
| `list` | Keyword | LIST ACTION |
| `load https://github.com/vercel/next.js nextjs` | Keyword + args | LOAD ACTION |
| `query nextjs "How does routing work?"` | Keyword + args | QUERY ACTION |
| `stats nextjs` | Keyword + args | STATS ACTION |
| `evict nextjs` | Keyword + args | EVICT ACTION |
| `how does routing work` | No keyword match | INTERACTIVE MODE |

---

## 6. 🔍 EXAMPLE USAGE

### Direct Commands (Power Users)

```bash
# Load a GitHub repo
/offload-context load https://github.com/honojs/hono hono

# Query cached content
/offload-context query hono "How does the middleware system work?"

# List all caches
/offload-context list

# Check usage stats
/offload-context stats hono

# Remove cache (stop billing)
/offload-context evict hono
```

### Interactive Flow (Guided)

```bash
# Start interactive mode
/offload-context
```

---

## 7. 📁 SUPPORTED SOURCES

| Type | Format | Example |
|------|--------|---------|
| GitHub repo | `https://github.com/owner/repo` | `github.com/vercel/next.js` |
| GitHub tag | `https://github.com/owner/repo@tag` | `github.com/vercel/next.js@v14` |
| GitHub branch | `https://github.com/owner/repo@branch` | `github.com/vercel/next.js@canary` |
| URL | `https://example.com/page` | `https://react.dev/learn` |
| PDF (remote) | `https://example.com/doc.pdf` | `https://arxiv.org/pdf/...` |
| PDF (local) | `/path/to/file.pdf` | `/docs/spec.pdf` |
| Local dir | `/path/to/directory` | `/projects/my-app` |

---

## 8. 🎯 DECISION MATRIX

```
NEED external content (GitHub, URLs, PDFs)?
    → Use /offload-context

NEED local codebase by INTENT (what code does)?
    → Use mcp__semantic_search__semantic_search

NEED conversation memory (past discussions)?
    → Use mcp__semantic_memory__memory_search

KNOW exact file path?
    → Use Read tool

KNOW exact symbol/pattern?
    → Use Grep tool
```

---

## 9. 🔗 RELATED RESOURCES

- **Full Skill:** `.opencode/skills/mcp-mnemo/SKILL.md`
- **Semantic Search:** `.opencode/skills/mcp-semantic-search/SKILL.md`
- **Semantic Memory:** `.opencode/skills/workflows-memory/SKILL.md`
