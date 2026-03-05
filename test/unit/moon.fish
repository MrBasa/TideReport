## Unit tests for moon helpers (emoji mapping and local phase model).

set -l root (dirname (dirname (dirname (status filename))))/functions
## Stub _tide_print_item so moon tests can load plugin code without Tide.
function _tide_print_item --description "Stub Tide's _tide_print_item for moon unit tests"
end
## Moon phase math constants (required by _tide_report_moon_math; not sourced from conf.d here)
set -g __tide_report_moon_PI (math "acos(-1)")
set -g __tide_report_moon_rad (math "$__tide_report_moon_PI / 180")
set -g __tide_report_moon_day_seconds 86400
set -g __tide_report_moon_J1970 2440588
set -g __tide_report_moon_J2000 2451545
set -g __tide_report_moon_obliquity (math "$__tide_report_moon_rad * 23.4397")
source "$root/_tide_item_moon.fish"
source "$root/_tide_report_provider_moon_local.fish"

@test "Full Moon returns full moon emoji" (__tide_report_get_moon_emoji "Full Moon") = "🌕"
@test "New Moon returns new moon emoji" (__tide_report_get_moon_emoji "New Moon") = "🌑"
@test "Waxing Crescent returns correct emoji" (__tide_report_get_moon_emoji "Waxing Crescent") = "🌒"
@test "First Quarter returns correct emoji" (__tide_report_get_moon_emoji "First Quarter") = "🌓"
@test "Waning Gibbous returns correct emoji" (__tide_report_get_moon_emoji "Waning Gibbous") = "🌖"
@test "Last Quarter returns correct emoji" (__tide_report_get_moon_emoji "Last Quarter") = "🌗"
@test "unknown phase returns unknown emoji" (__tide_report_get_moon_emoji "Unknown") = "❔"

@test "local model returns a known phase name" (
    set -l phase (__tide_report_moon_phase_from_unix 1704067200)
    switch "$phase"
        case "New Moon" "Waxing Crescent" "First Quarter" "Waxing Gibbous" "Full Moon" "Waning Gibbous" "Last Quarter" "Waning Crescent"
            echo 0
        case '*'
            echo 1
    end
) -eq 0
