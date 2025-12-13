# Codex CLI Prompt Templates

Ready-to-use prompt templates for common Codex CLI operations. Replace `[placeholders]` with your specific values.

---

## 1. 💻 CODE GENERATION

### Single File Application

```bash
codex exec "Create a [language] [application type] that [functionality]. Include [features]. Requirements: [requirements]. Output complete code." --full-auto 2>&1
```

**Example:**
```bash
codex exec "Create a Python CLI tool that fetches weather data. Include argument parsing and error handling. Requirements: use requests library, support multiple cities. Output complete code." --full-auto 2>&1
```

### Component/Module

```bash
codex exec "Generate a [language] [component type] for [purpose]. It should [features]. Follow [pattern/convention]." --full-auto 2>&1
```

**Example:**
```bash
codex exec "Generate a React component for user profile display. It should accept user data as props and show avatar, name, and bio. Follow functional component pattern with TypeScript." --full-auto 2>&1
```

### Multi-File Project

```bash
codex exec "Create a [project type] with these files: [file list]. The project should [functionality]. Include [features]." --full-auto 2>&1
```

**Example:**
```bash
codex exec "Create a REST API with these files: server.js, routes.js, models/user.js. The project should handle user CRUD operations. Include input validation and error handling." --full-auto 2>&1
```

---

## 2. 🔍 CODE REVIEW

### Comprehensive Review

```bash
codex exec "Review [file or directory] for: 1) Feature completeness, 2) Bugs and logic errors, 3) Security issues, 4) Performance concerns, 5) Code quality and maintainability. Provide detailed findings with specific line references." 2>&1
```

**Example:**
```bash
codex exec "Review src/auth.js for: 1) Feature completeness, 2) Bugs and logic errors, 3) Security issues, 4) Performance concerns, 5) Code quality and maintainability. Provide detailed findings with specific line references." 2>&1
```

### Security-Focused Review

```bash
codex exec "Perform security audit on [file]. Check for: XSS vulnerabilities, SQL injection risks, authentication issues, authorization flaws, data exposure, CSRF protection. List all findings with severity ratings." 2>&1
```

**Example:**
```bash
codex exec "Perform security audit on api/users.js. Check for: XSS vulnerabilities, SQL injection risks, authentication issues, authorization flaws, data exposure, CSRF protection. List all findings with severity ratings." 2>&1
```

### Performance Review

```bash
codex exec "Analyze [file] for performance issues. Look for: inefficient algorithms, unnecessary computations, memory leaks, blocking operations, optimization opportunities. Suggest specific improvements." 2>&1
```

**Example:**
```bash
codex exec "Analyze services/data-processor.js for performance issues. Look for: inefficient algorithms, unnecessary computations, memory leaks, blocking operations, optimization opportunities. Suggest specific improvements." 2>&1
```

---

## 3. 🐛 BUG FIXING

### Fix Known Bugs

```bash
codex exec "Fix these bugs in [file]: 1) [bug description], 2) [bug description], 3) [bug description]. Apply the fixes directly and preserve existing functionality." --full-auto 2>&1
```

**Example:**
```bash
codex exec "Fix these bugs in utils/validator.js: 1) Email validation allows invalid formats, 2) Password strength check has off-by-one error, 3) Missing null check in phone validation. Apply the fixes directly and preserve existing functionality." --full-auto 2>&1
```

### Auto-Detect and Fix

```bash
codex exec "Analyze [file] for bugs and fix them. Focus on: logic errors, edge cases, type issues, error handling gaps. Apply fixes and explain each change." --full-auto 2>&1
```

**Example:**
```bash
codex exec "Analyze controllers/payment.js for bugs and fix them. Focus on: logic errors, edge cases, type issues, error handling gaps. Apply fixes and explain each change." --full-auto 2>&1
```

---

## 4. 🧪 TEST GENERATION

### Unit Tests

```bash
codex exec "Generate [test framework] unit tests for [file]. Cover: [scenario 1], [scenario 2], [scenario 3]. Include edge cases and error conditions. Target ≥[X]% coverage." --full-auto 2>&1
```

**Example:**
```bash
codex exec "Generate Jest unit tests for utils/calculator.js. Cover: basic operations, division by zero, floating point precision, negative numbers. Include edge cases and error conditions. Target ≥90% coverage." --full-auto 2>&1
```

### Integration Tests

```bash
codex exec "Generate [framework] integration tests for [component/API]. Test scenarios: [scenario 1], [scenario 2]. Include setup and teardown." --full-auto 2>&1
```

**Example:**
```bash
codex exec "Generate supertest integration tests for /api/users endpoints. Test scenarios: create user, fetch user, update user, delete user. Include database setup and teardown." --full-auto 2>&1
```

### Test Fixtures

```bash
codex exec "Generate test fixtures for [entity]. Include: [variation 1], [variation 2], [variation 3]. Format as [format]." 2>&1
```

**Example:**
```bash
codex exec "Generate test fixtures for User model. Include: valid user, admin user, user with missing fields, user with invalid email. Format as JSON." 2>&1
```

---

## 5. 📝 DOCUMENTATION

### JSDoc/TSDoc Generation

```bash
codex exec "Generate comprehensive JSDoc comments for all functions in [file]. Include parameter types, return types, descriptions, and examples." --full-auto 2>&1
```

**Example:**
```bash
codex exec "Generate comprehensive JSDoc comments for all functions in lib/helpers.js. Include parameter types, return types, descriptions, and examples." --full-auto 2>&1
```

### README Generation

```bash
codex exec "Generate a README.md for this project. Include: project description, installation instructions, usage examples, API documentation, configuration options, contributing guidelines." 2>&1
```

### API Documentation

```bash
codex exec "Document the API endpoints in [file]. For each endpoint include: HTTP method, route, parameters, request body, response format, status codes, example requests." 2>&1
```

**Example:**
```bash
codex exec "Document the API endpoints in routes/products.js. For each endpoint include: HTTP method, route, parameters, request body, response format, status codes, example requests." 2>&1
```

---

## 6. 🔄 CODE TRANSFORMATION

### Refactoring

```bash
codex exec "Refactor [file] to improve [aspect]. Goals: [goal 1], [goal 2]. Maintain existing functionality and preserve the public API." --full-auto 2>&1
```

**Example:**
```bash
codex exec "Refactor services/order-processor.js to improve maintainability. Goals: extract helper functions, reduce complexity, add better error handling. Maintain existing functionality and preserve the public API." --full-auto 2>&1
```

### Language Translation

```bash
codex exec "Translate this [source language] code to [target language]: [code or file reference]. Preserve logic and add appropriate idioms for target language." 2>&1
```

**Example:**
```bash
codex exec "Translate this Python code to JavaScript: [file path]. Preserve logic and add appropriate idioms for JavaScript (Promises, async/await)." 2>&1
```

### Framework Migration

```bash
codex exec "Migrate [component] from [old framework] to [new framework]. Preserve functionality and follow [new framework] best practices." --full-auto 2>&1
```

**Example:**
```bash
codex exec "Migrate UserProfile component from React class component to functional component with hooks. Preserve functionality and follow React hooks best practices." --full-auto 2>&1
```

---

## 7. 📐 TYPE DEFINITIONS

### TypeScript Types

```bash
codex exec "Generate TypeScript type definitions for [API/schema]. Include: [entity 1], [entity 2], [entity 3]. Use interfaces where appropriate." 2>&1
```

**Example:**
```bash
codex exec "Generate TypeScript type definitions for REST API responses. Include: User, Post, Comment, ApiResponse. Use interfaces where appropriate." 2>&1
```

### Interface from JSON

```bash
codex exec "Create a TypeScript interface from this JSON: [JSON data]. Name it [InterfaceName] and make appropriate fields optional." 2>&1
```

---

## 8. 🏗️ ARCHITECTURE & ANALYSIS

### Project Analysis

```bash
codex exec "Analyze the architecture of [project or directory]. Report on: file structure, module dependencies, design patterns used, architectural concerns, improvement recommendations." 2>&1
```

**Example:**
```bash
codex exec "Analyze the architecture of src/. Report on: file structure, module dependencies, design patterns used, architectural concerns, improvement recommendations." 2>&1
```

### Dependency Analysis

```bash
codex exec "Analyze dependencies in [file or project]. Check for: unused dependencies, version conflicts, security vulnerabilities, outdated packages. Suggest updates." 2>&1
```

### Code Explanation

```bash
codex exec "Explain what this code does: [code or file]. Break down: purpose, key algorithms, data flow, edge cases handled, potential issues." 2>&1
```

**Example:**
```bash
codex exec "Explain what this code does in algorithms/merkle-tree.js. Break down: purpose, key algorithms, data flow, edge cases handled, potential issues." 2>&1
```

---

## 9. ⚡ SPECIALIZED TASKS

### Git Commit Message

```bash
codex exec "Generate a git commit message for these changes: [diff or description]. Follow conventional commits format." 2>&1
```

**Example:**
```bash
codex exec "Generate a git commit message for these changes: added user authentication, updated API routes, fixed validation bug. Follow conventional commits format." 2>&1
```

### Error Diagnosis

```bash
codex exec "Diagnose this error: [error message]. Analyze: root cause, affected components, fix strategy, prevention measures." 2>&1
```

**Example:**
```bash
codex exec "Diagnose this error: TypeError: Cannot read property 'id' of undefined in processUser function. Analyze: root cause, affected components, fix strategy, prevention measures." 2>&1
```

### Code Comparison

```bash
codex exec "Compare these two implementations: [approach A] vs [approach B]. Evaluate: performance, maintainability, scalability, error handling. Recommend best choice." 2>&1
```

---

## 10. 📦 BOILERPLATE GENERATION

### Configuration Files

```bash
codex exec "Generate a [config file type] for [tool/framework]. Include: [option 1], [option 2], [option 3]. Add comments explaining each section." 2>&1
```

**Example:**
```bash
codex exec "Generate a webpack.config.js for React application. Include: dev server config, babel loader, CSS modules, production optimization. Add comments explaining each section." 2>&1
```

### Project Scaffolding

```bash
codex exec "Create project structure for [project type]. Include: directory layout, essential files, basic configuration. Follow [convention] standards." --full-auto 2>&1
```

**Example:**
```bash
codex exec "Create project structure for Express REST API. Include: directory layout (routes, controllers, models, middleware), essential files, basic configuration. Follow MVC standards." --full-auto 2>&1
```

---

## 11. 🔁 MULTI-TURN PATTERNS

### Session Continuity

```bash
# First interaction - analysis
codex exec "Analyze the codebase structure in src/ and identify the main components." 2>&1

# Note the session ID from output, then resume:
codex resume [session-id] "Based on that analysis, generate a component diagram in Mermaid format." 2>&1

# Or resume most recent:
codex resume --last "Now suggest refactoring improvements for the largest component." 2>&1
```

---

## 12. 📋 TEMPLATE VARIABLES REFERENCE

Standard placeholders used across templates:

- `[file]` - File path
- `[directory]` - Directory path
- `[language]` - Programming language
- `[framework]` - Framework name
- `[component type]` - Type of component
- `[functionality]` - What it should do
- `[features]` - List of features
- `[requirements]` - List of requirements
- `[pattern/convention]` - Design pattern or coding convention
- `[aspect]` - Specific aspect to focus on
- `[goal]` - Objective to achieve
- `[X]` - Numeric value (e.g., coverage percentage)
- `[format]` - Data format (JSON, YAML, etc.)
- `[scenario]` - Test scenario description
- `[bug description]` - Description of a bug
- `[code]` - Code snippet or reference
- `[API/schema]` - API or schema reference
- `[entity]` - Data entity name

---

## 13. ✅ BEST PRACTICES

### Prompt Construction

1. **Be Specific**: Include exact requirements and constraints
2. **State Output Format**: Specify how you want the response structured
3. **Include Context**: Mention relevant technologies, patterns, conventions
4. **Add Action Words**: Use "Apply", "Generate", "Output complete" for execution
5. **Reference Files**: Use absolute or relative paths clearly

### Execution Tips

1. **Use --full-auto**: For code generation and modifications
2. **Omit --full-auto**: For analysis and review tasks
3. **Capture Output**: Always use `2>&1` to capture stderr
4. **Session Continuity**: Save session IDs for multi-turn workflows
5. **Validate Output**: Always review generated code before applying

### Safety Guidelines

1. **Review First**: Never blindly apply generated code
2. **Test Thoroughly**: Run tests before committing changes
3. **Check Security**: Scan for vulnerabilities in generated code
4. **Verify Dependencies**: Ensure suggested packages are appropriate
5. **Maintain Context**: Provide enough information for accurate generation
