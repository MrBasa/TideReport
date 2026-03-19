## Integration: render helpers and parse flow should match normalized deterministic output.

source (dirname (dirname (status filename)))/helpers/setup.fish
__tide_report_test_source_items

function _strip_ansi --argument-names s
    string replace -r '\e\[[0-9;]*m' '' -- "$s"
end

set -g TIDE_REPORT_TEST 1

@test "github render equals parse output for fixture" (
    set -l tmp (mktemp -d)
    set -l cache "$tmp/repo.json"
    cp "$REPO_ROOT/test/fixtures/github/repo.json" "$cache"
    __tide_report_test_reset_print_capture
    __tide_report_parse_github "$cache"
    set -l flow (_strip_ansi "$_tide_print_item_last_argv[2]" | string trim)
    set -l render (_strip_ansi (__tide_report_render_github 42 3 10 2 1 none | string collect) | string trim)
    command rm -rf "$tmp"
    test "$flow" = "$render"
    echo $status
) -eq 0

@test "moon parse equals emoji helper for fixture phase" (
    set -l tmp (mktemp -d)
    set -l cache "$tmp/moon.json"
    cp "$REPO_ROOT/test/fixtures/moon/phase.json" "$cache"
    __tide_report_test_reset_print_capture
    __tide_report_parse_moon "$cache"
    set -l flow (_strip_ansi "$_tide_print_item_last_argv[2]" | string trim)
    set -l render (__tide_report_get_moon_emoji "Full Moon")
    command rm -rf "$tmp"
    test "$flow" = "$render"
    echo $status
) -eq 0

set -e TIDE_REPORT_TEST
