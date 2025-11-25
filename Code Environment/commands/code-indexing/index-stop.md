---
description: Stop the codebase indexing watcher process
allowed-tools: Bash(codesql:*)
---

# Index Stop

Cleanly stop the semantic code indexing watcher process while preserving all indexed data.

---

## Purpose

Terminate the background file watcher process that monitors code changes. This stops automatic indexing while preserving all existing indexed data in the database.

---

## Contract

**Inputs:** None
**Outputs:** `STATUS=<OK|FAIL> ACTION=<stopped|not_running>`

---

## Instructions

Execute the following steps:

1. **Check current status:**
   - Run `codesql -stats` to check if watcher is running
   - If status shows "not watching" or similar, inform user and return early
   - No need to stop if not running

2. **Stop the watcher:**
   ```bash
   codesql -stop
   ```

3. **Wait for shutdown:**
   - The command will:
     - Send termination signal to watcher process
     - Wait for graceful shutdown
     - Clean up `.codebase/watcher.pid` file
     - Preserve all indexed data in `vectors.db`

4. **Verify shutdown:**
   - Run `codesql -stats` again to confirm
   - Check that watcher status is no longer "watching"
   - Confirm process has stopped

5. **Return status:**
   - If stopped successfully: `STATUS=OK ACTION=stopped`
   - If was not running: `STATUS=OK ACTION=not_running`
   - If failed: `STATUS=FAIL ERROR="<error message>"`

---

## Example Output

### Successful Stop
```
🛑 Stopping Codebase Indexer...

✅ Indexer stopped successfully!

Indexed data has been preserved in .codebase/
- Tracked files: 251
- Indexed commits: 0
- Collection: codebase-a0e8947e88ce4315b0

Use /index:start to resume indexing when needed.

STATUS=OK ACTION=stopped
```

### Not Running
```
ℹ️  Indexer is not currently running

The indexed data is still available:
- Tracked files: 251
- Collection: codebase-a0e8947e88ce4315b0

Use /index:start to start the watcher.

STATUS=OK ACTION=not_running
```

---

## Notes
- **Data Preservation:**
  - Stopping the watcher does NOT delete indexed data
  - All data remains in `.codebase/vectors.db`
  - Searches still work with existing index
  - Simply stops watching for new file changes

- **When to Stop:**
  - To reduce system resource usage
  - Before performing operations that modify many files
  - When switching to a different workspace
  - Not needed for normal workflow - watcher is lightweight

- **Restarting:**
  - Use `/index:start` to resume
  - Will pick up where it left off
  - Only indexes changes since stop

- **Graceful Shutdown:**
  - The command waits for clean termination
  - Any in-progress indexing completes
  - No data corruption risk
  - Safe to use at any time

---

## Troubleshooting
- If the watcher doesn't stop, check for orphaned processes
- Manually check `.codebase/watcher.pid` if issues persist
- The watcher may take a few seconds to fully terminate
- Use `/index:stats` to verify final status
