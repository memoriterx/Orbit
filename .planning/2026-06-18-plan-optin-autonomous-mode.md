# Opt-in Autonomous Execution Mode (Approach A — full, with autonomous loop) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add an opt-in (default-off) autonomous execution mode to the `plugins/orbit-base/` product, where the user pre-approves a scoped batch of low-risk tasks once and the leader runs an autonomous loop within that scope, auto-halting on the four-trigger high-risk gate — without ever adding a new role, hook, runtime, or state file.

**Architecture:** This is a *prose/contract alignment* change, not a runtime feature. Approach A reuses three existing orbit mechanisms: (1) the Plan Approval Gate exercised once over a named scope ("batch pre-approval"); (2) the leader as loop orchestrator (hub-and-spoke preserved — "continuous execution" is the leader looping, never agents handing off to each other); (3) the critic four-trigger OR gate repurposed as the hard auto-halt line (any trigger fires → task ejected from batch → loop halts → individual re-approval). **Two independent safeguards close the leader-self-judgment gap** that the critic gate flagged: (a) a **conservative default** — if a task's four-trigger judgment is anything other than *manifestly all-no* (i.e., ambiguous), the leader halts and individually re-approves ("ambiguous ⇒ stop", never "ambiguous ⇒ proceed"); and (b) **critic-on-entry** — before the user grants a batch pre-approval, the critic independently reviews the *entire enumerated batch* once for autonomous eligibility (every task manifestly all-no), placing a second pair of eyes at the entry point rather than only after a trigger fires. Both reuse the existing critic agent (zero new infrastructure). No new agents, no new hooks, no new state files, no MCP, no shared queue. The single consistency baseline is that the same four-trigger gate text already present in `leader.md`, `critic.md`, `CLAUDE.md`, and `using-orbit/SKILL.md` is referenced — not forked — by the autonomous-mode prose.

**Tech Stack:** Markdown agent prompts, `CLAUDE.md` operating rules, `using-orbit/SKILL.md` orientation skill, `commands/orbit-cycle.md` slash command, `references/{codex,gemini}-tools.md` degradation tables, `.claude-plugin/plugin.json` manifest. Verification is via `grep` contract checks, frontmatter/manifest validity checks, and written behavioral walkthrough scenarios (no executable test runner exists for prose contracts).

## Global Constraints

- **Scope: deliverable product only.** Edit only files under `plugins/orbit-base/`. The following are explicitly out of scope and MUST NOT be touched: `.claude/` (dev-team config, including `.claude/agents/leader.md`), `setup-orbit.sh` at any non-product path, the repo-root `README.md`, `.codex-plugin/` and `gemini-extension.json` manifests (no autonomous-mode field needed there). When this plan says "leader.md" it means **`plugins/orbit-base/agents/leader.md`**, never `.claude/agents/leader.md`.
- **Domain purity (non-negotiable).** No project name (oremi, Oremi, orbit-dev, etc.) anywhere in `plugins/orbit-base/`. Domain-variable values stay as `{{...}}` slots. The SubagentStop quality gate enforces `grep -rE 'oremi|Oremi' plugins/orbit-base/` == 0.
- **Hub-and-spoke is invariant.** "Continuous/autonomous execution" is implemented as the *leader looping over the existing single-task lifecycle*, NEVER as agent-to-agent handoff. The "no spoke talks to another spoke" rule must remain literally true and unweakened in every edited file.
- **Human gate is non-negotiable.** Batch pre-approval is the Plan Approval Gate *exercised once over a stated scope*, not a removal or weakening of it. Every edited surface that mentions the gate must state: pre-approval = one human exercise of the gate; any four-trigger firing forces automatic re-gating (individual human approval). The literal phrase "non-negotiable" in `CLAUDE.md:44` must remain and be reconciled, not deleted.
- **Default-off backward compatibility.** Absent an explicit pre-approval, behavior is byte-for-byte the current per-task Plan Approval. This must be stated in every surface and is a hard success criterion.
- **Tone/structure consistency.** Match the existing `leader.md`/`critic.md`/`using-orbit` register: terse, table-driven, English prose in the product files (the product files are English; only dev-team `.claude/` and `.planning/` are Korean). `commands/orbit-cycle.md` is Korean — match that file's Korean register for its edits.
- **Model tier.** No model-tier change; `bar` alias unaffected. No frontmatter `model:` field is added or changed by this plan.
- **No new files.** This plan creates zero new product files. It edits existing ones only. (No `autonomous-mode.md` agent, no new skill.)

---

## Why this is HIGH-RISK (basis for the critic gate before Plan Approval)

This plan is pre-judged high-risk. The four-trigger OR gate result, recorded here so the leader can route the critic before Plan Approval:

| Trigger | Verdict | Basis |
|---------|---------|-------|
| T1 Irreversibility | no | Pure prose/contract edits; revert restores prior text exactly. No data migration, no schema, no contract field that other code depends on. |
| T2 Blast radius | **YES (fires)** | Changes the *meaning of the Plan Approval Gate* — a public contract — and edits 5+ product surfaces (`leader.md`, `critic.md`, `CLAUDE.md`, `using-orbit/SKILL.md`, `orbit-cycle.md`, degradation tables). |
| T3 Security / data integrity | no | No auth/secrets/deletion/PII path. Risk of "autonomous run passes an integrity path without human review" is mitigated *by three layers*: (1) the T3 trigger is itself part of the auto-halt set; (2) the conservative default — an ambiguous T3 judgment halts rather than proceeds; (3) critic-on-entry independently screens the whole batch for integrity-touching tasks before pre-approval is granted. This must be explicitly preserved (a regression in any layer would flip this to YES). |
| T4 New external dependency | no | orbit-base existing assets only. No MCP, no queue, no runtime, no new file. |

**T2 fires → critic gate is mandatory before Plan Approval.** The single most important thing for the critic to verify: *does batch pre-approval weaken the "human gate is non-negotiable" principle, or is it a faithful re-exercise of the same gate?* The plan's position (to be challenged) is the latter — Tasks 1–3 encode the guarantees that make it so, and Tasks 2–4 add the conservative-default + critic-on-entry safeguards that close the leader-self-judgment gap. Secondary critic focus: whether the four-trigger gate is genuinely sufficient to define "low-risk" (the spike's open question §6.1), addressed by Task 2's operational definition.

**Note on the spike's recommendation.** The spike recommended an "A'-first" (advisory-only, no autonomous loop) path. This plan **consciously overrides that recommendation**: the user explicitly chose Approach A in full, including the autonomous loop. The override is not implicit — it is owned and recorded as **ADR-002** below. The critic's surfaced gaps are addressed by adding safeguards *inside* Approach A, not by retreating to A'.

---

## File Structure

All edits are to existing files under `plugins/orbit-base/`. Responsibilities:

| File | Role in this change | What it gains |
|------|--------------------|--------------|
| `CLAUDE.md` | AI-neutral operating rules — the canonical contract | A new "Autonomous Mode (opt-in)" section defining batch pre-approval, critic-on-entry, the low-risk operational definition (manifestly-all-no), the conservative "ambiguous ⇒ stop" default, the batch-cumulative T2 rule + batch-size cap, the auto-halt rule, scope re-validation at task boundaries, and the default-off guarantee; reconciliation of the "non-negotiable" sentence. |
| `agents/leader.md` | Leader behavior — the loop orchestrator | An "Autonomous Loop" subsection: critic-on-entry dispatch before pre-approval, how the leader runs the loop, per-iteration four-trigger gate with conservative default, batch-cumulative blast-radius tracking, batch-size cap + human re-sync, halt/eject behavior, scope re-validation + withdrawal handling at each boundary, failure rollback, Triple Crown application. |
| `agents/critic.md` | Owns the four-trigger gate definition | A note that the same four triggers double as the autonomous-mode auto-halt line, **and** that the critic performs the **on-entry batch eligibility screen** (independent review that every enumerated task is manifestly all-no) before pre-approval. No new triggers; the critic's invocation is now leader-gated in two places (on-entry screen + fired-trigger branch). |
| `skills/using-orbit/SKILL.md` | Orientation — first thing read in a session | An "Autonomous Mode (opt-in)" subsection mirroring CLAUDE.md in orientation register; degradation-table row for autonomous loop by environment. |
| `commands/orbit-cycle.md` | The lifecycle slash command (Korean) | A section on running the batch (pre-approval input, loop, halt), in Korean matching the file. |
| `skills/using-orbit/references/codex-tools.md` | Codex degradation reference | One line: how the autonomous loop degrades under Codex (sequential, no background pseudo-parallelism). |
| `skills/using-orbit/references/gemini-tools.md` | Gemini degradation reference | One line: how the autonomous loop degrades under Gemini (single context, role-switching — loop is manual sequential). |
| `.claude-plugin/plugin.json` | Manifest | Verified unchanged-or-version-bump only; no new field required. Used as the consistency baseline check. |

**Decomposition rationale:** `CLAUDE.md` is the canonical contract, so it is written first (Task 3) and every other surface references its definitions rather than re-deriving them — this is the DRY anchor that prevents the multi-surface drift T2 warns about. The operational definition of "low-risk" (Task 2) is locked before any surface uses the term. Task 1 establishes the verification harness (grep contract checks + walkthrough scenarios) first, TDD-style, so every later task has a red→green signal.

---

## Operational definitions (locked here — referenced by all tasks)

These are the load-bearing definitions. They are written into `CLAUDE.md` in Task 3; quoted here so every task implementer sees identical wording.

**Pre-approval scope expression.** The user states a batch as: *a named, finite set of tasks* — either (a) explicit roadmap item IDs/checkboxes, or (b) a bounded predicate over the roadmap (e.g., "all unstarted items in milestone M that are low-risk"). The scope MUST be finite and enumerable by the leader from the roadmap at pre-approval time. An open-ended "just keep going" is NOT a valid scope and the leader must decline it and request a bounded scope.

**Critic-on-entry (independent eligibility screen).** Before the user grants the batch pre-approval, the leader enumerates the scope and dispatches the **critic once** to independently review the *entire enumerated batch* for autonomous eligibility — confirming every listed task is *manifestly all-no* on the four triggers. This is a second pair of eyes at the **entry point**, not only after a trigger fires mid-loop. If the critic flags any task as not-manifestly-all-no (high-risk or ambiguous), that task is removed from the autonomous batch and routed to normal per-task approval; the batch proceeds (if at all) only over the critic-cleared remainder, and the user pre-approves *that* cleared list. Reuses the existing critic agent — zero new infrastructure. The critic-on-entry verdict is recorded as the pre-approval record alongside the enumerated list.

**Low-risk (autonomous-eligible) — operational definition.** A task is autonomous-eligible if and only if **all four** of these hold *manifestly* (the four-trigger OR gate, all-no, with no ambiguity):
1. Reversible (T1 no): undo needs no data migration, rewrite, or backward-compat break.
2. Contained (T2 no): touches < 3 components AND changes no public interface/contract — judged on **batch-cumulative blast radius** (see below), not the single task in isolation.
3. Integrity-neutral (T3 no): no auth/permissions/secrets/deletion/money/PII path.
4. No new external dependency (T4 no).

**Conservative default (ambiguity ⇒ stop).** Eligibility requires a *manifestly* all-no judgment. If any trigger's verdict is unclear, borderline, or requires a judgment call the leader is not confident about, the task is treated as **not eligible**: the loop halts and the task goes to individual human Plan Approval. The rule is **"ambiguous ⇒ stop", never "ambiguous ⇒ proceed."** This converts the leader's self-judgment from a silent-pass risk into a fail-safe: the only path to autonomous execution is an unambiguous all-no.

**Batch-cumulative blast radius (T2).** T2 is judged not per-task-in-isolation but against the **running cumulative total of components touched by the batch so far**. Before each task, the leader sums the distinct components already modified by completed batch tasks plus the components the next task's plan will touch; if that cumulative total reaches the T2 threshold (≥ 3 distinct components), T2 fires and the loop halts for re-approval — even if each individual task looked contained. This catches accumulation, cross-task interaction, and context drift that single-point judgment misses.

**Batch size cap + periodic human re-sync.** An autonomous batch is bounded by a hard cap: **at most 5 tasks per pre-approval** *and* a cumulative blast-radius ceiling (the T2 cumulative rule above). On reaching either ceiling, the loop halts and the leader returns to the human for an explicit re-sync — re-stating what was done and requesting a fresh pre-approval for any continuation. This is the periodic re-synchronization point that bounds accumulation risk; "ambiguous ⇒ stop" plus the cap means an autonomous run can never silently outrun human oversight.

The spike (§6.1) flagged that the user words "repetitive/exploratory" may not reduce to the four triggers. Resolution adopted by this plan: **the four-trigger gate is the sole, sufficient, measurable eligibility criterion.** "Repetitive" and "exploratory" are *motivations* for batching, not separate gates — a repetitive task that fires any trigger is still ejected. No fifth axis is introduced (YAGNI; avoids the domain-dependence the spike warned of, since the four triggers are domain-agnostic). This decision is recorded as ADR-001 below and must be promoted to project memory on completion.

**Auto-halt rule.** During the loop, after the architect produces each task's plan, the leader applies the four-trigger gate (manifestly-all-no standard, batch-cumulative T2). If **any** trigger fires **or the judgment is ambiguous**, that task is **ejected from the batch**, the **loop halts**, and the leader escalates that task to **individual human Plan Approval** (the existing per-task gate, plus the critic branch since a trigger fired). The loop does not silently skip and continue; it stops at the first ejection so the human sees it.

**Scope re-validation at each task boundary (staleness guard).** The scope is enumerated once at pre-approval, but the codebase and roadmap change as the loop runs. To prevent stale-scope drift, **at each task boundary** the leader re-confirms scope validity before dispatching the next task: (1) re-check the roadmap/codebase — if either has materially changed such that the remaining batch no longer matches what the critic cleared on entry (items added/removed/reprioritized, or a completed task altered the assumptions of a pending one), the leader **re-enumerates and re-runs critic-on-entry over the remaining items** before continuing; (2) check the withdrawal signal (below). Per-task plans are generated **at loop time** by the architect for the current task (never pre-generated stale at T0), so each plan reflects the codebase as it actually is at that iteration. Scope re-validation and the withdrawal check happen together at every boundary.

**Withdrawal mechanism.** The user may withdraw a batch pre-approval at any time. The leader checks for a withdrawal signal **at each task boundary** (before dispatching the builder for the next task), together with the scope re-validation above. Withdrawal stops the loop after the current in-flight task's Triple Crown completes (no mid-task kill — the in-flight task finishes its verification and commit so no half-done state is left). There is no hook-based mid-task interrupt (YAGNI — would require new infra, violating the no-new-hook constraint). Task-boundary granularity is the documented contract.

**Failure rollback.** If a task in the loop fails Triple Crown (② behavior or ③ quality), the **loop halts** (does not continue to the next task). Already-completed prior tasks in the batch remain committed (orbit commits per task — they are independently verified-and-passed). The failed task is escalated to the human. The contract: the loop is *halt-on-first-failure*, not *isolate-and-continue* — predictability over throughput, matching orbit's identity.

**Triple Crown in autonomous mode.** Triple Crown applies **unchanged** to every task in the loop. Autonomy lowers the *frequency of human approval*, never the *strength of verification*. (The spike asked if it could be lightened — answer: no, not in this plan; lightening verification would be a separate high-risk decision.) Cost note to document: per-loop SubagentStop quality-gate firings scale with loop length; this is accepted and stated, not optimized away.

**Reversibility note (scope-honest, T1 basis).** The *file-level* revert is byte-exact: reverting these commits restores the prior text exactly. But the change extends a **public contract** — the meaning of the Plan Approval Gate. Withdrawing that contract later (deprecating autonomous mode) is **not** cost-free: it is a deprecation/backward-incompatible change to the end-user workflow, since adopters may have built batch pre-approval into their process. **Default-off guarantees only adoption compatibility** (an end-user who never opts in sees byte-for-byte the prior behavior); it does NOT make the public-contract addition reversible without end-user workflow cost. T1 is scored "no" on the *implementation* (file revert), with this contract-deprecation cost explicitly acknowledged, not hidden.

**ADR-001 (record in plan, promote to memory on completion):** *Autonomous-mode eligibility = the existing four-trigger OR gate (all-no), no fifth axis. Rationale: domain-agnostic, reuses existing gate, avoids the spike's domain-dependence and OMC-6 over-engineering traps. Repetitive/exploratory are batching motivations, not gates.*

**ADR-002 (record in plan, promote to memory on completion):** *Spike's "A'-first" (advisory-only, no autonomous loop) recommendation is consciously rejected. Decision: adopt Approach A in full, including the autonomous loop, per explicit user choice. The critic-surfaced leader-self-judgment gap is closed by two safeguards added inside Approach A — a conservative "ambiguous ⇒ stop" default and a critic-on-entry independent batch screen — rather than by retreating to A'. This override is explicitly owned, not implicit. Cost accepted: the public-contract addition carries a deprecation cost if ever withdrawn (see Reversibility note).*

---

### Task 1: Verification harness — contract grep checks + walkthrough scenarios

Establish the red→green verification mechanism FIRST so every later task has a failing-then-passing signal. There is no code test runner for prose; the harness is a documented set of `grep`/validity commands plus written behavioral walkthrough scenarios that a reviewer executes by reading the edited files.

**Files:**
- Create (in `.planning/`, NOT product): `.planning/verify-autonomous-mode.sh` — a checker script the reviewer/builder runs. This lives in `.planning/` (dev artifact), not `plugins/orbit-base/`, so it does not pollute the product. It is the "test file."
- Test: the script self-verifies by exit code.

**Interfaces:**
- Produces: a runnable `bash .planning/verify-autonomous-mode.sh` that exits 0 only when all contract invariants hold. Later tasks make individual checks flip from FAIL to PASS.

- [ ] **Step 1: Write the failing checker script**

```bash
#!/usr/bin/env bash
# Contract checks for opt-in autonomous mode. Exit 0 = all invariants hold.
set -u
BASE="plugins/orbit-base"
fail=0
chk() { if eval "$2"; then echo "PASS: $1"; else echo "FAIL: $1"; fail=1; fi; }

# C1 domain purity: no project names leaked
chk "C1 no project-name leak" "[ \$(grep -rciE 'oremi|orbit-dev' \"\$BASE\" | awk -F: '{s+=\$2} END{print s+0}') -eq 0 ]"

# C2 default-off stated in CLAUDE.md and using-orbit
chk "C2a CLAUDE default-off" "grep -qiE 'default.?off|opt.?in.*default|absent.*pre.?approval' \"\$BASE/CLAUDE.md\""
chk "C2b using-orbit default-off" "grep -qiE 'default.?off|opt.?in' \"\$BASE/skills/using-orbit/SKILL.md\""

# C3 non-negotiable phrase preserved in CLAUDE.md
chk "C3 non-negotiable preserved" "grep -q 'non-negotiable' \"\$BASE/CLAUDE.md\""

# C4 auto-halt on four-trigger stated in leader.md and CLAUDE.md
chk "C4a leader auto-halt" "grep -qiE 'halt|eject|re-?approv' \"\$BASE/agents/leader.md\""
chk "C4b CLAUDE auto-halt" "grep -qiE 'halt|eject|re-?approv' \"\$BASE/CLAUDE.md\""

# C5 hub-and-spoke literally preserved (leader loop, not agent handoff)
chk "C5a leader loop-not-handoff" "grep -qiE 'leader.*loop|loop.*leader' \"\$BASE/agents/leader.md\""
chk "C5b hub-and-spoke still present" "grep -qi 'hub-and-spoke' \"\$BASE/agents/leader.md\""

# C6 four-trigger gate text not forked: critic still owns the canonical table
chk "C6 critic four-trigger intact" "grep -qi 'four-trigger\|Irreversibility' \"\$BASE/agents/critic.md\""

# C6b critic all-no invariant carve-out: the "all four no => critic does not run"
# claim must NOT be unconditional once autonomous mode ships — it must be scoped to
# the per-task lifecycle AND carry an autonomous on-entry exception. We detect the
# conflict by requiring, on any line that says the critic "does not run" when all-no,
# the scoping qualifier "per-task" (or an explicit autonomous "Exception"/carve-out).
# If the unconditional form survives, this FAILS — C6 (table present) cannot catch it.
chk "C6b critic all-no carve-out" "! grep -qiE 'all four are no.*critic does not run' \"\$BASE/agents/critic.md\" || grep -qiE 'per-task|Exception.*autonomous|autonomous.*(exception|carve)' \"\$BASE/agents/critic.md\""

# C7 withdrawal at task boundary documented in leader.md
chk "C7 withdrawal documented" "grep -qiE 'withdraw|task boundary' \"\$BASE/agents/leader.md\""

# C8 manifest valid JSON
chk "C8 plugin.json valid" "python3 -c 'import json,sys; json.load(open(\"'\"\$BASE\"'/.claude-plugin/plugin.json\"))'"

# C9 frontmatter intact on edited agent files (name+description+model lines present)
for f in leader critic; do
  chk "C9 $f frontmatter" "awk 'NR==1{a=(\$0==\"---\")} /^name:/{n=1} /^description:/{d=1} /^model:/{m=1} END{exit !(a&&n&&d&&m)}' \"\$BASE/agents/$f.md\""
done

# C10 degradation rows mention autonomous loop
chk "C10a codex degradation" "grep -qiE 'autonom|loop' \"\$BASE/skills/using-orbit/references/codex-tools.md\""
chk "C10b gemini degradation" "grep -qiE 'autonom|loop' \"\$BASE/skills/using-orbit/references/gemini-tools.md\""

# C11 critic-on-entry: independent batch eligibility screen before pre-approval
chk "C11a CLAUDE critic-on-entry" "grep -qiE 'critic.on.entry|critic.*before.*pre-?approv|independent.*eligibilit|batch.*eligibility screen' \"\$BASE/CLAUDE.md\""
chk "C11b leader critic-on-entry" "grep -qiE 'critic.on.entry|dispatch.*critic.*before|on-entry.*screen' \"\$BASE/agents/leader.md\""
chk "C11c critic.md owns on-entry" "grep -qiE 'on-entry|entry.*screen|enumerated batch' \"\$BASE/agents/critic.md\""

# C12 conservative default: ambiguous => stop
chk "C12a CLAUDE conservative default" "grep -qiE 'ambigu.*stop|manifestly all-no|ambigu.*not eligible' \"\$BASE/CLAUDE.md\""
chk "C12b leader conservative default" "grep -qiE 'ambigu.*stop|ambigu.*halt|manifestly all-no' \"\$BASE/agents/leader.md\""

# C13 batch-cumulative blast radius + batch-size cap / re-sync
chk "C13a CLAUDE cumulative T2" "grep -qiE 'cumulative.*blast|batch.cumulative|cumulative.*component' \"\$BASE/CLAUDE.md\""
chk "C13b CLAUDE batch cap/re-sync" "grep -qiE 'batch size cap|re-?sync|at most [0-9]+ task|cap' \"\$BASE/CLAUDE.md\""
chk "C13c leader cumulative+cap" "grep -qiE 'cumulative|re-?sync|cap' \"\$BASE/agents/leader.md\""

# C14 scope re-validation at task boundary (staleness guard)
chk "C14a CLAUDE scope re-validation" "grep -qiE 're-?validat|re-?enumerat|scope.*boundary|stale' \"\$BASE/CLAUDE.md\""
chk "C14b leader scope re-validation" "grep -qiE 're-?validat|re-?enumerat|re-confirm scope|stale' \"\$BASE/agents/leader.md\""

exit $fail
```

- [ ] **Step 2: Run it to verify it fails**

Run: `bash .planning/verify-autonomous-mode.sh`
Expected: several `FAIL:` lines (C2, C4, C5a, C6b, C7, C10, C11, C12, C13, C14) and non-zero exit, because no autonomous-mode prose exists yet. **C6b FAILs at T0 by design**: the current `critic.md:22` carries the *unconditional* "all four are no ⇒ critic does not run" sentence with no per-task scoping or autonomous carve-out — exactly the invariant conflict Task 4 Step 1 resolves; C6b flips to PASS once that sentence is scoped. C1/C3/C6/C8/C9 should already PASS (existing invariants). If C1/C3/C6/C8/C9 FAIL at this point, the harness or the baseline is wrong — fix before proceeding.

- [ ] **Step 3: Commit the harness**

```bash
git add .planning/verify-autonomous-mode.sh
git commit -m "chore: add contract-check harness for opt-in autonomous mode"
```

---

### Task 2: Lock the low-risk operational definition + ADR

Encode the operational definitions (above) as the single source the other surfaces quote. This task produces no product edit by itself except seeding the canonical text block into `CLAUDE.md`'s new section header so later tasks fill underneath it. We do it as a dedicated task because a reviewer could reject the *definition* while approving the *prose around it*.

**Files:**
- Modify: `plugins/orbit-base/CLAUDE.md` — add the section anchor and the low-risk definition + auto-halt rule (the load-bearing definitions only; surrounding prose comes in Task 3).

**Interfaces:**
- Consumes: nothing.
- Produces: a `## Autonomous Mode (opt-in)` section in `CLAUDE.md` containing the four-condition low-risk definition and the auto-halt rule, verbatim as in "Operational definitions" above. Tasks 3–7 quote/reference this; they must not restate the four conditions in their own words (DRY — reference "the four-trigger gate, all-no, as defined in CLAUDE.md Autonomous Mode").

- [ ] **Step 1: Add the section and definitions to CLAUDE.md**

Insert after the existing `## Plan Approval Gate` section, before `## Verification Standard`:

```markdown
## Autonomous Mode (opt-in)

Autonomous mode is **off by default**. Absent an explicit batch pre-approval, every task uses the standard per-task Plan Approval Gate above — unchanged. Autonomous mode never weakens that gate; it exercises it once over a stated scope.

**Batch pre-approval.** The user may exercise the Plan Approval Gate **once** over a *named, finite, enumerable set of tasks* (explicit roadmap IDs, or a bounded predicate over the roadmap). Open-ended scope ("just keep going") is not valid; the leader declines it and requests a bounded scope. Batch pre-approval is the same human gate, exercised once — not its removal.

**Critic-on-entry (independent eligibility screen).** Before the user grants the pre-approval, the leader enumerates the scope and dispatches the **critic once** to independently review the *entire enumerated batch* — confirming every task is manifestly all-no on the four triggers. Any task the critic flags as high-risk or ambiguous is removed from the autonomous batch and routed to normal per-task approval; the user pre-approves only the critic-cleared remainder. This is a second pair of eyes at the entry point, not only after a trigger fires mid-loop. Reuses the existing critic agent.

**Low-risk (autonomous-eligible).** A task is eligible if and only if **all four** of the four-trigger OR gate conditions are *manifestly no* (the same four triggers the critic uses), with no ambiguity:
1. Reversible (no data migration / rewrite / backward-compat break).
2. Contained (< 3 components AND no public interface/contract change) — judged on **batch-cumulative blast radius**, not the task alone.
3. Integrity-neutral (no auth / permissions / secrets / deletion / money / PII path).
4. No new external dependency.

"Repetitive" and "exploratory" are motivations for batching, not separate gates. The four triggers are the sole, measurable eligibility criterion.

**Conservative default (ambiguous ⇒ stop).** Eligibility requires a *manifestly all-no* judgment. If any trigger's verdict is unclear, borderline, or a low-confidence call, the task is **not eligible**: the loop halts and the task goes to individual human Plan Approval. The rule is **"ambiguous ⇒ stop", never "ambiguous ⇒ proceed."** The only path to autonomous execution is an unambiguous all-no.

**Batch-cumulative blast radius (T2) + batch-size cap.** T2 is judged against the **running cumulative total of distinct components touched by the batch so far** (not per-task-in-isolation): before each task the leader sums components already modified plus those the next task touches; reaching ≥ 3 distinct components fires T2 and halts the loop. An autonomous batch is additionally capped at **at most 5 tasks per pre-approval**; on reaching either ceiling the loop halts and the leader returns to the human for an explicit **re-sync** (re-state what was done, request fresh pre-approval for any continuation). This bounds accumulation, cross-task interaction, and context drift.

**Scope re-validation (staleness guard).** Scope is enumerated once at pre-approval, but the codebase/roadmap change during the loop. **At each task boundary** the leader re-confirms scope validity before the next task: if the roadmap/codebase has materially changed (items added/removed, or a completed task altered a pending task's assumptions), the leader **re-enumerates and re-runs critic-on-entry over the remaining items** before continuing. Per-task plans are generated at loop time (never pre-generated stale at the batch start), so each reflects the codebase as it is at that iteration.

**Auto-halt (hard).** During an autonomous batch, the leader applies the four-trigger gate (manifestly-all-no standard, batch-cumulative T2) to each task's plan. If **any** trigger fires **or the judgment is ambiguous**, the task is **ejected from the batch**, the **loop halts**, and the task escalates to **individual human Plan Approval** (with the critic branch, since a trigger fired). The human gate for high-risk work remains non-negotiable.
```

- [ ] **Step 2: Reconcile the existing non-negotiable sentence**

The existing `CLAUDE.md` line "No implementation proceeds without the user's explicit approval of the written plan. This gate is non-negotiable." stays. Append one clause so it harmonizes with batch pre-approval. Change it to:

```markdown
No implementation proceeds without the user's explicit approval of the written plan — given per task, or once over a pre-approved batch scope (see Autonomous Mode). This gate is non-negotiable: any four-trigger high-risk firing always forces individual human approval.
```

- [ ] **Step 3: Run the harness to verify the CLAUDE.md checks flip to PASS**

Run: `bash .planning/verify-autonomous-mode.sh`
Expected: `PASS: C2a CLAUDE default-off`, `PASS: C3 non-negotiable preserved`, `PASS: C4b CLAUDE auto-halt`, `PASS: C11a CLAUDE critic-on-entry`, `PASS: C12a CLAUDE conservative default`, `PASS: C13a CLAUDE cumulative T2`, `PASS: C13b CLAUDE batch cap/re-sync`, `PASS: C14a CLAUDE scope re-validation`. C2b/C4a/C5a/C7/C10, C11b/C11c, C12b, C13c, C14b still FAIL (other files untouched).

- [ ] **Step 4: Verify domain purity unbroken**

Run: `grep -rciE 'oremi|orbit-dev' plugins/orbit-base | awk -F: '{s+=$2} END{print s+0}'`
Expected: `0`

- [ ] **Step 5: Commit**

```bash
git add plugins/orbit-base/CLAUDE.md
git commit -m "feat(base): define opt-in autonomous mode contract in CLAUDE.md"
```

---

### Task 3: Leader autonomous-loop behavior

Encode how the leader actually runs the loop: hub-and-spoke preserved, per-iteration gate, halt/eject, withdrawal at task boundary, failure rollback, Triple Crown unchanged. This is the behavioral heart and the biggest blast-radius surface.

**Files:**
- Modify: `plugins/orbit-base/agents/leader.md` — add an `## Autonomous Loop (opt-in)` section after the existing `## High-Risk Decision Gate (critic branch)` section.

**Interfaces:**
- Consumes: the low-risk definition and auto-halt rule from `CLAUDE.md` (Task 2) — reference them, do not restate the four conditions.
- Produces: the leader loop contract that `orbit-cycle.md` (Task 5) and `using-orbit` (Task 4) point to.

- [ ] **Step 1: Add the Autonomous Loop section to leader.md**

Insert after the `## High-Risk Decision Gate (critic branch)` section, before `## Plan Approval Gate`:

```markdown
## Autonomous Loop (opt-in)

Off by default. Runs only after the user grants a **batch pre-approval** (see CLAUDE.md → Autonomous Mode). Absent pre-approval, every task uses the normal per-task Plan Approval Gate — no change.

**Continuous execution = the leader looping, never agent handoff.** Hub-and-spoke is unbroken: the leader still dispatches each agent, receives text output, and decides the next step. Builder, critic, and reviewer never talk to each other. "Autonomous" means the *human* is not re-prompted each task — it does not mean spokes communicate.

**Accepting a batch (critic-on-entry first).** The leader enumerates the pre-approved scope from the roadmap (explicit IDs or a bounded predicate). If the scope is open-ended, unenumerable, or larger than the **batch-size cap (at most 5 tasks)**, the leader declines and requests a bounded scope. Before asking the user to grant pre-approval, the leader **dispatches the critic once for an on-entry eligibility screen**: the critic independently reviews the entire enumerated list and confirms every task is *manifestly all-no* on the four triggers. Tasks the critic flags as high-risk or ambiguous are removed from the autonomous batch (routed to normal per-task approval); the leader presents the critic-cleared remainder to the user, and the user pre-approves *that* list. The enumerated cleared list plus the critic verdict is the pre-approval record.

**Loop per task (within scope):**
1. Dispatch architect (writing-plans) → receive plan. (Plans are generated **at loop time** for the current task — never pre-generated at batch start — so each reflects the current codebase.)
2. Apply the four-trigger OR gate to the plan (same gate as the critic branch), at the **manifestly-all-no** standard and judging **T2 on batch-cumulative blast radius** (distinct components touched by the batch so far + those this task touches; ≥ 3 fires T2).
   - **All four manifestly no (low-risk):** treat Plan Approval as already granted by the batch. Dispatch builder. Run full Triple Crown. On pass: mark roadmap checkbox, update the cumulative component tally, continue to next task.
   - **Any trigger fires OR the judgment is ambiguous (high-risk / unclear):** **eject this task from the batch and halt the loop.** The rule is **ambiguous ⇒ stop, never ambiguous ⇒ proceed.** Dispatch the critic (high-risk branch), then escalate to the user for individual Plan Approval. The loop does not resume automatically — the human decides.
3. **At each task boundary**, before dispatching the next task: (a) **re-validate scope** — re-check the roadmap/codebase; if either has materially changed (items added/removed, or a completed task altered a pending task's assumptions), **re-enumerate and re-run critic-on-entry over the remaining items** before continuing; (b) **check for a withdrawal signal** — if withdrawn, stop after the current task's Triple Crown and commit complete (no mid-task kill).
4. **Batch-size cap + re-sync.** On reaching the 5-task cap OR the cumulative blast-radius ceiling, halt the loop and return to the human for an explicit re-sync (re-state what was done, request fresh pre-approval for any continuation). An autonomous run can never silently outrun human oversight.

**Failure rollback.** If a task fails Triple Crown ② or ③, **halt the loop** (do not continue). Prior tasks stay committed (each was independently verified). Escalate the failed task to the user. The loop is halt-on-first-failure, not isolate-and-continue.

**Verification is never lightened.** Triple Crown applies in full to every task in the loop. Autonomy lowers human-approval frequency, not verification strength. (Loop length multiplies SubagentStop quality-gate runs; this cost is accepted.)
```

- [ ] **Step 2: Run the harness to verify the leader.md checks flip to PASS**

Run: `bash .planning/verify-autonomous-mode.sh`
Expected: `PASS: C4a leader auto-halt`, `PASS: C5a leader loop-not-handoff`, `PASS: C5b hub-and-spoke still present`, `PASS: C7 withdrawal documented`, `PASS: C11b leader critic-on-entry`, `PASS: C12b leader conservative default`, `PASS: C13c leader cumulative+cap`, `PASS: C14b leader scope re-validation`. C11c (critic.md) still FAIL until Task 4.

- [ ] **Step 3: Verify frontmatter intact**

Run: `awk 'NR==1{a=($0=="---")} /^name:/{n=1} /^description:/{d=1} /^model:/{m=1} END{exit !(a&&n&&d&&m)}' plugins/orbit-base/agents/leader.md && echo OK`
Expected: `OK` (frontmatter `name`/`description`/`model` untouched).

- [ ] **Step 4: Commit**

```bash
git add plugins/orbit-base/agents/leader.md
git commit -m "feat(base): add leader autonomous-loop behavior (opt-in)"
```

---

### Task 4: Critic note — auto-halt line + on-entry batch eligibility screen + invariant carve-out

A note in `critic.md` that the same four triggers serve as the autonomous-mode auto-halt line, **and** that the critic performs the on-entry batch eligibility screen before a batch pre-approval. The four-trigger *definition* does not change (no new triggers, no fork); only the critic's *invocation surface* gains a second leader-gated entry point (on-entry screen). This keeps the four-trigger table as the single owned source.

**Invariant-conflict carve-out (N1).** The existing `critic.md:22` sentence — *"If all four are no, the critic does not run — the normal lifecycle proceeds directly to Plan Approval."* — is an **unconditional** claim that directly contradicts critic-on-entry (which runs the critic precisely to confirm a batch is all-no). Left unscoped, the shipped `critic.md` would carry two conflicting invocation rules, violating this plan's own no-fork / single-source principle. Task 4 therefore **scopes that sentence**: the "all-no ⇒ critic does not run" rule applies to the **per-task general lifecycle only**, with an explicit **carve-out** that the leader-gated autonomous-mode on-entry batch screen is the exception. This is a *scoping clause on the existing sentence*, not a new trigger and not a fork of the table.

**Files:**
- Modify: `plugins/orbit-base/agents/critic.md` — (a) scope the existing "If all four are no…" sentence with the autonomous carve-out; (b) add a short note documenting the two leader-gated invocation points under the four-trigger table in the "When the Critic Is Invoked" section.

**Interfaces:**
- Consumes: the four-trigger table (already in critic.md — the canonical owner).
- Produces: documents the two leader-gated invocation points (on-entry batch screen + fired-trigger branch); the trigger definitions are unchanged and unforked; the "all-no ⇒ no critic" invariant is scoped to the per-task lifecycle.

- [ ] **Step 1: Scope the existing "If all four are no…" sentence (carve-out)**

Replace the existing `critic.md:22` sentence:

```markdown
If all four are no, the critic does not run — the normal lifecycle proceeds directly to Plan Approval. The critic never lobbies to be invoked; invocation is the leader's decision.
```

with the scoped form (adds the per-task-lifecycle qualifier + the autonomous carve-out; everything else unchanged):

```markdown
If all four are no, the critic does not run **in the normal per-task lifecycle** — that lifecycle proceeds directly to Plan Approval. **Exception (opt-in autonomous mode):** the leader-gated on-entry batch eligibility screen below *does* dispatch the critic over an all-no candidate batch — there, running the critic to *confirm* every task is manifestly all-no is the point, not a contradiction. The critic never lobbies to be invoked; invocation is the leader's decision in both cases.
```

- [ ] **Step 2: Add the two-invocation-points note after the four-trigger table in critic.md**

Insert immediately after the (now scoped) "If all four are no…" paragraph in `## When the Critic Is Invoked`:

```markdown
These same four triggers serve opt-in autonomous mode in two leader-gated ways (the trigger definitions are unchanged):

1. **On-entry batch eligibility screen.** Before the user grants a batch pre-approval, the leader dispatches the critic to independently review the **entire enumerated batch** — confirming every task is *manifestly all-no* on the four triggers. Any task that is high-risk or ambiguous is flagged and removed from the autonomous batch. This is a second pair of eyes at the entry point.
2. **Auto-halt line.** During an autonomous batch, any trigger firing (or an ambiguous judgment) ejects the task from the batch and halts the loop, routing it through this critic gate plus individual human approval.

See leader.md → Autonomous Loop and CLAUDE.md → Autonomous Mode. The critic still never self-invokes — both entry points are leader-gated.
```

- [ ] **Step 3: Run the harness to verify C6, C6b, and C11c PASS and no fork introduced**

Run: `bash .planning/verify-autonomous-mode.sh`
Expected: `PASS: C6 critic four-trigger intact`, `PASS: C6b critic all-no carve-out` (the unconditional "does not run when all-no" claim is now scoped — see C6b in Task 1), `PASS: C11c critic.md owns on-entry`. Then confirm the four-trigger table still appears exactly once as a defining table:
Run: `grep -c 'Irreversibility' plugins/orbit-base/agents/critic.md`
Expected: `1` (the canonical table row — the new note references, does not restate, the table).

- [ ] **Step 4: Verify frontmatter intact**

Run: `awk 'NR==1{a=($0=="---")} /^name:/{n=1} /^description:/{d=1} /^model:/{m=1} END{exit !(a&&n&&d&&m)}' plugins/orbit-base/agents/critic.md && echo OK`
Expected: `OK`

- [ ] **Step 5: Commit**

```bash
git add plugins/orbit-base/agents/critic.md
git commit -m "feat(base): note four-trigger gate doubles as autonomous auto-halt line; scope all-no invariant"
```

---

### Task 5: using-orbit orientation + degradation row

Mirror the autonomous-mode contract in the orientation skill (the first thing read in a session) in orientation register, and add a degradation-table row for the autonomous loop by environment.

**Files:**
- Modify: `plugins/orbit-base/skills/using-orbit/SKILL.md` — add an "Autonomous Mode (opt-in)" subsection under the lifecycle, a Quick Reference row, and a "Graceful Degradation by Environment" table row.

**Interfaces:**
- Consumes: definitions in CLAUDE.md (Task 2) and leader.md (Task 3) — reference, do not restate the four conditions.
- Produces: orientation-level summary; no new contract.

- [ ] **Step 1: Add the Autonomous Mode subsection after "Optional Branch: Skillify (after Done)"**

```markdown
### Optional Mode: Autonomous Loop (opt-in, default off)

By default every task uses per-task Plan Approval — unchanged. The user may instead grant a **batch pre-approval**: one exercise of the Plan Approval Gate over a named, finite set of roadmap tasks (capped at a few tasks). Before that approval, the **critic independently screens the whole batch on entry** — every task must be *manifestly* low-risk (four-trigger all-no). Within the cleared scope the leader runs an **autonomous loop** — plan → four-trigger gate → build → full Triple Crown → next — without re-prompting the human each task. The judgment is conservative: **anything ambiguous halts the loop** (ambiguous ⇒ stop). Blast radius is tracked **cumulatively across the batch**, and the loop halts for a human re-sync on reaching the batch-size cap. Hub-and-spoke is preserved: the leader loops; agents never hand off to each other. If any task's plan fires a four-trigger (high-risk) or is ambiguous, it is **ejected from the batch and the loop halts** for individual human approval — the human gate for high-risk work stays non-negotiable. Triple Crown is never lightened. See CLAUDE.md → Autonomous Mode and leader.md → Autonomous Loop.
```

- [ ] **Step 2: Add a Quick Reference row**

In the `## Quick Reference` table, add after the `Plan Approval` row:

```markdown
| Autonomous Mode | Opt-in (default off): critic screens a finite low-risk batch on entry; user pre-approves once; leader loops with cumulative blast-radius + batch cap; any four-trigger firing or ambiguity halts the loop for individual approval |
```

- [ ] **Step 3: Add a degradation-table row**

In the `## Graceful Degradation by Environment` table, add a row:

```markdown
| Autonomous loop (opt-in) | Full (leader loop over Agent dispatch) | Sequential (no background pseudo-parallelism) | Manual sequential (single context, role-switch per task) |
```

- [ ] **Step 4: Run the harness to verify C2b flips to PASS**

Run: `bash .planning/verify-autonomous-mode.sh`
Expected: `PASS: C2b using-orbit default-off`.

- [ ] **Step 5: Commit**

```bash
git add plugins/orbit-base/skills/using-orbit/SKILL.md
git commit -m "feat(base): document autonomous mode in using-orbit orientation + degradation"
```

---

### Task 6: orbit-cycle command (Korean) — batch run guidance

Add a section to the Korean `orbit-cycle.md` slash command on running a pre-approved batch. Match the file's Korean register.

**Files:**
- Modify: `plugins/orbit-base/commands/orbit-cycle.md` — add a section after "Step 6: 완료" and a caveat in "유의사항".

**Interfaces:**
- Consumes: leader.md Autonomous Loop and CLAUDE.md Autonomous Mode.
- Produces: command-level usage guidance.

- [ ] **Step 1: Add the autonomous batch section after "Step 6: 완료"**

```markdown
---

## (선택) 자율 모드 — 묶음 선승인 (기본 비활성)

기본값은 작업마다 Plan Approval이다(위 Step 3 그대로). 사용자가 명시적으로 **묶음 선승인**을 줄 때만 자율 루프가 동작한다.

**묶음 선승인 입력:** 사용자는 roadmap의 **유한하고 열거 가능한** 저위험 작업 집합을 지정한다(명시적 항목 ID, 또는 roadmap에 대한 한정 술어). "끝까지 알아서"처럼 범위가 열려 있거나 **묶음 상한(최대 5건)**을 넘으면 리드는 거절하고 한정된 범위를 요청한다.

**진입 시 critic 선검증(critic-on-entry):** 사용자가 선승인을 주기 *전에*, 리드는 범위를 열거하고 **critic을 1회 파견**해 열거된 묶음 전체가 4트리거 전부-no(명백한 저위험)인지 독립 검토한다. critic이 고위험·모호로 표시한 작업은 자율 묶음에서 제외(개별 승인 경로)되고, 사용자는 critic이 통과시킨 나머지만 선승인한다. 사후 발화가 아니라 진입 시점의 제2의 눈이다.

**자율 루프 (범위 내 작업마다):**
1. 리드가 architect 파견 → 플랜 수령(플랜은 루프 시점에 현재 작업용으로 생성 — 사전 일괄 생성 금지).
2. 4트리거 OR 게이트 적용(**명백한 전부-no** 기준, **T2는 묶음 누적 blast radius**로 판정: 지금까지 건드린 컴포넌트 + 이번 작업이 건드릴 컴포넌트, 합계 3개 이상이면 발화):
   - **전부 명백히 no(저위험):** 묶음 선승인으로 Plan Approval을 받은 것으로 간주 → builder 파견 → 전체 3갈래 검증 → 통과 시 다음 작업, 누적 컴포넌트 집계 갱신.
   - **하나라도 발화 또는 판정이 모호(고위험·불명확):** 해당 작업을 **묶음에서 제외하고 루프 정지** → critic 게이트 + 개별 사용자 승인. 원칙은 **모호 ⇒ 정지, 모호 ⇒ 진행 아님.** 사람 게이트는 예외 없이 유지된다.
3. **각 작업 경계에서:** (a) **범위 재검증** — roadmap/코드베이스가 실질적으로 변했으면(항목 추가·삭제, 또는 완료 작업이 대기 작업의 전제를 바꿈) 남은 항목에 대해 **재열거 + critic-on-entry 재실행** 후 진행; (b) **철회 신호 확인** — 철회 시 진행 중 작업의 3갈래 검증·커밋까지 마치고 정지(작업 중간 강제 종료 없음).
4. **묶음 상한 + 재동기화:** 5건 상한 또는 누적 blast radius 한도에 도달하면 루프를 정지하고 사람에게 돌아가 명시적 재동기화(완료 내역 보고 + 신규 선승인 요청)한다. 자율 실행이 사람 감독을 조용히 앞질러 갈 수 없다.

**실패 롤백:** 루프 중 작업이 3갈래 검증 ②/③에서 실패하면 루프를 정지한다(다음 작업으로 넘어가지 않음). 앞서 통과·커밋된 작업은 유지된다.

허브앤스포크 불변: "연속 실행"은 리드가 루프를 도는 것이지 에이전트끼리 핸드오프하는 것이 아니다. 3갈래 검증은 경량화되지 않는다.
```

- [ ] **Step 2: Add caveats to "유의사항"**

Append two bullets to the `## 유의사항` list:

```markdown
- **자율 모드는 opt-in**: 명시적 묶음 선승인이 없으면 항상 작업별 Plan Approval(기본값). 자율 모드는 사람 승인 빈도만 낮추고 검증 강도는 낮추지 않는다.
- **진입 시 critic 선검증**: 선승인 전 critic이 묶음 전체의 자율 적격성(전부 명백히 저위험)을 1회 독립 검토한다.
- **모호 ⇒ 정지**: 4트리거 판정이 명백한 전부-no가 아니면(모호하면) 루프를 정지하고 개별 재승인한다.
- **4트리거 자동 정지 + 누적 판정**: 자율 루프 중 4트리거가 하나라도 발화(누적 blast radius 포함)하면 해당 작업은 묶음에서 제외되고 루프가 정지해 개별 승인을 요한다.
- **묶음 상한**: 최대 5건 또는 누적 blast radius 한도 도달 시 정지하고 사람 재동기화.
```

- [ ] **Step 3: Verify domain purity + no project name**

Run: `grep -riE 'oremi|orbit-dev' plugins/orbit-base/commands/orbit-cycle.md; echo "exit=$?"`
Expected: `exit=1` (grep found nothing).

- [ ] **Step 4: Commit**

```bash
git add plugins/orbit-base/commands/orbit-cycle.md
git commit -m "feat(base): add autonomous batch guidance to orbit-cycle command"
```

---

### Task 7: Codex + Gemini degradation references

One line each in the codex/gemini tool references describing how the autonomous loop degrades, satisfying the spike's §6.6 graceful-degradation question.

**Files:**
- Modify: `plugins/orbit-base/skills/using-orbit/references/codex-tools.md`
- Modify: `plugins/orbit-base/skills/using-orbit/references/gemini-tools.md`

**Interfaces:**
- Consumes: the degradation row added in using-orbit (Task 5) — keep consistent.
- Produces: nothing new.

- [ ] **Step 1: Add a note to codex-tools.md**

Append a short section at the end:

```markdown
## Autonomous Mode (opt-in)

Orbit's opt-in autonomous loop runs **sequentially** under Codex: the leader processes one pre-approved batch task at a time. Codex's `spawn_agent` / `multi_agent=true` give partial dispatch, but no reliable background pseudo-parallelism, so the loop is strictly serial. The four-trigger auto-halt and full Triple Crown apply identically — only throughput differs.
```

- [ ] **Step 2: Add a note to gemini-tools.md**

Append a short section at the end:

```markdown
## Autonomous Mode (opt-in)

Under Gemini CLI's single-context, role-switching model, orbit's opt-in autonomous loop is **manual sequential**: the leader role processes each pre-approved batch task in turn, switching roles per step. The four-trigger auto-halt and full Triple Crown still apply; the human still grants the batch pre-approval once and the loop still halts on any high-risk firing.
```

- [ ] **Step 3: Run the full harness — all checks PASS**

Run: `bash .planning/verify-autonomous-mode.sh; echo "exit=$?"`
Expected: every line `PASS:` and `exit=0`.

- [ ] **Step 4: Commit**

```bash
git add plugins/orbit-base/skills/using-orbit/references/codex-tools.md plugins/orbit-base/skills/using-orbit/references/gemini-tools.md
git commit -m "feat(base): document autonomous loop degradation for Codex and Gemini"
```

---

### Task 8: Manifest baseline + final consistency sweep

Confirm the manifest needs no new field, validate it, and run the full multi-surface consistency sweep including the two behavioral walkthrough scenarios the spec requires.

**Files:**
- Modify (only if a version bump is policy): `plugins/orbit-base/.claude-plugin/plugin.json` — validate; bump version only if the project versions feature additions. No new field.

**Interfaces:**
- Consumes: all prior tasks.
- Produces: the green final state.

- [ ] **Step 1: Validate the manifest**

Run: `python3 -c 'import json; json.load(open("plugins/orbit-base/.claude-plugin/plugin.json")); print("valid")'`
Expected: `valid`. Confirm by reading that no autonomous-mode field is needed — autonomous mode is prose behavior, not a manifest capability.

- [ ] **Step 2: Run the full harness**

Run: `bash .planning/verify-autonomous-mode.sh; echo "exit=$?"`
Expected: all `PASS:`, `exit=0`.

- [ ] **Step 3: Behavioral walkthrough scenario A — default-off backward compat**

Read `leader.md`, `CLAUDE.md`, `using-orbit/SKILL.md` and confirm in prose: with NO pre-approval mentioned, the documented behavior is identical to the pre-change per-task Plan Approval. Verification command:
Run: `git show HEAD~7:plugins/orbit-base/CLAUDE.md > /tmp/before.md 2>/dev/null; grep -A3 'Plan Approval Gate' plugins/orbit-base/CLAUDE.md | head -5`
Expected: the per-task gate criteria (Tests/Impact/Conflicts/Success) are unchanged and present. Reviewer confirms no default path was altered.

- [ ] **Step 4: Behavioral walkthrough scenario B — four-trigger auto-halt**

Trace in `leader.md` Autonomous Loop: a batch task whose plan fires T2 (blast radius). Confirm the prose mandates: eject from batch → halt loop → critic gate → individual human approval. Verification command:
Run: `grep -A2 -iE 'any trigger fires' plugins/orbit-base/agents/leader.md`
Expected: prose stating eject + halt + escalate to individual Plan Approval.

- [ ] **Step 4b: Behavioral walkthrough scenario C — critic-on-entry independent screen**

Trace in `leader.md`/`CLAUDE.md`/`critic.md`: before pre-approval, the critic reviews the whole enumerated batch and removes any not-manifestly-all-no task; only the cleared remainder is pre-approved. Confirm the second-eyes-at-entry safeguard exists, not just the post-firing branch. Verification command:
Run: `bash .planning/verify-autonomous-mode.sh | grep -E 'C11'`
Expected: `PASS: C11a`, `PASS: C11b`, `PASS: C11c`. Reviewer confirms the prose in all three files agrees that the screen runs *before* pre-approval.

- [ ] **Step 4c: Behavioral walkthrough scenario D — conservative default + cumulative blast radius**

Trace in `leader.md`/`CLAUDE.md`: (1) an ambiguous (not manifestly all-no) judgment halts the loop ("ambiguous ⇒ stop"); (2) three single-task-contained edits that cumulatively touch ≥ 3 components fire T2 via the batch-cumulative rule and halt for re-sync; (3) the batch-size cap returns control to the human. Verification command:
Run: `bash .planning/verify-autonomous-mode.sh | grep -E 'C12|C13|C14'`
Expected: `PASS: C12a/C12b` (conservative default), `PASS: C13a/C13b/C13c` (cumulative T2 + cap/re-sync), `PASS: C14a/C14b` (scope re-validation). Reviewer confirms no surface says "ambiguous ⇒ proceed" and that T2 is described as cumulative, not per-task-isolated.

- [ ] **Step 5: Multi-surface consistency grep**

Run: `grep -rl -i 'autonomous' plugins/orbit-base | sort`
Expected: exactly these 7 files — `CLAUDE.md`, `agents/leader.md`, `agents/critic.md`, `skills/using-orbit/SKILL.md`, `commands/orbit-cycle.md`, `skills/using-orbit/references/codex-tools.md`, `skills/using-orbit/references/gemini-tools.md` (7 surfaces). Confirm none contradict the others on default-off, auto-halt, hub-and-spoke, or Triple Crown.

- [ ] **Step 6: Final domain-purity gate (simulates SubagentStop)**

Run: `grep -rciE 'oremi|Oremi|orbit-dev' plugins/orbit-base | awk -F: '{s+=$2} END{print s+0}'`
Expected: `0`.

- [ ] **Step 7: Commit (manifest only if bumped)**

```bash
git add plugins/orbit-base/.claude-plugin/plugin.json 2>/dev/null
git commit -m "chore(base): validate manifest for autonomous-mode addition" --allow-empty
```

---

## Impact Scope (for Plan Approval Gate item 2)

**Product files edited (7 surfaces):** `CLAUDE.md`, `agents/leader.md`, `agents/critic.md`, `skills/using-orbit/SKILL.md`, `commands/orbit-cycle.md`, `skills/using-orbit/references/codex-tools.md`, `skills/using-orbit/references/gemini-tools.md`.
**Manifest:** `.claude-plugin/plugin.json` — validated, no new field (optional version bump).
**Dev artifact (not product):** `.planning/verify-autonomous-mode.sh`.
**Out of scope (untouched):** `.claude/` (incl. dev `leader.md`), root `README.md`, `setup-orbit.sh`, `.codex-plugin/plugin.json`, `gemini-extension.json`.
**Public-contract change:** the *meaning* of the Plan Approval Gate is extended (per-task OR batch-scoped). This is why the change is high-risk (T2).

## Architecture-Conflict Statement (for Plan Approval Gate item 3)

- **Hub-and-spoke: preserved.** Continuous execution is the leader looping; agents never hand off. Verified by C5a/C5b and walkthrough A.
- **Single entry point: preserved.** The leader remains the sole router and gatekeeper; the critic still never self-invokes.
- **Human gate: preserved (re-exercised, not removed).** Batch pre-approval = one exercise of the gate; any four-trigger firing OR any ambiguity forces individual approval. Two safeguards close the leader-self-judgment gap: critic-on-entry (independent batch screen before pre-approval) and the conservative "ambiguous ⇒ stop" default. The "non-negotiable" sentence is reconciled, not deleted (C3 + Task 2 Step 2; C11/C12).
- **Accumulation bounded.** T2 is judged on batch-cumulative blast radius; an autonomous batch is capped (≤ 5 tasks + cumulative ceiling) with a mandatory human re-sync; scope is re-validated at every task boundary (C13/C14). Single-point judgment cannot let accumulation, cross-task interaction, or staleness drift past oversight.
- **Lightweight: preserved.** Zero new roles, zero new hooks, zero new state files, zero new dependencies (T4 no); critic-on-entry reuses the existing critic agent. Net: prose additions to 7 existing files.
- **Domain purity: preserved.** No project names; the eligibility criterion is the domain-agnostic four-trigger gate (C1 + final gate).

## Success Criteria (measurable, for Plan Approval Gate item 4)

1. `bash .planning/verify-autonomous-mode.sh` exits 0 (all C1–C14 PASS, including C6b).
2. `grep -rciE 'oremi|Oremi|orbit-dev' plugins/orbit-base` sums to 0 (domain purity).
3. Default-off proven: per-task Plan Approval criteria in `CLAUDE.md` unchanged (walkthrough A).
4. Auto-halt proven: `leader.md` mandates eject+halt+individual-approval on any trigger firing or ambiguity (walkthrough B).
5. `python3 -c 'json.load(open(".claude-plugin/plugin.json"))'` succeeds (manifest valid).
6. Frontmatter (`name`/`description`/`model`) intact on `leader.md` and `critic.md` (C9).
7. The four-trigger table remains owned by `critic.md` (appears once as a defining table) — no fork (C6 + Task 4 Step 2); and the "all-no ⇒ critic does not run" invariant is scoped to the per-task lifecycle with an explicit autonomous carve-out — no unconditional contradiction survives (C6b + Task 4 Step 1).
8. All 7 surfaces agree on the contract invariants (default-off, auto-halt, hub-and-spoke, Triple Crown, conservative-default, cumulative-T2) — Task 8 Step 5.
9. Critic-on-entry proven: `CLAUDE.md`/`leader.md`/`critic.md` all state the critic independently screens the whole batch *before* pre-approval (C11a/b/c + walkthrough C).
10. Conservative default proven: every relevant surface states "ambiguous ⇒ stop"; no surface says "ambiguous ⇒ proceed" (C12 + walkthrough D).
11. Accumulation bounded proven: batch-cumulative T2 + batch-size cap/re-sync (C13) and per-boundary scope re-validation (C14) present in `CLAUDE.md` and `leader.md` (walkthrough D).

## Testing Strategy Summary (for Plan Approval Gate item 1)

- **Domain purity gate:** grep sum == 0 (C1, final gate) — simulates SubagentStop.
- **Frontmatter/manifest validity:** awk frontmatter check (C9), JSON parse (C8).
- **Multi-surface consistency grep:** Task 8 Step 5 — all surfaces named, no contradiction.
- **"Opt-in default-off" verification:** C2a/C2b + walkthrough scenario A (default path unchanged).
- **"Four-trigger auto-halt" behavior verification:** C4a/C4b + walkthrough scenario B (trace the halt).
- **"Critic-on-entry" verification:** C11a/b/c + walkthrough scenario C (independent batch screen before pre-approval, agreed across all three files).
- **"Conservative default + bounded accumulation" verification:** C12 (ambiguous ⇒ stop), C13 (cumulative T2 + batch cap/re-sync), C14 (per-boundary scope re-validation) + walkthrough scenario D.
- TDD discipline adapted to prose: harness (Task 1) is written first and fails; each task flips named checks red→green.

## Self-Review

**Spec coverage:** Every spec mandate maps to a task — operational "low-risk" definition (Task 2 + ADR-001); scope expression & withdrawal (Task 2 def + Task 3 Step 1 + Task 6); loop control / failure rollback / Triple Crown (Task 3); multi-surface enumeration via grep (verified against actual repo — 7 surfaces in Task 8 Step 5); backward-compat default-off (Task 2, every surface, success criterion 3); Plan Approval Gate 4 items (sections above); high-risk basis (dedicated section). The spec listed `codex-tools.md`/`gemini-tools.md` as surfaces — covered (Task 7). The spec mentioned `setup-orbit.sh`/`.claude/`/root README as out of scope — enforced in Global Constraints. **Note:** the spec mentioned the dev-team `.claude/leader.md` confusion risk — Global Constraints pins all "leader.md" references to the product path.

**Critic-revision coverage (this revision):** blocker #1 — (a) conservative "ambiguous ⇒ stop" default (operational defs + Task 2/3, C12) and (b) critic-on-entry independent batch screen (operational defs + Tasks 2/3/4, C11), both written into CLAUDE.md + leader.md contract prose and critic.md responsibility; major #2 — batch-cumulative T2 + batch-size cap/re-sync (operational defs + Tasks 2/3/6, C13); major #3 — per-boundary scope re-validation + loop-time plan generation (operational defs + Task 3, C14); minor #4 — reversibility note softened (file-byte-exact vs public-contract deprecation cost; default-off = adoption compat only); minor #6 — spike's A'-first recommendation consciously rejected and owned as ADR-002.

**Re-critic-revision coverage (this revision):** N1 (major) — the unconditional `critic.md:22` "all four are no ⇒ critic does not run" claim is now scoped to the per-task lifecycle with an explicit autonomous on-entry carve-out (Task 4 Step 1), and a dedicated harness check **C6b** fails on any surviving unconditional form (Task 1; C6's table-presence check could not catch the contradiction); critic.md is reflected consistently in Impact Scope (7 surfaces), Architecture-Conflict Statement, and Success Criterion 7. N2 (minor) — Task 8 Step 5 miscount "exactly these 6 files" corrected to **7 files** with the enumerated list matching the count.

**Placeholder scan:** no TBD/TODO; all prose blocks are complete insert-ready text; all commands have expected output.

**Type consistency:** check IDs (C1–C14, incl. C6b) are consistent between the harness (Task 1) and the tasks that flip them (C6b is written in Task 1 and flipped in Task 4 Step 1/3). "four-trigger OR gate", "auto-halt", "eject", "batch pre-approval", "default-off", "critic-on-entry", "manifestly all-no", "ambiguous ⇒ stop", "batch-cumulative blast radius", "batch-size cap", "scope re-validation" used with identical meaning across all tasks.
