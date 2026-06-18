---
name: skillify
description: Use after a task completes when the same procedure or solution has recurred across three or more separate tasks (Rule of Three). Extracts the recurring pattern into a reusable, auto-discoverable project skill. Defines the lifecycle trigger, routing, and output format — delegates authoring craft to writing-skills.
---

# Skillify — Extract Recurring Solutions into Skills

Skillify is Orbit's lifecycle convention for turning a repeatedly-solved problem into a permanent, auto-discoverable skill. It defines **when** extraction starts, **who** does each step, **what** the output must look like, and **how** the result is auto-discovered. It does not re-teach skill-authoring craft — that belongs to `superpowers:writing-skills`.

## When to Extract: The Rule of Three

Extract only when the **same** procedure, fix, or technique has been applied in **three or more separate tasks**. One or two occurrences may be coincidence — do not extract (YAGNI). Extract reusable techniques, patterns, and tool usages — never a narrative of how one problem was solved once.

Signals that meet the Rule of Three:
- The same multi-step procedure was re-derived from scratch in three tasks.
- The reviewer flagged the same class of fix in three separate Triple Crown reviews.
- Three plans contained a near-identical setup/scaffolding sequence.

## Who Does What (hub-and-spoke routing)

Skillify never bypasses the leader. The routing is:

`reviewer detects → leader routes → architect extracts → builder writes`

| Step | Agent | Action |
|------|-------|--------|
| Detect | reviewer | During or after Triple Crown, recognizes a Rule-of-Three signal and reports it to the leader as text. |
| Route | leader | Decides whether the pattern is worth extracting; if so, dispatches the architect to draft the skill. No reviewer→architect direct contact. |
| Extract | architect | Drafts the skill content (proposal only — does not write product files directly). Loads `superpowers:writing-skills` for authoring craft. |
| Write & approve | builder + Plan Approval | A new skill is a product change, so it follows the normal lifecycle: leader presents the architect's proposal for Plan Approval, then the builder writes the file. |

Skillify is an **optional opt-in branch after `done`** in the single-task lifecycle. It is never a required step and never blocks task completion.

## What the Output Must Look Like (format spec)

Every extracted skill is a project skill that follows the Orbit skill convention:

```
skills/<skill-name>/SKILL.md
```

- The directory name and the frontmatter `name` must match and be kebab-case.
- frontmatter has exactly two fields: `name` and `description`. Skills carry no `model:` field (only agents do).
- `description` MUST state *when* the skill applies — this is what drives auto-discovery (see below).
- Keep domain values as slots (`{{...}}`) when the skill is domain-agnostic; never hardcode a specific project name.
- Add a `references/` subdirectory only if the body grows too long to hold in one read (YAGNI otherwise).

Example skeleton:

```markdown
---
name: <skill-name>
description: Use when <trigger situation> to <outcome>.
---

# <Skill Title>

<one-paragraph overview>

## <Steps or reference content>
```

## How It Is Auto-Discovered (native, no hook)

Auto-injection requires **no custom hook**. Claude Code natively indexes every `skills/<name>/SKILL.md` by its frontmatter `name`/`description` and loads the skill when the model meets a situation matching the `description`. This is **native skill discovery**.

Therefore the only requirement skillify enforces for discoverability is a precise, trigger-describing `description`. Do not add SubagentStart/UserPromptSubmit hooks to force injection — that would break in environments without hooks (Codex, Gemini) and duplicate native discovery.

## Authoring Craft Is Delegated

Skillify defines the lifecycle integration only. For *how to write a skill well* — observing baseline failure, writing the SKILL.md, and pressure-testing it (TDD for skills) — use `superpowers:writing-skills`. Do not duplicate that guidance here.

## Quick Reference

| Term | Meaning |
|------|---------|
| Rule of Three | Extract only after the same solution recurs in 3+ separate tasks |
| Routing | reviewer detects → leader routes → architect extracts → builder writes |
| native skill discovery | Auto-injection via SKILL.md frontmatter; no custom hook |
| opt-in branch | Skillify is optional after `done`; never blocks completion |
