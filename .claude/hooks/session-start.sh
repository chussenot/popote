#!/usr/bin/env sh
# SessionStart: make the mise toolchain available to the session.
#
# Cloud sessions (CLAUDE_CODE_REMOTE=true) start from a fresh container, so the
# hook installs mise and every tool in mise.toml, exports the tool paths
# through CLAUDE_ENV_FILE so later Bash calls see them, installs the git hooks
# and builds the codegraph index. Local sessions are left
# alone: a developer runs `mise install` once, and a hook that silently installs
# software on a workstation is a surprise nobody asked for.
#
# Never fails the session: every step is best-effort and reports what is missing.
set -u

root=${CLAUDE_PROJECT_DIR:-$(pwd)}
cd "$root" || exit 0

if [ "${CLAUDE_CODE_REMOTE:-}" != "true" ]; then
  command -v mise >/dev/null 2>&1 || echo "popote: mise not found; install it (https://mise.jdx.dev) and run 'mise install'."
  exit 0
fi

PATH="$HOME/.local/bin:$PATH"
export PATH

if ! command -v mise >/dev/null 2>&1; then
  curl -fsSL https://mise.run | sh >/dev/null 2>&1 || { echo "popote: mise install failed"; exit 0; }
fi

mise trust --quiet "$root/mise.toml" >/dev/null 2>&1 || true
mise install --yes >/dev/null 2>&1 || echo "popote: 'mise install' reported failures; run it to see which tool."

# ponytail: some cloud environments cannot reach the GitHub releases API for
# chussenot/pact, so mise's github backend fails. Building from the git source
# costs ~30 s once per container. Drop this fallback when mise resolves it.
pact_outside_mise=false
if ! mise which pact >/dev/null 2>&1; then
  pact_outside_mise=true
  if command -v pact >/dev/null 2>&1; then
    :
  elif command -v cargo >/dev/null 2>&1; then
    cargo install --git https://github.com/chussenot/pact --locked --root "$HOME/.local" >/dev/null 2>&1 \
      || echo "popote: pact build from source failed."
  else
    echo "popote: pact unavailable (no release access and no cargo)."
  fi
fi

# Persist the toolchain for the rest of the session.
if [ -n "${CLAUDE_ENV_FILE:-}" ]; then
  mise env --shell bash >>"$CLAUDE_ENV_FILE" 2>/dev/null || true
  # shellcheck disable=SC2016 # $PATH must expand when the env file is sourced
  printf 'export PATH="%s/.local/bin:$PATH"\n' "$HOME" >>"$CLAUDE_ENV_FILE"
  # With pact outside mise, `mise run` would retry the failing install on
  # every task; stop it from auto-installing in this session.
  if [ "$pact_outside_mise" = true ]; then
    echo 'export MISE_TASK_RUN_AUTO_INSTALL=false' >>"$CLAUDE_ENV_FILE"
  fi
fi

# Git hooks and the codegraph index are local state; a fresh clone has neither.
eval "$(mise env --shell bash 2>/dev/null)" 2>/dev/null || true
sh scripts/setup-hooks.sh >/dev/null 2>&1 || echo "popote: git hooks not installed; run 'mise run setup'."
# Project rtk filters apply only once trusted on this machine. The container
# is disposable and the filters are this repository's own, so trust them here;
# on a workstation the developer reviews them once with `mise run rtk:trust`.
if command -v rtk >/dev/null 2>&1; then
  rtk trust --yes >/dev/null 2>&1 || echo "popote: rtk filters not trusted; run 'rtk trust'."
fi
if command -v codegraph >/dev/null 2>&1 && [ ! -f .codegraph/codegraph.db ]; then
  codegraph init --yes >/dev/null 2>&1 || echo "popote: codegraph index not built; run 'mise run graph'."
fi
exit 0
