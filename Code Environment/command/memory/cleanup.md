---
description: Interactively clean up old or unused memories
argument-hint: "[--include-critical]"
allowed-tools: Read, Bash, mcp__semantic_memory__memory_list, mcp__semantic_memory__memory_delete, mcp__semantic_memory__memory_stats
---

# Memory Cleanup

Interactive cleanup of old, unused, or low-relevance memories from the semantic index.

---

```yaml
role: Memory Cleanup Specialist
purpose: Help users safely clean up outdated or unused memories
action: Find cleanup candidates, present for review, execute deletions

operating_mode:
  workflow: interactive_cleanup
  workflow_compliance: MANDATORY
  workflow_execution: menu_driven
  approvals: always_required
  tracking: cleanup_result
```

---

## MCP ENFORCEMENT MATRIX

**CRITICAL:** This command uses MCP tools where possible. Native MCP only - NEVER Code Mode.

```
┌─────────────────┬─────────────────────────────┬──────────┬─────────────────┐
│ SCREEN          │ REQUIRED MCP/TOOL CALLS     │ MODE     │ ON FAILURE      │
├─────────────────┼─────────────────────────────┼──────────┼─────────────────┤
│ CANDIDATE LIST  │ memory_list(limit:50)       │ SINGLE   │ Show error msg  │
├─────────────────┼─────────────────────────────┼──────────┼─────────────────┤
│ TIER SUMMARY    │ memory_stats                │ SINGLE   │ Hide summary    │
├─────────────────┼─────────────────────────────┼──────────┼─────────────────┤
│ DELETE ACTION   │ memory_delete(id)           │ PER-ITEM │ Log + continue  │
├─────────────────┼─────────────────────────────┼──────────┼─────────────────┤
│ VIEW CONTENT    │ Read (file system)          │ SINGLE   │ Error + skip    │
└─────────────────┴─────────────────────────────┴──────────┴─────────────────┘
```

**Tool Call Format:**
```
mcp__semantic_memory__memory_list({ limit: 50, sortBy: "created_at" })
mcp__semantic_memory__memory_stats({})
mcp__semantic_memory__memory_delete({ id: <memory_id> })
```

---

## 1. CONTRACT

**Inputs:** Optional `--include-critical` flag to include critical memories in suggestions
**Outputs:** `STATUS=<OK|CANCELLED|FAIL> REMOVED=<count> KEPT=<count>`

### Options

- `--include-critical` — Include critical memories in cleanup suggestions (use with caution)

---

## 2. DESIGN PRINCIPLES

1. **TIER PROTECTION** - Critical and important memories are protected by default
2. **ALWAYS PREVIEW FIRST** - Never delete without showing what
3. **INTERACTIVE** - User controls every step
4. **ESCAPE HATCH** - [c]ancel or [q]uit always available
5. **VIEW BEFORE DELETE** - [v]iew option to see content

---

## 3. IMPORTANCE TIER RULES

| Tier        | Symbol | Default Behavior                                      |
|-------------|--------|-------------------------------------------------------|
| constitutional | ⭐  | Never suggest (always protected)                      |
| critical    | !!     | Never suggest (protected, requires --include-critical)|
| important   | !      | Never suggest (protected)                             |
| normal      | -      | Suggest after 90 days if <3 accesses                  |
| temporary   | ~      | Suggest after 7 days                                  |
| deprecated  | x      | Always suggest for cleanup                            |

**Tier Symbols:** ⭐ = constitutional, !! = critical, ! = important, - = normal, ~ = temporary, x = deprecated

**Note:** Constitutional and critical memories are protected from cleanup. Use `--include-critical` flag only when absolutely necessary.

---

## 4. EXECUTION FLOW

```
/memory/cleanup [--include-critical]
    |
    +-> STEP 1: Find cleanup candidates (tier-aware)
    |       - deprecated tier: always candidates
    |       - temporary tier: older than 7 days
    |       - normal tier: older than 90 days AND <3 accesses
    |       - important/critical: protected (unless --include-critical)
    |
    +-> STEP 2: Show tier summary table
    |       - Display counts by tier
    |       - Show which tiers are protected
    |
    +-> STEP 3: Show preview table with tier column
    |       - Display candidates with age and tier info
    |       - Show memory titles and spec folders
    |
    +-> STEP 4: Get action choice
    |       - [a]ll - Remove all (with confirmation)
    |       - [n]one - Cancel, keep all
    |       - [r]eview - Step through each one
    |       - [c]ancel - Exit immediately
    |
    +-> STEP 5: If review mode
    |       - Show each with [y/n/v]iew options
    |       - [v]iew shows full content
    |       - [s]kip remaining ends early
    |
    +-> STEP 6: Execute and report
            - Show what was removed by tier
            - Show what was kept
            - Mention rebuild possibility
```

---

## 5. STEP-BY-STEP INSTRUCTIONS

### Step 1: Find Cleanup Candidates (Tier-Aware)

Execute the cleanup candidate finder with tier-aware logic:

```bash
node -e "
const vectorIndex = require('./.opencode/memory/scripts/lib/vector-index.js');
const fs = require('fs');

// Check for --include-critical flag
const includeCritical = process.argv.includes('--include-critical');

// Initialize database
vectorIndex.initializeDb();

// Get all memories
const db = vectorIndex.getDb();

// Current dates for tier-based calculations
const now = new Date();
const sevenDaysAgo = new Date(now);
sevenDaysAgo.setDate(sevenDaysAgo.getDate() - 7);
const ninetyDaysAgo = new Date(now);
ninetyDaysAgo.setDate(ninetyDaysAgo.getDate() - 90);

// Query for cleanup candidates with tier awareness
// Protected tiers (important, critical) are excluded unless --include-critical
const tierFilter = includeCritical
  ? \"importance_tier NOT IN ('important')\"
  : \"importance_tier NOT IN ('important', 'critical')\";

const candidates = db.prepare(\`
  SELECT
    id,
    spec_folder,
    file_path,
    title,
    importance_weight,
    importance_tier,
    access_count,
    created_at,
    updated_at
  FROM memory_index
  WHERE
    (
      -- deprecated tier: always suggest
      importance_tier = 'deprecated'
      OR
      -- temporary tier: after 7 days
      (importance_tier = 'temporary' AND created_at < ?)
      OR
      -- normal tier: after 90 days with low access
      (importance_tier = 'normal' AND created_at < ? AND (access_count IS NULL OR access_count < 3))
      OR
      -- Low importance weight (fallback for unmigrated)
      (importance_tier IS NULL AND importance_weight < 0.4)
    )
    AND \${tierFilter}
  ORDER BY
    CASE importance_tier
      WHEN 'deprecated' THEN 1
      WHEN 'temporary' THEN 2
      WHEN 'normal' THEN 3
      ELSE 4
    END,
    created_at ASC
  LIMIT 50
\`).all(sevenDaysAgo.toISOString(), ninetyDaysAgo.toISOString());

// Get tier summary for all memories
const tierSummary = db.prepare(\`
  SELECT
    COALESCE(importance_tier, 'unassigned') as tier,
    COUNT(*) as count
  FROM memory_index
  GROUP BY importance_tier
\`).all();

// Output as JSON for parsing
console.log(JSON.stringify({
  candidates,
  tierSummary,
  includeCritical
}, null, 2));
"
```

Parse the JSON output to get the list of candidates and tier summary.

### Step 2: Show Cleanup Summary by Tier

Display the tier breakdown first:

```
Memory Cleanup

### Cleanup Summary by Tier
| Tier       | Count | Suggested                |
|------------|-------|--------------------------|
| deprecated | X     | X                        |
| temporary  | X     | X                        |
| normal     | X     | X                        |
| important  | X     | 0 (protected)            |
| critical   | X     | 0 (protected)            |

Note: Critical and important memories are protected from cleanup.
      Use --include-critical to override (use with caution).
```

### Step 3: Show Preview Table

If candidates found, display with tier column:

```
Found <N> memories that may be outdated:

| ID  | Spec Folder            | Title                          | Tier       | Age        | Accesses | Score |
|-----|------------------------|--------------------------------|------------|------------|----------|-------|
| 42  | 006-hero-sections      | Early hero experiments         | deprecated | 4 months   | 1        | 0.3   |
| 55  | 008-external-analysis  | Deprecated API notes           | temporary  | 10 days    | 0        | 0.35  |
| 78  | 007-videos             | Old video handling approach    | normal     | 3 months   | 2        | 0.45  |

Select action:
```

If NO candidates found:

```
Memory Cleanup

No cleanup candidates found.

Your memory index is clean! All memories are:
- Recent (within retention period for their tier)
- Actively used (accessed 3+ times for normal tier)
- Important or critical tier (protected)

STATUS=OK REMOVED=0 KEPT=<total_count>
```

### Step 4: Get Action Choice (Main Menu)

Present options as numbered menu:

```
What would you like to do with these memories?

  [a] Remove all candidates - Delete all listed memories (requires confirmation)
  [r] Review each one - Step through each memory to decide individually
  [n] Keep all / None - Cancel cleanup, keep all memories
  [c] Cancel - Exit without changes

Enter choice [a/r/n/c]:
```

#### If User Selects "Remove all":

Show confirmation prompt:

```
Confirm: Remove all <N> memories? This cannot be undone.

  [y] Yes, remove all - Permanently delete all listed memories
  [n] No, go back - Return to previous menu

Enter choice [y/n]:
```

If confirmed, proceed to Step 6 (execute removal of all).

#### If User Selects "Keep all" or "Cancel":

```
Cleanup cancelled. No memories were removed.

STATUS=CANCELLED REMOVED=0 KEPT=<N>
```

#### If User Selects "Review each":

Proceed to Step 5.

### Step 5: Review Mode (Per-Item)

For EACH candidate memory, show:

```
---------------------------------------
Memory <current>/<total>: "<title>"
Spec folder: <spec_folder>
Tier: <importance_tier>
Created: <created_date>
Last updated: <updated_date>
Importance: <importance_weight>
Accesses: <access_count>
---------------------------------------

Remove this memory? [y/n/v] (or [s]kip remaining)
```

Present as inline numbered menu:

```
Remove "<title>" (tier: <importance_tier>)?

  [y] Yes, remove - Delete this memory
  [n] No, keep - Keep this memory
  [v] View content - Show full memory content before deciding
  [s] Skip remaining - End review, keep all remaining memories

Enter choice [y/n/v/s]:
```

#### If User Selects "View content":

Read the memory file and show content preview:

```bash
cat "<file_path>" | head -50
```

Display:

```
---------------------------------------
<title>
Tier: <importance_tier>
Created: <created_date>
File: <file_path>

Content preview:
---------------------------------------
<first 50 lines of file content>
---------------------------------------

(Showing first 50 lines)
```

Then re-ask the remove question:

```
Remove this memory?

  [y] Yes, remove - Delete this memory
  [n] No, keep - Keep this memory

Enter choice [y/n]:
```

#### If User Selects "Skip remaining":

Mark all remaining memories as "kept" and proceed to Step 6.

### Step 6: Execute Cleanup and Report

For each memory marked for removal, execute:

```bash
node -e "
const vectorIndex = require('./.opencode/memory/scripts/lib/vector-index.js');
vectorIndex.initializeDb();

// Delete by ID
const deleted = vectorIndex.deleteMemory(<id>);
console.log(deleted ? 'DELETED' : 'FAILED');
"
```

After all deletions complete, show summary with tier breakdown:

```
Cleanup complete!

### Removal Summary by Tier
| Tier       | Removed | Kept |
|------------|---------|------|
| deprecated | X       | X    |
| temporary  | X       | X    |
| normal     | X       | X    |
| important  | 0       | X    |
| critical   | 0       | X    |

   Total Removed: <removed_count> memories
   Total Kept: <kept_count> memories

   Tip: Memory files still exist on disk. To fully remove,
   delete the files from specs/*/memory/ folders.

   Run /memory/search verify to check index health.

STATUS=OK REMOVED=<removed_count> KEPT=<kept_count>
```

---

## 6. ERROR HANDLING

| Condition                  | Action                                           |
| -------------------------- | ------------------------------------------------ |
| Database unavailable       | Show error, suggest verify command               |
| No candidates found        | Show success message, exit cleanly               |
| File read fails            | Skip view, show error, allow y/n decision        |
| Delete operation fails     | Log error, continue with next, report at end     |
| User interrupts (Ctrl+C)   | Treat as cancel, exit without changes            |

---

## 7. OUTPUT EXAMPLES

### Example: Full Review Flow with Tiers

```
User: /memory/cleanup

System:
Memory Cleanup

### Cleanup Summary by Tier
| Tier       | Count | Suggested                |
|------------|-------|--------------------------|
| deprecated | 2     | 2                        |
| temporary  | 5     | 3                        |
| normal     | 30    | 1                        |
| important  | 8     | 0 (protected)            |
| critical   | 3     | 0 (protected)            |

Note: Critical and important memories are protected from cleanup.

Found 6 memories that may be outdated:

| ID  | Spec Folder            | Title                          | Tier       | Age        | Accesses | Score |
|-----|------------------------|--------------------------------|------------|------------|----------|-------|
| 12  | 006-hero-sections      | Early hero experiments         | deprecated | 4 months   | 1        | 0.3   |
| 15  | 008-external-analysis  | Old API exploration            | deprecated | 3 months   | 0        | 0.2   |
| 22  | 007-videos             | Temp debug notes               | temporary  | 10 days    | 0        | 0.4   |
| 28  | 009-research           | Quick test session             | temporary  | 14 days    | 1        | 0.35  |
| 33  | 010-hooks              | Scratch testing                | temporary  | 8 days     | 0        | 0.3   |
| 45  | 011-memory             | Initial approach               | normal     | 95 days    | 2        | 0.45  |

What would you like to do with these memories?
  [a] Remove all candidates
  [r] Review each one
  [n] Keep all / None
  [c] Cancel

User: r

System:
---------------------------------------
Memory 1/6: "Early hero experiments"
Spec folder: 006-hero-sections
Tier: deprecated
Created: 2024-08-15
Last updated: 2024-08-20
Importance: 0.3
Accesses: 1
---------------------------------------

Remove this memory? [y/n/v] (or [s]kip remaining)

User: y

... (continues through remaining memories)

System:
Cleanup complete!

### Removal Summary by Tier
| Tier       | Removed | Kept |
|------------|---------|------|
| deprecated | 2       | 0    |
| temporary  | 2       | 1    |
| normal     | 1       | 0    |
| important  | 0       | 8    |
| critical   | 0       | 3    |

   Total Removed: 5 memories
   Total Kept: 43 memories

   Tip: Memory files still exist on disk. To fully remove,
   delete the files from specs/*/memory/ folders.

   Run /memory/search verify to check index health.

STATUS=OK REMOVED=5 KEPT=43
```

### Example: No Candidates

```
User: /memory/cleanup

System:
Memory Cleanup

### Cleanup Summary by Tier
| Tier       | Count | Suggested                |
|------------|-------|--------------------------|
| deprecated | 0     | 0                        |
| temporary  | 2     | 0                        |
| normal     | 25    | 0                        |
| important  | 10    | 0 (protected)            |
| critical   | 5     | 0 (protected)            |

No cleanup candidates found.

Your memory index is clean! All memories are:
- Recent (within retention period for their tier)
- Actively used (accessed 3+ times for normal tier)
- Important or critical tier (protected)

STATUS=OK REMOVED=0 KEPT=42
```

### Example: With --include-critical Flag

```
User: /memory/cleanup --include-critical

System:
Memory Cleanup

WARNING: --include-critical flag is active. Critical memories will be included in suggestions.

### Cleanup Summary by Tier
| Tier       | Count | Suggested                |
|------------|-------|--------------------------|
| deprecated | 2     | 2                        |
| temporary  | 5     | 3                        |
| normal     | 30    | 1                        |
| important  | 8     | 0 (protected)            |
| critical   | 3     | 1 (UNPROTECTED!)         |

CAUTION: 1 critical memory is included in cleanup suggestions.
Review carefully before removing!

Found 7 memories that may be outdated:
...
```

### Example: Remove All

```
User: /memory/cleanup

System:
Memory Cleanup

### Cleanup Summary by Tier
| Tier       | Count | Suggested                |
|------------|-------|--------------------------|
| deprecated | 3     | 3                        |
| temporary  | 2     | 2                        |
| normal     | 35    | 0                        |
| important  | 8     | 0 (protected)            |
| critical   | 4     | 0 (protected)            |

Found 5 memories that may be outdated:
...

What would you like to do?

User: a

System:
Confirm: Remove all 5 memories? This cannot be undone.
  [Yes, remove all]
  [No, go back]

User: Yes

System:
Removing memories...
  [1/5] specs/006-hero-sections/memory/... (deprecated) REMOVED
  [2/5] specs/008-external-analysis/memory/... (deprecated) REMOVED
  [3/5] specs/007-videos/memory/... (deprecated) REMOVED
  [4/5] specs/009-research-pattern/memory/... (temporary) REMOVED
  [5/5] specs/010-comprehensive-hook/memory/... (temporary) REMOVED

Cleanup complete!

### Removal Summary by Tier
| Tier       | Removed | Kept |
|------------|---------|------|
| deprecated | 3       | 0    |
| temporary  | 2       | 0    |
| normal     | 0       | 35   |
| important  | 0       | 8    |
| critical   | 0       | 4    |

   Total Removed: 5 memories
   Total Kept: 47 memories

STATUS=OK REMOVED=5 KEPT=47
```

---

## 8. SMART DEFAULTS (INTERNAL LOGIC)

The command finds cleanup candidates using tier-aware criteria:

| Tier       | Age Threshold | Access Threshold | Always Suggest |
|------------|---------------|------------------|----------------|
| deprecated | N/A           | N/A              | Yes            |
| temporary  | 7 days        | N/A              | No             |
| normal     | 90 days       | <3 accesses      | No             |
| important  | N/A           | N/A              | Never          |
| critical   | N/A           | N/A              | Never*         |

*Unless `--include-critical` flag is used.

Additional smart defaults:

| Criterion        | Default Value | Description                      |
| ---------------- | ------------- | -------------------------------- |
| maxCandidates    | 50            | Maximum candidates to show       |
| fallbackWeight   | 0.4           | For unmigrated memories          |

---

## 9. INTEGRATION NOTES

### Database Operations

This command uses `vector-index.js` from the workflows-memory skill:

- `initializeDb()` - Initialize database connection
- `getDb()` - Get raw database for queries
- `deleteMemory(id)` - Remove memory by ID
- `getMemoryCount()` - Get total indexed count

### Tier Column Requirement

The `importance_tier` column must exist in the database. If missing, memories are treated as `normal` tier with fallback to `importance_weight` scoring.

### File Operations

Memory files on disk are NOT automatically deleted. The command only removes entries from the semantic index. To fully clean up:

1. Run `/memory/cleanup` to remove from index
2. Manually delete files from `specs/*/memory/` if desired
3. Run `/memory/search rebuild` if files are deleted

---

## 10. RELATED COMMANDS

- `/memory/search` - Search, manage index, view recent memories
- `/memory/save` - Save current conversation context
- `/memory/status` - Quick health check and statistics
- `/memory/triggers` - View and manage trigger phrases

---

## 11. QUICK REFERENCE

| Action                          | Result                                   |
| ------------------------------- | ---------------------------------------- |
| `/memory/cleanup`               | Start interactive cleanup (protected)    |
| `/memory/cleanup --include-critical` | Include critical memories           |
| Select [a]ll                    | Remove all candidates (with confirm)     |
| Select [r]eview                 | Step through each memory individually    |
| Select [n]one                   | Cancel, keep all memories                |
| Select [c]ancel                 | Exit immediately                         |
| During review: [v]iew           | Show full memory content                 |
| During review: [s]kip           | End review, keep remaining               |

### Tier Protection Summary

| Tier       | Protected | Override Flag           |
|------------|-----------|-------------------------|
| deprecated | No        | N/A                     |
| temporary  | No        | N/A                     |
| normal     | No        | N/A                     |
| important  | Yes       | Cannot override         |
| critical   | Yes       | `--include-critical`    |
