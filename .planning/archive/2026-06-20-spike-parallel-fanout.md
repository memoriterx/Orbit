# PERF-1 — Parallel Fan-out/Fan-in Pattern Formalization (Comparison Spike)

> **Spike, not an implementation plan.** This document compares options and recommends one; it does NOT pre-commit to building any option. No code, no contract edits. The leader runs the normal lifecycle (Plan Approval → builder) *only after* picking an option from this spike.

**Type:** Option-comparison design spike (PERF-1)
**Author:** architect
**Date:** 2026-06-20
**Status:** awaiting leader synthesis + user direction

---

## Pool Question

> "How (or whether) do we formalize the leader running several independent agents concurrently and aggregating after all complete — without breaking orbit's thin philosophy, hub-and-spoke routing, or the human gate?"

## Background (verified against the codebase)

- The leader **already** dispatches independent agents concurrently in practice: `Agent(builder, background=True)` and `Agent(researcher, background)` are documented patterns (leader.md:122–127), and explore.md:22,45 already names a **"broad-to-narrow parallel fan-out"** *inside a single agent*. So "parallel" exists at two levels today: (a) intra-agent tool fan-out (explore), and (b) inter-agent background dispatch (leader) — but only (a) is named as a first-class pattern. Inter-agent concurrency is improvised; no contract says *when* it is safe.
- The hub-and-spoke contract is compatible with fan-out **by construction**: the leader is the sole aggregation point, and spokes never talk to each other. Fan-out/fan-in maps onto hub-and-spoke cleanly — the hub dispatches N spokes, the hub collects N results. Nothing in fan-in requires spoke-to-spoke communication.
- Researcher's external finding (2026 multi-agent standards): fan-out/fan-in is a standard orchestration pattern with ~36–50% wall-clock reduction on independent subtasks. This is a *throughput* claim, not a *capability* claim — orbit can already do it; the question is codification.

## Constraint Anchors (must not break)

| Anchor | Source | Why it constrains fan-out |
|--------|--------|---------------------------|
| Hub-and-spoke | SKILL.md:10–26, leader.md:19 | Fan-in aggregation must stay leader-only; no spoke merges another spoke's output. |
| Human gate (Plan Approval) | CLAUDE.md Plan Approval Gate; SKILL.md:58–66 | Parallelism must not blur *which* plan the human approved or *when*. |
| Thin philosophy | CLAUDE.md "Leader writes nothing"; roadmap "Thin Ledger" | No new schema/infra/state files unless load-bearing. |
| Domain purity | CLAUDE.md Domain Purity Rule; harness C1 | No project names; slots stay slots. |
| Autonomous-mode safety | CLAUDE.md Autonomous Mode; leader.md:88–109; harness C12–C15g | **★** Batch cap ≤5, cumulative T2, skip-and-park park-logic, fail-closed independence predicate (D4) must survive any concurrency claim. |

---

## ★ The Central Interaction: Parallelism vs. Autonomous-Mode Accounting

This is the axis that makes PERF-1 non-trivial, so it is treated up front; every option is later scored against it (axis 3).

The autonomous loop's safety rests on **sequential, observable accounting**:

1. **Cumulative T2 blast radius** (CLAUDE.md): "before each task the leader sums components already modified plus those the next task touches; ≥3 fires T2 and halts." This is a *running sum updated per task in order*. Concurrent builds would compute their component sets against a **stale tally** — two tasks each individually <3 could jointly cross the ceiling, but if dispatched together neither sees the other's contribution before committing. **Parallel builds break the monotonic cumulative invariant.**
2. **skip-and-park D4 fail-closed predicate** (leader.md:102): a pending task is autonomously buildable "only when its independence from every parked task is affirmatively clear." A *parked task is a premise-mutator with no code trace*. If two pending tasks run concurrently, each is also a premise-mutator with no code trace *to the other* until both diffs land — the same uncertainty D4 already fails closed on, now multiplied across the concurrent set.
3. **halt-on-first-failure** (leader.md:107): Triple Crown ②/③ failure must halt the loop. With N tasks in flight, a failure in task A cannot un-build tasks B, C already committed — "halt" loses its meaning mid-flight.

**Conclusion carried into the options:** concurrency is **safe for read-only/independent investigation** (explore, researcher, critic-screen — no diff, no cumulative tally, no commit) and **structurally unsafe for the autonomous *build* loop** (cumulative T2, D4, halt-on-failure all assume serial commit). Any option that lets autonomous *builds* run in parallel is a contract rewrite, not a codification. This boundary is the spine of the recommendation.

---

## Options (minimum 3 + 1 free addition)

### Option 0 — Status Quo (no codification)

Leave fan-out as leader discretion. No file changes. The leader improvises `background=True` dispatch when it judges tasks independent.

**Concrete form:** nothing written. Today's leader.md:122–127 dispatch table stays as-is.

- **Cost:** 0.
- **Limit (explicit):** (a) No independence-judgment guidance → improvisation risk; a leader may parallelize order-dependent work and get a race/merge-order bug. (b) No named "fan-in" aggregation discipline → a leader might let one agent's output seed another's prompt (a soft hub-and-spoke erosion) without a rule reminding it not to. (c) The ~36–50% wall-clock win is realized inconsistently (only when the leader happens to think of it). (d) The explore.md "parallel fan-out" name exists for *intra-agent* search but there is no *inter-agent* analogue, so the vocabulary is asymmetric and confusing.

### Option 1 — Lightweight Pattern Codification (prose only) ⭐ RECOMMENDED

Add a named **"Independent Fan-out → Fan-in"** pattern to SKILL.md and leader.md in *prose*, with: (a) an independence-judgment guide, (b) 2–3 worked examples, (c) an explicit carve-out that the autonomous *build* loop stays serial. **Zero new schema, infra, state, or commands.** It names and bounds a capability the leader already has.

**Concrete form (prose-level draft — illustrative, not final wording):**

In `SKILL.md`, a new short section after "Delegation Principle":

> ### Independent Fan-out → Fan-in (optional throughput pattern)
> When the leader has **two or more independent** units of work — no shared state, no output of one feeding another's input, no ordering dependency — it may dispatch them **concurrently** (e.g. `Agent(explore, background)` + `Agent(researcher, background)` at once) and aggregate all results once every branch returns. The leader remains the sole fan-in point: no spoke reads another spoke's output. This is hub-and-spoke unchanged — one hub, N spokes, one collection.
>
> **Independence test (all must hold):** (1) no branch writes state another branch reads; (2) no branch's prompt depends on another branch's result; (3) no required ordering between branches; (4) branches do not edit the same files. If any is unclear, **run them serially** (uncertain ⇒ serial — same fail-closed spirit as the autonomous gate).
>
> **Safe by default for read-only fan-out:** parallel investigation (explore + researcher), parallel independent reviews, and the two non-build Triple Crown reads where independent. **Not for autonomous builds:** the autonomous loop's per-task build stays **serial** — its cumulative blast-radius (T2), skip-and-park independence predicate, and halt-on-first-failure all assume one commit at a time. Fan-out parallelizes *investigation and review*, never the autonomous build sequence.

In `leader.md`, one line added to the Agent Dispatch Pattern block and a 4–6 line "Independent fan-out" note pointing at the SKILL section, plus an explicit "build loop stays serial" sentence in the Autonomous Loop section (append-only, preserving every C-check phrase).

- **Surfaces touched:** SKILL.md (+~14 lines), leader.md (+~8 lines). Optionally one Quick-Reference row. **2 files.**
- **New schema/infra:** 0.
- **Reversibility:** trivial (delete prose).

### Option 2 — Structural Parallel Orchestration

Introduce a formal mechanism: a parallel-group declaration with explicit dependency annotation (e.g. a `## Parallel Group` block in the roadmap or plan, task-level `depends-on:` / `group:` fields, a fan-in barrier the leader must record). The leader reads the declaration and dispatches groups concurrently per the dependency DAG.

**Concrete form (illustrative):**

```
## Parallel Group: G1 (fan-in barrier required)
- [ ] [PERF-1a] explore X      depends-on: —      group: G1
- [ ] [PERF-1b] research Y     depends-on: —      group: G1
- [ ] [PERF-1c] synthesize     depends-on: G1     group: —
```

Plus new prose in leader.md/SKILL.md/CLAUDE.md defining the barrier semantics, how groups interact with the autonomous cumulative tally, and a degradation story for Codex/Gemini.

- **Surfaces touched:** roadmap convention, leader.md, SKILL.md, CLAUDE.md, codex-tools.md, gemini-tools.md, critic.md (T2 now must account for concurrent component sets), orbit-cycle.md command. **~8 surfaces.**
- **New schema:** yes (task-level dependency fields + group/barrier vocabulary). This is a roadmap-format contract change.
- **Reversibility:** medium-hard (roadmaps written in the new format must be migrated or tolerated; contract consumers must keep parsing old + new).
- **Key hazard:** directly collides with the ★ autonomous accounting. A declared parallel *build* group forces a redefinition of cumulative T2 ("sum of all concurrent component sets, computed before dispatch") and of skip-and-park D4 ("independence across a concurrent set, not just against parked tasks") and of halt-on-first-failure ("halt = cancel in-flight siblings?"). Each is a real contract rewrite that the C12–C15g harness pins. This is the heaviest option and the one most likely to fire high-risk triggers.

### Option 3 (free addition) — Read-only Fan-out Only (scoped subset of Option 1)

Codify fan-out **exclusively for read-only/non-mutating agents** (explore, researcher, critic-on-entry screen, the read-only Triple Crown ③ review) and say *nothing* about build parallelism — leaving builds implicitly serial. This is Option 1 minus the autonomous-mode carve-out paragraph (because builds are simply never in scope).

**Concrete form:** identical prose to Option 1's SKILL section, but the "Not for autonomous builds" paragraph is replaced by a tighter scope statement: *"Fan-out applies only to read-only agents (explore, researcher) and independent reviews. Any agent that writes files or commits (builder) is always dispatched one at a time."* No mention of the autonomous loop's internals at all — so it cannot accidentally contradict a C-check phrase.

- **Surfaces touched:** SKILL.md (+~10 lines), leader.md (+~5 lines). **2 files.**
- **New schema/infra:** 0.
- **Reversibility:** trivial.
- **Trade vs Option 1:** lower blast radius on the autonomous contract (it never references the loop, so zero C12–C15g interaction surface), but it leaves a gap: it gives no guidance on the *non-build* parts of the autonomous loop or on parallel independent **reviews** of already-built diffs, and it does not state *why* builds stay serial — so a future reader may not understand the boundary is principled rather than incidental.

---

## Comparison Table (6 evaluation axes)

| Axis | Opt 0 Status Quo | Opt 1 Prose Codification ⭐ | Opt 2 Structural | Opt 3 Read-only Only |
|------|------------------|-----------------------------|------------------|----------------------|
| **1. Thin-philosophy fit** | Perfect (nothing added) but under-specified | High — prose only, names an existing capability, no infra | **Low** — adds roadmap schema + barrier vocabulary; ceremony orbit explicitly avoids | High — minimal prose, narrowest scope |
| **2. Blast radius (surfaces)** | 0 | **2 files** (SKILL, leader) | **~8 surfaces** incl. critic T2 + both degradation refs + command | **2 files** (SKILL, leader) |
| **3. ★ Autonomous-mode interaction** | Undefined — risk a leader parallelizes a build mid-loop and silently breaks cumulative T2 | **Explicitly fences builds serial** — preserves T2/D4/halt by stating they bound serially; codifies the safe boundary | **Collides hard** — forces redefining cumulative T2, D4 independence, halt-on-failure for concurrent builds; rewrites C12–C15g-pinned contract | **Sidesteps** — never references the loop; builds serial by the "writers dispatched one at a time" rule; zero C12–C15g surface |
| **4. Independence judgment** | None (improvised) | **4-point test, uncertain⇒serial** (mirrors D4 fail-closed) | Formalized as `depends-on:` DAG — more precise but heavier; mis-annotation = silent race | Same 4-point test, but only for read-only branches (lower stakes if wrong) |
| **5. Hub-and-spoke + human gate** | Preserved but un-reminded (soft erosion risk) | **Preserved + reinforced** ("leader sole fan-in", gate unchanged) | Preserved but the barrier/group adds a place the gate timing could blur (when is a *group* approved — per task or per group?) | **Preserved + reinforced**, narrowest |
| **6. Domain-agnostic / reversibility / cost** | Agnostic; fully reversible; cost 0 | Agnostic (no project names); trivially reversible; **low cost** | Agnostic but roadmap-format change risks migration; medium-hard reversibility; **high cost** | Agnostic; trivially reversible; lowest cost |

---

## Recommendation: **Option 1 (Lightweight Prose Codification)**

### Rationale
1. **It codifies a capability orbit already has** rather than adding one. The leader already background-dispatches independent agents; Option 1 just *names* the pattern, supplies an independence test, and draws the one boundary that matters (builds stay serial). That is the definition of thin.
2. **It closes the real gap in Option 0** — the missing independence-judgment guide and the missing "leader is sole fan-in" reminder — at a 2-file cost.
3. **It is the only option that explicitly protects the ★ autonomous invariants** by stating them as serial-bounded. Option 0 leaves them exposed to improvisation; Option 2 actively rewrites them; Option 3 protects them by silence (weaker, because the boundary is undocumented).
4. **Reuses existing vocabulary** — explore.md already says "parallel fan-out" for intra-agent search; Option 1 extends the same term to inter-agent dispatch, making the vocabulary symmetric instead of asymmetric.
5. **~36–50% wall-clock win is captured where it is safe** (parallel investigation/review) without touching the build path where it is unsafe.

### Counter-argument (why one might NOT pick Option 1)
- **Prose can be ignored.** A codified-in-prose pattern has no enforcement (no hook, no harness check) — a leader can still improvise badly. If the team's actual pain is *enforcement* (leaders parallelizing unsafely), Option 1 does not fix it; only Option 2's structural DAG (or a new hook) would. The honest read: Option 1 bets the problem is *vocabulary and guidance*, not *enforcement*. If that bet is wrong, Option 1 under-delivers.
- **It may be solving a non-problem.** Option 0's only hard failure mode is a leader parallelizing order-dependent work — but there is no evidence in the codebase that this has happened. If the improvisation has been fine, the safest thin choice is Option 0 (do nothing) and revisit only on an observed incident. Option 1 is justified by *researcher's external standard* + *vocabulary asymmetry*, not by an observed orbit failure — that is a weaker warrant than a real incident, and a reasonable reviewer could prefer Option 0 until a fan-out bug is actually seen.
- **Boundary between Opt 1 and Opt 3:** if the team wants *zero* risk of contradicting a C12–C15g phrase, Option 3 is strictly safer (it never names the loop). Option 1's autonomous-carve-out paragraph is the one place it touches the pinned contract; it must be append-only and verified against the harness.

### If Option 1 is chosen — recommended fallback ordering
Option 1 → (if enforcement turns out to be the real need) revisit Option 2 with a concrete incident → Option 0 is the safe null. Do **not** jump to Option 2 without an observed unsafe-parallelism incident; its cost/reversibility is unjustified by current evidence.

---

## Touched-Surface List + Verification Strategy (for the recommended Option 1)

**Surfaces (if Option 1 is built later):**
- `plugins/orbit-base/skills/using-orbit/SKILL.md` — new "Independent Fan-out → Fan-in" section + optional Quick-Reference row.
- `plugins/orbit-base/agents/leader.md` — one dispatch-pattern line + a short fan-out note + a "build loop stays serial" sentence appended to the Autonomous Loop section (append-only).
- (Not touched by Opt 1: CLAUDE.md, critic.md, codex-tools.md, gemini-tools.md, orbit-cycle.md — Opt 1 deliberately stays off the autonomous-accounting and degradation surfaces. Opt 2 would touch all of these.)

**Verification strategy:**
1. **Domain-purity grep (C1):** `grep -rciE 'oremi|orbit-dev' plugins/orbit-base/` must stay 0; new prose uses slots/role names only, no project names.
2. **Autonomous-mode regression harness (C1–C15g):** run `.planning/verify-autonomous-mode.sh`. Option 1 is **append-only** to leader.md's Autonomous Loop section and adds an independent SKILL section — it must not alter any phrase the harness greps for. Critical checks to re-confirm green: **C5a/C5b** (leader-loop / hub-and-spoke literal), **C12** (ambiguous⇒stop — the fan-out independence test reuses the same "uncertain⇒serial" spirit and must not dilute the autonomous "ambiguous⇒stop" phrase), **C13** (cumulative T2 / cap — the "builds stay serial" sentence must reinforce, not reword, the cumulative-tally clause), **C15d/C15e** (halt-on-first-failure / isolate scoped to gate path — fan-out prose must not introduce a competing "parallel isolate" notion), **C15g** (fail-closed staleness — the independence test must read as consistent with, not a replacement for, D4). **Expected: all C1–C15g remain PASS** because Option 1 adds an orthogonal pattern and only *references* (never edits) the loop internals.
3. **Frontmatter integrity (C9):** leader.md edits stay below the frontmatter; name/description/model lines untouched.
4. **Manifest (C8):** no plugin.json change; stays valid JSON.
5. **New (recommended) assertion if built:** add a harness line asserting SKILL.md contains the fan-out section AND the "builds stay serial" boundary phrase, so a future edit cannot silently delete the build-serial fence. (This would be a C16-class addition — proposed, not part of this spike.)

---

## High-Risk Four-Trigger Self-Diagnosis (per option)

The leader applies this gate after picking an option; pre-computed here per the brief.

| Trigger | Opt 0 | Opt 1 ⭐ | Opt 2 | Opt 3 |
|---------|-------|---------|-------|-------|
| **T1 Irreversibility** (migration / rewrite / backward-compat break) | No | **No** (prose, deletable) | **YES** — roadmap-format change; existing roadmaps + parsers need migration/back-compat | No (prose, deletable) |
| **T2 Blast radius** (3+ components OR public-contract change) | No (0 surfaces) | **No** (2 files, no contract change) | **YES** — ~8 surfaces incl. the public autonomous contract (cumulative T2, D4, halt semantics) + degradation refs + command | No (2 files) |
| **T3 Security / integrity** (auth / secrets / deletion / PII) | No | **No** | No (orchestration only) | No |
| **T4 New external dependency** | No | **No** (no infra/MCP/runtime dep) | No (no new dep, but new internal schema) | No |

**Verdict:**
- **Opt 1 (recommended): all-no → low-risk.** No critic gate required if this option is chosen. *Caveat:* because it edits the autonomous-mode-adjacent leader.md, the leader should still treat the harness re-run as a mandatory acceptance check even though the four triggers are all-no — proximity to the C12–C15g contract warrants the C-harness as a guardrail, not a critic dispatch.
- **Opt 3: all-no → low-risk**, with even lower autonomous-contract proximity than Opt 1.
- **Opt 0: all-no → trivially low-risk** (nothing changes).
- **Opt 2: T1 + T2 fire → HIGH-RISK.** If the leader (or user) leans toward Option 2, the high-risk gate **must** dispatch the critic before Plan Approval — it rewrites the public autonomous contract that two prior critic rounds hardened, and the brief's ★ warning about autonomous-contract adjacency (T2) applies directly.

---

## Summary for the Leader

- **Spike path:** `/Users/dh/Project/orbit/.planning/plans/2026-06-20-spike-parallel-fanout.md`
- **Recommendation:** **Option 1 — lightweight prose codification** of an "Independent Fan-out → Fan-in" pattern (SKILL.md + leader.md, 2 files, append-only), with an explicit **"autonomous builds stay serial"** fence that protects cumulative T2 / skip-and-park D4 / halt-on-first-failure. Reverse-able, domain-agnostic, no new infra.
- **Honest counter:** Option 1 is unenforced prose justified by an external standard + vocabulary asymmetry rather than an observed orbit incident; if the real pain is *enforcement* or if no fan-out bug has ever occurred, **Option 0 (do nothing)** is the defensible thin alternative. Option 3 is a strictly-safer-but-narrower variant of Option 1.
- **Self-trigger verdict:** Opt 0 / Opt 1 / Opt 3 are **all-no → low-risk** (no critic gate needed). **Opt 2 fires T1 + T2 → high-risk** (critic gate mandatory if pursued).
- **Not committed:** this is a spike. No option is built until the leader runs Plan Approval on the chosen one.
