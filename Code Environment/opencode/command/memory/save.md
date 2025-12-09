---
description: Save current conversation context to memory with semantic indexing
argument-hint: "[spec-folder]"
allowed-tools: Read, Write, Bash, AskUserQuestion
---

# Memory Save

Save the current conversation context to a spec folder's memory directory with semantic indexing.

---

```yaml
role: Context Preservation Specialist
purpose: Save conversation context with intelligent folder detection
action: Determine target folder, analyze conversation, generate memory file

operating_mode:
  workflow: interactive_detection
  workflow_compliance: MANDATORY
  approvals: only_for_ambiguous_folders
  tracking: save_result
```

---

## 1. 📝 CONTRACT

**Inputs:** `$ARGUMENTS` - Optional spec folder (e.g., "011-semantic-memory" or full path)
**Outputs:** `STATUS=<OK|FAIL> PATH=<saved_file_path>`

---

## 2. 🔀 ROUTING LOGIC

```
$ARGUMENTS
    │
    ├─► Spec folder provided (e.g., "011-memory" or "specs/011-memory")
    │   └─► Use specified folder directly
    │
    ├─► Empty (no args)
    │   ├─► Check .spec-active marker → Use active spec
    │   ├─► Calculate alignment scores → Use best match if >70%
    │   └─► If ambiguous → Prompt user to select
    │
    └─► Invalid folder
        └─► Show available folders, prompt selection
```

---

## 3. 📁 FOLDER DETECTION

### Step 1: Check for Explicit Argument

If `$ARGUMENTS` provided:
- If matches `specs/###-name` pattern: use directly
- If matches `###-name` pattern: prepend `specs/`
- If just a name: search for matching spec folder

### Step 2: Check .spec-active Marker

```bash
cat .spec-active 2>/dev/null
```

If exists and valid: use that spec folder.

### Step 3: Calculate Alignment Scores

Analyze conversation content against spec folders:
- Extract keywords from conversation
- Match against spec folder names and contents
- Score based on relevance

**Threshold**: 70% alignment required for auto-selection.

### Step 4: Prompt if Ambiguous

Use `AskUserQuestion` if:
- No clear match (all scores < 70%)
- Multiple folders with similar scores (within 10%)

```yaml
question: "Which spec folder should this context be saved to?"
options:
  - label: "011-semantic-memory"
    description: "Current best match (65%)"
  - label: "003-memory-debugging"
    description: "Second best (58%)"
  - label: "Create new spec folder"
    description: "Start fresh specification"
```

---

## 4. 💾 SAVE PROCESS

### Step 1: Analyze Conversation

Extract from the current conversation:
- **Session summary**: What was accomplished
- **Key decisions**: Technical choices and rationale
- **Files modified**: List of changed files
- **Trigger phrases**: Keywords for future retrieval
- **User requests**: Original asks and outcomes

### Step 2: Create JSON Data

```json
{
  "specFolder": "011-semantic-memory",
  "sessionSummary": "Brief description of work done",
  "keyDecisions": ["Decision 1", "Decision 2"],
  "filesModified": ["/path/to/file1.js", "/path/to/file2.md"],
  "triggerPhrases": ["keyword1", "keyword2", "phrase three"],
  "technicalContext": {
    "relevant": "technical details"
  }
}
```

### Step 3: Execute Processing Script

```bash
echo '<JSON_DATA>' > /tmp/save-context-data.json
node .claude/skills/workflows-memory/scripts/generate-context.js /tmp/save-context-data.json
rm /tmp/save-context-data.json
```

### Step 4: Report Results

```
Saving Context...

   Spec folder: 011-semantic-memory

   Memory file created
   Metadata saved
   Embedding generated (384 dimensions)
   Indexed as memory #42
   Extracted 8 trigger phrases

Saved to: specs/011-semantic-memory/memory/08-12-25_12-30__session.md

STATUS=OK PATH=specs/011-semantic-memory/memory/08-12-25_12-30__session.md
```

---

## 5. 📄 OUTPUT FORMAT

### File Naming

`{DD-MM-YY}_{HH-MM}__{topic}.md`

Example: `08-12-25_12-30__semantic-memory.md`

### File Location

```
specs/{spec-folder}/memory/{timestamp}__{topic}.md
```

---

## 6. ⚠️ ERROR HANDLING

| Condition              | Action                                          |
| ---------------------- | ----------------------------------------------- |
| No spec folder found   | Prompt user to create one                       |
| Empty conversation     | Return `STATUS=FAIL ERROR="No context to save"` |
| Script execution fails | Show error, suggest manual save                 |
| Embedding fails        | Continue save, mark for retry                   |

---

## 7. 🔍 QUICK REFERENCE

| Usage                                                  | Behavior                              |
| ------------------------------------------------------ | ------------------------------------- |
| `/memory/save`                                         | Auto-detect spec folder, save context |
| `/memory/save 011-memory`                              | Save to specific spec folder          |
| `/memory/save specs/006-semantic-memory/003-debugging` | Save to nested spec folder            |

---

## 8. 🔗 RELATED COMMANDS

- `/memory/search` - Search, manage index, view recent memories
- `/semantic_search` - Direct semantic search command

---

## 9. 📖 FULL DOCUMENTATION

For comprehensive documentation:
`.claude/skills/workflows-memory/SKILL.md`1