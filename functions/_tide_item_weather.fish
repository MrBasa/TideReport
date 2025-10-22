# TideReport :: Weather Prompt Item
#
# This is the main function that Tide calls to display the weather.

function _tide_item_weather --description "Fetches and displays weather information for Tide"
    # Setup variables
    set -l cache_file ~/.cache/tide-report/weather.txt
    set -l url "$tide_report_wttr_url/$tide_report_weather_location?format=$tide_report_weather_format&$tide_report_weather_units&lang=$tide_report_weather_language"
    set -l now (date +%s)
    set -l output ""

    # Check cache status
    set -l cache_age -1
    set -l cache_is_expired true
    if test -f $cache_file
        set -l mod_time (date -r $cache_file +%s 2>/dev/null)
        if test $status -eq 0
            set cache_age (math $now - $mod_time)
            if test $cache_age -le $tide_report_weather_expire_seconds
                set cache_is_expired false
            end
        end
    end

    # Check if cache is fresh (not stale, not expired)
    if test $cache_age -ne -1; and test $cache_age -le $tide_report_weather_refresh_seconds
        set output (cat $cache_file)

    # Cache is stale, expired, or missing. We must fetch.
    else
        set -l timeout_sec (math -s3 "$tide_report_service_timeout_millis / 1000")
        set -l weather_data (curl -s --max-time $timeout_sec $url | string collect)
        set -l curl_status $status

        # 3. Validate the new data
        if _tide_report_validate_wttr $curl_status "$weather_data" "weather" "$url"
            # --- Validation PASSED ---
            set output $weather_data
            # Update cache
            mkdir -p (dirname $cache_file)
            echo $weather_data > $cache_file
        else
            # --- Validation FAILED ---
            # Fallback: Use stale-but-not-expired cache if available, otherwise use the unavailable text.
            if not $cache_is_expired
                set output (cat $cache_file)
            else
                set output $tide_report_weather_unavailable_text
            end
        end
    end

    # --- Final Output ---
    _tide_print_item weather $output
end

