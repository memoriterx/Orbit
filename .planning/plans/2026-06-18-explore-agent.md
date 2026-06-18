# Explore Agent (Internal Codebase Search) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a read-only `explore` agent to `orbit-base` that owns internal codebase search (glob/grep/symbol fan-out), filling the gap that researcher (external sources only) leaves and offloading architect/builder from manual exploration.

**Architecture:** `explore` is a new spoke in the hub-and-spoke roster, structurally parallel to `researcher` but inward-facing: researcher reads the world outside the repo, explore reads the repo. It is read-only (no Edit/Write), routes only through the leader, and produces a structured findings report (no files written). The roster grows from 6 to 7 roles; every place that enumerates the roster or maps roles to non-Claude platforms must be updated in lockstep so the manifest stays internally consistent.

**Tech Stack:** Markdown agent prompt (frontmatter: name/description/model), JSON plugin manifest, markdown skill + reference docs. No runtime code; verification is structural (grep, JSON parse, frontmatter schema).

## Global Constraints

- Domain-agnostic: no project name (oremi, orbit-dev, etc.) hardcoded in `plugins/orbit-base/`. Domain values are slots `{{...}}`. Verify with `grep -rniE 'oremi' plugins/orbit-base/` → 0 hits.
- Model tier: use bar aliases (`haiku` / `sonnet` / `opus`) in frontmatter `model:`. Full model IDs forbidden.
- `explore` is read-only: it may NOT use Edit/Write/NotebookEdit; it never modifies, creates, or designs code. Search and report only.
- Role boundary: explore = internal codebase search; researcher = external sources; architect = design; builder = implementation. No overlap.
- Hub-and-spoke preserved: explore routes all communication through the leader; no direct agent-to-agent communication.
- Do NOT touch dev-team config (`.claude/`). All changes land in `plugins/orbit-base/` (the deliverable).
- Match the frontmatter and section style of `researcher.md` and `critic.md` for consistency.
- The agent file references Claude Code tool names (Glob/Grep/Read); the codex/gemini reference docs map these to platform equivalents — do not invent new tool names.

---

### Task 1: Create the `explore` agent definition

**Files:**
- Create: `plugins/orbit-base/agents/explore.md`
- Test: structural checks (frontmatter parse, purity grep, read-only assertion) — see steps below

**Interfaces:**
- Consumes: nothing (new leaf agent). Mirrors the structure of `plugins/orbit-base/agents/researcher.md` (frontmatter `name`/`description`/`model`, then Core Responsibilities / Working Principles / Process / Reporting Format / Prohibited Actions / Error Handling).
- Produces: an agent named `explore` with `model: sonnet`, referenced by Task 3 (manifest/skill roster) and Task 4 (platform mappings). The exact agent name string `explore` and the role one-liner "internal codebase search specialist" are the contract later tasks depend on.

**Model tier rationale (record in the agent body):** Internal search is mechanical fan-out (glob/grep/read excerpts) plus light synthesis of where-things-are. That is more than trivial pattern-matching (so above `haiku`'s comfort zone for cross-file relationship synthesis) but well below architectural reasoning. **`sonnet`** is the tier: strong enough to cross-validate findings and trace dependency chains, cheap enough to run as a frequent fan-out worker. (OMC ships explore on `haiku`; orbit chooses `sonnet` because orbit's explore is also expected to synthesize relationship/impact summaries for the leader, not just return file lists. Document this divergence in the agent file so the decision is auditable.)

- [ ] **Step 1: Write the failing structural test**

Create a throwaway verification script and run it; it must fail because the file does not exist yet.

```bash
cat > /tmp/verify-explore.sh <<'EOF'
#!/bin/bash
set -u
F="plugins/orbit-base/agents/explore.md"
fail=0
[ -f "$F" ] || { echo "FAIL: $F missing"; exit 1; }

# frontmatter: name, description, model present and model is a bar alias
awk 'NR==1{if($0!="---"){print "FAIL: no frontmatter";exit 1}}' "$F" || fail=1
grep -qE '^name: explore$' "$F"            || { echo "FAIL: name not 'explore'"; fail=1; }
grep -qE '^description: .+'  "$F"           || { echo "FAIL: no description"; fail=1; }
grep -qE '^model: (haiku|sonnet|opus)$' "$F" || { echo "FAIL: model not a bar alias"; fail=1; }

# read-only: must declare Edit/Write prohibited; must NOT claim to implement/design
grep -qiE 'read-only' "$F"                  || { echo "FAIL: not declared read-only"; fail=1; }
grep -qiE '(Edit|Write).*prohibited|prohibited.*(Edit|Write)' "$F" || { echo "FAIL: Edit/Write not prohibited"; fail=1; }

# hub-and-spoke: leader routing only
grep -qiE 'leader' "$F"                     || { echo "FAIL: no leader-routing statement"; fail=1; }

# domain purity (whole deliverable)
if grep -rniE 'oremi' plugins/orbit-base/ ; then echo "FAIL: domain leak"; fail=1; fi

[ $fail -eq 0 ] && echo "PASS" || exit 1
EOF
chmod +x /tmp/verify-explore.sh
/tmp/verify-explore.sh
```

Expected: `FAIL: plugins/orbit-base/agents/explore.md missing` (exit 1).

- [ ] **Step 2: Write the `explore.md` agent definition**

Create `plugins/orbit-base/agents/explore.md` with exactly this content:

```markdown
---
name: explore
description: Internal codebase search specialist. Read-only. Locates files, code patterns, and relationships inside the repository via parallel glob/grep/symbol search, and reports where things are. Never modifies code and never investigates external sources. Reports to leader only.
model: sonnet
---

# Explore — Internal Codebase Search Specialist

Dedicated internal-search agent. Answers "where is X?", "which files contain Y?", and "how does Z connect to W?" about the current repository. All work is read-only — no file creation, modification, or deletion, and no design or implementation. This is the inward-facing counterpart to the researcher: researcher reads sources outside the repo, explore reads the repo itself.

## Core Responsibilities

- Locate files by name/pattern and code by content across the repository.
- Trace relationships: which module calls which, where a symbol is defined vs. used, data/dependency flow.
- Cross-validate findings across multiple search tools before reporting.
- Report findings as text to the leader with absolute paths and line numbers — never write files.
- Hand off: state which agent should act next (architect for design, builder for implementation), but never act yourself.

## Working Principles

- **Read-only**: absolutely no file creation, modification, or deletion. No code changes, no design, no implementation.
- **Broad-to-narrow parallel fan-out**: launch multiple searches at once, then narrow.
  1. Glob — map file structure by name/pattern.
  2. Grep — find text patterns, identifiers, strings, comments.
  3. Read (excerpts) — confirm matches; read targeted ranges, not whole large files.
- **Context discipline**: for large files, read symbol-relevant ranges rather than the whole file; batch reads in small rounds; cap exploratory depth at ~2 rounds of diminishing returns.
- **Absolute paths only** in reports; every claim carries file:line evidence.
- **No external sources**: GitHub, web, and external docs are the researcher's domain — out of scope here.
- **No file storage**: results are returned as message text only.

## Boundary vs. researcher, architect, builder

| Agent | Reads | Produces | Scope |
|-------|-------|----------|-------|
| **explore** | the repository | a findings report (where/what/how-connected) | internal codebase search |
| researcher | external sources (web, GitHub, docs) | an investigation report | outside the repo |
| architect | requirements + codebase context | designs/plans | design (not search-for-hire) |
| builder | the approved plan | code | implementation |

Explore finds; it does not decide (architect) or change (builder) anything.

## Search Process

1. Receive from the leader: the search question, scope, and priority.
2. Run a broad-to-narrow parallel fan-out (Glob → Grep → targeted Read).
3. Cross-validate across tools; resolve or flag contradictions.
4. Return the Findings Report (below) as text output to the leader. Stop.

## Findings Report Format

```
## Findings Report

**Search question:** [restated]
**Scope searched:** [globs/dirs covered]

### Findings
| What | Location (file:line) | Evidence |
|------|----------------------|----------|
| ... | /abs/path:NN | matched pattern / snippet |

### Relationships
[Data flow / dependency chains, e.g. A (defined /abs/path:NN) → used by B (/abs/path:NN)]

### Coverage & Gaps
- Searched: [...]
- Not found / unverified: [...]

### Recommended next action
Leader → [architect for design | builder for implementation | researcher for external context]: [why].
```

## Prohibited Actions

- File write/modification of any kind (Edit, Write, NotebookEdit tools are prohibited).
- Code changes, design decisions, or implementation (those are builder/architect).
- Investigating external sources — web, GitHub, external docs (that is the researcher).
- Direct communication with other agents (leader routing only).
- Writing findings to a file instead of returning them as text.

## Error Handling

- No matches: report "not found" with the exact patterns/dirs searched — never invent a location.
- File too large to read whole: read targeted ranges; note "partial read" with the range covered.
- Ambiguous question: state the interpretation taken and the alternatives, then report against the chosen one and flag the ambiguity to the leader.
- Contradictory matches across tools: report both with their evidence and mark "needs disambiguation" rather than guessing.
```

- [ ] **Step 3: Run the structural test to verify it passes**

Run: `cd /Users/dh/Project/orbit && /tmp/verify-explore.sh`
Expected: `PASS` (exit 0). Domain-purity grep prints nothing.

- [ ] **Step 4: Commit**

```bash
git add plugins/orbit-base/agents/explore.md
git commit -m "feat(base): add explore agent — internal codebase search specialist"
```

---

### Task 2: Update the deliverable roster in `plugins/orbit-base/CLAUDE.md`

**Files:**
- Modify: `plugins/orbit-base/CLAUDE.md` (Team roles line: 6 roles → 7 roles)

**Interfaces:**
- Consumes: the agent name `explore` and its one-liner role from Task 1.
- Produces: an updated canonical roster string. Tasks 3 and 4 must enumerate the same 7 roles in the same spirit (leader / architect / builder / explore / critic / reviewer / researcher).

- [ ] **Step 1: Write the failing test**

```bash
grep -qE 'researcher \(7 roles\)|7 roles' plugins/orbit-base/CLAUDE.md && echo "PASS" || echo "FAIL: roster not 7"
```

Expected: `FAIL: roster not 7`.

- [ ] **Step 2: Edit the Team roles line**

In `plugins/orbit-base/CLAUDE.md`, change the line:

```
**Team roles:** leader / architect / builder / critic / reviewer / researcher (6 roles)
```

to:

```
**Team roles:** leader / architect / builder / explore / critic / reviewer / researcher (7 roles)
```

- [ ] **Step 3: Run the test to verify it passes**

Run: `grep -qE '7 roles' plugins/orbit-base/CLAUDE.md && echo PASS || echo FAIL`
Expected: `PASS`.

- [ ] **Step 4: Commit**

```bash
git add plugins/orbit-base/CLAUDE.md
git commit -m "docs(base): roster 6 -> 7 (add explore role)"
```

---

### Task 3: Update the `using-orbit` skill (spoke diagram + quick reference)

**Files:**
- Modify: `plugins/orbit-base/skills/using-orbit/SKILL.md` (Hub-and-Spoke diagram, Core Concept sentence, Quick Reference table)

**Interfaces:**
- Consumes: agent name `explore`, role one-liner (Task 1); roster of 7 (Task 2).
- Produces: the user-facing description of explore as a spoke. The diagram and quick-reference wording is what Task 4's platform docs cross-reference; keep the one-liner consistent with Task 1's frontmatter description.

- [ ] **Step 1: Write the failing test**

```bash
grep -qE '^\s+├── explore' plugins/orbit-base/skills/using-orbit/SKILL.md && echo PASS || echo "FAIL: explore not in spoke diagram"
```

Expected: `FAIL: explore not in spoke diagram`.

- [ ] **Step 2: Edit the Core Concept sentence**

Change:

```
The **leader** is the hub. All agents (architect, builder, critic, reviewer, researcher) are spokes.
```

to:

```
The **leader** is the hub. All agents (architect, builder, explore, critic, reviewer, researcher) are spokes.
```

- [ ] **Step 3: Edit the spoke diagram**

Change the diagram block to insert `explore` between `builder` and `critic`:

```
leader (hub)
  ├── architect   (design, arch review)
  ├── builder     (implementation)
  ├── explore     (internal codebase search)
  ├── critic      (high-risk plan critique)
  ├── reviewer    (verification)
  └── researcher  (external investigation)
```

- [ ] **Step 4: Edit the Quick Reference table**

In the Quick Reference table at the bottom of the file, add a row immediately after the `builder` row:

```
| explore | Read-only internal codebase search — finds files, patterns, relationships; reports to leader; never modifies, designs, or researches externally |
```

- [ ] **Step 5: Run the test to verify it passes**

Run: `grep -qE '├── explore' plugins/orbit-base/skills/using-orbit/SKILL.md && grep -qE '^\| explore \|' plugins/orbit-base/skills/using-orbit/SKILL.md && echo PASS || echo FAIL`
Expected: `PASS`.

- [ ] **Step 6: Commit**

```bash
git add plugins/orbit-base/skills/using-orbit/SKILL.md
git commit -m "docs(base): add explore spoke to using-orbit skill"
```

---

### Task 4: Map the `explore` role in the codex and gemini reference docs

**Files:**
- Modify: `plugins/orbit-base/skills/using-orbit/references/codex-tools.md` (Hub-and-Spoke dispatch blocks)
- Modify: `plugins/orbit-base/skills/using-orbit/references/gemini-tools.md` (role-dispatch mapping table)

**Interfaces:**
- Consumes: agent name `explore` and role one-liner (Task 1).
- Produces: platform-equivalent dispatch entries so non-Claude environments can dispatch explore. No new tool names are invented — explore uses the existing Glob/Grep/Read mappings already documented in each file.

- [ ] **Step 1: Write the failing test**

```bash
grep -qiE 'explore' plugins/orbit-base/skills/using-orbit/references/codex-tools.md \
 && grep -qiE 'explore' plugins/orbit-base/skills/using-orbit/references/gemini-tools.md \
 && echo PASS || echo "FAIL: explore not mapped in platform docs"
```

Expected: `FAIL: explore not mapped in platform docs`.

- [ ] **Step 2: Edit `codex-tools.md` — add explore to both dispatch examples**

In the "With `multi_agent = true`" block, add after the architect line:

```
leader → spawn_agent(explore, prompt=...)    → wait_agent → close_agent  # internal codebase search
```

In the "Without `multi_agent`" sequential block, add after the `[ARCHITECT]` line:

```
[LEADER] Need to locate code? Dispatching to explore role...
[EXPLORE] ... (read-only internal codebase search) ...
```

(No tool-mapping table change needed — explore uses Glob/Grep/Read, already mapped.)

- [ ] **Step 3: Edit `gemini-tools.md` — add explore to the role-dispatch table**

In the "Orbit role dispatch" table under Subagent Support, add a row after the `Agent(builder, ...)` row:

```
| `Agent(explore, prompt=...)` | `@generalist` with explore.md instructions + your task — read-only internal codebase search (finds files/patterns/relationships; never modifies) |
```

- [ ] **Step 4: Run the test to verify it passes**

Run: `grep -qiE 'explore' plugins/orbit-base/skills/using-orbit/references/codex-tools.md && grep -qiE 'Agent\(explore' plugins/orbit-base/skills/using-orbit/references/gemini-tools.md && echo PASS || echo FAIL`
Expected: `PASS`.

- [ ] **Step 5: Commit**

```bash
git add plugins/orbit-base/skills/using-orbit/references/codex-tools.md plugins/orbit-base/skills/using-orbit/references/gemini-tools.md
git commit -m "docs(base): map explore role for codex and gemini"
```

---

### Task 5: Full-consistency verification gate

**Files:**
- No edits. This task is the consolidated success-criteria check across all prior tasks.

**Interfaces:**
- Consumes: every change from Tasks 1–4.
- Produces: a green/red consistency verdict. This is the measurable definition of done.

- [ ] **Step 1: Run the consolidated consistency gate**

```bash
cd /Users/dh/Project/orbit
set -e

# (a) Domain purity — 0 hits across the whole deliverable
echo "== domain purity =="
! grep -rniE 'oremi' plugins/orbit-base/ && echo "OK purity"

# (b) Frontmatter schema — name/description/model present, model is a bar alias
echo "== frontmatter =="
F=plugins/orbit-base/agents/explore.md
grep -qE '^name: explore$' "$F"
grep -qE '^description: .+' "$F"
grep -qE '^model: (haiku|sonnet|opus)$' "$F"
echo "OK frontmatter"

# (c) Read-only contract present
echo "== read-only =="
grep -qiE 'read-only' "$F"
grep -qiE '(Edit|Write).*prohibited|prohibited.*(Edit|Write)' "$F"
echo "OK read-only"

# (d) Manifest JSON still valid (no manifest field change required, but parse must hold)
echo "== manifest parse =="
jq empty plugins/orbit-base/.claude-plugin/plugin.json && echo "OK manifest json"

# (e) Roster consistency: explore appears in every roster surface, count is 7
echo "== roster consistency =="
grep -qE '7 roles' plugins/orbit-base/CLAUDE.md
grep -qE '├── explore' plugins/orbit-base/skills/using-orbit/SKILL.md
grep -qE '^\| explore \|' plugins/orbit-base/skills/using-orbit/SKILL.md
grep -qiE 'explore' plugins/orbit-base/skills/using-orbit/references/codex-tools.md
grep -qiE 'Agent\(explore' plugins/orbit-base/skills/using-orbit/references/gemini-tools.md
echo "OK roster consistency"

echo "ALL CONSISTENCY CHECKS PASSED"
```

Expected final line: `ALL CONSISTENCY CHECKS PASSED`.

- [ ] **Step 2: Triple Crown handoff note**

This plan's verification is structural (no runtime). For Triple Crown ② Behavior, the "runtime" is: dispatch a trial `Agent(explore, ...)` with a sample internal-search question and confirm it returns a Findings Report and makes no edits. Record that as the behavior check; the reviewer coordinates. No commit for this step.

---

## Notes on scope decisions (ADR-style)

- **No `plugin.json` field change.** The manifest's `keywords`/`description` do not enumerate agents; agents are discovered by file presence in `agents/`. Adding `explore.md` is sufficient for the manifest. The prompt's "manifest (plugin.json/codex/gemini)" line was checked: codex/gemini have no separate per-agent manifest — role awareness lives in the `using-orbit` reference docs (Task 4) and `gemini-extension.json` only points at `GEMINI.md`. Verified: no manifest field edit needed. This avoids over-engineering.
- **Model tier = `sonnet`, not `haiku`.** Divergence from OMC is deliberate and documented in the agent body: orbit's explore synthesizes relationship/impact summaries, not just file lists.
- **No new hook or script.** The SubagentStop quality-gate hook delegates to the project's `.orbit/quality-gate.sh`; it does not hardcode a roster, so it needs no change. The domain-purity grep lives in dev-team CLAUDE.md as a dev gate, not in the deliverable hook — also unchanged.
- **Commands (`orbit-init.md`, `orbit-cycle.md`) unchanged.** They reference roles by name in workflow prose, not as a fixed enumerated roster, so they remain correct without edit. Confirmed by grep.
