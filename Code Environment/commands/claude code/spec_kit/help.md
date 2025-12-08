---
description: List all SpecKit commands and quick reference
argument-hint: "[topic]"
allowed-tools: Read
---

# SpecKit Help

## 1. 📋 AVAILABLE COMMANDS

| Command               | Purpose                           | When to Use                      |
| --------------------- | --------------------------------- | -------------------------------- |
| `/spec_kit:help`      | Show this help                    | Anytime - command discovery      |
| `/spec_kit:complete`  | Full 12-step workflow             | New features, complete lifecycle |
| `/spec_kit:plan`      | Planning only (7 steps)           | Design before implementation     |
| `/spec_kit:implement` | Implementation (8 steps)          | Existing plan, ready to code     |
| `/spec_kit:research`  | Technical investigation (9 steps) | Exploring unknowns, spikes       |
| `/spec_kit:status`    | Show current progress             | Check completion status          |
| `/spec_kit:resume`    | Resume previous session           | Returning to incomplete work     |

---

## 2. 🔍 QUICK REFERENCE

### Documentation Levels (Progressive Enhancement)

```text
Level 1 (Baseline):     spec.md + plan.md + tasks.md
     ↓
Level 2 (Verification): Level 1 + checklist.md  
     ↓
Level 3 (Full):         Level 2 + decision-record.md + optional research
```

### LOC Guidance (Soft Thresholds)

| Level | LOC Range | Use When                               |
| ----- | --------- | -------------------------------------- |
| 1     | <100      | Simple changes, bug fixes              |
| 2     | 100-499   | Features needing QA validation         |
| 3     | ≥500      | Complex features, architecture changes |

---

## 3. ⚡ COMMAND MODES

All commands support two modes via suffix:
- `:auto` - Autonomous execution (minimal prompts)
- `:confirm` - Interactive mode (confirm each phase)

**Examples:**
```bash
/spec_kit:complete add user authentication :auto
/spec_kit:plan refactor database layer :confirm
/spec_kit:implement specs/045-feature/ :auto
```

---

## 4. 📁 SPEC FOLDER STRUCTURE

```text
specs/###-short-name/
├── spec.md              (Level 1+)
├── plan.md              (Level 1+)
├── tasks.md             (Level 1+)
├── checklist.md         (Level 2+)
├── decision-record.md   (Level 3)
├── research.md          (optional, any level)
├── research-spike.md    (optional, any level)
├── handover.md          (utility, any level)
├── debug-delegation.md  (utility, any level)
└── memory/              (auto-created for context)
```

---

## 5. 🚀 QUICK ACTIONS

| I want to...              | Command                                    |
| ------------------------- | ------------------------------------------ |
| Start a new feature       | `/spec_kit:complete [feature description]` |
| Plan without implementing | `/spec_kit:plan [feature description]`     |
| Execute an existing plan  | `/spec_kit:implement [spec-folder-path]`   |
| Research before planning  | `/spec_kit:research [topic]`               |
| Check my progress         | `/spec_kit:status`                         |
| Resume previous work      | `/spec_kit:resume`                         |

---

## 6. 🔧 TROUBLESHOOTING

### Quick Fixes

| Error                   | Cause                    | Fix                                   |
| ----------------------- | ------------------------ | ------------------------------------- |
| "Empty arguments"       | No description provided  | Add feature description after command |
| "Spec folder not found" | Wrong path or deleted    | Create: `mkdir -p specs/###-name/`    |
| "Missing plan.md"       | Skipped planning phase   | Run `/spec_kit:plan` first            |
| "Hook not triggering"   | Script not executable    | Run: `chmod +x .claude/hooks/**/*.sh` |
| "Workflow stuck"        | Step failed silently     | Say: "Resume at step X"               |
| ".spec-skip exists"     | Used Option D previously | Remove: `rm .claude/.spec-skip`       |

### Common Scenarios

**"I selected the wrong spec folder"**
1. Start a new conversation
2. Select correct folder when prompted

**"I forgot to create documentation"**
1. STOP current work
2. Create folder: `mkdir -p specs/###-feature-name/`
3. Copy templates:
   ```bash
   cp .opencode/speckit/templates/spec.md specs/###-name/
   cp .opencode/speckit/templates/plan.md specs/###-name/
   cp .opencode/speckit/templates/tasks.md specs/###-name/
   ```
4. Fill templates, then continue

**"Template has unfilled placeholders"**
1. Search for `[PLACEHOLDER]` and `[NEEDS CLARIFICATION]`
2. Replace ALL with actual content
3. Remove `<!-- SAMPLE CONTENT -->` blocks

---

## 7. 🚀 QUICK START

**Fastest path to productivity:**
```bash
/spec_kit:complete [your feature] :auto
```

This auto-creates the folder with sensible defaults.

**New to SpecKit?** See `.opencode/speckit/README.md`

**Full reference:** `.opencode/speckit/README.md`