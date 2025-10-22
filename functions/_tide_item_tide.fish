# TideReport :: Tide Prompt Item
# Displays the next high or low tide from NOAA.

function _tide_item_tide --description "Fetches and displays US-based tide information for Tide"

    # --- Internal Helper Function for Parsing NOAA JSON ---
    function _tide_report_tide_parse --description "Parses tide JSON and returns a formatted string"
        set -l json_data $argv[1]
        set -l now_str (date +%Y-%m-%d\ %H:%M)

        # Find the first prediction *after* the current time
        set -l next_tide (echo $json_data | jq -r --arg now "$now_str" \
            '.predictions | map(select(.t > $now)) | first | "\(.type),\(.v),\(.t)"')

        # Check for parse failure
        if test "$next_tide" = "null,null,null" -o -z "$next_tide"
            echo $tide_report_tide_unavailable_text
            return 1 # Signal failure
        end

        # Format the parsed data
        set -l parts (string split ',' $next_tide)
        set -l type $parts[1]
        set -l height (math "round($parts[2], 1)") # Round to 1 decimal
        set -l time (string split ' ' $parts[3])[2] # Get HH:MM part

        set -l arrow
        if test "$type" = "H"
            set arrow $tide_report_tide_arrow_rising
        else
            set arrow $tide_report_tide_arrow_falling
        end

        set -l unit_suffix "ft"
        if test "$tide_report_tide_units" = "metric"
            set unit_suffix "m"
        end

        echo "$arrow $height$unit_suffix @ $time"
        return 0 # Signal success
    end
    # --- End of Internal Helper Function ---

    # Checks for dependencies
    if not command -q jq
        _tide_print_item tide "jq not found"
        return
    end

    if test -z "$tide_report_tide_station_id"
        _tide_print_item tide "No station ID"
        return
    end

    # Setup variables
    set -l cache_file ~/.cache/tide-report/tide.json
    set -l url "https://api.tidesandcurrents.noaa.gov/api/prod/datagetter?product=predictions&application=tide_report_fish&begin_date=(date -u +%Y%m%d)&range=24&datum=MLLW&station=$tide_report_tide_station_id&time_zone=lst_ldt&units=$tide_report_tide_units&format=json"
    set -l now (date +%s)
    set -l timeout_sec (math -s3 "$tide_report_service_timeout_millis / 1000")

    # Check cache status
    set -l cache_age 2592000
    if test -f $cache_file
        set -l mod_time (date -r $cache_file +%s 2>/dev/null)
        if test $status -eq 0
            set cache_age (math $now - $mod_time)
        end
    end

    #  Determine final output based on cache status
    if test $cache_age -gt $tide_report_tide_expire_seconds
        # --- Cache is missing or expired ---
        # Immediately print "unavailable" text.
        _tide_print_item tide $tide_report_tide_unavailable_text

        # Now, synchronously fetch new data.
        set -l json_data (curl -s --max-time $timeout_sec $url | string collect)

        if test $status -eq 0 -a -n "$json_data"
            # 3. Fetch succeeded, parse it.
            set -l parsed_data (_tide_report_tide_parse $json_data)
            if test $status -eq 0
                # 4. Parse succeeded, update cache and print new data.
                mkdir -p (dirname $cache_file)
                echo $json_data > $cache_file
                _tide_print_item tide $parsed_data
            end
        end

    else if test $cache_age -gt $tide_report_tide_refresh_seconds
        # --- Cache is stale (but not expired) ---
        # mmediately parse and print the stale cache data.
        set -l parsed_data (_tide_report_tide_parse (cat $cache_file))
        _tide_print_item tide $parsed_data

        # Now, synchronously fetch new data.
        set -l json_data (curl -s --max-time $timeout_sec $url | string collect)

        if test $status -eq 0 -a -n "$json_data"
            # Fetch succeeded, parse it.
            set -l new_parsed_data (_tide_report_tide_parse $json_data)
            if test $status -eq 0
                # 4. Parse succeeded, update cache and print new data.
                mkdir -p (dirname $cache_file)
                echo $json_data > $cache_file
                _tide_print_item tide $new_parsed_data
            end
        end

    else
        # --- Cache is fresh and clean ---
        # We are good, just parse the cache content and finish.
        set -l parsed_data (_tide_report_tide_parse (cat $cache_file))
        _tide_print_item tide $parsed_data
    end
end
