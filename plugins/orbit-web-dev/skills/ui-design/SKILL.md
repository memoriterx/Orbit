---
name: ui-design
description: "Web UI/UX design skill for Next.js projects. Wireframe creation, component decomposition, color/typography token definition, mobile-first responsive layout design. Use when asked to design, wireframe, plan layouts, define component structure, propose color palette, or design brand-aligned visuals."
---

# UI Design — Web UI/UX Design

Designs the visual structure and layout of web pages for Next.js projects.

## Design Principles

Design is driven by the project's brand brief and content requirements. Without a brief, default to a clean, content-forward aesthetic:
- Readable body typography (sans-serif, sufficient contrast)
- Neutral backgrounds with a single accent color for CTAs
- Mobile-first, minimal interaction, content center-stage
- Semantic HTML structure (one `<h1>` per page, logical heading hierarchy)

When a brand brief is provided (e.g., a craft studio, a SaaS product, an e-commerce store), adapt the palette, typography, and layout patterns accordingly.

## Task Sequence

### 1. Design Token Definition

Propose Tailwind-compatible design tokens:

```typescript
// tailwind.config.ts additions
colors: {
  brand: {
    background: '#...',  // Page background
    surface:    '#...',  // Card / section background
    primary:    '#...',  // Primary CTA, links
    text:       '#...',  // Body text
    muted:      '#...',  // Secondary text, captions
  }
},
fontFamily: {
  display: [..., 'serif'],    // Headings
  body:    [..., 'sans-serif'], // Body text
}
```

Document the rationale for each token (brand alignment, contrast ratio, WCAG compliance where relevant).

### 2. Per-Page Layout Design

For each project page, produce an ASCII wireframe or structured description:

```
[Header: Logo + Navigation links]
[Hero: Large image/video + headline + CTA button]
[Content Section: Grid or list of items]
[Supporting Section: Social proof, features, etc.]
[Footer: Links + contact info]
```

Adapt to the project's actual page list. Fewer pages → more detail per page.

### 3. Component Decomposition

Break each page into Next.js-implementable components:

| Component | Type | Key Props | Notes |
|-----------|------|-----------|-------|
| `Header` | Server | - | Sticky, navigation links |
| `HeroSection` | Server | `headline`, `subtext`, `ctaText` | Above-the-fold priority |
| `ItemCard` | Server | `item: ItemType` | Used in grids |
| `InteractiveWidget` | Client | `items: ItemType[]` | Needs `"use client"` |

Explain Server vs Client assignment: Server for rendering and SEO; Client only for `useState`, `useEffect`, or browser events.

### 4. Responsive Breakpoints

Use Tailwind's default breakpoint system:

| Breakpoint | Min Width | Typical Layout |
|-----------|-----------|----------------|
| default (mobile) | 0px | Single column, large touch targets |
| `md:` | 768px | Two-column grid, optional sidebar |
| `lg:` | 1024px | Three-column grid, wider margins |

Apply consistently:
```
grid-cols-1 md:grid-cols-2 lg:grid-cols-3
```

Define touch target minimums: interactive elements ≥ 44px in both dimensions.

## Output Format

Report results as text output to the leader. Include:
- Design tokens (colors, typography, spacing scale)
- Per-page layout (wireframe or description)
- Component table with type, props, Server/Client reason
- Responsive breakpoint definitions
- Any brand assumptions noted if brief was incomplete
