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
# (This function is unchanged from the previous, correct version)
function __tide_report_parse_tide --description "Parses tide data from cache" --argument-names now cache_file
    begin
        set -l predictions (cat $cache_file | jq -r '.predictions[] | "\(.t)\t\(.type)"' 2>/dev/null)
        if test $pipestatus[2] -ne 0; or test -z "$predictions"
            echo "__TIDE_REPORT_UNAVAILABLE__"
            return
        end
        for line in $predictions
            set -l parts (string split "\t" -- $line)
            if test (count $parts) -ne 2; continue; end
            set -l date_str $parts[1]
            set -l tide_type $parts[2]
            set -l tide_timestamp (date -d "$date_str" +%s 2>/dev/null)
            if test $status -ne 0; continue; end
            if test $tide_timestamp -gt $now
                set -l tide_time (date -d "$date_str" +%H:%M)
                set -l arrow
                if test "$tide_type" = "H"
                    set arrow $tide_report_tide_arrow_rising
                else
                    set arrow $tide_report_tide_arrow_falling
                end
                echo "$arrow$tide_time"
                return
            end
        end
        echo "__TIDE_REPORT_UNAVAILABLE__"
    end; or begin
        echo "__TIDE_REPORT_UNAVAILABLE__"
    end
end


# --- Main Tide Prompt Item ---
function _tide_item_tide --description "Fetches and displays next tide for Tide"
    # --- Pre-flight Checks ---
    if not set -q tide_report_service_timeout_millis
        _tide_print_item tide "TideReport Config Not Loaded"
        return
    end
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
    set -l url "https://api.tidesandcurrents.noaa.gov/api/prod/datagetter?date=today&station=$tide_report_tide_station_id&product=predictions&interval=hilo&datum=MLLW&time_zone=lst_ldt&units=$tide_report_tide_units&format=json"

    # --- Main Logic Block (Try...) ---
    begin
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
            set output (__tide_report_parse_tide $now $cache_file)
        # Cache is stale, expired, or missing. We must fetch.
        else
            set -l timeout_sec (math -s3 "$tide_report_service_timeout_millis / 1000")
            set -l tide_json_data (curl -s --max-time $timeout_sec $url)
            set -l curl_status $status

            if _tide_report_validate_noaa $curl_status "$tide_json_data" "tide" "$url"
                mkdir -p (dirname $cache_file)
                echo $tide_json_data > $cache_file
                set output (__tide_report_parse_tide $now $cache_file)
            else
                if not $cache_is_expired
                    set output (__tide_report_parse_tide $now $cache_file)
                else
                    set output "__TIDE_REPORT_UNAVAILABLE__"
                end
            end
        end

        # --- Final Massage ---
        set output (string replace --all '\t' ' ' -- $output)
        set output (string replace --all --regex ' {2,}' ' ' -- $output)

    # --- CATCH BLOCK (UN-CRASHABLE) ---
    end; or begin
        set -l error_status $status
        # Use a hardcoded log file path to avoid mktemp failure
        set -l log_file "/tmp/tide-report-panic.log"

        # Log the error. These are simple echos and WILL NOT FAIL.
        echo "--- UNEXPECTED TIDE ERROR ---" >> $log_file
        echo "Timestamp: (date)" >> $log_file
        echo "Function: _tide_item_tide" >> $log_file
        echo "Exit Status: $error_status" >> $log_file
        if set -q url
            echo "URL: $url" >> $log_file
        end

        set output "__TIDE_REPORT_UNAVAILABLE__"
    end

    # --- Final Output ---
    # Handle the "unavailable" token here, so the catch block is clean.
    if test "$output" = "__TIDE_REPORT_UNAVAILABLE__"
        set output (set_color $tide_report_tide_unavailable_color)$tide_report_tide_unavailable_text
    end
    _tide_print_item tide $output
end
