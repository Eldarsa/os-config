#!/usr/bin/env bash
# Install mosh — UDP-based replacement for SSH that survives laptop sleep,
# IP changes, and network drops. Initial handshake is still SSH (TCP/22),
# then traffic moves to UDP on a port in 60000:61000 (opened in 35-firewall.sh).
#
# For public-IP connections, the Hetzner Cloud Firewall must also allow that
# UDP range. Tailscale-routed connections are unaffected — tailscale0 is
# fully trusted in ufw.

ensure_pkg mosh
