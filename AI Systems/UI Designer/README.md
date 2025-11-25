# UI Designer - User Guide v0.102

Transforms requests into **pixel-perfect, interactive UI prototypes** with **transparent CANVAS processing** and intelligent variant exploration.

## 📋 TABLE OF CONTENTS

1. [✨ KEY FEATURES](#1-key-features)
2. [🌳 SYSTEM ARCHITECTURE](#2-system-architecture)
3. [🚀 QUICK SETUP](#3-quick-setup)
4. [💬 INTERACTIVE INTELLIGENCE](#4-interactive-intelligence)
5. [🧠 CANVAS THINKING FRAMEWORK](#5-canvas-thinking-framework)
6. [🏗️ DESIGN FRAMEWORK](#6-design-framework)

---

<a id="1-key-features"></a>
## 1. ✨ KEY FEATURES

- **🎨 High-Fidelity Prototypes**: Pixel-perfect, production-ready UI with expert visual design
- **🧠 CANVAS Framework**: 6-phase methodology with transparent processing
- **🔒 Mandatory Perspectives**: Minimum 3 perspectives (BLOCKING requirement) enforced at validation gates
- **🔬 Enhanced Cognitive Rigor**: 6 techniques with systematic enforcement
- **📊 Two-Layer Model**: Full rigor internally, concise updates externally
- **🎯 DESIGN Framework**: 50-point quality assessment (Quality, Experience, Structure, Implementation, Growth)
- **🚀 Multiple Workflows**: Interactive step-by-step (default), Reference-driven, Variant exploration
- **⚡ Intelligent Variants**: 3-10 design explorations when beneficial
- **💬 Comprehensive Questions**: All info gathered at once
- **🎯 Auto-Complexity**: Smart detection and scaling
- **✅ Quality Gates**: DESIGN minimum 40/50 across all dimensions
- **🎨 Reference Extraction**: Context folder scanning, Figma MCP integration, STYLE.md generation
- **🛠️ Component Stack**: React + TypeScript + shadcn/ui + Tailwind CSS (component-based framework)
- **📦 Preview Required**: MANDATORY preview/demo file for instant visual validation

---

<a id="2-system-architecture"></a>
## 2. 🌳 SYSTEM ARCHITECTURE

```
AGENTS.md → Entry point with routing logic
    ↓
UI Designer (System prompt - 29 core rules)
    ↓
CANVAS Framework (Methodology with cognitive rigor)
    ↓
Interactive Intelligence (Conversation flow)
    ↓
Visual Intelligence (Design philosophy & quality)
    ↓
Component Intelligence (shadcn/ui + reference extraction)
    ↓
Output → /export/[###]-component.tsx + preview
```

---

<a id="3-quick-setup"></a>
## 3. 🚀 QUICK SETUP

### Step 1: Create Claude Project
1. Go to claude.ai → Projects → Create "UI Designer"

### Step 2: Add System Instructions
1. Edit project details → Custom instructions
3. Copy and paste: `UI Designer - v0.102.md` 
4. Save the project

### Step 3: Upload Supporting Documents
Add these documents to your project:

**Core Framework:**
- `UI Designer - CANVAS Thinking Framework - v0.102.md` (6-phase methodology, cognitive rigor, quality validation)
- `UI Designer - Interactive Intelligence - v0.102.md` (conversation patterns, state management, response templates)

**Design & Components:**
- `UI Designer - Visual Intelligence - v0.102.md` (design philosophy, aesthetic decisions, DESIGN quality framework)
- `UI Designer - Component Intelligence - v0.102.md` (shadcn/ui integration, reference extraction, MCP tools, preview strategies)

**Key Advantages:**
- Complete CANVAS methodology with transparent processing
- Automatic complexity scaling and variant generation
- Reference-driven workflows with STYLE.md generation
- Step-by-step confirmation ensuring user control
- Expert visual design with systematic cognitive rigor
- Component-based architecture with shadcn/ui + Tailwind CSS
- Mandatory preview files for instant visual validation

### Step 4: Start Designing
```
design a landing page              # Interactive step-by-step workflow (DEFAULT)
show me 5 login page variants     # Parallel variant exploration
create pricing section             # Step-by-step with confirmations
```

---

<a id="4-interactive-intelligence"></a>
## 4. 💬 INTERACTIVE INTELLIGENCE

### 🎨 Interactive Workflow (Default)

**Purpose:** Step-by-step design creation with user approval at each phase

**Format Features:**
- **MANDATORY Reference Questions** - Always ask at conversation start
- **Comprehensive initial question** - Gather all design requirements at once
- **ASCII wireframe preview** - Show layout structure before implementation
- **Phase-by-phase confirmation** - Layout → Theme → Animation → Generate
- **Multi-perspective transparency** - Show 3-7 expert viewpoints with key insights
- **Quality validation** - DESIGN framework scoring at delivery

**Key Feature:** User controls progression with approval at each design phase

**Workflow:**
```yaml
step_1_discovery:
  questions:
    - "Should I check the /context/Design System/ folder for STYLE.md?"
    - "Should I check the /context/ folder for design references (screenshots/images)?"
    - "Should I check the /context/Design System/ folder for existing CSS design variables?"
    - "Should I check Figma files using Figma MCP for design specifications?"
    - IF references found: "Which creativity mode? (Strict/Balanced/Creative)"
  
  user_provides: [design_type, key_features, target_audience, aesthetic_preferences]

step_2_concept_analysis:
  displays:
    - "🔍 Phase C - Concept"
    - "Analyzing from [X] perspectives"
    - Key insights per perspective (Visual, UX, Technical, Performance, Brand)
    - Synthesis statement
    - Critical assumptions flagged

step_3_layout_confirmation:
  shows: [ASCII wireframe, component hierarchy, responsive breakpoints]
  waits: User approval before proceeding

step_4_theme_confirmation:
  shows: [color palette, typography, spacing system, design tokens]
  waits: User approval before proceeding

step_5_animation_confirmation:
  shows: [interaction patterns, transition timing, animation strategy]
  waits: User approval before proceeding

step_6_generation:
  delivers: React component (.tsx) + preview/demo file
  validates: DESIGN score ≥40/50
```

---

<a id="5-canvas-thinking-framework"></a>
## 5. 🧠 CANVAS THINKING FRAMEWORK

### Two-Layer Transparency Model

**CANVAS** = **C**oncept **A**rchitecture **N**avigation **V**isual **A**nimate **S**hip

A structured 6-phase methodology ensuring exceptional prototypes through **concise transparent excellence** - full rigor applied internally, meaningful updates shown to users.

**Processing Depth:**
- **6 phases** with step-by-step confirmations
- Real-time transparency with user approvals at key decision points

### CANVAS Phases (v0.102 with DESIGN Integration)

| Phase | Purpose | Internal Processing | User Sees |
|-------|---------|---------------------|-----------|
| **C**oncept | Deep understanding | 3-7 perspectives, assumption audit, opposition analysis | "🔍 Analyzing (7 perspectives)" + Key insights |
| **A**rchitecture | Structure & metrics | DESIGN targets, constraint reversal, wireframes | ASCII wireframes, component hierarchy |
| **N**avigation | Interaction design | User flows, states, accessibility, routing | "🗺️ Navigation (flow optimized)" |
| **V**isual | Visual system | Design tokens, typography, color, spacing | Theme design → User confirmation |
| **A**nimate | Motion & polish | Transitions, micro-interactions, performance | Animation design → User confirmation |
| **S**hip | Final delivery | Validation, DESIGN scoring, file generation | "✨ Finalizing (DESIGN: 45/50)" |

### What Users Actually See

**Example CANVAS Progress Updates:**
```markdown
🔍 **Phase C - Concept**
Analyzing from 7 perspectives (Visual Design, UX Flow, Technical Implementation, 
Performance Engineering, Brand/Emotion, Accessibility, Business Value)

**Key Insights:**
- **Visual:** Clean hierarchy with clear focal points, modern sans-serif typography
- **UX:** Frictionless 3-step flow, progressive disclosure reduces cognitive load
- **Technical:** React components with TypeScript, shadcn/ui + Tailwind CSS, Flexbox/Grid layouts
- **Performance:** <100KB total, 60fps animations, lazy-load images
- **Brand:** Professional yet approachable, trustworthy color palette
- **Accessibility:** WCAG 2.1 AA compliant, keyboard navigation, ARIA labels
- **Business:** Clear CTA placement, social proof above fold, mobile-first

**Synthesis:** Modern professional aesthetic with user-centric flow prioritizes 
conversion while maintaining technical performance and accessibility standards.

[Assumes: Desktop-first users] [Assumes: OAuth integration available]

---

🏗️ **Phase A - Architecture**
Building responsive structure with CSS Grid + Flexbox, 8pt spacing system

[ASCII Wireframe shown here - layout preview before implementation]

📱 Breakpoints: Mobile (320px), Tablet (768px), Desktop (1200px)
Ready to proceed with layout? (Type 'yes' to continue)

---

🎨 **Phase V - Visual**
Design system: Modern blue (#2563eb), neutral grays, Inter font family
80+ design tokens generated, consistent 8pt spacing grid

Ready to proceed with theme? (Type 'yes' to continue)

---

✨ **Phase A - Animate**
Smooth transitions (200-300ms), hover states, loading feedback
60fps performance validated, reduced motion support included

Ready to generate prototype? (Type 'yes' to continue)

---

✅ **DESIGN Quality Score: 45/50**
- Quality (Design Excellence): 13/15
- Experience (User Journey): 14/15  
- Structure (Code Organization): 9/10
- Implementation (Technical Quality): 5/5
- Growth (Scalability): 4/5

📦 Generated: [001]-landing-page.tsx + preview.tsx
```

### Cognitive Rigor (Applied Automatically)

Six mandatory frameworks applied internally (users see key insights only):

1. **Multi-Perspective Analysis** - BLOCKING requirement (min 3, target 7) enforced at validation gates
2. **Assumption Audit** - Critical flags shown with explicit `[Assumes: X]` notation
3. **Perspective Inversion** - Key opposition insights integrated into design rationale
4. **Constraint Reversal** - Non-obvious solutions surfaced through backward analysis
5. **Mechanism First** - WHY before WHAT validation ensuring principle-driven design
6. **Pattern Recognition** - Reference extraction and token generation from visual sources

**Quality Targets:** DESIGN ≥40/50 (Quality 12+, Experience 12+, Structure 8+, Implementation 4+, Growth 3+)

**Validation Gates:** Three-phase enforcement (pre-design, during design, post-design) ensures consistent excellence

**Full details:** `UI Designer - CANVAS Thinking Framework - v0.102.md`

---

<a id="6-design-framework"></a>
## 6. 🏗️ DESIGN FRAMEWORK

### Quality Assessment Checklist

**DESIGN** ensures every prototype meets comprehensive quality standards across 5 dimensions:

**D**esign Excellence - Visual Quality (15 points)
- ✅ Visual hierarchy clear and effective (3/3)
- ✅ Color palette harmonious and purposeful (3/3)
- ✅ Typography system consistent and readable (3/3)
- ✅ Spacing system logical and breathing (3/3)
- ✅ Component patterns polished and refined (3/3)

**E**xperience - User Journey (15 points)
- ✅ User flows intuitive and frictionless (3/3)
- ✅ Interactions responsive and delightful (3/3)
- ✅ Feedback immediate and clear (3/3)
- ✅ Accessibility comprehensive (WCAG 2.1 AA) (3/3)
- ✅ Mobile experience optimized (3/3)

**S**tructure - Code Organization (10 points)
- ✅ React components well-structured with proper props (2/2)
- ✅ TypeScript types defined and consistent (2/2)
- ✅ shadcn/ui components properly integrated (2/2)
- ✅ Tailwind CSS classes organized and semantic (2/2)
- ✅ Component architecture clean and reusable (2/2)

**I**mplementation - Technical Quality (5 points)
- ✅ React + TypeScript stack properly implemented (1/1)
- ✅ shadcn/ui components accessible and customizable (1/1)
- ✅ Tailwind CSS utilities optimally used (1/1)
- ✅ Preview/demo file included for validation (1/1)
- ✅ 60fps animations with smooth interactions (1/1)

**G**rowth - Scalability (5 points)
- ✅ Design system expandable (1/1)
- ✅ Components reusable (1/1)
- ✅ Patterns documented (1/1)
- ✅ Easy to fork and iterate (1/1)
- ✅ Production-ready foundation (1/1)

### DESIGN-CANVAS Integration

**How They Work Together:**
- **CANVAS** = The **HOW** (process methodology)
- **DESIGN** = The **WHAT** (quality checklist)
- **Together** = Systematic process + Quality structure = Exceptional prototypes

**Integration Points:**
- Concept Phase → Sets DESIGN dimension targets
- Architecture Phase → Validates Structure scoring
- Navigation Phase → Optimizes Experience metrics
- Visual Phase → Maximizes Design Excellence
- Animate Phase → Enhances Experience and Implementation
- Ship Phase → Final DESIGN verification (≥40/50 required)

### What Users See for DESIGN

**Example DESIGN Communication:**
```markdown
✅ **DESIGN Quality Validation: 45/50**

**D**esign Excellence: 13/15
- Visual hierarchy: Clear focal points, intentional weight (3/3)
- Color palette: Modern blue primary, harmonious neutrals (3/3)
- Typography: Inter font system, readable scales (2/3)
- Spacing: 8pt grid system consistently applied (3/3)
- Component polish: Refined details, subtle shadows (2/3)

**E**xperience: 14/15
- User flows: Intuitive 3-step progression (3/3)
- Interactions: Smooth hover states, clear feedback (3/3)
- Feedback: Immediate response, loading states (3/3)
- Accessibility: WCAG 2.1 AA, keyboard nav, ARIA (3/3)
- Mobile: Responsive breakpoints, touch-optimized (2/3)

**S**tructure: 9/10
- Clean React components, proper TypeScript types, organized Tailwind classes (9/10)

**I**mplementation: 5/5
- React + TypeScript + shadcn/ui, preview included, 60fps animations (5/5)

**G**rowth: 4/5
- Expandable design system, reusable components, documented patterns (4/5)

**Critical Assumptions:**
[Assumes: Desktop-first users] [Assumes: Modern browser support (2020+)]
```

**Full details:** `UI Designer - Visual Intelligence - v0.102.md` (Section 7)