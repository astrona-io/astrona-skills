# astrona CLI reference (cached)

Condensed from `astrona-io/astrona-cli` docs. This file exists so the skill
never needs to clone that repo. If a command below behaves differently, trust
`astrona <cmd> --help` on the installed binary and update this file.

## Commands used by this skill

| Command | Purpose |
| --- | --- |
| `astrona content init ats <path> --slug S --path-id ID --title T --author-name N [--repo URL] [--description D]` | Scaffold a lab from a blueprint git repo. `ats` is the CLI's content-type token. Without `--repo` it clones `git@github.com:astrona-io/training-sandbox-blueprint.git`. The skill always passes `--repo <cached blueprint>`. |
| `astrona content validate ats <dir-or-git-url> [--git-ref REF]` | Accepted but returns "validation for content type ats is not yet implemented" on current CLI. Use `scripts/validate_lab.py` as the real gate. |
| `astrona content build atp ...` | ATP only — not used here. |
| `astrona run -c <dir>` | Spin up the lab environment from a local dir. Returns once SSH/bootstrap is ready; env keeps running. |
| `astrona run --git <url> -c <path>` | Same, but clone `<url>` first and read the lab at `<path>` (relative to the repo root), e.g. `astrona run --git ssh://git@github.com/astrona-io/ATS003.git -c sections/section-020/module-01/playground`. Lets a reader who never cloned the course run it. |
| `astrona submit -c <dir>` | Send work to the Proctor for grading. |
| `astrona test -c <dir> --junit-xml=report.xml` | CI lifecycle: bootstrap → apply `solution/` → submit → teardown. Proves the lab's own grading passes. |
| `astrona destroy <name>` | Tear down the running environment by its name (`metadata.name`, i.e. the slug) — what `run` reports. Works for a normal run or an `astrona test` run. `astrona destroy -c <dir>` also works when you have the dir. |
| `astrona list` / `astrona ssh <name>` | Inspect / shell into running qemu VMs. |
| `astrona check` | Verify local deps before `run`/`test`. |
| `astrona --version` | `astrona version <ver>` — `<ver>` is `developer` for local dev builds, else `vX.Y.Z`. |

Blueprint template variables (substituted in file contents and paths, both
`{{slug}}` and `{{.Slug}}` forms): `path_id`, `slug`, `title`, `description`,
`version`, `language`, `author_name`, `license`.

## config.yaml schema (internal/config.LabConfig)

Top level — every block optional; omitted = that stage does nothing:
`metadata`, `runtime` (omit for kind), `bootstrap`, `testing`, `validation`, `teardown`.

### metadata

| Field | Meaning |
| --- | --- |
| `name` | Lab name; becomes the cluster/VM name, prefixed `astro-`. |
| `docs.prerequisites` / `docs.examQuestion` / `docs.caseStudy` / `docs.guide` | Plain paths; astrona doesn't render them, listings use them. |

### runtime (omit entirely for a kind cluster)

```yaml
runtime:
  type: "qemu"                 # "" or "kind" (default) | "qemu"
  networks:                    # optional named segments
    - name: lab-net
      cidr: 10.10.0.0/24
  qemu:                        # always a list, even for one VM
    - name: ""                 # required once >1 entry
      image:
        type: "oci"            # "file" | "url" | "oci"
        source: "ghcr.io/astrona-io/ubuntu-24.04-server-docker:arm64"
        checksum: "sha256:..."
      arch: ""                 # default: host arch (native accel)
      cpus: 2
      memoryMB: 2048
      diskSizeGB: 20
      extraDisks:
        - { sizeGB: 5, format: qcow2, serial: data0 }
      networks:
        - { name: lab-net, ipv4: 10.10.0.10 }
      sshAccess: []            # other VM names this VM can SSH into (multi-VM)
      sshPort: 0
      sshPasswordAuth: false   # student account only; astrona account stays key-only
      display: false
      bootstrap: {}            # per-VM, after shared root bootstrap (multi-VM)
      validation: {}           # per-VM, after shared root validation (multi-VM)
```

### bootstrap / testing (same shape; `testing` runs only under `astrona test`)

| Field | Meaning |
| --- | --- |
| `init` | list of ResourceItem — scripts run in order at start |
| `manifests` | list of ResourceItem — `kubectl apply` (needs a cluster) |

### validation

| Field | Meaning |
| --- | --- |
| `checks` | list of ValidationCheck |
| `script` | single pass/fail ResourceItem |
| `scripts` | more scripts, run after `script`, in order |

**ValidationCheck**: `name`, `type` = `resourceExists` \| `podReady` \| `command`;
`resource` (kubectl selector) for the first two; `command` (bare words, no shell
interpolation) and optional `expect` (exact trimmed stdout) for `command`.

### teardown

`init` (best-effort ResourceItems before destroy), `keepCluster` (bool, default false).

### ResourceItem (shared)

`name`, `description` (optional), `type` = `file` \| `folder` \| `url`,
`source` = path relative to the lab dir, or a URL.

## Minimal kind-runtime example

```yaml
metadata:
  name: "k8s-basics-01"
  docs:
    prerequisites: "docs/prerequisites.md"
    examQuestion: "docs/exam-question.md"
    caseStudy: "docs/case-study.md"
    guide: "docs/step-by-step-guide.md"
bootstrap:
  init:
    - { name: "echo", type: "file", source: "hello.sh" }
testing:
  manifests:
    - { name: "solution", type: "folder", source: "solution" }
validation:
  checks:
    - { name: "lab-ns namespace exists", type: "resourceExists", resource: "namespace/lab-ns" }
  script:
    type: "file"
    source: "validate.sh"
teardown:
  keepCluster: false
```
