# Agent Prompt Templates

Copy-ready prompt templates for the 4 Sonnet Explore agents used in parallel codebase exploration.

---

## 1. 🏗️ ARCHITECTURE EXPLORER

**Focus**: Project structure, file organization, patterns
**Purpose**: Understand overall architecture

### Prompt Template

```
Explore the codebase to find architectural patterns relevant to: {task_description}

Return:
1. Your hypothesis about how the project is organized
2. Full paths to all relevant files (e.g., /path/to/file.ts:lineNumber)
3. Any patterns you noticed (file organization, module structure, naming conventions, etc.)

Do NOT draw conclusions - just report findings. The main agent will verify.
```

### Task Tool Invocation

```javascript
Task({
  subagent_type: "Explore",
  model: "sonnet",
  description: "Architecture exploration",
  prompt: `Explore the codebase to find architectural patterns relevant to: ${task_description}

Return:
1. Your hypothesis about how the project is organized
2. Full paths to all relevant files (e.g., /path/to/file.ts:lineNumber)
3. Any patterns you noticed (file organization, module structure, naming conventions, etc.)

Do NOT draw conclusions - just report findings. The main agent will verify.`
})
```

### Expected Output

```
HYPOTHESIS: The project uses a feature-based architecture with:
- src/pages/ for page components
- src/components/ for reusable UI
- src/lib/ for utilities and helpers
- src/types/ for TypeScript definitions

RELEVANT FILES:
- src/pages/index.ts:1-50 (main entry)
- src/pages/about.ts:1-80 (about page)
- src/components/Header.tsx:1-120 (header component)
- src/lib/utils.ts:15-80 (utility functions)
- tsconfig.json:1-30 (TypeScript configuration)

PATTERNS:
- Feature folders export via index.ts
- Components use .tsx extension
- Utilities use .ts extension
- PascalCase for components, snake_case for utilities
```

---

## 2. 🔍 FEATURE EXPLORER

**Focus**: Similar features, related patterns
**Purpose**: Find reusable patterns

### Prompt Template

```
Explore the codebase to find similar features or related patterns for: {task_description}

Return:
1. Your hypothesis about existing similar features
2. Full paths to all relevant files (e.g., /path/to/file.ts:lineNumber)
3. Any patterns you noticed (naming conventions, implementation patterns, etc.)

Do NOT draw conclusions - just report findings. The main agent will verify.
```

### Task Tool Invocation

```javascript
Task({
  subagent_type: "Explore",
  model: "sonnet",
  description: "Feature exploration",
  prompt: `Explore the codebase to find similar features or related patterns for: ${task_description}

Return:
1. Your hypothesis about existing similar features
2. Full paths to all relevant files (e.g., /path/to/file.ts:lineNumber)
3. Any patterns you noticed (naming conventions, implementation patterns, etc.)

Do NOT draw conclusions - just report findings. The main agent will verify.`
})
```

### Expected Output

```
HYPOTHESIS: The codebase has similar authentication patterns that could be
reused or extended. There's an existing form handling pattern in ContactForm
that matches what we need.

RELEVANT FILES:
- src/components/ContactForm.tsx:1-200 (form with validation)
- src/components/LoginForm.tsx:1-150 (authentication form)
- src/hooks/useFormValidation.ts:1-80 (validation hook)
- src/lib/api.ts:50-100 (API submission pattern)

PATTERNS:
- Forms use controlled components with useState
- Validation via custom hook (useFormValidation)
- API calls wrapped in try-catch with loading state
- Success/error toasts via Toast component
```

---

## 3. 🔗 DEPENDENCY EXPLORER

**Focus**: Imports, modules, affected areas
**Purpose**: Identify integration points

### Prompt Template

```
Explore the codebase to find dependencies and integration points for: {task_description}

Return:
1. Your hypothesis about which modules/files will be affected
2. Full paths to all relevant files (e.g., /path/to/file.ts:lineNumber)
3. Any patterns you noticed (dependency chains, coupling points, etc.)

Do NOT draw conclusions - just report findings. The main agent will verify.
```

### Task Tool Invocation

```javascript
Task({
  subagent_type: "Explore",
  model: "sonnet",
  description: "Dependency exploration",
  prompt: `Explore the codebase to find dependencies and integration points for: ${task_description}

Return:
1. Your hypothesis about which modules/files will be affected
2. Full paths to all relevant files (e.g., /path/to/file.ts:lineNumber)
3. Any patterns you noticed (dependency chains, coupling points, etc.)

Do NOT draw conclusions - just report findings. The main agent will verify.`
})
```

### Expected Output

```
HYPOTHESIS: The feature will need to integrate with:
- Authentication context (global state)
- API client (for server communication)
- Router (for navigation after auth)

RELEVANT FILES:
- src/context/AuthContext.tsx:1-100 (auth state provider)
- src/lib/api.ts:1-150 (API client with auth headers)
- src/lib/router.ts:1-80 (routing configuration)
- src/components/ProtectedRoute.tsx:1-50 (auth guard)
- package.json:1-50 (external dependencies)

PATTERNS:
- Context provider pattern for global state
- API client adds auth token to all requests
- Protected routes check AuthContext before render
- External dependencies: axios, react-router-dom
```

---

## 4. 🧪 TEST EXPLORER

**Focus**: Test patterns, testing infrastructure
**Purpose**: Understand verification approach

### Prompt Template

```
Explore the codebase to find test patterns and testing infrastructure.

Return:
1. Your hypothesis about how testing works in this project
2. Full paths to all relevant test files (e.g., /path/to/file.test.ts:lineNumber)
3. Any patterns you noticed (test frameworks, mocking patterns, coverage expectations, etc.)

Do NOT draw conclusions - just report findings. The main agent will verify.
```

### Task Tool Invocation

```javascript
Task({
  subagent_type: "Explore",
  model: "sonnet",
  description: "Test exploration",
  prompt: `Explore the codebase to find test patterns and testing infrastructure.

Return:
1. Your hypothesis about how testing works in this project
2. Full paths to all relevant test files (e.g., /path/to/file.test.ts:lineNumber)
3. Any patterns you noticed (test frameworks, mocking patterns, coverage expectations, etc.)

Do NOT draw conclusions - just report findings. The main agent will verify.`
})
```

### Expected Output

```
HYPOTHESIS: The project uses Jest for unit tests and Playwright for E2E tests.
Test files are co-located with source files using .test.ts suffix.

RELEVANT FILES:
- jest.config.js:1-30 (Jest configuration)
- playwright.config.ts:1-50 (Playwright configuration)
- src/components/Button.test.tsx:1-80 (component test example)
- src/lib/utils.test.ts:1-60 (utility test example)
- tests/e2e/auth.spec.ts:1-100 (E2E test example)

PATTERNS:
- Unit tests: Jest with React Testing Library
- E2E tests: Playwright with Page Object Model
- Mocking: jest.mock() for dependencies
- Test naming: describe('ComponentName') -> it('should...')
- Coverage threshold: 80% (from jest.config.js)
```

---

## 5. 📝 USAGE NOTES

### ⚠️ Parallel Spawning (CRITICAL)

**CRITICAL**: All 4 agents must be spawned in a **single message** for true parallel execution.

**✅ CORRECT** (parallel, ~15-30 seconds total):
```javascript
// Single message with 4 Task calls
Task({ description: "Architecture exploration", ... })
Task({ description: "Feature exploration", ... })
Task({ description: "Dependency exploration", ... })
Task({ description: "Test exploration", ... })
```

**❌ WRONG** (sequential, ~60-100 seconds total):
```javascript
// Multiple messages = sequential execution
const arch = await Task({ description: "Architecture exploration", ... })
const feat = await Task({ description: "Feature exploration", ... })
// ... etc (4x slower)
```

### ✅ Model Specification

Always specify `model: "sonnet"` in Task tool calls:

```javascript
Task({
  subagent_type: "Explore",
  model: "sonnet",  // REQUIRED - ensures fast, cost-effective exploration
  // ...
})
```

### ✅ Variable Substitution

Replace `{task_description}` with the actual task description before spawning:

```javascript
const prompt = template.replace('{task_description}', task_description)
```

### ✅ Output Processing

After agents return, collect their findings into a unified structure:

```javascript
const findings = {
  architecture: architectureAgent.result,
  feature: featureAgent.result,
  dependency: dependencyAgent.result,
  test: testAgent.result
}
```

---

## 6. ⚙️ PROMPT CUSTOMIZATION

### Adding Context

For tasks requiring specific focus, prepend context to prompts:

```
CONTEXT: This is a Webflow-hosted site with custom JavaScript loaded via CDN.
The codebase uses Motion.dev for animations and follows CDN-safe patterns.

Explore the codebase to find architectural patterns relevant to: {task_description}
[... rest of prompt ...]
```

### Narrowing Scope

For large codebases, add path constraints:

```
Explore the codebase to find architectural patterns relevant to: {task_description}

SCOPE: Focus on files in src/components/ and src/pages/ directories.

Return:
[... rest of prompt ...]
```

### Extending Output

For deeper exploration, add output sections:

```
Return:
1. Your hypothesis about how the project is organized
2. Full paths to all relevant files (e.g., /path/to/file.ts:lineNumber)
3. Any patterns you noticed (file organization, module structure, etc.)
4. Potential challenges or risks you identified
5. Recommended approach based on findings

Do NOT draw conclusions - just report findings. The main agent will verify.
```

---

**Remember**: These prompts generate hypotheses, not verified facts. Always verify agent findings by reading the identified files before including them in the plan.
