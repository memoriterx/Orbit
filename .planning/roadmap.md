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

- [ ] **[OMC-1] 역할별 모델 티어 명시**  
  researcher=haiku(경량 탐색), builder=sonnet(구현), architect/reviewer=opus(설계·검토).  
  orbit-base 에이전트 frontmatter `model:` 필드에 반영. dev팀 에이전트(`.claude/agents/`)는 이미 적용.  
  _다음 작업: orbit-base 에이전트 파일 4종 frontmatter 업데이트._

- [ ] **[OMC-2] executor/verifier 분리**  
  현재 builder가 구현 + 1차 검증을 겸함 → 자기승인 위험.  
  verifier 역할을 별도 에이전트로 분리해 builder 완료 후 독립 검증.  
  _다음 작업: orbit-base에 verifier.md 추가 + builder.md에서 자체 검증 절차 분리._

- [ ] **[OMC-3] skillify 패턴**  
  반복적으로 해결되는 문제를 스킬 파일(SKILL.md)로 추출·자동주입하는 패턴 도입.  
  orbit-base `skills/` 디렉터리에 새 스킬 정의 형식 명세 추가.  
  _다음 작업: skillify 스킬 정의 + 스킬 추출 트리거 명세 작성._

- [ ] **[OMC-4] ralplan식 3자 비판 계획**  
  고위험 아키텍처 결정 시 critic 역할이 architect 플랜을 독립 비판.  
  orbit-base에 `critic.md` 에이전트 추가 + leader.md에 고위험 판단 기준 명시.  
  _다음 작업: 고위험 결정 트리거 정의 → critic 에이전트 프롬프트 작성._

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
| M2 — OMC 흡수 | 4건 백로그 완료 + orbit-base 품질 게이트 통과 | 미완 |
| M3 — 릴리스 v0.2 | 에이전트 모델 티어 + executor/verifier 분리 반영 | 미완 |
