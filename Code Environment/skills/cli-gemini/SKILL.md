---
name: cli-gemini
description: Wield Google's Gemini CLI as a powerful auxiliary tool for code generation, review, analysis, and web research. Use when tasks benefit from a second AI perspective, current web information via Google Search, codebase architecture analysis, or parallel code generation. Also use when user explicitly requests Gemini operations.
allowed-tools: [Bash, Read, Write, Grep, Glob]
version: 1.1.0
---

<!-- Keywords: gemini-cli, google-gemini, code-generation, code-review, web-search, codebase-analysis, ai-orchestration, cross-validation -->

# Gemini CLI Integration Skill

Enable AI agents to effectively orchestrate Gemini CLI (v0.16.0+) with Gemini 3 Pro for code generation, review, analysis, and specialized tasks requiring a second AI perspective or real-time web information.

---

## 🚀 QUICK START: Slash Commands

**Recommended way to use this skill:**

| Command | Description | SpecKit | Best For |
|---------|-------------|---------|----------|
| `/cli:gemini` | Interactive Gemini query with gates | **Required** | Tracked queries with memory |
| `/cli:gemini_quick` | Fast Gemini query, no prompts | None | Quick one-off queries |

**Usage Flow:**
```
/cli:gemini [query] [:review|:generate|:analyze|:research]
    │
    ├─► Prompts for spec folder selection
    ├─► Loads relevant memory context
    ├─► Executes Gemini query
    └─► Saves response to spec memory (mandatory)

/cli:gemini_quick [query] [:type]
    │
    └─► Direct execution, no tracking
```

**When to use which:**
- **`/cli:gemini`**: Research sessions, architecture analysis, tracked investigations
- **`/cli:gemini_quick`**: Quick web searches, fast lookups, disposable queries

---

## 1. 🎯 WHEN TO USE

### Ideal Use Cases

**1. Second Opinion / Cross-Validation**
- Code review after writing code (different AI perspective)
- Security audit with alternative analysis
- Finding bugs the agent might have missed
- Validating architectural decisions

**2. Google Search Grounding**
- Questions requiring current internet information
- Latest library versions, API changes, documentation updates
- Current events or recent releases
- Real-time information not in the agent's training data

**3. Codebase Architecture Analysis**
- Use Gemini's `codebase_investigator` tool
- Understanding unfamiliar codebases
- Mapping cross-file dependencies
- Analyzing complex project structures

**4. Parallel Processing**
- Offload tasks while continuing other work
- Run multiple code generations simultaneously
- Background documentation generation
- Concurrent analysis of multiple files

**5. Specialized Generation**
- Test suite generation
- JSDoc/documentation generation
- Code translation between languages
- Boilerplate code creation

**6. Explicit User Request**
- User directly asks to use Gemini
- User wants comparison between different AI approaches
- User requests Google Search integration

### When NOT to Use

**Skip this skill when:**
- Simple, quick tasks (overhead not worth it)
- Tasks requiring immediate response (rate limits cause delays)
- Context is already loaded and understood by the agent
- Interactive refinement requiring conversation
- Task needs access to the agent's full conversation history
- Budget/cost constraints (Gemini API has limits)


---

## 2. 🧭 SMART ROUTING

### Activation Detection
```
TASK CONTEXT
    │
    ├─► User explicitly requests "Gemini", "Gemini CLI", "Google Gemini"
    │   └─► ACTIVATE this skill
    │
    ├─► Task needs real-time web search (Google Search grounding)
    │   └─► ACTIVATE this skill
    │
    ├─► Codebase architecture analysis needed
    │   └─► ACTIVATE this skill
    │
    ├─► User wants second AI perspective / alternative approach
    │   └─► ACTIVATE this skill
    │
    └─► Standard agent task (no external search/opinion needed)
        └─► Handle directly, skip this skill
```

### Resource Router
```python
def route_gemini_resources(task):
    # ──────────────────────────────────────────────────────────────────
    # CLI Reference
    # Purpose: CLI flags and command syntax
    # Key Insight: Load for command construction
    # ──────────────────────────────────────────────────────────────────
    if task.needs_command_help or task.first_time:
        return load("references/reference.md")  # CLI flags and syntax

    # ──────────────────────────────────────────────────────────────────
    # Gemini Tools (Web Search)
    # Purpose: Built-in tools (google_web_search, codebase_investigator)
    # Key Insight: Load when using Gemini-specific tools
    # ──────────────────────────────────────────────────────────────────
    if task.needs_current_info or task.web_search:
        return load("references/tools.md")  # google_web_search tool docs

    # ──────────────────────────────────────────────────────────────────
    # Gemini Tools (Codebase Analysis)
    # Purpose: Built-in tools (google_web_search, codebase_investigator)
    # Key Insight: Load when using Gemini-specific tools
    # ──────────────────────────────────────────────────────────────────
    if task.architecture_analysis:
        return load("references/tools.md")  # codebase_investigator tool

    # ──────────────────────────────────────────────────────────────────
    # Prompt Templates
    # Purpose: Prompt templates
    # Key Insight: Load for copy-paste prompts
    # ──────────────────────────────────────────────────────────────────
    if task.type in ["code_review", "test_generation", "doc_generation"]:
        return load("references/templates.md")  # prompt templates by use case

    # ──────────────────────────────────────────────────────────────────
    # Orchestration Patterns
    # Purpose: Advanced orchestration patterns
    # Key Insight: Load for Generate-Review-Fix
    # ──────────────────────────────────────────────────────────────────
    if task.multi_step or task.generate_review_fix:
        return load("references/patterns.md")  # Generate-Review-Fix pattern

    # Default: SKILL.md has basics for common cases
```

---

## 3. 🛠️ HOW TO USE

### Verify Installation

Before using, confirm Gemini CLI is available:

```bash
command -v gemini || which gemini
```

If not found, install following Gemini CLI documentation.

### Basic Command Pattern

```bash
gemini "[prompt]" --yolo -o text 2>&1
```

**Key flags:**
- `--yolo` or `-y`: Auto-approve all tool calls (required for automation)
- `-o text`: Human-readable output (default for agent integration)
- `-o json`: Structured output with stats and metadata
- `-m gemini-2.5-flash`: Use faster model for simple tasks

### Critical Behavioral Notes

**YOLO Mode Limitation**: Auto-approves tool calls but does NOT prevent planning prompts. Gemini may still present plans and ask "Does this plan look good?"

**Mitigation**: Use forceful language in prompts:
- "Apply now"
- "Start immediately"
- "Do this without asking for confirmation"
- "Execute directly without planning"

**Rate Limits**: Free tier has 60 requests/min, 1000/day. CLI auto-retries with backoff. Expect messages like "quota will reset after Xs".

### Output Processing

**Text output** (`-o text`):
- Direct human-readable response
- Parse as plain text
- Best for agent integration

**JSON output** (`-o json`):
```json
{
  "response": "actual content here",
  "stats": {
    "models": { "tokens": {...} },
    "tools": { "byName": {...} }
  }
}
```

Parse `response` field for content; `stats` for usage metrics.

### Quick Reference Commands

**Code Generation:**
```bash
gemini "Create [description] with [features]. Output complete file content." --yolo -o text
```

**Code Review:**
```bash
gemini "Review [file] for: 1) features, 2) bugs/security issues, 3) improvements" -o text
```

**Bug Fixing:**
```bash
gemini "Fix these bugs in [file]: [list]. Apply fixes now." --yolo -o text
```

**Test Generation:**
```bash
gemini "Generate [Jest/pytest] tests for [file]. Focus on [areas]." --yolo -o text
```

**Documentation:**
```bash
gemini "Generate JSDoc for all functions in [file]. Output as markdown." --yolo -o text
```

**Architecture Analysis:**
```bash
gemini "Use codebase_investigator to analyze this project" -o text
```

**Web Research:**
```bash
gemini "What are the latest [topic]? Use Google Search." -o text
```

**Faster Model (Simple Tasks):**
```bash
gemini "[prompt]" -m gemini-2.5-flash -o text
```

### Error Handling

**Rate Limit Exceeded:**
- CLI auto-retries with backoff
- Use `-m gemini-2.5-flash` for lower priority tasks
- Run in background for long operations

**Command Failures:**
- Check JSON output for detailed error stats
- Verify Gemini is authenticated: `gemini --version`
- Check `~/.gemini/settings.json` for config issues

**Validation After Generation:**
Always verify Gemini's output:
- Check for security vulnerabilities (XSS, injection)
- Test functionality matches requirements
- Review code style consistency
- Verify dependencies are appropriate

### Integration Workflow

**Standard Generate-Review-Fix Cycle:**

```bash
# 1. Generate
gemini "Create [code]" --yolo -o text

# 2. Review (Gemini reviews its own work)
gemini "Review [file] for bugs and security issues" -o text

# 3. Fix identified issues
gemini "Fix [issues] in [file]. Apply now." --yolo -o text
```

**Background Execution:**

For long tasks, run in background and monitor:
```bash
gemini "[long task]" --yolo -o text 2>&1 &
# Monitor with BashOutput tool
```

### Gemini's Unique Capabilities

These tools are available only through Gemini:

1. **google_web_search** - Real-time internet search via Google
2. **codebase_investigator** - Deep architectural analysis
3. **save_memory** - Cross-session persistent memory

### Configuration

**Project Context (Optional):**

Create `.gemini/GEMINI.md` in project root for persistent context that Gemini will automatically read.

**Session Management:**
- List sessions: `gemini --list-sessions`
- Resume session: `echo "follow-up" | gemini -r [index] -o text`

---

## 4. 📖 RULES

### ✅ ALWAYS

**ALWAYS do these without asking:**

1. **ALWAYS verify Gemini CLI is installed before use**
   - Run `command -v gemini` to check availability
   - Inform user if installation needed

2. **ALWAYS use `--yolo` flag to auto-approve tool calls**
   - Required for automated workflows
   - Prevents interactive prompts blocking execution

3. **ALWAYS specify output format explicitly**
   - Use `-o text` for human-readable output (default)
   - Use `-o json` when parsing structured data needed

4. **ALWAYS use forceful language to prevent planning prompts**
   - Include "Apply now", "Start immediately", "Execute directly"
   - Prevents Gemini from asking for confirmation despite --yolo

5. **ALWAYS validate Gemini's generated code**
   - Check for security vulnerabilities (XSS, SQL injection, etc.)
   - Test functionality matches requirements
   - Review code style consistency
   - Verify dependencies are appropriate

6. **ALWAYS redirect stderr to stdout (2>&1)**
   - Captures all output including errors
   - Essential for debugging rate limits and failures

7. **ALWAYS monitor rate limits**
   - Free tier: 60 requests/min, 1000/day
   - Consider `-m gemini-2.5-flash` for lower priority tasks
   - Inform user when approaching limits

### ❌ NEVER

**NEVER do these:**

1. **NEVER use for simple, trivial tasks**
   - Overhead of subprocess execution not worth it
   - The agent can handle most tasks directly
   - Use only when second opinion or unique capabilities needed

2. **NEVER use for interactive refinement**
   - Gemini CLI is one-shot execution
   - Cannot maintain conversation context
   - Use the agent's native capabilities for iterative work

3. **NEVER skip output validation**
   - Generated code may have bugs or security issues
   - Always review before applying to production
   - Test functionality before committing

4. **NEVER assume rate limits won't apply**
   - Free tier limits: 60/min, 1000/day
   - CLI auto-retries but adds delays
   - Plan for rate limit handling in workflows

5. **NEVER ignore authentication errors**
   - Check `gemini --version` to verify authentication
   - Review `~/.gemini/settings.json` for config issues
   - User must authenticate before Gemini CLI works

6. **NEVER use when context preservation is critical**
   - Gemini CLI doesn't see the agent's conversation history
   - Each invocation is isolated
   - Use the agent directly when context matters

### ⚠️ ESCALATE IF

**Ask user when:**

1. **ESCALATE IF rate limits are repeatedly exceeded**
   - User may need to upgrade tier
   - Consider alternative approaches
   - May need to batch or throttle requests

2. **ESCALATE IF Gemini authentication fails**
   - User needs to run authentication setup
   - Check `~/.gemini/settings.json` configuration
   - May require API key or account setup

3. **ESCALATE IF generated code has critical security vulnerabilities**
   - XSS, SQL injection, command injection detected
   - User should review before applying
   - May need manual security review

4. **ESCALATE IF command failures persist after troubleshooting**
   - Installation issues beyond CLI verification
   - Network or API connectivity problems
   - Configuration errors requiring user intervention

5. **ESCALATE IF task requires conversation history**
   - Gemini can't access the agent's context
   - User should clarify if task can be isolated
   - Consider alternative approach handling directly

---

## 5. 🎓 SUCCESS CRITERIA

### Task Completion Checklist

**Gemini CLI Usage Complete When:**

- [ ] Gemini CLI installation verified (`command -v gemini`)
- [ ] Command executed successfully (exit code 0)
- [ ] Output received and parsed correctly
- [ ] Generated code validated for security vulnerabilities
- [ ] Functionality tested and matches requirements
- [ ] Code style reviewed for consistency with project standards
- [ ] Dependencies verified as appropriate and up-to-date
- [ ] Rate limits respected (no excessive retry loops)
- [ ] Output integrated into codebase or communicated to user

### Quality Gates

**Before marking task complete:**

- **Security**: No XSS, SQL injection, command injection, or OWASP Top 10 vulnerabilities
- **Functionality**: Code executes without errors and meets requirements
- **Style**: Code follows project conventions (naming, formatting, structure)
- **Dependencies**: All dependencies appropriate and justified
- **Testing**: Functionality verified through testing or demonstration

### Integration Success

**When using Gemini for code review:**
- All security issues identified and addressed
- All bugs identified and documented
- Improvement suggestions evaluated and applied/rejected with rationale

**When using Gemini for code generation:**
- Generated code compiles/executes without errors
- Meets all specified requirements
- Passes validation checks (security, style, functionality)

**When using Gemini for research:**
- Information is current and accurate
- Sources are relevant to the question
- Results are communicated clearly to user

---

## 6. 🔗 INTEGRATION POINTS

### Related Skills

**workflows-spec-kit**:
- `/cli:gemini` requires SpecKit integration for memory tracking
- Queries are saved to spec folder memory
- Use `/spec_kit:resume` to continue tracked work

**workflows-memory**:
- Gemini query responses auto-saved to spec memory
- Use `/memory:search` to find past Gemini results
- Semantic search across all saved contexts

**cli-codex**:
- Companion CLI skill for OpenAI Codex
- Use Codex for deep reasoning, Gemini for web search
- Both integrate with SpecKit for memory tracking

**workflows-code**:
- Use cli-gemini as optional verification step in Phase 3
- Get second opinion before browser testing
- Security review, architecture validation, performance optimization
- See [workflows-code](../workflows-code/SKILL.md) Section 3 "Phase 3: Verification - Alternative Verification: Gemini CLI"

### Tool Usage Guidelines

**Bash tool**:
- Execute all gemini commands
- Capture stdout and stderr (2>&1)
- Monitor background processes if needed

**Read tool**:
- Examine files before passing to Gemini
- Verify Gemini's output files
- Compare before/after changes

**Write tool**:
- Save Gemini's generated output to files
- Create configuration files for Gemini
- Write test results or analysis reports

**Grep/Glob tools**:
- Find files to analyze with Gemini
- Locate code patterns for review
- Search for security vulnerabilities Gemini identified

### Knowledge Base Dependencies

**Required**: None

**Optional** (create if needed):
- `code_standards.md` - Project-specific code standards to validate Gemini's generated code
- `security_guidelines.md` - Project-specific security guidelines for compliance checking

### External Tools

**Gemini CLI** (v0.16.0+):
- Installation: Follow Gemini CLI documentation
- Authentication: Required before first use
- Configuration: `~/.gemini/settings.json`

**Optional**: `.gemini/GEMINI.md` in project root for persistent context

---

## 7. 🔧 TROUBLESHOOTING

### Rate Limits

Gemini API enforces rate limits:
- **60 requests per minute** (short-term burst)
- **1000 requests per day** (daily quota)

**Symptoms:**
- Error: "Resource exhausted" or "429 Too Many Requests"
- Requests fail after burst of operations
- CLI shows "quota will reset after Xs"

**Solutions:**
1. **Manual throttling**: Add 1-second delays between requests
2. **Batch operations**: Group similar requests together
3. **Strategic use**: Reserve for complex analysis, not simple queries
4. **Monitor usage**: Track daily request count

**Example Throttling:**
```bash
# Instead of rapid-fire requests:
for file in *.ts; do
  gemini "code review $file"
done

# Add delays:
for file in *.ts; do
  gemini "code review $file"
  sleep 1  # 1-second delay
done
```

**Rate Limit Recovery:**
- **Minute limit**: Wait 60 seconds, then retry
- **Daily limit**: Wait until next day (UTC reset)
- **Monitoring**: Use `-o json` to see request stats

### Authentication Issues

**Symptom**: "Not authenticated" or "Invalid API key" errors

**Solutions:**
1. Check authentication: `gemini --version`
2. Re-authenticate if needed: Follow Gemini CLI setup docs
3. Verify config: `cat ~/.gemini/settings.json`

### Yolo Mode Not Working

**Symptom**: Gemini still asking for confirmation despite `--yolo` flag

**Cause**: Yolo auto-approves tool calls but NOT planning prompts

**Solution**: Use forceful language in prompts:
- "Apply now"
- "Start immediately"
- "Do this without asking for confirmation"
- "Execute directly without planning"

### Command Failures

**Symptom**: Commands fail or hang

**Debug steps:**
1. Check JSON output: `gemini "[prompt]" -o json`
2. Verify Gemini version: `gemini --version` (need v0.16.0+)
3. Test with simpler prompt first
4. Check stderr: `gemini "[prompt]" 2>&1`

### Output Not as Expected

**Common causes:**
- Model choice: Try `-m gemini-2.5-flash` for simpler tasks or default for complex
- Prompt clarity: Be more specific and directive
- Context missing: Use `.gemini/GEMINI.md` for project context

**Solution**: Iterate prompt with more explicit instructions

---

## 8. 🔗 SLASH COMMAND REFERENCE

### Command Comparison

| Feature | `/cli:gemini` | `/cli:gemini_quick` |
|---------|---------------|---------------------|
| SpecKit Integration | **Required** | None |
| Memory Save | **Mandatory** | None |
| Interactive Gates | 3 gates | None |
| Best Model | Default | Default |
| Use Case | Tracked research | Quick lookups |

### `/cli:gemini` Flow

```
User Invokes /cli:gemini [query]
    │
    ▼
┌─────────────────────────────────────┐
│ GATE 0: Query Input Validation      │
│ ├─ If empty: Prompt for query       │
│ └─ If provided: Store and continue  │
└─────────────────────────────────────┘
    │
    ▼
┌─────────────────────────────────────┐
│ GATE 1: Spec Folder Selection       │
│ ├─ A) Use active spec               │
│ ├─ B) Use existing spec folder      │
│ ├─ C) Create new spec folder        │
│ └─ D) Quick mode → Redirect         │
└─────────────────────────────────────┘
    │
    ▼
┌─────────────────────────────────────┐
│ GATE 2: Memory Context Loading      │
│ ├─ Search for related memories      │
│ └─ Load context if found            │
└─────────────────────────────────────┘
    │
    ▼
┌─────────────────────────────────────┐
│ Execute Gemini Query                │
│ gemini "[query]" --yolo -o text     │
└─────────────────────────────────────┘
    │
    ▼
┌─────────────────────────────────────┐
│ MANDATORY: Save to Memory           │
│ {spec}/memory/{timestamp}__gemini.md│
└─────────────────────────────────────┘
```

### `/cli:gemini_quick` Flow

```
User Invokes /cli:gemini_quick [query]
    │
    ▼
┌─────────────────────────────────────┐
│ Parse Query Type                    │
│ ├─ :review → Review mode            │
│ ├─ :generate → Generate mode        │
│ ├─ :analyze → codebase_investigator │
│ └─ :research → google_web_search    │
└─────────────────────────────────────┘
    │
    ▼
┌─────────────────────────────────────┐
│ Execute Immediately                 │
│ gemini "[prefix] [query]" --yolo    │
└─────────────────────────────────────┘
    │
    ▼
┌─────────────────────────────────────┐
│ Display Raw Output                  │
│ (No memory save, no tracking)       │
└─────────────────────────────────────┘
```

### Query Type Modifiers

| Modifier | Gemini Tool | Use Case |
|----------|-------------|----------|
| `:review` | — | Security audit, bug hunting |
| `:generate` | — | Create new code |
| `:analyze` | codebase_investigator | Architecture analysis |
| `:research` | google_web_search | Current web info |

### Example Usage

**Tracked queries (with memory):**
```bash
/cli:gemini What are the latest Next.js 15 features? :research
/cli:gemini Analyze the authentication architecture :analyze
/cli:gemini Review src/auth.ts for security issues :review
```

**Quick queries (no tracking):**
```bash
/cli:gemini_quick What is React Server Components?
/cli:gemini_quick Check this code :review
```

---

**Remember**: This skill operates as a research and analysis specialist. It combines real-time web grounding with deep codebase analysis for comprehensive problem solving.