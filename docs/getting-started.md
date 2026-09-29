---
title: Getting started
description: Go from a fresh clone of popote to a green quality gate, working git hooks, a code index and a first tracked issue.
type: tutorial
status: current
audience: contributors
last_reviewed: 2026-09-29
tags: [onboarding, mise, beads, pact, codegraph]
---

# Getting started

This tutorial takes you from a fresh clone to a working setup in about ten
minutes. At the end you will have every tool installed, the git hooks
enforcing the repository rules, the quality gate passing, and a first issue in
the tracker. Every command is safe to run twice.

You need `git`, `curl` and a POSIX shell. Everything else comes from mise.

## 1. Install mise

mise installs and pins every other tool, so this is the only manual install.
Skip this step if `mise --version` already prints a version.

```sh
curl -fsSL https://mise.run | sh
```

Then activate it in your shell as the installer tells you (for bash,
`eval "$(~/.local/bin/mise activate bash)"` in `~/.bashrc`), and open a new
shell.

## 2. Install the toolchain

From the repository root:

```sh
mise trust
mise install
```

`mise trust` is needed once per clone, because `mise.toml` defines tasks that
run commands. `mise install` fetches the tools listed in
[the toolchain reference](reference/toolchain.md). Check the result:

```sh
mise ls --current
```

Every line should show an installed version. If `github:chussenot/pact` fails
with a GitHub API error, see
[pact from source](reference/toolchain.md#pact-from-source).

## 3. Install the git hooks

```sh
mise run setup
```

This chains three sets of hooks behind git: prek runs the file checks and
`cog verify` on your commit message, then beads runs its own hooks. Try it
with a commit message that breaks the convention:

```sh
git commit --allow-empty -m "updated stuff"
```

The commit is refused with a cocogitto error. That is the hook working. The
accepted form is a [Conventional Commit](https://www.conventionalcommits.org):

```sh
git commit --allow-empty -m "chore: try the commit-msg hook"
git reset --soft HEAD~1
```

The second command undoes the test commit.

Then trust the project's rtk filters, which condense the output of `fd`, `yq`
and `scc` for agents. rtk shows each filter before asking:

```sh
mise run rtk:trust
```

## 4. Run the quality gate

```sh
mise run check
```

This is the same gate CI runs: shellcheck on every POSIX script, ruff on every
Python script, the documentation check (frontmatter, titles, links and a
current `docs/llms.txt`), and rustfmt, clippy, tests and API docs for the
crate. The tasks run in parallel; the run passes when it ends with
`Finished in` and no task reports an error.

## 5. Build the code index

Agents answer questions about the code from a local graph instead of reading
file after file. Build it once per clone:

```sh
mise run graph
```

It ends with `Indexed N files` and creates `.codegraph/`, which is
gitignored. The `codegraph` MCP server keeps it current while you work, so
you do not run this again unless you delete the directory. Try a query:

```sh
codegraph explore "cmd_check"
```

You get the source of the documentation checker and what calls it.

## 6. Track your first issue

Work is tracked in beads, not in Markdown TODO lists, so that agents and
humans share one backlog.

```sh
bd create "Describe the first popote feature" -t task -p 2
bd ready
```

`bd ready` lists the issue you created: it has no blockers. Claim it with
`bd update <id> --claim`, where `<id>` is the `popote-…` identifier printed
by `bd create`.

## 7. Give yourself an identity for pact

When several agents share this checkout, pact leases stop them from editing
the same file at once. It needs to know who you are:

```sh
export PACT_AGENT="$(git config user.name | tr ' ' '-')"
export BEADS_ACTOR="$PACT_AGENT"
pact whoami
```

`pact whoami` now prints your identity instead of a warning. Put both exports
in your shell profile, or in `mise.local.toml` under `[env]` (gitignored).

## Where to go next

- [The agent harness](agent-harness.md) explains why the setup looks like
  this.
- [Harness reference](reference/harness.md) lists every hook and agent.
- [Documentation style guide](contributing/documentation-style.md) before you
  write your first page.
