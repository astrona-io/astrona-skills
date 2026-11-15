---
name: astrona-course-lab-docs
description: Rewrite an Astrona lab's question.md (with title/estimated_duration/summary front matter) and solution.md into a practical, certification-exam-style task and a beginner-friendly step-by-step walkthrough with a per-step `astrona submit` feedback loop, plus an extra solution.<name>.md per approach when a task has more than one practical way (CLI vs web UI). Derives everything from the lab's own validation scripts. Use when a lab's docs are thin, generic ("see the textbook"), or don't read like a real hands-on exam.
---

# Astrona Course Lab Docs

Turns a lab's `question.md` and `solution.md` into two things:

- **question.md** — a self-contained practical task that reads like a CNCF/LFCS
  hands-on exam item: a short scenario, then numbered objectives with every
  concrete value spelled out. No "go read the course". No verification section.
- **solution.md** — a plain, memorizable walkthrough that assumes the learner
  does not know shell shortcuts, structured around a fast feedback loop:
  `astrona submit` after every step, each step flipping one or more checks green.
  It is the default solution, normally the terminal way.
- **solution.\<name\>.md** (optional) — one more file per extra practical
  approach (`solution.web-ui.md`, `solution.helm.md`), each a full walkthrough
  of its own. See [More than one way](#more-than-one-way).

Invoke as a prefix: `/astrona-course-lab-docs <target> [all]`

| Invocation | Does |
| --- | --- |
| `/astrona-course-lab-docs <section-id> <module-id>` | Rewrite that one lab's `question.md` + `solution.md` |
| `/astrona-course-lab-docs <section-id> capstone` | Same, for the section capstone lab |
| `/astrona-course-lab-docs all` | Every lab under `labs/` in the current course |

`<target>` resolves to `labs/<section-id>/<module-id>/lab-01/` (or
`labs/<section-id>/capstone/lab-01/`). A raw path to a `lab-01/` directory also
works. If the target is ambiguous or missing, ask — never guess.

## The one rule

**The tasks come from the validation scripts, not from the course chapter.**
ATS labs frequently pair a module whose `course.md` teaches topic X with a lab
whose `validation/*.sh` asserts something broader or adjacent. Always follow the
validators. If you notice the mismatch, mention it to the user in your summary —
do not try to reconcile it by narrowing the task.

## Process (per lab)

1. **Read the grading.** For the target `lab-01/`:
   - Every file in `validation/`. Each script is one check. Extract: its short
     name (the `PASS:`/`FAIL:` label), the exact expected value (address, port,
     path, string, rule ordering, runtime-vs-permanent), and — for multi-node
     labs — which node it runs on (`vm:` key in `config.yaml`, or a `validation:`
     block nested under a named `qemu:` node).
   - `config.yaml`: `runtime` (single unnamed node → the node is `terminal`;
     one or more `name:`d nodes → use those names), `networks`, `extraDisks`,
     and the `bootstrap` wiring.
   - Every file in `bootstrap/`. This tells you the **starting state** and which
     checks are **already satisfied before the learner does anything** (a
     bootstrap that installs+enables a service, pre-creates a gateway, points a
     resolver, seeds a stale entry, etc.).
   - The lab's entry in the training's `astrona.yaml` (`title`,
     `estimated_duration`). The `question.md` front matter copies them.
2. **Read [references/question-style.md](references/question-style.md)** and
   write `question.md`, front matter first.
3. **Read [references/solution-style.md](references/solution-style.md)** and
   write `solution.md`, front matter first.
4. **Decide on extra solutions** per [More than one way](#more-than-one-way):
   if the task has more than one practical way, offer the user one
   `solution.<name>.md` per extra approach, and write each one they accept.
5. **Verify** with `scripts/check_lab_docs.sh <lab-dir>` and by hand. Run the
   script; do not simulate it. Resolve every finding.
   - `question.md` starts with front matter carrying `title`,
     `estimated_duration` and `summary`, matching `astrona.yaml`.
   - Every solution file starts with front matter carrying `title`, `order`
     and `summary`.
   - `question.md` has no `## Verification` (or similar) section.
   - Every validator has a matching task in `question.md` and a step (or a
     "already passes from setup" note) in each solution file.
   - Every concrete value in every solution file matches the validator exactly
     (trailing dots, `/24`, `tcp dport 6000 redirect to :6001`, …).
   - The `astrona submit` lines carry `--git <repo-git-url>`
     (the same URL as the lab README's `astrona run`) **and** `-c <this lab's
     real path>`. `-c` without `--git` does not resolve the lab.
6. Report: the checks covered, any course-vs-validation mismatch you saw, the
   files written (every solution file by name), and any extra approach you
   offered that the user declined. Never report a file, a check or a script
   run that did not happen.

## More than one way

Some tasks have more than one practical way to reach the graded end state:
the CLI and a web UI, `kubectl` and Helm, `nmcli` and Netplan. When the
validators accept more than one such way and each is something a learner
would really use, offer the user one extra solution file per approach before
writing it. Do not invent an approach the lab's environment cannot do (no web
UI is installed, no Helm binary).

- `solution.md` stays the default, normally the terminal way. A lab that names
  another file in `metadata.docs.solution` (or the old `guide` key) keeps that
  file as the default.
- Each extra approach is `solution.<name>.md` next to `config.yaml`, `<name>`
  in lower-case kebab-case (`web-ui`, `helm`). Never add a key to
  `config.yaml` for it: astrona finds the files. The `solution/` folder
  (`apply.sh`, reference manifests) is a different thing; leave it alone.
- Each file starts with front matter: `title` (the name in the solution
  menu), `order` (an integer, lowest first, in steps of 10: `10` for the
  default, `20`, `30` for the rest, so a new one fits between) and `summary`
  (one sentence shown under the title). Without `order` a solution sorts after
  those with one, the default first, then by title.
- Each solution covers the whole task from start to finish on its own,
  starting state to the final `astrona submit`, with the same feedback loop and
  checks. Never write "do steps 1 to 3 of the terminal solution first".
- Images (screenshots of a web UI) go in an `images/` folder next to the file,
  linked by relative path (`![Create form](images/web-ui-create.png)`). PNG,
  JPEG, WebP or GIF only, never SVG. Never invent a screenshot: if you cannot
  capture a real one, write the step in words and tell the user which images
  are still missing.
- Solutions are never shown in exams or playgrounds and never published on
  the website; write them for lab mode.

## Sibling labs share validation

Before writing, compare `validation/` across the section's labs (module-01…N
and capstone). ATS labs very often reuse **one** validation set across several
labs — sometimes every lab in the section.

- Author the shared content **once** for the lowest-numbered lab.
- For each sibling with byte-identical validation, copy the files (every
  `solution*.md` and its `images/`) and rewrite
  only the lab path in the two `astrona ... --git <url> -c labs/.../lab-01`
  commands (`sed 's#<old-path>#<new-path>#g'`).
- The **capstone** additionally gets one framing line at the top of its
  scenario: `This is the Section 0X0 capstone — one integrated <topic> task, no
  step-by-step guidance.` Its task list and solution are otherwise the same.

Two scripts differing only in an embedded hostname (`...-lab-042-server` vs
`...-lab-040-server`) still count as "the same" for reuse — the task is
identical.

## `all`

Resolve every `labs/section-*/*/lab-01/` in the course. Group by identical
validation, author one per group, derive the rest. Do the capstone of each
group last (it derives from a module lab plus the framing line). Report a table:
lab → checks → "authored" / "derived from <lab>".
