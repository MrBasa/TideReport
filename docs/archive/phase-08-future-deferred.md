# Phase 8 — Future & deferred


| Field          | Value                                                                                 |
| -------------- | ------------------------------------------------------------------------------------- |
| **Status**     | `completed`                                                                           |
| **Started**    | 2026-05-31                                                                            |
| **Completed**  | 2026-05-31                                                                            |
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

Includes a **configuration health** track: detect when enabled TideReport prompt items conflict with missing tools, bad universals, or environment quirks—and tell users how to fix them **without blocking the prompt** (checks run only on install/update, `tide-report configure`, and `tide-report doctor`).

## Checklist

### CLI extensions

- [x] **8.1** `**tide-report bug-report` subcommand** *(recommended when filing issues becomes painful)*
  - Mirror Tide's `_tide_sub_bug-report` flow.
  - Include in output:
    - `$_tide_report_version` / `tide_report_user_agent`
    - `tide_report_*_provider` settings
    - `gh auth status` summary
    - `$XDG_STATE_HOME/tide-report/tide-report.log` tail (if exists)
    - Selected universals (refresh/expire, show_ci)
    - `$_fisher_plugins` line (Tide already prints this)
    - URL to GitHub 'Create New Issue' - [https://github.com/MrBasa/TideReport/issues/new](https://github.com/MrBasa/TideReport/issues/new)
  - Add `_tide_report_sub_bug-report`; register in `tide-report` dispatcher.
  - Tests: help output + mocked env snapshot.
- **8.2–8.4, 8.7** moved to [phase-11-optional-future.md](../backlog/phase-11-optional-future.md) (optional backlog).

### Product / UX optional

- [x] **8.5** **Reduce first-prompt git subprocess cost**
  - `__tide_report_github_discover_repo`, `__tide_report_github_origin_from_config`, and `__tide_report_github_context_resolve` read `.git` / `config` before falling back to `git`.
  - Integration: first `_tide_item_github` visit logs zero `git`/`jq` subprocesses when wrappers are used (`test/integration/github_command_counts.fish`).

### Review carry-over (optional)

- [x] **8.6** **Timing-based "never block prompt" integration test**
  - Extended `test/integration/prompt_nonblocking.fish` (`RUN_SLOW_TESTS=1`): fake 3s curl/gh sleep + **≤1s** wall-clock on prompt path; flakiness documented in test header and README.
  - Moon-local fast path test always runs without `RUN_SLOW_TESTS`.

### Configuration health (`tide-report doctor`)

Shared rules for **8.8–8.19**:

- **Enabled items:** Union of `tide_left_prompt_items` and `tide_right_prompt_items` (universal vars). Only run checks for TideReport items present: `github`, `weather`, `moon`, `tide`. If a list is unset, treat as no items enabled for that side.
- **Never on the prompt path:** Do not invoke health checks from `_tide_item_*` or async fetch handlers. Allowed call sites: end of [`_tide_report_do_install.fish`](../functions/_tide_report_do_install.fish) (when any TideReport item enabled), end of [`_tide_report_run_wizard.fish`](../functions/_tide_report_run_wizard.fish), and new `tide-report doctor`.
- **Output:** Human-readable warnings to stderr (or stdout if Tide’s bug-report pattern prefers one stream—pick one and document). Use `set_color bryellow` for warnings, `brwhite` for fix hints, `cyan` for copy-paste commands. Exit `0` if only warnings; reserve non-zero for internal errors (e.g. doctor itself broken).
- **Refactor install deps:** Replace unconditional `gh`/`jq`/`curl` warnings in install with **per-enabled-item** checks from the shared helper (still warn on install when relevant items enabled).
- **Implementation sketch:** `_tide_report_enabled_items` → list; `_tide_report_run_health_checks` → dispatches; `_tide_report_sub_doctor` registered in [`tide-report.fish`](../functions/tide-report.fish). Reuse [`__tide_report_github_auth_ok`](../functions/_tide_report_github_context.fish), [`_tide_report_validate_weather_location`](../functions/_tide_report_validate_weather_location.fish), [`_tide_report_warn_global_prompt_items`](../functions/_tide_report_prompt_helpers.fish) where noted.
- **Tests:** One Fishtape file (e.g. `test/unit/core/health_checks.fish`) with mocked `command -v`, prompt lists, and universals; no real network in unit tests (optional gated integration test for geocode/IP).

- [x] **8.8** **Health-check framework and `tide-report doctor`**
  - Add `_tide_report_enabled_items` (returns `github` / `weather` / `moon` / `tide` subsets actually in prompt lists).
  - Add `_tide_report_run_health_checks` with optional `--quiet` (warnings only) for scripting.
  - Register `tide-report doctor` in help; document in README (Troubleshooting + CLI section).
  - Wire: install/update (if `any_present` in install logic), wizard completion, standalone `doctor`.
  - **Acceptance:** `tide-report doctor` finishes in under 2 seconds with no enabled items and prints nothing (or one “no TideReport items enabled” info line—product choice, document it).

- [x] **8.9** **H-1 — Missing `jq` / `curl` for enabled modules**
  - **Problem:** Install warns for missing tools even when the matching prompt item is disabled. When enabled, missing tools cause persistent unavailable text; [`_tide_report_log_expected`](../functions/_tide_report_log_expected.fish) logs `dependency` / parse failures.
  - **Detection (only if item enabled):**
    - **`jq`:** Required if **any** of `github`, `weather`, `moon`, `tide` enabled (all parse JSON; moon local still writes/reads `moon.json` shape; GitHub fetch uses `jq`).
    - **`curl`:** Required if `weather` or `tide` enabled; also if `moon` enabled **and** `tide_report_moon_provider` = `wttr` (see 8.11). Not required for `moon` + `local` only.
  - **Warning text must include:** which items are affected, install hint (`jq` / `curl` package names or “see README Requirements”), that the prompt will not block but data will stay unavailable.
  - **Acceptance:** With only `moon`+`local` enabled, doctor does not warn about `curl`. With `weather` enabled and `curl` absent, doctor warns.

- [x] **8.10** **H-2 — Weather enabled + invalid `tide_report_weather_location`**
  - **Problem:** Wizard validates via [`_tide_report_validate_weather_location`](../functions/_tide_report_validate_weather_location.fish); manual `set -U tide_report_weather_location …` can set a string Open-Meteo cannot geocode → endless unavailable + log lines from [`__tide_report_provider_weather_openmeteo`](../functions/_tide_report_provider_weather_openmeteo.fish).
  - **When:** `weather` enabled, `tide_report_weather_provider` = `openmeteo` (or default), and `tide_report_weather_location` is **non-empty** (trimmed).
  - **Check:** Call `_tide_report_validate_weather_location "$tide_report_weather_location"` (uses network; respect `tide_report_service_timeout_millis`). On failure, warn with the stderr message from validator and suggest `tide-report configure` or fixing the universal.
  - **Skip when:** Location is `""` (IP auto-detect path—covered by 8.17). Provider is `wttr` only: optional follow-up to hit wttr with a HEAD/light request—**defer** unless cheap; document “wttr location not validated in doctor v1”.
  - **Acceptance:** Mock validator or fixture geocode in tests; doctor warns on forced bad universal.

- [x] **8.11** **H-3 — Moon `wttr` — dependencies and location coupling**
  - **Problem:** [`__tide_report_provider_moon_wttr`](../functions/_tide_report_provider_moon_wttr.fish) builds URL from `$tide_report_wttr_url/$tide_report_weather_location` when moon is `wttr` but weather provider is **not** `wttr` (separate moon fetch). Empty location may still work via wttr IP mode, but users who set Open-Meteo + fixed city for weather may leave location empty and expect moon wttr to follow that city—it will not.
  - **When:** `moon` enabled and `tide_report_moon_provider` = `wttr`.
  - **Checks:**
    1. If `curl` or `jq` missing → warn (link to H-1).
    2. If `tide_report_weather_provider` ≠ `wttr` and `tide_report_weather_location` is empty → warn: moon wttr uses `tide_report_weather_location` in the URL; set a fixed location or set `tide_report_moon_provider local`, or set weather provider to `wttr` to share one fetch.
    3. If weather provider is `wttr` and location empty → info-only: “wttr uses IP-based location for weather and moon.”
  - **Acceptance:** Doctor warns on `moon=wttr`, `weather=openmeteo`, `location=""`.

- [x] **8.12** **H-4 — Tide enabled + missing or invalid `tide_report_tide_station_id`**
  - **Problem:** [`_tide_item_tide`](../functions/_tide_item_tide.fish) shows `tide_report_tide_unavailable_text` + `!stationID` when universal unset; invalid IDs yield `!data` from async handler after failed NOAA fetch.
  - **When:** `tide` enabled.
  - **Checks:**
    1. **Unset/empty:** `not set -q tide_report_tide_station_id` or trimmed string empty → warn; suggest NOAA map link from README and `set -U tide_report_tide_station_id '<id>'`.
    2. **Format:** Station ID must match `^[0-9]+$` (NOAA IDs are numeric). Non-numeric → warn before any network call.
    3. **Optional lightweight validation:** One background-safe GET to the same NOAA `datagetter` URL pattern as tide item (48h range) with timeout; if JSON missing `predictions` or HTTP fails → warn “station ID may be invalid or NOAA unreachable”. Gate behind doctor only (not prompt).
  - **Acceptance:** Doctor warns on empty station; warns on `abc`; optional test with fake curl fixture for NOAA 404.

- [x] **8.13** **H-5 — Tide enabled — US-only API and default Boston station**
  - **Problem:** Tide data is **US-only** ([NOAA Tides & Currents](https://tidesandcurrents.noaa.gov/)); default [`tide_report_tide_station_id`](../functions/_tide_report_defaults.fish) is `"8443970"` (Boston). Users outside the US often enable `tide` without changing station and see misleading local tide times.
  - **When:** `tide` enabled.
  - **Checks (informational, not errors):**
    1. Always print a one-line **info**: tides are US NOAA stations only; pick nearest station on the map (README link).
    2. If `tide_report_tide_station_id` equals default `8443970` (string compare after trim) → **warn**: still using default Boston; if you are not near Boston, set your station ID via `tide-report configure` or `set -U tide_report_tide_station_id …`.
  - **Do not** geo-locate the user in v1 (no IP→station). Optional future: wizard station picker.
  - **Acceptance:** Doctor info+warn when tide enabled and station is default.

- [x] **8.14** **H-6 — Unknown `tide_report_weather_provider` (silent wttr fallback)**
  - **Problem:** [`__tide_report_fetch_weather`](../functions/_tide_report_handle_async_weather.fish) `switch` uses `case '*'` → **wttr.in**, not Open-Meteo. Typos like `open-meteo` silently change behavior and may break expectations (location rules differ).
  - **When:** `weather` enabled.
  - **Check:** If provider not exactly `openmeteo` or `wttr` (case-sensitive per current code), warn: unknown provider `"$value"`; fetches use **wttr** today; fix universal to `openmeteo` or `wttr`.
  - **Optional code fix (same PR or follow-up):** Treat unknown as `openmeteo` default + log expected—if changed, update this requirement and README.
  - **Acceptance:** Doctor warns on `set -U tide_report_weather_provider typo`.

- [x] **8.15** **H-7 — Unknown `tide_report_moon_provider` (silent local fallback)**
  - **Problem:** [`_tide_report_handle_async_moon`](../functions/_tide_report_handle_async_moon.fish) only special-cases `wttr`; any other value uses **local** offline provider. User may believe they enabled network moon.
  - **When:** `moon` enabled.
  - **Check:** If provider not exactly `local` or `wttr`, warn: unknown provider; using **local** offline model; set `local` or `wttr` explicitly.
  - **Optional code fix:** Reject unknown at `set` time—only if product agrees; otherwise doctor-only.
  - **Acceptance:** Doctor warns on `moon_provider network`.

- [x] **8.16** **H-8 — GitHub + `gh` auth (stats and CI)**
  - **Problem:** Install warns `gh` missing unconditionally. Authenticated check exists only at runtime via [`__tide_report_github_auth_ok`](../functions/_tide_report_github_context.fish) (session-cached); unavailable text appends `!auth` via [`__tide_report_github_unavailable_display`](../functions/_tide_report_github_context.fish). CI fetch [`__tide_report_fetch_github_ci`](../functions/_tide_report_github_fetch.fish) also requires `gh`. Default [`tide_report_github_show_ci`](../functions/_tide_report_defaults.fish) is `true`.
  - **When:** `github` enabled.
  - **Checks:**
    1. `command -v gh` fails → warn + https://cli.github.com/
    2. `gh` present but `gh auth status -h github.com` fails (reuse `__tide_report_github_auth_ok` logic; doctor may bypass session cache with fresh check) → warn: `gh auth login`; mention private repos need repo scope; CI needs `workflow` read if documenting CI.
    3. If `tide_report_github_show_ci` = true and (1) or (2) → additional line: CI status will not appear until `gh` is installed and authenticated.
  - **Note:** GitHub item still **emits nothing** outside a GitHub `origin` repo ([`__tide_report_github_context`](../functions/_tide_report_github_context.fish))—doctor may add **info** when `github` enabled but `git rev-parse` fails or `origin` is not github.com: “segment only appears inside GitHub-backed git repos.”
  - **Acceptance:** Tests with mocked `gh`; warn when CI true and auth false.

- [x] **8.17** **H-9 — Open-Meteo weather with empty location (IP geo risk)**
  - **Problem:** Empty `tide_report_weather_location` + `openmeteo` uses IP geolocation ([`__tide_report_read_ip_location_cache`](../functions/_tide_report_weather_helpers.fish) / ipapi.co in helpers). VPN, corporate networks, or blocked ipapi → persistent weather unavailable (README troubleshooting).
  - **When:** `weather` enabled, provider `openmeteo`, location `""`.
  - **Checks:**
    1. **Info:** Weather follows current IP-based location; pin with `set -U tide_report_weather_location 'City'` or wizard if you need a fixed place (mirror wizard copy in [`_tide_report_run_wizard.fish`](../functions/_tide_report_run_wizard.fish)).
    2. **Optional doctor network probe:** Try IP cache read + if stale/missing one ipapi fetch (timeout); on failure warn: auto-detect failed; set explicit location. Skip probe in CI unit tests.
  - **Acceptance:** Doctor prints info whenever openmeteo+empty; warns when probe fails (mocked).

- [x] **8.18** **H-11 — Display: Nerd Font and `fish_emoji_width`**
  - **Problem:** Icons/emoji in weather, moon, GitHub, tide segments need Nerd Font; Fish 4.6+ default `fish_emoji_width 2` can misalign on older terminals (README 🚑 Troubleshooting).
  - **When:** Any of `github`, `weather`, `moon`, `tide` enabled.
  - **Checks (heuristic, no failure):**
    1. **Info:** Recommend a Nerd Font (README link). Optional weak signal: if `$fish_version` ≥ 4.6 and `fish_emoji_width` unset or `2`, mention `set -U fish_emoji_width 1` if symbols look offset.
    2. Do **not** try to detect Nerd Font installed (unreliable across distros).
  - **Acceptance:** Doctor emits info block when any item enabled; no exit-code change.

- [x] **8.19** **H-12 — `tide reload` and global prompt list override**
  - **Problem:** After `set -U tide_*_prompt_items` or wizard changes, users must run `tide reload` (README). Global `-g tide_left_prompt_items` / `tide_right_prompt_items` in `config.fish` **shadow** universals—wizard already warns via [`_tide_report_warn_global_prompt_items`](../functions/_tide_report_prompt_helpers.fish) but only at wizard time; easy to forget `tide reload`.
  - **When:** Any TideReport item enabled **or** doctor/configure just mutated prompt lists.
  - **Checks:**
    1. If `-g tide_left_prompt_items` or `-g tide_right_prompt_items` exists → reuse/extend `_tide_report_warn_global_prompt_items` with current universal lists as args.
    2. After configure/install wizard that changed items → remind: `tide reload` (cyan command). If TideReport items in universal lists but user has not reloaded this session—**optional weak check** (session flag set by wizard); v1 OK to always print reminder after configure/doctor when items enabled.
  - **Acceptance:** Doctor with global `-g` lists prints override warning; configure end prints reload reminder.

## Acceptance criteria

- Items implemented are documented in README and `tide-report --help`.
- Each shipped subcommand has at least one test.
- **Configuration health (8.8–8.19):** `tide-report doctor` runs all applicable H-* checks for enabled items; install/configure call the same helper; no health I/O on `_tide_item_*` path; `fish scripts/run_tests_isolated.fish` passes with new unit tests.
- **8.1 bug-report** should call or embed doctor summary (or duplicate `gh auth` + provider lines) so issue templates stay useful.
- Deferred items left unchecked should move to a **new** follow-up doc or issue with rationale in Done notes.

## Key files

- [functions/tide-report.fish](../functions/tide-report.fish)
- [functions/_tide_report_do_install.fish](../functions/_tide_report_do_install.fish) (refactor dependency warnings → health helper)
- [functions/_tide_report_run_wizard.fish](../functions/_tide_report_run_wizard.fish)
- [functions/_tide_report_prompt_helpers.fish](../functions/_tide_report_prompt_helpers.fish) (`_tide_report_warn_global_prompt_items`)
- [functions/_tide_report_github_context.fish](../functions/_tide_report_github_context.fish)
- [functions/_tide_report_handle_async_weather.fish](../functions/_tide_report_handle_async_weather.fish) (provider switch)
- [functions/_tide_report_handle_async_moon.fish](../functions/_tide_report_handle_async_moon.fish)
- [functions/_tide_report_validate_weather_location.fish](../functions/_tide_report_validate_weather_location.fish)
- [functions/_tide_report_weather_helpers.fish](../functions/_tide_report_weather_helpers.fish) (IP geo)
- [functions/_tide_item_tide.fish](../functions/_tide_item_tide.fish)
- [functions/_tide_report_provider_moon_wttr.fish](../functions/_tide_report_provider_moon_wttr.fish)
- [README.md](../README.md) (Requirements, Troubleshooting, CLI)
- New: `_tide_report_health_checks.fish`, `_tide_report_sub_doctor.fish`
- New: `_tide_report_sub_bug-report.fish` (8.1)
- New: `test/unit/core/health_checks.fish` (suggested)

## Done notes

- Shipped `tide-report doctor`, `tide-report bug-report`, and `_tide_report_health_checks.fish` (H-1–H-12). Doctor writes to **stderr**; bug-report embeds a health summary on **stdout**. With no TideReport items in prompt lists, doctor prints one INFO line (documented in README).
- Install/update and wizard call `_tide_report_run_health_checks` instead of unconditional `gh`/`jq`/`curl` warnings.
- Tests: `test/unit/core/health_checks.fish`, extended `test/integration/cli/tide_report_cli.fish`. Use `TIDE_REPORT_TEST_SKIP_DOCTOR_NETWORK` and `set -g` overrides in tests when setup applies `-g` defaults.
- **8.5–8.6** shipped in a follow-up pass (2026-05-31): file-based GitHub context discovery; slow prompt tests gain wall-clock threshold under `RUN_SLOW_TESTS=1`.
- **8.2, 8.3, 8.4, 8.7** moved to [phase-11-optional-future.md](../backlog/phase-11-optional-future.md).
- **Follow-up phases:** Prompt preview image automation → [phase-09-prompt-preview-images.md](../backlog/phase-09-prompt-preview-images.md) (9.1). Worldwide tide exploration → [phase-10-worldwide-tides.md](../backlog/phase-10-worldwide-tides.md) (10.1).