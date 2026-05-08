#!/usr/bin/env bash
# Create the workspace directory convention. Subsequent tools (the tmux
# sessionizer in particular) assume project repos live under ~/code.

if [ -d "$HOME/code" ]; then
  ok "~/code already exists"
else
  log "creating ~/code"
  mkdir -p "$HOME/code"
fi
