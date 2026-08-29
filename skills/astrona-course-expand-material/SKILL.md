---
name: astrona-course-expand-material
description: Expand rough, terse, or lab-oriented technical notes into accurate beginner-friendly course chapters. Works on a single course module's course.md in place, or every module in a section, and weaves in hands-on "try it" checkpoints when a module has a linked playground; when it has none it offers to auto-create one (via astrona-course-lab) or expand plain. Use for conceptual reading material; do not use when the user wants a guided lab, unguided challenge, assessment, or accuracy-only review.
---

# Course Expand Material

Create standalone reading material that teaches the supplied topic without assuming professional experience. When the material belongs to a course module that has a **linked playground**, interleave the reading with short hands-on checkpoints so the reader understands an idea and then immediately sees it run — pair programming between the text and a live machine.

**Every element earns its place or it is left out.** Objectives, prerequisites, analogies, warnings, summaries — add one because *this* subject needs it, never because the template has a slot for it. A short honest chapter beats a padded one. (Recall quizzes / knowledge checks are not this skill's job — that is `astrona-course-generate-assessment`.)

## 1. Resolve the target

This skill works on a **course module** by default. `<course-root>` is the current directory unless the user names another. Course files: `course.md`, or `courses.md` / `COURSES.md` — treat as the same file.

**One module** — the invocation gives `<section-id>` **and** `<module-id>`:

1. Resolve `<course-root>/sections/<section-id>/<module-id>/course.md`.
2. Confirm it exists. If not, stop and report the exact path.
3. Expand **in place** in that file.

**A whole section (batch)** — the invocation gives `<section-id>` with **no** `<module-id>`, or says "all modules in section …":

1. Run `scripts/list_section_modules.sh <course-root> <section-id>`. It prints one line per module (`<module-id>  LINKED|NOT_LINKED  <course-file>`).
2. Show the user that list and the playground-policy question from section 2b, and get both confirmed **before touching any file**.
3. Then process the modules one at a time per section 8.

**Neither id given** — ask the user for `<section-id>`, and whether they want one module (which one) or the whole section. Never guess, never infer ids from the working directory or open files.

**Loose notes with no course context and no ids** — expand and return one copy-ready Markdown chapter inside a four-backtick `markdown` fence; skip every playground step below.

## 2. Check the playground link

### 2a. Per module

Run `scripts/playground_status.sh <course-root> <section-id> <module-id>` (or `scripts/playground_status.sh <path-to-course-file-or-module-dir>`). It prints `LINKED` or `NOT_LINKED`. A module counts as linked when `sections/<…>/playground/` exists next to the course file, or the course file carries the `<!-- astrona:playground -->` callout (or a `## Playground` heading).

### 2b. Playground policy — what to do about NOT_LINKED modules

Settle this once, up front, and reuse it for every module in the run:

- **auto-create** — for each NOT_LINKED module, run `/astrona-course-lab create playground <section-id> <module-id>`, wait for `playground/`, then expand woven (3b). If creation fails (no `astrona` CLI, scaffold error), fall back to a plain chapter for that module and record why.
- **plain** — skip playground creation; expand every NOT_LINKED module as a plain chapter (sections 4–5, no Try-it).
- **ask** — decide per module (single-module runs only; do not use for a batch).

The user may pre-authorize a policy in the invocation ("yes, auto-create playgrounds", "expand plain, don't make playgrounds"). If they did, use it without prompting. Otherwise:

- **Single module, NOT_LINKED** — present the choices and wait:

  > This module has no linked playground. The chapter reads best when the reader can run what they read. Pick one:
  > 1. **Set one up** (recommended) — auto-create a playground, then expand with hands-on checkpoints.
  > 2. **Expand without a playground** — plain reading material, no checkpoints.
  > 3. **Do nothing.**

- **Batch** — ask for the policy (**auto-create** / **plain**) once, before starting. Not per module.

A LINKED module always goes straight to 3b regardless of policy.

## 3b. Expand with hands-on checkpoints (LINKED module, or one just auto-created)

Read [references/playground-weaving.md](references/playground-weaving.md) before drafting. Adapt [assets/chapter-with-playground-template.md](assets/chapter-with-playground-template.md).

- Explain each concept in plain language **first** (concrete before abstract), then add one **Try it** checkpoint for concepts that have something observable — the exact command to run in the already-running playground, the representative output, and one line tying what the reader sees back to the idea.
- **One explained concept, then at most one checkpoint. Never two `> [!TIP]` blocks in a row.** Before every checkpoint the reader must already have the idea, its terms, and know what they are about to see and why. If two things are worth trying, write the prose that sets up the second one before its block — do not stack them and leave the reader guessing what the second block is for.
- Leave the existing `<!-- astrona:playground -->` callout where the lab skill placed it (just under the H1). Do not move, duplicate, or rewrite it. Checkpoints assume the environment is already up from that callout's `astrona run` line — never re-teach startup, SSH boilerplate, or teardown per checkpoint.
- **The running machine is named `astro-<slug>`, not `<slug>`** (Astrona prefixes it). Any command that takes the environment name — `astrona ssh`, `astrona destroy` — uses `astro-<slug>`, where `<slug>` is `metadata.name` in the playground's `config.yaml`. See [references/playground-weaving.md](references/playground-weaving.md).
- No grading language: a playground has no task, no `astrona submit`, no pass/fail.
- Not every heading needs a checkpoint. If a concept cannot be shown in the playground as provisioned, say so plainly rather than inventing a command.

## 4. Chapter shape (module course.md)

A module chapter is built for a student reading alone to build a skill. Use this order. Include a section only when it carries real content for this subject.

**Always:**

1. **H1** — the module's own title. No `Chapter N:` prefix.
2. **Learning objectives** (`## Learning objectives`) — 3 to 6 lines, each a concrete "After this you can …". Measurable verbs (list, configure, explain, diagnose), not "understand". These are what the reader aims at while reading.
3. **Before you start** (`## Before you start`) — prior knowledge assumed, and what the playground already provides. Short. Lets the reader self-screen instead of drowning three sections in.
4. **Body** — the concept → (Try it) loop, one subject at a time. Concrete instance before every general rule.

**When the subject warrants it — not otherwise:**

5. **Where this fits** — one short paragraph connecting the subject to adjacent topics and the bigger system. Add it when the subject is easy to learn in isolation and misuse without context. Skip for a self-contained utility.
6. **Common pitfalls** (`> [!WARNING]`) — the specific misconceptions or mistakes a beginner makes on *this* subject, stated plainly with the correction. Only real, known traps. No generic "be careful".
7. **Section recap** — one or two sentences at the end of a long section stating what the reader now knows. For a short section it is noise; leave it out.

Do **not** add "Check your understanding" prompts, recall questions, `<details>` quiz blocks, or a "Keep going" / "Next steps" / "Where to go from here" section. Knowledge checks are the assessment skill's job; a chapter ends when the subject is covered.

## 5. Expansion rules (always)

1. **Title.** For an in-place module `course.md`, keep the module's own H1 title — one `#` H1, no `Chapter N:` prefix, no numbering. Only the loose-notes fenced output (section 1) uses `# Chapter N: <title>`.
2. Preserve the topic, intended audience, and useful examples.
3. Correct clear inaccuracies and soften claims that are not universally true.
4. Define unfamiliar terms before using them and explain the mental model before commands. Precede every general rule or definition with one concrete instance.
5. At most one analogy per hard concept. Flag it as an analogy and state where it breaks down. No analogy is better than one the reader will over-extend.
6. Remove guided-lab headings, root-shell setup, and graded exercises unless requested. (Playground **Try it** checkpoints from section 3b are optional, ungraded, and reference a running sandbox — they are not guided-lab framing.)
7. Retain useful commands as reference examples. State the shell / host / context each command block assumes. Explain arguments, side effects, privileges, temporary state, and persistent alternatives when relevant.
8. Treat addresses, hostnames, interface names, and command output as examples. Warn before a command that can interrupt networking or a remote session.

Read [references/chapter-style.md](references/chapter-style.md) before drafting. Do not add invented facts, citations, labs, quizzes, or a next chapter without a request.

## 6. Validate

On a created or edited Markdown file, run `scripts/validate_chapter.py FILE [flags]` and resolve every reported error:

- **In-place module `course.md`** — add `--module`: requires one `#` H1 with no `Chapter N:` prefix, a `## Learning objectives` section of 3–6 list items, and a `## Before you start` section.
- **Loose-notes fenced chapter** — no `--module`: requires the `# Chapter N: <title>` form.
- **Woven against a playground (3b)** — also add `--with-playground`: allows the callout and the `astrona run` / `astrona destroy` lines in checkpoints; guided-lab and grading framing still fail.

The validator does not check for pitfalls, recaps, or "where this fits" — those are judgement calls, added only when the subject needs them. It rejects `<details>`-style quiz / "Check your understanding" blocks outright.

## 7. Report

**Single module** — state what changed: sections added or restructured, how many **Try it** checkpoints were added, whether pitfalls / where-it-fits were included and why (or why not), and the playground status (linked / newly created / none by user choice).

**Batch** — one row per module: `module-id | playground: linked|created|failed→plain|plain | checkpoints: N | validator: pass|<errors> | notes`. Then a one-line total and the CLI version any playgrounds were built for.

## 8. Batch mode (whole section)

Only after section 1 listed the modules and section 2b fixed the policy, both confirmed by the user.

1. Process modules **one at a time**, in the listed order. For each:
   a. Re-read that module's `course.md`.
   b. `LINKED` → expand woven (3b). `NOT_LINKED` → apply the policy: **auto-create** runs `/astrona-course-lab create playground <section-id> <module-id>`, waits for `playground/`, then 3b; on failure, fall back to a plain chapter and record the reason. **plain** → plain chapter (sections 4–5).
   c. Apply sections 4 and 5. Save in place.
   d. Run section 6 validation with the right flags for how it was expanded.
2. **A validation error on one module does not stop the batch.** Fix what you can, record the rest, move on.
3. Keep each module's expansion self-contained — no cross-references to sibling modules unless the source `course.md` already had them.
4. Under the `auto-create` policy the `astrona-course-lab` skill reports which CLI version each playground was built for — surface that so the user can anchor later upgrades.
5. When every module is done, give the section 7 batch report. Do not claim a playground was created or a lab command ran unless it actually did.
