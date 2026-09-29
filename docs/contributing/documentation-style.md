---
title: Documentation style guide
description: How popote documentation is written and structured, and the frontmatter contract every page must meet.
type: reference
status: current
audience: contributors
last_reviewed: 2026-09-29
tags: [docs, style, contributing]
---

# Documentation style guide

Documentation here is read by engineers who will change the system and by
agents that act on it without asking. Both need the same thing: accurate
pages, each with one job, that say why before how. This guide is the
contract. `scripts/docs.py` enforces the mechanical parts; review enforces
the rest. The `docs-writer` agent applies it by default.

## Format

- Markdown only, under `docs/`, plus `README.md` at the root.
- File names are lowercase, hyphen-separated, and describe the content:
  `reference/toolchain.md`, not `tools-v2.md`.
- One H1 per page, identical to the frontmatter `title`.
- Sentence-case headings. Do not skip levels.

## Frontmatter

Every page starts with a YAML block of flat `key: value` lines. Lists use flow
style (`[a, b]`). Nested maps and block lists are rejected.

```yaml
---
title: Toolchain reference
description: Every tool pinned in mise.toml, what it is for, and every mise task.
type: reference
status: current
audience: contributors
last_reviewed: 2026-09-29
tags: [mise, tooling]
---
```

| Key | Required | Values | Rule |
| --- | --- | --- | --- |
| `title` | yes | text | Identical to the H1 |
| `description` | yes | one sentence | Under 200 characters, ends with a period; becomes the page's line in `docs/llms.txt` |
| `type` | yes | `index`, `tutorial`, `how-to`, `reference`, `explanation`, `decision` | One Diátaxis type per page, see below |
| `status` | yes | `draft`, `current`, `deprecated` | Draft pages are flagged in `llms.txt`; deprecated pages are dropped from it |
| `last_reviewed` | yes | `YYYY-MM-DD` | Date the page was last checked against the code; not in the future |
| `tags` | yes | flow list | Short lowercase topics |
| `audience` | no | `everyone`, `contributors`, `operators`, `agents` | Who the page is written for |
| `owner` | no | text | Person or team to ask |
| `superseded_by` | when deprecated | relative path | The page that replaces this one |

Unknown keys fail the check, so a typo (`last_review`) cannot pass silently.

## Page types

Each page does one of these jobs. A page that tries to do two gets split.

| `type` | Reader's situation | Shape |
| --- | --- | --- |
| `tutorial` | Learning; wants a guaranteed first success | Numbered steps that always work, with the expected result after each |
| `how-to` | Has a goal already | Prerequisites, numbered steps, verification; no background |
| `reference` | Looking something up | Complete, dry, mostly tables; mirrors the structure of the thing described |
| `explanation` | Wants to understand why | Problem, decision, alternatives, cost; prose and diagrams |
| `decision` | Wants the rationale for one choice | The [decision record template](../decisions/template.md) |
| `index` | Wants to find a page | Grouped links with one line each |

## Voice

- Open with the problem the page solves or the question it answers, in one or
  two sentences, before any mechanism.
- Present tense, active voice, second person for instructions ("run", "you").
- One idea per sentence. Short paragraphs.
- No marketing language, no filler ("simply", "just", "easily", "note that"),
  no emphasis for its own sake, no em dashes.
- Describe a setting by what goes wrong at each extreme, not only by its type
  and default. A limit names what it protects.
- A claim you could not verify says so where it is made.

## Elements

- **Tables** for parallel facts: tools, tasks, variables, hooks.
- **Fenced code blocks** with a language tag for commands, config and output.
  Commands are copy-pasteable: no `$` prompt; any placeholder is explained.
- **Mermaid** for a flow or structure a paragraph would describe worse. Keep
  diagrams small enough to read without zooming.
- **Links** are relative (`../reference/harness.md#subagents`). The check
  verifies the file and the anchor exist.
- Name a file, flag or function only when the reader has to go there.

## One fact, one place

A fact lives on one page. Other pages link to it. The "why" of an
architectural choice lives in its decision record; other pages state the
conclusion in one sentence and link it.

## Checks

| Check | Where it runs |
| --- | --- |
| `python3 scripts/docs.py check` | Claude Code edit hook (the edited page), pre-commit, `mise run check`, CI |
| `python3 scripts/docs.py llms --check` | pre-commit, `mise run check`, CI |

`docs.py check` validates the frontmatter keys and values, one H1 equal to
the title, and every relative link and anchor. `docs/llms.txt` is generated
by `mise run docs:llms`; never edit it by hand.

## New page checklist

1. Pick the one `type` the page is.
2. Write the frontmatter, then the H1, then the problem statement.
3. Link the page from `docs/index.md`, and from the README table if it is a
   top-level entry point.
4. Run `mise run docs:llms` and `mise run docs:check`.
5. Commit as `docs(<scope>): <summary>`.
