---
title: Toolchain reference
description: Every tool pinned in mise.toml, what it is for, and every mise task with the command it runs.
type: reference
status: current
audience: contributors
last_reviewed: 2026-09-29
tags: [mise, tooling, reference, codegraph, rust]
---

# Toolchain reference

`mise.toml` is the single source for tools and tasks. This page lists both.
Why there is one entry point: [decision 0001](../decisions/0001-mise-is-the-single-toolchain-entry-point.md).

## Tools

| Tool | mise backend | Purpose |
| --- | --- | --- |
| Rust 1.94.1 with rustfmt and clippy | `rust` | Builds, lints, tests and packages the crates under `crates/`; must satisfy `rust-version` in `Cargo.toml` (1.94) |
| Python 3.13 | `python` | Runs the Python scripts in `scripts/` and the hooks' JSON parsing |
| uv | `uv` | Python package manager, for when a script outgrows the standard library |
| ruff | `ruff` | Python lint and format, configured in `ruff.toml` |
| shellcheck | `shellcheck` | Lint for POSIX `sh` scripts |
| prek | `prek` | Runs `.pre-commit-config.yaml` as git hooks, without a Python venv per hook |
| cocogitto (`cog`) | `cocogitto` | Conventional Commits checks, changelog, version bumps; configured in `cog.toml` |
| beads (`bd`) | `github:gastownhall/beads` | Issue tracker shared by agents and humans; state in `.beads/` |
| pact | `github:chussenot/pact` | Leases, messages and watches between agents in one checkout; state in `.pact/` |
| rtk | `rtk` | Condenses command output before it reaches an agent |
| ripgrep (`rg`) | `ripgrep` | Content search; defaults in `.ripgreprc` |
| fd | `fd` | File search by name |
| ast-grep | `ast-grep` | Structural code search and rewrite |
| jq | `jq` | JSON query |
| yq | `yq` | YAML, TOML and XML query (mikefarah v4, not the Python `yq`) |
| sd | `sd` | Search and replace across files |
| scc | `aqua:boyter/scc` | Code size and complexity by language |
| hyperfine | `hyperfine` | Command benchmarking |
| Node.js LTS | `node` | Runtime for codegraph and the ponytail plugin hooks; not used for repository scripts |
| codegraph (pinned) | `npm:@colbymchenry/codegraph` | Local code knowledge graph served to agents over MCP; index in `.codegraph/` |

Versions are `latest` except Rust, Python, Node.js (current LTS) and codegraph. Rust is pinned so local, CI and release builds use the same compiler; bump it together with `rust-version` in `Cargo.toml`. codegraph is pinned because an upgrade can rewrite the agent configuration it generated ([harness reference](harness.md#edits-made-after-the-installer)), and because 1.6.0's prompt hook injected several KB of source into every task notification; 1.6.1 fixed that. `mise install` records nothing in the
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

Why these search tools, and how they perform: [Command-line tools for agents](cli-tools.md).

## Tasks

Run a task with `mise run <task>`; `mise tasks` lists them.

| Task | Runs | Use it to |
| --- | --- | --- |
| `setup` | `scripts/setup-hooks.sh` | Install the git hooks once per clone |
| `check` | `lint:sh`, `lint:py`, `docs:check`, `rust:fmt`, `rust:lint`, `rust:test`, `rust:doc` | Run the full quality gate (what CI and pre-push run) |
| `lint:sh` | `shellcheck --shell=sh scripts/*.sh .claude/hooks/*.sh` | Lint every POSIX script |
| `lint:py` | `ruff check .` and `ruff format --check .` | Lint and format-check every Python script |
| `docs:check` | `python3 scripts/docs.py check` and `llms --check` | Validate frontmatter, titles, links; confirm `docs/llms.txt` is current |
| `docs:llms` | `python3 scripts/docs.py llms` | Regenerate `docs/llms.txt` |
| `rust:fmt` | `cargo fmt --all --check` | Fail on unformatted Rust source |
| `rust:lint` | `cargo clippy --workspace --all-targets --locked -- -D warnings` | Lint every target with the pedantic set; warnings are errors |
| `rust:test` | `cargo test --workspace --locked` | Run unit tests and doctests, including the crate README example |
| `rust:doc` | `cargo doc --workspace --no-deps --locked` with `RUSTDOCFLAGS=-D warnings` | Build the API docs; a broken intra-doc link fails |
| `rust:package` | `cargo publish --dry-run --locked -p popote` | Build the crate exactly as crates.io would receive it, without uploading; CI runs it after `check` |
| `commits:check` | `cog check` | Confirm every commit follows Conventional Commits |
| `precommit` | `prek run --all-files` | Run every pre-commit hook against the whole tree |
| `changelog` | `cog changelog` | Print the changelog since the last tag |
| `release` | `cog bump --auto --annotated 'popote {{version}}'` | Bump the version from commit history, set it in the crate, update `CHANGELOG.md`, commit, and create an annotated `v*` tag that `git push --follow-tags` sends; see [Release the crate](../how-to/release-the-crate.md) |
| `graph` | `codegraph init --yes`, or `codegraph sync` when an index exists | Build or refresh the local code index |
| `rtk:trust` | `rtk trust` | Review and trust `.rtk/filters.toml` on this machine |
| `rtk:verify` | `rtk verify` | Run the inline tests of the rtk filters |
| `bench` | `scripts/bench-search.sh` | Compare `rg`/`fd` with `grep`/`find` on a directory |
| `bd:ready` | `bd ready` | List issues with no open blockers |
| `pact:doctor` | `pact doctor` | Check the coordination protocol is current and committed |

## Environment

`mise.toml` sets `CODEGRAPH_TELEMETRY=0`, so codegraph sends no usage
statistics from this repository. The setting reaches every codegraph
process: shells get it from mise, and the MCP server and prompt hook get it
through `scripts/codegraph.sh`. To opt in, set it to `1` in
`mise.local.toml`. What it would send is listed in the upstream
[TELEMETRY.md](https://github.com/colbymchenry/codegraph/blob/main/TELEMETRY.md).

`mise.toml` also sets `RIPGREP_CONFIG_PATH` to `.ripgreprc`, so ripgrep
searches dot-directories by default; see
[the ripgrep defaults](cli-tools.md#ripgrep-ripgreprc).

mise loads `.env` from the repository root when it exists. `.env` is
gitignored and the Bash guard refuses to commit it. Personal overrides
(`PACT_AGENT`, a pinned tool version) go in `mise.local.toml`, also
gitignored.
