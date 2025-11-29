# Testing Guide: Intelligent Duplicate Read Detection v2.0

## Quick Validation Checklist

### 1. Syntax & Execution
```bash
# Verify syntax
bash -n .claude/hooks/PreToolUse/warn-duplicate-reads.sh
# Expected: No output (success)

# Check executable
ls -l .claude/hooks/PreToolUse/warn-duplicate-reads.sh | grep -q 'x'
# Expected: Exit 0 (executable)

# Test with empty input (should exit gracefully)
echo '{}' | .claude/hooks/PreToolUse/warn-duplicate-reads.sh
# Expected: Exit 0, no output
```

### 2. Dependencies
```bash
# Check jq availability
command -v jq >/dev/null && echo "OK" || echo "MISSING"
# Expected: OK

# Check shared-state.sh
test -f .claude/hooks/lib/shared-state.sh && echo "OK" || echo "MISSING"
# Expected: OK
```

### 3. Performance Baseline
```bash
# Measure execution time (non-duplicate)
time echo '{"tool_name":"Read","tool_input":{"file_path":"/tmp/test.txt"}}' | \
  .claude/hooks/PreToolUse/warn-duplicate-reads.sh
# Expected: <50ms (real time)
```

---

## Test Scenarios

### Scenario 1: TRUE Duplicate (No Modification)

**Setup**:
```bash
# First read
echo '{"tool_name":"Read","tool_input":{"file_path":"/tmp/test.txt"}}' | \
  .claude/hooks/PreToolUse/warn-duplicate-reads.sh

# Wait 2 seconds

# Second read (duplicate)
echo '{"tool_name":"Read","tool_input":{"file_path":"/tmp/test.txt"}}' | \
  .claude/hooks/PreToolUse/warn-duplicate-reads.sh
```

**Expected Output**:
```json
{
  "duplicate_detected": true,
  "tool_name": "Read",
  "file_path": "/tmp/test.txt",
  "pattern": "",
  "previous_call": {
    "message_number": 1,
    "time_ago_seconds": 2,
    "time_ago_human": "2s"
  },
  "analysis": {
    "is_legitimate": false,
    "false_positive": false,
    "reason_ignored": null
  },
  "token_impact": {
    "estimated_waste_this_call": 1000,
    "session_total_waste": 1000,
    "potential_savings": "Consider reusing previous output"
  },
  "actionable_suggestion": "REUSE_PREVIOUS_OUTPUT"
}
```

**Validation**:
- ✓ `duplicate_detected: true`
- ✓ `is_legitimate: false`
- ✓ `estimated_waste_this_call: 1000`
- ✓ `actionable_suggestion: "REUSE_PREVIOUS_OUTPUT"`
- ✓ Session waste tracked: 1000 tokens

---

### Scenario 2: Verification Read After Modification

**Setup**:
```bash
# Simulate file modification tracking
cat > /tmp/claude_hooks_state/modified_files.json <<'EOF'
{
  "files": [
    {
      "path": "/tmp/test.txt",
      "tool": "Edit",
      "timestamp": "2025-11-29T09:00:01Z"
    }
  ]
}
EOF

# First read (before modification)
echo '{"tool_name":"Read","tool_input":{"file_path":"/tmp/test.txt"}}' | \
  .claude/hooks/PreToolUse/warn-duplicate-reads.sh

# Simulate 1 second delay

# Second read (after modification timestamp)
echo '{"tool_name":"Read","tool_input":{"file_path":"/tmp/test.txt"}}' | \
  .claude/hooks/PreToolUse/warn-duplicate-reads.sh
```

**Expected Output**:
```json
{
  "duplicate_detected": true,
  "tool_name": "Read",
  "file_path": "/tmp/test.txt",
  "analysis": {
    "is_legitimate": true,
    "false_positive": false,
    "reason_ignored": "verification_after_modification"
  },
  "token_impact": {
    "estimated_waste_this_call": 0,
    "reason": "Legitimate re-read pattern detected"
  },
  "actionable_suggestion": "PROCEED_AS_PLANNED"
}
```

**Validation**:
- ✓ `duplicate_detected: true`
- ✓ `is_legitimate: true`
- ✓ `reason_ignored: "verification_after_modification"`
- ✓ `estimated_waste_this_call: 0`
- ✓ `actionable_suggestion: "PROCEED_AS_PLANNED"`

---

### Scenario 3: Stale Context Refresh (>2min)

**Setup**:
```bash
# First read
echo '{"tool_name":"Read","tool_input":{"file_path":"/tmp/test.txt"}}' | \
  .claude/hooks/PreToolUse/warn-duplicate-reads.sh

# Manually backdate the timestamp (simulate 3 minutes ago)
jq '.signatures["Read:{\"file_path\":\"/tmp/test.txt\"}"].timestamp = "2025-11-29T08:57:00Z"' \
  /tmp/claude_hooks_state/tool_call_history.json > /tmp/tmp.json && \
  mv /tmp/tmp.json /tmp/claude_hooks_state/tool_call_history.json

# Second read (>2min later)
echo '{"tool_name":"Read","tool_input":{"file_path":"/tmp/test.txt"}}' | \
  .claude/hooks/PreToolUse/warn-duplicate-reads.sh
```

**Expected Output**:
```json
{
  "duplicate_detected": true,
  "tool_name": "Read",
  "file_path": "/tmp/test.txt",
  "analysis": {
    "is_legitimate": true,
    "false_positive": false,
    "reason_ignored": "stale_context_refresh"
  },
  "token_impact": {
    "estimated_waste_this_call": 0,
    "reason": "Legitimate re-read pattern detected"
  },
  "actionable_suggestion": "PROCEED_AS_PLANNED"
}
```

**Validation**:
- ✓ `is_legitimate: true`
- ✓ `reason_ignored: "stale_context_refresh"`
- ✓ `estimated_waste_this_call: 0`

---

### Scenario 4: Different Grep Patterns (Not Duplicate)

**Setup**:
```bash
# First grep
echo '{"tool_name":"Grep","tool_input":{"pattern":"TODO","path":"/tmp/test.txt"}}' | \
  .claude/hooks/PreToolUse/warn-duplicate-reads.sh

# Second grep (different pattern)
echo '{"tool_name":"Grep","tool_input":{"pattern":"FIXME","path":"/tmp/test.txt"}}' | \
  .claude/hooks/PreToolUse/warn-duplicate-reads.sh
```

**Expected Output**:
No duplicate detected (different signatures due to different patterns)

**Validation**:
- ✓ No output (different signatures, not a duplicate)

---

### Scenario 5: Session Token Waste Accumulation

**Setup**:
```bash
# Clear state
rm -f /tmp/claude_hooks_state/tool_call_history.json

# Duplicate #1 (1000 tokens)
echo '{"tool_name":"Read","tool_input":{"file_path":"/tmp/file1.txt"}}' | \
  .claude/hooks/PreToolUse/warn-duplicate-reads.sh
echo '{"tool_name":"Read","tool_input":{"file_path":"/tmp/file1.txt"}}' | \
  .claude/hooks/PreToolUse/warn-duplicate-reads.sh

# Duplicate #2 (400 tokens)
echo '{"tool_name":"Grep","tool_input":{"pattern":"test","path":"/tmp"}}' | \
  .claude/hooks/PreToolUse/warn-duplicate-reads.sh
echo '{"tool_name":"Grep","tool_input":{"pattern":"test","path":"/tmp"}}' | \
  .claude/hooks/PreToolUse/warn-duplicate-reads.sh

# Duplicate #3 (150 tokens)
echo '{"tool_name":"Glob","tool_input":{"pattern":"*.md","path":"/tmp"}}' | \
  .claude/hooks/PreToolUse/warn-duplicate-reads.sh
echo '{"tool_name":"Glob","tool_input":{"pattern":"*.md","path":"/tmp"}}' | \
  .claude/hooks/PreToolUse/warn-duplicate-reads.sh
```

**Expected Output** (on 3rd duplicate):
```json
{
  "token_impact": {
    "estimated_waste_this_call": 150,
    "session_total_waste": 1550,
    "potential_savings": "Consider reusing previous output"
  }
}
```

**Validation**:
- ✓ Session waste accumulates: 1000 + 400 + 150 = 1550
- ✓ Check state file:
  ```bash
  jq '.session_token_waste' /tmp/claude_hooks_state/tool_call_history.json
  # Expected: 1550
  ```

---

## Performance Testing

### Test 1: Execution Time Distribution

```bash
# Create test script
cat > /tmp/perf_test.sh <<'EOF'
#!/bin/bash
for i in {1..50}; do
  START=$(date +%s%N)
  echo '{"tool_name":"Read","tool_input":{"file_path":"/tmp/test'$i'.txt"}}' | \
    .claude/hooks/PreToolUse/warn-duplicate-reads.sh >/dev/null 2>&1
  END=$(date +%s%N)
  DURATION=$(( (END - START) / 1000000 ))
  echo "$DURATION"
done
EOF

chmod +x /tmp/perf_test.sh
/tmp/perf_test.sh | awk '{sum+=$1; if($1>max) max=$1; if(min=="" || $1<min) min=$1} END {print "Avg:",sum/NR,"ms | Min:",min,"ms | Max:",max,"ms"}'
```

**Expected Results**:
- Average: 30-45ms
- Min: 25-35ms
- Max: 45-55ms
- All values: <50ms (target)

### Test 2: Performance Under Load

```bash
# Simulate rapid bursts (like production)
for batch in {1..5}; do
  for i in {1..10}; do
    echo '{"tool_name":"Read","tool_input":{"file_path":"/tmp/test.txt"}}' | \
      .claude/hooks/PreToolUse/warn-duplicate-reads.sh >/dev/null 2>&1 &
  done
  wait
  sleep 1
done

# Check performance log
tail -n 50 .claude/hooks/logs/performance.log | grep warn-duplicate-reads | \
  awk '{print $4}' | sed 's/ms//' | \
  awk '{sum+=$1; count++} END {print "Avg:",sum/count,"ms"}'
```

**Expected**: Avg <50ms under concurrent load

---

## Integration Testing

### Test with Live Claude Code Session

1. **Enable Verbose Logging**:
   ```bash
   tail -f .claude/hooks/logs/performance.log | grep warn-duplicate-reads
   ```

2. **Trigger Duplicate Scenarios**:
   - Read same file twice without modification
   - Edit file, then read (verification)
   - Read file, wait 3 minutes, read again (stale context)

3. **Verify JSON Output**:
   ```bash
   # Check that output is valid JSON
   # (Claude Code should parse it successfully)
   ```

4. **Monitor False Positive Rate**:
   ```bash
   # Track 20 duplicate detections
   # Manually classify as true/false positive
   # Calculate rate: false_positives / total_detections
   # Target: <20%
   ```

---

## Regression Testing

### Ensure No Breaking Changes

1. **Backward Compatibility**:
   ```bash
   # Old state format should still work
   cat > /tmp/claude_hooks_state/tool_call_history.json <<'EOF'
   {
     "signatures": {
       "Read:{\"file_path\":\"/tmp/test.txt\"}": {
         "message_number": 1,
         "timestamp": "2025-11-29T09:00:00Z"
       }
     },
     "message_count": 1
   }
   EOF

   # Should auto-add session_token_waste field
   echo '{"tool_name":"Read","tool_input":{"file_path":"/tmp/test.txt"}}' | \
     .claude/hooks/PreToolUse/warn-duplicate-reads.sh

   # Verify field added
   jq '.session_token_waste' /tmp/claude_hooks_state/tool_call_history.json
   # Expected: 0 (initialized)
   ```

2. **Cross-Hook Integration**:
   ```bash
   # Verify modified_files state from track-file-modifications.sh
   test -f /tmp/claude_hooks_state/modified_files.json && echo "OK" || echo "MISSING"
   ```

---

## Failure Modes & Recovery

### Test 1: Missing jq
```bash
# Temporarily hide jq
alias jq=/tmp/nonexistent
echo '{"tool_name":"Read","tool_input":{"file_path":"/tmp/test.txt"}}' | \
  .claude/hooks/PreToolUse/warn-duplicate-reads.sh
# Expected: Exit 0 (silent fail), no output
unalias jq
```

### Test 2: Corrupted State File
```bash
echo "INVALID JSON" > /tmp/claude_hooks_state/tool_call_history.json
echo '{"tool_name":"Read","tool_input":{"file_path":"/tmp/test.txt"}}' | \
  .claude/hooks/PreToolUse/warn-duplicate-reads.sh
# Expected: Exit 0, reinitialized state
```

### Test 3: Missing State Directory
```bash
rm -rf /tmp/claude_hooks_state
echo '{"tool_name":"Read","tool_input":{"file_path":"/tmp/test.txt"}}' | \
  .claude/hooks/PreToolUse/warn-duplicate-reads.sh
# Expected: Exit 0, directory auto-created
```

---

## Success Criteria

### Must Pass (Blocking)
- ✓ All syntax checks pass
- ✓ Performance <50ms (avg under normal load)
- ✓ Valid JSON output (parseable by jq)
- ✓ Backward compatibility with v1.0 state
- ✓ No crashes on invalid input

### Should Pass (Target)
- ✓ False positive rate <20%
- ✓ Session waste tracking accurate (±5%)
- ✓ Legitimate patterns detected correctly (>95%)
- ✓ Performance <45ms (avg, stretch goal)

### Nice to Have (Future)
- Token estimates within 20% of actual (requires API integration)
- ML-based pattern detection (learning from behavior)
- Cross-session analytics

---

## Troubleshooting

### Issue: Performance >50ms
**Diagnosis**:
```bash
# Profile with time breakdown
bash -x .claude/hooks/PreToolUse/warn-duplicate-reads.sh < input.json 2>&1 | \
  grep -E '^\+\+ date' | wc -l
# Count jq invocations
```

**Solution**: Reduce jq calls, optimize timestamp parsing

### Issue: False Positives High (>30%)
**Diagnosis**:
```bash
# Analyze detection patterns
grep "is_legitimate.*false" session_log.txt | wc -l
grep "verification_after_modification" session_log.txt | wc -l
```

**Solution**: Adjust TTL threshold, improve modification detection

### Issue: JSON Output Invalid
**Diagnosis**:
```bash
# Test JSON validity
.claude/hooks/PreToolUse/warn-duplicate-reads.sh < input.json | jq empty
# Expected: No output (valid JSON)
```

**Solution**: Check heredoc formatting, escape special characters

---

## Validation Report Template

```markdown
## Validation Report: warn-duplicate-reads.sh v2.0

**Date**: YYYY-MM-DD
**Tester**: [Name]
**Environment**: macOS/Linux, Bash version X.X

### Test Results

| Scenario                     | Expected | Actual | Status |
|------------------------------|----------|--------|--------|
| TRUE Duplicate Detection     | ✓        | ✓      | PASS   |
| Verification Read (Legitimate)| ✓        | ✓      | PASS   |
| Stale Context Refresh        | ✓        | ✓      | PASS   |
| Session Waste Accumulation   | ✓        | ✓      | PASS   |
| Performance <50ms            | ✓        | ✓      | PASS   |

### Performance Metrics
- Average: XXms
- Min: XXms
- Max: XXms
- Target: <50ms

### False Positive Rate
- Total Detections: XX
- False Positives: XX
- Rate: XX% (target: <20%)

### Issues Found
[List any issues or anomalies]

### Recommendation
☐ APPROVE for production
☐ REJECT (needs fixes)
☐ CONDITIONAL (minor improvements)
```

---

## Next Steps

1. Run full test suite
2. Validate performance under load
3. Monitor false positive rate in production
4. Collect AI behavioral data (did it optimize based on signals?)
5. Iterate on token estimates (compare with actual usage)
