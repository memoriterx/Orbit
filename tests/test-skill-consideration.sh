#!/bin/bash
# Test suite for skill-consideration.sh (L1 consideration-delivery hook, D9)
# Tests: T-H
#
# NOTE: This test validates DELIVERY only.
# Whether the agent actually considered or invoked a skill is unverifiable
# and deliberately NOT tested here. L1's contract is delivery, not compliance.
#
# Usage: bash tests/test-skill-consideration.sh

HOOK="/Users/dh/Project/orbit/plugins/orbit/hooks/skill-consideration.sh"
PASS=0
FAIL=0

TMPDIR_ROOT=$(mktemp -d)
trap "rm -rf $TMPDIR_ROOT" EXIT

# Stub claude: all companions present and enabled
CLAUDE_PRESENT="$TMPDIR_ROOT/bin/claude"
mkdir -p "$TMPDIR_ROOT/bin"
cat > "$CLAUDE_PRESENT" << 'EOF'
#!/bin/bash
if [[ "$*" == *"plugin list"* ]] && [[ "$*" == *"--json"* ]]; then
    printf '[{"name":"superpowers","enabled":true},{"name":"gstack","enabled":true},{"name":"gsd","enabled":true}]'
    exit 0
fi
printf 'superpowers\ngstack\ngsd\n'
exit 0
EOF
chmod +x "$CLAUDE_PRESENT"

# Stub claude: superpowers missing
CLAUDE_NO_SP="$TMPDIR_ROOT/bin2/claude"
mkdir -p "$TMPDIR_ROOT/bin2"
cat > "$CLAUDE_NO_SP" << 'EOF'
#!/bin/bash
if [[ "$*" == *"plugin list"* ]] && [[ "$*" == *"--json"* ]]; then
    printf '[{"name":"gstack","enabled":true},{"name":"gsd","enabled":true}]'
    exit 0
fi
printf 'gstack\ngsd\n'
exit 0
EOF
chmod +x "$CLAUDE_NO_SP"

# Stub: no claude in PATH
EMPTY_BIN="$TMPDIR_ROOT/empty"
mkdir -p "$EMPTY_BIN"

# SubagentStart stdin payload for a builder
PAYLOAD_BUILDER='{"agent_type":"builder","subagent_id":"abc999"}'
PAYLOAD_REVIEWER='{"agent_type":"reviewer","subagent_id":"abc998"}'
PAYLOAD_CRITIC='{"agent_type":"critic","subagent_id":"abc997"}'
PAYLOAD_RESEARCHER='{"agent_type":"researcher","subagent_id":"abc996"}'

run_hook() {
    local payload="$1"
    local stub_dir="$2"
    local extra="$3"
    env PATH="$stub_dir:$PATH" $extra bash -c "echo '$payload' | bash '$HOOK'" 2>&1
}

echo "=== skill-consideration.sh test suite ==="
echo ""
echo "NOTE: Tests validate DELIVERY only."
echo "      Agent compliance (whether it actually used a skill) is unverifiable"
echo "      and is deliberately NOT tested — per L1 contract."
echo ""

# ---- T-H: Delivery positive (builder, all companions present) ----
echo "--- T-H delivery: builder + all companions present ---"

out=$(run_hook "$PAYLOAD_BUILDER" "$(dirname $CLAUDE_PRESENT)" "")
# Must be valid JSON
if echo "$out" | python3 -m json.tool > /dev/null 2>&1; then
    echo "  PASS  T-H valid JSON output"
    PASS=$((PASS+1))
else
    echo "  FAIL  T-H output is not valid JSON"
    echo "        stdout: $out"
    FAIL=$((FAIL+1))
fi

# hookEventName must be SubagentStart
if echo "$out" | python3 -c "import sys,json; d=json.load(sys.stdin); assert d.get('hookSpecificOutput',{}).get('hookEventName')=='SubagentStart'" 2>/dev/null; then
    echo "  PASS  T-H hookEventName=SubagentStart"
    PASS=$((PASS+1))
else
    echo "  FAIL  T-H hookEventName must be SubagentStart"
    FAIL=$((FAIL+1))
fi

# additionalContext must be present and non-empty
ctx=$(echo "$out" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('hookSpecificOutput',{}).get('additionalContext',''))" 2>/dev/null)
if [ -n "$ctx" ]; then
    echo "  PASS  T-H additionalContext present"
    PASS=$((PASS+1))
else
    echo "  FAIL  T-H additionalContext missing or empty"
    FAIL=$((FAIL+1))
fi

# Must contain builder's skills (from superpowers which is present)
if echo "$ctx" | grep -qi "test-driven-development\|superpowers\|builder"; then
    echo "  PASS  T-H context contains role-relevant content"
    PASS=$((PASS+1))
else
    echo "  FAIL  T-H context missing role/skills reference"
    echo "        context: $ctx"
    FAIL=$((FAIL+1))
fi

# Must contain explicit skip permission
if echo "$ctx" | grep -qiE "skip|not needed|unnecessary|omit"; then
    echo "  PASS  T-H context contains skip permission"
    PASS=$((PASS+1))
else
    echo "  FAIL  T-H context missing explicit skip permission"
    echo "        context: $ctx"
    FAIL=$((FAIL+1))
fi

echo ""

# ---- T-H: Companion-aware filtering (superpowers absent) ----
echo "--- T-H companion-aware: superpowers absent → its skills excluded ---"

out2=$(run_hook "$PAYLOAD_BUILDER" "$(dirname $CLAUDE_NO_SP)" "")
ctx2=$(echo "$out2" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('hookSpecificOutput',{}).get('additionalContext',''))" 2>/dev/null)

# superpowers skills must NOT appear when superpowers is absent
if echo "$ctx2" | grep -qi "test-driven-development\|systematic-debugging\|verification-before-completion"; then
    echo "  FAIL  T-H phantom superpowers skill leaked into context (companion absent)"
    echo "        context: $ctx2"
    FAIL=$((FAIL+1))
else
    echo "  PASS  T-H absent companion skills excluded from context"
    PASS=$((PASS+1))
fi

echo ""

# ---- T-H: claude absent → minimal/empty notice, exit 0 ----
echo "--- T-H claude absent → minimal/empty, never blocks ---"

out3=$(run_hook "$PAYLOAD_BUILDER" "$EMPTY_BIN" "")
rc3=$?

# Should not block (SubagentStart can't block structurally, but let's verify no block decision)
if echo "$out3" | grep -q '"decision":"block"'; then
    echo "  FAIL  T-H claude-absent: emitted block decision (forbidden for SubagentStart)"
    FAIL=$((FAIL+1))
else
    echo "  PASS  T-H claude-absent no block decision"
    PASS=$((PASS+1))
fi

# Should exit 0 (or at least not error-exit in a way that gates the subagent)
# SubagentStart hook: exit != 0 only shows stderr, doesn't gate. But we prefer exit 0 for cleanliness.
if [ $rc3 -eq 0 ]; then
    echo "  PASS  T-H claude-absent exits 0"
    PASS=$((PASS+1))
else
    echo "  WARN  T-H claude-absent exits $rc3 (non-fatal for SubagentStart, but unexpected)"
fi

echo ""

# ---- T-H: Never-blocks check across all roles ----
echo "--- T-H never-blocks: no role produces a block decision ---"

for role_payload in "$PAYLOAD_BUILDER" "$PAYLOAD_REVIEWER" "$PAYLOAD_CRITIC" "$PAYLOAD_RESEARCHER"; do
    out_r=$(run_hook "$role_payload" "$(dirname $CLAUDE_PRESENT)" "")
    if echo "$out_r" | grep -q '"decision":"block"'; then
        echo "  FAIL  T-H block-forbidden for payload: $role_payload"
        FAIL=$((FAIL+1))
    else
        echo "  PASS  T-H no-block for $(echo $role_payload | grep -o '"agent_type":"[^"]*"')"
        PASS=$((PASS+1))
    fi
done

echo ""

# ---- Honesty boundary (non-test, recorded as a statement) ----
echo "--- Honesty boundary (explicit non-test) ---"
echo "  NOTE  Whether the agent actually considered or invoked a skill is"
echo "        unverifiable and deliberately NOT tested. L1 contract = delivery only."
echo "        A future contributor must NOT add 'did the agent use it' assertions."
echo ""

# ---- No-mislabel check: L1 must not be described as required/enforced ----
echo "--- T-H no-mislabel: hook script must not call itself required/enforced ---"

HOOK_CONTENT=$(cat "$HOOK" 2>/dev/null || echo "")
if echo "$HOOK_CONTENT" | grep -iqE '(required|enforced|must use|fail-loud|block).*skill|skill.*(required|enforced|must use|fail-loud|block)'; then
    echo "  FAIL  T-H hook contains required/enforced language for skills (BLOCKER #2)"
    FAIL=$((FAIL+1))
else
    echo "  PASS  T-H hook does not mislabel skills as required/enforced"
    PASS=$((PASS+1))
fi

echo ""

# ---- T-D: syntax ----
echo "--- T-D: bash -n syntax check ---"
if bash -n "$HOOK" 2>&1; then
    echo "  PASS  T-D skill-consideration.sh syntax"
    PASS=$((PASS+1))
else
    echo "  FAIL  T-D skill-consideration.sh syntax error"
    FAIL=$((FAIL+1))
fi

echo ""
echo "=== Results: $PASS passed, $FAIL failed ==="
[ "$FAIL" -eq 0 ]
