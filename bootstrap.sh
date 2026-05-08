#!/usr/bin/env bash
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export REPO_DIR

# shellcheck source=lib/common.sh
source "$REPO_DIR/lib/common.sh"

log "bootstrapping from $REPO_DIR"

shopt -s nullglob
for step in "$REPO_DIR"/install/*.sh; do
  log "running $(basename "$step")"
  # shellcheck source=/dev/null
  source "$step"
done

ok "bootstrap complete"
