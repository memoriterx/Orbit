#!/bin/bash
# SubagentStop 훅용 — 품질 게이트 위임 래퍼.
#
# 동작:
#   ${CLAUDE_PROJECT_DIR}/.orbit/quality-gate.sh 가 있으면 실행한다.
#   없으면 pass(exit 0) — base는 특정 빌드 도구(npm/cargo/go)를 모름.
#   있고 실패하면 block JSON을 stdout에 출력한다.
#
# 프로젝트는 .orbit/quality-gate.sh 에 자신의 게이트를 정의한다.
# 예시: templates/quality-gate.template.sh 참조.

GATE="${CLAUDE_PROJECT_DIR}/.orbit/quality-gate.sh"

if [ ! -f "$GATE" ]; then
    exit 0
fi

if [ ! -x "$GATE" ]; then
    exit 0
fi

output=$("$GATE" 2>&1)
rc=$?

if [ $rc -ne 0 ]; then
    printf '{"decision":"block","reason":%s}' \
        "$(printf 'quality-gate 실패\n%s' "$output" | jq -Rs .)"
fi

exit 0
