---
name: nextjs-build
description: "Next.js App Router frontend implementation skill. Page components, Tailwind CSS responsive layouts, SEO metadata (generateMetadata), Server/Client component separation, API data fetching, next/image optimization. Use when asked to implement pages, write frontend code, set up SEO, or build components."
---

# Next.js Build — Frontend Implementation

Implements pages and components for a Next.js 14+ App Router web project.

## Project Structure Convention

```
app/
├── layout.tsx              # Root layout (shared Header, Footer)
├── page.tsx                # Home (/)
├── <section>/
│   └── page.tsx            # Section page
components/
├── layout/                 # Header, Footer, Nav
└── ui/                     # Reusable presentational components
types/
└── {{SHARED_TYPES_PATH}}   # Shared TypeScript interfaces (e.g., api.ts)
```

Adapt to your project's actual page structure. Document deviations.

## Server vs Client Components

App Router defaults to Server Components. Use Client Components only when needed:

**Server Component** — data fetching, static rendering, SEO-sensitive areas, no browser APIs
**Client Component** (`"use client"` directive) — `useState`, `useEffect`, event handlers, browser APIs

Carousels, modals, interactive forms → Client. Everything else → Server.

## SEO Implementation

Define `metadata` or `generateMetadata()` on each page:

```typescript
// Static metadata (app/page.tsx)
export const metadata: Metadata = {
  title: '{{PAGE_TITLE}}',
  description: '{{PAGE_DESCRIPTION}}',
  openGraph: {
    title: '{{OG_TITLE}}',
    description: '{{OG_DESCRIPTION}}',
    images: ['/og-image.jpg'],
  },
}

// Dynamic metadata (pages with async data)
export async function generateMetadata(): Promise<Metadata> {
  return {
    title: '{{DYNAMIC_PAGE_TITLE}}',
    description: '{{DYNAMIC_PAGE_DESCRIPTION}}',
  }
}
```

Add JSON-LD structured data to the home page via `<script type="application/ld+json">`.
Use schema.org types appropriate for the business (e.g., `LocalBusiness`, `Product`, `Organization`).

## Data Fetching in Server Components

Fetch data in Server Components with explicit caching:

```typescript
// Short-lived data (e.g., user reviews): 1-6 hour revalidation
const items = await fetch(`${process.env.NEXT_PUBLIC_API_BASE}/api/resource`, {
  next: { revalidate: 3600 }
}).then(r => r.json())

// Long-lived data (e.g., product catalog): 24-hour revalidation
const catalog = await fetch(`${process.env.NEXT_PUBLIC_API_BASE}/api/catalog`, {
  next: { revalidate: 86400 }
}).then(r => r.json())
```

If the backend API is incomplete, use mock data and mark with `// TODO: replace with live API`.

## Image Optimization

Always use `next/image`. Never use bare `<img>` tags:

```typescript
import Image from 'next/image'

<Image
  src="/path/to/image.jpg"
  alt="Descriptive alt text"
  width={1200}
  height={600}
  priority    // Hero/above-the-fold images only
  className="object-cover"
/>
```

## Responsive Layout with Tailwind

Mobile-first class ordering:

```
// Single column → 2 columns at md → 3 columns at lg
<div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
```

Minimum touch target size: `min-h-[44px] min-w-[44px]` for interactive elements.

## Output Format

Report results as text output to leader. Include:
- File list (created/modified)
- Each file's key implementation choices
- API integration points
- Mock data items with TODO markers
- Any architecture clarification needed
