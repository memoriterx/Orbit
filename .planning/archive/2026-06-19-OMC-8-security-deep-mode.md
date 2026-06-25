# Triple Crown ③ Security Deep-Mode + Explore Roster Fix Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a security deep-mode to the reviewer's Triple Crown ③ Quality prong (no new agent, roster stays at 7 roles), and fix the `explore` roster gap in `leader.md` and `codex-tools.md` — with a real token-extraction set-diff gate and a designated-canonical-reference (no-new-copy) gate that make both changes drift-resistant.

**Architecture:** This is the *alternative* to the rejected `security-reviewer` agent. Instead of a new role, ③ Quality gains a conditional **deep-mode**: when a change touches the security surface, ③ escalates from a lightweight scan to a deep OWASP-style category sweep. The security surface category string already exists in three pre-existing trigger rows (critic.md T3, leader.md T3, CLAUDE.md autonomous gate) — this plan does **not** unify them into one literal copy (that would be a larger refactor than this change warrants). Instead it **designates critic.md T3 as the canonical *reference* origin**: the two deep-mode documents this plan touches (reviewer.md, SKILL.md) point to that row *by name* ("critic T3 security surface") rather than adding a 4th hardcoded copy. The drift control is therefore honest and modest: **a no-new-copy count gate** (the literal category string must not appear in reviewer.md or SKILL.md) plus **vocabulary-anchor identity** (every deep-mode reference uses the same anchor phrase "critic T3 security surface", asserted present in critic.md, reviewer.md, and SKILL.md). This is *not* "single source of truth" — three legacy copies persist by design; it is "designated reference origin + no new copy." ③ deep-mode's entry condition is *measurable and identical in predicate* to critic T3, which gives a free soft-link: a plan that fired T3 at design time should drive ③ into deep-mode at verify time. Because critic T3 firing is itself a high-risk trigger that ejects a task from any autonomous batch, ③ deep-mode is documented as a **per-task-mode** behavior (mutually exclusive with the autonomous batch, not orthogonal to it).

**Tech Stack:** Markdown agent prompt files (`agents/*.md` with `name`/`description`/`model` frontmatter), Markdown skill + reference docs (`skills/using-orbit/`). No new agent, no new hook, no new script, no manifest schema change, no model-tier change. Verification is by `grep`/`jq`/manual structural checks.

## Global Constraints

Copied verbatim from the task brief and project rules — every task implicitly inherits these:

- **Scope is `plugins/orbit-base/` only.** Dev-team files (`.claude/`, `setup-orbit*.sh`, top-level `README.md`) are out of scope. Do NOT modify them.
- **No new agent. Roster stays at 7 roles** (leader / architect / builder / explore / critic / reviewer / researcher). No new manifest entry, no role-count change anywhere (7 stays 7).
- **Reviewer model tier unchanged** (`reviewer.md` frontmatter `model: opus` stays as-is).
- **Domain purity:** no project name (`oremi`, `Oremi`, `orbit-dev`, etc.) hardcoded anywhere in `plugins/orbit-base/`. Domain-variable values stay as `{{...}}` slots. Gate: `grep -riE 'oremi|orbit-dev' plugins/orbit-base/` returns 0 hits.
- **Domain-agnostic security categories:** the deep-mode checklist uses universal OWASP-style category *names* as vocabulary, parameterized through a `{{SECURITY_CHECK_CATEGORIES}}` slot. No language/framework hardcoded.
- **Designated reference origin for the security surface (NOT single-source-of-truth):** the category string `auth, permissions, secrets, deletion, or money/PII` already exists in **three** pre-existing trigger rows — critic.md T3 (comma-form), leader.md T3 (comma-form), and CLAUDE.md autonomous gate (slash-form variant). This plan does NOT collapse them into one literal. It **designates critic.md T3 as the canonical *reference* origin** and requires the two new deep-mode documents (reviewer.md, SKILL.md) to reference it **by the anchor phrase "critic T3 security surface"** rather than restating the category list. The integrity property enforced is honest and bounded: **(a) no new literal copy** — the comma-form string must not newly appear in reviewer.md or SKILL.md; **(b) vocabulary-anchor identity** — the anchor phrase "critic T3 security surface" appears verbatim in critic.md, reviewer.md, and SKILL.md so a future rename is grep-detectable across all referrers. Task 6's gates assert (a) by count and (b) by presence. The pre-existing three copies are left untouched and are out of scope for this plan.
- **Tone/structure parity:** match the existing `reviewer.md` / `critic.md` frontmatter, section order, table styles, "Domain Slots" table, and "Error Handling" conventions.
- **No commit `Co-Authored-By` lines.** Commit prefixes: `feat/fix/chore/docs/refactor:`.

---

## File Structure

| File | Action | Responsibility after change |
|------|--------|------------------------------|
| `plugins/orbit-base/agents/critic.md` | Modify | Add a visible anchor note naming the T3 trigger row the **canonical reference origin** for the security surface under the phrase "critic T3 security surface" (no HTML-comment marker; the anchor is the named phrase others grep for). Add a one-line soft-link note — scoped to the per-task / T3-fired path — that a fired T3 carries forward to reviewer ③ deep-mode. |
| `plugins/orbit-base/agents/reviewer.md` | Modify | ③ Quality prong gains a **deep-mode**: entry condition = "the change touches the security surface (critic T3 canonical definition)"; deep-mode runs an OWASP-style sweep over `{{SECURITY_CHECK_CATEGORIES}}`. Add the per-task-mode mutual-exclusivity sentence and the T3 soft-link inheritance sentence. Add the new slot to the Domain Slots table. |
| `plugins/orbit-base/agents/leader.md` | Modify | (a) Add `explore` to the Team Structure table (roster fix). (b) One line: when dispatching the reviewer, the leader signals whether the task touched the security surface (so ③ enters deep-mode), reusing the T3 judgment it already made. |
| `plugins/orbit-base/skills/using-orbit/SKILL.md` | Modify | Document ③ deep-mode in the Triple Crown section + a Quick Reference row; reference the canonical surface; state per-task-mode exclusivity. (explore already present here — no roster change needed.) |
| `plugins/orbit-base/skills/using-orbit/references/codex-tools.md` | Modify | Roster fix only: add `explore` to the line-32 sequential role-switching list and confirm the dispatch block already lists it (it does, line 40). |

**Not modified (confirmed by grep):** `CLAUDE.md` (explore already present line 9; T3 surface row stays as the pre-existing autonomous-gate copy — not touched), `GEMINI.md` (only `@`-includes, no roster of its own), `gemini-tools.md` (explore already present, lines 27), `architect.md`, `builder.md`, `explore.md`, `researcher.md`, both `plugin.json` manifests (no roster/role-count field), all hooks/scripts/templates.

---

## Design Resolutions (round-1 closures + round-2 critic REVISE)

These are the load-bearing decisions. The first four close the round-1 critic blockers; they are **preserved**. The round-2 critic REVISE (B1/B2/N1/N2/N3) refines #2 (reference origin, not single-source, no marker), #3/#4 (reviewer's own diff binds; leader-forward demoted to a hint), and scopes #4 to the per-task path. Verification gates in Task 6 were rewritten accordingly (real set-diff extraction; anchor-identity + no-new-copy instead of an HTML marker).

1. **Autonomous-mode mutual exclusivity (closes prior blocker #1).** A security-surface task fires critic T3, which ejects it from any autonomous batch (per CLAUDE.md Auto-halt + leader.md Autonomous Loop). Therefore ③ deep-mode can only ever run in **per-task mode**. The plan states this as *mutual exclusivity*, not orthogonality, in reviewer.md and SKILL.md — one sentence each. No new mechanism; it is an observation made explicit to kill the latent contradiction.

2. **Designated reference origin, not single source (closes prior major #2A — revised per B1).** The earlier draft used an HTML-comment marker `<!-- canonical: security-surface -->` and called critic.md T3 the "single source of truth." That was misleading on two counts: (i) the marker had **zero referential integrity** — it was an invisible per-file token that only let a gate count "is there a 4th copy", it could not detect a vocabulary drift in any referrer; and (ii) three literal copies of the surface string *already* exist (critic.md/leader.md/CLAUDE.md), so "single source" was false. **Revised mechanism (critic's recommended option (a), honest form):** drop the fake marker. Designate critic.md T3 as the canonical **reference origin** with a **visible anchor phrase** the row is named by — "**critic T3 security surface**". reviewer.md ③ deep-mode and SKILL.md reference the surface using that exact anchor phrase, not a restated category list. The drift control is two honest grep assertions (Task 6): **no-new-copy** (the comma-form literal must not appear in reviewer.md/SKILL.md) and **anchor-identity** (the phrase "critic T3 security surface" is present verbatim in critic.md, reviewer.md, SKILL.md — so a future rename of the surface vocabulary is detectable at every referrer). This is "designated reference origin + no new copy + shared anchor phrase," explicitly *not* "single source of truth."

3. **Entry condition measurable (closes prior major #1 / #5A).** ③ deep-mode entry is defined as a boolean: *does the change touch the critic-T3 security surface?* — the exact same predicate critic uses. Not a "deep vs. light examples" list. Task 5's gate checks that reviewer.md states the entry **condition** (references critic T3) and not merely a depth adjective.

4. **Critic T3 ↔ ③ soft-link, with reviewer's diff binding (closes prior major #2B; revised per N2).** critic.md T3 = *plan-stage* (pre-build) signal; ③ deep-mode = *code-stage* (post-build) check. They share the surface vocabulary. **The binding trigger is the reviewer's own inspection of the built diff** — ③ enters deep-mode iff the diff touches the surface, *regardless of whether the leader forwarded the T3 signal*. The leader's plan-stage T3-forward is demoted to a **non-authoritative corroborating hint** (it raises confidence but cannot gate): a forgotten forward can never silently downgrade a security-touching change to light scan. This both recovers the free signal the rejected hard-cut threw away **and** closes the "leader forgets ⇒ unprotected" gap (the round-1 blocker #1 variant). Scoped to the per-task / T3-fired path; see N1.

---

## Task 1: Name critic.md T3 the canonical reference origin (visible anchor phrase) + add scoped ③ soft-link note

**Files:**
- Modify: `plugins/orbit-base/agents/critic.md` — add one anchored note immediately after the trigger table (after current line 20, before the "If all four are no" paragraph). The T3 row itself (line 19) and its category string are **unchanged** — no HTML-comment marker is added (B1: the marker is removed as misleading).

**Interfaces:**
- Produces: the **visible anchor phrase** `critic T3 security surface`, present verbatim in critic.md, which reviewer.md and SKILL.md reference by name. No invisible marker; the phrase itself is the anchor a gate greps for.

- [ ] **Step 1: Write the failing test**

Create the verification check (run it before editing — it must fail):

```bash
# Gate A: critic.md carries the visible anchor phrase exactly once, and the
#         honest framing words ("reference origin", NOT "single source of truth").
C=plugins/orbit-base/agents/critic.md
n=$(grep -c "critic T3 security surface" "$C")
test "$n" -ge 1 \
 && grep -q "canonical reference origin" "$C" \
 && ! grep -qi "single source of truth" "$C" \
 && ! grep -q "canonical: security-surface" "$C" \
 && echo PASS || echo FAIL
```

(The HTML-comment marker `canonical: security-surface` must be ABSENT — Step 3 does not add it. The anchor is the human-readable phrase.)

- [ ] **Step 2: Run it to verify it fails**

Run the Step 1 block.
Expected: `FAIL` (the anchor phrase and note do not exist yet).

- [ ] **Step 3: Make the minimal edit**

Leave line 19 (the T3 row) exactly as-is. Add immediately after the trigger table (after current line 20, before the "If all four are no" paragraph):

```markdown
> **Canonical reference origin — "critic T3 security surface".** The T3 row above is the **designated reference origin** for what counts as a security surface (auth, permissions, secrets, deletion, money/PII). Other documents name this surface by the phrase *critic T3 security surface* instead of restating the list. (This is a reference origin, not a single source of truth: the same category string also appears, by pre-existing design, in leader.md T3 and the CLAUDE.md autonomous gate — those copies are out of scope here. The discipline is: no document this plan touches adds a new copy.)
>
> **Soft-link to verify stage (per-task, T3-fired path only).** *On the per-task lifecycle, when this T3 row fires at plan stage*, the reviewer's Triple Crown ③ enters security deep-mode at verify stage — unless the implementation removed the security surface entirely. T3 is the plan-stage signal; ③ deep-mode is its code-stage counterpart, sharing this surface vocabulary. This note applies **only** to the per-task path where T3 actually fires; it does **not** apply to the autonomous all-no carve-out (a manifestly-all-no task never fires T3, never builds under deep-mode, and "T3 always implies a verify step" is **not** implied).
```

- [ ] **Step 4: Run the gate to verify it passes**

Run the Step 1 block.
Expected: `PASS`.

- [ ] **Step 5: Commit**

```bash
git add plugins/orbit-base/agents/critic.md
git commit -m "feat(critic): name T3 the canonical reference origin + scoped soft-link to reviewer ③ deep-mode"
```

---

## Task 2: Add ③ security deep-mode to reviewer.md (entry condition + per-task exclusivity + T3 inheritance + slot)

**Files:**
- Modify: `plugins/orbit-base/agents/reviewer.md` — Prong ③ section (lines 56-65) and Domain Slots table (lines 82-86).

**Interfaces:**
- Consumes: the canonical name `critic T3 security surface` (from Task 1) and the soft-link rule.
- Produces: the slot `{{SECURITY_CHECK_CATEGORIES}}` (added to the Domain Slots table) consumed by no other task but required for domain purity.

- [ ] **Step 1: Write the failing test**

```bash
# Gate B: reviewer ③ defines deep-mode by ENTRY CONDITION via the anchor phrase,
#         makes the reviewer's OWN diff judgment binding (N2), demotes the leader
#         T3-forward to a corroborating hint, states per-task exclusivity,
#         keeps the read-only/executor-verifier boundary (N3), declares the slot,
#         and does NOT re-hardcode the surface string (B1 no-new-copy).
R=plugins/orbit-base/agents/reviewer.md
grep -q "critic T3 security surface" "$R" \
 && grep -qi "deep-mode" "$R" \
 && grep -qi "if and only if" "$R" \
 && grep -qi "own inspection of the built diff" "$R" \
 && grep -qi "corroborating hint" "$R" \
 && grep -qi "per-task" "$R" \
 && grep -qi "does \*\*not\*\* make the reviewer the remediation owner\|read-only" "$R" \
 && grep -q "{{SECURITY_CHECK_CATEGORIES}}" "$R" \
 && ! grep -q "auth, permissions, secrets, deletion" "$R" \
 && echo PASS || echo FAIL
```

- [ ] **Step 2: Run it to verify it fails**

Run the Step 1 block.
Expected: `FAIL` (none of the deep-mode text exists yet).

- [ ] **Step 3: Make the minimal edit**

Replace the Prong ③ section. Change lines 56-65 from the current ③ block to:

```markdown
### Prong ③ — Quality Review
Apply `{{QUALITY_REVIEW_SKILL}}` (default: superpowers requesting-code-review):
- Correctness bugs
- Security issues (hardcoded secrets, injection vectors)
- Maintainability concerns
- If architecture consistency is suspect, request architect lens review through leader

**Security deep-mode (conditional).** ③ has two modes:
- **Light scan (default):** the security bullet above — a surface read for obvious issues.
- **Deep-mode:** a structured OWASP-style sweep over `{{SECURITY_CHECK_CATEGORIES}}`.

**Entry condition is binding on the reviewer's own diff judgment (not on the leader's memory).** ③ enters deep-mode **if and only if the reviewer's own inspection of the built diff finds it touches the *critic T3 security surface*** (the canonical reference origin defined in `critic.md`; ③ reads the definition there rather than restating the category list here). The reviewer determines this *independently from the change set in front of it*; this self-judgment is the **authoritative** trigger. The same boolean predicate the critic uses at plan stage, applied here to the built code.

**Leader's T3-forward is a non-authoritative corroborating hint, never the gate.** If the leader reports that critic T3 fired at plan stage, that **raises confidence** but is **not** the deciding signal: even if the leader forgets to forward it, ③ still enters deep-mode whenever the reviewer's own diff inspection shows the surface was touched. A missing leader hint can never downgrade a security-touching change to light scan. (Conversely, a forwarded T3 whose surface was fully removed in implementation can drop back to light scan — the diff is what binds.)

**Per-task mode only (mutual exclusivity, not orthogonality):** a security-surface change fires critic T3, which ejects the task from any autonomous batch (see leader.md → Autonomous Loop). Deep-mode therefore runs **only in per-task mode** — it is never reached inside an autonomous batch, because such a task is never autonomous-eligible. The two are mutually exclusive, not parallel.

**Still read-only review (executor/verifier boundary preserved):** deep-mode is a deeper *review* — read-only, findings reported to the leader. It does **not** make the reviewer the remediation owner; fixes are still routed by the leader to the builder. Deeper inspection, same boundary.

Additional static verification per `{{STATIC_VERIFICATION_SKILL}}`:
- API shape / interface cross-comparison
- Environment variable consistency
```

Then add one row to the Domain Slots table (after line 86 `{{STATIC_VERIFICATION_SKILL}}` row):
```markdown
| `{{SECURITY_CHECK_CATEGORIES}}` | OWASP-style category vocabulary for ③ deep-mode (e.g., access control, injection, secrets management, sensitive-data exposure) — domain/framework-agnostic; project fills specifics |
```

- [ ] **Step 4: Run the gate to verify it passes**

Run the Step 1 block.
Expected: `PASS`.

- [ ] **Step 5: Commit**

```bash
git add plugins/orbit-base/agents/reviewer.md
git commit -m "feat(reviewer): add Triple Crown ③ security deep-mode (T3-gated entry, per-task only)"
```

---

## Task 3: Fix the explore roster gap in leader.md + add reviewer deep-mode dispatch signal

**Files:**
- Modify: `plugins/orbit-base/agents/leader.md:15` (Team Structure row) and the Agent Dispatch Pattern block (lines 116-124).

**Interfaces:**
- Consumes: the deep-mode entry condition (from Task 2) — the leader already computes the T3 judgment in the High-Risk Decision Gate, so it just forwards that boolean to the reviewer.

- [ ] **Step 1: Write the failing test**

```bash
# Gate C (partial — explore in leader.md): leader's roster row must list explore
L=plugins/orbit-base/agents/leader.md
grep -E "architect / builder / .*explore.* / reviewer|explore" "$L" | grep -q "Temporary Agent()" && echo PASS || echo FAIL
```

(Set-equality across all surfaces is Task 6; this is the local check.)

- [ ] **Step 2: Run it to verify it fails**

Run the Step 1 block.
Expected: `FAIL` (line 15 currently reads `architect / builder / critic / reviewer / researcher` — no explore).

- [ ] **Step 3: Make the minimal edit**

Change line 15 from:
```
| architect / builder / critic / reviewer / researcher | Temporary Agent() instances | Role-specific design, implementation, plan critique, verification |
```
to:
```
| architect / builder / explore / critic / reviewer / researcher | Temporary Agent() instances | Role-specific design, implementation, internal codebase search, plan critique, verification |
```

Add one line at the end of the Agent Dispatch Pattern section (after line 124, the closing of the dispatch list / before "All agent results return..."), inside or just after the code block add a comment line and a prose line:

In the dispatch code block (lines 118-124), add after the reviewer line:
```
Agent(reviewer, foreground)       # post Triple Crown coordination; leader forwards T3 verdict as a hint (③ deep-mode is decided by the reviewer's own diff inspection)
```
(i.e., extend the existing reviewer comment — do not add a new dispatch entry.)

And add this prose line after the code block (after line 126):
```markdown
When dispatching the reviewer, the leader **forwards the security-surface verdict it already computed for the high-risk gate (critic T3) as a corroborating hint** — not as an instruction. The reviewer decides ③ deep-mode from its **own inspection of the built diff**; the leader's forward only corroborates. If the leader forgets to forward it, the reviewer still enters deep-mode whenever its diff inspection shows the surface was touched — a missing hint never downgrades a security-touching change to a light scan. No new judgment is asked of the leader; it merely reuses the T3 boolean as a hint.
```

- [ ] **Step 4: Run the gate to verify it passes**

Run the Step 1 block.
Expected: `PASS`.

- [ ] **Step 5: Commit**

```bash
git add plugins/orbit-base/agents/leader.md
git commit -m "fix(leader): add explore to Team Structure roster; forward T3 verdict to reviewer ③ deep-mode"
```

---

## Task 4: Document ③ deep-mode in using-orbit SKILL.md

**Files:**
- Modify: `plugins/orbit-base/skills/using-orbit/SKILL.md` — Triple Crown Verification section (lines 68-83) and Quick Reference table (lines 123-137).

**Interfaces:**
- Consumes: canonical name `critic T3 security surface`, the entry condition, and per-task exclusivity from Tasks 1-2. References them; does not restate the category list.

- [ ] **Step 1: Write the failing test**

```bash
# Gate D: SKILL.md documents deep-mode by reference (anchor phrase, no re-hardcoded
#         surface string), makes the reviewer's diff judgment binding with the leader
#         forward as a hint (N2), keeps the read-only boundary (N3), states per-task
#         exclusivity, and adds a Quick Ref entry.
S=plugins/orbit-base/skills/using-orbit/SKILL.md
grep -qi "deep-mode" "$S" \
 && grep -q "critic T3 security surface" "$S" \
 && grep -qi "own inspection of the built diff" "$S" \
 && grep -qi "corroborating hint" "$S" \
 && grep -qi "per-task" "$S" \
 && grep -qi "read-only review" "$S" \
 && ! grep -q "auth, permissions, secrets, deletion" "$S" \
 && echo PASS || echo FAIL
```

- [ ] **Step 2: Run it to verify it fails**

Run the Step 1 block.
Expected: `FAIL`.

- [ ] **Step 3: Make the minimal edit**

After the Triple Crown table (after line 78, before the executor/verifier paragraph on line 80), insert:
```markdown

**③ security deep-mode.** Prong ③ has a conditional deep-mode. It enters deep-mode **if and only if the reviewer's own inspection of the built diff finds it touches the *critic T3 security surface*** (the canonical reference origin defined in `critic.md`), running an OWASP-style category sweep instead of a light scan. The reviewer's diff judgment is the binding trigger; the leader's plan-stage T3-forward is only a corroborating hint, so a forgotten forward never downgrades a security-touching change to a light scan. Because a T3-touching change is high-risk and is ejected from any autonomous batch, **deep-mode runs only in per-task mode** — it and the autonomous loop are mutually exclusive, never concurrent. Deep-mode is still a read-only review (findings go to the leader; fixes route to the builder) — it does not make the reviewer the remediation owner.
```

Add one row to the Quick Reference table (after the `Triple Crown` row, ~line 130):
```markdown
| ③ deep-mode | Triple Crown ③ Quality escalates from light scan to an OWASP-style sweep when the reviewer's diff inspection finds the change touches the critic T3 security surface (leader's T3-forward is only a hint); per-task mode only (never inside an autonomous batch); still read-only review |
```

- [ ] **Step 4: Run the gate to verify it passes**

Run the Step 1 block.
Expected: `PASS`.

- [ ] **Step 5: Commit**

```bash
git add plugins/orbit-base/skills/using-orbit/SKILL.md
git commit -m "docs(using-orbit): document Triple Crown ③ security deep-mode"
```

---

## Task 5: Fix the explore roster gap in codex-tools.md (last roster surface)

**Files:**
- Modify: `plugins/orbit-base/skills/using-orbit/references/codex-tools.md:32` (sequential role-switching list).

**Interfaces:**
- Consumes: nothing. Pure roster-string fix. The dispatch block (line 40) already lists explore; only the prose list at line 32 omits it.

- [ ] **Step 1: Write the failing test**

```bash
# Gate E (local): the role-switching prose lists explore alongside the other roles.
C=plugins/orbit-base/skills/using-orbit/references/codex-tools.md
sed -n '32p' "$C" | grep -q "explore" && echo PASS || echo FAIL
```

- [ ] **Step 2: Run it to verify it fails**

Run the Step 1 block.
Expected: `FAIL` (line 32 reads `(leader, architect, builder, reviewer)` — explore + critic + researcher omitted from that illustrative list; this plan adds explore to fix the documented gap).

- [ ] **Step 3: Make the minimal edit**

Change line 32's parenthetical from:
```
the single agent assumes each role (leader, architect, builder, reviewer) in sequence
```
to:
```
the single agent assumes each role (leader, architect, explore, builder, critic, reviewer, researcher) in sequence
```
(Full roster — matches the seven-role set; the dispatch block below it already enumerates explore/critic.)

- [ ] **Step 4: Run the gate to verify it passes**

Run the Step 1 block.
Expected: `PASS`.

- [ ] **Step 5: Commit**

```bash
git add plugins/orbit-base/skills/using-orbit/references/codex-tools.md
git commit -m "fix(codex-tools): add explore to sequential role-switching roster"
```

---

## Task 6: Cross-cutting verification gates (set-equality + canonical-source + entry-condition + purity + frontmatter)

**Files:**
- Test only: no product file changes. This task is the consolidated gate that must pass after Tasks 1-5.

**Interfaces:**
- Consumes: all prior tasks' outputs.

- [ ] **Step 1: Roster set-diff gate — REAL extraction, no hardcoded expected list (B2)**

The round-1 lesson was "set-equality, not phrase-presence." The earlier draft of this gate violated that lesson under a new label: it **hardcoded** each file's role tokens as the `check FILE token token...` arguments, so the comparison was `expected == expected` — it would pass even if leader.md still listed 5 roles. This revision **extracts the roster tokens from each file at runtime** and diffs the extraction against the canonical set. A human eyeball is never the gate.

**Normalization (load-bearing — the surfaces are NOT all the same set):** two surfaces (leader.md Team-Structure spoke row, SKILL.md hub-and-spoke list, gemini-tools dispatch table) list **spokes only** and deliberately omit `leader` (the hub is a separate row/line). Two surfaces (CLAUDE.md L9, codex-tools L32 after fix) list the **full** roster including `leader`. So the gate normalizes by **dropping `leader` from every extraction and comparing the spoke set** (the canonical 6 spokes); it then separately asserts that the two full-roster surfaces additionally contain `leader`. This is honest about the asymmetry instead of forcing a false uniform 7-set.

```bash
cd plugins/orbit-base
SPOKES=$(printf '%s\n' architect builder critic explore researcher reviewer | sort -u)  # canonical 6 spokes
fail=0

# extract(): given a single line of role tokens, split on / , and parens, keep known role words,
# drop 'leader', sort -u. Pure runtime extraction — nothing about the answer is hardcoded.
norm() {  # stdin = raw roster text → normalized spoke set on stdout
  tr 'A-Z' 'a-z' \
   | grep -oE 'architect|builder|critic|explore|reviewer|researcher|leader' \
   | grep -v '^leader$' \
   | sort -u
}
diffcheck() {  # $1=label  stdin=raw roster text
  local label="$1"; local got; got=$(norm)
  if [ "$got" = "$SPOKES" ]; then echo "OK   $label"; else echo "BAD  $label"; diff <(echo "$SPOKES") <(echo "$got"); fail=1; fi
}

# CLAUDE.md L9 full roster line (the "Team roles:" line)
grep -m1 "Team roles:" CLAUDE.md | diffcheck "CLAUDE.md:Team roles"
# leader.md Team-Structure spoke row (the Agent() instances row)
grep -m1 "Temporary Agent() instances" agents/leader.md | diffcheck "leader.md:Team Structure spoke row"
# SKILL.md hub-and-spoke spoke list (the 'All agents (...) are spokes' line)
grep -m1 "are spokes" skills/using-orbit/SKILL.md | diffcheck "SKILL.md:hub-and-spoke list"
# codex-tools L32 sequential role-switching parenthetical
grep -m1 "the single agent assumes each role" skills/using-orbit/references/codex-tools.md | diffcheck "codex-tools.md:role-switch list"
# gemini-tools dispatch table: concatenate all Agent(<role>, ...) rows into one stream
grep -E "Agent\((architect|builder|critic|explore|reviewer|researcher|leader)," skills/using-orbit/references/gemini-tools.md | diffcheck "gemini-tools.md:dispatch table"

# Full-roster surfaces must additionally carry 'leader' (CLAUDE.md, codex-tools)
grep -m1 "Team roles:" CLAUDE.md | grep -qi "leader" || { echo "BAD CLAUDE.md missing leader"; fail=1; }
grep -m1 "the single agent assumes each role" skills/using-orbit/references/codex-tools.md | grep -qi "leader" || { echo "BAD codex-tools missing leader"; fail=1; }

[ $fail -eq 0 ] && echo "ROSTER SET-DIFF: PASS" || echo "ROSTER SET-DIFF: FAIL"
```

Expected: `ROSTER SET-DIFF: PASS`. Every line is grepped from the file and tokenized at runtime; nothing about the expected answer is embedded in the per-file calls. If leader.md still omitted `explore`, `norm` would yield a 5-spoke set and `diff` would print the missing `explore` and set FAIL — exactly the failure the hardcoded draft could not catch. (Note for the executor implementing Task 3/5: the edits must make leader.md's spoke row and codex-tools L32 actually contain `explore`, or this gate fails for real.)

- [ ] **Step 2: Run it**

Run the Step 1 block.
Expected: `PASS`. If `BAD` for any file, the diff shows the missing/extra role.

- [ ] **Step 3: Canonical reference-origin gate (anchor-phrase identity + no-new-copy) — B1 honest form**

No HTML-comment marker is involved (it was removed as misleading). The gate asserts two honest properties: the **anchor phrase** is present at the origin and every referrer (so a future rename is grep-detectable), and **no new literal copy** of the surface string was introduced by this plan.

```bash
cd plugins/orbit-base
# (a) Anchor-phrase identity: the phrase "critic T3 security surface" is present
#     verbatim at the origin (critic.md) AND at both referrers (reviewer.md, SKILL.md).
#     If a future edit renames the surface vocabulary, this triple-presence breaks
#     and the gate catches the drift — real referential identity, unlike the old marker.
grep -q "critic T3 security surface" agents/critic.md \
 && grep -q "critic T3 security surface" agents/reviewer.md \
 && grep -q "critic T3 security surface" skills/using-orbit/SKILL.md \
 && grep -q "canonical reference origin" agents/critic.md \
 && ! grep -qi "single source of truth" agents/critic.md \
 && echo "ANCHOR-IDENTITY: PASS" || echo "ANCHOR-IDENTITY: FAIL"

# (b) No-new-copy: the comma-form category STRING is pre-existing in exactly 2 files
#     (critic.md T3, leader.md T3). CLAUDE.md uses the slash-form variant in its
#     autonomous gate (a separate legacy copy, not this grep's form). This plan must
#     NOT make reviewer.md or SKILL.md appear in the comma-form list — they reference
#     the surface by the anchor phrase instead of restating the list.
copies=$(grep -rl "auth, permissions, secrets, deletion" . | sort)
echo "comma-form literal-copy files:"; echo "$copies"
echo "$copies" | grep -qE "reviewer.md|using-orbit/SKILL.md" \
  && echo "NO-NEW-COPY: FAIL (deep-mode docs re-hardcoded the surface)" \
  || echo "NO-NEW-COPY: PASS"
# And the comma-form count is still exactly the 2 pre-existing trigger rows (not grown).
test "$(echo "$copies" | grep -c .)" -eq 2 && echo "COPY-COUNT: PASS (2 pre-existing)" || echo "COPY-COUNT: review — count changed"
```

Expected: `ANCHOR-IDENTITY: PASS`, `NO-NEW-COPY: PASS`, `COPY-COUNT: PASS`.

- [ ] **Step 4: ③ deep-mode entry-condition consistency gate**

The brief requires the gate detect *entry-condition consistency*, not mere phrase presence. ③ deep-mode and critic T3 must reference the same surface, and reviewer must phrase entry as a condition (reference to critic T3), not a depth adjective alone.

```bash
cd plugins/orbit-base
# Both the trigger (critic) and the verifier (reviewer) anchor to the same phrase,
# reviewer phrases entry as a boolean condition bound to its OWN diff inspection (N2),
# and the leader-forward is explicitly demoted to a corroborating hint.
grep -q "critic T3 security surface" agents/critic.md \
 && grep -q "critic T3 security surface" agents/reviewer.md \
 && grep -q "critic T3 security surface" skills/using-orbit/SKILL.md \
 && grep -qi "if and only if" agents/reviewer.md \
 && grep -qi "own inspection of the built diff" agents/reviewer.md \
 && grep -qi "corroborating hint" agents/reviewer.md \
 && echo "ENTRY-CONDITION: PASS" || echo "ENTRY-CONDITION: FAIL"
```

Expected: `ENTRY-CONDITION: PASS`. "if and only if" enforces boolean-condition phrasing over a vague "deeper when sensitive"; "own inspection of the built diff" + "corroborating hint" enforce that the reviewer's diff judgment binds and the leader-forward does not (N2).

- [ ] **Step 5: Domain purity + frontmatter integrity gate**

```bash
cd plugins/orbit-base
# Domain purity
grep -riE 'oremi|orbit-dev' . && echo "PURITY: FAIL" || echo "PURITY: PASS"
# No new hardcoded language/framework in the new slot's prose (slot stays a slot)
grep -q "{{SECURITY_CHECK_CATEGORIES}}" agents/reviewer.md && echo "SLOT: PASS" || echo "SLOT: FAIL"
# Frontmatter integrity: reviewer/critic/leader keep name+description+model; reviewer model unchanged
for a in reviewer critic leader; do
  head -5 "agents/$a.md" | grep -qE '^name:' && head -5 "agents/$a.md" | grep -qE '^description:' || echo "FRONTMATTER $a: FAIL"
done
grep -q '^model: opus' agents/reviewer.md && echo "REVIEWER-TIER: PASS (opus unchanged)" || echo "REVIEWER-TIER: FAIL"
echo "frontmatter checks done"
# Roster count unchanged: still 7
grep -q "(7 roles)" CLAUDE.md && echo "ROLE-COUNT: PASS (7 unchanged)" || echo "ROLE-COUNT: FAIL"
```

Expected: `PURITY: PASS`, `SLOT: PASS`, no `FRONTMATTER ... FAIL`, `REVIEWER-TIER: PASS`, `ROLE-COUNT: PASS`.

- [ ] **Step 6: Commit the gate record (no product change — empty/allow or skip)**

This task changes no product files; if all gates pass there is nothing to commit. Record the gate results in the verification report to the leader instead. (If a gate failed, return to the owning task — do not commit.)

```bash
echo "All cross-cutting gates passed — report to leader. No file change in this task."
```

---

## Self-Review

**1. Spec coverage:**
- Deep-mode added to ③ → Task 2. ✓
- Per-task mutual exclusivity stated → Task 2 (reviewer.md) + Task 4 (SKILL.md). ✓
- Designated reference origin + no-new-copy + anchor-identity (B1, NOT single-source) → Task 1 (visible anchor phrase, no marker) + Task 6 Step 3 (ANCHOR-IDENTITY + NO-NEW-COPY + COPY-COUNT). ✓
- Entry condition measurable & bound to reviewer's own diff (T3 boolean, not depth list; N2) → Task 2 phrasing ("if and only if" + "own inspection of the built diff") + Task 6 Step 4 gate. ✓
- Critic T3 ↔ ③ soft-link with leader-forward demoted to corroborating hint (N2) → Task 1 (scoped critic note) + Task 2 (reviewer binding) + Task 3 (leader hint). ✓
- Soft-link scoped to per-task / T3-fired path, not the autonomous all-no carve-out (N1) → Task 1 note explicit scope. ✓
- ③ deep-mode stays read-only review, reviewer not remediation owner (N3) → Task 2 + Task 4 ("read-only review" / "does not make the reviewer the remediation owner"). ✓
- explore roster fix → Task 3 (leader.md) + Task 5 (codex-tools.md). ✓
- REAL roster set-diff gate (runtime extraction, not hardcoded expected; B2) → Task 6 Step 1, dry-run-verified against current files. ✓
- No new agent, roster stays 7 → Global Constraints + Task 6 Step 5 ROLE-COUNT gate. ✓
- Domain-agnostic slot → Task 2 `{{SECURITY_CHECK_CATEGORIES}}` + Task 6 SLOT/PURITY gates. ✓
- Reviewer tier unchanged → Task 6 REVIEWER-TIER gate. ✓

**2. Placeholder scan:** No TBD/TODO. Every edit shows exact before/after text and exact gate commands. ✓

**3. Consistency:** The anchor phrase `critic T3 security surface` is used identically in Tasks 1, 2, 4 and asserted present at origin+both referrers by Task 6 Step 3. No HTML-comment marker anywhere (removed per B1). The Task 6 Step 1 set-diff extracts tokens at runtime and embeds no per-file answer (B2); normalization drops `leader` to handle the hub/spoke asymmetry across surfaces and separately asserts the two full-roster surfaces carry `leader`. ✓

**Note for executor:** Task 6 Step 1 is a genuine extraction gate — it greps each roster line from the file and tokenizes it live, so it fails for real if Tasks 3/5 do not actually add `explore`. Do not substitute a hardcoded list; that was the round-2 B2 defect. The `norm()`/`diffcheck()` mechanics were dry-run-verified by the architect against the current files (pre-fix leader.md and codex-tools correctly FAIL; CLAUDE.md/SKILL.md/gemini PASS).
