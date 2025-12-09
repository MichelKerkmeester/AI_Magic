---
name: workflows-git
description: Git workflow orchestrator guiding developers through workspace setup, clean commits, and work completion across git-worktrees, git-commit, and git-finish skills
allowed-tools: [Read, Bash]
version: 1.0.0
---

<!-- Keywords: git-workflow, git-worktree, conventional-commits, branch-management, pull-request, commit-hygiene, workspace-isolation, version-control -->

# Git Workflows - Git Development Orchestrator

> Unified workflow guidance across workspace isolation, commit hygiene, and work completion.

---

## 1. 🎯 WHEN TO USE

### 📚 Navigation Guide

**This file (SKILL.md)**: Orchestrator overview, phase routing, workspace enforcement, and decision trees.

**Reference Files** (detailed workflows):
- [worktree_workflows.md](./references/worktree_workflows.md) – 7-step worktree creation workflow
- [commit_workflows.md](./references/commit_workflows.md) – 6-step commit workflow with Conventional Commits
- [finish_workflows.md](./references/finish_workflows.md) – 5-step completion workflow (merge/PR/cleanup)
- [shared_patterns.md](./references/shared_patterns.md) – Branch naming, git commands, conventions
- [quick_reference.md](./references/quick_reference.md) – One-page cheat sheet

**Assets** (templates):
- [commit_message_template.md](./assets/commit_message_template.md) – Conventional Commits format examples
- [pr_template.md](./assets/pr_template.md) – PR description template
- [worktree_checklist.md](./assets/worktree_checklist.md) – Worktree creation validation checklist

### When to Use This Orchestrator

Use this orchestrator when:
- Starting new git-based work
- Unsure which git skill to use
- Following complete git workflow (setup → work → complete)
- Looking for git best practices (branch naming, commit conventions)

**Orchestrates 3 workflow phases** (each configured as separate entries in `skill-rules.json`):
- **git-worktrees** - Create isolated git workspaces for parallel development
- **git-commit** - Professional commit workflow with Conventional Commits
- **git-finish** - Complete work with merge, PR, or cleanup options

**Architecture Note**: These are conceptual workflow phases, not separate skill directories. The hook system routes users to this skill based on intent keywords. See Navigation Guide above for reference files.

---

## 2. 🚨 WORKSPACE CHOICE ENFORCEMENT

**MANDATORY**: The AI must NEVER autonomously decide between creating a branch or worktree.

### Hook Enforcement

Git workspace strategy is enforced by the `enforce-git-workspace-choice.sh` UserPromptSubmit hook. When git workspace triggers are detected (new feature, create branch, worktree, etc.), the user MUST explicitly choose:

| Option | Description | Best For |
|--------|-------------|----------|
| **A) Create a new branch** | Standard branch on current repo | Quick fixes, small changes |
| **B) Create a git worktree** | Isolated workspace in separate directory | Parallel work, complex features |
| **C) Work on current branch** | No new branch created | Trivial changes, exploration |

### AI Behavior Requirements

1. **WAIT** for user to answer the workspace question before proceeding
2. **NEVER** assume which workspace strategy the user wants
3. **RESPECT** the user's choice throughout the workflow
4. If user has already answered this session, reuse their preference

### Override Phrases

Power users can bypass the question with explicit phrases:
- `"use branch"` / `"create branch"` → Branch selected
- `"use worktree"` / `"in a worktree"` → Worktree selected
- `"current branch"` / `"on this branch"` → Current branch selected

### Session Persistence

Once user chooses, their preference is stored for 1 hour. The hook won't re-ask unless:
- Session expires (1 hour)
- User explicitly overrides with a different phrase
- User starts a new Claude Code session

---

## 3. 🧭 SMART ROUTING

### Phase Detection
```
GIT WORKFLOW CONTEXT
    │
    ├─► Starting new work / need isolated workspace
    │   └─► PHASE 1: Workspace Setup (git-worktrees)
    │       └─► Load: worktree_workflows.md, worktree_checklist.md
    │
    ├─► Ready to commit changes
    │   └─► PHASE 2: Commit (git-commit)
    │       └─► Load: commit_workflows.md, commit_message_template.md
    │
    ├─► Work complete / ready to integrate
    │   └─► PHASE 3: Finish (git-finish)
    │       └─► Load: finish_workflows.md, pr_template.md
    │
    ├─► Need command reference / conventions
    │   └─► Load: shared_patterns.md
    │
    └─► Quick overview needed
        └─► Load: quick_reference.md
```

### Resource Router
```python
def route_git_resources(task):
    # ──────────────────────────────────────────────────────────────────
    # Phase 1: Workspace Setup (git-worktrees)
    # Purpose: Complete 7-step worktree creation workflow
    # Key Insight: Directory selection priority, safety verification, branch strategies
    # ──────────────────────────────────────────────────────────────────
    if task.needs_isolated_workspace or "worktree" in task.keywords:
        return load("references/worktree_workflows.md")  # 7-step creation workflow

    # ──────────────────────────────────────────────────────────────────
    # Phase 2: Commit Workflow (git-commit)
    # Purpose: Complete 6-step commit workflow
    # Key Insight: File categorization, artifact filtering, Conventional Commits
    # ──────────────────────────────────────────────────────────────────
    if task.has_staged_changes or "commit" in task.keywords:
        load("references/commit_workflows.md")  # 6-step commit workflow
        if task.needs_message_help:
            return load("assets/commit_message_template.md")  # Conventional Commits examples

    # ──────────────────────────────────────────────────────────────────
    # Phase 3: Completion/Integration (git-finish)
    # Purpose: Complete 5-step completion workflow
    # Key Insight: Test verification gate, 4 options (merge/PR/keep/discard)
    # ──────────────────────────────────────────────────────────────────
    if task.ready_to_integrate or "merge" in task.keywords or "pr" in task.keywords:
        load("references/finish_workflows.md")  # 5-step completion workflow
        if task.creating_pr:
            return load("assets/pr_template.md")  # PR description template

    # ──────────────────────────────────────────────────────────────────
    # Quick Reference
    # Purpose: One-page cheat sheet
    # Key Insight: Skill selection flowchart, essential commands
    # ──────────────────────────────────────────────────────────────────
    if task.needs_quick_reference:
        return load("references/quick_reference.md")  # one-page cheat sheet

    # ──────────────────────────────────────────────────────────────────
    # Shared Patterns
    # Purpose: Common git patterns and command reference
    # Key Insight: Branch naming, git commands, Conventional Commits format
    # ──────────────────────────────────────────────────────────────────
    if task.needs_command_reference or task.needs_conventions:
        return load("references/shared_patterns.md")

    # ──────────────────────────────────────────────────────────────────
    # Worktree Checklist
    # Purpose: Step-by-step worktree creation checklist
    # Key Insight: Validation checkpoints for workspace setup
    # ──────────────────────────────────────────────────────────────────
    if task.setting_up_worktree:
        return load("assets/worktree_checklist.md")  # step-by-step validation

# ══════════════════════════════════════════════════════════════════════
# STATIC RESOURCES (always available, not conditionally loaded)
# ══════════════════════════════════════════════════════════════════════
# assets/commit_message_template.md → Format guide with real-world examples
# assets/pr_template.md → Structured PR descriptions with examples
```

---

## 4. 🛠️ HOW TO USE

### Git Development Lifecycle Map

Git development flows through 3 phases:

**Phase 1: Workspace Setup** (Isolate your work)
- **git-worktrees** - Create isolated workspace with short-lived temp branches
- Prevents: Branch juggling, stash chaos, context switching
- Output: Clean workspace ready for focused development

**Phase 2: Work & Commit** (Make clean commits)
- **git-commit** - Analyze changes, filter artifacts, write Conventional Commits
- Prevents: Accidental artifact commits, unclear commit history
- Output: Professional commit history following conventions

**Phase 3: Complete & Integrate** (Finish the work)
- **git-finish** - Merge, create PR, or discard work (with tests gate)
- Prevents: Incomplete work merged, untested code integrated
- Output: Work successfully integrated or cleanly discarded

### Phase Transitions
- Setup → Work: Worktree created, ready to code
- Work → Complete: Changes committed, tests passing
- Complete → Setup: Work integrated, start next task

---

## 5. 🗺️ SKILL SELECTION DECISION TREE

**What are you doing?**

### Workspace Setup (Phase 1)
- **Starting new feature/fix?** → **git-worktrees**
  - Need isolated workspace for parallel work
  - Want clean separation from other branches
  - Avoid branch juggling and stash chaos
- **Quick fix on current branch?** → Skip to Phase 2 (commit directly)

### Work & Commit (Phase 2)
- **Ready to commit changes?** → **git-commit**
  - Analyze what changed (filter artifacts)
  - Determine single vs. multiple commits
  - Write Conventional Commits messages
  - Stage only public-value files
- **No changes yet?** → Continue coding, return when ready

### Complete & Integrate (Phase 3)
- **Tests pass, ready to integrate?** → **git-finish**
  - Choose: Merge locally, Create PR, Keep as-is, or Discard
  - Cleanup worktree (if used)
  - Verify final integration
- **Tests failing?** → Return to Phase 2 (fix and commit)

### Common Workflows

**Full Workflow** (new feature):
```
git-worktrees (create workspace) → Code → git-commit (commit changes) → git-finish (integrate)
```

**Quick Fix** (current branch):
```
Code → git-commit (commit fix) → git-finish (integrate)
```

**Parallel Work** (multiple features):
```
git-worktrees (feature A) → Code → git-commit
git-worktrees (feature B) → Code → git-commit
git-finish (feature A) → git-finish (feature B)
```

---

## 6. 💡 INTEGRATION EXAMPLES

### Example 1: New Authentication Feature

**Flow**:
1. **Setup**: git-worktrees → `.worktrees/auth-feature` with `temp/auth`
2. **Work**: Code OAuth2 flow → Run tests
3. **Commit**: git-commit → Stage auth files → `feat(auth): add OAuth2 login flow`
4. **Complete**: git-finish → Merge to main → Tests pass → Cleanup worktree
5. **Result**: ✅ Feature integrated, clean history, workspace removed

### Example 2: Quick Hotfix

**Flow**:
1. **Work**: Fix null reference bug on current branch
2. **Commit**: git-commit → Filter coverage reports → `fix(api): handle null user response`
3. **Complete**: git-finish → Create PR → Link to issue #123
4. **Result**: ✅ PR created with descriptive commit, ready for review

### Example 3: Parallel Features

**Flow**:
1. **Setup A**: git-worktrees → `.worktrees/feature-a`
2. **Setup B**: git-worktrees → `.worktrees/feature-b`
3. **Work**: Switch between terminals, code both features
4. **Commit A**: cd feature-a → git-commit → `feat(search): add filters`
5. **Commit B**: cd feature-b → git-commit → `feat(export): add CSV export`
6. **Complete A**: git-finish → Merge A
7. **Complete B**: git-finish → Merge B
8. **Result**: ✅ Two features developed in parallel, integrated sequentially

---

## 7. ⚡ QUICK REFERENCE

**Git Workflow Principles**:
```
ISOLATION: Use worktrees for parallel work
CLARITY: Write conventional commits with clear descriptions
QUALITY: Run tests before integration (git-finish gate)
CLEANUP: Remove worktrees after completion
```

**Remember**: This skill orchestrates three specialized workflows - Worktree Management, Commit Hygiene, and Work Completion. All integrate seamlessly for a professional git development lifecycle.