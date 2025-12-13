# Code Workflows Quick Reference

One-page cheat sheet for fast navigation and common operations.

---

## 1. 🗺️ NAVIGATION DECISION TREE

```
┌─ Need to write code? ─────────────────────────────────┐
│                                                       │
│  Async/timing issues?  → condition-based-waiting      │
│  Validation needed?    → defense-in-depth             │
│  After JS changes?     → cdn-versioning               │
│  Animation needed?     → animation-workflows           │
│  Webflow collections?  → webflow-patterns               │
│  Performance needed?   → performance-patterns         │
│  Security needed?      → security-patterns            │
│                                                       │
└───────────────────────────────────────────────────────┘

┌─ Need to debug? ──────────────────────────────────────┐
│                                                       │
│  First debugging attempt?     → systematic-debugging  │
│  Deep call stack issue?       → root-cause-tracing    │
│  Animation issues?            → animation-workflows    │
│  Webflow collection issues?   → webflow-patterns        │
│  Performance issues?          → performance-debugging │
│  Error in unknown location?   → systematic-debugging  │
│                                                       │
└───────────────────────────────────────────────────────┘

┌─ Ready to claim complete? ────────────────────────────┐
│                                                       │
│  ALWAYS → verification-before-completion               │
│                                                       │
│  NO EXCEPTIONS. Test in browser first.                 │
│                                                       │
└───────────────────────────────────────────────────────┘
```

---

## 2. 🔧 COMMON COMMANDS

### Condition-Based Waiting

```javascript
// Wait for element
await waitForElement('[selector]', 5000);

// Wait for library
await waitForLibrary('LibraryName', 10000);

// Wait for image
await waitForImageLoad(imgElement);

// Wait for transition
await waitForTransitionEnd(element, 'opacity');

// DOM ready
await domReady();
```

### Validation Patterns

```javascript
// Entry validation
if (!param || typeof param !== 'expected') {
  console.error('[Component] Invalid parameter');
  return null;
}

// Safe nested access
const value = obj?.nested?.property ?? 'default';

// Sanitize text
text.replace(/</g, '&lt;').replace(/>/g, '&gt;');
```

### CDN Versioning

```bash
# NOTE: CDN versioning script location TBD (previously in code-cdn-versioning skill)
# Manual approach: Update version parameters in HTML files that reference modified JS

# Example manual update in HTML:
# <script src="path/to/file.js?v=1.0.0"></script>
# Change to: <script src="path/to/file.js?v=1.0.1"></script>
```

### Performance Patterns

See: [performance_patterns.md](./performance_patterns.md)

```javascript
// ✅ Animate transform/opacity only (Motion.dev)
import { animate } from "motion"
animate('.el', { y: [100, 0], opacity: [0, 1] }, { easing: "ease-out" });

// ✅ Lazy load with IntersectionObserver
const observer = new IntersectionObserver(entries => {
  entries.forEach(entry => {
    if (entry.isIntersecting) {
      entry.target.src = entry.target.dataset.src;
    }
  });
});

// ✅ Debounce user input
const debounce = (func, wait) => {
  let timeout;
  return (...args) => {
    clearTimeout(timeout);
    timeout = setTimeout(() => func(...args), wait);
  };
};
```

### Security Patterns

See: [security_patterns.md](./security_patterns.md)

```javascript
// ✅ Sanitize user input
function sanitizeHTML(str) {
  const div = document.createElement('div');
  div.textContent = str;
  return div.innerHTML;
}

// ✅ Use textContent instead of innerHTML
element.textContent = userInput;

// ✅ Validate input format
const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
if (!emailRegex.test(email)) throw new Error('Invalid email');
```

### Performance Debugging

See: [debugging_workflows.md](./debugging_workflows.md#3-🔍-performance-debugging)

```markdown
Chrome DevTools → Performance tab
1. Record (circle icon)
2. Perform interaction
3. Stop after 3-5 seconds
4. Analyze flame graph (Yellow=JS, Purple=Render, Green=Paint)
5. Bottom-Up view: Find expensive functions
6. Fix bottlenecks (batch DOM reads/writes, optimize algorithms)

Memory leaks:
1. Memory tab → Take snapshot
2. Perform action (e.g., open/close modal 10x)
3. Take second snapshot
4. Comparison view → Sort by Size Delta
5. Look for Detached DOM nodes
```

### DevTools Commands

```javascript
// Find elements
$$('[selector]');

// Get event listeners
getEventListeners(element);

// Monitor events
monitorEvents(element, 'click');

// Copy to clipboard
copy(object);

// Print call stack
console.trace();

// Pause execution
debugger;
```

### Browser Verification (CLI Alternative)

**Automated browser testing via workflows-chrome-devtools skill:**

```bash
# Console error checking
bdg https://anobel.com 2>&1
bdg console logs 2>&1 | jq '.[] | select(.level=="error")'
bdg stop 2>&1

# Multi-viewport screenshots
bdg https://anobel.com 2>&1
bdg screenshot desktop.png 2>&1  # Default: ~1920x1080

# Mobile viewport (requires Emulation.setDeviceMetricsOverride first)
bdg cdp Emulation.setDeviceMetricsOverride '{"width":375,"height":667,"deviceScaleFactor":2,"mobile":true}' 2>&1
bdg screenshot mobile.png 2>&1
bdg stop 2>&1

# DOM inspection
bdg https://anobel.com 2>&1
bdg dom query ".header-nav" 2>&1
bdg js "document.title" 2>&1
bdg stop 2>&1

# Network monitoring
bdg https://anobel.com 2>&1
bdg network cookies 2>&1
bdg har export network-trace.har 2>&1
bdg stop 2>&1

# Performance metrics
bdg https://anobel.com 2>&1
bdg cdp Performance.getMetrics 2>&1
bdg stop 2>&1
```

**Installation:**
```bash
npm install -g browser-debugger-cli@alpha
```

**See:** `.opencode/skills/workflows-chrome-devtools/SKILL.md` for complete CLI workflows

---

## 3. 📋 DEBUGGING CHECKLIST

```markdown
□ PHASE 1: ROOT CAUSE INVESTIGATION
  □ Read error messages completely
  □ Check DevTools Console
  □ Reproduce consistently
  □ Check recent changes (git log)
  □ Gather evidence with logging

□ PHASE 2: PATTERN ANALYSIS
  □ Find working examples
  □ Compare against references
  □ Identify differences
  □ Understand dependencies

□ PHASE 3: HYPOTHESIS & TESTING
  □ Form single hypothesis
  □ Test minimally (one change)
  □ Verify before continuing
  □ Ask if unsure

□ PHASE 4: IMPLEMENTATION
  □ Document the fix
  □ Implement single fix
  □ Verify in browser
  □ If 3+ fixes failed → question approach
```

---

## 4. ✅ VERIFICATION CHECKLIST

```markdown
□ BROWSER TESTING
  □ Chrome (via Chrome DevTools MCP automated testing)
  □ Desktop viewport (1920px)
  □ Mobile emulation (375px)

□ VIEWPORT TESTING
  □ Mobile (375px)
  □ Tablet (768px)
  □ Desktop (1920px)
  □ Transitions smooth

□ FUNCTIONALITY
  □ Clicked interactive elements
  □ Watched full animation
  □ Tested form submissions
  □ Tested media playback

□ CONSOLE/ERRORS
  □ No console errors
  □ No console warnings
  □ No failed network requests
```

---

## 5. ⚡ CODE SNIPPETS

### waitForElement

```javascript
async function waitForElement(selector, timeout = 5000) {
  const start = Date.now();
  while (Date.now() - start < timeout) {
    const el = document.querySelector(selector);
    if (el) return el;
    await new Promise(r => setTimeout(r, 50));
  }
  throw new Error(`Element ${selector} not found`);
}
```

### waitForLibrary

```javascript
async function waitForLibrary(name, timeout = 10000) {
  const start = Date.now();
  while (Date.now() - start < timeout) {
    if (typeof window[name] !== 'undefined') {
      return window[name];
    }
    await new Promise(r => setTimeout(r, 50));
  }
  throw new Error(`Library ${name} not loaded`);
}
```

### Validation Wrapper

```javascript
function validate(value, type, fallback) {
  if (!value || typeof value !== type) {
    console.warn(`Invalid ${type}, using fallback`);
    return fallback;
  }
  return value;
}

// Usage
const userId = validate(input, 'string', 'anonymous');
```

---

## 6. 🔑 KEY PRINCIPLES

**Implementation:**
- Wait for conditions, not timeouts
- Validate at every layer
- Update versions after JS changes

**Debugging:**
- Find root cause before fixing
- Use DevTools extensively
- Document the fix

**Verification:**
- Test in browser BEFORE claiming
- Multiple viewports required
- DevTools console must be clear

---

## 7. 📚 FULL DOCUMENTATION

### References
- `implementation_workflows.md` - Phase 1 workflows
- `animation_workflows.md` - Animation implementation guide
- `webflow_patterns.md` - Webflow platform patterns
- `performance_patterns.md` - Performance optimization
- `security_patterns.md` - OWASP security patterns
- `debugging_workflows.md` - Phase 2 workflows
- `verification_workflows.md` - Phase 3 (MANDATORY)
- `code_quality_standards.md` - Naming, initialization, standards
- `shared_patterns.md` - DevTools, logging, testing
- `devtools_guide.md` - Comprehensive DevTools reference

### Assets
- `wait_patterns.js` - Waiting code templates
- `validation_patterns.js` - Validation templates
- `debugging_checklist.md` - Debugging workflow
- `verification_checklist.md` - Browser testing

### Scripts
- `scripts/update_html_versions.py` - CDN versioning

---

## 8. 🎯 DECISION MATRIX

| Scenario                | Workflow                | Key Action                        |
| ----------------------- | ----------------------- | --------------------------------- |
| Element not ready       | condition-based-waiting | waitForElement                    |
| Form validation         | defense-in-depth        | Multi-layer validation            |
| After JS change         | cdn-versioning          | Run version updater               |
| Animation needed        | animation-workflows     | CSS vs Motion.dev decision tree   |
| Webflow collection list | webflow-patterns        | Event delegation, async rendering |
| Console error           | systematic-debugging    | Phase 1: Investigation            |
| Deep stack error        | root-cause-tracing      | Use debugger, trace back          |
| Ready to claim done     | verification            | Test in browser first             |
| Layout bug              | systematic-debugging    | Inspect element, computed styles  |
| Animation issue         | animation-workflows     | Motion.dev loading, layout jumps  |
| Webflow ID duplication  | webflow-patterns        | Use classes, event delegation     |
| Click not working       | systematic-debugging    | Check event listeners             |

---

**For detailed workflows, see the main SKILL.md orchestrator**