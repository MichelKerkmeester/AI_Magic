---
description: Transform raw requests into structured YAML user_inputs fields
argument-hint: "<raw-request-text> [target-prompt-path]"
allowed-tools: Read, Write, AskUserQuestion, Bash
---

# Transform Request to User Inputs

Convert natural language feature requests into properly structured YAML user_inputs blocks for use with SpecKit prompts and workflow automation.

## User Input

```text
$ARGUMENTS
```

---

## Purpose

This command transforms raw, unstructured feature descriptions into properly formatted YAML user_inputs configurations by:

1. **Analyzing target prompt structure** - Reads the destination prompt file to understand required fields
2. **Extracting context from natural language** - Parses objectives, constraints, deliverables from raw text
3. **Mapping elements to YAML fields** - Intelligently populates user_inputs with proper syntax
4. **Validating completeness** - Ensures all required fields are present with valid YAML syntax

**Use this command when:**
- Starting a new SpecKit workflow and need to convert your idea into structured input
- Have a feature description but don't want to manually format YAML
- Want to ensure proper user_inputs structure before running `/spec_kit:complete`, `/spec_kit:plan`, etc.

---

## Workflow Overview (4 Phases)

| Phase | Name | Purpose | Outputs |
|-------|------|---------|---------|
| 1 | Parse Arguments | Extract request text and target prompt selection | raw_request, target_prompt_path |
| 2 | Read Target Prompt | Analyze prompt structure and required fields | required_fields, optional_fields, field_examples |
| 3 | Transform Request | Apply 9-step workflow to generate YAML | user_inputs YAML block |
| 4 | Validate & Output | Verify YAML syntax and write to file | validated_yaml_file, validation_report |

---

## Contract

**Inputs:** `$ARGUMENTS` = raw request text (REQUIRED) + target prompt path (OPTIONAL)

**Outputs:**
- YAML user_inputs block written to file
- Validation report (syntax + completeness)
- `STATUS=OK|FAIL|CANCELLED`

**Example Invocation:**
```bash
/transform_request "Add user authentication to the dashboard using OAuth2"
/transform_request "Add newsletter signup" .opencode/prompts/spec_kit/spec_kit_complete_auto.yaml
```

---

## Instructions

Execute the following phases to transform raw requests into structured YAML:

### Phase 1: Parse Arguments

**Extract from `$ARGUMENTS`:**
1. **raw_request_text** (REQUIRED) - The natural language feature description
2. **target_prompt_path** (OPTIONAL) - Path to the prompt YAML file to analyze

**If target_prompt_path is empty:**

Use AskUserQuestion to select target prompt:

```
Which prompt template should I analyze for user_inputs structure?

**A) SpecKit Complete** (.opencode/prompts/spec_kit/spec_kit_complete_auto.yaml)
  - Full end-to-end workflow (spec, plan, tasks, implementation)
  - Use for: Complete feature development from idea to code

**B) SpecKit Plan** (.opencode/prompts/spec_kit/spec_kit_plan_auto.yaml)
  - Specification and planning only (spec, plan)
  - Use for: Planning phase before implementation

**C) SpecKit Implement** (.opencode/prompts/spec_kit/spec_kit_implement_auto.yaml)
  - Implementation execution only (requires existing plan)
  - Use for: Executing pre-planned work

**D) Custom Path**
  - Provide your own prompt YAML file path
  - Use for: Custom workflow prompts

Your choice? (A, B, C, or D)
```

**Wait for user response before proceeding.**

If user selects D (Custom Path), prompt for the path.

**Validation checkpoint:**
- [ ] Raw request text extracted and non-empty
- [ ] Target prompt path identified (selected or provided)
- [ ] User response received (no timeout)

---

### Phase 2: Read Target Prompt

**Read and parse target prompt file:**

1. **Load YAML file** from target_prompt_path
   ```
   Use Read tool to load the file
   ```

2. **Parse user_inputs section:**
   - Identify all fields defined in user_inputs
   - Note which fields are required vs optional
   - Extract field descriptions and examples
   - Understand field types (string, multiline, etc.)

3. **Validate prompt file exists:**
   ```
   If Read fails:
     STATUS=FAIL
     ERROR="Cannot read target prompt: [path]"
     SUGGESTION="Verify file exists and path is correct. Try:
       - .opencode/prompts/spec_kit/spec_kit_complete_auto.yaml
       - .opencode/prompts/spec_kit/spec_kit_plan_auto.yaml
       - .opencode/prompts/spec_kit/spec_kit_implement_auto.yaml"
     Exit
   ```

**Output from this phase:**
- target_prompt_structure (parsed field definitions)
- required_fields (list of mandatory fields)
- optional_fields (list of optional fields)
- field_examples (reference examples from prompt)

**Validation checkpoint:**
- [ ] Target prompt file loaded successfully
- [ ] user_inputs section identified and parsed
- [ ] Required vs optional fields distinguished
- [ ] Field structure understood

---

### Phase 3: Transform Request (Invoke YAML Transformation Workflow)

**Load transformation workflow:**

Read and execute `.opencode/prompts/transform_request.yaml` which implements the 9-step transformation process:

**Step 1: Target Prompt Analysis**
- Understand prompt purpose and context
- Map field structure to transformation logic

**Step 2: Request Parsing**
- Extract primary objectives from raw request
- Identify deliverables mentioned
- Detect constraints and requirements
- Determine scope and boundaries

**Step 3: Context Analysis**
- Infer domain context from mentioned tools/frameworks
- Extract constraints (performance, compatibility, patterns)
- Reference standards and guidelines
- Note platform or environmental constraints

**Step 4: Field Mapping**
- Match parsed elements to target prompt fields
- Determine which fields can be populated from request
- Identify missing information for required fields

**Step 5: Issues Identification**
- Analyze current state (if described)
- Note problems to address
- Flag unknowns needing discovery
- Document assumptions being made

**Step 6: Field Generation**
- Generate content for each field using proper YAML syntax
- Use pipe literal format `|` for multi-line content
- Include placeholders for unclear fields: `[NEEDS CLARIFICATION: ...]`
- Follow YAML indentation rules (2 spaces)

**Step 7: Decision Making**
- Assess complexity if applicable
- Determine approach if prompt requires it
- Justify choices with rationale

**Step 8: Output Assembly**
- Assemble complete user_inputs YAML block
- Format with proper structure and indentation
- Add comments for auto-generated fields
- Include key decisions summary

**Step 9: YAML Validation**
- Validate YAML syntax (proper indentation, quotes, literals)
- Check all required fields are populated
- Ensure no empty required fields
- Verify pipe literals used correctly for multi-line content

**If required fields cannot be inferred:**

Use AskUserQuestion to clarify missing information.

Example:
```
I need clarification to complete the user_inputs:

**Field: [field_name]**
Description: [field description from prompt]

What should I use for this field?

**A)** [intelligent suggestion 1]
**B)** [intelligent suggestion 2]
**C)** [intelligent suggestion 3]
**D)** Provide custom value

Your choice?
```

Wait for user response and incorporate into YAML.

**Validation checkpoint:**
- [ ] 9-step transformation workflow executed completely
- [ ] All required fields populated or flagged for clarification
- [ ] YAML structure follows proper syntax (pipe literals, indentation)
- [ ] User clarifications incorporated if requested

---

### Phase 4: Validate & Output

**Validation Steps:**

1. **Syntax Validation:**
   ```
   Check YAML syntax:
   - Proper indentation (2 spaces per level)
   - Pipe literals for multi-line (|)
   - Quotes escaped correctly
   - No trailing spaces
   - Valid YAML structure
   ```

2. **Completeness Check:**
   ```
   Verify all required fields:
   - All required_fields from target prompt are populated
   - No [PLACEHOLDER] text remaining
   - No empty string values for required fields
   - [NEEDS CLARIFICATION: ...] only in optional fields (if any)
   ```

3. **Auto-Fix Attempt (if validation fails):**
   ```
   Common fixes:
   - Add missing pipe literals for multi-line content
   - Correct indentation errors
   - Escape special characters (quotes, colons)
   - Remove trailing whitespace
   ```

   If auto-fix succeeds: Continue to output
   If auto-fix fails:
     STATUS=FAIL
     ERROR="YAML validation failed"
     DETAILS=[validation error messages]
     SUGGESTION="Review the following issues and correct manually:
       [list specific syntax errors]"
     Exit

**Determine Output Location:**

```
Check for active spec folder:
  If .claude/.spec-active.$$ exists:
    output_location = [contents of .spec-active file]/user_inputs.yaml
  Else if .claude/.spec-active exists (legacy):
    output_location = [contents of .spec-active file]/user_inputs.yaml
  Else:
    output_location = /export/[###]-user-inputs-[timestamp].yaml
    (where ### is next sequential number in /export/)
```

**Write YAML Block to File:**

Use Write tool to create the file with the generated user_inputs YAML block.

**Report Success:**

```
✅ YAML Transformation Complete

**Target Prompt Analyzed:**
- File: [target_prompt_path]
- Fields identified: [X required, Y optional]

**User Inputs Generated:**
- Fields populated: [list of populated fields]
- Clarifications needed: [list if any, or "None"]

**Validation:**
- Syntax check: PASSED ✅
- Completeness check: PASSED ✅
- All required fields: PRESENT ✅

**Output Location:**
- File: [output_location]

**Next Steps:**
1. Review generated YAML at [output_location]
2. Edit any [NEEDS CLARIFICATION: ...] placeholders if present
3. Use with SpecKit commands:
   /spec_kit:complete:auto [paste user_inputs content]

STATUS=OK PATH=[output_location]
```

**Validation checkpoint:**
- [ ] YAML syntax validated (passes parser check)
- [ ] All required fields present and non-empty
- [ ] Output file written successfully to correct location
- [ ] Success report displayed with STATUS=OK PATH

---

## Failure Recovery

| Condition | Recovery Action |
|-----------|-----------------|
| **Empty raw request** | Prompt user: "Please provide a feature description to transform" → Wait for input → Retry |
| **Invalid target prompt path** | Return error with suggestions for valid paths → Offer to retry with correct path |
| **YAML syntax errors** | Attempt auto-fix (indentation, literals, escaping) → If fails, return detailed error report |
| **Missing required fields** | Use AskUserQuestion to gather missing information → Incorporate responses → Regenerate YAML |
| **Write permission denied** | Fallback to outputting YAML in chat → Suggest manual file creation → Provide full YAML content |
| **Target prompt has no user_inputs** | Return error: "Selected prompt does not define user_inputs section" → Suggest alternative prompts |
| **Ambiguous request** | Flag ambiguous sections with [NEEDS CLARIFICATION: ...] → Prompt user for clarification → Update YAML |

---

## Examples

### Example 1: Simple Request

**Input:**
```bash
/transform_request "Add user authentication to the dashboard"
```

**User selects:** A (SpecKit Complete)

**Output:**
```yaml
user_inputs:
  git_branch: "feature-add-authentication"
  spec_folder: "specs/010-user-authentication"
  request: |
    Add user authentication to the dashboard
  context: |
    Feature requires authentication implementation for dashboard access.
    Assumes existing user management system.
  issues: ""
  environment: ""
  scope: |
    dashboard/**/*.ts
    components/auth/**
```

**Status:** `STATUS=OK`

---

### Example 2: Complex Request with Details

**Input:**
```bash
/transform_request "Add user authentication with OAuth2 to dashboard. Use Passport.js. Support Google and GitHub. Staging: https://staging.example.com. Files in src/auth/ and src/middleware/"
```

**User selects:** A (SpecKit Complete)

**Output:**
```yaml
user_inputs:
  git_branch: "feature-oauth2-authentication"
  spec_folder: "specs/011-oauth2-auth"
  request: |
    Add user authentication with OAuth2 to dashboard using Passport.js.
    Support Google and GitHub OAuth providers.
  context: |
    Technical stack: Passport.js for OAuth2 implementation
    OAuth providers: Google, GitHub
    Integration points: Dashboard authentication flow
  issues: |
    Current state: No authentication mechanism in place
    Concerns: OAuth provider configuration, token management
    Unknowns: Session storage strategy, refresh token handling
  environment: "https://staging.example.com"
  scope: |
    src/auth/**
    src/middleware/**
```

**Status:** `STATUS=OK`

---

### Example 3: Interactive Clarification

**Input:**
```bash
/transform_request "Refactor the payment module"
```

**System:** Asks which prompt template (user selects A)

**System:** Identifies vague request, prompts for clarification:
```
I need clarification to complete the user_inputs:

**Field: request**
The request "Refactor the payment module" is vague.

What is the primary goal of this refactoring?

**A)** Improve performance (optimize database queries, reduce API calls)
**B)** Improve maintainability (better code organization, add tests)
**C)** Add new features (new payment methods, subscription support)
**D)** Provide custom description

Your choice?
```

**User selects:** B

**Output:**
```yaml
user_inputs:
  git_branch: "refactor-payment-maintainability"
  spec_folder: "specs/012-payment-refactor"
  request: |
    Refactor the payment module to improve maintainability.
    Focus on better code organization and adding comprehensive tests.
  context: |
    Refactoring goal: Improve maintainability and code quality
    Technical focus: Code organization, test coverage
  issues: |
    Current state: Payment module lacks clear organization and test coverage
    Concerns: Potential breaking changes during refactoring
  environment: ""
  scope: |
    src/payments/**
```

**Status:** `STATUS=OK`

---

### Example 4: Error Handling

**Input:**
```bash
/transform_request "" /nonexistent/path.yaml
```

**Output:**
```
❌ YAML Transformation Failed

**Error:** Cannot read target prompt: /nonexistent/path.yaml

**Suggestion:** Verify file exists and path is correct. Try:
  - .opencode/prompts/spec_kit/spec_kit_complete_auto.yaml
  - .opencode/prompts/spec_kit/spec_kit_plan_auto.yaml
  - .opencode/prompts/spec_kit/spec_kit_implement_auto.yaml

STATUS=FAIL
```

---

## Notes

**Integration with SpecKit:**
- Generated YAML can be used directly with `/spec_kit:complete`, `/spec_kit:plan`, `/spec_kit:implement`
- Output location respects active spec folder (`.spec-active` marker)
- Falls back to `/export/` with sequential numbering if no active spec folder

**YAML Best Practices:**
- Always use pipe literal `|` for multi-line content
- Maintain 2-space indentation consistently
- Avoid special characters in field values (or quote them)
- Leave optional fields empty rather than using placeholder text

**Quality Assurance:**
- 100% YAML syntax validation required before output
- All required fields must be populated (no empty strings)
- Fallback to chat output if file write fails
- Clear error messages with actionable suggestions

---

## Related Commands

- `/spec_kit:complete` - Full SpecKit workflow using generated YAML
- `/spec_kit:plan` - Planning workflow using generated YAML
- `/spec_kit:implement` - Implementation workflow using generated YAML
- `/improve_prompt` - Enhance the generated prompt with DEPTH framework
