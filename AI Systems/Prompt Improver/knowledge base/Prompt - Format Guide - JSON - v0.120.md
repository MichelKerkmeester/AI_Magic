# Prompt Format Guide: JSON

Formatting guide for JSON output structure in prompt engineering with RCAF/CRAFT frameworks, file delivery standards, syntax validation, and format-specific best practices.

**Core Purpose:** Define JSON syntax specifications, structure patterns, validation rules, and file delivery standards. This guide focuses exclusively on HOW to format JSON output—processing logic, cognitive frameworks, and interaction patterns are handled by other guides (DEPTH, Interactive Mode, Patterns).

---

## 📋 TABLE OF CONTENTS

1. [🎯 OVERVIEW & PURPOSE](#-overview--purpose)
2. [📊 JSON FORMAT FUNDAMENTALS](#-json-format-fundamentals)
3. [📦 FILE DELIVERY STANDARDS](#-file-delivery-standards)
4. [🔧 RCAF JSON STRUCTURE](#-rcaf-json-structure)
5. [🎨 CRAFT JSON STRUCTURE](#-craft-json-structure)
6. [📄 ADVANCED JSON PATTERNS](#-advanced-json-patterns)
7. [🔄 FORMAT CONVERSIONS](#-format-conversions)
8. [⚖️ JSON VS OTHER FORMATS](#-json-vs-other-formats)
9. [💡 EXAMPLES & TEMPLATES](#-examples--templates)
10. [✅ SYNTAX VALIDATION](#-syntax-validation)
11. [🎓 BEST PRACTICES](#-best-practices)

---

<a id="-overview--purpose"></a>

## 1. 🎯 OVERVIEW & PURPOSE

### Why JSON Format?

JSON format provides structured, machine-parseable prompt engineering with consistent field access and programmatic integration capabilities.

**JSON Format Benefits:**
- **Structured Data:** Clear field separation and hierarchy
- **API Integration:** Direct compatibility with systems
- **Consistent Parsing:** Reliable field extraction
- **Type Safety:** Explicit data types
- **Validation:** Schema-based verification

### JSON vs Other Formats Summary

| Aspect | Markdown (Standard) | JSON | YAML |
|--------|-------------------|------|------|
| **Readability** | Natural language | Structured data | Human-friendly structure |
| **Token Usage** | Baseline | +5-10% | +3-7% |
| **Best For** | Human interaction | API/System integration | Configuration |
| **Framework Fit** | RCAF/CRAFT | RCAF preferred | RCAF optimal |

**Note:** Quality evaluation (CLEAR scoring) and enhancement processing are handled by separate guides (Patterns guide, DEPTH guide).

---

<a id="-json-format-fundamentals"></a>

## 2. 📊 JSON FORMAT FUNDAMENTALS

### Core JSON Principles

1. **Structure Over Prose:** Fields replace sentences
2. **Explicit Types:** Clear data type definitions
3. **Hierarchical Organization:** Nested structures for complexity
4. **Schema Consistency:** Predictable field patterns
5. **Minimal Redundancy:** No repeated information

### Basic JSON Prompt Structure

```json
{
  "instruction": "Primary directive",
  "context": "Essential information",
  "parameters": {
    "key1": "value1",
    "key2": "value2"
  },
  "output": {
    "format": "desired structure",
    "constraints": ["constraint1", "constraint2"]
  }
}
```

### JSON Data Types for Prompts

| Type | Use Case | Example |
|------|----------|---------|
| **String** | Text values | `"role": "Data Analyst"` |
| **Number** | Quantities | `"limit": 100` |
| **Boolean** | Flags | `"detailed": true` |
| **Array** | Lists | `"skills": ["Python", "SQL"]` |
| **Object** | Nested structure | `"format": {"type": "report"}` |

---

<a id="-file-delivery-standards"></a>

## 3. 📦 FILE DELIVERY STANDARDS

### 🔴 CRITICAL REQUIREMENTS

#### Mandatory File Delivery

**Core Rule:** Every enhancement MUST be delivered as a downloadable file (.json), NEVER inline or in chat.

**Delivery Methods:**
1. **Claude Desktop App & IDE Environments:** Create actual downloadable file using file creation tool
2. **CLI/Agent Mode (when AGENTS.md present):** Use `/Export` folder with sequential numbering
   - Format: `[###] - descriptive-filename.json`
   - Example: `001 - customer-segmentation-analysis.json`

**File Creation Requirements:**
- Use file creation tool to generate actual files
- Files must be downloadable/accessible by user
- NO artifacts, NO inline code blocks, NO chat delivery

#### Mandatory Minimal Header Format

**Single-line header at TOP of every JSON file:**
```
Mode: $json | Complexity: [level] | Framework: [RCAF/CRAFT]
```

**Header Requirements:**
- **Mode:** Always `$json` (with $ prefix)
- **Complexity level:** Low/Medium/High or 1-10
- **Framework used:** RCAF or CRAFT

**Note:** Quality scores (CLEAR) are evaluated separately per Patterns guide and reported in chat, not in file header.

#### JSON File Content Structure

**ONLY these two components in file:**
1. **Single-line header** (with $ prefix)
2. **JSON prompt content**

**FORBIDDEN in JSON files:**
- ❌ Format Options section
- ❌ CLEAR Evaluation breakdown
- ❌ Processing Applied section
- ❌ Additional metadata sections
- ❌ Explanations or commentary
- ✅ All explanations go in CHAT after file delivery

### Pre-Delivery Format Validation

```yaml
validate_json_format:
  description: "Format validation before JSON file delivery"
  
  format_checks:
    valid_json:
      check: is_valid_json_syntax
      required: true
    
    file_delivery:
      check: is_downloadable_file
      required: true
      note: "Must be actual file, not artifact or inline"
    
    header_present:
      check: has_single_line_header
      required: true
    
    header_format:
      check: mode_equals_json_with_dollar
      required: true
      expected: "$json"
    
    no_markdown:
      check: has_no_markdown_syntax
      required: true
      forbidden: ["**", "###", "```", "__"]
    
    no_extra_sections:
      check: has_only_header_and_content
      required: true
    
    framework_fields:
      check: has_all_required_fields
      required: true
      minimum: ["role", "context", "action", "format"]
  
  on_validation_failure:
    action: stop_and_regenerate
    message: "JSON format invalid. Failed checks: {failed_items}"
```

### 🔴 FORMAT COMPLIANCE ENFORCEMENT

#### ABSOLUTE RULES
When `$json` command is specified:
1. **Output MUST be valid JSON syntax ONLY**
2. **Output MUST be delivered as downloadable file (.json)**
3. **NO markdown formatting** (no **, no ###, no ```)
4. **NO explanatory text within the file**
5. **If cannot produce valid JSON, STOP and report error**
6. **Validate format before delivery - if invalid, RETRY**

#### FORMAT LOCK PROTOCOL
```yaml
format_lock_protocol:
  step_1_detection:
    trigger: "$json command identified"
    action: engage_json_only_mode
  
  step_2_lock:
    mode: json_only_output
    file_type: .json
    delivery: downloadable_file
  
  step_3_generate:
    output: pure_json_structure
    forbidden: [markdown, explanations, code_blocks]
  
  step_4_validate:
    check: is_valid_json_syntax
    method: json_parser_test
  
  step_5_decision:
    if_valid:
      action: deliver_as_file
    if_invalid:
      action: stop_and_regenerate
```

#### FORBIDDEN ELEMENTS IN JSON FILES
When $json is active, these are STRICTLY FORBIDDEN:
- ❌ Markdown bold: `**text**`
- ❌ Markdown headers: `### Header`
- ❌ Code blocks: ` ```json `
- ❌ Explanatory text before/after JSON
- ❌ Comments within JSON (JSON doesn't support comments)
- ❌ Mixed format output
- ❌ Inline/chat delivery (must be file)

#### CORRECT vs INCORRECT

**✅ CORRECT $json file delivery:**

**File:** `customer-analysis.json` (or `001 - customer-analysis.json` in /Export)
```
Mode: $json | Complexity: Medium | Framework: RCAF

{
  "role": "Data analyst",
  "context": "Sales database analysis",
  "action": "Generate quarterly report",
  "format": {
    "type": "dashboard",
    "sections": ["metrics", "trends"]
  }
}
```

**❌ INCORRECT - DO NOT DO THIS:**

**Delivering as inline code in chat:**
```
Mode: $json | Complexity: Medium | Framework: RCAF

**Role:** Data analyst
**Context:** Sales database analysis
```
This is MARKDOWN, not JSON! Also NOT delivered as file!

**❌ ALSO INCORRECT:**

**Delivering with explanatory text in file:**
```
Mode: $json | Complexity: Medium | Framework: RCAF

Here's the JSON prompt:
```json
{
  "role": "Data analyst"
}
```
```
NO explanatory text in file! NO code blocks! Just pure JSON. Explanations go in chat AFTER file delivery.

#### ERROR RECOVERY PROTOCOL
If wrong format is generated:

```yaml
error_recovery:
  step_1_recognize:
    check: "Is output markdown instead of JSON?"
    or_check: "Is output inline instead of file?"
  
  step_2_stop:
    action: halt_delivery
    reason: "Wrong format detected"
  
  step_3_announce:
    message: "Format error detected. Regenerating as JSON file..."
  
  step_4_retry:
    action: generate_proper_json
    ensure: pure_json_syntax
  
  step_5_validate:
    test: json_parser_validation
    must_succeed: true
  
  step_6_deliver:
    condition: validation_passed
    method: create_downloadable_file
    location: 
      - claude_desktop_ide: direct_file_creation
      - cli_agent: /export/[###]-filename.json
```

#### VALIDATION GATE
Before delivering ANY $json file:

```yaml
enforce_json_format:
  description: "Strict JSON format enforcement before file delivery"
  
  check_markdown_indicators:
    forbidden_patterns: ["**", "###", "```", "##", "__"]
    action: scan_content
    on_found:
      result: false
      message: "Markdown detected: {pattern}"
  
  validate_json_syntax:
    parser: json_syntax_validator
    action: parse_content
    on_success:
      result: true
      message: "Valid JSON"
    on_failure:
      result: false
      message: "Invalid JSON syntax"
  
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

<a id="-rcaf-json-structure"></a>

## 4. 🔧 RCAF JSON STRUCTURE

### Standard RCAF JSON Template

```json
{
  "role": "Specific expertise definition",
  "context": "Essential background information",
  "action": "Clear measurable task",
  "format": {
    "structure": "output type",
    "requirements": ["req1", "req2"],
    "constraints": ["limit1", "limit2"]
  }
}
```

### RCAF JSON Examples

#### Simple Analysis Task

**Delivered as file:**
```
Mode: $json | Complexity: Medium | Framework: RCAF

{
  "role": "Financial analyst specializing in SaaS metrics",
  "context": "Q4 2024 revenue data from B2B platform with 10K customers",
  "action": "Calculate MRR growth and identify top 3 trends",
  "format": {
    "structure": "executive_summary",
    "length": "500_words",
    "include": ["metrics", "charts", "recommendations"]
  }
}
```

#### Content Creation Task

**Delivered as file:**
```
Mode: $json | Complexity: Medium | Framework: RCAF

{
  "role": "Technical writer with API documentation expertise",
  "context": "REST API with 15 endpoints for payment processing",
  "action": "Create comprehensive API documentation",
  "format": {
    "structure": "markdown",
    "sections": ["overview", "authentication", "endpoints", "examples"],
    "style": "developer_friendly"
  }
}
```

### RCAF JSON Field Guidelines

| Field | Required | Description | Purpose |
|-------|----------|-------------|---------|
| **role** | Yes | Expertise needed | Defines AI's perspective and knowledge domain |
| **context** | Yes | Essential info | Provides situation, constraints, and background |
| **action** | Yes | Specific task | Specifies what AI should do |
| **format** | Yes | Output structure | Defines how results should be organized |

---

<a id="-craft-json-structure"></a>

## 5. 🎨 CRAFT JSON STRUCTURE

### Standard CRAFT JSON Template

```json
{
  "context": {
    "background": "Full situation details",
    "constraints": ["constraint1", "constraint2"],
    "assumptions": ["assumption1", "assumption2"]
  },
  "role": {
    "expertise": "Detailed expertise",
    "perspective": "Specific viewpoint"
  },
  "action": {
    "primary": "Main task",
    "subtasks": ["task1", "task2", "task3"],
    "deliverables": ["deliverable1", "deliverable2"]
  },
  "format": {
    "structure": "Output organization",
    "specifications": {
      "length": "word_count",
      "style": "tone",
      "sections": ["section1", "section2"]
    }
  },
  "target": {
    "metrics": ["metric1", "metric2"],
    "success_criteria": "Definition of success"
  }
}
```

#### Complex Analysis Task

**Delivered as file:**
```
Mode: $json | Complexity: High | Framework: CRAFT

{
  "context": {
    "background": "E-commerce platform experiencing 15% cart abandonment",
    "timeframe": "Last 6 months",
    "data_available": ["user_sessions", "transaction_logs", "surveys"],
    "constraints": ["GDPR compliance", "30-day deadline"]
  },
  "role": {
    "expertise": "UX researcher with e-commerce specialization",
    "perspective": "User-centric analysis"
  },
  "action": {
    "primary": "Identify cart abandonment root causes",
    "subtasks": [
      "Analyze user behavior patterns",
      "Segment users by abandonment stage",
      "Correlate with survey responses"
    ]
  },
  "format": {
    "structure": "research_report",
    "specifications": {
      "length": "2500_words",
      "visualizations": ["flow_diagrams", "heat_maps"],
      "sections": ["executive_summary", "methodology", "findings", "recommendations"]
    }
  },
  "target": {
    "metrics": ["abandonment_rate_reduction", "conversion_improvement"],
    "success_criteria": "Actionable insights reducing abandonment by 20%"
  }
}
```

---

<a id="-advanced-json-patterns"></a>

## 6. 📄 ADVANCED JSON PATTERNS

### Multi-Step Process JSON

**Delivered as file:**
```
Mode: $json | Complexity: High | Framework: RCAF

{
  "role": "Project coordinator",
  "context": "Software deployment for enterprise client",
  "action": {
    "phase_1": {
      "task": "Environment preparation",
      "outputs": ["checklist", "validation_report"]
    },
    "phase_2": {
      "task": "Deployment execution",
      "outputs": ["deployment_log", "test_results"]
    },
    "phase_3": {
      "task": "Post-deployment validation",
      "outputs": ["performance_metrics", "user_feedback"]
    }
  },
  "format": {
    "per_phase": "status_report",
    "final": "comprehensive_summary"
  }
}
```

### Conditional Logic JSON

**Delivered as file:**
```
Mode: $json | Complexity: Medium | Framework: RCAF

{
  "role": "Customer service AI",
  "context": "Support ticket classification system",
  "action": "Route tickets based on criteria",
  "logic": {
    "if_technical": {
      "route_to": "engineering",
      "priority": "assess_severity"
    },
    "if_billing": {
      "route_to": "finance",
      "priority": "high"
    },
    "if_general": {
      "route_to": "support_tier_1",
      "priority": "standard"
    }
  },
  "format": {
    "response": "routing_decision",
    "include": ["department", "priority", "rationale"]
  }
}
```

### Parameterized Template JSON

**Delivered as file:**
```
Mode: $json | Complexity: Medium | Framework: RCAF

{
  "template": "data_analysis",
  "parameters": {
    "dataset": "${DATASET_NAME}",
    "metrics": "${METRICS_ARRAY}",
    "timeframe": "${TIME_PERIOD}",
    "filters": "${FILTER_CONDITIONS}"
  },
  "role": "Data analyst",
  "context": "Business intelligence reporting",
  "action": "Generate insights from ${DATASET_NAME}",
  "format": {
    "structure": "dashboard",
    "charts": ["${CHART_TYPES}"],
    "export": "${OUTPUT_FORMAT}"
  }
}
```

---

<a id="-format-conversions"></a>

## 7. 🔄 FORMAT CONVERSIONS

### Standard to JSON Conversion

```yaml
standard_to_json_conversion:
  description: "Convert RCAF standard format to JSON"
  
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
  
  output_format:
    type: json
    structure:
      role: "{extracted_role}"
      context: "{extracted_context}"
      action: "{extracted_action}"
      format: "{extracted_format}"
    formatting: indent_2_spaces
```

### JSON to Standard Conversion

```yaml
json_to_standard_conversion:
  description: "Convert JSON to RCAF standard format"
  
  input_format:
    type: json
    required_fields: [role, context, action, format]
  
  output_format:
    type: markdown
    structure: |
      **Role:** {json.role}
      **Context:** {json.context}
      **Action:** {json.action}
      **Format:** {json.format}
```

---

<a id="-json-vs-other-formats"></a>

## 8. ⚖️ JSON VS OTHER FORMATS

### When to Use JSON Format

| Use JSON When | Use Standard When | Use YAML When |
|---------------|-------------------|---------------|
| API integration needed | Human readability priority | Configuration templates |
| Structured data processing | Natural conversation flow | Human editing needed |
| Programmatic generation | Creative or open-ended tasks | Complex hierarchies |
| Schema validation required | Flexibility needed | Comments helpful |
| Batch processing | Single prompt usage | Multi-line text common |

### CLEAR Score Impact

| Format | Avg CLEAR | Strengths | Weaknesses |
|--------|-----------|-----------|------------|
| **Standard** | 43/50 | Expression (9/10), Natural flow | Structure consistency |
| **JSON** | 41/50 | Arrangement (9/10), Precision | Expression (7/10) |
| **YAML** | 42/50 | Balance (8/10 avg) | Learning curve |

---

<a id="-examples--templates"></a>

## 9. 💡 EXAMPLES & TEMPLATES

### Template Library

#### Research Template

**Delivered as file:**
```
Mode: $json | Complexity: Medium | Framework: RCAF

{
  "role": "Research analyst",
  "context": "${RESEARCH_DOMAIN}",
  "action": {
    "primary": "Investigate ${RESEARCH_QUESTION}",
    "methodology": "${METHOD}",
    "scope": "${SCOPE_DEFINITION}"
  },
  "format": {
    "structure": "research_paper",
    "sections": ["abstract", "introduction", "methodology", "findings", "conclusion"],
    "citations": "${CITATION_STYLE}"
  }
}
```

#### Analysis Template

**Delivered as file:**
```
Mode: $json | Complexity: Medium | Framework: RCAF

{
  "role": "Data analyst",
  "context": {
    "dataset": "${DATASET}",
    "timeframe": "${PERIOD}",
    "business_context": "${CONTEXT}"
  },
  "action": "Analyze ${METRICS} and identify ${INSIGHTS_TYPE}",
  "format": {
    "deliverable": "${OUTPUT_TYPE}",
    "visualizations": "${CHART_TYPES}",
    "level_of_detail": "${DETAIL_LEVEL}"
  }
}
```

### Real-World Examples

#### Customer Segmentation

**Delivered as file:**
```
Mode: $json | Complexity: High | Framework: RCAF

{
  "role": "Marketing data scientist",
  "context": "E-commerce platform with 100K customers, 2 years transaction history",
  "action": "Perform customer segmentation using RFM analysis",
  "format": {
    "structure": "analysis_report",
    "include": ["segment_profiles", "characteristics", "recommendations"],
    "visualizations": ["segment_distribution", "value_matrix"],
    "export": "csv_and_pdf"
  }
}
```

---

<a id="-syntax-validation"></a>

## 10. ✅ SYNTAX VALIDATION

### Format Enforcement Checklist

Before delivering $json file:
- [ ] Command is `$json`?
- [ ] Content is PURE JSON?
- [ ] NO markdown bold (`**`)?
- [ ] NO markdown headers (`###`)?
- [ ] NO code blocks (` ``` `)?
- [ ] NO explanatory text?
- [ ] Valid JSON syntax (parseable)?
- [ ] All RCAF/CRAFT fields present?
- [ ] Header has `$json` mode?

**If ANY check fails → MUST REGENERATE**

### JSON Syntax Validation

- [ ] Valid JSON syntax
- [ ] Consistent data types
- [ ] No circular references
- [ ] Reasonable nesting depth (<4)
- [ ] UTF-8 encoding
- [ ] No trailing commas
- [ ] Escaped special characters
- [ ] Properly closed brackets/braces
- [ ] Quoted keys and string values
- [ ] No comments (JSON doesn't support)

### Common JSON Syntax Issues

| Issue | Recognition | Solution |
|-------|------------|----------|
| **Invalid JSON** | Parse errors | Validate with JSON linter |
| **Format violation** | Markdown instead of JSON | STOP and regenerate as pure JSON |
| **Mixed format** | JSON with markdown | Strip markdown elements |
| **Trailing commas** | Extra comma at end | Remove trailing commas |
| **Unquoted keys** | Parse failure | Wrap all keys in quotes |
| **Single quotes** | Parse failure | Use double quotes only |
| **Comments** | Parse failure | Remove comments (not valid JSON) |
| **Missing braces** | Incomplete structure | Add closing brackets/braces |

### JSON Parser Validation

```yaml
validate_json_syntax:
  description: "Validate JSON syntax before file delivery"
  
  check_markdown_indicators:
    forbidden_patterns:
      - "**"
      - "###"
      - "```"
      - "##"
      - "__"
    
    validation_logic:
      for_each: pattern
      scan: content
      if_found:
        result: false
        message: "Markdown detected: {pattern}"
  
  validate_json_parsing:
    parser: json_syntax_validator
    action: parse_content_as_json
    
    on_success:
      result: true
      message: "Valid JSON"
    
    on_failure:
      result: false
      message: "Invalid JSON syntax: {error_details}"
      action_required: regenerate_as_valid_json
```

---

<a id="-best-practices"></a>

## 11. 🎓 BEST PRACTICES

### JSON Format Do's ✅

**Syntax & Structure:**
- Use double quotes for keys and strings
- Validate JSON before delivery
- Keep nesting shallow (<4 levels)
- Use consistent field naming (snake_case or camelCase)
- Include all required framework fields (RCAF/CRAFT)
- Escape special characters properly
- Use appropriate data types (string, number, boolean, array, object)

**File Delivery:**
- Deliver as downloadable file (.json)
- Use `$json` mode in header
- Create actual file using file creation tool
- Include only header + JSON content in file
- Place explanations in chat after file delivery
- In CLI/Agent mode: Use /Export folder with sequential numbering

**Structure Quality:**
- Use arrays for multiple similar items
- Flatten structures where possible
- Document complex schemas
- Version your templates
- Test with JSON validators
- Ensure UTF-8 encoding

### JSON Format Don'ts ❌

**Syntax & Structure:**
- Don't use trailing commas
- Don't include comments (not valid JSON)
- Don't use single quotes
- Don't over-nest structures (>4 levels)
- Don't mix data types inconsistently
- Don't use reserved keywords as keys
- Don't forget closing brackets/braces

**File Delivery:**
- Don't deliver in chat (file only)
- Don't add verbose sections to file
- Don't deliver as inline code blocks
- Don't include markdown formatting in JSON
- Don't skip validation
- Don't mix JSON with markdown syntax

**Quality Issues:**
- Don't leave empty required fields
- Don't create circular references
- Don't embed complex logic in JSON
- Don't use undefined or null unnecessarily

### Framework Structure Guidelines

| Complexity | Framework | JSON Structure | Nesting Depth |
|------------|-----------|----------------|---------------|
| Simple (1-3) | RCAF | Flat structure | 1-2 levels |
| Medium (4-6) | RCAF | Nested format field | 2-3 levels |
| Complex (7-10) | CRAFT | Multi-level nesting | 3-4 levels |

### JSON Format Principles

> "Structure enables consistency. Consistency enables automation. Automation enables scale."

**Core Format Principles:**
1. **Clarity through structure** - Clear field separation
2. **Precision through types** - Explicit data types
3. **Reusability through templates** - Parameterized patterns
4. **Integration through standards** - API compatibility
5. **Quality through validation** - Syntax enforcement
6. **Focus through minimalism** - Minimal header only
7. **Consistency through rules** - Format compliance

### Token Efficiency

**JSON Token Overhead:**
- Baseline vs Standard format: +5-10%
- Main overhead: Brackets, quotes, field names
- Optimization: Remove nulls, flatten single items, use concise keys

**Optimization Techniques:**
```json
// Less efficient (verbose keys)
{
  "artificial_intelligence_model_role": "expert"
}

// More efficient (concise keys)
{
  "role": "expert"
}
```

### Format Quality Checklist

**Excellent JSON Format:**
- ✅ Valid JSON syntax (parseable)
- ✅ All framework fields present
- ✅ Consistent data types
- ✅ Shallow nesting (<4 levels)
- ✅ No syntax errors
- ✅ Delivered as downloadable file (.json)
- ✅ Single-line header with $json
- ✅ Clean structure (no markdown)
- ✅ Proper escaping
- ✅ API-ready format

---

*This JSON Format Guide defines syntax specifications, structure patterns, and file delivery standards for JSON prompt output. It focuses exclusively on HOW to format JSON—processing logic handled by DEPTH, quality evaluation by Patterns, and interaction flow by Interactive Mode. Use this guide for API integration, system-to-system communication, and programmatic parsing.*