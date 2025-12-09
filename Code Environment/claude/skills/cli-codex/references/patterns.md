# Codex CLI Integration Patterns

Advanced workflow patterns for integrating Codex CLI into development processes with explicit reasoning and validation checkpoints.

### Core Principle

"Different AI perspectives catch more issues than one - use generation-review-fix cycles for highest quality code."

---

## 1. 🔄 CORE PATTERNS

### Pattern 1: Generate-Review-Fix Cycle

**Pattern**: Three-step workflow for quality code generation with self-correction.

**Rationale**: Different AI perspective between generation and review improves code quality.

**Validation**: `code_quality_verified`

**Implementation:**

```bash
# Step 1: Generate
codex exec "Create [feature] with [requirements]" --full-auto 2>&1 > generated.log

# Step 2: Review (different perspective)
# Option A: Codex reviews its own work
codex exec "Review the code in [file] for bugs, security issues, and improvements" 2>&1 > review.log

# Option B: Claude reviews Codex's work
# [Use Claude's native review capabilities]

# Step 3: Fix identified issues
codex exec "Fix these issues in [file]: [list from review]. Apply fixes." --full-auto 2>&1
```

**Use Cases:**
- Complex feature implementation
- Security-critical code
- Performance-sensitive algorithms
- Production code requiring high quality

---

### 2. Cross-Validation Pattern

**Pattern**: Use Claude and Codex to validate each other's work.

**Rationale**: Two different AI perspectives catch more issues than one.

**Implementation:**

```bash
# Claude generates code
# [Claude creates implementation]

# Codex reviews Claude's code
codex exec "Review [claude-generated-file] for: 1) correctness, 2) security, 3) performance, 4) edge cases" 2>&1

# OR reverse:

# Codex generates code
codex exec "Create [feature]" --full-auto 2>&1

# Claude reviews Codex's code
# [Claude performs review]
```

**Use Cases:**
- Critical system components
- Security-sensitive features
- Complex business logic
- Highest quality requirements

---

### 3. Background Execution Pattern

**Pattern**: Run long Codex tasks in background while continuing other work.

**Rationale**: Maximize productivity by parallelizing work.

**Implementation:**

```bash
# Start background task
codex exec "Generate comprehensive test suite for [large project]" --full-auto 2>&1 > tests.log &
BG_PID=$!

# Continue with other work using Claude
# [Claude continues with implementation]

# Check if background task completed
if kill -0 $BG_PID 2>/dev/null; then
  echo "Codex still running..."
else
  echo "Codex completed. Review tests.log"
fi
```

**Use Cases:**
- Test generation for large codebases
- Documentation generation
- Large-scale refactoring analysis
- Multiple file analysis

---

### 4. Incremental Refinement Pattern

**Pattern**: Build complex outputs in stages rather than all at once.

**Rationale**: Easier debugging, validation per stage, better quality.

**Implementation:**

```bash
# Stage 1: Core functionality
codex exec "Create basic [component] with core features only" --full-auto 2>&1
# Validate Stage 1

# Stage 2: Add feature A (using session continuity)
codex resume --last "Add [feature A] to the component" 2>&1
# Validate Stage 2

# Stage 3: Add feature B
codex resume --last "Now add [feature B]" 2>&1
# Validate Stage 3

# Stage 4: Polish and optimize
codex resume --last "Refine the code: add error handling, optimize performance" 2>&1
```

**Use Cases:**
- Complex features with multiple concerns
- Large components
- Uncertain requirements (iterative clarification)
- Learning unfamiliar domains

---

## 2. 🎯 STRATEGIC PATTERNS

### 5. Model Selection Strategy

**Pattern**: Match task complexity to appropriate model/reasoning level.

**Decision Tree:**

```
Task Complexity
├── Complex (architecture, security, optimization)
│   └── Use: gpt-5.1-codex (high reasoning)
│        codex exec "[prompt]" 2>&1
│
├── Medium (standard features, refactoring)
│   └── Use: gpt-5.1-codex (default)
│        codex exec "[prompt]" 2>&1
│
└── Simple (boilerplate, basic operations)
    └── Use: o3-mini (faster)
         codex exec "[prompt]" -m o3-mini 2>&1
```

**Use Cases:**
- Resource optimization
- Cost management
- Speed vs quality trade-offs

---

### 6. Rate Limit Management Pattern

**Pattern**: Handle API rate limits gracefully with throttling and batching.

**Implementation:**

```bash
# Throttled Sequential Processing
for file in src/**/*.js; do
  echo "Processing $file..."
  codex exec "Review $file for security issues" 2>&1 > "reviews/$(basename $file).log"
  sleep 2  # 2-second delay between requests
done

# Batch Processing
FILES=$(ls src/**/*.js | head -10)
codex exec "Review these files for security issues: $FILES. Provide summary report." 2>&1

# Priority Queue (high priority first)
# Process critical files immediately
codex exec "Review auth.js" 2>&1
# Batch non-critical files
codex exec "Review these utility files: [list]" 2>&1
```

**Use Cases:**
- Large codebases
- Multiple file analysis
- Automated workflows
- CI/CD integration

---

### 7. Context Enrichment Pattern

**Pattern**: Provide rich context for better quality responses.

**Implementation:**

```bash
# Explicit Context in Prompt
codex exec "Context: This is a React app using TypeScript and Redux. File uses custom hooks pattern. Task: Review components/UserProfile.tsx for type safety and hook usage correctness." 2>&1

# Project Configuration Context
# Create ~/.codex/config.toml with project standards
cat > .codex/project-context.toml << EOF
[project]
framework = "React"
language = "TypeScript"
patterns = ["hooks", "redux"]
EOF

# File Reference Context
codex exec "Review this file in context of the API spec at docs/api.md: src/api/client.ts" 2>&1
```

**Use Cases:**
- Domain-specific code
- Framework-specific patterns
- Company coding standards
- Complex project conventions

---

## 3. 🚀 ADVANCED PATTERNS

### 8. Validation Pipeline Pattern

**Pattern**: Multi-step automated quality assurance.

**Implementation:**

```bash
# Step 1: Syntax Check
if [[ $LANGUAGE == "javascript" ]]; then
  node --check $FILE || exit 1
fi

# Step 2: Security Scan
codex exec "Security audit of $FILE. Check OWASP Top 10." 2>&1 > security.log
# Parse security.log for issues

# Step 3: Functional Test
# Run test suite

# Step 4: Style Check
codex exec "Review $FILE for code style issues per project standards" 2>&1 > style.log

# Final: Aggregate Results
echo "Validation complete. Check logs for issues."
```

**Use Cases:**
- Pre-commit hooks
- CI/CD pipelines
- Code review automation
- Quality gates

---

### 9. Diff Application Pattern

**Pattern**: Safely apply Codex-generated changes to codebase.

**Implementation:**

```bash
# Generate changes
codex exec "Refactor $FILE to improve [aspect]. Generate diff." --full-auto 2>&1 > changes.log

# Extract session/task ID from output
TASK_ID=$(grep "session id:" changes.log | cut -d' ' -f3)

# Review diff before applying
codex apply $TASK_ID --dry-run

# Apply if approved
codex apply $TASK_ID

# Alternative: Manual application
# Extract code from changes.log and apply manually
```

**Use Cases:**
- Safe refactoring
- Large-scale changes
- Automated code modifications
- Merge conflict resolution

---

### 10. Session Continuity Pattern

**Pattern**: Multi-turn workflows with saved context.

**Implementation:**

```bash
# Initial Analysis
codex exec "Analyze architecture of src/ directory" 2>&1 | tee analysis.log

# Extract session ID
SESSION_ID=$(grep "session id:" analysis.log | awk '{print $4}')

# Continue with follow-ups
codex resume $SESSION_ID "What are the main dependencies between modules?" 2>&1

codex resume $SESSION_ID "Suggest improvements to reduce coupling" 2>&1

codex resume $SESSION_ID "Generate refactoring plan" 2>&1

# Alternative: Use --last for most recent
codex resume --last "Generate implementation tasks" 2>&1
```

**Use Cases:**
- Iterative analysis
- Complex debugging
- Multi-step planning
- Exploratory architecture work

---

## 4. ❌ ANTI-PATTERNS

### What to Avoid

**1. Single-Shot Everything**
- **Don't**: Try to generate entire complex systems in one prompt
- **Do**: Use incremental refinement pattern

**2. Blind Trust**
- **Don't**: Apply generated code without review
- **Do**: Use validation pipeline pattern

**3. Ignoring Rate Limits**
- **Don't**: Rapid-fire requests without throttling
- **Do**: Use rate limit management pattern

**4. Over-Specification**
- **Don't**: Write 500-word prompts with every detail
- **Do**: Start simple, refine iteratively

**5. Context Neglect**
- **Don't**: Provide minimal context for complex tasks
- **Do**: Use context enrichment pattern

**6. Sequential When Parallel Works**
- **Don't**: Wait for each task when they're independent
- **Do**: Use background execution pattern

**7. Forgetting Session State**
- **Don't**: Lose session IDs and restart from scratch
- **Do**: Use session continuity pattern

**8. Wrong Tool Selection**
- **Don't**: Use Codex for simple tasks Claude handles well
- **Do**: Reserve Codex for second opinions and complex reasoning

---

## 5. 🔗 INTEGRATION WITH CLAUDE CODE WORKFLOWS

### Pattern: Claude Implements, Codex Validates

```bash
# Phase 1: Claude implements feature
# [Claude generates implementation]

# Phase 2: Codex reviews
codex exec "Review [claude-implementation] for: security, performance, edge cases" 2>&1

# Phase 3: Address findings
# [Claude or Codex fixes issues]

# Phase 4: Final validation
# [Run tests, manual review]
```

### Pattern: Codex Generates, Claude Integrates

```bash
# Phase 1: Codex generates component
codex exec "Generate [component] with [specs]" --full-auto 2>&1

# Phase 2: Claude integrates into codebase
# [Claude handles imports, dependencies, testing, integration]

# Phase 3: Both validate
# [Cross-validation pattern]
```

### Pattern: Parallel Work Stream

```bash
# Stream 1: Claude works on feature A
# [Claude implements feature A]

# Stream 2: Codex works on feature B (background)
codex exec "Implement [feature B]" --full-auto 2>&1 &

# Stream 3: Codex generates tests for A (background)
codex exec "Generate tests for [feature A code]" --full-auto 2>&1 &

# Merge: Integrate all streams
# [Claude coordinates integration]
```

---

## 6. 🛡️ ERROR RECOVERY PATTERNS

### Pattern: Graceful Failure Handling

```bash
# Attempt operation with error capture
codex exec "[prompt]" --full-auto 2>&1 > output.log
EXIT_CODE=$?

if [ $EXIT_CODE -ne 0 ]; then
  # Check for specific errors
  if grep -q "Rate limit" output.log; then
    echo "Rate limited. Waiting 60s..."
    sleep 60
    # Retry
    codex exec "[prompt]" --full-auto 2>&1
  elif grep -q "Authentication" output.log; then
    echo "Authentication failed. User intervention required."
    exit 1
  else
    echo "Unknown error. Falling back to Claude."
    # Use Claude instead
  fi
fi
```

### Pattern: Fallback Strategy

```bash
# Try Codex first
codex exec "[complex task]" 2>&1 > codex_output.log

# If Codex fails or produces poor output, use Claude
if [ $? -ne 0 ] || [ ! -s codex_output.log ]; then
  echo "Codex failed. Using Claude instead."
  # [Use Claude for task]
fi
```

---

## 7. ⚡ PERFORMANCE OPTIMIZATION PATTERNS

### Pattern: Result Caching

```bash
# Check cache first
CACHE_KEY=$(echo "[prompt]" | md5)
CACHE_FILE="~/.codex-cache/$CACHE_KEY"

if [ -f "$CACHE_FILE" ]; then
  echo "Using cached result"
  cat "$CACHE_FILE"
else
  echo "Generating new result"
  codex exec "[prompt]" 2>&1 | tee "$CACHE_FILE"
fi
```

### Pattern: Lazy Evaluation

```bash
# Don't run Codex until absolutely needed
if [ "$VALIDATION_NEEDED" = "true" ]; then
  codex exec "Validate [code]" 2>&1
fi
```

---

## 8. ✅ BEST PRACTICES SUMMARY

### DO
- ✅ Use incremental refinement for complex tasks
- ✅ Cross-validate critical code
- ✅ Run independent tasks in parallel
- ✅ Provide rich context
- ✅ Review all generated code
- ✅ Save session IDs for continuity
- ✅ Choose appropriate models
- ✅ Throttle bulk operations

### DON'T

- ❌ Generate everything in one prompt
- ❌ Trust output blindly
- ❌ Ignore rate limits
- ❌ Forget to capture stderr
- ❌ Use for trivial tasks
- ❌ Neglect error handling
- ❌ Skip validation
- ❌ Overload context window

---

## 9. 🗺️ PATTERN SELECTION GUIDE

| Need | Recommended Pattern |
|------|---------------------|
| High quality code | Generate-Review-Fix, Cross-Validation |
| Large project | Background Execution, Rate Limit Management |
| Complex feature | Incremental Refinement, Session Continuity |
| Fast iteration | Model Selection Strategy, Lazy Evaluation |
| Production safety | Validation Pipeline, Diff Application |
| Learning codebase | Session Continuity, Context Enrichment |
| CI/CD integration | Validation Pipeline, Error Recovery |
| Cost optimization | Model Selection, Result Caching |
