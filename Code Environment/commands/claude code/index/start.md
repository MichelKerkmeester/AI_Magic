---
description: Start the codebase indexing watcher process
allowed-tools: Bash(codesql:*)
---

# Index Start

Initialize the semantic code indexing system and start the file watcher process for automatic codebase indexing.

---

```yaml
role: Indexing System Initializer
purpose: Start background file watcher for automatic codebase indexing
action: Initialize .codebase/ directory and begin file watcher process

operating_mode:
  workflow: initialization_sequence
  workflow_compliance: MANDATORY
  workflow_execution: autonomous
  approvals: none_required
  tracking: startup_status_and_collection_id
  validation: watcher_running_confirmation
```

---

## Purpose

Start the background file watcher process that automatically indexes your codebase. This creates the `.codebase/` directory structure if needed and begins tracking code files for semantic search.

---

## Contract

**Inputs:** None
**Outputs:** `STATUS=<OK|FAIL> COLLECTION=<id> ACTION=<started|already_running>`

---

## Instructions

Execute the following steps:

1. **Load environment variables:**
   - The `codesql` CLI requires embedder configuration via environment variables
   - Source the env file before running any codesql commands:
   ```bash
   set -a && source .codebase/.env && set +a
   ```
   - This exports: `EMBED_BASE_URL`, `EMBED_API_KEY`, `EMBED_MODEL`, `EMBED_DIMENSION`
   - If `.codebase/.env` doesn't exist: `STATUS=FAIL ERROR="Missing .codebase/.env - run setup first"`

2. **Check if already running:**
   - Run `codesql -stats` to check current status
   - If status shows "watching", inform user and return early
   - This prevents duplicate watcher processes

3. **Start the indexer:**
   ```bash
   codesql -start
   ```

4. **Wait for initialization:**
   - The indexer will:
     - Create `.codebase/` directory if needed
     - Initialize `vectors.db`, `state.json`, `cache.json`
     - Generate collection ID
     - Start file watcher process
     - Begin initial indexing scan

5. **Verify startup:**
   - Run `codesql -stats` again to confirm
   - Extract collection ID and status
   - Check that watcher is running

6. **Return status:**
   - If started successfully: `STATUS=OK COLLECTION=<id> ACTION=started`
   - If already running: `STATUS=OK COLLECTION=<id> ACTION=already_running`
   - If failed: `STATUS=FAIL ERROR="<error message>"`

---

## Example Output

### Successful Start
```
🚀 Starting Codebase Indexer...

✅ Indexer started successfully!

Collection: codebase-a0e8947e88ce4315b0
Status: watching
Initial scan: In progress...

The indexer will now watch for file changes and keep the index up to date.
Use /index:stats to check progress.

STATUS=OK COLLECTION=codebase-a0e8947e88ce4315b0 ACTION=started
```

### Already Running
```
ℹ️  Indexer is already running

Collection: codebase-a0e8947e88ce4315b0
Status: watching
Tracked files: 251

Use /index:stop to stop the watcher, or /index:stats for details.

STATUS=OK COLLECTION=codebase-a0e8947e88ce4315b0 ACTION=already_running
```

---

## Notes
- **First Run:**
  - Creates `.codebase/` directory structure
  - Initial indexing may take a few minutes depending on codebase size
  - The watcher runs in the background

- **Subsequent Runs:**
  - Picks up where it left off using cached state
  - Only indexes changed files
  - Much faster than initial scan

- **What Gets Indexed:**
  - All code files in the workspace
  - Excludes: `node_modules/`, `.git/`, build artifacts, binary files
  - Respects `.gitignore` patterns

- **Background Process:**
  - The watcher runs as a background process
  - Process ID stored in `.codebase/watcher.pid`
  - Safe to close terminal after starting
  - Use `/index:stop` to stop the watcher cleanly

---

## Troubleshooting
- **"Unable to infer embedder provider" error:** Environment variables not loaded. Ensure step 1 (source .codebase/.env) was executed
- **"Invalid API key" (401) error:** API key in `.codebase/.env` is expired/invalid. Update `EMBED_API_KEY` with valid Voyage AI key
- If the command fails, check that `codesql` is available in PATH
- Ensure write permissions for `.codebase/` directory
- Check logs if indexing seems stuck
- Use `/index:reset` if the index is corrupted (destructive)
