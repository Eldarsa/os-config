#!/usr/bin/env bash
# Install lazygit from upstream GitHub release (apt's version lags badly).

if command -v lazygit >/dev/null; then
  ok "lazygit already installed ($(lazygit --version 2>/dev/null | head -1))"
  return 0
fi

case "$(uname -m)" in
  x86_64)        lg_arch="x86_64" ;;
  aarch64|arm64) lg_arch="arm64" ;;
  *) err "unsupported arch for lazygit prebuilt: $(uname -m)"; return 1 ;;
esac

log "fetching latest lazygit version"
lg_version=$(curl -fsSL "https://api.github.com/repos/jesseduffield/lazygit/releases/latest" \
  | grep -Po '"tag_name": "v\K[^"]*')

if [ -z "$lg_version" ]; then
  err "could not determine latest lazygit version"
  return 1
fi

log "downloading lazygit $lg_version ($lg_arch)"
tmp="$(mktemp -d)"
curl -fsSL \
  "https://github.com/jesseduffield/lazygit/releases/latest/download/lazygit_${lg_version}_Linux_${lg_arch}.tar.gz" \
  -o "$tmp/lazygit.tar.gz"
tar -xzf "$tmp/lazygit.tar.gz" -C "$tmp" lazygit
mkdir -p "$HOME/.local/bin"
install -m 0755 "$tmp/lazygit" "$HOME/.local/bin/lazygit"
rm -rf "$tmp"
ok "installed lazygit $lg_version to ~/.local/bin/lazygit"
