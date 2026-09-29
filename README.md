---
title: popote
description: What popote is, how the repository is set up for humans and coding agents, and where the documentation lives.
type: index
status: draft
audience: everyone
last_reviewed: 2026-09-29
tags: [overview]
---

# popote

popote is a Rust library that scales recipe quantities between serving
counts: `popote::scale(300.0, 4, 6)` returns `Ok(450.0)`. The crate lives in
`crates/popote`, has no dependencies, and is released to crates.io from this
repository; its crates.io page is [`crates/popote/README.md`](crates/popote/README.md).

The rest of the repository is the toolchain and the agent harness. The harness
exists so that several coding agents and humans can work in one checkout, with
the same tools, the same rules and a documentation gate that keeps the docs
honest.

## Quick start

```sh
curl -fsSL https://mise.run | sh   # once per machine, if mise is missing
mise install                       # every tool pinned in mise.toml
mise run setup                     # git hooks: prek, cocogitto, beads
mise run check                     # the quality gate CI runs
```

The full walkthrough is [Getting started](docs/getting-started.md).

## Documentation

| Page | Answers |
| --- | --- |
| [Documentation index](docs/index.md) | Where every page is and what each is for |
| [Getting started](docs/getting-started.md) | How to go from a clone to a green gate and a first issue |
| [The agent harness](docs/agent-harness.md) | Why the repository is built around agents, and what each part prevents |
| [Toolchain reference](docs/reference/toolchain.md) | Which tools are pinned and which `mise` tasks exist |
| [Command-line tools for agents](docs/reference/cli-tools.md) | Which search tools agents use, and how fast they are |
| [Harness reference](docs/reference/harness.md) | Every hook, agent, permission and managed block, and what triggers it |
| [Release the crate](docs/how-to/release-the-crate.md) | How to publish a new version to crates.io, and the one-time first publish |
| [Documentation style guide](docs/contributing/documentation-style.md) | How pages are written and the frontmatter contract |
| [Decision records](docs/decisions/README.md) | The choices made so far, and why |

Agents start at [`docs/llms.txt`](docs/llms.txt), generated from the page
frontmatter, and at [`AGENTS.md`](AGENTS.md) for the working protocol.
