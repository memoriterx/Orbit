---
name: web-qa
description: "Web static quality verification skill. Frontend-backend API shape cross-comparison, SEO metadata verification, mobile responsiveness check, environment variable consistency, Next.js build error prediction. Use when asked to QA, verify, test, find bugs, check SEO, or validate frontend-backend connection. Live browser verification is delegated to the behavior verification tool (e.g., gstack)."
---

# Web QA — Static Quality Verification

Verifies integration quality of a Next.js web project through static analysis and cross-comparison. Does not run the browser — live behavior verification is handled by the behavior verification tool.

## Core Principle

**Cross-comparison at boundaries** — do not just check for existence. Read both sides simultaneously:
- What does the frontend component *access* from API responses?
- What does the API route *actually return*?
- Are both consistent with `{{SHARED_TYPES_PATH}}`?

Verify incrementally as modules complete, not all at once at the end.

## Verification Checklist

### 1. API Shape Cross-Comparison (highest priority)

```
[Frontend access pattern]      [Backend return shape ({{SHARED_TYPES_PATH}})]
<component>.<field>    vs     <Interface>.<field>
```

Steps:
1. Extract all API response field accesses from `app/` and `components/` files
2. Cross-reference against `{{SHARED_TYPES_PATH}}`
3. List every mismatch with `file:line — description`

Common failure patterns:
- Frontend uses `item.authorName`, types define `item.author`
- Frontend expects `number`, types define `string`
- Frontend accesses a field that is optional in types without a null check

### 2. SEO Verification

For each page:
- `<title>` present and sized appropriately (40-60 characters recommended)
- `<meta name="description">` present (120-160 characters recommended)
- Open Graph: `og:title`, `og:description`, `og:image` present
- Home page: JSON-LD structured data block present
- Exactly one `<h1>` per page
- No bare `<img>` tags — only `next/image`
- All images have descriptive `alt` attributes

### 3. Mobile Responsiveness

- Class ordering is mobile-first: base → `md:` → `lg:`
- Grids use the pattern: `grid-cols-1 md:grid-cols-2 lg:grid-cols-3`
- Interactive elements have minimum touch target: `min-h-[44px] min-w-[44px]`
- Body text is at least `text-sm` (14px) on mobile

### 4. Environment Variable Consistency

- All `process.env.*` references in source code appear in `.env.local.example`
- Missing variables produce a clear warning or error (not a silent undefined)
- Graceful fallback behavior is implemented (mock data or explicit error state)

### 5. Next.js Build Error Prediction

Scan for these patterns before running `next build`:
- `useState` or `useEffect` in a Server Component (missing `"use client"`)
- Event handlers (`onClick`, `onChange`) in a Server Component
- Bare `<img>` tags (lint error in Next.js with `@next/next/no-img-element`)
- Undefined type references or missing imports
- `"use client"` directive not at the top of the file

## Bug Report Format

```markdown
### Bug #N: [Short description]
- **File**: path/to/file.tsx
- **Location**: line N — `relevant code`
- **Problem**: [specific mismatch or violation]
- **Fix direction**: [concrete suggestion]
```

## Scope Boundary

This skill covers **static verification only**:
- Code reading and cross-comparison
- Type interface conformance
- SEO pattern analysis
- Responsiveness pattern analysis
- Build error prediction

**Live browser verification** (page load, click interactions, screenshots, rendering) is out of scope. Delegate to the behavior verification tool (e.g., gstack browser skill).

## Output Format

Report verification results as text output to leader. Include:
- Summary table (total checks / pass / fail / unverified)
- All bugs found (file:line format)
- SEO results per page
- Mobile responsiveness findings
- Environment variable consistency results
- Items that need live browser verification (to be delegated)
