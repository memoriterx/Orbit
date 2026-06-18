# Codex Tool Mapping

Orbit skills use Claude Code tool names. When you encounter these in a skill or agent definition, use your Codex platform equivalent:

| Skill references | Codex equivalent |
|-----------------|------------------|
| `Agent` / `Task` (dispatch subagent) | `spawn_agent` (requires multi-agent support — see below) |
| Multiple `Agent` calls (parallel dispatch) | Multiple `spawn_agent` calls |
| Agent returns result | `wait_agent` |
| Agent completes, free the slot | `close_agent` |
| `Skill` tool (invoke a skill) | Skills load natively — follow the instructions |
| `Read` (file reading) | Use your native file tools |
| `Write` (file creation) | Use your native file tools |
| `Edit` (file editing) | Use your native file tools |
| `Bash` (run shell commands) | Use your native shell tools |
| `Grep` (search file content) | Use your native search tools |
| `Glob` (search files by name) | Use your native file listing tools |
| `WebSearch` | Use your native web search |
| `WebFetch` | Use your native web fetch |

## Enabling Multi-Agent Support (Required for Hub-and-Spoke)

Add to your Codex config (`~/.codex/config.toml`):

```toml
[features]
multi_agent = true
```

This enables `spawn_agent`, `wait_agent`, and `close_agent` for hub-and-spoke Agent dispatch.

Without `multi_agent = true`, Codex runs in single-context mode. In this mode, apply **sequential role-switching**: the single agent assumes each role (leader, architect, builder, reviewer) in sequence, explicitly narrating the role transition. Lifecycle discipline and Triple Crown verification still apply — only parallel dispatch is unavailable.

## Hub-and-Spoke in Codex

With `multi_agent = true`:

```
leader → spawn_agent(architect, prompt=...)  → wait_agent → close_agent
leader → spawn_agent(explore, prompt=...)    → wait_agent → close_agent  # internal codebase search
leader → spawn_agent(critic, prompt=...)     → wait_agent → close_agent  # high-risk only
leader → spawn_agent(builder, prompt=...)    → wait_agent → close_agent
leader → spawn_agent(reviewer, prompt=...)   → wait_agent → close_agent
```

Without `multi_agent`:

```
[LEADER] Dispatching to architect role...
[ARCHITECT] ... (design work) ...
[LEADER] Need to locate code? Dispatching to explore role...
[EXPLORE] ... (read-only internal codebase search) ...
[LEADER] High-risk? Dispatching to critic role... (skip if low-risk)
[CRITIC] ... (independent plan critique for high-risk decisions (leader-gated)) ...
[LEADER] Received critic output. Dispatching to builder...
[BUILDER] ... (implementation) ...
[LEADER] Received builder output. Dispatching to reviewer...
[REVIEWER] ... (verification) ...
```

## Orbit State Directory

`.orbit/` in the project root holds:
- `roadmap.md` — thin task ledger
- `notifications.log` — progress channel
- `quality-gate.sh` — project-specific verification commands
- `config` — `ORBIT_TMUX_SESSION` and other overrides

## Limitations vs. Claude Code

| Feature | Codex |
|---------|-------|
| Automatic hooks (quality gate, viewer, usage-resume) | Not available → run scripts manually |
| Viewer pane (live subagent transcripts) | Not available |
| Slash commands (`/orbit-init`, `/orbit-cycle`) | Partial — follow the SKILL.md prose manually |
| Lifecycle discipline and Triple Crown | Full — identical to Claude Code |
