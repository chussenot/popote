#!/usr/bin/env sh
# PreToolUse (Bash): hand the command to rtk, which rewrites it so its output
# reaches the agent condensed. A project-level hook rather than `rtk init -g`,
# so every clone and every cloud session gets it without touching ~/.claude.
# Passes through untouched when rtk is not installed.
set -eu
if command -v rtk >/dev/null 2>&1; then
  # rtk warns on stderr that no global hook is installed; this project hook is it.
  exec rtk hook claude 2>/dev/null
fi
cat >/dev/null
exit 0
