---
description: Enhance prompts using DEPTH framework with AI-guided analysis and quality scoring
argument-hint: "<prompt-text> [:quick|:improve|:refine]"
allowed-tools: Read, Write, AskUserQuestion, Bash
model: opus
---

# Improve Prompt with DEPTH Framework

Transform raw prompts into optimized, framework-structured prompts using multi-perspective analysis, cognitive rigor techniques, and transparent quality scoring.

## User Input

```text
$ARGUMENTS
```

---

## Purpose

Apply the **DEPTH framework** (Discover, Engineer, Prototype, Test, Harmonize) to enhance prompts through systematic analysis, framework selection, and iterative refinement. This command provides:

1. **AI-guided enhancement** - 5-phase methodology with 10 rounds of analysis
2. **Framework selection** - Automatic selection from RCAF, COSTAR, RACE, CIDI, TIDD-EC, CRISPE, CRAFT based on complexity
3. **Quality scoring** - CLEAR evaluation (50-point scale: Correctness, Logic, Expression, Arrangement, Reusability)
4. **Transparent reporting** - Two-layer transparency with concise updates and detailed reasoning

**Use this command when:**
- You have a raw prompt that needs structure and clarity
- You want to apply proven prompt engineering frameworks
- You need objective quality scoring for prompt comparison
- You're iterating on prompt design and need systematic improvement

---

## Workflow Overview (5 DEPTH Phases)

| Phase | Name | Purpose | Outputs |
|-------|------|---------|---------|
| D | Discover | Analyze intent, assess complexity, identify gaps | complexity_score, ricce_gaps, baseline_clear_score |
| E | Engineer | Select framework, apply cognitive rigor, restructure | selected_framework, cognitive_insights, restructured_draft |
| P | Prototype | Generate enhanced draft, validate RICCE | enhanced_prompt_draft, ricce_validation_5/5 |
| T | Test | Calculate CLEAR scores, compare quality | original_score, enhanced_score, improvement_delta |
| H | Harmonize | Final polish, consistency check, confirm targets | final_enhanced_prompt, final_clear_score_≥40/50 |

---

## Contract

**Inputs:** `$ARGUMENTS` = prompt text (REQUIRED) + mode flag (OPTIONAL: `:quick`, `:improve`, `:refine`)

**Outputs:**
- Enhanced prompt with framework structure
- CLEAR quality score (original vs enhanced)
- Framework selection rationale
- Improvement summary
- `STATUS=OK|FAIL|CANCELLED`

**Mode Behaviors:**
- **Default (Interactive)**: Full DEPTH with user participation, framework selection prompts
- **`:quick`**: Fast enhancement (1-5 rounds, auto-select framework, <10s target)
- **`:improve`**: Standard enhancement (10 rounds, interactive framework selection)
- **`:refine`**: Iterative mode (assumes existing good prompt, focuses on polish)

**Example Invocation:**
```bash
/improve_prompt "Write a function that processes user data"
/improve_prompt:quick "Analyze customer feedback and generate insights"
/improve_prompt:improve "You are an expert system that helps with code review"
/improve_prompt:refine "Role: Senior developer. Task: Review pull requests..."
```

---

## Instructions

Execute the following phases to enhance prompts using DEPTH methodology:

### Phase 1: Mode Detection & Input Parsing

**Extract from `$ARGUMENTS`:**

1. **Detect mode flag:**
   ```
   If $ARGUMENTS ends with :quick:
     mode = "quick"
     rounds = 1-5 (adaptive based on complexity)
     framework_selection = "automatic"
     user_interaction = "minimal"

   Else if $ARGUMENTS ends with :improve:
     mode = "improve"
     rounds = 10
     framework_selection = "interactive for complexity 5+"
     user_interaction = "standard"

   Else if $ARGUMENTS ends with :refine:
     mode = "refine"
     rounds = 10
     framework_selection = "preserve existing structure"
     user_interaction = "polish focus"

   Else:
     mode = "interactive"
     rounds = 10
     framework_selection = "interactive"
     user_interaction = "full"
   ```

2. **Extract prompt text:**
   - Remove mode flag if present
   - Trim whitespace
   - Validate non-empty

3. **If prompt text is empty:**
   ```
   Use AskUserQuestion:

   I need a prompt to enhance. Please provide:

   **A)** Paste your complete prompt text
   **B)** Describe what you want the prompt to do (I'll draft initial prompt)
   **C)** Provide file path containing prompt
   **D)** Cancel operation

   Your choice?
   ```

   Wait for user response:
   - If A: Use provided text
   - If B: Draft initial prompt from description, then proceed
   - If C: Read file using Read tool, extract prompt
   - If D: `STATUS=CANCELLED` and exit

4. **Store initial state:**
   ```
   original_prompt = [prompt text]
   original_length = [character count]
   mode = [detected mode]
   timestamp_start = [current time]
   ```

**Validation checkpoint:**
- [ ] Mode flag detected correctly (quick/improve/refine/interactive)
- [ ] Prompt text extracted and non-empty
- [ ] User response received if empty prompt (A/B/C/D selection)
- [ ] Initial state stored for comparison

---

### Phase 2: DEPTH Processing (Invoke improve_prompt.yaml)

**Execute DEPTH framework workflow:**

5. **Load and invoke `.opencode/prompts/improve_prompt.yaml`:**
   ```
   Pass to workflow:
   - prompt_text: [original prompt]
   - mode: [quick|improve|refine|interactive]
   - rounds: [1-5 for quick, 10 for others]
   - framework_preference: [auto|interactive|preserve]
   ```

6. **DEPTH Phases (executed by improve_prompt.yaml):**

   **Phase D: Discover (Rounds 1-2)**
   - Analyze prompt purpose and intent
   - Identify missing components (Role, Instructions, Context, Constraints, Examples)
   - Assess complexity (1-10 scale)
   - Multi-perspective analysis (minimum 3 perspectives: Prompt Engineering, AI Interpretation, User Clarity)

   **Phase E: Engineer (Rounds 3-5)**
   - Apply framework selection algorithm based on complexity:
     - Complexity 1-4: RCAF (Role, Context, Action, Format)
     - Complexity 5-6: User chooses between RCAF, COSTAR, TIDD-EC
     - Complexity 7: User chooses streamlined (RCAF) or comprehensive (CRAFT)
     - Complexity 8-10: CRAFT (Context, Role, Action, Format, Target) with TIDD-EC alternative
   - Cognitive rigor techniques:
     - **Perspective Inversion** (2-3 min): View from LLM's interpretation angle
     - **Constraint Reversal** (1-2 min): Question assumed constraints
     - **Assumption Audit** (2 min): Challenge unstated assumptions
     - **Mechanism First** (3-4 min): Focus on how AI will process this
   - Restructure prompt using selected framework

   **Phase P: Prototype (Rounds 6-7)**
   - Generate enhanced prompt draft
   - Apply RICCE validation:
     - **R**ole: Clearly defined persona/expertise
     - **I**nstructions: Unambiguous steps/tasks
     - **C**ontext: Relevant background information
     - **C**onstraints: Explicit boundaries/requirements
     - **E**xamples: Concrete demonstrations
   - Refine language for clarity and precision

   **Phase T: Test (Rounds 8-9)**
   - CLEAR scoring (50-point scale):
     - **C**orrectness (10 pts × 20%): Accuracy and factual integrity
     - **L**ogic (10 pts × 20%): Reasoning structure and coherence
     - **E**xpression (15 pts × 30%): Clarity, precision, readability
     - **A**rrangement (10 pts × 20%): Organization and flow
     - **R**eusability (5 pts × 10%): Adaptability and modularity
   - Compare original vs enhanced (target: ≥40/50, ≥8/10 per dimension)
   - Identify remaining gaps or weaknesses

   **Phase H: Harmonize (Round 10)**
   - Final polish and consistency check
   - Verify all RICCE components present
   - Ensure framework structure is clear
   - Confirm CLEAR score meets targets

7. **Monitor progress (two-layer transparency):**

   **External Layer (to user):**
   ```
   🔍 Phase D: Discovering prompt structure... [Rounds 1-2/10]
   🔧 Phase E: Engineering framework (RCAF selected)... [Rounds 3-5/10]
   📝 Phase P: Prototyping enhanced prompt... [Rounds 6-7/10]
   ✅ Phase T: Testing quality (CLEAR: 42/50)... [Rounds 8-9/10]
   🎯 Phase H: Harmonizing final version... [Round 10/10]
   ```

   **Internal Layer (full rigor):**
   - Complete multi-perspective analysis
   - Detailed cognitive rigor technique application
   - Comprehensive RICCE validation
   - Full CLEAR scoring breakdown

8. **Framework selection interaction (mode: improve or interactive):**

   **If complexity 5-6:**
   ```
   Use AskUserQuestion:

   Complexity Assessment: [5-6]/10

   Which framework should I use for enhancement?

   **A) RCAF (Role-Context-Action-Format)**
   - Best for: Clear instructions, moderate complexity
   - Structure: Simple 4-component framework
   - Speed: Fast

   **B) COSTAR (Context-Objective-Style-Tone-Audience-Response)**
   - Best for: Communication-focused prompts
   - Structure: 6-component framework
   - Speed: Moderate

   **C) TIDD-EC (Task-Instructions-Details-Deliverables-Examples-Constraints)**
   - Best for: Detailed task specifications
   - Structure: 6-component framework
   - Speed: Moderate

   Your choice?
   ```

   **If complexity 7:**
   ```
   Use AskUserQuestion:

   Complexity Assessment: 7/10 (High complexity detected)

   This prompt is complex. How should I approach it?

   **A) Streamlined (RCAF)**
   - Simplify complexity
   - Focus on core components
   - Risk: May lose nuance

   **B) Comprehensive (CRAFT)**
   - Embrace complexity
   - Full 5-component structure
   - Risk: May be verbose

   Your choice?
   ```

   **If complexity 8-10:**
   ```
   No user question (auto-select CRAFT)

   Report: "Complexity: [8-10]/10 → Using CRAFT framework (comprehensive)"
   Note: "Alternative: TIDD-EC also suitable for this complexity"
   ```

9. **Refine mode special handling:**

   If mode = "refine":
   - Detect existing framework structure in original prompt
   - Preserve framework choice
   - Focus on:
     - Language precision
     - Removing ambiguity
     - Strengthening constraints
     - Adding missing examples
     - Improving expression score (most weight: 30%)
   - Skip framework selection entirely

**Validation checkpoint:**
- [ ] DEPTH workflow invoked with correct mode parameters
- [ ] All 5 phases (D-E-P-T-H) executed or quick mode rounds completed
- [ ] Framework selected (automatic or interactive based on complexity)
- [ ] Cognitive rigor techniques applied (4 techniques documented)
- [ ] Enhanced prompt draft generated

---

### Phase 3: Quality Validation

**Validate enhanced prompt meets quality targets:**

10. **CLEAR Score Validation:**
    ```
    Calculate original prompt CLEAR score:
    - C: [0-10] Correctness
    - L: [0-10] Logic
    - E: [0-15] Expression
    - A: [0-10] Arrangement
    - R: [0-5] Reusability
    - Total: [0-50]

    Calculate enhanced prompt CLEAR score:
    - C: [0-10] Correctness
    - L: [0-10] Logic
    - E: [0-15] Expression
    - A: [0-10] Arrangement
    - R: [0-5] Reusability
    - Total: [0-50]

    Target thresholds:
    - Overall: ≥40/50 (80%)
    - Per dimension: ≥8/10 or ≥12/15 for Expression
    - Improvement delta: ≥5 points increase
    ```

11. **RICCE Completeness Check:**
    ```
    Verify enhanced prompt contains:
    ✓ Role: Clearly defined persona or expertise level
    ✓ Instructions: Unambiguous task description
    ✓ Context: Relevant background information
    ✓ Constraints: Explicit boundaries or requirements
    ✓ Examples: At least one concrete demonstration (if applicable)

    If any missing and score <40:
      FLAG for additional refinement round
    ```

12. **Quality gate decision:**
    ```
    If enhanced_score >= 40 AND enhanced_score > original_score + 5:
      quality_status = "PASS"
      proceed to Phase 4

    Else if mode = "quick" AND enhanced_score > original_score:
      quality_status = "PASS (quick mode threshold)"
      proceed to Phase 4

    Else:
      quality_status = "RETRY"

      Use AskUserQuestion:

      Quality check: Enhanced prompt scored [X]/50, below target of 40/50.

      What should I do?

      **A)** Run one more refinement round (focus on weak dimensions)
      **B)** Accept current version (proceed with score [X]/50)
      **C)** Cancel and return original prompt

      Your choice?

      Wait for response and act accordingly
    ```

**Validation checkpoint:**
- [ ] CLEAR scores calculated for both original and enhanced prompts
- [ ] Enhanced score ≥40/50 OR user accepted lower score
- [ ] RICCE completeness verified (5/5 or 4/5 with N/A justification)
- [ ] Quality gate passed or retry completed

---

### Phase 4: Output & Reporting

**Generate comprehensive output with transparency:**

13. **Determine output location:**
    ```
    Check for active spec folder:
      If .claude/.spec-active.$$ exists:
        output_location = [contents of .spec-active file]/enhanced_prompt.md
      Else if .claude/.spec-active exists (legacy):
        output_location = [contents of .spec-active file]/enhanced_prompt.md
      Else:
        output_location = /export/[###]-enhanced-prompt-[timestamp].md
        (where ### is next sequential number in /export/)
    ```

14. **Assemble output document:**
    ```markdown
    # Enhanced Prompt

    **Generated:** [timestamp]
    **Mode:** [quick|improve|refine|interactive]
    **Framework:** [RCAF|COSTAR|RACE|CIDI|TIDD-EC|CRISPE|CRAFT]
    **Complexity:** [1-10]/10
    **DEPTH Rounds:** [1-10]

    ---

    ## Enhanced Version

    [Enhanced prompt text with framework structure clearly visible]

    ---

    ## Quality Assessment

    ### CLEAR Score Comparison

    | Dimension | Original | Enhanced | Delta |
    |-----------|----------|----------|-------|
    | **Correctness** (10) | [X]/10 | [Y]/10 | +[Z] |
    | **Logic** (10) | [X]/10 | [Y]/10 | +[Z] |
    | **Expression** (15) | [X]/15 | [Y]/15 | +[Z] |
    | **Arrangement** (10) | [X]/10 | [Y]/10 | +[Z] |
    | **Reusability** (5) | [X]/5 | [Y]/5 | +[Z] |
    | **TOTAL** | **[X]/50** | **[Y]/50** | **+[Z]** |

    **Target Met:** [YES/NO] (Target: ≥40/50)

    ### RICCE Completeness

    - ✅ **Role**: [Brief description of defined role]
    - ✅ **Instructions**: [Brief description of task clarity]
    - ✅ **Context**: [Brief description of background provided]
    - ✅ **Constraints**: [Brief description of boundaries]
    - ✅ **Examples**: [Present/Not applicable]

    ---

    ## Framework Selection Rationale

    **Complexity Assessment:** [1-10]/10
    - [Brief explanation of complexity factors]

    **Framework Choice:** [Framework name]
    - [Rationale for why this framework was selected]
    - [Alternative frameworks considered]

    **Cognitive Rigor Applied:**
    - Perspective Inversion: [Key insight]
    - Constraint Reversal: [Key insight]
    - Assumption Audit: [Key insight]
    - Mechanism First: [Key insight]

    ---

    ## Key Improvements

    1. **[Improvement category]**: [Description]
    2. **[Improvement category]**: [Description]
    3. **[Improvement category]**: [Description]

    **Characters:** Original [XXX] → Enhanced [YYY] ([+/-ZZZ])

    ---

    ## Original Prompt (Reference)

    ```
    [Original prompt text for comparison]
    ```

    ---

    **Processing Time:** [X.X] seconds
    **DEPTH Rounds Completed:** [N]/10
    ```

15. **Write output file:**

    Use Write tool to create the file at output_location with assembled content.

16. **Report success:**
    ```
    ✅ Prompt Enhancement Complete

    **Mode:** [quick|improve|refine|interactive]
    **Framework Applied:** [Framework name]
    **DEPTH Rounds:** [N]/10

    **Quality Results:**
    - Original CLEAR Score: [X]/50
    - Enhanced CLEAR Score: [Y]/50
    - Improvement: +[Z] points ([P]%)
    - Target (≥40/50): [MET ✅ | NOT MET ❌]

    **Key Enhancements:**
    - [Top improvement 1]
    - [Top improvement 2]
    - [Top improvement 3]

    **Output Location:**
    - File: [output_location]

    **Next Steps:**
    1. Review enhanced prompt at [output_location]
    2. Test prompt with your AI system
    3. Run /improve_prompt:refine if further polish needed
    4. Compare results using CLEAR scores

    **Processing Time:** [X.X] seconds

    STATUS=OK PATH=[output_location]
    ```

**Validation checkpoint:**
- [ ] Output file written successfully to correct location
- [ ] Comprehensive report generated with all sections
- [ ] CLEAR score comparison table included
- [ ] Success report displayed with STATUS=OK PATH

---

## Failure Recovery

| Condition | Recovery Action |
|-----------|-----------------|
| **Empty prompt text** | Use AskUserQuestion with 4 options (paste, describe, file path, cancel) → Retry |
| **CLEAR score below target after enhancement** | Prompt user: retry refinement, accept current, or cancel → Act on response |
| **Framework selection timeout** | Default to RCAF (safest choice) → Notify user of fallback → Continue |
| **improve_prompt.yaml not found** | Return error: "Workflow file missing at .opencode/prompts/improve_prompt.yaml" → Suggest verify installation |
| **DEPTH processing timeout (>30s)** | Cancel processing → Return partial results with note → Offer to retry with :quick mode |
| **Write permission denied** | Fallback to outputting enhanced prompt in chat → Suggest manual file creation → Provide full content |
| **Invalid mode flag** | Ignore flag → Default to interactive mode → Notify user → Continue |
| **Complexity assessment fails** | Default to complexity 5 → Use RCAF framework → Notify assumption → Continue |

---

## Examples

### Example 1: Quick Mode

**Input:**
```bash
/improve_prompt:quick "Generate a summary of user feedback"
```

**Output:**
```
🔍 Quick Enhancement Mode (1-5 rounds)

Phase D: Analyzing prompt... ✓
Phase E: Applying RCAF framework... ✓
Phase P: Generating enhanced version... ✓
Phase T: Quality check (CLEAR: 38/50)... ✓

✅ Prompt Enhancement Complete

**Mode:** quick
**Framework Applied:** RCAF (Role-Context-Action-Format)
**DEPTH Rounds:** 3/10 (quick mode)

**Quality Results:**
- Original CLEAR Score: 18/50
- Enhanced CLEAR Score: 38/50
- Improvement: +20 points (111%)
- Target (≥40/50): NOT MET ⚠️ (quick mode: acceptable)

**Enhanced Prompt:**

**Role:** You are an expert data analyst specializing in user feedback analysis.

**Context:** You will receive raw user feedback data containing comments, ratings, and metadata from various channels (surveys, reviews, support tickets).

**Action:** Analyze the feedback to identify:
1. Common themes and patterns
2. Sentiment distribution (positive/negative/neutral)
3. Priority issues requiring immediate attention
4. Actionable recommendations for product improvement

**Format:** Provide output as:
- Executive summary (3-5 sentences)
- Top 5 themes with frequency counts
- Sentiment breakdown with percentages
- Priority issues list (ranked)
- Recommendations (3-5 specific actions)

**Output Location:** /export/001-enhanced-prompt-20250127-143022.md
**Processing Time:** 4.2 seconds

STATUS=OK
```

---

### Example 2: Interactive Mode with Framework Selection

**Input:**
```bash
/improve_prompt "You are a senior developer. Review this code and provide feedback on architecture, performance, and maintainability. Be thorough."
```

**System prompts:**
```
Complexity Assessment: 6/10

Which framework should I use for enhancement?

**A) RCAF (Role-Context-Action-Format)**
**B) COSTAR (Context-Objective-Style-Tone-Audience-Response)**
**C) TIDD-EC (Task-Instructions-Details-Deliverables-Examples-Constraints)**

Your choice?
```

**User selects:** A

**Output:**
```
✅ Prompt Enhancement Complete

**Mode:** interactive
**Framework Applied:** RCAF (Role-Context-Action-Format)
**DEPTH Rounds:** 10/10

**Quality Results:**
- Original CLEAR Score: 24/50
- Enhanced CLEAR Score: 44/50
- Improvement: +20 points (83%)
- Target (≥40/50): MET ✅

**Enhanced Prompt:**

**Role:**
You are a Senior Software Architect with 10+ years of experience in distributed systems, performance optimization, and maintainable code design. You specialize in code review with focus on long-term architectural health.

**Context:**
You will review code submissions as part of a pull request process. The codebase is a production system serving [X] users with [Y] requirements for reliability and performance. The team values: (1) clear architectural patterns, (2) measurable performance, (3) long-term maintainability.

**Action:**
Conduct a comprehensive code review evaluating:

1. **Architecture Analysis:**
   - Design patterns used and their appropriateness
   - Separation of concerns and modularity
   - Scalability implications
   - Integration points and dependencies

2. **Performance Evaluation:**
   - Time complexity of algorithms
   - Memory usage patterns
   - Database query efficiency
   - Caching opportunities
   - Potential bottlenecks

3. **Maintainability Assessment:**
   - Code readability and clarity
   - Documentation completeness
   - Test coverage and quality
   - Error handling robustness
   - Technical debt introduced or resolved

**Format:**
Provide review as structured report:

**Summary** (2-3 sentences)
- Overall assessment
- Primary concerns
- Approval recommendation (Approve/Request Changes/Reject)

**Architecture** (bullet points)
- Pattern analysis
- Design strengths
- Design concerns
- Refactoring suggestions

**Performance** (bullet points with metrics when possible)
- Efficiency analysis
- Optimization opportunities
- Benchmarking recommendations

**Maintainability** (bullet points)
- Code quality observations
- Documentation gaps
- Testing recommendations
- Long-term considerations

**Action Items** (prioritized list)
1. [Critical issues requiring immediate fix]
2. [Important improvements for this PR]
3. [Nice-to-have enhancements for future]

**CLEAR Score:** C:9 L:9 E:14 A:8 R:4 = 44/50 ✅

**Output Location:** specs/009-prompt-improvement-commands/enhanced_prompt.md
**Processing Time:** 8.7 seconds

STATUS=OK
```

---

### Example 3: Refine Mode (Polish Existing Prompt)

**Input:**
```bash
/improve_prompt:refine "Role: Expert data scientist. Task: Analyze dataset and identify trends. Context: Time series data from IoT sensors. Format: Report with visualizations."
```

**Output:**
```
✅ Prompt Enhancement Complete (Refine Mode)

**Mode:** refine
**Framework Applied:** RCAF (preserved existing structure)
**DEPTH Rounds:** 10/10 (polish focus)

**Quality Results:**
- Original CLEAR Score: 36/50
- Enhanced CLEAR Score: 43/50
- Improvement: +7 points (19%)
- Target (≥40/50): MET ✅

**Key Refinements:**
1. **Expression clarity**: Removed ambiguous terms ("trends" → specific pattern types)
2. **Constraint addition**: Added explicit boundaries (timeframe, sensor types, output format)
3. **Example provision**: Included concrete example of expected analysis structure

**Enhanced Prompt:**

**Role:**
You are an expert data scientist with specialization in time series analysis, IoT sensor data interpretation, and predictive modeling. You have domain expertise in identifying anomalies, seasonal patterns, and correlation structures in high-frequency sensor data.

**Task:**
Analyze the provided time series dataset from IoT sensors to identify:
1. **Trend patterns**: Long-term directional movements (upward, downward, stable)
2. **Seasonal patterns**: Recurring cycles (daily, weekly, monthly)
3. **Anomalies**: Outliers or unexpected deviations (>3 standard deviations)
4. **Correlations**: Relationships between different sensor readings (Pearson r > 0.7)

**Context:**
- **Data source**: IoT sensors deployed in [industrial/environmental/building] setting
- **Timeframe**: [Daily/hourly/minute-level] readings over [duration]
- **Sensor types**: Temperature, humidity, pressure, vibration, [other relevant metrics]
- **Data quality**: Expect ~5% missing values, occasional sensor drift
- **Business goal**: Predictive maintenance, efficiency optimization, or anomaly detection

**Format Requirements:**

**Executive Summary** (200-300 words)
- Dataset overview (timeframe, sensors, data quality)
- Key findings (3-5 bullet points)
- Primary recommendations

**Detailed Analysis** (structured sections)

1. **Trend Analysis**
   - Methodology: [Statistical method used]
   - Findings: [Description with quantitative metrics]
   - Visualization: Line plots with trend lines

2. **Seasonal Patterns**
   - Methodology: Decomposition technique used
   - Findings: Identified cycles with periods
   - Visualization: Seasonal decomposition plots

3. **Anomaly Detection**
   - Methodology: Detection algorithm
   - Findings: Anomalies with timestamps and severity
   - Visualization: Scatter plots with anomalies highlighted

4. **Correlation Analysis**
   - Methodology: Correlation matrix
   - Findings: Significant relationships (r > 0.7)
   - Visualization: Heatmap

**Visualizations**: Include 4-6 publication-quality plots (matplotlib/seaborn style)
**Code**: Provide reproducible Python analysis code
**Data**: Summary statistics table

**Example Structure:**
```
## Executive Summary
Dataset: 10,000 hourly readings from 8 sensors (Jan-Mar 2024)
Key Finding: Temperature sensor #3 shows upward trend (+2°C/month)
Recommendation: Investigate cooling system efficiency
...
```

**CLEAR Score:** C:9 L:9 E:13 A:8 R:4 = 43/50 ✅

**Output Location:** /export/002-enhanced-prompt-20250127-151543.md
**Processing Time:** 9.1 seconds

STATUS=OK
```

---

### Example 4: High Complexity with Automatic Framework

**Input:**
```bash
/improve_prompt "Create a comprehensive AI system that analyzes legal documents, extracts key clauses, identifies risks, compares against standard templates, generates summaries for different stakeholders, and provides actionable recommendations with citations."
```

**Output:**
```
🔍 Phase D: Discovering prompt structure... [Rounds 1-2/10]
   Complexity: 9/10 (High) → Auto-selecting CRAFT framework

🔧 Phase E: Engineering framework (CRAFT)... [Rounds 3-5/10]
   Applying cognitive rigor techniques...

📝 Phase P: Prototyping enhanced prompt... [Rounds 6-7/10]
   RICCE validation: 5/5 components present

✅ Phase T: Testing quality (CLEAR: 46/50)... [Rounds 8-9/10]
   Target exceeded ✅

🎯 Phase H: Harmonizing final version... [Round 10/10]

✅ Prompt Enhancement Complete

**Mode:** interactive
**Framework Applied:** CRAFT (Context-Role-Action-Format-Target)
**Complexity:** 9/10 (High complexity - comprehensive framework required)
**DEPTH Rounds:** 10/10

**Quality Results:**
- Original CLEAR Score: 22/50
- Enhanced CLEAR Score: 46/50
- Improvement: +24 points (109%)
- Target (≥40/50): MET ✅ (exceeded by 6 points)

**Framework Rationale:**
- Complexity 9/10 requires comprehensive structure
- Multiple stakeholders demand clear target specification
- CRAFT provides necessary scaffolding for complex multi-step AI system
- Alternative: TIDD-EC (also suitable, but CRAFT better for stakeholder focus)

**Key Improvements:**
1. **Structure**: Transformed single-sentence request into 5-component CRAFT framework
2. **Specificity**: Added concrete deliverables, formats, and success criteria
3. **Stakeholder clarity**: Defined distinct outputs for legal, executive, and operational audiences
4. **Risk categorization**: Specified risk severity levels and citation requirements

**CLEAR Score Breakdown:**
- Correctness: 9/10 (legally accurate terminology)
- Logic: 10/10 (clear processing pipeline)
- Expression: 14/15 (highly readable, minor verbosity)
- Arrangement: 9/10 (excellent structure)
- Reusability: 4/5 (adaptable to similar legal analysis tasks)

**Output Location:** specs/009-prompt-improvement-commands/enhanced_prompt.md
**Processing Time:** 12.3 seconds

STATUS=OK
```

---

## Notes

**Critical Rules:**
- ALWAYS apply full DEPTH framework (10 rounds) unless :quick mode
- ALWAYS calculate CLEAR scores for original and enhanced prompts
- ALWAYS provide framework selection rationale
- NEVER skip RICCE validation
- NEVER fabricate quality scores - calculate rigorously

**Mode Selection Guidance:**
- **:quick** - Use for rapid iterations, testing, or simple prompts (<5 complexity)
- **:improve** - Use for standard enhancement workflow with user participation
- **:refine** - Use when you have a good prompt that needs polish (score 30-39)
- **interactive** (default) - Use for first-time enhancement or learning the process

**Framework Quick Reference:**
- **RCAF**: Best general-purpose framework (complexity 1-6)
- **COSTAR**: Communication-focused prompts
- **RACE**: Rapid prototyping, clear actions
- **CIDI**: Creative/ideation prompts
- **TIDD-EC**: Detailed task specifications
- **CRISPE**: System prompts with personas
- **CRAFT**: Complex multi-stakeholder prompts (complexity 8-10)

**Quality Thresholds:**
- Target: ≥40/50 overall, ≥8/10 per dimension (or ≥12/15 for Expression)
- Minimum improvement delta: +5 points
- Quick mode: Any improvement is acceptable if time-constrained

**Integration with SpecKit:**
- Enhanced prompts saved to active spec folder if available
- Falls back to `/export/` with sequential numbering
- Output includes full comparison and rationale for documentation

**Performance Targets:**
- Quick mode: <10 seconds
- Improve/Refine mode: <30 seconds
- Interactive mode: <30 seconds (excluding user wait time)

**Cognitive Rigor Timing:**
- Perspective Inversion: 2-3 minutes (view from AI interpretation angle)
- Constraint Reversal: 1-2 minutes (question assumptions)
- Assumption Audit: 2 minutes (challenge unstated assumptions)
- Mechanism First: 3-4 minutes (focus on AI processing mechanics)

**Two-Layer Transparency Model:**
- **Internal**: Full DEPTH rigor, multi-perspective analysis, detailed scoring
- **External**: Concise progress updates, key decisions, final results
- Balance: Complete analysis without overwhelming user with details

---

## Related Commands

- `/transform_request` - Convert raw requests into structured YAML (input preparation)
- `/spec_kit:complete` - Full SpecKit workflow using enhanced prompts
- `/plan_claude` - Implementation planning using enhanced specification prompts
