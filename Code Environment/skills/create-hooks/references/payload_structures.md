# Payload Structures Reference - Claude Code Hooks

Complete JSON payload documentation for all 8 Claude Code hook types with schemas, extraction patterns, and security guidelines. This reference provides detailed field descriptions, extraction examples, and security best practices for every hook payload structure.

---

## 1. 📋 OVERVIEW

Each hook receives JSON via stdin with hook-specific fields. This reference provides complete schemas with field descriptions, extraction patterns, and security considerations.

## General Patterns

### Common Fields

Most hooks include these standard fields:

```json
{
  "session_id": "string - Unique session identifier",
  "cwd": "string - Current working directory"
}
```

### Standard Extraction Pattern

```bash
# Read JSON from stdin
INPUT=$(cat)

# Extract common fields with fallbacks
SESSION_ID=$(echo "$INPUT" | jq -r '.session_id // empty' 2>/dev/null)
CWD=$(echo "$INPUT" | jq -r '.cwd // empty' 2>/dev/null)
```

### Security: Input Sanitization

Always sanitize user-controlled fields:

```bash
# Session ID (alphanumeric + dash/underscore only)
SESSION_ID=$(echo "$SESSION_ID" | tr -cd 'a-zA-Z0-9_-')

# Path validation
SAFE_CWD=$(realpath "$CWD" 2>/dev/null || echo "$CWD")
if [ ! -d "$SAFE_CWD" ]; then
  echo "Invalid directory" >&2
  exit 1
fi
```

---

## 2. 💾 PRECOMPACT PAYLOAD

### JSON Schema

```json
{
  "trigger": "manual" | "auto",
  "custom_instructions": "string (optional)",
  "session_id": "string",
  "cwd": "string"
}
```

### Field Descriptions

| Field | Type | Required | Description | Security Notes |
|-------|------|----------|-------------|----------------|
| **`trigger`** | enum | Yes | "manual" (user `/compact`) or "auto" (threshold) | Safe enum value |
| **`custom_instructions`** | string | No | User text for manual compaction | Sanitize for logging |
| **`session_id`** | string | Yes | Session identifier | Alphanumeric only |
| **`cwd`** | string | Yes | Working directory | Validate with realpath |

### Extraction Pattern

```bash
INPUT=$(cat)

# Extract all fields with fallbacks
TRIGGER=$(echo "$INPUT" | jq -r '.trigger // "auto"' 2>/dev/null)
CUSTOM_INSTRUCTIONS=$(echo "$INPUT" | jq -r '.custom_instructions // empty' 2>/dev/null)
SESSION_ID=$(echo "$INPUT" | jq -r '.session_id // empty' 2>/dev/null)
CWD=$(echo "$INPUT" | jq -r '.cwd // empty' 2>/dev/null)

# Security: Sanitize session_id
if [ -n "$SESSION_ID" ]; then
  SESSION_ID=$(echo "$SESSION_ID" | tr -cd 'a-zA-Z0-9_-')
fi

# Security: Validate working directory
if [ -n "$CWD" ]; then
  SAFE_CWD=$(realpath "$CWD" 2>/dev/null || echo "$CWD")
  if [ ! -d "$SAFE_CWD" ]; then
    echo "⚠️  Invalid working directory" >&2
    exit 0  # Graceful degradation for PreCompact
  fi
  CWD="$SAFE_CWD"
fi
```

### Validation Logic

```bash
# Required fields check
if [ -z "$SESSION_ID" ]; then
  echo "⚠️  Session ID missing" >&2
  exit 0  # PreCompact cannot block
fi

if [ -z "$CWD" ] || [ ! -d "$CWD" ]; then
  echo "⚠️  Invalid working directory" >&2
  exit 0
fi
```

### Example Payloads

**Manual Compaction:**
```json
{
  "trigger": "manual",
  "custom_instructions": "Save context before starting new feature",
  "session_id": "f3b2a1c9d8e7f6",
  "cwd": "/Users/alice/projects/myapp"
}
```

**Auto Compaction:**
```json
{
  "trigger": "auto",
  "session_id": "a1b2c3d4e5f6g7",
  "cwd": "/Users/bob/code/webapp"
}
```

---

## 3. 🎯 USERPROMPTSSUBMIT PAYLOAD

### JSON Schema

```json
{
  "prompt": "string",
  "session_id": "string",
  "cwd": "string",
  "message_count": number
}
```

### Field Descriptions

| Field | Type | Required | Description | Security Notes |
|-------|------|----------|-------------|----------------|
| **`prompt`** | string | Yes | User's message text | May contain any UTF-8 |
| **`session_id`** | string | Yes | Session identifier | Alphanumeric only |
| **`cwd`** | string | Yes | Working directory | Validate with realpath |
| **`message_count`** | number | Yes | Total messages in session | Safe integer |

### Extraction Pattern

```bash
INPUT=$(cat)

PROMPT=$(echo "$INPUT" | jq -r '.prompt // empty' 2>/dev/null)
SESSION_ID=$(echo "$INPUT" | jq -r '.session_id // empty' 2>/dev/null)
CWD=$(echo "$INPUT" | jq -r '.cwd // empty' 2>/dev/null)
MESSAGE_COUNT=$(echo "$INPUT" | jq -r '.message_count // 0' 2>/dev/null)

# Security: Sanitize session_id
SESSION_ID=$(echo "$SESSION_ID" | tr -cd 'a-zA-Z0-9_-')
```

### Common Patterns

#### Pattern: Keyword Detection
```bash
# Convert to lowercase for case-insensitive matching
PROMPT_LOWER=$(echo "$PROMPT" | tr '[:upper:]' '[:lower:]')

# Define keywords
KEYWORDS=("save context" "save conversation" "document this")

# Check for matches
for keyword in "${KEYWORDS[@]}"; do
  if echo "$PROMPT_LOWER" | grep -qE "\\b${keyword}\\b"; then
    echo "🎯 Detected keyword: '$keyword'"
    # Trigger action
    break
  fi
done
```

#### Pattern: Message Threshold
```bash
# Trigger every N messages
THRESHOLD=20
if [ $((MESSAGE_COUNT % THRESHOLD)) -eq 0 ] && [ "$MESSAGE_COUNT" -gt 0 ]; then
  echo "📊 Reached $MESSAGE_COUNT messages"
  # Trigger auto-save
fi
```

#### Pattern: Question Detection (Skip Read-Only)
```bash
PROMPT_LOWER=$(echo "$PROMPT" | tr '[:upper:]' '[:lower:]')

# Skip hook for questions (read-only queries)
if echo "$PROMPT_LOWER" | grep -qiE '\\b(what|how|why|explain|show me|describe)\\b'; then
  exit 0  # Skip hook, allow silently
fi
```

### Example Payloads

**Keyword Trigger:**
```json
{
  "prompt": "save context before I lose this work",
  "session_id": "abc123def456",
  "cwd": "/Users/charlie/project",
  "message_count": 42
}
```

**Threshold Trigger:**
```json
{
  "prompt": "Add error handling to the upload function",
  "session_id": "xyz789",
  "cwd": "/Users/dave/app",
  "message_count": 200
}
```

---

## 4. 🛡️ PRETOOLUSE PAYLOAD

### JSON Schema

```json
{
  "tool_name": "string",
  "tool_input": object,
  "session_id": "string",
  "cwd": "string"
}
```

### Field Descriptions

| Field | Type | Required | Description | Security Notes |
|-------|------|----------|-------------|----------------|
| **`tool_name`** | string | Yes | Tool about to execute | Safe string |
| **`tool_input`** | object | Yes | Tool parameters (varies by tool) | Validate nested fields |
| **`session_id`** | string | Yes | Session identifier | Alphanumeric only |
| **`cwd`** | string | Yes | Working directory | Validate with realpath |

### Extraction Pattern (Bash Tool)

```bash
INPUT=$(cat)

TOOL_NAME=$(echo "$INPUT" | jq -r '.tool_name // empty' 2>/dev/null)

# Only process Bash tool
if [ "$TOOL_NAME" != "Bash" ]; then
  exit 0
fi

# Extract bash command
COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // empty' 2>/dev/null)
DESCRIPTION=$(echo "$INPUT" | jq -r '.tool_input.description // empty' 2>/dev/null)
```

### Extraction Pattern (Edit Tool)

```bash
TOOL_NAME=$(echo "$INPUT" | jq -r '.tool_name // empty')

if [ "$TOOL_NAME" = "Edit" ]; then
  FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty')
  OLD_STRING=$(echo "$INPUT" | jq -r '.tool_input.old_string // empty')
  NEW_STRING=$(echo "$INPUT" | jq -r '.tool_input.new_string // empty')
fi
```

### Tool-Specific Schemas

#### Bash Tool
```json
{
  "tool_name": "Bash",
  "tool_input": {
    "command": "string",
    "description": "string (optional)"
  }
}
```

#### Edit Tool
```json
{
  "tool_name": "Edit",
  "tool_input": {
    "file_path": "string",
    "old_string": "string",
    "new_string": "string"
  }
}
```

#### Write Tool
```json
{
  "tool_name": "Write",
  "tool_input": {
    "file_path": "string",
    "content": "string"
  }
}
```

#### Read Tool
```json
{
  "tool_name": "Read",
  "tool_input": {
    "file_path": "string",
    "offset": number (optional),
    "limit": number (optional)
  }
}
```

### Example Payloads

**Bash Tool:**
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

**Edit Tool:**
```json
{
  "tool_name": "Edit",
  "tool_input": {
    "file_path": "/Users/eve/app/config.json",
    "old_string": "\"debug\": false",
    "new_string": "\"debug\": true"
  },
  "session_id": "pqr456",
  "cwd": "/Users/eve/app"
}
```

---

## 5. ✨ POSTTOOLUSE PAYLOAD

### JSON Schema

```json
{
  "tool_name": "string",
  "tool_input": object,
  "tool_output": "string",
  "exit_code": number,
  "session_id": "string",
  "cwd": "string"
}
```

### Field Descriptions

| Field | Type | Required | Description | Security Notes |
|-------|------|----------|-------------|----------------|
| **`tool_name`** | string | Yes | Tool that executed | Safe string |
| **`tool_input`** | object | Yes | Tool parameters used | Same as PreToolUse |
| **`tool_output`** | string | Yes | Tool execution output | May be very large |
| **`exit_code`** | number | Yes | Tool exit code (0=success) | Safe integer |
| **`session_id`** | string | Yes | Session identifier | Alphanumeric only |
| **`cwd`** | string | Yes | Working directory | Validate with realpath |

### Extraction Pattern

```bash
INPUT=$(cat)

TOOL_NAME=$(echo "$INPUT" | jq -r '.tool_name // empty')
EXIT_CODE=$(echo "$INPUT" | jq -r '.exit_code // 1')
TOOL_OUTPUT=$(echo "$INPUT" | jq -r '.tool_output // empty')

# Extract file path (if applicable)
FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty')
```

### Common Pattern: Filter by Success

```bash
# Only process successful tool executions
if [ "$EXIT_CODE" -ne 0 ]; then
  exit 0  # Tool failed, skip post-processing
fi
```

### Common Pattern: File Type Filtering

```bash
# Only process markdown files
if [[ "$FILE_PATH" != *.md ]]; then
  exit 0
fi

# Only process specific tools
if [ "$TOOL_NAME" != "Write" ] && [ "$TOOL_NAME" != "Edit" ]; then
  exit 0
fi
```

### Example Payload

```json
{
  "tool_name": "Write",
  "tool_input": {
    "file_path": "/Users/frank/app/README.md",
    "content": "# My App\\nThis is my application"
  },
  "tool_output": "File written successfully",
  "exit_code": 0,
  "session_id": "lmn123",
  "cwd": "/Users/frank/app"
}
```

---

## 6. 🔒 PREMESSAGECREATE PAYLOAD

### JSON Schema

```json
{
  "prompt": "string",
  "context": "string",
  "session_id": "string",
  "cwd": "string"
}
```

### Field Descriptions

| Field | Type | Required | Description | Security Notes |
|-------|------|----------|-------------|----------------|
| **`prompt`** | string | Yes | User's message | Same as UserPromptSubmit |
| **`context`** | string | Yes | Internal context for AI | Very large, sensitive |
| **`session_id`** | string | Yes | Session identifier | Alphanumeric only |
| **`cwd`** | string | Yes | Working directory | Validate with realpath |

### Extraction Pattern

```bash
INPUT=$(cat)

PROMPT=$(echo "$INPUT" | jq -r '.prompt // empty')
CONTEXT=$(echo "$INPUT" | jq -r '.context // empty')
```

### Common Pattern: Secret Detection

```bash
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
    echo "⚠️  WARNING: Potential secret detected" >&2
    # Could block with exit 1, but usually just warn
  fi
done
```

### Example Payload

```json
{
  "prompt": "Show me the contents of config.json",
  "context": "[internal context sent to AI model]",
  "session_id": "stu789",
  "cwd": "/Users/grace/app"
}
```

---

## 7. 📝 POSTMESSAGECREATE PAYLOAD

### JSON Schema

```json
{
  "prompt": "string",
  "response": "string",
  "session_id": "string",
  "cwd": "string"
}
```

### Field Descriptions

| Field | Type | Required | Description | Security Notes |
|-------|------|----------|-------------|----------------|
| **`prompt`** | string | Yes | User's original message | Same as UserPromptSubmit |
| **`response`** | string | Yes | AI-generated response | Very large text |
| **`session_id`** | string | Yes | Session identifier | Alphanumeric only |
| **`cwd`** | string | Yes | Working directory | Validate with realpath |

### Extraction Pattern

```bash
INPUT=$(cat)

PROMPT=$(echo "$INPUT" | jq -r '.prompt // empty')
RESPONSE=$(echo "$INPUT" | jq -r '.response // empty')
SESSION_ID=$(echo "$INPUT" | jq -r '.session_id // empty')
```

### Common Pattern: Response Logging

```bash
# Log response metrics
LOG_FILE="$HOOKS_DIR/logs/responses.log"
TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')
RESPONSE_LENGTH=$(echo "$RESPONSE" | wc -c)

echo "[$TIMESTAMP] $SESSION_ID | Length: $RESPONSE_LENGTH bytes" >> "$LOG_FILE"
```

### Example Payload

```json
{
  "prompt": "Explain PreCompact hooks",
  "response": "PreCompact hooks fire before context compaction...",
  "session_id": "vwx012",
  "cwd": "/Users/henry/docs"
}
```

---

## 8. 🚀 PRESESSIONSTART PAYLOAD

### JSON Schema

```json
{
  "session_id": "string",
  "cwd": "string",
  "config": object
}
```

### Field Descriptions

| Field | Type | Required | Description | Security Notes |
|-------|------|----------|-------------|----------------|
| **`session_id`** | string | Yes | New session identifier | Alphanumeric only |
| **`cwd`** | string | Yes | Working directory | Validate with realpath |
| **`config`** | object | Yes | Session configuration | Nested object |

### Extraction Pattern

```bash
INPUT=$(cat)

SESSION_ID=$(echo "$INPUT" | jq -r '.session_id // empty')
CWD=$(echo "$INPUT" | jq -r '.cwd // empty')

# Extract config fields
MODEL=$(echo "$INPUT" | jq -r '.config.model // empty')
PROJECT_NAME=$(echo "$INPUT" | jq -r '.config.project_name // empty')
```

### Common Pattern: Dependency Check

```bash
# Check for required tools
REQUIRED_TOOLS=("git" "node" "npm")
MISSING_TOOLS=()

for tool in "${REQUIRED_TOOLS[@]}"; do
  if ! command -v "$tool" &>/dev/null; then
    MISSING_TOOLS+=("$tool")
  fi
done

if [ ${#MISSING_TOOLS[@]} -gt 0 ]; then
  echo "⚠️  WARNING: Missing tools: ${MISSING_TOOLS[*]}" >&2
fi
```

### Example Payload

```json
{
  "session_id": "yza345",
  "cwd": "/Users/iris/project",
  "config": {
    "model": "claude-sonnet-4-5",
    "project_name": "my-app",
    "auto_save": true
  }
}
```

---

## 9. 🧹 POSTSESSIONEND PAYLOAD

### JSON Schema

```json
{
  "session_id": "string",
  "cwd": "string",
  "duration_ms": number,
  "message_count": number
}
```

### Field Descriptions

| Field | Type | Required | Description | Security Notes |
|-------|------|----------|-------------|----------------|
| **`session_id`** | string | Yes | Session that ended | Alphanumeric only |
| **`cwd`** | string | Yes | Working directory | Validate with realpath |
| **`duration_ms`** | number | Yes | Session duration (ms) | Safe integer |
| **`message_count`** | number | Yes | Total messages | Safe integer |

### Extraction Pattern

```bash
INPUT=$(cat)

SESSION_ID=$(echo "$INPUT" | jq -r '.session_id // empty')
CWD=$(echo "$INPUT" | jq -r '.cwd // empty')
DURATION_MS=$(echo "$INPUT" | jq -r '.duration_ms // 0')
MESSAGE_COUNT=$(echo "$INPUT" | jq -r '.message_count // 0')
```

### Common Pattern: Cleanup

```bash
# Clean up session-specific temporary files
TEMP_DIR="/tmp/claude-session-$SESSION_ID"
if [ -d "$TEMP_DIR" ]; then
  rm -rf "$TEMP_DIR"
  echo "🧹 Cleaned up session temp directory"
fi
```

### Example Payload

```json
{
  "session_id": "bcd678",
  "cwd": "/Users/jack/workspace",
  "duration_ms": 3600000,
  "message_count": 87
}
```

---

## 10. 🔧 ADVANCED PATTERNS

### Nested JSON Extraction

```bash
# Extract deeply nested fields
NESTED_VALUE=$(echo "$INPUT" | jq -r '.config.settings.debug // false')
```

### Array Extraction

```bash
# Extract array values
ARRAY_VALUES=$(echo "$INPUT" | jq -r '.items[] // empty')

# Iterate over array
while IFS= read -r item; do
  echo "Processing: $item"
done < <(echo "$INPUT" | jq -r '.items[]')
```

### Conditional Extraction

```bash
# Extract with conditional logic
VALUE=$(echo "$INPUT" | jq -r '
  if .field1 != null then .field1
  elif .field2 != null then .field2
  else "default"
  end
')
```

### Multiple Field Extraction (Efficient)

```bash
# Single jq call for multiple fields (faster)
read -r FIELD1 FIELD2 FIELD3 < <(echo "$INPUT" | jq -r '.field1, .field2, .field3')
```

---

## 11. 🔒 SECURITY BEST PRACTICES

### Input Sanitization Checklist

- [ ] Sanitize session_id (alphanumeric + dash/underscore)
- [ ] Validate cwd with realpath
- [ ] Sanitize user text for shell safety
- [ ] Validate numeric fields are actually numbers
- [ ] Check enum values against allowed list
- [ ] Never use eval with user input
- [ ] Quote all variables in commands

### Path Traversal Prevention

```bash
# Always validate paths
SAFE_PATH=$(realpath "$USER_PATH" 2>/dev/null)
if [ ! -d "$SAFE_PATH" ]; then
  echo "Invalid path" >&2
  exit 1
fi

# Additional check: must be within allowed directory
if [[ "$SAFE_PATH" != /allowed/path/* ]]; then
  echo "Path outside allowed directory" >&2
  exit 1
fi
```

### Command Injection Prevention

```bash
# Never use eval with user input
# BAD: eval "$USER_INPUT"

# Always quote variables
# GOOD: "$USER_VARIABLE"

# Use arrays for complex commands
cmd=("git" "commit" "-m" "$USER_MESSAGE")
"${cmd[@]}"
```

### String Sanitization

```bash
# Remove shell metacharacters
SAFE_STRING=$(echo "$USER_INPUT" | tr -cd '[:alnum:][:space:]._-')

# More restrictive (alphanumeric only)
SAFE_STRING=$(echo "$USER_INPUT" | tr -cd '[:alnum:]')
```

---

## 12. 📚 SUMMARY

All 8 hook types follow consistent JSON patterns:
- Standard fields: session_id, cwd
- Tool-specific fields vary by hook type
- Always use jq with fallbacks (`// empty`)
- Always sanitize user-controlled inputs
- Always validate paths with realpath
- Quote all variables in bash commands

For implementation guidance, see:
- `hook_creation_guide.md`: Step-by-step creation process
- `best_practices.md`: Performance and security patterns
- `testing_guide.md`: Testing strategies with sample payloads
