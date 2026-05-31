source (dirname (dirname (status filename)))/../helpers/setup.fish
source "$REPO_ROOT/functions/_tide_report_handle_async_moon.fish"

set -l tmp (mktemp -d)
set -g HOME "$tmp/home"
mkdir -p "$HOME/.cache/tide-report"
set -l cache "$HOME/.cache/tide-report/moon.json"

@test "handle_async_moon returns unavailable when cache missing" (
    set -g tide_report_moon_provider local
    __tide_report_test_reset_print_capture
    _tide_report_handle_async_moon moon "$cache" 10 20 "NA" red 5
    test $status -eq 1
    echo $status
) -eq 0

@test "handle_async_moon returns valid when cache is fresh" (
    echo '{"phase":"Full Moon"}' > "$cache"
    set -g tide_report_moon_provider local
    _tide_report_handle_async_moon moon "$cache" 10 20 "NA" red 5
    echo $status
) -eq 0

@test "handle_async_moon stale cache returns valid and acquires fetch lock" (
    echo '{"phase":"Full Moon"}' > "$cache"
    __tide_report_test_set_cache_age "$cache" 15
    set -g tide_report_moon_provider local
    command rm -rf "$HOME/.cache/tide-report/locks"
    _tide_report_handle_async_moon moon "$cache" 10 20 "NA" red 5
    set -l ok $status
    test -d "$HOME/.cache/tide-report/locks/moon.lock"
    echo $ok
) -eq 0

@test "handle_async_moon expired cache with file present shows unavailable" (
    echo '{"phase":"Full Moon"}' > "$cache"
    __tide_report_test_set_cache_age "$cache" 25
    set -g tide_report_moon_provider local
    command rm -rf "$HOME/.cache/tide-report/locks"
    _tide_report_handle_async_moon moon "$cache" 10 20 "NA" red 5
    set -l st $status
    test $st -eq 1; and test -f "$cache"
    echo $status
) -eq 0

@test "handle_async_moon wttr with weather wttr uses shared weather lock" (
    echo '{"phase":"Full Moon"}' > "$cache"
    __tide_report_test_set_cache_age "$cache" 15
    set -g tide_report_moon_provider wttr
    set -g tide_report_weather_provider wttr
    command rm -rf "$HOME/.cache/tide-report/locks"
    _tide_report_handle_async_moon moon "$cache" 10 20 "NA" red 5
    set -l ok $status
    test -d "$HOME/.cache/tide-report/locks/weather.lock"
    echo $ok
) -eq 0

@test "handle_async_moon with lock held and missing cache shows unavailable" (
    command rm -f "$cache"
    set -g tide_report_moon_provider local
    set -l now (command date +%s)
    mkdir -p "$HOME/.cache/tide-report/locks/moon.lock"
    printf '%s\n' "$now" > "$HOME/.cache/tide-report/locks/moon.lock/ts"
    __tide_report_test_reset_print_capture
    _tide_report_handle_async_moon moon "$cache" 10 20 "NA" red 5
    set -l st $status
    command rm -rf "$HOME/.cache/tide-report/locks"
    echo $st
) -eq 1

command rm -rf "$tmp"
