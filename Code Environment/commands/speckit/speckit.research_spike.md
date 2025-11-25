---
description: Generate research spike documentation for time-boxed technical exploration.
---

## Command Purpose: Time-Boxed Research & Proof-of-Concept

**WHAT IT DOES**: Creates structured documentation for time-boxed research spikes—experimental investigations to answer technical questions, validate approaches, or reduce uncertainty before committing to a full implementation plan.

**WHY IT EXISTS**: Some technical questions can't be answered through documentation alone—they require hands-on experimentation. Spikes provide a controlled, time-limited way to explore unknowns and make informed decisions based on evidence.

**WHEN TO USE**: When facing significant technical uncertainty that blocks planning or decision-making: evaluating new libraries, testing performance approaches, validating feasibility, or exploring multiple solution paths before choosing one.

**KEY PRINCIPLE**: Time-boxing and focus. Spikes have strict time limits (typically 1-2 days) and clear success criteria. The goal is to answer specific questions and make decisions—not to build production-ready code or explore endlessly.

## User Input

```text
$ARGUMENTS
```

You **MUST** consider the user input before proceeding (if not empty).

## Outline

The text the user typed after `/speckit.research-spike` in the triggering message **is** the research question or exploration topic. Use it as the basis for generating spike documentation.

Given that research question/topic, do this:

1. **Parse Input**:
   - Extract research question from $ARGUMENTS
   - If empty: ERROR "No research question provided. Please specify what you want to investigate."
   - Identify time box from input (default: 1-2 days if not specified)
   - Extract success criteria if mentioned
   - Identify any specific technologies/approaches mentioned

2. **Setup**:
   - Run `.opencode/speckit/scripts/check-prerequisites.sh --json` from repo root
   - Parse JSON for FEATURE_DIR and AVAILABLE_DOCS
   - Generate short spike name from research question (2-4 words, kebab-case)
   - Assign spike number: Find highest SPIKE-### in FEATURE_DIR/spikes/, increment by 1 (default: SPIKE-001)
   - Create FEATURE_DIR/spikes/ directory if it doesn't exist
   - Create spike file: `FEATURE_DIR/spikes/spike-[###]-[short-name].md`

3. **Load Template**:
   - Load `.opencode/speckit/templates/research_spike_template.md` as structure reference

4. **Generate Spike Document** using template structure:

   a. **Metadata Section (§1)**:
      ```markdown
      # Research Spike: [RESEARCH QUESTION] - Exploration & Findings

      Time-boxed research and experimentation to answer a technical question or validate an approach.

      ---

      ## 1.  METADATA

      - **Spike ID**: SPIKE-[###]
      - **Status**: Proposed
      - **Date Started**: [TODAY - YYYY-MM-DD]
      - **Date Completed**: [Leave blank - to be filled]
      - **Time Box**: [X hours/days - from input or default 1-2 days]
      - **Actual Time**: [Leave blank - to be tracked]
      - **Researcher(s)**: [Extract from context or placeholder]
      - **Related Feature**: [Link to spec.md if applicable]
      ```

   b. **Research Question Section (§2)**:
      - Primary Question: Extract from input
      - Secondary Questions: Generate 2-3 related questions based on context
      - Success Criteria: Define what constitutes a successful spike (measurable outcomes)

   c. **Hypothesis Section (§3)**:
      - Initial Hypothesis: Make an educated guess based on research question
      - Expected Outcome: What you expect to find
      - If Confirmed: Next steps if hypothesis is correct
      - If Rejected: Next steps if hypothesis is wrong

   d. **Approach Section (§4)**:
      - Research Method: Select appropriate methods from template (code prototyping, literature review, etc.)
      - Scope: Define what's in/out of scope
      - Environment: Specify platform, tools, dataset, resources

   e. **Research Process Section (§5)**:
      - Generate placeholder sections for Day 1 / Phase 1, Day 2 / Phase 2
      - Include structure: Goal, Activities, Findings, Time Spent
      - Note: Actual research will fill these in during execution

   f. **Experiments Conducted Section (§6)**:
      - Generate 2-3 experiment template sections
      - Include structure: Objective, Setup, Procedure, Results, Conclusion

   g. **Findings Section (§7)**:
      - Key Discoveries: Placeholder for 3-5 discoveries
      - Evidence Table: Empty table with columns (Finding, Evidence Type, Source, Confidence)
      - Surprises: Placeholder
      - Limitations: Placeholder

   h. **Recommendation Section (§8)**:
      - Primary Recommendation: Placeholder
      - Rationale: Placeholder
      - Confidence Level: To be determined
      - Alternative Approaches: Placeholder

   i. **Next Steps Section (§9)**:
      - Immediate Actions: Empty table with columns (Action, Owner, Priority, Due Date)
      - Follow-up Research Needed: Placeholder checklist
      - Implementation Path: Placeholder numbered list

   j. **Detailed Notes Section (§10)**:
      - Observations: Placeholder
      - Code Snippets: Placeholder code block
      - Resources Consulted: Placeholder list
      - Dead Ends: Placeholder (important for documenting what didn't work)

   k. **References Section (§11)**:
      - Documentation: Placeholder links
      - Related Work: Links to similar spikes, specs, ADRs if they exist
      - External References: Placeholder

   l. **Conclusion Section (§12)**:
      - Hypothesis Status: To be determined
      - Answer to Research Question: To be filled during research
      - Impact on Project: Placeholder
      - Learnings for Next Time: Placeholder

5. **Generate Companion Guidance** (optional):
   - If feature context available (spec.md, plan.md), extract relevant sections
   - Identify related decisions that might inform the spike
   - Suggest specific experiments based on feature requirements

6. **Report Completion**:
   ```markdown
    Research Spike Document Created

    Spike Details:
   - Spike ID: SPIKE-[###]
   - Research Question: [Primary question]
   - Time Box: [X hours/days]
   - File Path: [Full path to spike document]

    Structure Generated:
   -  Metadata (ID, status, time box, researchers)
   -  Research Question (primary, secondary, success criteria)
   -  Hypothesis (initial guess, expected outcome, contingencies)
   -  Approach (method, scope, environment)
   -  Research Process (day-by-day templates)
   -  Experiments (template sections for 2-3 experiments)
   -  Findings (discoveries, evidence, surprises, limitations)
   -  Recommendation (primary rec, rationale, confidence, alternatives)
   -  Next Steps (actions, follow-ups, implementation path)
   -  Detailed Notes (observations, code, resources, dead ends)
   -  References (docs, related work, external refs)
   -  Conclusion (hypothesis status, answer, impact, learnings)

   Time Box: [X hours/days]
   - Start researching and fill in sections incrementally
   - Track actual time spent vs. time box
   - Respect the time box - stop when time is up!

    Next Steps:
   1. Review the generated spike document structure
   2. Begin research activities following the approach section
   3. Fill in research process sections day-by-day
   4. Document experiments as you conduct them
   5. Update findings and recommendations as you learn
   6. When time box expires: Complete conclusion section
   7. Consider creating ADR (Architecture Decision Record) if decision needed:
      - Run `/speckit.decision` with findings from this spike
   ```

## Key Rules

- **Time Box is Sacred**: Research must stop when time box expires, even if questions remain
- **Document Everything**: Including dead ends and failed approaches (valuable for others)
- **Focus on Answer**: Keep research focused on answering the primary question
- **Evidence-Based**: All findings should be backed by evidence (code, benchmarks, docs)
- **Progressive Disclosure**: Fill in sections incrementally as research progresses
- **Status Updates**: Update status field as spike progresses (Proposed -> In Progress -> Completed/Abandoned)

## Template Compliance

All generated spike documents MUST include every section from spike_template.md:
- § 1: Metadata
- § 2: Research Question
- § 3: Hypothesis
- § 4: Approach
- § 5: Research Process
- § 6: Experiments Conducted
- § 7: Findings
- § 8: Recommendation
- § 9: Next Steps
- §10: Detailed Notes
- §11: References
- §12: Conclusion

## Examples

**Example 1: Technology Comparison**
```
/speckit.spike "Compare authentication libraries (Passport.js vs. NextAuth.js) for OAuth2 integration"

-> Generates spike focused on comparing two specific libraries
-> Experiments section includes benchmarks, feature comparison, integration tests
-> Time box: 2 days
```

**Example 2: Performance Investigation**
```
/speckit.spike "Investigate video streaming performance issues on mobile devices"

-> Generates spike focused on performance analysis
-> Experiments include profiling, network analysis, device testing
-> Time box: 1 day
```

**Example 3: Feasibility Study**
```
/speckit.spike "Research feasibility of real-time collaborative editing with WebSockets"

-> Generates spike focused on feasibility analysis
-> Experiments include proof-of-concept, scalability testing, conflict resolution
-> Time box: 3 days
```

## Related Commands

After completing a spike, you may want to:
- **Create ADR**: If spike informs a technical decision, run `/speckit.decision` to document the decision
- **Update Spec**: If spike resolves [NEEDS CLARIFICATION] markers, update spec.md
- **Update Plan**: If spike changes technical approach, update plan.md Technical Context
