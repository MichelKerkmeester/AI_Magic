# 📚 Mnemo Query Examples - Categorized Usage Patterns

Practical examples for using mnemo's extended AI memory via Gemini context caching. Use these patterns when loading and querying external content (GitHub repos, documentation URLs, PDFs, JSON APIs).

---

## 1. 🐙 LOADING GITHUB REPOSITORIES

**Purpose**: Load entire codebases into Gemini's context cache for natural language querying about architecture, patterns, and implementation details.

**Key Points**:
- Supports public and private repositories (with token)
- Can target specific branches or tags
- TTL controls cache duration (60-86400 seconds)
- Use `systemInstruction` for expert-level responses

### Example: Load Popular Open-Source Library

**Goal**: Understand React's internal architecture

**Template**:
```javascript
context_load({
  source: "https://github.com/[owner]/[repo]",
  alias: "[short-name]",
  ttl: 7200,
  systemInstruction: "You are an expert on [framework/library]"
})
```

**Complete Example**:
```javascript
// Load React codebase
context_load({
  source: "https://github.com/facebook/react",
  alias: "react",
  ttl: 7200,
  systemInstruction: "You are an expert on React internals"
})

// Query architecture
context_query({
  alias: "react",
  query: "How does the fiber reconciliation algorithm work?"
})
```

**Why it works**: Full codebase loaded enables deep architectural queries without local cloning.

### Example: Load Specific Branch or Tag

**Goal**: Analyze a specific version of a framework

**Complete Example**:
```javascript
// Load Next.js v14 specifically
context_load({
  source: "https://github.com/vercel/next.js@v14.0.0",
  alias: "nextjs-14",
  ttl: 86400
})

// Query version-specific features
context_query({
  alias: "nextjs-14",
  query: "What are the new App Router features in v14?"
})
```

**Why it works**: Tag specification (`@v14.0.0`) loads exact version for accurate analysis.

### Example: Load Private Repository

**Goal**: Analyze internal company codebase

**Complete Example**:
```javascript
// Load private repo with token
context_load({
  source: "https://github.com/company/private-repo",
  alias: "internal",
  ttl: 3600,
  githubToken: process.env.GITHUB_TOKEN
})

// Query implementation details
context_query({
  alias: "internal",
  query: "How is authentication implemented?"
})
```

**Why it works**: GitHub token enables private repository access securely.

---

## 2. 🌐 LOADING DOCUMENTATION URLS

**Purpose**: Index entire documentation websites for comprehensive Q&A about frameworks, APIs, and libraries.

**Key Points**:
- Supports multiple URLs in single cache (use `sources` array)
- Good for cross-referencing related docs
- Higher TTL recommended for stable docs (86400 = 24h)

### Example: Load Framework Documentation

**Goal**: Learn React from official docs

**Template**:
```javascript
context_load({
  sources: [
    "https://[framework].dev/[path1]",
    "https://[framework].dev/[path2]"
  ],
  alias: "[framework]-docs",
  ttl: 86400
})
```

**Complete Example**:
```javascript
// Load multiple React doc sections
context_load({
  sources: [
    "https://react.dev/learn",
    "https://react.dev/reference/react"
  ],
  alias: "react-docs",
  ttl: 86400
})

// Cross-reference query
context_query({
  alias: "react-docs",
  query: "When should I use useCallback vs useMemo? Give examples."
})
```

**Why it works**: Multiple documentation pages combined for comprehensive answers.

### Example: Load API Documentation

**Goal**: Understand Stripe API for webhook handling

**Complete Example**:
```javascript
// Load Stripe API docs
context_load({
  source: "https://stripe.com/docs/api",
  alias: "stripe-api",
  ttl: 43200
})

// Query specific patterns
context_query({
  alias: "stripe-api",
  query: "How do I handle webhook events for subscription changes?"
})
```

**Why it works**: API docs indexed for natural language querying about endpoints and patterns.

---

## 3. 📄 LOADING PDFS

**Purpose**: Extract and query content from PDF documents including research papers, specifications, and reports.

**Key Points**:
- Supports local files and remote URLs
- Native PDF text extraction
- Good for technical papers, specs, and documentation

### Example: Technical Whitepaper

**Goal**: Analyze research paper methodology

**Template**:
```javascript
context_load({
  source: "/path/to/[document].pdf",  // or https://url/to/doc.pdf
  alias: "[short-name]",
  ttl: 3600
})
```

**Complete Example**:
```javascript
// Load research paper
context_load({
  source: "/path/to/research-paper.pdf",
  alias: "paper",
  ttl: 3600
})

// Query methodology
context_query({
  alias: "paper",
  query: "What methodology did they use? What were the key findings?"
})
```

**Why it works**: Native PDF text extraction enables natural language queries on document content.

### Example: Remote PDF Specification

**Goal**: Understand OAuth 2.0 RFC

**Complete Example**:
```javascript
// Load RFC document
context_load({
  source: "https://datatracker.ietf.org/doc/html/rfc6749",
  alias: "oauth-rfc",
  ttl: 86400,
  systemInstruction: "You are an OAuth 2.0 security expert"
})

// Query security considerations
context_query({
  alias: "oauth-rfc",
  query: "What are the security considerations for refresh tokens?"
})
```

**Why it works**: System instruction provides expert context for more accurate answers.

---

## 4. 🔍 QUERYING LOADED CONTENT

**Purpose**: Demonstrate effective query patterns for getting useful responses from cached content.

**Key Points**:
- Be specific in queries (context + question)
- Use `maxTokens` for longer code examples
- Natural language works best

### Example: Feature Discovery

**Goal**: Find specific functionality in loaded codebase

**Complete Example**:
```javascript
context_query({
  alias: "hono",
  query: "How do I add middleware for authentication?"
})
```

### Example: Architecture Understanding

**Goal**: Understand system design and component relationships

**Complete Example**:
```javascript
context_query({
  alias: "project",
  query: "What's the overall architecture? How do components communicate?"
})
```

### Example: Implementation Details with Extended Output

**Goal**: Get detailed code patterns with full examples

**Complete Example**:
```javascript
context_query({
  alias: "library",
  query: "Show me examples of error handling patterns used in this codebase",
  maxTokens: 4096  // Extended output for code examples
})
```

---

## 5. 🗂️ CACHE MANAGEMENT

**Purpose**: Manage cached contexts to control costs and maintain fresh content.

**Key Points**:
- `context_list` shows all active caches with metadata
- `context_refresh` updates content without changing alias
- `context_evict` stops billing immediately
- `context_stats` tracks token usage and costs

### Example: List All Caches

**Goal**: See what's currently cached and when it expires

**Complete Example**:
```javascript
context_list()
// Returns: [
//   { alias: "react", tokens: 500000, expires: "2024-01-15T12:00:00Z" },
//   { alias: "docs", tokens: 150000, expires: "2024-01-15T14:00:00Z" }
// ]
```

### Example: Refresh Stale Cache

**Goal**: Update cache with fresh content (e.g., after repo changes)

**Complete Example**:
```javascript
context_refresh({
  alias: "docs",
  ttl: 7200  // Extend for 2 more hours
})
```

### Example: Evict Unused Cache

**Goal**: Clean up and stop billing for unused context

**Complete Example**:
```javascript
context_evict({ alias: "old-project" })
// Cache removed, billing stopped
```

### Example: Check Usage Statistics

**Goal**: Monitor token usage and estimated costs

**Complete Example**:
```javascript
context_stats({ alias: "react" })
// Returns: {
//   tokens: 500000,
//   queries: 15,
//   estimatedCost: "$0.23",
//   cacheHitRate: 0.95
// }
```

---

## 6. 🔀 MULTI-SOURCE QUERIES

**Purpose**: Combine multiple sources into single cache for cross-referencing and comparative analysis.

**Key Points**:
- Use `sources` array (not `source`) for multiple items
- Single alias covers all sources
- Enables cross-reference queries

### Example: Cross-Reference Docs and Implementation

**Goal**: Compare documentation claims with actual implementation

**Complete Example**:
```javascript
// Load both docs and code
context_load({
  sources: [
    "https://github.com/framework/repo",
    "https://framework.dev/docs"
  ],
  alias: "framework-complete",
  ttl: 7200
})

// Cross-reference query
context_query({
  alias: "framework-complete",
  query: "The docs say X about routing - how is this actually implemented?"
})
```

**Why it works**: Combined sources enable queries that span documentation and implementation.

### Example: Compare Framework Approaches

**Goal**: Compare how different frameworks solve same problem

**Complete Example**:
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

**Why it works**: Multiple codebases in single context enables comparative analysis.

---

## 7. 📊 QUICK REFERENCE

**Purpose**: Fast lookup tables for source formats and command syntax.

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

### Command Quick Reference

| Command | Purpose | Example |
|---------|---------|---------|
| `context_load` | Load sources into cache | `context_load({ source: "...", alias: "..." })` |
| `context_query` | Query cached content | `context_query({ alias: "...", query: "..." })` |
| `context_list` | List active caches | `context_list()` |
| `context_stats` | Usage statistics | `context_stats({ alias: "..." })` |
| `context_refresh` | Refresh cache | `context_refresh({ alias: "...", ttl: 3600 })` |
| `context_evict` | Remove cache | `context_evict({ alias: "..." })` |

### Parameter Reference

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `source` | string | Yes* | Single source URL or path |
| `sources` | string[] | Yes* | Multiple sources (use instead of `source`) |
| `alias` | string | Yes | Cache identifier (1-64 chars) |
| `ttl` | number | No | Time to live in seconds (60-86400, default: 3600) |
| `systemInstruction` | string | No | System prompt for queries |
| `githubToken` | string | No | Token for private repos |
| `query` | string | Yes | Natural language question |
| `maxTokens` | number | No | Max response tokens |
| `temperature` | number | No | Response randomness (0-2) |

*Either `source` or `sources` required, not both

---

**Related Files**:
- See `../SKILL.md` for complete mnemo skill documentation
- See `../../mcp-semantic-search/SKILL.md` for local codebase search (complementary tool)
