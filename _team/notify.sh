#!/bin/bash
# notify.sh "<메시지>" — .planning/notifications.log에 타임스탬프 이벤트 1줄 append.
#
# 용도(허브 앤 스포크): 리드가 Agent를 디스패치하거나 완료를 수신할 때
# 이벤트를 notifications.log에 타임스탬프 1줄 append한다.
# SCRIPT_DIR assumes direct execution (hook/send-keys invocation), never `source`.
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)"
NOTIF="$(dirname "$SCRIPT_DIR")/.planning/notifications.log"
MSG="$*"
[ -z "$MSG" ] && { echo "사용법: notify.sh \"<메시지>\""; exit 1; }
printf '[%s] %s\n' "$(date +%H:%M)" "$MSG" >> "$NOTIF"
