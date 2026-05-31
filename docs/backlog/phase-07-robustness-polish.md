# Phase 7 — Robustness & polish

| Field | Value |
|-------|-------|
| **Status** | `pending` |
| **Started** | — |
| **Completed** | — |
| **Depends on** | [phase-03-user-features.md](phase-03-user-features.md), [phase-06-structure-tests.md](../archive/phase-06-structure-tests.md) (recommended) |

---

> ## Completion workflow
>
> When **every** checkbox in this document is done:
>
> 1. Set **Status** to `completed` and **Completed** to today's date.
> 2. Add a **Done notes** section (brief: PR links, caveats, follow-ups).
> 3. Update the phase row in [docs/README.md](../README.md).
> 4. Run: `git mv docs/backlog/phase-07-robustness-polish.md docs/archive/phase-07-robustness-polish.md`
>
> See [.cursor/rules/docs-backlog.mdc](../../.cursor/rules/docs-backlog.mdc).

---

## Goal

Remaining reliability gaps, install/uninstall polish, security/network hardening, and minor anti-patterns not covered in earlier phases.

## Checklist

### Install & uninstall

- [ ] **7.1** **Remove or shorten dev-branch `sleep 3`**
  - [`functions/_tide_report_do_install.fish`](../functions/_tide_report_do_install.fish) line 23.
  - Replace with immediate warning only, or shorter delay; avoid blocking Fisher install.

- [ ] **7.2** **Uninstall: erase `_tide_item_*` functions**
  - Extend regex in [`functions/_tide_report_do_uninstall.fish`](../functions/_tide_report_do_uninstall.fish) line 54, or document that session restart is required.
  - Update [`test/integration/uninstall.fish`](../test/integration/uninstall.fish) / uninstall runner.

- [ ] **7.3** **Document update cache wipe**
  - [`conf.d/tide_report.fish`](../conf.d/tide_report.fish) update handler `rm -rf ~/.cache/tide-report` is aggressive but intentional.
  - README note: update clears all module caches.
  - **Optional:** selective cache clear (weather only, etc.)—defer if complex.

- [ ] **7.4** **Wizard on update behavior**
  - After phase 3, confirm interactive update default-no is documented.
  - **Optional:** skip wizard question entirely on update (only `tide-report configure`)—only if product decision changes.

### Network & security

- [ ] **7.5** **HTTPS for IP geolocation**
  - Replace `http://ip-api.com` with HTTPS endpoint or alternative provider in:
    - [`functions/_tide_report_provider_weather_openmeteo.fish`](../functions/_tide_report_provider_weather_openmeteo.fish)
    - Install/wizard IP display
  - Test with fake curl.

### GitHub & logging

- [ ] **7.6** **GitHub CI fetch failure logging**
  - Add `__tide_report_log_expected` to [`__tide_report_fetch_github_ci`](../functions/_tide_item_github.fish) (mirror repo fetch).

- [ ] **7.7** **`date -Iseconds` in log helper (BSD)**
  - [`functions/__tide_report_log_expected.fish`](../functions/__tide_report_log_expected.fish): GNU-only `-Iseconds`; use portable timestamp or fallback (logging only).

### Naming & files (optional)

- [ ] **7.8** **Rename `__`-prefixed function files**
  - [`functions/__tide_report_log_expected.fish`](../functions/__tide_report_log_expected.fish), [`functions/__tide_report_validate_weather_location.fish`](../functions/__tide_report_validate_weather_location.fish) → `_tide_report_*` naming (`git mv`).

- [ ] **7.9** **Provider naming consistency**
  - `__tide_report_provider_wttr` vs `__tide_report_provider_moon_wttr` vs `__tide_report_provider_openmeteo`.

### Testing (carried from Phase 6)

- [ ] **7.11** **Non-blocking prompt timing test** _(deferred from [phase-06-structure-tests.md](../archive/phase-06-structure-tests.md) §6.8)_
  - Extend [`test/helpers/fake_bin/curl`](../test/helpers/fake_bin/curl) with a controllable sleep (e.g. env var).
  - Integration test: expired/missing cache triggers background fetch; assert prompt item returns before fetch completes.
  - Keep timing generous enough for Ubuntu/macOS CI; prefer “prompt returned + lock held” over tight wall-clock thresholds where possible.

### Conf init tests

- [ ] **7.10** **README defaults vs code test**
  - Extend [`test/unit/core/conf_init_defaults.fish`](../test/unit/core/conf_init_defaults.fish) to assert key defaults match README tables (sample set from `__tide_report_apply_defaults`).

## Acceptance criteria

- No unexplained 3s install delay on dev branch.
- Uninstall behavior documented or fixed for `_tide_item_*` session functions.
- CI fetch failures visible in log when `tide_report_log_expected` enabled.
- Non-blocking prompt timing test (7.11) implemented or explicitly deferred again in Done notes.
- Test suite passes.

## Key files

- Install/uninstall/conf files listed above.
- [README.md](../README.md)

## Done notes

_(Fill when completed.)_
