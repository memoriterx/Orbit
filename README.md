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
| **explore (내부 탐색자)** | 코드베이스 탐색 전담 | 프로젝트 내 파일·코드 패턴을 찾아 보고합니다. researcher(외부)와 구분됩니다. 코드는 건드리지 않습니다. | `sonnet` | —(역할 본연 기능) |
| **critic (비판자)** | 독립 검토자 | 위험한 계획이 있을 때만 호출됩니다. 설계자의 계획을 독립적으로 비판하고 PROCEED / REVISE를 판정합니다. | `opus` | —(역할 본연 기능) |
| **reviewer (검토자)** | 품질 보증 | 구현이 끝나면 완성도·동작·코드 품질을 3갈래로 검증합니다. | `opus` | `GSD`(①) · `gstack`(②) · `requesting-code-review`(③) · `skillify` |
| **researcher (외부 조사자)** | 웹 탐색 전담 | 외부 문서·라이브러리·커뮤니티 패턴을 조사해 리드에게 보고합니다. 코드는 건드리지 않습니다. | `haiku` | —(역할 본연 기능) |

**모델 티어:** `haiku` = 빠르고 가벼움(단순 탐색·조사) / `sonnet` = 균형(구현·조율·내부 탐색) / `opus` = 깊은 추론(설계·검증·비판 등 판단이 중요한 역할). 역할의 사고 난이도에 맞춰 모델을 배정하며, 프로젝트 설정에서 교체 가능합니다.

---

## 일하는 순서 (작업 생명주기)

하나의 작업이 완료되기까지 거치는 단계입니다.

```
로드맵에서 작업 선택
  → 설계자가 Discovery(사전 조사·정리) 먼저
      — 내부 코드 사실은 내부 탐색자(explore)에게 맡기고
      — 외부 자료가 필요하면 외부 조사자(researcher)에게 맡긴 뒤
      — 설계자가 결과를 종합해 무엇을 만들지·어디까지인지·뭐부터인지를 정리
  → 설계자가 계획 작성 (Discovery 결과 바탕)
  → [고위험 작업? → 비판자가 독립 검토 → 설계자 수정 → 재검토]
  → 당신이 계획 승인
  → 구현자가 코드 작성 (TDD)
  → Triple Crown 검증 (3갈래)
      ① 완성도: 계획 대비 구현이 빠진 게 없는지
      ② 동작: 실제로 실행해서 동작을 확인
      ③ 품질: 코드 정확성·보안·유지보수성 리뷰
  → 완료
```

"계획부터 쓰자"가 아니라 **"먼저 알아보고(Discovery) → 계획 작성"** 입니다.
새 역할을 추가하는 게 아니라, 설계자가 무엇을 알아볼지 결정하고 리드를 통해 기존 역할(explore·researcher)에 사실 수집을 맡긴 뒤 그 결과를 종합하는 단계입니다.

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
자율 실행 모드에는 두 가지 프로파일이 있습니다. 상황에 맞게 선택하세요.

**기본 — 멈추고 기다리기 (halt-on-trigger)**
고위험이거나 판단이 필요한 작업을 만나면 전체 실행을 멈추고, 사람이 확인해 줄 때까지 기다립니다.
자리에 있을 때 쓰기 좋습니다. 뭔가 애매한 게 있으면 바로 물어봐 줍니다.

**무인 자동완료 — 건너뛰고 모아두기 (skip-and-park)**
자리를 비울 때를 위한 옵션입니다. 리드가 고위험 또는 판단이 필요한 작업을 만나면 건너뛰고 따로 격리(parked)해 둡니다.
나머지 저위험 작업은 끝까지 자동으로 처리하고, 돌아왔을 때 격리된 작업 목록을 보고받습니다.
**고위험 작업은 절대 자동으로 결정하거나 구현하지 않습니다.** 비판자 검증과 사람 게이트는 어느 프로파일에서도 유지됩니다.

### 여러 일 동시에 (병렬 실행)

서로 관계없는 조사나 검증 작업은 리드가 여러 에이전트에 동시에 맡길 수 있습니다.
예를 들어 내부 탐색(explore)과 외부 조사(researcher)를 같이 시작하고, 둘 다 끝나면 리드가 결과를 한곳에 취합합니다.
에이전트끼리는 직접 이야기하지 않으므로, 리드가 유일한 취합점입니다.

**한 줄 경계:** 조사·검증은 병렬로 해도 괜찮지만, **코드 구현(빌드)은 항상 한 번에 하나씩** 합니다.
동시에 빌드를 여러 개 돌리면 안전장치(품질 게이트·검증 순서)가 뒤섞이기 때문입니다.

### 큰 기능 묶기 (task 그룹)

하나의 큰 기능을 여러 task로 쪼갤 때, 로드맵에서 그 관계를 표현하는 **경량 컨벤션**입니다.
새로운 도구나 훅이 필요하지 않고, 명명 규칙만으로 동작합니다.

**방법:**
- **그룹 헤더** `### [GROUP-NAME] <설명>` 을 백로그(또는 current) 섹션에 추가한다.
- 헤더 아래 각 task에 **ID 접두사** `[PREFIX-N]` 을 붙인다.
- 헤더 바로 아래 있는 task는 그룹을 자동으로 상속한다. 다른 위치에 task를 두려면 줄 끝에 `↳ part of [GROUP-NAME]` 을 표기한다.

```
## Backlog

### [GROUP-NAME] <큰 기능 설명>
- [ ] **[PREFIX-1] <하위 task>** — <설명>
- [x] **[PREFIX-2] <하위 task>** — <완료일>
- [ ] **[PREFIX-3] <하위 task>** — <설명>
```

**핵심 계약:** 그룹은 **수동 라벨**이지 능동 진행률 추적기가 아닙니다. 진행률 롤업 필드(`N/M complete` 같은 것)는 없고, 읽는 사람이 `- [x]` 를 눈으로 셉니다. 각 하위 task는 여전히 독립적으로 계획 → 승인 → 구현 → 검증 생명주기를 거칩니다. milestone(완료된 작업 묶음의 사후 라벨)과는 다릅니다 — 그룹은 백로그 항목을 제자리에서 묶는 응집 장치입니다. 로드맵은 여전히 thin ledger로 유지됩니다.

---

## 요구사항 (Requirements)

orbit의 Triple Crown 검증을 완전히 사용하려면 다음 동반 플러그인이 필요합니다 (v2.0.0).
동반 플러그인 없이도 계획·승인·구현 단계는 실행되지만, **검증 프롱이 FAIL 처리**됩니다.

| 동반 플러그인 | 검증 프롱 | 설치 방법 |
|--------------|----------|----------|
| **superpowers** | ③ 품질 (`superpowers:requesting-code-review`) | `/plugin install superpowers@claude-plugins-official` |
| **GSD** | ① 완성도 (`/gsd-verify-work`) | `/gsd-help` 또는 `/plugin install gsd` |
| **gstack** | ② 동작 (`/qa`) | `git clone --single-branch --depth 1 https://github.com/garrytan/gstack.git ~/.claude/skills/gstack && cd ~/.claude/skills/gstack && ./setup` |

> **v2.0.0 변경:** 이전 버전에서 동반 플러그인은 선택적이었습니다. v2.0.0부터 Triple Crown
> 검증 프롱에서 필수로 요구됩니다. Claude Code 전용입니다(Codex/Gemini는 수동 검증).
>
> **CI/헤드리스:** `ORBIT_SKIP_COMPANION_CHECK=1` 환경변수로 훅 레이어 체크를 건너뛸 수 있습니다.

---

## 빠른 시작 — 3단계 설치

```
# 1단계: 마켓플레이스 연결
/plugin marketplace add memoriterx/Orbit

# 2단계: 플러그인 설치
/plugin install orbit

# 3단계: 프로젝트 초기화
/orbit-init
```

> **기존 `orbit-base` 사용자:** 설치명이 `orbit`으로 변경되었습니다(v1.0.0).
> `/plugin uninstall orbit-base` 후 `/plugin install orbit`을 실행하세요.
> 마켓플레이스(`memoriterx/Orbit`)는 그대로이므로 재등록은 불필요합니다.

`/orbit-init`을 실행하면 프로젝트 루트에 `.orbit/` 폴더가 만들어집니다.

```
.orbit/
├── roadmap.md       ← 할 일 목록·마일스톤 관리
├── config           ← 세션명 등 설정
└── quality-gate.sh  ← 품질 게이트 (기본값: 항상 통과. 프로젝트에 맞게 수정)
```

---

## 30분 만에 첫 사이클 (처음 한 번 따라하기)

설치를 마쳤다면, 아래를 순서대로 따라 하면 **첫 작업 1건이 계획→승인→구현→검증을 거쳐 완료**됩니다.
처음 한 번만 보면 됩니다. 그 아래 "고급 설정"은 지금 몰라도 됩니다.

### 0. 최소 준비물

| 필수 | 검증 프롱 완전 사용 시 추가 필요 |
|------|--------------------------------|
| Claude Code (orbit은 그 위에서 동작) | `superpowers` — Triple Crown ③ 품질 프롱 |
| `orbit` 플러그인 설치 (위 3단계) | `gstack` — Triple Crown ② 동작 프롱 |
| 프로젝트 폴더 1개 | `gsd` — Triple Crown ① 완성도 프롱 |

**참고:** 계획·승인·구현 단계는 동반 플러그인 없이도 실행됩니다.
단, 동반 플러그인 없이 검증 프롱을 실행하면 FAIL 처리됩니다(v2.0.0).
위 "요구사항" 섹션의 설치 명령을 참고해 먼저 동반 플러그인을 설치하세요.

### 1. 프로젝트 초기화

프로젝트 폴더에서 Claude Code를 열고:

```
/orbit-init
```

`.orbit/` 폴더(roadmap·config·quality-gate.sh)가 생깁니다.

### 2. 할 일 한 줄 등록

`.orbit/roadmap.md`를 열어 백로그에 첫 작업을 한 줄 적습니다. 예:

```markdown
## 백로그

- [ ] **README에 프로젝트 소개 문단 추가** — 한 문단짜리 설명
```

작업은 무엇이든 좋습니다(도메인 무관). 한 줄이면 시작할 수 있습니다.

### 3. 사이클 시작

```
/orbit-cycle
```

그러면 리드(팀장)가 다음을 차례로 진행합니다 — **당신이 할 일은 한 곳, "승인"뿐입니다.**

1. **설계자가 계획을 짭니다** (먼저 Discovery로 무엇을·어디까지인지 정리한 뒤 플랜 작성).
2. (위험한 작업이면) **비판자가 계획을 먼저 검토**합니다.
3. **리드가 계획을 보여주고 당신의 승인을 기다립니다.** ← 여기서 "진행해 주세요" 또는 수정 요청.
4. 승인하면 **구현자가 테스트부터 쓰고(TDD) 코드를 만듭니다.**
5. **검토자가 3갈래(완성도·동작·품질)로 확인**합니다.
6. 통과하면 `.orbit/roadmap.md`의 체크박스가 `- [x]`로 바뀌고 완료 보고를 받습니다.

### 4. 다음 작업

roadmap 백로그에 다음 줄을 추가하고 `/orbit-cycle`을 다시 실행하면 됩니다.
여러 작업을 한꺼번에 자동으로 돌리고 싶다면, 위 "일하는 순서"의 **opt-in 자율 실행 모드**를 참고하세요(기본은 꺼져 있어, 매 작업마다 당신이 승인합니다).

막혔을 때는 아래 "고급 설정 참조 → 막혔을 때(트러블슈팅)"를 확인하세요.

---

## 동반 플러그인 설치

v2.0.0부터 Triple Crown 검증 프롱에 동반 플러그인이 **필수**입니다.
설치하지 않으면 해당 검증 프롱이 FAIL 처리됩니다. 위 "요구사항" 섹션을 참조하세요.

**superpowers** — 플랜 작성·코드리뷰 등 개발 방법론 스킬 모음. Anthropic 공식 마켓플레이스에서 바로 설치합니다.

```
/plugin install superpowers@claude-plugins-official
```

**gstack** — 브라우저·앱이 실제로 잘 도는지 확인하는 QA 도구. 웹뿐 아니라 iOS 앱 검증도 지원합니다. Git·Bun이 필요하며 아래를 Claude Code에 붙여넣으면 설치됩니다.

```
git clone --single-branch --depth 1 https://github.com/garrytan/gstack.git ~/.claude/skills/gstack && cd ~/.claude/skills/gstack && ./setup
```

> `/gstack`은 설치 명령이 아니라 헤드리스 브라우저를 구동하는 스킬입니다. 업데이트는 `/gstack-upgrade`로 합니다.

**gsd** — 스펙 기반 개발 프레임워크. Claude Code에서 `/gsd-help`를 실행하면 설치 안내가 표시됩니다. (gstack을 사용한다면 gstack을 통한 설치가 권장됩니다.)

GitHub 출처:

- [superpowers](https://github.com/obra/superpowers)
- [gstack](https://github.com/garrytan/gstack)
- gsd — Claude Code에서 `/gsd-help`로 설치 안내

### 스킬 카탈로그

orbit이 기본 제공하는 주요 스킬입니다.

| 스킬 | 출처 | 설명 |
|------|------|------|
| `using-orbit` | orbit | 팀 구조·생명주기·Triple Crown 안내. 세션 시작 시 로드 |
| `skillify` | orbit | 3회 이상 반복된 절차를 재사용 스킬로 추출하는 방법 |
| `writing-plans` | superpowers | 구현 전 플랜 문서 작성 방법론 |
| `writing-skills` | superpowers | 스킬 파일 작성 방법론 |
| `requesting-code-review` | superpowers | 코드 정확성·보안·유지보수성 리뷰 (Triple Crown ③ 기본) |
| `gstack` | gstack | 브라우저·런타임 동작 실증 (Triple Crown ② 흔한 예) |
| `GSD` | gsd | 계획 대비 구현 완성도 체크 (Triple Crown ① 도구) |

---

## 고급 설정 참조

이 아래 내용은 처음 시작할 때 몰라도 됩니다. 필요할 때 찾아보세요.

### 막혔을 때 (트러블슈팅)

첫 사이클에서 가장 흔한 막힘과 대응입니다.

| 증상 | 원인 | 대응 |
|------|------|------|
| `/orbit-init`·`/orbit-cycle`이 명령 목록에 안 보임 | `orbit` 플러그인 미설치 또는 미인식 | `/plugin install orbit` 재실행 후 Claude Code를 재시작. 마켓플레이스 미등록이면 `/plugin marketplace add memoriterx/Orbit` 먼저 |
| `/orbit-init` 실행 시 `CLAUDE_PLUGIN_ROOT` 관련 오류 | 커맨드 컨텍스트에서 `CLAUDE_PLUGIN_ROOT` 자동 주입은 보장되지 않음 | `export CLAUDE_PLUGIN_ROOT=<orbit 플러그인 설치 경로>` 후 `/orbit-init` 재실행. 설치 경로를 모르면 Claude Code 재시작 후 다시 시도 |
| `.orbit/` 가 안 생기거나 비어 있음 | 프로젝트 루트가 아닌 곳에서 실행 | 프로젝트 폴더 루트에서 `/orbit-init`을 다시 실행. 기존 파일은 덮어쓰지 않습니다(`cp -n`) |
| 동반 플러그인(superpowers 등)이 없다고 표시됨 | 선택 플러그인 미설치 | **무시해도 됩니다.** orbit 핵심 방법론은 플러그인 없이 동작합니다. 자동화가 필요하면 "그 다음 — 선택 플러그인" 참고 |
| tmux 2분할(리드+뷰어) 화면이 안 뜸 | tmux 미설치 또는 미사용 | tmux는 **선택사항**입니다. 없으면 단일 화면에서 그대로 동작합니다(훅이 조용히 종료). 쓰려면 아래 "tmux 팀 환경 셋업" 참고 |

그 외 문제는 [GitHub 이슈](https://github.com/memoriterx/Orbit/issues)에 남겨 주세요.

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

**플러그인 자동 감지·설치:** `setup-orbit.sh`는 Claude CLI 실행 전에 `orbit`이 설치돼 있는지 확인합니다. 미설치 시 마켓플레이스 등록과 `orbit` 설치를 자동으로 시도합니다(비대화형, 멱등). 자동 설치에 실패하면 에러로 중단하지 않고 claude 안에서 수동 실행할 명령을 안내합니다.

**업데이트 체크:** `ORBIT_SKIP_UPDATE=1`을 지정하지 않으면 매 실행 시 마켓플레이스 인덱스를 갱신하고 `orbit`을 최신 버전으로 업데이트합니다(실패해도 치명적이지 않음). `ORBIT_INSTALL_DEPS=1`일 때는 `superpowers`도 함께 업데이트합니다.

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

도구명 매핑: `plugins/orbit/skills/using-orbit/references/codex-tools.md`, `gemini-tools.md` 참조.

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

### orbit 구성

```
orbit                    ← 도메인 무관 골격 (어떤 기술 스택에도 적용)
├── 에이전트 7역: leader / architect / builder / explore / critic / reviewer / researcher
├── 커맨드: /orbit-init, /orbit-cycle
├── 훅: SubagentStop(품질 게이트) · SubagentStart(뷰어) · 사용량 자동재개
└── 크로스AI: CLAUDE.md(원천) + AGENTS.md→심링크(Codex) + GEMINI.md @포인터
```

---

## 라이선스

MIT
