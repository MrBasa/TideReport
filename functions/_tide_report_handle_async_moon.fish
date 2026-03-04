## TideReport :: Moon async fetch (provider-agnostic)
##
## Dispatches by tide_report_moon_provider (local | wttr). Normalized moon.json: { "phase": "..." }.
## When moon=wttr and weather=wttr, one weather fetch fills both caches.

set -l _tr_moon_dir (status filename | path dirname)
# Need __tide_report_fetch_weather when moon=wttr and weather=wttr
source "$_tr_moon_dir/_tide_report_handle_async_weather.fish"
source "$_tr_moon_dir/_tide_report_provider_moon_wttr.fish"
source "$_tr_moon_dir/_tide_report_provider_moon_local.fish"

function _tide_report_handle_async_moon --description "Manage moon.json cache validity and trigger background moon fetches" --argument-names item_name cache_file refresh_seconds expire_seconds unavailable_text unavailable_color timeout_sec
    set -l now (command date +%s)
    set -l trigger_fetch false
    set -l cache_valid false
    set -l provider (set -q tide_report_moon_provider; and echo $tide_report_moon_provider; or echo "local")

    if test -f "$cache_file"
        set -l mod_time (command date -r "$cache_file" +%s 2>/dev/null; or echo 0)
        set -l cache_age (math $now - $mod_time)
        if test $cache_age -le $expire_seconds
            set cache_valid true
            test $cache_age -gt $refresh_seconds && set trigger_fetch true
        else
            set trigger_fetch true
        end
    else
        set trigger_fetch true
    end

    if $trigger_fetch
        set -l lock_var "_tide_report_moon_lock"
        if test "$provider" = "wttr"; and test "$tide_report_weather_provider" = "wttr"
            set lock_var "_tide_report_wttr_lock"
        end
        set -l lock_time (set -q $lock_var; and echo $$lock_var; or echo 0)
        if test (math $now - $lock_time) -gt 120
            set -U $lock_var $now
            if test "$provider" = "wttr"; and test "$tide_report_weather_provider" = "wttr"
                set -l weather_cache "$HOME/.cache/tide-report/weather.json"
                __tide_report_fetch_weather "$weather_cache" "$timeout_sec" "$lock_var" &
            else if test "$provider" = "wttr"
                __tide_report_provider_moon_wttr "$cache_file" "$timeout_sec" "$lock_var" &
            else
                # Default and fallback: local offline provider.
                __tide_report_provider_moon_local "$cache_file" "$timeout_sec" "$lock_var" &
            end
            disown 2>/dev/null
        end
    end

    if $cache_valid
        return 0
    else
        _tide_print_item $item_name (set_color $unavailable_color)$unavailable_text
        return 1
    end
end
