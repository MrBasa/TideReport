source (dirname (dirname (status filename)))/../helpers/setup.fish
source "$REPO_ROOT/functions/_tide_item_github.fish"

set -l fakebin "$REPO_ROOT/test/helpers/fake_bin"
set -g PATH "$fakebin" $PATH
set -g tide_report_github_unavailable_text "…"

@test "unavailable_display appends !auth when gh is not authenticated" (
    set -gx TIDE_REPORT_TEST_GH_AUTH_FAIL 1
    set -e __tide_report_github_auth_ok 2>/dev/null
    set -l text (__tide_report_github_unavailable_display | string collect)
    string match -q '*!auth*' "$text"
    echo $status
) -eq 0

@test "unavailable_display stays generic when gh is authenticated" (
    set -e TIDE_REPORT_TEST_GH_AUTH_FAIL 2>/dev/null
    set -e __tide_report_github_auth_ok 2>/dev/null
    set -l text (__tide_report_github_unavailable_display | string collect)
    string match -q '*!auth*' "$text"; and echo 1; or echo 0
) -eq 0

set -e TIDE_REPORT_TEST_GH_AUTH_FAIL
set -e __tide_report_github_auth_ok 2>/dev/null
