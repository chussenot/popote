---
title: Harness reference
description: Every Claude Code hook, subagent, permission and tool-managed instruction block in popote, and what triggers each one.
type: reference
status: current
audience: contributors
last_reviewed: 2026-09-29
tags: [harness, claude-code, hooks, reference]
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
| `.rtk/filters.toml` | rtk | Project output filters (template, none active) |
| `docs/llms.txt` | Agents | Generated page index; never edit |

## Claude Code hooks

| Event | Matcher | Script | Behaviour |
| --- | --- | --- | --- |
| `SessionStart` | all | `.claude/hooks/session-start.sh` | Cloud sessions only: installs mise and the toolchain, builds pact from source if needed, exports tool paths through `CLAUDE_ENV_FILE`, installs git hooks. Local sessions: warns if mise is missing. Never fails the session |
| `SessionStart` | all | `bd prime --hook-json` | Loads the beads workflow and ready work into context |
| `PreToolUse` | `Bash` | `.claude/hooks/guard-bash.sh` | Denies the commands listed below, with the reason |
| `PreToolUse` | `Bash` | `.claude/hooks/rtk-rewrite.sh` | Passes the command to `rtk hook claude`, which prefixes supported commands with `rtk`. rtk pre-approves only read-only rewrites (`git status`); anything else (`git push --force`, compound commands) still goes through the permission rules. No-op without rtk |
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

## Plugins

| Plugin | Marketplace | Effect |
| --- | --- | --- |
| `ponytail@ponytail` | `DietrichGebert/ponytail` (GitHub) | Simplicity-first coding rules; `ponytail:` comments mark deliberate shortcuts; `/ponytail-debt` lists them |

Claude Code asks each user to trust the marketplace on first use.

## Permissions

`.claude/settings.json` pre-approves read-only and routine commands: `mise
run`, `prek run`, `cog check`/`verify`/`changelog`, `shellcheck`, `ruff`,
`python3 scripts/docs.py`, the common `bd` subcommands, the non-destructive
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

`bd init` also writes a beads block into `CLAUDE.md` and a second one for
Codex into `AGENTS.md`. Both were removed because `CLAUDE.md` imports
`AGENTS.md`, and `pact doctor` flags the duplicates. A beads upgrade may add
them back; run `pact doctor` afterwards.
