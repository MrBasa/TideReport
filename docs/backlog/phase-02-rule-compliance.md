# Phase 2 — Project rule compliance

| Field | Value |
|-------|-------|
| **Status** | `pending` |
| **Started** | — |
| **Completed** | — |
| **Depends on** | [phase-01-critical-bugs.md](phase-01-critical-bugs.md) (recommended) |

---

> ## Completion workflow
>
> When **every** checkbox in this document is done:
>
> 1. Set **Status** to `completed` and **Completed** to today's date.
> 2. Add a **Done notes** section (brief: PR links, caveats, follow-ups).
> 3. Update the phase row in [docs/README.md](../README.md).
> 4. Run: `git mv docs/backlog/phase-02-rule-compliance.md docs/archive/phase-02-rule-compliance.md`
>
> See [.cursor/rules/docs-backlog.mdc](../../.cursor/rules/docs-backlog.mdc).

---

## Goal

Align with [.cursor/rules/fish-functions-no-top-level-execution.mdc](../../.cursor/rules/fish-functions-no-top-level-execution.mdc): `functions/*.fish` contain only function definitions; no top-level `source`, `set`, or imperative calls.

## Checklist

### Required

- [ ] **2.1** **Remove top-level moon init call**
  - Delete line 103 (`__tide_report_moon_init_constants`) from [`functions/_tide_report_moon_math.fish`](../functions/_tide_report_moon_math.fish).
  - Rely on [`conf.d/tide_report.fish`](../conf.d/tide_report.fish) → `__tide_report_init_moon_constants g` only.

- [ ] **2.2** **Unify moon constant init naming**
  - Consolidate `__tide_report_init_moon_constants` (defaults/conf) vs `__tide_report_moon_init_constants` (moon_math)—one name, one implementation.
  - Ensure `set_if_missing` / non-destructive behavior where appropriate.

- [ ] **2.3** **Move top-level `source` chains into function bodies**
  - [`functions/_tide_report_handle_async_weather.fish`](../functions/_tide_report_handle_async_weather.fish) lines 10–13
  - [`functions/_tide_report_handle_async_moon.fish`](../functions/_tide_report_handle_async_moon.fish) lines 6–10
  - [`functions/_tide_report_do_install.fish`](../functions/_tide_report_do_install.fish) lines 1–2
  - Pattern: lazy `if not functions -q …; source …; end` inside the function that needs deps (as in [`functions/_tide_item_weather.fish`](../functions/_tide_item_weather.fish)).

- [ ] **2.4** **Conditional moon → weather stack loading**
  - Only source weather async + wttr/openmeteo providers when `moon=wttr && weather=wttr` (shared fetch) or when moon provider is wttr and needs wttr provider file.
  - Default `moon=local` must not load entire weather stack on moon handler autoload.

- [ ] **2.5** **Verify module independence tests**
  - Run/update [`test/unit/core/module_independence.fish`](../test/unit/core/module_independence.fish) if load paths change.

### Optional (include if low cost during phase)

- [ ] **2.6** **Fisher lazy-load event fallback**
  - Project rules note Fish may lazy-load `--on-event` handlers ([fish-shell#2667](https://github.com/fish-shell/fish-shell/issues/2667)).
  - Optional one-time `_tide_report_install` invoke at end of [`conf.d/tide_report.fish`](../conf.d/tide_report.fish) if production installs confirm missed events.
  - Document trade-off (double-run guard).

- [ ] **2.7** **Move `_tide_report_warn_global_prompt_items` to `functions/`**
  - Keep thin `--on-event` stubs in conf.d only.
  - File: [`conf.d/tide_report.fish`](../conf.d/tide_report.fish), [`functions/_tide_report_prompt_helpers.fish`](../functions/_tide_report_prompt_helpers.fish).

## Acceptance criteria

- No unconditional top-level execution in `functions/*.fish` (grep audit clean).
- Moon local provider does not source weather providers on autoload.
- Moon constants initialized once via conf.d path.
- Test suite passes.

## Key files

- [functions/_tide_report_moon_math.fish](../functions/_tide_report_moon_math.fish)
- [functions/_tide_report_handle_async_weather.fish](../functions/_tide_report_handle_async_weather.fish)
- [functions/_tide_report_handle_async_moon.fish](../functions/_tide_report_handle_async_moon.fish)
- [conf.d/tide_report.fish](../conf.d/tide_report.fish)

## Done notes

_(Fill when completed.)_
