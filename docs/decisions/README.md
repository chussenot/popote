---
title: Decision records
description: The architecture and process decisions taken in popote, their status, and how to record a new one.
type: index
status: current
audience: everyone
last_reviewed: 2026-09-29
tags: [decisions, adr]
---

# Decision records

A decision record captures one choice: the problem, what was decided, what
was rejected and what it costs. Records are the canonical "why"; other pages
link here instead of repeating the argument.

| # | Decision | Status |
| --- | --- | --- |
| 0001 | [mise is the single toolchain entry point](0001-mise-is-the-single-toolchain-entry-point.md) | accepted |
| 0002 | [Documentation is Markdown with a frontmatter contract](0002-documentation-is-markdown-with-a-frontmatter-contract.md) | accepted |
| 0003 | [Scripts are POSIX sh or Python](0003-scripts-are-posix-sh-or-python.md) | accepted |

## Recording a decision

1. Copy [the template](template.md) to `NNNN-<decision-as-a-sentence>.md`
   with the next free number.
2. Fill every section. "Alternatives" and "Consequences" are the reason the
   record exists; do not leave them thin.
3. Add a row to the table above.
4. A record is never rewritten after it is accepted. To change a decision,
   write a new record and set the old one's status to `superseded by NNNN`.
