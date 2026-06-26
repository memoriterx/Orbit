# README 재구성 (이용자 가독성) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 배포물 `/Users/dh/Project/orbit/README.md`를 신규 이용자 우선 흐름으로 재배치·그룹화하고 목차(TOC)를 추가해, 검증된 사실을 한 글자도 잃지 않으면서 가독성을 높인다.

**Architecture:** 콘텐츠 삭제가 아니라 **재배치·그룹화·목차·시각 정리** 위주. 신규자 진입 경로(소개 → 요구사항 → 설치 → 첫 사이클)를 상위에 모으고, 고급·내부·참조 정보(tmux 환경변수표, 훅 내부, 크로스AI, 도메인 슬롯)는 `<details>` 접기 또는 하단 참조 섹션으로 분리한다. 모든 변경은 단일 파일(`README.md`) 안에서 일어나며, 사실 보존은 grep 체크리스트로 검증한다.

**Tech Stack:** Markdown (GitHub Flavored), `<details>`/`<summary>` 접기, 인라인 앵커 링크.

## Global Constraints

- **정확성 불변:** 다음 사실을 글자 그대로 보존하거나 의미 동일하게 이동만 한다(삭제·변경 금지):
  - 설치 명령 `/plugin marketplace add memoriterx/Orbit`, `/plugin install orbit`, `/orbit-init`, `/orbit-cycle`
  - 동반 플러그인 3종 설치 명령: superpowers(`/plugin install superpowers@claude-plugins-official`), gstack(`git clone --single-branch --depth 1 https://github.com/garrytan/gstack.git ~/.claude/skills/gstack && cd ~/.claude/skills/gstack && ./setup`), gsd(`/gsd-help`)
  - 훅 6 이벤트 요약(README 488줄): `SubagentStop(품질 게이트) · SubagentStart(뷰어 · L1 스킬 주입) · UserPromptSubmit(세션 재개) · Stop(세션 로그) · Notification·MessageDisplay(사용량 자동감지)`
  - setup-orbit.sh 번들 vs 루트 래퍼 구분(번들=단독 가능 자체완결, 루트=단독 불가 `Error: bundled script not found` exit 1)
  - curl 부트스트랩 안내(`raw.githubusercontent.com/memoriterx/Orbit/main/plugins/orbit/scripts/setup-orbit.sh`)
  - 환경변수표 8행(ORBIT_TMUX_SESSION · CLAUDE_PROJECT_DIR · ORBIT_SKIP_PERMISSIONS · ORBIT_SKIP_PLUGIN_CHECK · ORBIT_INSTALL_DEPS · ORBIT_INSTALL_SCOPE · ORBIT_SKIP_UPDATE 및 기본값)
  - `ORBIT_SKIP_COMPANION_CHECK=1` CI/헤드리스 안내
  - 버전 표기 `v1.0.0`/`v2.0.0`/`v2.1.0`, orbit-base→orbit 마이그레이션 안내
  - 7역 역할표(이름·한마디·설명·모델), 3층 모델표, Triple Crown↔reviewer 강제 배선표, 역할별 스킬 배선표, 크로스AI표, Graceful Degradation표, 도메인 슬롯표, 스킬 카탈로그표
  - GitHub 링크(`github.com/memoriterx/Orbit/issues`, superpowers/gstack repo URL)
  - 출처 인용문(104줄 "클로드 코드... 완성 가이드")
  - MIT 라이선스
- **도메인 무관 유지:** 프로젝트명(oremi 등) 하드코딩 금지. `memoriterx/Orbit`은 orbit 자신을 가리키므로 정상.
- **내용 삭제 금지(예외 1건만):** 명백한 중복만 통합 가능. 본 플랜에서 식별한 중복은 Task 4에 명시. 그 외 삭제 0건.
- **마크다운 무결성:** 코드펜스 짝수 유지(현재 12쌍 24줄), `<details>` 태그 짝 유지, 앵커 링크 깨짐 없음.
- **단일 파일:** 변경은 `README.md`에만. 다른 파일 수정 금지.

---

## 현황 진단 (Discovery 결과)

**현재 구조 (실측):**
- 총 496줄, H2 17개(단 2개는 가짜 — 아래 참조), H3 다수, H4 1개, 표 ~12개, 코드펜스 12쌍.
- **가짜 헤더 함정:** 140줄 `## Backlog`(펜스 139–146 내부), 274줄 `## 백로그`(펜스 273–277 내부)는 **렌더링되지 않는 코드블록 내부 텍스트**다. TOC 생성·헤더 카운트 시 반드시 제외할 것.
- 기존 앵커 링크 1개(53줄 → `#역할별-동반-스킬-배선-v210`). 재배치 시 이 앵커 보존 필수.
- 목차(TOC) **없음**.

**현재 섹션 순서(렌더되는 진짜 H2):**
1. 이게 뭐예요?(3) → 2. 왜 팀으로 나누나요?(28) → 3. 팀 구성 7역(41) → 4. 일하는 순서(59) → 5. 역할별 스킬 배선(152) → 6. 요구사항(196) → 7. 빠른 시작 설치(214) → 8. 30분 첫 사이클(242) → 9. 동반 플러그인 설치(305) → 10. 고급 설정 참조(348) → 11. 라이선스(494)

**진단된 가독성 문제(근거 기반):**

| # | 문제 | 근거(줄) |
|---|------|----------|
| P1 | **설치가 너무 아래** — 신규 이용자의 "어떻게 시작?"인 빠른 시작이 214줄(전체 43% 지점). 그 위로 개념 설명 4개 H2(소개·왜·7역·일하는순서 = 153줄)가 진입을 가로막음 | 214 / 전체 496 |
| P2 | **개념 심화가 설치 앞에 과다** — "일하는 순서"(59–149) 안에 자율모드·병렬실행·task그룹 등 고급 개념이 첫 설치 전에 등장 | 106–148 |
| P3 | **스킬 배선 3절(152–193)이 설치 앞** — L1/L2/L3 3층 모델, 강제 배선표는 내부 메커니즘. 신규자에겐 설치 후 참조 정보인데 설치보다 위 | 152–193 |
| P4 | **설치·요구사항 정보 분산** — 동반 플러그인 정보가 "요구사항"(196), "30분 첫 사이클 0.최소준비물"(247), "동반 플러그인 설치"(305) 3곳에 흩어짐. 같은 설치 명령·FAIL 경고가 반복 | 196–211, 247–257, 305–330 |
| P5 | **TOC·네비게이션 부재** — 496줄 문서에 목차 없음. "이런 경우 여기로" 안내 없음 | 전체 |
| P6 | **고급/참조 정보가 본문 흐름에 평면 배치** — tmux 환경변수표(8행), 훅 내부, 크로스AI, 도메인 슬롯, Graceful Degradation표가 접힘 없이 모두 펼쳐져 시각적 밀도·길이 피로 유발 | 366–490 |

---

## 재구성 방향 후보 (Plan Approval에서 사용자 제시용)

| 접근 | 내용 | 변경 규모 | 위험 | 이득 |
|------|------|----------|------|------|
| **ⓐ 최소 침습** | TOC만 상단 추가 + 일부 H3 순서 미세 조정. 섹션 대이동 없음 | 소 (~+20줄) | 매우 낮음 (앵커·사실 거의 안 건드림) | 네비게이션 1건 해결(P5). P1~P4·P6 미해결 |
| **ⓑ 신규자 우선 전면 재배치 + 고급 접기 (추천)** | TOC 추가 + 섹션 순서를 "소개 → 요구사항/설치 → 첫 사이클 → 개념/원리 → 고급참조(접기)"로 재배치. tmux 환경변수표·훅내부·크로스AI·도메인슬롯을 `<details>`로 접음. 분산된 설치 정보(P4)는 한 곳으로 통합하고 나머지는 앵커로 연결 | 중 (이동 위주, 순삭제 0) | 중 (앵커 1개·코드펜스·details 짝 관리 필요) | P1~P6 전부 해결. 신규자 30초 안에 "뭐고 어떻게 시작" 도달 |
| **ⓒ 축소·중복 제거 중심** | 분산 설치 정보 통합 + 중복 산문 압축으로 길이 단축(~−80줄). 재배치는 부수적 | 중 (삭제 동반) | 높음 (사실 손실 위험 — 제약과 충돌 가능성) | 길이 피로 완화. 단 "삭제 최소" 제약과 마찰, 사실 보존 grep 부담 큼 |

**Architect 추천: ⓑ.**
- 근거: 사용자 요청("이용자가 보기 편하게")의 핵심은 **신규자 진입 경로**(P1~P4)와 **시각 밀도**(P6)다. ⓐ는 P5만 풀어 부족하고, ⓒ는 "삭제 최소·사실 보존" 제약과 정면 충돌해 위험이 높다. ⓑ는 **재배치·접기·통합**만으로 모든 문제를 풀며 삭제는 명백한 중복 1건(Task 4)에 한정 → 제약 준수와 효과를 동시에 만족.
- ⓑ는 아래 Task 1~6으로 구현한다. (사용자가 ⓐ 또는 ⓒ를 선택하면 해당 Task 부분집합만 실행.)

**목표 섹션 순서 (ⓑ):**
```
# orbit
[배지/한줄 태그라인 — 선택]
## 목차 (TOC)                         ← 신규(Task 1)
## 이게 뭐예요? (소개 + 왜 팀인가 통합)   ← 기존 1+2 인접 유지
## 빠른 시작 — 설치 3단계               ← 위로 이동(Task 2). 요구사항 요약 인라인
## 30분 만에 첫 사이클                   ← 설치 바로 뒤
## 팀 구성 — 7역                        ← 개념: 첫 사이클 뒤로
## 일하는 순서 (생명주기 + 고위험 + Triple Crown)
##   ├ opt-in 자율모드 / 병렬 / task그룹 (H3 유지)
## 동반 스킬 배선 + 3층 모델 + 강제배선   ← 메커니즘: 개념 뒤
## 참조 (Reference) ▾                   ← 고급/내부, 대부분 <details> 접기(Task 5)
##   ├ 동반 플러그인 상세 설치
##   ├ 막혔을 때(트러블슈팅)
##   ├ tmux 팀 환경 + 환경변수표  ▾(접기)
##   ├ setup-orbit.sh 단독 실행  ▾(접기)
##   ├ Graceful Degradation / 크로스AI  ▾(접기)
##   ├ 도메인 슬롯 / orbit 구성  ▾(접기)
##   └ 스킬 카탈로그
## 라이선스
```

---

## File Structure

- Modify: `/Users/dh/Project/orbit/README.md` (단일 파일 — 전 구간 재배치)

변경은 한 파일 안의 블록 이동·래핑이므로 Task를 "검증 가능한 사실 보존 단위"로 분할한다. 각 Task는 독립적으로 grep·렌더 무결성으로 검증된다.

---

## 사실 보존 체크리스트 (모든 Task 공통 — 회귀 테스트)

각 Task 종료 시 아래 스크립트를 실행해 **재구성 전후 동일**해야 한다. 출력이 달라지면 사실 손실/변형이다.

```bash
cd /Users/dh/Project/orbit
# 1. 핵심 사실 토큰 존재 카운트 (값은 변하지 않아야 함)
rtk proxy grep -coE 'plugin install orbit' README.md            # 기대: 변동 없음(>=2)
rtk proxy grep -coE 'memoriterx/Orbit' README.md                # 기대: 변동 없음(>=4)
rtk proxy grep -coE 'superpowers@claude-plugins-official' README.md  # 기대: >=2
rtk proxy grep -coE 'garrytan/gstack' README.md                 # 기대: >=2
rtk proxy grep -coE 'ORBIT_SKIP_COMPANION_CHECK' README.md      # 기대: >=1
rtk proxy grep -coE 'bundled script not found' README.md        # 기대: >=1
rtk proxy grep -coE 'raw.githubusercontent.com/memoriterx' README.md # 기대: >=1
rtk proxy grep -coE 'ORBIT_TMUX_SESSION|ORBIT_INSTALL_SCOPE|ORBIT_SKIP_UPDATE' README.md # 기대: 각 >=1
rtk proxy grep -coE '6 이벤트|6이벤트' README.md                # 기대: >=1
# 2. 도메인 순수성 (0이어야 함)
rtk proxy grep -ciE 'oremi' README.md                           # 기대: 0
# 3. 마크다운 무결성
rtk proxy grep -cE '^```|^  ```' README.md                      # 기대: 짝수
rtk proxy grep -coE '<details>' README.md ; rtk proxy grep -coE '</details>' README.md  # 기대: 동수
```

기준선(baseline)은 Task 0에서 저장한다.

---

### Task 0: 기준선 캡처 (사실 보존 회귀 기준)

**Files:**
- Read only: `/Users/dh/Project/orbit/README.md`
- Create (임시): `/private/tmp/.../baseline-facts.txt` (스크래치)

**Interfaces:**
- Produces: `baseline-facts.txt` — 재구성 후 모든 Task가 대조할 사실 토큰 카운트 스냅샷.

- [ ] **Step 1: 사실 토큰 카운트 스냅샷 저장**

```bash
cd /Users/dh/Project/orbit
{
  echo "plugin install orbit: $(rtk proxy grep -coE 'plugin install orbit' README.md)"
  echo "memoriterx/Orbit: $(rtk proxy grep -coE 'memoriterx/Orbit' README.md)"
  echo "superpowers-official: $(rtk proxy grep -coE 'superpowers@claude-plugins-official' README.md)"
  echo "garrytan/gstack: $(rtk proxy grep -coE 'garrytan/gstack' README.md)"
  echo "SKIP_COMPANION: $(rtk proxy grep -coE 'ORBIT_SKIP_COMPANION_CHECK' README.md)"
  echo "bundled-not-found: $(rtk proxy grep -coE 'bundled script not found' README.md)"
  echo "raw-github: $(rtk proxy grep -coE 'raw.githubusercontent.com/memoriterx' README.md)"
  echo "envvars: $(rtk proxy grep -coE 'ORBIT_TMUX_SESSION|ORBIT_INSTALL_SCOPE|ORBIT_SKIP_UPDATE|ORBIT_INSTALL_DEPS|ORBIT_SKIP_PLUGIN_CHECK|ORBIT_SKIP_PERMISSIONS|CLAUDE_PROJECT_DIR' README.md)"
  echo "hook-6: $(rtk proxy grep -coE 'SubagentStop|SubagentStart|UserPromptSubmit|MessageDisplay' README.md)"
  echo "oremi: $(rtk proxy grep -ciE 'oremi' README.md)"
  echo "fences: $(rtk proxy grep -cE '^\`\`\`|^  \`\`\`' README.md)"
} > /private/tmp/baseline-facts.txt
cat /private/tmp/baseline-facts.txt
```
Expected: 각 토큰의 0이 아닌 카운트(oremi만 0). fences=짝수.

- [ ] **Step 2: 커밋 불필요 (읽기 전용 기준선)**

기준선 파일은 스크래치이므로 커밋하지 않는다. 다음 Task로 진행.

---

### Task 1: 목차(TOC) 추가 (P5)

**Files:**
- Modify: `/Users/dh/Project/orbit/README.md` (H1 `# orbit` 바로 아래에 TOC 블록 삽입)

**Interfaces:**
- Consumes: 현재 렌더되는 진짜 H2 목록 (가짜 헤더 140 `## Backlog`·274 `## 백로그` 제외).
- Produces: 상단 TOC. **이후 Task에서 섹션을 재배치하면 TOC 링크도 함께 갱신**해야 한다(Task 6에서 최종 정합성 검증).

- [ ] **Step 1: TOC 블록을 H1 바로 아래 삽입**

GitHub 앵커 규칙(소문자화·공백→하이픈·특수문자 제거)에 맞춰 링크 생성. 한국어 헤더는 GitHub가 그대로 슬러그화하므로 기존 53줄 앵커(`#역할별-동반-스킬-배선-v210`) 패턴을 따른다. 예시(ⓑ 최종 순서 기준):

```markdown
## 목차

- [이게 뭐예요?](#이게-뭐예요)
- [빠른 시작 — 설치 3단계](#빠른-시작--설치-3단계)
- [30분 만에 첫 사이클](#30분-만에-첫-사이클)
- [팀 구성 — 7가지 역할](#팀-구성--7가지-역할)
- [일하는 순서 (작업 생명주기)](#일하는-순서-작업-생명주기)
- [역할별 동반 스킬 배선](#역할별-동반-스킬-배선-v210)
- [참조 (Reference)](#참조-reference)
- [라이선스](#라이선스)
```

주의: `—`(em dash)는 GitHub 슬러그에서 제거되어 `--`(연속 하이픈)로 남는다. 실제 렌더 후 앵커를 Task 6에서 클릭 검증.

- [ ] **Step 2: 도메인 순수성·펜스 회귀 체크**

```bash
cd /Users/dh/Project/orbit
rtk proxy grep -ciE 'oremi' README.md          # 기대: 0
rtk proxy grep -cE '^\`\`\`|^  \`\`\`' README.md  # 기대: 짝수(변동 없음)
```
Expected: oremi=0, fences=짝수.

- [ ] **Step 3: 커밋**

```bash
cd /Users/dh/Project/orbit
git checkout -b docs/readme-restructure   # 기본 브랜치면 분기
git add README.md
git commit -m "docs: README 목차(TOC) 추가"
```

---

### Task 2: 설치·요구사항을 상위로 재배치 (P1, P2, P3)

**Files:**
- Modify: `/Users/dh/Project/orbit/README.md` (블록 이동)

**Interfaces:**
- Consumes: 기존 "빠른 시작 — 3단계 설치"(214–238), "요구사항"(196–211) 블록.
- Produces: 소개 직후에 설치·요구사항이 오는 순서. 개념 섹션(7역·일하는순서·스킬배선)은 "30분 첫 사이클" 뒤로 이동.

- [ ] **Step 1: 섹션 블록 이동 (삭제 아님 — cut & paste)**

ⓑ 목표 순서로 H2 블록을 이동한다. 각 블록은 **헤더~다음 H2 직전까지 통째로** 이동(내부 H3·표·코드펜스 포함). 이동 대상:
- "빠른 시작 — 3단계 설치"(현 214–240) → "이게 뭐예요?/왜 팀인가" 직후로.
- "요구사항(Requirements)"(현 196–212) → 빠른 시작 바로 앞 또는 통합(Task 4와 조율).
- "30분 만에 첫 사이클"(현 242–303) → 빠른 시작 직후 유지.
- "팀 구성 7역"(현 41–57), "일하는 순서"(현 59–149), "역할별 스킬 배선"(현 152–194) → "30분 첫 사이클" 뒤로 이동.

각 블록 이동 시 앞뒤 `---` 구분선·빈 줄을 함께 관리해 마크다운 구조를 유지한다.

- [ ] **Step 2: 사실 보존 회귀 체크 (전체)**

```bash
cd /Users/dh/Project/orbit
{
  echo "plugin install orbit: $(rtk proxy grep -coE 'plugin install orbit' README.md)"
  echo "memoriterx/Orbit: $(rtk proxy grep -coE 'memoriterx/Orbit' README.md)"
  echo "envvars: $(rtk proxy grep -coE 'ORBIT_TMUX_SESSION|ORBIT_INSTALL_SCOPE|ORBIT_SKIP_UPDATE|ORBIT_INSTALL_DEPS|ORBIT_SKIP_PLUGIN_CHECK|ORBIT_SKIP_PERMISSIONS|CLAUDE_PROJECT_DIR' README.md)"
  echo "fences: $(rtk proxy grep -cE '^\`\`\`|^  \`\`\`' README.md)"
  echo "oremi: $(rtk proxy grep -ciE 'oremi' README.md)"
} | diff - <(grep -E 'plugin install orbit|memoriterx/Orbit|envvars|fences|oremi' /private/tmp/baseline-facts.txt) || echo "DIFF 발견 — 검토 필요"
```
Expected: 핵심 토큰 카운트 baseline과 동일(이동만 했으므로). oremi=0.

- [ ] **Step 3: 커밋**

```bash
cd /Users/dh/Project/orbit
git add README.md
git commit -m "docs: README 설치·요구사항 섹션 상위 재배치"
```

---

### Task 3: 개념 섹션 인접화 (소개+왜 통합 검토) (P2)

**Files:**
- Modify: `/Users/dh/Project/orbit/README.md`

**Interfaces:**
- Consumes: "이게 뭐예요?"(3–25), "왜 팀으로 나누나요?"(28–37).
- Produces: 소개 영역이 한 흐름으로 읽히도록 인접 배치 또는 "왜 팀인가"를 "이게 뭐예요?"의 H3 하위로 강등.

- [ ] **Step 1: "왜 팀으로 나누나요?"를 소개에 인접/하위화**

옵션 A(보수): 두 H2를 인접 유지(이미 인접). 옵션 B: "왜 팀으로 나누나요?"를 `### 왜 팀으로 나누나요?`로 강등해 "이게 뭐예요?" 아래 하위 절로 편입. **내용은 한 글자도 바꾸지 않고 헤더 레벨만 조정.** 결정은 Plan Approval에서 확정(기본 옵션 A — 변경 최소).

- [ ] **Step 2: 펜스·도메인 회귀 체크**

```bash
cd /Users/dh/Project/orbit
rtk proxy grep -ciE 'oremi' README.md
rtk proxy grep -cE '^\`\`\`|^  \`\`\`' README.md
```
Expected: oremi=0, fences=짝수.

- [ ] **Step 3: 커밋**

```bash
cd /Users/dh/Project/orbit
git add README.md
git commit -m "docs: README 소개 영역 흐름 정리"
```

---

### Task 4: 분산된 설치 정보 통합 (P4 — 유일한 중복 제거)

**Files:**
- Modify: `/Users/dh/Project/orbit/README.md`

**Interfaces:**
- Consumes: 동반 플러그인 설치 정보가 중복된 3곳 — "요구사항"표(201–205), "30분 첫 사이클 0.최소준비물"표(249–253), "동반 플러그인 설치"(305–330).
- Produces: 설치 명령의 **정전(canonical) 1곳**("동반 플러그인 설치" 또는 "요구사항")으로 통합. 나머지 위치는 앵커 링크로 대체.

**식별된 명백한 중복(삭제 근거 명시):**
- superpowers/gstack/gsd **설치 명령 문자열**이 "요구사항"표와 "동반 플러그인 설치" 본문에 **동일하게 2회** 등장(203–205 vs 313/319/324). "30분 첫 사이클"의 표(249–253)는 명령 없이 "어느 프롱"만 안내 → 이건 중복 아님(보존).
- **삭제 정책:** 설치 **명령 자체**는 정전 1곳에만 남기고, 다른 위치는 "→ [동반 플러그인 설치](#동반-플러그인-설치) 참조"로 대체. **명령 문자열은 정전 위치에 글자 그대로 보존**되므로 사실 손실 없음.

- [ ] **Step 1: 정전 위치 선정 및 중복 제거**

"동반 플러그인 설치" 섹션을 설치 명령 정전으로 지정. "요구사항" 섹션의 설치 명령 열은 `→ 설치 방법은 [동반 플러그인 설치](#동반-플러그인-설치)` 앵커로 축약(검증 프롱 매핑 정보는 유지). FAIL 경고 산문 중복(199–200 vs 256 vs 307–308)은 한 번만 본문에 두고 나머지는 한 줄로.

- [ ] **Step 2: 설치 명령 보존 회귀 체크 (중요)**

```bash
cd /Users/dh/Project/orbit
# 명령 문자열은 최소 1회 반드시 존재
rtk proxy grep -coE 'superpowers@claude-plugins-official' README.md  # 기대: >=1
rtk proxy grep -coE 'garrytan/gstack.git' README.md                 # 기대: >=1
rtk proxy grep -coE '/gsd-help' README.md                           # 기대: >=1
rtk proxy grep -coE '/plugin install orbit' README.md               # 기대: >=2 (설치+트러블슈팅)
```
Expected: 모든 명령 문자열 >=1 보존(0이면 사실 손실 — 롤백).

- [ ] **Step 3: 커밋**

```bash
cd /Users/dh/Project/orbit
git add README.md
git commit -m "docs: README 분산된 동반 플러그인 설치 정보 정전 통합"
```

---

### Task 5: 고급·참조 정보 `<details>` 접기 + 참조 섹션 그룹화 (P6)

**Files:**
- Modify: `/Users/dh/Project/orbit/README.md`

**Interfaces:**
- Consumes: "고급 설정 참조"(348) 하위 — tmux 환경변수표(408–416), setup-orbit.sh 단독실행(379–404), Graceful Degradation표(438–448), 크로스AI표(456–460), 도메인 슬롯표(470–478), orbit 구성(484–490).
- Produces: "참조(Reference)" H2 아래 그룹화. 밀도 높은 표/내부 메커니즘은 `<details><summary>…</summary> … </details>`로 접음.

- [ ] **Step 1: 접기 래핑 (내용 무변경, 래퍼만 추가)**

각 고급 블록을 `<details>`로 감싼다. **표·코드펜스·산문은 한 글자도 수정하지 않고** 앞에 `<details><summary>제목</summary>` 뒤에 `</details>`만 추가. 접기 후보:
- tmux 환경변수표 8행 → `<details><summary>환경변수 전체 표</summary>`
- setup-orbit.sh 단독 실행(번들 vs 래퍼 표 + curl) → `<details><summary>setup-orbit.sh 단독 실행 상세</summary>`
- Graceful Degradation표 → `<details>`
- 크로스AI표 → `<details>`
- 도메인 슬롯표 → `<details>`

**주의(마크다운 함정):** `<details>` 안의 markdown 표가 GitHub에서 렌더되려면 `<summary>` 다음에 **빈 줄 1개**가 있어야 한다. 코드펜스도 details 안에서 정상 동작하나 빈 줄 규칙 준수 필수.

- [ ] **Step 2: details 짝·펜스·사실 회귀 체크**

```bash
cd /Users/dh/Project/orbit
echo "open:  $(rtk proxy grep -coE '<details>' README.md)"
echo "close: $(rtk proxy grep -coE '</details>' README.md)"   # open==close 여야 함
echo "summary: $(rtk proxy grep -coE '<summary>' README.md)"
rtk proxy grep -cE '^\`\`\`|^  \`\`\`' README.md               # 짝수
rtk proxy grep -coE 'ORBIT_TMUX_SESSION|ORBIT_INSTALL_SCOPE|ORBIT_SKIP_UPDATE' README.md  # 보존
rtk proxy grep -coE 'bundled script not found' README.md       # 보존 >=1
rtk proxy grep -coE 'raw.githubusercontent.com/memoriterx' README.md  # 보존 >=1
```
Expected: open==close, 펜스 짝수, 환경변수·setup 사실 보존.

- [ ] **Step 3: 커밋**

```bash
cd /Users/dh/Project/orbit
git add README.md
git commit -m "docs: README 고급·참조 정보 details 접기 및 참조 섹션 그룹화"
```

---

### Task 6: 최종 정합성 — TOC 앵커·전체 사실 보존·렌더 무결성

**Files:**
- Modify: `/Users/dh/Project/orbit/README.md` (TOC 앵커 최종 갱신)

**Interfaces:**
- Consumes: 재배치 완료된 전체 README + Task 0 baseline.
- Produces: TOC 링크가 실제 헤더 앵커와 100% 일치하는 최종본.

- [ ] **Step 1: TOC 앵커 ↔ 실제 헤더 정합성 갱신**

재배치로 바뀐 섹션 순서에 맞춰 Task 1의 TOC 링크 순서·앵커를 최종 헤더와 일치시킨다. 기존 53줄 인라인 앵커(`#역할별-동반-스킬-배선-v210`)가 여전히 유효한지 확인.

- [ ] **Step 2: 전체 사실 보존 회귀 대조 (baseline diff)**

```bash
cd /Users/dh/Project/orbit
{
  echo "plugin install orbit: $(rtk proxy grep -coE 'plugin install orbit' README.md)"
  echo "memoriterx/Orbit: $(rtk proxy grep -coE 'memoriterx/Orbit' README.md)"
  echo "superpowers-official: $(rtk proxy grep -coE 'superpowers@claude-plugins-official' README.md)"
  echo "garrytan/gstack: $(rtk proxy grep -coE 'garrytan/gstack' README.md)"
  echo "SKIP_COMPANION: $(rtk proxy grep -coE 'ORBIT_SKIP_COMPANION_CHECK' README.md)"
  echo "bundled-not-found: $(rtk proxy grep -coE 'bundled script not found' README.md)"
  echo "raw-github: $(rtk proxy grep -coE 'raw.githubusercontent.com/memoriterx' README.md)"
  echo "envvars: $(rtk proxy grep -coE 'ORBIT_TMUX_SESSION|ORBIT_INSTALL_SCOPE|ORBIT_SKIP_UPDATE|ORBIT_INSTALL_DEPS|ORBIT_SKIP_PLUGIN_CHECK|ORBIT_SKIP_PERMISSIONS|CLAUDE_PROJECT_DIR' README.md)"
  echo "hook-6: $(rtk proxy grep -coE 'SubagentStop|SubagentStart|UserPromptSubmit|MessageDisplay' README.md)"
} > /private/tmp/after-facts.txt
diff <(rtk proxy grep -vE 'fences|oremi' /private/tmp/baseline-facts.txt) /private/tmp/after-facts.txt && echo "PASS: 사실 카운트 동일" || echo "FAIL: 차이 검토"
```
Expected: PASS — 모든 핵심 사실 토큰 카운트가 baseline과 동일(재배치·앵커축약만, 명령 문자열 정전 보존).

> 참고: Task 4의 중복 통합으로 일부 토큰(예: 설치 명령)이 baseline 대비 **감소**할 수 있다. 이 경우 diff는 차이를 보고하지만 **정전 위치에 >=1 보존**되었으면 정상. Step 2의 diff FAIL 시, 감소한 토큰이 "Task 4가 의도한 중복 제거 대상"인지 수동 확인하고, 그 외 토큰이 0이 되지 않았는지 검증.

- [ ] **Step 3: 마크다운 렌더 무결성 최종 확인**

```bash
cd /Users/dh/Project/orbit
echo "fences(짝수?): $(rtk proxy grep -cE '^\`\`\`|^  \`\`\`' README.md)"
echo "details open:  $(rtk proxy grep -coE '<details>' README.md)"
echo "details close: $(rtk proxy grep -coE '</details>' README.md)"
echo "oremi(0?):     $(rtk proxy grep -ciE 'oremi' README.md)"
```
Expected: 펜스 짝수, details open==close, oremi=0.

- [ ] **Step 4: (선택) 로컬 렌더 육안 확인**

가능하면 GitHub 미리보기 또는 `grip`/마크다운 뷰어로 TOC 클릭·details 펼침·표 렌더를 육안 확인. 불가 시 PR 미리보기로 대체.

- [ ] **Step 5: 최종 커밋**

```bash
cd /Users/dh/Project/orbit
git add README.md
git commit -m "docs: README TOC 앵커 정합성 및 최종 무결성 검증"
```

---

## 성공 기준 (측정 가능)

| 기준 | 측정 방법 | 목표 |
|------|----------|------|
| TOC 존재 | `## 목차` 헤더 grep | 1개 존재 |
| 설치 섹션 상위 배치 | "빠른 시작" 헤더의 줄번호 / 전체 줄수 | 상위 25% 이내 (현 43% → 개선) |
| 모든 핵심 사실 보존 | Task 6 baseline diff | 핵심 토큰 카운트 PASS(중복 제거분 제외 0 없음) |
| 도메인 순수성 | `grep -ci oremi README.md` | 0 |
| 마크다운 무결성 | 코드펜스 짝수 + details open==close | 통과 |
| TOC 앵커 유효 | 각 TOC 링크가 실제 헤더로 이동 | 깨진 링크 0 |
| 고급 정보 접기 | `<details>` 블록 수 | >=4 (P6 완화) |

## 테스트 전략 요약

- **사실 보존 회귀:** Task 0 baseline 스냅샷 ↔ Task 6 after 스냅샷 grep diff. 중복 제거(Task 4)로 의도적으로 감소한 토큰은 화이트리스트, 그 외 0 토큰은 즉시 롤백.
- **마크다운 무결성:** 코드펜스 짝수(12쌍 유지/details 추가분 반영), `<details>`/`</details>` 동수, `<summary>` 다음 빈 줄 규칙.
- **도메인 순수성:** `oremi` 0건 grep (CLAUDE.md SubagentStop 게이트와 정합).
- **앵커 무결성:** 기존 53줄 인라인 앵커 + 신규 TOC 앵커 클릭 검증.

## 고위험 4트리거 판단 (리드 게이트용)

| 트리거 | 발화? | 근거 |
|--------|-------|------|
| **T1 비가역성** | ❌ | 문서 변경, git revert로 완전 복구. 데이터 마이그레이션·하위호환 파괴 없음 |
| **T2 광범위 영향** | ❌ | 단일 파일(README.md). 공개 인터페이스·계약 변경 없음. 코드·훅·매니페스트 무관 |
| **T3 보안·무결성** | ❌ | 인증·시크릿·삭제·PII 경로 없음. 단, "사실 보존"이 준-무결성 우려 → grep 회귀 테스트로 커버 |
| **T4 신규 외부 의존성** | ❌ | 신규 런타임·서비스·벤더 종속 0. `<details>`는 표준 HTML/GFM |

**판정: 4트리거 모두 미발화 → 저위험.** critic 게이트 생략 가능(리드 최종 판단). 유일한 잔여 우려는 사실 보존이며, 이는 Task별 grep 회귀 테스트 + Task 6 baseline diff로 측정 가능하게 통제됨.
