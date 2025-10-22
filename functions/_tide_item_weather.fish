# TideReport :: Weather Prompt Item
#
# This is the main function that Tide calls to display the weather.
# It handles all the logic for reading the cache and triggering refreshes.

function _tide_item_weather --description "Displays weather information in the Tide prompt"
    set -l cache_file ~/.cache/tide_report/weather.txt
    set -l url "$tide_report_wttr_url/$tide_report_weather_location?format=$tide_report_weather_format&$tide_report_weather_units&lang=$tide_report_weather_language"

    sleep 2

    _tide_print_item weather (date +%H:%M:%S)
    #_tide_print_item weather (curl -s --max-time 10 $url)
    return

    # 1. Handle case where cache file does not exist
    if not test -f $cache_file
        _tide_print_item weather $tide_report_weather_unavailable_text
        _tide_report_fetch $url $cache_file "tide_report_weather_updated"
        return
    end

    # 2. Get the age of the cache file
    # TODO: `stat` command arguments differ between GNU (Linux) and BSD (macOS). This assumes GNU `stat`. For macOS, it would be `stat -f %m`.
    set -l mod_time (stat -c %Y $cache_file 2>/dev/null)
    if test $status -ne 0 # Handle error if stat fails
        _tide_print_item weather $tide_report_weather_unavailable_text
        return
    end

    set -l current_time (date +%s)
    set -l cache_age (math $current_time - $mod_time)

    # 3. Handle case where cache is expired
    if test $cache_age -gt $tide_report_weather_expire_seconds
        _tide_print_item weather $tide_report_weather_unavailable_text
        _tide_report_fetch $url $cache_file "tide_report_weather_updated"
        return
    end

    # 4. Handle case where cache is stale (but still valid)
    if test $cache_age -gt $tide_report_weather_refresh_seconds
        _tide_print_item weather (cat $cache_file) # Display the current (stale) data
        _tide_report_fetch $url $cache_file "tide_report_weather_updated"
        return
    end

    # 5. Handle case where cache is fresh
    _tide_print_item weather (cat $cache_file)
end
