# Orbit — AI-Neutral Operating Rules

This file defines the methodology and operating discipline for any project using the Orbit framework. It is the single source of truth for all AI environments.

## Framework: Orbit

Orbit is a hub-and-spoke multi-agent team framework for structured software delivery.

**Team roles:** leader / architect / builder / critic / reviewer / researcher (6 roles)  
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

No implementation proceeds without the user's explicit approval of the written plan. This gate is non-negotiable.

Approval criteria:
1. Tests included or testing strategy defined
2. Impact scope clearly stated
3. No architecture conflicts
4. Success criteria measurable

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
