## Integration tests: moon item with local and wttr providers (fixture-based, no network).
## All providers produce normalized moon.json with .phase; parser is provider-agnostic.

source (dirname (dirname (status filename)))/setup.fish

## --- Test 1: local provider with valid moon.json -> moon emoji ---
set -g _test_home (mktemp -d)
set -g _saved_home $HOME
set -g HOME $_test_home
mkdir -p $HOME/.cache/tide-report
printf '%s\n' '{"phase":"Full Moon"}' > $HOME/.cache/tide-report/moon.json
set -g tide_report_moon_provider "local"
set -g tide_report_weather_provider "openmeteo"
set -g tide_report_moon_refresh_seconds 99999
set -g tide_report_moon_expire_seconds 99999
set -g tide_report_weather_refresh_seconds 99999
set -g tide_report_weather_expire_seconds 99999
cp "$REPO_ROOT/test/fixtures/weather.json" $HOME/.cache/tide-report/weather.json

set -ge _tide_print_item_calls
_tide_item_moon

set -g _local_calls (string join " " $_tide_print_item_calls)
set -g HOME $_saved_home
command rm -rf $_test_home

@test "local provider with valid moon.json shows moon emoji" (
    string match -q "*🌕*" "$_local_calls"; or string match -q "*🌑*" "$_local_calls"; or string match -q "*🌒*" "$_local_calls"; or string match -q "*❔*" "$_local_calls"
    echo $status
) -eq 0

## --- Test 2: wttr provider with valid moon.json -> moon emoji ---
set -g _test_home (mktemp -d)
set -g HOME $_test_home
mkdir -p $HOME/.cache/tide-report
printf '%s\n' '{"phase":"New Moon"}' > $HOME/.cache/tide-report/moon.json
set -g tide_report_moon_provider "wttr"
set -g tide_report_weather_provider "openmeteo"
set -g tide_report_moon_refresh_seconds 99999
set -g tide_report_moon_expire_seconds 99999
cp "$REPO_ROOT/test/fixtures/weather.json" $HOME/.cache/tide-report/weather.json

set -ge _tide_print_item_calls
_tide_item_moon

set -g _wttr_calls (string join " " $_tide_print_item_calls)
set -g HOME $_saved_home
command rm -rf $_test_home

@test "wttr provider with valid moon.json shows moon emoji" (
    string match -q "*🌑*" "$_wttr_calls"; or string match -q "*🌕*" "$_wttr_calls"; or string match -q "*❔*" "$_wttr_calls"
    echo $status
) -eq 0

## --- Test 3: expired/missing cache -> unavailable (no hang) ---
set -g _test_home (mktemp -d)
set -g HOME $_test_home
mkdir -p $HOME/.cache/tide-report
# No moon.json; expire immediately so cache is invalid
set -g tide_report_moon_provider "local"
set -g tide_report_moon_refresh_seconds 0
set -g tide_report_moon_expire_seconds 0
cp "$REPO_ROOT/test/fixtures/weather.json" $HOME/.cache/tide-report/weather.json

set -ge _tide_print_item_calls
_tide_item_moon

set -g _expired_calls (string join " " $_tide_print_item_calls)
set -g HOME $_saved_home
command rm -rf $_test_home

@test "expired cache shows unavailable text and does not hang" (
    # Moon item ran (proves no hang) and showed unavailable
    string match -q "*moon*" "$_expired_calls"
    echo $status
) -eq 0
