---
description: Fast Gemini CLI query - skip prompts, execute immediately
argument-hint: <query> [:review|:generate|:analyze|:research]
allowed-tools: Bash, Read
model: sonnet
---

# Gemini Quick

Fast-path Gemini CLI query. Skips interactive prompts for rapid execution.

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
    │       └─► No match                               → RESEARCH (default)
    │
    └─► Empty
        └─► ERROR: Query required for quick mode
```

---

## 2. 📝 CONTRACT

**Inputs:** `$ARGUMENTS` — Query text with optional `:type` modifier (REQUIRED)
**Outputs:** Raw Gemini response, `STATUS=OK|FAIL`

---

## 3. ⚡ INSTRUCTIONS

### Step 1: Verify CLI

```bash
command -v gemini >/dev/null || { echo "ERROR: Gemini not installed"; exit 1; }
```

### Step 2: Detect Type & Execute

**Add forceful prefix based on type:**

| Type | Prefix |
|------|--------|
| Review | "Review for bugs and security. Execute immediately." |
| Generate | "Generate the following. Execute immediately." |
| Analyze | "Use codebase_investigator. Execute immediately." |
| Research | "Search the web using Google. Execute immediately." |

**Execute:**
```bash
gemini "{prefix} {query}" --yolo -o text 2>&1
```

### Step 3: Display Output

Show raw Gemini response directly. No post-processing.

---

## 4. 🔍 EXAMPLE USAGE

```bash
# Auto-detected types
/cli:gemini_quick What is Next.js 15?
/cli:gemini_quick Analyze the auth architecture
/cli:gemini_quick Create a TypeScript debounce function
/cli:gemini_quick Review src/auth.ts for security

# Explicit type modifier
/cli:gemini_quick What are React Server Components? :research
/cli:gemini_quick Check this code :review
```

---

## 5. 📊 OUTPUT FORMAT

```
Gemini Quick | Type: Research | Tool: google_web_search
─────────────────────────────────────────────────────────

Next.js 15 (Released October 2024):

Key Features:
- Turbopack stable for dev server
- Partial Prerendering (PPR) stable
- next/after API for post-response tasks
- React 19 support
- Enhanced caching controls

Sources: nextjs.org, Vercel blog
```

---

## 6. ⚠️ ERROR HANDLING

| Error | Action |
|-------|--------|
| CLI not found | Exit: Install from github.com/google-gemini/gemini-cli |
| Empty query | Exit with usage hint |
| Auth error | Display: Run `gemini --version` to check |
| Rate limit (60/min) | CLI auto-retries |
| Rate limit (1000/day) | Inform user: "Daily limit reached" |
| Timeout | Cancel, suggest simpler query |

---

## 7. 📌 NOTES

- **No prompts** — Requires query in arguments
- **No memory** — Use `/cli:gemini` for memory features
- **Auto-detection** — Type inferred from keywords
- **Google Search** — Real-time web info via google_web_search
- **codebase_investigator** — Deep architecture analysis
- **Rate Limits** — 60 req/min, 1000/day (free tier)

---

## 8. 🔗 RELATED COMMANDS

- `/cli:gemini` — Interactive mode with prompts and memory
- `/cli:codex_quick` — Fast Codex with deep reasoning
- `/cli:quick` — Unified fast AI interface
