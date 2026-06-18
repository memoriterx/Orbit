# OMC-3 skillify 패턴 — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 배포물 `plugins/orbit-base/`에 "반복적으로 해결되는 문제를 SKILL.md로 추출하는" skillify 패턴을 도입한다. orbit 고유 가치는 *추출 방법(HOW)*이 아니라 *생명주기 안에서의 언제·누가·무엇을·어디에(WHEN/WHO/WHAT/WHERE)* 라는 **트리거·라우팅·자동발견 규약**이다. authoring HOW는 superpowers `writing-skills`에 위임한다.

**Architecture:** skillify를 *수행하는* 신규 에이전트나 신규 훅을 만들지 않는다(아래 ADR-1·ADR-3). 산출물은 **단일 skillify 스킬 1개**(`skills/skillify/SKILL.md`) + 그 트리거를 생명주기에 연결하는 **3표면(using-orbit SKILL / leader.md / CLAUDE.md) 프롬프트 정렬**이다. skillify 스킬은 (a) 추출 트리거 기준(반복성 임계), (b) 라우팅(reviewer가 신호 감지 → leader가 architect에 추출 위임), (c) 결과물 형식 명세(orbit 프로젝트 스킬 SKILL.md frontmatter + 디렉터리 규약), (d) 자동발견 메커니즘(Claude Code의 SKILL.md name/description 네이티브 디스커버리) — 네 가지를 한 문서에 담는다. 실제 SKILL.md 본문 작성 품질은 superpowers `writing-skills`(TDD-for-skills)에 위임한다.

**Tech Stack:** Markdown SKILL.md + YAML frontmatter(name/description), Claude Code 네이티브 스킬 디스커버리, bash/grep(검증). 신규 bash 스크립트·훅·매니페스트 변경 없음.

## Global Constraints

- 도메인 순수성: `plugins/orbit-base/` 내 모든 신규/수정 파일에 특정 프로젝트명(oremi, Oremi, orbit-dev, memoriterx 등) 하드코딩 금지. 도메인 값은 슬롯(`{{...}}`)으로 남긴다. 검증: `grep -rEi 'oremi|orbit-dev' plugins/orbit-base/` 0건.
- 모듈 경계: 배포물 `plugins/orbit-base/`만 수정. 개발팀 설정 `.claude/`는 **참고 전용 — 수정 금지**.
- 매니페스트 정합성: `plugins/orbit-base/.claude-plugin/plugin.json`이 단일 일관성 기준. 본 작업은 신규 에이전트를 추가하지 않으므로 plugin.json을 변경하지 않는다.
- 허브앤스포크 불변식: 모든 에이전트 통신은 leader 경유. reviewer↔architect 직접 통신 도입 금지 — skillify 추출 위임도 leader를 경유한다.
- 스킬 디스커버리 규약: 신규 스킬 디렉터리는 `skills/<skill-name>/SKILL.md` 형식, frontmatter에 `name`(케밥케이스, 디렉터리명과 일치)과 `description`(언제 쓰는지 1문장)만 둔다. 기존 `using-orbit/SKILL.md`와 정합.
- 커밋 접두사 `feat/fix/chore/docs/refactor:` 사용. **Co-Authored-By 줄 절대 금지.**
- frontmatter `model:` 슬롯은 스킬 파일에 두지 않는다(스킬은 모델 티어가 없다 — 에이전트만 `model:` 보유). OMC-1 컨벤션 영향 없음.

---

## 사전 조사 결과 (실측)

### 실측 1 — 기존 스킬 형식 컨벤션 (`skills/using-orbit/SKILL.md`)

```
skills/
  using-orbit/
    SKILL.md                  # frontmatter: name, description (2필드만, model 없음)
    references/
      .gitkeep
      codex-tools.md          # 플랫폼별 보조 레퍼런스 (선택적, 본문에서 참조)
      gemini-tools.md
```

- frontmatter: `name: using-orbit`(디렉터리명과 일치, 케밥케이스), `description: ...Use at the start of any orchestrated work session.`(언제 쓰는지 명시).
- 본문: `#` H1 제목 + 산문/표 혼합. 도메인 무관(슬롯 미사용이지만 프로젝트명 하드코딩 없음).
- `references/`: 본문이 길어질 때 분리하는 보조 자료 디렉터리. skillify는 본문이 짧으므로 references 불필요(YAGNI).

### 실측 2 — Claude Code 스킬 디스커버리 메커니즘 (자동주입의 실체)

- Claude Code는 플러그인 `skills/*/SKILL.md`를 frontmatter `name`/`description`으로 **자동 인덱싱**한다. 모델이 `description`에 부합하는 상황을 만나면 Skill 도구로 로드한다.
- **즉 "자동주입(auto-injection)"은 별도 훅 없이 SKILL.md frontmatter만으로 실현된다** (핵심 아키텍처 질문 ②의 답 → ADR-3).
- 따라서 skillify가 만들어야 할 "자동발견되는 스킬"의 요건은 단 두 가지: (1) `skills/<name>/SKILL.md` 경로, (2) `description`이 *트리거 상황*을 명확히 기술. 이 요건을 skillify 스킬이 형식 명세로 못박는다.

### 실측 3 — 기존 생명주기·라우팅 (`using-orbit/SKILL.md`, `leader.md`)

- 생명주기: `select → plan(architect) → approve → build(builder) → verify(Triple Crown, reviewer 조율) → done(roadmap 체크 + 메모리 승격)`.
- reviewer는 Triple Crown 조율자이자 사후 검증 권한자(OMC-2). **여러 작업을 거치며 "같은 문제를 반복 해결"하는 신호를 가장 먼저 보는 위치**가 reviewer/사후 단계다 → skillify 트리거의 자연스러운 감지 지점(ADR-2).
- architect는 "핵심 결정을 메모리로 승격"하는 역할 보유 → 재사용 패턴을 *추출·문서화*하는 책임과 인접. skillify 추출 실행자로 적합(ADR-2).

### 실측 4 — superpowers `writing-skills`와의 관계 (중복 회피)

- `writing-skills`(설치됨): SKILL.md를 *어떻게 잘 쓰는가* — baseline 실패 관찰 → SKILL.md 작성 → 압박 시나리오로 검증(TDD-for-skills). 범용·개인 스킬 지향.
- orbit `skillify`가 답해야 할 것은 *언제 추출을 시작하나/누가/어느 디렉터리에/어떻게 자동발견되나* — **생명주기 통합 규약**. authoring HOW는 중복이므로 위임한다(ADR-4).

---

### ADR-1 (핵심 결정): skillify는 "수행하는 스킬 1개" + "형식 명세를 그 안에 포함"한다 (둘 다, 단 단일 문서)

**핵심 아키텍처 질문 "(a)수행 스킬 / (b)형식 명세 문서 / (c)둘 다?"에 대한 답:** **(c) 둘 다, 그러나 별도 두 파일이 아니라 단일 `skills/skillify/SKILL.md` 한 문서**로 통합한다.

**근거:**
1. roadmap 메모는 "skillify 스킬 정의 + 추출 트리거 명세" 두 가지를 언급한다. 그러나 둘은 분리하면 동기화 부담만 생긴다 — 트리거 명세는 skillify 스킬이 *수행할 절차의 일부*이지 독립 문서가 아니다.
2. skillify 스킬 본문 = "추출 트리거 판단 → 라우팅 → 결과물 형식 명세 적용 → 자동발견 확인"의 절차서. 형식 명세(새 스킬 SKILL.md가 따라야 할 frontmatter/디렉터리 규약)는 이 절차의 산출물 규격으로 본문 한 절에 들어간다.
3. 단일 문서 = Claude Code가 자동발견하는 실행 가능한 스킬이면서 동시에 형식 기준 문서. 도메인 무관 배포물은 파일 수가 적을수록 채택·유지가 쉽다(OMC-2 ADR-1과 동일 원칙).

**기각된 대안:** `skills/skillify/SKILL.md`(수행) + `skills/skillify/skill-format-spec.md`(명세) 2파일. 기각 — 명세는 SKILL.md 본문 한 절로 충분하며, 두 파일은 "어느 게 진실의 출처냐" 모호화를 부른다.

### ADR-2: 트리거는 reviewer가 감지, 추출은 architect가 수행, 라우팅은 leader 경유

**핵심 질문 "누가 추출을 트리거하나":**
- **감지(WHO detects):** reviewer. Triple Crown 사후 단계에서 "직전 N회 작업에서 동일 유형 문제를 반복 해결했다"는 신호를 reviewer가 식별해 leader에 보고. reviewer는 사후 단계에서 작업 흐름을 보는 유일한 검증자다(실측 3).
- **위임 결정(WHO decides):** leader. reviewer 신호를 받아 추출 가치가 있으면 architect에 skillify 위임. 허브앤스포크 불변식 준수(reviewer→architect 직접 통신 금지).
- **수행(WHO extracts):** architect. 재사용 패턴 문서화·메모리 승격 책임과 인접(실측 3). architect가 skillify 스킬을 로드해 새 `skills/<name>/SKILL.md`를 작성. authoring 품질은 superpowers `writing-skills`로(ADR-4).
- **승인(WHO approves):** 새 스킬은 배포물 변경이므로 일반 생명주기(Plan Approval 후 builder가 실제 파일 작성)를 따른다 — architect는 *제안*만, 파일 쓰기는 builder. (단, 본 OMC-3 작업 자체는 skillify *규약*을 추가하는 것이지 자동으로 스킬을 양산하는 게 아니다.)

**트리거 임계(WHAT to extract — 반복성 기준):** "**3회 규칙**" — 동일 절차/해결법이 서로 다른 작업에서 3회 이상 반복되면 추출 후보. 1~2회는 우연일 수 있어 추출하지 않는다(YAGNI). 추출 대상은 *재사용 가능한 기법·패턴·도구 사용법*이며, *한 번 푼 사건의 서사*는 아니다(writing-skills 정의 계승).

### ADR-3: 자동주입 = 별도 훅 없이 Claude Code 네이티브 스킬 디스커버리로 실현

**핵심 아키텍처 질문 ② "자동주입은 디스커버리로 가능한가, 별도 훅이 필요한가":** **네이티브 디스커버리로 충분 — 신규 훅 불필요.**

**근거:** 실측 2. Claude Code는 `skills/<name>/SKILL.md`의 frontmatter `name`/`description`을 자동 인덱싱하고 description에 부합하는 상황에서 모델이 스킬을 로드한다. skillify가 보장할 것은 "추출된 스킬의 `description`이 트리거 상황을 명확히 기술"하는 것뿐. 별도 SubagentStart/UserPromptSubmit 훅으로 강제 주입하면 (1) 모든 환경에서 동작 안 함(Codex/Gemini는 훅 없음 — graceful degradation 위반), (2) 디스커버리와 중복. **따라서 hooks.json·신규 훅 스크립트를 일절 건드리지 않는다.**

**SubagentStop 품질 게이트 영향:** `hooks/quality-gate.sh`(SubagentStop)는 `.orbit/quality-gate.sh`만 실행하는 머신 게이트로 skillify와 직교. 도메인 순수성 grep은 CLAUDE.md 규칙 — 본 작업 신규 텍스트가 새 위반을 만들지 않는지만 확인(슬롯 사용, 프로젝트명 미포함). **hooks.json 변경 0.**

### ADR-4: authoring HOW는 superpowers `writing-skills`에 위임 (중복 금지)

skillify 스킬은 "SKILL.md를 어떻게 잘 쓰는가"(baseline 실패 관찰·압박 테스트)를 **재설명하지 않는다.** 그 대목에서 `writing-skills`를 명시적으로 참조하도록 한 문장으로 위임한다. orbit skillify의 고유 가치는 생명주기 통합(트리거·라우팅·자동발견)에 한정한다. 이로써 superpowers와 범위가 겹치지 않는다.

**메모리 승격 대상:** ADR-1(단일 문서)·ADR-2(reviewer감지/architect추출/leader라우팅 + 3회 규칙)·ADR-3(네이티브 디스커버리, 무훅)·ADR-4(writing-skills 위임)는 작업 완료 후 프로젝트 메모리(`orbit_omc_comparison.md` 또는 신규 결정 노트)로 승격한다.

---

## leader.md 워크플로우 변경 여부

생명주기 핵심 흐름은 **불변**: `select → plan → approve → build → Triple Crown → done`. skillify는 새 *필수* 단계가 아니라 **done 직후의 선택적 옵트인 분기**다. leader.md에는 "Triple Crown 통과 후, reviewer가 반복 패턴(3회 규칙) 신호를 보고하면 leader가 architect에 skillify 추출을 위임할 수 있다"는 *기회 단계* 한 단락만 추가한다. 기본 경로는 변하지 않는다.

---

## File Structure

- Create: `plugins/orbit-base/skills/skillify/SKILL.md` — skillify 스킬(트리거 기준·라우팅·결과물 형식 명세·자동발견·writing-skills 위임)
- Modify: `plugins/orbit-base/skills/using-orbit/SKILL.md` — 생명주기 섹션에 "skillify = done 후 선택적 추출 분기" 1단락 + Quick Reference에 skillify 행 추가
- Modify: `plugins/orbit-base/agents/leader.md` — Triple Crown 후 skillify 기회 단계(옵트인) 명시
- Modify: `plugins/orbit-base/agents/reviewer.md` — 반복 패턴(3회 규칙) 감지·보고 책임 1줄 추가
- Verify-only(수정 없음): `agents/architect.md`(skillify는 별도 슬롯 없이 architect의 기존 "패턴 문서화·메모리 승격" 책임 안에서 동작), `.claude-plugin/plugin.json`, `hooks/hooks.json`, `hooks/*.sh`, `CLAUDE.md`

신규 1파일 + 정렬 3파일. 각 파일은 동일 불변식("skillify = 3회 규칙 트리거 → reviewer 감지 → leader 라우팅 → architect 추출 → 네이티브 디스커버리, 무훅, authoring은 writing-skills 위임")을 표현한다. 표면별 독립 테스트 사이클을 가지므로 4 태스크로 분할한다.

---

## 검증 전략 (전체)

코드가 아닌 프롬프트/스킬 문서 작업이므로 단위 테스트 대신 **grep 기반 텍스트 단언**과 **frontmatter 유효성·디스커버리 정합성·도메인 순수성 게이트**로 검증한다. 각 태스크는 다음을 만족한다:
1. 의도한 불변식 문자열 존재(positive assertion)
2. 신규 SKILL.md frontmatter가 디스커버리 규약 충족(`name` = 디렉터리명, `description` 존재)
3. 도메인 순수성 위반 0건(프로젝트명 하드코딩 없음)
4. 신규 훅·매니페스트·에이전트 파일 변경 0(에이전트는 *수정*만, 신규 추가 0)

---

## Task 1: skillify 스킬 정의 (`skills/skillify/SKILL.md`)

**Files:**
- Create: `plugins/orbit-base/skills/skillify/SKILL.md`

**Interfaces:**
- Consumes: 없음(신규 단독 문서)
- Produces: skillify 규약의 단일 진실 출처. Task 2~4가 이 문서의 핵심 용어와 정합해야 함. 합의 용어(verbatim, 네 파일 공통):
  - 트리거: `Rule of Three` (3회 규칙)
  - 라우팅: `reviewer detects → leader routes → architect extracts`
  - 자동발견: `native skill discovery` (무훅)

- [ ] **Step 1: 검증 단언 스크립트 작성 (실패 baseline)**

작성: `/tmp/omc3-verify.sh`

```bash
#!/bin/bash
# OMC-3 skillify 텍스트 단언 — 신규 스킬 + 3표면 정렬 검증
set -u
BASE="/Users/dh/Project/orbit/plugins/orbit-base"
fail=0

ckpresent() { # file pattern label
  if grep -qF "$2" "$1" 2>/dev/null; then echo "ok   [$3] $1"; else echo "FAIL [$3] $1: missing «$2»"; fail=1; fi
}

# Task1 skillify SKILL.md 존재 + 핵심 절
SK="$BASE/skills/skillify/SKILL.md"
if [ -f "$SK" ]; then echo "ok   [T1-exists] $SK"; else echo "FAIL [T1-exists] $SK absent"; fail=1; fi
ckpresent "$SK" "name: skillify" T1-name
ckpresent "$SK" "Rule of Three" T1-ruleof3
ckpresent "$SK" "reviewer detects" T1-route
ckpresent "$SK" "leader routes" T1-route2
ckpresent "$SK" "architect extracts" T1-route3
ckpresent "$SK" "native skill discovery" T1-discovery
ckpresent "$SK" "writing-skills" T1-delegate
ckpresent "$SK" "skills/<" T1-pathspec

# Task2 using-orbit 정렬
ckpresent "$BASE/skills/using-orbit/SKILL.md" "skillify" T2-skill-ref
ckpresent "$BASE/skills/using-orbit/SKILL.md" "Rule of Three" T2-ruleof3

# Task3 leader 정렬
ckpresent "$BASE/agents/leader.md" "skillify" T3-leader

# Task4 reviewer 정렬
ckpresent "$BASE/agents/reviewer.md" "Rule of Three" T4-reviewer

# Global: 도메인 순수성
if grep -rEiq 'oremi|orbit-dev' "$BASE"; then echo "FAIL purity: project name found"; fail=1; else echo "ok   purity (0 hits)"; fi
# 신규 에이전트 미추가 (정확히 5)
n=$(ls "$BASE/agents/"*.md | wc -l | tr -d ' '); [ "$n" = "5" ] && echo "ok   5 agent files" || { echo "FAIL agent count=$n (expected 5)"; fail=1; }
# frontmatter: skillify name == 디렉터리명
if [ -f "$SK" ]; then
  fmname=$(awk -F': ' '/^name:/{print $2; exit}' "$SK" | tr -d ' \r')
  [ "$fmname" = "skillify" ] && echo "ok   frontmatter name=skillify" || { echo "FAIL frontmatter name=«$fmname»"; fail=1; }
fi
# 신규 훅/매니페스트 변경 0
( cd /Users/dh/Project/orbit && git status --porcelain plugins/orbit-base/hooks/ plugins/orbit-base/.claude-plugin/plugin.json | grep -q . ) && { echo "FAIL hooks/manifest changed"; fail=1; } || echo "ok   hooks/manifest untouched"

exit $fail
```

- [ ] **Step 2: 스크립트 실행해 실패 확인**

Run: `bash /tmp/omc3-verify.sh`
Expected: T1-exists 이하 다수 `FAIL`(아직 파일 없음). purity/5-agents/hooks-untouched는 `ok`. 종료코드 1.

- [ ] **Step 3: skillify SKILL.md 작성**

작성: `plugins/orbit-base/skills/skillify/SKILL.md` (아래 전문 그대로)

````markdown
---
name: skillify
description: Use after a task completes when the same procedure or solution has recurred across three or more separate tasks (Rule of Three). Extracts the recurring pattern into a reusable, auto-discoverable project skill. Defines the lifecycle trigger, routing, and output format — delegates authoring craft to writing-skills.
---

# Skillify — Extract Recurring Solutions into Skills

Skillify is Orbit's lifecycle convention for turning a repeatedly-solved problem into a permanent, auto-discoverable skill. It defines **when** extraction starts, **who** does each step, **what** the output must look like, and **how** the result is auto-discovered. It does not re-teach skill-authoring craft — that belongs to `superpowers:writing-skills`.

## When to Extract: The Rule of Three

Extract only when the **same** procedure, fix, or technique has been applied in **three or more separate tasks**. One or two occurrences may be coincidence — do not extract (YAGNI). Extract reusable techniques, patterns, and tool usages — never a narrative of how one problem was solved once.

Signals that meet the Rule of Three:
- The same multi-step procedure was re-derived from scratch in three tasks.
- The reviewer flagged the same class of fix in three separate Triple Crown reviews.
- Three plans contained a near-identical setup/scaffolding sequence.

## Who Does What (hub-and-spoke routing)

Skillify never bypasses the leader. The routing is:

`reviewer detects → leader routes → architect extracts → builder writes`

| Step | Agent | Action |
|------|-------|--------|
| Detect | reviewer | During or after Triple Crown, recognizes a Rule-of-Three signal and reports it to the leader as text. |
| Route | leader | Decides whether the pattern is worth extracting; if so, dispatches the architect to draft the skill. No reviewer→architect direct contact. |
| Extract | architect | Drafts the skill content (proposal only — does not write product files directly). Loads `superpowers:writing-skills` for authoring craft. |
| Write & approve | builder + Plan Approval | A new skill is a product change, so it follows the normal lifecycle: leader presents the architect's proposal for Plan Approval, then the builder writes the file. |

Skillify is an **optional opt-in branch after `done`** in the single-task lifecycle. It is never a required step and never blocks task completion.

## What the Output Must Look Like (format spec)

Every extracted skill is a project skill that follows the Orbit skill convention:

```
skills/<skill-name>/SKILL.md
```

- The directory name and the frontmatter `name` must match and be kebab-case.
- frontmatter has exactly two fields: `name` and `description`. Skills carry no `model:` field (only agents do).
- `description` MUST state *when* the skill applies — this is what drives auto-discovery (see below).
- Keep domain values as slots (`{{...}}`) when the skill is domain-agnostic; never hardcode a specific project name.
- Add a `references/` subdirectory only if the body grows too long to hold in one read (YAGNI otherwise).

Example skeleton:

```markdown
---
name: <skill-name>
description: Use when <trigger situation> to <outcome>.
---

# <Skill Title>

<one-paragraph overview>

## <Steps or reference content>
```

## How It Is Auto-Discovered (native, no hook)

Auto-injection requires **no custom hook**. Claude Code natively indexes every `skills/<name>/SKILL.md` by its frontmatter `name`/`description` and loads the skill when the model meets a situation matching the `description`. This is **native skill discovery**.

Therefore the only requirement skillify enforces for discoverability is a precise, trigger-describing `description`. Do not add SubagentStart/UserPromptSubmit hooks to force injection — that would break in environments without hooks (Codex, Gemini) and duplicate native discovery.

## Authoring Craft Is Delegated

Skillify defines the lifecycle integration only. For *how to write a skill well* — observing baseline failure, writing the SKILL.md, and pressure-testing it (TDD for skills) — use `superpowers:writing-skills`. Do not duplicate that guidance here.

## Quick Reference

| Term | Meaning |
|------|---------|
| Rule of Three | Extract only after the same solution recurs in 3+ separate tasks |
| Routing | reviewer detects → leader routes → architect extracts → builder writes |
| native skill discovery | Auto-injection via SKILL.md frontmatter; no custom hook |
| opt-in branch | Skillify is optional after `done`; never blocks completion |
````

- [ ] **Step 4: 단언 재실행 (T1 통과 확인)**

Run: `bash /tmp/omc3-verify.sh`
Expected: 모든 `T1-*` 줄 `ok`, frontmatter name=skillify `ok`. T2~T4는 여전히 FAIL(다음 태스크). purity/5-agents/hooks-untouched `ok`.

- [ ] **Step 5: 커밋**

```bash
cd /Users/dh/Project/orbit
git add plugins/orbit-base/skills/skillify/SKILL.md
git commit -m "feat(base): skillify 스킬 정의 추가 — 반복 패턴 추출 규약 (OMC-3)"
```

---

## Task 2: using-orbit/SKILL.md — skillify를 생명주기 오리엔테이션에 반영

**Files:**
- Modify: `plugins/orbit-base/skills/using-orbit/SKILL.md`

**Interfaces:**
- Consumes: Task 1의 합의 용어(`Rule of Three`, 라우팅 문구)
- Produces: 프레임워크 사용자 대상 "skillify = done 후 선택적 추출 분기" 오리엔테이션. Task 3·4가 동일 용어 사용.

- [ ] **Step 1: Single-Task Lifecycle 절에 skillify 분기 단락 추가**

`using-orbit/SKILL.md` `## Single-Task Lifecycle` 섹션에서, `Simple questions, meta tasks...` 단락(L39) **바로 뒤**에 다음 단락을 추가:

```
### Optional Branch: Skillify (after Done)

After a task is done, an optional branch may fire. When the **Rule of Three** is met — the same procedure or fix has recurred across three or more separate tasks — the reviewer reports the signal to the leader, who may route the architect to extract the pattern into a reusable skill (`reviewer detects → leader routes → architect extracts → builder writes`). This is never required and never blocks completion. See the `skillify` skill for the trigger, routing, and output format; skill-authoring craft is delegated to superpowers `writing-skills`.
```

- [ ] **Step 2: Quick Reference 표에 skillify 행 추가**

`using-orbit/SKILL.md` `## Quick Reference` 표(마지막 `.orbit/` 행 뒤)에 다음 행을 추가:

```
| skillify | Optional after-done branch: extract a Rule-of-Three recurring solution into a reusable skill |
```

- [ ] **Step 3: 단언 재실행**

Run: `bash /tmp/omc3-verify.sh`
Expected: `ok [T2-skill-ref]`, `ok [T2-ruleof3]`. T3~T4 FAIL. globals `ok`.

- [ ] **Step 4: 커밋**

```bash
cd /Users/dh/Project/orbit
git add plugins/orbit-base/skills/using-orbit/SKILL.md
git commit -m "docs(base): using-orbit에 skillify 선택 분기 반영 (OMC-3)"
```

---

## Task 3: leader.md — Triple Crown 후 skillify 기회 단계(옵트인) 명시

**Files:**
- Modify: `plugins/orbit-base/agents/leader.md`

**Interfaces:**
- Consumes: Task 1의 라우팅(leader가 architect에 위임), Task 2의 생명주기 분기
- Produces: leader가 skillify 라우팅 결정권자임을 명시 — Task 4(reviewer)가 "leader에 보고" 정합.

- [ ] **Step 1: leader.md Workflow에 skillify 기회 단계 추가**

`leader.md`의 워크플로우 설명(단일 작업 생명주기를 기술한 섹션) 끝, `done` 단계 직후에 다음 단락을 추가. (정확한 삽입 지점: 워크플로우 코드블록 또는 그 직후 산문 단락의 끝 — Triple Crown/done을 설명한 위치.)

```
**Optional skillify branch (after done):** If the reviewer reports a Rule-of-Three signal — the same procedure or fix recurring across three or more tasks — the leader may dispatch the architect to extract the pattern into a reusable skill. The leader is the sole router here (reviewer never contacts the architect directly). Writing the new skill follows the normal lifecycle: the architect proposes, the leader runs Plan Approval, the builder writes the file. This branch is optional and never blocks task completion. See the skillify skill.
```

- [ ] **Step 2: 단언 재실행**

Run: `bash /tmp/omc3-verify.sh`
Expected: `ok [T3-leader]`. T4 FAIL. globals `ok`.

- [ ] **Step 3: 커밋**

```bash
cd /Users/dh/Project/orbit
git add plugins/orbit-base/agents/leader.md
git commit -m "feat(base): leader에 skillify 옵트인 기회 단계 추가 (OMC-3)"
```

---

## Task 4: reviewer.md — Rule of Three 반복 패턴 감지·보고 책임 추가

**Files:**
- Modify: `plugins/orbit-base/agents/reviewer.md`

**Interfaces:**
- Consumes: Task 1의 트리거(`Rule of Three`), Task 3의 라우팅(leader에 보고)
- Produces: reviewer가 skillify 신호 감지원임을 선언 — 말단(추가 소비자 없음).

- [ ] **Step 1: reviewer.md에 Rule of Three 감지 책임 추가**

`reviewer.md`의 책임/원칙 목록(Triple Crown 조율 책임을 기술한 섹션)에 다음 항목을 추가. (정확한 삽입 지점: Core Responsibilities 또는 Working Principles 목록 끝.)

```
- Watch for the Rule of Three: when the same procedure or class of fix has recurred across three or more separate tasks, report it to the leader as a skillify candidate. The reviewer only detects and reports — extraction is routed by the leader to the architect. Reporting is optional and never blocks the current task's completion verdict.
```

- [ ] **Step 2: 단언 재실행 (전체 통과)**

Run: `bash /tmp/omc3-verify.sh`
Expected: 모든 줄 `ok`. 종료코드 0.

- [ ] **Step 3: 도메인 순수성 + 디스커버리 정합성 + 매니페스트 불변 최종 확인**

Run:
```bash
grep -rEi 'oremi|orbit-dev' /Users/dh/Project/orbit/plugins/orbit-base/ || echo "PURITY OK (0)"
head -4 /Users/dh/Project/orbit/plugins/orbit-base/skills/skillify/SKILL.md
ls -d /Users/dh/Project/orbit/plugins/orbit-base/skills/*/ 
git -C /Users/dh/Project/orbit status --porcelain plugins/orbit-base/.claude-plugin/plugin.json plugins/orbit-base/hooks/
```
Expected: `PURITY OK (0)`; skillify SKILL.md frontmatter에 `name: skillify`·`description:` 보임; `skills/skillify/`·`skills/using-orbit/` 두 디렉터리 존재; plugin.json/hooks/ 변경 없음(빈 출력).

- [ ] **Step 4: 커밋**

```bash
cd /Users/dh/Project/orbit
git add plugins/orbit-base/agents/reviewer.md
git commit -m "feat(base): reviewer에 Rule of Three 패턴 감지·보고 책임 추가 (OMC-3)"
```

---

## 측정 가능한 성공 기준

1. `bash /tmp/omc3-verify.sh` 종료코드 0 (T1~T4 단언 전부 `ok`).
2. `plugins/orbit-base/skills/skillify/SKILL.md` 존재, frontmatter `name: skillify`(디렉터리명 일치) + `description` 보유, `model:` 필드 부재.
3. skillify SKILL.md가 네 규약을 모두 명시: 트리거(Rule of Three), 라우팅(reviewer→leader→architect→builder), 결과물 형식(`skills/<name>/SKILL.md`, name=디렉터리명, description=트리거 기술), 자동발견(native skill discovery, 무훅), authoring 위임(writing-skills).
4. `plugins/orbit-base/agents/`에 **정확히 5개** `.md`(신규 에이전트 0 — ADR-1/ADR-2는 기존 역할 재사용).
5. `grep -rEi 'oremi|orbit-dev' plugins/orbit-base/` → 0건.
6. `plugin.json`·`hooks/` diff 없음 (매니페스트·훅 불변 — ADR-3).
7. 4개 표면이 동일 불변식(Rule of Three / reviewer감지·leader라우팅·architect추출 / native discovery 무훅 / writing-skills 위임)을 일관되게 표현.

## Triple Crown 검증 매핑 (사후, reviewer 조율)

- **① 완성도(GSD):** Task 1~4 체크박스 + 성공기준 1~7 충족.
- **② 동작:** 스킬/프롬프트 문서이므로 런타임 대신 (a) `omc3-verify.sh` 종료코드 0, (b) skillify SKILL.md frontmatter 유효성(`head -4`로 name/description 손상 없음 — Claude Code 디스커버리가 인덱싱 가능한 형식), (c) `skills/` 하위 디렉터리 구조가 using-orbit과 동일 패턴인지 확인.
- **③ 품질:** superpowers requesting-code-review로 4개 diff 검토 — 불변식 표현의 모순/중복, writing-skills와의 범위 중복 재발 여부, 도메인 순수성. architect 아키 일관성 렌즈로 ADR-3(무훅 디스커버리)이 hooks.json/graceful-degradation 표(using-orbit)와 정합한지, 신규 스킬 디렉터리가 매니페스트(plugin.json은 skills를 명시 열거하지 않음 — 자동 디스커버리)와 정합한지 확인.

---

## Self-Review (작성자 점검)

1. **스펙 커버리지:** 조사항목 1(기존 스킬 형식)→실측 1 + Task 1 format spec. 항목 2(skillify 본질: 무엇/누가/자동주입)→ADR-2(누가/무엇)·ADR-3(자동주입). 항목 3(결과물 형태 a/b/c)→ADR-1(c, 단일 문서). 항목 4(허브앤스포크·생명주기 통합, leader.md 변경)→ADR-2 라우팅 + Task 3 + 워크플로우 변경 절. 항목 5(도메인 순수성·SubagentStop)→Global Constraints + ADR-3 영향 절. 항목 6(테스트/성공기준)→검증 전략 + 성공기준 7개. 핵심 질문 ①(writing-skills 차별화)→ADR-4. 핵심 질문 ②(자동주입 디스커버리 vs 훅)→ADR-3(디스커버리, 무훅). 누락 없음.
2. **플레이스홀더 스캔:** 모든 편집 단계가 verbatim 문자열 포함. skillify SKILL.md 전문 제공. TBD/TODO 없음. (삽입 지점은 "정확한 지점" 주석으로 명시 — 기존 파일의 가변 줄번호 의존 회피.)
3. **타입/문구 일관성:** 합의 용어 `Rule of Three`, `reviewer detects → leader routes → architect extracts`, `native skill discovery`, `writing-skills` 가 Task 1(발신)·2·3·4에서 동일 사용. omc3-verify.sh 단언이 이 문자열들을 그대로 검사. 라우팅 4단계(builder writes 포함)는 ADR-2와 SKILL.md 표·using-orbit·leader 모두에서 일치.
