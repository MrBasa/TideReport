# TideReport :: Tide Prompt Item
# Displays the next high or low tide from NOAA.
#
# --- Sample Data: ---
# https://api.tidesandcurrents.noaa.gov/api/prod/datagetter?date=today&station=8443970&product=predictions&interval=hilo&datum=MLLW&time_zone=lst_ldt&units=english&format=json
# { "predictions" : [
#    {"t":"2025-10-22 00:18", "v":"9.398", "type":"H"},
#    {"t":"2025-10-22 06:15", "v":"1.085", "type":"L"},
#    {"t":"2025-10-22 12:24", "v":"10.093", "type":"H"},
#    {"t":"2025-10-22 18:43", "v":"0.343", "type":"L"}
# ]}

# TideReport :: Tide Prompt Item
function _tide_item_tide
    # Pre-flight checks
    if not set -q tide_report_tide_station_id
        _tide_print_item tide "No Station ID"
        return
    end

    # Setup variables
    set -l cache_file ~/.cache/tide-report/tide.json
    set -l now (date +%s)
    set -l output
    set -l trigger_fetch false

    # Get current date and construct URL for 48-hour range
    set -l current_date (date +%Y%m%d)
    set -l url "https://api.tidesandcurrents.noaa.gov/api/prod/datagetter?product=predictions&interval=hilo&datum=MLLW&time_zone=lst_ldt&units=$tide_report_tide_units&format=json"
    set url "$url&station=$tide_report_tide_station_id"
    set url "$url&begin_date=$current_date"
    set url "$url&range=48"

    # Check cache status
    if test -f "$cache_file"
        set -l mod_time (date -r "$cache_file" +%s)
        set -l cache_age (math $now - $mod_time)

        if test $cache_age -le $tide_report_tide_expire_seconds
            # Parse and display tide data
            if set output (__tide_report_parse_tide $now "$cache_file")
                test $cache_age -gt $tide_report_tide_refresh_seconds && set trigger_fetch true
            else
                set output "$tide_report_tide_unavailable_text!data"
                set trigger_fetch true
            end
        else
            # Expired cache
            set output "$tide_report_tide_unavailable_text"
            set trigger_fetch true
        end
    else
        # No cache
        set output "$tide_report_tide_unavailable_text"
        set trigger_fetch true
    end

    # Trigger background fetch if needed
    if $trigger_fetch
        set -l lock_var "_tide_report_tide_lock"
        set -l lock_time (set -q $lock_var; and echo $$lock_var; or echo 0)
        if test (math $now - $lock_time) -gt 120
            set -U $lock_var $now
            _tide_report_fetch_tide "$url" "$cache_file" $lock_var &
        end
    end

    # Final output
    if string match -q "*!data" "$output"
        set output (set_color $tide_report_tide_unavailable_color)"$output"
    end
    _tide_print_item tide $output
end

function __tide_report_parse_tide --argument-names now cache_file
    # Debug: log start
    echo "=== Tide Parse Start ===" > ~/tmp.log

    # Simple validation - check if file exists and has predictions
    if not test -f "$cache_file"
        echo "Cache file doesn't exist" >> ~/tmp.log
        return 1
    end

    if not jq -e '.predictions | length > 0' "$cache_file" >/dev/null
        echo "jq validation failed" >> ~/tmp.log
        return 1
    end

    # Extract predictions
    set -l predictions (jq -r '.predictions[] | "\(.t) \(.type)"' "$cache_file")
    if test $status -ne 0; or test -z "$predictions"
        echo "jq extraction failed" >> ~/tmp.log
        return 1
    end

    for line in $predictions
        # Simple split by space - first two parts are date, last part is type
        set -l parts (string split " " -- $line)
        if test (count $parts) -lt 3
            continue
        end

        # Reconstruct date string (first two parts)
        set -l date_str "$parts[1] $parts[2]"
        set -l tide_type $parts[3]

        # Debug: log what we're parsing
        echo "Parsing: '$date_str' type: '$tide_type'" >> ~/tmp.log

        # Cross-platform date parsing
        set -l tide_timestamp
        if command -q gdate  # GNU date on macOS
            set tide_timestamp (gdate -d "$date_str" +%s 2>&1)
        else if date --version >/dev/null 2>&1  # GNU date on Linux
            set tide_timestamp (date -d "$date_str" +%s 2>&1)
        else  # BSD date (macOS)
            set tide_timestamp (date -j -f "%Y-%m-%d %H:%M" "$date_str" +%s 2>&1)
        end
        set -l date_status $status

        # Debug: log date parsing result
        echo "Date parse status: $date_status, output: '$tide_timestamp'" >> ~/tmp.log

        if test $date_status -ne 0; or test -z "$tide_timestamp"
            continue
        end

        # Check if this is a future tide
        if test $tide_timestamp -gt $now
            # Cross-platform time formatting
            set -l tide_time
            if command -q gdate
                set tide_time (gdate -d "$date_str" +%H:%M 2>&1)
            else if date --version >/dev/null 2>&1
                set tide_time (date -d "$date_str" +%H:%M 2>&1)
            else
                set tide_time (date -j -f "%Y-%m-%d %H:%M" "$date_str" +%H:%M 2>&1)
            end
            set -l format_status $status

            # Debug: log time formatting result
            echo "Time format status: $format_status, output: '$tide_time'" >> ~/tmp.log

            if test -n "$tide_time"; and test $format_status -eq 0
                set -l arrow
                test "$tide_type" = "H" && set arrow $tide_report_tide_arrow_rising || set arrow $tide_report_tide_arrow_falling
                echo "Success: $arrow$tide_time" >> ~/tmp.log
                echo "$arrow$tide_time"
                return 0
            end
        else
            echo "Tide in past: $tide_timestamp <= $now" >> ~/tmp.log
        end
    end

    echo "No future tides found" >> ~/tmp.log
    return 1
end

function _tide_report_fetch_tide --argument url cache_file lock_var
    # Auto-cleanup lock
    function _remove_lock --on-process-exit $fish_pid --inherit-variable lock_var
        set -e $lock_var
    end

    # Fetch and validate data
    set -l tide_data (curl -s --max-time 3 "$url")
    if test $status -eq 0; and test -n "$tide_data"; and echo "$tide_data" | jq -e '.predictions | length > 0' >/dev/null
        mkdir -p (dirname "$cache_file")
        echo "$tide_data" > "$cache_file"
        echo "Data fetched and cached" >> ~/tmp.log
    else
        echo "Fetch failed: status=$status, data_length="(string length "$tide_data") >> ~/tmp.log
    end
end
