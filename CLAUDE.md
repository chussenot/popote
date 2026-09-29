# CLAUDE.md

Claude Code reads this file; every other agent reads `AGENTS.md`. The
protocol lives in `AGENTS.md` and is imported below, so there is one copy to
keep current. Add here only what is specific to Claude Code.

## Claude Code specifics

- Delegate documentation work to the `docs-writer` subagent
  (`.claude/agents/docs-writer.md`). It knows the frontmatter contract and the
  style guide, and runs `mise run docs:check` before it reports.
- Hooks in `.claude/settings.json`:
  - `SessionStart`: installs the toolchain in cloud sessions, then `bd prime`.
  - `PreToolUse(Bash)`: denies commands that are never right here, then lets
    rtk compress command output.
  - `PostToolUse(Edit|Write)`: on a `docs/` page, checks its frontmatter and
    regenerates `docs/llms.txt`. A broken page is reported back to you.
  - `UserPromptSubmit`: `codegraph prompt-hook` adds graph context to
    structural questions ("how does X reach Y").
- The `codegraph` MCP server (`.mcp.json`) answers code questions from a
  local index; prefer `codegraph_explore` over grep-and-read loops. Build the
  index with `mise run graph` if `.codegraph/` is missing.
- The ponytail plugin is enabled for this project; trust the marketplace when
  Claude Code asks.

<!-- rtk-instructions v2 -->
# Command output

Command output here is condensed to save tokens, keeping every signal and
dropping costly noise. Treat it as the complete result: run commands
normally, and batch related commands into one call to avoid extra turns.
Truncated results state their recovery path in their own output. Re-run a
command as `rtk proxy <cmd>` only when its result is unusable: empty when
output was clearly expected, contradicting its exit code, or garbled.
<!-- /rtk-instructions -->

<!-- pact:begin hash:bec01292 -->
## pact coordination protocol

Claude Code loads this file, not `AGENTS.md`, so the protocol is imported
here instead of copied — one source of truth, in the file the other agents
already read. Run `pact init` to refresh it.

@AGENTS.md
<!-- pact:end -->
