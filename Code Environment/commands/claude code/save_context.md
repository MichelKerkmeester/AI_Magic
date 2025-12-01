---
description: Save conversation context to the related spec folder (v1.3.0)
argument-hint: [optional: spec-folder-name e.g. "122-skill-standardization"]
allowed-tools: Read, Write, Bash
---

# Save Context

Save the current conversation context as structured markdown documentation in the appropriate spec folder's memory directory.

---

```yaml
role: Context Preservation Specialist with Documentation Expertise
purpose: Preserve comprehensive conversation context for team sharing and future reference
action: Extract, structure, and save session context to spec folder memory directory

operating_mode:
  workflow: sequential_context_extraction
  workflow_compliance: MANDATORY
  workflow_execution: autonomous
  approvals: spec_folder_selection_if_ambiguous
  tracking: session_metadata_and_observations
  validation: alignment_score_threshold_70_percent
```

---

## Purpose

Preserve comprehensive conversation context including full dialogue, decisions, visual flowcharts, and file changes. Creates documentation in `specs/###-feature/memory/` for team sharing and future reference.

---

## Contract

**Inputs:** `$ARGUMENTS` — Optional spec folder name (e.g., "122-skill-standardization")
**Outputs:** Memory files in spec folder + `STATUS=<OK|FAIL> PATH=<memory-file-path>`

---

## Auto-Triggering

This skill automatically activates when:
- **Keywords detected**: "save context", "save conversation", "document this", "preserve context"
- **Context threshold**: Every 20 messages (automatic context preservation)

---

## Usage

```
/save-context
```

Optional argument to specify target spec folder (must be full folder name):
```
/save_context 092-skill-md-template
/save_context 122-skill-standardization
```

**Note**: Magic keywords like "latest" are not supported. Use the full folder name (e.g., `122-skill-standardization`).

---

## Spec Folder Detection

**Alignment Scoring**: The skill calculates alignment between conversation topics and spec folder names. If alignment is below 70%, you'll be prompted to select the correct folder.

**Sub-Folder Awareness**: When `.spec-active` marker exists, context is saved to the active sub-folder's `memory/` directory (e.g., `specs/122-name/003-subfolder/memory/`).

---

## What Gets Saved

**Primary Document**: `DD-MM-YY_HH-MM__topic.md`
- Session summary with request, completion, and learnings
- Full conversation flow with timestamps
- Key decisions and rationale
- Files created or modified
- Auto-generated workflow flowcharts
- Decision trees for complex choices

**Metadata File**: `metadata.json`
- Machine-readable session statistics
- Message counts, decision counts, diagram counts
- Timestamp and skill version info

---

## Output Location

```
/specs/###-feature-name/
└── memory/
    ├── DD-MM-YY_HH-MM__feature-name.md  # Complete session documentation
    └── metadata.json                     # Session stats and metadata
```

---

## Instructions

1. **Detect target spec folder:**
   - If argument provided: Use specified folder (e.g., "092-skill-md-template")
   - If "latest" or no argument: Find most recent spec folder in `/specs/`
   - Validate folder exists, create memory/ subdirectory if needed

2. **Analyze conversation:**
   - Extract user requests and completed work
   - Identify key decisions and their rationale
   - Note files created or modified
   - Detect conversation phases (Research → Planning → Implementation → Testing)
   - Capture any diagrams or flowcharts discussed

3. **Create structured JSON summary:**
   ```javascript
   {
     recent_context: [{
       request: "What user asked for",
       completed: "What was accomplished",
       learning: "Key insights from session",
       duration: "Estimated duration (e.g., '45m')",
       date: "ISO timestamp"
     }],
     observations: [{
       type: "feature|bugfix|decision|discovery|change",
       title: "Brief title",
       narrative: "Detailed description",
       timestamp: "ISO timestamp",
       files: ["affected", "files"],
       facts: ["Key", "points"]
     }],
     user_prompts: [{
       prompt: "Actual user message",
       timestamp: "ISO timestamp"
     }]
   }
   ```

4. **Write temporary data file:**
   ```bash
   echo '<JSON_DATA>' > /tmp/save-context-data.json
   ```

5. **Execute processing script:**
   ```bash
   node .claude/skills/workflows-save-context/scripts/generate-context.js /tmp/save-context-data.json
   ```

6. **Clean up:**
   ```bash
   rm /tmp/save-context-data.json
   ```

7. **Report results:**
   - Display generated file paths
   - Confirm successful save
   - Show location of documentation

---

## Data Quality Guidelines

**Session Metadata**:
- Be comprehensive but concise
- Focus on "what" and "why", not just "how"
- Capture decision rationale and trade-offs

**Observations**:
- Create for significant events only
- Include clear title and narrative
- List affected files
- Extract key factual points

**User Prompts**:
- Include ALL user messages chronologically
- Preserve original wording
- Include timestamps

---

## Failure Recovery

| Failure Type | Recovery Action |
|--------------|-----------------|
| Spec folder not found | Prompt for folder selection (A/B/C/D) |
| Memory directory inaccessible | Create memory/ subdirectory, retry |
| JSON parse error | Log error, create minimal context file |
| Script execution fails | Fall back to inline markdown generation |
| Alignment score below threshold | Prompt user to select correct folder |

---

## Error Handling

| Condition | Action |
|-----------|--------|
| Empty conversation | Return `STATUS=FAIL ERROR="No context to save"` |
| Invalid spec folder path | Suggest existing folders, prompt selection |
| Write permission denied | Report error, suggest alternative location |
| Script not found | Fall back to inline generation |

---

## When to Use

**Use when:**
- Completing significant implementation or research session
- Wrapping up complex feature with multiple decisions
- Documenting architectural discussion
- Creating reference for future conversations
- Sharing conversation context with team

**Don't use for:**
- Simple typo fixes or trivial changes
- Context already well-documented in spec/plan files
- Real-time progress tracking (use other methods)

---

## Configuration

Settings in `.claude/skills/workflows-save-context/config.jsonc`:
- `maxResultPreview`: Characters in tool result previews (default: 500)
- `maxConversationMessages`: Max messages to include (default: 100)
- `maxToolOutputLines`: Max lines from tool outputs (default: 100)
- `messageTimeWindow`: Time window for grouping phases in ms (default: 300000)
- `timezoneOffsetHours`: Timezone adjustment for timestamps (default: 1)

---

## Full Documentation

For comprehensive documentation including troubleshooting, performance characteristics, and advanced features, see:
`.claude/skills/workflows-save-context/SKILL.md`