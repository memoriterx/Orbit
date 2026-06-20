# Discovery-First Lifecycle Step (Option b2) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a contractual "Discovery first" step to the single-task lifecycle — the architect performs explicit problem-framing, requirements, scope, and prioritization *before* writing the plan, delegating internal facts to `explore` and external facts to `researcher` — **without adding any new agent** (roster stays 7).

**Architecture:** This is a documentation/prompt-contract change only. No executable code, no roster change, no new handoff. The discovery step is named as a pre-plan sub-activity of the *existing* architect role, explicitly framed as "use the existing explore/researcher spokes," not as a new investigation role. Edits are minimal and lean append-only: the five **step-enumerating** lifecycle surfaces gain a discovery node. A separate class of surfaces — the **four-phase lifecycle *summary*** (`plan, approve, implement, verify`) that appears in SKILL.md and the codex manifest, and the "Lifecycle discipline … applies" pointers in codex/gemini references — is **deliberately left unchanged**, with the rationale documented in the inventory below: discovery is a sub-step *of* the "plan" phase, and promoting it into a 4-phase invariant would wrongly elevate a sub-step to a peer phase. Verification is grep-based consistency gates (extended to assert the summary surfaces stay summary-level) + the autonomous-mode harness re-run (because leader.md and the lifecycle prose are touched).

**Tech Stack:** Markdown agent-prompt + skill + command files; JSON plugin manifests. No build system, no unit-test framework. The "test suite" is a set of grep/jq consistency assertions plus `verify-autonomous-mode.sh`.

## Global Constraints

- **Domain-agnostic (verbatim rule):** files under `plugins/orbit-base/` contain no hardcoded project names (oremi, orbit-dev, etc.); domain values stay as `{{...}}` slots. Gate: `grep -riE 'oremi|orbit-dev' plugins/orbit-base/` → 0 hits.
- **No new agent / roster stays 7:** do NOT create `agents/planner.md`; do NOT change "7 roles" / the spoke list / role-dispatch tables. The roster count is a guard, not a target.
- **Lean / append-only bias:** add the discovery step by inserting a node/line, not by renumbering or restructuring existing lifecycle steps. Do not increase the *count* of numbered lifecycle stages where a sub-step/annotation suffices. No new handoff (no leader→X→leader round trip beyond the architect's existing single dispatch).
- **Discovery uses existing spokes, is not a new role:** every discovery mention must state that internal facts go to `explore` and external facts to `researcher` (existing spokes), with the architect synthesizing — never imply a new investigation role.
- **Hub-and-spoke / Plan Approval / Triple Crown unchanged:** discovery is a pre-plan sub-activity of the architect's existing single dispatch. No change to gates, routing, or verification.
- **Scope = deployed product only:** edit only files under `plugins/orbit-base/`. Do NOT touch `.claude/`, `setup-orbit.sh`, or root `README.md`.
- **Frontmatter/structure style must match existing agents** when editing `architect.md` (`---\nname/description/model\n---` then H1, `## Core Responsibilities`, etc.). No emoji beyond what a file already uses.

---

## Touched-Surface Inventory (blast radius)

**Census method (not assumed):** the lifecycle-describing surfaces were enumerated by grep, not guessed. Two distinct classes emerged, and the distinction drives the edit/no-edit decision:

- **Class A — step enumerators** (list the lifecycle *steps* in order: select → plan → gate → approve → build → verify). These MUST gain the discovery node, or they go stale.
- **Class B — phase summaries** (a 4-phase invariant `plan, approve, implement/build, verify`, or a generic "Lifecycle discipline … applies" pointer). These name *phases*, not steps. Discovery is a sub-step **of the "plan" phase**, so a Class B surface is **not stale** without it. Editing Class B would wrongly promote a sub-step to a 4th/5th peer phase and is therefore **deliberately not done** — documented per-surface below.

Grep census (run at planning time against the live files; re-asserted in Task 6 — these exact line numbers were verified, not assumed):
```bash
# Class B phase-summary / lifecycle-pointer surfaces (verified present):
#   SKILL.md:8     "structured lifecycle for delivering work: plan, approve, implement, verify"
#   SKILL.md:145   "plan → approve → build → verify independently"
#   SKILL.md:153   "| Lifecycle discipline | Full | Full | Full |"
#   SKILL.md:158   "plan → approve → build → verify is the invariant"
#   .codex-plugin/plugin.json:28  "structured lifecycle for software delivery: plan, approve, implement, verify"
#   codex-tools.md:32   "Lifecycle discipline and Triple Crown verification still apply"
#   codex-tools.md:76   "| Lifecycle discipline and Triple Crown | Full — identical |"
#   gemini-tools.md:37  "The lifecycle discipline and Triple Crown verification remain identical"  (prose; matched by the broader 'lifecycle discipline' grep, lowercase)
#   gemini-tools.md:66  "| Lifecycle discipline and Triple Crown | Full — identical |"
# Note: the Task 6 census grep uses the patterns 'plan, approve, implement, verify | plan → approve → build → verify | Lifecycle discipline'
# and is the source of truth; this comment list is the human-readable summary. gemini-tools.md:37 is lowercase 'lifecycle discipline'
# (a prose sentence) — include '-i' if matching it explicitly is desired; the no-edit decision applies to it either way.
```

| File | Class | Action | What changes / why not |
|------|-------|--------|------------------------|
| `plugins/orbit-base/agents/architect.md` | A (owner) | **Modify** | Discovery contract home: Core Responsibilities bullet + Working Principle + Task Sequence step 1. |
| `plugins/orbit-base/CLAUDE.md` | A | **Modify** | One line in the Single-Task Lifecycle fenced block (discovery node before writing-plans). |
| `plugins/orbit-base/agents/leader.md` | A | **Modify** | One line in the Workflow fenced block; one line in the "Plan Writing — Always Architect's Job" list. |
| `plugins/orbit-base/skills/using-orbit/SKILL.md` (lifecycle block, lines 32-40) | A | **Modify** | `1a. Discover` sub-step under step 1 (no renumber). *Note:* the SAME file's lines 8/145/158 are Class B and stay unchanged — see below. |
| `plugins/orbit-base/commands/orbit-cycle.md` | A | **Modify** | One node in the Korean ASCII overview + a short discovery paragraph in Step 2. |
| `plugins/orbit-base/skills/using-orbit/SKILL.md` (lines 8, 145, 153, 158) | B | **No edit (justified)** | These state the 4-phase invariant `plan→approve→build→verify` (8/145/158) or a "Lifecycle discipline: Full" degradation-table row (153). Discovery is a sub-step of "plan"; adding it would create a false 5-phase invariant. Left as a phase summary by design. |
| `plugins/orbit-base/.codex-plugin/plugin.json` (line 28) | B | **No edit (justified)** | `longDescription` is a marketing phase summary (`plan, approve, implement, verify`), not a step list. Same rationale as SKILL.md:8. (Already reads "Seven roles" — no roster issue.) |
| `plugins/orbit-base/skills/using-orbit/references/codex-tools.md` (lines 32, 76) | B | **No edit (justified)** | "Lifecycle discipline … still apply" (32) and a "Lifecycle discipline: Full" row (76) are *pointers to* the lifecycle, not restatements of its steps. The steps live in SKILL.md (edited). Restating discovery here would duplicate the contract and risk drift. |
| `plugins/orbit-base/skills/using-orbit/references/gemini-tools.md` (lines 37, 66) | B | **No edit (justified)** | Same as codex-tools.md: prose pointer (37) + a "Lifecycle discipline: Full" row (66), not step enumerations. |
| `plugins/orbit-base/.claude-plugin/plugin.json` | — | **Verify only** | JSON validity check; contains no lifecycle step/summary string to update. |

**Total: 5 files modified (all Class A step enumerators). 4 files deliberately not edited (Class B summaries/pointers across SKILL.md/codex manifest/codex-tools/gemini-tools) + the claude manifest verify-only, each with a recorded rationale.** This 5-modified count is load-bearing for the T2 self-diagnosis below. (Class B occurrences span ~9 lines across those 4 files; the no-edit decision and the leak guard apply to all of them.)

**Why Class B is left alone (not an oversight — a decision):** the framework intentionally has two altitudes of lifecycle description. Step enumerators (Class A) are the operational contract and must carry discovery. Phase summaries (Class B) are a stable 4-phase mental model (`plan/approve/build/verify`); discovery lives **inside** "plan." Keeping Class B at phase altitude prevents two failure modes: (1) a false invariant where some surfaces say 4 phases and others 5; (2) contract duplication across dispatch-map references that then drift from the canonical step list. Task 6 adds a **guard** asserting Class B still reads as a 4-phase summary (no "discovery" leaked into the invariant), so this is enforced, not merely intended.

---

### Task 1: Add the Discovery contract to `architect.md`

The architect *owns* the discovery step, so its agent file is the contract's canonical home. This task makes the other surfaces' one-liners point at a real, defined contract.

**Discovery vs. the architect's existing "Read requirements" (anti-tautology — stated transparently).** Today `architect.md` Task Sequence step 1 is literally "Read requirements," and Error Handling already covers "Ambiguous requirements → reasonable default + ADR." So discovery is **not a new capability** — the architect already reads requirements and resolves ambiguity. What b2 adds is **explicit naming + sequencing of a discipline that was previously implicit**: (1) it makes problem-*framing* (the "why," distinct from "read the stated requirements") a named first move; (2) it makes must-have/nice-to-have *separation* and *priority order* mandatory outputs rather than optional; (3) it makes "delegate fact-finding to explore/researcher rather than re-investigate inline" an explicit instruction. **This is codification, not new machinery.** The value is that an implicit step under time pressure gets skipped; a named contract is checkable (a plan can be rejected for missing the framing). The plan states this openly so reviewers can judge whether the discipline is worth the prose — it is not dressed up as new capability. (If the team judges the naming not worth even 5 surfaces, the fallback is b3 — see "b2 vs. b3 net value" below.)

**Files:**
- Modify: `plugins/orbit-base/agents/architect.md`

**Interfaces:**
- Produces: the phrase "Discovery first" and the explore/researcher-delegation contract that CLAUDE.md, leader.md, SKILL.md, and orbit-cycle.md reference in Tasks 2-5. The exact step text below is the canonical wording later tasks shorten.

- [ ] **Step 1: Add a Core Responsibilities bullet for discovery**

In `plugins/orbit-base/agents/architect.md`, the Core Responsibilities `**Upfront (pre-implementation):**` block currently starts (lines 13-14):
```
**Upfront (pre-implementation):**
- Project directory structure and module boundaries
```
Insert a discovery bullet as the FIRST item of the Upfront block, so it reads:
```
**Upfront (pre-implementation):**
- **Discovery first (before writing the plan):** frame the real problem, distill explicit requirements (must-have vs. nice-to-have), define scope, and set priority order. Delegate fact-finding to the existing spokes — internal codebase facts to `explore`, external facts to `researcher` (via the leader) — and synthesize their findings. Discovery is a pre-plan sub-activity of this role, not a separate agent.
- Project directory structure and module boundaries
```

- [ ] **Step 2: Add a Working Principle reinforcing "use existing spokes"**

The Working Principles list (lines 30-33) currently ends with:
```
- Follow the project's established directory conventions.
```
Add one principle immediately after it:
```
- Discovery uses the existing `explore`/`researcher` spokes; the architect synthesizes their reports and does not duplicate their search/investigation work. Never introduce a new investigation role.
```

- [ ] **Step 3: Rewrite the Task Sequence "When design/plan is requested" block to lead with discovery**

The Task Sequence block (lines 43-47) currently reads:
```
**When design/plan is requested:**
1. Read requirements
2. Produce directory layout, type definitions, API spec, env schema, deployment topology
3. Record in `{{ARCHITECTURE_DOC_PATH}}` or plan file
4. Report to leader (leader runs Plan Approval)
```
Replace it with (discovery becomes step 1; the rest shift but the *stage* is unchanged — this is still "architect produces the plan"):
```
**When design/plan is requested:**
1. **Discovery first:** frame the problem, list explicit requirements (must-have vs. nice-to-have), define scope, and set priority. Where facts are needed, request them through the leader from `explore` (internal) or `researcher` (external) — do not re-investigate yourself; synthesize their reports.
2. Produce directory layout, type definitions, API spec, env schema, deployment topology — informed by the discovery above.
3. Record discovery + design in `{{ARCHITECTURE_DOC_PATH}}` or the plan file (the plan opens with the discovery framing).
4. Report to leader (leader runs the high-risk gate, then Plan Approval).
```

- [ ] **Step 4: Verify frontmatter, domain purity, and contract presence**

Run:
```bash
head -5 plugins/orbit-base/agents/architect.md
grep -c 'Discovery first' plugins/orbit-base/agents/architect.md
grep -c 'explore' plugins/orbit-base/agents/architect.md
grep -riE 'oremi|orbit-dev' plugins/orbit-base/agents/architect.md ; echo "purity-exit=$?"
grep -c 'planner' plugins/orbit-base/agents/architect.md
```
Expected: frontmatter shows `name: architect` / `model: opus`; `Discovery first` count is `2` (Core Responsibilities bullet + Task Sequence step); `explore` count ≥ 2; `purity-exit=1` (no hits); `planner` count `0` (no new role introduced).

- [ ] **Step 5: Commit**

```bash
git add plugins/orbit-base/agents/architect.md
git commit -m "feat(base): add Discovery-first pre-plan step to architect (uses explore/researcher)"
```

---

### Task 2: Add the discovery node to `CLAUDE.md` lifecycle

**Files:**
- Modify: `plugins/orbit-base/CLAUDE.md`

**Interfaces:**
- Consumes: the "Discovery first" contract defined in Task 1.

- [ ] **Step 1: Insert the discovery line in the Single-Task Lifecycle block**

The fenced block (lines 17-25) currently reads:
```
roadmap selection
→ leader dispatches architect (writing-plans) → architect produces plan
→ High-risk? leader gates critic (independent plan critique) → architect revises; low-risk skips
→ Plan Approval: leader presents architect's plan → user confirms
→ leader dispatches builder (TDD) → post-implementation Triple Crown
  ① Completeness   ② Behavior   ③ Quality
→ done (roadmap checkbox)
```
Replace the first lifecycle arrow line:
```
→ leader dispatches architect (writing-plans) → architect produces plan
```
with (append-only — one inserted line, no renumber):
```
→ leader dispatches architect: discovery first (frame problem, requirements, scope, priority; uses explore/researcher) → then writing-plans → architect produces plan
```

- [ ] **Step 2: Verify**

Run:
```bash
grep -c 'discovery first' plugins/orbit-base/CLAUDE.md
grep -c '7 roles' plugins/orbit-base/CLAUDE.md
grep -c 'planner' plugins/orbit-base/CLAUDE.md
grep -riE 'oremi|orbit-dev' plugins/orbit-base/CLAUDE.md ; echo "purity-exit=$?"
```
Expected: `discovery first` count `1`; `7 roles` count `1` (roster UNCHANGED — guard); `planner` count `0`; `purity-exit=1`.

- [ ] **Step 3: Commit**

```bash
git add plugins/orbit-base/CLAUDE.md
git commit -m "docs(base): CLAUDE.md lifecycle — discovery-first before writing-plans"
```

---

### Task 3: Add the discovery node to `leader.md`

**Files:**
- Modify: `plugins/orbit-base/agents/leader.md`

**Interfaces:**
- Consumes: the discovery contract (Task 1). Note: the discovery is the architect's sub-step, so the leader still makes exactly ONE architect dispatch for the plan — no new handoff.

- [ ] **Step 1: Insert the discovery line in the Workflow fenced block**

The Workflow block (lines 50-61) currently begins:
```
roadmap selection
→ leader dispatches architect (writing-plans) → architect produces plan
→ High-risk gate: leader applies the four-trigger OR gate to the plan
```
Replace the line:
```
→ leader dispatches architect (writing-plans) → architect produces plan
```
with:
```
→ leader dispatches architect: discovery first (architect frames problem/requirements/scope/priority, drawing on explore/researcher via the leader) → then writing-plans → architect produces plan
```

- [ ] **Step 2: Add discovery to the "Plan Writing — Always Architect's Job" list**

The numbered list (lines 39-44) currently reads:
```
1. Leader dispatches **architect** via `Agent()` with the task context and a request to run `writing-plans`.
2. Architect produces the plan document.
3. Leader receives the plan as agent output.
4. Leader presents the plan to the user for approval (Plan Approval Gate).
5. After approval, leader dispatches builder for implementation.
```
Replace item 1 with two sub-points (still ONE dispatch — discovery is inside the architect's task, the leader only relays explore/researcher requests it already supports):
```
1. Leader dispatches **architect** via `Agent()` with the task context and a request to run **discovery first, then `writing-plans`**. Discovery = frame the problem, requirements, scope, priority; the architect requests internal facts from `explore` and external facts from `researcher` through the leader (no new role, no new dispatch pattern — the leader already routes these spokes).
```
Leave items 2-5 unchanged.

- [ ] **Step 3: Verify**

Run:
```bash
grep -c 'discovery first' plugins/orbit-base/agents/leader.md
grep -c 'planner' plugins/orbit-base/agents/leader.md
grep -riE 'oremi|orbit-dev' plugins/orbit-base/agents/leader.md ; echo "purity-exit=$?"
```
Expected: `discovery first` count `2`; `planner` count `0`; `purity-exit=1`.

- [ ] **Step 4: Commit**

```bash
git add plugins/orbit-base/agents/leader.md
git commit -m "docs(base): leader workflow — architect does discovery-first before writing-plans"
```

---

### Task 4: Add the discovery sub-step to `using-orbit/SKILL.md`

**Files:**
- Modify: `plugins/orbit-base/skills/using-orbit/SKILL.md`

**Interfaces:**
- Consumes: the discovery contract (Task 1). Uses a `1a.` sub-step label so the existing numbered steps (1, 1.5, 2, 3, 4, 5) are NOT renumbered (lean / append-only).

- [ ] **Step 1: Insert a `1a. Discover` sub-step in the Single-Task Lifecycle block**

The fenced block (lines 32-40) currently reads:
```
0. Select    leader picks one task from roadmap
1. Plan      leader dispatches architect (writing-plans) → architect produces plan document
1.5 Gate     leader judges high-risk (4-trigger OR gate); if high-risk → critic critiques plan → architect revises; low-risk skips
2. Approve   leader presents architect's plan → user approval (no implementation without approval)
3. Build     leader dispatches builder (TDD, systematic debugging, verification)
4. Verify    Triple Crown three-pronged verification (reviewer coordinates)
5. Done      roadmap checkbox + key decisions promoted to memory
```
Insert one sub-step line immediately AFTER the `1. Plan` line, so it reads:
```
0. Select    leader picks one task from roadmap
1. Plan      leader dispatches architect (writing-plans) → architect produces plan document
1a. Discover (within step 1, before the plan) architect frames problem/requirements/scope/priority, drawing internal facts from explore and external facts from researcher; no new agent
1.5 Gate     leader judges high-risk (4-trigger OR gate); if high-risk → critic critiques plan → architect revises; low-risk skips
2. Approve   leader presents architect's plan → user approval (no implementation without approval)
3. Build     leader dispatches builder (TDD, systematic debugging, verification)
4. Verify    Triple Crown three-pronged verification (reviewer coordinates)
5. Done      roadmap checkbox + key decisions promoted to memory
```

- [ ] **Step 2: Verify**

Run:
```bash
grep -c '1a. Discover' plugins/orbit-base/skills/using-orbit/SKILL.md
grep -c 'planner' plugins/orbit-base/skills/using-orbit/SKILL.md
grep -riE 'oremi|orbit-dev' plugins/orbit-base/skills/using-orbit/SKILL.md ; echo "purity-exit=$?"
```
Expected: `1a. Discover` count `1`; `planner` count `0`; `purity-exit=1`.

- [ ] **Step 3: Commit**

```bash
git add plugins/orbit-base/skills/using-orbit/SKILL.md
git commit -m "docs(base): using-orbit lifecycle — add 1a Discover sub-step (no new role)"
```

---

### Task 5: Mirror the discovery node in `orbit-cycle.md` (Korean)

The Korean lifecycle command must stay consistent with the English surfaces, or the framework documents two different lifecycles.

**Files:**
- Modify: `plugins/orbit-base/commands/orbit-cycle.md`

**Interfaces:**
- Consumes: the discovery contract (Task 1).

- [ ] **Step 1: Add the discovery node to the ASCII overview**

The overview block (lines 11-37) contains:
```
roadmap 선택
    │
    ▼
writing-plans  (플랜 작성)
    │
    ▼
Plan Approval  (사용자 승인)  ← 승인 없이 구현 금지
```
Replace the `writing-plans` node with a discovery node above it:
```
roadmap 선택
    │
    ▼
discovery  (architect — 문제 프레이밍·요구사항·스코프·우선순위; explore/researcher 활용)
    │
    ▼
writing-plans  (architect — 플랜 작성)
    │
    ▼
Plan Approval  (사용자 승인)  ← 승인 없이 구현 금지
```

- [ ] **Step 2: Add a short discovery paragraph to Step 2**

In `## Step 2: writing-plans (플랜 작성 — architect 위임)`, the body currently contains:
```
리드는 **architect**를 `Agent()`로 디스패치해 플랜 작성을 위임한다:

```
Agent(architect, prompt="[작업 컨텍스트와 요구사항]. writing-plans 스킬로 플랜 문서를 작성해 주세요.")
```
```
Replace that dispatch instruction with one that names discovery first (and write the actual triple-backtick fence in the file):
```
리드는 **architect**를 `Agent()`로 디스패치한다. architect는 **discovery를 먼저** 수행한 뒤 플랜을 작성한다 — 문제 프레이밍·요구사항(필수/선택 구분)·스코프·우선순위. 내부 사실은 `explore`, 외부 사실은 `researcher`(둘 다 기존 스포크, 리드 경유)에게 위임하고 architect가 종합한다. **신규 에이전트는 만들지 않는다.**

```
Agent(architect, prompt="[작업 컨텍스트와 요구사항]. 먼저 discovery(문제 프레이밍·요구사항·스코프·우선순위, explore/researcher 활용)를 수행한 뒤 writing-plans 스킬로 플랜 문서를 작성해 주세요.")
```
```

- [ ] **Step 3: Verify**

Run:
```bash
grep -c 'discovery' plugins/orbit-base/commands/orbit-cycle.md
grep -c 'planner' plugins/orbit-base/commands/orbit-cycle.md
grep -riE 'oremi|orbit-dev' plugins/orbit-base/commands/orbit-cycle.md ; echo "purity-exit=$?"
```
Expected: `discovery` count ≥ 3; `planner` count `0`; `purity-exit=1`.

- [ ] **Step 4: Commit**

```bash
git add plugins/orbit-base/commands/orbit-cycle.md
git commit -m "docs(base): orbit-cycle (KR) mirror — discovery node before writing-plans"
```

---

### Task 6: Final consistency gate + autonomous-mode harness regression

**Files:** none modified — verification only. This is the measurable success-criteria check (the orbit equivalent of a test suite for a docs change), and it includes the autonomous-mode harness re-run because leader.md and the lifecycle prose were touched.

- [ ] **Step 1: Domain purity gate (Global Constraint)**

```bash
grep -riE 'oremi|orbit-dev' plugins/orbit-base/ ; echo "exit=$?"
```
Expected: no output and `exit=1`. Any hit = FAIL.

- [ ] **Step 2: Roster-unchanged guard (no accidental role drift)**

```bash
grep -rc 'planner' plugins/orbit-base/ | grep -v ':0' ; echo "planner-files-exit=$?"
grep -rn '8 roles\|Eight roles\|seven roles' plugins/orbit-base/
grep -rn '7 roles' plugins/orbit-base/CLAUDE.md
ls plugins/orbit-base/agents/planner.md 2>/dev/null ; echo "planner-file-exit=$?"
```
Expected: first command prints nothing and `planner-files-exit=1` (no file contains "planner"); second command finds NOTHING (no "8 roles"/"Eight roles"/"seven roles" introduced); third finds the single unchanged "7 roles" line in CLAUDE.md; `planner-file-exit` is non-zero (file does not exist). This proves b2 added no role.

- [ ] **Step 3: Discovery-step set-diff — present on every Class A surface, absent from Class B**

```bash
echo "== Class A (step enumerators) MUST contain discovery =="
for f in agents/architect.md CLAUDE.md agents/leader.md skills/using-orbit/SKILL.md commands/orbit-cycle.md; do
  c=$(grep -ci 'discover' "plugins/orbit-base/$f"); echo "$f : $c"
done
echo "== Class B (phase summaries / pointers) MUST stay summary-level: no 'discover' leaked into the 4-phase invariant =="
# Each of these lines must still read as plan/approve/(implement|build)/verify with NO discovery token inserted.
grep -nE 'plan, approve, implement, verify|plan → approve → build → verify|Lifecycle discipline' \
  plugins/orbit-base/skills/using-orbit/SKILL.md \
  plugins/orbit-base/.codex-plugin/plugin.json \
  plugins/orbit-base/skills/using-orbit/references/codex-tools.md \
  plugins/orbit-base/skills/using-orbit/references/gemini-tools.md
echo "== guard: the word 'discover' must NOT appear on the same line as the 4-phase invariant =="
grep -nE '(plan, approve, implement, verify|plan → approve → build → verify).*discover|discover.*(plan, approve, implement, verify|plan → approve → build → verify)' \
  plugins/orbit-base/skills/using-orbit/SKILL.md plugins/orbit-base/.codex-plugin/plugin.json ; echo "leak-exit=$?"
```
Expected: each of the 5 Class A files reports a non-zero discover count; the Class B grep still prints the 7 census lines **unchanged** (proof they were not silently edited); the leak guard prints nothing and `leak-exit=1` (no discovery token contaminated a phase-summary line). This is the explicit false-green defense the inventory's Class A/B split requires — it fails loudly if either a Class B summary was wrongly edited OR a Class A surface was missed.

- [ ] **Step 4: explore/researcher-delegation phrasing present (axis-1 contract)**

```bash
grep -rl 'explore' plugins/orbit-base/agents/architect.md plugins/orbit-base/agents/leader.md plugins/orbit-base/skills/using-orbit/SKILL.md plugins/orbit-base/commands/orbit-cycle.md
grep -rn 'new investigation role\|신규 에이전트' plugins/orbit-base/agents/architect.md plugins/orbit-base/commands/orbit-cycle.md
```
Expected: all four files appear in the first list (discovery delegates to explore); the second confirms the explicit "not a new role" guard exists in at least architect.md and orbit-cycle.md.

- [ ] **Step 5: JSON manifest validity**

```bash
python3 -m json.tool plugins/orbit-base/.codex-plugin/plugin.json > /dev/null && echo "codex OK"
python3 -m json.tool plugins/orbit-base/.claude-plugin/plugin.json > /dev/null && echo "claude OK"
```
Expected: both print `... OK`. (No manifest was edited; this confirms the change did not corrupt them.)

- [ ] **Step 6: Autonomous-mode harness regression (leader.md / lifecycle adjacency)**

The edit touches `leader.md` and the lifecycle prose that the autonomous-mode checks live alongside. The harness re-run is a **regression guard** — it confirms the discovery edit left the autonomous-loop invariants (critic-on-entry, four-trigger gate, batch cap, skip-and-park, fan-out) intact. The harness is **orthogonal to discovery** (it does not test the discovery step itself); a PASS proves *non-interference*, not that "discovery added no node." (The "no new node / no new handoff" claim is established separately by the manual coherence read in Step 7 and the structure of the edits themselves.)

```bash
bash .planning/verify-autonomous-mode.sh ; echo "harness-exit=$?"
```
Expected: the harness runs its checks (referenced as C1–C15g) and exits `0`. If any check fails, the discovery edit disturbed an adjacent autonomous-mode invariant — STOP and reconcile.

- [ ] **Step 7: Manual coherence read (no renumber, no new handoff)**

Confirm by eye:
- The lifecycle still has the same numbered stages (discovery is a sub-step/annotation, not a new numbered stage) in CLAUDE.md, leader.md, SKILL.md.
- The leader still makes exactly ONE architect dispatch to get the plan (discovery is inside it) — no leader→discovery-agent→leader round trip was introduced.
- Hub-and-spoke, Plan Approval, and Triple Crown prose are untouched.

- [ ] **Step 8: Final commit (if any verification fixes were applied)**

```bash
git add -A plugins/orbit-base/
git commit -m "chore(base): discovery-first step — final consistency + harness verification" || echo "nothing to commit"
```

---

## Success Criteria (measurable)

1. The "Discovery first" contract exists in `architect.md` (Core Responsibilities bullet + Task Sequence step 1), naming explore (internal) and researcher (external) as the fact-finders and the architect as synthesizer (Task 1 Step 4 → `Discovery first` count = 2, `explore` ≥ 2).
2. All 5 lifecycle-describing surfaces (architect.md, CLAUDE.md, leader.md, using-orbit/SKILL.md, orbit-cycle.md) contain the discovery step (Task 6 Step 3 → each non-zero).
3. **No new agent:** `agents/planner.md` does not exist; no file contains "planner"; no "8 roles"/"Eight roles" string exists; the single "7 roles" line in CLAUDE.md is unchanged (Task 6 Step 2).
4. **No duplication/drift, no false-green:** every Class B phase-summary/pointer surface (SKILL.md:8/145/153/158, codex manifest:28, codex-tools.md:32/76, gemini-tools.md:37/66) still reads as a 4-phase summary with no "discovery" token leaked into the invariant (Task 6 Step 3 leak guard → `leak-exit=1`, census lines unchanged).
5. Domain purity holds: `grep -riE 'oremi|orbit-dev' plugins/orbit-base/` → 0 hits (Task 6 Step 1, `exit=1`).
6. Both `plugin.json` manifests remain valid JSON (Task 6 Step 5).
7. The autonomous-mode harness passes after the change (Task 6 Step 6, `harness-exit=0`) — proving discovery added no loop node and no handoff.
8. Lifecycle stage *count* is unchanged (discovery is a sub-step/annotation), and the leader still makes one architect dispatch per plan — no new handoff (Task 6 Step 7).

## Test Strategy (Triple Crown mapping)

- **① Completeness:** Task 6 Steps 2-4 confirm every file in the touched-surface table received (or correctly did not receive) the discovery step; cross-check against the inventory table.
- **② Behavior:** there is no runtime; "behavior" = the grep set-diff gates (Task 6 Steps 1-4), JSON validity (Step 5), and the autonomous-mode harness re-run (Step 6). The harness is the closest thing to a behavioral test — it exercises the leader/lifecycle prose assumptions.
- **③ Quality:** architecture-consistency lens (architect) — frontmatter schema conformance on architect.md, domain-slot purity (slots preserved, no hardcoded domain), discovery contract coherence across the 5 surfaces, and the "no new role / no new handoff / no renumber" leanness checks (Task 6 Step 7); plus superpowers requesting-code-review for prose clarity.

## b2 vs. b3 — net value of editing 5 surfaces (for the Plan Approval choice)

The user should approve b2 *consciously over b3*, so the trade is stated plainly:

- **b3 (lightest):** add a "Discovery & Requirements" section requirement to the **plan document/template only** — 0 agent edits, ~1 surface, low-risk (no T2). The discipline rides on the *artifact* (each plan must open with framing/requirements/scope).
- **b2 (this plan):** name discovery in the **architect's role contract + the 5 step-enumerating lifecycle surfaces** — 5 edits, borderline T2.

**b2's net value over b3:** b3 only constrains the *output* (a plan can be rejected after the fact for missing a Discovery section). b2 constrains the *behavior* — it tells the architect, in its own role file, to *do discovery first and to delegate fact-finding to explore/researcher before drafting*, and it makes that step visible at every altitude an operator reads the lifecycle (CLAUDE.md, leader.md, SKILL.md, orbit-cycle.md). b3's template note is invisible at dispatch time and easy to satisfy with a perfunctory section; b2's contract is enforced at the point of action and checkable across surfaces. **b2 is worth its 5 surfaces only if the team values behavior-time enforcement over artifact-time enforcement.** If not — if a template section is judged sufficient — b3 is the honest, lighter choice and this plan should be deferred in its favor. The two are mutually exclusive starting points; b2 can later add b3's template section, but doing both at once would be redundant.

## Impact Scope

- **Files created:** 0.
- **Files modified:** 5 (`agents/architect.md`, `CLAUDE.md`, `agents/leader.md`, `skills/using-orbit/SKILL.md`, `commands/orbit-cycle.md`) — all Class A step enumerators.
- **Deliberately not edited (justified in inventory):** Class B phase summaries/pointers across 4 files (`SKILL.md:8/145/153/158`, `.codex-plugin/plugin.json:28`, `codex-tools.md:32/76`, `gemini-tools.md:37/66`) plus `.claude-plugin/plugin.json` (no lifecycle string). Verified to stay summary-level by Task 6 Step 3's leak guard.
- **Public-contract change:** the documented lifecycle gains an explicit discovery sub-step, but the **role set (7) is unchanged** and **no new handoff/gate** is added. This is a discipline annotation, not a structural contract change.
- **Out of scope (must not touch):** `.claude/`, `setup-orbit.sh`, root `README.md`. Note: `.codex-plugin/plugin.json:28` currently reads **"Seven roles (leader/architect/builder/explore/critic/reviewer/researcher)"** — it is correct and is NOT touched by this plan. (An earlier draft mistakenly referenced a "Five roles" string here; that string does not exist in the current file — corrected.)

## High-Risk 4-Trigger Self-Diagnosis

| Trigger | Verdict | Reasoning |
|---------|---------|-----------|
| **T1 Irreversibility** | NO | Pure prose additions; revert = git revert of 5 small edits. No migration, no rewrite, no backward-compat break. |
| **T2 Blast radius (≥3 components / public-interface change)** | **FIRES on surface count (5 files), but is a documentation discipline annotation — no role/gate/handoff/contract change.** | 5 files exceed the "3+ components" threshold by file count, so T2 technically fires. However, every edit is an append-only annotation of the *same* discovery discipline; no public role set changes (stays 7), no interface/gate/handoff changes. This is the "borderline T2" the spike predicted. |
| **T3 Security / data integrity** | NO | No auth, secrets, deletion, money, or PII paths touched. |
| **T4 New external dependency** | NO | No new runtime dep, service, or vendor. Discovery reuses existing explore/researcher spokes. |

**Self-diagnosis result: BORDERLINE — T2 fires on the 5-file surface count.** Per the leader's gate, the leader should treat this as **gate-eligible and run a short critic pass before Plan Approval** — cheap insurance because the lifecycle *contract prose* is touched, even though the change adds no role, gate, handoff, or renumber. This matches the spike's b2 prediction ("borderline T2 on surface count"). It is decisively lighter than the b1 path (which fired T2 on both ~13 surfaces AND a public roster-contract change). The leader makes the final gate call.

## Critic REVISE — resolution log (round 1)

- **MAJOR #1+#2 (verify-only misclassification + inventory gap):** resolved by a grep census run against the live files (Class B occurrences: SKILL.md:8/145/153/158, codex manifest:28, codex-tools.md:32/76, gemini-tools.md:37/66) and a Class A / Class B split. Class B is **left unedited with a per-surface recorded rationale** (discovery is a sub-step of the "plan" phase; promoting it to the 4-phase invariant would be wrong). Task 6 Step 3 now includes a **leak guard** so a missed Class A edit or a wrongly-edited Class B summary fails loudly (no false-green). Chose option (b) — justify non-inclusion — over (a) — edit them — because the 4-phase summary is a deliberate stable altitude.
- **MAJOR #3 (anti-tautology):** resolved in Task 1's new "Discovery vs. existing Read requirements" note — discovery is **codification of an implicit step**, not new capability; the value (named, checkable, skip-resistant under load) is stated transparently rather than dressed as machinery.
- **#6 (b2 vs. b3 net value):** added a dedicated section — b3 enforces at *artifact* time (template section), b2 enforces at *behavior* time (architect contract + 5 lifecycle surfaces). Stated so the user can consciously pick b2 over the lighter b3.
- **MINOR #4 (harness causal overclaim):** toned down — the harness proves **non-interference** with autonomous-mode invariants (orthogonal to discovery), not "discovery added no node." The no-node claim rests on Step 7 + the edit structure.
- **MINOR #5 (stale "Five roles"):** corrected — the codex manifest already reads "Seven roles"; the plan no longer claims a "Five roles" string exists.

## Self-Review

- **Spec coverage:** the brief's four "must solve" items plus the REVISE findings are all addressed — (1) touched-surface census + Class A/B split → inventory (5 modify, 5 justified-no-edit, claude manifest verify-only); (2) explore/researcher duplication-avoidance → Task 1 Steps 2-3, Task 6 Step 4; (3) leanness → `1a.` sub-step label / append-only inserts / Step 7 guard; (4) autonomous-mode interaction → Task 6 Step 6 non-interference regression. Verification covers domain purity, Class A/B set-diff with leak guard, harness C1–C15g, JSON validity.
- **Placeholder scan:** no TBD/TODO; every edit step shows verbatim before/after text.
- **Consistency:** "Discovery first" (architect.md) and the "discovery" node (other Class A surfaces) are used consistently; Task 6 grep targets match the strings written in Tasks 1-5; Class B census lines match the grep in the inventory.
