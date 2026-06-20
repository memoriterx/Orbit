# orbit 개발 로드맵

**업데이트:** 2026-06-18  
**상태 경로:** `.planning/`  
**보고 채널:** `.planning/notifications.log`

---

## 현재 진행 중

(없음 — 다음 작업은 아래 백로그에서 선택.)

---

## 백로그

### OMC 흡수 — orbit-base 개선 4건

- [x] **[OMC-1] 역할별 모델 티어 명시** (2026-06-18, 커밋 `dc6450e`)  
  researcher=haiku, builder=sonnet, architect/reviewer=opus, leader=sonnet.  
  실측 결과 4종은 이미 목표 티어와 일치 → researcher.md 단 1건만 sonnet→haiku 변경. Triple Crown 3갈래 PASS.

- [x] **[OMC-2] executor/verifier 분리** (2026-06-18, 커밋 `5668e08`·`b45d8f9`·`df70a82`·`b7b2dc9`)  
  ADR-1: verifier.md 신규 추가 대신 **기존 reviewer가 verifier 흡수** (이미 독립 에이전트로 분리됨).  
  builder self-check를 비권위적 pre-flight로 강등, reviewer를 완료 판정 권한 보유자로 명시.  
  4개 표면(builder/reviewer/leader.md + using-orbit SKILL) 프롬프트 정렬. Triple Crown 3갈래 PASS.

- [x] **[OMC-3] skillify 패턴** (2026-06-18, 커밋 `2fe8832`·`2d4c453`·`f799afb`·`cabb932`)  
  신규 `skills/skillify/SKILL.md` — 트리거 Rule of Three(3회 규칙), 라우팅 reviewer 감지→leader→architect 추출→builder 작성.  
  ADR-3: native skill discovery로 자동주입(신규 훅 0). ADR-4: authoring은 superpowers writing-skills에 위임(중복 회피).  
  using-orbit/leader/reviewer 정렬. Triple Crown 3갈래 PASS.

- [x] **[OMC-4] ralplan식 3자 비판 계획** (2026-06-18, 커밋 `c63a0b8`·`c516343`·`182564b`·`44bd26a`)  
  신규 `agents/critic.md`(opus, 6번째 에이전트) — 고위험 결정 시 architect 플랜 독립 비판(PROCEED/REVISE).  
  고위험 4트리거 OR 게이트(비가역성/광범위 영향/보안·무결성/신규 외부 의존성), leader가 Plan Approval 직전 판정, 저위험은 분기 생략.  
  leader/CLAUDE/using-orbit SKILL/codex/gemini 정렬. ADR-1: critic은 신규(self-approval 차단의 설계 단계 적용). Triple Crown 3갈래 PASS.

### OMC 비교 2차 — 에이전트/스킬 확장 (2026-06-18 발굴, 미착수)

OMC(oh-my-claudecode) 레포 재비교로 발굴. OMC-1~4 흡수 완료분 제외, neue gap만.
> ⚠️ Verifier 전담 에이전트는 **추가 금지** — OMC-2 ADR(reviewer가 verifier 흡수)로 기각됨.

- [x] **[OMC-5] Explore 에이전트** (2026-06-18, 커밋 `12d4beb`·`8a45439`·`1ecd41f`·`e532a12`)  
  신규 `agents/explore.md` — 내부 codebase 검색 전담 read-only(glob/grep/read fan-out). researcher(외부)와 4자 경계표로 분리.  
  모델 `sonnet`(OMC haiku 대비 상향: 관계·영향 합성). 로스터 6→7, using-orbit/codex/gemini 4표면 정렬. Triple Crown 3갈래 PASS(시범 dispatch 무편집 직접 검증).

- [~] **[OMC-6] Planner / Architect 책임 분리** — **보류** (2026-06-18, critic REVISE)  
  플랜(`.planning/2026-06-18-planner-agent-separation.md`)은 작성됐으나 critic 게이트에서 보류 결정.  
  근거: ① 전제("architect 과부하")가 실측 아닌 OMC 대칭 맞추기 — 옮겨갈 책임은 요구사항 1줄+태스크 1단계뿐인데 해법은 신규 opus 에이전트+12파일 계약 변경. ② 대안(b)(architect 단독 저자 유지, planner는 발견만)이 플랜 자체 D2 논리상 더 우수한데 미검토. ③ 경량성(7→8역, 매 작업 핸드오프 1회 추가) 트레이드오프.  
  **재검토 조건: dogfooding에서 architect 과부하가 실제 관측될 때.** 현행 7역 유지.

- [x] **[OMC-7] 선별 스킬 도입 → 스킬 이식 종결, 자율모드로 진화** (2026-06-19)  
  researcher 종속성 조사 결과: OMC 41종 스킬 대부분이 OMC 고유 인프라(`/team`·`/ralph`·MCP·공유큐) 종속이거나 orbit 스택(superpowers/gstack/gsd/skillify)과 중복 → **이식 가치 있는 독립 스킬 없음**. 자동화 모드(autopilot/ralplan/team)는 허브앤스포크·사람게이트와 구조적 충돌.  
  대신 사용자 제안으로 **opt-in 자율 실행 모드(접근 A)** 로 방향 전환 → 아래 완료 항목 참조.

- [x] **[OMC-8] 보안 검증 → Security-Reviewer만, 신규 에이전트 대신 reviewer ③ deep-mode** (2026-06-19, 커밋 `e1a8771`·`5d6c19e`·`9b9f3c9`·`67b21ab`·`469c18b`)  
  사용자가 Designer/QA는 보류, Security-Reviewer만 선택. critic 1차 REVISE(전담 에이전트 → 자율모드 상호배타·로스터 churn) → **신규 에이전트 없이 reviewer ③ 품질에 조건부 보안 deep-mode** 대안 채택.  
  진입: reviewer 자체 built-diff가 보안 표면(critic T3) touch 시 iff(리드 forward는 비권위 힌트). critic.md T3가 표면 정규 참조원. 자율모드 상호배타(보안=T3 추방→per-task 전용). read-only review 경계 유지.  
  **부수: explore 로스터 누락 버그 수정**(leader.md 표 + codex-tools.md — OMC-5에서 빠졌던 2표면). 집합일치 게이트(런타임 추출 set-diff)로 5표면 검증.  
  critic 게이트 **3라운드**(전담에이전트 REVISE → deep-mode B1·B2·N1·N2 REVISE → PROCEED). Triple Crown 3갈래 PASS(perturbation 역검증 포함).
  > advisory: 향후 신규 역할 추가 시 6-스포크(leader/SKILL/gemini) vs 7-full(CLAUDE/codex) 양쪽 + set-diff allow-list 갱신 필요.

---

## 완료

- [x] **[GROUP-1] Epic/task-그룹 경량 컨벤션 (옵션 1)** (2026-06-20, 커밋 `8bde931`·`26bdfd7`)  
  researcher 산업표준 조사: 지배 모델은 `task 흐름 + Epic/Project 묶음 + milestone 마커` 3계층인데 orbit은 중간 묶음 계층 부재. architect 비교 스파이크(4안: 현상유지/경량컨벤션/1급Epic/외부위임) → **옵션 1(경량 컨벤션)** 채택.  
  배포물 2표면만(SKILL.md "Thin Ledger"에 "Grouping Large Features" 문단 + roadmap.template.md 주석 예시). 그룹 헤더 `### [GROUP-NAME]`·ID 접두사 `[PREFIX-N]`·부모참조 `↳ part of`·**가드 문구**("manual label, not active progress tracker" — 옵션2 미끄러짐 3중 차단). 스키마·훅·생명주기·milestone 의미론 무변경, 가역(revert).  
  저위험 확정(4트리거 all-no) → critic 생략. Triple Crown 3갈래 PASS(No-Touch diff·도메인순수성 grep·자기일관성 독립 재현). 스파이크/플랜: `.planning/plans/2026-06-20-spike-epic-group-layer.md`·`2026-06-20-plan-epic-group-convention.md`.

- [x] **opt-in 자율 실행 모드 (접근 A 전체)** (2026-06-19, 커밋 `5ed666d`·`003a394`·`19bbf4a`·`91651dc`·`1bcc70a`·`6cc0fd9`·`0944aae`·`ba38d59`)  
  OMC-7에서 진화. 저위험 작업 묶음 일괄 선승인 + 리드 자율 루프. **신규 에이전트·훅·상태파일·의존성 0** — 기존 critic 4트리거 게이트·리드 루프·Plan Approval 재사용한 순수 계약 정렬.  
  안전장치: opt-in 기본 비활성 / critic-on-entry 독립 검증 / 보수적 기본값(모호⇒정지) / 누적 blast radius / 배치 상한 ≤5+재동기화 / 경계 범위 재검증 / Triple Crown 검증강도 불변 / N1 carve-out.  
  설계 스파이크(A vs B 비교, B 기각) → critic 게이트 **2라운드**(블로커#1+major#2·#3 → N1·N2) → Plan Approval. 7표면 정렬, 하네스 C1–C14 + 역검증 PASS, Triple Crown 3갈래 PASS, 배포물만 수정 diff 검증.

- [x] **orbit 자체 개발팀 환경 구성** (2026-06-18)  
  `.claude/agents/` (5역: leader/architect/builder/reviewer/researcher),  
  `.claude/settings.json` (훅 6종: Stop/Notification/MessageDisplay/UserPromptSubmit/SubagentStop/SubagentStart),  
  `CLAUDE.md`, `setup-orbit-dev.sh`, `.planning/roadmap.md` + usage-detect/resume-inject 이식.

---

## 마일스톤

| 마일스톤 | 목표 | 기준 |
|----------|------|------|
| M1 — 팀 환경 | dev팀이 orbit을 dogfooding으로 개발 가능 | 완료 |
| M2 — OMC 흡수 | 4건 백로그 완료 + orbit-base 품질 게이트 통과 | **완료 (2026-06-18)** |
| M3 — 릴리스 v0.2 | 에이전트 모델 티어 + executor/verifier 분리 반영 | **게시 완료 (2026-06-19, 태그 `v0.2.0` push)** |
| M4 — 릴리스 v0.3 | explore 에이전트 + opt-in 자율모드 + 보안 ③ deep-mode | **게시 완료 (2026-06-19, 태그 `v0.3.0` push)** |
| M5 — 릴리스 v0.4 | task-그룹 경량 컨벤션(GROUP-1) | **게시 완료 (2026-06-20, 태그 `v0.4.0` push)** |
