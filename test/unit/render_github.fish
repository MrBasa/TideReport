## Unit tests for __tide_report_render_github (fixed inputs → output).

source (dirname (dirname (status filename)))/setup.fish
set -g TIDE_REPORT_TEST 1

set -l out (__tide_report_render_github 42 3 0 0 0 pass | string collect)
set -l plain (string replace -r '\e\[[0-9;]*m' '' -- "$out")

@test "render_github with pass: non-empty output" -n "$out"
@test "render_github with pass: contains ★42" (string match -q '*★42*' $plain; and echo 0; or echo 1) -eq 0
@test "render_github with pass: contains ⑂3" (string match -q '*⑂3*' $plain; and echo 0; or echo 1) -eq 0
@test "render_github with pass: contains pass icon" (string match -q '*✓*' $plain; and echo 0; or echo 1) -eq 0

set -l out_fail (__tide_report_render_github 1 0 0 0 0 fail | string collect)
set -l plain_fail (string replace -r '\e\[[0-9;]*m' '' -- "$out_fail")
@test "render_github with fail: contains fail icon" (string match -q '*✗*' $plain_fail; and echo 0; or echo 1) -eq 0

set -l out_none (__tide_report_render_github 0 0 0 0 0 none | string collect)
@test "render_github all zeros and none: output is icon only or empty" (test -n "$out_none"; and echo 0; or echo 1) -eq 0

set -e TIDE_REPORT_TEST 2>/dev/null
