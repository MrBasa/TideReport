## Legacy compatibility unit test file.
## Keep this entrypoint but assert plugin behavior instead of testing copied regex logic.

source (dirname (dirname (status filename)))/helpers/setup.fish
source "$REPO_ROOT/functions/_tide_item_github.fish"

set -g TIDE_REPORT_TEST 1

@test "render_github includes icon and stats" (
    set -l out (__tide_report_render_github 42 3 10 2 1 none | string collect)
    string match -q '**★42*⑂3*10*!2*PR1*' "$out"
    echo $status
) -eq 0

@test "parse_github with fixture invokes _tide_print_item" (
    set -l tmp (mktemp -d)
    set -l cache "$tmp/repo.json"
    cp "$REPO_ROOT/test/fixtures/github/repo.json" "$cache"
    __tide_report_test_reset_print_capture
    __tide_report_parse_github "$cache"
    set -l ok 1
    if test (count $_tide_print_item_calls) -lt 1
        set ok 0
    end
    command rm -rf "$tmp"
    echo $ok
) -eq 1

set -e TIDE_REPORT_TEST
