# Workflow Flowchart - Linear Pattern Reference

> Sequential progression patterns for simple, straightforward conversation workflows.

---

## 1. 📖 OVERVIEW

The linear pattern demonstrates simple sequential progression through conversation phases. Use this pattern for workflows with 4 or fewer phases that proceed in a step-by-step manner.

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

## 3. 🎯 WHEN TO USE

| Scenario | Example |
|----------|---------|
| Simple sequential tasks | Step-by-step file updates |
| Straightforward implementations | Adding a single feature |
| Basic request-response workflows | Answer a question, provide solution |
| Bug fixes and patches | Identify, fix, verify |
| Documentation generation | Research, write, format |
| Single-path processes | No branching or concurrency |
| Workflows with ≤ 4 phases | Most common use case |

---

## 4. 🛠️ STYLE GUIDELINES

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

| Element | Rule |
|---------|------|
| **Line 1** | Phase name (left-aligned, 2 spaces from edge) |
| **Lines 2-4** | Activities with bullet points (• character) |
| **Last line** | Duration or timing information |
| **Activity limit** | 2-4 items (3 is ideal) |
| **Text truncation** | Fits within 50 chars per line |

### Flow Connectors

```
                        │
                        ▼
```

- **Vertical pipe**: Centered at column 24
- **Arrow**: Downward triangle at column 24
- **Spacing**: One blank line above and below boxes

### Terminal Boxes

| Type | Description |
|------|-------------|
| **Start** | Rounded corners with centered title |
| **End** | Rounded corners with centered completion message |
| **Width** | Same as process boxes (56 chars) |
| **Centering** | Title centered using space padding |

---

*Related: [workflow_parallel_pattern.md](./workflow_parallel_pattern.md) | [SKILL.md](../SKILL.md)*
