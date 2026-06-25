# RENAME-1: Plugin Install Name `orbit-base` → `orbit` Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Rename the distributable plugin's install identifier from `orbit-base` to `orbit` (and move `plugins/orbit-base/` → `plugins/orbit/`) across every manifest, script, hook gate, and document, so end-users run `/plugin install orbit` — while keeping the repo/marketplace identifier `memoriterx/Orbit` unchanged.

**Architecture:** This is a **rename + directory-move** change. The plugin's install identity is the `name` field in `plugins/<dir>/.claude-plugin/plugin.json` (per project memory `orbit_plugin_discovery.md`: Claude Code auto-discovers by convention dir and identifies by `name`). The change has four surfaces: (1) the directory `plugins/orbit-base/` → `plugins/orbit/` via `git mv` — **Task 1 is a pure `git mv` commit with no content change**, so `git log --follow` history-tracking stays robust; (2) four manifest `name` fields **and** the marketplace `source` path, all changed together in **Task 4** (the atomic rename commit); (3) the SubagentStop domain-purity gate's hardcoded grep path; (4) install-command and path prose in scripts and docs. Repo identifier `memoriterx/Orbit` and marketplace `name` (`orbit-marketplace`) are **invariant**.

**Tech Stack:** bash scripts, JSON manifests (`.claude-plugin/`, `.codex-plugin/`, `gemini-extension.json`, `marketplace.json`), markdown agent/skill/command prompts, Claude Code `hooks.json` (SubagentStop), `git mv`.

## Global Constraints

- **Read-this-before-starting (concurrency):** A separate **v0.6.3 release builder runs concurrently and owns git**. This rename build starts **only after v0.6.3 is published, critic gate passes, and Plan Approval is granted**. Do not begin while the v0.6.3 builder holds the working tree. (Plan-time constraint; the executing builder confirms v0.6.3 is shipped before Task 1.)
- **Repo / marketplace identifiers are invariant:** `memoriterx/Orbit` (repo, marketplace add target) and `orbit-marketplace` (marketplace `name`) **must not change**. Only the *plugin* name and its directory change. Verify post-change: `grep -rn 'memoriterx/Orbit' .` count is unchanged; `orbit-marketplace` still present.
- **Domain purity is preserved through the move:** after the directory move, `grep -riE 'oremi|orbit-dev' plugins/orbit/` returns 0 hits; slots (`{{...}}`) stay slots. The SubagentStop gate's grep path **must be updated to `plugins/orbit/`** or the gate silently stops protecting the renamed directory.
- **Module boundary (distributable vs dev-meta):** distributable changes (`plugins/orbit/`, top-level `setup-orbit.sh`, `README.md`, `CHANGELOG.md`, `.claude-plugin/marketplace.json`) and dev-team-meta changes (`.claude/`, `.planning/`) go in **separate commit groups** — never mixed in one commit.
- **Historical references are intentionally preserved:** past GitHub Release notes (v0.2–v0.6.3) and CHANGELOG entries already published reference `orbit-base`. These are **historical facts — do not retroactively edit them**. New CHANGELOG/migration text is *additive*. Post-rename `grep -rn 'orbit-base' .` is expected to be **non-zero only for these intentional historical residues**, enumerated in Task 8.
- **SemVer:** the install identifier is a public contract; changing it is a **breaking change**. This plan recommends a **MAJOR bump to `1.0.0`** (decision recorded as ADR-RENAME-1 in Task 0; final call belongs to the user at Plan Approval). All `version` fields move together to the same value.
- **No alias assumed:** unless claude-code-guide (leader-routed) confirms Claude Code marketplace supports a rename-alias / old-name redirect, treat this as a **hard break**: existing `orbit-base` installs keep working locally but receive no further updates under the old name; users must `/plugin uninstall orbit-base` then `/plugin install orbit`. A migration note ships in README + CHANGELOG (Task 7).
- **Static-verification limitation (explicit):** every verification gate in this plan is **static** — `grep`, `python3 -m json.tool` (JSON validity), `bash -n` (shell parse), and a live local execution of the SubagentStop gate command. **These prove the repository is internally consistent; they do NOT prove that `/plugin install orbit` resolves on the live marketplace.** Live install resolution depends on the renamed plugin being **published** (release pushed, marketplace index served), which **cannot be exercised from this working tree**. "New install works" is therefore **out of scope for this build's static gates** and is carved out as a separate follow-up (see "Post-Build Follow-Up (out of static scope)" below) executed as Triple Crown ② (behavior). **Do not declare "new install works" on the basis of the static gates alone.**

---

## Pre-Flight: Discovery Findings (blast-radius map)

The executing builder must treat this section as the authoritative inventory. Every `orbit-base` occurrence found by `grep -rn 'orbit-base' .` (excluding `.git/`) at plan time, classified:

**(a) Plugin identifier — MUST change to `orbit`:**
- `plugins/orbit-base/.claude-plugin/plugin.json:2` — `"name": "orbit-base"`
- `plugins/orbit-base/.codex-plugin/plugin.json:2` — `"name": "orbit-base"`
- `plugins/orbit-base/gemini-extension.json:2` — `"name": "orbit-base"`
- `.claude-plugin/marketplace.json:10` — plugin `"name": "orbit-base"`
- `setup-orbit.sh` (bundled, `plugins/orbit-base/scripts/setup-orbit.sh`) lines 141,142,145,154,155,156,164,182,184,185,187 — `claude plugin list/install/update orbit-base`, user-facing `/plugin install orbit-base`
- `README.md:157,184,188,270,271,290,291,323,325` — install command + skill-source column + troubleshooting

**(b) Directory path `plugins/orbit-base/` — MUST move (`git mv`) to `plugins/orbit/`, then update every referrer:**
- `.claude-plugin/marketplace.json:13` — `"source": "./plugins/orbit-base"` (repo-relative; moves with dir)
- `setup-orbit.sh:14` (top-level wrapper) — `BUNDLED="$SCRIPT_DIR/plugins/orbit-base/scripts/setup-orbit.sh"`
- `.claude/settings.json:50` — **SubagentStop gate**: `find plugins/orbit-base -name '*.sh'`, `find plugins/orbit-base -name '*.json'`, and `grep -r 'oremi\|Oremi' plugins/orbit-base/` (domain-purity gate path — **critical**)
- `README.md:367,390` — structure prose, skill reference paths

**(c) Descriptive prose — change for accuracy (context-dependent):**
- `CHANGELOG.md:3` — "All notable changes to orbit-base are documented" → "to orbit" (header prose, not a historical entry)
- `README.md:387` — "### orbit-base 구성" heading

**(c′) User-facing actionable instruction — HIGH change priority (not mere prose):**
- `plugins/orbit-base/commands/orbit-init.md:46,47` — the `export CLAUDE_PLUGIN_ROOT=<…orbit-base…>` hint and the install-path hint `~/.claude/plugins/.../orbit-base 하위입니다` are **instructions the user copies and runs**, not descriptive prose. Because the install dir is now `name`-derived (`orbit`), leaving `orbit-base` here makes the user `export` a path to a **non-existent directory** → `/orbit-init` fails. Elevated above class (c): verified explicitly in Task 5 Step 3.

**(d) Internal dev references — ACTIVE dev operating docs (dev-meta commit group), MUST change:**

> **Class-wide sweep methodology (resolves critic MAJOR A — done by CLASS, not by file):** the active dev surface is defined as the **set** `{ root CLAUDE.md, all of .claude/, .planning/roadmap.md, .planning/ active scripts (*.sh, *.py) }`. A full `grep -rn 'orbit-base'` over that exact set was run; **every** hit below is enumerated so no same-class file is missed again. The `.planning/` *plan/spike documents* (both `.planning/plans/*` and the loose `.planning/2026-06-18-*.md`) are **NOT** active operating docs — they are completed/archived records → class (e). Verified: `.planning/resume-inject.py` and `.planning/usage-detect.py` have **0** hits (no action).

Active-surface hits (all must reach 0):
- **`CLAUDE.md` (root) — 5 hits, all active:**
  - `:13` "orbit 개발팀은 **orbit-base 에이전트**(`.claude/agents/`)를 채택" → the framework's agent set is now `orbit` → "orbit 에이전트"
  - `:20` "`plugins/orbit-base/` = 배포 제품 …" → `plugins/orbit/` (the `.claude/` vs `plugins/` distinction block — names the live dir)
  - `:45` "`plugins/orbit-base/` 내 에이전트·스킬·템플릿 …" (도메인 순수성 규칙 prose) → `plugins/orbit/`
  - `:50` "`grep -r 'oremi|Oremi' plugins/orbit-base/  # 0건이어야 함`" (the documented domain-purity gate command) → `plugins/orbit/`
  - `:59` "배포물(`plugins/orbit-base/`)과 개발 환경 … 별도 커밋" (commit-rule prose) → `plugins/orbit/`
- **`.claude/settings.json:50`** — SubagentStop gate (3 hardcoded paths) — handled in **Task 2** (its own critical task), not Task 8.
- **`.claude/agents/reviewer.md:18,49`** — domain-purity grep path
- **`.claude/agents/architect.md:18,30,56,88`** — domain-purity wording + grep path
- **`.claude/agents/builder.md:52,59,85`** — domain-purity grep path
- **`.claude/agents/leader.md:27,63`** — PRODUCT_PATHS forbidden-write list + cross-ref pointer
- **`.planning/roadmap.md` — 2 active hits (the other 2 are residue, see (e)):**
  - `:32` cites `plugins/orbit-base/commands/orbit-init.md:34` as a path inside an **open/active** roadmap item → `plugins/orbit/commands/orbit-init.md:34`
  - `:58` active backlog **section heading** "### OMC 흡수 — orbit-base 개선 4건" → "orbit 개선 4건"
- **`.planning/verify-autonomous-mode.sh:4`** — `BASE="plugins/orbit-base"`

**(e) Intentional residue — DO NOT change (historical / superseded / completed records):**
- `CHANGELOG.md` published version entries that name `orbit-base` as the shipped artifact at that version (historical fact).
- `docs/2026-06-18-team-framework-packaging-design.md` and `-plan.md` — the **superseded two-plugin design** (`orbit-base` + `orbit-web-dev`); historical design records. Leave as-is (optional "superseded" banner — Task 7, optional).
- `docs/smoke-results.md` — a dated QA record of a past run. Historical.
- **`.planning/roadmap.md:114` and `:149`** — sentences *describing completed milestones* ("격리 temp 환경에서 orbit-base 설치·스캐폴딩 검증 … 배포 준비 완료", "M2 — OMC 흡수 … orbit-base 품질 게이트 통과 — 완료"). These narrate what was true at completion time → **residue, do not edit.** (This is the L32/L58 vs L114/L149 boundary critic flagged.)
- **All completed (`[x]`) plan/spike documents under `.planning/`** — both `.planning/plans/*.md` (e.g. `2026-06-18-*` … `2026-06-21-plan-rwv-install-fixes.md`, `2026-06-21-plan-docs-onboarding.md`) **and** the loose `.planning/2026-06-18-*.md` plan/spike files (`plan-optin-autonomous-mode.md`, `planner-agent-separation.md`, `spike-optin-autonomous-mode.md`). They reference paths as-of-authoring. Historical. **Do not edit.** (Generalized per critic MINOR C — the allow-list is now "any completed plan/spike record," not a date enumeration.)
- This plan file itself, `.planning/plans/2026-06-21-plan-rename-orbit.md` (discusses the rename).

**Non-issues confirmed at discovery (no action needed):**
- `plugins/orbit-base/hooks/hooks.json` — contains **no** hardcoded `orbit-base` or `plugins/` path (uses `${CLAUDE_PLUGIN_ROOT}`-relative resolution); transparent to the move. Verified: `grep -n 'orbit-base\|plugins/' hooks.json` → 0.
- `plugins/orbit-base/AGENTS.md` — a **relative symlink** to `CLAUDE.md` (`AGENTS.md -> CLAUDE.md`); survives `git mv` of the parent dir intact.

---

## Open Question for the Leader (route before/with critic gate)

**Marketplace rename/alias support.** Does Claude Code's marketplace support renaming a published plugin while preserving update continuity for users who installed it under the old name (an alias or `old-name → new-name` redirect)? This determines whether Task 7's migration strategy is "hard break + manual re-install note" (the conservative default this plan assumes) or "alias declared in marketplace.json (softer)." **Per hub-and-spoke, the architect cannot call claude-code-guide directly — the leader must route this question.** If the answer is "alias supported," the leader returns it and the architect adds an alias sub-task to Task 4; if "no alias," the plan proceeds as written (hard break). This plan is **complete and executable under the conservative hard-break default**; the alias answer can only soften, never block.

---

### Task 0: Record the rename ADR and confirm the version target

**Files:**
- Modify: `.planning/roadmap.md` (RENAME-1 entry — append ADR pointer; dev-meta)
- Reference only: project memory (a memory entry is promoted by the leader after completion, not written here)

This task is decision-recording only; no distributable file changes.

- [ ] **Step 1: Confirm the version target with the recorded recommendation**

The recommendation is **MAJOR → `1.0.0`**: changing the install identifier breaks the public install contract (`/plugin install orbit-base` stops resolving to the maintained plugin). Under SemVer a breaking change to a published, depended-upon identifier is a major bump. The build proceeds **on top of the shipped v0.6.3**. Record this as ADR-RENAME-1 with the rationale and the rejected alternative (minor bump — rejected because a name change is not backward-compatible). The final version value is the user's call at Plan Approval; if the user prefers to defer 1.0.0, the fallback is `0.7.0` (still signals a notable, non-patch change). **All `version` fields in Task 4 use whatever value is chosen here — keep them identical.**

**ADR-RENAME-1 — why now, why this rename (timing rationale; resolves critic recommendation #4):** The current user base is **effectively zero** — orbit is pre-1.0 and used only by its own dev team (dogfood). This makes *now* the **lowest-cost window** to take a permanent breaking change to the install identifier: there is no installed third-party base to strand. Every later release accretes users who would each pay the uninstall/reinstall migration cost, so deferring the rename strictly raises its blast radius. The rename itself is justified because the `-base` suffix promises a sibling-plugin tier (a `-base` + presets family) that **does not exist and is not planned** — orbit's extensibility is delivered through **domain slots** (`{{...}}` filled by each project's CLAUDE.md), not through sibling preset plugins. So `-base` is a misleading affordance; `/plugin install orbit` is both cleaner and more honest about the architecture. Record this paragraph verbatim in the ADR.

- [ ] **Step 2: Verify no work has begun on distributable files**

Run: `git -C /Users/dh/Project/orbit status --porcelain plugins/ setup-orbit.sh README.md .claude-plugin/`
Expected: clean (empty) for these paths — confirms the v0.6.3 builder has released and the tree is free. If not clean, **stop and report to leader** (concurrency constraint violated).

- [ ] **Step 3: Commit the ADR pointer (dev-meta commit group)**

```bash
git add .planning/roadmap.md
git commit -m "docs: record ADR-RENAME-1 (plugin name orbit-base→orbit, version target)"
```

---

### Task 1: Move the plugin directory — pure `git mv` (distributable)

**Files:**
- Move: `plugins/orbit-base/` → `plugins/orbit/` (entire tree, via `git mv` — **content-only-unchanged move; no other file touched in this commit**)

**Interfaces:**
- Produces: the canonical new directory path `plugins/orbit/` that every later task references. The relative symlink `plugins/orbit/AGENTS.md -> CLAUDE.md` must remain valid after the move.

**Why pure `git mv` (resolves critic recommendation #6):** keeping this commit to *only* the rename of paths (no marketplace-source edit, no manifest edit) keeps `git log --follow plugins/orbit/...` robust — git records a clean rename rather than a rename-plus-modify. The marketplace `source` path edit moves to **Task 4**, where it lands together with the manifest `name` change as the single atomic rename commit. Between Task 1 and Task 4 the marketplace `source` still reads `./plugins/orbit-base` (a dangling path) — this is acceptable because **the rename is not published until the whole sequence completes**; the working tree is internally consistent again by end of Task 4, and nothing installs from this tree mid-sequence.

- [ ] **Step 1: Move the directory with git**

```bash
cd /Users/dh/Project/orbit
git mv plugins/orbit-base plugins/orbit
```

- [ ] **Step 2: Verify the move preserved the tree and the symlink**

```bash
test -d plugins/orbit && test ! -d plugins/orbit-base && echo "DIR OK"
ls -l plugins/orbit/AGENTS.md   # must still show: AGENTS.md -> CLAUDE.md
readlink plugins/orbit/AGENTS.md   # must print: CLAUDE.md
find plugins/orbit -type f | wc -l   # must equal the pre-move count (40)
```
Expected: `DIR OK`, symlink target `CLAUDE.md`, file count `40`.

- [ ] **Step 3: Confirm the commit contains only renames (no content diffs)**

```bash
git add -A plugins/
git status --porcelain plugins/ | grep -vE '^R' && echo "WARNING: non-rename change staged" || echo "PURE RENAME OK"
```
Expected: `PURE RENAME OK` (every staged path under `plugins/` is a rename `R`, no `M`/`A`/`D`). If any non-rename appears, **unstage and investigate** — Task 1 must stay content-clean.

- [ ] **Step 4: Commit (distributable commit group — pure move)**

```bash
git commit -m "refactor: git mv plugins/orbit-base -> plugins/orbit (pure rename, no content change)"
```

---

### Task 2: Update the SubagentStop domain-purity gate path (dev-meta — critical)

**Files:**
- Modify: `.claude/settings.json:50` — SubagentStop hook command

**Why this task is isolated and high-priority:** the SubagentStop gate hardcodes `plugins/orbit-base` in three places (`find … *.sh`, `find … *.json`, `grep -r 'oremi\|Oremi' plugins/orbit-base/`). After Task 1's move, the gate now globs a **non-existent directory** and the domain-purity check passes vacuously (0 files scanned → 0 hits → no block) — silently disabling the guard. This must be fixed immediately after the move, before any builder edits land under `plugins/orbit/`.

- [ ] **Step 1: Read the current gate command**

Run: `grep -n 'plugins/orbit-base' .claude/settings.json`
Expected: one line (50) with three `plugins/orbit-base` substrings inside the SubagentStop command.

- [ ] **Step 2: Replace all three occurrences in that command**

In `.claude/settings.json`, within the SubagentStop hook command string, change every `plugins/orbit-base` to `plugins/orbit`. Specifically:
- `find plugins/orbit-base -name '*.sh'` → `find plugins/orbit -name '*.sh'`
- `find plugins/orbit-base -name '*.json'` → `find plugins/orbit -name '*.json'`
- `grep -r 'oremi\|Oremi' plugins/orbit-base/` → `grep -r 'oremi\|Oremi' plugins/orbit/`

(The block-reason message `plugins/orbit-base/ contains project-specific name` should also read `plugins/orbit/` for accuracy.)

- [ ] **Step 3: Verify JSON validity and that the path is gone**

```bash
python3 -m json.tool .claude/settings.json > /dev/null && echo "JSON OK"
grep -c 'plugins/orbit-base' .claude/settings.json   # must print 0
grep -c 'plugins/orbit ' .claude/settings.json       # >=1 (the find/grep now target the new dir)
```
Expected: `JSON OK`, first count `0`.

- [ ] **Step 4: Positive + negative gate test — EXECUTE the actual gate command (resolves critic BLOCKER #1)**

A manual `grep` against the new path does **not** prove the gate was fixed — it is a *separate* command and would pass even if `settings.json` were never edited. The only valid proof is to **extract the SubagentStop command string from `settings.json` and run it**, then assert it blocks on a planted violation (positive) and passes when clean (negative). This catches the build's central regression mode (gate globbing a dead path → vacuous pass).

```bash
cd /Users/dh/Project/orbit

# 1. Extract the SubagentStop hook command exactly as configured (no hand-copying).
GATE_CMD="$(python3 -c "
import json
cfg = json.load(open('.claude/settings.json'))
def walk(o):
    if isinstance(o, dict):
        if o.get('type')=='command' and 'command' in o and 'orbit' in o['command']:
            print(o['command']); return
        for v in o.values(): walk(v)
    elif isinstance(o, list):
        for v in o: walk(v)
walk(cfg)
")"
test -n "$GATE_CMD" && echo "GATE CMD EXTRACTED" || { echo "FAIL: could not extract gate command"; exit 1; }

# 2. NEGATIVE test — clean tree: gate must emit NO block decision (empty stdout / no 'block').
OUT_CLEAN="$(bash -c "$GATE_CMD" 2>&1)"
echo "$OUT_CLEAN" | grep -q '"decision":"block"' && echo "FAIL(neg): gate blocked a clean tree" || echo "NEG OK (no block on clean tree)"

# 3. POSITIVE test — plant a domain-purity violation under the NEW dir, re-run the SAME extracted command.
printf 'Oremi\n' > plugins/orbit/__probe_violation.md
OUT_DIRTY="$(bash -c "$GATE_CMD" 2>&1)"
echo "$OUT_DIRTY" | grep -q '"decision":"block"' && echo "POS OK (gate blocked on planted Oremi under plugins/orbit/)" || echo "FAIL(pos): gate did NOT block — it is still globbing the wrong path (VACUOUS)"

# 4. Clean up the probe — must leave the tree pristine.
rm -f plugins/orbit/__probe_violation.md
git status --porcelain plugins/orbit/__probe_violation.md | grep -q . && echo "FAIL: probe residue left" || echo "CLEANUP OK"
```
Expected: `GATE CMD EXTRACTED`, `NEG OK`, `POS OK`, `CLEANUP OK`. **If POS prints FAIL, the gate is still vacuous — the `settings.json` path edit (Step 2) did not take or missed one of the three hardcoded paths; do not proceed.** This positive/negative pair is the load-bearing proof that Task 2 actually re-armed the guard.

> **Branch-coverage note (critic MINOR B):** the `.md` probe exercises only the gate's **`grep` (domain-purity) branch** — it does not trigger the two `find … *.sh` / `find … *.json` branches. That residual is acceptable because **Step 3's `grep -c 'plugins/orbit-base' .claude/settings.json == 0` assertion already proves all THREE hardcoded paths were rewritten** (a single substring scan over the whole command string). So: Step 3 = "all three paths point at the new dir"; this probe = "the gate actually fires (non-vacuously) against the new dir." Together they cover both that the paths changed and that the change is live. (If stronger end-to-end coverage is ever wanted, plant a companion `__probe.sh` with a syntax error and a malformed `__probe.json` to drive the two `find` branches — not required here.)

> **Probe-safety note:** the probe file `plugins/orbit/__probe_violation.md` is created, asserted-on, and removed inside this one step; it is never staged or committed. The `__probe` name is distinctive for grep-based residue checks. If the run aborts mid-step, `rm -f plugins/orbit/__probe_violation.md` clears it.

- [ ] **Step 5: Commit (dev-meta commit group)**

```bash
git add .claude/settings.json
git commit -m "fix(dev): point SubagentStop domain-purity gate at plugins/orbit (post-rename)"
```

---

### Task 3: Update the top-level wrapper's bundled-script path (distributable)

**Files:**
- Modify: `setup-orbit.sh:7,14` (top-level wrapper)

- [ ] **Step 1: Write the failing check (path resolves)**

Before editing, confirm the wrapper currently points at the old (now-moved) path and would fail:
```bash
grep -n 'plugins/orbit-base' setup-orbit.sh   # shows line 14 -> stale path
test -f "$(cd "$(dirname setup-orbit.sh)" && pwd)/plugins/orbit-base/scripts/setup-orbit.sh" || echo "STALE PATH (expected before fix)"
```
Expected: line 14 prints; `STALE PATH (expected before fix)`.

- [ ] **Step 2: Fix the bundled path and the comment**

In `setup-orbit.sh`:
- Line 14: `BUNDLED="$SCRIPT_DIR/plugins/orbit-base/scripts/setup-orbit.sh"` → `BUNDLED="$SCRIPT_DIR/plugins/orbit/scripts/setup-orbit.sh"`
- Line 7 (comment prose): `# and run the bundled script via:` block mentions "install orbit-base as a Claude Code plugin" → change `orbit-base` to `orbit`.

- [ ] **Step 3: Verify the wrapper resolves**

```bash
bash -n setup-orbit.sh && echo "SYNTAX OK"
BUNDLED="$(cd "$(dirname setup-orbit.sh)" && pwd)/plugins/orbit/scripts/setup-orbit.sh"; test -f "$BUNDLED" && echo "BUNDLED RESOLVES"
grep -c 'plugins/orbit-base' setup-orbit.sh   # must print 0
```
Expected: `SYNTAX OK`, `BUNDLED RESOLVES`, count `0`.

- [ ] **Step 4: Commit (distributable commit group)**

```bash
git add setup-orbit.sh
git commit -m "fix: point top-level wrapper at plugins/orbit/scripts (post-rename)"
```

---

### Task 4: Rename the plugin identifier in all four manifests + bump version (distributable)

**Files:**
- Modify: `plugins/orbit/.claude-plugin/plugin.json:2` (`name`) + `:4` (`version`)
- Modify: `plugins/orbit/.codex-plugin/plugin.json:2` (`name`) + `:3` (`version`) + `:26` (`displayName "Orbit Base"`)
- Modify: `plugins/orbit/gemini-extension.json:2` (`name`) + `:4` (`version`)
- Modify: `.claude-plugin/marketplace.json:10` (`name`) + `:12` (`version`) + `:13` (`source` path — **moved here from Task 1 per #6**)

**Interfaces:**
- Consumes: the chosen version value from Task 0 (default `1.0.0`).
- Produces: the install identifier `orbit` — the user-facing `/plugin install orbit` target that Tasks 5–6 reference in scripts and docs. This is the commit where the working tree becomes **internally consistent again** (marketplace `source` now matches the moved dir AND the plugin `name` is `orbit`).

- [ ] **Step 1: Change `name` in the Claude manifest**

`plugins/orbit/.claude-plugin/plugin.json`: `"name": "orbit-base"` → `"name": "orbit"`; `"version": "0.6.3"` → `"version": "1.0.0"`.

- [ ] **Step 2: Change `name` + displayName in the Codex manifest**

`plugins/orbit/.codex-plugin/plugin.json`: `"name": "orbit-base"` → `"name": "orbit"`; `"version": "0.6.3"` → `"version": "1.0.0"`; `"displayName": "Orbit Base"` → `"displayName": "Orbit"` (the `-base` suffix no longer describes anything — keep the display name consistent with the new identity).

- [ ] **Step 3: Change `name` in the Gemini extension manifest**

`plugins/orbit/gemini-extension.json`: `"name": "orbit-base"` → `"name": "orbit"`; `"version": "0.6.3"` → `"version": "1.0.0"`.

- [ ] **Step 4: Change the plugin `name`, `version`, AND `source` in the marketplace manifest**

`.claude-plugin/marketplace.json`:
- line 10 — the **plugin** entry `"name": "orbit-base"` → `"name": "orbit"`
- line 12 — `"version": "0.6.3"` → `"version": "1.0.0"`
- line 13 — `"source": "./plugins/orbit-base"` → `"source": "./plugins/orbit"` (**this is the source-path edit moved out of Task 1 per #6** — it lands here so the dir move stays a pure rename and the source/name change is one atomic commit)

**Do NOT touch line 2 `"name": "orbit-marketplace"`** (marketplace identifier — invariant).

- [ ] **Step 5: Verify all four manifests are valid and consistent + source points at the moved dir**

```bash
for f in plugins/orbit/.claude-plugin/plugin.json plugins/orbit/.codex-plugin/plugin.json plugins/orbit/gemini-extension.json .claude-plugin/marketplace.json; do
  python3 -m json.tool "$f" > /dev/null && echo "OK $f" || echo "FAIL $f"
done
# the plugin name must be 'orbit' in all four, and orbit-base gone:
grep -rn '"name": "orbit-base"' plugins/orbit/ .claude-plugin/marketplace.json   # must print nothing
grep -rn '"name": "orbit"' plugins/orbit/ .claude-plugin/marketplace.json        # must print 4 lines
grep -n '"name": "orbit-marketplace"' .claude-plugin/marketplace.json            # must STILL print (invariant)
# source path now matches the moved dir, and resolves on disk:
grep -n '"source": "./plugins/orbit"' .claude-plugin/marketplace.json            # must print line 13
test -d ./plugins/orbit && echo "SOURCE RESOLVES"                                # the source dir exists
grep -c '"source": "./plugins/orbit-base"' .claude-plugin/marketplace.json       # must print 0 (no dangling source)
# version consistency:
grep -rn '"version": "1.0.0"' plugins/orbit/ .claude-plugin/marketplace.json     # must print 4 lines
```
Expected: 4× `OK`; first grep empty; second grep 4 lines; marketplace name present; source line present + `SOURCE RESOLVES`; dangling-source count `0`; 4× version lines.

- [ ] **Step 6: Commit (distributable commit group — the atomic rename)**

```bash
git add plugins/orbit/.claude-plugin/plugin.json plugins/orbit/.codex-plugin/plugin.json plugins/orbit/gemini-extension.json .claude-plugin/marketplace.json
git commit -m "feat!: rename plugin orbit-base -> orbit (name+source+version v1.0.0; BREAKING install identifier)"
```

---

### Task 5: Update install/update commands + prose in the bundled setup script (distributable)

**Files:**
- Modify: `plugins/orbit/scripts/setup-orbit.sh:141,142,145,154,155,156,164,182,184,185,187`
- Modify: `plugins/orbit/commands/orbit-init.md:46,47`

- [ ] **Step 1: Replace the install-identifier command strings**

In `plugins/orbit/scripts/setup-orbit.sh`, change every `orbit-base` to `orbit` in the plugin command surface:
- `claude plugin list … | grep -q "orbit-base"` → `grep -q "orbit"` (line 141)
- echo strings "OK orbit-base already installed" / "orbit-base not detected" (142, 145)
- comment "Step 2: install orbit-base" (154)
- `claude plugin install orbit-base --scope …` (155) and "OK orbit-base installed" (156)
- the manual-fallback hint `/plugin install orbit-base` (164)
- comment "Update orbit-base itself" (182)
- `claude plugin update orbit-base --scope …` (184), "OK orbit-base up-to-date" (185), "orbit-base update check failed" (187)

**Caution on line 141:** `grep -q "orbit"` will now also match an installed `orbit-marketplace` row if `plugin list` prints marketplace names. To keep the detection precise, use a word-boundary/anchored match: `grep -qw "orbit"` (matches the token `orbit` exactly, not `orbit-marketplace`). Apply `grep -qw "orbit"` on line 141.

- [ ] **Step 2: Replace the error-message prose in orbit-init**

In `plugins/orbit/commands/orbit-init.md` lines 46–47, change `orbit-base 플러그인 설치 디렉터리` → `orbit 플러그인 설치 디렉터리` and the path hint `~/.claude/plugins/.../orbit-base 하위입니다` → `~/.claude/plugins/.../orbit 하위입니다`.

- [ ] **Step 3: Verify the script and the precise-match guard**

```bash
bash -n plugins/orbit/scripts/setup-orbit.sh && echo "SYNTAX OK"
grep -c 'orbit-base' plugins/orbit/scripts/setup-orbit.sh   # must print 0
grep -c 'orbit-base' plugins/orbit/commands/orbit-init.md   # must print 0
grep -n 'grep -qw "orbit"' plugins/orbit/scripts/setup-orbit.sh   # must print (precise match guard present)
```
Expected: `SYNTAX OK`, both counts `0`, the `grep -qw` line present.

- [ ] **Step 4: Commit (distributable commit group)**

```bash
git add plugins/orbit/scripts/setup-orbit.sh plugins/orbit/commands/orbit-init.md
git commit -m "feat!: update bundled setup + orbit-init to install identifier 'orbit'"
```

---

### Task 6: Update README install/reference prose (distributable docs commit group)

**Files:**
- Modify: `README.md:157,184,188,270,271,290,291,323,325,367,387,390`
- Modify: `CHANGELOG.md:3` (header prose only — not a version entry)

- [ ] **Step 1: Replace install commands and identifier prose in README**

In `README.md`:
- `:157` install block `/plugin install orbit-base` → `/plugin install orbit`
- `:184` table cell "`orbit-base` 플러그인 설치 (위 3단계)" → "`orbit` 플러그인 설치 (위 3단계)"
- `:188` "처음엔 `orbit-base`만으로 충분합니다" → "`orbit`만으로 충분합니다"
- `:270,:271` skill-source column "`using-orbit` | orbit-base" / "`skillify` | orbit-base" → "orbit"
- `:290` troubleshooting "`orbit-base` 플러그인 미설치 …" and `/plugin install orbit-base` → `orbit`
- `:291` "`export CLAUDE_PLUGIN_ROOT=<orbit-base 플러그인 설치 경로>`" → `<orbit 플러그인 설치 경로>`
- `:323` "`orbit-base`가 설치돼 있는지 확인 … `orbit-base` 설치를 자동으로 시도" → `orbit`
- `:325` "`orbit-base`를 최신 버전으로 업데이트" → `orbit`

- [ ] **Step 2: Replace path-reference prose in README**

In `README.md`:
- `:367` skill-reference path `plugins/orbit-base/skills/using-orbit/references/codex-tools.md` → `plugins/orbit/...`
- `:387` heading "### orbit-base 구성" → "### orbit 구성"
- `:390` structure diagram label `orbit-base   ← 도메인 무관 골격` → `orbit   ← 도메인 무관 골격`

- [ ] **Step 3: Update the CHANGELOG header prose (not a version entry)**

In `CHANGELOG.md:3`: "All notable changes to orbit-base are documented in this file." → "All notable changes to orbit are documented in this file." **Do not touch any dated `## [x.y.z]` entry below** — those are historical and name the artifact as it shipped at that version.

- [ ] **Step 4: Verify README/CHANGELOG no longer carry the install identifier (except intentional)**

```bash
grep -n 'orbit-base' README.md       # expect 0 (README has no historical-residue requirement)
grep -n 'orbit-base' CHANGELOG.md     # expect ONLY the dated version-entry lines below line 3 (historical) — line 3 itself must be gone
```
Expected: README `0`; CHANGELOG line 3 gone, any remaining hits are dated historical entries only.

- [ ] **Step 5: Commit (distributable docs commit group)**

```bash
git add README.md CHANGELOG.md
git commit -m "docs: update install identifier to 'orbit' in README + CHANGELOG header"
```

---

### Task 7: Add the migration note + new CHANGELOG entry (distributable docs commit group)

**Files:**
- Modify: `CHANGELOG.md` (add new top entry)
- Modify: `README.md` (add a short migration callout near the install section, ~line 157)

**Interfaces:**
- Consumes: the version value from Task 0/Task 4 (default `1.0.0`); the alias answer from the Open-Question (if the leader returned "alias supported," add the alias note instead of the hard-break note).

- [ ] **Step 1: Add a new CHANGELOG entry with the BREAKING marker**

Add at the top of the entries section in `CHANGELOG.md` (above the current latest dated entry), using the chosen version and today's date:

```markdown
## [1.0.0] - 2026-06-21

### Changed
- **BREAKING:** the plugin install identifier is renamed `orbit-base` → `orbit`.
  Install now with `/plugin install orbit`. The directory `plugins/orbit-base/`
  moved to `plugins/orbit/`. The repository (`memoriterx/Orbit`) and marketplace
  name (`orbit-marketplace`) are unchanged.

### Migration
- Existing installs of `orbit-base` continue to function locally but no longer
  receive updates under the old name. To migrate:
  `/plugin uninstall orbit-base` then `/plugin install orbit`
  (the marketplace is already registered; no re-add needed).
```

Also add the matching link-reference line at the bottom of the file alongside the existing `[0.6.x]` link lines:
```markdown
[1.0.0]: https://github.com/memoriterx/Orbit/releases/tag/v1.0.0
```

- [ ] **Step 2: Add a short migration callout in README near the install block**

After the `/plugin install orbit` block (~line 157), add:
```markdown
> **기존 `orbit-base` 사용자:** 설치명이 `orbit`으로 변경되었습니다(v1.0.0).
> `/plugin uninstall orbit-base` 후 `/plugin install orbit`을 실행하세요.
> 마켓플레이스(`memoriterx/Orbit`)는 그대로이므로 재등록은 불필요합니다.
```

- [ ] **Step 3 (optional, low priority): Banner the superseded design docs**

If desired for clarity, prepend a one-line note to `docs/2026-06-18-team-framework-packaging-design.md` and `-plan.md`: `> NOTE (2026-06-21): superseded — the two-plugin design (orbit-base + orbit-web-dev) was abandoned; the framework ships a single plugin named 'orbit'.` This is documentation hygiene, not required for correctness. If skipped, these files remain intentional historical residue (Task 8 enumerates them).

- [ ] **Step 4: Verify CHANGELOG validity**

```bash
grep -n '## \[1.0.0\]' CHANGELOG.md && echo "ENTRY OK"
grep -n 'BREAKING' CHANGELOG.md && echo "BREAKING NOTED"
grep -n '\[1.0.0\]: https' CHANGELOG.md && echo "LINK OK"
```
Expected: all three print.

- [ ] **Step 5: Commit (distributable docs commit group)**

```bash
git add CHANGELOG.md README.md docs/2026-06-18-team-framework-packaging-*.md
git commit -m "docs: add v1.0.0 migration note (orbit-base->orbit hard-break guidance)"
```

---

### Task 8: Update dev-team meta references (dev-meta commit group)

**Files (full active-surface set from the class-wide sweep):**
- Modify: `CLAUDE.md` (root) — **5 active hits: lines 13, 20, 45, 50, 59**
- Modify: `.claude/agents/reviewer.md:18,49`
- Modify: `.claude/agents/architect.md:18,30,56,88`
- Modify: `.claude/agents/builder.md:52,59,85`
- Modify: `.claude/agents/leader.md:27,63`
- Modify: `.planning/roadmap.md:32,58` — **2 active hits** (L114/L149 are residue, untouched)
- Modify: `.planning/verify-autonomous-mode.sh:4`

> `.claude/settings.json` is **not** in this task — its gate is handled in Task 2. `.planning/roadmap.md` L114/L149 (completed-milestone narration) and all completed plan/spike records are class-(e) residue, untouched.

**Note:** these are dev-team operating docs/scripts that hardcode the old distributable name/path in their domain-purity grep commands, forbidden-write lists, dogfooding/commit prose, and active roadmap items. They must track the new name/path or they reference a dead directory.

- [ ] **Step 1: Update ALL FIVE active references in root CLAUDE.md**

In root `CLAUDE.md`:
- line 13 — "orbit 개발팀은 **orbit-base 에이전트**(`.claude/agents/`)를 채택" → "**orbit 에이전트**(`.claude/agents/`)를 채택"
- line 20 — "`plugins/orbit-base/` = **배포 제품** …" → "`plugins/orbit/` = **배포 제품** …"
- line 45 — "`plugins/orbit-base/` 내 에이전트·스킬·템플릿 …" → "`plugins/orbit/` 내 …"
- line 50 — the documented domain-purity gate command "`grep -r 'oremi|Oremi' plugins/orbit-base/  # 0건이어야 함`" → "`grep -r 'oremi|Oremi' plugins/orbit/  # 0건이어야 함`"
- line 59 — "배포물(`plugins/orbit-base/`)과 개발 환경 … 별도 커밋 권장" → "배포물(`plugins/orbit/`)과 …"

(All five are **active** instructions read every dev session; leaving any stale points the dev team — or the documented gate command — at a dead directory.)

- [ ] **Step 2: Update each agent's domain-purity grep path and forbidden-write list**

Replace `plugins/orbit-base/` with `plugins/orbit/` and the bare token `orbit-base` (where it names the distributable) with `orbit` in:
- `.claude/agents/reviewer.md` lines 18, 49 (grep paths)
- `.claude/agents/architect.md` lines 18, 30, 56, 88 (prose "orbit-base 에이전트·스킬" → "orbit ...", grep paths, `{{CONSISTENCY_LENS}}` path)
- `.claude/agents/builder.md` lines 52, 59, 85 (grep paths, `{{QUALITY_GATE_CMD}}` example path)
- `.claude/agents/leader.md` line 27 (PRODUCT_PATHS forbidden-write: `plugins/orbit-base/` → `plugins/orbit/`), line 63 (cross-ref pointer `plugins/orbit-base/agents/leader.md` → `plugins/orbit/agents/leader.md`)

- [ ] **Step 3: Update the two ACTIVE roadmap references (resolves critic MAJOR A)**

In `.planning/roadmap.md`:
- line 32 — the open/active roadmap item citing `plugins/orbit-base/commands/orbit-init.md:34` → `plugins/orbit/commands/orbit-init.md:34`
- line 58 — the active backlog section heading "### OMC 흡수 — orbit-base 개선 4건" → "### OMC 흡수 — orbit 개선 4건"

**Do NOT touch line 114 or line 149** — those narrate *completed* milestones (what was true at completion time) and are class-(e) residue. Editing them would falsify history.

- [ ] **Step 4: Update the autonomous-mode verify harness BASE path**

`.planning/verify-autonomous-mode.sh:4`: `BASE="plugins/orbit-base"` → `BASE="plugins/orbit"`.

- [ ] **Step 5: Verify dev-meta active references converged + residue preserved + harness parses**

```bash
# all active dev-meta paths gone:
grep -rn 'plugins/orbit-base' CLAUDE.md .claude/ .planning/verify-autonomous-mode.sh   # must print 0
grep -c 'orbit-base' CLAUDE.md   # must print 0 (all 5 active refs gone)
# roadmap: the 2 active refs gone, the 2 residue refs PRESERVED:
grep -n 'orbit-base' .planning/roadmap.md   # must print EXACTLY lines 114 and 149 (residue) — and NOT 32 or 58
bash -n .planning/verify-autonomous-mode.sh && echo "HARNESS SYNTAX OK"
```
Expected: first two counts `0`; roadmap grep shows **only** L114 + L149 (residue intact, active gone); `HARNESS SYNTAX OK`.

- [ ] **Step 6: Commit (dev-meta commit group)**

```bash
git add CLAUDE.md .claude/agents/reviewer.md .claude/agents/architect.md .claude/agents/builder.md .claude/agents/leader.md .planning/roadmap.md .planning/verify-autonomous-mode.sh
git commit -m "chore(dev): update dev-team meta refs (CLAUDE.md + agents + roadmap + harness) to plugins/orbit"
```

---

### Task 9: Full-repo convergence verification

**Files:** none (verification only)

- [ ] **Step 1: Confirm `orbit-base` has converged to intentional residue only**

```bash
cd /Users/dh/Project/orbit
grep -rn 'orbit-base' . --exclude-dir=.git
```
Expected output contains **only** these intentional-residue classes (Task pre-flight class (e)):
- dated `CHANGELOG.md` version entries below line 3 (historical),
- `docs/2026-06-18-team-framework-packaging-*.md` (superseded design, unless bannered in Task 7.3),
- `docs/smoke-results.md` (dated QA record),
- **any completed (`[x]`) plan/spike record under `.planning/`** — both `.planning/plans/*.md` and the loose `.planning/2026-06-18-*.md` plan/spike files (generalized per critic MINOR C — *not* a date enumeration; same-day 06-21 completed plans like `plan-rwv-install-fixes.md` and `plan-docs-onboarding.md` are covered),
- `.planning/roadmap.md` lines **114 and 149 only** (completed-milestone narration),
- this plan file `.planning/plans/2026-06-21-plan-rename-orbit.md` (which discusses the rename).

**Every other category — active manifests, scripts, gate, README install/reference prose, root `CLAUDE.md`, active roadmap items, and all dev-meta — must be 0.** Explicit per-file 0-convergence assertions for the active surfaces critic flagged (MAJOR #2 + MAJOR A):
```bash
grep -c 'orbit-base' CLAUDE.md   # must print 0 — root CLAUDE.md is ACTIVE (all 5 refs gone)
# roadmap: active refs gone, residue intact — must show EXACTLY L114 and L149:
grep -n 'orbit-base' .planning/roadmap.md   # must list only lines 114 and 149 (NOT 32, NOT 58)
# whole active dev surface, by class, in one assertion:
grep -rn 'orbit-base' CLAUDE.md .claude/ .planning/roadmap.md .planning/verify-autonomous-mode.sh .planning/*.py | grep -vE 'roadmap\.md:(114|149):' | head
# ^ expected: EMPTY (the only allowed hits are roadmap L114/L149, filtered out above)
```
If any active surface still shows `orbit-base` (i.e. the last command prints anything), fix and re-run before proceeding.

- [ ] **Step 2: Confirm invariants are intact**

```bash
grep -c 'memoriterx/Orbit' . -rn --exclude-dir=.git | head   # repo identifier present, unchanged in count vs pre-rename
grep -rn '"name": "orbit-marketplace"' .claude-plugin/marketplace.json   # marketplace name intact
grep -rn '"name": "orbit"' plugins/orbit/ .claude-plugin/marketplace.json | wc -l   # = 4 (the four manifests)
```
Expected: repo identifier present; marketplace name present; manifest-name count `4`.

- [ ] **Step 3: Confirm directory move + auto-discovery surface is consistent**

```bash
test -d plugins/orbit && test ! -d plugins/orbit-base && echo "DIR OK"
# the convention dirs Claude Code auto-discovers must all exist under the new path:
for d in agents commands skills hooks; do test -d plugins/orbit/$d && echo "OK plugins/orbit/$d"; done
test -f plugins/orbit/.claude-plugin/plugin.json && echo "MANIFEST OK"
readlink plugins/orbit/AGENTS.md   # must print CLAUDE.md (symlink survived move)
```
Expected: `DIR OK`, all four convention dirs `OK`, `MANIFEST OK`, symlink `CLAUDE.md`.

- [ ] **Step 4: Confirm all JSON manifests valid + all shell scripts parse**

```bash
for f in $(find plugins/orbit -name '*.json') .claude-plugin/marketplace.json; do python3 -m json.tool "$f" >/dev/null && echo "OK $f" || echo "FAIL $f"; done
for f in $(find plugins/orbit -name '*.sh') setup-orbit.sh .planning/verify-autonomous-mode.sh; do bash -n "$f" && echo "OK $f" || echo "FAIL $f"; done
```
Expected: all `OK`, no `FAIL`.

- [ ] **Step 5: Confirm the domain-purity gate is live on the new path (regression)**

```bash
grep -c 'plugins/orbit ' .claude/settings.json   # gate now globs the new dir (>=1)
grep -c 'plugins/orbit-base' .claude/settings.json   # 0 (no stale path)
grep -riE 'oremi|orbit-dev' plugins/orbit/ ; echo "purity exit=$?"   # 0 hits (exit 1 from grep = no match = pure)
```
Expected: gate-path count `>= 1`, stale-path count `0`, purity grep prints nothing (exit 1).

---

## Post-Build Follow-Up (out of static scope — resolves critic MAJOR #3)

The static gates in Task 9 prove **repository internal consistency** only. They **cannot** prove the renamed plugin installs from the live marketplace, because that requires a published release + a served marketplace index — neither exercisable from this working tree. The following step is therefore **explicitly carved out of this build** and enumerated as a separate, sequenced follow-up, executed as **Triple Crown ② (behavior)** after the rename is published:

1. **Publish** the rename (tag + GitHub Release for the chosen version, e.g. `v1.0.0`), so the marketplace index serves the new `name`/`source`. (Release mechanics out of scope for this plan; owned by whoever cuts the release, same as v0.6.3.)
2. **Live install probe** (Triple Crown ② — behavior): in a clean environment, run `/plugin marketplace add memoriterx/Orbit` (unchanged) then `/plugin install orbit`, and confirm the plugin resolves, installs, and its agents/commands/skills auto-discover. This is the **only** evidence that "new install works" — it is **not** claimed by any static gate in Task 9.
3. **Migration probe** (Triple Crown ② — behavior): from an environment that has `orbit-base` installed, confirm the documented migration path (`/plugin uninstall orbit-base` → `/plugin install orbit`) succeeds.

**Hard rule for the builder/reviewer:** do **not** mark RENAME-1 as "install verified" or "behavior ②" complete on the strength of Task 9's static gates. Task 9 closes "repo is consistent"; the follow-up above closes "it installs." These are distinct claims.

## Impact Scope

- **Distributable (end-user-facing):** `plugins/orbit/` (entire moved tree), `plugins/orbit/.claude-plugin/plugin.json`, `.codex-plugin/plugin.json`, `gemini-extension.json`, `plugins/orbit/scripts/setup-orbit.sh`, `plugins/orbit/commands/orbit-init.md`, top-level `setup-orbit.sh`, `.claude-plugin/marketplace.json`, `README.md`, `CHANGELOG.md`.
- **Dev-team meta (contributor-facing):** root `CLAUDE.md`, `.claude/settings.json` (gate), `.claude/agents/{reviewer,architect,builder,leader}.md`, `.planning/verify-autonomous-mode.sh`, `.planning/roadmap.md`.
- **Public contract changed:** the `/plugin install` identifier. **This is the breaking change.** Marketplace `add` target and repo URL unchanged.
- **Components touched:** ≥ 3 (manifests, scripts, hook gate, docs) → wide blast radius.

## Four-Trigger High-Risk Self-Assessment (for the leader's critic gate)

| Trigger | Verdict | Rationale |
|---------|---------|-----------|
| **T1 Irreversibility** | **FIRES** | Changing a published install identifier is not transparently reversible for users who already installed `orbit-base`: they must manually uninstall/reinstall. Reverting the rename would itself be a second breaking change. Backward-compat with the old install name is broken (no alias assumed). |
| **T2 Broad impact** | **FIRES** | Touches ~all active surfaces (4 manifests + 2 setup scripts + hook gate + README + CHANGELOG + 5 dev-meta files) and changes a **public contract** (the install identifier). Far exceeds the ≥3-component threshold. |
| **T3 Security/integrity** | does not fire | No auth/permissions/secrets/deletion/money/PII path. The `git mv` preserves history; no data migration of user content. (The only integrity-adjacent concern — the domain-purity gate going vacuous — is explicitly mitigated in Task 2.) |
| **T4 New external dependency** | does not fire | No new runtime dependency, external service, or vendor lock-in. |

**Conclusion:** **HIGH-RISK (T1 + T2 fire).** The leader must run the critic gate on this plan before Plan Approval, per the established workflow. Key critic-facing decision points: (1) MAJOR `1.0.0` vs minor bump; (2) hard-break vs alias migration (pending the leader-routed claude-code-guide answer); (3) whether the migration note sufficiently warns existing users.

## Migration Strategy (the critic's central concern)

**Default (this plan): hard break + migration guidance.**
- Already-installed `orbit-base` users: their local install keeps working but is **orphaned from updates** (the maintained plugin now publishes under `orbit`). They migrate manually: `/plugin uninstall orbit-base` → `/plugin install orbit`. The marketplace registration (`memoriterx/Orbit` → `orbit-marketplace`) is unchanged, so no `marketplace add` is needed.
- Past GitHub Releases (v0.2–v0.6.3) and their notes referencing `orbit-base` are **left intact** — they are historical facts. The break is announced going forward in the new `1.0.0` CHANGELOG entry + README callout.

**Alternative (only if the leader-routed claude-code-guide confirms support): marketplace alias.**
- If Claude Code marketplace supports declaring an old-name alias / redirect so existing installs continue updating under `orbit`, add that alias declaration to `.claude-plugin/marketplace.json` as an extra sub-task in Task 4, and soften the README/CHANGELOG note from "uninstall/reinstall" to "update in place." This is a **strict softening** of the default — it neither blocks nor reshapes any other task. This plan ships complete and correct without it.

**Rejected:** keeping both names live as two marketplace entries pointing at the same `source`. Rejected — it resurrects the very `-base`-implies-siblings confusion the rename is meant to remove, and doubles the maintenance/version surface.

## Commit Group Summary (distributable vs dev-meta never mixed)

| Group | Tasks | Commits |
|-------|-------|---------|
| **dev-meta** | 0, 2, 8 | ADR pointer; gate-path fix (positive/negative tested); dev-team meta refs (root CLAUDE.md ×5, agents, roadmap ×2 active, harness) |
| **distributable — move & rename** | 1, 3, 4, 5 | **pure git mv (1)**; wrapper path (3); 4-manifest rename + **marketplace source** + version bump (4); setup/orbit-init identifier (5) |
| **distributable — docs** | 6, 7 | README/CHANGELOG identifier prose; v1.0.0 migration note |
| **verification** | 9 | (no commit — static gates only) |
| **follow-up (separate, post-publish)** | — | live install + migration probe = Triple Crown ② behavior (NOT part of this build's static gates) |

Ordering rationale: **pure move first (Task 1, rename-only commit) → re-arm the gate immediately and prove it with a positive/negative test (Task 2) → fix referrers (3) → atomic identifier rename incl. marketplace source (4) → command/prose (5–7) → dev-meta incl. CLAUDE.md (8) → converge-verify (9) → post-publish live-install follow-up.** Task 1 stays content-clean for `--follow` robustness; the marketplace `source` edit deliberately rides with Task 4 so name+source land atomically. Task 2 runs right after the move so the domain-purity guard never sits vacuous while later distributable edits land.

## Success Criteria (measurable)

1. `git mv` complete and **content-clean**: `plugins/orbit/` exists, `plugins/orbit-base/` does not, file count preserved (40), `AGENTS.md` symlink intact, Task 1 commit is rename-only (Task 1 Step 3, Task 9 Step 3).
2. All four manifests carry `"name": "orbit"` and identical `"version"` (default `1.0.0`); marketplace `source` = `./plugins/orbit` and resolves on disk; `orbit-marketplace` name and `memoriterx/Orbit` repo identifier unchanged (Task 4 Step 5, Task 9 Step 2).
3. `grep -rn 'orbit-base' .` converges to **only** the enumerated intentional-historical residue; every active surface — including root `CLAUDE.md` (`grep -c 'orbit-base' CLAUDE.md` = 0) — is 0 (Task 9 Step 1).
4. All JSON valid, all shell scripts parse (Task 9 Step 4).
5. SubagentStop domain-purity gate **proven re-armed by executing the extracted gate command**: positive test blocks on a planted `Oremi` under `plugins/orbit/`, negative test passes clean, probe cleaned up (Task 2 Step 4); gate path is `plugins/orbit` with no stale `plugins/orbit-base` (Task 9 Step 5).
6. Distributable and dev-meta changes landed in **separate commits** per the commit-group table.
7. `1.0.0` CHANGELOG entry with BREAKING + Migration sections present; README migration callout present (Task 7).
8. **Static scope is honored:** "new install works" is **not** claimed from Task 9's static gates; the live-install + migration probes are enumerated as a separate post-publish Triple Crown ② follow-up (Post-Build Follow-Up section).

## Self-Review Notes

- **Concurrency:** plan is read-only at authoring time; the executing builder is gated on v0.6.3 publication (Task 0 Step 2 verifies a clean tree).
- **Gate-vacuity risk (critic BLOCKER #1 — resolved):** the central failure mode (domain-purity gate silently passing on a moved dir) is caught by **executing the actual SubagentStop command extracted from `settings.json`** with a positive (planted `Oremi` → must block) and negative (clean → must pass) test in Task 2 Step 4. A bare manual `grep` would *not* prove the gate file was edited; the extract-and-run test does. This is the load-bearing proof.
- **Active-vs-residue classification (critic MAJOR #2 round 1 + MAJOR A round 2 — resolved by CLASS-WIDE sweep):** instead of patching one more file, I re-ran the inventory **by class**: the active dev surface set `{ root CLAUDE.md, all .claude/, .planning/roadmap.md, .planning/ *.sh+*.py }` was grepped exhaustively. Results: root `CLAUDE.md` has **5** active hits (13/20/45/50/59 — round 1 under-scoped it to 2; now all 5 in Task 8 Step 1); `.planning/roadmap.md` has **2 active** (L32/L58 → Task 8 Step 3) vs **2 residue** (L114/L149 completed-milestone narration → untouched, asserted-present in Task 9); `.planning/*.py` scripts have **0** hits (confirmed no action). The loose `.planning/2026-06-18-*.md` plan/spike files are completed records → class (e). This kills the "one more same-class file" round-trip pattern.
- **Residue allow-list generalization (critic MINOR C — applied):** Task 9 Step 1 allow-list is now "**any completed (`[x]`) plan/spike record under `.planning/`**" rather than a `2026-06-18..20` date enumeration, so the same-day 06-21 completed plans (`plan-rwv-install-fixes.md`, `plan-docs-onboarding.md`) are covered and don't read as noise.
- **Gate positive-test branch coverage (critic MINOR B — documented):** Task 2 Step 4 notes the `.md` probe drives only the gate's `grep` branch; the two `find` branches are covered by Step 3's substring assertion that all three hardcoded paths changed. Optional companion `.sh`/`.json` probes noted but not required.
- **Static-verification limitation (critic MAJOR #3 — resolved):** an explicit Global Constraint + a "Post-Build Follow-Up" section state that all Task 9 gates are static and **do not** prove live install; the live-install + migration probes are carved out as a separate post-publish Triple Crown ② step, with a hard rule against claiming "install works" from static gates.
- **Pure-`git mv` (critic rec #6 — applied):** Task 1 is now a rename-only commit (verified content-clean in Task 1 Step 3); the marketplace `source` edit moved to Task 4 to keep `--follow` robust and land name+source atomically.
- **Timing rationale (critic rec #4 — applied):** ADR-RENAME-1 (Task 0 Step 1) now records "why now" — near-zero user base = lowest permanent-break cost window — and "why rename" — `-base` promises a nonexistent sibling tier; extensibility is via domain slots.
- **`orbit-init` path hint (critic rec #5 — applied):** reclassified from prose (c) to user-facing actionable instruction (c′); leaving it stale makes the user `export` a dead path. Verified in Task 5 Step 3.
- **`grep -q "orbit"` false-positive:** caught and mitigated with `grep -qw` in Task 5 Step 1 to avoid matching `orbit-marketplace`.
- **Invariants:** repo identifier and marketplace name are asserted unchanged (Task 9 Step 2), not just assumed.
