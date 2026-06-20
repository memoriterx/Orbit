# Internal Consistency Drift Remediation Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Close three internal-consistency drifts in orbit — one deployment-product surface gap (DRIFT-1) and two dogfooding dev-team drifts (DRIFT-2 parity, DRIFT-3 path portability) — without bloating dev config or breaking domain purity.

**Architecture:** Three independent remediations grouped by ownership boundary. DRIFT-1 touches the deployment product (`plugins/orbit-base/`) and follows the full lifecycle. DRIFT-2 and DRIFT-3 touch only dev-team config (`.claude/`, `_team/`) and are meta changes. The unifying principle is **single source of truth**: the canonical deployment surfaces (CLAUDE.md, deployment hooks) already hold the correct content; remediation aligns the divergent surfaces to them rather than re-authoring content.

**Tech Stack:** Markdown agent prompts, JSON settings, Python hook scripts, Bash team scripts. No build system — verification is grep/diff/`python3 -m json.tool`/`bash -n`.

## Global Constraints

- **Domain purity:** `plugins/orbit-base/` files must contain zero project-specific names (oremi, orbit-dev, etc.). Verify after DRIFT-1: `grep -rn 'oremi\|Oremi\|orbit-dev' plugins/orbit-base/` must return 0 hits (excluding the SubagentStop gate's own grep string if present). DRIFT-1 edits use domain-agnostic English/`.orbit/` paths only.
- **Commit separation:** Deployment-product changes (DRIFT-1) and dev-environment changes (DRIFT-2, DRIFT-3) ship in **separate commits**. DRIFT-1 = one commit on `plugins/orbit-base/`. DRIFT-2 = one commit on `.claude/agents/`. DRIFT-3 = one commit on `.claude/settings.json` + `_team/`. Never mix product and dev paths in one commit.
- **Commit message prefix:** `fix:` or `docs:` per CLAUDE.md rule. No `Co-Authored-By` line.
- **Lead does not implement:** This plan is executed by the builder after Plan Approval. The architect wrote it; the lead presents it.
- **orbit-cycle uses `.orbit/`, not `.planning/`:** The deployment command references `.orbit/` (the end-user state dir). Dev-team config references `.planning/`. Do not cross these.

---

## Discovery Summary (findings that shaped this plan)

**DRIFT-1 (confirmed by lead):** `plugins/orbit-base/commands/orbit-cycle.md` lifecycle diagram (lines 13-36) jumps `writing-plans → Plan Approval` with no high-risk critic gate step. Step 2 (lines 58-78) ends at "plan arrives → go to Step 3 (Plan Approval)" with no gate. The canonical surfaces — `plugins/orbit-base/CLAUDE.md` lines 22 + 60-83 and `plugins/orbit-base/skills/using-orbit/SKILL.md` — both document the critic gate. orbit-cycle.md is the only deployment surface missing it. Fix = insert the gate step into the diagram and a new Step between current Step 2 and Step 3, sourced verbatim-in-spirit from the canonical CLAUDE.md gate table.

**DRIFT-2 (recommendation: core-only, NOT full mirror):** The dev team `.claude/` is one dogfooding instance, not the shipped product. Two gaps are genuinely load-bearing for how the dev team runs every task and must be reflected:
- (a) `.claude/agents/leader.md` lifecycle diagram (lines 48-59) has no Discovery-first step; the deployment leader.md line 52 has it.
- (b) `.claude/agents/architect.md` "작업 순서" (lines 39-50) has no Discovery-first prefix step.

The Autonomous Loop / skip-and-park / fan-out sections (deployment leader.md lines 88-134) are **deliberately NOT mirrored**: the dev team does not run autonomous batches or fan-out builds today; copying ~90 lines of governance for an uninvoked mode would bloat dev config and create a second drift surface to maintain. Instead, add a single pointer line in `.claude/agents/leader.md` directing to the canonical deployment leader.md for autonomous/fan-out mechanics. Rationale: "missing is documentation, not role" — same pattern as the OMC-6 resolution in project memory.

**DRIFT-3 (REVISED after critic gate — verdict: keep dev forks, fix paths in place; do NOT repoint to deployment scripts).**

The original "deployment hooks are a strict superset" decision was **wrong** and a critic high-risk gate (T3 fired) blocked it with two confirmed BLOCKERs:

- **BLOCKER #1 — not a superset; a behavioral regression.** Deployment `resume-inject.py:14` sets `ROADMAP = ${CLAUDE_PROJECT_DIR}/.orbit/roadmap.md` and injects it into the resume prompt. But the dev team's real, active roadmap is `.planning/roadmap.md` (15 KB, live) — **`.orbit/roadmap.md` does not exist** (`ls .orbit/` → No such file). The dev fork injects `.planning/roadmap.md`. The logic body is byte-identical, but the **roadmap target path differs**. Repointing would make unattended post-usage-reset resume point at a nonexistent roadmap. *(Verified: `ls -la .planning/roadmap.md .orbit/roadmap.md` → `.orbit/roadmap.md` absent.)*

- **BLOCKER #2 — state-location move splits state, the opposite of single-source.** The dev team has no `.orbit/` dir, and `.gitignore:3` ignores `.orbit/` wholesale. Dev `.planning/usage-detect.log` is live (28 KB accumulated). Critically, `.claude/settings.json`'s **Stop hook (line 8) and MessageDisplay hook (line 30) — which this task does NOT touch — still write `.planning/`**. Repointing only the two Python hooks to `.orbit/` would split the same usage signal across two directories: state fragmentation, not single source. *(Verified: `.orbit/` absent, `.gitignore` line 3, `.planning/usage-detect.log` 28 KB present.)*

**Alternative evaluation (critic #5 + others):**
- **Rejected — `ORBIT_STATE_DIR` parameterization of the deployment script.** This would resolve #1/#2 at the source, but editing `plugins/orbit-base/hooks/*.py` makes DRIFT-3 a **deployment-product change**: separate commit, domain-purity gate, full lifecycle, and a changed T2/T4 risk profile. Out of scope for a portability fix; the coordinator explicitly flagged this scope-creep. DRIFT-3 must stay meta.
- **Rejected — `.orbit/roadmap.md` symlink.** Fragile, gitignored (would not be tracked), introduces a phantom path that masks the real divergence. No.
- **CHOSEN — option (b): keep the dev forks, edit them in place.** Replace the hardcoded `/Users/dh/Project/orbit/.planning` absolute path with `${CLAUDE_PROJECT_DIR:-os.getcwd()}/.planning` (and the roadmap reference stays `.planning/roadmap.md`). This fixes the **actual** portability defect (the absolute path), keeps state in `.planning/` (no fragmentation, no `.orbit/` creation), keeps the resume prompt pointing at the real active roadmap, and touches **zero** deployment files. The `.claude/settings.json` hook commands drop their absolute prefix the same way (`${CLAUDE_PROJECT_DIR:-$PWD}/.planning/...`).

The `_team/*.sh` scripts (critic judged Task 5 sound — unchanged) are genuinely dev-only (tmux `orbit-dev` viewer infra, no deployment counterpart) but hardcode absolute paths; fixed with `SCRIPT_DIR`/`$HOME`-independent derivation. Critic MINOR #6 (add a comment that `SCRIPT_DIR` assumes direct execution) is folded into Task 5.

**`CLAUDE_PROJECT_DIR` reliability (critic #3, #4):** Because we are now editing scripts (not deleting), the fallback `${CLAUDE_PROJECT_DIR:-$PWD}` / `os.environ.get('CLAUDE_PROJECT_DIR', os.getcwd())` makes the fix robust even if the env var is unset in an `async` hook context — it degrades to cwd, which for dev hooks is the project root. Verification now exercises the **actual hook-firing path** (echo a payload through the rewritten settings.json command via `bash -c`), not a hand-exported `CLAUDE_PROJECT_DIR` shortcut, and includes a rollback note.

---

## Four-Trigger High-Risk Self-Assessment (input for lead's critic gate decision)

The lead applies the four-trigger OR gate per DRIFT before Plan Approval. Self-assessment:

| DRIFT | T1 Irreversibility | T2 Blast radius (3+ comp / public contract) | T3 Security / integrity | T4 New external dep | Verdict |
|-------|--------------------|---------------------------------------------|-------------------------|----------------------|---------|
| **DRIFT-1** | No — prose insertion into one md file, git-revertible | No — 1 file (`orbit-cycle.md`); aligns to existing contract, changes none | No — no auth/secrets/deletion; documentation only | No | **Low-risk** — all-no |
| **DRIFT-2** | No — prose in 2 dev md files, revertible | No — 2 files, dev-only, no public/product contract | No — documentation only | No | **Low-risk** — all-no |
| **DRIFT-3 (REVISED — option b)** | **No** — in-place path edits to 2 dev forks + 2 settings.json command strings + 4 `_team` scripts; all git-revertible, **no deletions, no file moves, no state-location change** | **Reduced** — touches `settings.json` (2 hook command strings, not 4) + 2 edited (not deleted) dev forks + 4 `_team/*.sh`; all in `.claude/`+`.planning/`+`_team/`, no public/product contract, no deployment file | **Still touches auto-exec hook surface** — editing the command string of Notification/UserPromptSubmit hooks changes what auto-runs; but the change is **path-only** with a cwd fallback, no logic/state-location change, and keeps the real roadmap target | No — no new dependency; deployment scripts untouched | **Lower-risk than original; T3 still nominally fires** (auto-exec hook command edited) — re-gate recommended but BLOCKERs resolved |

**Recommendation to lead (REVISED):** DRIFT-1 and DRIFT-2 remain manifestly all-no → critic may be skipped. **DRIFT-3 still touches the auto-exec hook surface (T3)**, but the two BLOCKERs that drove the prior REVISE are now resolved by option (b): no `.orbit/` move (state stays in `.planning/`, no fragmentation with the untouched Stop/MessageDisplay hooks), no roadmap-target regression (resume still points at the live `.planning/roadmap.md`), no deployment-file edit (DRIFT-3 stays meta). T2 dropped (no deletions/moves; fewer settings.json edits). **Recommend the lead re-gate the revised DRIFT-3 with critic** (T3 nominally fires on any auto-exec hook command edit), but the plan now carries the BLOCKER resolutions and a faithful hook-path smoke test, so a PROCEED is expected. If the lead judges a path-only edit with cwd fallback as manifestly integrity-neutral, critic may be skipped at the lead's discretion — the call is the lead's.

---

## Impact Scope

- **DRIFT-1:** `plugins/orbit-base/commands/orbit-cycle.md` only. No code, no other surface. End-user-visible (shipped command).
- **DRIFT-2:** `.claude/agents/leader.md`, `.claude/agents/architect.md`. Dev-team only. Not shipped.
- **DRIFT-3 (REVISED):** `.claude/settings.json` (2 hook command strings), **edit** (not delete) `.planning/usage-detect.py` + `.planning/resume-inject.py` (path-only), edit `_team/notify.sh` + `_team/notify-done.sh` + `_team/auto-attach.sh` + `_team/attach-view.sh`. Dev-team only. **No deployment file touched. No `.orbit/` created. State stays in `.planning/`.** Changes auto-exec hook command path only (cwd fallback retained).

---

## File Structure

| File | DRIFT | Action | Responsibility after change |
|------|-------|--------|------------------------------|
| `plugins/orbit-base/commands/orbit-cycle.md` | 1 | Modify | Lifecycle guide now includes critic high-risk gate (diagram + Step) |
| `.claude/agents/leader.md` | 2 | Modify | Dev leader diagram shows Discovery-first; pointer to canonical autonomous/fan-out |
| `.claude/agents/architect.md` | 2 | Modify | Dev architect work-order starts with Discovery |
| `.claude/settings.json` | 3 | Modify | Notification + UserPromptSubmit hook commands use `${CLAUDE_PROJECT_DIR:-$PWD}`-relative dev-fork paths (no absolute `/Users/dh/...`) |
| `.planning/usage-detect.py` | 3 | **Retain + edit** | Dev fork — `.planning/`-relative state path derived from `CLAUDE_PROJECT_DIR` (was hardcoded absolute) |
| `.planning/resume-inject.py` | 3 | **Retain + edit** | Dev fork — `.planning/`-relative state + roadmap path (preserves correct `.planning/roadmap.md` resume target) |
| `_team/notify.sh` | 3 | Modify | Portable path via `$HOME`-independent derivation |
| `_team/notify-done.sh` | 3 | Modify | Portable `$NOTIFY` path |
| `_team/auto-attach.sh` | 3 | Modify | Portable `$PROJ` derivation |
| `_team/attach-view.sh` | 3 | Modify | Portable `$RUNNER`/`$PROJDIR` derivation |

---

# AREA A — DRIFT-1 (Deployment Product)

### Task 1: Insert critic high-risk gate into orbit-cycle.md

**Files:**
- Modify: `plugins/orbit-base/commands/orbit-cycle.md:13-36` (diagram) and insert a new section between `:78` and `:80`
- Test: grep-based assertion (no code test framework; this is a markdown surface)

**Interfaces:**
- Consumes: the canonical gate definition already in `plugins/orbit-base/CLAUDE.md:60-83` (four-trigger table) and the lifecycle line `CLAUDE.md:22`.
- Produces: an orbit-cycle.md whose lifecycle matches the canonical surface. No other task depends on this.

- [ ] **Step 1: Write the failing test (grep assertion)**

Confirm the gap exists before fixing. Run:

```bash
cd /Users/dh/Project/orbit
grep -c 'critic' plugins/orbit-base/commands/orbit-cycle.md
```

Expected: `0` (the word "critic" / high-risk gate is absent — this is the drift). If it returns >0, re-read the file; the drift may already be partially fixed.

- [ ] **Step 2: Edit the lifecycle diagram (lines 13-36)**

Insert the high-risk gate step between `writing-plans` and `Plan Approval`. Replace the diagram block so the relevant middle reads (keep surrounding lines intact, domain-agnostic, `.orbit/` paths):

```
writing-plans  (architect — 플랜 작성)
    │
    ▼
고위험 게이트  (리드 — 4트리거 OR 게이트 적용)
    ├── 고위험 → critic 독립 비판 → architect 수정 → (재게이트)
    └── 저위험 → critic 생략
    │
    ▼
Plan Approval  (사용자 승인)  ← 승인 없이 구현 금지
```

- [ ] **Step 3: Insert a new "Step 2.5" section between current Step 2 and Step 3**

After line 78 (end of Step 2, before the `---` preceding Step 3), insert:

```markdown
---

## Step 2.5: 고위험 결정 게이트 (critic 분기)

architect가 플랜을 반환한 뒤 **Plan Approval 전**, 리드는 4트리거 OR 게이트를 플랜에 적용한다. 하나라도 발화하면 **critic**을 `Agent()`로 파견해 독립 비판(PROCEED/REVISE)을 받는다. 모두 해당 없으면 critic을 생략한다(저위험 오버헤드 0).

| 트리거 | 고위험 조건 |
|--------|------------|
| T1 비가역성 | 되돌리려면 데이터 마이그레이션·재작성·하위 호환성 파괴가 필요한가? |
| T2 광범위 영향 | 3개 이상 컴포넌트/모듈에 닿거나, 공개 인터페이스·계약을 변경하는가? |
| T3 보안·무결성 | 인증·권한·시크릿·삭제·금전/PII 경로에 닿는가? |
| T4 신규 외부 의존성 | 신규 런타임 의존성·외부 서비스·벤더 종속을 도입하는가? |

REVISE 판정 시 리드는 발견 사항을 architect에게 전달해 플랜을 수정하고 재게이트한다. PROCEED면 Step 3으로 진행한다. critic은 self-invoke 불가, architect와 직접 통신 불가(허브앤스포크) — 게이트 권한은 리드에게만 있다.
```

- [ ] **Step 4: Run the verification (grep now passes + domain purity + json/bash gate)**

Run:

```bash
cd /Users/dh/Project/orbit
grep -c 'critic' plugins/orbit-base/commands/orbit-cycle.md          # expect >= 3
grep -c '고위험 게이트' plugins/orbit-base/commands/orbit-cycle.md    # expect >= 1
grep -rn 'oremi\|Oremi\|orbit-dev' plugins/orbit-base/commands/orbit-cycle.md  # expect 0 (domain purity)
```

Expected: critic count ≥ 3, 고위험 게이트 ≥ 1, domain-purity grep returns nothing.

- [ ] **Step 5: Cross-surface consistency check**

Confirm the inserted gate matches the canonical four triggers in CLAUDE.md:

```bash
cd /Users/dh/Project/orbit
diff <(grep -oE 'T[1-4] [가-힣]+' plugins/orbit-base/commands/orbit-cycle.md | sort -u) \
     <(grep -oE 'T[1-4] [가-힣]+' plugins/orbit-base/CLAUDE.md 2>/dev/null | sort -u) || true
```

Expected: the four trigger labels (T1 비가역성 / T2 광범위 영향 / T3 보안·무결성 / T4 신규 외부 의존성) appear in both. Manually confirm the orbit-cycle gate names match CLAUDE.md's gate semantics.

- [ ] **Step 6: Commit (deployment product — isolated commit)**

```bash
cd /Users/dh/Project/orbit
git add plugins/orbit-base/commands/orbit-cycle.md
git commit -m "fix(base): add high-risk critic gate to orbit-cycle lifecycle"
```

---

# AREA B — DRIFT-2 (Dev-Team Agent Parity, core-only)

### Task 2: Add Discovery-first to dev leader.md diagram + autonomous pointer

**Files:**
- Modify: `.claude/agents/leader.md:48-59` (workflow diagram), and append one pointer line after the diagram block

**Interfaces:**
- Consumes: the deployment leader.md `:52` Discovery-first phrasing and `:88-134` autonomous/fan-out sections as the canonical reference (do not copy the latter — point to it).
- Produces: dev leader.md whose lifecycle diagram includes Discovery-first. Task 3 (architect) is parallel-independent.

- [ ] **Step 1: Write the failing test (grep assertion)**

```bash
cd /Users/dh/Project/orbit
grep -c 'discovery\|Discovery\|디스커버리\|문제 프레이밍' .claude/agents/leader.md
```

Expected: `0` (Discovery-first is absent from the dev leader). If >0, re-read; drift may be partially fixed.

- [ ] **Step 2: Edit the workflow diagram (lines 48-59)**

Replace the first diagram step so the top reads (insert the discovery line before the existing `architect 파견` line):

```
roadmap 선택
→ 리드가 architect 파견: discovery 먼저 (문제 프레이밍·요구사항·스코프·우선순위; explore/researcher 활용) → writing-plans → architect가 플랜 작성
→ 고위험 게이트: 리드가 4트리거 OR 게이트 적용
   ├─ 고위험 → critic 파견 → 비판 보고서 → architect 수정 → (재게이트)
   └─ 저위험 → critic 생략
→ Plan Approval: 리드가 플랜 제시 → 사용자 확인
→ 리드가 builder 파견 (TDD, 구현)
→ 사후 Triple Crown
  ① 완성도: GSD    ② 동작: gstack    ③ 품질: superpowers review
→ 완료 (roadmap 체크박스)
```

- [ ] **Step 3: Append the autonomous/fan-out pointer (NOT a mirror)**

After the "단순 질문·메타 작업·설정 변경은 생명주기 불필요." line (currently line 61), insert:

```markdown

> **자율 모드·fan-out 미사용 (dev팀):** 이 dev팀은 자율 배치(skip-and-park)·병렬 fan-out 빌드를 운영하지 않는다. 해당 메커니즘이 필요해지면 배포물 `plugins/orbit-base/agents/leader.md`의 "Autonomous Loop" / "Independent fan-out" 절을 정전으로 참조한다. 여기 미러링하지 않는 이유: 미사용 거버넌스 ~90줄을 dev 설정에 복제하면 제2의 drift 표면이 생긴다(빠진 것은 역할이 아니라 문서다).
```

- [ ] **Step 4: Run verification**

```bash
cd /Users/dh/Project/orbit
grep -c 'discovery' .claude/agents/leader.md                  # expect >= 1
grep -c 'plugins/orbit-base/agents/leader.md' .claude/agents/leader.md  # expect >= 1 (pointer present)
```

Expected: discovery ≥ 1, pointer line ≥ 1.

- [ ] **Step 5: (commit deferred to Task 3 — both DRIFT-2 edits ship in one dev-agent commit)**

Do not commit yet. DRIFT-2 is one logical commit covering both leader.md and architect.md.

---

### Task 3: Add Discovery-first to dev architect.md work-order, then commit DRIFT-2

**Files:**
- Modify: `.claude/agents/architect.md:39-50` (작업 순서 section)

**Interfaces:**
- Consumes: the deployment architect's discovery-first convention; the dev leader diagram updated in Task 2 (for wording consistency on "discovery 먼저").
- Produces: dev architect work-order whose design path starts with Discovery. Completes the DRIFT-2 commit.

- [ ] **Step 1: Write the failing test (grep assertion)**

```bash
cd /Users/dh/Project/orbit
grep -c 'discovery\|Discovery\|문제 프레이밍\|디스커버리' .claude/agents/architect.md
```

Expected: `0`.

- [ ] **Step 2: Edit the "설계/플랜 요청 시" sub-list (lines 41-45)**

Insert a Discovery step as the new step 1, renumbering the rest. Replace the block:

```markdown
**설계/플랜 요청 시:**
1. **Discovery 먼저** — 문제 프레이밍·요구사항(필수/선택 구분)·스코프·우선순위 정리. 내부 사실은 `explore`, 외부 사실은 `researcher`에게 리드 경유로 위임하고 종합한다(신규 에이전트 안 만듦).
2. 요구사항 읽기
3. 플러그인 구조, 에이전트 스키마, 훅 인터페이스, 매니페스트 스펙, 배포 토폴로지 작성
4. `.planning/` 또는 플랜 파일에 기록
5. 리드에게 보고 (리드가 Plan Approval 진행)
```

- [ ] **Step 3: Run verification**

```bash
cd /Users/dh/Project/orbit
grep -c 'Discovery 먼저' .claude/agents/architect.md   # expect >= 1
```

Expected: ≥ 1.

- [ ] **Step 4: Commit DRIFT-2 (dev-team agents — isolated commit)**

```bash
cd /Users/dh/Project/orbit
git add .claude/agents/leader.md .claude/agents/architect.md
git commit -m "fix: add Discovery-first to dev-team leader/architect (DRIFT-2 core parity)"
```

---

# AREA C — DRIFT-3 (Dev-Team Path Portability) — T3 surface; re-gate recommended (BLOCKERs resolved by option b)

### Task 4: Make dev hooks portable in place (keep forks, fix absolute paths) — NO repoint, NO delete, NO state move

**Files:**
- Modify: `.planning/usage-detect.py:6` (state path derivation)
- Modify: `.planning/resume-inject.py:5` (pending path derivation; roadmap reference stays `.planning/roadmap.md`)
- Modify: `.claude/settings.json:19` (Notification hook command) and `:40` (UserPromptSubmit hook command) — drop the absolute `/Users/dh/Project/orbit` prefix only; keep the `.planning/*.py` fork targets

**Interfaces:**
- Consumes: nothing external. Pure path-portability edit of the existing dev forks.
- Produces: dev hooks that resolve their own paths via `CLAUDE_PROJECT_DIR` (cwd fallback) while keeping all state under `.planning/` and keeping the resume target at the live `.planning/roadmap.md`. `_team` fixes (Task 5) are independent.

**Critical context for the executor (why option b, not repoint+delete):**
- **Do NOT delete the dev forks and do NOT repoint settings.json at `plugins/orbit-base/hooks/*.py`.** A critic high-risk gate blocked that: the deployment `resume-inject.py` injects `${CLAUDE_PROJECT_DIR}/.orbit/roadmap.md`, but the dev team's real roadmap is `.planning/roadmap.md` and `.orbit/` does not exist here (gitignored wholesale). Repointing would break unattended resume and split usage state across `.planning/` (Stop/MessageDisplay hooks, untouched) and `.orbit/`.
- **This task keeps every path under `.planning/`.** The only defect being fixed is the hardcoded **absolute** prefix `/Users/dh/Project/orbit`. We replace it with a `CLAUDE_PROJECT_DIR`-relative (cwd-fallback) derivation. State location, roadmap target, and logic are all unchanged — only portability across contributor machines improves.
- **Deployment scripts (`plugins/orbit-base/hooks/`) are NOT touched.** DRIFT-3 stays a meta change (no domain-purity / product-commit / product-lifecycle implications).

- [ ] **Step 1: Write the failing test (assert absolute path present)**

```bash
cd /Users/dh/Project/orbit
grep -c "'/Users/dh/Project/orbit/.planning'" .planning/usage-detect.py   # expect 1
grep -c "/Users/dh/Project/orbit/.planning/pending-resume.json" .planning/resume-inject.py  # expect 1
grep -c '/Users/dh/Project/orbit/.planning/' .claude/settings.json        # expect 2
```

Expected: each grep returns 1, 1, 2 respectively (the hardcoded absolute paths — the portability defect).

- [ ] **Step 2: Edit `.planning/usage-detect.py` (line 6) — make `PLANNING` portable, keep `.planning/`**

Replace:

```python
PLANNING = '/Users/dh/Project/orbit/.planning'
```

with:

```python
PLANNING = os.path.join(os.environ.get('CLAUDE_PROJECT_DIR', os.getcwd()), '.planning')
```

(`os` is already imported on line 3. State stays in `.planning/`; only the absolute prefix becomes portable.)

- [ ] **Step 3: Edit `.planning/resume-inject.py` (line 5) — make `PENDING` portable, keep `.planning/`**

Replace:

```python
PENDING = '/Users/dh/Project/orbit/.planning/pending-resume.json'
```

with:

```python
PENDING = os.path.join(os.environ.get('CLAUDE_PROJECT_DIR', os.getcwd()), '.planning', 'pending-resume.json')
```

(`os` is already imported on line 3. **Leave the two `.planning/roadmap.md` strings in the injected prompt unchanged** — they correctly point at the dev team's live roadmap; that is BLOCKER #1's fix-by-non-change.)

- [ ] **Step 4: Verify both forks still compile**

```bash
cd /Users/dh/Project/orbit
python3 -m py_compile .planning/usage-detect.py && echo "usage-detect compiles"
python3 -m py_compile .planning/resume-inject.py && echo "resume-inject compiles"
```

Expected: both print `... compiles`.

- [ ] **Step 5: Edit `.claude/settings.json` Notification hook (line 19) — drop absolute prefix, keep dev fork target**

Replace:

```
"command": "python3 /Users/dh/Project/orbit/.planning/usage-detect.py"
```

with (cwd fallback so an unset `CLAUDE_PROJECT_DIR` in an async hook still resolves to the project root):

```
"command": "python3 \"${CLAUDE_PROJECT_DIR:-$PWD}/.planning/usage-detect.py\""
```

- [ ] **Step 6: Edit `.claude/settings.json` UserPromptSubmit hook (line 40) — drop absolute prefix, keep dev fork target**

Replace:

```
"command": "python3 /Users/dh/Project/orbit/.planning/resume-inject.py"
```

with:

```
"command": "python3 \"${CLAUDE_PROJECT_DIR:-$PWD}/.planning/resume-inject.py\""
```

- [ ] **Step 7: Validate settings.json is still valid JSON**

```bash
cd /Users/dh/Project/orbit
python3 -m json.tool .claude/settings.json > /dev/null && echo "settings.json valid JSON"
```

Expected: `settings.json valid JSON`. If it fails, the edit broke JSON escaping — fix the `\"` quoting.

- [ ] **Step 8: Behavior smoke test — exercise the ACTUAL hook command string, two env cases, with hard-fail assertions**

Extract the rewritten Notification command from settings.json and run it exactly as the harness would (`bash -c`), feeding a payload that **actually matches** the `usage-detect.py` trigger regex `9[3-9]%|100%`. (The earlier `"approaching usage limit, resets at 3:00 PM"` payload had **no percentage** → the script's `if not re.search(...)` short-circuits to `sys.exit(0)` and writes nothing → a vacuous pass that proves neither the write nor the fallback. The payload below contains `98%` and a reset time, so it reaches the `pending-resume.json` write. *Verified: `98% ... 3:00 PM` matches the regex; the old payload does not.*)

Two cases are run: **Case A** with `CLAUDE_PROJECT_DIR` set (the normal harness env), **Case B** with the variable **unset** via `env -u` and cwd = project root (the async-hook fallback branch — critic #2/#3). Both must land state in `.planning/` and leak nothing to `.orbit/`. Assertions hard-fail (`exit 1`) on a missing write so a silent no-op cannot pass.

```bash
cd /Users/dh/Project/orbit
CMD=$(python3 -c "import json; print(json.load(open('.claude/settings.json'))['hooks']['Notification'][0]['hooks'][0]['command'])")
echo "resolved hook command: $CMD"
PAYLOAD='{"message":"usage at 98% resets at 3:00 PM"}'

# --- Case A: CLAUDE_PROJECT_DIR set (normal harness env) ---
rm -f .planning/pending-resume.json
printf '%s' "$PAYLOAD" | CLAUDE_PROJECT_DIR="/Users/dh/Project/orbit" bash -c "$CMD"
test -f .planning/pending-resume.json && echo "PASS A: wrote .planning/pending-resume.json" || { echo "FAIL A: no write under CLAUDE_PROJECT_DIR set"; exit 1; }
test ! -e .orbit && echo "PASS A: no .orbit/ leak" || { echo "FAIL A: .orbit/ created — option b violated"; exit 1; }

# --- Case B: CLAUDE_PROJECT_DIR UNSET → cwd fallback (async-hook branch) ---
rm -f .planning/pending-resume.json
printf '%s' "$PAYLOAD" | env -u CLAUDE_PROJECT_DIR bash -c "cd /Users/dh/Project/orbit && $CMD"
test -f .planning/pending-resume.json && echo "PASS B: cwd-fallback wrote .planning/pending-resume.json" || { echo "FAIL B: fallback did not write (cwd-relative resolution broken)"; exit 1; }
test ! -e .orbit && echo "PASS B: no .orbit/ leak" || { echo "FAIL B: .orbit/ created under fallback"; exit 1; }
rm -f .planning/pending-resume.json
```

Expected: `PASS A: wrote ...`, `PASS A: no .orbit/ leak`, `PASS B: cwd-fallback wrote ...`, `PASS B: no .orbit/ leak`. Case A proves the set-env path; Case B is the load-bearing one — it exercises the `${CLAUDE_PROJECT_DIR:-$PWD}` fallback the async Notification hook may hit. **Async-hook cwd assumption (critic #3, closed as an explicit fact, not prose):** Claude Code invokes hook commands with the working directory set to the project root, so when `CLAUDE_PROJECT_DIR` is unset the `$PWD` fallback resolves to the project root — exactly what Case B asserts. The Python fork mirrors this with `os.environ.get('CLAUDE_PROJECT_DIR', os.getcwd())`. If this assumption were ever false, the independent probe shows the failure is **not** silent: the script would write to a wrong-but-existing dir or raise, and Case B's `exit 1` catches the missing `.planning/` write rather than passing vacuously.

- [ ] **Step 9: Resume-target verification — resume points at the dev team's live roadmap, both env cases**

```bash
cd /Users/dh/Project/orbit
# simulate a pending reset already elapsed → AUTO-RESUME branch
mkpending() { python3 -c "import json,time; json.dump({'reset_epoch': int(time.time())-10}, open('.planning/pending-resume.json','w'))"; }

# --- Case A: CLAUDE_PROJECT_DIR set ---
mkpending
OUT_A=$(printf '%s' '{"prompt":"hi"}' | CLAUDE_PROJECT_DIR="/Users/dh/Project/orbit" python3 .planning/resume-inject.py)
echo "$OUT_A" | grep -q '\.planning/roadmap\.md' && echo "PASS A: resume targets .planning/roadmap.md (live roadmap)" || { echo "FAIL A: wrong resume target"; exit 1; }
echo "$OUT_A" | grep -q '\.orbit/roadmap\.md' && { echo "FAIL A: resume targets nonexistent .orbit/roadmap.md"; exit 1; } || echo "PASS A: no .orbit/roadmap.md target"

# --- Case B: CLAUDE_PROJECT_DIR UNSET → cwd fallback ---
mkpending
OUT_B=$(printf '%s' '{"prompt":"hi"}' | env -u CLAUDE_PROJECT_DIR bash -c "cd /Users/dh/Project/orbit && python3 .planning/resume-inject.py")
echo "$OUT_B" | grep -q '\.planning/roadmap\.md' && echo "PASS B: fallback resume targets .planning/roadmap.md" || { echo "FAIL B: fallback wrong resume target"; exit 1; }

test -f .planning/roadmap.md && echo "PASS: target roadmap actually exists" || { echo "FAIL: target roadmap missing"; exit 1; }
rm -f .planning/pending-resume.json
```

Expected: `PASS A: resume targets .planning/roadmap.md (live roadmap)`, `PASS A: no .orbit/roadmap.md target`, `PASS B: fallback resume targets .planning/roadmap.md`, `PASS: target roadmap actually exists`. This is the critic-mandated proof that resume points at the real active roadmap under both the set-env and the unset-env (fallback) paths.

- [ ] **Step 10: Rollback note (critic #4 — failure detection + revert path)**

If Step 8 or Step 9 fails (state leaked to `.orbit/`, or resume targets the wrong roadmap, or JSON invalid), revert this task cleanly before retrying:

```bash
cd /Users/dh/Project/orbit
git checkout -- .planning/usage-detect.py .planning/resume-inject.py .claude/settings.json
```

(No deletions were made, so revert is a plain `git checkout` of three tracked files — there is nothing to un-delete.)

- [ ] **Step 11: (commit deferred to Task 5 — DRIFT-3 ships as one dev-env commit covering forks + settings + `_team`)**

Do not commit yet.

---

### Task 5: Make `_team/*.sh` path-portable, then commit DRIFT-3

**Files:**
- Modify: `_team/notify.sh:6`, `_team/notify-done.sh:3`, `_team/auto-attach.sh:4`, `_team/attach-view.sh:5-6`

**Interfaces:**
- Consumes: nothing (independent of Task 4). Pure path-derivation refactor.
- Produces: `_team` scripts that derive the project root from their own location instead of hardcoding `/Users/dh/Project/orbit` or `$HOME/Project/orbit`. Completes the DRIFT-3 commit.

**Pattern:** Each script lives in `<project-root>/_team/`. Derive the root once at the top:
```bash
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)"
PROJ="$(dirname "$SCRIPT_DIR")"
```
Then build all paths from `$PROJ` / `$SCRIPT_DIR`. The tmux session name `orbit-dev` stays literal (it is the dev session identity, not a path).

- [ ] **Step 1: Write the failing test (assert hardcoded paths present)**

```bash
cd /Users/dh/Project/orbit
grep -rln '/Users/dh/Project/orbit\|\$HOME/Project/orbit' _team/
```

Expected: lists `notify.sh`, `notify-done.sh`, `auto-attach.sh`, `attach-view.sh` (the hardcoded-path scripts).

- [ ] **Step 2: Edit `_team/notify.sh`**

Replace line 6:

```bash
NOTIF="$HOME/Project/orbit/.planning/notifications.log"
```

with (critic MINOR #6 — the comment documents that `SCRIPT_DIR` derivation assumes the script is executed directly, which all four `_team` scripts are: invoked by hooks or by `send-keys`, never sourced):

```bash
# SCRIPT_DIR assumes direct execution (hook/send-keys invocation), never `source`.
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)"
NOTIF="$(dirname "$SCRIPT_DIR")/.planning/notifications.log"
```

- [ ] **Step 3: Edit `_team/notify-done.sh`**

Replace line 3:

```bash
NOTIFY="/Users/dh/Project/orbit/_team/notify.sh"
```

with:

```bash
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)"
NOTIFY="$SCRIPT_DIR/notify.sh"
```

- [ ] **Step 4: Edit `_team/auto-attach.sh`**

Replace line 4:

```bash
PROJ="/Users/dh/Project/orbit"
```

with:

```bash
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)"
PROJ="$(dirname "$SCRIPT_DIR")"
```

(The rest of the script already uses `$PROJ/_team/attach-view.sh` — no further change needed.)

- [ ] **Step 5: Edit `_team/attach-view.sh`**

Replace lines 5-6:

```bash
PROJDIR="$HOME/.claude/projects/-Users-dh-Project-orbit"
RUNNER="$HOME/Project/orbit/_team/view-run.sh"
```

with:

```bash
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)"
PROJDIR="$HOME/.claude/projects/-Users-dh-Project-orbit"
RUNNER="$SCRIPT_DIR/view-run.sh"
```

(`PROJDIR` points at the Claude Code transcript store, which is keyed by the absolute project path and genuinely lives under `$HOME/.claude/projects/`. Leave its derivation as-is — it is not a project-relative path. Only `RUNNER` becomes script-relative.)

- [ ] **Step 6: Syntax-check all edited scripts**

```bash
cd /Users/dh/Project/orbit
for f in _team/notify.sh _team/notify-done.sh _team/auto-attach.sh _team/attach-view.sh; do
  bash -n "$f" && echo "$f OK"
done
```

Expected: all four print `... OK`.

- [ ] **Step 7: Behavior smoke test (notify.sh writes to the right place)**

```bash
cd /Users/dh/Project/orbit
_team/notify.sh "DRIFT-3 portability smoke test" && \
  tail -1 .planning/notifications.log
```

Expected: the last line of `.planning/notifications.log` shows the smoke-test message with a timestamp — confirming `SCRIPT_DIR` derivation resolves to the correct project-relative path.

- [ ] **Step 8: Confirm no hardcoded paths remain in `_team`**

```bash
cd /Users/dh/Project/orbit
grep -rn '/Users/dh/Project/orbit\|\$HOME/Project/orbit' _team/
```

Expected: no output (the only remaining `$HOME/.claude/projects/...` line in attach-view.sh is the transcript store, which is intentional and is not a `Project/orbit` path).

- [ ] **Step 9: Commit DRIFT-3 (dev-env — isolated commit)**

```bash
cd /Users/dh/Project/orbit
git add .planning/usage-detect.py .planning/resume-inject.py .claude/settings.json \
        _team/notify.sh _team/notify-done.sh _team/auto-attach.sh _team/attach-view.sh
git commit -m "fix: dev-team path portability — CLAUDE_PROJECT_DIR-relative hooks and script-relative _team paths (DRIFT-3)"
```

(Option b retains the dev forks — they are **edited, not deleted** — so this is a plain `git add` of all seven modified files. No `git rm`. The deployment scripts are untouched.)

---

# Triple Crown Verification (per area, run by reviewer after build)

### ① Completeness (GSD / roadmap comparison)
- All DRIFT-1/2/3 task checkboxes ticked.
- `.planning/roadmap.md` "내부 정합성 drift 보수" section: DRIFT-1, DRIFT-2, DRIFT-3 checkboxes marked `[x]` with date.
- Cross-check: every Discovery-Summary remediation point maps to a completed task.

### ② Behavior (runtime confirmation, not static read)
- **DRIFT-1:** `grep -c 'critic' plugins/orbit-base/commands/orbit-cycle.md` ≥ 3; manual read confirms the gate step is logically positioned between writing-plans and Plan Approval.
- **DRIFT-2:** `grep -c 'discovery' .claude/agents/leader.md` ≥ 1 and `.claude/agents/architect.md` ≥ 1; pointer line present.
- **DRIFT-3:** Task 4 Step 8 passes (the verbatim hook command writes `.planning/pending-resume.json`, no `.orbit/` leak). Task 4 Step 9 passes (resume prompt targets the live `.planning/roadmap.md`, never `.orbit/roadmap.md`). Task 5 Step 7 passes (notify.sh writes `.planning/notifications.log` via `SCRIPT_DIR`). `python3 -m json.tool .claude/settings.json` valid. `bash -n` clean on all `_team` scripts. **Deployment files unchanged:** `git diff --name-only` shows no `plugins/orbit-base/` path in the DRIFT-3 commit.

### ③ Quality (code review — superpowers requesting-code-review or architect arch-consistency lens)
- **Domain purity:** `grep -rn 'oremi\|Oremi\|orbit-dev' plugins/orbit-base/` returns 0 (DRIFT-1 introduced no project-specific names).
- **Cross-surface consistency:** orbit-cycle.md gate triggers match CLAUDE.md and SKILL.md (same four-trigger names).
- **Commit hygiene:** exactly three commits, product/dev never mixed, no `Co-Authored-By` line, correct `fix:` prefixes.
- **No regression:** the SubagentStop quality-gate hook (settings.json line 50) still passes — `bash -n` on all `plugins/orbit-base/*.sh`, `json.tool` on all `*.json`, domain-purity grep = 0.

---

## Success Criteria (measurable)

1. `grep -c 'critic' plugins/orbit-base/commands/orbit-cycle.md` ≥ 3 **and** the lifecycle diagram shows a high-risk gate branch between writing-plans and Plan Approval. *(DRIFT-1)*
2. `grep -c 'discovery' .claude/agents/leader.md` ≥ 1, `grep -c 'Discovery 먼저' .claude/agents/architect.md` ≥ 1, and dev leader.md contains a pointer to `plugins/orbit-base/agents/leader.md` for autonomous/fan-out (no full mirror). *(DRIFT-2)*
3. `.claude/settings.json` Notification + UserPromptSubmit hooks invoke the **dev forks** `.planning/*.py` via `${CLAUDE_PROJECT_DIR:-$PWD}` (no `/Users/dh/...` absolute prefix); the forks are **retained and edited** (not deleted); `grep -rn '/Users/dh/Project/orbit' .claude/settings.json .planning/usage-detect.py .planning/resume-inject.py` returns nothing; settings.json is valid JSON. State stays under `.planning/` (Task 4 Step 8: no `.orbit/` leak) and resume targets the live `.planning/roadmap.md` (Task 4 Step 9). *(DRIFT-3 hooks)*
4. `grep -rn '/Users/dh/Project/orbit\|\$HOME/Project/orbit' _team/` returns only the intentional `$HOME/.claude/projects/...` transcript-store line (no project-root hardcode); all four `_team` scripts pass `bash -n`. *(DRIFT-3 scripts)*
4b. `git diff --name-only` for the DRIFT-3 commit contains **no** `plugins/orbit-base/` path (deployment untouched; DRIFT-3 stays meta). *(DRIFT-3 scope)*
5. `grep -rn 'oremi\|Oremi\|orbit-dev' plugins/orbit-base/` returns 0 (domain purity preserved). *(global)*
6. Exactly three commits, product and dev paths never mixed in one commit. *(global)*

---

## Self-Review

**Spec coverage:** DRIFT-1 → Task 1. DRIFT-2 (leader diagram + architect work-order, core-only with autonomous pointer) → Tasks 2-3. DRIFT-3 (REVISED — settings.json hook path-portability + in-place dev-fork edits + `_team` portability) → Tasks 4-5. Discovery questions answered: DRIFT-2 = core-only recommendation with rationale; DRIFT-3 = **option (b) chosen** (keep dev forks, fix absolute paths in place — NOT repoint-to-deployment, which the critic gate blocked on two confirmed BLOCKERs). Four-trigger self-assessment present and re-scored post-revision (T3 still nominally fires on auto-exec hook edit; BLOCKERs resolved). Commit separation enforced. All addressed.

**Placeholder scan:** No TBD/TODO; every edit shows exact before/after text; every verification shows the command and expected output.

**Type/path consistency:** `${CLAUDE_PROJECT_DIR:-$PWD}` used identically in Task 4 Steps 5-6 (bash) and `os.environ.get('CLAUDE_PROJECT_DIR', os.getcwd())` in Task 4 Steps 2-3 (python). `SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)"` used identically across Task 5. State paths consistent: **all dev state stays under `.planning/`** (pending-resume, usage-detect.log, notifications.log) — no `.orbit/` is created or referenced anywhere in the dev path; deployment scripts (`.orbit/`-based) are untouched. The resume target remains `.planning/roadmap.md` (the live 15 KB roadmap), verified in Task 4 Step 9. No contradiction with the untouched Stop/MessageDisplay hooks, which also write `.planning/`.
```
