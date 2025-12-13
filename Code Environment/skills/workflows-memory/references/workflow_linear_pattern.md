# Linear Workflow Pattern - Sequential Flowcharts

> Sequential progression patterns for simple, straightforward conversation workflows.

**Core Principle:** Simple sequential flows for straightforward processes with clear step-by-step progression.

---

## 1. 📖 OVERVIEW

The linear pattern demonstrates simple sequential progression through conversation phases. Use this pattern for workflows with 4 or fewer phases that proceed in a step-by-step manner.

### Key Characteristics

| Characteristic     | Description                               |
| ------------------ | ----------------------------------------- |
| **Flow Direction** | Single path, top to bottom                |
| **Phase Count**    | 2-4 phases (optimal: 3)                   |
| **Complexity**     | Low - no branching or parallelism         |
| **Best For**       | Bug fixes, simple features, documentation |

---

## 2. 📊 EXAMPLE: BUG FIX WORKFLOW

```
╭────────────────────────────────────────────────────────╮
│                  CONVERSATION WORKFLOW                 │
╰────────────────────────────────────────────────────────╯
                        │
                        ▼
┌────────────────────────────────────────────────────────┐
│  Investigation                                         │
│  • Reading error logs                                  │
│  • Locating bug source                                 │
│  • Understanding context                               │
│  Duration: 4 minutes                                   │
└────────────────────────────────────────────────────────┘
                        │
                        ▼
┌────────────────────────────────────────────────────────┐
│  Fix Implementation                                    │
│  • Applying code changes                               │
│  • Adding error handling                               │
│  • Updating related code                               │
│  Duration: 6 minutes                                   │
└────────────────────────────────────────────────────────┘
                        │
                        ▼
┌────────────────────────────────────────────────────────┐
│  Verification                                           │
│  • Running test suite                                  │
│  • Confirming fix works                                  │
│  • Checking for regressions                            │
│  Duration: 3 minutes                                   │
└────────────────────────────────────────────────────────┘
                        │
                        ▼
╭────────────────────────────────────────────────────────╮
│                    WORKFLOW COMPLETE                   │
╰────────────────────────────────────────────────────────╯
```

---

## 3. 📊 EXAMPLE: DOCUMENTATION WORKFLOW

```
╭────────────────────────────────────────────────────────╮
│                 DOCUMENTATION WORKFLOW                 │
╰────────────────────────────────────────────────────────╯
                        │
                        ▼
┌────────────────────────────────────────────────────────┐
│  Research                                              │
│  • Reviewing existing code                             │
│  • Identifying key concepts                            │
│  Duration: 5 minutes                                   │
└────────────────────────────────────────────────────────┘
                        │
                        ▼
┌────────────────────────────────────────────────────────┐
│  Writing                                               │
│  • Drafting documentation                              │
│  • Adding code examples                                │
│  • Creating usage guides                               │
│  Duration: 10 minutes                                  │
└────────────────────────────────────────────────────────┘
                        │
                        ▼
┌────────────────────────────────────────────────────────┐
│  Review & Polish                                       │
│  • Checking accuracy                                   │
│  • Formatting consistently                             │
│  Duration: 3 minutes                                   │
└────────────────────────────────────────────────────────┘
                        │
                        ▼
╭────────────────────────────────────────────────────────╮
│                    DOCUMENTATION DONE                  │
╰────────────────────────────────────────────────────────╯
```

---

## 4. 🎯 WHEN TO USE

| Scenario                         | Example                             |
| -------------------------------- | ----------------------------------- |
| Simple sequential tasks          | Step-by-step file updates           |
| Straightforward implementations  | Adding a single feature             |
| Basic request-response workflows | Answer a question, provide solution |
| Bug fixes and patches            | Identify, fix, verify               |
| Documentation generation         | Research, write, format             |
| Single-path processes            | No branching or concurrency         |
| Workflows with ≤ 4 phases        | Most common use case                |

### When NOT to Use

| Scenario                     | Use Instead        |
| ---------------------------- | ------------------ |
| Multiple parallel activities | Parallel pattern   |
| Complex decision trees       | Decision pattern   |
| Iterative processes          | Loop pattern       |
| 5+ sequential phases         | Consider splitting |

---

## 5. 🛠️ STYLE GUIDELINES

### Box Structure (Standard Process)

```
┌────────────────────────────────────────────────────────┐
│  Phase Name                                            │
│  • Activity 1                                          │
│  • Activity 2                                          │
│  • Activity 3                                          │
│  Duration: X minutes                                   │
└────────────────────────────────────────────────────────┘
```

### Content Rules

| Element             | Rule                                          |
| ------------------- | --------------------------------------------- |
| **Line 1**          | Phase name (left-aligned, 2 spaces from edge) |
| **Lines 2-4**       | Activities with bullet points (• character)   |
| **Last line**       | Duration or timing information                |
| **Activity limit**  | 2-4 items (3 is ideal)                        |
| **Text truncation** | Fits within 50 chars per line                 |

### Flow Connectors

```
                        │
                        ▼
```

- **Vertical pipe**: Centered at column 24
- **Arrow**: Downward triangle at column 24
- **Spacing**: One blank line above and below boxes

### Terminal Boxes

| Type          | Description                                      |
| ------------- | ------------------------------------------------ |
| **Start**     | Rounded corners with centered title              |
| **End**       | Rounded corners with centered completion message |
| **Width**     | Same as process boxes (56 chars)                 |
| **Centering** | Title centered using space padding               |

---

## 6. ✅ VALIDATION

### Checklist Before Use

- [ ] Workflow has ≤ 4 phases
- [ ] No parallel activities required
- [ ] No decision branching needed
- [ ] Clear sequential progression
- [ ] Each phase has 2-4 activities

### Quality Checks

| Check         | Criteria                               |
| ------------- | -------------------------------------- |
| **Box width** | Exactly 56 characters                  |
| **Alignment** | Connectors centered at column 24       |
| **Content**   | Phase name + 2-4 activities + duration |
| **Spacing**   | One blank line between boxes           |
| **Terminals** | Rounded corners (╭╮╯╰) for start/end   |

---

*Related: [workflow_parallel_pattern.md](./workflow_parallel_pattern.md) | [SKILL.md](../SKILL.md)*
