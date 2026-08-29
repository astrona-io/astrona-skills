#!/usr/bin/env bash
# Resolve the astrona CLI, detect its version, and make sure the version-pinned
# lab blueprint cache exists. Prints shell-eval-able KEY=VALUE lines.
#
#   eval "$(scripts/lab_env.sh)"        # populate env
#   scripts/lab_env.sh --refresh        # force re-sync of the current version's cache
set -euo pipefail

SKILL_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
VENDORED_BLUEPRINT="$SKILL_DIR/assets/blueprint"
UPSTREAM="${ASTRONA_BLUEPRINT_REPO:-git@github.com:astrona-io/training-sandbox-blueprint.git}"
CACHE_ROOT="${XDG_CACHE_HOME:-$HOME/.cache}/astrona-course-lab/blueprint"

REFRESH=0
[ "${1:-}" = "--refresh" ] && REFRESH=1

ASTRONA_BIN="$(command -v astrona || true)"
if [ -z "$ASTRONA_BIN" ]; then
  echo "ERROR: astrona CLI not found in PATH. Install it first (see astrona-io/astrona-cli)." >&2
  exit 1
fi

# "astrona version developer"  or  "astrona version v0.1.8"  -> developer / v0.1.8
RAW_VERSION="$("$ASTRONA_BIN" --version 2>/dev/null | tail -n1 | awk '{print $NF}')"
[ -n "$RAW_VERSION" ] || RAW_VERSION="unknown"
# sanitize for use as a directory name
SAFE_VERSION="$(printf '%s' "$RAW_VERSION" | tr -c 'A-Za-z0-9._-' '_')"

CACHE_DIR="$CACHE_ROOT/$SAFE_VERSION"
SOURCE_MARKER="$CACHE_DIR/.blueprint-source"

sync_cache() {
  mkdir -p "$CACHE_ROOT"
  rm -rf "$CACHE_DIR"
  if git clone --quiet "$UPSTREAM" "$CACHE_DIR" >/dev/null 2>&1; then
    printf 'upstream\n' > "$SOURCE_MARKER"
  else
    mkdir -p "$CACHE_DIR"
    cp -R "$VENDORED_BLUEPRINT/." "$CACHE_DIR/"
    git -C "$CACHE_DIR" init -q
    git -C "$CACHE_DIR" add -A
    git -C "$CACHE_DIR" -c user.email=skill@astrona.local -c user.name=astrona-course-lab \
      commit -qm "vendored blueprint for astrona $RAW_VERSION"
    printf 'vendored\n' > "$SOURCE_MARKER"
  fi
}

if [ "$REFRESH" -eq 1 ] || [ ! -d "$CACHE_DIR/.git" ]; then
  sync_cache >&2
fi

BLUEPRINT_SOURCE="$(cat "$SOURCE_MARKER" 2>/dev/null || echo unknown)"

echo "ASTRONA_BIN=$ASTRONA_BIN"
echo "ASTRONA_VERSION=$RAW_VERSION"
echo "BLUEPRINT_DIR=$CACHE_DIR"
echo "BLUEPRINT_SOURCE=$BLUEPRINT_SOURCE"
echo "SKILL_DIR=$SKILL_DIR"
