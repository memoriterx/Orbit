# orbit 개발 로드맵

**업데이트:** 2026-06-18  
**상태 경로:** `.planning/`  
**보고 채널:** `.planning/notifications.log`

---

## 현재 진행 중

(없음 — REQDEPS-1 게시 완료(2026-06-25, 태그 `v2.1.0` push, `origin/main` 동기화). RENAME-1 Post-Build 라이브 `/plugin install orbit` probe만 잔존 = 라이브 세션 필요.)

- [x] **[HOOKGUARD-1] 훅 크로스프로젝트 가드 — user 스코프 전역 설치 시 비-orbit 프로젝트 오염 차단** (2026-06-25)
  포렌식 발굴: orbitt(→orbits) 포크 setup-orbit.sh가 orbit을 user(전역) 스코프로 자동설치(14:21 KST, UTC 착시로 "05:21"처럼 보였던 그 설치) → 훅 8종이 Oremi 등 비-orbit 프로젝트서 발화, `session-log.sh`·`usage-detect.py` 등 무가드로 `.orbit/` 생성·로그 오염, 연쇄로 `resume-inject.py` 프롬프트 주입, `quality-gate.sh` 조건부 차단 위험.
  **해법:** `.orbit/config`(orbit-init만 생성, 어떤 훅도 안 만듦 → 닭-달걀 회피) 마커 기반 컨텍스트 가드. 공유 헬퍼 `scripts/orbit-context.sh`의 `is_orbit_context()`(bash 5훅 source), python 2종 인라인 `_is_orbit_context()`, hooks.json MessageDisplay 인라인 프리픽스. **fail-toward-no-op**(env 부재 시 외부오염 차단 우선·내부 침묵 수용). Task 8b 정적 불변식(T-GUARD 동적순회로 신규 훅 가드 누락 자동FAIL + T-NOWRITE config-write 금지·regex 컨트롤 self-test).
  **critic 게이트 3라운드**(1R: 회귀 스위트 자가무력화 blocker×2 → 2R: 정규식 join-write 누락 blocker#8+하드코딩목록 major#9 → 3R PROCEED). Plan Approval. **Triple Crown ①②③ PASS**(③ 보안 deep-mode: MAJOR 1건[set -u+env미설정 시 silent no-op 위반] → Fix A 적용 후 재검 PASS). 122 테스트 green, 도메인순수성 0. 임시조치: user 스코프 언인스톨 완료(orbits·dev팀은 레포로컬 .claude/ 자립 → 무영향). 플랜: `.planning/plans/2026-06-25-plan-hook-cross-project-guard.md`.

- [x] **[REQDEPS-2] dev reviewer 보안 deep-mode parity drift 해소** (2026-06-25, 커밋 `bdaea35`, dev-meta)
  REQDEPS-1에서 분리한 별도 항목(D3 결정). 배포물 `plugins/orbit/agents/reviewer.md`엔 있던 ③ 보안 deep-mode 절이 dev `.claude/agents/reviewer.md`엔 부재(미import drift 메모만 존재)했던 비대칭 해소. **단순 복붙 아님** — 배포물의 도메인무관 슬롯(auth/PII) 대신 dev가 실제 검토하는 orbit 내부 표면(훅 인젝션·품질게이트 무결성·setup escape hatch)으로 체크리스트 치환. 발동은 reviewer 자기 diff 판단에 구속(리드 힌트 누락이 light로 강등 못 시킴), read-only 경계 유지. **저위험(4트리거 all-no)→critic 생략·버전/릴리스 없음.** drift 메모 삭제(절 추가로 거짓이 되므로). lead-verify(절 삽입·메모제거·배포물 무접촉·critic.md T3 참조 유효).

- [x] **[REQDEPS-1] 동반 플러그인(superpowers·GSD·gstack) 필수 전환 + 7역 스킬 배선 + 3층 모델 (v2.1.0)** (2026-06-25, 브랜치 `feat/required-deps-wiring`, 커밋 `b0969fa`·`81bc42d`·`c1e9b32`·`b778459`·`151974c`)
  v1.0.0 "자기완결성·도메인 무관" 불변식을 의도적으로 뒤집어 세 동반 플러그인을 일급 활용. **"필수"는 `dependencies` 배열 불가(크로스 마켓플레이스 self-disable, ADR-REQDEPS-1) → 런타임 fail-loud만.** **3층 모델:** L1 검토유도(SubagentStart `additionalContext` 주입, 차단불가·skip허용) / L2 산문권고 / **L3 ENFORCED**(reviewer 3프롱만 — companion 부재 시 비PASS+설치안내, 유일한 진짜 강제). 강제는 흔적 남는 reviewer 프롱에만 정직 한정(BLOCKER #2: 프롬프트 산문은 invoke 보장 불가). vendor-lock 매니페스트·README 정직 반영(ADR-REQDEPS-3). 단계 롤아웃 라벨 v2.0.0(TIER-1)/v2.1.0(L1·L2), 매니페스트 4종 현재버전 2.1.0 통일. critic 게이트 **2라운드**(BLOCKER#1 fail-closed 자살게이트→agent_type 스코핑·SubagentStart 차단불가 / BLOCKER#2 강제착각→TIER 분리 / MAJOR 공급망·도메인순수성) + L1통합 후 self-judge PROCEED. Triple Crown 3갈래 PASS(88/88 실행재현·비공허·인젝션안전·진짜 fail-loud, 도메인순수성 0). 빌드 중 잠복버그 발견·수정(all-enabled여도 block하던 false-positive). 플랜: `.planning/plans/2026-06-24-plan-required-deps-wiring.md`.

- [x] **[RENAME-1] 플러그인 설치 식별자 `orbit-base` → `orbit` (v1.0.0)** (2026-06-21, 커밋 `7f9c6fe`~`3c43d5e`, 태그 `v1.0.0`)
  설치 식별자 변경=공개 계약 파기 → MAJOR `1.0.0`(실사용자 사실상 0, 최저비용 시점). `-base`는 부재하는 형제-플러그인 계층 암시, 확장성은 도메인 슬롯으로 달성. `plugins/orbit-base/`→`plugins/orbit/`(순수 git mv), name/source/매니페스트 4종, 전 문서·setup, 활성 dev surface(CLAUDE.md·.claude/·roadmap 활성·verify-harness). **하드브레이크**(공식 alias 없음 — claude-code-guide 확인) + CHANGELOG/README 마이그레이션 안내. critic 게이트 2라운드(BLOCKER 게이트-공허검증 + MAJOR 인벤토리누락→클래스단위 sweep으로 해소) → PROCEED. Triple Crown 3갈래 PASS(게이트 재무장 양성/음성+CONTROL 독립재현). **잔여: Post-Build 라이브 `/plugin install orbit` probe = 라이브 세션 필요(정적 미증명).** 플랜: `.planning/plans/2026-06-21-plan-rename-orbit.md`.

---

## 백로그 — 성능·구조 개선 (2026-06-20 발굴)

researcher 외부 조사로 발굴. orbit thin·허브앤스포크·사람게이트 렌즈로 필터링 후 잔존한 실질 후보만.

- [x] **[PERF-1] 병렬 Fan-out/Fan-in 패턴 정식화** (2026-06-20 완료, 커밋 `b1487d9`)  
  → 아래 완료 섹션 참조. 옵션 1(경량 명문화) 채택.
  > 기각된 후보(재논의 방지): 의미론적 자동 라우팅(허브앤스포크 우회) · 자동 eval 루프(사람게이트 약화+T4) · 벡터DB 장기메모리(T4) · 동적 LLM 라우팅(T4) · 자동 롤백 webhook(T4) · 외부 observability 플랫폼(T4). DAG 의존성 명시·크로스LLM 가이드·자체 체크포인팅은 약함/중복으로 보류.

---

## 백로그 — 실사용 검증 발굴 (2026-06-21 RWV)

격리 temp에 신규 사용자 설치 시뮬레이션(QA-1 넘어 실설치 도그푸딩). README Quickstart를 그대로 따라갈 때의 차단점 발굴.

- [x] **[RWV-1] 신규자 설치 차단점 수정** (2026-06-21, 커밋 `ec723c9`·`aeec965`)  
  Triple Crown 3갈래 PASS(가드 Case A~D 독립 재현, 회귀 무, 거짓주석 정정 claude-code-guide 부합). **RWV-2 NIT 해소 확인(2026-06-25)**: README 트러블슈팅(현 `:359`)이 정직하게 *"커맨드 컨텍스트에서 `CLAUDE_PLUGIN_ROOT` 자동 주입은 보장되지 않음"* 으로 정정됨, `orbit-init.md` 거짓 주석도 제거됨(grep 0건) → 후속 docs 불필요.  
  - **BLOCKER**: `README.md:154`(+ 트러블슈팅 `:290`) 설치 블록이 `/plugin marketplace add <orbit-repo-url>` — 플레이스홀더라 신규자가 그대로 복붙하면 실패. 실값 `memoriterx/Orbit`(setup-orbit.sh 형식)로 교체 필요. 루트 README는 orbit 자신의 readme → 실repo 하드코딩 정상(도메인 누출 아님).  
  - **MAJOR**: `plugins/orbit/commands/orbit-init.md:34` `PLUGIN_ROOT="${CLAUDE_PLUGIN_ROOT}"` + 주석 `:125` "미설정 시 자동 감지된다"가 거짓(감지 로직 없음). claude-code-guide 확인: 커맨드 컨텍스트의 `CLAUDE_PLUGIN_ROOT` 주입은 공식 문서 보장 없음(훅만 명시). 미설정 시 `cp` 무음 실패 → /orbit-init 전체 실패 가능. 안전한 fallback 또는 fail-loud 가드 + 정직한 주석 필요(인라인 커맨드 bash엔 BASH_SOURCE 미적용 — architect 설계 판단).  
  - 기각: plugin.json↔codex 비대칭(MINOR) = 알려진 비이슈([[orbit-plugin-discovery]] — Claude 컨벤션 자동발견). NIT: `docs/smoke-results.md` stale marketplace.json 참조(내부 dev 문서, 후속 정리 옵션).

## 백로그 — 내부 정합성 drift 보수 (2026-06-20 explore 발굴)

병렬 fan-out 조사(researcher 외부 + explore 내부)로 발굴. 외부 후보는 thin 필터 미달/문서화 권고 수준 → 장기 백로그 시드만. 내부에서 실작업 3건 잔존.

- [x] **[DOCS-1] 신규 사용자 온보딩 — README Quickstart 워크스루 + 트러블슈팅** (2026-06-21, 커밋 `a4eef47`)  
  배포물 루트 README.md에 2섹션 추가형(+76/-0): "30분 만에 첫 사이클"(G1 end-to-end 워크스루 + G2 필수/선택 우선순위) + "막혔을 때" 트러블슈팅 표(G3). 신규 .md 0·표면 1파일. discovery: in-plugin 문서는 이미 완결, 갭은 흩어진 참조형 정보. 도메인순수성 0, 소스 대조 모순 0. Triple Crown 3갈래 PASS(②=문서 정확성 대조, ③ light scan=T3 무관). 저위험(추가형=계약 미변경 → T2 미발화) critic 생략. 플랜: `.planning/plans/2026-06-21-plan-docs-onboarding.md`.

- [x] **[DRIFT-1] orbit-cycle.md 생명주기에 critic 고위험 게이트 추가** (2026-06-20, 커밋 `8b63458`)  
  `commands/orbit-cycle.md` 생명주기 다이어그램(line 13-36)과 Step 2 본문에 **고위험 게이트 → critic 분기** 단계 부재. canonical(CLAUDE.md line 19-25 / SKILL.md)에는 있음 → 표면 간 모순. 배포물 → 생명주기 정상 진행 필요(architect 플랜 → Plan Approval → builder).

- [x] **[DRIFT-2] dev팀 에이전트 ↔ 배포물 동기화** (2026-06-20, 커밋 `b243c75`)  
  `.claude/agents/leader.md`에 Discovery-first 단계·Autonomous Loop·skip-and-park·fan-out 섹션 부재(배포물엔 전부 있음). `.claude/agents/architect.md` 작업순서에 Discovery-first 누락. discovery에서 dev팀 parity 적정 수준 판단 필요(전체 미러 vs 핵심만).

- [x] **[DRIFT-3] dev팀 경로 이식성** (2026-06-20, 커밋 `78ba1c1`)  
  `.claude/settings.json` 훅이 `.planning/*.py` 절대경로 하드코딩 + 이 스크립트가 배포판 `plugins/hooks/`와 로직 분기(어느 쪽이 정전인지 불명확). `_team/*.sh` 전부 `/Users/dh/Project/orbit` 절대경로 의존. → `CLAUDE_PROJECT_DIR`/`SCRIPT_DIR` 기반 동적 경로 전환.

- [ ] **[BACKLOG-장기] 외부 조사 시드** (researcher, 미착수·thin 필터 보류)  
  프롬프트 버저닝(git tag 기반)·토큰 비용추적/예산(자율모드 성숙 후)·trajectory 로깅 — 전부 자율모드가 무인 장기실행으로 진화할 때만 의미. 현 시점 thin 미달. 관측성 도구·마켓플레이스 거버넌스·메시지큐·AOrchestra 위임트리는 T4/허브앤스포크 우회/도메인충돌로 **기각**(재논의 방지).

---

## 백로그

### OMC 흡수 — orbit 개선 4건

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

- [x] **[OMC-6] Planner / Architect 책임 분리** — **해소(대안 b → OMC-6b/b2)** (2026-06-18 보류 → 2026-06-20 해소)  
  원안(신규 planner 에이전트, 7→8역)은 critic REVISE로 보류됐었음. 보류 근거: ①전제(architect 과부하) 미실측 ②대안(b) 미검토 ③경량성(7→8역) 트레이드오프.  
  2026-06-20 사용자가 **대안 (b)** 로 재추진 → architect 스파이크가 b1(신규 planner)을 explore/researcher와 ~90% 중복으로 비추천, **b2(신규 에이전트 없이 Discovery-first 단계 명문화)** 채택. **→ [OMC-6b] 참조(완료 섹션). 신규 역할 없이 discovery 우려 충족, 7역 유지.**

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

- [x] **[OMC-6b] Discovery-first 단계 명문화 — OMC-6 해소 (대안 b → b2)** (2026-06-20, 커밋 `1bed418`)  
  보류됐던 OMC-6(planner/architect 분리)을 사용자 지시로 **대안 (b)** 재추진. architect 스파이크: planner-discovery는 explore/researcher/architect와 **~90% 중복** → 신규 planner 에이전트(b1) 비추천, **b2(신규 에이전트 없이 "Discovery first" 단계를 architect 생명주기 계약에 명문화)** 권고. 사용자 b2 채택(대규모 채택 시 행동-시점 강제가 템플릿보다 우월 — 철학 정합).  
  배포물 **Class A 5표면**(architect/CLAUDE/leader/SKILL `1a.`/orbit-cycle) append-only. discovery=문제프레이밍·요구사항·스코프·우선순위, 내부=explore·외부=researcher 위임·architect 종합, "신규 조사역할 안 만듦" 가드. **신규 에이전트·핸드오프 0, 로스터 7역 불변.** Class B(4-phase 요약구) 의도적 미편집 + leak guard.  
  **critic 게이트 2라운드**(MAJOR 3[verify-only 오분류·lifecycle 요약구 누락·동어반복] REVISE → 전부 폐쇄 PROCEED). Triple Crown 3갈래 PASS(leak-exit=1·하네스 C1–C15g exit 0·T3 무관 light scan). 스파이크/플랜: `.planning/plans/2026-06-20-spike-planner-alt-b.md`·`2026-06-20-plan-discovery-first.md`.  
  → **OMC-6 보류 해소**: 신규 역할 추가 없이 discovery 우려를 규율 명문화로 충족. 7역 유지.

- [x] **[QA-1] end-to-end 스모크 테스트** (2026-06-20)  
  격리 temp 환경에서 orbit-base 설치·스캐폴딩 검증. **심각 결함 없음 — 배포 준비 완료.** 스캐폴딩(`.orbit/` roadmap/config/quality-gate)·에이전트 7종(frontmatter)·스킬 2·커맨드 2·훅(hooks.json+참조 6스크립트 실존)·매니페스트 4종 JSON 유효 0.5.0·도메인순수성 0 전부 PASS.  
  builder가 올린 중간 의문(claude plugin.json에 skills/commands/agents/hooks 경로 미선언) → **claude-code-guide 공식문서 확인 결과 비이슈**: Claude Code는 컨벤션 디렉터리(`agents/`·`commands/`·`skills/`·`hooks/hooks.json`) **자동 발견**, 경로 선언은 선택사항. 전역상태(~/.claude·tmux) 비파괴(tmux/CLI 실행 단계는 dry 확인).

- [x] **[PERF-1] 병렬 Fan-out/Fan-in 패턴 명문화 (옵션 1)** (2026-06-20, 커밋 `b1487d9`)  
  researcher 외부조사로 발굴(2026 멀티에이전트 표준). architect 비교 스파이크(4안) → **옵션 1(경량 산문 명문화)** 채택. 배포물 2표면 append-only(SKILL "Independent Fan-out→Fan-in" 섹션 + leader.md fan-out 안내·울타리).  
  ★ 핵심 경계: **읽기전용 조사/검증만 병렬 안전, 빌드/커밋은 항상 직렬**(누적 T2·skip-and-park D4·halt-on-first-failure가 직렬 커밋 전제) — leader Autonomous Loop에 "Builds stay serial" 울타리. 4점 독립성 테스트(불확실⇒직렬), 리드 유일 fan-in점(허브앤스포크 보존). 신규 인프라 0, 가역.  
  저위험 확정(4트리거 all-no) → critic 생략. Triple Crown 3갈래 PASS(하네스 C1–C15g 독립 재실행 exit 0, append-only 0-deletion, T3 무관=light scan). 스파이크/플랜: `.planning/plans/2026-06-20-spike-parallel-fanout.md`·`2026-06-20-plan-parallel-fanout.md`.

- [x] **[AUTO-1] 무인 자동완료 — 자율모드 skip-and-park 프로파일** (2026-06-20, 커밋 `6fa072c`·`bc94a62`)  
  자율모드에 opt-in 프로파일 `skip-and-park` 추가(기본 `halt-on-trigger` 불변). 무인 루프 중 고위험/모호 task를 **격리(park)하고 저위험은 끝까지 자동 완료**, parked 목록 보고. 사용자 B안(2026-06-20 직접 요청).  
  안전 계약(critic 검증): parked 고위험은 절대 자동 결정·구현 안 됨 / 검증(②③) 실패는 두 프로파일 halt 유지(BLOCKER-1) / D4 **fail-closed**(독립 입증 시에만 자율빌드, 불확실⇒park) / amortization 차단(parked 연속배치 제외 + ≥3 거부) / park는 halt 동치 아닌 **조건부 안전**으로 정직 재서술. 신규 인프라 0.  
  닿는 표면 6배포물 + 하네스 C15a–g. **critic 게이트 2라운드**(BLOCKER 2+MAJOR 4 REVISE → 전부 폐쇄 PROCEED). Triple Crown 3갈래 PASS(하네스 C1–C15g 독립 재현, 안전 불변식 역검증, ③ light scan=T3 무관). 플랜: `.planning/plans/2026-06-20-plan-unattended-skip-and-park.md`.

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
| M6 — 릴리스 v0.5 | skip-and-park 무인 자동완료(AUTO-1) + 병렬 fan-out(PERF-1) + 뷰어 픽스 | **게시 완료 (2026-06-20, 태그 `v0.5.0` push)** |
| M7 — 릴리스 v0.6 | Discovery-first 단계 명문화(OMC-6b, OMC-6 해소) + codex 역할수 정정 | **게시 완료 (2026-06-20, 태그 `v0.6.0` push)** |
| M8 — 릴리스 v1.0 | 플러그인 리네임 `orbit-base`→`orbit`(RENAME-1) | **게시 완료 (2026-06-21, 태그 `v1.0.0` push)** |
| M9 — 릴리스 v2.1 | 동반 플러그인 필수 전환 + 7역 스킬 배선 + 3층 모델(REQDEPS-1) | **게시 완료 (2026-06-25, 태그 `v2.1.0` push)** |
