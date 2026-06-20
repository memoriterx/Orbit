# Orbit — AI-Neutral Operating Rules

This file defines the methodology and operating discipline for any project using the Orbit framework. It is the single source of truth for all AI environments.

## Framework: Orbit

Orbit is a hub-and-spoke multi-agent team framework for structured software delivery.

**Team roles:** leader / architect / builder / explore / critic / reviewer / researcher (7 roles)  
**State directory:** `.orbit/` in the project root  
**Skill reference:** `skills/using-orbit/SKILL.md`

## Single-Task Lifecycle Trigger

Whenever working on a meaningful piece of project work, apply the single-task lifecycle:

```
roadmap selection
→ leader dispatches architect (writing-plans) → architect produces plan
→ High-risk? leader gates critic (independent plan critique) → architect revises; low-risk skips
→ Plan Approval: leader presents architect's plan → user confirms
→ leader dispatches builder (TDD) → post-implementation Triple Crown
  ① Completeness   ② Behavior   ③ Quality
→ done (roadmap checkbox)
```

Simple questions, meta tasks, and configuration changes do not require the full lifecycle.

**Leader writes nothing.** Plan writing, design, investigation, and implementation all belong to agents (architect or builder). The leader's direct actions are limited to: roadmap selection, dispatching agents, presenting plans for approval, and marking roadmap checkboxes.

## Hub-and-Spoke Communication Rule

All agent communication routes through the leader. No agent communicates directly with another agent. The leader dispatches, collects, and synthesizes.

## Context Management

- Read the architecture reference document (`{{ARCHITECTURE_DOC_PATH}}`) at task start if it exists.
- Keep the roadmap thin: backlog, current task, milestones, completeness criteria.
- Promote key decisions to project memory after task completion.
- Do not re-derive context already captured in memory files.

## Plan Approval Gate

No implementation proceeds without the user's explicit approval of the written plan — given per task, or once over a pre-approved batch scope (see Autonomous Mode). This gate is non-negotiable: any four-trigger high-risk firing always forces individual human approval.

Approval criteria:
1. Tests included or testing strategy defined
2. Impact scope clearly stated
3. No architecture conflicts
4. Success criteria measurable

## Autonomous Mode (opt-in)

Autonomous mode is **off by default**. Absent an explicit batch pre-approval, every task uses the standard per-task Plan Approval Gate above — unchanged. Autonomous mode never weakens that gate; it exercises it once over a stated scope.

**Batch pre-approval.** The user may exercise the Plan Approval Gate **once** over a *named, finite, enumerable set of tasks* (explicit roadmap IDs, or a bounded predicate over the roadmap). Open-ended scope ("just keep going") is not valid; the leader declines it and requests a bounded scope. Batch pre-approval is the same human gate, exercised once — not its removal.

**Critic-on-entry (independent eligibility screen).** Before the user grants the pre-approval, the leader enumerates the scope and dispatches the **critic once** to independently review the *entire enumerated batch* — confirming every task is manifestly all-no on the four triggers. Any task the critic flags as high-risk or ambiguous is removed from the autonomous batch and routed to normal per-task approval; the user pre-approves only the critic-cleared remainder. This is a second pair of eyes at the entry point, not only after a trigger fires mid-loop. Reuses the existing critic agent.

**Low-risk (autonomous-eligible).** A task is eligible if and only if **all four** of the four-trigger OR gate conditions are *manifestly no* (the same four triggers the critic uses), with no ambiguity:
1. Reversible (no data migration / rewrite / backward-compat break).
2. Contained (< 3 components AND no public interface/contract change) — judged on **batch-cumulative blast radius**, not the task alone.
3. Integrity-neutral (no auth / permissions / secrets / deletion / money / PII path).
4. No new external dependency.

"Repetitive" and "exploratory" are motivations for batching, not separate gates. The four triggers are the sole, measurable eligibility criterion.

**Conservative default (ambiguous ⇒ stop).** Eligibility requires a *manifestly all-no* judgment. If any trigger's verdict is unclear, borderline, or a low-confidence call, the task is **not eligible**: the loop halts and the task goes to individual human Plan Approval. The rule is **"ambiguous ⇒ stop", never "ambiguous ⇒ proceed."** The only path to autonomous execution is an unambiguous all-no.

**Batch-cumulative blast radius (T2) + batch-size cap.** T2 is judged against the **running cumulative total of distinct components touched by the batch so far** (not per-task-in-isolation): before each task the leader sums components already modified plus those the next task touches; reaching ≥ 3 distinct components fires T2 and halts the loop. An autonomous batch is additionally capped at **at most 5 tasks per pre-approval**; on reaching either ceiling the loop halts and the leader returns to the human for an explicit **re-sync** (re-state what was done, request fresh pre-approval for any continuation). This bounds accumulation, cross-task interaction, and context drift.

**Scope re-validation (staleness guard).** Scope is enumerated once at pre-approval, but the codebase/roadmap change during the loop. **At each task boundary** the leader re-confirms scope validity before the next task: if the roadmap/codebase has materially changed (items added/removed, or a completed task altered a pending task's assumptions), the leader **re-enumerates and re-runs critic-on-entry over the remaining items** before continuing. Per-task plans are generated at loop time (never pre-generated stale at the batch start), so each reflects the codebase as it is at that iteration.

**Auto-halt (hard).** During an autonomous batch, the leader applies the four-trigger gate (manifestly-all-no standard, batch-cumulative T2) to each task's plan. If **any** trigger fires **or the judgment is ambiguous**, the task is **ejected from the batch**, the **loop halts**, and the task escalates to **individual human Plan Approval** (with the critic branch, since a trigger fired). The human gate for high-risk work remains non-negotiable.

**Execution profiles (default `halt-on-trigger`; opt-in `skip-and-park`).** Autonomous Mode has two execution profiles, both opt-in within a batch pre-approval and fixed for the batch at pre-approval time:
- **`halt-on-trigger` (default).** Any four-trigger firing or ambiguous judgment ejects the task and **halts the entire loop**; remaining tasks are not attempted until the human resolves the ejected task. This is the prior, unchanged behavior. If the user names no profile, this applies.
- **`skip-and-park` (opt-in alternate).** Any four-trigger firing or ambiguous judgment ejects the task into a **parked set** and the loop **continues** with the remaining low-risk tasks. At batch end the leader reports the parked set. **`skip-and-park` is not a relaxation of the gate:** a parked (high-risk or ambiguous) task is **never auto-decided or auto-implemented** — it returns to individual human Plan Approval with the critic branch (since a trigger fired or the task was ambiguous). "ambiguous ⇒ park" is the same prohibition as "ambiguous ⇒ stop"; park changes only *which* tasks pause (the one task, not the whole loop), never letting an ambiguous task proceed. The sole path to autonomous execution remains an unambiguous all-no.

**Accounting under both profiles.** The cumulative blast-radius tally (T2) counts distinct components touched **only by tasks actually built (completed Triple Crown)**; a parked task is never built and contributes **zero** components — parking neither resets nor lowers the running tally, so a long `skip-and-park` run still hits the cumulative ceiling and re-syncs. The batch-size cap likewise counts **completed (built)** tasks (halt for re-sync on the 5th completion); parked tasks do not consume a slot. The enumeration ceiling at pre-approval stays ≤ 5 candidate tasks under either profile.

**Amortization guard (no re-sync laundering).** Parked tasks are **excluded from every autonomous continuation batch** — being parked means they are no longer manifestly all-no, so they re-enter only through individual per-task Plan Approval; the autonomous scope and the parked set are disjoint by construction. This prevents re-syncing from resetting the cumulative ceiling around a carried-forward high-risk task. Additionally, if **3 or more parked tasks are outstanding**, the leader **declines to grant any further autonomous batch** until the human has cleared the parked backlog — the parked set cannot grow unbounded behind human oversight.

## Verification Standard

Every implementation concludes with Triple Crown verification:

1. **Completeness** — all plan items built (GSD / roadmap comparison)
2. **Behavior** — runtime behavior confirmed (not just static code review)
3. **Quality** — code review for correctness, security, maintainability

All three prongs must pass before the task is declared complete.

## Memory vs. Roadmap

- **Roadmap** (`.orbit/roadmap.md`): what to do next — backlog, milestones, current pointer
- **Memory** (`{{MEMORY_PATH}}`): why decisions were made — architectural decisions, context, lessons learned

Completed tasks get a roadmap checkbox. Key decisions get a memory entry.

## Agent Dispatch Pattern

```
Agent(role, background=True/False, prompt=...)
```

Agent output is text returned to the leader. The leader reads it and decides the next step. No agent-to-agent communication.

## Notification Channel

Progress updates go to `.orbit/notifications.log`. No other side channels.

## Quality Gate

Project-specific quality gates (typecheck, lint, test) are defined in `.orbit/quality-gate.sh`. If not present, gates pass (no-op). The `builder` runs this before reporting completion.

## Domain Slots (filled by project or preset)

| Slot | Filled by |
|------|-----------|
| `{{ARCHITECTURE_DOC_PATH}}` | Project CLAUDE.md override |
| `{{MEMORY_PATH}}` | Project CLAUDE.md override |
| `{{PRODUCT_PATHS}}` | Project CLAUDE.md override — paths the leader must not directly modify |
| `{{QUALITY_GATE_CMD}}` | `.orbit/quality-gate.sh` |
