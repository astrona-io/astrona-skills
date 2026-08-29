---
name: astrona-course-expand-material
description: Expand rough, terse, or lab-oriented technical notes into accurate beginner-friendly course chapters. Works on a course module's course.md in place and weaves in hands-on "try it" checkpoints when the module has a linked playground; when it has none, it reports that and offers to set one up. Use for conceptual reading material; do not use when the user wants a guided lab, unguided challenge, assessment, or accuracy-only review.
---

# Course Expand Material

Create standalone reading material that teaches the supplied topic without assuming professional experience. When the material belongs to a course module that has a **linked playground**, interleave the reading with short hands-on checkpoints so the reader understands an idea and then immediately sees it run — pair programming between the text and a live machine.

**Every element earns its place or it is left out.** Objectives, prerequisites, analogies, warnings, summaries — add one because *this* subject needs it, never because the template has a slot for it. A short honest chapter beats a padded one. (Recall quizzes / knowledge checks are not this skill's job — that is `astrona-course-generate-assessment`.)

## 1. Resolve the target

This skill works on a **course module** by default.

1. Take `<section-id>` and `<module-id>` from the invocation. **If either is missing, ask the user for it — one prompt, explicitly naming both. Never guess, never infer from the working directory or open files.**
2. Resolve from the course root: `<course-root>/sections/<section-id>/<module-id>/course.md` (accept `courses.md` / `COURSES.md` as the same file). `<course-root>` is the current directory unless the user names another.
3. Confirm that file exists before doing anything. If it does not, stop and report the exact path you looked for.
4. Expand **in place** in that file.

**Only** when the user supplies loose notes with no course context and no ids: expand and return one copy-ready Markdown chapter inside a four-backtick `markdown` fence, and skip every playground step below.

## 2. Check the playground link

Run `scripts/playground_status.sh <course-root> <section-id> <module-id>` (or `scripts/playground_status.sh <path-to-course-file-or-module-dir>`). It prints `LINKED` or `NOT_LINKED`. A module counts as linked when `sections/<…>/playground/` exists next to the course file, or the course file carries the `<!-- astrona:playground -->` callout (or a `## Playground` heading).

## 3a. NOT_LINKED — stop and offer choices

Do **not** expand yet. The woven chapter is the point of this skill; a plain chapter is a fallback. Report to the user, verbatim intent:

> This module has no linked playground. The chapter reads best when the reader can run what they read. Pick one:
> 1. **Set one up** (recommended) — `/astrona-course-lab create playground <section-id> <module-id>`, then re-run this skill. You get concept → run it → observe → connect, in one pass.
> 2. **Expand without a playground** — plain reading material, no hands-on checkpoints.
> 3. **Do nothing.**

Wait for the answer. On (1), after `playground/` exists, continue at 3b. On (2), produce the chapter under sections 4 and 5 only (no Try-it checkpoints). On (3), stop.

## 3b. LINKED — expand with hands-on checkpoints

Read [references/playground-weaving.md](references/playground-weaving.md) before drafting. Adapt [assets/chapter-with-playground-template.md](assets/chapter-with-playground-template.md).

- Explain each concept in plain language **first** (concrete before abstract), then add one **Try it** checkpoint for concepts that have something observable — the exact command to run in the already-running playground, the representative output, and one line tying what the reader sees back to the idea.
- **One explained concept, then at most one checkpoint. Never two `> [!TIP]` blocks in a row.** Before every checkpoint the reader must already have the idea, its terms, and know what they are about to see and why. If two things are worth trying, write the prose that sets up the second one before its block — do not stack them and leave the reader guessing what the second block is for.
- Leave the existing `<!-- astrona:playground -->` callout where the lab skill placed it (just under the H1). Do not move, duplicate, or rewrite it. Checkpoints assume the environment is already up from that callout's `astrona run` line — never re-teach startup, SSH boilerplate, or teardown per checkpoint.
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

State what changed: sections added or restructured, how many **Try it** checkpoints were added, whether pitfalls / where-it-fits were included and why (or why not), and the playground status (linked / newly created / none by user choice).
