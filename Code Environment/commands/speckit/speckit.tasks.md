---
description: Generate an actionable, dependency-ordered tasks.md for the feature based on available design artifacts.
---

## Command Purpose: Implementation Task Breakdown

**WHAT IT DOES**: Breaks down the technical plan into granular, executable tasks organized by user story, with clear dependencies and parallel execution paths. Each task is small enough to complete in one focused session.

**WHY IT EXISTS**: Transforms high-level design into concrete action items that can be tracked, assigned, and executed. Provides the roadmap from plan to working code.

**WHEN TO USE**: After plan.md is complete with all design artifacts (data models, contracts, technical approach). This is the final preparation step before actual implementation begins.

**KEY PRINCIPLE**: Task independence and testability. Each task should be independently verifiable, properly scoped (30min-4hrs), and organized so related tasks can be executed in parallel when dependencies allow.

## User Input

```text
$ARGUMENTS
```

You **MUST** consider the user input before proceeding (if not empty).

## Outline

1. **Setup**: Run `.opencode/speckit/scripts/check-prerequisites.sh --json` from repo root and parse FEATURE_DIR and AVAILABLE_DOCS list. All paths must be absolute. For single quotes in args like "I'm Groot", use escape syntax: e.g 'I'\''m Groot' (or double-quote if possible: "I'm Groot").

2. **Load design documents**: Read from FEATURE_DIR:
   - **Required**: plan.md (tech stack, libraries, structure), spec.md (user stories with priorities)
   - **Optional**: data-model.md (entities), contracts/ (API endpoints), research.md (decisions), quickstart.md (test scenarios)
   - Note: Not all projects have all documents. Generate tasks based on what's available.

3. **Execute task generation workflow**:
   - Load plan.md and extract tech stack, libraries, project structure
   - Load spec.md and extract user stories with their priorities (P1, P2, P3, etc.)
   - If data-model.md exists: Extract entities and map to user stories
   - If contracts/ exists: Map endpoints to user stories
   - If research.md exists: Extract decisions for setup tasks
   - Generate tasks organized by user story (see Task Generation Rules below)
   - Generate dependency graph showing user story completion order
   - Create parallel execution examples per user story
   - Validate task completeness (each user story has all needed tasks, independently testable)

4. **Generate tasks.md**: Load `.opencode/speckit/templates/tasks_template.md` and preserve its EXACT structure:

   **Template Preservation**:
   - Preserve EXACT structure from tasks_template.md including:
     -  Section headers with UPPERCASE names
     -  HTML comment blocks (keep guidance comments as-is)
     -  Metadata structure and fields
     -  Conventions section (task format, path conventions, commit message hints)
     -  Markdown formatting (tables, lists, checkboxes)
   - Replace ONLY placeholder content ([BRACKETS], example tasks)
   - Keep all structural elements unchanged

   **Content Generation** - Fill template with:
   - Correct feature name from plan.md
   - Phase 1: Setup tasks (project initialization)
   - Phase 2: Foundational tasks (blocking prerequisites for all user stories)
   - Phase 3+: One phase per user story (in priority order from spec.md)
   - Each phase includes: story goal, independent test criteria, tests (if requested), implementation tasks
   - Final Phase: Polish & cross-cutting concerns
   - All tasks must follow the strict checklist format (see Task Generation Rules below)
   - Clear file paths for each task
   - Dependencies section showing story completion order
   - Parallel execution examples per story
   - Implementation strategy section (MVP first, incremental delivery)

5. **Validate Task Format**: After generating tasks.md, run format validation:

   a. **Scan all task lines** in generated tasks.md (lines matching `- [ ] T\d+`)

   b. **For each task, validate**:
      - Starts with `- [ ]` (markdown checkbox)
      - Has Task ID matching `T\d{3}` pattern (e.g., T001, T012)
      - Task IDs are sequential with no gaps
      - If phase is user story: Has story label `[US\d+]` format
      - Description includes file path (contains `/` or file extension `.`)
      - If marked `[P]`: Verify it's parallelizable (different files, no dependencies)

   c. **Auto-fix common issues**:
      - Add missing checkboxes: `T001 Description` -> `- [ ] T001 Description`
      - Pad task IDs: `T1` -> `T001`, `T12` -> `T012`
      - Fix story labels: `[Story 1]` -> `[US1]`, `[Story-1]` -> `[US1]`
      - Warn (don't auto-fix) if `[P]` marker on task with stated dependencies

   d. **Generate Validation Report**:
      ```
      Task Format Validation:
      =======================
      Total tasks: 45
      Valid: 43/45 (95.6%)
      Auto-fixed: 2
        - T023: Added missing checkbox
        - T035: Padded ID (T35 -> T035)

      Manual review needed: 2
        - T023: Missing file path
        - T035: Missing file path

      Compliance:  95.6% (≥95% target met)

      Validation by type:
      - Checkbox: 45/45 
      - Task ID: 45/45 
      - Sequence: 45/45
      - Story labels: 32/32
      - File paths: 43/45
      - Parallel: 12/12 
      ```

   e. **Save fixes**: If auto-fixes applied, save updated tasks.md

   f. **If compliance < 95%**: Warn user and list specific issues needing manual review

6. **Report**: Output path to generated tasks.md and summary:
   - Total task count
   - Task count per user story
   - Parallel opportunities identified
   - Independent test criteria for each story
   - Suggested MVP scope (typically just User Story 1)
   - **Format Validation Results**:
     - Compliance percentage (target: ≥95%)
     - Auto-fixes applied count
     - Manual review items (if any)
   - Next: Review tasks.md, especially any flagged items, then begin implementation

Context for task generation: $ARGUMENTS

The tasks.md should be immediately executable - each task must be specific enough that an LLM can complete it without additional context.

## Task Generation Rules

**CRITICAL**: Tasks MUST be organized by user story to enable independent implementation and testing.

**Tests are OPTIONAL**: Only generate test tasks if explicitly requested in the feature specification or if user requests TDD approach.

### Checklist Format (REQUIRED)

Every task MUST strictly follow this format:

```text
- [ ] [TaskID] [P?] [Story?] Description with file path
```

**Format Components**:

1. **Checkbox**: ALWAYS start with `- [ ]` (markdown checkbox)
2. **Task ID**: Sequential number (T001, T002, T003...) in execution order
3. **[P] marker**: Include ONLY if task is parallelizable (different files, no dependencies on incomplete tasks)
4. **[Story] label**: REQUIRED for user story phase tasks only
   - Format: [US1], [US2], [US3], etc. (maps to user stories from spec.md)
   - Setup phase: NO story label
   - Foundational phase: NO story label  
   - User Story phases: MUST have story label
   - Polish phase: NO story label
5. **Description**: Clear action with exact file path

**Examples**:

-  CORRECT: `- [ ] T001 Create project structure per implementation plan`
-  CORRECT: `- [ ] T005 [P] Implement authentication middleware in src/middleware/auth.py`
-  CORRECT: `- [ ] T012 [P] [US1] Create User model in src/models/user.py`
-  CORRECT: `- [ ] T014 [US1] Implement UserService in src/services/user_service.py`
-  WRONG: `- [ ] Create User model` (missing ID and Story label)
-  WRONG: `T001 [US1] Create model` (missing checkbox)
-  WRONG: `- [ ] [US1] Create User model` (missing Task ID)
-  WRONG: `- [ ] T001 [US1] Create model` (missing file path)

### Task Organization

1. **From User Stories (spec.md)** - PRIMARY ORGANIZATION:
   - Each user story (P1, P2, P3...) gets its own phase
   - Map all related components to their story:
     - Models needed for that story
     - Services needed for that story
     - Endpoints/UI needed for that story
     - If tests requested: Tests specific to that story
   - Mark story dependencies (most stories should be independent)

2. **From Contracts**:
   - Map each contract/endpoint -> to the user story it serves
   - If tests requested: Each contract -> contract test task [P] before implementation in that story's phase

3. **From Data Model**:
   - Map each entity to the user story(ies) that need it
   - If entity serves multiple stories: Put in earliest story or Setup phase
   - Relationships -> service layer tasks in appropriate story phase

4. **From Setup/Infrastructure**:
   - Shared infrastructure -> Setup phase (Phase 1)
   - Foundational/blocking tasks -> Foundational phase (Phase 2)
   - Story-specific setup -> within that story's phase

### Phase Structure

- **Phase 1**: Setup (project initialization)
- **Phase 2**: Foundational (blocking prerequisites - MUST complete before user stories)
- **Phase 3+**: User Stories in priority order (P1, P2, P3...)
  - Within each story: Tests (if requested) -> Models -> Services -> Endpoints -> Integration
  - Each phase should be a complete, independently testable increment
- **Final Phase**: Polish & Cross-Cutting Concerns
