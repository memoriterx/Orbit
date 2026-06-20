# Autonomous Mode — Skip-and-Park Execution Profile Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Extend orbit-base opt-in Autonomous Mode with a second, opt-in execution profile — **skip-and-park** — that parks (isolates) a high-risk/ambiguous task instead of halting the whole loop, continues clearing the remaining low-risk tasks, and reports the parked set to the human at batch end — without ever weakening the human gate for high-risk work.

**Architecture:** This is a **prose-contract** change to the orbit-base distributable. No new scripts, hooks, state files, or external dependencies. The entire feature is added by editing the existing Autonomous Mode contract across the six distributable surfaces that already describe it (the canonical regression harness `.planning/verify-autonomous-mode.sh` is a dev asset, updated separately — see Task 6.5). The default behavior (`halt-on-trigger`) is **unchanged and remains the default**; skip-and-park is a named alternate profile the user may select **only as part of granting a batch pre-approval**.

**The human-gate invariant is preserved identically across both profiles:** a high-risk/ambiguous task is **never auto-decided or auto-implemented** — park = defer that one task for individual approval, halt = stop the whole loop and defer that task for individual approval. Both route the high-risk task to the same human gate; they differ only in what happens to the *remaining low-risk tasks*.

**Two scopes of "isolate-and-continue" — kept strictly separate (this is BLOCKER-1's resolution):** orbit's existing contract has *two distinct ejection causes* with deliberately different loop policies, and skip-and-park changes only the first:
1. **Gate-path ejection (high-risk / ambiguous, pre-build).** This is where skip-and-park applies: under `skip-and-park` the gated task is *parked and the loop continues*; under `halt-on-trigger` (default) it *halts the loop*. The task is never built either way.
2. **Triple Crown failure (post-build, ② or ③ failed).** This is **out of scope for skip-and-park**. The existing `Failure rollback` contract — *"halt-on-first-failure, not isolate-and-continue"* (leader.md) — **remains in force under both profiles**. A built task that *fails verification* always halts the loop; skip-and-park never converts a verification failure into "park and continue." The plan edits the `Failure rollback` paragraph to state this scoping explicitly so the two clauses cannot be read as contradictory.

**Honest safety characterization (this is MAJOR-5's resolution):** park is **not** unconditionally "halt-safe-equivalent." It is **conditionally safe**, and the condition is the *task-independence* of the remaining low-risk tasks from the parked one. Halt is safe without that assumption (nothing else runs); park keeps running siblings, so its safety *depends* on those siblings not relying on the parked task's deferred decision. The plan secures that condition with a **conservative, fail-closed staleness predicate** (D4, below) and states the residual risk in the contract rather than claiming exact equivalence.

**Tech Stack:** Markdown agent prompts (`agents/*.md`), markdown skill (`skills/using-orbit/SKILL.md`), markdown command (`commands/orbit-cycle.md`), markdown references (`skills/using-orbit/references/*.md`), plugin root `CLAUDE.md`. No code; the "tests" are verification harnesses (grep/set-diff/invariant checks) run by the builder.

## Global Constraints

- **Domain-agnostic**: no project-specific names (oremi/Oremi/orbit-dev) in `plugins/orbit-base/`. `grep -riE 'oremi|orbit-dev' plugins/orbit-base/` must return 0. Slots (`{{...}}`) stay slots — verbatim from source.
- **Zero new infrastructure**: no new files, no new hooks, no new state files (`.orbit/*`), no new external dependencies. Edits land only in files that already document Autonomous Mode. (The prior autonomous feature shipped at "new-infra-zero"; this follows that precedent.)
- **Human-gate invariant is non-negotiable**: high-risk (any four-trigger firing) and ambiguous tasks are **never** auto-decided or auto-implemented under either profile. Skip-and-park defers them; it does not approve them.
- **Backward-compat**: the existing default (`halt-on-trigger`) contract wording is preserved. Skip-and-park is additive opt-in. No existing user who never selects skip-and-park sees any behavior change.
- **Surface tiering** (advisory from prior work): the **6-spoke surface** (leader.md, SKILL.md, gemini-tools.md) and the **7-full surface** (CLAUDE.md, codex-tools.md) plus orbit-cycle.md must all stay mutually consistent. Edit all six; do not introduce a fact in one that contradicts another.
- **No new copy of the four-trigger category string** (critic.md T3 canonical-origin discipline): this plan does not add a fifth copy of the trigger/security category list. It references existing definitions by name.

---

## Design Decisions (the seven required questions)

These decisions are the **contract** this plan implements. Every task's wording derives from here. The implementer copies the contract phrasings verbatim into the touched surfaces.

### D1 — Relationship to current auto-halt (two selectable profiles; default unchanged)

**Decision:** `halt-on-trigger` and `skip-and-park` are **two named profiles of the same Autonomous Mode**, not a replacement. **`halt-on-trigger` remains the default.** A batch pre-approval may *optionally* select `skip-and-park`; absent an explicit selection, the loop behaves exactly as today (halt-on-first-trigger). The user's existing contract is not broken: anyone who never names skip-and-park gets identical behavior.

**Contract phrasing (canonical, reused across surfaces):**
> Autonomous Mode has two **execution profiles**, both opt-in within a batch pre-approval:
> - **`halt-on-trigger` (default).** Any four-trigger firing or ambiguous judgment ejects the task and **halts the entire loop**; remaining tasks are not attempted until the human resolves the ejected task. (Unchanged from prior behavior.)
> - **`skip-and-park` (opt-in alternate).** Any four-trigger firing or ambiguous judgment ejects the task into a **parked set** and the loop **continues** with the remaining low-risk tasks. At batch end the leader reports the parked set to the human. Parked tasks are never auto-decided or auto-implemented; each returns to individual Plan Approval (with the critic branch, since a trigger fired or the task was ambiguous).
>
> The profile is fixed for the batch at pre-approval time and cannot change mid-loop. If the user does not name a profile, `halt-on-trigger` applies.

### D2 — Interaction with batch-cumulative blast radius (T2)

**Decision:** A parked task is **never implemented**, so it **contributes nothing** to the cumulative distinct-component tally. The running T2 total counts components touched **only by *completed (built)* tasks**. Parking a task removes it from the batch's blast-radius accounting entirely — it is as if the task were not in the batch for T2 purposes. This is the safe direction: parking cannot *inflate* cumulative blast radius and thereby cause a spurious later T2 halt.

**Important subtlety (kept explicit to avoid a loophole):** the cumulative T2 total still grows monotonically as *low-risk tasks complete*. Skip-and-park does **not** reset or lower the running tally; it merely declines to add the parked (un-built) task's components. So a long skip-and-park run still hits the cumulative-T2 ceiling and re-syncs exactly as halt-on-trigger would — parking does not let the loop evade the cumulative ceiling *within a single batch*.

**Amortization guard across re-approvals (this is MAJOR-3's resolution).** A real evasion path exists *across* batches, not within one: if every re-sync re-enumerates a fresh batch that *carries the parked high-risk tasks forward*, the cumulative ceiling effectively resets each re-approval, diluting oversight to "re-sync-count × 5." The contract closes this two ways, both fail-closed:
1. **Parked tasks are forcibly excluded from any continuation batch's enumeration.** A parked (high-risk/ambiguous) task can never re-enter an *autonomous* batch — by definition it is no longer manifestly all-no, so critic-on-entry would reject it anyway; the contract makes this explicit so it is not silently re-batched. Parked tasks return **only** through individual per-task Plan Approval. The autonomous scope and the parked set are disjoint by construction.
2. **Parked-backlog cap blocks re-approval.** If the accumulated parked set reaches a small cap (**≥ 3 parked tasks outstanding**), the leader **declines to grant any further autonomous batch** until the human has cleared (individually approved or rejected) the parked backlog. This prevents an operator from indefinitely deferring high-risk work while the low-risk loop races ahead — the parked set cannot grow unbounded behind the human's back.

**Contract phrasing:**
> Under either profile, the cumulative blast-radius tally (T2) counts distinct components touched **only by tasks that were actually built (completed Triple Crown)**. A parked task is never built and contributes **zero** components to the cumulative total. The tally still grows as low-risk tasks complete; parking neither resets nor lowers it. Reaching the cumulative-component ceiling halts the loop for re-sync under both profiles. **Parked tasks are excluded from every autonomous continuation batch** (they are no longer manifestly all-no; they return only through individual Plan Approval), so re-syncing cannot launder a high-risk task back into autonomy. If **3 or more parked tasks are outstanding**, the leader **declines to grant a further autonomous batch** until the human clears the parked backlog.

### D3 — Batch-size cap (≤5): count completed tasks, not parked

**Decision:** The **≤5 cap counts tasks the loop actually *built* (completed)**, not parked tasks. Parking a task does **not** consume a slot against the cap. Rationale: the cap exists to bound *accumulation, cross-task interaction, and context drift* from work actually done; a parked (un-built) task produces none of those. A skip-and-park batch may *enumerate* more than 5 candidates only if critic-on-entry cleared them — but if more than 5 are *built*, the loop halts for re-sync at the 5th completion regardless of how many were parked along the way.

**Edge case nailed down:** the **enumeration cap** at pre-approval is still ≤5 candidate tasks (unchanged — the leader declines an enumerated scope larger than 5). The **completion cap** is also 5. Parking simply means fewer than the enumerated count may complete; it never raises either ceiling.

**Contract phrasing:**
> The batch-size cap counts **completed (built)** tasks: the loop halts for human re-sync on the 5th completion. **Parked tasks do not count against the cap** (they are never built). The enumeration ceiling at pre-approval remains ≤5 candidate tasks regardless of profile.

### D4 — Scope re-validation (staleness) when a parked task changes a pending task's premise

**Decision (fail-closed predicate — this is MAJOR-4's resolution).** A parked task is **never built**, so its effect on a pending task's premise leaves **no code trace** to detect — the leader can only reason about it, and reasoning is false-negative-prone (it may *miss* a real dependency). A "park only if it *plausibly alters*" rule fails open: undetected coupling ⇒ a sibling built on a silently-stale premise. The contract therefore **inverts the predicate to fail-closed**:

> A pending task remains autonomously buildable **only if its independence from every parked task is affirmatively clear**. If the leader **cannot positively establish** that a pending task is unaffected by every parked task, the pending task is treated as **ambiguous ⇒ parked**. The default is *park*, not *build*: uncertainty about coupling resolves to parking, never to proceeding.

This is the same conservative posture orbit already uses for the four-trigger gate ("manifestly all-no, else stop") applied to inter-task coupling. The contract **explicitly names the residual false-negative risk** (the leader could wrongly *believe* independence is clear) rather than claiming detection is reliable — so the human reading the parked-set report knows park-and-continue rests on the leader's independence judgment, a known soft spot, now biased toward over-parking.

**Contract phrasing:**
> Scope re-validation runs at each task boundary under both profiles. Under `skip-and-park`, a parked task is a **premise-mutator with no code trace** (it was never built), so coupling cannot be detected from the diff — only reasoned about. The predicate is therefore **fail-closed**: a pending task stays autonomously buildable **only when its independence from every parked task is affirmatively clear**; if independence **cannot be positively established**, the pending task is itself **parked** (uncertain coupling ⇒ ambiguous ⇒ park). This biases toward over-parking. The residual risk — the leader wrongly judging independence clear (a false negative) — is acknowledged, not assumed away; it is the reason park is *conditionally* safe (D5), not halt-equivalent. Re-enumeration + critic-on-entry over the remaining items still applies if the roadmap/codebase materially changed.

### D5 — Ambiguous case ("ambiguous ⇒ stop" becomes "ambiguous ⇒ park"); not a safety weakening

**Decision (honest equivalence — this is MAJOR-5's resolution).** Under skip-and-park the local rule reads **"ambiguous ⇒ park"** instead of "ambiguous ⇒ halt-loop." The **strong invariant is genuinely identical** in both profiles and must be stated as such: *the ambiguous/high-risk task itself is never auto-decided or auto-implemented* — it lands at the exact same human gate (individual Plan Approval + critic branch). That part of "park = halt" is unconditional and true.

**But the *whole-loop* safety claim is NOT equivalent, and the plan must not pretend otherwise.** Halt is safe with **no assumptions** (nothing else runs). Park keeps running siblings, so park's safety for the *batch as a whole* carries one extra premise: **the surviving low-risk tasks are independent of the parked task.** That premise is enforced — but not *proven* — by D4's fail-closed predicate. So the honest characterization is:

> **Park is conditionally safe, not halt-equivalent.** For the parked task itself, park and halt are exactly equivalent (never auto-decided/auto-implemented — unconditional). For the rest of the loop, park's safety is *conditional on the D4 independence predicate holding*; halt has no such condition. The condition is biased fail-closed (uncertain ⇒ park), but its residual false-negative risk (D4) means park trades a small, acknowledged dependency-risk for higher throughput. The plan claims conditional safety, not exact equivalence.

**Contract phrasing (copied where the ambiguity rule appears):**
> **`skip-and-park` is not a relaxation of the per-task gate.** "ambiguous ⇒ park" is the same prohibition as "ambiguous ⇒ stop" *for the ambiguous task itself*: it is **never auto-decided or auto-implemented** — it is set aside for individual human Plan Approval (with the critic branch). The sole path to autonomous execution remains an unambiguous all-no. **Park is, however, only *conditionally* whole-loop-safe** (not halt-equivalent): unlike halt, it keeps running sibling tasks, so batch-level safety depends on the fail-closed independence predicate (scope re-validation) holding. That predicate biases toward over-parking; its residual false-negative risk is the deliberate cost of the higher throughput skip-and-park buys.

### D6 — Reporting format (where + what)

**Decision:** Two-tier reporting, reusing existing channels (no new files):
1. **Per-park, immediately:** a one-line entry to `.orbit/notifications.log` at the moment a task is parked (existing notification channel — no new channel).
2. **Batch-end consolidated:** the leader's final batch summary (the same return-to-human re-sync report that halt-on-trigger already produces) includes a **Parked Tasks** section.

**Parked-set record fields (per parked task):** `task ID`, `which trigger(s) fired or "ambiguous"`, `recommended next action` (always: individual Plan Approval + critic branch). Completed tasks are reported as today (checkbox + tally); parked tasks are reported in the dedicated section.

**Contract phrasing:**
> When a task is parked, the leader writes a one-line entry to `.orbit/notifications.log` (`PARKED <task-id> — trigger: <T1|T2|T3|T4|ambiguous> — next: individual Plan Approval + critic`). At batch end the leader's re-sync report includes a **Parked Tasks** section listing, per parked task: the task ID, the firing trigger (or "ambiguous"), and the recommended next action (individual Plan Approval with the critic branch). No new file or channel is introduced.

### D7 — Defining "unattended" (no new detection mechanism — it is a pre-approval option)

**Decision:** There is **no runtime "is-a-human-present" detector** — building one would violate the zero-new-infrastructure constraint and add an unverifiable signal. "Unattended" is **defined by the user's act of selecting `skip-and-park` when granting the batch pre-approval.** By choosing skip-and-park, the user is declaring "I will not be present to resolve each ejection mid-loop; park them and I will review the parked set when I return." The mechanism is therefore *identical* to the existing batch-pre-approval entry point — skip-and-park is one more attribute of the pre-approval, exactly like the enumerated scope and the (already-existing) profile of halting.

**Argument (recorded for the critic gate):** A separate unattended-detection mechanism is rejected because (a) it adds infrastructure with no reliable signal in a CLI/agent context, (b) it would make autonomy depend on an inferred state rather than an explicit human grant — weakening the "explicit human gate" property, and (c) the existing batch pre-approval already *is* the human's explicit statement of intent to step away. Tying skip-and-park to that grant keeps the human's intent explicit and auditable.

**Contract phrasing:**
> "Unattended" is **not detected at runtime**. It is the user's explicit choice of the `skip-and-park` profile when granting the batch pre-approval — a declaration that the human will review parked tasks on return rather than resolve each ejection live. No presence-detection mechanism exists or is added; skip-and-park is an attribute of the pre-approval grant, nothing more.

---

## Alternatives Considered and Rejected (this is MAJOR-6's resolution)

**Demand basis:** the user directly requested full skip-and-park on 2026-06-20 ("the user wants full skip-and-park properly implemented, not a simple alternative"). Demand is therefore *established by explicit request*, not inferred. The job of this section is to confirm the simpler option was weighed and explain why the requested design is warranted over it — not to relitigate whether the feature should exist.

**Alternative A — "current halt + manual resume" (the do-less option).**
*What it is:* keep the existing `halt-on-trigger` behavior unchanged; when the loop halts on a high-risk/ambiguous task, the human returns, individually approves that one task, and **manually re-issues a fresh batch pre-approval** for the remaining low-risk tasks. No new profile; the leader already supports per-task approval + re-sync.

*Why it is genuinely cheaper:* zero contract change, zero new failure modes, zero new amortization/staleness reasoning (D2/D3/D4 simply do not arise). It already works today.

*Why it is rejected for the stated need:* it does not satisfy the user's actual requirement — *finishing the low-risk remainder while the human is away*. Under Alternative A the loop is **stalled at the first high-risk task** until a human returns; every subsequent low-risk task waits behind it regardless of independence. For an unattended overnight/away run with one early high-risk item, Alternative A clears **zero** further tasks; skip-and-park clears the entire independent low-risk remainder. The user explicitly asked for the latter and explicitly ruled out a "simple alternative." Alternative A *is* that simple alternative, so it is rejected on the recorded requirement — but it remains the correct fallback for any user who does **not** opt into `skip-and-park` (it is literally the default profile).

**Alternative B — "isolate-and-continue for verification failures too" (the do-more option).**
*What it is:* also let a *Triple Crown failure* park-and-continue instead of halting.
*Why rejected:* a verification failure means built code is wrong — continuing risks compounding on a broken base, and the existing `Failure rollback` contract deliberately forbids it. Out of scope; the plan preserves halt-on-first-failure (see BLOCKER-1 / Architecture).

**Conclusion:** skip-and-park (gate-path only, fail-closed staleness, parked-backlog cap) is the minimal design that meets the explicit requirement while leaving Alternative A intact as the default and rejecting the unsafe Alternative B.

---

## Touched Surfaces (exact files + sections + edit outline)

**Distributable surfaces: six files** (set-diff in Task 7 asserts exactly these six change under `plugins/orbit-base/`, no more, no fewer). **Plus one dev-asset surface** (`.planning/verify-autonomous-mode.sh`) updated in Task 6.5 — outside the six-file set-diff boundary because `.planning/` is a development asset, not part of the shipped plugin.

| # | File | Section | Edit outline |
|---|------|---------|--------------|
| S1 | `plugins/orbit-base/CLAUDE.md` | `## Autonomous Mode (opt-in)` (lines ~52–74), esp. the **Auto-halt (hard)** paragraph | Add a **Execution profiles** sub-paragraph (D1) introducing `halt-on-trigger` (default) + `skip-and-park`; amend the Auto-halt paragraph to state both profiles' behavior; fold in D2 (T2 counts built-only + amortization guard / parked-backlog cap), D3 (cap counts built-only), D5 (conditional-safety non-weakening clause). 7-full surface — fullest treatment. |
| S2 | `plugins/orbit-base/agents/leader.md` | `## Autonomous Loop (opt-in)` (lines ~88–106), esp. step 2 high-risk branch, step 3 boundary, step 4 cap, **and the `Failure rollback` paragraph (line ~104)** | Add profile selection to "Accepting a batch"; in loop step 2 high-risk branch, add the park alternative to the halt path (D1/D5); step 3 add **fail-closed** premise-mutator staleness rule (D4); step 4 clarify cap counts built-only (D3) + parked-backlog cap (D2); add reporting (D6); **edit the `Failure rollback` paragraph to scope "isolate-and-continue" to the gate path only and reaffirm halt-on-first-failure for verification failures under both profiles (BLOCKER-1).** 6-spoke surface — operational detail. |
| S3 | `plugins/orbit-base/skills/using-orbit/SKILL.md` | `### Optional Mode: Autonomous Loop (opt-in, default off)` (line ~56) + `## Quick Reference` Autonomous Mode row (line ~150) | Add one sentence on the two profiles + park-not-weakening (D1/D5) to the prose paragraph; update the Quick Reference row to mention skip-and-park. 6-spoke surface — orientation level. |
| S4 | `plugins/orbit-base/commands/orbit-cycle.md` | `## (선택) 자율 모드 — 묶음 선승인` (lines ~157–175) + 유의사항 (lines ~197–201) | Mirror S1/S2 in Korean: profile selection at 묶음 선승인, park branch in loop step 2, premise-mutator in step 3, cap/T2 built-only, reporting, non-weakening note in 유의사항. 7-full surface. |
| S5 | `plugins/orbit-base/skills/using-orbit/references/codex-tools.md` | `## Autonomous Mode (opt-in)` (line ~78–80) | One sentence: both profiles apply identically under Codex's sequential loop; skip-and-park parks-and-continues serially, halt-on-trigger stops; four-trigger gate + Triple Crown unchanged. Degradation note only. |
| S6 | `plugins/orbit-base/skills/using-orbit/references/gemini-tools.md` | `## Autonomous Mode (opt-in)` (line ~74–76) | One sentence: both profiles apply under Gemini's manual sequential role-switch; skip-and-park parks-and-continues, halt stops; human still grants the batch (now optionally selecting the profile) once. Degradation note only. |

**Plus dev-asset surface (outside the six-file set-diff):**

| H | `.planning/verify-autonomous-mode.sh` | C1–C14 check block | Add C15 skip-and-park checks (see Task 6.5); confirm park edits do not break C4a (`halt\|eject` still present — `halt-on-trigger` keeps "halt"), C7 (`withdraw\|task boundary` preserved), C12a/C12b (`ambigu.*stop\|ambigu.*halt\|manifestly all-no` — the existing "ambiguous ⇒ stop" line is **kept**, park is added alongside it, not replacing it). Dev asset, not shipped; not in the six-file boundary. |

**Explicitly NOT touched (asserted by set-diff):** `critic.md` (no new trigger-category copy; D2/D5 reference its canonical T3 origin by name, no edit), `reviewer.md` (deep-mode is per-task-only and orthogonal to park; parked tasks are never built so never reach ③ — no edit needed; the existing "per-task mode only" mutual-exclusivity wording already covers this — **MINOR-8 adjacency note recorded below**), `plugin.json`/manifest, any `.orbit/` state, any script.

**MINOR-8 adjacency note (③ deep-mode × skip-and-park).** reviewer.md states ③ security deep-mode is "per-task mode only … never inside an autonomous batch," justified because a T3-touching task is high-risk and ejected from the batch. skip-and-park does **not** change this: a T3 firing is a four-trigger firing, so under *both* profiles the task is gated out (parked or halted) and **never built inside the autonomous loop** — it reaches ③ only later, in per-task mode, after individual approval. So the existing mutual-exclusivity wording remains exactly true under skip-and-park, and reviewer.md needs **no edit**. This adjacency is noted for completeness; closing it is **out of scope** for this plan (no contradiction exists to fix).

---

## Verification Strategy (this is a contract change — harnesses, not unit tests)

Because the deliverable is prose contract, "tests" are **executable verification harnesses** the builder runs and pastes output for. Four classes:

1. **Canonical regression harness (BLOCKER-2):** re-run the existing `.planning/verify-autonomous-mode.sh` (C1–C14). Every prior invariant must still PASS after the park edits — proving skip-and-park did not regress default-off, non-negotiable, auto-halt (C4), conservative-default (C12), cumulative-T2/cap (C13), or staleness (C14). Task 6.5 extends it with C15 (skip-and-park-specific) and Task 7 runs the full suite.
2. **Invariant harness (the load-bearing one):** grep-based reverse-check that the human-gate invariant survives. Asserts that **every** surface describing skip-and-park also, in the same section, contains the non-weakening clause (high-risk/ambiguous never auto-decided/auto-implemented; routes to individual Plan Approval + critic). A surface that introduces "park" without the guard fails the harness. **Plus a reverse-check that the `Failure rollback` "halt-on-first-failure" clause survived (BLOCKER-1).**
3. **Domain-purity grep:** `grep -riE 'oremi|orbit-dev' plugins/orbit-base/` → 0 matches; slot integrity check (no `{{...}}` slot was filled with a concrete value).
4. **Set-diff surface check:** `git diff --name-only` under `plugins/orbit-base/` equals exactly the six S1–S6 files — no more, no fewer (the harness edit lands under `.planning/`, deliberately outside this boundary).

Each task below ends with the relevant harness invocation and expected output. Tasks are ordered so the cross-surface invariant and the full C1–C15 suite are asserted once all surfaces are edited (Task 7).

---

## Task 1: CLAUDE.md (S1) — profiles, park branch, T2/cap accounting, non-weakening

**Files:**
- Modify: `plugins/orbit-base/CLAUDE.md` — `## Autonomous Mode (opt-in)` section (the "Auto-halt (hard)" paragraph ~line 74 and surrounding)

**Interfaces:**
- Produces: the canonical contract phrasings for **D1 profiles**, **D2 T2-built-only**, **D3 cap-built-only**, **D5 non-weakening clause**. Tasks 2–6 reuse these exact phrasings (shortened where the surface is orientation-level). Anchor strings later tasks/harness rely on: the literal phrase `skip-and-park`, the literal phrase `halt-on-trigger`, and the non-weakening sentence `never auto-decided or auto-implemented`.

- [ ] **Step 1: Write the failing invariant check for this surface**

Run (from repo root):
```bash
grep -c 'skip-and-park' plugins/orbit-base/CLAUDE.md
```
Expected now: `0` (proves the surface is unedited — this is the failing state).

- [ ] **Step 2: Add the Execution Profiles paragraph after the existing "Auto-halt (hard)" paragraph**

Insert this new paragraph immediately after the existing `**Auto-halt (hard).**` paragraph in `## Autonomous Mode (opt-in)`:

```markdown
**Execution profiles (default `halt-on-trigger`; opt-in `skip-and-park`).** Autonomous Mode has two execution profiles, both opt-in within a batch pre-approval and fixed for the batch at pre-approval time:
- **`halt-on-trigger` (default).** Any four-trigger firing or ambiguous judgment ejects the task and **halts the entire loop**; remaining tasks are not attempted until the human resolves the ejected task. This is the prior, unchanged behavior. If the user names no profile, this applies.
- **`skip-and-park` (opt-in alternate).** Any four-trigger firing or ambiguous judgment ejects the task into a **parked set** and the loop **continues** with the remaining low-risk tasks. At batch end the leader reports the parked set. **`skip-and-park` is not a relaxation of the gate:** a parked (high-risk or ambiguous) task is **never auto-decided or auto-implemented** — it returns to individual human Plan Approval with the critic branch (since a trigger fired or the task was ambiguous). "ambiguous ⇒ park" is the same prohibition as "ambiguous ⇒ stop"; park changes only *which* tasks pause (the one task, not the whole loop), never letting an ambiguous task proceed. The sole path to autonomous execution remains an unambiguous all-no.

**Accounting under both profiles.** The cumulative blast-radius tally (T2) counts distinct components touched **only by tasks actually built (completed Triple Crown)**; a parked task is never built and contributes **zero** components — parking neither resets nor lowers the running tally, so a long `skip-and-park` run still hits the cumulative ceiling and re-syncs. The batch-size cap likewise counts **completed (built)** tasks (halt for re-sync on the 5th completion); parked tasks do not consume a slot. The enumeration ceiling at pre-approval stays ≤ 5 candidate tasks under either profile.

**Amortization guard (no re-sync laundering).** Parked tasks are **excluded from every autonomous continuation batch** — being parked means they are no longer manifestly all-no, so they re-enter only through individual per-task Plan Approval; the autonomous scope and the parked set are disjoint by construction. This prevents re-syncing from resetting the cumulative ceiling around a carried-forward high-risk task. Additionally, if **3 or more parked tasks are outstanding**, the leader **declines to grant any further autonomous batch** until the human has cleared the parked backlog — the parked set cannot grow unbounded behind human oversight.
```

- [ ] **Step 3: Run the invariant check to verify it now passes**

Run:
```bash
grep -c 'skip-and-park' plugins/orbit-base/CLAUDE.md && \
grep -c 'halt-on-trigger' plugins/orbit-base/CLAUDE.md && \
grep -c 'never auto-decided or auto-implemented' plugins/orbit-base/CLAUDE.md && \
grep -ci 'parked.*outstanding|3 or more parked' plugins/orbit-base/CLAUDE.md
```
Expected: all four counts ≥ `1` (both profiles, the non-weakening clause, and the parked-backlog amortization cap present).

- [ ] **Step 4: Run domain-purity grep on the edited file**

Run:
```bash
grep -riE 'oremi|orbit-dev' plugins/orbit-base/CLAUDE.md; echo "exit=$?"
```
Expected: no output, `exit=1` (grep found nothing).

- [ ] **Step 5: Commit**

```bash
git add plugins/orbit-base/CLAUDE.md
git commit -m "feat(base): add skip-and-park autonomous execution profile to CLAUDE.md contract"
```

---

## Task 2: leader.md (S2) — operational loop: park branch, fail-closed staleness, parked-backlog cap, reporting, scoped failure-rollback

**Files:**
- Modify: `plugins/orbit-base/agents/leader.md` — `## Autonomous Loop (opt-in)` section (lines ~88–106) **and the `Failure rollback` paragraph (line ~104)**

**Interfaces:**
- Consumes: the D1/D5 profile phrasing and `skip-and-park`/`halt-on-trigger` anchor strings produced in Task 1.
- Produces: the operational loop semantics for **D4 fail-closed premise-mutator**, **D2 parked-backlog cap**, **D6 reporting** (immediate notifications.log line + batch-end Parked Tasks section), and **BLOCKER-1 scoped failure-rollback** (`halt-on-first-failure` kept for verification failures, `isolate-and-continue` scoped to gate path). Anchors produced: `affirmatively clear`/`positively established`/`fail-closed`, `halt-on-first-failure`, `3 or more parked`. Tasks 3–6 reuse the report-field list (task ID / trigger / next action) at orientation level; Task 6.5's C15 asserts these anchors.

- [ ] **Step 1: Write the failing check**

Run:
```bash
grep -c 'skip-and-park' plugins/orbit-base/agents/leader.md
```
Expected now: `0`.

- [ ] **Step 2: Add profile selection to "Accepting a batch"**

In the `**Accepting a batch (critic-on-entry first).**` paragraph, append this sentence at its end:

```markdown
The pre-approval also fixes the **execution profile**: `halt-on-trigger` (default — any ejection halts the whole loop) or the opt-in `skip-and-park` (an ejected task is parked and the loop continues with remaining low-risk tasks). If the user names no profile, `halt-on-trigger` applies. The profile is fixed for the batch and cannot change mid-loop.
```

- [ ] **Step 3: Add the park alternative to the loop step 2 high-risk branch**

In "Loop per task", step 2, the bullet beginning `- **Any trigger fires OR the judgment is ambiguous`, append after its existing text:

```markdown
   - Under **`halt-on-trigger`** (default): eject the task and **halt the loop** (as above), then dispatch the critic and escalate to individual Plan Approval. Under **`skip-and-park`**: **park** the task instead — record it (see reporting below) and **continue the loop** with the remaining low-risk tasks. Either way the parked/ejected task is **never auto-decided or auto-implemented**; it goes to individual human Plan Approval with the critic branch. Park defers one task; it never weakens the gate ("ambiguous ⇒ park" = "ambiguous ⇒ stop" for that task).
```

- [ ] **Step 4: Add the FAIL-CLOSED premise-mutator rule to step 3 (scope re-validation)**

In step 3 sub-item (a) (scope re-validation), append (note the predicate is fail-closed — *park unless independence is affirmatively clear*, not *park if plausibly affected*):

```markdown
Under `skip-and-park`, a **parked task is a premise-mutator with no code trace** (it was never built, so coupling cannot be detected from any diff — only reasoned about). The predicate is therefore **fail-closed**: a pending task stays autonomously buildable **only when its independence from every parked task is affirmatively clear**; if independence **cannot be positively established**, the pending task is itself **parked** (uncertain coupling ⇒ ambiguous ⇒ park). This biases toward over-parking. The residual risk — the leader wrongly judging independence clear (a false negative) — is the reason park is only *conditionally* whole-loop-safe, not halt-equivalent.
```

- [ ] **Step 5: Add the cap clarification + parked-backlog amortization cap to step 4, and a Reporting paragraph**

In step 4, append to the existing sentence:

```markdown
The cap counts **completed (built)** tasks; **parked tasks do not count against it** (they are never built), and parked tasks contribute zero to the cumulative blast-radius tally. Parked tasks are also **excluded from every autonomous continuation batch** (no longer manifestly all-no; they return only through individual Plan Approval), so re-syncing cannot launder a high-risk task back into autonomy. If **3 or more parked tasks are outstanding**, the leader **declines to grant a further autonomous batch** until the human clears the parked backlog.
```

Then add a new paragraph immediately after step 4:

```markdown
**Parked-set reporting (`skip-and-park` only).** When a task is parked, the leader **immediately** writes one line to `.orbit/notifications.log`: `PARKED <task-id> — trigger: <T1|T2|T3|T4|ambiguous> — next: individual Plan Approval + critic`. This per-park line is written at the moment of parking (not deferred to batch end) so the parked record survives an abnormal loop termination. At batch end the leader's re-sync report additionally includes a consolidated **Parked Tasks** section listing, per parked task: task ID, the firing trigger (or "ambiguous"), and the recommended next action (individual Plan Approval with the critic branch). No new file or channel is introduced — `.orbit/notifications.log` and the existing re-sync report are reused.
```

- [ ] **Step 5.5: Edit the `Failure rollback` paragraph to scope isolate-and-continue (BLOCKER-1)**

The existing `**Failure rollback.**` paragraph ends with *"The loop is halt-on-first-failure, not isolate-and-continue."* — which would contradict skip-and-park's "park-and-continue" unless scoped. Replace that final sentence:

Old:
```markdown
The loop is halt-on-first-failure, not isolate-and-continue.
```
New:
```markdown
The loop is **halt-on-first-failure** for *verification* failures under **both** execution profiles: a built task that fails Triple Crown ② or ③ always halts the loop and never park-and-continues. "Isolate-and-continue" applies **only** to the `skip-and-park` *gate path* (a high-risk/ambiguous task ejected **before** it is built); it never applies to a post-build verification failure. The two ejection causes are deliberately distinct: gate-path = defer un-built work (parkable under skip-and-park); verification failure = stop on broken built code (always halts).
```

- [ ] **Step 6: Run the surface invariant check**

Run:
```bash
grep -c 'skip-and-park' plugins/orbit-base/agents/leader.md && \
grep -c 'never auto-decided or auto-implemented' plugins/orbit-base/agents/leader.md && \
grep -c 'Parked Tasks' plugins/orbit-base/agents/leader.md && \
grep -ci 'affirmatively clear|positively established' plugins/orbit-base/agents/leader.md && \
grep -ci 'halt-on-first-failure' plugins/orbit-base/agents/leader.md && \
grep -ci 'parked.*outstanding|3 or more parked' plugins/orbit-base/agents/leader.md
```
Expected: all six counts ≥ `1` (park profile, non-weakening clause, reporting section, fail-closed predicate, surviving halt-on-first-failure clause, parked-backlog cap).

Also confirm the **pre-existing conservative-default line survived** (C12b depends on it):
```bash
grep -ciE 'ambigu.*stop|ambigu.*halt|manifestly all-no' plugins/orbit-base/agents/leader.md
```
Expected: ≥ `1` (the original "ambiguous ⇒ stop" wording is kept; park is added alongside, not as a replacement).

- [ ] **Step 7: Domain-purity grep + commit**

```bash
grep -riE 'oremi|orbit-dev' plugins/orbit-base/agents/leader.md; echo "exit=$?"
git add plugins/orbit-base/agents/leader.md
git commit -m "feat(base): skip-and-park loop semantics, fail-closed staleness, parked-backlog cap, scoped failure-rollback in leader.md"
```
Expected grep: no output, `exit=1`.

---

## Task 3: SKILL.md (S3) — orientation prose + Quick Reference row

**Files:**
- Modify: `plugins/orbit-base/skills/using-orbit/SKILL.md` — `### Optional Mode: Autonomous Loop` (line ~56) and `## Quick Reference` Autonomous Mode row (line ~150)

**Interfaces:**
- Consumes: D1 profile names + D5 non-weakening clause from Task 1.
- Produces: orientation-level summary (no new contract facts).

- [ ] **Step 1: Failing check**

Run:
```bash
grep -c 'skip-and-park' plugins/orbit-base/skills/using-orbit/SKILL.md
```
Expected now: `0`.

- [ ] **Step 2: Append two sentences to the Optional Mode: Autonomous Loop paragraph**

At the end of the `### Optional Mode: Autonomous Loop (opt-in, default off)` paragraph (after the existing final sentence "Triple Crown is never lightened."), append:

```markdown
The batch pre-approval also picks one of two **execution profiles**: `halt-on-trigger` (default — any ejection halts the whole loop) or the opt-in `skip-and-park` (the ejected task is **parked** and the loop continues with remaining low-risk tasks, with the parked set reported to the human at batch end). `skip-and-park` is **not** a weaker gate: a parked high-risk or ambiguous task is **never auto-decided or auto-implemented** — it returns to individual Plan Approval with the critic branch. "ambiguous ⇒ park" is the same prohibition as "ambiguous ⇒ stop"; only the scope of the pause differs (one task vs. the whole loop).
```

- [ ] **Step 3: Update the Quick Reference Autonomous Mode row**

Replace the existing Autonomous Mode row in `## Quick Reference`:

Old:
```markdown
| Autonomous Mode | Opt-in (default off): critic screens a finite low-risk batch on entry; user pre-approves once; leader loops with cumulative blast-radius + batch cap; any four-trigger firing or ambiguity halts the loop for individual approval |
```
New:
```markdown
| Autonomous Mode | Opt-in (default off): critic screens a finite low-risk batch on entry; user pre-approves once, picking a profile — `halt-on-trigger` (default: any ejection halts the loop) or `skip-and-park` (eject = park one task, loop continues, parked set reported at batch end); under both, a high-risk/ambiguous task is never auto-decided/auto-implemented (individual approval + critic); cumulative blast-radius + batch cap count built tasks only |
```

- [ ] **Step 4: Surface check + domain-purity + commit**

Run:
```bash
grep -c 'skip-and-park' plugins/orbit-base/skills/using-orbit/SKILL.md && \
grep -c 'never auto-decided or auto-implemented' plugins/orbit-base/skills/using-orbit/SKILL.md
grep -riE 'oremi|orbit-dev' plugins/orbit-base/skills/using-orbit/SKILL.md; echo "exit=$?"
```
Expected: first two counts ≥ `1`; grep no output, `exit=1`.

```bash
git add plugins/orbit-base/skills/using-orbit/SKILL.md
git commit -m "feat(base): document skip-and-park profile in using-orbit SKILL orientation + quick reference"
```

---

## Task 4: orbit-cycle.md (S4) — Korean command mirror

**Files:**
- Modify: `plugins/orbit-base/commands/orbit-cycle.md` — `## (선택) 자율 모드 — 묶음 선승인` (lines ~157–175) and `## 유의사항` (lines ~197–201)

**Interfaces:**
- Consumes: D1–D6 contract; expresses them in Korean consistent with S1/S2.
- Produces: command-level mirror. The literal anchor `skip-and-park` (kept in English even in Korean prose) and `유의사항` park note.

- [ ] **Step 1: Failing check**

Run:
```bash
grep -c 'skip-and-park' plugins/orbit-base/commands/orbit-cycle.md
```
Expected now: `0`.

- [ ] **Step 2: Add profile selection to 묶음 선승인 입력**

After the `**묶음 선승인 입력:**` paragraph, insert:

```markdown
**실행 프로파일 선택(선승인 시 고정):** 묶음 선승인은 두 프로파일 중 하나를 고정한다. `halt-on-trigger`(기본 — 작업이 제외되면 전체 루프 정지) 또는 opt-in `skip-and-park`(제외된 작업은 **격리(park)**되고 남은 저위험 작업으로 루프가 계속된다; 격리 목록은 배치 끝에서 사람에게 보고). 사용자가 프로파일을 명시하지 않으면 `halt-on-trigger`. 프로파일은 배치 동안 고정이며 루프 중간에 바꿀 수 없다.
```

- [ ] **Step 3: Add the park branch to 자율 루프 step 2**

In the 자율 루프 step 2, the bullet `- **하나라도 발화 또는 판정이 모호...`, append:

```markdown
 — `halt-on-trigger`(기본): 해당 작업을 제외하고 루프 정지 후 critic 게이트 + 개별 승인. `skip-and-park`: 해당 작업을 **격리(park)**하고 루프는 남은 저위험 작업으로 **계속**한다. 두 경우 모두 격리/제외된 작업은 **자동 결정·자동 구현되지 않는다** — 개별 Plan Approval(critic 분기 포함)로 간다. 격리는 한 작업만 미루는 것이며 게이트를 약화하지 않는다("모호 ⇒ 격리"는 그 작업에 대해 "모호 ⇒ 정지"와 동일한 금지).
```

- [ ] **Step 4: Add FAIL-CLOSED premise-mutator to step 3 and cap + backlog clarification to step 4**

In step 3 sub-item (a) (범위 재검증), append (fail-closed — 독립성이 입증돼야만 빌드):
```markdown
 `skip-and-park`에서 **격리된 작업은 코드 흔적 없는 전제 변경자**다(빌드되지 않았으므로 diff로 결합을 탐지할 수 없고 추론만 가능). 따라서 판정은 **fail-closed**다: 대기 작업은 **모든 격리 작업으로부터의 독립성이 명확히 입증될 때만** 자율 빌드 대상이며, 독립성을 **확정할 수 없으면** 그 대기 작업도 **격리**한다(불확실한 결합 ⇒ 모호 ⇒ 격리). over-park 쪽으로 편향한다. 잔여 위험(리드가 독립성을 잘못 "명확"으로 판정하는 false negative)이 park가 halt 동치가 아니라 **조건부** 안전인 이유다.
```

In step 4, append:
```markdown
 상한·누적 blast radius는 **완료(빌드)된 작업만** 센다. 격리된 작업은 빌드되지 않으므로 상한 슬롯을 소비하지 않고 누적 컴포넌트 집계에 0을 기여한다. 격리된 작업은 **모든 자율 연속 배치에서 제외**된다(더는 명백한 all-no가 아님 — 개별 Plan Approval로만 복귀). 따라서 재동기화로 고위험 작업을 자율에 세탁해 넣을 수 없다. **격리 작업이 3건 이상 미해결**이면 리드는 사람이 격리 백로그를 해소할 때까지 **추가 자율 배치를 거절**한다.
```

- [ ] **Step 5: Add reporting (immediate per-park) + 유의사항 notes**

After step 4, add:
```markdown
**격리 목록 보고(`skip-and-park` 전용):** 작업이 격리되면 리드는 **즉시** `.orbit/notifications.log`에 한 줄을 쓴다: `PARKED <작업ID> — trigger: <T1|T2|T3|T4|ambiguous> — next: 개별 Plan Approval + critic`. 이 per-park 기록은 격리 시점에 쓰여(배치 끝까지 미루지 않음) 비정상 종료에도 격리 기록이 남는다. 배치 끝의 재동기화 보고에 **격리된 작업** 섹션을 추가한다(작업ID, 발화 트리거 또는 "모호", 권장 다음 행동=개별 Plan Approval+critic). 새 파일·채널은 만들지 않는다.
```

In `## 유의사항`, add two new bullets:
```markdown
- **skip-and-park은 per-task 게이트 약화 아님**: opt-in `skip-and-park`는 고위험·모호 작업을 격리(미룸)할 뿐, 자동 결정·자동 구현하지 않는다. 격리된 작업은 개별 Plan Approval(critic 분기)로 처리된다. 기본값은 `halt-on-trigger`. 단, park는 형제 작업을 계속 돌리므로 **whole-loop 안전은 halt 동치가 아니라 조건부**(fail-closed 독립성 판정에 의존)다.
- **검증 실패는 두 프로파일 모두 정지**: Triple Crown ②/③ 실패는 `skip-and-park`에서도 park-and-continue가 아니라 루프 정지(halt-on-first-failure)다. isolate-and-continue는 **빌드 전 게이트 경로**에만 적용된다.
```

- [ ] **Step 6: Surface check + domain-purity + commit**

Run:
```bash
grep -c 'skip-and-park' plugins/orbit-base/commands/orbit-cycle.md && \
grep -c 'PARKED' plugins/orbit-base/commands/orbit-cycle.md && \
grep -ci 'fail-closed' plugins/orbit-base/commands/orbit-cycle.md && \
grep -ci 'halt-on-first-failure' plugins/orbit-base/commands/orbit-cycle.md
grep -riE 'oremi|orbit-dev' plugins/orbit-base/commands/orbit-cycle.md; echo "exit=$?"
```
Expected: all four counts ≥ `1`; grep no output, `exit=1`. (Note: `oremi|orbit-dev` grep excludes `skip-and-park`'s English term and the existing Korean text — both clean.)

```bash
git add plugins/orbit-base/commands/orbit-cycle.md
git commit -m "feat(base): mirror skip-and-park (fail-closed staleness, backlog cap, scoped failure-rollback) in orbit-cycle command"
```

---

## Task 5: codex-tools.md (S5) — degradation note

**Files:**
- Modify: `plugins/orbit-base/skills/using-orbit/references/codex-tools.md` — `## Autonomous Mode (opt-in)` (line ~78–80)

**Interfaces:**
- Consumes: D1 profile names.
- Produces: Codex degradation note (no new contract facts).

- [ ] **Step 1: Failing check**

Run:
```bash
grep -c 'skip-and-park' plugins/orbit-base/skills/using-orbit/references/codex-tools.md
```
Expected now: `0`.

- [ ] **Step 2: Append one sentence to the Autonomous Mode paragraph**

After the existing paragraph in `## Autonomous Mode (opt-in)`, append:

```markdown
Both execution profiles apply identically under Codex's serial loop: `halt-on-trigger` (default) stops the loop on the first ejection; opt-in `skip-and-park` parks the ejected task and continues serially through the remaining low-risk tasks, reporting the parked set at batch end. Only throughput is sequential — the four-trigger gate, the "never auto-decided or auto-implemented" guarantee for parked tasks, and full Triple Crown are unchanged.
```

- [ ] **Step 3: Surface check + domain-purity + commit**

Run:
```bash
grep -c 'skip-and-park' plugins/orbit-base/skills/using-orbit/references/codex-tools.md
grep -riE 'oremi|orbit-dev' plugins/orbit-base/skills/using-orbit/references/codex-tools.md; echo "exit=$?"
```
Expected: count ≥ `1`; grep no output, `exit=1`.

```bash
git add plugins/orbit-base/skills/using-orbit/references/codex-tools.md
git commit -m "feat(base): note skip-and-park profile in codex degradation reference"
```

---

## Task 6: gemini-tools.md (S6) — degradation note

**Files:**
- Modify: `plugins/orbit-base/skills/using-orbit/references/gemini-tools.md` — `## Autonomous Mode (opt-in)` (line ~74–76)

**Interfaces:**
- Consumes: D1 profile names.
- Produces: Gemini degradation note (no new contract facts).

- [ ] **Step 1: Failing check**

Run:
```bash
grep -c 'skip-and-park' plugins/orbit-base/skills/using-orbit/references/gemini-tools.md
```
Expected now: `0`.

- [ ] **Step 2: Append one sentence to the Autonomous Mode paragraph**

After the existing paragraph in `## Autonomous Mode (opt-in)`, append:

```markdown
The human still grants the batch pre-approval once, now also selecting one of two execution profiles: `halt-on-trigger` (default — the manual sequential loop stops on the first ejection) or opt-in `skip-and-park` (the ejected task is parked and the role-switching loop continues through the remaining low-risk tasks, with the parked set reported at batch end). Under both, a parked high-risk or ambiguous task is **never auto-decided or auto-implemented** — it returns to individual Plan Approval with the critic branch; the four-trigger gate and full Triple Crown are unchanged.
```

- [ ] **Step 3: Surface check + domain-purity + commit**

Run:
```bash
grep -c 'skip-and-park' plugins/orbit-base/skills/using-orbit/references/gemini-tools.md
grep -riE 'oremi|orbit-dev' plugins/orbit-base/skills/using-orbit/references/gemini-tools.md; echo "exit=$?"
```
Expected: count ≥ `1`; grep no output, `exit=1`.

```bash
git add plugins/orbit-base/skills/using-orbit/references/gemini-tools.md
git commit -m "feat(base): note skip-and-park profile in gemini degradation reference"
```

---

## Task 6.5: Extend the canonical regression harness with C15 (BLOCKER-2)

**Files:**
- Modify: `.planning/verify-autonomous-mode.sh` — add C15 checks before the final `exit $fail`. **Dev asset — deliberately outside the six-file `plugins/orbit-base/` set-diff boundary.**

**Interfaces:**
- Consumes: the anchor strings landed by Tasks 1–4 (`skip-and-park`, `halt-on-trigger`, `never auto-decided or auto-implemented`, `Parked Tasks`/`격리된 작업`, `halt-on-first-failure`).
- Produces: C15 assertions that future edits cannot silently drop skip-and-park's invariants. (C1–C14 are unchanged; they are *re-run*, not modified.)

- [ ] **Step 1: Confirm C1–C14 still pass on the edited surfaces BEFORE adding C15**

This proves the park edits did not regress any prior invariant (the core BLOCKER-2 worry — esp. C4a `halt|eject`, C7 `withdraw|task boundary`, C12b `ambigu.*stop|ambigu.*halt|manifestly all-no`).

Run:
```bash
bash .planning/verify-autonomous-mode.sh; echo "exit=$?"
```
Expected: every `C1`–`C14` line prints `PASS`, `exit=0`. If any prior check FAILs, a park edit broke a kept invariant — fix the surface (e.g. you replaced the "ambiguous ⇒ stop" line instead of adding park alongside it) before proceeding.

- [ ] **Step 2: Add the C15 skip-and-park block before `exit $fail`**

Insert immediately before the final `exit $fail` line:

```bash
# C15 skip-and-park profile invariants (added with the skip-and-park feature)
# C15a both profiles named in CLAUDE.md and leader.md
chk "C15a CLAUDE profiles named" "grep -qi 'skip-and-park' \"\$BASE/CLAUDE.md\" && grep -qi 'halt-on-trigger' \"\$BASE/CLAUDE.md\""
chk "C15b leader profiles named" "grep -qi 'skip-and-park' \"\$BASE/agents/leader.md\" && grep -qi 'halt-on-trigger' \"\$BASE/agents/leader.md\""
# C15c park never weakens the gate: non-weakening clause present wherever skip-and-park is described
for f in CLAUDE.md agents/leader.md skills/using-orbit/SKILL.md commands/orbit-cycle.md skills/using-orbit/references/codex-tools.md skills/using-orbit/references/gemini-tools.md; do
  chk "C15c $f park-with-guard" "! grep -qi 'skip-and-park' \"\$BASE/$f\" || grep -qiE 'never auto-decided or auto-implemented|never auto-decided/auto-implemented|자동 결정.{0,4}자동 구현되지 않' \"\$BASE/$f\""
done
# C15d failure-rollback halt survives in leader.md and is no longer unconditional isolate-and-continue
chk "C15d leader halt-on-first-failure kept" "grep -qi 'halt-on-first-failure' \"\$BASE/agents/leader.md\""
chk "C15e leader isolate scoped to gate path" "! grep -qiE 'isolate-and-continue' \"\$BASE/agents/leader.md\" || grep -qiE 'gate path|gate-path|before it is built|verification failure.*halt' \"\$BASE/agents/leader.md\""
# C15f amortization: parked-backlog cap stated in CLAUDE.md
chk "C15f CLAUDE parked-backlog cap" "grep -qiE '3 or more parked|parked.{0,30}outstanding|declines.{0,40}autonomous batch' \"\$BASE/CLAUDE.md\""
# C15g fail-closed staleness predicate stated in leader.md
chk "C15g leader fail-closed staleness" "grep -qiE 'affirmatively clear|positively established|fail-closed' \"\$BASE/agents/leader.md\""
```

- [ ] **Step 3: Run the full extended suite**

Run:
```bash
bash .planning/verify-autonomous-mode.sh; echo "exit=$?"
```
Expected: all `C1`–`C15g` lines `PASS`, `exit=0`.

- [ ] **Step 4: Commit (dev-asset commit, separate from the distributable commits)**

```bash
git add .planning/verify-autonomous-mode.sh
git commit -m "test(planning): extend autonomous-mode contract harness with C15 skip-and-park invariants"
```

---

## Task 7: Cross-surface invariant + set-diff verification (final gate)

**Files:**
- Test only (no file modified). This task asserts the whole change is consistent and bounded.

**Interfaces:**
- Consumes: all six edited distributable surfaces (Tasks 1–6) + the extended harness (Task 6.5).
- Produces: pass/fail evidence for the four verification classes.

- [ ] **Step 0: Re-run the full canonical + extended harness (C1–C15)**

Run:
```bash
bash .planning/verify-autonomous-mode.sh; echo "exit=$?"
```
Expected: all `C1`–`C15g` lines `PASS`, `exit=0`. (BLOCKER-2 evidence: prior invariants survived AND new ones hold.)

- [ ] **Step 1: Invariant harness — every skip-and-park surface carries the non-weakening guard**

Run this reverse-check (the load-bearing test). For each surface that mentions `skip-and-park`, it must also contain the non-weakening guard phrase. The 6-spoke/7-full surfaces use the full phrase; degradation refs use it too (codex/gemini sentences include "never auto-decided or auto-implemented" or, for codex, the explicit guarantee clause):

```bash
for f in \
  plugins/orbit-base/CLAUDE.md \
  plugins/orbit-base/agents/leader.md \
  plugins/orbit-base/skills/using-orbit/SKILL.md \
  plugins/orbit-base/commands/orbit-cycle.md \
  plugins/orbit-base/skills/using-orbit/references/codex-tools.md \
  plugins/orbit-base/skills/using-orbit/references/gemini-tools.md ; do
  if grep -q 'skip-and-park' "$f"; then
    if grep -qiE 'never auto-decided or auto-implemented|자동 결정.?자동 구현되지 않|never auto-decided/auto-implemented' "$f"; then
      echo "PASS  $f"
    else
      echo "FAIL (park without guard)  $f"
    fi
  else
    echo "FAIL (no skip-and-park)  $f"
  fi
done
```
Expected: `PASS` for all six files. Any `FAIL` blocks completion.

- [ ] **Step 2: Reverse invariant — no surface auto-builds high-risk**

Confirm no surface contains language permitting an ambiguous/high-risk task to proceed autonomously. This grep should find **zero** forbidden phrasings:

```bash
grep -rniE 'ambiguous.{0,20}(proceed|continue|build|auto)' plugins/orbit-base/ | grep -viE 'never|not|아님|않' || echo "OK: no ambiguous-proceed language"
```
Expected: `OK: no ambiguous-proceed language` (every ambiguous-mention is negated).

- [ ] **Step 3: Failure-rollback survival check (BLOCKER-1)**

Confirm the existing `halt-on-first-failure` invariant survived the park edits and that any `isolate-and-continue` mention is now scoped to the gate path:

```bash
grep -ni 'halt-on-first-failure' plugins/orbit-base/agents/leader.md
# isolate-and-continue, if present, must co-occur with a gate-path / verification-failure scoping
grep -niE 'isolate-and-continue' plugins/orbit-base/agents/leader.md && \
grep -qiE 'gate path|gate-path|before it is built|verification failure' plugins/orbit-base/agents/leader.md && \
echo "OK: isolate-and-continue scoped" || echo "OK: isolate-and-continue absent or scoped"
```
Expected: `halt-on-first-failure` present (≥1 line); scoping confirmed. A bare unconditional "halt-on-first-failure, not isolate-and-continue" replaced by park-and-continue without scoping is a BLOCKER-1 regression.

- [ ] **Step 4: Domain-purity sweep (whole distributable)**

```bash
grep -riE 'oremi|orbit-dev' plugins/orbit-base/; echo "exit=$?"
```
Expected: no output, `exit=1`.

- [ ] **Step 5: Set-diff surface check — exactly the six distributable files changed**

```bash
git diff --name-only main -- plugins/orbit-base/ | sort
```
Expected exactly (and only) these six lines:
```
plugins/orbit-base/CLAUDE.md
plugins/orbit-base/agents/leader.md
plugins/orbit-base/commands/orbit-cycle.md
plugins/orbit-base/skills/using-orbit/SKILL.md
plugins/orbit-base/skills/using-orbit/references/codex-tools.md
plugins/orbit-base/skills/using-orbit/references/gemini-tools.md
```
(If `critic.md`, `reviewer.md`, a manifest, or any `.orbit/` path appears under `plugins/orbit-base/`, the change exceeded its design boundary — investigate before declaring complete.)

- [ ] **Step 6: Confirm the harness edit landed OUTSIDE the plugins boundary (in `.planning/`)**

The Task 6.5 harness edit must show up under `.planning/`, **not** under `plugins/orbit-base/`:
```bash
git diff --name-only main -- .planning/verify-autonomous-mode.sh
git diff --name-only main -- plugins/orbit-base/ | grep -c 'verify-autonomous-mode' || echo "OK: harness not in plugins boundary"
```
Expected: first command lists `.planning/verify-autonomous-mode.sh`; second prints `OK: harness not in plugins boundary` (count 0). This proves the dev asset stayed off the six-file distributable surface.

- [ ] **Step 7: No new files under the distributable**

```bash
git status --porcelain plugins/orbit-base/ | grep -E '^\?\?' || echo "OK: no new untracked files under orbit-base"
```
Expected: `OK: no new untracked files under orbit-base` (zero-new-infrastructure honored for the shipped plugin).

- [ ] **Step 8: Record verification evidence (no commit needed — verification only)**

Paste the Step 0–7 outputs into the task's completion report. This is the Triple Crown ① completeness + ③ quality evidence for the contract change. (② behavior for a prose contract = the C1–C15 harness + reverse-invariant outputs above; there is no runtime to exercise.)

---

## Self-Review

**1. Spec coverage (the 7 questions + 8 critic findings):**
- D1 (auto-halt relationship / two profiles) → Tasks 1,2,3,4,5,6 (every surface).
- D2 (T2 built-only **+ amortization guard / parked-backlog cap — MAJOR-3**) → Task 1 step 2 (accounting + amortization), Task 2 step 5, Task 4 step 4.
- D3 (cap counts built only) → Task 1 step 2, Task 2 step 5, Task 4 step 4.
- D4 (staleness — **fail-closed predicate, MAJOR-4**) → Task 2 step 4, Task 4 step 4.
- D5 (**conditional-safety, honest equivalence — MAJOR-5**) → Tasks 1,2,3,4,5,6 (non-weakening clause + conditional-safety note).
- D6 (reporting format — **immediate per-park write, MINOR-7**) → Task 2 step 5, Task 4 step 5.
- D7 (unattended = pre-approval option, no detector) → Task 1/2/4 profile-selection wording. Recorded in Design Decisions.
- **BLOCKER-1 (failure-rollback contradiction)** → Task 2 step 5.5 (scope isolate-and-continue to gate path; halt-on-first-failure kept for verification failures); Task 7 step 3 survival check; C15d/C15e.
- **BLOCKER-2 (C1–C14 harness)** → Task 6.5 (re-run C1–C14 + add C15); Task 7 step 0; the harness is a `.planning/` dev asset (Task 7 step 6 confirms it stays off the six-file boundary).
- **MAJOR-6 (alternative comparison)** → "Alternatives Considered and Rejected" section (Alternative A = current halt + manual resume, rejected on the explicit 2026-06-20 user requirement; Alternative B rejected as unsafe).
- **MINOR-8 (③ deep-mode adjacency)** → noted in Touched Surfaces; no contradiction, out of scope, no reviewer.md edit.
- Touched-surface list → "Touched Surfaces" table (6 distributable + 1 dev-asset) + Task 7 set-diff.
- Measurable success criteria → below. High-risk self-diagnosis → below.

**2. Placeholder scan:** No "TBD/TODO/handle edge cases" — every edit step contains the literal text to insert. Verified.

**3. Consistency:** Anchor strings `skip-and-park`, `halt-on-trigger`, `never auto-decided or auto-implemented`, `PARKED`, `Parked Tasks`, `halt-on-first-failure`, `fail-closed`, `affirmatively clear` are used identically across tasks and asserted by C15 (Task 6.5) and the Task 7 reverse-invariant. The `.orbit/notifications.log` channel and the re-sync report are the only reporting sinks (no new channel) — consistent with D6 and the zero-infra constraint. The pre-existing "ambiguous ⇒ stop" line is **kept** (park added alongside), so C12 stays green.

---

## Measurable Success Criteria

1. **Canonical harness green (BLOCKER-2):** `bash .planning/verify-autonomous-mode.sh` → all `C1`–`C15g` `PASS`, `exit=0` (Task 7 Step 0). Prior C1–C14 invariants survived; C15 skip-and-park invariants hold.
2. All six surfaces (S1–S6) contain `skip-and-park`; Task 7 Step 1 prints `PASS` for all six.
3. Every skip-and-park-mentioning surface also carries the non-weakening guard (Task 7 Step 1 = 6×PASS; reverse "no ambiguous-proceed language" = OK).
4. **Failure-rollback preserved (BLOCKER-1):** `halt-on-first-failure` present in leader.md and `isolate-and-continue` scoped to the gate path (Task 7 Step 3; C15d/C15e).
5. **Amortization guard (MAJOR-3):** CLAUDE.md states the parked-backlog cap (≥3 parked ⇒ decline further batch) and parked-tasks-excluded-from-continuation (C15f).
6. **Fail-closed staleness (MAJOR-4):** leader.md states "independence affirmatively clear else park" (C15g).
7. `grep -riE 'oremi|orbit-dev' plugins/orbit-base/` → 0 matches (Task 7 Step 4, `exit=1`).
8. `git diff --name-only main -- plugins/orbit-base/` lists exactly the six files — no manifest, no `critic.md`, no `reviewer.md`, no `.orbit/` (Task 7 Step 5); the harness edit is confined to `.planning/` (Task 7 Step 6).
9. No new untracked files under `plugins/orbit-base/` (Task 7 Step 7) — zero-new-infrastructure honored for the shipped plugin.
10. Default behavior preserved: `halt-on-trigger` stated as default in S1, S2, S3, S4.

---

## High-Risk Four-Trigger Self-Diagnosis (input to the critic gate)

This change touches the human-gate / autonomous contract, so high-risk is expected. Per-trigger:

| Trigger | Fires? | Why |
|---------|--------|-----|
| **T1 Irreversibility** | **borderline / soft-yes** | Prose-only and git-revertible per file, so technically reversible. But it alters a *published behavioral contract* that downstream users may rely on; "undoing" after adoption means a contract change, not just a code revert. Treat as a contract-surface change, not a free rollback. |
| **T2 Blast radius** | **YES** | Touches **6 files** across the orbit-base distributable (well over the 3-component threshold) and modifies a **public, user-facing contract** (Autonomous Mode semantics). Unambiguous T2 firing. |
| **T3 Security / integrity** | **NO** | No auth/permissions/secrets/deletion/money/PII path. Note however: the change is *adjacent to* a safety invariant (the human gate). Not a T3 security surface, but its safety-criticality is why critic review is warranted on T1/T2 alone. |
| **T4 New external dependency** | **NO** | Zero new runtime deps, hooks, state files, or external services — by explicit constraint. |

**Verdict: HIGH-RISK (T2 fires unambiguously; T1 soft-fires).** This is a re-submission after a REVISE (2 BLOCKER + 4 MAJOR + 2 MINOR), all addressed above. Recommend the leader route this revised plan through the **critic gate** for re-review before Plan Approval.

**Disposition of the prior findings (for the critic's re-review):**
- **BLOCKER-1 (failure-rollback contradiction)** → resolved: Task 2 step 5.5 scopes "isolate-and-continue" to the gate path only and reaffirms `halt-on-first-failure` for verification failures under both profiles; Task 7 step 3 + C15d/C15e verify it.
- **BLOCKER-2 (C1–C14 harness omitted)** → resolved: Task 6.5 re-runs C1–C14 and adds C15; Task 7 step 0 runs the full suite. Park edits keep C4a/C7/C12 green by *adding* park alongside the kept "ambiguous ⇒ stop" line, never replacing it.
- **MAJOR-3 (amortization)** → resolved: parked tasks excluded from continuation batches + parked-backlog cap (≥3 ⇒ decline) in D2/Task 1.
- **MAJOR-4 (D4 false-negative)** → resolved: predicate inverted to fail-closed (build only if independence affirmatively clear; uncertainty ⇒ park), residual risk named.
- **MAJOR-5 (D5 honesty)** → resolved: restated as *conditional* whole-loop safety (parked-task invariant is exact; sibling safety depends on D4), not halt-equivalence.
- **MAJOR-6 (alternative comparison)** → resolved: Alternatives section compares/rejects "halt + manual resume" on the explicit user requirement.
- **MINOR-7 (abnormal-exit reporting)** → resolved: per-park notifications.log line written *immediately* at park time.
- **MINOR-8 (③ deep-mode adjacency)** → noted; no contradiction (a T3 task is gated out under both profiles, never built in-loop), out of scope.

**Critic should re-verify:** (a) the fail-closed predicate (D4) truly biases toward over-parking and the residual false-negative is honestly bounded; (b) the parked-backlog cap + continuation-exclusion (D2) actually closes the cross-re-sync amortization path; (c) the D5 "conditional safety" wording is now accurate, not over- or under-claiming; (d) the BLOCKER-1 scoping reads unambiguously (gate-path park vs. verification-failure halt are not conflatable).
