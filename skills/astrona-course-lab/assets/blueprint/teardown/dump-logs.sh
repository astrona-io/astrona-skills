#!/usr/bin/env bash
# Best-effort state capture for {{path_id}} before the environment is destroyed.
# Runs even on failure; must not exit non-zero in a way that blocks teardown.
set -uo pipefail

echo "[teardown] {{slug}}: capturing state"
# kubectl get all -A || true
