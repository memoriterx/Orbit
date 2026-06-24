#!/bin/bash
# SubagentStop 훅 — 품질 게이트 + Triple Crown 동반 플러그인 체크 (TIER-1, v2.0.0)
#
# 동작:
#   1. 관련성 게이트: 완료된 작업이 reviewer의 Triple Crown 프롱인지 판단 (N1: agent_type 필드 우선).
#      관련 없으면 → exit 0 (빌드/탐색/메타 작업은 차단하지 않는다 — BLOCKER #1 픽스).
#   2. 프롱 관련 완료인 경우: 해당 프롱에 필요한 동반 플러그인만 확인.
#      동반 플러그인 미설치 or 비활성 → {"decision":"block", ...} (TIER-1 강제).
#   3. claude CLI 없는 환경(CI/서브에이전트 PATH 미포함): 프롱 관련이어도 non-blocking 경고 출력 후
#      reviewer 보고 계약(D3, 두 번째 독립 게이트)에 위임. 자살 게이트 방지.
#   4. ORBIT_SKIP_COMPANION_CHECK=1: 프롱 체크 건너뜀 (CI/헤드리스 탈출구, ADR-REQDEPS-2).
#   5. 기존 프로젝트 .orbit/quality-gate.sh 위임은 별도 독립 실행 (동반 플러그인 체크와 무관).
#
# ADR-REQDEPS-2: "required"는 오직 검증 프롱에서만 (scoped). 다른 작업은 차단하지 않는다.
# D8 (intentional asymmetry note): dev팀 SubagentStop은 .claude/settings.json 인라인 훅으로
#   별도 운용되며 이 스크립트를 거치지 않는다. dev팀은 항상 동반 플러그인이 설치된
#   dogfood 환경이므로 의도된 비대칭이다 (drift 아님).

set -euo pipefail

# ---- 1. 기존 프로젝트 품질 게이트 위임 (동반 플러그인 체크와 독립 실행) ----
GATE="${CLAUDE_PROJECT_DIR:-.}/.orbit/quality-gate.sh"
if [ -f "$GATE" ] && [ -x "$GATE" ]; then
    project_output=$("$GATE" 2>&1) || {
        printf '{"decision":"block","reason":%s}' \
            "$(printf 'project quality-gate 실패\n%s' "$project_output" | jq -Rs .)"
        exit 0
    }
fi

# ---- 2. 관련성 게이트: reviewer 프롱인지 판단 ----
# SubagentStop 페이로드를 stdin에서 읽는다.
# N1: agent_type 필드를 1급 신호로 사용. 센티넬/트랜스크립트 파싱 폴백 금지.
stdin_payload=""
if [ -t 0 ]; then
    # stdin이 터미널이면 페이로드 없음 → 무관 작업으로 간주 → pass
    exit 0
fi
stdin_payload=$(cat 2>/dev/null || true)

# agent_type 추출 (jq 없으면 python3 fallback)
agent_type=""
if command -v jq >/dev/null 2>&1; then
    agent_type=$(printf '%s' "$stdin_payload" | jq -r '.agent_type // ""' 2>/dev/null || true)
elif command -v python3 >/dev/null 2>&1; then
    agent_type=$(printf '%s' "$stdin_payload" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('agent_type',''))" 2>/dev/null || true)
fi

# reviewer가 아니면 → pass (빌드/탐색/architect/meta 작업 모두 통과)
if [ "$agent_type" != "reviewer" ]; then
    exit 0
fi

# ---- 3. 탈출구: ORBIT_SKIP_COMPANION_CHECK=1 ----
if [ "${ORBIT_SKIP_COMPANION_CHECK:-0}" = "1" ]; then
    printf '[orbit] Triple Crown 동반 플러그인 체크 건너뜀 (ORBIT_SKIP_COMPANION_CHECK=1)\n' >&2
    exit 0
fi

# ---- 4. claude CLI 가용성 확인 ----
if ! command -v claude >/dev/null 2>&1; then
    # claude CLI 없음 → non-blocking 경고 후 reviewer 보고 계약(D3)에 위임
    printf '[orbit] 경고: claude CLI를 찾을 수 없어 동반 플러그인 체크를 건너뜁니다.\n' >&2
    printf '        Triple Crown 프롱 강제는 reviewer 보고 계약(D3)에서 이중으로 수행됩니다.\n' >&2
    printf '        설치 후 재시도하거나 ORBIT_SKIP_COMPANION_CHECK=1로 억제하세요.\n' >&2
    exit 0
fi

# ---- 5. 동반 플러그인 목록 가져오기 (정확한 이름 + enabled 상태 파싱) ----
# T-B2: 서브스트링 충돌(gstack-helper vs gstack) 방지 — JSON 파싱으로 정확한 이름+enabled 확인.
plugin_json=""
if plugin_json=$(claude plugin list --json 2>/dev/null); then
    : # JSON 파싱 경로
else
    # JSON 플래그 미지원 구 버전 fallback → 텍스트 파싱 (부정확할 수 있음, 경고 후 계속)
    printf '[orbit] 경고: claude plugin list --json 실패. 동반 플러그인 체크를 건너뜁니다.\n' >&2
    exit 0
fi

# 활성화된(enabled=true) 플러그인 이름 목록 추출
# 형식: [{"name":"superpowers","enabled":true}, ...]
is_enabled() {
    local plugin_name="$1"
    if command -v python3 >/dev/null 2>&1; then
        python3 -c "
import json, sys
data = json.loads('''$plugin_json''')
for p in data:
    if p.get('name') == '$plugin_name' and p.get('enabled', False):
        sys.exit(0)
sys.exit(1)
" 2>/dev/null
    elif command -v jq >/dev/null 2>&1; then
        echo "$plugin_json" | jq -e ".[] | select(.name == \"$plugin_name\" and .enabled == true)" >/dev/null 2>&1
    else
        # 최후 수단: 텍스트 grep (정확도 낮음)
        echo "$plugin_json" | grep -q "\"$plugin_name\""
    fi
}

# ---- 6. 세 개 동반 플러그인 전부 확인 ----
# reviewer는 ①②③ 모두 담당하므로 세 개 모두 필요.
# 플랜 D2에서 "prong별 해당 플러그인만" 명시했지만, reviewer 완료 시점엔
# 세 프롱 모두 완료됐어야 하므로 세 개 전부 확인.
MISSING_PLUGINS=()

if ! is_enabled "gsd"; then
    MISSING_PLUGINS+=("gsd (Triple Crown ① 완성도 프롱 필수 — '/plugin install gsd' 또는 '/gsd-help'로 설치)")
fi

if ! is_enabled "gstack"; then
    MISSING_PLUGINS+=("gstack (Triple Crown ② 동작 프롱 필수 — 설치: git clone --single-branch --depth 1 https://github.com/garrytan/gstack.git ~/.claude/skills/gstack && cd ~/.claude/skills/gstack && ./setup)")
fi

if ! is_enabled "superpowers"; then
    MISSING_PLUGINS+=("superpowers (Triple Crown ③ 품질 프롱 필수 — '/plugin install superpowers@claude-plugins-official'으로 설치)")
fi

if [ ${#MISSING_PLUGINS[@]} -gt 0 ]; then
    missing_list=""
    for p in "${MISSING_PLUGINS[@]}"; do
        missing_list+="${p}\n"
    done
    reason=$(printf 'Triple Crown 동반 플러그인 미설치/비활성:\n%s\n모든 플러그인을 설치하고 활성화한 뒤 다시 시도하세요.\nCI/헤드리스 환경에서 건너뛰려면: ORBIT_SKIP_COMPANION_CHECK=1' "$missing_list" | jq -Rs .)
    printf '{"decision":"block","reason":%s}' "$reason"
fi

exit 0
