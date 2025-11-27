---
description: Search codebase semantically using natural language queries
argument-hint: "<query> [--refined]"
allowed-tools: mcp__semantic-search__semantic_search
---

# Index Search

Perform semantic code search using natural language queries to find relevant code based on what it does, not just keyword matching.

---

## Purpose

Search your codebase using natural language queries. This leverages the semantic-search MCP server to find relevant code chunks based on functionality and intent, not just literal text matching.

---

## Contract

**Inputs:** `$ARGUMENTS` — Natural language search query, optionally followed by `--refined` flag
**Outputs:** `STATUS=<OK|FAIL> RESULTS_COUNT=<count>`

---

## Instructions

Execute the following steps:

1. **Parse arguments:**
   - Extract the search query from `$ARGUMENTS`
   - Check if `--refined` flag is present (enables LLM-based analysis)
   - If query is empty, return `STATUS=FAIL ERROR="Query is required"`

2. **Determine workspace path:**
   - Use current working directory: `/Users/michelkerkmeester/MEGA/Development/Websites/anobel.com`
   - This should match the workspace configured in the MCP server

3. **Execute semantic search:**
   - Call the MCP tool: `mcp__semantic-search__semantic_search`
   - Parameters:
     - `workspace_path`: Current workspace
     - `query`: The search query from step 1
     - `max_results`: 20 (default)
     - `refined_answer`: true if `--refined` flag present, false otherwise

4. **Format and display results:**
   - Show relevant code chunks with file paths and line numbers
   - If refined answer is enabled, display the LLM analysis brief first
   - Format file references as `file_path:line_number` for easy navigation
   - Count total unique files found

5. **Return status:**
   - If successful: `STATUS=OK RESULTS_COUNT=<count>`
   - If failed: `STATUS=FAIL ERROR="<error message>"`

---

## Example Usage

### Basic Search
```bash
/index:search "authentication middleware"
```

### Search with Refined Analysis
```bash
/index:search "video player initialization" --refined
```

### Sample Query Types
- "how is form validation handled"
- "navigation menu implementation"
- "hero section animation logic"
- "where are API requests made"
- "error handling patterns"

---

## Notes
- **Query Tips:**
  - Be specific: "how do we validate email inputs" > "validation"
  - Use exact names if known: "HeroVideo component"
  - Ask about functionality, not file names
  - Combine concepts: "form submission and error handling"

- **Refined Mode:**
  - Adds LLM-based analysis of relevance
  - Identifies key files vs boilerplate
  - Highlights missing references or imports
  - More expensive but more insightful

- **Requirements:**
  - Semantic-search MCP server must be running
  - Index must be populated (run `/index:start` first if needed)
  - At least some files must be indexed for results

## Example Output
```
🔍 Semantic Search Results for: "authentication middleware"

📊 Found 5 relevant code chunks across 3 files

src/2_javascript/form/form_validation.js:45-67
  // Email validation function
  function validateEmail(email) { ... }

src/2_javascript/form/form_submission.js:23-45
  // Form submission with validation
  async function handleSubmit(event) { ... }

[Additional results...]

STATUS=OK RESULTS_COUNT=3
```
