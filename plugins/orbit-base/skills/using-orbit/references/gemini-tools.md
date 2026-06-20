# Gemini CLI Tool Mapping

Orbit skills use Claude Code tool names. When you encounter these in a skill or agent definition, use your Gemini CLI platform equivalent:

| Skill references | Gemini CLI equivalent |
|-----------------|----------------------|
| `Read` (file reading) | `read_file` |
| `Write` (file creation) | `write_file` |
| `Edit` (file editing) | `replace` |
| `Bash` (run shell commands) | `run_shell_command` |
| `Grep` (search file content) | `grep_search` |
| `Glob` (search files by name) | `glob` |
| `WebSearch` | `google_web_search` |
| `WebFetch` | `web_fetch` |
| `Skill` tool (invoke a skill) | `activate_skill` |
| `Agent` / `Task` (dispatch subagent) | `@generalist` (see [Subagent Support](#subagent-support)) |

## Subagent Support

Gemini CLI supports subagents via the `@` syntax. Use `@generalist` to dispatch any role with the full prompt from the agent definition.

| Orbit role dispatch | Gemini CLI equivalent |
|--------------------|-----------------------|
| `Agent(architect, prompt=...)` | `@generalist` with architect.md instructions + your task |
| `Agent(critic, prompt=...)` | `@generalist` with critic.md instructions + your task — high-risk plan critique (leader-gated, optional branch) |
| `Agent(builder, prompt=...)` | `@generalist` with builder.md instructions + your task |
| `Agent(explore, prompt=...)` | `@generalist` with explore.md instructions + your task — read-only internal codebase search (finds files/patterns/relationships; never modifies) |
| `Agent(reviewer, prompt=...)` | `@generalist` with reviewer.md instructions + your task |
| `Agent(researcher, prompt=...)` | `@generalist` with researcher.md instructions + your task |

Fill all `{{SLOT}}` placeholders in the agent definition before passing it to `@generalist`.

## Hub-and-Spoke in Gemini CLI

Gemini CLI supports parallel subagent dispatch. For independent tasks, dispatch all `@generalist` requests together. For dependent tasks, sequence them.

Without subagents, apply **sequential role-switching**: the single agent assumes each role explicitly, narrating the transition. The lifecycle discipline and Triple Crown verification remain identical.

## Additional Gemini CLI Tools

These tools are available in Gemini CLI but have no Claude Code equivalent:

| Tool | Purpose |
|------|---------|
| `list_directory` | List files and subdirectories |
| `save_memory` | Persist facts to GEMINI.md across sessions |
| `ask_user` | Request structured input from the user |
| `tracker_create_task` | Rich task management |
| `enter_plan_mode` / `exit_plan_mode` | Read-only research mode before making changes |

## Orbit State Directory

`.orbit/` in the project root holds:
- `roadmap.md` — thin task ledger
- `notifications.log` — progress channel
- `quality-gate.sh` — project-specific verification commands
- `config` — environment overrides

## Limitations vs. Claude Code

| Feature | Gemini CLI |
|---------|------------|
| Automatic hooks (quality gate, viewer, usage-resume) | Not available → run scripts manually |
| Viewer pane (live subagent transcripts) | Not available |
| Slash commands (`/orbit-init`, `/orbit-cycle`) | Not available → follow SKILL.md prose |
| Lifecycle discipline and Triple Crown | Full — identical to Claude Code |

## Loading Orbit Context

Gemini CLI loads Orbit via `GEMINI.md` (pointed to by `gemini-extension.json`). The `@` pointers in `GEMINI.md` load:
1. `skills/using-orbit/SKILL.md` — lifecycle and methodology prose
2. `skills/using-orbit/references/gemini-tools.md` — this file (tool mapping)

## Autonomous Mode (opt-in)

Under Gemini CLI's single-context, role-switching model, orbit's opt-in autonomous loop is **manual sequential**: the leader role processes each pre-approved batch task in turn, switching roles per step. The four-trigger auto-halt and full Triple Crown still apply; the human still grants the batch pre-approval once and the loop still halts on any high-risk firing. The human still grants the batch pre-approval once, now also selecting one of two execution profiles: `halt-on-trigger` (default — the manual sequential loop stops on the first ejection) or opt-in `skip-and-park` (the ejected task is parked and the role-switching loop continues through the remaining low-risk tasks, with the parked set reported at batch end). Under both, a parked high-risk or ambiguous task is **never auto-decided or auto-implemented** — it returns to individual Plan Approval with the critic branch; the four-trigger gate and full Triple Crown are unchanged.
