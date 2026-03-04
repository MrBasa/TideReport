## Integration tests: weather and moon items with fixture cache and temp HOME.

source (dirname (dirname (status filename)))/setup.fish

set -g _test_home (mktemp -d)
set -g _saved_home $HOME
set -g HOME $_test_home
mkdir -p $HOME/.cache/tide-report
cp "$REPO_ROOT/test/fixtures/weather.json" $HOME/.cache/tide-report/weather.json
cp "$REPO_ROOT/test/fixtures/moon.json" $HOME/.cache/tide-report/moon.json

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
@test "weather output has no raw format placeholders (substituted, not %t %c etc.)" (
    set -l bad 0
    for c in $_tide_print_item_calls
        if string match -q "weather *" "$c"
            set -l out (string replace "weather " "" "$c")
            string match -q "*%t*" "$out"; and set bad 1
            string match -q "*%c*" "$out"; and set bad 1
            string match -q "*%d*" "$out"; and set bad 1
            string match -q "*%w*" "$out"; and set bad 1
            string match -q "*%f*" "$out"; and set bad 1
            string match -q "*%h*" "$out"; and set bad 1
            string match -q "*%u*" "$out"; and set bad 1
            string match -q "*%C*" "$out"; and set bad 1
            string match -q "*%S*" "$out"; and set bad 1
            string match -q "*%s*" "$out"; and set bad 1
            break
        end
    end
    echo $bad
) -eq 0
@test "output contains temperature or moon emoji" (
    string match -q -r "[-+]?[0-9]+°" "$_weather_moon_calls"; or string match -q "*🌕*" "$_weather_moon_calls"; or string match -q "*🌑*" "$_weather_moon_calls"; or string match -q "*❔*" "$_weather_moon_calls"
    echo $status
) -eq 0
@test "output contains moon emoji" (
    string match -q "*🌕*" "$_weather_moon_calls"; or string match -q "*🌑*" "$_weather_moon_calls"; or string match -q "*❔*" "$_weather_moon_calls"
    echo $status
) -eq 0
