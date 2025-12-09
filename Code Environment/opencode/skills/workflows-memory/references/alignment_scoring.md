# Alignment Scoring Reference

> How memory determines the best spec folder match for conversation context.

---

## 1. 📖 OVERVIEW

When saving context, the system calculates an **alignment score** (0-100%) to determine which spec folder best matches the conversation topic.

**Threshold**: 70% (prompts user if below)

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

---

## 3. 🎯 SCORE INTERPRETATION

| Score Range | Meaning | Action |
|-------------|---------|--------|
| 90-100% | Excellent match | Auto-selected |
| 70-89% | Good match | Auto-selected |
| 50-69% | Moderate match | User prompted to verify |
| 30-49% | Weak match | User prompted, alternatives shown |
| 0-29% | Poor match | User prompted, suggest new folder |

---

## 4. 🔍 KEYWORD EXTRACTION

Keywords are extracted from:

1. **Conversation request** - Initial user ask
2. **Observation titles** - Event summaries
3. **File names** - Modified files
4. **Technical terms** - Domain-specific language

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

### Bypass Options

**Environment Variable**:
```bash
# Skip alignment prompts, use most recent folder
AUTO_SAVE_MODE=true node generate-context.js data.json
```

**Explicit Folder Argument**:
```bash
# Bypass scoring, use specified folder
node generate-context.js data.json "122-specific-folder"
```

---

*Related: [SKILL.md](../SKILL.md) | [spec_folder_detection.md](./spec_folder_detection.md)*
