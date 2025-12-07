---
description: Show progress across all or specific specs
argument-hint: "[spec-folder-path | all]"
allowed-tools: Read, Glob, Bash
---

# SpecKit Status

## 1. 📋 Purpose

Display progress at a glance - single spec or all active specs.

## 2. 🔍 Usage

| Command                        | Result                       |
| ------------------------------ | ---------------------------- |
| `/spec_kit:status`             | Current/active spec progress |
| `/spec_kit:status all`         | All specs summary dashboard  |
| `/spec_kit:status specs/014-*` | Specific spec folder         |

## 3. ⚡ Execution Steps

### Step 1: Detect Target

```bash
# Check for argument
if [ -n "$ARGUMENTS" ]; then
  if [ "$ARGUMENTS" = "all" ]; then
    TARGET="all"
  else
    TARGET="$ARGUMENTS"
  fi
else
  # Check for active spec marker
  if [ -f ".spec-active" ]; then
    TARGET=$(cat .spec-active)
  else
    TARGET="all"
  fi
fi
```

### Step 2: Gather Metrics

For each spec folder, calculate:
1. **Tasks Progress**: Count `[x]` vs `[ ]` in tasks.md
2. **Checklist Progress**: Count by priority (P0/P1/P2)
3. **Files Present**: Check which required files exist
4. **Documentation Level**: Infer from files present

### Step 3: Generate Output

#### Single Spec Output Format

```text
╔═══════════════════════════════════════════════════════════════╗
║  014-context-aware-permission-system                          ║
║  Level: 3 | Status: COMPLETE                                  ║
╠═══════════════════════════════════════════════════════════════╣
║  TASKS      ████████████████████████████████████▓▓ 96%        ║
║             49/51 done | 2 deferred                           ║
╠───────────────────────────────────────────────────────────────╣
║  CHECKLIST  ████████████████████████████████████░░ 92%        ║
║             P0: 12/12 ✓ | P1: 15/15 ✓ | P2: 3/8               ║
╠───────────────────────────────────────────────────────────────╣
║  FILES      spec.md ✓ | plan.md ✓ | tasks.md ✓ | checklist ✓  ║
║             decision-record.md ✓ | migration-guide.md ✓       ║
╚═══════════════════════════════════════════════════════════════╝
```

#### Multi-Spec Dashboard (`/spec_kit:status all`)

```text
╔═══════════════════════════════════════════════════════════════╗
║  SPECKIT PROJECT DASHBOARD                    17 specs total  ║
╠═══════════════════════════════════════════════════════════════╣
║  Spec                                   Tasks    Chk    Status║
╠═══════════════════════════════════════════════════════════════╣
║  014-context-aware-permission      ████████ 96%  92%  COMPLETE║
║  013-speckit-enhancements          ████████ 100% 88%  COMPLETE║
║  012-hook-enhancements             ██████░░ 75%  --   ACTIVE  ║
║  011-semantic-memory-upgrade       ████████ 100% 100% COMPLETE║
║  ...                                                          ║
╠───────────────────────────────────────────────────────────────╣
║  TOTALS: 14 complete | 3 active | 0 blocked                   ║
║  Overall: ██████████████████████████████░░░░ 82%              ║
╚═══════════════════════════════════════════════════════════════╝
```

## 4. 📊 Calculation Logic

### Task Progress

```bash
# Count completed vs total tasks (fixed regex + division safety)
DONE=$(grep -cE '\[x\]' "$SPEC_FOLDER/tasks.md" 2>/dev/null || echo 0)
TOTAL=$(grep -cE '\[[x ]\]' "$SPEC_FOLDER/tasks.md" 2>/dev/null || echo 0)
PERCENT=$((TOTAL > 0 ? DONE * 100 / TOTAL : 0))
```

### Checklist Progress (by Priority)

```bash
# P0 Critical (must be 100%) - word boundaries + checkbox-only
P0_DONE=$(grep -cE '\[x\].*\bP0\b' "$SPEC_FOLDER/checklist.md" 2>/dev/null || echo 0)
P0_TOTAL=$(grep -cE '\[[x ]\].*\bP0\b' "$SPEC_FOLDER/checklist.md" 2>/dev/null || echo 0)

# P1 High (should be 100%)
P1_DONE=$(grep -cE '\[x\].*\bP1\b' "$SPEC_FOLDER/checklist.md" 2>/dev/null || echo 0)
P1_TOTAL=$(grep -cE '\[[x ]\].*\bP1\b' "$SPEC_FOLDER/checklist.md" 2>/dev/null || echo 0)

# P2 Medium (best effort)
P2_DONE=$(grep -cE '\[x\].*\bP2\b' "$SPEC_FOLDER/checklist.md" 2>/dev/null || echo 0)
P2_TOTAL=$(grep -cE '\[[x ]\].*\bP2\b' "$SPEC_FOLDER/checklist.md" 2>/dev/null || echo 0)

# Handle missing checklist.md (Level 1 specs)
if [ ! -f "$SPEC_FOLDER/checklist.md" ]; then
  CHK_DISPLAY="--"
fi
```

### Status Determination

| Condition                                       | Status   |
| ----------------------------------------------- | -------- |
| All tasks done, P0/P1 100%                      | COMPLETE |
| Tasks >50%, actively working                    | ACTIVE   |
| P0 items incomplete OR explicit BLOCKED markers | BLOCKED  |
| No progress AND last modified >14 days          | STALE    |

```bash
# Status determination with explicit criteria
BLOCKED_COUNT=$(grep -ciE 'blocked:' "$SPEC_FOLDER/tasks.md" 2>/dev/null || echo 0)
if [ "$PERCENT" -eq 100 ] && [ "$P0_DONE" -eq "$P0_TOTAL" ]; then
  STATUS="COMPLETE"
elif [ "$P0_DONE" -lt "$P0_TOTAL" ] || [ "$BLOCKED_COUNT" -gt 0 ]; then
  STATUS="BLOCKED"
elif [ "$PERCENT" -gt 0 ]; then
  STATUS="ACTIVE"
else
  STATUS="STALE"
fi
```

## 5. 🎯 Success Criteria

- [ ] Single command shows progress without navigation
- [ ] Visual progress bars for quick scanning
- [ ] Priority-based checklist breakdown
- [ ] Multi-spec dashboard for project overview
- [ ] Status clearly indicates next action

---

**Tip:** Run `/spec_kit:status` at session start to quickly resume where you left off.
