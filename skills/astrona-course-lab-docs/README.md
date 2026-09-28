# astrona-course-lab-docs

A Claude Code skill that rewrites an Astrona lab's **`question.md`** and
**`solution.md`** so the lab reads like a real hands-on certification exam.

- **question.md** → a self-contained practical task: short scenario, numbered
  objectives with every concrete value spelled out, no "read the course", no
  verification section.
- **solution.md** → a beginner-safe walkthrough (no assumed shell shortcuts)
  built around an `astrona submit` feedback loop: a memory table of the concepts,
  then steps that each turn one or more checks green, then a troubleshooting
  section.

Everything is derived from the lab's own `validation/*.sh` — not from the
course chapter, which in ATS labs often covers a narrower or different topic.

## Install

This repo's `justfile` symlinks it in:

```sh
just install      # from the astrona-skills repo root
```

Then invoke:

```
/astrona-course-lab-docs <section-id> <module-id>
/astrona-course-lab-docs <section-id> capstone
/astrona-course-lab-docs all
```

## Requirements

| Tool | Needed for |
| --- | --- |
| `bash`, `grep`, `find` | `scripts/check_lab_docs.sh` sanity pass |
| the `astrona` CLI | only the learner needs it — to run `astrona submit`; the skill itself does not call it |

## Files

| Path | Purpose |
| --- | --- |
| `SKILL.md` | process, targeting, sibling-lab reuse |
| `references/question-style.md` | the `question.md` contract |
| `references/solution-style.md` | the `solution.md` contract (feedback loop, memory table, plain-command rules) |
| `assets/question-template.md` | skeleton |
| `assets/solution-template.md` | skeleton |
| `scripts/check_lab_docs.sh` | lint rewritten `lab-01/` dirs for the defects this skill prevents |

## Relationship to `astrona-course-lab`

`astrona-course-lab` scaffolds and regenerates whole labs (config, bootstrap,
validation, solution). This skill only touches the two learner-facing docs, and
only to impose the exam-style / feedback-loop shape. Use it after a lab already
has working validation.
