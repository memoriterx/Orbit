#!/bin/bash
# attach-view.sh <pane> <label> <agentId>
# Agent()가 반환한 agentId의 서브에이전트 트랜스크립트를 찾아 해당 팬에 라이브 뷰 표시.
# 세션명: orbit-dev
PANE="$1"; LABEL="$2"; AGENTID="$3"
PROJDIR="$HOME/.claude/projects/-Users-dh-Project-orbit"
VIEWER="$HOME/Project/orbit/_team/agent-view.py"

if [ -z "$AGENTID" ]; then
    echo "사용법: attach-view.sh <pane> <label> <agentId>"; exit 1
fi

# 서브에이전트 트랜스크립트 등장 대기 (최대 30초)
TRANSCRIPT=""
for i in $(seq 1 60); do
    TRANSCRIPT=$(find "$PROJDIR" -path "*/subagents/agent-$AGENTID.jsonl" 2>/dev/null | head -1)
    [ -n "$TRANSCRIPT" ] && break
    sleep 0.5
done
if [ -z "$TRANSCRIPT" ]; then
    echo "agentId=$AGENTID 트랜스크립트 못 찾음 (30초 타임아웃)"; exit 1
fi
echo "감지: $TRANSCRIPT"
# 기존 --follow 프로세스만 종료 (팬 내용은 유지)
pkill -f "agent-view.py" 2>/dev/null || true
sleep 0.3
# 구분선 출력 후 새 에이전트 이어서 출력
# --follow 뷰어 종료(다음 attach의 pkill) 후 --wait 배너가 포그라운드를 점유 → 셸 프롬프트(%) 비노출
tmux send-keys -t "orbit-dev:0.$PANE" "echo '' && echo '━━━━━━━━━━ $LABEL ━━━━━━━━━━' && python3 '$VIEWER' '$LABEL' --file '$TRANSCRIPT' --follow; python3 '$VIEWER' '$LABEL' --wait" Enter
echo "팬 $PANE 에 '$LABEL' 이어서 연결됨 → $TRANSCRIPT"
