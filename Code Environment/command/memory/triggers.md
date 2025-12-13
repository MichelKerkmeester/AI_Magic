---
description: View and manage learned trigger phrases for memories
argument-hint: ""
allowed-tools: mcp__semantic_memory__memory_list, mcp__semantic_memory__memory_update
---

# Memory Triggers

View and manage learned trigger phrases that help find your memories faster.

---

```yaml
role: Trigger Phrase Manager
purpose: Display and manage learned trigger phrases for transparency and control
action: List triggers per memory, allow add/remove operations

operating_mode:
  workflow: interactive_menu
  workflow_compliance: MANDATORY
  workflow_execution: menu_driven
  approvals: only_for_clear_all
  tracking: action_and_result
```

---

## MCP ENFORCEMENT MATRIX

**CRITICAL:** This command requires MCP tool calls. Native MCP only - NEVER Code Mode.

```
┌─────────────────┬─────────────────────────────┬──────────┬─────────────────┐
│ SCREEN          │ REQUIRED MCP CALLS          │ MODE     │ ON FAILURE      │
├─────────────────┼─────────────────────────────┼──────────┼─────────────────┤
│ TRIGGER LIST    │ memory_list(limit:25)       │ SINGLE   │ Show error msg  │
├─────────────────┼─────────────────────────────┼──────────┼─────────────────┤
│ ADD/REMOVE      │ memory_update(id, triggers) │ SINGLE   │ Error + retry   │
└─────────────────┴─────────────────────────────┴──────────┴─────────────────┘
```

**Tool Call Format:**
```
mcp__semantic_memory__memory_list({ limit: 25, sortBy: "updated_at" })
mcp__semantic_memory__memory_update({ id: <id>, triggerPhrases: [...] })
```

---

## 1. CONTRACT

**Inputs:** `$ARGUMENTS` - Optional action (view, add, remove, search, clear)
**Outputs:** `STATUS=<OK|FAIL|CANCELLED> ACTION=<action_performed>`

---

## 2. ROUTING LOGIC

```
$ARGUMENTS
    |
    |-- Empty (no args)
    |   --> INTERACTIVE MODE: Show trigger list with menu
    |
    |-- "search" + phrase
    |   --> SEARCH ACTION: Filter memories by trigger
    |
    |-- "clear"
    |   --> CLEAR ACTION: Remove all learned triggers (with confirmation)
    |
    --> Otherwise
        --> INTERACTIVE MODE: Show trigger list
```

---

## 3. INTERACTIVE MODE

When called without arguments, display learned triggers and offer actions:

### Step 1: Query via MCP

Call the MCP tool directly (NEVER through Code Mode):

```
mcp__semantic_memory__memory_list({
  limit: 25,
  sortBy: "updated_at"
})
```

**Expected Response:**
```json
{
  "memories": [
    {
      "id": 42,
      "title": "OAuth Implementation",
      "spec_folder": "049-auth-system",
      "trigger_phrases": ["oauth", "token refresh", "callback url", "jwt decode"],
      "importance_tier": "critical"
    },
    ...
  ],
  "total": 47,
  "offset": 0,
  "limit": 25
}
```

### Step 2: Display Format

```
┌────────────────────────────────────────────────────────────────┐
│                   LEARNED TRIGGER PHRASES                      │
├────────────────────────────────────────────────────────────────┤
│                                                                │
│  These phrases help find your memories faster.                 │
│  The system learned them from your search patterns.            │
│                                                                │
│  [via: memory_list]                                            │
│  ─────────────────────────────────────────                     │
│                                                                │
│  Memory: "OAuth Implementation" [ID: 42]                       │
│    Folder: 049-auth-system                                     │
│    Tier: critical                                              │
│    Triggers: oauth, token refresh, callback url, jwt decode    │
│                                                                │
│  Memory: "Database Schema" [ID: 38]                            │
│    Folder: 050-database                                        │
│    Tier: important                                             │
│    Triggers: user table, migrations, foreign key               │
│                                                                │
│  Memory: "API Endpoints" [ID: 35]                              │
│    Folder: 051-api                                             │
│    Tier: normal                                                │
│    Triggers: rest api, endpoints, routes                       │
│                                                                │
├────────────────────────────────────────────────────────────────┤
│  [s]earch by trigger │ [a]dd trigger │ [r]emove trigger        │
│  [c]lear all         │ [q]uit                                  │
└────────────────────────────────────────────────────────────────┘
```

### Step 3: Show Menu

Present as inline prompt:
```
Select [s]earch, [a]dd, [r]emove, [c]lear, or [q]uit:
```

---

## 4. SEARCH ACTION

**Triggers:** `search` keyword or menu selection `[s]`

### Instructions

1. **Get search phrase:**
   - From arguments: `/memory/triggers search oauth`
   - From menu: prompt user for phrase

2. **Query via MCP and filter:**
   ```
   mcp__semantic_memory__memory_list({
     limit: 50,
     sortBy: "updated_at"
   })
   ```

3. **Filter results client-side:**
   Match memories where any trigger phrase contains the search term.

### Output Format

```
┌────────────────────────────────────────────────────────────────┐
│              TRIGGER SEARCH: "oauth"                           │
├────────────────────────────────────────────────────────────────┤
│                                                                │
│  Found 2 memories:                                             │
│                                                                │
│  [42] OAuth Implementation                                     │
│       Matched: oauth, oauth callback                           │
│                                                                │
│  [38] API Security Layer                                       │
│       Matched: oauth token                                     │
│                                                                │
├────────────────────────────────────────────────────────────────┤
│  [b]ack │ [q]uit                                               │
└────────────────────────────────────────────────────────────────┘

STATUS=OK ACTION=search MATCHES=2 QUERY="oauth"
```

---

## 5. ADD TRIGGER ACTION

**Triggers:** Menu selection `[a]`

### Instructions

1. **Prompt for memory ID:**
   ```
   Enter the memory ID to add a trigger to (shown in brackets above):
   ```

2. **Prompt for new phrase:**
   ```
   Enter the trigger phrase to add:
   ```

3. **Update via MCP:**
   ```
   # First get current triggers
   mcp__semantic_memory__memory_list({ limit: 1 })  # Get by ID
   
   # Then update with new trigger added
   mcp__semantic_memory__memory_update({
     id: <memory_id>,
     triggerPhrases: [...existing_triggers, "<new_trigger>"]
   })
   ```

### Output Format

```
Adding trigger phrase...

Added trigger "jwt validation" to memory #42
Total triggers for this memory: 5

STATUS=OK ACTION=add MEMORY_ID=42 TRIGGER="jwt validation"
```

---

## 6. REMOVE TRIGGER ACTION

**Triggers:** Menu selection `[r]`

### Instructions

1. **Prompt for memory ID:**
   ```
   Enter the memory ID to remove a trigger from:
   ```

2. **Show current triggers via MCP:**
   ```
   mcp__semantic_memory__memory_list({ limit: 50 })
   ```
   Filter to find the memory and display its triggers.

3. **Display triggers with numbers:**
   ```
   Memory: "OAuth Implementation"
   Current triggers:
     1) oauth
     2) token refresh
     3) callback url
     4) jwt decode
   
   Enter the number of the trigger to remove:
   ```

4. **Execute removal via MCP:**
   ```
   mcp__semantic_memory__memory_update({
     id: <memory_id>,
     triggerPhrases: [<filtered_triggers_without_removed>]
   })
   ```

### Output Format

```
Removing trigger phrase...

Removed trigger: "old keyword"
Remaining triggers: 4

STATUS=OK ACTION=remove MEMORY_ID=42 REMOVED="old keyword"
```

---

## 7. CLEAR ALL ACTION

**Triggers:** `clear` keyword or menu selection `[c]`

### Instructions

1. **Confirm destructive action:**
   ```
   ┌────────────────────────────────────────────────────────────────┐
   │                    ⚠ CONFIRM CLEAR ALL                         │
   ├────────────────────────────────────────────────────────────────┤
   │                                                                │
   │  This will remove ALL learned trigger phrases from ALL         │
   │  memories. This cannot be undone.                              │
   │                                                                │
   │  Are you sure?                                                 │
   │                                                                │
   ├────────────────────────────────────────────────────────────────┤
   │  [y]es, clear all │ [n]o, cancel                               │
   └────────────────────────────────────────────────────────────────┘
   ```

2. **If confirmed, iterate and clear:**
   ```
   # Get all memories
   mcp__semantic_memory__memory_list({ limit: 100 })
   
   # For each memory with triggers, clear them
   mcp__semantic_memory__memory_update({
     id: <id>,
     triggerPhrases: []
   })
   ```

### Output Format

```
Clearing all triggers...

Cleared triggers from 15 memories
All trigger phrases have been reset.

STATUS=OK ACTION=clear COUNT=15
```

---

## 8. QUICK REFERENCE

| Usage                            | Action                           |
| -------------------------------- | -------------------------------- |
| `/memory/triggers`               | Interactive mode with menu       |
| `/memory/triggers search oauth`  | Find memories by trigger phrase  |
| `/memory/triggers clear`         | Clear all triggers (with confirm)|

---

## 9. PURPOSE & TRANSPARENCY

This command exists to give users visibility into what the system has learned:

- **See the patterns**: Understand which phrases are associated with which memories
- **Correct mistakes**: Remove incorrect associations
- **Add knowledge**: Teach the system new trigger phrases
- **Build trust**: Transparency in how the system learns from your work

The trigger phrases are used during search to improve relevance and help surface the right memories when you need them.

---

## 10. ERROR HANDLING

| Condition              | Action                              |
| ---------------------- | ----------------------------------- |
| MCP tool fails         | Show error state with [r]etry       |
| No memories found      | Show "No memories indexed yet"      |
| Invalid memory ID      | Show error, re-prompt               |
| Empty trigger phrase   | Reject, ask for valid input         |

---

## 11. RELATED COMMANDS

- `/memory/search` - Search memories using trigger phrases
- `/memory/status` - View system health and statistics
- `/memory/save` - Save context (extracts trigger phrases automatically)

---

## 12. FULL DOCUMENTATION

For comprehensive documentation:
`.opencode/skills/workflows-memory/SKILL.md`
