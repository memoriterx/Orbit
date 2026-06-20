# Changelog

All notable changes to orbit-base are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.4.0] - 2026-06-20

### Added
- **task-group lightweight convention (GROUP-1):** large features spanning several tasks can now express cohesion in the roadmap with a **group header** (`### [GROUP-NAME] <description>`) and an **ID prefix** (`[PREFIX-N]`) on each member task — pure naming convention, zero new structure, hooks, or schema. Surfaces touched: `skills/using-orbit/SKILL.md` (Thin Ledger § Grouping Large Features) and `templates/roadmap.template.md`. **A group is a manual label, not an active progress tracker** — no roll-up field, no lifecycle change, hub-and-spoke unchanged. It does not replace milestones: milestones remain post-hoc labels for completed work; a group is an in-place cohesion device for backlog items. The roadmap stays a thin ledger — this is naming, not ceremony.

## [0.3.0] - 2026-06-19

### Added
- **explore agent (OMC-5):** new `agents/explore.md` — read-only internal codebase search via glob/grep/read fan-out. Separates role boundary with researcher (external sources). Model `sonnet`. Roster grows from 6 to 7.
- **opt-in autonomous mode (OMC-7):** batch pre-approval for low-risk task sets with leader autonomous loop. No new agents, hooks, state files, or dependencies — reuses existing critic four-trigger gate and Plan Approval. Off by default (opt-in). Safety guardrails: critic-on-entry independent screen, conservative default (ambiguous ⇒ stop), batch-cumulative blast radius, batch cap ≤5 + human re-sync, scope re-validation at each task boundary, Triple Crown verification strength unchanged.
- **Triple Crown ③ security deep-mode (OMC-8):** conditional security deep-scan mode in reviewer's ③ quality prong. Entered if and only if the reviewer's own built-diff touches a security surface (critic T3) — leader forward is a non-authoritative hint. Strengthens existing reviewer without adding a new agent. `{{SECURITY_CHECK_CATEGORIES}}` slot. Read-only review boundary preserved.

### Fixed
- Restored roster consistency across 5 surfaces after explore agent was absent from `agents/leader.md` Team Structure table and `references/codex-tools.md` role list (OMC-5 follow-up).

## [0.2.0] - 2026-06-18

### Added
- **Per-role model tiers (OMC-1):** explicit model assignment per agent — researcher `haiku`, builder `sonnet`, architect/reviewer `opus`, leader `sonnet`.
- **skillify skill (OMC-3):** `skills/skillify/SKILL.md` codifies the Rule of Three — after a pattern recurs three times, reviewer flags it, the leader routes extraction through architect, and builder authors the skill (authoring delegated to superpowers writing-skills). Surfaced via native skill discovery — no new hook.
- **critic agent (OMC-4):** a sixth agent (`agents/critic.md`, `opus`) that independently critiques the architect's plan (PROCEED/REVISE) for high-risk decisions. The leader gates on a four-trigger OR (irreversibility / broad impact / security-integrity / new external dependency) immediately before Plan Approval; low-risk work skips the branch.

### Changed
- **executor/verifier separation (OMC-2):** the reviewer is now the authoritative completion-decision holder (absorbing the verifier role); builder self-check is demoted to a non-authoritative pre-flight. Triple Crown remains the completion gate.
- Aligned all role surfaces (leader / builder / reviewer / using-orbit skill) and distribution manifests (codex, gemini) with the above changes.

[0.4.0]: https://github.com/memoriterx/Orbit/releases/tag/v0.4.0
[0.3.0]: https://github.com/memoriterx/Orbit/releases/tag/v0.3.0
[0.2.0]: https://github.com/memoriterx/Orbit/releases/tag/v0.2.0
