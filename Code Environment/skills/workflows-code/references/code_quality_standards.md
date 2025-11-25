# Code Quality Standards - Integrated Reference

Essential code quality standards for frontend development, integrating naming conventions, animation patterns, and initialization structure.

### Core Principle

Consistency enables collaboration. Clarity prevents bugs.

**Primary Sources:**
- [code_standards.md](../../../knowledge/code_standards.md) - Complete naming and commenting rules
- [initialization_pattern.md](../../../knowledge/initialization_pattern.md) - Complete CDN-safe pattern documentation
- [animation_workflows.md](./animation_workflows.md) - Complete animation implementation guide

---

## 1. 📝 NAMING CONVENTIONS

### JavaScript Identifiers (snake_case)

All JavaScript code uses `snake_case` for consistency:

| Type | Convention | Example |
|------|------------|---------|
| Variables | `snake_case` | `user_data`, `is_valid` |
| Functions | `snake_case` | `handle_submit()`, `init_component()` |
| Constants | `UPPER_SNAKE_CASE` | `MAX_RETRIES`, `INIT_DELAY_MS` |
| Private | `_snake_case` | `_internal_cache` |

### Semantic Function Prefixes

Use standard prefixes to indicate purpose:

| Prefix | Purpose | Returns |
|--------|---------|---------|
| `is_` | Boolean check | true/false |
| `has_` | Presence check | true/false |
| `get_` | Data retrieval | data (no mutation) |
| `set_` | Data mutation | void/success |
| `handle_` | Event handler | void |
| `init_` | Initialization | void |
| `load_` | Resource loading | Promise |

**Examples:**
```javascript
function is_valid_email(email) { }
function has_required_fields(form) { }
function get_form_data(form) { }
function set_loading_state(enabled) { }
function handle_submit(event) { }
function init_validation() { }
function load_external_library() { }
```

### CSS Naming (kebab-case with BEM)

```css
.hero { }                    /* Block */
.hero--title { }             /* Element */
.hero--overlay { }           /* Element */
.hero-featured { }           /* Modifier */
```

**See:** [code_standards.md Section 1](../../../knowledge/code_standards.md#1--naming-conventions-by-language-and-type) for complete naming rules.

---

## 2. 📁 FILE STRUCTURE REQUIREMENTS

### JavaScript File Header (MANDATORY)

**Standard pattern:** See [code_standards.md Section 2](../../../knowledge/code_standards.md#2-️-file-and-section-headers) for complete file header requirements.

**Quick reference:**
```javascript
// ───────────────────────────────────────────────────────────────
// COMPONENT: [NAME]
// ───────────────────────────────────────────────────────────────
```

**Rules:**
- Three-line separator format
- `COMPONENT: [NAME]` in uppercase
- No metadata (dates, authors, tickets)

### Section Headers (Numbered)

Organize code blocks with numbered sections:

```javascript
/* ─────────────────────────────────────────────────────────────
   1. CONFIGURATION
──────────────────────────────────────────────────────────────── */

/* ─────────────────────────────────────────────────────────────
   2. EVENT HANDLERS
──────────────────────────────────────────────────────────────── */

/* ─────────────────────────────────────────────────────────────
   3. INITIALIZE
──────────────────────────────────────────────────────────────── */
```

**See:** [code_standards.md Section 2](../../../knowledge/code_standards.md#2-️-file-and-section-headers) for complete header rules.

---

## 3. 🔧 INITIALIZATION PATTERN (CDN-SAFE)

### The Standard Pattern (COPY EXACTLY)

**Every component MUST use this pattern:**

```javascript
/* ─────────────────────────────────────────────────────────────
   INITIALIZE
──────────────────────────────────────────────────────────────── */
const INIT_FLAG = '__componentNameCdnInit';  // Unique per component
const INIT_DELAY_MS = 50;                     // Adjust per component

function init_component() {
  // Your initialization code here
}

const start = () => {
  // Guard: Prevent double initialization
  if (window[INIT_FLAG]) return;
  window[INIT_FLAG] = true;

  // If DOM already loaded, delay before initializing
  if (document.readyState !== 'loading') {
    setTimeout(init_component, INIT_DELAY_MS);
    return;
  }

  // Otherwise, wait for DOMContentLoaded with delay
  document.addEventListener(
    'DOMContentLoaded',
    () => setTimeout(init_component, INIT_DELAY_MS),
    { once: true }
  );
};

// Prefer Webflow.push, fallback to immediate start
if (window.Webflow?.push) {
  window.Webflow.push(start);
} else {
  start();
}
```

### Why This Pattern Exists

| Requirement | Implementation | Why Needed |
|------------|----------------|------------|
| **Guard Flag** | `if (window[INIT_FLAG]) return;` | Prevents double initialization during Webflow page transitions |
| **Delayed Execution** | `setTimeout(init_component, INIT_DELAY_MS)` | Ensures DOM and dependencies (Motion.dev) fully ready |
| **Webflow.push Support** | `window.Webflow.push(start)` | Integrates with Webflow's native queueing system |
| **Once-Only Listener** | `{ once: true }` | Prevents memory leaks from duplicate listeners |

### When to Adjust INIT_DELAY_MS

| Delay | When to Use | Example |
|-------|-------------|---------|
| **0ms** | No dependencies, simple DOM queries | Copyright year updater |
| **50ms** (default) | Standard components | Forms, accordions, navigation |
| **100ms+** | Heavy dependencies | Hero animations (Motion.dev), video players |

**See:** [initialization_pattern.md](../../../knowledge/initialization_pattern.md) for complete pattern documentation and troubleshooting.

---

## 4. 🎬 ANIMATION STRATEGY

### Quick Decision Tree

```
Need animation?
├─> Can CSS express it (transform/opacity)?
│   └─> Use CSS transitions/keyframes
└─> Requires sequencing/scroll/in-view logic?
    └─> Use Motion.dev
```

### Essential Patterns

**CSS animations (first choice):**
- Use GPU-accelerated properties only (transform, opacity)
- Add `prefers-reduced-motion` support (MANDATORY)
- Timing: 200-400ms for most interactions

**Motion.dev (for complexity):**
- Library loading: Global ES module import in global.html
- Retry pattern: Check `window.Motion` with setTimeout fallback
- Standardized easing: `[0.22, 1, 0.36, 1]` (ease-out), `[0.16, 1, 0.3, 1]` (expo-out)
- Performance: Remove `will-change` in `onComplete`

### Complete Animation Guide

**For implementation, debugging, and testing:**
- **Decision tree and patterns:** [animation_workflows.md](./animation_workflows.md)
- **Complete reference:** [animation_workflows.md](./animation_workflows.md) contains all animation policy, rationale, and implementation details

---

## 5. 💬 COMMENTING RULES

### Principles

**Quantity limit:** Maximum 5 comments per 10 lines of code

**Focus on WHY, not WHAT:**
- ✅ Explain intent, constraints, platform requirements
- ✅ Reference external dependencies (Webflow, libraries)
- ❌ Avoid narrating implementation details

### Function Purpose Comments

Single line above function describing intent:

```javascript
// Load Botpoison SDK from CDN if not already loaded
// Returns promise resolving to true on success, false on failure
function load_botpoison_sdk() {}

// Show modal with entrance animation using Motion.dev
// Make container visible before animating to avoid layout jumps
async function show_modal() {}
```

### Inline Logic Comments (WHY, Not WHAT)

**Good examples (explain reasoning):**
```javascript
// Prevent background scroll while modal is open
if (window.lenis) {
  window.lenis.stop();
}

// Add 10 second timeout to prevent infinite hang
const timeout = new Promise((_, reject) =>
  setTimeout(() => reject(new Error('Timeout')), 10000)
);

// Use modern Array.from or fallback to slice
return Array.from ? Array.from(list) : Array.prototype.slice.call(list);
```

**Bad examples (narrate implementation):**
```javascript
// ❌ Set price to price times 100
const price_cents = price * 100;

// ❌ Loop through items
for (const item of items) {}
```

### Platform-Specific Comments

Reference external constraints:

```javascript
// WEBFLOW: collection list constraint (max 100 items)
// MOTION: Animation requires Motion.dev library loaded
// LENIS: Smooth scroll integration point

// Conditional logging for debug mode
function log(...args) {
  if (debug_enabled) {
    console.log(LOG_PREFIX, ...args);
  }
}
```

**See:** [code_standards.md Section 3](../../../knowledge/code_standards.md#3--commenting-rules) for complete commenting guide.

---

## 6. 🔗 INTEGRATION WITH WORKFLOWS-CODE

### Phase 1: Implementation

When implementing code:
1. **Start with naming** - Use semantic function prefixes (is_, has_, get_, set_, handle_, init_)
2. **Add file header** - Component header at top of file
3. **Use initialization pattern** - Copy standard CDN-safe pattern
4. **Choose animation approach** - CSS first, Motion.dev for complexity
5. **Add WHY comments** - Explain intent, not implementation

### Phase 2: Debugging

When debugging:
1. **Check naming consistency** - Verify snake_case throughout
2. **Verify initialization** - Ensure guard flag and delay present
3. **Review comments** - Check for platform-specific notes (WEBFLOW, MOTION)
4. **Test animations** - Verify prefers-reduced-motion respected

### Phase 3: Verification

When verifying:
1. **Code standards check** - File headers, naming, comments
2. **Pattern compliance** - Initialization pattern used correctly
3. **Animation testing** - CSS/Motion.dev working across viewports
4. **Accessibility** - Reduced motion support verified

---

## 7. ✅ QUICK REFERENCE CHECKLIST

Before deploying any component:

**Naming:**
- [ ] All variables/functions use `snake_case`
- [ ] Constants use `UPPER_SNAKE_CASE`
- [ ] Semantic prefixes used (is_, has_, get_, etc.)

**File Structure:**
- [ ] Component header at top of file
- [ ] Numbered section headers for organization
- [ ] No metadata in headers (no dates/authors/tickets)

**Initialization:**
- [ ] Wrapped in IIFE `(() => { ... })()`
- [ ] Unique `INIT_FLAG` constant
- [ ] `INIT_DELAY_MS` constant (50ms default)
- [ ] Guard check and set present
- [ ] DOM readiness with setTimeout
- [ ] `{ once: true }` on event listener
- [ ] Webflow.push with fallback

**Animation:**
- [ ] CSS used for simple transitions
- [ ] Motion.dev for complex sequences
- [ ] Retry logic for Motion.dev loading
- [ ] `prefers-reduced-motion` support
- [ ] `will-change` cleanup on completion

**Comments:**
- [ ] Maximum 5 comments per 10 lines
- [ ] Focus on WHY, not WHAT
- [ ] Platform constraints documented
- [ ] No commented-out code

---

**Core principle:** These standards ensure maintainable, performant, accessible frontend code that integrates seamlessly with Webflow's CDN delivery and lifecycle.
