#!/usr/bin/env bash
# Bare-minimum packages every machine needs before anything else.

log "refreshing apt index"

# 1. Update system and install system tools
apt-get update && apt-get upgrade -y

# 2. Install essential packages
# Uses a common.sh helper to ensure packages are installed only once.
ensure_pkg \
  build-essential \
  ca-certificates \
  curl \
  git \
  

