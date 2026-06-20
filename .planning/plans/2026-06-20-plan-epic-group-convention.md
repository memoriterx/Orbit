# Epic/Task-Group 경량 컨벤션 (옵션 1) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** orbit-base에 "여러 task를 한 그룹으로 묶어 표현하는" 경량 컨벤션을 **순수 텍스트 규약으로** 도입한다 — 스키마·훅·생명주기 변경 없이, roadmap.md 안에서 그룹 헤더 + task ID 접두사만으로.

**Architecture:** 신규 구조물 0. 배포물 `plugins/orbit-base/` 내 **정확히 2개 정규 표면**(SKILL.md "Roadmap: Thin Ledger" 섹션 + roadmap 템플릿)에만 컨벤션을 문서화한다. 그룹은 **수동 라벨**이며 능동 진행률 추적기가 아니다 — 이 계약 문구를 명시적으로 못박아 thin 철학·단일작업 생명주기·허브앤스포크가 전부 무변경임을 보장한다. 롤백 = 추가한 문단/예시 제거.

**Tech Stack:** Markdown (에이전트 프롬프트·스킬·템플릿). 코드·JSON 매니페스트 무변경. 검증은 grep 기반 도메인 순수성 게이트 + Triple Crown 문서 일관성 리뷰.

## Global Constraints

- 채택안: **옵션 1 (경량 묶음 — 순수 컨벤션)**. 옵션 2(1급 Epic 능동 추적)는 명시적으로 비채택 — 진행률 롤업·생명주기 변경 금지.
- 배포물 한정: `plugins/orbit-base/` 만 편집. `.claude/`(dev팀)·`.planning/`(dev팀 상태)은 이 플랜의 편집 대상이 아니다.
- **도메인 무관성(domain-agnostic)**: 모든 예시는 슬롯/플레이스홀더(`[GROUP-NAME]`, `[PREFIX-N]`, `<...>`)로 작성. 특정 프로젝트명(oremi 등)·실제 task ID 하드코딩 절대 금지.
- **정규 계약 무변경**: `CLAUDE.md` "Memory vs. Roadmap"(milestone 의미론)·생명주기 문구·`commands/orbit-cycle.md`·`agents/leader.md`·codex/gemini 참조는 건드리지 않는다. 옵션 1의 blast radius = 2 표면이라는 핵심 안전 주장이 이 무변경에 달려 있다.
- 그룹은 **수동 라벨**이지 능동 진행률 추적기가 아니다. 묶음은 여전히 task 단위로 plan→approve→build→verify를 거친다.
- 고위험 4트리거: **옵션 1 = 저위험 확정** (T1 가역·T2 2표면/공개계약 무변경·T3 보안무관·T4 외부의존성 무. critic 분기 생략 가능).

---

## 닿는 표면 확정 목록

옵션 1이 실제 편집하는 표면은 **정확히 2개**다. 나머지는 **명시적 no-touch**(무변경 회귀 검증 대상).

### 편집 표면 (2개)

| # | 파일 | 섹션 | 변경 내용 |
|---|------|------|-----------|
| **E1** | `plugins/orbit-base/skills/using-orbit/SKILL.md` | "Roadmap: Thin Ledger" (현재 102-110행) | 섹션 끝에 "(선택) 큰 기능 묶기 — 경량 컨벤션" 하위 문단 1개 추가. 컨벤션 정의 + "수동 라벨, 능동 추적 아님" 계약 문구. |
| **E2** | `plugins/orbit-base/templates/roadmap.template.md` | "## 백로그" 섹션 | 그룹 헤더 컨벤션 *주석 예시* 추가 (구조 강제 아님). |

### No-Touch 표면 (회귀 검증 대상 — 무변경이어야 함)

| 파일 | 이유 |
|------|------|
| `plugins/orbit-base/CLAUDE.md` (Memory vs. Roadmap, Context Mgmt) | milestone 의미론·thin 정의 무변경 — 옵션 1은 정규 계약을 건드리지 않음 |
| `plugins/orbit-base/commands/orbit-cycle.md` | 생명주기 무변경 (그룹은 프로세스가 아니라 표기) |
| `plugins/orbit-base/agents/leader.md` | leader 직접 행동 무변경 (롤업 책임자 신설 없음) |
| `plugins/orbit-base/skills/using-orbit/references/codex-tools.md` | "thin task ledger" 문구 유지 |
| `plugins/orbit-base/skills/using-orbit/references/gemini-tools.md` | "thin task ledger" 문구 유지 |
| SKILL.md Quick Reference 표 (134행) | `Thin Ledger \| Minimal roadmap — no ceremony` 유지 — 컨벤션은 ceremony가 아니므로 이 줄과 모순 없음 |

---

## 컨벤션 명세 (이 플랜이 문서화할 규약 — 단일 정의)

E1·E2에 들어갈 컨벤션의 정본. 두 표면은 이 명세와 자기일관적이어야 한다.

1. **그룹 헤더 문법**: `### [GROUP-NAME] <그룹 설명>`
   - `[GROUP-NAME]`은 대문자 슬러그(`[EPIC]`, `[PAYMENTS]` 등) — 도메인 슬롯.
   - 헤더는 백로그(또는 현재 진행 중) 섹션 안에 둔다.
2. **task ID 접두사**: `[PREFIX-N]` — 그룹을 식별하는 접두사 + 일련번호.
   - 형태: `[PREFIX-1]`, `[PREFIX-2]` …. `PREFIX`는 그룹과 연관된 슬롯, `N`은 정수.
3. **부모-자식 표현**: task가 그룹 헤더 **바로 아래 모여** 있으면 헤더가 곧 부모 참조다. 헤더에서 떨어진 task는 줄 끝에 `↳ part of [GROUP-NAME]` 역참조 한 줄로 소속을 표시할 수 있다(선택).
4. **수동 라벨 계약 (못박기)**: 그룹은 **수동 라벨**이지 능동 진행률 추적기가 아니다.
   - 진행률 롤업(`3/5 완료` 같은 정규 필드)을 **요구하지 않는다**. 사람이 `- [x]` 개수를 눈으로 셀 수 있을 뿐.
   - 그룹은 **생명주기를 바꾸지 않는다**: 각 하위 task는 독립적으로 plan→approve→build→verify를 거친다.
   - 그룹은 **허브앤스포크를 바꾸지 않는다**: 새 역할·롤업 책임자·에이전트 간 통신이 생기지 않는다.
   - 그룹은 **milestone을 대체하지 않는다**: milestone은 여전히 완료 task를 묶는 사후 라벨이고, 그룹은 진행 중 task를 *표기상* 묶는 백로그 내 응집 장치다.
5. **선택성**: 컨벤션은 강제되지 않는다. 큰 기능이 없으면 헤더 없이 평평한 백로그를 쓴다.

---

## Task 1: SKILL.md "Roadmap: Thin Ledger"에 경량 컨벤션 문단 추가 (E1)

**Files:**
- Modify: `plugins/orbit-base/skills/using-orbit/SKILL.md` (현재 102-110행 "Roadmap: Thin Ledger" 섹션 끝)

**Interfaces:**
- Consumes: 없음 (독립 task)
- Produces: 컨벤션 정본 문단. Task 2의 템플릿 예시가 이 문단의 문법(`### [GROUP-NAME]`, `[PREFIX-N]`, "수동 라벨")과 일치해야 함.

- [ ] **Step 1: 현재 섹션 확인 (실패 테스트 대용 — 현재 상태에 컨벤션 문단이 없음을 확인)**

Run:
```bash
grep -c '큰 기능 묶기' plugins/orbit-base/skills/using-orbit/SKILL.md
```
Expected: `0` (아직 없음 — 추가 후 1이 되어야 함)

- [ ] **Step 2: "Roadmap: Thin Ledger" 섹션 끝에 컨벤션 문단 추가**

현재 섹션(110행 "...promoted to project memory, not the roadmap." 직후, 다음 `##` 헤더 "Graceful Degradation by Environment" 전)에 아래를 삽입한다:

```markdown
### Grouping Large Features — Lightweight Convention (optional)

A large feature spanning several tasks can express cohesion with a **group header** and an **ID prefix** — pure convention, no new structure:

- **Group header:** `### [GROUP-NAME] <description>` inside the backlog (or current) section.
- **Task ID prefix:** `[PREFIX-N]` on each member task (e.g. `[PREFIX-1]`, `[PREFIX-2]`).
- **Parent reference:** tasks gathered directly under the header inherit it; a task placed elsewhere may add a trailing `↳ part of [GROUP-NAME]`.

```
## Backlog

### [GROUP-NAME] <large-feature description>
- [ ] **[PREFIX-1] <sub-task>** — <description>
- [x] **[PREFIX-2] <sub-task>** — <completion date>
- [ ] **[PREFIX-3] <sub-task>** — <description>
```

**A group is a manual label, not an active progress tracker.** It does not require a roll-up field (no `N/M complete` contract) — readers simply count `- [x]` by eye. Grouping changes nothing about the lifecycle (each sub-task still runs plan → approve → build → verify independently) or hub-and-spoke (no new role or roll-up owner). It does not replace milestones: milestones remain post-hoc labels for completed work; a group is an in-place cohesion device for backlog items. The roadmap stays a thin ledger — this is naming, not ceremony.
```

> 도메인 무관성: 예시는 전부 `[GROUP-NAME]`·`[PREFIX-N]`·`<...>` 슬롯. 실제 프로젝트명·task ID 없음.

- [ ] **Step 3: 추가 확인 (통과 검증)**

Run:
```bash
grep -c 'Grouping Large Features' plugins/orbit-base/skills/using-orbit/SKILL.md
```
Expected: `1`

- [ ] **Step 4: 도메인 순수성 — 새 문단이 하드코딩을 끌어들이지 않았는지 확인**

Run:
```bash
grep -nEi 'oremi|orbit-dev' plugins/orbit-base/skills/using-orbit/SKILL.md
grep -nE '\[PAY-[0-9]|\[EPIC\] 결제' plugins/orbit-base/skills/using-orbit/SKILL.md
```
Expected: 둘 다 빈 출력 (실제 도메인 예시가 SKILL.md에 새지 않음 — 슬롯만 사용)

- [ ] **Step 5: 무변경 회귀 — Thin Ledger 정의·milestone 의미론 문구가 그대로인지**

Run:
```bash
grep -c 'no ceremony' plugins/orbit-base/skills/using-orbit/SKILL.md
grep -c 'Milestones: grouped delivery targets' plugins/orbit-base/skills/using-orbit/SKILL.md
```
Expected: 각각 `1` (기존 Thin Ledger 핵심 문구 보존 — 컨벤션이 ceremony 주장과 모순 없음)

- [ ] **Step 6: Commit**

```bash
git add plugins/orbit-base/skills/using-orbit/SKILL.md
git commit -m "feat(base): document lightweight task-group convention in Thin Ledger"
```

---

## Task 2: roadmap 템플릿에 그룹 헤더 주석 예시 추가 (E2)

**Files:**
- Modify: `plugins/orbit-base/templates/roadmap.template.md` (현재 "## 백로그" 섹션, 23-29행 영역)

**Interfaces:**
- Consumes: Task 1이 정의한 컨벤션 문법 (`### [GROUP-NAME]`, `[PREFIX-N]`, "수동 라벨"). 템플릿 예시는 이와 글자 그대로 일치해야 함.
- Produces: end-user가 보는 roadmap 스키마 안의 컨벤션 예시.

- [ ] **Step 1: 현재 백로그 섹션 확인 (현재 그룹 예시 없음)**

Run:
```bash
grep -c 'GROUP-NAME' plugins/orbit-base/templates/roadmap.template.md
```
Expected: `0` (추가 후 1+)

- [ ] **Step 2: "## 백로그" 섹션에 그룹 컨벤션 주석 예시 추가**

현재 백로그 섹션:
```markdown
## 백로그

<!-- 우선순위 순으로 정렬. 선택 시 "현재 진행 중"으로 이동. -->

- [ ] **<작업명>** — <한 줄 설명>
- [ ] **<작업명>** — <한 줄 설명>
```

이것을 아래로 교체한다 (기존 평평한 예시는 유지하고, 그 아래에 선택적 그룹 예시를 *주석으로* 덧붙임):
```markdown
## 백로그

<!-- 우선순위 순으로 정렬. 선택 시 "현재 진행 중"으로 이동. -->

- [ ] **<작업명>** — <한 줄 설명>
- [ ] **<작업명>** — <한 줄 설명>

<!--
(선택) 큰 기능 묶기 — 경량 컨벤션. 신규 구조·진행률 롤업·생명주기 변경 없음.
그룹은 수동 라벨이며 능동 진행률 추적기가 아니다. 각 하위 작업은 독립적으로
plan→approve→build→verify를 거친다. 자세한 규약은 using-orbit SKILL.md 참조.

### [GROUP-NAME] <큰 기능 설명>
- [ ] **[PREFIX-1] <하위 작업>** — <설명>
- [x] **[PREFIX-2] <하위 작업>** — <완료일>
- [ ] **[PREFIX-3] <하위 작업>** — <설명>
-->
```

> 도메인 무관성: 슬롯만(`[GROUP-NAME]`, `[PREFIX-N]`, `<...>`). 예시를 *주석*으로 둬 빈 템플릿을 받은 사용자가 평평한 백로그를 기본으로 쓰되, 필요 시 주석을 참고하도록 함 (구조 강제 아님).

- [ ] **Step 3: 추가 확인**

Run:
```bash
grep -c 'GROUP-NAME' plugins/orbit-base/templates/roadmap.template.md
grep -c 'PREFIX-1' plugins/orbit-base/templates/roadmap.template.md
```
Expected: 각각 `1` 이상

- [ ] **Step 4: SKILL ↔ 템플릿 자기일관성 — 두 표면의 문법이 일치하는지**

Run:
```bash
# 두 파일 모두 동일한 헤더 문법 [GROUP-NAME] 과 접두사 PREFIX-N 를 쓰는지
grep -l 'GROUP-NAME' plugins/orbit-base/skills/using-orbit/SKILL.md plugins/orbit-base/templates/roadmap.template.md
```
Expected: 두 파일 경로 모두 출력 (문법 토큰 일치 — Task1·Task2 정합)

- [ ] **Step 5: 도메인 순수성 게이트 (배포물 전체)**

Run:
```bash
grep -rnEi 'oremi' plugins/orbit-base/
grep -rnE '\[PAY-[0-9]|결제 리팩터링' plugins/orbit-base/
```
Expected: 둘 다 빈 출력 (사용자 미리보기의 `[PAY-N]`·"결제 리팩터링"은 *예시일 뿐* — 배포물엔 슬롯만 들어가야 함)

- [ ] **Step 6: Commit**

```bash
git add plugins/orbit-base/templates/roadmap.template.md
git commit -m "feat(base): add optional task-group convention example to roadmap template"
```

---

## TDD / 검증 전략

컨벤션은 코드가 아니라 문서다. 따라서 "테스트"는 grep 기반 불변 검증 + Triple Crown 문서 일관성으로 정의한다.

### 도메인 순수성 게이트 (필수 차단 게이트)

```bash
# 1. 프로젝트명 하드코딩 0건
grep -rnEi 'oremi' plugins/orbit-base/                    # → 0건
# 2. 실제 도메인 예시(사용자 미리보기) 누출 0건 — 슬롯만 허용
grep -rnE '\[PAY-[0-9]|결제 리팩터링' plugins/orbit-base/   # → 0건
# 3. 컨벤션 토큰이 슬롯 형태인지
grep -rn 'GROUP-NAME' plugins/orbit-base/                 # → SKILL + 템플릿 2파일
```

### 매니페스트 검증 (회귀용 — 문서 변경이므로 무변경 확인)

```bash
# JSON 매니페스트는 이 플랜이 건드리지 않음 — 파싱 정합만 회귀 확인
python3 -c "import json,glob; [json.load(open(f)) for f in glob.glob('plugins/orbit-base/**/*.json',recursive=True)]"
```

### Triple Crown

| 프롱 | 이 플랜에서의 정의 | 판정 방법 |
|------|---------------------|-----------|
| **① 완성도** | E1·E2 두 표면에 컨벤션이 플랜대로 들어갔나. 누락된 컨벤션 요소(헤더 문법/ID 접두사/부모참조/수동라벨 계약) 없나. | 플랜 항목 대조: Task1·Task2 전 체크박스 완료 + 위 4요소가 SKILL.md에 모두 존재하는지 grep |
| **② 동작** | 문서 컨벤션이 **자기일관적**이고 **기존 생명주기 문구와 모순 없음**. (코드가 아니므로 런타임 대신 자기일관성으로 정의) | (a) SKILL ↔ 템플릿 문법 토큰 일치 grep. (b) No-Touch 표면 무변경 확인(아래). (c) 예시 roadmap을 컨벤션대로 작성→leader가 그룹을 인식·평평한 백로그로도 동작하는지 시범 점검 |
| **③ 품질** | 프롬프트 일관성: thin 철학 정합("ceremony 아님" 주장이 살아있나), 슬롯 무결성, "수동 라벨 ≠ 능동 추적" 계약이 옵션 2로 미끄러지지 않게 막는가. | architect 아키텍처 일관성 렌즈 리뷰 + superpowers requesting-code-review |

### No-Touch 회귀 검증 (옵션 1의 "blast radius 2" 주장 증명)

```bash
# 편집한 2파일 외에 정규 계약 표면이 변경되지 않았음을 증명
git diff --name-only HEAD~2 -- \
  plugins/orbit-base/CLAUDE.md \
  plugins/orbit-base/commands/ \
  plugins/orbit-base/agents/leader.md \
  plugins/orbit-base/skills/using-orbit/references/
# → 빈 출력이어야 옵션 1(정규 계약·생명주기·codex/gemini 무변경) 주장 성립

# 변경된 파일은 정확히 2개여야
git diff --name-only HEAD~2 -- plugins/orbit-base/ | sort
# → 정확히:
#   plugins/orbit-base/skills/using-orbit/SKILL.md
#   plugins/orbit-base/templates/roadmap.template.md
```

---

## 성공 기준 (측정 가능)

1. **편집 표면 정확성:** `git diff --name-only HEAD~2 -- plugins/orbit-base/`가 **정확히 2개 파일**(SKILL.md, roadmap.template.md)만 출력한다.
2. **컨벤션 완전성:** SKILL.md "Roadmap: Thin Ledger" 섹션에 4요소가 모두 존재 — `grep`으로 (a) `### [GROUP-NAME]` 헤더 문법, (b) `[PREFIX-N]` 접두사, (c) `↳ part of` 부모참조, (d) `manual label`/"수동 라벨" 계약 문구 각 1건 이상.
3. **자기일관성:** SKILL.md와 roadmap.template.md가 동일 토큰(`GROUP-NAME`, `PREFIX-N`)을 사용 — 두 파일 모두 grep 히트.
4. **도메인 순수성:** `grep -rnEi 'oremi' plugins/orbit-base/` = 0건, `grep -rnE '\[PAY-[0-9]|결제 리팩터링' plugins/orbit-base/` = 0건.
5. **정규 계약 무변경:** No-Touch 회귀 grep(CLAUDE.md·commands·leader.md·references)가 빈 diff. "no ceremony"·"Milestones: grouped delivery targets" 문구 보존.
6. **Triple Crown 3갈래 PASS** (① 완성도 / ② 자기일관성·무모순 / ③ 프롬프트 일관성).
7. **가역성 확인:** 두 커밋 revert 시 roadmap/SKILL이 변경 전 상태로 완전 복귀(롤백=문단 제거).

---

## 고위험 4트리거 재확인 (한 줄)

**옵션 1 = 저위험 확정.** T1 가역(문단 제거로 롤백) · T2 2표면·공개계약 무변경 · T3 보안 무관 · T4 외부 의존성 무 → **전부 no, critic 분기 생략 가능.** (옵션 2였다면 T1+T2 발화로 critic 필수였으나 비채택.)

---

## Self-Review

- **Spec 커버리지:** 코디네이터 요구 6항목 — ① 닿는 표면 확정(E1·E2 + No-Touch 표) ✅ ② 컨벤션 명세(헤더 문법·ID 접두사·부모자식·수동라벨 계약) ✅ ③ 도메인 무관성(전 예시 슬롯) ✅ ④ TDD/검증 전략(도메인 grep·매니페스트 회귀·Triple Crown·No-Touch 회귀) ✅ ⑤ 성공 기준 7개 측정 가능 ✅ ⑥ 고위험 4트리거 재확인 한 줄 ✅.
- **Placeholder 스캔:** 모든 step에 실제 명령·삽입 텍스트 포함. "적절히 처리" 류 없음.
- **타입 일관성:** Task1 정의 토큰(`[GROUP-NAME]`, `[PREFIX-N]`, "manual label")을 Task2가 동일하게 소비. Step 4 자기일관성 grep으로 강제.
