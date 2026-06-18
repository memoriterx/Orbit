# 팀 프레임워크 배포화 — 단계별 구현 플랜 (writing-plans)

- **날짜:** 2026-06-18
- **설계 근거:** `2026-06-18-team-framework-packaging-design.md`
- **상태:** Plan Approval 대기 (승인 전 구현 금지)
- **승인 기준 (리드):** ① 오르미 제품 코드 무변경 보장 ② 신규 repo 추출(오르미 in-place 미수정) ③ 각 페이즈 success criteria 측정 가능 ④ 과설계 없음(1인 유지 수준)
- **제약:** 커밋 단계가 포함된 경우 커밋 메시지에 **Co-Authored-By 줄 절대 금지**.

## 확정 결정 (2026-06-18, 사용자 승인 — 열린 질문 해소)
- **Q1 명칭:** `orbit` 확정. 플러그인·상태디렉토리 `.orbit/`·마켓플레이스명 전반 사용.
- **Q2/Q3 repo:** 신규 repo `~/Project/orbit`, **1 repo / 2 플러그인(orbit-base + orbit-web-dev) / 1 마켓플레이스**. 오르미 오염 금지.
- **Q4 researcher:** **base 골격에 배치**(architect 초안의 web-dev 배치에서 변경). 네이버·인스타·오르미 결합 전부 제거한 **도메인 무관 범용 리서처**. 조사 대상 소스는 프로젝트마다 주입되는 변수. → base 역할 = leader/architect/builder/reviewer/**researcher** 5역. 네이버 플레이스·블로그 specifics는 web-dev 프리셋이 주입.
- **Q5 dogfooding:** 범위 밖, 보류 확정.

> **실행 제약:** 주간 사용량 한계로 2026-06-22 00:00(Asia/Seoul) 이후에야 서브에이전트(fullstack/qa) 디스패치 가능 → Phase 0 구현 착수는 리셋 후.

> 페이즈는 독립적으로 검증 가능하게 쪼갬. 각 페이즈 끝에 스모크 게이트. 구현 주체는 fullstack(메타 스크립트·파일 작성), 검증은 qa + architect(아키 일관성 렌즈).

---

## Phase 0 — 추출 스캐폴딩 & 명칭 확정
**Goal:** 신규 repo(또는 서브디렉토리)에 마켓플레이스+2플러그인 빈 골격을 만들고, 오르미 자산을 *복사*(이동 아님)로 가져올 준비를 한다. 오르미 repo는 무변경.

**Success Criteria:**
1. 프레임워크 명칭 확정(열린 질문 Q1) 및 repo 위치 확정(Q2/Q3).
2. `<repo>/.claude-plugin/marketplace.json` + `plugins/orbit-base/` + `plugins/orbit-web-dev/` 빈 디렉토리 트리 생성.
3. 두 플러그인의 `.claude-plugin/plugin.json` 매니페스트 작성(name/version/description).
4. 오르미 repo `git status`에 변경 0 (추출은 복사로만).

**Tasks:**
- [ ] T0.1 리드/사용자에 Q1~Q3 확정 요청(명칭·repo 위치·1repo 여부).
- [ ] T0.2 repo 디렉토리 트리 생성(설계 §4 레이아웃).
- [ ] T0.3 `marketplace.json` + 2개 `plugin.json` 작성.
- [ ] T0.4 빈 `README.md`(설치 가이드 자리표시자) 작성.

---

## Phase 1 — base 골격: 에이전트 + AI 중립 prose
**Goal:** 도메인 무관 5역(leader/architect/builder/reviewer/researcher) 에이전트와 AI 중립 방법론 prose(SKILL.md/CLAUDE.md) 1벌을 작성하고, 크로스AI 노출(심링크·@포인터)을 건다.

**Success Criteria:**
1. `plugins/orbit-base/agents/`에 leader.md(그대로 이식, PRODUCT_PATHS 변수화)·architect.md·builder.md·reviewer.md·researcher.md 5종 — 오르미 도메인 문자열 0건(`grep oremi|네이버|Next` = 0). researcher는 조사 대상 소스를 `{{RESEARCH_SOURCES}}` 변수로 받는 범용 리서처.
2. `skills/using-orbit/SKILL.md`에 생명주기·허브앤스포크·3갈래 검증 방법론 prose(orchestration-remap spec에서 추출·일반화).
3. `CLAUDE.md`(=원천 prose) + `AGENTS.md`→CLAUDE.md 심링크 + `GEMINI.md` @포인터 2줄 + `gemini-extension.json`.
4. `references/codex-tools.md`·`gemini-tools.md` 도구 매핑표(설계 §5).

**Tasks:**
- [ ] T1.1 leader.md 골격화(허브앤스포크·위임·Plan Approval·생명주기, 제품경로 `{{PRODUCT_PATHS}}`).
- [ ] T1.2 architect.md 골격(사전 설계+사후 일관성 렌즈, 도메인 슬롯 `{{...}}`).
- [ ] T1.3 builder.md(fullstack 일반화: 구현자 + TDD/디버깅/검증 방법론).
- [ ] T1.4 reviewer.md(qa 3갈래 조율 골격).
- [ ] T1.5 researcher.md(범용 리서처: 외부 소스 조사·읽기전용·리드 보고, 대상 소스 `{{RESEARCH_SOURCES}}` 주입).
- [ ] T1.6 SKILL.md + CLAUDE.md prose 작성, AGENTS.md 심링크, GEMINI.md/gemini-extension.json.
- [ ] T1.7 codex-tools.md/gemini-tools.md 매핑표.

**검증:** architect 아키 일관성 렌즈 — 역할 경계·base 순수성(오르미 잔재 0).

---

## Phase 2 — base 훅 & 스크립트 경로화
**Goal:** 6종 훅 + 팀 스크립트(notify·viewer·usage-resume)를 `${CLAUDE_PLUGIN_ROOT}`/`${CLAUDE_PROJECT_DIR}`로 경로화해 번들에 넣고, 품질 게이트를 프로젝트 위임형으로 만든다.

**Success Criteria:**
1. `hooks/hooks.json`이 6종 훅을 `${CLAUDE_PLUGIN_ROOT}/hooks/<script>`로 호출(superpowers 패턴).
2. usage-detect.py·resume-inject.py가 `${CLAUDE_PROJECT_DIR}/.orbit/`를 상태 경로로 사용(하드코딩 0).
3. quality-gate.sh = `${CLAUDE_PROJECT_DIR}/.orbit/quality-gate.sh` 위임 래퍼(없으면 pass, 있으면 실행→실패 시 block JSON).
4. viewer-attach.sh가 tmux 없을 때 **에러 없이 no-op**(graceful, R2).
5. `grep -rn '/Users/dh' plugins/orbit-base` = 0건.

**Tasks:**
- [ ] T2.1 6종 훅 → hooks.json 경로화 작성.
- [ ] T2.2 usage-detect.py·resume-inject.py 경로 변수화 이식.
- [ ] T2.3 quality-gate.sh 위임 래퍼 + templates/quality-gate.template.sh(기본 no-op pass).
- [ ] T2.4 notify.sh·notify-done.sh·attach-view.sh·agent-view.py 변수화 이식.
- [ ] T2.5 viewer-attach.sh tmux 부재 graceful 분기.
- [ ] T2.6 templates/orbit-config.template(ORBIT_TMUX_SESSION 등).

**검증:** qa — 하드코딩 grep 0건, tmux 부재 no-op 동작.

---

## Phase 3 — base 커맨드 & 초기화
**Goal:** `/orbit-init`(프로젝트에 `.orbit/` 스캐폴딩)·`/orbit-cycle`(생명주기 1건 가이드) 슬래시 커맨드와 roadmap 템플릿을 제공.

**Success Criteria:**
1. `commands/orbit-init.md`: 실행 시 프로젝트 루트에 `.orbit/roadmap.md`(템플릿)·`config`·`quality-gate.sh` 생성, 동반 플러그인(superpowers/gstack/gsd) 설치 감지 + 미설치 시 graceful 안내.
2. `commands/orbit-cycle.md`: roadmap 선택→plan→approval→구현→3갈래 흐름 가이드.
3. `templates/roadmap.template.md`: 빈 얇은 원장(백로그·마일스톤·현재 포인터·완성도 기준 섹션, 오르미 내용 0).

**Tasks:**
- [ ] T3.1 orbit-init.md 작성(스캐폴딩 + 소프트 의존 감지).
- [ ] T3.2 orbit-cycle.md 작성.
- [ ] T3.3 roadmap.template.md 작성.

**검증:** qa — 빈 임시 프로젝트에서 orbit-init 실행 → `.orbit/` 생성 확인.

---

## Phase 4 — web-dev 프리셋
**Goal:** 오르미 웹 도메인 자산(designer·fullstack·architect-web·qa-web + 스킬 4종 + researcher 도메인 주입)을 web-dev 프리셋으로 이식·일반화(오르미 브랜드/네이버를 예시로 격하).

**Success Criteria:**
1. `plugins/orbit-web-dev/agents/` 4종(designer·fullstack·architect-web·qa-web) + `skills/` 4종(nextjs-build·api-build·ui-design·web-qa).
2. base researcher에 주입할 **웹/네이버 소스 프리셋**(`{{RESEARCH_SOURCES}}` 채움값: 네이버 플레이스·블로그·인스타 스크래핑 예시)을 web-dev가 제공.
3. 오르미 고유 문자열(부케·오르미·네이버 URL)은 **예시(example)로 명시**되거나 변수화 — 하드코딩된 비즈니스 상수 0.
4. web-dev 단독 설치 불가 안내(base 선행 필요) README 명시.

**Tasks:**
- [ ] T4.1 designer.md 이식(부케 감성 → 예시).
- [ ] T4.2 fullstack.md·architect-web.md·qa-web.md 이식(Next.js specifics 유지, 오르미 상수 일반화).
- [ ] T4.3 base researcher용 웹/네이버 소스 프리셋(`{{RESEARCH_SOURCES}}` 채움값) 작성 — 네이버 플레이스·블로그·인스타 스크래핑을 예시로.
- [ ] T4.4 스킬 4종 복사 + 오르미 상수 일반화.
- [ ] T4.5 web-dev README(base 선행·override 안내).

**검증:** architect — 프리셋이 base 골격과 모순 없는지(역할 override 명확).

---

## Phase 5 — 스모크 검증 & 문서화
**Goal:** 설계 §8 스모크 A~D를 실행해 빈 프로젝트 설치 동작을 증명하고, 최종 README/설치 가이드를 완성한다.

**Success Criteria:**
1. 스모크 A(CC base 설치) 전 항목 통과 — 에이전트 노출·훅 동작·자동재개·변수 치환·하드코딩 0.
2. 스모크 B(web-dev) 통과.
3. 스모크 D(참조 무결성) 통과 — base 오르미 잔재 0, base 단독 설치 에러 0.
4. 스모크 C(크로스AI) best-effort 기록(환경 없으면 미검증 명시).
5. README: `/plugin marketplace add`→install→`/orbit-init` 3스텝 + 소프트 의존(superpowers/gstack/gsd) 안내 + graceful 매트릭스.

**Tasks:**
- [ ] T5.1 스모크 A 실행·기록(mktemp 빈 프로젝트).
- [ ] T5.2 스모크 B·D 실행·기록.
- [ ] T5.3 스모크 C best-effort 시도·결과 기록.
- [ ] T5.4 README 완성(설치·의존·degradation 매트릭스).
- [ ] T5.5 (선택, 리드 승인 시) 커밋 — **Co-Authored-By 줄 금지**. 브랜치에서 작업.

**검증:** qa 사후 3갈래(완성도 GSD / 동작 = 스모크 / 품질 review) + architect 일관성 렌즈.

---

## 페이즈 의존성

```
P0 → P1 → P2 → P3 → P4 → P5
        ↘ P2/P3 는 P1 prose 확정 후 병렬 가능
```
P4(web-dev)는 P1~P3(base) 완료 후. P5는 전부 후행.

## 범위 밖 (후속)
- 오르미 자체를 플러그인 dogfood로 교체(Q5) — 별도 작업 1건.
- 자동 CI 스모크(GitHub Actions) — 수동 스모크로 충분, 과설계 회피.
- Codex/Gemini 완전 동등성 — graceful degradation으로 한정.
