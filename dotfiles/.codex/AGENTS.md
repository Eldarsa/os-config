# jarvis machine notes (all agents)

Machine-wide guidance for any coding agent (Claude Code, Codex, GLM, …)
working on this VPS. Canonical copy: `~/os-config/dotfiles/.codex/AGENTS.md`
(Codex reads it at `~/.codex/AGENTS.md`; the global Claude `CLAUDE.md` imports it).

## Dev servers & user previews (Tailscale + Caddy)

This is a headless VPS. The user views running apps from other devices (Mac,
phone) over Tailscale — a `localhost` URL is useless to them.

- Every repo pins its dev port in its `dev` script (e.g. `next dev -p 3040`).
  The registry is `~/os-config/jarvis-proxy/PORTS.md`. Never fall back to a
  framework default port (3000/8000/8080) and never change a pinned port.
- A Caddy proxy fronts every registered dev port with HTTPS at
  **dev port + 10000**. When telling the user where to view an app, give
  `https://jarvis.taila5fd74.ts.net:<port + 10000>` — never `localhost`.
- Do not expose ports yourself: no `tailscale serve`/`funnel`, no binding
  tricks. Start the dev server normally; Caddy handles the rest.
- Secondary worktrees of one repo use base port + N. The +10000 rule still
  applies, but the extra port needs a `caddy.frag` entry in the repo root —
  see `~/os-config/jarvis-proxy/README.md` → "Adding a project".
- Checking your own work (curl, embedded/headless browser): use
  `localhost:<port>` directly; the proxy is for the user's devices.
