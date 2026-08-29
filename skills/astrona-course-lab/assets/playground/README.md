# {{title}} — Playground

- **ID:** {{path_id}}
- **Slug:** {{slug}}
- **Author:** {{author_name}}
- **Type:** Astrona playground — clean environment, no task, no grading

{{description}}

A single sandbox environment that spins up, runs OS prep, and stays running so
you can explore the module's topic on a clean machine. Nothing to submit.

## Run it

```sh
astrona run -c .
astrona destroy -c .
```

`astrona submit` and `astrona test` do not apply — there is no grading.

## Layout

| Path | Purpose |
| --- | --- |
| `config.yaml` | Environment definition (runtime + bootstrap only) |
| `bootstrap/prepare.sh` | OS prep run once at startup |
| `docs/overview.md` | What the environment contains and ideas to try |
