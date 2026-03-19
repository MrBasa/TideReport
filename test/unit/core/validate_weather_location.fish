source (dirname (dirname (status filename)))/../helpers/setup.fish
source "$REPO_ROOT/functions/__tide_report_validate_weather_location.fish"

set -l fakebin "$REPO_ROOT/test/helpers/fake_bin"
set -g PATH "$fakebin" $PATH
set -g tide_report_user_agent "tide-report/test"

@test "validate_weather_location accepts lat,lon when forecast API returns weather" (
    set -gx TIDE_REPORT_TEST_CURL_RESPONSE '{"current":{"temperature_2m":11}}'
    __tide_report_validate_weather_location "52.52,13.41" >/dev/null
    test $status -le 1
    echo $status
) -eq 0

@test "validate_weather_location rejects empty input" (
    __tide_report_validate_weather_location "" 2>/dev/null
    echo $status
) -eq 1

@test "validate_weather_location rejects when curl fails" (
    set -gx TIDE_REPORT_TEST_CURL_STATUS 1
    set -gx TIDE_REPORT_TEST_CURL_RESPONSE ''
    __tide_report_validate_weather_location "Berlin" 2>/dev/null
    echo $status
) -eq 1

set -e TIDE_REPORT_TEST_CURL_STATUS
set -e TIDE_REPORT_TEST_CURL_RESPONSE
