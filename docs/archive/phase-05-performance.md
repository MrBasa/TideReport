# Phase 5 — Performance

| Field | Value |
|-------|-------|
| **Status** | `completed` |
| **Started** | 2026-05-30 |
| **Completed** | 2026-05-30 |
| **Depends on** | [phase-04-shared-helpers.md](phase-04-shared-helpers.md) (optional; 4.9 overlaps) |

---

> ## Completion workflow
>
> When **every** checkbox in this document is done:
>
> 1. Set **Status** to `completed` and **Completed** to today's date.
> 2. Add a **Done notes** section (brief: PR links, caveats, follow-ups).
> 3. Update the phase row in [docs/README.md](../README.md).
> 4. Run: `git mv docs/backlog/phase-05-performance.md docs/archive/phase-05-performance.md`
>
> See [.cursor/rules/docs-backlog.mdc](../../.cursor/rules/docs-backlog.mdc).

---

## Goal

Optimize **background fetch paths** and portable mtime reads. Prompt path is already good (no network); do not regress "never delay the prompt."

## Checklist

### Required

- [x] **5.1** **Single jq program for wttr j1 extraction**
  - Replace ~15 `printf | jq` calls in [`functions/_tide_report_provider_weather_wttr.fish`](../functions/_tide_report_provider_weather_wttr.fish) lines 25–47 with one jq invocation.
  - Tests: [`test/unit/weather/provider_wttr.fish`](../test/unit/weather/provider_wttr.fish).

- [x] **5.2** **`path mtime` everywhere for cache age**
  - Replace `date -r "$cache_file" +%s` in weather/moon/tide handlers with `__tide_report_file_mtime` (from 4.9 or new).
  - GitHub already uses [`__tide_report_github_file_mtime`](../functions/_tide_item_github.fish)—generalize or alias.

- [x] **5.3** **Remove manual JSON escaping in wttr provider**
  - Delete lines 50–52 backslash/quote replacement; rely on `jq --arg` encoding only.
  - Add test case with quotes/special chars in condition text if missing.

### Optional

- [ ] **5.4** **Avoid duplicate wttr fetch when `moon=wttr` and `weather≠wttr`**
  - Moon wttr path re-fetches j1 while weather uses Open-Meteo; evaluate sharing or accepting redundancy.
  - Only implement if clear win without coupling modules.

- [ ] **5.5** **Moon local math subprocess count**
  - Document as acceptable (4h refresh); optional batching into fewer `math` calls if profiling shows issue.

## Acceptance criteria

- wttr provider uses ≤2 jq calls on success path (validate + build, or single extract + build).
- Weather/moon/tide cache age uses `path mtime` without `date -r` subprocess.
- No prompt-path regression; background-only changes.
- Test suite passes.

## Key files

- [functions/_tide_report_provider_weather_wttr.fish](../functions/_tide_report_provider_weather_wttr.fish)
- Async handlers and `_tide_item_tide.fish`

## Done notes

- wttr success path: one `jq -e -c` extract (includes validation) + one `jq -c` build via new `__tide_report_build_weather_normalized_json_from_wttr_extract`; moon cache still uses a third `jq -n` for safe `--arg` encoding.
- Manual `condition_text` escaping removed from `__tide_report_build_weather_normalized_json` (Open-Meteo path benefits too).
- Weather/moon/tide cache age already used `__tide_report_file_mtime` via `__tide_report_cache_state` (phase 4); `__tide_report_github_file_mtime` now delegates to the shared helper.
- Added `test/fixtures/weather/wttr_special_chars.json` and provider test for quoted condition text.
- Optional 5.4 (duplicate wttr fetch) and 5.5 (moon math batching) deferred—no clear win without coupling.
- `fish scripts/run_tests_isolated.fish` — all passed.
