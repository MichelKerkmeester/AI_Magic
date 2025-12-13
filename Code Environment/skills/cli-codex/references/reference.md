# Codex CLI Command Reference

Complete reference for OpenAI Codex CLI commands, flags, and configuration options.

---

## 1. ⚙️ COMMAND STRUCTURE

```bash
codex [OPTIONS] [COMMAND] [ARGS]
```

---

## 2. 🚀 MAIN COMMANDS

### Interactive Mode (Default)

```bash
codex [OPTIONS] [PROMPT]
```

Start interactive CLI session. If no subcommand specified, enters interactive mode.

### exec - Non-Interactive Execution

```bash
codex exec [OPTIONS] [PROMPT]
```

Run Codex non-interactively with a single prompt.

**Subcommands:**
- `exec resume [SESSION_ID]` - Resume a previous exec session

### login - Authentication Management

```bash
codex login [OPTIONS]
```

Manage authentication credentials for OpenAI API.

### logout - Remove Credentials

```bash
codex logout
```

Remove stored authentication credentials.

### mcp - MCP Server Management

```bash
codex mcp [COMMAND]
```

**Experimental** - Manage Model Context Protocol servers.

### mcp-server - Run MCP Server

```bash
codex mcp-server
```

**Experimental** - Run the Codex MCP server (stdio transport).

### app-server - App Server Tools

```bash
codex app-server [COMMAND]
```

**Experimental** - Run app server or related tooling.

### completion - Shell Completions

```bash
codex completion [SHELL]
```

Generate shell completion scripts for bash, zsh, fish, etc.

### sandbox - Sandboxed Execution

```bash
codex sandbox [COMMAND]
```

Run commands within Codex-provided sandbox.

**Platform-specific commands:**
- `macos` / `seatbelt` - Run under Seatbelt (macOS)
- `linux` / `landlock` - Run under Landlock+seccomp (Linux)
- `windows` - Run under Windows restricted token (Windows)

### apply - Apply Diffs

```bash
codex apply [OPTIONS] <TASK_ID>
```

Apply the latest diff produced by Codex agent as `git apply` to local working tree.

### resume - Resume Interactive Session

```bash
codex resume [OPTIONS] [SESSION_ID] [PROMPT]
```

Resume a previous interactive session.

**Options:**
- `--last` - Continue most recent session without picker

### cloud - Cloud Tasks

```bash
codex cloud [COMMAND]
```

**Experimental** - Browse tasks from Codex Cloud and apply changes locally.

### features - Feature Flags

```bash
codex features
```

Inspect feature flags.

---

## 3. 🎛️ GLOBAL OPTIONS

Available for most commands:

### Configuration Override

```bash
-c, --config <key=value>
```

Override configuration values from `~/.codex/config.toml`.

**Format:** Use dotted path for nested values. Value parsed as TOML.

**Examples:**
```bash
-c model="o3-mini"
-c 'sandbox_permissions=["disk-full-read-access"]'
-c shell_environment_policy.inherit=all
```

### Feature Flags

```bash
--enable <FEATURE>   # Enable a feature (repeatable)
--disable <FEATURE>  # Disable a feature (repeatable)
```

Equivalent to `-c features.<name>=true/false`

### Model Selection

```bash
-m, --model <MODEL>
```

Specify which model the agent should use.

**Common models:**
- `gpt-5.1-codex` (default)
- `o3-mini`
- `o3`

### Profile Selection

```bash
-p, --profile <CONFIG_PROFILE>
```

Use configuration profile from `config.toml` to specify default options.

### Version & Help

```bash
-V, --version  # Print version
-h, --help     # Print help
```

---

## 4. 🔒 EXECUTION OPTIONS

### Sandbox Mode

```bash
-s, --sandbox <SANDBOX_MODE>
```

Select sandbox policy for executing model-generated shell commands.

**Values:**
- `read-only` - No file modifications (safest)
- `workspace-write` - Can modify workspace files (recommended)
- `danger-full-access` - Full system access (dangerous)

### Approval Policy

```bash
-a, --ask-for-approval <APPROVAL_POLICY>
```

Configure when model requires human approval before executing commands.

**Values:**
- `untrusted` - Only run trusted commands without approval
- `on-failure` - Ask approval only if command fails
- `on-request` - Model decides when to ask
- `never` - Never ask for approval

**Note:** Available in interactive/resume modes, not `codex exec`.

### Full Auto Mode

```bash
--full-auto
```

Convenience alias for low-friction sandboxed automatic execution.

**Equivalent to:** `-a on-request --sandbox workspace-write`

### Dangerous Mode

```bash
--dangerously-bypass-approvals-and-sandbox
```

Skip all confirmation prompts and execute without sandboxing.

**⚠️ EXTREMELY DANGEROUS** - Only use in externally sandboxed environments.

---

## 5. 📥 INPUT OPTIONS

### Prompt Argument

```bash
codex exec "Your prompt here"
```

Provide prompt as command argument. Use `-` to read from stdin.

### Image Attachments

```bash
-i, --image <FILE>...
```

Attach image(s) to initial prompt (repeatable).

**Example:**
```bash
codex exec "Analyze this screenshot" -i screenshot.png
```

### Working Directory

```bash
-C, --cd <DIR>
```

Set working directory for the agent.

### Additional Writable Directories

```bash
--add-dir <DIR>
```

Add directories that should be writable alongside primary workspace.

---

## 6. 📤 OUTPUT OPTIONS

### JSON Output

```bash
--json
```

Print events to stdout as JSONL (JSON Lines format).

### Output Last Message

```bash
-o, --output-last-message <FILE>
```

Write the last message from agent to specified file.

### Output Schema

```bash
--output-schema <FILE>
```

Path to JSON Schema file describing model's final response shape.

### Color Settings

```bash
--color <COLOR>
```

Specify color settings for output.

**Values:** `always`, `never`, `auto` (default)

---

## 7. ⚡ ADDITIONAL OPTIONS

### Web Search

```bash
--search
```

Enable web search (off by default). Makes native `web_search` tool available to model.

**Note:** Available in interactive/resume modes.

### Git Repository Check

```bash
--skip-git-repo-check
```

Allow running Codex outside a Git repository.

### OSS Mode

```bash
--oss
```

Convenience flag to select local open source model provider.

**Equivalent to:** `-c model_provider=oss`

Verifies local Ollama server is running.

---

## 8. 📁 CONFIGURATION FILE

### Location

`~/.codex/config.toml`

### Format

TOML configuration file.

### Example Configuration

```toml
model = "gpt-5.1-codex"
model_reasoning_effort = "high"

[projects."/path/to/project"]
trust_level = "trusted"

[mcp_servers."chrome-devtools"]
command = "npx"
args = ["-y", "chrome-devtools-mcp"]

[mcp_servers."chrome-devtools".env]
NODE_ENV = "development"

[notice]
hide_gpt5_1_migration_prompt = true
```

### Configuration Hierarchy

1. Command-line flags (highest priority)
2. Project config (`.codex/config.toml` in project)
3. User config (`~/.codex/config.toml`)
4. System config (lowest priority)

---

## 9. 💾 SESSION MANAGEMENT

### Session ID Format

UUIDs (e.g., `019aa02d-536c-72d3-abfd-d0f5c233af91`)

Displayed in output header:
```
session id: 019aa02d-536c-72d3-abfd-d0f5c233af91
```

### Resume Session

```bash
# Resume specific session
codex resume 019aa02d-536c-72d3-abfd-d0f5c233af91 "continue with..."

# Resume most recent
codex resume --last "next step..."
```

---

## 10. 📊 OUTPUT FORMAT

### Standard Output (exec mode)

```
OpenAI Codex v0.58.0 (research preview)
--------
workdir: /path/to/dir
model: gpt-5.1-codex
provider: openai
approval: never
sandbox: workspace-write [workdir, /tmp, $TMPDIR]
reasoning effort: high
reasoning summaries: auto
session id: <uuid>
--------
user
[Your prompt]

thinking
[Reasoning process - shows model's thought process]

codex
[Model response]

tokens used
[Number of tokens consumed]
```

### Metadata Fields

- **workdir**: Current working directory
- **model**: Model being used
- **provider**: API provider (openai)
- **approval**: Approval policy active
- **sandbox**: Sandbox mode and allowed paths
- **reasoning effort**: Level of reasoning (high/medium/low)
- **reasoning summaries**: Auto-summarization setting
- **session id**: Unique session identifier
- **tokens used**: Total tokens consumed

---

## 11. 🔢 EXIT CODES

- `0` - Success
- Non-zero - Error (varies by error type)

---

## 12. 🌍 ENVIRONMENT VARIABLES

### OpenAI API Key

Codex CLI uses standard OpenAI authentication. Check specific Codex CLI docs for required environment variables.

### Custom Configuration

Environment variables can be used for configuration overrides. Check `codex --help` for specific variables.

---

## 13. 💻 PLATFORM-SPECIFIC NOTES

### macOS
- Uses Seatbelt for sandboxing
- Supports all standard features

### Linux
- Uses Landlock + seccomp for sandboxing
- Supports all standard features

### Windows
- Uses restricted token for sandboxing
- Feature parity with other platforms

---

## 14. 📌 VERSION REQUIREMENTS

**Minimum Version:** v0.58.0

**Verified Features:**
- All commands and flags documented here
- Reasoning display
- Session management
- Sandbox modes
- Approval policies

---

## 15. 📋 QUICK REFERENCE TABLE

| Flag        | Short | Description         | Default       |
| ----------- | ----- | ------------------- | ------------- |
| --full-auto | -     | Safe auto-execution | Off           |
| --sandbox   | -s    | Sandbox mode        | read-only     |
| --model     | -m    | Model selection     | gpt-5.1-codex |
| --config    | -c    | Override config     | -             |
| --cd        | -C    | Working directory   | Current       |
| --json      | -     | JSONL output        | Off           |
| --image     | -i    | Attach image        | -             |
| --help      | -h    | Show help           | -             |
| --version   | -V    | Show version        | -             |
