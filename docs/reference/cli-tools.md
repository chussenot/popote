---
title: Command-line tools for agents
description: The fast search and data tools in the toolchain, how rtk handles each, the repository defaults, and the benchmarks behind the choice.
type: reference
status: current
audience: contributors
last_reviewed: 2026-09-29
tags: [tooling, performance, rtk, ripgrep, reference]
---

# Command-line tools for agents

An agent spends much of a session searching: for a symbol, a file, a config
key. Each search is a tool call the session waits on, and each result is
context it pays for. The toolchain therefore ships the fastest single-purpose
tool for each kind of search, and every one of them reaches the agent through
rtk, either with rtk's built-in filter or with a project filter.

The rules agents follow are in the "Shell tools" table in `AGENTS.md`; this
page is the detail behind it.

## Tools

| Tool | Replaces | rtk handling | Read-only |
| --- | --- | --- | --- |
| `rg` (ripgrep) | `grep -r` | Built in: `rtk rg`, results grouped by file and capped | yes (except `--pre`) |
| `ast-grep` | regex over code | Built in: `rtk ast-grep`, matches grouped by file | yes, unless `-U`/`--update-all` |
| `fd` | `find` | Project filter: long lists capped at 150 lines | yes, unless `-x`/`-X` |
| `jq` | ad hoc JSON parsing | Built in: output capped at 40 lines | yes |
| `yq` (mikefarah v4) | sed or grep over YAML, TOML, XML | Project filter: output capped at 60 lines | yes, unless `-i` |
| `sd` | `sed -i` | None; it prints nothing on success | no, it edits files |
| `scc` | `wc -l`, cloc | Project filter: table rules and cost estimate removed | yes |
| `hyperfine` | `time` | None | runs the commands it is given |

Tools considered and left out: `eza` and `bat` (decoration for humans, and
rtk already condenses `ls` and `cat`), `delta` and `difftastic` (pagers for
humans; rtk condenses `diff`), `fzf` (interactive), and `jaq` (faster than
`jq`, but rtk only recognises `jq`, so its output would reach the agent
unfiltered).

## rtk runs what the agent asked for

rtk never substitutes one engine for another. `grep -rn` is rewritten to
`rtk grep -rn`, which still runs GNU grep. The speed of `rg` is only gained
when the agent calls `rg`, which is why `AGENTS.md` says so explicitly.

Claude Code's built-in Grep tool already uses ripgrep; the rule matters for
searches run through Bash, and for Codex and Cursor.

## Repository defaults

### ripgrep: `.ripgreprc`

`mise.toml` sets `RIPGREP_CONFIG_PATH` to the repository's `.ripgreprc`:

| Flag | Why |
| --- | --- |
| `--hidden` | `.claude/`, `.github/`, `.beads/` and `.rtk/` hold configuration; without it an agent concludes they do not exist |
| `--glob=!.git/` | Keeps git's object store out of `--hidden` results |
| `--max-columns=240` and `--max-columns-preview` | A match on a minified or JSONL line prints a preview instead of the whole line |

`.gitignore` still applies, so `.codegraph/`, `.beads` databases and caches
are not searched. Pass `--no-config` to bypass the file.

### fd

fd has no configuration file. It skips dot-directories unless given `-H`,
and respects `.gitignore` like ripgrep.

### rtk project filters: `.rtk/filters.toml`

Filters for `fd`, `yq` and `scc`, with inline tests (`mise run rtk:verify`).
rtk applies a project filter only after it is trusted on the machine, and
trust is tied to the file's hash:

| Where | How trust happens |
| --- | --- |
| Workstation | You review and trust once: `mise run rtk:trust`. Again after any change to the file |
| Cloud session | The session-start hook runs `rtk trust --yes` |
| CI | Not needed; CI does not run agents |

An untrusted filter is skipped silently: the command still runs, only
without the condensed output.

## Flags that differ from grep

| Flag | grep | rg |
| --- | --- | --- |
| `-E` | Extended regex | `--encoding`; rg regex is already extended, drop the flag |
| `-r` | Recursive | `--replace`; rg is recursive by default |
| `-i`, `-n`, `-l`, `-w`, `-v` | Same | Same |
| `--include='*.py'` | File filter | `-g '*.py'`, or `-t py` for a file type |

## Benchmarks

Measured on 2026-09-29 in a 4-core cloud container, with `hyperfine -N`
(no intermediate shell), warm cache, 8 to 15 runs each. Relative figures are
more stable across machines than absolute ones.

### Medium tree: a TypeScript project, about 1,200 files, 139 MB

| Command | Mean | Relative |
| --- | ---: | ---: |
| `rg -n resolveImport` | 18 ms | 1.0 |
| `rtk rg -n resolveImport` | 22 ms | 1.2 |
| `rtk grep -rn resolveImport .` | 72 ms | 3.9 |
| `grep -rn --exclude-dir=.git resolveImport .` | 468 ms | 25.7 |
| `rg -ni 'function\s+\w+Graph'` | 22 ms | 1.0 |
| `grep -rniE 'function\s+\w+Graph' --exclude-dir=.git .` | 479 ms | 21.5 |
| `find . -name '*.ts' -not -path './.git/*'` | 3.7 ms | 1.0 |
| `fd -e ts` | 8.3 ms | 2.2 |

### Large tree: about 79,000 files

| Command | Mean | Relative |
| --- | ---: | ---: |
| `fd -u -g '*.h'` over the tree | 51 ms | 1.0 |
| `find -name '*.h'` over the tree | 124 ms | 2.4 |

### What the numbers say

- **Content search is where the time goes, and rg wins it by more than an
  order of magnitude.** rtk's overhead on top of rg is a few milliseconds.
- **fd is not faster on small trees.** Its threads cost more than they save
  below a few thousand files, and it wins 2.4x on the large tree. On a small
  tree it is chosen for its output (gitignore-aware, so fewer irrelevant
  paths reach the context), not its speed.
- **On popote today every tool finishes in under 15 ms.** The choice pays
  off as code lands. `mise run bench` reruns the comparison on the current
  checkout, or on any directory: `mise run bench -- ../other-repo`.
