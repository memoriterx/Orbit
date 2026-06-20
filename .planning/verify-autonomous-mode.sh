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

# C15 skip-and-park profile invariants (added with the skip-and-park feature)
# C15a both profiles named in CLAUDE.md and leader.md
chk "C15a CLAUDE profiles named" "grep -qi 'skip-and-park' \"$BASE/CLAUDE.md\" && grep -qi 'halt-on-trigger' \"$BASE/CLAUDE.md\""
chk "C15b leader profiles named" "grep -qi 'skip-and-park' \"$BASE/agents/leader.md\" && grep -qi 'halt-on-trigger' \"$BASE/agents/leader.md\""
# C15c park never weakens the gate: non-weakening clause present wherever skip-and-park is described
for f in CLAUDE.md agents/leader.md skills/using-orbit/SKILL.md commands/orbit-cycle.md skills/using-orbit/references/codex-tools.md skills/using-orbit/references/gemini-tools.md; do
  chk "C15c $f park-with-guard" "! grep -qi 'skip-and-park' \"$BASE/$f\" || grep -qiE 'never auto-decided or auto-implemented|never auto-decided/auto-implemented|자동 결정.{0,4}자동 구현되지 않' \"$BASE/$f\""
done
# C15d failure-rollback halt survives in leader.md and is no longer unconditional isolate-and-continue
chk "C15d leader halt-on-first-failure kept" "grep -qi 'halt-on-first-failure' \"$BASE/agents/leader.md\""
chk "C15e leader isolate scoped to gate path" "! grep -qiE 'isolate-and-continue' \"$BASE/agents/leader.md\" || grep -qiE 'gate path|gate-path|before it is built|verification failure.*halt' \"$BASE/agents/leader.md\""
# C15f amortization: parked-backlog cap stated in CLAUDE.md
chk "C15f CLAUDE parked-backlog cap" "grep -qiE '3 or more parked|parked.{0,30}outstanding|declines.{0,40}autonomous batch' \"$BASE/CLAUDE.md\""
# C15g fail-closed staleness predicate stated in leader.md
chk "C15g leader fail-closed staleness" "grep -qiE 'affirmatively clear|positively established|fail-closed' \"$BASE/agents/leader.md\""

exit $fail
