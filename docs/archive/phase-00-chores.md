# Phase 0 — Chores & vendor updates

| Field | Value |
|-------|-------|
| **Status** | `completed` |
| **Started** | 2026-05-30 |
| **Completed** | 2026-05-30 |
| **Depends on** | none (can run in parallel with any phase) |

---

> ## Completion workflow
>
> When **every** checkbox in this document is done:
>
> 1. Set **Status** to `completed` and **Completed** to today's date.
> 2. Add a **Done notes** section (brief: PR links, caveats, follow-ups).
> 3. Update the phase row in [docs/README.md](../README.md).
> 4. Run: `git mv docs/backlog/phase-00-chores.md docs/archive/phase-00-chores.md`
>
> See [.cursor/rules/docs-backlog.mdc](../../.cursor/rules/docs-backlog.mdc).

---

## Goal

Keep vendored test tooling current and documented so CI and local runs stay reliable.

## Checklist

- [x] **0.1** **Audit vendored Fishtape version**
  - Current: `vendor/fishtape.fish` header reports **3.0.1** (tag `3.0.1`, commit `21ccd8c`).
  - Check [jorgebucaran/fishtape releases](https://github.com/jorgebucaran/fishtape/releases) and `main` for any post-tag fixes not yet released.
  - Record findings in **Done notes** (e.g. "already latest tag" or "refreshed from commit …").

- [x] **0.2** **Refresh `vendor/fishtape.fish` if upstream changed**
  - Replace from upstream tagged `functions/fishtape.fish` (or documented commit on main if team accepts pre-release).
  - Update header comment block: version, upstream commit hash, refresh date.
  - Keep [vendor/fishtape.LICENSE](../vendor/fishtape.LICENSE) in sync with upstream MIT license.

- [x] **0.3** **Verify test runner compatibility**
  - Run full suite: `fish scripts/run_tests_isolated.fish`
  - Run with network tests if applicable: `env RUN_NETWORK_TESTS=1 fish scripts/run_tests_isolated.fish`
  - Fix any breakage from Fishtape API/syntax changes (unlikely if still 3.0.1).

- [x] **0.4** **Document vendor refresh procedure** (one paragraph in [vendor/fishtape.fish](../vendor/fishtape.fish) header or [docs/README.md](../README.md)) so future updates repeat steps 0.1–0.3.

## Acceptance criteria

- Vendored Fishtape matches chosen upstream source; header metadata is accurate.
- Full isolated test suite passes on Linux (CI) after any vendor change.
- No undocumented drift between vendor file and upstream.

## Key files

- [vendor/fishtape.fish](../vendor/fishtape.fish)
- [vendor/fishtape.LICENSE](../vendor/fishtape.LICENSE)
- [scripts/run_tests_isolated.fish](../scripts/run_tests_isolated.fish)

## Done notes

- **0.1:** Latest release tag remains **3.0.1** (2021-01-22). `main` has two post-tag commits: `33471be` (abort on syntax check) and `e6e5fc2` (revert that check—`fish --no-execute` fails on `@test` helpers). No newer release published.
- **0.2:** Refreshed `vendor/fishtape.fish` from `main` at `e6e5fc2` (upstream formatting/help text; functionally equivalent to tag 3.0.1). Updated `vendor/fishtape.LICENSE` copyright line to match upstream `LICENSE.md`.
- **0.3:** `fish scripts/run_tests_isolated.fish` and `env RUN_NETWORK_TESTS=1 fish scripts/run_tests_isolated.fish` both pass on Linux.
- **0.4:** Vendor refresh procedure documented in the `vendor/fishtape.fish` header comment block.
