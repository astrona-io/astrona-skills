---
name: astrona-course-deep-dive
description: Split one dense or shallow course module's course.md into a short landing page plus ordered, lower-level deep-dive part files, so a topic that needs more depth (mechanism, packet/data flow, state machines, precedence rules, what a command does underneath) gets it without one unreadable wall of text. Re-syncs the astrona.yaml manifest and the section README, preserves every "Try it" checkpoint and pitfall, and leaves course.md as the landing page so existing links keep working. Use when a module is too long to scan in one sitting, or when the user asks for a course file to "go deeper" / "more low level" / "split into multiple files". Do not use for a first-draft expansion of loose notes (that is astrona-course-expand-material), a guided lab, an unguided challenge, an assessment, or accuracy-only review.
---

# Course Deep Dive (split a module into layered parts)

Take **one existing course module** whose single `course.md` is either too long to scan in one sitting or too shallow for the depth the reader needs, and restructure it into:

```
module-XX/
├── course.md                       # short landing page — kept, so existing links still resolve
├── course-01-<slug>.md             # Part 1 — one concern, taught low-level
├── course-02-<slug>.md             # Part 2
└── course-0N-<slug>.md             # …in the order a reader should work through them
```

This skill **restructures and deepens**. It does not invent a topic from nothing (`astrona-course-expand-material`), write a graded lab (`astrona-course-lab`), or produce quizzes (`astrona-course-generate-assessment`).

**Every part earns its place.** Split because the content genuinely has 3+ independently-jumpable subtopics or runs past a comfortable single read (~150–200 lines) — not "for organisation". If two parts would each be 40 lines, they are one part. See [references/depth-and-structure.md](references/depth-and-structure.md).

## 1. When this skill applies

Use it when **all** of these hold:

- The target is an existing `sections/<section-id>/<module-id>/course.md` (or `courses.md` / `COURSES.md`).
- The user wants it **deeper / more low-level / more memorable for an exam**, or the file is already long and hard to navigate.
- The subject has real internal structure — distinct sub-mechanisms, a pipeline with stages, a set of rules with precedence.

Do **not** use it when: the module is short and coherent and just needs better prose (that is a plain `astrona-course-expand-material` pass); the user wants a lab, challenge, assessment, or accuracy review; or there is no `course.md` yet.

## 2. Resolve the target

`<course-root>` is the current directory unless the user names another.

- **Both ids given** — resolve `<course-root>/sections/<section-id>/<module-id>/course.md`. Confirm it exists; if not, stop and report the exact path.
- **A path given** — accept a path to the `course.md` or its module dir.
- **Nothing given** — ask for `<section-id>` and `<module-id>`. Never guess from the working directory or open editor tabs.

This skill works on **one module per run**. For several modules, run it once each; state the module list back to the user first.

## 3. Inventory before touching anything

Read and note:

1. The target `course.md` end to end. List its headings, every `> [!TIP]` **Try it** checkpoint, every `> [!WARNING]` pitfall list, every analogy, and any `<!-- astrona:playground -->` callout.
2. `scripts/find_refs.sh <course-root> <section-id> <module-id>` — every file that links to this `course.md`: the `astrona.yaml` manifest entry, the section `README.md`, section/final quiz pages, and any sibling module's "next module" link. Keep this list; section 8 updates all of it.
3. The section's other modules — how they are structured, how the manifest titles their reading entries. Match that house style; only diverge if the user asked for a repo-wide change.

## 4. Plan the split

Draft the part list **before writing**. Show it to the user if the split is non-obvious (more than ~4 parts, or it changes the module's shape a lot).

Rules:

- **One concern per part.** A part answers one question: "how does X work", "what are the families", "how do I make it persist". If a part needs "and also" in its title, split it.
- **Order is a teaching sequence.** Part N assumes Parts 1..N-1. Earlier parts define the terms later parts use.
- **Size target ~120–200 lines per part.** Consistently under ~100 → merge with a neighbour. Consistently over ~220 → that part is really two concerns.
- **Landing page stays small** (~50–90 lines): the framing paragraph, the reading-order list, expanded learning objectives, "Before you start", "Where this fits". No teaching content that belongs in a part.
- **Nothing is dropped.** Every checkpoint, pitfall, and useful example from the original lands in exactly one part. New checkpoints may be added where a now-isolated concept has something observable; consolidate the original's scattered pitfalls into the relevant parts' `> [!WARNING]` blocks (or a "Common pitfalls" section in the last part).

## 5. Depth rules — what "more low level" means here

Lower-level = **mechanism**, not kernel/library source. For each part, push the explanation down to the layer that makes the commands predictable:

- the **data/packet/request flow** — the stages a thing passes through, in order, with a text diagram;
- **state machines and lifecycles** — the states an object moves between and what triggers each transition;
- **precedence and ordering rules** — when several things could apply, exactly which one wins and why;
- **what a command does underneath** — the objects it creates or edits, where they live, what reads them;
- **the failure modes that follow from the mechanism** — stated as consequences of how it works, not as a generic "be careful".

Do **not** drop to kernel struct names, source functions, or on-the-wire byte layouts unless the user explicitly asks — they rarely help on a certification exam and bury the parts that do.

Keep the teaching craft from `astrona-course-expand-material`:

- concrete instance **before** every general rule;
- at most **one analogy per hard concept**, flagged as an analogy, with where it breaks down;
- explain the **subject's** commands (expand the abbreviation, tie to the model, show on real output); assume generic shell commands are known;
- every command block states the shell / host / privilege it assumes; warn before anything that can cut a remote session.

## 6. Part file shape

```markdown
# Part N — <Concern>

> Prerequisite: [Part N-1 — <title>](./course-0X-<slug>.md). Next: [Part N+1 — <title>](./course-0Y-<slug>.md).

<One paragraph: what this part settles and why the reader needs it before moving on.>

## <Sub-heading — one idea>

<Concrete instance, then the mechanism. Text diagram for any flow or ordering.
One analogy max, flagged. Try-it checkpoint(s) where something is observable —
never two `> [!TIP]` blocks in a row; set up each one in prose first.>

## <Sub-heading …>

...

> *One-italic-line pull-quote: the single sentence to remember from this part.*

## Reference

- `man <page>` — one line on why it is worth opening.
- <authoritative doc / wiki page> — one line on what it adds.
```

- First part's breadcrumb points back to `./course.md`; last part's "Next" points to the module landing page or the section quiz.
- Slugs are short and kebab-case: `course-01-netfilter-and-packet-flow.md`, `course-02-tables-and-families.md`.
- Number with a zero-padded two-digit index so files sort.

## 7. Landing page shape (`course.md`)

Keep the original H1. Then:

1. The framing paragraph(s) — what the module teaches, and the contrast with an adjacent tool/concept that sharpens the boundary. Keep the `<!-- astrona:playground -->` callout directly under the H1 if it was there; do not move or duplicate it.
2. `## How this module is organised` — a numbered list linking each part in order, one line each on what that part covers.
3. `## Learning objectives` — 5–9 measurable "After this module you can …" lines, now spanning all the parts. Measurable verbs (name, explain, choose, write, read), not "understand".
4. `## Before you start` — assumed knowledge and what the playground provides. Short.
5. `## Where this fits` — one paragraph placing the module in the bigger system. Only if the subject needs it.

No teaching content on the landing page. If you are explaining a mechanism there, it belongs in a part.

## 8. Re-sync the manifest and the section README

Do all of these in the same pass, from the section 3 reference list:

- **`astrona.yaml`** — after the module's existing landing `reading` entry (`path: sections/<…>/<module-id>/course.md`), insert one `reading` entry per part, in order:

  ```yaml
      - type: reading
        title: "Module <M>.<N>: <part title>"
        path: sections/<section-id>/<module-id>/course-0N-<slug>.md
  ```

  where `<M>` is the module's number as the section already titles it. Do not remove the landing entry.
- **Section `README.md`** — under the module's link in the "Theoretical Concepts" (or equivalent) list, add a nested numbered list linking each part.
- **Quiz / final-exam pages that linked to `course.md`** — leave them; the landing page still exists and is the right target. Only touch them if a link pointed at a heading that moved into a part, in which case repoint it at the part.
- **Sibling "next module" links** — unchanged unless they pointed at a moved heading.

## 9. Validate

Run `scripts/check_split.sh <course-root> <section-id> <module-id>` and resolve every error. It checks:

- `astrona.yaml` parses as YAML, and **every** `path:` under this module's content block exists on disk;
- `course.md` still exists and every `course-0N-*.md` in the module dir is referenced by the manifest (and vice versa — no orphan part files, no dangling entries);
- each part file has the `# Part N — ` H1, a `> Prerequisite:` breadcrumb, a pull-quote line, and a `## Reference` section;
- code-fence counts are balanced in every file;
- no part file link (`./course-0X-*.md`) points at a file that does not exist.

If `python3` or `bash` is missing, do the same checks by hand and say so.

## 10. Report

State plainly:

- the part list, with per-file line counts;
- how many **Try it** checkpoints were carried over and how many new ones were added;
- which pitfalls / analogies moved where, and confirm none were dropped;
- the manifest and README entries added (counts);
- validator result;
- that nothing was committed (unless the user asked).

Do not claim a reference was updated unless it was, and do not claim the split is balanced if one part is still 300+ lines — say it needs another pass.
