##### DO NOT CHANGE THIS FILE UNLESS INSTRUCTED 😠

## 1. ⚠️ AI BEHAVIOR GUARDRAILS & ANTI-PATTERNS

### 🚨 MANDATORY RULES — Read These First

- **All file modifications require a spec folder** - code, documentation, configuration, templates, etc. (even non-SpecKit conversations)
- **Never lie or fabricate** - use "UNKNOWN" when uncertain, verify before claiming completion, follow process even for "trivial" changes
- **Clarify** if confidence < 80% or ambiguity exists; **propose options**
- **Use explicit uncertainty:** prefix claims with "I'M UNCERTAIN ABOUT THIS:" and output "UNKNOWN" when unverifiable
- **Prefer simplicity**, reuse existing patterns, and cite evidence with sources
- Solve only the stated problem; **avoid over-engineering** and premature optimization
- **Verify with checks** (simplicity, performance, maintainability, scope) before making changes
- **All MCP tool calls MUST go through code mode** - use `call_tool_chain` for efficient lazy-loaded MCP access (68% fewer tokens, 98.7% reduction in context overhead, 60% faster execution vs traditional tool calling) (if available) **EXCEPT** for native MCP tools (Sequential Thinking, Semantic Search)
- **CLI AI agents MUST use semantic search MCP** for code exploration/discovery - it's intent-based, not keyword matching (use grep/read for literal text). Call directly: `mcp__semantic_search__semantic_search()`, `mcp__semantic_search__visit_other_project()` - NOT through Code Mode
- **Semantic Memory MCP is MANDATORY** for research tasks, context recovery, and finding prior work. Call directly: `mcp__semantic_memory__memory_search()`, `mcp__semantic_memory__memory_load()`, `mcp__semantic_memory__memory_match_triggers()` - NOT through Code Mode
- **Sequential Thinking MCP** - OPTIONAL: Claude Code users use native ultrathink instead; VSCode/Copilot/OpenCode users can use when configured in `.mcp.json`

#### ⚡ Code Quality Standards Compliance

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

#### ⚡ Collaboration First
Before ANY code/file changes or terminal commands:

1. Determine documentation level (see Section 2)
2. **Ask user for spec folder confirmation** (MANDATORY)
   - Suggest spec number and options (A/B/C/D):
     - **A)** Use existing spec folder
     - **B)** Create new spec folder
     - **C)** Update related spec
     - **D)** Skip documentation
   - You MUST ask user to explicitly select option
   - NEVER decide autonomously or assume user preference
   - Wait for explicit user response before creating folder
3. Create spec folder based on user's explicit choice
4. Explain what you plan to do and why
5. Present your approach for review
6. Wait for explicit "go ahead" confirmation

**Exceptions**: Reading files for information and pure explanations allowed without permission
**Note**: Analysis tasks with issues/bugs/problems REQUIRE spec folder (analysis often leads to fixes)
**Critical**: No implementation without user approval AND spec folder creation

#### ⚡ Memory File Loading (After Spec Folder Selection)
When user selects Option A (Use existing spec folder) or Option C (Update related spec), and memory files exist:

1. **Interactive selection prompt** (DEFAULT BEHAVIOR)
   - Display numbered list of recent memories: `[1] [2] [3] [all] [skip]`
   - User chooses which context to load
   - `[skip]` continues without loading (instant, never blocks)
2. **Session preference phrases** (remembered for ~1 hour):
   - "auto-load memories" - Skip prompt, load most recent automatically
   - "fresh start" / "skip memory" - Skip all context loading this session
   - "ask about memories" - Revert to interactive selection (default)

> **Opencode Users:** Hooks are not supported in Opencode. Instead, manually run `/memory/search` before starting work in a spec folder. Feature parity: ~60% (commands work, automation requires manual steps).

#### ⚡ Git Workspace Choice (MANDATORY)

**NEVER autonomously decide between creating a branch or worktree.** Always ask user to choose:

When git workspace triggers are detected (new feature, create branch, worktree, fix bug, implement, etc.):
- **A)** Create a new branch - Standard branch on current repo
- **B)** Create a git worktree - Isolated workspace in separate directory
- **C)** Work on current branch - No new branch needed

**Enforcement**: `enforce-git-workspace-choice.sh` hook emits mandatory question. All tools blocked until user responds.

**Override phrases**: Users can bypass with "use branch", "use worktree", or "current branch"

**Session persistence**: Choice remembered for 1 hour within session

**Critical**: WAIT for explicit user choice before any git workspace operation. The workflows-git skill documents this requirement in detail.

#### ⚡ Parallel Sub-Agent Dispatch (MANDATORY QUESTION)

**ALWAYS ask users before dispatching parallel sub-agents.** Never dispatch autonomously.

**When to ask**: Task involves 2+ domains (code, docs, git, testing, devops, analysis)

**Use AskUserQuestion tool with these options:**
- **A)** Handle directly - Sequential execution, no parallel agents
- **B)** Use parallel agents - Dispatch specialized agents via Task tool for faster execution
- **C)** Auto-decide for session - Let system decide based on complexity (1 hour)

**Domain detection examples:**
- "implement feature and write tests" → 2 domains (code + testing) → ASK
- "refactor, update docs, and commit" → 3 domains (code + docs + git) → ASK
- "fix this bug" → 1 domain (code) → No question needed

**Override phrases**: Users can bypass with "proceed directly", "use parallel agents", or "auto-decide"

**Session persistence**: If user chose C, remember preference for 1 hour

**Critical**: WAIT for explicit user choice before dispatching parallel agents. Do NOT proceed with Task tool dispatch until user responds.

#### ⚡ Sequential Thinking (Complex Reasoning) - OPTIONAL

**Environment-Specific Utility:**
- **Claude Code**: NOT recommended - use native ultrathink instead (superior built-in reasoning)
- **VSCode/Copilot/OpenCode**: Useful - provides structured reasoning those environments lack

**5 Stages:** Problem Definition → Research → Analysis → Synthesis → Conclusion
**Tools:** `process_thought`, `generate_summary` (direct MCP calls, NOT through Code Mode)

#### ⚡ Clarification & Explicit Uncertainty

Ask clarifying questions when:
- Requirements or scope are ambiguous
- Confidence is below 80%
- Multiple reasonable interpretations exist

Pause and ask before proceeding. See Section 3 for confidence scoring and thresholds.

#### ⚡ Common Failure Patterns & Detection

**Quick Reference (14 Critical Patterns):**

**1. Task Misinterpretation**
- **Prevention:** Parse request carefully, confirm scope
- **Example:** Implementing when asked to investigate

**2. Rush to Code**
- **Prevention:** Analyze → Verify → Choose simplest approach
- **Example:** Starting code before understanding problem

**3. Fabrication/Lying**
- **Prevention:** Output "UNKNOWN" when uncertain, verify before claiming completion
- **Example:** Responding without verification, saying "tests pass" without running them
- **Detection Trigger:** "straightforward", "obvious" without verifying
- **Action:** Output "UNKNOWN" or verify first

**4. Skipping Verification**
- **Prevention:** Follow process even for "trivial" changes, run ALL tests
- **Example:** Skipping tests for "comment-only" changes
- **Detection Trigger:** "trivial edit", "just a comment"
- **Action:** Run ALL tests, no exceptions

**5. Assumption-Based Changes**
- **Prevention:** Read existing code first, verify evidence
- **Example:** "Fixing" working S3 upload unnecessarily

**6. Cascading Breaks**
- **Prevention:** Reproduce problem before fixing
- **Example:** Breaking code by "fixing" non-existent issues

**7. Skipping Process Steps**
- **Prevention:** Follow checklists consistently, no shortcuts
- **Example:** "I already know this, skip the checklist"
- **Detection Trigger:** "I already know this"
- **Action:** Follow checklist anyway

**8. Over-Engineering**
- **Prevention:** Solve ONLY stated problem, YAGNI principle
- **Example:** Complex state management vs simple variable

**9. Clever Over Clear**
- **Prevention:** Obvious code > clever tricks
- **Example:** One-liner regex vs readable string operations

**10. Retaining Legacy Code**
- **Prevention:** Remove unused code unless explicitly told otherwise
- **Example:** Keeping old code "just in case"
- **Detection Trigger:** "just in case", "don't change too much"
- **Action:** Remove unused code, ask if unsure

**11. Skipping Parallel Dispatch Question**
- **Prevention:** ALWAYS ask user before dispatching parallel sub-agents
- **Example:** Dispatching sub-agents without asking user first
- **Detection Trigger:** Task involves 2+ domains (code, docs, git, testing, devops, analysis)
- **Action:** Use AskUserQuestion tool with A/B/C options before any Task tool dispatch

**12. Claiming Without Browser Verification**
- **Prevention:** Browser test before completion claims (see workflows-code)
- **Example:** Saying "works" without opening browser

**13. Claiming Completion Without Checklist Verification (Level 2+)**
- **Prevention:** Use checklist.md to verify ALL items before any completion claims
- **Example:** Saying "done" or "complete" without loading and verifying checklist.md
- **Detection Trigger:** "done", "complete", "finished" without checklist verification
- **Action:** STOP → Load checklist.md → Verify each item → Mark [x] with evidence → Then claim done

**14. Skipping Semantic Memory on Research/Exploration Tasks**
- **Prevention:** ALWAYS use semantic memory MCP before research, exploration, or "read into" tasks
- **Example:** Using only Glob/Read/Grep for exploration when semantic memory has saved context
- **Detection Trigger:** "read into", "research", "explore", "find out about", "what do we have on", "prior work"
- **Action:** Call `mcp__semantic_memory__memory_search()` FIRST, then supplement with file reads
- **Tools:** `mcp__semantic_memory__memory_search()`, `mcp__semantic_memory__memory_load()`, `mcp__semantic_search__semantic_search()`

**Enforcement Protocol:** If you detect ANY pattern above:
1. **STOP** - Do not proceed
2. **Acknowledge** - "I was about to [pattern], which violates process discipline"
3. **Correct** - Follow proper procedure
4. **Verify** - Show evidence of correct process

**Detection Triggers:** "straightforward", "obvious", "trivial edit", "I already know", "skip checklist", "just in case", "done/complete/finished" (without checklist verification for Level 2+), "read into/research/explore" (without semantic memory search)

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

#### Checklist Self-Verification (Level 2+ Mandatory)

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
      └── memory/
  ```

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
Compute as weighted sum of factor scores (0–1), round to whole percent. Adjust weights based on project type.

```python
# ──────────────────────────────────────────────────────────────────────────────
# CONFIDENCE SCORING (Executable Logic)
# ──────────────────────────────────────────────────────────────────────────────
WEIGHTS = {
    "frontend": {"requirements_clarity": 25, "component_api": 15, "state_data_flow": 15, "type_safety": 10, "performance": 10, "accessibility": 10, "tooling": 10, "risk": 5},
    "backend": {"requirements_clarity": 25, "api_design": 20, "data_flow": 15, "security": 15, "performance": 10, "testing": 10, "risk": 5}
}

def calculate_confidence(domain: str, factor_scores: dict) -> int:
    """Calculate confidence (0-100%) as weighted sum. Factor scores: 0.0-1.0."""
    return round(sum(WEIGHTS[domain][f] * factor_scores.get(f, 0.0) for f in WEIGHTS[domain]))

def recommend_action(confidence: int) -> str:
    if confidence >= 80: return "proceed"
    elif confidence >= 40: return "proceed_with_caution"
    else: return "ask_clarification"
```

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

#### Phase 1: Initial Request Classification
```markdown
REQUEST CLASSIFICATION:
□ What is the actual request? [Restate in own words]
□ What is the desired outcome? [Be specific]
□ What is the scope? [Single change, feature, investigation]
□ What constraints exist? [Time, compatibility, dependencies]
□ DOCUMENTATION LEVEL: [Determine using Section 2 decision tree]
  - Does this involve file changes? [YES/NO]
  - If YES, what level? [1: Simple | 2: Standard | 3: Complete]
  - Spec folder to create: /specs/[###-short-name]/
```

#### Phase 2: Detailed Scope Analysis
```markdown
USER REQUEST: [Exact request in own words]

DOCUMENTATION SETUP:
- Documentation Level: [1/2/3 from decision tree]
- Spec Folder: /specs/[###-short-name]/
- Required Files: [List based on level]
- Template Adaptation: [Note any simplifications needed]

SCOPE DEFINITION:
- What IS included: [Specific deliverables]
- What is NOT included: [Out of scope items]
- What is uncertain: [Items needing clarification]

CURRENT STATE:
- ✅ What's working correctly
- ✅ What can be reused
- ❌ What's actually broken
- ❌ What needs to be added
```

#### Phase 3: Context Gathering & Evidence Collection
```markdown
CONTEXT GATHERING:
□ What files are mentioned or implied?
□ What existing patterns should be followed?
□ What documentation is relevant?
□ What dependencies or side effects exist?

REQUIREMENTS:
□ What is the MINIMUM needed to satisfy this request?
□ What would be over-engineering for this case?
□ What existing content can be reused or extended?
□ What approach is most maintainable?
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

#### Phase 5: Solution Effectiveness Validation
**Evaluate proposed approach against:**

```markdown
SIMPLICITY CHECK:
□ Is this the simplest solution that works?
□ Am I adding abstractions that aren't needed?
□ Could I solve this with less?
□ Am I following existing patterns or inventing new ones?

MAINTAINABILITY CHECK:
□ Does this follow established project patterns?
□ Will the next person understand this easily?
□ Is the content self-documenting?
□ Have I avoided clever tricks in favor of clarity?

SCOPE CHECK:
□ Am I solving ONLY the stated problem?
□ Am I avoiding feature creep?
□ Am I avoiding premature optimization?
□ Have I removed any gold-plating?
```

#### Phase 6: Pre-Change Verification
**Reality Check - Can I verify this works?**

Critical questions:
- ❓ Understand current implementation with evidence?
- ❓ Identified root cause (not symptoms)?
- ❓ Can trace flow end-to-end?
- ❓ Solution integrates cleanly?
- ❓ Considered relevant edge cases?
- ❓ Documented counter-evidence/caveats?

Include uncertainty statement and citations; mark "UNKNOWN" if insufficient.

**Counter-Evidence**: Note contradictions/limitations as "CAVEATS: [text]" or "CAVEATS: NONE FOUND"

**If multiple ❓ remain** → Read more content; if still <80% confidence, ask clarifying question

**Micro-loop for grounding and verification:**
```
Sense → Interpret → Verify → Reflect → Publish
- Sense: gather only relevant sources
- Interpret: break into atomic sub-claims
- Verify: check claims independently; label TRUE / FALSE / UNKNOWN
- Reflect: resolve conflicts; reduce entropy; shorten
- Publish: answer + uncertainty + citations
```

**⚠️ Anti-Fabrication:** If tempted to skip verification, claim "straightforward", or proceed despite uncertainty → See Section 1 Failure Patterns #3, #4, #7, #10. STOP and follow Enforcement Protocol.

**Pre-Change Checklist - Before making ANY file changes, verify:**

```markdown
□ I have parsed the request correctly (not assuming or extrapolating)
□ I have determined the documentation level (Section 2 decision tree)
□ I have created the spec folder: /specs/[###-short-name]/
□ I have created the required documentation files for the level
□ I understand which files need changes (read them first)
□ I know what success looks like (clear acceptance criteria)
□ I pass the Solution Effectiveness checks (simplicity, maintainability, scope)
□ If confidence < 80% or requirements are ambiguous: ask a clarifying question (see Section 3)
□ I can explain why this approach is optimal
□ I have cited sources for key claims or marked "UNKNOWN"
□ I ran a quick self-check for contradictions/inconsistencies
□ I avoided fabrication; missing info is labeled "UNKNOWN"
□ I have explained my approach and received explicit user approval
□ If Level 2+: Verified all checklist.md items and marked complete with evidence
```

**If ANY unchecked → STOP and analyze further**
**If no spec folder → STOP and create documentation first**
**If no user approval → STOP and present plan for review**

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
- **Chrome DevTools (cli-chrome-devtools):** Browser debugging via terminal (bdg CLI tool) - through Code Mode
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
Browser debugging? → cli-chrome-devtools skill [bdg CLI tool, through Code Mode]
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
  - Webflow, Figma, ClickUp, Chrome DevTools, Notion, etc.

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

```python
# ──────────────────────────────────────────────────────────────────────────────
# TASK DISPATCH (Parallel Agent Logic)
# ──────────────────────────────────────────────────────────────────────────────
COMPLEXITY_FORMULA = {"domains": 35, "files": 25, "loc": 15, "parallel": 20, "task_type": 5}

def calculate_complexity(task: dict) -> int:
    """Calculate complexity (0-100%). Args: {domains, files, loc, parallel_opportunity, complexity_rating}"""
    return round(
        COMPLEXITY_FORMULA["domains"] * _norm(task["domains"], "domains", max=5) +
        COMPLEXITY_FORMULA["files"] * _norm(task["files"], "files", max=10) +
        COMPLEXITY_FORMULA["loc"] * _norm(task["loc"], "loc", max=500) +
        COMPLEXITY_FORMULA["parallel"] * task["parallel_opportunity"] +
        COMPLEXITY_FORMULA["task_type"] * task["complexity_rating"]
    )

def _norm(val: int, cat: str, max: int) -> float:
    """Normalize value to 0.0-1.0."""
    return min(val / max, 1.0)

def dispatch_decision(domains: int) -> dict:
    """ALWAYS ask user when 2+ domains detected. Never dispatch autonomously."""
    if domains >= 2:
        return {"action": "ask_user", "reason": "2+ domains - MANDATORY question"}
    else:
        return {"action": "handle_direct", "reason": "single domain"}
```

#### Project-Specific MCP Configuration

**Two MCP Configuration Systems**:

1. **Native MCP** (`.mcp.json` / `opencode.json`) - Direct tools, called natively
   - **Sequential Thinking**:
     - Configured in `.mcp.json`, NOT in `.utcp_config.json`
     - ALWAYS called directly via `process_thought()`, `generate_summary()`
     - NEVER use Code Mode or `call_tool_chain()`
     - **Claude Code**: NOT recommended - use native ultrathink instead
     - **VSCode/Copilot/OpenCode**: Valuable - provides reasoning those environments lack
   - **Semantic Search**:
     - Configured in `.mcp.json`, NOT in `.utcp_config.json`
     - ALWAYS called directly via `semantic_search()`, `visit_other_project()`
     - NEVER use Code Mode or `call_tool_chain()`
     - **Why Native**: Reduces overhead, simpler invocation pattern
   - **Code Mode server**: The Code Mode tool itself (for accessing external tools)

2. **Code Mode MCP** (`.utcp_config.json`) - External tools accessed through Code Mode
   - **Config File**: `.utcp_config.json` (project root)
   - **Environment Variables**: `.env` (project root)
   - **External Tools**: Webflow, Figma, ClickUp, Chrome DevTools, Notion, etc.
   - **Invocation**: Through `call_tool_chain()` wrapper

**How to Check Available Code Mode Tools** (`.utcp_config.json`):
1. Read `.utcp_config.json` to see `manual_call_templates` array
2. Each object in the array defines an MCP server with:
   - `name`: The manual name (used for tool invocation)
   - `call_template_type`: Usually "mcp"
   - `config.mcpServers`: Server configuration details
   - `disabled`: If true, server is not active

**Critical Naming Convention** (Code Mode tools only):
All Code Mode tool calls follow the pattern: `{manual_name}.{manual_name}_{tool_name}`
- ✅ Correct: `webflow.webflow_sites_list({})`
- ❌ Wrong: `webflow.sites_list({})` (missing manual prefix)

**To Discover Available Code Mode Tools**:
- Use `search_tools()` to find tools by description
- Use `list_tools()` to see all available tools from active MCP servers
- Read `.utcp_config.json` to see which servers are configured and enabled
- **Note**: These methods only show Code Mode tools, NOT Sequential Thinking (which is in `.mcp.json`)

**Configuration Structure** (`.utcp_config.json` only):
```json
{
  "manual_call_templates": [
    {
      "name": "server_name",
      "call_template_type": "mcp",
      "config": {
        "mcpServers": {
          "server_name": {
            "transport": "stdio",
            "command": "command_to_run",
            "args": ["arg1", "arg2"],
            "env": {},
            "disabled": false  // if true, server is inactive
          }
        }
      }
    }
  ]
}
```

---

## 6. 🧩 SKILLS SYSTEM

Skills are specialized, on-demand capabilities that extend AI agents with domain expertise. Unlike hooks (automated triggers) or knowledge files (passive references), skills are explicitly invoked to handle complex, multi-step workflows.

### Skills vs Hooks vs Knowledge vs MCP Tools

| Type | Purpose | Execution | Examples |
|------|---------|-----------|----------|
| **Skills** | Multi-step workflow orchestration | AI-invoked when needed | `workflows-code`, `create-documentation` |
| **Hooks** | Automated quality checks | System-triggered (before/after operations) | `enforce-spec-folder`, `validate-bash` |
| **Knowledge** | Reference documentation | Passive context during responses | Code standards, MCP patterns |
| **MCP Tools** | External integrations | Direct API/protocol calls | Webflow, Figma, ClickUp, Semantic Search |

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
<name>cli-chrome-devtools</name>
<description>Direct Chrome DevTools Protocol access via browser-debugger-cli (bdg) terminal commands. Lightweight alternative to MCP servers for browser debugging, automation, and testing with significant token efficiency through self-documenting tool discovery (--list, --describe, --search).</description>
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
<name>create-documentation</name>
<description>Unified markdown and skill management specialist providing document quality enforcement (structure, c7score, style), content optimization for AI assistants, complete skill creation workflow (scaffolding, validation, packaging), and ASCII flowchart creation for visualizing complex workflows, user journeys, and decision trees.</description>
<location>project</location>
</skill>

<skill>
<name>mcp-code-mode</name>
<description>MCP orchestration via TypeScript execution for efficient multi-tool workflows. Use Code Mode for ALL MCP tool calls (ClickUp, Notion, Figma, Webflow, Chrome DevTools, etc.). Provides 98.7% context reduction, 60% faster execution, and type-safe invocation. Mandatory for external tool integration.</description>
<location>project</location>
</skill>

<skill>
<name>mcp-semantic-search</name>
<description>Intent-based code discovery for CLI AI agents using semantic search MCP tools. Use when finding code by what it does (not what it's called), exploring unfamiliar areas, or understanding feature implementations. Mandatory for code discovery tasks when you have MCP access.</description>
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

<!-- END AGENTS.md -->