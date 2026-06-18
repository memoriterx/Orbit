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
