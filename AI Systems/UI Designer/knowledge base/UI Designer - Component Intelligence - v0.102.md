# UI Designer - Component Intelligence

Component architecture, reference extraction, and shadcn/ui integration for rapid prototyping.

**Core Purpose:** Define shadcn/ui component usage, visual reference extraction workflows, token generation, and creative control modes for systematic design system application.

**Scope:** Component selection, reference extraction, token application, MCP tools, preview strategies. For design philosophy, see `UI Designer - Visual Intelligence`. For thinking methodology, see `UI Designer - CANVAS Thinking Framework`.

---

## 📋 TABLE OF CONTENTS

1. [🎯 OVERVIEW](#1-overview)
2. [📸 REFERENCE EXTRACTION](#2-reference-extraction)
3. [🎨 TOKEN EXTRACTION](#3-token-extraction)
4. [🎛️ CREATIVE CONTROL MODES](#4-creative-control-modes)
5. [📦 SHADCN/UI COMPONENTS](#5-shadcnui-components)
6. [🔌 MCP SERVER INTEGRATION](#6-mcp-server-integration)
7. [🔨 USAGE PATTERNS](#7-usage-patterns)
8. [👁️ PREVIEW STRATEGIES](#8-preview-strategies)
9. [📁 FILE VERSIONING](#9-file-versioning)
10. [✅ QUALITY CHECKLIST](#10-quality-checklist)
11. [🏎️ QUICK REFERENCE](#11-quick-reference)

---

## 1. 🎯 OVERVIEW

### Integrated Workflow

**Process:** User shows reference → Tokens extracted → Map to shadcn components → Creative mode applied → Design generated

**Why This Works:**
- **Precision** - Exact hex values, spacing, typography from visual sources
- **Speed** - Show design vs 500-word description
- **Consistency** - Build design systems from real examples
- **Component-based** - shadcn/ui provides accessible, customizable foundation
- **Flexibility** - Control adherence through creative modes (10-50% deviation)

### Reference Sources

| Source | Location | Best For |
|--------|----------|----------|
| **Context Folder** | `/context/` | Project references, batch processing |
| **Chat Upload** | Drag & drop | Quick iterations, single references |
| **Figma MCP** | Via integration | Direct design file access |
| **URL Screenshots** | Web pages | Live site analysis |

### Component Philosophy

shadcn/ui provides **unstyled, accessible base components** that serve as the foundation for all UI prototypes:
- **Copy-paste friendly** - Not installed as dependencies
- **Customizable** - Style with Tailwind CSS
- **Accessible** - Built with Radix UI primitives
- **Type-safe** - Full TypeScript support

---

## 2. 📸 REFERENCE EXTRACTION

### 5-Step Extraction Pipeline

```yaml
step_1_detection:
  - Scan /context/ folder or detect uploaded images
  - Support: PNG, JPG, JPEG, WebP, SVG
  - Auto-categorize by dimensions (desktop/mobile/tablet)

step_2_visual_analysis:
  - Identify UI elements (buttons, forms, cards, navigation)
  - Map layout structure (grid systems, flexbox patterns)
  - Analyze visual hierarchy

step_3_token_extraction:
  colors: Extract hex values → Build semantic palette → Calculate contrast ratios
  typography: Identify fonts → Measure sizes/line-heights → Calculate scale ratio
  spacing: Measure padding/margins → Detect grid system → Build spacing scale
  effects: Extract shadows → Identify borders → Detect gradients

step_4_pattern_inference:
  - Identify interaction states (hover, active, focus, disabled)
  - Map navigation flow
  - Extract component patterns

step_5_component_mapping:
  - Map UI patterns to shadcn/ui components
  - Document customization strategy
  - Generate component selection list
```

### STYLE.md Auto-Generation

```yaml
style_md_workflow:
  when: "References detected + no STYLE.md exists"
  
  token_aggregation:
    sources: [images, figma_mcp, css_variables]
    priority: "Figma > CSS variables > Visual references"
    conflicts: "Ask user which to use"
  
  populate_style_md:
    colors: Hex values + semantic mappings + WCAG validation
    typography: Font families + type scale + line-heights
    spacing: Grid system (4px/8px) + spacing scale
    effects: Shadows + border radius + animation timings
    components: Button variants + form patterns + navigation
    layout: Breakpoints + grid systems + container widths
    accessibility: Contrast ratios + WCAG compliance + focus indicators
  
  save_location: "/context/Design System/STYLE.md"
  
  update_existing:
    trigger: "STYLE.md exists + new references"
    ask: "Update STYLE.md with new tokens or keep existing?"
    options: [merge, replace, keep]
```

### Figma MCP Integration Workflow

**MANDATORY PRE-FLIGHT:** Always ask at conversation start: "Should I check Figma files using Figma MCP for design specifications?" (unless user already specified)

#### Quick Setup (3 Steps)
1. Generate Figma API token: `Figma Settings → Account → Personal Access Tokens`
2. Add to MCP config: `FIGMA_API_TOKEN=your_token` in Claude Desktop MCP settings
3. Test connection: Use `figma_list_files` tool

#### 7-Step Extraction Process

```yaml
figma_extraction_flow:
  step_1_preflight: "Ask user: 'Check Figma files using MCP?'"
  
  step_2_connect: 
    tools: [figma_list_files, figma_get_file]
    input: "Figma URL or file key"
    output: "File structure + metadata"
  
  step_3_creative_mode:
    ask: "Apply as: Strict/Balanced/Creative?"
    default: "Balanced"
  
  step_4_extract_styles:
    colors: "Paint styles → Hex values + semantic mapping"
    typography: "Text styles → Font families, sizes, weights, line-heights"
    effects: "Shadow/blur styles → CSS box-shadow, filter values"
    spacing: "Auto Layout → Padding, gap, margins (8px grid)"
  
  step_5_extract_components:
    structure: "Component definitions, variants, properties"
    states: "Map variant properties to CSS classes"
    docs: "Component descriptions and usage notes"
  
  step_6_map_to_shadcn:
    action: "Identify which shadcn/ui components match Figma patterns"
    output: "Component selection list with customization strategy"
  
  step_7_apply_creative_mode:
    strict: "Use exact values, ≤10% deviation"
    balanced: "Match aesthetic + optimize for web, 10-25% deviation"
    creative: "Inspired interpretation + modern enhancements, 25-50% deviation"
```

### Batch Screenshot Processing

```yaml
batch_processing:
  scenario: "Multiple reference images in /context/"
  workflow:
    1. Scan all images in /context/ folder
    2. Group by similarity (desktop/mobile, component/page)
    3. Extract tokens from each group
    4. Map to shadcn/ui components
    5. Consolidate into unified design system
    6. Flag inconsistencies for user review
  
  output_options:
    - Single STYLE.md (merged tokens)
    - Component mapping list (shadcn selections)
    - Both (comprehensive documentation)
  
  conflict_resolution:
    - Detect varying values (e.g., primary color differs between images)
    - Present options to user
    - Allow user to specify "use most common" or "use specific image as source of truth"
```

---

## 3. 🎨 TOKEN EXTRACTION

### Token Categories

```yaml
colors:
  extract: All hex values from reference
  build: Primitive tokens (gray-50 to gray-900, color-500 scales)
  semantic: primary, secondary, success, error, text, background, surface
  validate: WCAG AA (4.5:1 min) + WCAG AAA (7:1 critical text)
  shadcn_mapping:
    - Map extracted colors to shadcn CSS variables (--primary, --secondary, etc.)
    - Extend Tailwind config with brand-specific color scales
    - Generate HSL values for shadcn's color system

typography:
  identify: Character shapes → Google Fonts database → Closest alternatives
  measure: Font sizes + line-heights + weights
  calculate: Scale ratio (usually 1.125 - 1.333)
  output: Type scale (xs: 0.75rem → 4xl: 2.25rem)
  fallback: Exact match → Similar Google Font → System font
  shadcn_mapping:
    - Apply fonts via Tailwind config fontFamily extension
    - Use Tailwind typography classes (text-sm, text-base, text-lg, etc.)
    - Define custom classes for brand-specific typography

spacing:
  detect: Grid system (4px, 8px, 12px, or 16px base)
  measure: All padding/margin values
  build: Spacing scale (0: 0 → 20: 5rem)
  apply: Consistent throughout design
  shadcn_mapping:
    - Map to Tailwind spacing classes (p-4, m-6, space-y-4, etc.)
    - Use shadcn component padding patterns (Button, Card, Dialog)
    - Extend Tailwind config for custom spacing values if needed

effects:
  shadows: offset + blur + spread + color
  borders: width + style + radius
  gradients: type + angle + stops
  other: opacity + blur effects
  shadcn_mapping:
    - Apply via Tailwind shadow utilities (shadow-sm, shadow-md, etc.)
    - Extend with custom shadow definitions in Tailwind config
    - Use shadcn's border radius system (rounded-lg, rounded-md, etc.)
```

---

## 4. 🎛️ CREATIVE CONTROL MODES

**Strict Mode (≤10% deviation)** - Pixel-perfect replication
- Exact colors, spacing, typography | No substitutions | Preserve all relationships
- Use: Brand guidelines, client mockups, legal requirements

**Balanced Mode (10-25% adaptation)** [DEFAULT] - Web-optimized
- WCAG AA accessibility | 8px grid normalization | Modern CSS features | Responsive behavior
- Use: Production sites, modern web apps

**Creative Mode (25-50% interpretation)** - Design inspiration
- Explore palettes, pairings, modern effects | Innovative layouts | Advanced interactions
- Use: Portfolio, exploration, innovation

### Mode Comparison
| Aspect | Strict | Balanced | Creative |
|--------|--------|----------|----------|
| Color | 95%+ exact | 85% + WCAG | 60% inspired |
| Typography | Exact/closest | Optimized web font | Creative pairing |
| Spacing | Pixel-perfect | Grid-normalized | Rhythm-based |
| Layout | 90%+ match | Responsive-optimized | Modern interpretation |
| Effects | Replicated | Performance-optimized | Trend-enhanced |
| Components | Exact shadcn match | shadcn + customization | shadcn + innovation |

---

## 5. 📦 SHADCN/UI COMPONENTS

### Available Components

**Form Components:**
`Button`, `Input`, `Textarea`, `Select`, `Checkbox`, `RadioGroup`, `Switch`, `Slider`, `Label`, `Form`

**Layout Components:**
`Card`, `Separator`, `Tabs`, `Accordion`, `Collapsible`, `ScrollArea`, `AspectRatio`

**Overlay Components:**
`Dialog`, `Sheet`, `AlertDialog`, `Popover`, `HoverCard`, `Tooltip`, `DropdownMenu`, `ContextMenu`

**Navigation Components:**
`NavigationMenu`, `Breadcrumb`, `Pagination`, `Command`

**Feedback Components:**
`Alert`, `Toast`, `Progress`, `Badge`, `Avatar`, `Skeleton`

**Data Display:**
`Table`, `DataTable`, `Calendar`, `Carousel`

### Component Selection Matrix

| Design Need | Primary Component | Alternative | Notes |
|-------------|-------------------|-------------|-------|
| Call-to-action | `Button` | - | Use variant prop for styles |
| Form input | `Input` + `Label` | `Textarea` for multi-line | Wrap in `Form` for validation |
| Dropdown selector | `Select` | `Combobox` for search | Select for simple, Combobox for large lists |
| Modal dialog | `Dialog` | `Sheet` for mobile | Sheet slides from side |
| Action menu | `DropdownMenu` | `ContextMenu` | ContextMenu for right-click |
| Content container | `Card` | `div` with Tailwind | Card provides semantic structure |
| Navigation | `NavigationMenu` | `Tabs` for views | NavigationMenu for site nav |
| Status indicator | `Badge` | `Alert` for messages | Badge for inline, Alert for blocks |
| Notification | `Toast` | `Alert` | Toast for temporary, Alert for persistent |
| Data grid | `DataTable` | `Table` | DataTable for features, Table for simple |

---

## 6. 🔌 MCP SERVER INTEGRATION

### shadcn-ui MCP Server

**Configuration:** Automatically configured in `.mcp.json` and `.vscode/mcp.json`

### Available MCP Tools

```yaml
mcp_tools:
  list_shadcn_components:
    purpose: "Get complete list of available shadcn/ui components"
    usage: "Initial planning, component discovery"
  
  get_component_details:
    purpose: "Fetch detailed info about specific component"
    input: "Component name (e.g., 'button', 'dialog')"
    output: "Props, variants, usage patterns, dependencies"
  
  get_component_examples:
    purpose: "Get code examples for component"
    input: "Component name"
    output: "Multiple usage examples with variations"
  
  search_components:
    purpose: "Find components by keyword"
    input: "Search query (e.g., 'modal', 'form')"
    output: "Relevant components matching query"
```

### MCP Workflow

```yaml
component_selection_flow:
  step_1_analyze_need:
    action: "Analyze design requirements from references"
    questions:
      - "What UI pattern is needed?"
      - "What user interactions are required?"
      - "What states must be supported?"
  
  step_2_search_components:
    tool: "search_components OR list_shadcn_components"
    action: "Find matching base components"
  
  step_3_get_details:
    tool: "get_component_details"
    action: "Review props, variants, examples"
  
  step_4_select_base:
    action: "Choose most appropriate base component"
    criteria:
      - "Matches interaction pattern from reference"
      - "Supports required states"
      - "Minimal customization needed"
  
  step_5_get_examples:
    tool: "get_component_examples"
    action: "Review usage patterns for implementation guidance"
```

---

## 7. 🔨 USAGE PATTERNS

### Reference to Component Pipeline

```yaml
reference_to_component_workflow:
  step_1_extract_tokens:
    action: "Extract colors, typography, spacing, effects from references"
    output: "Design token set"
  
  step_2_map_components:
    action: "Identify UI patterns in references"
    map_to: "shadcn/ui components (Button, Card, Form, etc.)"
    output: "Component selection list with customization notes"
  
  step_3_apply_to_tailwind:
    action: "Extend Tailwind config with extracted tokens"
    config:
      colors: "Brand color scales mapped to Tailwind palette"
      fonts: "Custom font families added to fontFamily"
      spacing: "Custom spacing values if needed"
      shadows: "Brand-specific shadow definitions"
  
  step_4_customize_shadcn:
    action: "Apply tokens to shadcn base components"
    methods:
      - "Tailwind utility classes (className prop)"
      - "CSS variable overrides (--primary, --secondary, etc.)"
      - "Component variant extensions (CVA)"
  
  step_5_generate_components:
    action: "Output .tsx files with shadcn imports + customization"
    structure:
      - "Component file with TypeScript types"
      - "Preview/demo file for instant validation"
      - "Updated Tailwind config if needed"
```

### Customization Approach

#### 1. Start with Base Component
```tsx
import { Button } from '@/components/ui/button'

<Button>Click me</Button>
```

#### 2. Customize with Tailwind
```tsx
<Button className="bg-brand-500 hover:bg-brand-600 text-white">
  Click me
</Button>
```

#### 3. Extend with Variants (CVA)
```tsx
import { cva } from "class-variance-authority"

const buttonVariants = cva(
  "base-classes",
  {
    variants: {
      variant: {
        brand: "bg-brand-500 hover:bg-brand-600",
        outline: "border-brand-500 text-brand-500"
      }
    }
  }
)

<Button className={buttonVariants({ variant: "brand" })}>
  Click me
</Button>
```

### Component Pattern Mapping Examples

| Reference Pattern | shadcn Component | Customization Strategy |
|-------------------|------------------|------------------------|
| Primary CTA button | `Button` | `className="bg-brand-500 hover:bg-brand-600"` |
| Content card | `Card` | `className="p-6 rounded-brand shadow-brand"` |
| Modal dialog | `Dialog` | Customize `DialogContent` with brand colors |
| Form inputs | `Input`, `Select` | Apply focus rings with brand colors |
| Navigation menu | `NavigationMenu` | Style with brand typography + spacing |
| Data table | `Table` | Apply zebra striping, brand borders |
| Toast notifications | `Toast` | Semantic colors mapped to brand palette |

---

## 8. 👁️ PREVIEW STRATEGIES

### Preview File Template

**MANDATORY:** Every component export must include a preview/demo file for instant visual testing.

```tsx
// component-name-preview.tsx
import React from 'react'
import { ComponentName } from './component-name'

export default function ComponentNamePreview() {
  return (
    <div className="min-h-screen bg-gray-50 p-8">
      <div className="max-w-7xl mx-auto space-y-12">
        
        {/* Preview Header */}
        <header className="space-y-2">
          <h1 className="text-4xl font-bold">ComponentName Preview</h1>
          <p className="text-gray-600">All variants and states</p>
        </header>

        {/* Default State */}
        <section className="space-y-4">
          <h2 className="text-2xl font-semibold">Default</h2>
          <div className="bg-white p-8 rounded-lg shadow">
            <ComponentName title="Default Example" />
          </div>
        </section>

        {/* Variants Grid */}
        <section className="space-y-4">
          <h2 className="text-2xl font-semibold">All Variants</h2>
          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
            <div className="bg-white p-6 rounded-lg shadow">
              <h3 className="text-sm font-medium text-gray-500 mb-4">Primary</h3>
              <ComponentName variant="primary" />
            </div>
            <div className="bg-white p-6 rounded-lg shadow">
              <h3 className="text-sm font-medium text-gray-500 mb-4">Secondary</h3>
              <ComponentName variant="secondary" />
            </div>
          </div>
        </section>

        {/* States */}
        <section className="space-y-4">
          <h2 className="text-2xl font-semibold">States</h2>
          <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
            <div className="bg-white p-6 rounded-lg shadow">
              <h3 className="text-sm font-medium text-gray-500 mb-4">Loading</h3>
              <ComponentName loading />
            </div>
            <div className="bg-white p-6 rounded-lg shadow">
              <h3 className="text-sm font-medium text-gray-500 mb-4">Disabled</h3>
              <ComponentName disabled />
            </div>
          </div>
        </section>

      </div>
    </div>
  )
}
```

### Preview Best Practices

```yaml
preview_checklist:
  visual_completeness:
    - [ ] All variants shown
    - [ ] All states demonstrated (default, hover, focus, active, disabled, loading, error)
    - [ ] Responsive breakpoints visible
    - [ ] Interactive elements functional
  
  organization:
    - [ ] Clear section headings
    - [ ] Grouped by variant/state
    - [ ] Labeled with context
    - [ ] Consistent spacing
  
  usability:
    - [ ] Easy to scan visually
    - [ ] Background contrast for visibility
    - [ ] Grid layout for comparison
    - [ ] Mobile-friendly preview layout
```

---

## 9. 📁 FILE VERSIONING

### Iteration Tracking System

```yaml
initial_design:
  format: "{design_name}_{n}.tsx"
  example: "dashboard_1.tsx, login_2.tsx"
  location: "/export/[###]-{design_name}/"

iterations:
  format: "{original_name}_{iteration}.tsx"
  example: "dashboard_1.tsx → dashboard_1_1.tsx → dashboard_1_2.tsx"
  rule: "Never edit original, always create new iteration file"

version_tracking:
  sequential: "Auto-increment [###] prefix (001, 002, 003...)"
  descriptive: "Meaningful names with context"
  variants: "Add variant suffix: dashboard_1_minimal.tsx, dashboard_1_bold.tsx"
```

### Complete Example Structure
```
/export/
  ├── 001-dashboard/
  │   ├── dashboard_1.tsx              # Initial design
  │   ├── dashboard_1_1.tsx            # First iteration
  │   ├── dashboard_1_minimal.tsx      # Variant: Minimalist
  │   ├── dashboard_1-preview.tsx      # Preview file
  │   └── README.md
  ├── 002-login/
  │   ├── login_2.tsx
  │   ├── login_2-preview.tsx
  │   └── README.md
```

---

## 10. ✅ QUALITY CHECKLIST

### Component Quality Validation

```yaml
quality_gates:
  reference_extraction:
    - [ ] Tokens extracted accurately (colors, typography, spacing, effects)
    - [ ] Creative mode applied appropriately
    - [ ] WCAG AA contrast validated
    - [ ] Grid system detected correctly
  
  component_selection:
    - [ ] Used most appropriate shadcn base component
    - [ ] Leveraged existing variants when possible
    - [ ] Minimized custom component creation
    - [ ] Documented component selection rationale
  
  customization:
    - [ ] Applied Tailwind classes for brand alignment
    - [ ] Preserved accessibility attributes from shadcn
    - [ ] Used semantic color tokens
    - [ ] Implemented responsive classes (sm:, md:, lg:)
  
  typescript:
    - [ ] Defined proper prop interfaces
    - [ ] Used TypeScript for all files (.tsx, .ts)
    - [ ] Exported types for reusability
  
  states:
    - [ ] Implemented hover states
    - [ ] Implemented focus states
    - [ ] Implemented disabled states
    - [ ] Implemented loading states (when applicable)
    - [ ] Implemented error states (for forms)
  
  preview:
    - [ ] Created preview/demo file (MANDATORY)
    - [ ] Showed all variants
    - [ ] Demonstrated all states
    - [ ] Included responsive examples
  
  versioning:
    - [ ] Used correct file naming convention
    - [ ] Never edited original file
    - [ ] Created iteration files for changes
```

---

## 11. 🏎️ QUICK REFERENCE

### Extraction Commands

- `$extract strict` - Pixel-perfect replication with shadcn components (≤10%)
- `$extract` - Balanced mode: shadcn base + web optimization [DEFAULT]
- `$extract creative` - Creative interpretation using shadcn foundation (25-50%)
- `$extract tokens` - Tokens only mapped to Tailwind config
- `$extract batch` - Process all Context folder references with shadcn mapping

### MCP Commands

```typescript
// List all available components
list_shadcn_components()

// Get component details
get_component_details({ componentName: "button" })

// Get usage examples
get_component_examples({ componentName: "dialog" })

// Search for components
search_components({ query: "modal" })
```

### Component Selection Quick Guide

| Need | Component | Customization |
|------|-----------|---------------|
| Button | `Button` | `variant` + `size` + Tailwind |
| Modal | `Dialog` | `DialogContent` styling |
| Form | `Form` + `Input` | Validation + error states |
| Card | `Card` | Tailwind for shadows/borders |
| Menu | `DropdownMenu` | Menu items + icons |
| Nav | `NavigationMenu` | Active states + Tailwind |
| Notification | `Toast` | Semantic variants |

### CANVAS Integration

**Phase Integration with CANVAS:**

> **🧠 Complete CANVAS Methodology:** See `UI Designer - CANVAS Thinking Framework` for full 6-phase process details.

**Component Intelligence supports CANVAS phases:**
- **Phase C (Concept):** Reference detection, token extraction, creative mode selection
- **Phase A (Architecture):** Component hierarchy, shadcn base selection
- **Phase V (Visual):** Tailwind customization, brand token application
- **Phase A (Animate):** Interaction states, transition timing
- **Phase S (Ship):** Component generation, preview files, delivery

### File Structure Template

```
/export/###-component-name/
  ├── component-name.tsx          (Main component with shadcn imports)
  ├── component-name-preview.tsx  (Visual preview - MANDATORY)
  ├── component-name.types.ts     (TypeScript types)
  └── README.md                   (Documentation)
```

---

*Component Intelligence enables systematic reference extraction, token application, and shadcn/ui integration with flexible creative control for rapid, accessible, high-quality prototyping. For complete CANVAS methodology, see `UI Designer - CANVAS Thinking Framework`.*
