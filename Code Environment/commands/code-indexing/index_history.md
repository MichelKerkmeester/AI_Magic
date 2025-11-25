---
description: Index git commit history for temporal code understanding
argument-hint: "[count]"
allowed-tools: Bash(codesql:*)
---

# Index History

Index recent git commit history to enable temporal code search and understand code evolution over time.

---

## Purpose

Process git commit history to make code changes searchable. This enables semantic search queries about when features were added, how code evolved, and historical context.

---

## Contract

**Inputs:** `$ARGUMENTS` — Optional number of commits to index (default: 10)
**Outputs:** `STATUS=<OK|FAIL> INDEXED_COMMITS=<count>`

---

## Instructions

Execute the following steps:

1. **Load environment variables:**
   - Source the env file before running any codesql commands:
   ```bash
   set -a && source .codebase/.env && set +a
   ```
   - If `.codebase/.env` doesn't exist: `STATUS=FAIL ERROR="Missing .codebase/.env - run /index:start first"`

2. **Parse arguments:**
   - Extract commit count from `$ARGUMENTS`
   - If empty, default to 10 commits
   - Validate that count is a positive integer
   - If invalid: `STATUS=FAIL ERROR="Invalid commit count"`

3. **Verify git repository:**
   - Check that current directory is a git repository
   - If not: `STATUS=FAIL ERROR="Not a git repository"`

4. **Index commit history:**
   ```bash
   codesql -index-history <count>
   ```
   - This will process the last N commits
   - Extract code changes from each commit
   - Index the changes for semantic search
   - May take time for large commit histories

5. **Monitor progress:**
   - Show progress updates during indexing
   - Display commit messages being processed
   - Estimate time remaining if possible

6. **Verify completion:**
   - Run `codesql -stats` to check indexed commits count
   - Confirm the count increased appropriately

7. **Return status:**
   - If successful: `STATUS=OK INDEXED_COMMITS=<count>`
   - If failed: `STATUS=FAIL ERROR="<error message>"`

---

## Example Usage

### Index Last 10 Commits (Default)
```bash
/index:history
```

### Index Last 50 Commits
```bash
/index:history 50
```

### Index Last 100 Commits
```bash
/index:history 100
```

---

## Example Output
```
📚 Indexing Git Commit History...

Processing last 50 commits:
  ✓ fd152ab - Button + Fluid Responsive
  ✓ 2b0ff07 - Page Loader, Skills, etc.
  ✓ a8dd584 - Page Loader, Skills, etc.
  ✓ e2edd30 - Page Loader, Skills, etc.
  ✓ 46e9ed5 - Page Loader, Skills, etc.
  [... 45 more commits ...]

✅ Successfully indexed 50 commits!

Updated stats:
- Tracked files: 251
- Indexed commits: 50 (was 0)
- Collection: codebase-a0e8947e88ce4315b0

You can now search for code changes over time:
  /index:search "when was the button component refactored"
  /index:search "how did the page loader evolve"

STATUS=OK INDEXED_COMMITS=50
```

---

## Notes
- **Why Index History:**
  - Understand code evolution over time
  - Find when features were added or changed
  - Search for bug fixes and refactoring patterns
  - See historical context for current code

- **What Gets Indexed:**
  - Commit messages and metadata
  - Code diffs (additions and deletions)
  - File paths affected
  - Commit timestamps and authors

- **Performance:**
  - Small history (10-20 commits): Fast, < 1 minute
  - Medium history (50-100 commits): Moderate, 2-5 minutes
  - Large history (500+ commits): Slow, 10+ minutes
  - Consider indexing in batches for very large histories

- **Storage Impact:**
  - Each commit adds to index size
  - ~10-50KB per commit depending on changes
  - Monitor `.codebase/vectors.db` size

- **Best Practices:**
  - Start with recent commits (10-50)
  - Index more if you need deeper history
  - Re-index periodically as new commits are added
  - Consider indexing major feature branches

- **Temporal Search Examples:**
  - "when was authentication added"
  - "how has the navigation menu changed"
  - "what commits modified the hero section"
  - "evolution of form validation"

## Limitations
- Only indexes commits in current branch
- Requires git repository
- Large histories take time to process
- No automatic incremental updates (manual re-index needed)

## Troubleshooting
- If indexing is slow, try smaller batch sizes
- Ensure git history is available (not shallow clone)
- Check disk space for large histories
- Use `/index:stats` to verify progress
