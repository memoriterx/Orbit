#!/bin/bash
# SubagentStop 훅용 — stdin=payload(JSON). 완료 알림을 notifications.log에 기록.
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)"
NOTIFY="$SCRIPT_DIR/notify.sh"
[ ! -x "$NOTIFY" ] && exit 0

payload=$(cat 2>/dev/null)
at=$(printf '%s' "$payload" | jq -r '.agent_type // "agent"' 2>/dev/null)
aid=$(printf '%s' "$payload" | jq -r '.agent_id // ""' 2>/dev/null)
aid8="${aid:0:8}"
last=$(printf '%s' "$payload" | jq -r '.last_assistant_message // ""' 2>/dev/null)
summary=$(printf '%s' "$last" | head -1 | cut -c1-60)

if [ -n "$summary" ]; then
    "$NOTIFY" "[완료] $at (${aid8}) — ${summary}" >/dev/null 2>&1
else
    "$NOTIFY" "[완료] $at (${aid8})" >/dev/null 2>&1
fi
exit 0
