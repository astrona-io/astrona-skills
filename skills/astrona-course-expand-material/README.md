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

1. **Resolve the target.**
   - **One module** — `<section-id>` **and** `<module-id>`. Resolves
     `<course-root>/sections/<section-id>/<module-id>/course.md` (`courses.md` /
     `COURSES.md` accepted; `<course-root>` = current dir unless named). File
     must exist or the skill stops and reports the path. Expanded **in place**.
   - **Whole section (batch)** — `<section-id>` with **no** `<module-id>`, or
     "all modules in section …". `scripts/list_section_modules.sh` lists every
     module and its playground status; the skill shows that list + the
     playground policy and gets both confirmed before touching a file, then
     processes the modules one at a time.
   - **Neither id** — the skill asks for `<section-id>` and whether it is one
     module or the section. No guessing from the working directory.
   - **Loose notes, no course context** — returned as one fenced chapter,
     playground steps skipped.

2. **Check the playground link** with `scripts/playground_status.sh`. Linked =
   `sections/<…>/playground/` exists next to the course file, or the file
   carries the `<!-- astrona:playground -->` callout (the marker
   `astrona-course-lab` inserts).

3. **Playground policy for NOT_LINKED modules** — settled once and reused for
   the whole run:
   - **auto-create** — run
     `/astrona-course-lab create playground <section-id> <module-id>`, wait for
     `playground/`, expand woven. Creation fails → plain chapter + recorded
     reason.
   - **plain** — expand as plain reading material, no checkpoints.
   - **ask** — decide per module (single-module runs only).

   The user can pre-authorize in the invocation ("yes, auto-create
   playgrounds"). A single NOT_LINKED module with no pre-authorization gets the
   3-way prompt; a batch is asked for **auto-create / plain** once, up front.

4. **Expand.** LINKED (or just auto-created) → concept → `> [!TIP]` **Try it**
   loop, callout left untouched, no grading language. Plain → sections 4–5 only.

5. **Validate** each file with
   `scripts/validate_chapter.py FILE [--module] [--with-playground]`. In a
   batch, a validation error on one module does not stop the others.

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
# one module
Use astrona-course-expand-material to expand net-basics static-routing's course.md.

# whole section, auto-create any missing playgrounds
Use astrona-course-expand-material on all modules in section net-basics —
yes, auto-create playgrounds where missing.

# whole section, no playground creation
Expand every module in section net-basics as plain reading material.
```

```
$ scripts/playground_status.sh . net-basics static-routing
LINKED       dir=yes callout=yes file=./sections/net-basics/static-routing/course.md

$ scripts/playground_status.sh path/to/module/course.md
NOT_LINKED   dir=no callout=no file=path/to/module/course.md

$ scripts/list_section_modules.sh . net-basics
static-routing    LINKED        ./sections/net-basics/static-routing/course.md
dynamic-routing   NOT_LINKED    ./sections/net-basics/dynamic-routing/course.md
firewalls         LINKED        ./sections/net-basics/firewalls/course.md
section net-basics: 3 module(s) — 2 linked, 1 without a playground
```

`playground_status.sh` takes `<course-root> <section-id> <module-id>` or a path
to the course file or module dir. `list_section_modules.sh` takes
`<course-root> <section-id>` or a path to the section dir and prints one
tab-separated row per module (`<module-id>  LINKED|NOT_LINKED  <course-file>`)
plus a summary on stderr. Both exit `0` on success, `2` on bad args / missing
path / no modules.

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
| `astrona ssh` names the real VM `astro-<slug>` (not a bare slug) | always |
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
│   ├── list_section_modules.sh           # enumerate a section's modules + status (batch mode)
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
- **Explain the subject's commands, not the plumbing.** A command the module
  teaches (`vgs`, `pvs`, `ip`, `systemctl` …) gets: what it does, how to read
  its name (expand the abbreviation), and a memory hook tied to the model —
  then real output. Generic shell commands (`ls`, `cd`, `sudo`, `mkdir`) are
  assumed known and left unexplained. See
  [`references/chapter-style.md`](references/chapter-style.md).
- Do not add invented facts, citations, labs, quizzes, or a next chapter without
  a request.
- **Try it** checkpoints are optional, ungraded, and reference a running
  sandbox — they are not guided-lab framing. Guided step lists, grading, and
  `astrona submit` belong to `astrona-course-lab`, not here.
- No knowledge checks and no closing "Keep going" section. Quizzes are
  `astrona-course-generate-assessment`'s job; a chapter ends when the subject is
  covered.
- The prose must teach the chapter on its own; Try-it checkpoints are additive.
- **Batch mode** processes a section's modules one at a time, in listed order,
  with the module list and playground policy confirmed up front. One module's
  validation error does not stop the rest. `auto-create` that fails for a module
  (no `astrona` CLI, scaffold error) falls back to a plain chapter for that
  module and records why. The run ends with a per-module report table.
- Playground creation is delegated to `astrona-course-lab` — this skill never
  scaffolds a playground itself; it invokes that skill and waits.
- **Astrona qemu conventions** a woven chapter must respect: the running VM is
  `astro-<slug>` (used by `astrona ssh` / `astrona destroy`); in disk listings
  `vda` = primary/OS disk, `vdb` = ~366K cloud-init disk, anything after =
  attached in `config.yaml`. Confirm against the running playground, not memory.
