# Hook Reference

Quick reference for all available Claude Code hooks.

---

## UserPromptSubmit (11 hooks)

Trigger: Before user prompts are processed

| Hook | Description |
|------|-------------|
| `inject-datetime.sh` | Injects current date/time into AI context |
| `workflows-save-context-trigger.sh` | Auto-saves conversation context on keywords or every 20 messages |
| `validate-skill-activation.sh` | Matches prompts to skills, displays recommendations |
| `orchestrate-skill-validation.sh` | Calculates complexity, emits parallel dispatch questions |
| `suggest-semantic-search.sh` | Suggests semantic search MCP for code exploration |
| `suggest-mcp-tools.sh` | Suggests MCP tools and Code Mode for external services |
| `suggest-prompt-improvement.sh` | Suggests prompt quality improvements |
| `enforce-spec-folder.sh` | Enforces spec folder selection for file modifications |
| `enforce-git-workspace-choice.sh` | Mandatory question for git workspace strategy |
| `enforce-verification.sh` | Blocks completion claims without verification evidence |
| `enforce-markdown-strict.sh` | Validates markdown structure, blocks critical violations |

---

## PreToolUse (9 hooks)

Trigger: Before tool execution

| Hook | Description |
|------|-------------|
| `check-pending-questions.sh` | Blocks all tools when mandatory question pending |
| `validate-bash.sh` | Blocks wasteful commands (large file reads, context bloat) |
| `validate-mcp-calls.sh` | Enforces Code Mode routing for MCP tools |
| `validate-dispatch-requirement.sh` | Requires parallel dispatch decision before Task tool |
| `enforce-markdown-pre.sh` | Blocks invalid markdown filenames before creation |
| `validate-spec-final.sh` | Final spec validation before file modification |
| `announce-task-dispatch.sh` | Announces agent dispatch with rich metadata |
| `warn-duplicate-reads.sh` | Detects duplicate Read/Grep/Glob operations |
| `enforce-semantic-search.sh` | Suggests semantic search for exploratory Glob/Grep |

---

## PostToolUse (11 hooks)

Trigger: After tool execution

| Hook | Description |
|------|-------------|
| `enforce-markdown-naming.sh` | Auto-renames markdown files to snake_case |
| `validate-post-response.sh` | Quality check reminders for edited code |
| `remind-cdn-versioning.sh` | CDN cache-busting reminders for JS/CSS changes |
| `skill-scaffold-trigger.sh` | Auto-creates references/ and assets/ when SKILL.md written |
| `suggest-cli-verification.sh` | Suggests browser testing for frontend changes |
| `track-file-modifications.sh` | Tracks file changes for scope detection |
| `verify-spec-compliance.sh` | Verifies modifications match active spec folder |
| `detect-scope-growth.sh` | Warns when file count exceeds 150% of baseline |
| `summarize-task-completion.sh` | Summarizes Task tool results with metrics |
| `validate-output-quality.sh` | Detects fluff, ambiguity, lazy lists in output |
| `cleanup-session.sh` | (misplaced - should be PostSessionEnd) |

---

## SubagentStop (1 hook)

Trigger: When sub-agent (Task tool) completes

| Hook | Description |
|------|-------------|
| `validate-subagent-output.sh` | Validates sub-agent output quality, CAN BLOCK bad output |

---

## PreCompact (2 hooks)

Trigger: Before context compaction

| Hook | Description |
|------|-------------|
| `prune-context.sh` | Deduplicates tool calls, reduces context size |
| `save-context-before-compact.sh` | Backs up conversation before compaction |

---

## PreSessionStart (1 hook)

Trigger: When session begins

| Hook | Description |
|------|-------------|
| `initialize-session.sh` | Initializes session state and markers |

---

## PostSessionEnd (1 hook)

Trigger: When session ends

| Hook | Description |
|------|-------------|
| `cleanup-session.sh` | Cleans up temporary files and stale markers |

---

## Exit Code Reference

| Code | Meaning |
|------|---------|
| `0` | Allow (hook passed) |
| `0*` | Allow but prompts user |
| `1` | Block (stops execution) |

---

## Quick Stats

- **Total hooks**: 36
- **Blocking hooks**: 8 (validate-bash, enforce-markdown-pre, enforce-markdown-strict, enforce-verification, check-pending-questions, validate-dispatch-requirement, validate-spec-final, validate-subagent-output)
- **Advisory hooks**: 28

---

**Version**: 1.0.0 | **Updated**: 2025-12-03
