#!/bin/bash
# SubagentStart 훅 — L1 고려 제공 레이어 (consideration-delivery, v2.1.0)
#
# ADR-REQDEPS-4: SubagentStart 시 역할별 현재 설치·활성화된 스킬 목록 + 고려 지시를
# hookSpecificOutput.additionalContext로 주입한다.
#
# ★ 이 훅은 절대 차단(block)하지 않는다 ★
#   - SubagentStart는 구조적으로 차단 불가
#   - L1은 고려 프롬프트 "전달"만 보장; 에이전트의 실제 사용은 에이전트 판단
#   - 에이전트 준수(compliance)는 검증 불가이며 의도적으로 테스트하지 않는다
#   - skip은 명시적으로 허용된다 ("단순/메타 작업은 생명주기 불필요")
#
# L1은 "consideration delivery"이며 "required/enforced"가 아니다 (BLOCKER #2 트랩 반복 금지).
# 동반 플러그인 미설치 시 해당 스킬은 주입하지 않음 (팬텀 스킬 참조 방지).
#
# ★ ROLE_SKILL_MAP 단일 정전 (source of truth) ★
#   아래 get_sp_skills/get_gsd_skills/get_gs_skills case문이 역할↔스킬 공식 매핑의 정전이다.
#   파생본은 두 곳에 있으며, 정전과 일치해야 한다:
#     1) templates/orbit-config.template — 주석 처리된 기본값 예시 (파생본)
#     2) 각 에이전트 프롬프트의 "Companion Skill Wiring" 표 (파생본, 인간 독해용)
#   정전과 파생본의 일치는 tests/test-static.sh T-MAP drift 가드로 자동 검증된다.
#
# 역할→스킬 맵: .orbit/config의 ROLE_SKILL_MAP_<ROLE> 변수에서 읽음 (런타임 오버라이드).
# 미설정 시 아래 case문 기본값 사용 (orbit 공식 배선).
#
# 주의: declare -A (bash4 associative array) 대신 case문 사용 — macOS /bin/bash는 3.x.

set -uo pipefail

# ---- stdin에서 SubagentStart 페이로드 읽기 ----
stdin_payload=""
if [ ! -t 0 ]; then
    stdin_payload=$(cat 2>/dev/null || true)
fi

# agent_type 추출
agent_type=""
if command -v python3 >/dev/null 2>&1; then
    agent_type=$(printf '%s' "$stdin_payload" | python3 -c "
import sys, json
try:
    d = json.load(sys.stdin)
    print(d.get('agent_type', ''))
except Exception:
    print('')
" 2>/dev/null || true)
elif command -v jq >/dev/null 2>&1; then
    agent_type=$(printf '%s' "$stdin_payload" | jq -r '.agent_type // ""' 2>/dev/null || true)
fi

# agent_type이 없거나 인식 불가 → 빈 additionalContext로 조용히 종료
if [ -z "$agent_type" ]; then
    exit 0
fi

# ---- 동반 플러그인 활성 상태 확인 ----
# claude CLI 없으면 빈 주입으로 graceful 종료
SUPERPOWERS_ENABLED=0
GSTACK_ENABLED=0
GSD_ENABLED=0

if command -v claude >/dev/null 2>&1; then
    plugin_json=$(claude plugin list --json 2>/dev/null || echo "[]")
    if command -v python3 >/dev/null 2>&1; then
        # stdin 전달로 쉘 보간 우회 (하드닝: -c 방식, pipe stdin으로 JSON 전달)
        local_py='import json,sys; pl=json.load(sys.stdin); sp=1 if any(p.get("name")=="superpowers" and p.get("enabled",False) for p in pl) else 0; gs=1 if any(p.get("name")=="gstack" and p.get("enabled",False) for p in pl) else 0; gsd=1 if any(p.get("name")=="gsd" and p.get("enabled",False) for p in pl) else 0; print(sp,gs,gsd)'
        read -r SUPERPOWERS_ENABLED GSTACK_ENABLED GSD_ENABLED <<< "$(printf '%s' "$plugin_json" | python3 -c "$local_py" 2>/dev/null || echo "0 0 0")"
    fi
fi

# ---- .orbit/config에서 역할별 스킬 맵 로드 ----
# 단일 정전: {{ROLE_SKILL_MAP}} = .orbit/config의 ROLE_SKILL_MAP_<ROLE> 변수
CONFIG_FILE="${CLAUDE_PROJECT_DIR:-.}/.orbit/config"
if [ -f "$CONFIG_FILE" ]; then
    # shellcheck source=/dev/null
    source "$CONFIG_FILE" 2>/dev/null || true
fi

# ---- 역할별 동반 플러그인 스킬 기본값 (case문 — bash 3.x 호환) ----
# [ROLE_SKILL_MAP 정전] orbit 공식 배선 — 이 case문이 변경의 단일 진입점이다.
# 형식: "skill[level],skill[level],..." where [A]=always, [C]=conditional

get_sp_skills() {
    # superpowers 스킬 (설치된 경우에만 주입)
    case "$1" in
        leader)    echo "superpowers:using-superpowers[A],superpowers:dispatching-parallel-agents[C]" ;;
        architect) echo "superpowers:brainstorming[A],superpowers:writing-plans[A]" ;;
        builder)   echo "superpowers:test-driven-development[A],superpowers:verification-before-completion[A],superpowers:systematic-debugging[C],superpowers:executing-plans[C],superpowers:using-git-worktrees[C],superpowers:finishing-a-development-branch[C]" ;;
        critic)    echo "superpowers:receiving-code-review[A]" ;;
        reviewer)  echo "superpowers:requesting-code-review[A],superpowers:receiving-code-review[C]" ;;
        *)         echo "" ;;
    esac
}

get_gsd_skills() {
    # GSD 스킬 (설치된 경우에만 주입)
    case "$1" in
        architect) echo "/gsd-explore[C],/gsd-plan-phase[C]" ;;
        builder)   echo "/gsd-debug[C]" ;;
        explore)   echo "/gsd-map-codebase[C],/gsd-explore[C]" ;;
        critic)    echo "/gsd-secure-phase[C]" ;;
        reviewer)  echo "/gsd-verify-work[A],/gsd-progress[C],/gsd-code-review[C],/gsd-secure-phase[C]" ;;
        *)         echo "" ;;
    esac
}

get_gs_skills() {
    # gstack 스킬 (설치된 경우에만 주입)
    case "$1" in
        critic)    echo "cso[C]" ;;
        reviewer)  echo "/qa[A],/qa-only[C],/review[C],cso[C]" ;;
        researcher) echo "scrape[C],browse[C]" ;;
        *)         echo "" ;;
    esac
}

# ---- 역할별 설치된 스킬 조합 ----
role="$agent_type"

# .orbit/config 오버라이드 확인 (ROLE_SKILL_MAP_<ROLE> 변수)
config_var_name="ROLE_SKILL_MAP_${role}"
config_skills="${!config_var_name:-}"

available_skills=""

if [ -n "$config_skills" ]; then
    # .orbit/config에 설정된 경우: 해당 값 그대로 사용 (사용자 책임)
    available_skills="$config_skills"
else
    # 기본 맵: 설치된 동반 플러그인 스킬만 조합
    parts=()

    sp_part=$(get_sp_skills "$role")
    gsd_part=$(get_gsd_skills "$role")
    gs_part=$(get_gs_skills "$role")

    if [ "$SUPERPOWERS_ENABLED" = "1" ] && [ -n "$sp_part" ]; then
        parts+=("$sp_part")
    fi
    if [ "$GSD_ENABLED" = "1" ] && [ -n "$gsd_part" ]; then
        parts+=("$gsd_part")
    fi
    if [ "$GSTACK_ENABLED" = "1" ] && [ -n "$gs_part" ]; then
        parts+=("$gs_part")
    fi

    # 조합 (bash 배열 → 쉼표 구분 문자열)
    if [ ${#parts[@]} -gt 0 ]; then
        available_skills=$(IFS=,; echo "${parts[*]}")
    fi
fi

# ---- additionalContext 생성 ----
if [ -z "$available_skills" ]; then
    # 스킬 없음 → 최소 주의사항만 출력 (팬텀 스킬 참조 안 함)
    additional_ctx="[orbit L1] You are acting as ${role}. No companion skills are currently available for this role (companions not installed or not applicable). Proceed with your native methodology."
else
    additional_ctx="[orbit L1 — consideration delivery] You are acting as ${role}.

Available companion skills for this role: ${available_skills}

Before starting your work, consider whether any of these skills apply to THIS specific task.
- If a skill fits the task: use it.
- If the task is simple, meta, or the skill adds no value: SKIP the skill — do not force it.
  (\"단순/메타 작업은 생명주기 불필요\" — skipping is explicitly permitted.)

This is a consideration prompt, not a requirement. Whether you use a skill is your judgment."
fi

# ---- JSON 출력 ----
# SubagentStart 전용: hookEventName = SubagentStart
# 절대 "decision":"block"을 출력하지 않는다 — L1은 구조적으로 차단 불가
if command -v python3 >/dev/null 2>&1; then
    python3 -c "
import json, sys
output = {
    'hookSpecificOutput': {
        'hookEventName': 'SubagentStart',
        'additionalContext': sys.argv[1]
    }
}
print(json.dumps(output))
" "$additional_ctx" 2>/dev/null || true
elif command -v jq >/dev/null 2>&1; then
    jq -n \
        --arg ctx "$additional_ctx" \
        '{"hookSpecificOutput":{"hookEventName":"SubagentStart","additionalContext":$ctx}}'
else
    # fallback: manual JSON 구성
    escaped=$(printf '%s' "$additional_ctx" | python3 -c "import sys,json; print(json.dumps(sys.stdin.read()))" 2>/dev/null || printf '"%s"' "$additional_ctx")
    printf '{"hookSpecificOutput":{"hookEventName":"SubagentStart","additionalContext":%s}}' "$escaped"
fi

exit 0
