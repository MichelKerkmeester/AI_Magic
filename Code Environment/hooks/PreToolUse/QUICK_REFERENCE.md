# Quick Reference: Intelligent Duplicate Detection v2.0

## At-a-Glance

```
┌─────────────────────────────────────────────────────────────┐
│ HOOK: warn-duplicate-reads.sh v2.0                         │
├─────────────────────────────────────────────────────────────┤
│ Purpose:   Transform duplicates into actionable intelligence│
│ Triggers:  Before Read/Grep/Glob tool execution            │
│ Blocking:  No (advisory only, exit 0 always)               │
│ Performance: <50ms target (avg 35-45ms)                    │
│ Output:    Machine-readable JSON signals                   │
└─────────────────────────────────────────────────────────────┘
```

---

## Decision Tree

```
Read/Grep/Glob tool called
        ↓
Signature in history?
   ├─ NO  → Track signature, exit (20-30ms)
   └─ YES → DUPLICATE DETECTED
        ↓
File modified after last read?
   ├─ YES → LEGITIMATE (verification_after_modification)
   └─ NO  → Continue check
        ↓
Time elapsed > 2 minutes?
   ├─ YES → LEGITIMATE (stale_context_refresh)
   └─ NO  → TRUE DUPLICATE
        ↓
Emit actionable intelligence:
   • Token waste estimate
   • Session total waste
   • Actionable suggestion (REUSE_PREVIOUS_OUTPUT)
```

---

## JSON Output Quick Reference

### TRUE Duplicate (Wasteful)
```json
{
  "duplicate_detected": true,
  "tool_name": "Read|Grep|Glob",
  "file_path": "/path/to/file",
  "analysis": {
    "is_legitimate": false,
    "false_positive": false
  },
  "token_impact": {
    "estimated_waste_this_call": 1000|400|150,
    "session_total_waste": 1000+
  },
  "actionable_suggestion": "REUSE_PREVIOUS_OUTPUT"
}
```
**AI Action**: Reference previous output from message #X

### Legitimate Re-Read
```json
{
  "duplicate_detected": true,
  "analysis": {
    "is_legitimate": true,
    "reason_ignored": "verification_after_modification|stale_context_refresh"
  },
  "token_impact": {
    "estimated_waste_this_call": 0
  },
  "actionable_suggestion": "PROCEED_AS_PLANNED"
}
```
**AI Action**: Continue with read (intentional pattern)

---

## Token Estimates

| Tool | Estimated Tokens | Typical Range |
|------|------------------|---------------|
| Read | 1000 | 500-2000 |
| Grep | 400 | 200-800 |
| Glob | 150 | 100-300 |

**Note**: Conservative estimates based on typical output sizes

---

## Legitimate Re-Read Patterns

### 1. Verification After Modification
```
Timeline:
  T=0s:  Read file.md
  T=5s:  Edit file.md  ← Tracked by track-file-modifications.sh
  T=8s:  Read file.md  ← LEGITIMATE (verification)

Detection:
  modified_files.json shows Edit at T=5s
  Last read at T=0s → modification AFTER last read
  Result: is_legitimate=true
```

### 2. Stale Context Refresh
```
Timeline:
  T=0s:    Read file.md
  T=180s:  Read file.md  ← LEGITIMATE (>2min TTL)

Detection:
  time_elapsed = 180s > 120s threshold
  Result: is_legitimate=true
  Reason: AI context may have pruned previous output
```

### 3. Different Grep Patterns
```
Calls:
  Grep pattern="TODO" path="/src"
  Grep pattern="FIXME" path="/src"

Detection:
  Different signatures (pattern differs)
  No duplicate detected (unique queries)
```

---

## Performance Benchmarks

| Scenario | Expected Time |
|----------|---------------|
| No duplicate (best case) | 20-30ms |
| Duplicate (legitimate) | 35-45ms |
| Duplicate (true waste) | 45-55ms |
| **Target average** | **<50ms** |

---

## State Files

### tool_call_history.json
```json
{
  "signatures": {
    "Read:{\"file_path\":\"/tmp/file.txt\"}": {
      "message_number": 5,
      "timestamp": "2025-11-29T09:00:00Z"
    }
  },
  "message_count": 10,
  "session_token_waste": 2400
}
```
**Location**: `/tmp/claude_hooks_state/tool_call_history.json`
**TTL**: 5 minutes (300s)

### modified_files.json
```json
{
  "files": [
    {
      "path": "/tmp/file.txt",
      "tool": "Edit",
      "timestamp": "2025-11-29T09:00:05Z"
    }
  ]
}
```
**Location**: `/tmp/claude_hooks_state/modified_files.json`
**Source**: `PostToolUse/track-file-modifications.sh`
**TTL**: 5 minutes (300s)

---

## Common Scenarios

### Scenario 1: Repeated File Read (Wasteful)
```bash
# Message #5
Read /path/to/README.md

# Message #7 (15 seconds later, no edit)
Read /path/to/README.md
```
**Detection**: TRUE duplicate
**Output**: `estimated_waste_this_call: 1000`
**Suggestion**: `REUSE_PREVIOUS_OUTPUT`

### Scenario 2: Edit-Verify Pattern (Legitimate)
```bash
# Message #5
Read /path/to/config.json

# Message #6
Edit /path/to/config.json

# Message #7
Read /path/to/config.json  # Verification
```
**Detection**: LEGITIMATE (verification_after_modification)
**Output**: `estimated_waste_this_call: 0`
**Suggestion**: `PROCEED_AS_PLANNED`

### Scenario 3: Long-Running Task (Legitimate)
```bash
# Message #5
Read /path/to/spec.md

# [Work on implementation for 5 minutes]

# Message #25
Read /path/to/spec.md  # Context refresh
```
**Detection**: LEGITIMATE (stale_context_refresh)
**Output**: `estimated_waste_this_call: 0`
**Suggestion**: `PROCEED_AS_PLANNED`

---

## Testing Quick Commands

### Syntax Check
```bash
bash -n .claude/hooks/PreToolUse/warn-duplicate-reads.sh
```

### Performance Test
```bash
time echo '{"tool_name":"Read","tool_input":{"file_path":"/tmp/test.txt"}}' | \
  .claude/hooks/PreToolUse/warn-duplicate-reads.sh
```

### Clear State (Reset)
```bash
rm -f /tmp/claude_hooks_state/tool_call_history.json
```

### Check Session Waste
```bash
jq '.session_token_waste' /tmp/claude_hooks_state/tool_call_history.json
```

---

## Troubleshooting

### Issue: No output detected
**Cause**: Different tool (not Read/Grep/Glob)
**Solution**: Normal behavior, hook only tracks read-only tools

### Issue: Performance >50ms
**Check**: `tail .claude/hooks/logs/performance.log | grep warn-duplicate-reads`
**Diagnosis**: Look for >50ms entries
**Solution**: Profile with `bash -x` if persistent

### Issue: False positives high
**Check**: Analyze `is_legitimate` patterns in output
**Diagnosis**: Are verification reads marked as duplicates?
**Solution**: Verify `modified_files.json` is populated correctly

### Issue: Session waste not accumulating
**Check**: `cat /tmp/claude_hooks_state/tool_call_history.json`
**Diagnosis**: Look for `session_token_waste` field
**Solution**: Ensure v2.0 hook is active (check version in header)

---

## Key Metrics

### Success Criteria
- ✓ Performance: <50ms average
- ✓ False positives: <20%
- ✓ JSON validity: 100% parseable
- ✓ Backward compatibility: v1.0 state works

### Monitoring
```bash
# Performance (last 50 executions)
tail -n 50 .claude/hooks/logs/performance.log | grep warn-duplicate-reads | \
  awk '{print $4}' | sed 's/ms//' | \
  awk '{sum+=$1; count++} END {print "Avg:",sum/count,"ms"}'

# Session waste total
jq '.session_token_waste // 0' /tmp/claude_hooks_state/tool_call_history.json
```

---

## Version History

| Version | Date | Changes |
|---------|------|---------|
| 1.0.0 | 2025-11-27 | Initial advisory warnings |
| 2.0.0 | 2025-11-29 | Intelligent detection, JSON signals, token tracking |

---

## Quick Links

- **Full Implementation Guide**: `DUPLICATE_DETECTION_ENHANCEMENT.md`
- **Testing Guide**: `TESTING_GUIDE.md`
- **Analysis Summary**: `ANALYSIS_SUMMARY.md`
- **Source Code**: `warn-duplicate-reads.sh`
- **Related Hook**: `PostToolUse/track-file-modifications.sh`

---

## One-Liner Summary

```
v2.0 = Smart detection + JSON signals + Token tracking + <50ms
```

**Result**: Transform warnings from ignored overhead to actionable intelligence
