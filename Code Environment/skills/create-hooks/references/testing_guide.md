# Hook Testing Guide - Claude Code Hooks

Comprehensive three-phase testing strategy for Claude Code hooks: Validation → Integration → Production. This guide covers static validation, runtime testing with realistic payloads, and production monitoring to ensure hooks are reliable, performant, and secure before and after deployment.

---

## 1. 📋 OVERVIEW

Testing hooks ensures reliability, performance, and security before production deployment. This guide covers static validation, runtime testing with payloads, and production monitoring.

## Testing Philosophy

**Test Early, Test Often**: Validate syntax before running, test with payloads before deploying, monitor after deployment.

**Test Realistically**: Use realistic payloads that match production conditions.

**Test Edge Cases**: Valid input, missing fields, malicious input, performance limits.

---

## 2. ✅ PHASE 1: VALIDATION TESTING

### Purpose

Verify syntax, structure, and basic requirements without executing the hook.

### Tool: validate_hook.sh

Located at: `.claude/skills/create-hooks/scripts/validate_hook.sh`

```bash
.claude/skills/create-hooks/scripts/validate_hook.sh \
  /path/to/your-hook.sh
```

### Checks Performed

#### File Permissions
- Executable bit set (`chmod +x`)
- Readable by current user
- Not world-writable (security)

#### Shebang
- Starts with `#!/bin/bash`
- No Windows line endings (CRLF)
- No spaces after shebang

#### Bash Syntax
- `bash -n` syntax check passes
- No obvious syntax errors
- Proper quote matching

#### Bash 3.2+ Compatibility
- No `declare -A` (associative arrays)
- No `mapfile` or `readarray`
- No negative array indices (`${array[-1]}`)
- No `{start..end..step}` brace expansion

#### Exit Code Usage
- Uses 0, 1, or 2 only
- No variable exit codes
- Uses EXIT_ALLOW/EXIT_BLOCK/EXIT_ERROR constants

#### Required Components
- Sources `lib/output-helpers.sh`
- Sources `lib/exit-codes.sh`
- Has performance timing (START_TIME and END_TIME)
- Has error handling (if statements, checks)

#### Security Patterns
- Input sanitization present
- No `eval` with user input
- No unquoted variables in dangerous commands
- Path validation with `realpath`

### Example Output

```
──────────────────────────────────────────────────────
Validating Hook: my-hook.sh
──────────────────────────────────────────────────────

✅ Executable permission set
✅ Shebang present and correct
🔍 Checking bash syntax...
✅ Bash syntax valid
🔍 Checking bash 3.2+ compatibility...
✅ Bash 3.2+ compatible
⚠️  Warning: No input sanitization detected (security risk)

──────────────────────────────────────────────────────
✅ Validation passed: my-hook.sh
──────────────────────────────────────────────────────
```

### Fix Common Issues

**Issue: Hook not executable**
```bash
chmod +x .claude/hooks/{HookType}/my-hook.sh
```

**Issue: Bash 4+ features detected**
```bash
# Replace associative arrays with indexed arrays
# Replace mapfile with while read loops
# See best_practices.md for alternatives
```

**Issue: Missing input sanitization**
```bash
# Add sanitization for session_id
SESSION_ID=$(echo "$SESSION_ID" | tr -cd 'a-zA-Z0-9_-')

# Add path validation
SAFE_PATH=$(realpath "$USER_PATH" 2>/dev/null)
```

---

## 3. 🧪 PHASE 2: INTEGRATION TESTING

### Purpose

Execute hook with test payloads and verify behavior, performance, and error handling.

### Tool: test_hook.sh

Located at: `.claude/skills/create-hooks/scripts/test_hook.sh`

```bash
.claude/skills/create-hooks/scripts/test_hook.sh \
  /path/to/your-hook.sh \
  test-payload.json
```

### Test Scenarios

#### Valid Input (Happy Path)

**Purpose**: Verify hook works correctly with valid data.

**Example Payload (PreCompact)**:
```bash
cat > test-valid.json << 'EOF'
{
  "trigger": "manual",
  "session_id": "test123",
  "cwd": "/tmp/test-project"
}
EOF
```

**Expected Result**:
- Exit code: 0
- Expected output generated
- Performance within target
- No errors in stderr

#### Missing Required Field

**Purpose**: Verify graceful degradation when fields are missing.

**Example Payload**:
```bash
cat > test-missing-field.json << 'EOF'
{
  "cwd": "/tmp/test-project"
}
EOF
```

**Expected Result**:
- Exit code: 0 (graceful) or 1 (block with message)
- Clear error message explaining missing field
- No crash or undefined behavior

#### Malicious Input (Security Test)

**Purpose**: Verify input sanitization and security measures.

**Example Payload**:
```bash
cat > test-malicious.json << 'EOF'
{
  "session_id": "../../../etc/passwd",
  "cwd": "/tmp; rm -rf /",
  "field": "$(malicious_command)"
}
EOF
```

**Expected Result**:
- Path traversal prevented
- Command injection blocked
- Safe exit (0 or 1)
- Input sanitized before use

#### Performance Test

**Purpose**: Verify execution time within target for hook type.

**Example Payload**:
```bash
cat > test-performance.json << 'EOF'
{
  "session_id": "perf_test_abc123",
  "cwd": "/tmp/test-project",
  "large_field": "[... realistic large data ...]"
}
EOF
```

**Expected Result**:
- Execution time within target:
  - PreToolUse: <50ms
  - UserPromptSubmit: <200ms
  - PreCompact: <5s
- No hanging or infinite loops

### Running Test Suite

```bash
# Run all test scenarios
for payload in test-*.json; do
  echo "──────────────────────────────────────────"
  echo "Testing with: $payload"
  echo "──────────────────────────────────────────"

  .claude/skills/create-hooks/scripts/test_hook.sh \
    .claude/hooks/{HookType}/my-hook.sh \
    "$payload"

  echo ""
done
```

### Example Output

```
──────────────────────────────────────────────────────
Testing Hook: my-hook.sh
Payload: test-valid.json
──────────────────────────────────────────────────────

Payload Contents:
{
  "session_id": "test123",
  "cwd": "/tmp/test-project"
}

──────────────────────────────────────────────────────
Hook Output:
──────────────────────────────────────────────────────

💾 Processing session: test123
✅ Operation completed successfully

──────────────────────────────────────────────────────
Test Results:
──────────────────────────────────────────────────────
Exit Code: 0
Duration: 142ms
Status: ✅ Success (EXIT_ALLOW)
──────────────────────────────────────────────────────
```

### Creating Test Payloads

#### Template: PreCompact
```json
{
  "trigger": "manual",
  "custom_instructions": "Test context save",
  "session_id": "test_abc123",
  "cwd": "/tmp/test-project"
}
```

#### Template: UserPromptSubmit
```json
{
  "prompt": "save context",
  "session_id": "test_def456",
  "cwd": "/tmp/test-project",
  "message_count": 20
}
```

#### Template: PreToolUse
```json
{
  "tool_name": "Bash",
  "tool_input": {
    "command": "echo 'test'"
  },
  "session_id": "test_ghi789",
  "cwd": "/tmp/test-project"
}
```

#### Template: PostToolUse
```json
{
  "tool_name": "Write",
  "tool_input": {
    "file_path": "/tmp/test.md",
    "content": "# Test"
  },
  "tool_output": "File written successfully",
  "exit_code": 0,
  "session_id": "test_jkl012",
  "cwd": "/tmp/test-project"
}
```

---

## 4. 🚀 PHASE 3: PRODUCTION TESTING

### Purpose

Verify hook works correctly in real Claude Code environment before full rollout.

### Pre-Deployment Checklist

Before deploying to production:

- [ ] Validation tests pass (`validate_hook.sh`)
- [ ] All integration tests pass (valid, missing, malicious, performance)
- [ ] Security tests pass (sanitization, path validation)
- [ ] Performance acceptable for hook type
- [ ] Error handling verified (graceful degradation)
- [ ] Logging implemented (operations and performance)
- [ ] Documentation complete (file header, comments)
- [ ] Peer review completed (if applicable)
- [ ] Rollback plan prepared

### Deployment Process

#### Create Test Installation

```bash
# Install hook (already in correct location from development)
chmod +x .claude/hooks/{HookType}/my-hook.sh

# Verify location
ls -la .claude/hooks/{HookType}/my-hook.sh
# Should show: -rwxr-xr-x ... my-hook.sh
```

#### Monitor Logs

```bash
# Watch hook-specific logs
tail -f .claude/hooks/logs/my-hook.log

# Watch performance logs
tail -f .claude/hooks/logs/performance.log | grep my-hook

# Watch general hook execution
tail -f .claude/hooks/logs/orchestrator.log
```

#### Trigger Hook in Real Environment

Perform the action that triggers your hook:

- **PreCompact**: Run `/compact` command
- **UserPromptSubmit**: Submit message with trigger condition
- **PreToolUse**: Use tool that hook should validate
- **PostToolUse**: Perform action that triggers post-processing

#### Verify Success Criteria

- [ ] Hook triggers at correct time
- [ ] Output as expected
- [ ] Performance within target
- [ ] No errors in logs
- [ ] User experience acceptable

### Production Monitoring

#### Daily Checks

```bash
# Check for errors
grep -i "error\|failed" .claude/hooks/logs/my-hook.log | tail -20

# Check performance outliers
awk '$3 > 200 {print}' .claude/hooks/logs/performance.log | grep my-hook | tail -10

# Count executions
grep "my-hook" .claude/hooks/logs/performance.log | wc -l
```

#### Weekly Review

```bash
# Average execution time
grep "my-hook" .claude/hooks/logs/performance.log | \
  awk '{sum+=$NF; count++} END {print "Average: " sum/count "ms"}'

# Error rate
TOTAL=$(grep -c "my-hook" .claude/hooks/logs/my-hook.log)
ERRORS=$(grep -c "ERROR\|FAILED" .claude/hooks/logs/my-hook.log)
echo "Error rate: $(( ERRORS * 100 / TOTAL ))%"

# Performance distribution (p50, p95, p99)
grep "my-hook" .claude/hooks/logs/performance.log | \
  awk '{print $NF}' | sort -n | \
  awk 'BEGIN {count=0} {values[count++]=$1} END {
    print "p50: " values[int(count*0.5)] "ms"
    print "p95: " values[int(count*0.95)] "ms"
    print "p99: " values[int(count*0.99)] "ms"
  }'
```

### Rollback Procedure

If hook causes problems:

```bash
# Option 1: Disable temporarily (remove executable bit)
chmod -x .claude/hooks/{HookType}/my-hook.sh

# Option 2: Move out of hooks directory
mv .claude/hooks/{HookType}/my-hook.sh \
   .claude/hooks/{HookType}/my-hook.sh.disabled

# Option 3: Delete (if broken beyond repair)
rm .claude/hooks/{HookType}/my-hook.sh

# Verify hook no longer triggers
# Test the action that previously triggered the hook
```

---

## 5. 📝 TEST CASES BY HOOK TYPE

### PreCompact Hook Tests

**Test 1: Manual Trigger**
```json
{"trigger":"manual","session_id":"abc123","cwd":"/path"}
```
Expected: Context saved, exit 0

**Test 2: Auto Trigger**
```json
{"trigger":"auto","session_id":"abc123","cwd":"/path"}
```
Expected: Context saved, exit 0

**Test 3: Missing Session ID**
```json
{"trigger":"manual","cwd":"/path"}
```
Expected: Warning logged, exit 0 (graceful degradation)

**Test 4: Invalid Directory**
```json
{"trigger":"manual","session_id":"abc123","cwd":"/nonexistent"}
```
Expected: Warning logged, exit 0

---

### UserPromptSubmit Hook Tests

**Test 1: Keyword Match**
```json
{"prompt":"save context now","session_id":"abc","cwd":"/path","message_count":10}
```
Expected: Hook activates, exit 0

**Test 2: No Keyword**
```json
{"prompt":"hello world","session_id":"abc","cwd":"/path","message_count":10}
```
Expected: Hook skips (exit 0 silently)

**Test 3: Message Threshold**
```json
{"prompt":"test","session_id":"abc","cwd":"/path","message_count":200}
```
Expected: Auto-save triggers, exit 0

**Test 4: Case Sensitivity**
```json
{"prompt":"SAVE CONTEXT","session_id":"abc","cwd":"/path","message_count":10}
```
Expected: Keyword detected (case-insensitive), exit 0

---

### PreToolUse Hook Tests

**Test 1: Safe Command**
```json
{"tool_name":"Bash","tool_input":{"command":"echo test"},"session_id":"abc","cwd":"/path"}
```
Expected: Command allowed, exit 0

**Test 2: Dangerous Command**
```json
{"tool_name":"Bash","tool_input":{"command":"rm -rf /"},"session_id":"abc","cwd":"/path"}
```
Expected: Command blocked, exit 1, clear error message

**Test 3: Non-Bash Tool**
```json
{"tool_name":"Read","tool_input":{"file_path":"/path/file.txt"},"session_id":"abc","cwd":"/path"}
```
Expected: Tool allowed (not validated), exit 0

**Test 4: Syntax Error**
```json
{"tool_name":"Bash","tool_input":{"command":"if [ test; then"},"session_id":"abc","cwd":"/path"}
```
Expected: Warning shown, exit 0 (allow but warn)

---

### PostToolUse Hook Tests

**Test 1: Successful Write**
```json
{
  "tool_name":"Write",
  "tool_input":{"file_path":"/tmp/test.md","content":"# Test"},
  "tool_output":"Success",
  "exit_code":0,
  "session_id":"abc",
  "cwd":"/path"
}
```
Expected: File formatted, exit 0

**Test 2: Failed Tool**
```json
{
  "tool_name":"Write",
  "tool_input":{"file_path":"/tmp/test.md","content":"# Test"},
  "tool_output":"Error",
  "exit_code":1,
  "session_id":"abc",
  "cwd":"/path"
}
```
Expected: Post-processing skipped, exit 0

**Test 3: Non-Markdown File**
```json
{
  "tool_name":"Write",
  "tool_input":{"file_path":"/tmp/test.txt","content":"Test"},
  "tool_output":"Success",
  "exit_code":0,
  "session_id":"abc",
  "cwd":"/path"
}
```
Expected: Formatting skipped, exit 0

---

## 6. 🔍 DEBUGGING FAILED TESTS

### Common Issues

#### Issue: Hook Not Triggering

**Symptoms**: Hook never executes, no output in logs

**Debug Steps**:
1. Check hook location: `.claude/hooks/{HookType}/my-hook.sh`
2. Verify executable: `ls -l` (should show -rwx)
3. Check bash syntax: `bash -n my-hook.sh`
4. Review Claude Code logs for errors
5. Verify hook type matches trigger point

**Fix**:
```bash
# Make executable
chmod +x .claude/hooks/{HookType}/my-hook.sh

# Test manually
echo '{"test":"payload"}' | .claude/hooks/{HookType}/my-hook.sh
```

#### Issue: Exit Code Mismatch

**Symptoms**: test_hook.sh shows unexpected exit code

**Debug Steps**:
1. Add debug output: `set -x` at top of script
2. Check exit code logic
3. Review error handling
4. Test with minimal payload

**Fix**:
```bash
# Add debugging
set -x  # Enable debug mode
echo "DEBUG: Checkpoint 1" >&2
# ... your logic ...
echo "DEBUG: Exiting with code: $EXIT_CODE" >&2
exit $EXIT_CODE
```

#### Issue: Performance Too Slow

**Symptoms**: Execution exceeds target time

**Debug Steps**:
1. Profile with `time`: `time echo '{}' | ./hook.sh`
2. Add timing checkpoints
3. Identify bottleneck operations
4. Check for unnecessary external calls

**Fix**:
```bash
# Add timing checkpoints
echo "Checkpoint 1: $(date +%s%N)" >&2
expensive_operation
echo "Checkpoint 2: $(date +%s%N)" >&2

# Optimize bottleneck
# - Add caching
# - Use early exits
# - Parallelize independent operations
```

#### Issue: Security Vulnerability

**Symptoms**: Validation script shows security warnings

**Debug Steps**:
1. Review input sanitization
2. Check for eval usage
3. Verify path validation
4. Test with malicious payloads

**Fix**:
```bash
# Add sanitization
SESSION_ID=$(echo "$SESSION_ID" | tr -cd 'a-zA-Z0-9_-')

# Add path validation
SAFE_PATH=$(realpath "$USER_PATH" 2>/dev/null)
[ ! -d "$SAFE_PATH" ] && exit 1

# Remove eval
# eval "$USER_COMMAND"  # ❌
"$USER_COMMAND"  # ✅
```

---

## 7. 🔄 CONTINUOUS TESTING

### Automated Test Suite

Create script to run all tests:

```bash
#!/bin/bash
# test-all-hooks.sh

HOOKS_DIR=".claude/hooks"
TESTS_DIR=".claude/skills/create-hooks/tests"
VALIDATE_SCRIPT=".claude/skills/create-hooks/scripts/validate_hook.sh"
TEST_SCRIPT=".claude/skills/create-hooks/scripts/test_hook.sh"

echo "──────────────────────────────────────────"
echo "HOOK TEST SUITE"
echo "──────────────────────────────────────────"

TOTAL_TESTS=0
PASSED_TESTS=0
FAILED_TESTS=0

for hook in "$HOOKS_DIR"/*/*.sh; do
  HOOK_NAME=$(basename "$hook")
  HOOK_TYPE=$(basename "$(dirname "$hook")")

  echo ""
  echo "Testing: $HOOK_TYPE/$HOOK_NAME"

  # Validation
  if "$VALIDATE_SCRIPT" "$hook" >/dev/null 2>&1; then
    echo "  ✅ Validation passed"
    PASSED_TESTS=$((PASSED_TESTS + 1))
  else
    echo "  ❌ Validation failed"
    FAILED_TESTS=$((FAILED_TESTS + 1))
  fi
  TOTAL_TESTS=$((TOTAL_TESTS + 1))

  # Integration tests (if payload exists)
  PAYLOAD="$TESTS_DIR/$HOOK_TYPE.json"
  if [ -f "$PAYLOAD" ]; then
    if "$TEST_SCRIPT" "$hook" "$PAYLOAD" >/dev/null 2>&1; then
      echo "  ✅ Integration test passed"
      PASSED_TESTS=$((PASSED_TESTS + 1))
    else
      echo "  ❌ Integration test failed"
      FAILED_TESTS=$((FAILED_TESTS + 1))
    fi
    TOTAL_TESTS=$((TOTAL_TESTS + 1))
  fi
done

echo ""
echo "──────────────────────────────────────────"
echo "RESULTS: $PASSED_TESTS/$TOTAL_TESTS passed"
[ $FAILED_TESTS -gt 0 ] && echo "FAILURES: $FAILED_TESTS" || echo "ALL TESTS PASSED ✅"
echo "──────────────────────────────────────────"

exit $FAILED_TESTS
```

### Regression Testing

Before deploying hook updates:

```bash
# 1. Run full test suite on old version
./test-all-hooks.sh > results-old.txt

# 2. Update hook

# 3. Run full test suite on new version
./test-all-hooks.sh > results-new.txt

# 4. Compare results
diff results-old.txt results-new.txt

# 5. Verify no regressions
```

### Performance Regression

Track performance over time:

```bash
# Extract performance data
grep "my-hook" .claude/hooks/logs/performance.log | \
  awk '{print $1, $NF}' | \
  tail -1000 > performance-history.txt

# Plot trend (requires gnuplot or similar)
# Alert if average increases significantly
```

---

## 8. 📚 SUMMARY

Three-phase testing ensures hook quality:

1. **Validation**: Static analysis (syntax, compatibility, security)
2. **Integration**: Runtime testing (valid, missing, malicious, performance)
3. **Production**: Real environment testing (monitoring, rollback ready)

**Test Early**: Validate before running
**Test Thoroughly**: All scenarios (happy path + edge cases)
**Test Realistically**: Use production-like payloads
**Test Continuously**: Regression testing after changes
**Monitor Production**: Daily checks, weekly reviews

For more information:
- `hook_types.md`: Hook capabilities and payloads
- `hook_creation_guide.md`: Step-by-step implementation
- `payload_structures.md`: Test payload examples
- `best_practices.md`: Performance and security patterns
