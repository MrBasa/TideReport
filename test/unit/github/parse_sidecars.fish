source (dirname (dirname (status filename)))/../helpers/setup.fish
source "$REPO_ROOT/functions/_tide_item_github.fish"

set -l tmp (mktemp -d)
set -l cache "$tmp/repo.json"
set -l ci "$tmp/ci.json"
set -g TIDE_REPORT_TEST 1

@test "parse_github renders repo stats from stats sidecar" (
    printf '%s\n' '42 3 10 2 1' > "$cache.stats"
    __tide_report_test_reset_print_capture
    __tide_report_parse_github "$cache"
    string match -q '*★42*⑂3*10*!2*PR1*' "$_tide_print_item_last_argv[2]"
    echo $status
) -eq 0

@test "parse_github renders CI state from state sidecar" (
    cp "$REPO_ROOT/test/fixtures/github/repo.json" "$cache"
    printf '%s\n' '42 3 10 2 1' > "$cache.stats"
    printf '%s\n' 'pass' > "$ci.state"
    set -g tide_report_github_show_ci true
    __tide_report_test_reset_print_capture
    __tide_report_parse_github "$cache" "" "$ci"
    string match -q '*✔*' "$_tide_print_item_last_argv[2]"
    echo $status
) -eq 0

@test "parse_github falls back to legacy json caches when sidecars are absent" (
    cp "$REPO_ROOT/test/fixtures/github/repo.json" "$cache"
    printf '%s\n' '[{"status":"completed","conclusion":"success"}]' > "$ci"
    command rm -f "$cache.stats" "$ci.state"
    set -g tide_report_github_show_ci true
    __tide_report_test_reset_print_capture
    __tide_report_parse_github "$cache" "" "$ci"
    string match -q '*★42*' "$_tide_print_item_last_argv[2]"; and string match -q '*✔*' "$_tide_print_item_last_argv[2]"
    echo $status
) -eq 0

set -e TIDE_REPORT_TEST
command rm -rf "$tmp"
