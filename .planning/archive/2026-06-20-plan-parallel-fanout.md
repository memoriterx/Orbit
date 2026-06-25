# Independent Fan-out → Fan-in Pattern — Implementation Plan (PERF-1, Option 1)

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Codify, in prose only, an "Independent Fan-out → Fan-in" orchestration pattern so the leader has a named pattern + independence test + an explicit "autonomous builds stay serial" safety fence — without adding any schema, infra, state, or command.

**Architecture:** Append-only documentation edits to exactly two deliverable files: `plugins/orbit-base/skills/using-orbit/SKILL.md` (a new section) and `plugins/orbit-base/agents/leader.md` (a dispatch-pattern line + a short note + one serial-fence sentence appended to the Autonomous Loop section). No code, no JSON, no new files. The autonomous-mode regression harness (`.planning/verify-autonomous-mode.sh`, C1–C15g) plays the role of the test suite: it must stay green, proving the edits did not disturb any pinned autonomous-mode contract phrase.

**Tech Stack:** Markdown prose. Verification via `bash` + `grep` + the existing harness script.

## Global Constraints

- Touched surfaces: **exactly two files** — `plugins/orbit-base/skills/using-orbit/SKILL.md` and `plugins/orbit-base/agents/leader.md`. No other file in `plugins/orbit-base/` may change. (Verified by set-diff in Task 3.)
- **Append-only to the autonomous contract:** do not reword, move, or delete any existing sentence in leader.md's `## Autonomous Loop (opt-in)` section or SKILL.md's `### Optional Mode: Autonomous Loop` section. Only *add* the serial-fence sentence(s).
- **Domain purity:** no project names (`oremi`, `orbit-dev`, etc.). Use role names and slots only. `grep -rciE 'oremi|orbit-dev' plugins/orbit-base/` must remain 0.
- **Hub-and-spoke preserved:** the leader is the sole fan-in (aggregation) point; no spoke reads another spoke's output. Every added paragraph must restate or be consistent with this.
- **Boundary contract (the load-bearing rule):** read-only investigation/review may run in parallel; **build/commit is always serial.** The autonomous build loop is never parallelized — cumulative T2, skip-and-park D4, and halt-on-first-failure all assume one commit at a time.
- **Frontmatter untouched:** leader.md lines 1–5 (`name`/`description`/`model`) must not change (harness C9).
- Four-trigger self-diagnosis: **all-no → LOW-RISK** (prose-only, 2 files, no contract change, no new dependency). No critic gate required. The harness re-run is the mandatory acceptance guardrail in lieu of a critic dispatch.

---

## File Structure

| File | Change | Responsibility |
|------|--------|----------------|
| `plugins/orbit-base/skills/using-orbit/SKILL.md` | **Add** one new section "## Independent Fan-out → Fan-in (optional throughput pattern)" after the `## Delegation Principle` section (currently line 86–94, ends before `## Reporting Channel` at line 96). Optionally add one Quick-Reference row. | Canonical prose definition of the pattern, the 4-point independence test, the read-only-vs-build boundary, and the serial-build fence. |
| `plugins/orbit-base/agents/leader.md` | **Add** (a) one comment line in the `## Agent Dispatch Pattern` code block (lines 119–131), (b) a 4–6 line "Independent fan-out" note immediately after that code block, (c) one serial-fence sentence appended to the end of the `## Autonomous Loop (opt-in)` section (after line 109, before `## Plan Approval Gate` at line 111). | Operational reminder for the leader at the dispatch site + the serial-build fence inside the autonomous contract. |

No new files. No deletions.

---

## Task 1: Add the "Independent Fan-out → Fan-in" section to SKILL.md

**Files:**
- Modify: `plugins/orbit-base/skills/using-orbit/SKILL.md` — insert a new `##` section between the `## Delegation Principle` section (ends at line 94) and the `## Reporting Channel` section (begins at line 96).

**Interfaces:**
- Consumes: nothing (first task).
- Produces: a section titled exactly `## Independent Fan-out → Fan-in (optional throughput pattern)` containing the phrases later tasks and the harness-extension assertion rely on: the literal substrings `sole fan-in`, `uncertain ⇒ serial` (or `uncertain⇒serial`), and `builds stay serial` (or `build … serial`). Task 2's leader.md note points readers at this section by name.

- [ ] **Step 1: Read the insertion site to confirm exact boundary lines**

Run: `sed -n '86,96p' plugins/orbit-base/skills/using-orbit/SKILL.md`
Expected: line 86 is `## Delegation Principle`, line 96 is `## Reporting Channel`. Confirm the blank line that separates them (line 95) is the insertion point.

- [ ] **Step 2: Insert the new section**

Insert the following block so that it sits **after** the Delegation Principle section's last line (line 94) and **before** `## Reporting Channel` (line 96), separated by blank lines on both sides:

```markdown
## Independent Fan-out → Fan-in (optional throughput pattern)

When the leader has **two or more independent units of work**, it may dispatch them **concurrently** (e.g. `Agent(explore, background)` and `Agent(researcher, background)` at the same time) and aggregate every result once **all** branches return. This is hub-and-spoke unchanged: one hub fans out to N spokes and collects N results. The **leader is the sole fan-in point** — no spoke reads or merges another spoke's output. This pattern only changes *throughput*; the lifecycle, the gates, and the routing are untouched.

**Independence test — all four must hold (else run serially):**
1. No branch writes state another branch reads.
2. No branch's prompt depends on another branch's result.
3. No required ordering between branches.
4. No two branches edit the same files.

If any point is unclear, **uncertain ⇒ serial** — dispatch the branches one at a time. This is the same fail-closed spirit as the autonomous gate's "ambiguous ⇒ stop": parallelism is taken only when independence is affirmatively clear.

**Safe to parallelize — read-only investigation and review:** concurrent `explore` + `researcher` investigation; independent reviews of already-built diffs; the two read-only Triple Crown prongs (② behavior, ③ quality) when they share no state. None of these write files or commit, so concurrency cannot create a race.

**Never parallelize — builds and commits:** any agent that writes files or commits (the `builder`) is dispatched **one at a time**. In particular the **autonomous loop's per-task build stays serial**: its cumulative blast-radius (T2), its skip-and-park independence predicate, and its halt-on-first-failure all assume **one commit at a time**. Fan-out parallelizes *investigation and review only*, never the autonomous build sequence.
```

- [ ] **Step 3: Verify the section exists with all load-bearing phrases**

Run: `grep -c 'Independent Fan-out → Fan-in' plugins/orbit-base/skills/using-orbit/SKILL.md`
Expected: `1` (the new heading).

Run: `grep -ciE 'sole fan-in point' plugins/orbit-base/skills/using-orbit/SKILL.md && grep -ciE 'uncertain ⇒ serial' plugins/orbit-base/skills/using-orbit/SKILL.md && grep -ciE 'build.*stays serial|builds stays serial|build sequence' plugins/orbit-base/skills/using-orbit/SKILL.md`
Expected: each `1` (all three boundary phrases present).

- [ ] **Step 4: Verify the Autonomous Loop section in SKILL.md was NOT modified**

Run: `git diff plugins/orbit-base/skills/using-orbit/SKILL.md | grep -E '^[-+]' | grep -iE 'ambiguous|skip-and-park|halt-on|cumulative|critic-on-entry'`
Expected: **no output** (the new section may *mention* the loop, but the diff must not add/remove any line touching the autonomous contract's pinned phrases — only the new section's own "stays serial" line is allowed, which does not contain those substrings).

- [ ] **Step 5: (Optional) Add a Quick-Reference row**

Read the Quick Reference table (line 144 onward). Add one row in the same pipe-table format:

```markdown
| Fan-out → Fan-in | Optional throughput pattern: leader dispatches 2+ independent units concurrently and aggregates after all return; leader is sole fan-in; read-only investigation/review only — builds/commits stay serial |
```

Run: `grep -c 'Fan-out → Fan-in' plugins/orbit-base/skills/using-orbit/SKILL.md`
Expected: `2` (the section heading + the table row). If the optional row is skipped, expected is `1` — that is acceptable.

- [ ] **Step 6: Commit**

```bash
git add plugins/orbit-base/skills/using-orbit/SKILL.md
git commit -m "docs(base): codify Independent Fan-out → Fan-in pattern in using-orbit skill"
```

---

## Task 2: Add the dispatch-site note + serial-build fence to leader.md

**Files:**
- Modify: `plugins/orbit-base/agents/leader.md` — (a) the `## Agent Dispatch Pattern` code block (lines 119–131); (b) a note immediately after that block; (c) the end of the `## Autonomous Loop (opt-in)` section (append after line 109, before `## Plan Approval Gate` at line 111).

**Interfaces:**
- Consumes: the SKILL.md section name from Task 1 (`Independent Fan-out → Fan-in`) — the note references it by name.
- Produces: the literal phrase `build … stays serial` (or `builds stay serial`) inside the Autonomous Loop section, so the harness and any future C16-class assertion can confirm the fence is present.

- [ ] **Step 1: Read both insertion sites to confirm boundaries**

Run: `sed -n '119,131p' plugins/orbit-base/agents/leader.md` (Agent Dispatch Pattern block)
Run: `sed -n '105,111p' plugins/orbit-base/agents/leader.md` (end of Autonomous Loop section → `## Plan Approval Gate`)
Expected: line 119 is `## Agent Dispatch Pattern`; the code block ends and prose follows; line 109 is the last line of the Autonomous Loop section ("...this cost is accepted."); line 111 is `## Plan Approval Gate`.

- [ ] **Step 2: Add a comment line to the dispatch code block**

In the code block at lines 121–127 (the `Agent(...)` list), add one line so the block reads (insert the new `# fan-out` line after the existing dispatch lines, keeping `background=True`/`background` consistent with the existing style):

```
Agent(builder, background=True)   # implementation
Agent(reviewer, foreground)       # post Triple Crown coordination; leader forwards T3 verdict as a hint (③ deep-mode is decided by the reviewer's own diff inspection)
Agent(architect, foreground)      # design or arch consistency lens
Agent(critic, foreground)         # high-risk plan critique (only when gate fires)
Agent(researcher, background)     # external source investigation
# Independent fan-out: dispatch 2+ independent read-only agents at once (e.g. explore + researcher), aggregate after all return — leader is sole fan-in. Builds/commits stay serial.
```

- [ ] **Step 3: Add the fan-out note after the dispatch code block**

Immediately after the closing ``` of the dispatch code block and before the existing "When dispatching the reviewer..." paragraph (currently line 129), insert:

```markdown
**Independent fan-out (optional throughput).** When two or more units of work are independent — no shared state, no result-feeds-prompt dependency, no required ordering, no shared files — the leader may dispatch them concurrently and aggregate once all return. The leader remains the **sole fan-in point** (no spoke reads another spoke's output), so hub-and-spoke is unchanged. If independence is unclear, **dispatch serially** (uncertain ⇒ serial). Parallelize **read-only investigation and review only**; any agent that writes files or commits (`builder`) is dispatched one at a time. See the using-orbit skill, "Independent Fan-out → Fan-in".
```

- [ ] **Step 4: Append the serial-build fence to the Autonomous Loop section**

At the very end of the `## Autonomous Loop (opt-in)` section — after the "Verification is never lightened." paragraph (ends line 109) and **before** `## Plan Approval Gate` (line 111) — append a new paragraph:

```markdown
**Builds stay serial (no fan-out inside the loop).** The autonomous loop's per-task **build is never parallelized**. The cumulative blast-radius tally (T2), the skip-and-park fail-closed independence predicate (D4), and halt-on-first-failure all assume **one commit at a time**: a running sum updated per task in order, an independence judgment against every already-parked task, and a halt that can stop the loop before the next build. Concurrent builds would compute against a stale tally and rob "halt" of meaning mid-flight. Fan-out (above) applies to **read-only investigation and review**, never to the autonomous build sequence. This adds no exception to the gate — it states that the existing serial-commit assumption is load-bearing.
```

- [ ] **Step 5: Verify the new phrases exist and the frontmatter is intact**

Run: `grep -ciE 'sole fan-in point' plugins/orbit-base/agents/leader.md && grep -ciE 'uncertain ⇒ serial' plugins/orbit-base/agents/leader.md && grep -ciE 'Builds stay serial|build is never parallelized' plugins/orbit-base/agents/leader.md`
Expected: each `>= 1`.

Run: `awk 'NR==1{a=($0=="---")} /^name:/{n=1} /^description:/{d=1} /^model:/{m=1} END{exit !(a&&n&&d&&m)}' plugins/orbit-base/agents/leader.md && echo FRONTMATTER_OK`
Expected: `FRONTMATTER_OK` (harness C9 condition holds).

- [ ] **Step 6: Verify the existing Autonomous Loop contract phrases are UNCHANGED**

Run: `git diff plugins/orbit-base/agents/leader.md | grep -E '^-' | grep -iE 'halt-on-first-failure|ambiguous|skip-and-park|cumulative|fail-closed|isolate-and-continue|critic-on-entry|affirmatively clear'`
Expected: **no output** (no existing pinned phrase was removed or reworded; the change is purely additive).

- [ ] **Step 7: Commit**

```bash
git add plugins/orbit-base/agents/leader.md
git commit -m "docs(base): add independent fan-out note + serial-build fence to leader"
```

---

## Task 3: Full verification — domain purity, set-diff, and the C1–C15g regression harness

**Files:**
- No file changes. This task is the acceptance gate (the "test run") for the whole plan.

**Interfaces:**
- Consumes: the committed edits from Tasks 1 and 2.
- Produces: a green verification record (all checks pass) that the reviewer's Triple Crown ① / ③ relies on.

- [ ] **Step 1: Domain-purity grep (harness C1 condition, run standalone first)**

Run: `grep -rciE 'oremi|orbit-dev' plugins/orbit-base/ | awk -F: '{s+=$2} END{print s+0}'`
Expected: `0` (no project-name leak in any deliverable file).

- [ ] **Step 2: Set-diff — confirm exactly two files changed under plugins/orbit-base/**

Run: `git diff --name-only HEAD~2 HEAD -- plugins/orbit-base/ | sort`
Expected exactly these two lines and no others:
```
plugins/orbit-base/agents/leader.md
plugins/orbit-base/skills/using-orbit/SKILL.md
```
If any third file appears, STOP — a constraint was violated; revert and re-scope.

- [ ] **Step 3: Confirm no existing "serial" / "halt" contract phrase was lost anywhere in plugins/orbit-base/**

Run: `git diff HEAD~2 HEAD -- plugins/orbit-base/ | grep -E '^-' | grep -iE 'halt-on-first-failure|halt-on-trigger|skip-and-park|cumulative|ambiguous|fail-closed|isolate-and-continue'`
Expected: **no output** (every pre-existing serial/halt/autonomous phrase survives; the change is append-only).

- [ ] **Step 4: Run the autonomous-mode regression harness (C1–C15g) — the mandatory acceptance gate**

Run: `bash .planning/verify-autonomous-mode.sh; echo "EXIT=$?"`
Expected: `EXIT=0` and every check reported PASS. Confirm specifically that these remain PASS (the brief's named must-not-disturb set):
- **C1** (no project-name leak) — corroborates Step 1.
- **C5a / C5b** (leader-loop / hub-and-spoke literal preserved) — the new fan-out prose restates hub-and-spoke; it must not have shadowed the literal phrase.
- **C12a / C12b** (ambiguous ⇒ stop) — the fan-out "uncertain ⇒ serial" test must not have diluted or reworded the autonomous "ambiguous ⇒ stop" phrase.
- **C13a / C13b / C13c** (cumulative T2 / batch cap / re-sync) — the appended serial-fence paragraph references cumulative T2; it must reinforce, not reword, the pinned cumulative-tally clause.
- **C15d / C15e** (halt-on-first-failure kept; isolate scoped to gate path) — the fence must not introduce a competing "parallel isolate" notion.
- **C15g** (fail-closed staleness predicate) — the fan-out independence test must read as consistent with D4, not replace it.

- [ ] **Step 5: If any harness check regressed — diagnose, do not loosen the harness**

If a check fails, the edit reworded a pinned phrase. Fix by restoring the original sentence verbatim and re-adding the new prose *additively* (do not edit the harness to match the new wording — the harness is the contract). Re-run Step 4 until `EXIT=0`. Use superpowers:systematic-debugging if the failure is non-obvious.

- [ ] **Step 6: Record the verification result**

Append a one-line record to `.orbit/notifications.log` (operational log, not a deliverable):
```
PERF-1 verify: C1–C15g PASS, set-diff=2 files (SKILL.md, leader.md), domain-purity grep=0
```

---

## Self-Review (architect — run against the spike + brief)

**1. Coverage of the brief's 7 requirements:**
1. Exactly 2 surfaces named with exact sections — ✅ Task 1 (SKILL §after Delegation Principle), Task 2 (leader Dispatch Pattern + Autonomous Loop end).
2. Pattern + applied examples + 4-point test + serial fence — ✅ Task 1 Step 2, Task 2 Steps 3–4. Examples: explore+researcher concurrent (named), independent Triple Crown ②③ reads (named).
3. Boundary contract (read-only parallel safe / build serial / leader sole fan-in) — ✅ Task 1 Step 2 "Safe / Never parallelize" blocks + Task 2 Step 4 fence.
4. Domain-agnostic — ✅ Global Constraints + Task 3 Step 1 grep; only role names and slots used.
5. Verification strategy (domain grep + C1–C15g re-run + set-diff + serial/halt intactness) — ✅ Task 3 Steps 1–4, with the named C5/C12/C13/C15d-e/C15g checks explicitly enumerated.
6. Measurable success criteria — ✅ see below.
7. Four-trigger reconfirmation, one line — ✅ Global Constraints last bullet + Summary.

**2. Placeholder scan:** No TBD/TODO; every insertion shows verbatim text and every verification step shows the exact command + expected output.

**3. Type/phrase consistency:** The load-bearing substrings (`sole fan-in point`, `uncertain ⇒ serial`, `builds stay serial` / `build is never parallelized`) are asserted by the same `grep` strings used to insert them; Task 2's note references Task 1's section by its exact heading name.

---

## Success Criteria (measurable)

A reviewer marks PERF-1 done only when **all** hold:

1. `grep -c 'Independent Fan-out → Fan-in' plugins/orbit-base/skills/using-orbit/SKILL.md` ≥ `1`.
2. `grep -ciE 'sole fan-in point' plugins/orbit-base/agents/leader.md` ≥ `1` AND the same for SKILL.md.
3. `grep -ciE 'Builds stay serial|build is never parallelized' plugins/orbit-base/agents/leader.md` ≥ `1` (the serial-build fence is present inside the Autonomous Loop section).
4. `git diff --name-only HEAD~2 HEAD -- plugins/orbit-base/` lists **exactly** `agents/leader.md` and `skills/using-orbit/SKILL.md` — no third file.
5. `grep -rciE 'oremi|orbit-dev' plugins/orbit-base/` sums to `0`.
6. `bash .planning/verify-autonomous-mode.sh` exits `0` with all C1–C15g PASS (C5/C12/C13/C15d-e/C15g specifically confirmed).
7. `git diff HEAD~2 HEAD -- plugins/orbit-base/ | grep '^-'` contains **no** removal of any pre-existing `halt`/`serial`/`skip-and-park`/`cumulative`/`ambiguous`/`fail-closed` phrase (append-only proven).
8. leader.md frontmatter (`name`/`description`/`model`) intact (harness C9 green).

---

## High-Risk Four-Trigger Self-Diagnosis

| Trigger | Verdict |
|---------|---------|
| T1 Irreversibility | **No** — prose-only, trivially deletable, no migration. |
| T2 Blast radius | **No** — 2 files, append-only, no public-contract change (the autonomous contract is *referenced*, not modified). |
| T3 Security / integrity | **No** — orchestration documentation only. |
| T4 New external dependency | **No** — no infra, MCP, runtime dep, or new file. |

**Verdict: all-no → LOW-RISK. No critic gate required.** The C1–C15g harness re-run (Task 3) is the mandatory acceptance guardrail in place of a critic dispatch, because the edits sit adjacent to the autonomous-mode contract.

---

## Execution Handoff

Plan complete and saved to `/Users/dh/Project/orbit/.planning/plans/2026-06-20-plan-parallel-fanout.md`. Recommended execution: **Subagent-Driven** — one fresh builder per task (Task 1 → Task 2 → Task 3), with the leader reviewing the harness-green result between tasks. Task 3 is the binding acceptance gate; do not mark PERF-1 done until `verify-autonomous-mode.sh` exits 0.
