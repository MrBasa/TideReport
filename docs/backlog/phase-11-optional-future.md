# Phase 11 — Optional future tasks

| Field | Value |
|-------|-------|
| **Status** | `pending` |
| **Started** | — |
| **Completed** | — |
| **Depends on** | none (optional backlog; pick items when there is user or maintainer demand) |

---

> ## Completion workflow
>
> When **every** checkbox in this document is done:
>
> 1. Set **Status** to `completed` and **Completed** to today's date.
> 2. Add a **Done notes** section (brief: PR links, caveats, follow-ups).
> 3. Update the phase row in [docs/README.md](../README.md).
> 4. Run: `git mv docs/backlog/phase-11-optional-future.md docs/archive/phase-11-optional-future.md`
>
> See [.cursor/rules/docs-backlog.mdc](../../.cursor/rules/docs-backlog.mdc).

---

## Goal

Low-priority enhancements deferred from [phase-08-future-deferred.md](../archive/phase-08-future-deferred.md). None are required for a stable release; implement when feedback or maintenance pain justifies the work.

Items may be closed individually—this phase does not need to ship as a single batch.

## Checklist

### CLI

- [ ] **11.1** `tide-report reload` subcommand *(was phase 8.2)*
  - Thin-wrap `tide reload` with explanation.
  - Phase 3 explicitly **did not** add this; README and `tide-report doctor` already remind users to run `tide reload`.
  - **Skip unless** users report confusion.

### Product / UX

- [ ] **11.2** **Selective cache clear on update** *(was 8.3)*
  - Instead of `rm -rf ~/.cache/tide-report` on every Fisher update, clear per-module or stale-only entries.
  - Requires a policy for schema/version bumps vs. partial invalidation.

- [ ] **11.3** **GitHub stats expire tier** *(was 8.4)*
  - Repository stats are refresh-only today; CI already has expire. Add stats expire only if stale stars/forks become a reported issue.

### Tests / docs hygiene

- [ ] **11.4** **Conf defaults exhaustive test matrix** *(was 8.7)*
  - Every README configuration table row should map to a value from `__tide_report_apply_defaults` (automated or generated check).

## Acceptance criteria

- Each implemented item has tests or docs updates as appropriate.
- Partial completion is fine; note shipped items in **Done notes** and leave the rest open.

## Key files

- [functions/tide-report.fish](../../functions/tide-report.fish) (11.1)
- Install/update handlers and cache paths under `~/.cache/tide-report/` (11.2)
- [functions/_tide_report_github_parse.fish](../../functions/_tide_report_github_parse.fish) / cache policy (11.3)
- [functions/_tide_report_defaults.fish](../../functions/_tide_report_defaults.fish), [README.md](../../README.md), [test/unit/core/conf_init_defaults.fish](../../test/unit/core/conf_init_defaults.fish) (11.4)

## Done notes

_(Fill when items ship or when this doc is archived as “won’t do”.)_
