# Jarvis Port Registry

Single source of truth for dev ports running on this machine. The `jarvis-proxy`
Caddy instance fronts each one with HTTPS at **port + 10000**, using the
public-trust cert tailscale issues for `<host>.<tailnet>.ts.net`.

## Policy

- Every dev service pins a unique port in **3000–8999** in its repo's `dev` script.
- Default ports (3000, 8000, 8080) are forbidden — they collide.
- The HTTPS proxy port is always **local + 10000**. No exceptions.
- Adding a new project: pick the next free port from this table, add a block to
  `Caddyfile.tmpl`, re-run `bootstrap.sh` (or `sudo systemctl reload caddy`).

## Registry

| Project | Local port | HTTPS proxy | Notes |
|---|---|---|---|
| labelit web | 4070 | 14070 | Next.js |
| labelit backend | 4071 | 14071 | Bun/Hono |
| labelit promo | 4080 | 14080 | Next.js |
| controlroom | 4000 | 14000 | Next.js |
| pikazo web | 3070 | 13070 | Next.js |
| pikazo backend | 8050 | 18050 | Bun/Hono |
| Morolapper | 3010 | 13010 | Next.js (was 3000 — renumbered to free up the default) |
| Morolapper backend | 3100 | 13100 | Python/uvicorn (Docker) |
| nevy | 3020 | 13020 | Next.js (was 3000 — renumbered) |

## Reserved ranges (informal)

- **30xx** — Morolapper / nevy / smaller experiments
- **31xx** — backends paired with the above
- **40xx** — labelit & controlroom
- **80xx** — pikazo backend

Don't treat these as binding; treat the table above as binding.

## URL convention

Local dev (any device, when SSH-tunneled or on the same machine):

    http://localhost:<local-port>

From any tailnet device (HTTPS, secure context, real cert):

    https://jarvis.taila5fd74.ts.net:<local-port + 10000>

The HTTPS form is what mobile devices and other machines on the tailnet should
use. Without HTTPS, browser features like `crypto.subtle`, Service Workers,
and the Clipboard API are silently disabled.
