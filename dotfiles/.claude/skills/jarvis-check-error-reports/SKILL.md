---
name: jarvis-check-error-reports
description: Reconcile the last 4 days of Sentry triage reports in #jarvis against current Sentry status and recent fix commits. Surfaces already-fixed-but-unresolved issues for batch resolve, still-open items needing work, and noise to skip.
---

# jarvis-check-error-reports

Announce at start: "Reconciling the last 4 days of #jarvis triage reports against current Sentry + git state."

## Phase 1 — Read triage reports

Read `#jarvis` (channel ID `C0B3PA344SU`; if not found, `slack_search_channels query=jarvis`). Use `slack_read_channel` with `oldest` set to ~96h ago.

Keep messages whose body starts with `:bellhop_bell: _Sentry triage —`. For each, extract:
- Report date (message ts)
- Issue IDs from Sentry URLs (`https://venturetime.sentry.io/issues/<ID>`)
- Any `:microscope:` "Specific fix:" line (file:line path + intent)

Dedupe by issue ID across the window. If no triage messages found, print "No triage posts in last 4 days" and exit.

## Phase 2 — Verify each unique issue

**Fetch Sentry state** with `get_sentry_resource` by issue URL. Capture: `status`, `lastSeen`, `release` of last event, top first-party frame, `trace_id`. On HTTP 500, retry once with `url=` form; if still failing, mark "lookup-failed" and continue. On 404, mark "deleted-or-merged" and skip.

**Resolve repo path** — case-insensitive match of Sentry project slug against `~/code/*` (e.g. `pikazo`→`~/code/pikazo`, `Morolapper`→`~/code/Morolapper`). If no match, skip Signal B but continue.

**Always `git -C <repo> fetch --quiet` before signal checks** — stale clones cause false negatives.

If issue is unresolved, run these signals:

- **Signal A — commit references issue ID:**
  ```
  git -C <repo> log origin/main --oneline --since='<firstSeen>' --grep='<ISSUE-ID>'
  ```
  Confirm any match is actually merged with `git merge-base --is-ancestor <sha> origin/main`. If only on `staging`, classify as `fix-shipped-unclear`.

- **Signal B — top-frame file modified after last event:**
  ```
  git -C <repo> log origin/main --since='<lastSeen>' -- <first-party path>
  ```
  Skip when the top frame is minified (`/_next/static/chunks/*.js`) or absent — note "(Signal B skipped — no source-mapped frame)."

- **Signal C — sibling resolved:**
  `search_issues query='is:resolved' projectSlugOrId=<project> statsPeriod=14d`. Match by `trace_id` or near-identical title.

**Verify proposed fix** (only if the triage included one): `git -C <repo> log origin/main --since='<report_date>' -- <proposed file>`. Surface whether the file has been touched.

## Phase 3 — Classify

| Bucket | Trigger |
|---|---|
| `fixed-known` | Sentry status already `resolved` |
| `fixed-pending-resolve` | unresolved, Signal A matches AND last event predates that commit's merge time |
| `fixed-by-twin` | unresolved, Signal C matches a resolved sibling sharing `trace_id` |
| `fix-shipped-unclear` | unresolved AND (Signal B only with no events since, OR Signal A matched but commit is on `staging` not `main`) |
| `open-actionable` | unresolved, has proposed-fix in triage, file untouched since report |
| `open-needs-attention` | unresolved, ≥10 events OR ≥5 users, no fix signals |
| `noise` | unresolved AND (≤2 events OR third-party stack (Instagram/Facebook WebView, CookieYes, vendor SDKs) OR self-healing (`outcome: succeeded_on_retry`)) |

## Phase 4 — Present

Print sections in this order, omitting any that are empty:

1. **Header:** "Analyzed N triage reports (date range), M unique issues."
2. **✅ Already resolved in Sentry** — one-liner per issue, with URL.
3. **🟢 Likely fixed — recommend marking resolved** (`fixed-pending-resolve` + `fixed-by-twin`). For each: ID, title, last event time + release, fix commit + merge time, events since (should be 0), which signal triggered.
4. **⚠️ Open — has a proposed fix waiting** (`open-actionable`). Show proposed-fix file:line and whether the file has been touched since.
5. **🔴 Open — needs attention** (`open-needs-attention`). Volume, last seen, brief context.
6. **🟡 Low-signal / noise** (`noise`). One-liner each, with reason.

Each issue line includes its Sentry URL.

## Phase 5 — Batch resolve

If `fixed-pending-resolve` ∪ `fixed-by-twin` is non-empty, present via `AskUserQuestion` with `multiSelect=true`, all selected by default. The user can deselect any to leave open.

On confirmation, call `update_issue status=resolved` in parallel for each selected issue. Use ID-form (`organizationSlug=venturetime, issueId=<ID>`) — URL-form has hit 500s.

If the set is empty, or the user selects none, exit cleanly and print the candidate list as a copy-pasteable record.

## Guarantees

- **Read-only by default** — Phases 1–3 perform zero writes. Phase 4 only writes after explicit confirmation.
- **No git commits, no Slack posts, no `gh` calls.**
- **No auto-applying proposed fixes** — `open-actionable` items are surfaced as recommendations only.
