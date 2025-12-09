# Gemini CLI Command Reference

Complete reference for Gemini CLI v0.16.0+ commands, flags, and configuration.

### Core Principle

"Flexible output formats and session management enable programmatic integration and iterative workflows."

---

## 1. ⚙️ SETUP

Installation and authentication for Gemini CLI.

### Installation

```bash
npm install -g @google/gemini-cli
# Or without installing:
npx @google/gemini-cli
```

### Authentication

```bash
# Option 1: API Key
export GEMINI_API_KEY=your_key

# Option 2: OAuth (interactive)
gemini  # First run prompts for auth
```

---

## 2. 🚀 COMMAND FLAGS

Complete flag reference for gemini CLI commands.

### Essential Flags

| Flag | Short | Description |
|------|-------|-------------|
| `--yolo` | `-y` | Auto-approve all tool calls |
| `--output-format` | `-o` | Output format: `text`, `json`, `stream-json` |
| `--model` | `-m` | Model selection (e.g., `gemini-2.5-flash`) |

### Session Management

| Flag | Short | Description |
|------|-------|-------------|
| `--resume` | `-r` | Resume session by index or "latest" |
| `--list-sessions` | | List available sessions |
| `--delete-session` | | Delete session by index |

### Execution Options

| Flag | Short | Description |
|------|-------|-------------|
| `--sandbox` | `-s` | Run in isolated sandbox |
| `--approval-mode` | | `default`, `auto_edit`, or `yolo` |
| `--timeout` | | Request timeout in ms |
| `--checkpointing` | | Enable file change snapshots |

### Context & Tools

| Flag | Description |
|------|-------------|
| `--include-directories` | Add directories to workspace |
| `--allowed-tools` | Restrict available tools |
| `--allowed-mcp-server-names` | Restrict MCP servers |

### Other Options

| Flag | Short | Description |
|------|-------|-------------|
| `--debug` | `-d` | Enable debug output |
| `--version` | `-v` | Show version |
| `--help` | `-h` | Show help |
| `--list-extensions` | `-l` | List installed extensions |
| `--prompt-interactive` | `-i` | Interactive mode with initial prompt |

---

## 3. 📊 OUTPUT FORMATS

Different output formats for various use cases.

### Text (`-o text`)

```bash
gemini "prompt" -o text
# Returns: Human-readable response
```

### JSON (`-o json`)

```bash
gemini "prompt" -o json
```

Returns structured data:
```json
{
  "response": "The actual response content",
  "stats": {
    "models": {
      "gemini-2.5-flash": {
        "api": {
          "totalRequests": 3,
          "totalErrors": 0,
          "totalLatencyMs": 5000
        },
        "tokens": {
          "prompt": 1500,
          "candidates": 500,
          "total": 2000,
          "cached": 800,
          "thoughts": 150,
          "tool": 50
        }
      }
    },
    "tools": {
      "totalCalls": 2,
      "totalSuccess": 2,
      "totalFail": 0,
      "byName": {
        "google_web_search": {
          "count": 1,
          "success": 1,
          "durationMs": 3000
        }
      }
    }
  }
}
```

**Programmatic Access Example:**

❌ **BEFORE** (hard to parse):
```bash
gemini "analyze code" -o text | grep "issues"
```

✅ **AFTER** (structured access):
```bash
output=$(gemini "analyze code" -o json)
response=$(echo "$output" | jq -r '.response')
token_count=$(echo "$output" | jq -r '.stats.models."gemini-2.5-flash".tokens.total')
tool_calls=$(echo "$output" | jq -r '.stats.tools.totalCalls')
```

**Why better**: Structured access to response AND metadata (tokens, tool usage, latency)

### Stream JSON (`-o stream-json`)

Real-time newline-delimited JSON events for monitoring long tasks.

---

## 4. 🎨 MODEL SELECTION

Available models and usage patterns.

### Available Models

| Model | Use Case | Context |
|-------|----------|---------|
| `gemini-3-pro` | Complex tasks (default) | 1M tokens |
| `gemini-2.5-flash` | Quick tasks, lower latency | Large |
| `gemini-2.5-flash-lite` | Fastest, simplest tasks | Medium |

### Usage

```bash
# Default (Pro)
gemini "complex analysis" -o text

# Flash for speed
gemini "simple task" -m gemini-2.5-flash -o text
```

---

## 5. 🔧 CONFIGURATION

Settings files and project configuration.

### Settings Location

Priority order (highest first):
1. `/etc/gemini-cli/settings.json` (system)
2. `~/.gemini/settings.json` (user)
3. `.gemini/settings.json` (project)

### Example Settings

```json
{
  "security": {
    "auth": {
      "selectedType": "oauth-personal"
    }
  },
  "general": {
    "previewFeatures": true,
    "vimMode": false,
    "checkpointing": true
  },
  "mcpServers": {}
}
```

### Project Context (GEMINI.md)

Create `.gemini/GEMINI.md` in project root:
```markdown
# Project Context

Project description and guidelines.

## Coding Standards
- Standards Gemini should follow

## When Making Changes
- Guidelines for modifications
```

### Ignore Files (.geminiignore)

Like `.gitignore`, excludes files from context:
```
node_modules/
dist/
*.log
.env
```

---

## 6. 💬 SESSION MANAGEMENT

Working with persistent sessions.

### List Sessions

```bash
gemini --list-sessions
```

Output:
```
Available sessions for this project (5):
  1. Create task manager (10 minutes ago) [uuid]
  2. Review code (20 minutes ago) [uuid]
  ...
```

### Resume Session

```bash
# By index
echo "follow-up question" | gemini -r 1 -o text

# Latest session
echo "continue" | gemini -r latest -o text
```

---

## 7. ⚡ RATE LIMITS

Understanding and managing rate limits.

### Free Tier Limits

- 60 requests per minute
- 1000 requests per day

### Rate Limit Behavior

- CLI auto-retries with exponential backoff
- Message: `"quota will reset after Xs"`
- Typical wait: 1-5 seconds

### Mitigation Strategies

1. Use `gemini-2.5-flash` for simple tasks
2. Batch operations into single prompts
3. Run long tasks in background

---

## 8. 🎮 INTERACTIVE MODE

Features available in interactive mode.

### Interactive Commands

| Command | Purpose |
|---------|---------|
| `/help` | Show available commands |
| `/tools` | List available tools |
| `/stats` | Show token usage |
| `/compress` | Summarize context to save tokens |
| `/restore` | Restore file checkpoints |
| `/chat save <tag>` | Save conversation |
| `/chat resume <tag>` | Resume conversation |
| `/memory show` | Display GEMINI.md context |
| `/memory refresh` | Reload context files |

### Keyboard Shortcuts

| Shortcut | Function |
|----------|----------|
| `Ctrl+L` | Clear screen |
| `Ctrl+V` | Paste from clipboard |
| `Ctrl+Y` | Toggle YOLO mode |
| `Ctrl+X` | Open in external editor |

---

## 9. 🔌 PIPING & SCRIPTING

Integration with shell scripts and pipelines.

### Pipe Input

```bash
echo "What is 2+2?" | gemini -o text
cat file.txt | gemini "summarize this" -o text
```

### File Reference Syntax

In prompts, reference files with `@`:
```bash
gemini "Review @./src/main.js for bugs" -o text
```

### Shell Command Execution

In interactive mode, prefix with `!`:
```
> !git status
```

---

## 10. 🛠️ TROUBLESHOOTING

Common issues and solutions.

### Common Issues

| Issue | Solution |
|-------|----------|
| "API key not found" | Set `GEMINI_API_KEY` env var |
| "Rate limit exceeded" | Wait for auto-retry or use Flash |
| "Context too large" | Use `.geminiignore` or be specific |
| "Tool call failed" | Check JSON stats for details |

### Debug Mode

```bash
gemini "prompt" --debug -o text
```

### Error Reports

Full error reports saved to:
```
/var/folders/.../gemini-client-error-*.json
```

### Common Errors

**Authentication Errors:**

```bash
# Error: "API key not found"
# → Cause: GEMINI_API_KEY environment variable not set
# → Fix: export GEMINI_API_KEY=your_key

# Error: "401 Unauthorized"
# → Cause: Invalid or expired API key
# → Fix: Re-authenticate with `gemini` (follow prompts)
```

**Rate Limit Errors:**

```bash
# Error: "Resource exhausted" or "429 Too Many Requests"
# → Cause: Exceeded rate limits (60/min, 1000/day)
# → Fix: CLI auto-retries with backoff, or use -m gemini-2.5-flash

# Message: "quota will reset after Xs"
# → Cause: Hit rate limit, waiting for reset
# → Fix: Wait or reduce request rate
```

**Execution Errors:**

```bash
# Error: "Command not found: gemini"
# → Cause: Gemini CLI not installed or not in PATH
# → Fix: npm install -g @google/gemini-cli

# Error: "YOLO mode failed to auto-approve"
# → Cause: YOLO flag doesn't prevent planning prompts
# → Fix: Use forceful language ("Apply now", "Start immediately")
```