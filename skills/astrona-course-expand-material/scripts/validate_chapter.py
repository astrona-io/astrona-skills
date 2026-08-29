#!/usr/bin/env python3
"""Perform small deterministic checks on a generated Markdown chapter.

    validate_chapter.py FILE.md [--module] [--with-playground]

--module            The file is an in-place course-module course.md. Require
                    exactly one `#` H1 and forbid a `Chapter N:` prefix in it
                    (the platform orders modules; a numbered title makes no
                    sense). Without this flag the file is a standalone chapter
                    and must use the `# Chapter N: <title>` form.
--with-playground   Allow the `<!-- astrona:playground -->` callout and the
                    `astrona run` / `astrona destroy` lines that appear inside
                    "Try it" checkpoints, while still rejecting guided-lab and
                    grading framing.
"""

from pathlib import Path
import re
import sys

KNOWN_FLAGS = {"--module", "--with-playground"}


def main() -> int:
    args = [a for a in sys.argv[1:] if not a.startswith("--")]
    flags = {a for a in sys.argv[1:] if a.startswith("--")}
    if len(args) != 1 or flags - KNOWN_FLAGS:
        print("usage: validate_chapter.py FILE.md [--module] [--with-playground]")
        return 2
    module_mode = "--module" in flags
    with_playground = "--with-playground" in flags
    path = Path(args[0])
    text = path.read_text(encoding="utf-8")
    errors = []

    h1s = re.findall(r"^#[ \t]+(.+?)[ \t]*$", text, re.MULTILINE)
    if module_mode:
        if len(h1s) != 1:
            errors.append(f"expected exactly one '# ' H1, found {len(h1s)}")
        if h1s and re.match(r"Chapter\s+\d+\s*:", h1s[0]):
            errors.append(
                f"module title must not be numbered: {h1s[0]!r} "
                "(drop the 'Chapter N:' prefix)"
            )
    else:
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
