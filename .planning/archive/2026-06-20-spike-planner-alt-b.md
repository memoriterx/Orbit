# Spike — Planner/Architect Separation, Alternative (b): Option-Comparison

> **This is a comparison spike, not an implementation plan.** Output is an evaluated set of options and a single recommendation with rationale and a dissent. **Do NOT force one option into a build.** Implementation, if any, follows only after a separate Plan Approval on the recommended option.

**Question:** OMC-6 (introduce a `planner` agent) was deferred by a critic REVISE. The user (2026-06-20) directs a re-attempt via **alternative (b)**: planner owns *only* discovery / requirements / problem-framing / prioritization, and the **plan-document author stays the architect** (unlike the original OMC-6, which moved `writing-plans` to the planner). This spike evaluates whether alt-(b) is worth doing, and in what form.

**Spine of the spike (the one question everything hinges on):** *Does planner-discovery carry unique residual value that `explore` + `researcher` + `architect` do not already cover?* If the answer is "no," the honest recommendation is **do not build planner** — and this document says so plainly rather than rationalizing a new role into existence.

---

## Background facts (read once, verified against the repo)

- **Deferred original:** `.planning/2026-06-18-planner-agent-separation.md` — full 10-task build plan. It moved `writing-plans` ownership to planner (its D2), redefined architect to a "design review" pass, and propagated a 7→8 roster across 12 files. This is **not** alt-(b); alt-(b) keeps `writing-plans` with the architect.
- **Critic's three deferral grounds** (from `MEMORY.md → orbit_omc6_deferred.md`):
  1. **Premise unmeasured** — "architect is overloaded" was asserted, never observed.
  2. **Alternative (b) not examined** — a lighter split was available and skipped.
  3. **Thinness trade-off** — 7→8 roles taxes the "thin roster" philosophy.
- **Current roster (verified):** `leader / architect / builder / explore / critic / reviewer / researcher` = 7 roles. `plugins/orbit-base/CLAUDE.md:9` states "(7 roles)".
- **Existing discovery-capable agents (verified):**
  - `explore` (`agents/explore.md`, sonnet) — internal codebase search, read-only, "where is X / which files / how connected"; explicitly *not* "search-for-hire" decisions.
  - `researcher` (`agents/researcher.md`, haiku) — external-source investigation, read-only.
  - `architect` (`agents/architect.md`, opus) — its Task Sequence step 1 is literally **"Read requirements"**, and its Error Handling already covers **"Ambiguous requirements: make a reasonable default decision and record it as an ADR."** So requirements intake + ambiguity resolution already live in the architect today.
- **Stale fact found while surveying (independent of this spike):** `.codex-plugin/plugin.json:28` says **"Five roles (leader/architect/builder/reviewer/researcher)"** — already wrong today (omits explore + critic). Flagged here for a separate trivial fix; not caused by, and not blocking, this spike.

---

## ★ Axis 1 (the spine): planner-discovery vs. what already exists

This is the decisive axis. The table maps each concrete sub-activity people imagine "planner-discovery" doing onto the agent that **already** owns it today.

| Discovery sub-activity | Already owned by | Residual gap if planner absent? |
|---|---|---|
| "Where in the codebase does this touch?" | **explore** (internal search) | None — explore's core job |
| "What do other frameworks / docs do here?" | **researcher** (external sources) | None — researcher's core job |
| "Read the roadmap item & requirements" | **architect** (Task Seq step 1: *Read requirements*) | None — architect does this before planning |
| "Resolve ambiguous requirements / pick a default" | **architect** (Error Handling: *reasonable default → ADR*) | None — already specified |
| "Separate must-have vs. nice-to-have / scope" | **architect** (produces scope as part of the plan) + **leader** (roadmap selection) | Thin — done inside plan authorship |
| "Prioritize / sequence the work" | **leader** (roadmap ordering) + **architect** (task breakdown order) | Thin — split between leader & architect |
| "Frame the *real* problem behind the request" | **architect** (implicitly, before designing) + **critic** (challenges framing on high-risk) | **Possible residual** — no agent *named* for problem-framing, but it is not currently a bottleneck |
| "Requirements elicitation from the user" | **leader** (sole human interface) | Cannot be delegated — only the leader talks to the user (hub-and-spoke) |

**Reading of Axis 1.** Every concrete discovery activity already has an owner. The *search/investigation* half is fully covered by explore + researcher (this was exactly the critic's OMC-6 point). The *requirements/framing/scope/prioritization* half is covered by architect (intake + ambiguity + scope + task order) and leader (roadmap selection, user interface). The only arguably-unnamed sliver is **explicit problem-framing as a first-class step** — and the honest finding is that this is a *naming/discipline* gap, not a *capacity* gap. There is no observed evidence (ground 1 still unmet) that any current owner is failing at it.

**Verdict on the spine:** planner-discovery is **~90% redundant** with explore + researcher + architect + leader. The residual 10% ("problem-framing as an explicit, always-run step") is real as a *discipline* concern but does **not** justify an 8th agent. It justifies, at most, naming the step.

---

## Options (≥3)

### Option 0 — Status quo (no planner)
Discovery stays distributed: leader selects from roadmap and interfaces with the user; architect reads requirements, resolves ambiguity, defines scope, and authors the plan; explore/researcher are dispatched for internal/external lookups as needed. **Cost: 0.** Roster stays 7.

### Option b1 — New `planner` agent, discovery-only (alt-(b) literal)
Add an 8th agent that owns discovery / requirements analysis / problem-framing / prioritization, but **not** plan authorship (`writing-plans` stays with architect). New lifecycle step "0.5 Discover" between roadmap selection and plan authoring. Roster 7→8.

### Option b2 — No new agent; name a "Discovery step" in the architect lifecycle (lightweight codification)
Add a contractual **"Discovery first"** sub-step to the architect's Task Sequence: before producing the plan, the architect must (a) state the problem-framing in one paragraph, (b) list explicit requirements (must-have vs. nice-to-have), and (c) dispatch-request explore/researcher through the leader where lookups are needed. **Zero new roles.** This is the "skip-and-park / epic-group" style of change — codify a discipline as a named contract instead of spawning structure. Roster stays 7.

### Option b3 (free addition) — Discovery as a `writing-plans` skill section, not a role or a lifecycle step
Even lighter than b2: rather than touch the architect's lifecycle prose, require the plan document itself to open with a **"Discovery & Requirements"** section (problem framing, must/nice split, open assumptions, lookups performed). The discipline rides on the artifact, enforced by the plan template, not by any agent boundary. Roster stays 7. Smallest blast radius of all.

---

## Comparison across the 6 evaluation axes

| Axis | Opt 0 status-quo | Opt b1 new planner | Opt b2 named step | Opt b3 plan section |
|---|---|---|---|---|
| **1. Unique discovery value vs. explore/researcher/architect** (★) | Already covered; no gap closed | Adds ~10% (named framing) at a roster cost; ~90% duplicates existing owners | Closes the *same* 10% via a contract, 0 duplication | Closes the same 10% via the artifact, 0 duplication |
| **2. Thin-philosophy fit (7→8 cost vs. codification)** | Best (no change) | **Worst** — directly re-incurs deferral ground 3 | Good — codification, not a role | Best of the "do-something" options — pure template discipline |
| **3. Surfaces touched (blast radius)** | 0 | **~13 files** (planner.md + roster/lifecycle/spoke/codex/gemini/2×manifest/orbit-cycle/skillify/builder/explore/reviewer/leader/SKILL/CLAUDE) | **~4 files** (architect.md + CLAUDE.md + leader.md + using-orbit/SKILL.md lifecycle prose) | **1–2 files** (writing-plans usage note + optionally the roadmap/plan template) |
| **4. Hub-and-spoke / lifecycle / Plan Approval interaction** | Unchanged | **Adds a handoff** (leader→planner→leader→architect) and a new lifecycle node before every plan; more routing for the hub | No new handoff; same single architect dispatch, richer contract | No interaction at all; plan content only |
| **5. Autonomous-mode / skip-and-park / fan-out interaction** | Unchanged | Autonomous loop's per-task plan step gains a planner sub-dispatch → more loop surface, re-validate critic-on-entry against 8 roles; fan-out roster diagrams change | None — loop still dispatches architect for the plan | None |
| **6. Domain-neutrality / reversibility / upkeep** | n/a | New file must stay slot-pure; reverting means deleting 1 file + reverting 12 → costly rollback | Reversible (prose revert); slot-pure trivially | Most reversible (delete a section); slot-pure trivially |

---

## Answering the critic's three deferral grounds (required)

1. **Premise (architect overload) — still unmeasured.** Nothing in this spike supplies evidence that the architect is overloaded by discovery work. Axis 1 shows the architect already *does* requirements intake + ambiguity resolution today with no observed strain. **Ground 1 remains unmet for any option that adds capacity (b1).** It does *not* block b2/b3, which add discipline, not capacity.
2. **Alternative (b) superiority — examined, and it does NOT hold as a new-agent case.** The user's instinct that (b) is lighter than original-OMC-6 is correct *relative to OMC-6* (keeping `writing-plans` with the architect avoids the two-author ambiguity and ~half the propagation). **But "lighter than a bad option" is not "good."** Once examined, alt-(b)-as-a-new-agent (b1) still pays the full 7→8 roster tax (ground 3) to close a 10% gap that b2/b3 close for near-zero. So (b)'s real lesson is not "add a discovery agent"; it is "the discovery *concern* is legitimate but is a codification, not a role." **Alt-(b) is superior to OMC-6, and simultaneously inferior to simply naming the step.**
3. **Thinness (7→8) — confirmed as the deciding cost.** b1 re-incurs exactly the trade-off the critic flagged: one more role across ~13 surfaces, a heavier autonomous loop, and a costly rollback, to formalize problem-framing. b2/b3 deliver the same discipline at 1–4 surfaces with no roster growth.

---

## Recommendation

**Recommend Option b2 (name a "Discovery first" step in the architect's lifecycle), with b3 as the even-lighter fallback if the team wants zero lifecycle-prose churn.**

**Rationale:**
- It captures the *only* residual value Axis 1 found — explicit problem-framing + must/nice requirements as an always-run step — without adding an agent.
- It honors all three deferral grounds: no unmeasured-capacity bet (ground 1), it *is* the examined-and-preferred form of alt-(b) (ground 2), and it keeps the roster at 7 (ground 3).
- It is consistent with orbit's established pattern for this class of change (epic-group, skip-and-park): **codify a discipline as a named contract, don't spawn structure.**
- Smallest reversible footprint that still does something; slot-purity is trivial to preserve.

**Explicitly NOT recommended: Option b1 (new planner agent).** It is the literal alt-(b), but it fails the spine test — ~90% duplicate of explore/researcher/architect — and re-incurs the exact thinness cost the critic deferred on, with no new evidence of need.

### Dissent (why the recommendation could be wrong)
- **If problem-framing failures are actually occurring** (plans repeatedly mis-scoped because no one framed the real problem), then b2/b3's "discipline-by-contract" may be too weak — a contract an overloaded architect skips under load is no better than the status quo, and a *dedicated* planner (b1) that cannot be skipped might be the only thing that forces framing. This dissent becomes decisive **only with evidence** (e.g., a retro showing N plans deferred/reworked for framing reasons). Absent that evidence, it is speculation — which is precisely ground 1.
- **Secondary dissent:** even b2 may be unnecessary if the *real* fix is one sentence in `writing-plans` (b3). Recommending b2 over b3 slightly over-builds; the team should pick b3 if it values minimal lifecycle churn over an explicit architect-side contract.

**Evidence that would flip the recommendation to b1:** an observed, documented pattern (≥3 instances, mirroring orbit's own skillify "rule of three") of plans failing specifically for lack of up-front problem-framing that explore/researcher/architect did not catch. Until that exists, b1 is over-engineering.

---

## Touched-surface inventory + verification strategy (for whichever option is later approved)

**Option b1 surfaces (~13):** `agents/planner.md` (new), `agents/architect.md`, `agents/leader.md`, `agents/builder.md`, `agents/explore.md`, `agents/reviewer.md`, `CLAUDE.md`, `commands/orbit-cycle.md`, `skills/using-orbit/SKILL.md`, `skills/using-orbit/references/codex-tools.md`, `skills/using-orbit/references/gemini-tools.md`, `skills/skillify/SKILL.md`, `.codex-plugin/plugin.json` (and verify `.claude-plugin/plugin.json`).

**Option b2 surfaces (~4):** `agents/architect.md` (add Discovery sub-step), `CLAUDE.md` (lifecycle line), `agents/leader.md` (lifecycle block), `skills/using-orbit/SKILL.md` (lifecycle steps).

**Option b3 surfaces (1–2):** a usage note where the plan template / `writing-plans` convention lives (e.g., `templates/roadmap.template.md` or the plan-doc convention in using-orbit) — no agent file changes.

**Verification strategy (all options):**
- **Domain purity:** `grep -riE 'oremi|orbit-dev' plugins/orbit-base/` → 0 hits; slots (`{{...}}`) preserved.
- **Set-diff consistency** (if roster changes, i.e. b1 only): every surface enumerating the roster must move 7→8 together — `grep -rn '7 roles\|seven roles' plugins/orbit-base/` → 0 after; `grep -rln 'planner' plugins/orbit-base/` must equal the full surface set above. For b2/b3 the roster stays 7, so the **"7 roles" string must remain unchanged** (a guard against accidental roster drift).
- **New-agent roster surfaces (b1 only):** the 6-spoke vs. 7-full diagrams in `using-orbit/SKILL.md`, the codex `multi_agent` sequence, and the gemini `@generalist` table must all gain the planner row consistently.
- **Frontmatter schema (b1 only):** `agents/planner.md` must have `name`/`description`/`model` and match architect/critic structure; pick a model tier explicitly.
- **Autonomous-mode harness regression (b1 only):** re-run `.planning/verify-autonomous-mode.sh` and confirm critic-on-entry / fan-out narratives still reference a coherent roster (now 8). b2/b3 do not alter the loop, so no harness regression expected — but run it anyway to prove non-interference.
- **Manifest validity:** `python3 -m json.tool` on both `plugin.json` files (relevant to b1; also the right moment to fix the stale "Five roles" string regardless of option).

---

## High-risk 4-trigger self-diagnosis

| Trigger | b1 (new agent) | b2 (named step) | b3 (plan section) |
|---|---|---|---|
| **T1 Irreversibility** | Low–Med — revert = delete 1 + revert 12 files; recoverable but not trivial | No — prose revert | No — section revert |
| **T2 Broad impact (≥3 surfaces / public contract)** | **FIRES** — ~13 surfaces, and the **roster is a public contract** (end-user-visible role set 7→8) and the **lifecycle is a documented contract** | Borderline — 4 surfaces, lifecycle prose touched but no roster/contract change; likely fires T2 on surface count → treat as **gate-eligible** | No — 1–2 surfaces, no contract change |
| **T3 Security/integrity** | No | No | No |
| **T4 New external dependency** | No | No | No |

**Self-diagnosis result:**
- **b1 → HIGH-RISK (T2 fires).** If b1 is ever chosen, the leader must run the **critic gate** before Plan Approval, per the high-risk branch. (This mirrors the original OMC-6, which the critic already REVISE'd.)
- **b2 → BORDERLINE (T2 on surface count).** Recommend treating as **gate-eligible**: a short critic pass is cheap insurance given it touches the lifecycle contract prose, even though no roster/role changes.
- **b3 → LOW-RISK.** No contract change, 1–2 surfaces; critic may be skipped.

The **recommended** path (b2, fallback b3) is low-to-borderline risk — a deliberate contrast with b1's high-risk profile, and the core reason b2/b3 are preferred.

---

## Self-review against the brief

- ✅ Comparison spike, not a build plan; no option forced.
- ✅ Spine question (Axis 1) faced head-on with a mapping table; honest "do not build planner" verdict on b1.
- ✅ ≥3 options (0, b1, b2, b3).
- ✅ All 6 axes tabulated; Axis 1 given its own dedicated table.
- ✅ One recommendation (b2, fallback b3) + rationale + explicit dissent + flip-evidence.
- ✅ Touched-surface list + verification strategy (domain purity, set-diff, new-agent roster surfaces, autonomous-mode regression).
- ✅ All three deferral grounds answered, including whether (b)'s superiority actually holds (it holds vs. OMC-6, fails as a new-agent case).
- ✅ 4-trigger self-diagnosis; b1 fires T2 (multi-surface + public-contract) as predicted.
- ✅ Domain-neutrality / slot constraints respected (no `plugins/orbit-base/` edits made; this is a `.planning/` spike).
