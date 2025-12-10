---
name: mcp-mnemo
description: Extended AI memory via Gemini context caching. Use for loading and querying large external content (GitHub repos, documentation URLs, PDFs, JSON APIs) that exceeds local context. Complements semantic search for cross-project and external knowledge access.
allowed-tools: [Read, Glob, Grep, Bash]
version: 1.0.0
---

<!-- Keywords: mnemo, mcp, gemini, context-caching, extended-memory, github-repos, pdf-analysis, documentation, cross-project, external-knowledge -->

# MCP Mnemo - Extended AI Memory via Gemini Context Caching

Extended memory for AI assistants through Gemini context caching, enabling natural language queries across large codebases, documentation, PDFs, and external sources without complex retrieval systems.

---

## 1. 🎯 WHEN TO USE

### Primary Use Cases

**Use this skill when:**

1. **Large external codebase analysis**
   - Query entire GitHub repositories with full context
   - Understand architecture, patterns, and relationships across repos
   - Compare implementations across multiple projects

2. **Documentation site querying**
   - Index entire documentation websites for Q&A
   - Explore unfamiliar frameworks, APIs, or libraries
   - Cross-reference multiple documentation sources

3. **PDF and document processing**
   - Load and query research papers, reports, specifications
   - Comparative analysis across documents
   - Extract insights from technical whitepapers

4. **Cross-project pattern discovery**
   - Query multiple projects simultaneously
   - Find patterns and reuse code from other codebases
   - Compare implementation approaches

5. **External knowledge augmentation**
   - Access content from URLs, JSON APIs, remote sources
   - Maintain large static contexts across queries
   - Bridge gaps in local knowledge


### When NOT to Use

**Use different tools instead:**

1. **Known local file path** → Use `Read` tool
   ```
   ❌ context_query(alias="local", query="Show me hero_video.js")
   ✅ Read("src/hero/hero_video.js")
   ```

2. **Local codebase intent-based discovery** → Use `semantic_search`
   ```
   ❌ context_load(source=".", alias="local") + context_query
   ✅ mcp__semantic_search__semantic_search(query="Find validation logic")
   ```

3. **Specific symbol/pattern search** → Use `Grep` tool
   ```
   ❌ context_query(alias="code", query="Find initVideoPlayer calls")
   ✅ Grep("initVideoPlayer", output_mode="content")
   ```

4. **File structure exploration** → Use `Glob` tool
   ```
   ❌ context_query(alias="code", query="List all JavaScript files")
   ✅ Glob("**/*.js")
   ```

5. **Frequently changing data** → Use RAG/semantic search
   - Mnemo caches are static during TTL period
   - Semantic search indexes update in real-time


### Activation Triggers

**Activate this skill when user asks:**

- "Load [GitHub repo URL] and tell me about..."
- "Query the [framework] documentation for..."
- "Analyze this PDF/paper..."
- "Compare [repo1] and [repo2]..."
- "What does [external project] do with..."
- "Index [URL] and explain..."

**Do NOT activate for:**

- Local file operations (use Read/Write)
- Current project code discovery (use semantic search)
- Simple pattern matching (use Grep)

---

## 2. 🧭 SMART ROUTING

### Decision Matrix

```
NEED external content (GitHub, URLs, PDFs)?
    → Use Mnemo

NEED local codebase discovery by INTENT?
    → Use Semantic Search MCP

KNOW the exact file path?
    → Use Read tool

KNOW the exact symbol/pattern?
    → Use Grep tool

NEED file structure exploration?
    → Use Glob tool

KNOWLEDGE BASE > 1M tokens?
    → Use RAG (chunking required)
```

### Resource Router

```python
def route_mnemo_resources(task):
    # ──────────────────────────────────────────────────────────────────
    # QUERY EXAMPLES
    # Purpose: Categorized examples for all mnemo operations
    # Key Insight: Goal/Load/Query/Explanation structure for each use case
    # ──────────────────────────────────────────────────────────────────
    if task.needs_usage_examples or task.query_not_working:
        return load("assets/query_examples.md")

    # ──────────────────────────────────────────────────────────────────
    # TOOL COMPARISON
    # Purpose: When to use mnemo vs semantic search vs native tools
    # Key Insight: Mnemo for external, semantic search for local
    # ──────────────────────────────────────────────────────────────────
    if task.unsure_which_tool:
        return load("references/tool_comparison.md")

    # ══════════════════════════════════════════════════════════════════════
    # STATIC RESOURCES (always available, not conditionally loaded)
    # ══════════════════════════════════════════════════════════════════════
    # assets/query_examples.md → Categorized usage examples
    # references/tool_comparison.md → Decision matrix for tool selection
```

---

## 3. 🛠️ HOW IT WORKS

### Tool Overview

**6 MCP tools available:**

1. **`context_load`** - Load sources into Gemini context cache
   - GitHub repos (public/private), URLs, PDFs, JSON APIs, local files
   - Supports multiple sources combined into one cache
   - Configurable TTL (60-86400 seconds)

2. **`context_query`** - Query cached content with natural language
   - Natural language questions on cached context
   - Configurable max tokens and temperature

3. **`context_list`** - List all active caches
   - Shows alias, token count, expiry time
   - No parameters required

4. **`context_stats`** - Get usage statistics
   - Token usage and cost tracking
   - Cache hit rates

5. **`context_refresh`** - Refresh stale cache
   - Re-fetch source content
   - Update TTL

6. **`context_evict`** - Remove cached context
   - Free resources and stop billing


### Basic Usage Pattern

**Load → Query → Manage workflow:**

```javascript
// Step 1: Load external content
context_load({
  source: "https://github.com/owner/repo",
  alias: "my-repo",
  ttl: 3600  // 1 hour
})

// Step 2: Query the loaded content
context_query({
  alias: "my-repo",
  query: "How does authentication work in this project?"
})

// Step 3: Manage cache when done
context_evict({ alias: "my-repo" })
```


### Example 1: GitHub Repository Analysis

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

// Query specific patterns
context_query({
  alias: "hono",
  query: "Show me examples of request validation patterns"
})
```

**Why it works:** Full codebase loaded into context enables comprehensive understanding without local cloning.


### Example 2: Documentation Cross-Reference

**Goal:** Learn a new framework from official docs

```javascript
// Load documentation
context_load({
  sources: [
    "https://react.dev/learn",
    "https://react.dev/reference"
  ],
  alias: "react-docs",
  ttl: 86400  // 24 hours
})

// Query for specific guidance
context_query({
  alias: "react-docs",
  query: "When should I use useCallback vs useMemo? Give examples."
})
```

**Why it works:** Multiple documentation pages combined into single queryable context.


### Example 3: PDF Analysis

**Goal:** Extract insights from technical papers

```javascript
// Load PDF (local or URL)
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

**Why it works:** Native PDF support extracts text for natural language querying.


### Best Practices

**Do:**
- ✅ Use specific, natural language queries
- ✅ Combine related sources into single alias
- ✅ Set appropriate TTL based on content freshness needs
- ✅ Monitor costs with `context_stats`
- ✅ Evict unused caches to stop billing

**Don't:**
- ❌ Use for local project code (use semantic search)
- ❌ Load content > 1M tokens (use RAG instead)
- ❌ Expect real-time updates (content static during TTL)
- ❌ Use for simple file reads (use Read tool)

---

## 4. 📋 RULES

### ✅ ALWAYS

1. **ALWAYS verify GEMINI_API_KEY is configured**
   - Required for all mnemo operations
   - Check environment before first use

2. **ALWAYS use meaningful aliases**
   - 1-64 characters, descriptive
   - Example: "react-docs", "auth-library", "api-spec"

3. **ALWAYS set appropriate TTL**
   - Default: 3600 seconds (1 hour)
   - Range: 60-86400 seconds
   - Longer for stable content, shorter for frequently updated

4. **ALWAYS use context_list before operations**
   - Verify cache exists before querying
   - Check token counts and expiry

5. **ALWAYS evict unused caches**
   - Stops billing for storage
   - Good practice after completing tasks


### ❌ NEVER

1. **NEVER use mnemo for local file operations**
   - Use Read/Write tools for local files
   - Semantic search for local code discovery
   - Much faster and no API costs

2. **NEVER load content exceeding 1M tokens**
   - Gemini context window limit
   - Use RAG with chunking for larger content

3. **NEVER expect real-time updates**
   - Cache is static during TTL period
   - Use context_refresh for updates

4. **NEVER expose GEMINI_API_KEY**
   - Store in environment variables
   - Never commit to version control

5. **NEVER query non-existent aliases**
   - Use context_list to verify first
   - Clear error messages but wastes API call


### ⚠️ ESCALATE IF

1. **ESCALATE IF cache creation fails**
   - Check GEMINI_API_KEY validity
   - Verify source URL accessibility
   - Check token count (min 1,024 for Flash, 4,096 for Pro)

2. **ESCALATE IF queries return poor results**
   - Rephrase with more specific language
   - Add systemInstruction for context
   - Verify cache loaded successfully

3. **ESCALATE IF costs seem high**
   - Review cache TTLs
   - Check for forgotten caches with context_list
   - Consider shorter TTLs or fewer sources

4. **ESCALATE IF server won't start**
   - Verify bun installation
   - Check GEMINI_API_KEY environment variable
   - Review mnemo logs for errors

---

## 5. 🎓 SUCCESS CRITERIA

**Task complete when:**

- ✅ External content successfully loaded into cache
- ✅ Natural language queries return relevant results
- ✅ Used mnemo for appropriate use case (not local files)
- ✅ Cache managed properly (evicted when done)
- ✅ Cost-effective usage (appropriate TTL, no forgotten caches)


### Quality Targets

| Metric                 | Target                     |
| ---------------------- | -------------------------- |
| Cache creation success | 100% (with valid sources)  |
| Query relevance        | High (specific queries)    |
| Cost efficiency        | 75-90% savings vs uncached |
| Cache cleanup          | 100% evicted after task    |

---

## 6. 🔗 INTEGRATION POINTS

### MCP Dependency

**Required MCP tools:**
- `context_load` - Load sources into cache
- `context_query` - Query cached content
- `context_list` - List active caches
- `context_stats` - Usage statistics
- `context_refresh` - Refresh cache
- `context_evict` - Remove cache

**MCP server:** mnemo (TypeScript/Bun)

**Availability:** CLI AI agents with MCP support (Claude Code, Opencode)

**NOT available:** IDE integrations without MCP support


### Pairs With

**Semantic Search MCP:**
- Mnemo: External content, large contexts
- Semantic Search: Local codebase, real-time updates
- Workflow: Use semantic search for local, mnemo for external

**Read Tool:**
- Mnemo: Query external content
- Read: Access local files directly
- Workflow: context_query → identify file → Read local equivalent

**Grep Tool:**
- Mnemo: Natural language queries on external content
- Grep: Exact pattern matching on local files
- Workflow: Mnemo finds patterns, Grep validates locally


### Related Skills

**mcp-semantic-search:**
- Mnemo complements (not replaces) semantic search
- Use semantic search for local project code discovery
- Use mnemo for external repositories and documentation

**mcp-code-mode:**
- NOT needed for mnemo - call mnemo tools directly
- Code Mode is for external tools (Webflow, Figma, etc.)


### External Dependencies

**Gemini API:**
- Required for all operations
- API key must be configured
- Pricing: ~$1-4.50 per 1M tokens/hour storage
- 75-90% discount on cached input tokens

**Bun Runtime:**
- Required for local server
- Version 1.0+ recommended

**Installation Path:**
- Server: `/Users/USERNAME/path/to/mcp-servers/mnemo`
- Entry point: `packages/local/src/stdio.ts` (stdio) or `packages/local/src/index.ts` (HTTP)


### Cost Structure

| Component           | Cost                                  |
| ------------------- | ------------------------------------- |
| Cache storage       | ~$1-4.50 per 1M tokens/hour           |
| Cached input tokens | 10% of standard rate (75-90% savings) |
| Output tokens       | Standard rates                        |

**Example:** 100K token codebase, 1 hour, 10 queries ≈ $0.47


### External Documentation

- **Mnemo Repository:** https://github.com/Logos-Flux/mnemo
- **Gemini Context Caching:** https://ai.google.dev/gemini-api/docs/caching

---

**Remember**: Mnemo extends your AI memory with external content. Use it for GitHub repos, documentation, and PDFs - not for local files where Read and semantic search are faster and free.