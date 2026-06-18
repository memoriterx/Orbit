# Changelog

All notable changes to orbit-base are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.2.0] - 2026-06-18

### Added
- **Per-role model tiers (OMC-1):** explicit model assignment per agent — researcher `haiku`, builder `sonnet`, architect/reviewer `opus`, leader `sonnet`.
- **skillify skill (OMC-3):** `skills/skillify/SKILL.md` codifies the Rule of Three — after a pattern recurs three times, reviewer flags it, the leader routes extraction through architect, and builder authors the skill (authoring delegated to superpowers writing-skills). Surfaced via native skill discovery — no new hook.
- **critic agent (OMC-4):** a sixth agent (`agents/critic.md`, `opus`) that independently critiques the architect's plan (PROCEED/REVISE) for high-risk decisions. The leader gates on a four-trigger OR (irreversibility / broad impact / security-integrity / new external dependency) immediately before Plan Approval; low-risk work skips the branch.

### Changed
- **executor/verifier separation (OMC-2):** the reviewer is now the authoritative completion-decision holder (absorbing the verifier role); builder self-check is demoted to a non-authoritative pre-flight. Triple Crown remains the completion gate.
- Aligned all role surfaces (leader / builder / reviewer / using-orbit skill) and distribution manifests (codex, gemini) with the above changes.

[0.2.0]: https://github.com/memoriterx/Orbit/releases/tag/v0.2.0
