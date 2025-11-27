---
description: Create a detailed implementation plan with parallel exploration before any code changes
model: opus
argument-hint: <task description>
allowed-tools: Read, Write, Edit, Glob, Grep, Task, AskUserQuestion
---

# Implementation Plan

Create comprehensive implementation plans using parallel exploration agents to thoroughly analyze the codebase before any code changes.

---

## Purpose

Enter PLANNING MODE to create detailed, verified implementation plans. This command spawns multiple Explore agents in parallel to analyze different aspects of the codebase, then synthesizes their findings into a structured plan that must be approved before implementation begins.

---

## Contract

**Inputs:** `$ARGUMENTS` — Task description (REQUIRED)
**Outputs:** Plan file at `.claude/plans/[task-name].md` + `STATUS=<OK|FAIL|CANCELLED>`

---

## Instructions

Execute the following phases:

### Phase 1: Task Understanding

1. **Parse and validate input:**
   - Extract task description from `$ARGUMENTS`
   - If task is unclear or empty, use AskUserQuestion to clarify
   - If still unclear: `STATUS=FAIL ERROR="Task description required"`

2. **State your understanding:**
   - Clearly articulate what the task requires
   - Identify any ambiguities that need clarification

### Phase 2: Parallel Exploration (Sonnet Agents)

3. **Spawn multiple Explore agents in parallel** using Task tool with `subagent_type='Explore'` and `model: 'sonnet'`:

   | Agent | Focus | Purpose | Model |
   |-------|-------|---------|-------|
   | Architecture Explorer | Project structure, entry points, component connections | Understand system architecture | sonnet |
   | Feature Explorer | Similar features, related patterns | Find reusable patterns | sonnet |
   | Dependency Explorer | Imports, modules, affected areas | Identify integration points | sonnet |
   | Test Explorer | Test patterns, testing infrastructure | Understand verification approach | sonnet |

   **Important:** All Explore agents MUST specify `model: "sonnet"` in the Task tool call. This ensures fast, cost-effective exploration while Opus orchestrates and synthesizes.

4. **Agent spawn template:**
   ```typescript
   // Example Task tool call for each agent
   {
     "subagent_type": "Explore",
     "model": "sonnet",  // REQUIRED - use sonnet for all exploration
     "description": "Architecture exploration",
     "prompt": "Explore the codebase to find [specific aspect]. Return:\n1. Your hypothesis about how [aspect] works\n2. Full paths to all relevant files (e.g., /path/to/file.ts:lineNumber)\n3. Any patterns you noticed\n\nDo NOT draw conclusions - just report findings. The main agent will verify."
   }
   ```

### Phase 3: Hypothesis Verification (Opus Review)

5. **Verify agent findings** (Opus synthesizes and validates):
   - Read each file identified by Sonnet Explore agents
   - Verify or refute each hypothesis with deep reasoning
   - Cross-reference findings across agents for consistency
   - Build complete mental model of:
     - Current architecture
     - Affected components
     - Integration points
     - Potential risks
   - Resolve any conflicting hypotheses from different agents

### Phase 4: Plan Creation

6. **Create plan file** at `.claude/plans/[task-name].md`:

   ```markdown
   # Implementation Plan: [Task Title]

   Created: [Date]
   Status: PENDING APPROVAL

   ## Summary
   [2-3 sentences describing what will be accomplished]

   ## Scope
   ### In Scope
   - [List what will be changed]

   ### Out of Scope
   - [List what will NOT be changed]

   ## Prerequisites
   - [Any requirements before starting]

   ## Implementation Phases

   ### Phase 1: [Phase Name]
   **Objective**: [What this phase accomplishes]

   **Files to Modify**:
   - `path/to/file.ts` - [What changes]

   **New Files to Create**:
   - `path/to/new.ts` - [Purpose]

   **Steps**:
   1. [Detailed step]
   2. [Detailed step]

   **Verification**:
   - [ ] [How to verify this phase works]

   ### Phase 2: [Phase Name]
   [Same structure]

   ## Testing Strategy
   - [Unit tests to add/modify]
   - [Integration tests]
   - [Manual testing steps]

   ## Rollback Plan
   - [How to undo changes if needed]

   ## Risks and Mitigations
   | Risk | Likelihood | Impact | Mitigation |
   |------|------------|--------|------------|
   | [Risk] | Low/Med/High | Low/Med/High | [How to mitigate] |

   ## Open Questions
   - [Any unresolved questions for the user]

   ---
   **USER: Please review this plan. Edit any section directly, then confirm to proceed.**
   ```

### Phase 5: User Confirmation

7. **Request approval:**
   - Inform user of plan location
   - Ask them to review and edit if needed
   - Wait for explicit confirmation
   - DO NOT write implementation files until confirmed

8. **Return status:**
   - If plan created and awaiting review: `STATUS=OK ACTION=plan_created PATH=[path]`
   - If user rejects: `STATUS=CANCELLED ACTION=user_rejected`

### Phase 6: Plan Re-read

9. **After user confirms:**
   - Re-read the plan file completely (user may have edited it)
   - Note any changes the user made
   - Acknowledge the changes before proceeding
   - Begin implementation following the plan exactly

---

## Failure Recovery

| Failure Type | Recovery Action |
|--------------|-----------------|
| Task unclear | Use AskUserQuestion to clarify |
| Explore agents find nothing | Expand search scope, try different patterns |
| Conflicting findings | Document both perspectives, ask user to decide |
| User rejects plan | Revise based on feedback, resubmit |
| Cannot create plan file | Check permissions, use alternative path |

---

## Error Handling

| Condition | Action |
|-----------|--------|
| Empty `$ARGUMENTS` | Prompt: "Please describe the task you want to plan" |
| Explore agents timeout | Continue with available results, note gaps |
| Plan file exists | Ask to overwrite or create new version |

---

## Example Usage

### Basic Planning
```bash
/plan_claude Add user authentication with OAuth2
```

### Complex Feature
```bash
/plan_claude Implement real-time collaboration with conflict resolution
```

### Refactoring Task
```bash
/plan_claude Migrate payment processing from REST to GraphQL
```

---

## Example Output

```
🔍 Planning Mode Activated (Opus Orchestrator)

Task: Add user authentication with OAuth2

📊 Spawning Sonnet Explore Agents...
  ├─ [sonnet] Architecture Explorer: analyzing project structure...
  ├─ [sonnet] Feature Explorer: finding auth patterns...
  ├─ [sonnet] Dependency Explorer: mapping imports...
  └─ [sonnet] Test Explorer: reviewing test infrastructure...

✅ Exploration Complete (4 sonnet agents, 23 files identified)

🔬 Opus Verification Phase...
  ├─ Verifying architecture hypotheses...
  ├─ Cross-referencing agent findings...
  ├─ Resolving 2 conflicting hypotheses...
  └─ Building complete mental model...

📝 Creating Implementation Plan (Opus)...

Plan created at: .claude/plans/oauth2-auth.md

Please review the plan and confirm to proceed.
Options:
  - Review and edit the plan file directly
  - Reply "confirm" to proceed with implementation
  - Reply "cancel" to abort

STATUS=OK ACTION=plan_created PATH=.claude/plans/oauth2-auth.md
```

---

## Notes

- **Critical Rules:**
  - NEVER skip the exploration phase
  - NEVER write implementation code during planning
  - NEVER assume - verify by reading files
  - ALWAYS get user confirmation before implementing
  - ALWAYS re-read the plan after user confirms (they may have edited it)

- **Plan Quality:**
  - Must be detailed enough for another developer to follow
  - Each phase should be independently verifiable
  - Include rollback instructions for safety

- **Model Hierarchy (Orchestrator + Workers):**

  | Role | Model | Responsibility |
  |------|-------|----------------|
  | **Orchestrator** | `opus` | Understands task, dispatches agents, verifies hypotheses, synthesizes findings, creates plan |
  | **Explore Agents** | `sonnet` | Fast parallel exploration, file discovery, pattern identification, hypothesis generation |

  - Opus provides deep reasoning for verification and plan creation
  - Sonnet provides fast, cost-effective exploration (4 agents in parallel)
  - All Task tool calls for Explore agents MUST include `model: "sonnet"`
  - This hierarchy balances quality (Opus review) with speed (Sonnet exploration)

- **Integration:**
  - Works with spec folder system for documentation
  - Plans can feed into `/spec_kit:implement` workflo