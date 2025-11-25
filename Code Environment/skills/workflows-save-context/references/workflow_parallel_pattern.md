# Workflow Flowchart - Parallel Pattern Example

Demonstrates concurrent execution of multiple phases with synchronization points.

---

## Use Case: Multi-File Refactoring with Parallel Tasks

```
╭────────────────────────────────────────────────────────╮
│                  CONVERSATION WORKFLOW                 │
╰────────────────────────────────────────────────────────╯
                        │
                        ▼
┌────────────────────────────────────────────────────────┐
│  Preparation                                           │
│  • Analyzing codebase structure                        │
│  • Identifying target files                            │
│  Duration: 3 minutes                                   │
└────────────────────────────────────────────────────────┘
                        │
                        ▼
┌────────────────────────────────────────────────────────┐
│  PARALLEL EXECUTION - 3 concurrent phases              │
└────────────────────────────────────────────────────────┘
                        │
            ┌───────────────────────────┼───────────────────────────┐
            │                           │                           │
            ▼                           ▼                           ▼
┌────────────────────┐      ┌────────────────────┐      ┌────────────────────┐
│  Component Files   │      │   Utility Files    │      │    Types Files     │
│                    │      │                    │      │                    │
│  • Update API      │      │  • Refactor helper │      │  • Update interfac │
│  • Add tests       │      │  • Add docs        │      │  • Add generics    │
│                    │      │                    │      │                    │
│  Duration: 8 min   │      │  Duration: 6 min   │      │  Duration: 4 min   │
└────────────────────┘      └────────────────────┘      └────────────────────┘
            │                           │                           │
            │                           │                           │
            └───────────────────────────┼───────────────────────────┘
                        │
                        ▼    (All phases complete)
┌────────────────────────────────────────────────────────┐
│  SYNCHRONIZATION POINT                                 │
└────────────────────────────────────────────────────────┘
                        │
                        ▼
┌────────────────────────────────────────────────────────┐
│  Integration & Testing                                 │
│  • Running integration tests                           │
│  • Validating cross-file changes                       │
│  • Checking type consistency                           │
│  Duration: 4 minutes                                   │
└────────────────────────────────────────────────────────┘
                        │
                        ▼
╭────────────────────────────────────────────────────────╮
│                    WORKFLOW COMPLETE                   │
╰────────────────────────────────────────────────────────╯
```

---

## Key Features Demonstrated

- **Parallel execution**: Multiple phases running concurrently
- **Synchronization points**: Coordination between parallel streams
- **Section labels**: Complete boxes marking parallel block boundaries
- **Sync annotations**: "(All phases complete)" markers
- **Complete side-by-side boxes**: 20-char width for parallel tasks with full borders
- **Detailed timing**: Duration for each concurrent phase
- **Branch visualization**: Tree-like structure showing splits and merges

## When to Use This Pattern

- Concurrent development tasks
- Multi-file refactoring
- Parallel research and implementation
- Independent feature development
- Distributed problem-solving
- Any workflow with > 4 phases

## Style Guidelines

### Parallel Block Structure
```
┌────────────────────────────────────────────────────────┐
│  SECTION LABEL - Context information                   │
└────────────────────────────────────────────────────────┘
                        │
            ┌───────────────────────────┼───────────────────────────┐
            │                           │                           │
            ▼                           ▼                           ▼
┌────────────────────┐      ┌────────────────────┐      ┌────────────────────┐
│  Complete Box 1    │      │  Complete Box 2    │      │  Complete Box 3    │
│                    │      │                    │      │                    │
│  • Activity 1      │      │  • Activity 1      │      │  • Activity 1      │
│  • Activity 2      │      │  • Activity 2      │      │  • Activity 2      │
│                    │      │                    │      │                    │
│  Duration: X min   │      │  Duration: X min   │      │  Duration: X min   │
└────────────────────┘      └────────────────────┘      └────────────────────┘
            │                           │                           │
            └───────────────────────────┼───────────────────────────┘
```

### Parallel Phase Boxes
- **Width**: 20 characters (complete boxes with proper padding)
- **Content**: Full words with proper spacing, no truncation
- **Spacing**: 6 spaces between boxes
- **Max boxes**: 3 per row (more than 3 creates second row)
- **Padding**: 2 spaces from left edge, right-aligned with proper borders

### Synchronization Annotations
- **Location**: Below merge point of parallel branches
- **Format**: `(All phases complete)` or `(All X complete)`
- **Spacing**: Right-aligned with flow (4 spaces after arrow)

### Section Labels
- **Format**: Complete box with borders (┌─┐└─┘)
- **Width**: 56 characters (matching standard box width)
- **Label**: UPPERCASE with context info in same box
- **Usage**: Mark entry and exit of parallel blocks
- **Padding**: 2 spaces from left edge, proper right alignment