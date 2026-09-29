#!/usr/bin/env sh
# Benchmark the search commands agents run against their classic equivalents,
# on this checkout or on the directory given as $1. Needs hyperfine, rg, fd
# (all in mise.toml). Usage: mise run bench [-- DIR [PATTERN]]
#
# The point is to check the choice of tools on the code you actually have: fd
# beats find on large trees but loses on small ones (thread start-up), and
# rtk's overhead should stay in the noise.
set -eu

dir=${1:-.}
pattern=${2:-def}
runs=${BENCH_RUNS:-10}

for tool in hyperfine rg fd grep find; do
  command -v "$tool" >/dev/null 2>&1 || { echo "error: $tool not found (mise install)" >&2; exit 1; }
done

cd "$dir"
files=$(rg --files | wc -l | tr -d ' ')
echo "corpus: $(pwd) ($files files ripgrep would search), pattern: $pattern"

set -- \
  "grep -rn --exclude-dir=.git $pattern ." \
  "rg -n $pattern" \
  "find . -type f -not -path './.git/*'" \
  "fd --type f --hidden --exclude .git"
if command -v rtk >/dev/null 2>&1; then
  set -- "$@" "rtk rg -n $pattern"
fi

# -N: no intermediate shell, so the numbers are the tools, not sh start-up.
# -i: grep and rg exit 1 when nothing matches; that is a result, not a failure.
hyperfine -N -i --warmup 2 --runs "$runs" --style basic --export-markdown - "$@"
