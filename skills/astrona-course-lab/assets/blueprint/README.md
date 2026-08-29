# {{title}}

- **ID:** {{path_id}}
- **Slug:** {{slug}}
- **Author:** {{author_name}}
- **Type:** Astrona hands-on sandbox lab

{{description}}

## Run it

```sh
astrona run -c .
astrona submit -c .
astrona destroy -c .
```

## Prove it (authors / CI)

```sh
astrona test -c . --junit-xml=report.xml
```

`astrona test` bootstraps the lab, applies the reference solution in `solution/`,
submits it to the Proctor, and tears down — proving a learner who does everything
right will pass. Run it before publishing.

## Layout

| Path | Purpose |
| --- | --- |
| `config.yaml` | Lab definition (bootstrap / testing / validation / teardown) |
| `docs/prerequisites.md` | Knowledge and tooling needed first |
| `docs/exam-question.md` | Formal, self-contained task statement |
| `docs/case-study.md` | Softer, hint-driven version of the same task |
| `docs/step-by-step-guide.md` | Full walkthrough with the answer |
| `bootstrap/setup.sh` | Pre-work before the learner starts |
| `solution/` | Reference end state (CI only) |
| `validate.sh` | Pass/fail grading script |
| `teardown/dump-logs.sh` | State capture before teardown |
