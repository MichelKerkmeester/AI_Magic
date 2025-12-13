# Codex CLI Capabilities and Tools

Comprehensive documentation of Codex CLI's features, capabilities, and built-in tools.

---

## 1. 🧠 MODEL CAPABILITIES

### GPT-5.1 Codex (Default)

**Primary Model**: `gpt-5.1-codex`

**Key Features:**
- High reasoning capability
- Deep code understanding
- Architecture analysis
- Security-aware code generation
- Performance optimization insights

**Best For:**
- Complex algorithm design
- Security-critical code
- Architecture decisions
- Performance-sensitive code
- Deep refactoring

**Reasoning Display:**
Shows explicit "thinking" section in output, revealing:
- Problem analysis approach
- Decision-making process
- Trade-off considerations
- Alternative approaches considered

**Context Window:**
Large context window supporting extensive code analysis.

---

### Alternative Models

**o3-mini**: Faster, lighter model for simpler tasks

**Usage:**
```bash
codex exec "[simple prompt]" -m o3-mini 2>&1
```

**Best For:**
- Boilerplate generation
- Simple refactoring
- Quick code reviews
- Template filling

**o3**: Full capability model

**Usage:**
```bash
codex exec "[complex prompt]" -m o3 2>&1
```

**Best For:**
- Highest complexity tasks
- Research-level problems
- Novel algorithm design

---

## 2. 🤔 REASONING FEATURES

### Reasoning Effort Levels

Configurable in `~/.codex/config.toml`:

```toml
model_reasoning_effort = "high"  # or "medium" or "low"
```

**High** (default):
- Deep analysis
- Considers multiple approaches
- Thorough edge case analysis
- Slower but higher quality

**Medium**:
- Balanced approach
- Good for most tasks
- Faster than high

**Low**:
- Quick reasoning
- Simple tasks only
- Fastest execution

### Reasoning Summaries

**Configuration:**
```toml
reasoning_summaries = "auto"  # or "always" or "never"
```

**Auto** (default): Summarizes reasoning when appropriate
**Always**: Always shows reasoning summaries
**Never**: Hides reasoning summaries

---

## 3. 🔒 SANDBOX CAPABILITIES

### Sandbox Modes

**1. Read-Only** (Safest)

```bash
codex exec "[prompt]" -s read-only 2>&1
```

**Permissions:**
- Read files and directories
- No modifications allowed
- No file creation
- No file deletion

**Use Cases:**
- Code analysis
- Security audits
- Architecture review
- Learning codebases

**2. Workspace-Write** (Recommended)

```bash
codex exec "[prompt]" -s workspace-write 2>&1
# or use --full-auto which sets this
codex exec "[prompt]" --full-auto 2>&1
```

**Permissions:**
- Read all files
- Write to working directory
- Write to `/tmp` and `$TMPDIR`
- Cannot access system files

**Allowed Paths:**
- `[workdir]` - Current working directory
- `/tmp` - Temporary directory
- `$TMPDIR` - System temp directory

**Use Cases:**
- Code generation
- Refactoring
- Test generation
- Documentation creation

**3. Danger-Full-Access** (Use with Extreme Caution)

```bash
codex exec "[prompt]" -s danger-full-access 2>&1
```

**Permissions:**
- Full system access
- No restrictions
- Can modify any file
- Can execute any command

**⚠️ WARNING**: Only use in:
- Disposable/sandboxed environments
- Containers or VMs
- When absolutely necessary

**Use Cases:**
- System administration tasks
- Global configuration changes
- Cross-project operations

---

## 4. 💻 PLATFORM-SPECIFIC SANDBOXING

### macOS: Seatbelt

```bash
codex sandbox macos [command]
```

**Technology**: Apple's Seatbelt sandboxing
**Features**: Fine-grained access control

### Linux: Landlock + seccomp

```bash
codex sandbox linux [command]
```

**Technology**: Landlock LSM + seccomp-bpf
**Features**: Kernel-level isolation

### Windows: Restricted Token

```bash
codex sandbox windows [command]
```

**Technology**: Windows restricted token
**Features**: User-level sandboxing

---

## 5. ✅ APPROVAL MECHANISMS

**Note**: Approval policies available in interactive/resume modes, not `codex exec`.

### Policy Options

**never**:
```bash
codex resume --last "do task" -a never 2>&1
```
- No approval prompts
- All commands auto-execute
- Fastest execution

**untrusted**:
```bash
codex resume --last "do task" -a untrusted 2>&1
```
- Trusted commands auto-execute (ls, cat, sed, etc.)
- Untrusted commands require approval
- Balanced safety

**on-failure**:
```bash
codex resume --last "do task" -a on-failure 2>&1
```
- All commands attempt auto-execution
- Approval requested only on failure
- Allows sandboxed retry

**on-request**:
```bash
codex resume --last "do task" -a on-request 2>&1
```
- Model decides when to ask
- Intelligent approval points
- Best for complex workflows

---

## 6. 💾 SESSION MANAGEMENT

### Session Persistence

**Session ID Format**: UUID (e.g., `019aa02d-536c-72d3-abfd-d0f5c233af91`)

**Session Storage**:
- Stored locally in Codex CLI cache
- Includes full conversation context
- Persists across restarts

**Session Lifetime**:
- No explicit expiration (implementation-dependent)
- Can be explicitly deleted if needed

### Session Operations

**Resume Specific Session:**
```bash
codex resume 019aa02d-536c-72d3-abfd-d0f5c233af91 "continue with..." 2>&1
```

**Resume Most Recent:**
```bash
codex resume --last "next step..." 2>&1
```

**Session Context:**
- Maintains conversation history
- Preserves code understanding
- Enables iterative refinement

---

## 7. ⚙️ CONFIGURATION SYSTEM

### Configuration Hierarchy

1. **Command-line flags** (highest priority)
2. **Project config** (`.codex/config.toml`)
3. **User config** (`~/.codex/config.toml`)
4. **System config** (lowest priority)

### User Configuration

**Location**: `~/.codex/config.toml`

**Example:**
```toml
model = "gpt-5.1-codex"
model_reasoning_effort = "high"

# Project trust levels
[projects."/path/to/trusted/project"]
trust_level = "trusted"

[projects."/path/to/sandboxed/project"]
trust_level = "sandboxed"

# MCP Server configuration
[mcp_servers."chrome-devtools"]
command = "npx"
args = ["-y", "chrome-devtools-mcp"]

[mcp_servers."chrome-devtools".env]
NODE_ENV = "development"

# Feature flags
[features]
web_search = false
experimental_mode = false

# Notices
[notice]
hide_gpt5_1_migration_prompt = true
```

### Runtime Configuration Override

```bash
# Override model
codex exec "[prompt]" -c model="o3-mini" 2>&1

# Override multiple settings
codex exec "[prompt]" \
  -c model="o3" \
  -c model_reasoning_effort="high" \
  -c 'sandbox_permissions=["disk-full-read-access"]' \
  2>&1
```

---

## 8. 🔌 MCP (MODEL CONTEXT PROTOCOL) INTEGRATION

### MCP Server Support

Codex CLI can integrate with MCP servers for extended capabilities.

**Configuration:**
```toml
[mcp_servers."server-name"]
command = "command-to-run"
args = ["arg1", "arg2"]

[mcp_servers."server-name".env]
ENV_VAR = "value"
```

**Example - Chrome DevTools:**
```toml
[mcp_servers."chrome-devtools"]
command = "npx"
args = ["-y", "chrome-devtools-mcp"]

[mcp_servers."chrome-devtools".env]
NODE_ENV = "development"
```

### MCP Management Commands

```bash
# Experimental MCP commands
codex mcp [subcommand]
codex mcp-server  # Run MCP server
```

---

## 9. 📊 OUTPUT FORMATS AND METADATA

### Standard Output Format

**Header Section:**
```
OpenAI Codex v0.58.0 (research preview)
--------
workdir: /absolute/path
model: gpt-5.1-codex
provider: openai
approval: never
sandbox: workspace-write [workdir, /tmp, $TMPDIR]
reasoning effort: high
reasoning summaries: auto
session id: 019aa02d-536c-72d3-abfd-d0f5c233af91
--------
```

**Conversation Section:**
```
user
[Your prompt]

thinking
[Model's reasoning process - shows decision making]

codex
[Model's response]
```

**Footer Section:**
```
tokens used
[Total token count]
```

### JSONL Output Format

```bash
codex exec "[prompt]" --json 2>&1
```

**Format**: Newline-delimited JSON events

**Event Types:**
- Status updates
- Thinking events
- Response chunks
- Token usage
- Errors

**Parsing:**
```bash
codex exec "[prompt]" --json 2>&1 | while read -r line; do
  echo "$line" | jq '.type, .content'
done
```

---

## 10. 📁 FILE OUTPUT OPTIONS

### Save Last Message

```bash
codex exec "[prompt]" -o output.txt 2>&1
```

Writes the final message from Codex to specified file.

**Use Cases:**
- Capture generated code
- Save analysis results
- Store for later processing

### Structured Output Schema

```bash
codex exec "[prompt]" --output-schema schema.json 2>&1
```

Define JSON Schema for model's response format.

**Use Cases:**
- API response generation
- Structured data extraction
- Programmatic consumption

---

## 11. 🔀 DIFF GENERATION AND APPLICATION

### Generate Diffs

Codex can generate diffs for file modifications.

**Prompt Pattern:**
```bash
codex exec "Refactor [file] to [improvements]. Generate diff format." --full-auto 2>&1
```

### Apply Diffs

```bash
# Extract task ID from session
codex apply [task-id]
```

Applies generated diff to working tree using `git apply`.

**Safety:**
- Review diff before applying
- Test in separate branch
- Verify with version control

---

## 12. 🚀 ADVANCED FEATURES

### Web Search Integration

**Enable in resume mode:**
```bash
codex resume --last "search for latest [topic]" --search 2>&1
```

Enables native `web_search` tool for current information.

**Use Cases:**
- Latest library versions
- Current best practices
- Recent API changes
- Documentation lookups

### Working Directory Control

```bash
codex exec "[prompt]" -C /path/to/project 2>&1
```

Sets working directory for the agent.

### Additional Writable Directories

```bash
codex exec "[prompt]" --add-dir /path/to/other/dir 2>&1
```

Adds extra directories to writable list (with workspace-write sandbox).

### Skip Git Checks

```bash
codex exec "[prompt]" --skip-git-repo-check 2>&1
```

Allows running outside Git repositories.

---

## 13. 🛡️ TRUST LEVELS

### Project Trust Configuration

```toml
[projects."/path/to/project"]
trust_level = "trusted"
```

**Levels:**
- `trusted`: Full trust, minimal prompts
- `sandboxed`: Standard sandboxing
- `untrusted`: Maximum restrictions

**Effects:**
- Approval frequency
- Default sandbox mode
- Command execution policy

---

## 14. 💰 TOKEN USAGE AND COSTS

### Token Reporting

Always displayed in output footer:
```
tokens used
8,190
```

### Monitoring Usage

**Track in logs:**
```bash
codex exec "[prompt]" 2>&1 | tee -a usage.log
grep "tokens used" usage.log | awk '{sum += $3} END {print "Total:", sum}'
```

**Cost Estimation:**
- Check OpenAI pricing for gpt-5.1-codex
- Multiply token count by price per token
- Track across sessions

---

## 15. ⚠️ LIMITATIONS AND CONSTRAINTS

### Context Window

- Large but finite context window
- Very long prompts may be truncated
- Consider breaking large tasks into chunks

### Rate Limits

- Subject to OpenAI API rate limits
- Varies by account tier
- No auto-retry (manual handling required)

### Session Isolation

- `codex exec` is stateless (no conversation memory)
- Use `codex resume` for multi-turn workflows
- Cannot access the agent's conversation history

### Platform Differences

- Sandboxing varies by OS
- Some features may be platform-specific
- Test on target platform

---

## 16. 🆚 COMPARISON WITH OTHER TOOLS

### vs Native AI Agent

**Codex Advantages:**
- Shows explicit reasoning process
- Alternative AI perspective
- Different problem-solving approaches
- Can validate AI agent's work

**Native AI Agent Advantages:**
- Conversation context awareness
- Faster for simple tasks
- Better for iterative refinement
- No API rate limits

### When to Use Each

**Use Codex CLI:**
- Need second opinion
- Complex reasoning tasks
- Alternative approaches
- Background processing

**Use Native AI Agent:**
- Interactive development
- Context-dependent tasks
- Iterative refinement
- Real-time collaboration

---

## 17. ✅ BEST PRACTICES

### DO
- ✅ Use appropriate sandbox mode
- ✅ Review reasoning process
- ✅ Save session IDs for continuity
- ✅ Monitor token usage
- ✅ Validate all generated code
- ✅ Provide rich context
- ✅ Use structured output when possible

### DON'T

- ❌ Use danger-full-access casually
- ❌ Ignore security warnings
- ❌ Exceed rate limits carelessly
- ❌ Trust output blindly
- ❌ Skip approval mechanisms inappropriately
- ❌ Forget to capture stderr
