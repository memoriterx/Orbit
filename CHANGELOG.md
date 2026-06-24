# Changelog

All notable changes to orbit are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [2.1.0] - 2026-06-24

### Added (guidance, non-breaking — TIER-2 / L1 / L2)

- **7역할 동반 스킬 배선 (TIER-2 prose guidance):** architect/builder/leader/explore/critic/reviewer/researcher
  모든 역할에 "Companion skill wiring (guidance)" 섹션 추가. `[A-directive]`(항상 고려)/`[C]`(조건부 고려)/N/A
  분류로 역할별 적합 스킬 안내. **강제 아님** — 역할 프롬프트는 스킬 사용을 지시하지만 기계적으로
  강제하지 않는다. 미설치 시 역할의 자체 방법으로 대체된다. 단순/메타 작업에는 불필요.
  배포물(`plugins/orbit/`) + dev팀(`.claude/`) 양쪽 14개 파일 업데이트.

- **L1 고려 제공 레이어 (`skill-consideration.sh` 훅 + hooks.json SubagentStart 엔트리):**
  서브에이전트 스폰 시 역할별 현재 설치된 스킬 목록과 "고려 후 사용 또는 건너뛰기" 지시를
  `hookSpecificOutput.additionalContext`로 주입. **비차단·비강제** — SubagentStart는 구조적으로
  차단 불가; L1은 고려 프롬프트 전달만 보장하며 에이전트의 실제 스킬 사용은 에이전트 판단에 맡긴다.
  동반 플러그인 미설치 시 해당 스킬은 주입하지 않음(팬텀 스킬 참조 방지). 역할→스킬 맵은
  `.orbit/config`에서 설정 가능 (`{{ROLE_SKILL_MAP}}` 슬롯).

### Notes on labeling

- TIER-2 스킬 배선은 "guidance"이며 "required/enforced"가 아니다. 프롬프트는 지시하지만 강제하지 않는다.
- L1은 "consideration delivery"이며 "required/enforced"가 아니다. 에이전트 준수(compliance)는
  검증 불가이며 의도적으로 테스트하지 않는다. skip은 명시적으로 허용된다.
- TIER-1(enforced)은 v2.0.0에서 별도 BREAKING 엔트리로 기록됨.

## [2.0.0] - 2026-06-24

### Changed (BREAKING — TIER-1 enforcement only)

- **Triple Crown 검증 프롱에 동반 플러그인 필수 (TIER-1 BREAKING):**
  reviewer Triple Crown ①②③ 프롱이 각 동반 플러그인 없이는 FAIL 처리된다.
  이는 v1.0.0의 "자체 완결/graceful 저하" 보장을 의도적으로 역전한 변경이다.
  - ① 완성도 프롱: **GSD** (`/gsd-verify-work`) 필수. 미설치 시 FAIL.
  - ② 동작 프롱: **gstack** (`/qa`) 필수. 미설치 시 FAIL.
  - ③ 품질 프롱: **superpowers** (`superpowers:requesting-code-review`) 필수. 미설치 시 FAIL.

- **SubagentStop 훅 스코핑 (BLOCKER #1 픽스):** 동반 플러그인 체크는 **reviewer 완료 시에만**
  트리거된다 (SubagentStop `agent_type` 필드 기준). 빌드/탐색/메타 작업은 동반 플러그인 없어도
  차단되지 않는다. `claude` CLI 미가용 시 non-blocking 경고 후 reviewer 보고 계약에 위임.
  두 개의 독립 게이트: SubagentStop 훅 + reviewer 보고 계약.

- **계획·구현 단계는 차단 없음:** 동반 플러그인은 검증 프롱에서만 필수다.
  planning/building 작업은 동반 플러그인 없이도 실행된다.

- **manifests 업데이트 (ADR-REQDEPS-3 honesty):** `plugin.json`·`marketplace.json` 설명이
  vendor-lock을 명시한다. "어떤 기술 스택에도 적용 가능/도메인 무관" 카피 제거.
  orbit v2.0.0은 검증 레이어에서 Claude Code 전용이며 이를 솔직하게 반영한다.

### Added

- **ORBIT_SKIP_COMPANION_CHECK=1 탈출구:** CI/헤드리스/오프라인 환경에서 훅 레이어 체크 건너뜀.
  reviewer 보고 계약(D3)은 이 변수와 무관하게 유지 — 훅만 비활성화, reviewer 계약은 유지.
  영구 활성화 방지책 없음 = 자동화 신뢰 의도 (ADR-REQDEPS-2). `.orbit/config` 템플릿에 주석 시드.

### Migration

- Triple Crown 검증을 사용하려면 세 동반 플러그인을 모두 설치해야 한다:
  - superpowers: `/plugin install superpowers@claude-plugins-official`
  - GSD: `/gsd-help` 또는 `/plugin install gsd`
  - gstack: `git clone --single-branch --depth 1 https://github.com/garrytan/gstack.git ~/.claude/skills/gstack && cd ~/.claude/skills/gstack && ./setup`
- CI/자동화 환경에서 검증을 건너뛰려면: `ORBIT_SKIP_COMPANION_CHECK=1`
  (reviewer 보고 계약이 유일한 잔존 강제가 됨을 참고)

### Notes

- `dependencies` 배열 미추가 (ADR-REQDEPS-1): cross-marketplace 해결 불가 → 런타임 fail-loud 가드로 구현.
- 인터페이스 버전 핀닝 없음 (MINOR #7): 동반 플러그인 이름 변경 시 명확한 "명령어 없음" 오류로 표면화.
  예상 명령어를 오류 메시지에 명시하므로 이름 변경은 silent pass가 아닌 visible fail이 된다.
- D8 (의도된 hook 비대칭): dev팀 SubagentStop은 `.claude/settings.json` 인라인으로 별도 운용.
  dev팀은 dogfood 환경으로 항상 동반 플러그인이 설치돼 있어 의도된 비대칭이다 (drift 아님).

## [1.0.0] - 2026-06-21

### Changed
- **BREAKING:** the plugin install identifier is renamed `orbit-base` → `orbit`.
  Install now with `/plugin install orbit`. The directory `plugins/orbit-base/`
  moved to `plugins/orbit/`. The repository (`memoriterx/Orbit`) and marketplace
  name (`orbit-marketplace`) are unchanged.

### Migration
- Existing installs of `orbit-base` continue to function locally but no longer
  receive updates under the old name. To migrate:
  `/plugin uninstall orbit-base` then `/plugin install orbit`
  (the marketplace is already registered; no re-add needed).

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

[2.1.0]: https://github.com/memoriterx/Orbit/releases/tag/v2.1.0
[2.0.0]: https://github.com/memoriterx/Orbit/releases/tag/v2.0.0
[1.0.0]: https://github.com/memoriterx/Orbit/releases/tag/v1.0.0
[0.6.2]: https://github.com/memoriterx/Orbit/releases/tag/v0.6.2
[0.6.1]: https://github.com/memoriterx/Orbit/releases/tag/v0.6.1
[0.6.0]: https://github.com/memoriterx/Orbit/releases/tag/v0.6.0
[0.5.0]: https://github.com/memoriterx/Orbit/releases/tag/v0.5.0
[0.4.0]: https://github.com/memoriterx/Orbit/releases/tag/v0.4.0
[0.3.0]: https://github.com/memoriterx/Orbit/releases/tag/v0.3.0
[0.2.0]: https://github.com/memoriterx/Orbit/releases/tag/v0.2.0
