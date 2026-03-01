# Unit tests for moon phase emoji helper.

set -l root (dirname (dirname (dirname (status filename))))/functions
function _tide_print_item
end
source "$root/_tide_item_moon.fish"

@test "Full Moon returns full moon emoji" (__tide_report_get_moon_emoji "Full Moon") = "🌕"
@test "New Moon returns new moon emoji" (__tide_report_get_moon_emoji "New Moon") = "🌑"
@test "Waxing Crescent returns correct emoji" (__tide_report_get_moon_emoji "Waxing Crescent") = "🌒"
@test "First Quarter returns correct emoji" (__tide_report_get_moon_emoji "First Quarter") = "🌓"
@test "Waning Gibbous returns correct emoji" (__tide_report_get_moon_emoji "Waning Gibbous") = "🌖"
@test "Last Quarter returns correct emoji" (__tide_report_get_moon_emoji "Last Quarter") = "🌗"
@test "unknown phase returns unknown emoji" (__tide_report_get_moon_emoji "Unknown") = "❔"
