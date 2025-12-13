# Path-Scoped Rules

> **STATUS: NOT YET IMPLEMENTED**
> This document describes a FUTURE capability for context-aware rule enforcement.
> Currently, rules are applied uniformly. This serves as a design document.

---

## 1. Overview

Path-scoped rules would enable differentiated enforcement based on:
- File location (scratch/, memory/, templates/)
- Documentation level (1/2/3)
- File type (spec.md, decision-record.md, etc.)

### Why This Matters

| Scenario | Without Scoping | With Scoping |
|----------|-----------------|--------------|
| scratch/ prototypes | Full validation blocks | Minimal validation |
| Level 3 decision record | Same as notes | ADR-specific checks |
| Template files | Placeholder errors | Exempt from content validation |

---

## 2. Proposed Rule Hierarchy

```
GLOBAL RULES (always apply)
    ↓
LEVEL RULES (by documentation level)
    ↓
PATH RULES (by file pattern)
    ↓
OVERRIDE RULES (explicit exemptions)
```

---

## 3. Proposed Path Patterns

### By Directory

| Pattern | Proposed Behavior |
|---------|-------------------|
| `**/scratch/**` | Skip all validation |
| `**/memory/**` | Minimal validation |
| `.opencode/speckit/templates/**` | Skip content validation |
| `specs/*/spec.md` | Level-appropriate validation |

### By Level

| Level | Proposed Checks |
|-------|-----------------|
| 1 | Basic placeholder check, core sections |
| 2 | + Priority tags required, verification items |
| 3 | + Alternatives analysis, methodology, evidence |

---

## 4. Current Workarounds

Until implemented, use:

**Manual selection:**
```markdown
<!-- Agent instruction -->
When editing scratch/ files, skip validation.
```

**Environment variable:**
```bash
SPECKIT_SKIP_VALIDATION=true ./script.sh
```

---

## 5. Future Implementation

When implemented, would support:

1. **Real-time validation** - IDE integration
2. **Rule cascade** - Inherit from parent paths
3. **Custom severity** - Project overrides
4. **Autofix** - Automatic corrections

### Proposed Configuration

```yaml
# Future .speckit.yaml
path_rules:
  enabled: true
  patterns:
    - path: "**/scratch/**"
      rules: none
    - path: "specs/*/decision-record*.md"
      rules: level3_strict
```

---

## 6. Related Files

- [level_specifications.md](level_specifications.md) - Level requirements
- [automation_workflows.md](automation_workflows.md) - Current enforcement
