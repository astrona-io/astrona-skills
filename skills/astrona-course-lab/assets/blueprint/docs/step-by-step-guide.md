# Step-by-Step Guide: {{path_id}} — {{title}}

> Declared in [`../config.yaml`](../config.yaml) under `metadata.docs.guide`.
> This contains the full answer. Try the [exam question](./exam-question.md) first.

## 0. Start the lab

```sh
astrona run -c .
```

TODO: note what `astrona run` returns and how to reach the environment
(`kubectl --context kind-{{slug}} ...` or `astrona ssh {{slug}}`).

## 1. TODO: first action

TODO: explain why this step is needed, then the command:

```sh
# command
```

Expected observation: TODO — a stable signal of success, not a full output dump.

## 2. TODO: next action

```sh
# command
```

Expected observation: TODO.

## 3. Verify before submitting

```sh
# the same check grading runs, run by hand
```

## 4. Submit and clean up

```sh
astrona submit -c .
astrona destroy -c .
```

Expected: `PROCTOR: PASS`, exit code `0`.
