## Optional network validation: local moon model vs wttr.in.

if not set -q RUN_NETWORK_TESTS
    exit 0
end

source (dirname (dirname (status filename)))/helpers/setup.fish
source "$REPO_ROOT/functions/_tide_report_provider_moon_local.fish"

function __moon_validation_case --argument-names day_index
    set -l now (command date +%s)
    set -l unix (math "$now + $day_index * 86400")
    set -l local_phase (__tide_report_moon_phase_from_unix $unix)

    set -l url "$tide_report_wttr_url/$tide_report_weather_location?format=j1&lang=$tide_report_weather_language"
    set -l data (curl -s -A "$tide_report_user_agent" --max-time 20 "$url")
    if test $status -ne 0; or test -z "$data"
        echo "wttr.in request failed" >&2
        return 1
    end

    set -l wttr_phase (printf "%s" "$data" | jq -r ".weather[$day_index].astronomy[0].moon_phase // \"\"")
    test -n "$wttr_phase"; and test "$local_phase" = "$wttr_phase"
    echo $status
end

@test "local moon model matches wttr for next 3 days" (
    __moon_validation_case 0; and __moon_validation_case 1; and __moon_validation_case 2
    echo $status
) -eq 0
