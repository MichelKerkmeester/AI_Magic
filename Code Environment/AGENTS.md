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
- **All MCP tool calls MUST go through code mode** - use `call_tool_chain` for efficient lazy-loaded MCP access (68% fewer tokens, 98.7% reduction in context overhead, 60% faster execution vs traditional tool calling) (if available)
- **CLI AI agents MUST use semantic search MCP** for code exploration/discovery - it's intent-based, not keyword matching (use grep/read for literal text)
- **Sequential Thinking MCP** - OPTIONAL: Claude Code users use native ultrathink instead; VSCode/Copilot/OpenCode users can use when configured in `.mcp.json`

#### ⚡ Code Quality Standards Compliance

**MANDATORY:** Compliance checkpoints:
- Before **proposing solutions**: Verify approach aligns with code quality standards and webflow patterns (if available in project skills)
- Before **writing documentation**: Use create-documentation skill for structure/style enforcement (if available)
- Before **initialization code**: Follow initialization patterns from code quality standards (if available)
- Before **animation implementation**: See animation workflow references (if available)
- Before **searching codebase**: Use mcp-semantic-search skill for intent-based code discovery (if available)
- Before **complex multi-domain tasks**: Consider create-parallel-sub-agents skill for orchestration (≥20% complexity + ≥2 domains triggers mandatory question; ≥50% + ≥3 domains auto-dispatch)
- Before **spec folder creation**: Use workflows-spec-kit skill for template structure and sub-folder organization (if available)
- Before **conversation milestones**: workflows-save-context auto-triggers every 20 messages for context preservation (if available)
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

**Exceptions**: Analysis, reading files, and explanations allowed without permission
**Critical**: No implementation without user approval AND spec folder creation

#### ⚡ Memory File Loading (Mid-Conversation)
When continuing work in an existing spec folder with memory files, ask user:
- **A)** Load most recent memory file
- **B)** Load all recent files (up to 3)
- **C)** List all files and select specific
- **D)** Skip (start fresh)

Use Read tool (parallel calls for option B) to load selected files.

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

Pause and ask before proceeding.

**Truth Standards:**
- Prefix uncertain claims with: "I'M UNCERTAIN ABOUT THIS:"
- Output "UNKNOWN" when information is insufficient or unverifiable
- Never fabricate plausible-sounding details or invent details
- State confidence levels as percentages
- Meaning preservation and coherence are priority one

Example: `I'M UNCERTAIN ABOUT THIS: The endpoint may require auth scope "read:forms".`

**Enforcement Rules:**
- If uncertain or unverifiable → output "UNKNOWN" explicitly (no guessing)
- Fast wrong answers waste more time than admitting limitations
- Users make critical decisions based on your output - accuracy > speed
- Preserve truth even when it means saying "I don't know"

#### ⚡ Common Failure Patterns & Detection

**Quick Reference (12 Critical Patterns):**

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

**11. Skipping Complexity Check**
- **Prevention:** Calculate score before dispatch (see create-parallel-sub-agents)
- **Example:** Dispatching sub-agents for single-file changes
- **Detection Trigger:** Multi-domain task (≥2 domains) + complexity ≥35%
- **Action:** Use Task tool with sub-agents

**12. Claiming Without Browser Verification**
- **Prevention:** Browser test before completion claims (see workflows-code)
- **Example:** Saying "works" without opening browser

**Enforcement Protocol:** If you detect ANY pattern above:
1. **STOP** - Do not proceed
2. **Acknowledge** - "I was about to [pattern], which violates process discipline"
3. **Correct** - Follow proper procedure
4. **Verify** - Show evidence of correct process

**Detection Triggers:** "straightforward", "obvious", "trivial edit", "I already know", "skip checklist", "just in case"

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

#### Documentation Levels Overview

**Level 1: Trivial to Simple Changes** (<100 LOC)
- **Core Files:** spec.md
- **Optional Files:** checklist.md
- **Use When:** Small bug fixes, config tweaks, minor updates

**Level 2: Moderate Features** (<500 LOC)
- **Core Files:** spec.md + plan.md
- **Optional Files:** tasks.md, checklist.md
- **Use When:** New features, refactors, multi-file changes

**Level 3: Complex Features** (≥500 LOC)
- **Core Files:** spec.md + plan.md + tasks.md
- **Optional Files:** research-spike-*.md, decision-record-*.md
- **Use When:** Large features, architecture changes, system redesigns

#### Supporting Templates & Decision Rules
**Optional templates** (in `.opencode/speckit/templates/`):
- `tasks.md` - Break plan into actionable tasks (create after plan.md, before coding)
- `checklist.md` - Validation/QA checklists (when systematic validation needed)
- `research.md` - Comprehensive feature research documentation (for deep technical investigation spanning multiple areas before implementation; use before research-spike for larger research efforts)
- `research-spike.md` - Research/proof-of-concept work (time-boxed experimentation to answer specific technical questions or validate approaches, prefix with topic)
- `decision-record.md` - Architecture Decision Records/ADRs (major technical decisions, prefix with topic)

**Decision rules:**
- **When in doubt → choose higher level** (better to over-document than under-document)
- **Complexity/risk can override LOC** (e.g., 50 LOC config cascade = Level 2)
- **Multi-file changes often need higher level** than LOC alone suggests
- **Secondary factors:** Risk, dependencies, testing needs, architectural impact

```python
# ──────────────────────────────────────────────────────────────────────────────
# DOCUMENTATION LEVEL DETECTION (Executable Logic)
**Level Selection**:
- <100 LOC → Level 1 | Core: spec.md
- <500 LOC → Level 2 | Core: spec.md, plan.md
- ≥500 LOC → Level 3 | Core: spec.md, plan.md, tasks.md
- **Overrides**: High risk OR arch impact OR >5 files OR dependencies → Level 3
- **Rule**: When in doubt → choose higher level
```

### Spec Folder: `/specs/[###-short-name]/`
**Find next #**: `ls -d specs/[0-9]*/ | sed 's/.*\/\([0-9]*\)-.*/\1/' | sort -n | tail -1`
**Name format**: 2-3 words, lowercase, hyphens (e.g., `fix-typo`, `add-auth`, `mcp-code-mode`)
**Templates**: `.opencode/speckit/templates/` - Copy these files:
  - `spec.md` → Core requirements
  - `plan.md` → Implementation plan
  - `tasks.md` → Task breakdown
  - `checklist.md` → Validation checklist
  - `research.md` → Research documentation
  - `research-spike.md` → Research spike (prefix with topic)
  - `decision-record.md` → Decision records (prefix with topic)
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

**Memory File Selection & Context Loading:**

When continuing work in an existing spec folder (mid-conversation with substantial content), previous session memory files may be available for loading. The system shows up to 3 recent memory files with relative timestamps and offers 4 options:

- **A)** Load most recent file (quick context refresh)
- **B)** Load all recent files (comprehensive context)
- **C)** List all files and select specific (historical search)
- **D)** Skip (start fresh, no context)

**AI must ask user to choose A/B/C/D explicitly, then use Read tool** to load selected memory files. This seamless context restoration prevents re-asking questions and maintains conversation continuity across sessions. Memory directory is determined by `.spec-active.{SESSION_ID}` marker (V9: session-isolated, sub-folder aware).

### Enforcement Checkpoints
1. **Collaboration First Rule** - Create before presenting
2. **Request Analysis** - Determine level
3. **Pre-Code Checklist** - Verify exists (blocker)
4. **Final Review** - Confirm created
5. **Template Validation** (spec 122/014 improvements):
   - Placeholder removal (hard block: `[PLACEHOLDER]`, `[NEEDS CLARIFICATION: ...]`)
   - Template source validation (warn if missing template markers)
   - Metadata completeness (level-specific required fields)
   - Sub-folder organization (README template suggestions)

**Note**: AI agent auto-creates folder. SpecKit users: `/spec_kit:complete` or `/spec_kit:plan` handle Level 3.

---

## 3. 🧑‍🏫 CONFIDENCE & CLARIFICATION FRAMEWORK

**Core Principle:** If confidence < 80%, pause and ask for clarification with multiple-choice options.

### Thresholds & Actions
- **80–100% (HIGH):** Proceed with citable source or strong evidence
- **40–79% (MEDIUM):** Proceed with caution + caveats
- **0–39% (LOW):** Ask clarifying question or mark "UNKNOWN"

### When to Ask
- Ambiguous requirements
- Confidence < 80%
- Multiple valid interpretations
- Blockers beyond your control

### Response Format
**Required:**
- Cite sources (file paths/lines) OR mark "UNKNOWN"
- State confidence level if uncertain
- Provide counter-evidence/caveats when relevant

**Clarification Question Format:**
```
I need clarity (confidence: NN%). Which approach:
- A) [option + brief rationale]
- B) [option + brief rationale]
- C) [option + brief rationale]
```

---

## 4. 🧠 REQUEST ANALYSIS & SOLUTION FRAMEWORK

**Before ANY action or file changes:**

### Core Workflow (3 Phases)

**1. UNDERSTAND & SCOPE**
- What is actually requested? (Restate in own words)
- Request type: feature | bug | refactor | investigate
- Scope: What's the MINIMUM needed?
- Documentation level (Section 2): 1 | 2 | 3
- Spec folder: `/specs/###-short-name/`

**2. DESIGN & VALIDATE**
- **Simplicity**: Use existing patterns, avoid abstractions
- **Evidence**: Cite sources or mark "UNKNOWN"
- **Effectiveness**: Performant + Maintainable + Clear
- Checks: Simplicity | Performance | Maintainability | Scope
- **Anti-patterns**: Check Section 1 (lines 107-170)
- **Confidence**: If <80%, ask clarifying question (Section 3)

**3. PRE-CHANGE CHECKLIST** (Before ANY file changes)
```markdown
□ Spec folder created (if required)
□ Request parsed correctly (not assuming)
□ Files identified (read them first)
□ Simplest solution that works
□ Confidence ≥80% OR asked clarifying question
□ Cited sources OR marked "UNKNOWN"
□ User approval received
```

**STOP if any unchecked** → Analyze further, create spec folder, or ask questions

---

## 5. 🏎️ TOOL SELECTION & ROUTING

#### Tool Selection

**Key Routing Rules:**
- **Code Mode (mcp-code-mode):** MANDATORY for all MCP tools except Sequential Thinking (68% fewer tokens, 98.7% context reduction)
- **Semantic Search (mcp-semantic-search):** MANDATORY for CLI AI agents doing code discovery ("Find code that...", "How does...")
- **Sequential Thinking (OPTIONAL):** Claude Code: use ultrathink instead; VSCode/Copilot/OpenCode: useful when configured - call MCP directly, NOT through Code Mode
- **Parallel Sub-Agents (create-parallel-sub-agents):** MANDATORY when complexity ≥20% + 2+ domains (auto-dispatch ≥50% + 3+ domains)
- **Chrome DevTools (cli-chrome-devtools):** Browser debugging via terminal (bdg CLI tool)
- **Native Tools:** Read/Grep/Glob/Bash for file operations and simple tasks

See executable routing logic below and Quick Decision tree in Section 6.

```python
# ──────────────────────────────────────────────────────────────────────────────
# TOOL ROUTING (Executable Logic)
# ──────────────────────────────────────────────────────────────────────────────
TOOLS = {
    "read": {"triggers": ["known_file_path"], "use": "Specific file access"},
    "grep": {"triggers": ["exact_symbol", "keyword"], "use": "Literal text search"},
    "glob": {"triggers": ["file_pattern"], "use": "File discovery by pattern"},
    "bash": {"triggers": ["terminal_op"], "use": "System commands"},

    # SEMANTIC SEARCH - PRIORITY ROUTING (MANDATORY for code exploration)
    "semantic_search": {
        "triggers": [
            "find code that", "how does", "where do we", "where is",
            "what handles", "show me how", "locate", "which component",
            "what implements", "find all", "what depends", "find similar",
            "explore", "discover", "understand how"
        ],
        "mandatory_for": "cli_ai_agents",
        "priority": "FIRST for code exploration",
        "use_cases": [
            "Exploring unfamiliar code",
            "Finding by behavior/intent (not symbol name)",
            "Understanding patterns and relationships",
            "Discovering cross-file dependencies"
        ],
        "do_not_use_for": [
            "Known exact file paths (use Read)",
            "Specific symbol searches (use Grep)",
            "File structure exploration (use Glob)"
        ]
    },

    "sequential_thinking": {"triggers": ["complex reasoning", "architecture_decision"], "exception": "call_directly_not_code_mode", "availability": "optional_mcp_server"},
    "code_mode": {"triggers": ["ANY MCP except Sequential"], "mandatory": True, "benefits": "68% fewer tokens"},
    "chrome_devtools": {"triggers": ["bdg", "browser debugging"], "tool": "browser-debugger-cli"},
    "parallel_agents": {"triggers": ["complexity >= 20%", "multi_domain"], "thresholds": {"auto": 50, "ask": 20, "direct": 0}}
}

def route_tool(intent: str, file_known: bool = False, is_cli: bool = True, complexity: int = 0) -> str:
    """Route to most appropriate tool with semantic search priority."""

    # PRIORITY 1: Check semantic search FIRST for code exploration (MANDATORY)
    if is_cli and _is_code_exploration(intent):
        if _semantic_search_available():
            return "semantic_search"  # MANDATORY when available
        else:
            # Fallback to grep with warning
            log_warning("Semantic search recommended but unavailable - using grep fallback")
            return "grep"

    # PRIORITY 2: Mandatory routing (existing)
    if complexity >= 20 and _is_multi_domain(intent): return "parallel_agents"
    if _is_external_mcp(intent) and "reasoning" not in intent: return "code_mode"

    # PRIORITY 3: Intent-based (existing patterns)
    if any(t in intent.lower() for t in ["analyze", "design decision"]): return "sequential_thinking"
    if any(t in intent.lower() for t in ["bdg", "browser debug"]): return "chrome_devtools"

    # PRIORITY 4: File operations (only if NOT code exploration)
    if file_known: return "read"
    if "pattern" in intent.lower(): return "glob"
    if "keyword" in intent.lower(): return "grep"
    return "bash"

def _is_code_exploration(intent: str) -> bool:
    """Detect if intent is code exploration (not known file access)."""
    # Expanded patterns from mcp-semantic-search skill (14 triggers)
    exploration_patterns = [
        "find code that", "how does", "where do we", "where is",
        "what handles", "show me how", "locate", "which component",
        "what implements", "find all", "what depends", "find similar",
        "explore", "discover", "understand how"
    ]
    return any(p in intent.lower() for p in exploration_patterns)

def _semantic_search_available() -> bool:
    """Check if semantic search MCP server is available."""
    import os
    # Check for vector database (indicates semantic search is indexed)
    return os.path.exists(".codebase/vectors.db")

def _is_multi_domain(intent: str) -> bool:
    return sum(d in intent.lower() for d in ["code", "docs", "git", "testing", "devops"]) >= 2

def _is_external_mcp(intent: str) -> bool:
    return any(t in intent.lower() for t in ["figma", "webflow", "notion", "clickup"])
```

#### Project-Specific MCP Configuration

**Two MCP Configuration Systems**:

1. **Native MCP** (`.mcp.json`) - Direct tools, called natively
   - **Sequential Thinking**:
     - Configured in `.mcp.json`, NOT in `.utcp_config.json`
     - ALWAYS called directly via `process_thought()`, `generate_summary()`
     - NEVER use Code Mode or `call_tool_chain()`
     - **Claude Code**: NOT recommended - use native ultrathink instead
     - **VSCode/Copilot/OpenCode**: Valuable - provides reasoning those environments lack
   - **Code Mode server**: The Code Mode tool itself

2. **Code Mode MCP** (`.utcp_config.json`) - External tools accessed through Code Mode
   - **Config File**: `.utcp_config.json` (project root)
   - **Environment Variables**: `.env` (project root)
   - **Vector Database**: `.codebase/vectors.db` (for semantic search if configured)
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

## 6. 🎯 SKILL ACTIVATION QUICK REFERENCE

**workflows-spec-kit**
- **Trigger:** Any file modification
- **Reference:** Section 2

**workflows-save-context**
- **Trigger:** Every 20 messages, "save context"
- **Reference:** Auto-triggered

**workflows-planning**
- **Trigger:** Complex planning, parallel exploration, verified plan
- **Reference:** Auto-invoked by spec_kit:plan at step_6_planning

**workflows-code**
- **Trigger:** Frontend code changes
- **Reference:** Section 5, Tool #1 (if available)

**mcp-semantic-search**
- **Trigger:** "Find code that...", "How does..."
- **Reference:** Section 5, Tool #4 (if available)

**mcp-code-mode**
- **Trigger:** ANY MCP tool call (except Sequential Thinking)
- **Reference:** Section 5, Tool #3 (if available)

**cli-chrome-devtools**
- **Trigger:** "bdg", "browser debugging", Chrome DevTools CLI
- **Reference:** Section 5, Tool #5 (if available)

**create-parallel-sub-agents**
- **Trigger:** Complexity ≥20% + 2+ domains (mandatory question)
- **Reference:** Available as skill in some environments

**create-documentation**
- **Trigger:** Creating/editing docs or skills
- **Reference:** Available as skill in some environments

#### The Iron Law (workflows-code)
**NO COMPLETION CLAIMS WITHOUT BROWSER VERIFICATION**
- Open actual browser before saying "works", "fixed", "done"
- Test Chrome + mobile viewport (375px) minimum
- Check DevTools console for errors
- See: workflows-code skill for full 3-phase lifecycle (if available)

```python
# ──────────────────────────────────────────────────────────────────────────────
# SKILL DISPATCH (Executable Logic)
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

def dispatch_decision(complexity: int, domains: int) -> dict:
    if complexity >= 50 and domains >= 3:
        return {"action": "auto_dispatch", "reason": "≥50% + 3+ domains"}
    elif complexity >= 20 and domains >= 2:
        return {"action": "ask_user", "reason": "20-49% + 2+ domains"}
    else:
        return {"action": "handle_direct", "reason": "<20%"}
```

#### Tool Routing (Quick Decision)
```
Known file path? → Read()
Know what code DOES? → search_codebase() [semantic search - CLI only]
Exact symbol/keyword? → Grep()
File structure? → Glob()
Complex reasoning? → ultrathink (Claude Code) | process_thought() (VSCode/Copilot/OpenCode if configured)
Browser debugging? → cli-chrome-devtools skill [bdg CLI tool]
External MCP tools? → call_tool_chain() [Code Mode - MANDATORY except Sequential]
Complexity ≥20% + multi-domain? → See dispatch_decision() function in Section 6
```

**User Override Phrases:**
- `"proceed directly"` - Force direct handling
- `"use parallel agents"` - Force parallel dispatch
- `"auto-decide"` - Enable session auto-mode

**Example:** Auth + tests + docs = 3 domains (35%) + 8 files (25%) + 300 LOC (15%) + high parallel (20%) + complex (5%) = **100%** → AUTO-DISPATCH (≥50% + 3 domains threshold met, notification only, no question asked)