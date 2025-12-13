---
description: Query Gemini CLI with Google Search grounding, codebase analysis, and SpecKit memory integration
argument-hint: "[query] [:review|:generate|:analyze|:research]"
allowed-tools: Bash, Read, Write, mcp__semantic_memory__memory_search, mcp__semantic_memory__memory_load
---

# 🚨 MANDATORY GATES - BLOCKING ENFORCEMENT

**These gates MUST be passed sequentially. Each gate BLOCKS until complete.**

---

## 🔒 GATE 0: Query Input Validation

**STATUS: ☐ BLOCKED**

```
EXECUTE THIS CHECK FIRST:

├─ IF $ARGUMENTS is empty, undefined, or whitespace-only:
│   │
│   ├─ ASK user: "What would you like Gemini to help with?"
│   │   options:
│   │     - label: "Code review"
│   │       description: "Review code for bugs, security, improvements"
│   │     - label: "Code generation"
│   │       description: "Generate new code or features"
│   │     - label: "Architecture analysis"
│   │       description: "Analyze codebase using codebase_investigator"
│   │     - label: "Web research"
│   │       description: "Search web for current info (Google Search)"
│   ├─ WAIT for user response (DO NOT PROCEED)
│   ├─ Then ask for the specific query details
│   ├─ Store response as: query
│   └─ SET STATUS: ✅ PASSED
│
└─ IF $ARGUMENTS contains content:
    ├─ Store as: query
    └─ SET STATUS: ✅ PASSED

⛔ HARD STOP: DO NOT read past this gate until STATUS = ✅ PASSED
⛔ NEVER infer query from context, screenshots, or conversation history
```

**Gate 0 Output:** `query = ________________`

---

## 🔒 GATE 1: Spec Folder Selection

**STATUS: ☐ BLOCKED**

```
EXECUTE AFTER GATE 0 PASSES:

1. Check for active spec:
   $ cat .spec-active 2>/dev/null

2. Search for related spec folders:
   $ ls -d specs/*/ 2>/dev/null | tail -10

3. ASK user with these EXACT options:
   ┌────────────────────────────────────────────────────────────┐
   │ "Which spec folder should this query be associated with?"  │
   │                                                            │
   │ A) Use active spec: [show .spec-active if exists]          │
   │ B) Use existing spec folder: [list recent folders]         │
   │ C) Create new spec folder: specs/[###]-[query-slug]/       │
   │ D) Quick mode (no spec tracking - use /cli:gemini_quick)   │
   └────────────────────────────────────────────────────────────┘

4. WAIT for explicit user choice (A, B, C, or D)

5. IF user chooses D:
   └─► Redirect: "For quick queries without spec tracking, use /cli:gemini_quick"
   └─► EXIT this command

6. Store results:
   - spec_choice = [A/B/C]
   - spec_path = [path]

7. SET STATUS: ✅ PASSED

⛔ HARD STOP: DO NOT proceed until user explicitly selects
```

**Gate 1 Output:** `spec_choice = ___` | `spec_path = ________________`

---

## 🔒 GATE 2: Memory Context Loading

**STATUS: ☐ BLOCKED**

```
EXECUTE AFTER GATE 1 PASSES:

CHECK spec_choice value:

├─ IF spec_choice == C (Create new):
│   ├─ Create the spec folder
│   └─ SET STATUS: ✅ PASSED (new folder has no memory)
│
└─ IF spec_choice == A or B (Use existing):
    │
    ├─ Check: Does spec_path/memory/ exist AND contain files?
    │
    ├─ IF memory/ is empty or missing:
    │   └─ SET STATUS: ✅ PASSED (no memory to load)
    │
    └─ IF memory/ has files:
        │
        ├─ Search for related memories:
        │   mcp__semantic_memory__memory_search({
        │     query: "<keywords from user query>",
        │     specFolder: "<spec_path>",
        │     limit: 3
        │   })
        │
        ├─ IF relevant memories found (>50% match):
        │   ├─ Load top match automatically
        │   ├─ Display: "Loaded context from: [memory_file]"
        │   └─ SET STATUS: ✅ PASSED
        │
        └─ IF no relevant memories:
            └─ SET STATUS: ✅ PASSED

⛔ HARD STOP: DO NOT proceed until STATUS = ✅ PASSED
```

**Gate 2 Output:** `memory_loaded = [yes/no]` | `context_file = ________________`

---

## ✅ GATE STATUS VERIFICATION

**Before continuing to the workflow, verify ALL gates:**

| Gate                | Required Status | Your Status | Output Value              |
| ------------------- | --------------- | ----------- | ------------------------- |
| GATE 0: Query       | ✅ PASSED        | ______      | query: ______             |
| GATE 1: Spec Folder | ✅ PASSED        | ______      | spec_path: ______         |
| GATE 2: Memory      | ✅ PASSED        | ______      | memory_loaded: ______     |

---

# Gemini Query

Query Google's Gemini CLI with Google Search grounding, codebase analysis, and mandatory SpecKit integration.

---

## 1. 📋 ARGUMENT DISPATCH

```
$ARGUMENTS
    │
    ├─► Contains modifier (:review, :generate, :analyze, :research)
    │   └─► Use specified type, extract remaining text as query
    │
    ├─► Natural language (no modifier)
    │   └─► AUTO-DETECT type from keywords:
    │       ├─► "review|audit|security|bugs|check"     → REVIEW
    │       ├─► "create|generate|implement|build|add"  → GENERATE
    │       ├─► "analyze|architecture|structure|deps"  → ANALYZE
    │       ├─► "latest|current|search|what is|docs"   → RESEARCH
    │       └─► No match                               → Ask user
    │
    └─► Ambiguous single word
        └─► Ask user to specify type
```

---

## 2. 📝 CONTRACT

**Inputs:** `$ARGUMENTS` — Query text with optional `:type` modifier
**Outputs:** `STATUS=OK|FAIL TYPE=<type> SPEC=<path>`

---

## 3. ⚡ INSTRUCTIONS

### Step 1: Verify CLI

```bash
command -v gemini && echo "OK" || echo "NOT FOUND"
```

If not found: `STATUS=FAIL ERROR="Gemini CLI not installed"`

### Step 2: Parse Query Type

| Type | Modifier | Gemini Tool | Use Case |
|------|----------|-------------|----------|
| Review | `:review` | — | Security audit, bug hunting |
| Generate | `:generate` | — | Create new code |
| Analyze | `:analyze` | codebase_investigator | Architecture analysis |
| Research | `:research` | google_web_search | Current web info |

### Step 3: Execute Query

**Standard execution:**
```bash
gemini "{query}" --yolo -o text 2>&1
```

**For simpler tasks (faster):**
```bash
gemini "{query}" -m gemini-2.5-flash --yolo -o text 2>&1
```

**Key flags:**
- `--yolo` or `-y`: Auto-approve all tool calls
- `-o text`: Human-readable output
- `-m gemini-2.5-flash`: Faster model for simple tasks

### Step 4: Process Response

1. Parse output from Gemini CLI
2. Extract key findings
3. Validate for security issues in generated code
4. Format and display to user

---

## 4. 💾 MEMORY SAVE (MANDATORY)

**After displaying the Gemini response, ALWAYS save to memory:**

```
SAVE to {spec_path}/memory/{timestamp}__gemini-{type}.md:

1. Generate memory file with:
   - Original query as trigger phrase
   - Full Gemini response
   - Extracted key findings
   - Source URLs (for research queries)

2. Update .spec-active marker (if changed)

3. Confirm: "Saved to: {spec_path}/memory/{filename}"
```

**Memory File Format:**
```markdown
---
title: Gemini {Type} Query
date: {DD-MM-YY}_{HH-MM}
type: gemini-query
triggers: ["{original query keywords}"]
spec_folder: {spec_path}
---

## Query
{original_query}

## Type
{query_type} (Tool: {gemini_tool})

## Response
{gemini_response}

## Key Findings
{extracted_findings}

## Sources (if research)
{source_urls}
```

---

## 5. 🔍 EXAMPLE USAGE

**With type modifier:**
```bash
/cli:gemini Review auth.ts for security issues :review
/cli:gemini Create a React dark mode hook :generate
/cli:gemini What are the latest Next.js 15 features? :research
```

**Auto-detected type:**
```bash
/cli:gemini Analyze the authentication architecture
# → Auto-detects as ANALYZE, uses codebase_investigator

/cli:gemini What is React Server Components?
# → Auto-detects as RESEARCH, uses google_web_search
```

**Interactive (no args):**
```bash
/cli:gemini
# → Prompts for query, spec folder, then executes
```

---

## 6. 📊 OUTPUT FORMAT

```
┌─────────────────────────────────────────────────────────────┐
│  Gemini Query                                               │
├─────────────────────────────────────────────────────────────┤
│  Type: Research                                             │
│  Tool: google_web_search                                    │
│  Spec: specs/045-nextjs-upgrade                             │
│  Context: Loaded from 11-12-25_09-30__gemini-research.md    │
└─────────────────────────────────────────────────────────────┘

Response:
  Next.js 15 Key Features (Released October 2024):

  1. Turbopack stable for dev server
  2. Partial Prerendering (PPR) stable
  3. React 19 support
  4. Enhanced caching controls

  Sources: nextjs.org, Vercel blog

───────────────────────────────────────────────────────────────
Saved to: specs/045-nextjs-upgrade/memory/11-12-25_14-30__gemini-research.md

STATUS=OK TYPE=research SPEC=specs/045-nextjs-upgrade
```

---

## 7. ⚠️ ERROR HANDLING

| Error | Detection | Action |
|-------|-----------|--------|
| CLI not found | `command -v` fails | Show install: github.com/google-gemini/gemini-cli |
| Auth error | "auth" in output | Guide to re-authenticate |
| Rate limit (60/min) | "rate limit" in output | CLI auto-retries |
| Rate limit (1000/day) | "daily" in output | Inform user to wait |
| Timeout | >120s | Cancel, suggest simpler query |
| Spec folder invalid | Path doesn't exist | Return to GATE 1 |

---

## 8. 📌 NOTES

- **Google Search**: Unique capability for real-time web information
- **codebase_investigator**: Deep architecture analysis tool
- **Rate Limits**: 60 req/min, 1000/day (free tier)
- **Forceful Language**: Include "Execute immediately" to prevent planning prompts
- **Validation**: Always review generated code before using
- **SpecKit Required**: All queries tracked in spec folders
- **Quick Mode**: Use `/cli:gemini_quick` for untracked queries

---

## 9. 🔗 RELATED COMMANDS

- `/cli:gemini_quick` — Fast execution, no spec tracking
- `/cli:codex` — Codex with deep reasoning + spec tracking
- `/memory/save` — Manual context save
- `/memory/search` — Search saved memories
- `/spec_kit:complete` — Full SpecKit workflow
