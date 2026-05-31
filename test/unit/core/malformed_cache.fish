source (dirname (dirname (status filename)))/../helpers/setup.fish
source "$REPO_ROOT/functions/_tide_report_handle_async_tide.fish"
__tide_report_test_source_items

set -l tmp (mktemp -d)

@test "parse_weather handles corrupt weather.json gracefully" (
    set -l cache "$tmp/bad_weather.json"
    printf '%s\n' '{not-json' > "$cache"
    __tide_report_test_reset_print_capture
    __tide_report_parse_weather "$cache"
    test "$_tide_print_item_last_argv[1]" = weather
    echo $status
) -eq 0

@test "parse_github handles corrupt repo cache gracefully" (
    set -l cache "$tmp/bad_github.json"
    printf '%s\n' '{broken' > "$cache"
    __tide_report_test_reset_print_capture
    __tide_report_parse_github "$cache"
    test "$_tide_print_item_last_argv[1]" = github
    echo $status
) -eq 0

@test "handle_async_tide handles corrupt tide.json as parse failure" (
    set -l cache "$tmp/bad_tide.json"
    set -g tide_report_tide_unavailable_text "TUNAV"
    printf '%s\n' '{"predictions":[]}' > "$cache"
    set -l now (command date +%s)
    set -l gnu_date_cmd (__tide_report_gnu_date_cmd)
    set -l out (_tide_report_handle_async_tide \
        "$cache" "$now" 99999 99999 "$gnu_date_cmd" "$tide_report_tide_unavailable_text" red "!data" 5 "https://example.test")
    string match -q '*!data*' "$out"
    echo $status
) -eq 0

command rm -rf "$tmp"
