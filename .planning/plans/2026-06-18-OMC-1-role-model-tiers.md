# OMC-1 역할별 모델 티어 명시 — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 배포물 `plugins/orbit-base/agents/` 에이전트 프롬프트 파일들의 frontmatter `model:` 필드를 역할별 모델 티어 정책(researcher=haiku, builder/leader=sonnet, architect/reviewer=opus)에 맞춰 정렬한다.

**Architecture:** orbit-base 에이전트는 마크다운 파일이며 YAML frontmatter에 `model:` 별칭(`haiku`/`sonnet`/`opus`)을 둔다. Claude Code는 이 별칭을 인식하고, 미인식 값은 무음 폴백 없이 에러로 거부한다. 본 작업은 frontmatter 한 줄만 다루는 순수 설정 정렬이며, 코드·훅·매니페스트는 변경하지 않는다.

**Tech Stack:** Markdown + YAML frontmatter, bash/grep/awk (검증), Claude Code 에이전트 로딩.

## Global Constraints

- 도메인 순수성: `plugins/orbit-base/` 내 파일에 특정 프로젝트명(oremi, orbit-dev, memoriterx 등) 하드코딩 금지. (모델 별칭은 프로젝트명이 아니므로 위반 아님.)
- 모듈 경계: 배포물 `plugins/orbit-base/`만 수정. 개발팀 설정 `.claude/agents/`는 **참고 전용 — 수정 금지**.
- 매니페스트 정합성: `plugins/orbit-base/.claude-plugin/plugin.json`이 단일 일관성 기준. 본 작업은 이 파일을 변경하지 않는다.
- `model:` 허용값(authoritative, Claude Code model-config 문서 확인됨): 바 별칭 `haiku`/`sonnet`/`opus` 유효. 미인식 별칭은 에러로 거부(무음 폴백 없음).
- 커밋 접두사 `feat/fix/chore/docs/refactor:` 사용. Co-Authored-By 줄 금지.

---

## 사전 조사 결과 (실측 — roadmap 가정과의 차이)

roadmap OMC-1은 "에이전트 파일 4종 업데이트"를 가정하나, 실측 결과는 다르다.

**실제 `plugins/orbit-base/agents/` 파일은 5종** (leader 포함). 현재 frontmatter 상태:

| 파일 | name | 현재 `model:` | 목표 티어 | 변경 필요? |
|------|------|--------------|-----------|-----------|
| `architect.md` | architect | `opus` | opus | 아니오 (이미 일치) |
| `builder.md` | builder | `sonnet` | sonnet | 아니오 (이미 일치) |
| `reviewer.md` | reviewer | `opus` | opus | 아니오 (이미 일치) |
| `researcher.md` | researcher | `sonnet` | **haiku** | **예 — 유일한 실변경** |
| `leader.md` | leader | `sonnet` | sonnet (ADR-1) | 아니오 (이미 일치) |

**결론:** 실제 코드 변경이 필요한 파일은 `researcher.md` **단 1종**(`sonnet` → `haiku`). 나머지는 이미 목표 티어와 일치하므로 검증만 한다.

참고: 개발팀 `.claude/agents/researcher.md`는 이미 `model: haiku`. 즉 "dev팀은 이미 적용됨"은 사실이며, 배포물 researcher만 dev팀 기준에서 뒤처져 있었다.

### ADR-1: leader 모델 티어 = sonnet (유지)

roadmap은 leader를 언급하지 않으나 실파일에 존재한다. 합리적 기본값으로 **sonnet 유지**를 결정한다.
- 근거: leader는 조율·게이트·의존성 판단을 수행하는 오케스트레이터로, haiku의 경량 탐색 수준보다는 판단력이 필요하나 architect/reviewer 수준의 심층 설계·검토는 아니다. sonnet이 적정.
- 현재 값이 이미 `sonnet`이므로 무변경. 본 ADR은 "leader는 이번 정책에서 의도적으로 sonnet으로 유지됨"을 기록할 뿐이다.

### ADR-2: 별칭 형식 = 바 별칭(`haiku`/`sonnet`/`opus`) 사용

정식 model id(`claude-...`) 대신 바 별칭을 사용한다.
- 근거: 도메인 무관 배포물은 특정 모델 버전 id에 묶이면 모델 세대 교체 시 마다 수정이 필요하다. 별칭은 Claude Code가 당대 최신 티어로 해석하므로 배포물 수명에 유리하다. 기존 5개 파일 및 dev팀 파일 모두 바 별칭을 사용 중 — 컨벤션 일치.

---

## File Structure

- Modify: `plugins/orbit-base/agents/researcher.md` — frontmatter `model:` 줄 1개 (`sonnet` → `haiku`)
- Verify-only (수정 없음): `plugins/orbit-base/agents/{architect,builder,reviewer,leader}.md`

단일 파일 변경이므로 작업은 1개 태스크로 충분하다(검증·도메인 순수성 확인·커밋을 해당 태스크에 폴딩).

---

### Task 1: researcher 에이전트 모델 티어를 haiku로 정렬

**Files:**
- Modify: `plugins/orbit-base/agents/researcher.md` (frontmatter `model:` 줄)

**Interfaces:**
- Consumes: 없음 (frontmatter 스키마는 plugin.json이 아니라 Claude Code 에이전트 스키마가 규정; `name`/`description`/`model` 슬롯)
- Produces: 후속 작업이 의존하는 산출물 없음. Claude Code가 researcher 서브에이전트를 haiku로 로드하게 됨.

- [ ] **Step 1: 변경 전 현재 상태를 확인 (실패 조건 정의)**

Run:
```bash
grep -n '^model:' /Users/dh/Project/orbit/plugins/orbit-base/agents/researcher.md
```
Expected (변경 전): `2:model: sonnet` (행 번호는 다를 수 있음)

이 출력이 `model: haiku`이면 이미 적용된 것이니 Step 2~3을 건너뛰고 Step 4 검증으로 진행한다.

- [ ] **Step 2: frontmatter `model:` 값을 haiku로 변경**

`plugins/orbit-base/agents/researcher.md`의 frontmatter에서 정확히 다음 한 줄을

```yaml
model: sonnet
```

다음으로 교체한다:

```yaml
model: haiku
```

(frontmatter의 `name: researcher`, `description:` 줄은 건드리지 않는다.)

- [ ] **Step 3: 변경이 반영됐는지 확인**

Run:
```bash
grep -n '^model:' /Users/dh/Project/orbit/plugins/orbit-base/agents/researcher.md
```
Expected: `model: haiku` 한 줄만 출력 (PASS)

- [ ] **Step 4: 5개 파일 전체 티어 정책 일괄 검증**

Run:
```bash
cd /Users/dh/Project/orbit && for f in architect builder leader researcher reviewer; do
  printf '%-12s ' "$f"; grep -m1 '^model:' plugins/orbit-base/agents/$f.md
done
```
Expected (정확히 이 매핑):
```
architect    model: opus
builder      model: sonnet
leader       model: sonnet
researcher   model: haiku
reviewer     model: opus
```

- [ ] **Step 5: frontmatter 구조 유효성 확인 (각 파일 정확히 2개의 `---` 구분자, model 슬롯 1개)**

Run:
```bash
cd /Users/dh/Project/orbit && for f in architect builder leader researcher reviewer; do
  d=$(grep -c '^---$' plugins/orbit-base/agents/$f.md)
  m=$(grep -c '^model:' plugins/orbit-base/agents/$f.md)
  echo "$f: delimiters=$d model_lines=$m"
done
```
Expected: 각 파일 `delimiters=2 model_lines=1` (frontmatter 깨짐·중복 없음 확인)

- [ ] **Step 6: 모델 별칭이 허용값인지 확인 (미인식 별칭 방지)**

Run:
```bash
cd /Users/dh/Project/orbit && grep -h '^model:' plugins/orbit-base/agents/*.md \
  | sed 's/^model: *//' | sort -u
```
Expected: `haiku`, `opus`, `sonnet` 세 값만 출력. 그 외 값이 보이면 오타이므로 수정한다.
(근거: Claude Code는 미인식 model 별칭을 무음 폴백 없이 에러로 거부함 — model-config 문서 확인.)

- [ ] **Step 7: 도메인 순수성 회귀 확인 (SubagentStop 게이트 위반 없음)**

Run:
```bash
cd /Users/dh/Project/orbit && grep -rniE 'oremi|orbit-dev|memoriterx' plugins/orbit-base/agents/ \
  && echo "VIOLATION" || echo "CLEAN"
```
Expected: `CLEAN` (0건). 모델 별칭은 프로젝트명이 아니므로 도메인 순수성에 영향 없음을 확인.

참고: `plugins/orbit-base/hooks/quality-gate.sh`는 프로젝트-로컬 `.orbit/quality-gate.sh`만 위임 실행하며 frontmatter를 파싱하지 않는다. 따라서 본 변경은 SubagentStop 품질 게이트를 트립하지 않는다 (영향 없음 — 검증 불필요하나 도메인 순수성 grep으로 안전 확인).

- [ ] **Step 8: 커밋**

Run:
```bash
cd /Users/dh/Project/orbit && git add plugins/orbit-base/agents/researcher.md
git commit -m "feat(base): set researcher agent model tier to haiku (OMC-1)"
```

(architect/builder/leader/reviewer는 이미 목표 티어와 일치하여 변경 사항이 없으므로 본 커밋에는 researcher.md만 포함된다.)

---

## 영향 범위

- **변경 파일:** `plugins/orbit-base/agents/researcher.md` 1개 (frontmatter 한 줄).
- **무변경(검증만):** 나머지 4개 에이전트 파일 — 이미 목표 티어 일치.
- **훅:** 영향 없음. `quality-gate.sh`는 frontmatter 비파싱. hooks.json 변경 없음.
- **매니페스트:** `plugin.json` 변경 없음. 스키마 정합성 유지.
- **도메인 순수성:** 위반 없음 (모델 별칭은 도메인값 아님). grep 0건 유지.
- **모듈 경계:** 배포물 `plugins/`만 수정. `.claude/` 미접촉.
- **dev팀:** 영향 없음 (`.claude/agents/researcher.md`는 이미 haiku, 본 작업 대상 아님).

## 테스트/검증 전략

frontmatter는 빌드·런타임 테스트 대상이 아니므로 **정적 검증**으로 충족한다 (위 Task의 Step 4~7):
1. 티어 매핑 일치 (Step 4).
2. frontmatter 구조 무결성 — 구분자 2개, model 줄 1개 (Step 5).
3. 별칭 허용값 집합 {haiku, opus, sonnet} 외 값 없음 (Step 6) — Claude Code가 미인식 별칭을 에러 거부하므로 오타 = 런타임 로드 실패와 동치.
4. 도메인 순수성 회귀 0건 (Step 7).

런타임 인식 확인(선택, Triple Crown ② 동작 단계에서 reviewer가 수행 가능): Claude Code에서 researcher 서브에이전트를 1회 파견해 정상 로드(에러 없이 기동)되는지 관찰. 미인식 별칭이었다면 로드 단계에서 에러가 표출된다.

## 성공 기준 (측정 가능)

1. `grep -m1 '^model:' plugins/orbit-base/agents/researcher.md` → `model: haiku`.
2. Step 4 일괄 검증 출력이 5행 모두 목표 매핑과 정확히 일치.
3. Step 5: 5개 파일 모두 `delimiters=2 model_lines=1`.
4. Step 6: 별칭 집합이 `{haiku, opus, sonnet}` 정확히 일치 (이외 값 0).
5. Step 7: 도메인 순수성 grep 0건 (`CLEAN`).
6. researcher.md만 포함한 단일 커밋 생성 (`git show --stat` 확인 가능).
7. roadmap `.planning/roadmap.md`의 OMC-1 체크박스 완료 표시 (리드가 처리하는 메타 단계).
