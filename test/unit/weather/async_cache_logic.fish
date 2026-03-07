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

command rm -rf "$tmp"
