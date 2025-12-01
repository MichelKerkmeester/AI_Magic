---
name: workflows-save-context
description: This skill saves expanded conversation context when completing features or architectural discussions. It preserves full dialogue, decision rationale, visual flowcharts, and file changes for team sharing. Auto-triggered by keywords (e.g., "save context", "save conversation") or every 20 messages. (v9.0+ includes anchor-based context retrieval)
allowed-tools: [Read, Write, Bash]
version: 9.0.0
---

# Save Context - Expanded Conversation Documentation

Preserve comprehensive conversation context in human-readable markdown files. Creates structured documentation with session summaries, full dialogue flow, decisions, and auto-generated flowcharts.

**Auto-Triggering**: Automatically saves when user types trigger keywords OR every 20 messages (context budget management).

---

## 1. 🎯 WHEN TO USE

### Navigation Guide

**This file (SKILL.md)**: Core workflow and auto-trigger configuration

**Reference Files** (workflow patterns):
- [workflow_linear_pattern.md](./references/workflow_linear_pattern.md) – Sequential workflow pattern (≤4 phases)
- [workflow_parallel_pattern.md](./references/workflow_parallel_pattern.md) – Concurrent workflow pattern (>4 phases)

**Templates** (output format):
- [context_template.md](./templates/context_template.md) – Generated markdown file structure

**Scripts** (automation):
- [generate-context.js](./scripts/generate-context.js) – Node.js script that processes JSON and generates markdown

### When to Use

**Auto-Triggered By**:
- **Keywords**: "save context", "save conversation", "document this", "preserve context", etc.
- **Message Count**: Every 20 messages (configurable context budget trigger)

**Manual Invocation** (when auto-trigger doesn't fire):
- Completing a significant implementation or research session
- Wrapping up a complex feature with multiple decisions
- Documenting an architectural discussion
- Creating a reference for future conversations
- Sharing conversation context with team members

**This skill should NOT be used for**:
- Simple typo fixes or trivial changes
- Context already well-documented in spec/plan files
- Real-time progress tracking (use claude-mem instead)
- Conversations without spec folders (create spec folder first)

**Key Characteristics**:
- **Triggering**: Automatic via keywords or context threshold (no /clear needed)
- **Granularity**: Full conversation flow with intelligent summaries
- **Format**: Human-readable markdown files in `specs/###-feature/memory/`
- **Detail Level**: Intelligent summaries with key code snippets
- **Visual Docs**: Auto-generated flowcharts and decision trees
- **Use Case**: Session documentation and team sharing

### When to RETRIEVE Context (Equally Important)

**MANDATORY: Before ANY implementation work in a spec folder with memory files**:
- Search anchors for prior decisions and implementations
- Load relevant sections using the Context Recovery Protocol
- Acknowledge what you found (or note absence)

**Why Retrieval Matters**:
- **Prevents duplicate work** - Don't re-implement what's already done
- **Ensures consistency** - Don't contradict prior approved decisions
- **Reduces token waste** - Don't re-discover known information (93% savings)
- **Maintains continuity** - Build on prior context, not from scratch

**When to Search Anchors**:
- Starting work in ANY spec folder with a `memory/` directory
- Before making architectural decisions
- Before implementing features that might have prior context
- When user references "what we discussed" or "the previous approach"

**See Section 4 for the full Context Recovery Protocol (MANDATORY).**


---

## 2. 🧭 SMART ROUTING

```python
def route_save_context_resources(task):
    # context generation script
    if task.generating_context:
        return execute("scripts/generate-context.js")  # main generator
    
    # flowchart pattern selection
    if task.needs_flowchart:
        if task.phase_count <= 4:
            return load("assets/workflow_linear_pattern.md")  # simple linear
        else:
            return load("assets/workflow_parallel_pattern.md")  # complex parallel
    
    # output format reference
    if task.needs_output_format:
        return load("references/output_format.md")  # timestamp, naming, structure
    
    # alignment scoring explanation
    if task.alignment_questions:
        return load("references/alignment_scoring.md")  # topic/file/phase weights
    
    # trigger configuration
    if task.configuring_triggers:
        return load("references/trigger_config.md")  # keywords, auto-save interval

# triggers: "save context", "save conversation", "save session", or every 20 messages
# output: specs/###-feature/memory/{timestamp}__{topic}.md
# alignment threshold: 70% (warns if lower)
```

---

## 3. 🗂️ REFERENCES

### Core Framework & Workflows
| Document                                | Purpose                                   | Key Insight                                                 |
| --------------------------------------- | ----------------------------------------- | ----------------------------------------------------------- |
| **Save Context - Auto-Trigger**         | Keyword and message-count based activation| **Zero-friction context preservation at 20-message intervals** |
| **Save Context - Manual Workflow**      | On-demand session documentation           | **Comprehensive dialogue + flowcharts + decisions**         |

### Bundled Resources
| Document                                    | Purpose                                    | Key Insight                                |
| ------------------------------------------- | ------------------------------------------ | ------------------------------------------ |
| **references/workflow_linear_pattern.md**   | Sequential workflow pattern (≤4 phases)    | Linear conversation flow visualization     |
| **references/workflow_parallel_pattern.md** | Concurrent workflow pattern (>4 phases)    | Multi-threaded conversation flow handling  |
| **templates/context_template.md**           | Output markdown file structure             | Ensures consistent documentation format    |
| **scripts/generate-context.js**             | Node.js processor (JSON → Markdown)        | **Promise.all() for parallel processing**  |

---

## 4. 🛠️ HOW TO USE

This skill is **standalone** - it does NOT use claude-mem MCP or external memory systems. Claude creates the conversation summary directly from the current session.

### Automatic Triggering (Recommended - Zero Effort)

**Most Common Usage**: Let the UserPromptSubmit hook handle everything automatically

**User Action**:
- Type trigger keywords: "save context", "save conversation", "document this", etc.
- OR simply continue conversation (auto-saves every 20 messages)

**What Happens Automatically**:
1. UserPromptSubmit hook detects keyword or message count
2. Hook finds transcript file and current spec folder
3. Hook transforms transcript to JSON format
4. Hook calls script with correct arguments
5. Context saved to `specs/###-feature/memory/`
6. Confirmation message displayed

**AI Agent Action**: **NONE** - Hook handles everything automatically

**Result**: ✅ Context saved without AI agent intervention

**Example Output**:
```
💾 Auto-saving context (keyword: 'save context' detected)...
   ✓ Loaded conversation data
   📁 Step 2: Detecting spec folder...
   ✓ Using spec folder: 122-skill-standardization
   📝 Step 3: Generating context documentation...
   ✓ Context file created: 23-11-25_10-15__skill-standardization.md
   ✅ Context saved to: specs/122-skill-standardization/memory/
```

### Alternative Execution Methods

The save-context system supports **4 independent execution paths**. Hooks are supplementary and **NOT required** - any method can be used standalone.

#### Method 1: Hook Auto-Trigger (Recommended - Zero Effort)

**When to Use**: Production use, normal workflow
**Requirement**: Hook enabled in `.claude/settings.local.json`

See "Automatic Triggering" section above for full details.

#### Method 2: Slash Command (Manual Trigger)

**When to Use**: Manual save without typing trigger keywords
**Requirement**: Slash command file exists at `.claude/commands/save_context.md`

**Usage**:
```
/save_context
```

**What Happens**:
1. Slash command expands to full prompt
2. AI agent analyzes conversation history
3. AI agent creates structured JSON summary
4. AI agent calls `generate-context.js` with JSON data
5. Context saved to active spec folder's `memory/` directory

**Result**: Same output as hook auto-trigger, but AI-driven instead of hook-driven

#### Method 3: Direct Script Execution (Development/Testing)

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
cd /path/to/project
node .claude/skills/workflows-save-context/scripts/generate-context.js \
  /tmp/test-save-context.json \
  "049-anchor-context-retrieval"
```

**Result**: Context saved to specified spec folder's `memory/` directory

#### Method 4: Helper Script (Standalone - Easiest Manual Invocation)

**When to Use**: Manual saves without hooks or slash commands
**Requirement**: Node.js and jq installed

**Location**: `.claude/skills/workflows-save-context/scripts/save-context-manual.sh`

**Usage**:
```bash
# Save to specific spec folder
bash .claude/skills/workflows-save-context/scripts/save-context-manual.sh \
  "049-anchor-context-retrieval" \
  "Manual save session"

# Auto-detect most recent spec folder
bash .claude/skills/workflows-save-context/scripts/save-context-manual.sh

# Show help
bash .claude/skills/workflows-save-context/scripts/save-context-manual.sh --help
```

**What It Does**:
1. Auto-detects most recent spec folder (if not specified)
2. Creates minimal JSON data with placeholder content
3. Calls `generate-context.js` with proper arguments
4. Shows success confirmation with file location

**Result**: Context saved with minimal placeholder data (useful for testing)

#### Execution Method Comparison

| Method | Hooks Required | AI Agent Required | Use Case | Effort |
|--------|----------------|-------------------|----------|--------|
| **Hook Auto-Trigger** | ✅ Yes | ❌ No | Production | Zero |
| **Slash Command** | ❌ No | ✅ Yes | Manual save | Low |
| **Direct Script** | ❌ No | ❌ No | Testing/Debug | Medium |
| **Helper Script** | ❌ No | ❌ No | Standalone | Low |

**Key Principle**: Hooks supplement the system but are **NOT required**. All execution paths work independently.

**Output Files** (both methods):
```
/specs/###-feature-name/
└── memory/
    ├── 09-11-25_07-52__feature-name.md  # Complete session documentation
    └── metadata.json                     # Session stats and metadata
```

**Primary Document**: `{date}_{time}__{topic}.md`
- **Format**: Timestamped markdown file
- **Naming**: DD-MM-YY_HH-MM__topic.md (Dutch date format, 2-digit year, no seconds)
- **Topic**: Derived from spec folder name (without number prefix)
- **Example**: `09-11-25_07-52__adaptive-page-loader.md`
- **Contains**: Session summary, full dialogue, decisions, diagrams, and analysis

**Metadata File**: `metadata.json`
- **Purpose**: Machine-readable session statistics
- **Contains**: Date, time, message count, decision count, diagram count, skill version

**Visual Documentation**:
- **Workflow Flowchart**: Visual representation of conversation phases
  - Linear pattern (≤4 phases): Sequential workflows
  - Parallel pattern (>4 phases): Concurrent tasks
- **Decision Trees**: Visual breakdown of key decisions with options/rationale

### Retrieving Saved Context (v9.0+ - Anchor-Based Retrieval)

**New in v9.0**: Memory files now include searchable HTML comment anchors for task-oriented context retrieval.

**Why Anchor-Based Retrieval**:
- **Token Efficiency**: Load relevant sections (500-1500 tokens) instead of full files (10k-15k tokens)
- **Task-Oriented**: Search by what was done ("OAuth implementation") not when it happened
- **Grep-Friendly**: Simple command-line extraction without parsing markdown or JSON

**Anchor Format**: `<!-- anchor: category-keywords-spec# -->`
- Example: `<!-- anchor: implementation-oauth-callback-049 -->`
- Categories: implementation, decision, guide, architecture, files, discovery, integration

---

### Context Recovery Protocol (MANDATORY)

**CRITICAL**: Before implementing ANY changes in a spec folder with memory files, you MUST search for relevant anchors. This is NOT optional.

**Why This Is Mandatory**:
- Prevents duplicating work that was already completed
- Ensures consistency with prior decisions
- Reduces token waste by not re-discovering known information
- Maintains continuity across sessions (93-97% token savings)

**Protocol Steps**:

1. **Extract Keywords** from your current task:
   - Identify 2-4 key terms (e.g., "auth", "oauth", "callback", "hook")
   - Focus on domain terms, not common words

2. **Search Anchors** using grep:
   ```bash
   # Search within current spec folder
   grep -r "anchor:.*keyword" specs/###-current-spec/memory/*.md

   # Cross-spec search if broader context needed
   grep -r "anchor:.*keyword" specs/*/memory/*.md

   # Find all decision anchors (high-value context)
   grep -l "anchor: decision" specs/###-current-spec/memory/*.md
   ```

3. **Load Relevant Sections** if matches found:
   ```bash
   # Use load-related-context.sh for intelligent retrieval
   .claude/hooks/lib/load-related-context.sh "###-spec" smart "your keywords"

   # Or extract specific anchor directly
   sed -n '/<!-- anchor: decision-auth-049 -->/,/<!-- \/anchor: decision-auth-049 -->/p' file.md
   ```

4. **Acknowledge Context** in your response:
   - If found: "Based on prior decision in memory file [filename], I see that [summary]..."
   - If not found: "No prior context found for [task keywords] - proceeding with fresh implementation"

**Anti-Patterns (NEVER DO)**:
- ❌ Assuming no prior work exists without searching anchors first
- ❌ Saying "I don't see any X" without running grep commands
- ❌ Ignoring loaded context and re-implementing from scratch
- ❌ Making decisions that contradict documented prior decisions
- ❌ Skipping anchor search because "this seems like a new task"

**Enforcement**: If you skip this protocol, you risk:
- Duplicating hours of prior work
- Contradicting decisions the user already approved
- Wasting tokens re-discovering information that's already documented
- Breaking consistency across the codebase

---

**Quick Search - Find Memory Files**:
```bash
# Find all memory files containing OAuth implementation
grep -l "anchor: implementation-oauth" specs/*/memory/*.md

# Find all decision anchors about authentication
grep -l "anchor: decision.*auth" specs/*/memory/*.md

# List all available anchors in a memory file
grep -o 'anchor: [a-z0-9-]*' specs/049-*/memory/*.md | sort -u
```

**Extract Specific Sections**:
```bash
# Extract OAuth implementation section (500-1500 tokens vs 10k+ for full file)
sed -n '/<!-- anchor: implementation-oauth-callback-049 -->/,/<!-- \/anchor: implementation-oauth-callback-049 -->/p' \
  specs/049-anchor-context-retrieval/memory/23-11-28_14-30__anchor-context.md

# Extract decision about JWT vs Sessions
sed -n '/<!-- anchor: decision-jwt-sessions-049 -->/,/<!-- \/anchor: decision-jwt-sessions-049 -->/p' \
  specs/049-*/memory/*.md

# Extract summary section (always available)
sed -n '/<!-- anchor: summary-049 -->/,/<!-- \/anchor: summary-049 -->/p' \
  specs/049-*/memory/*.md
```

**Backward Compatibility**:
- **v8.x and earlier**: Memory files do NOT include anchor tags - use full file reading
- **v9.0+**: All new memory files include anchor tags automatically
- **Migration**: No action needed - old files work as-is, new files include anchors
- **Detection**: Check for `<!-- anchor:` presence to determine if file supports anchors

**Best Practices**:
1. **Always grep first**: Find which memory files contain relevant anchors before extraction
2. **Use wildcards**: `specs/*/memory/*.md` searches across all spec folders
3. **Verify anchor exists**: `grep -q "anchor: ${ANCHOR_ID}"` before sed extraction
4. **Fallback to full read**: If anchor not found, read entire file (v8.x compatibility)

**Token Savings Example**:
```
Traditional approach: Read full memory file = 12,000 tokens
Anchor-based approach: Read specific section = 800 tokens
Savings: 93% token reduction (14x more efficient)
```

**Context Retrieval Commands** (Phase 3-4):

The `load-related-context.sh` script provides intelligent memory file access:

| Command | Purpose | Example | Token Count |
|---------|---------|---------|-------------|
| `list` | Show all memory sessions | `load-related-context.sh "049-..." list` | N/A |
| `summary` | Load summary from recent file | `load-related-context.sh "049-..." summary` | ~400 tokens |
| `search <kw>` | Find anchors by keyword | `load-related-context.sh "049-..." search "oauth"` | N/A |
| `extract <id>` | Load specific section | `load-related-context.sh "049-..." extract "decision-jwt-049"` | ~600 tokens |
| `recent N` | Load last N summaries | `load-related-context.sh "049-..." recent 3` | ~900 tokens |
| `smart <query>` | Relevance-ranked search | `load-related-context.sh "049-..." smart "auth bug"` | ~600 tokens |
| `search_all <kw>` | Cross-spec search | `load-related-context.sh search_all "oauth"` | Varies |

**Retrieval Decision Tree** (MANDATORY FIRST STEP):
```
Starting work in spec folder?
│
└─► SEARCH ANCHORS FIRST (see Context Recovery Protocol above)
    │
    ├─ Found relevant anchors?
    │   │
    │   ├─ YES → Load sections, acknowledge context, then proceed
    │   │        ├─ Quick refresh    → summary (400 tokens)
    │   │        ├─ Specific section → extract <anchor-id> (600 tokens)
    │   │        ├─ Multiple files   → recent 3 (900 tokens)
    │   │        └─ Deep search      → smart <query> (relevance-ranked)
    │   │
    │   └─ NO  → Note "no prior context found for [keywords]"
    │            Proceed with fresh implementation
    │
    └─ Need cross-project context?
        └─ search_all <keyword> → spans all spec folders
```

**Relevance Scoring** (Phase 4):

Smart and search_all commands use weighted multi-dimensional scoring:

- **Category Match** (35%): decision > implementation > guide > architecture
- **Keyword Overlap** (30%): Number of query keywords in anchor ID
- **Recency Factor** (20%): Newer files rank higher (1 / days+1)
- **Spec Proximity** (15%): Same spec=1.0, parent=0.8, other=0.3

Formula: `score = (category*0.35 + keywords*0.30 + recency*0.20 + proximity*0.15) * 100`

**Hook Integration**:

When you return to a spec folder with memory files, the hook asks:
```
🧠 MEMORY FILES DETECTED - Found N previous session file(s)

Would you like to load previous session context?
  A) Load most recent session (summary only)
  B) Load last 3 sessions (multi-summary)
  C) List all sessions and select specific
  D) Skip (start fresh)

Choose an option (A/B/C/D):
```

---

## 5. 📋 IMPLEMENTATION STEPS

### Step 1: Analyze Current Conversation

Review conversation history and extract:
- What the user requested
- What work was completed
- Key decisions made and their rationale
- Files created or modified
- Conversation phases (Research → Planning → Implementation → Testing)
- Any diagrams or flowcharts discussed

### Step 2: Create Conversation Summary JSON

Build structured JSON with this format:

```javascript
{
  recent_context: [{
    request: "Brief description of what user asked for",
    completed: "What was accomplished",
    learning: "Key insights from this session",
    duration: "Estimated session duration (e.g., '45m')",
    date: "ISO timestamp"
  }],

  observations: [{
    type: "feature|bugfix|decision|discovery|change",
    title: "Brief title of what happened",
    narrative: "Detailed description of the event",
    timestamp: "ISO timestamp",
    files: ["list", "of", "files", "touched"],
    facts: ["Key", "fact", "points"]
  }],

  user_prompts: [{
    prompt: "The actual user message",
    timestamp: "ISO timestamp"
  }]
}
```

### Step 3: Write Data File

Save conversation summary to temporary file:

```javascript
const dataFilePath = '/tmp/save-context-data.json';

await Write({
  file_path: dataFilePath,
  content: JSON.stringify(conversationData, null, 2)
});
```

### Step 4: Execute Script

Run Node.js script to process data:

```bash
# Basic usage (will prompt for spec folder if alignment is low)
node .claude/skills/workflows-save-context/scripts/generate-context.js /tmp/save-context-data.json

# With spec folder argument (bypasses interactive prompt)
node .claude/skills/workflows-save-context/scripts/generate-context.js /tmp/save-context-data.json 124-feature-name
```

**Script Arguments**:
- **Arg 1** (required): Path to JSON data file
- **Arg 2** (optional): Spec folder name (e.g., `124-feature-name`)
  - **Format**: Must be full folder name matching `###-feature-name` pattern
  - **Examples**: `122-skill-standardization`, `124-asset-file-enhancement`
  - Bypasses interactive folder selection prompt
  - Useful for non-interactive environments (hooks, automation)
  - Script verifies folder exists in `specs/` directory

**⚠️ Common Mistakes - Arg 2 Format**:

| ❌ Incorrect | ✅ Correct | Reason |
|-------------|-----------|--------|
| `"122"` | `"122-skill-standardization"` | Must include full folder name |
| `"mcp-skills-alignment"` | `"122-skill-standardization"` | Must be spec folder, not subfolder |
| `"latest"` | `"122-skill-standardization"` | No magic keywords, use actual folder name |
| `"skill-standardization"` | `"122-skill-standardization"` | Must include ###- prefix |

**How to find correct folder name**:
```bash
# List all spec folders
ls -d specs/[0-9][0-9][0-9]-*/

# Get most recent spec folder
ls -d specs/[0-9][0-9][0-9]-*/ | sort -r | head -1 | xargs basename
```

**Script Operations** (uses `Promise.all()` for parallel execution):
- Session metadata collection
- Conversation flow extraction
- Decision documentation
- Diagram detection and generation

**Performance**: ~2-5 seconds for typical conversations

### Step 5: Clean Up

```bash
rm /tmp/save-context-data.json
```

### Step 6: Report Results

Display script output showing created files and location.

---

## 6. 📊 DATA STRUCTURE GUIDELINES

**Session Metadata** (`recent_context`):
- 1 entry summarizing entire conversation
- `request`: User's initial ask (1-2 sentences)
- `completed`: What was delivered (2-3 sentences)
- `learning`: Key insights (1-2 sentences)
- `duration`: Estimate based on conversation length

**Observations**:
Create for significant events:
- `feature`: New capability added
- `bugfix`: Problem fixed
- `decision`: Technical choice with rationale
- `discovery`: New understanding gained
- `change`: Refactoring or modification

Each should have clear title, narrative explaining what/why, and affected files.

**User Prompts**:
- Include ALL user messages chronologically
- Preserve original wording
- Include timestamps

**Quality Guidelines**:
- Be comprehensive but concise
- Focus on "what" and "why", not just "how"
- Capture decision rationale and trade-offs
- Note diagrams or visual elements discussed

---

## 7. 🔄 SPEC FOLDER DETECTION

**Logic**:
1. Check if current directory is within `/specs/###-*/`
2. If yes, use that as target
3. If no, find most recent spec folder in `/specs/`
4. Check alignment between conversation topics and folder name
   - Extract keywords from conversation request/observations
   - Calculate alignment score (0-100%) with spec folder name
   - Threshold: **70%** (strict alignment required)
5. If alignment < 70%, prompt user to select target folder
6. **MANDATORY**: If no spec folder exists, fail with error instructing user to create spec folder

**Context Alignment**:
- **Automatic filtering**: Archive folders (`z_*`, `*archive*`, `old*`) excluded from consideration
- **Topic extraction**: Keywords from `recent_context.request` and `observations[].title`
- **Scoring**: Percentage of spec folder keywords found in conversation topics
- **Interactive prompt** (when alignment < 70%):
  ```
  ⚠️  Conversation topic may not align with most recent spec folder
  Most recent: 020-page-loader (25% match)

  Alternative spec folders:
  1. 018-auth-improvements (85% match)
  2. 017-authentication-refactor (90% match)
  3. 020-page-loader (25% match)
  4. Specify custom folder path

  Select target folder (1-4): _
  ```

**Behavior** - Single memory folder with timestamped files:
- Uses single `memory/` folder per spec or sub-folder
- Creates timestamped markdown files: `{date}_{time}__{topic}.md`
- Example: `09-11-25_07-52__skill-refinement.md`
- No conflicts - each save creates a new timestamped file

**Sub-Folder Awareness**:
- When `.spec-active` marker exists, routes to sub-folder's memory/
- Marker format: `specs/###-name/sub-folder-name`
- Marker location (V9): `.claude/.spec-active.{SESSION_ID}` (session-isolated)
- Marker location (legacy): `.claude/.spec-active` (fallback when no session ID)
- Verifies sub-folder exists before using
- Falls back to root `memory/` if marker invalid
- Cleans up stale markers automatically

**Session Isolation (V9)**:
- Each Claude Code session has its own marker file
- Prevents concurrent sessions from overwriting each other's spec context
- Session marker cleaned up when session ends
- Stale markers (>24h) cleaned up on session start

**Versioning Example**:
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

**Routing Logic**:
1. **Hook**: Reads `.spec-active.{SESSION_ID}` marker (V9: session-isolated, falls back to legacy `.spec-active`)
2. **Hook**: Validates sub-folder path exists within current spec folder
3. **Hook**: Determines spec target:
   - Sub-folder active: `"###-name/NNN-subfolder"` (full path)
   - Sub-folder inactive: `"###-name"` (parent only)
4. **Hook**: Passes spec target to Node script as second argument
5. **Node Script**: Creates `{spec-target}/memory/` directory
6. **Node Script**: Writes context to correct memory/ folder
7. **Fallback**: Uses root `specs/###/memory/` if:
   - No `.spec-active` marker exists
   - Marker points to non-existent path
   - Marker points outside current spec folder

**Edge Case** - No conversation data:
- Skip alignment check (backward compatible)
- Use most recent spec folder automatically

### Sub-Folder Marker Validation

**Purpose**: Ensures `.spec-active.{SESSION_ID}` marker preserves full sub-folder paths when sub-folder versioning is active.

**Problem**: When reusing a spec folder with root-level content (Option A workflow), the hook may write the parent folder path to the marker instead of the full sub-folder path, causing save-context to save to the wrong memory/ directory.

**Validation Pattern** (applied in enforce-spec-folder.sh):
```bash
# Validate if sub-folder needed before creating marker
local target_folder="$stored_folder"
if has_root_level_content "$stored_folder" && [ -f "$SPEC_MARKER" ]; then
  # Sub-folder exists - use path from existing marker
  target_folder=$(cat "$SPEC_MARKER" 2>/dev/null | tr -d '\n')
fi
create_spec_marker "$target_folder"
```

**When Validation Triggers**:
- User selects Option A (reuse existing spec folder)
- Spec folder has root-level markdown files (indicates sub-folder structure)
- A `.spec-active.{SESSION_ID}` marker already exists

**Behavior**:
- **With validation**: Reads existing marker containing full sub-folder path (e.g., `specs/006-commands/004-plan-claude-upgrade`)
- **Without validation**: Would use parent folder path only (e.g., `specs/006-commands`) - WRONG
- **Result**: save-context saves to correct sub-folder's memory/ directory

**Safety Warning** (added to create_spec_marker() function):
```bash
# Safety check: warn if creating marker for folder with root content
if has_root_level_content "$spec_path"; then
  echo "⚠️  WARNING: Creating marker for folder with root content: $spec_path" >&2
  echo "   This may indicate sub-folder versioning is needed" >&2
  echo "   If this is intentional, ignore this warning" >&2
fi
```

**Troubleshooting**:
- If save-context saves to parent memory/ instead of sub-folder memory/: Check marker content with `cat .claude/.spec-active.*`
- Expected marker content: Full sub-folder path (e.g., `specs/122-feature/003-iteration`)
- Incorrect marker content: Parent path only (e.g., `specs/122-feature`)

### AUTO_SAVE_MODE Environment Variable

The `AUTO_SAVE_MODE` environment variable controls how the save-context script behaves when invoked programmatically (by hooks or automation).

**Usage**:
```bash
# Enable auto-save mode (bypasses all prompts)
AUTO_SAVE_MODE=true node generate-context.js data.json 122-feature-name

# Default mode (may prompt on low alignment)
node generate-context.js data.json
```

**Behavior When `AUTO_SAVE_MODE=true`**:
- Bypasses alignment score prompts (no user interaction)
- Always uses most recent spec folder without confirmation
- Ideal for automated triggers (hooks, CI/CD)
- Silent operation - only outputs on success or error

**Behavior When `AUTO_SAVE_MODE=false` (default)**:
- Prompts user when alignment score < 70%
- Offers spec folder alternatives to choose from
- Interactive mode suitable for manual invocation

**When to Use**:
- **Hooks/Automation**: Always set `AUTO_SAVE_MODE=true`
- **Manual Invocation**: Leave unset for interactive prompts
- **Testing**: Set to `true` to skip prompts during automated tests

**Edge Case** - No spec folder exists:
- Skill will fail with clear error message
- Error instructs user to create spec folder first: `mkdir -p specs/###-feature-name/`
- Aligns with conversation-documentation mandate that all conversations require spec folders

### Troubleshooting Context Retrieval (Phase 3-4)

Common issues with load-related-context.sh commands and solutions:

| Issue | Symptom | Solution |
|-------|---------|----------|
| **Anchor not found** | `⚠️  Anchor not found: X` | Use `search <keyword>` to find available anchors, or verify anchor ID spelling |
| **Memory folder empty** | `📚 No previous sessions found` | Run `save context` command to create first memory file in spec folder |
| **Wrong memory loaded** | Context from different session/spec | Check `.spec-active.*` marker matches your SESSION_ID and spec folder |
| **V8.x file detected** | `⚠️ v8.x format detected` | Re-save context to generate v9.0 anchors, or use Read tool for full file |
| **Token budget exceeded** | `🛑 Token budget exceeded: N tokens` | Use `summary` (~400 tokens) or `extract <id>` (~600 tokens) instead of full file |
| **No results from smart search** | `❌ No anchors found matching: query` | Check keywords match anchor IDs, try broader terms, or use `list` to see available files |
| **Cross-spec search fails** | `❌ No memory files found` | Ensure other spec folders have `memory/*.md` files with v9.0 anchors |
| **Session marker mismatch** | Loads context from parallel session | Set/check `CLAUDE_SESSION_ID` environment variable for session isolation |

**Debugging Commands**:
```bash
# Check if memory file has anchors (v9.0 vs v8.x)
grep -c "<!-- anchor:" specs/049-*/memory/*.md

# List all available anchor IDs in a file
grep -o 'anchor: [a-z0-9-]*' specs/049-*/memory/*.md | sed 's/anchor: //' | sort -u

# Check which session marker is active
ls -la .claude/.spec-active* && cat .claude/.spec-active.*

# Find all v9.0 memory files across project
find specs -name "*.md" -path "*/memory/*" -exec grep -l "<!-- anchor:" {} \;

# Test relevance scoring on specific anchor
source .claude/hooks/lib/relevance-scorer.sh
show_score_breakdown "decision-auth-049" "authentication decision" \
  "specs/049-*/memory/*.md" "049-folder"
```

**v9.0 vs v8.x Detection**:
```bash
# v9.0 file (with anchors) - supports extract, smart, search_all
grep -q "<!-- anchor:" file.md && echo "v9.0 (supports anchors)" || echo "v8.x (full read only)"

# Count v9 vs v8 files in spec folder
v9_count=$(find specs/049-*/memory -name "*.md" -exec grep -l "<!-- anchor:" {} \; | wc -l)
v8_count=$(find specs/049-*/memory -name "*.md" | wc -l)
echo "v9.0: $v9_count | v8.x: $((v8_count - v9_count))"
```

**Common Workflow Issues**:

1. **"I can't find a specific decision I know we made"**
   - Solution: Use `search_all "decision keyword"` to search across all spec folders
   - Example: `load-related-context.sh search_all "auth decision" --limit 10`

2. **"Smart search returns nothing but I know the content exists"**
   - Cause: Most files are v8.x format (no anchors)
   - Solution: Re-save context in those spec folders to generate v9.0 anchors
   - Workaround: Use `list` + Read tool for v8.x files

3. **"Context loaded from wrong spec folder"**
   - Cause: Session marker points to different folder
   - Solution: Check `.spec-active.{SESSION_ID}` content, or use full spec path
   - Example: `load-related-context.sh "001-skills/049-feature" summary`

4. **"Relevance scores seem wrong"**
   - Cause: Category weights or keyword matching not optimal for your use case
   - Solution: Use `show_score_breakdown` to debug, adjust query keywords
   - Future: Category weights will be configurable in `.claude/configs/`

---

## 8. 📖 RULES

### ✅ ALWAYS 

- Detect spec folder before creating memory documentation
- Use single `memory/` folder with timestamped files
- Include `metadata.json` with session stats
- Preserve timestamps in conversation flow
- Reference files instead of copying large code blocks
- Follow document style guide for markdown formatting

### ❌ NEVER 

- Fabricate decisions that weren't made
- Include sensitive data (passwords, API keys)
- Skip template validation before writing
- Proceed if spec folder detection fails
- Create versioned memory folders (always use single memory/)
- Save context without spec folder (must have spec folder first)

### ⚠️ ESCALATE IF

- Cannot create conversation summary (unclear what happened)
- Script execution fails with errors
- File write permissions denied
- No spec folder exists (instruct user to create one first)

---

## 9. 🎓 SUCCESS CRITERIA

**Task complete when**:
- ✅ Auto-detects current spec folder
- ✅ Creates 2 files in `memory/` folder (timestamped .md + metadata.json)
- ✅ Generates readable, well-formatted comprehensive documentation
- ✅ Includes accurate timestamps and metadata
- ✅ Handles edge cases gracefully
- ✅ Follows document style guide standards

**Performance**:
- ✅ Execution time: 2-5 seconds (parallel processing)
- ✅ Works in all Node.js v18+ environments
- ✅ No timeout errors

---

## 10. ⚡ PERFORMANCE CHARACTERISTICS

### Execution Time

**Typical execution times**:
- Manual save: 2-3 seconds
- Auto-save (20-message trigger): 3-5 seconds (includes relevance analysis)
- Context with diagrams: +1-2 seconds (diagram generation)

### Blocking Behavior

**Important**: save-context executes **synchronously** and blocks conversation flow during execution.

**Why synchronous?**
- Guarantees context is saved before continuing
- Prevents data loss if conversation interrupted
- Ensures error handling is immediate and visible
- No risk of race conditions or partial saves

**Trade-offs**:

✅ **Synchronous (current)**:
- Guaranteed completion before continuing
- Immediate error handling and user feedback
- No data loss risk
- Simple, reliable implementation
- ❌ Blocks conversation for 2-5 seconds

⚠️ **Asynchronous (potential future)**:
- No blocking during save
- ❌ Completion not guaranteed
- ❌ Error handling delayed or missed
- ❌ Complex state management needed

### Performance Impact

**Auto-save triggers every 20 messages** and blocks conversation for 3-5 seconds while:
1. Analyzing conversation for relevance (1-2s)
2. Generating context summary with metadata (1-2s)
3. Writing to memory/ folder (0.5-1s)
4. Updating metadata.json (0.5s)

**Mitigation strategies**:
- **Manual triggering**: Use `/save-context` command for control over timing
- **Strategic timing**: Trigger at natural breakpoints (feature complete, before task switching)
- **Deferred save**: Wait until end of session if auto-save feels disruptive
- **Disable auto-save**: Set threshold higher in config if needed

### Optimization

The script uses **parallel processing** (`Promise.all()`) internally:
- Session metadata collection runs in parallel
- Conversation flow extraction runs in parallel
- Decision documentation runs in parallel
- Diagram detection runs in parallel

**Result**: 40-60% faster than sequential processing would be.

### Future Improvements

Planned enhancement to move save-context to background Task tool execution:
- Would eliminate blocking behavior
- Requires Task tool API stabilization
- Adds complexity for error handling
- Currently deferred until user feedback indicates need

**Current recommendation**: Synchronous execution is the right choice for reliability.

---

## 11. 🗂️ MEMORY MANAGEMENT & CLEANUP

### Growth Over Time

Each auto-save creates a timestamped file in `specs/[spec]/memory/`:
- 20 messages = ~1 save = ~50KB
- 100 messages = ~5 saves = ~250KB
- Long projects accumulate dozens of memory files

### Cleanup Strategy

**When to Clean Up:**
- After feature completion and merge
- Quarterly maintenance (archive old specs)
- When spec folder >10MB

**Manual Cleanup Commands:**
```bash
# List memory folder sizes
du -sh specs/*/memory/ | sort -h

# Archive old spec (completed >30 days ago)
SPEC="specs/085-old-feature"
tar -czf "${SPEC}.tar.gz" "$SPEC" && rm -rf "$SPEC"

# Or move to archive directory
mkdir -p specs/z_archive/
mv specs/085-old-feature specs/z_archive/
```

**Auto-Archiving Script** (optional):
```bash
#!/usr/bin/env bash
# Archive specs completed >30 days ago
find specs/ -maxdepth 1 -type d -mtime +30 | while read spec; do
  echo "Archiving: $spec"
  tar -czf "${spec}.tar.gz" "$spec"
  rm -rf "$spec"
done
```

### Best Practices

- Keep active specs only in specs/ directory
- Archive completed work quarterly
- Compress before archiving (tar.gz)
- Document archive location in project README

---

## 12. 💡 EXAMPLES

### Example 1: Feature Implementation

**Context**: Completed implementing authentication system

**Invocation**: `Skill(skill: "save-context")`

**Output**:
```
/specs/015-auth-system/
└── memory/
    ├── 09-11-25_14-23__auth-system.md  # Complete session documentation
    └── metadata.json                    # Machine-readable stats
```

**Markdown File Contains**:
- Overview and summary
- JWT decision rationale
- Authentication flow diagram
- 45-message dialogue
- Session metadata (2.5 hours, 3 decisions)

**Use Case**: Team lead reviews why JWT was chosen

### Example 2: Bug Investigation

**Context**: Traced performance issue to N+1 query problem

**Output**:
```
/specs/023-fix-performance/
└── memory/
    ├── 09-11-25_16-45__fix-performance.md  # Complete session documentation
    └── metadata.json                        # Machine-readable stats
```

**Markdown File Contains**:
- Root cause analysis
- Solution implementation
- Query optimization diagram
- Debugging steps
- Session metadata (30 minutes, 2 decisions)

**Use Case**: Documentation for future similar bugs

---

## 13. 🔧 TROUBLESHOOTING

### "Low alignment score - what does it mean?"

**Context**: Alignment score < 70% triggers folder selection prompt

**Understanding Scores**:
- **90-100%**: Excellent match - conversation clearly relates to spec folder topic
- **70-89%**: Good match - auto-selected without prompt
- **50-69%**: Moderate match - may be related, user should verify
- **30-49%**: Weak match - conversation likely about different topic
- **0-29%**: Poor match - definitely different topic

**When to override**:
- Accept suggestion if high-scoring folder (>80%) matches your intent
- Override if you're intentionally documenting unrelated work in that folder
- Create new spec folder if no good match exists (option 4 in prompt)

**Example**:
```
Conversation about "authentication improvements"
→ 018-auth-improvements (90% match) ✅ Accept
→ 020-page-loader (15% match) ❌ Wrong folder
```

### "Cannot create conversation summary"

**Solution**:
1. Review conversation history manually
2. Focus on key events (what user asked, what was delivered, major decisions)
3. Create simplified summary with available information
4. Document what information is incomplete

### "Permission denied writing to context/"

**Solution**:
1. Check folder permissions: `ls -la specs/###-*/`
2. Fix: `chmod -R u+w specs/###-*/`
3. Re-invoke skill

---

## 14. 🔗 INTEGRATION POINTS

**Standalone Architecture**:
- **Input**: Current conversation session (Claude's analysis)
- **Processing**: Node.js script with intelligent summarization
- **Output**: Human-readable markdown documentation

**Data Flow**:
```
Conversation → Claude Analysis → JSON → Script → Markdown Files
```

**Pairs With**:
- `git-commit` - Can enhance with commit SHAs in conversation flow
- `create-flowchart` - Can contribute diagrams to output

---

## 15. 🎯 QUICK REFERENCE

**Invocation**: `Skill(skill: "save-context")`

**Output Location**:
- **ONLY**: `specs/###-feature/memory/` (spec folder mandatory)

**Files Created**:
1. **Timestamped Markdown** - `{date}_{time}__{topic}.md`
   - Contains: Session summary, full dialogue, decisions, diagrams
   - Example: `09-11-25_07-52__feature-name.md` or `09-11-25_07-52__session_summary.md`
2. **Metadata JSON** - `metadata.json`
   - Contains: Session stats (message/decision/diagram counts, timestamps)

**Key Data Structure**:
```json
{
  "recent_context": [{ "request", "completed", "learning", "duration" }],
  "observations": [{ "type", "title", "narrative", "files", "facts" }],
  "user_prompts": [{ "prompt", "timestamp" }]
}
```

**Script Location**: `.claude/skills/workflows-save-context/scripts/generate-context.js`

**Performance**: ~2-5 seconds (parallel execution)

---

**Remember**: This skill operates as a context preservation engine. It captures dialogue, decisions, and visual flows to maintain continuity across sessions.