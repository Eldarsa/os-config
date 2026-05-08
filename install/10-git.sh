#!/usr/bin/env bash
# Configure git: collect identity on first run, link the shared .gitconfig,
# and ensure an ed25519 SSH key tagged with the user's real email.

ensure_pkg git openssh-client

local_config="$HOME/.gitconfig.local"

# --- collect identity (only if not already set with real values) ------------
needs_identity=true
if [ -f "$local_config" ]; then
  existing_name="$(git config --file "$local_config" user.name 2>/dev/null || true)"
  existing_email="$(git config --file "$local_config" user.email 2>/dev/null || true)"
  if [ -n "$existing_name" ] && [ -n "$existing_email" ] \
      && [ "$existing_name" != "Your Name" ] \
      && [ "$existing_email" != "you@example.com" ]; then
    ok "git identity: $existing_name <$existing_email>"
    needs_identity=false
  fi
fi

if $needs_identity; then
  log "setting git identity (saved to ~/.gitconfig.local, not committed)"
  git_name=""
  while [ -z "$git_name" ]; do
    read -rp "  full name:  " git_name </dev/tty
    [ -z "$git_name" ] && warn "name cannot be empty"
  done
  git_email=""
  while [[ "$git_email" != *"@"*"."* ]]; do
    read -rp "  email:      " git_email </dev/tty
    [[ "$git_email" != *"@"*"."* ]] && warn "that doesn't look like an email"
  done
  cat > "$local_config" <<EOF
[user]
    name = $git_name
    email = $git_email
EOF
  ok "wrote ~/.gitconfig.local"
fi

# --- link the shared config -------------------------------------------------
link_dotfile .gitconfig .gitconfig

# --- ssh key ----------------------------------------------------------------
ssh_key="$HOME/.ssh/id_ed25519"
if [ -f "$ssh_key" ]; then
  ok "ssh key already at $ssh_key"
else
  email="$(git config --file "$local_config" user.email)"
  log "generating ed25519 ssh key for $email (will prompt for optional passphrase)"
  mkdir -p "$HOME/.ssh"
  chmod 700 "$HOME/.ssh"
  ssh-keygen -t ed25519 -C "$email" -f "$ssh_key"
fi

log "public key (add to GitHub: https://github.com/settings/ssh/new)"
cat "$ssh_key.pub"
