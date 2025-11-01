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
    set -l now (command date +%s)
    set -l output
    set -l trigger_fetch false

    # Get current date and construct URL for 48-hour range
    set -l current_date (command date +%Y%m%d)

    # --- CHANGE: Always fetch units in metric for consistent caching ---
    set -l url "https://api.tidesandcurrents.noaa.gov/api/prod/datagetter?product=predictions&interval=hilo&datum=MLLW&time_zone=gmt&units=metric&format=json"
    set url "$url&station=$tide_report_tide_station_id"
    set url "$url&begin_date=$current_date"
    set url "$url&range=48"

    # Check cache status
    if test -f "$cache_file"
        # 2>/dev/null suppresses errors if file disappears; 'or echo 0' handles it
        set -l mod_time (command date -r "$cache_file" +%s 2>/dev/null; or echo 0)
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

    # Trigger background fetch if needed, using logic from user's reference file
    if $trigger_fetch
        set -l lock_var "_tide_report_tide_lock"
        # Get lock time, default to 0 if not set
        set -l lock_time (set -q $lock_var; and echo $$lock_var; or echo 0)

        # If lock is older than 120s, set lock and run fetch
        test (math $now - $lock_time) -gt 120 && set -U $lock_var $now && _tide_report_fetch_tide "$url" "$cache_file" "$lock_var" &
    end

    # Final output
    if string match -q "*!data" "$output"
        set output (set_color $tide_report_tide_unavailable_color)"$output"
    end
    _tide_print_item tide $output
end

# This function now correctly handles GMT/UTC time
function __tide_report_parse_tide --argument-names now cache_file
    # Simple validation
    if not test -f "$cache_file"
        return 1
    end
    # Suppress jq error output on invalid JSON
    if not jq -e '.predictions | length > 0' "$cache_file" >/dev/null 2>&1
        return 1
    end

    # --- Determine date command *name* *once* ---
    set -l gnu_date_cmd
    if command -q gdate  # GNU date on macOS (Homebrew)
        set gnu_date_cmd gdate
    else if command date --version >/dev/null 2>&1  # GNU date on Linux
        set gnu_date_cmd date
    end
    # $gnu_date_cmd is now 'gdate', 'date', or empty (if BSD date)
    # -----------------------------------------------------------------

    # --- Get user's desired time format, default to %H:%M ---
    set -l time_format %H:%M
    if set -q tide_time_format; and test -n "$tide_time_format"
        set time_format $tide_time_format
    end
    # -----------------------------------------------------------------

    # Extract predictions, now including the value 'v'
    set -l predictions (jq -r '.predictions[] | "\(.t) \(.type) \(.v)"' "$cache_file" 2>/dev/null)
    if test $status -ne 0; or test -z "$predictions"
        return 1
    end

    for line in $predictions
        set -l parts (string split " " -- $line)
        if test (count $parts) -lt 4
            continue
        end

        set -l date_str "$parts[1] $parts[2]"
        set -l tide_type $parts[3]
        set -l tide_value_metric $parts[4] # This value is now always in meters

        # --- Cross-platform date parsing (parse as UTC) ---
        set -l tide_timestamp
        if test -n "$gnu_date_cmd"
            # GNU date (gdate or Linux date)
            set tide_timestamp ($gnu_date_cmd -d "$date_str UTC" +%s 2>&1)
        else
            # BSD date (default macOS)
            set tide_timestamp (TZ=UTC command date -j -f "%Y-%m-%d %H:%M" "$date_str" +%s 2>&1)
        end

        if test $status -ne 0; or test -z "$tide_timestamp"
            continue
        end

        # Check if this is a future tide (now a correct comparison)
        if test $tide_timestamp -gt $now

            # --- Cross-platform time formatting (format as local time) ---
            set -l tide_time
            if test -n "$gnu_date_cmd"
                # GNU date (gdate or Linux date)
                set tide_time ($gnu_date_cmd -d @$tide_timestamp +$time_format 2>&1)
            else
                # BSD date (default macOS)
                set tide_time (command date -r $tide_timestamp +$time_format 2>&1)
            end

            if test -n "$tide_time"; and test $status -eq 0
                set -l arrow
                test "$tide_type" = "H" && set arrow $tide_report_tide_arrow_rising || set arrow $tide_report_tide_arrow_falling

                set -l output_string "$arrow$tide_time"

                # --- CHANGE: Convert metric value to english if needed ---
                if set -q tide_report_tide_show_level; and test "$tide_report_tide_show_level" = "true"

                    set -l final_value $tide_value_metric
                    set -l unit_suffix "m" # Default to metric

                    # Check if user wants english units
                    if set -q tide_report_tide_units; and test "$tide_report_tide_units" = "english"
                        set final_value (math --scale=1 $tide_value_metric \* 3.28084)
                        set unit_suffix "ft"
                    end

                    # Format to one decimal place
                    set -l level (printf "%.1f" $final_value 2>/dev/null)
                    if test $status -eq 0; and test -n "$level"
                        set output_string "$output_string $level$unit_suffix"
                    end
                end

                echo $output_string
                return 0
            end
        end
    end

    return 1
end

# This function is unchanged
function _tide_report_fetch_tide --argument url cache_file lock_var
    # Auto-cleanup lock on exit, interrupt, or termination
    function _remove_lock --on-process-exit $fish_pid --on-signal INT --on-signal TERM --inherit-variable lock_var
        set -e $lock_var
    end

    # Fetch and validate data
    set -l tide_data (curl -s --max-time 3 "$url")
    set -l curl_status $status

    if test $curl_status -ne 0; or test -z "$tide_data"
        return
    end

    # Use 'printf' for robust piping to jq
    if printf "%s" "$tide_data" | jq -e '.predictions | length > 0' >/dev/null 2>&1
        mkdir -p (dirname "$cache_file")
        # Use 'printf' for robust file writing
        printf "%s" "$tide_data" > "$cache_file"
    end
end
