## Integration: prompt item payload should not change across fish_emoji_width values.

source (dirname (dirname (dirname (status filename))))/helpers/setup.fish

function _strip_ansi --argument-names s
    string replace -r '\e\[[0-9;]*m' '' -- "$s"
end

@test "moon parse output is stable for fish_emoji_width 1 and 2" (
    set -l tmp (mktemp -d)
    set -l cache "$tmp/moon.json"
    cp "$REPO_ROOT/test/fixtures/moon/phase.json" "$cache"

    set -g fish_emoji_width 1
    __tide_report_test_reset_print_capture
    __tide_report_parse_moon "$cache"
    set -l out_w1 (_strip_ansi "$_tide_print_item_last_argv[2]" | string trim)

    set -g fish_emoji_width 2
    __tide_report_test_reset_print_capture
    __tide_report_parse_moon "$cache"
    set -l out_w2 (_strip_ansi "$_tide_print_item_last_argv[2]" | string trim)

    set -e fish_emoji_width
    command rm -rf "$tmp"

    test "$out_w1" = "$out_w2"; and test "$out_w1" = "🌕"
    echo $status
) -eq 0

@test "weather parse output is stable for fish_emoji_width 1 and 2" (
    set -l tmp (mktemp -d)
    set -l cache "$tmp/weather.json"
    cp "$REPO_ROOT/test/fixtures/weather/openmeteo.json" "$cache"
    set -g tide_report_units m
    set -g tide_report_weather_format "%c %t %w"

    set -g fish_emoji_width 1
    __tide_report_test_reset_print_capture
    __tide_report_parse_weather "$cache"
    set -l out_w1 (_strip_ansi "$_tide_print_item_last_argv[2]" | string trim)

    set -g fish_emoji_width 2
    __tide_report_test_reset_print_capture
    __tide_report_parse_weather "$cache"
    set -l out_w2 (_strip_ansi "$_tide_print_item_last_argv[2]" | string trim)

    set -e fish_emoji_width
    command rm -rf "$tmp"

    test "$out_w1" = "$out_w2"; and string match -q '*°*' "$out_w1"
    echo $status
) -eq 0
