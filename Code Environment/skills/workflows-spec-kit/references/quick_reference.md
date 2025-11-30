# ⚡ Quick Reference - Commands, Checklists & Troubleshooting

Fast lookup for commands, checklists, and troubleshooting common spec folder scenarios. Use this as your quick-start guide for template copy commands, folder naming, and essential workflows.

---

## 1. 🎯 LEVEL DECISION SHORTCUTS

| Situation | Level | Core Templates | Supporting Templates |
|-----------|-------|----------------|---------------------|
| Typo, bug fix, <100 lines | 1 | spec.md | checklist.md |
| Feature, <500 lines | 2 | spec.md + plan.md | tasks.md, checklist.md, research-spike-*.md |
| Complex, 500+ lines | 3 | SpecKit (auto) | checklist.md |

---

## 2. 💻 TEMPLATE COPY COMMANDS

### Core Templates

```bash
## Level 1:
cp .claude/commands/spec_kit/assets/templates/spec.md specs/###-name/spec.md

## Level 2:
cp .claude/commands/spec_kit/assets/templates/spec.md specs/###-name/spec.md
cp .claude/commands/spec_kit/assets/templates/plan.md specs/###-name/plan.md
```

### Supporting Templates

```bash
## Tasks (after plan, before coding):
cp .claude/commands/spec_kit/assets/templates/tasks.md specs/###-name/tasks.md

## Checklist (validation needs):
cp .claude/commands/spec_kit/assets/templates/checklist.md specs/###-name/checklist.md

## Decision Record (use descriptive name):
cp .claude/commands/spec_kit/assets/templates/decision-record.md specs/###-name/decision-record-database.md

## Research-Spike (use descriptive name):
cp .claude/commands/spec_kit/assets/templates/research-spike.md specs/###-name/research-spike-performance.md
```

---

## 3. ⚙️ ESSENTIAL COMMANDS

### Find Next Spec Number

```bash
ls -d specs/[0-9]*/ | sed 's/.*\/\([0-9]*\)-.*/\1/' | sort -n | tail -1
```

Add 1 to the result to get your next number.

### Create Spec Folder

```bash
mkdir -p specs/###-short-name/
```

**Naming rules:**
- 2-3 words (shorter is better)
- Lowercase
- Hyphen-separated
- Action-noun structure

**Good examples:** `fix-typo`, `add-auth`, `mcp-code-mode`, `cli-codex`

### Remove Skip Marker

```bash
rm .claude/.spec-skip
```

Re-enables spec folder prompts after Option D was selected.

### Manual Context Save

Trigger manual context save:
```
Say: "save context" or "save conversation"
```

Context saved to `specs/###-folder/memory/` or `memory/` (fallback).

---

## 4. ✅ PRE-IMPLEMENTATION CHECKLIST

Before making ANY file changes, verify:

- [ ] Determined level (1/2/3) or exempt (typo fix)
- [ ] Created `/specs/[###-short-name]/`
- [ ] Copied appropriate templates from `.claude/commands/spec_kit/assets/templates/`
- [ ] Renamed templates correctly
- [ ] Filled core template sections with actual content
- [ ] Removed placeholder text and sample sections
- [ ] Identified and copied needed supporting templates
- [ ] Presented approach to user (including templates used)
- [ ] Got explicit approval ("yes"/"go ahead"/"proceed")

**If ANY unchecked → STOP**

---

## 5. 📁 FOLDER NAMING EXAMPLES

### Good Examples ✅

- `fix-typo` (concise, clear)
- `add-validation` (action-noun)
- `implement-auth` (descriptive)
- `cdn-migration` (noun-noun acceptable)
- `hero-animation-v2` (version included)

### Bad Examples ❌

- `fix-the-typo-in-header-component` (too long - max 4 words)
- `fixTypo` (not kebab-case)
- `fix_typo` (snake_case, should be kebab-case)
- `typo` (too vague, lacks context)
- `PROJ-123-fix` (no ticket numbers)

---

## 6. 📌 STATUS FIELD VALUES

| Status | Meaning | Reuse Priority |
|--------|---------|----------------|
| `draft` | Planning phase | 2 (can start) |
| `active` | Work in progress | 1 (highest - continue here) |
| `paused` | Temporarily on hold | 3 (can resume) |
| `complete` | Implementation finished | 4 (avoid reopening) |
| `archived` | Historical record | 5 (do not reuse) |

---

## 7. 🔀 UPDATE VS CREATE DECISION

### UPDATE Existing Spec When:

✅ Iterative development (continuing same feature)
✅ Bug fixes (fixing existing implementation)
✅ Scope escalation (work grew beyond estimate)
✅ Feature enhancement (adding to existing functionality)
✅ Resuming paused work

### CREATE New Spec When:

❌ Distinct feature (completely separate)
❌ Different approach (alternative strategy)
❌ Separate user story (different requirement)
❌ Complete redesign (starting over)
❌ Unrelated work (no connection)

---

## 8. 🔔 HOOK CONFIRMATION OPTIONS

When hook prompts at conversation start:

**Option A:** Use detected folder (if related work found)
**Option B:** Create new spec folder with suggested number
**Option C:** Update one of the related specs shown
**Option D:** Skip spec folder creation (**WARNING:** Technical debt!)

**AI Agent Rule:** NEVER decide autonomously - ask user to choose (A/B/C/D)

---

## 9. 🔄 LEVEL MIGRATION

If scope grows during implementation:

| From | To | Action |
|------|----|---------|
| 1 → 2 | Add `plan.md` to same folder |
| 2 → 3 | Use `/spec_kit:plan` in same folder |

**Always:**
- Update `level:` field in metadata
- Add changelog entry noting escalation
- Keep existing documentation (don't delete)
- Inform user of level change

---

## 10. 🔧 TROUBLESHOOTING

### "I forgot to create the spec folder"

**Fix:**
1. Stop coding immediately
2. Create spec folder retroactively
3. Document what was done and why
4. Get user approval
5. Continue with documentation in place

---

### "I'm not sure which level to choose"

**Solution:**
- When in doubt → choose **higher level**
- Ask user if confidence <80%
- Consider complexity and risk, not just LOC
- Better to over-document than under-document

---

### "Can I change levels mid-work?"

**Yes:**
- Going up: Add additional files (see Level Migration table)
- Going down: Keep existing docs (uncommon)
- Always: Inform user why level changed, update changelog

---

### "What if it's just exploration?"

**Rule:**
- Pure exploration/reading = NO spec needed
- Once you write/edit ANY files = SPEC REQUIRED
- If uncertain → create spec (safer)

---

### "Do I need specs for documentation changes?"

**YES - Documentation changes require specs just like code changes.**

**Requires spec:**
- ✅ Code files (*.js, *.ts, *.css, *.py)
- ✅ Documentation files (*.md, *.txt, docs/)
- ✅ Configuration files (*.json, *.yaml, *.toml)
- ✅ Knowledge base (.claude/knowledge/*.md)
- ✅ Templates (.claude/commands/spec_kit/assets/templates/*.md)
- ✅ Build files (package.json, requirements.txt)

**Exceptions (no spec needed):**
- ❌ Single typo fix (<5 characters in one file)
- ❌ Whitespace-only changes
- ❌ Auto-generated updates (package-lock.json)

---

### "When do I need an Architecture Decision Record (ADR)?"

**Create `decision-record-*.md` when making:**
- Database, framework, or library choices
- Architectural pattern selections
- Major refactoring approaches
- Infrastructure/deployment strategy changes

**Format:** Use descriptive name (e.g., `decision-record-database-choice.md`)

---

### "When do I create a research-spike?"

**Create `research-spike-*.md` BEFORE implementation when:**
- Technical feasibility unknown
- Need to evaluate multiple approaches
- Research required (performance, POC)
- Time-boxed exploration needed (1-3 days)

**Research-spike results inform spec and plan documents.**

**Format:** Use descriptive name (e.g., `research-spike-animation-performance.md`)

---

## 11. 📋 WHAT REQUIRES SPEC FOLDERS

| File Type | Requires Spec | Examples |
|-----------|--------------|----------|
| Code files | ✅ Yes | JavaScript, TypeScript, Python, CSS, HTML |
| Documentation | ✅ Yes | Markdown, README updates, guides |
| Configuration | ✅ Yes | JSON, YAML, TOML, .env templates |
| Knowledge base | ✅ Yes | `.claude/knowledge/*.md` updates |
| Templates | ✅ Yes | `.claude/commands/spec_kit/assets/templates/*.md` modifications |
| Build/tooling | ✅ Yes | package.json, requirements.txt, Dockerfile |

**Exceptions (no spec needed):**
- ❌ Pure exploration/reading (no file modifications)
- ❌ Single typo fixes (<5 characters in one file)
- ❌ Whitespace-only changes
- ❌ Auto-generated file updates (package-lock.json)

---

## 12. ⚠️ SKIP OPTION (OPTION D) USAGE

### When Appropriate ✅

- Quick code exploration without implementation
- Testing a concept or approach
- Reading/analyzing existing code only
- Prototyping that will be discarded

### When NOT Appropriate ❌

- Any actual implementation
- Bug fixes (even small ones)
- Feature work
- Refactoring
- Configuration changes
- Documentation updates

### Technical Debt Warning

Skipping documentation:
- Makes future debugging harder
- Loses implementation decisions
- Breaks team handoffs
- Creates incomplete change history

**Use sparingly.** When in doubt, create spec folder (even minimal Level 1).

---

## 13. ✅ TEMPLATE ADAPTATION CHECKLIST

Before presenting documentation to user:

- [ ] All templates copied from `.claude/commands/spec_kit/assets/templates/` (not from scratch)
- [ ] All placeholders replaced (`[PLACEHOLDER]`, `[NEEDS CLARIFICATION: ...]`)
- [ ] All sample content removed (`<!-- SAMPLE CONTENT -->`)
- [ ] Template footer deleted
- [ ] Metadata block filled correctly
- [ ] All sections filled with actual content (or marked "N/A")
- [ ] Cross-references to sibling documents working
- [ ] Numbering and emojis preserved
- [ ] Structure matches template
- [ ] Descriptive filenames used (for decision records and research-spikes)

**If ANY unchecked → Fix before user presentation**

---

## 14. 💾 CONTEXT AUTO-SAVE

**Automatic triggers:**
- Every 20 messages (20, 40, 60, 80, ...)
- Non-blocking parallel execution (when available)

**Manual triggers:**
- Keywords: "save context", "save conversation", "save this"

**Save location:**
- Primary: `specs/###-folder/memory/`
- Fallback: `memory/` (workspace root)

**Filename pattern:** `DD-MM-YY_HH-MM__short-description.md`

---

## 15. 🤖 AGENT CRITICAL RULES

### Absolutely Required

- **NEVER create documentation from scratch** - Always copy from templates
- **ALWAYS copy from `.claude/commands/spec_kit/assets/templates/`** directory
- **ALWAYS fill ALL placeholders** - No `[PLACEHOLDER]` in final docs
- **ALWAYS respond to hook prompts** - Ask user for A/B/C/D choice
- **ALWAYS get user approval** - Explicit "yes" before file changes

### Applies to ALL

- Code files (*.js, *.ts, *.py, *.css, *.html)
- Documentation files (*.md, README, docs/)
- Configuration files (*.json, *.yaml, *.toml)
- Knowledge base files (.claude/knowledge/*.md)
- Template files (.claude/commands/spec_kit/assets/templates/*.md)
- Build files (package.json, requirements.txt)

**No exceptions** (unless user explicitly selects Option D)

---

## 16. 💡 CORE PRINCIPLE

**Every file change deserves documentation.**

Future you will thank present you for creating that spec folder.

When in doubt:
- Document more rather than less
- Choose higher level over lower
- Create spec folder over skipping
- Ask user rather than guessing

**Cost of creating spec << Cost of reconstructing lost context later**
