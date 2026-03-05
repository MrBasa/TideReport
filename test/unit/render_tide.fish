## Unit tests for __tide_report_render_tide (type, time_str, value_metric, show_level → output).

source (dirname (dirname (status filename)))/setup.fish

set -l out_high (__tide_report_render_tide H "14:30" 3.2 true | string collect)
set -l plain_high (string replace -r '\e\[[0-9;]*m' '' -- "$out_high")

@test "render_tide high: non-empty output" -n "$out_high"
@test "render_tide high: contains time 14:30" (string match -q '*14:30*' $plain_high; and echo 0; or echo 1) -eq 0
@test "render_tide high: contains level 3.2m" (string match -q '*3.2m*' $plain_high; and echo 0; or echo 1) -eq 0

set -l out_low (__tide_report_render_tide L "06:15" 1.0 true | string collect)
set -l plain_low (string replace -r '\e\[[0-9;]*m' '' -- "$out_low")
@test "render_tide low: contains time 06:15" (string match -q '*06:15*' $plain_low; and echo 0; or echo 1) -eq 0
@test "render_tide low: contains level in meters" (string match -q '*1m*' $plain_low; or string match -q '*1.0m*' $plain_low; and echo 0; or echo 1) -eq 0

set -l out_no_level (__tide_report_render_tide H "12:00" 2.5 false | string collect)
set -l plain_no (string replace -r '\e\[[0-9;]*m' '' -- "$out_no_level")
@test "render_tide show_level false: no meter suffix" (string match -q '*2.5m*' $plain_no; and echo 1; or echo 0) -eq 0
