---
title: Documentation is Markdown with a frontmatter contract
description: Why popote documentation is Markdown in the repository with validated frontmatter and a generated llms.txt.
type: decision
status: current
audience: everyone
last_reviewed: 2026-09-29
tags: [decisions, docs]
---

# Documentation is Markdown with a frontmatter contract

**Status:** accepted
**Date:** 2026-09-29

## Context

Agents act on documentation without asking questions, so a stale or
ambiguous page produces wrong work, not just confusion. Agents also need to
find the right page cheaply, without reading the whole tree. Humans need the
same pages to render on GitHub and in review diffs.

## Decision

Documentation is Markdown under `docs/`, reviewed in the same pull request as
the code it describes. Every page carries frontmatter with a fixed set of
keys (title, one-sentence description, Diátaxis type, status, last reviewed
date, tags). `scripts/docs.py` validates it on edit, on commit and in CI, and
generates `docs/llms.txt` from it, so the agents' index is always current.
A dedicated `docs-writer` agent applies the
[style guide](../contributing/documentation-style.md).

## Alternatives

- **A wiki or an external docs tool.** Drifts from the code because it is not
  reviewed with it, and agents cannot read it from the checkout.
- **A static site generator from the start (MkDocs, Docusaurus).** Adds a
  build and a config file before there is anything to publish. The
  frontmatter is compatible with both, so this stays open.
- **Frontmatter without validation.** A convention nobody checks decays; a
  typo in a key would silently drop a page from the index.

## Consequences

- Every page is findable from `docs/llms.txt` by its description.
- Writing a page costs a frontmatter block and a passing check.
- The gate proves structure and links, not truth; accuracy still depends on
  review against the code.
- The parser is deliberately flat (no nested YAML). If the contract needs
  nesting, the script moves to a YAML library.
