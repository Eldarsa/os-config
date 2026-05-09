#!/usr/bin/env bash
# Install Caddy and configure this machine as the tailnet HTTPS reverse proxy.
# Idempotent: re-run after editing Caddyfile.tmpl or PORTS.md to apply.

# Skip cleanly if tailscale isn't authenticated yet.
if ! tailscale status --json >/dev/null 2>&1; then
  warn "tailscale not authenticated; skipping jarvis-proxy."
  warn "Run 'sudo tailscale up' first, then re-run bootstrap."
  return 0 2>/dev/null || exit 0
fi

ensure_pkg debian-keyring debian-archive-keyring apt-transport-https curl gpg jq openssl

# Add the Caddy apt repo (idempotent).
keyring=/usr/share/keyrings/caddy-stable-archive-keyring.gpg
sources=/etc/apt/sources.list.d/caddy-stable.list
if [ ! -s "$keyring" ]; then
  log "adding caddy gpg key"
  curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/gpg.key' \
    | sudo gpg --dearmor -o "$keyring"
fi
if [ ! -s "$sources" ]; then
  log "adding caddy apt source"
  curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/debian.deb.txt' \
    | sudo tee "$sources" >/dev/null
  sudo apt-get update
fi
ensure_pkg caddy

# Determine the device's MagicDNS name.
HOST=$(tailscale status --json | jq -r '.Self.DNSName' | sed 's/\.$//')
if [ -z "$HOST" ] || [ "$HOST" = "null" ]; then
  err "could not determine tailscale hostname"
  return 1 2>/dev/null || exit 1
fi
log "configuring jarvis-proxy for $HOST"

# Render Caddyfile from template.
tmp_caddyfile=$(mktemp)
trap 'rm -f "$tmp_caddyfile"' EXIT
sed "s|__HOST__|$HOST|g" "$REPO_DIR/jarvis-proxy/Caddyfile.tmpl" > "$tmp_caddyfile"

# Cert refresh script + systemd units (must exist before we can fetch the cert
# below or validate the Caddyfile, which references the cert paths).
sudo install -m 0755 "$REPO_DIR/jarvis-proxy/refresh-tailscale-cert.sh" \
  /usr/local/bin/refresh-tailscale-cert.sh
sudo install -m 0644 "$REPO_DIR/jarvis-proxy/caddy-tailscale-cert.service" \
  /etc/systemd/system/caddy-tailscale-cert.service
sudo install -m 0644 "$REPO_DIR/jarvis-proxy/caddy-tailscale-cert.timer" \
  /etc/systemd/system/caddy-tailscale-cert.timer

# Initial cert. Caddy validation provisions the full config (loads certs etc),
# so the cert must exist on disk before we can validate.
sudo /usr/local/bin/refresh-tailscale-cert.sh

# Validate before installing — bad config shouldn't replace good config.
# `--adapter caddyfile` is required when validating via --config, since Caddy
# can't infer the format from the temp filename.
if ! sudo caddy validate --adapter caddyfile --config "$tmp_caddyfile" >/dev/null 2>&1; then
  err "rendered Caddyfile failed validation:"
  sudo caddy validate --adapter caddyfile --config "$tmp_caddyfile" || true
  return 1 2>/dev/null || exit 1
fi
sudo install -m 0644 -D "$tmp_caddyfile" /etc/caddy/Caddyfile

# Enable + reload.
sudo systemctl daemon-reload
sudo systemctl enable --now caddy >/dev/null
sudo systemctl reload caddy
sudo systemctl enable --now caddy-tailscale-cert.timer >/dev/null

link_dotfile .local/bin/jarvis-status .local/bin/jarvis-status
chmod +x "$HOME/.local/bin/jarvis-status"

ok "jarvis-proxy active at https://$HOST  (per-service ports = local + 10000)"
ok "run \`jarvis-status\` for a health summary"
