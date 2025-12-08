---
description: Resume work on an existing spec folder - loads context, shows progress, and continues from last state
argument-hint: "[spec-folder-path]"
allowed-tools: Read, Write, Edit, Bash, Grep, Glob, Task, AskUserQuestion
---

# SpecKit Resume

## 1. 📋 PURPOSE

Resume work on an existing spec folder by automatically detecting the last active session, loading context from memory files, and presenting progress with clear next steps.

---

## 2. 🔍 USAGE

| Command                        | Result                                     |
| ------------------------------ | ------------------------------------------ |
| `/spec_kit:resume`             | Auto-detect and resume most recent session |
| `/spec_kit:resume specs/014-*` | Resume specific spec folder                |
| `/spec_kit:resume:auto`        | Resume without confirmation prompts        |

---

## 3. ⚡ EXECUTION STEPS

### Step 1: Session Detection

```bash
# Priority 1: Check for active spec marker
if [ -f ".spec-active" ]; then
  SPEC_FOLDER=$(cat .spec-active)
elif [ -f ".claude/.spec-active" ]; then
  SPEC_FOLDER=$(cat .claude/.spec-active)
else
  # Priority 2: Find most recent memory file
  SPEC_FOLDER=$(find specs -path "*/memory/*.md" -type f 2>/dev/null | \
    xargs ls -t 2>/dev/null | head -1 | sed 's|/memory/.*||')
fi

# Validate spec folder exists
if [ ! -d "$SPEC_FOLDER" ]; then
  echo "No active session found. Use /spec_kit:complete to start."
  exit 1
fi
```

### Step 2: Load Memory Context

```bash
MEMORY_DIR="$SPEC_FOLDER/memory"

# Find most recent memory file
if [ -d "$MEMORY_DIR" ]; then
  RECENT_MEMORY=$(ls -t "$MEMORY_DIR"/*.md 2>/dev/null | head -1)
  
  if [ -n "$RECENT_MEMORY" ]; then
    # Extract key sections
    PENDING=$(sed -n '/^### Pending Work/,/^##/{p}' "$RECENT_MEMORY" | head -10)
    NEXT_ACTIONS=$(sed -n '/^### Next Session Actions/,/^##/{p}' "$RECENT_MEMORY" | head -8)
  fi
fi
```

### Step 3: Calculate Progress

```bash
# Task progress
TASKS_DONE=$(grep -cE '\[x\]' "$SPEC_FOLDER/tasks.md" 2>/dev/null || echo 0)
TASKS_TOTAL=$(grep -cE '\[[x ]\]' "$SPEC_FOLDER/tasks.md" 2>/dev/null || echo 0)
TASKS_PERCENT=$((TASKS_TOTAL > 0 ? TASKS_DONE * 100 / TASKS_TOTAL : 0))

# Checklist progress (if exists)
if [ -f "$SPEC_FOLDER/checklist.md" ]; then
  CHK_DONE=$(grep -cE '\[x\]' "$SPEC_FOLDER/checklist.md" 2>/dev/null || echo 0)
  CHK_TOTAL=$(grep -cE '\[[x ]\]' "$SPEC_FOLDER/checklist.md" 2>/dev/null || echo 0)
  CHK_PERCENT=$((CHK_TOTAL > 0 ? CHK_DONE * 100 / CHK_TOTAL : 0))
else
  CHK_PERCENT="--"
fi
```

### Step 4: Display Resume Summary

```text
┌───────────────────────────────────────────────────────────────┐
│  🔄 RESUMING SESSION                                          │
│  specs/014-context-aware-permission-system/                   │
│                                                               │
│  Last Activity: 2 hours ago                                   │
│  Documentation Level: 3                                       │
│                                                               │
│  PROGRESS                                                     │
│    Tasks:     ████████████████████████████████░░░░ 80% (40/50)│
│    Checklist: ██████████████████████████████████░░ 92% (46/50)│
│                                                               │
│  ARTIFACTS                                                    │
│    spec.md ✓ | plan.md ✓ | tasks.md ✓ | checklist.md ✓        │
│                                                               │
│  PENDING WORK                                                 │
│    • Phase 5: Final verification                               │
│    • Phase 6: Documentation updates                           │
│                                                               │
│  NEXT ACTIONS                                                 │
│    1. Complete remaining P2 checklist items                   │
│    2. Update spec 014 documentation                           │
│    3. Commit all changes                                      │
└───────────────────────────────────────────────────────────────┘
```

### Step 5: Memory File Selection (unless :auto mode)

Present options for loading prior context:

```text
Load previous context?

  A) Load most recent memory file
  B) Load all recent files (comprehensive context)
  C) Select specific file
  D) Skip - start fresh without prior context
```

### Step 6: Execute Resume

Based on user selection:
- **Option A**: Read most recent memory file, extract context
- **Option B**: Read all memory files from last 7 days
- **Option C**: List files with timestamps, user selects
- **Option D**: Proceed without loading memory

After loading, present continuation options:

```text
Ready to continue. What would you like to do?

  A) Continue from pending work
  B) Run /spec_kit:status for detailed progress
  C) Run /spec_kit:implement to execute remaining tasks
  D) Just chat - I'll work on it myself
```

---

## 4. 📊 OUTPUT FORMAT

### Success Output

```text
╭─────────────────────────────────────────────────────────────╮
│ ✅ SESSION RESUMED                                          │
├─────────────────────────────────────────────────────────────┤
│ Spec: specs/014-context-aware-permission-system/            │
│ Context: Loaded from session-20251206-203430.md             │
│ Progress: 96% complete (49/51 tasks)                        │
│                                                             │
│ Ready to continue. What would you like to work on?          │
╰─────────────────────────────────────────────────────────────╯
```

### No Session Found

```text
╭─────────────────────────────────────────────────────────────╮
│ ⚠️  NO ACTIVE SESSION                                       │
├─────────────────────────────────────────────────────────────┤
│ No .spec-active marker found.                               │
│ No recent spec folders with incomplete tasks.               │
├─────────────────────────────────────────────────────────────┤
│ OPTIONS                                                     │
│   • Run /spec_kit:complete to start a new workflow           │
│   • Run /spec_kit:status all to view all specs              │
│   • Specify folder: /spec_kit:resume specs/014-*/           │
╰─────────────────────────────────────────────────────────────╯
```

### Stale Session (>7 days)

```text
╭─────────────────────────────────────────────────────────────╮
│ ⚠️  STALE SESSION DETECTED                                  │
├─────────────────────────────────────────────────────────────┤
│ Spec: specs/014-context-aware-permission-system/            │
│ Last Activity: 12 days ago                                  │
│ Context may be outdated. Codebase changes likely.           │
├─────────────────────────────────────────────────────────────┤
│ OPTIONS                                                     │
│   A) Resume anyway - Load context and continue              │
│   B) Fresh start - Keep artifacts, restart workflow          │
│   C) Review first - Show me what changed                     │
│   D) Cancel                                                 │
╰─────────────────────────────────────────────────────────────╯
```

---

## 5. 🎯 SUCCESS CRITERIA

- [ ] Detects active session from `.spec-active` marker
- [ ] Falls back to most recent memory file if no marker
- [ ] Displays clear progress summary
- [ ] Offers memory file loading options
- [ ] Handles missing/stale sessions gracefully
- [ ] Integrates with existing A/B/C/D question pattern

---

## 6. 🔗 RELATED COMMANDS

| Command               | Relationship                                        |
| --------------------- | --------------------------------------------------- |
| `/spec_kit:status`    | Read-only progress view (resume loads context)      |
| `/spec_kit:complete`  | Start new feature (resume continues existing)       |
| `/spec_kit:implement` | Execute implementation (can be called after resume) |

---

**Tip:** Run `/spec_kit:resume` at the start of each session to quickly pick up where you left off.