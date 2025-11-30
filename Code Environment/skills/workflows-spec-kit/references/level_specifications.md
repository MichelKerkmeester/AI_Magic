# 📐 Level Specifications - Complete Level 1-3 Requirements

Complete specifications for all three documentation levels (1-3) with detailed requirements, examples, and escalation criteria. Reference this document for comprehensive understanding of when to use each level and what content is expected.

**Note:** Single typo/whitespace fixes (<5 characters in one file) are exempt from spec folder requirements.

---

## 1. 🔵 LEVEL 1: SIMPLE CHANGES (<100 LOC)

### When to Use

- Localized to one component or module
- Includes trivial changes (typos, single-line fixes)
- Clear, well-defined requirements
- Low to moderate complexity
- Minimal dependencies on other systems

### Required Files

- `spec.md` (from `spec.md`)

### Optional Files

- `checklist.md` - When systematic validation needed (QA steps, deployment checks)

### Content Expectations

**spec.md required sections:**
- Problem statement or feature description
- Proposed solution
- Files to change
- Testing approach
- Success criteria

**Length:** Typically 100-200 lines

**checklist.md (if used):**
- Pre-implementation checks
- Implementation validation
- Testing checklist
- Deployment verification

### Example Scenarios

**Good fits for Level 1:**
- Fix "Error" → "Eror" typo
- Update comment for clarity
- Add email validation to contact form
- Fix bug in calculation logic
- Add loading spinner to form submission
- Update error message formatting
- Add new API endpoint (simple CRUD)
- Refactor single component for clarity

**Escalate to Level 2 if:**
- Affects multiple systems (not localized)
- Requires architectural decisions
- Needs complex testing strategy
- Dependencies on other changes
- LOC estimate increases to 100+

### Template Source

`.claude/commands/spec_kit/assets/templates/spec.md`

### Template Adaptation

1. Fill metadata block (created date, status, level, estimated LOC)
2. Replace `[PROBLEM]` with clear problem statement
3. Replace `[SOLUTION]` with proposed approach
4. List specific files to modify
5. Define testing approach (unit tests, manual verification)
6. State clear success criteria
7. Remove all sample content and placeholders

---

## 2. 🟡 LEVEL 2: MODERATE FEATURES (100-499 LOC)

### When to Use

- Multiple files or components affected
- Moderate complexity
- Requires planning and coordination
- Integration considerations across systems

### Required Files

- `spec.md` (from `spec.md`) - What we're building and why
- `plan.md` (from `plan.md`) - How we'll build it

### Optional Files

- `tasks.md` - After plan.md, before coding (breaks plan into actionable tasks)
- `checklist.md` - When systematic validation needed (QA, security review)
- `research-spike-[name].md` - Before implementation if research needed
- `decision-record-[name].md` - For significant technical decisions

### Content Expectations

**spec.md required sections:**
- Detailed requirements
- Technical approach
- Alternatives considered
- Success criteria
- Risks and mitigations
- Out of scope items

**Length:** Typically 300-500 lines

**plan.md required sections:**
- Implementation steps (ordered)
- File changes breakdown
- Testing strategy
- Rollout plan
- Dependencies

**Length:** Typically 200-400 lines

**tasks.md (if used):**
- Task breakdown from plan
- Dependencies between tasks
- Estimated effort per task
- Task ownership (if multi-person)

**checklist.md (if used):**
- Pre-implementation validation
- Per-task verification
- Integration testing steps
- Security review checklist
- Deployment verification

**research-spike-[name].md (if used):**
- Research question
- Approach and experiments
- Findings and recommendations
- Decision (go/no-go)
- Time-boxed (1-3 days typically)

**decision-record-[name].md (if used):**
- Context and problem
- Options considered
- Decision made
- Rationale
- Consequences and trade-offs

### Example Scenarios

**Good fits for Level 2:**
- Create reusable modal component with animations
- Implement form validation framework
- Add authentication flow
- Migrate from library A to library B
- Build file upload feature with progress tracking
- Refactor state management approach

**Escalate to Level 3 if:**
- Discover >500 LOC during implementation
- Complexity increases substantially
- Need multiple developers for coordination
- Requires extensive research or research-spikes
- Architectural impact broader than anticipated

### Template Sources

- `.claude/commands/spec_kit/assets/templates/spec.md`
- `.claude/commands/spec_kit/assets/templates/plan.md`
- `.claude/commands/spec_kit/assets/templates/tasks.md`
- `.claude/commands/spec_kit/assets/templates/checklist.md`
- `.claude/commands/spec_kit/assets/templates/research-spike.md`
- `.claude/commands/spec_kit/assets/templates/decision-record.md`

### Template Adaptation

**spec.md:**
1. Fill complete metadata block (category, tags, priority, status, created date)
2. Replace `[FEATURE_NAME]` throughout
3. Fill all functional requirements (FR-001, FR-002, etc.)
4. Document non-functional requirements (performance, usability, etc.)
5. List edge cases and error scenarios
6. Define measurable success criteria
7. Document dependencies and risks
8. Explicitly list out-of-scope items
9. Remove all sample content

**plan.md:**
1. Document architecture decisions
2. Break down implementation into ordered phases
3. List file changes per phase
4. Define testing strategy (unit, integration, E2E)
5. Document rollback plan
6. Identify dependencies (internal and external)
7. Estimate timeline per phase
8. Remove all sample content

---

## 3. 🔴 LEVEL 3: COMPLEX FEATURES (≥500 LOC)

### When to Use

- High complexity
- Multiple systems or components involved
- Requires coordination across teams
- Significant architectural impact

### Process

**Use `/spec_kit:complete` slash command** - it auto-generates all core files.

**Do NOT create Level 3 files manually** - SpecKit handles this automatically.

### Auto-Generated Files

When you run `/spec_kit:complete`, SpecKit creates:

- `spec.md` - Feature specification
- `plan.md` - Implementation plan
- `tasks.md` - Task breakdown
- `research.md` - Research findings
- `data-model.md` - Data structures
- `quickstart.md` - Getting started guide
- `contracts/` - API contracts directory

### Optional Files (Copy Manually)

- `checklist.md` (from `checklist.md`)
- `research-spike-[name].md` (from `research-spike.md`)
- `decision-record-[name].md` (from `decision-record.md`)

### Content Expectations

**SpecKit auto-fills:**
- All required sections based on user input
- Structured requirements
- Detailed implementation plan
- Task dependencies
- Research sections for unknowns
- Data model schemas
- API contracts

**Length:** Typically 500-1500 lines total across all files

**You adapt:**
- Review auto-generated content
- Fill in unknowns flagged by SpecKit
- Add additional decision records if needed
- Add research-spikes for uncertain areas
- Add checklist for systematic validation

### Example Scenarios

**Good fits for Level 3:**
- Major feature implementation (user dashboard with analytics)
- System redesign (payment flow v2)
- Architecture changes (microservices migration)
- Multi-team projects (integration with external systems)
- New product vertical (marketplace feature)
- Performance overhaul (real-time collaboration)

### SpecKit Command

```bash
/spec_kit:complete
```

**SpecKit will prompt for:**
- Feature name
- High-level description
- Key requirements
- Known constraints
- Integration points

**SpecKit then:**
- Creates spec folder
- Generates all core files
- Fills templates with provided info
- Flags unknowns for user input

### Manual Adaptation After SpecKit

1. Review all auto-generated files
2. Fill `[NEEDS CLARIFICATION: ...]` placeholders
3. Add decision records for major technical choices
4. Add research-spikes for uncertain/risky areas
5. Create comprehensive checklist for validation
6. Cross-link all sibling documents
7. Remove any remaining sample content

---

## 4. 🔄 LEVEL MIGRATION

### When Scope Grows During Implementation

If you discover mid-work that scope is larger than anticipated, escalate to higher level:

| From | To | Action | Document |
|------|----|---------| ---------|
| 1 → 2 | Add `plan.md` to same folder | Update level field, add changelog |
| 2 → 3 | Use `/spec_kit:plan` in same folder | Update level field, add changelog |

**Changelog example:**

```markdown
## Change Log
- 2025-11-15: Created as Level 1 (simple feature)
- 2025-11-16: Escalated to Level 2 (discovered architectural changes needed)
  - Added plan.md to document multi-phase approach
  - Estimated LOC increased from 80 to 250
```

**Rules:**
- Keep existing documentation (don't delete lower-level files)
- Update `level:` field in metadata
- Document reason for escalation
- Inform user of level change and implications

### When to Stay at Current Level

**Don't escalate unnecessarily:**
- Minor scope increase (50 → 95 LOC still Level 1)
- Complexity didn't actually increase (just took longer than expected)
- One additional file doesn't change coordination needs

**Stability preferred:**
- Once started, try to stay at chosen level
- Only escalate if genuinely needed
- Inform user before escalating

---

## 5. 📌 STATUS FIELD CONVENTION

Every spec.md should include a status field to track lifecycle:

```yaml
---
title: Feature Name
created: 2025-11-15
status: active  # ← Add this field
level: 2
---
```

### Valid Status Values

| Status | Meaning | When to Use | Reuse Priority |
|--------|---------|-------------|----------------|
| `draft` | Planning phase | Initial spec creation, not started | 2 (can start) |
| `active` | Work in progress | Currently implementing | 1 (highest - continue here) |
| `paused` | Temporarily on hold | Blocked or deprioritized | 3 (can resume) |
| `complete` | Implementation finished | Feature deployed and stable | 4 (avoid reopening) |
| `archived` | Historical record | Deprecated or superseded | 5 (do not reuse) |

### Status Lifecycle

```
draft → active → complete → archived
   ↓       ↓
paused  paused
   ↓
active (resume)
```

**Update status as work progresses:**
- Create spec → `draft`
- Start implementation → `active`
- Blocked/paused → `paused`
- Deployment complete → `complete`
- Feature deprecated → `archived`

---

## 6. 🔀 RELATED SPECS: UPDATE VS CREATE

### When to UPDATE Existing Spec

Update an existing spec folder when:

✅ **Iterative development** - Continuing work on same feature across sessions
- Example: Initial implementation → bug fixes → enhancements

✅ **Bug fixes** - Fixing issues in existing implementation
- Example: "Fix alignment bug in markdown-c7-optimizer" → Update markdown-c7-optimizer spec

✅ **Scope escalation** - Work grows beyond original estimate
- Example: Level 1 bug fix → Requires Level 2 refactor → Add plan.md to same folder

✅ **Feature enhancement** - Adding to existing functionality
- Example: "Add dark mode to modal" → Update modal-component spec

✅ **Resuming paused work** - Continuing previously paused implementation
- Example: Spec status: paused → active (add continuation notes)

### When to CREATE New Spec

Create a new spec folder when:

❌ **Distinct feature** - Completely separate functionality
- Example: "markdown-c7-optimizer" ≠ "markdown-validator" (different purposes)

❌ **Different approach** - Alternative implementation strategy
- Example: "hero-animation-css" vs "hero-animation-js" (different approaches)

❌ **Separate user story** - Different requirement or use case
- Example: "user-authentication" ≠ "user-profile" (separate stories)

❌ **Complete redesign** - Starting over with new architecture
- Example: "payment-flow-v2" (complete rewrite of v1)

❌ **Unrelated work** - No connection to existing specs
- Example: "add-search-feature" ≠ "fix-form-validation" (different areas)

### Decision Flowchart

```
User requests modification
    ↓
Extract keywords from request
    ↓
Search existing specs (folder names, titles)
    ↓
    ├─→ No matches found
    │      ↓
    │   Create new spec folder
    │
    └─→ Related specs found
           ↓
        Check status field
           ↓
           ├─→ status: active or draft
           │      ↓
           │   Recommend: UPDATE existing spec
           │   Reason: Work in progress, maintain continuity
           │
           ├─→ status: paused
           │      ↓
           │   ASK user: Resume paused work or create new?
           │   Reason: Context exists, but was stopped intentionally
           │
           └─→ status: complete or archived
                  ↓
               ASK user: Reopen completed work or create new?
               Reason: Feature was finished, ensure not regression
```
