---
name: workflows-save-context
description: Saves expanded conversation context with full dialogue, decision rationale, visual flowcharts, and file changes. Auto-triggers on keywords or every 20 messages. Includes semantic vector search.
allowed-tools: [Read, Write, Bash]
version: 1.0.0
---

<!-- Keywords: save-context, context-preservation, memory, session-documentation, auto-save, semantic-search, anchor-retrieval -->

# Save Context - Expanded Conversation Documentation

> **Related Documentation:**
> - [README.md](./README.md) - Semantic Memory setup, MCP integration, API reference
> - [/save_context](../../commands/save_context.md) - Slash command reference

> **TL;DR**: Say "save context" or let it auto-save every 20 messages. Creates `specs/###-feature/memory/{timestamp}.md` with full conversation, decisions, and diagrams. Includes semantic vector search.

---

## 1. 🎯 WHEN TO USE

### Trigger Phrases

| Phrase | Also Works |
|--------|------------|
| "save context" | "save conversation" |
| "document this" | "preserve context" |
| "save session" | "save this discussion" |

### Auto-Save

**Every 20 messages** the system automatically saves context. No action required.

### When to Save

| Scenario | Example |
|----------|---------|
| Feature complete | "Just finished the payment integration" |
| Complex discussion | "We made 5 architecture decisions today" |
| Team sharing | "Need to document this for the team" |
| Session ending | "Wrapping up for the day" |

### When NOT to Use

- Simple typo fixes or trivial changes
- Context already documented in spec/plan files
- Conversations without spec folders (create one first)

### Context Recovery (CRITICAL)

**Before implementing ANY changes** in a spec folder with memory files, search for relevant context:

```bash
# Keyword search
grep -r "anchor:.*keyword" specs/###-current-spec/memory/*.md

# Semantic search
claude-mem vector "your search query"
```

If found, load and acknowledge context before proceeding.

---

## 2. 🧭 SMART ROUTING

```python
def route_save_context_resources(task):
    # Main context generation
    if task.generating_context:
        return execute("scripts/generate-context.js")

    # Flowchart patterns
    if task.needs_flowchart:
        if task.phase_count <= 4:
            return load("references/workflow_linear_pattern.md")
        else:
            return load("references/workflow_parallel_pattern.md")

    # Semantic features
    if task.semantic_search:
        return load("references/semantic_memory.md")

    # Execution details
    if task.needs_execution_details:
        return load("references/execution_methods.md")

    # Spec folder routing
    if task.folder_detection:
        return load("references/spec_folder_detection.md")

    # Troubleshooting
    if task.has_issues:
        return load("references/troubleshooting.md")

    # Output format
    if task.needs_output_format:
        return load("references/output_format.md")

    # Configuration
    if task.configuring:
        return load("references/trigger_config.md")

# Output: specs/###-feature/memory/{timestamp}__{topic}.md
# Alignment threshold: 70%
```

---

## 3. 🗂️ REFERENCES

### Core Resources

| Document | Purpose | When to Read |
|----------|---------|--------------|
| [execution_methods.md](./references/execution_methods.md) | 4 execution paths, anchor retrieval | Running save-context |
| [semantic_memory.md](./references/semantic_memory.md) | Vector search, MCP tools | Semantic features |
| [spec_folder_detection.md](./references/spec_folder_detection.md) | Folder routing, markers | Understanding routing |

### Workflow Patterns

| Document | Purpose | When to Read |
|----------|---------|--------------|
| [workflow_linear_pattern.md](./references/workflow_linear_pattern.md) | Sequential diagrams (<=4 phases) | Creating flowcharts |
| [workflow_parallel_pattern.md](./references/workflow_parallel_pattern.md) | Concurrent diagrams (>4 phases) | Complex flows |

### Configuration & Troubleshooting

| Document | Purpose | When to Read |
|----------|---------|--------------|
| [trigger_config.md](./references/trigger_config.md) | Keywords, auto-save interval | Customizing triggers |
| [output_format.md](./references/output_format.md) | Timestamps, file naming | Understanding output |
| [alignment_scoring.md](./references/alignment_scoring.md) | Topic matching weights | Score questions |
| [troubleshooting.md](./references/troubleshooting.md) | Issue resolution | Debugging problems |

### Templates & Config

| File | Purpose |
|------|---------|
| [context_template.md](./templates/context_template.md) | Output format template |
| [config.jsonc](./config.jsonc) | Runtime configuration |
| [filters.jsonc](./filters.jsonc) | Content filtering rules |

---

## 4. 🛠️ HOW TO USE

### Quick Overview

| Action | Method | When to Use |
|--------|--------|-------------|
| Auto-save | Say trigger phrase or wait 20 msgs | Normal workflow |
| Manual save | `/save_context` command | Explicit control |
| Script | `node generate-context.js` | Testing/debugging |
| Semantic search | `claude-mem vector "query"` | Find prior context |

### Execution Methods

| Method | Hooks | AI | Effort | Use Case |
|--------|-------|-----|--------|----------|
| **Keyword trigger** | No | No | Zero | Type "save context" |
| **Slash command** | No | Yes | Low | `/save_context` |
| **Direct script** | No | No | Medium | Testing |
| **Helper script** | No | No | Low | Standalone |

For detailed examples, see [execution_methods.md](./references/execution_methods.md).

### Basic Script Usage

```bash
# With spec folder argument
node .claude/skills/workflows-save-context/scripts/generate-context.js \
  /tmp/context-data.json "122-feature-name"

# Helper script (auto-detects folder)
bash .claude/skills/workflows-save-context/scripts/save-context-manual.sh
```

### Output Files

| File | Content |
|------|---------|
| `{date}_{time}__{topic}.md` | Full session documentation |
| `metadata.json` | Session statistics |

**Naming**: `DD-MM-YY_HH-MM__topic.md` (e.g., `07-12-25_14-30__oauth.md`)

---

## 5. 🔗 ANCHOR-BASED RETRIEVAL

Memory files include searchable HTML anchors for targeted loading.

### Token Efficiency

| Approach | Tokens | Savings |
|----------|--------|---------|
| Full file read | ~12,000 | - |
| Anchor extraction | ~800 | 93% |

### Anchor Format

`<!-- anchor: category-keywords-spec# -->`

**Categories**: `implementation`, `decision`, `guide`, `architecture`, `files`, `discovery`, `integration`

### Quick Commands

```bash
# Find anchors by keyword
grep -l "anchor:.*decision.*auth" specs/*/memory/*.md

# Extract specific section
sed -n '/<!-- anchor: decision-jwt-049 -->/,/<!-- \/anchor: decision-jwt-049 -->/p' file.md
```

### Context Recovery Protocol

**MANDATORY**: Before implementing changes in folders with memory files:

1. **Extract keywords** from your task (2-4 key terms)
2. **Search anchors**: `grep -r "anchor:.*keyword" specs/###-spec/memory/*.md`
3. **Or use semantic search**: `claude-mem vector "your query"`
4. **Load relevant sections** if found
5. **Acknowledge context**: "Based on prior decision in [file]..."

See [execution_methods.md](./references/execution_methods.md) for full protocol.

---

## 6. 🧠 SEMANTIC SEARCH

Semantic vector search enables intelligent memory retrieval.

### Key Commands

| Command | Purpose | Example |
|---------|---------|---------|
| `search <query>` | Interactive semantic search | `/save_context search "OAuth"` |
| `multi <concepts>` | AND search across concepts | `/save_context search "oauth" "security"` |
| `rebuild` | Rebuild vector index | `/save_context rebuild` |
| `verify` | Check index integrity | `/save_context verify` |
| `resume` | Resume previous search session | `/save_context resume` |

### Interactive Search Mode (NEW - Spec 015)

Rich interactive search with preview, filtering, and session persistence:

```
/save_context search "oauth implementation"

Memory Search Results                              Page 1/3
============================================================

Query: "oauth implementation"
Found: 25 memories across 5 spec folders

#1 [92%] OAuth callback flow implementation
   Folder: 049-auth-system  |  Date: Dec 5  |  Tags: oauth, jwt
   "Authorization Code flow with PKCE, httpOnly refresh..."

#2 [85%] JWT token refresh strategy
   Folder: 049-auth-system  |  Date: Dec 4  |  Tags: jwt, refresh
   "Sliding window refresh with httpOnly cookies..."

---------------------------------------------------------------------
Actions: [v]iew #n | [l]oad #n | [f]ilter | [c]luster | [n]ext | [q]uit
```

### Interactive Actions

| Action | Purpose | Example |
|--------|---------|---------|
| `v#` or `view #` | Preview memory before loading | `v1` |
| `l#` or `load #` | Load memory into context | `l1` |
| `f <filter>` | Filter results | `f folder:auth date:>2025-12-01` |
| `c` | Cluster by spec folder | `c` |
| `n` / `p` | Next/previous page | `n` |
| `e <anchor>` | Extract specific section | `e decisions` |
| `b` | Back to previous view | `b` |
| `?` | Show help | `?` |

### Filter Syntax

```bash
f folder:049-auth      # Filter by spec folder (partial match)
f date:>2025-12-01     # Filter by date (after)
f date:<2025-12-01     # Filter by date (before)
f tag:oauth            # Filter by tag
f folder:auth tag:jwt  # Multiple filters (AND)
```

### Session Persistence

Search sessions persist for 1 hour:
- Resume with `/save_context resume`
- Auto-saves on every action
- Preserves filters, pagination, and state

### MCP Tools (for AI agents)

| Tool | Purpose |
|------|---------|
| `memory_search` | Semantic vector search |
| `memory_load` | Load memory by spec folder |
| `memory_match_triggers` | Fast trigger phrase matching |

See [semantic_memory.md](./references/semantic_memory.md) for complete documentation.

---

## 7. 📋 IMPLEMENTATION

### JSON Data Structure

```javascript
{
  "SPEC_FOLDER": "049-feature-name",
  "recent_context": [{
    "request": "What user asked for",
    "completed": "What was accomplished",
    "learning": "Key insights",
    "duration": "45m",
    "date": "2025-12-07T14:30:00Z"
  }],
  "observations": [{
    "type": "feature|bugfix|decision|discovery|change",
    "title": "Brief title",
    "narrative": "Detailed description",
    "timestamp": "2025-12-07T14:30:00Z",
    "files": ["path/to/file.js"],
    "facts": ["Key point 1", "Key point 2"]
  }],
  "user_prompts": [{
    "prompt": "The actual user message",
    "timestamp": "2025-12-07T14:30:00Z"
  }]
}
```

### Spec Folder Detection

| Step | Action |
|------|--------|
| 1 | Check if in `/specs/###-*/` directory |
| 2 | If not, find most recent spec folder |
| 3 | Calculate alignment score (threshold: 70%) |
| 4 | If < 70%, prompt user to select folder |
| 5 | If no spec folder exists, fail with error |

See [spec_folder_detection.md](./references/spec_folder_detection.md) for sub-folder routing.

---

## 8. 📖 RULES

### ALWAYS

- Detect spec folder before creating documentation
- Use single `memory/` folder with timestamped files
- Include `metadata.json` with session stats
- Search anchors/semantic before implementing in folders with memory
- Generate vector embeddings for new memory files

### NEVER

- Fabricate decisions that weren't made
- Include sensitive data (passwords, API keys)
- Skip template validation before writing
- Proceed if spec folder detection fails
- Save context without spec folder

### ESCALATE IF

- Cannot create conversation summary
- Script execution fails with errors
- File write permissions denied
- Vector embedding generation fails repeatedly
- No spec folder exists

---

## 9. 🎓 SUCCESS CRITERIA

### Task Complete When

- [x] Auto-detects current spec folder
- [x] Creates 2 files: `{timestamp}.md` + `metadata.json`
- [x] Generates readable, well-formatted documentation
- [x] Includes accurate timestamps and metadata
- [x] Vector embeddings generated
- [x] Trigger phrases extracted

### Performance Targets

| Operation | Target | Actual |
|-----------|--------|--------|
| Manual save | 2-3s | ~2.5s |
| Auto-save | 3-5s | ~4s |
| Vector search | <500ms | ~450ms |
| Trigger matching | <50ms | ~35ms |

---

## 10. 🔗 INTEGRATION POINTS

### Data Flow

```
Conversation → AI Analysis → JSON → Script → Markdown + Embeddings
```

### Pairs With

| Skill | Integration |
|-------|-------------|
| `git-commit` | Enhances with commit SHAs |
| `create-documentation` | Flowchart generation |
| `workflows-spec-kit` | Spec folder workflows |

### Script Location

```
.claude/skills/workflows-save-context/scripts/generate-context.js
```

### Semantic Components

| Component | Location |
|-----------|----------|
| Embeddings | `scripts/lib/embeddings.js` |
| Vector Index | `scripts/lib/vector-index.js` |
| Trigger Matcher | `scripts/lib/trigger-matcher.js` |
| Memory Database | `~/.claude/memory-index.sqlite` |

---

## 11. 💡 EXAMPLES

### Example 1: Feature Implementation

**Context**: Completed OAuth implementation

**Output**:
```
specs/015-auth-system/memory/
├── 07-12-25_14-23__auth-system.md
└── metadata.json
```

**Contains**: Session summary, JWT decision rationale, auth flow diagram, 45-message dialogue, vector embeddings

### Example 2: Finding Prior Context

```bash
# Search for authentication decisions
claude-mem vector "how did we implement OAuth"

# Result:
# [92%] specs/049-auth/memory/28-11-25_14-30__oauth.md
#       → OAuth callback flow with JWT tokens
```

---

## 12. ⚠️ COMMON MISTAKES

> **Quick Fixes**
> 1. **Missing spec folder**: `mkdir -p specs/###-feature/`
> 2. **Wrong script path**: Use `.claude/skills/workflows-save-context/scripts/generate-context.js`
> 3. **Arg 2 format**: Full folder name like `122-skill-standardization`, not just `122`
> 4. **Vector search empty**: Run `claude-mem rebuild` to generate embeddings

### Alignment Score

| Score | Meaning | Action |
|-------|---------|--------|
| 90-100% | Excellent match | Auto-selected |
| 70-89% | Good match | Auto-selected |
| 50-69% | Moderate match | Verify manually |
| 30-49% | Weak match | Select different folder |
| 0-29% | Poor match | Create new spec folder |

See [troubleshooting.md](./references/troubleshooting.md) for detailed issue resolution.

---

## 13. 📊 QUICK REFERENCE

**Invocation**: Say "save context" or use `/save_context`

**Menu Flow (v10.1)**: All `/save_context` invocations show an interactive menu first:
```
Tier 1: Save | Search | Recent | Manage Index
Tier 2 (Search): Natural language | Multi-concept
Tier 2 (Index): Health check | Fix problems | Rebuild
```
*Note: `AskUserQuestion` supports max 4 options per question, hence two-tier design.*

**Output**: `specs/###-feature/memory/{date}_{time}__{topic}.md`

**Semantic Search**: `claude-mem vector "your query"`

**Anchor Format**: `<!-- anchor: category-keywords-spec# -->`

**Key Data**:
```json
{
  "recent_context": [{ "request", "completed", "learning", "duration" }],
  "observations": [{ "type", "title", "narrative", "files", "facts" }],
  "user_prompts": [{ "prompt", "timestamp" }]
}
```

**Performance**: Save ~2-5s | Search <500ms | Triggers <50ms

**Script**: `.claude/skills/workflows-save-context/scripts/generate-context.js`

---

*This skill operates as a context preservation engine with semantic search, capturing dialogue, decisions, and visual flows while enabling intelligent retrieval across sessions.*
