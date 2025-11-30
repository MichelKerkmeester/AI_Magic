# 🤖 Automation Workflows - Hook Enforcement & Context Auto-Save

Hook-based **HARD enforcement**, context auto-save, and mandatory process workflows for AI agents. This document explains how the enforce-spec-folder.sh and save-context-trigger.sh hooks work and defines required AI agent behavior.

**Key Point:** Enforcement is HARD - hooks block commits with missing required templates based on the progressive enhancement model.

---

## 1. 🔒 HOOK-ASSISTED ENFORCEMENT

### Overview

The `enforce-spec-folder.sh` hook automatically prompts for spec folder confirmation **only at the start of conversations**. Once substantial work has started, the hook exits early to avoid interrupting flow.

### Detection Logic

**Start of conversation (triggers prompt):**
- Spec folder is empty, OR
- ≤2 files exist AND all files <1000 bytes

**Mid-conversation (skips prompt):**
- Spec folder has >2 files, OR
- Any file >1000 bytes

**Detection method:**
- Simple file system inspection
- No git required
- Fast and reliable

### Hook Behavior at Conversation Start

When the hook detects modification intent at conversation start, it:

1. **Detects modification keywords**: add, implement, fix, update, create, refactor, etc.
2. **Searches for related specs**: Checks existing spec folders for similar work
3. **Estimates documentation level**: Based on request analysis
4. **Presents 4 options**:
   - **A)** Use detected folder (if related work found)
   - **B)** Create new spec folder with suggested number
   - **C)** Update one of the related specs shown
   - **D)** Skip spec folder creation (proceeds without documentation)

### Hook Output Example

```
⚠️  SPEC FOLDER CONFIRMATION NEEDED

Detected modification intent: implement
Estimated documentation level: Level 2 (Standard)

Related specs found:
  • 067-user-authentication (status: complete)
  • 068-user-profile (status: active)

Choose one:
  A) Use detected folder: 069-existing-spec
  B) Create new spec folder: specs/070-short-name/
  C) Update related spec (see suggestions above)
  D) Skip spec folder creation (PROCEED WITHOUT DOCUMENTATION)
     ⚠️  WARNING: Skipping documentation creates technical debt
     ⚠️  Future debugging will be harder without context
     ⚠️  Use only for truly trivial explorations

Reply with A, B, C, or D to proceed with your choice.
```

### AI Agent Response Protocol

**When you see this hook output:**

1. **Present all 4 options to user** clearly
2. **Explain implications** of each choice
3. **Ask for explicit selection**: "Which option would you like? (A/B/C/D)"
4. **Wait for user response** - do not decide autonomously
5. **Proceed based on choice**:
   - **A**: Use the detected folder path
   - **B**: Create new folder with suggested number (or ask for different name)
   - **C**: Ask which related spec to update
   - **D**: Create skip marker and proceed without spec folder

**Critical rule**: NEVER decide autonomously - user MUST choose explicitly.

---

## 2. 🚫 OPTION D: SKIP DOCUMENTATION

### Purpose

Allow users to explicitly skip spec folder creation for truly trivial explorations that don't warrant documentation overhead.

### When to Use

**Appropriate for skip (✅):**
- Quick code exploration without implementation
- Testing a concept or approach
- Reading/analyzing existing code only
- Prototyping that will be discarded

**NOT appropriate for skip (❌):**
- Any actual implementation
- Bug fixes (logic changes, not typos)
- Feature work
- Refactoring
- Configuration changes
- Documentation updates (except single typos)

**Exempt from spec requirement (no skip needed):**
- Single typo fixes (<5 characters in one file)
- Whitespace-only changes
- Auto-generated file updates (package-lock.json)

### How It Works

1. **User selects Option D** from confirmation prompt
2. **Hook creates marker**: `.claude/.spec-skip` file
3. **Subsequent prompts skip**: All validation skipped for remainder of session
4. **Audit trail**: Skip events logged to `.claude/hooks/logs/spec-enforcement.log`

### Technical Debt Warning

**Skipping documentation creates technical debt.** Without context:
- Future debugging becomes harder
- Implementation decisions are lost
- Team handoffs lack context
- Change history is incomplete

**Use sparingly.** When in doubt, create spec folder (even minimal Level 1).

### Session Management

**Skip persistence:**
- Skip marker persists for entire session
- One marker file per workspace (not per-conversation)

**To re-enable spec folder prompts:**
```bash
rm .claude/.spec-skip
```

**Marker file characteristics:**
- Gitignored (not tracked in repository)
- Shared across conversations in same workspace
- Manual deletion required to re-enable prompts

### Audit Trail

**All skip events logged to:** `.claude/hooks/logs/spec-enforcement.log`

**Log format:**
```
[2025-11-23 14:23:45] SKIP: User selected Option D - Proceeding without spec folder
[2025-11-23 14:23:45] PROMPT: implement feature X (estimated Level 2)
```

**Use log for:**
- Project documentation health monitoring
- Identifying patterns of skip usage
- Auditing technical debt accumulation

---

## 3. 💾 CONTEXT AUTO-SAVE

### Overview

The `save-context-trigger.sh` hook automatically saves conversation context to preserve implementation history.

### Trigger Conditions

**Automatic triggers:**
- Every 20 messages (20, 40, 60, 80, 100, ...)
- Runs in parallel (non-blocking) when available
- Falls back to synchronous if parallel execution unavailable

**Manual triggers:**
- Keywords: "save context", "save conversation", "save this"
- Explicit user request to preserve conversation

### Save Location

**Primary target:** `specs/###-folder/memory/`
- Saves to the spec folder being worked on
- Creates `memory/` subdirectory if needed

**Fallback target:** `memory/` (workspace root)
- Used if no spec folder detected
- Ensures context preserved even without spec

### Execution Mode

**Parallel (preferred):**
- Non-blocking execution
- Conversation continues immediately
- Context saved in background
- No performance impact

**Synchronous (fallback):**
- Blocks briefly while saving
- Used if parallel execution unavailable
- Still completes quickly (<1 second typically)

### Benefits

- **10x more frequent**: 20 vs 200 messages (old threshold)
- **Non-blocking**: Conversation flows uninterrupted
- **Automatic**: No manual save required
- **Reliable**: Fallback ensures preservation

### Context File Format

**Filename pattern:** `DD-MM-YY_HH-MM__short-description.md`

**Example:** `23-11-25_14-30__implement-modal-component.md`

**Content includes:**
- Complete conversation history
- Implementation decisions
- Code changes discussed
- Debugging steps
- User preferences and choices

---

## 4. 📂 MEMORY FILE SELECTION & CONTEXT LOADING

The `enforce-spec-folder` hook presents memory file selection when continuing work in existing spec folders with substantial content, enabling seamless context restoration across sessions.

### Trigger Conditions

**Memory selection prompt appears when:**
1. Mid-conversation (spec folder has substantial content)
2. Memory directory exists (respects `.spec-active` marker for sub-folders)
3. At least one memory file exists (format: `DD-MM-YY_HH-MM__topic.md`)

**Prompt is skipped when:**
- No memory directory found
- Memory directory empty (no files)
- Start of conversation (spec folder validation takes precedence)

### Selection Options

The hook presents 4 options to the user via AI:

**A) Load most recent (file 1)**
- Loads single most recent memory file
- Fastest option for quick context refresh
- Recommended for continuing recent work

**B) Load all recent (files 1-3)**
- Loads up to 3 most recent memory files
- Comprehensive context from recent sessions
- Recommended for understanding recent decisions

**C) List all and select specific**
- Shows up to 10 memory files with full details
- User selects specific files by number
- Recommended for searching historical context

**D) Skip (start fresh)**
- No context loading
- Conversation starts from scratch
- Recommended for new direction or unrelated work

### AI Agent Protocol (MANDATORY)

**When memory selection prompt appears:**

1. **Present all options clearly**:
   ```
   I see we have previous context available for this spec folder.

   Which memory files should I load?
   A) Load most recent (file 1)
   B) Load all recent (files 1-3)
   C) List all files and select specific
   D) Skip (start fresh)
   ```

2. **Wait for user's explicit choice** - Do not decide autonomously

3. **Execute based on selection**:
   - **Option A**: Use Read tool on most recent file path
   - **Option B**: Use Read tool on 3 most recent file paths (parallel calls)
   - **Option C**: List up to 10 files, wait for user number selection, then read
   - **Option D**: Proceed without loading files

4. **Acknowledge loaded context**:
   ```
   ✅ Loaded context from [file names]

   I can see we previously discussed:
   - [Key point 1 from memory]
   - [Key point 2 from memory]
   - [Key decision made]

   Ready to continue from where we left off.
   ```

### Integration with Sub-Folder Versioning

**Memory directory routing:**
- Reads `.spec-active` marker first
- If marker points to sub-folder → Use sub-folder `memory/`
- If no marker → Use root `memory/`
- Independent `memory/` contexts per sub-folder iteration

**Example:**
```
specs/122-skill-standardization/
├── 001-original-work/
│   └── memory/
│       └── 23-11-25_10-10__original.md  (archived)
└── 002-api-refactor/       (.spec-active points here)
    └── memory/
        └── 23-11-25_11-30__api-refactor.md  ← This is shown
```

### File Path Resolution

**Memory file discovery:**
1. Check if `.spec-active` marker exists
2. If yes, read active path from marker
3. If active path matches spec folder → Use `{active_path}/memory/`
4. Fallback: Use `{spec_folder}/memory/`
5. List files matching pattern: `*__*.md`
6. Sort by filename (descending) → Most recent first
7. Return up to 3 most recent files

**File naming:**
- Format: `DD-MM-YY_HH-MM__topic.md`
- Example: `23-11-25_14-30__mcp-code-mode-alignment.md`
- Sorted by string comparison (works chronologically within year)
- Recent files appear first in list

### Performance

**Expected timing:**
- Directory discovery: <10ms
- File listing (3 files): <20ms
- Display formatting: <50ms
- **Total hook overhead: <100ms** (within target)

**Cross-Platform Compatibility:**
- ✅ macOS: Uses `date -j` command
- ✅ Linux: Uses `date -d` command
- Platform detection via `$OSTYPE` variable

### Logging

**Log events:**
- `MEMORY_PROMPT`: Memory selection prompt presented to user
- `MARKER_CLEANUP`: Stale `.spec-active` marker removed
- `MEMORY_LOADED`: Context files loaded (via AI Read tool, not hook)

**Log location:** `.claude/hooks/logs/enforce-spec-folder.log`

**Example log entries:**
```
[2025-11-25 14:30:15] STATUS: MEMORY_PROMPT
Prompt: implement the memory selection feature
Detail: Presented memory file selection for 003-speckit-rework

[2025-11-25 14:30:16] STATUS: MARKER_CLEANUP
Prompt: continue working
Detail: Removed stale .spec-active marker (path: specs/999-deleted)
```

---

## 5. ⚙️ MANDATORY PROCESS FOR AI AGENTS

### Pre-Change Workflow

**Before making ANY file changes (code, docs, config, templates), MUST complete:**

1. **Determine documentation level (1/2/3)**
   - Estimate LOC
   - Assess complexity and risk factors
   - Use decision matrix

2. **Check for related specs**
   - Search existing specs by keywords
   - Hook does this automatically at conversation start
   - Review status fields (draft/active/paused/complete/archived)

3. **Respond to hook confirmation prompt** (if displayed)
   - Present all 4 options (A/B/C/D) to user
   - Explain implications clearly
   - Ask for explicit user selection
   - Wait for response - NEVER decide autonomously

4. **Find next spec number** (if creating new folder)
   ```bash
   ls -d specs/[0-9]*/ | sed 's/.*\/\([0-9]*\)-.*/\1/' | sort -n | tail -1
   ```
   Add 1 to get next number.

5. **Create spec folder** (if user chose B or creating new)
   ```bash
   mkdir -p specs/###-short-name/
   ```

6. **Copy REQUIRED templates** from `.claude/commands/spec_kit/assets/templates/` (Progressive Enhancement)
   - Level 1 (Baseline): `spec.md` + `plan.md` + `tasks.md`
   - Level 2 (Verification): Level 1 + `checklist.md`
   - Level 3 (Full): Level 2 + `decision-record.md`

7. **Copy OPTIONAL templates** (Level 3 only, if needed)
   - `research-spike.md` → `research-spike-[name].md` (research required)
   - `research.md` → `research.md` (comprehensive research)

8. **Fill template content**
   - Replace ALL `[PLACEHOLDER]` text
   - Remove sample/example sections
   - Adapt to specific feature
   - Remove instructional comments

9. **Present to user**
   - Documentation level chosen
   - Spec folder path
   - Templates used
   - Implementation approach

10. **Wait for approval**
    - Get explicit "yes/go ahead/proceed"
    - Do not start file changes without explicit approval

### Enforcement Checkpoints (HARD Enforcement)

**Progressive Enhancement Required Files:**
```
Level 1 (Baseline):     spec.md + plan.md + tasks.md
Level 2 (Verification): Level 1 + checklist.md
Level 3 (Full):         Level 2 + decision-record.md
```

**At each stage, verify:**

1. **Request Analysis**
   - Classified level (1/2/3) based on LOC (soft guidance) and complexity
   - Secondary factors considered (risk, dependencies, testing)
   - LOC thresholds are soft guidance; enforcement is hard

2. **Hook Confirmation**
   - If hook presented options → Asked user for choice
   - User's selection documented
   - Choice honored (A/B/C/D)

3. **Template Selection (HARD ENFORCEMENT)**
   - Copied from `.claude/commands/spec_kit/assets/templates/` (not created from scratch)
   - ALL required templates for selected level present
   - Hooks will block commits if required templates missing:
     - Level 1: blocks if spec.md OR plan.md OR tasks.md missing
     - Level 2: blocks if checklist.md missing
     - Level 3: blocks if decision-record.md missing
   - Renamed correctly

4. **Content Adaptation**
   - All placeholders replaced with actual content
   - Sample sections removed
   - Template adapted to specific feature
   - Instructional comments deleted

5. **Pre-Change Validation**
   - Spec folder exists with ALL required templates for level
   - User reviewed approach
   - Templates are complete and accurate

6. **User Approval**
   - Explicit "yes" received
   - User understands scope and approach

7. **Final Review**
   - Documentation complete and accurate
   - All required templates present for level
   - Ready to begin file changes

**If ANY checkpoint fails → STOP and fix before proceeding.**
**If required template missing → Hook blocks commit**

---

## 6. ⚠️ CRITICAL AGENT RULES

### Absolutely Required

- **NEVER create documentation files from scratch** - Always copy from `.claude/commands/spec_kit/assets/templates/`
- **ALWAYS copy from templates directory** - Never freehand documentation
- **ALWAYS rename copied files correctly** - Use proper target filenames
- **ALWAYS fill in actual content** - Remove ALL placeholders and samples
- **ALWAYS respond to hook confirmation prompts** - Ask user for choice (A/B/C/D)
- **ALWAYS applies to ALL file changes** - Code, docs, config, templates, knowledge base files

### Workflow Discipline

- **Follow process even for "trivial" changes** - Process discipline prevents errors
- **No shortcuts** - Skipping steps = unreliability and bugs
- **Consistency is a feature** - Predictable process = better outcomes
- **Process protects against small errors compounding** - Discipline prevents cascading failures

### User Respect

- **Never decide autonomously** - User must choose spec folder approach
- **Always ask when uncertain** - Confidence <80% = ask clarifying questions
- **Always get approval before changes** - Explicit "yes" required
- **Always respect user's explicit choice** - Honor A/B/C/D selection

---

## 7. 🔧 TROUBLESHOOTING

### "Hook prompt not appearing"

**Likely cause:** Mid-conversation (>2 files or >1000 bytes exist)

**Fix:** Hook intentionally skips prompt once work has started. If you need spec folder guidance mid-work, manually check for existing specs and create folder following standard process.

### "Skip marker persists across conversations"

**Expected behavior:** Skip marker is workspace-wide, not conversation-specific

**To re-enable prompts:**
```bash
rm .claude/.spec-skip
```

### "Context not auto-saving"

**Check:**
1. Is save-context-trigger.sh hook enabled?
2. Are you past 20 message threshold?
3. Check logs: `.claude/hooks/logs/save-context-trigger.log`

**Manual trigger:**
Say "save context" or "save conversation" to trigger manual save.

### "User selected Option D, now wants spec folder"

**Fix:**
1. Remove skip marker: `rm .claude/.spec-skip`
2. Create spec folder manually following standard process
3. Fill templates
4. Get user approval
5. Document retroactive creation in changelog
