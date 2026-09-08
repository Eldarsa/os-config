# jarvis machine notes (all agents)

Machine-wide guidance for any coding agent (Claude Code, Codex, GLM, …)
working on this VPS. Canonical copy: `~/os-config/dotfiles/.codex/AGENTS.md`
(Codex reads it at `~/.codex/AGENTS.md`; the global Claude `CLAUDE.md` imports it).

## Never assume ANY git state from memory — verify it first

**Never assert any git or repo state from memory or conversation context —
check it with a command first.** Output you obtained earlier in the *same*
turn counts as checked; anything from a previous turn, a previous session,
or another agent does not. The rule covers, non-exhaustively:

- a PR's status (open, merged, closed) and a branch's position (ahead/behind,
  what it points at) — `gh pr view <n> --json state,mergedAt`, `git fetch` +
  `git rev-list --left-right --count`;
- **whether a branch, remote branch, tag, or worktree even exists** —
  `git ls-remote --heads origin`, `git worktree list` (branches get deleted
  on merge; long-lived branches like `staging` can be deleted by mistake);
- **which branch is checked out, what HEAD/a ref points at, and the default
  branch** — `git branch --show-current`, `git rev-parse`,
  `gh repo view --json defaultBranchRef` (don't assume `main` — repos here
  use different bases, and the default can be changed in repo settings);
- the working tree/status and whether local is in sync with the remote —
  `git status`, `git fetch` first.

Repos change between turns, between sessions, and out from under you
(GitHub-UI merges, force-pushes, other agents/people, branch cleanup). A
stale claim ("#48 is still open", "staging is at X", "we're on branch Y")
leads to wrong plans, wrong bases, and wasted work. This applies before ANY
action or recommendation that depends on repo state — merge orders, deploy
sequencing, choosing a PR base, "you still need to merge X". Always
`git fetch` before reasoning about remote state. Checking costs one command;
being wrong costs a re-plan.

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
