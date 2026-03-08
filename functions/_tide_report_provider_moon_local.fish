## Local moon phase provider (offline)
##
## Produces a normalized moon.json:
##   { "phase": "Full Moon" }
## Phase names are chosen to match __tide_report_get_moon_emoji.

## Map phase fraction [0,1) to phase name (bucket 0–7). Used by __tide_report_moon_phase_from_unix.
function __tide_report_moon_phase_name_from_fraction --description "Map phase fraction to phase name" --argument-names phase_fraction
    set -l bucket (math "floor($phase_fraction * 8)")
    switch $bucket
        case 0
            echo "New Moon"
        case 1
            echo "Waxing Crescent"
        case 2
            echo "First Quarter"
        case 3
            echo "Waxing Gibbous"
        case 4
            echo "Full Moon"
        case 5
            echo "Waning Gibbous"
        case 6
            echo "Last Quarter"
        case 7 '*'
            echo "Waning Crescent"
    end
end

## Map Unix timestamp to a human-readable moon phase name using the local model.
function __tide_report_moon_phase_from_unix --description "Map Unix time to a human-readable moon phase name" --argument-names unix_time
    set -l phase_fraction (__tide_report_moon_phase_fraction_from_unix $unix_time)
    if test -z "$phase_fraction"
        return 1
    end
    __tide_report_moon_phase_name_from_fraction $phase_fraction
end

if not functions -q __tide_report_moon_phase_fraction_from_unix
    source (status filename | path dirname)/_tide_report_moon_math.fish
end

## Write a normalized moon.json using the offline local moon phase model.
function __tide_report_provider_moon_local --description "Write normalized moon.json using offline local moon phase model" --argument-names moon_cache timeout_sec lock_var
    function _remove_lock_moon --description "Clear local moon provider lock when process exits" --on-process-exit $fish_pid --on-signal INT --on-signal TERM --inherit-variable lock_var
        set -e $lock_var
    end

    set -l now (command date +%s)
    set -l phase (__tide_report_moon_phase_from_unix $now)
    if test -z "$phase"
        return
    end

    set -l moon_json (jq -n --arg phase "$phase" '{phase:$phase}')
    mkdir -p (dirname "$moon_cache")
    set -l moon_temp "$moon_cache.$fish_pid.tmp"
    printf "%s" "$moon_json" > "$moon_temp" && command mv -f "$moon_temp" "$moon_cache"
end

