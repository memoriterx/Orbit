# Plan — Required Dependency Wiring (superpowers · GSD · gstack as hard requirements)

- **Date:** 2026-06-24
- **Author:** architect
- **Status:** Draft (pending Plan Approval)
- **SemVer:** **MAJOR** candidate — v2.0.0 (BREAKING: removes self-containment / graceful-degradation guarantee of v1.0.0)
- **User decision (fixed, not up for re-litigation):** superpowers, GSD, and gstack become **required** companion plugins. Remove orbit's independent graceful degradation / silent pass-through. Explicitly wire each role to the skills it uses so the process runs end-to-end without gaps. This intentionally reverses the v1.0.0 "self-contained / domain-agnostic" rationale; the user knows and chose this.

---

## Discovery (facts established before planning)

### Unknown #1 (★ design-deciding) — Does Claude Code support declaring/enforcing required plugin dependencies?

**Answer: Yes, the mechanism exists — but it does NOT fit orbit's case, so "required" must be implemented as runtime fail-loud guards, not as the manifest `dependencies` field. One path, converged.**

Confirmed from official docs (`code.claude.com/docs/en/plugins-reference` and `/plugin-dependencies`):

- `plugin.json` has a `dependencies` array. Entries are a bare plugin name or `{ "name", "version", "marketplace" }`.
- Enforcement is real: on install Claude Code auto-installs/transitively enables declared dependencies; a missing/disabled dependency surfaces `dependency-unsatisfied` and **disables the dependent plugin** until resolved. `claude plugin enable` fails listing the missing install commands.
- **The blocking constraint:** `name` **resolves within the declaring plugin's own marketplace** by default. Cross-marketplace resolution is *refused* unless the **root marketplace** (the one hosting the plugin the user installs — i.e. the user's, not orbit's to control) lists the target in `allowCrossMarketplaceDependenciesOn`. Version constraints additionally require git tags of the form `{plugin}--v{version}` on the dependency's marketplace repo.
- superpowers / GSD / gstack live in **separate, third-party marketplaces** that orbit's `orbit-marketplace` does not host and cannot tag. So a `dependencies` entry for them would fail with `cross-marketplace` (or `no-matching-tag`) on most user setups, and orbit cannot fix that from its side — the allowlist lives in the consuming user's root marketplace config.

**Conclusion:** The declarative `dependencies` field is **not a reliable enforcement path for orbit's three external companions.** Therefore *required-ness is implemented exclusively via runtime fail-loud guards* (detect tool absence → clear error + install guidance + block), at both the **hook layer** (SubagentStop) and the **agent-prompt layer** (reviewer ①②③). We will NOT add an unresolvable `dependencies` array (it would self-disable orbit on clean installs — worse UX than a guard). This is the single converged path.

*(If a future release ships orbit + the three companions in one unified marketplace with tagged releases, the `dependencies` field becomes viable; out of scope here. Noted as a memory follow-up, not built.)*

### Unknown #2 — Actual invocation interfaces per tool

- **superpowers** exposes **skills** (not slash commands), invoked by name: `superpowers:writing-plans`, `superpowers:test-driven-development`, `superpowers:systematic-debugging`, `superpowers:verification-before-completion`, `superpowers:requesting-code-review`, `superpowers:brainstorming`, `superpowers:receiving-code-review`. Presence ⇒ the relevant skill appears in the agent's available-skills list.
- **GSD** exposes **slash commands** with `/gsd-` prefix (`/gsd-help` enumerates; relevant: `/gsd-verify-work`, `/gsd-code-review`, `/gsd-progress`). Completeness prong ① uses GSD's verify/progress workflow.
- **gstack** is a **framework name**, not a command; it exposes commands/skills incl. `/qa`, `/qa-only`, `/review`, and `browse`. Behavior prong ② uses `/qa` (or `/qa-only` for report-only). Quality prong ③ may alternately use gstack `/review`.

### Unknown #3 — 7-role ↔ skill mapping (first-class wiring) — COMPLETE, inventory-grounded

**User scope expansion (2026-06-24, fixed):** all **7 roles** should *actively* use companion-plugin skills where one fits the role. No invented skill names — mapping is grounded in the real on-disk inventory below. Where no skill fits a role, it is honestly "N/A (with reason)" — no forced wiring (YAGNI).

**Inventory verified on disk / from command surface:**
- **superpowers** (15 skills, `~/.claude/plugins/cache/claude-plugins-official/superpowers/6.0.2/skills/`): `brainstorming`, `dispatching-parallel-agents`, `executing-plans`, `finishing-a-development-branch`, `receiving-code-review`, `requesting-code-review`, `subagent-driven-development`, `systematic-debugging`, `test-driven-development`, `using-git-worktrees`, `using-superpowers`, `verification-before-completion`, `writing-plans`, `writing-skills`.
- **GSD** (`/gsd-*` commands; `/gsd-help` enumerates): relevant incl. `/gsd-verify-work`, `/gsd-progress`, `/gsd-code-review`, `/gsd-debug`, `/gsd-map-codebase`, `/gsd-explore`, `/gsd-plan-phase`, `/gsd-secure-phase`, `/gsd-extract-learnings`.
- **gstack** (commands/skills): `/qa`, `/qa-only`, `/review`, `browse`, `investigate`, `scrape`, `cso` (Chief Security Officer), `careful`/`guard` (safety guardrails).

**Enforcement levels:** **[A] = always** (the role's core methodology routes through it every dispatch); **[C] = conditional** (invoked only when the trigger holds — keeps simple tasks overhead-free, consistent with the lifecycle's "단순 작업은 생명주기 불필요" principle); **N/A** = no fitting skill, with reason.

| Role | superpowers | GSD | gstack | When / level |
|------|-------------|-----|--------|--------------|
| **leader** | `using-superpowers` [A — session start, skill discovery]; `dispatching-parallel-agents` [C — fan-out 2+ independent read-only spokes] | N/A — GSD commands are work-execution surfaces, delegated to reviewer/builder | N/A — gstack is QA/build surface, delegated downstream | leader uses only *meta* skills (discovery + fan-out routing), no work skill — preserves hub-and-spoke orchestration-only role. |
| **architect** | `brainstorming` [A — discovery]; `writing-plans` [A — plan authoring] | `/gsd-explore` [C — Socratic ideation in discovery, if installed]; `/gsd-plan-phase` [C — when a roadmap phase wants GSD's structured phase plan] | N/A — no design skill in gstack | discovery + planning core methodology. |
| **builder** | `test-driven-development` [A]; `verification-before-completion` [A — before claiming done]; `systematic-debugging` [C — any bug/test failure]; `executing-plans` [C — running a written multi-step plan]; `using-git-worktrees` [C — isolation needed]; `finishing-a-development-branch` [C — integration time] | `/gsd-debug` [C — multi-cycle structured debug for hard bugs] | N/A — gstack QA is reviewer's prong ② | TDD + verification always; rest condition on situation. Simple/meta tasks stay outside the lifecycle → no skill forced. |
| **explore** | N/A — superpowers has no read-only codebase-search skill; explore's glob/grep/read fan-out is its native method | `/gsd-map-codebase` [C — when a *structured* codebase-map doc is wanted, not a one-off search]; `/gsd-explore` [C — Socratic routing if leader wants idea exploration vs raw search] | N/A | explore's core needs no skill; GSD map is a conditional upgrade for the "produce a codebase doc" case only. Honest N/A on superpowers. |
| **critic** | `receiving-code-review` [A — canonical "evaluate claims with technical rigor, no performative agreement" skill — directly models critic's red-team posture] | `/gsd-secure-phase` [C — high-risk plan touches T3 security surface, grounds threat-model critique] | `cso` (Chief Security Officer mode) [C — same T3 trigger, alternate security-critique lens] | rigor skill always; security skills condition on T3. No plan-*writing* skill (critic never authors). |
| **reviewer** | ③ `requesting-code-review` [A — quality prong]; `receiving-code-review` [C — synthesizing builder's response to prior findings] | ① `/gsd-verify-work` [A — completeness prong] + `/gsd-progress` [C]; `/gsd-code-review` [C — alt ③ lens]; `/gsd-secure-phase` [C — ③ deep-mode on T3] | ② `/qa` [A — behavior prong] (`/qa-only` [C — report-only]); `/review` [C — alt ③ lens]; `cso` [C — ③ deep-mode] | only role spanning all three plugins, one+ per prong. Each prong [A] tool is **required → fail-loud on absence** (D1/D3). |
| **researcher** | N/A — superpowers has no external-research skill (all are dev-process); researcher's WebSearch/WebFetch + doc reading is native | N/A — GSD's researcher subagents are GSD-internal orchestration agents, not user-invocable research skills | `scrape` [C — structured data extraction from a web page]; `browse` [C — live page navigation, not just fetch] | honest N/A on superpowers + GSD; gstack browser tools are the only genuine fit, conditional only. |

**Wiring contract notes:**
- The reviewer is the only role with **[A] required prong** companion tools. For every *other* role, companion skills are either superpowers meta-skills [A but low-cost] or **[C] conditional** — so the "active use" mandate does NOT force a skill onto trivial/meta work, preserving "단순 작업은 생명주기 불필요".
- **Enforceability tiers (load-bearing — corrected per critic BLOCKER #2):** there are exactly **two** honest categories, distinguished by *whether orbit can mechanically enforce them*:
  - **TIER-1 ENFORCED (the only true requirement):** the **reviewer ①②③ prongs**, gated by the **SubagentStop hook** (machine check) AND the reviewer's own report contract (`FAIL` if a prong tool is absent). This is the *only* surface where "required" is mechanically true — a hook can verify presence and a reviewer's verdict is a checkable artifact.
  - **TIER-2 PROSE GUIDANCE (not enforced, honestly labeled):** the per-role "[A]/[C]" wiring in the other 11 prompt instances (architect/builder/leader/explore/critic/researcher, both surfaces). These are **instructions to the agent**, not enforced invocations. Nothing in orbit can verify that builder *actually* called `test-driven-development` — the prompt only *tells* it to. Calling architect/builder core `[A]` "fail-loud" was a misstatement: a prompt cannot fail loud on its own non-compliance. **We relabel these as strong prose directives, not gates.** `[A]` now means "the prompt directs always-use"; `[C]` means "the prompt directs conditional-use". Neither is a runtime gate.
  - **Consequence for BREAKING surface:** only TIER-1 is a genuine behavioral break (a clean install with no companions now *blocks* at the reviewer prong / hook). TIER-2 is prompt-text guidance that degrades gracefully (agent falls back to native method; no block). The CHANGELOG and success criteria must reflect this split (see MAJOR #3 phased rollout).

### Three-layer model (revised — adds the front consideration layer per user 2026-06-24)

The user added a **pre-role skill-consideration injection** layer. It is a *consideration-prompting* mechanism, NOT enforcement, and NOT a skip-removal: it reliably **delivers** "here are your available skills; consider whether this task needs them, use them if so, and **skip if genuinely unnecessary** (simple/meta work)". It is isomorphic to superpowers `using-superpowers`' "if even 1% applicable, review; else skip" pattern. There are now exactly **three** layers, front → back:

| Layer | What it does | Mechanism | Enforced? | Skip allowed? | Version |
|-------|--------------|-----------|-----------|---------------|---------|
| **L1 — Consideration delivery (NEW)** | At subagent spawn, injects the role's available-skill list + a "consider-then-use-or-skip" directive into context | **SubagentStart hook** → `hookSpecificOutput.additionalContext` (confirmed real, see D9) | **No** — guarantees *delivery* of the prompt to consider; cannot and does not verify the agent actually considered or invoked | **Yes, explicitly** — "skip if not needed" is the whole point | v2.1.0 (non-breaking) |
| **L2 — Prose wiring (TIER-2)** | Static per-role "[A]/[C]" guidance baked into each agent prompt | Prompt text | **No** — guidance | n/a (it *is* the guidance L1 surfaces dynamically) | v2.1.0 (non-breaking) |
| **L3 — Verification enforcement (TIER-1)** | The three Triple Crown prongs must produce companion-tool output | Scoped SubagentStop hook + reviewer report contract | **Yes** — the only enforced surface | No (a prong tool is required) | v2.0.0 (BREAKING) |

**Layer relationships, overlap, boundaries:**
- **L1 and L2 are the same content, different delivery.** L2 is the static prompt text; L1 dynamically re-surfaces the *currently-available* subset at spawn time (companion-aware — see D9). L1 exists because a static prompt buried in a long agent file is less reliably acted on than a fresh system-reminder at spawn. They are complementary, not redundant: L2 is the durable source of truth; L1 is the just-in-time nudge. Neither enforces.
- **L1/L2 (consideration + guidance) vs L3 (enforcement) are categorically different and must never be conflated** — this is the BLOCKER #2 trap restated. L1 only guarantees the *consideration prompt is delivered*; whether the agent acts is its judgment. L3 is the only place "required" is mechanically true, and only for the three prongs.
- **Boundary rule:** L1 may *suggest* the reviewer's prong skills too, but it does **not** become the L3 gate — the reviewer prong enforcement stays in SubagentStop+report-contract regardless of what L1 injected. L1 never blocks (SubagentStart cannot block — confirmed D9), so it can never accidentally brick orbit. This is structurally safer than L3's hook.

### Current-state facts (from explore + this discovery)

- Behavior gap: **no fail-loud anywhere.** `quality-gate.sh` silently `exit 0` when `.orbit/quality-gate.sh` absent. reviewer.md ② says "unverified — tool not available" (graded, but doesn't forbid PASS); ①③ have no absence branch at all (silent downgrade).
- Layer contradiction: agent-prompt layer (② explicit downgrade) vs hook layer (silent exit 0) disagree.
- Both surfaces (deploy `plugins/orbit/agents/reviewer.md` + dev `.claude/agents/reviewer.md`) exist; dev reviewer is orbit-domain-filled and **lacks the security deep-mode section** the deploy reviewer has (pre-existing drift — in scope to decide).
- Slots in play: `{{BEHAVIOR_VERIFICATION_METHOD}}`, `{{QUALITY_REVIEW_SKILL}}`, `{{STATIC_VERIFICATION_SKILL}}` (reviewer.md). orbit-cycle.md has a "graceful when companion absent" table (lines ~206-214) and an absence column to remove/invert.

---

## Goal

Make the **Triple Crown verification prongs (①GSD ②gstack ③superpowers) mechanically required** at the only two enforceable surfaces — the SubagentStop hook and the reviewer's report contract: when a prong's tool is absent, that **prong (and only that prong) fails loud** (clear error + which plugin + how to install) instead of silently passing or downgrading. Separately, **wire all 7 roles** to the companion skills they should use via **prose directives** ([A] always / [C] conditional) — honest guidance, not a runtime gate — so each role actively leverages the plugins where one fits, while simple/meta tasks stay overhead-free. Resolve the agent-layer ↔ hook-layer contradiction within the enforced prong surface.

**Two-tier honesty (per critic BLOCKER #2):** TIER-1 = the three prongs (enforced, this is the real BREAKING change); TIER-2 = the 11 other role wirings (prose guidance, non-breaking). The plan, CHANGELOG, and success criteria keep these strictly separate.

## Non-Goals

- Adding a `dependencies` array for the three companions (Unknown #1: unreliable cross-marketplace; would self-disable orbit). Explicitly excluded.
- Building a unified single-marketplace bundle (future, out of scope).
- Changing the hub-and-spoke / Plan Approval / autonomous-mode semantics.
- Re-litigating the self-containment reversal (user-decided) — but the reversal **must be stated honestly** in manifest/README (see MAJOR #4), not hidden behind a narrow domain-purity grep.
- Claiming TIER-2 prose wiring is "enforced". It is not — orbit cannot verify an agent's actual skill invocations. (BLOCKER #2.)

## Rollout strategy (per critic MAJOR #3 — phased rollout evaluated)

**Decision: ADOPT phased rollout.** The two tiers map cleanly onto two releases, which also contains supply-chain risk (MAJOR #3):

- **v2.0.0 (MAJOR / BREAKING) — TIER-1 only:** the three Triple Crown prongs become mechanically required (hook + reviewer contract fail-loud, scoped per BLOCKER #1). This is the genuine backward-compat break: clean installs without companions now block at verification. Minimal, auditable, execution-tested surface.
- **v2.1.0 (MINOR / non-breaking) — TIER-2:** the 11 per-role prose wirings ([A]/[C] directives across architect/builder/leader/explore/critic/researcher). These add no gate and break nothing — a missing skill degrades to native method — so they are correctly a minor feature, not part of the BREAKING bump.

**Rationale:** (a) honestly separates "what actually breaks" (TIER-1) from "added guidance" (TIER-2), per BLOCKER #2; (b) limits the v2.0.0 supply-chain hostage surface to three prongs — if a companion renames/deprecates a command, only the narrow enforced prong breaks, and the fix is a single contract update, not 14 prompt rewrites; (c) lets the larger 14-file prose edit ship without a second BREAKING bump. **Builder may implement both tiers in one work cycle if the leader prefers**, but they version and CHANGELOG **separately** (2.0.0 entry = TIER-1 only; 2.1.0 entry = TIER-2). *Rejected alternative:* one big v2.0.0 covering all 14 files as "required" — rejected because it mislabels unenforceable prose as a breaking requirement and maximizes the supply-chain surface for no enforcement gain.

**Interface version pinning (MINOR #7):** the enforced prong commands (`/gsd-verify-work`, `/qa`, `superpowers:requesting-code-review`) are not version-pinned and could rename across companion releases. Since the `dependencies` semver path is unusable (ADR-REQDEPS-1), pinning is not mechanically available; instead the hook/reviewer error messages must name the *expected command* so a rename surfaces as a clear "command not found / changed" failure rather than a silent pass. Builder notes this as a known fragility (documented, not solved).

---

## Design

### D1 — Slot policy: pin to required tools, drop "if present" hedging

The three prong tools stop being optional/slotted defaults and become **named required tools** in prose. Slots are handled as:

- `{{QUALITY_REVIEW_SKILL}}` → keep the slot token (domain-agnostic projects may still substitute), but **change its default and contract**: default = `superpowers:requesting-code-review`, and the prompt states this tool is **required** — absence is a blocking error, not a manual-review fallback. Remove "(manual diff review if absent)" style hedging.
- `{{BEHAVIOR_VERIFICATION_METHOD}}` → same treatment, default = gstack `/qa`; absence blocks ②. Remove "note as unverified — tool not available" soft path; replace with **fail-loud block** (a tool-absent ② is FAIL, never PASS).
- Prong ① (GSD `/gsd-verify-work`) → currently prose-only; add explicit required-tool wording with fail-loud on absence.
- `{{STATIC_VERIFICATION_SKILL}}` and `{{SECURITY_CHECK_CATEGORIES}}` → unchanged (not part of the three required companions).

**Domain-purity — honest accounting (per critic MAJOR #4):** keeping slot *tokens* does NOT preserve domain-agnosticism here. The shipped *defaults* are now hardcoded vendor tool names (`superpowers:requesting-code-review`, gstack `/qa`, GSD `/gsd-verify-work`), and the prong contract requires them. The existing domain-purity grep only matches `oremi|Oremi|orbit-dev`, so it stays "clean" — **but that is a coincidence of the grep's narrow pattern, not evidence of principle compliance.** We will NOT use the clean grep to claim domain-agnosticism. Instead:
- **D1a (MAJOR #4 resolution):** the deliberate vendor-lock is stated honestly in the manifest `description` and README (see D7) — orbit's Triple Crown now *requires* superpowers/GSD/gstack; the "applies to any stack" copy is corrected. This is a conscious, documented reversal, not a hidden one.
- The slot tokens remain only as a *theoretical* repoint seam for a future non-Claude-Code fork; the shipped product is Claude-Code-companion-locked and says so.
- No *project* name (oremi/orbit-dev) is hardcoded — that narrower purity (no dogfood-project leakage into the deployable) still holds and is still grep-checked, but it is reported as exactly that, not as "domain-agnostic".

### D2 — Hook layer: SubagentStop guard, SCOPED to verification work (per critic BLOCKER #1)

**The flaw being fixed:** SubagentStop fires on *every* subagent completion (builder, explore, researcher, architect, doc/meta work — anything). A blanket "missing companion ⇒ block" turns the hook into a **suicide gate**: a clean install, a CI/headless run, a permissions hiccup, or a transient `claude plugin list` failure would block *all* orbit work, including companion-irrelevant tasks, indefinitely. The dev team's own build (where `claude` is not guaranteed on the subagent bash PATH) could self-brick on first run.

**Fix — block only when the completing work is a verification prong, and only for the tool that prong needs:**

Rewrite `plugins/orbit/hooks/quality-gate.sh` (reflect semantics in `templates/quality-gate.template.sh`):

1. **Relevance gate first (default-pass for irrelevant work).** The hook reads its SubagentStop stdin payload and determines whether the completing subagent was a **reviewer running a Triple Crown prong** (the only context where a companion is actually required). Determination signal options (builder to pick the robust one from the actual payload schema; explore/test during build):
   - the subagent type / name (`reviewer`) from the hook input, AND/OR
   - a sentinel the reviewer writes to `.orbit/` when it begins a prong (e.g. `.orbit/.prong-active`), AND/OR
   - presence of a verification marker in the transcript.
   If the completing work is **not** a verification prong → the hook **passes (exit 0)** regardless of companion presence. Builder/doc/explore/meta work is never blocked by companion absence. This is the core BLOCKER #1 fix.
2. **Companion check only on prong-relevant completion.** When step 1 says "this was a verification prong", check presence of *only the companion that prong uses* (① needs GSD, ② needs gstack, ③ needs superpowers — not all three at once). Missing → `{"decision":"block","reason":"..."}` naming that one plugin + its install command.
3. **`claude` CLI unavailable handling (no longer blanket fail-closed):** if presence cannot be determined because `claude` itself is absent:
   - In **prong-relevant** context → emit a **non-blocking warning** to stderr ("cannot verify <companion>; install or set ORBIT_SKIP_COMPANION_CHECK if intentional") and **defer the hard block to the reviewer's own report contract** (TIER-1's second enforcement point), which runs inside the agent where the skill/command either resolves or visibly does not. The reviewer cannot mark a prong PASS without the tool actually producing output, so enforcement is preserved without the hook bricking on a CLI-detection failure.
   - In **irrelevant** context → pass (exit 0).
4. **Explicit escape hatch:** honor `ORBIT_SKIP_COMPANION_CHECK=1` (env) and/or a `.orbit/config` flag for CI/headless/offline runs — documented, opt-in, prints that the prong check was skipped. This prevents the gate from being un-bypassable in legitimate automation.
5. The existing project `.orbit/quality-gate.sh` delegation (typecheck/lint/test) is preserved and runs **independently** of the companion check — it is NOT gated behind companion presence (it must still run on builder completions, which are companion-irrelevant for the prong check).

**Self-check that the scope reduction introduces no new failure mode (BLOCKER #1 ★ requirement):**
- *New false-negative risk:* if the relevance detector misclassifies a real prong as "irrelevant", the hook passes and enforcement falls solely to the reviewer report contract. **Mitigation:** the reviewer contract (D3) is an independent second gate — a prong is never PASS without tool output — so a hook false-negative degrades to "reviewer still catches it", not "silent pass". Two independent gates, not one.
- *New false-positive risk:* misclassifying builder work as a prong would block builder. **Mitigation:** default-pass bias — the detector must be *positively* sure it's a reviewer prong to engage; ambiguity ⇒ pass (opposite of the old fail-closed). This is the deliberate inversion the critic asked for.
- *Escape-hatch abuse:* `ORBIT_SKIP_COMPANION_CHECK` could be left on permanently, silently disabling TIER-1. **Mitigation:** the reviewer report contract is unaffected by the env var (it's an in-agent gate), so the escape hatch only relaxes the *hook*, not the reviewer's FAIL-on-absent-tool. Belt stays even if suspenders are off.

**Hook location:** keep the check inside `quality-gate.sh` (existing SubagentStop entry, hooks.json:45-58) — no new hooks.json entry, no second drift surface. hooks.json needs no change. Confirm during build.

### D3 — Reviewer prompt (both surfaces): unconditional fail-loud across ①②③

Edit `plugins/orbit/agents/reviewer.md` AND `.claude/agents/reviewer.md` (parity):

**This reviewer report contract is the second (and primary) TIER-1 enforcement point** — independent of the hook. Because the reviewer cannot mark a prong PASS without the tool actually producing verifiable output, this gate holds even when the D2 hook passes (relevance false-negative) or is bypassed (`ORBIT_SKIP_COMPANION_CHECK`). Two independent gates.

- ① Completeness: add "uses GSD `/gsd-verify-work` (expected command — required); if GSD absent / command not found → report ① FAIL with install guidance, do not silently checkbox-compare." Name the *expected command* so a companion rename surfaces as a clear failure (MINOR #7).
- ② Behavior: replace the "unverified — tool not available ⇒ manual checklist" Error-Handling path with "gstack `/qa` (expected command) required; absent ⇒ ② FAIL + install guidance. A tool-absent ② is never PASS."
- ③ Quality: state `superpowers:requesting-code-review` (expected skill) is required; absent ⇒ ③ FAIL + guidance.
- Update the report format note so any prong may legitimately be `FAIL — required tool <X> not installed/available: <install cmd>`.
- **Dev-reviewer security deep-mode drift:** *out of scope to add here* unless trivial — flag to leader as a separate parity item. (Rationale: prior memory DRIFT decisions favor not bloating dev parity beyond core; adding deep-mode to dev reviewer is a distinct concern from required-deps wiring. Recommend a separate roadmap item.) Builder must NOT silently import it.

### D4 — Role prompts: TIER-2 prose skill wiring (ALL 7 roles) — ships v2.1.0, NON-BREAKING

**Honesty correction (BLOCKER #2):** these are **prose directives to agents, not enforced gates.** Each agent prompt gains a **"Companion skill wiring (guidance)"** subsection per the Unknown #3 table. `[A]` = "prompt directs always-use"; `[C]` = "prompt directs conditional-use". **No `[A]` here is "fail-loud"** — a prompt cannot enforce its own compliance, and a missing skill degrades to the role's native method (no block). The earlier "[A] core = fail-loud" wording was wrong and is removed. The only mechanically-enforced requirement lives in D2/D3 (the three prongs). Both surfaces edited (`plugins/orbit/agents/*.md` + `.claude/agents/*.md` parity; dev surface uses orbit-domain slot fills).

- **`architect.md`**: [A-directive] discovery `superpowers:brainstorming`, planning `superpowers:writing-plans` — prompt directs always-use; if absent the prompt directs the architect to report it and fall back to manual framing (NOT a runtime block). [C] `/gsd-explore`, `/gsd-plan-phase`. Keep "leader never writes plans" invariant.
- **`builder.md`**: [A-directive] `superpowers:test-driven-development`, `superpowers:verification-before-completion`. [C] `superpowers:systematic-debugging`, `executing-plans`, `using-git-worktrees`, `finishing-a-development-branch`, `/gsd-debug`. All prose guidance, native fallback.
- **`reviewer.md`**: the three prongs are TIER-1 (D3, enforced). The [C] alt-lens wirings (`receiving-code-review`, `/gsd-code-review`, `/gsd-secure-phase`, `/qa-only`, `/review`, `cso`) are TIER-2 prose options.
- **`leader.md`**: [A-directive] `superpowers:using-superpowers` (session-start skill discovery), [C] `dispatching-parallel-agents` (fan-out). NO work-skill wiring. Drop any "low-risk skips / works without plugins" companion-optional language.
- **`explore.md`**: superpowers N/A (native glob/grep); [C] `/gsd-map-codebase`, `/gsd-explore`.
- **`critic.md`**: [A-directive] `superpowers:receiving-code-review` (rigor posture). [C] `/gsd-secure-phase`, `cso` (T3 trigger).
- **`researcher.md`**: superpowers/GSD N/A (no fitting skill — honest); [C] gstack `scrape`, `browse`.

**Critical builder instruction:** do NOT add fail-loud/block logic to ANY D4 wiring — neither [A-directive] nor [C]. The only block surface is D2 (hook, scoped) + D3 (reviewer prong contract). D4 is prompt text only. Over-guarding re-introduces the brittleness the critic flagged.

### D5 — orbit-cycle.md: invert the graceful-degradation table (TIER-1 framing)

- Replace the "동반 플러그인 없을 때 graceful 동작" table (≈ lines 206-214) and the "플러그인 없이도 생명주기는 완전히 실행 가능하다" line with a **"Required for verification (Triple Crown)"** section: the three companions are prerequisites **for the verification prongs specifically**; a missing prong tool blocks *that prong* (not all orbit work) with install guidance.
- Step 5 prongs ①②③: state each tool as required at the prong, fail-loud (mirror the reviewer contract D3). Make clear non-verification steps (planning/build) are not blocked by companion absence — only the verification step that needs the tool is (BLOCKER #1 framing).
- Keep `/gsd-help`, `/qa`, `/review` interface references (confirmed correct); name expected commands so renames surface (MINOR #7).

### D6 — orbit-init.md: Step 6 prereq notice (warn, scoped, with escape hatch)

- Rewrite Step 6: the three are **required for the Triple Crown verification prongs** (not "선택적/소프트 의존", but also not "required to do anything"). If any missing, print a prominent notice + per-plugin install command + which prong will block.
- orbit-init **warns, never hard-aborts** the `.orbit/` scaffold (scaffolding is companion-independent; enforcement is at the prong, per D2/D3).
- Mention the `ORBIT_SKIP_COMPANION_CHECK` escape hatch for CI/headless (D2 step 4), and seed it (commented) into `.orbit/config` via the config template.

### D7 — Manifests / README / CHANGELOG / plugin CLAUDE.md (phased versioning)

- `plugins/orbit/.claude-plugin/plugin.json`: TIER-1 lands at **`2.0.0`**; if TIER-2 ships separately it bumps to **`2.1.0`** (same file, second commit). **Do NOT add `dependencies` for the three** (Unknown #1). (No unresolvable `dependencies` array — a doc-only hint, if any, must not be that field.)
- `.claude-plugin/marketplace.json` (root): mirror the version bump; **description corrected (MAJOR #4):** replace "어떤 기술 스택에도 적용 가능 / 도메인 무관 단일 플러그인" with honest copy — orbit's Triple Crown **requires** superpowers + GSD + gstack as companion plugins. State the vendor-lock plainly.
- `plugins/orbit/CLAUDE.md`: update "Quality Gate"/"Verification Standard" — the **companion-prong check** fail-loud at the verification prong (scoped per D2); the project `.orbit/quality-gate.sh` no-op-when-absent for *build commands* stays. Clarify these are two distinct gates and that companion absence does NOT block non-verification work.
- `README.md`: add a **Requirements / Prerequisites** section listing the three as mandatory **for verification** with install commands; correct any "works standalone / optional companions / applies to any stack" copy (MAJOR #4 honesty). This is the user-facing honesty surface.
- `CHANGELOG.md`: **two separate entries** (per MAJOR #3): **`v2.0.0` (BREAKING)** = TIER-1 only — the three Triple Crown prongs now require their companion (hook + reviewer contract, scoped); clean installs without companions block *at verification*; migration = install the three (or set `ORBIT_SKIP_COMPANION_CHECK` for automation). **`v2.1.0` (feature, non-breaking)** = TIER-2 per-role prose skill wiring across 7 roles. Do NOT fold TIER-2 into the BREAKING entry.
- `gemini-extension.json` / `.codex-plugin/plugin.json`: check for a version field and bump for parity if present (builder to confirm; likely metadata only).

### D8 — Hook-layer parity asymmetry (per critic MINOR #6) — decide explicitly

The deploy product enforces the prong check via `plugins/orbit/hooks/quality-gate.sh` (SubagentStop in hooks.json). The **dev team's** SubagentStop is wired inline in `.claude/settings.json`, NOT through the deploy `quality-gate.sh` — so the dev team's own self-verification does **not** run the companion prong guard. **Decision (recommended): intentional, documented asymmetry.** The dev team always has the three companions installed (dogfood precondition), and routing dev's hook through the deploy script would couple dev self-verification to a product artifact it is supposed to test at arm's length. Builder records this as a deliberate non-parity in a one-line note in `.claude/` (or the plan's memory promotion), so a future reader does not mistake it for drift. *Alternative (rejected unless leader directs):* mirror the guard into `.claude/settings.json` — rejected because it adds a second enforcement surface to maintain for a precondition that already holds in dev.

### D9 — L1 consideration-delivery hook (NEW — pre-role skill-consideration injection)

**Hook-event reality — CONFIRMED by official docs (the ★ no-guessing requirement):**
- **`SubagentStart` fires when a subagent is spawned, before its execution**, and **supports context injection** via `hookSpecificOutput.additionalContext` (a string delivered as a system reminder the subagent reads on its next model request). Source: code.claude.com/docs/en/hooks lifecycle + decision-control tables.
- **`SubagentStart` cannot block** (no decision control; exit-code 2 only shows stderr). This is *exactly* the property we want: L1 must never gate, only deliver. The mechanism's own limitation enforces the honesty constraint.
- orbit **already wires SubagentStart** (`hooks.json:60-70` → `viewer-attach.sh`), so adding a second SubagentStart hook entry is a known, supported pattern — no new event type, no speculative design.

**Design:**
- New hook script `plugins/orbit/hooks/skill-consideration.sh` (or `.py`), added as a second `SubagentStart` entry in `hooks.json` (alongside viewer-attach).
- It reads the SubagentStart stdin payload to get the **role/subagent name**, looks up that role's **available skill list from config/slots** (not hardcoded — see domain-purity below), and emits:
  ```json
  {"hookSpecificOutput":{"hookEventName":"SubagentStart",
    "additionalContext":"You are acting as <role>. Skills available for this role: <list>. Before doing the work, consider whether any apply to THIS task; if so, use them. If the task is simple/meta and none genuinely apply, you may skip them — do not force a skill where it adds no value."}}
  ```
- **Companion-aware (graceful, per requirement #5):** the injected list contains **only skills whose companion is actually installed** (reuse the D2 detection: exact-name + enabled-state via `claude plugin list --json`). It must NOT tell a role to "consider" a skill from an absent companion. If `claude` is unavailable or no companions present → inject a minimal/empty notice (or skip injection entirely) rather than referencing phantom skills. L1 degrades silently because it is non-enforcing.
- **Domain-purity (requirement #5, consistent with MAJOR #4):** the role→skill map is **config/slot-driven**, sourced from `.orbit/config` (or a new `{{ROLE_SKILL_MAP}}` slot) seeded by the orbit-init template, NOT hardcoded into the shipped hook. The shipped default map names the vendor skills (the documented vendor-lock), but the *seam* stays repointable. This mirrors the L2 prompt wiring (Unknown #3 table) — single source, two deliveries.

**Honest labeling (requirement #3 — BLOCKER #2 trap NOT repeated):**
- L1 is named **"consideration delivery layer"**, never "enforced/required". It is **not** in TIER-1.
- The plan/CHANGELOG/tests describe it as: *guarantees the consideration prompt is delivered to the subagent; does NOT guarantee the agent considers or invokes — that remains agent judgment, and skipping is explicitly permitted.*
- Success criteria for L1 test only **delivery** (the additionalContext reaches the subagent), and explicitly state that "whether the agent considered it" is **unverifiable and out of scope**.

**Version placement (requirement #6):** L1 is **non-enforcing → non-breaking → v2.1.0** (with L2, the prose wiring it surfaces). Rationale: it adds no gate, blocks nothing (SubagentStart can't block), and degrades gracefully when companions are absent. It belongs with TIER-2, not the v2.0.0 BREAKING TIER-1. A clean install without companions sees L1 inject an empty/minimal notice and proceeds — no behavior break.

### Impact scope (file-class sweep)

**Deploy product (`plugins/orbit/`):** — *7-role expansion: ALL 7 agent prompts now in scope (was 4)*
- agents/reviewer.md, agents/architect.md, agents/builder.md, agents/leader.md, **agents/explore.md, agents/critic.md, agents/researcher.md** (prose-only "Companion skill wiring" subsection per D4)
- hooks/quality-gate.sh, templates/quality-gate.template.sh
- **hooks/skill-consideration.sh (NEW — L1, D9)**, **hooks/hooks.json (NEW SubagentStart entry — L1)**
- commands/orbit-cycle.md, commands/orbit-init.md
- **templates/orbit-config.template (NEW — seed `{{ROLE_SKILL_MAP}}` / role-skill map for L1, D9)**
- CLAUDE.md
- .claude-plugin/plugin.json (version + metadata)
- (verify) gemini-extension.json, .codex-plugin/plugin.json

*L1 note:* hooks.json gains a SubagentStart entry (orbit already wires SubagentStart for viewer-attach, so this is an additional hook in the existing array — confirmed supported, D9). The role→skill map is config-driven, seeded by the config template, repointable (domain-purity seam).

**Repo root / dev meta:** — *all 7 dev-surface agents now in scope*
- .claude-plugin/marketplace.json (root) — version + description
- README.md, CHANGELOG.md
- **.claude/agents/{reviewer,architect,builder,leader,explore,critic,researcher}.md** (dev parity — mirror the [A]/[C] wiring with orbit-domain slot fills; deep-mode drift on dev reviewer still flagged separately, NOT imported here)

**Scale note:** the 7-role expansion roughly doubles the edited agent-prompt surface (7 deploy + 7 dev = 14 prompt files vs. the prior 4+3). Each is prose-only, but parity discipline across 14 files raises drift risk — see new test T-G.

Touches **≥ 3 components** and changes public/lifecycle contract → T2 fires. TIER-1 reverses a documented v1.0.0 invariant (self-containment) → T1 (backward-compat break). **high-risk → critic gate before Plan Approval** (this revision is the post-REVISE re-gate candidate).

---

## Test Strategy

Past lesson (memory): **gates are verified by execution-based positive/negative tests, not grep.** The hook tests below center on the **scoped** behavior (BLOCKER #1): block only on verification-prong completion, pass everything else.

### T-A: Prong-relevant + tool absent ⇒ block (negative)
- Simulate a **reviewer prong** completion (SubagentStop stdin payload marking reviewer/prong context) with a stubbed `claude` reporting the needed companion *missing*.
- **Assert:** stdout `{"decision":"block"...}` names exactly the one missing plugin for that prong + install command. (Not all three — per-prong scoping.)

### T-B: Prong-relevant + all present ⇒ pass-through (positive)
- Prong context, stubbed `claude` reports companion present (and *enabled* — see T-B2).
- **Assert:** companion check passes; project `.orbit/quality-gate.sh` delegation still runs (temp gate exit 0 ⇒ no block; exit 1 ⇒ block with its message). Two gates compose.

### T-B2: disabled-but-listed plugin ⇒ treated as absent (MINOR #5)
- Stub `claude plugin list` output where the companion appears but is **disabled** (and a substring-collision name, e.g. `gstack-helper`, to catch naive `grep gstack`).
- **Assert:** the check treats disabled as absent (blocks in prong context) and does NOT false-match the substring. Detection must parse enabled-state + exact name, not bare `grep`.

### T-C: ★ Irrelevant work ⇒ ALWAYS pass (the BLOCKER #1 core test)
- Simulate **non-reviewer** completions (builder, explore, researcher, architect, doc/meta) with companions *missing* AND with `claude` *absent from PATH*.
- **Assert:** hook exits 0 (no block) in every irrelevant case. This is the regression test against the suicide-gate. Run the dev-team self-build scenario explicitly (claude not on subagent PATH, builder completion) ⇒ must pass.

### T-C2: prong-relevant + `claude` unavailable ⇒ warn, not hook-block
- Prong context, `claude` not on PATH.
- **Assert:** hook emits a non-blocking stderr warning and exits 0 (defers to reviewer contract), NOT a hook block. Confirms the fail-closed suicide path is gone; enforcement moved to D3.

### T-C3: escape hatch
- `ORBIT_SKIP_COMPANION_CHECK=1`, prong context, companion missing.
- **Assert:** hook passes with a "prong check skipped" notice. Confirms CI/headless escape works and is visible.

### T-D: Syntax / schema validation
- `bash -n` on quality-gate.sh + template; `python3 -m json.tool` on all JSON manifests; `claude plugin validate` on plugin.json if available.

### T-E: Prompt-contract static checks (supplement, not primary)
- Grep that no "graceful / works without / tool not available ⇒ manual PASS" hedge survives in reviewer.md (both), orbit-cycle.md, orbit-init.md for the three companions.
- **Honesty grep (MAJOR #4):** assert the manifest description + README no longer claim "applies to any stack / domain-agnostic / optional companions" — corrected to the documented vendor-lock.
- Project-purity (narrow, honestly labeled): `grep -rE 'oremi|Oremi|orbit-dev' plugins/orbit/` ⇒ 0. **Reported as "no dogfood-project leakage", NOT as "domain-agnostic".**

### T-F: Parity check (all 7 roles)
- For each role, diff the "Companion skill wiring (guidance)" subsection of deploy vs `.claude/` ⇒ semantically aligned (dev slot fills allowed). Deep-mode drift recorded separately, not silently changed. Confirm D8 hook-parity asymmetry is *documented* (a note exists), not accidental.

### T-G: TIER-2 prose coverage + no-over-guard (revised per BLOCKER #2)
- **Coverage:** each of the 7 deploy prompts contains the guidance subsection matching Unknown #3 ([A-directive]/[C]/N-A).
- **★ No-over-guard (negative, load-bearing):** assert NO D4 wiring — neither [A-directive] nor [C] — carries `block`/`decision":"block"`/hook-style fail-loud language. The ONLY prompt allowed to say a tool is required-and-FAIL-on-absence is `reviewer.md` (the three prongs, D3). Grep for block/fail-loud co-located with any non-prong skill name ⇒ 0. This is the BLOCKER #2 guard: prose stays prose.
- **Enforceability honesty:** the plan/CHANGELOG label TIER-2 as "guidance, not enforced" — assert the CHANGELOG v2.1.0 entry does not use the word "required/enforced" for the prose wiring.
- **N/A honesty:** explore(sp), researcher(sp+GSD), leader(GSD+gstack) state reasoned N/A, no invented skills.

### T-H: L1 consideration-delivery hook (NEW — D9; tests DELIVERY only)
- **Delivery positive:** run `skill-consideration.sh` with a SubagentStart stdin payload naming a role (e.g. `builder`) and stubbed `claude` reporting companions present. **Assert:** stdout is valid JSON with `hookSpecificOutput.hookEventName=="SubagentStart"` and `additionalContext` containing (a) the role's available skills and (b) the explicit "skip if not needed" permission. (`python3 -m json.tool` valid.)
- **Companion-aware filtering (graceful, #5):** stub a companion as absent/disabled. **Assert:** the injected list excludes that companion's skills — no "consider <phantom skill>" referencing an uninstalled companion. With `claude` absent or no companions ⇒ minimal/empty notice, never phantom skills, exit 0.
- **Never-blocks:** **Assert** the hook never emits a `decision":"block"` and a non-zero/garbage exit does not gate the subagent (SubagentStart cannot block — structural). 
- **Honesty boundary (explicit non-test):** the test suite **states** that "whether the agent actually considered or invoked a skill" is **unverifiable and deliberately NOT tested** — L1's contract is delivery, not compliance. This note must appear so a future reader does not add a false "did the agent use it" assertion.
- **No-mislabel:** assert L1 is never described as "required/enforced" in hook comments, CHANGELOG, or success criteria (same BLOCKER #2 guard applied to L1).

---

## Success Criteria (measurable)

**TIER-1 (v2.0.0 BREAKING — enforced):**
1. T-A passes: prong-relevant + missing companion ⇒ `block` naming the *one* prong's plugin + install command.
2. T-B / T-B2 pass: present-and-enabled ⇒ pass and composes with project gate; disabled-but-listed ⇒ treated as absent; no substring false-match (MINOR #5).
3. **★ T-C passes: companion-irrelevant work (builder/explore/researcher/architect/meta) ALWAYS passes**, even with companions missing and `claude` absent — including the dev-team self-build scenario. (BLOCKER #1 regression gate.)
4. T-C2 passes: prong-relevant + `claude` unavailable ⇒ non-blocking warning + defer to reviewer contract, NOT a hook block. T-C3: escape hatch works and is visible.
5. reviewer ①②③ each report `FAIL` (never PASS) when their prong tool is absent — the independent second gate, unaffected by the hook bypass/env var.
6. No "graceful PASS" hedge survives for the three companions (reviewer×2, orbit-cycle, orbit-init); T-E passes.
7. `plugin.json` + `marketplace.json` at `2.0.0`; **no `dependencies` array**; all JSON valid. CHANGELOG `v2.0.0` BREAKING entry covers **TIER-1 only**.
8. **MAJOR #4 honesty:** manifest description + README state the companion vendor-lock plainly; no surviving "any stack / domain-agnostic / optional" copy. Project-purity grep = 0, reported as "no dogfood leakage" (not "domain-agnostic"). `bash -n` clean.
9. D8 hook-parity asymmetry is documented (intentional note exists), not silent.

**TIER-2 / L2 (v2.1.0 feature — NON-breaking prose wiring):**
10. All 7 roles × both surfaces (14 prompts) carry the "Companion skill wiring (guidance)" subsection matching Unknown #3 ([A-directive]/[C]/N-A) — T-G coverage.
11. **★ No-over-guard (BLOCKER #2 gate):** no D4 wiring carries block/fail-loud language; only `reviewer.md` prongs may (T-G negative). A missing TIER-2 skill never blocks.
12. CHANGELOG `v2.1.0` entry labels TIER-2 as guidance, NOT "required/enforced"; N/A entries honest (no invented skills); 7-role parity holds (T-F); dev-reviewer deep-mode drift handled as a separate flagged item.

**L1 — Consideration delivery (v2.1.0 feature — NON-breaking, non-enforcing):**
13. T-H delivery passes: `skill-consideration.sh` emits valid SubagentStart `additionalContext` carrying the role's available skills + explicit skip permission.
14. **Companion-aware (graceful):** absent/disabled companion ⇒ its skills excluded from the injected list; `claude` absent / no companions ⇒ minimal-or-empty notice, never phantom skills; never blocks. Role→skill map is config/slot-driven (repointable seam), not hardcoded.
15. **Honesty (BLOCKER #2 trap not repeated):** L1 is labeled "consideration delivery", never "required/enforced", not in TIER-1; the test suite explicitly records that agent *compliance* is unverifiable and out of scope; CHANGELOG v2.1.0 describes L1 as a delivery/consideration nudge with skip permitted.

---

## Builder build-time notes (critic MINORs — handle during implementation)

- **#5 detection robustness:** `claude plugin list | grep <name>` is unsafe — substring collisions (e.g. `gstack` vs `gstack-helper`) AND disabled-but-listed plugins both mislead. Parse exact name + enabled state (prefer `claude plugin list --json` and read the entry's enabled/errors fields). Covered by T-B2.
- **#6 dev hook parity:** documented intentional asymmetry per D8. Builder leaves a one-line note recording it.
- **#7 interface version pinning:** prong commands unpinned; not mechanically pinnable (ADR-REQDEPS-1). Error messages name the *expected* command so a rename fails loud. Documented fragility, per Rollout strategy.

## Open Decisions for critic / leader (flagged, not pre-resolved)

1. **Companion check location** (D2): in `quality-gate.sh` vs new hook script. Recommend in-place (no new drift surface).
2. **orbit-init hard-abort vs warn** (D6): recommend warn-only (enforcement at the prong).
3. **Dev-reviewer deep-mode drift** (D3): recommend separate roadmap item; needs leader's call.
4. **SemVer / phasing**: TIER-1 = `2.0.0` BREAKING, TIER-2 = `2.1.0` feature (recommend, per MAJOR #3). Whether to ship in one cycle or two is leader's call; versioning/CHANGELOG stay separate either way. Confirm at Plan Approval.

---

## Revision log

- **R1 (post-critic REVISE, 2026-06-24):** addressed BLOCKER #1 (scoped the SubagentStop guard to verification-prong completions only + escape hatch + dual-gate; killed the fail-closed suicide path — D2, T-C/C2/C3), BLOCKER #2 (split TIER-1 enforced vs TIER-2 prose; relabeled [A] "fail-loud" → prose directive — Goal, asymmetry block, D4, T-G), MAJOR #3 (adopted phased rollout v2.0.0/v2.1.0 — Rollout strategy, D7, success criteria split), MAJOR #4 (honest vendor-lock in manifest/README; stopped using narrow grep to claim domain-agnosticism — D1a, D7, T-E), and MINORs #5/#6/#7 (build-time notes + T-B2 + D8). Ready for re-gate.
- **R2 (post-PROCEED, user added L1, 2026-06-24):** integrated the user's **pre-role skill-consideration injection** as a NEW non-enforcing **L1 layer** (D9). Verified hook-event reality against official docs (SubagentStart fires pre-execution, supports `additionalContext`, cannot block — exactly the non-gating property needed; orbit already wires SubagentStart). Formalized the **three-layer model** (L1 consideration-delivery / L2 prose wiring / L3 enforced prongs) with explicit boundaries. Placed L1 in v2.1.0 (non-breaking). Labeled L1 honestly as delivery-only (BLOCKER #2 trap not repeated; tests DELIVERY only, agent compliance explicitly unverifiable). Domain-purity: role→skill map config/slot-driven, companion-aware graceful. Added T-H + success criteria 13-15 + ADR-REQDEPS-4.

---

## ADR (Architecture Decision Record)

**ADR-REQDEPS-1:** Required external companions (superpowers/GSD/gstack) are enforced via **runtime guards**, NOT via `plugin.json` `dependencies`. Rationale: the `dependencies` field resolves only within the declaring plugin's own marketplace; cross-marketplace install requires an allowlist in the *consuming user's* root marketplace that orbit cannot set, so a declared dependency would fail to resolve and self-disable orbit on clean installs. Revisit only if all four ship in one tagged unified marketplace.

**ADR-REQDEPS-2 (post-REVISE):** "Required" is enforced **only at the verification prongs** (TIER-1), via two independent gates — a **scoped** SubagentStop hook (blocks only when a reviewer prong completes without its companion; passes all companion-irrelevant work) and the **reviewer report contract** (a prong is never PASS without tool output). The hook is fail-*open* for irrelevant work and defers to the reviewer when CLI detection is impossible — the opposite of the original fail-closed design — because SubagentStop fires on every subagent and a blanket block bricks orbit (CI/headless/dev-self-build). Per-role skill wiring (TIER-2) is **prose guidance, explicitly not enforced**: orbit cannot verify an agent's actual skill invocations, so claiming otherwise would be dishonest. TIER-1 is the only backward-compat break (v2.0.0); TIER-2 ships non-breaking (v2.1.0).

**ADR-REQDEPS-3 (domain-agnosticism, honest):** v2.0.0 deliberately ends orbit's domain/stack-agnostic positioning for its verification layer — the Triple Crown now hardcodes vendor tools. This is stated plainly in the manifest description and README. The `oremi|orbit-dev` purity grep is retained only as a *dogfood-leakage* check and is never cited as evidence of domain-agnosticism.

**ADR-REQDEPS-4 (L1 consideration-delivery layer):** A **SubagentStart** hook (`skill-consideration.sh`) injects, at subagent spawn, the role's currently-available skills plus a "consider-then-use-or-skip" directive via `hookSpecificOutput.additionalContext`. Chosen because SubagentStart is confirmed to (a) fire before subagent execution, (b) support context injection, and (c) **be unable to block** — making it structurally impossible for L1 to gate or brick orbit, which matches the user's intent of a *consideration nudge with explicit skip permission*, not enforcement. L1 is **not** TIER-1: it guarantees *delivery of the consideration prompt*, never *compliance* (agent judgment, unverifiable). The role→skill map is config/slot-driven and companion-aware, so absent companions are never surfaced as phantom skills; with no companions L1 degrades to an empty notice. Non-breaking → ships v2.1.0 with L2. This is the third layer: L1 (consider) → L2 (static guidance) → L3 (enforced prongs).
