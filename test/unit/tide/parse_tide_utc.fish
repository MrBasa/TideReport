## Tide UTC: NOAA predictions are GMT; display time must convert to local time.
## Pins intended behavior for phase-1 BSD fix (see docs/backlog/phase-01-critical-bugs.md).

source (dirname (dirname (status filename)))/../helpers/setup.fish
source "$REPO_ROOT/functions/_tide_report_tide_helpers.fish"

set -l fixture "$REPO_ROOT/test/fixtures/tide/predictions.json"
set -l now (command date +%s)
set -l gnu_date_cmd (__tide_report_gnu_date_cmd | string collect)
set -l saved_tz $TZ
set -gx TZ America/New_York
set -g tide_time_format "%H:%M"
set -g tide_report_tide_show_level false

function __tide_report_test_tide_time_only --argument-names parse_out
    set -l plain (string replace -r '\e\[[0-9;]*m' '' -- "$parse_out")
    string replace -a -r ' .*' '' -- "$plain"
end

@test "parse_tide converts NOAA GMT to America/New_York local time" (
    set -l expected ""
    if test -n "$gnu_date_cmd"
        set expected ($gnu_date_cmd -d "2030-06-15 00:18 UTC" +%H:%M 2>/dev/null | string collect)
    else if command date -j -f "%Y-%m-%d %H:%M %Z" "2030-06-15 00:18 UTC" +%H:%M >/dev/null 2>&1
        set expected (command date -j -f "%Y-%m-%d %H:%M %Z" "2030-06-15 00:18 UTC" +%H:%M 2>/dev/null | string collect)
    end
    test -n "$expected"; or begin
        echo "skip: no portable UTC date conversion on this platform"
        echo 0
        exit 0
    end

    set -l out (__tide_report_parse_tide $now "$fixture" "$gnu_date_cmd" | string collect)
    test -n "$out"; or begin
        echo "parse_tide returned empty output"
        echo 1
        exit 0
    end
    set -l got (__tide_report_test_tide_time_only "$out")
    test "$got" = "$expected"
    echo $status
) -eq 0

@test "parse_tide selects the next future NOAA prediction from GMT timestamps" (
    set -l tmp (mktemp -d)
    set -l cache "$tmp/tide.json"
    printf '%s\n' '{
  "predictions": [
    {"t": "2030-06-15 00:18", "v": "9.398", "type": "H"},
    {"t": "2030-06-15 06:15", "v": "1.085", "type": "L"}
  ]
}' > "$cache"
    set -l out (__tide_report_parse_tide $now "$cache" "$gnu_date_cmd" | string collect)
    test -n "$out"; and string match -q -r '[0-9]{1,2}:[0-9]{2}' "$out"
    set -l ok $status
    command rm -rf "$tmp"
    echo $ok
) -eq 0

set -q saved_tz[1]; and set -gx TZ "$saved_tz"; or set -e TZ
