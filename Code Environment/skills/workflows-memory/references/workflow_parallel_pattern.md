# Parallel Workflow Pattern - Concurrent Flowcharts

> Visual patterns for concurrent execution with synchronization points in complex workflows.

---

## 1. 📖 OVERVIEW

The parallel pattern demonstrates concurrent execution of multiple phases with synchronization points. Use this pattern for workflows with more than 4 phases or when tasks can be executed simultaneously.

**Core Principle:** Parallel execution with synchronization points for complex workflows.

### Key Characteristics

| Characteristic      | Description                               |
| ------------------- | ----------------------------------------- |
| **Concurrency**     | Multiple streams execute simultaneously   |
| **Synchronization** | Explicit merge points before continuation |
| **Independence**    | Parallel tasks have no inter-dependencies |
| **Efficiency**      | Reduces total execution time              |

---

## 2. 📊 EXAMPLE: MULTI-FILE REFACTORING

```
╭────────────────────────────────────────────────────────╮
│                  CONVERSATION WORKFLOW                 │
╰────────────────────────────────────────────────────────╯
                        │
                        ▼
┌────────────────────────────────────────────────────────┐
│  Preparation                                           │
│  • Analyzing codebase structure                        │
│  • Identifying target files                             │
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
│  • Validating cross-file changes                        │
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

## 3. 🎯 WHEN TO USE

| Scenario                             | Example                                 |
| ------------------------------------ | --------------------------------------- |
| Concurrent development tasks         | Multiple files edited simultaneously    |
| Multi-file refactoring               | Updating related components in parallel |
| Parallel research and implementation | Investigate while building              |
| Independent feature development      | Features with no dependencies           |
| Distributed problem-solving          | Team work on separate parts             |
| Workflows with > 4 phases            | Complex multi-step processes            |

### Decision Criteria

Choose parallel pattern when:
- Tasks can execute independently without blocking each other
- Total workflow has more than 4 distinct phases
- Multiple resources (files, components) need simultaneous updates
- Time savings justify the complexity of parallel visualization

---

## 4. 🛠️ STRUCTURE

### Parallel Block Template

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
                        │
                        ▼    (All phases complete)
┌────────────────────────────────────────────────────────┐
│  SYNCHRONIZATION POINT                                 │
└────────────────────────────────────────────────────────┘
```

### Essential Components

| Component          | Purpose                              |
| ------------------ | ------------------------------------ |
| **Entry Label**    | Marks start of parallel block        |
| **Branch Lines**   | Visual split into concurrent streams |
| **Parallel Boxes** | Individual task containers           |
| **Merge Lines**    | Reconnect parallel streams           |
| **Sync Point**     | Explicit wait for all streams        |

---

## 5. 📐 STYLE GUIDELINES

### Parallel Phase Boxes

| Property      | Value                                                      |
| ------------- | ---------------------------------------------------------- |
| **Width**     | 20 characters (complete boxes with proper padding)         |
| **Content**   | Full words with proper spacing, no truncation              |
| **Spacing**   | 6 spaces between boxes                                     |
| **Max boxes** | 3 per row (more than 3 creates second row)                 |
| **Padding**   | 2 spaces from left edge, right-aligned with proper borders |

### Synchronization Annotations

| Property     | Value                                          |
| ------------ | ---------------------------------------------- |
| **Location** | Below merge point of parallel branches         |
| **Format**   | `(All phases complete)` or `(All X complete)`  |
| **Spacing**  | Right-aligned with flow (4 spaces after arrow) |

### Section Labels

| Property    | Value                                           |
| ----------- | ----------------------------------------------- |
| **Format**  | Complete box with borders (┌─┐└─┘)              |
| **Width**   | 56 characters (matching standard box width)     |
| **Label**   | UPPERCASE with context info in same box         |
| **Usage**   | Mark entry and exit of parallel blocks          |
| **Padding** | 2 spaces from left edge, proper right alignment |

### Branch Line Characters

| Character | Usage                         |
| --------- | ----------------------------- |
| `┌`       | Top-left corner of branch     |
| `┐`       | Top-right corner (if needed)  |
| `└`       | Bottom-left corner for merge  |
| `┘`       | Bottom-right corner for merge |
| `┼`       | Center intersection point     |
| `─`       | Horizontal connection         |
| `│`       | Vertical connection           |

---

## 6. ✅ VALIDATION

### Checklist for Parallel Flowcharts

| Check | Requirement                                      |
| ----- | ------------------------------------------------ |
| ☐     | Entry label clearly marks parallel section start |
| ☐     | Branch lines properly aligned with center        |
| ☐     | All parallel boxes have equal width (20 chars)   |
| ☐     | 6-space gaps between parallel boxes              |
| ☐     | Maximum 3 boxes per row                          |
| ☐     | Merge lines reconnect all branches               |
| ☐     | Synchronization annotation present               |
| ☐     | Sync point box follows merge                     |
| ☐     | No orphaned branches                             |

### Common Errors to Avoid

| Error                     | Solution                                |
| ------------------------- | --------------------------------------- |
| Unequal box widths        | Use consistent 20-character width       |
| Missing sync point        | Always include explicit synchronization |
| Misaligned branches       | Center the branch structure             |
| Too many parallel streams | Split into multiple rows at 3+          |
| Truncated content         | Abbreviate or use full words            |

---

*Related: [workflow_linear_pattern.md](./workflow_linear_pattern.md) | [SKILL.md](../SKILL.md)*
