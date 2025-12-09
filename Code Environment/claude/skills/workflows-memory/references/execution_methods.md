# Execution Methods Reference

> Four independent execution paths for memory, plus anchor-based retrieval.

---

## 1. 📖 OVERVIEW

The memory system supports **4 independent execution paths**. Hooks are supplementary and **NOT required** - any method can be used standalone.

| Method | Hooks Required | AI Agent Required | Use Case | Effort |
|--------|----------------|-------------------|----------|--------|
| **Hook Auto-Trigger** | Yes | No | Production | Zero |
| **Slash Command** | No | Yes | Manual save | Low |
| **Direct Script** | No | No | Testing/Debug | Medium |
| **Helper Script** | No | No | Standalone | Low |

---

## 2. 🔄 METHOD 1: HOOK AUTO-TRIGGER

**When to Use**: Production use, normal workflow
**Requirement**: Hook enabled in `.opencode/settings.local.json`

**User Action**:
- Type trigger keywords: "save memory", "save conversation", "document this", etc.
- OR simply continue conversation (auto-saves every 20 messages)

**What Happens Automatically**:
1. UserPromptSubmit hook detects keyword or message count
2. Hook finds transcript file and current spec folder
3. Hook transforms transcript to JSON format
4. Hook calls script with correct arguments
5. Context saved to `specs/###-feature/memory/`

**AI Agent Action**: **NONE** - Hook handles everything

---

## 3. ⌨️ METHOD 2: SLASH COMMAND

**When to Use**: Manual save without typing trigger keywords
**Requirement**: Slash command files exist in `.claude/commands/memory/` or `.opencode/command/memory/`

**Usage**:
```
/memory/save       # Simple save with interactive folder detection
/memory/search     # Search, manage index, view recent, rebuild, verify, retry
```

**What Happens**:
1. Slash command expands to full prompt
2. AI agent analyzes conversation history
3. AI agent creates structured JSON summary
4. AI agent calls `generate-context.js` with JSON data
5. Context saved to active spec folder's `memory/` directory

---

## 4. 🖥️ METHOD 3: DIRECT SCRIPT EXECUTION

**When to Use**: Testing, debugging, custom workflows
**Requirement**: Node.js installed

**Usage**:
```bash
# Create minimal JSON data file
cat > /tmp/test-save-context.json << 'EOF'
{
  "SPEC_FOLDER": "049-anchor-context-retrieval",
  "recent_context": [{
    "request": "Test save-context execution",
    "completed": "Verified system works standalone",
    "learning": "Direct script execution requires minimal JSON",
    "duration": "5m",
    "date": "2025-11-28T18:30:00Z"
  }],
  "observations": [{
    "type": "discovery",
    "title": "Standalone execution test",
    "narrative": "Testing direct script invocation",
    "timestamp": "2025-11-28T18:30:00Z",
    "files": [],
    "facts": ["No hooks required", "Minimal data sufficient"]
  }],
  "user_prompts": [{
    "prompt": "Test save-context standalone",
    "timestamp": "2025-11-28T18:30:00Z"
  }]
}
EOF

# Execute script directly
node .opencode/skills/workflows-memory/scripts/generate-context.js \
  /tmp/test-memory.json \
  "049-anchor-context-retrieval"
```

---

## 5. 📜 METHOD 4: HELPER SCRIPT

**When to Use**: Manual saves without hooks or slash commands
**Requirement**: Node.js and jq installed

**Location**: `.opencode/skills/workflows-memory/scripts/memory-manual.sh`

**Usage**:
```bash
# Save to specific spec folder
bash .opencode/skills/workflows-memory/scripts/memory-manual.sh \
  "049-anchor-context-retrieval" \
  "Manual save session"

# Auto-detect most recent spec folder
bash .opencode/skills/workflows-memory/scripts/memory-manual.sh

# Show help
bash .opencode/skills/workflows-memory/scripts/memory-manual.sh --help
```

---

## 6. 🔖 ANCHOR-BASED RETRIEVAL

### Token Efficiency

| Approach | Tokens | Savings |
|----------|--------|---------|
| Full file read | ~12,000 | - |
| Anchor extraction | ~800 | 93% |

### Anchor Format

`<!-- anchor: category-keywords-spec# -->`

**Categories**: `implementation`, `decision`, `guide`, `architecture`, `files`, `discovery`, `integration`

### Quick Commands

```bash
# Find anchors by keyword
grep -l "anchor:.*decision.*auth" specs/*/memory/*.md

# Extract specific section
sed -n '/<!-- anchor: decision-jwt-049 -->/,/<!-- \/anchor: decision-jwt-049 -->/p' file.md
```

---

## 7. 📋 CONTEXT RECOVERY PROTOCOL

**CRITICAL**: Before implementing ANY changes in a spec folder with memory files, you MUST search for relevant anchors.

### Protocol Steps

1. **Extract Keywords** from your task (2-4 key terms)

2. **Search Anchors** using grep:
   ```bash
   # Search within current spec folder
   grep -r "anchor:.*keyword" specs/###-current-spec/memory/*.md

   # Cross-spec search if broader context needed
   grep -r "anchor:.*keyword" specs/*/memory/*.md
   ```

3. **Load Relevant Sections** if matches found:
   ```bash
   # Use load-related-context.sh for intelligent retrieval
   .opencode/hooks/lib/load-related-context.sh "###-spec" smart "your keywords"

   # Or extract specific anchor directly
   sed -n '/<!-- anchor: decision-auth-049 -->/,/<!-- \/anchor: decision-auth-049 -->/p' file.md
   ```

4. **Acknowledge Context** in your response:
   - If found: "Based on prior decision in memory file [filename], I see that [summary]..."
   - If not found: "No prior context found for [task keywords] - proceeding with fresh implementation"

---

## 8. 🔧 CONTEXT RETRIEVAL COMMANDS

| Command | Purpose | Example | Token Count |
|---------|---------|---------|-------------|
| `list` | Show all memory sessions | `load-related-context.sh "049-..." list` | N/A |
| `summary` | Load summary from recent file | `load-related-context.sh "049-..." summary` | ~400 tokens |
| `search <kw>` | Find anchors by keyword | `load-related-context.sh "049-..." search "oauth"` | N/A |
| `extract <id>` | Load specific section | `load-related-context.sh "049-..." extract "decision-jwt-049"` | ~600 tokens |
| `recent N` | Load last N summaries | `load-related-context.sh "049-..." recent 3` | ~900 tokens |
| `smart <query>` | Relevance-ranked search | `load-related-context.sh "049-..." smart "auth bug"` | ~600 tokens |

---

*Related: [SKILL.md](../SKILL.md) | [troubleshooting.md](./troubleshooting.md)*
