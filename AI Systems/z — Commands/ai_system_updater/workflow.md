---
description: Assess and improve files using system_updater workflow with approval gates. Supports :auto and :confirm modes
argument-hint: "<request> <target-files> [context:...] [reference:...] [complexity:quick|standard|deep] [output:...] [:auto|:confirm]"
allowed-tools: Read, Write, Edit, Grep, Glob, AskUserQuestion
---

# 🚨 MANDATORY FIRST ACTION - DO NOT SKIP

**BEFORE READING ANYTHING ELSE IN THIS FILE, CHECK `$ARGUMENTS`:**

```
IF $ARGUMENTS is empty, undefined, or contains only whitespace (ignoring mode flags):
    → STOP IMMEDIATELY
    → Use AskUserQuestion tool with this exact question:
        question: "What would you like to improve and which files?"
        options:
          - label: "Describe my request"
            description: "I'll provide the improvement request and target files"
    → WAIT for user response
    → Use their response to extract request and target_files
    → Only THEN continue with this workflow

IF $ARGUMENTS contains request and target files:
    → Continue reading this file
```

**CRITICAL RULES:**
- **DO NOT** infer requests or target files from context, screenshots, or conversation history
- **DO NOT** assume what files the user wants to improve based on recent activity
- **DO NOT** proceed past this point without explicit request AND target files from the user
- Both request and target_files MUST come from `$ARGUMENTS` or user's answer to the question above

---

# System Update

Execute the system_updater workflow to assess and improve files with optional approval gates. Automates the 5-step workflow (initialization, analysis, planning, artifact preparation, delivery) with intelligent input transformation and mode-based execution.

---

## Purpose

Automate file assessment and improvement using the system_updater.yaml workflow. Provides two execution modes:
- **Autonomous** (`:auto`): Execute all 5 steps without approval gates for quick improvements
- **Interactive** (`:confirm`): Pause at planning (step 3) and delivery (step 5) for user review and approval

Use when you need to systematically improve files based on requirements, reference standards, or best practices with zero-regression guarantees.

---

## Contract

**Inputs**: `$ARGUMENTS` — Request description (REQUIRED), target files (REQUIRED), optional context/reference/complexity/output folder, optional mode suffix

**Outputs**: Improved files in output folder + `STATUS=<OK|FAIL|CANCELLED|NEEDS_APPROVAL>` + change summary

## User Input

```text
$ARGUMENTS
```

## Workflow Overview (5 Steps)

| Step | Name | Purpose | Outputs |
|------|------|---------|---------|
| 1 | Initialization | Validate inputs, prepare framework | normalized_inputs, analysis_configuration |
| 2 | Analysis | Assess current state, identify issues | assessment_report, prioritized_issues |
| 3 | Planning | Create improvement plan | comprehensive_improvement_plan |
| 4 | Artifact Preparation | Generate improved files | ready_artifacts |
| 5 | Delivery | Write files to output folder | delivered_artifacts, change_summary |

**Approval Checkpoints** (`:confirm` mode only):
- Step 3: Planning approval (always required in confirm mode)
- Step 5: Artifact delivery approval (based on complexity policy)

---

## Instructions

### Phase 1: Mode Detection & Input Parsing

#### Step 1.1: Parse Mode Suffix

Detect execution mode from command invocation:

| Pattern | Mode | Behavior |
|---------|------|----------|
| `/system_update:workflow:auto` | AUTONOMOUS | Execute all steps without approval gates |
| `/system_update:workflow:confirm` | INTERACTIVE | Pause at step 3 and step 5 for approval |
| `/system_update:workflow` (no suffix) | PROMPT | Ask user to choose mode |

#### Step 1.2: Mode Selection (when no suffix detected)

If no `:auto` or `:confirm` suffix is present, use AskUserQuestion:

**Question**: "How would you like to execute this system update workflow?"

| Option | Mode | Description |
|--------|------|-------------|
| **A** | Autonomous | Execute all 5 steps without approval gates. Best for quick improvements and trusted changes. |
| **B** | Interactive | Pause at step 3 (planning approval) and step 5 (artifact delivery based on complexity). Best for critical changes needing review. |

**Wait for user response before proceeding.**

#### Step 1.3: Transform Raw Input

Parse the raw text from `$ARGUMENTS` and transform into structured user_inputs fields.

**Field Extraction Rules**:

| Field | Pattern Detection | Default If Empty |
|-------|-------------------|------------------|
| `request` | Primary task description (REQUIRED) | ERROR if completely empty |
| `target_files` | File paths, folders, globs after request | Infer from request or prompt user |
| `context` | "context:", "using:", "constraints:" patterns | Infer from request |
| `already_improved_reference_files` | "reference:", "baseline:" patterns | Skip (optional) |
| `complexity` | "complexity:quick", "complexity:standard", "complexity:deep" | "standard" |
| `output_folder` | "output:", "to:" patterns | "./output" |

**Extraction Pattern Examples**:
```
/system_update:workflow:auto "Improve SKILL.md files" .claude/skills/*/SKILL.md complexity:standard
  → request="Improve SKILL.md files"
  → target_files=".claude/skills/*/SKILL.md"
  → complexity="standard"
  → mode="auto"

/system_update:workflow:confirm "Fix formatting" specs/*/README.md context:"align with standards" reference:.claude/skills/create-documentation/SKILL.md
  → request="Fix formatting"
  → target_files="specs/*/README.md"
  → context="align with standards"
  → already_improved_reference_files=".claude/skills/create-documentation/SKILL.md"
  → mode="confirm"
```

#### Step 1.4: Load & Execute Workflow Prompt

Based on detected/selected mode, use the Read tool to load the appropriate YAML workflow:

**If AUTONOMOUS mode:**
```
Read(file_path: ".claude/commands/system_update/assets/auto.yaml")
```

**If INTERACTIVE mode:**
```
Read(file_path: ".claude/commands/system_update/assets/confirm.yaml")
```

Execute all instructions in the loaded YAML file sequentially as if they were inline in this command.

### Phase 2: Workflow Execution

The loaded YAML workflow will execute the 5-step system_updater process:

**Step 1**: Validate inputs, normalize fields, prepare analysis framework
**Step 2**: Load reference files (if provided), assess current state, prioritize issues
**Step 3**: Generate improvement plan → **APPROVAL CHECKPOINT** (confirm mode only)
**Step 4**: Create improved artifacts maintaining zero-regression policy
**Step 5**: Deliver artifacts → **APPROVAL CHECKPOINT** (confirm mode, based on complexity policy)

See `.claude/commands/system_update/assets/` for detailed workflow implementation.

---

## Complexity Policy

The complexity level affects approval requirements in interactive mode:

| Level | Analysis Depth | Approval at Step 5 (Confirm Mode) |
|-------|----------------|-----------------------------------|
| **quick** | Light (critical issues only) | Critical changes only |
| **standard** | Comprehensive (all significant issues) | Critical + Major changes |
| **deep** | Exhaustive (all issues + optimizations) | ALL artifacts (every change) |

**Autonomous mode**: No approvals regardless of complexity level.

---

## Context Loading

When resuming work in an existing spec folder, the system may use memory files for context (if available). This is handled automatically by the YAML workflow.

---

## Failure Recovery

| Failure Type | Recovery Action |
|--------------|-----------------|
| Empty request | ERROR: "Please describe what you want to improve" |
| Target files not found | ERROR: "Cannot access target files: [paths]" |
| Invalid complexity level | Use "standard" default, log warning |
| YAML file missing | ERROR: "Workflow file missing at .claude/commands/system_update/{mode}.yaml" |
| User rejects plan (step 3) | Allow revision or abort workflow |
| User rejects artifact (step 5) | Skip artifact or allow inline edits |
| Output folder permission denied | ERROR: "Cannot write to output folder, check permissions" |

---

## Error Handling

| Condition | Action |
|-----------|--------|
| Empty `$ARGUMENTS` | Prompt: "Please provide request and target files" |
| Request missing | ERROR: "REQUEST required - describe improvements needed" |
| Target files not accessible | ERROR: "Target files not found: [list paths]" |
| Invalid mode suffix | Ignore suffix, proceed to mode selection prompt |
| YAML file not found | ERROR: "Workflow file missing at [path]" |
| Permission denied | ERROR: "Cannot write to [path] - check permissions" |

---

## Completion Report

After workflow completion, report:

```
✅ System Update Workflow Finished

Mode: [AUTONOMOUS/INTERACTIVE]
Request: [user request summary]
Complexity: [quick/standard/deep]

Artifacts Created/Updated:
- [filename1] ([change type])
- [filename2] ([change type])
- ... ([N] files total)

Output Folder: [path]

Changes Summary:
- Critical fixes: [count]
- Major improvements: [count]
- Minor refinements: [count]

Quality Metrics:
- Files analyzed: [count]
- Issues found: [count]
- Issues fixed: [count]
- Validation: [PASS/FAIL]

Next Steps:
- Review artifacts in [output_folder]
- Validate changes meet requirements
- Apply to production if approved

STATUS=OK ACTION=artifacts_delivered COUNT=[approved]/[total]
```

---

## Examples

**Example 1: Quick improvement (autonomous)**
```
/system_update:workflow:auto "Fix typos in README files" specs/*/README.md complexity:quick
# Fast execution, only critical issues, no approval gates
```

**Example 2: Standard improvement with reference (autonomous)**
```
/system_update:workflow:auto "Align SKILL.md files with standard" .claude/skills/*/SKILL.md reference:.claude/skills/create-documentation/SKILL.md complexity:standard
# Uses reference file as baseline, comprehensive analysis, no approvals
```

**Example 3: Deep improvement (interactive)**
```
/system_update:workflow:confirm "Comprehensive hook optimization" .claude/hooks/**/*.sh context:"improve performance and readability" complexity:deep output:./improved-hooks/
# Approval at planning + approval for every artifact, exhaustive analysis
```

**Example 4: Context-rich improvement (interactive)**
```
/system_update:workflow:confirm "Enhance parallel agent system" .claude/hooks/UserPromptSubmit/orchestrate-skill-validation.sh context:"integrate with new complexity scoring" reference:.claude/skills/create-parallel-sub-agents/references/complexity_scoring.md
# Interactive mode with context and reference for guided improvements
```

**Example 5: No suffix - prompts for mode**
```
/system_update:workflow "Update documentation templates" .opencode/speckit/templates/*.md
# Will prompt: "How would you like to execute? (A) Autonomous (B) Interactive"
```

---

## Notes

- **Mode Behaviors:**
  - **Autonomous (`:auto`)**: Executes all 5 steps without user approval gates. Self-validates at each checkpoint. Makes informed decisions based on complexity level. Best for trusted improvements and quick fixes.
  - **Interactive (`:confirm`)**: Pauses at step 3 (planning approval) and step 5 (artifact delivery approval based on complexity policy). Allows review and modification at critical points. Best for high-impact changes.

- **Complexity Policy Impact:**
  - **Quick**: Light analysis, critical issues only. Autonomous: no approvals. Interactive: approval at step 3 (planning) + step 5 for critical changes only.
  - **Standard**: Comprehensive analysis, all significant issues. Autonomous: no approvals. Interactive: approval at step 3 + step 5 for critical and major changes.
  - **Deep**: Exhaustive analysis, all issues including optimizations. Autonomous: no approvals. Interactive: approval at step 3 + step 5 for ALL artifacts.

- **Integration:**
  - Works with system_updater.yaml core workflow (unchanged)
  - Supports all 6 user_inputs fields from system_updater
  - Preserves zero-regression policy and validation rules
  - Output files written to specified output_folder (default: ./output)

- **Field Transformation:**
  - `request`: Extracted from quoted string or primary description (REQUIRED)
  - `target_files`: Extracted from file paths/globs (can be inferred from request)
  - `context`: Extracted from `context:"..."` pattern (optional, can infer)
  - `already_improved_reference_files`: Extracted from `reference:...` pattern (optional)
  - `complexity`: Extracted from `complexity:[quick|standard|deep]` (default: standard)
  - `output_folder`: Extracted from `output:...` pattern (default: ./output)

- **Error Recovery:**
  - Empty request → ERROR with prompt to describe improvements
  - Invalid complexity → Uses "standard" default with warning
  - Missing YAML file → ERROR with installation/path suggestion
  - Target files not accessible → ERROR with file paths and alternatives
  - Permission denied → ERROR with permission issue and sudo suggestion

- **YAML Workflow Structure:**
  - Both auto and confirm modes implement same 5-step workflow
  - Difference: confirm mode adds approval_checkpoint blocks at step 3 and step 5
  - Approval checkpoints use AskUserQuestion tool for user interaction
  - Step 5 approval behavior varies by complexity level (quick/standard/deep)

---

## Troubleshooting

### Problem: Command not found or not recognized

**Symptoms**: `/system_update` command doesn't appear in command list or returns "command not found"

**Causes**:
- Command file not in `.claude/commands/` directory
- Command file has incorrect permissions
- Claude Code hasn't reloaded command definitions

**Solutions**:
1. Verify file exists: `ls -la .claude/commands/system_update.md`
2. Check file permissions: Should be readable (644 or similar)
3. Restart Claude Code session to reload commands
4. Verify frontmatter has valid `description:` field

---

### Problem: YAML file not found error

**Symptoms**: Error message: "Cannot read file at .claude/commands/system_update/auto.yaml"

**Causes**:
- YAML workflow files not installed
- Incorrect file paths in command
- Files in wrong directory

**Solutions**:
1. Verify YAML files exist:
   ```bash
   ls -la .claude/commands/system_update/auto.yaml
   ls -la .claude/commands/system_update/confirm.yaml
   ```
2. Check file paths in command file match actual locations
3. Ensure `.claude/commands/system_update/` directory exists
4. Re-install command if files are missing

---

### Problem: Mode detection not working

**Symptoms**: Wrong mode selected, or no mode selection prompt appears

**Causes**:
- Incorrect suffix syntax (`:auto` vs `:confirm`)
- AskUserQuestion tool not available
- Mode detection logic not executing

**Solutions**:
1. Use correct syntax: `/system_update:workflow:auto` or `/system_update:workflow:confirm`
2. If no suffix: Command should prompt for mode selection via AskUserQuestion
3. Check allowed-tools includes `AskUserQuestion` in frontmatter
4. Try with explicit mode suffix to bypass selection

---

### Problem: Approval checkpoint doesn't appear (confirm mode)

**Symptoms**: Interactive mode runs without pausing for approval

**Causes**:
- Using `:auto` suffix instead of `:confirm`
- YAML file missing approval_checkpoint blocks
- Complexity level set to skip approvals

**Solutions**:
1. Verify using `:confirm` suffix: `/system_update:workflow:confirm ...`
2. Check confirm.yaml has approval_checkpoint sections
3. For complexity:quick, only critical changes trigger step 5 approval
4. Review approval decision logic in YAML workflow

---

### Problem: Input transformation fails or fields not recognized

**Symptoms**: REQUEST empty error, or fields not extracted from arguments

**Causes**:
- Missing required `request` field
- Incorrect field syntax (quotes, colons)
- Input transformation logic not recognizing patterns

**Solutions**:
1. Always provide request in quotes: `/system_update:workflow:auto "Improve files" ...`
2. Use correct field syntax:
   - `context:"..."` (quoted value)
   - `reference:path/to/file.md` (unquoted path)
   - `complexity:standard` (unquoted value)
   - `output:./folder/` (unquoted path)
3. Check command file for field extraction patterns (lines 84-91)
4. Simplify input and add fields incrementally

---

### Problem: Output folder permission denied

**Symptoms**: Error writing files to output folder

**Causes**:
- Output folder doesn't exist
- No write permissions to output folder
- Invalid path specified

**Solutions**:
1. Create output folder: `mkdir -p ./output`
2. Check permissions: `ls -ld ./output`
3. Use different output folder: `output:/tmp/system-update-output/`
4. Specify absolute path instead of relative: `output:/Users/name/output/`

---

### Problem: Target files not found

**Symptoms**: Error: "Target files not accessible"

**Causes**:
- File paths don't exist
- Glob patterns don't match any files
- Incorrect path syntax

**Solutions**:
1. Verify files exist: `ls path/to/files`
2. Test glob pattern: `ls .claude/skills/*/SKILL.md`
3. Use absolute paths if relative paths fail
4. Check for typos in file paths

---

### Problem: Workflow execution stops or hangs

**Symptoms**: Command starts but doesn't complete, no error message

**Causes**:
- Waiting for approval in confirm mode
- YAML workflow has syntax error
- Large file processing taking time
- AI agent encountering unexpected condition

**Solutions**:
1. Check if awaiting approval (confirm mode step 3 or 5)
2. Validate YAML syntax: `yamllint .claude/commands/system_update/assets/*.yaml`
3. For large files, allow more time (standard complexity: 2-5 minutes)
4. Check Claude Code logs for errors
5. Try with simpler input first to isolate issue

---

### Problem: Wrong complexity level applied

**Symptoms**: Unexpected approval behavior or analysis depth

**Causes**:
- Typo in complexity value
- Default "standard" being used
- Complexity field not recognized

**Solutions**:
1. Use exact values: `complexity:quick`, `complexity:standard`, or `complexity:deep`
2. Check for typos (case-sensitive)
3. If omitted, "standard" is used by default
4. Verify complexity field appears in command invocation

---

### Problem: Reference files not being used

**Symptoms**: Improvements don't align with reference files

**Causes**:
- Reference file path incorrect
- Reference field syntax wrong
- YAML workflow not loading references

**Solutions**:
1. Use correct syntax: `reference:path/to/reference.md`
2. Verify reference file exists: `ls path/to/reference.md`
3. For multiple references, may need to specify in context instead
4. Check YAML workflow handles already_improved_reference_files field

---

### Getting More Help

If problems persist:

1. **Check YAML Files**: Validate syntax with `yamllint .claude/commands/system_update/*.yaml`
2. **Review Manual Tests**: See `specs/006-commands/005-system-updater-command/manual-test-checklist.md`
3. **Read Implementation Docs**: See `specs/006-commands/005-system-updater-command/IMPLEMENTATION.md`
4. **Test with Minimal Input**: Start simple and add complexity incrementally
5. **Check Claude Code Logs**: Look for error messages or warnings in console
