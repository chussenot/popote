---
title: mise is the single toolchain entry point
description: Why every tool and task in popote is declared in mise.toml, and what that costs.
type: decision
status: current
audience: everyone
last_reviewed: 2026-09-29
tags: [decisions, mise, tooling]
---

# mise is the single toolchain entry point

**Status:** accepted
**Date:** 2026-09-29

## Context

popote is worked on by humans and by coding agents, locally and in ephemeral
cloud containers. Every environment needs the same linters, hook runner,
commit checker, issue tracker and coordination tool, at compatible versions.
Without one declaration, each environment installs tools its own way and the
quality gate gives different answers on different machines.

## Decision

`mise.toml` declares every tool and every task. `mise install` provisions a
machine; `mise run <task>` is the only documented way to run a gate. Git
hooks, CI and the cloud session-start hook all call through mise.

## Alternatives

- **A Makefile plus per-tool install instructions.** Tasks are covered, tools
  are not: each contributor still installs and upgrades tools by hand.
- **A dev container.** Reproducible, but heavy for a repository of scripts
  and docs, and cloud agent sessions do not run inside it.
- **The installers each tool publishes (`curl | sh`).** Fine for one
  machine, but unpinned, scattered, and each writes to a different place.

## Consequences

- One command provisions any environment, and one file shows the whole
  toolchain.
- Contributors install mise first.
- Tools are on `latest` by default, so a release can change behaviour between
  two installs. Pin in `mise.toml` when that happens.
- A tool whose mise backend fails in an environment needs a documented
  fallback; pact has one (build from source).
