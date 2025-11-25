# Prompt Format Guide: YAML

Formatting guide for YAML output structure in prompt engineering with RCAF/CRAFT frameworks, file delivery standards, syntax validation, and format-specific best practices.

**Core Purpose:** Define YAML syntax specifications, structure patterns, validation rules, and file delivery standards. This guide focuses exclusively on HOW to format YAML output—processing logic, cognitive frameworks, and interaction patterns are handled by other guides (DEPTH, Interactive Mode, Patterns).

---

## 📋 Table of Contents

1. [🎯 OVERVIEW & PURPOSE](#-overview--purpose)
2. [📊 YAML FORMAT FUNDAMENTALS](#-yaml-format-fundamentals)
3. [📦 FILE DELIVERY STANDARDS](#-file-delivery-standards)
4. [🔧 RCAF YAML STRUCTURE](#-rcaf-yaml-structure)
5. [🎨 CRAFT YAML STRUCTURE](#-craft-yaml-structure)
6. [📄 ADVANCED YAML PATTERNS](#-advanced-yaml-patterns)
7. [🔄 FORMAT CONVERSIONS](#-format-conversions)
8. [⚖️ YAML VS OTHER FORMATS](#-yaml-vs-other-formats)
9. [💡 EXAMPLES & TEMPLATES](#-examples--templates)
10. [✅ SYNTAX VALIDATION](#-syntax-validation)
11. [🎓 BEST PRACTICES](#-best-practices)

---

<a id="-overview--purpose"></a>

## 1. 🎯 OVERVIEW & PURPOSE

### Why YAML Format?

YAML (YAML Ain't Markup Language) provides human-readable structured data with minimal syntax overhead, making it ideal for configuration-style prompts and multi-level hierarchies.

**Terminology Clarification:**
- **Framework** = Prompt organization (RCAF vs CRAFT)
- **Output Structure** = Data format (Standard/Markdown vs JSON vs YAML)
- This guide covers YAML as an **output structure** option

**See Also:**
- **Markdown Format Guide** - For Standard/Markdown output structure
- **JSON Format Guide** - For JSON output structure
- **Interactive Mode** - For format selection in conversational flow

**YAML Format Benefits:**
- **Human Readable:** Cleaner than JSON, more structured than Standard
- **Minimal Syntax:** No brackets or quotes for simple values
- **Clear Hierarchy:** Indentation-based structure
- **Comment Support:** Inline documentation capability
- **Multi-line Strings:** Natural text block handling

### YAML vs Other Formats Summary

| Aspect | Markdown (Standard) | JSON | YAML |
|--------|-------------------|------|------|
| **Readability** | Natural language | Structured data | Human-friendly structure |
| **Token Usage** | Baseline | +5-10% | +3-7% |
| **Best For** | Human interaction | API integration | Configuration, templates |
| **Framework Fit** | RCAF/CRAFT | RCAF preferred | RCAF optimal |

**Note:** Quality evaluation (CLEAR scoring) and enhancement processing are handled by separate guides (Patterns guide, DEPTH guide).

---

<a id="-yaml-format-fundamentals"></a>

## 2. 📊 YAML FORMAT FUNDAMENTALS

### Core YAML Principles

1. **Indentation Matters:** 2 spaces define hierarchy
2. **No Quotes Required:** For simple strings
3. **Lists with Dashes:** Clean array syntax
4. **Key-Value Simplicity:** Colon separation
5. **Multi-line Support:** Literal and folded blocks

### Basic YAML Prompt Structure

```yaml
instruction: Primary directive for the task
context: Essential background information
parameters:
  key1: value1
  key2: value2
  nested:
    subkey: subvalue
output:
  format: desired structure
  constraints:
    - constraint one
    - constraint two
  requirements:
    - requirement one
    - requirement two
```

### YAML Data Types for Prompts

| Type | Syntax | Example |
|------|--------|---------|
| **String** | No quotes needed | `role: Data Analyst` |
| **Number** | Direct value | `limit: 100` |
| **Boolean** | true/false | `detailed: true` |
| **List** | Dash prefix | `- Python`<br>`- SQL` |
| **Object** | Indented keys | `format:`<br>`  type: report` |
| **Multi-line** | Pipe or > | `description: |`<br>`  Multiple lines` |

---

<a id="-file-delivery-standards"></a>

## 3. 📦 FILE DELIVERY STANDARDS

### 🔴 CRITICAL REQUIREMENTS

#### Mandatory File Delivery

**Core Rule:** Every enhancement MUST be delivered as a downloadable file (.yaml or .yml), NEVER inline or in chat.

**Delivery Methods:**
1. **Claude Desktop App & IDE Environments:** Create actual downloadable file using file creation tool
2. **CLI/Agent Mode (when AGENTS.md present):** Use `/Export` folder with sequential numbering
   - Format: `[###] - descriptive-filename.yaml`
   - Example: `001 - customer-segmentation-analysis.yaml`

**File Creation Requirements:**
- Use file creation tool to generate actual files
- Files must be downloadable/accessible by user
- NO artifacts, NO inline code blocks, NO chat delivery

#### Mandatory Minimal Header Format

**Single-line header at TOP of every YAML file:**
```
Mode: $yaml | Complexity: [level] | Framework: [RCAF/CRAFT]
```

**Header Requirements:**
- **Mode:** Always `$yaml` (with $ prefix)
- **Complexity level:** Low/Medium/High or 1-10
- **Framework used:** RCAF or CRAFT

**Note:** Quality scores (CLEAR) are evaluated separately per Patterns guide and reported in chat, not in file header.

#### YAML File Content Structure

**ONLY these two components in file:**
1. **Single-line header** (with $ prefix)
2. **YAML prompt content**

**FORBIDDEN in YAML files:**
- ❌ Format Options section
- ❌ CLEAR Evaluation breakdown
- ❌ Processing Applied section
- ❌ Additional metadata sections
- ❌ Explanations or commentary
- ✅ All explanations go in CHAT after file delivery

### Pre-Delivery Format Validation

```yaml
validate_yaml_format:
  description: "Format validation before YAML file delivery"
  
  format_checks:
    valid_yaml:
      check: is_valid_yaml_syntax
      required: true
    
    file_delivery:
      check: is_downloadable_file
      required: true
      note: "Must be actual file, not artifact or inline"
    
    header_present:
      check: has_single_line_header
      required: true
    
    header_format:
      check: mode_equals_yaml_with_dollar
      required: true
      expected: "$yaml"
    
    no_extra_sections:
      check: has_only_header_and_content
      required: true
    
    framework_fields:
      check: has_all_required_fields
      required: true
      minimum: ["role", "context", "action", "format"]
    
    indentation_correct:
      check: validate_yaml_indentation
      required: true
      standard: 2_spaces
  
  on_validation_failure:
    action: stop_and_regenerate
    message: "YAML format invalid. Failed checks: {failed_items}"
```

### 🔴 FORMAT COMPLIANCE ENFORCEMENT

#### ABSOLUTE RULES
When `$yaml` command is specified:
1. **Output MUST be valid YAML syntax ONLY**
2. **NO markdown formatting** (no **, no ###, no ```)
3. **NO explanatory text within the artifact**
4. **If cannot produce valid YAML, STOP and report error**
5. **Validate format before delivery - if invalid, RETRY**

#### FORMAT LOCK PROTOCOL
```
DETECTION: $yaml command identified
↓
LOCK: YAML-only output mode engaged
↓
GENERATE: Pure YAML structure
↓
VALIDATE: Is it valid YAML? Can yaml.safe_load() parse it?
↓
If NO → STOP → REGENERATE
If YES → DELIVER
```

#### FORBIDDEN ELEMENTS IN YAML ARTIFACTS
When $yaml is active, these are STRICTLY FORBIDDEN:
- ❌ Markdown bold: `**text**`
- ❌ Markdown headers: `### Header`
- ❌ Code blocks: ` ```yaml `
- ❌ Explanatory text before/after YAML
- ❌ Mixed format output
- ❌ Tabs (use spaces only)
- ❌ Inconsistent indentation

#### CORRECT vs INCORRECT

**✅ CORRECT $yaml artifact:**
```
Mode: $yaml | Complexity: Medium | Framework: RCAF

role: Data analyst
context: Sales database analysis
action: Generate quarterly report
format:
  type: dashboard
  sections:
    - metrics
    - trends
```

**❌ INCORRECT - DO NOT DO THIS:**
```
Mode: $yaml | Complexity: Medium | Framework: RCAF

**Role:** Data analyst
**Context:** Sales database analysis
```
This is MARKDOWN, not YAML! IMMEDIATE FAILURE.

**❌ ALSO INCORRECT:**
```
Mode: $yaml | Complexity: Medium | Framework: RCAF

Here's the YAML prompt:
```yaml
role: Data analyst
```
```
NO explanatory text! NO code blocks! Just pure YAML.

#### ERROR RECOVERY PROTOCOL
**🔴 BLOCKING Protocol** - If wrong format is generated:
```
1. RECOGNIZE: "Output is markdown but should be YAML"
2. 🔴 STOP: Do not deliver wrong format (BLOCKING)
3. ANNOUNCE: "Format error detected. Regenerating as YAML..."
4. RETRY: Generate proper YAML
5. VALIDATE: yaml.safe_load() must succeed + RICCE check
6. DELIVER: Only if valid YAML and all validation gates passed
```

**Zero-tolerance enforcement:** Format violations are 🔴 BLOCKING errors that MUST prevent delivery.

#### VALIDATION GATE
Before delivering ANY $yaml file:

```yaml
enforce_yaml_format:
  description: "Strict YAML format enforcement before file delivery"
  
  check_markdown_indicators:
    forbidden_patterns: ["**", "###", "```", "##", "__"]
    action: scan_content
    on_found:
      result: false
      message: "Markdown detected: {pattern}"
  
  check_tab_characters:
    forbidden: "\t"
    action: scan_content
    on_found:
      result: false
      message: "Tabs detected (YAML requires spaces)"
  
  validate_yaml_syntax:
    parser: yaml_syntax_validator
    action: parse_content_as_yaml
    on_success:
      result: true
      message: "Valid YAML"
    on_failure:
      result: false
      message: "Invalid YAML syntax"
      action_required: regenerate_as_valid_yaml
  
  validate_delivery_method:
    check: is_downloadable_file
    on_failure:
      result: false
      message: "Must be file, not inline/chat"
  
  final_action:
    if_any_failure:
      action: must_regenerate
      reason: "Format validation failed"
```

---

<a id="-rcaf-yaml-structure"></a>

## 4. 🔧 RCAF YAML STRUCTURE

### Standard RCAF YAML Template

```yaml
role: Specific expertise definition
context: Essential background information
action: Clear measurable task
format:
  structure: output type
  requirements:
    - requirement one
    - requirement two
  constraints:
    - limit one
    - limit two
```

### RCAF YAML Examples

#### Simple Analysis Task

**Delivered as file:**
```
Mode: $yaml | Complexity: Medium | Framework: RCAF

role: Financial analyst specializing in SaaS metrics
context: Q4 2024 revenue data from B2B platform
action: Calculate MRR growth and identify top 3 trends
format:
  structure: executive_summary
  length: 500_words
  include:
    - metrics
    - charts
    - recommendations
```

#### Content Creation Task

**Delivered as file:**
```
Mode: $yaml | Complexity: Medium | Framework: RCAF

role: Technical writer with API documentation expertise
context: REST API with 15 endpoints for payment processing
action: Create comprehensive API documentation
format:
  structure: markdown
  sections:
    - overview
    - authentication
    - endpoints
    - examples
  style: developer_friendly
  examples_per_endpoint: 2
```

### RCAF Field Guidelines

| Field | Required | Description | Best Practices |
|-------|----------|-------------|----------------|
| **role** | Yes | Expertise needed | Be specific about domain |
| **context** | Yes | Essential info | Include constraints |
| **action** | Yes | Specific task | Make measurable |
| **format** | Yes | Output structure | Define sections |

---

<a id="-craft-yaml-structure"></a>

## 5. 🎨 CRAFT YAML STRUCTURE

### Standard CRAFT YAML Template

```yaml
context:
  background: Full situation details
  constraints:
    - constraint one
    - constraint two
  assumptions:
    - assumption one
    - assumption two
  
role:
  expertise: Detailed expertise description
  perspective: Specific viewpoint or approach
  
action:
  primary: Main task to accomplish
  subtasks:
    - task one
    - task two
    - task three
  deliverables:
    - deliverable one
    - deliverable two
    
format:
  structure: Output organization type
  specifications:
    length: word_count
    style: tone_and_voice
    sections:
      - section one
      - section two
      
target:
  metrics:
    - metric one
    - metric two
  success_criteria: Definition of successful outcome
```

#### Complex Analysis Task

**Delivered as file:**
```
Mode: $yaml | Complexity: High | Framework: CRAFT

context:
  background: E-commerce platform experiencing 15% cart abandonment
  timeframe: Last 6 months
  data_available:
    - user_sessions
    - transaction_logs
    - surveys
  constraints:
    - GDPR compliance required
    - 30-day deadline

role:
  expertise: UX researcher with e-commerce specialization
  perspective: User-centric analysis approach
  tools: Google Analytics, Hotjar, custom tracking

action:
  primary: Identify cart abandonment root causes
  subtasks:
    - Analyze user behavior patterns
    - Segment users by abandonment stage
    - Correlate with survey responses
    - Generate actionable recommendations

format:
  structure: research_report
  specifications:
    length: 2500_words
    visualizations:
      - flow_diagrams
      - heat_maps
      - conversion_funnels
    sections:
      - executive_summary
      - methodology
      - findings
      - recommendations

target:
  metrics:
    - abandonment_rate_reduction
    - conversion_improvement
  success_criteria: Actionable insights reducing abandonment by 20%
```

---

<a id="-advanced-yaml-patterns"></a>

## 6. 📄 ADVANCED YAML PATTERNS

### Multi-Phase Process YAML

**Delivered as file:**
```
Mode: $yaml | Complexity: High | Framework: RCAF

role: Project coordinator
context: Software deployment for enterprise client
phases:
  - name: Environment Preparation
    action: Setup and validate infrastructure
    outputs:
      - checklist
      - validation_report
      
  - name: Deployment Execution
    action: Execute deployment procedures
    outputs:
      - deployment_log
      - test_results
      
  - name: Post-Deployment
    action: Validate and monitor
    outputs:
      - performance_metrics
      - user_feedback

format:
  per_phase: status_report
  final: comprehensive_summary
  delivery: markdown_documents
```

### Conditional Logic YAML

**Delivered as file:**
```
Mode: $yaml | Complexity: Medium | Framework: RCAF

role: Customer service AI
context: Support ticket classification system
action: Route tickets based on criteria

routing_logic:
  technical:
    route_to: engineering
    priority: assess_severity
    conditions:
      - contains: error
      - contains: bug
      - contains: crash
      
  billing:
    route_to: finance
    priority: high
    conditions:
      - contains: payment
      - contains: invoice
      - contains: subscription
      
  general:
    route_to: support_tier_1
    priority: standard
    default: true

format:
  response: routing_decision
  include:
    - department
    - priority
    - rationale
```

### Template with Anchors YAML

**Delivered as file:**
```
Mode: $yaml | Complexity: Medium | Framework: RCAF

# Define reusable components
defaults: &default_format
  style: professional
  tone: concise
  audience: technical

templates:
  analysis: &analysis_template
    structure: analytical_report
    <<: *default_format
    sections:
      - overview
      - methodology
      - findings
      - recommendations

# Main prompt using anchors
role: Data analyst
context: Customer behavior analysis needed
action: Analyze purchase patterns
format:
  <<: *analysis_template
  length: 2000_words
  visualizations:
    - trend_charts
    - segment_analysis
```

---

<a id="-format-conversions"></a>

## 7. 🔄 FORMAT CONVERSIONS

**Cross-format guidance:**
- **From/To Markdown:** See **Markdown Format Guide**
- **From/To JSON:** See **JSON Format Guide**
- **Interactive selection:** Per **Interactive Mode**

### Standard to YAML Conversion

```yaml
standard_to_yaml_conversion:
  description: "Convert RCAF standard format to YAML"
  
  input_format:
    type: markdown
    structure: RCAF
    fields:
      - "**Role:** {role_text}"
      - "**Context:** {context_text}"
      - "**Action:** {action_text}"
      - "**Format:** {format_text}"
  
  parsing_rules:
    extract_role:
      pattern: "**Role:**"
      action: strip_and_capture_text
      target_field: role
    
    extract_context:
      pattern: "**Context:**"
      action: strip_and_capture_text
      target_field: context
    
    extract_action:
      pattern: "**Action:**"
      action: strip_and_capture_text
      target_field: action
    
    extract_format:
      pattern: "**Format:**"
      action: strip_and_capture_text
      target_field: format
      special_handling: parse_if_contains_commas
  
  output_format:
    type: yaml
    structure:
      role: "{extracted_role}"
      context: "{extracted_context}"
      action: "{extracted_action}"
      format: "{extracted_format}"
    formatting: 
      flow_style: false
      sort_keys: false
      indent: 2
```

### JSON to YAML Conversion

```yaml
json_to_yaml_conversion:
  description: "Convert JSON to YAML format"
  
  input_format:
    type: json
    required_fields: [role, context, action, format]
  
  conversion_process:
    step_1: parse_json_to_dict
    step_2: convert_dict_to_yaml
    
  output_format:
    type: yaml
    formatting:
      flow_style: false
      sort_keys: false
      indent: 2
```

### YAML to Standard Conversion

```yaml
yaml_to_standard_conversion:
  description: "Convert YAML to RCAF standard format"
  
  input_format:
    type: yaml
    required_fields: [role, context, action, format]
  
  output_format:
    type: markdown
    structure: |
      **Role:** {yaml.role}
      **Context:** {yaml.context}
      **Action:** {yaml.action}
      **Format:** {yaml.format}
```

---
    
    return standard
```

---

<a id="-yaml-vs-other-formats"></a>

## 8. ⚖️ YAML VS OTHER FORMATS

**Format Guide References:**
- **Markdown Guide:** See **Markdown Format Guide** for Standard format details
- **JSON Guide:** See **JSON Format Guide** for JSON format details
- **Selection Process:** Per **Interactive Mode** format selection workflow

### When to Use Each Format

| Use YAML When | Use JSON When | Use Standard When |
|---------------|---------------|-------------------|
| Configuration templates | API integration | Natural conversation |
| Human editing needed | Machine parsing only | Creative tasks |
| Complex hierarchies | Simple structures | Quick prompts |
| Comments helpful | Validation required | Flexibility needed |
| Multi-line text common | Data exchange | Single use |

### CLEAR Score Comparison

| Format | Base CLEAR | With DEPTH | Strengths | Weaknesses |
|--------|-----------|------------|-----------|------------|
| **Standard** | 43/50 avg | 48/50 avg | Expression (9/10) | Structure consistency |
| **JSON** | 41/50 avg | 46/50 avg | Arrangement (9/10) | Expression (7/10) |
| **YAML** | 42/50 avg | 47/50 avg | Balance (8/10 avg) | Learning curve |

---

<a id="-examples--templates"></a>

## 9. 💡 EXAMPLES & TEMPLATES

### Template Library

#### Research Template

**Delivered as file:**
```
Mode: $yaml | Complexity: Medium | Framework: RCAF

# Research Prompt Template
role: Research analyst
context: ${RESEARCH_DOMAIN}
action:
  primary: Investigate ${RESEARCH_QUESTION}
  methodology: ${METHOD}
  scope: ${SCOPE_DEFINITION}
  
format:
  structure: research_paper
  sections:
    - abstract
    - introduction
    - methodology
    - findings
    - conclusion
  citations: ${CITATION_STYLE}
  length: ${WORD_COUNT}
```

#### Analysis Template

**Delivered as file:**
```
Mode: $yaml | Complexity: Medium | Framework: RCAF

# Data Analysis Template
role: Data analyst
context:
  dataset: ${DATASET}
  timeframe: ${PERIOD}
  business_context: ${CONTEXT}
  
action: Analyze ${METRICS} and identify ${INSIGHTS_TYPE}

format:
  deliverable: ${OUTPUT_TYPE}
  visualizations: ${CHART_TYPES}
  detail_level: ${DETAIL_LEVEL}
  export_formats:
    - pdf
    - csv
    - interactive_dashboard
```

### Real-World Examples

#### Customer Segmentation

**Delivered as file:**
```
Mode: $yaml | Complexity: Medium | Framework: RCAF

role: Marketing data scientist
context: E-commerce platform with 100K customers, 2 years transaction history

action:
  primary: Perform customer segmentation using RFM analysis
  steps:
    - Calculate recency scores
    - Calculate frequency scores
    - Calculate monetary scores
    - Create segment profiles
    - Generate recommendations

format:
  structure: analysis_report
  include:
    - segment_profiles
    - characteristics
    - size_distribution
    - value_analysis
    - recommendations
  visualizations:
    - segment_distribution
    - value_matrix
    - trend_analysis
  export:
    - csv_data
    - pdf_report
    - interactive_dashboard
```

#### API Documentation

**Delivered as file:**
```
Mode: $yaml | Complexity: High | Framework: CRAFT

context:
  api_type: REST
  endpoints: 25
  authentication: OAuth 2.0
  versioning: semantic

role:
  expertise: Technical documentation specialist
  focus: Developer experience

action:
  document:
    - endpoint_specifications
    - authentication_flow
    - error_handling
    - rate_limits
    - examples

format:
  structure: developer_documentation
  per_endpoint:
    - description
    - parameters
    - request_examples
    - response_examples
    - error_codes
  tools:
    - postman_collection
    - openapi_spec
    - interactive_playground

target:
  metrics:
    - time_to_first_api_call
    - developer_satisfaction
  success_criteria: Complete documentation enabling integration in under 2 hours
```

---

<a id="-syntax-validation"></a>

## 10. ✅ SYNTAX VALIDATION

### Format Enforcement Checklist

Before delivering $yaml file:
- [ ] Command is `$yaml`?
- [ ] Content is PURE YAML?
- [ ] Consistent 2-space indentation?
- [ ] NO tabs (spaces only)?
- [ ] NO markdown formatting?
- [ ] Valid YAML syntax (parseable)?
- [ ] All RCAF/CRAFT fields present?
- [ ] Header has `$yaml` mode?

**If ANY check fails → MUST REGENERATE**

### YAML Syntax Validation

- [ ] Valid YAML syntax
- [ ] Consistent 2-space indentation
- [ ] No tab characters
- [ ] Proper list formatting (dash-space)
- [ ] Multi-line strings handled correctly
- [ ] No trailing spaces
- [ ] UTF-8 encoding
- [ ] Proper key-value separation (colon-space)
- [ ] Quoted strings when necessary
- [ ] No duplicate keys

### Common YAML Syntax Issues

| Issue | Recognition | Solution |
|-------|------------|----------|
| **Indentation error** | Parse fails | Use exactly 2 spaces per level |
| **Tab characters** | Parse fails | Replace tabs with spaces |
| **Missing colon-space** | Key without value | Ensure `key: value` format |
| **List syntax** | Structure errors | Use dash-space prefix: `- item` |
| **Quote confusion** | String parsing issues | Remove unnecessary quotes for simple strings |
| **Duplicate keys** | Parser warning | Ensure unique keys at each level |
| **Trailing spaces** | Formatting inconsistency | Remove trailing whitespace |
| **Wrong indentation** | Hierarchy issues | Maintain consistent 2-space indent |

### YAML Parser Validation

```yaml
validate_yaml_syntax:
  description: "Validate YAML syntax before file delivery"
  
  check_indentation:
    standard: 2_spaces
    forbidden: tabs
    action: scan_content
    on_invalid:
      result: false
      message: "Indentation error: use 2 spaces, no tabs"
  
  validate_yaml_parsing:
    parser: yaml_syntax_validator
    action: parse_content_as_yaml
    
    on_success:
      result: true
      message: "Valid YAML"
    
    on_failure:
      result: false
      message: "Invalid YAML syntax: {error_details}"
      action_required: regenerate_as_valid_yaml
  
  validate_structure:
    check_required_fields: [role, context, action, format]
    check_duplicates: true
    check_trailing_spaces: true
    
    on_failure:
      result: false
      message: "Structure validation failed"
```

---

<a id="-best-practices"></a>

## 11. 🎓 BEST PRACTICES

<a id="-performance-metrics"></a>

## 11. 📈 PERFORMANCE METRICS

### YAML Format Performance

| Metric | Target | Current Average |
|--------|--------|-----------------|
| **Parse Success Rate** | >99% | 99.5% |
| **Token Overhead** | <7% | 5.2% |
| **Base CLEAR Score** | >40/50 | 42/50 |
| **CLEAR with DEPTH** | >45/50 | 47/50 |
| **Human Readability** | High | 9/10 |
| **Edit Efficiency** | >JSON | 1.4x faster |
| **Artifact Delivery** | 100% | 100% |
| **Header Compliance** | 100% | 100% |

### Cognitive Rigor Metrics *(per DEPTH guide)*

| Metric | Target | Current Average |
|--------|--------|-----------------|
| **Perspectives Analyzed** | ≥3 (target 5) | 4.2 perspectives |
| **Multi-angle Assessment** | Every enhancement | 100% coverage |
| **RICCE Completeness** | 100% | 100% validation |
| **DEPTH Phase Coverage** | All 5 phases | 100% application |
| **Cognitive Depth Score** | ≥8/10 | 8.4/10 |
| **🔴 BLOCKING Failures** | 0% | <0.1% rate |

### Optimization Strategies

```python
def optimize_yaml_prompt(yaml_prompt):
    """Optimize YAML for clarity and efficiency"""
    
    import yaml
    
    optimizations = []
    data = yaml.safe_load(yaml_prompt)
    
    # Flatten single-item lists
    for key, value in data.items():
        if isinstance(value, list) and len(value) == 1:
            data[key] = value[0]
            optimizations.append(f"Flattened {key}")
    
    # Remove null values
    data = {k: v for k, v in data.items() if v is not None}
    if len(data) < len(yaml.safe_load(yaml_prompt)):
        optimizations.append("Removed null values")
    
    # Use flow style for short lists
    for key, value in data.items():
        if isinstance(value, list) and len(value) <= 3:
            optimizations.append(f"Compacted {key} list")
    
    return yaml.dump(data, default_flow_style=False), optimizations
```

---

<a id="-troubleshooting"></a>

## 12. 🔧 TROUBLESHOOTING

### Common YAML Issues & Fixes

| Issue | Recognition | Solution | Report in Chat |
|-------|------------|----------|----------------|
| **Not artifact** | Chat delivery | Force artifact | "Retrying artifact creation..." |
| **Wrong type** | text/plain | Change to text/markdown | "Fixing artifact type..." |
| **Indentation errors** | Parse fails | Use exactly 2 spaces | "Correcting indentation..." |
| **Quote confusion** | String parsing issues | Remove unnecessary quotes | "Simplifying syntax..." |
| **List syntax** | Structure errors | Ensure dash-space prefix | "Fixing list format..." |
| **Extra sections** | Explanations in artifact | Move to chat | "Cleaning artifact..." |
| **No transparency** | Missing report | Add after delivery | "Adding enhancement details..." |

### Validation Checklist

- [ ] Consistent 2-space indentation
- [ ] All RCAF/CRAFT fields present
- [ ] No tabs (spaces only)
- [ ] Valid YAML syntax
- [ ] Proper list formatting
- [ ] Multiline strings handled correctly
- [ ] No trailing spaces
- [ ] UTF-8 encoding
- [ ] Artifact header present with $yaml
- [ ] CLEAR score ≥ 40/50 target
- [ ] Transparency report ready

### REPAIR Protocol with Transparency

```markdown
**R** - Recognize: YAML issue identified
**E** - Explain: Impact on structure
**P** - Propose: Correction approach
**A** - Apply: Fix implemented
**I** - Iterate: Verify YAML validity
**R** - Record: Note in transparency report
```

---

<a id="-best-practices"></a>

## 13. 🎓 BEST PRACTICES

### YAML Prompt Excellence

### YAML Format Do's ✅

**Syntax & Structure:**
- Use 2-space indentation consistently
- Keep hierarchy shallow (<4 levels)
- Use meaningful key names
- Leverage multiline strings for text
- Add comments for complex sections (YAML supports #)
- Validate before delivery
- Use anchors (&) and aliases (*) for repeated content
- Test with YAML validators

**File Delivery:**
- Deliver as downloadable file (.yaml or .yml)
- Use `$yaml` mode in header
- Create actual file using file creation tool
- Include only header + YAML content in file
- Place explanations in chat after file delivery
- In CLI/Agent mode: Use /Export folder with sequential numbering

**Structure Quality:**
- Use proper list syntax (dash-space)
- Handle multi-line strings with | or >
- Ensure consistent spacing
- Document complex schemas with comments
- Version your templates
- Ensure UTF-8 encoding

### YAML Format Don'ts ❌

**Syntax & Structure:**
- Don't mix tabs and spaces (use spaces only)
- Don't over-nest structures (>4 levels)
- Don't use special characters in keys without quotes
- Don't forget list dash-space prefix
- Don't use flow style for complex data
- Don't ignore indentation rules
- Don't embed complex logic

**File Delivery:**
- Don't deliver in chat (file only)
- Don't add verbose sections to file
- Don't deliver as inline code blocks
- Don't skip validation
- Don't include explanations in file (chat only)

**Quality Issues:**
- Don't leave empty required fields
- Don't create duplicate keys at same level
- Don't use inconsistent indentation
- Don't forget trailing newline

### Framework Selection for YAML

| Complexity | Framework | YAML Structure |
|------------|-----------|----------------|
| Simple (1-3) | RCAF | Flat, 4 keys |
| Medium (4-6) | RCAF | Nested format |
| Complex (7-10) | CRAFT | Multi-level hierarchy |

### YAML Quality Metrics

### YAML Format Principles

> "Structure with humanity. YAML bridges machine precision with human readability."

**Core Format Principles:**
1. **Clarity through indentation** - Visual hierarchy
2. **Simplicity through minimalism** - Less syntax overhead
3. **Flexibility through structure** - Nested when needed
4. **Readability through spacing** - Natural formatting
5. **Maintainability through comments** - Self-documenting capability
6. **Focus through minimalism** - Minimal header only
7. **Consistency through rules** - Format compliance

### Token Efficiency

**YAML Token Overhead:**
- Baseline vs Standard format: +3-7%
- Main overhead: Indentation, list markers, key names
- Optimization: Remove nulls, flatten single items, use anchors for repetition

**Optimization Techniques:**
```yaml
# Less efficient (verbose keys)
artificial_intelligence_model_role: expert

# More efficient (concise keys)
role: expert

# Use anchors for repetition
defaults: &defaults
  format: report
  length: 1000

task_1:
  <<: *defaults
  specific: value
```

### Format Quality Checklist

**Excellent YAML Format:**
- ✅ Valid YAML syntax (parseable)
- ✅ All framework fields present
- ✅ Consistent 2-space indentation
- ✅ Shallow nesting (<4 levels)
- ✅ No syntax errors
- ✅ Delivered as downloadable file (.yaml/.yml)
- ✅ Single-line header with $yaml
- ✅ Clean structure (no markdown)
- ✅ Proper spacing and formatting
- ✅ Configuration-ready format

### The YAML Philosophy

> "Structure with humanity. YAML bridges machine precision with human readability."

**YAML Format Principles:**
1. **Clarity through indentation** - Visual hierarchy
2. **Simplicity through minimalism** - Less syntax overhead
3. **Flexibility through structure** - Nested when needed
4. **Readability through spacing** - Natural formatting
5. **Maintainability through comments** - Self-documenting
6. **Focus through minimalism** - Single header only
7. **Transparency through reporting** - Process visible in chat

### Command Activation

To use YAML format, users can *(per Interactive Mode)*:
- Use `$yaml` command for automatic YAML formatting
- Use `$y` as shorthand
- Combine with modes: `$improve $yaml` or `$refine $yaml`
- Request in Interactive Mode when format selection appears

**See:** **Interactive Mode** for complete command reference and conversational format selection workflow.

### Success Criteria

**Excellent YAML Prompt:**
- ✅ Valid YAML syntax
- ✅ All RCAF/CRAFT elements present
- ✅ Consistent indentation
- ✅ Clear hierarchy
- ✅ Minimal nesting
- ✅ Human readable
- ✅ Delivered as downloadable file (.yaml/.yml)
- ✅ Single-line header with $yaml
- ✅ Configuration-ready format
- ✅ Token overhead < 7%
- ✅ YAML-native validation

---

*This YAML Format Guide defines syntax specifications, structure patterns, and file delivery standards for YAML prompt output. It focuses exclusively on HOW to format YAML—processing logic handled by DEPTH, quality evaluation by Patterns, and interaction flow by Interactive Mode. Use this guide for configuration templates, human-readable structured data, and multi-level hierarchies.*