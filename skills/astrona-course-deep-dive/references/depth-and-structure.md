# Depth and structure reference

Companion to `SKILL.md`. Read before planning a split.

## When to split — and when not to

Split a `course.md` only when at least one is clearly true:

- It is **too long to scan in one sitting** — past ~150–200 lines and still growing as you add the depth the user asked for.
- It has **3+ subtopics a reader would jump to independently** — "how does the packet flow", "what are the address families", "how do I make it persist" are separate lookups, not one read.
- The user **explicitly asked** for it to go deeper / lower-level / be split.

Do **not** split when:

- The whole thing reads comfortably as one page. Splitting adds a navigation tax (breadcrumbs, a landing page, N manifest entries) and buys nothing.
- The parts would each be ~40 lines. Two thin parts are one real part.
- The user wanted better prose, not more structure — that is a plain expand pass.

If a split already happened and turned out too granular, merging back is the same workflow in reverse: fold parts together, delete the extra files, remove their manifest entries, collapse the README list.

## "More low-level" = mechanism, not source code

The goal is to make the commands **predictable** — the reader should be able to guess what a command will do because they know the machine underneath. Push down to these layers and stop:

| Layer | What to show | Example |
|---|---|---|
| **Flow** | the ordered stages a unit of work passes through, as a text diagram | the five netfilter hooks and the routing decision between them |
| **State machine** | the states an object holds and what moves it between them | conntrack `new → established → …`; firewalld runtime vs permanent |
| **Precedence** | when several things could apply, which one wins, stated as a rule | firewalld source-binding beats interface-binding beats default zone |
| **What the command edits** | the objects created/changed, where they live, what reads them | `firewall-cmd --permanent` writes XML under `/etc/firewalld/`, read on `--reload` |
| **Failure modes as consequences** | mistakes that follow from the mechanism, with the fix | `policy drop` before the SSH accept locks you out *because* evaluation stops at the first terminal verdict |

Do **not** go below that line unless asked:

- kernel struct / function names (`nf_hook_slow`, `struct nft_chain`)
- library internals and source file references
- on-the-wire byte offsets

They almost never appear on a sysadmin certification and they crowd out the parts that do.

## Part anatomy

Every part file:

1. `# Part N — <one concern>` — the concern, not a chapter number dump.
2. `> Prerequisite: [Part N-1](...). Next: [Part N+1](...).` — a one-line breadcrumb. First part points back to `./course.md`; last part points forward to the landing page or the section quiz.
3. **Opening paragraph** — what this part settles and why it comes before the next one.
4. **Body** — `##` sub-headings, one idea each. Concrete instance, then mechanism, then a text diagram for any flow/ordering. One analogy per hard concept, flagged, with where it breaks.
5. **Try-it checkpoints** where something is observable — never two `> [!TIP]` blocks back to back; the prose before each must give the reader the idea, the terms, and what they are about to see.
6. `> *pull-quote*` — one italic line, the single sentence to remember. This is the exam hook.
7. `## Reference` — `man` pages and authoritative docs, each with a one-line "why open this".

## Landing page anatomy

Keep it ~50–90 lines. It is a map, not a lesson.

- Original H1, kept verbatim.
- `<!-- astrona:playground -->` callout kept directly under the H1 if it was there — not moved, not duplicated.
- Framing paragraph(s): what the module teaches, plus the contrast with an adjacent tool that sharpens the boundary ("nftables is the rule layer; netfilter is the hooks it plugs into").
- `## How this module is organised` — numbered list, each item links a part and says in one line what it covers.
- `## Learning objectives` — 5–9 measurable "After this module you can …" spanning all parts.
- `## Before you start` — assumed knowledge + what the playground provides.
- `## Where this fits` — one paragraph, only if the subject is easy to learn in isolation and misuse without context.

If you catch yourself teaching a mechanism on the landing page, move it into a part.

## Worked example — the nftables module

Before: `sections/section-030/module-01/course.md`, one file, ~354 lines, covering the object model, families, chains, rules, handles, counters, source matches, chain policy, and persistence in a single scroll.

After: landing page + 6 parts.

| File | Concern | ~lines |
|---|---|---|
| `course.md` | framing, reading order, objectives, before-you-start | 73 |
| `course-01-netfilter-and-packet-flow.md` | the 5 hooks, routing decision, priority bands, where a base chain sits | 103 |
| `course-02-tables-and-families.md` | ruleset vs table, the 6 families, why `inet` | 103 |
| `course-03-chains-hooks-priority.md` | base vs regular chain, `type`, `jump`/`goto`, policy, lock-out | 138 |
| `course-04-rules-matches-verdicts.md` | matches, all verdicts, rule order, handles, counters | 201 |
| `course-05-conntrack-sets-maps.md` | `ct state`, the established/related pattern, sets, verdict maps | 138 |
| `course-06-persistence-and-operations.md` | runtime vs `/etc/nftables.conf`, atomic `nft -f`, tracing, pitfalls | 131 |

What made the cut lines land where they did:

- The original's single "Common pitfalls" `> [!WARNING]` was split: the lock-out pitfall went to Part 3 (next to chain policy, where it is a consequence), the family/IPv6 pitfall to Part 2, the rest into Part 6's consolidated list.
- Every original "Try it" moved to the part that now owns its concept; new checkpoints were added where isolating a concept (jump-and-return, live set edit, verdict map) gave something new to observe.
- Part 4 is 201 lines — at the top of the range but genuinely one concern (how a rule is written and edited), so it stayed whole rather than being split into a thin "matches" and a thin "editing" pair.

Manifest: the single `Module 1` reading entry kept, six `Module 1.1`–`Module 1.6` entries inserted after it. Section README: a nested numbered list under the module link. `final-domain-quiz.md` links to `course.md` were left alone — the landing page is still the right target.
