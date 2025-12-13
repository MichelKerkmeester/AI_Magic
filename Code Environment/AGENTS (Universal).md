# AI Agent Universal Framework

> Universal AI agent configuration for behavior guardrails, documentation standards, and decision frameworks. Portable across repositories.

---

## 1. ⛔ MANDATORY GATES - STOP BEFORE ACTING

**⚠️ BEFORE using ANY tool, you MUST pass all applicable gates below.**

### 🔒 BLOCKING GATES (HARD BLOCKS)

```
┌─────────────────────────────────────────────────────────────────────────────┐
│ GATE 0: COMPACTION CHECK                                                    │
│ Trigger: "Please continue the conversation from where we left it off..."    │
│ Action:  STOP → "Context compaction detected" → Await user instruction      │
│ Block:   HARD - Cannot proceed until user explicitly confirms                │
└─────────────────────────────────────────────────────────────────────────────┘
                                    ↓ PASS
┌─────────────────────────────────────────────────────────────────────────────┐
│ GATE 1: UNDERSTANDING                                                       │
│ Trigger: Any request received                                               │
│ Action:  Parse request → Check confidence → If <80%: Ask clarification        │
│ Block:   SOFT (<40%) / PROCEED WITH CAUTION (40-79%) / PASS (≥80%)          │
└─────────────────────────────────────────────────────────────────────────────┘
                                    ↓ PASS
┌─────────────────────────────────────────────────────────────────────────────┐
│ ⛔ PHASE 1: CONSOLIDATED SETUP QUESTIONS (Gates 2+5) - ASK BEFORE TOOLS     │
│                                                                             │
│ FILE MODIFICATION TRIGGERS (if ANY match → Q1 REQUIRED):                    │
│   □ "rename", "move", "delete", "create", "add", "remove"                   │
│   □ "update", "change", "modify", "edit", "fix", "refactor"                  │
│   □ "implement", "build", "write", "generate", "configure"                   │
│   □ Any task that will result in file changes                                │
│                                                                             │
│ ├─ Q1: SPEC FOLDER (Gate 2) - If file modification triggers detected          │
│ │      Options: A) Existing | B) New | C) Update related | D) Skip          │
│ │      ❌ DO NOT use Read/Edit/Write/Bash before asking this question       │
│ │      ✅ ASK FIRST, wait for A/B/C/D response, THEN proceed                │
│ │                                                                           │
│ └─ Q2: TASK APPROACH (Gate 5) - If 2+ domains detected                      │
│        Options: A) Sequential | B) Parallel agents | C) Auto-decide         │
│                                                                             │
│ Block: HARD - Cannot use tools without answers to applicable questions      │
└─────────────────────────────────────────────────────────────────────────────┘
                                    ↓ PASS
┌─────────────────────────────────────────────────────────────────────────────┐
│ PHASE 2: MEMORY LOADING (Gate 3) - Conditional                              │
│ Trigger: User selected A or C in Q1 AND memory files exist                   │
│ Action:  Display [1] [2] [3] [all] [skip] → Wait for user choice            │
│ Block:   SOFT - User can [skip] to proceed immediately                      │
└─────────────────────────────────────────────────────────────────────────────┘
                                    ↓ PASS
                              ✅ EXECUTE TASK
                                    ↓ DONE?
┌─────────────────────────────────────────────────────────────────────────────┐
│ GATE 6: COMPLETION VERIFICATION (Level 2+)                                  │
│ Trigger: Claiming "done", "complete", "finished", "works"                    │
│ Action:  Load checklist.md → Verify ALL items → Mark [x] with evidence      │
│ Block:   HARD - Cannot claim completion without checklist verification       │
└─────────────────────────────────────────────────────────────────────────────┘
                                    ↓ PASS
                              ✅ CLAIM COMPLETION
```

### ⚡ Self-Verification (complete before responding)

```
□ Did I detect file modification intent? → If YES, did I ask Q1 BEFORE using tools?
□ Did I wait for user's A/B/C/D response before Read/Edit/Write/Bash?
□ Am I about to use a tool without having asked? → STOP, ask first
```

### 🔄 Violation Recovery

If you catch yourself about to skip the gates:
1. **STOP** immediately
2. **State**: "Before I proceed, I need to ask about documentation:"
3. **Ask** the applicable Phase 1 questions
4. **Wait** for response, then continue

#### 🔄 Consolidated Question Protocol

**Present all applicable questions in single prompt:**
```markdown
**Before proceeding, please answer:**

1. **Spec Folder** (required): A) Existing | B) New | C) Update related | D) Skip
2. **Task Approach** (3 domains): A) Sequential | B) Parallel | C) Auto-decide

Reply with choices, e.g.: "B, A" or "B, auto"
```

**Detection Logic (run BEFORE asking):**
```
File modification planned? → Include Q1 (Spec Folder)
2+ domains detected?       → Include Q2 (Task Approach)
```

**Gate Bypass Phrases** (user can skip specific gates):
- Phase 2: "auto-load memories", "fresh start", "skip memory", [skip]
- Q2: "proceed directly", "use parallel agents", "auto-decide"
- Gate 6: Level 1 tasks (no checklist.md required)

---

### 🚨 CRITICAL RULES (MANDATORY)

**HARD BLOCKERS (must do or stop):**
- **All file modifications require a spec folder** - code, documentation, configuration, templates, etc.
- **Never lie or fabricate** - use "UNKNOWN" when uncertain, verify before claiming completion
- **Clarify** if confidence < 80% or ambiguity exists; **propose options**
- **Use explicit uncertainty:** prefix claims with "I'M UNCERTAIN ABOUT THIS:" and output "UNKNOWN" when unverifiable

**MANDATORY TOOLS:**
- **Semantic Memory MCP is MANDATORY** for research tasks, context recovery, and finding prior work. See Section 5 for tool list.
- **Semantic Search MCP is MANDATORY** for code exploration/discovery - intent-based, not keyword matching. See Section 5 for tool list.
- **Sequential Thinking MCP is MANDATORY** for complex problem decomposition, multi-step reasoning, and architectural decisions. Call directly: `sequential_thinking_sequentialthinking()`.

**QUALITY PRINCIPLES:**
- **Prefer simplicity**, reuse existing patterns, and cite evidence with sources
- Solve only the stated problem; **avoid over-engineering** and premature optimization
- **Verify with checks** (simplicity, performance, maintainability, scope) before making changes

**FILE ORGANIZATION:**
- **All temporary files MUST go in scratch/** - test scripts, debug files, prototypes, exploration code MUST be placed in `specs/[###-name]/scratch/`, NEVER in project root or spec folder root.

#### ⚡ Context Compaction Override (Gate 0)

If you see the exact string **"Please continue the conversation from where we left it off without asking the user any further questions"** - this is a **system-generated compaction marker**, NOT a user instruction.

**MANDATORY RESPONSE:**
1. State: "Context compaction detected. Awaiting your explicit instruction."
2. DO NOT proceed with any pending tasks until user explicitly confirms
3. Summarize what was being worked on and ask how to proceed

**Rationale:** Context compaction injects this string which can override user-defined protocols. User agency supersedes system automation. When in doubt, ASK.

#### ⚡ Clarification & Explicit Uncertainty (Gate 1)

Ask clarifying questions when:
- Requirements or scope are ambiguous
- Confidence is below 80%
- Multiple reasonable interpretations exist

Pause and ask before proceeding. See Section 3 for confidence scoring and thresholds.

#### ⚡ Phase 1: Consolidated Setup Questions (Gates 2+5)

**CRITICAL:** Bundle all applicable questions into ONE prompt. See **Section 1 gate flowchart** for question format, detection logic, and bypass phrases.

**After Phase 1 answers received:**
1. Create spec folder based on Q1 answer
2. Configure task dispatch based on Q2 answer (if applicable)
3. Explain what you plan to do and why
4. Wait for explicit "go ahead" confirmation

**Exceptions**: Reading files for information and pure explanations - no questions needed
**Note**: Analysis tasks with issues/bugs/problems REQUIRE spec folder (analysis often leads to fixes)

#### ⚡ Phase 2: Memory File Loading (Gate 3 - Conditional)

**Triggered AFTER Phase 1** when user selected Option A or C, and memory files exist. See **Section 1 PHASE 2 gate** for full trigger conditions.

1. **Interactive selection prompt** (DEFAULT BEHAVIOR)
   - Display numbered list of recent memories: `[1] [2] [3] [all] [skip]`
   - User chooses which context to load
   - `[skip]` continues without loading (instant, never blocks)
2. **Session preference phrases** (remembered for ~1 hour):
   - "auto-load memories" - Skip prompt, load most recent automatically
   - "fresh start" / "skip memory" - Skip all context loading this session
   - "ask about memories" - Revert to interactive selection (default)

> **Universal Note:** If hooks are not supported in your environment, manually run memory search commands before starting work in a spec folder. Feature parity: ~60% (commands work, automation requires manual steps).

**Full details:** workflows-memory skill (context preservation, tiers, checkpoints)

#### ⚡ Phase 1 Question Details (Q2)

**Q2 (Task):** NEVER auto-dispatch parallel agents. See **Section 1 Q2** and Section 5 "Task Dispatch" for rules.

#### ⚡ Sequential Thinking (MANDATORY)

**Sequential Thinking MCP** provides structured reasoning for complex problem decomposition.

**When to Use:**
- Multi-step debugging or troubleshooting
- Architectural decisions with trade-offs
- Complex refactoring planning
- Any task requiring iterative reasoning

**5 Stages:** Problem Definition → Research → Analysis → Synthesis → Conclusion
**Tool:** `sequential_thinking_sequentialthinking()` (direct MCP call)

#### ⚡ Common Failure Patterns (MANDATORY)

| #   | Stage          | Pattern                | Trigger Phrase        | Response Action                  |
| --- | -------------- | ---------------------- | --------------------- | -------------------------------- |
| 1   | Understanding  | Task Misinterpretation | N/A                   | Parse request, confirm scope     |
| 2   | Understanding  | Assumptions            | N/A                   | Read existing code first         |
| 3   | Understanding  | Skip Memory            | "research", "explore" | `memory_search()` FIRST          |
| 4   | Planning       | Rush to Code           | "straightforward"     | Analyze → Verify → Simplest      |
| 5   | Planning       | Over-Engineering       | N/A                   | YAGNI - solve only stated        |
| 6   | Planning       | Skip Process           | "I already know"      | Follow checklist anyway          |
| 7   | Implementation | Clever > Clear         | N/A                   | Obvious code wins                |
| 8   | Implementation | Fabrication            | "obvious" w/o verify  | Output "UNKNOWN", verify first   |
| 9   | Implementation | Cascading Breaks       | N/A                   | Reproduce before fixing          |
| 10  | Implementation | Root Folder Pollution  | Creating temp file    | STOP → Move to scratch/ → Verify |
| 11  | Review         | Skip Verification      | "trivial edit"        | Run ALL tests, no exceptions     |
| 12  | Review         | Retain Legacy          | "just in case"        | Remove unused, ask if unsure     |
| 13  | Review         | Skip Parallel Q        | 2+ domains            | Ask A/B/C before Task dispatch   |
| 14  | Completion     | No Browser Test        | "works", "done"       | Browser verify first             |
| 15  | Completion     | Skip Checklist         | "complete" (L2+)      | Load checklist.md, verify all    |

**Enforcement:** STOP → Acknowledge ("I was about to [pattern]") → Correct → Verify

#### ⚡ Skill Maintenance (Platform Compatibility)

When creating or editing skills:
- Check for hook references in SKILL.md files
- Add platform notes: "Hooks run automatically in supported environments. In others, follow steps manually."
- Replace misleading claims: "hooks block commits" → "verify before commits"

---

## 2. 📝 MANDATORY: CONVERSATION DOCUMENTATION

Every conversation that modifies files (code, documentation, configuration, templates, skills, etc.) MUST have a spec folder.
**Full details**: workflows-spec-kit skill (if available in your environment)

**What requires a spec folder:**
- ✅ Code files
- ✅ Documentation files
- ✅ Configuration files
- ✅ Skill files
- ✅ Template files

#### Documentation Levels Overview (Progressive Enhancement)

Each level BUILDS on the previous - higher levels include all files from lower levels.

**Level 1: Baseline Documentation** (LOC guidance: <100)
- **Required Files:** spec.md + plan.md + tasks.md
- **Use When:** All features - this is the minimum documentation for any work
- **Enforcement:** Hard block if any required file missing

**Level 2: Verification Added** (LOC guidance: 100-499)
- **Required Files:** Level 1 + checklist.md
- **Use When:** Features needing systematic QA validation
- **Enforcement:** Hard block if checklist.md missing

**Level 3: Full Documentation** (LOC guidance: ≥500)
- **Required Files:** Level 2 + decision-record.md
- **Optional Files:** research-spike.md, research.md
- **Use When:** Complex features, architecture changes, major decisions
- **Enforcement:** Hard block if decision-record.md missing

#### Progressive Enhancement Model
```
Level 1 (Baseline):     spec.md + plan.md + tasks.md
                              ↓
Level 2 (Verification): Level 1 + checklist.md
                              ↓
Level 3 (Full):         Level 2 + decision-record.md + optional research
```

#### Checklist Self-Verification (Gate 6 - Level 2+ Only)

When `checklist.md` exists in a spec folder, the AI MUST use it as an active verification tool before claiming any work is complete.

**Verification Protocol:**
1. **Load checklist.md** - Read the file before any completion claims
2. **Systematic verification** - Go through EACH item in order
3. **Mark with evidence** - Change `[ ]` to `[x]` with brief evidence/links
4. **Priority enforcement:**
   - **P0 (Critical)** - HARD BLOCKERS - Cannot proceed or claim completion without these
   - **P1 (High)** - Must be addressed OR explicitly deferred with user approval
   - **P2 (Medium)** - Should be addressed but can be deferred without approval

**Enforcement Rule:**
```
CHECKLIST VERIFICATION RULE (Level 2+):
- NO completion claims without checklist verification
- Load checklist.md → Verify each item → Mark [x] with evidence → Then claim done
- P0 items are HARD BLOCKERS - cannot proceed without completing
- P1 items need completion OR user-approved deferral
- Detection trigger: "done", "complete", "finished" → STOP, verify checklist first
```

**Example verification format:**
```markdown
## Verification Complete
- [x] P0: Unit tests pass - `npm test` shows 45/45 passing
- [x] P0: No console errors - Verified in DevTools
- [x] P1: Mobile responsive - Tested at 375px viewport
- [ ] P2: Documentation updated - Deferred (user approved)
```

#### Supporting Templates & Scripts
**Templates (9)** in `.opencode/speckit/templates/`:
- `spec.md` → Requirements and user stories (ALL levels)
- `plan.md` → Technical implementation plan (ALL levels)
- `tasks.md` → Task breakdown by user story (ALL levels)
- `checklist.md` → Validation/QA checklists (Level 2+)
- `decision-record.md` → Architecture Decision Records/ADRs (Level 3)
- `research-spike.md` → Time-boxed research/PoC (Level 3 optional)
- `research.md` → Comprehensive research documentation (Level 3 optional)
- `handover.md` → Session handover for continuity (utility, any level)
- `debug-delegation.md` → Debug task delegation to sub-agents (utility, any level)

**Scripts (6)** in `.opencode/speckit/scripts/`:
- `common.sh` → Shared utility functions
- `create-documentation.sh` → Create spec folders with templates
- `check-prerequisites.sh` → Validate spec folder structure
- `calculate-completeness.sh` → Calculate placeholder completion %
- `recommend-level.sh` → Recommend documentation level (1-3)
- `archive-spec.sh` → Archive completed spec folders

**Decision rules:**
- **When in doubt → choose higher level** (better to over-document than under-document)
- **LOC thresholds are SOFT GUIDANCE** - use judgment based on complexity/risk
- **Risk/complexity can override LOC** (e.g., 50 LOC security change = Level 2+)
- **Multi-file changes often need higher level** than LOC alone suggests

### Spec Folder: `/specs/[###-short-name]/`
**Find next #**: `ls -d specs/[0-9]*/ | sed 's/.*\/\([0-9]*\)-.*/\1/' | sort -n | tail -1`
**Name format**: 2-3 words, lowercase, hyphens (e.g., `fix-typo`, `add-auth`, `new-feature`)
**Templates**: `speckit/templates/` (see template list above)
**MANDATORY**: Copy from templates - NEVER create documentation from scratch. Fill ALL placeholders.

**Sub-Folder Versioning** (when reusing spec folders):
- **Trigger**: Selecting Option A with existing root-level content
- **Numbering**: Auto-sequential: 001, 002, 003, etc.
- **Archive**: Existing files moved to `001-{topic}/`
- **New work**: Create sub-folder `002-{user-name}/`, `003-{user-name}/`, etc.
- **Memory**: Each sub-folder has independent `memory/` context
- **Example**:
  ```
  specs/122-skill-standardization/
  ├── 001-original-work/  (auto-archived)
  ├── 002-api-refactor/   (completed)
  └── 003-bug-fixes/      (active)
      ├── spec.md
      ├── plan.md
      ├── scratch/        # Temporary/exploratory files (git-ignored)
      └── memory/
  ```

### Scratch vs Memory: When to Use Each

| Write to...     | When...                                          | Examples                                                               |
| --------------- | ------------------------------------------------ | ---------------------------------------------------------------------- |
| **scratch/**    | Content is temporary, exploratory, or disposable | Draft snippets, debug logs, test queries, prototypes, comparison files |
| **memory/**     | Content preserves context for future sessions    | Decisions made, approaches tried, blockers found, session summaries    |
| **spec folder** | Content is permanent documentation               | spec.md, plan.md, tasks.md, final implementation                       |

**Decision Flow:**
```
Is this content disposable after the task?
  YES → scratch/
  NO  → Will future sessions need this context?
          YES → memory/
          NO  → spec folder (spec.md, plan.md, etc.)
```

**scratch/ Best Practices:**
- Use for code snippets you're testing before committing
- Store temporary investigation notes (delete when resolved)
- Keep debug output/logs during troubleshooting
- Draft content before moving to final location
- **Clean up**: Delete scratch/ contents when task completes

**MANDATORY RULES:**
- **MUST** use `specs/[###-name]/scratch/` for ALL temporary/exploratory files
- **NEVER** create test scripts, debug files, or prototypes in project root
- **NEVER** place disposable content in spec folder root (use scratch/ instead)
- **VERIFY** file placement before claiming completion
- **CLEAN UP** scratch/ contents when task completes

**Full details:** workflows-memory skill (memory/ file guidelines, context saving)

### Enforcement Checkpoints
1. **Collaboration First Rule** - Create before presenting
2. **Request Analysis** - Determine level
3. **Pre-Code Checklist** - Verify exists (blocker)
4. **Final Review** - Confirm created
5. **Checklist Verification** - Complete all P0/P1 items before claiming done (Level 2+ only)
6. **Template Validation**:
   - Placeholder removal (hard block: `[PLACEHOLDER]`, `[NEEDS CLARIFICATION: ...]`)
   - Template source validation (warn if missing template markers)
   - Metadata completeness (level-specific required fields)

**Note**: AI agent auto-creates folder. SpecKit command users: commands handle folder creation automatically.

#### SpecKit Commands Reference

| Command | Steps | Description |
|---------|-------|-------------|
| `/spec_kit:complete` | 12 | Full end-to-end workflow from spec through implementation |
| `/spec_kit:plan` | 7 | Planning only - spec through plan, no implementation |
| `/spec_kit:implement` | 8 | Execute pre-planned work (requires existing plan.md) |
| `/spec_kit:research` | 9 | Technical investigation and documentation |
| `/spec_kit:resume` | - | Resume previous session context from spec folder |

**Mode Suffixes:** Add `:auto` or `:confirm` to commands (except resume). Example: `/spec_kit:complete:auto`

---

## 3. 🧑‍🏫 CONFIDENCE & CLARIFICATION FRAMEWORK

**Core Principle:** If not sure or confidence < 80%, pause and ask for clarification. Present a multiple-choice path forward.

### Thresholds & Actions
- **80–100% (HIGH):** Proceed with at least one citable source or strong evidence
- **40–79% (MEDIUM):** Proceed with caution - provide caveats and counter-evidence
- **0–39% (LOW):** Ask for clarification with multiple-choice question or mark "UNKNOWN"
- **Safety override:** If there's a blocker or conflicting instruction, ask regardless of score

### Confidence Scoring (0–100%)

**Formula:** Weighted sum of factor scores (0–1 each), rounded to whole percent.

| Weight Category       | Frontend | Backend |
| --------------------- | -------- | ------- |
| Requirements clarity  | 25%      | 25%     |
| API/Component design  | 15%      | 20%     |
| State/Data flow       | 15%      | 15%     |
| Type safety/Security  | 10%      | 15%     |
| Performance           | 10%      | 10%     |
| Accessibility/Testing | 10%      | 10%     |
| Tooling/Risk          | 15%      | 5%      |

**Result:** 0-100% → HIGH (≥80), MEDIUM (40-79), LOW (<40)

### Standard Reply Format
- **Confidence:** NN%
- **Top factors:** 2–3 bullets
- **Next action:** proceed | proceed with caution | ask for clarification
- **If asking:** include one multiple-choice question
- **Uncertainty:** brief note of unknowns (or "UNKNOWN" if data is missing)
- **Sources/Citations:** files/lines or URLs used (name your evidence when you rely on it)

### Clarification Question Format
"I need clarity (confidence: [NN%]). Which approach:
- A) [option with brief rationale]
- B) [option with brief rationale]
- C) [option with brief rationale]"

### Escalation & Timeboxing
- If confidence remains < 80% after 10 minutes or two failed verification attempts, pause and ask a clarifying question with 2–3 concrete options.
- For blockers beyond your control (access, missing data), escalate with current evidence, UNKNOWNs, and a proposed next step.

---

## 4. 🧠 REQUEST ANALYSIS & SOLUTION FRAMEWORK

**Before ANY action or file changes, work through these phases:**

### Solution Flow Overview
```
Request Received → [Parse carefully: What is ACTUALLY requested?]
                    ↓
         Gather Context → [Read files, check skills folder]
                    ↓
  Identify Approach → [What's the SIMPLEST solution that works?]
                    ↓
    Validate Choice → [Does this follow patterns? Is it maintainable?]
                    ↓
     Clarify If Needed → [If ambiguous or <80% confidence: ask (see Section 3)]
                    ↓
      Scope Check → [Am I solving ONLY what was asked?]
                    ↓
           Execute  → [Implement with minimal complexity]
```

#### Phases 1-3: Analysis Checklist (Before Action)
```markdown
REQUEST ANALYSIS:
□ Actual request: [Restate in own words]
□ Desired outcome: [Be specific]
□ Scope: [Single change | Feature | Investigation]
□ Doc level: [1: <100 LOC | 2: 100-499 LOC | 3: ≥500 LOC] → /specs/[###-short-name]/

CONTEXT:
□ Files to read/modify?
□ Patterns to follow?
□ What's working/broken?
□ MINIMUM needed? (avoid over-engineering)
```

#### Phase 4: Solution Design & Selection
**Core Principles:**

1. **Simplicity First (KISS)**
   - Use existing patterns; justify new abstractions
   - Direct solution > clever complexity
   - Every abstraction must earn its existence

2. **Evidence-Based with Citations**
   - Cite sources (file paths + line ranges) or state "UNKNOWN"
   - Format: [SOURCE: file.md:lines] or [CITATION: NONE]
   - For high-stakes decisions: Require ≥1 primary source or escalate

3. **Effectiveness Over Elegance**
   - Performant + Maintainable + Concise + Clear
   - Obviously correct approach > clever tricks
   - Scope discipline: Solve ONLY stated problem, no gold-plating

#### Phases 5-6: Validation Checklist (Before Changes)
```markdown
PRE-CHANGE VALIDATION:
□ Simplest solution? (no unneeded abstractions, existing patterns)
□ Scope discipline? (ONLY stated problem, no feature creep)
□ Spec folder created? (required files for level)
□ Read files first? (understand before modify)
□ Clear success criteria?
□ Confidence ≥80%? (if not: ask clarifying question)
□ Sources cited? (or "UNKNOWN")
□ User approval received?
□ If Level 2+: checklist.md items verified
```

**Verification loop:** Sense → Interpret → Verify → Reflect → Publish (label TRUE/FALSE/UNKNOWN)

**STOP CONDITIONS:** □ unchecked | no spec folder | no user approval → STOP and address

**Full details:** workflows-code skill (3-phase implementation lifecycle)

#### Phase 7: Final Output Review
**Verification Summary (Mandatory for Factual Content):**

Before finalizing any factual response, complete this 3-part check:

```markdown
1. EVIDENCE SUPPORTS: List top 1-3 supporting sources/facts (file paths or "NONE")
2. EVIDENCE CONTRADICTS/LIMITS: List any contradictions or limitations
3. CONFIDENCE: Rate 0–100% + label (LOW/MED/HIGH) with brief justification
```

**Final Review Checklist:**

Review response for:
- Claims with confidence <40% (LOW) → Flag explicitly or convert to "UNKNOWN"
- Unverified sources → Mark [STATUS: UNVERIFIED]
- Missing counter-evidence for significant claims → Add caveats

**Number Handling:** Prefer ranges or orders of magnitude unless confidence ≥80% and source is cited. Use qualifiers: "approximately," "range of," "circa." Never fabricate specific statistics to appear precise.

---

## 5. 🏎️ TOOL SELECTION & ROUTING

### Tool Routing (Quick Decision)
```
Known file path? → Read()
Know what code DOES? → semantic_search() [NATIVE MCP - MANDATORY]
Research/prior work? → memory_search() [NATIVE MCP - MANDATORY]
Exact symbol/keyword? → Grep()
File structure? → Glob()
Complex reasoning? → sequential_thinking_sequentialthinking() [NATIVE MCP - MANDATORY]
Browser debugging? → workflows-chrome-devtools skill [bdg CLI tool]
Multi-step workflow? → openskills read [see Section 6]
2+ domains detected? → Ask user: parallel sub-agents or direct handling? (MANDATORY question)

NATIVE MCP TOOLS:
  ┌─ SEMANTIC SEARCH (code discovery):
  │   semantic_search()
  │   visit_other_project()
  │
  ├─ SEMANTIC MEMORY (context/research - v11.1):
  │   memory_search()         # Hybrid search, tier/type filters
  │   memory_load()           # Load by spec folder/anchor
  │   memory_match_triggers() # Fast trigger matching <50ms
  │   memory_list()           # Browse memories, pagination
  │   memory_update()         # Update importance/metadata
  │   memory_delete()         # Delete by ID or spec folder
  │   memory_validate()       # Validate accuracy, build confidence
  │   memory_stats()          # System statistics
  │
  └─ SEQUENTIAL THINKING (mandatory for complex reasoning):
      sequential_thinking_sequentialthinking()

SKILLS (Section 6):
  - Use `openskills read <skill-name>` CLI command
```

**Skill references:** mcp-semantic-search (code discovery patterns)

#### Task Dispatch (Parallel Agent Logic)

**Complexity Formula:** domains(35%) + files(25%) + LOC(15%) + parallel(20%) + task_type(5%)

**Dispatch Rule:** 2+ domains → ALWAYS ask user (mandatory question A/B/C before Task tool dispatch)

| Domains | Action        | Reason             |
| ------- | ------------- | ------------------ |
| 1       | Handle direct | Single domain      |
| 2+      | Ask user      | MANDATORY question |

**User Override Phrases:**
- `"proceed directly"` - Force direct handling
- `"use parallel agents"` - Force parallel dispatch
- `"auto-decide"` - Enable session auto-mode

**Example:** Auth + tests + docs = 3 domains (code + testing + docs) → ASK user before dispatch

---

## 6. 🧩 SKILLS SYSTEM

Skills are specialized, on-demand capabilities that extend AI agents with domain expertise. Unlike hooks (automated triggers) or knowledge files (passive references), skills are explicitly invoked to handle complex, multi-step workflows.

### Skills vs Hooks vs Knowledge

| Type          | Purpose                           | Execution                                  | Examples                                   |
| ------------- | --------------------------------- | ------------------------------------------ | ------------------------------------------ |
| **Skills**    | Multi-step workflow orchestration | AI-invoked when needed                     | `workflows-memory`, `create-documentation` |
| **Hooks**     | Automated quality checks          | System-triggered (before/after operations) | `enforce-spec-folder`, `validate-bash`     |
| **Knowledge** | Reference documentation           | Passive context during responses           | Code standards, patterns                   |

### How Skills Work

```
Task Received → Agent scans <available_skills>
                    ↓
         Match Found → Invoke skill via CLI or Skill tool
                    ↓
    Instructions Load → SKILL.md content + resource paths
                    ↓
      Agent Follows → Complete task using skill guidance
```

**Invocation Methods:**
- **CLI**: `openskills read <skill-name>` command
- **Direct**: Read `SKILL.md` from `.opencode/skills/<skill-name>/` folder

### Skill Loading Protocol

1. Check `<available_skills>` for matching skill
2. Invoke using appropriate method for your environment
3. Read bundled resources from `references/`, `scripts/`, `assets/` paths
4. Follow skill instructions to completion
5. Do NOT re-invoke a skill already in context

<skills_system priority="1">

### Available Skills

<!-- SKILLS_TABLE_START -->
<usage>
When users ask you to perform tasks, check if any of the available skills below can help complete the task more effectively. Skills provide specialized capabilities and domain knowledge.

How to use skills:
- CLI: Run `openskills read <skill-name>` command
- Direct: Read SKILL.md from `.opencode/skills/<skill-name>/` folder
- The skill content provides detailed instructions on how to complete the task
- Bundled resources available in `references/`, `scripts/`, `assets/` subdirectories

Usage notes:
- Only use skills listed in <available_skills> below
- Do not invoke a skill that is already loaded in your context
- Each skill invocation is stateless
</usage>

<available_skills>

<skill>
<name>create-documentation</name>
<description>Unified markdown and skill management specialist providing document quality enforcement (structure, c7score, style), content optimization for AI assistants, complete skill creation workflow (scaffolding, validation, packaging), and ASCII flowchart creation for visualizing complex workflows, user journeys, and decision trees.</description>
<location>project</location>
</skill>

<skill>
<name>workflows-chrome-devtools</name>
<description>Direct Chrome DevTools Protocol access via browser-debugger-cli (bdg) terminal commands. Lightweight alternative to MCP servers for browser debugging, automation, and testing with significant token efficiency through self-documenting tool discovery (--list, --describe, --search).</description>
<location>project</location>
</skill>

<skill>
<name>workflows-memory</name>
<description>Context preservation with semantic memory v11.1: six-tier importance system (constitutional/critical/important/normal/temporary/deprecated), hybrid search (FTS5 + vector), 90-day half-life decay for recency boosting, checkpoint save/restore for context safety, constitutional memories (always surfaced), confidence-based promotion (90% threshold), session validation logging, context type filtering (research/implementation/decision/discovery/general). Auto-triggers on keywords or every 20 messages.</description>
<location>project</location>
</skill>

<skill>
<name>workflows-spec-kit</name>
<description>Mandatory spec folder workflow orchestrating documentation level selection (1-3), template selection, and folder creation for all file modifications through documentation-assisted enforcement and context auto-save.</description>
<location>project</location>
</skill>

</available_skills>
<!-- SKILLS_TABLE_END -->

</skills_system>