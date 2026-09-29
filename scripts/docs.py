#!/usr/bin/env python3
"""Documentation gate and index generator for popote.

Two subcommands, one frontmatter parser, so the check and the index cannot
disagree about what a page declares.

    python3 scripts/docs.py check [PATH ...]   # default: README.md docs
    python3 scripts/docs.py llms [--check]     # write or verify docs/llms.txt

`check` enforces the contract in docs/contributing/documentation-style.md:
frontmatter keys and values, one H1 equal to the title, and relative links
(including #anchors) that resolve. `llms` writes docs/llms.txt, the page index
agents read first (https://llmstxt.org), from the same frontmatter.

Standard library only: the script must run on a bare Python before
`mise install` has finished, and from git hooks.
"""

from __future__ import annotations

import argparse
import datetime as dt
import re
import sys
import unicodedata
from dataclasses import dataclass, field
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
DOCS = ROOT / "docs"
LLMS = DOCS / "llms.txt"

REQUIRED = ("title", "description", "type", "status", "last_reviewed", "tags")
OPTIONAL = ("audience", "owner", "superseded_by")
TYPES = ("index", "tutorial", "how-to", "reference", "explanation", "decision")
STATUSES = ("draft", "current", "deprecated")
AUDIENCES = ("everyone", "contributors", "operators", "agents")
DESCRIPTION_MAX = 200

# Section order in llms.txt; pages inside a section are sorted by path.
SECTIONS = (
    ("index", "Start here"),
    ("tutorial", "Tutorials"),
    ("how-to", "How-to guides"),
    ("reference", "Reference"),
    ("explanation", "Explanation"),
    ("decision", "Decisions"),
)

FENCE = re.compile(r"^(```|~~~)")
LINK = re.compile(r"(?<!!)\[[^\]]*\]\(([^)\s]+)(?:\s+\"[^\"]*\")?\)")
HEADING = re.compile(r"^(#{1,6})\s+(.*?)\s*#*\s*$")


@dataclass
class Page:
    path: Path
    meta: dict[str, object] = field(default_factory=dict)
    body: list[str] = field(default_factory=list)
    body_start: int = 1  # 1-based line number of the first body line
    errors: list[str] = field(default_factory=list)

    @property
    def rel(self) -> str:
        return self.path.relative_to(ROOT).as_posix()

    def error(self, msg: str, line: int | None = None) -> None:
        where = f"{self.rel}:{line}" if line else self.rel
        self.errors.append(f"{where}: {msg}")


# ---------------------------------------------------------------------------
# Parsing
# ---------------------------------------------------------------------------


def parse_scalar(raw: str) -> object:
    raw = raw.strip()
    if raw.startswith("[") and raw.endswith("]"):
        inner = raw[1:-1].strip()
        return [parse_scalar(x) for x in inner.split(",")] if inner else []
    if len(raw) >= 2 and raw[0] == raw[-1] and raw[0] in "\"'":
        return raw[1:-1]
    return raw


def load(path: Path) -> Page:
    """Split a page into frontmatter and body.

    ponytail: a flat `key: value` parser, not YAML. Flow lists (`[a, b]`) and
    quoted strings are supported; nested maps and block lists are rejected with
    a message. Move to PyYAML if the contract ever needs nesting.
    """
    page = Page(path)
    lines = path.read_text(encoding="utf-8").splitlines()
    if not lines or lines[0] != "---":
        page.error("missing frontmatter (first line must be ---)", 1)
        page.body = lines
        return page
    try:
        end = lines.index("---", 1)
    except ValueError:
        page.error("frontmatter is not closed by a --- line", 1)
        return page
    for n, line in enumerate(lines[1:end], start=2):
        if not line.strip() or line.lstrip().startswith("#"):
            continue
        if line[0].isspace() or line.lstrip().startswith("- "):
            page.error("nested or block-style values are not supported; use [a, b]", n)
            continue
        key, sep, value = line.partition(":")
        if not sep:
            page.error(f"not a 'key: value' line: {line!r}", n)
            continue
        key = key.strip()
        if key in page.meta:
            page.error(f"duplicate key '{key}'", n)
        page.meta[key] = parse_scalar(value)
    page.body = lines[end + 1 :]
    page.body_start = end + 2
    return page


def slug(text: str) -> str:
    """GitHub's heading anchor: lowercase, drop punctuation, spaces to hyphens."""
    text = re.sub(r"`([^`]*)`", r"\1", text)
    text = re.sub(r"\[([^\]]*)\]\([^)]*\)", r"\1", text)
    text = unicodedata.normalize("NFKC", text).lower()
    text = "".join(c for c in text if c.isalnum() or c in " -_")
    return text.replace(" ", "-")


def outside_fences(page: Page):
    """Yield (line_number, line) for body lines outside fenced code blocks."""
    fenced = False
    for n, line in enumerate(page.body, start=page.body_start):
        if FENCE.match(line.lstrip()):
            fenced = not fenced
            continue
        if not fenced:
            yield n, line


def anchors(page: Page) -> set[str]:
    seen: dict[str, int] = {}
    out: set[str] = set()
    for _, line in outside_fences(page):
        m = HEADING.match(line)
        if not m:
            continue
        base = slug(m.group(2))
        count = seen.get(base, 0)
        seen[base] = count + 1
        out.add(base if count == 0 else f"{base}-{count}")
    return out


# ---------------------------------------------------------------------------
# Checks
# ---------------------------------------------------------------------------


def check_meta(page: Page) -> None:
    meta = page.meta
    for key in REQUIRED:
        if key not in meta or meta[key] in ("", []):
            page.error(f"frontmatter missing '{key}'")
    for key in meta:
        if key not in REQUIRED + OPTIONAL:
            page.error(f"unknown frontmatter key '{key}' (allowed: {', '.join(REQUIRED + OPTIONAL)})")

    def one_of(key: str, allowed: tuple[str, ...]) -> None:
        value = meta.get(key)
        if value and value not in allowed:
            page.error(f"{key} '{value}' is not one of: {', '.join(allowed)}")

    one_of("type", TYPES)
    one_of("status", STATUSES)
    one_of("audience", AUDIENCES)

    desc = meta.get("description")
    if isinstance(desc, str) and desc:
        if len(desc) > DESCRIPTION_MAX:
            page.error(f"description is {len(desc)} characters; keep it under {DESCRIPTION_MAX}")
        if not desc.endswith("."):
            page.error("description must be one full sentence ending with a period")

    reviewed = meta.get("last_reviewed")
    if isinstance(reviewed, str) and reviewed:
        try:
            day = dt.date.fromisoformat(reviewed)
        except ValueError:
            page.error(f"last_reviewed '{reviewed}' is not an ISO date (YYYY-MM-DD)")
        else:
            if day > dt.date.today():
                page.error(f"last_reviewed {reviewed} is in the future")

    tags = meta.get("tags")
    if tags is not None and not isinstance(tags, list):
        page.error("tags must be a flow list, e.g. [docs, harness]")

    if meta.get("status") == "deprecated" and not meta.get("superseded_by"):
        page.error("a deprecated page names its replacement in 'superseded_by'")


def check_title(page: Page) -> None:
    h1 = [(n, m.group(2)) for n, line in outside_fences(page) if (m := HEADING.match(line)) and len(m.group(1)) == 1]
    if not h1:
        page.error("no H1 heading; the page starts with '# <title>'")
        return
    if len(h1) > 1:
        page.error(f"{len(h1)} H1 headings; keep exactly one", h1[1][0])
    title = page.meta.get("title")
    if isinstance(title, str) and title and h1[0][1] != title:
        page.error(f"H1 '{h1[0][1]}' differs from frontmatter title '{title}'", h1[0][0])


def check_links(page: Page, cache: dict[Path, Page]) -> None:
    for n, line in outside_fences(page):
        line = re.sub(r"`[^`]*`", "", line)  # links inside inline code are examples
        for target in LINK.findall(line):
            if re.match(r"^[a-z][a-z0-9+.-]*:", target) or target.startswith("//"):
                continue  # external: http:, https:, mailto:
            path_part, _, anchor = target.partition("#")
            dest = (page.path.parent / path_part).resolve() if path_part else page.path
            if not dest.exists():
                page.error(f"broken link: {target}", n)
                continue
            if anchor and dest.suffix == ".md":
                other = cache.get(dest) or cache.setdefault(dest, load(dest))
                if anchor not in anchors(other):
                    page.error(f"broken anchor: {target}", n)


def collect(targets: list[str]) -> list[Path]:
    files: list[Path] = []
    for t in targets:
        p = (ROOT / t).resolve() if not Path(t).is_absolute() else Path(t)
        if p.is_dir():
            files.extend(sorted(p.rglob("*.md")))
        elif p.suffix == ".md" and p.exists():
            files.append(p)
        else:
            print(f"{t}: not a Markdown file or directory", file=sys.stderr)
            sys.exit(2)
    return files


def cmd_check(targets: list[str]) -> int:
    cache: dict[Path, Page] = {}
    errors: list[str] = []
    files = collect(targets or ["README.md", "docs"])
    for path in files:
        page = cache.setdefault(path, load(path))
        if not page.errors:
            check_meta(page)
            check_title(page)
            check_links(page, cache)
        errors.extend(page.errors)
    for e in errors:
        print(e, file=sys.stderr)
    if errors:
        print(f"docs check failed: {len(errors)} finding(s) in {len(files)} page(s)", file=sys.stderr)
        return 1
    print(f"docs ok: {len(files)} page(s)")
    return 0


# ---------------------------------------------------------------------------
# llms.txt
# ---------------------------------------------------------------------------


def render_llms() -> str:
    readme = load(ROOT / "README.md")
    pages = [load(p) for p in sorted(DOCS.rglob("*.md"))]
    out = [
        f"# {readme.meta.get('title', 'popote')}",
        "",
        f"> {readme.meta.get('description', '')}",
        "",
        "Generated by `mise run docs:llms` from page frontmatter; do not edit.",
        "Paths are relative to this file. Deprecated pages are omitted.",
    ]
    for kind, heading in SECTIONS:
        rows = [p for p in pages if p.meta.get("type") == kind and p.meta.get("status") != "deprecated"]
        if not rows:
            continue
        out += ["", f"## {heading}", ""]
        for p in rows:
            rel = p.path.relative_to(DOCS).as_posix()
            draft = " (draft)" if p.meta.get("status") == "draft" else ""
            out.append(f"- [{p.meta.get('title', rel)}]({rel}){draft}: {p.meta.get('description', '')}")
    return "\n".join(out) + "\n"


def cmd_llms(check: bool) -> int:
    want = render_llms()
    have = LLMS.read_text(encoding="utf-8") if LLMS.exists() else ""
    if check:
        if want != have:
            print("docs/llms.txt is stale; run `mise run docs:llms`", file=sys.stderr)
            return 1
        print("llms.txt ok")
        return 0
    if want != have:
        LLMS.write_text(want, encoding="utf-8")
        print(f"wrote {LLMS.relative_to(ROOT)}")
    return 0


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__.split("\n\n")[0])
    sub = parser.add_subparsers(dest="cmd", required=True)
    p_check = sub.add_parser("check", help="validate frontmatter, titles and links")
    p_check.add_argument("paths", nargs="*", help="files or directories (default: README.md docs)")
    p_llms = sub.add_parser("llms", help="write docs/llms.txt")
    p_llms.add_argument("--check", action="store_true", help="fail if docs/llms.txt is stale")
    args = parser.parse_args()
    if args.cmd == "check":
        return cmd_check(args.paths)
    return cmd_llms(args.check)


if __name__ == "__main__":
    sys.exit(main())
