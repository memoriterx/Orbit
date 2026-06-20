# orbit

## 이게 뭐예요?

복잡한 작업을 AI에게 한꺼번에 "다 해줘"라고 하면
결과가 들쭉날쭉하고 버그도 잘 생깁니다.

orbit은 그 대신, 일을 **작은 단계로 쪼개고**
**각 단계를 다른 역할이 맡아** 체계적으로 처리합니다.

### 예를 들면

새 기능을 만들 때:

1. 설계자가 계획을 짠다
2. 당신이 승인한다
3. 구현자가 만든다
4. 검토자가 검사한다

각 역할은 서로 직접 이야기하지 않고, 항상 **리드(팀장)를 경유**합니다.
자전거 바퀴를 상상하면 됩니다 — 가운데 허브(리드)에 바큇살(각 역할)이 연결된 구조입니다.
이렇게 하면 누가 무엇을 결정했는지 항상 추적 가능하고, 중간에 사람이 개입해서 방향을 바꿀 수 있습니다.

orbit은 **Claude Code 플러그인**으로 동작하며, 어떤 기술 스택에도(Next.js·CLI·데이터 분석·문서 자동화 등) 동일하게 적용됩니다.

---

## 왜 팀으로 나누나요?

하나의 AI가 설계·구현·검증을 동시에 하면 자기 실수를 자기가 놓치기 쉽습니다.
orbit은 각 단계마다 **다른 역할**이 담당하도록 강제합니다.

- 설계자가 짠 계획을, 당신이 확인하고 나서야 구현이 시작됩니다.
- 구현이 끝나면 검토자가 별도로 품질을 확인합니다.
- 위험한 결정이 있을 때는 독립 비판자가 계획을 먼저 검토합니다.

그 결과: **버그가 줄고, 방향이 틀렸을 때 일찍 잡히고, 진행 상황이 눈에 보입니다.**

---

## 팀 구성 — 7가지 역할

| 역할 | 한 마디로 | 무엇을 하나요? | 모델 | 주요 스킬 |
|------|----------|--------------|------|----------|
| **leader (리드)** | 팀장 | 지시를 받고, 역할에 배분하고, 결과를 취합합니다. 코드는 직접 쓰지 않습니다. | `sonnet` | `writing-plans`(설계자에 위임) · `skillify`(반복 감지) |
| **architect (설계자)** | 계획 작성자 | 구현 전 플랜 문서를 만듭니다. 당신이 승인한 뒤에야 구현이 시작됩니다. | `opus` | `writing-plans` · `writing-skills`(스킬 추출 시) |
| **builder (구현자)** | 실제 개발자 | 승인된 계획대로 코드를 만듭니다. 테스트를 먼저 쓰고(TDD), 검증 후 완료를 선언합니다. | `sonnet` | `test-driven-development` · `systematic-debugging` · `verification-before-completion` |
| **reviewer (검토자)** | 품질 보증 | 구현이 끝나면 완성도·동작·코드 품질을 3갈래로 검증합니다. | `opus` | `GSD`(①) · `gstack`(②) · `requesting-code-review`(③) · `skillify` |
| **researcher (외부 조사자)** | 웹 탐색 전담 | 외부 문서·라이브러리·커뮤니티 패턴을 조사해 리드에게 보고합니다. 코드는 건드리지 않습니다. | `haiku` | —(역할 본연 기능) |
| **critic (비판자)** | 독립 검토자 | 위험한 계획이 있을 때만 호출됩니다. 설계자의 계획을 독립적으로 비판하고 PROCEED / REVISE를 판정합니다. | `opus` | —(역할 본연 기능) |
| **explore (내부 탐색자)** | 코드베이스 탐색 전담 | 프로젝트 내 파일·코드 패턴을 찾아 보고합니다. researcher(외부)와 구분됩니다. 코드는 건드리지 않습니다. | `sonnet` | —(역할 본연 기능) |

**모델 티어:** `haiku` = 빠르고 가벼움(단순 탐색·조사) / `sonnet` = 균형(구현·조율·내부 탐색) / `opus` = 깊은 추론(설계·검증·비판 등 판단이 중요한 역할). 역할의 사고 난이도에 맞춰 모델을 배정하며, 프로젝트 설정에서 교체 가능합니다.

---

## 일하는 순서 (작업 생명주기)

하나의 작업이 완료되기까지 거치는 단계입니다.

```
로드맵에서 작업 선택
  → 설계자가 계획 작성
  → [고위험 작업? → 비판자가 독립 검토 → 설계자 수정 → 재검토]
  → 당신이 계획 승인
  → 구현자가 코드 작성 (TDD)
  → Triple Crown 검증 (3갈래)
      ① 완성도: 계획 대비 구현이 빠진 게 없는지
      ② 동작: 실제로 실행해서 동작을 확인
      ③ 품질: 코드 정확성·보안·유지보수성 리뷰
  → 완료
```

### "고위험"이란?

아래 중 하나라도 해당하면 비판자를 먼저 거칩니다.

- 되돌리기 어려운 변경
- 영향 범위가 넓은 변경
- 보안·무결성 관련 변경
- 새로운 외부 의존성 추가

### Triple Crown (3갈래 검증)

검토자가 완료 판정을 내리기 전에 3가지를 모두 확인합니다.

| 갈래 | 무엇을 확인하나요? | 도구 |
|------|-------------------|------|
| ① 완성도 | 계획 대비 빠진 구현이 없는지 | GSD |
| ② 동작 | 실제 실행해서 기대대로 동작하는지 | 프로젝트가 지정 (웹에서 흔한 예: gstack) |
| ③ 품질 | 코드 정확성·보안·유지보수성 | requesting-code-review (기본값) |

② 동작과 ③ 품질에 사용하는 도구는 프로젝트마다 교체 가능합니다(슬롯 주입, 아래 참조).

> 출처: 클로드 코드(Claude Code) 멀티에이전트 팀 자동화 완성 가이드 : AI 개발팀 구성부터 Remote-Control 실전까지

### opt-in 자율 실행 모드

기본은 꺼져 있습니다. 저위험 작업 묶음을 미리 한꺼번에 승인하면, 리드가 연속으로 자동 실행합니다.
단, 고위험 작업은 자동 정지되고, 비판자 독립 검증과 사람 게이트는 항상 유지됩니다.

---

## 빠른 시작 — 3단계 설치

```
# 1단계: 마켓플레이스 연결
/plugin marketplace add <orbit-repo-url>

# 2단계: 플러그인 설치
/plugin install orbit-base

# 3단계: 프로젝트 초기화
/orbit-init
```

`/orbit-init`을 실행하면 프로젝트 루트에 `.orbit/` 폴더가 만들어집니다.

```
.orbit/
├── roadmap.md       ← 할 일 목록·마일스톤 관리
├── config           ← 세션명 등 설정
└── quality-gate.sh  ← 품질 게이트 (기본값: 항상 통과. 프로젝트에 맞게 수정)
```

---

## 그 다음 — 선택 플러그인

orbit은 아래 플러그인 없이도 핵심 기능(팀 구조·생명주기·자동 재개)이 동작합니다.
설치하면 Triple Crown 검증이 자동화됩니다.

단, **미설치 시 검증이 약해집니다.** 완성도(①)와 품질(③)은 reviewer가 플랜·코드를 직접 읽어 수동으로 대조할 수 있지만 덜 체계적입니다. 동작 검증(②)은 프로젝트 유형에 맞는 도구를 고르는 슬롯(`{{BEHAVIOR_VERIFICATION_METHOD}}`)으로 채워지며 — 웹이면 gstack(브라우저 QA), iOS 앱이면 gstack의 앱 QA 기능, CLI·API면 에이전트 직접 실행 — 단, UI·앱처럼 직접 실행이 어려운 동작은 적절한 자동 검증 도구(또는 사람)가 없으면 에이전트만으로 한계가 있습니다. **제대로 된 자동화 검증을 원한다면 설치를 권장합니다.**

```
# superpowers — 마켓플레이스에서 바로 설치
/plugin install superpowers
```

gstack은 setup 스크립트로 설치합니다. 아래를 Claude Code에 붙여넣으면 스킬을 등록하고 헤드리스 브라우저 바이너리를 빌드해 `~/.claude/skills/gstack`에 저장합니다 (Git·Bun 필요):

```
git clone --single-branch --depth 1 https://github.com/garrytan/gstack.git ~/.claude/skills/gstack && cd ~/.claude/skills/gstack && ./setup
```

> `/gstack`은 설치 명령이 아니라 헤드리스 브라우저를 구동하는 스킬입니다. 설치 후 업데이트는 `/gstack-upgrade`로 합니다.

gsd는 Claude Code에서 `/gsd-help`를 실행하면 설치 안내가 표시됩니다. (gstack을 사용한다면 gstack을 통한 설치가 권장됩니다.)

각 도구의 설치 방식·요구사항은 저장소마다 다르므로 최신 안내는 아래 저장소를 참조하세요.

각 플러그인의 GitHub 출처:

- [superpowers](https://github.com/obra/superpowers) — 플랜 작성·코드리뷰·스킬 작성 등 개발 방법론 스킬 모음
- [gstack](https://github.com/garrytan/gstack) — 브라우저·런타임 동작 실증 QA 도구. 웹뿐 아니라 iOS 앱 검증도 지원
- gsd (Get Shit Done, by TÂCHES) — Claude Code에서 `/gsd-help`로 설치 안내. 스펙 기반 개발 프레임워크

### 스킬 카탈로그

orbit이 기본 제공하는 주요 스킬입니다.

| 스킬 | 출처 | 설명 |
|------|------|------|
| `using-orbit` | orbit-base | 팀 구조·생명주기·Triple Crown 안내. 세션 시작 시 로드 |
| `skillify` | orbit-base | 3회 이상 반복된 절차를 재사용 스킬로 추출하는 방법 |
| `writing-plans` | superpowers | 구현 전 플랜 문서 작성 방법론 |
| `writing-skills` | superpowers | 스킬 파일 작성 방법론 |
| `requesting-code-review` | superpowers | 코드 정확성·보안·유지보수성 리뷰 (Triple Crown ③ 기본) |
| `gstack` | gstack | 브라우저·런타임 동작 실증 (Triple Crown ② 기본) |
| `GSD` | gsd | 계획 대비 구현 완성도 체크 (Triple Crown ① 도구) |

---

## 고급 설정 참조

이 아래 내용은 처음 시작할 때 몰라도 됩니다. 필요할 때 찾아보세요.

### tmux 팀 환경 셋업

tmux(터미널 다중 분할 도구)가 있으면 리드 화면과 서브에이전트 트랜스크립트를 나란히 볼 수 있습니다.
`setup-orbit.sh`가 리드(pane 0) + 뷰어(pane 1) 2분할 환경을 자동으로 만들고 Claude CLI를 실행합니다.

```bash
# 프로젝트 루트에서 실행
bash "${CLAUDE_PLUGIN_ROOT}/scripts/setup-orbit.sh"

# orbit 레포 루트에서 직접 실행 (개발·테스트용)
bash /path/to/orbit/setup-orbit.sh
```

주요 환경변수:

| 변수 | 기본값 | 설명 |
|------|--------|------|
| `ORBIT_TMUX_SESSION` | `orbit` | tmux 세션명 (`.orbit/config`에서도 설정 가능) |
| `CLAUDE_PROJECT_DIR` | git root / pwd | 프로젝트 루트 경로 |
| `ORBIT_SKIP_PERMISSIONS` | `true` | `--dangerously-skip-permissions` 전달 여부 (`0`으로 비활성화) |
| `ORBIT_SKIP_PLUGIN_CHECK` | (unset) | `1`로 설정하면 플러그인 감지·설치·업데이트 단계 전체를 건너뜀 (오프라인·이미 설치 확신 시) |
| `ORBIT_INSTALL_DEPS` | (unset) | `1`로 설정하면 동반 플러그인(superpowers/gstack/gsd) 설치·업데이트를 시도 |
| `ORBIT_INSTALL_SCOPE` | `user` | 플러그인 설치 범위: `user`(전역), `project`(프로젝트 `.claude/`), `local`(로컬 전용). 기존 팀 에이전트가 있는 프로젝트에서 충돌을 피하거나 전역 오염 없이 시험할 때 `project`/`local`로 격리 |
| `ORBIT_SKIP_UPDATE` | (unset) | `1`로 설정하면 orbit 및 동반 플러그인 업데이트 체크를 건너뜀 |

**플러그인 자동 감지·설치:** `setup-orbit.sh`는 Claude CLI 실행 전에 `orbit-base`가 설치돼 있는지 확인합니다. 미설치 시 마켓플레이스 등록과 `orbit-base` 설치를 자동으로 시도합니다(비대화형, 멱등). 자동 설치에 실패하면 에러로 중단하지 않고 claude 안에서 수동 실행할 명령을 안내합니다.

**업데이트 체크:** `ORBIT_SKIP_UPDATE=1`을 지정하지 않으면 매 실행 시 마켓플레이스 인덱스를 갱신하고 `orbit-base`를 최신 버전으로 업데이트합니다(실패해도 치명적이지 않음). `ORBIT_INSTALL_DEPS=1`일 때는 `superpowers`도 함께 업데이트합니다.

**동반 플러그인 분류:**

| 플러그인 | 설치 방법 | `ORBIT_INSTALL_DEPS=1` 동작 |
|----------|----------|---------------------------|
| `superpowers` | `claude-plugins-official` 마켓플레이스 → 자동 설치 가능 | 미설치 시 자동 설치, 설치 시 업데이트 |
| `gstack` | `~/.claude/skills/` 수동 설치 (마켓플레이스 미등록) | 설치 여부 확인 후 수동 안내만 출력 |
| `gsd` | Claude Code에서 `/gsd-help` 실행 (마켓플레이스 미등록) | 설치 여부 확인 후 수동 안내만 출력 |

SubagentStart 훅(`viewer-attach.sh`)이 서브에이전트 트랜스크립트를 뷰어 팬에 자동 연결합니다.
tmux가 없는 환경에서는 훅이 조용히 종료되어 영향 없습니다.

### 선택적 기능 부재 시 동작 (Graceful Degradation)

플러그인이나 환경이 없어도 핵심 방법론(계획→승인→구현→검증)은 어디서나 동작합니다.
자동화 도구가 없을 때는 수동 체크리스트로 대체됩니다.

| 기능 | Claude Code (풀) | Codex | Gemini |
|------|-----------------|-------|--------|
| 서브에이전트 병렬 실행 | 풀 지원 | `multi_agent on` 시 `spawn_agent`로 가능, off 시 순차 역할 전환 | 미지원 → 단일 컨텍스트에서 순차 역할 전환 |
| 자동 훅 (품질 게이트·사용량 재개·뷰어) | 풀 지원 | 미지원 → 수동 실행 | 미지원 → 수동 실행 |
| 생명주기 규율 (로드맵→계획→승인→구현→3갈래) | 지원 | 지원 | 지원 |
| Triple Crown 3갈래 검증 | 지원 (+동반 플러그인 스킬 자동화) | 지원 (수동 체크리스트) | 지원 (수동 체크리스트) |
| 슬래시 커맨드 (`/orbit-init`, `/orbit-cycle`) | 지원 | 부분 지원 | 부분 지원 |
| 뷰어 팬 라이브 가시화 (tmux) | tmux 있으면 지원 | 미지원 | 미지원 |
| `superpowers` 없을 때 Triple Crown ③ 품질 | 스킬로 자동화 | 수동 코드리뷰 체크리스트 | 수동 코드리뷰 체크리스트 |
| `gstack` 없을 때 Triple Crown ② 동작 검증 | 브라우저 QA 자동화 | 수동 브라우저 단계 | 수동 브라우저 단계 |
| `gsd` 없을 때 Triple Crown ① 완성도 | GSD 자동화 | 수동 로드맵 체크리스트 | 수동 로드맵 체크리스트 |

**저하 원칙:** 자동화(훅·서브에이전트·뷰어)는 환경에 따라 빠질 수 있지만, 방법론 규율(계획→승인→구현→검증)은 모든 환경에서 동일하게 살아남습니다.

### 크로스 AI 지원

orbit은 Claude Code 외에도 Codex, Gemini에서 동일한 방법론으로 사용할 수 있습니다.

| AI | 컨텍스트 진입점 | 방식 |
|----|----------------|------|
| Claude Code | `CLAUDE.md` | 원천 1벌 (AI 중립 prose) |
| Codex | `AGENTS.md` | 심볼릭 링크 → `CLAUDE.md` (중복 없음) |
| Gemini | `GEMINI.md` | `@./skills/using-orbit/SKILL.md` + `@references/gemini-tools.md` 포인터 2줄 |

도구명 매핑: `plugins/orbit-base/skills/using-orbit/references/codex-tools.md`, `gemini-tools.md` 참조.

### 도메인 슬롯

orbit은 특정 프로젝트에 종속되지 않습니다. 프로젝트마다 달라지는 값(경로·도구·소스 목록)은 `{{슬롯}}`으로 남겨 두고, 프로젝트 `CLAUDE.md` 또는 `.orbit/quality-gate.sh`에서 채웁니다.

슬롯이 비어 있으면 에이전트는 기본값으로 fallback 동작합니다.

| 슬롯 | 설명 |
|------|------|
| `{{PRODUCT_PATHS}}` | 리드가 직접 수정해서는 안 되는 제품 경로 |
| `{{SHARED_TYPES_PATH}}` | 공유 타입·인터페이스 파일 경로 |
| `{{ARCHITECTURE_DOC_PATH}}` | 아키텍처 문서 위치 |
| `{{QUALITY_GATE_CMD}}` | 품질 게이트 명령 (`.orbit/quality-gate.sh`에 채움) |
| `{{RESEARCH_SOURCES}}` | researcher가 조사할 외부 소스 목록 |
| `{{BEHAVIOR_VERIFICATION_METHOD}}` | Triple Crown ② 동작 검증 방법 (프로젝트가 지정; 웹에서 흔한 예: gstack) |
| `{{MEMORY_PATH}}` | 프로젝트 메모리 파일 경로 |

researcher 역할은 도메인 무관 범용입니다. 어떤 기술 스택 프로젝트에도 동일한 researcher를 사용하고, 조사할 외부 소스 목록을 `{{RESEARCH_SOURCES}}` 슬롯에 채우기만 하면 됩니다. 지정된 소스가 없으면 범용 외부 조사로 동작합니다.

### orbit-base 구성

```
orbit-base               ← 도메인 무관 골격 (어떤 기술 스택에도 적용)
├── 에이전트 7역: leader / architect / builder / reviewer / researcher / critic / explore
├── 커맨드: /orbit-init, /orbit-cycle
├── 훅: SubagentStop(품질 게이트) · SubagentStart(뷰어) · 사용량 자동재개
└── 크로스AI: CLAUDE.md(원천) + AGENTS.md→심링크(Codex) + GEMINI.md @포인터
```

---

## 라이선스

MIT
