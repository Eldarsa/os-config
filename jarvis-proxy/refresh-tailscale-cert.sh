#!/usr/bin/env bash
# Refresh the tailscale-issued cert for this machine and reload Caddy if it
# changed. Idempotent: tailscale only re-fetches when the cached cert is close
# to expiry. Host is auto-detected from `tailscale status` so this script works
# on any tailnet node.
set -euo pipefail

HOST="${1:-}"
if [ -z "$HOST" ]; then
	HOST=$(tailscale status --json 2>/dev/null | jq -r '.Self.DNSName' | sed 's/\.$//' || true)
fi
if [ -z "$HOST" ] || [ "$HOST" = "null" ]; then
	echo "refresh-tailscale-cert: could not determine tailscale hostname" >&2
	exit 1
fi

CERT_DIR="/var/lib/caddy"
CERT="$CERT_DIR/jarvis.crt"
KEY="$CERT_DIR/jarvis.key"

mkdir -p "$CERT_DIR"

OLD_FP=""
if [ -f "$CERT" ]; then
	OLD_FP=$(openssl x509 -in "$CERT" -noout -fingerprint -sha256 2>/dev/null || true)
fi

tailscale cert --cert-file "$CERT" --key-file "$KEY" "$HOST"

chown caddy:caddy "$CERT" "$KEY"
chmod 644 "$CERT"
chmod 640 "$KEY"

NEW_FP=$(openssl x509 -in "$CERT" -noout -fingerprint -sha256)

if [ "$OLD_FP" != "$NEW_FP" ]; then
	echo "Cert changed; reloading caddy."
	systemctl reload caddy
else
	echo "Cert unchanged; not reloading."
fi
