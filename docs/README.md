# TideReport implementation backlog

Actionable work items from the **TideReport code review** (May 2026), split into phases by logical boundary. Supersedes the Cursor plan `tidereport_code_review` for implementation tracking.

## How to use

1. Pick the **lowest-numbered phase** whose status is not `completed`.
2. Work through checkboxes in that phase document in order (unless a item notes a dependency).
3. When a phase is fully done, follow the **Completion workflow** in that document (mark status, archive the file).
4. Run `fish scripts/run_tests_isolated.fish` after substantive changes.

## Phase index

| Phase | Document | Focus | Status |
|-------|----------|-------|--------|
| 0 | [archive/phase-00-chores.md](archive/phase-00-chores.md) | Tooling & vendor updates (Fishtape) | `completed` |
| 1 | [archive/phase-01-critical-bugs.md](archive/phase-01-critical-bugs.md) | Correctness bugs (tide UTC, cache races) | `completed` |
| 2 | [archive/phase-02-rule-compliance.md](archive/phase-02-rule-compliance.md) | Fish `functions/` rules, lazy loading | `completed` |
| 3 | [backlog/phase-03-user-features.md](backlog/phase-03-user-features.md) | CLI, wizard, GitHub CI/`!auth`, docs | `pending` |
| 4 | [backlog/phase-04-shared-helpers.md](backlog/phase-04-shared-helpers.md) | Dedupe cache/geocoding/write helpers | `pending` |
| 5 | [backlog/phase-05-performance.md](backlog/phase-05-performance.md) | Background-path optimizations | `pending` |
| 6 | [backlog/phase-06-structure-tests.md](backlog/phase-06-structure-tests.md) | Module split, test coverage gaps | `pending` |
| 7 | [backlog/phase-07-robustness-polish.md](backlog/phase-07-robustness-polish.md) | Install/uninstall, naming, misc polish | `pending` |
| 8 | [backlog/phase-08-future-deferred.md](backlog/phase-08-future-deferred.md) | Future CLI & optional enhancements | `pending` |

**Recommended order:** 0 (can run anytime) → 1 → 2 → 3 → 4 → 5 → 6 → 7 → 8.

## Archive

Completed phase documents live in [archive/](archive/). See [archive/README.md](archive/README.md).

## Completion workflow (all phases)

> **Agents & contributors:** When a phase document is fully complete:
>
> 1. Set `Status: completed` and `Completed: YYYY-MM-DD` at the top of the document.
> 2. Check off every item; add a short **Done notes** section if anything diverged from the plan.
> 3. Update the **Status** column for that phase in the table above.
> 4. Move the file: `git mv docs/backlog/phase-NN-….md docs/archive/phase-NN-….md`
> 5. Do not delete archived docs—they record what shipped and when.

See also Cursor rule [.cursor/rules/docs-backlog.mdc](../.cursor/rules/docs-backlog.mdc).
