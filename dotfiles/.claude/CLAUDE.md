# Personal context for Claude Code

This file is loaded into every Claude Code session on this user account.
Project-specific guidance belongs in a project's own CLAUDE.md, not here.

## About me

(fill in: role, common stack, conventions you want enforced)

## Defaults I want

### Branch policy: stay on the current branch for continuous work

**Do NOT make a new branch for every phase, hotfix, or follow-up.** When work is part of one continuous effort — a structural fix, a hotfix for a regression in that fix, a deeper redesign of the same subsystem — stack commits on the current branch. Do not branch off `staging` every time the task name changes.

**Default to the fewest branch operations that ship the commits — ideally zero new branches.** Before creating any branch, ask: "do the commits I want to ship already live on a branch I can PR from as-is?"

- If you just pushed a PR and the user asks for changes / a follow-up / a deeper redo of the same work → **same branch**, new commit. The PR description can be updated.
- **Before opening a PR, check what already exists.** If a branch's diff against the base *is already exactly* the commits you want to ship — e.g. its earlier PR merged and only the new commits remain ahead of `staging` — open the new PR **from that existing branch**. A branch may carry a second PR after its first one merged; reusing it is correct and expected.
- **Never cherry-pick already-committed work onto a freshly-named branch** to get a tidier name or a "cleaner" single-concern PR. A stale-but-accurate branch name is not worth a new branch, duplicate commits, and a branch graveyard. (Cherry-pick onto a new branch is only justified when the commits are *entangled* with unrelated work on their current branch and genuinely can't be PR'd in isolation otherwise.)
- A merged prior PR does **not** by itself justify a new branch. "Related but separately scoped" still loses to "already sitting on a branch I can PR from."
- "Conceptual task changed" is not a signal to branch. The user thinks of all the work in one back-and-forth as one effort.
- When in doubt, **ask** before branching. The cost of a wrong branch-creation is high (review surface fragmented, branch graveyard, mental overhead). The cost of asking is one line.

If you've already created an unnecessary branch, surface that you did and offer to fold the work back onto the branch it belongs on, then delete the stray branch + remote. Don't quietly pile up branches and hope no one notices.

**Orca worktrees are not a violation of this policy.** On machines using Orca (e.g. jarvis), a worktree per task — each with its own branch — is the intended workflow. The rule translates as: one continuous effort = one worktree = one branch. Follow-ups, hotfixes, and deeper redos of that effort go in the *same* worktree on the *same* branch; don't spawn a new child worktree for what is really a follow-up.

### Verify PR/branch state before claiming it

**Never state a PR's or branch's status (open, merged, closed, ahead/behind) from memory or conversation context — check it first** (`gh pr view <n> --json state,mergedAt`, `git fetch` + `git rev-list`). Repos change between turns and between sessions: PRs get merged from the GitHub UI, branches get deleted on merge, checkouts get switched. A stale claim ("#48 is still open") leads to wrong plans and wasted work. This applies before ANY recommendation that depends on repo state — merge orders, deploy sequencing, "you still need to merge X". Checking costs one command; being wrong costs a re-plan.

### Merge strategy for PRs

**Do NOT default to `--squash` when merging.** Pattern-matching off a single recent commit in `git log` is not policy. Pick based on the PR's shape:

- **Rebase + merge** — default for any PR with meaningful per-commit structure, multiple Co-Authored-By trailers, or work from multiple sessions/agents. Preserves history for `git bisect`, blame, and audit.
- **Merge commit** — branch-to-branch promotions (e.g. `staging → main`) where each feature commit should remain visible in the target's history.
- **Squash** — only when the inside is a WIP trail (`fix typo`, `actually fix`, `tests`) AND the PR title is the only commit message worth keeping. If the commits inside have distinct meaning, don't squash.

When uncertain — especially with Co-Authored-By trailers from other sessions/agents — **ask before merging**, don't guess.

`gh repo view --json mergeCommitAllowed,squashMergeAllowed,rebaseMergeAllowed` tells you what's permitted; the criteria above tell you what's right.

## Machine-wide agent notes (jarvis)

Dev servers, Tailscale/Caddy preview URLs, and port conventions on this
machine — shared with all agents (canonical file lives at ~/.codex/AGENTS.md):

@~/.codex/AGENTS.md
