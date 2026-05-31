source (dirname (dirname (status filename)))/../helpers/setup.fish
__tide_report_test_source_items

set -l tmp (mktemp -d)
set -g HOME "$tmp/home"
mkdir -p "$HOME/.cache/tide-report"
set -l cache "$HOME/.cache/tide-report/weather.json"

@test "handle_async_weather returns unavailable when cache missing" (
    __tide_report_test_reset_print_capture
    _tide_report_handle_async_weather weather "$cache" 300 900 "NA" red 5
    test $status -eq 1
    echo $status
) -eq 0

@test "handle_async_weather returns valid when cache is fresh" (
    echo '{"temp_c":12}' > "$cache"
    __tide_report_test_reset_print_capture
    _tide_report_handle_async_weather weather "$cache" 300 900 "NA" red 5
    echo $status
) -eq 0

@test "handle_async_weather stale cache returns valid and acquires fetch lock" (
    echo '{"temp_c":12}' > "$cache"
    __tide_report_test_set_cache_age "$cache" 500
    command rm -rf "$HOME/.cache/tide-report/locks"
    __tide_report_test_reset_print_capture
    _tide_report_handle_async_weather weather "$cache" 300 900 "NA" red 5
    set -l ok $status
    test -d "$HOME/.cache/tide-report/locks/weather.lock"
    echo $ok
) -eq 0

@test "handle_async_weather expired cache with file present shows unavailable" (
    echo '{"temp_c":12}' > "$cache"
    __tide_report_test_set_cache_age "$cache" 1000
    command rm -rf "$HOME/.cache/tide-report/locks"
    __tide_report_test_reset_print_capture
    _tide_report_handle_async_weather weather "$cache" 300 900 "NA" red 5
    set -l st $status
    test $st -eq 1; and test -f "$cache"
    echo $status
) -eq 0

@test "handle_async_weather with lock held and missing cache shows unavailable" (
    command rm -f "$cache"
    set -l now (command date +%s)
    mkdir -p "$HOME/.cache/tide-report/locks/weather.lock"
    printf '%s\n' "$now" > "$HOME/.cache/tide-report/locks/weather.lock/ts"
    __tide_report_test_reset_print_capture
    _tide_report_handle_async_weather weather "$cache" 300 900 "NA" red 5
    set -l st $status
    command rm -rf "$HOME/.cache/tide-report/locks"
    echo $st
) -eq 1

@test "handle_async_weather stale cache with lock held still returns valid" (
    echo '{"temp_c":12}' > "$cache"
    __tide_report_test_set_cache_age "$cache" 500
    set -l now (command date +%s)
    mkdir -p "$HOME/.cache/tide-report/locks/weather.lock"
    printf '%s\n' "$now" > "$HOME/.cache/tide-report/locks/weather.lock/ts"
    __tide_report_test_reset_print_capture
    _tide_report_handle_async_weather weather "$cache" 300 900 "NA" red 5
    set -l st $status
    command rm -rf "$HOME/.cache/tide-report/locks"
    echo $st
) -eq 0

command rm -rf "$tmp"
