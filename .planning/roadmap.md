# orbit 개발 로드맵

**업데이트:** 2026-06-18  
**상태 경로:** `.planning/`  
**보고 채널:** `.planning/notifications.log`

---

## 현재 진행 중

(없음 — 신규 dev 환경 구성 완료. 다음 작업은 아래 백로그에서 선택.)

---

## 백로그

### OMC 흡수 — orbit-base 개선 4건

- [x] **[OMC-1] 역할별 모델 티어 명시** (2026-06-18, 커밋 `dc6450e`)  
  researcher=haiku, builder=sonnet, architect/reviewer=opus, leader=sonnet.  
  실측 결과 4종은 이미 목표 티어와 일치 → researcher.md 단 1건만 sonnet→haiku 변경. Triple Crown 3갈래 PASS.

- [x] **[OMC-2] executor/verifier 분리** (2026-06-18, 커밋 `5668e08`·`b45d8f9`·`df70a82`·`b7b2dc9`)  
  ADR-1: verifier.md 신규 추가 대신 **기존 reviewer가 verifier 흡수** (이미 독립 에이전트로 분리됨).  
  builder self-check를 비권위적 pre-flight로 강등, reviewer를 완료 판정 권한 보유자로 명시.  
  4개 표면(builder/reviewer/leader.md + using-orbit SKILL) 프롬프트 정렬. Triple Crown 3갈래 PASS.

- [x] **[OMC-3] skillify 패턴** (2026-06-18, 커밋 `2fe8832`·`2d4c453`·`f799afb`·`cabb932`)  
  신규 `skills/skillify/SKILL.md` — 트리거 Rule of Three(3회 규칙), 라우팅 reviewer 감지→leader→architect 추출→builder 작성.  
  ADR-3: native skill discovery로 자동주입(신규 훅 0). ADR-4: authoring은 superpowers writing-skills에 위임(중복 회피).  
  using-orbit/leader/reviewer 정렬. Triple Crown 3갈래 PASS.

- [x] **[OMC-4] ralplan식 3자 비판 계획** (2026-06-18, 커밋 `c63a0b8`·`c516343`·`182564b`·`44bd26a`)  
  신규 `agents/critic.md`(opus, 6번째 에이전트) — 고위험 결정 시 architect 플랜 독립 비판(PROCEED/REVISE).  
  고위험 4트리거 OR 게이트(비가역성/광범위 영향/보안·무결성/신규 외부 의존성), leader가 Plan Approval 직전 판정, 저위험은 분기 생략.  
  leader/CLAUDE/using-orbit SKILL/codex/gemini 정렬. ADR-1: critic은 신규(self-approval 차단의 설계 단계 적용). Triple Crown 3갈래 PASS.

---

## 완료

- [x] **orbit 자체 개발팀 환경 구성** (2026-06-18)  
  `.claude/agents/` (5역: leader/architect/builder/reviewer/researcher),  
  `.claude/settings.json` (훅 6종: Stop/Notification/MessageDisplay/UserPromptSubmit/SubagentStop/SubagentStart),  
  `CLAUDE.md`, `setup-orbit-dev.sh`, `.planning/roadmap.md` + usage-detect/resume-inject 이식.

---

## 마일스톤

| 마일스톤 | 목표 | 기준 |
|----------|------|------|
| M1 — 팀 환경 | dev팀이 orbit을 dogfooding으로 개발 가능 | 완료 |
| M2 — OMC 흡수 | 4건 백로그 완료 + orbit-base 품질 게이트 통과 | **완료 (2026-06-18)** |
| M3 — 릴리스 v0.2 | 에이전트 모델 티어 + executor/verifier 분리 반영 | **로컬 완료 (2026-06-18, 태그 `v0.2.0`)** — 외부 게시 사용자 승인 대기 |
