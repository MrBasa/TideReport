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
    _tide_report_handle_async_moon moon "$cache" 10 20 "NA" red 5
    echo $status
) -eq 0

command rm -rf "$tmp"
