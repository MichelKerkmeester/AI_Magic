---
description: Semantic code search - find code by intent, manage indexer
argument-hint: "[action|query] [options]"
allowed-tools: Bash(codesql:*), mcp__semantic-search__semantic_search, AskUserQuestion
---

# Semantic Search

Unified command for semantic code search and index management: search your codebase by intent, manage the indexer, and control the watcher process.

---

```yaml
role: Semantic Code Index Controller
purpose: Single entry point for all codebase indexing operations
action: Route to appropriate action based on intelligent argument parsing

operating_mode:
  workflow: smart_routing
  workflow_compliance: MANDATORY
  workflow_execution: context_aware
  approvals: only_for_destructive_actions
  tracking: action_and_result
  validation: state_aware_routing
```

---

## Contract

**Inputs:** `$ARGUMENTS` — Optional action keyword, search query, or options
**Outputs:** `STATUS=<OK|FAIL|CANCELLED> ACTION=<action_performed> [additional_context]`

---

## Routing Logic

Parse `$ARGUMENTS` and route using this decision tree:

```
$ARGUMENTS
    │
    ├─► Empty (no args)
    │   └─► MENU MODE: Check status → show context-aware menu
    │
    ├─► First word matches ACTION KEYWORD (case-insensitive)
    │   ├─► "start" | "on" | "init"       → START ACTION
    │   ├─► "stop" | "off" | "kill"       → STOP ACTION
    │   ├─► "stats" | "status" | "info"   → STATS ACTION
    │   ├─► "search" | "find" | "query"   → SEARCH ACTION (use remaining args as query)
    │   ├─► "reset" | "clear" | "wipe"    → RESET ACTION
    │   └─► "history" | "commits"         → HISTORY ACTION
    │
    ├─► Looks like NATURAL LANGUAGE QUERY
    │   Detection patterns:
    │   - Contains question words: how, where, what, when, why, which, is, are, does, can
    │   - Has 2+ words
    │   - Contains code terms: function, class, component, handler, method, validation, etc.
    │   - Contains quotes
    │   └─► SEARCH ACTION (use full args as query)
    │
    └─► Single ambiguous word (not a keyword)
        └─► SEARCH ACTION (assume search intent - most common use case)
```

---

## MENU MODE (No Arguments)

When called without arguments, provide a context-aware interactive menu.

### Step 1: Check Current State

```bash
codesql -stats 2>/dev/null
```

Parse output to determine:
- `is_running`: Is watcher currently active?
- `tracked_files`: Number of indexed files
- `indexed_commits`: Number of indexed commits
- `collection_id`: Current collection identifier

### Step 2: Present State-Aware Menu

Use `AskUserQuestion` with options based on current state:

**If indexer is NOT running:**
```yaml
question: "Codebase indexer is not running. What would you like to do?"
options:
  - label: "Start indexer"
    description: "Begin background file watching and indexing"
  - label: "View stats"
    description: "Show last known indexing statistics"
  - label: "Reset index"
    description: "Delete all indexed data (destructive)"
```

**If indexer IS running:**
```yaml
question: "Indexer is running (N files tracked). What would you like to do?"
options:
  - label: "Search codebase"
    description: "Semantic search using natural language"
  - label: "View stats"
    description: "Show current indexing statistics"
  - label: "Index git history"
    description: "Add commit history for temporal search"
  - label: "Stop indexer"
    description: "Stop the background watcher process"
```

> **Note:** For destructive operations like reset, use `/semantic_search reset` directly.

### Step 3: Route to Selected Action

Based on user selection, execute the corresponding action section below.

**If "Search codebase" selected:** Prompt for query using AskUserQuestion:
```yaml
question: "What would you like to search for?"
options:
  - label: "Enter query"
    description: "Type your natural language search query"
```
Then route to SEARCH ACTION with the provided query.

**If "Index git history" selected:** Prompt for count using AskUserQuestion:
```yaml
question: "How many commits should I index?"
options:
  - label: "Last 10 commits"
    description: "Quick indexing of recent history"
  - label: "Last 50 commits"
    description: "Moderate history coverage"
  - label: "Last 100 commits"
    description: "Comprehensive history (slower)"
```
Then route to HISTORY ACTION with the selected count.

---

## START ACTION

**Triggers:** `start`, `on`, `init`, or menu selection

### Instructions

1. **Load environment variables:**
   ```bash
   set -a && source .codebase/.env && set +a
   ```
   - If `.codebase/.env` doesn't exist: `STATUS=FAIL ERROR="Missing .codebase/.env - run setup first"`

2. **Check if already running:**
   ```bash
   codesql -stats
   ```
   - If status shows "watching", return early:
     `STATUS=OK ACTION=start RESULT=already_running`

3. **Start the indexer:**
   ```bash
   codesql -start
   ```

4. **Verify startup:**
   ```bash
   codesql -stats
   ```
   - Extract collection ID and confirm watcher is running

5. **Return:**
   - Success: `STATUS=OK ACTION=start RESULT=started COLLECTION=<id>`
   - Already running: `STATUS=OK ACTION=start RESULT=already_running COLLECTION=<id>`
   - Failed: `STATUS=FAIL ACTION=start ERROR="<message>"`

### Output Format
```
🚀 Starting Codebase Indexer...

✅ Indexer started successfully!
   Collection: codebase-xxxxx
   Status: watching

Use `/semantic_search <your query>` to search, or `/semantic_search stats` to monitor progress.

STATUS=OK ACTION=start RESULT=started COLLECTION=codebase-xxxxx
```

---

## STOP ACTION

**Triggers:** `stop`, `off`, `kill`, or menu selection

### Instructions

1. **Check current status:**
   ```bash
   codesql -stats
   ```
   - If not running, return early: `STATUS=OK ACTION=stop RESULT=not_running`

2. **Stop the watcher:**
   ```bash
   codesql -stop
   ```

3. **Verify shutdown:**
   ```bash
   codesql -stats
   ```
   - Confirm watcher is no longer "watching"

4. **Return:**
   - Success: `STATUS=OK ACTION=stop RESULT=stopped`
   - Was not running: `STATUS=OK ACTION=stop RESULT=not_running`
   - Failed: `STATUS=FAIL ACTION=stop ERROR="<message>"`

### Output Format
```
🛑 Stopping Codebase Indexer...

✅ Indexer stopped successfully!
   Indexed data preserved (251 files tracked)

Use `/semantic_search start` to resume indexing.

STATUS=OK ACTION=stop RESULT=stopped
```

---

## STATS ACTION

**Triggers:** `stats`, `status`, `info`, or menu selection

### Instructions

1. **Run stats command:**
   ```bash
   codesql -stats
   ```

2. **Parse and display:**
   - Workspace path
   - Collection ID
   - Tracked files count
   - Indexed commits count
   - Watcher status

3. **Return:**
   `STATUS=OK ACTION=stats TRACKED_FILES=<n> INDEXED_COMMITS=<n> WATCHER=<status>`

### Output Format
```
📊 Codebase Index Statistics

   Workspace:       /path/to/project
   Collection:      codebase-xxxxx
   Tracked files:   251
   Indexed commits: 50
   Watcher status:  watching

STATUS=OK ACTION=stats TRACKED_FILES=251 INDEXED_COMMITS=50 WATCHER=watching
```

---

## SEARCH ACTION

**Triggers:** `search`, `find`, `query`, natural language query, or menu selection

### Extracting the Query

- If triggered by keyword: query = remaining arguments after keyword
  - `/semantic_search search authentication middleware` → query = "authentication middleware"
- If triggered by natural language detection: query = full arguments
  - `/semantic_search how is form validation handled` → query = "how is form validation handled"
- If triggered by menu: use `AskUserQuestion` to get query

### Check for --refined Flag

- If `--refined` present in arguments, set `refined_answer: true`
- Remove flag from query string before searching

### Instructions

1. **Validate query:**
   - If empty after parsing: `STATUS=FAIL ACTION=search ERROR="Query required"`

2. **Check indexer state:**
   ```bash
   codesql -stats
   ```
   - If no tracked files, warn user and suggest `/semantic_search start`

3. **Execute semantic search:**
   Call MCP tool: `mcp__semantic-search__semantic_search`
   ```yaml
   workspace_path: <current_workspace>
   query: <extracted_query>
   max_results: 20
   refined_answer: <true if --refined flag present>
   ```

4. **Format results:**
   - Show file paths with line numbers: `file_path:line_number`
   - If refined mode, show LLM analysis first
   - Count unique files found

5. **Return:**
   `STATUS=OK ACTION=search RESULTS_COUNT=<n> QUERY="<query>"`

### Output Format
```
🔍 Searching: "authentication middleware"

📊 Found 5 relevant chunks across 3 files

src/auth/middleware.js:45-67
  // Authentication middleware
  function authMiddleware(req, res, next) { ... }

src/routes/protected.js:12-28
  // Protected route handler
  router.use(authMiddleware);

[Additional results...]

STATUS=OK ACTION=search RESULTS_COUNT=3 QUERY="authentication middleware"
```

---

## RESET ACTION

**Triggers:** `reset`, `clear`, `wipe`, or menu selection

⚠️ **DESTRUCTIVE OPERATION** - Requires confirmation

### Check for --confirm Flag

- If `--confirm` present: skip confirmation prompt
- If not present: require explicit user confirmation

### Instructions

1. **Show current state:**
   ```bash
   codesql -stats
   ```
   Display what will be deleted.

2. **Require confirmation (if no --confirm flag):**
   Use `AskUserQuestion`:
   ```yaml
   question: "⚠️ This will DELETE all indexed data (N files, N commits). Proceed?"
   options:
     - label: "Yes, delete everything"
       description: "Permanently remove all indexed data"
     - label: "No, cancel"
       description: "Keep existing index"
   ```
   - If cancelled: `STATUS=CANCELLED ACTION=reset`

3. **Stop watcher if running:**
   ```bash
   codesql -stop
   ```

4. **Execute reset:**
   ```bash
   codesql -full-reset
   ```

5. **Verify reset:**
   ```bash
   codesql -stats
   ```
   - Confirm 0 tracked files, 0 indexed commits

6. **Return:**
   - Success: `STATUS=OK ACTION=reset RESULT=completed`
   - Cancelled: `STATUS=CANCELLED ACTION=reset`
   - Failed: `STATUS=FAIL ACTION=reset ERROR="<message>"`

### Output Format
```
⚠️  Resetting Codebase Index...

   Deleting: 251 tracked files, 50 indexed commits

   Stopping watcher... ✓
   Deleting vectors... ✓
   Clearing cache... ✓
   Resetting state... ✓

✅ Index reset complete!

Use `/semantic_search start` to rebuild the index.

STATUS=OK ACTION=reset RESULT=completed
```

---

## HISTORY ACTION

**Triggers:** `history`, `commits`, or menu selection

### Extracting Count

- Default: 10 commits
- If number provided after keyword: use that count
  - `/semantic_search history 50` → count = 50
- If triggered by menu: optionally ask for count or use default

### Instructions

1. **Load environment variables:**
   ```bash
   set -a && source .codebase/.env && set +a
   ```

2. **Validate git repository:**
   ```bash
   git rev-parse --git-dir 2>/dev/null
   ```
   - If not a git repo: `STATUS=FAIL ACTION=history ERROR="Not a git repository"`

3. **Parse count:**
   - Extract number from arguments
   - Validate positive integer
   - Default to 10 if not provided

4. **Index commit history:**
   ```bash
   codesql -index-history <count>
   ```

5. **Verify completion:**
   ```bash
   codesql -stats
   ```
   - Confirm indexed commits count increased

6. **Return:**
   `STATUS=OK ACTION=history INDEXED_COMMITS=<count>`

### Output Format
```
📚 Indexing Git History (last 50 commits)...

   Processing commits:
   ✓ fd152ab - Button + Fluid Responsive
   ✓ 2b0ff07 - Page Loader, Skills
   ✓ a8dd584 - Page Loader updates
   [... more commits ...]

✅ Successfully indexed 50 commits!

You can now search code history:
  /semantic_search "when was the button component added"

STATUS=OK ACTION=history INDEXED_COMMITS=50
```

---

## Quick Reference

| Usage | Action |
|-------|--------|
| `/semantic_search` | Interactive menu based on current state |
| `/semantic_search start` | Start the background file watcher |
| `/semantic_search stop` | Stop the background file watcher |
| `/semantic_search stats` | Show indexing statistics |
| `/semantic_search <query>` | Semantic search (auto-detected) |
| `/semantic_search search <query>` | Explicit semantic search |
| `/semantic_search search <query> --refined` | Search with LLM analysis |
| `/semantic_search history` | Index last 10 git commits |
| `/semantic_search history 50` | Index last 50 git commits |
| `/semantic_search reset` | Reset index (with confirmation) |
| `/semantic_search reset --confirm` | Reset index (skip confirmation) |

---

## Error Handling

| Error | Response |
|-------|----------|
| `.codebase/.env` missing | Suggest running initial setup |
| `codesql` not in PATH | Show installation instructions |
| MCP server unavailable | Show MCP configuration help |
| Not a git repository | Skip history-related features |
| Empty search query | Prompt for query or show menu |
| Indexer not running (for search) | Offer to start it first |

---

## Troubleshooting

- **"Unable to infer embedder provider"**: Environment not loaded. The command sources `.codebase/.env` automatically.
- **"Invalid API key" (401)**: Update `EMBED_API_KEY` in `.codebase/.env`
- **Search returns no results**: Run `/semantic_search stats` to verify files are indexed
- **Watcher won't stop**: Check for orphaned processes in `.codebase/watcher.pid`
- **Reset fails**: Manually delete `.codebase/` directory as last resort

---

## Notes

- **Primary use case is search** - the command is optimized for this
- **State-aware** - behavior adapts based on whether indexer is running
- **Safe defaults** - destructive actions always require confirmation
- **Backwards compatible** - explicit keywords always work as expected
