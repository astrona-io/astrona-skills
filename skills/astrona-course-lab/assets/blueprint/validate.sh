#!/usr/bin/env bash
# Grading script for {{path_id}} — {{title}}
# Exit 0 = pass, non-zero = fail. Check ACTUAL content/behaviour, not just that
# a resource exists (the declarative `validation.checks` in config.yaml already
# cover existence). Treat this like a test assertion.
set -euo pipefail

# --- example (kind runtime): verify a configmap's real value -------------------
# VALUE=$(kubectl get configmap hello-config -n lab-ns -o jsonpath='{.data.message}')
# if [ "$VALUE" != "hello world" ]; then
#   echo "expected data.message='hello world', got '$VALUE'"
#   exit 1
# fi

echo "validate.sh: no assertions implemented yet — edit validate.sh"
exit 1
