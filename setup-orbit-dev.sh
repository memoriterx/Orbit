#!/bin/bash
# setup-orbit-dev.sh — orbit 프레임워크 자체 개발팀 환경 자동 구성 (2 pane / 허브 앤 스포크)
#
# ★ 이 스크립트는 orbit 프레임워크 개발자(contributor)용이다.
# ★ 제품 설치용(end-user 대상) 스크립트는 setup-orbit.sh 이다. 혼동 금지.
#
# 레이아웃 (2 panes):
#   ┌───────────────────────┬───────────────────────────────┐
#   │  [0] 리드 팀장         │  [1] 뷰어                    │
#   │  (유일한 실제 CLI)     │  (서브에이전트 라이브 뷰)     │
#   │         (좌우 50:50)   │                               │
#   └───────────────────────┴───────────────────────────────┘
#
# 운영 모델:
#   - 리드(pane 0)만 실제 Claude CLI. 에이전트는 리드 안에서 Agent()로 임시 생성·소멸.
#   - 서브에이전트 트랜스크립트는 ~/.claude/projects/-Users-dh-Project-orbit/<sid>/subagents/ 에 생성.
#   - SubagentStart 훅(auto-attach.sh)이 뷰어 팬(1)에 라이브 렌더를 자동 연결.

set -e

GREEN='\033[0;32m'
CYAN='\033[0;36m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

SESSION="orbit-dev"          # ← 오르미(oremi), 제품(orbit)과 다른 세션명
PROJECT="$HOME/Project/orbit"
NOTIF_LOG="$PROJECT/.planning/notifications.log"

# ── 유틸: 팬에 패턴이 나타날 때까지 대기 ──────────────────
wait_for_pane() {
    local pane="$1" pattern="$2" timeout="${3:-30}" waited=0
    while [ $waited -lt $timeout ]; do
        tmux capture-pane -t "$pane" -p 2>/dev/null | grep -qi "$pattern" && return 0
        sleep 1; waited=$((waited + 1))
    done
    return 1
}

# ── 유틸: Claude 실행 + 다이얼로그 자동 처리 ────────────────
start_claude_in_pane() {
    local pane="$1" agent_name="${2:-}"
    local claude_bin; claude_bin="$(command -v claude)"

    tmux send-keys -t "$pane" C-c 2>/dev/null; sleep 0.3
    tmux send-keys -t "$pane" C-u 2>/dev/null; sleep 0.2

    local cmd="cd \"$PROJECT\" && unset CLAUDECODE && $claude_bin --dangerously-skip-permissions"
    [ -n "$agent_name" ] && cmd="$cmd --agent \"$agent_name\""

    tmux send-keys -t "$pane" "$cmd" Enter

    # 다이얼로그 1: trust folder → Enter
    wait_for_pane "$pane" "trust this folder" 10 && {
        tmux send-keys -t "$pane" Enter; sleep 1
    }
    # 다이얼로그 2: terms of service → Down + Enter
    wait_for_pane "$pane" "I accept" 10 && {
        tmux send-keys -t "$pane" Down; sleep 0.5
        tmux send-keys -t "$pane" Enter; sleep 1
    }

    wait_for_pane "$pane" "bypass permissions" 30 || true
}

# ── [0/5] 사전 요구사항 확인 ────────────────────────────────
echo -e "${YELLOW}[0/5] 사전 요구사항 확인...${NC}"

MISSING=()
command -v tmux   &>/dev/null || MISSING+=("tmux")
command -v claude &>/dev/null || MISSING+=("claude (npm install -g @anthropic-ai/claude-code)")
command -v python3 &>/dev/null || MISSING+=("python3 (뷰어 렌더용)")
command -v jq &>/dev/null || MISSING+=("jq (훅 JSON 파싱용)")

if [ ${#MISSING[@]} -gt 0 ]; then
    echo -e "${RED}누락된 의존성:${NC}"
    for m in "${MISSING[@]}"; do echo "   - $m"; done
    exit 1
fi

echo "  tmux $(tmux -V | awk '{print $2}')"
echo "  claude $(claude --version 2>/dev/null | head -1)"
echo "  python3 $(python3 --version 2>/dev/null | awk '{print $2}')"

mkdir -p "$PROJECT/.planning"
if [ -s "$NOTIF_LOG" ]; then
    mv "$NOTIF_LOG" "$PROJECT/.planning/notifications.$(date +%Y%m%d-%H%M%S).log"
fi
touch "$NOTIF_LOG"
printf '[%s] ── orbit-dev 세션 시작 ──\n' "$(date +%H:%M)" >> "$NOTIF_LOG"
echo "  notifications.log 준비"

# ── [1/5] 기존 세션 정리 ────────────────────────────────────
echo -e "\n${YELLOW}[1/5] 기존 세션 초기화...${NC}"
tmux has-session -t "$SESSION" 2>/dev/null && {
    tmux kill-session -t "$SESSION"
    echo "  기존 '$SESSION' 세션 종료"
}

# ── [2/5] TMUX 세션 & 레이아웃 구성 ────────────────────────
echo -e "\n${YELLOW}[2/5] TMUX 세션 & 레이아웃 구성...${NC}"

TERM_WIDTH=$(tput cols 2>/dev/null || echo 280)
TERM_HEIGHT=$(tput lines 2>/dev/null || echo 65)
[ "$TERM_WIDTH" -lt 200 ] 2>/dev/null && TERM_WIDTH=280
[ "$TERM_HEIGHT" -lt 50 ] 2>/dev/null && TERM_HEIGHT=65

LEFT_WIDTH=$(( (TERM_WIDTH - 1) / 2 ))
RIGHT_WIDTH=$(( TERM_WIDTH - LEFT_WIDTH - 1 ))
if [ "$RIGHT_WIDTH" -lt 120 ]; then
    echo -e "  ${YELLOW}터미널 폭이 좁습니다(${TERM_WIDTH}칸). 오른쪽 팬이 ${RIGHT_WIDTH}칸입니다.${NC}"
fi

# 세션 생성 (pane 0)
tmux new-session -d -s "$SESSION" -x "$TERM_WIDTH" -y "$TERM_HEIGHT"

# 좌우 2분할: pane 0 (리드, 좌) / pane 1 (뷰어, 우)
tmux split-window -t "$SESSION:0.0" -h

# 팬 표시 설정
tmux set-option -t "$SESSION" pane-border-status top
tmux set-option -t "$SESSION" pane-border-format " #{pane_title} "
tmux set-option -t "$SESSION" allow-rename off

# 너비 조정
tmux resize-pane -t "$SESSION:0.0" -x "$LEFT_WIDTH"

# 팬 이름 설정
tmux select-pane -t "$SESSION:0.0" -T "리드 팀장 (orbit-dev)"
tmux select-pane -t "$SESSION:0.1" -T "서브에이전트 라이브"

echo "  레이아웃 구성 완료 (2 panes, 세션: $SESSION)"

# ── [3/5] 프로세스 실행 ──────────────────────────────────────
echo -e "\n${YELLOW}[3/5] 프로세스 실행 중...${NC}"

# pane 1 (뷰어): 대기 안내
tmux send-keys -t "$SESSION:0.1" \
    "clear; printf '\033[1;35m━━ 뷰어 (대기) ━━\033[0m\n서브에이전트가 시작되면 자동으로\n여기에 라이브 트랜스크립트가 연결됩니다.\n수동 연결: _team/attach-view.sh 1 <라벨> <agentId>\n'" Enter
echo "  Pane 1 (뷰어): 대기 모드"

# pane 0 (리드): 실제 Claude CLI 실행
echo -n "  Pane 0 (리드): "
start_claude_in_pane "$SESSION:0.0"
tmux capture-pane -t "$SESSION:0.0" -p 2>/dev/null | grep -qi "bypass permissions" \
    && echo -e "${GREEN}준비 완료${NC}" \
    || echo -e "${RED}타임아웃 — 수동 확인 필요${NC}"

# ── [4/5] 운영 안내 ──────────────────────────────────────────
echo -e "\n${YELLOW}[4/5] 운영 모델: 허브 앤 스포크 + 라이브 뷰${NC}"
echo "  · 모든 작업은 리드(pane 0)가 Agent()로 위임한다."
echo "  · 라이브 뷰: SubagentStart 훅(auto-attach.sh)이 뷰어(pane 1)에 자동 연결."
echo "      수동 연결: _team/attach-view.sh 1 <라벨> <agentId>"
echo "  · 이전 에이전트 출력은 지워지지 않고 구분선 아래 누적된다."
echo ""
echo "  ★ 이 환경은 orbit 개발자(contributor)용이다."
echo "  ★ 배포 플러그인(plugins/)은 이 환경과 별개다."

# ── [5/5] 완료 ──────────────────────────────────────────────
echo -e "\n${GREEN}"
echo "  ╔══════════════════════════════════════════════════╗"
echo "  ║   orbit 개발팀 환경 구성 완료! (2 panes)         ║"
echo "  ║   세션: orbit-dev                                ║"
echo "  ║  [0] 리드 팀장      [1] 뷰어                     ║"
echo "  ╚══════════════════════════════════════════════════╝"
echo -e "${NC}"

# 시작 포커스는 항상 리드(pane 0)
tmux select-pane -t "$SESSION:0.0"

[ -t 1 ] && tmux attach -t "$SESSION"
