---
description: Enhance prompts using DEPTH framework with AI-guided analysis and quality scoring
argument-hint: "<prompt-text> [:quick|:improve|:refine]"
allowed-tools: Read, Write, AskUserQuestion
---

# Improve Prompt - DEPTH Framework

Transform raw prompts into optimized, framework-structured prompts using DEPTH methodology (Discover, Engineer, Prototype, Test, Harmonize).

## Input

```text
$ARGUMENTS
```

---

## Purpose

Apply systematic prompt enhancement with:
- **Framework selection** - Auto-select from 7 frameworks (RCAF, COSTAR, RACE, CIDI, TIDD-EC, CRISPE, CRAFT)
- **Quality scoring** - CLEAR evaluation (50-point scale)
- **Dual output** - Analysis markdown + YAML prompt files

---

## Contract

**Input:** `$ARGUMENTS` = prompt text + optional mode (`:quick`, `:improve`, `:refine`)

**Output:** Two files (see Phase 6 in `.claude/commands/prompt_improver/assets/prompt_improver:workflow.yaml`)
1. `prompt_analysis.md` - Human-readable quality assessment
2. `enhanced_prompt.yaml` - Machine-readable prompt with metadata

**Modes:**
- **:quick** - Fast enhancement (1-5 rounds, auto-framework, <10s)
- **:improve** - Full DEPTH (10 rounds, interactive framework selection)
- **:refine** - Polish existing prompt (preserve framework, focus on clarity)
- **Default** - Interactive mode with full user participation

**Status:** `STATUS=OK ANALYSIS={path} PROMPT={path}` or `STATUS=ERROR|CANCELLED`

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

---

### Phase 2-5: Execute DEPTH Workflow

3. **Invoke `.claude/commands/prompt_improver/assets/prompt_improver:workflow.yaml`** with:
   - `prompt_text`: Original prompt
   - `mode`: Detected mode
   - `rounds`: 1-5 (quick) or 10 (others)

4. **DEPTH phases execute autonomously:**
   - **D (Discover)**: Analyze intent, assess complexity (1-10), identify RICCE gaps
   - **E (Engineer)**: Select framework, apply cognitive rigor, restructure
   - **P (Prototype)**: Generate enhanced draft, validate RICCE (5/5)
   - **T (Test)**: Calculate CLEAR scores (original vs enhanced)
   - **H (Harmonize)**: Final polish, verify ≥40/50 target

5. **Framework selection logic** (auto or interactive based on complexity):
   - Complexity 1-4: Auto-select RCAF
   - Complexity 5-6: Prompt user (RCAF / COSTAR / TIDD-EC)
   - Complexity 7: Prompt user (RCAF streamlined / CRAFT comprehensive)
   - Complexity 8-10: Auto-select CRAFT

6. **Quality validation:**
   ```
   If enhanced_score >= 40 AND delta >= 5:
     Proceed to Phase 6
   Else if mode = "quick" AND enhanced_score > original_score:
     Proceed to Phase 6
   Else:
     AskUserQuestion: Retry refinement / Accept current / Cancel
   ```

---

### Phase 6: Dual Output Generation

**See `.claude/commands/prompt_improver/assets/prompt_improver:workflow.yaml` Phase 6 for complete workflow.**

7. **Determine output location:**
   ```
   If .claude/.spec-active.$$ exists:
     base_path = [file contents]
   Else if .claude/.spec-active exists:
     base_path = [file contents]
   Else:
     base_path = /export/
     Use sequential numbering: [###]-prompt-analysis-[timestamp].md
   ```

8. **Write both files:**
   - File 1: `{base_path}/prompt_analysis.md` (7 sections: header, quality, RICCE, framework, cognitive rigor, improvements, metadata)
   - File 2: `{base_path}/enhanced_prompt.yaml` (metadata + framework-specific prompt components)
   - **Critical:** Both must succeed for STATUS=OK (atomic guarantee)

9. **Report success:**
   ```
   ✅ Enhanced prompt generated successfully!

   📄 Files created:
   - Analysis: {analysis_file_path}
   - Prompt:   {prompt_file_path}

   📊 Quality:
   - Original: {original_score}/50
   - Enhanced: {enhanced_score}/50
   - Improvement: +{delta} points

   🔧 Framework: {framework_name}

   STATUS=OK ANALYSIS={analysis_path} PROMPT={prompt_path}
   ```

---

## CLEAR Scoring (50 points)

| Dimension       | Weight | Max | Description                          |
|-----------------|--------|-----|--------------------------------------|
| Correctness (C) | 20%    | 10  | Accuracy, terminology                |
| Logic (L)       | 20%    | 10  | Reasoning structure, coherence       |
| Expression (E)  | 30%    | 15  | Clarity, precision, readability      |
| Arrangement (A) | 20%    | 10  | Organization, hierarchy              |
| Reusability (R) | 10%    | 5   | Adaptability, modularity             |

**Target:** ≥40/50 overall, ≥8/10 per dimension (≥12/15 for Expression)

---

## RICCE Validation

Enhanced prompt must contain:
- ✅ **Role** - Clearly defined persona/expertise
- ✅ **Instructions** - Unambiguous tasks/steps
- ✅ **Context** - Relevant background info
- ✅ **Constraints** - Explicit boundaries/requirements
- ✅ **Examples** - Concrete demonstrations (or N/A if not applicable)

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

## Error Recovery

| Condition | Action |
|-----------|--------|
| Empty prompt | AskUserQuestion with 4 options → Retry |
| Score below target | Prompt: retry / accept / cancel |
| Framework timeout | Default to RCAF → Notify → Continue |
| YAML not found | Error: "Missing .claude/commands/prompt_improver/assets/prompt_improver:workflow.yaml" |
| Write permission denied | Output to chat → Suggest manual save |

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
- ✅ Calculate CLEAR scores rigorously (no fabrication)
- ✅ Generate BOTH files (analysis.md + prompt.yaml)
- ✅ Replace all placeholders in YAML (no `{ACTUAL_*}` text in output)
- ✅ Validate RICCE completeness (5/5 or 4/5 with N/A)
- ❌ NEVER skip framework selection rationale
- ❌ NEVER leave placeholder text in YAML output
- ❌ NEVER proceed with <40/50 without user confirmation

---

## Notes

**Dual-Output Architecture:**
- `prompt_analysis.md` = Human review (quality assessment, RICCE, framework rationale)
- `enhanced_prompt.yaml` = Machine import (direct use in workflows/tools)
- Both files reference each other for traceability

**Integration:**
- Saves to active spec folder if available (`.claude/.spec-active.$$`)
- Falls back to `/export/` with sequential numbering
- YAML format enables direct import: `yaml.safe_load(open('enhanced_prompt.yaml'))`

**Performance Targets:**
- Quick: <10s | Improve/Refine: <30s | Interactive: <30s (+ user wait)

**Workflow Details:**
- Complete implementation: `.claude/commands/prompt_improver/assets/prompt_improver:workflow.yaml`
- Phase 6 (Dual Output): Steps 13-17 with atomic write guarantees
- Framework templates: All 7 frameworks fully specified
