#!/bin/bash
# SubagentStart 훅용 — stdin=훅 payload(JSON). 서브에이전트 트랜스크립트를 뷰어 팬에
# 라이브 연결한다. tmux 미설치 환경에서는 에러 없이 no-op으로 종료한다.

# tmux 부재 시 graceful no-op (R2)
if ! command -v tmux >/dev/null 2>&1; then
    exit 0
fi

payload=$(cat 2>/dev/null)
aid=$(printf '%s' "$payload" | jq -r '.agent_id // empty' 2>/dev/null)
atype=$(printf '%s' "$payload" | jq -r '.agent_type // "agent"' 2>/dev/null)
[ -z "$aid" ] && exit 0

ATTACH="${CLAUDE_PLUGIN_ROOT}/scripts/attach-view.sh"
[ ! -x "$ATTACH" ] && exit 0

nohup "$ATTACH" "1" "$atype" "$aid" >/dev/null 2>&1 &
exit 0
