# README setup-orbit.sh 사용법 문서 갭 보강 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** README가 "setup-orbit.sh 하나만 받아 실행"하려는 사용자에게 어느 파일(번들 vs 루트 wrapper)을 받아야 하는지, 단독 실행 시 자동 부트스트랩됨을, 그리고 잘못된 파일 선택 시 exit 1 함정을 정직하게 안내하도록 README의 "tmux 팀 환경 셋업" 절을 보강한다.

**Architecture:** 신규 절을 만들지 않고 기존 "tmux 팀 환경 셋업" 절(README:366~) 안에 소절 1개를 추가형으로 삽입한다. 정식 설치 경로(/plugin install 3단계)는 그대로 유지하고, setup-orbit.sh 단독 실행은 "tmux 편의/부트스트랩 경로"로만 한정한다(정식 대안으로 승격하지 않음 — 과대광고 금지). 두 파일의 결정적 차이(번들=자체완결 / 루트=wrapper, 레포 필요)를 명시해 함정을 제거한다.

**Tech Stack:** Markdown (README.md). 코드 변경 없음. 검증은 "서술 ↔ 실제 스크립트 동작 대조" + grep 기반 문구 존재 확인.

## Global Constraints

- 배포물(`README.md`) 변경 — **도메인 무관 유지**: 특정 프로젝트명(oremi, orbit-dev 등) 하드코딩 금지.
- **거짓·과대 안내 금지**: 서술하는 모든 동작은 실제 스크립트(`setup-orbit.sh` 두 파일)의 동작과 일치해야 한다. curl/wget 원라이너는 검증된 경우에만 안내.
- 기존 README 톤·구조·문체(한국어 경어체, "···" 불릿, 표 형식) 유지. **추가형 우선** — 기존 정확한 서술(특히 README:391 "플러그인 자동 감지·설치", README:371–377 두 실행 형태) 훼손 금지.
- 정식 설치 경로(README:214–225 빠른 시작 3단계)는 **무손상**. setup-orbit.sh 단독 실행을 "정식 대안"으로 승격하지 않는다.
- 커밋 메시지 접두사 `docs:` 사용. **Co-Authored-By 줄 절대 금지**(프로젝트 CLAUDE.md 규칙).

---

## 확정된 사실 기반 (구현자가 신뢰할 근거)

구현 전 architect가 두 스크립트와 README를 직접 읽어 확인한 사실. 구현자는 이를 전제로 작성하되, **Task 4에서 반드시 재대조**한다.

1. **루트 `/Users/dh/Project/orbit/setup-orbit.sh`** (21줄, 검증됨):
   - thin wrapper. `SCRIPT_DIR/plugins/orbit/scripts/setup-orbit.sh`를 `exec bash`로 위임.
   - 번들 파일이 옆에 없으면 (`if [ ! -f "$BUNDLED" ]`) → stderr `Error: bundled script not found at <경로>` 출력 후 **`exit 1`**.
   - 즉 **단독 복사·다운로드 시 동작 불가** — orbit 레포 디렉터리 구조(`plugins/orbit/scripts/`)가 옆에 있어야 함.

2. **번들 `/Users/dh/Project/orbit/plugins/orbit/scripts/setup-orbit.sh`** (339줄, 검증됨):
   - **자체완결형** — sibling 파일을 `source`하지 않음. 모든 로직 인라인. → **단일 파일 단독 실행 가능**.
   - step `[2/7]`(라인 133–243): `ORBIT_SKIP_PLUGIN_CHECK=1`이 아니면 `claude plugin list`로 orbit 설치 확인 → 미설치 시 `claude plugin marketplace add memoriterx/Orbit` + `claude plugin install orbit` 자동 시도(비대화형, 멱등). 실패해도 `exit` 안 함 — 수동 명령 안내 후 계속.
   - 즉 **단독 실행 시 orbit 플러그인을 자동 부트스트랩**.

3. **README 현재 상태** (검증됨):
   - 정식 설치 경로(214–225): `/plugin marketplace add` → `/plugin install orbit` → `/orbit-init`. setup-orbit.sh 미등장.
   - setup-orbit.sh는 "tmux 팀 환경 셋업" 절(366~)에만 등장. 두 실행 형태(373 번들 경로, 376 루트 경로) 제시.
   - 391: setup-orbit.sh 자동 감지·설치 이미 서술. 그러나 **"번들 스크립트를 단독으로 받아 실행"하는 사용 패턴은 미문서화**.
   - curl/wget/다운로드 안내 0건.

4. **curl 원라이너 가능성 판정** (Task 1에서 외부 검증 필수):
   - 번들 스크립트가 자체완결이므로 raw 단일 파일 다운로드 후 실행은 **기술적으로 성립**. 후보 raw URL: `https://raw.githubusercontent.com/memoriterx/Orbit/main/plugins/orbit/scripts/setup-orbit.sh`.
   - **그러나** 레포 기본 브랜치명·공개 여부·정확한 경로가 미확인이면 거짓 안내가 된다. Task 1에서 실제 확인되지 않으면 **curl 원라이너를 작성하지 않고** "레포/플러그인 디렉터리에서 복사" 안내만 한다(거짓 안내 금지 제약).

---

## File Structure

- **Modify only:** `/Users/dh/Project/orbit/README.md` — "tmux 팀 환경 셋업" 절(현재 366~405)에 소절 1개 삽입. 기존 두 실행 형태 코드블록(371–377)과 391 자동설치 서술 사이, 또는 직후가 자연스러운 삽입점.
- 신규 파일 없음. 다른 파일 변경 없음.

---

## Discovery 결정 사항 (리드가 위임한 (a)(b)(c) 판단 결과)

플랜 작성 전 architect가 확정한 설계 판단. 구현자는 이를 따른다.

- **(a) 위치:** 별도 최상위 절을 만들지 않고 **기존 "tmux 팀 환경 셋업" 절 안의 소절**로 보강한다. 이유: setup-orbit.sh의 일차 목적이 tmux 2분할 환경 구성이고, 단독 실행 패턴도 그 부트스트랩의 부산물이다. 별도 절은 정식 경로와 경쟁하는 인상을 줘 과대광고 위험.
- **(b) 정식 경로와의 정렬:** setup-orbit.sh 단독 실행을 **"tmux 편의/부트스트랩 경로"로 한정**한다. 정식 설치는 여전히 `/plugin install` 3단계임을 명시적으로 재확인하는 한 줄을 둔다. "정식 대안으로 승격" 안 함.
- **(c) "받는" 현실적 경로:** 번들 스크립트는 자체완결이므로 (1) orbit 레포 클론 후 `plugins/orbit/scripts/setup-orbit.sh` 사용, (2) 플러그인 설치 후 `${CLAUDE_PLUGIN_ROOT}/scripts/setup-orbit.sh` 사용(이미 문서화됨), (3) raw 단일 파일 다운로드(curl) — **단, (3)은 Task 1 검증 통과 시에만**. 루트 wrapper는 단독 복사 시 동작 불가임을 명시.

---

### Task 1: curl 원라이너 가능성 외부 검증 (안내 정확성 게이트)

이 Task는 코드를 쓰지 않는다. **거짓 안내 금지 제약을 만족시키기 위한 사실 확인**이다. 결과에 따라 Task 3의 분기가 결정된다.

**Files:**
- 없음 (검증만). 결과를 Task 3 분기 입력으로 사용.

**Interfaces:**
- Consumes: 후보 raw URL `https://raw.githubusercontent.com/memoriterx/Orbit/main/plugins/orbit/scripts/setup-orbit.sh` (브랜치 `main` 가정 — 검증 대상).
- Produces: 불리언 `CURL_VERIFIED` (true/false) + 검증된 정확한 raw URL(있으면). Task 3이 이 값으로 curl 블록 포함 여부를 결정.

- [ ] **Step 1: 레포 공개 여부·기본 브랜치·파일 경로 확인**

다음 중 가능한 방법으로 확인한다(순서대로 시도):

```bash
# 방법 A: gh CLI로 레포 메타 확인 (기본 브랜치명)
gh repo view memoriterx/Orbit --json defaultBranchRef,visibility 2>/dev/null

# 방법 B: raw URL이 실제로 스크립트를 반환하는지 (200 + shebang 확인)
curl -fsSL "https://raw.githubusercontent.com/memoriterx/Orbit/main/plugins/orbit/scripts/setup-orbit.sh" 2>/dev/null | head -1
```

Expected: 방법 A는 `"defaultBranchRef":{"name":"..."}` 와 `"visibility":"PUBLIC"`. 방법 B는 첫 줄이 `#!/bin/bash`.

- [ ] **Step 2: 판정 기록**

- 방법 B 첫 줄이 `#!/bin/bash`이고 레포가 PUBLIC이면 → `CURL_VERIFIED=true`, 검증된 URL 확정(기본 브랜치명이 `main`이 아니면 URL의 브랜치 세그먼트를 실제 값으로 교체).
- 200이 아니거나 레포가 PRIVATE이거나 네트워크로 확인 불가면 → `CURL_VERIFIED=false`. **이 경우 Task 3에서 curl 블록을 절대 작성하지 않는다**(거짓 안내 금지). 복사 안내만 남긴다.

> **주의:** 검증 불가(네트워크 차단 등)는 `false`와 동일하게 보수적으로 처리한다. "아마 될 것"으로 curl을 쓰지 않는다.

- [ ] **Step 3: 커밋 없음**

이 Task는 산출물이 없으므로 커밋하지 않는다. 결과만 Task 3로 전달.

---

### Task 2: 보강 소절 문안 작성 — 공통(검증 불요) 부분

`CURL_VERIFIED` 값과 무관하게 항상 들어가는 문안을 README에 삽입한다. curl 블록은 Task 3에서 분기 처리하므로 여기서는 비워 둔다(플레이스홀더 아님 — Task 3가 같은 절을 이어서 채운다).

**Files:**
- Modify: `/Users/dh/Project/orbit/README.md` — "tmux 팀 환경 셋업" 절. 두 실행 형태 코드블록(현재 371–377) 직후, "주요 환경변수:" 표(379~) **앞**에 소절 삽입.

**Interfaces:**
- Consumes: 확정된 사실 1·2·3(위), Discovery 결정 (a)(b)(c).
- Produces: README에 `#### setup-orbit.sh를 단독으로 받아 실행하기` 소절(curl 블록 자리 제외). Task 3이 curl 블록 자리를 채운다.

- [ ] **Step 1: 삽입 위치 확인 (실패 가능성 점검)**

Run:
```bash
grep -n "orbit 레포 루트에서 직접 실행" /Users/dh/Project/orbit/README.md
grep -n "^주요 환경변수:" /Users/dh/Project/orbit/README.md
```
Expected: 첫 grep은 코드블록 주석 라인(현재 ~375), 둘째는 표 도입 라인(현재 ~379). 두 라인 사이가 삽입점.

- [ ] **Step 2: 소절 본문 삽입**

기존 코드블록(```` ```bash ... bash /path/to/orbit/setup-orbit.sh ... ``` ````, 현재 371–377)과 "주요 환경변수:" 줄 사이에 아래를 삽입한다.

```markdown
#### setup-orbit.sh를 단독으로 받아 실행하기

> **정식 설치는 여전히 위 "빠른 시작 — 3단계 설치"입니다.** 아래는 tmux 팀 환경을 한 번에 구성하려는 편의·부트스트랩 경로이며, 정식 설치를 대체하지 않습니다.

"스크립트 하나만 받아서 실행하면 되나요?"에 대한 답은 **어느 파일을 받느냐에 따라 다릅니다.** orbit에는 이름이 같은 `setup-orbit.sh`가 두 개 있고, 동작이 다릅니다.

| 파일 | 단독 실행 | 동작 |
|------|----------|------|
| `plugins/orbit/scripts/setup-orbit.sh` (**번들**) | **가능** | 자체완결형. orbit 미설치 시 마켓플레이스 등록·`orbit` 설치까지 자동 부트스트랩한 뒤 tmux 2분할 환경을 만듭니다. |
| `setup-orbit.sh` (**레포 루트, wrapper**) | **불가** | 옆에 있는 번들 스크립트(`plugins/orbit/scripts/setup-orbit.sh`)로 위임하는 얇은 래퍼입니다. 이 파일만 떼어 복사·다운로드해 실행하면 `Error: bundled script not found` 와 함께 종료됩니다(exit 1). orbit 레포 디렉터리 구조 전체가 있어야 동작합니다. |

**따라서 "하나만 받아 실행"하려면 반드시 번들 파일(`plugins/orbit/scripts/setup-orbit.sh`)을 받으세요.** 루트 래퍼는 레포를 통째로 클론·체크아웃한 개발·테스트 환경에서만 의미가 있습니다.

받는 방법:

- **이미 플러그인을 설치했다면** — 위 코드블록의 `${CLAUDE_PLUGIN_ROOT}/scripts/setup-orbit.sh` 형태를 그대로 쓰면 됩니다(추가 다운로드 불필요).
- **레포를 클론했다면** — `plugins/orbit/scripts/setup-orbit.sh`를 직접 실행하거나, 그 파일 하나만 다른 위치로 복사해 실행해도 됩니다(자체완결이라 단독 동작).

<!-- CURL_BLOCK_SLOT: Task 3에서 CURL_VERIFIED 값에 따라 채움 -->
```

- [ ] **Step 3: 삽입 결과 형식 확인**

Run:
```bash
grep -n "단독으로 받아 실행하기" /Users/dh/Project/orbit/README.md
grep -n "CURL_BLOCK_SLOT" /Users/dh/Project/orbit/README.md
```
Expected: 두 grep 모두 정확히 1건. 슬롯 주석이 "주요 환경변수:" 표 앞에 위치.

- [ ] **Step 4: 도메인 순수성·정식경로 무손상 확인**

Run:
```bash
grep -rEi 'oremi|orbit-dev' /Users/dh/Project/orbit/README.md
grep -n "빠른 시작 — 3단계 설치" /Users/dh/Project/orbit/README.md
```
Expected: 첫 grep 0건(도메인 무관 유지). 둘째 grep 1건(정식 경로 절 무손상).

- [ ] **Step 5: 커밋**

```bash
git add README.md
git commit -m "docs: README — setup-orbit.sh 단독 실행 소절 추가(번들 vs 루트 wrapper 구분)"
```

---

### Task 3: curl 원라이너 블록 분기 채움

Task 1의 `CURL_VERIFIED` 값에 따라 슬롯(`<!-- CURL_BLOCK_SLOT ... -->`)을 채운다. **둘 중 하나만 적용**한다.

**Files:**
- Modify: `/Users/dh/Project/orbit/README.md` — `<!-- CURL_BLOCK_SLOT ... -->` 주석 줄을 교체.

**Interfaces:**
- Consumes: Task 1의 `CURL_VERIFIED`(true/false)와 검증된 raw URL.
- Produces: 슬롯 위치에 curl 안내(검증 시) 또는 복사 전용 안내(미검증 시). 슬롯 주석 제거.

- [ ] **Step 1: 분기 A — `CURL_VERIFIED=true`인 경우만**

슬롯 주석 줄을 아래로 교체한다. URL은 Task 1에서 **실제 검증된 값**으로 기입한다(아래는 `main` 브랜치 검증 가정 — 실제 값과 다르면 교체).

```markdown
- **아무것도 클론·설치하지 않았다면** — 번들 스크립트 한 파일만 내려받아 실행할 수 있습니다(자체완결이라 부트스트랩 포함):

  ```bash
  curl -fsSL https://raw.githubusercontent.com/memoriterx/Orbit/main/plugins/orbit/scripts/setup-orbit.sh -o setup-orbit.sh
  bash setup-orbit.sh
  ```

  > 받은 파일은 **반드시 위 표의 "번들" 파일**입니다(루트 래퍼가 아님). 실행하면 orbit 미설치 시 자동으로 설치한 뒤 tmux 환경을 구성합니다.
```

- [ ] **Step 2: 분기 B — `CURL_VERIFIED=false`인 경우만 (A 대신)**

슬롯 주석 줄을 아래로 교체한다. **curl 블록을 쓰지 않는다**(거짓 안내 금지).

```markdown
> **다운로드 원라이너 안내 없음(의도적):** 번들 스크립트의 직접 다운로드 URL은 이 문서에서 보장하지 않습니다. 위 두 방법(플러그인 설치 후 `${CLAUDE_PLUGIN_ROOT}` 사용, 또는 레포에서 번들 파일 복사)을 사용하세요.
```

- [ ] **Step 3: 슬롯 주석 잔존 여부 확인**

Run:
```bash
grep -n "CURL_BLOCK_SLOT" /Users/dh/Project/orbit/README.md
```
Expected: 0건(슬롯이 분기 내용으로 교체됨). 1건 이상이면 교체 누락 — 수정.

- [ ] **Step 4: 분기 정합성 확인**

Run:
```bash
grep -c "raw.githubusercontent.com/memoriterx/Orbit" /Users/dh/Project/orbit/README.md
```
Expected: 분기 A 적용 시 1(curl 블록), 분기 B 적용 시 0(curl 미작성). 값이 분기 선택과 불일치하면 잘못된 분기 — 수정.

- [ ] **Step 5: 커밋**

```bash
git add README.md
git commit -m "docs: README — setup-orbit.sh 단독 실행 다운로드 경로 안내(검증 분기 반영)"
```

---

### Task 4: 서술 ↔ 실제 스크립트 동작 대조 (테스트 게이트)

문서 변경이므로 "테스트"는 **서술이 실제 스크립트 동작과 일치하는지 대조**로 정의한다. 불일치 발견 시 해당 Task로 돌아가 수정.

**Files:**
- 없음 (검증만). 대조 실패 시 Task 2/3 문안 수정.

**Interfaces:**
- Consumes: 두 스크립트 실파일(`setup-orbit.sh` 루트·번들), 보강된 README.
- Produces: 측정 가능한 PASS/FAIL 판정(아래 체크 전부 PASS여야 완료).

- [ ] **Step 1: 루트 wrapper 함정 서술 대조**

서술 주장: "루트 래퍼는 단독 실행 시 `Error: bundled script not found` + exit 1". 실파일로 확인:

Run:
```bash
grep -n "bundled script not found" /Users/dh/Project/orbit/setup-orbit.sh
grep -n "exit 1" /Users/dh/Project/orbit/setup-orbit.sh
```
Expected: 두 grep 모두 매치(에러 메시지 라인 ~17, exit 1 라인 ~18). README의 함정 표현과 에러 문구가 **글자 그대로 일치**해야 함. 불일치 시 Task 2 표 문구 수정.

- [ ] **Step 2: 번들 자체완결·자동 부트스트랩 서술 대조**

서술 주장: "번들은 자체완결, orbit 미설치 시 마켓 등록+install 자동 시도".

Run:
```bash
grep -n "^source\|^\. " /Users/dh/Project/orbit/plugins/orbit/scripts/setup-orbit.sh
grep -n "plugin marketplace add memoriterx/Orbit" /Users/dh/Project/orbit/plugins/orbit/scripts/setup-orbit.sh
grep -n "plugin install orbit" /Users/dh/Project/orbit/plugins/orbit/scripts/setup-orbit.sh
```
Expected: 첫 grep 0건(sibling source 없음 = 자체완결 확인). 둘째·셋째 grep 각 1건 이상(자동 부트스트랩 확인). 불일치 시 Task 2 표 "번들" 행 수정.

- [ ] **Step 3: 정식 경로 무손상·도메인 순수성 회귀 확인**

Run:
```bash
grep -n "/plugin install orbit" /Users/dh/Project/orbit/README.md | head -3
grep -rEi 'oremi|orbit-dev' /Users/dh/Project/orbit/README.md
```
Expected: 첫 grep — 빠른 시작 3단계 절의 정식 명령이 그대로 존재. 둘째 grep — 0건.

- [ ] **Step 4: 함정 명시 성공 기준 grep (측정 가능 성공 기준)**

Run:
```bash
grep -q "bundled script not found" /Users/dh/Project/orbit/README.md && echo "PASS: 함정 명시" || echo "FAIL: 함정 미명시"
grep -q "번들" /Users/dh/Project/orbit/README.md && echo "PASS: 번들 안내" || echo "FAIL"
grep -q "정식 설치는 여전히" /Users/dh/Project/orbit/README.md && echo "PASS: 정식경로 한정" || echo "FAIL"
```
Expected: 3건 모두 `PASS`. 하나라도 FAIL이면 해당 문안 보강.

- [ ] **Step 5: curl 분기 정확성 최종 확인**

Run:
```bash
# CURL_VERIFIED=true였다면 curl 블록 존재, false였다면 부재여야 함
grep -c "curl -fsSL https://raw.githubusercontent.com/memoriterx/Orbit" /Users/dh/Project/orbit/README.md
```
Expected: Task 1 판정과 일치(true→1, false→0). 불일치 시 거짓/누락 안내 — Task 3 재적용.

- [ ] **Step 6: 커밋 없음(검증 Task)**

대조 전부 PASS면 완료. 실패 항목이 있었다면 해당 Task에서 수정·재커밋 후 이 Task 재실행.

---

## Self-Review (architect 작성 후 점검)

**1. Spec coverage:**
- "어느 파일을 받아야 하는지" → Task 2 표(번들 vs 루트). ✓
- "단독 실행 시 자동 부트스트랩됨" → Task 2 표 "번들" 행 + curl 분기 주석. ✓
- "함정 명시(루트 wrapper 단독 불가, exit 1)" → Task 2 표 "루트" 행 + Task 4 Step 1 대조. ✓
- "(a) 위치 판단" → Discovery 결정 (a): 기존 절 내 소절. ✓
- "(b) 정식경로 정렬" → Discovery (b) + Task 2 인용 블록 "정식 설치는 여전히". ✓
- "(c) 받는 경로 + curl 검증" → Task 1(검증) + Task 3(분기). ✓
- "성공 기준 측정 가능" → Task 4 Step 4 grep PASS/FAIL. ✓
- "테스트 전략(서술↔동작 대조)" → Task 4 전체. ✓

**2. Placeholder scan:** `<!-- CURL_BLOCK_SLOT -->`는 플레이스홀더가 아니라 Task 3가 명시 분기로 채우는 슬롯(실제 두 분기 문안 모두 본문 제공). "TBD/TODO/적절히" 류 없음. ✓

**3. Type consistency:** `CURL_VERIFIED` 명칭이 Task 1(정의)·Task 3(소비)·Task 4(검증)에서 동일. raw URL 경로(`plugins/orbit/scripts/setup-orbit.sh`)가 전 Task 일관. ✓

---

## 미해결·구현자 주의

- **curl URL 브랜치명**: 본 플랜은 기본 브랜치를 `main`으로 가정한다. Task 1에서 실제 기본 브랜치가 다르면(`master` 등) Task 3 URL의 브랜치 세그먼트를 교체할 것. 검증 없이 `main` 하드코딩 금지.
- 삽입 위치 라인 번호(371–379 등)는 본 플랜 작성 시점 스냅샷. Task 2 Step 1의 grep으로 실제 위치를 재확인한 뒤 삽입할 것(라인 드리프트 대비).
