# astrona-skills

[![Liberapay](https://img.shields.io/badge/Liberapay-Support_Astrona.io-F6C915?logo=liberapay&logoColor=black&style=for-the-badge)](https://liberapay.com/Astrona.io)

A collection of [Agent Skills](https://docs.claude.com/en/docs/claude-code/skills) for working on
Astrona courses, labs, and technical training material.

Each skill lives in its own folder under [`skills/`](skills/) and is completely self-contained: a
`SKILL.md` that tells the agent what the skill does and when to use it, plus any supporting
`references/`, `scripts/`, and `assets/` it needs.

## The idea

Claude Code (and other skill-aware agents) look for skills in a few well-known folders — most
commonly `~/.claude/skills/` for your personal machine, or `.claude/skills/` inside a project.

This repo is where the skills are **authored and version-controlled**. You don't copy the folders
into `~/.claude/skills/` — that would leave you editing a stale copy and forgetting to commit. Instead
you **symlink** each skill from this repo into the folder the agent reads. Then:

- The agent picks the skill up as if it were installed normally.
- You edit the files here, in git, and every change is live immediately.
- `git pull` updates every skill at once.

The [`justfile`](justfile) automates making and removing those symlinks.

## Requirements

- [`just`](https://github.com/casey/just) — `brew install just`

## Quick start

```sh
# Symlink every skill in ./skills into ~/.claude/skills/
just install

# See what's linked and whether any links are broken
just status

# Remove the symlinks this repo created (leaves everything else alone)
just uninstall
```

After `just install`, restart Claude Code (or start a new session) and the skills are available.

## Commands

| Command | What it does |
| --- | --- |
| `just install` | Symlinks each `skills/*/` folder that contains a `SKILL.md` into the vendor skills folder. Idempotent — safe to run repeatedly. Refuses to overwrite a real file or folder that's in the way. |
| `just uninstall` | Removes only the symlinks that point back into this repo. Foreign symlinks, real folders, and unrelated files are untouched. |
| `just reinstall` | `uninstall` followed by `install`. Use after renaming or deleting a skill. |
| `just status` | Prints the source and vendor paths, then lists every entry in the vendor folder: `ok`, `BROKEN` (dangling symlink), or `file` (not a symlink). |

## Choosing where skills get installed

By default the vendor folder is `~/.claude/skills/`. Override it with the `CLAUDE_SKILLS_DIR`
environment variable — useful for installing into a single project instead of your whole machine:

```sh
# Install into the current project's .claude/skills/ folder
CLAUDE_SKILLS_DIR=.claude/skills just install

# Install for a different tool
CLAUDE_SKILLS_DIR=~/.config/some-agent/skills just install
```

The same variable is respected by `uninstall`, `status`, and `reinstall`.

## Repository layout

```
astrona-skills/
├── justfile              # install / uninstall / status / reinstall
├── README.md
└── skills/
    └── astrona-course-lab/
        ├── SKILL.md       # required — name, description, instructions
        ├── README.md      # optional — human docs for this skill
        ├── references/    # optional — docs the agent reads on demand
        ├── scripts/       # optional — helper scripts the skill runs
        └── assets/        # optional — templates, fixtures, images
```

## Adding a new skill

1. Create `skills/<your-skill-name>/`.
2. Add a `SKILL.md` with YAML frontmatter:

   ```markdown
   ---
   name: your-skill-name
   description: One or two sentences on what the skill does and when the agent should reach for it.
   ---

   # Your Skill Name

   Instructions for the agent...
   ```

3. Run `just install` (or `just reinstall` if you're also renaming/removing others).
4. Commit the new folder.

A folder without a `SKILL.md` is skipped by `just install` and reported by `just status`.

## How the symlinks look

`just install` creates ordinary `ln -s` symlinks with **absolute** targets:

```
~/.claude/skills/astrona-course-lab -> /Users/you/Developer/astrona.io/astrona-skills/skills/astrona-course-lab
```

Verify from a terminal — this is the source of truth:

```sh
ls -la ~/.claude/skills/
readlink ~/.claude/skills/astrona-course-lab
```

Note: macOS **Finder** does not show an arrow badge for `ln -s` symlinks (only for Finder
"aliases"), so a real symlink can look like a plain folder there. Trust `ls -la`.
