# astrona-course-lab

A Claude Code skill for authoring and maintaining **Astrona hands-on labs** and
**playgrounds** with the `astrona` CLI.

It is verb-dispatched: you invoke it with a prefix and a verb, and it scaffolds,
regenerates, or checks lab content. The `astrona` binary is the only hard
dependency — the skill caches the lab blueprint locally per CLI version, so a
normal run needs no network.

## Requirements

| Tool | Needed for |
| --- | --- |
| `astrona` CLI on `PATH` | every verb (version detection, scaffolding) |
| `python3` | `scripts/validate_lab.py` (no third-party packages) |
| `git` | blueprint cache bookkeeping |
| Docker/Podman + `kind` | only if you actually `astrona run` / `test` a kind-runtime lab locally |

## Install

Drop the folder at `~/.claude/skills/astrona-course-lab/`. Claude Code discovers
it automatically; the slash command is the `name:` in `SKILL.md`:

```
/astrona-course-lab <verb> ...
```

Restart Claude Code if a changed `name:` / `description:` does not show up.

## Verbs

| Invocation | Does |
| --- | --- |
| `/astrona-course-lab create lab <topic>` | Scaffold a new guided lab, then fill it in |
| `/astrona-course-lab create playground <section-id> <module-id>` | Scaffold a clean, ungraded environment inside `sections/<section-id>/<module-id>/` |
| `/astrona-course-lab update <part> <target>` | Regenerate one part of an existing lab or playground in place |
| `/astrona-course-lab validate <target>` | Structural + `astrona content validate` checks (auto-detects a playground) |
| `/astrona-course-lab test <target>` | Full `astrona test` lifecycle (only if the machine has the deps) |

`<part>` is one of `solution`, `guide`, `validation`, `bootstrap`,
`exam-question`, `case-study`, `prerequisites`, `overview`.

### Targeting course content

The course tree is fixed: `sections/<section-id>/<module-id>/` holds the
module's guided lab, and `sections/<section-id>/<module-id>/playground/` its
playground. So `<target>` above is **`<section-id> <module-id>`**, resolved from
the course root — not a raw path. Add a third word `playground` to target the
playground instead of the lab:

```
/astrona-course-lab validate net-basics static-routing
/astrona-course-lab validate net-basics static-routing playground
```

`scripts/validate_lab.py` takes this form directly. A raw path still works for a
standalone lab outside a course tree. Missing ids are prompted for, never
guessed.

Every verb first runs `scripts/lab_env.sh` to resolve the CLI, detect its
version, and sync the version-pinned blueprint cache. The skill tells you which
CLI version it is building for — keep that value; it is the anchor for upgrading
an older lab later.

### create lab

Gathers the target (`<section-id> <module-id>` inside a course tree →
`sections/<section-id>/<module-id>/`, or a standalone dir defaulting to
`./<slug>`), plus `path-id`, `slug`, `title`, author, runtime (`kind` default or
`qemu`), the learning objective, and the graded task. Scaffolds from the cached
blueprint, then fills `config.yaml`, `docs/`, `bootstrap/setup.sh`, `solution/`,
and `validate.sh` with real content. Runs the validator and
`astrona content validate`.

```
/astrona-course-lab create lab "Kubernetes NetworkPolicy basics"
```

### create playground

A playground is a lab stripped to just the environment: it spins up, runs OS
prep, and stays running for free exploration. No task, no `docs/exam-question`,
no `solution/`, no `validation`, no `astrona submit`.

Run it **from the course root**. The module folder is
`sections/<section-id>/<module-id>/` and must contain a free-form `courses.md`.
The playground is written to that module's `playground/` subfolder, and a
`## Playground` section is appended to `courses.md` to link the two.

```
/astrona-course-lab create playground net-basics static-routing
```

- If `<section-id>` or `<module-id>` is omitted, the skill prompts for it — it
  does not guess.
- Title comes from the first `#` H1 in `courses.md` unless overridden.
- Runtime is inferred from `courses.md`: Kubernetes / `kubectl` / a cluster →
  `kind`; a plain server / SSH / `systemd` / packages → `qemu`. If unclear, the
  skill asks.
- `bootstrap/prepare.sh` is environment prep only — install tools, seed sample
  data; never pre-build a finished setup the learner was meant to explore.

Validate it with:

```
/astrona-course-lab validate net-basics static-routing playground
```

### update <part> <target>

`<target>` is `<section-id> <module-id>` (add `playground` for the playground);
see [Targeting course content](#targeting-course-content). Reads the existing
`config.yaml` and the target file, regenerates only the named part, re-runs the
validator, and shows a diff summary. `metadata`, IDs, and unrelated files are
left untouched. For a playground target, `bootstrap` targets
`bootstrap/prepare.sh` and `overview` targets `docs/overview.md`; the graded
parts do not apply.

### validate <target>

Runs `scripts/validate_lab.py <section-id> <module-id> [playground]` then
`astrona content validate ats <resolved-dir>` (`ats` is the CLI's content-type
token). `validate_lab.py` also accepts a raw path. It auto-detects a playground
(a dir named `playground`, or a `config.yaml` marked as a playground) and checks
it as an ungraded environment — it flags a `validation:` / `testing:` block as
wrong for a playground.

The CLI's lab-content validation currently returns "not yet implemented"; the
Python validator is the real structural gate until it catches up.

### test <target>

`<target>` is `<section-id> <module-id>`, resolved to the module's lab dir. Only
if `astrona check` passes locally. Runs
`astrona test -c <resolved-dir> --junit-xml=<resolved-dir>/report.xml` and
reports the real result. Not applicable to a playground (no grading).

## Layout

```
astrona-course-lab/
├── SKILL.md                     # the skill definition Claude follows
├── README.md                    # this file
├── .gitignore                   # keeps OS cruft + runtime output out of git
├── references/
│   ├── lab-design.md            # guided lab design rules
│   ├── playground-design.md     # playground design rules
│   └── astrona-cli.md           # cached CLI + config.yaml reference
├── scripts/
│   ├── lab_env.sh               # resolve CLI + sync blueprint cache
│   ├── scaffold_lab.sh          # `astrona content init` from the cache
│   ├── scaffold_playground.sh   # copy assets/playground into a module
│   └── validate_lab.py          # structural validator (lab + playground)
└── assets/
    ├── blueprint/               # vendored lab blueprint (offline fallback)
    └── playground/              # playground template
```

## Blueprint cache

`scripts/lab_env.sh` keeps the blueprint at
`${XDG_CACHE_HOME:-~/.cache}/astrona-course-lab/blueprint/<astrona-version>/`,
keyed to the installed CLI version. A new CLI version gets a fresh cache dir;
older caches stay for upgrade comparisons. Sync tries the upstream blueprint
repo first and falls back to the vendored copy in `assets/blueprint/`, so a
run always continues offline. Force a re-sync with `scripts/lab_env.sh --refresh`.

## Publishing

Safe to make public as-is. `.gitignore` at the skill root keeps OS/editor cruft,
Python bytecode, and any runtime output (`report.xml`, scaffolded
`sections/**/playground/` trees, a local blueprint cache) out of the repo. The
real blueprint cache lives under `~/.cache`, never inside the skill.

## Notes

- Never claim a lab, challenge, or command was executed unless it actually ran
  in the stated environment.
- In `astrona content init ats` / `... validate ats`, `ats` is the CLI's
  content-type token — not lab branding.
