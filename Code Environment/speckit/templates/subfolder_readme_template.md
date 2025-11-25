# [YOUR_VALUE_HERE: sub-folder-name] - Overview

Purpose and organization documentation for a sub-folder within a larger spec folder.

<!-- SPECKIT_TEMPLATE_SOURCE: subfolder_readme_template | v1.0 -->

---

## 1. METADATA

- **Parent Spec**: [OPTIONAL: link to parent spec folder - example: `../` or `specs/###-parent-name/`]
- **Sub-Folder Purpose**: [YOUR_VALUE_HERE: brief description of why this sub-folder exists - 1 sentence]
- **Created**: [FORMAT: YYYY-MM-DD]
- **Status**: [NEEDS CLARIFICATION: Active | Complete | Archived]
- **Owner**: [YOUR_VALUE_HERE: team/individual]

---

## 2. PURPOSE

[YOUR_VALUE_HERE: 1-2 paragraph explanation of why this sub-folder exists and what problem it solves]

### Relationship to Parent Spec

[YOUR_VALUE_HERE: explain how this sub-folder's work relates to the parent spec folder's overall goals]

### Scope

**This sub-folder contains**:
- [YOUR_VALUE_HERE: item 1 - example: Analysis of X component]
- [YOUR_VALUE_HERE: item 2 - example: Implementation documentation for Y feature]
- [YOUR_VALUE_HERE: item 3 - example: Testing artifacts for Z scenario]

**This sub-folder does NOT contain**:
- [YOUR_VALUE_HERE: out of scope item 1]
- [YOUR_VALUE_HERE: out of scope item 2]

---

## 3. STRUCTURE & ORGANIZATION

### File Organization

```
[sub-folder-name]/
  README.md              # This file (overview and navigation)
  [file1.md]             # [Purpose of file 1]
  [file2.md]             # [Purpose of file 2]
  [sub-sub-folder/]      # [Purpose of nested folder]
```

### Key Documents

**[YOUR_VALUE_HERE: document-1-name]** - [Brief description and purpose]
- Location: `./[filename.md]`
- Status: [NEEDS CLARIFICATION: Draft | In Review | Complete]

**[YOUR_VALUE_HERE: document-2-name]** - [Brief description and purpose]
- Location: `./[filename.md]`
- Status: [NEEDS CLARIFICATION: Draft | In Review | Complete]

**[YOUR_VALUE_HERE: document-3-name]** - [Brief description and purpose]
- Location: `./[filename.md]`
- Status: [NEEDS CLARIFICATION: Draft | In Review | Complete]

---

## 4. WORKFLOW & USAGE

### When to Use This Sub-Folder

Use this sub-folder when:
- [YOUR_VALUE_HERE: condition 1 - example: Working on X-related analysis]
- [YOUR_VALUE_HERE: condition 2 - example: Implementing Y sub-feature]
- [YOUR_VALUE_HERE: condition 3 - example: Documenting Z process]

### Integration with Parent Spec

- **Reference from parent**: [YOUR_VALUE_HERE: how parent spec references this sub-folder]
- **Dependencies**: [YOUR_VALUE_HERE: what this sub-folder depends on from parent or other sub-folders]
- **Deliverables**: [YOUR_VALUE_HERE: what outputs from this sub-folder feed back to parent]

---

## 5. STATUS & PROGRESS

### Completion Checklist

- [ ] [YOUR_VALUE_HERE: key deliverable 1]
- [ ] [YOUR_VALUE_HERE: key deliverable 2]
- [ ] [YOUR_VALUE_HERE: key deliverable 3]
- [ ] All documentation complete
- [ ] Integration with parent spec verified

### Current Status

**Last Updated**: [FORMAT: YYYY-MM-DD]

**Progress**: [YOUR_VALUE_HERE: brief status update - example: Analysis complete, implementation in progress]

**Blockers**: [YOUR_VALUE_HERE: none | list any blockers preventing completion]

**Next Steps**:
1. [YOUR_VALUE_HERE: next action item 1]
2. [YOUR_VALUE_HERE: next action item 2]
3. [YOUR_VALUE_HERE: next action item 3]

---

## 6. REFERENCES

### Parent Spec Documents

- **Parent Spec**: [OPTIONAL: link to `../spec.md` or parent folder README]
- **Parent Plan**: [OPTIONAL: link to `../plan.md` if applicable]
- **Related Sub-Folders**: [OPTIONAL: links to sibling sub-folders if applicable]

### External References

- [OPTIONAL: link to related documentation]
- [OPTIONAL: link to related code/implementation]
- [OPTIONAL: link to related issues/tickets]

---

## 7. NOTES

[YOUR_VALUE_HERE: any additional context, observations, or important information about this sub-folder]

**Common Use Cases**:
- [YOUR_VALUE_HERE: use case 1]
- [YOUR_VALUE_HERE: use case 2]

**Lessons Learned**:
- [YOUR_VALUE_HERE: learning 1]
- [YOUR_VALUE_HERE: learning 2]

**Future Improvements**:
- [YOUR_VALUE_HERE: improvement idea 1]
- [YOUR_VALUE_HERE: improvement idea 2]

---

## WHEN TO USE THIS TEMPLATE

**Use subfolder README.md when:**
- Spec folder contains multiple sub-folders for organization
- Sub-folder has specific purpose distinct from parent spec
- Team needs navigation guidance within complex spec folder
- Sub-folder versioning/archiving used (001-original/, 002-update/, etc.)
- Multiple related but distinct work streams within single spec

**Skip subfolder README.md when:**
- Flat spec folder structure (no sub-folders)
- Sub-folder purpose is obvious from name and single file
- Temporary/working directory that will be cleaned up
- Sub-folder contains only generated files (no documentation needed)

**Common sub-folder types:**
- **Versioned iterations**: `001-original-work/`, `002-api-refactor/`, `003-bug-fixes/`
- **Domain separation**: `frontend/`, `backend/`, `infrastructure/`
- **Phase separation**: `research/`, `design/`, `implementation/`
- **Component separation**: `authentication/`, `payments/`, `notifications/`

**Related templates:**
- Create when reusing spec folder with versioning (see spec 122 sub-folder pattern)
- Reference parent spec.md, plan.md, tasks.md for context
- Update `.spec-active` marker to point to current active sub-folder
- Use migration script to create versioned sub-folders

---

<!--
  REPLACE SAMPLE CONTENT IN FINAL OUTPUT
  - This template contains placeholders and examples
  - Replace them with actual content for your sub-folder
-->
