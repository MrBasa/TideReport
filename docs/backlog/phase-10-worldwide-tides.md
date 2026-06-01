# Phase 10 — Worldwide tide predictions (exploration)

| Field          | Value                                                                                 |
| -------------- | ------------------------------------------------------------------------------------- |
| **Status**     | `pending`                                                                             |
| **Started**    | —                                                                                     |
| **Completed**  | —                                                                                     |
| **Depends on** | none (may run in parallel with [phase-09-prompt-preview-images.md](../archive/phase-09-prompt-preview-images.md)) |

---

> ## Completion workflow
>
> When **every** checkbox in this document is done:
>
> 1. Set **Status** to `completed` and **Completed** to today's date.
> 2. Add a **Done notes** section (brief: PR links, caveats, follow-ups).
> 3. Update the phase row in [docs/README.md](../README.md).
> 4. Run: `git mv docs/backlog/phase-10-worldwide-tides.md docs/archive/phase-10-worldwide-tides.md`
>
> See [.cursor/rules/docs-backlog.mdc](../../.cursor/rules/docs-backlog.mdc).

---

## Goal

Capture research on worldwide tide support so a future implementation can pick a direction without re-litigating basics. Intentionally loose — a design spike backlog, not a committed feature. Independent of [phase-09-prompt-preview-images.md](../archive/phase-09-prompt-preview-images.md).

---

## Checklist

- [ ] **10.1** **Worldwide tide predictions — research & direction** *(spike / design backlog; not a committed feature)*
  - **Context:** Tide data today is **US-only** via NOAA [`datagetter`](https://api.tidesandcurrents.noaa.gov/) in [`_tide_item_tide.fish`](../functions/_tide_item_tide.fish), keyed by numeric `tide_report_tide_station_id`. Doctor item H-5 (phase 8) documents the limitation and default Boston station. Unlike **weather** (`openmeteo` / `wttr`) and **moon** (`local` / `wttr`), tide has **no provider abstraction** — NOAA is wired end-to-end in the item + [`__tide_report_fetch_tide`](../functions/_tide_report_tide_helpers.fish).
  - **User ask:** Support tide reports worldwide; “implement predictions ourselves” was considered.
  - **Observations (for later dig-in):**
    - **Moon `local` is not a template for tide.** Moon phase is global astronomy ([`_tide_report_moon_math.fish`](../functions/_tide_report_moon_math.fish) + local provider). Tides are **location-specific**: coast geometry, depth, and resonance change harmonic amplitudes/phases per site. Accurate prediction needs **harmonic constituents** (M2, S2, K1, …) per station or a gridded model — not a single formula everywhere.
    - **Pure Fish implementation is impractical** for production accuracy: would require a large harmonics database, a prediction engine (harmonic sum + timezone/datum), and lat/lon → station resolution. Conflicts with project preference for **minimal dependencies** unless justified.
    - **Reimplementing NOAA math for US-only** adds little value; NOAA already provides authoritative free predictions for US stations.
    - **Plausible directions** (compare before building):
      | Approach | Pros | Cons |
      | -------- | ---- | ---- |
      | **Global tide API** (e.g. WorldTides, Stormglass, others — TBD) | Small diff; same async/cache/parse pattern as today | API keys, rate limits, ToS, network dependency |
      | **Bundled harmonics + helper** (XTide / libtcd / pyTMD + FES/TPXO-style data) | Offline-capable; global coverage for ports | Large data install; new binary/Python dep; packaging macOS/Linux CI |
      | **Pure Fish / rough formula** | No deps | Inaccurate; not recommended except toy scope |
    - **Suggested architecture if pursued:** Mirror weather/moon — `tide_report_tide_provider` (`noaa` | …), location model (`tide_report_tide_station_id` for NOAA **or** lat/lon / place name for global), normalize fetch output to current JSON shape consumed by [`__tide_report_parse_tide`](../functions/_tide_report_tide_helpers.fish) so [`_tide_item_tide`](../functions/_tide_item_tide.fish) stays thin. Keep **never block the prompt** (background spawn + file cache).
    - **Product/docs:** README, wizard, and doctor would need worldwide vs US messaging; optional wizard station/location picker (H-5 deferred “no IP→station in v1”).
    - **Dependencies rule:** Reluctant to add deps — any new provider must justify curl/jq-only vs shipped harmonics vs external binary.
  - **Deliverable for this backlog item (minimal):** A short **decision note** (section in this doc’s Done notes, or `docs/design/worldwide-tides.md`) listing: chosen direction or explicit “defer”, API vs offline tradeoff, config UX sketch, and follow-up implementation items (e.g. 10.2 provider spike). **No requirement to ship code** in 10.1 unless product promotes it to a new checked item.
  - **Acceptance:** Decision note exists; if deferred, rationale recorded; if proceeding, split concrete tasks into new numbered items in this phase or a follow-up phase.

---

## Acceptance criteria

- Worldwide tide options and constraints are written down; next steps are explicit or explicitly deferred.

## Key files

- [functions/_tide_item_tide.fish](../functions/_tide_item_tide.fish)
- [functions/_tide_report_tide_helpers.fish](../functions/_tide_report_tide_helpers.fish)
- [functions/_tide_report_health_checks.fish](../functions/_tide_report_health_checks.fish) (H-5 US-only messaging)
- Optional: `docs/design/worldwide-tides.md`

## Done notes

_(Fill when completed.)_
