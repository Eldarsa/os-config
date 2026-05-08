#!/usr/bin/env bash
# Bare-minimum packages every machine needs before anything else.

log "refreshing apt index"
sudo apt-get update -y

ensure_pkg \
  build-essential \
  ca-certificates \
  curl \
  git
