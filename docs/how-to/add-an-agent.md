---
title: Add an agent to the harness
description: Create a Claude Code subagent for popote that follows the repository conventions and passes review.
type: how-to
status: current
audience: contributors
last_reviewed: 2026-09-29
tags: [harness, agents, claude-code]
---

# Add an agent to the harness

Use this when a kind of task recurs often enough that a dedicated prompt,
tool list and procedure would do it better than a general session. The
`docs-writer` agent is the reference implementation.

## Before you start

- A task that a skill or a `mise` task already covers does not need an agent.
- An agent that only reads (an auditor, a reviewer) gets no `Edit` or
  `Write` tools. Least privilege keeps a reviewer from quietly fixing what it
  should report.

## Steps

1. Create `.claude/agents/<name>.md`. The name is a role, lowercase and
   hyphenated: `test-writer`, `config-reviewer`.

2. Write the frontmatter:

   ```yaml
   ---
   name: test-writer
   description: Writes and maintains tests for scripts/. Use when a script changes or a bug needs a regression test.
   tools: Read, Grep, Glob, Edit, Write, Bash
   model: inherit
   color: blue
   ---
   ```

   The `description` decides when Claude Code delegates to the agent. Start
   with what it does, then "Use when…" with concrete triggers.

3. Write the body in this order:
   - **Role and reader**: one paragraph on what the agent produces and who
     consumes it.
   - **Source of truth**: which files it must read first, and that code wins
     over prose.
   - **Rules**: the conventions it enforces, linked to the page that owns
     them rather than copied.
   - **Procedure**: numbered steps, starting with `pact lease acquire` for
     the files it will write and ending with the gate it must pass
     (`mise run check` or a narrower task) and a Conventional Commit.
   - **Report**: what it returns to the caller.

4. Add the agent to the subagents table in
   [the harness reference](../reference/harness.md#subagents), and mention it
   in `CLAUDE.md` if sessions should delegate to it by default.

5. If the agent needs a new command without a permission prompt, add the
   narrowest matching rule to `permissions.allow` in `.claude/settings.json`.

## Verify

1. Run `mise run check`. It must pass.
2. Start a new Claude Code session and run `/agents`. The new agent is
   listed.
3. Give the session a task matching the description, without naming the
   agent. Claude Code delegates to it.
