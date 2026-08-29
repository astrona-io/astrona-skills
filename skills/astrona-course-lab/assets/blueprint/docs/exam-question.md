# Exam Question: {{path_id}} — {{title}}

> Declared in [`../config.yaml`](../config.yaml) under `metadata.docs.examQuestion`.
> Meet the [prerequisites](./prerequisites.md) first.

**Task weight: 100%** (single scored task — adjust if you split it)

---

## Context

TODO: describe the environment the learner is dropped into. For a kind lab,
give the context name (`kind-{{slug}}`). For a qemu lab, say it is a real VM
reached over SSH with no Kubernetes.

## Task

TODO: state exactly what to produce. Be literal about names and values —
grading is exact.

1. ...
2. ...

## Constraints

- Do not modify `config.yaml` or anything under `docs/` or `solution/`.
- Do not tear down the environment mid-task — `astrona run` once and work
  against it until you submit.

## How you will be graded

You do not grade yourself. From this lab directory:

```sh
astrona submit -c .
```

The Proctor runs the declarative `validation.checks` and `validate.sh`. A
`PROCTOR: PASS` verdict and exit code `0` mean you are done. Re-submit freely.

When finished:

```sh
astrona destroy -c .
```

---

Want it walked through? See the [step-by-step guide](./step-by-step-guide.md).
Prefer hints over a full answer? See the [case study](./case-study.md).
