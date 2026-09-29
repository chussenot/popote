#!/usr/bin/env sh
# Run codegraph through mise, for callers that start without an activated
# shell: Claude Code launches MCP servers and hooks with the environment it
# was started with, not the one `mise activate` or the session-start hook
# builds. Going through `mise exec` gives codegraph the pinned binary and the
# [env] of mise.toml (CODEGRAPH_TELEMETRY=0 among them).
#
# Usage: scripts/codegraph.sh <codegraph arguments>
#   MCP server:  scripts/codegraph.sh serve --mcp
#   Prompt hook: scripts/codegraph.sh prompt-hook
#
# Falls back to a codegraph already on PATH, and exits 127 when neither mise
# nor codegraph can be found (a fresh container before the session-start hook
# has installed them; reconnect the server with /mcp once it has).
set -eu

root=$(cd "$(dirname "$0")/.." && pwd)
cd "$root"

mise_bin=$(command -v mise 2>/dev/null || true)
[ -n "$mise_bin" ] || { [ -x "$HOME/.local/bin/mise" ] && mise_bin="$HOME/.local/bin/mise"; }

if [ -n "$mise_bin" ]; then
  # A prompt hook must never block on a download; only the MCP server may
  # install codegraph on first use.
  if [ "${1:-}" = "prompt-hook" ]; then
    MISE_EXEC_AUTO_INSTALL=false
    export MISE_EXEC_AUTO_INSTALL
  fi
  exec "$mise_bin" exec npm:@colbymchenry/codegraph -- codegraph "$@"
fi

if command -v codegraph >/dev/null 2>&1; then
  exec codegraph "$@"
fi

echo "codegraph: neither mise nor codegraph found; run 'mise install'" >&2
exit 127
