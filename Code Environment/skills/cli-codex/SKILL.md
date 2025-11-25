---
name: cli-codex
description: Wield OpenAI's Codex CLI as a powerful auxiliary tool for code generation, review, analysis, and parallel processing. Use when tasks benefit from a second AI perspective, alternative implementation approaches, or specialized code generation. Also use when user explicitly requests Codex operations.
allowed-tools: [Bash, Read, Write, Grep, Glob]
version: 1.0.0
---

# Codex CLI Integration Skill

Enable Claude Code to effectively orchestrate OpenAI Codex CLI (v0.58.0+) with GPT-5.1 Codex for code generation, review, analysis, and specialized tasks requiring a second AI perspective.

---

## 1. 🎯 WHEN TO USE

### 📚 Navigation Guide

**This file (SKILL.md)**: Core workflow and usage patterns

**Reference Files**:
- [patterns.md](./references/patterns.md) - Common usage patterns and workflows
- [reference.md](./references/reference.md) - Complete CLI command reference
- [templates.md](./references/templates.md) - Prompt templates and examples
- [tools.md](./references/tools.md) - Codex-specific tools and capabilities

### When to Use

### Ideal Use Cases

**1. Second Opinion / Cross-Validation**
- Code review after writing code (different AI perspective)
- Security audit with alternative analysis
- Finding bugs Claude might have missed
- Validating architectural decisions

**2. Alternative Implementation Approaches**
- Compare different solution strategies
- Get alternative design patterns
- Explore different algorithmic approaches
- Evaluate trade-offs between implementations

**3. Parallel Processing**
- Offload tasks while continuing other work
- Run multiple code generations simultaneously
- Background test generation
- Concurrent analysis of multiple files

**4. Specialized Generation**
- Test suite generation
- Type definitions and interfaces
- Boilerplate code creation
- Code translation between languages

**5. Reasoning-Heavy Tasks**
- Complex algorithm design
- Architecture analysis
- Performance optimization strategies
- Deep code understanding (Codex shows reasoning process)

**6. Explicit User Request**
- User directly asks to use Codex
- User wants comparison between Claude and Codex approaches
- User requests specific Codex features

### When NOT to Use

**Skip this skill when:**
- Simple, quick tasks (overhead not worth it)
- Tasks requiring immediate response (Codex takes longer)
- Context is already loaded and understood by Claude
- Interactive refinement requiring conversation
- Task needs access to Claude's full conversation history
- Budget/cost constraints (OpenAI API costs)


---

## 2. 🗂️ REFERENCES

### Core Framework
| Document | Purpose | Key Insight |
|----------|---------|-------------|
| **Cli Codex - Main Workflow** | Core capability and execution pattern | **Specialized auxiliary tool integration** |

### References
| Document | Purpose | Key Insight |
|----------|---------|-------------|
| **references/patterns.md** | Common Codex CLI usage patterns and workflows | Load for standard workflow examples |
| **references/reference.md** | Complete CLI command reference with all flags and options | Load for command syntax and options |
| **references/templates.md** | Prompt templates and examples for different use cases | Load for copy-paste prompt starters |
| **references/tools.md** | Codex-specific tools documentation (sandbox modes, session management) | Load when using Codex's specialized features |

### Smart Routing Logic

```yaml
use_case_routing:
  explicit_request:
    resource: reference.md
    action: verify_codex_installed

  reasoning_heavy:
    resource: tools.md
    model: codex-reasoning

  code_review:
    resource: templates.md
    template: code_review_template.md

  architecture_analysis:
    resource: templates.md
    template: architecture_analysis_template.md

  alternative_approach:
    resource: patterns.md
    action: compare_implementations

  parallel_processing:
    execution: background
    monitor: true

  simple_task:
    action: handle_directly_with_claude

  specialized_generation:
    resources: [templates.md, tools.md]
    types: [tests, types, refactoring]
    validation: sandbox_required
```

---

## 3. 🛠️ HOW TO USE

### Verify Installation

Before using, confirm Codex CLI is available:

```bash
command -v codex || which codex
```

If not found, user needs to install Codex CLI.

### Basic Command Pattern

```bash
codex exec "[prompt]" --full-auto 2>&1
```

**Key flags:**
- `--full-auto`: Convenience alias for sandboxed auto-execution (sets `-a on-request` + `-s workspace-write`)
- `-s <mode>`: Sandbox mode (`read-only`, `workspace-write`, `danger-full-access`)
- `-m <model>`: Model selection (default: `gpt-5.1-codex`)
- `--json`: Output as JSONL for programmatic parsing
- `-o <file>`: Write last message to file
- `-C <dir>`: Set working directory
- `--skip-git-repo-check`: Allow running outside git repo

### Critical Behavioral Notes

**Reasoning Display**: Codex shows a "thinking" section before responses, providing insight into its reasoning process. This is valuable for understanding complex decisions.

**Spec Folder Awareness**: Codex CLI (v0.58.0+) is trained to respect documentation requirements similar to Claude Code. It may ask for spec folders before generating code.

**Session Management**: Each `codex exec` is independent. Use `codex resume` to continue previous sessions.

**Output Format**: Standard output includes metadata header with:
- Working directory
- Model used
- Provider (OpenAI)
- Approval policy
- Sandbox mode
- Reasoning effort level
- Session ID
- Token usage

### Output Processing

**Text output** (default):
```
OpenAI Codex v0.58.0 (research preview)
--------
workdir: /path/to/project
model: gpt-5.1-codex
provider: openai
approval: never
sandbox: workspace-write
reasoning effort: high
reasoning summaries: auto
session id: <uuid>
--------
user
[your prompt]

thinking
[reasoning process]

codex
[response]

tokens used
[count]
```

**JSON output** (`--json`):
- JSONL format (newline-delimited JSON events)
- Parse for events, status, and final response
- Useful for automation and monitoring

### Quick Reference Commands

**Code Generation:**
```bash
codex exec "Create [description] with [features]. Output complete code." --full-auto 2>&1
```

**Code Review:**
```bash
codex exec "Review [file] for: 1) features, 2) bugs/security issues, 3) improvements" 2>&1
```

**Bug Fixing:**
```bash
codex exec "Fix these bugs in [file]: [list]. Apply fixes now." --full-auto 2>&1
```

**Test Generation:**
```bash
codex exec "Generate [Jest/pytest] tests for [file]. Focus on [areas]." --full-auto 2>&1
```

**Type Definitions:**
```bash
codex exec "Generate TypeScript types for [API/schema]." --full-auto 2>&1
```

**Code Translation:**
```bash
codex exec "Translate this [language] code to [target language]: [code]" 2>&1
```

**Refactoring:**
```bash
codex exec "Refactor [file] to improve [aspect] while maintaining functionality." --full-auto 2>&1
```

**Architecture Analysis:**
```bash
codex exec "Analyze the architecture of [project/file] and explain [aspects]." 2>&1
```

**Performance Optimization:**
```bash
codex exec "Suggest performance optimizations for [code/file]." 2>&1
```

**Session Resume:**
```bash
codex resume --last "[follow-up prompt]" 2>&1
```

**Different Model:**
```bash
codex exec "[prompt]" -m o3-mini 2>&1
```

**Read-Only Sandbox (Safe Mode):**
```bash
codex exec "[prompt]" -s read-only 2>&1
```

### Sandbox Modes

**1. read-only** (Safest)
- No file modifications allowed
- Only reading and analysis
- Use for: Reviews, analysis, planning

**2. workspace-write** (Recommended)
- Can modify files in working directory
- Can write to `/tmp` and `$TMPDIR`
- Use for: Most code generation tasks

**3. danger-full-access** (Use with caution)
- Full system access
- No sandboxing restrictions
- Use for: System-level tasks only when necessary

### Approval Policies

**Note**: Available in `codex resume` command, not `codex exec`

- **never**: No approval needed (auto-execute all commands)
- **untrusted**: Only trusted commands auto-execute
- **on-failure**: Ask approval only if command fails
- **on-request**: Model decides when to ask

### Error Handling

**Authentication Errors:**
- Check `codex --version` for auth status
- User needs to configure OpenAI API access

**Command Failures:**
- Use `--json` for detailed error information
- Check stderr output (captured via `2>&1`)
- Verify working directory with `-C` flag

**Rate Limits:**
- OpenAI API has rate limits (varies by tier)
- No auto-retry like some CLIs
- Space out requests or batch operations

**Validation After Generation:**
Always verify Codex's output:
- Check for security vulnerabilities (XSS, injection)
- Test functionality matches requirements
- Review code style consistency
- Verify dependencies are appropriate

### Integration Workflow

**Standard Generate-Review-Fix Cycle:**

```bash
# 1. Generate code
codex exec "Create [feature]" --full-auto 2>&1

# 2. Review (can use Claude or Codex)
# Option A: Codex reviews its own work
codex exec "Review the code in [file] for bugs and security issues" 2>&1

# Option B: Claude reviews Codex's work
# [Use Claude's native capabilities]

# 3. Fix identified issues
codex exec "Fix [issues] in [file]. Apply changes." --full-auto 2>&1
```

**Background Execution:**

For long tasks, run in background:
```bash
codex exec "[long task]" --full-auto 2>&1 &
# Monitor output or use BashOutput tool
```

**Session Continuity:**

For multi-turn workflows:
```bash
# First interaction
codex exec "Analyze [codebase]" 2>&1
# Note the session id from output

# Resume with follow-up
codex resume [session-id] "Now generate [feature] based on analysis" 2>&1

# Or resume most recent
codex resume --last "Continue with [next step]" 2>&1
```

### Configuration

**Project Context (Optional):**

Create `~/.codex/config.toml` for persistent settings:
```toml
model = "gpt-5.1-codex"
model_reasoning_effort = "high"

[projects."/path/to/project"]
trust_level = "trusted"
```

**Session Management:**
- Resume last session: `codex resume --last`
- Resume specific session: `codex resume [session-id]`

---

## 4. 📖 RULES

### ✅ ALWAYS

**ALWAYS do these without asking:**

1. **ALWAYS verify Codex CLI is installed before use**
   - Run `command -v codex` to check availability
   - Inform user if installation needed

2. **ALWAYS use `--full-auto` for automated workflows**
   - Sets safe sandbox mode (workspace-write)
   - Sets reasonable approval policy (on-request)
   - Prevents interactive prompts

3. **ALWAYS redirect stderr to stdout (2>&1)**
   - Captures all output including errors
   - Essential for debugging and error handling
   - Allows complete output analysis

4. **ALWAYS validate Codex-generated code**
   - Check for security vulnerabilities (OWASP Top 10)
   - Test functionality matches requirements
   - Review code style consistency
   - Verify dependencies are appropriate
   - Never blindly apply generated code

5. **ALWAYS use appropriate sandbox mode**
   - Default to `workspace-write` for most tasks
   - Use `read-only` for analysis-only tasks
   - Only use `danger-full-access` when explicitly necessary

6. **ALWAYS capture and parse output metadata**
   - Session ID for resume/debugging
   - Token usage for cost tracking
   - Model and sandbox settings for verification
   - Reasoning process for understanding decisions

7. **ALWAYS respect OpenAI API rate limits**
   - Space out requests when running multiple commands
   - Consider batching operations
   - Monitor for rate limit errors

### ❌ NEVER

**NEVER do these:**

1. **NEVER use for simple, trivial tasks**
   - Overhead of subprocess execution not worth it
   - Claude can handle most tasks directly
   - Use only when second opinion or unique capabilities needed

2. **NEVER use for interactive refinement**
   - Codex exec is one-shot execution
   - Use `codex resume` for multi-turn, but limited
   - Use Claude's native capabilities for iterative work

3. **NEVER skip output validation**
   - Generated code may have bugs or security issues
   - Always review before applying to production
   - Test functionality before committing

4. **NEVER assume authentication is configured**
   - Check `codex --version` first time
   - User must have OpenAI API access configured
   - Escalate authentication errors immediately

5. **NEVER ignore sandbox mode implications**
   - `danger-full-access` is dangerous
   - `read-only` prevents file modifications
   - `workspace-write` is safe default

6. **NEVER use when context preservation is critical**
   - Codex exec doesn't see Claude's conversation history
   - Each invocation is isolated
   - Use Claude directly when context matters

### ⚠️ ESCALATE IF

**Ask user when:**

1. **ESCALATE IF authentication fails**
   - User needs to configure OpenAI API access
   - Cannot proceed without valid credentials
   - Provide setup instructions

2. **ESCALATE IF generated code has critical security vulnerabilities**
   - XSS, SQL injection, command injection detected
   - User should review before applying
   - May need manual security review

3. **ESCALATE IF command failures persist**
   - Multiple failed attempts
   - Unclear error messages
   - May require user intervention

4. **ESCALATE IF task requires conversation history**
   - Codex can't access Claude's context
   - User should clarify if task can be isolated
   - Consider alternative approach using Claude

5. **ESCALATE IF full system access requested**
   - User requesting `danger-full-access` mode
   - Confirm they understand security implications
   - Verify necessity of elevated permissions

---

## 5. 🎓 SUCCESS CRITERIA

### Task Completion Checklist

**Codex CLI Usage Complete When:**

- [ ] Codex CLI installation verified (`command -v codex`)
- [ ] Command executed successfully (clean output received)
- [ ] Output parsed and metadata captured (session ID, tokens)
- [ ] Generated code validated for security vulnerabilities
- [ ] Functionality tested and matches requirements
- [ ] Code style reviewed for consistency with project standards
- [ ] Dependencies verified as appropriate
- [ ] Output integrated into codebase or communicated to user

### Quality Gates

**Before marking task complete:**

- **Security**: No XSS, SQL injection, command injection, or OWASP Top 10 vulnerabilities
- **Functionality**: Code executes without errors and meets requirements
- **Style**: Code follows project conventions (naming, formatting, structure)
- **Dependencies**: All dependencies appropriate and justified
- **Testing**: Functionality verified through testing or demonstration

### Integration Success

**When using Codex for code review:**
- All security issues identified and addressed
- All bugs identified and documented
- Improvement suggestions evaluated and applied/rejected with rationale

**When using Codex for code generation:**
- Generated code compiles/executes without errors
- Meets all specified requirements
- Passes validation checks (security, style, functionality)

**When using Codex for architecture analysis:**
- Analysis is comprehensive and accurate
- Recommendations are actionable
- Reasoning process is clear and logical

---

## 6. 🔗 INTEGRATION POINTS

### Hook System Integration

**N/A** - cli-codex is invoked directly via Bash tool, not integrated into hook system.

### Related Skills

**workflows-code**:
- Use cli-codex as optional verification step in Phase 3
- Get second opinion before browser testing
- Security review, architecture validation, performance optimization
- Pattern: Claude implements → Codex reviews → Fix issues → Test

**code-review** (if exists):
- Use cli-codex for second-opinion code reviews
- Complement Claude's review with Codex's perspective
- Identify issues Claude may have missed

**bug-hunting** (if exists):
- Leverage Codex's alternative analysis perspective
- Cross-validate bug identification
- Find edge cases through different reasoning

**test-generation** (if exists):
- Use Codex to generate comprehensive test suites
- Parallel test generation while Claude works on implementation
- Alternative test approaches for coverage

### Tool Usage Guidelines

**Bash tool**:
- Execute all codex commands
- Capture stdout and stderr (2>&1)
- Monitor background processes if needed

**Read tool**:
- Examine files before passing to Codex
- Verify Codex's output files
- Compare before/after changes

**Write tool**:
- Save Codex's generated output to files
- Create configuration files for Codex
- Write test results or analysis reports

**Grep/Glob tools**:
- Find files to analyze with Codex
- Locate code patterns for review
- Search for security vulnerabilities Codex identified

### Knowledge Base Dependencies

**Required**: None

**Optional**:
- `.claude/knowledge/code_standards.md` - Use to validate Codex's generated code against project standards
- `.claude/knowledge/security_guidelines.md` - Use to check Codex's code for security compliance

### External Tools

**Codex CLI** (v0.58.0+):
- Installation: User must install (not automated)
- Authentication: OpenAI API access required
- Configuration: `~/.codex/config.toml`

**Optional**: MCP servers can be configured in Codex config

---

**Remember**: This skill operates as a specialized auxiliary intelligence. It provides alternative perspectives, parallel processing, and specialized code generation to enhance development.