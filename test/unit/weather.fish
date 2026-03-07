## Unit tests for weather helpers and parser behavior.

source (dirname (dirname (status filename)))/helpers/setup.fish
source "$REPO_ROOT/functions/_tide_item_weather.fish"

@test "weather code 113 returns sun emoji" (__tide_report_get_weather_emoji 113) = "☀️"
@test "weather code 119 returns cloud emoji" (__tide_report_get_weather_emoji 119) = "☁️"
@test "weather code 122 returns overcast emoji" (__tide_report_get_weather_emoji 122) = "🌥️"
@test "weather code 999 returns unknown emoji" (__tide_report_get_weather_emoji 999) = "❔"

@test "wind N returns down arrow" (__tide_report_get_wind_arrow "N") = "⬇"
@test "wind S returns up arrow" (__tide_report_get_wind_arrow "S") = "⬆"
@test "wind W returns right arrow" (__tide_report_get_wind_arrow "W") = "➡"
@test "wind SW returns NE arrow" (__tide_report_get_wind_arrow "SW") = "⬈"
@test "wind invalid returns empty" (__tide_report_get_wind_arrow "INVALID") = ""

@test "gnu_date_cmd returns empty or gdate/date" (
    set -l c (__tide_report_gnu_date_cmd | string collect)
    test -z "$c"; or string match -q -r "^(gdate|date)\$" "$c"
    echo $status
) -eq 0
# format_wttr_time: with "07:30 AM" and %H:%M we expect something (formatted or fallback)
@test "format_wttr_time returns something for valid input" -n (__tide_report_format_wttr_time "07:30 AM" "%H:%M")
@test "format_wttr_time returns empty for empty input" -z (__tide_report_format_wttr_time "" "%H:%M")

# format_unix_time: Unix timestamp to display format
@test "format_unix_time returns something for valid epoch" -n (__tide_report_format_unix_time "1727692200" "%H:%M")
@test "format_unix_time returns empty for empty input" -z (__tide_report_format_unix_time "" "%H:%M")
@test "format_unix_time returns empty for null input" -z (__tide_report_format_unix_time "null" "%H:%M")

@test "time_string_to_unix returns empty for empty input" -z (__tide_report_time_string_to_unix "")

@test "time_string_to_unix returns numeric epoch for valid input" (
    set -l out (__tide_report_time_string_to_unix "07:30 AM" | string collect)
    string match -q -r '^[0-9]+$' "$out"
    echo $status
) -eq 0

@test "time_string_to_unix returns empty for malformed input" (
    set -l out (__tide_report_time_string_to_unix "not-a-time" | string collect)
    test -z "$out"
    echo $status
) -eq 0

@test "parse_weather prints parsed weather for metric units" (
    set -l tmp (mktemp -d)
    set -l cache "$tmp/weather.json"
    cp "$REPO_ROOT/test/fixtures/weather/openmeteo.json" "$cache"
    set -g tide_report_units m
    set -g tide_report_weather_format "%c %t %w"
    __tide_report_test_reset_print_capture
    __tide_report_parse_weather "$cache"
    set -l payload "$_tide_print_item_last_argv[2]"
    command rm -rf "$tmp"
    test -n "$payload"; and string match -q -r '[-+]?[0-9]+°' "$payload"; and string match -q '*km/h*' "$payload"
    echo $status
) -eq 0

@test "parse_weather switches wind units for uscs mode" (
    set -l tmp (mktemp -d)
    set -l cache "$tmp/weather.json"
    cp "$REPO_ROOT/test/fixtures/weather/openmeteo.json" "$cache"
    set -g tide_report_units u
    set -g tide_report_weather_format "%c %t %w"
    __tide_report_test_reset_print_capture
    __tide_report_parse_weather "$cache"
    set -l payload "$_tide_print_item_last_argv[2]"
    command rm -rf "$tmp"
    string match -q '*mph*' "$payload"
    echo $status
) -eq 0

@test "parse_weather prints unavailable text when temp is missing" (
    set -l tmp (mktemp -d)
    set -l cache "$tmp/weather_bad.json"
    printf '%s\n' '{"temp_c":null}' > "$cache"
    set -g tide_report_units m
    __tide_report_test_reset_print_capture
    __tide_report_parse_weather "$cache"
    set -l item_name "$_tide_print_item_last_argv[1]"
    command rm -rf "$tmp"
    test "$item_name" = "weather"
    echo $status
) -eq 0
