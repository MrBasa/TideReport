# TideReport Codebase Audit

Audit date: 2025-03-01. Scope: all `.fish` files under `conf.d/` and `functions/`.

**Remediation applied:** 2025-03-01. All items below were addressed in code (redirects, test style, dead code removal, shared `__tide_report_gnu_date_cmd`, pipeline comments, `command date`, string-replace loop, jq `first`).

---

## 1. Bashisms and non-Fish constructs

### 1.1 Redirect style (minor)

**Rule:** Prefer Fish-idiomatic redirects; avoid `&>/dev/null`; use `^/dev/null` or `2>/dev/null` where needed.

| File | Line(s) | Current | Note |
|------|--------|--------|------|
| `conf.d/tide_report.fish` | 19, 22, 26 | `>/dev/null 2>&1` | Works in Fish; idiomatic Fish is `^/dev/null` to suppress both stdout and stderr. |
| `functions/_tide_item_github.fish` | 8 | `>/dev/null 2>&1` | Same. |
| `functions/_tide_item_weather.fish` | 182 | `>/dev/null 2>&1` | Same. |
| `functions/_tide_item_tide.fish` | 29, 150 | `>/dev/null 2>&1` | Same. |
| `functions/_tide_report_handle_async_wttr.fish` | 66 | `>/dev/null 2>&1` | Same. |

**Recommendation:** Optionally replace `cmd >/dev/null 2>&1` with `cmd ^/dev/null` for consistency with project rules. Low priority; current form is valid.

### 1.2 `test` with `-a` / `-o` (style / portability)

**Rule:** Prefer Fish combinators `; and` / `; or` over `test ... -a ...` / `-o ...`.

| File | Line | Current | Recommendation |
|------|------|--------|----------------|
| `functions/_tide_item_github.fish` | 24 | `test -z "$owner" -o -z "$repo"` | Use `test -z "$owner"; or test -z "$repo"`. |
| `functions/_tide_item_github.fish` | 126 | `test $status -eq 0 -a -n "$json_data"` | Use `test $status -eq 0; and test -n "$json_data"`. |

Fish’s `test` does support `-a`/`-o`, but the project rule prefers Fish syntax; the suggested form is clearer and avoids any parser-edge cases.

---

## 2. Overly verbose code

### 2.1 Dead / redundant assignments — `_tide_item_weather.fish`

**Lines 85–93:** `sunrise_str` and `sunset_str` are set twice; the first assignment is unused.

```fish
    set -l sunrise_str (string trim -- $sunrise)
    set -l sunset_str (string trim -- $sunset)
    # %S: Sunrise time
    set -l sunrise_str (__tide_report_format_wttr_time "$sunrise" $tide_time_format)
    # %s: Sunset time
    set -l sunset_str (__tide_report_format_wttr_time "$sunset" $tide_time_format)
```

**Recommendation:** Remove the first two lines (trim-only assignments). If formatting is desired before `__tide_report_format_wttr_time`, pass `(string trim -- $sunrise)` into that function and keep a single assignment.

### 2.2 Repeated `string replace` — `_tide_item_weather.fish` (lines 95–106)

The same pattern is repeated many times:

```fish
    set output (string replace -a -- '%t' $temp_str $output)
    set output (string replace -a -- '%C' $cond_text $output)
    … (10 times total)
```

**Recommendation:** Either keep as-is for maximum clarity, or refactor to a loop over a list of placeholder/value pairs to shorten the block. Current form is readable; optimization is optional.

### 2.3 Duplicated GNU/BSD date detection

The same “use `gdate` if available, else `date` if GNU” block appears in:

- `functions/_tide_item_weather.fish` (lines 178–184) in `__tide_report_format_wttr_time`
- `functions/_tide_item_tide.fish` (lines 26–30) in `_tide_item_tide`

**Recommendation:** Extract a shared helper, e.g. `__tide_report_gnu_date_cmd`, that sets a variable or prints the command name, and call it from both places to avoid drift and duplication.

---

## 3. Brittle / non-resilient code

### 3.1 Pipeline and `$status` — weather and github parsers

**`_tide_item_weather.fish` line 56–60:**

```fish
    jq -r "…" "$cache_file" 2>/dev/null | read -l -d \; temp …
    if test $status -ne 0; or test -z "$temp"
```

In a pipeline, `$status` reflects the **last** command (`read`), not `jq`. If `jq` fails, `read` may still exit 0 with empty/incomplete variables. The real guard here is `test -z "$temp"`; the `$status` check is at best redundant and can be misleading when debugging.

**Recommendation:** Keep the `-z "$temp"` (and similar) checks; treat the `$status` check as optional or remove it for clarity, and add a short comment that we rely on content checks after pipelines.

**`_tide_item_github.fish` line 93–96:** Same pattern: `jq … | read -l …` then `test $status -ne 0`. The meaningful check is whether the read variables are valid; consider documenting or simplifying.

### 3.2 Use of `date` without `command` — `_tide_item_github.fish`

**Lines 39, 43:** `date +%s` and `date -r "$cache_file" +%s` are used without `command`.

Elsewhere (e.g. `_tide_report_handle_async_wttr.fish`, `_tide_item_tide.fish`) the code uses `command date` to avoid user-defined `date` functions or aliases.

**Recommendation:** Use `command date` here too for consistency and resilience.

### 3.3 Uninstall: erasing functions by pattern — `conf.d/tide_report.fish` line 112

```fish
    builtin functions --erase (builtin functions --all | string match --entire -r '^_?tide_report')
```

If `functions --all` is large (many loaded functions), this builds a big list. Uninstall usually runs once, so impact is limited. The only brittleness is if the regex or `--entire` behavior changes; the pattern itself is appropriate.

**Recommendation:** No change required; optional: add a one-line comment that this list can be long in heavily customized sessions.

### 3.4 Lock variable indirection — tide and github

Tide (lines 63–65) and GitHub (62–64) use:

```fish
        if set -q $lock_var
            set lock_time $$lock_var
```

In Fish, `$$lock_var` is indirect expansion (value of the variable whose name is in `lock_var`). That is correct. The pattern is consistent with `_tide_report_handle_async_wttr.fish` (line 30). No change needed.

---

## 4. Un-optimized code and subshell overuse

### 4.1 Subshells that are necessary and acceptable

- `(command date +%s)`, `(math …)`, `(jq …)`, `(set -q $lock_var; and echo $$lock_var; or echo 0)`: all are appropriate; no change suggested.

### 4.2 Weather: many sequential `string replace` subshells

**`_tide_item_weather.fish` lines 95–106:** Each line is one subshell and one `string replace`. For a single prompt line this is negligible, but it is the heaviest use of command substitution in one place.

**Recommendation:** Optional optimization: build a single replacement list and loop, or use a single `string replace` with a regex that substitutes multiple placeholders (if feasible and still readable). Not required for correctness.

### 4.3 Tide: `jq … | head -n 1` in command substitution

**`_tide_item_tide.fish` lines 91–96:**

```fish
    set -l next_tide (jq -r … "$cache_file" 2>/dev/null | head -n 1)
```

`jq` can limit output itself (e.g. `first(…)` or `limit(1; …)`), so the pipeline could be a single `jq` call without `head`.

**Recommendation:** Use jq’s `first` (or equivalent) so the result is a single `(jq …)` subshell without `head -n 1`. Reduces one process and one pipe.

### 4.4 Conf: uninstall variable list — `conf.d/tide_report.fish` line 105

```fish
    set -l vars_to_erase (set -U --names | string match -r '^_?(tide_report|tide_github|tide_weather|tide_moon|tide_tide).*')
```

Runs once on uninstall; `set -U --names` is a builtin and the pipeline is small. No optimization needed.

---

## 5. Summary table

| Category | Severity | Count | Action |
|----------|----------|--------|--------|
| Redirect `>/dev/null 2>&1` | Low | 6 | Optional: switch to `^/dev/null` |
| `test -o` / `-a` | Low | 2 | Prefer `; or` / `; and` |
| Dead code (sunrise_str/sunset_str) | Low | 1 | Remove first assignment pair |
| Duplicated date-detection logic | Medium | 2 | Extract shared helper |
| Pipeline `$status` semantics | Low | 2 | Rely on content checks; comment or simplify |
| `date` without `command` (github) | Low | 2 | Use `command date` |
| Multiple `string replace` (weather) | Optional | 1 block | Consider loop/regex if optimizing |
| `jq | head -n 1` (tide) | Low | 1 | Use jq `first` to drop `head` |

Overall the codebase is in good shape: no critical bashisms, no blocking brittleness, and subshell use is mostly justified. The items above are incremental improvements for style, consistency, and minor performance.
