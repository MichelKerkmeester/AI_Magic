# Gemini CLI Built-in Tools

Reference for Gemini's built-in tools, their capabilities, and usage patterns.

---

## 1. 🌟 UNIQUE TOOLS

Tools available only through Gemini CLI (unique to Gemini).

### google_web_search

Performs web search using Google Search API.

**Capabilities:**
- Real-time internet search
- Current information (news, releases, docs)
- Grounded responses with sources

**Usage:**
```bash
gemini "What are the latest React 19 features? Use Google Search." -o text
```

**Best For:**
- Current events and news
- Latest library versions
- Recent documentation updates
- Community opinions and benchmarks

**Example Queries:**
- "What are the security vulnerabilities in lodash 4.x? Use Google Search."
- "What's new in TypeScript 5.4? Use Google Search."
- "Best practices for Next.js 14 app router in November 2025."

### codebase_investigator

Specialized tool for deep codebase analysis.

**Capabilities:**
- Architectural mapping
- Dependency analysis
- Cross-file relationship detection
- System-wide pattern identification

**Usage:**
```bash
gemini "Use the codebase_investigator tool to analyze this project" -o text
```

**Output Includes:**
- Overall architecture description
- Key file purposes
- Component relationships
- Dependency chains
- Potential issues/inconsistencies

**Best For:**
- Onboarding to new codebases
- Understanding legacy systems
- Finding hidden dependencies
- Architecture documentation

**Example:**
```bash
gemini "Use codebase_investigator to map the authentication flow in this project" -o text
```

### save_memory

Saves information to persistent long-term memory.

**Capabilities:**
- Cross-session persistence
- Key-value storage
- Recall in future sessions

**Usage:**
```bash
gemini "Remember that this project uses Zustand for state management. Save this to memory." -o text
```

**Best For:**
- Project conventions
- User preferences
- Recurring context
- Custom instructions

---

## 2. 📁 FILE OPERATIONS

Standard file system tools.

### list_directory

Lists files and subdirectories in a path.

**Parameters:**
- `path`: Directory to list
- `ignore`: Glob patterns to exclude

**Example Output:**
```
src/
  components/
  utils/
  index.js
package.json
README.md
```

### read_file

Reads file content with truncation for large files.

**Supported Formats:**
- Text files (all types)
- Images (PNG, JPG, GIF, WEBP, SVG, BMP)
- PDF documents

**Parameters:**
- `path`: File path
- `offset`: Starting line (for large files)
- `limit`: Number of lines

**Large File Handling:**
If file exceeds limit, output indicates truncation and provides instructions for reading more with offset/limit.

---

## 3. 🔍 SEARCH & DISCOVERY

Tools for finding files and content.

### search_file_content

Fast content search powered by ripgrep.

**Advantages over grep:**
- Optimized performance
- Automatic output limiting (max 20k matches)
- Better pattern matching

**Parameters:**
- `pattern`: Regex pattern
- `path`: Search root
- Various ripgrep flags

### glob

Pattern-based file finding.

**Returns:**
- Absolute paths
- Sorted by modification time (newest first)

**Example Patterns:**
- `src/**/*.ts` - All TypeScript files in src
- `**/*.test.js` - All test files
- `**/README.md` - All READMEs

---

## 4. 🌐 NETWORK OPERATIONS

Tools for fetching web content.

### web_fetch

Fetches content from URLs.

**Capabilities:**
- HTTP/HTTPS URLs
- Local addresses (localhost)
- Up to 20 URLs per request

**Usage:**
```bash
gemini "Fetch and summarize https://example.com/docs" -o text
```

---

## 5. ✅ TASK MANAGEMENT

Internal task tracking tools.

### write_todos

Internal task tracking.

**Capabilities:**
- Track subtasks for complex requests
- Organize multi-step work
- Prevent missed steps

**Automatic Usage:**
Gemini uses this internally for complex tasks.

---

## 6. 📊 TOOL STATISTICS

JSON output format for tool usage metrics.

When using `-o json`, tool usage is reported:

```json
{
  "stats": {
    "tools": {
      "totalCalls": 3,
      "totalSuccess": 3,
      "totalFail": 0,
      "totalDurationMs": 5000,
      "totalDecisions": {
        "accept": 0,
        "reject": 0,
        "modify": 0,
        "auto_accept": 3
      },
      "byName": {
        "google_web_search": {
          "count": 1,
          "success": 1,
          "fail": 0,
          "durationMs": 3000,
          "decisions": {
            "auto_accept": 1
          }
        },
        "read_file": {
          "count": 2,
          "success": 2,
          "fail": 0,
          "durationMs": 2000,
          "decisions": {
            "auto_accept": 2
          }
        }
      }
    }
  }
}
```

---

## 7. 🔧 TOOL CONFIGURATION

Restricting and configuring tool access.

### Using allowed-tools

In settings or command line, restrict available tools:

```bash
gemini --allowed-tools "read_file,glob" "Find config files" -o text
```

### In Settings

```json
{
  "security": {
    "allowedTools": ["read_file", "list_directory", "glob"]
  }
}
```

---

## 8. 💡 BEST PRACTICES

Guidelines for effective tool usage.

### When to Use Specific Tools

**google_web_search:**
- Need current/recent information
- Checking latest versions
- Finding documentation updates
- Community solutions to problems

**codebase_investigator:**
- New to a codebase
- Understanding complex systems
- Finding hidden dependencies
- Creating documentation

**save_memory:**
- Recurring project context
- User preferences
- Custom conventions

### Tool Combination Patterns

**Research → Implement:**
```bash
gemini "Use Google Search to find best practices for [topic], then implement them" --yolo -o text
```

**Analyze → Report:**
```bash
gemini "Use codebase_investigator to analyze the project, then write a summary report" --yolo -o text
```

**Search → Read → Modify:**
```bash
gemini "Find all files using deprecated API, read them, and suggest updates" -o text
```

### Tool Invocation

**Automatic Tool Selection:**

Gemini automatically selects appropriate tools based on the prompt:

| Prompt Type                 | Tool Selected         |
| --------------------------- | --------------------- |
| "What files are in src/"    | list_directory        |
| "Find all TODO comments"    | search_file_content   |
| "Read package.json"         | read_file             |
| "Find all React components" | glob                  |
| "What's new in Vue 4?"      | google_web_search     |
| "Analyze this codebase"     | codebase_investigator |

**Explicit Tool Requests:**

You can explicitly request tools:

```bash
gemini "Use the codebase_investigator tool to..." -o text
gemini "Search the web for..." -o text
gemini "Use glob to find all..." -o text
```

### Tool Selection Decision Tree

Quick decision guide for choosing the right tool for your task.

```
Need current/recent information?
├─ YES → Use google_web_search
│   ├─ Latest library versions
│   ├─ Current best practices
│   ├─ Recent documentation updates
│   └─ Community solutions/benchmarks
└─ NO → Need deep codebase understanding?
    ├─ YES → Use codebase_investigator
    │   ├─ Architecture mapping
    │   ├─ Dependency chain analysis
    │   ├─ Cross-file relationships
    │   └─ Pattern identification
    └─ NO → Need cross-session persistence?
        ├─ YES → Use save_memory
        │   ├─ Project conventions
        │   ├─ User preferences
        │   └─ Custom instructions
        └─ NO → Use standard file tools
            ├─ read_file (read content)
            ├─ list_directory (explore)
            ├─ search_file_content (find)
            └─ glob (pattern match)
```

### Tool Combination Patterns

Effective patterns for combining multiple tools in workflows.

**Research → Implement:**
```bash
# Step 1: Research with google_web_search
# Step 2: Implement with file tools
gemini "Use Google Search to find React 19 best practices, then implement them in @./src/App.js" --yolo
```

**Analyze → Refactor:**
```bash
# Step 1: Analyze with codebase_investigator
# Step 2: Refactor based on findings
gemini "Use codebase_investigator to find all deprecated API usage, then update to new API" --yolo
```

**Search → Read → Modify:**
```bash
# Step 1: Search for pattern
# Step 2: Read matching files
# Step 3: Apply modifications
gemini "Find all components using old state management, read them, and migrate to new pattern" --yolo
```

**Web Research → Local Implementation:**
```bash
# Combine web research with local code generation
gemini "Research latest TypeScript error handling patterns via Google Search, then create error-handling.ts with examples" --yolo
```

---

## 9. 🆚 COMPARISON WITH OTHER AI TOOLS

Tool capability comparison between Gemini CLI and standard AI tools.

| Capability    | Standard AI Tools | Gemini CLI                |
| ------------- | ----------------- | ------------------------- |
| File listing  | LS, Glob          | list_directory, glob      |
| File reading  | Read              | read_file                 |
| File writing  | Write, Edit       | write_file (in YOLO)      |
| Code search   | Grep              | search_file_content       |
| Web fetch     | WebFetch          | web_fetch                 |
| Web search    | WebSearch         | **google_web_search**     |
| Architecture  | Task (Explore)    | **codebase_investigator** |
| Memory        | N/A               | **save_memory**           |
| Task tracking | TodoWrite         | write_todos               |

**Bold** = Gemini's unique advantage