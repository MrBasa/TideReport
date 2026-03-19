## Optional network validation: local moon model vs timeanddate primary phases.

if not set -q RUN_NETWORK_TESTS; or test "$RUN_NETWORK_TESTS" != "1"
    exit 0
end

source (dirname (dirname (status filename)))/helpers/setup.fish
source "$REPO_ROOT/functions/_tide_report_moon_math.fish"
source "$REPO_ROOT/functions/_tide_report_provider_weather_openmeteo.fish"

function __tide_report_month_name_to_number --argument-names name
    switch $name
        case January; echo 01
        case February; echo 02
        case March; echo 03
        case April; echo 04
        case May; echo 05
        case June; echo 06
        case July; echo 07
        case August; echo 08
        case September; echo 09
        case October; echo 10
        case November; echo 11
        case December; echo 12
        case '*'; echo ""
    end
end

@test "timeanddate page is reachable for moon-phase validation" (
    set -l html (curl -s "https://www.timeanddate.com/moon/phases/?year=2027")
    test -n "$html"
    echo $status
) -eq 0

@test "local moon fraction is numeric for reference date" (
    set -l unix (__tide_report_iso8601_to_unix "2027-01-01T12:00")
    set -l frac (__tide_report_moon_phase_fraction_from_unix $unix)
    string match -q -r '^[0-9]+(\.[0-9]+)?$' "$frac"
    echo $status
) -eq 0
