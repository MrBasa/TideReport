## Integration tests: weather and moon deterministic cache parsing assertions.

source (dirname (dirname (status filename)))/helpers/setup.fish
__tide_report_test_source_items

set -l tmp (mktemp -d)
set -g HOME "$tmp/home"
mkdir -p "$HOME/.cache/tide-report"
cp "$REPO_ROOT/test/fixtures/weather/openmeteo.json" "$HOME/.cache/tide-report/weather.json"
cp "$REPO_ROOT/test/fixtures/moon/phase.json" "$HOME/.cache/tide-report/moon.json"
set -g tide_report_weather_refresh_seconds 99999
set -g tide_report_weather_expire_seconds 99999
set -g tide_report_moon_refresh_seconds 99999
set -g tide_report_moon_expire_seconds 99999

__tide_report_test_reset_print_capture
_tide_item_weather
set -l weather_out "$_tide_print_item_last_argv[2]"
_tide_item_moon
set -l moon_out "$_tide_print_item_last_argv[2]"

@test "weather output has no raw placeholders" (
    string match -q '*%t*' "$weather_out"; or string match -q '*%c*' "$weather_out"
    set -l bad $status
    test $bad -eq 0; and echo 1; or echo 0
) -eq 0

@test "weather output includes emoji, temp and wind" (
    string match -q -r '[-+]?[0-9]+°' "$weather_out"; and string match -q '*km/h*' "$weather_out"
    echo $status
) -eq 0

@test "moon output includes expected moon emoji" (
    string match -q -r '🌕|🌑|🌒|🌓|🌔|🌖|🌗|🌘|❔' "$moon_out"
    echo $status
) -eq 0

command rm -rf "$tmp"
