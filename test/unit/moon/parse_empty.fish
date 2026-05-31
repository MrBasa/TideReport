source (dirname (dirname (status filename)))/../helpers/setup.fish
source "$REPO_ROOT/functions/_tide_item_moon.fish"

set -l tmp (mktemp -d)

@test "parse_moon shows unavailable for empty moon.json" (
    set -l cache "$tmp/empty_moon.json"
    printf '%s\n' '{}' > "$cache"
    __tide_report_test_reset_print_capture
    __tide_report_parse_moon "$cache"
    set -l item "$_tide_print_item_last_argv[1]"
    test "$item" = moon
    echo $status
) -eq 0

command rm -rf "$tmp"
