# Animation Workflows - Phase 1 Implementation

Complete animation implementation guide following CSS-first approach, with Motion.dev for complex sequences. Includes decision tree, implementation patterns, performance optimization, testing procedures, and policy.

### Core Principle

CSS first for simplicity and performance. Motion.dev when you need programmatic control.

**Prerequisites:** Follow code quality standards:
- **Initialization:** Use CDN-safe pattern with guard flags and delays
- **Naming:** Use `snake_case` for functions/variables
- See [code_quality_standards.md](./code_quality_standards.md) for complete standards

---

## 1. 🎯 ANIMATION DECISION TREE

### Primary Decision Order

Use this sequence when implementing animations:

1. **CSS transitions/keyframes** - First choice for hover, focus, small reveals, and state changes
2. **Motion.dev** - Use when you need programmatic control, in-view triggers, or coordinated sequences

### Quick Decision Flow

```
Need animation?
├─> Can CSS express it (transform/opacity/clip/mask)?
│   └─> Use CSS transitions or @keyframes
└─> Requires sequencing/stagger/scroll/in-view logic?
    └─> Use Motion.dev
```

**When CSS is sufficient:**
- Hover/focus states
- Simple state transitions (open/close, show/hide)
- Single-property animations
- Looping animations without timing dependencies

**When Motion.dev is required:**
- Scroll-triggered animations
- In-view entrance sequences
- Staggered animations (multiple elements with delays)
- Coordinated multi-step sequences
- Programmatic timing control

---

## 2. 🎨 CSS ANIMATION PATTERNS

### GPU-Accelerated Properties Only

**Use these properties for smooth 60fps animations:**

```css
.element {
  /* ✅ GPU-accelerated - USE THESE */
  transform: translate(0, 0);  /* Position changes */
  opacity: 1;                  /* Fade effects */
  scale: 1;                    /* Size changes */
  rotate: 0deg;                /* Rotation */

  /* ❌ Layout properties - AVOID THESE */
  width: 200px;    /* Causes layout recalculation */
  height: 100px;   /* Causes layout recalculation */
  top: 0;          /* Causes layout recalculation */
  left: 0;         /* Causes layout recalculation */
}
```

### Timing Guidance

**Recommended durations by interaction type:**

| Interaction Type | Duration | Easing | Example |
|-----------------|----------|--------|---------|
| **Micro-interactions** | 150-250ms | ease-out | Button hover, icon changes |
| **Standard transitions** | 200-400ms | ease-out | Dropdowns, modals, cards |
| **Entrance animations** | 400-600ms | custom cubic-bezier | Hero elements, sections |
| **Exit animations** | 200-300ms | ease-in | Modal close, element removal |

**Standard easing curves:**
```css
.element {
  /* General purpose */
  transition: transform 0.3s cubic-bezier(0.22, 1, 0.36, 1);

  /* Snappy interactions */
  transition: opacity 0.2s ease-out;

  /* Continuous motion */
  transition: transform 0.5s linear;
}
```

### Accessibility Compliance (MANDATORY)

**Every animated element MUST respect prefers-reduced-motion:**

```css
/* Your animation */
.animated-element {
  transition: transform 0.3s ease-out, opacity 0.2s ease-out;
}

/* Disable for users who prefer reduced motion */
@media (prefers-reduced-motion: reduce) {
  .animated-element {
    animation-duration: 0.01ms !important;
    transition-duration: 0.01ms !important;
  }
}
```

**Why 0.01ms instead of 0ms:** Setting to 0ms can prevent transition/animation events from firing. 0.01ms applies end state while preserving event handling.

### Dropdown Pattern (No Layout Jump)

**Problem:** Height transitions from `0` to `auto` cause layout jumps because CSS cannot transition to/from `auto`.

**Solution:** Measure natural height, transition to pixel value, then set auto after transition completes:

```css
.dropdown {
  overflow: hidden;
  height: 0;
  opacity: 0;
  transition:
    height 0.3s cubic-bezier(0.22, 1, 0.36, 1),
    opacity 0.2s cubic-bezier(0.22, 1, 0.36, 1);
}

.dropdown[open] {
  /* Will be set to pixel value by JavaScript, then auto */
  height: auto;
  opacity: 1;
}
```

```javascript
// Measure and apply natural height
function open_dropdown(dropdown) {
  const naturalHeight = dropdown.scrollHeight;
  dropdown.setAttribute('open', '');
  dropdown.style.height = `${naturalHeight}px`;

  // After transition completes, remove fixed height
  dropdown.addEventListener('transitionend', () => {
    dropdown.style.height = 'auto';
  }, { once: true });
}

// Close: Set to pixel value first, then animate to 0
function close_dropdown(dropdown) {
  const currentHeight = dropdown.scrollHeight;
  dropdown.style.height = `${currentHeight}px`;

  // Force reflow so browser registers the pixel value
  dropdown.offsetHeight;

  // Now animate to 0
  dropdown.style.height = '0';
  dropdown.removeAttribute('open');
}
```

**Reference implementation:** `src/2_javascript/navigation/language_selector.js` - Complete dropdown with measured height animation

---

## 3. ⚡ MOTION.DEV INTEGRATION

### Library Loading (Global Setup)

**Load Motion.dev once as ES module in global.html:**

```html
<!-- src/0_html/global.html -->
<script type="module">
  const lib = await import('https://cdn.jsdelivr.net/npm/motion@12.15.0/+esm');
  window.Motion = lib; // { animate, inView, scroll, stagger, ... }
</script>
```

**Why this approach:**
- Single CDN request for all components
- Global availability prevents import duplication
- Version-locked for stability (`@12.15.0`)
- All Motion.dev functions available via `window.Motion`

### Component Initialization Pattern with Retry Logic

**Standard pattern for components using Motion.dev:**

```javascript
(() => {
  const INIT_FLAG = '__animationComponentCdnInit';
  const INIT_DELAY_MS = 100;  // Higher delay for Motion.dev dependency

  function init_animation() {
    const { animate, inView } = window.Motion || {};

    // Retry if Motion.dev not loaded yet (CDN delays)
    if (!animate || !inView) {
      setTimeout(init_animation, 100);
      return;
    }

    // Your animation logic here
    inView('.hero-element', ({ target }) => {
      animate(target,
        { opacity: [0, 1], y: [40, 0] },
        { duration: 0.6, easing: [0.22, 1, 0.36, 1] }
      );
    });
  }

  const start = () => {
    if (window[INIT_FLAG]) return;
    window[INIT_FLAG] = true;

    if (document.readyState !== 'loading') {
      setTimeout(init_animation, INIT_DELAY_MS);
      return;
    }

    document.addEventListener(
      'DOMContentLoaded',
      () => setTimeout(init_animation, INIT_DELAY_MS),
      { once: true }
    );
  };

  // Webflow compatibility
  if (window.Webflow?.push) {
    window.Webflow.push(start);
  } else {
    start();
  }
})();
```

**Pattern explanation:**
- `INIT_FLAG` prevents double initialization
- `INIT_DELAY_MS = 100` allows Motion.dev to load from CDN
- Retry logic handles variable CDN loading times
- `window.Motion || {}` safely destructures even if undefined

**See:** [code_quality_standards.md](./code_quality_standards.md) Section 3 for complete CDN-safe pattern documentation.

### Standardized Animation Parameters

**From/to arrays for properties (recommended approach):**

```javascript
const { animate } = window.Motion;

// Single property
animate(element, {
  opacity: [0, 1]  // From 0 to 1
}, { duration: 0.6 });

// Multiple properties
animate(element, {
  opacity: [0, 1],
  y: [40, 0],           // From 40px down to 0 (entrance from below)
  scale: [0.95, 1]      // From slightly smaller to full size
}, {
  duration: 0.6,
  easing: [0.22, 1, 0.36, 1]
});
```

**Standardized easing curves (aligned with Webflow):**

```javascript
const easings = {
  easeOut: [0.22, 1, 0.36, 1],    // General purpose, smooth deceleration
  expoOut: [0.16, 1, 0.3, 1]      // Dramatic entrances, strong deceleration
};

animate(element, properties, {
  duration: 0.6,
  easing: easings.easeOut
});
```

### In-View One-Time Entrances

**Trigger animations when elements scroll into view:**

```javascript
const { inView } = window.Motion;

// Basic in-view entrance
inView('.section', ({ target }) => {
  animate(target,
    { opacity: [0, 1], y: [40, 0] },
    { duration: 0.6 }
  );
}, {
  amount: 0.3  // Trigger when 30% of element is visible
});

// Multiple elements with stagger
inView('.card-grid', ({ target }) => {
  const cards = target.querySelectorAll('.card');

  cards.forEach((card, index) => {
    animate(card,
      { opacity: [0, 1], y: [20, 0] },
      {
        duration: 0.5,
        delay: index * 0.1  // Stagger by 100ms per card
      }
    );
  });
}, {
  amount: 0.2
});
```

### Performance Cleanup Pattern

**Always remove will-change after animations complete:**

```javascript
const { animate } = window.Motion;

animate(element, { opacity: [0, 1] }, {
  duration: 0.6,
  onComplete: () => {
    element.style.willChange = '';  // Remove GPU hint
  }
});
```

**Why this matters:**
- `will-change` promotes element to GPU layer (expensive)
- Keeping it active after animation wastes memory
- Browser manages layers better when will-change is removed

**Reference implementations:**

| File | Pattern Demonstrated |
|------|---------------------|
| `src/2_javascript/hero/hero_general.js` | InView-based multi-phase sequence, easing maps, loader fadeout, will-change cleanup |
| `src/2_javascript/hero/hero_blog_article.js` | Content-first then overlay, short durations, expoOut easing |

---

## 4. 🚀 PERFORMANCE OPTIMIZATION

### Set Initial States (Prevent Flicker)

**Problem:** Elements are visible before JavaScript runs, then jump when animation starts.

**Solution:** Set initial animated state in CSS:

```css
/* Set initial state for entrance animations */
.animated-entrance {
  opacity: 0;
  transform: translateY(40px);
}

/* After JS runs, animate to final state */
.animated-entrance.is-visible {
  opacity: 1;
  transform: translateY(0);
  transition: opacity 0.6s ease-out, transform 0.6s ease-out;
}
```

```javascript
// JavaScript adds class to trigger animation
inView('.animated-entrance', ({ target }) => {
  target.classList.add('is-visible');
});
```

### Batch Style Reads and Writes

**Problem:** Interleaving reads and writes causes layout thrashing (multiple reflows).

**Solution:** Batch all reads first, then all writes:

```javascript
// ❌ BAD: Causes layout thrashing
elements.forEach(el => {
  const height = el.scrollHeight;  // Read (forces layout)
  el.style.height = `${height}px`; // Write
  el.classList.add('active');       // Write
});
// Browser reflows 3 times (read-write-write per iteration)

// ✅ GOOD: Batch reads, then writes
const heights = elements.map(el => el.scrollHeight);  // All reads
elements.forEach((el, i) => {                         // All writes
  el.style.height = `${heights[i]}px`;
  el.classList.add('active');
});
// Browser reflows only once (after all writes)
```

### Will-Change Lifecycle Management

**Proper will-change usage:**

```javascript
// Set will-change just before animation
element.style.willChange = 'transform, opacity';

// Run animation
await animate(element, properties, {
  duration: 0.6,
  onComplete: () => {
    // Remove will-change after animation
    element.style.willChange = '';
  }
});
```

**When to use will-change:**
- Complex animations (multiple properties)
- Scroll-triggered animations (set on scroll start, remove on scroll end)
- High-frequency animations (dragging, following cursor)

**When NOT to use will-change:**
- Simple hover states (browser optimizes automatically)
- Permanent state (wastes GPU memory)
- Static elements (no animation planned)

---

## 5. 🧪 TESTING AND DEBUGGING PROCEDURES

### Pre-Deployment Checklist

**Cross-device timing verification:**
1. **Desktop** - Verify full animation durations feel natural
2. **Tablet** - Check medium viewport behavior, adjust if needed
3. **Mobile** - Ensure animations are brief (300ms max recommended for mobile)

**Why mobile needs shorter durations:** Mobile devices have smaller screens where motion is more noticeable, and users expect snappier interactions.

### Layout Stability Testing

**Prevent content jumps during animation:**

1. **Measure before animating** - Capture `scrollHeight`, `offsetWidth` before transition
2. **Apply transitions to measured pixel values** - Animate from/to known values
3. **Set `auto` after transition completes** - Use `transitionend` event
4. **Verify no content jumps** - Check surrounding content doesn't shift

**Testing procedure:**
```javascript
// Add visual debugging
element.addEventListener('transitionstart', () => {
  console.log('Animation start:', {
    height: element.offsetHeight,
    scroll: window.scrollY
  });
});

element.addEventListener('transitionend', () => {
  console.log('Animation end:', {
    height: element.offsetHeight,
    scroll: window.scrollY
  });
});

// Scroll position should not change during animation
```

### Reduced Motion Testing

**Required testing for accessibility compliance:**

1. **Enable "Reduce motion" in OS settings**
   - macOS: System Preferences → Accessibility → Display → Reduce motion
   - Windows: Settings → Ease of Access → Display → Show animations
   - iOS/Android: Accessibility settings → Reduce motion

2. **Verify animations skip or use minimal duration (<20ms)**
   - Elements should instantly appear in final state
   - No jarring transitions or sudden movements

3. **Confirm end states are visually correct without animation**
   - All content visible and positioned correctly
   - No missing or hidden elements

**JavaScript detection pattern:**
```javascript
const prefersReducedMotion = window.matchMedia(
  '(prefers-reduced-motion: reduce)'
).matches;

if (prefersReducedMotion) {
  // Skip animation, apply end state directly
  element.style.opacity = '1';
  element.style.transform = 'none';
} else {
  // Run full animation sequence
  animate(element, { opacity: [0, 1] }, { duration: 0.6 });
}
```

### Performance Profiling

**Use Chrome DevTools Performance panel:**

1. **Open DevTools** → Performance tab
2. **Record during animation sequence** (click record, trigger animation, stop)
3. **Analyze for performance issues:**

**What to look for:**

| Issue | Visual Indicator | Fix |
|-------|-----------------|-----|
| **Long tasks** | Red bars >50ms | Split work into smaller chunks, use requestAnimationFrame |
| **Forced reflows** | Purple bars labeled "Layout" | Batch style reads/writes, avoid layout properties |
| **Excessive layers** | Many green "Paint" bars | Remove unnecessary will-change, limit animated elements |
| **Jank (dropped frames)** | Choppy FPS graph | Use GPU-accelerated properties only (transform, opacity) |

**Target metrics:**
- **60 FPS** - 16.67ms per frame maximum
- **No long tasks** - All main thread work <50ms
- **Minimal layout** - Only 1-2 layout recalculations per animation

### Automated Animation Testing (MCP & CLI)

**Automated testing enables visual regression detection and objective performance measurement:**

#### Visual State Capture (Before/After Animation)

**Option 1: Chrome DevTools MCP**
```markdown
1. Navigate to page:
   [Use tool: mcp__chrome_devtools_2__navigate_page]
   - url: "https://anobel.com"

2. Capture before state:
   [Use tool: mcp__chrome_devtools_2__take_screenshot]
   - Save as "animation-before.png"

3. Trigger animation (via evaluate_script or user interaction)

4. Capture after state:
   [Use tool: mcp__chrome_devtools_2__take_screenshot]
   - Save as "animation-after.png"

5. Compare screenshots visually
```

**Option 2: cli-chrome-devtools (Terminal-based)**
```bash
# Visual regression testing workflow
bdg https://anobel.com 2>&1

# Capture initial state
bdg screenshot animation-before.png 2>&1

# Trigger animation (wait for completion)
sleep 2

# Capture final state
bdg screenshot animation-after.png 2>&1

# Stop session
bdg stop 2>&1

# Compare screenshots (use diff tool)
compare animation-before.png animation-after.png animation-diff.png
```

#### Animation Performance Metrics

**CLI Performance Profiling:**
```bash
# Navigate to page
bdg https://anobel.com 2>&1

# Trigger animation and capture metrics immediately after
bdg js "document.querySelector('.animated-element').classList.add('animate')" 2>&1
sleep 1  # Wait for animation to complete

# Get performance metrics
bdg cdp Performance.getMetrics 2>&1 > animation-metrics.json

# Check for layout thrashing
jq '.result.metrics[] | select(.name == "LayoutCount" or .name == "RecalcStyleCount")' animation-metrics.json

# Check timing metrics
jq '.result.metrics[] | select(.name | contains("Duration"))' animation-metrics.json

# Stop session
bdg stop 2>&1
```

**Key animation metrics:**
```json
{
  "name": "LayoutCount",
  "value": 2  // Should be ≤3 per animation
},
{
  "name": "RecalcStyleCount",
  "value": 1  // Should be minimal
},
{
  "name": "TaskDuration",
  "value": 145  // Total task time in ms
}
```

**Performance Assertion Example:**
```bash
#!/bin/bash
# Assert animation performance meets targets

bdg https://anobel.com 2>&1

# Trigger animation
bdg js "document.querySelector('.hero').classList.add('animate-in')" 2>&1
sleep 0.6  # Animation duration

# Get metrics
METRICS=$(bdg cdp Performance.getMetrics 2>&1)
bdg stop 2>&1

# Extract layout count
LAYOUT_COUNT=$(echo "$METRICS" | jq '.result.metrics[] | select(.name=="LayoutCount") | .value')

# Assert performance target
if [ "$LAYOUT_COUNT" -gt 3 ]; then
  echo "❌ FAIL: Too many layouts ($LAYOUT_COUNT > 3)"
  exit 1
else
  echo "✅ PASS: Layout count within target ($LAYOUT_COUNT ≤ 3)"
fi
```

#### Multi-Viewport Animation Testing

**Automated cross-viewport testing:**
```bash
#!/bin/bash
# Test animations at all viewports

VIEWPORTS=("1920:1080:desktop" "768:1024:tablet" "375:667:mobile")
URL="https://anobel.com"

for viewport in "${VIEWPORTS[@]}"; do
  IFS=':' read -r width height name <<< "$viewport"

  echo "Testing $name viewport (${width}x${height})..."

  bdg "$URL" 2>&1

  # Set viewport
  bdg cdp Emulation.setDeviceMetricsOverride "{\"width\":$width,\"height\":$height,\"deviceScaleFactor\":2,\"mobile\":false}" 2>&1

  # Capture before animation
  bdg screenshot "animation-${name}-before.png" 2>&1

  # Trigger animation
  bdg js "document.querySelector('.animated-element').classList.add('animate')" 2>&1
  sleep 1

  # Capture after animation
  bdg screenshot "animation-${name}-after.png" 2>&1

  # Get performance metrics
  bdg cdp Performance.getMetrics 2>&1 > "animation-${name}-metrics.json"

  bdg stop 2>&1

  echo "✅ $name viewport captured"
done

echo "✅ All viewport tests complete"
```

#### Reduced Motion Testing

**Automated prefers-reduced-motion verification:**
```bash
# Test with reduced motion preference
bdg https://anobel.com 2>&1

# Enable reduced motion emulation
bdg cdp Emulation.setEmulatedMedia '{"features":[{"name":"prefers-reduced-motion","value":"reduce"}]}' 2>&1

# Check if animations are disabled
REDUCED_MOTION=$(bdg js "window.matchMedia('(prefers-reduced-motion: reduce)').matches" 2>&1)

echo "Reduced motion active: $REDUCED_MOTION"

# Capture screenshot in reduced motion mode
bdg screenshot animation-reduced-motion.png 2>&1

bdg stop 2>&1
```

**See:** `.claude/skills/cli-chrome-devtools/` for complete CLI automation patterns

---

## 6. 🐛 COMMON ISSUES AND SOLUTIONS

### Layout Jump on Height Animation

**Issue:** Content shifts when transitioning `height: 0` to `height: auto`

**Cause:** CSS cannot animate to `auto` value, snaps instead of transitioning

**Solution:**
```javascript
// Measure natural height first
const naturalHeight = element.scrollHeight;

// Animate to pixel value
element.style.height = `${naturalHeight}px`;

// After transition, set to auto (responsive)
element.addEventListener('transitionend', () => {
  element.style.height = 'auto';
}, { once: true });
```

### Jank on Scroll-Triggered Animations

**Issue:** Animations stutter or drop frames during scrolling

**Cause:** Animating layout properties (width, height, top, left) forces reflows

**Solution:**
```javascript
// ❌ BAD: Animates layout properties
animate(element, {
  width: [100, 200],    // Causes reflow
  top: [0, 100]         // Causes reflow
});

// ✅ GOOD: GPU-accelerated properties only
animate(element, {
  scale: [0.5, 1],      // GPU-accelerated
  y: [0, 100]           // GPU-accelerated (translateY)
});
```

**Additional optimization:**
```javascript
// Add will-change temporarily for complex animations
element.style.willChange = 'transform, opacity';

animate(element, properties, {
  onComplete: () => {
    element.style.willChange = '';  // Remove after
  }
});
```

### Animation Doesn't Start (Motion.dev Not Loaded)

**Issue:** `window.Motion` is undefined, animations don't run

**Cause:** CDN loading slower than component initialization

**Solution:** Use retry logic pattern
```javascript
function init_animation() {
  const { animate, inView } = window.Motion || {};

  // Retry if Motion.dev not loaded yet
  if (!animate || !inView) {
    setTimeout(init_animation, 100);  // Retry after 100ms
    return;
  }

  // Now safe to use animate/inView
  inView('.hero', ({ target }) => {
    animate(target, { opacity: [0, 1] }, { duration: 0.6 });
  });
}
```

### Elements Flicker Before Animation

**Issue:** Elements visible in default state, then jump to animated start state

**Cause:** CSS initial state not set before JavaScript runs

**Solution:** Set initial state in CSS
```css
/* Set initial state for all animated elements */
.hero-element {
  opacity: 0;           /* Start invisible */
  transform: translateY(40px);  /* Start below final position */
}

/* JavaScript will animate to these values */
.hero-element.animated {
  opacity: 1;
  transform: translateY(0);
}
```

**Alternative:** Use JavaScript to set state before DOM renders (in `<head>`)
```html
<script>
  // Runs before body renders
  document.documentElement.classList.add('js-enabled');
</script>

<style>
  .js-enabled .hero-element {
    opacity: 0;
    transform: translateY(40px);
  }
</style>
```

---

## 7. 🔗 INTEGRATION WITH WORKFLOWS-CODE

### Phase 1: Implementation

When implementing animations:
1. **Decide CSS vs Motion.dev** - Use decision tree (Section 1)
2. **CSS animations** - GPU properties only, add prefers-reduced-motion
3. **Motion.dev animations** - Use retry pattern, standardized easings
4. **Set initial states** - Prevent flicker in CSS
5. **Add cleanup** - Remove will-change in onComplete

### Phase 2: Debugging

When debugging animation issues:
1. **Check Motion.dev loading** - Verify `window.Motion` defined
2. **Verify GPU properties** - No width/height/top/left animations
3. **Test reduced motion** - Enable OS setting, verify end state
4. **Profile performance** - DevTools Performance panel, check for long tasks

### Phase 3: Verification

When verifying animations:
1. **Cross-device testing** - Desktop, tablet, mobile timing
2. **Accessibility testing** - Reduced motion support
3. **Performance profiling** - 60 FPS, no jank, minimal layout
4. **Layout stability** - No content jumps during animation

---

**Core principle:** CSS first for simplicity, Motion.dev for complexity. Keeps payloads small, performance high, and behavior predictable.
