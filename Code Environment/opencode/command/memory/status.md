---
description: Quick health check and memory system statistics
argument-hint: ""
allowed-tools: Read, Bash
---

# Memory Status

Quick health check and statistics for the memory system.

---

```yaml
role: System Health Monitor
purpose: Provide at-a-glance system status and quick actions
action: Query database, check health, display statistics

operating_mode:
  workflow: single_display
  workflow_compliance: MANDATORY
  workflow_execution: immediate
  approvals: none_required
  tracking: display_only
```

---

## 1. 📝 CONTRACT

**Inputs:** `$ARGUMENTS` - None required (status is always displayed)
**Outputs:** `STATUS=OK|DEGRADED|ERROR`

---

## 2. ⚡ EXECUTION

When called, immediately gather and display system status:

### Step 1: Query Statistics

```bash
node -e "
const path = require('path');
const fs = require('fs');
const os = require('os');

// Load vector-index module
const vi = require('./.claude/skills/workflows-memory/scripts/lib/vector-index.js');

// Initialize and get database
const db = vi.initializeDb();

// Get counts by status
const stats = vi.getStatusCounts();
const total = stats.pending + stats.success + stats.failed + stats.retry;

// Get database file info
const dbPath = vi.getDbPath();
let dbSize = 0;
try {
  const stat = fs.statSync(dbPath);
  dbSize = (stat.size / 1024 / 1024).toFixed(2);
} catch (e) {
  dbSize = '?';
}

// Check sqlite-vec availability
const vecAvailable = vi.isVectorSearchAvailable();

// Get last activity timestamps
const lastSave = db.prepare('SELECT MAX(created_at) as ts FROM memory_index').get();
const lastUpdate = db.prepare('SELECT MAX(updated_at) as ts FROM memory_index').get();

// Verify integrity (quick check)
let integrity = { isConsistent: true, orphanedVectors: 0, missingVectors: 0 };
try {
  integrity = vi.verifyIntegrity();
} catch (e) {
  // sqlite-vec not available, skip integrity check
}

// Format timestamps
function formatTimestamp(ts) {
  if (!ts) return 'Never';
  const date = new Date(ts);
  const now = new Date();
  const diffMs = now - date;
  const diffMins = Math.floor(diffMs / 60000);
  const diffHours = Math.floor(diffMs / 3600000);
  const diffDays = Math.floor(diffMs / 86400000);

  if (diffMins < 1) return 'Just now';
  if (diffMins < 60) return diffMins + ' minutes ago';
  if (diffHours < 24) return diffHours + ' hours ago';
  if (diffDays < 7) return diffDays + ' days ago';
  return date.toLocaleDateString();
}

// Output JSON for parsing
console.log(JSON.stringify({
  total,
  success: stats.success,
  pending: stats.pending,
  failed: stats.failed,
  retry: stats.retry,
  dbSize,
  vecAvailable,
  lastSave: lastSave?.ts || null,
  lastUpdate: lastUpdate?.ts || null,
  lastSaveFormatted: formatTimestamp(lastSave?.ts),
  lastUpdateFormatted: formatTimestamp(lastUpdate?.ts),
  isConsistent: integrity.isConsistent,
  orphaned: integrity.orphanedVectors,
  missing: integrity.missingVectors
}));
"
```

### Step 2: Parse and Display

Based on the JSON output, display the status dashboard:

---

## 3. 📊 DISPLAY FORMAT

```
Memory System Status

 Memories:     47 indexed
 Health:       [HEALTH_INDICATOR]
 Last save:    [LAST_SAVE]
 Last update:  [LAST_UPDATE]

 Storage:      [SIZE] MB used
 Performance:  Vector search [VEC_STATUS]

 Quick actions: [s]earch [c]leanup [r]ebuild index
```

### Health Indicators

Determine the health indicator based on collected data:

```
If vecAvailable AND isConsistent AND failed == 0:
   Health: "All systems operational"

Else if failed > 0 AND failed < 5:
   Health: "[failed] embeddings need attention"

Else if NOT vecAvailable:
   Health: "Degraded - sqlite-vec unavailable (keyword search only)"

Else if NOT isConsistent:
   Health: "Index inconsistency detected - run cleanup"

Else if failed >= 5:
   Health: "[failed] failed embeddings - run retry"
```

### Example Outputs

**Healthy System:**
```
Memory System Status

 Memories:     47 indexed
 Health:       All systems operational
 Last save:    2 hours ago
 Last update:  15 minutes ago

 Storage:      12.5 MB used
 Performance:  Vector search available

 Quick actions: [s]earch [c]leanup [r]ebuild index

STATUS=OK
```

**System with Issues:**
```
Memory System Status

 Memories:     42 indexed
 Health:       3 embeddings need attention
 Last save:    1 day ago
 Last update:  1 day ago

 Storage:      8.2 MB used
 Performance:  Vector search available

 Pending:      2 awaiting processing
 Failed:       3 need retry

 Quick actions: [s]earch [c]leanup [r]ebuild index

Tip: Run /memory/search retry to fix failed embeddings

STATUS=DEGRADED
```

**Degraded Mode:**
```
Memory System Status

 Memories:     35 indexed
 Health:       Degraded - sqlite-vec unavailable
 Last save:    3 hours ago
 Last update:  3 hours ago

 Storage:      5.1 MB used
 Performance:  Keyword search only (no vectors)

 Quick actions: [s]earch [r]ebuild index

Note: Install sqlite-vec for full semantic search:
      brew install sqlite-vec (macOS)

STATUS=DEGRADED
```

---

## 4. ⚡ QUICK ACTIONS

The status display suggests quick actions the user can take:

| Key | Action                     | Command              |
| --- | -------------------------- | -------------------- |
| [s] | Search memories            | `/memory/search`     |
| [c] | Cleanup orphaned entries   | `/memory/search verify --fix` |
| [r] | Rebuild index              | `/memory/search rebuild` |

These are informational - the user types the full command if they want to proceed.

---

## 5. 📋 DETAILED BREAKDOWN

When there are issues, show additional detail:

### If pending > 0:
```
 Pending:      [N] awaiting processing
```

### If failed > 0:
```
 Failed:       [N] need retry
 Tip: Run /memory/search retry to fix failed embeddings
```

### If orphaned > 0 or missing > 0:
```
 Orphaned:     [N] entries without files
 Missing:      [N] files without embeddings
 Tip: Run /memory/search verify --fix to cleanup
```

---

## 6. 🔢 STATUS CODES

| Code     | Meaning                           |
| -------- | --------------------------------- |
| OK       | All systems healthy               |
| DEGRADED | Some issues but functional        |
| ERROR    | Critical issue, action required   |

---

## 7. 💬 NO-JARGON LANGUAGE

This command uses plain English:

| Technical Term      | User-Friendly Version              |
| ------------------- | ---------------------------------- |
| Embedding           | "indexed" or "processed"           |
| sqlite-vec          | "vector search"                    |
| Orphaned entry      | "entry without file"               |
| Missing vector      | "file not processed"               |
| WAL mode            | (not shown)                        |
| Cosine distance     | (not shown)                        |

---

## 8. 🔧 IMPLEMENTATION

Execute this Node.js script to gather all data:

```javascript
// status-check.js - executed inline
const path = require('path');
const fs = require('fs');
const vi = require('./.claude/skills/workflows-memory/scripts/lib/vector-index.js');

// Gather all statistics
const db = vi.initializeDb();
const stats = vi.getStatusCounts();
const total = stats.pending + stats.success + stats.failed + stats.retry;

// Database size
const dbPath = vi.getDbPath();
let dbSizeMB = 0;
try {
  dbSizeMB = (fs.statSync(dbPath).size / 1024 / 1024).toFixed(1);
} catch (e) { /* ignore */ }

// Vector availability
const vecAvailable = vi.isVectorSearchAvailable();

// Timestamps
const lastSave = db.prepare('SELECT MAX(created_at) as ts FROM memory_index').get();

// Format relative time
function relativeTime(ts) {
  if (!ts) return 'Never';
  const diffMs = Date.now() - new Date(ts).getTime();
  const mins = Math.floor(diffMs / 60000);
  if (mins < 60) return mins + ' minutes ago';
  const hours = Math.floor(diffMs / 3600000);
  if (hours < 24) return hours + ' hours ago';
  return Math.floor(diffMs / 86400000) + ' days ago';
}

// Integrity check
let integrity = { isConsistent: true, orphanedVectors: 0, missingVectors: 0 };
if (vecAvailable) {
  try { integrity = vi.verifyIntegrity(); } catch (e) { /* ignore */ }
}

// Determine health status
let health, statusCode;
if (vecAvailable && integrity.isConsistent && stats.failed === 0) {
  health = 'All systems operational';
  statusCode = 'OK';
} else if (!vecAvailable) {
  health = 'Degraded - sqlite-vec unavailable';
  statusCode = 'DEGRADED';
} else if (stats.failed > 0) {
  health = stats.failed + ' embeddings need attention';
  statusCode = 'DEGRADED';
} else {
  health = 'Index inconsistency detected';
  statusCode = 'DEGRADED';
}

// Output
console.log('');
console.log('Memory System Status');
console.log('');
console.log(' Memories:     ' + total + ' indexed');
console.log(' Health:       ' + health);
console.log(' Last save:    ' + relativeTime(lastSave?.ts));
console.log('');
console.log(' Storage:      ' + dbSizeMB + ' MB used');
console.log(' Performance:  ' + (vecAvailable ? 'Vector search available' : 'Keyword search only'));
console.log('');

if (stats.pending > 0 || stats.failed > 0) {
  if (stats.pending > 0) console.log(' Pending:      ' + stats.pending + ' awaiting processing');
  if (stats.failed > 0) console.log(' Failed:       ' + stats.failed + ' need retry');
  console.log('');
}

console.log(' Quick actions: [s]earch [c]leanup [r]ebuild index');
console.log('');
console.log('STATUS=' + statusCode);
```

---

## 9. ⚠️ ERROR HANDLING

| Condition            | Action                                |
| -------------------- | ------------------------------------- |
| Database not found   | Show "No memories yet - run /memory/save first" |
| Module load fails    | Show "System not initialized"         |
| Permission error     | Show "Cannot access database"         |

---

## 10. 🔗 RELATED COMMANDS

- `/memory/search` - Search and manage memories
- `/memory/triggers` - View learned trigger phrases
- `/memory/save` - Save current context

---

## 11. 📖 FULL DOCUMENTATION

For comprehensive documentation:
`.claude/skills/workflows-memory/SKILL.md`
