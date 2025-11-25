---
name: create-flowchart
description: This skill creates comprehensive ASCII flowcharts in markdown for visualizing complex workflows, user journeys, system architectures, and decision trees. This skill should be used when documenting processes with multi-path flows, parallel execution, approval gates, and nested processes with clear visual hierarchy.
allowed-tools: [Read, Write, Edit]
version: 1.1.0
---

# Flowchart Creation - Workflow & Process Visualization

Create comprehensive ASCII flowcharts in markdown for visualizing complex workflows, user journeys, system architectures, and decision trees.

**Core principle**: Clarity through visual hierarchy + consistent formatting = comprehensible workflows

---

## 1. 🎯 WHEN TO USE

### Navigation Guide

**This file (SKILL.md)**: Core workflow and usage patterns

**Reference Files**:
- [approval_workflow_loops.md](./references/approval_workflow_loops.md) – Detailed documentation
- [decision_tree_flow.md](./references/decision_tree_flow.md) – Detailed documentation
- [parallel_execution.md](./references/parallel_execution.md) – Detailed documentation
- [simple_workflow.md](./references/simple_workflow.md) – Detailed documentation
- [system_architecture_swimlane.md](./references/system_architecture_swimlane.md) – Detailed documentation
- [user_onboarding.md](./references/user_onboarding.md) – Detailed documentation

**Scripts**:
- [validate.sh](./scripts/validate.sh) – Automation script

### When to Use

### Key Capabilities

**Process Documentation**:
- Multi-path decision flows with branching logic
- Parallel execution blocks with synchronization points
- Hierarchical nested processes and sub-workflows
- Approval gates and validation checkpoints

**Visualization Scenarios**:
- Documenting complex multi-step workflows
- User journey mapping with step-by-step flows
- System architecture and data flow diagrams
- Decision trees with multiple branches
- Showing parallel execution paths and dependencies
- Creating quick reference guides for processes

### When NOT to Use

**Skip this skill when:**
- Simple linear lists (use bullet points instead)
- Code architecture (use mermaid diagrams instead)
- Data models (use ER diagrams instead)
- Interactive/exportable diagrams required
- Very simple 2-3 step processes


---

## 2. 🗂️ REFERENCES

### Core Framework
| Document | Purpose | Key Insight |
|----------|---------|-------------|
| **Create Flowchart - Main Workflow** | Core capability and execution pattern | **Specialized auxiliary tool integration** |

### References
| Document | Purpose | Key Insight |
|----------|---------|-------------|
| **references/simple_workflow.md** | Pattern 1: Linear sequence example | Load for basic top-to-bottom flow patterns |
| **references/decision_tree_flow.md** | Pattern 2: Multi-branch decision example | Load for complex decision trees with multiple paths |
| **references/parallel_execution.md** | Pattern 3: Concurrent tasks example | Load for sync points and parallel execution blocks |
| **references/user_onboarding.md** | Pattern 4: Nested sub-process example | Load for hierarchical workflows with sub-processes |
| **references/approval_workflow_loops.md** | Pattern 5 + Pattern 6 combined example | Load for revision cycles and approval gates |
| **references/system_architecture_swimlane.md** | Swimlane pattern example | Load for layer separation and multi-column diagrams |

### Scripts
| Document | Purpose | Key Insight |
|----------|---------|-------------|
| **scripts/validate.sh** | Flowchart validation automation | Execute to check size and depth warnings |

### Smart Routing Logic

```python
def flowchart_creation_workflow(requirements):
    analysis = analyze_workflow_requirements(requirements)
    step_count = analysis.steps + analysis.decisions + analysis.branches

    if step_count > 40:
        return escalate_split_recommendation(
            reason=f"{step_count} boxes exceeds 40-box limit",
            suggestion="Split into sub-workflows or phases"
        )

    pattern_map = {
        'is_linear_sequence': ('linear', 'simple_workflow.md'),
        'has_decision_branches': ('decision_branch', 'decision_tree_flow.md'),
        'has_parallel_tasks': ('parallel', 'parallel_execution.md'),
        'has_nested_process': ('nested', 'user_onboarding.md'),
        'has_approval_gate': ('approval_gate', 'approval_workflow_loops.md'),
        'has_loop_iteration': ('loop', 'approval_workflow_loops.md'),
        'has_multi_stage': ('pipeline', 'system_architecture_swimlane.md')
    }

    pattern, template_file = next(
        ((p, t) for attr, (p, t) in pattern_map.items() if getattr(analysis, attr)),
        ('combined', None)
    )

    template = load_template(template_file) if template_file else create_combined_template(analysis)

    diagram = build_diagram(pattern, template, requirements)

    validation = validate_readability(diagram, script="validate.sh")
    while not validation.all_paths_clear:
        diagram = refine_layout_labels(diagram, validation.issues, adjust_spacing=True, adjust_alignment=True)
        validation = validate_readability(diagram, script="validate.sh")

    check_box_alignment(diagram)
    validate_decision_labels(diagram)

    return {"status": "complete", "diagram": diagram, "pattern": pattern}
```

---

## 3. 🛠️ HOW IT WORKS

This skill provides reusable flowchart components and 7 core patterns for visualizing complex workflows, user journeys, and system architectures using ASCII art in markdown.

**Workflow**: Select pattern → Build with components → Validate → Document

See reference files for production-ready examples of each pattern.

### Component-Based Design

This skill provides reusable elements for building flowcharts:

**Building Blocks**:
```
Process Box:        Decision Diamond:     Terminal:
┌─────────────┐         ╱──────╲           ╭─────────╮
│   Action    │        ╱ Test?  ╲          │  Start  │
└─────────────┘        ╲        ╱          ╰─────────╯
                        ╲──────╱
```

**Flow Control**:
```
Standard Flow:      Branch:           Parallel:
     │              │   │   │         ┌────┬────┐
     ▼              ▼   ▼   ▼         │    │    │
```

**Advanced Patterns**:
- **Multi-Column Layouts**: Table-like structures for parallel tracks (Frontend | Backend | Database)
- **Swimlane Diagrams**: Responsibility across roles/systems with horizontal dividers
- **Conditional Loops**: Decision diamonds with loop-back arrows for iteration
- **Error Handling**: Nested error handlers with retry logic inside decision branches

See `references/` folder for 6 production-ready examples demonstrating all patterns.

### Creation Workflow

**Process**:
1. **Understand** - Identify all steps, decisions, branches, parallel activities
2. **Choose Pattern** - Select from 7 core patterns (see Pattern Library below)
3. **Build Hierarchy** - Apply consistent spacing, alignment, visual flow
4. **Add Details** - Labels, timing, annotations, role indicators
5. **Review** - Verify all paths, connections, readability

**Validation**:
- All paths lead from start to end?
- Decision outcomes covered?
- Parallel blocks have sync points?
- No ambiguous connections?

### Pattern Library

The skill provides 7 core patterns for building flowcharts. Use the Pattern Selection Guide below to choose the appropriate pattern for your workflow.

#### Pattern Selection Guide

| Need | Pattern | Use Case |
|------|---------|----------|
| Simple sequence | 1: Linear Sequential | Step-by-step without branching |
| Yes/No choice | 2: Decision Branch | Binary or multi-way decisions |
| Simultaneous work | 3: Parallel Execution | Multiple tasks run together |
| Complex subprocess | 4: Nested Sub-Process | Embedded workflows |
| Manual checkpoint | 5: Approval Gate | Review/approval required |
| Repeated action | 6: Loop/Iteration | Until condition met |
| Multi-phase project | 7: Pipeline | Sequential stages with gates |

#### Pattern 1: Linear Sequential Flow

```
╭────────────────────╮
│       Start        │
╰────────────────────╯
         │
         ▼
┌────────────────────┐
│     Step 1         │
└────────────────────┘
         │
         ▼
┌────────────────────┐
│     Step 2         │
└────────────────────┘
         │
         ▼
╭────────────────────╮
│        End         │
╰────────────────────╯
```

#### Pattern 2: Decision Branch

```
┌────────────────────┐
│   Check Status     │
└────────────────────┘
         │
         ▼
    ╱──────────╲
   ╱  Valid?    ╲
   ╲            ╱
    ╲──────────╱
      │      │
    Yes      No
      │      │
      ▼      ▼
  ┌─────┐  ┌─────┐
  │ Pass│  │Reject│
  └─────┘  └─────┘
```

#### Pattern 3: Parallel Execution

```
┌────────────────────┐
│   Trigger Event    │
└────────────────────┘
         │
         ▼
┌───────────────────────────────────────────┐
│  PARALLEL EXECUTION - Stage A             │
└───────────────────────────────────────────┘
         │           │           │
         ▼           ▼           ▼
    ┌────────┐  ┌────────┐  ┌────────┐
    │ Task A │  │ Task B │  │ Task C │
    └────────┘  └────────┘  └────────┘
         │           │           │
         └───────────┼───────────┘
                     ▼
┌────────────────────┐
│    Synthesis       │
└────────────────────┘
```

#### Pattern 4: Nested Sub-Process

```
┌────────────────────────────────────────┐
│  MAIN PROCESS: User Onboarding         │
│  ┌──────────────────────────────────┐  │
│  │  SUB-PROCESS: Account Creation   │  │
│  │  Step 1: Collect Info            │  │
│  │  Step 2: Validate                │  │
│  │  Step 3: Create Account          │  │
│  └──────────────────────────────────┘  │
└────────────────────────────────────────┘
         │
         ▼
┌────────────────────┐
│  Next Main Step    │
└────────────────────┘
```

#### Pattern 5: Approval Gate

```
┌────────────────────┐
│  Prepare Review    │
└────────────────────┘
         │
         ▼
┌────────────────────┐
│ ⚠️  APPROVAL GATE  │
│  Review Required   │
└────────────────────┘
    │         │
 Approve   Reject
    │         │
    ▼         ▼
┌───────┐  ┌───────┐
│Proceed│  │Revise │
└───────┘  └───────┘
```

#### Pattern 6: Loop/Iteration

```
┌────────────────────┐
│  Initialize        │
└────────────────────┘
         │
         ▼
    ╱──────────╲
   ╱  Complete?  ╲
   ╲            ╱
    ╲──────────╱
      │      │
     Yes     No
      │      │
      │      └──────┐
      ▼             ▼
  ┌─────┐    ┌──────────┐
  │ End │    │ Process  │
  └─────┘    │ Item     │
             └──────────┘
                  │
                  └────────┘ Loop back
```

#### Pattern 7: Multi-Stage Pipeline

```
┌──────────┐     ┌──────────┐     ┌──────────┐
│ Stage 1  │────▶│ Stage 2  │────▶│ Stage 3  │
│ Planning │     │  Build   │     │  Deploy  │
└──────────┘     └──────────┘     └──────────┘
     │                │                │
     ▼                ▼                ▼
  [Gate 1]        [Gate 2]        [Gate 3]
```

---

## 4. 📖 RULES

### ✅ ALWAYS 

**ALWAYS do these without asking:**

1. **ALWAYS use consistent box styles throughout**
   - Standard process: `┌─────┐` single-line boxes
   - Terminals: `╭─────╮` rounded corners for start/end
   - Decisions: `╱─────╲` diamond shape
   - Maintains visual consistency and readability

2. **ALWAYS label all decision branches**
   - Show Yes/No, Approve/Reject, or specific outcomes
   - Never leave paths unlabeled or assume they're obvious
   - Prevents ambiguity in workflow understanding

3. **ALWAYS align elements vertically or horizontally**
   - Maintains clean visual flow
   - Stick to vertical/horizontal lines (no diagonals)
   - Use consistent spacing (single blank line between steps)

4. **ALWAYS show complete paths from start to end**
   - Every box must have entry and exit points
   - No orphaned processes
   - All parallel blocks must converge to sync points

5. **ALWAYS validate readability**
   - Test at different zoom levels
   - Verify arrows connect correctly
   - Check that any path can be traced start to end

### ❌ NEVER 

**NEVER do these:**

1. **NEVER create ambiguous arrow connections**
   - Bad: Multiple paths merging without explicit merge point
   - Good: Show explicit merge with aligned arrows
   - Always align arrows clearly and merge paths explicitly

2. **NEVER leave decision outcomes unlabeled**
   - Every decision branch must show all possible outcomes
   - Missing labels create confusion
   - Label paths: Yes/No, Success/Failure, Valid/Invalid

3. **NEVER overcrowd a single diagram**
   - Break diagrams with >40 boxes into multiple views
   - Use nested sub-processes for complexity
   - Split into separate diagrams with clear transitions

4. **NEVER mix box styles inconsistently**
   - Use standard boxes for processes throughout
   - Reserve rounded boxes for terminals only
   - Decisions always use diamond shape
   - Use emoji within boxes for importance (⚠️ ✅ 🔒) not box style changes

5. **NEVER skip spacing and alignment**
   - Inconsistent spacing makes flow hard to follow
   - Poor alignment creates visual confusion
   - Use single blank line between simple steps, double for major sections

### ⚠️ ESCALATE IF

**Ask user when:**

1. **ESCALATE IF process exceeds ~30-40 boxes**
   - Diagram too complex for single view
   - Needs breakdown into multiple diagrams
   - Consider nested sub-processes or separate views

2. **ESCALATE IF interactive/exportable format needed**
   - ASCII flowcharts are text-based only
   - Suggest mermaid diagrams or design tools
   - Cannot provide animation or interactivity

3. **ESCALATE IF collaborative editing required**
   - Multiple stakeholders need to edit simultaneously
   - ASCII format has limitations for collaboration
   - Recommend dedicated diagramming tools

---

## 5. 🎓 SUCCESS CRITERIA

### Flowchart Complete When

**Quality checklist**:
- ✅ All paths from start to end are clear
- ✅ Decisions have labeled outcomes
- ✅ Parallel processes clearly marked with sync points
- ✅ Approval gates visually distinct (⚠️ marker)
- ✅ Spacing and alignment consistent throughout
- ✅ Can be understood without verbal explanation
- ✅ Matches actual process accurately
- ✅ Visual hierarchy supports comprehension

### Validation Questions

**Can answer YES to all?**
- Can a new person follow any path?
- Are all decision points exhaustive?
- Do parallel blocks resolve properly?
- Is timing/context provided where needed?
- Does visual hierarchy aid understanding?

---

## 6. 🔗 INTEGRATION POINTS

### Reference Examples

**Production-ready examples** in `references/` directory:

| File | Pattern | Complexity | Key Features |
|------|---------|------------|--------------|
| simple_workflow.md | Linear | Low | Basic top-to-bottom flow |
| parallel_execution.md | Parallel | Medium-High | Concurrent tasks, sync points |
| user_onboarding.md | Nested | High | Sub-processes, celebrations |
| decision_tree_flow.md | Decision Branch | High | Multiple decisions, error handling |
| approval_workflow_loops.md | Loop + Approval | High | Revision cycles, escalation |
| system_architecture_swimlane.md | Swimlane | High | Layer separation, integration |

### Tool Usage

**Read**: Load reference examples for pattern guidance

**Write**: Create new flowchart markdown files

**Edit**: Modify existing flowcharts

### Related Skills

**Pairs with**:
- **git-worktrees** - Documenting branch strategies
- **workflows-git** - Process visualization for Git workflows
- **Project documentation** - Process guides and READMEs

---

## 7. 🔧 TROUBLESHOOTING

### Flowchart Too Complex

**Symptom**: Diagram hard to follow, deeply nested, or >200 lines

**Solutions**:
1. **Split into multiple diagrams** - One per major workflow or decision tree
2. **Use swimlanes** - Separate parallel processes horizontally
3. **Abstract details** - Reference other docs for implementation specifics
4. **Run validator**: Use `scripts/validate.sh` to get size/depth warnings

### Box Alignment Issues

**Symptom**: Boxes don't line up, borders misaligned

**Solutions**:
1. **Use monospace font** - Required for proper rendering
2. **Count dashes** - All box tops/bottoms should have same dash count
3. **Check spaces** - Indentation must be consistent (2 spaces per level)
4. **Copy from templates** - Use reference examples as starting point

### Arrows Not Connecting

**Symptom**: Arrows don't visually connect to boxes

**Solutions**:
1. **Verify spacing** - Arrows must align with box centers
2. **Use tree branches** - `├─` and `└─` for hierarchical connections
3. **Check patterns** - See Section 3 (HOW IT WORKS) for correct arrow patterns
4. **Validate**: Run `scripts/validate.sh` for broken arrow detection

### Rendering Issues in Markdown Viewers

**Symptom**: Flowchart looks broken in GitHub/editors

**Solutions**:
1. **Use fenced code blocks** - Wrap in ` ```text ` blocks
2. **Avoid emoji in boxes** - Can break alignment in some renderers
3. **Test in target viewer** - Render may vary between platforms
4. **Stick to basic Unicode** - Use standard box-drawing characters only

**Need more help?** See [RULES section](#4--rules) for anti-patterns and best practices

---

**Remember**: This skill operates as a visualization engine for complex processes. It transforms abstract logic into clear, hierarchical ASCII flowcharts for better understanding.