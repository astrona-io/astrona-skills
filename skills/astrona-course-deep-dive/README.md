# astrona-course-deep-dive

A Claude Code skill for taking **one existing course module** whose single
`course.md` has outgrown a single read — or needs to go lower-level for an exam —
and splitting it into a **short landing page plus ordered deep-dive parts**,
without breaking the `astrona.yaml` manifest or the section `README.md`.

It **restructures and deepens** existing material. It does not draft a topic from
scratch (`astrona-course-expand-material`), write a graded lab
(`astrona-course-lab`), or generate quizzes
(`astrona-course-generate-assessment`).

## When to use it

All of these should be true:

- there is an existing `sections/<section-id>/<module-id>/course.md`;
- the user wants it **deeper / more low-level / more memorable for an exam**, or
  it is already long and hard to navigate;
- the subject has real internal structure — sub-mechanisms, a staged pipeline, a
  set of rules with precedence.

Not for: a short coherent module that just needs better prose; a lab, challenge,
assessment, or accuracy review; a module with no `course.md` yet.

## Result shape

```
module-XX/
├── course.md                       # kept as a ~50–90 line landing page — existing links still resolve
├── course-01-<slug>.md             # Part 1 — one concern, taught at mechanism level
├── course-02-<slug>.md             # Part 2
└── course-0N-<slug>.md             # …in reading order
```

- **`course.md`** keeps its H1 and playground callout, gains a
  `## How this module is organised` reading-order list, expanded
  `## Learning objectives` spanning every part, `## Before you start`, and
  (if the subject needs it) `## Where this fits`. No teaching content.
- **each part** has `# Part N — <concern>`, a `> Prerequisite: … Next: …`
  breadcrumb, concept→`> [!TIP]` Try-it body, an italic pull-quote (the exam
  hook), and a `## Reference` section.

## What "more low-level" means here

Mechanism, not source code. Push each part down to the layer that makes the
commands predictable — **flow** (ordered stages, with a text diagram),
**state machines**, **precedence rules**, **what a command edits underneath**,
and **failure modes stated as consequences** of the mechanism. Stop above kernel
struct/function names and on-the-wire byte layouts unless the user asks.
See [`references/depth-and-structure.md`](references/depth-and-structure.md).

Nothing from the original is dropped: every `> [!TIP]` checkpoint and
`> [!WARNING]` pitfall is redistributed into the part that owns its concept; new
checkpoints are added where isolating a concept exposes something new to observe.

## Usage

```
# by ids
Use astrona-course-deep-dive on section-030 module-01 — go deeper, more low-level.

# by path
Use astrona-course-deep-dive on sections/section-030/module-02/course.md.
```

One module per run. For several, invoke it once each.

## Requirements

| Tool | Needed for |
| --- | --- |
| `bash` + `grep` + `find` | `scripts/find_refs.sh`, `scripts/check_split.sh` |
| `python3` (with `pyyaml`) | the YAML-parse check in `scripts/check_split.sh` (skipped with a warning if absent) |

## Scripts

### `scripts/find_refs.sh`

```
scripts/find_refs.sh <course-root> <section-id> <module-id>
scripts/find_refs.sh <path-to-module-course.md-or-module-dir>
```

Lists every file that references the module's `course.md` — the `astrona.yaml`
entry, the section `README.md`, quiz/final-exam pages, sibling-module
"next module" links, lab READMEs — as `file:line: <matched text>`. Run it during
the inventory step so the re-sync pass updates all of them. Exit `0` always
(including zero hits), `2` on bad args.

Matching: a full `sections/<section>/<module>/` path segment is searched
repo-wide; a bare `](./module-XX/course.md)` relative link is searched **only**
under `sections/<section>/` and `labs/<section>/`, so it does not match every
other section's identically-numbered module dir.

### `scripts/check_split.sh`

```
scripts/check_split.sh <course-root> <section-id> <module-id>
scripts/check_split.sh <path-to-module-dir>
```

Post-split validation:

| Check | |
| --- | --- |
| `astrona.yaml` parses as YAML | skipped with a warning if `python3` missing |
| `course.md` still present in the module dir | |
| every `course-0N-*.md` in the dir is referenced by the manifest | and every manifest `path:` under the module exists on disk |
| each part has `# Part N — ` H1, `> Prerequisite:` breadcrumb, an italic `> *…*` pull-quote, a `## Reference` section | |
| code-fence ` ``` ` counts balanced in `course.md` and every part | |
| every `](./course-0X-*.md)` link inside a part resolves | |

Exit `0` clean, `1` on any failure, `2` on bad args.

## Layout

```
astrona-course-deep-dive/
├── SKILL.md                       # the procedure Claude follows
├── README.md                      # this file
├── references/
│   └── depth-and-structure.md     # when to split, the "how low-level" calibration, part/landing anatomy, a worked example
└── scripts/
    ├── find_refs.sh               # every file that links to the module's course.md
    └── check_split.sh             # post-split consistency check
```

## Notes

- **The landing page keeps its URL.** `course.md` is never deleted or renamed, so
  quiz pages and cross-section links that point at it stay valid. Only repoint a
  link if it targeted a heading that moved into a part.
- **`astrona.yaml`:** insert one `reading` entry per part, titled
  `Module <M>.<N>: <part title>`, directly after the module's existing landing
  entry. Do not remove the landing entry.
- **Match the section's house style** for file names and manifest titles — check
  the sibling modules before diverging.
- **Don't over-split.** Parts under ~100 lines each want merging; a part over
  ~220 is really two concerns. A split "for organisation" when the module still
  reads fine as one page just adds a navigation tax — say so instead.
- Nothing is committed unless the user asks.
