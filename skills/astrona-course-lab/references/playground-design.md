# Playground design (Astrona)

A playground is a lab with everything graded stripped out. It exists to let
a learner see a topic running on a clean machine — poke around, break things,
`astrona destroy`, start over. No task, no answer, no verdict.

## Keep

- One `runtime` — a kind cluster (default) or a qemu VM — chosen to match what
  the module teaches.
- `bootstrap.init` — environment prep only: install the tools the module talks
  about, seed sample files/data, start services.
- `docs/overview.md` — what is installed, how to reach it, a few open-ended
  things to try. No task statement.
- `teardown.keepCluster: false`.

## Drop

- `docs/exam-question.md`, `docs/case-study.md`, `docs/step-by-step-guide.md`.
- `solution/`, `validate.sh`, and the `testing` + `validation` blocks.
- Any "you will be graded" / `astrona submit` / `PROCTOR: PASS` language.

## Placement

Always `sections/<section-id>/<module-id>/playground/`, resolved from the course
root. That module folder holds `courses.md`.
`scripts/scaffold_playground.sh --section <id> --module <id>` puts the
playground there and appends a `## Playground` section to `courses.md` so the
two are linked. One playground per module. Prompt the user for a missing
`section-id` / `module-id` rather than guessing.

## Runtime, from courses.md

`courses.md` is free-form markdown. Infer the runtime from the body:

- Kubernetes / `kubectl` / a cluster / manifests → `kind`.
- A plain server / SSH / `systemd` / packages / a single host → `qemu`.
- If the body does not make it clear, ask the user.

## Don't

Prep the machine, not the outcome. There is no solution to withhold, but also
do not hand the learner a finished setup they were meant to build while
exploring.
