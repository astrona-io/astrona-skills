#!/usr/bin/env bash
# List every module under a section and whether it has a linked playground.
#
#   scripts/list_section_modules.sh <course-root> <section-id>
#   scripts/list_section_modules.sh <path-to-section-dir>
#
# A module is any immediate subdirectory of the section that contains a course
# file (course.md / courses.md / COURSES.md). Prints one line per module,
# sorted by module id:
#
#   <module-id>   LINKED|NOT_LINKED   <course-file>
#
# and a trailing summary line to stderr. Exit 0 on success, 2 on bad args /
# missing section / no modules found.
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

case $# in
  1)
    [ -d "$1" ] || { echo "ERROR: not a directory: $1" >&2; exit 2; }
    SECTION_DIR="$(cd "$1" && pwd)"
    ;;
  2)
    SECTION_DIR="$1/sections/$2"
    [ -d "$SECTION_DIR" ] || { echo "ERROR: section dir not found: $SECTION_DIR" >&2; exit 2; }
    SECTION_DIR="$(cd "$SECTION_DIR" && pwd)"
    ;;
  *)
    echo "usage: list_section_modules.sh <course-root> <section-id>" >&2
    echo "       list_section_modules.sh <path-to-section-dir>" >&2
    exit 2
    ;;
esac

found=0 linked=0 unlinked=0
for mod in "$SECTION_DIR"/*/; do
  mod="${mod%/}"
  [ -d "$mod" ] || continue
  mid="$(basename "$mod")"
  course=""
  for c in "$mod/course.md" "$mod/courses.md" "$mod/COURSES.md"; do
    [ -f "$c" ] && { course="$c"; break; }
  done
  [ -n "$course" ] || continue
  found=$((found + 1))

  status_line="$("$HERE/playground_status.sh" "$course" 2>/dev/null || true)"
  case "$status_line" in
    LINKED*)   state="LINKED";     linked=$((linked + 1)) ;;
    *)         state="NOT_LINKED"; unlinked=$((unlinked + 1)) ;;
  esac
  printf '%s\t%s\t%s\n' "$mid" "$state" "$course"
done

[ "$found" -gt 0 ] || { echo "ERROR: no modules with a course file under $SECTION_DIR" >&2; exit 2; }
echo "section $(basename "$SECTION_DIR"): $found module(s) — $linked linked, $unlinked without a playground" >&2
