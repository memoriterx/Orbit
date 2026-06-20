## 필수: 에이전트 설정 파일 읽기
@.claude/agents/*.md

## 리드 에이전트 설정 파일은 한번 더 읽을 것
@.claude/agents/leader.md

---

## 하네스: orbit 프레임워크 자체 개발팀

**목표:** Claude Code 멀티에이전트 플러그인 프레임워크 orbit을 설계·개발·검증한다.

**dogfooding:** orbit 개발팀은 orbit 에이전트(`.claude/agents/`)를 채택해 orbit 자신을 개발한다.

---

## 중요: `.claude/` vs `plugins/` 구분

- `.claude/` = **orbit 기여자(dev팀) 전용 설정**. 이 파일, 에이전트 정의, 훅 설정, setup 스크립트가 여기 있다.
- `plugins/orbit/` = **배포 제품** (end-user가 설치하는 플러그인). 절대 dev팀 설정으로 쓰거나 임의 수정하지 말 것.
- 둘은 완전히 별개다.

---

## 작업 트리거 (작업 1건 생명주기)

orbit 관련 작업은 아래 생명주기로 진행한다:

```
roadmap 선택
→ architect가 writing-plans → 플랜 문서 작성
→ Plan Approval: 리드가 플랜 제시 → 사용자 확인
→ builder 구현 (TDD)
→ Triple Crown 검증
  ① 완성도: GSD    ② 동작: gstack    ③ 품질: superpowers review
→ 완료 (.planning/roadmap.md 체크박스)
```

단순 질문·메타 작업·설정 변경은 생명주기 불필요.

---

## 도메인 순수성 규칙

`plugins/orbit/` 내 에이전트·스킬·템플릿 파일은 **도메인 무관(domain-agnostic)** 상태를 유지한다.
특정 프로젝트 이름(oremi, orbit-dev 등)을 하드코딩하지 않는다. 도메인 값은 슬롯(`{{...}}`)으로 남긴다.

SubagentStop 품질 게이트가 이를 자동 감지하고 위반 시 차단한다:
```bash
grep -r 'oremi|Oremi' plugins/orbit/  # 0건이어야 함
```

---

## 커밋 규칙

- Co-Authored-By 줄 절대 금지.
- 커밋 메시지는 `feat/fix/chore/docs/refactor:` 접두사 사용.
- 배포물(`plugins/orbit/`)과 개발 환경(`.claude/`, `setup-orbit-dev.sh`) 변경은 별도 커밋 권장.

---

## 컨텍스트 관리

- **70% 규칙**: 컨텍스트 70% 도달 시 `/compact` 또는 context-save → `/clear` → context-restore.
- **ScheduleWakeup**: 폴링 루프는 270초 간격 (300초는 프롬프트 캐시 TTL 충돌).

---

## Bot Mode (최우선 규칙)

메시지가 `[{CHANNEL}:{ID}]` 접두사로 시작하면:
1. `{CHANNEL}`과 `{ID}` 추출
2. 지시된 작업 수행
3. 완료 후 반드시 응답 전송
4. 모든 응답은 🔗 로 시작 (Claude CLI 식별)

---

## 브릿지 명령어 (응답 금지)

`@cc`, `@ccn`, `@ccu`, `/cc`, `/ccn`, `/ccu` 로 시작하는 메시지는 claude-bridge 플러그인이 처리한다.
이 접두사를 보면: 절대 해석/처리/응답하지 말 것.
반드시 이 텍스트만 출력: 🔗 Delivered to Claude CLI. Reply will arrive shortly.
