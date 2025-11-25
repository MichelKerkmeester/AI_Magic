---
description: Show codebase indexing statistics and status
allowed-tools: Bash(codesql:*)
---

# Index Stats

Display current statistics for the semantic code indexing system.

---

## Purpose

Show real-time statistics about the indexing system including tracked files, indexed commits, collection ID, and watcher status.

---

## Contract

**Inputs:** None
**Outputs:** `STATUS=<OK|FAIL> TRACKED_FILES=<count> INDEXED_COMMITS=<count> COLLECTION=<id> WATCHER_STATUS=<status>`

---

## Instructions

Execute the following steps:

1. **Run the stats command:**
   ```bash
   codesql -stats
   ```

2. **Parse the output:**
   - Extract workspace path
   - Extract collection ID
   - Extract tracked files count
   - Extract indexed commits count
   - Extract watcher status

3. **Format and return results:**
   - If successful: `STATUS=OK TRACKED_FILES=<count> INDEXED_COMMITS=<count> COLLECTION=<id> WATCHER_STATUS=<status>`
   - If failed: `STATUS=FAIL ERROR="<error message>"`

4. **Display formatted output:**
   Show the statistics in a clear, readable format with appropriate labels and values.

---

## Example Output
```
📊 Codebase Indexing Statistics

Workspace: /path/to/project
Collection: codebase-a0e8947e88ce4315b0
Tracked files: 251
Indexed commits: 0
Status: watching

STATUS=OK TRACKED_FILES=251 INDEXED_COMMITS=0 COLLECTION=codebase-a0e8947e88ce4315b0 WATCHER_STATUS=watching
```

---

## Notes
- This is a read-only operation and safe to run at any time
- The command will work even if the indexer is not currently running
- Use this to verify indexing status before running searches
