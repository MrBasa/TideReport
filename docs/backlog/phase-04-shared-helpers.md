# Phase 4 — Shared helpers & deduplication

| Field | Value |
|-------|-------|
| **Status** | `pending` |
| **Started** | — |
| **Completed** | — |
| **Depends on** | [phase-03-user-features.md](phase-03-user-features.md) (CI helper may reuse cache_state) |

---

> ## Completion workflow
>
> When **every** checkbox in this document is done:
>
> 1. Set **Status** to `completed` and **Completed** to today's date.
> 2. Add a **Done notes** section (brief: PR links, caveats, follow-ups).
> 3. Update the phase row in [docs/README.md](../README.md).
> 4. Run: `git mv docs/backlog/phase-04-shared-helpers.md docs/archive/phase-04-shared-helpers.md`
>
> See [.cursor/rules/docs-backlog.mdc](../../.cursor/rules/docs-backlog.mdc).

---

## Goal

Extract duplicated logic into shared helpers (~100+ lines saved), improve consistency across weather/moon/tide/GitHub cache paths.

## Checklist

### Required

- [ ] **4.1** **`__tide_report_cache_state`**
  - Inputs: cache file path, now, refresh_seconds, expire_seconds.
  - Outputs: trigger_fetch, cache_valid (and optionally stale flag).
  - Replace duplicate blocks in:
    - [`functions/_tide_report_handle_async_weather.fish`](../functions/_tide_report_handle_async_weather.fish)
    - [`functions/_tide_report_handle_async_moon.fish`](../functions/_tide_report_handle_async_moon.fish)
    - [`functions/_tide_item_tide.fish`](../functions/_tide_item_tide.fish)
  - Consider GitHub CI segment (phase 3 may inline first; refactor here if not done).

- [ ] **4.2** **`__tide_report_write_json_cache`**
  - Atomic `$path.$fish_pid.tmp` + `mv`; `mkdir -p` parent.
  - Adopt in tide fetch (if not done in phase 1), weather, moon providers.

- [ ] **4.3** **`__tide_report_openmeteo_resolve_location`**
  - Unify geocoding/lat-lon/IP logic from:
    - [`functions/_tide_report_provider_weather_openmeteo.fish`](../functions/_tide_report_provider_weather_openmeteo.fish)
    - [`functions/__tide_report_validate_weather_location.fish`](../functions/__tide_report_validate_weather_location.fish)
    - Install wizard IP display in [`functions/_tide_report_do_install.fish`](../functions/_tide_report_do_install.fish) / wizard file.

- [ ] **4.4** **`__tide_report_build_weather_normalized_json`**
  - Single `jq -n` builder shared by wttr and openmeteo providers.

- [ ] **4.5** **`_tide_report_handle_async_tide`**
  - Extract inline async logic from [`functions/_tide_item_tide.fish`](../functions/_tide_item_tide.fish) to match weather/moon pattern.
  - Item file: locals + handler call + parse only.

### Optional

- [ ] **4.6** **Deduplicate uninstall left/right filtering**
  - [`functions/_tide_report_do_uninstall.fish`](../functions/_tide_report_do_uninstall.fish) lines 7–43 → shared helper.

- [ ] **4.7** **Deduplicate install non-interactive default-item paths**
  - [`functions/_tide_report_do_install.fish`](../functions/_tide_report_do_install.fish) duplicate branches ~65–73 vs 81–89.

- [ ] **4.8** **`__tide_report_write_moon_json_cache`**
  - Consolidate moon.json write snippet (3 provider files).

- [ ] **4.9** **`__tide_report_file_mtime`**
  - Wrapper around `path mtime` (GitHub pattern) for use before phase 5 wholesale replacement.

## Acceptance criteria

- No functional behavior change except bug fixes already in earlier phases.
- Cache age logic lives in one helper used by weather, moon, tide.
- Open-Meteo geocoding not copy-pasted in three files.
- Tests pass; existing async_cache_logic tests still valid.

## Key files

- New: `functions/_tide_report_cache_helpers.fish` (or split by concern—document choice in Done notes)
- Weather/moon/tide handlers and providers listed above.

## Done notes

_(Fill when completed.)_
