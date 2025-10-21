# tide-report-weather :: Prompt Item Function
#
# This is the main function that Tide calls to display the weather.
# It handles all the logic for reading the cache and triggering refreshes.

function tide-report_weather --description "Displays weather information in the Tide prompt"
    set -l cache_file ~/.cache/tide-report/weather.txt
    set -l url "$tide-report_wttr.in_url/$tide_report_weather_location?format=$tide_report_weather_format&$tide_report_weather_units&lang=$tide_report_weather_language"

    # 1. Handle case where cache file does not exist
    if not test -f $cache_file
        echo $tide-report_weather_unavailable_text
        _tide-report_fetch $url $cache_file "tide-report_weather_updated"
        return
    end

    # 2. Get the age of the cache file
    # TODO: `stat` command arguments differ between GNU (Linux) and BSD (macOS). This assumes GNU `stat`. For macOS, it would be `stat -f %m`.
    set -l mod_time (stat -c %Y $cache_file 2>/dev/null)
    if test $status -ne 0 # Handle error if stat fails
        echo $tide-report_weather_unavailable_text
        return
    end

    set -l current_time (date +%s)
    set -l cache_age (math $current_time - $mod_time)

    # 3. Handle case where cache is expired
    if test $cache_age -gt $tide-report_weather_expire_seconds
        echo $tide-report_weather_unavailable_text
        _tide-report_fetch $url $cache_file "tide-report_weather_updated"
        return
    end

    # 4. Handle case where cache is stale (but still valid)
    if test $cache_age -gt $tide-report_weather_refresh_seconds
        cat $cache_file # Display the current (stale) data
        _tide-report_fetch $url $cache_file "tide-report_weather_updated"
        return
    end

    # 5. Handle case where cache is fresh
    cat $cache_file
end
