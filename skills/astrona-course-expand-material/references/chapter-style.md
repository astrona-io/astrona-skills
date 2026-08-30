# Chapter style

Written for a student reading alone to build a skill. Clarity and honesty over
completeness. Add nothing that does not help this reader on this subject.

## Explaining

- Lead with what the concept is and why it matters.
- Concrete instance first, then the general rule — every time.
- Plain language. Define a technical term on first use.
- At most one analogy per hard concept. Say "as an analogy" and state where it
  breaks down. A concept with no analogy beats one the reader over-extends.
- Prefer "normally," "commonly," or "depends on the environment" when exceptions
  matter. Distinguish configuration from verification, and link state from
  end-to-end reachability.
- Treat addresses, hostnames, interface names, and command output as examples.
- Every command block states the shell / host / context it assumes (playground
  VM, cluster, local machine).
- Warn before a command that can interrupt networking or a remote session.
- State whether a command-line change survives a restart.
- Short tables only for exact comparisons; `text` blocks for compact topologies.
- Do not force identical headings onto every topic.

## Commands — explain the subject's, ignore the plumbing

- **Subject commands** — the ones this module teaches (`pvs` / `vgs` / `lvs` in
  an LVM module; `ip` / `bridge` in a routing module; `systemctl` in a services
  module). On first use, give three things, then show it on real output:
  1. **What it does** — in one line.
  2. **How to read its name** — expand the abbreviation.
     `pvs` / `vgs` / `lvs` = **p**hysical **v**olume**s** /
     **v**olume **g**roup**s** / **l**ogical **v**olume**s**; the trailing `s`
     is the short one-line-each *summary*, and the `*display` cousins
     (`pvdisplay`, …) are the verbose form.
  3. **A memory hook tied to the model** — teach the PV → VG → LV stack once and
     the six commands fall out of it. The reader should remember the model, not
     memorise a flashcard list.
- **Incidental commands** — `ls`, `cd`, `sudo`, `mkdir`, `cat`, `echo`, an
  editor, `grep`. Assume the reader knows them. Do not define, expand, or
  footnote them; they are not what the module is about.
- A load-bearing but genuinely obscure flag on an incidental command gets one
  short clause — not a paragraph.
- When a subject has a family of related commands, group them by the one idea
  behind them so the names become predictable rather than arbitrary.

## Retention aids — use where they pay off, skip otherwise

- **Common pitfalls** (`> [!WARNING]`): the specific misconceptions and mistakes
  a beginner makes on *this* subject, each with the correction. Only real,
  known traps — never a generic "be careful".
- **Section recap**: one or two sentences of "what you now know" at the end of a
  long section. Noise on a short one — leave it out.

## Not here

- Numbered task lists, `## Step-by-step`, "do X then Y" walkthroughs — that is
  the guided-lab skill.
- **"Check your understanding", recall questions, `<details>` quiz blocks** —
  knowledge checks belong to `astrona-course-generate-assessment`, not the
  chapter.
- Grading language, `astrona submit`, proctor talk, pass/fail.
- Invented facts, citations, quizzes, or a "next chapter".
