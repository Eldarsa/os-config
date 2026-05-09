#!/usr/bin/env bash
# System libraries Playwright's bundled Chromium needs to launch
# (libnspr4, libnss3, libasound2t64, etc.). The exact set drifts across
# Ubuntu releases, so we delegate to Playwright's own install-deps command —
# it knows which apt packages match its current bundled Chromium.
#
# This is system-level (apt). Per-project Playwright is installed as a
# devDependency in each repo and `playwright install chromium` (no --with-deps)
# fetches just the browser binary into the user cache.

if ! command -v node >/dev/null 2>&1; then
  warn "node not found; skipping playwright-deps. Re-run after 20-mise.sh."
  return 0 2>/dev/null || exit 0
fi

# Marker file lets us short-circuit on subsequent runs without re-invoking npx.
marker=/var/lib/playwright-deps.installed
if [ -f "$marker" ]; then
  ok "playwright system deps already installed"
  return 0 2>/dev/null || exit 0
fi

log "installing Playwright Chromium system dependencies (apt, via playwright install-deps)"
# `playwright install-deps` invokes sudo internally for apt; we don't wrap it
# in sudo ourselves (would run npx as root and pollute root's npm cache).
npx -y playwright@latest install-deps chromium

sudo touch "$marker"
ok "playwright system deps installed"
