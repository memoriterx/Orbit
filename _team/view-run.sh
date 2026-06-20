#!/bin/bash
# view-run.sh <label> <transcript> — 뷰어 기동 래퍼.
# attach-view.sh가 send-keys로 호출한다. 긴 복합 명령 대신 이 한 줄만
# 팬에 echo되게 해 셸 입력 잡음을 줄인다.
# --follow 종료(다음 attach의 pkill) 후 --wait 배너가 포그라운드를 점유 → 프롬프트(%) 비노출.
LABEL="$1"; TRANSCRIPT="$2"
VIEWER="$(dirname "$0")/agent-view.py"
echo ''
echo "━━━━━━━━━━ $LABEL ━━━━━━━━━━"
python3 "$VIEWER" "$LABEL" --file "$TRANSCRIPT" --follow
python3 "$VIEWER" "$LABEL" --wait
