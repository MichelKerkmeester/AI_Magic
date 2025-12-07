---
description: Save context & semantic memory operations - save, search, index management (v10.0)
argument-hint: "[action|query] [options]"
allowed-tools: Read, Write, Bash, AskUserQuestion
---

# Save Context

Unified command for conversation context saving and semantic memory operations: save sessions, search memory semantically, manage embeddings, and control the memory index.

---

```yaml
role: Memory & Context Preservation Specialist
purpose: Single entry point for all memory operations (v10.0 semantic memory)
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
    │   └─► MENU MODE: Check memory state → show context-aware menu
    │
    ├─► First word matches ACTION KEYWORD (case-insensitive)
    │   ├─► "save" | "now" | "this"        → SAVE ACTION (save current session)
    │   ├─► "search" | "find" | "vector"   → SEARCH ACTION (semantic search)
    │   ├─► "multi"                         → MULTI-CONCEPT SEARCH ACTION
    │   ├─► "rebuild" | "reindex"          → REBUILD ACTION (regenerate embeddings)
    │   ├─► "verify" | "check" | "status"  → VERIFY ACTION (check index integrity)
    │   ├─► "list-failed" | "failed"       → LIST-FAILED ACTION
    │   ├─► "retry"                         → RETRY ACTION (retry failed embeddings)
    │   └─► "recent" | "history"           → RECENT ACTION (show recent memories)
    │
    ├─► Spec folder pattern (NNN-name or just folder name)
    │   └─► SAVE ACTION (save to specified folder)
    │
    └─► Natural language query (2+ words)
        └─► SEARCH ACTION (semantic memory search)
```

---

## MENU MODE (No Arguments)

When called without arguments, provide a context-aware interactive menu.

### Step 1: Check Current State

Determine:
- Active spec folder (from `.spec-active` marker)
- Current conversation length
- Memory index status

### Step 2: Present State-Aware Menu

Use `AskUserQuestion` with options based on current state:

**Standard Menu:**
```yaml
question: "What would you like to do with memory?"
options:
  - label: "Save current context"
    description: "Save this session to memory with semantic indexing"
  - label: "Search memory"
    description: "Semantic search across all saved memories"
  - label: "View recent memories"
    description: "Show recently saved session summaries"
  - label: "Manage index"
    description: "Rebuild, verify, or retry failed embeddings"
```

### Step 3: Route to Selected Action

Based on user selection:
- **"Save current context"** → SAVE ACTION
- **"Search memory"** → Prompt for query, then SEARCH ACTION
- **"View recent memories"** → RECENT ACTION
- **"Manage index"** → Show sub-menu:
  ```yaml
  question: "Index management options:"
  options:
    - label: "Verify integrity"
      description: "Check for missing embeddings or orphaned entries"
    - label: "Rebuild index"
      description: "Regenerate all embeddings from source files"
    - label: "View failed"
      description: "Show embeddings that failed to generate"
    - label: "Retry failed"
      description: "Retry failed embedding generations"
  ```

---

## SAVE ACTION

**Triggers:** `save`, `now`, `this`, spec folder argument, or menu selection

### Instructions

1. **Determine target spec folder:**
   - If argument provided (e.g., "092-skill-md-template"): Use specified folder
   - If `.spec-active` marker exists: Use active spec folder
   - Otherwise: Calculate alignment scores, prompt if ambiguous

2. **Analyze conversation:**
   - Extract user requests and completed work
   - Identify key decisions and rationale
   - Note files created or modified
   - Detect conversation phases

3. **Create structured JSON summary:**
   See data structure in Instructions section below.

4. **Execute processing script:**
   ```bash
   echo '<JSON_DATA>' > /tmp/save-context-data.json
   node .claude/skills/workflows-save-context/scripts/generate-context.js /tmp/save-context-data.json
   rm /tmp/save-context-data.json
   ```

5. **Report results:**
   - Display generated file paths
   - Show embedding status (indexed/pending/failed)
   - Report extracted trigger phrases

### Output Format
```
💾 Saving Context...

   Spec folder: 011-semantic-memory-upgrade

   ✓ Memory file created
   ✓ Metadata saved
   ✓ Embedding generated (384 dimensions)
   ✓ Indexed as memory #42
   ✓ Extracted 8 trigger phrases

📁 Saved to: specs/011-semantic-memory-upgrade/memory/06-12-25_19-30__semantic-memory.md

STATUS=OK ACTION=save PATH=specs/011-semantic-memory-upgrade/memory/06-12-25_19-30__semantic-memory.md
```

---

## SEARCH ACTION

**Triggers:** `search`, `find`, `vector`, natural language query, or menu selection

### Extracting the Query

- If triggered by keyword: query = remaining arguments
  - `/save_context search authentication flow` → query = "authentication flow"
- If triggered by natural language: query = full arguments
  - `/save_context how did we implement OAuth` → query = "how did we implement OAuth"
- If triggered by menu: use `AskUserQuestion` to get query

### Instructions

1. **Validate query:**
   - If empty: `STATUS=FAIL ACTION=search ERROR="Query required"`

2. **Execute semantic search:**
   ```bash
   .claude/hooks/lib/load-related-context.sh vector "<query>"
   ```

3. **Format results:**
   - Show file paths with similarity scores
   - Display titles and spec folders
   - Include trigger phrases that matched

4. **Return:**
   `STATUS=OK ACTION=search RESULTS_COUNT=<n> QUERY="<query>"`

### Output Format
```
🔍 Semantic Search: "authentication implementation"

📊 Found 3 relevant memories

  [92%] 049-auth-system/memory/28-11-25_14-30__oauth-implementation.md
        "OAuth callback flow implementation with JWT tokens"
        Triggers: oauth, jwt authentication, callback flow

  [78%] 049-auth-system/memory/25-11-25_10-15__auth-decisions.md
        "Authentication strategy decisions and trade-offs"
        Triggers: authentication, session management

  [65%] 032-api/memory/20-11-25_09-00__api-security.md
        "API security layer with token validation"
        Triggers: api security, token validation

STATUS=OK ACTION=search RESULTS_COUNT=3 QUERY="authentication implementation"
```

---

## MULTI-CONCEPT SEARCH ACTION

**Triggers:** `multi` keyword

### Instructions

1. **Parse concepts:**
   - Extract 2-5 concepts from arguments
   - `/save_context multi oauth errors retry` → concepts = ["oauth", "errors", "retry"]

2. **Validate:**
   - Minimum 2 concepts required
   - Maximum 5 concepts allowed

3. **Execute multi-concept search:**
   ```bash
   .claude/hooks/lib/load-related-context.sh multi "concept1" "concept2" ...
   ```

4. **Format results:**
   - Show per-concept similarity scores
   - Display average similarity

### Output Format
```
🔍 Multi-Concept Search: oauth AND errors AND retry

📊 Found 2 memories matching ALL concepts

  [88%] 049-auth-system/memory/29-11-25_16-45__oauth-debugging.md
        Concepts: oauth=92%, errors=85%, retry=88%

  [72%] 049-auth-system/memory/27-11-25_11-20__auth-edge-cases.md
        Concepts: oauth=78%, errors=70%, retry=68%

STATUS=OK ACTION=multi RESULTS_COUNT=2 CONCEPTS=3
```

---

## REBUILD ACTION

**Triggers:** `rebuild`, `reindex`, or menu selection

### Instructions

1. **Show current state:**
   ```bash
   .claude/hooks/lib/load-related-context.sh verify
   ```

2. **Confirm rebuild:**
   Use `AskUserQuestion`:
   ```yaml
   question: "Rebuild will regenerate all embeddings. This may take several minutes. Proceed?"
   options:
     - label: "Yes, rebuild"
       description: "Regenerate embeddings for all memory files"
     - label: "Cancel"
       description: "Keep existing index"
   ```

3. **Execute rebuild:**
   ```bash
   .claude/hooks/lib/load-related-context.sh rebuild
   ```

### Output Format
```
🔄 Rebuilding Memory Index...

   Processing: specs/*/memory/*.md

   [1/25] 011-semantic-memory/memory/06-12-25_18-46__semantic-memory.md ✓
   [2/25] 049-auth-system/memory/28-11-25_14-30__oauth-implementation.md ✓
   ...

✅ Rebuild complete!
   Total files: 25
   Embeddings generated: 25
   Time: 12.3s

STATUS=OK ACTION=rebuild FILES=25 TIME=12.3s
```

---

## VERIFY ACTION

**Triggers:** `verify`, `check`, `status`, or menu selection

### Instructions

1. **Execute verify:**
   ```bash
   .claude/hooks/lib/load-related-context.sh verify
   ```

2. **Display results:**
   - Total indexed memories
   - Orphaned entries (index without file)
   - Missing embeddings (file without index)
   - Sync status

### Output Format
```
📊 Memory Index Status

   Total indexed: 42 memories
   Embeddings: 40 success, 2 failed
   Orphaned entries: 0
   Missing embeddings: 2

   Files needing attention:
   - specs/049-auth/memory/old-file.md (orphaned)
   - specs/050-api/memory/new-file.md (not indexed)

STATUS=OK ACTION=verify INDEXED=42 FAILED=2 ORPHANED=0 MISSING=2
```

---

## LIST-FAILED ACTION

**Triggers:** `list-failed`, `failed`, or menu selection

### Instructions

1. **Execute list-failed:**
   ```bash
   .claude/hooks/lib/load-related-context.sh list-failed
   ```

2. **Display results:**
   - File paths
   - Error reasons
   - Retry counts

### Output Format
```
❌ Failed Embeddings (2 files)

  specs/049-auth/memory/corrupt-file.md
    Error: Invalid markdown structure
    Attempts: 3 (permanent failure)

  specs/050-api/memory/large-file.md
    Error: Content exceeds token limit
    Attempts: 1 (will retry)

STATUS=OK ACTION=list-failed COUNT=2
```

---

## RETRY ACTION

**Triggers:** `retry`, or menu selection

### Instructions

1. **Execute retry:**
   ```bash
   .claude/hooks/lib/load-related-context.sh retry
   ```

2. **Display results:**
   - Processed count
   - Success/failure breakdown

### Output Format
```
🔄 Retrying Failed Embeddings...

   Processing 2 failed embeddings...

   ✓ specs/050-api/memory/large-file.md - SUCCESS
   ✗ specs/049-auth/memory/corrupt-file.md - STILL FAILING

✅ Retry complete!
   Processed: 2
   Succeeded: 1
   Failed: 1

STATUS=OK ACTION=retry PROCESSED=2 SUCCEEDED=1 FAILED=1
```

---

## RECENT ACTION

**Triggers:** `recent`, `history`, or menu selection

### Instructions

1. **Execute recent:**
   ```bash
   .claude/hooks/lib/load-related-context.sh recent 5
   ```

2. **Display results:**
   - Recent memory files with timestamps
   - Summaries and spec folders

### Output Format
```
📚 Recent Memories (last 5)

  [Today 18:46] 011-semantic-memory-upgrade
    "Semantic memory upgrade implementation"

  [Today 14:30] 049-auth-system
    "OAuth callback implementation"

  [Yesterday] 050-api-refactor
    "API endpoint restructuring"

STATUS=OK ACTION=recent COUNT=5
```

---

## Quick Reference

| Usage | Action |
|-------|--------|
| `/save_context` | Interactive menu based on current state |
| `/save_context save` | Save current session to memory |
| `/save_context 011-semantic-memory` | Save to specific spec folder |
| `/save_context search <query>` | Semantic memory search |
| `/save_context <natural query>` | Auto-detected semantic search |
| `/save_context multi <c1> <c2>` | Multi-concept AND search |
| `/save_context rebuild` | Rebuild all embeddings |
| `/save_context verify` | Check index integrity |
| `/save_context list-failed` | Show failed embeddings |
| `/save_context retry` | Retry failed embeddings |
| `/save_context recent` | Show recent memories |

---

## v10.0 Semantic Memory Features

This command now supports the v10.0 semantic memory upgrade:

- **Semantic Search**: Natural language queries using vector embeddings
- **Multi-Concept AND**: Find memories matching ALL specified concepts
- **Trigger Phrase Extraction**: Automatic extraction during save
- **Proactive Surfacing**: Memories auto-surface when triggers match
- **Local Processing**: All embeddings generated locally (MiniLM-L6-v2)

---

## Error Handling

| Condition | Action |
|-----------|--------|
| Empty conversation | Return `STATUS=FAIL ERROR="No context to save"` |
| Invalid spec folder | Suggest existing folders, prompt selection |
| Embedding generation fails | Mark for retry, save continues |
| sqlite-vec unavailable | Fall back to anchor-only mode |
| Search returns no results | Suggest broader query |

---

## Full Documentation

For comprehensive documentation including troubleshooting, performance characteristics, and advanced features, see:
`.claude/skills/workflows-save-context/SKILL.md`
