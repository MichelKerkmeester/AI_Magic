---
description: Enhance prompts using DEPTH framework with AI-guided analysis
argument-hint: "<prompt-text> [:quick|:improve|:refine]"
allowed-tools: Read, Write, AskUserQuestion
---

# ⛔ MANDATORY GATES - BLOCKING ENFORCEMENT

**YOU MUST COMPLETE ALL GATES BEFORE READING ANYTHING ELSE IN THIS FILE.**

These gates are BLOCKING - you cannot proceed past any gate until its condition is satisfied.

---

## GATE 0: Input Validation ⛔ HARD STOP

**Check `$ARGUMENTS` for prompt text to improve:**

```
IF $ARGUMENTS is empty, undefined, or contains only whitespace:
    ⛔ BLOCKED - Cannot proceed
    
    ACTION REQUIRED:
    1. Use AskUserQuestion tool with this exact question:
       question: "What prompt would you like me to improve?"
       options:
         - label: "Provide prompt text"
           description: "I'll paste or describe the prompt to improve"
    2. WAIT for user response
    3. Capture response as: prompt_text = ______
    4. Only THEN proceed to GATE 1

IF $ARGUMENTS contains prompt text:
    ✅ Capture: prompt_text = $ARGUMENTS
    → Proceed to GATE 1
```

**GATE 0 Output:**
- `prompt_text = ______` (REQUIRED - must be filled before continuing)

---

## GATE 1: Spec Folder Selection ⛔ HARD STOP

**You MUST ask user to select a spec folder option. DO NOT SKIP THIS QUESTION.**

```
⛔ BLOCKED until user explicitly selects A, B, C, or D

ACTION REQUIRED:
1. Use AskUserQuestion tool with these exact options:
   question: "Where should I save the prompt improvement documentation?"
   options:
     A) Use existing spec folder - [suggest relevant existing folder if found]
     B) Create new spec folder - specs/[###-prompt-improvement]/
     C) Update related spec - [suggest if related spec exists]
     D) Skip documentation - (output directly without saving)

2. WAIT for user response
3. Capture: spec_folder_choice = ______ (A, B, C, or D)
4. Capture: spec_folder_path = ______
5. Only THEN proceed to GATE 2 (if applicable) or continue workflow
```

**GATE 1 Output:**
- `spec_folder_choice = ______` (REQUIRED - A, B, C, or D)
- `spec_folder_path = ______` (REQUIRED - actual path, or "N/A" if D)

---

## GATE 2: Memory Context Loading (Conditional)

**This gate only applies if user selected Option A or C in GATE 1.**

```
IF spec_folder_choice is A or C AND memory/ folder exists with files:
    → Auto-load the most recent memory file (DEFAULT)
    → Briefly confirm: "Loaded context from [filename]"
    → User can say "skip memory" or "fresh start" to bypass
    
IF spec_folder_choice is B or D:
    → Skip this gate (no memory to load)
    ✅ Proceed to workflow
```

---

## Gate Status Verification

Before proceeding, verify all gates are passed:

| Gate | Status | Required Output |
|------|--------|-----------------|
| GATE 0 | ⬜ | `prompt_text = ______` |
| GATE 1 | ⬜ | `spec_folder_choice = ______`, `spec_folder_path = ______` |
| GATE 2 | ⬜ | Memory loaded OR skipped (conditional) |

**All gates must show ✅ before continuing to the workflow below.**

---

## Violation Self-Detection

If you notice yourself:
- Reading workflow steps before completing gates → ⛔ STOP, return to incomplete gate
- Assuming prompt text without explicit input → ⛔ STOP, return to GATE 0
- Skipping spec folder question → ⛔ STOP, return to GATE 1
- Proceeding without user's explicit choice → ⛔ STOP, ask the required question

**Recovery Protocol:** State "I need to complete the mandatory gates first" and return to the first incomplete gate.

---

# Improve Prompt - DEPTH Framework

Transform raw prompts into optimized, framework-structured prompts using DEPTH methodology (Discover, Engineer, Prototype, Test, Harmonize).

---

```yaml
role: Prompt Engineering Specialist with Multi-Perspective Analysis Expertise
purpose: Transform raw prompts into optimized, framework-structured prompts through systematic DEPTH methodology
action: Apply 5-phase enhancement workflow with cognitive rigor and framework selection

operating_mode:
  workflow: sequential_with_cognitive_rigor
  workflow_compliance: MANDATORY
  workflow_execution: autonomous_with_user_checkpoints
  approvals: framework_selection_for_complexity_5_plus
  tracking: phase_round_progress_transparent
  validation: qualitative_completeness_check
```

---

## User Input

```text
$ARGUMENTS
```

---

## Workflow Overview (5 Phases)

| Phase | Name | Purpose | Outputs |
|-------|------|---------|---------|
| 1 | Discover | Analyze intent, assess complexity | complexity_score, gap_analysis |
| 2 | Engineer | Select framework, restructure | framework_selection, structure |
| 3 | Prototype | Generate enhanced draft | enhanced_prompt_draft |
| 4 | Test | Validate clarity and completeness | validation_report |
| 5 | Harmonize | Final polish for consistency | spec.md, enhanced_prompt.yaml |

---

## Mode Detection & Routing

| Pattern | Mode | Behavior |
|---------|------|----------|
| `/prompt_improver:workflow:quick` | QUICK | 1-5 rounds, auto-framework |
| `/prompt_improver:workflow:improve` | FULL | 10 rounds, interactive framework selection |
| `/prompt_improver:workflow:refine` | REFINE | Preserve framework, polish clarity |
| `/prompt_improver:workflow` (no suffix) | INTERACTIVE | Full user participation |

---

## Purpose

Apply systematic prompt enhancement with:
- **Framework selection** - Auto-select from 7 frameworks (RCAF, COSTAR, RACE, CIDI, TIDD-EC, CRISPE, CRAFT)
- **Iterative refinement** - Multi-round improvement for clarity and structure
- **Dual output** - SpecKit spec.md + YAML prompt for comprehensive documentation

---

## Contract

**Input:** `$ARGUMENTS` = prompt text + optional mode (`:quick`, `:improve`, `:refine`)

**Output:** Always creates spec folder with both files:
1. **spec.md** - Simplified specification (Purpose, Original Prompt, numbered framework sections)
2. **enhanced_prompt.yaml** - Pure YAML prompt (NO metadata wrapper, just framework components at top-level)

**Location:** User-selected spec folder (A/B/C/D choice following SpecKit workflow)

**Modes:**
- **:quick** - Fast enhancement (1-5 rounds, auto-framework, <10s)
- **:improve** - Full DEPTH (10 rounds, interactive framework selection)
- **:refine** - Polish existing prompt (preserve framework, focus on clarity)
- **Default** - Interactive mode with full user participation

**Status:** `STATUS=OK SPEC={folder} FILES={spec.md,enhanced_prompt.yaml}` or `STATUS=ERROR|CANCELLED`

---

## Instructions

### Phase 1: Parse Input

1. **Extract mode and prompt:**
   ```
   If $ARGUMENTS ends with :quick/:improve/:refine:
     mode = [detected mode]
     prompt_text = $ARGUMENTS minus mode flag
   Else:
     mode = "interactive"
     prompt_text = $ARGUMENTS
   ```

2. **Validate prompt:**
   - If empty: Use AskUserQuestion with options (paste text / describe intent / file path / cancel)
   - Store: `original_prompt`, `original_length`, `mode`, `timestamp_start`

3. **Spec folder selection (follows standard SpecKit workflow):**
   - Find next spec number: `ls -d specs/[0-9]*/ | sed 's/.*\/\([0-9]*\)-.*/\1/' | sort -n | tail -1`
   - Suggest name: `enhanced-prompt` or based on prompt content
   - Use AskUserQuestion with 4 options (A/B/C/D pattern from AGENTS.md):
     - **A)** Use existing spec folder (if .spec-active exists)
     - **B)** Create new spec folder: `specs/[###]-[suggested-name]/`
     - **C)** Update related spec (show any existing prompt-related specs)
     - **D)** Skip documentation (creates `.claude/.spec-skip` marker) - NOT RECOMMENDED
   - Store: `spec_folder_path`, `spec_folder_choice`

### Phase 1.3: Verify Gates Passed

Before continuing, confirm all gates are complete:

```
□ GATE 0: prompt_text captured from $ARGUMENTS or user response
□ GATE 1: spec_folder_choice explicitly selected (A/B/C/D)
□ GATE 2: Memory loaded (if applicable) or skipped

If ANY gate incomplete → STOP and return to that gate
```

---

### Phase 2-5: Execute DEPTH Workflow

3. **Invoke workflow YAML** (search order: `.claude/commands/prompt_improver/assets/improve_prompt.yaml` → `.opencode/command/prompt_improver/assets/improve_prompt.yaml`) with:
   - `prompt_text`: Original prompt
   - `mode`: Detected mode
   - `rounds`: 1-5 (quick) or 10 (others)
   
   **Fallback logic:** If not found in `.claude/`, automatically search `.opencode/` folder.

4. **DEPTH phases execute autonomously:**
   - **D (Discover)**: Analyze intent, assess complexity (1-10), identify gaps
   - **E (Engineer)**: Select framework, apply cognitive rigor, restructure
   - **P (Prototype)**: Generate enhanced draft with clear structure
   - **T (Test)**: Validate clarity, completeness, and actionability
   - **H (Harmonize)**: Final polish for consistency and flow

5. **Framework selection logic** (auto or interactive based on complexity):
   - Complexity 1-4: Auto-select RCAF
   - Complexity 5-6: Prompt user (RCAF / COSTAR / TIDD-EC)
   - Complexity 7: Prompt user (RCAF streamlined / CRAFT comprehensive)
   - Complexity 8-10: Auto-select CRAFT

6. **Quality validation:**
   - Verify prompt has clear role, context, and actionable instructions
   - Check framework components are complete and substantive
   - Ensure no placeholder text remains

---

### Phase 6: Dual Output Generation

**See workflow YAML Phase 6 for complete workflow (searched in `.claude/` then `.opencode/`).**

7. **Use spec folder from Phase 1 step 3:**
   ```
   # Spec folder already determined by user choice (A/B/C/D)
   base_path = {spec_folder_path from Phase 1}

   # If user selected D (skip), fall back to /export/
   If spec_folder_path is empty:
     base_path = /export/
     Use sequential numbering: [###]-enhanced-prompt/
   ```

8. **Write both output files to spec folder:**
   - **File 1 - spec.md** (Simplified specification):
     - `# Feature Specification: Enhanced Prompt - {title}` - Title with framework
     - `### Purpose` - What the enhanced prompt accomplishes
     - `### Original Prompt` - The raw input prompt
     - `## 1. {COMPONENT}` - First framework component (e.g., TASK, ROLE)
     - `## 2. {COMPONENT}` - Second framework component
     - ... numbered sections for each framework component
     - **NO** metadata, scope, success criteria, usage, or appendix sections

   - **File 2 - enhanced_prompt.yaml** (Pure YAML - NO metadata):
     - Header comment only (title + framework name)
     - Framework components at top-level (e.g., `role:`, `context:`, `action:`, `format:`)
     - **NO** `metadata:` section
     - **NO** `prompt:` wrapper
     - **NO** timestamps or complexity scores
     - Direct import ready: `yaml.safe_load(open('enhanced_prompt.yaml'))` returns framework components

9. **Report success:**
   ```
   ✅ Enhanced prompt created successfully!

   📁 Spec folder: {spec_folder_path}
   📄 Files created:
   - spec.md (simplified specification)
   - enhanced_prompt.yaml (machine-readable)

   🔧 Framework: {framework_name}
   📐 Complexity: {complexity}/10

   STATUS=OK SPEC={spec_folder_path} FILES=spec.md,enhanced_prompt.yaml
   ```

---

## Framework Quick Reference

| Framework | Components | Best For | Complexity |
|-----------|-----------|----------|------------|
| **RCAF** | role, context, action, format | General-purpose | 1-6 |
| **COSTAR** | context, objective, style, tone, audience, response | Communication | 5-6 |
| **RACE** | role, action, context, examples | Rapid prototyping | 3-5 |
| **CIDI** | context, instructions, details, input | Creative/ideation | 4-6 |
| **TIDD-EC** | task, instructions, details, deliverables, examples, constraints | Technical specs | 5-7 |
| **CRISPE** | capacity, role, insight, statement, personality, experiment | System prompts | 4-6 |
| **CRAFT** | context, role, action, format, target | Multi-stakeholder | 7-10 |

---

## Failure Recovery

| Failure Type | Recovery Action |
|--------------|-----------------|
| Enhancement incomplete | Prompt: retry refinement / accept current / cancel |
| Framework timeout | Default to RCAF → Notify → Continue |
| YAML workflow missing | Search `.claude/` then `.opencode/` → Error if both fail |
| Write permission denied | Output to chat → Suggest manual save |

---

## Error Handling

| Condition | Action |
|-----------|--------|
| Empty `$ARGUMENTS` | AskUserQuestion with 4 options (paste/describe/file/cancel) |
| Invalid mode suffix | Default to INTERACTIVE mode |
| Framework selection fails | Auto-select RCAF as fallback |
| Spec folder conflict | Prompt for resolution (A/B/C/D options) |

---

## Context Loading

When resuming in an existing spec folder with prior prompt work:
- **A)** Load most recent enhanced_prompt.yaml (quick context)
- **B)** Load all recent files (comprehensive)
- **C)** List all files and select specific
- **D)** Skip (start fresh)

---

## Templates Used

- `.claude/commands/prompt_improver/assets/improve_prompt.yaml` - DEPTH workflow logic
- `.opencode/speckit/templates/spec.md` - SpecKit specification output

---

## Completion Report

After workflow completion, report:

```
Prompt Enhancement Complete

Spec folder: {spec_folder_path}
Framework: {framework_name}
Complexity: {complexity}/10
Rounds: {round_count}

Files created:
- spec.md (SpecKit specification)
- enhanced_prompt.yaml (machine-readable)

STATUS=OK SPEC={spec_folder_path} FILES=spec.md,enhanced_prompt.yaml
```

---

## Examples

### Quick Mode
```bash
/prompt_improver:workflow:quick "Analyze user feedback"
```
Output: 3-5 rounds, RCAF framework, ~5 seconds

### Interactive Mode
```bash
/prompt_improver:workflow "Review code for architecture and performance"
```
Output: 10 rounds, user selects framework (complexity 5-6), ~12 seconds

### Refine Mode
```bash
/prompt_improver:workflow:refine "Role: Data scientist. Task: Analyze IoT sensor data..."
```
Output: Preserves existing framework, polishes clarity, ~9 seconds

---

## Critical Rules

- ✅ Execute full DEPTH (10 rounds) unless :quick mode
- ✅ Generate BOTH files (spec.md + enhanced_prompt.yaml)
- ✅ Replace all placeholders in YAML (no `{ACTUAL_*}` text in output)
- ✅ Ensure framework components are complete and substantive
- ❌ NEVER skip framework selection rationale
- ❌ NEVER leave placeholder text in YAML output
- ❌ NEVER proceed with incomplete prompts without user confirmation

---

## Notes

**Dual-Output Architecture:**
- `spec.md` = Human review (simplified: Purpose, Original Prompt, numbered framework sections)
- `enhanced_prompt.yaml` = Pure YAML prompt content (NO metadata, direct use)
- Both files stored in same spec folder

**YAML Output - Pure Prompt Content:**
- YAML contains ONLY the enhanced prompt itself
- NO metadata section, timestamps, or complexity scores
- Framework components directly at top-level (e.g., `role:`, `context:`, `action:`, `format:`)
- Direct import ready: `data = yaml.safe_load(open('enhanced_prompt.yaml'))` returns prompt components
- Example: `data['role']`, `data['context']`, `data['action']`

**spec.md - Simplified Structure:**
- Title and brief framework description
- Purpose section explaining what the enhanced prompt accomplishes
- Original Prompt section with the raw input
- Numbered sections for each framework component (## 1. TASK, ## 2. INSTRUCTIONS, etc.)
- NO metadata, scope, success criteria, usage, or appendix sections

**Integration:**
- Saves to active spec folder if available
- Falls back to `/export/` with sequential numbering
- YAML ready for copy/paste into AI workflows

**Workflow Details:**
- Complete implementation: `improve_prompt.yaml` (in `.claude/commands/` or `.opencode/command/`)
- Phase 6 (Dual Output): Steps 13-17 with atomic write guarantees
- Framework templates: All 7 frameworks output as pure YAML
