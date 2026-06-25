# 신규 사용자 온보딩·문서 개선 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 외부 신규 사용자가 orbit-base를 발견·설치하고 첫 작업 1건 생명주기(plan→approval→build→verify)를 문서만으로 완주할 수 있도록, **단일 end-to-end Quickstart 워크스루 1개**와 **압축 트러블슈팅 1개**를 README에 추가한다(thin 원칙 — 신규 파일·매뉴얼 비대화 없이 README 내 섹션 증분).

**Architecture:** 기존 README.md의 검증된 구조·톤(v0.6.x 다회 일관성 검토 완료)을 보존하면서, 현재 "흩어진 정보"(설치 3단계·생명주기·역할표·동반 플러그인·고급 설정)를 **신규자가 한 번에 따라가는 선형 시나리오 1개**로 묶는 얇은 추가만 한다. orbit-base 배포물 문서는 손대지 않는다(SKILL.md·CLAUDE.md·commands는 이미 일관·완결). 변경 표면은 **루트 README.md 단 1파일**로 한정해 도메인 순수성·배포물 경계 위험을 최소화한다.

**Tech Stack:** Markdown only. 코드/스크립트 변경 없음. 검증은 사람-읽기 워크스루(문서만으로 N단계 완주) + 자동 grep(도메인 순수성·링크 정합성).

## Global Constraints

- **변경 표면 = 루트 `README.md` 단 1파일.** `plugins/orbit-base/` 하위 문서(README/CLAUDE.md/SKILL.md/commands)·`setup-orbit.sh`·`.claude-plugin/marketplace.json`·`plugin.json`은 **이 플랜에서 수정하지 않는다.** (discovery 결과 이들은 이미 완결·일관)
- **배포물 vs dev 경계:** 루트 `README.md`는 배포물(end-user 대면) — 도메인 순수성 적용 대상. 도메인 무관(oremi/orbit-dev/실프로젝트명 하드코딩 0). 예제는 일반적 가상 프로젝트(`my-app` 같은 placeholder)로만 표기.
- **도메인 순수성:** 워크스루 예제는 특정 스택·프로젝트명을 박지 않는다. roadmap 작업 예시는 도메인 무관 일반 문구(예: "할 일 1건 추가")로.
- **기존 구조·톤 보존:** README는 이미 `## 이게 뭐예요? / 왜 팀으로 / 팀 구성 / 일하는 순서 / 빠른 시작 / 그 다음 — 선택 플러그인 / 고급 설정 / 라이선스` 구조. 신규 섹션은 이 흐름을 **깨지 않는 위치**에 삽입하고, 기존 내용을 중복 재서술하지 않는다(링크·앵커로 참조).
- **thin 원칙:** 방대한 매뉴얼은 반패턴. 추가는 Quickstart 워크스루 1개 + 트러블슈팅 표 1개로 제한. 새 `.md` 파일 생성 금지.
- **언어·톤:** 기존 README와 동일한 한국어 평어체·친절한 설명 톤 유지.

---

## Discovery 요약 (이 플랜의 근거)

architect가 discovery로 직접 읽은 신규자 대면 문서 자산:

| 표면 | 현재 커버리지 | 신규자 관점 갭 |
|------|--------------|----------------|
| 루트 `README.md` (327줄) | 개념·역할 7표·생명주기·자율모드·fan-out·그룹·설치 3단계·동반 플러그인·graceful degradation·크로스AI·슬롯·구성 | **풍부하나 "참조형"** — 개념을 주제별로 나열. 신규자가 "처음부터 끝까지 한 번 따라가는" 선형 시나리오 부재. 설치(150줄)·tmux 셋업(222줄)·생명주기(57줄)가 멀리 떨어져 있어 zero→first-cycle 경로가 머릿속에서 재조립돼야 함 |
| `setup-orbit.sh` (루트, thin wrapper) | 번들 스크립트로 exec | 정상 |
| `plugins/orbit-base/scripts/setup-orbit.sh` | tmux 2팬+플러그인 자동설치 | README 고급 섹션이 커버 |
| `.claude-plugin/marketplace.json` / `plugin.json` | v0.6.1, 유효 | 정상 |
| `commands/orbit-init.md` | `/orbit-init` 절차 + 완료 후 "다음 단계" 5개 안내 | 완결. README Quickstart에서 이 명령으로 연결됨 |
| `commands/orbit-cycle.md` | 생명주기 전체(critic 게이트·자율모드 포함) 상세 | 완결·일관(DRIFT-1로 최근 정합) |
| `skills/using-orbit/SKILL.md` | 프레임워크 오리엔테이션 전문 | 완결 |
| `CHANGELOG.md` | Keep-a-Changelog 0.6.1 | 정상 |

**zero→first-cycle 경로 추적 (현재 문서만으로):**

1. (a) 발견·설치 — README "빠른 시작 3단계"(150–161줄)가 커버. ✅
2. (b) 팀 환경 셋업(tmux·뷰어) — README "고급 설정 참조 → tmux 팀 환경 셋업"(222–260줄). **그러나 "고급, 처음엔 몰라도 됨"으로 표시돼 신규자가 첫 사이클에 tmux를 써야 하는지/안 써도 되는지 판단 어려움.** (실제로는 선택사항이나 명시적 "맨 처음엔 이거 1개만 하면 된다" 경로 부재)
3. (c) roadmap 첫 작업 등록 — `/orbit-init` 후 `.orbit/roadmap.md`를 열어 작업 추가. orbit-init.md "다음 단계"에는 있으나 **README 본문 zero→first 흐름엔 "roadmap에 어떻게 첫 줄을 쓰는가" 구체 예시 없음.** roadmap.template.md 형식을 신규자가 추측해야 함.
4. (d) 첫 생명주기 완주 — `/orbit-cycle` 실행. README 생명주기 다이어그램은 개념 설명이고, **"실제로 무엇을 입력하고 무엇을 기대하는가"의 1회 실연 부재.**

**식별된 갭(차단도 순):**
- **G1 (높음):** end-to-end Quickstart 워크스루 부재 — 설치→init→roadmap 1줄→`/orbit-cycle`→승인→완료까지 "복붙 가능한 1회 시나리오"가 없다. 정보는 다 있으나 신규자가 5곳에서 조립해야 함.
- **G2 (중):** 동반 플러그인 설치 전제(superpowers/gstack/gsd)가 "그 다음 — 선택 플러그인"에 있으나, **첫 사이클을 돌리는 데 무엇이 최소 필수이고 무엇이 나중인지의 우선순위가 신규자 시점에서 불명확.** (실제: 전부 선택, 핵심 방법론은 무플러그인 동작 — 이 사실이 Quickstart에 압축돼야 함)
- **G3 (중):** 트러블슈팅 부재 — `/orbit-init`이 `CLAUDE_PLUGIN_ROOT` 미설정으로 실패하거나, `/plugin install`이 안 보이거나, tmux 미설치 시 무엇을 보는지의 빠른 대응표 없음.
- **G4 (낮음, 선택):** "처음 한 번"과 "고급"의 시각적 구분 — 신규자가 고급 섹션을 첫날 읽어야 한다고 오해할 여지. (G1 워크스루가 해결하면 부수 해소)

**우선순위 결정:** G1 = 단일 최고가치 추가(신규자 차단 1순위). G2는 G1 워크스루 안에 1개 박스로 흡수. G3는 작은 표 1개. G4는 별도 작업 불필요(G1이 흡수). → **thin: README에 Quickstart 워크스루 1개 + 트러블슈팅 표 1개. 그 이상 없음.**

---

## 4트리거 고위험 Self-Assessment (architect → 리드 게이트 입력)

| 트리거 | 판정 | 근거 |
|--------|------|------|
| **T1 비가역성** | **no** | Markdown 추가. git revert 1회로 완전 원복. 데이터 마이그레이션·하위호환 파괴 없음. |
| **T2 광범위 영향 / 공개 계약** | **경계 — 리드 판단 요청** | 변경 파일은 README.md 단 1개(<3 컴포넌트). 그러나 **README는 공개 end-user 대면 문서**이며 "빠른 시작 3단계"·설치 절차는 사실상 공개 계약. 이 플랜은 **기존 설치 명령·절차를 변경하지 않고 워크스루로 재서술·보강만** 하므로 계약 변경 아님(추가형, 비파괴). 리드가 "공개 README 보강 = T2 발화 여부"를 최종 판정. architect 견해: **저위험**(기존 명령 불변, 순수 추가). |
| **T3 보안·무결성** | **no** | 인증·권한·시크릿·삭제·금전·PII 경로 무관. |
| **T4 신규 외부 의존성** | **no** | 신규 런타임·서비스·벤더 0. 문서가 언급하는 superpowers/gstack/gsd는 **기존 선택 동반 플러그인**으로 이미 README에 존재 — 신규 도입 아님. |

**architect 권고:** 전부 명백히 no 또는 비파괴-추가형 경계 1건 → **저위험**. 리드가 T2 경계를 "추가형이라 계약 미변경"으로 동의하면 critic 생략 가능. 동의가 불확실하면 critic 1회 파견 권장(모호 ⇒ 정지 정신).

---

## File Structure

이 플랜이 만지는 파일과 책임:

- **Modify: `/Users/dh/Project/orbit/README.md`** — 유일한 변경 파일.
  - 신규 섹션 A: `## 30분 만에 첫 사이클 (Quickstart 워크스루)` — "빠른 시작 3단계"(150–161줄) **직후**, "그 다음 — 선택 플러그인"(174줄) **앞**에 삽입. zero→first-cycle 선형 시나리오.
  - 신규 하위 섹션 B: 워크스루 내 `### 최소 준비물 vs 나중에` 박스 — G2(플러그인 우선순위) 흡수.
  - 신규 섹션 C: `### 막혔을 때 (트러블슈팅)` — 워크스루 말미 또는 고급 설정 직전. G3 흡수.

**왜 README 1파일인가:** discovery 결과 배포물 in-plugin 문서(SKILL/CLAUDE.md/commands)는 이미 완결·일관(DRIFT-1 정합 완료). 신규자 차단의 본질은 "정보 부재"가 아니라 "선형 진입 경로 부재"이므로, 진입점인 루트 README에 워크스루 1개를 더하는 것이 최소·최대가치 개입. in-plugin 문서 수정은 도메인 순수성·배포물 경계 위험만 늘리고 가치는 중복.

---

## Task 1: Quickstart 워크스루 섹션 삽입 (G1·G2 해소)

**Files:**
- Modify: `/Users/dh/Project/orbit/README.md` — "## 빠른 시작 — 3단계 설치" 블록(현재 150–170줄, `/orbit-init`로 끝나고 `.orbit/` 트리 설명까지) 직후, "## 그 다음 — 선택 플러그인"(현재 174줄) 직전에 신규 섹션 삽입.

**Interfaces:**
- Consumes: 기존 README의 설치 3단계 명령(`/plugin marketplace add`, `/plugin install orbit-base`, `/orbit-init`)과 `/orbit-cycle` 명령명. 이 워크스루는 그 명령들을 **재정의하지 않고 순서대로 엮기만** 한다.
- Produces: 신규자가 따라가는 선형 경로. 이후 Task 2(트러블슈팅)가 이 워크스루의 "막혔을 때" 참조 앵커를 가리킨다.

- [ ] **Step 1: 삽입 지점 확인**

Read `/Users/dh/Project/orbit/README.md` 의 현재 150–174줄 범위를 읽어, "## 빠른 시작 — 3단계 설치" 섹션이 `.orbit/` 트리 코드블록(169–170줄 `└── quality-gate.sh ...` + 닫는 ```)으로 끝나고 그 다음 `---` 구분선, 이어서 "## 그 다음 — 선택 플러그인"이 오는 구조를 확인한다. 삽입은 `.orbit/` 트리 코드블록과 그 뒤 `---` 사이, 또는 `---` 직후 새 섹션으로 한다(기존 `---` 구분선 흐름 보존).

- [ ] **Step 2: Quickstart 워크스루 섹션 작성·삽입**

기존 "## 빠른 시작 — 3단계 설치" 섹션 끝(`.orbit/` 트리 설명)과 다음 `---` 사이에, 아래 마크다운을 **그대로** 삽입한다(도메인 무관 placeholder `my-app` 사용, 실프로젝트명 0):

```markdown
---

## 30분 만에 첫 사이클 (처음 한 번 따라하기)

설치를 마쳤다면, 아래를 순서대로 따라 하면 **첫 작업 1건이 계획→승인→구현→검증을 거쳐 완료**됩니다.
처음 한 번만 보면 됩니다. 그 아래 "고급 설정"은 지금 몰라도 됩니다.

### 0. 최소 준비물 vs 나중에

| 지금 꼭 필요 | 나중에(선택) |
|--------------|--------------|
| Claude Code (orbit은 그 위에서 동작) | `superpowers` — 계획·TDD·리뷰 스킬 자동화 |
| `orbit-base` 플러그인 설치 (위 3단계) | `gstack` — 브라우저/앱 동작 검증 자동화 |
| 프로젝트 폴더 1개 | `gsd` — 완성도 검증 자동화 |

**핵심:** orbit의 방법론(계획→승인→구현→검증)은 **동반 플러그인 없이도 그대로 동작**합니다.
플러그인은 각 검증 단계를 자동화해 줄 뿐입니다. 처음엔 `orbit-base`만으로 충분합니다.

### 1. 프로젝트 초기화

프로젝트 폴더에서 Claude Code를 열고:

```
/orbit-init
```

`.orbit/` 폴더(roadmap·config·quality-gate.sh)가 생깁니다.

### 2. 할 일 한 줄 등록

`.orbit/roadmap.md`를 열어 백로그에 첫 작업을 한 줄 적습니다. 예:

```markdown
## 백로그

- [ ] **README에 프로젝트 소개 문단 추가** — 한 문단짜리 설명
```

작업은 무엇이든 좋습니다(도메인 무관). 한 줄이면 시작할 수 있습니다.

### 3. 사이클 시작

```
/orbit-cycle
```

그러면 리드(팀장)가 다음을 차례로 진행합니다 — **당신이 할 일은 한 곳, "승인"뿐입니다.**

1. **설계자가 계획을 짭니다** (먼저 Discovery로 무엇을·어디까지인지 정리한 뒤 플랜 작성).
2. (위험한 작업이면) **비판자가 계획을 먼저 검토**합니다.
3. **리드가 계획을 보여주고 당신의 승인을 기다립니다.** ← 여기서 "진행해 주세요" 또는 수정 요청.
4. 승인하면 **구현자가 테스트부터 쓰고(TDD) 코드를 만듭니다.**
5. **검토자가 3갈래(완성도·동작·품질)로 확인**합니다.
6. 통과하면 `.orbit/roadmap.md`의 체크박스가 `- [x]`로 바뀌고 완료 보고를 받습니다.

### 4. 다음 작업

roadmap 백로그에 다음 줄을 추가하고 `/orbit-cycle`을 다시 실행하면 됩니다.
여러 작업을 한꺼번에 자동으로 돌리고 싶다면, 위 "일하는 순서"의 **opt-in 자율 실행 모드**를 참고하세요(기본은 꺼져 있어, 매 작업마다 당신이 승인합니다).

### 막혔을 때

`/orbit-init`이나 `/plugin` 명령이 안 보이거나 오류가 나면, 아래 "고급 설정 참조 → 막혔을 때(트러블슈팅)"를 확인하세요.
```

- [ ] **Step 3: 삽입 후 구조·중복 검증**

Read 한 README.md에서 다음을 확인한다:
- 신규 섹션이 "빠른 시작 3단계" 다음, "그 다음 — 선택 플러그인" 앞에 위치하는가.
- `## ` (h2) 헤더 레벨이 주변 섹션과 일관되는가.
- 기존 "일하는 순서" 생명주기 다이어그램(57줄~)을 **중복 재서술하지 않고** 참조만 하는가(Step 2 본문은 6단계 요약만 — 다이어그램 복제 아님).
- 동반 플러그인 설치 명령(`/plugin install superpowers@...` 등)을 **중복하지 않고** "그 다음 — 선택 플러그인" 섹션을 가리키는가.

- [ ] **Step 4: 도메인 순수성 grep 검증**

Run:
```bash
grep -nE 'oremi|Oremi|orbit-dev|/Users/dh|memoriterx' /Users/dh/Project/orbit/README.md
```
Expected: Task 2 작성분 포함 신규 추가 라인에서 **0건**(기존 라인의 `memoriterx` 같은 정당한 출처 URL은 무관 — 신규 워크스루 본문에 실프로젝트명·개인경로·dev팀명이 없는지 확인). placeholder는 `my-app` 등 일반 명사만.

- [ ] **Step 5: 커밋**

```bash
cd /Users/dh/Project/orbit
git add README.md
git commit -m "docs: add zero-to-first-cycle quickstart walkthrough to README"
```

---

## Task 2: 트러블슈팅 표 삽입 (G3 해소)

**Files:**
- Modify: `/Users/dh/Project/orbit/README.md` — "## 고급 설정 참조"(현재 218줄) 섹션 **내부**, "### tmux 팀 환경 셋업"(222줄) **직전**에 `### 막혔을 때 (트러블슈팅)` 하위 섹션 삽입. (Task 1의 "막혔을 때" 링크가 이 앵커를 가리킴)

**Interfaces:**
- Consumes: Task 1 워크스루의 "막혔을 때" 참조. orbit-init.md의 알려진 실패 모드(`CLAUDE_PLUGIN_ROOT` 미설정)와 setup-orbit.sh의 tmux-graceful 동작(discovery에서 확인).
- Produces: 신규자가 첫 사이클 중 가장 흔한 3~4개 막힘에 대한 즉답표. 이후 작업 없음(thin 종결).

- [ ] **Step 1: 삽입 지점 확인**

Read `/Users/dh/Project/orbit/README.md` 의 "## 고급 설정 참조" 헤더(218줄 부근)와 바로 다음 "### tmux 팀 환경 셋업"(222줄) 사이를 확인한다. 트러블슈팅은 고급 섹션의 첫 하위 항목으로 삽입한다(신규자가 막혔을 때 가장 먼저 닿도록).

- [ ] **Step 2: 트러블슈팅 하위 섹션 작성·삽입**

"## 고급 설정 참조" 헤더와 그 도입 문장("이 아래 내용은 처음 시작할 때 몰라도 됩니다...") 직후, "### tmux 팀 환경 셋업" 직전에 아래를 삽입한다:

```markdown
### 막혔을 때 (트러블슈팅)

첫 사이클에서 가장 흔한 막힘과 대응입니다.

| 증상 | 원인 | 대응 |
|------|------|------|
| `/orbit-init`·`/orbit-cycle`이 명령 목록에 안 보임 | `orbit-base` 플러그인 미설치 또는 미인식 | `/plugin install orbit-base` 재실행 후 Claude Code를 재시작. 마켓플레이스 미등록이면 `/plugin marketplace add <orbit-repo-url>` 먼저 |
| `/orbit-init` 실행 시 `CLAUDE_PLUGIN_ROOT` 관련 오류 | 플러그인 루트 경로 미감지 | 보통 자동 감지됩니다. 안 되면 Claude Code 재시작; 그래도 안 되면 플러그인 재설치 |
| `.orbit/` 가 안 생기거나 비어 있음 | 프로젝트 루트가 아닌 곳에서 실행 | 프로젝트 폴더 루트에서 `/orbit-init`을 다시 실행. 기존 파일은 덮어쓰지 않습니다(`cp -n`) |
| 동반 플러그인(superpowers 등)이 없다고 표시됨 | 선택 플러그인 미설치 | **무시해도 됩니다.** orbit 핵심 방법론은 플러그인 없이 동작합니다. 자동화가 필요하면 "그 다음 — 선택 플러그인" 참고 |
| tmux 2분할(리드+뷰어) 화면이 안 뜸 | tmux 미설치 또는 미사용 | tmux는 **선택사항**입니다. 없으면 단일 화면에서 그대로 동작합니다(훅이 조용히 종료). 쓰려면 아래 "tmux 팀 환경 셋업" 참고 |

그 외 문제는 [GitHub 이슈](https://github.com/memoriterx/Orbit/issues)에 남겨 주세요.
```

- [ ] **Step 3: 링크 정합성 검증**

Read README.md에서:
- Task 1의 "고급 설정 참조 → 막혔을 때(트러블슈팅)" 텍스트가 이 섹션 제목(`### 막혔을 때 (트러블슈팅)`)과 일치하는가(앵커 텍스트 정합).
- GitHub 이슈 URL이 plugin.json의 `repository`(`https://github.com/memoriterx/Orbit`)와 일관되는가.
- 표의 대응이 기존 README 사실과 모순되지 않는가(특히 "tmux 선택사항·훅 조용히 종료"는 260줄과 일치, "cp -n 덮어쓰기 안 함"은 orbit-init.md와 일치).

- [ ] **Step 4: 도메인 순수성 재확인**

Run:
```bash
grep -nE 'oremi|Oremi|orbit-dev' /Users/dh/Project/orbit/README.md
```
Expected: **0건**. (트러블슈팅 표에 dev팀 고유 명칭 유입 없음 확인)

- [ ] **Step 5: 커밋**

```bash
cd /Users/dh/Project/orbit
git add README.md
git commit -m "docs: add new-user troubleshooting table to README advanced section"
```

---

## Success Criteria (측정 가능)

1. **zero→first-cycle 선형 완주 가능:** 신규자가 README "30분 만에 첫 사이클" 섹션만 위에서 아래로 읽고, 다른 섹션을 재조립하지 않고도 (a)설치 확인 → (b)`/orbit-init` → (c)roadmap 1줄 등록 → (d)`/orbit-cycle`로 승인까지 4단계를 빠짐없이 따라갈 수 있다. (검증: 워크스루에 4단계 각각의 입력 명령과 기대 결과가 명시돼 있는가 — 사람-읽기 체크)
2. **최소 준비물 명확:** "0. 최소 준비물 vs 나중에" 표로 첫 사이클 최소 요건(orbit-base만)과 선택 플러그인이 분리돼, 신규자가 무엇을 지금 설치해야 하는지 1초에 판단 가능.
3. **트러블슈팅 즉답:** discovery가 식별한 4개 흔한 막힘(명령 미표시·CLAUDE_PLUGIN_ROOT·.orbit 미생성·플러그인 부재·tmux)에 각각 1행 대응이 있다.
4. **도메인 순수성 0 위반:** `grep -nE 'oremi|Oremi|orbit-dev' README.md` 신규 추가분 0건.
5. **비중복·비파괴:** 기존 설치 3단계 명령·생명주기 다이어그램·동반 플러그인 설치 명령이 **재정의되지 않고** 참조/요약만 된다(중복 추가 금지 제약 충족). git diff가 기존 라인 삭제 없이 추가 위주(섹션 삽입)임을 확인.
6. **thin 유지:** 신규 `.md` 파일 0개. 변경 파일 1개(README.md). 추가 섹션 정확히 2개(Quickstart 워크스루 + 트러블슈팅).

---

## 검증 방법 (Triple Crown 3갈래)

**① 완성도 (GSD / 체크리스트):**
- 위 Success Criteria 6항목 전부 충족 확인.
- Task 1·2의 모든 스텝 체크박스 완료.
- `gsd` 플러그인 있으면 해당 완성도 워크플로, 없으면 위 체크리스트 수동 확인.

**② 동작 (문서는 "읽어서 따라갈 수 있는가"가 동작):**
- README "30분 만에 첫 사이클" 섹션을 **신규자 시선으로 1회 통독**하며, 각 단계의 명령이 실제 실행 가능하고 기대 결과 서술이 정확한지 대조. (gstack 브라우저 QA 대상 아님 — 정적 문서. quality-gate.sh no-op 통과 확인으로 대체)
- 실제 임시 프로젝트에서 워크스루대로 `/orbit-init`까지 dry 실행해 `.orbit/` 생성·"다음 단계" 안내가 워크스루 서술과 일치하는지 1회 확인(선택, 환경 가능 시).

**③ 품질 (code review):**
- `superpowers:requesting-code-review` 또는 diff 직접 검토: (a)톤·언어 기존 README와 일관, (b)헤더 레벨·`---` 구분선 흐름 보존, (c)링크/앵커 정합, (d)기존 내용 비파괴, (e)도메인 순수성.
- **③ deep-mode 비대상:** 보안 표면(T3) 무관 → light scan.
- **아키텍처 일관성 렌즈(architect 재호출 조건):** 변경이 배포물 경계·도메인 순수성에 닿으므로, 리드가 ③ 후 architect에 "배포물 README가 도메인 무관 유지 + in-plugin 문서와 모순 없음" 일관성 리뷰를 요청할 수 있다(선택).

---

## 영향 범위

- **변경 파일:** `/Users/dh/Project/orbit/README.md` 1개 (추가 2섹션).
- **건드리지 않는 표면:** `plugins/orbit-base/**`(전부), `setup-orbit.sh`, `.claude-plugin/marketplace.json`, `plugin.json`, `CHANGELOG.md`, `.claude/**`, `.planning/**`(이 플랜 파일 제외).
- **배포물 vs dev:** README.md는 배포물 → 별도 커밋 2개(Task별), 도메인 순수성 적용. dev 환경(`.claude/`) 무변경.
- **하위 호환:** 추가형·비파괴 → 기존 사용자 영향 0. 신규 사용자 진입 마찰만 감소.
- **CHANGELOG:** 이 플랜은 CHANGELOG 갱신을 포함하지 않음(배포물 문서 보강은 다음 릴리스 노트에서 일괄 기록 권장 — 리드 판단). 필요 시 별도 메타 작업으로 분리.

---

## Self-Review (architect 자체 점검)

**1. 스펙 커버리지:** discovery 4문항 전부 플랜에 반영 — (1)문서 인벤토리=Discovery 표, (2)zero→first 경로 추적=Discovery 본문, (3)갭 식별=G1–G4, (4)우선순위=차단도순+thin. 제약(도메인 순수성·배포물 경계·기존 일관성·4트리거·Goal/Success/Tasks/검증/영향범위) 전부 포함. ✅

**2. 플레이스홀더 스캔:** 모든 스텝에 실제 삽입 마크다운 전문 포함(TBD·"적절히"·"등등" 없음). 트러블슈팅 표·워크스루 본문 모두 완전 텍스트. ✅

**3. 일관성:** 앵커 텍스트("막혔을 때(트러블슈팅)")가 Task 1 참조와 Task 2 제목에서 일치. 삽입 위치(3단계 직후 / 고급 섹션 내 tmux 직전)가 두 Task 간 모순 없음. placeholder `my-app`만 사용(실명 0). ✅

**잠재 리스크:** README 줄번호는 discovery 시점 기준 — builder는 줄번호가 아닌 **섹션 헤더 텍스트로 삽입 지점을 앵커링**할 것(Step 1이 매번 Read로 재확인). T2 경계 1건은 리드 게이트에 위임.
