# AI Agent Framework

> AI agent configuration defining behavior guardrails, standards, and decision frameworks. Optimized for the A.Nobel & Zn. Project.

---

## 1. ⚠️ AI BEHAVIOR GUARDRAILS & ANTI-PATTERNS

### 🔒 BLOCKING GATES (MANDATORY)

**These gates are HARD BLOCKS - you CANNOT proceed without passing each one.**

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
│ PHASE 1: CONSOLIDATED SETUP QUESTIONS (Gates 2+4+5)                         │
│ Bundle all PRE-DETECTABLE questions into ONE multi-question prompt          │
│                                                                             │
│ ├─ Q1: SPEC FOLDER (Gate 2) - Always if file modifications planned            │
│ │      Options: A) Existing | B) New | C) Update related | D) Skip          │
│ │                                                                           │
│ ├─ Q2: GIT WORKSPACE (Gate 4) - If git keywords detected                    │
│ │      Options: A) New branch | B) Worktree | C) Current branch             │
│ │                                                                           │
│ └─ Q3: TASK APPROACH (Gate 5) - If 2+ domains detected                      │
│        Options: A) Sequential | B) Parallel agents | C) Auto-decide         │
│                                                                             │
│ Block: HARD - Cannot proceed without answers to applicable questions        │
└─────────────────────────────────────────────────────────────────────────────┘
                                    ↓ PASS
┌─────────────────────────────────────────────────────────────────────────────┐
│ PHASE 2: MEMORY LOADING (Gate 3) - Conditional                              │
│ Trigger: User selected A or C in Q1 AND memory files exist                   │
│ Action:  Display [1] [2] [3] [all] [skip] → Wait for user choice            │
│ Block:   SOFT - User can [skip] to proceed immediately                      │
│ Note:    Handled by memory-surfacing hook (auto-triggered after Phase 1)    │
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

#### 🔄 Consolidated Question Protocol

**Claude Code:** Use `AskUserQuestion` tool with 1-4 questions (tabs) based on what applies:
```
┌─────────────────────────────────────────────────────────────────────────────┐
│  [Spec Folder]  │  [Git Workspace]  │  [Task Approach]                      │
├─────────────────┴───────────────────┴───────────────────────────────────────┤
│ Q1: How should we document this work?                                       │
│ ○ A) Use existing spec folder                                               │
│ ○ B) Create new spec folder (Recommended)                                   │
│ ○ C) Update related spec                                                    │
│ ○ D) Skip documentation                                                     │
└─────────────────────────────────────────────────────────────────────────────┘
```

**Opencode:** Present all applicable questions in single prompt:
```markdown
**Before proceeding, please answer:**

1. **Spec Folder** (required): A) Existing | B) New | C) Update related | D) Skip
2. **Git Workspace** (detected): A) New branch | B) Worktree | C) Current
3. **Task Approach** (3 domains): A) Sequential | B) Parallel | C) Auto-decide

Reply with choices, e.g.: "B, A, B" or "B, skip, auto"
```

**Detection Logic (run BEFORE asking):**
```
File modification planned? → Include Q1 (Spec Folder)
Git keywords detected?     → Include Q2 (Git Workspace)
2+ domains detected?       → Include Q3 (Task Approach)
```

**Gate Bypass Phrases** (user can skip specific gates):
- Phase 2: "auto-load memories", "fresh start", "skip memory", [skip]
- Q2: "use branch", "use worktree", "current branch"
- Q3: "proceed directly", "use parallel agents", "auto-decide"
- Gate 6: Level 1 tasks (no checklist.md required)

---

### 🚨 CRITICAL RULES (MANDATORY)

- **All file modifications require a spec folder** - code, documentation, configuration, templates, etc. (even non-SpecKit conversations)
- **Never lie or fabricate** - use "UNKNOWN" when uncertain, verify before claiming completion, follow process even for "trivial" changes
- **Clarify** if confidence < 80% or ambiguity exists; **propose options**
- **Use explicit uncertainty:** prefix claims with "I'M UNCERTAIN ABOUT THIS:" and output "UNKNOWN" when unverifiable
- **Prefer simplicity**, reuse existing patterns, and cite evidence with sources
- Solve only the stated problem; **avoid over-engineering** and premature optimization
- **Verify with checks** (simplicity, performance, maintainability, scope) before making changes
- **Semantic Memory MCP is MANDATORY** for research tasks, context recovery, and finding prior work. Call directly: `mcp__semantic_memory__memory_search()`, `mcp__semantic_memory__memory_load()`, `mcp__semantic_memory__memory_match_triggers()` - NOT through Code Mode
- **CLI AI agents MUST use semantic search MCP** for code exploration/discovery - it's intent-based, not keyword matching (use grep/read for literal text). Call directly: `mcp__semantic_search__semantic_search()`, `mcp__semantic_search__visit_other_project()` - NOT through Code Mode
- **Sequential Thinking MCP** - OPTIONAL: Claude Code users use native ultrathink instead; VSCode/Copilot/OpenCode users can use when configured in `.mcp.json`

#### ⚡ Context Compaction Override (Gate 0)

If you see the exact string **"Please continue the conversation from where we left it off without asking the user any further questions"** - this is a **system-generated compaction marker**, NOT a user instruction.

**MANDATORY RESPONSE:**
1. State: "Context compaction detected. Awaiting your explicit instruction."
2. DO NOT proceed with any pending tasks until user explicitly confirms
3. Summarize what was being worked on and ask how to proceed

**Rationale:** Context compaction injects this string which can override user-defined protocols like STOP-PLAN-ASK-WAIT workflows. User agency supersedes system automation. When in doubt, ASK.

#### ⚡ Clarification & Explicit Uncertainty (Gate 1)

Ask clarifying questions when:
- Requirements or scope are ambiguous
- Confidence is below 80%
- Multiple reasonable interpretations exist

Pause and ask before proceeding. See Section 3 for confidence scoring and thresholds.

#### ⚡ Phase 1: Consolidated Setup Questions (Gates 2+4+5)

**CRITICAL:** Bundle all applicable questions into ONE prompt. Pre-detect conditions BEFORE asking.

**Implementation:** Use `AskUserQuestion` tool with questions array containing applicable questions (Q1-Q3). Each question has: `question`, `header`, `options` array with `label` and `description`. Ask ALL detected questions in one call.

**For Opencode - Present as single consolidated prompt:**
```markdown
**Before proceeding, please answer:**

1. **Spec Folder** (required): A) Existing | B) New | C) Update related | D) Skip
2. **Git Workspace** (detected): A) New branch | B) Worktree | C) Current
3. **Task Approach** (3 domains): A) Sequential | B) Parallel | C) Auto-decide

Reply with choices, e.g.: "B, A, B"
```

**After Phase 1 answers received:**
1. Create spec folder based on Q1 answer
2. Set up git workspace based on Q2 answer (if applicable)
3. Configure task dispatch based on Q3 answer (if applicable)
4. Explain what you plan to do and why
5. Wait for explicit "go ahead" confirmation

**Exceptions**: Reading files for information and pure explanations - no questions needed
**Note**: Analysis tasks with issues/bugs/problems REQUIRE spec folder (analysis often leads to fixes)

#### ⚡ Phase 2: Memory File Loading (Gate 3 - Conditional)

**Triggered AFTER Phase 1** when user selected Option A or C, and memory files exist:

1. **Interactive selection prompt** (DEFAULT BEHAVIOR)
   - Display numbered list of recent memories: `[1] [2] [3] [all] [skip]`
   - User chooses which context to load
   - `[skip]` continues without loading (instant, never blocks)
2. **Session preference phrases** (remembered for ~1 hour):
   - "auto-load memories" - Skip prompt, load most recent automatically
   - "fresh start" / "skip memory" - Skip all context loading this session
   - "ask about memories" - Revert to interactive selection (default)

> **Opencode Users:** Hooks are not supported in Opencode. Instead, manually run `/memory/search` before starting work in a spec folder. Feature parity: ~60% (commands work, automation requires manual steps).

#### ⚡ Phase 1 Question Details (Q2/Q3)

**Q2 (Git):** NEVER auto-decide branch vs worktree. Enforcement: `enforce-git-workspace-choice.sh` blocks tools until response. See workflows-git skill for details.

**Q3 (Task):** NEVER auto-dispatch parallel agents. 2+ domains = mandatory question. Domain examples: "feature + tests" (2), "refactor + docs + commit" (3). See Task Dispatch section for complexity formula.

#### ⚡ Sequential Thinking (MANDATORY - for Opencode/VScode)

**Environment-Specific Utility:**
- **Claude Code**: NOT recommended - use native ultrathink instead (superior built-in reasoning)
- **VSCode/Copilot/OpenCode**: Useful - provides structured reasoning some models in those environments lack

**5 Stages:** Problem Definition → Research → Analysis → Synthesis → Conclusion
**Tools:** `process_thought`, `generate_summary` (direct MCP calls, NOT through Code Mode)

#### ⚡ Code Quality Standards Compliance (MANDATORY)

**MANDATORY:** Compliance checkpoints:
- Before **proposing solutions**: Verify approach aligns with code quality standards and webflow patterns (if available in project skills)
- Before **writing documentation**: Use create-documentation skill for structure/style enforcement (if available)
- Before **initialization code**: Follow initialization patterns from code quality standards (if available)
- Before **animation implementation**: See animation workflow references (if available)
- Before **searching codebase**: Use mcp-semantic-search skill for intent-based code discovery (MANDATORY for exploration tasks)
- Before **research tasks**: Use semantic memory MCP to find prior work, saved context, and related memories (MANDATORY)
- Before **complex multi-domain tasks**: ALWAYS ask user before parallel sub-agent dispatch (2+ domains triggers mandatory question)
- Before **spec folder creation**: Use workflows-spec-kit skill for template structure and sub-folder organization (if available)
- Before **conversation milestones**: workflows-memory auto-triggers every 20 messages for context preservation (if available)
- **If conflict exists**: Code quality standards override general practices

**Violation handling:** If proposed solution contradicts code quality standards, STOP and ask for clarification or revise approach.

#### ⚡ Common Failure Patterns (MANDATORY)

| #   | Pattern                | Trigger Phrase        | Response Action                |
| --- | ---------------------- | --------------------- | ------------------------------ |
| 1   | Task Misinterpretation | N/A                   | Parse request, confirm scope   |
| 2   | Rush to Code           | "straightforward"     | Analyze → Verify → Simplest    |
| 3   | Fabrication            | "obvious" w/o verify  | Output "UNKNOWN", verify first |
| 4   | Skip Verification      | "trivial edit"        | Run ALL tests, no exceptions   |
| 5   | Assumptions            | N/A                   | Read existing code first       |
| 6   | Cascading Breaks       | N/A                   | Reproduce before fixing        |
| 7   | Skip Process           | "I already know"      | Follow checklist anyway        |
| 8   | Over-Engineering       | N/A                   | YAGNI - solve only stated      |
| 9   | Clever > Clear         | N/A                   | Obvious code wins              |
| 10  | Retain Legacy          | "just in case"        | Remove unused, ask if unsure   |
| 11  | Skip Parallel Q        | 2+ domains            | Ask A/B/C before Task dispatch |
| 12  | No Browser Test        | "works", "done"       | Browser verify first           |
| 13  | Skip Checklist         | "complete" (L2+)      | Load checklist.md, verify all  |
| 14  | Skip Memory            | "research", "explore" | `memory_search()` FIRST        |

**Enforcement:** STOP → Acknowledge ("I was about to [pattern]") → Correct → Verify

#### ⚡ Skill Maintenance (MANDATORY - Platform Compatibility)

**CRITICAL:** Skills sync to both `.claude/skills/` and `.opencode/skills/`. Opencode does NOT support hooks.

When creating or editing skills:
- Check for hook references: `grep -E "hooks block|hook_interaction|\.claude/hooks/|Automatic.*via hooks" SKILL.md`
- Add Opencode notes: "In Claude Code, this runs automatically via hooks. In Opencode, follow manually."
- Replace misleading claims: "hooks block commits" → "verify before commits"
- See **Pitfall 6** in `create-documentation/references/skill_creation.md` for complete guidelines

---

## 2. 📝 MANDATORY: CONVERSATION DOCUMENTATION

Every conversation that modifies files (code, documentation, configuration, templates, skills, etc.) MUST have a spec folder. This applies to ALL conversations (SpecKit AND regular chat queries).
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
- **Optional Files:** None (baseline is complete)
- **Use When:** All features - this is the minimum documentation for any work
- **Enforcement:** Hard block if any required file missing

**Level 2: Verification Added** (LOC guidance: 100-499)
- **Required Files:** Level 1 + checklist.md
- **Optional Files:** None
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
- [x] P0: No console errors - Verified in Chrome DevTools
- [x] P1: Mobile responsive - Tested at 375px viewport
- [ ] P2: Documentation updated - Deferred (user approved)
```

#### Supporting Templates & Decision Rules
**All templates** (in `.opencode/speckit/templates/`):
- `spec.md` → Requirements and user stories (ALL levels)
- `plan.md` → Technical implementation plan (ALL levels)
- `tasks.md` → Task breakdown by user story (ALL levels)
- `checklist.md` → Validation/QA checklists (Level 2+)
- `decision-record.md` → Architecture Decision Records/ADRs (Level 3, prefix with topic)
- `research-spike.md` → Time-boxed research/PoC (Level 3 optional, prefix with topic)
- `research.md` → Comprehensive research documentation (Level 3 optional)
- `handover.md` → Session handover for continuity (utility, any level)
- `debug-delegation.md` → Debug task delegation to sub-agents (utility, any level)

**Decision rules:**
- **When in doubt → choose higher level** (better to over-document than under-document)
- **LOC thresholds are SOFT GUIDANCE** - use judgment based on complexity/risk
- **Risk/complexity can override LOC** (e.g., 50 LOC security change = Level 2+)
- **Multi-file changes often need higher level** than LOC alone suggests
- **Enforcement is HARD** - hooks block commits with missing required templates

### Spec Folder: `/specs/[###-short-name]/`
**Find next #**: `ls -d specs/[0-9]*/ | sed 's/.*\/\([0-9]*\)-.*/\1/' | sort -n | tail -1`
**Name format**: 2-3 words, lowercase, hyphens (e.g., `fix-typo`, `add-auth`, `mcp-code-mode`)
**Templates**: `.opencode/speckit/templates/` (see template list above)
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

### Enforcement Checkpoints
1. **Collaboration First Rule** - Create before presenting
2. **Request Analysis** - Determine level
3. **Pre-Code Checklist** - Verify exists (blocker)
4. **Final Review** - Confirm created
5. **Checklist Verification** - Complete all P0/P1 items before claiming done (Level 2+ only)
6. **Template Validation** (spec 122/014 improvements):
   - Placeholder removal (hard block: `[PLACEHOLDER]`, `[NEEDS CLARIFICATION: ...]`)
   - Template source validation (warn if missing template markers)
   - Metadata completeness (level-specific required fields)

**Note**: AI agent auto-creates folder. SpecKit users: `/spec_kit:complete` or `/spec_kit:plan` handle Level 3.

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
- **Optional (when fact-checking):** JSON block

```json
{
  "label": "TRUE | FALSE | UNKNOWN",
  "truth_score": 0.0-1.0,
  "uncertainty": 0.0-1.0,
  "citations": ["..."],
  "audit_hash": "sha256(...)"
}
```

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

#### Tool Selection

**Key Routing Rules:**
- **Code Mode (mcp-code-mode):** MANDATORY for external MCP tools (Webflow, Figma, ClickUp, Chrome DevTools) - 68% fewer tokens, 98.7% context reduction
- **Semantic Search (mcp-semantic-search):** MANDATORY for code discovery ("Find code that...", "How does..."). **Native MCP** - call directly: `mcp__semantic_search__semantic_search()`, `mcp__semantic_search__visit_other_project()` - NOT through Code Mode
- **Semantic Memory (mcp-semantic-memory):** MANDATORY for research, context recovery, finding prior work. **Native MCP** - call directly: `mcp__semantic_memory__memory_search()`, `mcp__semantic_memory__memory_load()` - NOT through Code Mode
- **Sequential Thinking (OPTIONAL):** Claude Code: use ultrathink instead; VSCode/Copilot/OpenCode: useful when configured - **Native MCP** - call directly, NOT through Code Mode
- **Parallel Sub-Agents (Task tool):** ALWAYS ask user when 2+ domains detected (mandatory question before dispatch)
- **Chrome DevTools (workflows-chrome-devtools):** Browser debugging via terminal (bdg CLI tool) - through Code Mode
- **Skills:** On-demand workflow orchestration for complex tasks (see Section 6)
- **Native Tools:** Read/Grep/Glob/Bash for file operations and simple tasks

### Tool Routing (Quick Decision)
```
Known file path? → Read()
Know what code DOES? → mcp__semantic_search__semantic_search() [NATIVE MCP - MANDATORY]
Research/prior work? → mcp__semantic_memory__memory_search() [NATIVE MCP - MANDATORY]
Exact symbol/keyword? → Grep()
File structure? → Glob()
Complex reasoning? → ultrathink (Claude Code) | process_thought() (Sequential Thinking MCP) (VSCode/OpenCode)
Browser debugging? → workflows-chrome-devtools skill [bdg CLI tool, through Code Mode]
External MCP tools? → call_tool_chain() [Code Mode - Webflow, Figma, ClickUp, etc.]
Multi-step workflow? → Skill() or openskills read [see Section 6]
2+ domains detected? → Ask user: parallel sub-agents or direct handling? (MANDATORY question)

NATIVE MCP (call directly - NEVER through Code Mode):
  ┌─ SEMANTIC SEARCH (code discovery):
  │   mcp__semantic_search__semantic_search()
  │   mcp__semantic_search__visit_other_project()
  │
  ├─ SEMANTIC MEMORY (context/research):
  │   mcp__semantic_memory__memory_search()
  │   mcp__semantic_memory__memory_load()
  │   mcp__semantic_memory__memory_match_triggers()
  │
  └─ SEQUENTIAL THINKING (optional):
      process_thought(), generate_summary()

CODE MODE (call_tool_chain):
  - Webflow, Figma, ClickUp, Chrome DevTools, etc.

SKILLS (Section 6):
  - Skill("skill-name") [Claude Code]
  - openskills read <skill-name> [Other agents]
```

**User Override Phrases:**
- `"proceed directly"` - Force direct handling
- `"use parallel agents"` - Force parallel dispatch
- `"auto-decide"` - Enable session auto-mode

**Example:** Auth + tests + docs = 3 domains (code + testing + docs) → ASK user before dispatch (mandatory question A/B/C)

#### The Iron Law (workflows-code)
**NO COMPLETION CLAIMS WITHOUT BROWSER VERIFICATION**
- Open actual browser before saying "works", "fixed", "done"
- Test Chrome + mobile viewport (375px) minimum
- Check DevTools console for errors
- See: workflows-code skill for full 3-phase lifecycle (if available)

#### Task Dispatch (Parallel Agent Logic)

**Complexity Formula:** domains(35%) + files(25%) + LOC(15%) + parallel(20%) + task_type(5%)

**Dispatch Rule:** 2+ domains → ALWAYS ask user (mandatory question A/B/C before Task tool dispatch)

| Domains | Action        | Reason             |
| ------- | ------------- | ------------------ |
| 1       | Handle direct | Single domain      |
| 2+      | Ask user      | MANDATORY question |

#### Project-Specific MCP Configuration

**Two MCP Configuration Systems**:

1. **Native MCP** (`.mcp.json` / `opencode.json`) - Direct tools, called natively
   - **Sequential Thinking**: Configured in `.mcp.json`, called via `process_thought()`, `generate_summary()` - NOT Code Mode
   - **Semantic Search**: Configured in `.mcp.json`, called via `semantic_search()`, `visit_other_project()` - NOT Code Mode
   - **Code Mode server**: The Code Mode tool itself (for accessing external tools)

2. **Code Mode MCP** (`.utcp_config.json`) - External tools accessed through Code Mode
   - **Config File**: `.utcp_config.json` (project root)
   - **External Tools**: Webflow, Figma, ClickUp, Chrome DevTools, etc.
   - **Invocation**: Through `call_tool_chain()` wrapper

**Critical Naming Convention** (Code Mode tools only):
All Code Mode tool calls follow the pattern: `{manual_name}.{manual_name}_{tool_name}`
- ✅ Correct: `webflow.webflow_sites_list({})`
- ❌ Wrong: `webflow.sites_list({})` (missing manual prefix)

**To Discover Available Code Mode Tools**:
- Use `search_tools()` to find tools by description
- Use `list_tools()` to see all available tools from active MCP servers
- Read `.utcp_config.json` to see which servers are configured and enabled

---

## 6. 🧩 SKILLS SYSTEM

Skills are specialized, on-demand capabilities that extend AI agents with domain expertise. Unlike hooks (automated triggers) or knowledge files (passive references), skills are explicitly invoked to handle complex, multi-step workflows.

### Skills vs Hooks vs Knowledge vs MCP Tools

| Type          | Purpose                           | Execution                                  | Examples                                 |
| ------------- | --------------------------------- | ------------------------------------------ | ---------------------------------------- |
| **Skills**    | Multi-step workflow orchestration | AI-invoked when needed                     | `workflows-code`, `create-documentation` |
| **Hooks**     | Automated quality checks          | System-triggered (before/after operations) | `enforce-spec-folder`, `validate-bash`   |
| **Knowledge** | Reference documentation           | Passive context during responses           | Code standards, MCP patterns             |
| **MCP Tools** | External integrations             | Direct API/protocol calls                  | Webflow, Figma, ClickUp, Semantic Search |

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
- **Claude Code**: `Skill("skill-name")` tool (native)
- **Other Agents**: `openskills read <skill-name>` CLI command

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
- Claude Code: Skill("skill-name") tool
- Other agents: Bash("openskills read <skill-name>")
- The skill content will load with detailed instructions on how to complete the task
- Base directory provided in output for resolving bundled resources (references/, scripts/, assets/)

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
<name>cli-codex</name>
<description>Wield OpenAI's Codex CLI as a powerful auxiliary tool for code generation, review, analysis, and parallel processing. Use when tasks benefit from a second AI perspective, alternative implementation approaches, or specialized code generation. Also use when user explicitly requests Codex operations.</description>
<location>project</location>
</skill>

<skill>
<name>cli-gemini</name>
<description>Wield Google's Gemini CLI as a powerful auxiliary tool for code generation, review, analysis, and web research. Use when tasks benefit from a second AI perspective, current web information via Google Search, codebase architecture analysis, or parallel code generation. Also use when user explicitly requests Gemini operations.</description>
<location>project</location>
</skill>

<skill>
<name>mcp-code-mode</name>
<description>MCP orchestration via TypeScript execution for efficient multi-tool workflows. Use Code Mode for ALL MCP tool calls (ClickUp, Figma, Webflow, Chrome DevTools, etc.). Provides 98.7% context reduction, 60% faster execution, and type-safe invocation. Mandatory for external tool integration.</description>
<location>project</location>
</skill>

<skill>
<name>mcp-semantic-search</name>
<description>Intent-based code discovery for CLI AI agents using semantic search MCP tools. Use when finding code by what it does (not what it's called), exploring unfamiliar areas, or understanding feature implementations. Mandatory for code discovery tasks when you have MCP access.</description>
<location>project</location>
</skill>

<skill>
<name>workflows-chrome-devtools</name>
<description>Direct Chrome DevTools Protocol access via browser-debugger-cli (bdg) terminal commands. Lightweight alternative to MCP servers for browser debugging, automation, and testing with significant token efficiency through self-documenting tool discovery (--list, --describe, --search).</description>
<location>project</location>
</skill>

<skill>
<name>workflows-code</name>
<description>Orchestrator guiding developers through implementation, debugging, and verification phases across specialized code quality skills (project)</description>
<location>project</location>
</skill>

<skill>
<name>workflows-git</name>
<description>Git workflow orchestrator guiding developers through workspace setup, clean commits, and work completion across git-worktrees, git-commit, and git-finish skills</description>
<location>project</location>
</skill>

<skill>
<name>workflows-memory</name>
<description>Saves expanded conversation context with full dialogue, decision rationale, visual flowcharts, and file changes. Auto-triggers on keywords or every 20 messages. Includes semantic vector search.</description>
<location>project</location>
</skill>

<skill>
<name>workflows-spec-kit</name>
<description>Mandatory spec folder workflow orchestrating documentation level selection (1-3), template selection, and folder creation for all file modifications through hook-assisted enforcement and context auto-save.</description>
<location>project</location>
</skill>

</available_skills>
<!-- SKILLS_TABLE_END -->

</skills_system>