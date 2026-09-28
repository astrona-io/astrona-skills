#!/usr/bin/env bash
# Lint one or more rewritten lab-01/ directories for the common defects this
# skill exists to prevent. Not a grader — a fast sanity pass after a rewrite.
#
# Usage:
#   check_lab_docs.sh labs/section-010/module-01/lab-01 [more...]
#   check_lab_docs.sh --all            # every labs/section-*/*/lab-01 under CWD
#
# Exit 0 clean, 1 if any issue found.

set -u

fail=0
note() { printf '%s\n' "$*"; fail=1; }

targets=()
if [[ "${1:-}" == "--all" ]]; then
  while IFS= read -r d; do targets+=("$d"); done < <(find labs -type d -name 'lab-01' 2>/dev/null | sort)
  [[ ${#targets[@]} -eq 0 ]] && { echo "no labs/section-*/*/lab-01 found under $PWD"; exit 1; }
else
  [[ $# -eq 0 ]] && { echo "usage: $0 <lab-01-dir>... | --all"; exit 2; }
  targets=("$@")
fi

for d in "${targets[@]}"; do
  q="$d/question.md"; s="$d/solution.md"
  [[ -s "$q" ]] || note "$d: question.md missing or empty"
  [[ -s "$s" ]] || note "$d: solution.md missing or empty"
  [[ -s "$q" && -s "$s" ]] || continue

  # question.md must not carry a verification / grading section
  grep -qiE '^#+ *verification' "$q" && note "$q: has a Verification section (remove it)"
  grep -q '/usr/local/bin/validate' "$q" && note "$q: mentions validate-*.sh (grading belongs in solution.md)"
  grep -qi 'astrona submit' "$q" && note "$q: mentions 'astrona submit' (belongs in solution.md only)"

  # stale generic template leftovers
  for pat in 'perform the step-by-step commands detailed in' \
             'guided training session' 'This is a \*\*guided training lab' \
             'see the textbook' 'fully detailed inside'; do
    grep -qi "$pat" "$q" "$s" && note "$d: stale template phrase: $pat"
  done

  # solution.md must drive the astrona feedback loop with the grading command.
  # Form: astrona submit --git <url> -c labs/section-XXX/<mod>/lab-01
  want="labs/${d#labs/}"; want="${want%/}"
  grep -qE "astrona submit --git \S+ -c $want(\s|\$)" "$s" || note "$s: no 'astrona submit --git <url> -c $want'"
  grep -q 'astrona test' "$s" && note "$s: uses 'astrona test' — the learner grading command is 'astrona submit'"
  grep -qE 'astrona submit -c labs/' "$s" && note "$s: 'astrona submit -c …' is missing the required --git <url>"
  while IFS= read -r p; do
    [[ "$p" == "$want" ]] || note "$s: an astrona -c path ($p) points at a different lab (stale copy?)"
  done < <(grep -oE 'astrona submit --git \S+ -c labs/section-[0-9]+/[a-z0-9-]+/lab-01' "$s" | grep -oE 'labs/section-[0-9]+/[a-z0-9-]+/lab-01' | sort -u)

  grep -qiE '^#+ *the feedback loop' "$s" || note "$s: no 'The feedback loop' section"
  grep -qiE '\*\*run the check\*\*|run the check' "$s" || note "$s: no per-step 'Run the check' cue"
  grep -qiE '^#+ *if a check stays red|^#+ *if (something|a check)' "$s" || note "$s: no troubleshooting section"

  # shell-shortcut smell in learner-facing commands
  grep -qE '^[A-Z_]+=\"?\$\(' "$s" && note "$s: captures a value with \$( ) — spell it out for beginners"
done

if [[ $fail -eq 0 ]]; then
  echo "OK: ${#targets[@]} lab(s) look consistent with the skill's contract"
fi
exit $fail
