# jarvis-proxy

A single Caddy reverse proxy on `jarvis` that fronts every dev server with a
real public-trust HTTPS cert (issued by Tailscale). Removes the secure-context
restrictions that break `crypto.subtle`, Service Workers, Clipboard API, etc.
when accessing dev URLs from other tailnet devices (laptop, phone, iPad).

## Files

| File | Goes to | Purpose |
|---|---|---|
| `Caddyfile.tmpl` | `/etc/caddy/Caddyfile` (rendered) | Per-port reverse-proxy map. `__HOST__` is replaced at install time. |
| `refresh-tailscale-cert.sh` | `/usr/local/bin/` | Renew the tailscale cert; reload Caddy iff fingerprint changed. |
| `caddy-tailscale-cert.service` + `.timer` | `/etc/systemd/system/` | Daily renewal check + 2 min after boot. |
| `PORTS.md` | (just docs) | Source of truth for port assignments. Edit when adding a project. |

## Adding a project

**Default — and what every project here actually does (`bday`, `wedding-card`,
`venturetime`, `wall-club`, …): drop a `caddy.frag` at the repo root.** Owned or
not, long-lived or not. It needs no os-config edit and no render.

1. Pick a free port from `PORTS.md` (3000–8999, **not** a framework default).
2. Create `caddy.frag` at the repo root:
   ```caddy
   jarvis.<tailnet>.ts.net:1XXXX {
       import tls_jarvis
       reverse_proxy 127.0.0.1:XXXX
   }
   ```
3. Pin the port in the repo's `dev` script (`next dev -p XXXX`) so it can't
   drift back to a framework default.
4. Framework host allowlist — the preview origin is not `localhost`, so dev
   asset/action requests get blocked without it:
   - **Next.js** (`next.config.*`):
     `allowedDevOrigins: ['jarvis.taila5fd74.ts.net', 'jarvis']`
     (full hostname required — `'jarvis.*'` does NOT glob)
   - **Vite** (`vite.config.*`):
     `server.allowedHosts: ['jarvis.taila5fd74.ts.net']`
5. `sudo systemctl reload caddy`. The rendered Caddyfile globs
   `/home/eldar/code/*/caddy.frag` and absorbs every matching file. Removing the
   project = delete the frag and reload.
6. Record the port in `PORTS.md` (note "via `caddy.frag`").
7. Preview from any tailnet device (Mac browser, phone, Orca's embedded
   browser) at `https://jarvis.taila5fd74.ts.net:1XXXX` — HTTPS with a real
   cert, so secure-context APIs (clipboard, service workers, WebCrypto) work.
   Don't use `tailscale serve` for dev previews; this proxy is the convention.

Notes:
- The `tls_jarvis` snippet is defined in the main Caddyfile and is visible from
  imported frags.
- One broken frag fails Caddy reload for *all* sites. Run
  `sudo caddy validate --config /etc/caddy/Caddyfile` after editing.
- **Never place a git worktree directly under `~/code/`** — its checked-out
  copy of `caddy.frag` gets globbed too, and the duplicate site address breaks
  Caddy reload for everything. Orca's worktrees live in `~/orca/workspaces/`
  (outside the glob), which is safe.

### Running multiple worktrees of one repo at once

The pinned port is per-repo, so a second live worktree needs its own port.
Convention: a repo owns the ten-port block starting at its base port
(e.g. gamevault 3040–3049). Main checkout runs the base; a concurrent worktree
runs `next dev -p <base+N>`, and you add the matching `1XXXX → XXXX` block to
the repo's `caddy.frag` for the slots you actually use. `allowedDevOrigins`
matches by hostname, not port — no change needed there. Agents previewing
their own worktree via Orca's embedded browser can just use `localhost:<port>`
and skip the proxy entirely.

### Rare: baking a block into the template

Edit `Caddyfile.tmpl` directly **only** if you specifically want the entry in the
rendered base config rather than a per-repo frag. Add the
`__HOST__:1XXXX { … }` block, update `PORTS.md`, then **re-render**:
`cd ~/os-config && ./bootstrap.sh`. A plain `sudo systemctl reload caddy` will
**not** pick up a template edit — the rendered `/etc/caddy/Caddyfile` is
unchanged until you re-render. Never keep both a template block and a
`caddy.frag` for the same port: duplicate site address breaks Caddy.

## Diagnostics

```
jarvis-status                  # one-shot health summary
sudo systemctl status caddy
journalctl -u caddy -f
sudo systemctl list-timers caddy-tailscale-cert.timer
```
