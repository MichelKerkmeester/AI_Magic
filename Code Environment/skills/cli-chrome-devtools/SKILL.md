---
name: cli-chrome-devtools
description: Direct Chrome DevTools Protocol access via browser-debugger-cli (bdg) terminal commands. Lightweight alternative to MCP servers for browser debugging, automation, and testing with significant token efficiency through self-documenting tool discovery (--list, --describe, --search).
---

# Chrome DevTools CLI - Direct CDP Access via Terminal Commands

Enables AI agents to leverage browser-debugger-cli (bdg) for direct Chrome DevTools Protocol access via terminal commands. Provides lightweight browser automation, debugging, and testing without the overhead of MCP servers or Puppeteer/Playwright frameworks.

---

## 1. 🎯 WHEN TO USE

### 📚 Navigation Guide

**This file (SKILL.md)**: Core workflow patterns, session management basics, common CDP commands, tool comparison for quick browser debugging via terminal.

**Reference Files** (detailed documentation):
- [cdp_patterns.md](./references/cdp_patterns.md) – Complete CDP domain patterns, Unix composability, discovery workflows (9 sections)
- [session_management.md](./references/session_management.md) – Advanced session patterns, multi-session management, state persistence (11 sections)
- [troubleshooting.md](./references/troubleshooting.md) – Systematic diagnostics, error resolution, platform-specific fixes (14 sections)

**When to load references**:
- CDP domain exploration → cdp_patterns.md
- Complex session scenarios → session_management.md
- Errors or installation issues → troubleshooting.md

**This skill should be used when**:
- User mentions "browser debugging", "Chrome DevTools", "CDP" explicitly
- User asks to inspect, test, or automate browser tasks with lightweight CLI approach
- User wants screenshots, HAR files, console logs, or network inspection via terminal
- User mentions "bdg" or "browser-debugger-cli" explicitly
- User requests alternative to Puppeteer/Playwright when lightweight CLI preferred
- User needs quick DOM queries, cookie manipulation, or JavaScript execution in browser
- User wants terminal-based browser automation with Unix pipe composability

**This skill should NOT be used for**:
- Complex UI testing suites requiring sophisticated frameworks (use Puppeteer/Playwright instead)
- MCP-based workflows where MCP infrastructure already working (use mcp-code-mode skill)
- Heavy multi-step automation workflows better suited for frameworks
- Cross-browser testing (bdg supports Chrome/Chromium/Edge only)
- Visual regression testing or complex test frameworks
- When user explicitly requests Puppeteer, Playwright, or Selenium

---

### Tool Comparison

| Feature | cli-chrome-devtools (bdg) | Chrome DevTools MCP | Puppeteer/Playwright |
|---------|---------------------------|---------------------|---------------------|
| **Setup** | `npm install -g bdg` | MCP config + server | Heavy dependencies |
| **Discovery** | `--list`, `--describe`, `--search` | `search_tools()` | API docs required |
| **Execution** | Direct Bash commands | `call_tool_chain()` | Script files |
| **Token Cost** | Lowest (self-doc) | Medium (progressive) | Highest (verbose) |
| **CDP Access** | All 644 methods | MCP-exposed subset | Full but complex |
| **Best For** | Debugging, inspection | Multi-tool workflows | Complex UI testing |
| **State** | Session-based | Tool chain | Script context |
| **Learning Curve** | Minimal | Moderate | Steep |

**Use bdg when**:
- Quick debugging/inspection tasks
- Terminal-first workflow preferred
- Token efficiency is priority
- Self-documenting discovery needed

**Use MCP when**:
- Integrating multiple MCP tools
- Complex multi-tool orchestration
- Type-safe tool invocation required

**Use Puppeteer/Playwright when**:
- Complex UI test suites
- Heavy automation workflows
- Need cross-browser support

---

## 2. 🧭 SMART ROUTING

```python
def route_bdg_resources(task):
    # CDP method guidance and examples
    if task.needs_cdp_patterns or task.exploring_domains or task.unix_pipes:
        return load("references/cdp_patterns.md")

    # Advanced session patterns
    if task.session_complexity or task.multi_session or task.resumption:
        return load("references/session_management.md")

    # Error resolution
    if task.has_error or task.troubleshooting or task.installation_issue:
        return load("references/troubleshooting.md")

    # Default: SKILL.md has basics for common cases
```

---

## 3. 🗂️ REFERENCES

### Core Framework
| Document | Purpose | Key Insight |
|----------|---------|-------------|
| **Chrome DevTools CLI - Main Workflow** | Terminal-based CDP access via bdg | **Lightweight alternative to MCP servers with self-documenting discovery** |

### References
| Document | Purpose | Key Insight |
|----------|---------|-------------|
| **references/cdp_patterns.md** | CDP domain patterns, command examples, Unix composability, discovery workflows | Load for CDP method guidance, domain exploration, or Unix pipe patterns |
| **references/session_management.md** | Advanced session patterns, multi-session management, state persistence, cleanup | Load for session complexity, multi-session scenarios, or resumption needs |
| **references/troubleshooting.md** | Error resolution, installation fixes, platform-specific issues, debug mode | Load for errors, installation issues, browser connection problems, or debugging |

---

## 4. 🛠️ HOW IT WORKS

### Installation & Verification

**Before first use**, verify bdg availability:

```bash
# Check if installed
command -v bdg || echo "Install: npm install -g browser-debugger-cli@alpha"

# Verify version
bdg --version 2>&1

# Check Chrome/Chromium available
which google-chrome chromium-browser chromium 2>/dev/null
```

**Installation command**:
```bash
npm install -g browser-debugger-cli@alpha
```

**Platform support**:
- macOS: Native support
- Linux: Native support
- Windows: WSL only (PowerShell/Git Bash NOT supported)

**Browser compatibility**:
- Google Chrome (recommended)
- Chromium
- Microsoft Edge (Chromium-based)

### Self-Discovery Workflow

**Core differentiator**: bdg is self-documenting. ALWAYS use discovery commands when exploring new capabilities.

**Progressive disclosure pattern**:

```bash
# Step 1: List available domains and methods
bdg --list
# Output: All 53 CDP domains with method counts

# Step 2: Explore specific domain
bdg --describe Page
# Output: All Page domain methods with parameters

# Step 3: Search for specific capability
bdg --search screenshot
# Output: All methods containing "screenshot"

# Step 4: Get method details
bdg --describe Page.captureScreenshot
# Output: Method signature, parameters, return type

# Step 5: Execute discovered method
bdg cdp Page.captureScreenshot 2>&1
```

**Discovery advantages**:
- No hardcoded method lists (tool maintains documentation)
- Up-to-date with CDP changes
- Token efficient (load only needed info)
- Case-insensitive search
- Cross-domain discovery

**Example: Finding cookie methods**:
```bash
bdg --search cookie 2>&1
# Returns: Network.getCookies, Network.setCookie, Network.deleteCookies, etc.

bdg --describe Network.setCookie 2>&1
# Returns: Full method signature and parameter details
```

### Session Management Basics

**Session lifecycle**:

```bash
# 1. Start session with URL
bdg https://example.com 2>&1

# 2. Verify session active
bdg status 2>&1

# 3. Execute operations
bdg screenshot output.png 2>&1
bdg console logs 2>&1
bdg cdp Page.captureScreenshot 2>&1

# 4. Stop session (cleanup)
bdg stop 2>&1
```

**Session states**:
- `inactive` - No browser connection
- `starting` - Browser launching
- `active` - Ready for commands
- `error` - Connection failed

**ALWAYS verify session before CDP commands**:
```bash
# Check session status
if bdg status 2>&1 | jq -e '.state == "active"' > /dev/null; then
  bdg cdp Page.captureScreenshot 2>&1
else
  echo "No active session - start one first"
  bdg https://example.com 2>&1
fi
```

**Cleanup pattern**:
```bash
#!/bin/bash
# Ensure cleanup on script exit
trap "bdg stop 2>&1" EXIT INT TERM

bdg https://example.com 2>&1
bdg screenshot output.png 2>&1
# Cleanup happens automatically on exit
```

### Common CDP Patterns

**Page domain - Screenshots**:
```bash
# Helper command (simplest)
bdg screenshot output.png 2>&1

# CDP method (base64 output)
bdg cdp Page.captureScreenshot 2>&1 | jq -r '.result.data' | base64 -d > output.png

# With viewport clip
bdg cdp Page.captureScreenshot '{
  "clip": {"x": 0, "y": 0, "width": 800, "height": 600, "scale": 1}
}' 2>&1
```

**DOM domain - Element queries**:
```bash
# Helper command (simplest)
bdg dom query ".my-class" 2>&1
bdg dom query "#element-id" 2>&1
bdg dom query "[data-testid='login']" 2>&1

# CDP method (full control)
doc_node=$(bdg cdp DOM.getDocument 2>&1 | jq '.result.root.nodeId')
element=$(bdg cdp DOM.querySelector "{\"nodeId\": $doc_node, \"selector\": \"h1\"}" 2>&1 | jq '.result.nodeId')
bdg cdp DOM.getOuterHTML "{\"nodeId\": $element}" 2>&1 | jq -r '.result.outerHTML'
```

**Network domain - Cookies**:
```bash
# Helper commands (simplest)
bdg network cookies 2>&1
bdg network headers 2>&1

# CDP methods (full control)
bdg cdp Network.enable 2>&1
bdg cdp Network.getCookies '{"urls":["https://example.com"]}' 2>&1

# Set cookie
bdg cdp Network.setCookie '{
  "name": "auth_token",
  "value": "secret-123",
  "domain": "example.com",
  "path": "/",
  "secure": true,
  "httpOnly": true
}' 2>&1

# Delete cookie
bdg cdp Network.deleteCookies '{"name": "auth_token", "domain": "example.com"}' 2>&1
```

**Runtime domain - Console & JavaScript**:
```bash
# Helper commands (simplest)
bdg console logs 2>&1
bdg js "document.title" 2>&1
bdg js "localStorage.getItem('token')" 2>&1

# CDP methods (full control)
bdg cdp Runtime.enable 2>&1
bdg cdp Runtime.evaluate '{"expression": "document.title", "returnByValue": true}' 2>&1
```

**Network domain - HAR export**:
```bash
# Export network trace
bdg cdp Network.enable 2>&1
# ... wait for page load ...
bdg har export network-trace.har 2>&1

# Analyze with jq
jq '.log.entries[] | {url: .request.url, status: .response.status, time}' network-trace.har
```

### Unix Composability

**Pipe to jq for JSON processing**:

```bash
# Extract specific fields
bdg console logs 2>&1 | jq '.[] | select(.level == "error")'

# Filter results
bdg network cookies 2>&1 | jq '[.[] | {name, domain, value}]'

# Count items
bdg cdp DOM.querySelectorAll '{"nodeId":1,"selector":"div"}' 2>&1 | jq '.result.nodeIds | length'

# Transform and save
bdg cdp Page.getNavigationHistory 2>&1 | jq '.result.entries[] | .url' > urls.txt
```

**Grep for text filtering**:

```bash
# Find errors in console
bdg console logs 2>&1 | grep -i "error"

# Filter by URL pattern
bdg har export - 2>&1 | grep "api.example.com"
```

**Combine with other tools**:

```bash
# Download screenshot and upload to S3
bdg screenshot - 2>&1 | aws s3 cp - s3://bucket/screenshot.png

# Extract data and POST to API
bdg js "localStorage.getItem('data')" 2>&1 | jq -r '.result.value' | curl -X POST -d @- https://api.example.com/data

# Chain multiple operations
for url in "${urls[@]}"; do
  bdg "$url" 2>&1
  bdg screenshot "${url//https:\/\//}.png" 2>&1
  bdg console logs 2>&1 > "${url//https:\/\//}-console.json"
  bdg stop 2>&1
done
```

### Error Handling

**ALWAYS capture stderr**:

```bash
# Correct - captures both stdout and stderr
bdg cdp Page.navigate '{"url":"https://example.com"}' 2>&1

# Wrong - loses error messages
bdg cdp Page.navigate '{"url":"https://example.com"}'
```

**Check exit codes**:

```bash
# Verify command success
bdg screenshot output.png 2>&1
if [ $? -eq 0 ]; then
  echo "Screenshot captured successfully"
else
  echo "Screenshot failed - check errors"
fi

# Conditional execution
bdg status 2>&1 && bdg screenshot output.png 2>&1 || echo "Session not active"
```

**Parse JSON errors**:

```bash
# CDP method errors returned as JSON
output=$(bdg cdp Page.navigate '{"url":"invalid"}' 2>&1)

if echo "$output" | jq -e '.error' > /dev/null; then
  error_msg=$(echo "$output" | jq -r '.error.message')
  echo "CDP Error: $error_msg"
fi
```

**Common errors**:
- `Error: No active session` → Start session first with `bdg <url>`
- `Error: Method not found` → Use `bdg --search` to find correct method name
- `Error: Could not find Chrome` → Set `CHROME_PATH` environment variable
- `Error: Invalid parameter` → Check method signature with `bdg --describe`

---

## 5. 📋 RULES

### ✅ ALWAYS

- **Verify bdg installation** before first use: `command -v bdg || echo "Install: npm install -g browser-debugger-cli@alpha"`
- **Start with discovery commands** (`--list`, `--describe`, `--search`) when exploring new capabilities
- **Verify session status** before executing CDP commands
- **Capture stderr** with `2>&1` for comprehensive error handling
- **Use helpers when available** (`bdg screenshot`, `bdg console logs`) - simpler than raw CDP
- **Stop sessions promptly** with `bdg stop` after operations complete
- **Use jq for JSON processing** instead of string manipulation
- **Check exit codes** (`$?`) for scripting and error handling
- **Enable CDP domains upfront** (Network, Runtime, DOM) for better performance in batch operations
- **Document method discovery** - show how you found the method (`bdg --describe`) before execution

### ❌ NEVER

- Execute CDP commands without verifying session active first
- Hardcode CDP method lists - use self-discovery instead
- Skip error handling - always use `2>&1` pattern
- Leave sessions running - cleanup with `bdg stop` or trap
- Mix binary output with jq parsing (screenshots, PDFs)
- Assume method names - verify with `--describe`
- Use without checking platform compatibility (Windows requires WSL)
- Skip installation verification on first skill usage
- Fabricate method capabilities - discover with `--list` and `--describe`
- Proceed with operations if session in `error` state

### ⚠️ ESCALATE IF

- bdg not installed and user on Windows without WSL (not supported)
- Chrome/Chromium not found and path cannot be determined
- Session fails to start after 3 retry attempts
- CDP method consistently fails with parameter errors (may need user clarification on intent)
- Task requires complex UI testing better suited for Puppeteer/Playwright
- Task requires cross-browser testing (bdg Chrome-only)
- User's task better served by MCP approach (already have MCP infrastructure)
- Browser launch fails due to permissions/sandbox issues (platform-specific)

---

## 6. 🎓 SUCCESS CRITERIA

### Browser Debugging Workflow Completion

**Browser debugging workflow complete when**:
- ✅ bdg installation verified (or installation command provided)
- ✅ Session started successfully (`bdg status` shows `active` state)
- ✅ CDP operations executed successfully (exit code 0, valid JSON output)
- ✅ Required data captured (screenshot, console logs, cookies, HAR, etc.)
- ✅ Session stopped and cleaned up (`bdg stop` executed)
- ✅ Output provided to user (file paths, extracted data, analysis results)
- ✅ Error handling implemented (stderr captured, exit codes checked)
- ✅ Method discovery documented (show how capabilities were found)

---

## 7. 💡 EXAMPLES

### Example 1: Screenshot Capture

**User Request**: "Use browser debugger CLI to capture a screenshot of https://example.com"

**Execution**:
```bash
# Verify installation
command -v bdg || echo "Install: npm install -g browser-debugger-cli@alpha"

# Start session
bdg https://example.com 2>&1

# Wait for page load
sleep 2

# Verify session
bdg status 2>&1 | jq '.state'

# Capture screenshot
bdg screenshot example.png 2>&1

# Stop session
bdg stop 2>&1
```

**Output**:
- Screenshot saved to `example.png`
- Session cleaned up
- File path provided to user

---

### Example 2: Console Log Analysis

**User Request**: "Check the console logs for errors on https://example.com"

**Execution**:
```bash
# Start session
bdg https://example.com 2>&1

# Enable console
bdg cdp Runtime.enable 2>&1

# Get console logs
bdg console logs 2>&1 | jq '.[] | select(.level=="error")' > errors.json

# Count errors
error_count=$(jq '. | length' errors.json)

# Extract messages
jq -r '.[] | "\(.level): \(.text)"' errors.json

# Stop session
bdg stop 2>&1

echo "Found $error_count console errors"
```

**Output**:
- Error count reported
- Error messages extracted and displayed
- Errors saved to `errors.json` for review

---

### Example 3: Network Request Monitoring

**User Request**: "Export network trace for https://example.com and show slow requests"

**Execution**:
```bash
# Start session
bdg https://example.com 2>&1

# Enable network tracking
bdg cdp Network.enable 2>&1

# Wait for page load
sleep 5

# Export HAR
bdg har export network-trace.har 2>&1

# Find slow requests (>1000ms)
jq '.log.entries[] | select(.time > 1000) | {url: .request.url, time, status: .response.status}' network-trace.har

# Stop session
bdg stop 2>&1
```

**Output**:
- HAR file saved to `network-trace.har`
- Slow requests identified and displayed
- URL, timing, and status code for each slow request

---

### Example 4: Cookie Manipulation

**User Request**: "Set an authentication cookie on https://example.com and verify it's set"

**Execution**:
```bash
# Start session
bdg https://example.com 2>&1

# Enable network
bdg cdp Network.enable 2>&1

# Set cookie
bdg cdp Network.setCookie '{
  "name": "auth_token",
  "value": "secret-token-123",
  "domain": "example.com",
  "path": "/",
  "secure": true,
  "httpOnly": true,
  "sameSite": "Strict"
}' 2>&1

# Verify cookie
bdg cdp Network.getCookies '{"urls":["https://example.com"]}' 2>&1 | jq '.result.cookies[] | select(.name=="auth_token")'

# Stop session
bdg stop 2>&1
```

**Output**:
- Cookie set successfully
- Cookie verification displayed showing name, value, domain, secure flags
- Session cleaned up

---

### Example 5: Method Discovery Workflow

**User Request**: "How can I get the page title using bdg?"

**Execution**:
```bash
# Step 1: Search for relevant methods
bdg --search title 2>&1

# Step 2: Explore Runtime domain (JavaScript evaluation)
bdg --describe Runtime 2>&1 | grep -i title

# Step 3: Get method details
bdg --describe Runtime.evaluate 2>&1

# Step 4: Start session and execute
bdg https://example.com 2>&1
bdg cdp Runtime.evaluate '{"expression": "document.title", "returnByValue": true}' 2>&1 | jq -r '.result.result.value'

# Alternative: Use helper
bdg js "document.title" 2>&1 | jq -r '.result.value'

# Stop session
bdg stop 2>&1
```

**Output**:
- Discovery process documented
- Multiple approaches shown (CDP vs helper)
- Page title extracted and displayed

---

## 8. 🔗 INTEGRATION POINTS

### Triggers

**Automatic activation when**:
- User mentions "bdg", "browser-debugger-cli" explicitly
- User requests "lightweight browser debugging" or "quick CDP access"
- User asks for "terminal-based browser automation"
- User wants "screenshot without Puppeteer" or similar lightweight approach
- User asks "how to debug browser from command line"

**Related Skills**:
- `cli-codex` - Similar Bash execution pattern, auxiliary tool integration
- `cli-gemini` - Similar auxiliary CLI tool pattern
- `mcp-code-mode` - Alternative approach for MCP-based browser automation
- `workflows-code` - Integration point for Phase 3 browser testing

### workflows-code Integration

**Phase 3: Browser Testing Enhancement**

When implementing browser-based features using workflows-code skill, cli-chrome-devtools provides lightweight verification:

**Workflow**:
1. Implement feature (Phase 2 code changes)
2. Start local server (Phase 3 verification)
3. **Use bdg for inspection**:
   ```bash
   bdg http://localhost:3000 2>&1
   bdg screenshot verification.png 2>&1
   bdg console logs 2>&1 | grep ERROR
   bdg har export network.har 2>&1
   bdg stop 2>&1
   ```
4. Analyze captured data
5. Iterate on implementation

**Benefits over manual browser testing**:
- Automated screenshot capture
- Console log extraction for error analysis
- Network monitoring without DevTools UI
- Scriptable verification workflows
- CI/CD integration potential

**Example Integration**:
```bash
# After implementing feature, verify with bdg
npm run dev &  # Start dev server
sleep 5        # Wait for server

bdg http://localhost:3000 2>&1
bdg screenshot feature-verification.png 2>&1
bdg console logs 2>&1 > console-output.json
bdg cdp Performance.getMetrics 2>&1 > performance.json
bdg stop 2>&1

# Check for errors
if jq '.[] | select(.level=="error")' console-output.json | grep -q .; then
  echo "❌ Console errors detected - see console-output.json"
  exit 1
fi

echo "✅ Feature verification complete"
```

---

## 9. 🎯 QUICK REFERENCE

### Essential Commands

```bash
# Installation
npm install -g browser-debugger-cli@alpha

# Discovery
bdg --list                    # List all domains
bdg --describe Page           # Domain methods
bdg --search screenshot       # Find methods

# Session
bdg <url>                     # Start session
bdg status                    # Check status
bdg stop                      # Stop session

# Helpers (prefer these)
bdg screenshot <path>         # Capture screenshot
bdg console logs              # Get console logs
bdg network cookies           # Get cookies
bdg dom query "<selector>"    # Query DOM
bdg js "<expression>"         # Execute JS
bdg har export <path>         # Export HAR

# CDP Methods (when helpers insufficient)
bdg cdp <Method> [params]     # Execute CDP method
```

### Error Handling Pattern

```bash
#!/bin/bash
trap "bdg stop 2>&1" EXIT INT TERM

if ! command -v bdg &> /dev/null; then
  echo "Install: npm install -g browser-debugger-cli@alpha"
  exit 1
fi

bdg "$URL" 2>&1 || exit 1

if ! bdg status 2>&1 | jq -e '.state == "active"' > /dev/null; then
  echo "Session failed to start"
  exit 1
fi

# ... operations ...
```

### Common Use Cases

| Task | Command |
|------|---------|
| Screenshot | `bdg screenshot output.png 2>&1` |
| Console errors | `bdg console logs 2>&1 \| jq '.[] \| select(.level=="error")'` |
| Get cookies | `bdg network cookies 2>&1` |
| Set cookie | `bdg cdp Network.setCookie '{...}' 2>&1` |
| DOM query | `bdg dom query ".class" 2>&1` |
| Execute JS | `bdg js "document.title" 2>&1` |
| Export HAR | `bdg har export network.har 2>&1` |
| Page metrics | `bdg cdp Performance.getMetrics 2>&1` |

---

## 10. 📚 BUNDLED RESOURCES

### references/

This skill includes 3 reference files with detailed guidance:

**`cdp_patterns.md`** (~2k words):
- Complete CDP domain patterns (Page, DOM, Network, Runtime, Memory, Performance)
- Workflow examples (screenshot, console logs, network monitoring, cookie manipulation, DOM inspection)
- Unix composability patterns (jq, grep, pipes)
- Discovery pattern examples
- Advanced patterns (multi-session, conditional execution, data pipelines)

**`session_management.md`** (~1k words):
- Session lifecycle and state management
- Start patterns with retry logic and timeout handling
- Multi-session management and concurrent processing
- Session resumption and state persistence
- Error recovery and graceful degradation
- Performance optimization (session pooling, batch operations)

**`troubleshooting.md`** (~1.5k words):
- Installation issues (command not found, npm fails, wrong Node version)
- Browser connection issues (browser not found, launch fails, sandbox errors)
- Session management issues (won't start, stuck in starting, conflicts)
- CDP command errors (method not found, parameter errors, session required)
- Output parsing issues (jq errors, binary data)
- Performance issues (slow execution, high memory)
- Platform-specific solutions (macOS, Linux, Windows/WSL)
- Error code reference and debug mode

Load these references when needed for detailed guidance beyond SKILL.md basics.