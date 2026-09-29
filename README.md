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

popote is at its starting point: the repository holds the toolchain and the
agent harness, not product code yet. The harness exists so that several coding
agents and humans can work in one checkout from the first commit, with the same
tools, the same rules and a documentation gate that keeps the docs honest.

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
| [Harness reference](docs/reference/harness.md) | Every hook, agent, permission and managed block, and what triggers it |
| [Documentation style guide](docs/contributing/documentation-style.md) | How pages are written and the frontmatter contract |
| [Decision records](docs/decisions/README.md) | The choices made so far, and why |

Agents start at [`docs/llms.txt`](docs/llms.txt), generated from the page
frontmatter, and at [`AGENTS.md`](AGENTS.md) for the working protocol.
