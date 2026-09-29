#!/usr/bin/env sh
# PreToolUse (Bash): deny a few commands that are never right in this repo.
# Emits a permissionDecision of "deny" with the reason; anything else passes.
#
# Matching is done on command positions only (start of line, or after ; && || |),
# with here-doc bodies removed first, so documentation that *mentions* a
# forbidden command is not blocked.
set -eu
input=$(cat)
cmd=$(printf '%s' "$input" | python3 -c 'import json,sys; print(json.load(sys.stdin).get("tool_input",{}).get("command",""))' 2>/dev/null || true)
[ -n "$cmd" ] || exit 0

# Drop here-doc bodies: from a line containing <<WORD / <<'WORD' / <<-"WORD" to the WORD line.
stripped=$(printf '%s\n' "$cmd" | awk '
  BEGIN { indoc = 0 }
  indoc { if ($0 == term) { indoc = 0 } ; next }
  {
    if (match($0, /<<-?[[:space:]]*[\047"]?[A-Za-z_][A-Za-z0-9_]*[\047"]?/)) {
      t = substr($0, RSTART, RLENGTH)
      gsub(/<<-?[[:space:]]*/, "", t); gsub(/[\047"]/, "", t)
      term = t; indoc = 1
    }
    print
  }')

deny() {
  printf '{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"deny","permissionDecisionReason":"%s"}}\n' "$1"
  exit 0
}

# A command position: start of line, or after ; & | ( ` or $( .
at() { printf '%s\n' "$stripped" | grep -Eq "(^|[;&|(\`][[:space:]]*|\\\$\\([[:space:]]*)$1"; }

if at 'git[[:space:]]+push[^;&|]*(\+main|HEAD:main|[[:space:]]main([[:space:]]|$))'; then
  deny "Direct or forced pushes to main are not allowed; open a pull request from a feature branch."
fi
if at 'git[[:space:]]+(rebase|add)[^;&|]*[[:space:]]-i([[:space:]]|$)'; then
  deny "Interactive git commands hang in an agent shell; use the non-interactive form."
fi
if at 'bd[[:space:]]+edit([[:space:]]|$)'; then
  deny "bd edit opens an interactive editor and would hang; use bd update --title/--description/--notes."
fi
if at 'git[[:space:]]+(add|commit)[^;&|]*(^|[[:space:]])\.env(\.[A-Za-z0-9_-]+)?([[:space:]]|$)' \
   && ! at 'git[[:space:]]+(add|commit)[^;&|]*\.env\.example([[:space:]]|$)'; then
  deny ".env holds secrets and is gitignored; document variables in .env.example instead."
fi
if at 'cargo[[:space:]]+publish([[:space:]]|$)' && ! at 'cargo[[:space:]]+publish[^;&|]*--dry-run'; then
  deny "Agents never publish crates: releases go out from the release workflow on a v* tag (mise run release), and the one-time first publish is done by a human. Use cargo publish --dry-run to check a package."
fi
if at 'git[[:space:]]+commit[^;&|]*--no-verify'; then
  deny "Commit hooks enforce Conventional Commits and the docs gate; fix the finding instead of skipping them."
fi
exit 0
