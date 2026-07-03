source (dirname (dirname (status filename)))/../helpers/setup.fish
source "$REPO_ROOT/functions/_tide_report_provider_weather_openmeteo.fish"

set -l fakebin "$REPO_ROOT/test/helpers/fake_bin"
set -g PATH "$fakebin" $PATH
set -l tmp (mktemp -d)
set -g HOME "$tmp/home"
mkdir -p "$HOME/.cache/tide-report"
set -l out "$HOME/.cache/tide-report/weather.json"
set -l max_time_file "$tmp/curl_max_time"

@test "wmo_to_condition_code maps clear" (__tide_report_wmo_to_condition_code 0) = "113"
@test "wmo_to_condition_text maps overcast" (__tide_report_wmo_to_condition_text 3) = "Overcast"
@test "degrees_to_16point maps 0 to N" (__tide_report_degrees_to_16point 0) = "N"
@test "degrees_to_16point maps 225 to a valid compass token" (
    string match -q -r '^[A-Z]{1,3}$' (__tide_report_degrees_to_16point 225)
    echo $status
) -eq 0
@test "iso8601_to_unix returns empty for empty input" -z (__tide_report_iso8601_to_unix "")

@test "provider_openmeteo writes normalized weather.json from forecast" (
    set -gx TIDE_REPORT_RESOLVED_LOCATION "52.0,13.0"
    set -gx TIDE_REPORT_TEST_CURL_FORECAST_RESPONSE "$REPO_ROOT/test/fixtures/weather/openmeteo_forecast.json"
    set -gx TIDE_REPORT_TEST_CURL_FORECAST_STATUS 0
    command rm -f "$out"
    __tide_report_provider_weather_openmeteo "$out" 7 weather
    set -l ok 0
    test -f "$out"; and jq -e '.temp_c == 12' "$out" >/dev/null; or set ok 1
    echo $ok
) -eq 0

@test "provider_openmeteo passes timeout_sec to curl max-time" (
    set -gx TIDE_REPORT_RESOLVED_LOCATION "52.0,13.0"
    set -gx TIDE_REPORT_TEST_CURL_FORECAST_RESPONSE "$REPO_ROOT/test/fixtures/weather/openmeteo_forecast.json"
    set -gx TIDE_REPORT_TEST_CURL_MAX_TIME_FILE "$max_time_file"
    command rm -f "$max_time_file" "$out"
    __tide_report_provider_weather_openmeteo "$out" 9 weather
    test (command cat "$max_time_file") = 9
    echo $status
) -eq 0

@test "provider_openmeteo does not write cache on forecast failure" (
    set -gx TIDE_REPORT_RESOLVED_LOCATION "52.0,13.0"
    set -gx TIDE_REPORT_TEST_CURL_FORECAST_STATUS 1
    set -gx TIDE_REPORT_TEST_CURL_FORECAST_RESPONSE ''
    command rm -f "$out"
    __tide_report_provider_weather_openmeteo "$out" 5 weather
    test -f "$out"; and echo 1; or echo 0
) -eq 0

@test "openmeteo_fetch_ip_geo uses HTTPS and parses ipapi.co response" (
    source "$REPO_ROOT/functions/_tide_report_weather_helpers.fish"
    set -gx TIDE_REPORT_TEST_CURL_IP_RESPONSE "$REPO_ROOT/test/fixtures/weather/ipapi_co.json"
    set -l ip_json (__tide_report_openmeteo_fetch_ip_geo 5 | string collect)
    set -l lat (printf "%s" "$ip_json" | jq -r '.latitude // .lat // empty')
    test "$lat" = 52.52
    echo $status
) -eq 0

@test "openmeteo_fetch_ip_geo falls back when ipapi returns non-json" (
    source "$REPO_ROOT/functions/_tide_report_weather_helpers.fish"
    set -gx TIDE_REPORT_TEST_CURL_IP_RESPONSE 'Please contact us for a trial account'
    set -gx TIDE_REPORT_TEST_CURL_IP_GEOJS_RESPONSE "$REPO_ROOT/test/fixtures/weather/geojs_ip.json"
    set -l ip_json (__tide_report_openmeteo_fetch_ip_geo 5 | string collect)
    set -l lat (printf "%s" "$ip_json" | jq -r '.latitude // .lat // empty')
    test "$lat" = 41.9209
    echo $status
) -eq 0

@test "openmeteo_wizard_ip_line suppresses jq errors on provider failure" (
    source "$REPO_ROOT/functions/_tide_report_weather_helpers.fish"
    set -gx TIDE_REPORT_TEST_CURL_IP_RESPONSE 'Please contact us for a trial account'
    set -e TIDE_REPORT_TEST_CURL_IP_GEOJS_RESPONSE
    set -l out (__tide_report_openmeteo_wizard_ip_line 5 2>&1 | string collect)
    __tide_report_openmeteo_wizard_ip_line 5 >/dev/null 2>/dev/null
    test $status -ne 0
    and not string match -qi '*jq:*' -- "$out"
    echo $status
) -eq 0

set -e TIDE_REPORT_RESOLVED_LOCATION
set -e TIDE_REPORT_TEST_CURL_FORECAST_RESPONSE
set -e TIDE_REPORT_TEST_CURL_FORECAST_STATUS
set -e TIDE_REPORT_TEST_CURL_MAX_TIME_FILE
set -e TIDE_REPORT_TEST_CURL_IP_RESPONSE
set -e TIDE_REPORT_TEST_CURL_IP_GEOJS_RESPONSE
command rm -rf "$tmp"
