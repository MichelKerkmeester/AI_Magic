---
name: workflows-git
description: Git workflow orchestrator guiding developers through workspace setup, clean commits, and work completion across git-worktrees, git-commit, and git-finish skills
allowed-tools: [Read, Bash]
version: 1.0.0
---

# Git Workflows - Git Development Orchestrator

> Unified workflow guidance across workspace isolation, commit hygiene, and work completion.

---

## 1. 🎯 WHEN TO USE

### 📚 Navigation Guide

**This file (SKILL.md)**: Essential overview and navigation to specialized workflows

**Reference Files** (detailed documentation):
- [worktree_workflows.md](./references/worktree_workflows.md) – Phase 1: Complete worktree creation workflow
- [commit_workflows.md](./references/commit_workflows.md) – Phase 2: Professional commit workflow
- [finish_workflows.md](./references/finish_workflows.md) – Phase 3: Work completion and integration
- [shared_patterns.md](./references/shared_patterns.md) – Git commands, conventions, common patterns
- [quick_reference.md](./references/quick_reference.md) – One-page cheat sheet

**Assets** (templates and checklists):
- [commit_message_template.md](./assets/commit_message_template.md) – Conventional Commits examples
- [pr_template.md](./assets/pr_template.md) – Pull request templates
- [worktree_checklist.md](./assets/worktree_checklist.md) – Step-by-step worktree creation

### When to Use This Orchestrator

Use this orchestrator when:
- Starting new git-based work
- Unsure which git skill to use
- Following complete git workflow (setup → work → complete)
- Looking for git best practices (branch naming, commit conventions)

**Orchestrates 3 workflow phases** (configured in `skill-rules.json`, activated via hook keyword matching):
- **git-worktrees** - Create isolated git workspaces for parallel development
- **git-commit** - Professional commit workflow with Conventional Commits
- **git-finish** - Complete work with merge, PR, or cleanup options

**Note**: These are workflow phases within this orchestrator, not separate skill directories. Each phase has detailed documentation in the `references/` folder. The hook system activates them based on user intent keywords.

---

## 2. 🗂️ REFERENCES

### Core Framework & Workflow Phases
| Document                             | Purpose                                    | Key Insight                                              |
| ------------------------------------ | ------------------------------------------ | -------------------------------------------------------- |
| **Git Workflows - Phase 1: Setup**   | Workspace isolation via git-worktrees      | **Parallel work without branch juggling or stash chaos** |
| **Git Workflows - Phase 2: Commit**  | Professional commit hygiene via git-commit | **Conventional Commits with artifact filtering**         |
| **Git Workflows - Phase 3: Complete** | Work integration via git-finish            | **Tests gate + 4 structured completion options**         |

### Bundled Resources
| Document                              | Purpose                                         | Key Insight                                                         |
| ------------------------------------- | ----------------------------------------------- | ------------------------------------------------------------------- |
| **references/worktree_workflows.md**  | Complete 7-step worktree creation workflow      | Directory selection priority, safety verification, branch strategies |
| **references/commit_workflows.md**    | Complete 6-step commit workflow                 | File categorization, artifact filtering, Conventional Commits       |
| **references/finish_workflows.md**    | Complete 5-step completion workflow             | Test verification gate, 4 options (merge/PR/keep/discard)           |
| **references/shared_patterns.md**     | Common git patterns and command reference       | Branch naming, git commands, Conventional Commits format            |
| **references/quick_reference.md**     | One-page cheat sheet                            | Skill selection flowchart, essential commands                       |
| **assets/commit_message_template.md** | Conventional Commits examples                   | Format guide with real-world examples                               |
| **assets/pr_template.md**             | Pull request templates                          | Structured PR descriptions with examples                            |
| **assets/worktree_checklist.md**      | Step-by-step worktree creation checklist        | Validation checkpoints for workspace setup                          |

### Smart Routing Logic

```yaml
git_workflow:
  phase_1_setup:
    resource: worktree_workflows.md
    action: create_isolated_workspace

  phase_2_commit:
    resource: commit_workflows.md
    actions:
      - analyze_changes
      - filter_artifacts
      - create_conventional_commit

  phase_3_finish:
    resource: finish_workflows.md
    actions:
      - run_tests
      - choose_integration_method
    on_test_failure: return_to_phase_2
    integration_options:
      - merge
      - pr
      - keep
      - discard
```

---

## 3. 🛠️ HOW TO USE

### Git Development Lifecycle Map

Git development flows through 3 phases:

**Phase 1: Workspace Setup** (Isolate your work)
- **git-worktrees** - Create isolated workspace with short-lived temp branches
- Prevents: Branch juggling, stash chaos, context switching
- Output: Clean workspace ready for focused development
- **See**: [worktree_workflows.md](./references/worktree_workflows.md)

**Phase 2: Work & Commit** (Make clean commits)
- **git-commit** - Analyze changes, filter artifacts, write Conventional Commits
- Prevents: Accidental artifact commits, unclear commit history
- Output: Professional commit history following conventions
- **See**: [commit_workflows.md](./references/commit_workflows.md)

**Phase 3: Complete & Integrate** (Finish the work)
- **git-finish** - Merge, create PR, or discard work (with tests gate)
- Prevents: Incomplete work merged, untested code integrated
- Output: Work successfully integrated or cleanly discarded
- **See**: [finish_workflows.md](./references/finish_workflows.md)

### Phase Transitions
- Setup → Work: Worktree created, ready to code
- Work → Complete: Changes committed, tests passing
- Complete → Setup: Work integrated, start next task

---

## 4. 🗺️ SKILL SELECTION DECISION TREE

**What are you doing?**

### Workspace Setup (Phase 1)
- **Starting new feature/fix?** → **git-worktrees**
  - Need isolated workspace for parallel work
  - Want clean separation from other branches
  - Avoid branch juggling and stash chaos
  - **See**: [worktree_workflows.md](./references/worktree_workflows.md) for complete 7-step workflow
- **Quick fix on current branch?** → Skip to Phase 2 (commit directly)

### Work & Commit (Phase 2)
- **Ready to commit changes?** → **git-commit**
  - Analyze what changed (filter artifacts)
  - Determine single vs. multiple commits
  - Write Conventional Commits messages
  - Stage only public-value files
  - **See**: [commit_workflows.md](./references/commit_workflows.md) for complete 6-step workflow
  - **Templates**: [commit_message_template.md](./assets/commit_message_template.md)
- **No changes yet?** → Continue coding, return when ready

### Complete & Integrate (Phase 3)
- **Tests pass, ready to integrate?** → **git-finish**
  - Choose: Merge locally, Create PR, Keep as-is, or Discard
  - Cleanup worktree (if used)
  - Verify final integration
  - **See**: [finish_workflows.md](./references/finish_workflows.md) for complete 5-step workflow
  - **Templates**: [pr_template.md](./assets/pr_template.md)
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

## 5. 📋 SHARED PATTERNS

Common git patterns, commands, and conventions are documented in detail.

**See**: [shared_patterns.md](./references/shared_patterns.md) for:
- Branch naming conventions (temp, feature, detached HEAD)
- Git command reference (worktree, commit, merge, remote operations)
- Conventional Commits format and examples
- Common workflow patterns and sequences
- Quality check checklists

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

**For one-page cheat sheet**: See [quick_reference.md](./references/quick_reference.md)

**Quick Navigation**:
- **Starting work?** Section 3 (Lifecycle Map) shows which phase you're in
- **Need a skill?** Section 4 (Decision Tree) guides selection
- **Need git commands?** See [shared_patterns.md](./references/shared_patterns.md)
- **Need an example?** Section 6 (Integration Examples) shows real workflows
- **Need detailed workflow?** See [worktree_workflows.md](./references/worktree_workflows.md), [commit_workflows.md](./references/commit_workflows.md), [finish_workflows.md](./references/finish_workflows.md)

**Git Workflow Principles**:
```
ISOLATION: Use worktrees for parallel work
CLARITY: Write conventional commits with clear descriptions
QUALITY: Run tests before integration (git-finish gate)
CLEANUP: Remove worktrees after completion
```

**Remember**: This skill orchestrates three specialized workflows - Worktree Management, Commit Hygiene, and Work Completion. All integrate seamlessly for a professional git development lifecycle.