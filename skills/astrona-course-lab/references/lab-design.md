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

Avoid: hidden prerequisites, unexplained root shells, fake verification that
only checks exit code, and placeholders that look like real credentials.

Never claim the lab was executed unless it actually ran in the stated
environment.
