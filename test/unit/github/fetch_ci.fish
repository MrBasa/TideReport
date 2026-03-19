source (dirname (dirname (status filename)))/../helpers/setup.fish
source "$REPO_ROOT/functions/_tide_item_github.fish"

set -l fakebin "$REPO_ROOT/test/helpers/fake_bin"
set -g PATH "$fakebin" $PATH
set -l tmp (mktemp -d)
set -l cache "$tmp/ci.json"
set -l state "$cache.state"

@test "fetch_github_ci writes cache on success" (
    set -gx TIDE_REPORT_TEST_GH_STATUS 0
    set -gx TIDE_REPORT_TEST_GH_RESPONSE '[{"status":"completed","conclusion":"success"}]'
    __tide_report_fetch_github_ci MrBasa/TideReport main "$cache" _lock
    test -f "$cache"; and test -f "$state"
    echo $status
) -eq 0

@test "fetch_github_ci does not write cache on failure" (
    set -gx TIDE_REPORT_TEST_GH_STATUS 1
    set -gx TIDE_REPORT_TEST_GH_RESPONSE ''
    command rm -f "$cache" "$state"
    __tide_report_fetch_github_ci MrBasa/TideReport main "$cache" _lock
    test -f "$cache"; or test -f "$state"; and echo 1; or echo 0
) -eq 0

set -e TIDE_REPORT_TEST_GH_STATUS
set -e TIDE_REPORT_TEST_GH_RESPONSE
command rm -rf "$tmp"
