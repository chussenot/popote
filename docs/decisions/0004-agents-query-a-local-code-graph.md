---
title: Agents query a local code graph
description: Why popote agents answer code questions through codegraph over MCP, and what that costs in context, runtime and privacy.
type: decision
status: current
audience: everyone
last_reviewed: 2026-09-29
tags: [decisions, codegraph, mcp, agents]
---

# Agents query a local code graph

**Status:** accepted
**Date:** 2026-09-29

## Context

Coding agents discover structure by searching and reading files one at a
time. On a question about a flow ("how does X reach Y?") most of their tool
calls go to discovery, and text search misses indirect calls such as
callbacks and interface dispatch. Several agents work in this repository, and
Claude Code, Codex and Cursor are all configured, so a solution has to serve
all three.

## Decision

Use [codegraph](https://github.com/colbymchenry/codegraph). It indexes the
checkout into a local SQLite graph (`.codegraph/`, gitignored) and serves one
MCP tool, `codegraph_explore`, to all three agents from project-scoped config
(`.mcp.json`, `.cursor/mcp.json`, `.codex/config.toml`). A Claude Code prompt
hook adds graph context to structural prompts. It is installed from npm
through mise, and its telemetry is off by default (`CODEGRAPH_TELEMETRY=0`).

## Alternatives

- **Search and read only.** No new tool, but agents keep spending their
  budget rediscovering structure, and indirect calls stay invisible.
- **Language servers over MCP.** Precise per language, but one server per
  language to install and configure, and no single "explain this flow" query.
- **A hosted code search service.** Sends source off the machine, which is a
  larger decision than this repository should make alone.

## Consequences

- Upstream benchmarks report far fewer tool calls and no file reads for
  structural questions. That is the vendor's measurement on other
  repositories; it has not been measured here.
- Answers are dense and stay in context. Upstream measured about 80% more
  retrieval context resident at the end of long sessions. Long sessions in a
  small window pay for this.
- Node.js becomes a toolchain runtime (codegraph and the ponytail hooks need
  it). Scripts are still POSIX sh or Python, per
  [0003](0003-scripts-are-posix-sh-or-python.md).
- Each machine builds its own index (`mise run graph`). Cloud sessions build
  it at session start.
- The installer owns part of the config. `codegraph upgrade` can rewrite it,
  so review `git diff` after upgrading.
- Revisit if the index is regularly stale in practice, or if context
  pressure in long sessions outweighs the saved calls.
