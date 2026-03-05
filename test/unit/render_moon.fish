## Unit tests for __tide_report_get_moon_emoji (phase text → emoji). Reused as moon "render".

source (dirname (dirname (status filename)))/setup.fish

@test "get_moon_emoji Full Moon returns 🌕" (__tide_report_get_moon_emoji "Full Moon") = "🌕"
@test "get_moon_emoji New Moon returns 🌑" (__tide_report_get_moon_emoji "New Moon") = "🌑"
@test "get_moon_emoji First Quarter returns 🌓" (__tide_report_get_moon_emoji "First Quarter") = "🌓"
@test "get_moon_emoji Last Quarter returns 🌗" (__tide_report_get_moon_emoji "Last Quarter") = "🌗"
@test "get_moon_emoji Waxing Crescent returns 🌒" (__tide_report_get_moon_emoji "Waxing Crescent") = "🌒"
@test "get_moon_emoji Waning Gibbous returns 🌖" (__tide_report_get_moon_emoji "Waning Gibbous") = "🌖"
@test "get_moon_emoji unknown returns default" (__tide_report_get_moon_emoji "Unknown") = "❔"
