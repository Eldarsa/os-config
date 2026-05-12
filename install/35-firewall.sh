#!/usr/bin/env bash
# Configure ufw: default-deny incoming, allow SSH (rate-limited), and trust
# the Tailscale interface fully. Outbound stays open. Safe to re-run.
#
# Note: docker publishes container ports via its own iptables chains that
# bypass ufw. When you DON'T want a docker port public, bind it explicitly:
#     docker run -p 127.0.0.1:3000:3000 ...      # localhost only
#     docker run -p 100.96.190.13:3000:3000 ...  # Tailscale IP only
# The Hetzner cloud firewall is the second line of defense for this.

ensure_pkg ufw

# Default policies (no-op if already correct).
sudo ufw default deny incoming >/dev/null
sudo ufw default allow outgoing >/dev/null

# SSH from anywhere, rate-limited to slow brute-force attempts.
# ufw detects existing equivalent rules and skips silently — fully idempotent.
sudo ufw limit 22/tcp comment 'SSH (rate-limited)' >/dev/null

# Mosh UDP range — survives laptop sleep / network drops where SSH can't.
# Hetzner Cloud Firewall must also allow this range for public-IP connections.
sudo ufw allow 60000:61000/udp comment 'mosh' >/dev/null

# Trust the Tailscale interface fully — your tailnet is private by design.
# Rule is preserved even if tailscale0 doesn't exist yet; activates when it does.
sudo ufw allow in on tailscale0 comment 'tailscale' >/dev/null

# Enable LAST, after rules are in place. --force skips the disconnect warning.
if sudo ufw status | grep -q "Status: active"; then
  ok "ufw already active"
else
  log "enabling ufw"
  sudo ufw --force enable
fi

log "ufw status:"
sudo ufw status verbose
