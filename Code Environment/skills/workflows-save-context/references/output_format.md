# Output Format Reference

> Timestamp formats, file naming conventions, and output structure for save-context.

---

## 1. 📖 OVERVIEW

Save-context generates structured documentation files with consistent naming conventions and predictable output locations. This reference details the format specifications for all output files.

---

## 2. 📄 FILE NAMING CONVENTION

### Primary Document

**Format**: `{date}_{time}__{topic}.md`

| Component | Format | Example |
|-----------|--------|---------|
| Date | DD-MM-YY | 07-12-25 |
| Time | HH-MM | 14-30 |
| Separator | `__` (double underscore) | __ |
| Topic | kebab-case from spec folder | oauth-implementation |

**Full Example**: `07-12-25_14-30__oauth-implementation.md`

### Metadata File

**Format**: `metadata.json`

Located alongside the primary document in the `memory/` folder.

---

## 3. 📂 OUTPUT LOCATION

```
specs/###-feature-name/
└── memory/
    ├── 07-12-25_14-30__feature-name.md   # Primary document
    └── metadata.json                      # Session statistics
```

### Path Resolution

1. Check if in `/specs/###-*/` directory
2. Find most recent spec folder if not
3. Create `memory/` subdirectory if missing
4. Generate timestamped filename

---

## 4. 📝 DOCUMENT STRUCTURE

### Primary Document Sections

```markdown
# Session Summary

## Overview
[Brief session description]

## Key Decisions
<!-- anchor: decisions-{spec#} -->
[Decision documentation]
<!-- /anchor: decisions-{spec#} -->

## Implementation Details
<!-- anchor: implementation-{spec#} -->
[What was built]
<!-- /anchor: implementation-{spec#} -->

## Conversation Flow
[Full dialogue with timestamps]

## Files Modified
[List of changed files]

## Session Metadata
[Statistics and timing]
```

### Anchor Tags

Each section includes HTML comment anchors for targeted retrieval:

```html
<!-- anchor: category-keywords-spec# -->
Content here...
<!-- /anchor: category-keywords-spec# -->
```

**Categories**: `implementation`, `decision`, `guide`, `architecture`, `files`, `discovery`, `integration`

---

## 5. 🗃️ METADATA JSON STRUCTURE

```json
{
  "timestamp": "2025-12-07T14:30:00Z",
  "specFolder": "049-oauth-implementation",
  "messageCount": 45,
  "decisionCount": 3,
  "diagramCount": 2,
  "duration": "2h 15m",
  "topics": ["oauth", "jwt", "authentication"]
}
```

### Timestamp Formats

| Context | Format | Example |
|---------|--------|---------|
| Filename date | DD-MM-YY | 07-12-25 |
| Filename time | HH-MM | 14-30 |
| JSON timestamp | ISO 8601 | 2025-12-07T14:30:00Z |
| Conversation flow | HH:MM:SS | 14:30:45 |

---

*Related: [SKILL.md](../SKILL.md) | [context_template.md](../templates/context_template.md)*
