# Overview: {{path_id}} — {{title}} (Playground)

> Declared in [`../config.yaml`](../config.yaml) under `metadata.docs.guide`.

This is a **playground**, not a lab. The environment starts clean, runs
`bootstrap/prepare.sh`, and then waits. There is no task, no `astrona submit`,
and no pass/fail. Explore, break things, `astrona destroy`, start over.

## What's in the box

- TODO: runtime — a kind cluster (context `kind-{{slug}}`) or a qemu VM reached
  with `astrona ssh {{slug}}`.
- TODO: the tools and packages `bootstrap/prepare.sh` installs.
- TODO: any sample files or data seeded for you.

## Things to try

- TODO: a few open-ended prompts to explore the module's topic hands-on.

## When you're done

```sh
astrona destroy {{slug}}
```

(`astrona destroy` takes the environment name, not the config path.)
