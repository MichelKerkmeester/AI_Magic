# [Reference Topic Title] - Claude Code Hooks

Comprehensive reference documentation for [topic]. This reference provides deep technical guidance with explicit reasoning, step-by-step workflows, and pattern libraries for [domain].

---

## 1. 📖 WHAT ARE HOOK REFERENCES?

**Purpose**: Reference files are detailed technical documentation in the `references/` directory that provide deep-dive guidance for [topic] with **explicit reasoning** - making thought processes visible, showing decision logic, and analyzing root causes.

**Core Characteristics**:
- **Technical depth**: Step-by-step reasoning with rationale for each decision
- **Phased workflows**: Structured processes with validation checkpoints
- **Pattern libraries**: Before/after examples, comparison tables, real-world use cases
- **Tool integration**: Script usage, hook integration patterns, API references
- **Root cause analysis**: Systematic debugging and troubleshooting guides

**Key Difference from Generic Documentation**:
- Hook references = Actionable workflows with explicit reasoning and validation
- Generic docs = Information reference without decision logic or workflows

**Progressive Disclosure in Skills**:
```
Level 1: Metadata (name + description)
         └─ Always in context (~100 words)
            ↓
Level 2: SKILL.md body
         └─ When skill triggers (<5k words)
            ↓
Level 3: Reference files (this document)
         └─ Loaded as needed (500-3000 lines per file)
```

Reference files are **Level 3**: Deep technical guidance loaded only when specific workflow details needed.

---

## 2. 🎯 WHEN TO CREATE REFERENCE FILES

**Create reference file when**:
- Multi-phase workflows with validation checkpoints required
- Decision trees with multiple branches need documentation
- Complex patterns requiring before/after examples
- Root cause analysis workflows essential for troubleshooting
- Tool integration patterns must be standardized
- Performance optimization strategies need detailed explanation

**Don't create reference file for**:
- Simple concepts explainable in SKILL.md (<500 words)
- One-step processes without decision logic
- Duplicate content already in other references
- Project-specific guidance (not reusable)

**Examples of good reference files**:
- ✅ hook_types.md (multi-type taxonomy with decision logic)
- ✅ payload_structures.md (complex data structures, validation patterns)
- ✅ best_practices.md (pattern library with rationale)
- ❌ Simple command reference (belongs in SKILL.md)
- ❌ Project-specific configuration (not reusable)

---

## 3. 📋 OVERVIEW

### Purpose

[2-3 paragraphs explaining:
- What problem this reference solves
- Who benefits from this information
- How it fits into the broader hook ecosystem]

### Scope

**In Scope**:
- [Topic 1]
- [Topic 2]
- [Topic 3]

**Out of Scope**:
- [Topic 1 - see other reference]
- [Topic 2 - see other reference]

### Quick Summary

| Aspect | Description |
|--------|-------------|
| **Primary Use Case** | [Most common scenario] |
| **Related Hook Types** | [Which hooks use this] |
| **Complexity** | [Low / Medium / High] |
| **Performance Impact** | [Negligible / Moderate / Significant] |

---

## 4. 🧠 CORE CONCEPTS

### Concept 1: [Name]

**Definition**: [Clear, concise explanation of the concept]

**Why It Matters**: [Practical importance]

**Key Characteristics**:
- [Characteristic 1]
- [Characteristic 2]
- [Characteristic 3]

**Visual Representation**:
```
[ASCII diagram or flowchart if applicable]
```

### Concept 2: [Name]

**Definition**: [Clear, concise explanation of the concept]

**Why It Matters**: [Practical importance]

**Key Characteristics**:
- [Characteristic 1]
- [Characteristic 2]
- [Characteristic 3]

### Concept 3: [Name]

**Definition**: [Clear, concise explanation of the concept]

**Why It Matters**: [Practical importance]

**Key Characteristics**:
- [Characteristic 1]
- [Characteristic 2]
- [Characteristic 3]

---

## 5. 🛠️ IMPLEMENTATION GUIDE

### Step 1: [First Step Name]

**Objective**: [What this step achieves]

**Prerequisites**: [What must be done before this step]

**Process**:

1. [Sub-step 1]
   ```bash
   # Code example for sub-step 1
   ```

2. [Sub-step 2]
   ```bash
   # Code example for sub-step 2
   ```

3. [Sub-step 3]
   ```bash
   # Code example for sub-step 3
   ```

**Validation**: [How to verify this step succeeded]

**Common Issues**:
- [Issue 1 and quick fix]
- [Issue 2 and quick fix]

### Step 2: [Second Step Name]

**Objective**: [What this step achieves]

**Prerequisites**: [What must be done before this step]

**Process**:

1. [Sub-step 1]
   ```bash
   # Code example
   ```

2. [Sub-step 2]
   ```bash
   # Code example
   ```

**Validation**: [How to verify this step succeeded]

**Common Issues**:
- [Issue 1 and quick fix]
- [Issue 2 and quick fix]

### Step 3: [Third Step Name]

**Objective**: [What this step achieves]

**Prerequisites**: [What must be done before this step]

**Process**:

1. [Sub-step 1]
   ```bash
   # Code example
   ```

**Validation**: [How to verify this step succeeded]

**Common Issues**:
- [Issue 1 and quick fix]

---

## 6. 💡 EXAMPLES

### Example 1: [Basic Use Case]

**Scenario**: [Description of the use case]

**Requirements**:
- [Requirement 1]
- [Requirement 2]

**Implementation**:

```bash
#!/bin/bash
# [Example implementation with detailed comments]

# Step 1: [What this does]
[code]

# Step 2: [What this does]
[code]

# Step 3: [What this does]
[code]
```

**Expected Output**:
```
[Sample output from running the example]
```

**Explanation**:
- [Line-by-line explanation of key parts]

### Example 2: [Intermediate Use Case]

**Scenario**: [Description of the use case]

**Requirements**:
- [Requirement 1]
- [Requirement 2]

**Implementation**:

```bash
#!/bin/bash
# [Example implementation]
[code]
```

**Expected Output**:
```
[Sample output]
```

**Key Differences from Example 1**:
- [Difference 1 and why it matters]
- [Difference 2 and why it matters]

### Example 3: [Advanced Use Case]

**Scenario**: [Description of the use case]

**Requirements**:
- [Requirement 1]
- [Requirement 2]
- [Requirement 3]

**Implementation**:

```bash
#!/bin/bash
# [Example implementation]
[code]
```

**Expected Output**:
```
[Sample output]
```

**Advanced Techniques Used**:
- [Technique 1: explanation]
- [Technique 2: explanation]

---

## 7. ⭐ BEST PRACTICES

### Practice 1: [Name]

**Guideline**: [The practice in one sentence]

**Rationale**: [Why this is important]

**Good Example**:
```bash
# [Code showing the right way]
```

**Bad Example**:
```bash
# [Code showing the wrong way]
```

**Impact**:
- **Performance**: [How this affects performance]
- **Security**: [How this affects security]
- **Maintainability**: [How this affects maintainability]

### Practice 2: [Name]

**Guideline**: [The practice in one sentence]

**Rationale**: [Why this is important]

**Good Example**:
```bash
# [Code showing the right way]
```

**Bad Example**:
```bash
# [Code showing the wrong way]
```

**Impact**:
- **Performance**: [How this affects performance]
- **Security**: [How this affects security]
- **Maintainability**: [How this affects maintainability]

### Practice 3: [Name]

**Guideline**: [The practice in one sentence]

**Rationale**: [Why this is important]

**Good Example**:
```bash
# [Code showing the right way]
```

**Bad Example**:
```bash
# [Code showing the wrong way]
```

**Impact**:
- **Performance**: [How this affects performance]
- **Security**: [How this affects security]
- **Maintainability**: [How this affects maintainability]

---

## 8. 🔧 TROUBLESHOOTING

### Problem 1: [Issue Name]

**Symptoms**:
- [Observable symptom 1]
- [Observable symptom 2]

**Possible Causes**:
1. [Cause 1]
   - **Check**: [How to verify this is the cause]
   - **Fix**: [Step-by-step solution]

2. [Cause 2]
   - **Check**: [How to verify this is the cause]
   - **Fix**: [Step-by-step solution]

**Prevention**: [How to avoid this issue in the future]

### Problem 2: [Issue Name]

**Symptoms**:
- [Observable symptom 1]
- [Observable symptom 2]

**Possible Causes**:
1. [Cause 1]
   - **Check**: [How to verify this is the cause]
   - **Fix**: [Step-by-step solution]

**Prevention**: [How to avoid this issue in the future]

### Problem 3: [Issue Name]

**Symptoms**:
- [Observable symptom 1]

**Possible Causes**:
1. [Cause 1]
   - **Check**: [How to verify this is the cause]
   - **Fix**: [Step-by-step solution]

**Prevention**: [How to avoid this issue in the future]

---

## 9. ⚡ PERFORMANCE CONSIDERATIONS

### Performance Profile

| Operation | Target Time | Typical Time | Notes |
|-----------|-------------|--------------|-------|
| [Operation 1] | [Target] | [Actual] | [Important notes] |
| [Operation 2] | [Target] | [Actual] | [Important notes] |
| [Operation 3] | [Target] | [Actual] | [Important notes] |

### Optimization Strategies

#### Strategy 1: [Name]

**When to Apply**: [Conditions for using this strategy]

**Implementation**:
```bash
# [Code example]
```

**Performance Gain**: [Quantified improvement if available]

**Trade-offs**:
- [Pro 1]
- [Con 1]

#### Strategy 2: [Name]

**When to Apply**: [Conditions for using this strategy]

**Implementation**:
```bash
# [Code example]
```

**Performance Gain**: [Quantified improvement if available]

**Trade-offs**:
- [Pro 1]
- [Con 1]

### Benchmarking

**How to Measure Performance**:
```bash
# [Command to measure performance]
```

**Interpreting Results**:
- [Metric 1]: [What it means]
- [Metric 2]: [What it means]

---

## 10. 🔒 SECURITY CONSIDERATIONS

### Security Concern 1: [Name]

**Risk Level**: [Low / Medium / High / Critical]

**Description**: [What the security concern is]

**Attack Scenarios**:
- [Scenario 1 description]
- [Scenario 2 description]

**Mitigation**:
```bash
# [Code showing secure implementation]
```

**Validation**:
- [How to verify the mitigation is effective]

### Security Concern 2: [Name]

**Risk Level**: [Low / Medium / High / Critical]

**Description**: [What the security concern is]

**Mitigation**:
```bash
# [Code showing secure implementation]
```

**Validation**:
- [How to verify the mitigation is effective]

---

## 11. 📚 REFERENCES

### Related Documentation

- **Internal References**:
  - [Reference 1]: `references/[filename].md#section`
  - [Reference 2]: `references/[filename].md#section`

- **Asset Examples**:
  - [Example 1]: `assets/[filename].sh`
  - [Example 2]: `assets/[filename].sh`

- **Scripts**:
  - [Script 1]: `scripts/[filename].sh`
  - [Script 2]: `scripts/[filename].sh`

### External Resources

- [Resource 1]: [URL] - [Brief description]
- [Resource 2]: [URL] - [Brief description]
- [Resource 3]: [URL] - [Brief description]

### Standards and Specifications

- [Standard 1]: [URL or citation]
- [Standard 2]: [URL or citation]

---

## 12. ✅ HOOK REFERENCE CHECKLIST

**Use this checklist to ensure your reference file is complete and production-ready.**

### Structure & Organization

- [ ] Topic clearly defined in title and overview section
- [ ] Purpose explicitly stated in Overview (Section 3)
- [ ] Scope (In/Out) clearly defined in Overview
- [ ] Prerequisites documented for implementation steps
- [ ] All major sections complete and relevant to topic
- [ ] Logical flow from concepts → implementation → examples → troubleshooting

### Content Quality

- [ ] Core concepts explained with clear definitions and importance statements
- [ ] Step-by-step implementation guide provided (Section 5)
- [ ] Examples cover basic, intermediate, and advanced use cases (Section 6)
- [ ] Best practices section includes good/bad code examples with impact analysis (Section 7)
- [ ] Troubleshooting section addresses common issues with diagnosis and solutions (Section 8)
- [ ] All explanations avoid jargon or define technical terms clearly

### Technical Accuracy

- [ ] All code examples tested and working in Bash 3.2+
- [ ] Performance targets realistic and based on actual testing
- [ ] Security considerations address relevant threat vectors (Section 10)
- [ ] Exit codes correctly documented (Quick Reference Card)
- [ ] File paths use proper quoting and escaping
- [ ] Variable naming consistent with hook system standards

### Cross-References

- [ ] Related documentation linked in References section (Section 11)
- [ ] Asset examples properly referenced with file paths
- [ ] External resources cited with URLs
- [ ] Internal links to other reference files include anchor text
- [ ] Scripts and tools referenced exist and are accessible

### Completeness Checks

- [ ] No placeholder text remains ([PLACEHOLDER], [TODO], [NEEDS CLARIFICATION])
- [ ] All section headers properly numbered
- [ ] Version and date fields filled in footer
- [ ] Glossary includes all technical terms used
- [ ] Change history documented for current version

---

## 13. 🔄 HOOK REFERENCE MAINTENANCE

### Lifecycle Management

**When to Update**:
- Hook system changes that affect documented patterns
- New patterns or best practices emerge from production use
- Security vulnerabilities discovered and mitigation strategies identified
- Performance optimization strategies become available
- User feedback indicates confusion, errors, or missing content
- Related reference files updated with cascade effects
- Annual review cycle to ensure currency

**Version Control**:
- Document version tracked in footer (semantic versioning: X.Y.Z)
- Change history maintained in Appendix with dates and summaries
- Breaking changes clearly marked with migration guidance
- Deprecation notices provided with advance warning periods
- Migration guides provided for major structural changes

**Update Process**:
1. Review all code examples for accuracy against current hook system
2. Test examples in actual hook environment (Bash 3.2+ compatibility)
3. Verify cross-references to related documentation (no broken links)
4. Update security considerations for any new threat patterns
5. Refresh performance benchmarks if system changes occurred
6. Increment version number in footer (patch/minor/major)
7. Add entry to Change History with date and summary
8. Request review by hook system maintainer before publication

**Quality Standards**:
- Examples must be production-ready and tested
- Code follows create-hooks best practices guide
- Security patterns reflect current threat landscape
- Performance targets reflect actual system benchmarks
- Links verified and functional (no 404s or redirects)
- Bash 3.2 compatibility maintained
- No deprecated patterns documented without migration guidance

### Deprecation Strategy

**Marking Deprecated Content**:
```markdown
> **DEPRECATED**: This pattern deprecated as of [DATE].
> Use [NEW_PATTERN] instead (see [REFERENCE_LINK]).
> Removal planned for [FUTURE_DATE].
```

**Deprecation Timeline**:
- Announce deprecation with advance notice (minimum 2 versions)
- Provide migration guide in Appendix
- Update examples to show new pattern
- Mark old pattern with deprecation notice
- Remove from documentation after agreed timeline

---

## 14. 🎯 QUICK REFERENCE CARD

### Essential Commands

```bash
# [Most common command 1]
[command]

# [Most common command 2]
[command]

# [Most common command 3]
[command]
```

### Common Patterns

**Pattern 1**: [One-line description]
```bash
[code snippet]
```

**Pattern 2**: [One-line description]
```bash
[code snippet]
```

**Pattern 3**: [One-line description]
```bash
[code snippet]
```

### Exit Codes

| Code | Meaning | When to Use |
|------|---------|-------------|
| 0 | [Meaning] | [Usage] |
| 1 | [Meaning] | [Usage] |
| 2 | [Meaning] | [Usage] |

---

## 15. 📝 APPENDIX

### Glossary

- **[Term 1]**: [Definition]
- **[Term 2]**: [Definition]
- **[Term 3]**: [Definition]