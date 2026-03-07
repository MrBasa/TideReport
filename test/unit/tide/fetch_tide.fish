source (dirname (dirname (status filename)))/../helpers/setup.fish
source "$REPO_ROOT/functions/_tide_item_tide.fish"

set -l fakebin "$REPO_ROOT/test/helpers/fake_bin"
set -g PATH "$fakebin" $PATH
set -l tmp (mktemp -d)
set -l cache "$tmp/tide.json"
set -g tide_report_user_agent "tide-report/test"

@test "fetch_tide writes cache for valid NOAA payload" (
    set -gx TIDE_REPORT_TEST_CURL_STATUS 0
    set -gx TIDE_REPORT_TEST_CURL_RESPONSE "$REPO_ROOT/test/fixtures/tide/predictions.json"
    __tide_report_fetch_tide https://example.test "$cache" _lock
    test -f "$cache"
    echo $status
) -eq 0

@test "fetch_tide does not write cache for invalid payload" (
    set -gx TIDE_REPORT_TEST_CURL_STATUS 0
    set -gx TIDE_REPORT_TEST_CURL_RESPONSE '{"predictions":[]}'
    command rm -f "$cache"
    __tide_report_fetch_tide https://example.test "$cache" _lock
    test -f "$cache"; and echo 1; or echo 0
) -eq 0

set -e TIDE_REPORT_TEST_CURL_STATUS
set -e TIDE_REPORT_TEST_CURL_RESPONSE
command rm -rf "$tmp"
