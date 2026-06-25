#!/bin/bash
# Test suite for orbit-context.sh guard + per-hook positive/negative behavior.
# Usage: bash tests/test-context-guard.sh  (exit 0 = all pass)
HOOKS="/Users/dh/Project/orbit/plugins/orbit/hooks"
SCRIPTS="/Users/dh/Project/orbit/plugins/orbit/scripts"
PASS=0; FAIL=0
ok()  { echo "  PASS  $1"; PASS=$((PASS+1)); }
bad() { echo "  FAIL  $1"; echo "        $2"; FAIL=$((FAIL+1)); }

TMP=$(mktemp -d); trap "rm -rf $TMP" EXIT
ORBITP="$TMP/orbit-proj";   mkdir -p "$ORBITP/.orbit"; : > "$ORBITP/.orbit/config"
PLAINP="$TMP/plain-proj";   mkdir -p "$PLAINP"          # no .orbit/config
PLUGIN_ROOT="/Users/dh/Project/orbit/plugins/orbit"     # real plugin root for hook tests

# ---- Task 1: helper unit ----
source "$SCRIPTS/orbit-context.sh"
( CLAUDE_PROJECT_DIR="$ORBITP" is_orbit_context ) \
  && ok "guard: orbit project detected" || bad "guard: orbit project detected" "expected exit 0"
( CLAUDE_PROJECT_DIR="$PLAINP" is_orbit_context ) \
  && bad "guard: plain project rejected" "expected exit 1" || ok "guard: plain project rejected"
# bare .orbit/ dir with no config must NOT count (chicken-egg guard)
mkdir -p "$PLAINP/.orbit"
( CLAUDE_PROJECT_DIR="$PLAINP" is_orbit_context ) \
  && bad "guard: bare .orbit dir rejected" "expected exit 1" || ok "guard: bare .orbit dir rejected"
rmdir "$PLAINP/.orbit"

echo ""

# ---- session-log.sh ----
echo "--- session-log.sh ---"
echo '{"session_id":"abc"}' | CLAUDE_PLUGIN_ROOT="$PLUGIN_ROOT" CLAUDE_PROJECT_DIR="$PLAINP" bash "$HOOKS/session-log.sh" >/dev/null 2>&1
[ -e "$PLAINP/.orbit" ] && bad "session-log: no-op in plain proj" "created .orbit/" || ok "session-log: no-op in plain proj"

echo '{"session_id":"abc"}' | CLAUDE_PLUGIN_ROOT="$PLUGIN_ROOT" CLAUDE_PROJECT_DIR="$ORBITP" bash "$HOOKS/session-log.sh" >/dev/null 2>&1
[ -f "$ORBITP/.orbit/session-log.md" ] && ok "session-log: writes in orbit proj" || bad "session-log: writes in orbit proj" "no session-log.md"

# unset CLAUDE_PROJECT_DIR must fall back to $(pwd) (matches is_orbit_context guard)
rm -f "$ORBITP/.orbit/session-log.md"
( cd "$ORBITP" && echo '{"session_id":"u"}' | \
  env -u CLAUDE_PROJECT_DIR CLAUDE_PLUGIN_ROOT="$PLUGIN_ROOT" bash "$HOOKS/session-log.sh" >/dev/null 2>&1 )
[ -f "$ORBITP/.orbit/session-log.md" ] \
  && ok "session-log: falls back to pwd when CLAUDE_PROJECT_DIR unset" \
  || bad "session-log: falls back to pwd when CLAUDE_PROJECT_DIR unset" "no session-log.md written"

echo ""

# ---- usage-detect.py ----
echo "--- usage-detect.py ---"
echo '{"message":"approaching usage limit 95% resets at 3:00 PM"}' | CLAUDE_PROJECT_DIR="$PLAINP" python3 "$HOOKS/usage-detect.py" >/dev/null 2>&1
{ [ -e "$PLAINP/.orbit" ] || [ -f "$PLAINP/.orbit/pending-resume.json" ]; } && bad "usage-detect: no-op in plain" "wrote .orbit/" || ok "usage-detect: no-op in plain"

echo '{"message":"approaching usage limit 95% resets at 3:00 PM"}' | CLAUDE_PROJECT_DIR="$ORBITP" python3 "$HOOKS/usage-detect.py" >/dev/null 2>&1
[ -f "$ORBITP/.orbit/pending-resume.json" ] && ok "usage-detect: writes in orbit" || bad "usage-detect: writes in orbit" "no pending-resume.json"

echo ""

# ---- resume-inject.py ----
echo "--- resume-inject.py ---"
# (a) regression lock: no pending, no config → silent pass-through (held identical pre/post-guard)
out=$(echo '{"prompt":"hello"}' | CLAUDE_PROJECT_DIR="$PLAINP" python3 "$HOOKS/resume-inject.py" 2>&1)
rc=$?
{ [ $rc -eq 0 ] && [ -z "$out" ]; } && ok "resume-inject: regression-lock silent no-op (no pending)" || bad "resume-inject: regression-lock silent no-op (no pending)" "rc=$rc out=$out"

# (b) GUARD EFFECT contrast: a real pending file present but NO .orbit/config → still no injection.
mkdir -p "$PLAINP/.orbit"; echo '{"reset_epoch":9999999999}' > "$PLAINP/.orbit/pending-resume.json"
out=$(echo '{"prompt":"hello"}' | CLAUDE_PROJECT_DIR="$PLAINP" python3 "$HOOKS/resume-inject.py" 2>&1)
rc=$?
{ [ $rc -eq 0 ] && [ -z "$out" ]; } && ok "resume-inject: guard suppresses inject without config" || bad "resume-inject: guard suppresses inject without config" "rc=$rc out=$out (leaked injection in non-orbit)"
rm -rf "$PLAINP/.orbit"

# ---- resume-inject.py: orbit-context positive (config present → injects) ----
echo '{"reset_epoch":9999999999}' > "$ORBITP/.orbit/pending-resume.json"
out=$(echo '{"prompt":"hello"}' | CLAUDE_PROJECT_DIR="$ORBITP" python3 "$HOOKS/resume-inject.py" 2>/dev/null)
echo "$out" | grep -q "USAGE-WARNING" && ok "resume-inject: injects in orbit" || bad "resume-inject: injects in orbit" "no warning: $out"
rm -f "$ORBITP/.orbit/pending-resume.json"

echo ""

# ---- notify-done.sh + viewer-attach.sh ----
echo "--- notify-done.sh + viewer-attach.sh ---"
# Stub a notify.sh that writes a sentinel; guard must prevent it in plain proj.
STUBROOT="$TMP/stubplugin"; mkdir -p "$STUBROOT/scripts"
cp "$SCRIPTS/orbit-context.sh" "$STUBROOT/scripts/orbit-context.sh"
printf '#!/bin/bash\necho called >> "%s/notify-sentinel"\n' "$TMP" > "$STUBROOT/scripts/notify.sh"
chmod +x "$STUBROOT/scripts/notify.sh"
echo '{"agent_type":"builder","last_assistant_message":"done"}' | \
  CLAUDE_PLUGIN_ROOT="$STUBROOT" CLAUDE_PROJECT_DIR="$PLAINP" bash "$HOOKS/notify-done.sh" >/dev/null 2>&1
[ -f "$TMP/notify-sentinel" ] && bad "notify-done: no-op in plain" "called notify.sh" || ok "notify-done: no-op in plain"
echo '{"agent_type":"builder","last_assistant_message":"done"}' | \
  CLAUDE_PLUGIN_ROOT="$STUBROOT" CLAUDE_PROJECT_DIR="$ORBITP" bash "$HOOKS/notify-done.sh" >/dev/null 2>&1
[ -f "$TMP/notify-sentinel" ] && ok "notify-done: fires in orbit" || bad "notify-done: fires in orbit" "notify.sh not called"

# viewer-attach: no-op in plain proj — exit 0 AND no side effects
out=$(echo '{"agent_id":"x","agent_type":"builder"}' | CLAUDE_PLUGIN_ROOT="$STUBROOT" CLAUDE_PROJECT_DIR="$PLAINP" bash "$HOOKS/viewer-attach.sh" 2>&1)
rc=$?
{ [ $rc -eq 0 ] && [ -z "$out" ] && [ ! -e "$PLAINP/.orbit" ]; } \
  && ok "viewer-attach: no-op in plain (exit 0, no stdout, no .orbit/)" \
  || bad "viewer-attach: no-op in plain" "rc=$rc out=$out orbit_exists=$( [ -e "$PLAINP/.orbit" ] && echo yes || echo no )"

echo ""

# ---- quality-gate.sh ----
echo "--- quality-gate.sh ---"
out=$(echo '{"agent_type":"reviewer"}' | CLAUDE_PLUGIN_ROOT="$STUBROOT" CLAUDE_PROJECT_DIR="$PLAINP" bash "$HOOKS/quality-gate.sh" 2>/dev/null)
echo "$out" | grep -q '"decision":"block"' && bad "quality-gate: no block in plain" "blocked non-orbit reviewer" || ok "quality-gate: no block in plain"

# non-reviewer in orbit proj → pass (exit 0, no block)
out=$(echo '{"agent_type":"builder"}' | CLAUDE_PLUGIN_ROOT="$STUBROOT" CLAUDE_PROJECT_DIR="$ORBITP" bash "$HOOKS/quality-gate.sh" 2>/dev/null)
echo "$out" | grep -q '"decision":"block"' && bad "quality-gate: builder not blocked in orbit" "blocked builder" || ok "quality-gate: builder not blocked in orbit"

echo ""

# ---- skill-consideration.sh ----
echo "--- skill-consideration.sh ---"
out=$(echo '{"agent_type":"builder"}' | CLAUDE_PLUGIN_ROOT="$PLUGIN_ROOT" CLAUDE_PROJECT_DIR="$PLAINP" bash "$HOOKS/skill-consideration.sh" 2>/dev/null)
[ -z "$out" ] && ok "skill-consideration: no inject in plain" || bad "skill-consideration: no inject in plain" "emitted: $out"

out=$(echo '{"agent_type":"builder"}' | CLAUDE_PLUGIN_ROOT="$PLUGIN_ROOT" CLAUDE_PROJECT_DIR="$ORBITP" bash "$HOOKS/skill-consideration.sh" 2>/dev/null)
echo "$out" | grep -q "orbit L1" && ok "skill-consideration: injects in orbit" || bad "skill-consideration: injects in orbit" "no L1 context: $out"

echo ""

# ---- set -u hooks: CLAUDE_PLUGIN_ROOT unset → silent exit 0 (regression: unbound variable) ----
echo "--- set -u hooks: unset CLAUDE_PLUGIN_ROOT ---"

# quality-gate.sh with unset CLAUDE_PLUGIN_ROOT must exit 0 with no stderr noise
out=$(echo '{"agent_type":"reviewer"}' | env -u CLAUDE_PLUGIN_ROOT bash "$HOOKS/quality-gate.sh" 2>&1)
rc=$?
{ [ $rc -eq 0 ] && ! echo "$out" | grep -q "unbound variable"; } \
  && ok "quality-gate: unset CLAUDE_PLUGIN_ROOT → silent exit 0" \
  || bad "quality-gate: unset CLAUDE_PLUGIN_ROOT → silent exit 0" "rc=$rc out=$out"

# skill-consideration.sh with unset CLAUDE_PLUGIN_ROOT must exit 0 with no stderr noise
out=$(echo '{"agent_type":"builder"}' | env -u CLAUDE_PLUGIN_ROOT bash "$HOOKS/skill-consideration.sh" 2>&1)
rc=$?
{ [ $rc -eq 0 ] && ! echo "$out" | grep -q "unbound variable"; } \
  && ok "skill-consideration: unset CLAUDE_PLUGIN_ROOT → silent exit 0" \
  || bad "skill-consideration: unset CLAUDE_PLUGIN_ROOT → silent exit 0" "rc=$rc out=$out"

echo ""

# ---- MessageDisplay inline hook ----
echo "--- MessageDisplay inline hook ---"
MD_CMD=$(python3 -c "import json; d=json.load(open('$HOOKS/hooks.json')); print(d['hooks']['MessageDisplay'][0]['hooks'][0]['command'])")
echo '{"delta":"approaching usage limit, resets at 3:00 PM"}' | CLAUDE_PROJECT_DIR="$PLAINP" bash -c "$MD_CMD" >/dev/null 2>&1
[ -f "$PLAINP/.orbit/usage-detect.log" ] && bad "MessageDisplay: no-op in plain" "wrote log" || ok "MessageDisplay: no-op in plain"
echo '{"delta":"approaching usage limit, resets at 3:00 PM"}' | CLAUDE_PROJECT_DIR="$ORBITP" bash -c "$MD_CMD" >/dev/null 2>&1
[ -f "$ORBITP/.orbit/usage-detect.log" ] && ok "MessageDisplay: writes in orbit" || bad "MessageDisplay: writes in orbit" "no log"

# unset CLAUDE_PROJECT_DIR: guard uses :-$PWD, so mkdir/append must use the SAME fallback
rm -f "$ORBITP/.orbit/usage-detect.log"
( cd "$ORBITP" && echo '{"delta":"approaching usage limit, resets at 3:00 PM"}' | \
  env -u CLAUDE_PROJECT_DIR bash -c "$MD_CMD" >/dev/null 2>&1 )
[ -f "$ORBITP/.orbit/usage-detect.log" ] \
  && ok "MessageDisplay: falls back to PWD when CLAUDE_PROJECT_DIR unset" \
  || bad "MessageDisplay: falls back to PWD when CLAUDE_PROJECT_DIR unset" "no usage-detect.log"

echo ""
echo "context-guard: $PASS passed, $FAIL failed"
[ $FAIL -eq 0 ]
