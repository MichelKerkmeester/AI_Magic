# Spec Folder Detection Reference

> How memory determines and routes to the correct spec folder.

---

## 1. 📖 OVERVIEW

Save-context automatically detects the appropriate spec folder for saving context documentation. This ensures context is organized with the relevant feature/task.

---

## 2. 🔍 DETECTION LOGIC

| Step | Action |
|------|--------|
| 1 | Check if in `/specs/###-*/` directory |
| 2 | If not, find most recent spec folder |
| 3 | Calculate alignment score (threshold: 70%) |
| 4 | If < 70%, prompt user to select folder |
| 5 | If no spec folder exists, fail with error |

---

## 3. 📊 ALIGNMENT SCORING

When detecting the target folder, the system calculates an alignment score:

| Component | Weight |
|-----------|--------|
| Topic Match | 40% |
| File Context | 30% |
| Phase Alignment | 20% |
| Recency | 10% |

**Threshold**: 70% (prompts user if below)

See [alignment_scoring.md](./alignment_scoring.md) for full details.

---

## 4. 🗂️ SUB-FOLDER AWARENESS

When `.spec-active` marker exists, routes to sub-folder's memory/:

### Marker Format

`specs/###-name/sub-folder-name`

### Marker Locations

| Version | Location |
|---------|----------|
| Current | `.opencode/.spec-active.{SESSION_ID}` |
| Legacy | `.opencode/.spec-active` |

### Routing Logic

1. **Hook**: Reads `.spec-active.{SESSION_ID}` marker
2. **Hook**: Validates sub-folder path exists
3. **Hook**: Determines spec target:
   - Sub-folder active: `"###-name/NNN-subfolder"` (full path)
   - Sub-folder inactive: `"###-name"` (parent only)
4. **Hook**: Passes spec target to Node script
5. **Script**: Creates `{spec-target}/memory/` directory
6. **Script**: Writes context to correct memory/ folder

### Fallback Behavior

Uses root `specs/###/memory/` if:
- No `.spec-active` marker exists
- Marker points to non-existent path
- Marker points outside current spec folder

---

## 5. 🔐 SESSION ISOLATION

- Each session has its own marker file
- Prevents concurrent sessions from overwriting each other
- Session marker cleaned up when session ends
- Stale markers (>24h) cleaned up on session start

---

## 6. 📁 SUB-FOLDER STRUCTURE EXAMPLE

```
specs/122-skill-standardization/
├── 001-cli-codex-alignment/
│   └── memory/
│       └── 23-11-25_10-03__cli-codex.md
├── 002-workflows-spec-kit/
│   └── memory/
│       └── 23-11-25_10-06__workflows.md
└── 003-spec-folder-versioning/  ← Active (from .spec-active)
    └── memory/
        └── 23-11-25_15-30__versioning.md  ← Writes here
```

### Sub-Folder Marker Validation

**Purpose**: Ensures `.spec-active.{SESSION_ID}` marker preserves full sub-folder paths when sub-folder versioning is active.

**Validation Pattern** (in enforce-spec-folder.sh):

```bash
local target_folder="$stored_folder"
if has_root_level_content "$stored_folder" && [ -f "$SPEC_MARKER" ]; then
  # Sub-folder exists - use path from existing marker
  target_folder=$(cat "$SPEC_MARKER" 2>/dev/null | tr -d '\n')
fi
create_spec_marker "$target_folder"
```

**When Validation Triggers**:
- User selects Option A (reuse existing spec folder)
- Spec folder has root-level markdown files
- A `.spec-active.{SESSION_ID}` marker already exists

---

## 7. ⚙️ AUTO_SAVE_MODE ENVIRONMENT VARIABLE

Controls script behavior when invoked programmatically:

```bash
# Enable auto-save mode (bypasses all prompts)
AUTO_SAVE_MODE=true node generate-context.js data.json 122-feature-name

# Default mode (may prompt on low alignment)
node generate-context.js data.json
```

**When `AUTO_SAVE_MODE=true`**:
- Bypasses alignment score prompts
- Always uses most recent spec folder
- Silent operation

**When to Use**:
- **Hooks/Automation**: Always set `AUTO_SAVE_MODE=true`
- **Manual Invocation**: Leave unset for interactive prompts
- **Testing**: Set to `true` to skip prompts

---

## 8. ⚠️ EDGE CASES

### No Spec Folder Exists

- Skill fails with clear error message
- Error instructs user to create spec folder: `mkdir -p specs/###-feature-name/`

### No Conversation Data

- Skip alignment check (backward compatible)
- Use most recent spec folder automatically

### Archive Filtering

Folders matching these patterns are automatically excluded:

- `z_*` (archive prefix)
- `*archive*` (contains "archive")
- `old*` (deprecated prefix)

---

*Related: [SKILL.md](../SKILL.md) | [alignment_scoring.md](./alignment_scoring.md)*
