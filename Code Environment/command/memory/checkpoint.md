---
description: Save and restore memory states for context switching and safety nets
argument-hint: "<subcommand> [name]"
allowed-tools: Read, Bash, mcp__semantic_memory__memory_list, mcp__semantic_memory__memory_search, mcp__semantic_memory__memory_load, mcp__semantic_memory__memory_stats, mcp__semantic_memory__memory_delete
---

# Memory Checkpoint Management

Save and restore memory states for context switching and safety nets.

---

```yaml
role: Memory State Manager
purpose: Create and manage checkpoints for memory state preservation
action: Execute subcommand (create/restore/list/delete) with checkpoint operations

operating_mode:
  workflow: subcommand_dispatch
  workflow_compliance: MANDATORY
  approvals: restore_and_delete_only
  tracking: checkpoint_operations
```

---

## 1. CONTRACT

**Inputs:** `$ARGUMENTS` - Subcommand and optional checkpoint name
**Outputs:** `STATUS=<OK|FAIL> CHECKPOINT=<name> ACTION=<create|restore|list|delete>`

---

## 2. USAGE

This command accepts a subcommand:

| Subcommand | Description |
|------------|-------------|
| `create <name>` | Save current memory state with a name |
| `restore <name>` | Restore to a saved checkpoint |
| `list` | Show all available checkpoints |
| `delete <name>` | Remove a checkpoint |

---

## 3. ROUTING LOGIC

```
$ARGUMENTS
    |
    +--> "create <name>"
    |    +-> Validate name (no spaces, alphanumeric + dashes)
    |    +-> Snapshot all memory IDs and metadata
    |    +-> Save to .opencode/checkpoints/<name>.json
    |    +-> Enforce max 10 checkpoints (oldest auto-deleted)
    |
    +--> "restore <name>"
    |    +-> Load checkpoint from .opencode/checkpoints/<name>.json
    |    +-> Calculate diff (added/removed/changed memories)
    |    +-> Show diff summary, require confirmation
    |    +-> On confirm: reload memory state
    |
    +--> "list"
    |    +-> Scan .opencode/checkpoints/ directory
    |    +-> Display table: name, created, memory count, size
    |
    +--> "delete <name>"
    |    +-> Require confirmation
    |    +-> Remove checkpoint file permanently
    |
    +--> Empty or invalid
         +-> Show usage help
```

---

## 4. SUBCOMMAND: CREATE

### Usage
```
/memory/checkpoint create "before-refactor"
```

### Process

1. **Validate Name**
   - Alphanumeric characters, dashes, underscores only
   - Max 50 characters
   - No spaces

2. **Gather Memory State**
   - Use `mcp__semantic_memory__memory_list` to get all memories
   - For each memory, capture:
     - `id`: Memory ID
     - `spec_folder`: Associated spec folder
     - `title`: Memory title
     - `importance_weight`: Priority level
     - `created_at`: Creation timestamp
     - `updated_at`: Last update timestamp
     - `trigger_phrases`: Associated triggers

3. **Create Checkpoint File**
   ```bash
   mkdir -p .opencode/checkpoints
   ```

   Write to `.opencode/checkpoints/<name>.json`:
   ```json
   {
     "name": "<name>",
     "created_at": "<ISO timestamp>",
     "memory_count": 47,
     "memories": [
       {
         "id": 1,
         "spec_folder": "011-semantic-memory",
         "title": "Memory title",
         "importance_weight": 0.8,
         "created_at": "2025-12-08T10:30:00Z",
         "trigger_phrases": ["keyword1", "keyword2"]
       }
     ]
   }
   ```

4. **Enforce Limits**
   - Max 10 checkpoints allowed
   - If limit exceeded: delete oldest checkpoint automatically
   - Auto-cleanup: remove checkpoints older than 30 days

5. **Output**
   ```
   Checkpoint 'before-refactor' created

      Memories captured: 47
      Spec folders: 5
      Total size: 12.4 KB

   STATUS=OK CHECKPOINT=before-refactor ACTION=create
   ```

---

## 5. SUBCOMMAND: RESTORE

### Usage
```
/memory/checkpoint restore "before-refactor"
```

### Process

1. **Load Checkpoint**
   - Read `.opencode/checkpoints/<name>.json`
   - If not found: show error with available checkpoints

2. **Calculate Diff**
   - Get current memory state via `mcp__semantic_memory__memory_list`
   - Compare with checkpoint:
     - **Added**: Memories in current but not in checkpoint
     - **Removed**: Memories in checkpoint but not in current
     - **Changed**: Memories with different metadata

3. **Show Diff Summary**
   ```
   Restoring checkpoint 'before-refactor'

   Changes detected:
      - 12 memories added since checkpoint (will be removed)
      - 3 memories deleted since checkpoint (will be restored)
      - 2 memories modified since checkpoint (will be reverted)

   Confirm? [y]es, [n]o, [v]iew diff
   ```

4. **View Diff Option**
   If user selects `v`:
   ```
   MEMORIES TO REMOVE (added after checkpoint):
   - #48: "Auth refactor session" (011-auth-system)
   - #49: "Error handling updates" (011-auth-system)
   ...

   MEMORIES TO RESTORE (deleted after checkpoint):
   - #45: "Original auth design" (011-auth-system)
   ...

   MEMORIES TO REVERT (modified after checkpoint):
   - #42: title changed, importance changed
   ...

   Confirm restore? [y]es, [n]o
   ```

5. **Execute Restore**
   - Use `mcp__semantic_memory__memory_delete` for memories to remove
   - Note: Full restore requires re-saving deleted memories (not always possible)
   - Output:
   ```
   Checkpoint 'before-refactor' restored

      Memories removed: 12
      Memories marked for recovery: 3 (manual re-save needed)

   STATUS=OK CHECKPOINT=before-refactor ACTION=restore
   ```

### CAUTION

Restore is a **destructive operation**:
- Memories added after checkpoint will be deleted
- Deleted memories cannot be automatically restored (data loss)
- Always create a new checkpoint before restoring

---

## 6. SUBCOMMAND: LIST

### Usage
```
/memory/checkpoint list
```

### Process

1. **Scan Checkpoints Directory**
   ```bash
   ls -la .opencode/checkpoints/*.json 2>/dev/null
   ```

2. **Parse Each Checkpoint**
   - Read JSON file
   - Extract: name, created_at, memory_count
   - Calculate file size

3. **Display Table**
   ```
   Available Checkpoints

   | Name              | Created          | Memories | Size    |
   |-------------------|------------------|----------|---------|
   | before-refactor   | Dec 8, 10:30 AM  | 47       | 12.4 KB |
   | feature-auth      | Dec 7, 3:15 PM   | 42       | 10.8 KB |
   | initial-state     | Dec 5, 9:00 AM   | 35       | 8.2 KB  |

   Total: 3 checkpoints (31.4 KB)

   STATUS=OK ACTION=list
   ```

4. **Empty State**
   ```
   No checkpoints found

   Create one with: /memory/checkpoint create "my-checkpoint"

   STATUS=OK ACTION=list
   ```

---

## 7. SUBCOMMAND: DELETE

### Usage
```
/memory/checkpoint delete "old-checkpoint"
```

### Process

1. **Verify Checkpoint Exists**
   - Check `.opencode/checkpoints/<name>.json`
   - If not found: show error with available checkpoints

2. **Show Confirmation**
   ```
   Delete checkpoint 'old-checkpoint'?

      Created: Dec 5, 9:00 AM
      Memories: 35
      Size: 8.2 KB

   This action is permanent. Confirm? [y]es, [n]o
   ```

3. **Execute Delete**
   ```bash
   rm .opencode/checkpoints/<name>.json
   ```

4. **Output**
   ```
   Checkpoint 'old-checkpoint' deleted

   STATUS=OK CHECKPOINT=old-checkpoint ACTION=delete
   ```

---

## 8. MCP TOOL USAGE

Uses `mcp__semantic_memory__` tools internally:

| Operation | Tool Used |
|-----------|-----------|
| List memories | `mcp__semantic_memory__memory_list` |
| Get stats | `mcp__semantic_memory__memory_stats` |
| Load specific memory | `mcp__semantic_memory__memory_load` |
| Delete memory | `mcp__semantic_memory__memory_delete` |
| Search memories | `mcp__semantic_memory__memory_search` |

---

## 9. USE CASES

### Before Major Refactors
```
User: Create a checkpoint before I start the auth refactor
AI: /memory/checkpoint create "pre-auth-refactor"
    Checkpoint 'pre-auth-refactor' created (47 memories)

[... work happens, things go wrong ...]

User: Restore to before the refactor
AI: /memory/checkpoint restore "pre-auth-refactor"
    Restoring will:
    - Remove 12 memories added since checkpoint
    - Restore 3 memories that were deleted
    Confirm? [y]es, [n]o, [v]iew diff
```

### Context Switching Between Features
```
User: I need to switch to the billing feature for a bit
AI: /memory/checkpoint create "auth-wip"
    Checkpoint 'auth-wip' created

[... work on billing ...]

User: Back to auth work, restore my context
AI: /memory/checkpoint restore "auth-wip"
```

### Experimentation
```
User: Let me try a different approach, but save current state first
AI: /memory/checkpoint create "approach-a"

[... try different approach ...]

User: That didn't work, go back
AI: /memory/checkpoint restore "approach-a"
```

### Session Recovery
```
User: I accidentally ran memory cleanup, can we recover?
AI: /memory/checkpoint list
    | Name         | Created         | Memories |
    | daily-backup | Dec 8, 9:00 AM  | 52       |

AI: /memory/checkpoint restore "daily-backup"
```

---

## 10. CONFIGURATION

Defaults (can be overridden in `.opencode/configs/memory.jsonc`):

```jsonc
{
  "checkpoints": {
    "max_count": 10,           // Maximum checkpoints allowed
    "max_age_days": 30,        // Auto-delete after N days
    "storage_path": ".opencode/checkpoints"
  }
}
```

---

## 11. ERROR HANDLING

| Condition | Action |
|-----------|--------|
| Invalid subcommand | Show usage help with available subcommands |
| Checkpoint not found | List available checkpoints |
| Name validation fails | Show naming requirements |
| Max checkpoints exceeded | Auto-delete oldest, warn user |
| Restore without confirmation | Abort operation |
| Delete without confirmation | Abort operation |
| Checkpoints directory missing | Create automatically |

---

## 12. QUICK REFERENCE

| Command | Description |
|---------|-------------|
| `/memory/checkpoint create "name"` | Save current memory state |
| `/memory/checkpoint restore "name"` | Restore to saved state (requires confirmation) |
| `/memory/checkpoint list` | Show all checkpoints |
| `/memory/checkpoint delete "name"` | Remove checkpoint (requires confirmation) |

---

## 13. RELATED COMMANDS

- `/memory/save` - Save conversation context to memory
- `/memory/search` - Search memories semantically
- `/memory/status` - View memory system statistics
- `/memory/cleanup` - Clean up old or unused memories

---

## 14. LIMITATIONS

1. **Cannot fully restore deleted memories**: When a memory is deleted from the database, restoring a checkpoint cannot recreate it. The checkpoint only records metadata, not full content.

2. **Embedding data not preserved**: Checkpoints capture metadata but not vector embeddings. Restored memories will retain their original embeddings if they still exist.

3. **Cross-session limitations**: Checkpoints are local to the workspace and may not transfer between machines.

---

## 15. FULL DOCUMENTATION

For comprehensive memory system documentation:
`.opencode/skills/workflows-memory/SKILL.md`
