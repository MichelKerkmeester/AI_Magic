# 📚 Knowledge Base File Templates - Creation Guide

Comprehensive templates and guidelines for creating effective knowledge base files in `.claude/knowledge/` directory. These templates provide complete scaffolds for documenting technical patterns, standards, and reference material.

---

## 1. 📖 INTRODUCTION & TEMPLATE SELECTION

### Purpose of Knowledge Files

Knowledge files document technical patterns, standards, constraints, and reference material that Claude Code needs to access during development. A well-crafted knowledge file:

- **Provides context** for architectural decisions and patterns
- **Documents constraints** of platforms, tools, and frameworks
- **Captures standards** for code quality, naming, and structure
- **Serves as reference** for common patterns and best practices

### When to Create Knowledge Files

**Create a knowledge file when:**
- Documenting platform-specific constraints (e.g., Webflow limitations)
- Capturing code standards and conventions
- Recording architectural patterns used across the project
- Providing reference material for tools, frameworks, or APIs
- Explaining initialization patterns, animation strategies, etc.

**DO NOT create knowledge file when:**
- Documenting a specific skill workflow → Use `references/` in skill folder
- Implementing a feature → Use spec files in `specs/` directory
- Creating reusable commands → Use `.claude/commands/`
- Writing project documentation → Use README files

### Knowledge File Characteristics

**Target audience**: Claude Code AI agent
**Target size**: 200-500 lines (can be longer for comprehensive references)
**Enforcement level**: Moderate (structural violations will block)
**Quality target**: 85+ overall score

**Common knowledge file topics**:
- Code standards and naming conventions
- Platform constraints (Webflow, browser APIs, etc.)
- Initialization patterns and lifecycle management
- Animation strategies and performance patterns
- MCP tool usage and integration patterns
- Build system configuration and tooling

---

## 2. 🎯 KNOWLEDGE FILE STRUCTURE REQUIREMENTS

### Critical Structural Rules

**FORBIDDEN**:
- ❌ **NO YAML frontmatter** (knowledge files must not have `---` metadata blocks)
- ❌ **NO multiple H1 headers** (exactly one H1 allowed)
- ❌ **NO unnumbered H2 sections** (all H2 must start with number)
- ❌ **NO lowercase H2 headings** (all H2 must be ALL CAPS)
- ❌ **NO emojis in H3/H4** (emojis only allowed in H2)

**REQUIRED**:
- ✅ **H1 with subtitle** format: `# Topic Name - Descriptive Subtitle`
- ✅ **H2 numbered + emoji + ALL CAPS** format: `## 1. 🎯 SECTION NAME`
- ✅ **H3 in Title Case** format: `### Subsection Name` (no numbers, no emoji)
- ✅ **Section separators** between H2 sections: `---`

### Enforcement Levels by Element

| Element            | Rule        | Enforcement | Violation Consequence              |
| ------------------ | ----------- | ----------- | ---------------------------------- |
| YAML frontmatter   | Forbidden   | Blocking    | File rejected, manual fix required |
| H1 subtitle        | Required    | Blocking    | File rejected, manual fix required |
| H2 numbering       | Required    | Blocking    | File rejected, manual fix required |
| H2 ALL CAPS        | Required    | Blocking    | File rejected, manual fix required |
| H2 emoji           | Required    | Warning     | File accepted, fix recommended     |
| H3 Title Case      | Recommended | Advisory    | File accepted, no action required  |
| Section separators | Recommended | Advisory    | File accepted, no action required  |

### Valid vs. Invalid Examples

**❌ INVALID - Has frontmatter (forbidden)**:
```markdown
---
title: Code Standards
---

# Code Standards - Naming and Structure
```

**✅ VALID - No frontmatter**:
```markdown
# Code Standards - Naming and Structure
```

**❌ INVALID - H1 missing subtitle**:
```markdown
# Code Standards
```

**✅ VALID - H1 with subtitle**:
```markdown
# Code Standards - Naming and Structure
```

**❌ INVALID - H2 not numbered**:
```markdown
## CORE PRINCIPLES
```

**✅ VALID - H2 numbered**:
```markdown
## 1. 🎯 CORE PRINCIPLES
```

**❌ INVALID - H2 not ALL CAPS**:
```markdown
## 1. 🎯 Core Principles
```

**✅ VALID - H2 ALL CAPS**:
```markdown
## 1. 🎯 CORE PRINCIPLES
```

**❌ INVALID - H3 with emoji or number**:
```markdown
### 1.1 🔧 Function Naming
```

**✅ VALID - H3 Title Case, no emoji**:
```markdown
### Function Naming
```

---

## 3. 📝 COMPLETE KNOWLEDGE FILE TEMPLATE

### Standard Knowledge File Template

```markdown
# Topic Name - Descriptive Subtitle

Brief introduction paragraph (2-4 sentences) explaining:
- What this knowledge file covers
- Why this information is important for Claude Code
- When Claude should reference this file
- Scope and limitations of the content

---

## 1. 🎯 PRIMARY CONCEPT

Main concept explanation goes here. This section introduces the core topic and provides foundational understanding.

### Key Characteristics

- Characteristic 1: Explanation
- Characteristic 2: Explanation
- Characteristic 3: Explanation

### Core Principles

**Principle 1 Name**:
Detailed explanation of the first core principle...

**Principle 2 Name**:
Detailed explanation of the second core principle...

### When to Apply

**Use this approach when:**
- Condition 1
- Condition 2
- Condition 3

**Avoid this approach when:**
- Anti-pattern 1
- Anti-pattern 2
- Anti-pattern 3

---

## 2. 🔧 IMPLEMENTATION DETAILS

Technical implementation guidance and patterns.

### Pattern Overview

Description of the implementation pattern...

**Example**:
```javascript
// Code example showing the pattern
function examplePattern() {
  // Implementation details
}
```

### Required Components

**Component 1**:
- Purpose: What it does
- Requirements: What it needs
- Integration: How it connects

**Component 2**:
- Purpose: What it does
- Requirements: What it needs
- Integration: How it connects

### Integration Points

Description of how this integrates with other systems...

---

## 3. 📋 STANDARDS AND REQUIREMENTS

Mandatory standards and requirements that must be followed.

### Naming Conventions

**Rule 1**:
- Format: Specific format description
- Examples: Valid examples
- Counter-examples: Invalid examples

**Rule 2**:
- Format: Specific format description
- Examples: Valid examples
- Counter-examples: Invalid examples

### Code Structure

**Requirement 1**:
Detailed description with examples...

**Requirement 2**:
Detailed description with examples...

### Validation Rules

- ✅ Valid pattern 1
- ✅ Valid pattern 2
- ❌ Invalid pattern 1
- ❌ Invalid pattern 2

---

## 4. ⚠️ CONSTRAINTS AND LIMITATIONS

Platform-specific constraints, technical limitations, and workarounds.

### Platform Constraints

**Constraint 1**:
- Description: What the limitation is
- Impact: How it affects implementation
- Workaround: How to handle it

**Constraint 2**:
- Description: What the limitation is
- Impact: How it affects implementation
- Workaround: How to handle it

### Technical Limitations

**Limitation 1**:
Explanation and mitigation strategy...

**Limitation 2**:
Explanation and mitigation strategy...

### Common Pitfalls

**Pitfall 1**: Description
- **Symptom**: How to recognize it
- **Cause**: Why it happens
- **Fix**: How to resolve it

**Pitfall 2**: Description
- **Symptom**: How to recognize it
- **Cause**: Why it happens
- **Fix**: How to resolve it

---

## 5. 💡 BEST PRACTICES

Recommended approaches and optimization strategies.

### Performance Optimization

**Practice 1**:
Description and rationale...

**Practice 2**:
Description and rationale...

### Maintainability

**Practice 1**:
Description and rationale...

**Practice 2**:
Description and rationale...

### Security Considerations

**Practice 1**:
Description and rationale...

**Practice 2**:
Description and rationale...

---

## 6. 🔗 REFERENCES

### Internal Documentation

- [Related Knowledge File](./related_file.md)
- [Skill Reference](./../skills/skill-name/SKILL.md)
- [Project Documentation](../../docs/topic.md)

### External Resources

- External documentation link 1
- External documentation link 2
- API reference links

### Related Patterns

- Related pattern 1
- Related pattern 2

---

## 4. 🔧 SECTION-BY-SECTION CONTENT GUIDANCE

### Section 1: Primary Concept

**Purpose**: Introduce the core topic and establish foundational understanding

**Required content**:
- Core concept definition
- Key characteristics or properties
- When to apply vs. avoid
- Relationship to other concepts

**Length**: 150-300 lines
**Critical for**: Establishing context and scope

**Common mistakes**:
- Too abstract without concrete examples
- Missing the "when to apply" guidance
- Assuming prior knowledge

### Section 2: Implementation Details

**Purpose**: Provide technical patterns and implementation guidance

**Required content**:
- Concrete code examples
- Pattern descriptions with syntax
- Integration points and dependencies
- Component breakdowns

**Length**: 100-250 lines
**Critical for**: Practical application of concepts

**Common mistakes**:
- Examples without explanation
- Missing error handling patterns
- No integration context

### Section 3: Standards and Requirements

**Purpose**: Define mandatory rules and conventions

**Required content**:
- Naming conventions with examples
- Code structure requirements
- Validation rules (✅ valid, ❌ invalid)
- Enforcement mechanisms

**Length**: 100-200 lines
**Critical for**: Ensuring consistency and compliance

**Common mistakes**:
- Vague requirements
- Missing counter-examples
- No validation guidance

### Section 4: Constraints and Limitations

**Purpose**: Document platform constraints and technical limitations

**Required content**:
- Platform-specific constraints
- Technical limitations
- Workarounds and mitigation strategies
- Common pitfalls with fixes

**Length**: 100-200 lines
**Critical for**: Avoiding implementation problems

**Common mistakes**:
- Listing constraints without workarounds
- Missing impact assessment
- No symptom descriptions for pitfalls

### Section 5: Best Practices

**Purpose**: Share optimization strategies and recommended approaches

**Required content**:
- Performance optimization techniques
- Maintainability patterns
- Security considerations
- Quality improvement strategies

**Length**: 80-150 lines
**Critical for**: Producing high-quality implementations

**Common mistakes**:
- Generic advice without context
- Best practices without rationale
- Missing performance implications

### Section 6: References

**Purpose**: Link to related documentation and external resources

**Required content**:
- Internal documentation links
- External resource links
- Related patterns and skills
- API references

**Length**: 30-50 lines
**Critical for**: Navigation and further learning

**Common mistakes**:
- Broken links
- Missing context for external resources
- No categorization of references

---

## 5. ✅ BEST PRACTICES & COMMON PITFALLS

### Best Practices

**1. No Frontmatter Rule**
- ✅ Knowledge files MUST NOT have YAML frontmatter
- ✅ Use inline metadata if needed (e.g., status badges)
- ❌ Never add `---` delimited metadata blocks

**2. H1 Subtitle Requirement**
- ✅ Always use format: `# Topic - Subtitle`
- ✅ Make subtitle descriptive and specific
- ❌ Never use single-word titles without subtitle

**3. H2 Numbering and Formatting**
- ✅ Number all H2 sections sequentially (1, 2, 3...)
- ✅ Use ALL CAPS for H2 text
- ✅ Include relevant emoji at start
- ✅ Format: `## 1. 🎯 SECTION NAME`

**4. H3 Subsection Formatting**
- ✅ Use Title Case (capitalize major words)
- ✅ No numbers or emojis in H3
- ✅ Keep focused on single subtopic

**5. Progressive Detail**
- ✅ Start broad in H2, get specific in H3/H4
- ✅ Use examples throughout
- ✅ Include both valid and invalid patterns

**6. Code Examples**
- ✅ Show complete, working examples
- ✅ Add comments explaining key parts
- ✅ Include both good and bad examples


### Common Pitfalls

**1. Frontmatter Violation**
- ❌ **Mistake**: Adding YAML frontmatter like SKILL.md files
- ✅ **Fix**: Remove all `---` delimited blocks at file start
- **Impact**: Blocking error, file will be rejected

**2. Missing H1 Subtitle**
- ❌ **Mistake**: Using `# Topic Name` without subtitle
- ✅ **Fix**: Add ` - Subtitle` to H1: `# Topic - Subtitle`
- **Impact**: Blocking error, file will be rejected

**3. Unnumbered H2 Sections**
- ❌ **Mistake**: `## SECTION NAME` without number
- ✅ **Fix**: Add sequential number: `## 1. 🎯 SECTION NAME`
- **Impact**: Blocking error, file will be rejected

**4. Lowercase H2 Text**
- ❌ **Mistake**: `## 1. 🎯 Section Name` in Title Case
- ✅ **Fix**: Convert to ALL CAPS: `## 1. 🎯 SECTION NAME`
- **Impact**: Blocking error, file will be rejected

**5. Emojis in H3/H4**
- ❌ **Mistake**: `### 🔧 Subsection Name`
- ✅ **Fix**: Remove emoji: `### Subsection Name`
- **Impact**: Warning, file accepted but needs cleanup

**6. Multiple H1 Headers**
- ❌ **Mistake**: Using multiple H1 headers in one file
- ✅ **Fix**: Use only one H1, rest should be H2/H3/H4
- **Impact**: Blocking error, file will be rejected

**7. Skipping Heading Levels**
- ❌ **Mistake**: Jumping from H2 to H4 directly
- ✅ **Fix**: Use proper nesting: H2 → H3 → H4
- **Impact**: Advisory warning, file accepted

**8. Too Abstract Without Examples**
- ❌ **Mistake**: Explaining concepts without code examples
- ✅ **Fix**: Include concrete examples with annotations
- **Impact**: Reduces effectiveness, no technical violation

**9. Missing Constraints Section**
- ❌ **Mistake**: Documenting patterns without limitations
- ✅ **Fix**: Always include constraints and workarounds
- **Impact**: Incomplete documentation, leads to errors

**10. Broken Cross-References**
- ❌ **Mistake**: Links to files that don't exist or moved
- ✅ **Fix**: Verify all links before committing
- **Impact**: Navigation broken, reduces usability

---

## 6. 🔍 QUALITY CHECKLIST & QUICK REFERENCE

### Pre-Commit Validation Checklist

**Structural Requirements**:
- [ ] NO YAML frontmatter (file must not start with `---`)
- [ ] H1 has subtitle format: `# Topic - Subtitle`
- [ ] Exactly ONE H1 header (no more, no less)
- [ ] All H2 sections numbered sequentially (1, 2, 3...)
- [ ] All H2 sections in ALL CAPS
- [ ] All H2 sections have relevant emoji
- [ ] H3 subsections use Title Case (no numbers, no emojis)
- [ ] Section separators (`---`) between H2 sections
- [ ] No skipped heading levels (H2 → H3 → H4, not H2 → H4)

**Content Requirements**:
- [ ] Introduction paragraph explains purpose and scope
- [ ] Code examples are complete and working
- [ ] Both valid (✅) and invalid (❌) patterns shown
- [ ] Constraints section documents platform limitations
- [ ] Best practices include rationale
- [ ] References section links to related docs
- [ ] All internal links verified and working

**Quality Standards**:
- [ ] Target length: 200-500 lines (can exceed for comprehensive refs)
- [ ] Examples have explanatory comments
- [ ] Subsections focused on single topics
- [ ] Progressive detail (broad → specific)
- [ ] No assumed knowledge without context

### Quick Reference: H2 Emoji Standards

Use relevant emojis for knowledge file H2 sections:

```
PRIMARY/CORE CONCEPTS     → 🎯
TECHNICAL/TOOLS           → 🔧
LISTS/REQUIREMENTS        → 📋
REFERENCES/LINKS          → 🔗
WARNINGS/CONSTRAINTS      → ⚠️
TIPS/BEST PRACTICES       → 💡
DATA/EXAMPLES             → 📊
GOALS/OBJECTIVES          → 🎯
DOCUMENTATION             → 📄
WORKFLOW/PROCESS          → 🚀
INTEGRATION               → 🔌
SECURITY                  → 🔒
PERFORMANCE               → ⚡
```

### Quality Scoring Targets

**Structure Score**: 100/100
- Perfect markdown structure
- All headings properly formatted
- No structural violations

**C7Score**: 85+/100
- Clarity: Clear explanations and examples
- Completeness: All sections properly filled
- Correctness: Accurate technical information
- Conciseness: No unnecessary verbosity
- Consistency: Uniform formatting and style
- Context: Proper background and rationale
- Citations: References to sources

**Overall Score**: 85+/100
- Combined structural and content quality
- Knowledge files can be more flexible than SKILL files

### Common Validation Errors and Fixes

| Error Message                    | Cause                     | Quick Fix              |
| -------------------------------- | ------------------------- | ---------------------- |
| "Knowledge file has frontmatter" | YAML `---` block detected | Remove all frontmatter |
| "H1 missing subtitle"            | H1 is `# Topic` only      | Add ` - Subtitle`      |
| "H2 not numbered"                | Missing number prefix     | Add `1. ` before emoji |
| "H2 not ALL CAPS"                | Title Case H2 text        | Convert to ALL CAPS    |
| "Multiple H1 headers"            | More than one `#`         | Keep only one H1       |
| "Skipped heading level"          | H2 → H4 jump              | Add intermediate H3    |
| "H3 has emoji"                   | Emoji in subsection       | Remove emoji from H3   |

### File Naming Conventions

**Knowledge files** should use:
- Lowercase with underscores: `code_standards.md`
- Descriptive names: `mcp_semantic_search.md`
- Topic-focused: `initialization_pattern.md`, `mcp_code_mode.md`

**Avoid**:
- ❌ Hyphens: `code-standards.md` (use underscores)
- ❌ Camel case: `codeStandards.md` (use lowercase)
- ❌ Generic names: `doc.md`, `notes.md` (be specific)
- ❌ ALL CAPS: `README.md` (lowercase for knowledge)

---

## QUICK START CHECKLIST

Starting a new knowledge file? Follow these steps:

1. **Choose filename**: `topic_name.md` (lowercase, underscores)
2. **Copy template**: From Section 3 above
3. **NO frontmatter**: Do not add YAML metadata
4. **Write H1**: `# Topic Name - Descriptive Subtitle`
5. **Number H2s**: `## 1. 🎯 SECTION` (sequential, emoji, ALL CAPS)
6. **Add H3s**: `### Subsection Name` (Title Case, no emoji)
7. **Include examples**: Both valid ✅ and invalid ❌
8. **Document constraints**: Platform limitations and workarounds
9. **Verify structure**: Run through checklist above

**Template location**: This file, Section 3
**Additional resources**: [core_standards.md](../references/core_standards.md)
**Validation**: `.claude/hooks/` will check on commit
