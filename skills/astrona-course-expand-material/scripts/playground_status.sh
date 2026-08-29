#!/usr/bin/env bash
# Report whether a course module has a linked playground.
#
#   scripts/playground_status.sh <course-root> <section-id> <module-id>
#   scripts/playground_status.sh <path-to-course-file-or-module-dir>
#
# A module is LINKED when either:
#   - <module>/playground/ exists, or
#   - the module's course file carries `<!-- astrona:playground -->`
#     or a `## Playground` heading.
#
# Prints one line to stdout:
#   LINKED       dir=<yes|no> callout=<yes|no> file=<course file>
#   NOT_LINKED   dir=no callout=no file=<course file>
# Exit 0 on success (status is on stdout), 2 on bad args or missing files.
set -euo pipefail

usage() {
  echo "usage: playground_status.sh <course-root> <section-id> <module-id>" >&2
  echo "       playground_status.sh <path-to-course-file-or-module-dir>" >&2
  exit 2
}

MODULE=""
case $# in
  1)
    if [ -f "$1" ]; then
      MODULE="$(cd "$(dirname "$1")" && pwd)"
    elif [ -d "$1" ]; then
      MODULE="$(cd "$1" && pwd)"
    else
      echo "ERROR: not a file or directory: $1" >&2; exit 2
    fi
    ;;
  3)
    ROOT="$1"; SECTION="$2"; MOD="$3"
    MODULE="$ROOT/sections/$SECTION/$MOD"
    [ -d "$MODULE" ] || { echo "ERROR: module dir not found: $MODULE" >&2; exit 2; }
    MODULE="$(cd "$MODULE" && pwd)"
    ;;
  *)
    usage
    ;;
esac

COURSE=""
for c in "$MODULE/course.md" "$MODULE/courses.md" "$MODULE/COURSES.md"; do
  [ -f "$c" ] && { COURSE="$c"; break; }
done
[ -n "$COURSE" ] || { echo "ERROR: no course.md / courses.md in $MODULE" >&2; exit 2; }

DIR=no
[ -d "$MODULE/playground" ] && DIR=yes

CALLOUT=no
if grep -q 'astrona:playground' "$COURSE" || grep -qE '^##[[:space:]]+Playground' "$COURSE"; then
  CALLOUT=yes
fi

if [ "$DIR" = yes ] || [ "$CALLOUT" = yes ]; then
  echo "LINKED       dir=$DIR callout=$CALLOUT file=$COURSE"
else
  echo "NOT_LINKED   dir=no callout=no file=$COURSE"
fi
