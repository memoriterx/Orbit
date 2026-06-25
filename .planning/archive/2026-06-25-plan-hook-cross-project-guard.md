# Orbit Hook Cross-Project Pollution Fix — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make orbit's 8 distributed hooks no-op safely (exit 0, no writes, no output) when fired in a project that has not been orbit-initialized, while preserving full behavior in orbit projects — and document/soften the `user`-scope install default that exposes them globally.

**Architecture:** Add one shared bash guard helper (`scripts/orbit-context.sh`) exporting `is_orbit_context()` that returns true only when a **durable orbit marker** exists (`.orbit/config`, created by `orbit-init` *before* any hook runs). Bash hooks source it; Python hooks (`usage-detect.py`, `resume-inject.py`) get an equivalent inline `_is_orbit_context()` guard (Python cannot source bash). The MessageDisplay inline hook in `hooks.json` gets an inline test. The guard runs **before any side effect** (mkdir/write/stdout/block). Install-scope: keep `user` default (intended "team uses orbit everywhere" UX) but document the trade-off and rely on the context guard as the real fix; no scope flip.

**Tech Stack:** bash 3.x (macOS-compatible — no `declare -A`), python3, jq (with python3 fallback), Claude Code hooks.json contract.

## Global Constraints

- **Domain purity:** No project name (oremi, orbit-dev, etc.) may be hardcoded into `plugins/orbit/`. Verified by `grep -riE 'oremi|orbit-dev' plugins/orbit/` returning 0 hits.
- **bash 3.x only:** macOS `/bin/bash` is 3.2 — no associative arrays, no `declare -A`. Match existing hook style.
- **Marker file = `.orbit/config`** — the single durable orbit-context signal. Chosen over bare `.orbit/` (which buggy hooks self-create → chicken-egg) and over `roadmap.md`/`quality-gate.sh` (config is always copied by `orbit-init` Step 4, never user-deletable for normal operation, and never self-created by any hook).
- **Guard placement:** the context check must precede every side effect (`mkdir`, file write, `printf` to stdout, JSON block emission).
- **Preserve orbit behavior:** in a project with `.orbit/config`, every hook must behave exactly as before (regression tests assert this).
- **No new runtime dependency.** Pure bash/python3, already required.
- **Hook contract:** all hooks exit 0 except where a `{"decision":"block"}` JSON is intentionally emitted (quality-gate). The guard's no-op path is always `exit 0` with empty stdout.

- **`CLAUDE_PROJECT_DIR` env-availability risk (critic major #5, ref memory RWV-1).** The guard reads `${CLAUDE_PROJECT_DIR:-$(pwd)}`. Per RWV-1, `CLAUDE_PROJECT_DIR` is **guaranteed for hook execution** (all 8 entry points here are hooks — session-log, usage-detect, resume-inject, notify-done, viewer-attach, quality-gate, skill-consideration are `command`-type hooks; MessageDisplay is an inline hook command), so the primary risk surface (slash-command inline bash) does not apply to this plan. The `$(pwd)` fallback exists only as defense-in-depth for a hypothetical missing-env edge. **Fail direction decided: fail toward no-op (silent) rather than fail toward active.** If `CLAUDE_PROJECT_DIR` were ever unset *and* `pwd` were not the orbit project root, `is_orbit_context()` returns false → the hook no-ops. Consequence: an orbit feature could silently not fire (false negative), but orbit never pollutes a foreign project (no false positive). For a "stop cross-project pollution" goal this is the correct conservative bias — silence over contamination. This trade-off is recorded here and surfaced to the user at Plan Approval; if a future hook needs hard-fail-loud on missing env, it must opt in explicitly (not the default).

---

## Background: the chicken-egg resolution (read before Task 1)

The reported trap: "guard on `.orbit/` existence" fails because `session-log.sh` and `usage-detect.py` **self-create `.orbit/`** via `mkdir -p`. If the guard tested the directory, the hook's own `mkdir` would satisfy it.

**Resolution (verified against `commands/orbit-init.md`):** `orbit-init` Step 4 copies `templates/orbit-config.template` → `.orbit/config`. This is a **durable marker file** written at initialization, *before* any session hook fires, and **no hook ever creates `config`**. So the guard tests for the *file* `.orbit/config`, not the *directory* `.orbit/`. The buggy hooks lose their unconditional `mkdir -p`; they only `mkdir`/write *after* the guard confirms `.orbit/config` exists. No chicken-egg: the marker is established by an explicit user action (`/orbit-init`), never by a hook.

**Trade-off recorded:** a user who manually `mkdir .orbit` without running `/orbit-init` would not be detected as orbit-context. This is correct — bare `.orbit/` with no `config` is not an initialized orbit project. The dev team (`.claude/`) does not use these distributed hooks (it has its own inline SubagentStop per quality-gate.sh comment D8), so dev parity is unaffected.

---

## Considered alternatives (critic minor #6, #7)

**#6 — Central single-prefix guard in `hooks.json` (rejected, with a fallback path).** Instead of editing 8 hook files, prepend `[ -f "${CLAUDE_PROJECT_DIR:-$PWD}/.orbit/config" ] || exit 0;` to every hook's `command` string in `hooks.json` alone (1 file). **Pro:** smaller change surface; guard-omission becomes structurally impossible for any hook registered through hooks.json. **Con (decisive):** (a) the `command`-type hooks invoke `bash script.sh` / `python3 script.py` as a child process — a prefix in the JSON command would gate the *invocation* but the scripts remain independently executable/testable and would carry no guard of their own, so unit tests and any direct call bypass it; (b) python hooks can't share a bash prefix cleanly (wrapping `python3 x.py` behind a bash `&&` works but mixes languages in the manifest and complicates stdin piping for usage-detect/resume-inject); (c) it concentrates 8 distinct behaviors into one brittle JSON string, hurting readability and diffability. **Decision: per-file guards (this plan) + the Task 8b static invariant** give the same "can't forget the guard" guarantee as centralization, without the child-process-bypass hole. The hooks.json inline MessageDisplay command is the *one* case where the inline-prefix form is unavoidable (no script to source), and it is guarded inline in Task 8.

**#7 — Python `_is_orbit_context()` duplicated across `usage-detect.py` and `resume-inject.py` (accepted as-is, invariant-locked).** The two python hooks each carry an identical 3-line `_is_orbit_context()` (python cannot `source` the bash helper). Extracting a shared `orbit_context.py` module is rejected: it adds an import-path/packaging concern for two trivial functions and a 3rd file to keep in sync, for no behavioral gain. Instead, **semantic consistency across all three forms** (bash `is_orbit_context`, python `_is_orbit_context`, hooks.json inline) — same marker path `.orbit/config`, same `CLAUDE_PROJECT_DIR`→`pwd`/`getcwd` fallback — is asserted structurally by the Task 8b static guard (every python hook must define `_is_orbit_context`; every inline command must test `.orbit/config`). The duplication is bounded (2 copies, 3 lines) and drift is caught by CI, so DRY is traded for zero-packaging-surface deliberately.

## File Structure

- **Create:** `plugins/orbit/scripts/orbit-context.sh` — sourced bash helper. Exports `is_orbit_context()` (exit 0 = orbit context, 1 = not). Single source of truth for the bash marker check.
- **Create:** `tests/test-context-guard.sh` — positive/negative suite for all 8 hooks.
- **Modify:** `plugins/orbit/hooks/session-log.sh` — source guard, gate before `mkdir`.
- **Modify:** `plugins/orbit/hooks/usage-detect.py` — inline `_is_orbit_context()`, gate before `makedirs`.
- **Modify:** `plugins/orbit/hooks/resume-inject.py` — inline `_is_orbit_context()`, gate at top (also re-emit prompt unchanged on no-op).
- **Modify:** `plugins/orbit/hooks/notify-done.sh` — source guard, gate before notify.
- **Modify:** `plugins/orbit/hooks/quality-gate.sh` — source guard, gate before companion/project-gate logic (see Task 6 for the reviewer-block decision).
- **Modify:** `plugins/orbit/hooks/skill-consideration.sh` — source guard, gate before context injection.
- **Modify:** `plugins/orbit/hooks/viewer-attach.sh` — source guard, gate before attach.
- **Modify:** `plugins/orbit/hooks/hooks.json` — MessageDisplay inline hook: add marker test before `mkdir`.
- **Modify:** `plugins/orbit/scripts/setup-orbit.sh` — add a one-line scope-trade-off notice near the install step (no behavior change).
- **Modify:** `plugins/orbit/commands/orbit-init.md` — Step 7 note: `.orbit/config` is the context marker; document install-scope guidance.

**Interfaces (the shared contract every task consumes):**
- `is_orbit_context()` (bash): reads env `CLAUDE_PROJECT_DIR` (fallback `pwd`). Returns 0 iff `"$dir/.orbit/config"` is a regular file. No stdout. Idempotent, no side effects.
- `_is_orbit_context()` (python): `os.path.isfile(os.path.join(os.environ.get('CLAUDE_PROJECT_DIR', os.getcwd()), '.orbit', 'config'))`.
- Inline (jq-free bash in hooks.json): `[ -f "${CLAUDE_PROJECT_DIR:-$PWD}/.orbit/config" ]`.

---

### Task 1: Shared bash context-guard helper

**Files:**
- Create: `plugins/orbit/scripts/orbit-context.sh`
- Test: `tests/test-context-guard.sh`

**Interfaces:**
- Produces: `is_orbit_context()` — exit 0 if `${CLAUDE_PROJECT_DIR:-$(pwd)}/.orbit/config` is a regular file, else exit 1. No stdout, no side effects. Safe to `source` from any hook.

- [ ] **Step 1: Write the failing test harness + first cases**

Create `tests/test-context-guard.sh`:

```bash
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

echo ""; echo "context-guard: $PASS passed, $FAIL failed"
[ $FAIL -eq 0 ]
```

- [ ] **Step 2: Run it to confirm it fails**

Run: `bash /Users/dh/Project/orbit/tests/test-context-guard.sh`
Expected: FAIL — `orbit-context.sh: No such file or directory` (source fails).

- [ ] **Step 3: Write the helper**

Create `plugins/orbit/scripts/orbit-context.sh`:

```bash
#!/bin/bash
# orbit-context.sh — shared guard for orbit's distributed hooks.
#
# Sourced by every bash hook. Exports is_orbit_context(): exit 0 iff the
# current project has been orbit-initialized, else exit 1.
#
# "Orbit-initialized" = the durable marker file ${CLAUDE_PROJECT_DIR}/.orbit/config
# exists. This file is written by /orbit-init (Step 4) BEFORE any hook runs and is
# NEVER created by a hook — so it cannot be self-satisfied (chicken-egg safe).
# Bare .orbit/ directory does NOT count: a hook could create it; config it cannot.
#
# No stdout, no side effects. Safe to source repeatedly.

is_orbit_context() {
    local _dir="${CLAUDE_PROJECT_DIR:-$(pwd)}"
    [ -f "$_dir/.orbit/config" ]
}
```

- [ ] **Step 4: Run the test to confirm pass**

Run: `bash /Users/dh/Project/orbit/tests/test-context-guard.sh`
Expected: PASS — 3 guard cases pass.

- [ ] **Step 5: Commit**

```bash
git add plugins/orbit/scripts/orbit-context.sh tests/test-context-guard.sh
git commit -m "feat: add shared orbit-context guard helper + test harness"
```

---

### Task 2: Guard `session-log.sh` (Stop hook — unconditional mkdir, highest-impact leak)

**Files:**
- Modify: `plugins/orbit/hooks/session-log.sh`
- Test: `tests/test-context-guard.sh` (append cases)

**Interfaces:**
- Consumes: `is_orbit_context()` from Task 1.

- [ ] **Step 1: Append failing tests**

Add to `tests/test-context-guard.sh` before the summary line:

```bash
# ---- session-log.sh ----
echo '{"session_id":"abc"}' | CLAUDE_PROJECT_DIR="$PLAINP" bash "$HOOKS/session-log.sh" >/dev/null 2>&1
[ -e "$PLAINP/.orbit" ] && bad "session-log: no-op in plain proj" "created .orbit/" || ok "session-log: no-op in plain proj"

echo '{"session_id":"abc"}' | CLAUDE_PROJECT_DIR="$ORBITP" bash "$HOOKS/session-log.sh" >/dev/null 2>&1
[ -f "$ORBITP/.orbit/session-log.md" ] && ok "session-log: writes in orbit proj" || bad "session-log: writes in orbit proj" "no session-log.md"
```

- [ ] **Step 2: Run to confirm failure**

Run: `bash /Users/dh/Project/orbit/tests/test-context-guard.sh`
Expected: FAIL — "session-log: no-op in plain proj" fails (current code `mkdir -p` creates `.orbit/`).

- [ ] **Step 3: Add guard to `session-log.sh`**

Replace the file body with:

```bash
#!/bin/bash
# Stop 훅용 — 세션 종료 시각을 .orbit/session-log.md 에 append.
# 비-orbit 프로젝트에서는 no-op (orbit-context.sh 가드).
source "${CLAUDE_PLUGIN_ROOT}/scripts/orbit-context.sh" 2>/dev/null || exit 0
is_orbit_context || exit 0

ORBIT_DIR="${CLAUDE_PROJECT_DIR}/.orbit"
mkdir -p "$ORBIT_DIR"
sid=$(cat 2>/dev/null | jq -r '.session_id // "?"' 2>/dev/null || echo "?")
printf '[%s] session stopped (sid=%s)\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$sid" \
  >> "$ORBIT_DIR/session-log.md" 2>/dev/null || true
```

(Note: `mkdir -p` is retained for the rare case where `.orbit/config` exists but `.orbit/` was partially removed; the guard has already confirmed orbit-context.)

- [ ] **Step 4: Run to confirm pass**

Run: `bash /Users/dh/Project/orbit/tests/test-context-guard.sh`
Expected: PASS — both session-log cases pass.

- [ ] **Step 5: Commit**

```bash
git add plugins/orbit/hooks/session-log.sh tests/test-context-guard.sh
git commit -m "fix: session-log hook no-ops outside orbit context"
```

---

### Task 3: Guard `usage-detect.py` (Notification hook — makedirs + log on every notification)

**Files:**
- Modify: `plugins/orbit/hooks/usage-detect.py`
- Test: `tests/test-context-guard.sh` (append)

**Interfaces:**
- Consumes: marker contract (python form). Produces: `_is_orbit_context()` local to the file.

- [ ] **Step 1: Append failing tests**

```bash
# ---- usage-detect.py ----
echo '{"message":"approaching usage limit 95% resets at 3:00 PM"}' | CLAUDE_PROJECT_DIR="$PLAINP" python3 "$HOOKS/usage-detect.py" >/dev/null 2>&1
{ [ -e "$PLAINP/.orbit" ] || [ -f "$PLAINP/.orbit/pending-resume.json" ]; } && bad "usage-detect: no-op in plain" "wrote .orbit/" || ok "usage-detect: no-op in plain"

echo '{"message":"approaching usage limit 95% resets at 3:00 PM"}' | CLAUDE_PROJECT_DIR="$ORBITP" python3 "$HOOKS/usage-detect.py" >/dev/null 2>&1
[ -f "$ORBITP/.orbit/pending-resume.json" ] && ok "usage-detect: writes in orbit" || bad "usage-detect: writes in orbit" "no pending-resume.json"
```

- [ ] **Step 2: Run to confirm failure**

Run: `bash /Users/dh/Project/orbit/tests/test-context-guard.sh`
Expected: FAIL — "usage-detect: no-op in plain" fails (current `os.makedirs` runs unconditionally).

- [ ] **Step 3: Add guard to `usage-detect.py`**

Replace lines 9–13 (the `ORBIT = ...` block and `os.makedirs`) with a guarded version. New top of file after the docstring:

```python
import re, sys, json, os
from datetime import datetime, date, timedelta, time

def _is_orbit_context():
    base = os.environ.get('CLAUDE_PROJECT_DIR', os.getcwd())
    return os.path.isfile(os.path.join(base, '.orbit', 'config'))

if not _is_orbit_context():
    sys.exit(0)

ORBIT = os.path.join(
    os.environ.get('CLAUDE_PROJECT_DIR', os.getcwd()),
    '.orbit'
)
os.makedirs(ORBIT, exist_ok=True)
```

(Everything below `os.makedirs` is unchanged.)

- [ ] **Step 4: Run to confirm pass**

Run: `bash /Users/dh/Project/orbit/tests/test-context-guard.sh`
Expected: PASS — both usage-detect cases pass.

- [ ] **Step 5: Commit**

```bash
git add plugins/orbit/hooks/usage-detect.py tests/test-context-guard.sh
git commit -m "fix: usage-detect hook no-ops outside orbit context"
```

---

### Task 4: Guard `resume-inject.py` (UserPromptSubmit — must re-emit prompt unchanged on no-op)

**Files:**
- Modify: `plugins/orbit/hooks/resume-inject.py`
- Test: `tests/test-context-guard.sh` (append)

**Interfaces:**
- Consumes: marker contract. **Special:** UserPromptSubmit no-op must NOT mangle the user's prompt. Current code `sys.exit(0)` when `pending-resume.json` is absent — which leaves the prompt untouched (Claude Code uses the original). So the guard can simply `sys.exit(0)` early, same as the existing no-pending path. Confirmed safe: exit 0 with no stdout = prompt passes through unmodified.

- [ ] **Step 1: Append failing test**

```bash
# ---- resume-inject.py ----
# Negative test is two-part (critic major #3): the pre-existing silent-exit is a
# REGRESSION LOCK only (it passed before the guard). The guard's actual effect is
# proven by the active-pending contrast: a pending-resume.json that WOULD inject in
# orbit-context must be ignored in a plain project — exit 0, empty stdout, prompt untouched.

# (a) regression lock: no pending, no config → silent pass-through (held identical pre/post-guard)
out=$(echo '{"prompt":"hello"}' | CLAUDE_PROJECT_DIR="$PLAINP" python3 "$HOOKS/resume-inject.py" 2>&1)
rc=$?
{ [ $rc -eq 0 ] && [ -z "$out" ]; } && ok "resume-inject: regression-lock silent no-op (no pending)" || bad "resume-inject: regression-lock silent no-op (no pending)" "rc=$rc out=$out"

# (b) GUARD EFFECT contrast: a real pending file present but NO .orbit/config → still no injection.
#     Without the guard this WOULD emit USAGE-WARNING; with it, the missing config suppresses it.
echo '{"reset_epoch":9999999999}' > "$PLAINP/pending-resume.json"   # note: NOT under .orbit/ (plain has none)
mkdir -p "$PLAINP/.orbit"; echo '{"reset_epoch":9999999999}' > "$PLAINP/.orbit/pending-resume.json"
out=$(echo '{"prompt":"hello"}' | CLAUDE_PROJECT_DIR="$PLAINP" python3 "$HOOKS/resume-inject.py" 2>&1)
rc=$?
{ [ $rc -eq 0 ] && [ -z "$out" ]; } && ok "resume-inject: guard suppresses inject without config" || bad "resume-inject: guard suppresses inject without config" "rc=$rc out=$out (leaked injection in non-orbit)"
rm -rf "$PLAINP/.orbit" "$PLAINP/pending-resume.json"
```

Note: part (a) is a regression lock (already green pre-guard, must stay green). Part (b) is the load-bearing guard-effect proof: identical pending payload, the only difference is `.orbit/config` absence → injection must vanish. This converts the formerly-hollow "exit 0" check into a real positive/negative contrast.

```bash
# ---- resume-inject.py: orbit-context positive (config present → injects) ----
echo '{"reset_epoch":9999999999}' > "$ORBITP/.orbit/pending-resume.json"
out=$(echo '{"prompt":"hello"}' | CLAUDE_PROJECT_DIR="$ORBITP" python3 "$HOOKS/resume-inject.py" 2>/dev/null)
echo "$out" | grep -q "USAGE-WARNING" && ok "resume-inject: injects in orbit" || bad "resume-inject: injects in orbit" "no warning: $out"
rm -f "$ORBITP/.orbit/pending-resume.json"
```

- [ ] **Step 2: Run to confirm current state**

Run: `bash /Users/dh/Project/orbit/tests/test-context-guard.sh`
Expected: "resume-inject: injects in orbit" PASS; "silent no-op" PASS (pre-existing). Proceed to add the guard so the no-op is context-driven, not file-driven.

- [ ] **Step 3: Add guard to `resume-inject.py`**

Insert immediately after the imports (before the `ORBIT = ...` block at line 9):

```python
def _is_orbit_context():
    base = os.environ.get('CLAUDE_PROJECT_DIR', os.getcwd())
    return os.path.isfile(os.path.join(base, '.orbit', 'config'))

if not _is_orbit_context():
    sys.exit(0)
```

- [ ] **Step 4: Run to confirm pass**

Run: `bash /Users/dh/Project/orbit/tests/test-context-guard.sh`
Expected: PASS — both resume-inject cases pass.

- [ ] **Step 5: Commit**

```bash
git add plugins/orbit/hooks/resume-inject.py tests/test-context-guard.sh
git commit -m "fix: resume-inject hook no-ops outside orbit context"
```

---

### Task 5: Guard `notify-done.sh` + `viewer-attach.sh` (SubagentStop/Start side hooks)

**Files:**
- Modify: `plugins/orbit/hooks/notify-done.sh`
- Modify: `plugins/orbit/hooks/viewer-attach.sh`
- Test: `tests/test-context-guard.sh` (append)

**Interfaces:**
- Consumes: `is_orbit_context()`. Both already exit 0 early on missing helper scripts, so adding the guard is low-risk.

- [ ] **Step 1: Append failing tests**

```bash
# ---- notify-done.sh: no-op outside orbit (no notify.sh call) ----
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

# ---- viewer-attach.sh: no-op in plain proj — exit 0 AND no side effects ----
# (critic major #3: assert side-effect absence, not just exit code, since a clean
#  exit alone is satisfied even by an unguarded run that found no tmux.)
out=$(echo '{"agent_id":"x","agent_type":"builder"}' | CLAUDE_PLUGIN_ROOT="$STUBROOT" CLAUDE_PROJECT_DIR="$PLAINP" bash "$HOOKS/viewer-attach.sh" 2>&1)
rc=$?
{ [ $rc -eq 0 ] && [ -z "$out" ] && [ ! -e "$PLAINP/.orbit" ]; } \
  && ok "viewer-attach: no-op in plain (exit 0, no stdout, no .orbit/)" \
  || bad "viewer-attach: no-op in plain" "rc=$rc out=$out orbit_exists=$( [ -e "$PLAINP/.orbit" ] && echo yes || echo no )"
```

- [ ] **Step 2: Run to confirm failure**

Run: `bash /Users/dh/Project/orbit/tests/test-context-guard.sh`
Expected: FAIL — "notify-done: no-op in plain" fails (current code calls notify.sh whenever it is executable).

- [ ] **Step 3: Add guard to `notify-done.sh`**

Insert after the shebang+comment block, before `NOTIFY=...`:

```bash
source "${CLAUDE_PLUGIN_ROOT}/scripts/orbit-context.sh" 2>/dev/null || exit 0
is_orbit_context || exit 0
```

- [ ] **Step 4: Add guard to `viewer-attach.sh`**

Insert after the tmux check (after the `command -v tmux` block, before `payload=$(cat ...)`):

```bash
source "${CLAUDE_PLUGIN_ROOT}/scripts/orbit-context.sh" 2>/dev/null || exit 0
is_orbit_context || exit 0
```

- [ ] **Step 5: Run to confirm pass**

Run: `bash /Users/dh/Project/orbit/tests/test-context-guard.sh`
Expected: PASS — notify-done (both) and viewer-attach cases pass.

- [ ] **Step 6: Commit**

```bash
git add plugins/orbit/hooks/notify-done.sh plugins/orbit/hooks/viewer-attach.sh tests/test-context-guard.sh
git commit -m "fix: notify-done + viewer-attach hooks no-op outside orbit context"
```

---

### Task 6: Guard `quality-gate.sh` (SubagentStop — the reviewer-block decision)

**Files:**
- Modify: `plugins/orbit/hooks/quality-gate.sh`
- Test: `tests/test-context-guard.sh` (append)

**Decision (resolves the prompt's open question):** The context guard goes at the **very top**, before both Gate A (project `.orbit/quality-gate.sh` delegation) and Gate B (companion-plugin reviewer block). Rationale: a non-orbit project that happens to dispatch a subagent named `reviewer` must not be blocked by orbit's companion-plugin requirement. The existing `agent_type != "reviewer" → exit 0` guard remains as a second layer, but the context guard is the primary fix and is unambiguous (no `.orbit/config` ⇒ not an orbit project ⇒ orbit has no authority to block). Gate A delegation to `$CLAUDE_PROJECT_DIR/.orbit/quality-gate.sh` is also correctly skipped — in a non-orbit project that path won't exist anyway, but the guard makes the intent explicit and avoids any surprise if a stray file is present.

**Interfaces:**
- Consumes: `is_orbit_context()`. Must run before `set -euo pipefail`-dependent logic but `source` is safe under `set -u` since the helper defines the function unconditionally.

- [ ] **Step 1: Append failing tests**

```bash
# ---- quality-gate.sh: non-orbit reviewer must NOT be blocked ----
out=$(echo '{"agent_type":"reviewer"}' | CLAUDE_PLUGIN_ROOT="$STUBROOT" CLAUDE_PROJECT_DIR="$PLAINP" bash "$HOOKS/quality-gate.sh" 2>/dev/null)
echo "$out" | grep -q '"decision":"block"' && bad "quality-gate: no block in plain" "blocked non-orbit reviewer" || ok "quality-gate: no block in plain"

# ---- in orbit context, the existing relevance gate still applies ----
# non-reviewer in orbit proj → pass (exit 0, no block)
out=$(echo '{"agent_type":"builder"}' | CLAUDE_PLUGIN_ROOT="$STUBROOT" CLAUDE_PROJECT_DIR="$ORBITP" bash "$HOOKS/quality-gate.sh" 2>/dev/null)
echo "$out" | grep -q '"decision":"block"' && bad "quality-gate: builder not blocked in orbit" "blocked builder" || ok "quality-gate: builder not blocked in orbit"
```

Note: the `STUBROOT` from Task 5 must contain `orbit-context.sh` (it does). Ensure `tests` references `STUBROOT` after Task 5's setup, or duplicate the stub-plugin block before these cases if running Task 6 standalone.

- [ ] **Step 2: Run to confirm failure**

Run: `bash /Users/dh/Project/orbit/tests/test-context-guard.sh`
Expected: FAIL — "quality-gate: no block in plain" may fail because without the guard, a non-orbit `reviewer` reaches the companion-plugin check; with no `claude` CLI in the stub PATH it currently exits 0 (non-block) — but the guard makes this deterministic and independent of CLI presence. If the local environment has `claude` on PATH with companions missing, the unguarded path WOULD block. The test asserts the guarded, deterministic behavior.

- [ ] **Step 3: Add guard to `quality-gate.sh`**

Insert immediately after the comment header and `set -euo pipefail` (after line 19), before the Gate A block:

```bash
# ---- 0. orbit-context 가드: 비-orbit 프로젝트면 orbit은 차단 권한이 없다 ----
source "${CLAUDE_PLUGIN_ROOT}/scripts/orbit-context.sh" 2>/dev/null || exit 0
is_orbit_context || exit 0
```

- [ ] **Step 4: Run to confirm pass**

Run: `bash /Users/dh/Project/orbit/tests/test-context-guard.sh`
Expected: PASS — both quality-gate cases pass.

- [ ] **Step 5: Harden the existing quality-gate suite (MANDATORY — prevents self-nullification)**

> **Why mandatory (critic blocker #1):** `tests/test-quality-gate.sh:57` does `mkdir -p "$TMPPROJECT/.orbit"` but never creates `.orbit/config`. Once the guard lands at the top of `quality-gate.sh`, all 19 existing cases would fail `is_orbit_context()` → immediate `exit 0` → every block / companion-check / escape-hatch assertion becomes a hollow "passes because nothing ran" test. This step is **unconditional and must run before Task 6 is considered done**, not a conditional "if a case no-ops" afterthought.

5a. **Make the 19 cases orbit-context (line ~57 setup):**
```bash
TMPPROJECT="$TMPDIR_ROOT/project"
mkdir -p "$TMPPROJECT/.orbit"
: > "$TMPPROJECT/.orbit/config"        # <-- ADD: durable marker so the guard passes
```

5b. **Add a NEW negative-contrast case** (config absent → orbit must NOT block, proving the block disappears only outside orbit). Append after the T-A block (the reviewer-blocks case), so the same reviewer payload that blocks in orbit-context is shown to pass in a non-orbit dir:
```bash
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
```

This case is the load-bearing contrast: T-A (orbit-context, companion missing) → **block**; T-CTX (same payload, same missing-companion stub, no `.orbit/config`) → **pass**. Together they prove the guard suppresses the block *only* outside orbit and preserves it inside.

- [ ] **Step 6: Run both suites to confirm hardening worked**

```bash
bash /Users/dh/Project/orbit/tests/test-context-guard.sh
bash /Users/dh/Project/orbit/tests/test-quality-gate.sh
```
Expected: both `0 failed`. **Sanity-check the count**: `test-quality-gate.sh` must still report the same number of PASS as before the guard (≈20–21 incl. the new T-CTX), NOT a collapsed/reduced count. A dropped PASS count signals cases silently no-op'd — investigate before proceeding.

- [ ] **Step 7: Commit**

```bash
git add plugins/orbit/hooks/quality-gate.sh tests/test-context-guard.sh tests/test-quality-gate.sh
git commit -m "fix: quality-gate hook no-ops outside orbit context (non-orbit reviewer not blocked)"
```

---

### Task 7: Guard `skill-consideration.sh` (SubagentStart — additionalContext injection)

**Files:**
- Modify: `plugins/orbit/hooks/skill-consideration.sh`
- Test: `tests/test-context-guard.sh` (append)

**Interfaces:**
- Consumes: `is_orbit_context()`. No-op = exit 0 with empty stdout (no `additionalContext`).

- [ ] **Step 1: Append failing tests**

```bash
# ---- skill-consideration.sh: no injection outside orbit ----
out=$(echo '{"agent_type":"builder"}' | CLAUDE_PROJECT_DIR="$PLAINP" bash "$HOOKS/skill-consideration.sh" 2>/dev/null)
[ -z "$out" ] && ok "skill-consideration: no inject in plain" || bad "skill-consideration: no inject in plain" "emitted: $out"

out=$(echo '{"agent_type":"builder"}' | CLAUDE_PROJECT_DIR="$ORBITP" bash "$HOOKS/skill-consideration.sh" 2>/dev/null)
echo "$out" | grep -q "orbit L1" && ok "skill-consideration: injects in orbit" || bad "skill-consideration: injects in orbit" "no L1 context: $out"
```

- [ ] **Step 2: Run to confirm failure**

Run: `bash /Users/dh/Project/orbit/tests/test-context-guard.sh`
Expected: FAIL — "skill-consideration: no inject in plain" fails (current code emits `[orbit L1] You are acting as builder...` for any `agent_type`).

- [ ] **Step 3: Add guard to `skill-consideration.sh`**

Insert after `set -uo pipefail` (line 28), before the stdin-read block:

```bash
# orbit-context 가드: 비-orbit 프로젝트면 스킬 고려 주입 안 함 (no-op).
source "${CLAUDE_PLUGIN_ROOT}/scripts/orbit-context.sh" 2>/dev/null || exit 0
is_orbit_context || exit 0
```

- [ ] **Step 4: Run to confirm pass**

Run: `bash /Users/dh/Project/orbit/tests/test-context-guard.sh`
Expected: PASS — both skill-consideration cases pass.

- [ ] **Step 5: Harden the existing skill-consideration suite (MANDATORY — same self-nullification trap)**

> **Why mandatory (critic blocker #2):** `tests/test-skill-consideration.sh`'s `run_hook` (line 60) never sets `CLAUDE_PROJECT_DIR`; it only sets `PATH` to a stub `bin/` dir. With the guard's fallback `${CLAUDE_PROJECT_DIR:-$(pwd)}`, the project dir resolves to the test process's pwd (the repo root — which DOES happen to have `.orbit/config` during dev, but MUST NOT be relied on; in CI/fresh-clone or any non-orbit checkout it would be absent, and even in-repo it is accidental coupling). Once the guard lands, every positive case ("injects in orbit", "companion-aware filtering", "valid JSON", "never-blocks") is at the mercy of pwd. Make orbit-context **explicit and injected**, not accidental.

5a. **Create an orbit-context project dir in setup** (after line ~16, the `trap` line):
```bash
ORBITPROJ="$TMPDIR_ROOT/orbit-proj"
mkdir -p "$ORBITPROJ/.orbit"
: > "$ORBITPROJ/.orbit/config"
```

5b. **Inject it via `run_hook`** so all positive cases run in orbit-context regardless of pwd. Change `run_hook` (line 56–61) to pass `CLAUDE_PROJECT_DIR`:
```bash
run_hook() {
    local payload="$1"
    local stub_dir="$2"
    local extra="$3"
    local project_dir="${4:-$ORBITPROJ}"     # default = orbit-context
    env PATH="$stub_dir:$PATH" CLAUDE_PROJECT_DIR="$project_dir" $extra \
        bash -c "echo '$payload' | bash '$HOOK'" 2>&1
}
```
This keeps all existing call sites (lines 73/128/146/173) unchanged — they now run in orbit-context by default, so the positive "injects in orbit" assertions stay meaningful after the guard.

5c. **Add a NEW negative-contrast case**: same builder payload in a NON-orbit dir → empty stdout, no injection. Append after the T-H delivery-positive block:
```bash
# ---- T-CTX: no injection outside orbit (context guard, contrast to T-H positive) ----
echo "--- T-CTX: builder in NON-orbit project → no additionalContext injection ---"
PLAINPROJ="$TMPDIR_ROOT/plain"            # NO .orbit/config
mkdir -p "$PLAINPROJ"
out_ctx=$(run_hook "$PAYLOAD_BUILDER" "$(dirname $CLAUDE_PRESENT)" "" "$PLAINPROJ")
if [ -z "$out_ctx" ]; then
    echo "  PASS  T-CTX non-orbit-no-injection (empty stdout)"
    PASS=$((PASS+1))
else
    echo "  FAIL  T-CTX non-orbit-no-injection: expected empty stdout, got: $out_ctx"
    FAIL=$((FAIL+1))
fi
```

Contrast pair: T-H (builder, orbit-context) → valid SubagentStart JSON with `additionalContext`; T-CTX (same builder, same companion-present stub, no `.orbit/config`) → empty stdout (guard no-op). Proves injection is suppressed *only* outside orbit.

- [ ] **Step 6: Run both suites + sanity-check count**

```bash
bash /Users/dh/Project/orbit/tests/test-context-guard.sh
bash /Users/dh/Project/orbit/tests/test-skill-consideration.sh
```
Expected: both `0 failed`. The skill-consideration PASS count must hold steady (all positive cases still fire) plus +1 for T-CTX — a collapsed count means the guard silently no-op'd the positive cases.

- [ ] **Step 7: Commit**

```bash
git add plugins/orbit/hooks/skill-consideration.sh tests/test-context-guard.sh tests/test-skill-consideration.sh
git commit -m "fix: skill-consideration hook no-ops outside orbit context"
```

---

### Task 8: Guard the MessageDisplay inline hook in `hooks.json`

**Files:**
- Modify: `plugins/orbit/hooks/hooks.json` (line 30, MessageDisplay command)
- Test: `tests/test-context-guard.sh` (append — extract & run the inline command)

**Interfaces:**
- Inline guard (no source available in a one-liner): prefix with `[ -f "${CLAUDE_PROJECT_DIR:-$PWD}/.orbit/config" ] || exit 0;`.

- [ ] **Step 1: Append failing test**

```bash
# ---- MessageDisplay inline: extract command from hooks.json and run it ----
MD_CMD=$(python3 -c "import json; d=json.load(open('$HOOKS/hooks.json')); print(d['hooks']['MessageDisplay'][0]['hooks'][0]['command'])")
echo '{"delta":"approaching usage limit, resets at 3:00 PM"}' | CLAUDE_PROJECT_DIR="$PLAINP" bash -c "$MD_CMD" >/dev/null 2>&1
[ -f "$PLAINP/.orbit/usage-detect.log" ] && bad "MessageDisplay: no-op in plain" "wrote log" || ok "MessageDisplay: no-op in plain"
echo '{"delta":"approaching usage limit, resets at 3:00 PM"}' | CLAUDE_PROJECT_DIR="$ORBITP" bash -c "$MD_CMD" >/dev/null 2>&1
[ -f "$ORBITP/.orbit/usage-detect.log" ] && ok "MessageDisplay: writes in orbit" || bad "MessageDisplay: writes in orbit" "no log"
```

- [ ] **Step 2: Run to confirm failure**

Run: `bash /Users/dh/Project/orbit/tests/test-context-guard.sh`
Expected: FAIL — "MessageDisplay: no-op in plain" fails (current inline command `mkdir -p` + log on matching delta).

- [ ] **Step 3: Edit `hooks.json` MessageDisplay command**

Prefix the existing command string (line 30) with the inline guard. New command value:

```
i=$(cat 2>/dev/null); [ -f "${CLAUDE_PROJECT_DIR:-$PWD}/.orbit/config" ] || exit 0; delta=$(printf '%s' "$i" | jq -r '.delta // ""' 2>/dev/null); printf '%s' "$delta" | grep -iqE 'approaching.*usage limit|resets? at [0-9]+:[0-9]+.*[AP]M|out of.*usage' && { mkdir -p "${CLAUDE_PROJECT_DIR}/.orbit"; printf '[%s] EVT=MESSAGE %s\n' "$(date '+%F %T')" "$i" >> "${CLAUDE_PROJECT_DIR}/.orbit/usage-detect.log"; }; exit 0
```

(The `i=$(cat ...)` capture is moved before the guard so stdin is always drained — but the guard fires before any `mkdir`/write. JSON-escape the value correctly when editing the file: `\\n` stays `\\n`, embedded `"` stay escaped.)

- [ ] **Step 4: Validate JSON + run test**

Run: `python3 -c "import json; json.load(open('/Users/dh/Project/orbit/plugins/orbit/hooks/hooks.json'))" && echo JSON-OK`
Expected: `JSON-OK`
Run: `bash /Users/dh/Project/orbit/tests/test-context-guard.sh`
Expected: PASS — both MessageDisplay cases pass.

- [ ] **Step 5: Commit**

```bash
git add plugins/orbit/hooks/hooks.json tests/test-context-guard.sh
git commit -m "fix: MessageDisplay inline hook no-ops outside orbit context"
```

---

### Task 8b: Static invariant guard — enforce the chicken-egg resolution for future hooks (critic major #4)

**Files:**
- Modify: `tests/test-static.sh` (append two grep-based invariant checks before the results line)

**Why (critic major #4):** The chicken-egg "resolution" is currently true only for today's 8-hook snapshot; nothing *enforces* it. A future contributor adding a 9th side-effect hook could (a) forget the guard, re-exposing cross-project pollution, or (b) write to `.orbit/config` from a hook, re-creating the self-satisfying marker bug. These two static greps turn the invariant into a CI-enforced rule so the class of bug cannot silently regress.

**Invariant A — every side-effect hook is guarded.** Each bash hook that writes/notifies/injects must either `source .../orbit-context.sh` (and call `is_orbit_context`) or carry an inline `.orbit/config` test; each python hook must define `_is_orbit_context`; the hooks.json inline command must carry the inline `[ -f .../.orbit/config ]` test.

**Invariant B — no hook writes `.orbit/config`.** No file under `plugins/orbit/hooks/` (nor the MessageDisplay inline command in hooks.json) may write to `.orbit/config` — that would re-introduce a self-created marker (chicken-egg). Reads only.

- [ ] **Step 1: Append the invariant checks to `tests/test-static.sh`** (before the `=== Results ===` line)

```bash
# ---- T-GUARD: EVERY hook in hooks/ carries the orbit-context guard (invariant A) ----
# (critic major #9: dynamic directory traversal — a future 9th hook with no guard
#  must auto-FAIL. Intentional exceptions go in GUARD_ALLOWLIST, never silent omission.)
echo "--- T-GUARD: all hooks guarded (dynamic) ---"
HOOKS_DIR="$ORBIT/hooks"
# Hooks that legitimately carry NO orbit-context guard. Must be justified in a comment.
# (empty today — all 7 script hooks are side-effecting and guarded; the .json/.gitkeep
#  are handled separately below. Add a basename here ONLY with a written rationale.)
GUARD_ALLOWLIST=" "   # space-delimited basenames, e.g. " probe-readonly.sh "
for f in "$HOOKS_DIR"/*.sh "$HOOKS_DIR"/*.py; do
    [ -e "$f" ] || continue            # nullglob-safe if a class is absent
    b=$(basename "$f")
    case "$GUARD_ALLOWLIST" in *" $b "*)
        echo "  PASS  T-GUARD $b allowlisted (intentional no-guard)"; PASS=$((PASS+1)); continue ;;
    esac
    case "$b" in
        *.sh)
            if grep -q 'orbit-context.sh' "$f" && grep -q 'is_orbit_context' "$f"; then
                echo "  PASS  T-GUARD $b sources guard"; PASS=$((PASS+1))
            else
                echo "  FAIL  T-GUARD $b missing orbit-context guard (source + is_orbit_context)"; FAIL=$((FAIL+1))
            fi ;;
        *.py)
            if grep -q '_is_orbit_context' "$f"; then
                echo "  PASS  T-GUARD $b defines _is_orbit_context"; PASS=$((PASS+1))
            else
                echo "  FAIL  T-GUARD $b missing _is_orbit_context guard"; FAIL=$((FAIL+1))
            fi ;;
    esac
done
# hooks.json inline commands must each carry the inline marker test (iterate ALL inline cmds)
if python3 - "$HOOKS_DIR/hooks.json" <<'PYEOF'
import json, sys
d = json.load(open(sys.argv[1]))
missing = []
for event, groups in d.get("hooks", {}).items():
    for g in groups:
        for h in g.get("hooks", []):
            cmd = h.get("command", "")
            # only inline shell commands carry side effects directly; script-invoking
            # commands ("bash .../x.sh", "python3 .../x.py") are guarded inside the script.
            invokes_script = (".sh" in cmd or ".py" in cmd)
            if not invokes_script and ".orbit/config" not in cmd:
                missing.append(event)
sys.exit(1 if missing else 0)
PYEOF
then
    echo "  PASS  T-GUARD hooks.json inline commands carry .orbit/config test"; PASS=$((PASS+1))
else
    echo "  FAIL  T-GUARD a hooks.json inline command missing .orbit/config test"; FAIL=$((FAIL+1))
fi

# ---- T-NOWRITE: no hook may WRITE .orbit/config (invariant B — chicken-egg lock) ----
echo "--- T-NOWRITE: no hook writes .orbit/config ---"
# (critic blocker #8: the prior regex used open\([^)]*...config[^)]*["'](w|a) — the
#  [^)]* stopped at the FIRST ')' so it never reached the mode arg in the common idiom
#  open(os.path.join(O,'.orbit','config'),'w'). Fixed: use .* (not괄호-bounded) so a
#  same-line config-write reaches the mode literal. 2-line variable-split writes
#  (path=...; open(path,'w') on separate lines) are an accepted structural limit.)
NOWRITE_PAT='(>|>>|tee|cp |mv ).*\.orbit/config|open\(.*\.orbit['"'"'",/[:space:]]+config.*['"'"'"](w|a)['"'"'"]'
if grep -rnE "$NOWRITE_PAT" "$HOOKS_DIR" 2>/dev/null; then
    echo "  FAIL  T-NOWRITE a hook writes .orbit/config (re-creates chicken-egg marker)"; FAIL=$((FAIL+1))
else
    echo "  PASS  T-NOWRITE no hook writes .orbit/config"; PASS=$((PASS+1))
fi
# scan the hooks.json inline command strings too
if python3 - "$HOOKS_DIR/hooks.json" <<'PYEOF'
import json, sys, re
d = json.load(open(sys.argv[1]))
pat = re.compile(r'(>|>>|tee).*\.orbit/config')
for event, groups in d.get("hooks", {}).items():
    for g in groups:
        for h in g.get("hooks", []):
            if pat.search(h.get("command", "")):
                sys.exit(1)
sys.exit(0)
PYEOF
then
    echo "  PASS  T-NOWRITE hooks.json inline does not write .orbit/config"; PASS=$((PASS+1))
else
    echo "  FAIL  T-NOWRITE a hooks.json inline command writes .orbit/config"; FAIL=$((FAIL+1))
fi

# ---- T-NOWRITE self-test: positive/negative controls lock the regex (critic blocker #8) ----
# Guarantees the detection regex actually CATCHES a config-write and does NOT false-positive
# on a config-READ or a pending-resume.json write. Run against synthetic fixtures, not hooks/.
echo "--- T-NOWRITE controls: regex catches writes, ignores reads ---"
_ctl=$(mktemp -d)
printf "open(os.path.join(O,'.orbit','config'),'w')\n"            > "$_ctl/pos_join.py"   # MUST catch
printf 'echo x > "%s/.orbit/config"\n' '$DIR'                    > "$_ctl/pos_redir.sh"  # MUST catch
printf "open(os.path.join(ORBIT,'pending-resume.json'),'w')\n"   > "$_ctl/neg_pending.py" # must NOT catch
printf '[ -f "$_dir/.orbit/config" ]\n'                          > "$_ctl/neg_read.sh"    # must NOT catch
_pos_hits=0; _neg_hits=0
for cf in "$_ctl/pos_join.py" "$_ctl/pos_redir.sh"; do
    grep -nE "$NOWRITE_PAT" "$cf" >/dev/null 2>&1 && _pos_hits=$((_pos_hits+1))
done
for cf in "$_ctl/neg_pending.py" "$_ctl/neg_read.sh"; do
    grep -nE "$NOWRITE_PAT" "$cf" >/dev/null 2>&1 && _neg_hits=$((_neg_hits+1))
done
rm -rf "$_ctl"
if [ "$_pos_hits" -eq 2 ] && [ "$_neg_hits" -eq 0 ]; then
    echo "  PASS  T-NOWRITE regex controls (2 positive caught, 0 false-positive)"; PASS=$((PASS+1))
else
    echo "  FAIL  T-NOWRITE regex controls drifted (pos=$_pos_hits/2 neg=$_neg_hits/0)"; FAIL=$((FAIL+1))
fi
```

> **Notes.**
> - **#8 regex fix:** `[^)]*` → `.*`. The old form's `[^)]*` halted at the first `)` (here the `os.path.join(...)` close paren) and never reached the `'w'`/`'a'` mode literal, so the canonical `open(os.path.join(O,'.orbit','config'),'w')` write — the exact idiom usage-detect.py uses for `pending-resume.json` — passed as a false green. The new `.*` is not paren-bounded, so config-then-mode on the same line matches. The control self-test above locks this against future regex edits.
> - **Accepted limit:** a 2-line variable-split write (`path = .../config` then `open(path,'w')` on a later line) is not caught — same-line `join` form is the realistic hook idiom and IS caught; the 2-line form is explicitly out of scope.
> - **#9 dynamic traversal:** T-GUARD now iterates `"$HOOKS_DIR"/*.sh` and `*.py` rather than a fixed list, so a future 9th hook with no guard auto-FAILs. Intentional unguarded hooks go in `GUARD_ALLOWLIST` (a written exception), never a silent gap. The hooks.json check also iterates every inline command across all events.
> - **Read vs write:** a legitimate config READ uses `[ -f ... ]` / `os.path.isfile` / `open(...,'r')` and is not matched (verified by `neg_read.sh` control).

- [ ] **Step 2: Run the static suite (now includes the new invariants)**

Run: `bash /Users/dh/Project/orbit/tests/test-static.sh`
Expected: PASS — every `*.sh`/`*.py` in `hooks/` reports guarded (dynamic traversal); the MessageDisplay inline command carries the `.orbit/config` test; no hook writes `.orbit/config`; **and the T-NOWRITE regex control self-test reports "2 positive caught, 0 false-positive"**. (These pass only after Tasks 1–8 land, so run this task last among the guard tasks.) Note: the control self-test runs against synthetic fixtures, so it is green independent of Tasks 1–8 — if it ever fails, the detection regex has drifted and invariant B is no longer trustworthy.

- [ ] **Step 3: Commit**

```bash
git add tests/test-static.sh
git commit -m "test: static invariant — all side-effect hooks guarded, none write .orbit/config"
```

---

### Task 9: Install-scope policy — documentation, not a default flip (decision B)

**Files:**
- Modify: `plugins/orbit/scripts/setup-orbit.sh` (near the install step, ~line 155)
- Modify: `plugins/orbit/commands/orbit-init.md` (Step 7 / 주의사항)

**Decision (resolves prompt section B):** Keep `ORBIT_INSTALL_SCOPE=user` as default. Rationale: (1) `user` scope is the intended UX — an orbit team uses orbit across all their projects, and a global install is the documented happy path. (2) The real defect was *unguarded hooks*, now fixed in Tasks 1–8: with the context guard, a global install is inert in non-orbit projects (no writes, no blocks, no injection). Flipping to `project`/`local` would break the global-team UX to fix a problem the guard already fixes — wrong layer. (3) `project`/`local` remain available via `ORBIT_INSTALL_SCOPE` for users who want isolation. The change here is **a one-line notice + doc clarity**, not behavior.

**Interfaces:** none (documentation/notice only).

- [ ] **Step 1: Add scope-trade-off notice to `setup-orbit.sh`**

After the install-success branch (near line 158, the existing `[ "$ORBIT_INSTALL_SCOPE" != "user" ] && echo ...` line), add a `user`-scope notice:

```bash
[ "$ORBIT_INSTALL_SCOPE" = "user" ] && \
    echo -e "  ${CYAN}Installed at user scope (global). Orbit hooks are inert in non-orbit projects (guarded by .orbit/config). For per-project isolation, re-run with ORBIT_INSTALL_SCOPE=project.${NC}"
```

- [ ] **Step 2: Verify the notice prints (smoke, no real install)**

Run: `bash -n /Users/dh/Project/orbit/plugins/orbit/scripts/setup-orbit.sh && echo SYNTAX-OK`
Expected: `SYNTAX-OK` (syntax check only; full run requires `claude` CLI).

- [ ] **Step 3: Document the context marker + scope in `orbit-init.md`**

In the 주의사항 section of `commands/orbit-init.md`, append:

```markdown
- `.orbit/config`는 orbit 컨텍스트 마커다. orbit의 배포 훅(session-log, usage-detect,
  resume-inject, quality-gate, skill-consideration, notify-done, viewer-attach,
  MessageDisplay)은 이 파일이 있을 때만 동작한다. `/orbit-init`을 실행하지 않은
  프로젝트(이 파일 없음)에서는 모든 훅이 no-op이므로, orbit을 `user`(전역) 스코프로
  설치해도 비-orbit 프로젝트를 오염시키지 않는다.
- 전역 노출이 우려되면 `ORBIT_INSTALL_SCOPE=project`(또는 `local`)로 설치 범위를
  현재 프로젝트로 제한할 수 있다 — 단 컨텍스트 가드가 있으므로 필수는 아니다.
```

- [ ] **Step 4: Commit**

```bash
git add plugins/orbit/scripts/setup-orbit.sh plugins/orbit/commands/orbit-init.md
git commit -m "docs: clarify .orbit/config context marker + user-scope trade-off"
```

---

### Task 10: Full regression sweep + domain-purity check

**Files:** none (verification only).

- [ ] **Step 1: Run all three hook test suites**

```bash
bash /Users/dh/Project/orbit/tests/test-context-guard.sh
bash /Users/dh/Project/orbit/tests/test-quality-gate.sh
bash /Users/dh/Project/orbit/tests/test-skill-consideration.sh
```
Expected: all three print `0 failed` / exit 0.

- [ ] **Step 2: Run the static test suite (catches drift / map consistency + new guard invariants)**

Run: `bash /Users/dh/Project/orbit/tests/test-static.sh`
Expected: PASS (no new violations). Includes Task 8b's **T-GUARD** (all 8 side-effect hooks carry the orbit-context guard) and **T-NOWRITE** (no hook writes `.orbit/config`). A future unguarded hook or a config-write would fail here.

- [ ] **Step 3: Domain-purity grep (constraint)**

Run: `grep -riE 'oremi|orbit-dev' /Users/dh/Project/orbit/plugins/orbit/ && echo VIOLATION || echo CLEAN`
Expected: `CLEAN`

- [ ] **Step 4: hooks.json validity + every hook still exits 0 on empty/terminal stdin**

```bash
python3 -c "import json; json.load(open('/Users/dh/Project/orbit/plugins/orbit/hooks/hooks.json'))" && echo JSON-OK
for h in session-log notify-done viewer-attach skill-consideration quality-gate; do
  CLAUDE_PLUGIN_ROOT=/Users/dh/Project/orbit/plugins/orbit bash /Users/dh/Project/orbit/plugins/orbit/hooks/$h.sh </dev/null >/dev/null 2>&1; echo "$h exit=$?";
done
```
Expected: `JSON-OK`; each hook `exit=0`.

- [ ] **Step 5: Final commit (if any test-file tweaks were needed)**

```bash
git add -A tests/
git commit -m "test: full cross-project guard regression sweep green"
```

---

## Self-Review

**Spec coverage:**
- (A) context guard for all 8 hooks → Tasks 1–8 (session-log, usage-detect, resume-inject, notify-done, viewer-attach, quality-gate, skill-consideration, MessageDisplay). ✔
- chicken-egg resolution → marker = `.orbit/config` (durable, init-created, never hook-created), documented in Background + Task 1, **invariant-enforced** by Task 8b T-NOWRITE. ✔
- quality-gate reviewer-block decision → Task 6 (guard at top, before Gate A and Gate B). ✔
- (B) install-scope policy → Task 9 (keep `user`, document trade-off, guard is the real fix). ✔
- Domain purity → Task 10 Step 3. ✔
- TDD verification commands → every task has concrete run/expected. ✔

**Critic REVISE remediation:**
- **blocker #1 (quality-gate self-nullification)** → Task 6 Step 5 now MANDATORY: adds `: > "$TMPPROJECT/.orbit/config"` to the 19-case setup so they run in orbit-context, plus new **T-CTX** negative-contrast case (non-orbit reviewer NOT blocked) directly contrasting T-A (orbit reviewer blocked). Count-sanity check guards against silent collapse. ✔
- **blocker #2 (skill-consideration self-nullification)** → Task 7 Step 5 now MANDATORY: `run_hook` injects `CLAUDE_PROJECT_DIR=$ORBITPROJ` (with `.orbit/config`) so all positive cases stay live; new **T-CTX** negative case (builder in non-orbit → empty stdout) contrasts the positive injection. ✔
- **major #3 (hollow negative tests)** → resume-inject negative split into regression-lock (a) + guard-effect contrast (b: pending present, config absent → no injection); viewer-attach negative now asserts exit 0 **AND** empty stdout **AND** no `.orbit/` creation. ✔
- **major #4 (static invariant)** → Task 8b adds T-GUARD (all hooks guarded) + T-NOWRITE (no hook writes `.orbit/config`) to test-static.sh; future hooks can't regress the class. ✔
- **blocker #8 (T-NOWRITE regex missed `os.path.join` config-write)** → regex `[^)]*`→`.*` so `open(os.path.join(O,'.orbit','config'),'w')` is caught; added a positive/negative control self-test (2 positive fixtures must be caught, `pending-resume.json` write + config read must NOT) that locks the regex against drift. 2-line variable-split write accepted as documented structural limit. ✔
- **major #9 (T-GUARD hardcoded list didn't enforce new hooks)** → T-GUARD now dynamically traverses `hooks/*.sh` and `*.py` (a 9th unguarded hook auto-FAILs); hooks.json check iterates every inline command across all events; intentional exceptions go in an explicit `GUARD_ALLOWLIST`, never silent omission. ✔
- **major #5 (`CLAUDE_PROJECT_DIR` false-negative)** → Global Constraints records the env-availability risk, confirms all entry points are hooks (env guaranteed per RWV-1), and decides fail-toward-no-op (silence over contamination), surfaced at Plan Approval. ✔
- **minor #6 (central hooks.json prefix)** → Considered-alternatives: rejected (child-process bypass hole), per-file guards + Task 8b static check give equivalent "can't forget" guarantee. ✔
- **minor #7 (python duplication)** → Considered-alternatives: 2×3-line duplication accepted, drift caught by Task 8b static guard; no shared module (avoids packaging surface). ✔

**Negative/positive contrast coverage (all 8 hooks):** every hook has a positive (orbit-context: fires/writes/injects) AND a negative (non-orbit: no-op with side-effect-absence assertion) case — session-log (write vs no `.orbit/`), usage-detect (pending-resume.json vs none), resume-inject (USAGE-WARNING vs empty + guard-effect contrast), notify-done (sentinel vs none), viewer-attach (clean vs no-stdout/no-`.orbit/`), quality-gate (block vs T-CTX no-block), skill-consideration (additionalContext vs T-CTX empty), MessageDisplay (log vs no log). ✔

**Placeholder scan:** No TBD/TODO; every code step shows full content. ✔

**Type consistency:** `is_orbit_context()` (bash) / `_is_orbit_context()` (python) / inline `[ -f .../.orbit/config ]` used consistently across all tasks, enforced by Task 8b T-GUARD. Marker file is `.orbit/config` in every reference. ✔
