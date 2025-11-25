# Hook Types Reference - Claude Code Hooks

Complete documentation of all 8 Claude Code hook types with payloads, capabilities, use cases, and implementation patterns. This reference serves as the authoritative guide for understanding trigger points, blocking capabilities, and performance targets for each hook type in the system.

---

## 1. 📋 OVERVIEW

Claude Code provides 8 hook types that fire at different points in the execution lifecycle. Each hook type receives a JSON payload via stdin and can optionally block execution (depending on hook type capabilities).

### Hook Types Summary

| Hook Type | Trigger Point | Can Block? | Performance Target | Common Use Cases |
|-----------|---------------|------------|-------------------|------------------|
| PreCompact | Before compaction | No | <5s | Context preservation, backup |
| UserPromptSubmit | User message submitted | Yes | <200ms | Keyword triggers, validation |
| PreToolUse | Before tool execution | Yes | <50ms | Safety checks, validation |
| PostToolUse | After tool execution | No | <200ms | Auto-fix, formatting |
| PreMessageCreate | Before AI response | Yes | <100ms | Content filtering |
| PostMessageCreate | After AI response | No | <200ms | Analytics, logging |
| PreSessionStart | Session initialization | Yes | <1s | Environment setup |
| PostSessionEnd | Session termination | No | <1s | Cleanup, archiving |

### Exit Code Convention

All hooks follow this exit code pattern:

- **0 (EXIT_ALLOW)**: Allow execution to proceed / Success
- **1 (EXIT_BLOCK)**: Block execution with warning (only effective if hook can block)
- **2 (EXIT_ERROR)**: Critical error, block execution (only effective if hook can block)

---

## 2. 💾 PRECOMPACT HOOK

### Trigger Point

Fires immediately before context compaction occurs, triggered by:
- Manual compaction: User runs `/compact` command
- Automatic compaction: Context reaches ~75% threshold

### Payload Structure

```json
{
  "trigger": "manual|auto",
  "custom_instructions": "string (optional, only for manual)",
  "session_id": "string",
  "cwd": "string"
}
```

### Field Descriptions

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| **`trigger`** | string | Yes | "manual" (user-initiated) or "auto" (threshold) |
| **`custom_instructions`** | string | No | User-provided instructions (manual compact only) |
| **`session_id`** | string | Yes | Unique session identifier |
| **`cwd`** | string | Yes | Current working directory |

### Capabilities

**Cannot Block Compaction**: Exit code is logged but does not prevent compaction. PreCompact hooks cannot block the compaction process - this is by design to prevent hooks from leaving Claude Code in an unusable state.

**Access to Full Transcript**: The session_id can be used to locate and read the full conversation transcript before it's compacted.

**Synchronous Execution**: Hook runs synchronously before compaction begins, ensuring completion before context loss.

### Common Use Cases

1. **Context Preservation**: Save conversation context to spec folder before compaction
2. **Transcript Backup**: Copy transcript to external storage
3. **Summary Generation**: Generate and save conversation summary
4. **Handoff Documentation**: Create documentation for team handoff
5. **Analytics**: Extract and log conversation metrics

### Performance Target

**<5 seconds** - Users are waiting for compaction to complete, but context preservation is more important than speed. If hook takes longer, compaction still proceeds.

### Example Payload (Manual Compact)

```json
{
  "trigger": "manual",
  "custom_instructions": "Save context before long research session",
  "session_id": "f3b2a1c9d8e7f6",
  "cwd": "/Users/alice/projects/myapp"
}
```

### Example Payload (Auto Compact)

```json
{
  "trigger": "auto",
  "session_id": "a1b2c3d4e5f6g7",
  "cwd": "/Users/bob/code/webapp"
}
```

### Implementation Pattern

```bash
#!/bin/bash

# Parse payload
INPUT=$(cat)
TRIGGER=$(echo "$INPUT" | jq -r '.trigger // "auto"')
SESSION_ID=$(echo "$INPUT" | jq -r '.session_id // empty')
CWD=$(echo "$INPUT" | jq -r '.cwd // empty')

# Validate required fields
if [ -z "$SESSION_ID" ] || [ -z "$CWD" ]; then
  echo "⚠️  Missing required fields, skipping save" >&2
  exit 0  # Allow compaction anyway
fi

# Display notification
if [ "$TRIGGER" = "manual" ]; then
  echo "💾 Saving context before compaction (manual trigger)..."
else
  echo "💾 Saving context before compaction (auto threshold)..."
fi

# Perform context save operation
# [your logic here]

# Always allow compaction (PreCompact cannot block)
exit 0
```

### Best Practices

- **Always exit 0**: PreCompact cannot block, so always return success
- **Graceful degradation**: If dependencies missing, warn and exit 0
- **Fast execution**: Target <5s but prioritize data integrity
- **Comprehensive logging**: Log all operations for debugging
- **Error resilience**: Handle all errors gracefully, never crash

### Real-World Example

See `assets/precompact_example.sh` for complete working implementation that:
- Locates transcript using project slug conversion
- Transforms JSONL → JSON
- Calls workflows-save-context skill
- Handles sub-folder versioning
- Logs all operations

---

## 3. 🎯 USERPROMPTSSUBMIT HOOK

### Trigger Point

Fires when user submits a message, before Claude Code processes it.

### Payload Structure

```json
{
  "prompt": "string",
  "session_id": "string",
  "cwd": "string",
  "message_count": number
}
```

### Field Descriptions

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| **`prompt`** | string | Yes | The user's actual message text |
| **`session_id`** | string | Yes | Unique session identifier |
| **`cwd`** | string | Yes | Current working directory |
| **`message_count`** | number | Yes | Total messages in conversation |

### Capabilities

**Can Block**: Exit code 1 or 2 blocks prompt processing and displays warning to user.

**Text Analysis**: Full access to user's message for keyword detection, pattern matching, validation.

**Conditional Triggering**: Can selectively trigger based on message content, count, or patterns.

### Common Use Cases

1. **Keyword Detection**: Auto-trigger skills when user says "save context", "create hook", etc.
2. **Auto-Documentation**: Detect when spec folder needed and prompt user
3. **Message Threshold**: Trigger actions at message milestones (every 20 messages, etc.)
4. **Validation**: Block messages that violate policies or contain problematic patterns
5. **Analytics**: Log message patterns and user behavior

### Performance Target

**<200ms** - Hook blocks prompt processing, so must be fast to maintain responsive UX.

### Example Payload

```json
{
  "prompt": "save context before I lose this work",
  "session_id": "abc123def456",
  "cwd": "/Users/charlie/project",
  "message_count": 42
}
```

### Implementation Pattern (Keyword Detection)

```bash
#!/bin/bash

INPUT=$(cat)
PROMPT=$(echo "$INPUT" | jq -r '.prompt // empty')

# Convert to lowercase for case-insensitive matching
PROMPT_LOWER=$(echo "$PROMPT" | tr '[:upper:]' '[:lower:]')

# Define keywords to detect
KEYWORDS=("save context" "save conversation" "document this")

# Check for keyword matches
for keyword in "${KEYWORDS[@]}"; do
  if echo "$PROMPT_LOWER" | grep -qF "$keyword"; then
    echo "🎯 Detected keyword: '$keyword' - triggering workflows-save-context"
    # Skill activation happens automatically
    exit 0
  fi
done

# No keywords detected, allow silently
exit 0
```

### Implementation Pattern (Message Threshold)

```bash
#!/bin/bash

INPUT=$(cat)
MESSAGE_COUNT=$(echo "$INPUT" | jq -r '.message_count // 0')

# Trigger every 20 messages
if [ $((MESSAGE_COUNT % 20)) -eq 0 ] && [ "$MESSAGE_COUNT" -gt 0 ]; then
  echo "📊 Reached $MESSAGE_COUNT messages - auto-saving context"
  # Trigger save-context workflow
  exit 0
fi

# Not at threshold, allow silently
exit 0
```

### Best Practices

- **Fast execution**: Target <200ms - users waiting for response
- **Early exit**: Skip hook if not applicable (keyword not found, etc.)
- **Case-insensitive matching**: Use `tr '[:upper:]' '[:lower:]'` for keywords
- **Word boundaries**: Use `grep -E "\\b$keyword\\b"` to avoid partial matches
- **Silent skip**: Exit 0 without output if hook doesn't apply
- **Clear messages**: If triggering action, explain why to user

### Real-World Example

See `assets/userpromptssubmit_example.sh` for working implementation that detects "save context" keywords and triggers workflows-save-context skill.

---

## 4. 🛡️ PRETOOLUSE HOOK

### Trigger Point

Fires before Claude Code executes any tool (Read, Write, Edit, Bash, etc.).

### Payload Structure

```json
{
  "tool_name": "string",
  "tool_input": object,
  "session_id": "string",
  "cwd": "string"
}
```

### Field Descriptions

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| **`tool_name`** | string | Yes | Name of tool about to execute (e.g., "Bash", "Edit") |
| **`tool_input`** | object | Yes | Tool parameters (structure varies by tool) |
| **`session_id`** | string | Yes | Unique session identifier |
| **`cwd`** | string | Yes | Current working directory |

### Capabilities

**Can Block**: Exit code 1 or 2 prevents tool execution and shows warning to user.

**Safety Validation**: Validate tool parameters before execution to prevent dangerous operations.

**Command Inspection**: For Bash tool, inspect command before execution.

### Common Use Cases

1. **Safety Checks**: Block dangerous bash commands (rm -rf /, etc.)
2. **Syntax Validation**: Validate bash scripts before execution
3. **Permission Checks**: Ensure user has permission for operation
4. **Policy Enforcement**: Block operations that violate project policies
5. **Audit Logging**: Log all tool usage for security/compliance

### Performance Target

**<50ms** - Hook blocks tool execution, must be extremely fast to avoid disrupting workflow.

### Example Payload (Bash Tool)

```json
{
  "tool_name": "Bash",
  "tool_input": {
    "command": "rm -rf /tmp/cache",
    "description": "Clear temporary cache"
  },
  "session_id": "xyz789",
  "cwd": "/Users/dave/app"
}
```

### Example Payload (Edit Tool)

```json
{
  "tool_name": "Edit",
  "tool_input": {
    "file_path": "/Users/dave/app/config.json",
    "old_string": "\"debug\": false",
    "new_string": "\"debug\": true"
  },
  "session_id": "xyz789",
  "cwd": "/Users/dave/app"
}
```

### Implementation Pattern (Bash Validation)

```bash
#!/bin/bash

INPUT=$(cat)
TOOL_NAME=$(echo "$INPUT" | jq -r '.tool_name // empty')

# Only validate Bash tool
if [ "$TOOL_NAME" != "Bash" ]; then
  exit 0  # Allow other tools
fi

# Extract bash command
COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // empty')

# Dangerous patterns to block
DANGEROUS_PATTERNS=(
  "rm -rf /"
  "rm -rf /*"
  "dd if=/dev/zero"
  "mkfs\."
  ":(){:|:&};:"  # Fork bomb
)

# Check for dangerous patterns
for pattern in "${DANGEROUS_PATTERNS[@]}"; do
  if echo "$COMMAND" | grep -qF "$pattern"; then
    echo "🚫 BLOCKED: Dangerous command detected" >&2
    echo "   Pattern: $pattern" >&2
    echo "   Command: $COMMAND" >&2
    exit 1  # Block execution
  fi
done

# Validate bash syntax
if ! echo "$COMMAND" | bash -n 2>/dev/null; then
  echo "⚠️  WARNING: Bash syntax error detected" >&2
  echo "   Command may fail: $COMMAND" >&2
  # Allow anyway (just a warning)
fi

# Allow execution
exit 0
```

### Best Practices

- **Extremely fast**: <50ms target - users notice any delay
- **Selective validation**: Only validate when necessary (tool type match)
- **Clear blocking reasons**: Explain exactly why command was blocked
- **Allow by default**: Only block genuinely dangerous operations
- **Non-intrusive warnings**: Warn for suspicious patterns without blocking
- **Pattern matching**: Use grep/regex for efficient pattern detection

### Real-World Example

See `assets/pretooluse_example.sh` for working validation hook that blocks dangerous bash commands.

---

## 5. ✨ POSTTOOLUSE HOOK

### Trigger Point

Fires after Claude Code completes tool execution, with access to tool results.

### Payload Structure

```json
{
  "tool_name": "string",
  "tool_input": object,
  "tool_output": string,
  "exit_code": number,
  "session_id": "string",
  "cwd": "string"
}
```

### Field Descriptions

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| **`tool_name`** | string | Yes | Name of tool that executed |
| **`tool_input`** | object | Yes | Tool parameters used |
| **`tool_output`** | string | Yes | Tool execution output |
| **`exit_code`** | number | Yes | Tool exit code (0 = success) |
| **`session_id`** | string | Yes | Unique session identifier |
| **`cwd`** | string | Yes | Current working directory |

### Capabilities

**Cannot Block**: Tool already executed, so exit code only affects hook success logging.

**Result Analysis**: Full access to tool output for parsing, validation, logging.

**Auto-Fix**: Can automatically fix issues detected in tool output.

### Common Use Cases

1. **Auto-Formatting**: Format code after Write/Edit operations
2. **Linting**: Run linters after file modifications
3. **Style Enforcement**: Fix markdown/code style issues
4. **Test Execution**: Auto-run tests after code changes
5. **Logging**: Record tool usage and results for analytics

### Performance Target

**<200ms** - Non-blocking but visible delay in UX. Users notice slow post-processing.

### Example Payload

```json
{
  "tool_name": "Write",
  "tool_input": {
    "file_path": "/Users/eve/app/README.md",
    "content": "# My App\nThis is my app"
  },
  "tool_output": "File written successfully",
  "exit_code": 0,
  "session_id": "pqr456",
  "cwd": "/Users/eve/app"
}
```

### Implementation Pattern (Auto-Formatting)

```bash
#!/bin/bash

INPUT=$(cat)
TOOL_NAME=$(echo "$INPUT" | jq -r '.tool_name // empty')
EXIT_CODE=$(echo "$INPUT" | jq -r '.exit_code // 1')

# Only process successful Write/Edit operations
if [ "$EXIT_CODE" -ne 0 ]; then
  exit 0  # Tool failed, skip post-processing
fi

if [ "$TOOL_NAME" != "Write" ] && [ "$TOOL_NAME" != "Edit" ]; then
  exit 0  # Not a file modification
fi

# Extract file path
FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty')

# Only format markdown files
if [[ "$FILE_PATH" != *.md ]]; then
  exit 0
fi

# Check if prettier is available
if ! command -v prettier &>/dev/null; then
  exit 0  # No formatter, skip
fi

# Format the file
if prettier --write "$FILE_PATH" 2>/dev/null; then
  echo "✨ Auto-formatted: $(basename "$FILE_PATH")"
fi

exit 0
```

### Best Practices

- **Check exit code first**: Skip processing if tool failed
- **Selective processing**: Only process relevant tool types
- **Dependency checks**: Gracefully skip if tools unavailable
- **Idempotent operations**: Safe to run multiple times
- **Silent success**: Only output if action taken
- **Error handling**: Never crash, always exit 0
- **File type filtering**: Only process applicable files

### Real-World Example

See `assets/posttooluse_example.sh` for working auto-format hook that fixes markdown after edits.

---

## 6. 🔒 PREMESSAGECREATE HOOK

### Trigger Point

Fires before Claude Code generates a response to user, after internal processing.

### Payload Structure

```json
{
  "prompt": "string",
  "context": "string",
  "session_id": "string",
  "cwd": "string"
}
```

### Field Descriptions

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| **`prompt`** | string | Yes | User's message (same as UserPromptSubmit) |
| **`context`** | string | Yes | Internal context being sent to AI |
| **`session_id`** | string | Yes | Unique session identifier |
| **`cwd`** | string | Yes | Current working directory |

### Capabilities

**Can Block**: Exit code 1 or 2 prevents AI response generation.

**Context Inspection**: Read internal context before sending to AI model.

**Content Filtering**: Block responses based on context analysis.

### Common Use Cases

1. **Content Filtering**: Block responses containing sensitive information
2. **Policy Enforcement**: Ensure compliance with content policies
3. **Context Validation**: Verify context doesn't contain leaked secrets
4. **Rate Limiting**: Prevent excessive API usage
5. **Analytics**: Log context patterns for optimization

### Performance Target

**<100ms** - Blocks AI response, must be very fast to maintain conversation flow.

### Example Payload

```json
{
  "prompt": "Show me the API keys in config.json",
  "context": "[internal context with file contents]",
  "session_id": "lmn123",
  "cwd": "/Users/frank/app"
}
```

### Implementation Pattern (Secret Detection)

```bash
#!/bin/bash

INPUT=$(cat)
CONTEXT=$(echo "$INPUT" | jq -r '.context // empty')

# Patterns that might indicate secrets
SECRET_PATTERNS=(
  "api[_-]?key"
  "password"
  "secret"
  "token"
  "auth[_-]?key"
)

# Check for potential secrets in context
for pattern in "${SECRET_PATTERNS[@]}"; do
  if echo "$CONTEXT" | grep -qiE "$pattern"; then
    echo "⚠️  WARNING: Potential secret detected in context" >&2
    echo "   Pattern: $pattern" >&2
    # Could block here with exit 1, but we'll just warn
  fi
done

exit 0  # Allow response
```

### Best Practices

- **Very fast**: <100ms critical - interrupts conversation
- **Conservative blocking**: Only block truly problematic content
- **Privacy focused**: Protect sensitive user data
- **Minimal inspection**: Don't parse entire context deeply
- **Clear warnings**: Explain why content was blocked
- **Logging**: Record blocks for policy refinement

---

## 7. 📝 POSTMESSAGECREATE HOOK

### Trigger Point

Fires after Claude Code generates a response, before displaying to user.

### Payload Structure

```json
{
  "prompt": "string",
  "response": "string",
  "session_id": "string",
  "cwd": "string"
}
```

### Field Descriptions

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| **`prompt`** | string | Yes | User's original message |
| **`response`** | string | Yes | AI-generated response text |
| **`session_id`** | string | Yes | Unique session identifier |
| **`cwd`** | string | Yes | Current working directory |

### Capabilities

**Cannot Block**: Response already generated, cannot prevent display.

**Response Analysis**: Full access to AI response for logging, analytics.

**Post-Processing**: Can extract data from response for storage.

### Common Use Cases

1. **Analytics**: Log response patterns and metrics
2. **Archiving**: Save important responses to external storage
3. **Extraction**: Pull out key decisions or code snippets
4. **Notification**: Alert team about significant responses
5. **Quality Monitoring**: Detect response quality issues

### Performance Target

**<200ms** - Non-blocking but delays response display to user.

### Example Payload

```json
{
  "prompt": "Explain PreCompact hooks",
  "response": "PreCompact hooks fire before...",
  "session_id": "stu789",
  "cwd": "/Users/grace/docs"
}
```

### Implementation Pattern (Response Logging)

```bash
#!/bin/bash

INPUT=$(cat)
RESPONSE=$(echo "$INPUT" | jq -r '.response // empty')
SESSION_ID=$(echo "$INPUT" | jq -r '.session_id // empty')

# Log response length and timestamp
LOG_FILE=".claude/hooks/logs/responses.log"
TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')
RESPONSE_LENGTH=$(echo "$RESPONSE" | wc -c)

echo "[$TIMESTAMP] Session: $SESSION_ID | Length: $RESPONSE_LENGTH bytes" >> "$LOG_FILE"

exit 0
```

### Best Practices

- **Async when possible**: Don't delay response display
- **Minimal processing**: Extract only what's needed
- **Efficient logging**: Use append operations
- **Privacy aware**: Don't log sensitive content
- **Silent operation**: No output to user
- **Error resilient**: Never crash, always exit 0

---

## 8. 🚀 PRESESSIONSTART HOOK

### Trigger Point

Fires when Claude Code session initializes, before first user interaction.

### Payload Structure

```json
{
  "session_id": "string",
  "cwd": "string",
  "config": object
}
```

### Field Descriptions

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| **`session_id`** | string | Yes | New session identifier |
| **`cwd`** | string | Yes | Working directory for session |
| **`config`** | object | Yes | Session configuration |

### Capabilities

**Can Block**: Exit code 1 or 2 prevents session from starting.

**Environment Setup**: Initialize environment before session begins.

**Validation**: Check prerequisites and requirements.

### Common Use Cases

1. **Environment Validation**: Check required tools installed
2. **Git Status**: Verify clean working tree
3. **Dependency Checks**: Ensure project dependencies available
4. **Workspace Setup**: Initialize directories or files
5. **Session Configuration**: Load project-specific settings

### Performance Target

**<1 second** - Session start delay acceptable but should be quick.

### Example Payload

```json
{
  "session_id": "vwx012",
  "cwd": "/Users/henry/project",
  "config": {
    "model": "claude-sonnet-4-5",
    "project_name": "my-app"
  }
}
```

### Implementation Pattern (Dependency Check)

```bash
#!/bin/bash

INPUT=$(cat)
CWD=$(echo "$INPUT" | jq -r '.cwd // empty')

cd "$CWD" || exit 0

# Check for required tools
REQUIRED_TOOLS=("git" "node" "npm")
MISSING_TOOLS=()

for tool in "${REQUIRED_TOOLS[@]}"; do
  if ! command -v "$tool" &>/dev/null; then
    MISSING_TOOLS+=("$tool")
  fi
done

if [ ${#MISSING_TOOLS[@]} -gt 0 ]; then
  echo "⚠️  WARNING: Missing required tools: ${MISSING_TOOLS[*]}" >&2
  echo "   Session will start but some features may not work" >&2
fi

exit 0  # Allow session start
```

### Best Practices

- **Fast initialization**: <1s target
- **Conservative blocking**: Only block for critical issues
- **Clear error messages**: Explain setup problems
- **Graceful degradation**: Warn for non-critical issues
- **Idempotent setup**: Safe to run multiple times
- **Minimal side effects**: Don't modify workspace unnecessarily

---

## 9. 🧹 POSTSESSIONEND HOOK

### Trigger Point

Fires when Claude Code session terminates, after all user interaction complete.

### Payload Structure

```json
{
  "session_id": "string",
  "cwd": "string",
  "duration_ms": number,
  "message_count": number
}
```

### Field Descriptions

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| **`session_id`** | string | Yes | Session that ended |
| **`cwd`** | string | Yes | Working directory of session |
| **`duration_ms`** | number | Yes | Session duration in milliseconds |
| **`message_count`** | number | Yes | Total messages in session |

### Capabilities

**Cannot Block**: Session already ended, cannot prevent termination.

**Cleanup Operations**: Clean up temporary files, close connections.

**Final Logging**: Record session statistics and outcomes.

### Common Use Cases

1. **Cleanup**: Remove temporary files and caches
2. **Analytics**: Log session statistics
3. **Archiving**: Save session data to external storage
4. **Notifications**: Alert team about session completion
5. **State Reset**: Clean up session-specific state

### Performance Target

**<1 second** - Non-blocking but user may wait for cleanup to complete.

### Example Payload

```json
{
  "session_id": "yza345",
  "cwd": "/Users/iris/workspace",
  "duration_ms": 3600000,
  "message_count": 87
}
```

### Implementation Pattern (Cleanup)

```bash
#!/bin/bash

INPUT=$(cat)
SESSION_ID=$(echo "$INPUT" | jq -r '.session_id // empty')
CWD=$(echo "$INPUT" | jq -r '.cwd // empty')

# Clean up session-specific temporary files
TEMP_DIR="/tmp/claude-session-$SESSION_ID"
if [ -d "$TEMP_DIR" ]; then
  rm -rf "$TEMP_DIR"
  echo "🧹 Cleaned up session temp directory"
fi

# Log session completion
LOG_FILE=".claude/hooks/logs/sessions.log"
TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')
DURATION=$(echo "$INPUT" | jq -r '.duration_ms // 0')
MESSAGE_COUNT=$(echo "$INPUT" | jq -r '.message_count // 0')

echo "[$TIMESTAMP] Session ended: $SESSION_ID | Duration: ${DURATION}ms | Messages: $MESSAGE_COUNT" >> "$LOG_FILE"

exit 0
```

### Best Practices

- **Quick cleanup**: <1s target for user experience
- **Safe operations**: Never delete important data
- **Thorough logging**: Record session metrics
- **Error handling**: Handle missing files gracefully
- **Silent operation**: Minimal output unless errors
- **Idempotent**: Safe if called multiple times

---

## 10. 🧭 HOOK SELECTION GUIDE

### Decision Matrix

Use this matrix to select the appropriate hook type:

| Scenario | Recommended Hook | Why |
|----------|------------------|-----|
| Save context before compaction | PreCompact | Fires before context loss |
| Auto-trigger on keywords | UserPromptSubmit | Detects user intent |
| Validate bash commands | PreToolUse | Blocks dangerous operations |
| Format code after edits | PostToolUse | Auto-fix after changes |
| Filter sensitive content | PreMessageCreate | Blocks before AI sees |
| Log all responses | PostMessageCreate | Analytics on outputs |
| Check dependencies | PreSessionStart | Validate environment |
| Clean up temp files | PostSessionEnd | Cleanup after session |

### When Multiple Hooks Apply

If multiple hook types could solve your use case:

1. **Prefer earlier hooks**: Block problems before they happen (PreToolUse vs PostToolUse)
2. **Prefer specific triggers**: More targeted hooks (PreCompact vs UserPromptSubmit)
3. **Consider blocking needs**: Can you block or only observe?
4. **Consider performance**: Earlier hooks often have stricter timing requirements

---

## 11. 📚 SUMMARY

All 8 hook types follow consistent patterns:
- JSON payload via stdin
- Exit codes 0/1/2 with standard meanings
- Performance targets based on blocking behavior
- Security-first design with input sanitization
- Graceful degradation for missing dependencies

For implementation details, see:
- `hook_creation_guide.md`: Step-by-step creation process
- `payload_structures.md`: Complete JSON schemas
- `best_practices.md`: Performance and security patterns
- `testing_guide.md`: Comprehensive testing strategies
