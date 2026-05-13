# Design: `/jarvis-check-error-reports` skill

**Date:** 2026-05-13
**Status:** Approved, ready for implementation plan
**Type:** Personal Claude Code skill

## Problem

The autonomous Sentry triage routine posts daily digests to `#jarvis`. Reports flag issues as "unresolved / escalating" purely on Sentry's state — they don't cross-check whether a fix has already shipped to `main`. As a result, the same issue is repeatedly listed as "top priority" with a proposed fix, even when the proposed fix has already been merged and the issue has stopped firing.

On 2026-05-13 this caused a near-miss: the day's report still recommended a patch to `apps/web/src/lib/services/direct-upload-service.ts:74-78` for PIKAZO-1G, when the real fix (PR #112) had already merged via staging→main PR #113 (commit `fbc8c14`) two days earlier and the issue had zero events since. Acting on the recommendation would have wasted a coding session and conflicted with the deployed fix.

A persistent memory was added (`feedback_sentry_triage_verification.md`) to remind future sessions to verify fix status before acting. This skill is the systematized version of that rule.

## Goals

- Reconcile the last 4 days of `#jarvis` Sentry triage reports against current Sentry state and shipped fixes.
- Surface three buckets clearly: already fixed (recommend resolving in Sentry), still open with actionable next step, and noise.
- Make resolving fixed-but-unresolved issues a one-click batch action.
- Stay read-only by default — no Sentry/Slack/git writes without explicit user confirmation.

## Non-goals

- Auto-resolving issues without user confirmation.
- Applying proposed fixes automatically. The skill points to them; applying is a follow-up session.
- Posting summaries back to `#jarvis`. (Future: a separate scheduled routine could do this; see "Future work.")
- Scanning the entire Sentry org. Input is bounded by the editorial filter the triage routine already applies.
- Replacing the triage routine itself.

## Approach

Pure prose skill, no helper scripts. Frontmatter + body of `SKILL.md` describes the workflow as discrete phases. Claude orchestrates existing MCP tools (Slack, Sentry) and shells out to `git` via Bash. No new infrastructure, no language runtime.

Rejected alternatives:
- **Skill + helper script.** Would re-implement Slack/Sentry clients the MCP servers already provide.
- **Sub-agent dispatch.** Right shape for a scheduled routine; wrong shape for an interactive slash command where the user batch-confirms actions.

## Architecture

### Location

- **Source:** `~/os-config/dotfiles/.claude/skills/jarvis-check-error-reports/SKILL.md`
- **Live path:** `~/.claude/skills/jarvis-check-error-reports/SKILL.md` (linked from `os-config` during bootstrap)
- **Invocation:** `/jarvis-check-error-reports`

The skill is tracked in `os-config` so it survives reprovisioning and follows the existing convention in `dotfiles/.claude/skills.list`'s header comment: authored skills live in the repo and are linked into `~/.claude/`.

### Frontmatter

```yaml
---
name: jarvis-check-error-reports
description: Reconcile the last 4 days of Sentry triage reports in #jarvis against current Sentry status and recent fix commits. Surfaces already-fixed-but-unresolved issues for batch resolve, still-open items needing work, and noise to skip.
---
```

## Workflow

The skill body instructs Claude through five phases.

### Phase 1 — Discovery

1. Read `#jarvis` (channel ID `C0B3PA344SU`, fall back to `slack_search_channels query=jarvis` if not found). Use `slack_read_channel` with `oldest` set to ~96h ago.
2. Filter to messages whose body starts with `:bellhop_bell: _Sentry triage —`.
3. For each kept message, extract:
   - Report date (from message ts)
   - Per-project sections (`_pikazo_`, `_labelit_`, …)
   - Issue IDs from Sentry URLs (`https://venturetime.sentry.io/issues/<ID>`)
   - Status emoji (`:new:`, `:repeat:`, `:chart_with_upwards_trend:`, `:white_check_mark:`)
   - Event / user counts as reported that day
   - Any `:microscope:` Investigation block — capture the "Specific fix:" file:line path
   - The "Top priority" recommendation line
4. Aggregate by issue ID across the 4-day window. Per unique issue, record:
   - First and last mention dates
   - All proposed fixes (file:line + summary)
   - All reports it appeared in

If no triage messages are found, print "No triage posts in last 4 days" and exit.

### Phase 2 — Per-issue verification

For each unique issue:

#### 2a. Fetch current Sentry state

`get_sentry_resource` by issue URL. Capture: `status`, `substatus`, `lastSeen`, `release` tag on the most recent event, top first-party stack frame file path, `trace_id`.

On HTTP 500, retry once with the `url=` form. On second failure, mark "lookup-failed" and continue.

If the issue no longer exists in Sentry (404), mark "deleted-or-merged" and skip.

#### 2b. Resolve repo path

Case-insensitive match of the Sentry project slug against directories in `~/code/`. Examples:
- `pikazo` → `~/code/pikazo`
- `labelit` → `~/code/labelit`
- `Morolapper` → `~/code/Morolapper`
- `labelmaker-backend` → `~/code/labelmaker-backend`

If no match found, skip Signal B for this issue but continue with A and C; note in output.

#### 2c. Run fix signals (only if still unresolved)

Before any signal check, run `git -C <repo> fetch --quiet` to avoid stale-clone false negatives. (Learned: my local pikazo was 3 commits behind during the 2026-05-13 session.)

- **Signal A — Commit references issue ID:**
  ```
  git -C ~/code/<repo> log origin/main --oneline --since='<firstSeen>' --grep='<ISSUE-ID>'
  ```
  For any match, confirm it's actually merged to main:
  ```
  git merge-base --is-ancestor <sha> origin/main
  ```
  Capture SHA, subject, author date. If the commit references the ID but is only on `staging`, classify as `fix-shipped-unclear` with note "fix on staging, not yet merged to main."

- **Signal B — Top-frame file modified after last event:**
  Extract first-party path from the stack frame (anything outside `node_modules/` and `_next/`). Then:
  ```
  git -C ~/code/<repo> log origin/main --since='<lastSeen>' -- <path>
  ```
  Any commits found = post-event change in the implicated file.

  **Skip when no first-party path exists** — minified client-side stacks (e.g. `/_next/static/chunks/6020-xxx.js`) and "No stacktrace available" events can't be mapped to a source path. Note in output as "(Signal B skipped — no source-mapped frame)" and continue.

- **Signal C — Sibling issue resolved:**
  `search_issues query='is:resolved'` scoped to the project, statsPeriod=14d. Compare each resolved issue's `trace_id` and title against the current issue. If a match is found, surface as a candidate twin.

#### 2d. Verify proposed fix (if the triage included one)

If the report listed `apps/web/src/foo.ts:74-78` as the "Specific fix":
- `git -C <repo> log origin/main --since='<report_date>' -- <path>` — did the file get touched after the recommendation?
- If yes, `git show` the change and check whether it implements the proposed semantics. Surface the result in the output.

#### 2e. Classify

| Bucket | Trigger | Recommended action |
|---|---|---|
| `fixed-known` | Sentry status already `resolved` | none |
| `fixed-pending-resolve` | unresolved, Signal A matches AND last event predates that commit's merge time | mark resolved |
| `fixed-by-twin` | unresolved, Signal C found a resolved sibling sharing `trace_id` | mark resolved (with twin reference) |
| `fix-shipped-unclear` | unresolved, AND either: Signal B only (file touched, no ID ref, no events since), OR Signal A matched but the commit is on `staging` and not yet in `origin/main` | flag for manual review |
| `open-actionable` | unresolved, has proposed-fix in triage, file untouched since report | recommend applying the proposed fix |
| `open-needs-attention` | unresolved, ≥10 events OR ≥5 users, no fix signals | flag for investigation |
| `noise` | unresolved, ≤2 events OR third-party stack (Instagram/Facebook WebView, CookieYes, vendor SDKs) OR self-healing (`outcome: succeeded_on_retry`) | suggest skip |

Thresholds (10 events, 5 users, 2 events) are written inline in the skill body so they can be tuned by editing the file.

### Phase 3 — Presentation

Print to terminal in this order, each section omitted if empty:

1. **Header:** "Analyzed N triage reports (date range), M unique issues."
2. **✅ Already resolved in Sentry** — one-liner per issue.
3. **🟢 Likely fixed — recommend marking resolved** — `fixed-pending-resolve` and `fixed-by-twin`. Show issue ID, title, last event time + release, fix commit + merge time, events since (should be 0), which signal triggered.
4. **⚠️ Open — has a proposed fix waiting** — `open-actionable`. Show proposed-fix file:line and whether the file has been touched since.
5. **🔴 Open — needs attention** — `open-needs-attention`. Volume, last seen, brief context.
6. **🟡 Low-signal / noise** — `noise`. One-liner each with reason.

Each issue line includes its Sentry URL so the user can jump straight to it.

### Phase 4 — Batch resolve

If `fixed-pending-resolve` ∪ `fixed-by-twin` is non-empty, present the list via `AskUserQuestion` with `multiSelect=true`. Default: all selected. The user can deselect any candidate they want to leave open.

On confirmation, call `update_issue status=resolved` in parallel for each selected issue. Use ID-form (`organizationSlug=venturetime, issueId=<ID>`) to avoid the URL-form 500s we saw in this session.

If the user declines or selects none, exit cleanly and print the candidate list as a copy-pasteable record.

### Phase 5 — Read-only guarantee

Phases 1–3 perform zero writes. Phase 4 only writes when the user has explicitly confirmed which issues to resolve. The skill performs no `git commit`, no Slack post, no `gh pr`, no `mark as ignored` in Sentry.

## Edge cases (covered above, summarized here)

- No triage messages in window → exit cleanly.
- Stale local repo → `git fetch --quiet` before signal checks.
- Repo not present locally → skip Signal B, continue.
- Sentry 500 → retry with `url=` form, then mark "lookup-failed."
- Slack channel ID stale → fall back to `slack_search_channels`.
- Issue deleted/merged in Sentry → mark and skip.
- Fix only on staging, not main → classify `fix-shipped-unclear`.
- User declines batch resolve → exit with copy-pasteable list.

## Future work (out of scope for v1)

- Scheduled variant that posts a verification summary back to `#jarvis` — a separate routine, not this skill. Could reuse the same prose as the agent prompt.
- "Apply proposed fix" auto-mode for `open-actionable` items — would need a planning step (`superpowers:writing-plans`) and likely should stay manual.
- Cross-project metrics (e.g., median time from "top priority" recommendation to fix shipped).

## Testing

Manual verification on first run:
1. Invoke `/jarvis-check-error-reports` in a clean session.
2. Confirm it finds 3–4 triage reports.
3. Confirm it correctly identifies LABELIT-1A and PIKAZO-1G as already-resolved (since we resolved them in this session, they should now appear in `fixed-known`).
4. Confirm the open issues (PIKAZO-1H, PIKAZO-8, PIKAZO-9, PIKAZO-16, etc.) appear in the correct buckets.
5. Verify no Sentry/Slack writes happen unless the batch-resolve prompt is confirmed.

## References

- Memory: `~/.claude/projects/-home-eldar/memory/feedback_sentry_triage_verification.md`
- Skill convention: `~/os-config/dotfiles/.claude/skills.list` (header comment about authored skills)
- Bootstrap: `~/os-config/install/60-claude-skills.sh`
- Related session: 2026-05-13 triage analysis that motivated this design.
