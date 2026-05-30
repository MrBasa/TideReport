# Phase 1 — Critical bugs

| Field | Value |
|-------|-------|
| **Status** | `completed` |
| **Started** | 2026-05-30 |
| **Completed** | 2026-05-30 |
| **Depends on** | none |

---

> ## Completion workflow
>
> When **every** checkbox in this document is done:
>
> 1. Set **Status** to `completed` and **Completed** to today's date.
> 2. Add a **Done notes** section (brief: PR links, caveats, follow-ups).
> 3. Update the phase row in [docs/README.md](../README.md).
> 4. Run: `git mv docs/backlog/phase-01-critical-bugs.md docs/archive/phase-01-critical-bugs.md`
>
> See [.cursor/rules/docs-backlog.mdc](../../.cursor/rules/docs-backlog.mdc).

---

## Goal

Fix correctness bugs with small, high-impact diffs before refactors. These affect real users (especially macOS/BSD tide times and cache races).

## Checklist

- [x] **1.1** **Tide UTC parsing on BSD/macOS**
  - **Problem:** [`functions/_tide_item_tide.fish`](../functions/_tide_item_tide.fish) lines 138–141: GNU branch parses NOAA GMT as `"$date_str UTC"`; BSD branch parses as **local** time → wrong tide display on macOS CI.
  - **Fix:** Use patterns from [`functions/_tide_report_time_helpers.fish`](../functions/_tide_report_time_helpers.fish) (`__tide_report_gnu_date_cmd`, epoch helpers) with explicit UTC on BSD.
  - **Tests:** Extend [`test/unit/tide/parse_tide_branches.fish`](../test/unit/tide/parse_tide_branches.fish) or integration [`test/integration/tide.fish`](../test/integration/tide.fish) with BSD-style date path (mock or conditional).

- [x] **1.2** **Atomic tide cache write**
  - **Problem:** [`__tide_report_fetch_tide`](../functions/_tide_item_tide.fish) ~line 165 writes directly with `printf > cache_file`; weather/moon use `$cache.$fish_pid.tmp` + `mv`.
  - **Fix:** Temp file + atomic `mv`; `mkdir -p` parent dir before write.
  - **Tests:** Existing [`test/unit/tide/fetch_tide.fish`](../test/unit/tide/fetch_tide.fish) should still pass.

- [x] **1.3** **Align tide fetch timeout with config**
  - **Problem:** `--max-time 3` hardcoded; other modules use `tide_report_service_timeout_millis`.
  - **Fix:** Pass `timeout_sec` into `__tide_report_fetch_tide` (from item entry) and use in curl.
  - **Tests:** Optional unit assertion that timeout is propagated (mock curl env in fake_bin if needed).

## Acceptance criteria

- Tide times correct when NOAA returns GMT on both GNU and BSD `date`.
- No direct writes to `tide.json` on the fetch path.
- Tide curl `--max-time` respects `tide_report_service_timeout_millis`.
- `fish scripts/run_tests_isolated.fish` passes.

## Key files

- [functions/_tide_item_tide.fish](../functions/_tide_item_tide.fish)
- [functions/_tide_report_time_helpers.fish](../functions/_tide_report_time_helpers.fish)
- [functions/_tide_report_defaults.fish](../functions/_tide_report_defaults.fish)

## Done notes

- Added `__tide_report_noaa_gmt_to_unix` (GNU `-d "… UTC"`, BSD `date -u -j -f`) and wired `__tide_report_parse_tide` through `__tide_report_format_unix_time` for local display.
- Tide fetch uses `$cache_file.$fish_pid.tmp` + `mv -f`; timeout comes from `tide_report_service_timeout_millis` via new `timeout_sec` argument on `__tide_report_fetch_tide`.
- Tests: existing `test/unit/tide/parse_tide_utc.fish`; new `noaa_gmt_to_unix` cases in `test/unit/core/time_helpers.fish`; timeout propagation via `TIDE_REPORT_TEST_CURL_MAX_TIME_FILE` in fake curl.
