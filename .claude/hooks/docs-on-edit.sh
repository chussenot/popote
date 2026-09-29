#!/usr/bin/env sh
# PostToolUse (Edit|Write): after a Markdown page under docs/ (or the README) is
# written, check its frontmatter and regenerate docs/llms.txt, so the index
# never lags the pages and a broken page is caught while the agent still has it
# open. A failed check exits 2: Claude Code feeds stderr back to the agent.
set -eu
input=$(cat)
file=$(printf '%s' "$input" | python3 -c 'import json,sys; print(json.load(sys.stdin).get("tool_input",{}).get("file_path",""))' 2>/dev/null || true)
root=${CLAUDE_PROJECT_DIR:-.}
rel=${file#"$root"/}

case "$rel" in
  docs/llms.txt) exit 0 ;;
  docs/*.md|README.md) ;;
  *) exit 0 ;;
esac

cd "$root"
if ! out=$(python3 scripts/docs.py check "$rel" 2>&1); then
  printf '%s\n' "$out" >&2
  exit 2
fi
python3 scripts/docs.py llms >/dev/null 2>&1 || true
exit 0
