---
description: View and manage learned trigger phrases for memories
argument-hint: ""
allowed-tools: Read, Bash, AskUserQuestion
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

## 1. 📝 CONTRACT

**Inputs:** `$ARGUMENTS` - Optional action (view, add, remove, search, clear)
**Outputs:** `STATUS=<OK|FAIL|CANCELLED> ACTION=<action_performed>`

---

## 2. 🔀 ROUTING LOGIC

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

## 3. 🖥️ INTERACTIVE MODE

When called without arguments, display learned triggers and offer actions:

### Step 1: Query the Database

```bash
# Get all memories with their trigger phrases
node -e "
const vi = require('./.claude/skills/workflows-memory/scripts/lib/vector-index.js');
const db = vi.getDb();
const rows = db.prepare('SELECT id, title, spec_folder, trigger_phrases FROM memory_index ORDER BY updated_at DESC LIMIT 25').all();

console.log('');
rows.forEach((row, i) => {
  const triggers = row.trigger_phrases ? JSON.parse(row.trigger_phrases) : [];
  if (triggers.length > 0) {
    console.log('Memory: \"' + (row.title || 'Untitled') + '\"');
    console.log('  Folder: ' + row.spec_folder);
    console.log('  Triggers: ' + triggers.join(', '));
    console.log('  [ID: ' + row.id + ']');
    console.log('');
  }
});
"
```

### Step 2: Display Format

```
Learned Trigger Phrases

These phrases help find your memories faster.
The system learned them from your search patterns.

 Memory: "OAuth Implementation"
   Folder: 049-auth-system
   Triggers: oauth, token refresh, callback url, jwt decode
   [ID: 42]

 Memory: "Database Schema"
   Folder: 050-database
   Triggers: user table, migrations, foreign key
   [ID: 38]

 Memory: "API Endpoints"
   Folder: 051-api
   Triggers: rest api, endpoints, routes
   [ID: 35]
```

### Step 3: Show Menu

```yaml
question: "What would you like to do?"
options:
  - label: "Search by trigger phrase"
    description: "Find memories matching a specific phrase"
  - label: "Add trigger to a memory"
    description: "Associate a new phrase with a memory"
  - label: "Remove trigger from a memory"
    description: "Delete a learned phrase"
  - label: "Clear all learned triggers"
    description: "Reset all trigger phrases (with confirmation)"
  - label: "Exit"
    description: "Return to normal operation"
```

---

## 4. 🔍 SEARCH ACTION

**Triggers:** `search` keyword or menu selection

### Instructions

1. **Get search phrase:**
   - From arguments: `/memory/triggers search oauth`
   - From menu: prompt with `AskUserQuestion`

2. **Query database:**
   ```bash
   node -e "
   const vi = require('./.claude/skills/workflows-memory/scripts/lib/vector-index.js');
   const db = vi.getDb();
   const searchTerm = process.argv[1].toLowerCase();
   const rows = db.prepare('SELECT id, title, spec_folder, trigger_phrases FROM memory_index').all();

   const matches = rows.filter(row => {
     const triggers = row.trigger_phrases ? JSON.parse(row.trigger_phrases) : [];
     return triggers.some(t => t.toLowerCase().includes(searchTerm));
   });

   if (matches.length === 0) {
     console.log('No memories found with trigger: \"' + searchTerm + '\"');
   } else {
     console.log('Found ' + matches.length + ' memories:');
     console.log('');
     matches.forEach(row => {
       const triggers = JSON.parse(row.trigger_phrases || '[]');
       const matched = triggers.filter(t => t.toLowerCase().includes(searchTerm));
       console.log('  [' + row.id + '] ' + (row.title || 'Untitled'));
       console.log('       Matched: ' + matched.join(', '));
     });
   }
   " "$SEARCH_PHRASE"
   ```

### Output Format

```
Search: "oauth"

Found 2 memories:

  [42] OAuth Implementation
       Matched: oauth, oauth callback

  [38] API Security Layer
       Matched: oauth token

STATUS=OK ACTION=search MATCHES=2 QUERY="oauth"
```

---

## 5. ➕ ADD TRIGGER ACTION

**Triggers:** Menu selection "Add trigger to a memory"

### Instructions

1. **Prompt for memory ID:**
   ```yaml
   question: "Enter the memory ID to add a trigger to (shown in brackets above):"
   options: []  # Free text input
   ```

2. **Prompt for new phrase:**
   ```yaml
   question: "Enter the trigger phrase to add:"
   options: []  # Free text input
   ```

3. **Update database:**
   ```bash
   node -e "
   const vi = require('./.claude/skills/workflows-memory/scripts/lib/vector-index.js');
   const db = vi.getDb();
   const memoryId = parseInt(process.argv[1]);
   const newTrigger = process.argv[2].toLowerCase().trim();

   const row = db.prepare('SELECT trigger_phrases FROM memory_index WHERE id = ?').get(memoryId);
   if (!row) {
     console.log('Memory not found: ' + memoryId);
     process.exit(1);
   }

   const triggers = row.trigger_phrases ? JSON.parse(row.trigger_phrases) : [];
   if (triggers.includes(newTrigger)) {
     console.log('Trigger already exists: \"' + newTrigger + '\"');
     process.exit(0);
   }

   triggers.push(newTrigger);
   db.prepare('UPDATE memory_index SET trigger_phrases = ? WHERE id = ?')
     .run(JSON.stringify(triggers), memoryId);

   console.log('Added trigger \"' + newTrigger + '\" to memory #' + memoryId);
   " "$MEMORY_ID" "$NEW_TRIGGER"
   ```

### Output Format

```
Adding trigger phrase...

Added trigger "jwt validation" to memory #42
Total triggers for this memory: 5

STATUS=OK ACTION=add MEMORY_ID=42 TRIGGER="jwt validation"
```

---

## 6. ➖ REMOVE TRIGGER ACTION

**Triggers:** Menu selection "Remove trigger from a memory"

### Instructions

1. **Prompt for memory ID:**
   ```yaml
   question: "Enter the memory ID to remove a trigger from:"
   options: []
   ```

2. **Show current triggers and prompt for removal:**
   ```bash
   node -e "
   const vi = require('./.claude/skills/workflows-memory/scripts/lib/vector-index.js');
   const db = vi.getDb();
   const memoryId = parseInt(process.argv[1]);

   const row = db.prepare('SELECT title, trigger_phrases FROM memory_index WHERE id = ?').get(memoryId);
   if (!row) {
     console.log('Memory not found');
     process.exit(1);
   }

   const triggers = row.trigger_phrases ? JSON.parse(row.trigger_phrases) : [];
   console.log('Memory: ' + (row.title || 'Untitled'));
   console.log('Current triggers:');
   triggers.forEach((t, i) => console.log('  ' + (i+1) + ') ' + t));
   " "$MEMORY_ID"
   ```

3. **Prompt for trigger to remove:**
   ```yaml
   question: "Enter the number of the trigger to remove:"
   options: []
   ```

4. **Execute removal:**
   ```bash
   node -e "
   const vi = require('./.claude/skills/workflows-memory/scripts/lib/vector-index.js');
   const db = vi.getDb();
   const memoryId = parseInt(process.argv[1]);
   const triggerIndex = parseInt(process.argv[2]) - 1;

   const row = db.prepare('SELECT trigger_phrases FROM memory_index WHERE id = ?').get(memoryId);
   const triggers = JSON.parse(row.trigger_phrases || '[]');

   if (triggerIndex < 0 || triggerIndex >= triggers.length) {
     console.log('Invalid trigger number');
     process.exit(1);
   }

   const removed = triggers.splice(triggerIndex, 1)[0];
   db.prepare('UPDATE memory_index SET trigger_phrases = ? WHERE id = ?')
     .run(JSON.stringify(triggers), memoryId);

   console.log('Removed trigger: \"' + removed + '\"');
   " "$MEMORY_ID" "$TRIGGER_INDEX"
   ```

### Output Format

```
Removing trigger phrase...

Removed trigger: "old keyword"
Remaining triggers: 4

STATUS=OK ACTION=remove MEMORY_ID=42 REMOVED="old keyword"
```

---

## 7. 🗑️ CLEAR ALL ACTION

**Triggers:** `clear` keyword or menu selection

### Instructions

1. **Confirm destructive action:**
   ```yaml
   question: "This will remove ALL learned trigger phrases from ALL memories. This cannot be undone. Are you sure?"
   options:
     - label: "Yes, clear all triggers"
       description: "Remove all learned phrases (destructive)"
     - label: "Cancel"
       description: "Keep existing triggers"
   ```

2. **If confirmed, execute:**
   ```bash
   node -e "
   const vi = require('./.claude/skills/workflows-memory/scripts/lib/vector-index.js');
   const db = vi.getDb();

   const countBefore = db.prepare('SELECT COUNT(*) as c FROM memory_index WHERE trigger_phrases IS NOT NULL AND trigger_phrases != \"[]\"').get().c;

   db.prepare('UPDATE memory_index SET trigger_phrases = \"[]\"').run();

   console.log('Cleared triggers from ' + countBefore + ' memories');
   "
   ```

### Output Format

```
Clearing all triggers...

Cleared triggers from 15 memories
All trigger phrases have been reset.

STATUS=OK ACTION=clear COUNT=15
```

---

## 8. 📋 QUICK REFERENCE

| Usage                            | Action                           |
| -------------------------------- | -------------------------------- |
| `/memory/triggers`               | Interactive mode with menu       |
| `/memory/triggers search oauth`  | Find memories by trigger phrase  |
| `/memory/triggers clear`         | Clear all triggers (with confirm)|

---

## 9. 💡 PURPOSE & TRANSPARENCY

This command exists to give users visibility into what the system has learned:

- **See the patterns**: Understand which phrases are associated with which memories
- **Correct mistakes**: Remove incorrect associations
- **Add knowledge**: Teach the system new trigger phrases
- **Build trust**: Transparency in how the system learns from your work

The trigger phrases are used during search to improve relevance and help surface the right memories when you need them.

---

## 10. ⚠️ ERROR HANDLING

| Condition              | Action                              |
| ---------------------- | ----------------------------------- |
| No memories found      | Show "No memories indexed yet"      |
| Invalid memory ID      | Show error, re-prompt               |
| Database unavailable   | Show connection error               |
| Empty trigger phrase   | Reject, ask for valid input         |

---

## 11. 🔗 RELATED COMMANDS

- `/memory/search` - Search memories using trigger phrases
- `/memory/status` - View system health and statistics
- `/memory/save` - Save context (extracts trigger phrases automatically)

---

## 12. 📖 FULL DOCUMENTATION

For comprehensive documentation:
`.claude/skills/workflows-memory/SKILL.md`
