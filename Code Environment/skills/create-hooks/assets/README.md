# Assets Directory

This directory contains reference data, templates, examples, and lookup tables that support the skill's functionality.

## Purpose

Assets provide copy-paste templates, code examples, and reference data that users can apply directly without needing to construct from scratch.

## Common Asset Types

### 📝 Templates (`*_templates.md`)
- Copy-paste starting points for common tasks
- Configuration files, code snippets, document structures
- Include field descriptions and complete examples

### 📊 References (`*_reference.md`)
- Lookup tables, decision matrices, classification systems
- Quick reference data (emoji mappings, naming conventions)
- Standards and specifications

### 💡 Examples (`*_examples.md`)
- Working examples of skill outputs
- Before/after comparisons
- Common patterns and anti-patterns

### 🎓 Guides (`*_guide.md`)
- Step-by-step guides for complex processes
- Troubleshooting documentation
- Integration instructions

## Naming Conventions

- Format: `[topic]_[type].md`
- Use underscores (not hyphens)
- Lowercase only
- Examples: `frontmatter_templates.md`, `validation_reference.md`

## Template

Use `hook_asset_template.md` as a starting point when creating new hook example documentation. This template provides:
- Asset information and metadata
- Overview with use case and key patterns
- Complete hook structure breakdown
- Testing scenarios and validation
- Integration points and common patterns
- Security and performance considerations
- Troubleshooting guidance

Use `hook_reference_template.md` when creating new reference documentation files.

## File Inventory

| File | Type | Purpose | Version | Last Updated |
|------|------|---------|---------|--------------|
| **hook_template.sh** | Template | Base template with all required sections (header, validation, main logic) | 1.0.0 | 2025-01-24 |
| **precompact_example.sh** | Example | Production PreCompact hook demonstrating context preservation workflow | 1.0.0 | 2025-01-24 |
| **userpromptssubmit_example.sh** | Example | Keyword detection and auto-trigger pattern | 1.0.0 | 2025-01-24 |
| **pretooluse_example.sh** | Example | Validation hook with blocking capability | 1.0.0 | 2025-01-24 |
| **posttooluse_example.sh** | Example | Auto-fix and formatting pattern | 1.0.0 | 2025-01-24 |
| **premessagecreate_example.sh** | Example | Response context validation and logging hook | 1.0.0 | 2025-11-25 |
| **postmessagecreate_example.sh** | Example | Response metrics collection hook | 1.0.0 | 2025-11-25 |
| **presessionstart_example.sh** | Example | Session initialization and state setup hook | 1.0.0 | 2025-11-25 |
| **postsessionend_example.sh** | Example | Session cleanup and archival hook | 1.0.0 | 2025-11-25 |
| **hook_asset_template.md** | Template | Template for creating new hook asset documentation | 1.0.0 | 2025-01-24 |
| **hook_reference_template.md** | Template | Template for creating new reference documentation | 1.0.0 | 2025-01-24 |

---

**Directory Version**: 1.1.0
**Last Updated**: 2025-11-25
**Maintained By**: Claude Code AI Documentation
