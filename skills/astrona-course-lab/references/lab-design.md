# Guided lab design (Astrona)

A guided lab should have:

- One measurable learning objective.
- Explicit prerequisites and starting state (`docs/prerequisites.md`).
- A formal task statement (`docs/exam-question.md`) and a hint-driven variant
  (`docs/case-study.md`).
- A full walkthrough with the answer (`docs/step-by-step-guide.md`).
- Small, ordered, copy-safe commands in the guide with an expected observation
  after each — a stable signal, not a brittle full-output snapshot.
- Grading that measures the objective:
  - `validation.checks` (`resourceExists` / `podReady` / `command`) for "does
    the thing exist".
  - `validation.script` (`validate.sh`) for actual content or behaviour.
- A reference solution in `solution/` so `astrona test` can prove the grading
  passes against a correct answer.
- `bootstrap` limited to pre-work — never pre-build the graded state.
- Warnings before destructive or connectivity-affecting actions.
- `teardown` for anything the lab mutates outside the sandbox.

## Question title

The question file starts with front matter that names the task for people:

```markdown
---
title: Create Deployments From Workflow Inputs
estimated_duration: 15m
summary: One sentence about the task.
---
```

`title` is the lab's `title` in the training's `astrona.yaml` without the
trailing ` Lab`; `estimated_duration` is the same value as there. astrona shows
the title instead of `metadata.name`, which stays the identifier (cluster
name, grading, telemetry).

## Solutions

- The default solution is the file in `metadata.docs.solution` (old key
  `guide`), else `solution.md`: normally the terminal way.
- A task with more than one practical way (CLI vs web UI) gets one extra file
  per approach, `solution.<name>.md` next to `config.yaml`, `<name>` in
  lower-case kebab-case (`solution.web-ui.md`). Offer it to the user; do not
  add it unasked. No `config.yaml` key lists it: astrona finds the files.
- Every solution file starts with front matter: `title` (menu name, e.g.
  `Terminal`, `Web UI`), `order` (integer, lowest first, steps of 10: `10`
  for the default, then `20`, `30`) and `summary` (one sentence). Without
  `order` a solution sorts after those with one, the default first, then by
  title.
- Each solution covers the whole task from start to finish on its own; never
  "do the first steps of the other solution".
- Images go in `images/` next to the file, linked by relative path. PNG, JPEG,
  WebP or GIF, never SVG.
- `solution/` (reference manifests, `apply.sh` for `astrona test`) is a
  different thing from these walkthroughs.
- Solutions are never shown in exams or playgrounds and never published on
  the website.

Avoid: hidden prerequisites, unexplained root shells, fake verification that
only checks exit code, and placeholders that look like real credentials.

Never claim the lab was executed unless it actually ran in the stated
environment.
