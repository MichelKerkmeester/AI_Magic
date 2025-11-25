---
description: Generate Architecture Decision Record (ADR) for technical decisions.
---

## Command Purpose: Architecture Decision Documentation

**WHAT IT DOES**: Creates structured Architecture Decision Records (ADRs) that document significant technical decisions, alternatives considered, trade-offs evaluated, and rationale for the chosen approach.

**WHY IT EXISTS**: Preserves institutional knowledge about WHY decisions were made. Six months from now, when someone asks "why did we choose X over Y?", the ADR provides the complete context and reasoning.

**WHEN TO USE**: When making any significant technical decision that has long-term implications: library choices, architectural patterns, data storage approaches, API designs, or other decisions that would be costly to reverse later.

**KEY PRINCIPLE**: Decision transparency and reversibility. Document not just what was chosen, but what alternatives existed, what criteria mattered, and what trade-offs were accepted—so future teams can revisit decisions with full context if circumstances change.

## User Input

```text
$ARGUMENTS
```

You **MUST** consider the user input before proceeding (if not empty).

## Outline

The text the user typed after `/speckit.decision` in the triggering message **is** the decision context or problem statement. Use it as the basis for generating an ADR.

Given that decision context/problem, do this:

1. **Parse Input**:
   - Extract decision problem/context from $ARGUMENTS
   - If empty: ERROR "No decision context provided. Please specify the technical decision to document."
   - Identify mentioned alternatives/options if any
   - Extract constraints or requirements mentioned
   - Identify stakeholders if mentioned

2. **Setup**:
   - Run `.opencode/speckit/scripts/check-prerequisites.sh --json` from repo root
   - Parse JSON for FEATURE_DIR and AVAILABLE_DOCS
   - Generate short decision name from problem statement (2-4 words, kebab-case)
   - Assign ADR number: Find highest ADR-### in FEATURE_DIR/decisions/, increment by 1 (default: ADR-001)
   - Create FEATURE_DIR/decisions/ directory if it doesn't exist
   - Create ADR file: `FEATURE_DIR/decisions/adr-[###]-[short-name].md`

3. **Load Template**:
   - Load `.opencode/speckit/templates/decision_record_template.md` as structure reference

4. **Interactive Decision Capture**:

   a. **Clarify Context** (if not clear from input):
      - Ask about constraints (technical, business, time/resource)
      - Ask about current situation (what exists today)
      - Ask about assumptions

   b. **Gather Alternatives** (2-4 options required):
      - If alternatives mentioned in input: Use them
      - If not mentioned: Ask user to provide 2-4 alternative approaches

      For each alternative, ask:
      ```markdown
      ## Alternative [N]: [Option Name]

      **How it works**: [Brief description]

      **Key Pros** (2-4 items):
      - [Pro 1]
      - [Pro 2]

      **Key Cons** (2-4 items):
      - [Con 1]
      - [Con 2]

      **Score** (1-10, where 10 is best): [X/10]
      ```

      Present questions one at a time for each alternative. Use table format for pros/cons if helpful.

   c. **Generate Comparison Matrix**:
      - Create weighted comparison across criteria:
        - Performance (weight: High)
        - Maintainability (weight: High)
        - Cost (weight: Medium)
        - Time to implement (weight: Medium)
        - Scalability (weight: High)
      - Calculate weighted scores
      - Identify highest scoring option

   d. **Determine Recommendation**:
      - If user explicitly chose an option: Use that
      - If scores are clear: Recommend highest scoring option
      - If scores are close: Ask user for final decision or tiebreaker criteria

5. **Generate ADR Document** using template structure:

   a. **Metadata Section (§1)**:
      ```markdown
      # Decision: [DECISION TITLE] - Architecture Decision Record

      Architecture Decision Record (ADR) documenting a significant technical decision and its rationale.

      ---

      ## 1.  METADATA

      - **Decision ID**: ADR-[###]
      - **Status**: Proposed (will change to Accepted after approval)
      - **Date**: [TODAY - YYYY-MM-DD]
      - **Deciders**: [Extract from context or placeholder]
      - **Related Feature**: [Link to spec.md if in feature directory]
      - **Supersedes**: N/A (or link if replacing an existing ADR)
      - **Superseded By**: N/A
      ```

   b. **Context Section (§2)**:
      - Problem Statement: Extract from input
      - Current Situation: From input or user clarification
      - Constraints: From input or user clarification
      - Assumptions: From input or user clarification

   c. **Decision Section (§3)**:
      - Summary: One-sentence description of chosen option
      - Detailed Description: Comprehensive explanation of what/how/why
      - Technical Approach: Code example or architecture diagram (if applicable)

   d. **Alternatives Considered Section (§4)**:
      - For each option (2-4):
        - Description, Pros, Cons, Score
        - Mark chosen option with [CHOSEN]
        - Include "Why Chosen" for selected option
        - Include "Why Rejected" for non-selected options
      - Comparison Matrix: Table with weighted criteria and scores

   e. **Consequences Section (§5)**:
      - Positive Consequences: Benefits of chosen approach (3-5 items)
      - Negative Consequences: Drawbacks + mitigation strategies (2-4 items)
      - Risks: Table with Impact, Likelihood, Mitigation
      - Technical Debt Introduced: Any debt + plan to address

   f. **Impact Assessment Section (§6)**:
      - Systems Affected: Components impacted and how
      - Teams Impacted: Teams affected and what they need to do
      - Migration Path: Step-by-step migration (if changing existing system)
      - Rollback Strategy: How to revert if needed

   g. **Timeline Section (§7)**:
      - Decision Made: Today's date
      - Implementation Start: Estimated or TBD
      - Target Completion: Estimated or TBD
      - Review Date: 6-12 months from decision date

   h. **References Section (§8)**:
      - Related Documents: Links to spec.md, plan.md, related ADRs, spikes
      - External References: Docs, papers, articles that informed decision
      - Discussion History: Links to discussions, meetings, RFCs

   i. **Approval & Sign-off Section (§9)**:
      - Approvers Table: Placeholder rows for stakeholders
      - Status Changes Table: Initial entry (- -> Proposed)

   j. **Updates & Amendments Section (§10)**:
      - Amendment History: Empty table (for future updates)
      - Review Notes: Placeholder
      - Review Schedule: Date to review decision

6. **Generate Companion Artifacts** (optional):
   - If decision impacts spec.md: Suggest updates to Technical Context or Assumptions
   - If decision resolves spike: Reference spike document in References section
   - If decision changes plan.md: Note which sections need updating

7. **Report Completion**:
   ```markdown
    Architecture Decision Record Created

    Decision Details:
   - Decision ID: ADR-[###]
   - Decision: [One-sentence summary]
   - Status: Proposed (awaiting approval)
   - File Path: [Full path to ADR document]

    Alternatives Evaluated:
   - Option 1 (CHOSEN): [Name] - Score: [X/10]
   - Option 2: [Name] - Score: [Y/10]
   - Option 3: [Name] - Score: [Z/10]

    Structure Generated:
   -  Metadata (ID, status, date, deciders, related docs)
   -  Context (problem, current situation, constraints, assumptions)
   -  Decision (summary, detailed description, technical approach)
   -  Alternatives Considered (2-4 options with pros/cons/scores)
   -  Comparison Matrix (weighted criteria evaluation)
   -  Consequences (positive, negative, risks, technical debt)
   -  Impact Assessment (systems, teams, migration, rollback)
   -  Timeline (decision date, implementation, review)
   -  References (related docs, external refs, discussions)
   -  Approval & Sign-off (approvers table, status changes)
   -  Updates & Amendments (history, review notes)

    Next Steps:
   1. Review the generated ADR document
   2. Fill in any additional technical details
   3. Share with stakeholders for approval
   4. Update Status from "Proposed" to "Accepted" after approval
   5. Update related documents (spec.md, plan.md) if needed
   6. If implementing: Reference this ADR in implementation tasks

    Related Commands:
   - Update spec.md if decision affects requirements
   - Update plan.md Technical Context if decision changes approach
   - Create research-spike first if more research needed: `/speckit.research-spike`
   ```

## Key Rules

- **Alternatives Required**: Must document at least 2 alternatives (including chosen option)
- **Evidence-Based**: Include rationale and comparison criteria for decision
- **Status Tracking**: Start as "Proposed", move to "Accepted" after approval
- **Consequences Honest**: Document both positive AND negative consequences
- **Migration Plan**: If changing existing systems, include migration path
- **Rollback Strategy**: Always document how to revert the decision
- **Review Schedule**: Set future review date to reassess decision

## Template Compliance

All generated ADR documents MUST include every section from decision_record_template.md:
- § 1: Metadata
- § 2: Context
- § 3: Decision
- § 4: Alternatives Considered
- § 5: Consequences
- § 6: Impact Assessment
- § 7: Timeline
- § 8: References
- § 9: Approval & Sign-off
- §10: Updates & Amendments

## Interactive Flow Example

```
User: /speckit.decision "Choose authentication library for OAuth2 integration"

Assistant: "I'll help document this technical decision. Let me gather the alternatives you're considering."

Q1: What authentication libraries are you evaluating? (e.g., Passport.js, NextAuth.js, Auth0 SDK, custom solution)

User: "Passport.js, NextAuth.js, and Auth0 SDK"

Assistant: [For each alternative, asks about pros, cons, score]

-> Generates ADR-001 with all 3 alternatives documented
-> Creates comparison matrix with weighted scores
-> Recommends highest scoring option or asks user to choose
```

## Examples

**Example 1: Library Selection**
```
/speckit.decision "Choose state management library for React app (Redux vs. Zustand vs. Context API)"

-> Generates ADR with 3 alternatives
-> Comparison on performance, bundle size, learning curve, community support
-> Weighted scoring based on project needs
```

**Example 2: Architecture Decision**
```
/speckit.decision "Decide between monolith vs. microservices architecture for backend"

-> Generates ADR with architectural trade-offs
-> Impact assessment on teams, deployment, scalability
-> Migration path from current state
-> Rollback strategy
```

**Example 3: Technology Stack**
```
/speckit.decision "Select database for user data (PostgreSQL vs. MongoDB vs. DynamoDB)"

-> Generates ADR with data model considerations
-> Comparison on query patterns, scalability, cost, operational overhead
-> Consequences for data consistency and availability
```

**Example 4: Pattern/Approach**
```
/speckit.decision "Choose error handling strategy (try-catch vs. Result type vs. Error boundaries)"

-> Generates ADR with implementation patterns
-> Pros/cons of each approach
-> Code examples for chosen pattern
```

## Related Commands

- **Research First**: If decision needs more investigation, run `/speckit.research-spike` to research alternatives first
- **Update Spec**: If decision affects requirements, update spec.md Assumptions or Technical Context
- **Update Plan**: If decision changes technical approach, update plan.md Technical Context section
- **Link from Tasks**: Reference ADR in implementation tasks (e.g., "Implement authentication per ADR-001")

## Status Lifecycle

ADR status follows this workflow:

```
Proposed -> [Review/Discussion] -> Accepted -> [Implementation]
                (down)                                    (down)
            Rejected                            (Optional)
                                                     (down)
                                            Deprecated -> Superseded
```

- **Proposed**: Initial state, awaiting approval
- **Accepted**: Approved and ready for implementation
- **Rejected**: Not approved, decision not moving forward
- **Deprecated**: Decision outdated but kept for historical reference
- **Superseded**: Replaced by newer ADR (link to new ADR)
