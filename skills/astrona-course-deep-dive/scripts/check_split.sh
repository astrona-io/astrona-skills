#!/usr/bin/env bash
# Validate a module that has been split into course.md + course-0N-*.md parts.
#
#   scripts/check_split.sh <course-root> <section-id> <module-id>
#   scripts/check_split.sh <path-to-module-dir>
#
# Checks:
#   1. astrona.yaml parses as YAML.
#   2. course.md still exists in the module dir.
#   3. every course-0N-*.md in the dir is referenced by astrona.yaml, and every
#      manifest path under sections/<section>/<module>/ exists on disk.
#   4. each part file has:  '# Part N' H1,  '> Prerequisite:' breadcrumb,
#      an italic pull-quote line,  '## Reference' section.
#   5. balanced ``` fences in course.md and every part.
#   6. every ./course-0X-*.md link inside a part resolves to a real file.
#
# Exit 0 clean, 1 on any check failure, 2 on bad args.
set -euo pipefail

usage() {
  echo "usage: check_split.sh <course-root> <section-id> <module-id>" >&2
  echo "       check_split.sh <path-to-module-dir>" >&2
  exit 2
}

case $# in
  1)
    [ -d "$1" ] || { echo "ERROR: not a directory: $1" >&2; exit 2; }
    MDIR="$(cd "$1" && pwd)"
    MODULE="$(basename "$MDIR")"
    SECTION="$(basename "$(dirname "$MDIR")")"
    ROOT="$(cd "$MDIR/../../.." && pwd)"
    ;;
  3)
    ROOT="$1"; SECTION="$2"; MODULE="$3"
    MDIR="$ROOT/sections/$SECTION/$MODULE"
    [ -d "$MDIR" ] || { echo "ERROR: module dir not found: $MDIR" >&2; exit 2; }
    ROOT="$(cd "$ROOT" && pwd)"; MDIR="$(cd "$MDIR" && pwd)"
    ;;
  *) usage ;;
esac

MANIFEST="$ROOT/astrona.yaml"
[ -f "$MANIFEST" ] || MANIFEST="$ROOT/astrona.yml"
fail=0
note() { printf 'FAIL  %s\n' "$*"; fail=1; }
ok()   { printf 'ok    %s\n' "$*"; }

# --- 1. manifest parses -------------------------------------------------------
if [ ! -f "$MANIFEST" ]; then
  note "no astrona.yaml / astrona.yml at $ROOT"
elif command -v python3 >/dev/null 2>&1; then
  if python3 -c "import yaml,sys; yaml.safe_load(open(sys.argv[1]))" "$MANIFEST" 2>/dev/null; then
    ok "astrona.yaml parses"
  else
    note "astrona.yaml does not parse as YAML"
  fi
else
  echo "warn  python3 missing — skipped YAML parse check"
fi

# --- 2. course.md still present ---------------------------------------------
LANDING=""
for c in course.md courses.md COURSES.md; do
  [ -f "$MDIR/$c" ] && LANDING="$MDIR/$c" && break
done
[ -n "$LANDING" ] && ok "landing page present ($(basename "$LANDING"))" \
                  || note "no course.md in $MDIR"

# --- 3. parts <-> manifest cross-check ------------------------------------
shopt -s nullglob
PARTS=( "$MDIR"/course-[0-9][0-9]-*.md )
shopt -u nullglob
if [ ${#PARTS[@]} -eq 0 ]; then
  note "no course-0N-*.md part files found in $MDIR"
fi

MANLINES=""
[ -f "$MANIFEST" ] && MANLINES="$(grep -E "sections/${SECTION}/${MODULE}/" "$MANIFEST" || true)"

for p in "${PARTS[@]}"; do
  rel="sections/${SECTION}/${MODULE}/$(basename "$p")"
  if printf '%s\n' "$MANLINES" | grep -qF "$rel"; then
    ok "manifest references $(basename "$p")"
  else
    note "$(basename "$p") is not referenced in astrona.yaml"
  fi
done

if [ -f "$MANIFEST" ]; then
  # every manifest path under this module must exist on disk
  while IFS= read -r path; do
    [ -z "$path" ] && continue
    if [ -e "$ROOT/$path" ]; then
      ok "manifest path exists: $path"
    else
      note "manifest path missing on disk: $path"
    fi
  done < <(grep -oE "sections/${SECTION}/${MODULE}/[A-Za-z0-9_./-]+" "$MANIFEST" | sort -u)
fi

# --- 4. part file structure ---------------------------------------------------
for p in "${PARTS[@]}"; do
  b="$(basename "$p")"
  grep -qE '^# Part [0-9]+ (—|-|--) '           "$p" || note "$b: missing '# Part N — ' H1"
  grep -qE '^> *Prerequisite:'                  "$p" || note "$b: missing '> Prerequisite:' breadcrumb"
  grep -qE '^> \*.+\*$'                         "$p" || note "$b: missing italic pull-quote line ('> *...*')"
  grep -qE '^## Reference *$'                   "$p" || note "$b: missing '## Reference' section"
done

# --- 5. balanced fences -----------------------------------------------------
for f in "$LANDING" "${PARTS[@]}"; do
  [ -f "$f" ] || continue
  n="$(grep -cE '^```' "$f" || true)"
  if [ $(( n % 2 )) -eq 0 ]; then
    ok "fences balanced: $(basename "$f") ($n)"
  else
    note "$(basename "$f"): odd number of \`\`\` fences ($n)"
  fi
done

# --- 6. intra-part links resolve -----------------------------------------
for p in "${PARTS[@]}"; do
  b="$(basename "$p")"
  while IFS= read -r target; do
    [ -z "$target" ] && continue
    [ -f "$MDIR/$target" ] || note "$b: link to ./$target does not resolve"
  done < <(grep -oE '\]\(\./(course-[0-9][0-9]-[A-Za-z0-9_-]+\.md)\)' "$p" \
            | sed -E 's#\]\(\./##; s#\)##' | sort -u)
done

echo
if [ "$fail" -eq 0 ]; then
  echo "PASS — split looks consistent"
  exit 0
else
  echo "one or more checks FAILED"
  exit 1
fi
