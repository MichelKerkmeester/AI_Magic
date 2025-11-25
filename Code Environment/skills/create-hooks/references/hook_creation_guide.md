# Hook Creation Guide - Claude Code Hooks

Step-by-step process for creating production-ready Claude Code hooks from planning to deployment. This guide walks you through all phases: planning, template selection, implementation, validation, testing, and deployment with real-world examples and best practices.

---

## 1. 📋 PREREQUISITES

### Required Knowledge

- **Bash Scripting Basics**: Variables, conditionals, loops, functions
- **JSON Parsing**: Using `jq` for JSON extraction
- **Exit Codes**: Understanding 0=success, non-zero=error
- **File Permissions**: chmod, executable bits
- **Text Processing**: grep, sed, tr for string manipulation

### Required Tools

Verify these tools are installed before creating hooks:

```bash
# Bash 3.2+ (check version)
bash --version
# Should show 3.2.x or higher

# jq (JSON processor)
jq --version
# Install: brew install jq (macOS) or apt install jq (Linux)

# node (if hook needs JavaScript)
node --version
# Install from https://nodejs.org/

# realpath (path validation)
realpath --version
# Usually included in GNU coreutils
```

### Environment Setup

```bash
# Verify dependencies
command -v bash && echo "✅ bash available"
command -v jq && echo "✅ jq available"
command -v node && echo "✅ node available"
command -v realpath && echo "✅ realpath available"

# Check bash version (must be 3.2+)
BASH_VERSION=$(bash --version | head -1 | grep -oE '[0-9]+\.[0-9]+')
echo "Bash version: $BASH_VERSION"
```

---

## 2. 🎯 STEP 1: PLANNING (10-15 MINUTES)

Before writing any code, answer these planning questions:

### Critical Questions

1. **What trigger point do I need?**
   - When should the hook fire? (before tool, after message, etc.)
   - Review `hook_types.md` for trigger point descriptions

2. **What should the hook accomplish?**
   - What specific action or validation?
   - What are the success criteria?

3. **Can it block execution?**
   - Must it block (PreToolUse) or just observe (PostToolUse)?
   - What happens if hook fails?

4. **What performance target is acceptable?**
   - <50ms for blocking hooks (PreToolUse)
   - <200ms for user-facing hooks (UserPromptSubmit, PostToolUse)
   - <5s for background hooks (PreCompact)

5. **What external dependencies are required?**
   - Does it need jq, node, git, external APIs?
   - How to handle missing dependencies?

### Decision Matrix

Use this matrix to choose hook type:

| Goal | Hook Type | Rationale |
|------|-----------|-----------|
| Save context before loss | PreCompact | Fires before compaction |
| Auto-trigger on keywords | UserPromptSubmit | Analyzes user message |
| Block dangerous commands | PreToolUse | Validates before execution |
| Format code after edit | PostToolUse | Auto-fix after change |
| Validate environment | PreSessionStart | Checks before session |
| Clean up temp files | PostSessionEnd | Cleanup after session |

### Planning Template

Create a brief plan document:

```markdown
# Hook: [name]

## Purpose
[What does this hook do?]

## Hook Type
[PreCompact, UserPromptSubmit, PreToolUse, etc.]

## Trigger Condition
[When exactly does this fire?]

## Required Payload Fields
[Which JSON fields are needed?]

## Success Criteria
[What defines successful execution?]

## Performance Target
[<50ms, <200ms, <5s, etc.]

## Dependencies
[jq, node, git, external tools, etc.]

## Error Handling
[What happens when things fail?]
```

---

## 3. 📂 STEP 2: TEMPLATE SELECTION (5 MINUTES)

### Choose Your Starting Point

**Option A: Base Template** (for new hooks)
```bash
cp .claude/skills/create-hooks/assets/hook_template.sh \
   .claude/hooks/{HookType}/my-hook.sh
```

**Option B: Similar Example** (for similar use cases)
```bash
# For PreCompact hooks
cp .claude/skills/create-hooks/assets/precompact_example.sh \
   .claude/hooks/PreCompact/my-context-hook.sh

# For UserPromptSubmit hooks (keyword detection)
cp .claude/skills/create-hooks/assets/userpromptssubmit_example.sh \
   .claude/hooks/UserPromptSubmit/my-keyword-hook.sh

# For PreToolUse hooks (validation)
cp .claude/skills/create-hooks/assets/pretooluse_example.sh \
   .claude/hooks/PreToolUse/my-validator.sh

# For PostToolUse hooks (auto-fix)
cp .claude/skills/create-hooks/assets/posttooluse_example.sh \
   .claude/hooks/PostToolUse/my-formatter.sh
```

### Make Executable

```bash
chmod +x .claude/hooks/{HookType}/my-hook.sh
```

### Hook Naming Conventions

- **Lowercase with hyphens**: `save-context-before-compact.sh`
- **Descriptive**: Name should explain what it does
- **Verb-first**: `validate-bash.sh`, `enforce-markdown.sh`
- **Extension**: Always `.sh` for bash scripts

---

## 4. ⚙️ STEP 3: IMPLEMENTATION (30-60 MINUTES)

### File Header Template

Every hook must start with this header structure:

```bash
#!/bin/bash

# ───────────────────────────────────────────────────────────────
# HOOK NAME
# ───────────────────────────────────────────────────────────────
# Brief description of what this hook does (1-2 sentences)
#
# Version: 1.0.0
# Created: YYYY-MM-DD
#
# PERFORMANCE TARGET: <Xms/s>
# COMPATIBILITY: Bash 3.2+ (macOS and Linux compatible)
#
# EXECUTION ORDER: {HookType} hook
#   Fires when: [specific trigger condition]
#   Can block: YES/NO
#   Purpose: [primary purpose]
#
# EXIT CODE CONVENTION:
#   0 = [meaning for this hook - usually Allow/Success]
#   1 = [meaning for this hook - usually Block/Warning]
#   2 = [meaning for this hook - usually Error]
# ───────────────────────────────────────────────────────────────
```

### Required Components

Every hook needs these 8 components in order:

#### 1. Source Shared Libraries

```bash
# Locate directories
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" 2>/dev/null && pwd)"
HOOKS_DIR="$(cd "$SCRIPT_DIR/.." 2>/dev/null && pwd)"

# Source helper libraries
source "$HOOKS_DIR/lib/output-helpers.sh" || exit 0
source "$HOOKS_DIR/lib/exit-codes.sh" || exit 0
```

#### 2. Performance Timing Start

```bash
# Performance timing START
START_TIME=$(date +%s%N)
```

#### 3. Dependency Checks

```bash
# Check required tools
if ! check_dependency "jq" "brew install jq (macOS) or apt install jq (Linux)"; then
  echo "   ⚠️  Hook skipped: jq not available" >&2
  exit $EXIT_ALLOW  # Graceful degradation
fi

# Check optional tools (non-blocking)
if ! command -v prettier &>/dev/null; then
  echo "   💡 prettier not found (optional)" >&2
fi
```

#### 4. Parse JSON Payload

```bash
# Read JSON from stdin
INPUT=$(cat)

# Extract fields with fallbacks
FIELD1=$(echo "$INPUT" | jq -r '.field1 // empty' 2>/dev/null)
FIELD2=$(echo "$INPUT" | jq -r '.field2 // "default_value"' 2>/dev/null)
SESSION_ID=$(echo "$INPUT" | jq -r '.session_id // empty' 2>/dev/null)
CWD=$(echo "$INPUT" | jq -r '.cwd // empty' 2>/dev/null)
```

#### 5. Input Sanitization (Security)

```bash
# Sanitize session ID (alphanumeric + dash/underscore only)
if [ -n "$SESSION_ID" ]; then
  SESSION_ID=$(echo "$SESSION_ID" | tr -cd 'a-zA-Z0-9_-')
fi

# Validate and sanitize path
if [ -n "$CWD" ]; then
  SAFE_CWD=$(realpath "$CWD" 2>/dev/null || echo "$CWD")
  if [ ! -d "$SAFE_CWD" ]; then
    echo "   ⚠️  Invalid working directory: $CWD" >&2
    exit $EXIT_ALLOW  # or EXIT_BLOCK depending on severity
  fi
fi

# Sanitize user text (remove shell metacharacters if needed)
SAFE_TEXT=$(echo "$USER_TEXT" | tr -cd '[:alnum:][:space:]._-')
```

#### 6. Validation

```bash
# Validate required fields
if [ -z "$REQUIRED_FIELD" ]; then
  echo "   ❌ Error: Required field missing" >&2
  exit $EXIT_BLOCK  # or EXIT_ALLOW for non-critical
fi

# Validate business logic
if ! validate_logic; then
  echo "   ⚠️  Validation failed: $REASON" >&2
  exit $EXIT_BLOCK
fi
```

#### 7. Core Logic

```bash
# ───────────────────────────────────────────────────────────────
# CORE LOGIC
# ───────────────────────────────────────────────────────────────

# Implement your hook's main functionality here
# Example patterns:

# Pattern A: Keyword Detection
if echo "$PROMPT" | grep -qiE "\\b(keyword1|keyword2)\\b"; then
  echo "🎯 Detected keyword - triggering action"
  # perform action
fi

# Pattern B: File Processing
if [ -f "$FILE_PATH" ]; then
  # process file
  process_file "$FILE_PATH"
fi

# Pattern C: Command Validation
if ! validate_command "$COMMAND"; then
  echo "🚫 BLOCKED: Invalid command" >&2
  exit $EXIT_BLOCK
fi

# Pattern D: External Script Execution
if ! node "$SCRIPT_PATH" "$ARG1" "$ARG2"; then
  echo "   ⚠️  Script execution failed" >&2
  exit $EXIT_ALLOW  # or EXIT_ERROR depending on severity
fi
```

#### 8. Performance Logging & Exit

```bash
# ───────────────────────────────────────────────────────────────
# PERFORMANCE LOGGING
# ───────────────────────────────────────────────────────────────

END_TIME=$(date +%s%N)
DURATION=$(( (END_TIME - START_TIME) / 1000000 ))

# Log performance (use helper from output-helpers.sh)
log_performance "my-hook" "$DURATION"

# Optional: Log to hook-specific file
LOG_DIR="$HOOKS_DIR/logs"
mkdir -p "$LOG_DIR"
echo "[$(date '+%Y-%m-%d %H:%M:%S')] my-hook ${DURATION}ms" >> "$LOG_DIR/performance.log"

# ───────────────────────────────────────────────────────────────
# EXIT
# ───────────────────────────────────────────────────────────────

exit $EXIT_ALLOW  # or EXIT_BLOCK, EXIT_ERROR as appropriate
```

### Complete Code Structure Template

```bash
#!/bin/bash

# [HEADER - see File Header Template above]

# 1. Source shared libraries
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" 2>/dev/null && pwd)"
HOOKS_DIR="$(cd "$SCRIPT_DIR/.." 2>/dev/null && pwd)"
source "$HOOKS_DIR/lib/output-helpers.sh" || exit 0
source "$HOOKS_DIR/lib/exit-codes.sh" || exit 0

# 2. Performance timing
START_TIME=$(date +%s%N)

# 3. Dependency checks
check_dependency "jq" || exit 0

# 4. Parse JSON payload
INPUT=$(cat)
FIELD=$(echo "$INPUT" | jq -r '.field // empty')

# 5. Input sanitization
SAFE_FIELD=$(echo "$FIELD" | tr -cd 'a-zA-Z0-9_-')

# 6. Validation
[ -z "$SAFE_FIELD" ] && exit 0

# 7. Core logic
echo "Processing: $SAFE_FIELD"
# [your logic here]

# 8. Performance logging & exit
END_TIME=$(date +%s%N)
DURATION=$(( (END_TIME - START_TIME) / 1000000 ))
log_performance "my-hook" "$DURATION"
exit $EXIT_ALLOW
```

---

## 5. ✅ STEP 4: VALIDATION (5-10 MINUTES)

### Run Automated Validation

```bash
.claude/skills/create-hooks/scripts/validate_hook.sh \
  .claude/hooks/{HookType}/my-hook.sh
```

### Validation Checks

The validation script checks:

1. **Executable permission** (`chmod +x`)
2. **Shebang present** (`#!/bin/bash`)
3. **Bash syntax valid** (`bash -n`)
4. **Bash 3.2+ compatible** (no `declare -A`, `mapfile`, `readarray`)
5. **Exit codes used correctly** (0, 1, or 2 only)
6. **Input sanitization present** (security patterns)
7. **Performance logging implemented**

### Manual Verification Checklist

- [ ] File header complete with version, purpose, exit codes
- [ ] Sources output-helpers.sh and exit-codes.sh
- [ ] Performance timing START and END present
- [ ] All user input sanitized
- [ ] Error messages descriptive and helpful
- [ ] Exit code appropriate for hook type
- [ ] Comments explain non-obvious logic
- [ ] No hardcoded paths (use variables)

### Fix Common Issues

**Issue: Executable permission missing**
```bash
chmod +x .claude/hooks/{HookType}/my-hook.sh
```

**Issue: Bash 4+ features detected**
```bash
# Replace associative arrays
# BAD: declare -A my_array
# GOOD: Use indexed arrays or jq

# Replace mapfile
# BAD: mapfile -t lines < file.txt
# GOOD: while IFS= read -r line; do lines+=("$line"); done < file.txt

# Replace readarray
# BAD: readarray -t items < <(command)
# GOOD: while IFS= read -r item; do items+=("$item"); done < <(command)
```

**Issue: Unquoted variables**
```bash
# BAD: cd $CWD
# GOOD: cd "$CWD"

# BAD: if [ $VAR = "value" ]; then
# GOOD: if [ "$VAR" = "value" ]; then
```

---

## 6. 🧪 STEP 5: TESTING (15-30 MINUTES)

### Create Test Payloads

Create JSON test files for different scenarios:

#### Valid Input (Happy Path)

```bash
cat > test-valid.json << 'EOF'
{
  "session_id": "test123",
  "cwd": "/tmp/test-project",
  "field": "valid_value"
}
EOF
```

#### Missing Required Field

```bash
cat > test-missing-field.json << 'EOF'
{
  "cwd": "/tmp/test-project"
}
EOF
```

#### Malicious Input (Security Test)

```bash
cat > test-malicious.json << 'EOF'
{
  "session_id": "../../../etc/passwd",
  "cwd": "/tmp; rm -rf /",
  "field": "$(malicious_command)"
}
EOF
```

#### Performance Test

```bash
# Use realistic payload size
cat > test-performance.json << 'EOF'
{
  "session_id": "perf_test_abc123",
  "cwd": "/tmp/test-project",
  "field": "value",
  "large_field": "[... large data ...]"
}
EOF
```

### Run Test Script

```bash
# Run all test scenarios
for payload in test-*.json; do
  echo "Testing with: $payload"
  .claude/skills/create-hooks/scripts/test_hook.sh \
    .claude/hooks/{HookType}/my-hook.sh \
    "$payload"
  echo "─────────────────────────────────────"
done
```

### Test Scenario Checklist

- [ ] Valid input: Hook succeeds (exit 0)
- [ ] Missing field: Graceful handling (warn or block appropriately)
- [ ] Malicious input: Sanitization works, no security breach
- [ ] Performance: Within target time (<50ms/<200ms/<5s)
- [ ] Error conditions: Clear error messages, proper exit codes
- [ ] Idempotent: Running multiple times produces same result

### Performance Benchmarking

```bash
# Measure execution time
time echo '{"session_id":"test","cwd":"'$PWD'"}' | \
  .claude/hooks/{HookType}/my-hook.sh

# Run 10 times and average
for i in {1..10}; do
  /usr/bin/time -p echo '{"session_id":"test","cwd":"'$PWD'"}' | \
    .claude/hooks/{HookType}/my-hook.sh 2>&1 | grep real
done
```

---

## 7. 🚀 STEP 6: DEPLOYMENT (5 MINUTES)

### Pre-Deployment Checklist

Before deploying to production:

- [ ] All validation checks pass
- [ ] All test scenarios pass (valid, missing, malicious, performance)
- [ ] Security patterns verified (sanitization, path validation)
- [ ] Performance within target for hook type
- [ ] Error handling comprehensive
- [ ] Logging implemented (operations and performance)
- [ ] Documentation complete (header, comments)
- [ ] Peer review completed (if applicable)

### Deploy Hook

Hook is already in correct location from implementation:

```bash
# Verify location and permissions
ls -la .claude/hooks/{HookType}/my-hook.sh

# Expected output:
# -rwxr-xr-x  1 user  staff  5432 Nov 24 14:30 my-hook.sh
#  ^^^^ executable bit set
```

### Monitor Initial Usage

```bash
# Watch logs in real-time
tail -f .claude/hooks/logs/my-hook.log

# Watch performance logs
tail -f .claude/hooks/logs/performance.log | grep my-hook

# Check for errors
grep -i "error\|failed" .claude/hooks/logs/my-hook.log
```

### Verify Hook Triggers

Test hook in real Claude Code session:

1. **PreCompact**: Run `/compact` and verify hook executes
2. **UserPromptSubmit**: Submit message with trigger condition
3. **PreToolUse**: Use tool that hook should validate
4. **PostToolUse**: Perform action that triggers post-processing

### Rollback Plan

If hook causes problems:

```bash
# Disable hook temporarily (remove executable bit)
chmod -x .claude/hooks/{HookType}/my-hook.sh

# Or move out of hooks directory
mv .claude/hooks/{HookType}/my-hook.sh \
   .claude/hooks/{HookType}/my-hook.sh.disabled
```

---

## 8. 🔧 COMMON PATTERNS

### Keyword Detection Pattern

```bash
#!/bin/bash
INPUT=$(cat)
PROMPT=$(echo "$INPUT" | jq -r '.prompt // empty')
PROMPT_LOWER=$(echo "$PROMPT" | tr '[:upper:]' '[:lower:]')

KEYWORDS=("save context" "save conversation" "document this")

for keyword in "${KEYWORDS[@]}"; do
  if echo "$PROMPT_LOWER" | grep -qF "$keyword"; then
    echo "🎯 Detected: '$keyword'"
    # Trigger action
    break
  fi
done

exit 0
```

### Validation with Blocking Pattern

```bash
#!/bin/bash
INPUT=$(cat)
COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // empty')

# Dangerous patterns
DANGEROUS=("rm -rf /" "dd if=/dev/zero" ":(){:|:&};:")

for pattern in "${DANGEROUS[@]}"; do
  if echo "$COMMAND" | grep -qF "$pattern"; then
    echo "🚫 BLOCKED: Dangerous command detected" >&2
    echo "   Pattern: $pattern" >&2
    exit 1  # Block execution
  fi
done

exit 0  # Allow execution
```

### Auto-Fix After Tool Use Pattern

```bash
#!/bin/bash
INPUT=$(cat)
TOOL_NAME=$(echo "$INPUT" | jq -r '.tool_name // empty')
FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty')

# Only process markdown files after Write/Edit
if [ "$TOOL_NAME" != "Write" ] && [ "$TOOL_NAME" != "Edit" ]; then
  exit 0
fi

if [[ "$FILE_PATH" != *.md ]]; then
  exit 0
fi

# Auto-format
if command -v prettier &>/dev/null; then
  prettier --write "$FILE_PATH" 2>/dev/null
  echo "✨ Auto-formatted: $(basename "$FILE_PATH")"
fi

exit 0
```

### External Script Execution Pattern

```bash
#!/bin/bash
INPUT=$(cat)

# Create temp file with payload
TEMP_JSON="/tmp/hook-payload-$$.json"
echo "$INPUT" > "$TEMP_JSON"

# Execute external script
if ! node "$HOOKS_DIR/scripts/process.js" "$TEMP_JSON"; then
  echo "   ⚠️  External script failed" >&2
  rm -f "$TEMP_JSON"
  exit 0  # Graceful degradation
fi

# Cleanup
rm -f "$TEMP_JSON"
exit 0
```

---

## 9. 🔍 TROUBLESHOOTING

### Issue: Hook Not Triggering

**Symptoms**: Hook never executes, no output in logs

**Debug Steps**:
1. Check hook location: `.claude/hooks/{HookType}/my-hook.sh`
2. Verify executable: `ls -l .claude/hooks/{HookType}/my-hook.sh` (should show -rwx)
3. Check for syntax errors: `bash -n my-hook.sh`
4. Review Claude Code logs for errors
5. Verify hook type matches trigger point

**Fix**:
```bash
# Make executable
chmod +x .claude/hooks/{HookType}/my-hook.sh

# Test manually
echo '{"test":"payload"}' | .claude/hooks/{HookType}/my-hook.sh
```

### Issue: Hook Blocks When It Shouldn't

**Symptoms**: Execution blocked unexpectedly

**Debug Steps**:
1. Check exit code in hook
2. Verify hook type can block (PreCompact cannot)
3. Review validation logic
4. Check error messages in logs

**Fix**:
```bash
# PreCompact hooks must always exit 0
if [ "$HOOK_TYPE" = "PreCompact" ]; then
  # Always allow
  exit 0
fi

# PostToolUse hooks must always exit 0
if [ "$HOOK_TYPE" = "PostToolUse" ]; then
  # Always allow (tool already ran)
  exit 0
fi
```

### Issue: Performance Too Slow

**Symptoms**: Hook takes longer than target time

**Debug Steps**:
1. Profile with `time` command
2. Identify bottleneck operations
3. Check for unnecessary external calls
4. Review loop efficiency

**Fix**:
```bash
# Bad: Multiple jq calls
FIELD1=$(echo "$INPUT" | jq -r '.field1')
FIELD2=$(echo "$INPUT" | jq -r '.field2')
FIELD3=$(echo "$INPUT" | jq -r '.field3')

# Good: Single jq call
read -r FIELD1 FIELD2 FIELD3 < <(echo "$INPUT" | jq -r '.field1, .field2, .field3')

# Bad: Expensive operation in loop
for file in *.txt; do
  expensive_operation "$file"
done

# Good: Early exit or caching
if [ "$CONDITION" = true ]; then
  exit 0  # Skip expensive work
fi
```

### Issue: Security Vulnerability

**Symptoms**: Hook vulnerable to injection or traversal

**Debug Steps**:
1. Review input sanitization
2. Check for eval usage
3. Verify path validation
4. Test with malicious payloads

**Fix**:
```bash
# Always sanitize session IDs
SESSION_ID=$(echo "$SESSION_ID" | tr -cd 'a-zA-Z0-9_-')

# Always validate paths
SAFE_PATH=$(realpath "$USER_PATH" 2>/dev/null)
if [ ! -d "$SAFE_PATH" ]; then
  echo "Invalid path" >&2
  exit 1
fi

# Never use eval with user input
# BAD: eval "$USER_COMMAND"
# GOOD: "$USER_COMMAND" (quoted and direct)

# Quote all variables
# BAD: cd $DIR
# GOOD: cd "$DIR"
```

---

## 10. 📚 BEST PRACTICES SUMMARY

### Performance
- Target <50ms for PreToolUse, <200ms for user-facing, <5s for PreCompact
- Use early exits to skip unnecessary work
- Cache expensive operations
- Profile regularly with `time` command

### Security
- Sanitize all user input (session IDs, paths, text)
- Use `realpath` for path validation
- Never use `eval` with user input
- Quote all variables in commands

### Reliability
- Graceful degradation for missing dependencies
- Comprehensive error handling with descriptive messages
- Idempotent operations (safe to run multiple times)
- Always exit with appropriate code

### Maintainability
- Complete file headers with version and purpose
- Inline comments for non-obvious logic
- Consistent naming conventions
- Follow bash 3.2+ compatibility

### Testing
- Validate syntax before deployment
- Test all scenarios (valid, missing, malicious, performance)
- Monitor initial production usage
- Have rollback plan ready

---

## 11. ⏭️ NEXT STEPS

After successfully creating your hook:

1. **Document**: Add entry to `.claude/hooks/README.md`
2. **Share**: If generally useful, consider contributing upstream
3. **Monitor**: Watch logs for first few days
4. **Iterate**: Gather feedback and improve
5. **Maintain**: Review and update as needs evolve

For more information:
- `hook_types.md`: Detailed hook type documentation
- `payload_structures.md`: Complete JSON schemas
- `best_practices.md`: Advanced patterns
- `testing_guide.md`: Comprehensive testing strategies
