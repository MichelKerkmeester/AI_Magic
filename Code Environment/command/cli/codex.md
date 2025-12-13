---
description: Query Codex CLI with deep reasoning, structured prompts, and SpecKit memory integration
argument-hint: "[query] [:review|:generate|:analyze|:explain|:debug|:refactor]"
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
│   ├─ ASK user: "What would you like Codex to help with?"
│   │   options:
│   │     - label: "Code review"
│   │       description: "Review code for bugs, security, improvements"
│   │     - label: "Code generation"
│   │       description: "Generate new code or features"
│   │     - label: "Architecture analysis"
│   │       description: "Analyze patterns and dependencies"
│   │     - label: "Code explanation"
│   │       description: "Explain complex code or algorithms"
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
   │ D) Quick mode (no spec tracking - use /cli:codex_quick)    │
   └────────────────────────────────────────────────────────────┘

4. WAIT for explicit user choice (A, B, C, or D)

5. IF user chooses D:
   └─► Redirect: "For quick queries without spec tracking, use /cli:codex_quick"
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

# Codex Query

Query OpenAI's Codex CLI with structured prompts, deep reasoning visibility, and mandatory SpecKit integration.

---

## 1. 📋 ARGUMENT DISPATCH

```
$ARGUMENTS
    │
    ├─► Contains modifier (:review, :generate, :analyze, :explain, :debug, :refactor)
    │   └─► Use specified type, extract remaining text as query
    │
    ├─► Natural language (no modifier)
    │   └─► AUTO-DETECT type from keywords:
    │       ├─► "review|audit|security|bugs|check"     → REVIEW
    │       ├─► "create|generate|implement|build|add"  → GENERATE
    │       ├─► "analyze|architecture|structure|deps"  → ANALYZE
    │       ├─► "explain|what|how|why|understand"      → EXPLAIN
    │       ├─► "debug|fix|error|broken|failing"       → DEBUG
    │       ├─► "refactor|improve|clean|optimize"      → REFACTOR
    │       └─► No match                               → Ask user
    │
    └─► Ambiguous single word
        └─► Ask user to specify type
```

---

## 2. 📝 CONTRACT

**Inputs:** `$ARGUMENTS` — Query text with optional `:type` modifier
**Outputs:** `STATUS=OK|FAIL TYPE=<type> TOKENS=<n> SPEC=<path>`

---

## 3. ⚡ INSTRUCTIONS

### Step 1: Verify CLI

```bash
command -v codex && echo "OK" || echo "NOT FOUND"
```

If not found: `STATUS=FAIL ERROR="Codex CLI not installed"`

### Step 2: Parse Query Type

| Type | Modifier | Sandbox | Use Case |
|------|----------|---------|----------|
| Review | `:review` | read-only | Security audit, bug hunting |
| Generate | `:generate` | workspace-write | Create new code |
| Analyze | `:analyze` | read-only | Architecture analysis |
| Explain | `:explain` | read-only | Code walkthrough |
| Debug | `:debug` | read-only | Find root cause |
| Refactor | `:refactor` | workspace-write | Improve structure |

### Step 3: Execute Query

**Read-only types** (review, analyze, explain, debug):
```bash
codex exec "{query}" -s read-only 2>&1
```

**Write types** (generate, refactor):
```bash
codex exec "{query}" --full-auto 2>&1
```

### Step 4: Process Response

1. Extract thinking section (shows reasoning)
2. Extract main response
3. Capture session ID and token usage
4. Format and display to user

---

## 4. 💾 MEMORY SAVE (MANDATORY)

**After displaying the Codex response, ALWAYS save to memory:**

```
SAVE to {spec_path}/memory/{timestamp}__codex-{type}.md:

1. Generate memory file with:
   - Original query as trigger phrase
   - Full Codex response
   - Extracted key findings
   - Session metadata

2. Update .spec-active marker (if changed)

3. Confirm: "Saved to: {spec_path}/memory/{filename}"
```

**Memory File Format:**
```markdown
---
title: Codex {Type} Query
date: {DD-MM-YY}_{HH-MM}
type: codex-query
triggers: ["{original query keywords}"]
spec_folder: {spec_path}
---

## Query
{original_query}

## Type
{query_type} (Sandbox: {sandbox_mode})

## Response
{codex_response}

## Key Findings
{extracted_findings}

## Session
ID: {session_id} | Tokens: {token_count}
```

---

## 5. 🔍 EXAMPLE USAGE

**With type modifier:**
```bash
/cli:codex Review auth.ts for XSS vulnerabilities :review
/cli:codex Create a debounce hook :generate
/cli:codex Explain this recursive algorithm :explain
```

**Auto-detected type:**
```bash
/cli:codex Why is this returning undefined?
# → Auto-detects as DEBUG

/cli:codex How does the auth middleware work?
# → Auto-detects as EXPLAIN
```

**Interactive (no args):**
```bash
/cli:codex
# → Prompts for query, spec folder, then executes
```

---

## 6. 📊 OUTPUT FORMAT

```
┌─────────────────────────────────────────────────────────────┐
│  Codex Query                                                │
├─────────────────────────────────────────────────────────────┤
│  Type: Review                                               │
│  Sandbox: read-only                                         │
│  Spec: specs/042-auth-security                              │
│  Context: Loaded from 11-12-25_09-30__codex-review.md       │
└─────────────────────────────────────────────────────────────┘

Thinking:
  Analyzing auth.ts for OWASP Top 10 vulnerabilities...

Response:
  1. CRITICAL [L45]: SQL injection - use parameterized queries
  2. HIGH [L78]: Missing rate limiting on login
  3. MEDIUM [L23]: Weak password validation

───────────────────────────────────────────────────────────────
Session: abc123 | Tokens: 2,450
Saved to: specs/042-auth-security/memory/11-12-25_14-30__codex-review.md

STATUS=OK TYPE=review TOKENS=2450 SPEC=specs/042-auth-security
```

---

## 7. ⚠️ ERROR HANDLING

| Error | Detection | Action |
|-------|-----------|--------|
| CLI not found | `command -v` fails | Show install instructions |
| Auth error | "auth" in output | Guide to `codex auth login` |
| Rate limit | "rate limit" in output | Wait 60s, retry |
| Timeout | >120s | Cancel, suggest simpler query |
| Spec folder invalid | Path doesn't exist | Return to GATE 1 |

---

## 8. 📌 NOTES

- **Deep Reasoning**: Codex shows visible "thinking" section
- **Session Resume**: Use `codex resume --last` for follow-ups
- **Sandbox Safety**: Read-only prevents accidental changes
- **Validation**: Always review generated code before using
- **SpecKit Required**: All queries tracked in spec folders
- **Quick Mode**: Use `/cli:codex_quick` for untracked queries

---

## 9. 🔗 RELATED COMMANDS

- `/cli:codex_quick` — Fast execution, no spec tracking
- `/cli:gemini` — Gemini with web search + spec tracking
- `/memory/save` — Manual context save
- `/memory/search` — Search saved memories
- `/spec_kit:complete` — Full SpecKit workflow
