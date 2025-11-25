# Hook Best Practices - Claude Code Hooks

Performance optimization, security patterns, error handling, and proven implementation strategies for Claude Code hooks. This guide provides battle-tested patterns and anti-patterns to ensure your hooks are fast, secure, and reliable in production environments.

---

## 1. ⚡ PERFORMANCE OPTIMIZATION

### Target Times by Hook Type

| Hook Type | Target | Priority | Rationale |
|-----------|--------|----------|-----------|
| PreToolUse | <50ms | CRITICAL | Blocks tool execution - any delay impacts UX |
| UserPromptSubmit | <200ms | HIGH | Blocks prompt processing - noticeable delay |
| PostToolUse | <200ms | MEDIUM | Non-blocking but visible to user |
| PreCompact | <5s | LOW | Users waiting but context preservation critical |
| PreSessionStart | <1s | MEDIUM | One-time initialization acceptable |
| PostSessionEnd | <1s | LOW | Background cleanup acceptable |
| PreMessageCreate | <100ms | CRITICAL | Blocks AI response generation |
| PostMessageCreate | <200ms | MEDIUM | Non-blocking logging/analytics |

### Early Exit Pattern

Exit immediately when hook doesn't apply:

```bash
# Pattern: Skip if not applicable
if [ -z "$REQUIRED_FIELD" ]; then
  exit 0  # No output, instant return
fi

# Pattern: Tool-specific filtering
if [ "$TOOL_NAME" != "Bash" ]; then
  exit 0  # Only process Bash tools
fi

# Pattern: File type filtering
if [[ "$FILE_PATH" != *.md ]]; then
  exit 0  # Only process markdown files
fi
```

**Impact**: Reduces average execution time from 100ms to <5ms for skipped hooks.

### Lazy Dependency Checks Pattern

Only check dependencies when actually needed:

```bash
# BAD: Check upfront even if not needed
check_dependency "jq" || exit 0
check_dependency "node" || exit 0
check_dependency "prettier" || exit 0

# GOOD: Check only when needed
if [ "$SHOULD_FORMAT" = true ]; then
  check_dependency "prettier" || exit 0
  # Use prettier
fi
```

**Impact**: Avoids 20-30ms overhead for unused dependencies.

### Caching Pattern

Cache expensive operations:

```bash
# Cache file for session
CACHE_FILE="/tmp/hook_cache_${SESSION_ID}.json"

if [ -f "$CACHE_FILE" ]; then
  # Use cached result
  RESULT=$(cat "$CACHE_FILE")
else
  # Perform expensive operation
  RESULT=$(expensive_operation)
  echo "$RESULT" > "$CACHE_FILE"
fi
```

**Impact**: 10-100x speedup for repeated operations.

### Efficient jq Usage Pattern

Minimize jq calls:

```bash
# BAD: Multiple jq calls (3x overhead)
FIELD1=$(echo "$INPUT" | jq -r '.field1')
FIELD2=$(echo "$INPUT" | jq -r '.field2')
FIELD3=$(echo "$INPUT" | jq -r '.field3')

# GOOD: Single jq call
read -r FIELD1 FIELD2 FIELD3 < <(echo "$INPUT" | jq -r '.field1, .field2, .field3')
```

**Impact**: Reduces 30-45ms to 10-15ms for multi-field extraction.

### Parallel Execution Pattern

Run independent tasks in parallel:

```bash
# Run tasks in background
task1 &
PID1=$!
task2 &
PID2=$!

# Wait for both to complete
wait $PID1
wait $PID2
```

**Impact**: 2x speedup for independent operations.

---

## 2. 🔒 SECURITY CONSIDERATIONS

### Input Sanitization Patterns

#### Session ID Sanitization

```bash
# Allow only alphanumeric, dash, underscore
SESSION_ID=$(echo "$SESSION_ID" | tr -cd 'a-zA-Z0-9_-')

# Validate length (typical: 10-20 chars)
if [ ${#SESSION_ID} -lt 5 ] || [ ${#SESSION_ID} -gt 50 ]; then
  echo "Invalid session ID length" >&2
  exit 1
fi
```

#### Path Validation

```bash
# Step 1: Resolve to absolute path
SAFE_PATH=$(realpath "$USER_PATH" 2>/dev/null)

# Step 2: Verify exists
if [ ! -d "$SAFE_PATH" ]; then
  echo "Path does not exist: $USER_PATH" >&2
  exit 1
fi

# Step 3: Verify within allowed directory
ALLOWED_DIR="/Users/username/projects"
if [[ "$SAFE_PATH" != "$ALLOWED_DIR"/* ]]; then
  echo "Path outside allowed directory" >&2
  exit 1
fi

# Step 4: Check for symlink attacks
if [ -L "$USER_PATH" ]; then
  echo "Symlinks not allowed" >&2
  exit 1
fi
```

#### Command Injection Prevention

```bash
# DANGEROUS: eval with user input
eval "$USER_COMMAND"  # ❌ NEVER DO THIS

# DANGEROUS: Unquoted variables
cd $USER_DIR  # ❌ Shell expansion vulnerability
rm -rf $USER_PATH/*  # ❌ Catastrophic if $USER_PATH is empty

# SAFE: Quoted variables
cd "$USER_DIR"  # ✅ Prevents word splitting
rm -rf "$USER_PATH"/*  # ✅ Safe even if empty

# SAFER: Validation first
if [ -z "$USER_DIR" ] || [ ! -d "$USER_DIR" ]; then
  exit 1
fi
cd "$USER_DIR"
```

#### String Sanitization

```bash
# Remove shell metacharacters
SAFE_STRING=$(echo "$USER_INPUT" | tr -cd '[:alnum:][:space:]._-')

# More restrictive (alphanumeric only)
ALPHA_ONLY=$(echo "$USER_INPUT" | tr -cd '[:alnum:]')

# Escape special characters
ESCAPED=$(printf '%q' "$USER_INPUT")
```

### Exit Code Security

```bash
# DANGEROUS: User-controlled exit code
exit $USER_EXIT_CODE  # ❌ Could be malicious value

# SAFE: Validate against allowed values
case "$RESULT" in
  success) exit 0 ;;
  warning) exit 1 ;;
  error) exit 2 ;;
  *) exit 2 ;;  # Default to error
esac
```

---

## 3. 🛠️ ERROR HANDLING STRATEGIES

### Graceful Degradation

Always handle missing dependencies gracefully:

```bash
# Pattern: Optional dependency
if ! command -v prettier &>/dev/null; then
  echo "💡 prettier not found (formatting disabled)" >&2
  # Continue without formatting
  exit 0
fi

# Pattern: Required dependency
if ! check_dependency "jq" "brew install jq"; then
  echo "⚠️  jq required but not found, skipping hook" >&2
  exit 0  # Skip gracefully
fi
```

### Comprehensive Error Messages

Provide actionable error messages:

```bash
# BAD: Silent failure
if ! process_file; then
  exit 1
fi

# GOOD: Descriptive error
if ! process_file "$FILE_PATH"; then
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" >&2
  echo "❌ Error: Failed to process file" >&2
  echo "" >&2
  echo "File: $FILE_PATH" >&2
  echo "Reason: $(cat error.log 2>/dev/null || echo 'Unknown')" >&2
  echo "" >&2
  echo "Possible fixes:" >&2
  echo "  • Check file permissions" >&2
  echo "  • Verify file format" >&2
  echo "  • Check available disk space" >&2
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" >&2
  exit 1
fi
```

### Error Recovery with Retry

```bash
# Retry pattern with exponential backoff
MAX_RETRIES=3
RETRY=0

while [ $RETRY -lt $MAX_RETRIES ]; do
  if operation; then
    break  # Success
  fi

  RETRY=$((RETRY + 1))

  if [ $RETRY -lt $MAX_RETRIES ]; then
    WAIT_TIME=$((RETRY * 2))
    echo "⚠️  Attempt $RETRY failed, retrying in ${WAIT_TIME}s..." >&2
    sleep $WAIT_TIME
  fi
done

if [ $RETRY -eq $MAX_RETRIES ]; then
  echo "❌ Operation failed after $MAX_RETRIES retries" >&2
  exit 1
fi
```

### Error Logging

```bash
# Log errors for debugging
LOG_ERROR() {
  local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
  local message="$1"

  echo "[$timestamp] ERROR: $message" >> "$LOG_FILE" 2>&1

  # Also show to user
  echo "❌ $message" >&2
}

# Usage
if ! process_file; then
  LOG_ERROR "Failed to process $FILE_PATH"
  exit 1
fi
```

---

## 4. ⚠️ COMMON ANTI-PATTERNS

### Blocking PreCompact Hooks Anti-Pattern

**Before (Incorrect)**:
```bash
# Try to block compaction
if [ "$VALIDATION_FAILED" = true ]; then
  exit 1  # Doesn't work! PreCompact cannot block
fi
```

**After (Correct)**:
```bash
# Log warning and allow
if [ "$VALIDATION_FAILED" = true ]; then
  echo "⚠️  Validation failed, but allowing compaction" >&2
  LOG_WARNING "Validation failed but compaction proceeded"
  exit 0  # Always exit 0 for PreCompact
fi
```

**Why Better**: PreCompact hooks cannot block by design to prevent hooks from leaving Claude Code unusable. Always exit 0 and log warnings instead.

### Using Bash 4+ Features Anti-Pattern

**Before (Incompatible)**:
```bash
# Associative arrays (bash 4+)
declare -A my_array
my_array["key"]="value"
```

**After (Compatible)**:
```bash
# Use indexed arrays or jq
KEYS=("key1" "key2" "key3")
VALUES=("val1" "val2" "val3")

# Or use jq for complex data
DATA='{"key1":"val1","key2":"val2"}'
VALUE=$(echo "$DATA" | jq -r '.key1')
```

**Why Better**: macOS ships with bash 3.2.57 and won't upgrade due to licensing. Bash 4+ features break compatibility.

### Slow Operations in Fast Hooks Anti-Pattern

```bash
# ❌ BAD: Network call in PreToolUse (<50ms target)
RESULT=$(curl -s https://api.example.com/validate)

# ✅ GOOD: Cache or use background check
CACHE_FILE="/tmp/validation_cache.json"
if [ ! -f "$CACHE_FILE" ] || [ $(find "$CACHE_FILE" -mmin +60) ]; then
  # Cache expired or missing - refresh in background
  curl -s https://api.example.com/validate > "$CACHE_FILE" &
fi

if [ -f "$CACHE_FILE" ]; then
  RESULT=$(cat "$CACHE_FILE")
fi
```

**Why**: PreToolUse blocks tool execution - must be <50ms.

### Missing Input Validation Anti-Pattern

```bash
# ❌ BAD: Use raw input
cd "$USER_CWD"
rm -rf "$USER_PATH"/*

# ✅ GOOD: Validate first
SAFE_CWD=$(realpath "$USER_CWD" 2>/dev/null)
if [ -z "$SAFE_CWD" ] || [ ! -d "$SAFE_CWD" ]; then
  echo "Invalid directory" >&2
  exit 1
fi
cd "$SAFE_CWD"

# Never rm -rf without multiple validations!
```

**Why**: Input validation prevents security vulnerabilities and crashes.

### Unquoted Variables Anti-Pattern

```bash
# ❌ BAD: Unquoted variables
if [ $VAR = "value" ]; then  # Fails if $VAR is empty
  cd $DIR  # Word splitting vulnerability
fi

# ✅ GOOD: Always quote
if [ "$VAR" = "value" ]; then
  cd "$DIR"
fi
```

**Why**: Unquoted variables cause word splitting and globbing issues.

---

## 5. ✅ RECOMMENDED PATTERNS

### Pattern: Dependency Chain

Check all dependencies upfront:

```bash
DEPS=("jq" "node" "git")
MISSING=()

for dep in "${DEPS[@]}"; do
  if ! command -v "$dep" &>/dev/null; then
    MISSING+=("$dep")
  fi
done

if [ ${#MISSING[@]} -gt 0 ]; then
  echo "⚠️  Missing dependencies: ${MISSING[*]}" >&2
  exit 0  # Graceful degradation
fi
```

### Pattern: Atomic File Operations

```bash
# Write to temp file, then move (atomic)
TEMP_FILE=$(mktemp)
trap "rm -f $TEMP_FILE" EXIT  # Cleanup on exit

echo "content" > "$TEMP_FILE"

# Atomic move
if mv "$TEMP_FILE" "$TARGET_FILE"; then
  echo "✅ File written atomically"
else
  echo "❌ Write failed" >&2
  exit 1
fi
```

### Pattern: Logging with Context

Include context in all log messages:

```bash
LOG_FILE="$HOOKS_DIR/logs/my-hook.log"

# Include: timestamp, session, operation, result
TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')
echo "[$TIMESTAMP] [$SESSION_ID] Operation: $OP | Result: $RESULT" >> "$LOG_FILE"
```

### Pattern: Performance Tracking

Always measure and log performance:

```bash
START_TIME=$(date +%s%N)

# ... hook logic ...

END_TIME=$(date +%s%N)
DURATION=$(( (END_TIME - START_TIME) / 1000000 ))

# Log performance
log_performance "hook-name" "$DURATION"

# Alert if slow
if [ $DURATION -gt $TARGET_MS ]; then
  echo "⚠️  Performance: ${DURATION}ms (target: ${TARGET_MS}ms)" >&2
fi
```

### Pattern: Feature Flags

Use environment variables for feature toggles:

```bash
# Feature flag (default: disabled)
ENABLE_FEATURE=${ENABLE_MY_FEATURE:-false}

if [ "$ENABLE_FEATURE" = "true" ]; then
  # Feature code
  echo "🎯 Feature enabled"
fi
```

---

## 6. 🐚 BASH 3.2 COMPATIBILITY

### Forbidden Features

Features that don't work in bash 3.2:

```bash
# ❌ Associative arrays (bash 4.0+)
declare -A array

# ❌ Process substitution with pipelines (unreliable)
mapfile -t lines < <(command)
readarray -t lines < <(command)

# ❌ Negative array indices (bash 4.2+)
echo "${array[-1]}"

# ❌ {start..end..step} brace expansion (bash 4.0+)
for i in {0..10..2}; do
  echo $i
done
```

### Bash 3.2 Alternatives

```bash
# ✅ Use indexed arrays
KEYS=("key1" "key2")
VALUES=("val1" "val2")

# ✅ Use while read loops
while IFS= read -r line; do
  lines+=("$line")
done < <(command)

# ✅ Use array length for last element
last_index=$((${#array[@]} - 1))
echo "${array[$last_index]}"

# ✅ Use seq for step ranges
for i in $(seq 0 2 10); do
  echo $i
done
```

---

## 7. 🧪 TESTING RECOMMENDATIONS

### Unit Testing Functions

```bash
# Test individual functions
test_sanitize_session_id() {
  INPUT="abc-123_DEF!@#"
  RESULT=$(sanitize_session_id "$INPUT")
  EXPECTED="abc-123_DEF"

  if [ "$RESULT" = "$EXPECTED" ]; then
    echo "✅ test_sanitize_session_id PASSED"
    return 0
  else
    echo "❌ test_sanitize_session_id FAILED" >&2
    echo "   Expected: $EXPECTED" >&2
    echo "   Got: $RESULT" >&2
    return 1
  fi
}
```

### Integration Testing

```bash
# Test full hook with realistic payload
test_hook_integration() {
  PAYLOAD='{"session_id":"test123","cwd":"'"$PWD"'"}'
  RESULT=$(echo "$PAYLOAD" | ./my-hook.sh)
  EXIT_CODE=$?

  if [ $EXIT_CODE -eq 0 ]; then
    echo "✅ Integration test PASSED"
  else
    echo "❌ Integration test FAILED (exit: $EXIT_CODE)" >&2
    echo "   Output: $RESULT" >&2
  fi
}
```

### Security Testing

```bash
# Test malicious input handling
test_security() {
  MALICIOUS_PAYLOADS=(
    '{"session_id":"../../etc/passwd"}'
    '{"cwd":"/tmp; rm -rf /"}'
    '{"field":"$(malicious_command)"}'
  )

  for payload in "${MALICIOUS_PAYLOADS[@]}"; do
    echo "$payload" | ./my-hook.sh >/dev/null 2>&1
    EXIT_CODE=$?

    # Should exit safely (0 or 1), not crash
    if [ $EXIT_CODE -le 2 ]; then
      echo "✅ Security test passed: $payload"
    else
      echo "❌ Security test failed: $payload (exit: $EXIT_CODE)" >&2
    fi
  done
}
```

---

## 8. ✅ DEPLOYMENT CHECKLIST

Before production deployment:

- [ ] **Performance**: Within target time for hook type
- [ ] **Security**: All inputs sanitized, paths validated
- [ ] **Compatibility**: Bash 3.2+ features only
- [ ] **Error Handling**: Graceful degradation for missing dependencies
- [ ] **Logging**: Operations and performance logged
- [ ] **Testing**: All test scenarios pass (valid, missing, malicious, performance)
- [ ] **Documentation**: File header complete with version and purpose
- [ ] **Validation**: `validate_hook.sh` passes without warnings
- [ ] **Peer Review**: Code reviewed by another developer (if applicable)
- [ ] **Rollback Plan**: Know how to disable hook if issues arise

---

## 9. 📊 MONITORING IN PRODUCTION

### Daily Checks

```bash
# Check for errors
grep -i "error\|failed" .claude/hooks/logs/my-hook.log | tail -20

# Check performance
awk '$3 > 200 {print}' .claude/hooks/logs/performance.log | grep my-hook | tail -10

# Check execution frequency
grep "my-hook" .claude/hooks/logs/performance.log | wc -l
```

### Weekly Review

```bash
# Average execution time
awk '/my-hook/ {sum+=$NF; count++} END {print sum/count "ms"}' \
  .claude/hooks/logs/performance.log

# Error rate
TOTAL=$(grep -c "my-hook" .claude/hooks/logs/my-hook.log)
ERRORS=$(grep -c "ERROR" .claude/hooks/logs/my-hook.log)
echo "Error rate: $(( ERRORS * 100 / TOTAL ))%"
```

### Performance Regression Detection

```bash
# Compare current week vs previous week
CURRENT_AVG=$(grep "my-hook" .claude/hooks/logs/performance.log | \
  tail -100 | awk '{sum+=$NF; count++} END {print sum/count}')

PREVIOUS_AVG=$(grep "my-hook" .claude/hooks/logs/performance.log | \
  tail -200 | head -100 | awk '{sum+=$NF; count++} END {print sum/count}')

REGRESSION=$(echo "scale=2; ($CURRENT_AVG - $PREVIOUS_AVG) / $PREVIOUS_AVG * 100" | bc)
echo "Performance change: ${REGRESSION}%"
```

---

## 10. 📚 SUMMARY

**Performance**: Early exits, caching, lazy checks, efficient jq usage
**Security**: Sanitize inputs, validate paths, quote variables, no eval
**Reliability**: Graceful degradation, comprehensive errors, retry logic
**Compatibility**: Bash 3.2+ only, test on macOS
**Testing**: Unit + integration + security + performance
**Monitoring**: Daily error checks, weekly performance reviews

For more information:
- `hook_types.md`: Hook capabilities and limitations
- `hook_creation_guide.md`: Step-by-step implementation
- `payload_structures.md`: JSON schemas and extraction
- `testing_guide.md`: Comprehensive testing strategies
