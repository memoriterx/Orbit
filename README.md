# orbit

허브앤스포크 멀티에이전트 팀 프레임워크 — Claude Code 플러그인.

**orbit**은 구조화된 소프트웨어 딜리버리를 위한 팀 운영 프레임워크다. 리드(팀장)가 허브, 전문 역할 에이전트(architect/builder/reviewer/researcher)가 스포크. 계획→승인→구현→Triple Crown 검증의 단일 작업 생명주기를 강제한다.

orbit은 **도메인 무관** 프레임워크다. Next.js·CLI·데이터 분석·문서 자동화 등 어떤 기술 스택에도 동일한 팀 구조와 워크프로세스 규율이 적용된다.

---

## 2단계 설치

```
# Step 1: 마켓플레이스 연결
/plugin marketplace add <orbit-repo-url>

# Step 2: 플러그인 설치
/plugin install orbit-base

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

## orbit-base 구성

```
orbit-base               ← 도메인 무관 골격 (어떤 기술 스택에도 적용)
├── 에이전트 5역: leader / architect / builder / reviewer / researcher
├── 커맨드: /orbit-init, /orbit-cycle
├── 훅: SubagentStop(품질 게이트) · SubagentStart(뷰어) · 사용량 자동재개
└── 크로스AI: CLAUDE.md(원천) + AGENTS.md→심링크(Codex) + GEMINI.md @포인터
```

도메인별 커스터마이즈는 **슬롯 주입**으로 한다. base 에이전트가 제공하는 `{{슬롯}}`을 프로젝트 CLAUDE.md 또는 `.orbit/quality-gate.sh`에서 채우면, 에이전트는 도메인에 맞게 동작한다.

### Research & Slot Injection

리서처 역할은 **base에 있으며 도메인 무관 범용**이다. 어떤 기술 스택 프로젝트에도 동일한 researcher 에이전트를 사용하고, 조사할 외부 소스 목록을 `{{RESEARCH_SOURCES}}` 슬롯에 직접 채운다.

| 역할 | 위치 | 설명 |
|------|------|------|
| 검색 엔진(역할) | `orbit-base/agents/researcher.md` | 도메인 무관 범용 리서처. 외부 소스를 조사해 리드에게 보고하는 읽기 전용 역할. |
| 검색 대상(소스 목록) | 프로젝트 CLAUDE.md 또는 `.orbit/` 설정 | `{{RESEARCH_SOURCES}}` 슬롯에 직접 기입. 위치/리뷰 플랫폼·SNS·문서 사이트 등 프로젝트에 맞는 소스를 자유롭게 채운다. |

슬롯이 비어 있으면 researcher는 일반적인 웹 검색으로 fallback 동작한다.

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

base 에이전트가 사용하는 주요 슬롯 — 프로젝트 CLAUDE.md에서 채운다.

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

## tmux 팀 환경 셋업

`setup-orbit.sh`는 리드(pane 0) + 뷰어(pane 1) 2팬 tmux 환경을 자동 구성하고 Claude CLI를 실행한다.

```bash
# 프로젝트 루트에서 실행
bash "${CLAUDE_PLUGIN_ROOT}/scripts/setup-orbit.sh"

# 또는 orbit 레포 루트에서 직접 실행 (개발·테스트용)
bash /path/to/orbit/setup-orbit.sh
```

주요 환경변수:

| 변수 | 기본값 | 설명 |
|------|--------|------|
| `ORBIT_TMUX_SESSION` | `orbit` | tmux 세션명 (`.orbit/config`에서도 설정 가능) |
| `CLAUDE_PROJECT_DIR` | git root / pwd | 프로젝트 루트 경로 |
| `ORBIT_SKIP_PERMISSIONS` | `true` | `--dangerously-skip-permissions` 전달 여부 (`""`로 비활성화) |
| `ORBIT_SKIP_PLUGIN_CHECK` | (unset) | `1`로 설정하면 플러그인 감지·설치·업데이트 단계 전체를 건너뜀 (오프라인·이미 설치 확신 시) |
| `ORBIT_INSTALL_DEPS` | (unset) | `1`로 설정하면 동반 플러그인(superpowers/gstack/gsd) 설치·업데이트를 시도 |
| `ORBIT_SKIP_UPDATE` | (unset) | `1`로 설정하면 orbit 및 동반 플러그인 업데이트 체크를 건너뜀 |

**플러그인 자동 감지·설치:** `setup-orbit.sh`는 Claude CLI 실행 전에 `orbit-base`가 설치돼 있는지 확인한다. 미설치 시 `memoriterx/Orbit` 마켓플레이스 등록과 `orbit-base` 설치를 자동으로 시도한다(비대화형, 멱등). 자동 설치에 실패하면 에러로 중단하지 않고 claude 안에서 수동 실행할 명령을 안내한다.

**업데이트 체크:** `ORBIT_SKIP_UPDATE=1`을 지정하지 않으면 매 실행 시 `orbit-marketplace` 인덱스를 갱신하고 `orbit-base`를 최신 버전으로 업데이트한다(실패해도 비치명적). `ORBIT_INSTALL_DEPS=1`일 때는 `superpowers`도 함께 업데이트한다.

**동반 플러그인 분류:**

| 플러그인 | 설치 방법 | `ORBIT_INSTALL_DEPS=1` 동작 |
|----------|----------|---------------------------|
| `superpowers` | `claude-plugins-official` 마켓플레이스 → 자동 설치 가능 | 미설치 시 자동 설치, 설치 시 업데이트 |
| `gstack` | `~/.claude/skills/` 수동 설치 (마켓플레이스 미등록) | 설치 여부 확인 후 수동 안내만 출력 |
| `gsd` | `~/.claude/skills/` 수동 설치 (마켓플레이스 미등록) | 설치 여부 확인 후 수동 안내만 출력 |

SubagentStart 훅(`viewer-attach.sh`)이 서브에이전트 트랜스크립트를 뷰어 팬에 자동 연결한다.
tmux가 없는 환경에서는 훅이 graceful no-op으로 종료되어 영향 없다.

---

## 라이선스

MIT
