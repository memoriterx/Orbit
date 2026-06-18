# orbit

허브앤스포크 멀티에이전트 팀 프레임워크 — Claude Code 플러그인.

**orbit**은 구조화된 소프트웨어 딜리버리를 위한 팀 운영 프레임워크다. 리드(팀장)가 허브, 전문 역할 에이전트(architect/builder/reviewer/researcher)가 스포크. 계획→승인→구현→Triple Crown 검증의 단일 작업 생명주기를 강제한다.

---

## 3단계 설치

```
# Step 1: 마켓플레이스 연결
/plugin marketplace add <orbit-repo-url>

# Step 2: 플러그인 설치
/plugin install orbit-base

# (선택) Next.js 웹개발 프리셋이 필요한 경우 — orbit-base 선행 필수
/plugin install orbit-web-dev

# Step 3: 프로젝트 초기화
/orbit-init
```

`/orbit-init` 실행 결과:
```
.orbit/
├── roadmap.md       ← 백로그·마일스톤 원장
├── config           ← tmux 세션명 등 설정
└── quality-gate.sh  ← 품질 게이트 (기본 no-op pass, 프로젝트 맞게 수정)
```

---

## 소프트 의존성 (선택 설치)

orbit은 아래 플러그인 없이도 핵심 기능(허브앤스포크·생명주기·자동재개)이 동작한다.
설치 시 Triple Crown 3갈래 검증 자동화가 강화된다.

```
/plugin install superpowers
/plugin install gstack
/plugin install gsd
```

### Graceful Degradation 매트릭스

| 기능 | Claude Code (풀) | Codex | Gemini |
|------|-----------------|-------|--------|
| 허브앤스포크 서브에이전트 (Agent 디스패치) | 풀 지원 | `multi_agent on` 시 `spawn_agent`로 가능, off 시 순차 역할 전환 | 미지원 → 단일 컨텍스트에서 순차 역할 전환 |
| 자동 훅 (typecheck 게이트·사용량 재개·뷰어) | 풀 지원 | 미지원 → 수동 실행 | 미지원 → 수동 실행 |
| 생명주기 규율 (roadmap→plan→approval→구현→3갈래) | 지원 | 지원 | 지원 |
| Triple Crown 3갈래 검증 prose | 지원 (+동반 플러그인 스킬 자동화) | 지원 (수동 체크리스트) | 지원 (수동 체크리스트) |
| 슬래시 커맨드 (`/orbit-init`, `/orbit-cycle`) | 지원 | 부분 지원 | 부분 지원 |
| 뷰어 팬 라이브 가시화 (tmux) | tmux 있으면 지원 | 미지원 | 미지원 |
| `superpowers` 없을 때 Triple Crown ③ 품질 | 스킬로 자동화 | 수동 코드리뷰 체크리스트 | 수동 코드리뷰 체크리스트 |
| `gstack` 없을 때 Triple Crown ② 동작 검증 | 브라우저 QA 자동화 | 수동 브라우저 단계 | 수동 브라우저 단계 |
| `gsd` 없을 때 Triple Crown ① 완성도 | GSD 자동화 | 수동 로드맵 체크리스트 | 수동 로드맵 체크리스트 |

**저하 원칙:** 자동화(훅·서브에이전트·뷰어)는 환경 따라 사라지되, 방법론 규율(계획→승인→구현→검증)은 모든 환경에서 동일하게 생존한다.

---

## 2층 구조

```
orbit-base               ← 도메인 무관 골격 (어떤 기술 스택에도 적용)
├── 에이전트 5역: leader / architect / builder / reviewer / researcher
├── 커맨드: /orbit-init, /orbit-cycle
├── 훅: SubagentStop(품질 게이트) · SubagentStart(뷰어) · 사용량 자동재개
└── 크로스AI: CLAUDE.md(원천) + AGENTS.md→심링크(Codex) + GEMINI.md @포인터

orbit-web-dev            ← Next.js 웹개발 프리셋 (orbit-base 위에 얹음)
├── 에이전트 4종: architect-web / designer / fullstack / qa-web
├── 스킬 4종: nextjs-build / api-build / ui-design / web-qa
└── 리서처 소스 프리셋: presets/research-sources.md
```

### base vs web-dev 차이

| 항목 | orbit-base | orbit-web-dev |
|------|-----------|---------------|
| 에이전트 | leader/architect/builder/reviewer/researcher (도메인 무관) | architect-web/designer/fullstack/qa-web (Next.js 특화) |
| 스킬 | using-orbit (방법론) | nextjs-build/api-build/ui-design/web-qa |
| 도메인 슬롯 | `{{PRODUCT_PATHS}}`, `{{SHARED_TYPES_PATH}}` 등 비어 있음 | 예시값 제공 (e.g., `types/api.ts`, `tsc --noEmit && next lint`) |
| 대상 | 어떤 도메인(CLI·데이터·문서)에도 적용 | Next.js App Router 풀스택 프로젝트 |

**web-dev는 base를 대체하지 않고 확장한다.** base 에이전트와 web-dev 에이전트는 이름이 달라 충돌 없이 공존한다(`builder` vs `fullstack`, `architect` vs `architect-web`).

---

## 크로스 AI 지원

| AI | 컨텍스트 진입점 | 방식 |
|----|----------------|------|
| Claude Code | `CLAUDE.md` | 원천 1벌 (AI 중립 prose) |
| Codex | `AGENTS.md` | 심볼릭 링크 → `CLAUDE.md` (중복 0) |
| Gemini | `GEMINI.md` | `@./skills/using-orbit/SKILL.md` + `@references/gemini-tools.md` 포인터 2줄 |

도구명 매핑: `plugins/orbit-base/skills/using-orbit/references/codex-tools.md`, `gemini-tools.md` 참조.

---

## 도메인 슬롯

base 에이전트가 사용하는 주요 슬롯 — 프로젝트 CLAUDE.md 또는 web-dev 프리셋이 채운다.

| 슬롯 | 설명 |
|------|------|
| `{{PRODUCT_PATHS}}` | 리드가 직접 수정해서는 안 되는 제품 경로 |
| `{{SHARED_TYPES_PATH}}` | 공유 타입/인터페이스 파일 경로 |
| `{{ARCHITECTURE_DOC_PATH}}` | 아키텍처 문서 위치 |
| `{{QUALITY_GATE_CMD}}` | 품질 게이트 명령 (`.orbit/quality-gate.sh`에 채움) |
| `{{RESEARCH_SOURCES}}` | 리서처가 조사할 외부 소스 목록 |
| `{{BEHAVIOR_VERIFICATION_METHOD}}` | Triple Crown ② 동작 검증 방법 |
| `{{MEMORY_PATH}}` | 프로젝트 메모리 파일 경로 |

---

## 라이선스

MIT
