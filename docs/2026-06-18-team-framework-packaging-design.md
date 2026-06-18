# 팀 프레임워크 배포화 설계 (Team Framework Packaging)

- **날짜:** 2026-06-18
- **작성:** architect (설계만, 구현 없음)
- **상태:** 설계 + writing-plans 산출 → 리드 보고 → Plan Approval 대기
- **범위:** 메타/하네스 레이어만. 오르미 제품 코드(`app/`, `components/`, `lib/`)는 무관·무변경.
- **승인된 방향:** ① Claude Code 플러그인(git 마켓플레이스) 1차 배포 ② 크로스AI 이식(graceful degradation) ③ base 골격 + web-dev 프리셋 2층.

---

## 0. 한 줄 요약

오르미의 허브앤스포크 멀티에이전트 팀(리드 + architect/fullstack/designer/qa/researcher + 3갈래 검증 + 사용량 자동재개 + 뷰어 팬)을, **오르미 도메인 콘텐츠를 변수로 빼낸** 재사용 프레임워크로 분리하여, Claude Code 플러그인으로 배포하고 Codex/Gemini에서도 프로세스 규율만큼은 동작하게 한다. 결과물 이름: **`orbit`** (Orchestrated Roles + Build/Inspect/Test — 임시명, 리드 확정 필요).

---

## 1. 현황 전수 조사 결과 (무엇이 거기 있나)

리드 요청에 따라 아래를 전수 읽음. 각 자산의 **재사용성**과 **오르미 결합도**를 표시한다.

| 자산 | 위치 | 본질 | 오르미 결합 |
|------|------|------|-------------|
| leader.md | `.claude/agents/` | 허브앤스포크·위임·Plan Approval·생명주기 | 낮음 (제품 경로 금지 규칙만 오르미 특정) |
| architect.md | `.claude/agents/` | 사전 설계 + 사후 아키 일관성 렌즈 | 높음 (Next.js·types/api.ts·네이버 스크래퍼·홈/제품/후기 하드코딩) |
| fullstack.md | `.claude/agents/` | 구현자 + TDD/디버깅 방법론 | 높음 (Next.js App Router·네이버·PM2/Nginx) |
| designer.md | `.claude/agents/` | UI/UX 설계자 | 높음 (부케 공방 감성·Tailwind·3페이지) |
| qa.md | `.claude/agents/` | 사후 3갈래 검증 조율자 | 중간 (3갈래 골격은 일반, SEO/네이버/web-qa는 웹) |
| researcher.md | `.claude/agents/` | 외부 소스 리서처 | 높음 (네이버 블로그/플레이스·Instagram·curl 레시피) |
| CLAUDE.md | 루트 | Bot Mode·브릿지·컨텍스트 규칙·생명주기 트리거 | 혼합 (Bot Mode/브릿지는 환경 특정, 생명주기는 일반) |
| settings.json hooks 6종 | `.claude/` | Stop·Notification·MessageDisplay·UserPromptSubmit·SubagentStop·SubagentStart | 혼합 (typecheck/lint 게이트는 npm 특정, 나머지는 일반) |
| usage-detect.py / resume-inject.py | `.planning/` | 사용량 한계 감지 → 리셋 후 자동재개 | 낮음 (경로만 하드코딩, 로직은 도메인 무관) |
| notify.sh / notify-done.sh | `_team/` | notifications.log append + 완료 알림 | 낮음 (경로 하드코딩만) |
| auto-attach.sh / attach-view.sh / agent-view.py | `_team/` | 서브에이전트 트랜스크립트 → tmux 뷰어 팬 라이브 | 중간 (tmux 세션명 `oremi`·홈경로 하드코딩, 메커니즘은 일반) |
| roadmap.md | `.planning/` | 얇은 원장 (백로그·마일스톤·현재 포인터·완성도 기준) | 낮음 (패턴은 일반, 내용은 오르미) |
| orchestration-remap spec | `docs/.../specs/` | Triple Crown 검증 흐름 설계 근거 | 낮음 (방법론 prose, 재사용 가능) |
| 도메인 스킬 4종 | `.claude/skills/` | api-build·nextjs-build·ui-design·web-qa | 높음 (전부 오르미 웹 특정) |

### 참조 기준: superpowers 플러그인 (검증된 패턴)

`~/.claude/plugins/cache/.../superpowers/5.1.0`을 분해한 결과, **우리가 필요한 크로스AI 메커니즘을 전부 이미 구현**하고 있어 그대로 미러링한다:

- `.claude-plugin/plugin.json` (CC 매니페스트) · `.codex-plugin/plugin.json` · `.cursor-plugin/plugin.json` — AI별 매니페스트 분리
- `AGENTS.md -> CLAUDE.md` **심볼릭 링크** (Codex는 AGENTS.md를 읽음 → 1벌 prose를 심링크로 노출, 중복 0)
- `GEMINI.md` = `@./path` **포인터 파일** 2줄 + `gemini-extension.json`(`contextFileName` 지정)
- `hooks/hooks.json`에서 `${CLAUDE_PLUGIN_ROOT}/hooks/run-hook.cmd` — 번들 스크립트 경로화 표준
- `skills/using-superpowers/references/codex-tools.md`·`gemini-tools.md` — Claude 도구명 → 타 AI 도구명 매핑표

→ **결론: 바퀴를 재발명하지 않는다. superpowers 레이아웃을 1:1 차용한다.**

---

## 2. 설계 항목 ① — 프레임워크 vs 오르미 콘텐츠 분리표

각 항목을 **(a) 그대로 이식 / (b) 변수화 / (c) 스트립(오르미 전용, 미포함)** 으로 분류.

| 자산 | 처리 | 비고 |
|------|------|------|
| leader.md 골격(허브앤스포크·위임·Plan Approval·생명주기·보고채널) | **(a) 그대로** | 도메인 무관. "오르미 코드 금지" 규칙은 `{{PRODUCT_PATHS}}` 변수화 |
| architect.md 골격(사전 설계 + 사후 일관성 렌즈·ADR·체크리스트 형식) | **(b) 변수화** | "아키 일관성 렌즈"라는 역할 형태는 base. Next.js/types/api.ts/네이버는 web-dev 프리셋으로 분리 |
| fullstack.md 골격(구현자 + TDD/디버깅/검증 방법론·리드 보고 형식) | **(b) 변수화** | 구현자 역할은 base. 기술스택 specifics는 프리셋 |
| designer.md | **(c) 스트립 → web-dev 프리셋** | 순수 웹 UI 역할. base에는 "선택적 designer 슬롯"만 |
| qa.md 골격(3갈래 검증 조율·통과/실패 보고) | **(b) 변수화** | 3갈래(완성도/동작/품질)는 base. SEO·네이버·web-qa·gstack 브라우저는 프리셋 |
| researcher.md | **(c) 스트립 → 선택적** | 네이버 curl 레시피는 100% 오르미. base에는 "읽기전용 리서처" 골격만 옵션 |
| CLAUDE.md: 생명주기 트리거·컨텍스트 규칙(70%·ScheduleWakeup) | **(a) 그대로** | 일반 운영 규율 |
| CLAUDE.md: Bot Mode·브릿지 명령어(@cc 등) | **(c) 스트립** | Remote-Control/claude-bridge 환경 특정. 프레임워크 밖 |
| settings.json: Stop·SubagentStart·SubagentStop(notify 분기) | **(a) 그대로** | 경로만 `${CLAUDE_PLUGIN_ROOT}`/`${CLAUDE_PROJECT_DIR}` 치환 |
| settings.json: SubagentStop typecheck/lint 게이트 | **(b) 변수화** | 명령을 `${CLAUDE_PROJECT_DIR}/.orbit/quality-gate.sh`로 위임 → 프로젝트가 게이트 정의(npm/cargo/go 등) |
| settings.json: Notification·UserPromptSubmit(사용량 자동재개) | **(a) 그대로** | 경로화만 |
| usage-detect.py / resume-inject.py | **(a) 그대로** | 경로 하드코딩 → env 변수. 로직 도메인 무관 |
| notify·notify-done·auto-attach·attach-view·agent-view | **(a) 그대로** | 경로/세션명 변수화 (`ORBIT_TMUX_SESSION`, `${CLAUDE_PROJECT_DIR}`) |
| roadmap.md (얇은 원장 패턴) | **(b) 변수화** | 빈 템플릿(`roadmap.template.md`)으로 제공. 오르미 내용은 스트립 |
| orchestration-remap spec(Triple Crown prose) | **(a) 그대로** | AI 중립 방법론 문서로 base/docs에 편입 |
| 도메인 스킬 4종(api/nextjs/ui/web-qa) | **(c) 스트립 → web-dev 프리셋** | 오르미 웹 빌드 스킬. base 무관 |

**원칙:** prose(방법론·역할 형태)는 AI 중립 마크다운 1벌에 두고, 도메인(기술스택·제품 경로·브랜드)은 변수 또는 프리셋 레이어로 주입. 하드코딩 절대경로는 전부 변수.

---

## 3. 설계 항목 ② — 하드코딩 절대경로 해소

현재 `/Users/dh/Project/Oremi/...`가 박힌 곳: settings.json(6 훅), usage-detect.py, resume-inject.py, notify.sh, notify-done.sh, auto-attach.sh, attach-view.sh, agent-view.py.

**Claude Code 변수 2종 의미 구분 (핵심):**
- `${CLAUDE_PLUGIN_ROOT}` → **플러그인 번들 안의 스크립트**(읽기 전용 배포물). 훅이 호출하는 `.sh`/`.py`는 여기.
- `${CLAUDE_PROJECT_DIR}` → **현재 프로젝트의 산출물**(가변 상태). roadmap·notifications.log·pending-resume.json·session-log는 여기.

### 치환 매핑

| 현재 하드코딩 | 치환 |
|---------------|------|
| 훅 command가 호출하는 스크립트 경로 | `${CLAUDE_PLUGIN_ROOT}/hooks/<script>` |
| `.planning/` 상태 파일 (roadmap, notifications.log, pending-resume.json, session-log) | `${CLAUDE_PROJECT_DIR}/.orbit/` |
| `_team/` 스크립트 상호 호출 (notify-done→notify) | `${CLAUDE_PLUGIN_ROOT}/scripts/` |
| tmux 세션명 `oremi` | env `ORBIT_TMUX_SESSION` (기본 `orbit`, `.orbit/config` 에서 override) |
| py 스크립트 `PLANNING = '/Users/.../.planning'` | `os.environ.get('CLAUDE_PROJECT_DIR', os.getcwd()) + '/.orbit'` |
| 트랜스크립트 검색 경로 `~/.claude/projects/-Users-dh-...` | `find ~/.claude/projects -path '*/subagents/agent-<id>.jsonl'` (세션 무관 결정적 검색 — 이미 attach-view.sh가 이 패턴) |

**훅이 stdin payload(JSON)를 받으므로** 대부분 스크립트는 인자 대신 stdin에서 데이터를 얻는다. 절대경로만 위 표대로 바꾸면 이식 가능.

**상태 디렉토리 통일:** `.planning/` → `.orbit/` 로 단일화(프레임워크 산출물 네임스페이스). gsd가 `.planning/`을 쓰므로 충돌 회피 + 우리 프레임워크 식별성 확보.

---

## 4. 설계 항목 ③ — Claude Code 플러그인 구조

superpowers 레이아웃 미러링. **base + web-dev 프리셋을 한 마켓플레이스의 2개 플러그인**으로 배포(설치 시 선택).

```
orbit/                                  # git 저장소 루트 = 마켓플레이스
├── .claude-plugin/
│   └── marketplace.json                # 2개 플러그인 등록 (orbit-base, orbit-web-dev)
├── plugins/
│   ├── orbit-base/                     # 도메인 무관 골격
│   │   ├── .claude-plugin/
│   │   │   └── plugin.json             # CC 매니페스트
│   │   ├── .codex-plugin/plugin.json   # Codex 매니페스트 ("skills":"./skills/")
│   │   ├── agents/
│   │   │   ├── leader.md               # (a) 그대로
│   │   │   ├── architect.md            # (b) 골격 (도메인 슬롯 변수)
│   │   │   ├── builder.md              # (b) fullstack 골격 일반화
│   │   │   └── reviewer.md             # (b) qa 3갈래 조율 골격
│   │   ├── skills/
│   │   │   └── using-orbit/
│   │   │       ├── SKILL.md            # AI 중립 방법론 prose (1벌, 원천)
│   │   │       └── references/
│   │   │           ├── codex-tools.md  # 도구명 매핑 (Task→spawn_agent 등)
│   │   │           └── gemini-tools.md
│   │   ├── commands/
│   │   │   ├── orbit-cycle.md          # 생명주기 1건 실행 가이드 슬래시커맨드
│   │   │   └── orbit-init.md           # 프로젝트에 .orbit/ 스캐폴딩
│   │   ├── hooks/
│   │   │   ├── hooks.json              # ${CLAUDE_PLUGIN_ROOT} 경로화
│   │   │   ├── usage-detect.py
│   │   │   ├── resume-inject.py
│   │   │   ├── session-log.sh
│   │   │   ├── quality-gate.sh         # ${CLAUDE_PROJECT_DIR}/.orbit/quality-gate.sh 위임 래퍼
│   │   │   ├── notify-done.sh
│   │   │   └── viewer-attach.sh        # tmux 있으면 attach, 없으면 no-op (graceful)
│   │   ├── scripts/
│   │   │   ├── notify.sh
│   │   │   ├── attach-view.sh
│   │   │   └── agent-view.py
│   │   ├── templates/
│   │   │   ├── roadmap.template.md     # 빈 얇은 원장
│   │   │   ├── quality-gate.template.sh# 프로젝트가 채우는 게이트 (기본 no-op pass)
│   │   │   └── orbit-config.template   # ORBIT_TMUX_SESSION 등
│   │   ├── CLAUDE.md                   # AI 중립 운영 규율 (생명주기·컨텍스트 규칙)
│   │   ├── AGENTS.md -> CLAUDE.md      # 심링크 (Codex)
│   │   ├── GEMINI.md                   # @포인터 2줄 (Gemini)
│   │   ├── gemini-extension.json
│   │   └── README.md
│   └── orbit-web-dev/                  # 웹개발 프리셋 (orbit-base 위에 얹음)
│       ├── .claude-plugin/plugin.json
│       ├── agents/
│       │   ├── architect-web.md        # Next.js·types/api.ts·캐싱 specifics
│       │   ├── designer.md             # (c)에서 이식한 UI/UX
│       │   ├── fullstack.md            # Next.js App Router specifics
│       │   ├── qa-web.md               # SEO·반응형·shape 교차검증
│       │   └── researcher.md           # 외부소스 리서처 (네이버 레시피는 예시로 일반화)
│       ├── skills/
│       │   ├── nextjs-build/
│       │   ├── api-build/
│       │   ├── ui-design/
│       │   └── web-qa/
│       └── README.md
└── README.md                           # 설치 가이드 + 의존성
```

### 매니페스트 핵심

`marketplace.json` (저장소 루트):
```json
{
  "name": "orbit-marketplace",
  "owner": { "name": "<author>" },
  "plugins": [
    { "name": "orbit-base", "source": "./plugins/orbit-base", "description": "도메인 무관 멀티에이전트 팀 골격" },
    { "name": "orbit-web-dev", "source": "./plugins/orbit-web-dev", "description": "Next.js 풀스택 프리셋 (orbit-base 위)" }
  ]
}
```

`plugins/orbit-base/.claude-plugin/plugin.json`:
```json
{
  "name": "orbit-base",
  "version": "0.1.0",
  "description": "허브앤스포크 멀티에이전트 팀 + Triple Crown 검증 + 사용량 자동재개",
  "author": { "name": "<author>" },
  "license": "MIT",
  "keywords": ["agents","orchestration","workflow","tdd","review"]
}
```
(agents/commands/hooks/skills는 CC가 디렉토리 관례로 자동 발견 — 별도 선언 불필요.)

### 플러그인 의존성 (gstack/gsd/superpowers/RTK) 처리

플러그인 매니페스트에 **하드 의존 선언 메커니즘이 없다**(CC 미지원). 따라서:
- **권장 동반 설치 가이드** 방식: README + `orbit-init` 커맨드가 설치 여부를 감지(`/plugin` 목록 확인 안내)하고, 미설치 시 graceful degradation 메시지 출력.
- base는 **superpowers/gstack/gsd 없이도 핵심(허브앤스포크·생명주기·자동재개)이 동작**하도록 설계. 3갈래 검증은 "동반 플러그인 있으면 그 스킬 사용, 없으면 수동 체크리스트로 저하".
- 즉 의존을 **소프트 의존(soft dependency)** 으로 두고 README에 `/plugin marketplace add` 3줄 명시.

---

## 5. 설계 항목 ④ — 크로스AI 이식 레이어

### 노출 방식 (중복 0, superpowers 검증 패턴 1:1)

| AI | 컨텍스트 파일 | 방식 |
|----|---------------|------|
| Claude Code | `CLAUDE.md` | 원천 1벌 (AI 중립 prose) |
| Codex | `AGENTS.md` | **심볼릭 링크 → CLAUDE.md** (`ln -s CLAUDE.md AGENTS.md`) |
| Gemini | `GEMINI.md` | `@./skills/using-orbit/SKILL.md` + `@references/gemini-tools.md` **포인터 2줄** + `gemini-extension.json` |

→ 방법론 prose는 **한 곳(SKILL.md / CLAUDE.md)에만** 존재. 심링크·@포인터로 노출만. 수동 동기화 불필요.

### 도구명 매핑 (graceful degradation의 핵심)

`skills/using-orbit/references/codex-tools.md` 및 `gemini-tools.md`에 Claude 도구 → 타 AI 도구 매핑:

| 스킬이 참조하는 것 | Codex | Gemini |
|-------------------|-------|--------|
| `Agent`/`Task` (서브에이전트 디스패치) | `spawn_agent`/`wait_agent`/`close_agent` (multi_agent 활성 시) | 미지원 → 순차 단일 컨텍스트 폴백 |
| 훅(SubagentStart/Stop 등) | 미지원 → 수동 게이트 | 미지원 → 수동 게이트 |
| `Skill` 도구 | 네이티브 로드 | 네이티브/수동 로드 |
| Read/Write/Edit/Bash | 네이티브 파일·셸 도구 | 네이티브 파일·셸 도구 |

### "동작하는 것 / 안 하는 것" 매트릭스

| 기능 | Claude Code | Codex | Gemini |
|------|-------------|-------|--------|
| 허브앤스포크 서브에이전트 (Agent 디스패치) | ✅ 풀 | △ multi_agent on이면 가능 | ✗ → 단일 컨텍스트 순차 역할 전환 |
| 자동 훅 (typecheck 게이트·사용량 재개·뷰어) | ✅ 풀 | ✗ → 수동 | ✗ → 수동 |
| 생명주기 규율 (roadmap→plan→approval→구현→3갈래) | ✅ | ✅ | ✅ |
| Triple Crown 3갈래 검증 prose | ✅ (+동반 플러그인 스킬) | ✅ (수동 체크리스트) | ✅ (수동 체크리스트) |
| 슬래시 커맨드 | ✅ | 부분 | 부분 |
| 뷰어 팬 라이브 가시화 | ✅ (tmux) | ✗ | ✗ |

---

## 6. 설계 항목 ⑤ — 골격(base) + 프리셋 2층 구조

### 에이전트 골격화 방법

각 base 에이전트는 **역할 형태(form)만** 정의하고 도메인은 슬롯으로 비운다. 프리셋은 base 에이전트를 **대체(override)** 하거나 **보강**한다. CC 플러그인은 같은 이름 에이전트가 두 플러그인에 있으면 나중 설치가 덮어쓰지 않으므로, **프리셋은 다른 이름**(`fullstack`, `designer`, `architect-web`)으로 제공하고 README가 "web-dev 설치 시 builder 대신 fullstack 사용" 안내.

예 — base `architect.md` 골격:
```
# Architect (역할 형태)
- 사전: 요구사항 → 구조/인터페이스/배포 설계 → 플랜 산출 → 리드 보고
- 사후: "{{CONSISTENCY_LENS}}" 체크리스트로 일관성 검토
- {{DOMAIN_DESIGN_ITEMS}} ← 프리셋이 채움 (web-dev: 디렉토리·types/api.ts·캐싱·env·토폴로지)
```
web-dev `architect-web.md`는 이 골격을 상속하되 `{{...}}`를 Next.js 구체값으로 채운 완성본.

### 도메인 주입 지점

1. **프리셋 에이전트 정의** (web-dev의 agents/) — 가장 강한 주입.
2. **`.orbit/config`** (프로젝트 루트) — `PRODUCT_PATHS`, `QUALITY_GATE_CMD`, `TMUX_SESSION` 등 프로젝트별 값.
3. **프로젝트 CLAUDE.md** — 프로젝트가 자기 도메인 규칙 추가(오르미의 경우 Bot Mode 등은 여기에 남김).

### base가 단독으로 주는 가치 (프리셋 없이)
허브앤스포크 팀 + leader/architect/builder/reviewer 4역 + 생명주기 + 3갈래 검증 골격 + 사용량 자동재개 + (tmux 있으면) 뷰어. → 어떤 도메인(데이터분석·문서작성·CLI툴)에도 적용 가능.

---

## 7. 설계 항목 ⑥ — 단계적 저하 (graceful degradation) 정의

| 환경 | 사용자 경험 |
|------|------------|
| **Claude Code (풀)** | `/plugin install` → 에이전트·훅·커맨드·뷰어 전부 활성. 리드가 Agent() 디스패치, 훅이 자동 게이트·사용량 재개·뷰어 라이브. 동반 플러그인(superpowers/gstack/gsd) 있으면 3갈래에 그 스킬 사용. |
| **Codex (프로세스 규율)** | AGENTS.md가 방법론 로드. multi_agent on이면 spawn_agent로 역할 분담, off면 단일 컨텍스트에서 역할을 순차 전환. 훅 없음 → 게이트/재개는 사용자가 수동 실행(스크립트는 그대로 호출 가능). 생명주기·3갈래 규율은 그대로 따름. |
| **Gemini (프로세스 규율 최소)** | GEMINI.md가 방법론 prose 로드. 서브에이전트·훅 없음 → 단일 에이전트가 생명주기 단계를 의식적으로 밟고, 3갈래 검증을 수동 체크리스트로 수행. 핵심 가치(계획→승인→구현→검증 규율)는 보존. |

**저하 원칙:** 자동화(훅·서브에이전트·뷰어)는 사라지되 **방법론 규율은 모든 환경에서 동일하게 생존**. "안 되면 멈추는" 게 아니라 "수동으로라도 같은 절차".

---

## 8. 설계 항목 ⑦ — 검증 방법 (스모크 절차)

빈 프로젝트에 설치 → 동작 확인. **수동 스모크 체크리스트**(자동 테스트는 과설계 — 1인 유지 가능 수준 유지).

### 스모크 A — Claude Code 설치 (필수)
1. 새 임시 디렉토리 `mktemp -d` → `git init` → 빈 프로젝트.
2. `/plugin marketplace add <orbit repo>` → `/plugin install orbit-base`.
3. `/orbit-init` 실행 → `.orbit/`(roadmap.template·config·quality-gate) 스캐폴딩 확인.
4. `leader`/`architect`/`builder`/`reviewer` 에이전트가 `/agents`에 노출되는지 확인.
5. 훅 동작: 더미 SubagentStop → quality-gate.sh 호출되는지, notifications.log append 되는지.
6. 사용량 자동재개: usage-detect.py에 가짜 경고 stdin 주입 → pending-resume.json 생성 확인 → resume-inject.py가 프롬프트 주입 확인.
7. `${CLAUDE_PLUGIN_ROOT}`·`${CLAUDE_PROJECT_DIR}`가 실제 경로로 치환되는지 (하드코딩 `/Users/dh` 잔존 0 — `grep -rn '/Users/dh'` = 0건).

### 스모크 B — web-dev 프리셋 (필수)
8. `/plugin install orbit-web-dev` → `fullstack`/`designer`/`qa-web`/`architect-web` 노출 + 도메인 스킬 4종 로드 확인.

### 스모크 C — 크로스AI (best-effort)
9. Codex: AGENTS.md 심링크가 CLAUDE.md를 가리키는지, `cat AGENTS.md`가 prose 반환하는지. multi_agent on에서 spawn_agent 1회 디스패치 시도.
10. Gemini: GEMINI.md @포인터가 SKILL.md를 로드하는지(수동 확인).

### 스모크 D — 참조 무결성
11. `grep -rn 'oremi\|/Users/dh\|네이버\|부케' plugins/orbit-base` = 0건 (base에 오르미 잔재 없음).
12. base 단독 설치 시 web-dev 스킬 참조로 인한 에러 없음(소프트 의존 확인).

**합격 기준:** A·B·D 전부 통과 = 배포 가능. C는 best-effort(타 AI 환경 부재 시 코드 리뷰로 대체).

---

## 9. 리스크 & 열린 질문 (리드 결정 필요)

### 리스크
- **R1 (낮음):** CC 플러그인 변수 치환이 모든 훅 컨텍스트에서 동일하게 동작 안 할 수 있음 → 스모크 A-7로 조기 검출.
- **R2 (중간):** tmux 뷰어는 CC+tmux 세션 가정. 플러그인 사용자가 tmux 없으면 viewer-attach.sh가 no-op이어야 함(에러 금지) → graceful 처리 필수.
- **R3 (중간):** 소프트 의존(superpowers 등) 미설치 시 3갈래 스킬 호출이 "스킬 없음" 에러 내지 않게 사전 감지 분기 필요.
- **R4 (낮음):** Codex multi_agent·Gemini는 우리가 실제 검증 환경이 없을 수 있음 → C는 best-effort로 격하, 미검증 명시.
- **R5 (낮음):** 오르미 현행 셋업을 **그대로 두고** 별도 repo로 추출하느냐, in-place 리팩터하느냐. 추출 권장(오르미 동작 보존).

### 열린 질문
- **Q1:** 프레임워크 명칭 — `orbit` 임시. 리드/사용자 확정?
- **Q2:** base와 web-dev를 **하나의 마켓플레이스 2플러그인**(권장) vs **2개 repo**? 권장: 1 repo.
- **Q3:** 추출 위치 — 오르미 repo 안 서브디렉토리 vs 신규 repo `~/Project/orbit`? 권장: 신규 repo(오르미 오염 방지).
- **Q4:** researcher를 base 옵션으로 둘지 web-dev에 둘지? 권장: web-dev(네이버 레시피 결합도 높음). base엔 "읽기전용 리서처 골격"만 옵션.
- **Q5:** 오르미 자체는 이 플러그인을 **역으로 설치해서 dogfood**할지(현 in-place 셋업 → 플러그인 설치로 교체)? 권장: Phase 5에서 별도 결정(범위 밖).

---

## 10. 설계 결정 이유 (ADR 요약)

- **ADR-1:** superpowers 레이아웃 1:1 차용 — 검증된 크로스AI 패턴(심링크·@포인터·codex-tools 매핑) 재발명 금지.
- **ADR-2:** 상태 디렉토리 `.planning/` → `.orbit/` — gsd `.planning/`과 충돌 회피 + 프레임워크 네임스페이스 식별.
- **ADR-3:** 의존성은 소프트 의존 — CC가 하드 의존 미지원 + base 단독 가치 보존 + graceful degradation.
- **ADR-4:** base/web-dev 2플러그인 1마켓플레이스 — 선택 설치 + 도메인 분리.
- **ADR-5:** 품질 게이트는 `${CLAUDE_PROJECT_DIR}/.orbit/quality-gate.sh`로 위임 — npm/cargo/go 등 스택 중립.
- **ADR-6:** 신규 repo 추출 — 오르미 동작 보존(in-place 리팩터 위험 회피).
- **ADR-7:** 크로스AI는 graceful degradation 우선, 완전 동등성 비목표 — 1인 유지 가능 수준.

---

## 부록 — 구현 플랜은 별도 파일

phased writing-plans: `docs/superpowers/specs/2026-06-18-team-framework-packaging-plan.md`
