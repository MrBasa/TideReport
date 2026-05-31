## TideReport :: Moon async fetch (provider-agnostic)
##
## Dispatches by tide_report_moon_provider (local | wttr). Normalized moon.json: { "phase": "..." }.
## When moon=wttr and weather=wttr, one weather fetch fills both caches.

function __tide_report_moon_load_deps --description "Lazy-load moon async dependencies based on configured provider" --argument-names provider
    set -l _dir (status filename | path dirname)
    if not functions -q __tide_report_cache_state
        source "$_dir/_tide_report_cache_helpers.fish"
    end
    if not functions -q __tide_report_lock_acquire
        source "$_dir/_tide_report_lock_helpers.fish"
    end
    if test "$provider" = "wttr"
        if test "$tide_report_weather_provider" = "wttr"
            if not functions -q __tide_report_fetch_weather
                source "$_dir/_tide_report_handle_async_weather.fish"
            end
        else if not functions -q __tide_report_provider_moon_wttr
            source "$_dir/_tide_report_provider_moon_wttr.fish"
        end
    else if not functions -q __tide_report_provider_moon_local
        source "$_dir/_tide_report_provider_moon_local.fish"
    end
end

function _tide_report_handle_async_moon --description "Manage moon.json cache validity and trigger background moon fetches" --argument-names item_name cache_file refresh_seconds expire_seconds unavailable_text unavailable_color timeout_sec
    set -l provider (set -q tide_report_moon_provider; and echo $tide_report_moon_provider; or echo "local")
    __tide_report_moon_load_deps "$provider"

    set -l now (command date +%s)
    set -l _state (__tide_report_cache_state "$cache_file" "$now" $refresh_seconds $expire_seconds)
    set -l trigger_fetch false
    set -l cache_valid false
    test "$_state[1]" = true; and set trigger_fetch true
    test "$_state[2]" = true; and set cache_valid true

    if $trigger_fetch
        set -l lock_var "moon"
        if test "$provider" = "wttr"; and test "$tide_report_weather_provider" = "wttr"
            set lock_var "weather"
        end
        if __tide_report_lock_acquire "$lock_var" "$now" 120
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
