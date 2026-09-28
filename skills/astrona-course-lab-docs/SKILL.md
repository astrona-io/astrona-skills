---
name: astrona-course-lab-docs
description: Rewrite an Astrona lab's question.md and solution.md into a practical, certification-exam-style task and a beginner-friendly step-by-step walkthrough with a per-step `astrona submit` feedback loop. Derives everything from the lab's own validation scripts. Use when a lab's docs are thin, generic ("see the textbook"), or don't read like a real hands-on exam.
---

# Astrona Course Lab Docs

Turns a lab's `question.md` and `solution.md` into two things:

- **question.md** — a self-contained practical task that reads like a CNCF/LFCS
  hands-on exam item: a short scenario, then numbered objectives with every
  concrete value spelled out. No "go read the course". No verification section.
- **solution.md** — a plain, memorizable walkthrough that assumes the learner
  does not know shell shortcuts, structured around a fast feedback loop:
  `astrona submit` after every step, each step flipping one or more checks green.

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
2. **Read [references/question-style.md](references/question-style.md)** and
   write `question.md`.
3. **Read [references/solution-style.md](references/solution-style.md)** and
   write `solution.md`.
4. **Verify** with `scripts` / by hand:
   - `question.md` has no `## Verification` (or similar) section.
   - Every validator has a matching task in `question.md` and a step (or a
     "already passes from setup" note) in `solution.md`.
   - Every concrete value in `solution.md` matches the validator exactly
     (trailing dots, `/24`, `tcp dport 6000 redirect to :6001`, …).
   - The `astrona submit` lines carry `--git <repo-git-url>`
     (the same URL as the lab README's `astrona run`) **and** `-c <this lab's
     real path>`. `-c` without `--git` does not resolve the lab.
5. Report: the checks covered, any course-vs-validation mismatch you saw, and
   the files written.

## Sibling labs share validation

Before writing, compare `validation/` across the section's labs (module-01…N
and capstone). ATS labs very often reuse **one** validation set across several
labs — sometimes every lab in the section.

- Author the shared content **once** for the lowest-numbered lab.
- For each sibling with byte-identical validation, copy the files and rewrite
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
