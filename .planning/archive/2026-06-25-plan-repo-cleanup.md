# Repo Cleanup & Shell Hardening Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Harden two deployed hook shell paths against unset `CLAUDE_PROJECT_DIR`, fix doc/manifest drift, harden the dev setup script, and remove dead/stale documentation — without breaking the 122-test baseline or domain purity.

**Architecture:** Two independent change groups. **Group AB (deploy hardening)** touches `plugins/orbit/` (product) + `README.md` + adds regression test cases; it is push-bound. **Group CD (doc cleanup)** touches dev-only docs (`docs/`, `.planning/`, `setup-orbit-dev.sh`); the user said the doc-cleanup portion does not need to be pushed. The two groups commit separately and never interleave.

**Tech Stack:** bash hooks, JSON manifests (`plugin.json`), markdown docs, bash test harness in `tests/` (plain `pass/fail` echo runners, no framework).

## Global Constraints

- **Domain purity:** No project name (`oremi`, `Oremi`, `orbit-dev`, real user paths) may be hardcoded into any file under `plugins/orbit/`. Verify with `grep -riE 'oremi|오르미|orbit-dev' plugins/orbit/` → 0 hits after AB changes.
- **Test baseline (must stay GREEN):** 122 tests across 4 runners — `test-context-guard.sh` (21), `test-quality-gate.sh` (16), `test-skill-consideration.sh` (15), `test-static.sh` (70). Run each via `bash tests/<file>.sh`; pass line is `N passed, 0 failed`. Group AB must keep all 122 GREEN and ADD new cases (count rises).
- **Commit prefixes:** `fix/feat/chore/docs/refactor:`. **No `Co-Authored-By` line** (project rule — overrides any default).
- **Commit separation & push boundary:** Group AB (Tasks 1–4) = product hardening, committed together (or in 2 product/README commits), **pushed**. Group CD (Tasks 5–7) = doc cleanup, separate commit(s), **NOT pushed** (user directive). Never mix AB and CD files in one commit.
- **Leader-only meta files** are out of scope here; this plan is builder-executed end-to-end.

---

## File Structure

| File | Group | Responsibility | Change |
|------|-------|----------------|--------|
| `plugins/orbit/hooks/session-log.sh` | A | Stop hook: append session-stop to `.orbit/session-log.md` | Modify line 7: bare `${CLAUDE_PROJECT_DIR}` → `${CLAUDE_PROJECT_DIR:-$(pwd)}` |
| `plugins/orbit/hooks/hooks.json` | A | Hook registry; MessageDisplay inline cmd | Modify line 30: 2× bare `${CLAUDE_PROJECT_DIR}` → `${CLAUDE_PROJECT_DIR:-$PWD}` |
| `tests/test-context-guard.sh` | A | Regression harness for the two hooks above | Add cases: both hooks no-crash when `CLAUDE_PROJECT_DIR` unset |
| `README.md` | B | Public product README hooks summary (line 461) | Modify: list all 6 events accurately |
| `plugins/orbit/.claude-plugin/plugin.json` | B | Claude Code manifest | **Decision below — likely NO change** |
| `docs/smoke-results.md` | C/D | Internal dated QA snapshot (2026-06-18) | **DELETE** (stale `orbit-base` paths) |
| `setup-orbit-dev.sh` | C | Dev-team tmux setup (root, dev-only) | `set -e`→`set -euo pipefail`; fix stale comments |
| `docs/2026-06-18-team-framework-packaging-{design,plan}.md` | D | Superseded 2-plugin design/plan | **DELETE** (superseded) |
| `.planning/plans/2026-06-19-OMC-8-security-reviewer.md` | D | Rejected security-reviewer plan | **DELETE** (rejected, unreferenced) |

---

## Resolved Open Questions (Discovery)

These were verified during discovery — implementers do NOT re-investigate:

1. **plugin.json `skills` key (Task 4 — DECISION: do NOT add).**
   - The codex manifest (`plugins/orbit/.codex-plugin/plugin.json:24`) has `"skills": "./skills/"`. The Claude Code manifest (`.claude-plugin/plugin.json`) omits it.
   - **Verified:** Claude Code auto-discovers `skills/` by convention (project memory `orbit_plugin_discovery`: "Claude Code는 agents/commands/skills/hooks를 컨벤션 디렉터리 자동발견, plugin.json 경로선언 선택").
   - **Verified:** `roadmap.md:47` already adjudicated this exact asymmetry as a **known non-issue** ("plugin.json↔codex 비대칭(MINOR) = 알려진 비이슈 — Claude 컨벤션 자동발견").
   - The codex `skills` key exists because the Codex runtime requires explicit declaration; Claude does not. Adding it to the Claude manifest is **inert at best, and risks implying a non-convention loader.** The two manifests are intentionally asymmetric per-runtime — that asymmetry is the consistency baseline, not a defect.
   - **Conclusion: leave `.claude-plugin/plugin.json` unchanged.** Task 4 only records this rationale (no file edit). If a reviewer insists on symmetry, the safe action is a comment in the codebase memory — not a manifest field.

2. **README hooks summary (Task 5/B).** `README.md:461` summarizes hooks as 3 groups and omits `Stop`, `Notification`, `MessageDisplay`. Actual `hooks.json` registers 6 events: `Stop`, `Notification`, `MessageDisplay`, `UserPromptSubmit`, `SubagentStop`, `SubagentStart`.

3. **smoke-results.md (Task 5/C).** 14+ `plugins/orbit-base/` path hits. `roadmap.md:47` + `plan-rwv-install-fixes.md:42,288` flagged it as a stale internal NIT, cleanup-optional. No functional link breaks on delete (the references are prose NIT notes, not navigational links). **The user's scope item C says "update paths to `plugins/orbit/`", but discovery shows the whole file is a dated 2026-06-18 QA snapshot superseded by the v1.0.0 rename — the conservative-but-decisive call is DELETE, not patch.** See Task 5 for both options; recommendation = DELETE.

4. **setup-orbit-dev.sh `set -euo pipefail` regression risk.** Inspected: arrays use `${MISSING[@]}` (safe under `set -u` only when non-empty — but it is always referenced after `${#MISSING[@]} -gt 0` guard OR within a `for` that handles empty); `${agent_name:-}` and `${2:-}` already use defaults. One real risk: `tput`/`command -v` subshell exits under `pipefail`. Task 6 adds the flags AND verifies a dry parse + guarded-variable audit.

5. **Test runner.** No aggregate runner script exists; each `tests/*.sh` is run directly. `setup-orbit-dev.sh` (root, dev-only) is NOT in `test-static.sh`'s `bash -n` list (that list covers the *product* `plugins/orbit/scripts/setup-orbit.sh`). So Task 6's syntax safety is verified manually, not by the suite.

---

## High-Risk Trigger Assessment (Architect's judgment — for Leader's gate)

| Trigger | Fires? | Reasoning |
|---------|--------|-----------|
| **T1 Irreversibility** | **NO** | Shell edits are 1-line and trivially revertible. Doc deletions are git-tracked (recoverable via history). No data migration, no backward-compat break. README wording is reversible. |
| **T2 Broad impact** | **NO** | AB touches 2 hook files + README + 1 test file. No public interface/contract change — the hooks' stdout/exit-code contract is *unchanged* (the fallback only changes which dir is used when env is unset, which was previously a crash path, not a contract). Under 3 components per group. |
| **T3 Security/Integrity/Deletion** | **BORDERLINE → flag for Leader** | Scope item D involves **file deletion** (3–4 docs). All are dev-only, git-recoverable, and verified unreferenced — but "deletion path" is literally a T3 keyword. **Recommendation: low-risk in substance** (no product files deleted; `plugins/orbit/` deletions explicitly forbidden by this plan; all deletions are dated/superseded internal docs with grep-confirmed zero functional inbound links). I judge this does NOT warrant critic, but flag it so the Leader makes the call. |
| **T4 New external dependency** | **NO** | No new runtime deps, services, or vendor lock. `set -euo pipefail` is a bash builtin behavior change, not a dependency. |

**Architect's recommendation:** Net **low-risk**. The only trigger-adjacent item is doc deletion (T3 keyword "deletion"), but it is dev-only, reversible via git, and grep-verified safe. I recommend **critic may be skipped**, but defer the T3 deletion call to the Leader per the four-trigger OR gate. If the Leader prefers caution, scope item D can be downgraded from DELETE to "move to `.planning/archive/`" with no plan rework (noted in Task 7).

---

## Group AB — Deploy Hardening (PUSH-BOUND)

### Task 1: Harden `session-log.sh` against unset `CLAUDE_PROJECT_DIR`

**Files:**
- Modify: `plugins/orbit/hooks/session-log.sh:7`
- Test: `tests/test-context-guard.sh` (add case)

**Interfaces:**
- Consumes: stdin JSON `{"session_id": "..."}`; env `CLAUDE_PLUGIN_ROOT`, `CLAUDE_PROJECT_DIR`. Sourced guard `orbit-context.sh::is_orbit_context` already uses `${CLAUDE_PROJECT_DIR:-$(pwd)}`.
- Produces: appends a line to `$ORBIT_DIR/session-log.md`; exit 0 always (no-op outside orbit context). Contract unchanged.

- [ ] **Step 1: Write the failing test**

Add to `tests/test-context-guard.sh`, in the `session-log.sh` section (after the existing line ~35 orbit-write check). The test asserts the hook does NOT crash (no `unbound variable` / non-clean behavior) when `CLAUDE_PROJECT_DIR` is unset but the cwd IS an orbit project:

```bash
# unset CLAUDE_PROJECT_DIR must fall back to $(pwd) (matches is_orbit_context guard)
( cd "$ORBITP" && echo '{"session_id":"u"}' | \
  env -u CLAUDE_PROJECT_DIR CLAUDE_PLUGIN_ROOT="$PLUGIN_ROOT" bash "$HOOKS/session-log.sh" >/dev/null 2>&1 )
[ -f "$ORBITP/.orbit/session-log.md" ] \
  && ok "session-log: falls back to pwd when CLAUDE_PROJECT_DIR unset" \
  || bad "session-log: falls back to pwd when CLAUDE_PROJECT_DIR unset" "no session-log.md written"
```

> Note: `$ORBITP`, `$PLUGIN_ROOT`, `$HOOKS`, `ok`, `bad` are already defined at the top of `test-context-guard.sh`. `$ORBITP` is a temp dir containing `.orbit/config`, so `is_orbit_context` returns true via its own `:-$(pwd)` fallback.

- [ ] **Step 2: Run test to verify it fails**

Run: `bash tests/test-context-guard.sh`
Expected: FAIL on the new case — current line 7 `ORBIT_DIR="${CLAUDE_PROJECT_DIR}/.orbit"` expands to `/.orbit` when unset, so `mkdir -p /.orbit` fails (permission) and no `session-log.md` is written in `$ORBITP`. Failed count = 1, message "no session-log.md written".

- [ ] **Step 3: Write minimal implementation**

In `plugins/orbit/hooks/session-log.sh`, change line 7:

```bash
ORBIT_DIR="${CLAUDE_PROJECT_DIR:-$(pwd)}/.orbit"
```

(was: `ORBIT_DIR="${CLAUDE_PROJECT_DIR}/.orbit"`)

- [ ] **Step 4: Run test to verify it passes**

Run: `bash tests/test-context-guard.sh`
Expected: `context-guard: 22 passed, 0 failed` (21 prior + 1 new).

- [ ] **Step 5: Verify no regression across the whole suite**

Run: `for t in tests/*.sh; do bash "$t" | tail -1; done`
Expected: 22 + 16 + 15 + 70 = 123 passed, 0 failed total.

- [ ] **Step 6: Verify domain purity unaffected**

Run: `grep -riE 'oremi|오르미|orbit-dev' plugins/orbit/hooks/session-log.sh`
Expected: no output (exit 1).

- [ ] **Step 7: Do NOT commit yet** — fold this into Task 2's commit (both are Group A product hardening). Proceed to Task 2.

---

### Task 2: Harden `hooks.json` MessageDisplay inline command

**Files:**
- Modify: `plugins/orbit/hooks/hooks.json:30`
- Test: `tests/test-context-guard.sh` (add case)

**Interfaces:**
- Consumes: stdin JSON `{"delta": "..."}`; env `CLAUDE_PROJECT_DIR`. The inline command's guard already uses `[ -f "${CLAUDE_PROJECT_DIR:-$PWD}/.orbit/config" ] || exit 0`, but the subsequent `mkdir`/`append` use **bare** `${CLAUDE_PROJECT_DIR}` (mismatch).
- Produces: appends to `${...}/.orbit/usage-detect.log` only when delta matches usage-limit patterns AND `.orbit/config` exists; exit 0 always. Contract unchanged.

- [ ] **Step 1: Write the failing test**

Add to `tests/test-context-guard.sh`, in the `MessageDisplay inline hook` section (after the existing line ~140 orbit-write check). The existing test already extracts `MD_CMD` via the python one-liner at line 136 — reuse `$MD_CMD`:

```bash
# unset CLAUDE_PROJECT_DIR: guard uses :-$PWD, so mkdir/append must use the SAME fallback
( cd "$ORBITP" && echo '{"delta":"approaching usage limit, resets at 3:00 PM"}' | \
  env -u CLAUDE_PROJECT_DIR bash -c "$MD_CMD" >/dev/null 2>&1 )
[ -f "$ORBITP/.orbit/usage-detect.log" ] \
  && ok "MessageDisplay: falls back to PWD when CLAUDE_PROJECT_DIR unset" \
  || bad "MessageDisplay: falls back to PWD when CLAUDE_PROJECT_DIR unset" "no usage-detect.log"
```

> `$MD_CMD` is the command string from `hooks.json`; `$ORBITP` contains `.orbit/config`. With `CLAUDE_PROJECT_DIR` unset, the guard passes (`:-$PWD` → cwd `$ORBITP`), but the bare `mkdir "${CLAUDE_PROJECT_DIR}/.orbit"` becomes `mkdir "/.orbit"` (fails) and the append targets `/.orbit/usage-detect.log` (fails) — so no log lands in `$ORBITP`.

- [ ] **Step 2: Run test to verify it fails**

Run: `bash tests/test-context-guard.sh`
Expected: FAIL on the new case — "no usage-detect.log". (Failed count = 1.)

- [ ] **Step 3: Write minimal implementation**

In `plugins/orbit/hooks/hooks.json`, line 30, replace the two bare `${CLAUDE_PROJECT_DIR}` occurrences inside the inline command with `${CLAUDE_PROJECT_DIR:-$PWD}`. The line currently contains:

```
... && { mkdir -p \"${CLAUDE_PROJECT_DIR}/.orbit\"; printf '[%s] EVT=MESSAGE %s\\n' \"$(date '+%F %T')\" \"$i\" >> \"${CLAUDE_PROJECT_DIR}/.orbit/usage-detect.log\"; }; exit 0
```

Change BOTH `${CLAUDE_PROJECT_DIR}/.orbit` to `${CLAUDE_PROJECT_DIR:-$PWD}/.orbit`. The guard `[ -f \"${CLAUDE_PROJECT_DIR:-$PWD}/.orbit/config\" ]` already uses this form — after the edit all three references match. Leave every escape (`\"`, `\\n`) byte-identical; only the two `}` → `:-$PWD}` insertions change.

- [ ] **Step 4: Validate JSON is still well-formed**

Run: `python3 -c "import json; json.load(open('plugins/orbit/hooks/hooks.json')); print('valid json')"`
Expected: `valid json`

- [ ] **Step 5: Run test to verify it passes**

Run: `bash tests/test-context-guard.sh`
Expected: `context-guard: 23 passed, 0 failed` (21 base + Task1 + Task2).

- [ ] **Step 6: Verify the existing guard-marker static tests still pass**

`test-static.sh` has T-GUARD (line 432) and T-NOWRITE (line 469) which scan `hooks.json` inline commands for the `.orbit/config` test marker and that they don't *write* config. The edit preserves the `.orbit/config` guard string and does not add a config write.

Run: `bash tests/test-static.sh | tail -1`
Expected: `70 passed, 0 failed`.

- [ ] **Step 7: Full-suite regression + domain purity**

Run: `for t in tests/*.sh; do bash "$t" | tail -1; done`
Expected total: 23 + 16 + 15 + 70 = 124 passed, 0 failed.
Run: `grep -riE 'oremi|오르미|orbit-dev' plugins/orbit/hooks/`
Expected: no output.

- [ ] **Step 8: Commit Group A (product hardening)**

```bash
git checkout -b cleanup/shell-hardening
git add plugins/orbit/hooks/session-log.sh plugins/orbit/hooks/hooks.json tests/test-context-guard.sh
git commit -m "fix: align hook CLAUDE_PROJECT_DIR fallbacks with is_orbit_context guard

session-log.sh:7 and hooks.json MessageDisplay used bare \${CLAUDE_PROJECT_DIR};
the orbit-context guard already falls back to pwd/PWD. Unset env now no-ops
cleanly instead of writing to /.orbit. Adds 2 regression cases."
```

> Branch first: repo is on `main`; commit/push only on a branch per project policy. If a branch already exists from an earlier task, skip the `checkout -b`.

---

### Task 3: Fix README hooks summary (line 461) to list all 6 events

**Files:**
- Modify: `README.md:461`

**Interfaces:** none (prose). Public-facing product doc.

- [ ] **Step 1: Read the current line in context**

Run: `sed -n '457,463p' README.md`
Current line 461:
```
└── 훅: SubagentStop(품질 게이트) · SubagentStart(뷰어 · L1 스킬 주입) · 사용량 자동재개
```
This omits `Stop`, `Notification`, `MessageDisplay` and labels only 3 groups.

- [ ] **Step 2: Replace with an accurate-but-concise summary**

The actual 6 events (from `hooks.json`): `Stop` (session-log), `Notification` (usage-detect), `MessageDisplay` (usage-limit detect), `UserPromptSubmit` (resume-inject), `SubagentStop` (quality-gate + notify-done), `SubagentStart` (viewer-attach + skill-consideration).

Replace line 461 with (keeps README tone — single tree leaf, grouped by purpose):

```
└── 훅(6 이벤트): SubagentStop(품질 게이트) · SubagentStart(뷰어 · L1 스킬 주입) · UserPromptSubmit(세션 재개) · Stop(세션 로그) · Notification·MessageDisplay(사용량 자동감지)
```

- [ ] **Step 3: Verify the claim matches hooks.json**

Run: `python3 -c "import json; print(sorted(json.load(open('plugins/orbit/hooks/hooks.json'))['hooks'].keys()))"`
Expected: `['MessageDisplay', 'Notification', 'Stop', 'SubagentStart', 'SubagentStop', 'UserPromptSubmit']` — all 6 now named in the README line.

- [ ] **Step 4: Domain purity check on README change**

Run: `git diff README.md | grep -iE 'oremi|오르미|orbit-dev'`
Expected: no output. (README may legitimately mention `orbit-base` in migration notes elsewhere — do NOT touch those; only line 461 changes here.)

- [ ] **Step 5: Commit Group B (README accuracy)**

```bash
git add README.md
git commit -m "docs: README hook summary list all 6 events (Stop/Notification/MessageDisplay added)"
```

---

### Task 4: plugin.json `skills` key — record NO-CHANGE decision

**Files:** none modified. Decision-recording task only.

**Interfaces:** none.

- [ ] **Step 1: Confirm the asymmetry still holds**

Run:
```bash
python3 -c "import json; print('claude has skills:', 'skills' in json.load(open('plugins/orbit/.claude-plugin/plugin.json')))"
python3 -c "import json; print('codex has skills:', 'skills' in json.load(open('plugins/orbit/.codex-plugin/plugin.json')))"
```
Expected: `claude has skills: False`, `codex has skills: True`.

- [ ] **Step 2: Confirm Claude auto-discovers skills (no manifest key needed)**

Run: `ls plugins/orbit/skills/`
Expected: skill directories present (e.g. `using-orbit/`, `skillify/`). Claude Code auto-discovers these by convention (project memory `orbit_plugin_discovery`; `roadmap.md:47` adjudicated this asymmetry as a known non-issue).

- [ ] **Step 3: Record the decision — DO NOT edit the manifest**

**Decision:** Leave `plugins/orbit/.claude-plugin/plugin.json` unchanged. Adding `"skills": "./skills/"` is inert for Claude (convention auto-discovery already covers it) and would imply a non-convention loader. The per-runtime manifest asymmetry IS the consistency baseline. No commit for this task.

> This step produces a one-line note for the Leader's report, not a file change. If the Leader/critic later wants the rationale persisted, the destination is project memory (`orbit_plugin_discovery`), not the manifest.

---

## Group CD — Doc Cleanup (NOT PUSHED)

> **Push boundary:** Everything below is committed on the same branch but the user directed that the doc-cleanup portion does not need pushing. Keep these commits separate from Tasks 1–3 so they can be left local or dropped without touching product hardening.

### Task 5: Delete stale `docs/smoke-results.md`

**Files:**
- Delete: `docs/smoke-results.md`

**Interfaces:** none functional.

- [ ] **Step 1: Confirm it is unreferenced as a navigational link**

Run: `grep -rn "smoke-results" --include="*.md" --include="*.sh" . | grep -v "docs/smoke-results.md:"`
Expected: only prose NIT mentions in `roadmap.md:47`, `plan-rwv-install-fixes.md:42,288` — no functional/navigational link. (Verified in discovery.)

- [ ] **Step 2: Confirm it is the stale dated snapshot, not live**

Run: `grep -c "orbit-base" docs/smoke-results.md`
Expected: ≥ 14 (pre-rename paths). This file is a 2026-06-18 QA snapshot superseded by the v1.0.0 rename.

> **Scope note:** The user's scope item C offered "update paths to `plugins/orbit/`". Discovery shows the entire file is a dated, one-time QA record full of pre-rename assertions — patching paths would resurrect a stale snapshot as if current. **DELETE is the correct, conservative call** for a dev-only dated record. If the Leader prefers preservation, the fallback (Step 3-ALT) moves it to `.planning/archive/` instead — choose one.

- [ ] **Step 3: Delete the file**

```bash
git rm docs/smoke-results.md
```

(3-ALT fallback, only if Leader chooses preserve-not-delete: `mkdir -p .planning/archive && git mv docs/smoke-results.md .planning/archive/`)

- [ ] **Step 4: Verify no dangling reference now breaks**

Run: `grep -rn "smoke-results.md" --include="*.md" . | grep -v "\.planning/archive"`
Expected: only the prose NIT lines in roadmap/old-plans (acceptable — they are historical mentions, not links). No README or active doc references it.

- [ ] **Step 5: Do NOT commit yet** — batch with Tasks 6–7 (Group CD commit).

---

### Task 6: Harden `setup-orbit-dev.sh` + fix stale comments

**Files:**
- Modify: `setup-orbit-dev.sh:19` (`set -e` → `set -euo pipefail`)
- Modify: `setup-orbit-dev.sh:17` (comment: `auto-attach.sh` → `viewer-attach.sh`)
- Modify: `setup-orbit-dev.sh:140,153,154` (comments/echo: `_team/attach-view.sh` → `plugins/orbit/scripts/attach-view.sh`; `auto-attach.sh` → `viewer-attach.sh`)

**Interfaces:** dev-only tmux launcher; no test-suite coverage (verified: not in `test-static.sh` bash-n list). Verify by manual parse.

- [ ] **Step 1: Audit for `set -u` regressions BEFORE flipping the flag**

Run: `grep -nE '\$\{?[A-Za-z_][A-Za-z0-9_]*' setup-orbit-dev.sh | grep -vE ':-|\$\{#|\$\(|MISSING\[@\]'`
Review output: every plain `$VAR` must be guaranteed-set before use. Known-safe (verified in discovery): `$claude_bin` (assigned just above use), `$agent_name`/`$2` use `:-`, `${MISSING[@]}` is guarded by `${#MISSING[@]} -gt 0` and iterated only when non-empty, color vars are literals. No unguarded read of an external/optional var found.

- [ ] **Step 2: Flip the safety flag**

Change `setup-orbit-dev.sh:19`:
```bash
set -euo pipefail
```
(was `set -e`)

- [ ] **Step 3: Verify the script still parses (syntax + unset-var dry check)**

Run: `bash -n setup-orbit-dev.sh && echo "syntax OK"`
Expected: `syntax OK`.

Then a guarded dry-run of just the early variable block to catch `set -u` faults (the script's real body needs tmux/claude, so do not run it fully):
```bash
bash -uo pipefail -c 'GREEN=""; CYAN=""; YELLOW=""; RED=""; NC=""; SESSION="orbit-dev"; PROJECT="$HOME/Project/orbit"; NOTIF_LOG="$PROJECT/.planning/notifications.log"; MISSING=(); echo "early block OK with set -u"'
```
Expected: `early block OK with set -u`. (Confirms the top-level variable initialization is `set -u`-clean.)

- [ ] **Step 4: Fix stale comment at line 17**

Change `setup-orbit-dev.sh:17`:
```bash
#   - SubagentStart 훅(viewer-attach.sh)이 뷰어 팬(1)에 라이브 렌더를 자동 연결.
```
(was: `auto-attach.sh`)

- [ ] **Step 5: Fix stale path/name references at lines 140, 153, 154**

Line 140 (the heredoc-ish printf for pane 1 waiting message) currently says `_team/attach-view.sh 1 <라벨> <agentId>`. Change to:
```
수동 연결: plugins/orbit/scripts/attach-view.sh 1 <라벨> <agentId>
```

Line 153:
```bash
echo "  · 라이브 뷰: SubagentStart 훅(viewer-attach.sh)이 뷰어(pane 1)에 자동 연결."
```
(was `auto-attach.sh`)

Line 154:
```bash
echo "      수동 연결: plugins/orbit/scripts/attach-view.sh 1 <라벨> <agentId>"
```
(was `_team/attach-view.sh`)

- [ ] **Step 6: Confirm no stale tokens remain**

Run: `grep -nE '_team/|auto-attach\.sh' setup-orbit-dev.sh`
Expected: no output.

- [ ] **Step 7: Re-verify syntax after comment edits**

Run: `bash -n setup-orbit-dev.sh && echo OK`
Expected: `OK`. (setup-orbit-dev.sh is dev-only and NOT under `plugins/orbit/`, so the domain-purity grep does not apply — but it does reference `$HOME/Project/orbit`, which is acceptable in a dev-only script and must NOT be propagated to any product file.)

- [ ] **Step 8: Do NOT commit yet** — batch with Task 7 (Group CD commit).

---

### Task 7: Delete superseded/rejected design & plan docs

**Files:**
- Delete: `docs/2026-06-18-team-framework-packaging-design.md`
- Delete: `docs/2026-06-18-team-framework-packaging-plan.md`
- Delete: `.planning/plans/2026-06-19-OMC-8-security-reviewer.md`

**Interfaces:** none functional. All verified unreferenced-as-links in discovery.

- [ ] **Step 1: Confirm the two packaging docs are superseded and cross-ref only each other**

Run: `grep -rln "team-framework-packaging" --include="*.md" . | grep -v "^./docs/2026-06-18-team-framework-packaging"`
Expected: hits in `plan-rename-orbit.md` (labels them "superseded two-plugin design") and `plan-M3.md` (out-of-scope example reference) — no active navigational dependency. The two files reference each other (self-contained pair); deleting both resolves the cross-ref.

- [ ] **Step 2: Confirm the rejected OMC-8 plan is unreferenced**

Run: `grep -rln "OMC-8-security-reviewer" --include="*.md" .`
Expected: no output (only the file itself, excluded). `roadmap.md:110` references the ADOPTED `OMC-8-security-deep-mode.md`, not this rejected `-security-reviewer.md`. (Verified: the security-reviewer agent was explicitly rejected in favor of reviewer ③ deep-mode — project memory `orbit_security_deepmode`.)

- [ ] **Step 3: Delete the three files**

```bash
git rm docs/2026-06-18-team-framework-packaging-design.md \
       docs/2026-06-18-team-framework-packaging-plan.md \
       .planning/plans/2026-06-19-OMC-8-security-reviewer.md
```

- [ ] **Step 4: Verify no active doc links break**

Run: `grep -rn "team-framework-packaging\|OMC-8-security-reviewer" --include="*.md" .`
Expected: only historical prose mentions in completed-plan files (`plan-rename-orbit.md`, `plan-M3.md`) — these are dated records describing past state, not live links. README and active roadmap pointer are clean.

- [ ] **Step 5: Check if `docs/` is now empty**

Run: `ls docs/`
Expected: after Task 5 (smoke-results) + Task 7 (2 packaging docs) deletions, `docs/` may be empty. If empty, `git` will have already removed it on the deletes (git does not track empty dirs). No explicit `rmdir` needed; note the state in the report.

- [ ] **Step 6: Commit Group CD (doc cleanup) — separate from Group AB**

```bash
git add -A setup-orbit-dev.sh
git commit -m "chore: harden setup-orbit-dev.sh (set -euo pipefail) + fix stale path/name comments"
git commit -m "docs: remove stale/superseded internal docs (smoke-results, 2-plugin packaging, rejected OMC-8 plan)" \
  -- docs/smoke-results.md docs/2026-06-18-team-framework-packaging-design.md \
     docs/2026-06-18-team-framework-packaging-plan.md \
     .planning/plans/2026-06-19-OMC-8-security-reviewer.md
```

> The deletions were staged via `git rm` in Tasks 5 & 7; the second commit records them. Two CD commits (hardening vs deletion) keep concerns separate. **Do NOT push these CD commits** per user directive — only Group AB (Tasks 1–3) is push-bound.

- [ ] **Step 7: Note remaining archive candidates (NO action — report only)**

Discovery flagged ~22 additional completed-plan/spike files in `.planning/plans/` and 3 loose completed files in `.planning/` as *archive candidates* (move to `.planning/archive/`, not delete — they hold historical value and are referenced by roadmap `[x]` records). **This plan does NOT touch them** (out of approved scope: "2번 전부 + 불필요 문서 식별" = the enumerated A–D items). List them in the completion report so the Leader can decide on a future archival pass.

---

## Final Verification (run after all tasks)

- [ ] **V1: Full test suite GREEN with new cases**

Run: `for t in tests/*.sh; do bash "$t" | tail -1; done`
Expected: `23 + 16 + 15 + 70 = 124 passed, 0 failed` (122 baseline + 2 new context-guard cases).

- [ ] **V2: Domain purity across product**

Run: `grep -riE 'oremi|오르미|orbit-dev' plugins/orbit/`
Expected: no output (exit 1).

- [ ] **V3: JSON validity**

Run: `python3 -c "import json; json.load(open('plugins/orbit/hooks/hooks.json')); json.load(open('plugins/orbit/.claude-plugin/plugin.json')); print('OK')"`
Expected: `OK`.

- [ ] **V4: Commit/push boundary respected**

Run: `git log --oneline main..HEAD`
Expected: Group AB commits (hooks fix, README) are present and push-eligible; Group CD commits (setup hardening, doc deletion) are present but flagged not-to-push. Confirm no commit mixes `plugins/orbit/` product files with `docs/` deletions.

---

## Self-Review (architect)

**Spec coverage:**
- A1 session-log.sh:7 → Task 1 ✓
- A2 hooks.json:30 → Task 2 ✓
- B3 README:461 → Task 3 ✓
- B4 plugin.json skills key → Task 4 (decision: no-change, with verified rationale) ✓
- C5 smoke-results.md → Task 5 (DELETE, with patch-fallback noted) ✓
- C6 setup-orbit-dev.sh → Task 6 (flag + comment fixes, regression-audited) ✓
- D7 dead-doc identification → Task 7 (3 deletes) + discovery table + archive-candidate list in Step 7 ✓

**Placeholder scan:** No TBD/TODO/"handle edge cases"/"similar to Task N" — every code/command step shows exact content and expected output. ✓

**Type/name consistency:** Test helper names (`ok`, `bad`, `$ORBITP`, `$PLUGIN_ROOT`, `$HOOKS`, `$MD_CMD`) match existing `test-context-guard.sh` definitions. Fallback forms `${CLAUDE_PROJECT_DIR:-$(pwd)}` (session-log, matching its sourced guard) and `${CLAUDE_PROJECT_DIR:-$PWD}` (hooks.json, matching its inline guard) are intentionally different to mirror each file's existing guard form — not an inconsistency. ✓

**Constraints honored:** Commit separation (AB vs CD), push boundary, domain purity gate, 122→124 test baseline, no `Co-Authored-By`. ✓
