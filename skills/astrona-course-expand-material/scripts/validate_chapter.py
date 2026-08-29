#!/usr/bin/env python3
"""Perform small deterministic checks on a generated Markdown chapter.

    validate_chapter.py FILE.md [--module] [--with-playground]

--module            The file is an in-place course-module course.md. Require
                    exactly one `#` H1 with no `Chapter N:` prefix (the platform
                    orders modules), a `## Learning objectives` section of 3-6
                    list items, and a `## Before you start` section. Without this
                    flag the file is a standalone chapter and must use the
                    `# Chapter N: <title>` form.
--with-playground   Allow the `<!-- astrona:playground -->` callout and the
                    `astrona run` / `astrona destroy` lines that appear inside
                    "Try it" checkpoints, while still rejecting guided-lab and
                    grading framing.

Always rejected: guided step-by-step sections, `Check your understanding` /
hidden-answer `<details>` quiz blocks, and closing `Keep going` / `Next steps`
sections. Those belong to other skills or nowhere in a chapter.
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

    lines = text.splitlines()

    h1s = re.findall(r"^#[ \t]+(.+?)[ \t]*$", text, re.MULTILINE)
    if module_mode:
        if len(h1s) != 1:
            errors.append(f"expected exactly one '# ' H1, found {len(h1s)}")
        if h1s and re.match(r"Chapter\s+\d+\s*:", h1s[0]):
            errors.append(
                f"module title must not be numbered: {h1s[0]!r} "
                "(drop the 'Chapter N:' prefix)"
            )

        obj_re = re.compile(
            r"^##\s+(learning objectives|objectives|what you'?ll be able to do)\s*$",
            re.IGNORECASE,
        )
        pre_re = re.compile(
            r"^##\s+(before you start|prerequisites|what you need to know first)\s*$",
            re.IGNORECASE,
        )
        obj_idx = next((i for i, ln in enumerate(lines) if obj_re.match(ln)), None)
        if obj_idx is None:
            errors.append("module chapter missing a '## Learning objectives' section")
        else:
            count = 0
            for ln in lines[obj_idx + 1:]:
                if re.match(r"^##\s+\S", ln):
                    break
                if re.match(r"^\s*[-*]\s+\S", ln):
                    count += 1
            if not 3 <= count <= 6:
                errors.append(
                    f"'## Learning objectives' has {count} list items; want 3-6"
                )
        if not any(pre_re.match(ln) for ln in lines):
            errors.append("module chapter missing a '## Before you start' section")
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

    if re.search(r"^#{1,6}\s+check your understanding", text, re.MULTILINE | re.IGNORECASE):
        errors.append(
            "'Check your understanding' section — knowledge checks belong to "
            "astrona-course-generate-assessment, not a course chapter"
        )
    if re.search(r"<summary>\s*(answer|solution)\b", text, re.IGNORECASE):
        errors.append(
            "hidden-answer <details> quiz block — not for a course chapter"
        )
    if re.search(
        r"^#{1,6}\s+(keep going|next steps?|where to go from here|what'?s next)\b",
        text,
        re.MULTILINE | re.IGNORECASE,
    ):
        errors.append(
            "closing 'Keep going' / 'Next steps' section — a chapter ends when "
            "the subject is covered"
        )

    if text.count("```") % 2:
        errors.append("unbalanced fenced code block")

    # No two "> [!TIP]" checkpoints in a row: each must follow prose that
    # explains the concept it exercises. A bare heading between them does not
    # count as explanation.
    tip_re = re.compile(r"^>\s*\[!TIP\]", re.IGNORECASE)
    in_fence = False
    prev_tip_line = None
    prose_since_tip = True
    for lineno, line in enumerate(text.splitlines(), 1):
        stripped = line.strip()
        if stripped.startswith("```"):
            in_fence = not in_fence
            continue
        if in_fence:
            continue
        if tip_re.match(line):
            if prev_tip_line is not None and not prose_since_tip:
                errors.append(
                    f"'> [!TIP]' checkpoint at line {lineno} follows the one at "
                    f"line {prev_tip_line} with no explanation between them"
                )
            prev_tip_line = lineno
            prose_since_tip = False
            continue
        if stripped and not stripped.startswith(">") and not stripped.startswith("#"):
            prose_since_tip = True

    for error in errors:
        print(f"ERROR: {error}")
    return 1 if errors else 0


if __name__ == "__main__":
    raise SystemExit(main())
