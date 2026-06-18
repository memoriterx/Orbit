---
name: using-orbit
description: Orbit framework orientation — hub-and-spoke multi-agent team, single-task lifecycle, and Triple Crown verification. Use at the start of any orchestrated work session.
---

# Using Orbit

Orbit is a hub-and-spoke multi-agent team framework. It provides a structured lifecycle for delivering work: plan, approve, implement, verify.

## Core Concept: Hub-and-Spoke

The **leader** is the hub. All agents (architect, builder, critic, reviewer, researcher) are spokes. No spoke communicates with another spoke directly — all communication routes through the leader.

```
user
  │
leader (hub)
  ├── architect   (design, arch review)
  ├── builder     (implementation)
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

Executor/verifier separation: the builder is the executor and the reviewer is the verifier. The builder's pre-flight self-check is non-authoritative; only the reviewer's Triple Crown decides completion. The agent that builds never approves its own output.

If ③ surfaces architecture concerns, the leader dispatches the architect for an "architecture consistency lens" review.

## Delegation Principle

The leader delegates everything except:
- Roadmap selection and checkbox management
- Plan Approval gate (presents architect's plan to user, awaits confirmation)
- Memory file updates (key decisions only)
- Agent and skill definitions (leader.md, CLAUDE.md)

Root cause analysis, investigation, **plan writing**, bash execution, implementation, and verification all belong to agents. When the thought "this is simple enough to do inline" arises, that is the exact cue to delegate immediately.

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

## Graceful Degradation by Environment

| Feature | Claude Code | Codex | Gemini |
|---------|-------------|-------|--------|
| Hub-and-spoke Agent dispatch | Full (Agent tool) | Partial (spawn_agent, multi_agent=true) | Single context, sequential role-switching |
| Automatic hooks (quality gate, viewer) | Full | Not available → manual | Not available → manual |
| Lifecycle discipline | Full | Full | Full |
| Triple Crown verification prose | Full + companion skills | Manual checklist | Manual checklist |
| Slash commands | Full | Partial | Partial |

Automation (hooks, subagents, viewer pane) degrades gracefully. **The lifecycle discipline survives in all environments** — plan → approve → build → verify is the invariant.

## Quick Reference

| Term | Meaning |
|------|---------|
| Hub-and-spoke | Leader routes all agent communication |
| Plan Approval | User gate before any implementation |
| Triple Crown | Three-prong post-implementation verification |
| Thin Ledger | Minimal roadmap — no ceremony |
| builder | Executor — generic implementer; self-check is non-authoritative |
| critic | High-risk plan critic — challenges the plan before build; invoked only when leader gates high-risk; never self-approves a plan |
| reviewer | Verifier — Triple Crown coordinator; holds completion authority |
| `.orbit/` | Project state directory (roadmap, notifications, config) |
| skillify | Optional after-done branch: extract a Rule-of-Three recurring solution into a reusable skill |
