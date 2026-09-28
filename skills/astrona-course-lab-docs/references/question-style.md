# question.md style

A practical, exam-style task. The learner reads only this file and knows
exactly what to build. It never tells them to read the course, and it never
explains *how*.

## Shape

```markdown
# Question

Solve this question on: `<node>`

## Scenario

<2–5 sentences. Real-world framing: who needs this and why. Name the
constraint that makes it non-trivial — what must NOT break, what is
off-limits, what is already in place.>

## Tasks

1. **<Short bold label>.** <Imperative sentence with every concrete value:
   addresses, prefixes, ports, filenames, exact strings, modes, zones.>
   <Optional: the observable end state, e.g. "`getent hosts app-srv1`
   returns `192.168.10.71`".>

2. **<label>.** <…>
```

## Rules

- **`Solve this question on:`** names the node.
  - Single unnamed `qemu`/`kind` node → `` `terminal` ``.
  - Named nodes → the name(s) the learner works on, e.g. `` `target` `` or
    `` `server` and `client` ``. Do not list nodes the learner never touches
    (a bootstrap-only gateway/dns node).
- **Every value a validator checks appears in the task text**, verbatim:
  `192.168.10.71/24`, `fd00:10::70/64`, `8443/tcp`, `maxpoll 10`,
  `Web Server 1 (Frankfurt)`, `tcp dport 6000 redirect to :6001`,
  `/opt/course/private_ip`, `ns1.internal.example.com.` (trailing dot included).
- **State ordering / scoping requirements** when a validator enforces them:
  "the accept rule must come before the catch-all drop", "global `no` plus a
  `Match User elena` exception", "both live now and saved for reboot".
- **Checks already satisfied by bootstrap** are context, not tasks. Fold them
  into the scenario ("firewalld is installed, running, and the interface is in
  the `public` zone") instead of asking for them. Optionally add a verify-only
  task ("verify it is listening, don't break it") when the validator would fail
  if the learner regresses it.
- **A table is fine** for a list of "query → expected answer" or "port →
  behaviour" pairs.
- **No `## Verification` section. No mention of `astrona submit`, validation
  scripts, or `/usr/local/bin/validate-*.sh`.** Grading belongs in the
  solution, not the question.
- Keep it tight. Scenario short, tasks scannable. Wrap prose ~76 columns.

## Capstone variant

Identical tasks, plus one line opening the scenario:

> This is the Section 0X0 capstone — one integrated <topic> task, no
> step-by-step guidance.
