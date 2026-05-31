source (dirname (dirname (status filename)))/../helpers/setup.fish
source "$REPO_ROOT/functions/_tide_report_handle_async_tide.fish"

set -l tmp (mktemp -d)
set -g HOME "$tmp/home"
mkdir -p "$HOME/.cache/tide-report"
set -l cache "$HOME/.cache/tide-report/tide.json"
set -l now (command date +%s)
set -l gnu_date_cmd (__tide_report_gnu_date_cmd)
set -g tide_report_tide_unavailable_text "TUNAV"

@test "handle_async_tide stale cache returns parsed output and acquires lock" (
    cp "$REPO_ROOT/test/fixtures/tide/predictions.json" "$cache"
    __tide_report_test_set_cache_age "$cache" 500
    command rm -rf "$HOME/.cache/tide-report/locks"
    set -l out (_tide_report_handle_async_tide \
        "$cache" "$now" 300 900 "$gnu_date_cmd" "$tide_report_tide_unavailable_text" red "!data" 5 "https://example.test")
    set -l ok 0
    test -n "$out"; and test -d "$HOME/.cache/tide-report/locks/tide.lock"; or set ok 1
    echo $ok
) -eq 0

@test "handle_async_tide missing cache shows unavailable" (
    command rm -f "$cache"
    command rm -rf "$HOME/.cache/tide-report/locks"
    set -l out (_tide_report_handle_async_tide \
        "$cache" "$now" 300 900 "$gnu_date_cmd" "$tide_report_tide_unavailable_text" red "!data" 5 "https://example.test")
    string match -q '*TUNAV*' "$out"
    echo $status
) -eq 0

@test "handle_async_tide expired cache with file present shows unavailable" (
    cp "$REPO_ROOT/test/fixtures/tide/predictions.json" "$cache"
    __tide_report_test_set_cache_age "$cache" 1000
    command rm -rf "$HOME/.cache/tide-report/locks"
    set -l out (_tide_report_handle_async_tide \
        "$cache" "$now" 300 900 "$gnu_date_cmd" "$tide_report_tide_unavailable_text" red "!data" 5 "https://example.test")
    string match -q '*TUNAV*' "$out"; and test -f "$cache"
    echo $status
) -eq 0

@test "handle_async_tide with lock held and missing cache shows unavailable" (
    command rm -f "$cache"
    set -l lock_now (command date +%s)
    mkdir -p "$HOME/.cache/tide-report/locks/tide.lock"
    printf '%s\n' "$lock_now" > "$HOME/.cache/tide-report/locks/tide.lock/ts"
    set -l out (_tide_report_handle_async_tide \
        "$cache" "$now" 300 900 "$gnu_date_cmd" "$tide_report_tide_unavailable_text" red "!data" 5 "https://example.test")
    command rm -rf "$HOME/.cache/tide-report/locks"
    string match -q '*TUNAV*' "$out"
    echo $status
) -eq 0

command rm -rf "$tmp"
