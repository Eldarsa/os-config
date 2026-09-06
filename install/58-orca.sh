#!/usr/bin/env bash
# Orca remote server: install the desktop package (headless serve mode) and the
# systemd user service. Docs: https://www.onorca.dev/docs/remote-servers
#
# Manual steps after a rebuild (interactive OAuth / pairing — can't be scripted):
#   orca-ide account add --agent claude     # and --agent codex
#   systemctl --user restart orca-serve && journalctl --user -u orca-serve | grep 'Pairing URL'
#     → paste the pairing URL into Orca on the Mac (Settings → Remote Orca Servers)
#   orca-ide skills install --skill orca-cli --skill orchestration

if command -v orca-ide >/dev/null; then
  ok "orca-ide already installed ($(orca-ide --version 2>/dev/null | head -1))"
else
  log "installing latest orca-ide .deb from stablyai/orca releases"
  tmp="$(mktemp -d)"
  gh release download -R stablyai/orca -p 'orca-ide_*_amd64.deb' -D "$tmp"
  sudo apt-get install -y "$tmp"/orca-ide_*_amd64.deb
  rm -rf "$tmp"
fi

# Systemd user service (copied, not symlinked — systemd refuses out-of-tree
# symlinked user units). NOTE: --pairing-address is this machine's Tailscale IP;
# on a rebuilt/renamed machine update it (tailscale ip -4) in the unit AND in
# dotfiles/.config/systemd/user/orca-serve.service.
mkdir -p "$HOME/.config/systemd/user"
cp -f "$REPO_DIR/dotfiles/.config/systemd/user/orca-serve.service" \
      "$HOME/.config/systemd/user/orca-serve.service"
systemctl --user daemon-reload
systemctl --user enable --now orca-serve.service
sudo loginctl enable-linger "$USER"
ok "orca-serve.service enabled (port 6768, tailnet-only per firewall model)"
