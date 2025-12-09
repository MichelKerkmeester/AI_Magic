---
description: Unified memory browser with search AND related navigation
argument-hint: "[query]"
allowed-tools: Read, Bash, mcp__semantic_memory__memory_search, mcp__semantic_memory__memory_load, mcp__semantic_memory__memory_match_triggers, AskUserQuestion
---

# Unified Memory Browser

Search conversation memories and navigate relationships - all in one command.

---

```yaml
role: Memory Browser Specialist
purpose: Unified search AND related navigation in one interactive experience
action: Route through search → select → related → explore flow

operating_mode:
  workflow: interactive_browser
  workflow_compliance: MANDATORY
  workflow_execution: single_letter_actions
  approvals: none_required
  tracking: session_state
```

---

## 1. 📝 CONTRACT

**Inputs:** `$ARGUMENTS` - Optional search query
**Outputs:** Memory content, search results, or navigation state

---

## 2. 🔀 ROUTING LOGIC

```
$ARGUMENTS
    |
    +---> Empty (no args)
    |     └──> SEARCH PROMPT SCREEN
    |
    +---> Query provided
          └──> SEARCH RESULTS SCREEN
```

---

## 3. 🔍 SEARCH PROMPT SCREEN

When called without arguments, show this:

```
Memory Browser
--------------
Search: _

Enter search query, then press Enter.

[q]uit
```

**Instructions:**
1. Use `AskUserQuestion` to get search query:
   ```yaml
   question: "Memory Browser\n─────────────────\nSearch:"
   options: []
   allow_free_form: true
   ```
2. If user provides query → Route to SEARCH RESULTS SCREEN
3. If user enters "q" → Exit with `STATUS=CANCELLED`

---

## 4. 📊 SEARCH RESULTS SCREEN

Execute search and display numbered results:

### Step 1: Execute Semantic Search

Call MCP tool directly:
```
mcp__semantic_memory__memory_search({
  query: "<user_query>",
  limit: 10
})
```

### Step 2: Display Results

```
Memory Search: "<query>"
─────────────────────────────────────────

Results (N found):

 [1] <Title 1>                           (92% match)
     <spec-folder>

 [2] <Title 2>                           (85% match)
     <spec-folder>

 [3] <Title 3>                           (78% match)
     <spec-folder>

─────────────────────────────────────────
[1-N] select | [n]ew search | [q]uit
```

### Step 3: Handle Selection

Use `AskUserQuestion`:
```yaml
question: "Select result [1-N], [n]ew search, or [q]uit:"
options: []
allow_free_form: true
```

**Action Routing:**
- Number 1-N → MEMORY DETAIL SCREEN (for selected memory)
- "n" or "N" → Return to SEARCH PROMPT SCREEN
- "q" or "Q" → Exit with `STATUS=OK ACTION=browse`

### No Results Display

```
Memory Search: "<query>"
─────────────────────────────────────────

No memories found matching your query.

Suggestions:
- Try broader keywords
- Use different terms
- Check for typos

─────────────────────────────────────────
[n]ew search | [q]uit
```

---

## 5. 📄 MEMORY DETAIL SCREEN

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

Preview:
<First 300 characters of content...>

─────────────────────────────────────────
Related Memories:

 [a] <Related Title 1>                   (92% related)
 [b] <Related Title 2>                   (87% related)
 [c] <Related Title 3>                   (81% related)

─────────────────────────────────────────
[a-c] explore | [s]earch | [b]ack | [l]oad full | [q]uit
```

### Step 4: Handle Selection

Use `AskUserQuestion`:
```yaml
question: "[a-c] explore | [s]earch | [b]ack | [l]oad full | [q]uit:"
options: []
allow_free_form: true
```

**Action Routing:**
- "a", "b", "c" → MEMORY DETAIL SCREEN (for related memory)
- "s" or "S" → Return to SEARCH PROMPT SCREEN
- "b" or "B" → Return to SEARCH RESULTS SCREEN (previous results)
- "l" or "L" → FULL LOAD ACTION
- "q" or "Q" → Exit with `STATUS=OK ACTION=browse`

---

## 6. 💾 FULL LOAD ACTION

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
   ═══════════════════════════════════════
   Spec: <spec-folder>
   File: <file_path>
   Date: <created_at>
   ═══════════════════════════════════════

   <full_content>

   ═══════════════════════════════════════
   [s]earch | [b]ack | [q]uit
   ```

3. Handle selection:
   - "s" or "S" → Return to SEARCH PROMPT SCREEN
   - "b" or "B" → Return to MEMORY DETAIL SCREEN
   - "q" or "Q" → Exit with `STATUS=OK ACTION=load MEMORY=<title>`

---

## 7. 🔗 MULTI-CONCEPT SEARCH

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

Results (N found matching ALL concepts):

 [1] <Title>                             (88% avg)
     oauth: 92% | jwt: 85% | errors: 88%

 [2] <Title>                             (72% avg)
     oauth: 78% | jwt: 70% | errors: 68%

─────────────────────────────────────────
[1-N] select | [n]ew search | [q]uit
```

---

## 8. 🧠 STATE MANAGEMENT

Track navigation state for [b]ack action:

```yaml
browser_state:
  current_screen: search_prompt | search_results | memory_detail | full_load
  last_query: "<query>"
  last_results: [<result_list>]
  current_memory: <memory_object>
  navigation_stack: [<screen_history>]
```

When user presses [b]ack:
- Pop from navigation_stack
- Restore previous screen state
- If stack empty, go to SEARCH PROMPT SCREEN

---

## 9. ⚠️ ERROR HANDLING

| Condition             | Action                                    |
| --------------------- | ----------------------------------------- |
| MCP tool fails        | Show error, offer [r]etry or [q]uit       |
| Memory not found      | Show message, return to search results    |
| Invalid selection     | Re-prompt with valid options              |
| Empty query           | Re-prompt for query                       |
| No related memories   | Show "No related memories found"          |

### Error Display Format

```
Error
─────────────────────────────────────────
<error_message>

─────────────────────────────────────────
[r]etry | [s]earch | [q]uit
```

---

## 10. 📋 QUICK REFERENCE

| Input              | Action                          |
| ------------------ | ------------------------------- |
| `/memory/search`   | Open browser, prompt for query  |
| `/memory/search q` | Search for "q" immediately      |
| `1`, `2`, `3`...   | Select numbered result          |
| `a`, `b`, `c`...   | Explore related memory          |
| `n`                | New search                       |
| `s`                | Search (from detail/full view)  |
| `b`                | Back to previous screen         |
| `l`                | Load full memory content        |
| `q`                | Quit browser                     |

---

## 11. 🎨 DISPLAY FORMATTING

### Similarity Score Display

Convert similarity scores to percentages:
- Raw score 0.92 → "92% match"
- Raw score 0.85 → "85% related"

### Title Truncation

- Max title length: 35 characters
- If longer: truncate and add "..."

### Column Alignment

```
 [1] <Title padded to 35 chars>          (XX% match)
```

Use consistent spacing for visual alignment.

---

## 12. ⌨️ KEYBOARD SHORTCUTS SUMMARY

**Universal (all screens):**
- `q` - Quit browser

**Search Results:**
- `1-9` - Select result
- `n` - New search

**Memory Detail:**
- `a-e` - Explore related (up to 5)
- `s` - New search
- `b` - Back to results
- `l` - Load full content

**Full Load:**
- `s` - New search
- `b` - Back to detail view

---

## 13. 🎯 EXAMPLE SESSION

```
User: /memory/search

Memory Browser
─────────────────
Search: auth flow_

User: auth flow

Memory Search: "auth flow"
─────────────────────────────────────────

Results (3 found):

 [1] OAuth Implementation                (92% match)
     049-auth-system

 [2] JWT token handling                  (85% match)
     049-auth-system

 [3] Session management                  (78% match)
     032-api-security

─────────────────────────────────────────
[1-3] select | [n]ew search | [q]uit

User: 1

OAuth Implementation
─────────────────────────────────────────
Spec: 049-auth-system
Date: 2024-11-28 14:30

Preview:
Implemented OAuth 2.0 callback flow with JWT token generation.
Key decisions: Used RS256 for signing, 15-minute access token
expiry, 7-day refresh token rotation...

─────────────────────────────────────────
Related Memories:

 [a] JWT token storage                   (92% related)
 [b] Callback URL handling               (87% related)
 [c] Auth error patterns                 (81% related)

─────────────────────────────────────────
[a-c] explore | [s]earch | [b]ack | [l]oad full | [q]uit

User: l

Full Memory: OAuth Implementation
═══════════════════════════════════════
Spec: 049-auth-system
File: specs/049-auth-system/memory/28-11-25_14-30__oauth.md
Date: 2024-11-28 14:30
═══════════════════════════════════════

<full content displayed here>

═══════════════════════════════════════
[s]earch | [b]ack | [q]uit

User: q

STATUS=OK ACTION=browse MEMORIES_VIEWED=1 QUERY="auth flow"
```

---

## 14. 🔗 RELATED COMMANDS

- `/memory/save` - Save current conversation context

---

## 15. 📖 FULL DOCUMENTATION

For comprehensive documentation:
`.claude/skills/workflows-memory/SKILL.md`
