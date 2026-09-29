---
title: Harness reference
description: Every Claude Code hook, subagent, permission and tool-managed instruction block in popote, and what triggers each one.
type: reference
status: current
audience: contributors
last_reviewed: 2026-09-29
tags: [harness, claude-code, hooks, mcp, reference]
---

# Harness reference

This page lists the parts of the agent harness and their triggers. Why each
part exists is in [The agent harness](../agent-harness.md).

## Files

| Path | Read by | Holds |
| --- | --- | --- |
| `AGENTS.md` | Every agent | The working protocol, plus the beads and pact blocks |
| `CLAUDE.md` | Claude Code | Claude-specific notes, the rtk block, and `@AGENTS.md` |
| `.claude/settings.json` | Claude Code | Permissions, hooks, enabled plugins |
| `.claude/agents/*.md` | Claude Code | Subagents |
| `.claude/hooks/*.sh` | Claude Code | Hook scripts (POSIX `sh`) |
| `.agents/skills/beads/` | Codex, Claude Code | Beads skill installed by `bd init` |
| `.codex/`, `.cursor/` | Codex, Cursor | Beads hooks and rules installed by `bd init` |
| `.rtk/filters.toml` | rtk | Project output filters for `fd`, `yq` and `scc`; active once trusted |
| `.ripgreprc` | ripgrep | Repository defaults: dot-directories, long-line previews |
| `.mcp.json` | Claude Code | Project MCP servers: `codegraph` |
| `.cursor/mcp.json` | Cursor | `codegraph` MCP server |
| `.codex/config.toml` | Codex | Codex hooks switch and the `codegraph` MCP server |
| `.codegraph/` | codegraph | Local index (SQLite); gitignored, built by `mise run graph` |
| `docs/llms.txt` | Agents | Generated page index; never edit |

## Claude Code hooks

| Event | Matcher | Script | Behaviour |
| --- | --- | --- | --- |
| `SessionStart` | all | `.claude/hooks/session-start.sh` | Cloud sessions only: installs mise and the toolchain, builds pact from source if needed, exports tool paths through `CLAUDE_ENV_FILE` (and `MISE_TASK_RUN_AUTO_INSTALL=false` when pact is not mise-managed), installs git hooks, trusts the project rtk filters, builds the codegraph index if missing. Local sessions: warns if mise is missing. Never fails the session |
| `SessionStart` | all | `bd prime --hook-json` | Loads the beads workflow and ready work into context |
| `PreToolUse` | `Bash` | `.claude/hooks/guard-bash.sh` | Denies the commands listed below, with the reason |
| `PreToolUse` | `Bash` | `.claude/hooks/rtk-rewrite.sh` | Passes the command to `rtk hook claude`, which prefixes supported commands with `rtk`. rtk pre-approves only read-only rewrites (`git status`); anything else (`git push --force`, compound commands) still goes through the permission rules. No-op without rtk |
| `UserPromptSubmit` | all | `scripts/codegraph.sh prompt-hook` | For a structural prompt ("how does X reach Y", a known symbol name), injects `codegraph_explore` output into context. Silent for other prompts, without an index, or when codegraph is not installed; never installs anything. Disable per user with `CODEGRAPH_NO_PROMPT_HOOK=1` |
| `PostToolUse` | `Edit\|Write` | `.claude/hooks/docs-on-edit.sh` | On `README.md` or `docs/**/*.md`: runs `docs.py check` on the page (exit 2 with findings on failure, which Claude Code shows to the agent), then regenerates `docs/llms.txt` |

### Commands the Bash guard denies

| Pattern | Why |
| --- | --- |
| `git push` to `main` (direct, `HEAD:main`, `+main`) | Changes reach `main` through pull requests |
| `git rebase -i`, `git add -i` | Interactive commands hang an agent shell |
| `bd edit` | Opens an editor and hangs |
| `git add`/`git commit` of `.env` or `.env.*` (not `.env.example`) | Secrets stay local |
| `git commit --no-verify` | Hooks enforce commit format and the docs gate |

Matching applies at command positions only, after here-doc bodies are
removed, so text that mentions a command is not blocked.

## Subagents

| Name | File | Tools | Use for |
| --- | --- | --- | --- |
| `docs-writer` | `.claude/agents/docs-writer.md` | Read, Grep, Glob, Edit, Write, Bash | Writing or updating `README.md` and `docs/**`, decision records, docs restructuring |

To add one, follow [Add an agent to the harness](../how-to/add-an-agent.md).

## MCP servers

| Server | Config | Tools exposed | Notes |
| --- | --- | --- | --- |
| `codegraph` | `.mcp.json`, `.cursor/mcp.json`, `.codex/config.toml` | `codegraph_explore` | Claude Code starts it through `scripts/codegraph.sh serve --mcp` (see below); Codex and Cursor call `codegraph serve --mcp` directly. The server watches the checkout and re-syncs the index about two seconds after a file changes. `alwaysLoad` keeps the tool out of Claude Code's deferred tool search. With no `.codegraph/` index it answers with guidance to use the built-in tools |

### Why Claude Code goes through `scripts/codegraph.sh`

Claude Code starts MCP servers and hooks with the environment it was launched
with. The session-start hook's `CLAUDE_ENV_FILE` only reaches Bash commands,
so in a cloud session `codegraph` was not on the server's `PATH` and the
server failed to connect. Without mise, the server also missed the `[env]` of
`mise.toml`, so `CODEGRAPH_TELEMETRY=0` did not apply to it.

`scripts/codegraph.sh` runs `mise exec npm:@colbymchenry/codegraph --
codegraph …` from the repository root, which fixes both. It finds mise on
`PATH` or in `~/.local/bin`, falls back to a `codegraph` already on `PATH`,
and exits 127 when neither exists. The MCP server may install codegraph on
first use; the prompt hook never installs anything, so a prompt is never held
up by a download. `.mcp.json` points at the script as
`${CLAUDE_PROJECT_DIR:-.}/scripts/codegraph.sh`, which Claude Code expands.

In a brand-new container the server can start before the session-start
hook has installed mise. It then fails once; reconnect it with `/mcp` after
the hook finishes. Installing mise in the environment's setup script removes
that race.

### Edits made after the installer

`codegraph install --target=claude,codex,cursor --location=local` generated
these files. Four edits were made afterwards:

- The Claude Code server and prompt hook call `scripts/codegraph.sh`. The
  hook command ends with the comment `# runs: codegraph prompt-hook`, the
  text the installer looks for, so `codegraph install --refresh` does not
  add a second hook.
- `.mcp.json` sets `alwaysLoad`.
- The Cursor entry uses `${workspaceFolder}` instead of the installer's
  absolute path, so it works in any clone.
- The installer's `.claude/CLAUDE.md` was deleted because it repeated the
  CodeGraph block already in `AGENTS.md`.

Re-running the installer or `codegraph upgrade` can undo these; check
`git diff` afterwards. To upgrade, change the pinned version in `mise.toml`
rather than running `codegraph upgrade`, then run `mise install` and
`codegraph install --refresh`, and review the diff.

## Plugins

| Plugin | Marketplace | Effect |
| --- | --- | --- |
| `ponytail@ponytail` | `DietrichGebert/ponytail` (GitHub) | Simplicity-first coding rules; `ponytail:` comments mark deliberate shortcuts; `/ponytail-debt` lists them |

Claude Code asks each user to trust the marketplace on first use.

## Permissions

`.claude/settings.json` pre-approves read-only and routine commands: `mise
run`, `prek run`, `cog check`/`verify`/`changelog`, `shellcheck`, `ruff`,
`python3 scripts/docs.py`, every `codegraph` MCP tool (`mcp__codegraph__*`),
the common `bd` subcommands, the non-destructive
`pact` subcommands, `rtk proxy`, and `git status`/`diff`/`log`. It denies
reading `.env` and `.env.*`. Everything else prompts.

## Git hooks

`core.hooksPath` is `.beads/hooks`. `scripts/setup-hooks.sh` inserts a prek
block ahead of the beads-managed section in each hook, so prek runs first.

| Git hook | Runs |
| --- | --- |
| `pre-commit` | File hygiene, shellcheck, ruff, `docs.py check`, `docs.py llms --check`, `.env` refusal; then beads |
| `commit-msg` | `cog verify --file` (Conventional Commits) |
| `pre-push` | `mise run check`; then beads |

## Tool-managed blocks

Edit text outside these markers only; the owning tool rewrites what is inside.

| File | Marker | Owner | Refresh with |
| --- | --- | --- | --- |
| `AGENTS.md` | `BEGIN BEADS INTEGRATION` | beads | `bd setup` |
| `AGENTS.md` | `pact:begin` | pact | `pact init` |
| `CLAUDE.md` | `pact:begin` | pact | `pact init` |
| `CLAUDE.md` | `rtk-instructions` | rtk | `rtk init` |
| `AGENTS.md` | `CODEGRAPH_START` | codegraph | `codegraph install --refresh` |

`bd init` also writes a beads block into `CLAUDE.md` and a second one for
Codex into `AGENTS.md`. Both were removed because `CLAUDE.md` imports
`AGENTS.md`, and `pact doctor` flags the duplicates. A beads upgrade may add
them back; run `pact doctor` afterwards.
