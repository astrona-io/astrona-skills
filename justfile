# astrona-skills — install skills as symlinks into a vendor Claude skills folder

# Where skill sources live (each subdir with a SKILL.md is one skill)
src_dir := justfile_directory() / "skills"

# Vendor target. Override: `just skills_dir=.claude/skills install`
skills_dir := env_var_or_default("CLAUDE_SKILLS_DIR", home_directory() / ".claude" / "skills")

_default:
    @just --list

# Symlink every skill in ./skills into the vendor skills folder
install:
    #!/usr/bin/env bash
    set -euo pipefail
    mkdir -p "{{skills_dir}}"
    shopt -s nullglob
    count=0
    for skill in "{{src_dir}}"/*/; do
        [ -f "${skill}SKILL.md" ] || { echo "skip (no SKILL.md): ${skill}"; continue; }
        name="$(basename "$skill")"
        link="{{skills_dir}}/${name}"
        target="${skill%/}"
        if [ -L "$link" ]; then
            cur="$(readlink "$link")"
            [ "$cur" = "$target" ] && { echo "ok    ${name}"; count=$((count+1)); continue; }
            rm "$link"
        elif [ -e "$link" ]; then
            echo "ERROR: ${link} exists and is not a symlink — refusing to touch" >&2
            exit 1
        fi
        ln -s "$target" "$link"
        echo "link  ${name} -> ${target}"
        count=$((count+1))
    done
    echo "installed ${count} skill(s) into {{skills_dir}}"

# Remove only the symlinks that point back into this repo
uninstall:
    #!/usr/bin/env bash
    set -euo pipefail
    [ -d "{{skills_dir}}" ] || { echo "nothing to do: {{skills_dir}} missing"; exit 0; }
    shopt -s nullglob
    for link in "{{skills_dir}}"/*; do
        [ -L "$link" ] || continue
        case "$(readlink "$link")" in
            "{{src_dir}}"/*) rm "$link"; echo "unlink $(basename "$link")" ;;
        esac
    done

# Show current state of the vendor skills folder
status:
    #!/usr/bin/env bash
    set -euo pipefail
    echo "src:    {{src_dir}}"
    echo "vendor: {{skills_dir}}"
    echo
    [ -d "{{skills_dir}}" ] || { echo "(vendor folder does not exist yet)"; exit 0; }
    shopt -s nullglob
    for link in "{{skills_dir}}"/*; do
        name="$(basename "$link")"
        if [ -L "$link" ]; then
            tgt="$(readlink "$link")"
            [ -e "$link" ] && state="ok" || state="BROKEN"
            printf '%-8s %s -> %s\n' "$state" "$name" "$tgt"
        else
            printf '%-8s %s (not a symlink)\n' "file" "$name"
        fi
    done

# Re-link from scratch
reinstall: uninstall install
