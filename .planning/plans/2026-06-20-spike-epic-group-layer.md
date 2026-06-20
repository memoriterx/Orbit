# Spike: Epic / Task-Group 중간 계층 도입 비교 설계

> **이것은 구현 플랜이 아니다.** 옵션 비교 스파이크다. 한 안을 강행하지 않는다 — 트레이드오프를 펼치고, 추천안 1개와 그 반대 관점을 함께 제시한다. 실제 구현은 추천안 채택 후 별도 `writing-plans` 산출물로 이어진다.

**작성:** architect · 2026-06-20
**Roadmap 항목:** `[GROUP-1] Epic/task-그룹 중간 계층 비교 설계 스파이크`
**산출 경로:** `.planning/plans/2026-06-20-spike-epic-group-layer.md`

---

## 1. 풀어야 할 질문

> "큰 기능을 여러 task로 쪼개 한 묶음(Epic)으로 추적"하는 수요를, orbit이 **thin roadmap 철학**을 깨지 않고 어떻게(또는 도입하지 않고) 충족할 것인가?

### 배경 (researcher 조사 + orbit 현황)

- orbit 현재 모델: `roadmap task 1건 → 단일작업 생명주기 → milestone 라벨`. **2계층.**
- orbit의 milestone은 **능동 관리자가 아니라 수동 라벨/시점 마커** — "끝난 task를 묶는 사후 마커"(PMI 표준 부합). 진행 중 task를 능동 추적하지 않는다.
- 산업 표준 작업 구동 단위 = task/ticket (모델 B). **orbit과 일치 — 표준 부합.**
- 현대 지배 모델은 **하이브리드 3계층**: `[Task/Issue 흐름] + [Epic/Project 상위 컨테이너 = 여러 task를 묶어 능동 추적] + [Milestone 라벨/마커]`.
- GitHub sub-issues, Jira Epic이 이 "중간 묶음" 계층을 제공. **orbit엔 이 중간 계층이 없다.**
- 소팀·스타트업 추세: 무거운 계층 회피 → 티켓 흐름 + 가벼운 라벨.

### 핵심 긴장

orbit의 차별점은 **thin roadmap("no ceremony")** 이다. Epic은 본질적으로 ceremony(롤업 추적·진행률·부모-자식 계약)를 추가한다. 따라서 이 스파이크의 진짜 질문은 "Epic이 좋은가"가 아니라 **"중간 묶음 수요가 thin 철학을 깨뜨릴 만큼 강한가, 아니면 컨벤션으로 충분한가"** 이다.

---

## 2. 닿는 표면 인벤토리 (blast-radius 기준선)

옵션 평가의 객관적 분모. orbit-base에서 roadmap/milestone/thin 개념을 언급하는 **모든 표면**을 실측 grep으로 확정했다.

| # | 표면 | 현재 내용 | 비고 |
|---|------|-----------|------|
| S1 | `skills/using-orbit/SKILL.md:102-110` | "Roadmap: Thin Ledger" 섹션 (Backlog/Current/Milestones/Completeness) | 정규 정의처 |
| S2 | `skills/using-orbit/SKILL.md:134` | Quick Reference 표 `Thin Ledger \| Minimal roadmap — no ceremony` | 한 줄 |
| S3 | `CLAUDE.md:38` | "Keep the roadmap thin: backlog, current task, milestones, completeness criteria" | Context Mgmt |
| S4 | `CLAUDE.md:88` | "Memory vs. Roadmap" — `Roadmap = backlog, milestones, current pointer` | 정규 계약 |
| S5 | `templates/roadmap.template.md` | 실제 roadmap 구조 (현재 진행 중 / 마일스톤 / 백로그 / 완료 / 완성도 기준) | end-user가 보는 스키마 |
| S6 | `skills/using-orbit/references/codex-tools.md:64` | `roadmap.md — thin task ledger` | codex 환경 |
| S7 | `skills/using-orbit/references/gemini-tools.md:54` | `roadmap.md — thin task ledger` | gemini 환경 |
| S8 | `commands/orbit-cycle.md` Step 1·6 | roadmap 선택·체크박스 라이프사이클 | 생명주기 진입/종료 |
| S9 | `agents/leader.md` (배포물) | roadmap 선택·체크박스가 leader 직접 행동 | 생명주기 계약 |

**기준선 표면 수: 9.** 이 중 정규 계약은 S1·S4·S5 (정의처). 나머지는 동기화 종속.

> 주의: `.claude/`(dev팀)와 `.planning/`(dev팀 상태)은 배포물이 아니다. 위 표는 **배포물 `plugins/orbit-base/` 한정**. dev팀 자신의 roadmap 운용은 별개이며, 도메인 무관성 규칙의 대상이 아니다.

---

## 3. 비교 옵션 (4안)

### 옵션 0 — 현상유지 (Do Nothing)

중간 계층 없음. 큰 기능은 **roadmap 백로그 섹션 헤더 + milestone 라벨**로 느슨히 처리. 신규 구조물·스키마·계약 0.

**구체적 형태** (현행 그대로 — `templates/roadmap.template.md` 무변경):

```markdown
## 백로그

### OMC 흡수 — orbit-base 개선 4건      ← 섹션 헤더가 사실상의 비공식 묶음
- [x] [OMC-1] 역할별 모델 티어 명시 ...
- [x] [OMC-2] executor/verifier 분리 ...

## 마일스톤
| M2 — OMC 흡수 | 4건 백로그 완료 + 품질 게이트 통과 | 완료 |   ← 사후 라벨
```

> 실제 dev팀 roadmap이 이미 이렇게 운용 중(`### OMC 흡수` 헤더 + `M2` 마일스톤). 즉 옵션 0은 **이미 부분적으로 존재하는 자생 패턴**이다.

**한계 (명시):**
- 섹션 헤더는 **비정형** — 진행률 롤업 없음, 부모-자식 명시 참조 없음, ID 체계 없음.
- "이 Epic이 몇 % 끝났나"를 사람이 눈으로 세야 함.
- 큰 기능의 task들이 백로그에서 흩어지면 묶음 응집이 깨짐(헤더 아래 모여 있어야만 유지).
- milestone은 사후 라벨이라 **진행 중** 큰 기능을 추적하지 못함 (애초에 그 용도가 아님).

---

### 옵션 1 — 경량 묶음 (순수 컨벤션)

신규 구조물·스키마·훅 **0**. `roadmap.md` 내부 **컨벤션만**으로 task 그룹을 표현. 정규화는 하되 강제(코드/훅)는 하지 않음.

**컨벤션 3요소:**
1. **그룹 ID 접두사**: task ID에 `[GROUP-N]` 접두사 (이미 dev팀이 `[GROUP-1]`, `[OMC-1]`로 자생적으로 사용 중).
2. **그룹 헤더 줄**: 백로그 내 `#### [GROUP-N] <그룹명> — <한 줄 의도>` 헤더로 응집.
3. **부모 참조 줄** (선택): 개별 task가 헤더에서 떨어져도 `↳ part of [GROUP-N]` 한 줄로 역참조.

**구체적 형태** (`templates/roadmap.template.md`에 *주석으로* 컨벤션 예시 추가 — 구조 강제 아님):

```markdown
## 백로그

<!-- (선택) 큰 기능은 그룹 헤더로 묶어 응집을 표현할 수 있다. 구조 강제 아님 — 순수 컨벤션. -->

#### [GROUP-1] <큰 기능명> — <한 줄 의도>
- [ ] **[GROUP-1] <하위 작업 A>** — <설명>
- [ ] **[GROUP-1] <하위 작업 B>** — <설명>
- [x] **[GROUP-1] <하위 작업 C>** — <완료일>

<!-- 헤더에서 떨어진 task는 역참조 한 줄로 그룹 소속을 표시할 수 있다. -->
- [ ] **<작업명>** — <설명>  ↳ part of [GROUP-1]
```

**SKILL.md 변경 (S1)** — Thin Ledger 섹션에 **한 문단 추가**:

```markdown
### (선택) 큰 기능 묶기 — 경량 컨벤션
여러 task에 걸친 큰 기능은 `[GROUP-N]` ID 접두사와 그룹 헤더로 응집을 표현한다.
이는 순수 컨벤션이다 — 신규 구조·진행률 롤업·생명주기 변경 없음. 묶음은 여전히
task 단위로 plan→approve→build→verify를 거치고, 완료 시점에 milestone 라벨로
사후 마킹된다. Epic을 능동 추적 단위로 승격시키지 않는다 (그건 옵션 2).
```

**닿는 표면:** S1 (한 문단), S5 (주석 예시). **2개.** 정규 계약(S4 Memory-vs-Roadmap) 무변경 — milestone 의미론 유지, 생명주기 무변경.

**한계:**
- 컨벤션은 강제되지 않음 → 일관성은 사용자/leader 규율에 의존.
- 진행률 롤업은 여전히 사람이 눈으로(단, 그룹 헤더 아래 모여 있으면 `- [x]` 카운트가 쉬움).
- "능동 추적"을 원하는 팀에겐 부족 (의도적 — 그 수요는 옵션 2).

---

### 옵션 2 — 1급 Epic 계층 (First-Class)

roadmap에 Epic을 **능동적 진행 추적 단위**로 정식 도입. 하위 task 진행률·완료 롤업이 정규 계약이 됨.

**구체적 형태** (`templates/roadmap.template.md`에 신규 정규 섹션):

```markdown
## Epics (진행 중 큰 기능 — 능동 추적)

### [EPIC-1] <큰 기능명>
- **상태:** 진행 중 (3/5 완료, 60%)
- **의도:** <왜 이 Epic이 존재하는가>
- **완료 기준:** <Epic 단위 done 정의>
- **하위 task:**
  - [x] [EPIC-1.1] <task> — <완료일>
  - [x] [EPIC-1.2] <task> — <완료일>
  - [x] [EPIC-1.3] <task> — <완료일>
  - [ ] [EPIC-1.4] <task>
  - [ ] [EPIC-1.5] <task>

## 마일스톤   ← 여전히 사후 라벨 (Epic과 별개)
```

**필수 동반 변경:**
- **S1 (SKILL.md Thin Ledger)**: "Backlog/Current/Milestones/Completeness" → "+ Epics(능동 추적)". Thin Ledger 정의를 3계층으로 재서술. "no ceremony" 주장과 직접 충돌 → 문구 재협상 필요.
- **S2**: Quick Reference에 `Epic` 행 신규.
- **S4 (CLAUDE.md Memory vs Roadmap)**: "Roadmap = backlog, milestones, current pointer" → "+ epics(진행률 롤업)". **정규 계약 변경.**
- **S3**: Context Mgmt "keep roadmap thin" 문구 — Epic 롤업이 thin과 충돌하므로 단서 추가.
- **S5**: 템플릿에 Epics 섹션 + 롤업 표기법.
- **S6·S7 (codex/gemini)**: `roadmap.md — thin task ledger` → Epic 계층 반영.
- **S8 (orbit-cycle)**: 생명주기에 "task 선택 시 부모 Epic 진행률 갱신" 단계가 끼어들 수 있음 — Step 1·6 변경.
- **S9 (leader.md)**: leader 직접 행동에 "Epic 진행률 롤업 갱신"이 추가될지 결정 필요(누가 롤업을 유지하나?).

**닿는 표면:** S1–S9 **최대 9개 전부** (현실적으로 핵심 6+). 정규 계약 2개(S1·S4) 변경.

**한계:**
- thin 철학과 정면 충돌 — orbit의 차별점을 약화.
- 롤업 유지 책임자 불명확 (leader? builder? 자동?) → 새 계약 표면.
- 진행률 % 는 누가 갱신해도 drift 위험 (수동) 또는 신규 자동화 필요(훅 — blast radius 폭증).

---

### 옵션 3 — 위임형 (GSD/외부 도구에 Epic 위임)

orbit은 중간 계층을 **자체 도입하지 않고**, Epic 추적을 동반 플러그인(GSD의 milestone/phase, 또는 GitHub sub-issues)에 위임. orbit roadmap은 thin 유지, 큰 기능 추적은 "있으면 쓰고 없으면 옵션 1로 graceful degrade".

**구체적 형태** (SKILL.md Graceful Degradation 표 + Thin Ledger에 한 줄):

```markdown
### (선택) 큰 기능 능동 추적 — 외부 위임
여러 task에 걸친 큰 기능의 능동적 진행률 추적이 필요하면, orbit roadmap 자체를
무겁게 만들지 않고 동반 도구에 위임한다:
- GSD 설치 시: GSD의 milestone/phase 추적 워크플로 사용.
- GitHub 워크플로 팀: sub-issues / Projects.
- 도구 없을 때: 옵션 1 경량 컨벤션으로 degrade.
orbit roadmap은 thin task ledger를 유지한다 — Epic 상태의 정본(source of truth)이 아니다.
```

**닿는 표면:** S1 (한 문단), Graceful Degradation 표 (SKILL.md:112-123 내). **2개.** 정규 계약 무변경.

**한계:**
- **end-user 도구 선택 침범 위험** — "GSD 쓰라"는 권유가 orbit의 중립성을 흐림. (완화: "있으면 쓰고 없으면 degrade"로 강제 아닌 옵션 제시.)
- GSD/GitHub 안 쓰는 팀에겐 사실상 옵션 1과 동일 → 옵션 1의 상위집합에 가까움.
- 두 도구 간 roadmap 동기화 책임이 사용자에게 — 정본 분산(roadmap의 task vs GSD의 phase).

---

## 4. 비교 표 (6축)

| 축 | 옵션 0 현상유지 | 옵션 1 경량 컨벤션 | 옵션 2 1급 Epic | 옵션 3 외부 위임 |
|----|----------------|-------------------|-----------------|------------------|
| **1. thin 철학 정합** | ◎ 완전 정합 (구조물 0) | ○ 정합 (컨벤션은 ceremony 아님, "선택" 명시) | ✕ **정면 충돌** ("no ceremony" 재협상) | ○ 정합 (roadmap thin 유지, 무게는 외부로) |
| **2. blast radius (표면 수)** | ◎ **0** | ○ **2** (S1 문단, S5 주석) | ✕ **6~9** (정규 계약 S1·S4 포함) | ○ **2** (S1 문단, degrade 표) |
| **3. 도메인 무관성** | ◎ 영향 없음 | ◎ `[GROUP-N]`는 도메인 무관, 슬롯 불요 | △ Epic 예시가 도메인색 띄기 쉬움 — `<큰 기능명>` 슬롯 엄수 필요 | ◎ 위임 대상만 언급, 도메인 무관 |
| **4. 생명주기 상호작용** | ◎ 무변경 | ◎ 무변경 (task 단위 lifecycle 그대로) | ✕ Step 1·6에 롤업 갱신 끼어듦, 롤업 책임자 신설 | ◎ 무변경 (외부 도구가 별도 추적) |
| **5. end-user 도구 선택 침범** | ◎ 없음 | ◎ 없음 (순수 텍스트 컨벤션) | ◎ 없음 (orbit 내재, 도구 불요) | △ **GSD/GitHub 권유** — "있으면" 단서로 완화 가능 |
| **6. 가역성 / 도입·유지 비용** | ◎ 비용 0 / 빼기 불요 | ◎ 도입 저, **가역 (문단·주석 제거로 롤백)** | ✕ 도입 고, 정규 계약·롤업 데이터 생기면 **빼기 어려움** | ○ 도입 저, 가역 (한 문단 제거) |

범례: ◎ 매우 좋음 · ○ 좋음 · △ 주의 · ✕ 나쁨/충돌

---

## 5. 고위험 4트리거 자가진단

각 옵션이 leader 고위험 게이트(critic 분기)를 발화시키는가? (T1 비가역성 / T2 광범위 영향 = 3+ 표면·공개계약 / T3 보안 / T4 외부 의존성)

| 옵션 | T1 비가역성 | T2 광범위 영향 (3+ 표면/공개계약) | T3 보안·무결성 | T4 외부 의존성 | **종합** |
|------|-------------|----------------------------------|----------------|----------------|----------|
| 0 현상유지 | no | no (0 표면) | no | no | **저위험** — critic 생략 |
| 1 경량 컨벤션 | no (가역) | no (2 표면, 공개계약 무변경) | no | no | **저위험** — critic 생략 |
| 2 1급 Epic | **YES** (정규 계약 생성→하위 호환 깨짐) | **YES** (6~9 표면 + S1·S4 공개계약 변경) | no | no | **고위험** — critic 필수 |
| 3 외부 위임 | no (가역) | no (2 표면) | no | △ (외부 도구 *권유*지 신규 *런타임* 의존성은 아님 — 경계선) | **저위험** (T4 경계선 — critic 게이트에서 판정 권고) |

**해석:**
- **옵션 0·1·3 은 저위험** → leader 4트리거 OR 게이트에서 critic 분기 생략 가능. (옵션 3은 T4 경계선이므로 leader가 "권유 vs 의존성"을 명시적으로 판정해야 함.)
- **옵션 2 만 고위험** (T1+T2 동시 발화) → 채택 시 **critic 게이트 필수**. orbit 선례(OMC-6 planner 분리, opt-in 자율모드)와 동일 패턴: 정규 계약을 건드리는 변경은 critic을 거쳐야 한다.

---

## 6. architect 추천안

### 추천: **옵션 1 (경량 묶음 — 순수 컨벤션)**, 옵션 3을 흡수한 형태로.

**근거:**

1. **수요를 thin 철학을 깨지 않고 충족한다.** 풀어야 할 질문의 핵심 제약("thin을 깨지 않고")을 만족하는 유일한 *능동적* 응답이다. 옵션 0은 수요를 사실상 방치하고, 옵션 2는 thin을 깬다.

2. **수요가 이미 자생적으로 존재함을 실측 확인.** dev팀 roadmap이 이미 `[OMC-1]`·`[GROUP-1]` ID 접두사와 `### OMC 흡수` 섹션 헤더를 쓰고 있다 — 즉 옵션 1은 **새 패턴 발명이 아니라 자생 패턴의 정규화**다. 정규화의 위험이 가장 낮다.

3. **가역성·blast radius가 최소.** 2 표면(문단 1개 + 주석 1개), 정규 계약 무변경, 저위험(critic 생략 가능). 나중에 "역시 불필요"로 판명되면 문단 제거로 무손실 롤백.

4. **옵션 3의 좋은 부분을 흡수 가능.** 옵션 1의 SKILL 문단에 "더 강한 능동 추적이 필요하면 동반 도구(GSD/GitHub)에 위임, orbit roadmap은 thin 유지"라는 **한 줄 graceful 안내**를 덧붙이면 옵션 3의 가치(외부 위임 경로)를 도구 침범 없이 포섭한다. → 옵션 1 + 옵션 3의 한 줄 = 비용 거의 동일, 커버리지 상위집합.

5. **생명주기·허브앤스포크 불변.** Epic이 생명주기를 바꾸지 않는다(옵션 2의 가장 큰 risk). task 단위 plan→approve→build→verify가 그대로다. 묶음은 순전히 *표기*이지 *프로세스*가 아니다.

### 반대 관점 (왜 추천하지 않을 수도 있는가)

정직하게 펼친다:

- **(A) 옵션 1이 옵션 0보다 정말 나은가?** 컨벤션은 강제되지 않는다. dev팀이 이미 헤더+ID를 쓰고 있다면, SKILL에 한 문단 박는 것의 *순(net) 가치*는 "문서화된 권장" 정도다. 만약 사용자가 "굳이 정규화할 필요 없다, 자생 패턴으로 충분"이라 본다면 **옵션 0이 옳다**. 옵션 1의 ROI가 "한 문단의 명료성"에 그칠 수 있다는 점은 정직한 약점이다.

- **(B) 수요의 실재성이 미검증.** researcher는 *산업 표준*을 조사했지, *orbit end-user가 실제로 Epic 추적을 요청했다*는 증거는 없다. OMC-6(planner 분리)가 "전제가 실측 아닌 표준 맞추기"라는 이유로 보류된 선례가 정확히 여기 적용된다. **"산업이 3계층이니까"는 orbit이 3계층이어야 할 이유가 아니다.** 이 약점이 크다고 보면, 추천은 옵션 1이 아니라 **옵션 0(현상유지) + 수요 실관측 시 재검토**로 후퇴해야 한다.

- **(C) 컨벤션의 일관성 위험.** 강제되지 않는 컨벤션은 시간이 지나며 drift한다(어떤 task는 `[GROUP-N]`, 어떤 건 안 붙임). 강제하려면 훅이 필요한데, 그 순간 옵션 1의 "blast radius 2"가 무너지고 옵션 2 쪽으로 미끄러진다.

### 추천의 조건부 성격

따라서 추천은 **무조건적이지 않다**:
- 사용자가 "중간 묶음 수요가 실재하고 자생 패턴을 문서로 못박고 싶다" → **옵션 1 (+ 옵션 3 한 줄)**.
- 사용자가 "수요 미검증, 자생 패턴으로 충분" → **옵션 0**, OMC-6식 보류 (재검토 조건: dogfooding/end-user에서 Epic 추적 수요 실관측 시).
- **옵션 2는 비추천** — 현 시점 thin 철학 비용 대비 정당화 근거(실측 수요) 부재. 채택하려면 반드시 critic 게이트를 거쳐야 하며, 통과 가능성은 OMC-6 보류 선례상 낮다.

---

## 7. 닿는 표면 목록 + 검증 전략 (추천안 = 옵션 1 기준)

추천안 채택 시 후속 구현 플랜이 다룰 표면과 검증 방법. (스파이크 단계에선 *목록*만 — 구현은 별도.)

### 7.1 닿는 표면 (옵션 1 + 옵션 3 한 줄)

| 표면 | 변경 | 도메인 무관성 |
|------|------|---------------|
| S1 `skills/using-orbit/SKILL.md` Thin Ledger | "(선택) 큰 기능 묶기" 문단 1개 추가 + 외부 위임 한 줄 | `[GROUP-N]`·`<큰 기능명>` 슬롯, 도메인색 0 |
| S5 `templates/roadmap.template.md` | 백로그 섹션에 그룹 헤더 컨벤션 *주석* 예시 추가 | `<큰 기능명>`·`<설명>` 슬롯 유지 |

정규 계약(S4 Memory-vs-Roadmap)·생명주기(S8)·leader(S9)·codex/gemini(S6·S7)·Quick Ref(S2)·Context Mgmt(S3) **무변경** — milestone 의미론·thin 정의·생명주기를 건드리지 않기 때문.

### 7.2 검증 전략

1. **도메인 순수성 grep** (배포물 필수 게이트):
   ```bash
   grep -rEi 'oremi|orbit-dev|<실제 프로젝트명>' plugins/orbit-base/   # 0건이어야 함
   grep -rn 'GROUP-1\]' plugins/orbit-base/   # 예시는 GROUP-N 슬롯 형태여야, 실제 ID 하드코딩 금지
   ```
   추가된 예시가 슬롯(`[GROUP-N]`, `<큰 기능명>`)을 쓰고 특정 프로젝트 task ID를 하드코딩하지 않는지 확인.

2. **매니페스트/스키마 정합:**
   ```bash
   python3 -c "import json,glob; [json.load(open(f)) for f in glob.glob('plugins/orbit-base/**/*.json',recursive=True)]"
   ```
   옵션 1은 JSON 매니페스트를 건드리지 않으므로 이 게이트는 회귀 검증용(무변경 확인).

3. **계약 무변경 회귀 grep** (옵션 1의 핵심 안전 주장 검증):
   ```bash
   # milestone 의미론·thin 정의·생명주기 문구가 그대로인지 — diff가 S4/S8/S9를 건드리지 않았음을 증명
   git diff --name-only -- plugins/orbit-base/CLAUDE.md plugins/orbit-base/commands/ plugins/orbit-base/agents/leader.md
   # → 빈 출력이어야 옵션 1 (S4·S8·S9 무변경) 주장이 성립
   ```

4. **Triple Crown** (구현 시):
   - ① 완성도: 추가 문단·주석이 플랜대로 들어갔나.
   - ② 동작: 문서 변경이므로 "예시 roadmap을 컨벤션대로 작성→leader가 그룹 인식" 시범 dispatch로 동작 확인.
   - ③ 품질: thin 철학 정합·슬롯 무결성 리뷰 (architect 아키텍처 일관성 렌즈).

---

## 8. 요약 (리드 보고용)

- **질문:** Epic 중간 계층을 thin 철학 안 깨고 충족하는 법.
- **4안 비교 완료** (0 현상유지 / 1 경량 컨벤션 / 2 1급 Epic / 3 외부 위임).
- **추천: 옵션 1 (경량 컨벤션) + 옵션 3 한 줄 흡수** — blast radius 2 표면, 정규 계약·생명주기 무변경, 저위험(critic 생략 가능), 가역.
- **단, 조건부 추천.** 강력한 반대 관점 존재: ① 옵션 1의 순가치가 옵션 0 대비 "한 문단"에 그칠 수 있음 ② **수요 실재성 미검증 — OMC-6 보류 선례 직접 적용** → 사용자가 수요 미검증으로 보면 **옵션 0 + 보류**가 옳다.
- **옵션 2 비추천** — 유일한 고위험 안(T1+T2 발화), thin 정면 충돌, 실측 수요 부재. 채택 시 critic 게이트 필수.
- **고위험 자가진단:** 옵션 0·1·3 저위험(critic 생략) / 옵션 2 고위험(critic 필수). 옵션 3은 T4 경계선 — leader가 "권유 vs 의존성" 판정 권고.

**다음 단계 (리드 판단):** 사용자에게 옵션 1 vs 옵션 0(보류) 선택을 제시. 옵션 1 채택 시 별도 구현 `writing-plans` 산출. 옵션 2 채택 시 반드시 critic 게이트 선행.
