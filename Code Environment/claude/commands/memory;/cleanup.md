---
description: Interactively clean up old or unused memories
argument-hint: ""
allowed-tools: Read, Bash, AskUserQuestion
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

## 1. 📝 CONTRACT

**Inputs:** None required (NO FLAGS - works without parameters)
**Outputs:** `STATUS=<OK|CANCELLED|FAIL> REMOVED=<count> KEPT=<count>`

---

## 2. 📋 DESIGN PRINCIPLES

1. **NO FLAGS** - Command works without any parameters
2. **ALWAYS PREVIEW FIRST** - Never delete without showing what
3. **INTERACTIVE** - User controls every step
4. **ESCAPE HATCH** - [c]ancel or [q]uit always available
5. **VIEW BEFORE DELETE** - [v]iew option to see content

---

## 3. 🔀 EXECUTION FLOW

```
/memory/cleanup
    |
    +-> STEP 1: Find cleanup candidates (smart defaults)
    |       - Memories older than 90 days
    |       - Accessed less than 3 times
    |       - Low confidence score (<0.4)
    |
    +-> STEP 2: Show preview table
    |       - Display candidates with age info
    |       - Show memory titles and spec folders
    |
    +-> STEP 3: Get action choice
    |       - [a]ll - Remove all (with confirmation)
    |       - [n]one - Cancel, keep all
    |       - [r]eview - Step through each one
    |       - [c]ancel - Exit immediately
    |
    +-> STEP 4: If review mode
    |       - Show each with [y/n/v]iew options
    |       - [v]iew shows full content
    |       - [s]kip remaining ends early
    |
    +-> STEP 5: Execute and report
            - Show what was removed
            - Show what was kept
            - Mention rebuild possibility
```

---

## 4. ⚡ STEP-BY-STEP INSTRUCTIONS

### Step 1: Find Cleanup Candidates

Execute the cleanup candidate finder with smart defaults:

```bash
node -e "
const vectorIndex = require('./.claude/skills/workflows-memory/scripts/lib/vector-index.js');
const fs = require('fs');

// Initialize database
vectorIndex.initializeDb();

// Get all memories
const db = vectorIndex.getDb();
const cutoffDate = new Date();
cutoffDate.setDate(cutoffDate.getDate() - 90);

// Query for cleanup candidates: old, low-usage, or low-importance memories
const candidates = db.prepare(\`
  SELECT
    id,
    spec_folder,
    file_path,
    title,
    importance_weight,
    created_at,
    updated_at
  FROM memory_index
  WHERE
    created_at < ?
    OR importance_weight < 0.4
  ORDER BY created_at ASC
  LIMIT 50
\`).all(cutoffDate.toISOString());

// Output as JSON for parsing
console.log(JSON.stringify(candidates, null, 2));
"
```

Parse the JSON output to get the list of candidates.

### Step 2: Show Preview Table

If candidates found, display:

```
Memory Cleanup

Found <N> memories that may be outdated:

 | Last Updated | Spec Folder            | Memory Title                   |
 |--------------|------------------------|--------------------------------|
 | 4 months ago | 006-hero-sections      | Early hero experiments         |
 | 3 months ago | 008-external-analysis  | Deprecated API notes           |
 | 2 months ago | 007-videos             | Old video handling approach    |

Select action:
```

If NO candidates found:

```
Memory Cleanup

No cleanup candidates found.

Your memory index is clean! All memories are:
- Recent (within 90 days)
- Actively used (accessed 3+ times)
- Good quality (confidence >0.4)

STATUS=OK REMOVED=0 KEPT=<total_count>
```

### Step 3: Get Action Choice (Main Menu)

Use AskUserQuestion to present options:

```yaml
question: "What would you like to do with these memories?"
options:
  - label: "[a] Remove all candidates"
    description: "Delete all listed memories (requires confirmation)"
  - label: "[r] Review each one"
    description: "Step through each memory to decide individually"
  - label: "[n] Keep all / None"
    description: "Cancel cleanup, keep all memories"
  - label: "[c] Cancel"
    description: "Exit without changes"
```

#### If User Selects "Remove all":

Show confirmation prompt:

```yaml
question: "Confirm: Remove all <N> memories? This cannot be undone."
options:
  - label: "Yes, remove all"
    description: "Permanently delete all listed memories"
  - label: "No, go back"
    description: "Return to previous menu"
```

If confirmed, proceed to Step 5 (execute removal of all).

#### If User Selects "Keep all" or "Cancel":

```
Cleanup cancelled. No memories were removed.

STATUS=CANCELLED REMOVED=0 KEPT=<N>
```

#### If User Selects "Review each":

Proceed to Step 4.

### Step 4: Review Mode (Per-Item)

For EACH candidate memory, show:

```
---------------------------------------
Memory <current>/<total>: "<title>"
Spec folder: <spec_folder>
Created: <created_date>
Last updated: <updated_date>
Importance: <importance_weight>
---------------------------------------

Remove this memory? [y/n/v] (or [s]kip remaining)
```

Use AskUserQuestion:

```yaml
question: "Remove \"<title>\"?"
options:
  - label: "[y] Yes, remove"
    description: "Delete this memory"
  - label: "[n] No, keep"
    description: "Keep this memory"
  - label: "[v] View content"
    description: "Show full memory content before deciding"
  - label: "[s] Skip remaining"
    description: "End review, keep all remaining memories"
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
Created: <created_date>
File: <file_path>

Content preview:
---------------------------------------
<first 50 lines of file content>
---------------------------------------

(Showing first 50 lines)
```

Then re-ask the remove question:

```yaml
question: "Remove this memory?"
options:
  - label: "[y] Yes, remove"
    description: "Delete this memory"
  - label: "[n] No, keep"
    description: "Keep this memory"
```

#### If User Selects "Skip remaining":

Mark all remaining memories as "kept" and proceed to Step 5.

### Step 5: Execute Cleanup and Report

For each memory marked for removal, execute:

```bash
node -e "
const vectorIndex = require('./.claude/skills/workflows-memory/scripts/lib/vector-index.js');
vectorIndex.initializeDb();

// Delete by ID
const deleted = vectorIndex.deleteMemory(<id>);
console.log(deleted ? 'DELETED' : 'FAILED');
"
```

After all deletions complete, show summary:

```
Cleanup complete!

   Removed: <removed_count> memories
   Kept: <kept_count> memories

   Tip: Memory files still exist on disk. To fully remove,
   delete the files from specs/*/memory/ folders.

   Run /memory/search verify to check index health.

STATUS=OK REMOVED=<removed_count> KEPT=<kept_count>
```

---

## 5. ⚠️ ERROR HANDLING

| Condition                  | Action                                           |
| -------------------------- | ------------------------------------------------ |
| Database unavailable       | Show error, suggest verify command               |
| No candidates found        | Show success message, exit cleanly               |
| File read fails            | Skip view, show error, allow y/n decision        |
| Delete operation fails     | Log error, continue with next, report at end     |
| User interrupts (Ctrl+C)   | Treat as cancel, exit without changes            |

---

## 6. 📊 OUTPUT EXAMPLES

### Example: Full Review Flow

```
User: /memory/cleanup

System:
Memory Cleanup

Found 3 memories that may be outdated:

 | Last Updated | Spec Folder            | Memory Title                   |
 |--------------|------------------------|--------------------------------|
 | 4 months ago | 006-hero-sections      | Early hero experiments         |
 | 3 months ago | 008-external-analysis  | Deprecated API notes           |
 | 2 months ago | 007-videos             | Old video handling approach    |

What would you like to do with these memories?
  [a] Remove all candidates
  [r] Review each one
  [n] Keep all / None
  [c] Cancel

User: r

System:
---------------------------------------
Memory 1/3: "Early hero experiments"
Spec folder: 006-hero-sections
Created: 2024-08-15
Last updated: 2024-08-20
Importance: 0.3
---------------------------------------

Remove this memory? [y/n/v] (or [s]kip remaining)

User: v

System:
---------------------------------------
Early hero experiments
Created: 2024-08-15
File: specs/006-hero-sections/memory/15-08-24_10-30__hero-experiments.md

Content preview:
---------------------------------------
# Early Hero Experiments

## Session Summary
We tried using parallax scrolling for the hero section but ran into
performance issues on mobile. Switching to CSS transforms instead...

## Key Decisions
- Abandoned parallax in favor of simpler transforms
- Mobile-first approach for animations
...
---------------------------------------

(Showing first 50 lines)

Remove this memory? [y/n]

User: y

System:
---------------------------------------
Memory 2/3: "Deprecated API notes"
Spec folder: 008-external-analysis
Created: 2024-09-01
Last updated: 2024-09-05
Importance: 0.35
---------------------------------------

Remove this memory? [y/n/v] (or [s]kip remaining)

User: n

System:
---------------------------------------
Memory 3/3: "Old video handling approach"
Spec folder: 007-videos
Created: 2024-10-01
Last updated: 2024-10-15
Importance: 0.25
---------------------------------------

Remove this memory? [y/n/v] (or [s]kip remaining)

User: y

System:
Cleanup complete!

   Removed: 2 memories
   Kept: 1 memory

   Tip: Memory files still exist on disk. To fully remove,
   delete the files from specs/*/memory/ folders.

   Run /memory/search verify to check index health.

STATUS=OK REMOVED=2 KEPT=1
```

### Example: No Candidates

```
User: /memory/cleanup

System:
Memory Cleanup

No cleanup candidates found.

Your memory index is clean! All memories are:
- Recent (within 90 days)
- Actively used
- Good quality (confidence >0.4)

STATUS=OK REMOVED=0 KEPT=42
```

### Example: Remove All

```
User: /memory/cleanup

System:
Memory Cleanup

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
  [1/5] specs/006-hero-sections/memory/... REMOVED
  [2/5] specs/008-external-analysis/memory/... REMOVED
  [3/5] specs/007-videos/memory/... REMOVED
  [4/5] specs/009-research-pattern/memory/... REMOVED
  [5/5] specs/010-comprehensive-hook/memory/... REMOVED

Cleanup complete!

   Removed: 5 memories
   Kept: 37 memories

STATUS=OK REMOVED=5 KEPT=37
```

---

## 7. 🧠 SMART DEFAULTS (INTERNAL LOGIC)

The command finds cleanup candidates using these criteria (user never sees these):

| Criterion        | Default Value | Description                      |
| ---------------- | ------------- | -------------------------------- |
| maxAgeDays       | 90            | Memories older than 3 months     |
| maxAccessCount   | 2             | Accessed less than 3 times       |
| maxConfidence    | 0.4           | Low importance/confidence score  |
| maxCandidates    | 50            | Maximum candidates to show       |

These defaults are tuned for typical usage patterns but may be adjusted in future versions.

---

## 8. 🔧 INTEGRATION NOTES

### Database Operations

This command uses `vector-index.js` from the workflows-memory skill:

- `initializeDb()` - Initialize database connection
- `getDb()` - Get raw database for queries
- `deleteMemory(id)` - Remove memory by ID
- `getMemoryCount()` - Get total indexed count

### File Operations

Memory files on disk are NOT automatically deleted. The command only removes entries from the semantic index. To fully clean up:

1. Run `/memory/cleanup` to remove from index
2. Manually delete files from `specs/*/memory/` if desired
3. Run `/memory/search rebuild` if files are deleted

### Future: findCleanupCandidates

Agent 8 (Task T2.6) will implement `findCleanupCandidates()` in vector-index.js with advanced criteria. When available, replace the inline SQL query in Step 1 with:

```javascript
const candidates = vectorIndex.findCleanupCandidates({
  maxAgeDays: 90,
  maxAccessCount: 2,
  maxConfidence: 0.4
});
```

---

## 9. 🔗 RELATED COMMANDS

- `/memory/search` - Search, manage index, view recent memories
- `/memory/save` - Save current conversation context
- `/memory/search verify` - Check index health after cleanup
- `/memory/search rebuild` - Rebuild index from files

---

## 10. 📋 QUICK REFERENCE

| Action                | Result                                   |
| --------------------- | ---------------------------------------- |
| `/memory/cleanup`     | Start interactive cleanup                |
| Select [a]ll          | Remove all candidates (with confirm)     |
| Select [r]eview       | Step through each memory individually    |
| Select [n]one         | Cancel, keep all memories                |
| Select [c]ancel       | Exit immediately                         |
| During review: [v]iew | Show full memory content                 |
| During review: [s]kip | End review, keep remaining               |
