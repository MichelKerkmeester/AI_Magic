# Troubleshooting Reference

> Common issues and solutions for memory.

---

## 1. 📖 OVERVIEW

This reference provides solutions for common memory issues, including alignment scoring problems, context retrieval failures, and script execution errors.

---

## 2. 🔧 QUICK FIXES

| Issue | Solution |
|-------|----------|
| Missing spec folder | `mkdir -p specs/###-feature/` |
| Wrong script path | Use `.opencode/skills/workflows-memory/scripts/generate-context.js` |
| Arg 2 format | Full folder name like `122-skill-standardization`, not just `122` |
| Vector search empty | Run `claude-mem rebuild` to generate embeddings |

---

## 3. 📊 ALIGNMENT SCORE ISSUES

### "Low alignment score - what does it mean?"

| Score Range | Meaning | Action |
|-------------|---------|--------|
| 90-100% | Excellent match | Auto-selected |
| 70-89% | Good match | Auto-selected |
| 50-69% | Moderate match | Verify manually |
| 30-49% | Weak match | Select different folder |
| 0-29% | Poor match | Create new spec folder |

**When to override**:
- Accept suggestion if high-scoring folder (>80%) matches intent
- Override if intentionally documenting unrelated work
- Create new spec folder if no good match exists

---

## 4. 🔍 CONTEXT RETRIEVAL ISSUES

| Issue | Symptom | Solution |
|-------|---------|----------|
| **Anchor not found** | `Anchor not found: X` | Use `search <keyword>` to find available anchors |
| **Memory folder empty** | `No previous sessions found` | Run `save context` to create first memory file |
| **Wrong memory loaded** | Context from different session | Check `.spec-active.*` marker |
| **Legacy file detected** | `Legacy format detected` | Re-save context to generate current anchors |
| **Token budget exceeded** | `Token budget exceeded: N tokens` | Use `summary` or `extract <id>` |
| **No results from smart search** | `No anchors found matching: query` | Try broader keywords, use `list` |

---

## 5. 🐛 DEBUGGING COMMANDS

```bash
# Check if memory file has anchors
grep -c "<!-- anchor:" specs/049-*/memory/*.md

# List all available anchor IDs in a file
grep -o 'anchor: [a-z0-9-]*' specs/049-*/memory/*.md | sed 's/anchor: //' | sort -u

# Check which session marker is active
ls -la .opencode/.spec-active* && cat .opencode/.spec-active.*

# Find all memory files with anchors across project
find specs -name "*.md" -path "*/memory/*" -exec grep -l "<!-- anchor:" {} \;
```

### File Format Detection

```bash
# Check file version
grep -q "<!-- anchor:" file.md && echo "Current (supports anchors)" || echo "Legacy (full read only)"

# Count files by format in spec folder
current_count=$(find specs/049-*/memory -name "*.md" -exec grep -l "<!-- anchor:" {} \; | wc -l)
total_count=$(find specs/049-*/memory -name "*.md" | wc -l)
echo "Current: $current_count | Legacy: $((total_count - current_count))"
```

---

## 6. 🔄 COMMON WORKFLOW ISSUES

### "I can't find a specific decision I know we made"

**Solution**: Use `search_all "decision keyword"` to search across all spec folders

```bash
load-related-context.sh search_all "auth decision" --limit 10
```

### "Smart search returns nothing but I know the content exists"

**Cause**: Most files are legacy format (no anchors)

**Solution**: Re-save context in those spec folders to generate current anchors

**Workaround**: Use `list` + Read tool for legacy files

### "Context loaded from wrong spec folder"

**Cause**: Session marker points to different folder

**Solution**: Check `.spec-active.{SESSION_ID}` content, or use full spec path

```bash
load-related-context.sh "001-skills/049-feature" summary
```

### "Permission denied writing to memory/"

**Solution**:
1. Check folder permissions: `ls -la specs/###-*/`
2. Fix: `chmod -R u+w specs/###-*/`
3. Re-invoke skill

---

## 7. 📝 SCRIPT ARGUMENT FORMAT

| Incorrect | Correct | Reason |
|-----------|---------|--------|
| `"122"` | `"122-skill-standardization"` | Must include full folder name |
| `"mcp-skills-alignment"` | `"122-skill-standardization"` | Must be spec folder, not subfolder |
| `"latest"` | `"122-skill-standardization"` | No magic keywords |
| `"skill-standardization"` | `"122-skill-standardization"` | Must include ###- prefix |

**How to find correct folder name**:
```bash
# List all spec folders
ls -d specs/[0-9][0-9][0-9]-*/

# Get most recent spec folder
ls -d specs/[0-9][0-9][0-9]-*/ | sort -r | head -1 | xargs basename
```

---

## 8. ⚠️ ESCALATION

**Escalate if**:
- Cannot create conversation summary
- Script execution fails with errors
- File write permissions denied
- Vector embedding generation fails repeatedly
- No spec folder exists

---

*Related: [SKILL.md](../SKILL.md) | [execution_methods.md](./execution_methods.md)*
