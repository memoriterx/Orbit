#!/bin/bash
# Static checks: T-D (JSON validity), T-E (no hedge survivors),
# T-E honesty (no "domain-agnostic" / "any stack"), T-G (no over-guard),
# T-G CHANGELOG honesty, project purity grep.
#
# Usage: bash tests/test-static.sh

ORBIT="/Users/dh/Project/orbit/plugins/orbit"
ROOT="/Users/dh/Project/orbit"
PASS=0
FAIL=0

echo "=== Static checks ==="
echo ""

# ---- T-D: JSON validity ----
echo "--- T-D: JSON validity ---"

for f in \
    "$ORBIT/.claude-plugin/plugin.json" \
    "$ROOT/.claude-plugin/marketplace.json" \
    "$ORBIT/.codex-plugin/plugin.json" \
    "$ORBIT/hooks/hooks.json"; do
    if python3 -m json.tool "$f" > /dev/null 2>&1; then
        echo "  PASS  T-D JSON valid: $(basename $(dirname $f))/$(basename $f)"
        PASS=$((PASS+1))
    else
        echo "  FAIL  T-D JSON invalid: $f"
        FAIL=$((FAIL+1))
    fi
done

echo ""

# ---- T-D: bash -n for all shell scripts ----
echo "--- T-D: bash -n syntax ---"
for f in \
    "$ORBIT/hooks/quality-gate.sh" \
    "$ORBIT/hooks/viewer-attach.sh" \
    "$ORBIT/hooks/notify-done.sh" \
    "$ORBIT/hooks/session-log.sh" \
    "$ORBIT/hooks/skill-consideration.sh" \
    "$ORBIT/templates/quality-gate.template.sh" \
    "$ORBIT/scripts/setup-orbit.sh" \
    "$ORBIT/scripts/attach-view.sh" \
    "$ORBIT/scripts/notify.sh"; do
    if [ ! -f "$f" ]; then
        echo "  SKIP  T-D not found: $(basename $f)"
        continue
    fi
    if bash -n "$f" 2>&1; then
        echo "  PASS  T-D syntax: $(basename $f)"
        PASS=$((PASS+1))
    else
        echo "  FAIL  T-D syntax error: $f"
        FAIL=$((FAIL+1))
    fi
done

echo ""

# ---- T-E: No graceful-hedge survivors in reviewer, orbit-cycle, orbit-init ----
echo "--- T-E: No graceful-hedge survivors for three companions ---"

# "tool not available" soft-pass phrase in reviewer.md
for f in \
    "$ORBIT/agents/reviewer.md" \
    "$ROOT/.claude/agents/reviewer.md"; do
    if grep -qi "unverified — tool not available" "$f" 2>/dev/null; then
        echo "  FAIL  T-E hedge survives in $(basename $(dirname $f))/reviewer.md: 'unverified — tool not available'"
        FAIL=$((FAIL+1))
    else
        echo "  PASS  T-E no soft-pass hedge in $(basename $(dirname $f))/reviewer.md"
        PASS=$((PASS+1))
    fi
done

# orbit-cycle.md: "없어도 orbit은 동작" or the old graceful table
if grep -q "플러그인 없이도 생명주기는 완전히 실행 가능하다" "$ORBIT/commands/orbit-cycle.md" 2>/dev/null; then
    echo "  FAIL  T-E old graceful-pass line survives in orbit-cycle.md"
    FAIL=$((FAIL+1))
else
    echo "  PASS  T-E orbit-cycle.md: old graceful-pass removed"
    PASS=$((PASS+1))
fi

# orbit-init.md: "없어도 orbit은 동작" in Step 6 area
if grep -q "없어도 orbit은 동작" "$ORBIT/commands/orbit-init.md" 2>/dev/null; then
    echo "  FAIL  T-E old soft-dependency language survives in orbit-init.md Step 6"
    FAIL=$((FAIL+1))
else
    echo "  PASS  T-E orbit-init.md Step 6: soft-dependency language removed"
    PASS=$((PASS+1))
fi

echo ""

# ---- T-E honesty: manifest + README no longer claim "any stack / domain-agnostic / optional" ----
echo "--- T-E honesty: no 'domain-agnostic/any-stack/optional' in manifest+README ---"

PLUGIN_JSON="$ORBIT/.claude-plugin/plugin.json"
MARKETPLACE_JSON="$ROOT/.claude-plugin/marketplace.json"
README="$ROOT/README.md"

for f in "$PLUGIN_JSON" "$MARKETPLACE_JSON"; do
    if grep -qi "어떤 기술 스택에도 적용 가능\|도메인 무관\|domain-agnostic\|applies to any stack" "$f" 2>/dev/null; then
        echo "  FAIL  T-E honesty: old 'any-stack/domain-agnostic' copy survives in $(basename $f)"
        FAIL=$((FAIL+1))
    else
        echo "  PASS  T-E honesty: $(basename $f) no false domain-agnostic claim"
        PASS=$((PASS+1))
    fi
done

# README: should mention that companions are required (for verification)
if grep -qiE "required|필수|Prerequisites|Requirements" "$README" 2>/dev/null; then
    echo "  PASS  T-E README mentions required/prerequisites"
    PASS=$((PASS+1))
else
    echo "  FAIL  T-E README missing required companions section"
    FAIL=$((FAIL+1))
fi

echo ""

# ---- T-E project purity (narrowly labeled) ----
echo "--- T-E project purity (no dogfood leakage — 'oremi|orbit-dev' in plugins/orbit/) ---"

found=$(grep -rE 'oremi|Oremi|orbit-dev' "$ORBIT/" 2>/dev/null | grep -v Binary | wc -l | tr -d ' ')
if [ "$found" -eq 0 ]; then
    echo "  PASS  T-E project purity: 0 dogfood references (oremi/orbit-dev)"
    PASS=$((PASS+1))
else
    echo "  FAIL  T-E project purity: $found references found"
    grep -rE 'oremi|Oremi|orbit-dev' "$ORBIT/" 2>/dev/null | grep -v Binary | head -5
    FAIL=$((FAIL+1))
fi

echo ""

# ---- T-G: No over-guard — D4 wiring must not carry block/fail-loud language ----
echo "--- T-G: No over-guard — non-reviewer agent files must not have block/fail-loud for skills ---"

AGENT_DIR="$ORBIT/agents"
DEV_AGENT_DIR="$ROOT/.claude/agents"

# reviewer.md is the ONLY allowed one to say block/fail for prong tools
# Check all OTHER agents do not have block/fail-loud HOOK-STYLE decision language
# Pattern: {"decision":"block"} style or "fail-loud" adjacent to a companion skill name
# We use a precise pattern: the JSON decision:block pattern, or "fail-loud" near companion names.
# We do NOT flag "blocker" (plan severity), "blocked (4xx)" (HTTP), "when blocked" (debugging).
for agent in architect builder leader explore critic researcher; do
    for dir in "$AGENT_DIR" "$DEV_AGENT_DIR"; do
        f="$dir/$agent.md"
        if [ ! -f "$f" ]; then continue; fi
        # Only flag the hook-style block pattern or "fail-loud" phrasing near skill names
        if grep -qE '"decision"\s*:\s*"block"|fail-loud' "$f" 2>/dev/null; then
            echo "  FAIL  T-G over-guard: $agent.md ($(basename $dir)) contains hook block/fail-loud language"
            grep -nE '"decision"\s*:\s*"block"|fail-loud' "$f" | head -3
            FAIL=$((FAIL+1))
        else
            echo "  PASS  T-G no over-guard: $agent.md ($(basename $dir))"
            PASS=$((PASS+1))
        fi
    done
done

echo ""

# ---- T-G CHANGELOG honesty: v2.1.0 must not use "required/enforced" for TIER-2 prose ----
echo "--- T-G CHANGELOG honesty: v2.1.0 entry must not call TIER-2 required/enforced ---"

CHANGELOG="$ROOT/CHANGELOG.md"
if [ -f "$CHANGELOG" ]; then
    # Extract the v2.1.0 section (between ## [2.1.0] and the next ## [)
    v21_section=$(awk '/^\#\# \[2\.1\.0\]/,/^\#\# \[/' "$CHANGELOG" | grep -v "^## \[" | head -50)
    if echo "$v21_section" | grep -qiE '\b(required|enforced|mandatory)\b'; then
        echo "  FAIL  T-G CHANGELOG v2.1.0 uses required/enforced for TIER-2"
        echo "$v21_section" | grep -iE '\b(required|enforced|mandatory)\b' | head -3
        FAIL=$((FAIL+1))
    else
        echo "  PASS  T-G CHANGELOG v2.1.0 correctly labels TIER-2 as guidance"
        PASS=$((PASS+1))
    fi
else
    echo "  SKIP  T-G CHANGELOG not found"
fi

echo ""

# ---- T-G coverage: all 7 deploy agents have Companion skill wiring section ----
echo "--- T-G coverage: all 7 deploy agents have Companion skill wiring section ---"

for agent in architect builder leader explore critic reviewer researcher; do
    f="$AGENT_DIR/$agent.md"
    if [ ! -f "$f" ]; then
        echo "  FAIL  T-G missing agent file: $f"
        FAIL=$((FAIL+1))
        continue
    fi
    if grep -qi "Companion skill wiring\|companion.*wiring\|wiring.*companion" "$f" 2>/dev/null; then
        echo "  PASS  T-G companion wiring section: $agent.md"
        PASS=$((PASS+1))
    else
        echo "  FAIL  T-G missing companion wiring section: $agent.md"
        FAIL=$((FAIL+1))
    fi
done

echo ""

# ---- T-F: parity check — dev agents have wiring too ----
echo "--- T-F: parity — dev agents also have companion wiring sections ---"

for agent in architect builder leader explore critic reviewer researcher; do
    f="$DEV_AGENT_DIR/$agent.md"
    if [ ! -f "$f" ]; then
        echo "  FAIL  T-F missing dev agent file: $f"
        FAIL=$((FAIL+1))
        continue
    fi
    # Match English or Korean heading variants
    if grep -qi "Companion skill wiring\|companion.*wiring\|wiring.*companion\|동반 스킬 배선\|동반.*배선\|배선.*동반" "$f" 2>/dev/null; then
        echo "  PASS  T-F companion wiring section: .claude/$agent.md"
        PASS=$((PASS+1))
    else
        echo "  FAIL  T-F missing companion wiring in dev: .claude/$agent.md"
        FAIL=$((FAIL+1))
    fi
done

echo ""

# ---- T-F: D8 hook-parity asymmetry documented ----
echo "--- T-F: D8 hook-parity asymmetry is documented ---"

# Check that some file mentions the intentional asymmetry
found_d8=0
for f in "$ROOT/.claude/agents/leader.md" "$ROOT/.claude/agents/reviewer.md" "$ROOT/plugins/orbit/hooks/quality-gate.sh"; do
    if grep -qi "asymmetr\|intentional\|dev.*hook\|hook.*dev" "$f" 2>/dev/null; then
        found_d8=1
        break
    fi
done

if [ "$found_d8" -eq 1 ]; then
    echo "  PASS  T-F D8 asymmetry documented somewhere"
    PASS=$((PASS+1))
else
    echo "  FAIL  T-F D8 hook-parity asymmetry not documented"
    FAIL=$((FAIL+1))
fi

echo ""

# ---- manifest version checks ----
echo "--- Version: plugin.json and marketplace.json at 2.0.0 (minimum) ---"

plugin_ver=$(python3 -c "import json; d=json.load(open('$PLUGIN_JSON')); print(d.get('version',''))" 2>/dev/null)
market_ver=$(python3 -c "import json; d=json.load(open('$MARKETPLACE_JSON')); p=d.get('plugins',[]); print(p[0].get('version','') if p else '')" 2>/dev/null)

if echo "$plugin_ver" | grep -qE '^2\.[0-9]+\.[0-9]+'; then
    echo "  PASS  plugin.json version: $plugin_ver"
    PASS=$((PASS+1))
else
    echo "  FAIL  plugin.json version should be 2.x.x, got: $plugin_ver"
    FAIL=$((FAIL+1))
fi

if echo "$market_ver" | grep -qE '^2\.[0-9]+\.[0-9]+'; then
    echo "  PASS  marketplace.json version: $market_ver"
    PASS=$((PASS+1))
else
    echo "  FAIL  marketplace.json version should be 2.x.x, got: $market_ver"
    FAIL=$((FAIL+1))
fi

# No dependencies array in plugin.json
if python3 -c "import json; d=json.load(open('$PLUGIN_JSON')); assert 'dependencies' not in d, 'dependencies field found'" 2>/dev/null; then
    echo "  PASS  plugin.json has no dependencies array (ADR-REQDEPS-1)"
    PASS=$((PASS+1))
else
    echo "  FAIL  plugin.json must NOT have a dependencies array"
    FAIL=$((FAIL+1))
fi

echo ""

# ---- T-MAP: ROLE_SKILL_MAP drift guard ----
# source of truth: skill-consideration.sh case statements
# derived: agent wiring tables (L2 prose)
# cross-source diff: skills in canonical must all appear in L2 table for that role
echo "--- T-MAP: ROLE_SKILL_MAP drift guard (canonical case stmt vs L2 agent tables) ---"

map_drift_result=$(python3 - << 'PYEOF'
import re, os, sys

hook_file = "/Users/dh/Project/orbit/plugins/orbit/hooks/skill-consideration.sh"
agent_dir = "/Users/dh/Project/orbit/plugins/orbit/agents"
roles = ['leader', 'architect', 'builder', 'explore', 'critic', 'reviewer', 'researcher']

def parse_case_block(func_name, text):
    """Extract role->skills from a case statement function body."""
    pattern = rf'{re.escape(func_name)}\(\)\s*\{{(.*?)^}}'
    m = re.search(pattern, text, re.MULTILINE | re.DOTALL)
    if not m:
        return {}
    block = m.group(1)
    role_skills = {}
    for role_match in re.finditer(r'(\w+)\)\s+echo\s+"([^"]+)"', block):
        role = role_match.group(1)
        if role == '*':
            continue
        skills_str = role_match.group(2)
        skills = [re.sub(r'\[.*?\]', '', s).strip() for s in skills_str.split(',')]
        role_skills[role] = [s for s in skills if s]
    return role_skills

with open(hook_file) as f:
    hook_content = f.read()

sp = parse_case_block('get_sp_skills', hook_content)
gsd = parse_case_block('get_gsd_skills', hook_content)
gs = parse_case_block('get_gs_skills', hook_content)

# Combine all skills per role (canonical)
canonical = {}
for role in set(list(sp.keys()) + list(gsd.keys()) + list(gs.keys())):
    skills = []
    if role in sp: skills.extend(sp[role])
    if role in gsd: skills.extend(gsd[role])
    if role in gs: skills.extend(gs[role])
    canonical[role] = sorted(set(skills))

def extract_l2_skills(filepath):
    """Extract all backtick skill names from Companion Skill Wiring section."""
    with open(filepath) as f:
        content = f.read()
    m = re.search(r'## Companion Skill Wiring.*?(?=^## |\Z)', content, re.MULTILINE | re.DOTALL)
    if not m:
        return []
    section = m.group(0)
    # Extract all backtick contents
    all_bt = re.findall(r'`([^`]+)`', section)
    # Filter: skill names contain ':', '/', or are short names like 'cso', 'scrape', 'browse'
    # Exclude level annotations like [A-directive], [C], etc.
    skills = []
    for s in all_bt:
        s = s.strip()
        if s.startswith('[') or s in ('[A-directive]', '[C]', 'A', 'C'):
            continue
        # Must look like a skill: has ':', '/', or is a known short name
        if ':' in s or s.startswith('/') or re.match(r'^[a-z][a-z0-9_-]+$', s):
            # Normalize: strip level annotations from end
            s_clean = re.sub(r'\s*\[.*', '', s).strip()
            if s_clean:
                skills.append(s_clean)
    return sorted(set(skills))

errors = []
for role in sorted(canonical.keys()):
    agent_file = os.path.join(agent_dir, f"{role}.md")
    if not os.path.exists(agent_file):
        errors.append(f"MISSING_FILE:{role}:{agent_file}")
        continue
    l2_skills = set(extract_l2_skills(agent_file))
    canonical_set = set(canonical[role])
    missing = canonical_set - l2_skills
    if missing:
        errors.append(f"DRIFT:{role}:in canonical but missing from L2:{sorted(missing)}")

if errors:
    for e in errors:
        print(f"FAIL:{e}")
    sys.exit(1)
else:
    for role in sorted(canonical.keys()):
        print(f"PASS:{role}")
    sys.exit(0)
PYEOF
)
map_drift_exit=$?

while IFS= read -r line; do
    if [[ "$line" == PASS:* ]]; then
        role="${line#PASS:}"
        echo "  PASS  T-MAP no drift: $role"
        PASS=$((PASS+1))
    elif [[ "$line" == FAIL:* ]]; then
        echo "  FAIL  T-MAP $line"
        FAIL=$((FAIL+1))
    fi
done <<< "$map_drift_result"

if [ $map_drift_exit -ne 0 ] && ! echo "$map_drift_result" | grep -q "^FAIL:"; then
    echo "  FAIL  T-MAP python3 script error (exit $map_drift_exit)"
    FAIL=$((FAIL+1))
fi

echo ""
echo "=== Results: $PASS passed, $FAIL failed ==="
[ "$FAIL" -eq 0 ]
