---
name: create-hooks
description: Comprehensive hook creation documentation for Claude Code's 8 hook types. Provides templates, payload structures, best practices, testing strategies, and production examples for building custom hooks.
allowed-tools: [Read, Write, Edit, Bash]
version: 1.0.0
---

# Hook Creation Specialist

Create custom Claude Code hooks with templates, examples, and testing infrastructure for all 8 hook types.

**Core principle**: Hooks = event-driven automation at critical execution points. The right hook type + proper payload handling + security patterns = reliable, performant automation.

---

## 1. 🎯 CAPABILITIES OVERVIEW

This skill provides comprehensive hook creation guidance across Claude Code's 8 hook types, organized into three lifecycle phases:

### Phase 1: Pre-Execution Hooks (Validation & Preparation)

**PreSessionStart** - Environment validation before session begins
**UserPromptSubmit** - Keyword detection and auto-triggers before processing
**PreToolUse** - Safety validation before tool execution
**PreMessageCreate** - Content filtering before AI response
**PreCompact** - Context preservation before compaction

**Use when**: Need to validate, prepare, or save state BEFORE actions occur
**Capabilities**: Can block execution (except PreCompact), validate inputs, trigger workflows
**See**: Section 2 (References) → hook_types.md for detailed capabilities

### Phase 2: Post-Execution Hooks (Verification & Enhancement)

**PostToolUse** - Auto-formatting and cleanup after tool completion
**PostMessageCreate** - Logging and analytics after AI responds
**PostSessionEnd** - Cleanup and archiving after session terminates

**Use when**: Need to enhance, verify, or clean up AFTER actions complete
**Capabilities**: Cannot block (action already occurred), can modify results, log analytics
**See**: Section 2 (References) → hook_types.md for implementation patterns

### Progressive Disclosure Model

This skill follows a layered information architecture:
1. **SKILL.md** (this file): Overview, navigation, rules, quick reference
2. **references/**: Deep technical documentation (hook types, payloads, security, testing)
3. **assets/**: Templates and working examples ready to adapt
4. **scripts/**: Automation for validation and testing

Load resources progressively based on your current step in the creation workflow.

**See**: Section 4 (How to Use) for step-by-step workflow

---

## 2. 🗂️ REFERENCES

### Core Framework

This skill provides comprehensive hook creation guidance for Claude Code's 8 hook types:

| Hook Type | Trigger Point | Can Block? | Common Use Cases |
|-----------|---------------|------------|------------------|
| **PreCompact** | Before context compaction | No | Save context, backup transcript |
| **UserPromptSubmit** | User submits message | Yes | Keyword detection, auto-documentation |
| **PreToolUse** | Before tool execution | Yes | Validation, safety checks |
| **PostToolUse** | After tool execution | No | Auto-fix, logging |
| **PreMessageCreate** | Before AI response | Yes | Content filtering, validation |
| **PostMessageCreate** | After AI response | No | Analytics, archiving |
| **PreSessionStart** | Before session begins | Yes | Environment setup, validation |
| **PostSessionEnd** | After session ends | No | Cleanup, archiving |

### References

| Document | Purpose | Key Insight |
|----------|---------|-------------|
| **references/hook_types.md** | Complete documentation for all 8 hook types with payloads and capabilities | Load for hook type selection and payload structure understanding |
| **references/hook_creation_guide.md** | Step-by-step hook creation process from planning to deployment | Load for complete implementation workflow guidance |
| **references/payload_structures.md** | JSON schemas, extraction patterns, and security notes for all hook types | Load for payload parsing and input sanitization |
| **references/best_practices.md** | Performance optimization, security patterns, error handling strategies | Load for production-ready implementation patterns |
| **references/testing_guide.md** | Three-phase testing strategy with validation scenarios | Load for comprehensive hook testing and validation |

### Assets

| Document | Purpose | Key Insight |
|----------|---------|-------------|
| **assets/hook_template.sh** | Base template with all required sections (header, validation, main logic) | Load when starting any new hook implementation |
| **assets/precompact_example.sh** | Production PreCompact hook (context preservation workflow) | Load for context-saving patterns and skill integration |
| **assets/userpromptssubmit_example.sh** | Keyword detection and auto-trigger pattern | Load for prompt analysis and conditional execution |
| **assets/pretooluse_example.sh** | Validation hook with blocking capability | Load for safety checks and execution prevention |
| **assets/posttooluse_example.sh** | Auto-fix and formatting pattern | Load for post-execution enhancement workflows |
| **assets/hook_asset_template.md** | Template for creating new hook asset documentation | Load when documenting a new hook example |
| **assets/hook_reference_template.md** | Template for creating new reference documentation | Load when creating new reference guides |

### Scripts

| Document | Purpose | Key Insight |
|----------|---------|-------------|
| **scripts/validate_hook.sh** | Static analysis: syntax, permissions, bash 3.2 compatibility, security patterns | Execute before deployment for compatibility verification |
| **scripts/test_hook.sh** | Dynamic testing: execute with payloads, measure performance, verify exit codes | Execute for functional validation and performance benchmarking |

### Hook Type Decision Tree

```
What do you need to automate?
│
├─ Before compaction? → PreCompact
│  (save context, backup)
│
├─ User submits message? → UserPromptSubmit
│  (keyword triggers, validation)
│
├─ Before tool runs? → PreToolUse
│  (validation, safety checks)
│
├─ After tool completes? → PostToolUse
│  (auto-fix, formatting)
│
├─ Before AI responds? → PreMessageCreate
│  (content filtering)
│
├─ After AI responds? → PostMessageCreate
│  (logging, analytics)
│
├─ Session starts? → PreSessionStart
│  (environment setup)
│
└─ Session ends? → PostSessionEnd
   (cleanup, archiving)
```

### Smart Routing Logic

```python
def hook_creation_workflow(automation_need):
    hook_type_mapping = {
        "before_compaction": "PreCompact",
        "user_submits_message": "UserPromptSubmit",
        "before_tool_runs": "PreToolUse",
        "after_tool_completes": "PostToolUse",
        "before_ai_responds": "PreMessageCreate",
        "after_ai_responds": "PostMessageCreate",
        "session_starts": "PreSessionStart",
        "session_ends": "PostSessionEnd"
    }

    selected_type = hook_type_mapping.get(select_hook_type(automation_need))
    capabilities = load_hook_capabilities(selected_type)

    hook_path = f".claude/hooks/{selected_type}/my-hook.sh"
    copy_template(load_template("assets/hook_template.sh"), hook_path)

    implement_hook_logic(hook_path, automation_need)

    if needs_payload_parsing(automation_need):
        extract_required_fields_with_jq(hook_path, load_payload_patterns())

    if needs_security_patterns(automation_need):
        implement_sanitization(hook_path, load_security_patterns())

    validation = execute_validation_script("scripts/validate_hook.sh", hook_path)
    while not validation.passed:
        fix_validation_issues(hook_path, validation.issues)
        validation = execute_validation_script("scripts/validate_hook.sh", hook_path)

    test_payload = create_test_payload(selected_type, "test.json")
    testing_strategies = load_testing_guide()

    test_results = execute_test_script("scripts/test_hook.sh", hook_path, test_payload)
    while not test_results.passed:
        debug_hook_logic(hook_path, test_results.failures)
        test_results = execute_test_script("scripts/test_hook.sh", hook_path, test_payload)

    performance = check_performance(hook_path)
    if not performance.acceptable:
        optimize_performance(hook_path, load_best_practices())

    deploy_hook(hook_path, chmod="+x")
    setup_production_monitoring(hook_path)

    return {
        "status": "complete",
        "hook_type": selected_type,
        "hook_path": hook_path,
        "validation": "passed",
        "tests": "passed",
        "performance": "optimized"
    }

HOOK_TYPES = {
    "PreCompact": "Before compaction (save context, backup)",
    "UserPromptSubmit": "User submits message (keyword triggers, validation)",
    "PreToolUse": "Before tool runs (validation, safety checks)",
    "PostToolUse": "After tool completes (auto-fix, formatting)",
    "PreMessageCreate": "Before AI responds (content filtering)",
    "PostMessageCreate": "After AI responds (logging, analytics)",
    "PreSessionStart": "Session starts (environment setup)",
    "PostSessionEnd": "Session ends (cleanup, archiving)"
}
```

---

## 3. 🛠️ WHEN TO USE

This skill provides comprehensive documentation and tooling for creating custom Claude Code hooks. Use this skill when you need to understand hook types, create custom automation, implement validation workflows, or test hooks before deployment.

### Navigation Guide

**This file (SKILL.md)**: Essential overview and rules for using this skill

**Core Sections**:
- [Section 1](CAPABILITIES OVERVIEW) - Understanding the 8 hook types and progressive disclosure model
- [Section 2](#2-references) - Resource tables, decision trees, and smart routing diagram
- [Section 3](#3-when-to-use) - Use cases and applicability guidance
- [Section 4](#4-how-to-use) - Hook creation workflow and quick start example
- [Section 5](#5-rules) - ALWAYS, NEVER, and ESCALATE IF rules
- [Section 6](#6-success-criteria) - Production-ready checklist
- [Section 7](#7-integration-points) - Integration examples, tool usage, external systems
- [Section 8](#8-quick-reference) - Code snippets, performance targets, comprehensive docs
- [Section 9](#9-quick-start) - Fast-path workflow for experienced users

**Reference Files** (detailed documentation):
- [hook_types.md](./references/hook_types.md) - All 8 types with payloads, capabilities, examples
- [hook_creation_guide.md](./references/hook_creation_guide.md) - Step-by-step process from planning to deployment
- [payload_structures.md](./references/payload_structures.md) - JSON schemas, extraction patterns, security notes
- [best_practices.md](./references/best_practices.md) - Performance, security, error handling patterns
- [testing_guide.md](./references/testing_guide.md) - Three-phase testing strategy with examples

**Assets** (templates and examples):
- [hook_template.sh](./assets/hook_template.sh) - Base template for new hooks
- [precompact_example.sh](./assets/precompact_example.sh) - Context preservation pattern
- [userpromptssubmit_example.sh](./assets/userpromptssubmit_example.sh) - Keyword detection pattern
- [pretooluse_example.sh](./assets/pretooluse_example.sh) - Validation and blocking pattern
- [posttooluse_example.sh](./assets/posttooluse_example.sh) - Auto-fix and formatting pattern
- [hook_asset_template.md](./assets/hook_asset_template.md) - Template for documenting new hook examples
- [hook_reference_template.md](./assets/hook_reference_template.md) - Template for creating new references

**Scripts** (automation):
- [validate_hook.sh](./scripts/validate_hook.sh) - Static analysis and compatibility validation
- [test_hook.sh](./scripts/test_hook.sh) - Dynamic testing with payloads and performance measurement

### When to Use This Skill

- Creating custom hooks for workflow automation
- Understanding hook types and their capabilities
- Learning payload structures and exit code conventions
- Implementing security and performance best practices
- Testing hooks before production deployment
- Troubleshooting existing hook implementations

### When NOT to Use This Skill

- Simple bash scripting without Claude Code integration (use Bash tool directly)
- Git commit hooks (use git-specific documentation)
- General automation outside Claude Code context
- Quick one-off scripts (hooks are for repeated automation)

---

## 4. 📖 HOW TO USE

### Hook Creation Workflow

1. **Select Hook Type** → Use Section 2 (Hook Type Decision Tree) or read `references/hook_types.md`
2. **Load Template** → Copy `assets/hook_template.sh` as starting point
3. **Implement Logic** → Follow payload structure from `references/payload_structures.md`
4. **Validate Syntax** → Run `scripts/validate_hook.sh your-hook.sh`
5. **Test Locally** → Run `scripts/test_hook.sh your-hook.sh test-payload.json`
6. **Deploy** → Move to `.claude/hooks/{HookType}/your-hook.sh`

### Quick Start Example

```bash
# 1. Copy template
cp .claude/skills/create-hooks/assets/hook_template.sh \
   .claude/hooks/PreCompact/my-backup-hook.sh

# 2. Edit with your logic
# [Implement your hook logic]

# 3. Make executable
chmod +x .claude/hooks/PreCompact/my-backup-hook.sh

# 4. Validate
.claude/skills/create-hooks/scripts/validate_hook.sh \
  .claude/hooks/PreCompact/my-backup-hook.sh

# 5. Test with sample payload
echo '{"trigger":"manual","session_id":"test","cwd":"'$PWD'"}' > test.json
.claude/skills/create-hooks/scripts/test_hook.sh \
  .claude/hooks/PreCompact/my-backup-hook.sh test.json

# 6. Ready for production!
```

## 5. ⚙️ RULES

### ✅ ALWAYS 

- Read `references/hook_types.md` first to understand capabilities and limitations
- Use bash 3.2+ compatible syntax (macOS compatibility - no associative arrays, mapfile, readarray)
- Follow exit code convention: 0=allow/success, 1=block/warning, 2=error
- Validate hooks with `scripts/validate_hook.sh` before deployment
- Test hooks with `scripts/test_hook.sh` using sample payloads
- Include file header with version, purpose, performance target, and exit codes
- Source shared libraries: `lib/output-helpers.sh` and `lib/exit-codes.sh`
- Implement input sanitization for security (sanitize session IDs, validate paths)
- Add performance timing and logging
- Handle errors gracefully with descriptive messages

### ❌ NEVER 

- Use bash 4+ features (declare -A, mapfile, readarray) - breaks macOS compatibility
- Block PreCompact hooks with exit code 1/2 (compaction cannot be prevented)
- Skip input sanitization (security vulnerability)
- Use eval with user-controlled input (command injection risk)
- Deploy without validation and testing
- Forget to make hook executable (chmod +x)
- Use unquoted variables in commands
- Hardcode paths (use environment variables and discovery)

### ⚠️ ESCALATE IF

- Unsure which hook type to use (multiple seem applicable)
- Complex logic requiring coordination between multiple hook types
- Performance requirements unclear or conflicting
- Security validation needed for sensitive operations
- Hook needs to modify Claude Code's internal state
- Integration with external systems unclear

## 6. ✅ SUCCESS CRITERIA

Hook is production-ready when:

- ✅ Hook type correctly selected for the use case
- ✅ Template properly adapted with required components
- ✅ Validation passes (`scripts/validate_hook.sh` returns 0)
- ✅ All test scenarios pass (valid, missing fields, malicious input)
- ✅ Performance within target (<50ms for PreToolUse, <5s for PreCompact, etc.)
- ✅ Security patterns implemented (sanitization, path validation)
- ✅ Error handling comprehensive with graceful degradation
- ✅ Documentation complete (file header, inline comments)
- ✅ Logging implemented (operations and performance)
- ✅ Tested in production-like environment

## 7. 🔗 INTEGRATION POINTS

### 7.1 Integration Examples

#### Example 1: PreCompact Hook (Context Preservation)

**Use Case**: Automatically save conversation context before compaction

**Implementation**: See `assets/precompact_example.sh` (working production hook)

**Key Patterns**:
- Parse JSON payload for trigger type, session ID, working directory
- Locate transcript file using project slug conversion
- Transform JSONL → JSON using `lib/transform-transcript.js`
- Call workflows-save-context skill with AUTO_SAVE_MODE
- Always exit 0 (PreCompact cannot block)

**Integration**: Uses `workflows-save-context` skill, `lib/transform-transcript.js`

### Example 2: UserPromptSubmit Hook (Keyword Detection)

**Use Case**: Auto-trigger save-context when user says "save context"

**Implementation**: See `assets/userpromptssubmit_example.sh`

**Key Patterns**:
- Extract prompt text from payload
- Convert to lowercase for case-insensitive matching
- Use grep with word boundaries to match keywords
- Exit 0 to allow (silent skip) or trigger skill activation

**Integration**: Triggers `workflows-save-context` skill when keywords detected

### Example 3: PreToolUse Hook (Validation)

**Use Case**: Validate bash commands before execution

**Implementation**: See `assets/pretooluse_example.sh`

**Key Patterns**:
- Extract tool name and arguments from payload
- Run validation checks (syntax, security patterns)
- Exit 0 to allow or exit 1 to block with warning
- Display clear error message explaining block reason

**Integration**: Blocks tool execution when validation fails

### Example 4: PostToolUse Hook (Auto-Fix)

**Use Case**: Automatically fix markdown formatting after file edits

**Implementation**: See `assets/posttooluse_example.sh`

**Key Patterns**:
- Extract tool result and affected files
- Run formatting/linting tools
- Apply fixes automatically
- Log all changes for transparency
- Exit 0 (cannot block, already executed)

**Integration**: Uses external formatters (prettier, markdownlint)

### 7.2 Tool Usage Guidelines

**When to Use Each Tool**:

- **Read Tool**: Load reference documentation from `references/` for detailed specifications
- **Grep Tool**: Search for patterns in existing hooks (e.g., find all PreCompact hooks)
- **Bash Tool**: Execute validation (`scripts/validate_hook.sh`) and testing (`scripts/test_hook.sh`)
- **Edit Tool**: Modify hook templates and existing hook implementations

**Progressive Loading Strategy**:

1. **Start with SKILL.md Section 2** → Identify hook type and required resources
2. **Load specific reference** → `references/hook_types.md` for selected hook type
3. **Copy template** → `assets/hook_template.sh` as starting point
4. **Load payload guide** → `references/payload_structures.md` for JSON parsing
5. **Load best practices** → `references/best_practices.md` for security and performance
6. **Load testing guide** → `references/testing_guide.md` before validation

**Cross-References**:
- Section 2 (REFERENCES) → Complete resource tables and smart routing diagram
- Section 5 (RULES) → Bash 3.2 compatibility requirements and security patterns
- Section 8 (QUICK REFERENCE) → Code snippets and performance targets

### 7.3 External Systems Integration

**Claude Code Skill Integration**:
- **workflows-save-context**: Called by PreCompact hooks for context preservation
- **create-documentation**: Referenced for documenting custom hook implementations
- **workflows-conversation**: Used for spec folder creation during hook development

**System Dependencies**:
- **jq** (JSON processor): Required for all hooks parsing JSON payloads
- **node** (JavaScript runtime): Required for transform scripts (`lib/transform-transcript.js`)
- **git**: Required for repository-aware hooks (commit history, branch detection)
- **realpath** (GNU coreutils): Required for path validation and security checks

**External Tool Integration**:
- **Formatters**: prettier, markdownlint (PostToolUse auto-fix patterns)
- **Linters**: shellcheck, yamllint (PreToolUse validation patterns)
- **Security scanners**: Custom validators for command injection prevention

### 7.4 Troubleshooting

#### Common Issues

**Issue: Hook not triggering**
- Check hook is in correct directory: `.claude/hooks/{HookType}/`
- Verify executable permission: `chmod +x hook.sh`
- Check hook name doesn't conflict with others
- Review Claude Code logs for errors

**Issue: Validation fails with bash 4+ features**
- Replace `declare -A` with indexed arrays or jq
- Replace `mapfile` with `while read` loops
- Replace `readarray` with manual array building
- Test on macOS or bash 3.2 environment

**Issue: Hook blocks when it shouldn't**
- PreCompact hooks: Always exit 0 (cannot block)
- PostToolUse hooks: Always exit 0 (tool already ran)
- Check exit code logic matches hook type capabilities

**Issue: Performance too slow**
- Profile with `time` command to find bottlenecks
- Implement caching for expensive operations
- Use early exits to skip unnecessary work
- Consider async execution for non-critical tasks

**Issue: Security concerns with user input**
- Sanitize session IDs: `tr -cd 'a-zA-Z0-9_-'`
- Validate paths: `realpath "$PATH"` and check exists
- Never use `eval` with user input
- Quote all variables in commands

### 7.5 Shared Libraries

**Hook Infrastructure Libraries** (`.claude/hooks/lib/`):

- **output-helpers.sh**: Formatting and logging functions
  - `log_info()`, `log_warn()`, `log_error()` - Standardized logging with timestamps
  - `format_duration()` - Convert milliseconds to human-readable format
  - `check_dependency()` - Validate required tool availability with install hints

- **exit-codes.sh**: Exit code constants for consistent behavior
  - `EXIT_ALLOW=0` - Allow execution / success
  - `EXIT_BLOCK=1` - Block execution / warning (only for hooks that can block)
  - `EXIT_ERROR=2` - Error condition (blocks if hook can block)

- **transform-transcript.js**: JSONL → JSON conversion for PreCompact hooks
  - Converts Claude Code conversation transcripts to structured JSON
  - Enables context analysis and preservation workflows
  - Usage: `node lib/transform-transcript.js < transcript.jsonl > transcript.json`

**Import Pattern**:
```bash
#!/bin/bash
# Standard library imports for hooks
HOOKS_DIR="${CLAUDE_HOOKS_DIR:-.claude/hooks}"
source "$HOOKS_DIR/lib/exit-codes.sh"
source "$HOOKS_DIR/lib/output-helpers.sh"
```

---

## 8. ⚡ QUICK REFERENCE

### Exit Code Convention

```bash
# Source exit code constants
source "$HOOKS_DIR/lib/exit-codes.sh"

# Use in your hook
exit $EXIT_ALLOW   # 0: Allow execution
exit $EXIT_BLOCK   # 1: Block/warn (only if hook can block)
exit $EXIT_ERROR   # 2: Error (blocks if hook can block)
```

### JSON Payload Parsing

```bash
# Read JSON from stdin
INPUT=$(cat)

# Extract fields with fallbacks
FIELD=$(echo "$INPUT" | jq -r '.field // "default"' 2>/dev/null)

# Security: Sanitize
SAFE_FIELD=$(echo "$FIELD" | tr -cd 'a-zA-Z0-9_-')
```

### Performance Timing

```bash
START_TIME=$(date +%s%N)

# ... your hook logic ...

END_TIME=$(date +%s%N)
DURATION=$(( (END_TIME - START_TIME) / 1000000 ))
log_performance "hook-name" "$DURATION"
```

### Dependency Checks

```bash
if ! check_dependency "jq" "brew install jq"; then
  echo "⚠️  jq required but not found" >&2
  exit 0  # Graceful degradation
fi
```

### Input Sanitization Cheat Sheet

```bash
# Session ID (alphanumeric + dash/underscore only)
SESSION_ID=$(echo "$SESSION_ID" | tr -cd 'a-zA-Z0-9_-')

# Path validation
SAFE_PATH=$(realpath "$USER_PATH" 2>/dev/null)
[ ! -d "$SAFE_PATH" ] && exit 1

# String sanitization (remove shell metacharacters)
SAFE_STRING=$(echo "$STRING" | tr -cd '[:alnum:][:space:]._-')
```

### Performance Targets by Hook Type

| Hook Type | Target | Why |
|-----------|--------|-----|
| PreToolUse | <50ms | Blocks tool execution - must be fast |
| UserPromptSubmit | <200ms | Blocks prompt processing - impacts UX |
| PostToolUse | <200ms | Non-blocking but visible delay |
| PreCompact | <5s | User waiting but compaction important |
| Others | <500ms | Balance between function and UX |

### 8.1 Comprehensive Documentation

For detailed information, read the bundled references:

1. **Hook Types**: `references/hook_types.md` - All 8 types with payloads, capabilities, examples
2. **Creation Guide**: `references/hook_creation_guide.md` - Step-by-step process from planning to deployment
3. **Payloads**: `references/payload_structures.md` - JSON schemas, extraction patterns, security notes
4. **Best Practices**: `references/best_practices.md` - Performance, security, error handling patterns
5. **Testing**: `references/testing_guide.md` - Three-phase testing strategy with examples

### 8.2 Working Examples

Study these production-ready examples in `assets/`:

1. **hook_template.sh**: Base template with all required sections
2. **precompact_example.sh**: Full PreCompact hook (context saving)
3. **userpromptssubmit_example.sh**: Keyword detection pattern
4. **pretooluse_example.sh**: Validation with blocking
5. **posttooluse_example.sh**: Auto-fix pattern

### 8.3 Testing Tools

Use these scripts for validation and testing:

1. **scripts/validate_hook.sh**: Static analysis (syntax, permissions, compatibility, security)
2. **scripts/test_hook.sh**: Execute with test payloads, measure performance, verify exit codes

---

## 9. ⚡ QUICK START

Ready to create your first hook? Follow these steps:

1. Read `references/hook_types.md` to understand the 8 hook types
2. Choose the appropriate hook type for your use case
3. Copy `assets/hook_template.sh` as your starting point
4. Follow `references/hook_creation_guide.md` for step-by-step instructions
5. Validate with `scripts/validate_hook.sh`
6. Test with `scripts/test_hook.sh`
7. Deploy to `.claude/hooks/{HookType}/`

For questions or complex scenarios, escalate using the guidelines in Section 5 (RULES → ESCALATE IF).

---

**Remember**: This skill operates across three lifecycle phases - Pre-Execution, Post-Execution, and Progressive Disclosure. All integrate to provide reliable, event-driven automation.