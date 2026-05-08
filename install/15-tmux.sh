#!/usr/bin/env bash
# Install tmux + fzf, link config and sessionizer, bootstrap tpm.
# Plugins themselves are installed on first tmux launch via `prefix + I`,
# or by running ~/.tmux/plugins/tpm/bin/install_plugins.

ensure_pkg tmux fzf

tpm_dir="$HOME/.tmux/plugins/tpm"
if [ -d "$tpm_dir/.git" ]; then
  ok "tpm already cloned"
else
  log "cloning tpm (tmux plugin manager)"
  git clone --depth=1 https://github.com/tmux-plugins/tpm "$tpm_dir"
fi

link_dotfile .tmux.conf            .tmux.conf
link_dotfile .local/bin/sessionizer .local/bin/sessionizer
chmod +x "$HOME/.local/bin/sessionizer"
