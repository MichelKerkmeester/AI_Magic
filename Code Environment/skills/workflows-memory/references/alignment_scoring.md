# Alignment Scoring - Spec Folder Matching Algorithm

> How save-context determines the best spec folder match for conversation context.

---

## 1. 📖 OVERVIEW

When saving context, the system calculates an **alignment score** (0-100%) to determine which spec folder best matches the conversation topic.

**Core Principle:** Match conversations to spec folders with 70% threshold confidence.

**Threshold**: 70% minimum for auto-selection (prompts user if below)

---

## 2. 📊 SCORING COMPONENTS

| Component | Weight | Description |
|-----------|--------|-------------|
| Topic Match | 40% | Keywords from conversation match spec folder name |
| File Context | 30% | Files discussed exist in spec folder |
| Phase Alignment | 20% | Conversation phase matches spec workflow |
| Recency | 10% | More recent folders score higher |

### Calculation Formula

```python
def calculate_alignment_score(conversation, spec_folder):
    topic_score = match_keywords(conversation.topics, spec_folder.name) * 0.40
    file_score = match_files(conversation.files, spec_folder.files) * 0.30
    phase_score = match_phase(conversation.phase, spec_folder.workflow) * 0.20
    recency_score = calculate_recency(spec_folder.modified_date) * 0.10

    return (topic_score + file_score + phase_score + recency_score) * 100
```

### Component Details

**Topic Match (40%)**
- Extracts keywords from conversation
- Compares against spec folder name segments
- Uses fuzzy matching for partial matches

**File Context (30%)**
- Tracks files mentioned or modified in conversation
- Checks if files exist within spec folder's scope
- Higher weight for recently modified files

**Phase Alignment (20%)**
- Maps conversation activities to workflow phases
- Planning → spec.md, plan.md
- Implementation → code files, tasks.md
- Verification → checklist.md, testing

**Recency (10%)**
- Exponential decay based on last modification
- 7-day half-life
- Prevents stale folders from scoring high

---

## 3. 🎯 SCORE INTERPRETATION

| Score Range | Meaning | Action |
|-------------|---------|--------|
| 90-100% | Excellent match | Auto-selected |
| 70-89% | Good match | Auto-selected |
| 50-69% | Moderate match | User prompted to verify |
| 30-49% | Weak match | User prompted, alternatives shown |
| 0-29% | Poor match | User prompted, suggest new folder |

### Example Scoring Walkthrough

**Scenario**: Conversation about "fix tab menu border styling"

```
Spec Folder: 006-code-refinement/002-tab-menu-border-fix/

Component Breakdown:
├─ Topic Match:    "tab menu border" ↔ "tab-menu-border-fix" = 95%
├─ File Context:   tab_menu.js discussed, exists in scope    = 80%
├─ Phase Alignment: debugging activity ↔ implementation      = 70%
└─ Recency:        modified 2 days ago                       = 85%

Weighted Calculation:
  (0.95 × 0.40) + (0.80 × 0.30) + (0.70 × 0.20) + (0.85 × 0.10)
= 0.38 + 0.24 + 0.14 + 0.085
= 0.845 → 84.5%

Result: Good match → Auto-selected
```

---

## 4. 🔍 KEYWORD EXTRACTION

Keywords are extracted from:

1. **Conversation request** - Initial user ask
2. **Observation titles** - Event summaries
3. **File names** - Modified files
4. **Technical terms** - Domain-specific language

### Extraction Process

```
Input: "Fix the tab menu border not showing on hover state"

Step 1: Tokenize
  ["Fix", "the", "tab", "menu", "border", "not", "showing", "on", "hover", "state"]

Step 2: Remove stop words
  ["Fix", "tab", "menu", "border", "showing", "hover", "state"]

Step 3: Normalize
  ["fix", "tab", "menu", "border", "showing", "hover", "state"]

Step 4: Extract meaningful terms
  ["tab", "menu", "border", "hover", "state"]

Output: Primary keywords for matching
```

### Stop Words (excluded)

```
the, a, an, is, are, was, were, be, been, being,
have, has, had, do, does, did, will, would, could,
should, may, might, must, shall, can, need, dare,
ought, used, to, of, in, for, on, with, at, by,
from, as, into, through, during, before, after,
above, below, between, under, again, further, then,
once, here, there, when, where, why, how, all, each,
few, more, most, other, some, such, no, nor, not,
only, own, same, so, than, too, very, just, also
```

---

## 5. 💬 INTERACTIVE PROMPT

When alignment < 70%, user sees:

```
Conversation topic may not align with most recent spec folder.
Most recent: 020-page-loader (25% match)

Alternative spec folders:
1. 018-auth-improvements (85% match)
2. 017-authentication-refactor (90% match)
3. 020-page-loader (25% match)
4. Specify custom folder path

Select target folder (1-4): _
```

### Archive Filtering

Folders matching these patterns are automatically excluded:

- `z_*` (archive prefix)
- `*archive*` (contains "archive")
- `old*` (deprecated prefix)

---

## 6. ⚙️ BYPASS OPTIONS

### Environment Variable

```bash
# Skip alignment prompts, use most recent folder
AUTO_SAVE_MODE=true node generate-context.js data.json
```

### Explicit Folder Argument

```bash
# Bypass scoring, use specified folder
node generate-context.js data.json "122-specific-folder"
```

### Session Preferences

Users can set preferences that persist within a session:

| Phrase | Effect |
|--------|--------|
| `"auto-save"` | Skip prompts, use highest-scoring folder |
| `"always ask"` | Prompt even for high-confidence matches |
| `"new folder"` | Always create new spec folder |

---

*Related: [SKILL.md](../SKILL.md) | [spec_folder_detection.md](./spec_folder_detection.md)*
