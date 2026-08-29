# astrona-course-expand-material

A Claude Code skill for turning rough, terse, or lab-oriented notes into an
accurate, beginner-friendly **course chapter**.

When the material belongs to a course module that has a **linked playground**,
the skill interleaves the reading with short hands-on **Try it** checkpoints —
the reader understands an idea and then immediately runs it on a live machine.
When the module has no playground, the skill stops and offers to set one up
rather than silently producing a text-only chapter.

## Requirements

| Tool | Needed for |
| --- | --- |
| `python3` | `scripts/validate_chapter.py` (no third-party packages) |
| `bash` + `grep` | `scripts/playground_status.sh` |
| `astrona-course-lab` skill | only if you choose "set one up" for a module with no playground |

## Install

Drop the folder at `~/.claude/skills/astrona-course-expand-material/` (or
`just install` from the repo root). Claude Code discovers it by the `name:` in
`SKILL.md`, which must match the folder name. Restart Claude Code if a changed
`name:` / `description:` does not show up.

## What it does

1. **Resolve the target.** Works on a course module by default.
   - Takes `<section-id>` and `<module-id>`. **If either is missing, the skill
     asks for it** — one prompt naming both, no guessing from the working
     directory.
   - Resolves from the course root:
     `<course-root>/sections/<section-id>/<module-id>/course.md` (`courses.md` /
     `COURSES.md` also accepted). `<course-root>` is the current dir unless
     named. The file must exist or the skill stops and reports the path.
   - Expanded **in place** in that file.
   - Only loose notes with no course context skip this: returned as one
     copy-ready Markdown chapter in a fenced block, playground steps skipped.

2. **Check the playground link** with
   `scripts/playground_status.sh`. A module is linked when
   `sections/<…>/playground/` exists next to the course file, or the course file
   carries the `<!-- astrona:playground -->` callout (or a `## Playground`
   heading) — the same marker `astrona-course-lab` inserts when it scaffolds a
   playground.

3. **No playground → stop and offer choices:**
   1. Set one up — `/astrona-course-lab create playground <section-id> <module-id>`,
      then re-run this skill (recommended).
   2. Expand without a playground — plain reading material.
   3. Do nothing.

4. **Playground linked → expand with checkpoints.** Each concept is explained in
   plain language first, then a `> [!TIP]` **Try it** block gives the command to
   run in the already-running playground, the representative output, and one line
   connecting what the reader sees to the idea. The existing playground callout
   under the H1 is left untouched. No grading language — a playground has no
   task, no `astrona submit`, no pass/fail.

5. **Validate** with `scripts/validate_chapter.py FILE [--module] [--with-playground]`.

## Chapter shape (module course.md)

Built for a student reading alone. **Always:** the module's own H1 title (no
`Chapter N:`), `## Learning objectives` (3–6 measurable "after this you can …"),
`## Before you start` (prior knowledge + what the playground already provides),
then the concept → Try-it loop.

**Only when the subject needs it — never as filler:** `## Where this fits` (one
context paragraph), `> [!WARNING]` **Common pitfalls** (real, known beginner
traps with corrections), a one-line **section recap** after a long section. See
[`references/chapter-style.md`](references/chapter-style.md).

**Never:** "Check your understanding" / recall questions / `<details>` quiz
blocks (that is `astrona-course-generate-assessment`), or a closing
"Keep going" / "Next steps" section — a chapter ends when the subject is
covered.

## Usage

```
Use astrona-course-expand-material to expand net-basics static-routing's course.md.
```

```
$ scripts/playground_status.sh . net-basics static-routing
LINKED       dir=yes callout=yes file=./sections/net-basics/static-routing/course.md

$ scripts/playground_status.sh path/to/module/course.md
NOT_LINKED   dir=no callout=no file=path/to/module/course.md
```

`playground_status.sh` takes either `<course-root> <section-id> <module-id>` or a
path to the course file or the module dir. Status is printed to stdout; exit is
`0` on success, `2` on bad args or a missing course file.

## Validator

`scripts/validate_chapter.py FILE [--module] [--with-playground]` runs
deterministic checks:

| Check | Behaviour |
| --- | --- |
| Title | `--module`: exactly one `#` H1, **no** `Chapter N:` prefix. Without it: `# Chapter N: <title>` required. |
| `## Learning objectives` present, 3–6 list items | `--module` only |
| `## Before you start` present | `--module` only |
| Balanced ` ``` ` fences | always |
| No `## Step-by-step` section | always |
| No `Check your understanding` heading or `<summary>Answer</summary>` quiz block | always |
| No closing `Keep going` / `Next steps` / `What's next` section | always |
| No two `> [!TIP]` checkpoints in a row (a bare heading between them does not count as explanation) | always |
| Rejects `Guided Practice Lab`, `astrona submit`, `astrona test`, `PROCTOR:` | always |
| Rejects `astrona run`, `astrona destroy` | rejected without `--with-playground`; allowed with it (callout + Try it blocks) |

The validator does **not** require pitfalls, recaps, or "where this fits" —
those are judgement calls, added only when the subject needs them. Objectives
heading synonyms accepted: `Objectives`, `What you'll be able to do`. Prereqs
synonyms: `Prerequisites`, `What you need to know first`.

Exit `0` clean, `1` on errors, `2` on bad args. Use `--module` for an in-place
module `course.md`; add `--with-playground` when the chapter was woven against a
playground.

## Layout

```
astrona-course-expand-material/
├── SKILL.md                              # the skill definition Claude follows
├── README.md                             # this file
├── references/
│   ├── chapter-style.md                  # prose rules (analogies, pitfalls, recaps)
│   └── playground-weaving.md             # interleaving text with Try-it checkpoints
├── scripts/
│   ├── playground_status.sh              # is this module linked to a playground?
│   └── validate_chapter.py               # structural validator
├── assets/
│   ├── chapter-template.md               # plain chapter skeleton
│   └── chapter-with-playground-template.md   # woven chapter skeleton
└── agents/
    └── openai.yaml                       # display name + default prompt
```

## Notes

- **Every element earns its place.** Objectives, prerequisites, analogies,
  warnings, recaps — each is added because this subject needs it, never because
  a template has the slot. A short honest chapter beats a padded one.
- Do not add invented facts, citations, labs, quizzes, or a next chapter without
  a request.
- **Try it** checkpoints are optional, ungraded, and reference a running
  sandbox — they are not guided-lab framing. Guided step lists, grading, and
  `astrona submit` belong to `astrona-course-lab`, not here.
- No knowledge checks and no closing "Keep going" section. Quizzes are
  `astrona-course-generate-assessment`'s job; a chapter ends when the subject is
  covered.
- The prose must teach the chapter on its own; Try-it checkpoints are additive.
