# Prompt Format Guide: Markdown

Formatting guide for Markdown (Standard) output structure in prompt engineering with RCAF/CRAFT frameworks, file delivery standards, syntax validation, and format-specific best practices.

**Core Purpose:** Define Markdown syntax specifications, structure patterns, validation rules, and file delivery standards. This guide focuses exclusively on HOW to format Markdown output—processing logic, cognitive frameworks, and interaction patterns are handled by other guides (DEPTH, Interactive Mode, Patterns).

---

## 📋 Table of Contents

1. [🎯 OVERVIEW & PURPOSE](#-overview--purpose)
2. [📊 MARKDOWN FORMAT FUNDAMENTALS](#-markdown-format-fundamentals)
3. [📦 FILE DELIVERY STANDARDS](#-file-delivery-standards)
4. [🔧 RCAF MARKDOWN STRUCTURE](#-rcaf-markdown-structure)
5. [🎨 CRAFT MARKDOWN STRUCTURE](#-craft-markdown-structure)
6. [📄 ADVANCED MARKDOWN PATTERNS](#-advanced-markdown-patterns)
7. [🔄 FORMAT CONVERSIONS](#-format-conversions)
8. [⚖️ MARKDOWN VS OTHER FORMATS](#-markdown-vs-other-formats)
9. [💡 EXAMPLES & TEMPLATES](#-examples--templates)
10. [✅ SYNTAX VALIDATION](#-syntax-validation)
11. [🎓 BEST PRACTICES](#-best-practices)

---

<a id="-overview--purpose"></a>

## 1. 🎯 OVERVIEW & PURPOSE

### Why Markdown (Standard) Format?

Markdown format provides natural language prompt engineering with optimal human readability while maintaining clear structure through RCAF/CRAFT frameworks.

**Terminology Clarification:**
- **Framework** = Prompt organization method (RCAF vs CRAFT)
- **Format** = Data structure (Standard/Markdown vs JSON vs YAML)
- **Standard Format** = Markdown-based natural language structure

**See Also:**
- **YAML Format Guide** - For YAML syntax and structure
- **JSON Format Guide** - For JSON syntax and structure
- **Interactive Mode** - For format selection in conversational flow
- **DEPTH guide** - For processing methodology and transparency reporting
- **Patterns guide** - For quality evaluation (CLEAR scoring)

**Markdown Format Benefits:**
- **Natural Language:** Conversational flow
- **Human Readable:** Immediate comprehension
- **Flexible Structure:** Adapts to complexity
- **Minimal Overhead:** Baseline token usage
- **Direct Communication:** Clear intent expression

### Format Comparison Summary

| Aspect | Markdown (Standard) | JSON | YAML |
|--------|-------------------|------|------|
| **Readability** | Natural language | Structured data | Human-friendly structure |
| **Token Usage** | Baseline (100%) | +5-10% | +3-7% |
| **Best For** | Human interaction | API integration | Configuration |
| **Framework Fit** | RCAF/CRAFT equal | RCAF preferred | RCAF optimal |
| **Learning Curve** | None | Medium | Low |

---

<a id="-markdown-format-fundamentals"></a>

## 2. 📊 MARKDOWN FORMAT FUNDAMENTALS

### Core Markdown Principles

1. **Clarity First:** Every word must earn its place
2. **Natural Flow:** Conversational structure
3. **Semantic Headers:** Clear section delineation
4. **Concise Expression:** Maximum clarity, minimum tokens
5. **Action-Oriented:** Focus on what needs to be done

### Basic Markdown Prompt Structure

```markdown
**Role:** [Specific expertise needed]
**Context:** [Essential background information]
**Action:** [Clear, measurable task]
**Format:** [Expected output structure]
```

### Markdown Elements for Prompts

| Element | Use Case | Example |
|---------|----------|---------|
| **Bold Headers** | Section markers | `**Role:** Data Analyst` |
| **Bullet Lists** | Multiple requirements | `- Requirement 1` |
| **Numbered Lists** | Sequential steps | `1. First step` |
| **Inline Code** | Technical terms | `` `API endpoint` `` |
| **Block Quotes** | Context emphasis | `> Important note` |

---

<a id="-file-delivery-standards"></a>

## 3. 📦 FILE DELIVERY STANDARDS

### File Delivery Methods

**Claude Desktop App & IDE Environments:**
- Use file creation tool to create actual downloadable files
- File format: `.md` (Markdown)
- Include only: Header + prompt content
- Place explanations in chat AFTER file delivery

**CLI/Agent Mode (via `AGENTS.md`):**
- Save to `/Export` folder
- Use sequential numbering: `[###] - descriptive-filename.md`
- Example: `[001] - research-prompt-ai-ethics.md`
- Follow same structure: Header + content only

### Mandatory Minimal Header Format

**Single-line header at TOP of every file:**
```
Mode: $[mode] | Complexity: [level] | Framework: [RCAF/CRAFT]
```

**Header Requirements:**
- **Mode with $ prefix:** $improve, $refine, $quick, etc.
- **Complexity level:** Low/Medium/High or 1-10
- **Framework used:** RCAF or CRAFT

**Note:** Quality scores (CLEAR) reported separately in chat, not in file header.

### File Content Structure

**ONLY these two components in file:**
1. **Single-line header** (with $ prefix)
2. **Enhanced prompt content** (natural language markdown)

**FORBIDDEN in files:**
- ❌ CLEAR Evaluation breakdown
- ❌ Processing Applied section
- ❌ Format Options section
- ❌ Additional metadata sections
- ❌ Explanations or commentary
- ✅ All explanations go in CHAT after delivery

### Pre-Delivery Validation

**Validation Requirements:**

```yaml
validate_markdown_file:
  description: "Validate Markdown file before delivery"
  
  checks:
    is_downloadable_file:
      check: file_type == "text/markdown"
      status: required
      
    file_created:
      check: file_object != null
      status: required
      
    header_present:
      check: has_single_line_header == true
      status: required
      
    header_format:
      check: header_contains_dollar_prefix == true
      status: required
      
    no_extra_sections:
      check: has_only_header_and_content == true
      status: required
      
    framework_complete:
      check: all_framework_fields_present == true
      validation: "RCAF: role, context, action, format"
      status: required
      
  on_validation_failure:
    action: stop_and_regenerate
    message: "Validation error - regenerating complete file"
```

### Content Compliance Rules

**Output Requirements:**
1. **Natural language markdown ONLY**
2. **NO raw JSON/YAML within Markdown files**
3. **NO explanatory metadata within the file**
4. **All framework fields must be complete**
5. **Validate before delivery - if invalid, RETRY**

### Correct vs Incorrect Examples

**✅ CORRECT Markdown file:**
```
Mode: $improve | Complexity: Medium | Framework: RCAF

**Role:** Data analyst with expertise in SaaS metrics.
**Context:** Q4 revenue data from B2B platform with 10K customers.
**Action:** Calculate MRR growth and identify top 3 revenue trends.
**Format:** Executive summary (500 words) with metrics, charts, and recommendations.
```

**❌ INCORRECT - DO NOT DO THIS:**
```
Mode: $improve | Complexity: Medium | Framework: RCAF

**Role:** Data analyst

**CLEAR Evaluation:**
- Correctness: 8/10
- Logic: 9/10
...

**Processing Applied:**
✅ DEPTH rounds completed
```
NO metadata sections! Just the enhanced prompt.

---

<a id="-rcaf-markdown-structure"></a>

## 4. 🔧 RCAF MARKDOWN STRUCTURE

### Standard RCAF Template

```markdown
**Role:** [Specific expertise definition]
**Context:** [Essential background information]
**Action:** [Clear measurable task]
**Format:** [Expected output requirements]
```

### RCAF Markdown Examples

#### Simple Analysis Task

**Delivered as file:**
```
Mode: $improve | Complexity: Medium | Framework: RCAF

**Role:** Financial analyst specializing in SaaS metrics and growth analysis.
**Context:** Q4 2024 revenue data from B2B platform with 10,000 customers, focusing on subscription trends.
**Action:** Calculate MRR growth rate, identify top 3 revenue trends, and provide actionable insights.
**Format:** Executive summary (500 words) with key metrics, trend charts, and 3-5 strategic recommendations.
```

#### Content Creation Task

**Delivered as file:**
```
Mode: $improve | Complexity: Medium | Framework: RCAF

**Role:** Technical writer with API documentation expertise and developer experience focus.
**Context:** REST API with 15 endpoints for payment processing, OAuth 2.0 authentication, versioned at v2.1.
**Action:** Create comprehensive API documentation including authentication flow, endpoint specifications, and integration examples.
**Format:** Developer-friendly markdown with overview, authentication guide, endpoint reference, code examples, and troubleshooting section.
```

### RCAF Field Guidelines

| Field | Required | Description | Best Practices |
|-------|----------|-------------|----------------|
| **Role** | Yes | Expertise needed | Be specific about domain and skills |
| **Context** | Yes | Essential background | Include constraints and scope |
| **Action** | Yes | Task to perform | Make measurable and specific |
| **Format** | Yes | Output structure | Define sections and length |

---

<a id="-craft-markdown-structure"></a>

## 5. 🎨 CRAFT MARKDOWN STRUCTURE

### Standard CRAFT Template

```markdown
**Context:** [Comprehensive background and constraints]
**Role:** [Detailed expertise and perspective]
**Action:** [Primary task with subtasks and deliverables]
**Format:** [Detailed output specifications]
**Target:** [Success metrics and criteria]
```

### CRAFT Markdown Examples

#### Complex Analysis Task

**Delivered as file:**
```
Mode: $refine | Complexity: High | Framework: CRAFT

**Context:** E-commerce platform experiencing 15% cart abandonment rate over the last 6 months. Available data includes user session logs, transaction records, and customer surveys. Must comply with GDPR and deliver within 30 days.

**Role:** UX researcher with e-commerce specialization, applying user-centric analysis methodology using behavioral analytics and qualitative research techniques.

**Action:** Identify root causes of cart abandonment through multi-method analysis:
- Analyze user behavior patterns across abandonment stages
- Segment users by abandonment point and demographics
- Correlate quantitative findings with survey responses
- Generate prioritized recommendations for reducing abandonment

**Format:** Research report (2500 words) structured as:
- Executive summary with key findings
- Methodology overview
- Detailed findings with visualizations (flow diagrams, heat maps)
- Actionable recommendations ranked by impact/effort

**Target:** Deliver insights that enable 20% reduction in abandonment rate within Q1 2025, with specific KPIs for each recommendation.
```

### CRAFT vs RCAF Decision Matrix

| Use CRAFT When | Use RCAF When |
|----------------|---------------|
| Multiple success metrics needed | Single clear outcome |
| Complex multi-stakeholder scenarios | Straightforward task |
| Detailed specifications required | Flexibility preferred |
| Comprehensive documentation needed | Quick clarity needed |

---

<a id="-advanced-markdown-patterns"></a>

## 6. 📄 ADVANCED MARKDOWN PATTERNS

### Multi-Step Process Pattern

**Delivered as file:**
```
Mode: $improve | Complexity: High | Framework: RCAF

**Role:** Project coordinator with software deployment expertise.

**Context:** Enterprise client deployment for cloud-based CRM system, 500+ users, multiple departments, requiring zero downtime migration.

**Action:** Execute three-phase deployment process:

**Phase 1 - Environment Preparation:**
- Validate infrastructure requirements
- Configure staging environment
- Create rollback procedures
- Output: Readiness checklist and validation report

**Phase 2 - Deployment Execution:**
- Migrate data in batches
- Deploy application components
- Run integration tests
- Output: Deployment log and test results

**Phase 3 - Post-Deployment Validation:**
- Monitor system performance
- Gather user feedback
- Address immediate issues
- Output: Performance metrics and optimization recommendations

**Format:** Status report per phase with traffic light indicators, plus comprehensive summary document with lessons learned.
```

### Conditional Logic Pattern

```markdown
**Role:** Customer service specialist with technical troubleshooting skills.

**Context:** First-line support for software platform with varied user base.

**Action:** Classify and route support tickets using decision tree:

If technical issue detected (error messages, system behavior):
  → Route to: Engineering team
  → Priority: Assess based on severity indicators
  → Include: Full error logs and reproduction steps

If billing/payment related:
  → Route to: Finance team  
  → Priority: High (affects revenue)
  → Include: Account details and transaction IDs

If general inquiry or how-to question:
  → Route to: Support Tier 1
  → Priority: Standard queue
  → Include: User context and previous tickets

**Format:** Routing decision with department assignment, priority level, and brief rationale (50 words max).
```

---

<a id="-format-conversions"></a>

## 7. 🔄 FORMAT CONVERSIONS

**Cross-format guidance:**
- **To/From YAML:** See **YAML Format Guide**
- **To/From JSON:** See **JSON Format Guide**
- **Interactive selection:** Per **Interactive Mode**

### Markdown to JSON Conversion

```yaml
markdown_to_json:
  description: "Convert RCAF Markdown to JSON format"
  
  parse_markdown:
    pattern: "**[Field]:** [value]"
    extract_fields:
      - role
      - context
      - action
      - format
      
  build_json:
    structure: object
    fields:
      role: "[extracted_role_value]"
      context: "[extracted_context_value]"
      action: "[extracted_action_value]"
      format: "[extracted_format_value]"
      
  output:
    format: json
    indent: 2
```

### Markdown to YAML Conversion

```yaml
markdown_to_yaml:
  description: "Convert RCAF Markdown to YAML format"
  
  parse_markdown:
    pattern: "**[Field]:** [value]"
    extract_fields:
      - role
      - context
      - action
      - format
      
  build_yaml:
    structure: key_value_pairs
    indentation: 2_spaces
    fields:
      role: "[extracted_role_value]"
      context: "[extracted_context_value]"
      action: "[extracted_action_value]"
      format: "[extracted_format_value]"
      
  output:
    format: yaml
    flow_style: false
```

### Conversion Examples

**Original Markdown:**
```markdown
**Role:** Data analyst with SQL expertise.
**Context:** Sales database with 5 years of transaction data.
**Action:** Identify top performing products by region.
**Format:** Dashboard with charts and executive summary.
```

**JSON Equivalent:**
```json
{
  "role": "Data analyst with SQL expertise",
  "context": "Sales database with 5 years of transaction data",
  "action": "Identify top performing products by region",
  "format": "Dashboard with charts and executive summary"
}
```

**YAML Equivalent:**
```yaml
role: Data analyst with SQL expertise
context: Sales database with 5 years of transaction data
action: Identify top performing products by region
format: Dashboard with charts and executive summary
```

---

<a id="-markdown-vs-other-formats"></a>

## 8. ⚖️ MARKDOWN VS OTHER FORMATS

**Format Guide References:**
- **YAML Guide:** See **YAML Format Guide** for structured data format details
- **JSON Guide:** See **JSON Format Guide** for API integration format details
- **Selection Process:** Per **Interactive Mode** format selection workflow

### Format Selection Matrix

| Factor | Choose Markdown | Choose JSON | Choose YAML |
|--------|----------------|-------------|-------------|
| **Audience** | Humans | Machines/APIs | Configurations |
| **Complexity** | Any level | Structured only | Hierarchical |
| **Flexibility** | High | Low | Medium |
| **Readability** | Excellent | Fair | Good |
| **Token Efficiency** | Best | Lower | Medium |
| **Integration** | Manual | Automated | Semi-automated |

---

<a id="-examples--templates"></a>

## 9. 💡 EXAMPLES & TEMPLATES

### Template Library

#### Research Template

**Delivered as file:**
```
Mode: $improve | Complexity: Medium | Framework: RCAF

**Role:** Research analyst with expertise in [DOMAIN].
**Context:** Investigating [RESEARCH_QUESTION] within [SCOPE] using [AVAILABLE_RESOURCES].
**Action:** Conduct systematic research using [METHODOLOGY] to identify [KEY_FINDINGS] and develop [DELIVERABLES].
**Format:** Research paper with abstract, methodology, findings, and recommendations, approximately [LENGTH] words.
```

#### Analysis Template

**Delivered as file:**
```
Mode: $improve | Complexity: Medium | Framework: RCAF

**Role:** Data analyst specializing in [DOMAIN].
**Context:** Dataset containing [DATA_DESCRIPTION] from [TIME_PERIOD] with [CONSTRAINTS].
**Action:** Analyze [METRICS] to identify [INSIGHTS_TYPE] and provide [RECOMMENDATIONS_COUNT] actionable recommendations.
**Format:** [OUTPUT_TYPE] including visualizations ([CHART_TYPES]) and executive summary.
```

---

<a id="-syntax-validation"></a>

## 10. ✅ SYNTAX VALIDATION

### Markdown Syntax Validation

**Pre-Delivery Checks:**

```yaml
validate_markdown_syntax:
  description: "Validate Markdown syntax before file delivery"
  
  check_framework_fields:
    required_fields:
      - "**Role:**"
      - "**Context:**"
      - "**Action:**"
      - "**Format:**"
    validation: all_fields_present
    
  check_header_format:
    pattern: "Mode: $[mode] | Complexity: [level] | Framework: [RCAF/CRAFT]"
    dollar_prefix: required
    single_line: true
    
  check_forbidden_sections:
    disallowed:
      - "CLEAR Evaluation"
      - "Processing Applied"
      - "Format Options"
      - "Enhancement Details"
    action_if_found: regenerate_file
    
  validate_markdown_formatting:
    bold_headers: "**Field:**"
    list_syntax: standard_markdown
    no_raw_json_yaml: true
    
  on_success:
    result: true
    message: "Valid Markdown file - ready for delivery"
    
  on_failure:
    result: false
    action: stop_and_regenerate
    message: "Validation failed - regenerating"
```

### Framework Validation

**RCAF Completeness Check:**
```yaml
validate_rcaf:
  role:
    present: required
    specific: true
    example: "Data analyst with SQL expertise"
    
  context:
    present: required
    sufficient_detail: true
    example: "Sales database with 5 years of data"
    
  action:
    present: required
    measurable: true
    example: "Identify top 10 products by region"
    
  format:
    present: required
    clearly_defined: true
    example: "Dashboard with charts and summary"
```

**CRAFT Completeness Check:**
```yaml
validate_craft:
  context:
    present: required
    comprehensive: true
    
  role:
    present: required
    expertise_defined: true
    
  action:
    present: required
    specific_steps: true
    
  format:
    present: required
    structure_defined: true
    
  target:
    present: required
    audience_clear: true
```

---

<a id="-best-practices"></a>

## 11. 🎓 BEST PRACTICES

### Markdown Format Do's ✅

**Syntax & Structure:**
- Use bold for section headers (**Field:**)
- Keep paragraphs concise and focused
- Use lists for multiple items
- Include specific examples
- Define measurable outcomes
- Maintain conversational tone
- Use proper Markdown formatting
- Validate syntax before delivery

**File Delivery:**
- Deliver as downloadable file (.md)
- Use `$` prefix in mode header
- Create actual file using file creation tool
- Include only header + prompt content in file
- Place explanations in chat after file delivery
- In CLI/Agent mode: Use /Export folder with sequential numbering

**Content Quality:**
- Framework fields complete (RCAF/CRAFT)
- Clear role definition
- Complete context
- Specific, measurable action
- Well-defined format requirements
- Natural readability
- No metadata contamination

### Markdown Format Don'ts ❌

**Syntax & Structure:**
- Don't over-format with complex Markdown
- Don't embed unnecessary code blocks
- Don't use ambiguous language
- Don't skip framework fields
- Don't nest lists excessively
- Don't include raw JSON/YAML in Markdown files

**File Delivery:**
- Don't deliver in chat (file only)
- Don't add verbose sections to file
- Don't skip validation
- Don't include explanations in file (chat only)
- Don't forget $ prefix in header
- Don't add quality scores to header

**Content Issues:**
- Don't include CLEAR evaluation in file
- Don't add processing sections
- Don't hide framework structure
- Don't use vague requirements
- Don't create unmeasurable actions

### Token Efficiency

**Markdown Token Overhead:**
- Baseline format: 100% (reference point)
- Optimization: Use concise language, avoid redundancy
- Balance: Clarity vs brevity

**Optimization Techniques:**
```markdown
# Less efficient (verbose)
**Role:** You are a professional data analyst who specializes in...

# More efficient (concise)
**Role:** Data analyst specializing in...

# Use specific terms
**Context:** Large dataset (avoid "very large dataset with lots of data")
```

### Format Quality Checklist

**Excellent Markdown File:**
- ✅ Valid Markdown syntax
- ✅ Single-line header with $ prefix
- ✅ All framework fields present (RCAF/CRAFT)
- ✅ Clear role definition
- ✅ Complete context
- ✅ Specific, measurable action
- ✅ Well-defined format requirements
- ✅ Delivered as downloadable file
- ✅ No metadata sections in file
- ✅ Natural readability
- ✅ Immediate usability

### Markdown Format Principles

> "Natural language is the universal interface. Markdown provides structure without sacrificing humanity."

**Core Principles:**
1. **Clarity through simplicity** - Direct communication
2. **Structure through convention** - Consistent patterns
3. **Flexibility through natural language** - Adaptable expression
4. **Efficiency through minimalism** - No wasted tokens
5. **Focus through minimalism** - Minimal header only
6. **Consistency through rules** - Format compliance

---

*This Markdown Format Guide defines syntax specifications, structure patterns, and file delivery standards for natural language prompt output. It focuses exclusively on HOW to format Markdown—processing logic handled by DEPTH, quality evaluation by Patterns, and interaction flow by Interactive Mode. Use this guide for baseline human-readable format with optimal clarity.*