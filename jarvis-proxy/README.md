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

## Adding a new project

1. Pick a free port from `PORTS.md` (3000–8999, **not** a framework default).
2. Add a block to `Caddyfile.tmpl`:
   ```
   __HOST__:1XXXX {
       import tls_jarvis
       reverse_proxy 127.0.0.1:XXXX
   }
   ```
3. Update the table in `PORTS.md`.
4. Re-run bootstrap: `cd ~/os-config && ./bootstrap.sh` (idempotent), or
   just `sudo systemctl reload caddy` if you only edited the Caddyfile.

## Diagnostics

```
jarvis-status                  # one-shot health summary
sudo systemctl status caddy
journalctl -u caddy -f
sudo systemctl list-timers caddy-tailscale-cert.timer
```
