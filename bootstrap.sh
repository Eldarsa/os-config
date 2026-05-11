#!/usr/bin/env bash
set -eEuo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export REPO_DIR

# shellcheck source=lib/common.sh
source "$REPO_DIR/lib/common.sh"

current_step=""
on_error() {
  local code=$?
  err "bootstrap failed in step: ${current_step:-<pre-step setup>} (exit $code)"
  err "fix the above error, then re-run ./bootstrap.sh — earlier steps are idempotent"
  exit "$code"
}
trap on_error ERR

log "bootstrapping from $REPO_DIR"

shopt -s nullglob
for step in "$REPO_DIR"/install/*.sh; do
  current_step="$(basename "$step")"
  log "running $current_step"
  # shellcheck source=/dev/null
  source "$step"
done
current_step=""

ok "bootstrap complete"
