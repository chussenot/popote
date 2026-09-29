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

payload=""
if [ "${1:-}" = "prompt-hook" ]; then
  # Turns the harness writes (subagent reports, notifications) are not
  # questions about the code, yet codegraph answers them with several KB of
  # source. Drop them before codegraph sees them.
  # ponytail: codegraph 1.6.1 skips a bare <task-notification> itself but not
  # these; remove this filter once upstream skips harness turns generally.
  payload=$(cat)
  if printf '%s' "$payload" | python3 -c '
import json, sys
try:
    prompt = str(json.load(sys.stdin).get("prompt", ""))
except Exception:
    sys.exit(1)
markers = ("<agent-message", "[Subagent hand-back]", "<task-notification>", "[SYSTEM NOTIFICATION")
sys.exit(0 if any(m in prompt for m in markers) else 1)
'; then
    exit 0
  fi
fi

if [ -n "$mise_bin" ]; then
  if [ "${1:-}" = "prompt-hook" ]; then
    # A prompt hook must never block on a download; only the MCP server may
    # install codegraph on first use.
    MISE_EXEC_AUTO_INSTALL=false
    export MISE_EXEC_AUTO_INSTALL
    printf '%s' "$payload" | "$mise_bin" exec npm:@colbymchenry/codegraph -- codegraph "$@"
    exit $?
  fi
  exec "$mise_bin" exec npm:@colbymchenry/codegraph -- codegraph "$@"
fi

if command -v codegraph >/dev/null 2>&1; then
  if [ "${1:-}" = "prompt-hook" ]; then
    printf '%s' "$payload" | codegraph "$@"
    exit $?
  fi
  exec codegraph "$@"
fi

echo "codegraph: neither mise nor codegraph found; run 'mise install'" >&2
exit 127
