# Hook Asset Templates - Claude Code Hooks

Complete templates for creating hook asset files. Hook assets are working production-ready hook examples that demonstrate patterns and serve as copy-paste starting points for common use cases.

---

## 1. 📖 WHAT ARE HOOK ASSETS?

**Purpose**: Hook assets are production-ready example hooks that demonstrate best practices and serve as templates for common use cases.

**Key Characteristics**:
- **Working code**: Fully functional hooks that can be deployed immediately
- **Best practices**: Demonstrate security, performance, and error handling patterns
- **Copy-paste ready**: Minimal modification needed for common use cases
- **Reference implementations**: Show correct usage of hook APIs and patterns

**Location**: `.claude/skills/create-hooks/assets/`

**Benefits**:
- Accelerates hook development (copy-paste starting point)
- Ensures consistency across hooks
- Documents patterns through working code
- Reduces security vulnerabilities through vetted examples
- Provides performance-optimized implementations

---

## 2. 🎯 WHEN TO CREATE HOOK ASSET FILES

**Create hook asset files when**:
- Common hook pattern used multiple times across projects
- Complex implementation worth documenting with working code
- Best practice pattern that should be standardized
- Security-critical pattern (validation, sanitization, authentication)
- Performance-optimized implementation to share

**Don't create hook assets for**:
- Simple one-off hooks (keep in project-specific directory)
- Experimental or untested code
- Project-specific logic (not reusable across projects)
- Hooks still under active development

**Examples of good hook assets**:
- ✅ PreCompact context save hook (common pattern, widely reusable)
- ✅ Bash command validation hook (security pattern, critical use case)
- ✅ Markdown auto-format hook (quality pattern, standardization)
- ❌ Project-specific API integration hook (not reusable)
- ❌ Experimental ML model integration (not production-ready)

---

## 3. 📂 HOOK ASSET FILE INFORMATION

**`file_name`**: `[hooktype]_[purpose]_example.sh` (e.g., `precompact_context_save_example.sh`)
**`hook_type`**: [PreCompact | UserPromptSubmit | PreToolUse | PostToolUse | PreMessageCreate | PostMessageCreate | PreSessionStart | PostSessionEnd]
**`can_block`**: [Yes | No]
**`created`**: [YYYY-MM-DD]
**`version`**: 1.0.0

---

## 4. 📋 OVERVIEW

**Use Case**: [One sentence describing what this hook does and why it's useful]

**Implementation**: See `assets/[filename].sh` (working production hook)

**Key Patterns**:
- [Pattern 1: e.g., Parse JSON payload for specific fields]
- [Pattern 2: e.g., Validate input with security sanitization]
- [Pattern 3: e.g., Execute core logic with error handling]
- [Pattern 4: e.g., Exit with appropriate code (0/1/2)]

**Integration**: [List external skills, libraries, or tools used]

---

## 5. 🏗️ HOOK STRUCTURE

### File Header

```bash
#!/bin/bash
# Version: 1.0.0
# Purpose: [Brief description of hook purpose]
# Hook Type: [HookType]
# Can Block: [Yes/No]
# Performance Target: [<50ms | <200ms | <500ms | <5s]
# Exit Codes:
#   0: [What triggers exit 0]
#   1: [What triggers exit 1, or "N/A - cannot block"]
#   2: [What triggers exit 2, or "N/A - cannot block"]
```

### Library Imports

```bash
# Determine hooks directory
HOOKS_DIR="${CLAUDE_HOOKS_DIR:-.claude/hooks}"

# Source shared libraries
source "$HOOKS_DIR/lib/exit-codes.sh"
source "$HOOKS_DIR/lib/output-helpers.sh"
```

### Dependency Checks

```bash
# Check required dependencies
if ! check_dependency "jq" "brew install jq"; then
  log_error "jq required but not found"
  exit $EXIT_ERROR
fi
```

### Input Parsing

```bash
# Read JSON payload from stdin
INPUT=$(cat)

# Extract required fields with fallbacks
FIELD1=$(echo "$INPUT" | jq -r '.field1 // "default"' 2>/dev/null)
FIELD2=$(echo "$INPUT" | jq -r '.field2 // "default"' 2>/dev/null)

# Sanitize inputs for security
SAFE_FIELD1=$(echo "$FIELD1" | tr -cd 'a-zA-Z0-9_-')
```

### Main Logic

```bash
# Performance timing start
START_TIME=$(date +%s%N)

# Core hook logic
[Your implementation here]

# Performance timing end
END_TIME=$(date +%s%N)
DURATION=$(( (END_TIME - START_TIME) / 1000000 ))
log_performance "hook-name" "$DURATION"
```

### Exit Handling

```bash
# Success case
log_info "Hook completed successfully"
exit $EXIT_ALLOW

# Block case (if hook can block)
log_warn "Validation failed: [reason]"
exit $EXIT_BLOCK

# Error case
log_error "Hook failed: [reason]"
exit $EXIT_ERROR
```

---

## 6. ✅ TESTING

### Test Payload Example

```json
{
  "field1": "test_value1",
  "field2": "test_value2",
  "trigger": "manual",
  "session_id": "test-session-123",
  "cwd": "/path/to/project"
}
```

### Validation Command

```bash
# Static validation
.claude/skills/create-hooks/scripts/validate_hook.sh \
  .claude/hooks/[HookType]/[filename].sh

# Functional testing
echo '[test_payload_json]' | \
  .claude/skills/create-hooks/scripts/test_hook.sh \
  .claude/hooks/[HookType]/[filename].sh -
```

### Expected Behavior

- **Valid input**: Exit 0, log success message
- **Invalid input**: Exit 1 (if can block) or 0 (if cannot block), log warning
- **Error condition**: Exit 2 (if can block) or 0 (if cannot block), log error
- **Performance**: Complete within [target] ms

---

## 7. 🔌 INTEGRATION POINTS

### Related Skills

- [Skill 1]: [How it's used in this hook]
- [Skill 2]: [How it's used in this hook]

### External Tools

- [Tool 1]: [Purpose and usage]
- [Tool 2]: [Purpose and usage]

### Shared Libraries

- `lib/output-helpers.sh`: [Which functions are used]
- `lib/exit-codes.sh`: [Which constants are used]
- `lib/[other].sh`: [Purpose if applicable]

---

## 8. 🎯 COMMON PATTERNS

### Pattern 1: [Pattern Name]

**Use When**: [When to apply this pattern]

**Example**:
```bash
# [Pattern implementation code]
```

**Benefits**:
- [Benefit 1]
- [Benefit 2]

### Pattern 2: [Pattern Name]

**Use When**: [When to apply this pattern]

**Example**:
```bash
# [Pattern implementation code]
```

**Benefits**:
- [Benefit 1]
- [Benefit 2]

---

## 9. 🔒 SECURITY CONSIDERATIONS

- **Input sanitization**: [How this hook sanitizes user input]
- **Path validation**: [How file paths are validated]
- **Command injection prevention**: [How eval/exec are avoided]
- **Privilege escalation**: [How permissions are handled]

---

## 10. ⚡ PERFORMANCE OPTIMIZATION

- **Caching**: [What is cached and why]
- **Early exits**: [Conditions for skipping work]
- **Async operations**: [What runs asynchronously]
- **Bottleneck analysis**: [Known performance considerations]

---

## 11. 🔧 TROUBLESHOOTING

### Issue: [Common Problem 1]

**Symptoms**: [How to recognize this issue]
**Cause**: [Root cause explanation]
**Solution**: [Step-by-step fix]

### Issue: [Common Problem 2]

**Symptoms**: [How to recognize this issue]
**Cause**: [Root cause explanation]
**Solution**: [Step-by-step fix]

---

## 12. 📚 REFERENCES

- [Hook Types Documentation]: `references/hook_types.md#[hooktype]`
- [Payload Structure]: `references/payload_structures.md#[hooktype]-payload`
- [Best Practices]: `references/best_practices.md#[relevant-section]`
- [Testing Guide]: `references/testing_guide.md#[relevant-phase]`

---

## 13. ✅ HOOK ASSET CHECKLIST

Use this checklist to validate your hook asset is complete and production-ready:

**Structure & Documentation**:
- [ ] File follows naming convention: `[hooktype]_[purpose]_example.sh`
- [ ] File header complete with version, purpose, hook type, can block status
- [ ] Exit codes documented (0, 1, 2 with descriptions)
- [ ] Performance target specified and tested
- [ ] All sections of this template addressed

**Implementation Quality**:
- [ ] Shared libraries sourced (exit-codes.sh, output-helpers.sh)
- [ ] Dependencies checked with fallback messages
- [ ] Input parsing with JSON error handling
- [ ] Input sanitization for security (no eval/exec of user input)
- [ ] Performance timing implemented and logged
- [ ] Proper exit code handling (EXIT_ALLOW, EXIT_BLOCK, EXIT_ERROR)

**Testing & Validation**:
- [ ] Static validation passes (validate_hook.sh)
- [ ] Functional testing passes with test payload
- [ ] Performance target met in testing
- [ ] Security patterns verified (sanitization, path validation)
- [ ] Error cases handled gracefully

**Documentation & Integration**:
- [ ] Use case clearly described
- [ ] Key patterns documented
- [ ] Example payload provided
- [ ] Related skills/tools listed
- [ ] Cross-references to other documentation complete

**Production Readiness**:
- [ ] No hardcoded paths or credentials
- [ ] Compatible with Bash 3.2+
- [ ] Graceful degradation if optional dependencies missing
- [ ] Logging appropriate (not too verbose for production)
- [ ] Tested in production-like environment

---

## 14. 🔄 HOOK ASSET MAINTENANCE

### Lifecycle Management

**When to Update**:
- Bug fixes discovered in production
- Performance optimizations identified
- Security vulnerabilities detected
- New best practices emerge
- Hook type specifications change
- Shared library APIs updated

**Version Numbering**:
- **Major (X.0.0)**: Breaking changes, incompatible with previous versions
- **Minor (1.X.0)**: New features, backward compatible
- **Patch (1.0.X)**: Bug fixes, no new features

**Update Process**:
1. Test changes against validation suite
2. Update version number in file header
3. Update VERSION HISTORY section below
4. Re-run static validation (validate_hook.sh)
5. Test with production-like payload
6. Update related documentation if needed

**Deprecation Process**:
1. Mark as deprecated in file header: `# Status: DEPRECATED`
2. Add deprecation notice in Overview section
3. Specify replacement hook or migration path
4. Keep file available for 2 minor versions minimum
5. Remove only after confirming no active usage

**Monitoring & Feedback**:
- Track usage through hook logs
- Monitor performance metrics
- Review error reports from production
- Collect feedback from hook developers
- Update based on emerging patterns