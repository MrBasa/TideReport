# TideReport :: Tide Prompt Item
# This function handles all logic for displaying the tide prediction module.
#
# --- Sample Data: ---
# https://api.tidesandcurrents.noaa.gov/api/prod/datagetter?date=today&station=8443970&product=predictions&interval=hilo&datum=MLLW&time_zone=lst_ldt&units=english&format=json
# { "predictions" : [
#    {"t":"2025-10-22 00:18", "v":"9.398", "type":"H"},
#    {"t":"2025-10-22 06:15", "v":"1.085", "type":"L"},
#    {"t":"2025-10-22 12:24", "v":"10.093", "type":"H"},
#    {"t":"2025-10-22 18:43", "v":"0.343", "type":"L"}
# ]}

function _tide_item_tide --description "Fetches and displays next high or low tide"
    if not set -q tide_report_tide_station_id
        set -l output (set_color $tide_report_tide_unavailable_color)"$tide_report_tide_unavailable_text!stationID"
        _tide_print_item tide $output
        return
    end

    # Get current epoch (cross-platform)
    set -l now (command date +%s)
    # Get current date for URL (cross-platform)
    set -l current_date (command date +%Y%m%d)

    # Determine GNU/BSD date command for the parser
    set -l gnu_date_cmd
    if command -q gdate
        set gnu_date_cmd gdate
    else if command date --version >/dev/null 2>&1
        set gnu_date_cmd date
    end

    set -l cache_file ~/.cache/tide-report/tide.json
    set -l output
    set -l trigger_fetch false
    set -l url "https://api.tidesandcurrents.noaa.gov/api/prod/datagetter?product=predictions&interval=hilo&datum=MLLW&time_zone=gmt&units=metric&format=json"
    set url "$url&station=$tide_report_tide_station_id"
    set url "$url&begin_date=$current_date"
    set url "$url&range=48"

    if test -f "$cache_file"
        set -l mod_time (command date -r "$cache_file" +%s 2>/dev/null; or echo 0)
        set -l cache_age (math $now - $mod_time)

        if test $cache_age -le $tide_report_tide_expire_seconds
            if set output (__tide_report_parse_tide $now "$cache_file" "$gnu_date_cmd")
                test $cache_age -gt $tide_report_tide_refresh_seconds && set trigger_fetch true
            else
                set output (set_color $tide_report_tide_unavailable_color)"$tide_report_tide_unavailable_text!data"
                set trigger_fetch true
            end
        else
            set output (set_color $tide_report_tide_unavailable_color)"$tide_report_tide_unavailable_text"
            set trigger_fetch true
        end
    else
        set output (set_color $tide_report_tide_unavailable_color)"$tide_report_tide_unavailable_text"
        set trigger_fetch true
    end

    if $trigger_fetch
        set -l lock_var "_tide_report_tide_lock"
        set -l lock_time 0
        if set -q $lock_var
            set lock_time $$lock_var
        end
        test (math $now - $lock_time) -gt 120 && set -U $lock_var $now && __tide_report_fetch_tide "$url" "$cache_file" "$lock_var" &
    end

    _tide_print_item tide $output
end

# --- Parse Tide Data ---
function __tide_report_parse_tide --argument-names now cache_file gnu_date_cmd
    if not test -f "$cache_file"
        return 1
    end
    if not jq -e '.predictions | length > 0' "$cache_file" >/dev/null 2>&1
        return 1
    end

    set -l time_format %H:%M
    if set -q tide_time_format; and test -n "$tide_time_format"
        set time_format $tide_time_format
    end

    set -l predictions (jq -r '.predictions[] | "\(.t) \(.type) \(.v)"' "$cache_file" 2>/dev/null)
    if test $status -ne 0; or test -z "$predictions"
        return 1
    end

    for line in $predictions
        set -l parts (string split " " -- $line)
        if test -z "$parts[4]"
            continue
        end

        set -l date_str "$parts[1] $parts[2]"
        set -l tide_type $parts[3]
        set -l tide_value_metric $parts[4]
        set -l tide_timestamp

        if test -n "$gnu_date_cmd"
            set tide_timestamp ($gnu_date_cmd -d "$date_str UTC" +%s 2>&1)
        else
            set tide_timestamp (TZ=UTC command date -j -f "%Y-%m-%d %H:%M" "$date_str" +%s 2>&1)
        end

        if test $status -ne 0; or test -z "$tide_timestamp"
            continue
        end

        if test $tide_timestamp -gt $now
            set -l tide_time
            if test -n "$gnu_date_cmd"
                set tide_time ($gnu_date_cmd -d @$tide_timestamp +$time_format 2>&1)
            else
                set tide_time (command date -r $tide_timestamp +$time_format 2>&1)
            end

            if test -n "$tide_time"; and test $status -eq 0
                set -l arrow_symbol
                test "$tide_type" = "H" && set arrow_symbol $tide_report_tide_symbol_high || set arrow_symbol $tide_report_tide_symbol_low

                set -l arrow (set_color $tide_report_tide_symbol_color)$arrow_symbol(set_color $tide_tide_color)
                set -l output_string "$arrow$tide_time"

                if set -q tide_report_tide_show_level; and test "$tide_report_tide_show_level" = "true"
                    set -l level_value $tide_value_metric
                    set -l unit_suffix "m"
                    if set -q tide_report_tide_units; and test "$tide_report_tide_units" = "english"
                        set level_value "$tide_value_metric * 3.28084"
                        set unit_suffix "ft"
                    end
                    set -l level (math --scale=1 $level_value)

                    if test $status -eq 0; and test -n "$level"
                        set output_string "$output_string $level$unit_suffix"
                    end
                end
                echo $output_string
                return 0 # Success
            end
        end
    end
    return 1 # Failure
end

# --- Fetch Tide Data ---
function __tide_report_fetch_tide --argument url cache_file lock_var
    function _remove_lock --on-process-exit $fish_pid --on-signal INT --on-signal TERM --inherit-variable lock_var
        set -e $lock_var
    end
    set -l tide_data (curl -s --max-time 3 "$url")
    set -l curl_status $status
    if test $curl_status -ne 0; or test -z "$tide_data"
        return
    end
    if printf "%s" "$tide_data" | jq -e '.predictions | length > 0' >/dev/null 2>&1
        mkdir -p (dirname "$cache_file"); and printf "%s" "$tide_data" > "$cache_file"
    end
end
