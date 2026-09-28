#!/usr/bin/env bash
# List every file that references a module's course.md, so a split can re-sync
# all of them in one pass.
#
#   scripts/find_refs.sh <course-root> <section-id> <module-id>
#   scripts/find_refs.sh <path-to-module-course.md-or-module-dir>
#
# Prints one `file:line: <matched text>` per reference, grouped, to stdout.
# Searches *.md, *.yaml, *.yml under <course-root>.
# Exit 0 on success (even with zero hits), 2 on bad args.
set -euo pipefail

usage() {
  echo "usage: find_refs.sh <course-root> <section-id> <module-id>" >&2
  echo "       find_refs.sh <path-to-module-course.md-or-module-dir>" >&2
  exit 2
}

ROOT="" SECTION="" MODULE=""
case $# in
  1)
    p="$1"
    if [ -f "$p" ]; then
      mdir="$(cd "$(dirname "$p")" && pwd)"
    elif [ -d "$p" ]; then
      mdir="$(cd "$p" && pwd)"
    else
      echo "ERROR: not a file or directory: $p" >&2; exit 2
    fi
    MODULE="$(basename "$mdir")"
    SECTION="$(basename "$(dirname "$mdir")")"
    ROOT="$(cd "$mdir/../../.." && pwd)"
    ;;
  3)
    ROOT="$1"; SECTION="$2"; MODULE="$3"
    [ -d "$ROOT/sections/$SECTION/$MODULE" ] || {
      echo "ERROR: module dir not found: $ROOT/sections/$SECTION/$MODULE" >&2; exit 2; }
    ROOT="$(cd "$ROOT" && pwd)"
    ;;
  *) usage ;;
esac

# Course file basenames we accept
COURSE_RE='(course|courses|COURSES)\.md'
# FULL_RE  — a path segment <section>/<module>/ anywhere. Searched repo-wide:
#            manifest paths, cross-section links, lab READMEs.
# REL_RE   — a bare relative link ](./ or ](../ <module>/course.md. Only meaningful
#            in files that live inside this section's own tree, so it is searched
#            ONLY under sections/<section>/ and labs/<section>/ — otherwise it
#            matches every other section's identically-numbered module dir.
FULL_RE="sections/${SECTION}/${MODULE}(/|\"|\)|'|[[:space:]]|\$)"
REL_RE="\]\((\./|\.\./)*${MODULE}/${COURSE_RE}"

echo "# references to sections/${SECTION}/${MODULE}/ under ${ROOT}"
found=0
emit() { grep -nE "$2" "$1" | sed "s#^#${1#$ROOT/}:#" && found=1; }

while IFS= read -r -d '' f; do
  grep -qnE "$FULL_RE" "$f" 2>/dev/null && emit "$f" "$FULL_RE"
done < <(find "$ROOT" \( -name '*.md' -o -name '*.yaml' -o -name '*.yml' \) \
           -not -path '*/.git/*' -print0)

for scope in "$ROOT/sections/$SECTION" "$ROOT/labs/$SECTION"; do
  [ -d "$scope" ] || continue
  while IFS= read -r -d '' f; do
    grep -qnE "$REL_RE" "$f" 2>/dev/null && emit "$f" "$REL_RE"
  done < <(find "$scope" -name '*.md' -not -path '*/.git/*' -print0)
done

[ "$found" -eq 1 ] || echo "# (no references found)"
exit 0
