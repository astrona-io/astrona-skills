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
