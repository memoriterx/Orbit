#!/bin/bash
# Test suite for quality-gate.sh (D2 companion prong check)
# Tests: T-A, T-B, T-B2, T-C, T-C2, T-C3
#
# Usage: bash tests/test-quality-gate.sh
# Returns 0 if all tests pass, 1 on any failure.

GATE="/Users/dh/Project/orbit/plugins/orbit/hooks/quality-gate.sh"
PASS=0
FAIL=0

# ---- helper ----
run_test() {
    local name="$1"
    local expected_exit="$2"      # 0 or 0 (gate script always exits 0; "block" is stdout)
    local expected_block="$3"     # "yes" or "no"
    local expected_pattern="$4"   # grep pattern in stdout (optional)
    shift 4
    # remaining args: env vars to set before running
    local env_setup="$*"

    local output
    output=$(env $env_setup bash "$GATE" 2>/dev/null)
    local rc=$?

    local blocked="no"
    if echo "$output" | grep -q '"decision":"block"'; then
        blocked="yes"
    fi

    local ok=1
    if [ "$blocked" != "$expected_block" ]; then
        ok=0
    fi
    if [ -n "$expected_pattern" ] && [ "$blocked" = "yes" ]; then
        if ! echo "$output" | grep -q "$expected_pattern"; then
            ok=0
        fi
    fi

    if [ "$ok" = "1" ]; then
        echo "  PASS  $name"
        PASS=$((PASS+1))
    else
        echo "  FAIL  $name"
        echo "        expected_block=$expected_block, got blocked=$blocked"
        echo "        stdout: $output"
        FAIL=$((FAIL+1))
    fi
}

# Create a temp dir for stub scripts and temp project dir
TMPDIR_ROOT=$(mktemp -d)
trap "rm -rf $TMPDIR_ROOT" EXIT

TMPPROJECT="$TMPDIR_ROOT/project"
mkdir -p "$TMPPROJECT/.orbit"
: > "$TMPPROJECT/.orbit/config"        # durable marker so the context guard passes

# Stub claude that reports companion present (enabled)
CLAUDE_PRESENT="$TMPDIR_ROOT/bin/claude-present"
mkdir -p "$TMPDIR_ROOT/bin"
cat > "$CLAUDE_PRESENT" << 'EOF'
#!/bin/bash
# Stub: all three companions present and enabled
if [[ "$*" == *"plugin list"* ]] && [[ "$*" == *"--json"* ]]; then
    printf '[{"name":"superpowers","enabled":true},{"name":"gstack","enabled":true},{"name":"gsd","enabled":true}]'
    exit 0
fi
# fallback: non-json list (for grep path)
printf 'superpowers\ngstack\ngsd\n'
exit 0
EOF
chmod +x "$CLAUDE_PRESENT"

# Stub claude that reports companion MISSING
CLAUDE_MISSING="$TMPDIR_ROOT/bin/claude-missing"
cat > "$CLAUDE_MISSING" << 'EOF'
#!/bin/bash
# Stub: NO companions present
if [[ "$*" == *"plugin list"* ]]; then
    printf '[]'
    exit 0
fi
printf ''
exit 0
EOF
chmod +x "$CLAUDE_MISSING"

# Stub claude that reports companion disabled-but-listed, plus a name-collision
# gstack-helper present enabled, gstack present BUT disabled, gsd present enabled
CLAUDE_DISABLED="$TMPDIR_ROOT/bin/claude-disabled"
cat > "$CLAUDE_DISABLED" << 'EOF'
#!/bin/bash
if [[ "$*" == *"plugin list"* ]] && [[ "$*" == *"--json"* ]]; then
    printf '[{"name":"gstack-helper","enabled":true},{"name":"gstack","enabled":false},{"name":"gsd","enabled":true},{"name":"superpowers","enabled":true}]'
    exit 0
fi
printf 'gstack-helper\ngstack\ngsd\nsuperpowers\n'
exit 0
EOF
chmod +x "$CLAUDE_DISABLED"

# SubagentStop stdin payloads
# reviewer-prong payload (agent_type = reviewer)
PAYLOAD_REVIEWER='{"agent_type":"reviewer","subagent_id":"abc123","task":"Triple Crown verification"}'
# non-reviewer payloads
PAYLOAD_BUILDER='{"agent_type":"builder","subagent_id":"abc124","task":"implementation"}'
PAYLOAD_EXPLORE='{"agent_type":"explore","subagent_id":"abc125","task":"codebase search"}'
PAYLOAD_META='{"agent_type":"architect","subagent_id":"abc126","task":"plan writing"}'
PAYLOAD_NOAGENTTYPE='{"subagent_id":"abc127","task":"some task"}'

# Helper to run gate with stdin payload and PATH override
ORBIT_PLUGIN_ROOT="/Users/dh/Project/orbit/plugins/orbit"
run_gate_with_payload() {
    local payload="$1"
    local claude_bin="$2"
    local extra_env="$3"
    local project_dir="${4:-$TMPPROJECT}"

    # Build PATH with stub bin dir first
    local stub_dir
    stub_dir=$(dirname "$claude_bin")
    # Copy the claude stub to a tmp location named "claude"
    local claude_stub="$stub_dir/claude"
    cp "$claude_bin" "$claude_stub"
    chmod +x "$claude_stub"

    env \
        PATH="$stub_dir:$PATH" \
        CLAUDE_PROJECT_DIR="$project_dir" \
        CLAUDE_PLUGIN_ROOT="$ORBIT_PLUGIN_ROOT" \
        $extra_env \
        bash -c "echo '$payload' | bash '$GATE'" 2>&1
}

echo "=== quality-gate.sh test suite ==="
echo ""

# ---- T-C: Irrelevant work → ALWAYS pass, even with companions missing and claude absent ----
echo "--- T-C: Irrelevant work always passes ---"

# Builder completion, companions missing, claude present but no plugins
out=$(run_gate_with_payload "$PAYLOAD_BUILDER" "$CLAUDE_MISSING" "" "$TMPPROJECT")
if echo "$out" | grep -q '"decision":"block"'; then
    echo "  FAIL  T-C builder-no-companions: expected pass, got block"
    FAIL=$((FAIL+1))
else
    echo "  PASS  T-C builder-no-companions"
    PASS=$((PASS+1))
fi

# Explore completion
out=$(run_gate_with_payload "$PAYLOAD_EXPLORE" "$CLAUDE_MISSING" "" "$TMPPROJECT")
if echo "$out" | grep -q '"decision":"block"'; then
    echo "  FAIL  T-C explore-no-companions: expected pass, got block"
    FAIL=$((FAIL+1))
else
    echo "  PASS  T-C explore-no-companions"
    PASS=$((PASS+1))
fi

# Meta/architect completion
out=$(run_gate_with_payload "$PAYLOAD_META" "$CLAUDE_MISSING" "" "$TMPPROJECT")
if echo "$out" | grep -q '"decision":"block"'; then
    echo "  FAIL  T-C meta-no-companions: expected pass, got block"
    FAIL=$((FAIL+1))
else
    echo "  PASS  T-C meta-no-companions"
    PASS=$((PASS+1))
fi

# dev-team self-build scenario: claude not on PATH (absent), builder payload
# Use PATH=/usr/bin:/bin to ensure claude is not found
out=$(env PATH="/usr/bin:/bin" CLAUDE_PROJECT_DIR="$TMPPROJECT" CLAUDE_PLUGIN_ROOT="$ORBIT_PLUGIN_ROOT" bash -c "echo '$PAYLOAD_BUILDER' | bash '$GATE'" 2>&1)
if echo "$out" | grep -q '"decision":"block"'; then
    echo "  FAIL  T-C dev-self-build-claude-absent: expected pass, got block"
    FAIL=$((FAIL+1))
else
    echo "  PASS  T-C dev-self-build-claude-absent"
    PASS=$((PASS+1))
fi

# No agent_type field → should pass (not a reviewer)
out=$(run_gate_with_payload "$PAYLOAD_NOAGENTTYPE" "$CLAUDE_MISSING" "" "$TMPPROJECT")
if echo "$out" | grep -q '"decision":"block"'; then
    echo "  FAIL  T-C no-agent-type: expected pass, got block"
    FAIL=$((FAIL+1))
else
    echo "  PASS  T-C no-agent-type"
    PASS=$((PASS+1))
fi

echo ""

# ---- T-A: Prong-relevant + tool ABSENT → block ----
echo "--- T-A: Reviewer prong + companion missing → block ---"

out=$(run_gate_with_payload "$PAYLOAD_REVIEWER" "$CLAUDE_MISSING" "" "$TMPPROJECT")
if echo "$out" | grep -q '"decision":"block"'; then
    echo "  PASS  T-A reviewer-no-companions-blocks"
    PASS=$((PASS+1))
    # Also check it names at least one companion and install command
    if echo "$out" | grep -qiE 'gsd|gstack|superpowers'; then
        echo "  PASS  T-A block-names-companion"
        PASS=$((PASS+1))
    else
        echo "  FAIL  T-A block-should-name-companion"
        FAIL=$((FAIL+1))
    fi
else
    echo "  FAIL  T-A reviewer-no-companions: expected block, got pass"
    echo "        stdout: $out"
    FAIL=$((FAIL+1))
fi

echo ""

# ---- T-B: Prong-relevant + all present → pass ----
echo "--- T-B: Reviewer prong + companions present → pass ---"

out=$(run_gate_with_payload "$PAYLOAD_REVIEWER" "$CLAUDE_PRESENT" "" "$TMPPROJECT")
if echo "$out" | grep -q '"decision":"block"'; then
    echo "  FAIL  T-B reviewer-companions-present: expected pass, got block"
    echo "        stdout: $out"
    FAIL=$((FAIL+1))
else
    echo "  PASS  T-B reviewer-companions-present"
    PASS=$((PASS+1))
fi

echo ""

# ---- T-B2: disabled-but-listed + substring-collision ----
echo "--- T-B2: Disabled plugin treated as absent; substring collision handled ---"

out=$(run_gate_with_payload "$PAYLOAD_REVIEWER" "$CLAUDE_DISABLED" "" "$TMPPROJECT")
if echo "$out" | grep -q '"decision":"block"'; then
    echo "  PASS  T-B2 disabled-gstack-blocks"
    PASS=$((PASS+1))
    # Should NOT mention gstack-helper as the problematic plugin
    # The block reason should mention gstack (the actual required one), not gstack-helper
    if echo "$out" | grep -q '"gstack-helper"'; then
        echo "  FAIL  T-B2 false-matched-substring gstack-helper"
        FAIL=$((FAIL+1))
    else
        echo "  PASS  T-B2 no-substring-false-match"
        PASS=$((PASS+1))
    fi
else
    # If all 3 required (gsd, superpowers) are enabled and only gstack disabled,
    # still should block because gstack is required for prong ②
    echo "  FAIL  T-B2 disabled-gstack-should-block"
    echo "        stdout: $out"
    FAIL=$((FAIL+1))
fi

echo ""

# ---- T-C2: Prong-relevant + claude unavailable → warn, not block ----
echo "--- T-C2: Reviewer prong + claude absent → warn, not block ---"

# Use PATH=/usr/bin:/bin to hide claude (typically in ~/.local/bin or /usr/local/bin)
out=$(env PATH="/usr/bin:/bin" CLAUDE_PROJECT_DIR="$TMPPROJECT" CLAUDE_PLUGIN_ROOT="$ORBIT_PLUGIN_ROOT" bash -c "echo '$PAYLOAD_REVIEWER' | bash '$GATE'" 2>&1)
if echo "$out" | grep -q '"decision":"block"'; then
    echo "  FAIL  T-C2 claude-absent-reviewer: expected warn+pass, got block"
    echo "        stdout: $out"
    FAIL=$((FAIL+1))
else
    echo "  PASS  T-C2 claude-absent-reviewer-no-block"
    PASS=$((PASS+1))
fi

echo ""

# ---- T-C3: Escape hatch ----
echo "--- T-C3: ORBIT_SKIP_COMPANION_CHECK=1 → always pass even in prong context ---"

out=$(run_gate_with_payload "$PAYLOAD_REVIEWER" "$CLAUDE_MISSING" "ORBIT_SKIP_COMPANION_CHECK=1" "$TMPPROJECT")
if echo "$out" | grep -q '"decision":"block"'; then
    echo "  FAIL  T-C3 escape-hatch: expected pass, got block"
    echo "        stdout: $out"
    FAIL=$((FAIL+1))
else
    echo "  PASS  T-C3 escape-hatch-passes"
    PASS=$((PASS+1))
    # Check that it printed a skip notice somewhere (stderr or stdout)
    out_both=$(env ORBIT_SKIP_COMPANION_CHECK=1 CLAUDE_PROJECT_DIR="$TMPPROJECT" CLAUDE_PLUGIN_ROOT="$ORBIT_PLUGIN_ROOT" bash -c "echo '$PAYLOAD_REVIEWER' | bash '$GATE'" 2>&1)
    if echo "$out_both" | grep -qiE 'skip|SKIP'; then
        echo "  PASS  T-C3 escape-hatch-notice-visible"
        PASS=$((PASS+1))
    else
        echo "  WARN  T-C3 escape-hatch-notice-not-found (not required but recommended)"
    fi
fi

echo ""

# ---- T-CTX: non-orbit reviewer is NOT blocked (context guard, contrast to T-A) ----
echo "--- T-CTX: Reviewer prong in NON-orbit project → no block ---"
PLAINPROJ="$TMPDIR_ROOT/plain"            # deliberately NO .orbit/config
mkdir -p "$PLAINPROJ"
out=$(run_gate_with_payload "$PAYLOAD_REVIEWER" "$CLAUDE_MISSING" "" "$PLAINPROJ")
if echo "$out" | grep -q '"decision":"block"'; then
    echo "  FAIL  T-CTX non-orbit-reviewer: expected pass (no orbit authority), got block"
    echo "        stdout: $out"
    FAIL=$((FAIL+1))
else
    echo "  PASS  T-CTX non-orbit-reviewer-not-blocked"
    PASS=$((PASS+1))
fi

echo ""

# ---- T-D: syntax check ----
echo "--- T-D: bash -n syntax check ---"
if bash -n "$GATE" 2>&1; then
    echo "  PASS  T-D quality-gate.sh syntax"
    PASS=$((PASS+1))
else
    echo "  FAIL  T-D quality-gate.sh syntax error"
    FAIL=$((FAIL+1))
fi

TEMPLATE="/Users/dh/Project/orbit/plugins/orbit/templates/quality-gate.template.sh"
if bash -n "$TEMPLATE" 2>&1; then
    echo "  PASS  T-D quality-gate.template.sh syntax"
    PASS=$((PASS+1))
else
    echo "  FAIL  T-D quality-gate.template.sh syntax error"
    FAIL=$((FAIL+1))
fi

echo ""
echo "=== Results: $PASS passed, $FAIL failed ==="
[ "$FAIL" -eq 0 ]
