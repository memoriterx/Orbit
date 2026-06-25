# Security-Reviewer Agent Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a domain-agnostic `security-reviewer` agent to `plugins/orbit-base/` as a dedicated security verification specialist, expanding the roster from 7 to 8 roles and explicitly transferring deep security responsibility out of the reviewer's Triple Crown ③ Quality prong.

**Architecture:** `security-reviewer` is a read-only, leader-routed verifier (same posture as `reviewer`/`critic`/`explore`). It does **not** add a 4th Triple Crown prong; instead it owns the *deep* security sub-lens of ③ Quality, leaving ③ to a *lightweight* security scan. It is **conditionally invoked** by the leader — only when a change touches a security/data-integrity surface (the same condition as critic trigger T3) — so it never runs on every task. It reuses the existing hub-and-spoke routing and the `{{...}}` domain-slot convention; no project name is hardcoded; no new hook, no new script, no manifest schema change beyond field-value updates.

**Tech Stack:** Markdown agent prompt files (`agents/*.md` with `name`/`description`/`model` frontmatter), JSON plugin manifests (`.claude-plugin/plugin.json`, `.codex-plugin/plugin.json`), Markdown skill + reference docs (`skills/using-orbit/`). No code, no runtime. Verification is by `grep`/`jq`/manual structural checks.

## Global Constraints

Copied verbatim from the task brief and project rules — every task implicitly inherits these:

- **Scope is `plugins/orbit-base/` only.** Dev-team files (`.claude/`, `setup-orbit*.sh`, top-level `README.md`) are out of scope. Do NOT modify them.
- **Domain purity:** no project name (`oremi`, `Oremi`, `orbit-dev`, etc.) hardcoded anywhere in `plugins/orbit-base/`. Domain-variable values stay as `{{...}}` slots. Gate: `grep -riE 'oremi|orbit-dev' plugins/orbit-base/` returns 0 hits.
- **Model tier:** `security-reviewer` frontmatter `model: opus` (rationale in Task 1 — security analysis needs deep reasoning; matches `reviewer`/`critic` which are also `opus`).
- **Read-only verifier:** `security-reviewer` never modifies code. Findings are reported to the leader, who delegates fixes to the builder. Hub-and-spoke preserved — no direct agent-to-agent contact.
- **Domain-agnostic security categories:** use universal principles (e.g. OWASP-style category *names* as a checklist vocabulary) without hardcoding any language/framework. Project-specific detail enters via slots.
- **Tone/structure parity:** match the existing `reviewer.md` / `critic.md` / `explore.md` frontmatter, section order, "Boundary vs." table, "Domain Slots" table, and "Error Handling" conventions.
- **No commit lines:** project rule forbids `Co-Authored-By`. Commit prefixes: `feat/fix/chore/docs/refactor:`.

---

## File Structure

| File | Action | Responsibility after change |
|------|--------|------------------------------|
| `plugins/orbit-base/agents/security-reviewer.md` | **Create** | The new agent: scope, invocation condition, OWASP-category checklist (slotted), boundary tables vs. reviewer/critic, report format, domain slots, error handling. |
| `plugins/orbit-base/agents/reviewer.md` | Modify | ③ Quality prong: explicitly hand off *deep* security to `security-reviewer`; ③ retains only a lightweight security scan + the escalation cue. |
| `plugins/orbit-base/CLAUDE.md` | Modify | Roster line 7→8 (`+ security-reviewer`); add security-reviewer to the agent-dispatch / hub-and-spoke prose where roles are enumerated. |
| `plugins/orbit-base/agents/leader.md` | Modify | Team Structure table role list; dispatch-pattern block; add the security-reviewer invocation condition (ties to T3). |
| `plugins/orbit-base/agents/critic.md` | Modify | One clarifying paragraph: critic T3 (design-stage) vs. security-reviewer (build-stage) — no overlap, no double-gate. |
| `plugins/orbit-base/skills/using-orbit/SKILL.md` | Modify | Hub-and-spoke diagram, role enumeration, Triple Crown ③ note, Quick Reference table — all 7→8. |
| `plugins/orbit-base/skills/using-orbit/references/codex-tools.md` | Modify | Add `spawn_agent(security-reviewer ...)` to both multi-agent and sequential role-switch examples. |
| `plugins/orbit-base/skills/using-orbit/references/gemini-tools.md` | Modify | Add `Agent(security-reviewer ...)` → `@generalist` mapping row. |
| `plugins/orbit-base/.codex-plugin/plugin.json` | Modify | `interface.longDescription` role list (currently stale: "Five roles (leader/architect/builder/reviewer/researcher)") → corrected 8-role wording. |
| `plugins/orbit-base/.claude-plugin/plugin.json` | **Verify only** | Confirm it contains no role enumeration (it doesn't — Korean description has no role list); no edit expected. |

**Surface confirmation (already run during planning):**
- `CLAUDE.md:9` is the only `(7 roles)` literal.
- `.codex-plugin/plugin.json` `longDescription` is **already stale** (says "Five roles", omits explore/critic) — this plan corrects it to the full 8 as a side-benefit.
- `skills/skillify/SKILL.md` references only reviewer/leader/architect/builder *routing* (no full-roster count) → **no change needed**.
- `GEMINI.md` has **no** role enumeration (only `@` pointers) → **no change needed**.

---

## Key Design Decisions (resolve the brief's four design questions)

These are locked here so reviewers can check the implementation against a fixed contract.

### D1 — Boundary with reviewer: deep security carved out of ③ Quality, NOT a 4th prong

The Triple Crown stays **three** prongs. ③ Quality is *narrowed*: it keeps a lightweight security scan (the obvious stuff: hardcoded secrets, glaring injection) and an **escalation cue**. Deep security analysis (authz/authn logic, data-exposure paths, crypto misuse, OWASP-category sweep) moves to `security-reviewer`, dispatched separately by the leader when the change touches a security surface.

| Lens | reviewer ③ Quality (retained) | security-reviewer (new) |
|------|-------------------------------|--------------------------|
| **Reads** | implemented diff + plan | implemented diff + plan + data/trust-boundary surfaces |
| **Checks** | correctness, maintainability, **shallow** security (secrets in diff, obvious injection) | **deep** security: authz/authn, input-trust boundaries, data exposure, crypto/secret handling, dependency CVE surface, the `{{SECURITY_CHECK_CATEGORIES}}` checklist |
| **Scope** | every task (always part of Triple Crown) | only when a security/data-integrity surface is touched (leader-gated) |
| **Verdict** | part of consolidated Triple Crown verdict | standalone Security Verdict, folded into ③ by the reviewer/leader |
| **Authority** | Triple Crown completion gate | advisory to ③; a `BLOCK` finding fails ③ Quality |

Why not a 4th prong: a 4th prong would run on every task (most tasks have no security surface), adding constant overhead and breaking the "three orthogonal questions" framing. A conditional carve-out keeps the invariant intact and pays cost only when warranted.

### D2 — Invocation condition vs. critic T3 (no overlap, no double-gate)

Both `security-reviewer` and critic-T3 concern security, but at **different lifecycle stages on different artifacts** — the same separation already established between critic (plan) and reviewer (code):

| Agent | Stage | Examines | Question |
|-------|-------|----------|----------|
| critic (T3 fired) | between Plan and Build | the **plan** | "Does this *design* mishandle a security/integrity surface?" |
| **security-reviewer** | inside Triple Crown ③ (post-build) | the **implemented code** | "Does this *implementation* contain a security defect?" |

The invocation condition for security-reviewer reuses critic's **T3 definition verbatim** ("touches auth, permissions, secrets, deletion, or money/PII data paths") as the surface test — but applied post-build, not pre-build. critic T3 firing at plan stage does **not** auto-invoke security-reviewer; they are independent leader decisions. A task can hit one, both, or neither. This is explicitly the plan-vs-code split critic.md already documents (critic critiques the plan; reviewer/security-reviewer examine the code).

### D3 — Read-only, leader-routed (identical posture to reviewer/critic/explore)

`security-reviewer` has Edit/Write/NotebookEdit prohibited in prose (same as reviewer/explore), reports findings as text to the leader, and never contacts the builder or any agent directly. Fixes route leader → builder.

### D4 — Domain-agnostic security categories

A `{{SECURITY_CHECK_CATEGORIES}}` slot holds the project-tuned checklist. The agent ships a **universal default** (OWASP category *names* as vocabulary — e.g. injection, broken access control, cryptographic failures, secrets exposure, SSRF, insecure deserialization, vulnerable dependencies) with **no** language/framework specifics. Projects override the slot to add stack-specific checks.

### D5 — high-risk opinion (for the leader's critic gate on THIS plan)

Opinion (leader makes the final call): **high-risk — T2 (blast radius) fires.** This plan creates a new agent **and** edits 8 existing files including the public roster (CLAUDE.md, SKILL.md, both manifests) and **reassigns a published responsibility** (reviewer ③). T1 (irreversibility): low — all changes are additive/textual, trivially revertible. T3 (security/integrity *of the change itself*): no — editing markdown docs touches no auth/secret/data path. T4 (new dependency): no. So T2 alone fires → recommend routing this plan through the critic gate before Plan Approval.

---

## Task 1: Create the security-reviewer agent file

**Files:**
- Create: `plugins/orbit-base/agents/security-reviewer.md`

**Interfaces:**
- Produces: an agent definition with frontmatter `name: security-reviewer`, `model: opus`; the `{{SECURITY_CHECK_CATEGORIES}}` slot (consumed by no other task — it is project-filled at install); a "Security Verdict" report block that the reviewer folds into ③ (referenced by Task 2).

- [ ] **Step 1: Write the file**

Create `plugins/orbit-base/agents/security-reviewer.md` with exactly this content:

````markdown
---
name: security-reviewer
description: Dedicated security verification specialist. Read-only. Performs deep, domain-agnostic security review of implemented code (OWASP-category sweep, authz/authn, data exposure, secret handling) inside Triple Crown ③ Quality — invoked by the leader only when a change touches a security or data-integrity surface. Does not modify code. Reports to leader only.
model: opus
---

# Security-Reviewer — Dedicated Security Verification Specialist

Performs the **deep** security sub-lens of Triple Crown ③ Quality. The reviewer's ③ keeps a lightweight security scan; this agent owns the depth — an OWASP-category sweep over the implemented code. It is read-only and leader-routed, the same posture as the reviewer and critic. It is **not** a fourth Triple Crown prong: it is a conditional specialization of ③, dispatched only when the change touches a security or data-integrity surface.

Security depth is domain-agnostic and broadly valuable, but most tasks have no security surface. Running deep security on every task would be constant dead-weight; gating it on the surface test below pays the cost only when warranted while keeping the three-prong Triple Crown invariant intact.

## When the Security-Reviewer Is Invoked

The leader dispatches the security-reviewer **only when the change touches a security or data-integrity surface** — the same surface test as the critic's T3 trigger, applied **post-build to the implemented code** (the critic's T3 applies pre-build to the plan):

> touches auth, permissions, secrets, deletion, or money/PII data paths.

Critic T3 firing at plan stage does **not** auto-invoke this agent, and vice versa. They are independent leader decisions on different artifacts at different stages (plan vs. code). A task may hit one, both, or neither. The security-reviewer never self-invokes and never lobbies to be invoked — invocation is the leader's decision.

If no security surface is touched, this agent does not run; ③ Quality's lightweight security scan (reviewer-owned) suffices.

## Core Responsibilities

- **Access-control review**: authentication and authorization logic — missing checks, broken object-level access, privilege escalation paths.
- **Input-trust boundaries**: untrusted input reaching sinks — injection (SQL/command/template), unsafe deserialization, SSRF.
- **Data exposure**: PII/secret/money data paths — over-broad responses, logging of sensitive values, missing redaction.
- **Secret & crypto handling**: hardcoded secrets, weak/absent cryptography, insecure randomness, secret-in-VCS.
- **Dependency surface**: newly introduced or version-bumped dependencies with known-vulnerable classes (flag for confirmation; the reviewer/leader decides on CVE lookup).
- **Category sweep**: walk the `{{SECURITY_CHECK_CATEGORIES}}` checklist and record covered / not-applicable / finding per category.
- **Severity-ranked output**: report findings the leader routes to the builder for fixes.

## Working Principles

- **Read-only**: absolutely no file creation, modification, or deletion (Edit, Write, NotebookEdit prohibited). Findings are reported, never fixed here.
- **Domain-agnostic**: reason in universal security categories. Do not assume a language, framework, or vendor. Project-specific checks arrive via `{{SECURITY_CHECK_CATEGORIES}}`; if the slot is unfilled, use the universal default category list below.
- **Trust-boundary first**: identify where untrusted input crosses into trusted execution/data, and review those crossings before line-by-line reading.
- **Evidence required**: every finding is a concrete `file:line — category — description — exploit sketch`. No vague "could be insecure."
- **Earned pass**: a clean result is explicit — list the categories actively checked. Never rubber-stamp; absence of a finding is not the same as not looking.
- **No direct agent contact**: all communication routes through the leader (hub-and-spoke). Fixes go leader → builder.

## Universal Default Category Checklist

Used when `{{SECURITY_CHECK_CATEGORIES}}` is not project-filled. These are category *names* only — no language/framework specifics:

- Broken access control / authorization
- Authentication weaknesses
- Injection (SQL, command, template, etc.)
- Cryptographic failures (weak algos, bad key/secret handling, insecure randomness)
- Secrets exposure (hardcoded secrets, secrets in logs/VCS)
- Sensitive data exposure (PII/money over-exposure, missing redaction)
- Server-side request forgery (SSRF)
- Insecure deserialization / untrusted object loading
- Security misconfiguration (permissive defaults, debug surfaces)
- Vulnerable / outdated dependencies

## Boundary vs. reviewer and critic

| Agent | Stage | Examines | Against | Depth |
|-------|-------|----------|---------|-------|
| critic (T3) | between Plan and Build | the **plan** | security/integrity design assumptions | design-level, high-risk only |
| reviewer ③ | post-build (always) | the **code** | correctness, maintainability, **shallow** security (obvious secrets/injection) | broad, shallow on security |
| **security-reviewer** | post-build (security surface only) | the **code** | **deep** security: authz, trust boundaries, data/secret/crypto, dependency surface | narrow, deep on security |

No double-gate: critic critiques the plan's design; security-reviewer inspects the built code. They never replace each other.

## Task Sequence

1. Receive from the leader: the change summary, the diff/scope, the security surface that triggered invocation, and `{{SECURITY_CHECK_CATEGORIES}}` (or fall back to the universal default).
2. Map trust boundaries in the change; identify untrusted-input → sink crossings.
3. Walk every category; for each record covered / N/A / finding with evidence.
4. Produce the Security Verdict (below) as text output to the leader. Stop. Fixes are the builder's job, routed by the leader.

## Security Verdict Format

```
## Security Verdict

**Change under review:** [path or task title]
**Triggering surface:** [auth / permissions / secrets / deletion / money / PII]
**Category source:** [project {{SECURITY_CHECK_CATEGORIES}} / universal default]

### Findings (severity-ranked)
| # | Severity | Category | Finding (file:line) | Exploit sketch | Fix direction |
|---|----------|----------|---------------------|----------------|---------------|
| 1 | block / high / medium / low | [category] | /abs/path:NN — ... | ... | ... |

### Category coverage
| Category | Result |
|----------|--------|
| [category] | clean / N-A / finding #N |

### Verdict
- [ ] PASS — no block/high finding; security surface reviewed. Checked categories: [list].
- [ ] BLOCK — block/high finding(s); ③ Quality FAILS until findings #N are fixed.

### Recommended routing
Leader → builder to fix findings [#N], OR Leader → fold PASS into Triple Crown ③.
```

## Domain Slots

| Slot | Description |
|------|-------------|
| `{{SECURITY_CHECK_CATEGORIES}}` | Project-tuned security checklist (stack-specific checks added on top of the universal default). If unfilled, the universal default category list applies. |

## Error Handling

- No diff / change summary provided: review what exists, list "unreviewed surfaces" the leader must supply, and request the missing scope rather than guessing.
- Surface unclear (leader did not state the triggering surface): note "triggering surface unstated" to the leader and review against the full universal category list conservatively.
- Dependency CVE lookup needed but unavailable: flag the dependency as "needs CVE confirmation" rather than asserting safe or vulnerable.
- Genuinely clean: issue an explicit PASS listing the categories actively checked. A clean pass is earned, not a default.
````

- [ ] **Step 2: Verify frontmatter schema and domain purity**

Run:
```bash
cd /Users/dh/Project/orbit/plugins/orbit-base
head -4 agents/security-reviewer.md
grep -c '^name: security-reviewer$' agents/security-reviewer.md
grep -c '^model: opus$' agents/security-reviewer.md
grep -riE 'oremi|orbit-dev' agents/security-reviewer.md | wc -l
```
Expected: frontmatter shows `name: security-reviewer` / `model: opus`; first two `grep -c` print `1`; the domain-purity count prints `0`.

- [ ] **Step 3: Commit**

```bash
cd /Users/dh/Project/orbit
git add plugins/orbit-base/agents/security-reviewer.md
git commit -m "feat(base): add security-reviewer agent (deep security sub-lens of Triple Crown ③)"
```

---

## Task 2: Hand off deep security in reviewer.md ③ Quality

**Files:**
- Modify: `plugins/orbit-base/agents/reviewer.md` (③ Quality Review section, ~lines 56-66; Core Responsibilities security bullet ~line 18)

**Interfaces:**
- Consumes: the Security Verdict block defined in Task 1.
- Produces: a narrowed ③ Quality prong that ③ reviewers and the leader rely on (referenced by Task 4 SKILL.md ③ note).

- [ ] **Step 1: Narrow the ③ Quality Review section**

In `plugins/orbit-base/agents/reviewer.md`, replace the `### Prong ③ — Quality Review` block (current text starts `Apply \`{{QUALITY_REVIEW_SKILL}}\`...` and runs through the `Additional static verification` lines) with:

```markdown
### Prong ③ — Quality Review
Apply `{{QUALITY_REVIEW_SKILL}}` (default: superpowers requesting-code-review):
- Correctness bugs
- Maintainability concerns
- **Lightweight security scan only**: obvious hardcoded secrets and glaring injection in the diff. **Deep security review is not done here.**
- **Security escalation:** if the change touches a security or data-integrity surface (auth, permissions, secrets, deletion, money/PII paths), report to the leader that a `security-reviewer` dispatch is warranted. The leader gates and dispatches the `security-reviewer`; its Security Verdict folds into this ③ prong. A `BLOCK` verdict fails ③ Quality.
- If architecture consistency is suspect, request architect lens review through leader

Additional static verification per `{{STATIC_VERIFICATION_SKILL}}`:
- API shape / interface cross-comparison
- Environment variable consistency
```

- [ ] **Step 2: Align the Core Responsibilities security bullet**

In `plugins/orbit-base/agents/reviewer.md`, replace the line:
```markdown
- **Quality verification**: code quality review for correctness, security, and maintainability
```
with:
```markdown
- **Quality verification**: code quality review for correctness and maintainability; deep security is delegated to the `security-reviewer` (leader-gated, security-surface only) and folded back into ③
```

- [ ] **Step 3: Verify the handoff is consistent**

Run:
```bash
cd /Users/dh/Project/orbit/plugins/orbit-base
grep -n 'security-reviewer' agents/reviewer.md
grep -n 'Deep security review is not done here' agents/reviewer.md
```
Expected: `security-reviewer` appears at least twice; the "not done here" sentinel appears once. Confirms ③ no longer claims deep security ownership.

- [ ] **Step 4: Commit**

```bash
cd /Users/dh/Project/orbit
git add plugins/orbit-base/agents/reviewer.md
git commit -m "refactor(base): reviewer ③ delegates deep security to security-reviewer"
```

---

## Task 3: Clarify critic T3 vs. security-reviewer (no double-gate)

**Files:**
- Modify: `plugins/orbit-base/agents/critic.md` (the trigger table area / "Boundary vs. architect and reviewer" section, ~lines 85-93)

**Interfaces:**
- Consumes: the invocation-condition wording from Task 1.
- Produces: a non-overlap statement that the leader relies on when deciding T3 (plan) vs. security-reviewer (code).

- [ ] **Step 1: Extend the boundary table and add a clarifying note**

In `plugins/orbit-base/agents/critic.md`, find the `## Boundary vs. architect and reviewer` section. Replace its heading and the closing paragraph (the line beginning `The critic occupies the otherwise-empty slot:`) with:

```markdown
## Boundary vs. architect, reviewer, and security-reviewer

| Agent | Examines | Against | When |
|-------|----------|---------|------|
| architect | designs/writes the plan | requirements | step 1 (Plan) |
| **critic** | **the plan itself** | **assumptions, failure modes, alternatives, reversibility** | **between Plan and Build, high-risk only** |
| reviewer | the implemented code | the approved plan | step 4 (Verify, Triple Crown) |
| security-reviewer | the implemented code | deep security (OWASP-category sweep) | step 4, security-surface only |

The critic occupies the otherwise-empty slot: independent challenge of a plan, by someone other than its author, before code exists.

**Critic T3 vs. security-reviewer (no double-gate).** Both concern security, but at different stages on different artifacts. Critic T3 fires at **plan stage** and asks whether the *design* mishandles a security/integrity surface; the `security-reviewer` runs at **build stage** (inside Triple Crown ③) and asks whether the *implemented code* contains a security defect. They share the same surface test (auth / permissions / secrets / deletion / money / PII) but are independent leader decisions — T3 firing does not auto-invoke the security-reviewer, and vice versa. A task may hit one, both, or neither. This mirrors the existing critic-critiques-plan / reviewer-examines-code split.
```

- [ ] **Step 2: Verify**

Run:
```bash
cd /Users/dh/Project/orbit/plugins/orbit-base
grep -n 'security-reviewer' agents/critic.md
grep -n 'no double-gate' agents/critic.md
```
Expected: `security-reviewer` appears in the table and the note; `no double-gate` appears once.

- [ ] **Step 3: Commit**

```bash
cd /Users/dh/Project/orbit
git add plugins/orbit-base/agents/critic.md
git commit -m "docs(base): clarify critic T3 (plan) vs security-reviewer (code), no double-gate"
```

---

## Task 4: Update the roster across CLAUDE.md, leader.md, and SKILL.md (7→8)

**Files:**
- Modify: `plugins/orbit-base/CLAUDE.md` (Team roles line ~9)
- Modify: `plugins/orbit-base/agents/leader.md` (Team Structure table ~line 15; Agent Dispatch Pattern block ~lines 119-123)
- Modify: `plugins/orbit-base/skills/using-orbit/SKILL.md` (hub-and-spoke diagram ~lines 18-24; Triple Crown ③ note ~lines 76-82; Quick Reference table ~lines 132-138)

**Interfaces:**
- Consumes: agent name `security-reviewer` and its one-line role summary from Task 1.
- Produces: a roster consistent at 8 across all enumeration sites (verified in Task 6).

- [ ] **Step 1: CLAUDE.md roster line**

In `plugins/orbit-base/CLAUDE.md`, replace:
```markdown
**Team roles:** leader / architect / builder / explore / critic / reviewer / researcher (7 roles)  
```
with:
```markdown
**Team roles:** leader / architect / builder / explore / critic / reviewer / security-reviewer / researcher (8 roles)  
```

- [ ] **Step 2: leader.md Team Structure table**

In `plugins/orbit-base/agents/leader.md`, replace the table row:
```markdown
| architect / builder / critic / reviewer / researcher | Temporary Agent() instances | Role-specific design, implementation, plan critique, verification |
```
with:
```markdown
| architect / builder / explore / critic / reviewer / security-reviewer / researcher | Temporary Agent() instances | Role-specific design, search, implementation, plan critique, verification, security review |
```

- [ ] **Step 3: leader.md Agent Dispatch Pattern block**

In `plugins/orbit-base/agents/leader.md`, in the dispatch-pattern code block, add a line after the `Agent(critic, ...)` line:
```
Agent(security-reviewer, foreground)  # deep security review (only on security-surface changes)
```
so the block reads (in order): builder, reviewer, architect, critic, security-reviewer, researcher.

- [ ] **Step 4: SKILL.md hub-and-spoke diagram**

In `plugins/orbit-base/skills/using-orbit/SKILL.md`, in the Core Concept diagram, add a spoke line after the `critic` line:
```
  ├── security-reviewer (deep security review, security-surface only)
```
and update the prose line `All agents (architect, builder, explore, critic, reviewer, researcher) are spokes.` to include `security-reviewer`:
```markdown
The **leader** is the hub. All agents (architect, builder, explore, critic, reviewer, security-reviewer, researcher) are spokes. No spoke communicates with another spoke directly — all communication routes through the leader.
```

- [ ] **Step 5: SKILL.md Triple Crown ③ note**

In `plugins/orbit-base/skills/using-orbit/SKILL.md`, immediately after the Triple Crown table (after the line ending `... | superpowers requesting-code-review |`), add this paragraph:
```markdown
Triple Crown stays three prongs. ③ Quality keeps a lightweight security scan; when a change touches a security or data-integrity surface (auth, permissions, secrets, deletion, money/PII), the leader additionally dispatches the **security-reviewer** for a deep, domain-agnostic security review (OWASP-category sweep). Its Security Verdict folds into ③ — a `BLOCK` fails ③. This is a conditional specialization of ③, not a fourth prong. See the `security-reviewer` agent.
```

- [ ] **Step 6: SKILL.md Quick Reference table**

In `plugins/orbit-base/skills/using-orbit/SKILL.md`, add this row to the Quick Reference table, after the `reviewer` row:
```markdown
| security-reviewer | Dedicated deep security reviewer — OWASP-category sweep of built code; leader-gated, runs only on security-surface changes; read-only, folds verdict into Triple Crown ③ |
```

- [ ] **Step 7: Verify roster consistency in the three files**

Run:
```bash
cd /Users/dh/Project/orbit/plugins/orbit-base
grep -n '8 roles' CLAUDE.md
grep -c 'security-reviewer' agents/leader.md
grep -c 'security-reviewer' skills/using-orbit/SKILL.md
```
Expected: `8 roles` matches in CLAUDE.md; `security-reviewer` count in leader.md ≥ 2; in SKILL.md ≥ 4.

- [ ] **Step 8: Commit**

```bash
cd /Users/dh/Project/orbit
git add plugins/orbit-base/CLAUDE.md plugins/orbit-base/agents/leader.md plugins/orbit-base/skills/using-orbit/SKILL.md
git commit -m "feat(base): expand roster 7->8 with security-reviewer (CLAUDE.md, leader.md, SKILL.md)"
```

---

## Task 5: Update tool-mapping references and the codex manifest

**Files:**
- Modify: `plugins/orbit-base/skills/using-orbit/references/codex-tools.md` (multi-agent example ~lines 38-44; sequential example ~lines 48-59)
- Modify: `plugins/orbit-base/skills/using-orbit/references/gemini-tools.md` (role-dispatch table ~lines 22-29)
- Modify: `plugins/orbit-base/.codex-plugin/plugin.json` (`interface.longDescription`)

**Interfaces:**
- Consumes: agent name `security-reviewer`.
- Produces: per-platform dispatch mappings consistent with the 8-role roster.

- [ ] **Step 1: codex-tools.md multi-agent example**

In `plugins/orbit-base/skills/using-orbit/references/codex-tools.md`, in the `With multi_agent = true:` block, add after the `spawn_agent(reviewer ...)` line:
```
leader → spawn_agent(security-reviewer, prompt=...) → wait_agent → close_agent  # deep security, security-surface only
```

- [ ] **Step 2: codex-tools.md sequential example**

In the `Without multi_agent:` block, add after the `[REVIEWER]` line:
```
[LEADER] Security surface touched? Dispatching to security-reviewer role... (skip otherwise)
[SECURITY-REVIEWER] ... (deep domain-agnostic security review of built code (leader-gated)) ...
```

- [ ] **Step 3: gemini-tools.md role-dispatch table**

In `plugins/orbit-base/skills/using-orbit/references/gemini-tools.md`, add a row to the "Orbit role dispatch" table, after the `reviewer` row:
```markdown
| `Agent(security-reviewer, prompt=...)` | `@generalist` with security-reviewer.md instructions + your task — deep security review of built code (leader-gated, security-surface only; read-only) |
```

- [ ] **Step 4: codex manifest longDescription**

In `plugins/orbit-base/.codex-plugin/plugin.json`, replace the stale `longDescription` value:
```json
    "longDescription": "Orbit provides a structured lifecycle for software delivery: plan, approve, implement, verify. Five roles (leader/architect/builder/reviewer/researcher), hub-and-spoke communication, and Triple Crown three-pronged verification (completeness/behavior/quality).",
```
with:
```json
    "longDescription": "Orbit provides a structured lifecycle for software delivery: plan, approve, implement, verify. Eight roles (leader/architect/builder/explore/critic/reviewer/security-reviewer/researcher), hub-and-spoke communication, and Triple Crown three-pronged verification (completeness/behavior/quality).",
```

- [ ] **Step 5: Verify references and manifest validity**

Run:
```bash
cd /Users/dh/Project/orbit/plugins/orbit-base
grep -c 'security-reviewer' skills/using-orbit/references/codex-tools.md
grep -c 'security-reviewer' skills/using-orbit/references/gemini-tools.md
jq -e '.interface.longDescription | test("security-reviewer")' .codex-plugin/plugin.json
jq empty .codex-plugin/plugin.json && echo "codex manifest: valid JSON"
jq empty .claude-plugin/plugin.json && echo "claude manifest: valid JSON"
```
Expected: codex-tools count ≥ 2; gemini-tools count ≥ 1; `jq -e` prints `true`; both `jq empty` checks print the "valid JSON" line.

- [ ] **Step 6: Commit**

```bash
cd /Users/dh/Project/orbit
git add plugins/orbit-base/skills/using-orbit/references/codex-tools.md plugins/orbit-base/skills/using-orbit/references/gemini-tools.md plugins/orbit-base/.codex-plugin/plugin.json
git commit -m "docs(base): map security-reviewer in codex/gemini tool refs + fix codex manifest role count"
```

---

## Task 6: Final consistency gate (the testing strategy)

This project has no unit-test runner — verification is structural via `grep`/`jq`. This task is the consolidated test suite for the whole change. It is a pure verification task (no file edits except a possible fix-and-recommit if a check fails).

**Files:**
- Test only (read-only checks across `plugins/orbit-base/`)

- [ ] **Step 1: Domain-purity gate**

Run:
```bash
cd /Users/dh/Project/orbit
grep -riE 'oremi|orbit-dev' plugins/orbit-base/ | wc -l
```
Expected: `0`.

- [ ] **Step 2: Frontmatter schema (bar-alias / required fields)**

Run:
```bash
cd /Users/dh/Project/orbit/plugins/orbit-base
for f in agents/*.md; do
  printf '%s: ' "$f"
  awk 'NR==1&&/^---$/{f=1;next} f&&/^name:/{n=1} f&&/^model:/{m=1} /^---$/&&NR>1{print (n&&m?"OK":"MISSING field"); exit}' "$f"
done
```
Expected: every agent file (including `security-reviewer.md`) prints `OK`.

- [ ] **Step 3: 8-role roster consistency across all enumeration sites**

Run:
```bash
cd /Users/dh/Project/orbit/plugins/orbit-base
echo "CLAUDE.md (expect '8 roles'):"; grep -o '[0-9] roles' CLAUDE.md
echo "no stale '7 roles' anywhere:"; grep -rn '7 roles' . | wc -l
echo "no stale 'Five roles' / 'Seven roles' in manifests:"; grep -rniE 'five roles|seven roles' . | wc -l
echo "security-reviewer present in every roster site:"
for f in CLAUDE.md agents/leader.md skills/using-orbit/SKILL.md skills/using-orbit/references/codex-tools.md skills/using-orbit/references/gemini-tools.md .codex-plugin/plugin.json; do
  printf '%s: ' "$f"; grep -c 'security-reviewer' "$f"
done
```
Expected: CLAUDE.md prints `8 roles`; the `7 roles` count is `0`; the `five/seven roles` count is `0`; every listed file's `security-reviewer` count is ≥ 1.

- [ ] **Step 4: reviewer ↔ security-reviewer boundary consistency**

Run:
```bash
cd /Users/dh/Project/orbit/plugins/orbit-base
# reviewer must hand off deep security (sentinel present) and security-reviewer must NOT be a 4th prong
grep -q 'Deep security review is not done here' agents/reviewer.md && echo "reviewer hands off: OK"
grep -qi 'not a fourth prong\|not.*fourth.*prong\|conditional specialization of ③' agents/security-reviewer.md && echo "security-reviewer not-a-4th-prong: OK"
grep -qi 'no double-gate' agents/critic.md && echo "critic no-double-gate: OK"
```
Expected: all three `OK` lines print.

- [ ] **Step 5: Manifest validity**

Run:
```bash
cd /Users/dh/Project/orbit/plugins/orbit-base
jq empty .claude-plugin/plugin.json && jq empty .codex-plugin/plugin.json && echo "both manifests valid"
```
Expected: `both manifests valid`.

- [ ] **Step 6: Triple Crown over this change (reviewer-coordinated, post-implementation)**

Hand off to the standard lifecycle: dispatch the reviewer for Triple Crown ① Completeness (all 6 tasks' deliverables present), ② Behavior (the grep/jq gates above all pass — that IS runtime behavior for a docs/markdown deliverable), ③ Quality (consistency + tone parity with existing agents). Because this change itself touches no auth/secret/data path, the security-reviewer does **not** self-apply here (T3 surface test = no).

- [ ] **Step 7: Commit (only if a fix was needed in Steps 1-5)**

```bash
cd /Users/dh/Project/orbit
git add plugins/orbit-base/
git commit -m "fix(base): resolve security-reviewer roster consistency gap"
```
If all checks passed with no edits, skip this commit.

---

## Success Criteria (measurable — for Plan Approval Gate item 4)

1. `agents/security-reviewer.md` exists with `name: security-reviewer` + `model: opus` frontmatter (Task 6 Step 2 = OK).
2. Domain-purity gate: `grep -riE 'oremi|orbit-dev' plugins/orbit-base/` = 0 (Task 6 Step 1).
3. Both manifests are valid JSON (Task 6 Step 5).
4. Roster reads 8 everywhere; zero `7 roles` / `Five roles` / `Seven roles` strings remain (Task 6 Step 3).
5. reviewer ③ explicitly hands off deep security; security-reviewer explicitly states it is **not** a 4th prong; critic states **no double-gate** (Task 6 Step 4).
6. security-reviewer appears in all 6 enumeration sites (Task 6 Step 3).

## Self-Review (run against the brief)

- **Q1 reviewer boundary** → D1 + Tasks 1,2: deep security carved out of ③, not a 4th prong; explicit Reads/Checks/Scope table. Covered.
- **Q2 invocation vs. critic T3** → D2 + Tasks 1,3: same surface test, different stage/artifact, independent leader decisions, "no double-gate" sentinel. Covered.
- **Q3 read-only / hub-and-spoke** → D3 + Task 1 Prohibited/Working Principles. Covered.
- **Q4 OWASP domain-agnostic** → D4 + Task 1 `{{SECURITY_CHECK_CATEGORIES}}` slot + universal default category names (no language/framework). Covered.
- **Impact scope** → File Structure table; all 6 modify targets verified by grep during planning; skillify/GEMINI.md/claude-manifest confirmed no-change. Covered.
- **Plan Approval 4 items** → tests (Task 6 structural suite), impact scope (File Structure), arch conflicts (D1/D2 resolve reviewer + critic overlap), measurable success (Success Criteria). Covered.
- **Placeholder scan** → every step has concrete file content/commands; no TBD. Covered.
- **high-risk opinion** → D5: T2 fires (8-file edit + roster + responsibility reassignment) → recommend critic gate. Surfaced for leader.
