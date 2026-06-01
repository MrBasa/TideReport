# Phase 9 — Prompt preview image generation

| Field          | Value                                                                                 |
| -------------- | ------------------------------------------------------------------------------------- |
| **Status**     | `completed`                                                                           |
| **Started**    | 2026-05-31                                                                            |
| **Completed**  | 2026-05-31                                                                            |
| **Depends on** | [phase-08-future-deferred.md](../archive/phase-08-future-deferred.md) (completed)     |

---

> ## Completion workflow
>
> When **every** checkbox in this document is done:
>
> 1. Set **Status** to `completed` and **Completed** to today's date.
> 2. Add a **Done notes** section (brief: PR links, caveats, follow-ups).
> 3. Update the phase row in [docs/README.md](../README.md).
> 4. Run: `git mv docs/backlog/phase-09-prompt-preview-images.md docs/archive/phase-09-prompt-preview-images.md`
>
> See [.cursor/rules/docs-backlog.mdc](../../.cursor/rules/docs-backlog.mdc).

---

## Goal

Automate README / marketing prompt screenshots from the existing text preview helper, without shipping that tooling to Fisher installs. Independent of [phase-10-worldwide-tides.md](phase-10-worldwide-tides.md).

---

## Checklist

- [x] **9.1** **Prompt preview image generation script (repo-only)**
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

---

## Acceptance criteria

- Maintainer can regenerate prompt preview images from repo root; assets live under `docs/assets/` (or documented path); installable plugin surface unchanged.

## Key files

- [functions/_tide_report_prompt_helpers.fish](../functions/_tide_report_prompt_helpers.fish) (`_tide_report_install_show_preview`)
- [test/integration/prompt/install_show_preview.fish](../test/integration/prompt/install_show_preview.fish)
- [scripts/run_tests_isolated.fish](../scripts/run_tests_isolated.fish) (isolation pattern)
- [README.md](../../README.md) (Previews section)
- New: `scripts/generate_prompt_previews.fish`
- New: `docs/assets/prompt-previews/` (when images exist)

## Done notes

- Added `scripts/generate_prompt_previews.fish` and `scripts/ansi_preview_to_png.py` (ANSI → SVG → PNG via `rsvg-convert` or ImageMagick; no pip deps).
- Committed 11 preview variants under `docs/assets/prompt-previews/`; README **Previews** uses three representative PNGs.
- Capture uses `TERM=xterm-256color`, isolated temp `HOME`/`XDG_*`, and FiraCode Nerd Font Mono when available.
