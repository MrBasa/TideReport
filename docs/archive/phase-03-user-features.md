# Phase 3 — User-facing features

| Field | Value |
|-------|-------|
| **Status** | `completed` |
| **Started** | 2026-05-30 |
| **Completed** | 2026-05-30 |
| **Depends on** | [phase-02-rule-compliance.md](../archive/phase-02-rule-compliance.md) (recommended; wizard extraction overlaps 2.3) |

---

> ## Completion workflow
>
> When **every** checkbox in this document is done:
>
> 1. Set **Status** to `completed` and **Completed** to today's date.
> 2. Add a **Done notes** section (brief: PR links, caveats, follow-ups).
> 3. Update the phase row in [docs/README.md](../README.md).
> 4. Run: `git mv docs/backlog/phase-03-user-features.md docs/archive/phase-03-user-features.md`
>
> See [.cursor/rules/docs-backlog.mdc](../../.cursor/rules/docs-backlog.mdc).

---

## Goal

Ship user-directed features: Tide-aligned `tide-report` CLI, wizard UX, GitHub CI freshness, `!auth` display, GitHub fetch timeout, and README accuracy.

## Checklist

### `tide-report` CLI (Tide-aligned)

- [x] **3.1** **Add `functions/tide-report.fish` dispatcher**
  - Mirror Tide's `tide.fish` pattern: `-v/--version`, `-h/--help`, subcommand dispatch to `_tide_report_sub_$argv[1]`.
  - Version string from `$_tide_report_version`.

- [x] **3.2** **Add `_tide_report_sub_configure`**
  - Interactive guard if not `status is-interactive`.
  - Calls `_tide_report_run_wizard`.

- [x] **3.3** **Extract `_tide_report_run_wizard`**
  - Move wizard body (~lines 91–280) from [`functions/_tide_report_do_install.fish`](../functions/_tide_report_do_install.fish) to [`functions/_tide_report_run_wizard.fish`](../functions/_tide_report_run_wizard.fish).
  - `_tide_report_do_install` becomes orchestration + prompts only.

- [x] **3.4** **Context-aware wizard prompts in `_tide_report_do_install`**
  - Pass `install` vs `update` context (argument or flag).
  - **Install** (interactive): `"Run the TideReport install wizard? [Y/n]"` — default **yes**.
  - **Update** (interactive): `"Run the TideReport configuration wizard? [y/N]"` — default **no**.
  - **Non-interactive:** never prompt; apply defaults/version only.
  - [`conf.d/tide_report.fish`](../conf.d/tide_report.fish): update handler passes `update` context.

- [x] **3.5** **`_tide_report_help` content**
  - List `configure` subcommand.
  - **Do not** add `reload` subcommand; include See also: *"After manual `set -U` changes, run `tide reload`."*
  - **`bug-report`:** deferred to [phase-08-future-deferred.md](phase-08-future-deferred.md).

- [x] **3.6** **Update install footer & README Usage**
  - Footer: reconfigure via `tide-report configure` or `fisher update` + yes at prompt.
  - README: document CLI; fix mismatches (see 3.14).

- [x] **3.7** **Tests: CLI and update prompt**
  - [`test/integration/items/update_event.fish`](../test/integration/items/update_event.fish): empty input on update skips wizard.
  - New tests: `tide-report --help`, `--version`, `configure` dispatch.

### GitHub CI freshness (stats unchanged)

- [x] **3.8** **Add `tide_report_github_ci_expire_seconds`**
  - Default **180** in [`functions/_tide_report_defaults.fish`](../functions/_tide_report_defaults.fish).
  - Stats keep refresh-only (`tide_report_github_refresh_seconds`); no stats expire tier.

- [x] **3.9** **Implement CI display policy in [`functions/_tide_item_github.fish`](../functions/_tide_item_github.fish)**
  - Fresh (`age ≤ ci_refresh`): show cached pass/fail/pending.
  - Stale or fetch in-flight: force **⏳**, not last pass/fail.
  - Expired/missing + no active fetch: **omit CI icon** (stats still shown).

- [x] **3.10** **Tests: CI stale → pending, expired → hidden**
  - Extend [`test/unit/github/ci_refresh.fish`](../test/unit/github/ci_refresh.fish), [`test/unit/github/parse_ci_states.fish`](../test/unit/github/parse_ci_states.fish).

### GitHub `!auth`

- [x] **3.11** **Add `__tide_report_github_auth_ok`**
  - `gh auth status -h github.com`; session-cache in `$__tide_report_github_auth_ok`.
  - Call only on unavailable path (not every warm render).

- [x] **3.12** **Append `!auth` to unavailable text when unauthenticated**
  - [`_tide_item_github`](../functions/_tide_item_github.fish) missing-cache path and [`__tide_report_parse_github`](../functions/_tide_item_github.fish) empty-stats path.
  - Authenticated + network failure: generic unavailable only.

- [x] **3.13** **Fetch failure logging**
  - `__tide_report_fetch_github`: log `"gh not authenticated"` vs network failure via [`__tide_report_log_expected`](../functions/__tide_report_log_expected.fish).
  - **Optional in this phase:** same for `__tide_report_fetch_github_ci` (also tracked in phase 7).

- [x] **3.14** **Tests: fake `gh` auth-status + `!auth` integration**
  - Update [`test/helpers/fake_bin/gh`](../test/helpers/fake_bin/gh).

### GitHub timeout & README

- [x] **3.15** **Wire GitHub fetch timeout**
  - [`__tide_report_fetch_github`](../functions/_tide_item_github.fish): use `timeout_sec` (e.g. `timeout` wrapper around `gh`, or documented env limit).
  - Apply same pattern to CI fetch if feasible.

- [x] **3.16** **README documentation fixes**
  - `!auth` (implemented).
  - CI behavior paragraph (waiting ⏳ vs hidden; new expire var).
  - Tide station "requires ID" → note default `8443970`.
  - Moon `curl` requirement → note default `local` provider.
  - `tide_time_format` default (`"%H:%M"` when unset).
  - Document `tide_report_github_icon`, `tide_report_user_agent`.

## Acceptance criteria

- `tide-report configure` runs wizard; `--help` / `--version` work.
- Update with Enter at prompt does not run wizard; install default still offers wizard.
- CI stale pass/fail not shown; waiting shows ⏳; expired offline hides CI icon.
- Unauthenticated gh shows `…!auth` on unavailable path.
- README matches code for all variables touched.
- Full test suite passes.

## Key files

- [functions/tide-report.fish](../functions/tide-report.fish) (new)
- [functions/_tide_report_run_wizard.fish](../functions/_tide_report_run_wizard.fish) (new)
- [functions/_tide_report_do_install.fish](../functions/_tide_report_do_install.fish)
- [conf.d/tide_report.fish](../conf.d/tide_report.fish)
- [functions/_tide_item_github.fish](../functions/_tide_item_github.fish)
- [README.md](../README.md)

## Done notes

- Added `tide-report` CLI (`configure`, `--help`, `--version`) and extracted `_tide_report_run_wizard`; install/update prompts are context-aware (`install` default yes, `update` default no).
- GitHub CI: `tide_report_github_ci_expire_seconds` (180s), display policy via `__tide_report_github_ci_display_state`, `gh` timeout via `__tide_report_run_gh`, `!auth` on unavailable path with session-cached `gh auth status`.
- Tests: `test/integration/cli/tide_report_cli.fish`, `test/unit/github/auth_unavailable.fish`, extended CI/update tests; `github_command_counts` seeds CI cache for the repo’s actual default branch (`main` vs `master`).
- `tide-report bug-report` remains deferred in [phase-08-future-deferred.md](phase-08-future-deferred.md).
