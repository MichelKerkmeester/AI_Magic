# Skills Reference

Skills are modular, reusable capabilities that can be invoked within workflows to perform specific tasks. They provide a standardized way to extend workflow functionality without duplicating logic.

---

## What Are Skills?

Skills are pre-defined operations that workflows can invoke using the `Skill` tool. They encapsulate common tasks like:

- **Context persistence** - Saving execution context for future sessions
- **Memory management** - Loading and storing session memory
- **File operations** - Standardized file handling patterns

Skills differ from commands in that:
- **Commands** are user-facing entry points (e.g., `/agent_router:workflow`)
- **Skills** are internal capabilities invoked by workflows programmatically

---

## Skill Invocation Pattern

Skills are invoked within workflow YAML files using the following pattern:

```yaml
tool_invocation:
  tool: Skill
  parameter: skill="skill-name"
  note: "Description of what the skill does"
  fallback: "Action if skill is unavailable"
```

### Example: Context Persistence

From `route_confirm.yaml` (lines 478-492):

```yaml
step_7_context_persistence:
  purpose: Save execution context for future sessions

  activities:
  - Invoke workflows-save-context skill (preferred method)
  - If skill available, use Skill tool with parameter skill="workflows-save-context"
  - Generate anchor tags for grep-able sections
  - Save context to spec folder memory/ if in spec folder context
  - Otherwise save to .claude/plans/ or appropriate location
  - If skill unavailable, continue without persistence (fallback)

  tool_invocation:
    tool: Skill
    parameter: skill="workflows-save-context"
    note: "Use the Skill tool to activate context saving functionality"
    fallback: "Continue without persistence if skill is unavailable"
```

---

## Available Skills

### `workflows-save-context`

**Purpose:** Persists workflow execution context to memory files for session continuity.

**What it does:**
1. Auto-generates HTML anchor tags for grep-able sections
2. Uses anchor format: `<!-- anchor: category-topic-spec -->`
3. Saves to spec folder `memory/` if spec folder context is active
4. Falls back to `.claude/plans/` or `agent_scope_root` otherwise
5. Preserves request summary, routing results, and execution decisions

**Invocation:**
```yaml
tool: Skill
parameter: skill="workflows-save-context"
```

**Fallback behavior:** If the skill is unavailable, the workflow continues without persistence. This ensures workflows don't fail when running in environments without skill support.

**Referenced in:**
- `z — Commands/agent_router/assets/route_auto.yaml` (lines 247, 252)
- `z — Commands/agent_router/assets/route_confirm.yaml` (lines 478-492)

---

## Skill vs Command Comparison

| Aspect | Commands | Skills |
|--------|----------|--------|
| **Entry point** | User-invoked via `/command-name` | Workflow-invoked via `Skill` tool |
| **Visibility** | Visible in command palette | Internal/hidden from users |
| **Location** | `.claude/commands/` or `.opencode/command/` | Registered in environment |
| **Arguments** | `$ARGUMENTS` from user input | `skill="skill-name"` parameter |
| **Scope** | Full workflow execution | Single focused operation |

---

## Creating Custom Skills

Skills are environment-provided capabilities. To add custom skills:

1. **Claude Desktop/Projects:** Register skills through the project configuration
2. **OpenCode:** Use custom tools or MCP servers for equivalent functionality

### Skill Design Principles

When designing skills:

- **Single responsibility** - Each skill should do one thing well
- **Graceful degradation** - Always provide fallback behavior
- **Minimal dependencies** - Skills should be self-contained
- **Clear naming** - Use `domain-action` pattern (e.g., `workflows-save-context`)

---

## Fallback Patterns

Skills may not be available in all environments. Workflows should always include fallback logic:

```yaml
activities:
  - Invoke skill-name skill (preferred method)
  - If skill unavailable, execute fallback behavior
  - Never fail workflow due to missing skill

tool_invocation:
  tool: Skill
  parameter: skill="skill-name"
  fallback: "Continue without [feature] if skill is unavailable"
```

### Fallback Examples

| Skill | Fallback Behavior |
|-------|-------------------|
| `workflows-save-context` | Continue without persistence |
| (future) `memory-load` | Start fresh without prior context |
| (future) `export-format` | Use default formatting |

---

## Environment Compatibility

| Environment | Skill Support | Notes |
|-------------|---------------|-------|
| Claude Desktop | Yes | Native skill support via Projects |
| Claude.ai (web) | Limited | Some skills available |
| OpenCode | Via MCP | Skills can be implemented as MCP tools |
| API Direct | No | Use fallback patterns |

---

## Best Practices

### For Workflow Authors

1. **Always define fallbacks** - Never assume skills are available
2. **Document skill purpose** - Include clear `note:` descriptions
3. **Test without skills** - Verify workflow completes when skills unavailable
4. **Use consistent naming** - Follow `domain-action` pattern

### For Skill Implementers

1. **Return clear status** - Success, failure, or partial completion
2. **Handle edge cases** - Missing files, permissions, etc.
3. **Log operations** - Enable debugging when needed
4. **Minimize side effects** - Be predictable and reversible

---

## Troubleshooting

### Skill Not Found

**Symptom:** Workflow reports skill unavailable

**Causes:**
- Environment doesn't support skills
- Skill not registered in current project
- Typo in skill name

**Resolution:**
- Check environment compatibility
- Verify skill registration
- Ensure workflow fallback is working

### Skill Execution Fails

**Symptom:** Skill invoked but operation fails

**Causes:**
- Missing permissions
- Invalid parameters
- External dependency unavailable

**Resolution:**
- Check skill error message
- Verify prerequisites
- Use fallback behavior

---

## Related Documentation

- `z — Commands/agent_router/workflow.md` - Agent Router workflow using skills
- `z — Commands/agent_router/assets/route_auto.yaml` - Autonomous mode with skill invocation
- `z — Commands/agent_router/assets/route_confirm.yaml` - Interactive mode with skill invocation
