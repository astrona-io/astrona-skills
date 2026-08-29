---
name: astrona-course-lab
description: Generate and maintain Astrona hands-on labs with the astrona CLI. Verb-dispatched — "create lab" scaffolds a new lab from the cached blueprint and fills config.yaml, docs, and grading; "create playground" scaffolds a clean ungraded environment inside a course module; "update <part>" regenerates one piece of an existing lab; "validate" and "test" check it. Use for any Astrona lab or playground authoring or upgrade task.
---

# Astrona Course Lab

Backed by the installed `astrona` CLI. The CLI binary is the dependency — this skill never clones `astrona-cli`. The lab blueprint is cached locally per CLI version (see Blueprint cache) so nothing is re-downloaded on a normal run.

Invoke as a prefix: `/astrona-course-lab <verb> ...`

| Invocation | Does |
| --- | --- |
| `/astrona-course-lab create lab <topic>` | Scaffold a new guided lab, then fill it in |
| `/astrona-course-lab create playground <section-id> <module-id>` | Scaffold a clean, ungraded environment inside `sections/<section-id>/<module-id>/` |
| `/astrona-course-lab update solution\|guide\|validation\|bootstrap\|exam-question\|case-study\|prerequisites\|overview <target>` | Regenerate one part of an existing lab or playground in place |
| `/astrona-course-lab validate <target>` | Structural + `astrona content validate` checks (auto-detects a playground) |
| `/astrona-course-lab test <target>` | Full `astrona test` lifecycle (only if the machine has the deps) |

If no verb is given, ask which one.

## Targeting course content

The course tree is a fixed structure: `sections/<section-id>/<module-id>/`, with
the module's guided lab at that path and its playground at
`sections/<section-id>/<module-id>/playground/`.

So `<target>` in every verb above is **`<section-id> <module-id>`** — resolved
from the course root — not a raw path. Add a third word `playground` to point at
the playground instead of the lab (`validate <section-id> <module-id> playground`).
`scripts/validate_lab.py` accepts this form directly; for other commands build
the path yourself. A raw path is still accepted for a lab that lives outside a
course tree (e.g. a fresh `create lab` under `./<slug>`).

If `<section-id>` or `<module-id>` is missing, prompt the user for it — never
guess. Confirm the resolved directory exists before acting.

## Always do first (every verb)

1. Run `scripts/lab_env.sh`. It resolves the `astrona` binary, detects its version, syncs the version-pinned blueprint cache if missing, and prints `ASTRONA_VERSION`, `BLUEPRINT_DIR`, `BLUEPRINT_SOURCE`.
2. Tell the user, verbatim, which version you are building for, e.g.
   `Building lab for astrona CLI <ASTRONA_VERSION> (blueprint: <BLUEPRINT_SOURCE>).`
   This is the anchor a client needs later to upgrade a lab from an older CLI version.
3. If the CLI printed a "new version available" notice, surface it. Do not run `astrona upgrade` unless the user asks.

## create lab

1. Read [references/lab-design.md](references/lab-design.md) and [references/astrona-cli.md](references/astrona-cli.md).
2. Gather inputs. Ask only for what is missing and changes the output:
   - **target** — where the lab goes. Inside a course tree, take
     **section-id** + **module-id** and scaffold at
     `sections/<section-id>/<module-id>/` (prompt for a missing id; never
     guess). Otherwise take an explicit **target directory**, default `./<slug>`.
   - **path-id** (e.g. `LAB042`) — required
   - **slug** (kebab-case) — required
   - **title** — required
   - **author-name** — default to the git user or ask
   - **runtime**: `kind` cluster (default) or `qemu` VM
   - **learning objective** — one measurable outcome — required
   - **the graded task** and how success is observable
3. Scaffold: `scripts/scaffold_lab.sh --target <resolved-dir> --slug <slug> --path-id <id> --title "<title>" --author-name "<name>"`, where `<resolved-dir>` is `sections/<section-id>/<module-id>/` or the standalone path. This runs `astrona content init` against the cached blueprint (`--repo <BLUEPRINT_DIR>`), so it works offline. (`ats` in the CLI call is the content-type token, not lab branding.)
4. Fill in the generated files against the inputs:
   - `config.yaml` — set `metadata.name`, wire `bootstrap.init`, `testing.manifests` (reference solution), `validation.checks` + `validation.script`. For `qemu`, add the `runtime:` block per [references/astrona-cli.md](references/astrona-cli.md).
   - `docs/prerequisites.md`, `docs/exam-question.md`, `docs/case-study.md`, `docs/step-by-step-guide.md` — real content, not placeholders.
   - `bootstrap/setup.sh` — only pre-work; never pre-build the graded state.
   - `solution/` — the correct end state a perfect learner produces.
   - `validate.sh` — exits `0` pass / non-zero fail; check actual content/behaviour, not just existence.
5. Run `scripts/validate_lab.py <section-id> <module-id>` (or `... <resolved-dir>`) and resolve every error.
6. Run `astrona content validate ats <resolved-dir>` and report output (`ats` = CLI content-type token). On this CLI it returns "validation for content type ats is not yet implemented" — that is expected; `scripts/validate_lab.py` is the real structural gate until the CLI catches up.
7. Report the tree and the CLI version the lab targets.

## create playground

A playground is a lab stripped to just the environment: it spins up, runs OS
prep, and stays running for free exploration. No task, no `docs/exam-question`,
no `solution/`, no `validation`, no `astrona submit`. Use it to let a learner
see a module's topic running on a clean machine.

Invoked as `create playground <section-id> <module-id>`. Run it from the course
root. The module folder is `sections/<section-id>/<module-id>/`, and the
playground is created at `sections/<section-id>/<module-id>/playground/` so the
two stay linked.

1. Read [references/playground-design.md](references/playground-design.md) and
   [references/astrona-cli.md](references/astrona-cli.md).
2. If `<section-id>` or `<module-id>` was not given on the invocation, prompt
   the user for the missing one. Do not guess. Then confirm
   `sections/<section-id>/<module-id>/courses.md` exists — if not, stop and
   report the path you looked for.
3. Read `courses.md`. It is free-form markdown:
   - **Title**: first `#` H1, unless the user overrides.
   - **Runtime**: infer from the body — Kubernetes / `kubectl` / a cluster →
     `kind`; a plain server / SSH / `systemd` / packages → `qemu`. If the body
     does not make it clear, ask the user.
   - Note the tools/packages the module needs so `bootstrap/prepare.sh` can
     preinstall them.
4. Scaffold:
   `scripts/scaffold_playground.sh --section <section-id> --module <module-id> --runtime kind|qemu [--course-root .] [--slug <slug>] [--title "<title>"] [--repo-url <https url>] [--branch <name>] [--git-url <ssh url>]`.
   This copies `assets/playground/` into the module's `playground/`, fills the
   template vars, adds a `runtime:` block for `qemu`, and inserts a **playground
   callout** into `courses.md` right under the module title.
   - **If `playground/` already exists** the script stops (exit 3) without
     touching anything. Ask the user whether to update it. For one part prefer
     `update <part> <section-id> <module-id> playground`; only re-run with
     `--force` if they want the whole thing regenerated.
   - **The callout link must be an absolute repo browse URL**, not
     `./playground/` — `courses.md` is read on GitHub / GitLab / the Astrona
     site, not a local clone. The script resolves it from `--repo-url`, else
     the module's git `origin` remote (from the `.git` it finds by walking up
     the folder structure). Finds neither → relative link + warning; then ask
     the user for the course repo URL and re-run with `--repo-url` (add
     `--branch` if not `main`).
   - The callout's `astrona run` uses `--git <ssh url> -c <repo-root path>` so a
     reader who never cloned can copy-paste it (`--git-url` overrides the ssh
     URL derived from `origin`). `astrona destroy` uses the **environment name**
     (the slug), not the config path.
   - Placement is a `> [!NOTE]` alert (blue info box on GitHub) just below the
     H1, so the playground is visible up front, not buried at the bottom. If the
     script had to fall back (no H1) confirm it reads well.
5. Fill in the generated files:
   - `bootstrap/prepare.sh` — install the module's tools, seed sample data.
     Environment prep only; there is nothing to grade, and don't pre-build a
     finished setup the learner was meant to explore building.
   - `config.yaml` — for `qemu`, set a real `image.source` / `arch` for the
     host per [references/astrona-cli.md](references/astrona-cli.md).
   - `docs/overview.md` — what is in the box and a few open-ended things to try.
6. Run `scripts/validate_lab.py <section-id> <module-id> playground` and resolve
   every error.
7. Open `courses.md`, confirm the callout sits just under the title and reads
   well, the link is an absolute repo URL, and the `run` / `destroy` commands
   are right (absolute `--git` URL, repo-root `-c` path, `destroy <slug>`).
8. Report the tree, the `courses.md` callout link, and the CLI version the
   playground targets.

## update <part> <target>

`<target>` is `<section-id> <module-id>` (add `playground` for the playground)
per [Targeting course content](#targeting-course-content); resolve it to a
directory first.

1. Read the existing `config.yaml` and the target file. Keep `metadata`, IDs, and unrelated files untouched.
2. Regenerate only the named part, consistent with the rest of the lab.
3. Re-run `scripts/validate_lab.py` on the same target.
4. Show a diff summary of what changed.

For a playground target, `bootstrap` targets `bootstrap/prepare.sh` and
`overview` targets `docs/overview.md`. `solution`, `guide`, `validation`,
`exam-question`, `case-study`, `prerequisites` do not apply to a playground.

## validate <target>

`<target>` is `<section-id> <module-id>` (add `playground` for the playground).
Run `scripts/validate_lab.py <section-id> <module-id> [playground]`, then
`astrona content validate ats <resolved-dir>`. Report both (the CLI's
lab-content validation is not yet implemented — say so). Do not edit files
unless asked.

## test <target>

`<target>` is `<section-id> <module-id>`, resolved to the module's lab dir.
Only if `astrona check` passes on this machine. Run
`astrona test -c <resolved-dir> --junit-xml=<resolved-dir>/report.xml`. Report
the real result. Never claim a lab was tested or executed unless the command
actually ran here.

Not applicable to a playground — there is no grading. Use `validate` and, if you
want to see it come up, `astrona run -c <resolved-dir>/playground` then
`astrona destroy <slug>` (the environment name, not the config path).

## Blueprint cache

`scripts/lab_env.sh` keeps the blueprint at
`${XDG_CACHE_HOME:-~/.cache}/astrona-course-lab/blueprint/<astrona-version>/`.

- Cache is keyed to the **installed** CLI version. A new CLI version → new cache dir → re-synced on the next trigger, so you always build against the current CLI while older caches stay intact for upgrade comparisons.
- Sync tries the upstream blueprint repo first; if it is unreachable it seeds from the vendored copy in `assets/blueprint/`. Either way the run continues offline.
- `scripts/lab_env.sh --refresh` forces a re-sync for the current version.
