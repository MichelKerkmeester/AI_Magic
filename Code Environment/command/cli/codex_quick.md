---
description: Fast Codex CLI query - skip prompts, execute immediately
argument-hint: <query> [:review|:generate|:analyze|:explain|:debug|:refactor]
allowed-tools: Bash, Read
model: sonnet
---

# Codex Quick

Fast-path Codex CLI query. Skips interactive prompts for rapid execution.

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
    │       ├─► "review|audit|security|bugs|check"     → REVIEW (read-only)
    │       ├─► "create|generate|implement|build|add"  → GENERATE (full-auto)
    │       ├─► "analyze|architecture|structure|deps"  → ANALYZE (read-only)
    │       ├─► "explain|what|how|why|understand"      → EXPLAIN (read-only)
    │       ├─► "debug|fix|error|broken|failing"       → DEBUG (read-only)
    │       ├─► "refactor|improve|clean|optimize"      → REFACTOR (full-auto)
    │       └─► No match                               → ANALYZE (default)
    │
    └─► Empty
        └─► ERROR: Query required for quick mode
```

---

## 2. 📝 CONTRACT

**Inputs:** `$ARGUMENTS` — Query text with optional `:type` modifier (REQUIRED)
**Outputs:** Raw Codex response, `STATUS=OK|FAIL`

---

## 3. ⚡ INSTRUCTIONS

### Step 1: Verify CLI

```bash
command -v codex >/dev/null || { echo "ERROR: Codex not installed"; exit 1; }
```

### Step 2: Detect Type & Execute

**Read-only types** (review, analyze, explain, debug):
```bash
codex exec "{query}" -s read-only 2>&1
```

**Write types** (generate, refactor):
```bash
codex exec "{query}" --full-auto 2>&1
```

### Step 3: Display Output

Show raw Codex response including:
- Thinking section (visible reasoning)
- Main response
- Session ID and token count

---

## 4. 🔍 EXAMPLE USAGE

```bash
# Auto-detected types
/cli:codex_quick Review auth.ts for XSS vulnerabilities
/cli:codex_quick Implement a debounce function
/cli:codex_quick Why is this returning undefined?

# Explicit type modifier
/cli:codex_quick Optimize this loop :refactor
/cli:codex_quick What patterns are used here? :analyze
```

---

## 5. 📊 OUTPUT FORMAT

```
Codex Quick | Type: Review | Sandbox: read-only
─────────────────────────────────────────────────

Thinking:
  Analyzing for OWASP Top 10 vulnerabilities...

Response:
  1. CRITICAL [L45]: SQL injection risk
  2. HIGH [L78]: Missing rate limiting
  3. MEDIUM [L23]: Weak password validation

─────────────────────────────────────────────────
Session: abc123 | Tokens: 1,842
```

---

## 6. ⚠️ ERROR HANDLING

| Error | Action |
|-------|--------|
| CLI not found | Exit with install message |
| Empty query | Exit with usage hint |
| Auth error | Display: `codex auth login` |
| Rate limit | Wait and retry automatically |
| Timeout (>120s) | Cancel, suggest simpler query |

---

## 7. 📌 NOTES

- **No prompts** — Requires query in arguments
- **No memory** — Use `/cli:codex` for memory features
- **Auto-detection** — Type inferred from keywords
- **Deep reasoning** — Thinking section shows Codex's process

---

## 8. 🔗 RELATED COMMANDS

- `/cli:codex` — Interactive mode with prompts and memory
- `/cli:gemini_quick` — Fast Gemini with Google Search
