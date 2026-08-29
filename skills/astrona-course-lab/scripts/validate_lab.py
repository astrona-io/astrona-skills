#!/usr/bin/env python3
"""Structural check for an Astrona hands-on lab.

Usage:
    validate_lab.py PATH
    validate_lab.py SECTION_ID MODULE_ID        # from the course root
    validate_lab.py SECTION_ID MODULE_ID playground

The two-/three-arg form resolves to `sections/<SECTION_ID>/<MODULE_ID>/`
(plus `playground/` when that word is passed, or automatically when the module
dir has no config.yaml of its own but does have a playground/ subdir).

PATH may be:
  * a lab directory (must contain config.yaml)
  * a playground directory (dir named `playground` or a config.yaml marked
    "Playground") — checked as an ungraded environment: no validation/testing
  * a config.yaml file
  * a single markdown guide (legacy: checks lab-doc headings + fenced blocks)

No third-party deps. YAML is inspected with light regex, not fully parsed.
"""

from __future__ import annotations

import re
import sys
from pathlib import Path

DOC_HEADINGS = ("## Objective", "## Prerequisites", "## Starting state", "## Verify the result")


def check_markdown(path: Path) -> list[str]:
    text = path.read_text(encoding="utf-8")
    errors = [f"missing heading {h!r}" for h in DOC_HEADINGS if h not in text]
    if text.count("```") % 2:
        errors.append("unbalanced fenced code blocks")
    return errors


def _refs(config_text: str, key: str) -> list[str]:
    """Collect `source:`/`<key>:` path values that look like repo-relative files."""
    out = []
    for m in re.finditer(rf'^\s*{key}:\s*["\']?([^"\'\n]+)["\']?\s*$', config_text, re.M):
        val = m.group(1).strip()
        if not val:
            continue
        if val.startswith(("http://", "https://", "oci:")):
            continue
        # container image ref, e.g. ghcr.io/org/img:tag — not a repo-relative path
        if re.match(r'[\w.-]+\.[\w.-]+/', val):
            continue
        out.append(val)
    return out


def _referenced_paths(text: str) -> set[str]:
    return set(_refs(text, "source")) | {
        v for k in ("prerequisites", "examQuestion", "caseStudy", "guide")
        for v in _refs(text, k)
    }


def is_playground(lab_dir: Path, text: str) -> bool:
    """A playground is an ungraded environment-only lab."""
    if lab_dir.name == "playground":
        return True
    return bool(re.search(r'^#.*\bPlayground\b', text, re.M))


def check_playground_dir(lab_dir: Path, text: str) -> list[str]:
    errors: list[str] = []

    if not re.search(r'^\s*name:\s*\S', text, re.M):
        errors.append("config.yaml: metadata.name is not set")
    if "bootstrap:" not in text:
        errors.append("config.yaml: playground has no bootstrap block — nothing prepares the machine")
    if "validation:" in text or "testing:" in text:
        errors.append("config.yaml: a playground is ungraded — remove the validation/testing block")

    for rel in sorted(_referenced_paths(text)):
        if not (lab_dir / rel).exists():
            errors.append(f"config.yaml references missing path: {rel}")

    for rel in sorted(_refs(text, "source")):
        p = lab_dir / rel
        if p.is_file() and p.suffix == ".sh" and p.stat().st_size == 0:
            errors.append(f"empty script: {rel}")

    if not _refs(text, "guide"):
        errors.append("config.yaml: metadata.docs.guide not set (recommended — points at docs/overview.md)")

    return errors


def check_lab_dir(lab_dir: Path) -> list[str]:
    errors: list[str] = []
    config = lab_dir / "config.yaml"
    if not config.is_file():
        return [f"no config.yaml in {lab_dir}"]

    text = config.read_text(encoding="utf-8")

    if is_playground(lab_dir, text):
        return check_playground_dir(lab_dir, text)

    if not re.search(r'^\s*name:\s*\S', text, re.M):
        errors.append("config.yaml: metadata.name is not set")
    if "validation:" not in text:
        errors.append("config.yaml: no validation block")
    elif not re.search(r'^\s*(checks|script|scripts):', text, re.M):
        errors.append("config.yaml: validation block has no checks/script/scripts")

    # every file the config points at must exist
    referenced = _referenced_paths(text)
    for rel in sorted(referenced):
        if not (lab_dir / rel).exists():
            errors.append(f"config.yaml references missing path: {rel}")

    # docs pointers are recommended
    for k in ("prerequisites", "examQuestion", "guide"):
        if not _refs(text, k):
            errors.append(f"config.yaml: metadata.docs.{k} not set (recommended)")

    # a reference solution should exist for `astrona test`
    if "testing:" not in text:
        errors.append("config.yaml: no testing block (reference solution for `astrona test`)")

    # validation scripts must be non-empty and look like pass/fail scripts
    for rel in sorted(_refs(text, "source")):
        p = lab_dir / rel
        if p.is_file() and p.suffix == ".sh" and p.stat().st_size == 0:
            errors.append(f"empty script: {rel}")

    return errors


def resolve_ids(args: list[str]) -> Path:
    """`SECTION_ID MODULE_ID [playground]` -> a directory under sections/."""
    section, module = args[0], args[1]
    want_playground = len(args) == 3 and args[2] == "playground"
    base = Path("sections") / section / module
    if want_playground:
        return base / "playground"
    if not (base / "config.yaml").is_file() and (base / "playground").is_dir():
        return base / "playground"
    return base


def main() -> int:
    args = sys.argv[1:]
    if len(args) in (2, 3) and "/" not in args[0] and "." not in args[0]:
        target = resolve_ids(args)
        if not target.is_dir():
            print(f"ERROR: resolved {target} but it is not a directory "
                  f"(run from the course root; check the section/module ids)")
            return 2
    elif len(args) == 1:
        target = Path(args[0])
    else:
        print(__doc__)
        return 2

    if target.is_dir():
        errors = check_lab_dir(target)
    elif target.name == "config.yaml":
        errors = check_lab_dir(target.parent)
    elif target.suffix in (".md", ".markdown"):
        errors = check_markdown(target)
    else:
        print(f"ERROR: don't know how to validate {target}")
        return 2

    for e in errors:
        print(f"ERROR: {e}")
    if not errors:
        print(f"OK: {target}")
    return 1 if errors else 0


if __name__ == "__main__":
    raise SystemExit(main())
