# Smoke Test Results — Phase 5

- **날짜:** 2026-06-18
- **실행:** Phase 5 스모크 검증 (A~D + 참조 무결성)
- **판정:** A = 통과, B = 통과, C = 미검증(환경 없음), D = 통과(주석 포함)

---

## 스모크 D — 참조 무결성 (필수)

### D-1. oremi/도메인 오염 grep

```
grep -riE 'oremi|오르미|네이버|부케|/Users/dh' plugins/orbit-base
```

**결과: 0건 — PASS**

### D-2. JSON 유효성 검증

| 파일 | 결과 |
|------|------|
| `.claude-plugin/marketplace.json` | PASS |
| `plugins/orbit-base/.claude-plugin/plugin.json` | PASS |
| `plugins/orbit-base/.codex-plugin/plugin.json` | PASS |
| `plugins/orbit-base/gemini-extension.json` | PASS |
| `plugins/orbit-web-dev/.claude-plugin/plugin.json` | PASS |
| `plugins/orbit-base/hooks/hooks.json` | PASS |

모두 `python3 -m json.tool` 파싱 통과.

### D-3. 심링크 무결성

```
readlink plugins/orbit-base/AGENTS.md
→ CLAUDE.md

cat AGENTS.md (첫 줄):
→ "# Orbit — AI-Neutral Operating Rules"
```

**결과: AGENTS.md → CLAUDE.md 심링크 정상 작동 — PASS**

### D-4. 고아 플레이스홀더 점검

base `agents/*.md` + `CLAUDE.md`의 `{{SLOT}}` 토큰 전수:

| 슬롯 | 정의 위치 (Domain Slots 표) | web-dev 채움값 제공 여부 |
|------|-----------------------------|--------------------------|
| `{{ARCHITECTURE_DOC_PATH}}` | architect.md, CLAUDE.md, builder.md | web-dev agent 예시 제공 (PASS) |
| `{{SHARED_TYPES_PATH}}` | architect.md, builder.md, reviewer.md | web-dev agent 예시 제공 (PASS) |
| `{{DOMAIN_SCOPE}}` | architect.md | web-dev agent 예시 제공 (PASS) |
| `{{CONSISTENCY_LENS}}` | architect.md | web-dev `architect-web.md`로 override — 대체 PASS |
| `{{DOMAIN_DESIGN_ITEMS}}` | architect.md | web-dev `architect-web.md`로 override — 대체 PASS |
| `{{PRODUCT_PATHS}}` | leader.md, CLAUDE.md | 프로젝트 CLAUDE.md에서 채움 (문서화됨) — PASS |
| `{{QUALITY_GATE_CMD}}` | builder.md, reviewer.md, CLAUDE.md | web-dev 예시 제공 + `.orbit/quality-gate.sh` 위임 — PASS |
| `{{BEHAVIOR_VERIFICATION_METHOD}}` | reviewer.md | web-dev `qa-web.md` + README 슬롯 표 — PASS |
| `{{QUALITY_REVIEW_SKILL}}` | reviewer.md | web-dev `qa-web.md` (superpowers 기본값 명시) — PASS |
| `{{STATIC_VERIFICATION_SKILL}}` | reviewer.md | web-dev `qa-web.md` (web-qa skill) — PASS |
| `{{RESEARCH_SOURCES}}` | researcher.md | web-dev `presets/research-sources.md` 예시 — PASS |
| `{{MEMORY_PATH}}` | CLAUDE.md | 프로젝트 CLAUDE.md에서 채움 (문서화됨) — PASS |

**결과: 고아 플레이스홀더 0건 — 모든 슬롯이 Domain Slots 표에 정의되고 채움값 경로 존재 — PASS**

**주의:** `plugin.json` 파일의 `email` 필드에 `memoriterx@gmail.com`이 있음. 이는 저자 메타데이터(오르미 도메인 콘텐츠 아님) — 오염으로 간주하지 않음. 단, 공개 배포 전 author 정보 업데이트 권장.

---

## 스모크 A — CC base 설치 구조적 검증

실제 `/plugin install` 인터랙티브 설치는 비대화형 환경에서 불가 → `mktemp -d` 빈 프로젝트로 orbit-init 절차 시뮬레이션.

```bash
TMPDIR=$(mktemp -d)
PLUGIN_ROOT="/Users/dh/Project/orbit/plugins/orbit-base"
PROJECT_ROOT="$TMPDIR"
```

### A-1. .orbit/ 스캐폴딩

| 단계 | 결과 |
|------|------|
| `mkdir -p .orbit/` | PASS |
| `cp -n roadmap.template.md → .orbit/roadmap.md` | PASS (파일 생성됨) |
| `cp -n orbit-config.template → .orbit/config` | PASS |
| `cp -n quality-gate.template.sh → .orbit/quality-gate.sh` + `chmod +x` | PASS (실행 권한 부여됨) |

### A-2. quality-gate.sh 동작

| 시나리오 | 결과 |
|---------|------|
| `.orbit/quality-gate.sh` 없을 때 (hooks/quality-gate.sh 래퍼) → exit 0 | PASS |
| `.orbit/quality-gate.sh` 있고 exit 0 (no-op pass) | PASS |
| wrapper exit code 확인 | exit 0 — PASS |

### A-3. 소프트 의존 감지 (graceful degradation)

`claude plugin list` 없는 환경에서 `2>/dev/null` suppression으로 에러 없이 MISSING 목록 출력:

```
MISSING plugins detected (gracefully): gstack gsd
No error thrown → graceful degradation OK
```

**결과: PASS**

### A-4. 변수 하드코딩 grep

```
grep -rn '/Users/dh' plugins/orbit-base
```

**결과: 0건 — PASS** (hooks.json은 `${CLAUDE_PLUGIN_ROOT}` / `${CLAUDE_PROJECT_DIR}` 변수 사용)

### A-5. hooks.json 경로화 확인

6종 훅 전부 `${CLAUDE_PLUGIN_ROOT}/hooks/<script>` 또는 `${CLAUDE_PROJECT_DIR}/.orbit/` 변수 사용 확인됨.

**스모크 A 종합: PASS**

---

## 스모크 B — web-dev 구조 검증

### B-1. 에이전트 존재 확인

`plugins/orbit-web-dev/agents/`:
- `architect-web.md` — 존재 (PASS)
- `designer.md` — 존재 (PASS)
- `fullstack.md` — 존재 (PASS)
- `qa-web.md` — 존재 (PASS)

### B-2. 스킬 4종 존재 확인

`plugins/orbit-web-dev/skills/`:
- `nextjs-build/SKILL.md` — 존재 (PASS)
- `api-build/SKILL.md` — 존재 (PASS)
- `ui-design/SKILL.md` — 존재 (PASS)
- `web-qa/SKILL.md` — 존재 (PASS)

### B-3. 슬롯 매핑 일관성

base 에이전트 슬롯 vs web-dev 에이전트 슬롯 교차 확인:

| base 슬롯 | web-dev 매핑 상태 |
|-----------|------------------|
| `{{SHARED_TYPES_PATH}}` | fullstack.md·architect-web.md·qa-web.md 모두 동일 슬롯 사용 — 일관 (PASS) |
| `{{QUALITY_GATE_CMD}}` | fullstack.md 명시 (예: `tsc --noEmit && next lint`) — PASS |
| `{{STATIC_VERIFICATION_SKILL}}` | qa-web.md에서 `web-qa` skill로 구체화 — PASS |
| `{{BEHAVIOR_VERIFICATION_METHOD}}` | qa-web.md에서 gstack 예시 제공 — PASS |
| `{{RESEARCH_SOURCES}}` | `presets/research-sources.md`로 채움값 제공 — PASS |
| `{{CONSISTENCY_LENS}}` | base architect 슬롯 → architect-web이 체크리스트로 구체화 (override) — PASS |
| `{{DOMAIN_DESIGN_ITEMS}}` | base architect 슬롯 → architect-web의 "Core Responsibilities" 섹션으로 구체화 — PASS |

### B-4. base 선행 필요 안내

`plugins/orbit-web-dev/README.md` 첫 섹션에 "orbit-base must be installed before orbit-web-dev" 명시 확인 — PASS

**스모크 B 종합: PASS**

---

## 스모크 C — 크로스 AI (best-effort)

실제 Codex / Gemini 설치 환경 없음 → 구조 검증만 수행.

### C-1. Codex (AGENTS.md 심링크)

- `AGENTS.md → CLAUDE.md` 심링크 존재 확인 (D-3에서 이미 검증)
- `cat AGENTS.md` = CLAUDE.md 내용 반환 확인 (D-3에서 이미 검증)
- `codex-tools.md` 도구 매핑표 존재: `plugins/orbit-base/skills/using-orbit/references/codex-tools.md` — 확인됨
- superpowers 플러그인의 동일 패턴(심링크 기반)과 구조 일치 — 구조적으로 올바름

**결과: 미검증 (Codex 실환경 없음) — 구조는 superpowers 검증 패턴과 일치**

### C-2. Gemini (GEMINI.md @포인터)

- `GEMINI.md` 내용: `@./skills/using-orbit/SKILL.md` + `@./skills/using-orbit/references/gemini-tools.md` 2줄
- `gemini-extension.json`의 `contextFileName: "GEMINI.md"` 확인됨
- `gemini-tools.md` 존재: `plugins/orbit-base/skills/using-orbit/references/gemini-tools.md` — 확인됨
- superpowers 플러그인의 동일 패턴(@포인터 기반)과 구조 일치

**결과: 미검증 (Gemini 실환경 없음) — 구조는 superpowers 검증 패턴과 일치**

**스모크 C 종합: 미검증 — 구조만 superpowers 패턴 일치 확인. 실제 Codex/Gemini 환경에서 별도 검증 필요.**

---

## 최종 판정

| 스모크 | 결과 | 비고 |
|--------|------|------|
| **A** (CC base 설치 구조 검증) | **PASS** | .orbit/ 스캐폴딩·quality-gate·graceful degradation 전부 통과 |
| **B** (web-dev 구조 검증) | **PASS** | 에이전트 4종·스킬 4종·슬롯 매핑 일관성 확인 |
| **C** (크로스AI best-effort) | **미검증** | 환경 없음 — 구조적으로 superpowers 패턴 일치 |
| **D** (참조 무결성) | **PASS** | 오르미 잔재 0건·JSON 전부 유효·심링크 정상·고아 슬롯 0건 |

**배포 가능 기준(A·B·D 전부 통과) → 충족.**
