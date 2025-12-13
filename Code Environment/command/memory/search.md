---
description: Unified memory browser with search AND related navigation
argument-hint: "[query] [--tier:<tier>] [--type:<type>] [--use-decay:<bool>]"
allowed-tools: Read, Bash, mcp__semantic_memory__memory_search, mcp__semantic_memory__memory_load, mcp__semantic_memory__memory_match_triggers, mcp__semantic_memory__memory_list, mcp__semantic_memory__memory_stats
---

# Unified Memory Browser

Search conversation memories and navigate relationships - all in one command.

---

```yaml
role: Memory Browser Specialist
purpose: Unified search AND related navigation in one interactive experience
action: Route through dashboard → search → select → related → explore flow

operating_mode:
  workflow: interactive_browser
  workflow_compliance: MANDATORY
  workflow_execution: single_letter_actions
  approvals: none_required
  tracking: session_state
```

---

## MCP ENFORCEMENT MATRIX

**CRITICAL:** This command requires MCP tool calls. Failure handling is mandatory.

```
┌─────────────────┬─────────────────────────────┬──────────┬─────────────────┐
│ SCREEN          │ REQUIRED MCP CALLS          │ MODE     │ ON FAILURE      │
├─────────────────┼─────────────────────────────┼──────────┼─────────────────┤
│ HOME (Dashboard)│ memory_stats                │ PARALLEL │ Show error box  │
│                 │ memory_list(limit:5)        │          │ Show empty state│
│                 │ memory_match_triggers       │          │ Hide section    │
├─────────────────┼─────────────────────────────┼──────────┼─────────────────┤
│ SEARCH RESULTS  │ memory_search(query)        │ SINGLE   │ No results msg  │
├─────────────────┼─────────────────────────────┼──────────┼─────────────────┤
│ MEMORY DETAIL   │ memory_load(specFolder, id) │ SINGLE   │ Error + [b]ack  │
│                 │ memory_search(keywords)     │ THEN     │ Hide related    │
├─────────────────┼─────────────────────────────┼──────────┼─────────────────┤
│ FULL LOAD       │ memory_load(specFolder, id) │ SINGLE   │ Error + [b]ack  │
└─────────────────┴─────────────────────────────┴──────────┴─────────────────┘
```

**Tool Call Format (NATIVE MCP - NEVER Code Mode):**
```
mcp__semantic_memory__memory_stats({})
mcp__semantic_memory__memory_list({ limit: 5, sortBy: "created_at" })
mcp__semantic_memory__memory_match_triggers({ prompt: "<context>", limit: 3 })
mcp__semantic_memory__memory_search({ query: "<query>", limit: 10 })
mcp__semantic_memory__memory_load({ specFolder: "<folder>", memoryId: <id> })
```

---

## 1. CONTRACT

**Inputs:** `$ARGUMENTS` - Optional search query with optional filters
**Outputs:** Memory content, search results, or navigation state

### Argument Format

```
/memory/search [query] [--tier:<tier>] [--type:<type>] [--use-decay:<bool>]
```

### Filter Options

- `--tier:<tier>` — Filter by importance tier
  - Values: `critical`, `important`, `normal`, `temporary`, `deprecated`
  - Example: `--tier:critical` shows only critical memories
  - Can combine: `--tier:important,critical` shows both tiers

- `--type:<type>` — Filter by context type
  - Values: `research`, `implementation`, `decision`, `discovery`, `general`
  - Example: `--type:decision` shows only decision records
  - Can combine with --tier: `--tier:important --type:implementation`

- `--use-decay:<bool>` — Enable/disable decay scoring (default: true)
  - `--use-decay:false` for architecture queries needing equal historical weighting
  - When false, older memories rank equally with recent ones

### Filter Parsing

Parse `$ARGUMENTS` to extract:
```yaml
parsed_input:
  query: "<extracted_query_text>"
  filters:
    tier: ["critical"] | null       # Single or comma-separated values
    type: ["decision"] | null       # Single or comma-separated values
    use_decay: true | false         # Default: true
```

---

## 2. ROUTING LOGIC

```
$ARGUMENTS
    |
    +---> Empty (no args)
    |     └──> HOME SCREEN (Dashboard)
    |
    +---> Query provided (with optional filters)
          └──> SEARCH RESULTS SCREEN
```

---

## 3. HOME SCREEN (DASHBOARD)

When called without arguments, show an interactive dashboard:

### Step 1: Gather Dashboard Data (PARALLEL MCP CALLS)

Execute these MCP calls in parallel:

```
# Call 1: Get system statistics
mcp__semantic_memory__memory_stats({})

# Call 2: Get recent memories
mcp__semantic_memory__memory_list({
  limit: 5,
  sortBy: "created_at"
})

# Call 3: Get suggested memories (based on current context)
mcp__semantic_memory__memory_match_triggers({
  prompt: "<current_conversation_context>",
  limit: 3
})
```

### Step 2: Display Dashboard

```
┌────────────────────────────────────────────────────────────────┐
│                      MEMORY DASHBOARD                          │
├────────────────────────────────────────────────────────────────┤
│                                                                │
│  QUICK STATS [via: memory_stats]                               │
│  ─────────────────────────────────────────                     │
│  Total memories: <count>                                       │
│  By tier: <constitutional>⭐ <critical>!! <important>!         │
│           <normal>- <temporary>~ <deprecated>x                 │
│  Last saved: <relative_time>                                   │
│  Health: <status>                                              │
│                                                                │
│  RECENT MEMORIES [via: memory_list]                            │
│  ─────────────────────────────────────────                     │
│  [1] <title> (<tier>) - <spec_folder> - <age>                  │
│  [2] <title> (<tier>) - <spec_folder> - <age>                  │
│  [3] <title> (<tier>) - <spec_folder> - <age>                  │
│  [4] <title> (<tier>) - <spec_folder> - <age>                  │
│  [5] <title> (<tier>) - <spec_folder> - <age>                  │
│                                                                │
│  SUGGESTED FOR YOU [via: memory_match_triggers]                │
│  ─────────────────────────────────────────                     │
│  [a] <title> - <match_reason>                                  │
│  [b] <title> - <match_reason>                                  │
│                                                                │
├────────────────────────────────────────────────────────────────┤
│  [1-5] load recent │ [a-b] load suggested │ [s]earch           │
│  [f]ilter by tier  │ [c]leanup            │ [q]uit             │
└────────────────────────────────────────────────────────────────┘
```

### Step 3: Handle Selection

Present as inline prompt:
```
Select [1-5] recent, [a-b] suggested, [s]earch, [f]ilter, [c]leanup, or [q]uit:
```

**Action Routing:**
- Number 1-5 → MEMORY DETAIL SCREEN (for selected recent memory)
- "a", "b" → MEMORY DETAIL SCREEN (for suggested memory)
- "s" or "S" → SEARCH PROMPT SCREEN
- "f" or "F" → TIER FILTER MENU (then refresh dashboard)
- "c" or "C" → Route to `/memory/cleanup`
- "q" or "Q" → Exit with `STATUS=OK ACTION=dashboard`

### Empty State Display

If no memories exist:

```
┌────────────────────────────────────────────────────────────────┐
│                      MEMORY DASHBOARD                          │
├────────────────────────────────────────────────────────────────┤
│                                                                │
│  QUICK STATS [via: memory_stats]                               │
│  ─────────────────────────────────────────                     │
│  Total memories: 0                                             │
│  Health: No memories indexed yet                               │
│                                                                │
│  GETTING STARTED                                               │
│  ─────────────────────────────────────────                     │
│  No memories saved yet. To create your first memory:           │
│                                                                │
│  1. Work in a spec folder (specs/###-name/)                    │
│  2. Run /memory/save when you want to preserve context         │
│  3. Your conversation will be indexed for future search        │
│                                                                │
├────────────────────────────────────────────────────────────────┤
│  [q]uit                                                        │
└────────────────────────────────────────────────────────────────┘
```

### Error State Display

If MCP calls fail:

```
┌────────────────────────────────────────────────────────────────┐
│                      MEMORY DASHBOARD                          │
├────────────────────────────────────────────────────────────────┤
│                                                                │
│  ⚠ Unable to load dashboard data                               │
│                                                                │
│  Error: <error_message>                                        │
│                                                                │
│  Troubleshooting:                                              │
│  - Check if semantic memory MCP is running                     │
│  - Verify database exists at expected location                 │
│  - Try /memory/status for diagnostics                          │
│                                                                │
├────────────────────────────────────────────────────────────────┤
│  [r]etry │ [s]earch (fallback) │ [q]uit                        │
└────────────────────────────────────────────────────────────────┘
```

---

## 4. SEARCH PROMPT SCREEN

When user presses [s] from dashboard, show search input:

```
Memory Search
─────────────────────────────────────────
Enter search query (with optional filters):

Filter options:
  --tier:<critical|important|normal|temporary|deprecated>
  --type:<research|implementation|decision|discovery|general>
  --use-decay:<true|false>

─────────────────────────────────────────
[b]ack to dashboard | [q]uit
```

**Instructions:**
1. Request user input for search query
2. If user provides query → Parse filters → Route to SEARCH RESULTS SCREEN
3. If user enters "b" → Return to HOME SCREEN (dashboard)
4. If user enters "q" → Exit with `STATUS=CANCELLED`

---

## 5. SEARCH RESULTS SCREEN

Execute search and display numbered results:

### Step 1: Execute Semantic Search

Call MCP tool directly with parsed filters:
```
mcp__semantic_memory__memory_search({
  query: "<user_query>",
  limit: 10
})
```

### Step 2: Apply Filters (Post-Processing)

If `--tier` specified:
- Filter results where `tier` matches any value in the filter list

If `--type` specified:
- Filter results where `type` matches any value in the filter list

If `--use-decay:false`:
- Sort by raw similarity score without time decay weighting

### Step 3: Display Results

```
Memory Search: "<query>"
─────────────────────────────────────────
Active Filters: tier=<tier|all> | type=<type|all> | decay=<on|off>

Results (N found):

| # | Score | Tier     | Type           | Title                      | Spec Folder       |
|---|-------|----------|----------------|----------------------------|-------------------|
| 1 | 92%   | critical | implementation | OAuth Implementation       | 049-auth-system   |
| 2 | 85%   | important| decision       | JWT token handling         | 049-auth-system   |
| 3 | 78%   | normal   | research       | Session management         | 032-api-security  |

─────────────────────────────────────────
[1-N] select | [n]ew search | [t]ier | [y]pe | [d]ecay | [q]uit
```

### Step 4: Handle Selection

Present as inline numbered menu:
```
Select result [1-N], [n]ew, [t]ier, [y]pe, [d]ecay, or [q]uit:
```

**Action Routing:**
- Number 1-N → MEMORY DETAIL SCREEN (for selected memory)
- "n" or "N" → Return to SEARCH PROMPT SCREEN
- "t" or "T" → TIER FILTER MENU
- "y" or "Y" → TYPE FILTER MENU
- "d" or "D" → Toggle decay on/off, re-run search
- "q" or "Q" → Exit with `STATUS=OK ACTION=browse`

### No Results Display

```
Memory Search: "<query>"
─────────────────────────────────────────
Active Filters: tier=<tier|all> | type=<type|all> | decay=<on|off>

No memories found matching your query and filters.

Suggestions:
- Try broader keywords
- Remove or adjust filters
- Use different terms
- Check for typos

─────────────────────────────────────────
[n]ew search | [t]ier | [y]pe | [d]ecay | [q]uit
```

---

## 6. QUICK FILTERS

### Tier Filter Menu

When user presses `[t]`:

```
Tier Filter
─────────────────────────────────────────
Current: <current_tier_filter|all>

Select tier(s) to filter:

 [1] critical   - Architectural decisions, core patterns
 [2] important  - Key implementations, significant bugs
 [3] normal     - General context, routine work
 [4] temporary  - Short-term, WIP content
 [5] deprecated - Outdated, superseded content
 [a] all        - Clear tier filter (show all)

Enter number(s) comma-separated (e.g., "1,2") or [b]ack:
```

**Action:**
- Parse selection, update `filters.tier`
- Re-run search with new filter
- Return to SEARCH RESULTS SCREEN

### Type Filter Menu

When user presses `[y]`:

```
Type Filter
─────────────────────────────────────────
Current: <current_type_filter|all>

Select type(s) to filter:

 [1] research       - Investigation, exploration findings
 [2] implementation - Code changes, feature builds
 [3] decision       - Choices made, rationale recorded
 [4] discovery      - Bugs found, insights gained
 [5] general        - Miscellaneous context
 [a] all            - Clear type filter (show all)

Enter number(s) comma-separated (e.g., "1,3") or [b]ack:
```

**Action:**
- Parse selection, update `filters.type`
- Re-run search with new filter
- Return to SEARCH RESULTS SCREEN

### Decay Toggle

When user presses `[d]`:
- Toggle `filters.use_decay` between true/false
- Display: `Decay scoring: ON → OFF` or `Decay scoring: OFF → ON`
- Re-run search with new setting
- Return to SEARCH RESULTS SCREEN

---

## 7. MEMORY DETAIL SCREEN

Show preview and related memories:

### Step 1: Load Memory Preview

Call MCP tool:
```
mcp__semantic_memory__memory_load({
  specFolder: "<spec_folder>",
  memoryId: <id>
})
```

### Step 2: Search for Related Memories

Call MCP tool with the memory's title/topic as query:
```
mcp__semantic_memory__memory_search({
  query: "<memory_title_or_keywords>",
  limit: 5
})
```

Filter out the current memory from results.

### Step 3: Display Detail View

```
<Memory Title>
─────────────────────────────────────────
Spec: <spec-folder>
Date: <created_at>
Tier: <tier>
Type: <type>

Preview:
<First 300 characters of content...>

─────────────────────────────────────────
Related Memories:

| # | Score | Tier     | Type       | Title                      |
|---|-------|----------|------------|----------------------------|
| a | 92%   | critical | decision   | Related Title 1            |
| b | 87%   | normal   | research   | Related Title 2            |
| c | 81%   | important| impl.      | Related Title 3            |

─────────────────────────────────────────
[a-c] explore | [s]earch | [b]ack | [l]oad full | [q]uit
```

### Step 4: Handle Selection

Present as inline numbered menu:
```
[a-c] explore | [s]earch | [b]ack | [l]oad full | [q]uit:
```

**Action Routing:**
- "a", "b", "c" → MEMORY DETAIL SCREEN (for related memory)
- "s" or "S" → Return to SEARCH PROMPT SCREEN
- "b" or "B" → Return to SEARCH RESULTS SCREEN (previous results)
- "l" or "L" → FULL LOAD ACTION
- "q" or "Q" → Exit with `STATUS=OK ACTION=browse`

---

## 8. FULL LOAD ACTION

Load complete memory content:

### Instructions

1. Call MCP tool:
   ```
   mcp__semantic_memory__memory_load({
     specFolder: "<spec_folder>",
     memoryId: <id>
   })
   ```

2. Display full content:
   ```
   Full Memory: <Title>
   ─────────────────────────────────────────
   Spec: <spec-folder>
   File: <file_path>
   Date: <created_at>
   Tier: <tier>
   Type: <type>
   ─────────────────────────────────────────

   <full_content>

   ─────────────────────────────────────────
   [s]earch | [b]ack | [q]uit
   ```

3. Handle selection:
   - "s" or "S" → Return to SEARCH PROMPT SCREEN
   - "b" or "B" → Return to MEMORY DETAIL SCREEN
   - "q" or "Q" → Exit with `STATUS=OK ACTION=load MEMORY=<title>`

---

## 9. MULTI-CONCEPT SEARCH

When user provides multiple distinct concepts (2-5 words with "AND" or "+"):

### Detection

- Query contains " AND " (case-insensitive)
- Query contains " + "
- Example: "oauth AND jwt AND errors"

### Instructions

Parse concepts and call:
```
mcp__semantic_memory__memory_search({
  concepts: ["oauth", "jwt", "errors"],
  limit: 10
})
```

### Display Format

```
Multi-Concept Search: oauth AND jwt AND errors
─────────────────────────────────────────
Active Filters: tier=<tier|all> | type=<type|all> | decay=<on|off>

Results (N found matching ALL concepts):

| # | Avg   | Tier     | Type       | Title                      | Concept Scores          |
|---|-------|----------|------------|----------------------------|-------------------------|
| 1 | 88%   | critical | impl.      | Auth Error Handling        | oauth:92 jwt:85 err:88  |
| 2 | 72%   | normal   | research   | Token Validation           | oauth:78 jwt:70 err:68  |

─────────────────────────────────────────
[1-N] select | [n]ew search | [t]ier | [y]pe | [d]ecay | [q]uit
```

---

## 10. STATE MANAGEMENT

Track navigation state for [b]ack action:

```yaml
browser_state:
  current_screen: search_prompt | search_results | memory_detail | full_load
  last_query: "<query>"
  last_results: [<result_list>]
  current_memory: <memory_object>
  navigation_stack: [<screen_history>]
  filters:
    tier: ["critical", "important"] | null
    type: ["decision"] | null
    use_decay: true | false
```

When user presses [b]ack:
- Pop from navigation_stack
- Restore previous screen state
- If stack empty, go to SEARCH PROMPT SCREEN

---

## 11. ERROR HANDLING

| Condition             | Action                                    |
| --------------------- | ----------------------------------------- |
| MCP tool fails        | Show error, offer [r]etry or [q]uit       |
| Memory not found      | Show message, return to search results    |
| Invalid selection     | Re-prompt with valid options              |
| Empty query           | Re-prompt for query                       |
| No related memories   | Show "No related memories found"          |
| Invalid filter value  | Show valid options, re-prompt             |

### Error Display Format

```
Error
─────────────────────────────────────────
<error_message>

─────────────────────────────────────────
[r]etry | [s]earch | [q]uit
```

---

## 12. QUICK REFERENCE

| Input                     | Action                              |
| ------------------------- | ----------------------------------- |
| `/memory/search`          | Open browser, prompt for query      |
| `/memory/search q`        | Search for "q" immediately          |
| `/memory/search q --tier:critical` | Search with tier filter    |
| `/memory/search q --type:decision` | Search with type filter    |
| `/memory/search q --use-decay:false` | Search without decay     |
| `1`, `2`, `3`...          | Select numbered result              |
| `a`, `b`, `c`...          | Explore related memory              |
| `n`                       | New search                          |
| `s`                       | Search (from detail/full view)      |
| `b`                       | Back to previous screen             |
| `l`                       | Load full memory content            |
| `t`                       | Toggle tier filter menu             |
| `y`                       | Toggle type filter menu             |
| `d`                       | Toggle decay on/off                 |
| `q`                       | Quit browser                        |

---

## 13. DISPLAY FORMATTING

### Results Format

All results display in table format with columns:

```
| # | Score | Tier | Type | Title | Spec Folder |
```

### Tier Display Values

| Tier       | Display    |
|------------|------------|
| critical   | critical   |
| important  | important  |
| normal     | normal     |
| temporary  | temporary  |
| deprecated | deprecated |

### Type Display Values

| Type           | Display (short) |
|----------------|-----------------|
| research       | research        |
| implementation | impl.           |
| decision       | decision        |
| discovery      | discovery       |
| general        | general         |

### Similarity Score Display

Convert similarity scores to percentages:
- Raw score 0.92 → "92%"
- Raw score 0.85 → "85%"

### Title Truncation

- Max title length: 28 characters
- If longer: truncate and add "..."

### Column Alignment

Use consistent spacing for visual alignment in table format.

---

## 14. KEYBOARD SHORTCUTS SUMMARY

**Universal (all screens):**
- `q` - Quit browser

**Search Results:**
- `1-9` - Select result
- `n` - New search
- `t` - Tier filter menu
- `y` - Type filter menu
- `d` - Toggle decay

**Memory Detail:**
- `a-e` - Explore related (up to 5)
- `s` - New search
- `b` - Back to results
- `l` - Load full content

**Full Load:**
- `s` - New search
- `b` - Back to detail view

**Filter Menus:**
- `1-5` - Select filter value
- `a` - Select all (clear filter)
- `b` - Back without changing

---

## 15. EXAMPLE SESSION

```
User: /memory/search auth flow --tier:critical,important

Memory Search: "auth flow"
─────────────────────────────────────────
Active Filters: tier=critical,important | type=all | decay=on

Results (2 found):

| # | Score | Tier     | Type       | Title                      | Spec Folder       |
|---|-------|----------|------------|----------------------------|-------------------|
| 1 | 92%   | critical | impl.      | OAuth Implementation       | 049-auth-system   |
| 2 | 85%   | important| decision   | JWT token handling         | 049-auth-system   |

─────────────────────────────────────────
[1-2] select | [n]ew search | [t]ier | [y]pe | [d]ecay | [q]uit

User: t

Tier Filter
─────────────────────────────────────────
Current: critical,important

Select tier(s) to filter:

 [1] critical   - Architectural decisions, core patterns
 [2] important  - Key implementations, significant bugs
 [3] normal     - General context, routine work
 [4] temporary  - Short-term, WIP content
 [5] deprecated - Outdated, superseded content
 [a] all        - Clear tier filter (show all)

Enter number(s) comma-separated (e.g., "1,2") or [b]ack:

User: a

Memory Search: "auth flow"
─────────────────────────────────────────
Active Filters: tier=all | type=all | decay=on

Results (3 found):

| # | Score | Tier     | Type       | Title                      | Spec Folder       |
|---|-------|----------|------------|----------------------------|-------------------|
| 1 | 92%   | critical | impl.      | OAuth Implementation       | 049-auth-system   |
| 2 | 85%   | important| decision   | JWT token handling         | 049-auth-system   |
| 3 | 78%   | normal   | research   | Session management         | 032-api-security  |

─────────────────────────────────────────
[1-3] select | [n]ew search | [t]ier | [y]pe | [d]ecay | [q]uit

User: 1

OAuth Implementation
─────────────────────────────────────────
Spec: 049-auth-system
Date: 2024-11-28 14:30
Tier: critical
Type: implementation

Preview:
Implemented OAuth 2.0 callback flow with JWT token generation.
Key decisions: Used RS256 for signing, 15-minute access token
expiry, 7-day refresh token rotation...

─────────────────────────────────────────
Related Memories:

| # | Score | Tier     | Type       | Title                      |
|---|-------|----------|------------|----------------------------|
| a | 92%   | important| impl.      | JWT token storage          |
| b | 87%   | normal   | research   | Callback URL handling      |
| c | 81%   | normal   | discovery  | Auth error patterns        |

─────────────────────────────────────────
[a-c] explore | [s]earch | [b]ack | [l]oad full | [q]uit

User: l

Full Memory: OAuth Implementation
─────────────────────────────────────────
Spec: 049-auth-system
File: specs/049-auth-system/memory/28-11-25_14-30__oauth.md
Date: 2024-11-28 14:30
Tier: critical
Type: implementation
─────────────────────────────────────────

<full content displayed here>

─────────────────────────────────────────
[s]earch | [b]ack | [q]uit

User: q

STATUS=OK ACTION=browse MEMORIES_VIEWED=1 QUERY="auth flow"
```

---

## 16. RELATED COMMANDS

- `/memory/save` - Save current conversation context
- `/memory/status` - Quick health check and statistics
- `/memory/triggers` - View and manage trigger phrases
- `/memory/cleanup` - Clean up old or unused memories

---

## 17. FULL DOCUMENTATION

For comprehensive documentation:
`.opencode/skills/workflows-memory/SKILL.md`
