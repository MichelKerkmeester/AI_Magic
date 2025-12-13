# Spec Folder Detection - Routing & Alignment Logic

> Automatic detection, routing, and validation of spec folders for context preservation.

**Core Principle:** Accurate folder detection ensures context lands in the right place.

---

## 1. 📖 OVERVIEW

Save-context automatically detects the appropriate spec folder for saving context documentation. This ensures context is organized with the relevant feature/task and maintains proper version history.

### Detection System Versions

| Version | Mechanism | Status |
|---------|-----------|--------|
| **V10** | Topic-based matching via `.spec-actives.json` | Current |
| **V9** | Session-specific marker `.spec-active.{SESSION_ID}` | Supported |
| **Legacy** | Root-level `.spec-active` marker | Deprecated |

### Key Capabilities

- **Multi-spec tracking**: Multiple active specs per workspace
- **Topic matching**: Automatic routing based on conversation keywords
- **Session isolation**: Concurrent sessions don't conflict
- **Sub-folder awareness**: Routes to correct versioned sub-folder
- **Alignment scoring**: Validates context-to-folder relevance

---

## 2. 🎯 DETECTION LOGIC

### Detection Flowchart

```
┌─────────────────────────────────────────────────────────────────┐
│                    SPEC FOLDER DETECTION                        │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
              ┌───────────────────────────────┐
              │ STEP 1: Check V9 Session      │
              │ Marker (.spec-active.{SID})   │
              └───────────────────────────────┘
                              │
                    ┌─────────┴─────────┐
                    │                   │
               [EXISTS]            [NOT FOUND]
                    │                   │
                    ▼                   ▼
           ┌──────────────┐   ┌───────────────────────────┐
           │ Validate     │   │ STEP 2: Try V10 Topic     │
           │ Path Exists  │   │ Matching (.spec-actives)  │
           └──────────────┘   └───────────────────────────┘
                    │                   │
              [VALID]            ┌──────┴──────┐
                    │            │             │
                    ▼       [2+ MATCHES]  [<2 MATCHES]
           ┌──────────────┐      │             │
           │ USE FOLDER   │      ▼             ▼
           │ FROM MARKER  │  ┌─────────┐  ┌───────────────────┐
           └──────────────┘  │ USE     │  │ STEP 3: Fallback  │
                             │ MATCHED │  │ Highest Numbered  │
                             │ SPEC    │  └───────────────────┘
                             └─────────┘           │
                                   │               │
                                   └───────┬───────┘
                                           ▼
                              ┌───────────────────────────┐
                              │ STEP 4: Calculate         │
                              │ Alignment Score           │
                              └───────────────────────────┘
                                           │
                                  ┌────────┴────────┐
                                  │                 │
                             [≥70%]            [<70%]
                                  │                 │
                                  ▼                 ▼
                         ┌──────────────┐  ┌──────────────────┐
                         │ PROCEED      │  │ PROMPT USER      │
                         │ WITH SAVE    │  │ TO SELECT FOLDER │
                         └──────────────┘  └──────────────────┘
```

### Detection Steps Summary

| Step | Action | Mechanism |
|------|--------|-----------|
| 1 | Check session marker | `.spec-active.{SESSION_ID}` (V9) |
| 2 | Try topic matching | `.spec-actives.json` keywords (V10) |
| 3 | Fallback to highest | Numeric sort of `specs/###-*` |
| 4 | Calculate alignment | Score against folder context |
| 5 | Validate threshold | Prompt user if <70% |
| 6 | Error if none | Fail with clear instructions |

---

## 3. 📊 ALIGNMENT SCORING

When detecting the target folder, the system calculates an alignment score to validate the match quality.

### Score Components

| Component | Weight | Description |
|-----------|--------|-------------|
| **Topic Match** | 40% | Keyword overlap with spec topic |
| **File Context** | 30% | Referenced files in spec folder |
| **Phase Alignment** | 20% | Current work phase matches spec |
| **Recency** | 10% | Last accessed timestamp |

### Threshold Behavior

| Score | Action |
|-------|--------|
| **≥70%** | Proceed automatically |
| **<70%** | Prompt user for confirmation |
| **0%** | Fail with error (no matching spec) |

**Reference:** See [alignment_scoring.md](./alignment_scoring.md) for full scoring details.

### AUTO_SAVE_MODE Override

```bash
# Enable auto-save mode (bypasses alignment prompts)
AUTO_SAVE_MODE=true node generate-context.js data.json 122-feature-name

# Default mode (prompts on low alignment)
node generate-context.js data.json
```

| Mode | Behavior |
|------|----------|
| `AUTO_SAVE_MODE=true` | Bypass prompts, use most recent spec |
| `AUTO_SAVE_MODE=false` (default) | Interactive prompts on low alignment |

---

## 4. 📂 SUB-FOLDER ROUTING

### Sub-Folder Structure Example

```
specs/122-skill-standardization/
├── 001-api-integration/
│   └── memory/
│       └── 23-11-25_10-03__api-integration.md
├── 002-workflows-spec-kit/
│   └── memory/
│       └── 23-11-25_10-06__workflows.md
└── 003-spec-folder-versioning/  ← Active (from .spec-active)
    └── memory/
        └── 23-11-25_15-30__versioning.md  ← Writes here
```

### Marker Locations by Version

| Version | Location | Format |
|---------|----------|--------|
| **V10** | `.opencode/.spec-actives.json` | JSON with topic keywords |
| **V9** | `.opencode/.spec-active.{SESSION_ID}` | Plain text path |
| **Legacy** | `.spec-active` (root) | Plain text path |

### V10 Multi-Spec Configuration

```json
{
  "specs": [
    {
      "path": "specs/006-semantic-memory",
      "topic_keywords": ["memory", "semantic", "search", "vector"],
      "last_accessed": "2025-12-13T09:55:00Z"
    },
    {
      "path": "specs/007-documentation",
      "topic_keywords": ["docs", "readme", "reference", "template"],
      "last_accessed": "2025-12-12T14:30:00Z"
    }
  ]
}
```

### Routing Logic Steps

| Step | Action | Details |
|------|--------|---------|
| 1 | Check V9 marker | Session-specific `.spec-active.{SID}` |
| 2 | V10 topic match | Extract prompt keywords, match against `topic_keywords` |
| 3 | Fallback | `find specs/ -maxdepth 1 -name "[0-9][0-9][0-9]-*" \| sort -r \| head -1` |
| 4 | Validate | Confirm sub-folder path exists |
| 5 | Determine target | Full path `###-name/NNN-subfolder` or parent `###-name` |
| 6 | Pass to script | Node script receives validated spec target |
| 7 | Create memory dir | `mkdir -p {spec-target}/memory/` |
| 8 | Write context | Save to correct memory folder |

### Sub-Folder Marker Validation

Ensures `.spec-active.{SESSION_ID}` preserves full sub-folder paths:

```bash
local target_folder="$stored_folder"
if has_root_level_content "$stored_folder" && [ -f "$SPEC_MARKER" ]; then
  # Sub-folder exists - use path from existing marker
  target_folder=$(cat "$SPEC_MARKER" 2>/dev/null | tr -d '\n')
fi
create_spec_marker "$target_folder"
```

**Validation Triggers:**
- User selects Option A (reuse existing spec folder)
- Spec folder has root-level markdown files
- A `.spec-active.{SESSION_ID}` marker already exists

---

## 5. ⚙️ CONFIGURATION

### Session Isolation

| Feature | Behavior |
|---------|----------|
| **Marker per session** | Each session has own `.spec-active.{SESSION_ID}` |
| **No conflicts** | Concurrent sessions don't overwrite each other |
| **Cleanup on end** | Session marker removed when session ends |
| **Stale cleanup** | Markers >24h old cleaned on session start |

### Manual Workflow

When automatic detection is insufficient:

1. **Check active specs**: Read `.spec-actives.json` or root `.spec-active`
2. **Explicit folder**: Use `/memory/save [spec-folder]` with explicit path
3. **Follow AGENTS.md**: Maintain discipline per project standards

### Archive Filtering

Folders matching these patterns are automatically excluded from detection:

| Pattern | Description |
|---------|-------------|
| `z_*` | Archive prefix |
| `*archive*` | Contains "archive" |
| `old*` | Deprecated prefix |

---

## 6. ⚠️ EDGE CASES

### No Spec Folder Exists

**Behavior:** Skill fails with clear error message.

**Error Output:**
```
ERROR: No spec folder found in specs/
Create one with: mkdir -p specs/###-feature-name/
```

**Resolution:** Create spec folder manually before running save-context.

### No Conversation Data

**Behavior:** Skip alignment check (backward compatible).

**Resolution:** Use most recent spec folder automatically.

### Marker Points to Non-Existent Path

**Behavior:** Fallback to highest-numbered spec folder.

**Triggers:**
- Marker file references deleted folder
- Marker points outside current project
- Path validation fails

### Topic Match Below Threshold

**Behavior:** Prompt user when <2 keyword matches found.

**Resolution:**
- User confirms suggested folder, OR
- User specifies explicit folder path

### Concurrent Session Conflicts

**Behavior:** Each session isolated via unique marker.

**Prevention:**
- Session ID included in marker filename
- No shared state between sessions
- Stale markers auto-cleaned

---

## 7. 🔍 VALIDATION CHECKPOINTS

### Pre-Save Validation

| Check | Action on Failure |
|-------|-------------------|
| Spec folder exists | Error with creation instructions |
| Memory directory writable | Error with permission details |
| Alignment score ≥70% | Prompt user for confirmation |
| Session marker valid | Fallback to topic matching |

### Post-Save Validation

| Check | Action on Failure |
|-------|-------------------|
| File written successfully | Retry once, then error |
| File not empty | Error with debug info |
| Correct folder targeted | Log warning, proceed |

### Health Check Commands

```bash
# Verify current session marker
cat .opencode/.spec-active.${SESSION_ID}

# List all active specs (V10)
cat .opencode/.spec-actives.json | jq '.specs[].path'

# Find highest-numbered spec
find specs/ -maxdepth 1 -name "[0-9][0-9][0-9]-*" | sort -r | head -1

# Check for stale markers (>24h)
find .opencode/ -name ".spec-active.*" -mtime +1
```

---

## 8. 🔗 RELATED REFERENCES

| Reference | Description |
|-----------|-------------|
| [SKILL.md](../SKILL.md) | Main skill documentation |
| [alignment_scoring.md](./alignment_scoring.md) | Full scoring algorithm details |
| [memory_file_format.md](./memory_file_format.md) | Output file format specification |

---

*Last Updated: 2025-12-13 | Version: V10*
