---
description: Guide a single work item through the orbit lifecycle (roadmap → plan → approval → build → verify)
argument-hint: "[task description or roadmap item ID]"
allowed-tools: [Read, Bash]
---

# /orbit-cycle — 작업 1건 생명주기 가이드

`.orbit/roadmap.md`에서 작업 1건을 선택해 완료까지 안내한다.

## 생명주기 개요

```
roadmap 선택
    │
    ▼
writing-plans  (플랜 작성)
    │
    ▼
Plan Approval  (사용자 승인)  ← 승인 없이 구현 금지
    │
    ▼
구현  (TDD: 실패 테스트 → 최소 구현 → 통과 → 리팩터)
    │
    ▼
사후 3갈래 검증
    ├── ① 완성도  (GSD — /gsd:verify)
    ├── ② 동작    (gstack — /gstack QA)
    └── ③ 품질    (code review — /review 또는 /code-review)
    │
    ▼
완료  (roadmap 체크박스 ✅, 백로그 이동)
```

---

## Step 1: roadmap에서 작업 선택

`.orbit/roadmap.md`를 열어 **현재 진행 중** 또는 **백로그**에서 작업 1건을 고른다.

```bash
cat "${CLAUDE_PROJECT_DIR}/.orbit/roadmap.md"
```

인자(`$ARGUMENTS`)가 있으면 해당 설명·ID에 맞는 항목을 우선 찾는다.

선택 기준:
- 의존성이 없거나 선행 작업이 완료된 것
- 가장 높은 우선순위 또는 현재 마일스톤에 속한 것

선택한 항목을 **현재 진행 중** 섹션으로 이동하고 작업을 사용자에게 확인받는다.

---

## Step 2: writing-plans (플랜 작성)

`superpowers:writing-plans` 스킬이 설치돼 있으면 사용한다:

```
/writing-plans
```

없으면 직접 플랜을 작성한다. 플랜은 다음을 포함해야 한다:
- **Goal**: 이 작업으로 달성할 상태
- **Success Criteria**: 완료 판정 기준 (측정 가능)
- **Tasks**: 체크박스 목록 (`- [ ] T1: ...`)
- **검증 방법**: 3갈래 검증 각각의 실행 명령

플랜 파일 위치 예시: `.orbit/plans/PLAN-<slug>.md`

---

## Step 3: Plan Approval (사용자 승인)

**구현을 시작하기 전에 반드시 사용자 승인을 받는다.**

플랜을 사용자에게 제시하고 명시적 승인을 요청한다:

> "위 플랜으로 진행할까요? 수정이 필요하면 알려주세요."

승인 없이 구현하지 않는다. 이 규칙은 예외 없이 적용된다.

---

## Step 4: 구현 (TDD)

`superpowers:test-driven-development` 패턴을 따른다:

1. **실패하는 테스트 작성** — 원하는 동작을 테스트로 먼저 기술한다.
2. **최소 구현** — 테스트가 통과하는 최소한의 코드를 작성한다.
3. **통과 확인** — 테스트를 실행해 green을 확인한다.
4. **리팩터** — 동작을 유지하면서 코드를 정리한다.

구현 중 막히면 `superpowers:systematic-debugging`을 참고한다.

완료 선언 전 `superpowers:verification-before-completion`을 실행한다:
- 검증 명령을 실제로 실행한다.
- 통과 증거를 확인한다.
- 추측으로 완료를 선언하지 않는다.

---

## Step 5: 사후 3갈래 검증

### ① 완성도 검증 (GSD)

`gsd` 플러그인이 있으면:
```
/gsd:verify
```

없으면 직접 확인:
- 플랜의 모든 Task 체크박스가 완료됐는가?
- Success Criteria 전 항목을 충족했는가?
- 빠진 엣지케이스·하위 요구사항이 없는가?

### ② 동작 검증 (gstack)

`gstack` 플러그인이 있으면:
```
/gstack
```

없으면 프로젝트의 `.orbit/quality-gate.sh`를 실행:
```bash
"${CLAUDE_PROJECT_DIR}/.orbit/quality-gate.sh"
```

### ③ 품질 검증 (code review)

`superpowers` 또는 `code-review` 플러그인이 있으면:
```
/review
```
또는:
```
/code-review
```

없으면 diff를 직접 검토해 명백한 버그·보안·가독성 문제를 확인한다.

---

## Step 6: 완료

3갈래 검증을 모두 통과하면:

1. `.orbit/roadmap.md`에서 해당 항목을 완료 처리한다:
   ```
   - [x] **<작업명>** — <완료일 YYYY-MM-DD>
   ```
2. **현재 진행 중** 섹션에서 **백로그 (완료)** 섹션으로 이동한다.
3. 완료 요약을 사용자에게 보고한다:
   - 구현 내용
   - 변경된 파일
   - 3갈래 검증 결과
   - 다음 추천 작업 (roadmap 기준)

---

## 동반 플러그인 없을 때 graceful 동작

| 플러그인 | 있을 때 | 없을 때 |
|----------|---------|---------|
| superpowers | /writing-plans, TDD 스킬, /review 사용 | 직접 플랜 작성, 수동 TDD, diff 직접 검토 |
| gsd | /gsd:verify 자동화 | 체크박스 수동 확인 |
| gstack | /gstack QA 자동화 | quality-gate.sh 수동 실행 |

플러그인 없이도 생명주기는 완전히 실행 가능하다. 플러그인은 자동화·편의성을 더한다.

---

## 유의사항

- **허브앤스포크**: 모든 에이전트 통신은 리드(팀장)를 경유한다. 에이전트 간 직접 통신 금지.
- **Plan Approval 없는 구현 금지**: 사용자 승인 전 코드를 수정하거나 생성하지 않는다.
- **작업 1건 원칙**: 동시에 여러 작업을 진행하지 않는다. 현재 작업을 완료한 후 다음으로 넘어간다.
- **검증 증거 확보**: 완료 선언 시 반드시 실행 결과(pass 로그)를 증거로 제시한다.
