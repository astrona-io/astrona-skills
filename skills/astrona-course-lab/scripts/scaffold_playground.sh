#!/usr/bin/env bash
# Scaffold a playground: a clean, ungraded environment nested inside a course
# module folder, resolved as <course-root>/sections/<section-id>/<module-id>/.
# That folder must contain courses.md.
#
#   scripts/scaffold_playground.sh --section net-basics --module static-routing \
#     --runtime kind|qemu [--course-root .] [--slug net-play] \
#     [--title "Networking Playground"] [--path-id PLAYGROUND] \
#     [--author-name "Jane Doe"] [--description "..."] [--force]
#
# Reads the module's courses.md for a title (first H1) when --title is absent,
# copies assets/playground/ into <module>/playground/ with template vars filled,
# adds a runtime: block for qemu, and appends a "## Playground" section to
# courses.md so the folder and the module stay linked.
set -euo pipefail

SKILL_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TEMPLATE="$SKILL_DIR/assets/playground"

SECTION_ID="" MODULE_ID="" COURSE_ROOT="." SLUG="" TITLE="" RUNTIME=""
PATH_ID="PLAYGROUND" AUTHOR="" DESCRIPTION="" FORCE=0
while [ $# -gt 0 ]; do
  case "$1" in
    --section)      SECTION_ID="$2"; shift 2 ;;
    --module)       MODULE_ID="$2"; shift 2 ;;
    --course-root)  COURSE_ROOT="$2"; shift 2 ;;
    --slug)         SLUG="$2"; shift 2 ;;
    --title)        TITLE="$2"; shift 2 ;;
    --runtime)      RUNTIME="$2"; shift 2 ;;
    --path-id)      PATH_ID="$2"; shift 2 ;;
    --author-name)  AUTHOR="$2"; shift 2 ;;
    --description)  DESCRIPTION="$2"; shift 2 ;;
    --force)        FORCE=1; shift ;;
    *)              echo "unknown flag: $1" >&2; exit 2 ;;
  esac
done

[ -n "$SECTION_ID" ] || { echo "ERROR: --section <section-id> is required" >&2; exit 2; }
[ -n "$MODULE_ID" ]  || { echo "ERROR: --module <module-id> is required" >&2; exit 2; }
[ -d "$COURSE_ROOT" ] || { echo "ERROR: course root not found: $COURSE_ROOT" >&2; exit 2; }

MODULE="$COURSE_ROOT/sections/$SECTION_ID/$MODULE_ID"
if [ ! -d "$MODULE" ]; then
  echo "ERROR: module dir not found: $MODULE" >&2
  echo "       expected <course-root>/sections/<section-id>/<module-id>/" >&2
  exit 2
fi

COURSES=""
for c in "$MODULE/courses.md" "$MODULE/course.md" "$MODULE/COURSES.md"; do
  [ -f "$c" ] && { COURSES="$c"; break; }
done
[ -n "$COURSES" ] || { echo "ERROR: no courses.md in $MODULE" >&2; exit 2; }

case "${RUNTIME:-}" in
  ""|kind|qemu) ;;
  *) echo "ERROR: --runtime must be kind or qemu" >&2; exit 2 ;;
esac

if [ -z "$TITLE" ]; then
  TITLE="$(grep -m1 -E '^#[[:space:]]+' "$COURSES" | sed -E 's/^#[[:space:]]+//; s/[[:space:]]+$//' || true)"
  [ -n "$TITLE" ] || TITLE="Playground"
fi
if [ -z "$SLUG" ]; then
  BASE="$(printf '%s' "$SECTION_ID-$MODULE_ID" | tr '[:upper:]' '[:lower:]' | sed -E 's/[^a-z0-9]+/-/g; s/^-+//; s/-+$//')"
  case "$BASE" in
    *playground) SLUG="$BASE" ;;
    *)           SLUG="${BASE:-playground}-playground" ;;
  esac
fi
[ -n "$AUTHOR" ] || AUTHOR="$(git config user.name 2>/dev/null || echo 'Author Name')"

eval "$("$SKILL_DIR/scripts/lab_env.sh")"
echo "Building playground for astrona CLI $ASTRONA_VERSION (blueprint: $BLUEPRINT_SOURCE)." >&2

TARGET="$MODULE/playground"
if [ -e "$TARGET" ] && [ "$FORCE" -ne 1 ]; then
  echo "ERROR: $TARGET already exists (use --force to overwrite)" >&2
  exit 2
fi
rm -rf "$TARGET"
mkdir -p "$TARGET"
cp -R "$TEMPLATE/." "$TARGET/"

subst() {
  sed -e "s|{{path_id}}|${PATH_ID}|g" \
      -e "s|{{slug}}|${SLUG}|g" \
      -e "s|{{title}}|${TITLE}|g" \
      -e "s|{{author_name}}|${AUTHOR}|g" \
      -e "s|{{description}}|${DESCRIPTION}|g" \
      "$1" > "$1.tmp" && mv "$1.tmp" "$1"
}
find "$TARGET" -type f -print0 | while IFS= read -r -d '' f; do subst "$f"; done
chmod +x "$TARGET/bootstrap/prepare.sh"

if [ "$RUNTIME" = "qemu" ]; then
  cat >> "$TARGET/config.yaml" <<'YAML'

runtime:
  type: "qemu"
  qemu:
    # Set a real image source + arch for the host — see references/astrona-cli.md.
    - name: ""
      image:
        type: "oci"
        source: "ghcr.io/astrona-io/ubuntu-24.04-server-docker:arm64"
      cpus: 2
      memoryMB: 2048
      diskSizeGB: 20
      sshPasswordAuth: false
YAML
fi

if ! grep -q '^## Playground' "$COURSES"; then
  cat >> "$COURSES" <<'MD'

## Playground

A clean, ungraded sandbox for this module: [`playground/`](./playground/).

```sh
astrona run -c playground
astrona destroy -c playground
```
MD
  LINKED="appended ## Playground section"
else
  LINKED="already had a ## Playground section — left as is"
fi

echo >&2
echo "Scaffolded playground at $TARGET :" >&2
find "$TARGET" -type f | sort >&2
echo >&2
echo "courses.md ($COURSES): $LINKED." >&2
