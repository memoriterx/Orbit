# Changelog

All notable changes to orbit are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.6.3] - 2026-06-21

### Fixed
- **신규자 설치 차단 해소:** README 설치 안내의 마켓플레이스 등록 명령에 플레이스홀더(`<orbit-repo-url>`)가 그대로 남아 있어 처음 설치하는 사용자가 막히는 문제를 수정(`memoriterx/Orbit`으로 실값 교체, `ec723c9`).
- **`/orbit-init` 무음 실패 → fail-loud 가드:** `CLAUDE_PLUGIN_ROOT`가 미설정이거나 `templates/` 디렉터리가 없을 때 `cp`가 루트 절대경로로 무음 실패하던 문제를 수정. 이제 명확한 에러 메시지와 함께 즉시 중단하고, `export CLAUDE_PLUGIN_ROOT=<경로>` 후 재실행 안내를 출력한다(`aeec965`).
- **트러블슈팅·주석 사실 정정:** `CLAUDE_PLUGIN_ROOT`가 "보통 자동 감지된다"는 README 트러블슈팅 표의 거짓 주장을 제거. 커맨드 컨텍스트에서 자동 주입이 보장되지 않는다는 사실과 `export` 후 재실행 안내로 교체. orbit-init.md 가드 주석과 일치.

## [0.6.2] - 2026-06-21

### Added
- **신규 사용자 온보딩 보강:** README에 "30분 만에 첫 사이클" Quickstart 워크스루와 "막혔을 때" 트러블슈팅 표 추가. 설치 직후 첫 사이클을 처음부터 끝까지 따라갈 수 있도록 단계별 안내 및 일반적인 오류 원인·해결책을 문서화했다.

## [0.6.1] - 2026-06-20

### Fixed
- **orbit-cycle critic gate (DRIFT-1):** the `skills/using-orbit/orbit-cycle.md` command lifecycle was missing the high-risk critic gate step between plan authoring and Plan Approval. The step — four-trigger OR gate (T1 irreversibility / T2 broad impact / T3 security-integrity / T4 new external dependency); low-risk skips, high-risk routes to critic for independent PROCEED/REVISE verdict — is now present and matches the canonical flow in `CLAUDE.md`, `agents/leader.md`, and the `using-orbit` skill.

### Internal
- Discovery-first step added to dev-team leader and architect definitions (DRIFT-2).
- Dev-team hook and script paths made portable via `CLAUDE_PROJECT_DIR`-relative references (DRIFT-3).

## [0.6.0] - 2026-06-20

### Changed
- **Discovery-first lifecycle step (OMC-6b):** the architect now performs an explicit **discovery** step — framing the problem, requirements, scope, and priority — *before* authoring the plan, delegating internal facts to `explore` and external facts to `researcher` and synthesizing the result. This resolves the long-deferred OMC-6 (planner/architect separation): rather than adding an eighth `planner` agent (found ~90% redundant with explore/researcher/architect), discovery is codified as a named pre-plan step in the existing architect contract. **No new agent, no new hand-off; the roster stays at seven.** Append-only across five lifecycle surfaces (architect / CLAUDE / leader / using-orbit skill / orbit-cycle); the four-phase summary lines (plan → approve → build → verify) are intentionally left unchanged since discovery is a sub-step of the plan phase.

### Fixed
- **codex manifest role count:** `.codex-plugin/plugin.json` longDescription said "Five roles (leader/architect/builder/reviewer/researcher)" — corrected to "Seven roles (leader/architect/builder/explore/critic/reviewer/researcher)" to include the explore and critic agents.

## [0.5.0] - 2026-06-20

### Added
- **unattended skip-and-park profile (AUTO-1):** opt-in autonomous execution profile. When unattended, high-risk/ambiguous tasks are *parked* (never auto-decided or auto-built) while low-risk tasks complete to the end; the parked list is reported for human review. Default `halt-on-trigger` profile unchanged. Safety: parked high-risk is never auto-built; verification (②/③) failures halt under both profiles; D4 fail-closed (a pending task builds only if independence from every parked task is affirmatively clear, else parks); parked tasks are excluded from continuation batches and ≥3 outstanding parked tasks declines further autonomous batches. Documented as *conditional whole-loop safety*, not halt-equivalence. Zero new infrastructure; harness `C15a–g` added.
- **Independent Fan-out → Fan-in pattern (PERF-1):** codifies leader-driven concurrent dispatch of independent work with the leader as the sole fan-in point (hub-and-spoke preserved). Read-only investigation/review is parallel-safe; **builds/commits always stay serial** (cumulative T2, skip-and-park D4, and halt-on-first-failure all assume one commit at a time). Includes a 4-point independence test (uncertain ⇒ serial). Append-only prose in `skills/using-orbit/SKILL.md` and `agents/leader.md`; zero new infrastructure.

### Fixed
- **viewer pane noise (`scripts/agent-view.py`, `scripts/attach-view.sh`, new `scripts/view-run.sh`):** the live subagent viewer now exits cleanly on SIGTERM/SIGINT (no more `zsh: terminated` messages when the viewer is replaced), shows an idle "waiting" banner instead of leaving a bare shell prompt between subagents, and launches through a short `view-run.sh` wrapper so the pane echoes one short line instead of a long compound command.

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

[0.6.2]: https://github.com/memoriterx/Orbit/releases/tag/v0.6.2
[0.6.1]: https://github.com/memoriterx/Orbit/releases/tag/v0.6.1
[0.6.0]: https://github.com/memoriterx/Orbit/releases/tag/v0.6.0
[0.5.0]: https://github.com/memoriterx/Orbit/releases/tag/v0.5.0
[0.4.0]: https://github.com/memoriterx/Orbit/releases/tag/v0.4.0
[0.3.0]: https://github.com/memoriterx/Orbit/releases/tag/v0.3.0
[0.2.0]: https://github.com/memoriterx/Orbit/releases/tag/v0.2.0
