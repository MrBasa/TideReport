# TideReport :: Weather Prompt Item
#
# This is the main function that Tide calls to display the weather.
# It handles all the logic for reading the cache and triggering refreshes.

function _tide_item_weather --description "Displays weather information in the Tide prompt"
    set -l cache_file ~/.cache/tide_report/weather.txt
    set -l url "$tide_report_wttr_url/$tide_report_weather_location?format=$tide_report_weather_format&$tide_report_weather_units&lang=$tide_report_weather_language"

    _tide_print_item weather (date +%H:%M:%S) $url
    _tide_print_item weather (curl -s --max-time 10 $url)
    return

    # TODO: `stat` command arguments differ between GNU (Linux) and BSD (macOS). This assumes GNU `stat`. For macOS, it would be `stat -f %m`.
    set -l mod_time (stat -c %Y $cache_file 2>/dev/null)

    # 1. Handle case where cache file does not exist or data is expired
    if not test -e $cache_file; or test (math $now - (stat -c %Y $cache_file)) -gt $tide_report_weather_expire_seconds
        # Cache file does not exist or data is expired
        _tide_print_item weather $tide_report_weather_unavailable_text
    else
        # Cache file exists and data is valid
        _tide_print_item weather (cat $cache_file)
    end

    # If refresh is needed, do a refresh.
    if not test -e $cache_file; or test (math $now - (stat -c %Y $cache_file)) -gt $tide_report_weather_refresh_seconds
        # Ensure the cache directory exists
        mkdir -p (dirname $cache_file)
        # Convert the timeout from milliseconds to seconds for curl
        set -l timeout_sec (math -s3 "$tide_report_service_timeout_millis / 1000")
        curl -s --max-time $timeout_sec $url | read weather_data

        if test $status -eq 0
            # If successful, update cache file and output new data
            echo $weather_data > $cache_file
            _tide_print_item weather $weather_data
        else
            # Otherwise, print unavailable text
            _tide_print_item weather $tide_report_weather_unavailable_text
        end
    end
end
