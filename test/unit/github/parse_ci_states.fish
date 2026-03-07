source (dirname (dirname (status filename)))/../helpers/setup.fish
source "$REPO_ROOT/functions/_tide_item_github.fish"

set -l tmp (mktemp -d)
set -l cache "$tmp/repo.json"
set -l ci "$tmp/ci.json"
cp "$REPO_ROOT/test/fixtures/github/repo.json" "$cache"
set -g tide_report_github_show_ci true
set -g TIDE_REPORT_TEST 1

@test "parse_github renders pass icon for successful CI" (
    echo '[{"status":"completed","conclusion":"success"}]' > "$ci"
    __tide_report_test_reset_print_capture
    __tide_report_parse_github "$cache" "" "$ci"
    string match -q '*✔*' "$_tide_print_item_last_argv[2]"
    echo $status
) -eq 0

@test "parse_github renders fail icon for failed CI" (
    echo '[{"status":"completed","conclusion":"failure"}]' > "$ci"
    __tide_report_test_reset_print_capture
    __tide_report_parse_github "$cache" "" "$ci"
    string match -q '*✗*' "$_tide_print_item_last_argv[2]"
    echo $status
) -eq 0

@test "parse_github renders pending icon for in-progress CI" (
    echo '[{"status":"in_progress","conclusion":null}]' > "$ci"
    __tide_report_test_reset_print_capture
    __tide_report_parse_github "$cache" "" "$ci"
    string match -q '*⋯*' "$_tide_print_item_last_argv[2]"
    echo $status
) -eq 0

set -e TIDE_REPORT_TEST
command rm -rf "$tmp"
