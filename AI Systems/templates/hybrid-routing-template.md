# [CUSTOMIZE: System Name] - Hybrid Routing Architecture

<!--
TEMPLATE INSTRUCTIONS:
- Replace all [CUSTOMIZE] markers with your specific content
- Keep the ═ separator style for all section headers
- Maintain the 6-section structure in this exact order
- Use CONFIDENCE_THRESHOLDS constants (do not use inline values)
- Reference this spec: specs/001-hybrid-routing-architecture/spec.md
-->

---

─────────────────────────────────────────────────────────────────────────────────
## SECTION 1: COMMAND ENTRY POINTS
─────────────────────────────────────────────────────────────────────────────────

<!--
INSTRUCTIONS:
- List ALL user-facing commands using markdown tree syntax
- Use ├─► and └─► for branch notation
- End branches with STATIC: (direct resource lookup) or HANDLER: (Python delegation)
- Always include a DEFAULT fallback case
- Group related commands together
-->

### 1.1 [CUSTOMIZE: Primary Command Group]

```
/[CUSTOMIZE: command] [args]
    │
    ├─► [CUSTOMIZE: pattern1]
    │   └─► STATIC: [CUSTOMIZE: resource_key]
    │
    ├─► [CUSTOMIZE: pattern2]
    │   └─► HANDLER: [CUSTOMIZE: handler_name]
    │
    ├─► [CUSTOMIZE: pattern3]
    │   ├─► [subpattern_a]
    │   │   └─► STATIC: [CUSTOMIZE: resource_key]
    │   └─► [subpattern_b]
    │       └─► HANDLER: [CUSTOMIZE: handler_name]
    │
    └─► DEFAULT
        └─► HANDLER: default_handler
```

### 1.2 [CUSTOMIZE: Secondary Command Group]

```
/[CUSTOMIZE: command2] [args]
    │
    ├─► [CUSTOMIZE: pattern1]
    │   └─► STATIC: [CUSTOMIZE: resource_key]
    │
    └─► DEFAULT
        └─► HANDLER: fallback_handler
```

---

─────────────────────────────────────────────────────────────────────────────────
## SECTION 2: SMART ROUTING LOGIC
─────────────────────────────────────────────────────────────────────────────────

<!--
INSTRUCTIONS:
- Use Python pseudo-code ONLY for conditional/threshold logic
- Always use CONFIDENCE_THRESHOLDS constant (defined below)
- Include named decision blocks with # ── separator comments
- Use standard return types: Resource(), Execute(), Default()
- All functions must have docstrings with Purpose and Returns
-->

### 2.1 Universal Constants

```python
# ─────────────────────────────────────────────────────────────────────────────
# CONFIDENCE THRESHOLDS - DO NOT MODIFY VALUES
# ─────────────────────────────────────────────────────────────────────────────

CONFIDENCE_THRESHOLDS = {
    "HIGH": 0.85,      # Direct route, no clarification needed
    "MEDIUM": 0.60,    # Route with confirmation prompt
    "LOW": 0.40,       # Use fallback chain
    "FALLBACK": 0.0    # Interactive/default mode
}
```

### 2.2 [CUSTOMIZE: Primary Handler Name]

```python
def [CUSTOMIZE: handler_name](request, context):
    """
    Purpose: [CUSTOMIZE: What this handler decides/routes]
    Returns: Resource() | Execute() | Default()
    """

    # ── Blocking Gate: [CUSTOMIZE: Gate description] ──────────────────────────
    if [CUSTOMIZE: blocking_condition]:
        return Default("[CUSTOMIZE: reason for block]")

    # ── Decision Block: [CUSTOMIZE: Decision description] ─────────────────────
    confidence = calculate_confidence(request)

    if confidence >= CONFIDENCE_THRESHOLDS["HIGH"]:
        # [CUSTOMIZE: What happens at high confidence]
        return Resource("[CUSTOMIZE: resource_key]")

    elif confidence >= CONFIDENCE_THRESHOLDS["MEDIUM"]:
        # [CUSTOMIZE: What happens at medium confidence]
        return Execute("[CUSTOMIZE: action]", confirm=True)

    elif confidence >= CONFIDENCE_THRESHOLDS["LOW"]:
        # [CUSTOMIZE: What happens at low confidence]
        return chain_fallback("[CUSTOMIZE: domain]")

    else:
        # Fallback to interactive mode
        return Default("interactive_mode")
```

### 2.3 [CUSTOMIZE: Secondary Handler Name]

```python
def [CUSTOMIZE: handler_name](input_data, state):
    """
    Purpose: [CUSTOMIZE: Handler purpose]
    Returns: Resource() | Execute() | Default()
    """

    # ── Mode Detection ────────────────────────────────────────────────────────
    mode = detect_mode(state)

    if mode == "[CUSTOMIZE: mode1]":
        return Resource("[CUSTOMIZE: resource_for_mode1]")

    elif mode == "[CUSTOMIZE: mode2]":
        return Execute("[CUSTOMIZE: action_for_mode2]")

    # ── Topic Matching ────────────────────────────────────────────────────────
    topic = match_topic(input_data, TOPIC_REGISTRY)

    if topic:
        return Resource(TOPIC_REGISTRY[topic]["document"])

    return Default("fallback")
```

---

─────────────────────────────────────────────────────────────────────────────────
## SECTION 3: SEMANTIC TOPIC REGISTRY
─────────────────────────────────────────────────────────────────────────────────

<!--
INSTRUCTIONS:
- Map keywords/phrases to documents with synonyms
- Used by Section 2 handlers for topic matching
- Include primary keyword and list of synonyms
- Reference document keys from Section 4
-->

```python
TOPIC_REGISTRY = {
    # ── [CUSTOMIZE: Topic Category 1] ─────────────────────────────────────────
    "[CUSTOMIZE: topic1]": {
        "keywords": ["[CUSTOMIZE: keyword1]", "[CUSTOMIZE: keyword2]"],
        "synonyms": ["[CUSTOMIZE: synonym1]", "[CUSTOMIZE: synonym2]"],
        "document": "[CUSTOMIZE: resource_key]",
        "confidence_boost": 0.1  # Optional: boost for exact matches
    },

    # ── [CUSTOMIZE: Topic Category 2] ─────────────────────────────────────────
    "[CUSTOMIZE: topic2]": {
        "keywords": ["[CUSTOMIZE: keyword1]", "[CUSTOMIZE: keyword2]"],
        "synonyms": ["[CUSTOMIZE: synonym1]", "[CUSTOMIZE: synonym2]"],
        "document": "[CUSTOMIZE: resource_key]",
        "confidence_boost": 0.0
    },

    # ── [CUSTOMIZE: Topic Category 3] ─────────────────────────────────────────
    "[CUSTOMIZE: topic3]": {
        "keywords": ["[CUSTOMIZE: keyword1]"],
        "synonyms": [],
        "document": "[CUSTOMIZE: resource_key]",
        "confidence_boost": 0.15
    }
}
```

---

─────────────────────────────────────────────────────────────────────────────────
## SECTION 4: STATIC RESOURCES
─────────────────────────────────────────────────────────────────────────────────

<!--
INSTRUCTIONS:
- List ALL static resource mappings as markdown tables
- No conditional logic allowed in this section
- Keys are referenced by Sections 1, 2, and 3
- Types: template | guide | reference | config
- Paths should be relative to project root
-->

### 4.1 [CUSTOMIZE: Resource Category 1]

| Key | Path | Type | Description |
|-----|------|------|-------------|
| `[CUSTOMIZE: key1]` | `[CUSTOMIZE: path/to/file.md]` | template | [CUSTOMIZE: Purpose] |
| `[CUSTOMIZE: key2]` | `[CUSTOMIZE: path/to/file.md]` | guide | [CUSTOMIZE: Purpose] |
| `[CUSTOMIZE: key3]` | `[CUSTOMIZE: path/to/file.md]` | reference | [CUSTOMIZE: Purpose] |

### 4.2 [CUSTOMIZE: Resource Category 2]

| Key | Path | Type | Description |
|-----|------|------|-------------|
| `[CUSTOMIZE: key4]` | `[CUSTOMIZE: path/to/file.md]` | template | [CUSTOMIZE: Purpose] |
| `[CUSTOMIZE: key5]` | `[CUSTOMIZE: path/to/file.md]` | config | [CUSTOMIZE: Purpose] |

### 4.3 Document Loading Tiers

<!--
INSTRUCTIONS:
- Categorize ALL resources into one of three tiers
- ALWAYS: Loaded on every request
- TRIGGER: Loaded on specific conditions/keywords
- ON-DEMAND: Loaded only on explicit command
-->

| Tier | Resources | Loading Condition |
|------|-----------|-------------------|
| **ALWAYS** | `[CUSTOMIZE: key1]`, `[CUSTOMIZE: key2]` | Every request |
| **TRIGGER** | `[CUSTOMIZE: key3]` | [CUSTOMIZE: trigger condition] |
| **ON-DEMAND** | `[CUSTOMIZE: key4]`, `[CUSTOMIZE: key5]` | `/[CUSTOMIZE: command]` |

---

─────────────────────────────────────────────────────────────────────────────────
## SECTION 5: FALLBACK CHAINS
─────────────────────────────────────────────────────────────────────────────────

<!--
INSTRUCTIONS:
- Define priority-ordered alternatives for each routing domain
- Each chain should have 2-4 levels
- Final fallback MUST always be interactive_mode or a safe default
- Used by Section 2 when confidence < LOW threshold
-->

```python
FALLBACK_CHAINS = {
    # ── [CUSTOMIZE: Domain 1] ─────────────────────────────────────────────────
    "[CUSTOMIZE: domain1]": [
        "[CUSTOMIZE: primary_fallback]",      # Priority 1: [CUSTOMIZE: When to use]
        "[CUSTOMIZE: secondary_fallback]",    # Priority 2: [CUSTOMIZE: When to use]
        "interactive_mode"                    # Priority 3: Final fallback
    ],

    # ── [CUSTOMIZE: Domain 2] ─────────────────────────────────────────────────
    "[CUSTOMIZE: domain2]": [
        "[CUSTOMIZE: primary_fallback]",      # Priority 1: [CUSTOMIZE: When to use]
        "[CUSTOMIZE: secondary_fallback]",    # Priority 2: [CUSTOMIZE: When to use]
        "[CUSTOMIZE: tertiary_fallback]",     # Priority 3: [CUSTOMIZE: When to use]
        "default_handler"                     # Priority 4: Final fallback
    ],

    # ── General/Uncategorized ─────────────────────────────────────────────────
    "general": [
        "topic_match",                        # Try semantic matching first
        "recent_context",                     # Check conversation context
        "interactive_mode"                    # Ask user for clarification
    ]
}

def chain_fallback(domain):
    """
    Purpose: Execute fallback chain for given domain
    Returns: First successful handler result or Default()
    """
    chain = FALLBACK_CHAINS.get(domain, FALLBACK_CHAINS["general"])

    for fallback in chain:
        result = try_handler(fallback)
        if result.success:
            return result

    return Default("interactive_mode")
```

---

─────────────────────────────────────────────────────────────────────────────────
## SECTION 6: CROSS-REFERENCES
─────────────────────────────────────────────────────────────────────────────────

<!--
INSTRUCTIONS:
- Document which commands invoke each handler
- Document which resources each handler may load
- Use markdown tree format for visual clarity
- Update this section whenever handlers change
-->

### 6.1 Handler Dependencies

```
[CUSTOMIZE: handler_name]
    │
    ├─► Invoked By:
    │   ├─► /[CUSTOMIZE: command1] [pattern]
    │   └─► /[CUSTOMIZE: command2] [pattern]
    │
    └─► May Load:
        ├─► [CUSTOMIZE: resource_key1]
        ├─► [CUSTOMIZE: resource_key2]
        └─► [CUSTOMIZE: resource_key3]
```

```
[CUSTOMIZE: handler_name2]
    │
    ├─► Invoked By:
    │   └─► /[CUSTOMIZE: command] DEFAULT
    │
    └─► May Load:
        ├─► [CUSTOMIZE: resource_key]
        └─► interactive_mode (fallback)
```

### 6.2 Resource Usage Map

```
[CUSTOMIZE: resource_key1]
    │
    └─► Referenced By:
        ├─► SECTION 1: /[CUSTOMIZE: command] → STATIC
        ├─► SECTION 2: [CUSTOMIZE: handler_name]
        └─► SECTION 3: TOPIC_REGISTRY["[CUSTOMIZE: topic]"]
```

### 6.3 Command → Handler → Resource Flow

<!-- Visual summary of the complete routing flow -->

```
USER INPUT
    │
    ▼
┌─────────────────────────────────────────────────────────────────┐
│ SECTION 1: Command Entry Points                                 │
│   /command [args] → Pattern Match                               │
└─────────────────────────────────────────────────────────────────┘
    │
    ├─► STATIC: resource_key ──────────────────┐
    │                                          │
    └─► HANDLER: handler_name                  │
            │                                  │
            ▼                                  │
┌─────────────────────────────────────────┐    │
│ SECTION 2: Smart Routing Logic          │    │
│   Confidence scoring + conditions       │    │
└─────────────────────────────────────────┘    │
            │                                  │
            ├─► SECTION 3: Topic Match         │
            │                                  │
            ├─► SECTION 5: Fallback Chain      │
            │                                  │
            ▼                                  ▼
┌─────────────────────────────────────────────────────────────────┐
│ SECTION 4: Static Resources                                     │
│   Key → Path lookup                                             │
└─────────────────────────────────────────────────────────────────┘
            │
            ▼
        RESPONSE
```

---

<!--
─────────────────────────────────────────────────────────────────────────────────
TEMPLATE CHECKLIST - Verify before use
─────────────────────────────────────────────────────────────────────────────────

[ ] All [CUSTOMIZE] markers replaced with specific content
[ ] All 6 sections present in correct order
[ ] Section headers use ═ separator style
[ ] Python uses CONFIDENCE_THRESHOLDS constant (not inline values)
[ ] All commands have DEFAULT fallback case
[ ] All handlers have docstrings with Purpose and Returns
[ ] All static resources in markdown table format
[ ] Fallback chains end with interactive_mode or safe default
[ ] Cross-references updated for all handlers
[ ] Document loading tiers assigned for all resources

Reference: specs/001-hybrid-routing-architecture/spec.md
-->
