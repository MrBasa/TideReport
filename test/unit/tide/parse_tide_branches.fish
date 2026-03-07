source (dirname (dirname (status filename)))/../helpers/setup.fish
source "$REPO_ROOT/functions/_tide_item_weather.fish"
source "$REPO_ROOT/functions/_tide_item_tide.fish"

set -l fixture "$REPO_ROOT/test/fixtures/tide/predictions.json"
set -l now (command date +%s)
set -l gnu_date_cmd (__tide_report_gnu_date_cmd)

@test "parse_tide returns output for valid fixture" -n (__tide_report_parse_tide $now "$fixture" "$gnu_date_cmd")

@test "parse_tide returns failure for missing cache" (
    __tide_report_parse_tide $now /tmp/does-not-exist "$gnu_date_cmd"
    echo $status
) -eq 1

@test "render_tide uses feet when units=u" (
    set -g tide_report_units u
    set -l out (__tide_report_render_tide H "10:00" 3.0 true)
    string match -q '*ft*' "$out"
    echo $status
) -eq 0

@test "render_tide hides level when show_level=false" (
    set -l out (__tide_report_render_tide H "10:00" 3.0 false)
    string match -q '*m*' "$out"; and echo 1; or echo 0
) -eq 0
