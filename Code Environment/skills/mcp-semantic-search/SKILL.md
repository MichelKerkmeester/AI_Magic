---
name: mcp-semantic-search
description: Intent-based code discovery for CLI AI agents using semantic search MCP tools. Use when finding code by what it does (not what it's called), exploring unfamiliar areas, or understanding feature implementations. Mandatory for code discovery tasks when you have MCP access.
allowed-tools: [Grep, Read, Glob]
version: 1.0.0
---

# MCP Semantic Search - Intent-Based Code Discovery

Semantic code search for CLI AI agents that enables AI-powered codebase exploration using natural language queries instead of keyword searches. Available exclusively for CLI AI agents with MCP (Model Context Protocol) support.

---

## 1. 🎯 WHEN TO USE

### 📚 Navigation Guide

**This file (SKILL.md)**: Intent-based code discovery activation rules and core patterns

**References** (detailed documentation):
- [tool_comparison.md](./references/tool_comparison.md) – Semantic vs Grep vs Glob decision framework
- [architecture.md](./references/architecture.md) – System components and data flow
- [query_patterns.md](./references/query_patterns.md) – Effective query writing guide

**Assets** (templates and examples):
- [query_examples.md](./assets/query_examples.md) – Categorized example queries (9 categories)


### Primary Use Cases

**Use this skill when:**

1. **Exploring unfamiliar code**
   - You don't know where functionality lives
   - You need to understand how features work
   - You're new to the codebase

2. **Finding by behavior/intent**
   - "Find code that validates email addresses"
   - "Show me where we handle form submissions"
   - "Locate animation initialization logic"

3. **Understanding patterns**
   - "How do we use Motion.dev library?"
   - "Find all modal implementations"
   - "Show me cookie consent patterns"

4. **Discovering cross-file relationships**
   - "How does navigation interact with page transitions?"
   - "What code depends on the video player?"
   - "Find related components across files"

5. **Code discovery tasks for CLI AI agents**
   - Any task requiring intent-based code search
   - When grep/glob don't provide enough context
   - When you know what code does, not where it is


### When NOT to Use

**Use different tools instead:**

1. **Known exact file paths** → Use `Read` tool
   ```
   ❌ semantic_search("Find hero_video.js content")
   ✅ Read("src/hero/hero_video.js")
   ```

2. **Specific symbol searches** → Use `Grep` tool
   ```
   ❌ semantic_search("Find all calls to initVideoPlayer")
   ✅ Grep("initVideoPlayer", output_mode="content")
   ```

3. **Simple keyword searches** → Use `Grep` tool
   ```
   ❌ semantic_search("Find all TODO comments")
   ✅ Grep("TODO:", output_mode="content")
   ```

4. **File structure exploration** → Use `Glob` tool
   ```
   ❌ semantic_search("Show me all JavaScript files")
   ✅ Glob("**/*.js")
   ```

5. **IDE integrations** → NOT SUPPORTED
   - This skill is ONLY for CLI AI agents
   - IDE autocomplete (GitHub Copilot in VS Code) uses different systems
   - IDE-embedded chat (no MCP support as of 2025)


### Activation Triggers

**Activate this skill when user asks:**

- "Find code that handles [feature/behavior]"
- "Where do we implement [functionality]?"
- "Show me how [feature] works"
- "How do we handle [behavior]?"
- "What code [performs action]?"
- "Find [pattern] implementation"
- "Show me [component/module] code"

**Do NOT activate for:**

- Known file paths
- Exact symbol/function name searches
- File pattern matching requests
- IDE autocomplete questions

---

## 2. 🧭 SMART ROUTING

```python
def route_semantic_search_resources(task):
    # tool selection guidance
    if task.unsure_which_tool:
        return load("references/tool_comparison.md")  # semantic vs grep vs glob decision
    
    # query writing help
    if task.needs_query_examples or task.query_not_working:
        load("references/query_patterns.md")  # effective query writing guide
        return load("assets/query_examples.md")  # 9 categories of real queries
    
    # architecture/system understanding
    if task.needs_architecture_info:
        return load("references/architecture.md")  # indexer + MCP server + vector DB
    
    # tool decision:
    # - know exact file path → use Read() tool directly
    # - know exact symbol name → use Grep() tool directly
    # - know file pattern → use Glob() tool directly
    # - know what code DOES → use semantic_search() with natural language
```

---

## 3. 🗂️ REFERENCES

### Core Framework

| Document | Purpose | Key Insight |
|----------|---------|-------------|
| **MCP Semantic Search - Intent-Based Code Discovery** | Enable CLI AI agents to search codebases by intent using natural language queries | **Finds code by what it does, not what it's called** |

### Bundled Resources

| Document | Purpose | Key Insight |
|----------|---------|-------------|
| **references/tool_comparison.md** | Decision framework for semantic search vs grep vs glob | When to use each tool based on knowledge and intent |
| **references/architecture.md** | System architecture and data flow | Two-component system: Indexer + MCP Server + Vector DB |
| **references/query_patterns.md** | Effective query writing guide | Describe behavior in natural language for best results |
| **assets/query_examples.md** | Categorized example queries | 9 categories of real-world query patterns |

---

## 4. 🛠️ HOW IT WORKS

### Tool Overview

**Three semantic search MCP tools available:**

1. **`semantic_search`** - Search current project semantically
   - Primary tool for code discovery
   - Finds code by intent and behavior
   - Returns ranked code snippets with file paths

2. **`search_commit_history`** - Search git commit history
   - Understanding why code was changed
   - Finding when features were added
   - Locating bug fixes

3. **`visit_other_project`** - Search other indexed projects
   - Finding similar patterns in other codebases
   - Reusing code from other projects
   - Cross-project comparisons


### Basic Usage Pattern

**Query structure - describe what code does:**

```javascript
// Good: Natural language, behavior-focused
semantic_search("Find code that validates email addresses in contact forms")

// Good: Question format
semantic_search("How do we handle page transitions?")

// Good: Feature discovery
semantic_search("Find cookie consent implementation")

// Bad: Grep syntax
semantic_search("grep validateEmail")  // ❌ Use grep tool instead

// Bad: Known file path
semantic_search("Show me hero_video.js")  // ❌ Use Read tool instead
```

### Example 1: Feature Discovery

**Goal:** Find email validation logic

```javascript
// Step 1: Use semantic search
semantic_search("Find code that validates email addresses in contact forms")

// Expected results:
// - src/form/form_validation.js (ranked #1)
// - src/utils/email_validator.js (ranked #2)
// - Code snippets with validation logic

// Step 2: Read full context
Read("src/form/form_validation.js")

// Step 3: Analyze and make changes
Edit(...) or Write(...)
```

**Why it works:** Query describes behavior (validates email), context (contact forms), allowing semantic search to find relevant code.


### Example 2: Understanding Relationships

**Goal:** Find what code depends on video player

```javascript
// Use relationship query
semantic_search("What code depends on the video player?")

// Expected results:
// - src/components/hero_section.js (uses video player)
// - src/animations/hero_animations.js (triggers on video events)
// - Code snippets showing imports and usage

// Follow up: Read specific files
Read("src/components/hero_section.js")
```

**Why it works:** Semantic search understands dependencies and can find related code across files.


### Query Best Practices

**Do:**

- ✅ Use natural language
- ✅ Describe what code does (behavior)
- ✅ Add context ("in forms", "for video player")
- ✅ Ask about relationships ("What code depends on...")
- ✅ Be specific about intent

**Don't:**

- ❌ Use grep/find syntax
- ❌ Search for exact symbols (use Grep instead)
- ❌ Request known file paths (use Read instead)
- ❌ Be too generic ("Find code")

**For more query patterns, see:** [query_patterns.md](./references/query_patterns.md)


### Trust the Judge Model

**Results are reranked for relevance:**

- Top results are usually most relevant
- Judge model (voyage-3) understands intent
- If results seem off, rephrase query more specifically
- Add context: "in [component]" or "for [feature]"

---

## 5. 📋 RULES

### ✅ ALWAYS 

1. **ALWAYS use for intent-based discovery**
   - When you know what code does, not where it is
   - Exploring unfamiliar codebase areas
   - Understanding feature implementations

2. **ALWAYS use natural language**
   - Describe behavior in conversational tone
   - "Find code that validates email addresses"
   - NOT grep syntax or code symbols

3. **ALWAYS provide context in queries**
   - Include "in [component]" or "for [feature]"
   - Improves result relevance significantly
   - "Find validation in contact forms" beats "Find validation"

4. **ALWAYS combine with Read tool**
   - Semantic search discovers files
   - Read tool provides full context
   - Workflow: semantic_search → Read → Edit

5. **ALWAYS check for MCP availability**
   - This skill requires MCP access
   - Only works for CLI AI agents
   - Verify semantic-search MCP server is running

### ❌ NEVER 

1. **NEVER use for known file paths**
   - If you know the path, use Read tool
   - Faster, no API latency
   - Example: Read("src/hero/hero_video.js")

2. **NEVER use for exact symbol searches**
   - If you know the symbol name, use Grep
   - More precise for literal text matching
   - Example: Grep("initVideoPlayer", output_mode="content")

3. **NEVER use grep/find syntax**
   - Semantic search uses natural language
   - NOT command-line syntax
   - "Find code that..." NOT "grep pattern"

4. **NEVER skip validation of MCP access**
   - Verify you have MCP support
   - Only CLI AI agents can use this
   - IDE integrations use different systems

5. **NEVER use for file structure exploration**
   - Use Glob for file pattern matching
   - Glob is faster for file navigation
   - Example: Glob("**/*.js")

### ⚠️ ESCALATE IF

1. **ESCALATE IF MCP server unavailable**
   - Inform user of missing dependency
   - Suggest fallback to Grep/Glob tools
   - Provide setup guide reference

2. **ESCALATE IF results consistently irrelevant**
   - After 2-3 query rephrases still not relevant
   - May indicate indexing issue
   - Verify with `/semantic_search stats` or ask user to run `/semantic_search start`

3. **ESCALATE IF uncertain about tool selection**
   - If confidence < 80% on semantic vs grep vs glob
   - Ask user for clarification
   - Provide tool comparison context

4. **ESCALATE IF IDE integration requested**
   - This skill does NOT work with IDE autocomplete
   - Clarify scope: CLI AI agents only
   - Explain system separation

---

## 6. 🎓 SUCCESS CRITERIA

**Task complete when:**

- ✅ Found relevant code by intent/behavior
- ✅ Used correct tool (semantic vs grep vs glob)
- ✅ Provided natural language query (not grep syntax)
- ✅ Combined with Read tool for full context
- ✅ Avoided using semantic search for known paths
- ✅ Added context to query when needed ("in forms", "for feature")
- ✅ Trusted judge model reranking (top results checked first)

---

## 7. 🔗 INTEGRATION POINTS

### MCP Dependency

**Required MCP tools:**

- `semantic_search` - Semantic code search
- `search_commit_history` - Semantic commit history search
- `visit_other_project` - Cross-project search

**MCP server:** semantic-search (Python)

**Availability:** CLI AI agents only (Claude Code AI, GitHub Copilot CLI, Opencode, Kilo CLI)

**NOT available:** IDE integrations (GitHub Copilot in VS Code/IDEs)


### Pairs With

**Read tool:**

- Semantic search discovers files
- Read provides full file context
- Workflow: semantic_search → Read → Edit

**Grep tool:**

- Semantic search for discovery
- Grep for specific symbol usage
- Workflow: semantic_search → Grep("symbol")

**Glob tool:**

- Glob for file structure
- Semantic search for understanding
- Workflow: Glob("**/*.js") → semantic_search("How does [component] work?")


### Related Skills

**Note on Code Mode:**

- Semantic search is a **NATIVE MCP tool** - call directly, NOT through Code Mode
- Use `semantic_search()`, `search_commit_history()`, `visit_other_project()` directly
- Code Mode is for external tools (Webflow, Figma, ClickUp, etc.)
- See [.claude/skills/mcp-code-mode/SKILL.md](../mcp-code-mode/SKILL.md) for external tool patterns


### External Dependencies

**Indexer:** codebase-index-cli (Node.js)

- Creates vector embeddings from code
- Watches files for real-time updates
- Stores in .codebase/vectors.db

**Vector Database:** SQLite (.codebase/vectors.db)

- 1024-dimensional vectors
- Real-time file watching
- Project-specific index

**Voyage AI API:**

- voyage-code-3 model (embeddings)
- voyage-3 model (judge/reranking)
- API key required

### Project Indexing Requirements

**Must be indexed first:**

- Run `codesql -start` (CLI) or `/semantic_search start` (Claude Code) to create .codebase/vectors.db
- Use `/semantic_search stats` to verify indexing status
- Indexer watches files for automatic updates

**Current example.com index (as of 2025-11-25):**

- 249 files indexed
- 496 code blocks
- Languages: JavaScript, CSS, HTML, Markdown


### Scope and Compatibility

**✅ Works with (CLI AI agents):**

- Claude Code AI
- GitHub Copilot CLI
- Opencode
- Kilo CLI
- Any MCP-compatible CLI AI agent

**❌ Does NOT work with (IDE integrations):**

- GitHub Copilot in VS Code/IDEs
- GitHub Copilot Chat in IDE
- Any IDE-embedded autocomplete systems

**Reason:** Different systems - semantic search is for CLI AI agents helping you via chat, not autocomplete while typing.


### External Documentation

- **Indexer repository:** https://github.com/dudufcb1/codebase-index-cli
- **MCP server repository:** https://github.com/dudufcb1/semantic-search
- **Voyage AI documentation:** https://docs.voyageai.com/
- **For detailed architecture, see:** [architecture.md](./references/architecture.md)

---

**Remember**: This skill operates as an intent-based discovery engine. It enables natural language exploration of the codebase to find functionality by behavior rather than keyword.