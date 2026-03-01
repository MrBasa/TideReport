# Unit tests for weather helpers (emoji, wind arrow, date cmd, time format).
# Source only the weather item so we get __tide_report_get_weather_emoji, etc.

set -l root (dirname (dirname (dirname (status filename))))/functions
# Stub so parser code doesn't fail if we ever call it
function _tide_print_item
end
source "$root/_tide_item_weather.fish"

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
