#!/bin/bash
# attach-view.sh <pane> <label> <agentId>
# Agent()가 반환한 agentId의 서브에이전트 트랜스크립트를 찾아 해당 팬에 라이브 뷰 표시.
#
# 트랜스크립트 검색: ~/.claude/projects 전체를 agentId로 결정적 검색.
# tmux 세션명: ORBIT_TMUX_SESSION 환경변수 (기본 "orbit"), .orbit/config 에서 override 가능.

PANE="$1"; LABEL="$2"; AGENTID="$3"
VIEWER="${CLAUDE_PLUGIN_ROOT}/scripts/agent-view.py"
RUNNER="${CLAUDE_PLUGIN_ROOT}/scripts/view-run.sh"
SESSION="${ORBIT_TMUX_SESSION:-orbit}"

if [ -z "$AGENTID" ]; then
    echo "사용법: attach-view.sh <pane> <label> <agentId>"; exit 1
fi

# .orbit/config 가 있으면 로드 (ORBIT_TMUX_SESSION override)
ORBIT_CONFIG="${CLAUDE_PROJECT_DIR}/.orbit/config"
if [ -f "$ORBIT_CONFIG" ]; then
    # shellcheck disable=SC1090
    source "$ORBIT_CONFIG" 2>/dev/null || true
    SESSION="${ORBIT_TMUX_SESSION:-$SESSION}"
fi

# 서브에이전트 트랜스크립트 등장 대기 (최대 30초)
TRANSCRIPT=""
for i in $(seq 1 60); do
    TRANSCRIPT=$(find "$HOME/.claude/projects" -path "*/subagents/agent-$AGENTID.jsonl" 2>/dev/null | head -1)
    [ -n "$TRANSCRIPT" ] && break
    sleep 0.5
done
if [ -z "$TRANSCRIPT" ]; then
    echo "agentId=$AGENTID 트랜스크립트 못 찾음 (30초 타임아웃)"; exit 1
fi
echo "감지: $TRANSCRIPT"

# 기존 follow 프로세스 종료 (팬 내용은 유지)
pkill -f "agent-view.py" 2>/dev/null || true
sleep 0.3

# 구분선 출력 후 새 에이전트 이어서 출력
# 긴 복합 명령 대신 래퍼 한 줄만 팬에 echo (셸 입력 잡음 최소화)
tmux send-keys -t "${SESSION}:0.$PANE" "'$RUNNER' '$LABEL' '$TRANSCRIPT'" Enter
echo "팬 $PANE 에 '$LABEL' 이어서 연결됨 → $TRANSCRIPT"
