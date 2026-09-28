# solution.md style

A plain, beginner-safe walkthrough built around a fast feedback loop. The
learner should be able to follow it without knowing any shell shortcuts, and
should always know which checks are green.

## Shape

```markdown
# Solution Walkthrough

<1–2 sentences: what you will do, on which node(s), and what stays untouched
(so a global change does not read as scary).>

<Memory table — see below.>

## The feedback loop

Grading runs from the **host terminal** — the shell where you typed
`astrona run`, not inside the VM:

```bash
astrona submit --git <repo-git-url> -c <lab-path>
```

`astrona submit` is the grading command the learner runs (there is no separate
`astrona test`). It needs the **same `--git <repo-git-url>`** the lab's
`README.md` uses in its `astrona run` line — without it the lab does not
resolve. Get the URL from that README (or the repo's `origin` remote) and use
it verbatim, e.g.
`astrona submit --git git@github.com:astrona-io/ATS003.git -c labs/section-010/module-02/lab-01`.

<Show the initial check list. Mark bootstrap-satisfied ones PASS, the rest
FAIL.> Run it now, then again after every step.

---

## Step 1: <look at the starting state>

<Commands to observe what is there. No check flips yet — say so.>

---

## Step 2: <first real change>

<commands>

<annotate each config block line by line>

**Run the check** — `<check-name>` now passes.

---

## Step N: Submit

<When all green:>

```bash
astrona submit --git <repo-git-url> -c <lab-path>
```

---

## If a check stays red

- **`<check>` fails — <symptom>.** <cause>. <fix>.
```

## The memory table

Right after the intro. Distils the *concepts*, not the keystrokes — 3–5 rows.

```markdown
| Goal | Where it lives | Command / file |
| --- | --- | --- |
| Address now (temporary) | running kernel | `sudo ip addr add …` |
| Address after reboot (permanent) | `/etc/netplan/*.yaml` | edit a file, then `sudo netplan apply` |
| A name for an address | `/etc/hosts` | add one line |
```

Pick the axis that makes the topic click: temporary-vs-permanent,
runtime-vs-permanent (firewalld), table→chain→rule (nftables), which-node.

## Command rules — assume no shortcut knowledge

- **No command substitution to capture a value.** Not `IFACE=$(ip route …)`.
  Instead: "run `ip route`, read the name after `dev` — in these examples it is
  `enp0s1`; use your own." Then use the literal `enp0s1` in every command with
  that one-line caveat.
- **No `awk` / `cut` / `sed` pipelines** in learner-facing commands. Show the
  full command output and tell them what to look for.
- **No heredocs, no `tee`-pipe-from-echo for multi-line files.** Use
  `sudo nano <file>` and show the exact block to type, then the save keys
  (`nano`: `Ctrl+O`, `Enter`, `Ctrl+X`).
- A single `echo 'one line' | sudo tee -a <file>` is acceptable for appending
  one literal line.
- Prefer `sudo systemctl restart <svc>` / `reload` spelled out over clever
  one-liners.
- Every multi-line config block gets a short line-by-line explanation of what
  each directive/key does.

## The feedback loop

- `astrona submit` runs from the **host terminal**, not inside the VM. Say so
  explicitly. It is both the per-step check and the final submission — there is
  no `astrona test`.
- It takes `--git <repo-git-url> -c <lab-path>` — the same `--git` URL as the
  lab README's `astrona run`. `-c` alone does not work. Put the full form in
  every code block; plain prose ("re-run `astrona submit`") is fine.
- List the checks by their short names (the `PASS:`/`FAIL:` label in each
  script). Show bootstrap-satisfied checks as `PASS` from the start.
- **Every step ends with "Run the check"** and names the check(s) that turn
  green. Step 1 (observe the starting state) is the only step with no check.
- If a check needs time (IPv6 DAD, chrony sync, NTP client selection), say so
  and give the "wait and re-run" instruction rather than a brittle sleep.
- Order the steps so each unlocks the next check cleanly; group changes that
  flip the same check.

## "If a check stays red"

One bullet per realistic failure mode, each mapped to a validator: the symptom
(ideally the script's own `FAIL:` wording), the cause, the fix. Cover the
ordering/scoping traps, the "runtime but not permanent" trap, the "edited the
wrong file / wrong node" trap, and a clean-slate reset if one exists
(`nft flush ruleset`, `systemctl restart <svc>`).

## Optional extras

- A `>` blockquote for an alternative tool path (NetworkManager instead of
  Netplan) when a validator accepts either — tell them to use one, not both.
- A `>` note for good practice the lab does not grade (persisting an nftables
  ruleset), clearly marked "not required to pass".

## Multi-node labs

Open each node's section with `astrona ssh <node>`. Keep the memory table
node-aware. The feedback-loop command still runs on the host and covers all
nodes at once.
