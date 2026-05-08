#!/usr/bin/env bash
# Bare-minimum packages every machine needs before anything else.

log "refreshing apt index and upgrading system packages"

# 1. Update package index and upgrade what's already installed.
#    Two separate commands (not chained with &&) so set -e halts on real failures.
sudo apt-get update -y
sudo apt-get upgrade -y

# 2. Install essential packages (idempotent via ensure_pkg).
ensure_pkg \
  build-essential \
  ca-certificates \
  curl \
  git
