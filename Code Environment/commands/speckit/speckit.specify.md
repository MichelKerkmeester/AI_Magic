---
description: Create or update the feature specification from a natural language feature description.
---

## Command Purpose: Feature Requirements Definition

**WHAT IT DOES**: Transforms a natural language feature description into a structured, comprehensive specification document (spec.md) that defines requirements, user stories, success criteria, and scope WITHOUT implementation details.

**WHY IT EXISTS**: Creates a shared understanding of WHAT needs to be built before deciding HOW to build it. The spec serves as a contract between stakeholders and engineers, ensuring everyone agrees on the problem and desired outcomes.

**WHEN TO USE**: First step in any new feature development after an idea or request is identified. Run this before any planning or technical design.

**KEY PRINCIPLE**: Technology-agnostic requirements. The spec should be understandable by non-technical stakeholders and remain valid even if implementation technology changes.

## User Input

```text
$ARGUMENTS
```

You **MUST** consider the user input before proceeding (if not empty).

## Outline

The text the user typed after `/speckit.specify` in the triggering message **is** the feature description. Assume you always have it available in this conversation even if `$ARGUMENTS` appears literally below. Do not ask the user to repeat it unless they provided an empty command.

Given that feature description, do this:

1. **Generate a concise short name** (2-4 words) for the branch:
   - Analyze the feature description and extract the most meaningful keywords
   - Create a 2-4 word short name that captures the essence of the feature
   - Use action-noun format when possible (e.g., "add-user-auth", "fix-payment-bug")
   - Preserve technical terms and acronyms (OAuth2, API, JWT, etc.)
   - Keep it concise but descriptive enough to understand the feature at a glance
   - Examples:
     - "I want to add user authentication" -> "user-auth"
     - "Implement OAuth2 integration for the API" -> "oauth2-api-integration"
     - "Create a dashboard for analytics" -> "analytics-dashboard"
     - "Fix payment processing timeout bug" -> "fix-payment-timeout"

2. **Check for existing branches before creating new one**:
   
   a. First, fetch all remote branches to ensure we have the latest information:
      ```bash
      git fetch --all --prune
      ```
   
   b. Find the highest feature number across all sources for the short-name:
      - Remote branches: `git ls-remote --heads origin | grep -E 'refs/heads/[0-9]+-<short-name>$'`
      - Local branches: `git branch | grep -E '^[* ]*[0-9]+-<short-name>$'`
      - Specs directories: Check for directories matching `specs/[0-9]+-<short-name>`
   
   c. Determine the next available number:
      - Extract all numbers from all three sources
      - Find the highest number N
      - Use N+1 for the new branch number
   
   d. Run the script `.opencode/speckit/scripts/create-new-feature.sh --json "$ARGUMENTS"` with the calculated number and short-name:
      - Pass `--number N+1` and `--short-name "your-short-name"` along with the feature description
      - Bash example: `.opencode/speckit/scripts/create-new-feature.sh --json "$ARGUMENTS" --json --number 5 --short-name "user-auth" "Add user authentication"`
      - PowerShell example: `.opencode/speckit/scripts/create-new-feature.sh --json "$ARGUMENTS" -Json -Number 5 -ShortName "user-auth" "Add user authentication"`
   
   **IMPORTANT**:
   - Check all three sources (remote branches, local branches, specs directories) to find the highest number
   - Only match branches/directories with the exact short-name pattern
   - If no existing branches/directories found with this short-name, start with number 1
   - You must only ever run this script once per feature
   - The JSON is provided in the terminal as output - always refer to it to get the actual content you're looking for
   - The JSON output will contain BRANCH_NAME and SPEC_FILE paths
   - For single quotes in args like "I'm Groot", use escape syntax: e.g 'I'\''m Groot' (or double-quote if possible: "I'm Groot")

3. **Estimate Complexity and Select Documentation Level**:

   Analyze the feature description to determine appropriate documentation level:

   **Level 1 (Simple)** - Use `spec_template.md` with core sections only:
   - Simple, isolated feature
   - < 100 lines of code
   - Single component/module
   - No complex dependencies
   - Examples: add contact form, new UI component, simple API endpoint
   - Required sections: Metadata, Objective, Scope, Acceptance Criteria

   **Level 2 (Standard)** - Use `spec_template.md` fully:
   - Complex feature requiring coordination
   - ≥ 100 lines of code
   - Multiple components/systems
   - User stories needed
   - Formal requirements tracking needed
   - Examples: authentication system, payment integration, multi-step workflow

   **Estimation Criteria** (use to determine level):
   - Count of systems/components affected
   - Number of user personas/workflows
   - Data model complexity (entities, relationships)
   - Integration points (APIs, services)
   - Security/compliance requirements

   **Selection Logic**:
   ```
   IF (single file AND simple change AND no architecture):
     level = 0
   ELSE IF (< 100 LOC AND single component AND limited scope):
     level = 1
   ELSE:
     level = 2
   ```

   Load the selected template and use its structure for generation.

4. Follow this execution flow:

    1. Parse user description from Input
       If empty: ERROR "No feature description provided"
    2. Extract key concepts from description
       Identify: actors, actions, data, constraints
    3. For unclear aspects:
       - Make informed guesses based on context and industry standards
       - Only mark with [NEEDS CLARIFICATION: specific question] if:
         - The choice significantly impacts feature scope or user experience
         - Multiple reasonable interpretations exist with different implications
         - No reasonable default exists
       - **LIMIT: Maximum 3 [NEEDS CLARIFICATION] markers total**
       - Prioritize clarifications by impact: scope > security/privacy > user experience > technical details
    4. Fill User Scenarios & Testing section
       If no clear user flow: ERROR "Cannot determine user scenarios"
    5. Generate Functional Requirements
       Each requirement must be testable
       Use reasonable defaults for unspecified details (document assumptions in Assumptions section)
    6. Define Success Criteria
       Create measurable, technology-agnostic outcomes
       Include both quantitative metrics (time, performance, volume) and qualitative measures (user satisfaction, task completion)
       Each criterion must be verifiable without implementation details
    7. Identify Key Entities (if data involved)
    8. Return: SUCCESS (spec ready for planning)

5. **Generate Specification from Template** - Load the selected template file and use it as the EXACT structure for output:

   **Template Loading**:
   - Load `.opencode/speckit/templates/spec_template.md` for all levels
   - For Level 1 (Simple): Use core sections only (Metadata, Objective, Scope, Acceptance Criteria)
   - For Level 2+ (Standard/Complex): Use all sections from template
   - Preserve EXACT structure including:
     -  Section headers with UPPERCASE names
     -  HTML comment blocks (keep guidance comments as-is)
     -  Metadata structure and fields
     -  Section numbering and subsections
     -  Markdown formatting (tables, lists, emphasis)

   **Content Generation**:
   - Replace ONLY the placeholder content (text in [BRACKETS], example values, generic descriptions)
   - Keep all structural elements unchanged (headers, comments, formatting)
   - Fill in specific values from feature description in $ARGUMENTS
   - Generate concrete examples based on feature context

   **For Level 2 (spec_template.md), MUST include these mandatory sections**:

   a. **Traceability Mapping** (§4, after Functional Requirements):
      ```markdown
      ### Traceability Mapping
      Map User Stories -> Functional Requirements

      | User Story | Related FRs |
      |------------|-------------|
      | Story 1 - [Title] | FR-001, FR-003 |
      | Story 2 - [Title] | FR-002, FR-004 |
      ```
      - Map each user story to its functional requirements
      - Ensure all FRs are traced to at least one story
      - Identify shared FRs across multiple stories

   b. **Risk Matrix** (§8, Dependencies & Risks section):
      ```markdown
      ### Risk Assessment

      **Risk Matrix** (MANDATORY for Level 2+):

      | Risk ID | Description | Impact | Likelihood | Mitigation Strategy | Owner |
      |---------|-------------|--------|------------|---------------------|-------|
      | R-001 | [Risk description] | High/Med/Low | High/Med/Low | [Mitigation plan] | [Name] |
      | R-002 | [Risk description] | High/Med/Low | High/Med/Low | [Mitigation plan] | [Name] |
      ```
      - Minimum 2 risks required for Level 2
      - Identify technical, security, and operational risks
      - Include impact and likelihood assessment
      - Document mitigation strategies

   c. **Rollback Plan** (§8, after Risk Matrix):
      ```markdown
      ### Rollback Plan

      - **Rollback Trigger**: [Conditions that require rollback]
      - **Rollback Procedure**: [Step-by-step rollback process]
      - **Data Migration Reversal**: [If applicable]
      ```
      - Define rollback triggers (error rate, critical bugs, etc.)
      - Document step-by-step rollback procedure
      - Address data migration reversal if state changes occur

   d. **Constitution Check** (§1, in Assumptions subsection):
      ```markdown
      ### Assumptions

      **Constitution Compliance**:
      - This feature aligns with constitution principles: [reference AGENTS.md (project principles)]
      - Complexity justification: [if adding new patterns/projects/abstractions]
      ```
      - Reference constitution for complexity tracking
      - Justify any complexity increases
      - Document simpler alternatives considered

   **For Level 1 (Simple features using spec_template.md)**:
   - Include core sections: Metadata, Objective, Scope, Acceptance Criteria, Non-Goals, Success Metrics
   - Mark optional sections as "N/A - Simple feature" or omit them
   - Add escalation guidance: "If scope grows beyond 100 LOC or complexity increases, upgrade to Level 2 documentation"

6. **Specification Quality Validation**: After writing the initial spec, validate it against quality criteria:

   a. **Create Spec Quality Checklist**: Generate a checklist file at `FEATURE_DIR/checklists/requirements.md` using the checklist template structure with these validation items:

      ```markdown
      # Specification Quality Checklist: [FEATURE NAME]
      
      **Purpose**: Validate specification completeness and quality before proceeding to planning
      **Created**: [DATE]
      **Feature**: [Link to spec.md]
      
      ## Content Quality
      
      - [ ] No implementation details (languages, frameworks, APIs)
      - [ ] Focused on user value and business needs
      - [ ] Written for non-technical stakeholders
      - [ ] All mandatory sections completed
      
      ## Requirement Completeness

      - [ ] No [NEEDS CLARIFICATION] markers remain
      - [ ] Requirements are testable and unambiguous
      - [ ] Success criteria are measurable
      - [ ] Success criteria are technology-agnostic (no implementation details)
      - [ ] All acceptance scenarios are defined
      - [ ] Edge cases are identified
      - [ ] Scope is clearly bounded
      - [ ] Dependencies and assumptions identified

      ## Level 2 Mandatory Sections (if Level 2 selected)

      - [ ] Traceability Mapping table present (User Stories -> FRs)
      - [ ] Risk Matrix present (minimum 2 risks with impact/likelihood/mitigation)
      - [ ] Rollback Plan section present (trigger, procedure, data reversal)
      - [ ] Constitution Check reference in Assumptions

      ## Feature Readiness

      - [ ] All functional requirements have clear acceptance criteria
      - [ ] User scenarios cover primary flows
      - [ ] Feature meets measurable outcomes defined in Success Criteria
      - [ ] No implementation details leak into specification
      
      ## Notes
      
      - Items marked incomplete require spec updates before `/speckit.clarify` or `/speckit.plan`
      ```

   b. **Run Validation Check**: Review the spec against each checklist item:
      - For each item, determine if it passes or fails
      - Document specific issues found (quote relevant spec sections)

   c. **Handle Validation Results**:

      - **If all items pass**: Mark checklist complete and proceed to step 6

      - **If items fail (excluding [NEEDS CLARIFICATION])**:
        1. List the failing items and specific issues
        2. Update the spec to address each issue
        3. Re-run validation until all items pass (max 3 iterations)
        4. If still failing after 3 iterations, document remaining issues in checklist notes and warn user

      - **If [NEEDS CLARIFICATION] markers remain**:
        1. Extract all [NEEDS CLARIFICATION: ...] markers from the spec
        2. **LIMIT CHECK**: If more than 3 markers exist, keep only the 3 most critical (by scope/security/UX impact) and make informed guesses for the rest
        3. For each clarification needed (max 3), present options to user in this format:

           ```markdown
           ## Question [N]: [Topic]
           
           **Context**: [Quote relevant spec section]
           
           **What we need to know**: [Specific question from NEEDS CLARIFICATION marker]
           
           **Suggested Answers**:
           
           | Option | Answer | Implications |
           |--------|--------|--------------|
           | A      | [First suggested answer] | [What this means for the feature] |
           | B      | [Second suggested answer] | [What this means for the feature] |
           | C      | [Third suggested answer] | [What this means for the feature] |
           | Custom | Provide your own answer | [Explain how to provide custom input] |
           
           **Your choice**: _[Wait for user response]_
           ```

        4. **CRITICAL - Table Formatting**: Ensure markdown tables are properly formatted:
           - Use consistent spacing with pipes aligned
           - Each cell should have spaces around content: `| Content |` not `|Content|`
           - Header separator must have at least 3 dashes: `|--------|`
           - Test that the table renders correctly in markdown preview
        5. Number questions sequentially (Q1, Q2, Q3 - max 3 total)
        6. Present all questions together before waiting for responses
        7. Wait for user to respond with their choices for all questions (e.g., "Q1: A, Q2: Custom - [details], Q3: B")
        8. Update the spec by replacing each [NEEDS CLARIFICATION] marker with the user's selected or provided answer
        9. Re-run validation after all clarifications are resolved

   d. **Update Checklist**: After each validation iteration, update the checklist file with current pass/fail status

7. Report completion with:
   - **Template Level Selected**: Level 0/1/2 (with reasoning)
   - **Template Used**: Path to template file
   - **Branch Name**: Feature branch created
   - **Spec File Path**: Path to generated spec.md
   - **Mandatory Sections** (Level 2 only):
     -  Traceability Mapping (User Stories -> FRs)
     -  Risk Matrix (minimum 2 risks)
     -  Rollback Plan
     -  Constitution Check
   - **Checklist Results**: Pass/fail status from requirements.md validation
   - **Next Phase**: Recommend `/speckit.clarify` if clarifications needed, or `/speckit.plan` if ready

   **Example Report**:
   ```
    Specification Complete

    Template Selection:
   - Level: 2 (Complex Feature)
   - Reasoning: Multiple components (auth, API, database), >100 LOC estimated
   - Template: .opencode/speckit/templates/spec_template.md

    Artifacts Created:
   - Branch: 029-user-authentication
   - Spec: /specs/029-user-authentication/spec.md

    Mandatory Sections (Level 2):
   -  Traceability Mapping: 3 user stories mapped to 8 FRs
   -  Risk Matrix: 4 risks identified (2 High, 2 Medium)
   -  Rollback Plan: Defined with triggers and procedures
   -  Constitution Check: Included in Assumptions

    Quality Validation:
   - Requirements Checklist: checklists/requirements.md (15 items)
   - Status: 2 clarifications needed (see spec.md)

   Next: Run /speckit.clarify to resolve ambiguities, then /speckit.plan
   ```

**NOTE:** The script creates and checks out the new branch and initializes the spec file before writing.

## General Guidelines

## Quick Guidelines

- Focus on **WHAT** users need and **WHY**.
- Avoid HOW to implement (no tech stack, APIs, code structure).
- Written for business stakeholders, not developers.
- DO NOT create any checklists that are embedded in the spec. That will be a separate command.

### Section Requirements

- **Mandatory sections**: Must be completed for every feature
- **Optional sections**: Include only when relevant to the feature
- When a section doesn't apply, remove it entirely (don't leave as "N/A")

### For AI Generation

When creating this spec from a user prompt:

1. **Make informed guesses**: Use context, industry standards, and common patterns to fill gaps
2. **Document assumptions**: Record reasonable defaults in the Assumptions section
3. **Limit clarifications**: Maximum 3 [NEEDS CLARIFICATION] markers - use only for critical decisions that:
   - Significantly impact feature scope or user experience
   - Have multiple reasonable interpretations with different implications
   - Lack any reasonable default
4. **Prioritize clarifications**: scope > security/privacy > user experience > technical details
5. **Think like a tester**: Every vague requirement should fail the "testable and unambiguous" checklist item
6. **Common areas needing clarification** (only if no reasonable default exists):
   - Feature scope and boundaries (include/exclude specific use cases)
   - User types and permissions (if multiple conflicting interpretations possible)
   - Security/compliance requirements (when legally/financially significant)

**Examples of reasonable defaults** (don't ask about these):

- Data retention: Industry-standard practices for the domain
- Performance targets: Standard web/mobile app expectations unless specified
- Error handling: User-friendly messages with appropriate fallbacks
- Authentication method: Standard session-based or OAuth2 for web apps
- Integration patterns: RESTful APIs unless specified otherwise

### Success Criteria Guidelines

Success criteria must be:

1. **Measurable**: Include specific metrics (time, percentage, count, rate)
2. **Technology-agnostic**: No mention of frameworks, languages, databases, or tools
3. **User-focused**: Describe outcomes from user/business perspective, not system internals
4. **Verifiable**: Can be tested/validated without knowing implementation details

**Good examples**:

- "Users can complete checkout in under 3 minutes"
- "System supports 10,000 concurrent users"
- "95% of searches return results in under 1 second"
- "Task completion rate improves by 40%"

**Bad examples** (implementation-focused):

- "API response time is under 200ms" (too technical, use "Users see results instantly")
- "Database can handle 1000 TPS" (implementation detail, use user-facing metric)
- "React components render efficiently" (framework-specific)
- "Redis cache hit rate above 80%" (technology-specific)
