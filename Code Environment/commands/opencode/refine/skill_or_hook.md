---
description: Audit, fix, and improve skills and hooks systems (4 phases)
argument-hint: <target> [:audit|:fix|:full] - target can be "skills", "hooks", "both", or specific path
allowed-tools: Read, Write, Edit, Glob, Grep, Bash, Task, AskUserQuestion, Skill
model: opus
---

# Skill & Hook Refinement Command

Systematically audit, fix, and improve skills and hooks using parallel exploration and evidence-based methodology.

---

```yaml
role: Code Quality Engineer with Platform Compatibility Expertise
purpose: Audit, fix, and improve skills and hooks through systematic 4-phase methodology
action: Execute Detect → Fix → Verify → Document workflow with parallel Sonnet exploration

operating_mode:
  workflow: sequential_4_phase
  workflow_compliance: MANDATORY
  workflow_execution: orchestrator_with_workers
  approvals: user_approval_before_fixes
  tracking: priority_classification_P0_P3
  validation: quality_gates_and_dry_run_tests
```

---

## User Input

```text
$ARGUMENTS
```

---

## Workflow Overview (4 Phases)

| Phase | Name | Purpose | Outputs |
|-------|------|---------|---------|
| 1 | Detect | Parallel exploration with 4 Sonnet agents | Issue inventory (P0-P3) |
| 2 | Fix | Apply pattern library fixes | Fixed files, version bumps |
| 3 | Verify | Quality gates and dry-run tests | Verification results |
| 4 | Document | Audit report and context save | spec folder, memory/ |

---

## Mode Detection & Routing

| Pattern | Mode | Phases Executed |
|---------|------|-----------------|
| `/refine:skill_or_hook :audit` | DETECT ONLY | Phase 1 |
| `/refine:skill_or_hook :fix` | DETECT + FIX | Phases 1-2 |
| `/refine:skill_or_hook :full` | COMPLETE | Phases 1-4 |
| `/refine:skill_or_hook` (no suffix) | FULL (default) | Phases 1-4 |

---

## Purpose

Execute a 4-phase refinement workflow (Detect → Fix → Verify → Document) to:
1. **Detect** code smells, bugs, and improvement opportunities using concrete grep patterns
2. **Fix** issues using platform-aware pattern library (macOS/Linux compatibility)
3. **Verify** fixes with dry-run tests and quality gates
4. **Document** changes with comprehensive audit report and version bumps

**Modes:**
- **:audit** - Detection only (Phase 1) - Identify issues without making changes
- **:fix** - Detect + Fix (Phases 1-2) - Find and fix issues, no verification
- **:full** - Complete workflow (Phases 1-4) - Thorough audit with verification and documentation (DEFAULT)

---

## Contract

**Inputs:** `$ARGUMENTS` — Target scope + optional mode
- `skills` - Audit all skills in `.claude/skills/`
- `hooks` - Audit all hooks in `.claude/hooks/`
- `both` - Audit both systems (DEFAULT if no target specified)
- `{specific-path}` - Audit single skill/hook (e.g., `.claude/skills/workflows-code/` or `.claude/hooks/PreToolUse/validate-bash.sh`)

**Outputs:**
- SpecKit documentation at `specs/###-refine-audit/`:
  - `spec.md` - Audit specification (ALWAYS)
  - `plan.md` - Fix implementation plan (ALWAYS)
  - `tasks.md` - Task breakdown (ALWAYS)
  - `checklist.md` - Verification checklist (if :fix or :full)
  - `audit_report.md` - Comprehensive findings report
  - `memory/` - Session context for future reference
- Fixed files (if :fix or :full mode)
- Version bumps (patch for fixes, minor for improvements)

**Status:** `STATUS=<OK|FAIL|CANCELLED> ISSUES_FOUND=N ISSUES_FIXED=N PATH={spec_folder}`

---

## Instructions

Execute the following workflow:

### Step 1: Parse Input & Determine Scope

1. **Extract target and mode from $ARGUMENTS:**
   ```
   If $ARGUMENTS contains :audit → mode = "audit"
   If $ARGUMENTS contains :fix → mode = "fix"
   If $ARGUMENTS contains :full OR no mode → mode = "full"

   If $ARGUMENTS contains "skills" → scope = "skills"
   If $ARGUMENTS contains "hooks" → scope = "hooks"
   If $ARGUMENTS contains "both" OR empty → scope = "both"
   If $ARGUMENTS is a path → scope = "specific", target_path = path
   ```

2. **Validate scope:**
   - If scope is "specific", verify the path exists
   - If path doesn't exist, return error with suggested corrections

### Step 2: Spec Folder Setup (MANDATORY)

3. **Check for existing related spec folders:**
   ```bash
   ls -d specs/*refine* specs/*audit* specs/*hook* specs/*skill* 2>/dev/null
   ```

4. **Ask user to choose (A/B/C/D) - MANDATORY per AGENTS.md:**
   - **A)** Use existing spec folder (if related spec found)
   - **B)** Create new spec folder: `specs/###-refine-audit/`
   - **C)** Update related spec (create sub-folder)
   - **D)** Skip documentation (NOT RECOMMENDED - creates technical debt)

   **WAIT for explicit user response before creating folder.**

5. **If continuing in existing spec folder with memory files:**
   Ask user to choose:
   - **A)** Load most recent memory file
   - **B)** Load all recent files (up to 3)
   - **C)** List all files and select specific
   - **D)** Skip (start fresh)

6. **Create spec folder using templates:**
   ```bash
   # Copy required templates (Level 1 minimum)
   cp .opencode/speckit/templates/spec.md "$SPEC_FOLDER/"
   cp .opencode/speckit/templates/plan.md "$SPEC_FOLDER/"
   cp .opencode/speckit/templates/tasks.md "$SPEC_FOLDER/"

   # Add checklist if :fix or :full mode (Level 2)
   if [[ "$MODE" != "audit" ]]; then
     cp .opencode/speckit/templates/checklist.md "$SPEC_FOLDER/"
   fi
   ```

### Step 3: Load YAML Workflow

7. **Read the workflow YAML:**
   ```
   Asset path: .claude/commands/refine/assets/refine_workflow.yaml
   ```

8. **Execute workflow phases based on mode:**
   - **:audit** → Phase 1 only
   - **:fix** → Phases 1-2
   - **:full** → Phases 1-4

### Step 4: Parallel Exploration (Phase 1)

9. **Spawn 4 Sonnet exploration agents in parallel:**

   | Agent | Focus | Purpose |
   |-------|-------|---------|
   | **Code Smell Explorer** | Bug patterns, platform issues | Find code smells using grep patterns |
   | **Structure Explorer** | SKILL.md format, frontmatter | Validate structural requirements |
   | **Cross-Reference Explorer** | Broken refs, missing files | Verify all references resolve |
   | **Performance Explorer** | Timing, subprocess overhead | Identify performance bottlenecks |

10. **Aggregate findings and classify by priority (P0-P3):**
    - P0 (Critical): Fix immediately - crashes, security issues
    - P1 (High): Fix this session - compatibility, major bugs
    - P2 (Medium): Fix if time - minor bugs, outdated docs
    - P3 (Low): Document only - style issues, micro-optimizations

### Step 5: User Approval Gate (MANDATORY)

11. **Present issue inventory to user:**
    ```
    Issue Classification:
      P0 (Critical): N issues
      P1 (High): N issues
      P2 (Medium): N issues
      P3 (Low): N issues

    P0/P1 issues to fix:
    - [file:line] Description
    - [file:line] Description
    ```

12. **Ask for explicit approval before applying fixes:**
    - "Should I proceed with fixing N P0/P1 issues? (yes/no/select)"
    - **WAIT for explicit "yes" or "go ahead" confirmation**
    - If user says "no" or "select", allow them to choose specific fixes

### Step 6: Apply Fixes (Phase 2)

13. **For each approved P0/P1 issue, apply fix from pattern library:**
    - Platform compatibility (macOS/Linux)
    - JSON null safety (jq patterns)
    - Exit code standardization
    - Performance optimizations (caching)

14. **Bump versions:**
    - Patch (0.0.X) for bug fixes
    - Minor (0.X.0) for new features
    - Major (X.0.0) for breaking changes

### Step 7: Verification (Phase 3)

15. **Run verification commands:**
    ```bash
    # Syntax check
    bash -n hook.sh

    # Dry run test
    echo '{"prompt": "test"}' | bash hook.sh

    # Performance check
    grep "hook-name" .claude/hooks/logs/performance.log
    ```

16. **Quality gates:**
    - All hooks pass `bash -n` syntax check
    - Exit codes use constants (EXIT_ALLOW, EXIT_BLOCK, etc.)
    - jq calls have null safety (`// empty` or `// "default"`)
    - Performance within targets (<100ms typical)

### Step 8: Documentation (Phase 4)

17. **Update spec folder with findings:**
    - Fill `spec.md` with audit scope and requirements
    - Fill `plan.md` with fix approach and patterns used
    - Fill `tasks.md` with issues found and their status
    - Fill `checklist.md` with verification results (Level 2+)
    - Generate `audit_report.md` with comprehensive findings

18. **Invoke workflows-save-context skill:**
    ```
    Skill(skill: "workflows-save-context")
    ```
    This saves session context to `memory/` for future sessions.

19. **Return final status:**
    ```
    STATUS=OK ISSUES_FOUND=N ISSUES_FIXED=N PATH={spec_folder}/
    ```

---

## Failure Recovery

| Failure Type | Recovery Action |
|--------------|-----------------|
| Agent exploration fails | Retry with broader search scope, fallback to manual grep |
| Fix introduces regression | Immediate revert, document in audit report, skip to next issue |
| Verification phase hangs | Timeout after 30s, log partial results, continue |
| Cross-reference cannot resolve | Document as deferred, create placeholder note |
| Platform detection fails | Default to macOS-safe patterns (more restrictive) |
| User rejects all fixes | Complete :audit mode only, document findings |

---

## Error Handling

| Condition | Action |
|-----------|--------|
| Empty `$ARGUMENTS` | Default to `both :full` |
| Invalid path | Return error with path suggestions |
| No issues found | Return success with "All clear" message |
| Fix breaks functionality | Revert fix, log for manual review |
| Permission denied | Report which files couldn't be modified |
| YAML not found | Return error with installation suggestion |
| User declines spec folder | Warn about technical debt, proceed with :audit only |

---

## Critical Rules

- Execute full 4-phase workflow (Detect-Fix-Verify-Document) unless mode specifies otherwise
- Run detection BEFORE any fixes (never fix blind)
- Verify AFTER each fix (bash -n, dry-run tests)
- Use EXIT_* constants (never magic exit codes like `exit 1`)
- Add null safety (`// empty` or `// "default"`) to ALL jq calls
- Bump version numbers on ANY code change
- **MANDATORY**: Ask user for spec folder choice (A/B/C/D) before creating
- **MANDATORY**: Get explicit user approval before applying fixes
- NEVER skip verification phase in :full mode
- NEVER fix P2/P3 issues before P0/P1 are resolved
- NEVER modify shared lib without testing ALL dependents

---

## Examples

### Full Audit (Default)
```bash
/refine:skill_or_hook
# Audits both skills and hooks with full 4-phase workflow
```

### Audit Only (No Changes)
```bash
/refine:skill_or_hook hooks :audit
# Detection only - reports issues without fixing
```

### Quick Fix
```bash
/refine:skill_or_hook skills :fix
# Detect and fix P0/P1 issues, skip verification
```

### Single Hook
```bash
/refine:skill_or_hook .claude/hooks/PreToolUse/validate-bash.sh :full
# Full audit of single hook file
```

### Single Skill
```bash
/refine:skill_or_hook .claude/skills/workflows-code/ :full
# Full audit of single skill folder
```

---

## Example Output

```
Refinement Mode Activated (Opus Orchestrator)

Target: hooks
Mode: FULL (Detect → Fix → Verify → Document)

Step 2: Spec Folder Setup
  Found related specs: specs/057-hook-optimization-refactor/

  Please choose (A/B/C/D):
  A) Use existing: specs/057-hook-optimization-refactor/
  B) Create new: specs/060-refine-audit/
  C) Update related (create sub-folder)
  D) Skip documentation (not recommended)

  [User selects B]
  Created: specs/060-refine-audit/

Phase 1: Parallel Exploration (4 Sonnet agents)
  Code Smell Explorer: scanning for bug patterns...
  Structure Explorer: validating hook structure...
  Cross-Reference Explorer: checking lib dependencies...
  Performance Explorer: analyzing timing data...
  Exploration Complete (47 files scanned)

Issue Classification:
  P0 (Critical): 0
  P1 (High): 3
  P2 (Medium): 8
  P3 (Low): 12

Step 5: User Approval
  P0/P1 issues to fix:
  - validate-bash.sh:45 - date +%s%N (platform compat)
  - enforce-spec.sh:89 - Missing null safety
  - shared-state.sh:23 - Magic exit code

  Should I proceed with fixing 3 P0/P1 issues? (yes/no/select)
  [User confirms: yes]

Phase 2: Applying Fixes
  [1/3] validate-bash.sh:45 - date +%s%N → _get_nano_time()
  [2/3] enforce-spec.sh:89 - Missing null safety → Added // empty
  [3/3] shared-state.sh:23 - Magic exit code → EXIT_BLOCK constant
  Fixes Applied: 3/3

Phase 3: Verification
  Syntax checks: 23/23 passed
  Dry run tests: 23/23 passed
  Performance: All within targets

Phase 4: Documentation
  spec.md: Updated with audit scope
  plan.md: Documented fix approach
  tasks.md: Listed all issues and status
  checklist.md: Verification results
  audit_report.md: Comprehensive findings
  memory/: Context saved for future sessions

STATUS=OK ISSUES_FOUND=23 ISSUES_FIXED=3 PATH=specs/060-refine-audit/
```

---

## Issue Detection Patterns

### Hook Code Smells (grep patterns)
| ID | Pattern | Command | Fix |
|----|---------|---------|-----|
| PERF-01 | jq in loops | Check files with both loop+jq constructs | Cache to shell vars |
| PERF-02 | date +%s%N | `grep -n "date +%s%N" \| grep -v "_get_nano_time\|# .*date"` | Use _get_nano_time() |
| COMPAT-01 | stat -c | `grep -n "stat -c" \| grep -v "stat -f"` | Platform check (Darwin: -f, Linux: -c) |
| COMPAT-02 | sed -i without '' | `grep -n "sed -i [^']"` | Add '' for macOS |
| BUG-01 | Missing null safety | `grep -n "jq -r" \| grep -v "// empty\|// \"\"\|// null"` | Add `// empty` or `// "default"` |
| BUG-02 | Magic exit codes | `grep -n "^\s*exit [1-9]" \| grep -v "EXIT_\|# exit"` | Use constants (only non-zero) |
| STYLE-01 | Missing header | `head -5 hook.sh \| grep -q "PURPOSE\|DESCRIPTION"` | Add header block |

### Skill Structural Smells
| ID | Check | Command | Fix |
|----|-------|---------|-----|
| STRUCT-01 | Missing frontmatter | `grep -E "^(name\|version\|allowed-tools):"` | Add required fields |
| STRUCT-02 | Missing sections | `grep -Ei "## [0-9]*\.?\s*WHEN TO USE"` | Add required section |
| STRUCT-03 | Broken refs | Find missing files in references/ | Fix path or remove ref |

---

## Templates Used

- `.claude/commands/refine/assets/refine_workflow.yaml` - 4-phase workflow with pattern library
- `.opencode/speckit/templates/spec.md` - Audit specification template
- `.opencode/speckit/templates/plan.md` - Fix implementation plan template
- `.opencode/speckit/templates/tasks.md` - Task breakdown template
- `.opencode/speckit/templates/checklist.md` - Verification checklist (Level 2+)

---

## Completion Report

After workflow completion, report:

```
Refinement Complete

Scope: {scope}
Mode: {mode}
Duration: {duration}

Results:
  Issues Found: {issues_found}
  Issues Fixed: {issues_fixed}
  Files Modified: {files_modified}

Artifacts Created:
  - specs/{spec_number}-refine-audit/spec.md
  - specs/{spec_number}-refine-audit/plan.md
  - specs/{spec_number}-refine-audit/tasks.md
  - specs/{spec_number}-refine-audit/audit_report.md
  - specs/{spec_number}-refine-audit/memory/{timestamp}__refine-audit.md

STATUS=OK ISSUES_FOUND={N} ISSUES_FIXED={N} PATH=specs/{spec_number}-refine-audit/
```

---

## Notes

- **Platform Compatibility:**
  - All fixes use platform-aware patterns (macOS Bash 3.2 + Linux)
  - Uses `$(uname)` detection for Darwin vs Linux
  - stat: `-f %m` (macOS) vs `-c %Y` (Linux)
  - sed: `-i ''` (macOS) vs `-i` (Linux)

- **Exit Codes:**
  - Uses standard constants from `lib/exit-codes.sh`
  - EXIT_ALLOW=0, EXIT_BLOCK=1, EXIT_ERROR=2, EXIT_WARNING=3, EXIT_SKIP=4
  - Never use magic numbers directly

- **Shared Libraries:**
  - `lib/exit-codes.sh` - Exit code constants (required)
  - `lib/output-helpers.sh` - Output formatting (required)
  - `lib/shared-state.sh` - Inter-hook state management
  - `lib/signal-output.sh` - Mandatory question emission
  - `lib/tool-input-parser.sh` - JSON input parsing (optional)
  - `lib/perf-timing.sh` - Performance timing helpers

- **Version Bumps:**
  - Follows SemVer - patch for fixes, minor for features
  - Platform-safe update: uses `$(uname)` check for sed command

- **Model Hierarchy:**

  | Role | Model | Responsibility |
  |------|-------|----------------|
  | **Orchestrator** | `opus` | Task understanding, dispatch, verification, synthesis |
  | **Workers** | `sonnet` | Fast parallel exploration, issue discovery |

  **Worker Dispatch Format (Task tool):**
  ```json
  {
    "subagent_type": "Explore",
    "model": "sonnet",
    "description": "Code Smell Explorer",
    "prompt": "Analyze skills and hooks for code smells..."
  }
  ```

- **YAML Workflow Architecture:**
  - Command file (~350 lines): Input parsing, user interactions, workflow loading
  - YAML workflow (~1100 lines): All 4-phase logic with pattern library
  - Pattern library: Platform-aware fix patterns for common issues

- **SpecKit Integration:**
  - Creates Level 1 minimum (spec.md + plan.md + tasks.md)
  - Level 2 for :fix/:full modes (adds checklist.md)
  - Templates from `.opencode/speckit/templates/`
  - Memory context via workflows-save-context skill

- **Skill Integrations:**
  - `workflows-spec-kit` - Template structure (implicit via template copying)
  - `workflows-save-context` - Session context persistence
  - Hooks enforce spec folder creation before file modifications
