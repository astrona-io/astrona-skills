# Solution Walkthrough

<What you will do, on which node(s), and what stays untouched.>

| Goal | Where it lives | Command / file |
| --- | --- | --- |
| <concept row> | <location> | `<command>` |
| <concept row> | <location> | `<command>` |

## The feedback loop

Grading runs from the **host terminal** — the shell where you typed
`astrona run`, not inside the VM:

```bash
astrona submit --git <repo-git-url> -c labs/section-0X0/module-0Y/lab-01
```

<N> checks:

```text
PASS  <bootstrap-satisfied-check>
FAIL  <check>
FAIL  <check>
```

Run it now, then again after every step.

---

## Step 1: Look at the starting state

<observe commands>

*(No check flips yet — this step just gathers information.)*

---

## Step 2: <first change>

```bash
<command>
```

<line-by-line explanation of any config block>

**Run the check** — `<check>` now passes.

---

## Step 3: <next change>

```bash
<command>
```

**Run the check** — `<check>` now passes.

---

## Step N: Submit

When `astrona submit` shows every line `PASS`:

```bash
astrona submit --git <repo-git-url> -c labs/section-0X0/module-0Y/lab-01
```

---

## If a check stays red

- **`<check>` fails — <symptom>.** <cause>. <fix>.
- **`<check>` fails — <symptom>.** <cause>. <fix>.
