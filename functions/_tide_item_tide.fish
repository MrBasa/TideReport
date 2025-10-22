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

# --- "Private" Helper Function ---
# Usage: __tide_report_parse_tide $now_timestamp $cache_file_path
function __tide_report_parse_tide --description "Parses tide data from cache" --argument-names now cache_file
    # This entire function is wrapped in a try/catch block
    # as a final safeguard.
    begin
        # Use jq for simple, robust extraction.
        # We use a tab '\t' as a delimiter.
        set -l predictions (cat $cache_file | jq -r '.predictions[] | "\(.t)\t\(.type)"' 2>/dev/null)

        # Check the status of the 'jq' command in the pipe.
        if test $pipestatus[2] -ne 0
            # jq itself failed (e.g., invalid JSON).
            echo (set_color $tide_report_tide_unavailable_color)$tide_report_tide_unavailable_text
            return
        end

        # Check if jq simply found no predictions
        if test -z "$predictions"
            echo (set_color $tide_report_tide_unavailable_color)$tide_report_tide_unavailable_text
            return
        end

        for line in $predictions
            set -l parts (string split "\t" -- $line)
            if test (count $parts) -ne 2
                continue # Malformed line
            end

            set -l date_str $parts[1]
            set -l tide_type $parts[2]

            # Use 'date -d', which is much more flexible
            # and can parse 'T...Z' or ' ' separators.
            # We silence its stderr as well.
            set -l tide_timestamp (date -d "$date_str" +%s 2>/dev/null)
            if test $status -ne 0
                continue # date command failed to parse
            end

            # Compare timestamp to $now
            if test $tide_timestamp -gt $now
                # This is the first future tide.
                set -l tide_time (date -d "$date_str" +%H:%M)
                set -l arrow
                if test "$tide_type" = "H"
                    set arrow $tide_report_tide_arrow_rising
                else
                    set arrow $tide_report_tide_arrow_falling
                end
                echo "$arrow$tide_time"
                return # We are done
            end
        end

        # If loop finishes, no future tides were found
        echo (set_color $tide_report_tide_unavailable_color)$tide_report_tide_unavailable_text

    # --- This is the "catch" block for the helper ---
    end; or begin
        # Catch any other unexpected error (e.g., in 'string split')
        echo (set_color $tide_report_tide_unavailable_color)$tide_report_tide_unavailable_text
    end
end


# --- Main Tide Prompt Item ---
# Displays the next high or low tide from NOAA.
function _tide_item_tide --description "Fetches and displays next tide for Tide"
    # --- Pre-flight Checks ---
    if not type -q jq
        _tide_print_item tide (set_color $tide_report_tide_unavailable_color)"jq not found"
        return
    end
    if test -z "$tide_report_tide_station_id"
        _tide_print_item tide (set_color $tide_report_tide_unavailable_color)"No Station ID"
        return
    end

    # --- Setup Variables ---
    set -l cache_file ~/.cache/tide-report/tide.json
    set -l output ""

    # --- Main Logic Block (Try...) ---
    begin
        set -l url "https://api.tidesandcurrents.noaa.gov/api/prod/datagetter?date=today&station=$tide_report_tide_station_id&product=predictions&interval=hilo&datum=MLLW&time_zone=lst_ldt&units=$tide_report_tide_units&format=json"
        set -l now (date +%s)

        # --- Check Cache Status ---
        set -l cache_age -1
        set -l cache_is_expired true
        if test -f $cache_file
            set -l mod_time (date -r $cache_file +%s 2>/dev/null)
            if test $status -eq 0
                set cache_age (math $now - $mod_time)
                if test $cache_age -le $tide_report_tide_expire_seconds
                    set cache_is_expired false
                end
            end
        end

        # Check if cache is fresh
        if test $cache_age -ne -1; and test $cache_age -le $tide_report_tide_refresh_seconds
            # Call the armored helper function
            set output (__tide_report_parse_tide $now $cache_file)

        # Cache is stale, expired, or missing. We must fetch.
        else
            set -l timeout_sec (math -s3 "$tide_report_service_timeout_millis / 1000")
            set -l tide_json_data (curl -s --max-time $timeout_sec $url)
            set -l curl_status $status

            # Use the NOAA-specific validator
            if _tide_report_validate_noaa $curl_status "$tide_json_data" "tide" "$url"
                # --- Validation PASSED ---
                mkdir -p (dirname $cache_file)
                echo $tide_json_data > $cache_file
                set output (__tide_report_parse_tide $now $cache_file)
            else
                # --- Validation FAILED ---
                # Fallback to stale (but not expired) cache if it exists
                if not $cache_is_expired
                    set output (__tide_report_parse_tide $now $cache_file)
                else
                    # Stale cache is expired or never existed, show unavailable
                    set output (set_color $tide_report_tide_unavailable_color)$tide_report_tide_unavailable_text
                end
            end
        end

        # --- Final Massage ---
        set output (string replace --all '\t' ' ' -- $output)
        set output (string replace --all --regex ' {2,}' ' ' -- $output)

    # --- Catch Unexpected Errors ---
    end; or begin
        set -l error_status $status
        set -l log_file (mktemp --tmpdir tide-report-panic.XXXXXX.log)
        echo "--- UNEXPECTED TIDE ERROR ---" >> $log_file
        echo "Timestamp: (date)" >> $log_file
        echo "Function: _tide_item_tide" >> $log_file
        echo "Exit Status: $error_status" >> $log_file
        if set -q url
            echo "URL: $url" >> $log_file
        end

        # Set output to unavailable
        set output (set_color $tide_report_tide_unavailable_color)$tide_report_tide_unavailable_text
    end

    # --- Final Output ---
    _tide_print_item tide $output
end
