source (dirname (dirname (status filename)))/../helpers/setup.fish
source "$REPO_ROOT/functions/_tide_item_github.fish"

set -l fakebin "$REPO_ROOT/test/helpers/fake_bin"
set -g PATH "$fakebin" $PATH
set -l tmp (mktemp -d)
set -l cache "$tmp/repo.json"

@test "fetch_github writes cache on success" (
    set -gx TIDE_REPORT_TEST_GH_STATUS 0
    set -gx TIDE_REPORT_TEST_GH_RESPONSE "$REPO_ROOT/test/fixtures/github/repo.json"
    __tide_report_fetch_github MrBasa/TideReport "$cache" 5 _lock
    test -f "$cache"
    echo $status
) -eq 0

@test "fetch_github does not write cache on failure" (
    set -gx TIDE_REPORT_TEST_GH_STATUS 1
    set -gx TIDE_REPORT_TEST_GH_RESPONSE ''
    command rm -f "$cache"
    __tide_report_fetch_github MrBasa/TideReport "$cache" 5 _lock
    test -f "$cache"; and echo 1; or echo 0
) -eq 0

set -e TIDE_REPORT_TEST_GH_STATUS
set -e TIDE_REPORT_TEST_GH_RESPONSE
command rm -rf "$tmp"
