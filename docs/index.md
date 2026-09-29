---
title: Documentation index
description: Every page in the popote documentation, grouped by what the reader is trying to do.
type: index
status: current
audience: everyone
last_reviewed: 2026-09-29
tags: [overview]
---

# Documentation index

The documentation follows [Diátaxis](https://diataxis.fr): each page does one
job, so you can tell from the section which kind of answer you will get.
Agents read the same list, generated from frontmatter, in [llms.txt](llms.txt).

## Learn

- [Getting started](getting-started.md): from a fresh clone to a green quality
  gate and a first tracked issue.

## Do

- [Add an agent to the harness](how-to/add-an-agent.md): write a new Claude
  Code subagent that follows the repository's conventions.
- [Release the crate](how-to/release-the-crate.md): publish a new version of
  `popote` to crates.io, including the one-time first publish.

## Look up

- [Toolchain reference](reference/toolchain.md): pinned tools and `mise` tasks.
- [Harness reference](reference/harness.md): hooks, agents, permissions and
  tool-managed instruction blocks.
- [Command-line tools for agents](reference/cli-tools.md): the fast search
  tools, their rtk handling and benchmarks.
- [Documentation style guide](contributing/documentation-style.md): voice,
  structure and the frontmatter contract.

## Understand

- [The agent harness](agent-harness.md): why the repository is built around
  agents, and the failure each part prevents.
- [Decision records](decisions/README.md): the choices made so far.
