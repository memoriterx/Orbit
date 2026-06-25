# Planner/Architect Responsibility Split — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Introduce a new `planner` agent to orbit-base that owns discovery, requirements analysis, planning, and prioritization (the "what/why"), so that `architect` narrows to system design, schema definition, and architecture-consistency review (the "how") — relieving the overloaded architect and aligning with the OMC planner/architect split.

**Architecture:** Add `plugins/orbit-base/agents/planner.md` (new, opus-tier strategic planning consultant). Redefine `architect.md` to drop discovery/requirements/planning and keep system design + arch-consistency lens. Update the lifecycle so `planner` owns `writing-plans` and the architect performs a **design review pass** on the planner's plan before the high-risk/critic gate. Propagate the 7→8 roster and the new lifecycle across every surface that names the roster or describes the lifecycle: `CLAUDE.md`, `using-orbit/SKILL.md`, `leader.md`, `codex-tools.md`, `gemini-tools.md`, both `plugin.json` manifests, `orbit-cycle.md`, `skillify/SKILL.md`, `builder.md`, `reviewer.md`, `explore.md`. All edits are documentation/prompt markdown + JSON manifest — there is no executable code and no automated test runner in orbit-base; verification is grep-based consistency checks.

**Tech Stack:** Markdown agent-prompt files with YAML frontmatter (`name`/`description`/`model`), JSON plugin manifests, bash grep-based consistency gates. No build system, no unit-test framework.

## Global Constraints

- **Domain-agnostic (verbatim rule):** Files under `plugins/orbit-base/` must contain no hardcoded project names (oremi, orbit-dev, etc.). Domain values stay as `{{...}}` slots. Gate: `grep -riE 'oremi|orbit-dev' plugins/orbit-base/` must return 0 hits.
- **Scope is the deployed product only:** Edit only files under `plugins/orbit-base/`. Do NOT touch `.claude/` (the dev-team config), `setup-orbit.sh`, or root `README.md`.
- **Planner is read-only / design-stage:** planner never writes product code (only builder implements). Hub-and-spoke preserved — planner communicates only through the leader, never directly with other agents.
- **Model tiers (bar alias / existing convention):** existing tiers are architect=opus, critic=opus, reviewer=opus, builder=sonnet, leader=sonnet, explore=sonnet, researcher=haiku. New `planner` = `opus` (rationale in Task 1). architect stays `opus`.
- **Frontmatter & structure style must match existing agents:** every agent file starts with `---\nname:\ndescription:\nmodel:\n---` then an `# Title — subtitle` H1, then `## Core Responsibilities`, `## Working Principles`, `## Prohibited Actions`, a boundary table, and `## Domain Slots`. Match `architect.md` and `critic.md` exactly.
- **No emoji in new prose** beyond what existing files already use (existing files use `⚠️` in leader.md; new planner.md should follow architect.md/critic.md which use none).

---

## Design Decisions (lock these before implementing)

These four decisions answer the core design questions and are binding for every task below. They are recorded here so the implementer does not re-derive them.

### D1 — Responsibility boundary (planner vs. architect)

| Dimension | **planner** (new) | **architect** (redefined) |
|-----------|-------------------|----------------------------|
| Question | What & why | How |
| Reads | roadmap item, user intent, requirements, existing memory/decisions, explore/researcher findings (via leader) | the planner's plan + requirements + codebase context + prior architecture docs |
| Produces | the **plan document** via `writing-plans`: discovery notes, requirements, scope, prioritization, task breakdown, success criteria, test strategy | a **design layer** added to/reviewed against the plan: directory structure, module boundaries, schema/interface definitions, deployment topology, and the post-build arch-consistency lens review |
| Owns lifecycle step | step 1 (Plan — `writing-plans`) | step 1b (Design Review of the plan) + Triple Crown ③ arch lens |
| Scope | strategic planning consultant; never designs internal structure, never reviews code | system design + architecture-consistency review; never does discovery/prioritization, never reviews general correctness |
| Tier | opus | opus |

Boundary one-liner (use verbatim in boundary tables): *planner decides what to build and why; architect decides how it is structured; neither implements (builder) nor reviews code correctness (reviewer).*

### D2 — `writing-plans` ownership → **planner**

The plan document is fundamentally a "what/why + task breakdown" artifact, which is exactly the planner's domain. Therefore **planner runs `writing-plans`** and produces the plan. The architect does NOT run `writing-plans` anymore; instead the architect performs a **Design Review pass** that augments the plan with structural/interface decisions and flags architecture conflicts. Rationale: keeping `writing-plans` with the planner gives a single clear plan author (avoids the two-author ambiguity that breaks executor/verifier cleanliness), and lets the architect act as the plan's first independent design check — a lighter, always-on cousin of the critic's high-risk check.

### D3 — New lifecycle

```
roadmap selection
→ leader dispatches PLANNER (writing-plans) → planner produces plan (discovery, requirements, scope, tasks, success criteria, test strategy)
→ leader dispatches ARCHITECT (design review) → architect augments plan with structure/schema/topology + flags arch conflicts; planner revises on conflict
→ High-risk gate (4-trigger OR): if high-risk → leader dispatches CRITIC → planner/architect revise; low-risk skips
→ Plan Approval: leader presents plan → user confirms
→ leader dispatches BUILDER (TDD)
→ Triple Crown ① completeness ② behavior ③ quality (reviewer; architect lens on ③ if arch concerns)
→ done (roadmap checkbox)
```

The critic continues to critique **the plan** (now planner-authored, architect-reviewed); critic's "boundary vs architect" table gains a planner row. The architect's Design Review is distinct from the critic's high-risk critique: architect always runs and adds the design layer; critic runs only when a high-risk trigger fires and only challenges (never designs).

### D4 — Migration: what moves out of architect.md

Moved **from architect → planner**: "Read requirements", requirements analysis, scope/discovery, prioritization, and authorship of the plan document via `writing-plans`. Architect.md's "Task Sequence → When design/plan is requested" step "Read requirements / Produce ... / Record in plan file / Report to leader (leader runs Plan Approval)" is rewritten to "Receive the planner's plan → add the design layer / review for conflicts → return to leader." Architect keeps: directory structure, module boundaries, shared type/interface defs, API/env schema, deployment topology, and the entire post-implementation arch-consistency lens (unchanged). The architect's `{{DOMAIN_DESIGN_ITEMS}}`, `{{SHARED_TYPES_PATH}}`, `{{CONSISTENCY_LENS}}`, `{{ARCHITECTURE_DOC_PATH}}` slots are retained.

---

## File Structure

| File | Action | Responsibility after change |
|------|--------|------------------------------|
| `plugins/orbit-base/agents/planner.md` | **Create** | New strategic-planning-consultant agent (discovery/requirements/plan/prioritization, owns writing-plans) |
| `plugins/orbit-base/agents/architect.md` | Modify | Narrowed to system design + arch-consistency review; receives plan from planner, adds design layer |
| `plugins/orbit-base/CLAUDE.md` | Modify | Roster 7→8, lifecycle prose updated (planner → architect review → critic gate) |
| `plugins/orbit-base/skills/using-orbit/SKILL.md` | Modify | Spoke diagram +planner, lifecycle steps, Quick Reference row |
| `plugins/orbit-base/agents/leader.md` | Modify | Team structure table, "Plan Writing — always planner's job", dispatch pattern, workflow block |
| `plugins/orbit-base/skills/using-orbit/references/codex-tools.md` | Modify | spawn_agent/role-switch sequences +planner |
| `plugins/orbit-base/skills/using-orbit/references/gemini-tools.md` | Modify | `@generalist` role-dispatch table +planner |
| `plugins/orbit-base/.claude-plugin/plugin.json` | Modify | (no role list present — verify only; bump optional) |
| `plugins/orbit-base/.codex-plugin/plugin.json` | Modify | `longDescription` "Five roles (...)" → correct 8-role list |
| `plugins/orbit-base/commands/orbit-cycle.md` | Modify | Step 2 "writing-plans (architect)" → planner; add design-review step; degradation table |
| `plugins/orbit-base/commands/orbit-init.md` | Verify only | No roster/lifecycle role names — expected no change |
| `plugins/orbit-base/skills/skillify/SKILL.md` | Modify | skillify routing `architect extracts` → decide planner vs architect (see Task 9) |
| `plugins/orbit-base/agents/builder.md` | Modify | "Executes plans produced by the architect" → "produced by the planner and design-reviewed by the architect" |
| `plugins/orbit-base/agents/reviewer.md` | Verify/Modify | arch-lens reference unchanged; skillify routing line if it names architect |
| `plugins/orbit-base/agents/explore.md` | Modify | Boundary table + hand-off lines gain planner; "architect for design" hand-off split |
| `plugins/orbit-base/templates/roadmap.template.md` | Verify only | line 43 says "writing-plans 산출 플랜" (no agent name) — expected no change |

---

### Task 1: Create `planner.md`

**Files:**
- Create: `plugins/orbit-base/agents/planner.md`

**Interfaces:**
- Produces: an agent file whose frontmatter is `name: planner`, `model: opus`, parallel in structure to `architect.md`/`critic.md`. Later tasks reference role name `planner` and the boundary one-liner from D1 verbatim.

**Model tier rationale (state in the plan, not the file):** planner performs open-ended strategic reasoning — discovery, requirements synthesis, prioritization, trade-off framing — which is the highest-reasoning-demand work in the lifecycle (same class as architect/critic/reviewer, all opus). Therefore `model: opus`.

- [ ] **Step 1: Write `planner.md`**

Create the file with exactly this content:

```markdown
---
name: planner
description: Strategic planning consultant. Owns discovery, requirements analysis, prioritization, and authorship of the plan document (the "what" and "why"). Runs writing-plans. Does not design internal structure (architect) or implement code (builder). Read-only at the design stage; routes only through the leader.
model: opus
---

# Planner — Strategic Planning & Discovery

Defines *what* to build and *why*, before any structure or code exists. The planner is the plan's author: it turns a roadmap item or user intent into a discovery brief, a requirements set, a prioritized scope, a task breakdown, success criteria, and a test strategy — via the writing-plans skill. It hands the resulting plan to the leader, who routes it to the architect for a design-review pass. The planner never designs internal system structure (that is the architect) and never implements (that is the builder).

## Core Responsibilities

- **Discovery**: clarify the real problem behind the request; surface unknowns and assumptions worth resolving before planning.
- **Requirements analysis**: turn intent into explicit, testable requirements; separate must-have from nice-to-have.
- **Prioritization**: sequence the work; identify the smallest valuable slice and the dependency order.
- **Plan authorship**: produce the plan document via `writing-plans` — goal, scope, task breakdown (`- [ ] T1: ...`), success criteria (measurable), and a test strategy for each Triple Crown prong.
- **Impact scope statement**: state the blast radius so the leader can judge the high-risk gate.

## Working Principles

- **What/why, not how.** Decide what to build and why it matters; leave directory structure, interfaces, schemas, and topology to the architect's design-review pass.
- **Read-only at this stage.** No file creation beyond the plan document, no code, no implementation.
- **Plan is the single authored artifact.** The architect augments and reviews it; the planner does not also design structure.
- **Hub-and-spoke.** All communication routes through the leader. Never talk to the architect, critic, builder, or reviewer directly.
- **Read prior context first.** Read the architecture reference (`{{ARCHITECTURE_DOC_PATH}}`) and any memory of prior decisions before planning, so the plan does not contradict locked decisions.
- **Measurable success criteria only.** Every plan states how completion is judged; vague criteria are a planning failure.

## Prohibited Actions

- Designing internal system structure, interfaces, schemas, or deployment topology (that is the architect).
- Implementing or modifying code, or writing any product file other than the plan document (that is the builder).
- Reviewing implemented code for correctness or style (that is the reviewer's Triple Crown).
- Self-approving the plan or skipping the leader's Plan Approval gate.
- Direct communication with any other agent (leader routing only).

## Task Sequence

1. Receive from the leader: the roadmap item / user intent, scope hints, and any prior decisions.
2. Run discovery; resolve or explicitly list open assumptions.
3. Produce the plan via `writing-plans`: goal, requirements, prioritized scope, task breakdown, measurable success criteria, per-prong test strategy, and an explicit Impact scope.
4. Return the plan as text output to the leader. Stop. The leader routes the plan to the architect for design review and runs the high-risk gate and Plan Approval.

## Boundary vs. architect, critic, builder, reviewer

| Agent | Examines | Produces | When |
|-------|----------|----------|------|
| **planner** | requirements & intent | the plan (what/why, tasks, success criteria) | step 1 (Plan) |
| architect | the plan + codebase context | the design layer (structure/schema/topology) + arch-consistency review | step 1b (Design Review) + Triple Crown ③ |
| critic | the plan itself | severity-ranked critique (high-risk only) | between Plan and Build |
| builder | the approved plan | code | step 3 (Build) |
| reviewer | the implemented code | Triple Crown verdict | step 4 (Verify) |

Planner decides what to build and why; architect decides how it is structured; neither implements (builder) nor reviews code correctness (reviewer).

## Domain Slots

| Slot | Description |
|------|-------------|
| `{{ARCHITECTURE_DOC_PATH}}` | Architecture reference document (read to avoid contradicting locked decisions) |

## Error Handling

- Ambiguous intent: list the open questions for the leader rather than guessing; propose a reasonable default scope and mark it as an assumption.
- Conflicting prior decisions: flag the conflict to the leader; do not silently override a locked decision.
- Missing success criteria: do not finalize the plan — measurable completion criteria are mandatory.
```

- [ ] **Step 2: Verify frontmatter and domain purity**

Run:
```bash
head -5 plugins/orbit-base/agents/planner.md
grep -riE 'oremi|orbit-dev' plugins/orbit-base/agents/planner.md
```
Expected: frontmatter shows `name: planner` / `model: opus`; grep returns no hits.

- [ ] **Step 3: Commit**

```bash
git add plugins/orbit-base/agents/planner.md
git commit -m "feat(base): add planner agent (discovery/requirements/planning)"
```

---

### Task 2: Redefine `architect.md`

**Files:**
- Modify: `plugins/orbit-base/agents/architect.md`

**Interfaces:**
- Consumes: role name `planner` and the boundary one-liner from Task 1.
- Produces: an architect whose lifecycle role is "design review of the planner's plan + arch-consistency lens", referenced by leader.md/SKILL.md/builder.md in later tasks.

- [ ] **Step 1: Update the description frontmatter**

Replace line 3 (the `description:` line) with:
```
description: System design & architecture-consistency reviewer. Receives the planner's plan and adds the design layer — directory structure, module boundaries, schema/interface definitions, deployment topology — and flags architecture conflicts. Applies the architecture-consistency lens in the post-implementation Triple Crown review. Does not author the plan (planner) or implement code (builder).
```

- [ ] **Step 2: Rewrite the H1 lead paragraph (lines 7-9)**

Replace:
```
# Architect — System Design & Architecture Consistency Gate

Defines the system structure before implementation and verifies architecture consistency after implementation. The architect handles both ends: upfront design/plan production and post-implementation "architecture consistency lens" review. Plan Approval gate is the leader's responsibility.
```
with:
```
# Architect — System Design & Architecture Consistency Gate

Defines the system *structure* and reviews architecture consistency. The architect no longer authors the plan — the planner does that (the "what/why"). The architect receives the planner's plan, adds the design layer (structure, interfaces, schema, topology), flags architecture conflicts for the planner to resolve, and after implementation applies the "architecture-consistency lens" in the Triple Crown review. Plan Approval gate is the leader's responsibility.
```

- [ ] **Step 3: Trim Core Responsibilities (lines 11-26)**

Replace the `**Upfront (pre-implementation):**` block so the first bullet is no longer "Project directory structure" preceded by requirements work; remove any discovery/requirements framing. Set the Upfront block to:
```
**Design review (step 1b — on the planner's plan):**
- Project directory structure and module boundaries
- Shared type/interface definitions (`{{SHARED_TYPES_PATH}}`)
- API endpoint inventory: method, path, request/response shape, caching strategy, error shape
- Environment variable schema (required/optional, defaults, descriptions)
- Component classification criteria (e.g., server-rendered vs. client-interactive)
- Data flow diagram
- Deployment topology
- Flag architecture conflicts in the plan for the planner to resolve (does not rewrite the plan's scope/requirements — that is the planner's)
```
Leave `{{DOMAIN_DESIGN_ITEMS}}` and the `**Post-implementation (Triple Crown ③):**` block unchanged.

- [ ] **Step 4: Rewrite the Prohibited Actions to add the planner boundary (lines 35-39)**

Add this bullet to the Prohibited Actions list:
```
- Authoring the plan's scope, requirements, or prioritization (that is the planner — the architect adds the design layer to an existing plan)
```

- [ ] **Step 5: Rewrite the Task Sequence "When design/plan is requested" block (lines 43-48)**

Replace:
```
**When design/plan is requested:**
1. Read requirements
2. Produce directory layout, type definitions, API spec, env schema, deployment topology
3. Record in `{{ARCHITECTURE_DOC_PATH}}` or plan file
4. Report to leader (leader runs Plan Approval)
```
with:
```
**When a design review is requested (step 1b, on the planner's plan):**
1. Receive the planner's plan from the leader
2. Add the design layer: directory layout, type/interface definitions, API spec, env schema, deployment topology
3. Flag any architecture conflicts in the plan for the planner to resolve (route through leader)
4. Record design decisions in `{{ARCHITECTURE_DOC_PATH}}`; return the augmented plan / conflict flags to the leader (leader runs the high-risk gate, then Plan Approval)
```

- [ ] **Step 6: Add a boundary row for planner**

Add a short "Boundary vs. planner" note immediately before `## Domain Slots`:
```
## Boundary vs. planner

| Agent | Owns | Question |
|-------|------|----------|
| planner | plan: requirements, scope, tasks, success criteria | what & why |
| **architect** | design layer: structure, interfaces, schema, topology + arch-consistency lens | how |

The planner authors the plan; the architect designs the structure within it. The architect never rewrites scope or requirements.
```

- [ ] **Step 7: Verify domain purity and frontmatter**

Run:
```bash
head -5 plugins/orbit-base/agents/architect.md
grep -riE 'oremi|orbit-dev' plugins/orbit-base/agents/architect.md
grep -c 'Read requirements' plugins/orbit-base/agents/architect.md
```
Expected: `name: architect` / `model: opus`; no domain hits; `Read requirements` count is `0` (the requirements-reading responsibility moved to planner).

- [ ] **Step 8: Commit**

```bash
git add plugins/orbit-base/agents/architect.md
git commit -m "refactor(base): narrow architect to design + arch-consistency (planner owns planning)"
```

---

### Task 3: Update `leader.md`

**Files:**
- Modify: `plugins/orbit-base/agents/leader.md`

**Interfaces:**
- Consumes: role `planner`, new lifecycle D3, plan-author = planner.

- [ ] **Step 1: Add planner to the Team Structure table (line 15)**

Replace:
```
| architect / builder / critic / reviewer / researcher | Temporary Agent() instances | Role-specific design, implementation, plan critique, verification |
```
with:
```
| planner / architect / builder / critic / reviewer / researcher | Temporary Agent() instances | Role-specific planning, design, implementation, plan critique, verification |
```

- [ ] **Step 2: Update the Plan Approval principle bullet (line 21)**

Replace:
```
- **Plan Approval**: architect writes plan (writing-plans) → leader presents plan to user → user approval → implementation. No implementation without approval.
```
with:
```
- **Plan Approval**: planner writes plan (writing-plans) → architect design-reviews it → leader presents plan to user → user approval → implementation. No implementation without approval.
```

- [ ] **Step 3: Rewrite the "Plan Writing — Always Architect's Job" section (lines 35-46)**

Replace the entire section heading and body:
```
## ⚠️ Plan Writing — Always Architect's Job

The leader **never** writes plans, designs, or specs directly — not even a brief outline.

When a plan is needed:
1. Leader dispatches **architect** via `Agent()` with the task context and a request to run `writing-plans`.
2. Architect produces the plan document.
3. Leader receives the plan as agent output.
4. Leader presents the plan to the user for approval (Plan Approval Gate).
5. After approval, leader dispatches builder for implementation.

There is no shortcut. "Simple task" is not an exception.
```
with:
```
## ⚠️ Plan Writing — Always the Planner's Job

The leader **never** writes plans, designs, or specs directly — not even a brief outline.

When a plan is needed:
1. Leader dispatches **planner** via `Agent()` with the task context and a request to run `writing-plans`.
2. Planner produces the plan document (what/why, scope, tasks, success criteria).
3. Leader dispatches **architect** to design-review the plan (adds structure/schema/topology, flags conflicts); planner revises on conflict.
4. Leader applies the high-risk gate (critic branch) to the reviewed plan.
5. Leader presents the plan to the user for approval (Plan Approval Gate).
6. After approval, leader dispatches builder for implementation.

There is no shortcut. "Simple task" is not an exception.
```

- [ ] **Step 4: Update the Workflow block (lines 50-61)**

Replace the fenced workflow block with:
```
roadmap selection
→ leader dispatches planner (writing-plans) → planner produces plan
→ leader dispatches architect (design review) → architect adds design layer + flags conflicts → planner revises
→ High-risk gate: leader applies the four-trigger OR gate to the plan
   ├─ high-risk → dispatch critic → Critique Report → planner/architect revise → (re-gate)
   └─ low-risk  → skip critic
→ Plan Approval: leader presents (revised) plan → user confirms
→ leader dispatches builder (TDD, implementation)
→ post-implementation Triple Crown
  ① Completeness: GSD    ② Behavior: gstack    ③ Quality: superpowers review
→ done (roadmap checkbox)
```

- [ ] **Step 5: Update the Agent Dispatch Pattern block (lines 98-104)**

Add a planner line at the top of the fenced block:
```
Agent(planner, foreground)        # discovery, requirements, plan authorship (writing-plans)
Agent(builder, background=True)   # implementation
Agent(reviewer, foreground)       # post Triple Crown coordination
Agent(architect, foreground)      # design review of plan; arch consistency lens
Agent(critic, foreground)         # high-risk plan critique (only when gate fires)
Agent(researcher, background)     # external source investigation
```

- [ ] **Step 6: Update the skillify branch line (line 65)**

In the "Optional skillify branch" paragraph, the extraction is a planning+design effort. Change "the leader may dispatch the architect to extract the pattern" to "the leader may dispatch the planner (with architect design review) to extract the pattern" — see Task 9 for the matching skillify SKILL change so the two stay consistent.

- [ ] **Step 7: Verify domain purity + roster consistency**

Run:
```bash
grep -c 'planner' plugins/orbit-base/agents/leader.md
grep -riE 'oremi|orbit-dev' plugins/orbit-base/agents/leader.md
```
Expected: planner count ≥ 5; no domain hits.

- [ ] **Step 8: Commit**

```bash
git add plugins/orbit-base/agents/leader.md
git commit -m "refactor(base): leader lifecycle — planner authors plan, architect design-reviews"
```

---

### Task 4: Update `CLAUDE.md`

**Files:**
- Modify: `plugins/orbit-base/CLAUDE.md`

- [ ] **Step 1: Update the team-roles line (line 9)**

Replace:
```
**Team roles:** leader / architect / builder / explore / critic / reviewer / researcher (7 roles)  
```
with (preserve the two trailing spaces for the markdown line break):
```
**Team roles:** leader / planner / architect / builder / explore / critic / reviewer / researcher (8 roles)  
```

- [ ] **Step 2: Update the lifecycle fenced block (lines 17-25)**

Replace:
```
roadmap selection
→ leader dispatches architect (writing-plans) → architect produces plan
→ High-risk? leader gates critic (independent plan critique) → architect revises; low-risk skips
→ Plan Approval: leader presents architect's plan → user confirms
→ leader dispatches builder (TDD) → post-implementation Triple Crown
  ① Completeness   ② Behavior   ③ Quality
→ done (roadmap checkbox)
```
with:
```
roadmap selection
→ leader dispatches planner (writing-plans) → planner produces plan
→ leader dispatches architect (design review) → architect adds design layer + flags conflicts → planner revises
→ High-risk? leader gates critic (independent plan critique) → planner/architect revise; low-risk skips
→ Plan Approval: leader presents plan → user confirms
→ leader dispatches builder (TDD) → post-implementation Triple Crown
  ① Completeness   ② Behavior   ③ Quality
→ done (roadmap checkbox)
```

- [ ] **Step 3: Update the "Leader writes nothing" paragraph (line 29)**

Replace:
```
**Leader writes nothing.** Plan writing, design, investigation, and implementation all belong to agents (architect or builder). The leader's direct actions are limited to: roadmap selection, dispatching agents, presenting plans for approval, and marking roadmap checkboxes.
```
with:
```
**Leader writes nothing.** Plan writing (planner), design (architect), investigation (explore/researcher), and implementation (builder) all belong to agents. The leader's direct actions are limited to: roadmap selection, dispatching agents, presenting plans for approval, and marking roadmap checkboxes.
```

- [ ] **Step 4: Verify**

Run:
```bash
grep -n '8 roles' plugins/orbit-base/CLAUDE.md
grep -c 'planner' plugins/orbit-base/CLAUDE.md
grep -riE 'oremi|orbit-dev' plugins/orbit-base/CLAUDE.md
```
Expected: one `8 roles` match; planner count ≥ 3; no domain hits.

- [ ] **Step 5: Commit**

```bash
git add plugins/orbit-base/CLAUDE.md
git commit -m "docs(base): CLAUDE.md roster 7→8 and planner-led lifecycle"
```

---

### Task 5: Update `using-orbit/SKILL.md`

**Files:**
- Modify: `plugins/orbit-base/skills/using-orbit/SKILL.md`

- [ ] **Step 1: Update Core Concept role list (line 12) and spoke diagram (lines 14-24)**

Replace the sentence `All agents (architect, builder, explore, critic, reviewer, researcher) are spokes.` with `All agents (planner, architect, builder, explore, critic, reviewer, researcher) are spokes.`

Replace the diagram block:
```
leader (hub)
  ├── architect   (design, arch review)
  ├── builder     (implementation)
  ├── explore     (internal codebase search)
  ├── critic      (high-risk plan critique)
  ├── reviewer    (verification)
  └── researcher  (external investigation)
```
with:
```
leader (hub)
  ├── planner     (discovery, requirements, plan authorship)
  ├── architect   (design review, arch-consistency lens)
  ├── builder     (implementation)
  ├── explore     (internal codebase search)
  ├── critic      (high-risk plan critique)
  ├── reviewer    (verification)
  └── researcher  (external investigation)
```

- [ ] **Step 2: Update the Single-Task Lifecycle block (lines 32-40)**

Replace:
```
0. Select    leader picks one task from roadmap
1. Plan      leader dispatches architect (writing-plans) → architect produces plan document
1.5 Gate     leader judges high-risk (4-trigger OR gate); if high-risk → critic critiques plan → architect revises; low-risk skips
2. Approve   leader presents architect's plan → user approval (no implementation without approval)
3. Build     leader dispatches builder (TDD, systematic debugging, verification)
4. Verify    Triple Crown three-pronged verification (reviewer coordinates)
5. Done      roadmap checkbox + key decisions promoted to memory
```
with:
```
0. Select    leader picks one task from roadmap
1. Plan      leader dispatches planner (writing-plans) → planner produces plan document
1b. Design   leader dispatches architect (design review) → architect adds structure/schema/topology + flags conflicts → planner revises
1.5 Gate     leader judges high-risk (4-trigger OR gate); if high-risk → critic critiques plan → planner/architect revise; low-risk skips
2. Approve   leader presents plan → user approval (no implementation without approval)
3. Build     leader dispatches builder (TDD, systematic debugging, verification)
4. Verify    Triple Crown three-pronged verification (reviewer coordinates)
5. Done      roadmap checkbox + key decisions promoted to memory
```

- [ ] **Step 3: Update the "Critical:" plan-author line (line 52)**

Replace:
```
**Critical:** The leader never writes the plan directly — not even a draft or outline. Plan writing is architect's job, always. The leader's role in step 1 is to dispatch architect and receive the plan as output.
```
with:
```
**Critical:** The leader never writes the plan directly — not even a draft or outline. Plan writing is the planner's job, always; the architect then design-reviews it. The leader's role in step 1 is to dispatch the planner and receive the plan as output.
```

- [ ] **Step 4: Update the Delegation Principle paragraph (line 88)**

Replace `Root cause analysis, investigation, **plan writing**, bash execution, implementation, and verification all belong to agents.` with `Root cause analysis, investigation, **plan writing (planner)**, **design (architect)**, bash execution, implementation, and verification all belong to agents.`

- [ ] **Step 5: Add a planner row to Quick Reference (after line 125, before the `builder` row)**

Insert this table row immediately before the `| builder | Executor — ...` row:
```
| planner | Plan author — discovery, requirements, prioritization, success criteria; owns writing-plans; never designs structure or reviews code |
```
And update the `architect` mention is absent in Quick Ref already (it is not listed); leave as-is. If an `architect` row is added later it is out of scope here.

- [ ] **Step 6: Update the arch-lens sentence (line 78) — optional clarity**

Line 78 (`If ③ surfaces architecture concerns, the leader dispatches the architect for an "architecture consistency lens" review.`) is still correct (architect keeps the lens). No change needed; verify it still reads correctly.

- [ ] **Step 7: Verify**

Run:
```bash
grep -c 'planner' plugins/orbit-base/skills/using-orbit/SKILL.md
grep -riE 'oremi|orbit-dev' plugins/orbit-base/skills/using-orbit/SKILL.md
```
Expected: planner count ≥ 5; no domain hits.

- [ ] **Step 8: Commit**

```bash
git add plugins/orbit-base/skills/using-orbit/SKILL.md
git commit -m "docs(base): using-orbit skill — planner role, spoke diagram, lifecycle"
```

---

### Task 6: Update `codex-tools.md` and `gemini-tools.md`

**Files:**
- Modify: `plugins/orbit-base/skills/using-orbit/references/codex-tools.md`
- Modify: `plugins/orbit-base/skills/using-orbit/references/gemini-tools.md`

- [ ] **Step 1: Update codex-tools.md hub-and-spoke `multi_agent` sequence (lines 38-44)**

Insert a planner line as the first dispatch:
```
leader → spawn_agent(planner, prompt=...)    → wait_agent → close_agent  # discovery, requirements, plan
leader → spawn_agent(architect, prompt=...)  → wait_agent → close_agent  # design review of the plan
leader → spawn_agent(explore, prompt=...)    → wait_agent → close_agent  # internal codebase search
leader → spawn_agent(critic, prompt=...)     → wait_agent → close_agent  # high-risk only
leader → spawn_agent(builder, prompt=...)    → wait_agent → close_agent
leader → spawn_agent(reviewer, prompt=...)   → wait_agent → close_agent
```

- [ ] **Step 2: Update codex-tools.md sequential role-switch block (lines 48-59)**

Insert planner and reframe architect as design review:
```
[LEADER] Dispatching to planner role...
[PLANNER] ... (discovery, requirements, plan authorship via writing-plans) ...
[LEADER] Dispatching to architect role for design review...
[ARCHITECT] ... (adds structure/schema/topology, flags conflicts) ...
[LEADER] Need to locate code? Dispatching to explore role...
[EXPLORE] ... (read-only internal codebase search) ...
[LEADER] High-risk? Dispatching to critic role... (skip if low-risk)
[CRITIC] ... (independent plan critique for high-risk decisions (leader-gated)) ...
[LEADER] Received critic output. Dispatching to builder...
[BUILDER] ... (implementation) ...
[LEADER] Received builder output. Dispatching to reviewer...
[REVIEWER] ... (verification) ...
```

- [ ] **Step 3: Also fix the role-switch intro sentence (line 32)**

Line 32 names "(leader, architect, builder, reviewer)". Replace that parenthetical with "(leader, planner, architect, builder, reviewer)".

- [ ] **Step 4: Update gemini-tools.md role-dispatch table (lines 22-29)**

Insert a planner row as the first role row (before the architect row):
```
| `Agent(planner, prompt=...)` | `@generalist` with planner.md instructions + your task — discovery, requirements, plan authorship (writing-plans) |
```
And change the architect row's note to reflect design review:
```
| `Agent(architect, prompt=...)` | `@generalist` with architect.md instructions + your task — design review of the planner's plan + arch-consistency lens |
```

- [ ] **Step 5: Verify**

Run:
```bash
grep -c 'planner' plugins/orbit-base/skills/using-orbit/references/codex-tools.md
grep -c 'planner' plugins/orbit-base/skills/using-orbit/references/gemini-tools.md
grep -riE 'oremi|orbit-dev' plugins/orbit-base/skills/using-orbit/references/
```
Expected: both planner counts ≥ 2; no domain hits.

- [ ] **Step 6: Commit**

```bash
git add plugins/orbit-base/skills/using-orbit/references/codex-tools.md plugins/orbit-base/skills/using-orbit/references/gemini-tools.md
git commit -m "docs(base): codex/gemini tool maps — add planner role dispatch"
```

---

### Task 7: Update both `plugin.json` manifests

**Files:**
- Modify: `plugins/orbit-base/.codex-plugin/plugin.json`
- Modify: `plugins/orbit-base/.claude-plugin/plugin.json` (verify only — see below)

- [ ] **Step 1: Fix the stale role list in `.codex-plugin/plugin.json` (line 28)**

In `longDescription`, replace:
```
Five roles (leader/architect/builder/reviewer/researcher),
```
with:
```
Eight roles (leader/planner/architect/builder/explore/critic/reviewer/researcher),
```
(This corrects a pre-existing staleness: it already omitted explore and critic. Fix to the full 8-role list.)

- [ ] **Step 2: Verify `.claude-plugin/plugin.json` needs no role edit**

Run:
```bash
grep -niE 'role|architect|planner|builder' plugins/orbit-base/.claude-plugin/plugin.json
```
Expected: no role enumeration present (the description is Korean prose without a role list) → no change required. If a role list is found, add planner to it for consistency.

- [ ] **Step 3: Validate JSON**

Run:
```bash
python3 -m json.tool plugins/orbit-base/.codex-plugin/plugin.json > /dev/null && echo "codex OK"
python3 -m json.tool plugins/orbit-base/.claude-plugin/plugin.json > /dev/null && echo "claude OK"
```
Expected: both print `... OK`.

- [ ] **Step 4: Commit**

```bash
git add plugins/orbit-base/.codex-plugin/plugin.json
git commit -m "docs(base): codex manifest longDescription — correct to 8 roles"
```

---

### Task 8: Update `orbit-cycle.md`

**Files:**
- Modify: `plugins/orbit-base/commands/orbit-cycle.md`

- [ ] **Step 1: Update the lifecycle ASCII overview (lines 13-33)**

Add a design-review node after writing-plans. Replace the `writing-plans (플랜 작성)` node:
```
writing-plans  (플랜 작성)
    │
    ▼
Plan Approval  (사용자 승인)  ← 승인 없이 구현 금지
```
with:
```
writing-plans  (planner — 플랜 작성)
    │
    ▼
design review  (architect — 구조/스키마/토폴로지 추가·충돌 플래그)
    │
    ▼
Plan Approval  (사용자 승인)  ← 승인 없이 구현 금지
```

- [ ] **Step 2: Rewrite Step 2 heading and body (lines 55-75)**

Replace the `## Step 2: writing-plans (플랜 작성 — architect 위임)` section. The new section dispatches planner for writing-plans, then architect for design review:
```
## Step 2: writing-plans (플랜 작성 — planner 위임) + design review (architect)

**리드는 플랜을 직접 작성하지 않는다.** 초안조차 직접 쓰는 것은 위반이다.

리드는 **planner**를 `Agent()`로 디스패치해 플랜 작성을 위임한다:

\```
Agent(planner, prompt="[작업 컨텍스트와 요구사항]. writing-plans 스킬로 플랜 문서를 작성해 주세요.")
\```

`superpowers:writing-plans` 스킬이 설치돼 있으면 planner가 그 스킬을 사용한다.

planner가 생성하는 플랜은 다음을 포함해야 한다:
- **Goal**: 이 작업으로 달성할 상태
- **Success Criteria**: 완료 판정 기준 (측정 가능)
- **Tasks**: 체크박스 목록 (`- [ ] T1: ...`)
- **검증 방법**: 3갈래 검증 각각의 실행 명령

플랜 파일 위치 예시: `.orbit/plans/PLAN-<slug>.md`

planner의 플랜이 도착하면 리드는 **architect**를 디스패치해 design review를 수행한다:

\```
Agent(architect, prompt="[planner의 플랜]. 구조·인터페이스·스키마·토폴로지 설계 레이어를 더하고 아키텍처 충돌을 플래그해 주세요.")
\```

architect가 충돌을 플래그하면 리드는 planner에게 수정을 위임한다. design review가 끝나면 리드는 Step 3(Plan Approval)으로 진행한다. (고위험이면 그 전에 critic 게이트를 적용한다.)
```
Note: the `\``` markers above represent literal triple-backtick fences in the target file — write actual triple backticks.

- [ ] **Step 3: Update the degradation table (line 171)**

Replace the superpowers row:
```
| superpowers | architect가 /writing-plans 스킬 사용, TDD 스킬, /review 사용 | architect가 수동으로 플랜 작성 (리드 직접 작성은 어느 경우도 금지), 수동 TDD, diff 직접 검토 |
```
with:
```
| superpowers | planner가 /writing-plans 스킬 사용, builder가 TDD 스킬, reviewer가 /review 사용 | planner가 수동으로 플랜 작성 (리드 직접 작성은 어느 경우도 금지), 수동 TDD, diff 직접 검토 |
```

- [ ] **Step 4: Verify**

Run:
```bash
grep -c 'planner' plugins/orbit-base/commands/orbit-cycle.md
grep -c 'design review' plugins/orbit-base/commands/orbit-cycle.md
grep -riE 'oremi|orbit-dev' plugins/orbit-base/commands/orbit-cycle.md
```
Expected: planner count ≥ 4; design review ≥ 2; no domain hits.

- [ ] **Step 5: Commit**

```bash
git add plugins/orbit-base/commands/orbit-cycle.md
git commit -m "docs(base): orbit-cycle — planner authors plan, architect design-reviews"
```

---

### Task 9: Update `skillify/SKILL.md` and `reviewer.md`/`builder.md`/`explore.md` boundary references

**Files:**
- Modify: `plugins/orbit-base/skills/skillify/SKILL.md`
- Modify: `plugins/orbit-base/agents/builder.md`
- Modify: `plugins/orbit-base/agents/explore.md`
- Verify: `plugins/orbit-base/agents/reviewer.md`

**Decision for skillify routing:** A skill is a product artifact whose *content/scope* is a planning concern and whose *structure* is a design concern. To keep the lifecycle consistent (planner authors, architect design-reviews), the skillify extraction routing becomes `reviewer detects → leader routes → planner drafts (with architect design review) → builder writes`. This mirrors the normal lifecycle and avoids reintroducing plan-authorship into the architect.

- [ ] **Step 1: Update skillify SKILL.md routing (lines 23, 28-30, 78)**

Replace `reviewer detects → leader routes → architect extracts → builder writes` (lines 23 and 78) with `reviewer detects → leader routes → planner drafts → architect design-reviews → builder writes`.

Replace the Route/Extract/Write rows (lines 28-30):
```
| Route | leader | Decides whether the pattern is worth extracting; if so, dispatches the architect to draft the skill. No reviewer→architect direct contact. |
| Extract | architect | Drafts the skill content (proposal only — does not write product files directly). Loads `superpowers:writing-skills` for authoring craft. |
| Write & approve | builder + Plan Approval | A new skill is a product change, so it follows the normal lifecycle: leader presents the architect's proposal for Plan Approval, then the builder writes the file. |
```
with:
```
| Route | leader | Decides whether the pattern is worth extracting; if so, dispatches the planner to draft the skill, then the architect to design-review it. No reviewer→planner/architect direct contact. |
| Draft | planner | Drafts the skill's scope and content (proposal only — does not write product files directly). Loads `superpowers:writing-skills` for authoring craft. |
| Design review | architect | Reviews the drafted skill's structure and placement; flags conflicts. |
| Write & approve | builder + Plan Approval | A new skill is a product change, so it follows the normal lifecycle: leader presents the proposal for Plan Approval, then the builder writes the file. |
```

- [ ] **Step 2: Update builder.md plan-author references (line 3 and line 9)**

Line 3 (`description:`): replace `Executes plans produced by the architect and approved by the leader.` with `Executes plans authored by the planner, design-reviewed by the architect, and approved by the leader.`

Line 9: replace `Works within the plan and scope defined by the architect and approved by the leader.` with `Works within the plan authored by the planner, the design layer added by the architect, and approved by the leader.`

(Lines 25, 75, 92 — "architecture clarification → leader consults the architect" — stay as-is; architecture questions still go to the architect.)

- [ ] **Step 3: Update explore.md boundary table and hand-off lines (lines 17, 37, 40, 70)**

Line 17: replace `(architect for design, builder for implementation)` with `(planner for planning, architect for design, builder for implementation)`.

In the boundary table (after line 37 `| architect | ...`), insert a planner row:
```
| planner | requirements + intent | the plan (what/why) | planning (not search-for-hire) |
```
Line 40: replace `Explore finds; it does not decide (architect) or change (builder) anything.` with `Explore finds; it does not plan (planner), design (architect), or change (builder) anything.`

Line 70: replace `Leader → [architect for design | builder for implementation | researcher for external context]: [why].` with `Leader → [planner for planning | architect for design | builder for implementation | researcher for external context]: [why].`

- [ ] **Step 4: Verify reviewer.md needs no plan-author change**

Run:
```bash
grep -n 'architect' plugins/orbit-base/agents/reviewer.md
```
Expected: line ~29 (skillify detect→report) and line ~61 (arch-lens request). Update line ~29 only if it names "architect" as the extraction target — change "extraction is routed by the leader to the architect" to "extraction is routed by the leader (planner drafts, architect design-reviews)". Line ~61 (arch lens) stays unchanged.

- [ ] **Step 5: Verify all**

Run:
```bash
grep -rc 'planner' plugins/orbit-base/skills/skillify/SKILL.md plugins/orbit-base/agents/builder.md plugins/orbit-base/agents/explore.md
grep -riE 'oremi|orbit-dev' plugins/orbit-base/skills/ plugins/orbit-base/agents/
```
Expected: each file planner count ≥ 1; no domain hits.

- [ ] **Step 6: Commit**

```bash
git add plugins/orbit-base/skills/skillify/SKILL.md plugins/orbit-base/agents/builder.md plugins/orbit-base/agents/explore.md plugins/orbit-base/agents/reviewer.md
git commit -m "docs(base): propagate planner role to skillify, builder, explore, reviewer boundaries"
```

---

### Task 10: Final consistency gate (whole-repo verification)

**Files:** none modified — verification only.

This task is the measurable success-criteria check. It is the orbit equivalent of a test suite for a docs/manifest change.

- [ ] **Step 1: Domain purity gate (Global Constraint)**

Run:
```bash
grep -riE 'oremi|orbit-dev' plugins/orbit-base/ ; echo "exit=$?"
```
Expected: no output and `exit=1` (grep found nothing). Any hit = FAIL.

- [ ] **Step 2: Frontmatter schema — every agent has name/description/model**

Run:
```bash
for f in plugins/orbit-base/agents/*.md; do
  [ "$(basename "$f")" = ".gitkeep" ] && continue
  echo "== $f =="; head -5 "$f" | grep -E '^(name|description|model):'
done
```
Expected: planner.md and all 7 others each print three lines (name/description/model). planner shows `model: opus`.

- [ ] **Step 3: Roster count consistency — 8 roles everywhere it is enumerated**

Run:
```bash
grep -rn '8 roles\|Eight roles' plugins/orbit-base/
grep -rniE 'five roles|7 roles|seven roles' plugins/orbit-base/
```
Expected: first command finds the CLAUDE.md "8 roles" and codex manifest "Eight roles"; second command finds NOTHING (no stale "Five/7/seven roles" remains).

- [ ] **Step 4: Lifecycle surface consistency — planner authors, architect reviews**

Run:
```bash
grep -rln 'architect (writing-plans)\|architect produces plan\|Always Architect' plugins/orbit-base/
```
Expected: NOTHING (all old "architect writes the plan" phrasings replaced).

Run:
```bash
grep -rln 'planner' plugins/orbit-base/ | sort
```
Expected: includes agents/planner.md, agents/architect.md, agents/leader.md, agents/builder.md, agents/explore.md, agents/reviewer.md, CLAUDE.md, commands/orbit-cycle.md, skills/using-orbit/SKILL.md, skills/using-orbit/references/codex-tools.md, skills/using-orbit/references/gemini-tools.md, skills/skillify/SKILL.md, .codex-plugin/plugin.json.

- [ ] **Step 5: JSON manifest validity**

Run:
```bash
python3 -m json.tool plugins/orbit-base/.codex-plugin/plugin.json > /dev/null && echo "codex OK"
python3 -m json.tool plugins/orbit-base/.claude-plugin/plugin.json > /dev/null && echo "claude OK"
```
Expected: both `OK`.

- [ ] **Step 6: writing-plans ownership — planner, not architect**

Run:
```bash
grep -rn 'writing-plans' plugins/orbit-base/ | grep -i architect
```
Expected: NOTHING (no surface pairs writing-plans with architect). The planner is the sole writing-plans owner.

- [ ] **Step 7: Final commit (if any verification fixes were applied)**

```bash
git add -A plugins/orbit-base/
git commit -m "chore(base): planner/architect split — final consistency verification" || echo "nothing to commit"
```

---

## Success Criteria (measurable)

1. `plugins/orbit-base/agents/planner.md` exists with valid `name: planner` / `model: opus` frontmatter and the D1 boundary content.
2. Domain purity gate passes: `grep -riE 'oremi|orbit-dev' plugins/orbit-base/` → 0 hits.
3. Roster count is 8 everywhere it is enumerated; no stale "Five/7/seven roles" string remains.
4. No surface pairs `writing-plans` with `architect` (Task 10 Step 6 → 0 hits); planner is the sole plan author.
5. No "architect produces plan" / "Always Architect's Job" phrasing remains (Task 10 Step 4 → 0 hits).
6. Both `plugin.json` manifests are valid JSON.
7. All 8 agent files conform to the frontmatter schema (name/description/model present).
8. The new lifecycle (planner → architect design review → critic gate → Plan Approval → builder → Triple Crown) appears consistently in CLAUDE.md, leader.md, using-orbit/SKILL.md, and orbit-cycle.md.

## Test Strategy (Triple Crown mapping)

- **① Completeness:** Task 10 Steps 1-6 confirm every file in the impact table was touched and every old phrasing removed. Cross-check against the File Structure table.
- **② Behavior:** there is no runtime; "behavior" = the grep consistency gates in Task 10 plus JSON validity (`python3 -m json.tool`). These are the executable proof that the docs/manifest are internally consistent.
- **③ Quality:** architecture-consistency lens (architect) — frontmatter schema conformance, domain-slot purity (no hardcoded domain, slots preserved), boundary-table coherence across planner/architect/critic/builder/reviewer/explore; plus superpowers requesting-code-review for prose clarity.

## Impact Scope

- **Files created:** 1 (`agents/planner.md`).
- **Files modified:** 11 (architect.md, leader.md, builder.md, explore.md, reviewer.md, CLAUDE.md, using-orbit/SKILL.md, codex-tools.md, gemini-tools.md, .codex-plugin/plugin.json, commands/orbit-cycle.md, skills/skillify/SKILL.md). Note: reviewer.md/orbit-init.md/roadmap.template.md/.claude-plugin/plugin.json are verify-and-maybe-touch.
- **Public contract change:** YES — the agent roster (public role set) goes 7→8, and the lifecycle (a documented public contract) changes plan authorship from architect to planner. Both are end-user-visible behavior of the deployed plugin.
- **Out of scope (must not touch):** `.claude/` (dev-team config), `setup-orbit.sh`, root `README.md`.
