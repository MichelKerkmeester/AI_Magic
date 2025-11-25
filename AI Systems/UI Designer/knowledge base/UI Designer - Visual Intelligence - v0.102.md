# UI Designer - Visual Intelligence

Design philosophy, aesthetic decision logic, and quality frameworks for exceptional visual design.

**Core Purpose:** Provide theoretical foundations, decision-making frameworks, and systematic quality assessment for all design decisions through expert visual sensibility.

**Scope:** Pure design theory - visual systems, aesthetic principles, pattern selection, quality frameworks. For conversation patterns, see `UI Designer - Interactive Intelligence`. For thinking methodology, see `UI Designer - CANVAS Thinking Framework`.

---

## 📋 TABLE OF CONTENTS

1. [🎨 DESIGN PHILOSOPHY](#1-design-philosophy)
2. [🔄 PARALLEL DESIGN METHODOLOGY](#2-parallel-design-methodology)
3. [📐 VISUAL SYSTEMS THEORY](#3-visual-systems-theory)
4. [🧩 PATTERN SELECTION](#4-pattern-selection)
5. [✨ POLISH & TRENDS](#5-polish--trends)
6. [🎯 DECISION TREES](#6-decision-trees)
7. [📊 QUALITY ASSESSMENT](#7-quality-assessment)
8. [🏎️ QUICK REFERENCE](#8-quick-reference)

---

## 1. 🎨 DESIGN PHILOSOPHY

**Three Pillars of Visual Excellence:**

| Pillar | Definition | Validation | Techniques |
|--------|------------|------------|------------|
| **Hierarchy** | Guide eye through visual weight | Most important element clear <1 sec | Size/color contrast, spacing emphasis, typography weight |
| **Harmony** | Cohesion through consistent language | Feels cohesive, not Frankenstein | Color unity, typography consistency, spacing system, shape language |
| **Refinement** | Obsessive micro-details | Professional craft vs amateur | Pixel-perfect alignment, subtle shadows, transition polish, color subtlety |

**Core Principles:**
- "Why before What" - Understand purpose (shadows = depth hierarchy, not decoration)
- "Convention with Intention" - Follow patterns, break intentionally when needed
- "Simplicity = Result of Complexity" - Simple designs require complex thinking

---

## 2. 🔄 PARALLEL DESIGN METHODOLOGY

**When to Generate Variants:**

| Trigger | Action | Count |
|---------|--------|-------|
| Explicit request ("show options", "variations") | Generate immediately | User-specified or 3-5 |
| High complexity + uncertainty (complexity 7+, "not sure") | Offer variant generation | 5-10 |
| Creative/subjective ("design landing page", "make modern") | Generate by default | 3-5 |
| Clear direction (detailed mockup, specific reference) | Single high-fidelity | 1 (no variants) |

**Strategy Selection:** Analyze audience + industry + content density + brand personality → Select 3-7 diverse strategies spanning solution space → Document rationale for each

**Workflow:** Diverge (strategies → wireframes → pros/cons) → Present (equal treatment, honest tradeoffs) → Selection (single/hybrid/iterate) → Refinement (full CANVAS, DESIGN 40+/50)

---

## 3. 📐 VISUAL SYSTEMS THEORY

### Typography

**Font Pairing Rules:**
1. Contrast - Serif+Sans or Display+Neutral | Avoid similar sans or two decorative
2. Hierarchy - Use weight/size, not just different fonts
3. Limit - Max 2 families (+monospace for code = 3)
4. Readability - 16px min, 1.5-1.8 line-height, 45-75 char line length

**Readability Science:**
- Line length: 45-75 chars (66 ideal) | <45 = choppy | >75 = lost tracking | Use `max-width: 35em`
- Line height: 1.5-1.8 body (1.6 ideal) | 1.7-1.8 long lines | 1.5-1.6 short | 1.2-1.3 headings
- Font size: 16px min | 16-18px mobile | 16-21px desktop | Never <12px

**Modular Scale:**
| Ratio | Feel | Scale (16px base) | Use |
|-------|------|-------------------|-----|
| 1.2 Minor Third | Subtle | 16→19→23→28 | Conservative corporate |
| 1.25 Major Third | Balanced | 16→20→25→31 | Business apps |
| 1.333 Perfect Fourth | Strong | 16→21→28→38 | Modern interfaces |
| 1.618 Golden Ratio | Dramatic | 16→26→42→68 | Bold marketing |

**Font Psychology:**
| Type | Signals | Best For |
|------|---------|----------|
| Serif | Trust, tradition, sophistication | Long-form, luxury, finance, law |
| Sans-Serif | Modern, friendly, efficient | Interfaces, tech, versatile |
| Display | Bold, creative, attention | Headlines only, large sizes |
| Monospace | Technical, precise | Code blocks, technical docs |

### Color Theory

**Harmony Systems:**
| System | Use | Rule |
|--------|-----|------|
| Monochromatic | Minimalist, content-focused | 50-900 shades + tinted grays |
| Analogous | Cohesive with variety | 60% dominant, 30% support, 10% accent |
| Complementary | High energy, attention | 90/10 or 80/20 split (NEVER 50/50) |
| Split-Complementary | Contrast without aggression | Softer than pure complementary |
| Triadic | Playful, creative | 65% dominant, 25% secondary, 10% accent |
| Tetradic | Complex interfaces | One dominant (60%+), advanced |

**Psychology:**
| Color | Effect | Signals | Use | Caution |
|-------|--------|---------|-----|---------|
| Blue | Calming | Trust, professionalism | Finance, tech, healthcare | Cold/distant |
| Red | Urgency | Passion, danger | Food, sales, alerts | Stress - use sparingly |
| Green | Restful | Health, growth | Nature, wellness | — |
| Yellow | Stimulates | Optimism, energy | Small accents | Eye strain |
| Purple | Imagination | Luxury, creativity | Premium, creative | Overly decorative |
| Orange | Energetic | Enthusiasm, friendly | Social, CTAs | — |
| Black/Gray | — | Sophistication, power | Luxury, interfaces | Pure black harsh |

**Accessibility:**
- WCAG AA: 4.5:1 text <18px | 3:1 text 18px+ or 14px+ bold | AAA: 7:1
- Color blindness (~8% males): Never color alone - add icon/label | Avoid red/green, blue/purple | Safe: blue/orange, dark/light contrast
- Semantic: Green=success, Red=error, Yellow=warning, Blue=info

**Refinement:**
- Avoid pure black (#000) → Use #1a1a1a or tinted darks
- Avoid pure white (#fff) → Use #fafafa or warm whites
- Tint grays with brand color for cohesion
- Gradients: Analogous only (complementary = mud), validate contrast across entire gradient
- Scale: Base (500) → Lighter (50-400) → Darker (600-900) | 50-100 backgrounds, 400-500 buttons, 800-900 text

### Spacing Systems

**8-Point Grid Benefits:** Divides evenly (8, 16, 24, 32, 48, 64) | Device-compatible | 44px touch targets = 5.5×8 | Subconscious rhythm | Faster decisions | Feels polished

**Progressive Spacing:** (Tighter within, wider between)
| Scope | Spacing | Example |
|-------|---------|---------|
| Within component | 8px | Button elements, card padding |
| Between components | 16px | Cards in section, form fields |
| Between sections | 32px | Major content areas |
| Between page sections | 64px+ | Hero → features → testimonials |

### CSS Variables & Design System

**Pre-Flight:** Check `/context/Design System/` folder for STYLE.md or CSS variables before generating tokens (see Interactive Intelligence for question workflow)

**Priority:** STYLE.md → CSS vars → Figma (MCP) → Images → Generate new (see CANVAS Phase C)

**Variable Structure:**
1. Primitives: `--primary-500: #02393e` (raw values with scale 0-1400)
2. Semantic: `--primary-base: var(--primary-500)` (darkest, darker, dark, base, light, lighter, lightest)
3. Contextual: `--bg-brand-base: var(--primary-base)` (purpose-based: bg, border, content, states)
4. Component: `--bg-button-enabled-primary: var(--bg-brand-base)` (component-specific tokens)

**Typography Variables:** `--font-family-primary`, `--font-weight-medium`, `--font-line-height-body`, `--font-size-body-base`

**Spacing Variables:** `--spacing-{value}: {rem}` (2, 4, 6, 8, 10, 12, 16, 20, 24, 32, 40, 48, 64, 80, 96...)

**Fluid Responsive Typography:** (Use for long-form/marketing, skip for data apps)
```css
/* Formula: font-size = base + (coefficient × viewport-width)
   coefficient = (max-size - min-size) / (max-vw - min-vw)
   base = (min-size - min-vw × coefficient) / 16 */
html { font-size: calc(var(--base-0) * 1rem + var(--coefficient-0) * 1vw); }
```

**Benefits:** Single source of truth | Easy theme switching | Browser-native | Enforces consistency

### Gestalt Principles (Perception Psychology)

| Principle | Application |
|-----------|-------------|
| Proximity | Related elements closer (4-8px), unrelated wider (24px+) |
| Similarity | Same-level items look identical, different levels distinct |
| Closure | Simplified logos, outline icons, minimal strokes |
| Continuity | Left-aligned text, single-column forms create clear paths |
| Figure/Ground | Dark overlays for modals, white cards on gray, depth hierarchy |
| Symmetry | Centered (formal) or intentional asymmetry (modern) |
| Common Region | Cards with borders/backgrounds, distinct section colors |
| Common Fate | Related elements animate together as unit |
| Prägnanz | Simplest icon forms, basic shapes, clear categories |
| Multistability | Clever logos only - never for functional UI |
| Invariance | Icons recognizable at all sizes, across themes |
| Emergence | Simple components (cards + grid) create sophistication |

### Usability Heuristics (Nielsen's 10)

| Heuristic | Application |
|-----------|-------------|
| System Status | Loading states, progress bars, validation feedback |
| Real World Match | Universal icons (🔍 🏠), color conventions |
| User Control | Prominent X, cancel visible, undo notifications |
| Consistency | All primary CTAs identical, same spacing everywhere |
| Error Prevention | Date pickers vs text, disabled submit, confirmations |
| Recognition > Recall | Visible nav, autocomplete, recent items, tooltips |
| Flexibility | Keyboard shortcuts, bulk actions, customization |
| Minimalist Design | Clear hierarchy, progressive disclosure, no clutter |
| Error Recovery | Red + icon + prominent, tell how to fix |
| Help Documentation | Tooltips, inline hints, helpful empty states |

**Priority:** Works → Usable → Beautiful (aesthetics enhance, never replace function)

### Laws of UX (Cognitive Psychology)

| Law | Application |
|-----|-------------|
| Fitts's Law | 44x44px min touch, related actions near, corners = infinite targets |
| Hick's Law | 5-7 nav items, one primary action/section, progressive disclosure |
| Miller's Law | Chunk info (123-456-7890), 5-7 nav, break long forms into steps |
| Jakob's Law | Logo top-left → home, search top-right, links look like links |
| Serial Position | Important items at start and end of lists/menus/forms |
| Doherty Threshold | <400ms response, optimistic UI, 100ms instant / 400ms acceptable |
| Tesler's Law | Complexity can't vanish - progressive disclosure, don't oversimplify |

---

## 4. 🧩 PATTERN SELECTION

**Buttons:** Primary (1 per section, main action) | Secondary (multiple OK, cancel/back) | Ghost (tertiary, minimal weight)

**Forms:** Above labels (standard, better mobile) | Inline labels (compact, single-field)

**Cards:** Elevated (featured, important, shadow prominence) | Flat (list items, dense layouts)

**Navigation:** Horizontal (5-7 items, familiar) | Sidebar (10+ items, scalable) | Tabs (related views, same context)

**Layout Patterns:**
| Pattern | Use | Avoid |
|---------|-----|-------|
| Centered Hero | Landing, marketing, launches | Complex messaging, multiple CTAs |
| Split Hero | SaaS, app showcases | Weak/non-essential imagery |
| Full Bleed Hero | Portfolio, photography | Slow images, readability issues |
| 3-Column Grid | Features, services | Content varies greatly in size |
| Asymmetric Grid | Blogs, dashboards | All content equal importance |
| Masonry Grid | Image galleries | Need predictable vertical scanning |

---

## 5. ✨ POLISH & TRENDS

**Polish Levels:**
| Level | Characteristics | Perception |
|-------|-----------------|------------|
| 1. Functional | Basic styling, no transitions, inconsistent spacing | Prototype/MVP |
| 2. Refined | 8px grid, 200ms transitions, typography hierarchy, palette | Real product |
| 3. Sophisticated | Pixel-perfect, 60fps, subtle shadows, no pure black, micro-interactions | Professional/premium |
| 4. Exceptional | Optical balance, spring easing, texture/depth, all states polished | Top tech company |

**Target:** Level 3 production | Level 4 showcase

**Contemporary Trends:**
| Trend | Use | Vanilla CSS | Caution |
|-------|-----|-------------|---------|
| Glassmorphism | Modern apps, overlays, nav | `backdrop-filter: blur(10px)` + semi-transparent | Performance, contrast risk |
| Gradient Meshes | Hero backgrounds, brand | `linear-gradient()` / `radial-gradient()` | Can overwhelm, readability |
| Neumorphism | Minimalist, tactile | Inset shadows + matching bg | Low contrast, decorative only |
| Bold Typography | Landing, marketing, headers | `clamp()` responsive scaling | Overwhelming if overused |
| Dark Mode | Low-light, creative tools | `@media (prefers-color-scheme: dark)` + CSS vars | Desaturate, maintain contrast |
| Micro Animations | All interactions | `transform`/`opacity` only (GPU), 150-300ms | Must be 60fps |
| Asymmetric Layouts | Modern, creative | CSS Grid varied columns | Harder responsive |

**Performance:** Use `transform`, `opacity`, `filter` (GPU) | Avoid `width`, `height`, `top`, `left`, `margin`, `padding` (CPU, causes jank) | Add `will-change` for animated elements

---

## 5.5 🎬 ANIMATION MICRO-SYNTAX

**Compact Notation for Efficient Communication** (from SuperDesign):

**Format:** `element: duration easing [transforms] modifiers`

**Core Syntax Examples:**
```
button: 200ms ease-out [S1→1.05, Y0→-2] hover
card: 300ms ease-out [Y+20→0, α0→1] +100ms
loader: 1000ms linear [R0→360°] ∞
typing: 1400ms ease-in-out [Y±8, α0.4→1] ∞ stagger+200ms
sidebar: 350ms ease-out [X-280→0, α0→1]
modal: 300ms ease-out [α0→1, S0.95→1]
shake: 400ms [X±5] ×3
```

**Legend:**
- **Transforms:** S=Scale, Y=TranslateY, X=TranslateX, R=Rotate, α=Opacity
- **Modifiers:** ∞=Infinite loop, +Xms=Delay, ×N=Repeat count, stagger=Sequential delay
- **States:** hover, focus, active, disabled, loading, error, success
- **Directions:** →=to, ±=oscillate, ↗=increase, ↔=alternate

**Pre-Built Pattern Library:**

```yaml
# Core UI Interactions
btnHover: 200ms [S1→1.05, shadow↗]
btnPress: 150ms [S1→0.95→1, R±2°]
btnDisabled: 300ms [α1→0.5]
linkHover: 150ms [α1→0.8, X0→2]

# Message & Content Flow
msgIn: 400ms ease-out [Y+20→0, X+10→0, S0.9→1]
msgOut: 300ms ease-in [Y0→-20, α1→0]
fadeIn: 300ms [α0→1]
fadeOut: 200ms [α1→0]
slideUp: 400ms ease-out [Y+40→0, α0→1]
slideDown: 300ms ease-in [Y0→+40, α1→0]

# Loading States
spinner: 1000ms ∞ linear [R360°]
pulse: 1500ms ∞ [α0.5→1→0.5]
skeleton: 2000ms ∞ [bg: muted↔accent]
dots: 1400ms ∞ [Y±8] stagger+200ms
bars: 1200ms ∞ [S1→1.5→1] stagger+100ms

# Overlays & Modals
overlayIn: 300ms [α0→1, blur0→4px]
overlayOut: 200ms [α1→0, blur4→0]
modalIn: 300ms ease-out [α0→1, S0.95→1, Y+20→0]
modalOut: 200ms ease-in [α1→0, S1→0.95, Y0→+20]
drawerIn: 350ms ease-out [X-280→0, α0→1]
drawerOut: 250ms ease-in [X0→-280, α1→0]

# Micro Interactions
cardHover: 200ms [Y0→-2, shadow↗]
cardPress: 150ms [S1→0.98]
itemSelect: 200ms [bg→accent, S1→1.02]
ripple: 400ms [S0→2, α1→0]
bounce: 600ms [S0→1.2→1, R360°]
shake: 400ms [X±5] ×3
wiggle: 500ms [R±3°] ×2

# Navigation & Panels
navSlide: 300ms ease-out [X-100%→0]
tabSwitch: 200ms [α0→1]
accordionOpen: 300ms ease-out [height:0→auto, α0→1]
accordionClose: 200ms ease-in [height:auto→0, α1→0]

# Feedback & Status
success: 600ms bounce [S0→1.2→1, R360°]
error: 400ms [X±5] shake
warning: 500ms [α0.3→1] pulse ×2
notification: 300ms ease-out [Y-20→0, α0→1] +delay
toast: 300ms ease-out [X+100%→0, α0→1]
```

**Timing Guidelines:**
- **Quick (100-150ms):** Hover states, toggle switches, small UI changes
- **Standard (200-300ms):** Most transitions, button clicks, content reveals
- **Slow (400-600ms):** Page transitions, complex animations, feedback
- **Very Slow (800ms+):** Loading indicators, celebration animations

**Easing Patterns:**
```yaml
ease-out: "Decelerating (most transitions, content in)" # cubic-bezier(0, 0, 0.2, 1)
ease-in: "Accelerating (content out, dismissals)" # cubic-bezier(0.4, 0, 1, 1)
ease-in-out: "Smooth (loops, oscillations)" # cubic-bezier(0.4, 0, 0.2, 1)
linear: "Constant speed (spinners, progress)" # cubic-bezier(0, 0, 1, 1)
bounce: "Spring effect (success, playful)" # Custom cubic-bezier
```

**Usage in Design:**
```markdown
# Phase A - Animation Design

## Core Interactions
- Button hover: 200ms [S1→1.05, shadow↗]
- Button press: 150ms [S1→0.95→1]
- Card entrance: 400ms ease-out [Y+20→0, α0→1] stagger+100ms

## Loading States
- Primary loader: 1000ms ∞ linear [R360°]
- Skeleton: 2000ms ∞ [bg: muted↔accent]

## Page Transitions
- Content in: 400ms ease-out [Y+40→0, α0→1]
- Modal: 300ms ease-out [α0→1, S0.95→1]
```

---

## 5.6 🎨 PRE-BUILT THEME LIBRARY

**Complete Theme Systems** (from SuperDesign):

### Neo-Brutalism Style
```css
:root {
  /* Colors */
  --background: oklch(1.0000 0 0);
  --foreground: oklch(0 0 0);
  --primary: oklch(0.6489 0.2370 26.9728);
  --primary-foreground: oklch(1.0000 0 0);
  --secondary: oklch(0.9680 0.2110 109.7692);
  --secondary-foreground: oklch(0 0 0);
  --accent: oklch(0.5635 0.2408 260.8178);
  --destructive: oklch(0 0 0);
  --border: oklch(0 0 0);
  
  /* Typography */
  --font-sans: 'DM Sans', sans-serif;
  --font-mono: 'Space Mono', monospace;
  
  /* Effects */
  --radius: 0px;
  --shadow: 4px 4px 0px 0px hsl(0 0% 0% / 1.00);
  --shadow-md: 4px 4px 0px 0px hsl(0 0% 0% / 1.00), 4px 2px 4px -1px hsl(0 0% 0% / 1.00);
  --spacing: 0.25rem; /* 4px base */
}
```

**Character:** Bold, vintage web, high contrast, flat colors, harsh shadows, no gradients
**Best For:** Creative portfolios, art projects, playful brands, vintage aesthetics

### Modern Dark Mode
```css
:root {
  /* Colors */
  --background: oklch(0.1450 0 0);
  --foreground: oklch(0.9850 0 0);
  --primary: oklch(0.9850 0 0);
  --primary-foreground: oklch(0.2050 0 0);
  --secondary: oklch(0.9700 0 0);
  --muted: oklch(0.2820 0 0);
  --accent: oklch(0.8100 0.1000 252);
  --destructive: oklch(0.5770 0.2450 27.3250);
  --border: oklch(0.2820 0 0);
  
  /* Typography */
  --font-sans: 'Inter', system-ui, sans-serif;
  --font-mono: 'JetBrains Mono', monospace;
  
  /* Effects */
  --radius: 0.625rem; /* 10px */
  --shadow: 0 1px 3px 0px hsl(0 0% 0% / 0.10), 0 1px 2px -1px hsl(0 0% 0% / 0.10);
  --shadow-md: 0 4px 6px -1px hsl(0 0% 0% / 0.10), 0 2px 4px -1px hsl(0 0% 0% / 0.10);
  --spacing: 0.25rem; /* 4px base */
}
```

**Character:** Professional, tech-forward, subtle shadows, refined, modern
**Best For:** SaaS products, developer tools, tech companies, dashboards

### Minimalist Light
```css
:root {
  /* Colors */
  --background: oklch(0.9850 0 0);
  --foreground: oklch(0.1450 0 0);
  --primary: oklch(0.2050 0 0);
  --primary-foreground: oklch(0.9850 0 0);
  --secondary: oklch(0.9700 0 0);
  --secondary-foreground: oklch(0.1450 0 0);
  --muted: oklch(0.9550 0 0);
  --accent: oklch(0.9700 0 0);
  --border: oklch(0.9220 0 0);
  
  /* Typography */
  --font-sans: 'Inter', sans-serif;
  --font-serif: 'Merriweather', serif;
  
  /* Effects */
  --radius: 0.5rem; /* 8px */
  --shadow: 0 1px 3px 0px hsl(0 0% 0% / 0.05);
  --shadow-md: 0 4px 6px -1px hsl(0 0% 0% / 0.05), 0 2px 4px -1px hsl(0 0% 0% / 0.05);
  --spacing: 0.5rem; /* 8px base */
}
```

**Character:** Clean, spacious, subtle, content-focused, neutral
**Best For:** Editorial, content platforms, minimalist brands, clean interfaces

### Vibrant/Playful
```css
:root {
  /* Colors */
  --background: oklch(0.9900 0.0200 109.7692);
  --foreground: oklch(0.1450 0 0);
  --primary: oklch(0.6489 0.2370 26.9728);
  --primary-foreground: oklch(1.0000 0 0);
  --secondary: oklch(0.9680 0.2110 109.7692);
  --accent: oklch(0.5635 0.2408 260.8178);
  --destructive: oklch(0.5770 0.2450 27.3250);
  --border: oklch(0.9220 0 0);
  
  /* Typography */
  --font-sans: 'Poppins', sans-serif;
  --font-display: 'Outfit', sans-serif;
  
  /* Effects */
  --radius: 1rem; /* 16px - rounded */
  --shadow: 0 4px 6px -1px hsl(0 0% 0% / 0.10);
  --shadow-md: 0 10px 15px -3px hsl(0 0% 0% / 0.10), 0 4px 6px -2px hsl(0 0% 0% / 0.05);
  --spacing: 0.5rem; /* 8px base */
}
```

**Character:** Energetic, friendly, colorful, rounded, approachable
**Best For:** Consumer apps, creative tools, entertainment, youth brands

### Professional/Corporate
```css
:root {
  /* Colors */
  --background: oklch(0.9850 0 0);
  --foreground: oklch(0.1450 0 0);
  --primary: oklch(0.4500 0.1900 260); /* Corporate blue */
  --primary-foreground: oklch(0.9850 0 0);
  --secondary: oklch(0.5500 0.1000 240);
  --muted: oklch(0.9550 0 0);
  --accent: oklch(0.7000 0.1500 50); /* Gold accent */
  --border: oklch(0.8500 0 0);
  
  /* Typography */
  --font-sans: 'Roboto', sans-serif;
  --font-serif: 'Merriweather', serif;
  
  /* Effects */
  --radius: 0.375rem; /* 6px - subtle */
  --shadow: 0 1px 3px 0px hsl(0 0% 0% / 0.12), 0 1px 2px 0px hsl(0 0% 0% / 0.08);
  --shadow-md: 0 4px 6px -1px hsl(0 0% 0% / 0.12), 0 2px 4px -1px hsl(0 0% 0% / 0.08);
  --spacing: 0.5rem; /* 8px base */
}
```

**Character:** Trustworthy, conservative, professional, subtle, traditional
**Best For:** Enterprise software, financial services, legal, healthcare

**Usage:** Copy theme CSS → Customize colors/fonts → Apply to design system → Reference throughout CANVAS phases

---

## 6. 🎯 DECISION TREES

**Style Selection:**
| By | Direction |
|----|-----------|
| Audience | Enterprise → Professional Classic/Minimalist | Young consumers → Bold/Playful | General → Modern/Minimalist | Creative → Bold/Playful | Technical → Data-Dense/Minimalist |
| Industry | Finance/Legal/Healthcare → Professional Classic | Tech startups → Modern Trendy | Creative agencies → Bold Expressive | Ecommerce → Modern/Minimalist | Enterprise software → Minimalist/Data-Dense |
| Density | High → Data-Dense Professional | Medium → Modern/Professional Classic | Low → Minimalist/Playful Creative |

**Color Selection:**
1. Brand colors? → Use as primary, extend with complementary
2. No brand → Industry: Finance/Legal (Blue #2563EB trust) | Health/Wellness (Green #10B981 growth) | Energy (Red/Orange #EF4444 excitement) | Luxury (Purple/Gold #8B5CF6 premium)
3. Harmony: Monochromatic (minimalist) | Complementary/Triadic (bold) | Analogous (professional)
4. Validate: WCAG AA (4.5:1 text, 3:1 UI) - non-negotiable

**Typography Pairing:**
1. Heading personality: Professional (Inter, Roboto) | Elegant (Merriweather, Playfair) | Bold (Clash Display, Montserrat) | Friendly (Poppins, Nunito)
2. Body pairing: Serif heading → Sans body | Display heading → Neutral sans | Sans heading → Same font different weight
3. Validate: Heading 2x+ larger | Bold (600-700) vs Regular (400) | Style contrast
4. Scale: Professional (1.333 Perfect Fourth) | Elegant (1.25 Major Third) | Bold (1.618 Golden Ratio)

---

## 7. 📊 QUALITY ASSESSMENT

**Visual Hierarchy Scoring (50 pts):**
| Criterion | Excellent (10) | Good (7-9) | Poor (1-6) |
|-----------|----------------|------------|------------|
| Focal Point | <1 sec identify | Clear within 2 sec | Unclear/competing |
| Size Contrast | Primary 2x+ larger | Primary 1.5x larger | Similar sizes |
| Color Contrast | High primary (4.5:1+), subtle secondary | Noticeable difference | Similar everywhere |
| Whitespace | More around important | Some differentiation | Cramped, equal |
| Visual Flow | Clear: entry → primary → action | Mostly clear | Jumps around |

**Scoring:** 80%+ excellent | 60-79% good | <60% needs improvement

**Aesthetic Sophistication (40 pts):**
| Category | Novice (1-2) | Intermediate (3-4) | Advanced (5-6) | Expert (7-8) |
|----------|--------------|-------------------|----------------|--------------|
| Color | Primary colors, pure black | Extended palette, some tints | Rich darks, subtle tints | Perfect harmony, cultural awareness |
| Typography | System fonts, no scale | 2 fonts, basic scale | Intentional pairing, math scale | Perfect pairing, golden ratio details |
| Spacing | Random, no system | Some consistency | 8px grid, clear rhythm | Perfect rhythm, optical balance |
| Balance | Unbalanced, random | Mostly balanced | Intentional, purposeful asymmetry | Perfect, sophisticated asymmetry |
| Micro-Details | No polish, instant | Basic 200ms transitions | Subtle shadows, all states | Obsessive, 60fps, pixel-perfect |

**Scoring:** 30+ expert | 25-29 advanced | 20-24 intermediate | <20 needs work

**Rapid Checklist (30-sec):**
1. Most important element clear in 1 sec? (Hierarchy)
2. 8px grid spacing consistent? (System)
3. All interactive elements have hover? (Interaction)
4. No pure black/white? (Sophistication)
5. Feels polished/professional? (Overall)
6. 4.5:1 text contrast min? (Accessibility)
7. Animations smooth 60fps? (Performance)
8. Works mobile 375px? (Responsive)
9. Vanilla JS/CSS/HTML only? (Technical)
10. Self-contained HTML file? (Delivery)

**Pass:** 8+/10 checks

---

## 8. 🏎️ QUICK REFERENCE

**Style:** Enterprise → Minimalist/Professional | Young consumers → Bold/Playful | General → Modern/Minimalist | Creative → Bold/Playful | Finance/Legal/Health → Professional Classic | Tech startups → Modern Trendy | Agencies → Bold Expressive | Ecommerce → Modern/Minimalist

**Color:** Brand colors → Extend with tints/shades | Trust → Blue #2563EB + orange accents | Energy → Red/Orange #EF4444 + triadic | Premium → Purple/Gold #8B5CF6 + whitespace | Natural → Green #10B981 + earth tones | Playful → Warm high saturation | No direction → Analogous harmony

**Typography:** Professional (Inter + Inter) | Elegant (Playfair + Source Sans) | Bold (Clash Display + Inter) | Friendly (Poppins + Poppins) | Technical (Roboto + Roboto Mono) | Traditional (Merriweather + Open Sans)

**Scale:** Professional (1.333 Perfect Fourth) | Elegant (1.25 Major Third) | Dramatic (1.618 Golden Ratio)

**Spacing:** Standard (8px grid: 8, 16, 24, 32, 48, 64) | Dramatic (Golden: 16, 26, 42, 68, 110) | Compact (4px: 4, 8, 12, 16, 20, 24) | Premium (2x: 16, 32, 64, 96)

---

## 9. 🎨 SHADCN/UI INTEGRATION

**Component Mapping Strategy:**

| Design Need | shadcn/ui Component | Customization Approach |
|-------------|---------------------|------------------------|
| Buttons | Button, ToggleGroup | Variant prop + Tailwind classes for brand colors |
| Forms | Input, Select, Checkbox, RadioGroup, Textarea, Form | Tailwind for spacing, colors, focus states |
| Cards/Containers | Card, Separator | Tailwind for shadows, borders, backgrounds |
| Modals/Overlays | Dialog, Sheet, AlertDialog, Popover | Tailwind for backdrop, positioning |
| Navigation | NavigationMenu, Tabs, Breadcrumb | Tailwind for active states, spacing |
| Feedback | Alert, Toast, Badge, Progress | Tailwind for semantic colors (success/error/warning) |
| Data Display | Table, DataTable, Accordion, Collapsible | Tailwind for row styling, zebra stripes |
| Typography | Text primitives with Tailwind | Use Tailwind's typography scale classes |

**shadcn/ui Design System Alignment:**

1. **Colors** - Use shadcn's CSS variable system:
   ```css
   --primary: 221.2 83.2% 53.3%;
   --secondary: 210 40% 96.1%;
   --accent: 210 40% 96.1%;
   --destructive: 0 84.2% 60.2%;
   ```
   Customize via Tailwind config or inline CSS variables

2. **Typography** - Leverage Tailwind's built-in scale:
   ```tsx
   <h1 className="text-4xl font-bold">
   <p className="text-base leading-7">
   ```

3. **Spacing** - Use Tailwind's spacing scale (aligns with 8px grid):
   ```tsx
   <div className="p-6 space-y-4">  // 24px padding, 16px gap
   ```

4. **Component Variants** - Extend shadcn components:
   ```tsx
   <Button variant="default" size="lg" className="bg-brand-500">
   ```

**Reference Extraction + shadcn/ui Workflow:**

1. **Extract design tokens** from references (colors, typography, spacing)
2. **Map to shadcn/ui components** - identify which base components fit the design
3. **Apply customization**:
   - Strict mode: Override shadcn defaults with exact extracted tokens
   - Balanced mode: Blend shadcn patterns with extracted aesthetic
   - Creative mode: Use shadcn as foundation, interpret freely
4. **Extend with Tailwind** - Add extracted colors/fonts via Tailwind config
5. **Generate components** - Output .tsx files with shadcn imports + customization

**Example Token Mapping:**

```typescript
// Extracted from reference
const extractedTokens = {
  primary: '#02393e',
  fontHeading: 'Clash Display',
  fontBody: 'Inter',
  spacing: 8, // 8px grid
  borderRadius: 12
}

// Map to Tailwind config extension
tailwind.config = {
  theme: {
    extend: {
      colors: {
        brand: {
          500: '#02393e', // extracted primary
        }
      },
      fontFamily: {
        heading: ['Clash Display', ...],
        body: ['Inter', ...],
      },
      borderRadius: {
        brand: '12px',
      }
    }
  }
}

// Use in shadcn component
<Button className="bg-brand-500 font-heading rounded-brand">
```

**Quality Checklist for shadcn Components:**

- [ ] Started with appropriate shadcn/ui base component
- [ ] Applied Tailwind customization for brand alignment
- [ ] Proper TypeScript types for all props
- [ ] Accessibility attributes preserved from shadcn base
- [ ] Responsive classes applied (sm:, md:, lg:)
- [ ] Hover/focus states defined with Tailwind
- [ ] Component can be imported and reused
- [ ] Demo/usage example provided

---

**Three Pillars:** Hierarchy (guide eye) | Harmony (cohesion) | Refinement (obsess details)

**Technical Implementation:** All visual theory translates to React components with shadcn/ui base components, customized with Tailwind CSS utility classes for brand-specific implementations. For complete methodology, see `UI Designer - CANVAS Thinking Framework`.