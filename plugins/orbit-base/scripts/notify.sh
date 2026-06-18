#!/bin/bash
# notify.sh "<메시지>" — .orbit/notifications.log 에 타임스탬프 이벤트 1줄 append.
#
# 용도: 리드가 Agent를 디스패치하거나 완료를 수신할 때 이벤트를 기록한다.
#
# 예:
#   notify.sh "[디스패치] architect 사전검토 (agent ab12..)"
#   notify.sh "[완료] builder P1 구현 — tsc 통과, 아키 사후검토 요청"

ORBIT="${CLAUDE_PROJECT_DIR}/.orbit"
NOTIF="$ORBIT/notifications.log"
MSG="$*"
[ -z "$MSG" ] && { echo "사용법: notify.sh \"<메시지>\""; exit 1; }
mkdir -p "$ORBIT"
printf '[%s] %s\n' "$(date +%H:%M)" "$MSG" >> "$NOTIF"
