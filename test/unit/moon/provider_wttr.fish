source (dirname (dirname (status filename)))/../helpers/setup.fish
source "$REPO_ROOT/functions/_tide_report_provider_moon_wttr.fish"

set -l fakebin "$REPO_ROOT/test/helpers/fake_bin"
set -g PATH "$fakebin" $PATH
set -l tmp (mktemp -d)
set -l cache "$tmp/moon.json"

@test "provider_moon_wttr writes moon cache on success" (
    set -gx TIDE_REPORT_TEST_CURL_STATUS 0
    set -gx TIDE_REPORT_TEST_CURL_RESPONSE "$REPO_ROOT/test/fixtures/weather/wttr.json"
    __tide_report_provider_moon_wttr "$cache" 5 _lock
    test -f "$cache"
    echo $status
) -eq 0

@test "provider_moon_wttr does not write moon cache on failure" (
    set -gx TIDE_REPORT_TEST_CURL_STATUS 1
    set -gx TIDE_REPORT_TEST_CURL_RESPONSE ''
    command rm -f "$cache"
    __tide_report_provider_moon_wttr "$cache" 5 _lock
    test -f "$cache"; and echo 1; or echo 0
) -eq 0

set -e TIDE_REPORT_TEST_CURL_STATUS
set -e TIDE_REPORT_TEST_CURL_RESPONSE
command rm -rf "$tmp"
