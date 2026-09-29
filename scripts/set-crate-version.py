#!/usr/bin/env python3
"""Set the package version in a crate's Cargo.toml.

    python3 scripts/set-crate-version.py crates/popote/Cargo.toml 0.2.0

Called by cocogitto's pre_bump_hooks (cog.toml) so the crate version and the
release tag never disagree. Rewrites the first `version = "..."` line of the
[package] table and nothing else, keeping comments and layout.

ponytail: a line rewrite, not a TOML parser (tomllib cannot write). It
relies on `version` being a plain string inside [package], which the release
workflow's tag check would catch if it ever stopped being true.
"""

from __future__ import annotations

import re
import sys
from pathlib import Path

SEMVER = re.compile(r"^\d+\.\d+\.\d+(?:-[0-9A-Za-z.-]+)?(?:\+[0-9A-Za-z.-]+)?$")


def main() -> int:
    if len(sys.argv) != 3:
        print(__doc__.strip().splitlines()[2].strip(), file=sys.stderr)
        return 2
    path, version = Path(sys.argv[1]), sys.argv[2]
    if not SEMVER.match(version):
        print(f"not a semantic version: {version}", file=sys.stderr)
        return 2

    lines = path.read_text(encoding="utf-8").splitlines(keepends=True)
    in_package = False
    for i, line in enumerate(lines):
        stripped = line.strip()
        if stripped.startswith("["):
            in_package = stripped == "[package]"
            continue
        if in_package and re.match(r'^version\s*=\s*"[^"]*"', stripped):
            lines[i] = re.sub(r'"[^"]*"', f'"{version}"', line, count=1)
            path.write_text("".join(lines), encoding="utf-8")
            print(f"{path}: version = {version}")
            return 0
    print(f"{path}: no version line in [package]", file=sys.stderr)
    return 1


if __name__ == "__main__":
    sys.exit(main())
