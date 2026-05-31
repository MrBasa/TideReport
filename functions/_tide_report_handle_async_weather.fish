## TideReport :: Weather async fetch (provider-agnostic)
##
## Normalized cache schemas (all weather providers produce this shape):
##
##   weather.json: temp_c, temp_f, feels_like_c, feels_like_f, condition_code (WWO 113=clear, ...),
##   condition_text, wind_speed_kmh, wind_speed_mph, wind_dir_16 (N, NE, ...), humidity, uv_index,
##   sunrise_utc, sunset_utc (Unix timestamps)

function __tide_report_weather_load_lock --description "Lazy-load weather lock helpers"
    if not functions -q __tide_report_lock_acquire
        source (status filename | path dirname)/_tide_report_lock_helpers.fish
    end
    if not functions -q __tide_report_spawn_weather_fetch
        source (status filename | path dirname)/_tide_report_spawn_helpers.fish
    end
end

function __tide_report_weather_load_cache --description "Lazy-load shared cache helpers"
    if not functions -q __tide_report_cache_state
        source (status filename | path dirname)/_tide_report_cache_helpers.fish
    end
end

function __tide_report_weather_load_providers --description "Lazy-load weather provider implementations"
    set -l _dir (status filename | path dirname)
    if not functions -q __tide_report_provider_weather_wttr
        source "$_dir/_tide_report_provider_weather_wttr.fish"
    end
    if not functions -q __tide_report_provider_weather_openmeteo
        source "$_dir/_tide_report_provider_weather_openmeteo.fish"
    end
end

## --- Main async handler for the weather cache (used by weather item only) ---
function _tide_report_handle_async_weather --description "Manage weather.json cache validity and trigger provider fetches" --argument-names item_name cache_file refresh_seconds expire_seconds unavailable_text unavailable_color timeout_sec
    __tide_report_weather_load_lock
    __tide_report_weather_load_cache
    set -l now (command date +%s)

    set -l _state (__tide_report_cache_state "$cache_file" "$now" $refresh_seconds $expire_seconds)
    set -l trigger_fetch false
    set -l cache_valid false
    test "$_state[1]" = true; and set trigger_fetch true
    test "$_state[2]" = true; and set cache_valid true

    if $trigger_fetch
        set -l lock_var "weather"
        if __tide_report_lock_acquire "$lock_var" "$now" 120
            set -l resolved ""
            if test "$tide_report_weather_provider" = "openmeteo"; and test -z "$tide_report_weather_location"
                if not functions -q __tide_report_read_ip_location_cache
                    source (status filename | path dirname)/_tide_report_weather_helpers.fish
                end
                set resolved (__tide_report_read_ip_location_cache "$now" 86400)
            end
            set -l parent_pid "$fish_pid"
            __tide_report_spawn_weather_fetch "$cache_file" "$timeout_sec" "$lock_var" "$parent_pid" "$resolved"
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
    __tide_report_weather_load_lock
    __tide_report_weather_load_providers
    function _remove_lock --description "Clear weather provider lock when process exits" --on-process-exit $fish_pid --on-signal INT --on-signal TERM --inherit-variable lock_var
        __tide_report_lock_release "$lock_var"
    end

    switch "$tide_report_weather_provider"
        case wttr
            __tide_report_provider_weather_wttr "$weather_cache" "$timeout_sec" "$lock_var"
        case openmeteo
            __tide_report_provider_weather_openmeteo "$weather_cache" "$timeout_sec" "$lock_var"
        case '*'
            __tide_report_provider_weather_wttr "$weather_cache" "$timeout_sec" "$lock_var"
    end
end

# Moon handler in _tide_report_handle_async_moon.fish (sources this file for __tide_report_fetch_weather)
