# Phase 9 — Docs assets & worldwide tides (exploration)

| Field          | Value                                                                                 |
| -------------- | ------------------------------------------------------------------------------------- |
| **Status**     | `pending`                                                                             |
| **Started**    | —                                                                                     |
| **Completed**  | —                                                                                     |
| **Depends on** | [phase-08-future-deferred.md](../archive/phase-08-future-deferred.md) (completed)     |

---

> ## Completion workflow
>
> When **every** checkbox in this document is done:
>
> 1. Set **Status** to `completed` and **Completed** to today's date.
> 2. Add a **Done notes** section (brief: PR links, caveats, follow-ups).
> 3. Update the phase row in [docs/README.md](../README.md).
> 4. Run: `git mv docs/backlog/phase-09-docs-and-tides.md docs/archive/phase-09-docs-and-tides.md`
>
> See [.cursor/rules/docs-backlog.mdc](../../.cursor/rules/docs-backlog.mdc).

---

## Goal

Two tracks deferred from product discussion (May 2026):

1. **Developer tooling** — automate README / marketing prompt screenshots from the existing text preview helper, without shipping that tooling to Fisher installs.
2. **Product exploration** — capture research on worldwide tide support so a future implementation can pick a direction without re-litigating basics.

Neither track blocks releases. Item **9.2** is intentionally loose; treat it as a design spike backlog, not a committed feature.

---

## Checklist

### Docs / dev tooling

- [ ] **9.1** **Prompt preview image generation script (repo-only)**
  - **Problem:** [README.md](../../README.md) **Previews** uses manually captured PNGs (GitHub user-attachments). The install wizard already prints deterministic ANSI previews via [`_tide_report_install_show_preview`](../functions/_tide_report_prompt_helpers.fish), but there is no repeatable way to turn those into image assets for docs.
  - **Scope:** Add a **developer script** under `scripts/` (e.g. `scripts/generate_prompt_previews.fish`) that automates sample image generation for maintainers.
  - **Not installable:** Fisher installs `conf.d/` and `functions/` only — **`scripts/` must not be referenced from install paths** (`conf.d`, `functions`, Fisher events). Do not add wizard/CLI subcommands that depend on this script. Document in script header + README **Contributing** (or a short comment in README Previews) that it is maintainer-only.
  - **Behavior sketch:**
    1. Source repo `functions/` (or minimal subset: preview helper + render helpers + defaults) in an isolated temp `HOME` / `XDG_CONFIG_HOME` (same pattern as [`scripts/run_tests_isolated.fish`](../scripts/run_tests_isolated.fish)).
    2. Seed deterministic `tide_*` colors and TideReport universals (reuse patterns from [`test/support/install_runner.fish`](../test/support/install_runner.fish) / [`test/integration/prompt/install_show_preview.fish`](../test/integration/prompt/install_show_preview.fish)).
    3. Emit preview lines for at least: `all` (medium weather), per-module (`github`, `weather` concise/medium/detailed, `moon`, `tide`), and metric vs US units where relevant.
    4. Capture terminal output to image files under e.g. `docs/assets/prompt-previews/` (PNG and/or SVG — pick one primary format during implementation).
    5. Print a summary of written paths and optional `--open` flag for local review.
  - **Capture approach (choose during implementation):** terminal-to-SVG (`termtosvg`, `svg-term-cli`, etc.), `script` + screenshot tool, or headless terminal + `scrot`/`import`. Fixed `TERM=xterm-256color` and a documented Nerd Font requirement. **Do not** use generative AI for “screenshots” — styling must match real Tide segments.
  - **README:** Replace or supplement manual attachment URLs with committed assets once generated; note how to regenerate.
  - **Acceptance:** `fish -n scripts/generate_prompt_previews.fish`; script runs on maintainer machine and writes at least one image per preview variant; no new files under `functions/` or `conf.d/` required for end users; Fisher install path unchanged.

### Worldwide tides (exploration — loosely defined)

- [ ] **9.2** **Worldwide tide predictions — research & direction** *(spike / design backlog; not a committed feature)*
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
  - **Deliverable for this backlog item (minimal):** A short **decision note** (section in this doc’s Done notes, or `docs/design/worldwide-tides.md`) listing: chosen direction or explicit “defer”, API vs offline tradeoff, config UX sketch, and follow-up implementation items (e.g. 9.3 provider spike). **No requirement to ship code** in 9.2 unless product promotes it to a new checked item.
  - **Acceptance:** Decision note exists; if deferred, rationale recorded; if proceeding, split concrete tasks into new numbered items in this phase or a follow-up phase.

---

## Acceptance criteria

- **9.1:** Maintainer can regenerate prompt preview images from repo root; assets live under `docs/assets/` (or documented path); installable plugin surface unchanged.
- **9.2:** Worldwide tide options and constraints are written down; next steps are explicit or explicitly deferred.

## Key files

- [functions/_tide_report_prompt_helpers.fish](../functions/_tide_report_prompt_helpers.fish) (`_tide_report_install_show_preview`)
- [test/integration/prompt/install_show_preview.fish](../test/integration/prompt/install_show_preview.fish)
- [scripts/run_tests_isolated.fish](../scripts/run_tests_isolated.fish) (isolation pattern)
- [README.md](../../README.md) (Previews section)
- [functions/_tide_item_tide.fish](../functions/_tide_item_tide.fish), [functions/_tide_report_tide_helpers.fish](../functions/_tide_report_tide_helpers.fish)
- [functions/_tide_report_health_checks.fish](../functions/_tide_report_health_checks.fish) (H-5 US-only messaging)
- New: `scripts/generate_prompt_previews.fish` (9.1)
- New: `docs/assets/prompt-previews/` (9.1, when images exist)
- Optional: `docs/design/worldwide-tides.md` (9.2)

## Done notes

_(Fill when completed.)_
