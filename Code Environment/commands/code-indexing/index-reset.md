---
description: Delete all indexed data and start fresh (DESTRUCTIVE)
argument-hint: "[--confirm]"
allowed-tools: Bash(codesql:*), AskUserQuestion
---

# Index Reset

⚠️ **DESTRUCTIVE OPERATION** - Delete all indexed data and reset to fresh state.

---

## Purpose

Reset the semantic code indexing system by deleting all vectors, cached metadata, and commit history. This is a destructive operation that requires confirmation and forces a complete re-index.

---

## Contract

**Inputs:** `$ARGUMENTS` — Must include `--confirm` flag to proceed
**Outputs:** `STATUS=<OK|FAIL|CANCELLED> ACTION=<reset|cancelled>`

---

## Instructions

Execute the following steps:

1. **Safety check - Require confirmation:**
   - Check if `--confirm` flag is present in `$ARGUMENTS`
   - If NOT present, warn user and require explicit confirmation:
     - Use AskUserQuestion to ask: "⚠️ This will DELETE all indexed data. Are you sure you want to proceed?"
     - Options: "Yes, delete everything" / "No, cancel"
     - If user cancels: `STATUS=CANCELLED ACTION=cancelled`

2. **Show what will be deleted:**
   - Run `codesql -stats` to show current state
   - Display:
     - Number of tracked files that will be lost
     - Number of indexed commits that will be lost
     - Collection ID
     - Database size (.codebase/ directory)

3. **Stop watcher if running:**
   - Run `codesql -stop` first
   - Ensure no processes are accessing the database
   - Wait for clean shutdown

4. **Execute reset:**
   ```bash
   codesql -full-reset
   ```
   - This will:
     - Delete `.codebase/vectors.db`
     - Delete `.codebase/cache.json`
     - Reset `.codebase/state.json`
     - Remove all indexed data

5. **Verify reset:**
   - Check that `.codebase/` is in clean state
   - Run `codesql -stats` to confirm reset
   - Should show 0 tracked files, 0 indexed commits

6. **Provide next steps:**
   - Inform user to run `/index:start` to rebuild
   - Warn that re-indexing may take time
   - Suggest using `/index:history` after restart if needed

7. **Return status:**
   - If reset successfully: `STATUS=OK ACTION=reset`
   - If cancelled: `STATUS=CANCELLED ACTION=cancelled`
   - If failed: `STATUS=FAIL ERROR="<error message>"`

---

## Example Usage

### Without Confirmation (Safe Default)
```bash
/index:reset
```
→ Will prompt for confirmation before proceeding

### With Confirmation Flag (Skip Prompt)
```bash
/index:reset --confirm
```
→ Proceeds immediately (use with caution)

---

## Example Output

### Confirmation Prompt
```
⚠️  INDEX RESET WARNING

This operation will DELETE the following:
- Tracked files: 251
- Indexed commits: 0
- Collection: codebase-a0e8947e88ce4315b0
- Database size: ~7MB

This action CANNOT be undone. You will need to re-index from scratch.

Are you sure you want to proceed?
  [ ] Yes, delete everything
  [x] No, cancel

Operation cancelled.
STATUS=CANCELLED ACTION=cancelled
```

### Successful Reset
```
⚠️  Resetting Codebase Index...

Current state:
- Tracked files: 251
- Indexed commits: 0
- Collection: codebase-a0e8947e88ce4315b0

Stopping watcher... ✓
Deleting indexed data... ✓
Cleaning cache... ✓
Resetting state... ✓

✅ Index has been completely reset!

All indexed data has been deleted. To rebuild:
1. Run /index:start to begin indexing
2. Wait for initial scan to complete
3. Optionally run /index:history to index commits

STATUS=OK ACTION=reset
```

---

## Notes
- **When to Use:**
  - Index is corrupted or showing errors
  - Major codebase restructure
  - Want to change indexing configuration
  - Troubleshooting search quality issues
  - Testing or development purposes

- **Impact:**
  - ❌ All semantic search data lost
  - ❌ All indexed commit history lost
  - ❌ All cached file metadata lost
  - ❌ Search will not work until re-indexed
  - ✅ Source code files NOT affected
  - ✅ Can rebuild from scratch

- **Alternatives to Consider:**
  - Use `/index:stop` if you just want to pause indexing
  - Use `/index:start` to resume without reset
  - Check logs before resetting
  - Only reset as last resort

- **Re-indexing After Reset:**
  1. Run `/index:start` - may take several minutes
  2. Use `/index:stats` to monitor progress
  3. Run `/index:history` if temporal search needed
  4. Test search with `/index:search`

- **Best Practices:**
  - Always backup important data first
  - Document reason for reset
  - Inform team members if shared workspace
  - Schedule during low-activity periods
  - Monitor re-indexing progress

---

## Troubleshooting
- If reset fails, manually delete `.codebase/` directory
- If watcher won't stop, check for orphaned processes
- Ensure write permissions for `.codebase/` directory
- Check disk space before re-indexing
- Use `/index:stats` to verify reset completion

## Safety Features
- Requires explicit confirmation by default
- Shows what will be deleted before proceeding
- Stops watcher automatically
- Provides clear next steps
- Cannot accidentally delete source code
