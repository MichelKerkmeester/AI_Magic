# Workflow Flowchart - Linear Pattern Example

Demonstrates simple sequential progression through conversation phases.

---

## Use Case: Straightforward Bug Fix Implementation

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
│  Verification                                          │
│  • Running test suite                                  │
│  • Confirming fix works                                │
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

## Key Features Demonstrated

- **Sequential progression**: Step-by-step workflow execution
- **Detailed activities**: Inline breakdown of phase tasks (3 bullets per phase)
- **Timing information**: Duration tracking for each phase
- **Simple flow**: Top-to-bottom without branching
- **Consistent structure**: All phases follow same format
- **Clear progression**: Each phase builds on previous

## When to Use This Pattern

- Simple sequential tasks
- Straightforward feature implementations
- Basic request-response workflows
- Bug fixes and patches
- Documentation generation
- Single-path processes
- Workflows with ≤ 4 phases

## Style Guidelines

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
- **Line 1**: Phase name (left-aligned, 2 spaces from edge)
- **Lines 2-4**: Activities with bullet points (• character)
- **Last line**: Duration or timing information
- **Activity limit**: 2-4 items (3 is ideal)
- **Text truncation**: Fits within 50 chars per line

### Flow Connectors
```
                        │
                        ▼
```
- **Vertical pipe**: Centered at column 24
- **Arrow**: Downward triangle at column 24
- **Spacing**: One blank line above and below boxes

### Terminal Boxes
- **Start**: Rounded corners with centered title
- **End**: Rounded corners with centered completion message
- **Width**: Same as process boxes (56 chars)
- **Centering**: Title centered using space padding