#!/usr/bin/env bash
# Install GitHub CLI (gh) from GitHub's official apt repo. Used for PRs,
# issue triage, and any gh-based workflow. After install, run `gh auth login`
# once interactively (needs a browser).

if command -v gh >/dev/null; then
  ok "gh already installed ($(gh --version | head -1))"
  return 0
fi

log "adding GitHub CLI's official apt repo"

sudo install -m 0755 -d /etc/apt/keyrings
if [ ! -f /etc/apt/keyrings/githubcli-archive-keyring.gpg ]; then
  curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg \
    | sudo tee /etc/apt/keyrings/githubcli-archive-keyring.gpg >/dev/null
  sudo chmod go+r /etc/apt/keyrings/githubcli-archive-keyring.gpg
fi

arch="$(dpkg --print-architecture)"
echo "deb [arch=$arch signed-by=/etc/apt/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" \
  | sudo tee /etc/apt/sources.list.d/github-cli.list >/dev/null

log "installing gh"
sudo apt-get update -y
sudo apt-get install -y gh

if ! command -v gh >/dev/null; then
  err "gh install failed — check sudo access and apt errors above"
  return 1
fi

ok "installed gh ($(gh --version | head -1))"
warn "run 'gh auth login' once to authenticate (needs a browser)"
