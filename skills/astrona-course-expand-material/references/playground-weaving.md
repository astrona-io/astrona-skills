# Weaving a chapter with its playground

Goal: the reader learns an idea and, in the same pass, runs it on a live machine
and sees it behave. Reading is the primary channel; the playground makes it
concrete. Think pair programming — the text explains, the reader drives.

## Rhythm, per concept

1. **Explain** — plain language, define terms, concrete example before the
   abstract rule.
2. **Try it** — one command (or a short sequence) to run in the running
   playground.
3. **Observe** — the representative output, marked as an example.
4. **Connect** — one sentence linking what they saw to the idea just explained.

Only concepts with something observable get a checkpoint. Do not force one onto
every heading. A chapter with three well-placed checkpoints beats one with ten
filler ones.

## One concept, then one checkpoint — never a stack

Every `> [!TIP]` block must sit directly after the prose that explains the idea
it exercises. The reader reaches the block already knowing the terms, the mental
model, and what the command is about to show.

**Do not place two (or three) `> [!TIP]` blocks back to back.** A run of
checkpoints with no teaching between them leaves the reader running commands
without knowing why the second and third exist. If a section is worth two
hands-on steps, write the setup for the second step — what it adds, what to look
for — as normal prose before its block.

```
   explain concept A  →  [!TIP] try A  →  explain concept B  →  [!TIP] try B
```

not

```
   explain concept A  →  [!TIP] try A  →  [!TIP] try B  →  [!TIP] try C
```

## No knowledge checks

Do not add "Check your understanding" prompts, recall questions, or `<details>`
quiz blocks. A course chapter teaches; graded and self-check questions are
`astrona-course-generate-assessment`'s job. You may ask the reader in prose to
*predict* an output before a Try it runs it — that is teaching, not a quiz — but
no hidden-answer blocks.

## Try it block format

```markdown
> [!TIP]
> **Try it — <what you will see>**
>
> ```sh
> <command run inside the playground>
> ```
>
> Expect something like:
>
> ```text
> <trimmed representative output>
> ```
>
> <one sentence: how this output shows the concept above>
```

`> [!TIP]` renders as a green box on GitHub and any GFM-alert-aware renderer and
degrades to a plain blockquote elsewhere — same portability reason the
playground callout uses `> [!NOTE]`.

## Rules

- **Assume the environment is already up.** The `<!-- astrona:playground -->`
  callout under the H1 carries the one `astrona run` line. Checkpoints do not
  repeat startup, SSH login boilerplate, `kubectl config use-context`, or
  `astrona destroy`.
- **Leave the callout alone.** Do not move it, duplicate it, or restyle it.
- **The VM / environment name is prefixed `astro-`.** Astrona runs the machine
  as `astro-<slug>`, not `<slug>`. Every command that takes the environment name
  — `astrona ssh`, `astrona list` output, `astrona destroy` — must use
  `astro-<slug>`. `<slug>` is `metadata.name` in the playground's `config.yaml`.
  For a qemu playground, give the reader the shell command **once** (in "Before
  you start" or the first checkpoint that needs it) as
  `astrona ssh astro-<slug>`; later checkpoints just show the command to run
  inside the VM. Example: `astrona ssh astro-net-basics-static-routing-playground`.
- **No grading.** A playground has no task, no `astrona submit`, no
  `PROCTOR: PASS`, no pass/fail verdict. Never imply the reader is being scored.
- **Safe and repeatable commands.** Prefer read-only inspection. If a command
  changes state, say what it changes and how to undo it. Warn before anything
  that can drop networking or the current session.
- **Output is an example.** Hostnames, IPs, interface names, IDs, and timing all
  vary — say so.
- **No invention.** If the playground as provisioned cannot show a concept
  (missing tool, different runtime), state that plainly instead of writing a
  command that will not work. If it looks like the playground *should* cover it,
  note that its `bootstrap/prepare.sh` may need the tool added.
- **Prose still stands on its own.** A reader with no machine in front of them
  should still learn the chapter from the text alone; checkpoints are additive.

## What stays out

- `## Guided Practice Lab`, `## Step-by-step`, numbered "do this then that"
  task lists — that is the guided-lab skill's job.
- `astrona submit`, `astrona test`, report XML, proctor language.
- Setup that pre-builds the thing the reader was meant to explore building.
