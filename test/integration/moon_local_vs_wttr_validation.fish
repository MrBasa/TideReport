## Optional validation test: compare local moon model against wttr.in
## This test is skipped unless TIDE_REPORT_ENABLE_NETWORK_TESTS is set.

if not set -q TIDE_REPORT_ENABLE_NETWORK_TESTS
    exit 0
end

source (dirname (dirname (status filename)))/setup.fish
source "$REPO_ROOT/functions/_tide_report_provider_moon_local.fish"

## Compare local moon model against wttr.in for a given day index offset from today.
function __moon_validation_case --description "Compare local moon phase with wttr.in for the given day offset" --argument-names day_index
    set -l now (command date +%s)
    set -l unix (math "$now + $day_index * 86400")
    set -l local_phase (__tide_report_moon_phase_from_unix $unix)

    set -l url "$tide_report_wttr_url/$tide_report_weather_location?format=j1&lang=$tide_report_weather_language"

    # wttr.in can be unstable; allow a generous timeout and one retry.
    set -l data ""
    for attempt in 1 2
        set data (curl -s -A "$tide_report_user_agent" --max-time 20 "$url")
        if test $status -eq 0; and test -n "$data"
            break
        end
        if test $attempt -eq 1
            echo "Day index $day_index: wttr.in request failed on attempt $attempt, retrying..." >&2
        end
    end
    if test -z "$data"
        echo "Day index $day_index: network error talking to wttr.in after retries" >&2
        return 1
    end
    set -l wttr_phase (printf "%s" "$data" | jq -r ".weather[$day_index].astronomy[0].moon_phase // \"\"")
    if test -z "$wttr_phase"
        echo "Day index $day_index: wttr.in returned empty moon_phase" >&2
        return 1
    end

    if test "$local_phase" != "$wttr_phase"
        echo "Day index $day_index:" >&2
        echo "  local: $local_phase" >&2
        echo "  wttr : $wttr_phase" >&2
        return 1
    end

    echo "Day index $day_index: local and wttr agree on $local_phase" >&2
    return 0
end

@test "local moon model matches wttr.in for the next few days (when enabled)" (
    __moon_validation_case 0; and __moon_validation_case 1; and __moon_validation_case 2
    echo $status
) -eq 0

