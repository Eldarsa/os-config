#!/usr/bin/env bash
# Install zsh, make it the login shell, and link our .zshrc.

ensure_pkg zsh

zsh_path="$(command -v zsh)"
current_shell="$(getent passwd "$USER" | cut -d: -f7)"

if [ "$current_shell" = "$zsh_path" ]; then
  ok "login shell already zsh"
else
  log "changing login shell to $zsh_path (may prompt for password)"
  chsh -s "$zsh_path" "$USER"
fi

link_dotfile .zshrc .zshrc
