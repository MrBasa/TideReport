# Phase 6 — Structure & test coverage

| Field | Value |
|-------|-------|
| **Status** | `pending` |
| **Started** | — |
| **Completed** | — |
| **Depends on** | [phase-03-user-features.md](phase-03-user-features.md), [phase-04-shared-helpers.md](phase-04-shared-helpers.md) (recommended) |

---

> ## Completion workflow
>
> When **every** checkbox in this document is done:
>
> 1. Set **Status** to `completed` and **Completed** to today's date.
> 2. Add a **Done notes** section (brief: PR links, caveats, follow-ups).
> 3. Update the phase row in [docs/README.md](../README.md).
> 4. Run: `git mv docs/backlog/phase-06-structure-tests.md docs/archive/phase-06-structure-tests.md`
>
> See [.cursor/rules/docs-backlog.mdc](../../.cursor/rules/docs-backlog.mdc).

---

## Goal

Larger refactors (optional) and close test coverage gaps identified in the code review—especially async contract, locks, and failure paths.

## Checklist

### Structure (optional — larger diffs)

- [ ] **6.1** **Split [`functions/_tide_item_github.fish`](../functions/_tide_item_github.fish) (~477 lines)**
  - Move to modules mirroring weather, e.g.:
    - `_tide_report_github_context.fish`
    - `_tide_report_github_fetch.fish`
    - `_tide_report_github_parse.fish`
  - Item file: thin entry + lazy sources.
  - Use `git mv` per [.cursor/rules/git-rename.mdc](../../.cursor/rules/git-rename.mdc).

- [ ] **6.2** **Align naming conventions**
  - `--argument-names` on `__tide_report_fetch_tide` (matches peers).
  - Consider renaming `__tide_report_provider_wttr` → `__tide_report_provider_weather_wttr` (optional breaking internal rename only if no external refs).

### Async & cache tests (recommended)

- [ ] **6.3** **Stale cache window tests (weather, moon, tide)**
  - Assert: `refresh < age ≤ expire` still renders cached data **and** sets trigger_fetch.
  - Files: extend [`test/unit/weather/async_cache_logic.fish`](../test/unit/weather/async_cache_logic.fish), [`test/unit/moon/async_cache_logic.fish`](../test/unit/moon/async_cache_logic.fish); add tide equivalent.

- [ ] **6.4** **Expired cache with file present**
  - Weather/moon: missing vs expired distinction.
  - Moon integration pattern: [`test/integration/moon_providers.fish`](../test/integration/moon_providers.fish).

- [ ] **6.5** **Lock helper unit tests**
  - [`functions/_tide_report_lock_helpers.fish`](../functions/_tide_report_lock_helpers.fish):
    - acquire success/failure
    - stale lock recovery (120s TTL)
    - release cleanup

- [ ] **6.6** **Lock-held skip behavior**
  - When lock already held, second prompt does not spawn duplicate fetch; shows unavailable/expired until first completes.

- [ ] **6.7** **Open-Meteo provider E2E (fake curl)**
  - Mirror [`test/unit/weather/provider_wttr.fish`](../test/unit/weather/provider_wttr.fish) for `__tide_report_provider_openmeteo` writing `weather.json`.
  - IP-location sidecar + `TIDE_REPORT_RESOLVED_LOCATION` if applicable.

- [ ] **6.8** **Non-blocking prompt timing test (optional)**
  - Fake curl that sleeps; assert prompt returns before fetch completes (integration).

### GitHub & tide failure paths

- [ ] **6.9** **Tide unavailable suffix tests**
  - `!stationID` when station unset; `!data` when parse fails ([`_tide_item_tide.fish`](../functions/_tide_item_tide.fish)).

- [ ] **6.10** **Malformed cache JSON tests**
  - Corrupt weather/tide/github cache files → graceful unavailable.

- [ ] **6.11** **`tide_report_service_timeout_millis` propagation test**
  - Assert curl receives expected `--max-time` via fake_bin.

- [ ] **6.12** **Moon provider combination tests**
  - `moon=wttr` + `weather=wttr` shared `"weather"` lock.
  - Malformed empty `moon.json` at parse time.

- [ ] **6.13** **GitHub integration: full unavailable path**
  - Missing cache → unavailable text; with auth mock for `!auth` (may overlap phase 3).

- [ ] **6.14** **`log_expected` disable values**
  - README lists `0`, `false`, `no`; tests only cover `no`—add cases if desired.

## Acceptance criteria

- Required test items (6.3–6.7 minimum) implemented unless explicitly deferred in Done notes.
- Optional structure split (6.1) only if completed without behavior change.
- `fish scripts/run_tests_isolated.fish` passes.

## Key files

- [test/unit/](../test/unit/), [test/integration/](../test/integration/), [test/helpers/fake_bin/](../test/helpers/fake_bin/)
- [functions/_tide_item_github.fish](../functions/_tide_item_github.fish) if split

## Done notes

_(Fill when completed.)_
