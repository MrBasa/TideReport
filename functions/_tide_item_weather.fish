# TideReport :: Weather Prompt Item
#
# This is the main function that Tide calls to display the weather.

function _tide_item_weather --description "Fetches and displays weather information for Tide"
    # Setup variables
    set -l cache_file ~/.cache/tide-report/weather.txt
    set -l url "$tide_report_wttr_url/$tide_report_weather_location?format=$tide_report_weather_format&$tide_report_weather_units&lang=$tide_report_weather_language"
    set -l now (date +%s)

    _tide_print_item weather (random 0 9)
    sleep 2
    _tide_print_item weather (random 0 9)
    sleep 2
    _tide_print_item weather (random 0 9)
    return

    # Check cache status
    set -l cache_age -1
    if test -f $cache_file
        set -l mod_time (date -r $cache_file +%s 2>/dev/null)
        if test $status -eq 0
            set cache_age (math $now - $mod_time)
        end
    end

    # Determine final output based on cache status
    if test $cache_age -eq -1; or test $cache_age -gt $tide_report_weather_expire_seconds
        # --- Cache is missing or expired ---
        # Immediately print "unavailable" text.
        _tide_print_item weather $tide_report_weather_unavailable_text

        # Now, synchronously fetch new data.
        set -l timeout_sec (math -s3 "$tide_report_service_timeout_millis / 1000")
        set -l weather_data (curl -s --max-time $timeout_sec $url | string collect)

        if test $status -eq 0 -a -n "$weather_data"
            # Fetch succeeded, update cache and print new data.
            mkdir -p (dirname $cache_file)
            echo $weather_data > $cache_file
            _tide_print_item weather $weather_data
        end
        # If fetch fails, we already printed "unavailable", so we just end.

    else if test $cache_age -gt $tide_report_weather_refresh_seconds
        # --- Cache is stale (but not expired) ---
        # Immediately print the stale cache data.
        _tide_print_item weather (cat $cache_file)

        # Synchronously fetch new data in the background.
        set -l timeout_sec (math -s3 "$tide_report_service_timeout_millis / 1000")
        set -l weather_data (curl -s --max-time $timeout_sec $url | string collect)

        if test $status -eq 0 -a -n "$weather_data"
            # Fetch succeeded, update cache and print new data.
            mkdir -p (dirname $cache_file)
            echo $weather_data > $cache_file
            _tide_print_item weather $weather_data
        end
    else
        # --- Cache is fresh ---
        # We good, just print the cache content and finish.
        _tide_print_item weather (cat $cache_file)
    end
end

