## TideReport :: Tide helpers (parse, render, fetch)
##
## Shared by _tide_item_tide and _tide_report_handle_async_tide.

if not functions -q __tide_report_gnu_date_cmd
    source (status filename | path dirname)/_tide_report_time_helpers.fish
end
if not functions -q __tide_report_write_json_cache
    source (status filename | path dirname)/_tide_report_cache_helpers.fish
end
if not functions -q __tide_report_lock_acquire
    source (status filename | path dirname)/_tide_report_lock_helpers.fish
end

function __tide_report_render_tide --description "Render tide segment from type (H/L), time_str, value_metric, show_level" --argument-names type time_str value_metric show_level
    set -q type || set type "H"
    set -q time_str || set time_str ""
    set -q value_metric || set value_metric ""
    set -q show_level || set show_level "true"

    set -q tide_report_tide_symbol_high || set -l tide_report_tide_symbol_high "⇞"
    set -q tide_report_tide_symbol_low || set -l tide_report_tide_symbol_low "⇟"
    set -q tide_report_tide_symbol_color || set -l tide_report_tide_symbol_color white
    set -q tide_tide_color || set -l tide_tide_color 0087AF

    set -l arrow_symbol
    test "$type" = "H" && set arrow_symbol $tide_report_tide_symbol_high || set arrow_symbol $tide_report_tide_symbol_low
    set -l arrow (set_color $tide_report_tide_symbol_color)$arrow_symbol(set_color $tide_tide_color)
    set -l output_string "$arrow$time_str"

    if test "$show_level" = "true"; and test -n "$value_metric"
        set -l unit_suffix "m"
        set -l level_value $value_metric
        if set -q tide_report_units; and test "$tide_report_units" = "u"
            set level_value (math --scale=1 "$value_metric * 3.28084")
            set unit_suffix "ft"
        else
            set level_value (math --scale=1 $value_metric)
        end
        if test -n "$level_value"
            set output_string "$output_string $level_value$unit_suffix"
        end
    end
    echo "$output_string"
end

function __tide_report_parse_tide --description "Parse tide.json and compute the next tide time and level" --argument-names now cache_file gnu_date_cmd
    if not test -f "$cache_file"
        return 1
    end

    set -l time_format %H:%M
    if set -q tide_time_format; and test -n "$tide_time_format"
        set time_format $tide_time_format
    end

    set -l current_time_str (command date -u +"%Y-%m-%d %H:%M")

    set -l next_tide (jq -r --arg now_str "$current_time_str" '
        ([.predictions[]
        | select(.t > $now_str)
        | select(.v != null and .v != "")
        | "\(.t);\(.type);\(.v)"] | first // empty)
        ' "$cache_file" 2>/dev/null)

    if test -z "$next_tide"
        return 1
    end

    echo "$next_tide" | read --delimiter ";" -l date_str tide_type tide_value_metric

    set -l epoch (__tide_report_noaa_gmt_to_unix "$date_str")
    set -l tide_time (__tide_report_format_unix_time $epoch $time_format)

    if test -n "$epoch"; and test -n "$tide_time"
        set -l show_level "true"
        set -q tide_report_tide_show_level; and test "$tide_report_tide_show_level" != "true"; and set show_level "false"
        __tide_report_render_tide "$tide_type" "$tide_time" "$tide_value_metric" "$show_level"
        return 0
    end
    return 1
end

function __tide_report_fetch_tide --description "Fetch tide predictions from NOAA and update tide.json cache" --argument-names url cache_file lock_var timeout_sec
    function _remove_lock --description "Clear tide fetch lock when process exits" --on-process-exit $fish_pid --on-signal INT --on-signal TERM --inherit-variable lock_var
        __tide_report_lock_release "$lock_var"
    end
    set -q timeout_sec || set timeout_sec (math --scale=0 "$tide_report_service_timeout_millis / 1000")
    set -l tide_data (curl -s -A "$tide_report_user_agent" --max-time $timeout_sec "$url")
    set -l curl_status $status
    if test $curl_status -ne 0; or test -z "$tide_data"
        functions -q __tide_report_log_expected && __tide_report_log_expected tide "NOAA API unavailable or invalid response"
        return
    end
    if printf "%s" "$tide_data" | jq -e '.predictions | length > 0' 2>/dev/null >/dev/null
        __tide_report_write_json_cache "$cache_file" "$tide_data"
    else
        functions -q __tide_report_log_expected && __tide_report_log_expected tide "NOAA API unavailable or invalid response"
    end
end
