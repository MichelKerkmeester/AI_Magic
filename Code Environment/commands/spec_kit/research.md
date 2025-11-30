---
description: Research workflow (9 steps) - technical investigation and documentation. Supports :auto and :confirm modes
argument-hint: "[research-topic] [:auto|:confirm]"
allowed-tools: Read, Write, Edit, Bash, Grep, Glob, Task, AskUserQuestion, WebFetch, WebSearch
---

# SpecKit Research

Conduct comprehensive technical investigation and create research documentation. Use before specification when technical uncertainty exists or to document findings for future reference.

---

## Purpose

Run the 9-step research workflow: codebase investigation, external research, technical analysis, and documentation. Creates research.md with comprehensive findings. Use when technical uncertainty exists before planning.

---

## Contract

**Inputs:** `$ARGUMENTS` — Research topic with optional parameters (focus, scope, constraints)
**Outputs:** Spec folder with research.md (17 sections) + `STATUS=<OK|FAIL|CANCELLED>`

## User Input

```text
$ARGUMENTS
```

## Workflow Overview (9 Steps)

| Step | Name | Purpose | Outputs |
|------|------|---------|---------|
| 1 | Request Analysis | Define research scope | feature_summary, research_objectives |
| 2 | Pre-Work Review | Review AGENTS.md, standards | principles_established |
| 3 | Codebase Investigation | Explore existing patterns | current_state_analysis |
| 4 | External Research | Research docs, best practices | best_practices_summary |
| 5 | Technical Analysis | Feasibility assessment | technical_specifications |
| 6 | Quality Checklist | Generate validation checklist | quality_checklist |
| 7 | Solution Design | Architecture and patterns | solution_architecture |
| 8 | Research Compilation | Create research.md | research.md |
| 9 | Save Context | Preserve conversation | memory/*.md |

## Research Document Sections (17 Sections)

The generated `research.md` includes:

1. **Metadata** - Research ID, status, dates, researchers
2. **Investigation Report** - Request summary, findings, recommendations
3. **Executive Overview** - Summary, architecture diagram, quick reference
4. **Core Architecture** - Components, data flow, integration points
5. **Technical Specifications** - API docs, attributes, events, state
6. **Constraints & Limitations** - Platform, security, performance, browser
7. **Integration Patterns** - Third-party, auth, error handling, retry
8. **Implementation Guide** - Markup, JS, CSS, configuration
9. **Code Examples** - Initialization, helpers, API usage, edge cases
10. **Testing & Debugging** - Strategies, approaches, e2e, diagnostics
11. **Performance** - Optimization, benchmarks, caching
12. **Security** - Validation, data protection, spam prevention
13. **Maintenance** - Upgrade paths, compatibility, decision trees
14. **API Reference** - Attributes, JS API, events, cleanup
15. **Troubleshooting** - Common issues, errors, solutions, workarounds
16. **Acknowledgements** - Contributors, resources, tools
17. **Appendix & Changelog** - Glossary, related docs, history

---

## Instructions

### Phase 1: Mode Detection & Input Parsing

#### Step 1.1: Parse Mode Suffix

Detect execution mode from command invocation:

| Pattern | Mode | Behavior |
|---------|------|----------|
| `/spec_kit:research:auto` | AUTONOMOUS | Execute all steps without user approval gates |
| `/spec_kit:research:confirm` | INTERACTIVE | Pause at each step for user approval |
| `/spec_kit:research` (no suffix) | PROMPT | Ask user to choose mode |

#### Step 1.2: Mode Selection (when no suffix detected)

If no `:auto` or `:confirm` suffix is present, use AskUserQuestion:

**Question**: "How would you like to execute this research workflow?"

| Option | Mode | Description |
|--------|------|-------------|
| **A** | Autonomous | Execute all 9 steps without approval gates. Best for focused research topics. |
| **B** | Interactive | Pause at each step for approval. Best for exploratory research needing direction. |

**Wait for user response before proceeding.**

#### Step 1.3: Transform Raw Input

Parse the raw text from `$ARGUMENTS` and transform into structured user_inputs fields.

**Field Extraction Rules**:

| Field | Pattern Detection | Default If Empty |
|-------|-------------------|------------------|
| `git_branch` | "branch: X", "on branch X", "feature/X" | Auto-create feature-{NNN} |
| `spec_folder` | "specs/NNN", "spec folder X", "in specs/X" | Auto-create next available |
| `context` | "using X", "with Y", "tech stack:", "investigating:" | Infer from request |
| `issues` | "issue:", "bug:", "problem:", "error:", "question:", "unknown:" | Topics to investigate |
| `request` | Research topic description (REQUIRED) | ERROR if completely empty |
| `environment` | URLs, "staging:", "example:" | Skip browser analysis |
| `scope` | File paths, glob patterns, "focus:" | Default to specs/** |

#### Step 1.4: Load & Execute Workflow Prompt

Based on detected/selected mode:

- **AUTONOMOUS**: Load and execute `.claude/commands/spec_kit/assets/spec_kit_research_auto.yaml`
- **INTERACTIVE**: Load and execute `.claude/commands/spec_kit/assets/spec_kit_research_confirm.yaml`

### Phase 2: Workflow Execution

Execute the 9 steps defined in Workflow Overview. Each step produces artifacts that feed into subsequent steps. See prompt files for detailed step-by-step instructions.

---

## Key Differences from Other Commands

- **Does NOT proceed to implementation** - Terminates after research.md
- **Primary output is research.md** - Comprehensive technical documentation
- **Use case** - Technical uncertainty, feasibility analysis, documentation
- **Next steps** - Can feed into `/spec_kit:plan` or `/spec_kit:complete`

---

## Context Loading

When resuming work in an existing spec folder, the system will prompt to load prior session memory:
- **A)** Load most recent memory file (quick context refresh)
- **B)** Load all recent files (up to 3) (comprehensive context)
- **C)** List all files and select specific (historical search)
- **D)** Skip (start fresh, no context)

See CLAUDE.md Section 2 for full memory file handling details.

## Failure Recovery

| Failure Type | Recovery Action |
|--------------|-----------------|
| Research scope unclear | Ask clarifying questions, narrow focus |
| External sources unavailable | Document limitation, continue with available info |
| Conflicting findings | Document both perspectives with analysis, flag for review |
| Technical dead-end | Document findings, recommend alternative approach |

## Error Handling

| Condition | Action |
|-----------|--------|
| Empty `$ARGUMENTS` | Prompt user: "Please describe what you want to research" |
| Unclear research scope | Ask clarifying questions |
| External sources unavailable | Document limitation, continue with available info |
| Conflicting findings | Document both perspectives with analysis |

## Documentation Levels (Progressive Enhancement)

| Level | Required Files | LOC Guidance | Use Case |
|-------|---------------|--------------|----------|
| **Level 1 (Baseline)** | spec.md + plan.md + tasks.md | <100 LOC | Simple changes, bug fixes |
| **Level 2 (Verification)** | Level 1 + checklist.md | 100-499 LOC | Medium features, refactoring |
| **Level 3 (Full)** | Level 2 + decision-record.md | >=500 LOC | Complex features, architecture changes |

**Note:** LOC thresholds are soft guidance. Choose level based on complexity and risk.

## Templates Used

- `.opencode/speckit/templates/research.md` (primary output)
- `.opencode/speckit/templates/research-spike.md` (optional for time-boxed sub-investigations)
- `.opencode/speckit/templates/decision-record.md` (Level 3 - for significant decisions)

## Completion Report

After workflow completion, report:

```
✅ SpecKit Research Workflow Finished

Mode: [AUTONOMOUS/INTERACTIVE]
Branch: feature-NNN-short-name
Spec Folder: specs/NNN-short-name/

Research Summary:
- Topic: [research topic]
- Scope: [areas investigated]
- Key Findings: [count]
- Recommendations: [count]

Artifacts Created:
- research.md (comprehensive technical documentation)
- memory/[timestamp]__research_session.md (context saved)

Optional Artifacts (if created):
- research-spike-[name].md (time-boxed investigations)
- decision-record-[name].md (architecture decisions)

Next Steps:
- Review research findings
- Validate technical recommendations
- Run /spec_kit:plan or /spec_kit:complete to proceed with development

STATUS=OK PATH=specs/NNN-short-name/
```

## Examples

**Example 1: Multi-Integration Feature**
```
/spec_kit:research:auto "Webflow CMS integration with external payment gateway and email service"
```

**Example 2: Complex Architecture**
```
/spec_kit:research:confirm "Real-time collaboration system with conflict resolution"
```

**Example 3: Performance-Critical Feature**
```
/spec_kit:research "Video streaming optimization for mobile browsers"
```

---

## Notes

- **Mode Behaviors:**
  - **Autonomous (`:auto`)**: Executes all steps without user approval gates. Self-validates research completeness. Makes informed decisions on research depth. Documents all findings systematically.
  - **Interactive (`:confirm`)**: Pauses after each step for user approval. Presents options: Approve, Review Details, Modify, Skip, Abort. Allows redirection of research focus. Presents findings for review before proceeding. Enables iterative exploration.

- **Integration:**
  - Works with spec folder system for documentation
  - Feeds into `/spec_kit:plan` or `/spec_kit:complete` workflows
  - Context saved via workflows-save-context skill
