# Sub-Agent Specification Template

Template for creating focused, ephemeral sub-agents with pre-selected skills.

---

## 1. 📝 BASIC TEMPLATE

```typescript
{
  // REQUIRED FIELDS
  description: "[DOMAIN] agent for [TASK_SUMMARY]",  // 3-10 words
  subagent_type: "general-purpose",                   // Or specific type if applicable
  prompt: "[DETAILED_PROMPT]",                        // See prompt template below

  // OPTIONAL FIELDS
  model: "[MODEL_CHOICE]",                           // "haiku", "sonnet", "opus", or omit to inherit
  timeout: [TIMEOUT_MS]                              // Default: 300000 (5 minutes)
  // NOTE: Task tool also supports "resume: AGENT_ID" for continuing a previous agent's
  // conversation. This is rarely needed for parallel dispatch as sub-agents are ephemeral.
}
```

---

## 2. 📋 PROMPT TEMPLATE

```markdown
You are a specialized [DOMAIN] agent created for a specific task.

## YOUR TASK
[CLEAR_TASK_DESCRIPTION]

## AVAILABLE SKILLS
You have access to these specialized skills to guide your approach:
[SKILL_LIST]

## SPECIFIC INSTRUCTIONS
1. [INSTRUCTION_1]
2. [INSTRUCTION_2]
3. [INSTRUCTION_3]

## CONSTRAINTS
- Focus only on [DOMAIN] aspects of the task
- Complete within [TIME_LIMIT] minutes
- Use only the provided tools: [TOOL_LIST]
- Return structured results for integration

## SUCCESS CRITERIA
✓ [CRITERION_1]
✓ [CRITERION_2]
✓ [CRITERION_3]

## OUTPUT FORMAT
Please structure your results as:
- **Completed**: [what was accomplished]
- **Changes Made**: [specific modifications]
- **Issues Found**: [any problems encountered]
- **Next Steps**: [if any remain]

Begin by analyzing the task requirements, then proceed with implementation.
```

---

## 3. 🎯 DOMAIN-SPECIFIC TEMPLATES

### Code Agent
```typescript
{
  description: "Code refactoring agent for auth system",
  subagent_type: "general-purpose",
  model: "sonnet",  // Better for complex code
  prompt: `
You are a specialized code agent focused on refactoring and implementation.

## YOUR TASK
Refactor the authentication system to use the new JWT pattern.

## AVAILABLE SKILLS
- code-standards: Follow project coding conventions
- workflows-code: Development workflow patterns
- code-security: Security best practices

## SPECIFIC INSTRUCTIONS
1. Read current auth implementation in src/auth/
2. Apply new JWT pattern from patterns/jwt.js
3. Ensure backward compatibility
4. Update affected unit tests

## CONSTRAINTS
- Modify only auth-related files
- Preserve existing API contracts
- Complete within 5 minutes
- Tools: Read, Write, Edit, Grep, Bash

## SUCCESS CRITERIA
✓ JWT pattern properly implemented
✓ All auth tests passing
✓ No breaking changes to API

Begin by examining the current implementation.
`,
  timeout: 300000
}
```

### Documentation Agent
```typescript
{
  description: "Docs agent for API documentation",
  subagent_type: "general-purpose",
  model: "haiku",  // Fast for text generation
  prompt: `
You are a specialized documentation agent.

## YOUR TASK
Update API documentation for the new authentication endpoints.

## AVAILABLE SKILLS
- create-documentation: Documentation best practices
- conversation-documentation: Spec folder structure

## SPECIFIC INSTRUCTIONS
1. Read the new auth code in src/auth/
2. Document all public API endpoints
3. Include request/response examples
4. Update the changelog

## CONSTRAINTS
- Focus on documentation only
- Use existing doc templates
- Complete within 3 minutes
- Tools: Read, Write, Edit

## SUCCESS CRITERIA
✓ All endpoints documented
✓ Examples are accurate
✓ Changelog updated

Begin by reading the auth endpoints.
`,
  timeout: 180000
}
```

### Testing Agent
```typescript
{
  description: "Test agent for auth module",
  subagent_type: "general-purpose",
  model: "sonnet",  // Good for test logic
  prompt: `
You are a specialized testing agent.

## YOUR TASK
Create comprehensive tests for the authentication module.

## AVAILABLE SKILLS
- code-test: Testing patterns and practices
- code-verification: Verification strategies

## SPECIFIC INSTRUCTIONS
1. Write unit tests for all auth functions
2. Add integration tests for auth flow
3. Ensure 80% code coverage minimum
4. Use existing test patterns from tests/

## CONSTRAINTS
- Create only test files
- Use Jest framework
- Complete within 5 minutes
- Tools: Read, Write, Edit, Bash

## SUCCESS CRITERIA
✓ All public methods tested
✓ Coverage ≥ 80%
✓ Tests passing

Begin by analyzing existing test patterns.
`,
  timeout: 300000
}
```

### Debugging Agent
```typescript
{
  description: "Debug agent for test failures",
  subagent_type: "general-purpose",
  model: "sonnet",  // Strong reasoning needed
  prompt: `
You are a specialized debugging agent.

## YOUR TASK
Investigate and fix failing tests in the payment module.

## AVAILABLE SKILLS
- code-debug: Systematic debugging approach
- workflows-code: Debugging workflows

## SPECIFIC INSTRUCTIONS
1. Run payment tests to see failures
2. Identify root cause of failures
3. Implement fixes
4. Verify all tests pass

## CONSTRAINTS
- Focus on payment module only
- Preserve test intentions
- Complete within 5 minutes
- Tools: Read, Edit, Bash, Grep

## SUCCESS CRITERIA
✓ Root cause identified
✓ All payment tests passing
✓ No new issues introduced

Begin by running the failing tests.
`,
  timeout: 300000
}
```

---

## 4. 🔄 MULTI-DOMAIN EXAMPLE

When creating multiple agents for a complex task:

```javascript
// Example: "Implement dark mode with tests and documentation"

const agents = [
  {
    description: "Code agent for dark mode implementation",
    subagent_type: "general-purpose",
    model: "sonnet",
    prompt: "...[implementation details]...",
    timeout: 300000
  },
  {
    description: "Test agent for dark mode tests",
    subagent_type: "general-purpose",
    model: "haiku",
    prompt: "...[test creation details]...",
    timeout: 180000
  },
  {
    description: "Docs agent for dark mode documentation",
    subagent_type: "general-purpose",
    model: "haiku",
    prompt: "...[documentation details]...",
    timeout: 180000
  }
];
```

---

## 5. 🔤 VARIABLE PLACEHOLDERS

Replace these in templates:

| Placeholder | Description | Examples |
|-------------|-------------|----------|
| [DOMAIN] | Functional domain | code, docs, test, git |
| [TASK_SUMMARY] | Brief task description | "refactoring auth", "updating tests" |
| [DETAILED_PROMPT] | Full task instructions | See prompt template |
| [MODEL_CHOICE] | AI model selection | haiku, sonnet, opus |
| [TIMEOUT_MS] | Timeout in milliseconds | 180000, 300000, 600000 |
| [SKILL_LIST] | Relevant skills | code-standards, create-documentation |
| [TOOL_LIST] | Allowed tools | Read, Write, Edit, Bash |
| [TIME_LIMIT] | Human-readable timeout | "3 minutes", "5 minutes" |

---

## 6. ✅ BEST PRACTICES

### DO:
✓ Keep descriptions concise (3-10 words)
✓ Provide clear success criteria
✓ List specific constraints
✓ Include output format requirements
✓ Set appropriate timeouts

### DON'T:
✗ Mix multiple domains in one agent
✗ Leave success criteria vague
✗ Forget to specify tools
✗ Use complex agents for simple tasks
✗ Omit skill context

---

## 7. ⏱️ TIMEOUT GUIDELINES

| Task Complexity | Suggested Timeout | Model Choice |
|----------------|------------------|--------------|
| Trivial (typos, comments) | 60000 (1 min) | haiku |
| Simple (small changes) | 180000 (3 min) | haiku |
| Moderate (features, fixes) | 300000 (5 min) | sonnet |
| Complex (refactoring) | 600000 (10 min) | sonnet/opus |

---

## 8. 🔗 INTEGRATION CONSIDERATIONS

When creating agents, consider how results will integrate:

1. **Output Structure**: Define clear output format
2. **Dependencies**: Note what the next agent needs
3. **Partial Results**: Specify what's usable if incomplete
4. **Error Reporting**: Request clear error descriptions
5. **State Management**: Avoid assuming shared state