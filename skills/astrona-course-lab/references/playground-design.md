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
playground there and inserts a **callout** into `courses.md` so the two are
linked. One playground per module. Prompt the user for a missing
`section-id` / `module-id` rather than guessing. If `playground/` already
exists the script stops (exit 3) — ask the user before overwriting with
`--force`, or use `update <part> ... playground` for one piece.

### The callout in courses.md

A GitHub `[!NOTE]` alert right below the module's H1 — marked
`<!-- astrona:playground -->` for idempotency — so a reader sees up front that a
runnable playground exists. Not a `## Playground` section at the bottom: the
playground must not be the last thing seen after finishing the module.

```markdown
<!-- astrona:playground -->
> [!NOTE]
> 🧪 **Hands-on playground for this module** — a clean, throwaway machine to explore on. No task, no grading. Folder: [`playground/`](<browse url>)
>
> ```sh
> astrona run --git <ssh url> -c <repo-root path>
> astrona destroy <slug>
> ```
```

`> [!NOTE]` renders as a blue info box on GitHub and any GFM-alert-aware
renderer. GitHub strips `class` / `style` off HTML, so an alert is the only
portable coloured box — a styled `<div>` would just render as plain text there.
Renderers without alert support degrade to a plain blockquote; the 🧪 marker
keeps it reading as a callout.

- **Folder link** — absolute repo browse URL, never `./playground/`
  (`courses.md` is read on GitHub / GitLab / the Astrona site). Built from
  `--repo-url`, else the git `origin` remote of the `.git` found by walking up
  the folder structure: `git@host:org/repo.git` and
  `https://host/org/repo.git` normalize to
  `https://host/org/repo/tree/<branch>/<path>`; GitLab hosts get `/-/tree/`.
  No URL → relative link + warning → ask the user for the repo URL and re-run.
- **`astrona run --git <ssh url> -c <path>`** — so a reader who never cloned
  can copy-paste. `<ssh url>` is derived from `origin` (or `--git-url`);
  `<path>` is the playground path from the repo root.
- **`astrona destroy <slug>`** — the environment name (`metadata.name`), not
  the config path.

## Runtime, from courses.md

`courses.md` is free-form markdown. Infer the runtime from the body:

- Kubernetes / `kubectl` / a cluster / manifests → `kind`.
- A plain server / SSH / `systemd` / packages / a single host → `qemu`.
- If the body does not make it clear, ask the user.

## Don't

Prep the machine, not the outcome. There is no solution to withhold, but also
do not hand the learner a finished setup they were meant to build while
exploring.
