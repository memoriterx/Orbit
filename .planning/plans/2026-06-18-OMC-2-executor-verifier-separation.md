# OMC-2 executor/verifier 분리 — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 배포물 `plugins/orbit-base/`에서 "구현자(executor=builder)"와 "독립 검증자(verifier)"의 권한 경계를 명확히 분리해, builder가 자기 산출물을 스스로 승인하는(self-approval) 구조적 위험을 제거한다.

**Architecture:** verifier 역할은 **신규 에이전트가 아니라 기존 `reviewer`**가 담당한다(아래 ADR-1 참조). 본 작업은 (1) `builder.md`의 자체 검증 절차를 "비권위적 pre-flight 체크"로 재정의해 승인 권한을 제거하고, (2) `reviewer.md`·`leader.md`·`using-orbit/SKILL.md`·`CLAUDE.md`에 "독립 검증 권한은 reviewer에게 있고 builder의 self-check는 승인이 아니다"는 권한 경계를 명시하는, **순수 프롬프트(마크다운) 정렬 작업**이다. 신규 파일·훅·매니페스트 변경은 없다.

**Tech Stack:** Markdown 에이전트 프롬프트 + YAML frontmatter, bash/grep (검증), Claude Code 에이전트 로딩.

## Global Constraints

- 도메인 순수성: `plugins/orbit-base/` 내 모든 파일에 특정 프로젝트명(oremi, Oremi, orbit-dev, memoriterx 등) 하드코딩 금지. 검증: `grep -rEi 'oremi|orbit-dev' plugins/orbit-base/` 0건.
- 모듈 경계: 배포물 `plugins/orbit-base/`만 수정. 개발팀 설정 `.claude/agents/`는 **참고 전용 — 수정 금지**.
- 매니페스트 정합성: `plugins/orbit-base/.claude-plugin/plugin.json`이 단일 일관성 기준. 본 작업은 이 파일을 변경하지 않는다(신규 에이전트 미추가 결정에 따름).
- 허브앤스포크 불변식: 모든 에이전트 통신은 leader 경유. builder↔reviewer 직접 통신 도입 금지.
- 커밋 접두사 `feat/fix/chore/docs/refactor:` 사용. **Co-Authored-By 줄 절대 금지.**
- frontmatter `model:` 별칭은 바 별칭(`haiku`/`sonnet`/`opus`) 사용(OMC-1 ADR-2 컨벤션). 본 작업은 어떤 `model:` 값도 변경하지 않는다.

---

## 사전 조사 결과 (실측 — roadmap 가정과의 차이)

roadmap OMC-2는 "orbit-base에 `verifier.md` 추가 + builder.md에서 자체 검증 절차 분리"를 가정한다. 실측 결과 이 가정의 **전반부(verifier.md 신규 추가)는 채택하지 않는다.** 근거는 ADR-1.

**실측 1 — 배포물 에이전트 5종 현황:**

| 파일 | name | model | 역할 요약 |
|------|------|-------|-----------|
| `leader.md` | leader | sonnet | 조율·게이트. 코드/플랜 미작성 |
| `architect.md` | architect | opus | 설계 + 사후 아키 일관성 렌즈 |
| `builder.md` | builder | sonnet | **구현 + 현재 "자체 검증 체크리스트" 보유** |
| `reviewer.md` | reviewer | opus | **사후 Triple Crown 3갈래 독립 검증 조율. 코드 미수정. 결과를 leader에 보고** |
| `researcher.md` | researcher | haiku | 외부 조사 |

**실측 2 — builder의 현재 "자체 검증" 기술 위치** (`plugins/orbit-base/agents/builder.md`):

- L31: Task Sequence 3단계 — `3. Run self-verification checklist`
- L49-53: `### Verification Before Completion` 섹션
- L55-61: `## Self-Verification Checklist (before reporting)` — typecheck/lint/tests, 요구사항 충족, 시크릿/절대경로, env, 스코프 체크박스 5종
- L70: 리포트의 `Next required action: [post-verification: completeness(GSD)/behavior(gstack)/quality(review)]`

**실측 3 — reviewer는 이미 독립 검증자다** (`plugins/orbit-base/agents/reviewer.md`):

- L7-9: "Verifies implementation quality **after the builder completes work**"
- L25, L29: "Do not modify code — all fixes delegated through the leader to the builder"
- L39-61: Triple Crown 3갈래(완성도/동작/품질) 전부 보유

→ **즉, executor(builder)와 verifier(reviewer)는 이미 별개 에이전트로 분리되어 있다.** 빠진 것은 *권한 경계의 명시적 선언*뿐이다. 현재 builder.md의 self-verification 체크리스트는 "통과해야 리포트한다"고만 적혀 있어, 마치 builder의 self-check가 승인 게이트인 것처럼 읽힐 여지가 있다. 이것이 self-approval 위험의 실체다.

**실측 4 — 역할 로스터가 4개 표면에 하드코딩됨** (신규 에이전트 추가 시 동기화 필요했을 지점, ADR-1 채택으로 변경 불필요):

- `CLAUDE.md:9` — `leader / architect / builder / reviewer / researcher (5 roles)`
- `skills/using-orbit/SKILL.md:12,17-21,57-63` — 스포크 목록, Triple Crown 표
- `skills/using-orbit/references/codex-tools.md:32` — 순차 역할 전환 목록
- `skills/using-orbit/references/gemini-tools.md:25-27` — Agent 매핑 표
- `.claude-plugin/plugin.json` — (로스터 미포함, description만)

---

### ADR-1 (핵심 결정): verifier는 신규 에이전트가 아니라 기존 reviewer다

**결정:** `verifier.md`를 신규 생성하지 **않는다.** verifier 책임은 기존 `reviewer` 에이전트에 귀속시키고, builder의 자체검증을 "비권위적 pre-flight"로 강등해 승인 권한을 reviewer로 일원화한다.

**핵심 아키텍처 질문에 대한 답:** *"verifier는 reviewer와 별개여야 하는가, 아니면 reviewer로 흡수하는 게 더 단순·정합적인가?"* → **reviewer로 흡수한다.**

**근거:**
1. **중복 제거(YAGNI).** OMC-2의 목표는 "구현자와 검증자의 분리"다. 그 분리는 이미 builder(구현) vs reviewer(검증)로 존재한다. reviewer는 별도 에이전트(opus), 코드 미수정, leader에 독립 보고 — self-approval을 구조적으로 차단하는 정의를 이미 충족한다. 별도 verifier를 추가하면 reviewer와 책임이 90% 겹친다.
2. **경계 모호화 회피.** verifier(1차 독립 검증)와 reviewer(Triple Crown 조율)를 둘 다 두면, 둘 다 "builder 산출물을 검증"하므로 leader가 매 작업마다 "이건 verifier냐 reviewer냐" 라우팅 판단을 해야 한다. 이는 허브앤스포크 라우팅 복잡도를 늘리고 책임 공백/중복을 만든다.
3. **단순성·수명.** 도메인 무관 배포물은 역할 수가 적을수록 채택·유지가 쉽다. 6번째 에이전트 추가는 매니페스트·SKILL·codex/gemini 레퍼런스 4표면을 모두 동기화해야 하는 비용을 발생시킨다(실측 4). 이득(self-approval 차단)은 reviewer 권한 명시만으로 동일하게 달성된다.
4. **OMC 원전 정합.** OMC의 executor/verifier 분리 핵심은 "구현 주체 ≠ 승인 주체"라는 권한 분리지, "에이전트 개수 +1"이 아니다. 권한 분리는 프롬프트 한 줄로 달성된다.

**기각된 대안 (verifier.md 신규):** builder→verifier(1차)→reviewer(Triple Crown) 2단 검증. 기각 사유 — verifier의 "1차 검증"과 reviewer Triple Crown ①완성도+③품질이 거의 동일. 2단계는 검증 깊이를 더하지 않고 라운드트립만 늘린다. 고위험 결정의 독립 비판은 별도 백로그 OMC-4(critic)가 담당하므로 여기서 선취하지 않는다.

**메모리 승격 대상:** 본 ADR("orbit의 executor/verifier 분리 = builder/reviewer 권한 경계이며 별도 verifier 에이전트를 두지 않는다")은 작업 완료 후 프로젝트 메모리(`orbit_omc_comparison.md` 또는 신규 결정 노트)로 승격한다.

### ADR-2: builder self-check = 비권위적 pre-flight (승인 게이트 아님)

builder의 self-verification은 제거하지 않고 **유지하되 의미를 재정의**한다. 제거하면 builder가 깨진 산출물을 그대로 넘겨 reviewer 왕복이 늘어 비효율적이다. 대신 "이 체크는 builder 자신의 사전 점검일 뿐 완료 승인이 아니다. 완료 판정 권한은 reviewer의 Triple Crown에 있다"를 명시한다. SubagentStop `quality-gate.sh` 훅(머신 게이트)과는 직교한다(아래 영향 분석).

---

## SubagentStop 품질 게이트 영향 분석

`hooks/quality-gate.sh`는 SubagentStop에서 `.orbit/quality-gate.sh`(있으면) 실행 → 실패 시 `{"decision":"block"}`. 이는 **builder/reviewer 무관하게 모든 서브에이전트 종료 시 동작하는 머신 게이트**다.

- 본 작업은 훅을 **변경하지 않는다.** 머신 게이트(자동 lint/test)와 휴먼/에이전트 검증 권한(reviewer)은 직교한다.
- 권한 경계 명시 후에도 게이트는 그대로 builder 종료 시 quality-gate.sh를 돌린다. 이는 self-approval 위험과 무관(머신 검사이지 builder의 자기 승인이 아님).
- 도메인 순수성 grep(`oremi` 등 0건)은 CLAUDE.md 규칙이며 본 작업이 새 위반을 만들지 않는지만 확인하면 된다(신규 텍스트에 프로젝트명 미포함).

---

## leader.md 워크플로우 변경 여부

생명주기 흐름 자체는 **불변**: `roadmap → architect(plan) → 승인 → builder(구현) → Triple Crown(reviewer 검증) → done`. ADR-1로 새 단계가 추가되지 않는다. 변경은 "검증 권한 명시" 한 줄 — builder는 self-approve하지 않으며 완료 판정은 reviewer Triple Crown이라는 점을 leader.md 완료 기준/Triple Crown 섹션에 못박는다.

---

## File Structure

- Modify: `plugins/orbit-base/agents/builder.md` — self-verification을 "pre-flight(비권위)"로 재정의, 리포트에 "검증 권한은 reviewer" 명시
- Modify: `plugins/orbit-base/agents/reviewer.md` — "독립 검증 권한 보유자(self-approval 차단자)" 역할을 Core Responsibilities/원칙에 명시
- Modify: `plugins/orbit-base/agents/leader.md` — 완료 기준에 "builder self-check ≠ 완료 승인; 완료 판정은 reviewer Triple Crown" 못박기
- Modify: `plugins/orbit-base/skills/using-orbit/SKILL.md` — Triple Crown 표/Delegation 절에 executor/verifier 권한 분리 1줄 추가
- Verify-only (수정 없음): `hooks/quality-gate.sh`, `.claude-plugin/plugin.json`, `CLAUDE.md`, `commands/orbit-cycle.md`, `references/*.md` (로스터 5종 유지 — 신규 에이전트 없음)

순수 프롬프트 정렬이며 4개 파일이 같은 단일 불변식("executor≠approver, approver=reviewer")을 표현한다. 표면별로 분리 가능한 독립 테스트 사이클을 가지므로 4 태스크로 분할한다.

---

## 검증 전략 (전체)

코드가 아닌 프롬프트 변경이므로 단위 테스트 대신 **grep 기반 텍스트 단언(assertion)** 과 **도메인 순수성/매니페스트 정합성 게이트**로 검증한다. 각 태스크는 다음을 만족해야 한다:

1. 의도한 문자열이 존재(positive assertion)
2. 제거 대상(승인 의미의 self-verification 표현)이 부재(negative assertion)
3. 도메인 순수성 위반 0건
4. 신규 파일·매니페스트·훅 변경 0 (이 작업 범위)

---

## Task 1: builder.md — self-verification을 비권위적 pre-flight로 재정의

**Files:**
- Modify: `plugins/orbit-base/agents/builder.md`

**Interfaces:**
- Consumes: 없음 (단독 프롬프트 편집)
- Produces: builder가 "검증 권한 없음, 완료 판정은 reviewer" 라는 불변식의 발신원. Task 2~4가 이 동일 문구와 정합해야 함. 합의 문구(verbatim, 네 파일 공통 사용):
  - `Builder self-checks are a non-authoritative pre-flight, not a completion gate. Completion authority belongs to the reviewer's Triple Crown.`

- [ ] **Step 1: 검증 단언 스크립트 작성 (실패 확인용 baseline)**

작성: `/tmp/omc2-verify.sh`

```bash
#!/bin/bash
# OMC-2 텍스트 단언 — 4 파일 공통 불변식 검증
set -u
BASE="/Users/dh/Project/orbit/plugins/orbit-base"
fail=0
PHRASE="non-authoritative pre-flight"
AUTH="Completion authority belongs to the reviewer"

check() { # file pattern label expect(present|absent)
  if grep -qF "$2" "$1"; then have=present; else have=absent; fi
  if [ "$have" != "$4" ]; then echo "FAIL [$3] $1: expected $4 got $have"; fail=1;
  else echo "ok   [$3] $1 ($4)"; fi
}

# Task1 builder
check "$BASE/agents/builder.md" "$PHRASE" T1-preflight present
check "$BASE/agents/builder.md" "$AUTH" T1-authority present
# Task2 reviewer
check "$BASE/agents/reviewer.md" "independent verification authority" T2-authority present
check "$BASE/agents/reviewer.md" "self-approval" T2-selfapproval present
# Task3 leader
check "$BASE/agents/leader.md" "$AUTH" T3-authority present
# Task4 skill
check "$BASE/skills/using-orbit/SKILL.md" "executor" T4-executor present

# Global: 도메인 순수성 + 신규 에이전트 미추가
if grep -rEiq 'oremi|orbit-dev' "$BASE"; then echo "FAIL purity: project name found"; fail=1; else echo "ok   purity (0 hits)"; fi
if [ -f "$BASE/agents/verifier.md" ]; then echo "FAIL no-new-agent: verifier.md exists"; fail=1; else echo "ok   no verifier.md"; fi
n=$(ls "$BASE/agents/"*.md | wc -l | tr -d ' '); [ "$n" = "5" ] && echo "ok   5 agent files" || { echo "FAIL agent count = $n (expected 5)"; fail=1; }

exit $fail
```

- [ ] **Step 2: 스크립트 실행해 실패 확인**

Run: `bash /tmp/omc2-verify.sh`
Expected: T1~T4 단언 다수 `FAIL` (아직 미편집), purity/no-new-agent/count는 `ok`. 종료코드 1.

- [ ] **Step 3: builder.md Task Sequence 3단계 재정의**

`builder.md`에서:

기존 (L30-32 부근):
```
2. Implement following the methodology below
3. Run self-verification checklist
4. Report results as text output to leader
```
변경 후:
```
2. Implement following the methodology below
3. Run the pre-flight self-check (non-authoritative — see below)
4. Report results as text output to leader for the reviewer's independent verification
```

- [ ] **Step 4: builder.md "Self-Verification Checklist" 섹션 제목·전문(前文) 재정의**

기존 (L55):
```
## Self-Verification Checklist (before reporting)
```
변경 후:
```
## Pre-Flight Self-Check (before reporting — non-authoritative)

Builder self-checks are a non-authoritative pre-flight, not a completion gate. Completion authority belongs to the reviewer's Triple Crown. The purpose here is to avoid handing the reviewer obviously-broken work, not to self-approve.
```
(체크박스 5종 L56-61은 그대로 유지.)

- [ ] **Step 5: builder.md 리포트 포맷의 Next action 문구 보강**

기존 (L70):
```
- Next required action: [post-verification: completeness(GSD)/behavior(gstack)/quality(review)] / [none]
```
변경 후:
```
- Next required action: independent verification by reviewer (Triple Crown: completeness(GSD)/behavior(gstack)/quality(review)). Builder does not self-approve completion.
```

- [ ] **Step 6: Task 1 단언 재실행 (T1 통과 확인)**

Run: `bash /tmp/omc2-verify.sh`
Expected: `ok [T1-preflight]`, `ok [T1-authority]`. T2~T4는 여전히 FAIL(다음 태스크). purity/no-new-agent/count `ok`.

- [ ] **Step 7: 커밋**

```bash
cd /Users/dh/Project/orbit
git add plugins/orbit-base/agents/builder.md
git commit -m "refactor(base): builder self-check를 비권위적 pre-flight로 강등 (OMC-2)"
```

---

## Task 2: reviewer.md — 독립 검증 권한 보유자(self-approval 차단자) 명시

**Files:**
- Modify: `plugins/orbit-base/agents/reviewer.md`

**Interfaces:**
- Consumes: Task 1의 불변식 문구 (builder가 self-approve하지 않는다는 전제)
- Produces: reviewer가 "유일한 완료 판정 권한자"임을 선언하는 문구. Task 3(leader)이 이를 참조.

- [ ] **Step 1: reviewer.md 도입부에 독립 검증 권한 문장 추가**

`reviewer.md` L9 (Core Responsibilities 직전, 도입 단락 끝)에 다음 단락을 추가:

```
The reviewer holds independent verification authority: the builder implements but does not self-approve its own output, so the reviewer's Triple Crown is the completion gate. This executor/verifier separation removes self-approval risk — the agent that builds is never the agent that approves.
```

- [ ] **Step 2: reviewer.md Working Principles에 self-approval 차단 원칙 추가**

`reviewer.md` Working Principles 목록(L22-25)의 끝에 다음 항목 추가:

```
- The reviewer is a distinct agent from the builder. Never rubber-stamp the builder's pre-flight self-check — re-verify independently. The builder's self-check carries no approval weight.
```

- [ ] **Step 3: Task 2 단언 재실행**

Run: `bash /tmp/omc2-verify.sh`
Expected: `ok [T2-authority]` (independent verification authority), `ok [T2-selfapproval]` (self-approval). T3~T4 FAIL. purity/no-new-agent/count `ok`.

- [ ] **Step 4: 커밋**

```bash
cd /Users/dh/Project/orbit
git add plugins/orbit-base/agents/reviewer.md
git commit -m "feat(base): reviewer를 독립 검증 권한 보유자로 명시 (OMC-2)"
```

---

## Task 3: leader.md — 완료 판정 권한을 reviewer Triple Crown에 못박기

**Files:**
- Modify: `plugins/orbit-base/agents/leader.md`

**Interfaces:**
- Consumes: Task 1·2의 불변식 (builder self-check ≠ 승인, reviewer = 권한자)
- Produces: leader 완료 기준에 동일 불변식 반영 — 추가 소비자 없음(말단)

- [ ] **Step 1: leader.md Completion Criteria에 권한 경계 명시**

`leader.md` `## Completion Criteria` 섹션(L82-88) 목록 뒤에 다음 단락을 추가:

```
**Authority note:** The builder's pre-flight self-check is not a completion signal. Completion authority belongs to the reviewer's Triple Crown. The leader treats a builder report as "ready for independent verification," never as "done." The builder is the executor; the reviewer is the verifier — the agent that builds never approves its own work.
```

- [ ] **Step 2: Task 3 단언 재실행**

Run: `bash /tmp/omc2-verify.sh`
Expected: `ok [T3-authority]`. T4 FAIL. purity/no-new-agent/count `ok`.

- [ ] **Step 3: 커밋**

```bash
cd /Users/dh/Project/orbit
git add plugins/orbit-base/agents/leader.md
git commit -m "feat(base): leader 완료 권한을 reviewer Triple Crown으로 명시 (OMC-2)"
```

---

## Task 4: using-orbit/SKILL.md — executor/verifier 권한 분리를 프레임워크 오리엔테이션에 반영

**Files:**
- Modify: `plugins/orbit-base/skills/using-orbit/SKILL.md`

**Interfaces:**
- Consumes: Task 1~3의 불변식
- Produces: 프레임워크 사용자 대상 오리엔테이션 텍스트 — 말단

- [ ] **Step 1: SKILL.md Triple Crown 절에 권한 분리 문장 추가**

`SKILL.md` Triple Crown 표(L57-63) 바로 뒤 단락(L63 "All three must pass..." 단락) 끝에 다음을 추가:

```
Executor/verifier separation: the builder is the executor and the reviewer is the verifier. The builder's pre-flight self-check is non-authoritative; only the reviewer's Triple Crown decides completion. The agent that builds never approves its own output.
```

- [ ] **Step 2: SKILL.md Quick Reference 표에 builder/reviewer 의미 보강**

`SKILL.md` Quick Reference 표(L107-115)의 builder/reviewer 행을 다음으로 교체:

기존:
```
| builder | Generic implementer (fill with domain-specific agent in presets) |
| reviewer | Triple Crown coordinator |
```
변경 후:
```
| builder | Executor — generic implementer; self-check is non-authoritative |
| reviewer | Verifier — Triple Crown coordinator; holds completion authority |
```

- [ ] **Step 3: Task 4 단언 재실행 (전체 통과)**

Run: `bash /tmp/omc2-verify.sh`
Expected: 모든 줄 `ok`. 종료코드 0.

- [ ] **Step 4: 도메인 순수성 + 매니페스트 정합성 최종 확인**

Run:
```bash
grep -rEi 'oremi|orbit-dev' /Users/dh/Project/orbit/plugins/orbit-base/ || echo "PURITY OK (0)"
git -C /Users/dh/Project/orbit status --porcelain plugins/orbit-base/.claude-plugin/plugin.json plugins/orbit-base/hooks/
```
Expected: `PURITY OK (0)`, plugin.json/hooks/ 변경 없음(빈 출력).

- [ ] **Step 5: 커밋**

```bash
cd /Users/dh/Project/orbit
git add plugins/orbit-base/skills/using-orbit/SKILL.md
git commit -m "docs(base): using-orbit에 executor/verifier 권한 분리 반영 (OMC-2)"
```

---

## 측정 가능한 성공 기준

1. `bash /tmp/omc2-verify.sh` 종료코드 0 (T1~T4 단언 전부 `ok`).
2. `plugins/orbit-base/agents/`에 **정확히 5개** `.md` 파일 (verifier.md 미존재 — ADR-1).
3. `grep -rEi 'oremi|orbit-dev' plugins/orbit-base/` → 0건.
4. `plugin.json`·`hooks/` diff 없음 (매니페스트·훅 불변).
5. builder.md에 "self-approve"/"completion gate"로서의 self-verification 표현 부재 — `grep -c "Self-Verification Checklist (before reporting)" builder.md` = 0.
6. 4개 파일이 동일 불변식("executor≠approver, approver=reviewer")을 일관되게 표현.

## Triple Crown 검증 매핑 (사후, reviewer 조율)

- **① 완성도(GSD):** Task 1~4 체크박스 + 위 성공기준 1~6 충족 확인.
- **② 동작:** 프롬프트 변경이므로 런타임 대신 `omc2-verify.sh` 실행 결과(종료코드 0)와 5개 에이전트 파일 frontmatter 유효성(`name`/`description`/`model` 보존) 확인. `head -5` 로 각 파일 frontmatter 손상 없음 확인.
- **③ 품질:** superpowers requesting-code-review로 4개 diff 검토 — 불변식 표현의 모순/중복/도메인 순수성 위반 여부. architect 아키 일관성 렌즈로 ADR-1 결정(신규 에이전트 미추가)이 매니페스트/로스터 4표면과 정합한지 확인.

---

## Self-Review (작성자 점검)

1. **스펙 커버리지:** 지시 항목 1(reviewer/verifier 경계 판단)→ADR-1. 항목 2(builder 자체검증 분리/제거)→Task 1. 항목 3(verifier frontmatter)→ADR-1으로 불요(reviewer 재사용). 항목 4(leader 워크플로우 변경)→Task 3 + 워크플로우 분석 절. 항목 5(도메인 순수성/SubagentStop)→Global Constraints + 영향 분석 절. 항목 6(테스트/성공기준)→검증 전략 + 성공 기준 절. 핵심 질문(별개 vs 흡수)→ADR-1에서 "흡수" 결정 + 근거 4개. 누락 없음.
2. **플레이스홀더 스캔:** 모든 편집 단계가 verbatim 문자열 포함. TBD/TODO 없음.
3. **타입/문구 일관성:** 합의 문구 "non-authoritative pre-flight" / "Completion authority belongs to the reviewer" 가 Task 1(발신)·3·4에서 동일 사용. reviewer는 "independent verification authority". omc2-verify.sh 단언이 이 문자열들을 그대로 검사.
