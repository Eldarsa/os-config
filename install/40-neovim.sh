#!/usr/bin/env bash
# Install Neovim from the official prebuilt tarball (apt's version lags) and
# bootstrap the LazyVim starter config. Plugins install themselves on first
# `nvim` launch — nothing else to do here.

# LazyVim's main runtime deps. fdfind is renamed to fd below.
ensure_pkg \
  ripgrep \
  fd-find \
  unzip \
  xclip

# --- neovim binary ----------------------------------------------------------
nvim_prefix="$HOME/.local/share/nvim-stable"
nvim_bin="$HOME/.local/bin/nvim"

if [ -x "$nvim_bin" ]; then
  ok "neovim already installed ($("$nvim_bin" --version | head -1))"
else
  case "$(uname -m)" in
    x86_64)        nvim_arch="x86_64" ;;
    aarch64|arm64) nvim_arch="arm64" ;;
    *) err "unsupported arch for neovim prebuilt: $(uname -m)"; return 1 ;;
  esac

  log "downloading latest stable neovim ($nvim_arch)"
  tmp="$(mktemp -d)"
  curl -fsSL \
    "https://github.com/neovim/neovim/releases/latest/download/nvim-linux-${nvim_arch}.tar.gz" \
    -o "$tmp/nvim.tar.gz"
  mkdir -p "$nvim_prefix"
  tar -xzf "$tmp/nvim.tar.gz" -C "$nvim_prefix" --strip-components=1
  rm -rf "$tmp"

  mkdir -p "$HOME/.local/bin"
  ln -sf "$nvim_prefix/bin/nvim" "$nvim_bin"
  ok "installed neovim to $nvim_prefix"
fi

# Debian/Ubuntu ship `fd` as `fdfind` to avoid a name clash; LazyVim wants `fd`.
if [ ! -e "$HOME/.local/bin/fd" ] && command -v fdfind >/dev/null; then
  mkdir -p "$HOME/.local/bin"
  ln -sf "$(command -v fdfind)" "$HOME/.local/bin/fd"
  ok "linked fdfind -> fd"
fi

# --- lazyvim starter --------------------------------------------------------
nvim_config="$HOME/.config/nvim"
if [ -d "$nvim_config" ]; then
  ok "$nvim_config already exists (leaving alone)"
else
  log "cloning LazyVim starter into $nvim_config"
  git clone --depth=1 https://github.com/LazyVim/starter "$nvim_config"
  rm -rf "$nvim_config/.git"
  ok "LazyVim starter ready — first 'nvim' launch will install plugins"
fi
