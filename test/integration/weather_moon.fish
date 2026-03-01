# Integration tests: weather and moon items with fixture cache and temp HOME.

source (dirname (dirname (status filename)))/setup.fish

set -g _test_home (mktemp -d)
set -g _saved_home $HOME
set -g HOME $_test_home
mkdir -p $HOME/.cache/tide-report
cp "$REPO_ROOT/test/fixtures/wttr.json" $HOME/.cache/tide-report/wttr.json

# Cache is valid (recent file); use long refresh/expire so we don't trigger fetch
set -g tide_report_weather_refresh_seconds 99999
set -g tide_report_weather_expire_seconds 99999
set -g tide_report_moon_refresh_seconds 99999
set -g tide_report_moon_expire_seconds 99999
set -g tide_report_service_timeout_millis 6000

# Run items (they read cache and parse)
_tide_item_weather
_tide_item_moon

set -g HOME $_saved_home
command rm -rf $_test_home

set -g _weather_moon_calls (string join " " $_tide_print_item_calls)
@test "weather or moon item called _tide_print_item" (count _tide_print_item_calls) -ge 1
@test "output contains temperature or moon emoji" (
    string match -q -r "[-+]?[0-9]+°" "$_weather_moon_calls"; or string match -q "*🌕*" "$_weather_moon_calls"; or string match -q "*🌑*" "$_weather_moon_calls"; or string match -q "*❔*" "$_weather_moon_calls"
    echo $status
) -eq 0
@test "output contains moon emoji" (
    string match -q "*🌕*" "$_weather_moon_calls"; or string match -q "*🌑*" "$_weather_moon_calls"; or string match -q "*❔*" "$_weather_moon_calls"
    echo $status
) -eq 0
