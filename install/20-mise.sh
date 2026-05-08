#!/usr/bin/env bash
# Install mise (runtime version manager) and link the global config.
# After this step, `node` is available as the LTS version, managed by mise.

if command -v mise >/dev/null; then
  ok "mise already installed ($(mise --version))"
else
  log "installing mise via https://mise.run"
  curl -fsSL https://mise.run | sh
fi

# Make mise findable for the rest of this script (zshrc handles future shells).
export PATH="$HOME/.local/bin:$PATH"

link_dotfile .config/mise/config.toml .config/mise/config.toml

log "installing tools declared in global mise config"
mise install
