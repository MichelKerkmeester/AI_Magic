---
description: Execute the implementation planning workflow using the plan template to generate design artifacts.
---

## Command Purpose: Technical Design & Architecture Planning

**WHAT IT DOES**: Transforms technology-agnostic requirements (from spec.md) into concrete technical plans including architecture, tech stack decisions, data models, API contracts, and implementation approach.

**WHY IT EXISTS**: Bridges the gap between WHAT (requirements) and HOW (implementation). Creates the technical blueprint that guides task breakdown and actual coding.

**WHEN TO USE**: After spec.md is complete and clarified. This is where engineers translate business requirements into technical solutions, making all major architectural and technology decisions.

**KEY PRINCIPLE**: Design before build. All significant technical decisions (libraries, patterns, data structures, API contracts) are documented and validated against project constitution before any code is written.

## User Input

```text
$ARGUMENTS
```

You **MUST** consider the user input before proceeding (if not empty).

## Outline

1. **Setup**: Run `.opencode/speckit/scripts/setup-plan.sh --json` from repo root and parse JSON for FEATURE_SPEC, IMPL_PLAN, SPECS_DIR, BRANCH. For single quotes in args like "I'm Groot", use escape syntax: e.g 'I'\''m Groot' (or double-quote if possible: "I'm Groot").

2. **Load context**: Read FEATURE_SPEC and `AGENTS.md (project principles)`. Load IMPL_PLAN template from `.opencode/speckit/templates/plan_template.md`.

   **Template Preservation**:
   - Preserve EXACT structure from plan_template.md including:
     -  Section headers with UPPERCASE names
     -  HTML comment blocks (keep guidance comments as-is)
     -  Metadata structure and all fields
     -  Section numbering (§1-§10) and subsections
     -  Markdown formatting (tables, lists, code blocks)
   - Replace ONLY placeholder content ([BRACKETS], NEEDS CLARIFICATION, example values)
   - Keep all structural elements unchanged

3. **Execute plan workflow**: Fill the template structure following this sequence:
   - Fill Technical Context (mark unknowns as "NEEDS CLARIFICATION")
   - Fill Constitution Check section from constitution
   - Evaluate gates (ERROR if violations unjustified)
   - Phase 0: Generate research.md (resolve all NEEDS CLARIFICATION)
   - Phase 1: Generate data-model.md, contracts/, quickstart.md
   - Phase 1: Update agent context by running the agent script
   - Re-evaluate Constitution Check post-design

4. **Stop and report**: Command ends after Phase 1 complete. Report:
   - Branch name
   - IMPL_PLAN path (plan.md)
   - Generated artifacts:
     - research.md (Phase 0)
     - data-model.md (Phase 1)
     - contracts/ directory (Phase 1)
     - quickstart.md (Phase 1)
   - Plan sections added:
     -  Testing Strategy (§5)
     -  Success Metrics (§6)
     -  Risk Matrix (§7, imported from spec)
     -  Dependencies (§8)
     -  Communication & Review (§9)
     -  Phases 2-4 outlines (§4)
   - Template compliance: All plan_template.md sections present
   - Next step: Run `/speckit.tasks` to generate implementation task breakdown

## Phases

### Phase 0: Outline & Research

1. **Extract unknowns from Technical Context** above:
   - For each NEEDS CLARIFICATION -> research task
   - For each dependency -> best practices task
   - For each integration -> patterns task

2. **Generate and dispatch research agents**:

   ```text
   For each unknown in Technical Context:
     Task: "Research {unknown} for {feature context}"
   For each technology choice:
     Task: "Find best practices for {tech} in {domain}"
   ```

3. **Consolidate findings** in `research.md` using format:
   - Decision: [what was chosen]
   - Rationale: [why chosen]
   - Alternatives considered: [what else evaluated]

**Output**: research.md with all NEEDS CLARIFICATION resolved

### Phase 1: Design & Contracts

**Prerequisites:** `research.md` complete

1. **Extract entities from feature spec** -> `data-model.md`:
   - Entity name, fields, relationships
   - Validation rules from requirements
   - State transitions if applicable

2. **Generate API contracts** from functional requirements:
   - For each user action -> endpoint
   - Use standard REST/GraphQL patterns
   - Output OpenAPI/GraphQL schema to `/contracts/`

3. **Generate Testing Strategy** -> Add to `plan.md`:
   - Load Technical Context from plan.md
   - Detect language/framework from tech stack
   - Generate test pyramid section:
     ```
            /\
           /E2E\      <- Few, high-value end-to-end tests
          /------\
         /  INTEG \   <- More integration tests
        /----------\
       /   UNIT     \  <- Many unit tests (foundation)
      /--------------\
     ```
   - Add test tool recommendations based on stack
   - Define coverage targets (unit ≥70%, integration ≥60%, E2E ≥40%)
   - Create CI quality gates checklist

4. **Generate Success Metrics** -> Add to `plan.md`:
   - Load Success Criteria from spec.md
   - Convert each criterion to measurable metric
   - Create tables: Functional, Performance, Quality Metrics
   - Add measurement methods for each
   - Include target values and baselines

5. **Import Risk Matrix** -> Add to `plan.md`:
   - Load Risk Assessment section from spec.md
   - Copy Risk Matrix to plan.md §7
   - Add implementation-specific mitigations
   - Cross-reference rollback plan

6. **Generate Dependencies Tables** -> Add to `plan.md`:
   - Scan spec.md for dependencies
   - Categorize: Internal vs. External
   - Add status tracking columns (Green/Yellow/Red)
   - Include impact assessment
   - Reference from Technical Context

7. **Generate Communication & Review** -> Add to `plan.md`:
   - Identify stakeholders from spec.md
   - Define checkpoint cadence (standups, reviews, demos)
   - List approval gates
   - Add review schedule

**Output**: data-model.md, /contracts/*, quickstart.md, Testing Strategy, Success Metrics, Risk Matrix, Dependencies, Communication sections in plan.md

### Phase 2-4: Implementation Phases Outline

After Phase 1 complete, generate outline sections in plan.md for remaining implementation phases:

**Phase 2: Core Implementation**
- Goal: Implement primary user stories (extract from spec.md priorities P0, P1)
- Deliverables: List key features from spec.md user stories
- Owner: [Placeholder - team/individual]
- Duration: [Estimate based on task count from user stories]
- Parallel Tasks: Identify independent story implementations with [P] marker

**Phase 3: Integration & Testing**
- Goal: Integrate components, run full test suite
- Deliverables: Integration tests passing, E2E tests passing, performance benchmarks met
- Owner: [Placeholder]
- Duration: [Estimate 20-30% of core implementation time]
- Parallel Tasks: Independent test suites, documentation updates

**Phase 4: Deployment & Monitoring**
- Goal: Production deployment with observability
- Deliverables: Production deployment complete, monitoring/alerting configured, documentation finalized
- Owner: [Placeholder]
- Duration: [Estimate 10-15% of core implementation time]
- Parallel Tasks: Documentation finalization, monitoring setup

**Note**: These are outline sections. Detailed task breakdown will be generated by `/speckit.tasks` command.

## Key rules

- Use absolute paths
- ERROR on gate failures or unresolved clarifications
