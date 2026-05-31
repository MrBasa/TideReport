source (dirname (dirname (status filename)))/../helpers/setup.fish
source "$REPO_ROOT/functions/_tide_report_handle_async_weather.fish"

set -l fakebin "$REPO_ROOT/test/helpers/fake_bin"
set -g PATH "$fakebin" $PATH
set -l tmp (mktemp -d)
set -g HOME "$tmp/home"
mkdir -p "$HOME/.cache/tide-report"
set -l out "$HOME/.cache/tide-report/weather.json"
set -l max_time_file "$tmp/curl_max_time"

@test "fetch_weather propagates tide_report_service_timeout_millis to curl max-time" (
    set -g tide_report_service_timeout_millis 11000
    set -g tide_report_weather_provider openmeteo
    set -g tide_report_weather_location "52.0,13.0"
    set -gx TIDE_REPORT_TEST_CURL_FORECAST_RESPONSE "$REPO_ROOT/test/fixtures/weather/openmeteo_forecast.json"
    set -gx TIDE_REPORT_TEST_CURL_MAX_TIME_FILE "$max_time_file"
    command rm -f "$max_time_file" "$out"
    set -l timeout_sec (math --scale=0 "$tide_report_service_timeout_millis / 1000")
    __tide_report_fetch_weather "$out" "$timeout_sec" weather
    test (command cat "$max_time_file") = 11
    echo $status
) -eq 0

set -e TIDE_REPORT_TEST_CURL_FORECAST_RESPONSE
set -e TIDE_REPORT_TEST_CURL_MAX_TIME_FILE
command rm -rf "$tmp"
