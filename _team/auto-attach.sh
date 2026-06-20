#!/bin/bash
# SubagentStart 훅용 — stdin=훅 payload(JSON). 서브에이전트 트랜스크립트를 뷰어 팬(1)에
# 라이브 연결한다. 세션명 orbit-dev 기준.
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)"
PROJ="$(dirname "$SCRIPT_DIR")"
payload=$(cat 2>/dev/null)
aid=$(printf '%s' "$payload" | jq -r '.agent_id // empty' 2>/dev/null)
atype=$(printf '%s' "$payload" | jq -r '.agent_type // "agent"' 2>/dev/null)
[ -z "$aid" ] && exit 0

# 뷰어 팬 1에 라이브 연결
if [ -x "$PROJ/_team/attach-view.sh" ]; then
  nohup "$PROJ/_team/attach-view.sh" "1" "$atype" "$aid" >/dev/null 2>&1 &
fi
exit 0
