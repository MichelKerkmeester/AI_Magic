---
description: Research workflow (9 steps) - technical investigation and documentation. Supports :auto and :confirm modes
argument-hint: "[research-topic] [:auto|:confirm]"
allowed-tools: Read, Write, Edit, Bash, Grep, Glob, Task, AskUserQuestion, WebFetch, WebSearch
---

# 🚨 MANDATORY GATES - BLOCKING ENFORCEMENT

**These gates MUST be passed sequentially. Each gate BLOCKS until complete. You CANNOT proceed to the workflow until ALL gates show ✅ PASSED or ⏭️ N/A.**

---

## 🔒 GATE 0: Input Validation

**STATUS: ☐ BLOCKED**

```
EXECUTE THIS CHECK FIRST:

├─ IF $ARGUMENTS is empty, undefined, or whitespace-only (ignoring :auto/:confirm flags):
│   │
│   ├─ ASK user: "What topic would you like to research?"
│   ├─ WAIT for user response (DO NOT PROCEED)
│   ├─ Store response as: research_topic
│   └─ SET STATUS: ✅ PASSED
│
└─ IF $ARGUMENTS contains content:
    ├─ Store as: research_topic
    └─ SET STATUS: ✅ PASSED

⛔ HARD STOP: DO NOT read past this gate until STATUS = ✅ PASSED
⛔ NEVER infer topics from context, screenshots, or conversation history
```

**Gate 0 Output:** `research_topic = ________________`

---

## 🔒 GATE 1: Spec Folder Selection

**STATUS: ☐ BLOCKED**

```
EXECUTE AFTER GATE 0 PASSES:

1. Search for related spec folders:
   $ ls -d specs/*/ 2>/dev/null | tail -10

2. ASK user with these EXACT options:
   ┌────────────────────────────────────────────────────────────┐
   │ "Where should this research be documented?"                │
   │                                                            │
   │ A) Use existing spec folder: [suggest if related found]    │
   │ B) Create new spec folder: specs/[NNN]-[topic-slug]/       │
   │ C) Update related spec: [if partial match found]           │
   │ D) Skip documentation (no persistent artifacts)            │
   └────────────────────────────────────────────────────────────┘

3. WAIT for explicit user choice (A, B, C, or D)

4. Store results:
   - spec_choice = [A/B/C/D]
   - spec_path = [path or null if D]

5. SET STATUS: ✅ PASSED

⛔ HARD STOP: DO NOT proceed until user explicitly selects A, B, C, or D
⛔ NEVER auto-create spec folders without user confirmation
⛔ NEVER assume or infer the user's choice
```

**Gate 1 Output:** `spec_choice = ___` | `spec_path = ________________`

---

## 🔒 GATE 2: Memory Context Loading

**STATUS: ☐ BLOCKED / ☐ N/A**

```
EXECUTE AFTER GATE 1 PASSES:

CHECK spec_choice value:

├─ IF spec_choice == D (Skip):
│   └─ SET STATUS: ⏭️ N/A (no spec folder, no memory)
│
├─ IF spec_choice == B (Create new):
│   └─ SET STATUS: ⏭️ N/A (new folder has no memory)
│
└─ IF spec_choice == A or C (Use existing):
    │
    ├─ Check: Does spec_path/memory/ exist AND contain files?
    │
    ├─ IF memory/ is empty or missing:
    │   └─ SET STATUS: ⏭️ N/A (no memory to load)
    │
    └─ IF memory/ has files:
        │
        ├─ ASK user:
        │   ┌────────────────────────────────────────────────────┐
        │   │ "Load previous context from this spec folder?"     │
        │   │                                                    │
        │   │ A) Load most recent memory file (quick refresh)     │
        │   │ B) Load all recent files, up to 3 (comprehensive)   │
        │   │ C) List all files and select specific                │
        │   │ D) Skip (start fresh, no context)                  │
        │   └────────────────────────────────────────────────────┘
        │
        ├─ WAIT for user response
        ├─ Execute loading based on choice (use Read tool)
        ├─ Acknowledge loaded context briefly
        └─ SET STATUS: ✅ PASSED

⛔ HARD STOP: DO NOT proceed until STATUS = ✅ PASSED or ⏭️ N/A
```

**Gate 2 Output:** `memory_loaded = [yes/no]` | `context_summary = ________________`

---

## ✅ GATE STATUS VERIFICATION

**Before continuing to the workflow, verify ALL gates:**

| Gate                | Required Status   | Your Status | Output Value                         |
| ------------------- | ----------------- | ----------- | ------------------------------------ |
| GATE 0: Input       | ✅ PASSED          | ______      | research_topic: ______               |
| GATE 1: Spec Folder | ✅ PASSED          | ______      | spec_choice: ___ / spec_path: ______ |
| GATE 2: Memory      | ✅ PASSED or ⏭️ N/A | ______      | memory_loaded: ______                |

```
VERIFICATION CHECK:
├─ ALL gates show ✅ PASSED or ⏭️ N/A?
│   ├─ YES → Proceed to "# SpecKit Research" section below
│   └─ NO  → STOP and complete the blocked gate
```

---

## ⚠️ VIOLATION SELF-DETECTION

**You are IN VIOLATION if you:**
- Started reading the workflow section before all gates passed
- Proceeded without asking user for research topic (Gate 0)
- Auto-created or assumed a spec folder without A/B/C/D choice (Gate 1)
- Skipped memory prompt when using existing folder with memory files (Gate 2)
- Inferred topic from context instead of explicit user input

**VIOLATION RECOVERY PROTOCOL:**
```
1. STOP immediately - do not continue current action
2. STATE: "I violated GATE [X] by [specific action]. Correcting now."
3. RETURN to the violated gate
4. COMPLETE the gate properly (ask user, wait for response)
5. RESUME only after all gates pass verification
```

---

# SpecKit Research

Conduct comprehensive technical investigation and create research documentation. Use before specification when technical uncertainty exists or to document findings for future reference.

---

```yaml
role: Technical Researcher with Comprehensive Analysis Expertise
purpose: Conduct deep technical investigation and create structured research documentation
action: Run 9-step research workflow from investigation through documentation compilation

operating_mode:
  workflow: sequential_9_step
  workflow_compliance: MANDATORY
  workflow_execution: autonomous_or_interactive
  approvals: step_by_step_for_confirm_mode
  tracking: research_finding_accumulation
  validation: completeness_check_17_sections
```

---

## 1. 📋 PURPOSE

Run the 9-step research workflow: codebase investigation, external research, technical analysis, and documentation. Creates research.md with comprehensive findings. Use when technical uncertainty exists before planning.

---

## 2. 📝 CONTRACT

**Inputs:** `$ARGUMENTS` — Research topic with optional parameters (focus, scope, constraints)
**Outputs:** Spec folder with research.md (17 sections) + `STATUS=<OK|FAIL|CANCELLED>`

### User Input

```text
$ARGUMENTS
```

---

## 3. ⚡ WORKFLOW OVERVIEW (9 STEPS)

| Step | Name                   | Purpose                       | Outputs                              |
| ---- | ---------------------- | ----------------------------- | ------------------------------------ |
| 1    | Request Analysis       | Define research scope         | feature_summary, research_objectives |
| 2    | Pre-Work Review        | Review AGENTS.md, standards   | principles_established               |
| 3    | Codebase Investigation | Explore existing patterns     | current_state_analysis               |
| 4    | External Research      | Research docs, best practices | best_practices_summary               |
| 5    | Technical Analysis     | Feasibility assessment        | technical_specifications             |
| 6    | Quality Checklist      | Generate validation checklist | quality_checklist                    |
| 7    | Solution Design        | Architecture and patterns     | solution_architecture                |
| 8    | Research Compilation   | Create research.md            | research.md                          |
| 9    | Save Context           | Preserve conversation         | memory/*.md                          |

---

## 4. 📊 RESEARCH DOCUMENT SECTIONS (17 SECTIONS)

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

## 5. ⚡ INSTRUCTIONS

### Phase 1: Mode Detection & Input Parsing

#### Step 1.1: Parse Mode Suffix

Detect execution mode from command invocation:

| Pattern                           | Mode        | Behavior                                      |
| --------------------------------- | ----------- | --------------------------------------------- |
| `/spec_kit:research:auto`         | AUTONOMOUS  | Execute all steps without user approval gates |
| `/spec_kit:research:confirm`      | INTERACTIVE | Pause at each step for user approval          |
| `/spec_kit:research` (no suffix)  | PROMPT      | Ask user to choose mode                       |

#### Step 1.2: Mode Selection (when no suffix detected)

If no `:auto` or `:confirm` suffix is present, use AskUserQuestion:

**Question**: "How would you like to execute this research workflow?"

| Option | Mode        | Description                                                                       |
| ------ | ----------- | --------------------------------------------------------------------------------- |
| **A**  | Autonomous  | Execute all 9 steps without approval gates. Best for focused research topics.     |
| **B**  | Interactive | Pause at each step for approval. Best for exploratory research needing direction. |

**Wait for user response before proceeding.**

#### Step 1.3: Verify Gates Passed

**⚠️ CHECKPOINT: Confirm all gates from the enforcement section above are complete.**

Before proceeding, verify you have these values from the gates:
- `research_topic` from GATE 0
- `spec_choice` and `spec_path` from GATE 1
- `memory_loaded` status from GATE 2

**If ANY gate is incomplete, STOP and return to the MANDATORY GATES section.**

#### Step 1.4: Transform Raw Input

Parse the research_topic (from GATE 0) and transform into structured user_inputs fields.

**Field Extraction Rules**:

| Field         | Pattern Detection                                               | Default If Empty                                   |
| ------------- | --------------------------------------------------------------- | -------------------------------------------------- |
| `git_branch`  | "branch: X", "on branch X", "feature/X"                         | Auto-create feature-{NNN}                          |
| `spec_folder` | "specs/NNN", "spec folder X", "in specs/X"                      | **USE VALUE FROM GATE 1** (user's explicit choice) |
| `context`     | "using X", "with Y", "tech stack:", "investigating:"            | Infer from request                                 |
| `issues`      | "issue:", "bug:", "problem:", "error:", "question:", "unknown:" | Topics to investigate                              |
| `request`     | Research topic description (REQUIRED)                           | ERROR if completely empty                          |
| `environment` | URLs, "staging:", "example:"                                    | Skip browser analysis                              |
| `scope`       | File paths, glob patterns, "focus:"                             | Default to specs/**                                |

**IMPORTANT:** The `spec_folder` field MUST come from the user's explicit choice in Step 1.3.
Do NOT auto-create or infer - the user MUST have selected Option A, B, C, or D.

#### Step 1.5: Load & Execute Workflow Prompt

Based on detected/selected mode:

- **AUTONOMOUS**: Load and execute `.opencode/command/spec_kit/assets/spec_kit_research_auto.yaml`
- **INTERACTIVE**: Load and execute `.opencode/command/spec_kit/assets/spec_kit_research_confirm.yaml`

### Phase 2: Workflow Execution

Execute the 9 steps defined in Workflow Overview. Each step produces artifacts that feed into subsequent steps. See prompt files for detailed step-by-step instructions.

---

## 6. 📌 KEY DIFFERENCES FROM OTHER COMMANDS

- **Does NOT proceed to implementation** - Terminates after research.md
- **Primary output is research.md** - Comprehensive technical documentation
- **Use case** - Technical uncertainty, feasibility analysis, documentation
- **Next steps** - Can feed into `/spec_kit:plan` or `/spec_kit:complete`

---

## 7. 🔗 CONTEXT LOADING

When resuming work in an existing spec folder, the system will prompt to load prior session memory:
- **A)** Load most recent memory file (quick context refresh)
- **B)** Load all recent files (up to 3) (comprehensive context)
- **C)** List all files and select specific (historical search)
- **D)** Skip (start fresh, no context)

See AGENTS.md Section 2 for full memory file handling details.

---

## 8. 🔧 FAILURE RECOVERY

| Failure Type                 | Recovery Action                                           |
| ---------------------------- | --------------------------------------------------------- |
| Research scope unclear       | Ask clarifying questions, narrow focus                    |
| External sources unavailable | Document limitation, continue with available info         |
| Conflicting findings         | Document both perspectives with analysis, flag for review |
| Technical dead-end           | Document findings, recommend alternative approach         |

---

## 9. ⚠️ ERROR HANDLING

| Condition                    | Action                                                   |
| ---------------------------- | -------------------------------------------------------- |
| Empty `$ARGUMENTS`           | Prompt user: "Please describe what you want to research" |
| Unclear research scope       | Ask clarifying questions                                 |
| External sources unavailable | Document limitation, continue with available info        |
| Conflicting findings         | Document both perspectives with analysis                 |

---

## 10. 📁 DOCUMENTATION LEVELS (PROGRESSIVE ENHANCEMENT)

| Level                      | Required Files               | LOC Guidance | Use Case                               |
| -------------------------- | ---------------------------- | ------------ | -------------------------------------- |
| **Level 1 (Baseline)**     | spec.md + plan.md + tasks.md | <100 LOC     | Simple changes, bug fixes              |
| **Level 2 (Verification)** | Level 1 + checklist.md       | 100-499 LOC  | Medium features, refactoring           |
| **Level 3 (Full)**         | Level 2 + decision-record.md | >=500 LOC    | Complex features, architecture changes |

**Note:** LOC thresholds are soft guidance. Choose level based on complexity and risk.

---

## 11. 📁 TEMPLATES USED

**Core Templates:**
- `.opencode/speckit/templates/spec.md` (Level 1+)
- `.opencode/speckit/templates/plan.md` (Level 1+)
- `.opencode/speckit/templates/tasks.md` (Level 1+)
- `.opencode/speckit/templates/checklist.md` (Level 2+)
- `.opencode/speckit/templates/decision-record.md` (Level 3)

**Research Templates (primary for this workflow):**
- `.opencode/speckit/templates/research.md` (primary output)
- `.opencode/speckit/templates/research-spike.md` (optional for time-boxed sub-investigations)

**Utility Templates:**
- `.opencode/speckit/templates/handover.md` (any level)
- `.opencode/speckit/templates/debug-delegation.md` (any level)

---

## 12. 📊 COMPLETION REPORT

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

---

## 13. 🔍 EXAMPLES

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

## 14. 📌 NOTES

- **Mode Behaviors:**
  - **Autonomous (`:auto`)**: Executes all steps without user approval gates. Self-validates research completeness. Makes informed decisions on research depth. Documents all findings systematically.
  - **Interactive (`:confirm`)**: Pauses after each step for user approval. Presents options: Approve, Review Details, Modify, Skip, Abort. Allows redirection of research focus. Presents findings for review before proceeding. Enables iterative exploration.

- **Parallel Sub-Agent Dispatch (AGENTS.md Compliant):**
  - Eligible phases (Codebase Investigation, External Research, Technical Analysis) can dispatch parallel sub-agents for faster execution
  - Complexity scoring evaluates: domain count (35%), file count (25%), LOC estimate (15%), parallel opportunity (20%), task type (5%)
  - **Dispatch Behavior:**
    - <20% complexity → Execute directly (no parallel agents)
    - ≥20% + 2 domains → ALWAYS ask user via AskUserQuestion
    - No auto-dispatch: Per AGENTS.md Section 1, always ask before parallel dispatch
  - **Session Preference:** User's choice persists for 1 hour
  - **Override Phrases:** "proceed directly", "use parallel agents", "auto-decide"

- **Integration:**
  - Works with spec folder system for documentation
  - Feeds into `/spec_kit:plan` or `/spec_kit:complete` workflows
  - Context saved via workflows-memory skill
