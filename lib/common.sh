#!/usr/bin/env bash
# Sourced by bootstrap.sh and every install/*.sh script.
# Keep helpers small and idempotent.

log()  { printf '\033[1;34m==>\033[0m %s\n' "$*"; }
ok()   { printf '\033[1;32m  ok\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33m  !!\033[0m %s\n' "$*" >&2; }
err()  { printf '\033[1;31m  xx\033[0m %s\n' "$*" >&2; }

# Install one or more apt packages, skipping any already present.
ensure_pkg() {
  local missing=()
  for pkg in "$@"; do
    if dpkg -s "$pkg" >/dev/null 2>&1; then
      ok "$pkg already installed"
    else
      missing+=("$pkg")
    fi
  done
  if [ ${#missing[@]} -gt 0 ]; then
    log "installing: ${missing[*]}"
    sudo apt-get install -y "${missing[@]}"
  fi
}

# Symlink $REPO_DIR/dotfiles/<src> to $HOME/<dest>, backing up anything in the way.
link_dotfile() {
  local src="$REPO_DIR/dotfiles/$1"
  local dest="$HOME/$2"
  mkdir -p "$(dirname "$dest")"
  if [ -L "$dest" ] && [ "$(readlink "$dest")" = "$src" ]; then
    ok "linked: ~/$2"
    return
  fi
  if [ -e "$dest" ] || [ -L "$dest" ]; then
    warn "backing up existing ~/$2 -> ~/$2.bak"
    mv "$dest" "$dest.bak"
  fi
  ln -s "$src" "$dest"
  ok "linked: ~/$2 -> dotfiles/$1"
}
