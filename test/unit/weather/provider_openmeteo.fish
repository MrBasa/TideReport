source (dirname (dirname (status filename)))/../helpers/setup.fish
source "$REPO_ROOT/functions/_tide_report_provider_weather_openmeteo.fish"

@test "wmo_to_condition_code maps clear" (__tide_report_wmo_to_condition_code 0) = "113"
@test "wmo_to_condition_text maps overcast" (__tide_report_wmo_to_condition_text 3) = "Overcast"
@test "degrees_to_16point maps 0 to N" (__tide_report_degrees_to_16point 0) = "N"
@test "degrees_to_16point maps 225 to a valid compass token" (
    string match -q -r '^[A-Z]{1,3}$' (__tide_report_degrees_to_16point 225)
    echo $status
) -eq 0
@test "iso8601_to_unix returns empty for empty input" -z (__tide_report_iso8601_to_unix "")
