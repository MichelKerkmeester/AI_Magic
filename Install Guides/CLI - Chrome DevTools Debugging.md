# Chrome DevTools CLI (bdg) Installation Guide

A comprehensive guide to installing, configuring, and using browser-debugger-cli (bdg) for terminal-based Chrome DevTools Protocol access.

---

## 🤖 AI-FIRST INSTALL GUIDE

**Copy and paste this prompt to your AI assistant to get installation help:**

```
I want to install the Chrome DevTools CLI (bdg) from https://github.com/cloudy-g/browser-debugger-cli

Please help me:
1. Check if I have Node.js 16+ and Chrome/Chromium installed
2. Install the browser-debugger-cli@alpha package globally via npm
3. Verify the bdg command is available
4. Show me how to use self-documenting features (--list, --describe, --search)
5. Test basic operations: start session, capture screenshot, check console logs
6. Configure my environment for optimal bdg usage (I'm using: [OpenCode CLI / VS Code / Terminal workflows])

Guide me through each step with the exact commands I need to run.
```

**What the AI will do:**
- Verify Node.js 16+ and Chrome browser are installed
- Install bdg CLI tool globally via npm
- Test basic bdg commands (--version, --help)
- Demonstrate self-documenting features for CDP method discovery
- Walk through complete workflow: start session, interact with browser, capture data, stop session
- Show you how to integrate bdg with your AI workflow
- Explain token efficiency benefits vs MCP tools

**Expected setup time:** 3-5 minutes

---

#### 📋 TABLE OF CONTENTS

1. [📖 OVERVIEW](#1--overview)
2. [📋 PREREQUISITES](#2--prerequisites)
3. [📥 INSTALLATION](#3--installation)
4. [⚙️ CONFIGURATION](#4-️-configuration)
5. [✅ VERIFICATION](#5--verification)
6. [🚀 USAGE](#6--usage)
7. [🎯 FEATURES](#7--features)
8. [💡 EXAMPLES](#8--examples)
9. [🔧 TROUBLESHOOTING](#9--troubleshooting)
10. [📚 RESOURCES](#10--resources)

---

## 1. 📖 OVERVIEW

Chrome DevTools CLI (`bdg`) is a lightweight terminal-based tool for direct Chrome DevTools Protocol (CDP) access. It provides 644 CDP methods via command-line interface, enabling browser automation, debugging, and testing without Puppeteer/Playwright overhead.

### Key Features

- **Direct CDP Access**: All 644 Chrome DevTools Protocol methods available
- **Self-Documenting**: Built-in discovery via `--list`, `--describe`, `--search`
- **Session Management**: Persistent browser sessions with state tracking
- **Unix Composability**: Pipes, jq integration, shell scripting-friendly
- **Lightweight**: Minimal dependencies, fast startup
- **Token Efficient**: Lower AI context overhead vs MCP tools
- **No Driver Dependencies**: Uses Chrome's built-in DevTools Protocol

### How It Compares

| Feature | bdg (CLI) | Chrome DevTools MCP | Puppeteer |
|---------|-----------|---------------------|-----------|
| **Setup** | npm install -g | MCP server config | npm + code |
| **Execution** | Direct bash | Via Code Mode | Node.js scripts |
| **Token Cost** | Lowest | Medium | High |
| **Discovery** | --list, --describe | Type definitions | Docs required |
| **Use Case** | Quick tasks, terminal workflows | IDE automation | Complex testing |
| **Learning Curve** | Minimal | Medium | Steep |

### What You Can Do

- **Browser Automation**: Navigate pages, click elements, fill forms
- **Debugging**: Capture console logs, network HAR files, DOM snapshots
- **Testing**: Multi-viewport screenshots, performance metrics (Core Web Vitals)
- **Inspection**: Execute JavaScript, query selectors, monitor network
- **Data Extraction**: Cookies, localStorage, sessionStorage, headers

### What's Protected

bdg provides session isolation:
- Each session has unique browser context
- Sessions persist until explicitly stopped
- Concurrent sessions supported (use different URLs)
- State management via `bdg status` and `bdg stop`

---

## 2. 📋 PREREQUISITES

Before installing Chrome DevTools CLI, ensure you have:

### Required

- **Node.js 16 or higher**
  ```bash
  node --version
  # Should show v16.x or higher
  ```

- **npm** (comes with Node.js)
  ```bash
  npm --version
  # Should show 7.x or higher
  ```

- **Google Chrome or Chromium** installed
  ```bash
  # macOS
  open -a "Google Chrome" --args --version

  # Linux
  google-chrome --version

  # Windows
  "C:\Program Files\Google\Chrome\Application\chrome.exe" --version
  ```

### Optional but Recommended

- **jq** for JSON parsing (enhances bdg output processing)
  ```bash
  # macOS
  brew install jq

  # Linux
  sudo apt-get install jq

  # Verify
  jq --version
  ```

- **Terminal with color support** for better readability
- **Bash 4.0+** for shell scripting integration

---

## 3. 📥 INSTALLATION

### Step 1: Install browser-debugger-cli via npm

```bash
# Install globally using alpha version
npm install -g browser-debugger-cli@alpha

# Expected output:
# + browser-debugger-cli@0.6.10
# added 123 packages in 8.5s
```

**Why @alpha?**
- Current stable version: v0.6.10
- Active development with frequent updates
- Production-ready despite alpha tag

### Step 2: Verify Installation

```bash
# Check bdg command is available
which bdg

# Expected output:
# /usr/local/bin/bdg  (or similar path)
```

```bash
# Check version
bdg --version

# Expected output:
# 0.6.10
```

### Step 3: Test Basic Functionality

```bash
# Show help
bdg --help

# Expected: Usage information and available options
```

### Installation Locations

- **Binary**: `/usr/local/bin/bdg` (or `~/.npm-global/bin/bdg`)
- **Package**: `node_modules/browser-debugger-cli/` (global)
- **Session Data**: Current working directory (`~/.bdg-sessions/` for persistent)

---

## 4. ⚙️ CONFIGURATION

### Option A: Shell Integration (Recommended)

Add bdg autocomplete and aliases to your shell:

**Bash** (`~/.bashrc`):
```bash
# bdg aliases
alias bdg-screenshot='bdg screenshot output.png 2>&1'
alias bdg-console='bdg console logs 2>&1 | jq'
alias bdg-har='bdg har export network.har 2>&1'

# Quick session shortcuts
alias bdg-start='bdg'
alias bdg-stop='bdg stop 2>&1'
```

**Zsh** (`~/.zshrc`):
```zsh
# bdg completions (if available)
compdef _bdg bdg

# bdg aliases
alias bdg-screenshot='bdg screenshot output.png 2>&1'
alias bdg-console='bdg console logs 2>&1 | jq'
alias bdg-har='bdg har export network.har 2>&1'
```

### Option B: Project-Specific Configuration

Create `.bdgrc` in your project root:

```bash
#!/bin/bash
# bdg configuration

# Default URL for quick starts
export BDG_DEFAULT_URL="http://localhost:3000"

# Screenshot defaults
export BDG_SCREENSHOT_WIDTH=1920
export BDG_SCREENSHOT_HEIGHT=1080

# Output directory
export BDG_OUTPUT_DIR="./bdg-output"
mkdir -p "$BDG_OUTPUT_DIR"

# Helper functions
bdg-quick-test() {
  bdg "$BDG_DEFAULT_URL" 2>&1
  bdg screenshot "$BDG_OUTPUT_DIR/test.png" 2>&1
  bdg console logs 2>&1 | jq '.[] | select(.level=="error")'
  bdg stop 2>&1
}
```

Source it:
```bash
source .bdgrc
```

### Option C: Integration with AI Workflows

#### For OpenCode CLI:

Create bash helper in `.claude/scripts/bdg-helpers.sh`:

```bash
#!/bin/bash
# bdg integration for OpenCode workflows

bdg_verify_page() {
  local url="$1"
  echo "🔍 Verifying $url with bdg..."

  bdg "$url" 2>&1
  bdg screenshot verify.png 2>&1
  bdg console logs 2>&1 | jq '.[] | select(.level=="error")' > errors.json
  bdg har export network.har 2>&1
  bdg stop 2>&1

  echo "✅ Verification complete. Check: verify.png, errors.json, network.har"
}

export -f bdg_verify_page
```

#### For VS Code Terminal:

Add to `.vscode/tasks.json`:

```json
{
  "version": "2.0.0",
  "tasks": [
    {
      "label": "bdg: Verify Page",
      "type": "shell",
      "command": "bdg ${input:url} && bdg screenshot output.png && bdg console logs | jq && bdg stop",
      "problemMatcher": []
    }
  ],
  "inputs": [
    {
      "id": "url",
      "type": "promptString",
      "description": "Enter URL to verify"
    }
  ]
}
```

---

## 5. ✅ VERIFICATION

### Check 1: Version and Help

```bash
# Check version
bdg --version

# Expected output: 0.6.10
```

```bash
# Check help
bdg --help

# Expected: Shows usage information
```

### Check 2: Self-Documenting Features

```bash
# List all available CDP domains
bdg --list

# Expected: Shows 53 domains (Page, Network, DOM, Console, etc.)
```

```bash
# Describe a specific domain
bdg --describe Page

# Expected: Shows all Page.* methods with descriptions
```

```bash
# Search for specific functionality
bdg --search screenshot

# Expected: Lists methods related to screenshots
```

### Check 3: Basic Session Test

```bash
# Start session with a test URL
bdg https://example.com 2>&1

# Expected: Session started, browser opens
```

```bash
# Check session status
bdg status 2>&1

# Expected: Shows active session info
```

```bash
# Stop session
bdg stop 2>&1

# Expected: Session stopped successfully
```

### Check 4: Screenshot Test

```bash
# Complete workflow test
bdg https://example.com 2>&1
bdg screenshot test.png 2>&1
bdg stop 2>&1

# Verify screenshot created
ls -lh test.png

# Expected: test.png file exists (typically 50-200KB)
```

---

## 6. 🚀 USAGE

### Basic Usage Pattern

bdg follows a **session-based workflow**:

1. **Start Session**: `bdg <url>` - Opens browser and starts session
2. **Interact**: Use CDP methods (screenshot, console, network, etc.)
3. **Stop Session**: `bdg stop` - Closes browser and cleans up

### Session Management

```bash
# Start session
bdg https://anobel.com 2>&1

# Check session status
bdg status 2>&1

# Stop session (always do this when done)
bdg stop 2>&1
```

### Direct CDP Method Invocation

```bash
# Method format: Domain.method
bdg Page.captureScreenshot 2>&1

# With parameters (JSON format)
bdg Page.navigate --url "https://example.com" 2>&1
```

### Unix Composability

bdg outputs JSON, making it pipe-friendly:

```bash
# Extract specific data with jq
bdg console logs 2>&1 | jq '.[] | select(.level=="error")'

# Count network requests
bdg network requests 2>&1 | jq 'length'

# Filter DOM elements
bdg dom query "a" 2>&1 | jq '.[].href'
```

### Common Workflows

**1. Console Error Checking**:
```bash
bdg https://anobel.com 2>&1
bdg console logs 2>&1 | jq '.[] | select(.level=="error")' > errors.json
bdg stop 2>&1
cat errors.json
```

**2. Multi-Viewport Screenshots**:
```bash
bdg https://anobel.com 2>&1
bdg screenshot desktop.png --width 1920 --height 1080 2>&1
bdg screenshot mobile.png --width 375 --height 667 2>&1
bdg stop 2>&1
```

**3. Network Analysis**:
```bash
bdg https://anobel.com 2>&1
bdg har export network.har 2>&1
bdg stop 2>&1
# Analyze HAR file with external tools
```

---

## 7. 🎯 FEATURES

### 7.1 Self-Documenting Discovery

**Purpose**: Find CDP methods without external documentation

**Commands**:
- `bdg --list` - List all 53 CDP domains
- `bdg --describe <domain>` - Show methods for specific domain
- `bdg --search <keyword>` - Search methods by keyword

**Example**:
```bash
# Find screenshot methods
bdg --search screenshot

# Output:
# Page.captureScreenshot
# Page.captureScreenshotToBase64
# Emulation.setDeviceMetricsOverride (for viewport)
```

### 7.2 Session Management

**Purpose**: Persistent browser state across multiple commands

**Commands**:
- `bdg <url>` - Start new session with URL
- `bdg status` - Check current session status
- `bdg stop` - Stop active session

**Session Data**:
- Browser context (cookies, localStorage, sessionStorage)
- Navigation history
- Network cache
- DOM state

### 7.3 Page Interaction

**Key Methods**:
- `Page.navigate` - Navigate to URL
- `Page.reload` - Refresh page
- `Page.captureScreenshot` - Screenshot (PNG, JPEG, WebP)
- `Page.printToPDF` - Generate PDF
- `Input.dispatchMouseEvent` - Mouse clicks
- `Input.dispatchKeyEvent` - Keyboard input

**Example**:
```bash
bdg https://example.com 2>&1
bdg Page.navigate --url "https://anobel.com" 2>&1
bdg screenshot homepage.png 2>&1
bdg stop 2>&1
```

### 7.4 Console Monitoring

**Key Methods**:
- `Runtime.enable` - Enable console tracking
- `Runtime.consoleAPICalled` - Capture console.log/error/warn
- `Runtime.evaluate` - Execute JavaScript

**Example**:
```bash
bdg https://anobel.com 2>&1
bdg console logs 2>&1 | jq '.[] | {level, message}'
bdg stop 2>&1
```

### 7.5 Network Inspection

**Key Methods**:
- `Network.enable` - Enable network tracking
- `Network.getResponseBody` - Get response content
- `Network.emulateNetworkConditions` - Throttle network
- HAR export (full network waterfall)

**Example**:
```bash
bdg https://anobel.com 2>&1
bdg network requests 2>&1 | jq '.[] | select(.status >= 400)'
bdg har export failed-requests.har 2>&1
bdg stop 2>&1
```

### 7.6 DOM Querying

**Key Methods**:
- `DOM.getDocument` - Get DOM tree
- `DOM.querySelector` - Find elements
- `DOM.getAttributes` - Extract attributes

**Example**:
```bash
bdg https://anobel.com 2>&1
bdg dom query "meta[property='og:title']" 2>&1 | jq '.[].content'
bdg stop 2>&1
```

### 7.7 Performance Measurement

**Key Methods**:
- `Performance.enable` - Enable metrics
- `Performance.getMetrics` - Core Web Vitals
- Tracing for timeline analysis

**Example**:
```bash
bdg https://anobel.com 2>&1
bdg performance metrics 2>&1 | jq '.[] | select(.name | contains("Layout"))'
bdg stop 2>&1
```

---

## 8. 💡 EXAMPLES

### Example 1: Visual Regression Testing

**Scenario**: Capture screenshots at multiple viewports for comparison

```bash
#!/bin/bash
# visual-regression.sh

URLS=("https://anobel.com/en" "https://anobel.com/nl")
VIEWPORTS=("1920x1080" "375x667" "768x1024")

for url in "${URLS[@]}"; do
  page=$(echo "$url" | sed 's|https://||' | sed 's|/|-|g')

  bdg "$url" 2>&1

  for viewport in "${VIEWPORTS[@]}"; do
    width=$(echo "$viewport" | cut -d'x' -f1)
    height=$(echo "$viewport" | cut -d'x' -f2)

    bdg screenshot "${page}-${viewport}.png" --width "$width" --height "$height" 2>&1
  done

  bdg stop 2>&1
done

echo "✅ Captured $(ls *.png | wc -l) screenshots"
```

**Result**: 6 screenshots (2 URLs × 3 viewports)

### Example 2: Console Error Monitoring

**Scenario**: Monitor production site for JavaScript errors

```bash
#!/bin/bash
# error-monitor.sh

URL="https://anobel.com"
OUTPUT_DIR="./error-logs"
TIMESTAMP=$(date +%Y%m%d-%H%M%S)

mkdir -p "$OUTPUT_DIR"

echo "🔍 Monitoring $URL for errors..."

bdg "$URL" 2>&1

# Capture console logs
bdg console logs 2>&1 | jq '.[] | select(.level=="error")' > "$OUTPUT_DIR/errors-$TIMESTAMP.json"

# Check if errors exist
error_count=$(jq 'length' "$OUTPUT_DIR/errors-$TIMESTAMP.json")

if [ "$error_count" -gt 0 ]; then
  echo "⚠️  Found $error_count console errors"
  jq '.[].message' "$OUTPUT_DIR/errors-$TIMESTAMP.json"
else
  echo "✅ No console errors found"
fi

bdg stop 2>&1
```

**Output**:
```json
{
  "level": "error",
  "message": "Uncaught TypeError: Cannot read property 'foo' of undefined",
  "url": "https://anobel.com/app.js",
  "lineNumber": 42
}
```

### Example 3: Performance Audit

**Scenario**: Measure page load performance metrics

```bash
#!/bin/bash
# performance-audit.sh

URL="https://anobel.com"
RUNS=3
METRICS_FILE="performance-metrics.json"

echo "🚀 Running $RUNS performance audits for $URL..."

echo "[" > "$METRICS_FILE"

for i in $(seq 1 $RUNS); do
  echo "  Run $i/$RUNS..."

  bdg "$URL" 2>&1 > /dev/null
  bdg performance trace start 2>&1
  sleep 5  # Wait for page to fully load
  bdg performance trace stop 2>&1 > "trace-run-$i.json"
  bdg stop 2>&1

  # Extract key metrics
  jq '{
    run: '$i',
    firstContentfulPaint: .metrics.FirstContentfulPaint,
    largestContentfulPaint: .metrics.LargestContentfulPaint,
    totalBlockingTime: .metrics.TotalBlockingTime,
    cumulativeLayoutShift: .metrics.CumulativeLayoutShift
  }' "trace-run-$i.json" >> "$METRICS_FILE"

  [ "$i" -lt "$RUNS" ] && echo "," >> "$METRICS_FILE"
done

echo "]" >> "$METRICS_FILE"

# Calculate averages
jq '[.[] | {
  avgFCP: ([.[].firstContentfulPaint] | add / length),
  avgLCP: ([.[].largestContentfulPaint] | add / length),
  avgTBT: ([.[].totalBlockingTime] | add / length),
  avgCLS: ([.[].cumulativeLayoutShift] | add / length)
}]' "$METRICS_FILE"
```

### Example 4: Form Automation

**Scenario**: Fill and submit form programmatically

```bash
#!/bin/bash
# form-automation.sh

URL="https://example.com/contact"

echo "📝 Automating form submission..."

bdg "$URL" 2>&1

# Fill form fields
bdg dom fill "#name" "John Doe" 2>&1
bdg dom fill "#email" "john@example.com" 2>&1
bdg dom fill "#message" "Test message from bdg" 2>&1

# Submit form
bdg dom click "#submit-button" 2>&1

# Wait for response
sleep 2

# Check for success message
bdg dom query ".success-message" 2>&1 | jq '.[].textContent'

bdg stop 2>&1
```

### Example 5: Network HAR Export for Analysis

**Scenario**: Capture complete network waterfall for performance debugging

```bash
#!/bin/bash
# network-analysis.sh

URL="https://anobel.com"
HAR_FILE="network-waterfall.har"

echo "📡 Capturing network traffic for $URL..."

bdg "$URL" 2>&1

# Export HAR file
bdg har export "$HAR_FILE" 2>&1

bdg stop 2>&1

# Analyze with jq
echo "📊 Network Analysis:"
echo "  Total Requests: $(jq '.log.entries | length' "$HAR_FILE")"
echo "  Failed Requests: $(jq '[.log.entries[] | select(.response.status >= 400)] | length' "$HAR_FILE")"
echo "  Total Transfer Size: $(jq '[.log.entries[].response.bodySize] | add' "$HAR_FILE") bytes"
echo "  Slowest Request: $(jq '[.log.entries[] | {url: .request.url, time: .time}] | sort_by(.time) | reverse | .[0]' "$HAR_FILE")"
```

---

## 9. 🔧 TROUBLESHOOTING

### bdg Command Not Found

**Problem**: `bash: bdg: command not found`

**Solutions**:
1. Verify global installation
   ```bash
   npm list -g | grep browser-debugger-cli
   ```

2. Check npm global bin path
   ```bash
   npm config get prefix
   # Add to PATH if needed:
   export PATH="$PATH:$(npm config get prefix)/bin"
   ```

3. Reinstall globally
   ```bash
   npm uninstall -g browser-debugger-cli
   npm install -g browser-debugger-cli@alpha
   ```

4. Use npx as alternative
   ```bash
   npx browser-debugger-cli --version
   ```

### Chrome Not Found

**Problem**: `Error: Could not find Chrome executable`

**Solutions**:
1. Specify Chrome path explicitly
   ```bash
   export CHROME_PATH="/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"
   bdg https://example.com 2>&1
   ```

2. Install Chrome/Chromium
   ```bash
   # macOS
   brew install --cask google-chrome

   # Linux
   sudo apt-get install google-chrome-stable

   # Windows
   # Download from https://www.google.com/chrome/
   ```

3. Use Chromium instead
   ```bash
   export CHROME_PATH="/usr/bin/chromium-browser"
   ```

### Session Already Active

**Problem**: `Error: Session already active on this URL`

**Solutions**:
1. Stop existing session
   ```bash
   bdg stop 2>&1
   ```

2. Check session status
   ```bash
   bdg status 2>&1
   ```

3. Kill orphaned processes
   ```bash
   ps aux | grep chrome
   kill <PID>
   ```

4. Clear session data
   ```bash
   rm -rf ~/.bdg-sessions/*
   ```

### Screenshot Empty/Black

**Problem**: Screenshot files are blank or all black

**Solutions**:
1. Add wait time before screenshot
   ```bash
   bdg https://example.com 2>&1
   sleep 3  # Wait for page load
   bdg screenshot output.png 2>&1
   bdg stop 2>&1
   ```

2. Check page loaded
   ```bash
   bdg dom query "body" 2>&1 | jq '.[].childElementCount'
   ```

3. Disable headless mode (for debugging)
   ```bash
   export BDG_HEADLESS=false
   bdg https://example.com 2>&1
   ```

### JSON Parsing Errors

**Problem**: `jq: parse error: Invalid numeric literal`

**Solutions**:
1. Ensure bdg outputs JSON
   ```bash
   bdg console logs 2>&1 | python3 -m json.tool
   ```

2. Check stderr vs stdout
   ```bash
   bdg console logs 2>&1 | tee output.txt
   ```

3. Filter non-JSON lines
   ```bash
   bdg console logs 2>&1 | grep -E '^\[|^\{'
   ```

### Permission Denied Errors

**Problem**: `EACCES: permission denied`

**Solutions**:
1. Fix npm permissions
   ```bash
   mkdir ~/.npm-global
   npm config set prefix '~/.npm-global'
   echo 'export PATH=~/.npm-global/bin:$PATH' >> ~/.bashrc
   source ~/.bashrc
   ```

2. Reinstall without sudo
   ```bash
   npm install -g browser-debugger-cli@alpha
   ```

---

## 10. 📚 RESOURCES

### Documentation

- **GitHub Repository**: https://github.com/cloudy-g/browser-debugger-cli
- **npm Package**: https://www.npmjs.com/package/browser-debugger-cli
- **Chrome DevTools Protocol**: https://chromedevtools.github.io/devtools-protocol/

### CLI Skill Reference

- **cli-chrome-devtools Skill**: `.claude/skills/cli-chrome-devtools/SKILL.md`
- **CDP Patterns**: `.claude/skills/cli-chrome-devtools/references/cdp_patterns.md`
- **Session Management**: `.claude/skills/cli-chrome-devtools/references/session_management.md`
- **Troubleshooting**: `.claude/skills/cli-chrome-devtools/references/troubleshooting.md`

### Helper Commands

```bash
# View available methods
bdg --list | less

# Search for specific functionality
bdg --search "network"
bdg --search "screenshot"
bdg --search "cookie"

# Get method details
bdg --describe Page
bdg --describe Network
bdg --describe Console

# Check current session
bdg status 2>&1 | jq

# View all sessions
ls -la ~/.bdg-sessions/

# Clean up sessions
bdg stop 2>&1
rm -rf ~/.bdg-sessions/*
```

### Integration Patterns

#### With Git Workflow
```bash
# Pre-commit hook: Check for console errors
#!/bin/bash
npm start &  # Start dev server
sleep 5
bdg http://localhost:3000 2>&1
errors=$(bdg console logs 2>&1 | jq '.[] | select(.level=="error")' | jq -s 'length')
bdg stop 2>&1
if [ "$errors" -gt 0 ]; then
  echo "❌ Found $errors console errors"
  exit 1
fi
```

#### With CI/CD
```yaml
# .github/workflows/visual-regression.yml
- name: Run Visual Regression
  run: |
    npm install -g browser-debugger-cli@alpha
    npm start &
    sleep 10
    bdg http://localhost:3000 2>&1
    bdg screenshot baseline.png 2>&1
    bdg stop 2>&1
```

#### With Monitoring
```bash
# Cron job: Hourly error monitoring
0 * * * * /usr/local/bin/bdg https://anobel.com && /usr/local/bin/bdg console logs | jq '.[] | select(.level=="error")' >> /var/log/console-errors.log && /usr/local/bin/bdg stop
```

### Performance Considerations

| Task | bdg (CLI) | Chrome DevTools MCP | Recommendation |
|------|-----------|---------------------|----------------|
| **Quick screenshot** | <2s | ~5s | Use bdg |
| **Console monitoring** | <1s | ~3s | Use bdg |
| **Multi-viewport testing** | <5s | ~15s | Use bdg |
| **Complex automation** | Medium | High | Depends on workflow |
| **Token cost (AI)** | Low (10-50 tokens) | Medium (100-300 tokens) | bdg 70% cheaper |

### Project Structure

```
browser-debugger-cli/
├── bin/
│   └── bdg                    # Main CLI executable
├── lib/
│   ├── session.js            # Session management
│   ├── cdp.js                # CDP protocol handler
│   ├── discovery.js          # Self-documenting features
│   └── utils.js              # Helper functions
├── package.json
└── README.md
```

---

## Quick Reference

### Essential Commands

```bash
# Install
npm install -g browser-debugger-cli@alpha

# Verify
bdg --version
bdg --help

# Discovery
bdg --list              # List all CDP domains
bdg --describe Page     # Show Page.* methods
bdg --search screenshot # Find screenshot methods

# Basic workflow
bdg https://example.com 2>&1
bdg screenshot output.png 2>&1
bdg console logs 2>&1 | jq
bdg stop 2>&1
```

### Common Usage Patterns

**Console Error Checking**:
```bash
bdg https://anobel.com 2>&1
bdg console logs 2>&1 | jq '.[] | select(.level=="error")'
bdg stop 2>&1
```

**Multi-Viewport Screenshots**:
```bash
bdg https://anobel.com 2>&1
bdg screenshot desktop.png --width 1920 --height 1080 2>&1
bdg screenshot mobile.png --width 375 --height 667 2>&1
bdg stop 2>&1
```

**Network Analysis**:
```bash
bdg https://anobel.com 2>&1
bdg har export network.har 2>&1
bdg stop 2>&1
jq '.log.entries[] | select(.response.status >= 400)' network.har
```

**Performance Metrics**:
```bash
bdg https://anobel.com 2>&1
bdg performance metrics 2>&1 | jq '.[] | select(.name | contains("Paint"))'
bdg stop 2>&1
```

### Configuration Quick Edit

```bash
# Add to ~/.bashrc or ~/.zshrc
export BDG_DEFAULT_URL="http://localhost:3000"
export CHROME_PATH="/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"

alias bdg-test='bdg "$BDG_DEFAULT_URL" && bdg screenshot test.png && bdg console logs | jq && bdg stop'
```

---

**Installation Complete!**

You now have Chrome DevTools CLI (bdg) installed and configured. Use it for lightweight browser automation, terminal-based debugging, and token-efficient browser verification in your AI workflows.

Start exploring CDP methods with `bdg --list` and discover 644 ways to interact with Chrome programmatically from your terminal!

For integration with AI workflows, see the cli-chrome-devtools skill documentation in `.claude/skills/cli-chrome-devtools/`.
