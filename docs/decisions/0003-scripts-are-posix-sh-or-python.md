---
title: Scripts are POSIX sh or Python
description: Why every script and hook in popote is POSIX sh or standard-library Python, and when that rule would change.
type: decision
status: current
audience: contributors
last_reviewed: 2026-09-29
tags: [decisions, scripts]
---

# Scripts are POSIX sh or Python

**Status:** accepted
**Date:** 2026-09-29

## Context

Scripts run in git hooks, Claude Code hooks, CI runners and fresh cloud
containers, sometimes before `mise install` has finished. A script that needs
a runtime or package that is not there fails at the worst moment: on commit,
or at session start.

## Decision

Scripts are either POSIX `sh` (no Bash-isms) or Python 3 using the standard
library only. Shell is for gluing commands together; Python is for anything
that parses, validates or generates. shellcheck (`--shell=sh`) and ruff gate
both.

## Alternatives

- **Bash.** Arrays and `[[ ]]` are convenient, but `/bin/sh` is `dash` on
  Debian and Ubuntu, and the difference shows up only when a hook runs there.
- **Node.js or Go.** A second runtime or a compile step for helper scripts.
- **Python with third-party packages.** Needs a virtual environment before
  the first hook can run.

## Consequences

- Any script runs on any machine with `sh` and `python3`.
- Some Python is longer than it would be with a library; `scripts/docs.py`
  parses flat frontmatter itself instead of using PyYAML.
- When a script needs a package, it becomes a `uv` project with its own lock
  file, and this record is superseded.
