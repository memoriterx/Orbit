#!/bin/bash
# setup-orbit.sh — Claude multi-agent team environment setup (2-pane / hub-and-spoke)
#
# Layout (2 panes):
#   ┌───────────────────────┬───────────────────────────────┐
#   │  [0] Lead (hub)        │  [1] Viewer                  │
#   │  (only real Claude CLI)│  (subagent live transcript)  │
#   │         (left/right 50:50)                             │
#   └───────────────────────┴───────────────────────────────┘
#
# Operating model:
#   - Lead (pane 0) is the only real Claude CLI instance.
#     Agents are created temporarily via Agent() inside the lead.
#   - Subagent transcripts are written to:
#       ~/.claude/projects/<session-id>/subagents/agent-<agentId>.jsonl
#   - The SubagentStart hook (viewer-attach.sh) auto-connects the viewer pane.
#
# Variables (all overridable via environment or .orbit/config):
#   ORBIT_TMUX_SESSION      — tmux session name            (default: "orbit")
#   CLAUDE_PROJECT_DIR      — project root                 (default: git root or pwd)
#   ORBIT_SKIP_PERMISSIONS  — pass --dangerously-skip-permissions to claude
#                             (default: true; set to "" to disable)
#   ORBIT_SKIP_PLUGIN_CHECK — skip orbit plugin detection & install step  (default: unset)
#   ORBIT_INSTALL_DEPS      — opt-in: install/update companion plugins     (default: unset)
#                             auto-installs: superpowers (claude-plugins-official marketplace)
#                             manual-only:   gstack, gsd (skills-dir install — instructions printed)
#   ORBIT_INSTALL_SCOPE     — plugin install scope: user, project, or local (default: user)
#                             user: available globally across all projects
#                             project: written to .claude/ in the current project
#                             local:   written to .claude/ but git-ignored (local override)
#   ORBIT_SKIP_UPDATE       — skip all update checks                       (default: unset)

set -euo pipefail

GREEN='\033[0;32m'
CYAN='\033[0;36m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# ── Plugin install scope ──────────────────────────────────────
# Validate ORBIT_INSTALL_SCOPE; fall back to "user" on invalid value.
_raw_scope="${ORBIT_INSTALL_SCOPE:-user}"
case "$_raw_scope" in
    user|project|local)
        ORBIT_INSTALL_SCOPE="$_raw_scope"
        ;;
    *)
        echo -e "${YELLOW}Warning: ORBIT_INSTALL_SCOPE='$_raw_scope' is not valid (user/project/local) — falling back to 'user'${NC}"
        ORBIT_INSTALL_SCOPE="user"
        ;;
esac
unset _raw_scope

# ── Session name ─────────────────────────────────────────────
SESSION="${ORBIT_TMUX_SESSION:-orbit}"

# ── Project root ──────────────────────────────────────────────
# Priority: CLAUDE_PROJECT_DIR env var → git root → pwd
if [ -n "${CLAUDE_PROJECT_DIR:-}" ]; then
    PROJECT="$CLAUDE_PROJECT_DIR"
elif git rev-parse --show-toplevel >/dev/null 2>&1; then
    PROJECT="$(git rev-parse --show-toplevel)"
else
    PROJECT="$(pwd)"
fi

# ── Notification log ─────────────────────────────────────────
ORBIT_DIR="$PROJECT/.orbit"
NOTIF_LOG="$ORBIT_DIR/notifications.log"

# ── Skip permissions flag (default: enabled) ──────────────────
# Default: ON (pass --dangerously-skip-permissions).
# Set ORBIT_SKIP_PERMISSIONS=0 to disable.

# ── Util: wait until a pattern appears in a pane ─────────────
wait_for_pane() {
    local pane="$1" pattern="$2" timeout="${3:-30}" waited=0
    while [ $waited -lt $timeout ]; do
        tmux capture-pane -t "$pane" -p 2>/dev/null | grep -qi "$pattern" && return 0
        sleep 1; waited=$((waited + 1))
    done
    return 1
}

# ── Util: launch claude in a pane, auto-handle dialogs ───────
start_claude_in_pane() {
    local pane="$1" agent_name="${2:-}"
    local claude_bin; claude_bin="$(command -v claude)"

    tmux send-keys -t "$pane" C-c 2>/dev/null; sleep 0.3
    tmux send-keys -t "$pane" C-u 2>/dev/null; sleep 0.2

    local cmd="cd \"$PROJECT\" && unset CLAUDECODE && $claude_bin"
    [ "${ORBIT_SKIP_PERMISSIONS:-1}" != "0" ] && cmd="$cmd --dangerously-skip-permissions"
    [ -n "$agent_name" ] && cmd="$cmd --agent \"$agent_name\""

    tmux send-keys -t "$pane" "$cmd" Enter

    # Dialog 1: trust folder → Enter
    wait_for_pane "$pane" "trust this folder" 10 && {
        tmux send-keys -t "$pane" Enter; sleep 1
    }
    # Dialog 2: terms of service → Down + Enter
    wait_for_pane "$pane" "I accept" 10 && {
        tmux send-keys -t "$pane" Down; sleep 0.5
        tmux send-keys -t "$pane" Enter; sleep 1
    }

    wait_for_pane "$pane" "bypass permissions" 30 || true
}

# ── [1/7] Prerequisites ───────────────────────────────────────
echo -e "${YELLOW}[1/7] Checking prerequisites...${NC}"

MISSING=()
command -v tmux    &>/dev/null || MISSING+=("tmux")
command -v claude  &>/dev/null || MISSING+=("claude (npm install -g @anthropic-ai/claude-code)")
command -v python3 &>/dev/null || MISSING+=("python3 (required for viewer pane)")

if [ ${#MISSING[@]} -gt 0 ]; then
    echo -e "${RED}Missing dependencies:${NC}"
    for m in "${MISSING[@]}"; do echo "   - $m"; done
    exit 1
fi

echo "  OK tmux $(tmux -V | awk '{print $2}')"
echo "  OK claude $(claude --version 2>/dev/null | head -1)"
echo "  OK python3 $(python3 --version 2>/dev/null | awk '{print $2}')"
echo "  Project root: $PROJECT"
echo "  Session name: $SESSION"

# ── [2/7] orbit plugin detection, update & companion install ─
# Skip entirely if ORBIT_SKIP_PLUGIN_CHECK=1 (offline / already installed).
if [ "${ORBIT_SKIP_PLUGIN_CHECK:-}" != "1" ]; then
    echo ""
    echo -e "${YELLOW}[2/7] Checking orbit plugin...${NC}"

    _ORBIT_BASE_INSTALLED=0

    if claude plugin list 2>/dev/null | grep -qw "orbit"; then
        echo "  OK orbit already installed"
        _ORBIT_BASE_INSTALLED=1
    else
        echo "  orbit not detected — attempting auto-install..."

        # Step 1: ensure orbit marketplace is registered (idempotent)
        if claude plugin marketplace add memoriterx/Orbit --scope "$ORBIT_INSTALL_SCOPE" 2>/dev/null; then
            echo "  OK orbit-marketplace registered"
        else
            echo -e "  ${YELLOW}Warning: could not register orbit-marketplace${NC}"
        fi

        # Step 2: install orbit (idempotent)
        if claude plugin install orbit --scope "$ORBIT_INSTALL_SCOPE" 2>/dev/null; then
            echo -e "  ${GREEN}OK orbit installed${NC}"
            _ORBIT_BASE_INSTALLED=1
            [ "$ORBIT_INSTALL_SCOPE" != "user" ] && \
                echo -e "  ${CYAN}Installed at $ORBIT_INSTALL_SCOPE scope — active only in this project${NC}"
        else
            echo -e "  ${RED}Auto-install failed.${NC}"
            echo "  To activate team features, run inside claude:"
            echo "    /plugin marketplace add memoriterx/Orbit"
            echo "    /plugin install orbit"
        fi

    fi

    # ── Update check ─────────────────────────────────────────────
    # Runs unless ORBIT_SKIP_UPDATE=1.  Failures are non-fatal.
    if [ "${ORBIT_SKIP_UPDATE:-}" != "1" ]; then
        echo ""
        echo -e "${YELLOW}  Checking for updates...${NC}"

        # Pull latest marketplace index (idempotent git fetch under the hood)
        if claude plugin marketplace update orbit-marketplace 2>/dev/null; then
            echo "  OK orbit-marketplace index refreshed"
        else
            echo -e "  ${YELLOW}  Warning: could not refresh orbit-marketplace index (offline?)${NC}"
        fi

        # Update orbit itself (only if installed)
        if [ "$_ORBIT_BASE_INSTALLED" = "1" ]; then
            if claude plugin update orbit --scope "$ORBIT_INSTALL_SCOPE" 2>/dev/null; then
                echo "  OK orbit up-to-date"
            else
                echo -e "  ${YELLOW}  Warning: orbit update check failed (non-fatal)${NC}"
            fi
        fi
    else
        echo "  ORBIT_SKIP_UPDATE=1 — skipping update checks"
    fi

    # ── Companion plugins (opt-in via ORBIT_INSTALL_DEPS=1) ──────
    # superpowers: available in claude-plugins-official marketplace → auto-install/update.
    # gstack, gsd:  skills-dir installs (not in any marketplace) → manual instructions only.
    if [ "${ORBIT_INSTALL_DEPS:-}" = "1" ]; then
        echo ""
        echo -e "${YELLOW}  ORBIT_INSTALL_DEPS=1 — companion plugins...${NC}"

        # superpowers — marketplace-installable (claude-plugins-official)
        if claude plugin list 2>/dev/null | grep -q "superpowers"; then
            echo "  OK superpowers already installed"
            if [ "${ORBIT_SKIP_UPDATE:-}" != "1" ]; then
                if claude plugin update superpowers --scope "$ORBIT_INSTALL_SCOPE" 2>/dev/null; then
                    echo "  OK superpowers up-to-date"
                else
                    echo -e "  ${YELLOW}  Warning: superpowers update check failed (non-fatal)${NC}"
                fi
            fi
        else
            echo "  Installing superpowers from claude-plugins-official..."
            if claude plugin install superpowers@claude-plugins-official --scope "$ORBIT_INSTALL_SCOPE" 2>/dev/null; then
                echo -e "  ${GREEN}OK superpowers installed${NC}"
                [ "$ORBIT_INSTALL_SCOPE" != "user" ] && \
                    echo -e "  ${CYAN}Installed at $ORBIT_INSTALL_SCOPE scope — active only in this project${NC}"
            else
                echo -e "  ${YELLOW}  superpowers auto-install failed. Run inside claude:${NC}"
                echo "      /plugin install superpowers"
            fi
        fi

        # gstack — skills-dir only (no marketplace entry) → manual instructions
        if [ -d "${HOME}/.claude/skills/gstack" ]; then
            echo "  OK gstack already present (~/.claude/skills/gstack)"
        else
            echo -e "  ${YELLOW}  gstack is not in any marketplace — manual install required:${NC}"
            echo "      Clone or copy the gstack skill folder into ~/.claude/skills/gstack/"
            echo "      See: https://github.com/garrytan/gstack (or your team's source)"
        fi

        # gsd — skills-dir only (no marketplace entry) → manual instructions
        if [ -d "${HOME}/.claude/skills/gsd" ]; then
            echo "  OK gsd already present (~/.claude/skills/gsd)"
        else
            echo -e "  ${YELLOW}  gsd is not in any marketplace — manual install required:${NC}"
            echo "      Clone or copy the gsd skill folder into ~/.claude/skills/gsd/"
            echo "      gsd: run /gsd-help in Claude Code for install guidance (or your team's source)"
        fi
    fi
fi

mkdir -p "$ORBIT_DIR"
if [ -s "$NOTIF_LOG" ]; then
    mv "$NOTIF_LOG" "$ORBIT_DIR/notifications.$(date +%Y%m%d-%H%M%S).log"
fi
touch "$NOTIF_LOG"
printf '[%s] ── session start ──\n' "$(date +%H:%M)" >> "$NOTIF_LOG"
echo "  OK notifications.log ready"

# ── [3/7] Kill existing session ───────────────────────────────
echo -e "\n${YELLOW}[3/7] Resetting existing session...${NC}"
tmux has-session -t "$SESSION" 2>/dev/null && {
    tmux kill-session -t "$SESSION"
    echo "  Killed existing '$SESSION' session"
}

# ── [4/7] Create tmux session & layout ───────────────────────
echo -e "\n${YELLOW}[4/7] Creating tmux session & layout...${NC}"

TERM_WIDTH=$(tput cols 2>/dev/null || echo 280)
TERM_HEIGHT=$(tput lines 2>/dev/null || echo 65)
[ "$TERM_WIDTH" -lt 200 ] 2>/dev/null && TERM_WIDTH=280
[ "$TERM_HEIGHT" -lt 50 ] 2>/dev/null && TERM_HEIGHT=65

LEFT_WIDTH=$(( (TERM_WIDTH - 1) / 2 ))
RIGHT_WIDTH=$(( TERM_WIDTH - LEFT_WIDTH - 1 ))
if [ "$RIGHT_WIDTH" -lt 120 ]; then
    echo -e "  ${YELLOW}Warning: terminal is narrow (${TERM_WIDTH} cols). Right pane is ${RIGHT_WIDTH} cols.${NC}"
fi

# Create session (pane 0)
tmux new-session -d -s "$SESSION" -x "$TERM_WIDTH" -y "$TERM_HEIGHT"

# Split horizontally: pane 0 (lead, left) / pane 1 (viewer, right)
tmux split-window -t "$SESSION:0.0" -h

# Pane border display
tmux set-option -t "$SESSION" pane-border-status top
tmux set-option -t "$SESSION" pane-border-format " #{pane_title} "
tmux set-option -t "$SESSION" allow-rename off

# Adjust left pane width
tmux resize-pane -t "$SESSION:0.0" -x "$LEFT_WIDTH"

# Pane titles
tmux select-pane -t "$SESSION:0.0" -T "Lead"
tmux select-pane -t "$SESSION:0.1" -T "Subagent Viewer"

echo "  OK Layout ready (2 panes)"

# ── [5/7] Start processes ─────────────────────────────────────
echo -e "\n${YELLOW}[5/7] Starting processes...${NC}"

# Pane 1 (viewer): standby message
tmux send-keys -t "$SESSION:0.1" \
    "clear; printf '\033[1;35m━━ Viewer (standby) ━━\033[0m\nSubagent transcripts will appear here automatically.\nThe SubagentStart hook (viewer-attach.sh) handles auto-connection.\n'" Enter
echo "  OK Pane 1 (viewer): standby mode"

# Pane 0 (lead): real Claude CLI
echo -n "  Pane 0 (lead): "
start_claude_in_pane "$SESSION:0.0"
tmux capture-pane -t "$SESSION:0.0" -p 2>/dev/null | grep -qi "bypass permissions" \
    && echo -e "${GREEN}OK Ready${NC}" \
    || echo -e "${RED}Warning: timed out — check pane manually${NC}"

# ── [6/7] Usage notes ─────────────────────────────────────────
echo -e "\n${YELLOW}[6/7] Operating model: hub-and-spoke + live viewer${NC}"
echo "  · All work is delegated from the lead (pane 0) via Agent()."
echo "  · Live view: SubagentStart hook (viewer-attach.sh) auto-connects to pane 1."
echo "  · Previous agent output is preserved and separated by a divider line."
echo "  · Notification log: $NOTIF_LOG"

# ── [7/7] Done ────────────────────────────────────────────────
echo -e "\n${GREEN}"
echo "  ╔══════════════════════════════════════════════╗"
echo "  ║   Team environment ready! (2 panes)          ║"
echo "  ║                                              ║"
echo "  ║  [0] Lead              [1] Viewer            ║"
echo "  ╚══════════════════════════════════════════════╝"
echo -e "${NC}"

# Focus always starts on the lead (pane 0)
tmux select-pane -t "$SESSION:0.0"

# Attach (or switch) to the session.
# When running inside an existing tmux client, use switch-client so the current
# window is replaced by the orbit session rather than triggering
# "open terminal failed: not a terminal".
if [ -t 1 ]; then
    if [ -n "${TMUX:-}" ]; then
        tmux switch-client -t "$SESSION"
    else
        tmux attach -t "$SESSION"
    fi
fi
