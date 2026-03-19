source (dirname (dirname (status filename)))/../helpers/setup.fish
source "$REPO_ROOT/functions/_tide_report_provider_weather_wttr.fish"

set -l fakebin "$REPO_ROOT/test/helpers/fake_bin"
set -g PATH "$fakebin" $PATH
set -l tmp (mktemp -d)
set -g HOME "$tmp/home"
mkdir -p "$HOME/.cache/tide-report"
set -l out "$HOME/.cache/tide-report/weather.json"

@test "provider_wttr writes normalized weather and moon cache" (
    set -gx TIDE_REPORT_TEST_CURL_STATUS 0
    set -gx TIDE_REPORT_TEST_CURL_RESPONSE "$REPO_ROOT/test/fixtures/weather/wttr.json"
    __tide_report_provider_wttr "$out" 5 _lock
    test -f "$out"; and test -f "$HOME/.cache/tide-report/moon.json"
    echo $status
) -eq 0

@test "provider_wttr does not write cache on curl failure" (
    set -gx TIDE_REPORT_TEST_CURL_STATUS 1
    set -gx TIDE_REPORT_TEST_CURL_RESPONSE ''
    command rm -f "$out"
    __tide_report_provider_wttr "$out" 5 _lock
    test -f "$out"; and echo 1; or echo 0
) -eq 0

set -e TIDE_REPORT_TEST_CURL_STATUS
set -e TIDE_REPORT_TEST_CURL_RESPONSE
command rm -rf "$tmp"
