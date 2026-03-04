## TideReport :: Weather async fetch (provider-agnostic)
##
## Normalized cache schemas (all weather providers produce this shape):
##
##   weather.json: temp_c, temp_f, feels_like_c, feels_like_f, condition_code (WWO 113=clear, ...),
##   condition_text, wind_speed_kmh, wind_speed_mph, wind_dir_16 (N, NE, ...), humidity, uv_index,
##   sunrise_utc, sunset_utc (Unix timestamps)

## Source provider implementations
set -l _tr_weather_dir (status filename | path dirname)
source "$_tr_weather_dir/_tide_report_provider_weather_wttr.fish"
source "$_tr_weather_dir/_tide_report_provider_weather_openmeteo.fish"

## --- Main async handler for the weather cache (used by weather item only) ---
function _tide_report_handle_async_weather --description "Manage weather.json cache validity and trigger provider fetches" --argument-names item_name cache_file refresh_seconds expire_seconds unavailable_text unavailable_color timeout_sec
    set -l now (command date +%s)
    set -l trigger_fetch false
    set -l cache_valid false

    # Check cache status
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
        set -l lock_var "_tide_report_wttr_lock"
        set -l lock_time (set -q $lock_var; and echo $$lock_var; or echo 0)
        if test (math $now - $lock_time) -gt 120
            set -U $lock_var $now
            set -l resolved ""
            if test "$tide_report_weather_provider" = "openmeteo"; and test -z "$tide_report_weather_location"
                set -l ip_file "$HOME/.cache/tide-report/ip-location"
                if test -f "$ip_file"
                    set -l line (string split '|' (cat "$ip_file" 2>/dev/null; or echo ""))
                    if test (count $line) -ge 3; and test "$line[1]" = "$fish_pid"
                        set -l mtime (command date -r "$ip_file" +%s 2>/dev/null; or echo 0)
                        set -l age (math $now - $mtime)
                        if test $age -le 86400
                            set resolved "$line[2],$line[3]"
                        end
                    end
                end
            end
            set -l parent_pid "$fish_pid"
            begin
                set -gx TIDE_REPORT_PARENT_PID "$parent_pid"
                test -n "$resolved"; and set -gx TIDE_REPORT_RESOLVED_LOCATION "$resolved"
                __tide_report_fetch_weather "$cache_file" "$timeout_sec" "$lock_var"
            end &
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

## --- Dispatch by provider ---
function __tide_report_fetch_weather --description "Dispatch to configured weather provider to refresh weather.json" --argument-names weather_cache timeout_sec lock_var
    function _remove_lock --description "Clear weather provider lock when process exits" --on-process-exit $fish_pid --on-signal INT --on-signal TERM --inherit-variable lock_var
        set -e $lock_var
    end

    switch "$tide_report_weather_provider"
        case wttr
            __tide_report_provider_wttr "$weather_cache" "$timeout_sec" "$lock_var"
        case openmeteo
            __tide_report_provider_openmeteo "$weather_cache" "$timeout_sec" "$lock_var"
        case '*'
            __tide_report_provider_wttr "$weather_cache" "$timeout_sec" "$lock_var"
    end
end

# Moon handler in _tide_report_handle_async_moon.fish (sources this file for __tide_report_fetch_weather)
