# TideReport :: PhaseOfTheMoonToday (potmt) moon provider
# Uses https://api.phaseofthemoontoday.com/v1/current (no auth). Phase names match __tide_report_get_moon_emoji.

function __tide_report_provider_moon_potmt --argument-names moon_cache timeout_sec lock_var
    function _remove_lock_moon --on-process-exit $fish_pid --on-signal INT --on-signal TERM --inherit-variable lock_var
        set -e $lock_var
    end

    set -l url (set -q tide_report_moon_potmt_url; and echo $tide_report_moon_potmt_url; or echo "https://api.phaseofthemoontoday.com/v1/current")
    set -l fetched_data (curl -s -A "tide-report/1.0" --max-time $timeout_sec "$url")
    if test $status -ne 0; or test -z "$fetched_data"
        return
    end
    set -l phase (printf "%s" "$fetched_data" | jq -r '.phase // ""')
    if test -n "$phase"
        set -l moon_json (jq -n --arg phase "$phase" '{phase:$phase}')
        mkdir -p (dirname "$moon_cache")
        set -l moon_temp "$moon_cache.$fish_pid.tmp"
        printf "%s" "$moon_json" > "$moon_temp" && command mv -f "$moon_temp" "$moon_cache"
    end
end
