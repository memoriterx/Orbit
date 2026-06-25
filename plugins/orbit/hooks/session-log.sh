#!/bin/bash
# Stop 훅용 — 세션 종료 시각을 .orbit/session-log.md 에 append.
# 비-orbit 프로젝트에서는 no-op (orbit-context.sh 가드).
source "${CLAUDE_PLUGIN_ROOT}/scripts/orbit-context.sh" 2>/dev/null || exit 0
is_orbit_context || exit 0

ORBIT_DIR="${CLAUDE_PROJECT_DIR:-$(pwd)}/.orbit"
mkdir -p "$ORBIT_DIR"
sid=$(cat 2>/dev/null | jq -r '.session_id // "?"' 2>/dev/null || echo "?")
printf '[%s] session stopped (sid=%s)\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$sid" \
  >> "$ORBIT_DIR/session-log.md" 2>/dev/null || true
