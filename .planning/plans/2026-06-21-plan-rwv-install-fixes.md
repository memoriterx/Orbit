# RWV-1 신규자 설치 차단점 보수 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 실사용 검증(RWV-1)에서 발굴된 신규자 설치 차단점 2건(README 설치 URL 플레이스홀더 BLOCKER, orbit-init.md `CLAUDE_PLUGIN_ROOT` 무음 실패 + 거짓 주석 MAJOR)을 thin하게 보수하여 README v0.6.2 Quickstart를 그대로 따라가는 신규자가 막히지 않게 한다.

**Architecture:** 두 보수는 성격이 다른 두 배포물에 걸쳐 있어 **별도 커밋**으로 분리한다. (1) README의 마켓플레이스 add 플레이스홀더 `<orbit-repo-url>`를 `setup-orbit.sh`가 실제 사용하는 인자 `memoriterx/Orbit`로 교체. (2) orbit-init.md 인라인 bash에 `CLAUDE_PLUGIN_ROOT` **fail-loud 가드**를 추가하여 미설정 시 무음 `cp` 실패 대신 명확한 에러+수동 export 안내로 중단시키고, 거짓 "자동 감지" 주석을 사실대로 정정한다.

**Tech Stack:** Markdown(슬래시 커맨드 정의·README), 인라인 bash. 신규 의존성·런타임 없음.

## Global Constraints

- **구현 금지 영역 아님 — 이 플랜은 builder가 실행**: 본 문서는 architect 산출 플랜. 리드 승인 후 builder가 구현.
- **커밋 분리(필수)**: BLOCKER(README, 루트 배포물)와 MAJOR(orbit-init.md, `plugins/orbit-base/` 배포물)는 **별도 커밋**. 두 보수를 한 커밋에 섞지 말 것.
- **커밋 접두사**: `fix:` 또는 `docs:` 사용. Co-Authored-By 줄 절대 금지.
- **도메인 순수성 불변식**: 보수 후 `grep -rniE 'oremi|orbit-dev' plugins/orbit-base/` = **0** 유지. (현재 baseline = 0, 검증됨.) `memoriterx/Orbit`는 루트 README에만 들어가며 — 루트 README는 orbit 자신의 프로젝트 readme이므로 실 repo 하드코딩이 정상(도메인 누출 아님). `plugins/orbit-base/` 내부에는 절대 repo명·프로젝트명 하드코딩 금지.
- **실값 출처(단일 진실)**: 마켓플레이스 add 인자의 정답 형식은 `setup-orbit.sh`다 — `plugins/orbit-base/scripts/setup-orbit.sh:148,163`이 `memoriterx/Orbit`를 사용. README는 이와 **글자 단위로 일치**해야 한다.
- **`/plugin install orbit-base`(README:157)는 변경 금지** — 플러그인명이 `.claude-plugin/marketplace.json`의 `"name": "orbit-base"`와 이미 일치(검증됨).
- **`.claude-plugin/plugin.json`↔`.codex-plugin/plugin.json` 비대칭은 건드리지 말 것** — 알려진 비이슈([[orbit-plugin-discovery]] 메모리, QA-1 확정). 동기화 금지.

---

## Discovery 결과 (이 플랜의 근거 — builder는 읽기만)

- **BLOCKER 실값 확정**: `plugins/orbit-base/scripts/setup-orbit.sh:148` `claude plugin marketplace add memoriterx/Orbit --scope ...`, 동 파일 `:163` 수동 안내 `/plugin marketplace add memoriterx/Orbit`. → README 교체값 = `memoriterx/Orbit`.
- **marketplace.json 정합**: `.claude-plugin/marketplace.json`의 plugin name = `orbit-base`(v0.6.2). README:157 `/plugin install orbit-base`와 일치.
- **MAJOR 근본 원인 확정(claude-code-guide 공식 문서 대조)**:
  - `CLAUDE_PLUGIN_ROOT`는 **훅·MCP/LSP·monitor 커맨드 컨텍스트에만** 공식 주입 보장. **슬래시 커맨드(.md) bash 컨텍스트에는 주입 보장 없음**([plugins-reference 환경변수 절], GitHub issue #9354로 알려진 한계).
  - 커맨드 인라인 bash는 **Claude가 Bash 툴로 실행** → env는 Claude Code 프로세스 환경에서 옴. 따라서 커맨드용 플러그인 루트 변수는 **존재하지 않으며**, `${BASH_SOURCE[0]}` 기반 자기-도출도 **인라인 bash라 통하지 않는다**(스크립트 파일이 아님).
  - 결과: `CLAUDE_PLUGIN_ROOT` 미설정 시 `PLUGIN_ROOT`가 빈 문자열 → `cp -n "/templates/..."`가 절대경로 `/templates/...`로 해석 → 소스 부재로 **무음 실패**, `.orbit/` 비어 생성되어 /orbit-init 전체가 사실상 실패.
  - **설계 결론(thin)**: 신뢰 가능한 fallback 도출 경로가 **없으므로** 후보(b)는 채택 불가. 후보(a) **fail-loud 가드** + 후보(c) **주석 정정**을 함께 채택. 무음 `cp` 실패를 빈-값 조기 차단으로 바꾸고, 거짓 자동 감지 주장 제거.
  - **선례**: `plugins/orbit-base/hooks/`(notify-done.sh, viewer-attach.sh, hooks.json)는 `CLAUDE_PLUGIN_ROOT`를 쓰지만 그건 **훅 컨텍스트라 주입이 보장**됨 — orbit-init은 커맨드라 보장 안 됨. 이 차이가 MAJOR의 핵심.

---

## File Structure

| 파일 | 책임 | 변경 |
|------|------|------|
| `README.md` | orbit 프로젝트 자체 readme. Quickstart·트러블슈팅 | Modify (BLOCKER, 커밋 1) |
| `plugins/orbit-base/commands/orbit-init.md` | `/orbit-init` 슬래시 커맨드 정의(.orbit/ 스캐폴딩 인라인 bash) | Modify (MAJOR, 커밋 2) |
| `docs/smoke-results.md` | 내부 dev 스모크 기록(배포물 아님) | (옵션 NIT — 아래 권고 참조, 기본 보류) |

---

## Success Criteria (측정 가능)

1. **SC-1 (BLOCKER)**: `grep -n '<orbit-repo-url>' README.md` → **0건**. (플레이스홀더 완전 제거.)
2. **SC-2 (BLOCKER)**: `grep -nc 'marketplace add memoriterx/Orbit' README.md` → **≥ 2**(Quickstart 본문 + 트러블슈팅). README의 `marketplace add` 인자가 `setup-orbit.sh:148`과 글자 단위로 일치.
3. **SC-3 (BLOCKER)**: README:157 `/plugin install orbit-base`는 변경 없음(diff에 미포함).
4. **SC-4 (MAJOR)**: `orbit-init.md`에서 "자동 감지된다" 거짓 주장 문구 제거 — `grep -n '자동 감지' plugins/orbit-base/commands/orbit-init.md` 가 거짓-주장 라인(:125)을 더 이상 반환하지 않음(또는 사실 정정 문구로 대체).
5. **SC-5 (MAJOR — 동작 입증)**: 미설정 케이스 시뮬레이션에서 fail-loud 가드가 **트리거됨**(Task 2 Step 5의 검증 스크립트가 비-0 exit + 명확한 에러 메시지 출력, `cp` 실행 안 됨). 설정 케이스에서는 가드 통과(정상 cp 경로).
6. **SC-6 (불변식)**: `grep -rniE 'oremi|orbit-dev' plugins/orbit-base/` → **0건**.
7. **SC-7 (커밋 분리)**: `git log --oneline -2`가 README 커밋과 orbit-init 커밋을 **별개**로 보여줌.

---

## Task 1: README 설치 URL 플레이스홀더 → 실값 (BLOCKER)

**Files:**
- Modify: `README.md:154` (Quickstart 1단계 코드블록)
- Modify: `README.md:290` (트러블슈팅 표의 동일 플레이스홀더)
- Test: 검증 grep(아래 Step). 자동화 테스트 프레임워크 없는 markdown — grep로 검증.

**Interfaces:**
- Consumes: `plugins/orbit-base/scripts/setup-orbit.sh:148,163`의 실 인자 `memoriterx/Orbit`(단일 진실).
- Produces: 후속 작업 없음(독립 변경).

**현재 상태(verbatim, 변경 전):**
- `README.md:154` → `/plugin marketplace add <orbit-repo-url>`
- `README.md:290` (트러블슈팅 표 셀 내부) → `... 마켓플레이스 미등록이면 \`/plugin marketplace add <orbit-repo-url>\` 먼저`

- [ ] **Step 1: 현재 플레이스홀더 위치를 fail-first로 확인 (변경 전 baseline)**

Run:
```bash
grep -n '<orbit-repo-url>' /Users/dh/Project/orbit/README.md
```
Expected: 2개 라인 출력(154, 290 근방). 이 출력이 보여야 교체 대상이 확정된다. 0건이면 이미 누군가 고친 것이니 중단하고 리드에 보고.

- [ ] **Step 2: Quickstart 코드블록(:154) 교체**

`README.md`에서 아래 정확한 문자열을 교체한다.

찾을 문자열:
```
/plugin marketplace add <orbit-repo-url>
```
바꿀 문자열:
```
/plugin marketplace add memoriterx/Orbit
```
(주의: 이 정확한 문자열은 :154에 1회 등장. 트러블슈팅 :290은 표 셀 안에 백틱과 함께 들어 있어 문맥이 다르므로 Step 3에서 별도 처리.)

- [ ] **Step 3: 트러블슈팅 표(:290) 교체**

`README.md:290` 표 셀에서 동일 플레이스홀더를 교체한다.

찾을 문자열(셀 일부, 고유):
```
마켓플레이스 미등록이면 `/plugin marketplace add <orbit-repo-url>` 먼저
```
바꿀 문자열:
```
마켓플레이스 미등록이면 `/plugin marketplace add memoriterx/Orbit` 먼저
```

- [ ] **Step 4: 교체 검증 (SC-1, SC-2, SC-3)**

Run:
```bash
echo "SC-1 (플레이스홀더 0건 기대):"
grep -n '<orbit-repo-url>' /Users/dh/Project/orbit/README.md; echo "exit=$? (1이면 0건=PASS)"
echo "SC-2 (실값 >=2 기대):"
grep -c 'marketplace add memoriterx/Orbit' /Users/dh/Project/orbit/README.md
echo "SC-3 (install 라인 불변 — 1건 기대):"
grep -c '/plugin install orbit-base' /Users/dh/Project/orbit/README.md
```
Expected:
- SC-1: 출력 없음, `exit=1` (플레이스홀더 0건 → PASS)
- SC-2: `2` 이상
- SC-3: `1` (변경 안 됨)

- [ ] **Step 5: 커밋 (README 단독 — 커밋 1)**

```bash
cd /Users/dh/Project/orbit
git add README.md
git commit -m "fix: replace install URL placeholder with memoriterx/Orbit in README"
```
(이 커밋에는 `README.md`만 포함. orbit-init.md 변경을 절대 함께 스테이징하지 말 것.)

---

## Task 2: orbit-init.md CLAUDE_PLUGIN_ROOT fail-loud 가드 + 거짓 주석 정정 (MAJOR)

**Files:**
- Modify: `plugins/orbit-base/commands/orbit-init.md` — Step 1 직후(:19 이후)에 가드 블록 삽입, 주석(:124-126) 정정
- Test: 미설정/설정 두 케이스 시뮬레이션 bash(아래 Step 5). 인라인 커맨드 bash라 단위테스트 프레임워크 없음 — 격리 시뮬레이션으로 동작 입증.

**Interfaces:**
- Consumes: 없음(커맨드 자체 수정).
- Produces: 가드는 이후 Step 3~5(`cp -n "$PLUGIN_ROOT/templates/..."`)와 Step 7 안내(`${CLAUDE_PLUGIN_ROOT}/scripts/setup-orbit.sh`)가 의존하는 **불변식**(PLUGIN_ROOT 비어 있지 않음)을 보장.

**설계 의도(thin):** 신뢰 가능한 fallback 변수가 없으므로(Discovery 참조) 자동 도출을 시도하지 않는다. 빈 값을 **조기에 fail-loud로 차단**하고 사용자에게 정확한 export 방법을 안내한다. 무음 `cp` 실패(루트 절대경로 해석)를 명시적 중단으로 대체.

- [ ] **Step 1: 현재 거짓-주장 주석을 fail-first로 확인 (변경 전 baseline)**

Run:
```bash
grep -n '자동 감지' /Users/dh/Project/orbit/plugins/orbit-base/commands/orbit-init.md
```
Expected: `:125`(근방)에 "플러그인 마켓플레이스 설치 경로에서 자동 감지된다" 라인이 출력되어야 한다. 이게 정정 대상.

- [ ] **Step 2: Step 3(roadmap 복사) 앞에 fail-loud 가드 블록 삽입**

`plugins/orbit-base/commands/orbit-init.md`의 현재 `### Step 3: roadmap.md 복사` 헤더 직전에, **새 하위 절**을 삽입한다. (기존 Step 3의 `PLUGIN_ROOT="${CLAUDE_PLUGIN_ROOT}"` 라인은 가드 안으로 흡수하므로, 가드 도입 후 Step 3 코드블록의 그 라인은 **중복이 되어 제거**한다 — Step 3에서는 가드가 설정한 `$PLUGIN_ROOT`를 그대로 사용.)

삽입할 절(정확한 내용):
````markdown
### Step 2.5: PLUGIN_ROOT 확정 및 가드 (필수)

템플릿 파일은 플러그인 번들 안에 있으므로 `CLAUDE_PLUGIN_ROOT`가 필요하다.
**커맨드 컨텍스트에서 `CLAUDE_PLUGIN_ROOT` 주입은 공식 보장이 없다**(훅과 달리).
미설정 시 경로가 빈 문자열이 되어 `cp`가 루트 절대경로로 무음 실패하므로,
**빈 값이면 여기서 명확히 중단**한다(무음 실패 방지).

```bash
PLUGIN_ROOT="${CLAUDE_PLUGIN_ROOT}"
if [ -z "$PLUGIN_ROOT" ] || [ ! -d "$PLUGIN_ROOT/templates" ]; then
  echo "[orbit-init] ERROR: 플러그인 템플릿 경로를 찾을 수 없습니다." >&2
  echo "  CLAUDE_PLUGIN_ROOT 가 설정되지 않았거나 templates/ 디렉터리가 없습니다." >&2
  echo "  (커맨드 컨텍스트에서는 CLAUDE_PLUGIN_ROOT 자동 주입이 보장되지 않습니다.)" >&2
  echo "" >&2
  echo "  해결: 플러그인 설치 경로를 찾아 수동 지정 후 /orbit-init 재실행." >&2
  echo "    예) export CLAUDE_PLUGIN_ROOT=<orbit-base 플러그인 설치 디렉터리>" >&2
  echo "        # 설치 경로는 보통 ~/.claude/plugins/.../orbit-base 하위입니다." >&2
  exit 1
fi
echo "orbit-init plugin root: $PLUGIN_ROOT"
```

이 가드를 통과하면 `$PLUGIN_ROOT/templates/`가 실제로 존재함이 보장된다.
````

- [ ] **Step 3: 기존 Step 3 코드블록에서 중복 `PLUGIN_ROOT=` 라인 제거**

기존 `### Step 3: roadmap.md 복사`의 코드블록은 현재:
```bash
PLUGIN_ROOT="${CLAUDE_PLUGIN_ROOT}"
cp -n "$PLUGIN_ROOT/templates/roadmap.template.md" \
      "$PROJECT_ROOT/.orbit/roadmap.md"
echo "created: .orbit/roadmap.md"
```
첫 줄 `PLUGIN_ROOT="${CLAUDE_PLUGIN_ROOT}"`를 **삭제**하여 아래로 만든다(가드가 이미 설정·검증했으므로):
```bash
cp -n "$PLUGIN_ROOT/templates/roadmap.template.md" \
      "$PROJECT_ROOT/.orbit/roadmap.md"
echo "created: .orbit/roadmap.md"
```
(Step 4·Step 5의 `cp`는 이미 `$PLUGIN_ROOT`만 참조하므로 변경 불필요.)

- [ ] **Step 4: 거짓 주석(:124-126) 정정**

기존 주의사항(현재 :124-126):
```
- `cp -n` 사용으로 기존 `.orbit/` 파일은 절대 덮어쓰지 않는다.
- `CLAUDE_PLUGIN_ROOT` 미설정 시 플러그인 마켓플레이스 설치 경로에서 자동 감지된다.
  수동 지정 필요 시: `export CLAUDE_PLUGIN_ROOT=<경로>` 후 재실행.
- `.orbit/` 하위 파일은 `.gitignore`에 추가하거나 커밋해도 무방하다(팀 공유 가능).
```
아래로 교체(자동 감지 주장 제거, 사실 반영):
```
- `cp -n` 사용으로 기존 `.orbit/` 파일은 절대 덮어쓰지 않는다.
- 이 커맨드는 플러그인 번들의 `templates/`를 복사하므로 `CLAUDE_PLUGIN_ROOT`가 필요하다.
  커맨드 컨텍스트에서는 이 변수의 자동 주입이 보장되지 않는다(훅과 달리). 미설정이면
  Step 2.5 가드가 명확한 에러로 중단시킨다 — 안내대로 `export CLAUDE_PLUGIN_ROOT=<경로>` 후 재실행한다.
- `.orbit/` 하위 파일은 `.gitignore`에 추가하거나 커밋해도 무방하다(팀 공유 가능).
```

- [ ] **Step 5: 동작 입증 — 미설정/설정 양 케이스 시뮬레이션 (SC-5)**

가드 로직을 격리 추출해 두 케이스를 실행한다(인라인 커맨드라 직접 실행은 불가 → 동일 로직 격리 검증).

Run:
```bash
cd /tmp && rm -rf rwv1-guard-test && mkdir -p rwv1-guard-test && cd rwv1-guard-test

# 가드 로직 추출(orbit-init.md Step 2.5와 동일)
cat > guard.sh <<'EOF'
PLUGIN_ROOT="${CLAUDE_PLUGIN_ROOT}"
if [ -z "$PLUGIN_ROOT" ] || [ ! -d "$PLUGIN_ROOT/templates" ]; then
  echo "[orbit-init] ERROR: 플러그인 템플릿 경로를 찾을 수 없습니다." >&2
  exit 1
fi
echo "GUARD-PASS: $PLUGIN_ROOT"
EOF

echo "=== Case A: CLAUDE_PLUGIN_ROOT 미설정 (fail-loud 기대) ==="
( unset CLAUDE_PLUGIN_ROOT; bash guard.sh ); echo "exitA=$? (1 기대)"

echo "=== Case B: 빈 값 (fail-loud 기대) ==="
( CLAUDE_PLUGIN_ROOT="" bash guard.sh ); echo "exitB=$? (1 기대)"

echo "=== Case C: templates 없는 경로 (fail-loud 기대) ==="
( CLAUDE_PLUGIN_ROOT="/tmp/rwv1-guard-test/nope" bash guard.sh ); echo "exitC=$? (1 기대)"

echo "=== Case D: 유효 경로 (pass 기대) ==="
mkdir -p /tmp/rwv1-guard-test/fake-plugin/templates
( CLAUDE_PLUGIN_ROOT="/tmp/rwv1-guard-test/fake-plugin" bash guard.sh ); echo "exitD=$? (0 기대)"

cd / && rm -rf /tmp/rwv1-guard-test
```
Expected:
- Case A/B/C: stderr에 ERROR 출력 + `exit=1` (무음 cp 도달 전 차단 — SC-5 핵심)
- Case D: `GUARD-PASS: ...` 출력 + `exit=0`

이 결과가 나오면 fail-loud 가드가 미설정 케이스를 실제로 잡고, 유효 케이스는 통과함이 입증된다(Triple Crown ② 동작).

- [ ] **Step 6: 정적 검증 (SC-4, SC-6)**

Run:
```bash
echo "SC-4 (거짓 자동감지 주장 제거 — 0건 기대):"
grep -n '설치 경로에서 자동 감지된다' /Users/dh/Project/orbit/plugins/orbit-base/commands/orbit-init.md; echo "exit=$? (1이면 0건=PASS)"
echo "SC-6 (도메인 순수성 — 0건 기대):"
grep -rniE 'oremi|orbit-dev' /Users/dh/Project/orbit/plugins/orbit-base/; echo "exit=$? (1이면 0건=PASS)"
```
Expected:
- SC-4: 출력 없음, `exit=1` (거짓 주장 제거됨)
- SC-6: 출력 없음, `exit=1` (도메인 누출 0)

- [ ] **Step 7: 커밋 (orbit-init.md 단독 — 커밋 2)**

```bash
cd /Users/dh/Project/orbit
git add plugins/orbit-base/commands/orbit-init.md
git commit -m "fix(base): fail-loud guard for CLAUDE_PLUGIN_ROOT in orbit-init, correct false auto-detect comment"
```
(이 커밋에는 `plugins/orbit-base/commands/orbit-init.md`만. README 변경과 분리.)

---

## 기각·옵션 (플랜 명시)

- **기각(MINOR)** — `.claude-plugin/plugin.json`↔`.codex-plugin/plugin.json` 비대칭: **알려진 비이슈**. Claude Code 컨벤션 자동발견으로 skills 경로 선언은 선택사항([[orbit-plugin-discovery]] 메모리, QA-1 확정). **동기화하지 말 것** — 이 플랜의 어떤 Task도 이를 건드리지 않는다.

- **옵션(NIT) — `docs/smoke-results.md` stale 참조**: smoke-results.md:23-24가 `.claude-plugin/marketplace.json` / `plugins/orbit-base/.claude-plugin/plugin.json`을 참조한다. 이는 **내부 dev 스모크 기록**(2026-06-18 Phase 5)이며 **배포물 무관**, 신규자 설치 경로에 영향 없음.
  - **권고: 이번 RWV-1 보수에서는 보류**한다. 이유: (1) 신규자 차단점과 무관(이 플랜의 Goal 밖), (2) 커밋 분리 원칙상 housekeeping을 BLOCKER/MAJOR 커밋에 섞으면 안 됨, (3) thin 유지. 별도 housekeeping task로 후속 백로그 시드만 권고(roadmap RWV 섹션 하위 NIT로 이미 기록됨). 리드가 저비용 정리를 원하면 독립 `docs:` 커밋으로 분리 처리.

---

## 영향 범위

| 항목 | 범위 |
|------|------|
| 변경 파일 | `README.md`(루트), `plugins/orbit-base/commands/orbit-init.md`(배포물) — **2개** |
| 변경 컴포넌트 | (1) README 문서, (2) `/orbit-init` 커맨드 — **2개 컴포넌트** |
| 공개 인터페이스 | `/orbit-init` 커맨드의 **동작**이 변함(미설정 시 무음 실패 → fail-loud 중단). 단 정상 설치 경로(CLAUDE_PLUGIN_ROOT 주입됨)에서는 동작 동일. 명령 시그니처·인자·산출 파일은 불변. |
| 데이터/마이그레이션 | 없음 |
| 의존성 | 신규 의존성 0 |
| 하위 호환성 | 정상 케이스 불변. 깨져 있던(무음 실패) 미설정 케이스만 명시적 에러로 바뀜 — 회귀 아님(failure mode 개선). |

---

## 4트리거 Self-Assessment (고위험 게이트 입력 — 리드가 최종 판정)

| 트리거 | 판정 | 근거 |
|--------|------|------|
| **T1 비가역성** | **NO** | 두 변경 모두 텍스트 편집, `git revert`로 즉시 원복. 데이터 마이그레이션·재작성·하위호환 파괴 없음. |
| **T2 광범위 영향** | **경계 → NO 쪽**(리드 확인) | 2개 파일 / 2개 컴포넌트(< 3). 공개 커맨드 `/orbit-init`의 **동작**을 바꾸나(미설정 케이스 fail-loud), 인터페이스 시그니처·정상경로는 불변. T2 임계(≥3 컴포넌트 또는 공개 계약 변경)에 **시그니처 변경은 없음**. 다만 init 스캐폴딩(첫 실행 경로)의 동작 변경이므로 **검증으로 입증 필수**(Task 2 Step 5가 이를 담당). |
| **T3 보안·무결성** | **NO** | 인증·권한·시크릿·삭제·금전·PII 경로 무관. fail-loud는 오히려 무음 실패를 막아 안전성↑. |
| **T4 신규 외부 의존성** | **NO** | 신규 런타임·외부 서비스·벤더 종속 0. 순수 bash/markdown. |

**self-assessment 결론**: 4트리거 모두 NO(T2는 경계지만 시그니처 불변·컴포넌트<3로 NO 쪽). 다만 **MAJOR가 init 첫 실행 경로의 동작을 바꾸므로**, 저위험 판정이라도 **Task 2 Step 5의 동작 검증(미설정 케이스를 가드가 실제로 잡는지)**을 통과해야 완료로 인정한다. 최종 critic 분기 여부는 리드 판정.

---

## 검증 방법 요약 (Triple Crown 매핑)

- **① 완성도(GSD/roadmap)**: SC-1~SC-7 전부 충족 + roadmap RWV-1 체크박스. Task 1·2의 모든 Step 체크.
- **② 동작(gstack/런타임)**: Task 2 Step 5 — 미설정/빈값/templates부재 케이스에서 가드가 비-0 exit + 에러 출력(무음 cp 미도달), 유효 케이스 통과. (브라우저 무관 → bash 시뮬레이션이 동작 입증.) Task 1은 grep 검증(SC-1~3).
- **③ 품질(superpowers review + 아키텍처 일관성)**: 커밋 분리 준수(SC-7), 도메인 순수성 0(SC-6), 거짓 주석 제거(SC-4). 가드가 기존 커맨드 인라인-bash 관례를 따르고 과설계 없는지 확인.

---

## 추가 내부 조사 필요 시 (리드 보고용 — builder 직접 호출 금지)

현재 플랜은 discovery 완료분으로 **추가 explore 위임 불요**. 단, 구현 중 아래가 발견되면 리드 경유로 explore 위임 권고:
- (가정 검증) orbit-init.md의 라인 번호가 구현 시점에 어긋나면(다른 보수로 이동) — explore에 `commands/orbit-init.md` 현재 구조 재맵핑 요청.
- (선택) NIT 정리를 진행하기로 하면 — explore에 `docs/` 내 `.claude-plugin/` 경로 참조 전수 grep 요청 후 별도 housekeeping task화.
