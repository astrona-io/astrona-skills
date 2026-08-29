#!/usr/bin/env bash
# Scaffold a new lab from the cached, version-pinned blueprint.
#
#   scripts/scaffold_lab.sh --target ./my-lab --slug my-lab \
#     --path-id LAB042 --title "My Lab" --author-name "Jane Doe"
#
# `ats` below is the astrona CLI's content-type token, not lab branding.
# Extra args after a literal -- are passed straight to `astrona content init`.
set -euo pipefail

SKILL_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

TARGET="" SLUG="" PATH_ID="" TITLE="" AUTHOR="" DESCRIPTION=""
PASSTHRU=()
while [ $# -gt 0 ]; do
  case "$1" in
    --target)       TARGET="$2"; shift 2 ;;
    --slug)         SLUG="$2"; shift 2 ;;
    --path-id)      PATH_ID="$2"; shift 2 ;;
    --title)        TITLE="$2"; shift 2 ;;
    --author-name)  AUTHOR="$2"; shift 2 ;;
    --description)  DESCRIPTION="$2"; shift 2 ;;
    --)             shift; PASSTHRU=("$@"); break ;;
    *)              echo "unknown flag: $1" >&2; exit 2 ;;
  esac
done

for pair in "SLUG:$SLUG" "PATH_ID:$PATH_ID" "TITLE:$TITLE"; do
  [ -n "${pair#*:}" ] || { echo "ERROR: --${pair%%:*} is required" | tr 'A-Z_' 'a-z-' >&2; exit 2; }
done
[ -n "$TARGET" ] || TARGET="./$SLUG"
[ -n "$AUTHOR" ] || AUTHOR="$(git config user.name 2>/dev/null || echo 'Author Name')"

eval "$("$SKILL_DIR/scripts/lab_env.sh")"
echo "Building lab for astrona CLI $ASTRONA_VERSION (blueprint: $BLUEPRINT_SOURCE)." >&2

ARGS=(content init ats "$TARGET"
  --repo "$BLUEPRINT_DIR"
  --slug "$SLUG"
  --path-id "$PATH_ID"
  --title "$TITLE"
  --author-name "$AUTHOR")
[ -n "$DESCRIPTION" ] && ARGS+=(--description "$DESCRIPTION")
[ ${#PASSTHRU[@]} -gt 0 ] && ARGS+=("${PASSTHRU[@]}")

"$ASTRONA_BIN" "${ARGS[@]}"

echo >&2
echo "Scaffolded $TARGET :" >&2
find "$TARGET" -type f -not -path '*/.git/*' | sort >&2
