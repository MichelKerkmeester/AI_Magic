# [Short Spec Name] - [One-Line Purpose]

[1-2 paragraph overview of the feature/change and why this spec folder exists. Provide context about what problem this solves and the intended outcome.]

<!-- SPECKIT_TEMPLATE_SOURCE: readme_template | v1.0 -->

---

## 1. METADATA

- **Spec ID**: [FORMAT: ###-short-name]
- **Status**: [FORMAT: Draft | In Progress | Complete | Archived]
- **Documentation Level**: [FORMAT: 0 | 1 | 2 | 3]
- **Created**: [FORMAT: YYYY-MM-DD]
- **Last Updated**: [FORMAT: YYYY-MM-DD]
- **Owner**: [YOUR_VALUE_HERE: Team name or individual]
- **Related Specs**: [OPTIONAL: Comma-separated list of related spec IDs, or "None"]

---

## 2. FOLDER STRUCTURE

[YOUR_VALUE_HERE: Provide tree view of files in this spec folder]

```
specs/[###-short-name]/
├── README.md (this file)
├── spec.md
├── plan.md
├── [OPTIONAL: tasks.md]
├── [OPTIONAL: checklist.md]
├── [OPTIONAL: research-*.md]
├── [OPTIONAL: research-spike-*.md]
├── [OPTIONAL: decision-record-*.md]
└── memory/
    └── [OPTIONAL: context saves from conversation]
```

**Sub-Folder Organization** (if applicable):
```
specs/[###-short-name]/
├── 001-[previous-work]/     (archived)
├── 002-[current-work]/      (active - .spec-active marker)
│   ├── spec.md
│   ├── plan.md
│   └── memory/
└── .spec-active → points to active sub-folder
```

---

## 3. OBJECTIVE

[YOUR_VALUE_HERE: Clear 2-4 sentence statement of what this spec accomplishes. Focus on the "why" and the expected outcome.]

**Key Goals**:
- [YOUR_VALUE_HERE: Primary goal or deliverable]
- [YOUR_VALUE_HERE: Secondary goal or deliverable]
- [YOUR_VALUE_HERE: Additional goal if applicable]

---

## 4. CORE DOCUMENTS

### spec.md
[YOUR_VALUE_HERE: Brief description of what spec.md contains - requirements, user stories, success criteria]

**Status**: ✅ Complete | ⚠️ In Progress | ❌ Not Started

### plan.md
[YOUR_VALUE_HERE: Brief description of what plan.md contains - technical approach, architecture, implementation phases]

**Status**: ✅ Complete | ⚠️ In Progress | ❌ Not Started

### tasks.md [OPTIONAL]
[YOUR_VALUE_HERE: Brief description if present - task breakdown organized by user story]

**Status**: ✅ Complete | ⚠️ In Progress | ❌ Not Started | N/A

### Additional Documents
[YOUR_VALUE_HERE: List any other documents with brief descriptions]

---

## 5. STATUS & PROGRESS

### Current Phase
[YOUR_VALUE_HERE: What phase is this work currently in - Planning | Implementation | Testing | Review | Complete]

### Completion Status
- **Overall Progress**: [YOUR_VALUE_HERE: percentage or phase description]
- **Spec Documentation**: ✅ Complete | ⚠️ In Progress | ❌ Not Started
- **Implementation**: ✅ Complete | ⚠️ In Progress | ❌ Not Started
- **Testing**: ✅ Complete | ⚠️ In Progress | ❌ Not Started
- **Review**: ✅ Complete | ⚠️ In Progress | ❌ Not Started

### Active Work
[YOUR_VALUE_HERE: What is currently being worked on]

### Blockers
[YOUR_VALUE_HERE: Any blockers or dependencies preventing progress]

**Status**: ✅ No blockers | ⚠️ Minor blockers | ❌ Critical blockers

---

## 6. RELATED SPECS

[YOUR_VALUE_HERE: Links to related spec folders or external resources]

### Dependencies
- [OPTIONAL: Link to spec folder or resource this work depends on]

### Related Work
- [OPTIONAL: Link to related spec folder or resource]

### References
- [OPTIONAL: External documentation, ADRs, or resources]

---

## 7. NOTES

[YOUR_VALUE_HERE: Any important context, decisions, or information that doesn't fit above]

### Key Decisions
- [YOUR_VALUE_HERE: Important decision made during this work]

### Lessons Learned
- [OPTIONAL: Insights gained during implementation]

### Future Considerations
- [OPTIONAL: Ideas or improvements for future work]

---

## WHEN TO USE THIS TEMPLATE

Use `readme_template.md` as the root README.md for your spec folder when:

- ✅ You need to document the overall organization and structure of a spec folder
- ✅ You want to provide navigation to all documents within the spec folder
- ✅ You need to track status and progress at the folder level
- ✅ You want to explain the purpose and scope of the entire spec folder

This template is for **root-level spec folder organization**. For:
- **Level 0 (minimal)**: Use `minimal_readme_template.md` instead
- **Sub-folders**: Use `subfolder_readme_template.md` instead

---

<!--
  ROOT SPEC FOLDER README TEMPLATE
  - Provides overview and navigation for entire spec folder
  - Tracks status and progress
  - Links to all core documents
  - Semantic emojis only: ✅ ❌ ⚠️
-->
