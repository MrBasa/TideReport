# Phase 8 — Future & deferred

| Field | Value |
|-------|-------|
| **Status** | `pending` |
| **Started** | — |
| **Completed** | — |
| **Depends on** | [phase-03-user-features.md](phase-03-user-features.md) (`tide-report` CLI foundation) |

---

> ## Completion workflow
>
> When **every** checkbox in this document is done:
>
> 1. Set **Status** to `completed` and **Completed** to today's date.
> 2. Add a **Done notes** section (brief: PR links, caveats, follow-ups).
> 3. Update the phase row in [docs/README.md](../README.md).
> 4. Run: `git mv docs/backlog/phase-08-future-deferred.md docs/archive/phase-08-future-deferred.md`
>
> See [.cursor/rules/docs-backlog.mdc](../../.cursor/rules/docs-backlog.mdc).

---

## Goal

Features explicitly deferred from phase 3+ and optional enhancements that need product validation. Lower priority than phases 1–7.

## Checklist

### CLI extensions

- [ ] **8.1** **`tide-report bug-report` subcommand** _(recommended when filing issues becomes painful)_
  - Mirror Tide's `_tide_sub_bug-report` flow.
  - Include in output:
    - `$_tide_report_version` / `tide_report_user_agent`
    - `tide_report_*_provider` settings
    - `gh auth status` summary
    - `$XDG_STATE_HOME/tide-report/tide-report.log` tail (if exists)
    - Selected universals (refresh/expire, show_ci)
    - `$_fisher_plugins` line (Tide already prints this)
  - Add `_tide_report_sub_bug-report`; register in `tide-report` dispatcher.
  - Tests: help output + mocked env snapshot.

- [ ] **8.2** **`tide-report reload` subcommand** _(optional — low value)_
  - Only if user feedback shows confusion about `tide reload`.
  - Would thin-wrap `tide reload` with explanation—**not recommended** per phase 3 decision.
  - Skip unless explicitly requested.

### Product / UX optional

- [ ] **8.3** **Selective cache clear on update**
  - Instead of `rm -rf ~/.cache/tide-report` on every update, clear per-module or stale-only.

- [ ] **8.4** **GitHub stats expire tier**
  - Currently refresh-only by design; add expire if stale stars/forks become a reported issue.

- [ ] **8.5** **Reduce first-prompt git subprocess cost**
  - [`__tide_report_github_context`](../functions/_tide_item_github.fish): 3× `git` on first repo visit; optional `.git` file reads only.

### Review carry-over (optional)

- [ ] **8.6** **Timing-based "never block prompt" integration test**
  - Fake curl sleep; measure prompt return (may be flaky in CI—document).

- [ ] **8.7** **Conf defaults exhaustive test matrix**
  - Every README table row ↔ `__tide_report_apply_defaults`.

## Acceptance criteria

- Items implemented are documented in README and `tide-report --help`.
- Each shipped subcommand has at least one test.
- Deferred items left unchecked should move to a **new** follow-up doc or issue with rationale in Done notes.

## Key files

- [functions/tide-report.fish](../functions/tide-report.fish)
- New `_tide_report_sub_bug-report.fish` (suggested)

## Done notes

_(Fill when completed. OK to archive with many items still unchecked if team decides to close the phase as "won't do"—document that decision.)_
