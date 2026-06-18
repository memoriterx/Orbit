# orbit-web-dev

**Next.js App Router fullstack web development preset for the orbit framework.**

This plugin adds web-specific agents, skills, and presets on top of `orbit-base`. It does **not** replace the base — it extends it.

---

## Prerequisites

**`orbit-base` must be installed before `orbit-web-dev`.**

```
/plugin marketplace add <orbit-repo-url>
/plugin install orbit-base
/plugin install orbit-web-dev
```

Installing `orbit-web-dev` alone will result in missing agents (`leader`, `architect`, `builder`, `reviewer`, `researcher`) and missing base skills (`using-orbit`).

---

## What This Plugin Provides

### Agents (4 web-domain agents)

| Agent | Extends | Role |
|-------|---------|------|
| `designer` | — | Web UI/UX designer: wireframes, design tokens, component decomposition |
| `fullstack` | `builder` | Next.js App Router implementer: pages, API routes, external source integration, SEO, deployment config |
| `architect-web` | `architect` | Web architecture designer and post-implementation consistency reviewer: directory structure, shared types, API contracts, caching strategy |
| `qa-web` | `reviewer` | Web QA coordinator: Triple Crown verification with web-specific static checks (API shape, SEO, responsiveness, env vars) |

**Note on naming:** `orbit-base` provides `builder`, `architect`, `reviewer`. This plugin provides `fullstack`, `architect-web`, `qa-web` under different names so both plugins can be installed simultaneously without collision. Use the web-dev agents for Next.js projects; the base agents remain available for non-web tasks.

### Skills (4 web-domain skills)

| Skill | Purpose |
|-------|---------|
| `nextjs-build` | Frontend implementation: pages, components, SEO metadata, next/image |
| `api-build` | Backend implementation: Route Handlers, external source integration, env vars, PM2/Nginx |
| `ui-design` | UI design: wireframes, design tokens, responsive breakpoints, component specs |
| `web-qa` | Static verification: API shape cross-comparison, SEO checks, responsiveness, env var consistency |

### Presets

| File | Purpose |
|------|---------|
| `presets/research-sources.md` | Template for filling `{{RESEARCH_SOURCES}}` on the base `researcher` agent. Provides an example web-business source list (location listing, review platform, social media) with scraping guidelines. |

---

## Domain Slots to Fill

After installing this plugin, fill the following slots in your project's `CLAUDE.md` or agent invocations:

| Slot | Set To |
|------|--------|
| `{{SHARED_TYPES_PATH}}` | Your shared TypeScript interface file (e.g., `types/api.ts`) |
| `{{ARCHITECTURE_DOC_PATH}}` | Your architecture document path (e.g., `_workspace/00_architecture.md`) |
| `{{QUALITY_GATE_CMD}}` | Your verification command (e.g., `tsc --noEmit && next lint`) |
| `{{BEHAVIOR_VERIFICATION_METHOD}}` | Your browser verification tool (e.g., `gstack` skill, manual) |
| `{{RESEARCH_SOURCES}}` | Fill from `presets/research-sources.md` template |

---

## Soft Dependencies

The following plugins are **recommended but not required**:

| Plugin | Provides | Degradation without it |
|--------|---------|----------------------|
| `superpowers` | `requesting-code-review`, `test-driven-development`, etc. | Use manual code review checklist in `reviewer.md` |
| `gstack` | Live browser verification | Use manual browser steps for Triple Crown Prong ② |
| `gsd` | GSD completeness tracking | Use manual roadmap checklist for Triple Crown Prong ① |

Install recommended plugins:
```
/plugin install superpowers
/plugin install gstack
/plugin install gsd
```

---

## Workflow Overview

This plugin integrates with the orbit lifecycle defined by `orbit-base`:

```
roadmap item selected
  → /orbit-cycle: plan (architect-web) → Plan Approval (leader)
  → implement (fullstack, designer)
  → Triple Crown verification (qa-web):
      ① completeness (GSD / roadmap)
      ② behavior (gstack browser)
      ③ quality (web-qa skill + superpowers code review)
  → complete (roadmap checkbox)
```

---

## License

MIT
