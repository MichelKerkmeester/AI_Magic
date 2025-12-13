---
description: Quick health check and memory system statistics
argument-hint: ""
allowed-tools: mcp__semantic_memory__memory_stats
---

# Memory Status

Quick health check and statistics for the memory system.

---

```yaml
role: System Health Monitor
purpose: Provide at-a-glance system status and quick actions
action: Query MCP for statistics, display dashboard

operating_mode:
  workflow: single_display
  workflow_compliance: MANDATORY
  workflow_execution: immediate
  approvals: none_required
  tracking: display_only
```

---

## MCP ENFORCEMENT MATRIX

**CRITICAL:** This command requires MCP tool calls. Native MCP only - NEVER Code Mode.

```
┌─────────────────┬─────────────────────────────┬──────────┬─────────────────┐
│ SCREEN          │ REQUIRED MCP CALLS          │ MODE     │ ON FAILURE      │
├─────────────────┼─────────────────────────────┼──────────┼─────────────────┤
│ STATUS DISPLAY  │ memory_stats                │ SINGLE   │ Show error msg  │
└─────────────────┴─────────────────────────────┴──────────┴─────────────────┘
```

**Tool Call Format:**
```
mcp__semantic_memory__memory_stats({})
```

---

## 1. CONTRACT

**Inputs:** `$ARGUMENTS` - None required (status is always displayed)
**Outputs:** `STATUS=OK|DEGRADED|ERROR`

---

## 2. EXECUTION

When called, immediately gather and display system status:

### Step 1: Query Statistics via MCP

Call the MCP tool directly (NEVER through Code Mode):

```
mcp__semantic_memory__memory_stats({})
```

**Expected Response Fields:**
```json
{
  "total_memories": 47,
  "by_tier": {
    "constitutional": 2,
    "critical": 5,
    "important": 12,
    "normal": 25,
    "temporary": 3,
    "deprecated": 0
  },
  "by_status": {
    "pending": 0,
    "success": 47,
    "failed": 0,
    "retry": 0
  },
  "database_size_mb": 12.5,
  "last_created": "2024-12-13T10:30:00Z",
  "last_updated": "2024-12-13T14:15:00Z",
  "top_folders": [
    { "folder": "005-memory", "count": 8 },
    { "folder": "006-code-refinement", "count": 5 }
  ]
}
```

### Step 2: Format Relative Time

Convert timestamps to human-readable format:
- < 1 minute: "Just now"
- < 60 minutes: "N minutes ago"
- < 24 hours: "N hours ago"
- < 7 days: "N days ago"
- Otherwise: Date format

### Step 3: Determine Health Status

```
If success > 0 AND failed == 0 AND pending == 0:
   Health: "All systems operational"
   StatusCode: OK

Else if failed > 0 AND failed < 5:
   Health: "[failed] embeddings need attention"
   StatusCode: DEGRADED

Else if failed >= 5:
   Health: "[failed] failed embeddings - run retry"
   StatusCode: DEGRADED

Else if pending > 0:
   Health: "[pending] memories awaiting processing"
   StatusCode: DEGRADED
```

---

## 3. DISPLAY FORMAT

```
┌────────────────────────────────────────────────────────────────┐
│                    MEMORY SYSTEM STATUS                        │
├────────────────────────────────────────────────────────────────┤
│                                                                │
│  OVERVIEW [via: memory_stats]                                  │
│  ─────────────────────────────────────────                     │
│  Memories:     <total> indexed                                 │
│  Health:       <health_indicator>                              │
│  Last save:    <relative_time>                                 │
│  Last update:  <relative_time>                                 │
│                                                                │
│  BY TIER                                                       │
│  ─────────────────────────────────────────                     │
│  ⭐ Constitutional: <count>                                    │
│  !! Critical:       <count>                                    │
│  !  Important:      <count>                                    │
│  -  Normal:         <count>                                    │
│  ~  Temporary:      <count>                                    │
│  x  Deprecated:     <count>                                    │
│                                                                │
│  STORAGE                                                       │
│  ─────────────────────────────────────────                     │
│  Database size: <size> MB                                      │
│                                                                │
├────────────────────────────────────────────────────────────────┤
│  Quick actions: [s]earch [c]leanup [r]ebuild index             │
└────────────────────────────────────────────────────────────────┘

STATUS=<OK|DEGRADED|ERROR>
```

### Health Indicators

| Condition | Health Message | Status Code |
|-----------|----------------|-------------|
| All healthy | "All systems operational" | OK |
| < 5 failed | "[N] embeddings need attention" | DEGRADED |
| >= 5 failed | "[N] failed embeddings - run retry" | DEGRADED |
| Pending > 0 | "[N] awaiting processing" | DEGRADED |
| MCP fails | "Unable to reach memory service" | ERROR |

### Example Outputs

**Healthy System:**
```
┌────────────────────────────────────────────────────────────────┐
│                    MEMORY SYSTEM STATUS                        │
├────────────────────────────────────────────────────────────────┤
│                                                                │
│  OVERVIEW [via: memory_stats]                                  │
│  ─────────────────────────────────────────                     │
│  Memories:     47 indexed                                      │
│  Health:       All systems operational                         │
│  Last save:    2 hours ago                                     │
│  Last update:  15 minutes ago                                  │
│                                                                │
│  BY TIER                                                       │
│  ─────────────────────────────────────────                     │
│  ⭐ Constitutional: 2                                          │
│  !! Critical:       5                                          │
│  !  Important:      12                                         │
│  -  Normal:         25                                         │
│  ~  Temporary:      3                                          │
│  x  Deprecated:     0                                          │
│                                                                │
│  STORAGE                                                       │
│  ─────────────────────────────────────────                     │
│  Database size: 12.5 MB                                        │
│                                                                │
├────────────────────────────────────────────────────────────────┤
│  Quick actions: [s]earch [c]leanup [r]ebuild index             │
└────────────────────────────────────────────────────────────────┘

STATUS=OK
```

**System with Issues:**
```
┌────────────────────────────────────────────────────────────────┐
│                    MEMORY SYSTEM STATUS                        │
├────────────────────────────────────────────────────────────────┤
│                                                                │
│  OVERVIEW [via: memory_stats]                                  │
│  ─────────────────────────────────────────                     │
│  Memories:     42 indexed                                      │
│  Health:       3 embeddings need attention                     │
│  Last save:    1 day ago                                       │
│  Last update:  1 day ago                                       │
│                                                                │
│  ⚠ ISSUES DETECTED                                             │
│  ─────────────────────────────────────────                     │
│  Pending:      2 awaiting processing                           │
│  Failed:       3 need retry                                    │
│                                                                │
│  Tip: Run /memory/search retry to fix failed embeddings        │
│                                                                │
├────────────────────────────────────────────────────────────────┤
│  Quick actions: [s]earch [c]leanup [r]ebuild index             │
└────────────────────────────────────────────────────────────────┘

STATUS=DEGRADED
```

**Error State (MCP Failure):**
```
┌────────────────────────────────────────────────────────────────┐
│                    MEMORY SYSTEM STATUS                        │
├────────────────────────────────────────────────────────────────┤
│                                                                │
│  ⚠ Unable to reach memory service                              │
│                                                                │
│  Error: <error_message>                                        │
│                                                                │
│  Troubleshooting:                                              │
│  - Check if semantic memory MCP server is running              │
│  - Verify database file exists                                 │
│  - Check MCP configuration in .mcp.json                        │
│                                                                │
├────────────────────────────────────────────────────────────────┤
│  [r]etry │ [q]uit                                              │
└────────────────────────────────────────────────────────────────┘

STATUS=ERROR
```

---

## 4. QUICK ACTIONS

The status display suggests quick actions the user can take:

| Key | Action                     | Command              |
| --- | -------------------------- | -------------------- |
| [s] | Search memories            | `/memory/search`     |
| [c] | Cleanup old entries        | `/memory/cleanup`    |
| [r] | Rebuild index              | `/memory/search rebuild` |

These are informational - the user types the full command if they want to proceed.

---

## 5. STATUS CODES

| Code     | Meaning                           |
| -------- | --------------------------------- |
| OK       | All systems healthy               |
| DEGRADED | Some issues but functional        |
| ERROR    | Critical issue, action required   |

---

## 6. USER-FRIENDLY LANGUAGE

This command uses plain English:

| Technical Term      | User-Friendly Version              |
| ------------------- | ---------------------------------- |
| Embedding           | "indexed" or "processed"           |
| sqlite-vec          | "vector search"                    |
| Orphaned entry      | "entry without file"               |
| Missing vector      | "file not processed"               |
| importance_tier     | Tier symbols (⭐ !! ! - ~ x)       |

---

## 7. ERROR HANDLING

| Condition            | Action                                |
| -------------------- | ------------------------------------- |
| MCP tool fails       | Show error state with troubleshooting |
| No memories yet      | Show "No memories indexed - run /memory/save first" |
| Network timeout      | Show "Connection timeout - [r]etry"   |

---

## 8. RELATED COMMANDS

- `/memory/search` - Search and manage memories
- `/memory/triggers` - View learned trigger phrases
- `/memory/save` - Save current context
- `/memory/cleanup` - Clean up old memories

---

## 9. FULL DOCUMENTATION

For comprehensive documentation:
`.opencode/skills/workflows-memory/SKILL.md`
