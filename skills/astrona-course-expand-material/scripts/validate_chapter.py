#!/usr/bin/env python3
"""Perform small deterministic checks on a generated Markdown chapter.

    validate_chapter.py FILE.md [--with-playground]

--with-playground allows the `<!-- astrona:playground -->` callout and the
`astrona run` / `astrona destroy` lines that appear inside "Try it" checkpoints,
while still rejecting guided-lab and grading framing.
"""

from pathlib import Path
import re
import sys


def main() -> int:
    args = [a for a in sys.argv[1:] if not a.startswith("--")]
    flags = {a for a in sys.argv[1:] if a.startswith("--")}
    if len(args) != 1 or flags - {"--with-playground"}:
        print("usage: validate_chapter.py FILE.md [--with-playground]")
        return 2
    with_playground = "--with-playground" in flags
    path = Path(args[0])
    text = path.read_text(encoding="utf-8")
    errors = []

    if not re.search(r"^# Chapter \d+:", text, re.MULTILINE):
        errors.append("missing '# Chapter N:' title")

    banned = [
        "Guided Practice Lab",
        "astrona submit",
        "astrona test",
        "PROCTOR:",
    ]
    if not with_playground:
        banned += ["astrona run", "astrona destroy"]
    for phrase in banned:
        if phrase in text:
            errors.append(f"lab/grading framing remains: {phrase!r}")

    if re.search(r"^##\s+Step[- ]by[- ]step", text, re.MULTILINE | re.IGNORECASE):
        errors.append("guided step-by-step section in conceptual material")

    if text.count("```") % 2:
        errors.append("unbalanced fenced code block")

    for error in errors:
        print(f"ERROR: {error}")
    return 1 if errors else 0


if __name__ == "__main__":
    raise SystemExit(main())
