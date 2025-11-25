# Prompt Engineering Assistant v0.921

Transforms vague requests into clear, effective AI prompts using proven frameworks, systematic evaluation, and **concise transparent DEPTH processing**.

## 📋 TABLE OF CONTENTS

1. [🆕 WHAT'S NEW IN V0.921](#1-whats-new-in-v0921)
2. [✨ KEY FEATURES](#2-key-features)
3. [🌳 SYSTEM ARCHITECTURE](#3-system-architecture)
4. [🚀 QUICK SETUP](#4-quick-setup)
5. [🎛️ OPERATING MODES](#5-operating-modes)
6. [📋 MODE DETAILS](#6-mode-details)
7. [💬 INTERACTIVE MODE](#7-interactive-mode)
8. [🧠 DEPTH THINKING FRAMEWORK](#8-depth-thinking-framework)
9. [🏗️ RICCE FRAMEWORK](#9-ricce-framework)
10. [🎯 FRAMEWORK INTELLIGENCE](#10-framework-intelligence)
11. [📊 ENHANCEMENT SYSTEM](#11-enhancement-system)
12. [📈 CLEAR EVALUATION](#12-clear-evaluation)

---

<a id="1-whats-new-in-v0921"></a>
## 1. 🆕 WHAT'S NEW IN V0.921

### 🎯 Major Update: Format Guides Refactored (v0.120)

**All Three Format Guides Completely Restructured:**

The JSON, YAML, and Markdown format guides underwent comprehensive refactoring to eliminate redundancy and focus purely on format specifications:

**Core Improvements Across All Guides:**
- **Pure Format Focus** - Removed all processing logic, quality evaluation, and workflow details
- **Single Source of Truth** - Delegated cognitive processing to DEPTH v0.106, evaluation to Patterns v0.102
- **Streamlined Structure** - Reduced from 13 sections to 11 focused sections

**What Was Removed:**
- ❌ Transparency Reporting section (now in DEPTH v0.106)
- ❌ Performance Metrics section (now in Patterns v0.102)
- ❌ Troubleshooting section (merged into validation)
- ❌ Python pseudo code (replaced with YAML)
- ❌ CLEAR scores in file headers (reported separately in chat)
- ❌ Duplicate processing logic from DEPTH/Interactive Mode

**What Was Enhanced:**
- ✨ File delivery methods clearly documented (Desktop vs CLI/Agent)
- ✨ Syntax validation with YAML-based validation rules
- ✨ Format-specific best practices with Do's/Don'ts categories
- ✨ Token efficiency sections with practical optimization tips
- ✨ Format quality checklists for each output type

**Benefits:**
- 📉 Reduced maintenance burden (no duplicate logic)
- 📈 Improved clarity (pure format specifications)
- 🎯 Better separation of concerns (format vs processing)
- 🔄 Easier updates (change logic once, not in 4 files)
- 📚 Cleaner documentation (focused and concise)

### 📊 Evolution: v0.921 → v0.920 → v0.910 → v0.900

**v0.921:** Format guides refactored (v0.120) - pure format focus, YAML pseudo code, file delivery standards  
**v0.920:** New Thinking Framework (RICCE integration, cognitive rigor), and Interactive Mode (two-layer transparency)
**v0.910:** Architecture standardization with YAML processing structure  
**v0.900:** Foundation with framework intelligence and comprehensive patterns

---

<a id="2-key-features"></a>
## 2. ✨ KEY FEATURES

- **🎯 Seven Frameworks**: RCAF, COSTAR, RACE, CIDI, TIDD-EC, CRISPE, CRAFT with intelligent auto-selection
- **🧠 DEPTH Framework**: 10-round methodology with two-layer transparency and RICCE integration
- **🔒 Mandatory Perspectives**: Minimum 3 perspectives (BLOCKING requirement), target 5
- **🔬 Enhanced Cognitive Rigor**: 6 techniques (multi-perspective, assumption audit, perspective inversion, constraint reversal, mechanism-first, RICCE compliance)
- **📊 Two-Layer Model**: Full rigor internally, concise updates externally
- **🏗️ RICCE Framework**: Role, Instructions, Context, Constraints, Examples validation integrated throughout
- **🚀 Seven Operating Modes**: Interactive (default), Quick, Short, Improve, Refine, JSON, YAML
- **⚡ Quick Mode**: Auto-scaled 1-5 rounds based on complexity
- **💬 Single Question**: All info gathered at once (except $quick)
- **📈 CLEAR Scoring**: 50-point context-aware evaluation (target 40+)
- **📄 Three Output Formats**: Standard/Markdown, JSON, YAML with format-specific optimization
- **🛠️ REPAIR+ Protocol**: Advanced error detection and recovery
- **✅ Quality Gates**: Multi-phase validation ensuring consistent excellence

---

<a id="3-system-architecture"></a>
## 3. 🌳 SYSTEM ARCHITECTURE

```
AGENTS.md → Entry point with intelligent routing logic
    ↓
Writer - Prompt Improver - v0.921.md (System prompt - 38 core rules)
    ↓
DEPTH Framework v0.106 (Methodology with RICCE & transparency)
    ↓
Interactive Mode v0.642 (Conversation flow with two-layer model)
    ↓
Patterns & Evaluation v0.102 (7 frameworks + CLEAR scoring)
    ↓
Format Guides v0.120 (Markdown, JSON, YAML - pure format specs)
    ↓
Output → /export/[###]-enhanced-prompt.[md|json|yaml]
```

---

<a id="4-quick-setup"></a>
## 4. 🚀 QUICK SETUP

### Step 1: Create Claude Project
1. Go to claude.ai → Projects → Create "Prompt Engineering Assistant"

### Step 2: Add System Instructions
1. Edit project details → Custom instructions
2. Copy and paste: `Writer - Prompt Improver - v0.921.md`
3. Save the project

### Step 3: Upload Supporting Documents

Add these documents to your project:

**Core Framework:**
- `Prompt - DEPTH Thinking Framework - v0.106.md` (two-layer transparency, mandatory perspectives, RICCE integration)
- `Prompt - Interactive Mode - v0.642.md` (conversation flow, state management, smart routing)
- `Prompt - Patterns, Enhancements & Evaluation - v0.102.md` (complete framework library, CLEAR scoring)

**Format Specifications:**
Each format guide (v0.120) is fully self-contained with pure format focus:

- **`Prompt - Format Guide - Markdown - v0.120.md`**
  - Natural language prompt structure (DEFAULT FORMAT)
  - RCAF/CRAFT framework integration
  - Baseline token usage, optimal human readability
  - File delivery standards (Desktop vs CLI/Agent modes)
  - YAML-based syntax validation
  
- **`Prompt - Format Guide - JSON - v0.120.md`**
  - Structured data for API/system integration
  - Schema validation and type safety
  - Token overhead: +5-10%
  - File delivery with validation rules
  - YAML pseudo code for conversions
  
- **`Prompt - Format Guide - YAML - v0.120.md`**
  - Human-friendly configuration format
  - Minimal syntax overhead, clear hierarchy
  - Token overhead: +3-7%
  - Configuration-ready format specifications
  - YAML-native validation examples

**Key Advantages of v0.120 Refactor:**
- Pure format specifications (no processing logic duplication)
- Clear file delivery standards aligned with system prompt
- YAML pseudo code throughout for consistency
- Streamlined 11-section structure
- Token efficiency guidance
- Format quality checklists
- Complete framework library (7 frameworks with 87-94% success rates)
- Automatic complexity detection and scaling
- Context-aware CLEAR evaluation with dimension weighting
- Comprehensive pattern library (20+ enhancement patterns)
- Consistent DEPTH v0.106 integration across all operations

### Step 4: Start Enhancing
```
analyze customer data            # Interactive mode with full transparency
$quick fix grammar              # Fast 1-5 round enhancement
$improve generate report        # Standard 10-round DEPTH processing
$json api endpoint              # JSON format with structure optimization
$yaml config template           # YAML format with hierarchy optimization
```

---

<a id="5-operating-modes"></a>
## 5. 🎛️ OPERATING MODES

**Default Mode:** The system defaults to `$interactive` with automatic 10-round DEPTH unless specified.

| Mode | Command | Purpose | Questions | DEPTH Processing | Transparency | Output |
|------|---------|---------|-----------|------------------|--------------|--------|
| **Interactive** | (default) | Guided enhancement | 1 comprehensive | 10 rounds (concise updates) | Two-layer | User choice |
| **$quick** | `$quick` / `$q` | Fast processing | NONE | 1-5 auto-scaled | Summary | Auto-format |
| **$short** | `$short` / `$s` | Minimal refinement | 1 comprehensive | 3 rounds | Key changes | Auto-format |
| **$improve** | `$improve` / `$i` | Standard enhancement | 1 comprehensive | 10 rounds (concise updates) | Two-layer | Auto-format |
| **$refine** | `$refine` / `$r` | Maximum optimization | 1 comprehensive | 10 rounds (concise updates) | Deep analysis | Auto-format |
| **$json** | `$json` / `$j` | API format | 1 comprehensive | 10 rounds (concise updates) | Structure focus | JSON only |
| **$yaml** | `$yaml` / `$y` | Config format | 1 comprehensive | 10 rounds (concise updates) | Template focus | YAML only |

### Interactive Flow (Default)
System asks one comprehensive question to understand your enhancement needs:
- What prompt needs enhancement?
- What's the use case/goal?
- Any specific requirements?

System waits for complete response before proceeding with full DEPTH processing.

**Note:** The system emphasizes concise transparency with two-layer processing and BLOCKING enforcement of minimum 3 perspectives (target 5).

---

<a id="6-mode-details"></a>
## 6. 📋 MODE DETAILS

### 💬 Interactive Mode (Default)

**Purpose:** Conversational enhancement with guided framework selection

**Process:**
1. System asks comprehensive question
2. Waits for user response
3. Analyzes request (complexity, frameworks, format)
4. Presents options if needed
5. Applies DEPTH with concise updates
6. Delivers enhanced prompt

**Key Features:**
- ONE question gathering ALL needed info
- Framework intelligence with confidence scores
- Format selection (Markdown/JSON/YAML)
- Full 10-round DEPTH processing
- Complete transparency report after delivery

**Full details:** `Prompt - Interactive Mode - v0.642.md`

---

### ⚡ $quick Mode

**Purpose:** Rapid enhancement with auto-scaled DEPTH (1-5 rounds)

**Complexity Scaling:**
| Complexity | DEPTH Rounds | Use Case |
|------------|--------------|----------|
| **1-2** | 1-2 rounds | Simple edits, typo fixes |
| **3-4** | 3 rounds | Basic refinement |
| **5-6** | 4 rounds | Standard enhancement |
| **7+** | 5 rounds | Complex restructuring |

**Process:**
- No questions asked (immediate processing)
- Automatic complexity detection
- Auto-scaled DEPTH application
- Brief summary delivery
- Framework auto-selected

**Example:** `$quick enhance my chatbot prompt`

---

### 📝 $short Mode

**Purpose:** Minimal refinement with focused 3-round DEPTH

**Process:**
- Asks ONE comprehensive question
- Applies focused 3-round DEPTH
- Key changes highlighted
- Quick turnaround

**Use Case:** When you need light polish without full analysis

**Example:** `$short improve clarity of this prompt`

---

### 🎯 $improve Mode

**Purpose:** Standard comprehensive enhancement with full DEPTH

**Process:**
- Asks ONE comprehensive question
- Full 10-round DEPTH processing
- Two-layer transparency (concise updates)
- Complete enhancement report
- Framework intelligence applied

**Use Case:** Default enhancement mode for most prompts

**Example:** `$improve help me write a data analysis prompt`

---

### 💎 $refine Mode

**Purpose:** Maximum optimization for already-good prompts

**Process:**
- Asks ONE comprehensive question
- Full 10-round DEPTH with deep analysis
- Detailed optimization report
- Multiple improvement iterations considered
- Excellence-level targeting (CLEAR 45+)

**Use Case:** Taking good prompts to excellence

**Example:** `$refine optimize this high-performing prompt further`

---

### 🔧 $json Mode

**Purpose:** Structured JSON output for API/system integration

**Key Features:**
- Valid JSON syntax only (no markdown)
- Schema-based structure
- Field consistency and type safety
- API-ready format
- Token overhead: +5-10%

**Best For:**
- API integrations
- System-to-system communication
- Programmatic parsing
- Data pipelines

**Average CLEAR:** 41/50 (lower expression, higher correctness weighting)

**Full details:** `Prompt - Format Guide - JSON - v0.111.md`

---

### 📋 $yaml Mode

**Purpose:** Human-friendly YAML configuration format

**Key Features:**
- Minimal syntax (no brackets/quotes)
- Clear indentation-based hierarchy
- Comment support for documentation
- Multi-line string handling
- Token overhead: +3-7%

**Best For:**
- Configuration templates
- Documentation with structure
- Human-readable data
- Multi-level hierarchies

**Average CLEAR:** 42/50 (balanced readability and structure)

**Full details:** `Prompt - Format Guide - YAML - v0.111.md`

---

<a id="7-interactive-mode"></a>
## 7. 💬 INTERACTIVE MODE

### Conversational Guidance Flow

**Default behavior** when no mode specified ($quick, $improve, $json, etc.)

**Process:**
```
User Request
     ↓
Single Comprehensive Question
(What needs enhancement? Use case? Requirements?)
     ↓
Wait for Complete User Response
     ↓
Apply DEPTH v0.106 (10 rounds with concise updates)
     ↓
Deliver Enhanced Prompt + Transparency Report
```

**Key Features:**
- ONE question gathering ALL needed info
- Never answers own questions
- Always waits for user response
- Applies full DEPTH with two-layer transparency
- Framework intelligence with selection reasoning
- Format choice presented (Markdown/JSON/YAML)
- Complete transparency report after delivery

**What Users See:**
```markdown
I'll enhance your prompt using comprehensive DEPTH processing.

To create the best enhancement, please provide:
1. **Current prompt or description:** What needs enhancement?
2. **Use case/goal:** What will this prompt accomplish?
3. **Any specific requirements:** Format, framework, constraints?

[System waits for response]

[After response, DEPTH processing begins with concise updates]

🔍 **Analyzing from 5 perspectives:** Prompt Engineering, AI Interpretation, 
    User Clarity, Framework Selection, Token Efficiency
**Key Insight:** Technical documentation needs precision framework

⚙️ **Engineering solution** (7 frameworks evaluated)
**Selected:** TIDD-EC (93% success rate, precision-critical tasks)

🔨 **Building** (TIDD-EC structure, RICCE-compliant)
**Structure:** Task, Instructions, Do's, Don'ts, Examples, Context

✅ **Quality validation complete**
**CLEAR Score:** 44/50 (Correctness: 9, Logic: 9, Expression: 13, 
                        Arrangement: 9, Reuse: 4)

✨ **Finalizing** (Excellence confirmed, RICCE verified)
Ready for delivery

[Enhanced prompt delivered + full transparency report]
```

**Full details:** `Prompt - Interactive Mode - v0.642.md`

---

<a id="8-depth-thinking-framework"></a>
## 8. 🧠 DEPTH THINKING FRAMEWORK

### Two-Layer Transparency Model

**DEPTH** = **D**iscover **E**ngineer **P**rototype **T**est **H**armonize

A structured 5-phase methodology ensuring comprehensive prompt enhancement through **concise transparent excellence** - full rigor applied internally, meaningful updates shown to users.

**Processing Depth:**
| Mode | Rounds | User Visibility | Application |
|------|--------|-----------------|-------------|
| **Standard** | 10 rounds | Concise progress updates | Real-time transparency |
| **$quick** | 1-5 auto-scaled | Summary at completion | Complexity-based |
| **$short** | 3 rounds | Key changes only | Focused refinement |

### DEPTH Phases (v0.106 with RICCE Integration)

| Phase | Purpose | Internal Processing | User Sees |
|-------|---------|---------------------|-----------|
| **D**iscover | Deep understanding | 5 perspectives, assumption audit, complexity analysis, RICCE Role & Context | "🔍 Analyzing (5 perspectives)" |
| **E**ngineer | Solution generation | 7 frameworks evaluated, constraint analysis, RICCE Constraints & Instructions | "⚙️ Engineering (optimal framework selected)" |
| **P**rototype | Build framework | Template application, RICCE validation, mechanism-first structure | "🔨 Building (RCAF/framework structure)" |
| **T**est | Validate quality | CLEAR scoring (5 dimensions), quality gates, RICCE Examples validation | "✅ Validating (CLEAR 42/50)" |
| **H**armonize | Final polish | Final verification, cognitive rigor check, RICCE completeness | "✨ Finalizing (excellence confirmed)" |

### What Users Actually See

**Example DEPTH Progress Updates:**
```markdown
🔍 **Analyzing from 5 perspectives:** Prompt Engineering, AI Interpretation,
    User Clarity, Framework Specialist, Token Efficiency
**Key Insight:** Content creation task benefits from audience-focused approach

⚙️ **Engineering solution** (7 frameworks evaluated)
**Selected:** COSTAR (94% success rate, content creation champion)
**Alternative:** RCAF (92% - considered for simpler approach)

🔨 **Building** (COSTAR structure, RICCE-compliant)
**Structure:** Context, Objective, Style, Tone, Audience, Response format

✅ **Quality validation complete**
**CLEAR Score:** 43/50 breakdown:
- Correctness: 9/10 (accurate requirements, valid assumptions)
- Logic: 8/10 (clear reasoning flow, edge cases covered)
- Expression: 13/15 (high clarity, minimal ambiguity)
- Arrangement: 9/10 (excellent structure, logical sections)
- Reuse: 4/5 (adaptable with minor adjustments)

✨ **Finalizing** (Excellence confirmed, RICCE verified)
**Assumptions flagged:** [Assumes: Target audience has technical background]
Ready for delivery
```

### Cognitive Rigor (Applied Automatically)

Six mandatory frameworks applied internally (users see key insights only):

1. **Multi-Perspective Analysis** - BLOCKING requirement (min 3, target 5) with enforcement at validation gates
2. **Assumption Audit** - Critical flags shown with explicit `[Assumes: X]` notation
3. **Perspective Inversion** - Key opposition insights integrated into rationale
4. **Constraint Reversal** - Non-obvious solutions surfaced through backward analysis
5. **Mechanism First** - WHY before WHAT validation ensuring principle-driven design
6. **RICCE Compliance** - Structural completeness across all five dimensions

**Quality Targets:** All dimensions 8+ (Completeness, Clarity, Actionability, Accuracy, Relevance, Mechanism Depth)

**Validation Gates:** Multi-phase enforcement (pre-enhancement, during enhancement, post-enhancement) ensures consistent excellence

**Full details:** `Prompt - DEPTH Thinking Framework - v0.106.md`

---

<a id="9-ricce-framework"></a>
## 9. 🏗️ RICCE FRAMEWORK

### Structural Validation Checklist

**RICCE** ensures every enhanced prompt contains essential elements for complete understanding:

**R**ole - Perspectives Defined
- ✅ Minimum 3 perspectives analyzed (target 5)
- ✅ Target AI role/expertise defined
- ✅ User context understood

**I**nstructions - Tasks Broken Down
- ✅ Clear action items specified
- ✅ Execution sequence logical
- ✅ Success criteria defined

**C**ontext - Layers Comprehensive
- ✅ Domain background provided
- ✅ Constraints specified
- ✅ Dependencies identified

**C**onstraints - Boundaries Established
- ✅ Scope boundaries clear
- ✅ Format requirements defined
- ✅ Quality thresholds set

**E**xamples - Validation Included
- ✅ Use cases provided
- ✅ Expected outputs shown
- ✅ Edge cases considered

### RICCE-DEPTH Integration

**How They Work Together:**
- **DEPTH** = The **HOW** (process methodology)
- **RICCE** = The **WHAT** (structural checklist)
- **Together** = Rigorous process + Complete structure = Superior prompts

**Integration Points:**
- Discover Phase → Populates RICCE Role & Context
- Engineer Phase → Validates RICCE Constraints & Instructions
- Prototype Phase → Applies full RICCE structure
- Test Phase → Validates RICCE Examples
- Harmonize Phase → Final RICCE verification

### What Users See for RICCE

**Example RICCE Communication:**
```markdown
✅ **RICCE validation complete:**
- Role: 5 perspectives analyzed (Prompt Eng., AI Interpretation, User Clarity,
        Framework Selection, Token Efficiency)
- Instructions: Clear action items with execution sequence defined
- Context: Domain background, constraints, and dependencies specified
- Constraints: Scope boundaries set, format requirements defined
- Examples: Use cases with expected outputs and edge cases

**Assumption Flagged:** [Assumes: API supports async requests]
```

**Full details:** `Prompt - DEPTH Thinking Framework - v0.106.md` (Sections 5-6)

---

<a id="10-framework-intelligence"></a>
## 10. 🎯 FRAMEWORK INTELLIGENCE

### Automatic Framework Selection

The system analyzes your request across 8 dimensions using structured logic:

```yaml
framework_selection:
  analyze_characteristics:
    - complexity: [1-10 scale]
    - urgency: [boolean]
    - audience_specific: [boolean]
    - creative_element: [boolean]
    - precision_critical: [boolean]
    - compliance_needs: [boolean]
    - multi_stakeholder: [boolean]
  
  select_best:
    method: highest_score
    output:
      primary: [selected_framework]
      confidence: [normalized_score]
      alternative: [second_best]
      reasoning: [explanation]
```

### Framework Selection Matrix

| Complexity | Primary Need | Framework | Success Rate | Use Cases |
|------------|--------------|-----------|--------------|-----------|
| **1-3** | Speed | RACE | 88% | Urgent tasks, quick iterations |
| **1-4** | Clarity | RCAF | 92% | General prompts, balanced needs |
| **3-6** | Audience | COSTAR | 94% | Content creation, communication |
| **4-6** | Instructions | CIDI | 90% | Documentation, tutorials |
| **5-7** | Creativity | CRISPE | 87% | Strategy, exploration |
| **6-8** | Precision | TIDD-EC | 93% | Compliance, quality-critical |
| **7-10** | Comprehensive | CRAFT | 91% | Complex projects, planning |

### Framework Descriptions

**RCAF (Role, Context, Action, Format)** - 92% Success
- **Best for:** 80% of prompts, general-purpose tasks
- **Strengths:** Balanced, clear structure, high adaptability
- **Use when:** Unsure which framework to use

**COSTAR (Context, Objective, Style, Tone, Audience, Response)** - 94% Success
- **Best for:** Content creation, communication tasks
- **Strengths:** Audience focus, style control, highest success rate
- **Use when:** Output needs specific tone or audience targeting

**RACE (Role, Action, Context, Execute)** - 88% Success
- **Best for:** Urgent tasks requiring quick iterations
- **Strengths:** Speed, simplicity, action-oriented
- **Use when:** Time-sensitive or simple requests

**CIDI (Context, Instructions, Details, Input)** - 90% Success
- **Best for:** Process documentation, tutorials, step-by-step guides
- **Strengths:** Instruction clarity, detail orientation
- **Use when:** Creating instructional content

**TIDD-EC (Task, Instructions, Do's, Don'ts, Examples, Context)** - 93% Success
- **Best for:** Quality-critical tasks, compliance requirements
- **Strengths:** Precision, explicit constraints, second-highest success
- **Use when:** Accuracy and compliance are paramount

**CRISPE (Capacity, Role, Insight, Statement, Personality, Experiment)** - 87% Success
- **Best for:** Strategic planning, creative exploration
- **Strengths:** Adaptability, experimental approach
- **Use when:** Exploring new directions or strategies

**CRAFT (Context, Role, Action, Format, Target)** - 91% Success
- **Best for:** Complex multi-faceted projects
- **Strengths:** Comprehensive coverage, planning depth
- **Use when:** High complexity (7+) with multiple stakeholders

### Power Combinations

**For Complex Scenarios:**
- **RCAF + CoT (Chain of Thought)**: Systematic thinking structure
- **COSTAR + ReAct (Reasoning + Acting)**: Iterative content refinement
- **TIDD-EC + Few-Shot**: Learning from examples with precision
- **RACE + ToT (Tree of Thoughts)**: Rapid decision trees
- **Master-Detail Pattern**: Nested framework hierarchies

**Full details:** `Prompt - Patterns, Enhancements & Evaluation - v0.102.md` (Sections 1-4)

---

<a id="11-enhancement-system"></a>
## 11. 📊 ENHANCEMENT SYSTEM

### Systematic Enhancement Pipeline

```yaml
enhancement_pipeline:
  stages:
    - structural_enhancement:
        actions: [apply_framework, reorganize_sections]
    - clarity_enhancement:
        actions: [simplify_language, disambiguate_terms]
    - precision_enhancement:
        actions: [add_metrics, specify_constraints, define_scope]
    - efficiency_enhancement:
        actions: [remove_redundancy, compress_verbose, optimize_tokens]
    - reusability_enhancement:
        actions: [parameterize_variables, add_flexibility, generalize_patterns]
```

### Common Pattern Transformations

| Pattern | Impact | CLEAR Gain | Example |
|---------|--------|------------|---------|
| **Vague→Specific** | Add role, context, metrics | +15-20 points | "Analyze text" → "Analyze sentiment in customer reviews with 1-5 scale" |
| **Assumption Elimination** | Make implicit explicit | +3-5 Correctness | Add: "[Assumes: data in CSV format with header row]" |
| **Scope Boundaries** | Define included/excluded | +4-6 Logic | "Analyze reviews (exclude ratings <3 stars)" |
| **Example Injection** | Clarify format expectations | +3-5 Expression | Add 2-3 input/output examples |
| **Success Layering** | Min/target/excellence levels | +4-5 Arrangement | Define minimum viable, target, and excellence criteria |

### Enhancement Priority Matrix

```yaml
by_score:
  "< 25": "Complete rewrite with RCAF baseline"
  "25-30": "Framework switch evaluation (try COSTAR or TIDD-EC)"
  "30-35": "Fix 2 weakest CLEAR dimensions"
  "35-40": "Polish weakest dimension"
  "40-45": "Optional refinements for excellence"
  "45+": "Excellence achieved - ship it!"
```

### Excellence Patterns (45+ CLEAR)
- Complete context layering (environmental, historical, constraints, resources)
- Multi-level success criteria (minimum, target, excellence)
- Adaptive response formats (quick review vs comprehensive)
- Self-documenting structure (what, why, how, example)

**Full details:** `Prompt - Patterns, Enhancements & Evaluation - v0.102.md` (Sections 5-7)

---

<a id="12-clear-evaluation"></a>
## 12. 📈 CLEAR EVALUATION

### Context-Aware Scoring System

```yaml
contextual_clear_scoring:
  base_weights:
    correctness: 0.20
    logic: 0.20
    expression: 0.30
    arrangement: 0.20
    reuse: 0.10
  
  context_adjustments:
    api_integration:
      correctness: 0.30  # Higher accuracy requirement
      expression: 0.20   # Lower language priority
    creative_writing:
      expression: 0.35   # Higher clarity priority
      correctness: 0.15  # Lower accuracy requirement
    template_creation:
      reuse: 0.25        # Higher adaptability priority
      logic: 0.15        # Lower reasoning priority
```

### CLEAR Dimensions (50-point scale)

| Dimension | Points | Assessment Criteria |
|-----------|--------|---------------------|
| **Correctness** | 10 | Accuracy, no contradictions, valid assumptions |
| **Logic** | 10 | Reasoning flow, cause-effect, conditional handling |
| **Expression** | 15 | Clarity, specificity, minimal ambiguity |
| **Arrangement** | 10 | Structure, organization, logical flow |
| **Reusability** | 5 | Adaptability, parameterization, flexibility |

### Score Interpretation

| Score | Grade | Quality Level | Action |
|-------|-------|--------------|--------|
| **45-50** | A+ | Excellence | Ship immediately |
| **40-44** | A | Professional | Ready to use |
| **35-39** | B | Good | Minor refinements optional |
| **30-34** | C | Adequate | Consider improvements |
| **<30** | D/F | Needs work | Significant enhancement required |

### Multi-Pass Evaluation
1. **Surface Pass**: Framework presence, basic completeness
2. **Deep Pass**: Ambiguity detection, assumption analysis
3. **Interaction Pass**: AI interpretation testing, failure mode analysis

**Full details:** `Prompt - Patterns, Enhancements & Evaluation - v0.102.md` (Sections 9-11)