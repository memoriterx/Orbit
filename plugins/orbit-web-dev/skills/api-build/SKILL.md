---
name: api-build
description: "Next.js App Router backend API implementation skill. Route Handlers, external data source integration (REST, scrapers, headless CMS), shared TypeScript interfaces, environment variable management, deployment configuration (PM2, Nginx). Use when asked to build APIs, backend routes, external service integration, or deployment configuration."
---

# API Build — Backend Implementation

Implements backend API Route Handlers and external data source integrations for a Next.js App Router project.

## Project Structure Convention

```
app/api/
├── <resource>/
│   └── route.ts            # Route Handler: GET /api/<resource>
lib/
├── <source>/               # External source integration (isolated module)
│   ├── client.ts           # Source client / fetcher
│   └── index.ts            # Public interface
└── env.ts                  # Environment variable validation
types/
└── {{SHARED_TYPES_PATH}}   # Shared TypeScript interfaces (e.g., api.ts)
data/
└── <resource>-mock.json    # Mock fallback data
```

## Shared TypeScript Interfaces

Define shared types before implementing routes. Both frontend and backend reference the same file (`{{SHARED_TYPES_PATH}}`):

```typescript
// types/api.ts (example structure — adapt to your domain)
export interface ResourceItem {
  id: string
  // ... domain-specific fields
  createdAt: string  // ISO 8601
}

export interface ApiResponse<T> {
  data: T
  total?: number
  error?: string
}
```

Define interfaces before writing any route handlers.

## Route Handler Pattern

```typescript
// app/api/<resource>/route.ts
import { NextResponse } from 'next/server'
import { getItems } from '@/lib/<source>'
import type { ResourceItem } from '@/types/api'

export const revalidate = 3600  // ISR: seconds

export async function GET(request: Request): Promise<NextResponse<ResourceItem[]>> {
  try {
    const items = await getItems()
    return NextResponse.json(items)
  } catch (error) {
    // Fallback to mock data when source is unavailable
    const mock = await import('@/data/<resource>-mock.json')
    return NextResponse.json(mock.default)
  }
}
```

Set `revalidate` based on how frequently the data changes:
- High-change data (e.g., reviews, stock): 1-6 hours
- Low-change data (e.g., product catalog): 24 hours
- Static data: `revalidate = false`

## External Data Source Integration

When no official API exists for a data source, isolate the integration:

```
lib/<source>/
├── client.ts       # HTTP fetching, HTML parsing, or SDK calls
└── index.ts        # Public interface — route handlers only import from here
```

**Isolation principle**: route handlers and pages call `lib/<source>` only through the public interface. Implementation details (parsing logic, headers, retry) stay inside the module.

Always include a mock fallback:
```typescript
// lib/<source>/index.ts
export async function getItems(): Promise<ResourceItem[]> {
  if (!process.env.SOURCE_ID) {
    console.warn('SOURCE_ID not set. Using mock data.')
    return import('@/data/<resource>-mock.json').then(m => m.default)
  }
  // ... actual fetch
}
```

## Environment Variable Management

Create `.env.local.example` alongside the implementation:

```bash
# .env.local.example
# Required
RESOURCE_SOURCE_ID=       # ID for your data source

# Optional — enables live data if set; falls back to mock if absent
EXTERNAL_API_KEY=
EXTERNAL_API_SECRET=
```

Handle missing variables gracefully:
```typescript
// lib/env.ts
export function requireEnv(key: string): string {
  const value = process.env[key]
  if (!value) throw new Error(`Missing required environment variable: ${key}`)
  return value
}
```

## Deployment Configuration

**PM2 (ecosystem.config.js):**
```javascript
module.exports = {
  apps: [{
    name: '{{APP_NAME}}',
    script: 'node_modules/.bin/next',
    args: 'start',
    env: {
      PORT: 3000,
      NODE_ENV: 'production'
    }
  }]
}
```

**Nginx reverse proxy (nginx/{{APP_NAME}}.conf):**
```nginx
server {
  listen 80;
  server_name {{DOMAIN}};

  location / {
    proxy_pass http://localhost:3000;
    proxy_http_version 1.1;
    proxy_set_header Upgrade $http_upgrade;
    proxy_set_header Connection 'upgrade';
    proxy_set_header Host $host;
    proxy_cache_bypass $http_upgrade;
  }
}
```

Replace `{{APP_NAME}}` and `{{DOMAIN}}` with your project's actual values.

## Output Format

Report results as text output to leader. Include:
- Environment variable list (with `.env.local.example` content)
- Endpoint inventory (method + path + caching strategy)
- TypeScript interface definitions
- External source integration approach (live vs. mock)
- Deployment config summary
- Any architecture clarification needed
