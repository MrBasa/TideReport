# TideReport :: wttr.in moon provider (moon-only fetch)
# Used when moon provider is wttr but weather provider is not wttr (so we need a separate moon request).

function __tide_report_provider_moon_wttr --argument-names moon_cache timeout_sec lock_var
    function _remove_lock_moon --on-process-exit $fish_pid --on-signal INT --on-signal TERM --inherit-variable lock_var
        set -e $lock_var
    end

    set -l url "$tide_report_wttr_url/$tide_report_weather_location?format=j1&lang=$tide_report_weather_language"
    set -l fetched_data (curl -s -A "$tide_report_user_agent" --max-time $timeout_sec "$url")
    if test $status -ne 0; or test -z "$fetched_data"
        return
    end
    set -l phase (printf "%s" "$fetched_data" | jq -r '.weather[0].astronomy[0].moon_phase // ""')
    if test -n "$phase"
        set -l moon_json (jq -n --arg phase "$phase" '{phase:$phase}')
        mkdir -p (dirname "$moon_cache")
        set -l moon_temp "$moon_cache.$fish_pid.tmp"
        printf "%s" "$moon_json" > "$moon_temp" && command mv -f "$moon_temp" "$moon_cache"
    end
end
