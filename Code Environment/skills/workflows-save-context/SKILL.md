---
name: workflows-save-context
description: This skill saves expanded conversation context when completing features or architectural discussions. It preserves full dialogue, decision rationale, visual flowcharts, and file changes for team sharing. Auto-triggered by keywords (e.g., "save context", "save conversation") or every 20 messages.
allowed-tools: [Read, Write, Bash]
version: 1.3.0
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


---

## 2. 🗂️ REFERENCES

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

### Smart Routing Logic

```python
def save_context_workflow(message):
    trigger_keywords = ["save context", "save conversation", "save session"]
    message_count = get_message_count()

    if any(keyword in message.lower() for keyword in trigger_keywords):
        trigger = "manual"
    elif message_count >= 20 and message_count % 20 == 0:
        trigger = "auto"
    else:
        return

    log_trigger(trigger, message_count)

    conversation_data = analyze_conversation_history(
        extract_user_requests=True,
        extract_decisions=True,
        extract_files_modified=True,
        extract_commands_run=True,
        extract_phase_transitions=True
    )

    temp_file = write_temp_data_file(generate_json_structure(conversation_data))

    spec_folder = detect_spec_folder()
    if not spec_folder:
        spec_folder = prompt_user_for_folder(search_recent_spec_folders(limit=5))

    active_marker = read_spec_active_marker(spec_folder)
    memory_dir = f"{spec_folder}/{active_marker}/memory" if active_marker else f"{spec_folder}/memory"

    alignment_score = calculate_alignment_score(conversation_data, spec_folder)

    if alignment_score < 0.70:
        log_warning(f"Low alignment ({alignment_score:.0%}) between conversation and {spec_folder}")
        if not prompt_user(f"Conversation alignment with {spec_folder} is {alignment_score:.0%}. Continue?"):
            spec_folder = prompt_user_for_folder(search_recent_spec_folders(limit=5))
            memory_dir = f"{spec_folder}/memory"

    context_result = execute_context_generator(
        script="scripts/generate-context.js",
        input_data=temp_file,
        output_dir=memory_dir,
        parallel_processing=True
    )

    flowchart = (
        generate_linear_flowchart(conversation_data.phases, "workflow_linear_pattern.md")
        if len(conversation_data.phases) <= 4
        else generate_parallel_flowchart(conversation_data.phases, "workflow_parallel_pattern.md")
    )

    timestamp = get_timestamp_format()
    topic = extract_topic_name(conversation_data)
    context_file_path = f"{memory_dir}/{timestamp}__{topic}.md"

    write_context_file(context_file_path, context_result.markdown, flowchart)

    update_metadata(memory_dir, f"{timestamp}__{topic}.md", message_count, len(conversation_data.phases), alignment_score, timestamp)

    log_success(f"Context saved to {context_file_path}")
    return {"status": "complete", "file": context_file_path}

def calculate_alignment_score(conversation_data, spec_folder):
    topic_overlap = calculate_topic_similarity(conversation_data.topic, spec_folder)
    file_overlap = calculate_file_overlap(conversation_data.files, spec_folder)
    phase_consistency = check_phase_consistency(conversation_data.phases, spec_folder)
    return (topic_overlap * 0.5) + (file_overlap * 0.3) + (phase_consistency * 0.2)
```

---

## 3. 🛠️ HOW TO USE

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

### Manual Invocation (Advanced - Rarely Needed)

**When to Use**:
- Auto-trigger hook is disabled
- Testing or debugging
- Custom workflow requirements

**⚠️ Important**: Only use manual invocation if auto-trigger is not working. In 99% of cases, the automatic hook is sufficient.

**AI Agent Process**:

1. Analyze current conversation history
2. Create structured JSON summary
3. Run Node.js script to process and generate markdown
4. Write to `specs/###-feature/memory/` folder

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

---

## 4. 📋 IMPLEMENTATION STEPS

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

## 5. 📊 DATA STRUCTURE GUIDELINES

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

## 6. 🔄 SPEC FOLDER DETECTION

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
- Marker location: `.claude/.spec-active`
- Verifies sub-folder exists before using
- Falls back to root `memory/` if marker invalid
- Cleans up stale markers automatically

**Versioning Example**:
```
specs/122-skill-standardization/
├── 001-cli-codex-alignment/
│   └── memory/
│       └── 23-11-25_10-03__cli-codex.md
├── 002-workflows-conversation/
│   └── memory/
│       └── 23-11-25_10-06__workflows.md
└── 003-spec-folder-versioning/  ← Active (from .spec-active)
    └── memory/
        └── 23-11-25_15-30__versioning.md  ← Writes here
```

**Routing Logic**:
1. **Hook**: Reads `.spec-active` marker (if exists)
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

---

## 7. 📖 RULES

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

## 8. 🎓 SUCCESS CRITERIA

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

## 9. ⚡ PERFORMANCE CHARACTERISTICS

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

## 10. 🗂️ MEMORY MANAGEMENT & CLEANUP

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

## 11. 💡 EXAMPLES

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

## 12. 🔧 TROUBLESHOOTING

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

## 13. 🔗 INTEGRATION POINTS

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

## 14. 🎯 QUICK REFERENCE

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