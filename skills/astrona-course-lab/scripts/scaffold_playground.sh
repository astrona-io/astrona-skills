#!/usr/bin/env bash
# Scaffold a playground: a clean, ungraded environment nested inside a course
# module folder, resolved as <course-root>/sections/<section-id>/<module-id>/.
# That folder must contain courses.md.
#
#   scripts/scaffold_playground.sh --section net-basics --module static-routing \
#     --runtime kind|qemu [--course-root .] [--slug net-play] \
#     [--title "Networking Playground"] [--path-id PLAYGROUND] \
#     [--author-name "Jane Doe"] [--description "..."] \
#     [--repo-url https://github.com/org/course] [--branch main] \
#     [--git-url ssh://git@github.com/org/course.git] [--force]
#
# Reads the module's courses.md for a title (first H1) when --title is absent,
# copies assets/playground/ into <module>/playground/ with template vars filled,
# adds a runtime: block for qemu, and inserts a playground callout into
# courses.md right under the module title (a `> [!NOTE]` GitHub alert — blue
# info box on GitHub) so a reader sees up front that a runnable playground
# exists.
#
# If <module>/playground/ already exists, the script stops with exit 3 (no
# overwrite) so the caller can ask the user; --force overwrites.
#
# The callout link is an ABSOLUTE repo browse URL, not ./playground/, because
# courses.md is read on GitHub / GitLab / the Astrona site, not a local clone.
# It is resolved from --repo-url, else the module's git 'origin' remote; with
# neither it falls back to a relative link and warns.
#
# The callout's `astrona run` uses `--git <url> -c <repo-root path>` so a reader
# who never cloned can copy-paste it; --git-url overrides the derived ssh URL.
# `astrona destroy` takes the environment name (metadata.name = the slug), not
# the config path.
set -euo pipefail

SKILL_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TEMPLATE="$SKILL_DIR/assets/playground"

SECTION_ID="" MODULE_ID="" COURSE_ROOT="." SLUG="" TITLE="" RUNTIME=""
PATH_ID="PLAYGROUND" AUTHOR="" DESCRIPTION="" FORCE=0 REPO_URL="" BRANCH="" GIT_URL=""
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
    --repo-url)     REPO_URL="$2"; shift 2 ;;
    --branch)       BRANCH="$2"; shift 2 ;;
    --git-url)      GIT_URL="$2"; shift 2 ;;
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
  echo "EXISTS: $TARGET already exists." >&2
  echo "        Ask the user whether to update it. To regenerate one part, use" >&2
  echo "        '/astrona-course-lab update <part> $SECTION_ID $MODULE_ID playground'." >&2
  echo "        To overwrite the whole playground, re-run this with --force." >&2
  exit 3
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

# --- resolve an absolute web link to the playground folder ------------------
# courses.md is read on GitHub / GitLab / the Astrona site, not from a local
# clone, so the ## Playground link must be an absolute repo URL.
git_web_base() {
  # normalize a git remote URL to an https browse base, no trailing .git
  local u="$1"
  u="${u%.git}"
  case "$u" in
    git@*:*)
      local host="${u#git@}"; host="${host%%:*}"
      printf 'https://%s/%s' "$host" "${u#*:}" ;;
    ssh://git@*)
      printf 'https://%s' "${u#ssh://git@}" ;;
    https://*|http://*)
      printf '%s' "$u" | sed -E 's#^(https?://)[^/@]*@#\1#' ;;
    *)
      printf '%s' "$u" ;;
  esac
}

git_ssh_url() {
  # normalize a git remote URL to an ssh clone URL astrona run --git can use
  local u="$1"
  case "$u" in
    ssh://*)   printf '%s' "$u" ;;
    git@*:*)
      local host="${u#git@}"; host="${host%%:*}"
      printf 'ssh://git@%s/%s' "$host" "${u#*:}" ;;
    https://*|http://*)
      printf 'ssh://git@%s' "$(printf '%s' "$u" | sed -E 's#^https?://([^/@]*@)?##')" ;;
    *)         printf '%s' "$u" ;;
  esac
}

GIT_ROOT="" WEB_BASE="" RAW_REMOTE=""
if git -C "$MODULE" rev-parse --show-toplevel >/dev/null 2>&1; then
  GIT_ROOT="$(git -C "$MODULE" rev-parse --show-toplevel)"
  RAW_REMOTE="$(git -C "$MODULE" remote get-url origin 2>/dev/null || true)"
fi
if [ -n "$REPO_URL" ]; then
  WEB_BASE="$(git_web_base "$REPO_URL")"
elif [ -n "$RAW_REMOTE" ]; then
  WEB_BASE="$(git_web_base "$RAW_REMOTE")"
fi

# path of the playground relative to the repo root — used for the browse link
# and for `astrona run ... -c <path>`. Ask git so /private vs /var symlinks on
# macOS do not break a string prefix strip.
REL_PATH=""
[ -n "$GIT_ROOT" ] && REL_PATH="$(cd "$TARGET" && git rev-parse --show-prefix)" && REL_PATH="${REL_PATH%/}"
[ -n "$REL_PATH" ] || REL_PATH="sections/$SECTION_ID/$MODULE_ID/playground"

# ssh clone URL for `astrona run --git`: --git-url wins, else derive from origin
GIT_SSH=""
if [ -n "$GIT_URL" ]; then
  GIT_SSH="$GIT_URL"
elif [ -n "$RAW_REMOTE" ]; then
  GIT_SSH="$(git_ssh_url "$RAW_REMOTE")"
fi

PLAYGROUND_LINK=""
if [ -n "$WEB_BASE" ]; then
  [ -n "$BRANCH" ] || BRANCH="$(git -C "$MODULE" rev-parse --abbrev-ref HEAD 2>/dev/null || true)"
  case "$BRANCH" in ""|HEAD) BRANCH="main" ;; esac
  case "$WEB_BASE" in
    *gitlab*) PLAYGROUND_LINK="$WEB_BASE/-/tree/$BRANCH/$REL_PATH" ;;
    *)        PLAYGROUND_LINK="$WEB_BASE/tree/$BRANCH/$REL_PATH" ;;
  esac
fi

if grep -q 'astrona:playground' "$COURSES" || grep -q '^## Playground' "$COURSES"; then
  LINKED="courses.md already has a playground callout — left as is"
else
  if [ -n "$PLAYGROUND_LINK" ]; then
    PG_HREF="$PLAYGROUND_LINK"
    LINKED="inserted playground callout (link: $PLAYGROUND_LINK)"
  else
    PG_HREF="./playground/"
    LINKED="inserted playground callout with a RELATIVE link — no git repo URL found"
    {
      echo "WARNING: no git repo URL for the playground link."
      echo "         courses.md is read on GitHub/GitLab/the Astrona site, not a local clone,"
      echo "         so a relative ./playground/ link will be broken there."
      echo "         Re-run with --repo-url <https url> [--branch <name>], or run inside a"
      echo "         git checkout whose 'origin' remote points at the course repo."
    } >&2
  fi

  # run command: pull the playground straight from git by repo-root path so a
  # reader who never cloned can copy-paste it. destroy takes the environment
  # NAME that run reports (metadata.name = the slug), not the config path.
  if [ -n "$GIT_SSH" ]; then
    RUN_CMD="astrona run --git $GIT_SSH -c $REL_PATH"
  else
    RUN_CMD="astrona run -c $REL_PATH"
  fi
  DESTROY_CMD="astrona destroy $SLUG"

  # A callout right under the module title, so a reader sees up front that a
  # runnable playground exists — not buried at the bottom of the module.
  # `> [!NOTE]` is a GitHub alert: renders as a blue info box on GitHub and on
  # any renderer with GFM-alert support. GitHub strips styled HTML (no class/
  # style attributes), so an alert is the only portable "blue box". Renderers
  # without alert support fall back to a plain blockquote — the 🧪 marker keeps
  # it reading as a callout there.
  BLOCK="$(printf '<!-- astrona:playground -->\n> [!NOTE]\n> 🧪 **Hands-on playground for this module** — a clean, throwaway machine to explore on. No task, no grading. Folder: [`playground/`](%s)\n>\n> ```sh\n> %s\n> %s\n> ```\n' "$PG_HREF" "$RUN_CMD" "$DESTROY_CMD")"
  H1_LINE="$(grep -n -m1 -E '^#[[:space:]]+' "$COURSES" | cut -d: -f1 || true)"
  if [ -n "$H1_LINE" ]; then
    INS="$H1_LINE" LEAD=$'\n'
    NEXT=$((H1_LINE + 1))
    [ -z "$(sed -n "${NEXT}p" "$COURSES")" ] && { INS="$NEXT"; LEAD=""; }
    { head -n "$INS" "$COURSES"; printf '%s%s\n\n' "$LEAD" "$BLOCK"; tail -n +"$((INS + 1))" "$COURSES"; } > "$COURSES.tmp" && mv "$COURSES.tmp" "$COURSES"
    LINKED="$LINKED, below the title (line $INS)"
  else
    { printf '%s\n\n' "$BLOCK"; cat "$COURSES"; } > "$COURSES.tmp" && mv "$COURSES.tmp" "$COURSES"
    LINKED="$LINKED, at the top (no H1 found)"
  fi
fi

echo >&2
echo "Scaffolded playground at $TARGET :" >&2
find "$TARGET" -type f | sort >&2
echo >&2
echo "courses.md ($COURSES): $LINKED." >&2
