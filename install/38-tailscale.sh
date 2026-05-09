#!/usr/bin/env bash
# Install Tailscale via the official install script and make `tailscale`
# usable without sudo for $USER. Authentication (`tailscale up`) still
# requires a one-time interactive browser flow.

if command -v tailscale >/dev/null 2>&1; then
  ok "tailscale already installed ($(tailscale version | head -1))"
else
  log "installing tailscale (via official install script)"
  curl -fsSL https://tailscale.com/install.sh | sh
fi

# `tailscale set --operator` requires sudo only when the operator isn't
# already $USER. Probe by trying a command that fails iff access is denied.
if tailscale serve status >/dev/null 2>&1; then
  ok "tailscale operator already set"
else
  log "setting tailscale operator to $USER (sudo)"
  sudo tailscale set --operator="$USER"
fi

if ! tailscale status --json >/dev/null 2>&1; then
  warn "tailscale is installed but not authenticated."
  warn "Run once: sudo tailscale up"
  warn "Then re-run bootstrap to wire up the proxy."
fi
