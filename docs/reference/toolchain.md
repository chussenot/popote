---
title: Toolchain reference
description: Every tool pinned in mise.toml, what it is for, and every mise task with the command it runs.
type: reference
status: current
audience: contributors
last_reviewed: 2026-09-29
tags: [mise, tooling, reference]
---

# Toolchain reference

`mise.toml` is the single source for tools and tasks. This page lists both.
Why there is one entry point: [decision 0001](../decisions/0001-mise-is-the-single-toolchain-entry-point.md).

## Tools

| Tool | mise backend | Purpose |
| --- | --- | --- |
| Python 3.13 | `python` | Runs the Python scripts in `scripts/` and the hooks' JSON parsing |
| uv | `uv` | Python package manager, for when a script outgrows the standard library |
| ruff | `ruff` | Python lint and format, configured in `ruff.toml` |
| shellcheck | `shellcheck` | Lint for POSIX `sh` scripts |
| prek | `prek` | Runs `.pre-commit-config.yaml` as git hooks, without a Python venv per hook |
| cocogitto (`cog`) | `cocogitto` | Conventional Commits checks, changelog, version bumps; configured in `cog.toml` |
| beads (`bd`) | `github:gastownhall/beads` | Issue tracker shared by agents and humans; state in `.beads/` |
| pact | `github:chussenot/pact` | Leases, messages and watches between agents in one checkout; state in `.pact/` |
| rtk | `rtk` | Condenses command output before it reaches an agent |

Versions are `latest` except Python. `mise install` records nothing in the
repository, so two machines can resolve different versions after a release.
Pin a version in `mise.toml` when a tool upgrade breaks the gate.

### pact from source

mise installs pact from its GitHub release through the GitHub API. Some
environments cannot reach that API for this repository and fail with a
`403 Forbidden`. The fallback builds from the git source (about 30 seconds,
needs `cargo`):

```sh
cargo install --git https://github.com/chussenot/pact --locked --root "$HOME/.local"
```

The cloud session-start hook runs this fallback automatically.

## Tasks

Run a task with `mise run <task>`; `mise tasks` lists them.

| Task | Runs | Use it to |
| --- | --- | --- |
| `setup` | `scripts/setup-hooks.sh` | Install the git hooks once per clone |
| `check` | `lint:sh`, `lint:py`, `docs:check` | Run the full quality gate (what CI and pre-push run) |
| `lint:sh` | `shellcheck --shell=sh scripts/*.sh .claude/hooks/*.sh` | Lint every POSIX script |
| `lint:py` | `ruff check .` and `ruff format --check .` | Lint and format-check every Python script |
| `docs:check` | `python3 scripts/docs.py check` and `llms --check` | Validate frontmatter, titles, links; confirm `docs/llms.txt` is current |
| `docs:llms` | `python3 scripts/docs.py llms` | Regenerate `docs/llms.txt` |
| `commits:check` | `cog check` | Confirm every commit follows Conventional Commits |
| `precommit` | `prek run --all-files` | Run every pre-commit hook against the whole tree |
| `changelog` | `cog changelog` | Print the changelog since the last tag |
| `release` | `cog bump --auto` | Bump the version from commit history, tag, update `CHANGELOG.md` |
| `bd:ready` | `bd ready` | List issues with no open blockers |
| `pact:doctor` | `pact doctor` | Check the coordination protocol is current and committed |

## Environment

mise loads `.env` from the repository root when it exists. `.env` is
gitignored and the Bash guard refuses to commit it. Personal overrides
(`PACT_AGENT`, a pinned tool version) go in `mise.local.toml`, also
gitignored.
