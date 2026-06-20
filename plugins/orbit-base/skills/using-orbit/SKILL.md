---
name: using-orbit
description: Orbit framework orientation — hub-and-spoke multi-agent team, single-task lifecycle, and Triple Crown verification. Use at the start of any orchestrated work session.
---

# Using Orbit

Orbit is a hub-and-spoke multi-agent team framework. It provides a structured lifecycle for delivering work: plan, approve, implement, verify.

## Core Concept: Hub-and-Spoke

The **leader** is the hub. All agents (architect, builder, explore, critic, reviewer, researcher) are spokes. No spoke communicates with another spoke directly — all communication routes through the leader.

```
user
  │
leader (hub)
  ├── architect   (design, arch review)
  ├── builder     (implementation)
  ├── explore     (internal codebase search)
  ├── critic      (high-risk plan critique)
  ├── reviewer    (verification)
  └── researcher  (external investigation)
```

The leader dispatches agents via `Agent()`, receives their text output, synthesizes results, and decides next steps.

## Single-Task Lifecycle

Every piece of work follows this lifecycle:

```
0. Select    leader picks one task from roadmap
1. Plan      leader dispatches architect (writing-plans) → architect produces plan document
1a. Discover (within step 1, before the plan) architect frames problem/requirements/scope/priority, drawing internal facts from explore and external facts from researcher; no new agent
1.5 Gate     leader judges high-risk (4-trigger OR gate); if high-risk → critic critiques plan → architect revises; low-risk skips
2. Approve   leader presents architect's plan → user approval (no implementation without approval)
3. Build     leader dispatches builder (TDD, systematic debugging, verification)
4. Verify    Triple Crown three-pronged verification (reviewer coordinates)
5. Done      roadmap checkbox + key decisions promoted to memory
```

Simple questions, meta tasks, and configuration changes skip the lifecycle.

### Optional Branch: High-Risk Critique (between Plan and Approve)

When the leader judges a decision high-risk — irreversible, wide blast radius (3+ components / public contract), security or data-integrity sensitive, or introducing a new external dependency — the leader dispatches the **critic** before Plan Approval. The critic independently challenges the plan's assumptions, failure modes, alternatives, and reversibility cost, then returns a severity-ranked Critique Report (PROCEED or REVISE). The architect revises on REVISE. This is the design-stage form of executor/verifier separation: the plan's author never critiques its own plan. Low-risk tasks skip this entirely. Routing is leader-only; the critic never talks to the architect directly. See the `critic` agent.

### Optional Branch: Skillify (after Done)

After a task is done, an optional branch may fire. When the **Rule of Three** is met — the same procedure or fix has recurred across three or more separate tasks — the reviewer reports the signal to the leader, who may route the architect to extract the pattern into a reusable skill (`reviewer detects → leader routes → architect extracts → builder writes`). This is never required and never blocks completion. See the `skillify` skill for the trigger, routing, and output format; skill-authoring craft is delegated to superpowers `writing-skills`.

**Critical:** The leader never writes the plan directly — not even a draft or outline. Plan writing is architect's job, always. The leader's role in step 1 is to dispatch architect and receive the plan as output.

### Optional Mode: Autonomous Loop (opt-in, default off)

By default every task uses per-task Plan Approval — unchanged. The user may instead grant a **batch pre-approval**: one exercise of the Plan Approval Gate over a named, finite set of roadmap tasks (capped at a few tasks). Before that approval, the **critic independently screens the whole batch on entry** — every task must be *manifestly* low-risk (four-trigger all-no). Within the cleared scope the leader runs an **autonomous loop** — plan → four-trigger gate → build → full Triple Crown → next — without re-prompting the human each task. The judgment is conservative: **anything ambiguous halts the loop** (ambiguous ⇒ stop). Blast radius is tracked **cumulatively across the batch**, and the loop halts for a human re-sync on reaching the batch-size cap. Hub-and-spoke is preserved: the leader loops; agents never hand off to each other. If any task's plan fires a four-trigger (high-risk) or is ambiguous, it is **ejected from the batch and the loop halts** for individual human approval — the human gate for high-risk work stays non-negotiable. Triple Crown is never lightened. See CLAUDE.md → Autonomous Mode and leader.md → Autonomous Loop. The batch pre-approval also picks one of two **execution profiles**: `halt-on-trigger` (default — any ejection halts the whole loop) or the opt-in `skip-and-park` (the ejected task is **parked** and the loop continues with remaining low-risk tasks, with the parked set reported to the human at batch end). `skip-and-park` is **not** a weaker gate: a parked high-risk or ambiguous task is **never auto-decided or auto-implemented** — it returns to individual Plan Approval with the critic branch. "ambiguous ⇒ park" is the same prohibition as "ambiguous ⇒ stop"; only the scope of the pause differs (one task vs. the whole loop).

### Plan Approval Gate

Before approving a plan, the leader checks:
- Tests included or testing strategy defined
- Impact scope clearly stated  
- No architecture conflicts flagged
- Success criteria measurable

No implementation proceeds without explicit user approval.

## Triple Crown Verification

After implementation, three orthogonal questions are asked:

| Prong | Question | Who |
|-------|----------|-----|
| ① Completeness | Did we build everything in the plan? | GSD / roadmap comparison |
| ② Behavior | Does it actually work at runtime? | gstack browser / run / CLI |
| ③ Quality | Is the code correct and maintainable? | superpowers requesting-code-review |

All three must pass before a task is marked complete. The reviewer agent coordinates the three prongs and reports consolidated results to the leader.

**③ security deep-mode.** Prong ③ has a conditional deep-mode. It enters deep-mode **if and only if the reviewer's own inspection of the built diff finds it touches the *critic T3 security surface*** (the canonical reference origin defined in `critic.md`), running an OWASP-style category sweep instead of a light scan. The reviewer's diff judgment is the binding trigger; the leader's plan-stage T3-forward is only a corroborating hint, so a forgotten forward never downgrades a security-touching change to a light scan. Because a T3-touching change is high-risk and is ejected from any autonomous batch, **deep-mode runs only in per-task mode** — it and the autonomous loop are mutually exclusive, never concurrent. Deep-mode is still a read-only review (findings go to the leader; fixes route to the builder) — it does not make the reviewer the remediation owner.

Executor/verifier separation: the builder is the executor and the reviewer is the verifier. The builder's pre-flight self-check is non-authoritative; only the reviewer's Triple Crown decides completion. The agent that builds never approves its own output.

If ③ surfaces architecture concerns, the leader dispatches the architect for an "architecture consistency lens" review.

## Delegation Principle

The leader delegates everything except:
- Roadmap selection and checkbox management
- Plan Approval gate (presents architect's plan to user, awaits confirmation)
- Memory file updates (key decisions only)
- Agent and skill definitions (leader.md, CLAUDE.md)

Root cause analysis, investigation, **plan writing**, bash execution, implementation, and verification all belong to agents. When the thought "this is simple enough to do inline" arises, that is the exact cue to delegate immediately.

## Independent Fan-out → Fan-in (optional throughput pattern)

When the leader has **two or more independent units of work**, it may dispatch them **concurrently** (e.g. `Agent(explore, background)` and `Agent(researcher, background)` at the same time) and aggregate every result once **all** branches return. This is hub-and-spoke unchanged: one hub fans out to N spokes and collects N results. The **leader is the sole fan-in point** — no spoke reads or merges another spoke's output. This pattern only changes *throughput*; the lifecycle, the gates, and the routing are untouched.

**Independence test — all four must hold (else run serially):**
1. No branch writes state another branch reads.
2. No branch's prompt depends on another branch's result.
3. No required ordering between branches.
4. No two branches edit the same files.

If any point is unclear, **uncertain ⇒ serial** — dispatch the branches one at a time. This is the same fail-closed spirit as the autonomous gate's "ambiguous ⇒ stop": parallelism is taken only when independence is affirmatively clear.

**Safe to parallelize — read-only investigation and review:** concurrent `explore` + `researcher` investigation; independent reviews of already-built diffs; the two read-only Triple Crown prongs (② behavior, ③ quality) when they share no state. None of these write files or commit, so concurrency cannot create a race.

**Never parallelize — builds and commits:** any agent that writes files or commits (the `builder`) is dispatched **one at a time**. In particular the **autonomous loop's per-task build stays serial**: its cumulative blast-radius (T2), its skip-and-park independence predicate, and its halt-on-first-failure all assume **one commit at a time**. Fan-out parallelizes *investigation and review only*, never the autonomous build sequence.

## Reporting Channel

Agents report as **text output** to the leader. The leader reads agent output and decides the next step. No direct agent-to-agent communication.

Project notifications go to `.orbit/notifications.log`.

## Roadmap: Thin Ledger

The roadmap (`.orbit/roadmap.md`) is a minimal record:
- Backlog: unstarted tasks
- Current: task in progress
- Milestones: grouped delivery targets
- Completeness criteria: measurable definition of done

When a task completes, it gets a checkbox. Key architectural decisions are promoted to project memory, not the roadmap.

### Grouping Large Features — Lightweight Convention (optional)

A large feature spanning several tasks can express cohesion with a **group header** and an **ID prefix** — pure convention, no new structure:

- **Group header:** `### [GROUP-NAME] <description>` inside the backlog (or current) section.
- **Task ID prefix:** `[PREFIX-N]` on each member task (e.g. `[PREFIX-1]`, `[PREFIX-2]`).
- **Parent reference:** tasks gathered directly under the header inherit it; a task placed elsewhere may add a trailing `↳ part of [GROUP-NAME]`.

```
## Backlog

### [GROUP-NAME] <large-feature description>
- [ ] **[PREFIX-1] <sub-task>** — <description>
- [x] **[PREFIX-2] <sub-task>** — <completion date>
- [ ] **[PREFIX-3] <sub-task>** — <description>
```

**A group is a manual label, not an active progress tracker.** It does not require a roll-up field (no `N/M complete` contract) — readers simply count `- [x]` by eye. Grouping changes nothing about the lifecycle (each sub-task still runs plan → approve → build → verify independently) or hub-and-spoke (no new role or roll-up owner). It does not replace milestones: milestones remain post-hoc labels for completed work; a group is an in-place cohesion device for backlog items. The roadmap stays a thin ledger — this is naming, not ceremony.

## Graceful Degradation by Environment

| Feature | Claude Code | Codex | Gemini |
|---------|-------------|-------|--------|
| Hub-and-spoke Agent dispatch | Full (Agent tool) | Partial (spawn_agent, multi_agent=true) | Single context, sequential role-switching |
| Automatic hooks (quality gate, viewer) | Full | Not available → manual | Not available → manual |
| Lifecycle discipline | Full | Full | Full |
| Triple Crown verification prose | Full + companion skills | Manual checklist | Manual checklist |
| Slash commands | Full | Partial | Partial |
| Autonomous loop (opt-in) | Full (leader loop over Agent dispatch) | Sequential (no background pseudo-parallelism) | Manual sequential (single context, role-switch per task) |

Automation (hooks, subagents, viewer pane) degrades gracefully. **The lifecycle discipline survives in all environments** — plan → approve → build → verify is the invariant.

## Quick Reference

| Term | Meaning |
|------|---------|
| Hub-and-spoke | Leader routes all agent communication |
| Plan Approval | User gate before any implementation |
| Autonomous Mode | Opt-in (default off): critic screens a finite low-risk batch on entry; user pre-approves once, picking a profile — `halt-on-trigger` (default: any ejection halts the loop) or `skip-and-park` (eject = park one task, loop continues, parked set reported at batch end); under both, a high-risk/ambiguous task is never auto-decided/auto-implemented (individual approval + critic); cumulative blast-radius + batch cap count built tasks only |
| Triple Crown | Three-prong post-implementation verification |
| ③ deep-mode | Triple Crown ③ Quality escalates from light scan to an OWASP-style sweep when the reviewer's diff inspection finds the change touches the critic T3 security surface (leader's T3-forward is only a hint); per-task mode only (never inside an autonomous batch); still read-only review |
| Thin Ledger | Minimal roadmap — no ceremony |
| builder | Executor — generic implementer; self-check is non-authoritative |
| explore | Read-only internal codebase search — finds files, patterns, relationships; reports to leader; never modifies, designs, or researches externally |
| critic | High-risk plan critic — challenges the plan before build; invoked only when leader gates high-risk; never self-approves a plan |
| reviewer | Verifier — Triple Crown coordinator; holds completion authority |
| `.orbit/` | Project state directory (roadmap, notifications, config) |
| skillify | Optional after-done branch: extract a Rule-of-Three recurring solution into a reusable skill |
| Fan-out → Fan-in | Optional throughput pattern: leader dispatches 2+ independent units concurrently and aggregates after all return; leader is sole fan-in; read-only investigation/review only — builds/commits stay serial |
