source (dirname (dirname (status filename)))/../helpers/setup.fish
source "$REPO_ROOT/functions/_tide_report_validate_weather_location.fish"

set -l fakebin "$REPO_ROOT/test/helpers/fake_bin"
set -g PATH "$fakebin" $PATH
set -gx TIDE_REPORT_TEST_CURL_FORECAST_RESPONSE "$REPO_ROOT/test/fixtures/weather/openmeteo_forecast.json"
set -gx TIDE_REPORT_TEST_CURL_FORECAST_STATUS 0
set -gx TIDE_REPORT_TEST_CURL_GEOCODE_RESPONSE "$REPO_ROOT/test/fixtures/weather/openmeteo_forecast.json"

@test "validate_weather_location accepts coordinates" (
    _tide_report_validate_weather_location "52.52,13.41" >/dev/null
    echo $status
) -eq 0

@test "validate_weather_location rejects empty input" (
    _tide_report_validate_weather_location "" 2>/dev/null
    echo $status
) -ne 0

@test "validate_weather_location rejects unknown place without geocode" (
    set -e TIDE_REPORT_TEST_CURL_GEOCODE_RESPONSE
    _tide_report_validate_weather_location "Berlin" 2>/dev/null
    echo $status
) -ne 0

set -e TIDE_REPORT_TEST_CURL_FORECAST_RESPONSE
set -e TIDE_REPORT_TEST_CURL_FORECAST_STATUS
set -e TIDE_REPORT_TEST_CURL_GEOCODE_RESPONSE
