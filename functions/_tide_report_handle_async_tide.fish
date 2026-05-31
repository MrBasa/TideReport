## TideReport :: Tide async fetch
##
## Manages tide.json cache validity and triggers background NOAA fetches.

function __tide_report_tide_load_deps --description "Lazy-load tide async dependencies"
    set -l _dir (status filename | path dirname)
    if not functions -q __tide_report_cache_state
        source "$_dir/_tide_report_cache_helpers.fish"
    end
    if not functions -q __tide_report_gnu_date_cmd
        source "$_dir/_tide_report_time_helpers.fish"
    end
    if not functions -q __tide_report_lock_acquire
        source "$_dir/_tide_report_lock_helpers.fish"
    end
    if not functions -q __tide_report_parse_tide
        source "$_dir/_tide_report_tide_helpers.fish"
    end
end

function _tide_report_handle_async_tide --description "Manage tide.json cache, trigger fetch, return formatted output" --argument-names cache_file now refresh_seconds expire_seconds gnu_date_cmd unavailable_text unavailable_color parse_failed_suffix timeout_sec url
    __tide_report_tide_load_deps

    set -l trigger_fetch false
    set -l output (set_color $unavailable_color)"$unavailable_text"

    set -l _state (__tide_report_cache_state "$cache_file" "$now" $refresh_seconds $expire_seconds)
    set -l trigger_fetch false
    set -l cache_valid false
    test "$_state[1]" = true; and set trigger_fetch true
    test "$_state[2]" = true; and set cache_valid true

    if $cache_valid
        if set parsed (__tide_report_parse_tide "$now" "$cache_file" "$gnu_date_cmd")
            set output $parsed
        else
            set output (set_color $unavailable_color)"$unavailable_text$parse_failed_suffix"
            set trigger_fetch true
        end
    end

    if $trigger_fetch
        set -l lock_name "tide"
        if __tide_report_lock_acquire "$lock_name" "$now" 120
            __tide_report_fetch_tide "$url" "$cache_file" "$lock_name" "$timeout_sec" &
            disown 2>/dev/null
        end
    end

    echo "$output"
end
