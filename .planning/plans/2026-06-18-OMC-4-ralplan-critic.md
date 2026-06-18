# OMC-4 ralplan식 3자 비판 계획 (critic 에이전트) — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 배포물 `plugins/orbit-base/`에 `critic.md` 에이전트(6번째 역할)를 추가하고, **고위험 아키텍처 결정**에 한해 critic이 architect의 플랜을 독립 비판하는 ralplan식 분기(architect 플랜 → critic 비판 → architect 수정 → Plan Approval)를 생명주기에 삽입한다. 저위험 작업에는 이 분기가 끼지 않는다.

**Architecture:** critic은 architect·reviewer와 중복되지 않는 **고유 역할**이다(아래 ADR-1). architect는 플랜을 *작성*하고, reviewer는 *구현물*을 플랜 기준으로 검증한다. critic은 그 사이 공백 — *플랜 자체*를 코드 작성 전에 독립 비판한다(self-approval 차단의 설계 단계 버전). 이 비판은 비용이 있으므로 **고위험 트리거가 켜질 때만** 발동한다(ADR-2: 측정 가능한 트리거, leader가 판정). 본 작업은 (1) `critic.md` 신규 생성, (2) leader.md·using-orbit SKILL·CLAUDE.md·plugin.json description·codex/gemini 레퍼런스의 역할 로스터·생명주기 동기화로 구성된 **순수 마크다운+JSON 정렬 작업**이다. 신규 훅은 없다(ADR-3, OMC-3 graceful degradation 정합).

**Tech Stack:** Markdown 에이전트 프롬프트 + YAML frontmatter, JSON 매니페스트(plugin.json), bash/grep(검증), Claude Code 에이전트 네이티브 디스커버리.

## Global Constraints

- **도메인 순수성:** `plugins/orbit-base/` 내 모든 신규·수정 텍스트에 특정 프로젝트명(`oremi`, `Oremi`, `orbit-dev`, `memoriterx` 등) 하드코딩 금지. 도메인 값은 슬롯(`{{...}}`)으로. 검증: `grep -rEi 'oremi|orbit-dev' plugins/orbit-base/` 0건.
- **모듈 경계:** 배포물 `plugins/orbit-base/`만 수정. 개발팀 설정 `.claude/`는 **참고 전용 — 수정 금지**.
- **매니페스트 정합성:** `plugins/orbit-base/.claude-plugin/plugin.json`이 단일 일관성 기준. 본 작업은 description의 역할 수만 갱신한다(아래 Task 4 — 에이전트 등록은 디렉터리 네이티브 디스커버리이므로 별도 배열 등록 불필요, ADR-4).
- **허브앤스포크 불변식:** 모든 에이전트 통신은 leader 경유. **critic↔architect 직접 통신 도입 금지.** 비판은 leader가 architect 플랜을 critic에 전달 → critic 리포트를 leader가 수령 → leader가 architect에 환류.
- **frontmatter `model:` 별칭:** 바 별칭(`haiku`/`sonnet`/`opus`)만 사용(OMC-1 ADR-2 컨벤션). critic은 `opus`(비판적 추론 — ADR-5).
- **커밋 접두사** `feat/fix/chore/docs/refactor:` 사용. **Co-Authored-By 줄 절대 금지.**
- **graceful degradation:** 신규 훅 0건. critic 분기는 프롬프트(생명주기 규율)로만 표현 — 자동화 없이 Claude/Codex/Gemini 전 환경에서 동일하게 동작(OMC-3 ADR-3 정합).

---

## 사전 조사 결과 (실측)

**실측 1 — 배포물 에이전트 5종 현황** (`plugins/orbit-base/agents/`):

| 파일 | name | model | 역할 요약 | 생명주기 위치 |
|------|------|-------|-----------|---------------|
| `leader.md` | leader | sonnet | 조율·게이트·라우팅 | 전(全) 단계 hub |
| `architect.md` | architect | opus | 설계·플랜 **작성** + 사후 아키 일관성 렌즈 | 1.Plan, 4.Verify③(렌즈) |
| `builder.md` | builder | sonnet | 구현(TDD) | 3.Build |
| `reviewer.md` | reviewer | opus | 사후 Triple Crown 3갈래 독립 검증 | 4.Verify |
| `researcher.md` | researcher | haiku | 외부 조사 | 임의 |

→ critic 추가 시 **6종**. 빈 슬롯: "플랜이 *작성된 직후, 구현 전*에 그 플랜을 *작성자가 아닌* 독립 시각으로 비판" — 현재 어느 역할도 이 위치를 점유하지 않는다.

**실측 2 — 역할 로스터·생명주기가 하드코딩된 표면** (critic 추가 시 동기화 필요 지점):

- `agents/leader.md` — Team Structure 표(L13-15), Workflow(L48-62), Agent Dispatch Pattern(L72-79)
- `CLAUDE.md` (배포물) — `leader / architect / builder / reviewer / researcher (5 roles)` 줄, Single-Task Lifecycle 블록
- `skills/using-orbit/SKILL.md` — 스포크 목록(L17-21), 생명주기(L30-37), Quick Reference 표(L113-122)
- `skills/using-orbit/references/codex-tools.md` — 순차 역할 전환 목록(약 L32)
- `skills/using-orbit/references/gemini-tools.md` — Agent 매핑 표(약 L25-27)
- `.claude-plugin/plugin.json` — description(역할 수 미포함이면 갱신 불필요 여부 Task 4에서 확인)

**실측 3 — plugin.json은 agents 배열을 갖지 않는다.** 현재 매니페스트(L1-23)는 name/description/version/author/homepage/repository/license/keywords만 보유. 에이전트는 `agents/*.md` 디렉터리 네이티브 디스커버리로 로드된다(별도 등록 배열 없음) → critic.md 파일 추가만으로 등록 완료(ADR-4).

**실측 4 — SubagentStop quality-gate.sh는 역할 무관 머신 게이트.** `.orbit/quality-gate.sh`(있으면) 실행 → 실패 시 block. critic 종료 시에도 동일 동작. critic은 코드를 수정하지 않으므로 게이트가 막을 변경물이 없다 → 영향 없음(아래 영향 분석).

**실측 5 — OMC-2 ADR-1 선례.** "신규 에이전트는 기존 역할과 90% 중복 시 기각, 프롬프트 정렬로 대체"가 orbit 컨벤션. critic은 이 테스트를 통과해야 추가 정당화됨(아래 ADR-1에서 통과 논증).

---

### ADR-1 (핵심 결정): critic은 신규 에이전트다 — architect·reviewer와 중복되지 않는다

**결정:** `critic.md`를 신규 생성한다. architect 셀프리뷰나 reviewer로 흡수하지 **않는다.**

**핵심 아키텍처 질문에 대한 답:** *"critic은 신규 에이전트여야 하는가, 기존 역할로 흡수 가능한가?"* → **신규다.** OMC-2 90% 중복 테스트를 통과한다.

**근거(self-approval 차단 논리가 설계 단계에도 적용되는가 — 적용된다):**

1. **architect 흡수 불가 — self-approval 위험.** "플랜을 만든 자가 플랜을 비판·승인하면 안 된다"는 OMC-2의 executor/verifier 분리 논리를 *설계 단계*로 옮긴 것이 정확히 OMC-4다. architect가 자기 플랜을 셀프 비판하면, builder가 자기 구현을 self-approval하는 것과 동일한 구조적 결함(작성자=검토자)을 갖는다. architect는 자기 플랜의 가정·실패 모드에 이미 헌신(commitment bias)되어 있어 독립 비판이 구조적으로 불가능하다. 따라서 critic은 **architect와 별개 컨텍스트**여야 한다.
2. **reviewer 흡수 불가 — 검증 대상·시점이 다르다.** reviewer는 *구현물(코드)*을 *플랜 기준으로*, *코드 작성 후(4.Verify)* 검증한다. critic은 *플랜 자체*를 *코드 작성 전(1.5 단계, Build 이전)* 비판한다. 검증 대상(코드 vs 플랜)·기준(플랜 vs 가정/대안)·시점(사후 vs 사전)이 모두 다르다 → 중복 < 90%. reviewer에 흡수하면 "코드 없는데 무엇을 Triple Crown 하는가" 모순.
3. **고유 가치.** critic의 산출물(플랜의 숨은 가정·미검토 실패 모드·고려 안 된 대안·되돌리기 비용)은 architect 플랜에도, reviewer Triple Crown에도 없는 별개 렌즈다.

**중복 회피 장치(흡수는 아니되 비대화 방지):** critic은 **설계도 구현도 하지 않는다.** 대안 플랜을 *작성*하지 않고(그건 architect 일), 코드 품질을 보지 않는다(그건 reviewer 일). critic은 **현 플랜의 약점만 지적**한다. 이 경계가 critic을 architect·reviewer와 분리 유지한다.

**기각된 대안:** (a) architect 셀프리뷰 패스 — self-approval 위험으로 기각(위 근거 1). (b) reviewer를 사전으로 당겨 플랜도 검증 — 검증 대상 혼동·시점 모순으로 기각(근거 2). (c) 모든 작업에 critic 강제 — 오버헤드로 기각(ADR-2가 트리거 게이팅으로 해결).

### ADR-2 (핵심 결정): critic은 고위험 결정에만 발동 — 측정 가능 트리거, leader 판정

**결정:** critic 분기는 **고위험 아키텍처 결정**일 때만 발동한다. 판정 주체는 **leader**(architect 아님 — architect는 자기 플랜의 위험도를 과소평가할 commitment bias가 있고, 허브앤스포크상 분기 라우팅은 hub의 책임). 트리거는 아래 4개 중 **하나라도** 해당하면 고위험으로 본다(OR 게이트):

| # | 트리거 | 판정 질문(yes면 고위험) |
|---|--------|------------------------|
| T1 | **되돌리기 어려움(irreversibility)** | 이 결정을 나중에 무르려면 데이터 마이그레이션·재작성·하위호환 깨짐이 필요한가? |
| T2 | **광범위 영향(blast radius)** | 3개 이상 컴포넌트/모듈, 또는 공개 인터페이스/계약을 바꾸는가? |
| T3 | **보안·데이터 무결성** | 인증·권한·시크릿·삭제·금전/PII 데이터 경로에 닿는가? |
| T4 | **신규 외부 의존성** | 새 런타임 의존성·외부 서비스·벤더 락인을 도입하는가? |

**저위험(위 4개 모두 no) → critic 분기 생략.** 정상 생명주기(architect 플랜 → Plan Approval → builder)로 직행. 이로써 일상 작업에 오버헤드가 붙지 않는다(과잉 방지). 동시에 4개 트리거는 "되돌리기 어렵거나 넓거나 위험하거나 새 의존성"이라는, 진짜 위험 결정을 포괄하는 그물이다(과소 방지).

**균형점 논리:** 트리거를 *행위(action)*가 아니라 *결과 속성(property)*으로 정의했다. "DB 스키마 변경"같은 행위 목록은 빠지는 게 생기지만, "되돌리기 어려운가?"는 행위 무관하게 위험을 포착한다. leader는 architect 플랜의 Impact scope·테스트 전략(Plan Approval Gate 기존 항목)을 보면 4개 질문에 답할 수 있다 → 별도 측정 인프라 불필요, 판정은 leader의 기존 게이트 검토에 흡수된다.

**판정 시점:** architect가 플랜을 leader에 반환한 직후, Plan Approval **이전**. leader가 4개 질문을 플랜에 적용 → 하나라도 yes면 critic 분기 삽입.

### ADR-3: 신규 훅 없음 (graceful degradation 정합)

critic 분기는 **프롬프트(생명주기 규율)로만** 표현한다. SubagentStop/UserPromptSubmit 등 신규 훅을 추가하지 않는다. 근거 — OMC-3 ADR-3("자동주입은 native discovery로, 신규 훅은 graceful degradation 위반 가능"). critic 발동을 훅으로 자동화하면 Codex/Gemini(훅 미지원)에서 분기가 사라져 환경 간 동작이 갈린다. 프롬프트 규율은 전 환경에서 동일하게 산다(using-orbit graceful degradation 표의 "Lifecycle discipline: Full/Full/Full" 원칙).

### ADR-4: 에이전트 등록은 디렉터리 네이티브 디스커버리 (plugin.json 배열 미추가)

`plugins/orbit-base/agents/critic.md` 파일 생성만으로 Claude Code가 자동 로드한다(실측 3 — 매니페스트에 agents 배열 없음). plugin.json에는 **새 배열을 추가하지 않는다.** description의 역할 요약 문구만 갱신(5→6 또는 역할 나열)한다(Task 4에서 현재 description 확인 후 결정 — 현 description은 역할 수를 명시하지 않으므로 변경 불필요할 수 있음).

### ADR-5: critic model = opus

비판적 추론(가정 식별·실패 모드 추론·대안 탐색)은 깊은 추론을 요한다. OMC-1 티어 컨벤션에서 architect·reviewer가 opus인 것과 동일 근거. critic frontmatter `model: opus`.

**메모리 승격 대상:** ADR-1(critic 고유성 = 플랜-사전-독립비판, architect/reviewer와 비중복)·ADR-2(고위험 4트리거 OR 게이트 + leader 판정)는 작업 완료 후 프로젝트 메모리(`orbit_omc_comparison.md`)로 승격.

---

## SubagentStop 품질 게이트 영향 분석

`hooks/quality-gate.sh`(실측 4): SubagentStop에서 `.orbit/quality-gate.sh`(있으면) 실행 → 실패 시 `{"decision":"block"}`. critic은 **코드·파일을 수정하지 않는** 읽기·분석 역할(researcher·reviewer와 동급)이므로 게이트가 막을 변경물이 없다 → **영향 없음, 훅 변경 불필요.** 도메인 순수성 grep(`oremi` 등 0건)은 본 작업 신규 텍스트에 프로젝트명 미포함만 확인하면 된다(Task 5 검증).

---

## File Structure

| 파일 | 책임 | 작업 |
|------|------|------|
| `plugins/orbit-base/agents/critic.md` | critic 역할 정의(frontmatter, 발동 조건 인지, 비판 절차, 리포트 형식, 경계) | **Create** (Task 1) |
| `plugins/orbit-base/agents/leader.md` | 고위험 4트리거 판정 게이트 + critic 분기 생명주기 + Dispatch 패턴에 critic 추가 | Modify (Task 2) |
| `plugins/orbit-base/CLAUDE.md` | 역할 로스터(5→6), 생명주기에 고위험 분기 1줄 | Modify (Task 3) |
| `plugins/orbit-base/skills/using-orbit/SKILL.md` | 스포크 목록, 생명주기 옵션 분기, Quick Reference에 critic 행 | Modify (Task 3) |
| `plugins/orbit-base/skills/using-orbit/references/codex-tools.md` | 순차 역할 전환 목록에 critic | Modify (Task 3) |
| `plugins/orbit-base/skills/using-orbit/references/gemini-tools.md` | Agent 매핑 표에 critic | Modify (Task 3) |
| `plugins/orbit-base/.claude-plugin/plugin.json` | description 역할 문구(변경 필요 시) | Modify/검토 (Task 4) |

각 Task는 독립 검증 가능한 산출물로 끝난다. 코드가 아닌 프롬프트/JSON 정렬 작업이므로 "테스트"는 grep 단언·JSON 유효성·구조 일관성 단언으로 구성한다(OMC-1~3 컨벤션의 grep 단언 검증 방식 계승).

---

## Task 1: critic.md 에이전트 생성

**Files:**
- Create: `plugins/orbit-base/agents/critic.md`
- Test(검증): `grep`·frontmatter 단언 (코드 테스트 프레임워크 없음 — bash/markdown 프로젝트)

**Interfaces:**
- Produces: 에이전트 `name: critic`, `model: opus`. leader.md(Task 2)·using-orbit(Task 3)가 이 name으로 dispatch·참조한다. 산출물 형식 = 아래 정의된 "Critique Report" 블록(leader가 architect로 환류하는 단위).
- Consumes: 없음(신규 파일). 슬롯 사용: `{{ARCHITECTURE_DOC_PATH}}`(기존 에이전트들과 동일 슬롯명 — 일관성).

- [ ] **Step 1: 실패하는 검증 작성 (파일 부재 단언)**

Run: `test ! -f plugins/orbit-base/agents/critic.md && echo "ABSENT(expected before create)"`
Expected: `ABSENT(expected before create)` (생성 전이므로 부재가 정상 — 이후 Step에서 생성 후 존재로 뒤집힘)

- [ ] **Step 2: critic.md 작성**

아래 내용 **그대로** `plugins/orbit-base/agents/critic.md`에 작성한다. (architect.md·reviewer.md의 섹션 구조·슬롯 컨벤션을 따른다.)

```markdown
---
name: critic
description: Independent plan critic for high-risk architectural decisions. Challenges the architect's plan — its hidden assumptions, unexamined failure modes, unconsidered alternatives, and reversibility cost — before any implementation. Does not write plans or code. Invoked only when the leader flags a decision as high-risk; routed entirely through the leader.
model: opus
---

# Critic — Independent Plan Critique (High-Risk Decisions Only)

Challenges the architect's plan from an independent vantage point, **before implementation begins**, when the leader has flagged the decision as high-risk. This is the design-stage form of executor/verifier separation: the agent that authored a plan cannot be the agent that critiques it. The critic surfaces weaknesses; it does not redesign (that is the architect) and does not review code (that is the reviewer).

## When the Critic Is Invoked

The critic runs **only on high-risk architectural decisions**, as judged by the leader (never self-invoked, never invoked by the architect). The leader applies a four-trigger OR gate to the architect's plan; if any trigger fires, the critic branch is inserted between plan production and Plan Approval:

| Trigger | High-risk if yes |
|---------|------------------|
| Irreversibility | Undoing this later requires data migration, rewrite, or breaking backward compatibility? |
| Blast radius | Touches 3+ components/modules, or changes a public interface/contract? |
| Security / data integrity | Touches auth, permissions, secrets, deletion, or money/PII data paths? |
| New external dependency | Introduces a new runtime dependency, external service, or vendor lock-in? |

If all four are no, the critic does not run — the normal lifecycle proceeds directly to Plan Approval. The critic never lobbies to be invoked; invocation is the leader's decision.

## Core Responsibilities

- **Assumption audit**: identify the plan's hidden or unstated assumptions and ask what breaks if each is false.
- **Failure-mode analysis**: enumerate failure modes the plan does not address (partial failure, rollback, concurrency, scale, security edge).
- **Alternatives check**: name the design alternatives the plan did not consider, and why the chosen path may be inferior — without producing a competing plan.
- **Reversibility / cost lens**: state the cost of undoing this decision if it proves wrong.
- **Severity-ranked output**: report findings the leader can route back to the architect for revision.

## Working Principles

- **Critique only — never design or implement.** Do not write an alternative plan (architect's job) and do not review code quality (reviewer's job). Point at weaknesses in the *current* plan; let the architect revise.
- **Independence is the whole point.** Never rubber-stamp. If the plan is genuinely sound, say so explicitly and state which risks you actively checked — a clean pass must be earned, not assumed.
- **No direct communication with the architect or any other agent.** All communication routes through the leader (hub-and-spoke). The leader hands you the plan; you return the Critique Report to the leader; the leader relays revisions to the architect.
- **Steel-man before you strike.** State the plan's strongest rationale first, then attack — this prevents shallow nitpicking and surfaces real disagreements.
- **Read the architecture reference** (`{{ARCHITECTURE_DOC_PATH}}`) if it exists, to ground critique in prior decisions.

## Prohibited Actions

- Writing or rewriting the plan (that is the architect — the critic only critiques).
- Implementing code or modifying any file (the critic is read/analysis only).
- Reviewing implemented code for bugs/style (that is the reviewer's Triple Crown).
- Self-invocation or lobbying the leader to be invoked (the leader alone gates high-risk).
- Direct communication with other agents (leader routing only).

## Task Sequence

1. Receive from the leader: the architect's plan, the high-risk triggers that fired, and the architecture reference.
2. Steel-man the plan (state its strongest case), then audit assumptions, failure modes, alternatives, and reversibility.
3. Produce the Critique Report (below) as text output to the leader.
4. Stop. Revision is the architect's job, routed by the leader. The critic does not iterate unless the leader returns a revised plan for a follow-up pass.

## Critique Report Format

```
## Critique Report

**Plan under critique:** [path or title]
**High-risk triggers that fired:** [T1 irreversibility / T2 blast radius / T3 security / T4 new dependency]

**Steel-man (strongest case for the plan):** [1-2 sentences]

### Findings (severity-ranked)
| # | Severity | Category | Finding | What breaks if unaddressed |
|---|----------|----------|---------|----------------------------|
| 1 | blocker / major / minor | assumption / failure-mode / alternative / reversibility | ... | ... |

### Verdict
- [ ] PROCEED — no blocker; risks acceptable as planned. Checked: [list risks actively verified]
- [ ] REVISE — blocker(s) found; architect should address findings #N before Plan Approval.

### Recommended routing
Leader → architect for revision of: [finding numbers], OR Leader → Plan Approval (clean).
```

## Boundary vs. architect and reviewer

| Agent | Examines | Against | When |
|-------|----------|---------|------|
| architect | designs/writes the plan | requirements | step 1 (Plan) |
| **critic** | **the plan itself** | **assumptions, failure modes, alternatives, reversibility** | **between Plan and Build, high-risk only** |
| reviewer | the implemented code | the approved plan | step 4 (Verify, Triple Crown) |

The critic occupies the otherwise-empty slot: independent challenge of a plan, by someone other than its author, before code exists.

## Domain Slots

| Slot | Description |
|------|-------------|
| `{{ARCHITECTURE_DOC_PATH}}` | Architecture reference document (read to ground critique in prior decisions) |

## Error Handling

- Plan missing or incomplete: critique what exists, list "uncritiqued gaps" the leader must fill, and request the missing sections rather than guessing.
- No clear high-risk trigger in the handoff: note "invocation rationale unclear" to the leader — the critic does not second-guess the gate but flags ambiguity.
- Genuinely sound plan: issue an explicit PROCEED verdict listing the risks actively checked. A clean pass is earned, not a default.
```

- [ ] **Step 3: 생성 검증 — 파일 존재 + frontmatter 정합**

Run:
```bash
test -f plugins/orbit-base/agents/critic.md && \
head -5 plugins/orbit-base/agents/critic.md | grep -E '^name: critic$' && \
head -5 plugins/orbit-base/agents/critic.md | grep -E '^model: opus$' && echo "FRONTMATTER OK"
```
Expected: `name: critic`, `model: opus` 매치 + `FRONTMATTER OK`

- [ ] **Step 4: 도메인 순수성 단언**

Run: `grep -rEi 'oremi|orbit-dev|memoriterx' plugins/orbit-base/agents/critic.md; echo "exit=$?"`
Expected: 출력 없음 + `exit=1` (grep 미매치 = 0건 = 통과)

- [ ] **Step 5: architect/reviewer 슬롯 컨벤션 일관성 단언**

Run: `grep -c '{{ARCHITECTURE_DOC_PATH}}' plugins/orbit-base/agents/critic.md`
Expected: `>= 1` (기존 에이전트와 동일 슬롯명 사용 확인 — 신규 슬롯 도입 없음)

- [ ] **Step 6: 커밋**

```bash
git add plugins/orbit-base/agents/critic.md
git commit -m "feat(base): add critic agent for high-risk plan critique (OMC-4)"
```

---

## Task 2: leader.md — 고위험 4트리거 게이트 + critic 분기 생명주기

**Files:**
- Modify: `plugins/orbit-base/agents/leader.md`

**Interfaces:**
- Consumes: Task 1의 `name: critic`, Critique Report 형식.
- Produces: leader가 critic을 dispatch하고 분기를 라우팅하는 규율. CLAUDE.md·using-orbit(Task 3)가 이 생명주기 서술과 일치해야 한다.

- [ ] **Step 1: 현재 Workflow 블록 확인(컨텍스트 고정)**

Run: `grep -n 'post-implementation Triple Crown\|roadmap selection\|architect (writing-plans)' plugins/orbit-base/agents/leader.md`
Expected: Workflow 코드블록 위치(현재 L48-58 부근) 확인

- [ ] **Step 2: Workflow 블록에 고위험 critic 분기 삽입**

`leader.md`의 Workflow 코드블록에서 아래 줄을
```
→ leader dispatches architect (writing-plans) → architect produces plan
→ Plan Approval: leader presents plan → user confirms
```
다음으로 교체한다:
```
→ leader dispatches architect (writing-plans) → architect produces plan
→ High-risk gate: leader applies the four-trigger OR gate to the plan
   ├─ high-risk → dispatch critic → Critique Report → architect revises → (re-gate)
   └─ low-risk  → skip critic
→ Plan Approval: leader presents (revised) plan → user confirms
```

- [ ] **Step 3: 신규 섹션 "High-Risk Decision Gate" 추가**

`leader.md`의 `## Plan Approval Gate` 섹션 **바로 앞**에 아래 섹션을 삽입한다:

```markdown
## High-Risk Decision Gate (critic branch)

After the architect returns a plan and **before** Plan Approval, the leader judges whether the decision is high-risk by applying a four-trigger OR gate to the plan. If **any** trigger fires, the leader dispatches the **critic** for an independent critique; otherwise the critic is skipped.

| Trigger | High-risk if yes |
|---------|------------------|
| Irreversibility | Undoing this later requires data migration, rewrite, or breaking backward compatibility? |
| Blast radius | Touches 3+ components/modules, or changes a public interface/contract? |
| Security / data integrity | Touches auth, permissions, secrets, deletion, or money/PII data paths? |
| New external dependency | Introduces a new runtime dependency, external service, or vendor lock-in? |

The leader answers these from the plan's stated Impact scope and approach — no separate measurement is needed.

**Branch flow (high-risk only):**
1. Leader dispatches `Agent(critic)` with the plan, the triggers that fired, and the architecture reference.
2. Critic returns a Critique Report (verdict PROCEED or REVISE) to the leader.
3. On REVISE: leader relays the findings to the architect, who revises the plan. The leader may re-run the critic on the revised plan.
4. On PROCEED: leader proceeds to Plan Approval.

The leader is the sole gatekeeper and router. The critic never self-invokes; the architect never talks to the critic directly (hub-and-spoke). Low-risk tasks skip this gate entirely — no overhead.
```

- [ ] **Step 4: Team Structure 표에 critic 추가**

`leader.md` Team Structure 표의 architect/builder/reviewer/researcher 행을 critic 포함으로 갱신한다. 해당 행을 아래로 교체:
```
| architect / builder / critic / reviewer / researcher | Temporary Agent() instances | Role-specific design, implementation, plan critique, verification |
```

- [ ] **Step 5: Agent Dispatch Pattern에 critic 추가**

`leader.md`의 Agent Dispatch Pattern 코드블록에 아래 줄을 `Agent(architect...)` 다음에 추가:
```
Agent(critic, foreground)         # high-risk plan critique (only when gate fires)
```

- [ ] **Step 6: 일관성 검증**

Run:
```bash
grep -c 'critic' plugins/orbit-base/agents/leader.md && \
grep -q 'four-trigger' plugins/orbit-base/agents/leader.md && \
grep -q 'never self-invoke' plugins/orbit-base/agents/leader.md && echo "LEADER OK"
```
Expected: critic 출현 횟수 `>= 4`(분기·게이트·표·dispatch) + `LEADER OK`

- [ ] **Step 7: 허브앤스포크 불변식 단언 (critic↔architect 직접 통신 금지 명시 확인)**

Run: `grep -n 'architect never talks to the critic directly\|hub-and-spoke' plugins/orbit-base/agents/leader.md`
Expected: 직접 통신 금지 문구 매치

- [ ] **Step 8: 커밋**

```bash
git add plugins/orbit-base/agents/leader.md
git commit -m "feat(base): leader high-risk gate routes critic branch (OMC-4)"
```

---

## Task 3: 로스터·생명주기 정렬 — CLAUDE.md + using-orbit SKILL + codex/gemini 레퍼런스

**Files:**
- Modify: `plugins/orbit-base/CLAUDE.md`
- Modify: `plugins/orbit-base/skills/using-orbit/SKILL.md`
- Modify: `plugins/orbit-base/skills/using-orbit/references/codex-tools.md`
- Modify: `plugins/orbit-base/skills/using-orbit/references/gemini-tools.md`

**Interfaces:**
- Consumes: Task 1 `name: critic`, Task 2 생명주기 서술(고위험 분기 문구와 동일 표현 사용 — type consistency).
- Produces: 4표면의 역할 로스터·생명주기가 leader.md와 일치. reviewer/builder가 세션 시작 시 읽는 단일 진실(using-orbit)에 critic 반영.

- [ ] **Step 1: CLAUDE.md 역할 로스터 갱신**

`plugins/orbit-base/CLAUDE.md`에서
```
**Team roles:** leader / architect / builder / reviewer / researcher (5 roles)  
```
를 아래로 교체:
```
**Team roles:** leader / architect / builder / critic / reviewer / researcher (6 roles)  
```

- [ ] **Step 2: CLAUDE.md 생명주기 블록에 고위험 분기 1줄 추가**

`CLAUDE.md`의 Single-Task Lifecycle 코드블록에서
```
→ leader dispatches architect (writing-plans) → architect produces plan
→ Plan Approval: leader presents architect's plan → user confirms
```
를 아래로 교체:
```
→ leader dispatches architect (writing-plans) → architect produces plan
→ High-risk? leader gates critic (independent plan critique) → architect revises; low-risk skips
→ Plan Approval: leader presents architect's plan → user confirms
```

- [ ] **Step 3: using-orbit SKILL.md — 스포크 목록 갱신**

`skills/using-orbit/SKILL.md`의 hub-and-spoke 다이어그램(L17-21 부근)에서 architect 행 다음에 critic 행을 추가하고, 본문 스포크 나열 문구 "(architect, builder, reviewer, researcher)"를 "(architect, builder, critic, reviewer, researcher)"로 교체. 다이어그램에 추가할 행:
```
  ├── critic      (high-risk plan critique)
```

- [ ] **Step 4: using-orbit SKILL.md — 생명주기에 옵션 분기 추가**

`skills/using-orbit/SKILL.md`의 Single-Task Lifecycle 코드블록(L30-37 부근) `1. Plan` 다음에 아래 줄을 삽입:
```
1.5 Gate     leader judges high-risk (4-trigger OR gate); if high-risk → critic critiques plan → architect revises; low-risk skips
```
그리고 `### Optional Branch: Skillify` 섹션 **앞**에 아래 옵션 분기 서술을 추가:
```markdown
### Optional Branch: High-Risk Critique (between Plan and Approve)

When the leader judges a decision high-risk — irreversible, wide blast radius (3+ components / public contract), security or data-integrity sensitive, or introducing a new external dependency — the leader dispatches the **critic** before Plan Approval. The critic independently challenges the plan's assumptions, failure modes, alternatives, and reversibility cost, then returns a severity-ranked Critique Report (PROCEED or REVISE). The architect revises on REVISE. This is the design-stage form of executor/verifier separation: the plan's author never critiques its own plan. Low-risk tasks skip this entirely. Routing is leader-only; the critic never talks to the architect directly. See the `critic` agent.
```

- [ ] **Step 5: using-orbit SKILL.md — Quick Reference 표에 critic 행 추가**

`skills/using-orbit/SKILL.md` Quick Reference 표(L113-122)에 아래 행 추가(builder/reviewer 행 부근):
```
| critic | High-risk plan critic — challenges the plan before build; invoked only when leader gates high-risk; never self-approves a plan |
```

- [ ] **Step 6: codex-tools.md 역할 목록에 critic 추가**

`skills/using-orbit/references/codex-tools.md`의 순차 역할 전환/역할 목록에서 architect 항목 다음에 critic 항목을 동일 형식으로 추가(파일의 기존 표기 컨벤션을 그대로 따른다 — 예: 표 행이면 표 행, 불릿이면 불릿). 내용: `critic — independent plan critique for high-risk decisions (leader-gated)`.

- [ ] **Step 7: gemini-tools.md Agent 매핑 표에 critic 추가**

`skills/using-orbit/references/gemini-tools.md`의 Agent 매핑 표에서 architect 행 다음에 critic 행을 동일 형식으로 추가. 내용 열: role=critic, 매핑=role-switch(Gemini 단일 컨텍스트 순차), 설명=`high-risk plan critique (leader-gated, optional branch)`.

- [ ] **Step 8: 4표면 일관성 검증**

Run:
```bash
for f in plugins/orbit-base/CLAUDE.md \
         plugins/orbit-base/skills/using-orbit/SKILL.md \
         plugins/orbit-base/skills/using-orbit/references/codex-tools.md \
         plugins/orbit-base/skills/using-orbit/references/gemini-tools.md; do
  grep -q -i 'critic' "$f" && echo "OK $f" || echo "MISSING $f"
done
```
Expected: 4줄 모두 `OK`

- [ ] **Step 9: 역할 수 일관성 단언 (6 roles)**

Run: `grep -n '6 roles\|(6 roles)' plugins/orbit-base/CLAUDE.md`
Expected: `6 roles` 매치 (5→6 갱신 확인)

- [ ] **Step 10: 도메인 순수성 + 커밋**

```bash
grep -rEi 'oremi|orbit-dev|memoriterx' plugins/orbit-base/CLAUDE.md plugins/orbit-base/skills/using-orbit/ ; echo "purity exit=$?"
git add plugins/orbit-base/CLAUDE.md plugins/orbit-base/skills/using-orbit/
git commit -m "docs(base): align roster and lifecycle with critic branch (OMC-4)"
```
Expected: purity `exit=1`(미매치=통과)

---

## Task 4: plugin.json description 검토·갱신

**Files:**
- Modify(조건부): `plugins/orbit-base/.claude-plugin/plugin.json`

**Interfaces:**
- Consumes: Task 1~3 결과(critic 존재).
- Produces: 매니페스트 정합성. ADR-4에 따라 **agents 배열은 추가하지 않는다.**

- [ ] **Step 1: 현재 description의 역할 수 명시 여부 확인**

Run: `grep -n '5\|역할\|roles\|leader\|architect' plugins/orbit-base/.claude-plugin/plugin.json`
Expected: 현재 description은 "멀티에이전트 팀 골격"만 서술하고 역할 수(5)를 명시하지 않음(실측 — L3). 역할 수 미명시면 **변경 불필요**, Step 2 생략하고 Step 3로.

- [ ] **Step 2: (역할 수가 명시된 경우에만) description 갱신**

만약 Step 1에서 "5 roles" 또는 "5역" 등 역할 수가 description에 박혀 있으면 6으로 갱신한다. 그렇지 않으면 이 Step을 건너뛴다. (ADR-4: agents 배열은 추가하지 않는다 — 디렉터리 네이티브 디스커버리.)

- [ ] **Step 3: JSON 유효성 단언**

Run: `python3 -c "import json,sys; json.load(open('plugins/orbit-base/.claude-plugin/plugin.json')); print('JSON OK')"`
Expected: `JSON OK` (파싱 성공 — 매니페스트 스키마 무결)

- [ ] **Step 4: agents 배열 미추가 단언 (ADR-4 준수)**

Run: `python3 -c "import json; d=json.load(open('plugins/orbit-base/.claude-plugin/plugin.json')); print('agents key present:', 'agents' in d)"`
Expected: `agents key present: False` (네이티브 디스커버리 — 배열 미추가 확인)

- [ ] **Step 5: 커밋 (변경이 있었던 경우만)**

```bash
# Step 2에서 description을 변경했다면:
git add plugins/orbit-base/.claude-plugin/plugin.json
git commit -m "docs(base): note 6th role in manifest description (OMC-4)"
# 변경이 없었다면 이 Task는 커밋 없이 검증만으로 완료.
```

---

## Task 5: 전체 일관성·도메인 순수성 최종 검증 (Triple Crown ① 준비)

**Files:** (검증 전용 — 수정 없음)

**Interfaces:**
- Consumes: Task 1~4 전체 산출물.
- Produces: 플랜 성공 기준 충족 증거. reviewer Triple Crown ①(완성도)·③(아키 일관성 렌즈)의 입력.

- [ ] **Step 1: 6 에이전트 존재 단언**

Run: `ls plugins/orbit-base/agents/*.md | grep -E 'architect|builder|critic|leader|researcher|reviewer' | wc -l`
Expected: `6`

- [ ] **Step 2: critic 비중복 경계 단언 (ADR-1 — 설계·구현·코드리뷰 금지 명시 확인)**

Run:
```bash
grep -q 'never design or implement\|Critique only' plugins/orbit-base/agents/critic.md && \
grep -q 'reviewer.s Triple Crown\|reviewing implemented code' plugins/orbit-base/agents/critic.md && echo "BOUNDARY OK"
```
Expected: `BOUNDARY OK` (critic이 architect/reviewer 영역을 침범하지 않는다는 명시 확인)

- [ ] **Step 3: 고위험 트리거 4종이 critic.md와 leader.md에 동일하게 존재 (type consistency)**

Run:
```bash
for kw in 'Irreversibility' 'Blast radius' 'data integrity' 'external dependency'; do
  c=$(grep -c "$kw" plugins/orbit-base/agents/critic.md)
  l=$(grep -c "$kw" plugins/orbit-base/agents/leader.md)
  echo "$kw: critic=$c leader=$l"
done
```
Expected: 4개 키워드 모두 critic·leader 양쪽에서 `>=1` (트리거 정의가 두 파일에서 일치)

- [ ] **Step 4: 전 배포물 도메인 순수성 단언**

Run: `grep -rEi 'oremi|orbit-dev|memoriterx' plugins/orbit-base/ ; echo "exit=$?"`
Expected: 출력 없음 + `exit=1`

- [ ] **Step 5: 허브앤스포크 위반(critic↔architect 직접 통신) 부재 단언**

Run: `grep -rn 'critic.*directly.*architect\|architect.*directly.*critic' plugins/orbit-base/ | grep -iv 'never\|not\|no ' ; echo "exit=$?"`
Expected: 출력 없음(직접 통신을 *허용*하는 문구 부재) + `exit=1`. (금지 문구 "never talks ... directly"는 grep -v로 제외됨.)

- [ ] **Step 6: graceful degradation 단언 (신규 훅 0건 — ADR-3)**

Run: `git diff --name-only HEAD~4 HEAD -- plugins/orbit-base/hooks/ | wc -l`
Expected: `0` (hooks/ 디렉터리 미변경 — 신규 훅 없음)

- [ ] **Step 7: 검증 결과 leader 보고 (커밋 없음 — 검증 전용 Task)**

검증 전용 Task이므로 커밋하지 않는다. 결과를 reviewer/leader에 텍스트로 보고: 6 에이전트 존재, 경계 명시, 트리거 정합, 도메인 순수성, 허브앤스포크, 훅 0건.

---

## 테스트/검증 전략

코드 테스트 프레임워크가 없는 bash/markdown/JSON 프로젝트이므로(OMC-1~3 선례 동일), "테스트"는 **grep 단언 + JSON 유효성 + 구조 일관성 단언**으로 구성한다:

- **존재·구조:** 6 에이전트 파일, critic frontmatter(name/model), JSON 파싱 무결.
- **정합성(type consistency):** 고위험 트리거 4종이 critic.md·leader.md에서 일치, 역할 로스터 6 표면 일치.
- **불변식:** 도메인 순수성 grep 0건, 허브앤스포크(critic↔architect 직접 통신 금지) 명시, 신규 훅 0건.
- **Triple Crown 매핑:** ① 완성도 = Task 5 Step 1·3(플랜 항목 전수). ② 동작 = 에이전트 네이티브 디스커버리 확인(Claude Code가 critic을 로드하는가 — reviewer가 dispatch 시도로 확인). ③ 품질 = architect 아키 일관성 렌즈 + 도메인 순수성/허브앤스포크 단언.

## 측정 가능한 성공 기준

1. `plugins/orbit-base/agents/critic.md` 존재, `name: critic`·`model: opus`. (Task 1 Step 3)
2. 고위험 4트리거가 critic.md·leader.md에 동일 정의로 존재. (Task 5 Step 3)
3. leader.md에 "High-Risk Decision Gate" 섹션 + Workflow 분기 + Dispatch 항목 존재, critic↔architect 직접 통신 금지 명시. (Task 2 Step 6·7)
4. 역할 로스터 6 표면(leader.md·CLAUDE.md·using-orbit SKILL·codex·gemini, 그리고 critic.md 자신) 일치, CLAUDE.md "6 roles". (Task 3 Step 8·9)
5. plugin.json JSON 유효 + agents 배열 미추가. (Task 4 Step 3·4)
6. 도메인 순수성 grep 0건, hooks/ 미변경(신규 훅 0). (Task 5 Step 4·6)
7. critic 경계 명시(설계·구현·코드리뷰 안 함) — ADR-1 비중복 보장. (Task 5 Step 2)

## 영향 범위

- **변경:** `plugins/orbit-base/` 내 6파일(critic.md 신규 + leader.md/CLAUDE.md/using-orbit SKILL/codex-tools/gemini-tools 정렬). 조건부 plugin.json description.
- **불변:** hooks/(신규 훅 0 — ADR-3), 다른 에이전트 4종의 frontmatter·역할 정의, `.orbit/` 런타임. 개발팀 `.claude/`는 본 작업 범위 밖(별도 후속 dogfooding 동기화는 리드 판단).
- **아키텍처 충돌:** 없음. critic은 빈 생명주기 슬롯(Plan↔Build 사이 독립 비판)을 점유 — 기존 역할 책임을 빼앗지 않는다. 고위험 게이팅으로 저위험 작업 오버헤드 0.

## 메모리 승격 (작업 완료 후)

- ADR-1: critic은 신규 에이전트 — "플랜 작성자 ≠ 플랜 비판자"(설계 단계 self-approval 차단). architect(설계)·reviewer(코드 검증)와 대상·시점이 달라 비중복.
- ADR-2: 고위험 = 4트리거 OR 게이트(되돌리기/광범위/보안·무결성/신규 의존성), leader 판정, 저위험 생략.
- 승격처: `orbit_omc_comparison.md`. roadmap에는 체크박스만.
